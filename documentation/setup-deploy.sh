#!/bin/sh
# setup-deploy.sh — provision the poseidon-side plumbing for the GitLab CI
# `deploy:documentation` job (see .gitlab-ci.yml and poseidon-deploy.md).
#
# Run this ONCE on poseidon, as root (sudo). It is idempotent: re-running
# refreshes the dirs/authorized_keys and (only if missing) the key pair.
#
# It creates:
#   * an unprivileged system account `clautolisp-deploy`
#   * the web dir  /var/www/poseidon/public_html/ogamita/autolisp-spec
#     (owned clautolisp-deploy:www-data, setgid, so Apache reads what the
#      deploy account writes)
#   * an SSH key pair whose public half is installed as an rrsync
#     FORCED-COMMAND authorized_keys entry — the key can ONLY rsync into
#     that one directory (no shell, no other path, no forwarding)
#
# It then self-tests the exact rsync the CI job runs, and prints the two
# values to paste into GitLab > Settings > CI/CD > Variables (protected):
#     DEPLOY_SSH_PRIVATE_KEY   (File type recommended)
#     DEPLOY_KNOWN_HOSTS       (File type recommended)
set -eu

DEPLOY_USER=clautolisp-deploy
DEPLOY_HOME=/var/lib/clautolisp-deploy
WEBROOT=/var/www/poseidon/public_html
TARGET="$WEBROOT/ogamita/autolisp-spec"
PUBHOST=poseidon.informatimago.com
RRSYNC=/usr/bin/rrsync
KEYDIR="$DEPLOY_HOME/.ssh"
KEYFILE="$KEYDIR/id_clautolisp_ci"          # private key kept here, root-readable
AUTHKEYS="$KEYDIR/authorized_keys"

[ "$(id -u)" = 0 ] || { echo "run as root (sudo $0)" >&2; exit 1; }
command -v "$RRSYNC" >/dev/null || { echo "rrsync not found at $RRSYNC (apt install rsync)" >&2; exit 1; }

echo "== 1. deploy account =="
if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
    useradd --system --create-home --home-dir "$DEPLOY_HOME" --shell /bin/bash "$DEPLOY_USER"
    echo "created $DEPLOY_USER"
else
    echo "$DEPLOY_USER already exists"
fi

echo "== 2. web dirs =="
install -d -o www-data          -g www-data -m 0755 "$WEBROOT/ogamita"
install -d -o "$DEPLOY_USER"    -g www-data -m 2755 "$TARGET"
ls -ld "$WEBROOT/ogamita" "$TARGET"

echo "== 3. SSH key + rrsync-restricted authorized_keys =="
install -d -o "$DEPLOY_USER" -g "$DEPLOY_USER" -m 0700 "$KEYDIR"
if [ ! -f "$KEYFILE" ]; then
    ssh-keygen -t ed25519 -N '' -C 'clautolisp-ci-deploy@gitlab' -f "$KEYFILE"
    chown "$DEPLOY_USER:$DEPLOY_USER" "$KEYFILE" "$KEYFILE.pub"
    echo "generated $KEYFILE"
else
    echo "$KEYFILE already exists — keeping it"
fi
# Forced command: this key may only rsync into $TARGET. `restrict` disables
# pty + all forwarding. rrsync chroots the session to $TARGET, so the CI
# job rsyncs to "<user>@host:" (empty path == the restricted root).
printf 'command="%s %s",restrict %s\n' "$RRSYNC" "$TARGET" "$(cat "$KEYFILE.pub")" > "$AUTHKEYS"
chown "$DEPLOY_USER:$DEPLOY_USER" "$AUTHKEYS"
chmod 0600 "$AUTHKEYS"

echo "== 4. self-test (the exact rsync the CI job runs) =="
probe="$(mktemp -d)"; trap 'rm -rf "$probe"' EXIT
echo "deploy-selftest $(date -u +%FT%TZ)" > "$probe/.deploy-selftest"
SSH="ssh -i $KEYFILE -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$probe/known_hosts -o BatchMode=yes"
# Push a probe file in, confirm it lands in $TARGET, then remove it.
rsync -rlptz -e "$SSH" "$probe/.deploy-selftest" "$DEPLOY_USER@localhost:"
if [ -f "$TARGET/.deploy-selftest" ]; then
    echo "OK — probe reached $TARGET"
    rm -f "$TARGET/.deploy-selftest"
else
    echo "FAILED — probe did not reach $TARGET" >&2; exit 1
fi

echo
echo "============================================================"
echo "Set these GitLab CI/CD variables (Settings > CI/CD > Variables,"
echo "scope: protected; File type recommended for both):"
echo
echo "------ DEPLOY_SSH_PRIVATE_KEY ------------------------------"
cat "$KEYFILE"
echo "------ DEPLOY_KNOWN_HOSTS ----------------------------------"
ssh-keyscan -t ed25519,rsa,ecdsa "$PUBHOST" 2>/dev/null
echo "------------------------------------------------------------"
echo "Done. The deploy:documentation job will publish to"
echo "  http://$PUBHOST/ogamita/autolisp-spec/"
