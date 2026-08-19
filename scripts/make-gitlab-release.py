#!/usr/bin/env python3
"""Publish the GitLab Release for a release tag, with working asset links.

    python3 scripts/make-gitlab-release.py release-1.8.49
    python3 scripts/make-gitlab-release.py release-1.8.49 --dry-run
    python3 scripts/make-gitlab-release.py release-1.8.49 --update

Step 6 of the release procedure (AGENTS.md / version-rules.md § 5). It
exists because that step used to be improvised by hand, and the hand got
it wrong twice:

  * `/artifacts/file/<path>` is the artefact BROWSING page and serves
    HTML; `/artifacts/raw/<path>` serves the file. Both answer 200, so a
    consumer following a `file' link writes 40 KB of HTML to disk under
    the archive's name and only fails later, at extraction, with a
    message about archive format rather than about the link
    (release-asset-links-use-artifacts-file.issue -- reported from the
    SCHMS+ CI, which had to carry a rewrite workaround). Releases
    1.8.47 and 1.8.49 were published with `file' links.

  * The asset list was retyped per release, so it could drift from what
    the pipeline actually collected. It is now read from
    manifest-release-assets.txt, which collect-artefacts writes from the
    directory it just filled: a new platform joins the published release
    with no edit here, and a missing one shows up as a short manifest.

Both failures shared a shape -- a release that LOOKS published and is not
usable -- so this script refuses to publish rather than warn: every link
is fetched before the release is created, and an asset that answers with
HTML aborts the run.
"""

import argparse
import json
import subprocess
import sys

PROJECT = "ogamita/clautolisp"
WEB = f"https://gitlab.com/{PROJECT}"
ARTEFACT_DIR = "dist/combined"
MANIFEST = "manifest-release-assets.txt"


def api(path, method="GET", body=None, raw=False):
    cmd = ["glab", "api", path]
    if method != "GET":
        cmd += ["--method", method, "--input", "-",
                "--header", "Content-Type: application/json"]
    proc = subprocess.run(cmd, input=json.dumps(body) if body else None,
                          capture_output=True, text=not raw)
    if proc.returncode != 0:
        err = proc.stderr if not raw else proc.stderr.decode("utf-8", "replace")
        sys.exit(f"error: GET {path}: {err.strip()}")
    if raw:
        return proc.stdout
    return json.loads(proc.stdout) if proc.stdout.strip() else {}


def collect_job(tag):
    """The collect:release job whose artefacts this release publishes."""
    pipelines = api(f"projects/:id/pipelines?ref={tag}&per_page=20")
    if not pipelines:
        sys.exit(f"error: no pipeline for {tag} -- was the tag pushed?")
    pipeline = pipelines[0]
    jobs = api(f"projects/:id/pipelines/{pipeline['id']}/jobs?per_page=100")
    found = [j for j in jobs if j["name"] == "collect:release"]
    if not found:
        sys.exit(f"error: pipeline {pipeline['id']} has no collect:release job")
    job = found[0]
    if job["status"] != "success":
        sys.exit(f"error: collect:release is {job['status']}, not success. "
                 "A release may only be published from a collect that ran.")
    return pipeline["id"], job["id"]


def assets(job_id, tag):
    """What the collect job says it produced -- not what we hope it did."""
    path = f"projects/:id/jobs/{job_id}/artifacts/{ARTEFACT_DIR}/{MANIFEST}"
    proc = subprocess.run(["glab", "api", path], capture_output=True)
    if proc.returncode == 0:
        names = [n.strip() for n in
                 proc.stdout.decode("utf-8").splitlines() if n.strip()]
        if not names:
            sys.exit(f"error: {MANIFEST} is empty -- the collect produced "
                     "nothing")
        return names

    # Releases collected before the manifest existed (1.8.47, 1.8.49) can
    # still have their links repaired: take the names from the release
    # itself. Only a fallback -- it can only repair a set someone already
    # got right, never notice one that was short.
    print(f"note: no {MANIFEST} in job {job_id} (collected before it "
          "existed); taking the asset names from the release itself")
    existing = subprocess.run(["glab", "api", f"projects/:id/releases/{tag}"],
                              capture_output=True, text=True)
    if existing.returncode != 0:
        sys.exit(f"error: job {job_id} has no {MANIFEST} and {tag} has no "
                 "release to take the names from")
    return [l["name"] for l in
            json.loads(existing.stdout)["assets"]["links"]]


def link_for(job_id, name):
    # raw, never file: see the module docstring.
    return f"{WEB}/-/jobs/{job_id}/artifacts/raw/{ARTEFACT_DIR}/{name}"


def verify(url):
    """Fetch the head of the link and report what a consumer would get."""
    fmt = "%{http_code} %{content_type} %{size_download}"
    proc = subprocess.run(
        ["curl", "-sSL", "-r", "0-1023", "-o", "/dev/null", "-w", fmt, url],
        capture_output=True, text=True)
    if proc.returncode != 0:
        return False, f"curl failed: {proc.stderr.strip()}"
    parts = proc.stdout.split()
    code = parts[0] if parts else "?"
    ctype = parts[1] if len(parts) > 1 else "?"
    if "text/html" in ctype:
        return False, (f"HTTP {code} serves {ctype} -- this is the artefact "
                       "browsing page, not the file")
    if code not in ("200", "206"):
        return False, f"HTTP {code} ({ctype})"
    return True, f"HTTP {code} {ctype}"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("tag", help="the release tag, e.g. release-1.8.49")
    ap.add_argument("--dry-run", action="store_true",
                    help="verify the links and print them; publish nothing")
    ap.add_argument("--update", action="store_true",
                    help="replace the assets of an existing release")
    ap.add_argument("--description-file",
                    help="file holding the release description (markdown)")
    args = ap.parse_args()

    tag = args.tag
    if not tag.startswith("release-"):
        sys.exit(f"error: {tag} is not a release tag (expected release-M.m.d)")
    version = tag[len("release-"):]

    pipeline_id, job_id = collect_job(tag)
    print(f"pipeline {pipeline_id}, collect:release job {job_id}")

    names = assets(job_id, tag)
    print(f"{len(names)} asset(s) to attach")

    links, bad = [], []
    for name in names:
        url = link_for(job_id, name)
        ok, detail = verify(url)
        print(f"  {'ok  ' if ok else 'FAIL'} {name}: {detail}")
        if ok:
            links.append({"name": name, "url": url, "link_type": "package"})
        else:
            bad.append(name)

    if bad:
        sys.exit(f"error: {len(bad)} link(s) do not serve their file; "
                 "refusing to publish a release of dead links: "
                 + ", ".join(bad))

    if args.dry_run:
        print(f"dry run: {len(links)} verified link(s), nothing published")
        return

    description = ""
    if args.description_file:
        with open(args.description_file) as f:
            description = f.read()

    existing = subprocess.run(["glab", "api", f"projects/:id/releases/{tag}"],
                              capture_output=True, text=True).returncode == 0
    if existing and not args.update:
        sys.exit(f"error: release {tag} already exists; pass --update to "
                 "replace its assets")

    if existing:
        for link in api(f"projects/:id/releases/{tag}")["assets"]["links"]:
            api(f"projects/:id/releases/{tag}/assets/links/{link['id']}",
                method="DELETE")
        for link in links:
            api(f"projects/:id/releases/{tag}/assets/links", "POST", link)
        if description:
            api(f"projects/:id/releases/{tag}", "PUT",
                {"description": description})
        print(f"updated release {tag}: {len(links)} asset link(s)")
    else:
        body = {"name": f"clautolisp {version}", "tag_name": tag,
                "assets": {"links": links}}
        if description:
            body["description"] = description
        api("projects/:id/releases", "POST", body)
        print(f"created release {tag}: {len(links)} asset link(s)")


if __name__ == "__main__":
    main()
