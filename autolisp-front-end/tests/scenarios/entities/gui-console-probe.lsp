;;;; gui-console-probe.lsp — MANUAL GUI-console encoding probe
;;;;
;;;; Run this INSIDE the BricsCAD / AutoCAD GUI (NOT via alfe — it is pure,
;;;; self-contained AutoLISP). Load it and it runs once; retype ENCGUI to
;;;; run again:
;;;;
;;;;   Command: (load "…/gui-console-probe.lsp")      ; or APPLOAD it
;;;;   Command: ENCGUI                                 ; to re-run
;;;;
;;;; WHY: the batch probes (encoding-probe.lsp) cannot reach the CAD's own
;;;; GUI text console — there is no console in -B / accoreconsole batch. This
;;;; script measures the `console` situation, both directions:
;;;;
;;;;   * OUTPUT — it prints known accented characters; YOU read whether they
;;;;     render correctly (é € à) or as mojibake, and note it.
;;;;   * INPUT  — the MEASURABLE part: it asks you to TYPE é and € at the
;;;;     command line and reports the code points the GUI console decoded
;;;;     your keystrokes into (233 = Latin-1/correct for é; 195 169 = the
;;;;     UTF-8 bytes seen as two chars; etc.), plus the raw input bytes.
;;;;
;;;; Everything is echoed to the console AND written to a report file whose
;;;; full path is printed at the end. Please send me that report file.
;;;;
;;;; The SOURCE here is pure ASCII: the accented characters are built with
;;;; (chr N), so loading this file can't itself confound the measurement.

;; ---- tiny helpers (mirrors encoding-probe.lsp, GUI-standalone) ------------

(defun s2 (x)
  (cond ((null x) "nil")
        ((= (type x) 'STR) (if (= x "") "empty" x))
        ((= (type x) 'INT) (itoa x))
        ((= (type x) 'REAL) (rtos x 2 4))
        (T "?")))

;; *ENCLOG* accumulates every reported line so we can dump it to a file.
(defun m (key x / line)
  (setq line (strcat "ENCGUI " key " = " (s2 x)))
  (princ (strcat "\n" line))
  (setq *ENCLOG* (cons line *ENCLOG*))
  (princ))

;; one byte -> two lowercase hex digits
(defun hx (n / h) (setq h "0123456789abcdef" n (rem n 256))
  (strcat (substr h (1+ (/ n 16)) 1) (substr h (1+ (rem n 16)) 1)))

;; DECODED code points of S (space-separated ints): how the engine sees it.
(defun codepoints (s / i n out)
  (if (= (type s) 'STR)
      (progn (setq out "" i 1 n (strlen s))
             (while (<= i n)
               (setq out (strcat out (itoa (ascii (substr s i 1))) " "))
               (setq i (1+ i)))
             out)
    "not-a-string"))

;; read PATH back byte-by-byte as "aa bb cc". Reads under a single-byte
;; total decoder so the RAW bytes survive (on clautolisp via
;; *AUTOLISP-FILE-ENCODING*; on BricsCAD/AutoCAD the ANSI/Mac-Roman default
;; is already single-byte, so read-char returns the byte value). Wrapped so
;; a decode error yields "DECODE-ERR" instead of halting.
(defun dumpbytes-impl (path / f c out)
  (setq out "" f (open path "r"))
  (if f (progn (while (setq c (read-char f)) (setq out (strcat out (hx c) " ")))
               (close f))
    (setq out "OPEN-FAILED"))
  out)
(defun dumpbytes (path / old r)
  (setq old *AUTOLISP-FILE-ENCODING*)             ; clautolisp-only; no-op on CADs
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

;; getstring that never halts; returns "" on error or on nil (Esc/EOF).
(defun ask (prompt / r)
  (setq r (vl-catch-all-apply 'getstring (list T prompt)))
  (if (and (not (vl-catch-all-error-p r)) (= (type r) 'STR)) r ""))

;; measure one typed accented character: code points + raw bytes.
(defun measure-input (tag prompt / in path)
  (setq in (ask prompt))
  (m (strcat "input." tag ".cp")  (codepoints in))
  (m (strcat "input." tag ".len") (strlen in))
  (setq path (strcat "encp-gui-input-" tag ".txt"))
  (if (trywrite path "w" in)
      (m (strcat "input." tag ".bytes") (dumpbytes path))))

;; pick a writable base dir for the report and return the full path.
(defun report-path ( / base)
  (setq base (cond ((getenv "USERPROFILE")) ((getenv "HOME")) (T ".")))
  (strcat base "/enc-gui-console-report.txt"))

;; ---- the probe ------------------------------------------------------------

(defun c:encgui ( / S EU rp f)
  (setq *ENCLOG* nil)
  (princ "\n=== GUI console encoding probe ===")
  (princ "\nAnswer the two prompts by TYPING the requested accented char.\n")

  ;; 1. target identity (the os x tool x version x codepage key)
  (m "ver"         (ver))
  (m "product"     (getvar "PRODUCT"))
  (m "program"     (getvar "PROGRAM"))
  (m "acadver"     (getvar "ACADVER"))
  (m "platform"    (getvar "PLATFORM"))
  (m "locale"      (getvar "LOCALE"))
  (m "syscodepage" (getvar "SYSCODEPAGE"))
  (m "dwgcodepage" (getvar "DWGCODEPAGE"))
  (m "lispsys"     (getvar "LISPSYS"))            ; AutoCAD; nil elsewhere

  ;; 2. console OUTPUT — you READ these; note which render correctly.
  (setq EU (vl-catch-all-apply 'chr (list 8364)))
  (if (vl-catch-all-error-p EU) (setq EU ""))
  (setq S (strcat "A" (chr 233) EU "B"))          ; A e-acute euro B
  (princ "\n--- console OUTPUT test (read the next line on screen) ---")
  (princ (strcat "\n  string  : [" S "]   (expect: A, e-acute, euro, B)"))
  (princ (strcat "\n  e-acute : code 233 -> [" (chr 233) "]"))
  (princ (strcat "\n  euro    : code 8364 -> [" EU "]"))
  (princ (strcat "\n  a-grave : code 224 -> [" (chr 224) "]\n"))
  (m "output.string.cp" (codepoints S))           ; what the engine stored
  ;; correlate: same string to a file, dump its bytes (the file encoding).
  (if (trywrite "encp-gui-out.txt" "w" S)
      (m "output.file.bytes" (dumpbytes "encp-gui-out.txt")))

  ;; 3. console INPUT — the measurable part. Type the char, we decode it.
  (princ "\n--- console INPUT test (type the accented char, then Enter) ---")
  (measure-input "e-acute" "\nType the e-acute char and Enter (é): ")
  (measure-input "euro"    "\nType the euro sign and Enter (€): ")
  (measure-input "word"    "\nType the word and Enter (café à €): ")

  ;; 4. write the report file and tell the user where it is.
  (setq rp (report-path))
  (setq f (vl-catch-all-apply 'open (list rp "w")))
  (if (and (not (vl-catch-all-error-p f)) f)
      (progn
        (foreach ln (reverse *ENCLOG*) (write-line ln f))
        (close f)
        (m "report.written" rp))
      (m "report.written" "FAILED-open-report"))

  (princ "\n\n=== ENCGUI DONE ===")
  (princ "\nPlease: (a) note which OUTPUT chars rendered correctly on screen,")
  (princ (strcat "\n        (b) send me the report file: " rp "\n"))
  (princ))

;; auto-run once on load, and advertise the re-run command.
(princ "\nGUI console encoding probe loaded. Running now; retype ENCGUI to repeat.\n")
(c:encgui)
