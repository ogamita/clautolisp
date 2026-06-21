# Publishing the AutoLISP spec to poseidon

The GitLab CI `deploy:documentation` job publishes the prebuilt HTML manual
produced by `release:documentation` to the poseidon web site:

    http://poseidon.informatimago.com/ogamita/autolisp-spec/

## Pipeline

1. `release:documentation` (stage `release`, runs on thalassa) builds the
   paged HTML/Info/PDF and packages `dist/clautolisp-<ver>-documentation.tar.bz2`.
   That tarball ships the browsable HTML manual at
   `share/doc/autolisp-spec/html/` (index.html + symbols.html + per-section
   pages).
2. `deploy:documentation` (stage `deploy`, runs on the poseidon group
   runner) pulls that artefact via `needs:`, unpacks it, and `rsync`s
   `share/doc/autolisp-spec/html/` over SSH onto the poseidon web root.
   It runs on a version tag (`v*` / `clautolisp-v*`) or manually.

These HTML pages are **build output** — "object files" of the documentation
job. They are deployed here, never committed. The poseidon web site is its
own git repo whose `.gitignore` excludes `ogamita/autolisp-spec/`.

## Deploy mechanism (least privilege)

The job SSHes back to poseidon's own sshd as an unprivileged account,
`clautolisp-deploy`, whose key is locked down with an **rrsync forced
command** in `authorized_keys`:

    command="/usr/bin/rrsync /var/www/poseidon/public_html/ogamita/autolisp-spec",restrict ssh-ed25519 AAAA...

so the key can ONLY `rsync` into that single directory — no shell, no other
path, no port/agent/X11 forwarding. Because rrsync chroots the session to
the restricted dir, the job rsyncs to the **empty** remote path
(`clautolisp-deploy@host:`) and needs no server-side `mkdir`. Even if the
CI key leaks, its blast radius is "overwrite the spec pages".

The target dir is owned `clautolisp-deploy:www-data`, mode `2755` (setgid),
so Apache (www-data) reads what the deploy account writes.

## One-time setup

Run the helper on poseidon as root — it creates the account, the web dir
and the restricted key, self-tests the exact rsync the CI job performs,
and prints the two values to register in GitLab:

    sudo documentation/setup-deploy.sh

Then add, in **Settings > CI/CD > Variables** (scope: protected; *File*
type recommended for both):

| Variable                 | Value                                              |
|--------------------------|----------------------------------------------------|
| `DEPLOY_SSH_PRIVATE_KEY` | the printed private key                             |
| `DEPLOY_KNOWN_HOSTS`     | the printed `ssh-keyscan poseidon.informatimago.com` output |

After that, tagging a release (or running the job manually) publishes the
spec. To rotate the key, re-run `setup-deploy.sh` after deleting
`/var/lib/clautolisp-deploy/.ssh/id_clautolisp_ci*`.

## Home-page link / web site under git

The deployed pages are reached from the poseidon home page. The companion
helper `documentation/setup-poseidon-website.sh` (run once, as root) puts
the DocumentRoot under git, `.gitignore`s the CI-deployed
`ogamita/autolisp-spec/` pages (build output, not site source), and adds
the link to `/ogamita/autolisp-spec/` on the home page:

    sudo documentation/setup-poseidon-website.sh
