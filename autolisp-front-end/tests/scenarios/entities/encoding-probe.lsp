;;;; encoding-probe.lsp — per-target character-encoding MEASUREMENT probe
;;;;
;;;; DISCOVERY, not pass/fail: it exercises the encoding situations on
;;;; whatever target runs it (clautolisp / BricsCAD / accoreconsole, on
;;;; macOS / Windows / Linux) and REPORTS the exhibited bytes, so the
;;;; encoding-situations §7 defaults table can be filled from real runs
;;;; (see issues/open/encoding-situations-cli-options.issue and
;;;; encoding-consolidation.issue). The vendor harness archives its output.
;;;;
;;;; The SOURCE is pure ASCII: every non-ASCII test character is built with
;;;; (chr N), so the `source` situation cannot confound the measurement.
;;;; Each line is machine-readable:  ENC <key> = <value>
;;;; Byte dumps are lowercase hex, space-separated, so they survive any
;;;; console encoding on the way back.
;;;;
;;;; Run it:
;;;;   alfe --clautolisp --host mock -l encoding-probe.lsp
;;;;   alfe --bricscad --mode batch      -l encoding-probe.lsp
;;;;   alfe --autocad  --mode batch      -l encoding-probe.lsp

(defun s2 (x / )
  (cond ((null x) "nil")
        ((= (type x) 'STR) (if (= x "") "empty" x))
        ((= (type x) 'INT) (itoa x))
        ((= (type x) 'REAL) (rtos x 2 4))
        (T "?")))

(defun m (key x / ) (princ (strcat "ENC " key " = " (s2 x) "\n")) (princ))

;; one byte -> two lowercase hex digits
(defun hx (n / h) (setq h "0123456789abcdef" n (rem n 256))
  (strcat (substr h (1+ (/ n 16)) 1) (substr h (1+ (rem n 16)) 1)))

;; read PATH back byte-by-byte and return "aa bb cc" hex. Reads under
;; ISO-8859-1 (a TOTAL single-byte decoder: every byte -> one char 0-255,
;; never a decode error) so the raw bytes survive on an engine that honours
;; *AUTOLISP-FILE-ENCODING* for the read (clautolisp; BricsCAD's ANSI/Mac
;; Roman default is already single-byte). Wrapped so a stray decode error
;; on a Unicode-default engine yields "DECODE-ERR" instead of halting.
(defun dumpbytes-impl (path / f c out)
  (setq out "" f (open path "r"))
  (if f (progn
          (while (setq c (read-char f)) (setq out (strcat out (hx c) " ")))
          (close f))
    (setq out "OPEN-FAILED"))
  out)

(defun dumpbytes (path / old r)
  (setq old *AUTOLISP-FILE-ENCODING*)
  (setq *AUTOLISP-FILE-ENCODING* "ISO-8859-1")
  (setq r (vl-catch-all-apply 'dumpbytes-impl (list path)))
  (setq *AUTOLISP-FILE-ENCODING* old)
  (if (vl-catch-all-error-p r) "DECODE-ERR" r))

;; write S to PATH under MODE; T if it worked (mode may be unsupported).
(defun trywrite (path mode s / f ok)
  (setq ok nil)
  (setq f (vl-catch-all-apply 'open (list path mode)))
  (if (and (not (vl-catch-all-error-p f)) f)
      (progn (vl-catch-all-apply 'princ (list s f))
             (vl-catch-all-apply 'close (list f))
             (setq ok T)))
  ok)

;; the DECODED code points of S, space-separated ints — reveals how many
;; chars the engine sees and their codes (65 233 90 = it decoded "AéZ";
;; 65 195 169 90 = it decoded UTF-8 é-bytes as two Latin-1 chars).
(defun codepoints (s / i n out)
  (if (= (type s) 'STR)
      (progn (setq out "" i 1 n (strlen s))
             (while (<= i n)
               (setq out (strcat out (itoa (ascii (substr s i 1))) " "))
               (setq i (1+ i)))
             out)
    "not-a-string"))

;; open PATH under MODE and report the DECODED code points (read-char
;; returns the engine's decoded char code). Distinct from dumpbytes, which
;; reads under ISO-8859-1 to recover the RAW bytes. Wrapped so a decode
;; error yields "READ-ERR" rather than halting the probe.
(defun readcp-impl (path mode / f c out)
  (setq out "" f (open path mode))
  (if f (progn (while (setq c (read-char f)) (setq out (strcat out (itoa c) " ")))
               (close f))
    (setq out "OPEN-FAIL"))
  out)
(defun readcp (path mode / r)
  (setq r (vl-catch-all-apply 'readcp-impl (list path mode)))
  (if (vl-catch-all-error-p r) "READ-ERR" r))

;; source situation: write a file whose SOURCE contains a literal non-ASCII
;; char (A é Z) under a chosen write MODE, record the on-disk BYTES (known),
;; then NATIVE (load) it and report the code points the engine's own loader
;; decoded. Comparing bytes↔codepoints characterises the native-load decode
;; (the axis behind cad-load-encoding-macos) without needing external
;; byte-exact fixtures we cannot transfer into the CAD's cwd.
(defun srcprobe (tag mode / path expr r)
  (setq path (strcat "encp-src-" tag ".lsp"))
  (setq expr (strcat "(setq ENCSRC \"A" (chr 233) "Z\")"))
  (if (trywrite path mode expr)
      (progn
        (m (strcat "source." tag ".bytes") (dumpbytes path))
        (setq ENCSRC "unset")
        (setq r (vl-catch-all-apply 'load (list path)))
        (if (vl-catch-all-error-p r)
            (m (strcat "source." tag ".load") "LOAD-ERR")
            (m (strcat "source." tag ".cp") (codepoints ENCSRC))))))

(defun run-encoding-probe ( / S)
  (princ "=== encoding probe ===\n")

  ;; --- 1. target identity: the (os x tool x version x codepage) key ---
  (m "ver"         (ver))
  (m "product"     (getvar "PRODUCT"))
  (m "program"     (getvar "PROGRAM"))
  (m "acadver"     (getvar "ACADVER"))
  (m "platform"    (getvar "PLATFORM"))
  (m "locale"      (getvar "LOCALE"))
  (m "syscodepage" (getvar "SYSCODEPAGE"))   ; nil on engines without it
  (m "dwgcodepage" (getvar "DWGCODEPAGE"))
  (m "lispsys"     (getvar "LISPSYS"))        ; AutoCAD only; nil elsewhere

  ;; --- 1b. the env the CAD's AutoLISP sees (the driver varies these) ---
  (m "env.LANG"     (getenv "LANG"))
  (m "env.LC_ALL"   (getenv "LC_ALL"))
  (m "env.LC_CTYPE" (getenv "LC_CTYPE"))
  (m "env.LANGUAGE" (getenv "LANGUAGE"))

  ;; --- 2. the test string: A <e-acute 233> [euro 8364] B ---
  ;; 233 is in the Latin-1/ANSI range; the euro (8364) probes the cp1252
  ;; 0x80-0x9F band the drain's Latin-1 fallback gets wrong — but (chr 8364)
  ;; may not be representable on a codepage engine, so it is guarded.
  (setq EU (vl-catch-all-apply 'chr (list 8364)))
  (if (vl-catch-all-error-p EU) (setq EU ""))
  (setq S (strcat "A" (chr 233) EU "B"))
  (m "test.length" (strlen S))               ; how the engine counts the string

  ;; --- 3. `file` situation: write known bytes, dump them back as hex.
  ;; trywrite no-ops (returns nil) when the target rejects the mode, so the
  ;; unsupported codec suffixes simply do not report. ---
  (if (trywrite "encp-default.txt"     "w"             S)
      (m "file.default.hex"     (dumpbytes "encp-default.txt")))
  (if (trywrite "encp-ccs-utf8.txt"    "w,ccs=UTF-8"   S)   ; BricsCAD codec suffix
      (m "file.ccs-utf8.hex"    (dumpbytes "encp-ccs-utf8.txt")))
  (if (trywrite "encp-ccs-utf16le.txt" "w,ccs=UTF-16LE" S)
      (m "file.ccs-utf16le.hex" (dumpbytes "encp-ccs-utf16le.txt")))

  ;; --- 4. cadstdio OUT: print the accents to the console; the alfe drain
  ;; captures the raw bytes on the way back (compare to file.default.hex). ---
  (m "console.test" S)

  ;; --- 5. does (setvar "SYSCODEPAGE" ...) take, and change the write? ---
  ;; (accoreconsole documents SYSCODEPAGE as read-only; BricsCAD may honour
  ;; it — the point is to MEASURE, per target.)
  (setq r (vl-catch-all-apply 'setvar (list "SYSCODEPAGE" "ansi_1252")))
  (m "setvar.syscodepage-ansi_1252"
     (if (vl-catch-all-error-p r) "rejected" "accepted"))
  (m "syscodepage.after-set" (getvar "SYSCODEPAGE"))
  (if (trywrite "encp-after-scp.txt" "w" S)
      (m "file.after-syscodepage.hex" (dumpbytes "encp-after-scp.txt")))

  ;; --- 6. file READ decode: how the engine DECODES bytes it wrote back.
  ;; read.*.cp are the decoded code points (65 233 8364 66 = clean A é € B);
  ;; compares default vs explicit ccs= read modes, and cross-reads a
  ;; UTF-8-written and a UTF-16LE-written file to probe read-side codec
  ;; selection (incl. BricsCAD's ccs=UNICODE auto-adapt-on-read claim). ---
  (m "read.default.cp"            (readcp "encp-default.txt"     "r"))
  (m "read.default-as-utf8.cp"    (readcp "encp-default.txt"     "r,ccs=UTF-8"))
  (m "read.utf8file-as-utf8.cp"   (readcp "encp-ccs-utf8.txt"    "r,ccs=UTF-8"))
  (m "read.utf8file-default.cp"   (readcp "encp-ccs-utf8.txt"    "r"))
  (m "read.utf16file-unicode.cp"  (readcp "encp-ccs-utf16le.txt" "r,ccs=UNICODE"))
  (m "read.utf16file-utf16le.cp"  (readcp "encp-ccs-utf16le.txt" "r,ccs=UTF-16LE"))

  ;; --- 7. source situation: native (load) decode vs known on-disk bytes,
  ;; across the write encodings (default / UTF-8 / UTF-16LE). Each line pair
  ;; source.<tag>.bytes + source.<tag>.cp says "these bytes decoded to these
  ;; code points" — the direct measurement of the CAD's own loader. ---
  (srcprobe "default" "w")
  (srcprobe "utf8"    "w,ccs=UTF-8")
  (srcprobe "utf16le" "w,ccs=UTF-16LE")

  ;; --- 8. log situation (identity only; producing/reading a batch log is
  ;; E2 and has so far failed to yield a file). Report the log sysvars so we
  ;; at least capture the path/mode the target exposes. ---
  (m "log.mode"     (getvar "LOGFILEMODE"))
  (m "log.path"     (getvar "LOGFILEPATH"))
  (m "log.name"     (getvar "LOGFILENAME"))

  (princ "ENC-PROBE DONE\n")
  (princ))

(run-encoding-probe)
