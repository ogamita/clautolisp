#!/bin/sh
# Fail if the PARENT pipeline gates a job on a variable that only exists as a
# dotenv artefact.
#
# GitLab evaluates `rules:' at PIPELINE CREATION, before any job runs, so a
# variable published by a job (detect:runners writes MACOS_RUNNER /
# WINDOWS_RUNNER into a dotenv report) is NOT DEFINED when rules are read.
# A rule testing it is never true, and if the fallback is `when: never' the
# job is silently not created at all.
#
# That is not a hypothetical: on release-1.8.43 it removed
# release:windows:x86-64 and release:darwin:arm64 from the tag pipeline
# WHILE BOTH MACHINES WERE ONLINE -- detect:runners reported
# WINDOWS_RUNNER=online in the very same pipeline -- and the release simply
# came out missing two platforms. Nothing failed; that is what makes it
# worth a check.
#
# The CHILD pipeline (.gitlab/native.yml) may use them freely: the parent
# passes them as TRIGGER VARIABLES, which are known when the child is
# created. So this checks the parent file only.
#
#   sh scripts/check-ci-dotenv-rules.sh
set -e

ci=${1:-.gitlab-ci.yml}
[ -f "$ci" ] || { echo "FAIL: $ci not found"; exit 1; }

# Variables produced by a dotenv report in this pipeline. Derived from the
# `dotenv:' declarations rather than hard-coded, so a new one is covered
# without editing this script.
dotenv_files=$(sed -n 's/.*dotenv:[[:space:]]*\(.*\)/\1/p' "$ci" | tr -d '"' | sort -u)
[ -n "$dotenv_files" ] || { echo "no dotenv reports in $ci -- nothing to check"; exit 0; }

# The names those files carry: read them out of the script that writes them.
vars=""
for f in $dotenv_files; do
    for producer in scripts/ci-detect-runners.py; do
        [ -f "$producer" ] || continue
        vars="$vars $(sed -n 's/.*[("]\([A-Z][A-Z0-9_]*_RUNNER\)[")].*/\1/p' "$producer" | sort -u)"
    done
done
vars=$(printf '%s\n' $vars | sort -u)
[ -n "$vars" ] || { echo "no dotenv variable names found -- the extractor needs updating, not deleting"; exit 1; }

status=0
for v in $vars; do
    # Every `if:' line of the parent that mentions the variable.
    hits=$(grep -n "^[[:space:]]*-\{0,1\}[[:space:]]*if:.*\$$v\b" "$ci" || true)
    if [ -n "$hits" ]; then
        echo "FAIL: $ci gates a job on \$$v, which is a DOTENV variable:"
        echo "$hits" | sed 's/^/    /'
        echo "      rules: are evaluated at pipeline creation, before"
        echo "      detect:runners runs, so this condition is never true."
        echo "      Pass it to a child pipeline as a trigger variable, or"
        echo "      use a variable set when the pipeline is created."
        status=1
    fi
done

[ $status -eq 0 ] && echo "ci rules: no parent job gated on a dotenv variable"
exit $status
