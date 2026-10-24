#!/usr/bin/env bash
# Mirror a collected release set to the poseidon download area, FROM CI.
#
#   bash scripts/mirror-release-to-poseidon.sh <version> <dir>
#
# collect-release-artefact-exceeds-gitlab-size-limit, option 3 (pjb,
# 2026-10-24): the release set is ~1 GB, above gitlab.com's artefact limit
# (413 for release-2.3.0), so collect:release no longer hands it to a later
# step as a GitLab artefact: it mirrors <dir> (its dist/combined) straight to
#   https://poseidon.informatimago.com/ogamita/clautolisp/releases/<version>/
# and regenerates the index pages, the way deploy:documentation publishes the
# spec manual.
#
# It sends as release-ogamita, the poseidon account that owns the ogamita web
# tree (documentation/setup-deploy.sh): every sender's key there is an rrsync
# forced command chrooted to /var/www/poseidon/public_html/ogamita -- rsync
# there and nothing else, no shell. So the remote paths below are relative to
# that tree (clautolisp/releases/...), and the index pages are generated HERE:
# the release page from <dir>, the release listing from the version
# directories the server lists (rsync --list-only). Archives land read-only
# (444), directories 755 (pjb, 2026-10-24).
#
# Env: DEPLOY_SSH_PRIVATE_KEY, DEPLOY_KNOWN_HOSTS -- base64, as a value or a
#      File-type CI variable (the runners' key, as for deploy:documentation);
#      or RELEASE_DEPLOY_KEY_FILE, a plain private key file (a sender on
#      poseidon: ~/.ssh/release-ogamita); DEPLOY_HOST
#      (poseidon.informatimago.com), DEPLOY_USER (release-ogamita).
set -euo pipefail
VER="${1:?usage: $0 <version> <dir>}"
DIR="${2:?usage: $0 <version> <dir>}"
HOST="${DEPLOY_HOST:-poseidon.informatimago.com}"
USER_="${DEPLOY_USER:-release-ogamita}"
BASE=clautolisp/releases
URL="https://poseidon.informatimago.com/ogamita/clautolisp/releases/$VER/"
GEN="$(cd "$(dirname "$0")" && pwd)/gen-release-index.py"

[ -d "$DIR" ] || { echo "no directory $DIR" >&2; exit 1; }
[ -f "$DIR/manifest-release-assets.txt" ] || { echo "no manifest-release-assets.txt in $DIR" >&2; exit 1; }

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
decode() {  # $1: a variable's value -- a file path (File type) or base64 text
  if [ -f "$1" ]; then base64 -d "$1"; else printf '%s' "$1" | base64 -d; fi
}
if [ -n "${RELEASE_DEPLOY_KEY_FILE:-}" ]; then
  cp "$RELEASE_DEPLOY_KEY_FILE" "$work/id"
else
  [ -n "${DEPLOY_SSH_PRIVATE_KEY:-}" ] || {
    echo "DEPLOY_SSH_PRIVATE_KEY is not set (a protected CI/CD variable:" >&2
    echo "the job must run on a protected ref -- a release-* tag)" >&2; exit 1; }
  decode "$DEPLOY_SSH_PRIVATE_KEY" > "$work/id"
fi
chmod 600 "$work/id"
if [ -n "${DEPLOY_KNOWN_HOSTS:-}" ]; then
  decode "$DEPLOY_KNOWN_HOSTS" > "$work/known_hosts"
  hostcheck="-o StrictHostKeyChecking=yes"
else
  : > "$work/known_hosts"
  hostcheck="-o StrictHostKeyChecking=accept-new"
fi
SSH="ssh -i $work/id -o IdentitiesOnly=yes -o BatchMode=yes $hostcheck -o UserKnownHostsFile=$work/known_hosts"

echo "== the $VER release page"
python3 "$GEN" --version "$DIR" "$VER"

echo "== mirror $DIR -> $USER_@$HOST:$BASE/$VER/"
ls -l "$DIR"
# Directories 755, files read-only 444: Apache (www-data) reads them, and a
# published release is not edited in place.
rsync -rlptz --delete --chmod=D755,F444 -e "$SSH" "$DIR/" "$USER_@$HOST:$BASE/$VER/"

echo "== the releases index"
# Top-level entries of the releases directory; a version is a directory whose
# name starts with a digit. The one just mirrored is listed by now.
versions=$(rsync --list-only -e "$SSH" "$USER_@$HOST:$BASE/" \
             | awk '$1 ~ /^d/ { n=$NF; if (n ~ /^[0-9]/) print n }')
echo "releases on the server: $(echo $versions)"
case " $(echo $versions) " in *" $VER "*) ;; *) echo "the mirrored $VER is not listed" >&2; exit 1;; esac
python3 "$GEN" --root-index "$work/index.html" $versions
rsync -rlptz --chmod=F444 -e "$SSH" "$work/index.html" "$USER_@$HOST:$BASE/"

echo "mirrored -> $URL"
