(defun autolisp-bootstrap-append-line (path text / f)
  (if (and (= (type path) 'STR)
           (/= path ""))
    (progn
      (setq f (open path "a"))
      (if f
        (progn
          (write-line text f)
          (close f))))))

(defun autolisp-bootstrap-write-line (path text / f)
  (if (and (= (type path) 'STR)
           (/= path ""))
    (progn
      (setq f (open path "w"))
      (if f
        (progn
          (write-line text f)
          (close f))))))

(defun autolisp-bootstrap-render-error (err / msg)
  (cond
    ((and (= (type err) 'STR)
          (/= err ""))
     err)
    ((and (fboundp 'vl-catch-all-error-message)
          (not (vl-catch-all-error-p
                 (setq msg (vl-catch-all-apply 'vl-catch-all-error-message
                                               (list err))))))
     msg)
    (T
     "<bootstrap failure>")))

(defun autolisp-bootstrap-mark-fatal (phase err / msg)
  (setq msg (autolisp-bootstrap-render-error err))
  (autolisp-bootstrap-append-line *AUTOLISP_ERRFILE*
                                  (strcat "ERROR " phase ": " msg))
  (autolisp-bootstrap-write-line *AUTOLISP_STATUSFILE* "1")
  (autolisp-bootstrap-write-line *AUTOLISP_PROTOCOL_STATUSFILE*
                                 (strcat "FAILED " phase))
  (if *AUTOLISP_QUIT_ON_FINISH*
    (vl-catch-all-apply 'command (list "_QUIT" "_Y")))
  1)

(defun autolisp-write-line (path text / f)
  (setq f (open path "a"))
  (if f
    (progn
      (write-line text f)
      (close f))))

(defun autolisp-reset-file (path / f)
  (setq f (open path "w"))
  (if f (close f)))

(defun autolisp-slurp-file (path / f line acc)
  (setq f (open path "r"))
  (if (not f)
    ""
    (progn
      (setq acc "")
      (while (setq line (read-line f))
        (setq line (vl-string-translate "\r" "" line))
        (if (= acc "")
          (setq acc line)
          (setq acc (strcat acc "\n" line))))
      (close f)
      acc)))

(defun autolisp-str (obj)
  (if (= (type obj) 'STR)
    obj
    (autolisp-render obj)))

(defun autolisp-render (obj / rendered)
  (setq rendered (vl-catch-all-apply 'vl-princ-to-string (list obj)))
  (if (vl-catch-all-error-p rendered)
    "<unprintable>"
    rendered))

(defun autolisp-set-status (code / f)
  (setq f (open *AUTOLISP_STATUSFILE* "w"))
  (if f
    (progn
      (write-line (itoa code) f)
      (close f)))
  code)

(defun autolisp-set-status-text (text / f)
  (setq f (open *AUTOLISP_STATUSFILE* "w"))
  (if f
    (progn
      (write-line text f)
      (close f)))
  text)

(defun autolisp-log-out (text)
  (autolisp-write-line *AUTOLISP_OUTFILE* text))

(defun autolisp-log-err (text)
  (autolisp-write-line *AUTOLISP_ERRFILE* text))

(defun autolisp-safe-getvar (name / value)
  (setq value (vl-catch-all-apply 'getvar (list name)))
  (if (vl-catch-all-error-p value)
    ""
    (autolisp-str value)))

(defun autolisp-write-runtime-info (/ f)
  (setq f (open *AUTOLISP_PROTOCOL_INFOFILE* "w"))
  (if f
    (progn
      (write-line (autolisp-safe-getvar "PRODUCT") f)
      (write-line (autolisp-safe-getvar "ACADVER") f)
      (write-line (autolisp-safe-getvar "PROGRAM") f)
      (close f)))
  nil)

(defun autolisp-stdout-prefix ()
  "<<<AUTOLISP-STDOUT>>>")

(defun autolisp-escape-string (text / idx len ch acc)
  (setq idx 1)
  (setq len (strlen text))
  (setq acc "")
  (while (<= idx len)
    (setq ch (substr text idx 1))
    (if (= ch "\\")
      (setq acc (strcat acc "\\\\"))
      (if (= ch "\"")
        (setq acc (strcat acc "\\\""))
        (setq acc (strcat acc ch))))
    (setq idx (+ idx 1)))
  acc)

(defun autolisp-readable-text (obj / acc first tail)
  (cond
    ((null obj)
     "nil")
    ((= (type obj) 'STR)
     (strcat "\"" (autolisp-escape-string obj) "\""))
    ((listp obj)
     (setq acc "(")
     (setq first T)
     (setq tail obj)
     (while tail
       (if first
         (setq first nil)
         (setq acc (strcat acc " ")))
       (setq acc (strcat acc (autolisp-readable-text (car tail))))
       (setq tail (cdr tail)))
     (strcat acc ")"))
    (T
     (autolisp-render obj))))

(defun autolisp-stdout-text (obj)
  (autolisp-readable-text obj))

(defun autolisp-emit-user-out (obj)
  (if *AUTOLISP_CAPTURE_STDOUT*
    (autolisp-write-line *AUTOLISP_OUTFILE*
                         (strcat (autolisp-stdout-prefix)
                                 (autolisp-stdout-text obj))))
  obj)

(defun autolisp-emit-user-line (text)
  (if *AUTOLISP_CAPTURE_STDOUT*
    (autolisp-write-line *AUTOLISP_OUTFILE*
                         (strcat (autolisp-stdout-prefix) text))
    text)
  text)

;; Fallback for BricsCAD builds where the project-specific LispFunction is not
;; loaded yet. The real EPURELIB.dll definition can still replace this later.
(defun get_new_guid (/ stamp)
  (if (not (boundp '*AUTOLISP_GUID_SEQ*))
    (setq *AUTOLISP_GUID_SEQ* 0))
  (setq *AUTOLISP_GUID_SEQ* (+ *AUTOLISP_GUID_SEQ* 1))
  (setq stamp (rtos (getvar "DATE") 2 8))
  (strcat "AUTO-" stamp "-" (itoa *AUTOLISP_GUID_SEQ*)))

(defun autolisp-mark-begin (kind idx)
  nil)

(defun autolisp-mark-end (kind idx rc)
  nil)

(defun autolisp-finish (code)
  (if *AUTOLISP_LOG_STATE*
    (autolisp-log-restore *AUTOLISP_LOG_STATE*))
  (if _autolisp_old_srchpath
    (setvar "SRCHPATH" _autolisp_old_srchpath))
  (autolisp-set-status code)
  (if *AUTOLISP_QUIT_ON_FINISH*
    (autolisp-host-quit))
  code)

(defun autolisp-source-scan-text (text / idx len depth in-string escape in-comment ch line col open-stack started top)
  (setq *AUTOLISP_SOURCE_SCAN_STATE* 'empty)
  (setq *AUTOLISP_SOURCE_SCAN_LINE* 1)
  (setq *AUTOLISP_SOURCE_SCAN_COL* 1)
  (setq idx 1)
  (setq len (strlen text))
  (setq depth 0)
  (setq in-string nil)
  (setq escape nil)
  (setq in-comment nil)
  (setq line 1)
  (setq col 0)
  (setq open-stack nil)
  (setq started nil)
  (while (and (<= idx len)
              (/= *AUTOLISP_SOURCE_SCAN_STATE* 'extra))
    (setq ch (substr text idx 1))
    (cond
      ((= ch "\n")
       (setq line (+ line 1))
       (setq col 0)
       (setq in-comment nil))
      (T
       (setq col (+ col 1))
       (cond
         (in-comment
          nil)
         (in-string
          (cond
            (escape
             (setq escape nil))
            ((= ch "\\")
             (setq escape T))
            ((= ch "\"")
             (setq in-string nil))))
         ((= ch ";")
          (setq in-comment T))
         ((member ch '(" " "\t" "\r"))
          nil)
         (T
          (setq started T)
          (cond
            ((= ch "\"")
             (setq in-string T))
            ((= ch "(")
             (setq depth (+ depth 1))
             (setq open-stack (cons (list line col) open-stack)))
            ((= ch ")")
             (if (> depth 0)
               (progn
                 (setq depth (- depth 1))
                 (setq open-stack (cdr open-stack)))
               (progn
                 (setq *AUTOLISP_SOURCE_SCAN_STATE* 'extra)
                 (setq *AUTOLISP_SOURCE_SCAN_LINE* line)
                 (setq *AUTOLISP_SOURCE_SCAN_COL* col)))))))))
    (setq idx (+ idx 1)))
  (if (/= *AUTOLISP_SOURCE_SCAN_STATE* 'extra)
    (cond
      ((not started)
       (setq *AUTOLISP_SOURCE_SCAN_STATE* 'empty))
      (in-string
       (setq *AUTOLISP_SOURCE_SCAN_STATE* 'incomplete-string)
       (setq *AUTOLISP_SOURCE_SCAN_LINE* line)
       (setq *AUTOLISP_SOURCE_SCAN_COL* (max 1 col)))
      (open-stack
       (setq top (car open-stack))
       (setq *AUTOLISP_SOURCE_SCAN_STATE* 'incomplete)
       (setq *AUTOLISP_SOURCE_SCAN_LINE* (car top))
       (setq *AUTOLISP_SOURCE_SCAN_COL* (cadr top)))
      (T
       (setq *AUTOLISP_SOURCE_SCAN_STATE* 'complete)
       (setq *AUTOLISP_SOURCE_SCAN_LINE* line)
       (setq *AUTOLISP_SOURCE_SCAN_COL* (max 1 col)))))
  *AUTOLISP_SOURCE_SCAN_STATE*)

(defun autolisp-source-leading-symbols (text count / idx len ch in-comment token start tokens)
  (setq idx 1)
  (setq len (strlen text))
  (setq in-comment nil)
  (setq tokens '())
  (while (and (<= idx len)
              (< (length tokens) count))
    (setq ch (substr text idx 1))
    (cond
      (in-comment
       (if (= ch "\n")
         (setq in-comment nil))
       (setq idx (+ idx 1)))
      ((= ch ";")
       (setq in-comment T)
       (setq idx (+ idx 1)))
      ((member ch '(" " "\t" "\r" "\n" "(" ")"))
       (setq idx (+ idx 1)))
      (T
       (setq start idx)
       (while (and (<= idx len)
                   (not (member (substr text idx 1)
                                '(" " "\t" "\r" "\n" "(" ")" "\"" ";"))))
         (setq idx (+ idx 1)))
       (setq token (substr text start (- idx start)))
       (setq tokens (append tokens (list token))))))
  tokens)

(defun autolisp-source-leading-defun-name (text / tokens)
  (setq tokens (autolisp-source-leading-symbols text 2))
  (if (and (= (length tokens) 2)
           (= (strcase (car tokens)) "DEFUN"))
    (cadr tokens)
    nil))

(defun autolisp-source-trim-leading-junk (text / idx len ch in-comment done)
  ;; READ on BricsCAD can return NIL when the input string starts with
  ;; comment-only lines. Strip leading spaces/comments before READ so the
  ;; first real top-level form is what gets parsed.
  (setq idx 1)
  (setq len (strlen text))
  (setq in-comment nil)
  (setq done nil)
  (while (and (<= idx len) (not done))
    (setq ch (substr text idx 1))
    (cond
      (in-comment
       (if (= ch "\n")
         (setq in-comment nil))
       (setq idx (+ idx 1)))
      ((= ch ";")
       (setq in-comment T)
       (setq idx (+ idx 1)))
      ((member ch '(" " "\t" "\r" "\n"))
       (setq idx (+ idx 1)))
      (T
       (setq done T))))
  (if (> idx len)
    ""
    (substr text idx)))

(defun autolisp-source-stack-text (/ paths acc)
  (setq paths (reverse *AUTOLISP_LOAD_STACK*))
  (setq acc "")
  (while paths
    (if (= acc "")
      (setq acc (car paths))
      (setq acc (strcat acc " -> " (car paths))))
    (setq paths (cdr paths)))
  acc)

(defun autolisp-source-format-error (path detail line col form-start defun-name / msg stack)
  (setq msg (strcat "while loading " path))
  (if form-start
    (setq msg (strcat msg " (form starting at line " (itoa form-start) ")")))
  (if line
    (setq msg (strcat msg " at line " (itoa line))))
  (if col
    (setq msg (strcat msg ", column " (itoa col))))
  (if (and defun-name (/= defun-name ""))
    (setq msg (strcat msg " in defun " defun-name)))
  (setq msg (strcat msg ": " detail))
  (setq stack (autolisp-source-stack-text))
  (if (and stack (/= stack "") (> (length *AUTOLISP_LOAD_STACK*) 1))
    (setq msg (strcat msg " [load stack: " stack "]")))
  msg)

(defun autolisp-effective-error-message (fallback)
  (if (and (boundp '*AUTOLISP_LAST_ERROR_CONTEXT*)
           *AUTOLISP_LAST_ERROR_CONTEXT*
           (/= *AUTOLISP_LAST_ERROR_CONTEXT* ""))
    *AUTOLISP_LAST_ERROR_CONTEXT*
    fallback))

(defun autolisp-clear-last-error-context ()
  (setq *AUTOLISP_LAST_ERROR_CONTEXT* nil))

(defun autolisp-source-pop-stack ()
  (if *AUTOLISP_LOAD_STACK*
    (setq *AUTOLISP_LOAD_STACK* (cdr *AUTOLISP_LOAD_STACK*)))
  nil)

(defun autolisp-source-raise (path detail line col form-start defun-name / msg)
  (setq msg (autolisp-source-format-error path detail line col form-start defun-name))
  (setq *AUTOLISP_LAST_ERROR_CONTEXT* msg)
  (autolisp-source-pop-stack)
  (error msg))

(defun autolisp-source-load-failure (onfailure)
  (if (= (type onfailure) 'SYM)
    (eval onfailure)
    onfailure))

(defun autolisp-source-resolve-load-path (path / found home)
  (setq found (findfile path))
  (if (not found)
    (setq found (findfile (strcat path ".lsp"))))
  (if (not found)
    (if (and (> (strlen path) 1)
             (= (substr path 1 2) "~/"))
      (progn
        (setq home (getenv "HOME"))
        (if home
          (progn
            (setq found (findfile (strcat home (substr path 2))))
            (if (not found)
              (setq found (findfile (strcat home (substr path 2) ".lsp")))))))))
  found)

(defun autolisp-source-load-core-impl (path has-onfailure onfailure / resolved f line line-no form-text form-start-line result form-read defun-name eval-result capture-old)
  (setq resolved (autolisp-source-resolve-load-path path))
  (if (not resolved)
    (if has-onfailure
      (autolisp-source-load-failure onfailure)
      (error (strcat "LOAD failed: \"" path "\"")))
    (progn
      (setq *AUTOLISP_LOAD_STACK* (cons resolved *AUTOLISP_LOAD_STACK*))
      (setq f (open resolved "r"))
      (if (not f)
        (autolisp-source-raise resolved "unable to open source file" nil nil nil nil))
      (setq line-no 0)
      (setq form-text "")
      (setq form-start-line nil)
      (setq result nil)
      (while (setq line (read-line f))
        (setq line (vl-string-translate "\r" "" line))
        (setq line-no (+ line-no 1))
        (if (= form-text "")
          (setq form-start-line line-no))
        (if (= form-text "")
          (setq form-text line)
          (setq form-text (strcat form-text "\n" line)))
        (autolisp-source-scan-text form-text)
        (cond
          ((= *AUTOLISP_SOURCE_SCAN_STATE* 'extra)
           (close f)
           (autolisp-source-raise resolved
                                  "extra right parenthesis on input"
                                  *AUTOLISP_SOURCE_SCAN_LINE*
                                  *AUTOLISP_SOURCE_SCAN_COL*
                                  form-start-line
                                  (autolisp-source-leading-defun-name form-text)))
          ((= *AUTOLISP_SOURCE_SCAN_STATE* 'complete)
           (setq defun-name (autolisp-source-leading-defun-name form-text))
           (setq form-read
                 (vl-catch-all-apply 'read
                                     (list (autolisp-source-trim-leading-junk form-text))))
           (if (vl-catch-all-error-p form-read)
             (progn
               (close f)
               (autolisp-source-raise resolved
                                      (autolisp-effective-error-message
                                        (vl-catch-all-error-message form-read))
                                      line-no
                                      1
                                      form-start-line
                                      defun-name))
             (progn
               (if (and (boundp '*load-verbose*) *load-verbose*)
                 (autolisp-emit-user-line
                   (strcat "LOADFORM " (autolisp-str form-read))))
               (setq capture-old *AUTOLISP_CAPTURE_STDOUT*)
               (setq *AUTOLISP_CAPTURE_STDOUT* T)
               (setq eval-result (vl-catch-all-apply 'autolisp-eval-request-form (list form-read)))
               (setq *AUTOLISP_CAPTURE_STDOUT* capture-old)
               (if (vl-catch-all-error-p eval-result)
                 (if (or *AUTOLISP_QUIT_REQUESTED*
                         (autolisp-quit-signal-p
                           (vl-catch-all-error-message eval-result)))
                   (progn
                     (close f)
                     (autolisp-source-pop-stack)
                     (error *AUTOLISP_QUIT_SIGNAL*))
                   (progn
                     (close f)
                     (autolisp-source-raise resolved
                                            (autolisp-effective-error-message
                                              (vl-catch-all-error-message eval-result))
                                            form-start-line
                                            1
                                            form-start-line
                                            defun-name)))
                 (setq result eval-result))
               (setq form-text "")
               (setq form-start-line nil))))))
      (close f)
      (if (/= form-text "")
        (progn
          (autolisp-source-scan-text form-text)
          (autolisp-source-raise resolved
                                 (if (= *AUTOLISP_SOURCE_SCAN_STATE* 'incomplete-string)
                                   "unexpected end of file while reading string"
                                   "unexpected end of file while reading form")
                                 line-no
                                 1
                                 form-start-line
                                 (autolisp-source-leading-defun-name form-text))))
      ;; The documented LOAD contract is to return the loaded filename on
      ;; success, not the last evaluated form.
      (setq result resolved)
      (autolisp-source-pop-stack)
      result)))

(defun autolisp-source-load (path /)
  (autolisp-source-load-core-impl path nil nil))

(defun autolisp-source-load-with-onfailure (path onfailure /)
  (autolisp-source-load-core-impl path T onfailure))

(defun autolisp-internal-protocol-load-p (path)
  (and (= (type path) 'STR)
       (wcmatch path "*protocol-request-*.lsp")))

(defun autolisp-load-form-p (form)
  (and (listp form)
       form
       (= (type (car form)) 'SYM)
       (= (strcase (vl-symbol-name (car form))) "LOAD")))

(defun autolisp-normalize-princ-call (form / head)
  (cond
    ((atom form)
     form)
    ((and (listp form) form)
     (setq head (car form))
     (cond
       ((and (= (type head) 'SYM)
             (= (strcase (vl-symbol-name head)) "QUOTE"))
        form)
       ((and (= (type head) 'SYM)
             (= (strcase (vl-symbol-name head)) "FUNCTION"))
        form)
       ((and (= (type head) 'SYM)
             (= (strcase (vl-symbol-name head)) "PRINC")
             (= (length form) 1))
        (list 'autolisp-princ-newline))
       (T
        (cons head (mapcar 'autolisp-normalize-princ-call (cdr form))))))
    (T
     form)))

(defun autolisp-eval-load-form (form)
  (cond
    ((and (= (length form) 2)
          (autolisp-internal-protocol-load-p (cadr form)))
     (eval form))
    ((= (length form) 2)
     (autolisp-source-load (cadr form)))
    ((and (= (length form) 3)
          (autolisp-internal-protocol-load-p (cadr form)))
     (eval form))
    ((= (length form) 3)
     (autolisp-source-load-with-onfailure (cadr form) (caddr form)))
    (T
     (eval form))))

(defun autolisp-eval-request-form (form)
  (setq form (autolisp-normalize-princ-call form))
  (if (autolisp-load-form-p form)
    (autolisp-eval-load-form form)
    (eval form)))

(defun autolisp-run-load (idx path / r olderr)
  (autolisp-mark-begin "LOAD" idx)
  (autolisp-log-out (strcat "LOAD " path))
  (setq *AUTOLISP_CAPTURE_STDOUT* T)
  (setq *AUTOLISP_ERROR_MSG* nil)
  (setq olderr *error*)
  (setq *error* autolisp-trap-error)
  (setq r (autolisp-source-load path))
  (setq *error* olderr)
  (setq *AUTOLISP_CAPTURE_STDOUT* nil)
  (if *AUTOLISP_QUIT_REQUESTED*
    (error *AUTOLISP_QUIT_SIGNAL*)
    (if (autolisp-quit-signal-p *AUTOLISP_ERROR_MSG*)
      (error *AUTOLISP_QUIT_SIGNAL*)
    (if *AUTOLISP_ERROR_MSG*
      (progn
        (autolisp-log-err
          (strcat "ERROR load " path ": "
                  (autolisp-effective-error-message *AUTOLISP_ERROR_MSG*)))
        (autolisp-clear-last-error-context)
        (autolisp-mark-end "LOAD" idx 1)
        nil)
      (progn
        (autolisp-log-out (strcat "LOADED " path))
        (autolisp-mark-end "LOAD" idx 0)
        T)))))

(defun autolisp-trap-error (msg)
  (setq *AUTOLISP_ERROR_MSG* (autolisp-effective-error-message msg))
  (if (autolisp-quit-signal-p msg)
    (setq *AUTOLISP_QUIT_REQUESTED* T))
  nil)

(defun autolisp-run-eval-file (idx path / form-text form-read r olderr ok)
  (autolisp-mark-begin "EXPR" idx)
  (setq ok nil)
  (setq form-text (autolisp-slurp-file path))
  (if (null form-text)
    (progn
      (autolisp-log-err (strcat "ERROR read-file " path ": unable to open expression file"))
      (autolisp-mark-end "EXPR" idx 1))
    (progn
      (autolisp-log-out (strcat "EVAL " form-text))
      (setq *AUTOLISP_ERROR_MSG* nil)
      (setq olderr *error*)
      (setq *error* autolisp-trap-error)
      (setq form-read (read form-text))
      (setq *error* olderr)
      (if *AUTOLISP_QUIT_REQUESTED*
        (error *AUTOLISP_QUIT_SIGNAL*)
        (if (autolisp-quit-signal-p *AUTOLISP_ERROR_MSG*)
          (error *AUTOLISP_QUIT_SIGNAL*)
        (if *AUTOLISP_ERROR_MSG*
          (progn
            (autolisp-log-err (strcat "ERROR read " form-text ": " *AUTOLISP_ERROR_MSG*))
            (autolisp-mark-end "EXPR" idx 1))
          (progn
            (setq *AUTOLISP_CAPTURE_STDOUT* T)
            (setq *AUTOLISP_ERROR_MSG* nil)
            (setq olderr *error*)
            (setq *error* autolisp-trap-error)
            (setq r (autolisp-eval-request-form form-read))
            (setq *error* olderr)
            (setq *AUTOLISP_CAPTURE_STDOUT* nil)
            (if *AUTOLISP_QUIT_REQUESTED*
              (error *AUTOLISP_QUIT_SIGNAL*)
              (if (autolisp-quit-signal-p *AUTOLISP_ERROR_MSG*)
                (error *AUTOLISP_QUIT_SIGNAL*)
              (if *AUTOLISP_ERROR_MSG*
                (progn
                  (autolisp-log-err (strcat "ERROR eval " form-text ": " *AUTOLISP_ERROR_MSG*))
                  (autolisp-mark-end "EXPR" idx 1))
                (progn
                  (autolisp-log-out (strcat "RESULT " (autolisp-stdout-text r)))
                  (autolisp-mark-end "EXPR" idx 0)
                  (setq ok T)))))))))))
  ok)

(defun autolisp-run-main (idx main-name / sym-read r olderr)
  (autolisp-mark-begin "MAIN" idx)
  (autolisp-log-out (strcat "MAIN " main-name))
  (setq *AUTOLISP_ERROR_MSG* nil)
  (setq olderr *error*)
  (setq *error* autolisp-trap-error)
  (setq sym-read (read main-name))
  (setq *error* olderr)
  (if *AUTOLISP_QUIT_REQUESTED*
    (error *AUTOLISP_QUIT_SIGNAL*)
    (if (autolisp-quit-signal-p *AUTOLISP_ERROR_MSG*)
      (error *AUTOLISP_QUIT_SIGNAL*)
    (if *AUTOLISP_ERROR_MSG*
      (progn
        (autolisp-log-err (strcat "ERROR read-main " main-name ": " *AUTOLISP_ERROR_MSG*))
        (autolisp-mark-end "MAIN" idx 1)
        nil)
      (progn
        (setq *AUTOLISP_CAPTURE_STDOUT* T)
        (setq *AUTOLISP_ERROR_MSG* nil)
        (setq olderr *error*)
        (setq *error* autolisp-trap-error)
        (setq r (funcall sym-read))
        (setq *error* olderr)
        (setq *AUTOLISP_CAPTURE_STDOUT* nil)
        (if *AUTOLISP_QUIT_REQUESTED*
          (error *AUTOLISP_QUIT_SIGNAL*)
          (if (autolisp-quit-signal-p *AUTOLISP_ERROR_MSG*)
            (error *AUTOLISP_QUIT_SIGNAL*)
          (if *AUTOLISP_ERROR_MSG*
            (progn
              (autolisp-log-err (strcat "ERROR main " main-name ": " *AUTOLISP_ERROR_MSG*))
              (autolisp-mark-end "MAIN" idx 1)
              nil)
            (progn
              (autolisp-log-out (strcat "MAIN-RESULT " (autolisp-stdout-text r)))
              (autolisp-mark-end "MAIN" idx 0)
              T)))))))))

(defun autolisp-host-quit ()
  (command "_QUIT" "_Y"))

(setq *AUTOLISP_QUIT_SIGNAL* "__AUTOLISP_QUIT_SIGNAL__")
(setq *AUTOLISP_QUIT_REQUESTED* nil)
(setq *AUTOLISP_LOAD_STACK* nil)
(setq *AUTOLISP_LAST_ERROR_CONTEXT* nil)
(setq *CLLOAD_DEFAULT_LOADER* 'autolisp-source-load)

(defun autolisp-quit-signal-p (msg)
  (and (= (type msg) 'STR)
       (= msg *AUTOLISP_QUIT_SIGNAL*)))

(defun quit ()
  (setq *AUTOLISP_QUIT_REQUESTED* T)
  (error *AUTOLISP_QUIT_SIGNAL*))

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
(defun autolisp-safe-getvar (name)
  (getvar name))

(defun autolisp-safe-setvar (name value)
  (setvar name value))

(defun autolisp-log-setup (/ old-mode old-path old-name)
  (setq old-mode (autolisp-safe-getvar "LOGFILEMODE"))
  (setq old-path (autolisp-safe-getvar "LOGFILEPATH"))
  (setq old-name (autolisp-safe-getvar "LOGFILENAME"))
  (autolisp-safe-setvar "LOGFILEPATH" *AUTOLISP_LOGDIR*)
  (if *AUTOLISP_LOGNAME*
    (autolisp-safe-setvar "LOGFILENAME" *AUTOLISP_LOGNAME*))
  (autolisp-safe-setvar "LOGFILEMODE" 1)
  (list old-mode old-path old-name))

(defun autolisp-log-restore (state / old-mode old-path old-name)
  (if state
    (progn
      (setq old-mode (nth 0 state))
      (setq old-path (nth 1 state))
      (setq old-name (nth 2 state))
      (if old-path (autolisp-safe-setvar "LOGFILEPATH" old-path))
      (if old-name (autolisp-safe-setvar "LOGFILENAME" old-name))
      (if old-mode (autolisp-safe-setvar "LOGFILEMODE" old-mode)))))

(setq _autolisp_log_setup_result (vl-catch-all-apply 'autolisp-log-setup nil))
(if (vl-catch-all-error-p _autolisp_log_setup_result)
  (progn
    (setq *AUTOLISP_LOG_STATE* nil)
    (autolisp-log-err
      (strcat "WARN log-setup: "
              (vl-catch-all-error-message _autolisp_log_setup_result))))
  (setq *AUTOLISP_LOG_STATE* _autolisp_log_setup_result))
;; Mirror interactive output to OUTFILE so results do not depend on CAD session logs.
(defun print (obj)
  (autolisp-princ-newline)
  (autolisp-emit-user-out obj))

(defun princ (obj)
  (autolisp-emit-user-line (autolisp-str obj))
  obj)

(defun prin1 (obj)
  (autolisp-emit-user-out obj))

(defun autolisp-princ-newline ()
  (if *AUTOLISP_CAPTURE_STDOUT*
    (autolisp-emit-user-line "")
    (terpri))
  nil)

(defun prompt (msg)
  (if msg
    (progn
      (autolisp-emit-user-line (autolisp-str msg))
      msg)
    msg))

(defun autolisp-slurp-lines (path / f line acc)
  (setq f (open path "r"))
  (if (not f)
    nil
    (progn
      (setq acc '())
      (while (setq line (read-line f))
        (setq line (vl-string-translate "\r" "" line))
        (setq acc (cons line acc)))
      (close f)
      (reverse acc))))

(defun autolisp-lines->text (lines / acc)
  (setq acc "")
  (while lines
    (if (= acc "")
      (setq acc (car lines))
      (setq acc (strcat acc "\n" (car lines))))
    (setq lines (cdr lines)))
  acc)

(defun autolisp-sleep-ms (ms / r)
  (setq r (vl-catch-all-apply 'vlax-sleep (list ms)))
  (if (vl-catch-all-error-p r)
    (vl-catch-all-apply 'command (list "_DELAY" ms)))
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

(defun autolisp-run-repl-request (/ lines req-id form-text f form-read r)
  (setq lines (autolisp-slurp-lines *AUTOLISP_INPFILE*))
  (if (null lines)
    nil
    (progn
      (setq req-id "0")
      (if (and lines (wcmatch (car lines) ";REQ *"))
        (setq req-id (substr (car lines) 6)))
      (setq form-text (autolisp-lines->text (cdr lines)))
      (autolisp-reset-file *AUTOLISP_OUTFILE*)
      (autolisp-reset-file *AUTOLISP_ERRFILE*)
      (autolisp-repl-reset-counters)
      (if (= form-text "")
        (progn
          (autolisp-log-err "ERROR read repl request: empty input")
          (autolisp-note-fail)
          (autolisp-log-out (autolisp-summary-line))
          (autolisp-set-status-text (strcat "READY " req-id))
          T)
        (progn
          (setq form-read (vl-catch-all-apply 'read (list form-text)))
          (vl-file-delete *AUTOLISP_INPFILE*)
          (if (vl-catch-all-error-p form-read)
            (progn
              (autolisp-log-err (strcat "ERROR read repl request: " (vl-catch-all-error-message form-read)))
              (autolisp-note-fail)
              (autolisp-log-out (autolisp-summary-line))
              (autolisp-set-status-text (strcat "READY " req-id))
              T)
            (if (equal form-read '__AUTOLISP_QUIT__)
              (progn
                (autolisp-set-status-text (strcat "STOP " req-id))
                nil)
              (progn
                (autolisp-log-out (strcat "EVAL " form-text))
                (setq *AUTOLISP_CAPTURE_STDOUT* T)
                (setq r (vl-catch-all-apply 'autolisp-eval-request-form (list form-read)))
                (setq *AUTOLISP_CAPTURE_STDOUT* nil)
                (if (vl-catch-all-error-p r)
                  (progn
                    (autolisp-log-err (strcat "ERROR eval " form-text ": " (vl-catch-all-error-message r)))
                    (autolisp-note-fail))
                  (progn
                    (autolisp-log-out (strcat "RESULT " (autolisp-stdout-text r)))
                    (autolisp-note-ok)))
                (autolisp-log-out (autolisp-summary-line))
                (autolisp-set-status-text (strcat "READY " req-id))
                T))))))))

(defun autolisp-repl-loop (/ keep-going)
  (autolisp-set-status-text "READY 0")
  (setq keep-going T)
  (while keep-going
    (while (not (findfile *AUTOLISP_INPFILE*))
      (autolisp-sleep-ms 100))
    (if (not (autolisp-run-repl-request))
      (setq keep-going nil)))
  ;; BricsCAD macOS batch quit can crash inside its own _QUIT handler.
  ;; Let the wrapper stop the launched process instead.
  (if *AUTOLISP_QUIT_ON_FINISH*
    (command "_QUIT" "_Y")))
(autolisp-write-runtime-info)
