#!/bin/sh
# Fail if a release:* job's artefacts never reach collect:release.
#
# GitLab's `needs:' names jobs one by one, so adding a platform means
# adding a release:<os>:<arch> job AND remembering to list it in
# collect:release. Forgetting the second half costs a full build whose
# output is then discarded without a word -- which is exactly what
# happened to release:linux:arm32 (release-artefact-set-incomplete.issue).
#
# pjb, 2026-08-16, asked for the artefact set to cover "tout autre
# binaires que nous pourrions builder a l'avenir avec des runners
# supplementaires". Nothing can make `needs:' a glob, so this makes the
# omission LOUD instead: a new release job that is not collected fails
# the pipeline that introduces it.
#
#   sh scripts/check-release-collect-needs.sh
#   make check-release-collect-needs
set -e

ci=${1:-.gitlab-ci.yml}

[ -f "$ci" ] || { echo "FAIL: $ci not found"; exit 1; }

# Every top-level job whose name starts with release: (top-level == no
# leading whitespace, trailing colon).
jobs=$(sed -n 's/^\(release:[A-Za-z0-9:_-]*\):[[:space:]]*$/\1/p' "$ci" | sort -u)

[ -n "$jobs" ] || { echo "FAIL: no release:* jobs found in $ci -- the parser needs updating, not deleting"; exit 1; }

# collect:release's needs block: from the job header to the next
# top-level key, keeping the job names it mentions.
needs=$(sed -n '/^collect:release:[[:space:]]*$/,/^[A-Za-z]/p' "$ci" \
        | sed -n 's/.*job:[[:space:]]*"\{0,1\}\(release:[A-Za-z0-9:_-]*\)"\{0,1\}.*/\1/p' \
        | sort -u)

status=0
for j in $jobs; do
    if echo "$needs" | grep -qx "$j"; then
        echo "ok  $j is collected"
    else
        echo "FAIL: $j builds artefacts that collect:release never receives."
        echo "      Add it to collect:release's needs: in $ci, or delete the job."
        status=1
    fi
done

# The converse: a needs: entry naming a job that no longer exists would
# make the whole pipeline fail at parse time on GitLab, but say so here
# rather than after pushing a tag.
for n in $needs; do
    echo "$jobs" | grep -qx "$n" || {
        echo "FAIL: collect:release needs $n, which is not a job in $ci"
        status=1
    }
done

[ $status -eq 0 ] && echo "release collection: every release:* job is collected"
exit $status
