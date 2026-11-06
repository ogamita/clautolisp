#!/usr/bin/env bash
# Mirror a LOCALLY collected clautolisp release set to the poseidon web
# download area (https://poseidon.informatimago.com/ogamita/clautolisp/
# releases/<ver>/) and regenerate the index pages. Run ON poseidon, as a
# sender of the release-ogamita account (claude, runners: their
# ~/.ssh/release-ogamita key; documentation/setup-deploy.sh). No sudo.
#
#   bash scripts/deploy-release-to-poseidon.sh release-2.3.0 --from DIR
#
# Since collect-release-artefact-exceeds-gitlab-size-limit (option 3, pjb
# 2026-10-24) collect:release mirrors every release ITSELF, and its GitLab
# artefact keeps only the manifest and the release page -- so there is no
# artefact set left to download, and this script only takes --from: DIR is
# a dist/combined holding manifest-release-assets.txt, collected by hand
# (`make collect-artefacts` on the tag's release-job artefacts plus the GitHub
# Windows run, as collect:release does) -- for re-mirroring a release, or one
# whose CI mirror failed. It runs the same mirror as the job
# (scripts/mirror-release-to-poseidon.sh).
#
# Env: RELEASE_DEPLOY_KEY_FILE (default ~/.ssh/release-ogamita),
#      DEPLOY_HOST (default localhost).
set -euo pipefail
TAG="${1:?usage: $0 release-X.Y.Z --from DIR}"; VER="${TAG#release-}"
[ "${2:-}" = "--from" ] || {
  echo "usage: $0 release-X.Y.Z --from DIR" >&2
  echo "collect:release mirrors each release itself now; its artefact holds only" >&2
  echo "the manifest, so there is nothing to download (and mirroring it with" >&2
  echo "--delete would empty the release directory)." >&2
  exit 2; }
FROM="${3:?--from needs a directory}"
export RELEASE_DEPLOY_KEY_FILE="${RELEASE_DEPLOY_KEY_FILE:-$HOME/.ssh/release-ogamita}"
export DEPLOY_HOST="${DEPLOY_HOST:-localhost}"
exec bash "$(cd "$(dirname "$0")" && pwd)/mirror-release-to-poseidon.sh" "$VER" "$FROM"
