(defun autolisp-bootstrap-append-line (alfe--path alfe--text / alfe--f)
  (if (and (= (type alfe--path) 'STR)
           (/= alfe--path ""))
    (progn
      (setq alfe--f (open alfe--path "a"))
      (if alfe--f
        (progn
          (write-line alfe--text alfe--f)
          (close alfe--f))))))

(defun autolisp-bootstrap-write-line (alfe--path alfe--text / alfe--f)
  (if (and (= (type alfe--path) 'STR)
           (/= alfe--path ""))
    (progn
      (setq alfe--f (open alfe--path "w"))
      (if alfe--f
        (progn
          (write-line alfe--text alfe--f)
          (close alfe--f))))))

(defun autolisp-bootstrap-render-error (alfe--err / alfe--msg)
  (cond
    ((and (= (type alfe--err) 'STR)
          (/= alfe--err ""))
     alfe--err)
    ((and (fboundp 'vl-catch-all-error-message)
          (not (vl-catch-all-error-p
                 (setq alfe--msg (vl-catch-all-apply 'vl-catch-all-error-message
                                               (list alfe--err))))))
     alfe--msg)
    (T
     "<bootstrap failure>")))

(defun autolisp-bootstrap-mark-fatal (alfe--phase alfe--err / alfe--msg)
  (setq alfe--msg (autolisp-bootstrap-render-error alfe--err))
  (autolisp-bootstrap-append-line *AUTOLISP_ERRFILE*
                                  (strcat "ERROR " alfe--phase ": " alfe--msg))
  (autolisp-bootstrap-write-line *AUTOLISP_STATUSFILE* "1")
  (autolisp-bootstrap-write-line *AUTOLISP_PROTOCOL_STATUSFILE*
                                 (strcat "FAILED " alfe--phase))
  (if *AUTOLISP_QUIT_ON_FINISH*
    (vl-catch-all-apply 'command (list "_QUIT" "_Y")))
  1)

(defun autolisp-write-line (alfe--path alfe--text / alfe--f)
  (setq alfe--f (open alfe--path "a"))
  (if alfe--f
    (progn
      (write-line alfe--text alfe--f)
      (close alfe--f))))

(defun autolisp-reset-file (alfe--path / alfe--f)
  (setq alfe--f (open alfe--path "w"))
  (if alfe--f (close alfe--f)))

(defun autolisp-slurp-file (alfe--path / alfe--f alfe--line alfe--acc)
  (setq alfe--f (open alfe--path "r"))
  (if (not alfe--f)
    ""
    (progn
      (setq alfe--acc "")
      (while (setq alfe--line (read-line alfe--f))
        (setq alfe--line (vl-string-translate "\r" "" alfe--line))
        (if (= alfe--acc "")
          (setq alfe--acc alfe--line)
          (setq alfe--acc (strcat alfe--acc "\n" alfe--line))))
      (close alfe--f)
      alfe--acc)))

(defun autolisp-str (alfe--obj)
  (if (= (type alfe--obj) 'STR)
    alfe--obj
    (autolisp-render alfe--obj)))

(defun autolisp-render (alfe--obj / alfe--rendered)
  (setq alfe--rendered (vl-catch-all-apply 'vl-princ-to-string (list alfe--obj)))
  (if (vl-catch-all-error-p alfe--rendered)
    "<unprintable>"
    alfe--rendered))

(defun autolisp-set-status (alfe--code / alfe--f)
  (setq alfe--f (open *AUTOLISP_STATUSFILE* "w"))
  (if alfe--f
    (progn
      (write-line (itoa alfe--code) alfe--f)
      (close alfe--f)))
  alfe--code)

(defun autolisp-set-status-text (alfe--text / alfe--f)
  (setq alfe--f (open *AUTOLISP_STATUSFILE* "w"))
  (if alfe--f
    (progn
      (write-line alfe--text alfe--f)
      (close alfe--f)))
  alfe--text)

(defun autolisp-log-out (alfe--text)
  (autolisp-write-line *AUTOLISP_OUTFILE* alfe--text))

(defun autolisp-log-err (alfe--text)
  (autolisp-write-line *AUTOLISP_ERRFILE* alfe--text))

(defun autolisp-safe-getvar (alfe--name / alfe--value)
  (setq alfe--value (vl-catch-all-apply 'getvar (list alfe--name)))
  (if (vl-catch-all-error-p alfe--value)
    ""
    (autolisp-str alfe--value)))

(defun autolisp-write-runtime-info (/ alfe--f)
  (setq alfe--f (open *AUTOLISP_PROTOCOL_INFOFILE* "w"))
  (if alfe--f
    (progn
      (write-line (autolisp-safe-getvar "PRODUCT") alfe--f)
      (write-line (autolisp-safe-getvar "ACADVER") alfe--f)
      (write-line (autolisp-safe-getvar "PROGRAM") alfe--f)
      (close alfe--f)))
  nil)

(defun autolisp-stdout-prefix ()
  "<<<AUTOLISP-STDOUT>>>")

(defun autolisp-escape-string (alfe--text / alfe--idx alfe--len alfe--ch alfe--acc)
  (setq alfe--idx 1)
  (setq alfe--len (strlen alfe--text))
  (setq alfe--acc "")
  (while (<= alfe--idx alfe--len)
    (setq alfe--ch (substr alfe--text alfe--idx 1))
    (if (= alfe--ch "\\")
      (setq alfe--acc (strcat alfe--acc "\\\\"))
      (if (= alfe--ch "\"")
        (setq alfe--acc (strcat alfe--acc "\\\""))
        (setq alfe--acc (strcat alfe--acc alfe--ch))))
    (setq alfe--idx (+ alfe--idx 1)))
  alfe--acc)

(defun autolisp-readable-text (alfe--obj / alfe--acc alfe--first alfe--tail alfe--rest)
  (cond
    ((null alfe--obj)
     "nil")
    ((= (type alfe--obj) 'STR)
     (strcat "\"" (autolisp-escape-string alfe--obj) "\""))
    ((listp alfe--obj)
     ;; Walk the list with an improper-tail guard. A proper list
     ;; ends with NIL, terminator stays a plain closing paren; a
     ;; dotted pair like `[1 . 2]' or improper tail like
     ;; `[1 2 . 3]' ends with a non-NIL non-cons, and we emit a
     ;; ` . X' before the closing paren so the rendered text is
     ;; read-equal to the original. Without this guard the loop
     ;; tried CAR on a tail integer and signalled `bad argument
     ;; type', which became user-visible after alfe 1.1.13 routed
     ;; eval through the file-load path -- mapcar+lambda bodies
     ;; returning cons cells via cons of two atoms produce dotted
     ;; pairs that the printer crashed on.
     (setq alfe--acc "(")
     (setq alfe--first T)
     (setq alfe--tail alfe--obj)
     (while alfe--tail
       (if alfe--first
         (setq alfe--first nil)
         (setq alfe--acc (strcat alfe--acc " ")))
       (setq alfe--acc (strcat alfe--acc (autolisp-readable-text (car alfe--tail))))
       (setq alfe--rest (cdr alfe--tail))
       (cond
         ((null alfe--rest)
           (setq alfe--tail nil))
         ((listp alfe--rest)
           (setq alfe--tail alfe--rest))
         (T
           (setq alfe--acc (strcat alfe--acc " . " (autolisp-readable-text alfe--rest)))
           (setq alfe--tail nil))))
     (strcat alfe--acc ")"))
    (T
     (autolisp-render alfe--obj))))

(defun autolisp-stdout-text (alfe--obj)
  (autolisp-readable-text alfe--obj))

;; --- Printing a form back as SOURCE, losslessly ---------------------------
;;
;; alfe-cad-transport-rounds-reals: autolisp-readable-text renders an atom
;; with vl-princ-to-string, which is right for what a program PRINTS (the
;; user sees the digits the CAD's own princ would show) and wrong for SOURCE
;; that the CAD will read again: PRINC of a REAL keeps 6 significant digits on
;; AutoCAD (1.5707963267948966 -> 1.5708) and 14 on BricsCAD. A form that has
;; to be written back as text (alfe-eval.lsp, when a normaliser rewrote it)
;; goes through autolisp-form-source-text instead, which prints every REAL
;; with as many digits as it takes to read back to the SAME double.
;;
;; The candidates are tried shortest first, and each is CHECKED in the CAD
;; itself by reading it back -- the CAD's reader is the one that will read the
;; file, so its verdict is the one that counts:
;;   1. the plain princ text (3.0, 0.5: kept as the user would write them);
;;   2. (rtos x 1 16): scientific, 17 significant digits -- enough for any
;;      double -- and any magnitude (1.0e-300, 1.0e300);
;;   3. (rtos x 2 16): decimal, for a CAD whose reader would not take 2.
;; RTOS output depends on DIMZIN (its zero-suppression bits can drop the
;; leading zero, ".5", or the trailing ones, "3" for 3.0), so it is normalised
;; to always carry a digit before and after the point; a REAL stays a REAL.
;; When no candidate reads back exactly, the readable one with the most
;; digits is used, and failing that the plain text: never worse than before.

;; The REAL that TEXT reads as, or NIL when it reads as anything else or
;; does not read at all.
(defun autolisp-real-text-value (alfe--text / alfe--r)
  (setq alfe--r (vl-catch-all-apply 'read (list alfe--text)))
  (if (and (not (vl-catch-all-error-p alfe--r)) (= (type alfe--r) 'REAL))
    alfe--r
    nil))

(defun autolisp-real-text-reads-back-p (alfe--text alfe--x / alfe--r)
  (setq alfe--r (autolisp-real-text-value alfe--text))
  (and alfe--r (= alfe--r alfe--x)))

;; Undo what DIMZIN's zero suppression does to RTOS output: ".5" -> "0.5",
;; "-.5" -> "-0.5", "3" -> "3.0", "3." -> "3.0", "1E+00" -> "1.0E+00".
(defun autolisp-real-text-normalize (alfe--text / alfe--epos alfe--mant alfe--expo)
  (cond
    ((= (substr alfe--text 1 1) ".") (setq alfe--text (strcat "0" alfe--text)))
    ((= (substr alfe--text 1 2) "-.") (setq alfe--text (strcat "-0" (substr alfe--text 2)))))
  (setq alfe--epos (vl-string-search "E" (strcase alfe--text)))
  (if alfe--epos
    (progn
      (setq alfe--mant (substr alfe--text 1 alfe--epos))
      (setq alfe--expo (substr alfe--text (+ alfe--epos 1))))
    (progn
      (setq alfe--mant alfe--text)
      (setq alfe--expo "")))
  (cond
    ((not (vl-string-search "." alfe--mant)) (setq alfe--mant (strcat alfe--mant ".0")))
    ((= (substr alfe--mant (strlen alfe--mant)) ".") (setq alfe--mant (strcat alfe--mant "0"))))
  (strcat alfe--mant alfe--expo))

;; (rtos X MODE 16), normalised, or NIL when RTOS refuses.
(defun autolisp-real-rtos-text (alfe--x alfe--mode / alfe--s)
  (setq alfe--s (vl-catch-all-apply 'rtos (list alfe--x alfe--mode 16)))
  (if (or (vl-catch-all-error-p alfe--s) (/= (type alfe--s) 'STR) (= alfe--s ""))
    nil
    (autolisp-real-text-normalize alfe--s)))

;; T when the REAL X is a negative zero. = cannot tell -0.0 from 0.0, but
;; ATAN (atan2) can: (atan -0.0 -1.0) is -pi, (atan 0.0 -1.0) is +pi.
(defun autolisp-real-negative-zero-p (alfe--x / alfe--r)
  (and (= alfe--x 0.0)
       (progn
         (setq alfe--r (vl-catch-all-apply 'atan (list alfe--x -1.0)))
         (and (not (vl-catch-all-error-p alfe--r)) (minusp alfe--r)))))

;; Source text for the REAL X that reads back to X itself.
(defun autolisp-real-source-text (alfe--x / alfe--plain alfe--sci alfe--dec)
  (setq alfe--plain (autolisp-render alfe--x))
  (cond
    ;; Zero: every candidate reads back = to it whatever its sign, so the
    ;; sign is decided here (RTOS drops it on some hosts).
    ((= alfe--x 0.0) (if (autolisp-real-negative-zero-p alfe--x) "-0.0" "0.0"))
    ((autolisp-real-text-reads-back-p alfe--plain alfe--x) alfe--plain)
    ((and (setq alfe--sci (autolisp-real-rtos-text alfe--x 1))
          (autolisp-real-text-reads-back-p alfe--sci alfe--x))
     alfe--sci)
    ((and (setq alfe--dec (autolisp-real-rtos-text alfe--x 2))
          (autolisp-real-text-reads-back-p alfe--dec alfe--x))
     alfe--dec)
    ((and alfe--sci (autolisp-real-text-value alfe--sci)) alfe--sci)
    ((and alfe--dec (autolisp-real-text-value alfe--dec)) alfe--dec)
    (T alfe--plain)))

;; autolisp-readable-text for SOURCE: the same rendering (strings quoted and
;; escaped, dotted tails kept, symbols and integers as princ shows them)
;; except that a REAL keeps all its digits.
(defun autolisp-form-source-text (alfe--obj / alfe--acc alfe--first alfe--tail alfe--rest)
  (cond
    ((null alfe--obj)
     "nil")
    ((= (type alfe--obj) 'STR)
     (strcat "\"" (autolisp-escape-string alfe--obj) "\""))
    ((= (type alfe--obj) 'REAL)
     (autolisp-real-source-text alfe--obj))
    ((listp alfe--obj)
     (setq alfe--acc "(")
     (setq alfe--first T)
     (setq alfe--tail alfe--obj)
     (while alfe--tail
       (if alfe--first
         (setq alfe--first nil)
         (setq alfe--acc (strcat alfe--acc " ")))
       (setq alfe--acc (strcat alfe--acc (autolisp-form-source-text (car alfe--tail))))
       (setq alfe--rest (cdr alfe--tail))
       (cond
         ((null alfe--rest)
           (setq alfe--tail nil))
         ((listp alfe--rest)
           (setq alfe--tail alfe--rest))
         (T
           (setq alfe--acc (strcat alfe--acc " . " (autolisp-form-source-text alfe--rest)))
           (setq alfe--tail nil))))
     (strcat alfe--acc ")"))
    (T
     (autolisp-render alfe--obj))))

(defun autolisp-emit-user-out (alfe--obj)
  (if *AUTOLISP_CAPTURE_STDOUT*
    (autolisp-write-line *AUTOLISP_OUTFILE*
                         (strcat (autolisp-stdout-prefix)
                                 (autolisp-stdout-text alfe--obj))))
  alfe--obj)

(defun autolisp-emit-user-line (alfe--text)
  (if *AUTOLISP_CAPTURE_STDOUT*
    (autolisp-write-line *AUTOLISP_OUTFILE*
                         (strcat (autolisp-stdout-prefix) alfe--text))
    alfe--text)
  alfe--text)

;; Fallback for BricsCAD builds where the project-specific LispFunction is not
;; loaded yet. The real EPURELIB.dll definition can still replace this later.
(defun get_new_guid (/ alfe--stamp)
  (if (not (boundp '*AUTOLISP_GUID_SEQ*))
    (setq *AUTOLISP_GUID_SEQ* 0))
  (setq *AUTOLISP_GUID_SEQ* (+ *AUTOLISP_GUID_SEQ* 1))
  (setq alfe--stamp (rtos (getvar "DATE") 2 8))
  (strcat "AUTO-" alfe--stamp "-" (itoa *AUTOLISP_GUID_SEQ*)))

(defun autolisp-mark-begin (alfe--kind alfe--idx)
  nil)

(defun autolisp-mark-end (alfe--kind alfe--idx alfe--rc)
  nil)

(defun autolisp-finish (alfe--code)
  (if *AUTOLISP_LOG_STATE*
    (autolisp-log-restore *AUTOLISP_LOG_STATE*))
  (if _autolisp_old_srchpath
    (setvar "SRCHPATH" _autolisp_old_srchpath))
  (autolisp-set-status alfe--code)
  (if *AUTOLISP_QUIT_ON_FINISH*
    (autolisp-host-quit))
  alfe--code)

;; AutoLISP has two comment forms: a semicolon comments out the rest of
;; its line, and ;| opens a BLOCK comment that runs, across lines, to the
;; next |; -- the documentation blocks of SCHMS and outils-autolisp are
;; written that way. Every scanner below tracks both, so that the prose
;; of a block comment -- parentheses, quotes and semicolons included --
;; is never taken for code (alfe-cad-source-loader-evaluates-block-
;; comments: `no function definition: SYMBOLE' was the word after a
;; parenthesis in such a block). Delimiters inside a string are text.
(defun autolisp-source-block-open-p (alfe--text alfe--idx)
  (and (= (substr alfe--text alfe--idx 1) ";")
       (= (substr alfe--text (+ alfe--idx 1) 1) "|")))

(defun autolisp-source-block-close-p (alfe--text alfe--idx)
  (and (= (substr alfe--text alfe--idx 1) "|")
       (= (substr alfe--text (+ alfe--idx 1) 1) ";")))

;; TEXT without its block comments, each replaced by one space, for the
;; loader's own READ: what the CAD's READ makes of a block comment inside
;; a form is not something the loader needs to depend on. TEXT is
;; returned as is when it holds no ;| at all.
(defun autolisp-source-strip-block-comments (alfe--text / alfe--idx alfe--len alfe--ch alfe--in-string alfe--escape alfe--in-line alfe--acc alfe--seg)
  (if (not (vl-string-search ";|" alfe--text))
    alfe--text
    (progn
      (setq alfe--idx 1)
      (setq alfe--len (strlen alfe--text))
      (setq alfe--in-string nil)
      (setq alfe--escape nil)
      (setq alfe--in-line nil)
      (setq alfe--acc '())
      (setq alfe--seg 1)
      (while (<= alfe--idx alfe--len)
        (setq alfe--ch (substr alfe--text alfe--idx 1))
        (cond
          (alfe--in-line
           (if (= alfe--ch "\n") (setq alfe--in-line nil)))
          (alfe--in-string
           (cond
             (alfe--escape (setq alfe--escape nil))
             ((= alfe--ch "\\") (setq alfe--escape T))
             ((= alfe--ch "\"") (setq alfe--in-string nil))))
          ((= alfe--ch "\"") (setq alfe--in-string T))
          ((autolisp-source-block-open-p alfe--text alfe--idx)
           (setq alfe--acc (cons " " (cons (substr alfe--text alfe--seg (- alfe--idx alfe--seg)) alfe--acc)))
           (setq alfe--idx (+ alfe--idx 2))
           (while (and (<= alfe--idx alfe--len)
                       (not (autolisp-source-block-close-p alfe--text alfe--idx)))
             (setq alfe--idx (+ alfe--idx 1)))
           ;; idx is on the | of |; (or past the end): skip that |, the
           ;; loop step skips the ;.
           (setq alfe--seg (+ alfe--idx 2)))
          ((= alfe--ch ";") (setq alfe--in-line T)))
        (setq alfe--idx (+ alfe--idx 1)))
      (if (<= alfe--seg alfe--len)
        (setq alfe--acc (cons (substr alfe--text alfe--seg) alfe--acc)))
      (apply 'strcat (reverse alfe--acc)))))

(defun autolisp-source-scan-text (alfe--text / alfe--idx alfe--len alfe--depth alfe--in-string alfe--escape alfe--in-comment alfe--ch alfe--line alfe--col alfe--open-stack alfe--started alfe--top alfe--block-line alfe--block-col)
  (setq *AUTOLISP_SOURCE_SCAN_STATE* 'empty)
  (setq *AUTOLISP_SOURCE_SCAN_LINE* 1)
  (setq *AUTOLISP_SOURCE_SCAN_COL* 1)
  (setq alfe--idx 1)
  (setq alfe--len (strlen alfe--text))
  (setq alfe--depth 0)
  (setq alfe--in-string nil)
  (setq alfe--escape nil)
  (setq alfe--in-comment nil)
  (setq alfe--line 1)
  (setq alfe--col 0)
  (setq alfe--open-stack nil)
  (setq alfe--started nil)
  (while (and (<= alfe--idx alfe--len)
              (/= *AUTOLISP_SOURCE_SCAN_STATE* 'extra))
    (setq alfe--ch (substr alfe--text alfe--idx 1))
    (cond
      ((= alfe--ch "\n")
       (setq alfe--line (+ alfe--line 1))
       (setq alfe--col 0)
       (if (eq alfe--in-comment 'line)
         (setq alfe--in-comment nil)))
      (T
       (setq alfe--col (+ alfe--col 1))
       (cond
         ((eq alfe--in-comment 'block)
          (if (autolisp-source-block-close-p alfe--text alfe--idx)
            (progn
              (setq alfe--in-comment nil)
              (setq alfe--idx (+ alfe--idx 1))
              (setq alfe--col (+ alfe--col 1)))))
         (alfe--in-comment
          nil)
         (alfe--in-string
          (cond
            (alfe--escape
             (setq alfe--escape nil))
            ((= alfe--ch "\\")
             (setq alfe--escape T))
            ((= alfe--ch "\"")
             (setq alfe--in-string nil))))
         ((autolisp-source-block-open-p alfe--text alfe--idx)
          (setq alfe--in-comment 'block)
          (setq alfe--block-line alfe--line)
          (setq alfe--block-col alfe--col)
          (setq alfe--idx (+ alfe--idx 1))
          (setq alfe--col (+ alfe--col 1)))
         ((= alfe--ch ";")
          (setq alfe--in-comment 'line))
         ((member alfe--ch '(" " "\t" "\r"))
          nil)
         (T
          (setq alfe--started T)
          (cond
            ((= alfe--ch "\"")
             (setq alfe--in-string T))
            ((= alfe--ch "(")
             (setq alfe--depth (+ alfe--depth 1))
             (setq alfe--open-stack (cons (list alfe--line alfe--col) alfe--open-stack)))
            ((= alfe--ch ")")
             (if (> alfe--depth 0)
               (progn
                 (setq alfe--depth (- alfe--depth 1))
                 (setq alfe--open-stack (cdr alfe--open-stack)))
               (progn
                 (setq *AUTOLISP_SOURCE_SCAN_STATE* 'extra)
                 (setq *AUTOLISP_SOURCE_SCAN_LINE* alfe--line)
                 (setq *AUTOLISP_SOURCE_SCAN_COL* alfe--col)))))))))
    (setq alfe--idx (+ alfe--idx 1)))
  (if (/= *AUTOLISP_SOURCE_SCAN_STATE* 'extra)
    ;; in-string and open-stack imply started. A block comment still
    ;; open at the end needs more lines even when no form has begun --
    ;; 'empty would let the loader drop the text, and the comment's next
    ;; line would then be read as code.
    (cond
      (alfe--in-string
       (setq *AUTOLISP_SOURCE_SCAN_STATE* 'incomplete-string)
       (setq *AUTOLISP_SOURCE_SCAN_LINE* alfe--line)
       (setq *AUTOLISP_SOURCE_SCAN_COL* (max 1 alfe--col)))
      (alfe--open-stack
       (setq alfe--top (car alfe--open-stack))
       (setq *AUTOLISP_SOURCE_SCAN_STATE* 'incomplete)
       (setq *AUTOLISP_SOURCE_SCAN_LINE* (car alfe--top))
       (setq *AUTOLISP_SOURCE_SCAN_COL* (cadr alfe--top)))
      ((eq alfe--in-comment 'block)
       (setq *AUTOLISP_SOURCE_SCAN_STATE* 'incomplete-comment)
       (setq *AUTOLISP_SOURCE_SCAN_LINE* alfe--block-line)
       (setq *AUTOLISP_SOURCE_SCAN_COL* alfe--block-col))
      ((not alfe--started)
       (setq *AUTOLISP_SOURCE_SCAN_STATE* 'empty))
      (T
       (setq *AUTOLISP_SOURCE_SCAN_STATE* 'complete)
       (setq *AUTOLISP_SOURCE_SCAN_LINE* alfe--line)
       (setq *AUTOLISP_SOURCE_SCAN_COL* (max 1 alfe--col)))))
  *AUTOLISP_SOURCE_SCAN_STATE*)

(defun autolisp-source-leading-symbols (alfe--text alfe--count / alfe--idx alfe--len alfe--ch alfe--in-comment alfe--token alfe--start alfe--tokens)
  (setq alfe--idx 1)
  (setq alfe--len (strlen alfe--text))
  (setq alfe--in-comment nil)
  (setq alfe--tokens '())
  (while (and (<= alfe--idx alfe--len)
              (< (length alfe--tokens) alfe--count))
    (setq alfe--ch (substr alfe--text alfe--idx 1))
    (cond
      ((eq alfe--in-comment 'block)
       (if (autolisp-source-block-close-p alfe--text alfe--idx)
         (progn
           (setq alfe--in-comment nil)
           (setq alfe--idx (+ alfe--idx 2)))
         (setq alfe--idx (+ alfe--idx 1))))
      (alfe--in-comment
       (if (= alfe--ch "\n")
         (setq alfe--in-comment nil))
       (setq alfe--idx (+ alfe--idx 1)))
      ((autolisp-source-block-open-p alfe--text alfe--idx)
       (setq alfe--in-comment 'block)
       (setq alfe--idx (+ alfe--idx 2)))
      ((= alfe--ch ";")
       (setq alfe--in-comment 'line)
       (setq alfe--idx (+ alfe--idx 1)))
      ((member alfe--ch '(" " "\t" "\r" "\n" "(" ")"))
       (setq alfe--idx (+ alfe--idx 1)))
      (T
       (setq alfe--start alfe--idx)
       (while (and (<= alfe--idx alfe--len)
                   (not (member (substr alfe--text alfe--idx 1)
                                '(" " "\t" "\r" "\n" "(" ")" "\"" ";"))))
         (setq alfe--idx (+ alfe--idx 1)))
       (setq alfe--token (substr alfe--text alfe--start (- alfe--idx alfe--start)))
       (setq alfe--tokens (append alfe--tokens (list alfe--token))))))
  alfe--tokens)

(defun autolisp-source-leading-defun-name (alfe--text / alfe--tokens)
  (setq alfe--tokens (autolisp-source-leading-symbols alfe--text 2))
  (if (and (= (length alfe--tokens) 2)
           (= (strcase (car alfe--tokens)) "DEFUN"))
    (cadr alfe--tokens)
    nil))

(defun autolisp-source-trim-leading-junk (alfe--text / alfe--idx alfe--len alfe--ch alfe--in-comment alfe--done)
  ;; READ on BricsCAD can return NIL when the input string starts with
  ;; comment-only lines. Strip leading spaces/comments before READ so the
  ;; first real top-level form is what gets parsed.
  (setq alfe--idx 1)
  (setq alfe--len (strlen alfe--text))
  (setq alfe--in-comment nil)
  (setq alfe--done nil)
  (while (and (<= alfe--idx alfe--len) (not alfe--done))
    (setq alfe--ch (substr alfe--text alfe--idx 1))
    (cond
      ((eq alfe--in-comment 'block)
       (if (autolisp-source-block-close-p alfe--text alfe--idx)
         (progn
           (setq alfe--in-comment nil)
           (setq alfe--idx (+ alfe--idx 2)))
         (setq alfe--idx (+ alfe--idx 1))))
      (alfe--in-comment
       (if (= alfe--ch "\n")
         (setq alfe--in-comment nil))
       (setq alfe--idx (+ alfe--idx 1)))
      ((autolisp-source-block-open-p alfe--text alfe--idx)
       (setq alfe--in-comment 'block)
       (setq alfe--idx (+ alfe--idx 2)))
      ((= alfe--ch ";")
       (setq alfe--in-comment 'line)
       (setq alfe--idx (+ alfe--idx 1)))
      ((member alfe--ch '(" " "\t" "\r" "\n"))
       (setq alfe--idx (+ alfe--idx 1)))
      (T
       (setq alfe--done T))))
  (if (> alfe--idx alfe--len)
    ""
    (substr alfe--text alfe--idx)))

(defun autolisp-source-stack-text (/ alfe--paths alfe--acc)
  (setq alfe--paths (reverse *AUTOLISP_LOAD_STACK*))
  (setq alfe--acc "")
  (while alfe--paths
    (if (= alfe--acc "")
      (setq alfe--acc (car alfe--paths))
      (setq alfe--acc (strcat alfe--acc " -> " (car alfe--paths))))
    (setq alfe--paths (cdr alfe--paths)))
  alfe--acc)

(defun autolisp-source-format-error (alfe--path alfe--detail alfe--line alfe--col alfe--form-start alfe--defun-name / alfe--msg alfe--stack)
  (setq alfe--msg (strcat "while loading " alfe--path))
  (if alfe--form-start
    (setq alfe--msg (strcat alfe--msg " (form starting at line " (itoa alfe--form-start) ")")))
  (if alfe--line
    (setq alfe--msg (strcat alfe--msg " at line " (itoa alfe--line))))
  (if alfe--col
    (setq alfe--msg (strcat alfe--msg ", column " (itoa alfe--col))))
  (if (and alfe--defun-name (/= alfe--defun-name ""))
    (setq alfe--msg (strcat alfe--msg " in defun " alfe--defun-name)))
  (setq alfe--msg (strcat alfe--msg ": " alfe--detail))
  (setq alfe--stack (autolisp-source-stack-text))
  (if (and alfe--stack (/= alfe--stack "") (> (length *AUTOLISP_LOAD_STACK*) 1))
    (setq alfe--msg (strcat alfe--msg " [load stack: " alfe--stack "]")))
  alfe--msg)

;;; Raising an error WITHOUT the `error' function.
;;;
;;; alfe-autocad-error-primitive-masks-load-failure. `error' is NOT an
;;; AutoLISP function: the autolisp-spec documents none (only
;;; vl-exit-with-error, which is VLX-scoped). BricsCAD and clautolisp
;;; provide one as an extension; AutoCAD does not. So on AutoCAD every
;;; rethrow in this runtime failed with "no function definition: ERROR",
;;; which REPLACED the diagnostic the source loader had just assembled --
;;; and since an undefined-function error is signalled while RESOLVING
;;; the symbol, it escapes vl-catch-all-apply, so a failed nested load
;;; could even be published as a success.
;;;
;;; The runtime therefore raises with arithmetic: (/ 1 0) fails on every
;;; supported host and IS trappable. The message travels the way the
;;; source loader's own diagnostic already travelled, in
;;; *AUTOLISP_LAST_ERROR_CONTEXT*, which autolisp-effective-error-message
;;; prefers over whatever text the host produced for the arithmetic --
;;; so the inner pathname, line, column, form start and nested load stack
;;; all survive.
;;;
;;; The three statements make the abort certain even on a host that would
;;; tolerate a division by zero: the last is an undefined function, which
;;; no host survives. It is unreachable on every host we know.
(defun autolisp-force-error ()
  (/ 1 0)
  (car 0)
  (__autolisp-force-error-no-such-function))

(defun autolisp-raise (alfe--msg)
  (if (autolisp-quit-signal-p alfe--msg)
    ;; A quit is a control signal, not a diagnostic: do not put it in
    ;; the error context (it would be reported as an error message).
    ;; The protocol loop and the batch paths recognise a quit by
    ;; *AUTOLISP_QUIT_REQUESTED*, which they test BEFORE the message.
    (setq *AUTOLISP_QUIT_REQUESTED* T)
    ;; A caller that already assembled a context (the source loader)
    ;; keeps it; a bare raise becomes the context itself.
    (if (or (not (boundp '*AUTOLISP_LAST_ERROR_CONTEXT*))
            (null *AUTOLISP_LAST_ERROR_CONTEXT*)
            (= *AUTOLISP_LAST_ERROR_CONTEXT* ""))
      ;; An EMPTY message must still win over the arithmetic used to
      ;; raise: an empty context loses to the host's "divide by zero",
      ;; and the user would be told something this runtime did, not what
      ;; happened. Say plainly that there was no message; the loop then
      ;; adds the form (alfe-cad-load-error-message-says-only-error).
      (setq *AUTOLISP_LAST_ERROR_CONTEXT*
            (if (or (null alfe--msg) (/= (type alfe--msg) 'STR) (= (autolisp-str alfe--msg) ""))
                "the engine supplied no message"
                (autolisp-str alfe--msg)))))
  (autolisp-force-error))

(defun autolisp-effective-error-message (alfe--fallback)
  (if (and (boundp '*AUTOLISP_LAST_ERROR_CONTEXT*)
           *AUTOLISP_LAST_ERROR_CONTEXT*
           (/= *AUTOLISP_LAST_ERROR_CONTEXT* ""))
    *AUTOLISP_LAST_ERROR_CONTEXT*
    alfe--fallback))

(defun autolisp-clear-last-error-context ()
  (setq *AUTOLISP_LAST_ERROR_CONTEXT* nil))

(defun autolisp-source-pop-stack ()
  (if *AUTOLISP_LOAD_STACK*
    (setq *AUTOLISP_LOAD_STACK* (cdr *AUTOLISP_LOAD_STACK*)))
  nil)

(defun autolisp-source-raise (alfe--path alfe--detail alfe--line alfe--col alfe--form-start alfe--defun-name / alfe--msg)
  (setq alfe--msg (autolisp-source-format-error alfe--path alfe--detail alfe--line alfe--col alfe--form-start alfe--defun-name))
  (setq *AUTOLISP_LAST_ERROR_CONTEXT* alfe--msg)
  (autolisp-source-pop-stack)
  (autolisp-raise alfe--msg))

(defun autolisp-source-load-failure (alfe--onfailure)
  (if (= (type alfe--onfailure) 'SYM)
    (eval alfe--onfailure)
    alfe--onfailure))

;; T when PATH names a file that opens for reading. findfile searches the
;; CAD Support File Search Path, NOT the current directory -- on AutoCAD
;; accoreconsole a bare relative name of a file in the cwd is not found by
;; findfile, though native (open)/(load) resolve it (and BricsCAD's findfile
;; does search the cwd). So the resolver below falls back to a direct open
;; test. accoreconsole-deported-load-highbyte.
(defun autolisp-source-file-openable-p (alfe--path / alfe--f)
  (setq alfe--f (open alfe--path "r"))
  (if alfe--f
    (progn (close alfe--f) T)
    nil))

(defun autolisp-source-resolve-load-path (alfe--path / alfe--found alfe--home)
  (setq alfe--found (findfile alfe--path))
  (if (not alfe--found)
    (setq alfe--found (findfile (strcat alfe--path ".lsp"))))
  ;; cwd-relative / absolute paths findfile's support-path search misses:
  ;; accept the path as given (then +".lsp") when it actually opens.
  (if (not alfe--found)
    (if (autolisp-source-file-openable-p alfe--path)
      (setq alfe--found alfe--path)))
  (if (not alfe--found)
    (if (autolisp-source-file-openable-p (strcat alfe--path ".lsp"))
      (setq alfe--found (strcat alfe--path ".lsp"))))
  (if (not alfe--found)
    (if (and (> (strlen alfe--path) 1)
             (= (substr alfe--path 1 2) "~/"))
      (progn
        (setq alfe--home (getenv "HOME"))
        (if alfe--home
          (progn
            (setq alfe--found (findfile (strcat alfe--home (substr alfe--path 2))))
            (if (not alfe--found)
              (setq alfe--found (findfile (strcat alfe--home (substr alfe--path 2) ".lsp")))))))))
  alfe--found)

;; Run the loaded-file's read+eval loop. Extracted from
;; `autolisp-source-load-core-impl' so the outer function can wrap
;; this body in a `vl-catch-all-apply' and reliably restore
;; *AUTOLISP-LOAD-PATHNAME* on the way out, even when the loaded
;; file errors part-way through. See
;; `issues/closed/autolisp-load-pathname.issue'.
(defun autolisp-source-load-run-body (alfe--resolved /)
  (setq *AUTOLISP_LOAD_STACK* (cons alfe--resolved *AUTOLISP_LOAD_STACK*))
  (autolisp-source-load-run-body-impl alfe--resolved))

(defun autolisp-source-load-core-impl (alfe--path alfe--has-onfailure alfe--onfailure / alfe--resolved alfe--prev-load-pathname alfe--catch-result)
  (setq alfe--resolved (autolisp-source-resolve-load-path alfe--path))
  (if (not alfe--resolved)
    (if alfe--has-onfailure
      (autolisp-source-load-failure alfe--onfailure)
      (autolisp-raise (strcat "LOAD failed: \"" alfe--path "\"")))
    (progn
      ;; Bind *AUTOLISP-LOAD-PATHNAME* (both hyphen and underscore
      ;; spellings, per the project's convention) to the absolute
      ;; resolved pathname. autolisp-source-resolve-load-path delegates
      ;; to `findfile' which returns the absolute path for any matched
      ;; candidate, so `resolved' is already absolute. We save the
      ;; prior value and restore it on the way out (or clear to nil at
      ;; top level), so nested loads compose correctly and an error
      ;; in the loaded file doesn't leak a stale value back to the
      ;; caller. See `issues/closed/autolisp-load-pathname.issue'.
      (setq alfe--prev-load-pathname
        (if (boundp '*AUTOLISP-LOAD-PATHNAME*) *AUTOLISP-LOAD-PATHNAME* nil))
      (setq *AUTOLISP-LOAD-PATHNAME* alfe--resolved)
      (setq *AUTOLISP_LOAD_PATHNAME* alfe--resolved)
      (setq alfe--catch-result
        (vl-catch-all-apply 'autolisp-source-load-run-body
                            (list alfe--resolved)))
      (setq *AUTOLISP-LOAD-PATHNAME* alfe--prev-load-pathname)
      (setq *AUTOLISP_LOAD_PATHNAME* alfe--prev-load-pathname)
      (if (vl-catch-all-error-p alfe--catch-result)
        (autolisp-raise (vl-catch-all-error-message alfe--catch-result))
        alfe--catch-result))))

;; --- G3: native (load) honours the resolved `source' encoding -------------
;;
;; The front-end publishes the EXPLICITLY-requested source encoding as
;; *AUTOLISP-CAD-LOAD-ENCODING* (empty when the user did not pass -Esource).
;; When set, open the source file the way THIS backend understands
;; (*AUTOLISP-BACKEND*): BricsCAD "r,ccs=ENC"; clautolisp reads
;; *AUTOLISP-FILE-ENCODING* itself so a bare open suffices; and AutoCAD a
;; bare open too. AutoCAD 2022's OPEN, measured (E1, job 16980926802): at
;; LISPSYS 0 any third argument is an error; at LISPSYS 1 / 2 a plain "r"
;; decodes UTF-8 -- BOM skipped -- and falls back to cp1252 on a byte that is
;; not UTF-8, while "r" "utf8" returns the BOM as a character (65279) and
;; stops reading at the first such byte. So the third argument is never
;; better than the plain read, and is worse at LISPSYS 1 / 2.
;; ANY failure -- an unsupported 3rd arg at AutoCAD LISPSYS 0, an unknown ccs
;; -- falls back to the bare "r" open, so a load can NEVER break because of
;; this. Empty encoding => bare open => the pre-G3 behaviour, unchanged.
;;
;; NB: THIS file (and the rest of the vendored runtime) still must stay pure
;; ASCII -- it is sourced by the CAD to BOOTSTRAP the encoding machinery,
;; before *AUTOLISP-CAD-LOAD-ENCODING* exists. G3 governs the USER files the
;; shim loads, not the runtime itself, so the ASCII-only rule below stands.

(defun autolisp-source-enc-canon (alfe--s / alfe--out alfe--i alfe--c)
  ;; upcase and drop "-"/"_" so "utf-8" "UTF8" "utf_8" all fold to "UTF8".
  (setq alfe--out "" alfe--i 1)
  (while (<= alfe--i (strlen alfe--s))
    (setq alfe--c (substr alfe--s alfe--i 1))
    (if (and (/= alfe--c "-") (/= alfe--c "_"))
      (setq alfe--out (strcat alfe--out (strcase alfe--c))))
    (setq alfe--i (1+ alfe--i)))
  alfe--out)

(defun autolisp-source-open-encoded-try (alfe--path alfe--enc alfe--backend / alfe--u)
  (setq alfe--u (autolisp-source-enc-canon alfe--enc))
  (cond
    ((= alfe--backend "BRICSCAD")
     (cond ((= alfe--u "UTF8")    (open alfe--path "r,ccs=UTF-8"))
           ((= alfe--u "UTF16LE") (open alfe--path "r,ccs=UTF-16LE"))
           (T               (open alfe--path "r"))))    ; ANSI default handles latin-1
    ((= alfe--backend "AUTOCAD")
     (open alfe--path "r"))                              ; LISPSYS decides (see above)
    (T                      (open alfe--path "r"))))     ; clautolisp reads the var itself

(defun autolisp-source-open-encoded (alfe--path / alfe--enc alfe--backend alfe--f)
  (setq alfe--enc (if (boundp '*AUTOLISP-CAD-LOAD-ENCODING*) *AUTOLISP-CAD-LOAD-ENCODING* nil))
  (setq alfe--backend (if (boundp '*AUTOLISP-BACKEND*) *AUTOLISP-BACKEND* nil))
  (if (or (null alfe--enc) (= alfe--enc "") (null alfe--backend))
    (open alfe--path "r")                                ; behaviour-preserving default
    (progn
      (setq alfe--f (vl-catch-all-apply 'autolisp-source-open-encoded-try
                                  (list alfe--path alfe--enc alfe--backend)))
      (if (or (vl-catch-all-error-p alfe--f) (null alfe--f))
        (open alfe--path "r")                            ; robust fallback on any failure
        alfe--f))))

;; Where the FIRST top-level form in TEXT ends, as a 1-based index, or
;; NIL when TEXT holds no complete form.
;;
;; alfe-cad-source-loader-drops-a-second-form-on-a-line: the read loop
;; accumulates lines until the text scans as balanced, then called READ on
;; the whole of it. READ returns the FIRST form only, and the buffer was
;; then cleared -- so every later form on the same line was thrown away,
;; silently. (princ "x")(princ "y") printed only x; (setq a 1)(setq b 2)
;; left b unbound; no diagnostic anywhere. Two forms on one line is
;; ordinary AutoLISP (clautolisp's own loader runs both), so the loop
;; takes them one at a time, and that needs to know where the first ends.
;;
;; The conventions are autolisp-source-scan-text's: a string runs to its
;; unescaped closing quote, a semicolon comments out the rest of its line,
;; ;| comments out everything up to the next |;, everything else is
;; structure. A form is a parenthesised list -- ending
;; at the paren that brings the depth back to zero -- or a bare atom,
;; which ends before the first whitespace after it, or at end of text.
(defun autolisp-source-first-form-end
       (alfe--text / alfe--idx alfe--len alfe--ch alfe--depth alfe--in-string alfe--escape alfe--in-comment alfe--started alfe--found)
  (setq alfe--idx 1)
  (setq alfe--len (strlen alfe--text))
  (setq alfe--depth 0)
  (setq alfe--in-string nil)
  (setq alfe--escape nil)
  (setq alfe--in-comment nil)
  (setq alfe--started nil)
  (setq alfe--found nil)
  (while (and (<= alfe--idx alfe--len) (not alfe--found))
    (setq alfe--ch (substr alfe--text alfe--idx 1))
    (cond
      ((eq alfe--in-comment 'block)
       (if (autolisp-source-block-close-p alfe--text alfe--idx)
         (progn
           (setq alfe--in-comment nil)
           (setq alfe--idx (+ alfe--idx 1)))))
      (alfe--in-comment
       (if (= alfe--ch "\n") (setq alfe--in-comment nil)))
      (alfe--in-string
       (cond
         (alfe--escape (setq alfe--escape nil))
         ((= alfe--ch "\\") (setq alfe--escape T))
         ((= alfe--ch "\"")
          (setq alfe--in-string nil)
          ;; A string at top level is a complete form by itself.
          (if (= alfe--depth 0) (setq alfe--found alfe--idx)))))
      ((and alfe--started (= alfe--depth 0) (= alfe--ch ";"))
       ;; A comment ends a bare atom begun at top level.
       (setq alfe--found (- alfe--idx 1)))
      ((autolisp-source-block-open-p alfe--text alfe--idx)
       (setq alfe--in-comment 'block)
       (setq alfe--idx (+ alfe--idx 1)))
      ((= alfe--ch ";") (setq alfe--in-comment 'line))
      ((= alfe--ch "\"")
       (setq alfe--in-string T)
       (setq alfe--started T))
      ((= alfe--ch "(")
       (setq alfe--depth (+ alfe--depth 1))
       (setq alfe--started T))
      ((= alfe--ch ")")
       (setq alfe--depth (- alfe--depth 1))
       (if (<= alfe--depth 0) (setq alfe--found alfe--idx)))
      ((member alfe--ch (list " " "\t" "\r" "\n"))
       ;; Whitespace ends a bare atom begun at top level.
       (if (and alfe--started (= alfe--depth 0)) (setq alfe--found (- alfe--idx 1))))
      (T (setq alfe--started T)))
    (if (not alfe--found) (setq alfe--idx (+ alfe--idx 1))))
  ;; A bare atom that runs to the end of TEXT ends there.
  (if (and (not alfe--found) alfe--started (= alfe--depth 0)) (setq alfe--found alfe--len))
  alfe--found)

(defun autolisp-source-load-run-body-impl (alfe--resolved / alfe--f alfe--line alfe--line-no alfe--form-text alfe--form-start-line alfe--result alfe--form-read alfe--defun-name alfe--eval-result alfe--capture-old alfe--piece alfe--piece-end)
  (progn
      (setq alfe--f (autolisp-source-open-encoded alfe--resolved))
      (if (not alfe--f)
        (autolisp-source-raise alfe--resolved "unable to open source file" nil nil nil nil))
      (setq alfe--line-no 0)
      (setq alfe--form-text "")
      (setq alfe--form-start-line nil)
      (setq alfe--result nil)
      (while (setq alfe--line (read-line alfe--f))
        (setq alfe--line (vl-string-translate "\r" "" alfe--line))
        (setq alfe--line-no (+ alfe--line-no 1))
        (if (= alfe--form-text "")
          (setq alfe--form-start-line alfe--line-no))
        (if (= alfe--form-text "")
          (setq alfe--form-text alfe--line)
          (setq alfe--form-text (strcat alfe--form-text "\n" alfe--line)))
        (autolisp-source-scan-text alfe--form-text)
        (cond
          ((= *AUTOLISP_SOURCE_SCAN_STATE* 'extra)
           (close alfe--f)
           (autolisp-source-raise alfe--resolved
                                  "extra right parenthesis on input"
                                  *AUTOLISP_SOURCE_SCAN_LINE*
                                  *AUTOLISP_SOURCE_SCAN_COL*
                                  alfe--form-start-line
                                  (autolisp-source-leading-defun-name alfe--form-text)))
          ((= *AUTOLISP_SOURCE_SCAN_STATE* 'complete)
           ;; form-text can hold MORE THAN ONE form -- two forms on a line
           ;; is ordinary AutoLISP -- and READ returns only the first, so
           ;; take them one at a time and keep the remainder. Clearing the
           ;; buffer after the first is what silently discarded the rest
           ;; (alfe-cad-source-loader-drops-a-second-form-on-a-line).
           (setq alfe--piece-end (autolisp-source-first-form-end alfe--form-text))
           (while alfe--piece-end
           (setq alfe--piece (substr alfe--form-text 1 alfe--piece-end))
           (setq alfe--form-text (substr alfe--form-text (+ alfe--piece-end 1)))
           (setq alfe--defun-name (autolisp-source-leading-defun-name alfe--piece))
           (setq alfe--form-read
                 (vl-catch-all-apply 'read
                                     (list (autolisp-source-strip-block-comments
                                             (autolisp-source-trim-leading-junk alfe--piece)))))
           (if (vl-catch-all-error-p alfe--form-read)
             (progn
               (close alfe--f)
               (autolisp-source-raise alfe--resolved
                                      (autolisp-effective-error-message
                                        (vl-catch-all-error-message alfe--form-read))
                                      alfe--line-no
                                      1
                                      alfe--form-start-line
                                      alfe--defun-name))
             (progn
               (if (and (boundp '*load-verbose*) *load-verbose*)
                 (autolisp-emit-user-line
                   (strcat "LOADFORM " (autolisp-str alfe--form-read))))
               (setq alfe--capture-old *AUTOLISP_CAPTURE_STDOUT*)
               (setq *AUTOLISP_CAPTURE_STDOUT* T)
               ;; alfe-load drives this loop with *alfe-load-rewrite* set: it
               ;; rewrites native ops to alfe-* and evaluates DIRECTLY, so the
               ;; form is never re-serialised to alfe-eval.lsp and native-loaded
               ;; (which re-introduces a high byte that chokes AutoCAD). The
               ;; default protocol path keeps going through eval-request-form,
               ;; WITH the form's own text: on a CAD that text is what reaches
               ;; the native LOAD, so a real literal keeps every digit the
               ;; file gave it (alfe-cad-transport-rounds-reals).
               (setq alfe--eval-result
                 (if (and (boundp '*alfe-load-rewrite*) *alfe-load-rewrite*)
                   (vl-catch-all-apply 'alfe-eval-rewritten-form
                                       (list alfe--form-read))
                   (vl-catch-all-apply 'autolisp-eval-request-source
                                       (list alfe--form-read
                                             (autolisp-first-form-text alfe--piece)))))
               (setq *AUTOLISP_CAPTURE_STDOUT* alfe--capture-old)
               (if (vl-catch-all-error-p alfe--eval-result)
                 (if (or *AUTOLISP_QUIT_REQUESTED*
                         (autolisp-quit-signal-p
                           (vl-catch-all-error-message alfe--eval-result)))
                   (progn
                     (close alfe--f)
                     (autolisp-source-pop-stack)
                     (autolisp-raise *AUTOLISP_QUIT_SIGNAL*))
                   (progn
                     (close alfe--f)
                     (autolisp-source-raise alfe--resolved
                                            (autolisp-effective-error-message
                                              (vl-catch-all-error-message alfe--eval-result))
                                            alfe--form-start-line
                                            1
                                            alfe--form-start-line
                                            alfe--defun-name)))
                 (setq alfe--result alfe--eval-result))))
           ;; Another form on the same line?
           (autolisp-source-scan-text alfe--form-text)
           (if (= *AUTOLISP_SOURCE_SCAN_STATE* 'complete)
             (setq alfe--piece-end (autolisp-source-first-form-end alfe--form-text))
             (setq alfe--piece-end nil)))
           ;; What is left is either nothing of substance -- whitespace or
           ;; a trailing comment -- or the start of a form the next lines
           ;; continue -- or a block comment they continue. Keep the latter,
           ;; and let it own the current line.
           (if (member *AUTOLISP_SOURCE_SCAN_STATE* '(incomplete incomplete-comment))
             (setq alfe--form-start-line alfe--line-no)
             (progn
               (setq alfe--form-text "")
               (setq alfe--form-start-line nil))))))
      (close alfe--f)
      (if (/= alfe--form-text "")
        (progn
          (autolisp-source-scan-text alfe--form-text)
          ;; A non-empty form-text whose scan state is 'empty contains
          ;; only whitespace and/or comments -- not an unclosed form.
          ;; That happens whenever the source file's last non-blank
          ;; line is a comment. Treat it as benign EOF (the comment
          ;; is silently discarded, just like comments encountered
          ;; mid-file) rather than raising "unexpected end of file".
          ;; Keep this file ASCII-only: every byte > 127 has caused a
          ;; BricsCAD / clautolisp LOAD failure ("ASCII stream decoding
          ;; error on octet sequence #(226)") -- the em-dash that used
          ;; to live in this comment was exactly such a byte. G3 makes the
          ;; shim honour the encoding for USER files (autolisp-source-open-
          ;; encoded above), but the vendored runtime+bootstrap themselves
          ;; still stay pure ASCII: they are sourced by the CAD to BOOTSTRAP
          ;; the encoding machinery, before *AUTOLISP-CAD-LOAD-ENCODING* even
          ;; exists, so they cannot rely on it for their own decode.
          (if (/= *AUTOLISP_SOURCE_SCAN_STATE* 'empty)
            (autolisp-source-raise alfe--resolved
                                   (cond
                                     ((= *AUTOLISP_SOURCE_SCAN_STATE* 'incomplete-string)
                                      "unexpected end of file while reading string")
                                     ((= *AUTOLISP_SOURCE_SCAN_STATE* 'incomplete-comment)
                                      "unexpected end of file in a ;| block comment")
                                     (T
                                      "unexpected end of file while reading form"))
                                   alfe--line-no
                                   1
                                   alfe--form-start-line
                                   (autolisp-source-leading-defun-name alfe--form-text)))))
      ;; The documented LOAD contract is to return the loaded filename on
      ;; success, not the last evaluated form.
      (setq alfe--result alfe--resolved)
      (autolisp-source-pop-stack)
      alfe--result))

(defun autolisp-source-load (alfe--path /)
  (autolisp-source-load-core-impl alfe--path nil nil))

(defun autolisp-source-load-with-onfailure (alfe--path alfe--onfailure /)
  (autolisp-source-load-core-impl alfe--path T alfe--onfailure))

;; --- alfe-* interface operators (fixed arity) -----------------------------
;;
;; accoreconsole-deported-load-highbyte: AutoCAD's native (load) chokes on a
;; high byte, and we cannot fix that by SHADOWING (load)/(princ)/... --
;; AutoCAD has no variadic user functions, so a shadow must be fixed-arity,
;; and re-routing every (load) through the deporting shim re-enters the
;; protocol server loop. Instead we expose fixed-arity alfe-* operators and
;; have alfe-load REWRITE the calls in the code it loads: (princ a b) becomes
;; (alfe-princ* (list a b)), (load p) becomes (alfe-load* (list p)), etc. The
;; star forms take exactly ONE argument -- the argument LIST -- so any arity
;; maps to a fixed-arity call, no &rest needed on any host. Ordinary user code
;; that alfe does NOT load keeps calling the native operators (losing the
;; deportation/redirection, which is fine since alfe owns the code that needs
;; it -- test scenarios and the REPL).
;;
;; alfe-load also evaluates the rewritten forms DIRECTLY (not via the emitted
;; autolisp-eval-request-form, which re-serialises each form to alfe-eval.lsp
;; and native-loads it -- re-introducing the very high byte that chokes
;; AutoCAD). Direct eval keeps the byte-decoded string in memory.

(setq *alfe-load-rewrite* nil)   ; T only while alfe-load drives the read loop

;; Output operators: one argument, the arg list, mirroring the runtime's
;; princ/print/prin1 framing. A file descriptor in the second slot writes
;; there; otherwise output goes to the captured user stream.
(defun alfe-princ* (alfe--args)
  (cond
    ((null alfe--args) (autolisp-princ-newline))
    ((cadr alfe--args)
     (autolisp-write-string-to-file (autolisp-str (car alfe--args)) (cadr alfe--args))
     (car alfe--args))
    (T (autolisp-emit-user-line (autolisp-str (car alfe--args))) (car alfe--args))))

(defun alfe-print* (alfe--args)
  (cond
    ((null alfe--args) (autolisp-princ-newline))
    ((cadr alfe--args)
     (autolisp-write-string-to-file
       (strcat "\n" (autolisp-stdout-text (car alfe--args)) " ") (cadr alfe--args))
     (car alfe--args))
    (T (autolisp-princ-newline) (autolisp-emit-user-out (car alfe--args)))))

(defun alfe-prin1* (alfe--args)
  (cond
    ((null alfe--args) (autolisp-emit-user-out nil))
    ((cadr alfe--args)
     (autolisp-write-string-to-file (autolisp-stdout-text (car alfe--args)) (cadr alfe--args))
     (car alfe--args))
    (T (autolisp-emit-user-out (car alfe--args)))))

;; One-argument conveniences for hand-written alfe-owned code.
(defun alfe-princ (alfe--obj) (alfe-princ* (list alfe--obj)))
(defun alfe-print (alfe--obj) (alfe-print* (list alfe--obj)))
(defun alfe-prin1 (alfe--obj) (alfe-prin1* (list alfe--obj)))

;; Deporting byte-safe loader. alfe-load / alfe-load-onfailure are the
;; fixed-arity entry points; alfe-load* takes the arg list (what the rewriter
;; emits). autolisp-source-load reads the file honouring its encoding
;; (autolisp-source-open-encoded) via read-line, and -- with *alfe-load-rewrite*
;; set -- the read loop evaluates each form through alfe-eval-rewritten-form.
(defun alfe-load (alfe--path / alfe--prev alfe--result)
  (setq alfe--prev (if (boundp '*alfe-load-rewrite*) *alfe-load-rewrite* nil))
  (setq *alfe-load-rewrite* T)
  (setq alfe--result (vl-catch-all-apply 'autolisp-source-load (list alfe--path)))
  (setq *alfe-load-rewrite* alfe--prev)
  (if (vl-catch-all-error-p alfe--result)
    (autolisp-raise (vl-catch-all-error-message alfe--result))
    alfe--result))

(defun alfe-load-onfailure (alfe--path alfe--onfailure / alfe--prev alfe--result)
  (setq alfe--prev (if (boundp '*alfe-load-rewrite*) *alfe-load-rewrite* nil))
  (setq *alfe-load-rewrite* T)
  (setq alfe--result
        (vl-catch-all-apply 'autolisp-source-load-with-onfailure
                            (list alfe--path alfe--onfailure)))
  (setq *alfe-load-rewrite* alfe--prev)
  (if (vl-catch-all-error-p alfe--result)
    (autolisp-raise (vl-catch-all-error-message alfe--result))
    alfe--result))

(defun alfe-load* (alfe--args)
  (if (cdr alfe--args)
    (alfe-load-onfailure (car alfe--args) (cadr alfe--args))
    (alfe-load (car alfe--args))))

;; -Efile-write forwarded to the CAD's OPEN (encoding-situations-cli-options
;; section 6 point 5). alfe sets, in run-common.lsp, ONLY where the CAD
;; honours it (measured):
;;   *ALFE-OPEN-WRITE-CCS* -- BricsCAD on Windows: "w,ccs=UTF-8" (UTF-8 with a
;;     BOM) and "w,ccs=UTF-16LE" (with a BOM);
;;   *ALFE-OPEN-WRITE-ARG* -- AutoCAD: (open f "w" "utf8") writes UTF-8 without
;;     a BOM at LISPSYS 1 / 2, and (open f "a" "utf8") appends UTF-8 (measured
;;     2026-10-08: no BOM, and "utf8-bom" on an append adds no second one);
;;     at LISPSYS 0 any third argument is an error.
;; AutoCAD 2022 at LISPSYS 0 and BricsCAD on macOS ignore any encoding. With
;; neither set, OPEN calls are never rewritten (see alfe-form-needs-rewrite-p).
(defun alfe-open-ccs-active-p ()
  (and (boundp '*ALFE-OPEN-WRITE-CCS*)
       (= (type *ALFE-OPEN-WRITE-CCS*) 'STR)
       (> (strlen *ALFE-OPEN-WRITE-CCS*) 0)))

(defun alfe-open-arg-active-p ()
  (and (boundp '*ALFE-OPEN-WRITE-ARG*)
       (= (type *ALFE-OPEN-WRITE-ARG*) 'STR)
       (> (strlen *ALFE-OPEN-WRITE-ARG*) 0)))

(defun alfe-open-rewrite-p ()
  (or (alfe-open-ccs-active-p) (alfe-open-arg-active-p)))

;; T when AutoLISP is Unicode (LISPSYS 1 or 2), where AutoCAD's OPEN takes
;; its third argument. LISPSYS is read when AutoCAD starts; a CAD without it
;; (before 2021) is the ANSI case.
(defun alfe-lispsys-unicode-p ( / alfe--v)
  (setq alfe--v (vl-catch-all-apply 'getvar (list "LISPSYS")))
  (and (not (vl-catch-all-error-p alfe--v))
       (member alfe--v '(1 2))))

;; One warning per distinct text and run, on alfe's error channel.
(setq *alfe-open-warned* nil)
(defun alfe-open-warn (alfe--text)
  (if (not (member alfe--text *alfe-open-warned*))
    (progn
      (setq *alfe-open-warned* (cons alfe--text *alfe-open-warned*))
      (autolisp-log-err (strcat "WARN " alfe--text))))
  nil)

;; T iff ARGS is (path mode) with a plain "w" or "a" mode.
(defun alfe-open-plain-write-p (alfe--args)
  (and (= (length alfe--args) 2)
       (= (type (cadr alfe--args)) 'STR)
       (member (strcase (cadr alfe--args)) '("W" "A"))))

;; (open path mode [enc]) with its arguments as ONE list. A plain "w" / "a"
;; mode (no ",ccs=" of its own, no third argument) gets ",ccs=<ccs>"
;; appended, or the third argument <arg> when LISPSYS is 1 or 2. If the CAD
;; refuses either, the plain mode is used. Every other call is passed to OPEN
;; unchanged.
(defun alfe-open* (alfe--args / alfe--f)
  (cond
    ((and (alfe-open-ccs-active-p) (alfe-open-plain-write-p alfe--args))
     (setq alfe--f (vl-catch-all-apply
                     'open
                     (list (car alfe--args)
                           (strcat (cadr alfe--args) ",ccs=" *ALFE-OPEN-WRITE-CCS*))))
     (if (or (null alfe--f) (vl-catch-all-error-p alfe--f))
       (open (car alfe--args) (cadr alfe--args))
       alfe--f))
    ((and (alfe-open-arg-active-p) (alfe-open-plain-write-p alfe--args))
     (cond
       ((not (alfe-lispsys-unicode-p))
        (alfe-open-warn
          (strcat "-Efile-write: not forwarded, LISPSYS is "
                  (vl-prin1-to-string (getvar "LISPSYS"))
                  ": AutoCAD's OPEN takes an encoding only at LISPSYS 1 or 2"
                  " (measured, AutoCAD 2022); files are written in cp1252."))
        (open (car alfe--args) (cadr alfe--args)))
       (T
        (setq alfe--f (vl-catch-all-apply
                        'open
                        (list (car alfe--args) (cadr alfe--args)
                              *ALFE-OPEN-WRITE-ARG*)))
        (if (or (null alfe--f) (vl-catch-all-error-p alfe--f))
          (open (car alfe--args) (cadr alfe--args))
          alfe--f))))
    (T (apply 'open alfe--args))))

;; T iff FORM contains a native princ/print/prin1/load CALL that needs
;; rewriting. Walks without consing; stops at QUOTE / FUNCTION so quoted
;; data never false-positives. This is the CONS-IDENTITY GUARD: unless a
;; form actually contains one of these calls, alfe-rewrite-form must return
;; it UNTOUCHED. Re-consing a form and then eval'ing it breaks on the CAD
;; backends -- the reader attaches per-cell metadata that a rebuilt cons
;; lacks, and AutoCAD then fails eval'ing it (observed as "division par
;; zero" on accoreconsole for EVERY alfe-load, ASCII or not). The princ
;; normalizer (autolisp-normalize-princ-call) is written the same way for
;; the same reason. OPEN counts only while *ALFE-OPEN-WRITE-CCS* or
;; *ALFE-OPEN-WRITE-ARG* is set (alfe-open-rewrite-p), so without a forwarded
;; -Efile-write nothing more is rebuilt.
(defun alfe-form-needs-rewrite-p (alfe--form / alfe--head alfe--s)
  (cond
    ((atom alfe--form) nil)
    ((not (listp alfe--form)) nil)
    ((null alfe--form) nil)
    (T
     (setq alfe--head (car alfe--form))
     (cond
       ((and (= (type alfe--head) 'SYM)
             (progn (setq alfe--s (strcase (vl-symbol-name alfe--head)))
                    (or (= alfe--s "QUOTE") (= alfe--s "FUNCTION"))))
        nil)
       ((and (= (type alfe--head) 'SYM)
             (or (= alfe--s "PRINC") (= alfe--s "PRINT") (= alfe--s "PRIN1") (= alfe--s "LOAD")
                 (and (= alfe--s "OPEN") (alfe-open-rewrite-p))))
        T)
       (T
        (cond
          ((alfe-form-needs-rewrite-p (car alfe--form)) T)
          ((alfe-form-needs-rewrite-p (cdr alfe--form)) T)
          (T nil)))))))

;; Rewrite a form's native operator calls into alfe-* calls. The star forms
;; take the arg list, so a variadic call maps to a fixed-arity one. Only
;; called (via alfe-rewrite-form) when the pre-check found a call to rewrite,
;; so a form with none keeps its reader-built cons cells intact.
(defun alfe-rewrite-form-impl (alfe--form / alfe--head alfe--s)
  (cond
    ((atom alfe--form) alfe--form)
    ((not (listp alfe--form)) alfe--form)
    ((null alfe--form) alfe--form)
    (T
     (setq alfe--head (car alfe--form))
     (cond
       ((and (= (type alfe--head) 'SYM)
             (progn (setq alfe--s (strcase (vl-symbol-name alfe--head)))
                    (or (= alfe--s "QUOTE") (= alfe--s "FUNCTION"))))
        alfe--form)
       ((and (= (type alfe--head) 'SYM) (= alfe--s "PRINC"))
        (list 'alfe-princ* (cons 'list (mapcar 'alfe-rewrite-form (cdr alfe--form)))))
       ((and (= (type alfe--head) 'SYM) (= alfe--s "PRINT"))
        (list 'alfe-print* (cons 'list (mapcar 'alfe-rewrite-form (cdr alfe--form)))))
       ((and (= (type alfe--head) 'SYM) (= alfe--s "PRIN1"))
        (list 'alfe-prin1* (cons 'list (mapcar 'alfe-rewrite-form (cdr alfe--form)))))
       ((and (= (type alfe--head) 'SYM) (= alfe--s "LOAD"))
        (list 'alfe-load* (cons 'list (mapcar 'alfe-rewrite-form (cdr alfe--form)))))
       ((and (= (type alfe--head) 'SYM) (= alfe--s "OPEN") (alfe-open-rewrite-p))
        (list 'alfe-open* (cons 'list (mapcar 'alfe-rewrite-form (cdr alfe--form)))))
       (T
        (mapcar 'alfe-rewrite-form alfe--form))))))

;; Cons-identity-preserving entry point: an untouched form is returned as-is
;; (same cons cells), so only forms that really carry a native operator call
;; are rebuilt. See alfe-form-needs-rewrite-p.
(defun alfe-rewrite-form (alfe--form)
  (if (alfe-form-needs-rewrite-p alfe--form)
    (alfe-rewrite-form-impl alfe--form)
    alfe--form))

(defun alfe-eval-rewritten-form (alfe--form)
  (eval (alfe-rewrite-form alfe--form)))

;; --- -Efile-write on EVERY action, not only in alfe-loaded code ----------
;;
;; alfe-efile-write-not-applied-to-l-file (pjb 2026-10-08: "apply
;; -Efile-write to -l and -x too"). The -l file, -x forms, --main, REPL input
;; and every other protocol request reach the CAD through
;; autolisp-eval-request-source, which hands the request's own TEXT to the
;; CAD's native LOAD (alfe-cad-transport-rounds-reals: a re-print loses the
;; digits of a real). So OPEN is rewritten there IN THE TEXT: each OPEN call
;; "(open a b)" becomes "(alfe-open* (list a b))", and every other character
;; of the source is kept as written. Shadowing OPEN itself cannot do it:
;; AutoCAD has no &rest, and OPEN takes two or three arguments.
;;
;; Only OPEN, and only while -Efile-write is forwarded (alfe-open-rewrite-p):
;; without it nothing here runs and no request changes. princ/print/prin1/
;; load keep their own (request-path) handling -- unlike alfe-load, which
;; rewrites them too.

;; T iff FORM contains an OPEN call, outside QUOTE / FUNCTION. Walks without
;; consing, like alfe-form-needs-rewrite-p, but for OPEN alone.
(defun alfe-form-has-open-call-p (alfe--form / alfe--head alfe--s)
  (cond
    ((atom alfe--form) nil)
    ((not (listp alfe--form)) nil)
    ((null alfe--form) nil)
    (T
     (setq alfe--head (car alfe--form))
     (cond
       ((and (= (type alfe--head) 'SYM)
             (progn (setq alfe--s (strcase (vl-symbol-name alfe--head)))
                    (or (= alfe--s "QUOTE") (= alfe--s "FUNCTION"))))
        nil)
       ((and (= (type alfe--head) 'SYM) (= alfe--s "OPEN")) T)
       ((alfe-form-has-open-call-p (car alfe--form)) T)
       ((alfe-form-has-open-call-p (cdr alfe--form)) T)
       (T nil)))))

(defun alfe-rewrite-open-calls-impl (alfe--form / alfe--head alfe--s)
  (cond
    ((atom alfe--form) alfe--form)
    ((not (listp alfe--form)) alfe--form)
    ((null alfe--form) alfe--form)
    (T
     (setq alfe--head (car alfe--form))
     (cond
       ((and (= (type alfe--head) 'SYM)
             (progn (setq alfe--s (strcase (vl-symbol-name alfe--head)))
                    (or (= alfe--s "QUOTE") (= alfe--s "FUNCTION"))))
        alfe--form)
       ((and (= (type alfe--head) 'SYM) (= alfe--s "OPEN"))
        (list 'alfe-open* (cons 'list (mapcar 'alfe-rewrite-open-calls (cdr alfe--form)))))
       (T
        (mapcar 'alfe-rewrite-open-calls alfe--form))))))

;; FORM with its OPEN calls turned into alfe-open* calls -- the SAME conses
;; when it has none (the cons-identity guard of alfe-rewrite-form).
(defun alfe-rewrite-open-calls (alfe--form)
  (if (alfe-form-has-open-call-p alfe--form)
    (alfe-rewrite-open-calls-impl alfe--form)
    alfe--form))

;; T iff a request FORM must have its OPEN calls rewritten: -Efile-write is
;; forwarded AND the form calls OPEN.
(defun alfe-open-request-p (alfe--form)
  (and (alfe-open-rewrite-p) (alfe-form-has-open-call-p alfe--form)))

(defun alfe-open-text-delimiter-p (alfe--ch)
  (member alfe--ch '(" " "\t" "\r" "\n" "(" ")" "'" "\"" ";")))

;; The token heading the list whose open paren is at IDX of TEXT, as
;; (START . TOKEN), or NIL when the list starts with no token.
(defun alfe-open-text-head (alfe--text alfe--idx alfe--len / alfe--j alfe--start)
  (setq alfe--j (+ alfe--idx 1))
  (while (and (<= alfe--j alfe--len) (member (substr alfe--text alfe--j 1) '(" " "\t" "\r" "\n")))
    (setq alfe--j (+ alfe--j 1)))
  (setq alfe--start alfe--j)
  (while (and (<= alfe--j alfe--len) (not (alfe-open-text-delimiter-p (substr alfe--text alfe--j 1))))
    (setq alfe--j (+ alfe--j 1)))
  (if (> alfe--j alfe--start) (cons alfe--start (substr alfe--text alfe--start (- alfe--j alfe--start))) nil))

;; TEXT, the source of one form, with every OPEN call "(open ARGS)" written
;; "(alfe-open* (list ARGS))" -- the textual twin of alfe-rewrite-open-calls:
;; a list quoted by ' or headed by QUOTE / FUNCTION is left alone, strings and
;; comments (; and ;| |;) are skipped. Nothing else of TEXT changes, so a real
;; literal keeps every digit it was written with.
(defun alfe-open-rewrite-text (alfe--text / alfe--idx alfe--len alfe--ch alfe--nx alfe--stack alfe--quoted alfe--pending alfe--in-string alfe--escape alfe--in-comment alfe--in-block alfe--head alfe--s alfe--child-quoted alfe--open-p alfe--edits alfe--out alfe--pos alfe--e)
  (setq alfe--idx 1)
  (setq alfe--len (strlen alfe--text))
  (setq alfe--stack nil)
  (setq alfe--pending nil)
  (setq alfe--in-string nil)
  (setq alfe--escape nil)
  (setq alfe--in-comment nil)
  (setq alfe--in-block nil)
  (setq alfe--edits nil)
  (while (<= alfe--idx alfe--len)
    (setq alfe--ch (substr alfe--text alfe--idx 1))
    (setq alfe--nx (if (< alfe--idx alfe--len) (substr alfe--text (+ alfe--idx 1) 1) ""))
    (cond
      (alfe--in-block
       (if (and (= alfe--ch "|") (= alfe--nx ";"))
         (progn (setq alfe--in-block nil) (setq alfe--idx (+ alfe--idx 1)))))
      (alfe--in-comment
       (if (= alfe--ch "\n") (setq alfe--in-comment nil)))
      (alfe--in-string
       (cond
         (alfe--escape (setq alfe--escape nil))
         ((= alfe--ch "\\") (setq alfe--escape T))
         ((= alfe--ch "\"") (setq alfe--in-string nil))))
      ((= alfe--ch ";")
       (if (= alfe--nx "|")
         (progn (setq alfe--in-block T) (setq alfe--idx (+ alfe--idx 1)))
         (setq alfe--in-comment T)))
      ((= alfe--ch "\"")
       (setq alfe--in-string T)
       (setq alfe--pending nil))
      ((= alfe--ch "'")
       (setq alfe--pending T))
      ((= alfe--ch "(")
       (setq alfe--quoted (or alfe--pending (and alfe--stack (car (car alfe--stack)))))
       (setq alfe--pending nil)
       (setq alfe--child-quoted alfe--quoted)
       (setq alfe--open-p nil)
       (if (not alfe--quoted)
         (progn
           (setq alfe--head (alfe-open-text-head alfe--text alfe--idx alfe--len))
           (if alfe--head
             (progn
               (setq alfe--s (strcase (cdr alfe--head)))
               (cond
                 ((= alfe--s "OPEN")
                  (setq alfe--open-p T)
                  (setq alfe--edits (cons (list (car alfe--head) (strlen (cdr alfe--head))
                                          "alfe-open* (list")
                                    alfe--edits)))
                 ((or (= alfe--s "QUOTE") (= alfe--s "FUNCTION"))
                  (setq alfe--child-quoted T)))))))
       (setq alfe--stack (cons (list alfe--child-quoted alfe--open-p) alfe--stack)))
      ((= alfe--ch ")")
       (if alfe--stack
         (progn
           (if (cadr (car alfe--stack))
             (setq alfe--edits (cons (list alfe--idx 0 ")") alfe--edits)))
           (setq alfe--stack (cdr alfe--stack)))))
      ((member alfe--ch '(" " "\t" "\r" "\n")) nil)
      (T (setq alfe--pending nil)))
    (setq alfe--idx (+ alfe--idx 1)))
  ;; The edits were collected left to right; splice them in.
  (setq alfe--out "")
  (setq alfe--pos 1)
  (foreach alfe--e (reverse alfe--edits)
    (if (> (car alfe--e) alfe--pos)
      (setq alfe--out (strcat alfe--out (substr alfe--text alfe--pos (- (car alfe--e) alfe--pos)))))
    (setq alfe--out (strcat alfe--out (caddr alfe--e)))
    (setq alfe--pos (+ (car alfe--e) (cadr alfe--e))))
  (if (<= alfe--pos alfe--len)
    (strcat alfe--out (substr alfe--text alfe--pos))
    alfe--out))

;; The text the CAD is given for a request FORM that calls OPEN while
;; -Efile-write is forwarded. NORMALIZED is FORM after the princ normaliser,
;; SOURCE the text FORM was read from (or NIL). When FORM was not rebuilt and
;; its SOURCE is at hand, that source is rewritten textually -- and used only
;; if it reads back EQUAL to the form-walk rewrite, so the CAD evaluates
;; exactly what alfe-load would have. Otherwise (no text, or the normaliser
;; rebuilt the form, which is then printed anyway) the rewritten form is
;; printed with autolisp-form-source-text, reals at full precision.
(defun alfe-open-request-text (alfe--form alfe--normalized alfe--source / alfe--rewritten alfe--text alfe--back)
  (setq alfe--rewritten (alfe-rewrite-open-calls alfe--normalized))
  (if (and alfe--source (eq alfe--normalized alfe--form))
    (progn
      (setq alfe--text (vl-catch-all-apply 'alfe-open-rewrite-text (list alfe--source)))
      (if (vl-catch-all-error-p alfe--text)
        (setq alfe--text nil))
      (if alfe--text
        (setq alfe--back (vl-catch-all-apply 'read (list alfe--text))))
      (if (and alfe--text (not (vl-catch-all-error-p alfe--back)) (equal alfe--back alfe--rewritten))
        alfe--text
        (autolisp-form-source-text alfe--rewritten)))
    (autolisp-form-source-text alfe--rewritten)))

(defun autolisp-internal-protocol-load-p (alfe--path)
  (and (= (type alfe--path) 'STR)
       (wcmatch alfe--path "*protocol-request-*.lsp")))

(defun autolisp-load-form-p (alfe--form)
  (and (listp alfe--form)
       alfe--form
       (= (type (car alfe--form)) 'SYM)
       (= (strcase (vl-symbol-name (car alfe--form))) "LOAD")))

;; Cheap-walk pre-check: T iff FORM contains a princ/print/prin1 call that the
;; fixed-arity no-&rest shadows can't take as written -- i.e. UNDER-arity: an
;; empty `(princ)' OR a 1-arg `(princ X)' / `(print X)' / `(prin1 X)'. On the
;; no-&rest host the shadows require (obj file); an under-arity call raises
;; "nombre d'arguments insuffisants" (the same trap that silently ate all probe
;; output on AutoCAD -- see autocad-no-rest-output-capture.issue), so the
;; rewriter below pads them. Walks the tree without consing. Stops at QUOTE /
;; FUNCTION exactly like the rewriter, so quoted data doesn't false-positive.
;; (On &rest hosts autolisp-normalize-princ-call is the identity, so none of
;; this runs -- BricsCAD is unaffected.)
(defun autolisp-form-contains-empty-princ-p (alfe--form / alfe--head alfe--s)
  (cond
    ((atom alfe--form) nil)
    ((not (listp alfe--form)) nil)
    ((null alfe--form) nil)
    (T
      (setq alfe--head (car alfe--form))
      (cond
        ((and (= (type alfe--head) 'SYM)
              (progn (setq alfe--s (strcase (vl-symbol-name alfe--head)))
                     (or (= alfe--s "QUOTE") (= alfe--s "FUNCTION"))))
          nil)
        ((and (= (type alfe--head) 'SYM)
              (or (= alfe--s "PRINC") (= alfe--s "PRINT") (= alfe--s "PRIN1"))
              (< (length alfe--form) 3))          ; 0 or 1 args on a 2-arg shadow
          T)
        ((and (= (type alfe--head) 'SYM)
              (= alfe--s "LOAD")
              (= (length alfe--form) 2))          ; 1-arg (load X) on a 2-arg shadow
          T)
        (T
          (cond
            ((autolisp-form-contains-empty-princ-p (car alfe--form)) T)
            ((autolisp-form-contains-empty-princ-p (cdr alfe--form)) T)
            (T nil)))))))

;; The actual rewriter — only called from `autolisp-normalize-princ-call'
;; when the pre-check confirmed there IS at least one empty `(princ)' to
;; replace. Rebuilds cons cells (necessary to inject the rewrite); see
;; the comment on autolisp-normalize-princ-call about why we don't want
;; this to run otherwise.
(defun autolisp-normalize-princ-call-impl (alfe--form / alfe--head alfe--s)
  (cond
    ((atom alfe--form)
     alfe--form)
    ((and (listp alfe--form) alfe--form)
     (setq alfe--head (car alfe--form))
     (cond
       ((and (= (type alfe--head) 'SYM)
             (progn (setq alfe--s (strcase (vl-symbol-name alfe--head)))
                    (or (= alfe--s "QUOTE") (= alfe--s "FUNCTION"))))
        alfe--form)
       ;; princ/print/prin1: the no-&rest shadows require (obj file), so pad
       ;; under-arity calls. Empty (princ) keeps its newline alias; a 1-arg
       ;; call gets the missing FILE = nil (the arg itself is walked too);
       ;; 2-arg (and odd larger) calls just recurse into their args. This
       ;; preserves the value contract -- princ returns its first arg.
       ((and (= (type alfe--head) 'SYM)
             (or (= alfe--s "PRINC") (= alfe--s "PRINT") (= alfe--s "PRIN1")))
        (cond
          ((= (length alfe--form) 1)
           (if (= alfe--s "PRINC")
             (list 'autolisp-princ-newline)
             (list alfe--head "" nil)))
          ((= (length alfe--form) 2)
           (list alfe--head
                 (autolisp-normalize-princ-call-impl (cadr alfe--form))
                 nil))
          (T
           (cons alfe--head (mapcar 'autolisp-normalize-princ-call-impl (cdr alfe--form))))))
       ;; `load' is likewise shadowed with a fixed (file onfailure) arity on the
       ;; no-&rest host (e.g. a vertical app's own load wrapper), so a 1-arg
       ;; (load X) trips the same too-few-args trap. Pad the missing ONFAILURE
       ;; with nil; 2-arg (load X F) passes through.
       ((and (= (type alfe--head) 'SYM)
             (= alfe--s "LOAD")
             (= (length alfe--form) 2))
        (list alfe--head
              (autolisp-normalize-princ-call-impl (cadr alfe--form))
              nil))
       (T
        (cons alfe--head (mapcar 'autolisp-normalize-princ-call-impl (cdr alfe--form))))))
    (T
     alfe--form)))

;; Rewrite bare `(princ)' calls (with no arguments) into
;; `(autolisp-princ-newline)' so the bootstrap-shadowed 1-arg `princ'
;; doesn't trip an arity error.
;;
;; CONS-IDENTITY-PRESERVING: when the form contains no empty `(princ)',
;; we return FORM untouched. The previous version recursively rebuilt
;; every cons cell unconditionally; under BricsCAD V26 that destroyed
;; the read-time per-cell metadata that the runtime's `mapcar' walker
;; consults to recognise an embedded `(lambda …)' as a function
;; literal — and so a form like
;;   (mapcar (lambda (x) (cons x x)) '(1 2 3))
;; came out of `(eval form)' fine on the raw command line but failed
;; with `bad argument type <1>; expected <CONS> at [car]' when sent
;; through the alfe protocol bridge (which had wrapped the form in
;; `(print …)' and re-cons'd it via normalize before eval'ing). The
;; cheap pre-check avoids the rebuild entirely for the 99% common case
;; — any user form that doesn't literally contain `(princ)' passes
;; through with the reader's cons-cell identity intact, and BricsCAD's
;; mapcar happily walks the lambda.
(defun autolisp-normalize-princ-call (alfe--form)
  (if (autolisp-form-contains-empty-princ-p alfe--form)
    (autolisp-normalize-princ-call-impl alfe--form)
    alfe--form))

(defun autolisp-eval-load-form (alfe--form)
  ;; The LOAD argument must be EVALUATED before it reaches the source loader:
  ;; (load p) / (load (strcat dir "f.lsp")) are as valid as (load "f.lsp").
  ;; Passing (cadr form) raw made findfile see the unevaluated expression and
  ;; fail with "bad argument type <P>; expected <STRING>" for anything but a
  ;; string literal (alfe-load-form-argument-not-evaluated). (eval x) on a
  ;; string literal is the string itself, so literals keep working.
  (cond
    ((and (= (length alfe--form) 2)
          (autolisp-internal-protocol-load-p (cadr alfe--form)))
     (eval alfe--form))
    ((= (length alfe--form) 2)
     (autolisp-source-load (eval (cadr alfe--form))))
    ((and (= (length alfe--form) 3)
          (autolisp-internal-protocol-load-p (cadr alfe--form)))
     (eval alfe--form))
    ((= (length alfe--form) 3)
     (autolisp-source-load-with-onfailure (eval (cadr alfe--form)) (eval (caddr alfe--form))))
    (T
     (eval alfe--form))))

(defun autolisp-eval-request-form (alfe--form)
  (setq alfe--form (autolisp-normalize-princ-call alfe--form))
  (if (autolisp-load-form-p alfe--form)
    (autolisp-eval-load-form alfe--form)
    ;; -Efile-write reaches the OPEN calls of every request
    ;; (alfe-efile-write-not-applied-to-l-file); the form is untouched
    ;; unless it is forwarded and the form calls OPEN.
    (eval (if (alfe-open-request-p alfe--form)
            (alfe-rewrite-open-calls alfe--form)
            alfe--form))))

;; The same request, with the SOURCE TEXT the form was read from (or NIL
;; when there is none). Every caller that read the form from text passes
;; that text along: alfe's run-common.lsp redefines this function to hand
;; the TEXT itself to the CAD's native LOAD instead of printing the form
;; back, which lost the digits of every real literal
;; (alfe-cad-transport-rounds-reals). Here, with no such override, the
;; text is not needed and the form is evaluated as before.
(defun autolisp-eval-request-source (alfe--form alfe--text)
  (autolisp-eval-request-form alfe--form))

;; The text of the FIRST form in TEXT -- leading blanks and comments
;; dropped, nothing after the form kept -- i.e. exactly what READ consumed
;; from it. NIL when TEXT is not a string or holds no complete form.
(defun autolisp-first-form-text (alfe--text / alfe--trimmed alfe--end)
  (if (= (type alfe--text) 'STR)
    (progn
      (setq alfe--trimmed (autolisp-source-trim-leading-junk alfe--text))
      (setq alfe--end (autolisp-source-first-form-end alfe--trimmed))
      (if alfe--end
        (substr alfe--trimmed 1 alfe--end)
        nil))
    nil))

(defun autolisp-run-load (alfe--idx alfe--path / alfe--r alfe--olderr)
  (autolisp-mark-begin "LOAD" alfe--idx)
  (autolisp-log-out (strcat "LOAD " alfe--path))
  (setq *AUTOLISP_CAPTURE_STDOUT* T)
  (setq *AUTOLISP_ERROR_MSG* nil)
  (setq alfe--olderr *error*)
  (setq *error* autolisp-trap-error)
  (setq alfe--r (autolisp-source-load alfe--path))
  (setq *error* alfe--olderr)
  (setq *AUTOLISP_CAPTURE_STDOUT* nil)
  (if *AUTOLISP_QUIT_REQUESTED*
    (autolisp-raise *AUTOLISP_QUIT_SIGNAL*)
    (if (autolisp-quit-signal-p *AUTOLISP_ERROR_MSG*)
      (autolisp-raise *AUTOLISP_QUIT_SIGNAL*)
    (if *AUTOLISP_ERROR_MSG*
      (progn
        (autolisp-log-err
          (strcat "ERROR load " alfe--path ": "
                  (autolisp-effective-error-message *AUTOLISP_ERROR_MSG*)))
        (autolisp-clear-last-error-context)
        (autolisp-mark-end "LOAD" alfe--idx 1)
        nil)
      (progn
        (autolisp-log-out (strcat "LOADED " alfe--path))
        (autolisp-mark-end "LOAD" alfe--idx 0)
        T)))))

(defun autolisp-trap-error (alfe--msg)
  (setq *AUTOLISP_ERROR_MSG* (autolisp-effective-error-message alfe--msg))
  (if (autolisp-quit-signal-p alfe--msg)
    (setq *AUTOLISP_QUIT_REQUESTED* T))
  nil)

(defun autolisp-run-eval-file (alfe--idx alfe--path / alfe--form-text alfe--form-read alfe--r alfe--olderr alfe--ok)
  (autolisp-mark-begin "EXPR" alfe--idx)
  (setq alfe--ok nil)
  (setq alfe--form-text (autolisp-slurp-file alfe--path))
  (if (null alfe--form-text)
    (progn
      (autolisp-log-err (strcat "ERROR read-file " alfe--path ": unable to open expression file"))
      (autolisp-mark-end "EXPR" alfe--idx 1))
    (progn
      (autolisp-log-out (strcat "EVAL " alfe--form-text))
      (setq *AUTOLISP_ERROR_MSG* nil)
      (setq alfe--olderr *error*)
      (setq *error* autolisp-trap-error)
      (setq alfe--form-read (read alfe--form-text))
      (setq *error* alfe--olderr)
      (if *AUTOLISP_QUIT_REQUESTED*
        (autolisp-raise *AUTOLISP_QUIT_SIGNAL*)
        (if (autolisp-quit-signal-p *AUTOLISP_ERROR_MSG*)
          (autolisp-raise *AUTOLISP_QUIT_SIGNAL*)
        (if *AUTOLISP_ERROR_MSG*
          (progn
            (autolisp-log-err (strcat "ERROR read " alfe--form-text ": " *AUTOLISP_ERROR_MSG*))
            (autolisp-mark-end "EXPR" alfe--idx 1))
          (progn
            (setq *AUTOLISP_CAPTURE_STDOUT* T)
            (setq *AUTOLISP_ERROR_MSG* nil)
            (setq alfe--olderr *error*)
            (setq *error* autolisp-trap-error)
            (setq alfe--r (autolisp-eval-request-source
                            alfe--form-read
                            (autolisp-first-form-text alfe--form-text)))
            (setq *error* alfe--olderr)
            (setq *AUTOLISP_CAPTURE_STDOUT* nil)
            (if *AUTOLISP_QUIT_REQUESTED*
              (autolisp-raise *AUTOLISP_QUIT_SIGNAL*)
              (if (autolisp-quit-signal-p *AUTOLISP_ERROR_MSG*)
                (autolisp-raise *AUTOLISP_QUIT_SIGNAL*)
              (if *AUTOLISP_ERROR_MSG*
                (progn
                  (autolisp-log-err (strcat "ERROR eval " alfe--form-text ": " *AUTOLISP_ERROR_MSG*))
                  (autolisp-mark-end "EXPR" alfe--idx 1))
                (progn
                  (autolisp-log-out (strcat "RESULT " (autolisp-stdout-text alfe--r)))
                  (autolisp-mark-end "EXPR" alfe--idx 0)
                  (setq alfe--ok T)))))))))))
  alfe--ok)

(defun autolisp-run-main (alfe--idx alfe--main-name / alfe--sym-read alfe--r alfe--olderr)
  (autolisp-mark-begin "MAIN" alfe--idx)
  (autolisp-log-out (strcat "MAIN " alfe--main-name))
  (setq *AUTOLISP_ERROR_MSG* nil)
  (setq alfe--olderr *error*)
  (setq *error* autolisp-trap-error)
  (setq alfe--sym-read (read alfe--main-name))
  (setq *error* alfe--olderr)
  (if *AUTOLISP_QUIT_REQUESTED*
    (autolisp-raise *AUTOLISP_QUIT_SIGNAL*)
    (if (autolisp-quit-signal-p *AUTOLISP_ERROR_MSG*)
      (autolisp-raise *AUTOLISP_QUIT_SIGNAL*)
    (if *AUTOLISP_ERROR_MSG*
      (progn
        (autolisp-log-err (strcat "ERROR read-main " alfe--main-name ": " *AUTOLISP_ERROR_MSG*))
        (autolisp-mark-end "MAIN" alfe--idx 1)
        nil)
      (progn
        (setq *AUTOLISP_CAPTURE_STDOUT* T)
        (setq *AUTOLISP_ERROR_MSG* nil)
        (setq alfe--olderr *error*)
        (setq *error* autolisp-trap-error)
        (setq alfe--r (funcall alfe--sym-read))
        (setq *error* alfe--olderr)
        (setq *AUTOLISP_CAPTURE_STDOUT* nil)
        (if *AUTOLISP_QUIT_REQUESTED*
          (autolisp-raise *AUTOLISP_QUIT_SIGNAL*)
          (if (autolisp-quit-signal-p *AUTOLISP_ERROR_MSG*)
            (autolisp-raise *AUTOLISP_QUIT_SIGNAL*)
          (if *AUTOLISP_ERROR_MSG*
            (progn
              (autolisp-log-err (strcat "ERROR main " alfe--main-name ": " *AUTOLISP_ERROR_MSG*))
              (autolisp-mark-end "MAIN" alfe--idx 1)
              nil)
            (progn
              (autolisp-log-out (strcat "MAIN-RESULT " (autolisp-stdout-text alfe--r)))
              (autolisp-mark-end "MAIN" alfe--idx 0)
              T)))))))))

(defun autolisp-host-quit ()
  (command "_QUIT" "_Y"))

(setq *AUTOLISP_QUIT_SIGNAL* "__AUTOLISP_QUIT_SIGNAL__")
(setq *AUTOLISP_QUIT_REQUESTED* nil)
(setq *AUTOLISP_LOAD_STACK* nil)
(setq *AUTOLISP_LAST_ERROR_CONTEXT* nil)
(setq *CLLOAD_DEFAULT_LOADER* 'autolisp-source-load)

(defun autolisp-quit-signal-p (alfe--msg)
  (and (= (type alfe--msg) 'STR)
       (= alfe--msg *AUTOLISP_QUIT_SIGNAL*)))

(defun quit ()
  (setq *AUTOLISP_QUIT_REQUESTED* T)
  (autolisp-raise *AUTOLISP_QUIT_SIGNAL*))

(defun exit ()
  (quit))

(setq *AUTOLISP_TOTAL* 0)
(setq *AUTOLISP_OK* 0)
(setq *AUTOLISP_FAIL* 0)
(setq *AUTOLISP_ERROR* 0)
(setq *AUTOLISP_CAPTURE_STDOUT* nil)
(setq *AUTOLISP_ERROR_MSG* nil)
(setq *load-verbose* nil)

(defun autolisp-note-ok ()
  (setq *AUTOLISP_TOTAL* (+ *AUTOLISP_TOTAL* 1))
  (setq *AUTOLISP_OK* (+ *AUTOLISP_OK* 1)))

(defun autolisp-note-fail ()
  (setq *AUTOLISP_TOTAL* (+ *AUTOLISP_TOTAL* 1))
  (setq *AUTOLISP_FAIL* (+ *AUTOLISP_FAIL* 1)))

(defun autolisp-summary-line ()
  (strcat "TOTAL=" (itoa *AUTOLISP_TOTAL*)
          " OK=" (itoa *AUTOLISP_OK*)
          " FAIL=" (itoa *AUTOLISP_FAIL*)
          " ERROR=" (itoa *AUTOLISP_ERROR*)))

(autolisp-reset-file *AUTOLISP_OUTFILE*)
(autolisp-reset-file *AUTOLISP_ERRFILE*)
(autolisp-set-status 99)
(setq *AUTOLISP_LOG_STATE* nil)
(defun autolisp-safe-getvar (alfe--name / alfe--r)
  (setq alfe--r (vl-catch-all-apply 'getvar (list alfe--name)))
  (if (vl-catch-all-error-p alfe--r) nil alfe--r))

;; Actually safe: some sysvars are read-only on some hosts (LOGFILENAME is
;; read-only on both AutoCAD and BricsCAD -- only LOGFILEPATH is settable),
;; and a bare (setvar) on such a var SIGNALS, which previously aborted the
;; whole log-setup mid-way and surfaced as an error. Swallow the rejection
;; and return T only when the set took.
(defun autolisp-safe-setvar (alfe--name alfe--value / alfe--r)
  (setq alfe--r (vl-catch-all-apply 'setvar (list alfe--name alfe--value)))
  (not (vl-catch-all-error-p alfe--r)))

(defun autolisp-log-setup (/ alfe--old-mode alfe--old-path)
  ;; Direct the session log into our workdir via LOGFILEPATH -- the one
  ;; log sysvar that is writable on the real CAD hosts. LOGFILENAME is
  ;; read-only there, so we do NOT try to set it (the host keeps its
  ;; default log name in our directory, which is all we need). Every set
  ;; goes through autolisp-safe-setvar, so a host that also locks
  ;; LOGFILEPATH/LOGFILEMODE degrades quietly instead of erroring.
  (setq alfe--old-mode (autolisp-safe-getvar "LOGFILEMODE"))
  (setq alfe--old-path (autolisp-safe-getvar "LOGFILEPATH"))
  (autolisp-safe-setvar "LOGFILEPATH" *AUTOLISP_LOGDIR*)
  (autolisp-safe-setvar "LOGFILEMODE" 1)
  (list alfe--old-mode alfe--old-path))

(defun autolisp-log-restore (alfe--state / alfe--old-mode alfe--old-path)
  (if alfe--state
    (progn
      (setq alfe--old-mode (nth 0 alfe--state))
      (setq alfe--old-path (nth 1 alfe--state))
      (if alfe--old-path (autolisp-safe-setvar "LOGFILEPATH" alfe--old-path))
      (if alfe--old-mode (autolisp-safe-setvar "LOGFILEMODE" alfe--old-mode)))))

(setq _autolisp_log_setup_result (vl-catch-all-apply 'autolisp-log-setup nil))
(if (vl-catch-all-error-p _autolisp_log_setup_result)
  (progn
    (setq *AUTOLISP_LOG_STATE* nil)
    (autolisp-log-err
      (strcat "WARN log-setup: "
              (vl-catch-all-error-message _autolisp_log_setup_result))))
  (setq *AUTOLISP_LOG_STATE* _autolisp_log_setup_result))
;; Write TEXT verbatim to an already-open file descriptor FILE, one
;; character at a time. write-char is NOT shadowed by the bootstrap, so
;; this reaches the genuine file. Used by the file-bound branch of the
;; print/princ/prin1 shadows below: when the user passes a descriptor
;; opened with (open path "w"|"a"), the output must land in that file,
;; not in the captured-stdout / protocol slot. Going through
;; (ascii (substr ...)) avoids needing the original (now-shadowed)
;; printer to reach the file. Keep ASCII-only (see the note in
;; autolisp-source-load-run-body-impl): every byte > 127 has tripped a
;; BricsCAD / clautolisp LOAD failure.
(defun autolisp-write-string-to-file (alfe--text alfe--file / alfe--idx alfe--len)
  (setq alfe--idx 1)
  (setq alfe--len (strlen alfe--text))
  (while (<= alfe--idx alfe--len)
    (write-char (ascii (substr alfe--text alfe--idx 1)) alfe--file)
    (setq alfe--idx (+ alfe--idx 1)))
  nil)

;; Mirror interactive output to OUTFILE so results do not depend on CAD
;; session logs. All three honour AutoLISP's optional file-descriptor
;; argument: (princ obj f) / (print obj f) / (prin1 obj f) write to the
;; open file F instead of the captured-stdout slot -- otherwise output
;; destined for a user-opened file leaks onto stdout. See
;; issues/closed/alfe-bricscad-open.issue. FILE is nil for the common
;; no-descriptor call, which keeps the previous protocol behaviour.
(defun print (alfe--obj alfe--file)
  (if alfe--file
    (progn
      (autolisp-write-string-to-file
        (strcat "\n" (autolisp-stdout-text alfe--obj) " ") alfe--file)
      alfe--obj)
    (progn
      (autolisp-princ-newline)
      (autolisp-emit-user-out alfe--obj))))

(defun princ (alfe--obj alfe--file)
  (if alfe--file
    (progn
      (autolisp-write-string-to-file (autolisp-str alfe--obj) alfe--file)
      alfe--obj)
    (progn
      (autolisp-emit-user-line (autolisp-str alfe--obj))
      alfe--obj)))

(defun prin1 (alfe--obj alfe--file)
  (if alfe--file
    (progn
      (autolisp-write-string-to-file (autolisp-stdout-text alfe--obj) alfe--file)
      alfe--obj)
    (autolisp-emit-user-out alfe--obj)))

(defun autolisp-princ-newline ()
  (if *AUTOLISP_CAPTURE_STDOUT*
    (autolisp-emit-user-line "")
    (terpri))
  nil)

(defun prompt (alfe--msg)
  (if alfe--msg
    (progn
      (autolisp-emit-user-line (autolisp-str alfe--msg))
      alfe--msg)
    alfe--msg))

(defun autolisp-slurp-lines (alfe--path / alfe--f alfe--line alfe--acc)
  (setq alfe--f (open alfe--path "r"))
  (if (not alfe--f)
    nil
    (progn
      (setq alfe--acc '())
      (while (setq alfe--line (read-line alfe--f))
        (setq alfe--line (vl-string-translate "\r" "" alfe--line))
        (setq alfe--acc (cons alfe--line alfe--acc)))
      (close alfe--f)
      (reverse alfe--acc))))

(defun autolisp-lines->text (alfe--lines / alfe--acc)
  (setq alfe--acc "")
  (while alfe--lines
    (if (= alfe--acc "")
      (setq alfe--acc (car alfe--lines))
      (setq alfe--acc (strcat alfe--acc "\n" (car alfe--lines))))
    (setq alfe--lines (cdr alfe--lines)))
  alfe--acc)

;; Probe whether a function NAME (a string) is actually bound on this host.
;; vl-catch-all-apply CANNOT trap the error raised when a symbol has no
;; function definition at all: that error is signalled while resolving the
;; symbol to an applicable subr, before the guard is established, so it
;; escapes the guard (this is why calling an undefined vlax-sleep through
;; vl-catch-all-apply let "fonction incorrecte: VLAX-SLEEP" propagate on
;; AutoCAD's accoreconsole). atoms-family probes the symbol table directly:
;; given a symlist it returns the supplied names that exist, nil in the slot
;; for those that do not.
(defun autolisp-host-has-fn (alfe--name / alfe--hit)
  (setq alfe--hit (atoms-family 1 (list (strcase alfe--name))))
  (if (and alfe--hit (car alfe--hit)) T nil))

;; Real-time yield of about MS milliseconds using ONLY (getvar "DATE") -- a
;; monotonic-enough wall clock every AutoCAD/BricsCAD provides, read without
;; any command context, that never signals. DATE is the Julian day number
;; plus fraction-of-day, so one day = 86400000 ms.
;;
;; We deliberately do NOT use (command "_DELAY" ms) here: on AutoCAD's
;; accoreconsole that raises "fonction d'ordre incorrecte: COMMAND", and --
;; like an undefined vlax-sleep -- that error is signalled while resolving
;; `command' for the call, BEFORE any vl-catch-all-apply guard is
;; established, so it escapes the guard and aborts the protocol read loop.
;; A clock spin costs CPU but is correct and portable; hosts with a real
;; sleep (vlax-sleep on BricsCAD) never reach this helper.
(defun autolisp-busy-wait-ms (alfe--ms / alfe--target)
  (setq alfe--target (+ (getvar "DATE") (/ (float alfe--ms) 86400000.0)))
  (while (< (getvar "DATE") alfe--target)
    (setq alfe--target alfe--target)))

(defun autolisp-delay-ms (alfe--ms)
  (autolisp-busy-wait-ms alfe--ms)
  nil)

(defun autolisp-sleep-ms (alfe--ms / alfe--r)
  (if (autolisp-host-has-fn "VLAX-SLEEP")
    (progn
      (setq alfe--r (vl-catch-all-apply 'vlax-sleep (list alfe--ms)))
      (if (vl-catch-all-error-p alfe--r)
        (autolisp-delay-ms alfe--ms)))
    (autolisp-delay-ms alfe--ms))
  nil)

(defun autolisp-repl-reset-counters ()
  (setq *AUTOLISP_TOTAL* 0)
  (setq *AUTOLISP_OK* 0)
  (setq *AUTOLISP_FAIL* 0)
  (setq *AUTOLISP_ERROR* 0))

(defun autolisp-request-reset ()
  (autolisp-reset-file *AUTOLISP_OUTFILE*)
  (autolisp-reset-file *AUTOLISP_ERRFILE*)
  (autolisp-repl-reset-counters)
  (setq *AUTOLISP_CAPTURE_STDOUT* nil)
  (setq *AUTOLISP_ERROR_MSG* nil)
  (setq *AUTOLISP_QUIT_REQUESTED* nil)
  (autolisp-clear-last-error-context)
  nil)

(defun autolisp-request-exit-code ()
  (autolisp-log-out (autolisp-summary-line))
  (if (> *AUTOLISP_FAIL* 0)
    1
    0))

(defun autolisp-run-repl-request (/ alfe--lines alfe--req-id alfe--form-text alfe--f alfe--form-read alfe--r)
  (setq alfe--lines (autolisp-slurp-lines *AUTOLISP_INPFILE*))
  (if (null alfe--lines)
    nil
    (progn
      (setq alfe--req-id "0")
      (if (and alfe--lines (wcmatch (car alfe--lines) ";REQ *"))
        (setq alfe--req-id (substr (car alfe--lines) 6)))
      (setq alfe--form-text (autolisp-lines->text (cdr alfe--lines)))
      (autolisp-reset-file *AUTOLISP_OUTFILE*)
      (autolisp-reset-file *AUTOLISP_ERRFILE*)
      (autolisp-repl-reset-counters)
      (if (= alfe--form-text "")
        (progn
          (autolisp-log-err "ERROR read repl request: empty input")
          (autolisp-note-fail)
          (autolisp-log-out (autolisp-summary-line))
          (autolisp-set-status-text (strcat "READY " alfe--req-id))
          T)
        (progn
          (setq alfe--form-read (vl-catch-all-apply 'read (list alfe--form-text)))
          (vl-file-delete *AUTOLISP_INPFILE*)
          (if (vl-catch-all-error-p alfe--form-read)
            (progn
              (autolisp-log-err (strcat "ERROR read repl request: " (vl-catch-all-error-message alfe--form-read)))
              (autolisp-note-fail)
              (autolisp-log-out (autolisp-summary-line))
              (autolisp-set-status-text (strcat "READY " alfe--req-id))
              T)
            (if (equal alfe--form-read '__AUTOLISP_QUIT__)
              (progn
                (autolisp-set-status-text (strcat "STOP " alfe--req-id))
                nil)
              (progn
                (autolisp-log-out (strcat "EVAL " alfe--form-text))
                (setq *AUTOLISP_CAPTURE_STDOUT* T)
                (setq alfe--r (vl-catch-all-apply 'autolisp-eval-request-source
                                                  (list alfe--form-read
                                                        (autolisp-first-form-text alfe--form-text))))
                (setq *AUTOLISP_CAPTURE_STDOUT* nil)
                (if (vl-catch-all-error-p alfe--r)
                  (progn
                    (autolisp-log-err (strcat "ERROR eval " alfe--form-text ": " (vl-catch-all-error-message alfe--r)))
                    (autolisp-note-fail))
                  (progn
                    (autolisp-log-out (strcat "RESULT " (autolisp-stdout-text alfe--r)))
                    (autolisp-note-ok)))
                (autolisp-log-out (autolisp-summary-line))
                (autolisp-set-status-text (strcat "READY " alfe--req-id))
                T))))))))

(defun autolisp-repl-loop (/ alfe--keep-going)
  (autolisp-set-status-text "READY 0")
  (setq alfe--keep-going T)
  (while alfe--keep-going
    (while (not (findfile *AUTOLISP_INPFILE*))
      (autolisp-sleep-ms 100))
    (if (not (autolisp-run-repl-request))
      (setq alfe--keep-going nil)))
  ;; BricsCAD macOS batch quit can crash inside its own _QUIT handler.
  ;; Let the wrapper stop the launched process instead.
  (if *AUTOLISP_QUIT_ON_FINISH*
    (command "_QUIT" "_Y")))
(autolisp-write-runtime-info)
