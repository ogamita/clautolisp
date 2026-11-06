#!/bin/sh
# POSIX sh — audit the repository against the shared version rules:
# https://gitlab.com/informatimago/rules/-/blob/master/version-rules.md
#
# Checks the topological invariants: I1 (release-* is a tag-only
# namespace, tags annotated), I3 (ancestry order within a series),
# I5 (version-* pointers sit exactly on the newest release), I6
# (maint-* carries its series), I7 (no orphaned release). I2, I4 and
# I8 are policy rather than topology — see version-rules.md § 6.
#
# Project-independent: it reads nothing but git refs and, if present, the
# project's accepted-exceptions list (see below). Drop it into any
# project that follows the rules (usually as scripts/check-versions.sh,
# wired to a `make check-versions' target) and run it from the top of a
# work tree. The canonical copy lives in the rules repository above;
# fix it there, then re-vendor.
#
# Exits non-zero if any invariant is violated; prints one line per
# check. Read-only: never creates, moves or deletes a ref.
#
# A violation the project has decided to live with — an immutable
# published ref it will not rewrite — can be declared as an ACCEPTED
# EXCEPTION, reported as `xfail' with its reason instead of failing the
# run (see the exceptions block below). An audit that is always red is
# not a gate: nobody reads it, and the next real violation goes unseen.
#
# Scope: the local repository. Remote-tracking refs (origin/*) are used
# for the branch checks when they exist, so a stale local checkout does
# not produce false failures; run `git fetch --prune --tags` first.
# The trunk may be called `master' or `main'.

set -u

fail=0
accepted=0
stale=0

# --- accepted exceptions (project-local) ------------------------------
# A violation a project has DECIDED to live with — always an immutable
# published ref it will not rewrite — is declared in the exceptions file
# (scripts/version-audit-exceptions.txt by default, $VERSION_AUDIT_EXCEPTIONS
# to override, relative to the top of the work tree). One per line:
#
#     <glob matched against the check's message>  # why it is accepted
#
# A matched violation is reported as `xfail' with its reason and does NOT
# fail the run; everything else still does, so the audit keeps its value
# as a gate. The reason is REQUIRED — an exception nobody can justify is
# not an exception. An exception that matches NOTHING is reported as
# `stale' and FAILS, so the list cannot rot silently once the underlying
# situation is resolved (version-rules.md § 6: the published-ref rule is
# what makes a permanent exception legitimate at all).
exceptions_file=${VERSION_AUDIT_EXCEPTIONS:-scripts/version-audit-exceptions.txt}
exception_hits=' '
exception_reason=''

exception_match() {          # $1 = message; sets exception_reason on a hit
    _msg=$1
    _i=0
    exception_reason=''
    [ -f "$exceptions_file" ] || return 1
    while IFS= read -r _line; do
        _i=$((_i + 1))
        case $_line in ''|'#'*) continue ;; esac
        _pat=${_line%%'#'*}
        _pat=$(printf '%s' "$_pat" | sed 's/[[:space:]]*$//')
        [ -n "$_pat" ] || continue
        # shellcheck disable=SC2254  # the pattern is meant to glob
        case $_msg in
            $_pat)
                case $_line in
                    *'#'*) exception_reason=$(printf '%s' "${_line#*'#'}" \
                                              | sed 's/^[[:space:]]*//') ;;
                    *)     exception_reason='' ;;
                esac
                exception_hits="$exception_hits$_i "
                return 0 ;;
        esac
    done < "$exceptions_file"
    return 1
}

note() { printf '  %s\n' "$*"; }
ok()   { printf 'ok    %s\n' "$*"; }
bad()  {
    if exception_match "$*"; then
        printf 'xfail %s\n' "$*"
        if [ -n "$exception_reason" ]; then
            printf '        accepted: %s\n' "$exception_reason"
            accepted=$((accepted + 1))
        else
            printf '        accepted WITHOUT A REASON in %s — say why\n' \
                   "$exceptions_file"
            fail=$((fail + 1))
        fi
    else
        printf 'FAIL  %s\n' "$*"
        fail=$((fail + 1))
    fi
}

# --- inventory --------------------------------------------------------
# Release tags: release-M.m.d, excluding pre-releases (-rcN).
releases=$(git tag --list 'release-*' \
           | grep -E '^release-[0-9]+\.[0-9]+\.[0-9]+$' \
           | sort -t. -k1,1V -k2,2n -k3,3n)

if [ -z "$releases" ]; then
    bad "I1: no release-M.m.d tags found"
    exit 1
fi

series=$(echo "$releases" | sed -e 's/^release-//' -e 's/\.[0-9]*$//' | sort -u -V)
majors=$(echo "$series" | cut -d. -f1 | sort -u -V)

# A branch ref, preferring origin/ when present.
branch_sha() {
    git rev-parse --verify -q "refs/remotes/origin/$1" 2>/dev/null \
        || git rev-parse --verify -q "refs/heads/$1" 2>/dev/null
}
has_branch() { [ -n "$(branch_sha "$1")" ]; }

# Newest release tag of a series (highest d).
newest_of_series() {
    echo "$releases" | grep -E "^release-$1\.[0-9]+$" | sort -t. -k3,3n | tail -1
}

# --- I1: release-* is a tag-only namespace ---------------------------
stray=$(git for-each-ref --format='%(refname:short)' \
            'refs/heads/release-*' 'refs/remotes/origin/release-*' \
        | sed 's|^origin/||' | sort -u)
if [ -n "$stray" ]; then
    bad "I1: branches in the release-* namespace (reserved for tags)"
    for b in $stray; do note "$b"; done
else
    ok "I1: release-* is tags only"
fi

for t in $releases; do
    if [ "$(git cat-file -t "$t" 2>/dev/null)" != tag ]; then
        bad "I1: $t is not an annotated tag"
    fi
done

# --- I3: ancestry order within each series ---------------------------
for s in $series; do
    prev=""
    for t in $(echo "$releases" | grep -E "^release-$s\.[0-9]+$" | sort -t. -k3,3n); do
        if [ -n "$prev" ]; then
            if ! git merge-base --is-ancestor "$prev^{commit}" "$t^{commit}"; then
                bad "I3: $prev is not an ancestor of $t (same series)"
            fi
        fi
        prev=$t
    done
done
[ $fail -eq 0 ] && ok "I3: releases ordered by ancestry within every series"

# --- I5: pointers sit exactly on the newest release ------------------
for s in $series; do
    newest=$(newest_of_series "$s")
    want=$(git rev-parse "$newest^{commit}")
    if has_branch "version-$s"; then
        got=$(branch_sha "version-$s")
        if [ "$got" = "$want" ]; then
            ok "I5: version-$s == $newest"
        else
            bad "I5: version-$s is at $(echo "$got" | cut -c1-8), expected $newest ($(echo "$want" | cut -c1-8))"
        fi
    else
        bad "I5: version-$s is missing (newest release of the series: $newest)"
    fi
done

for M in $majors; do
    top=$(echo "$series" | grep -E "^$M\." | sort -V | tail -1)
    newest=$(newest_of_series "$top")
    want=$(git rev-parse "$newest^{commit}")
    if has_branch "version-$M"; then
        got=$(branch_sha "version-$M")
        if [ "$got" = "$want" ]; then
            ok "I5: version-$M == $newest"
        else
            bad "I5: version-$M is at $(echo "$got" | cut -c1-8), expected $newest ($(echo "$want" | cut -c1-8))"
        fi
    else
        bad "I5: version-$M is missing (newest release of major $M: $newest)"
    fi
done

# --- I6: maintenance lines carry their series ------------------------
for s in $series; do
    has_branch "maint-$s" || continue
    tip=$(branch_sha "maint-$s")
    for t in $(echo "$releases" | grep -E "^release-$s\.[0-9]+$"); do
        if ! git merge-base --is-ancestor "$t^{commit}" "$tip"; then
            bad "I6: maint-$s does not contain $t"
        fi
    done
    ok "I6: maint-$s contains every release-$s.*"
done

# --- I7: no orphaned release -----------------------------------------
lines=$(git for-each-ref --format='%(refname)' \
            'refs/heads/master' 'refs/remotes/origin/master' \
            'refs/heads/main' 'refs/remotes/origin/main' \
            'refs/heads/maint-*' 'refs/remotes/origin/maint-*' \
            'refs/heads/dev-*' 'refs/remotes/origin/dev-*')
for t in $releases; do
    c=$(git rev-parse "$t^{commit}")
    found=no
    for l in $lines; do
        if git merge-base --is-ancestor "$c" "$l" 2>/dev/null; then found=yes; break; fi
    done
    [ "$found" = yes ] || bad "I7: $t is not reachable from the trunk or any maint-*/dev-* line"
done
ok "I7: every release is reachable from a development line"

# --- informational: deprecated tag formats (version-rules.md § 3.2) ---
# Not a violation: existing vM.m.d / <program>-vA.B.C tags are published
# refs and stay. Reported so nobody starts creating them again.
legacy=$(git tag --list | grep -v '^release-' \
         | grep -Ec '^(v[0-9]|[a-z][a-z0-9-]*-v?[0-9])' || true)
[ "${legacy:-0}" -gt 0 ] && \
    printf 'note  %s tag(s) in a deprecated format (vM.m.d, <program>-vA.B.C) — kept, but create no more\n' "$legacy"

# --- stale exceptions -------------------------------------------------
# An exception that matched nothing is itself a finding: the situation it
# covers is gone, so the line must go too — otherwise the list grows into
# a blanket that hides the next real violation.
if [ -f "$exceptions_file" ]; then
    i=0
    while IFS= read -r line; do
        i=$((i + 1))
        case $line in ''|'#'*) continue ;; esac
        pat=${line%%'#'*}
        pat=$(printf '%s' "$pat" | sed 's/[[:space:]]*$//')
        [ -n "$pat" ] || continue
        case $exception_hits in
            *" $i "*) ;;
            *) printf 'stale %s:%s: exception matched nothing — %s\n' \
                      "$exceptions_file" "$i" "$pat"
               stale=$((stale + 1))
               fail=$((fail + 1)) ;;
        esac
    done < "$exceptions_file"
fi

# --- summary ----------------------------------------------------------
printf '\n'
if [ $fail -eq 0 ]; then
    printf 'check-versions: %s releases, %s series — all invariants hold' \
           "$(echo "$releases" | wc -l | tr -d ' ')" \
           "$(echo "$series"   | wc -l | tr -d ' ')"
    if [ $accepted -gt 0 ]; then
        printf ' (%s accepted exception(s) in %s).\n' \
               "$accepted" "$exceptions_file"
    else
        printf '.\n'
    fi
    exit 0
fi
printf 'check-versions: %s violation(s)' "$fail"
[ $accepted -gt 0 ] && printf ', %s accepted exception(s)' "$accepted"
[ $stale -gt 0 ]    && printf ', %s stale exception(s)' "$stale"
printf ' — see\n  %s\n' \
       "https://gitlab.com/informatimago/rules/-/blob/master/version-rules.md"
exit 1
