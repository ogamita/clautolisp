#!/usr/bin/env bash
# TEMPORARY triage (remove with the debug job): does cad-vl-filename-directory-
# and-load still reproduce at HEAD on real BricsCAD? The SCHMS+ harness derives
# its dir from a *tu:self-override* var via vl-filename-directory, composes a
# sibling framework path, then (load <that-var>) at top level. The reported
# error "bad argument type <*TU:TEST-FRAMEWORK*>" is a SYMBOL reaching findfile
# -- i.e. the same unevaluated-(load VAR) bug now fixed
# (alfe-load-form-argument-not-evaluated). This replicates the pattern and also
# prints the derived path, so we see whether vl-filename-directory itself
# diverges on BricsCAD.
set -u
root="${CI_PROJECT_DIR:-$(pwd)}"
alfe="$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl"
out="$root/dist/cad-triage-vl"
mkdir -p "$out"
export ALFE_RUNTIME_LSP="$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
export ALFE_BOOTSTRAP_LSP="$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"
[ -x "$alfe" ] || { echo "alfe not built at $alfe" >&2; exit 2; }

fw="$out/vl-framework.lsp"
printf '(setq *tu:fw-marker* 999)\n(princ "VL-FRAMEWORK-LOADED")\n' > "$fw"

outer="$out/vl-outer.lsp"
cat > "$outer" <<LSP
(setq *tu:self-override* "$outer")
(setq *tu:dir* (vl-filename-directory *tu:self-override*))
(setq *tu:framework* (strcat *tu:dir* "/vl-framework.lsp"))
(princ (strcat "\nVL-DIR=[" *tu:dir* "] VL-FW=[" *tu:framework* "]"))
(load *tu:framework*)
(princ (strcat "\nVL-FRAMEWORK-SEES=" (itoa *tu:fw-marker*)))
LSP

echo "==== TRIAGE cad-vl (harness path derivation + load VAR) ===="
"$alfe" -norc --bricscad --mode batch --timeout 120 -l "$outer" 2>&1
echo "---- exit $? ----"
echo "triage-vl done"
exit 0
