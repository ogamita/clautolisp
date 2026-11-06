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
# It checks a second thing, learned the hard way (see below): every job
# the collect needs must be scheduled AUTOMATICALLY on a release tag.
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

# Jobs whose artefacts reach collect:release OUT OF BAND -- not through a
# GitLab `needs:'. release:windows:x86-64 is built on GitHub Actions (the
# CAD-free Windows build host, windows-build-host.issue / !129) and pulled by
# collect:release with `gh run download'; the GitLab job of that name is only a
# 100%-manual fallback on the self-hosted PC. So it is intentionally NOT a need,
# and intentionally NOT automatic on a tag -- both checks below skip it.
collected_offband="release:windows:x86-64"
is_offband() { echo "$collected_offband" | tr ' ' '\n' | grep -qx "$1"; }

# collect:release's needs block: from the job header to the next
# top-level key, keeping the job names it mentions.
needs=$(sed -n '/^collect:release:[[:space:]]*$/,/^[A-Za-z]/p' "$ci" \
        | sed -n 's/.*job:[[:space:]]*"\{0,1\}\(release:[A-Za-z0-9:_-]*\)"\{0,1\}.*/\1/p' \
        | sort -u)

status=0
for j in $jobs; do
    if is_offband "$j"; then
        echo "ok  $j is collected out-of-band (GitHub Actions -> gh run download)"
        continue
    fi
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

# Every job collect:release needs must START BY ITSELF on a release tag.
#
# `optional: true' does NOT make a manual job safe to need. GitLab SKIPS
# the dependent job when one of its needs is a manual job that nobody
# played: `optional' covers a need that is ABSENT from the pipeline, not
# one that is PRESENT BUT UNPLAYED. That distinction cost two releases --
# 1.8.43 published nothing, and 1.8.47's collect was skipped until the
# arm32 job was played by hand -- because the earlier version of this
# check asserted the opposite and passed.
#
# So the rule is now the direct one: a release job must carry a
# release-tag rule (one of the *on-release-* anchors), which schedules it
# automatically on a tag. A lane that is only ever manual has no business
# being a need of the collect.
for j in $jobs; do
    if is_offband "$j"; then
        echo "ok  $j is manual-only by design (GitHub builds the release Windows set)"
        continue
    fi
    body=$(sed -n "/^$j:[[:space:]]*$/,/^[A-Za-z]/p" "$ci")
    rules=$(printf '%s' "$body" | sed -n '/^[[:space:]]*rules:/,$p')

    if [ -z "$rules" ]; then
        echo "ok  $j has no rules -- it runs on every pipeline"
        continue
    fi

    if printf '%s' "$rules" | grep -q '\*on-release'; then
        echo "ok  $j starts by itself on a release tag"
    else
        echo "FAIL: $j has no release-tag rule, so on a tag it is manual-only."
        echo "      collect:release needs it, and GitLab SKIPS a job whose need"
        echo "      is an unplayed manual job -- optional: true does NOT help,"
        echo "      it only covers a need that is absent from the pipeline."
        echo "      Give it an *on-release-* rule (with a SKIP_<PLATFORM>_RELEASE"
        echo "      opt-out if its runner is intermittent)."
        status=1
    fi
done

[ $status -eq 0 ] && echo "release collection: every release:* job is collected"
exit $status
