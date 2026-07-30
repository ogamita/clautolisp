#!/usr/bin/env bash
# TEMPORARY ccs-discovery (remove with the debug job): find the exact ,ccs= NAME
# BricsCAD accepts for cp1252 on macOS. Open a single-byte-0xE9 file with several
# ccs candidates and read-char it; the codec that yields code 233 (é) is the one
# to map WINDOWS-1252 to. (cad-chr-vs-loaded-encoding: ,ccs=WINDOWS-1252 was
# rejected -> bare open -> Mac Roman -> È.)
set -u
root="${CI_PROJECT_DIR:-$(pwd)}"
alfe="$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl"
out="$root/dist/cad-diag-chr"; mkdir -p "$out"
export ALFE_RUNTIME_LSP="$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
export ALFE_BOOTSTRAP_LSP="$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"
[ -x "$alfe" ] || { echo "alfe not built" >&2; exit 2; }

# A file holding exactly one byte 0xE9.
tf="$out/byte-e9.bin"; printf '\xe9' > "$tf"
echo "=== byte-e9.bin ==="; xxd "$tf"

diagfile="$out/ccs-diag.txt"; rm -f "$diagfile"
cat > "$out/diag.lsp" <<LSP
(setq df (open "$diagfile" "w"))
(defun tryccs (ccs / f code)
  (setq f (vl-catch-all-apply (quote open) (list "$tf" (strcat "r,ccs=" ccs))))
  (princ (strcat "ccs=" ccs " -> ") df)
  (if (vl-catch-all-error-p f)
    (princ (strcat "OPEN-ERR: " (vl-catch-all-error-message f)) df)
    (if (null f) (princ "nil" df)
      (progn (setq code (read-char f)) (close f)
             (princ (if code (itoa code) "eof") df))))
  (princ "\n" df))
(tryccs "Windows-1252")
(tryccs "windows-1252")
(tryccs "WINDOWS-1252")
(tryccs "1252")
(tryccs "ANSI")
(tryccs "CP1252")
(tryccs "ISO-8859-1")
(tryccs "Latin1")
(tryccs "UTF-8")
(princ "want: the ccs whose value is 233 (byte 0xE9 = cp1252 e-acute)\n" df)
(close df)
(princ "CCS-DIAG-DONE")
LSP

echo "=== run: alfe --bricscad -l diag.lsp (ccs discovery) ==="
"$alfe" -norc --bricscad --mode batch --timeout 120 -l "$out/diag.lsp" 2>&1
echo "---- exit $? ----"
echo "=== ccs-diag.txt ==="; cat "$diagfile" 2>/dev/null || echo "(absent)"
exit 0
