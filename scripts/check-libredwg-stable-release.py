#!/usr/bin/env python3
"""Does the vendored LibreDWG still follow upstream's latest STABLE release?

libredwg-version-is-superproject-describe. clautolisp follows LibreDWG's
stable releases (pjb, 2026-10-07): the GitHub releases of LibreDWG/libredwg
with prerelease=false. clautolisp/third-party/libredwg.release records the
followed release (`version <tag>') and the commit that tag names
(`commit <sha>'); build-libredwg.sh stamps that version into the library.

    python3 scripts/check-libredwg-stable-release.py --offline
    make check-libredwg-release            (in make check-release / CI)

        The recorded commit is the submodule's gitlink in HEAD. No network,
        no submodule checkout (reads the superproject's tree), so it runs in
        the check:release lane: moving the submodule without updating the
        release file fails there, not at the next release build.

    python3 scripts/check-libredwg-stable-release.py
    make check-libredwg-stable-release     (manual / periodic, NETWORK)

        The offline check, then asks GitHub for upstream's stable releases
        and says whether one is NEWER than the recorded one, with the tag's
        commit and the steps to follow it (AGENTS.md, "CI -- following
        LibreDWG stable releases"). Deliberately in no CI lane: a normal
        pipeline must not go red because GitHub is slow or upstream
        published a release.

Upstream also publishes a GitHub release per commit (0.14.8590, ...),
marked prerelease: those are snapshots, not releases, and are ignored.

Exit status (sysexits.h): 0 up to date; 1 a newer stable release exists, or
the release file disagrees with the gitlink; 64 usage; 65 the release file
is malformed; 69 GitHub could not be asked.
"""
import json
import os
import re
import subprocess
import sys
import urllib.request

REPO = 'LibreDWG/libredwg'
SUBMODULE = 'clautolisp/third-party/libredwg'
RELEASE_FILE = 'clautolisp/third-party/libredwg.release'

EX_NEWER, EX_USAGE, EX_DATAERR, EX_UNAVAILABLE = 1, 64, 65, 69


def recorded():
    fields = {}
    try:
        with open(RELEASE_FILE, encoding='utf-8') as f:
            for line in f:
                m = re.match(r'^(version|commit)\s+(\S+)', line)
                if m and m.group(1) not in fields:
                    fields[m.group(1)] = m.group(2)
    except OSError as e:
        print(f'{RELEASE_FILE}: {e}', file=sys.stderr)
        sys.exit(EX_DATAERR)
    if 'version' not in fields or 'commit' not in fields:
        print(f"{RELEASE_FILE}: needs a 'version <tag>' and a 'commit <sha>' line",
              file=sys.stderr)
        sys.exit(EX_DATAERR)
    return fields['version'], fields['commit']


def gitlink():
    return subprocess.run(['git', 'rev-parse', f'HEAD:{SUBMODULE}'],
                          check=True, capture_output=True, text=True).stdout.strip()


def version_key(tag):
    return tuple(int(n) for n in re.findall(r'\d+', tag))


def stable_releases():
    req = urllib.request.Request(
        f'https://api.github.com/repos/{REPO}/releases?per_page=100',
        headers={'Accept': 'application/vnd.github+json',
                 'User-Agent': 'clautolisp-check-libredwg-stable-release'})
    token = os.environ.get('GITHUB_TOKEN')
    if token:
        req.add_header('Authorization', f'Bearer {token}')
    with urllib.request.urlopen(req, timeout=30) as r:
        releases = json.load(r)
    return [x for x in releases if not x.get('prerelease') and not x.get('draft')]


def tag_commit(tag):
    out = subprocess.run(
        ['git', 'ls-remote', f'https://github.com/{REPO}.git',
         f'refs/tags/{tag}', f'refs/tags/{tag}^{{}}'],
        check=True, capture_output=True, text=True, timeout=60).stdout
    refs = dict(reversed(line.split('\t')) for line in out.splitlines() if '\t' in line)
    return refs.get(f'refs/tags/{tag}^{{}}') or refs.get(f'refs/tags/{tag}')


def main(argv):
    if argv not in ([], ['--offline']):
        print(__doc__, file=sys.stderr)
        return EX_USAGE
    version, commit = recorded()
    link = gitlink()
    if link != commit:
        print(f'FAIL: {RELEASE_FILE} records LibreDWG {version} at {commit},\n'
              f'      but HEAD pins the submodule {SUBMODULE} at {link}.\n'
              f'      Update both together (AGENTS.md, "CI -- following LibreDWG'
              f' stable releases").')
        return EX_NEWER
    print(f'OK: LibreDWG {version} recorded at {commit}, which HEAD pins.')
    if argv == ['--offline']:
        return 0

    try:
        stable = stable_releases()
    except Exception as e:  # network, rate limit, JSON
        print(f'cannot ask GitHub for {REPO} releases: {e}', file=sys.stderr)
        return EX_UNAVAILABLE
    if not stable:
        print(f'cannot find any stable release of {REPO}', file=sys.stderr)
        return EX_UNAVAILABLE
    latest = max(stable, key=lambda x: (x.get('published_at') or '',
                                        version_key(x['tag_name'])))
    tag = latest['tag_name']
    if tag == version or version_key(tag) <= version_key(version):
        print(f'OK: {version} is upstream\'s latest stable release '
              f'(published {latest.get("published_at")}).')
        return 0
    try:
        sha = tag_commit(tag) or '<resolve the tag>'
    except Exception as e:
        sha = f'<cannot resolve: {e}>'
    print(f'NEWER: LibreDWG {tag} is a stable release (published '
          f'{latest.get("published_at")}), we follow {version}.\n'
          f'  {latest.get("html_url")}\n'
          f'To follow it (AGENTS.md, "CI -- following LibreDWG stable releases"):\n'
          f'  git -C {SUBMODULE} fetch --tags origin && git -C {SUBMODULE} checkout {tag}\n'
          f'  edit {RELEASE_FILE}: version {tag} / commit {sha}\n'
          f'  git add {SUBMODULE} {RELEASE_FILE}\n'
          f'  make -C clautolisp build-libredwg   then the DWG tests')
    return EX_NEWER


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
