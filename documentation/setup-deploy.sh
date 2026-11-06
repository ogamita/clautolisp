#!/bin/sh
# setup-deploy.sh — provision the poseidon account that receives the
# ogamita web artefacts: the spec manual (deploy:documentation) and the
# release sets (collect:release, scripts/mirror-release-to-poseidon.sh).
# See poseidon-deploy.md.
#
# Run this on poseidon, as root (sudo). It is idempotent.
#
# pjb, 2026-10-24: one account, release-ogamita, owns
# /var/www/poseidon/public_html/ogamita (group www-data); its authorized_keys
# holds the keys of those who send artefacts there -- only senders ON
# poseidon: the GitLab runners (their CI deploy key) and the claude account.
# Directories are 755, files 644, release archives 444 (read-only).
#
# Each key is an rrsync FORCED COMMAND chrooted to the ogamita tree: it can
# rsync there and nothing else -- no shell, no other path, no forwarding.
# A sender addresses paths RELATIVE to that tree (autolisp-spec/,
# clautolisp/releases/<version>/).
#
# KEYS lists the senders' PUBLIC keys (files). The private half of the CI
# runners' key is the DEPLOY_SSH_PRIVATE_KEY CI/CD variable (base64, File
# type, protected + masked); this script never reads nor prints a private
# key. A missing public key is an error, not a silent skip.
set -eu

ACCOUNT=release-ogamita
ACCOUNT_HOME=/var/lib/release-ogamita
WEB=/var/www/poseidon/public_html/ogamita
RELEASES="$WEB/clautolisp/releases"
RRSYNC=/usr/bin/rrsync
KEYS="${KEYS:?KEYS: the senders' public key files (the CI runners' key, claude's)}"

[ "$(id -u)" = 0 ] || { echo "run as root (sudo $0)" >&2; exit 1; }
command -v "$RRSYNC" >/dev/null || { echo "rrsync not found at $RRSYNC (apt install rsync)" >&2; exit 1; }
for key in $KEYS; do
    [ -f "$key" ] || { echo "no public key $key" >&2; exit 1; }
    case "$(head -c 30 "$key")" in
        ssh-*) ;;
        *) echo "$key is not a public key" >&2; exit 1 ;;
    esac
done

echo "== 1. the account =="
if ! id "$ACCOUNT" >/dev/null 2>&1; then
    useradd --system --create-home --home-dir "$ACCOUNT_HOME" --shell /bin/sh "$ACCOUNT"
    echo "created $ACCOUNT"
else
    echo "$ACCOUNT already exists"
fi

echo "== 2. authorized_keys: one rrsync-restricted entry per sender =="
install -d -o "$ACCOUNT" -g "$ACCOUNT" -m 0700 "$ACCOUNT_HOME/.ssh"
for key in $KEYS; do
    printf 'command="%s %s",restrict %s\n' "$RRSYNC" "$WEB" "$(cat "$key")"
done > "$ACCOUNT_HOME/.ssh/authorized_keys"
chown "$ACCOUNT:$ACCOUNT" "$ACCOUNT_HOME/.ssh/authorized_keys"
chmod 0600 "$ACCOUNT_HOME/.ssh/authorized_keys"
awk '{print "  " $NF}' "$ACCOUNT_HOME/.ssh/authorized_keys"

echo "== 3. the ogamita tree: $ACCOUNT:www-data, 755 / 644, releases 444 =="
chown -R "$ACCOUNT:www-data" "$WEB"
find "$WEB" -type d -exec chmod 00755 {} +
find "$WEB" -type f -exec chmod 0644 {} +
if [ -d "$RELEASES" ]; then find "$RELEASES" -type f -exec chmod 0444 {} +; fi
ls -ld "$WEB" "$WEB"/*

echo
echo "Done. Senders rsync to $ACCOUNT@poseidon.informatimago.com:<path under"
echo "$WEB>, e.g. autolisp-spec/ or clautolisp/releases/<version>/."
