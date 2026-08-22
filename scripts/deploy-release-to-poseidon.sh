#!/usr/bin/env bash
# Mirror a clautolisp release's collect:release artefacts to the poseidon web
# download area (https://poseidon.informatimago.com/ogamita/clautolisp/releases/
# <ver>/) and regenerate the index pages. Run ON poseidon (needs sudo to the
# www tree); make-gitlab-release.py then points the GitLab Release links here.
#
#   GITLAB_TOKEN=<api token> bash scripts/deploy-release-to-poseidon.sh release-1.9.3
#
# Env: GITLAB_TOKEN (api scope; falls back to ~claude/.authinfo port claude),
#      WEBROOT (default /var/www/poseidon/public_html/ogamita/clautolisp/releases).
set -euo pipefail
TAG="${1:?usage: $0 release-X.Y.Z}"; VER="${TAG#release-}"
API=https://gitlab.com/api/v4; PID=80415300
WEBROOT="${WEBROOT:-/var/www/poseidon/public_html/ogamita/clautolisp/releases}"
GEN="$(cd "$(dirname "$0")" && pwd)/gen-release-index.py"
T="${GITLAB_TOKEN:-$(awk '{p=pw="";for(i=1;i<=NF;i++){if($i=="port")p=$(i+1);if($i=="password")pw=$(i+1)} if(p=="claude")print pw}' ~claude/.authinfo 2>/dev/null || true)}"
[ -n "$T" ] || { echo "no GITLAB_TOKEN"; exit 1; }
gl(){ curl -fsSL --header "PRIVATE-TOKEN: $T" "$@"; }  # -L: the artefacts endpoint 302s to the CDN

plid=$(gl "$API/projects/$PID/pipelines?ref=$TAG&per_page=1" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d[0]["id"] if d else "")')
[ -n "$plid" ] || { echo "no pipeline for $TAG"; exit 1; }
jid=$(gl "$API/projects/$PID/pipelines/$plid/jobs?per_page=100" | python3 -c 'import sys,json
r=[j for j in json.load(sys.stdin) if j["name"]=="collect:release" and j["status"]=="success"]
print(r[0]["id"] if r else "")')
[ -n "$jid" ] || { echo "collect:release for $TAG not success yet"; exit 1; }
echo "pipeline $plid, collect:release job $jid"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
gl -o "$tmp/art.zip" "$API/projects/$PID/jobs/$jid/artifacts"
( cd "$tmp" && unzip -q art.zip )
src="$tmp/dist/combined"; [ -d "$src" ] || { echo "no dist/combined in artefacts"; exit 1; }
echo "archives:"; ls -1 "$src" | sed 's/^/  /'

sudo install -d -o www-data -g www-data "$WEBROOT/$VER"
sudo rsync -a --delete --chown=www-data:www-data "$src"/ "$WEBROOT/$VER"/
sudo python3 "$GEN" "$WEBROOT"
sudo chown -R www-data:www-data "$WEBROOT"
echo "mirrored -> https://poseidon.informatimago.com/ogamita/clautolisp/releases/$VER/"
