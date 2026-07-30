#!/usr/bin/env bash
# TEMPORARY verification (remove with the debug job): cad-chr-vs-loaded-encoding.
# With the ccs fix, a cp1252 -l source (-Esource Windows-1252) must now load as
# é (bytes C3 A9), = (chr 233), not È (C3 88). Also dumps
# *AUTOLISP-CAD-LOAD-ENCODING* to confirm the front-end publishes the codec.
set -u
root="${CI_PROJECT_DIR:-$(pwd)}"
alfe="$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl"
out="$root/dist/cad-diag-chr"
mkdir -p "$out"
export ALFE_RUNTIME_LSP="$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
export ALFE_BOOTSTRAP_LSP="$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"
[ -x "$alfe" ] || { echo "alfe not built" >&2; exit 2; }

printf '(setq src-e "\xe9")\n' > "$out/se.lsp"       # one cp1252 byte 0xE9 = é
echo "=== se.lsp bytes ==="; xxd "$out/se.lsp"

diagfile="$out/chr-diag.txt"; rm -f "$diagfile"
cat > "$out/diag.lsp" <<LSP
(setq df (open "$diagfile" "w"))
(defun dl (k s) (princ k df) (princ "=[" df) (princ s df) (princ "]\n" df))
(dl "CAD-LOAD-ENCODING" (if (boundp (quote *AUTOLISP-CAD-LOAD-ENCODING*)) *AUTOLISP-CAD-LOAD-ENCODING* "UNBOUND"))
(dl "BACKEND" (if (boundp (quote *AUTOLISP-BACKEND*)) *AUTOLISP-BACKEND* "UNBOUND"))
(dl "SRC" src-e)
(dl "CHR" (chr 233))
(princ (strcat "ASCII-SRC=" (itoa (ascii src-e)) " ASCII-CHR=" (itoa (ascii (chr 233))) "\n") df)
(princ (strcat "EQ=" (if (= src-e (chr 233)) "T" "nil") "\n") df)
(close df)
(princ "CHR-DIAG-DONE")
LSP

echo "=== run: alfe --bricscad -Esource/-Efile Windows-1252 -l se.lsp -l diag.lsp ==="
"$alfe" -norc --bricscad --mode batch --timeout 120 \
  -Esource Windows-1252 -Efile Windows-1252 \
  -l "$out/se.lsp" -l "$out/diag.lsp" 2>&1
echo "---- exit $? ----"
echo "=== chr-diag.txt (text) ==="; cat "$diagfile" 2>/dev/null || echo "(absent)"
echo "=== chr-diag.txt (hex — SRC should now be c3 a9 é, EQ=T) ==="; xxd "$diagfile" 2>/dev/null || echo "(absent)"
exit 0
