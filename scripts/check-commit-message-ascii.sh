#!/bin/sh
# Is the commit message plain ASCII?
#
# windows-runner-commit-message-breaks-powershell: GitLab Runner's PowerShell
# executor writes the job environment -- CI_COMMIT_MESSAGE included -- into a
# generated .ps1 before get_sources, and under-escapes it. A message carrying
# an em dash, a backtick, a section sign or a "<...>" makes that script fail to
# PARSE, so the job dies before cloning. Worse than dying: it has been seen
# carrying on and running the job's script in the runner's own directory, where
# a target that happens to exist would do something meaningless.
#
# The real fix is a newer runner on that machine (pjb's call). The repo-side
# rule, already adopted by hand, is: A COMMIT WHOSE PIPELINE RUNS WINDOWS JOBS
# TAKES A PLAIN-ASCII MESSAGE. This is that rule, mechanically -- a rule kept
# by discipline alone is kept until the day it is forgotten, and the cost lands
# on the one platform nobody runs locally.
#
# Usage:
#   scripts/check-commit-message-ascii.sh [revision-range|commit]   (default HEAD)
#
# Checks the SUBJECT and BODY of each commit named. Exits 1 on the first
# offender, printing the line, the character and its position. In CI only HEAD
# matters -- that is what CI_COMMIT_MESSAGE carries -- but a range is accepted
# so a branch can be checked before it is pushed:
#
#   scripts/check-commit-message-ascii.sh origin/master..HEAD
set -u

range=${1:-HEAD}
case $range in
  *..*) revs=$(git log --format=%H "$range") ;;
  *)    revs=$(git log -1 --format=%H "$range") ;;
esac

if [ -z "$revs" ]; then
    echo "commit-message-ascii: no commit in '$range' -- nothing to check"
    exit 0
fi

status=0
checked=0
for rev in $revs; do
    checked=$((checked + 1))
    short=$(git log -1 --format=%h "$rev")
    # LC_ALL=C so the pattern means BYTES: a UTF-8 em dash is three bytes
    # outside the printable ASCII range, and that is exactly what the runner
    # chokes on.
    offenders=$(git log -1 --format='%B' "$rev" \
                | LC_ALL=C grep -n '[^ -~]' || true)
    if [ -n "$offenders" ]; then
        status=1
        echo "commit-message-ascii: $short has non-ASCII in its message:"
        printf '%s\n' "$offenders" | sed 's/^/    /'
        echo "    subject: $(git log -1 --format=%s "$rev")"
    fi
done

if [ $status -ne 0 ]; then
    cat <<'EOF'

commit-message-ascii: rewrite the message(s) in plain ASCII -- hyphens instead
of em dashes, "section 11" instead of a section sign, straight quotes, no
backticks. The Windows runner's PowerShell executor turns CI_COMMIT_MESSAGE
into code and fails to parse it, killing the job before it clones (and, once,
running its script in the runner's own directory instead).
See issues/open/windows-runner-commit-message-breaks-powershell.issue --
the real fix is the runner version, this is the rule until then.
EOF
    exit 1
fi

echo "commit-message-ascii: $checked commit message(s) are plain ASCII"
exit 0
