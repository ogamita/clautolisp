#!/bin/sh
# setup-poseidon-website.sh — put the poseidon web site under git and add a
# link from the home page to the AutoLISP spec.
#
# Run ONCE on poseidon as root (sudo). Idempotent.
#
# The docroot itself becomes the git working tree. The CI-deployed spec
# pages (ogamita/autolisp-spec/) are build output and are .gitignore'd —
# they live in the working tree but are never committed.
set -eu

DOCROOT=/var/www/poseidon/public_html
GIT="sudo -u www-data git -c safe.directory=$DOCROOT \
     -c user.name=Pascal J. Bourguignon -c user.email=informatimago@gmail.com"

[ "$(id -u)" = 0 ] || { echo "run as root (sudo $0)" >&2; exit 1; }
[ -d "$DOCROOT" ] || { echo "no docroot at $DOCROOT" >&2; exit 1; }

echo "== 1. git init (docroot is the working tree) =="
if [ ! -d "$DOCROOT/.git" ]; then
    $GIT init -b master "$DOCROOT"
    echo "initialised git repo at $DOCROOT"
else
    echo "$DOCROOT is already a git repo"
fi

echo "== 2. .gitignore (CI-deployed object files) =="
cat > "$DOCROOT/.gitignore" <<'IGN'
# Generated documentation deployed by clautolisp CI
# (release:documentation -> deploy:documentation). These HTML pages are
# build output ("object files"), not web-site source — never commit them.
/ogamita/autolisp-spec/
IGN
chown www-data:www-data "$DOCROOT/.gitignore"

echo "== 3. home page with a link to the spec =="
[ -f "$DOCROOT/index.html" ] && [ ! -f "$DOCROOT/index.html.orig" ] \
    && cp -p "$DOCROOT/index.html" "$DOCROOT/index.html.orig"
cat > "$DOCROOT/index.html" <<'HTML'
<!doctype html><html lang="en"><head><meta charset="utf-8">
<title>poseidon.informatimago.com</title>
<style>body{font-family:system-ui,sans-serif;max-width:42rem;margin:6rem auto;padding:0 1rem;color:#222}a{color:#06c}</style>
</head><body><h1>poseidon.informatimago.com</h1>
<p>Development &amp; testbed host. Up and running.</p>
<h2>Projects</h2>
<ul>
<li><a href="/ogamita/autolisp-spec/">AutoLISP / Visual&nbsp;LISP specification</a>
    &mdash; reference manual for the clautolisp project.</li>
</ul>
</body></html>
HTML
chown www-data:www-data "$DOCROOT/index.html"

echo "== 4. commit =="
# index.html.orig is a one-off backup; don't track it.
grep -qxF '/index.html.orig' "$DOCROOT/.gitignore" 2>/dev/null \
    || echo '/index.html.orig' >> "$DOCROOT/.gitignore"
$GIT -C "$DOCROOT" add -A
if $GIT -C "$DOCROOT" diff --cached --quiet; then
    echo "nothing to commit (already up to date)"
else
    $GIT -C "$DOCROOT" commit -q -m "site: home page + link to /ogamita/autolisp-spec/; ignore CI-deployed spec pages"
    echo "committed"
fi
$GIT -C "$DOCROOT" --no-pager log --oneline -1
echo
echo "Done. Home page now links to http://poseidon.informatimago.com/ogamita/autolisp-spec/"
echo "(The spec pages appear once the clautolisp deploy:documentation job runs.)"
