#!/usr/bin/env bash
#
# run-probes.sh PRODUCT
#
# READ FIRST if anything here misbehaves against a real CAD:
#   documentation/accoreconsole-headless-autolisp.org
#
# It documents the traps this script exists inside -- MSYS2 rewriting the
# /s switch, the CRLF requirement, SECURELOAD, the mandatory ._QUIT, and
# why results must come from a FILE rather than stdout or an exit code.
# Five consecutive failures here were three of those, each invisible
# until the previous one was fixed.
#
# Run the probe suite (probes/sources/manifest.txt) inside PRODUCT
# (autocad | bricscad | clautolisp), writing one record per line to a
# committed results file:
#
#   probe-results/<product>/<platform>/<timestamp>/results.sexp
#
# The runner command is taken from $RUNNER_TEMPLATE if set, otherwise
# from probes/scripts/detect-cad.sh PRODUCT (which honours the
# AUTOCAD_*/BRICSCAD_*/CLAUTOLISP_* overrides). Unless PROBE_NO_COMMIT
# is set, the results file + metadata are git-added and committed (never
# pushed) so they can be handed back for processing.
#
# Usage is normally indirect, via the top-level Makefile:
#   make probe                 # auto-detect a CAD, else clautolisp
#   make probe-autocad
#   make probe-bricscad
#   make probe-clautolisp      # headless baseline column

set -euo pipefail

product="${1:?usage: run-probes.sh <autocad|bricscad|clautolisp>}"

probes_dir="$(cd "$(dirname "$0")/.." && pwd)"
repo_root="$(cd "$probes_dir/.." && pwd)"
sources_dir="$probes_dir/sources"
manifest="$sources_dir/manifest.txt"

# PROBE_SUITES: run only these manifest entries, space- or
# comma-separated, matched against the source file name with or without
# the `probe-' prefix and the `.lsp' suffix -- so PROBE_SUITES=foreach-scope
# and PROBE_SUITES=probe-foreach-scope.lsp both work. Default: every suite.
#
# It exists because the suite was ALL-OR-NOTHING on an engine: one suite
# that kills the CAD takes every other answer down with it, and there was
# no way to ask the one question you came for. That is exactly what
# happened the first time this suite met BricsCAD.
suite_wanted() {
  local src="$1" want name
  [[ -z "${PROBE_SUITES:-}" ]] && return 0
  name="${src%.lsp}"; name="${name#probe-}"
  for want in ${PROBE_SUITES//,/ }; do
    want="${want%.lsp}"; want="${want#probe-}"
    [[ "$name" == "$want" ]] && return 0
  done
  return 1
}

[[ -f "$manifest" ]] || { echo "run-probes: missing $manifest" >&2; exit 2; }

platform="ms-windows"
case "$(uname -s 2>/dev/null || echo unknown)" in
  Darwin) platform="macos" ;;
  Linux)  platform="linux" ;;
  MINGW*|MSYS*|CYGWIN*) platform="ms-windows" ;;
  *) [[ "${OS:-}" == "Windows_NT" ]] && platform="ms-windows" || platform="unknown" ;;
esac

# Resolve the runner command template.
runner_template="${RUNNER_TEMPLATE:-}"
if [[ -z "$runner_template" ]]; then
  runner_template="$(bash "$probes_dir/scripts/detect-cad.sh" "$product")" || {
    echo "run-probes: could not locate a runner for '$product'." >&2
    echo "Pass one explicitly, e.g.:" >&2
    echo "  make probe-$product RUNNER_TEMPLATE='\"/path/to/engine\" /s __SCRIPT_FILE__'" >&2
    exit 3
  }
fi

timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
run_rel="probe-results/$product/$platform/$timestamp"
run_dir="$repo_root/$run_rel"
result_file="$run_dir/results.sexp"
metadata_file="$run_dir/metadata.json"
wrapper_file="$run_dir/run-probes.lsp"
script_file="$run_dir/run-probes.scr"

mkdir -p "$run_dir"

lisp_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# A path that a NATIVE CAD can open, from a path this shell understands.
#
# Under MSYS2 the two are not the same, and the difference is invisible
# until it costs a probe run.  MSYS2 converts POSIX paths in process
# ARGUMENTS at the boundary -- which is why accoreconsole found the .scr
# passed as `/s /c/Users/...' -- but it cannot convert a path written
# INSIDE a file.  A generated (load "/c/Users/.../run-probes.lsp") is
# therefore handed verbatim to AutoCAD, which has no such directory, and
# the load fails silently: a failed load inside a .scr is not a process
# failure, so accoreconsole exits 0 and the result file is simply EMPTY.
#
# That is exactly how the 2026-08-16 AutoCAD run failed -- engine banner,
# clean exit, no results, no error naming a path.
#
# cygpath -m gives the mixed form (C:/Users/...): a Windows path with
# forward slashes, which AutoLISP takes without the backslash escaping a
# native form would need.  Identity anywhere but MSYS2/Cygwin.
cad_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -m "$1"
    else
        printf '%s' "$1"
    fi
}

# A path for the engine's COMMAND LINE, which is not the same thing.
#
# Inside a Lisp file the mixed form (C:/Users/...) is right: forward
# slashes need no escaping in a string. On a command line it is wrong for
# accoreconsole, which scans its arguments for `/letter' switches -- so
# C:/Users/PPBN02261/works/... offers it /U, /P, /w and more, none of
# which it knows, and it answers by printing its USAGE and ignoring the
# script. That is what pjb's three failed runs did.
#
# The native form (C:\Users\...) has no slashes to misread. Quoted at the
# substitution site because a Windows path may contain spaces and the
# runner templates do not quote the placeholder.
cad_arg_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$1"
    else
        printf '%s' "$1"
    fi
}

# Emit AutoLISP that appends one progress record to the results file.
# Raw open/write/close rather than probe-core's recorder, because the
# whole point is to work when probe-core has NOT loaded.
emit_step_marker() {
  local label="$1" expr="${2:-\"\"}"
  printf '(setq cad-probe--out (open "%s" "a"))\n' \
         "$(lisp_escape "$(cad_path "$result_file")")"
  printf '(if cad-probe--out (progn (write-line (strcat "((KIND . \\"step\\") (AT . \\"%s\\") (VALUE . \\"" (vl-princ-to-string %s) "\\"))") cad-probe--out) (close cad-probe--out)))\n' \
         "$(lisp_escape "$label")" "$expr"
}

# --- generate the probe wrapper (.lsp) -------------------------------
{
  # Every path below is consumed by the CAD, not by this shell, so each
  # goes through cad_path -- see its comment for what happens otherwise.
  # SECURELOAD, in the WRAPPER and not only in the .scr: a runner that
  # hands the wrapper straight to the engine -- the alfe route, which has
  # no .scr at all -- would otherwise hit SECURELOAD on the nested
  # (load)s below. Harmless where the .scr already cleared it, and
  # vl-catch-all-apply'd because an engine without the sysvar must not
  # die here.
  printf "(vl-catch-all-apply 'setvar (list \"SECURELOAD\" 0))\n"
  printf '(setq cad-probe-result-file "%s")\n'  "$(lisp_escape "$(cad_path "$result_file")")"
  printf '(setq cad-probe-platform "%s")\n'      "$(lisp_escape "$platform")"
  printf '(setq cad-probe-product "%s")\n'       "$(lisp_escape "$product")"
  printf '(setq cad-probe-run-directory "%s")\n' "$(lisp_escape "$(cad_path "$run_dir")")"
  # Write a marker BEFORE anything else can fail, so an empty result file
  # and a wrapper that started are distinguishable. Without it, "the load
  # failed" and "a suite died on its first form" look identical from
  # here: both leave nothing behind.
  printf '(setq cad-probe--out (open "%s" "w"))\n' \
         "$(lisp_escape "$(cad_path "$result_file")")"
  printf '(if cad-probe--out (progn (write-line "((KIND . \\"wrapper-start\\"))" cad-probe--out) (close cad-probe--out)))\n'
  # WHY EACH LOAD REPORTS ITSELF.
  #
  # Twice now a run has left exactly `wrapper-start' and nothing else,
  # and twice the diagnosis was a guess: the wrapper ran, something in
  # the loads did not, and the file could not say which. On BricsCAD the
  # bare engine segfaulted and under alfe it exited 1 in silence, so
  # neither harness said either.
  #
  # LOAD returning NIL is the case that matters: SECURELOAD refuses a
  # file outside TRUSTEDPATHS, and a repository checkout never is one.
  # The SETVAR above is wrapped in VL-CATCH-ALL-APPLY, so an engine that
  # REFUSES to clear SECURELOAD swallows that refusal silently -- and the
  # run then dies later, opaquely, at the first undefined function.
  # Recording the sysvar and each load's value turns the next run into an
  # explanation instead of another guess.
  printf '(setq cad-probe--out (open "%s" "a"))\n' \
         "$(lisp_escape "$(cad_path "$result_file")")"
  printf '(if cad-probe--out (progn (write-line (strcat "((KIND . \\"load-context\\") (SECURELOAD . \\"" (vl-princ-to-string (vl-catch-all-apply (quote getvar) (list "SECURELOAD"))) "\\"))") cad-probe--out) (close cad-probe--out)))\n'
  # Each load records whether it returned anything. A NIL here is the
  # whole answer when the run dies at the first undefined function.
  printf '(setq cad-probe--loaded (vl-catch-all-apply (quote load) (list "%s")))\n' \
         "$(lisp_escape "$(cad_path "$sources_dir/probe-core.lsp")")"
  printf '(setq cad-probe--out (open "%s" "a"))\n' \
         "$(lisp_escape "$(cad_path "$result_file")")"
  printf '(if cad-probe--out (progn (write-line (strcat "((KIND . \\"load\\") (FILE . \\"probe-core.lsp\\") (VALUE . \\"" (vl-princ-to-string cad-probe--loaded) "\\"))") cad-probe--out) (close cad-probe--out)))\n'
  # Load every suite file from the manifest.
  while read -r src fn _rest; do
    [[ -z "$src" || "$src" == \#* ]] && continue
    suite_wanted "$src" || continue
    printf '(setq cad-probe--loaded (vl-catch-all-apply (quote load) (list "%s")))\n' \
           "$(lisp_escape "$(cad_path "$sources_dir/$src")")"
    emit_step_marker "loaded $src" "cad-probe--loaded"
  done < "$manifest"
  # Is the recorder even THERE? A load that returned without defining
  # anything and a load that defined everything look identical from the
  # outside, and that ambiguity is what two rounds of guessing cost.
  emit_step_marker "begin-run-defined-p" "(if cad-probe-begin-run 1 0)"
  printf '(cad-probe-begin-run)\n'
  emit_step_marker "begin-run-returned"
  while read -r src fn _rest; do
    [[ -z "$src" || "$src" == \#* ]] && continue
    suite_wanted "$src" || continue
    printf '(%s)\n' "$fn"
  done < "$manifest"
  printf '(cad-probe-end-run)\n'
  printf '(princ)\n'
} > "$wrapper_file"

# --- generate the CAD script (.scr) that loads the wrapper -----------
# A CAD command script evaluates a leading-paren line as AutoLISP.
{
  # The two princ lines are INSTRUMENTATION, and they earn their place.
  #
  # A CAD script that loads nothing looks exactly like one that loads
  # everything: accoreconsole prints its banner, shows a few `Commande:'
  # prompts, and quits 0 either way. The 2026-08-16 AutoCAD runs produced
  # an empty result file twice, and the console gave no way to tell
  # whether the (load …) had even been reached.
  #
  # So the script now says so itself. In the console trace:
  #   neither line          -> the .scr was not executed as AutoLISP
  #   only "loading"        -> the wrapper was reached and the load failed
  #   both lines            -> the wrapper ran; look at the result file
  # SECURELOAD has been 1 by default since AutoCAD 2014 and refuses
  # (load) of a file outside TRUSTEDPATHS -- a repository checkout never
  # is one. Wrapped in vl-catch-all-apply because an engine without that
  # sysvar must not die here.
  printf "(vl-catch-all-apply 'setvar (list \"SECURELOAD\" 0))\n"
  printf '(princ "\\ncad-probe: loading wrapper\\n")\n'
  printf '(load "%s")\n' "$(lisp_escape "$(cad_path "$wrapper_file")")"
  printf '(princ "\\ncad-probe: wrapper returned\\n")\n'
  # Without an explicit quit the engine sits on its prompt and the caller
  # has to time it out. `._QUIT': `.' bypasses any redefinition, `_' is
  # the language-independent form -- this machine runs a French AutoCAD.
  # `_Y' answers the save-the-drawing question that follows.
  printf '._QUIT _Y\n'
} > "$script_file"

# A CAD script is read LINE BY LINE by the engine's script reader, and on
# Windows that reader expects CRLF. Written from MSYS2 the file is LF-only
# -- verified on the 2026-08-16 run, od showed no \r anywhere -- and the
# engine then advances its prompts without evaluating anything: script
# consumed, nothing run, exit 0.
#
# Only the .scr needs this. The .lsp it loads is read by the AutoLISP
# READER, which does not care about line endings.
if command -v cygpath >/dev/null 2>&1; then
    sed -i 's/$/\r/' "$script_file"
fi

write_metadata() {
  cat > "$metadata_file" <<EOF
{
  "product": "$(json_escape "$product")",
  "platform": "$(json_escape "$platform")",
  "timestamp_utc": "$(json_escape "$timestamp")",
  "status": "$(json_escape "$1")",
  "exit_code": $2,
  "runner_template": "$(json_escape "$runner_template")",
  "result_file": "$(json_escape "$run_rel/results.sexp")"
}
EOF
}

write_metadata "prepared" 0

# The engine is a NATIVE program, so the file it is pointed at must be
# named in ITS path form -- and MSYS2 will not do this one for us: its
# argument converter treats an argument beginning with `/' followed by a
# letter as a WINDOWS SWITCH, so `/c/Users/...' is passed through
# untouched.
#
# Then the NATIVE form, not the mixed one: see cad_arg_path. Quoted here
# because a Windows path may contain spaces and the templates do not
# quote the placeholder.
#
# CORRECTION to an earlier reading of this: accoreconsole prints its
# USAGE TEXT on every run, good or bad. It is NOT a sign of a malformed
# command line, and treating it as one sent this diagnosis down a false
# path once already.
# __DRAWING_FILE__: a drawing OF THIS RUN'S OWN, copied into the run
# directory from the one committed beside alfe's loader.
#
# Two reasons, and the first is the one that blocked this suite. BricsCAD
# was invoked with a script and NO DOCUMENT, and it segfaulted before a
# single probe record on both platforms -- while alfe, which always hands
# it a drawing, works. alfe's own launcher says why: "Open a drawing with
# the app: no document, no command line, nowhere for the keystrokes to
# land."
#
# The second is why it is a COPY rather than the file itself: pjb,
# 2026-08-30 -- passing the same drawing to successive runs produces
# modal "already in use, open read-only?" dialogs when a previous CAD
# left a lock, and a modal in a batch run is a hung run. The run
# directory is already unique per invocation, so a drawing written there
# is nobody else's. This is the same rule alfe now follows in its own
# workdir (issues/closed/empty-ressource.issue); the probe harness is a
# second caller of the same idea, not a second implementation of it --
# the bytes come from the one committed file.
drawing_file=""
if [[ "$runner_template" == *__DRAWING_FILE__* ]]; then
  drawing_source="$repo_root/autolisp-front-end/source/empty.dwg"
  if [[ -f "$drawing_source" ]]; then
    drawing_file="$run_dir/empty.dwg"
    cp -f "$drawing_source" "$drawing_file"
  else
    echo "run-probes: no empty drawing at $drawing_source; launching without one" >&2
  fi
fi

cmd="$runner_template"
cmd="${cmd//__PROBE_FILE__/\"$(cad_arg_path "$wrapper_file")\"}"
cmd="${cmd//__SCRIPT_FILE__/\"$(cad_arg_path "$script_file")\"}"
if [[ -n "$drawing_file" ]]; then
  cmd="${cmd//__DRAWING_FILE__/\"$(cad_arg_path "$drawing_file")\"}"
else
  # No drawing to give: drop the placeholder rather than pass an empty
  # quoted argument, which BricsCAD would read as a filename.
  cmd="${cmd//__DRAWING_FILE__/}"
fi

echo "run-probes: $product on $platform" >&2
echo "  runner : $cmd" >&2
echo "  output : $run_rel/results.sexp" >&2

set +e
# MSYS2 rewrites the SWITCHES, not just the paths: `/s' is handed to the
# engine as `S:\' and `/i' as `I:\', so accoreconsole receives arguments
# it cannot parse and answers by printing its usage. That is the real
# reason every AutoCAD attempt printed the usage banner -- and it is a
# documented MSYS2 behaviour, not something to be deduced from a trace.
#
# Disarming the conversion is what makes /s reach the engine as /s. The
# paths still have to be converted by hand, which is what cad_path (mixed
# form, inside Lisp) and cad_arg_path (native form, on the command line)
# do above.
#
# Harmless off MSYS2: both variables are simply unread there.
MSYS2_ARG_CONV_EXCL='*' MSYS_NO_PATHCONV=1 bash -lc "$cmd"
exit_code=$?
set -e

# A run is COMPLETE only if it reached its end record. Non-empty is not
# enough: the wrapper writes a `wrapper-start' marker before anything can
# fail, so a suite that dies on its first form still leaves a file behind.
# Checking for run-end is what tells "it ran" from "it started".
if [[ $exit_code -eq 0 && -s "$result_file" ]] && grep -q 'run-end' "$result_file"; then
  write_metadata "completed" "$exit_code"
elif [[ $exit_code -eq 0 && -s "$result_file" ]]; then
  write_metadata "incomplete" "$exit_code"
  echo "run-probes: ERROR — the wrapper started but never reached its end record." >&2
  echo "  A suite raised and stopped the run. The partial results are kept:" >&2
  echo "    $result_file" >&2
  exit 1
else
  write_metadata "failed" "$exit_code"
  # An EMPTY result file after a CLEAN exit is the failure mode worth
  # naming, because it looks like success: the engine started, printed
  # its banner, ran nothing and quit 0.  A failed (load …) inside a .scr
  # is not a process failure, so the exit code cannot be trusted alone.
  # It used to be a WARNING, and the run went on to a `git add' of a file
  # that does not exist, ending in a bare "fatal: pathspec … did not
  # match any files" -- a message about git, for a problem about paths.
  if [[ $exit_code -eq 0 && ! -s "$result_file" ]]; then
    echo "run-probes: ERROR — the runner exited 0 but wrote NO results." >&2
    echo "  The engine ran and produced nothing, which usually means the" >&2
    echo "  generated wrapper could not be loaded. On Windows the classic" >&2
    echo "  cause is a path form: a native CAD cannot open /c/Users/...," >&2
    echo "  only C:/Users/... (this script converts them with cygpath -m)." >&2
    echo "  Look at the generated files, they are kept:" >&2
    echo "    $script_file" >&2
    echo "    $wrapper_file" >&2
    exit 1
  fi
  echo "run-probes: WARNING — runner exit $exit_code, result file $( [[ -s $result_file ]] && echo non-empty || echo EMPTY )." >&2
fi

# --- commit the results ----------------------------------------------
if [[ -n "${PROBE_NO_COMMIT:-}" ]]; then
  echo "run-probes: PROBE_NO_COMMIT set — not committing." >&2
elif git -C "$repo_root" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$repo_root" add "$run_rel/results.sexp" "$run_rel/metadata.json"
  if git -C "$repo_root" diff --cached --quiet -- "$run_rel"; then
    echo "run-probes: nothing to commit." >&2
  else
    git -C "$repo_root" commit -q -m "probes: $product/$platform $timestamp" \
        -- "$run_rel/results.sexp" "$run_rel/metadata.json"
    echo "run-probes: committed $run_rel (not pushed)." >&2
  fi
else
  echo "run-probes: not a git repo — results left uncommitted at $run_dir." >&2
fi

echo "Probe run directory: $run_dir"
exit "$exit_code"
