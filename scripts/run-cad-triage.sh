#!/usr/bin/env bash
# TEMPORARY triage harness — checks whether the STALE (alfe 1.1–1.6-era) CAD
# cluster bugs still reproduce at HEAD on a real CAD, so we can close the ones
# already fixed and focus on the rest. Driven by the debug:cad:triage:* jobs;
# remove when the cluster triage is done.
#
# Bugs probed on --bricscad:
#   - alfe-large-form-load-limit          (-l of a big single form)
#   - alfe-bricscad-open                  ((prin1/princ x fileDesc) -> file, not stdout)
#   - alfe-load-form-argument-not-evaluated (-l with (setq p ...)(load p))
#
# Usage: run-cad-triage.sh --backend bricscad
set -u
backend="bricscad"
while [ $# -gt 0 ]; do
  case "$1" in
    --backend) backend="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

root="${CI_PROJECT_DIR:-$(pwd)}"
alfe="$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl"
out="$root/dist/cad-triage/$backend-$(uname -s)"
mkdir -p "$out"
rt_lsp="$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
bs_lsp="$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"
[ -f "$rt_lsp" ] && export ALFE_RUNTIME_LSP="$rt_lsp"
[ -f "$bs_lsp" ] && export ALFE_BOOTSTRAP_LSP="$bs_lsp"
[ -x "$alfe" ] || { echo "alfe not built at $alfe" >&2; exit 2; }

run() { echo "==== TRIAGE $1 ===="; shift; "$alfe" -norc --"$backend" --mode batch --timeout 120 "$@" 2>&1; echo "---- exit $? ----"; echo; }

# --- 1. large-form: a single (setq *big* '(0 1 ... N)) ~ hundreds of KB -------
big="$out/bigform.lsp"
{ printf "(setq *big* '("; for i in $(seq 1 40000); do printf '%d ' "$i"; done; printf "))\n"; } > "$big"
echo "bigform.lsp size: $(wc -c < "$big") bytes"
run large-form -l "$big" -x '(princ (strcat "BIGLEN=" (itoa (length *big*))))'

# --- 2. alfe-bricscad-open: (prin1/princ x fileDesc) must hit the FILE --------
openprobe="$out/open-probe.lsp"
cat > "$openprobe" <<'LSP'
(defun triage-open ( / f g line path)
  (setq path (strcat (getvar "TEMPPREFIX") "alfe-triage-open.txt"))
  (setq f (open path "w"))
  (if f (progn (prin1 "NAME" f) (princ " " f) (prin1 42 f) (princ "\n" f) (close f)))
  (setq g (open path "r"))
  (setq line (if g (read-line g)))
  (if g (close g))
  (princ (strcat "OPENFILE=[" (if line line "EMPTY") "]"))
  (princ (if (and line (wcmatch line "*NAME*42*")) " OPEN-OK" " OPEN-BUG-went-to-stdout")))
(triage-open)
LSP
run open-to-file -l "$openprobe"

# --- 3. load-form via -l: (setq p ...)(load p) -------------------------------
inner="$out/inner.lsp"; printf '(setq *tri-inner* 777)\n(princ "INNER-LOADED")\n' > "$inner"
outer="$out/outer.lsp"
printf '(setq p "%s")\n(load p)\n(princ (strcat "OUTER-SEES=" (itoa *tri-inner*)))\n' "$inner" > "$outer"
run load-form-via-l -l "$outer"

echo "triage done ($backend)"
exit 0
