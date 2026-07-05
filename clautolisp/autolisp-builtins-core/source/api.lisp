(in-package #:clautolisp.autolisp-builtins-core)

;; SB-POSIX is a contrib package: it does not exist until required.
;; BUILTIN-GETPID below reads `sb-posix:getpid`, so the package must
;; exist at compile time (the reader interns the symbol) — load it
;; here, before any later form references it, rather than relying on
;; some other system having required it incidentally first.
(eval-when (:compile-toplevel :load-toplevel :execute)
  #+sbcl (require :sb-posix))

(defparameter *core-builtin-names*
  '("TYPE" "NULL" "NOT" "ATOM" "VL-SYMBOLP" "VL-SYMBOL-NAME" "VL-SYMBOL-VALUE"
    "VL-BB-REF" "VL-BB-SET" "VL-PROPAGATE" "VL-DOC-REF" "VL-DOC-SET"
    "VL-DOC-EXPORT" "VL-DOC-IMPORT"
    "MAPCAR" "VL-EVERY" "VL-MEMBER-IF" "VL-MEMBER-IF-NOT" "VL-REMOVE-IF"
    "VL-REMOVE-IF-NOT" "VL-SOME"
    "+" "-" "*" "/" "1+" "1-" "MAX" "MIN" "REM" "GCD" "LCM" "~" "LOGAND"
    "LOGIOR" "LSH" "STRCAT" "STRLEN" "SUBSTR" "ASCII" "CHR" "ATOI" "ATOF"
    "READ" "LOAD" "AUTOLOAD" "OPEN" "CLOSE" "READ-LINE" "READ-CHAR" "WRITE-LINE" "WRITE-CHAR"
    "FINDFILE" "FINDTRUSTEDFILE" "VL-DIRECTORY-FILES" "VL-FILE-DIRECTORY-P"
    "VL-FILENAME-BASE" "VL-FILENAME-DIRECTORY" "VL-FILENAME-EXTENSION"
    "VL-FILE-DELETE" "VL-FILE-RENAME" "VL-FILE-SIZE" "VL-FILE-SYSTIME"
    "VL-FILE-COPY" "VL-FILENAME-MKTEMP" "VL-MKDIR"
    "PRIN1" "PRINC" "PRINT" "TERPRI" "PROMPT" "EXIT" "QUIT"
    "VL-PRIN1-TO-STRING" "VL-PRINC-TO-STRING"
    "VL-CATCH-ALL-APPLY" "VL-CATCH-ALL-ERROR-P" "VL-CATCH-ALL-ERROR-MESSAGE"
    "VL-EXIT-WITH-ERROR" "VL-EXIT-WITH-VALUE"
    "DEFUN-Q-LIST-REF" "DEFUN-Q-LIST-SET"
    "BOUNDP" "CAR" "CDR" "CONS" "LIST" "APPEND" "ASSOC" "LENGTH" "NTH"
    "REVERSE" "LAST" "MEMBER" "SUBST" "LISTP" "VL-CONSP" "VL-LIST*"
    "NUMBERP" "=" "/=" "<" "<=" ">" ">=" "ABS" "FIX" "FLOAT" "ZEROP"
    "MINUSP"
    ;; --- M2 (missing-functions.issue) ---
    "GETENV" "SETENV" "GETPID" "SLEEP" "GC" "STARTAPP"
    "VL-GETCURRENTDIR" "VL-SETCURRENTDIR" "VL-GETSTARTUPDIR"
    "VL-RMDIR" "FNSPLITL" "DOC_CLIPBOARD"
    "VER" "LISP$VERSION" "MEM" "ALLOC" "HELP"
    "TRANS" "TEXTBOX" "VLE_G_VECTOL"
    "GRAPHSCR" "TEXTSCR" "TEXTPAGE" "REDRAW" "SETVIEW"
    "TABLET" "MENUCMD" "MENUGROUP" "SHOWHTMLMODALWINDOW"
    "*PUSH-ERROR-USING-COMMAND*" "*PUSH-ERROR-USING-STACK*" "*POP-ERROR-MODE*"
    ;; --- M3a VLE-* list/predicate/number helpers ---
    "VLE-NTH0" "VLE-NTH1" "VLE-NTH2" "VLE-NTH3" "VLE-NTH4"
    "VLE-NTH5" "VLE-NTH6" "VLE-NTH7" "VLE-NTH8" "VLE-NTH9"
    "VLE-PUT-NTH" "VLE-SUBST-NTH" "VLE-REMOVE-NTH"
    "VLE-REMOVE-ALL" "VLE-REMOVE-FIRST" "VLE-REMOVE-LAST"
    "VLE-LIST-SPLIT" "VLE-SUBLIST"
    "VLE-LIST-DIFF" "VLE-LIST-INTERSECT" "VLE-LIST-SUBTRACT" "VLE-LIST-UNION"
    "VLE-CDRASSOC" "VLE-CADRASSOC" "VLE-SET-CDRASSOC" "VLE-LIST-MASSOC"
    "VLE-APPEND" "VLE-MEMBER" "VLE-SEARCH"
    "VLE-INTEGERP" "VLE-REALP" "VLE-NUMBERP" "VLE-STRINGP"
    "VLE-POINTP" "VLE-ENAMEP" "VLE-PICKSETP"
    "VLE-VARIANTP" "VLE-SAFEARRAYP" "VLE-VLAOBJECTP"
    "VLE-CEILING" "VLE-FLOOR" "VLE-ROUND" "VLE-ROUNDTO"
    "VLE-ATOI32" "VLE-ITOA32" "VLE-INT64TO32" "VLE-TAN"
    ;; --- M3b VLE-VECTOR-* math ---
    "VLE-VECTOR-GET" "VLE-VECTOR-ADD" "VLE-VECTOR-SUB"
    "VLE-VECTOR-NEGATE" "VLE-VECTOR-SCALE" "VLE-VECTOR-MIDPOINT"
    "VLE-VECTOR-NORMALISE" "VLE-VECTOR-DOTPRODUCT"
    "VLE-VECTOR-CROSSPRODUCT" "VLE-VECTOR-ANGLETO"
    "VLE-VECTOR-ANGLETOREF" "VLE-VECTOR-LENGTH"
    "VLE-VECTOR-LENGTH2D" "VLE-VECTOR-LENGTH2DXZ" "VLE-VECTOR-LENGTH2DYZ"
    "VLE-VECTOR-ISUNITLENGTH" "VLE-VECTOR-ISEQUAL"
    "VLE-VECTOR-ISZEROLENGTH" "VLE-VECTOR-ISPARALLEL"
    "VLE-VECTOR-ISCODIRECTIONAL" "VLE-VECTOR-ISPERPENDICULAR"
    "VLE-VECTOR-ISXAXIS" "VLE-VECTOR-ISYAXIS" "VLE-VECTOR-ISZAXIS"
    "VLE-VECTOR-GETPERPVECTOR" "VLE-VECTOR-GETUCS"
    "VLE-VECTOR-TO2D" "VLE-VECTOR-TO3D"
    "VLE-VECTOR-GETTOLERANCE" "VLE-VECTOR-SETTOLERANCE"
    ;; --- M3c VLE-* string/file/color/misc ---
    "VLE-STRING-REPLACE" "VLE-STRING-SPLIT"
    "VLE-FILE->LIST" "VLE-FILEP" "VLE-FILE-ENCODING"
    "VLE-ACI2RGB" "VLE-RGB2ACI"
    "VLE-STARTAPP" "VLE-PING-ALIVE"
    "VLE-OPTIMISER" "VLE-OPTIMIZER" "VLE-FASTCOM"
    ;; --- M3d VLE-* CAD / COM / UI stubs ---
    "VLE-ALERT" "VLE-COLLECTION->LIST" "VLE-COMPILE-SHAPE"
    "VLE-CURVE-GETPERIMETER" "VLE-DICTIONARY-LIST"
    "VLE-DICTOBJNAME" "VLE-DICTSEARCH"
    "VLE-DISPLAYPAUSE" "VLE-DISPLAYUPDATE" "VLE-EDITTEXTINPLACE"
    "VLE-ENABLESERVERBUSY" "VLE-ENAME-VALID"
    "VLE-END-TRANSACTION" "VLE-START-TRANSACTION"
    "VLE-ENTGET" "VLE-ENTGET-M" "VLE-ENTGET-MASSOC"
    "VLE-ENTMOD" "VLE-ENTMOD-M"
    "VLE-EXTENSIONS-ACTIVE" "VLE-GETGEOMEXTENTS"
    "VLE-HIDEPROMPTMENU" "VLE-SHOWPROMPTMENU"
    "VLE-IS-CURVE" "VLE-LICENSELEVEL"
    "VLE-LISPINSTALL" "VLE-LISPVERSION" "VLE-NTH<X>"
    "VLE-SAFEARRAY->LIST" "VLE-SELECTIONSET->LIST"
    "VLE-SUNID" "VLE-TABLE-LIST" "VLE-TABLE-LIST-ALL" "VLE-TBLSEARCH"
    ;; --- M4 VLISP-* IDE stubs ---
    "VLISP-COMPILE" "VLISP-EXPORT-SYMBOL" "VLISP-IMPORT-SYMBOL"
    "VLISP-IMPORT-EXSUBRS" "VLISP-OPTIMIZER"
    ;; --- M5 core/misc rest ---
    "VL-INIT" "VL-LOAD-COM" "VL-LOAD-REACTORS" "VL-LOAD-ALL"
    "VL-ENABLE-USER-CANCEL" "LAYOUTLIST" "ACDIMENABLEUPDATE" "VPORTS"
    "VL-REGISTRY-READ" "VL-REGISTRY-WRITE" "VL-REGISTRY-DELETE"
    "VL-REGISTRY-DESCENDENTS"
    "GETCFG" "SETCFG"
    "ADS" "INITDIA" "INSPECTOR" "DLG-SYSVARS" "EXPAND"
    "LISP$INSTALL" "LISP$ENABLEFASTCOM" "BPOLY"
    "BCAD$DISABLE-EXTENDED-ERROR" "BCAD$LICENSELEVELS"
    "VMON" "_VLAX-SAFEARRAY-MODE"
    "LISTALLPROPERTIES" "DUMPALLPROPERTIES"
    "ISPROPERTYREADONLY" "ISPROPERTYVALID"
    "GETPROPERTYVALUE" "SETPROPERTYVALUE"
    "VL-LIST-LOADED-LISP" "VL-LIST-LOADED-VLX" "VL-VLX-LOADED-P"
    "VL-UNLOAD-VLX" "VL-LIST-EXPORTED-FUNCTIONS"
    "VL-VBALOAD" "VL-VBARUN" "VL-CMDF"
    "VL-ACAD-DEFUN" "VL-ACAD-UNDEFUN" "VL-GET-RESOURCE"
    "VL-GETGEOMEXTENTS" "VL-HIDEPROMPTMENU" "VL-SHOWPROMPTMENU"
    "VL-LOCAL-UNDO-CLEAR" "VL-LOCAL-UNDO-POP" "VL-LOCAL-UNDO-PUSH"
    "VL-LOCAL-UNDO-RESET" "VL-LOCAL-UNDO-STEPS"
    "VL-ANNOTATIVE-ADDSCALE" "VL-ANNOTATIVE-GET"
    "VL-ANNOTATIVE-GETSCALES" "VL-ANNOTATIVE-REMOVE"
    "VL-ANNOTATIVE-REMOVESCALE" "VL-ANNOTATIVE-RESET"
    "VL-ANNOTATIVE-SCALELIST" "VL-ANNOTATIVE-SET"
    "VL-ANNOTATIVE-SETSCALES" "VL-ANNOTATIVE-SUPPORTED"
    "VL-SUBENT-ATPOINT" "VL-SUBENT-SELECT" "VL-SUBENT-SSADD"
    "VL-SUBENT-SSDEL" "VL-SUBENT-SSMEMB"
    "VL-VPLAYER-GET-COLOR" "VL-VPLAYER-GET-LINETYPE"
    "VL-VPLAYER-GET-LINEWEIGHT" "VL-VPLAYER-GET-TRANSPARENCY"
    "VL-VPLAYER-SET-COLOR" "VL-VPLAYER-SET-LINETYPE"
    "VL-VPLAYER-SET-LINEWEIGHT" "VL-VPLAYER-SET-TRANSPARENCY"
    "VL-VPLAYER-SET-TRUECOLOR"
    "VL-VECTOR-PROJECT-POINTTOENTITY"))

(defun make-builtin-runtime-error (code builtin-name condition)
  (error 'autolisp-runtime-error
         :code code
         :message (format nil
                          "AutoLISP builtin ~A signaled an error: ~A"
                          builtin-name
                          condition)
         :details (list :builtin builtin-name
                        :condition condition)
         :call-stack (current-autolisp-call-stack)))

(defun signal-builtin-argument-error (code builtin-name control-string &rest arguments)
  (error 'autolisp-runtime-error
         :code code
         :message (apply #'format nil control-string arguments)
         :details (list* :builtin builtin-name arguments)
         :call-stack (current-autolisp-call-stack)))

(defun signal-builtin-host-error (code builtin-name control-string &rest arguments)
  (error 'autolisp-runtime-error
         :code code
         :message (apply #'format nil control-string arguments)
         :details (list* :builtin builtin-name arguments)
         :call-stack (current-autolisp-call-stack)))

(defun wrap-builtin-function (builtin-name function)
  (lambda (&rest arguments)
    (handler-case
        (apply function arguments)
      (autolisp-runtime-error (condition)
        (error condition))
      (file-error (condition)
        (make-builtin-runtime-error :builtin-file-error builtin-name condition))
      (error (condition)
        (make-builtin-runtime-error :builtin-error builtin-name condition)))))

;;; --- ERRNO helpers ------------------------------------------------
;;;
;;; AutoLISP system variable ~ERRNO~ (autolisp-spec §16) is set by a
;;; documented subset of builtins on failure: entget, entmake,
;;; entmod, entsel, findfile, load, nentsel, open, read-line, ssget,
;;; ssname, tablet, write-line, xdsize. Codes are enumerated in
;;; Autodesk's AutoLISP "Error Codes Reference" -- the 86-row table
;;; first published as
;;; help.autodesk.com/cloudhelp/2015/ENU/AutoCAD-AutoLISP/files/
;;; GUID-97327347-2A13-4CBC-BDBF-979C7F1CABD5.htm and unchanged in
;;; later releases. Phase-3-followup wiring (this work) threads the
;;; matching SET-AUTOLISP-ERRNO calls through every failure site.
;;;
;;; SUCCESS-on-set-errno-0 is per Autodesk's documented behaviour
;;; ("ERRNO is reset on a successful AutoLISP call"). We don't
;;; reset ERRNO on the entry path -- AutoCAD's own note that ERRNO
;;; "is not always cleared to zero" means callers must inspect it
;;; immediately after a documented failure, before any subsequent
;;; call (including the inspect itself) has a chance to reset it.
;;;
;;; Common codes (excerpt; see Source Notes above):
;;;
;;;     0   No error / success
;;;     1   Invalid symbol-table name
;;;     2   Invalid entity or selection-set name
;;;     4   Invalid selection set
;;;     7   Object selection: pick failed
;;;    13   Invalid handle
;;;    17   Invalid use of deleted entity
;;;    18   Invalid table name
;;;    22   Value out of range
;;;    31   Attempt to modify deleted entity
;;;    36   Bad entity type
;;;    50   Improper location of APPID field
;;;    51   Exceeded maximum XDATA size
;;;    52   Entity selection: null response
;;;    68   Digitizer is not a tablet
;;;    69   Tablet is not calibrated
;;;    70   Invalid tablet arguments
;;;    73   Cannot open executable file

(declaim (inline errno-and-return))
(defun errno-and-return (code value)
  "Set ERRNO to CODE and return VALUE. Used at builtin failure /
success sites to record the documented AutoLISP error code without
disrupting the value-returning shape of the call site."
  (set-autolisp-errno code)
  value)

(defun make-core-builtin-subr (name function)
  (make-autolisp-subr name (wrap-builtin-function name function)))

(defun builtin-boundp (object)
  (unless (typep object 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "BOUNDP"
     "Expected an AutoLISP symbol, got ~S."
     object))
  (clautolisp.autolisp-runtime:autolisp-boundp object))

(defun builtin-vl-bb-ref (object)
  (unless (typep object 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-BB-REF"
     "VL-BB-REF expects an AutoLISP symbol, got ~S."
     object))
  (nth-value 0 (blackboard-ref object)))

(defun builtin-vl-bb-set (symbol value)
  (unless (typep symbol 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-BB-SET"
     "VL-BB-SET expects an AutoLISP symbol, got ~S."
     symbol))
  (blackboard-set symbol value))

(defun builtin-vl-propagate (symbol)
  (unless (typep symbol 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-PROPAGATE"
     "VL-PROPAGATE expects an AutoLISP symbol, got ~S."
     symbol))
  (propagate-variable symbol))

(defun builtin-vl-doc-ref (object)
  (unless (typep object 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-DOC-REF"
     "VL-DOC-REF expects an AutoLISP symbol, got ~S."
     object))
  (nth-value 0 (current-document-namespace-ref object)))

(defun builtin-vl-doc-set (symbol value)
  (unless (typep symbol 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-DOC-SET"
     "VL-DOC-SET expects an AutoLISP symbol, got ~S."
     symbol))
  (current-document-namespace-set symbol value))

(defun builtin-vl-doc-export (object)
  (unless (typep object 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-DOC-EXPORT"
     "VL-DOC-EXPORT currently expects an AutoLISP symbol, got ~S."
     object))
  (export-function-to-current-document object))

(defun builtin-vl-doc-import (object)
  (cond
    ((typep object 'autolisp-symbol)
     (import-function-from-current-document object))
    ((typep object 'autolisp-string)
     (import-functions-from-application object))
    (t
     (signal-builtin-argument-error
      :invalid-symbol-argument
      "VL-DOC-IMPORT"
      "VL-DOC-IMPORT currently expects an AutoLISP symbol or application string, got ~S."
      object))))

(defun require-function-definition-list (object operator-name)
  (unless (and (consp object) (listp object))
    (signal-builtin-argument-error
     :invalid-defun-q-definition
     operator-name
     "~A expects a proper list function definition, got ~S."
     operator-name
     object))
  object)

(defun builtin-defun-q-list-ref (object)
  (unless (typep object 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "DEFUN-Q-LIST-REF"
     "DEFUN-Q-LIST-REF expects an AutoLISP symbol, got ~S."
     object))
  (autolisp-function-list-definition object))

(defun builtin-defun-q-list-set (symbol definition)
  (unless (typep symbol 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "DEFUN-Q-LIST-SET"
     "DEFUN-Q-LIST-SET expects an AutoLISP symbol, got ~S."
     symbol))
  (let* ((list-definition (require-function-definition-list definition "DEFUN-Q-LIST-SET"))
         (lambda-list (first list-definition))
         (body (rest list-definition))
         (function (make-autolisp-usubr (autolisp-symbol-name symbol)
                                        lambda-list
                                        body
                                        (default-evaluation-context))))
    (set-autolisp-symbol-function symbol function)
    (set-autolisp-function-list-definition symbol list-definition)
    symbol))

(defun filename-extension-present-p (string)
  (let* ((normalized (normalize-path-string string))
         (separator (position #\/ normalized :from-end t))
         (leaf (if separator
                   (subseq normalized (1+ separator))
                   normalized)))
    (not (null (position #\. leaf :from-end t)))))

(defun load-candidate-paths (filename)
  (let ((normalized (normalize-path-string filename)))
    (if (filename-extension-present-p normalized)
        (list normalized)
        (mapcar (lambda (extension)
                  (concatenate 'string normalized extension))
                '(".vlx" ".fas" ".lsp")))))

(defun resolve-load-pathname (filename)
  (let ((normalized (normalize-path-string filename)))
    (cond
      ((directory-prefix-p normalized)
       (dolist (candidate (load-candidate-paths normalized) nil)
         (let ((resolved (resolve-open-pathname candidate)))
           (when (probe-file resolved)
             (return resolved)))))
      (t
       (dolist (candidate (load-candidate-paths normalized) nil)
         (let ((direct (probe-file (resolve-open-pathname candidate))))
           (when direct
             (return direct)))
         (let ((located (search-path-list-for-file candidate
                                                   (%effective-support-dirs))))
           (when located
             (return (pathname located)))))))))

(defun evaluate-load-onfailure (object)
  (cond
    ((null object) nil)
    ((or (typep object 'autolisp-subr)
         (typep object 'clautolisp.autolisp-runtime:autolisp-usubr))
     (call-autolisp-function object))
    ((typep object 'autolisp-symbol)
     (call-autolisp-function
      (resolve-autolisp-function-designator object)))
    (t
     object)))

(defun %coerce-encoding-designator (object operator-name)
  "Coerce a string-designator (autolisp-string or autolisp-symbol) to
its underlying CL string for encoding-API consumers. Returns nil
when OBJECT is nil. Signals :invalid-string-argument on anything
else."
  (cond
    ((null object) nil)
    ((typep object 'autolisp-string) (autolisp-string-value object))
    ((typep object 'autolisp-symbol) (autolisp-symbol-name object))
    (t
     (signal-builtin-argument-error
      :invalid-string-argument
      operator-name
      "~A expects a string designator (string or symbol) for the encoding argument, got ~S."
      operator-name
      object))))

(defun %resolve-load-external-format (encoding-string operator-name)
  "Map ENCODING-STRING (a CL string from %COERCE-ENCODING-DESIGNATOR)
to the CL external-format keyword PARSE-LOCALE-ENCODING-STRING
recognises. Unknown but syntactically-plausible names pass through
upcased; a nil ENCODING-STRING returns nil so the load path falls
back to the documented precedence chain. Signals
:invalid-encoding-argument on a value the resolver can't accept."
  (cond
    ((null encoding-string) nil)
    (t
     (let ((kw (clautolisp.autolisp-runtime:parse-locale-encoding-string
                encoding-string)))
       (unless kw
         (signal-builtin-argument-error
          :invalid-encoding-argument
          operator-name
          "~A: encoding ~S is not a recognised encoding name."
          operator-name
          encoding-string))
       kw))))

(defun %dispatch-load-encoding-diagnostic (encoding-string)
  "Emit the encoding-dispatch.issue diagnostic appropriate for the
running dialect when LOAD is called with the clautolisp-native
positional [encoding] argument:

- :clautolisp        accept silently.
- :strict            enc-extension-used (every extension is reported).
- :autocad-2026      enc-foreign-dialect / clautolisp (foreign form).
- :bricscad-v26      enc-foreign-dialect / clautolisp (foreign form).
- anything else      silent (forward-compatible :lax / unknown dialects).

The form is ALWAYS honoured at runtime regardless of dialect; only
the diagnostic varies. encoding-dispatch.issue, section 'Per-dialect
behavior'."
  (let* ((dialect (current-evaluation-dialect))
         (name (clautolisp.autolisp-reader:autolisp-dialect-name dialect)))
    (case name
      ((:strict)
       (clautolisp.autolisp-runtime:signal-encoding-diagnostic
        :enc-extension-used
        "LOAD's positional [encoding] argument (~S) is a clautolisp extension; ~
--strict reports every encoding extension."
        encoding-string))
      ((:autocad-2026 :bricscad-v26)
       (clautolisp.autolisp-runtime:signal-encoding-diagnostic
        :enc-foreign-dialect
        "LOAD's positional [encoding] argument (~S) is a clautolisp ~
extension; --~(~A~) has no per-call encoding control on LOAD."
        encoding-string (case name
                          (:autocad-2026 "autocad")
                          (:bricscad-v26 "bricscad")
                          (t name))))
      (t nil))))

;;; --- SECURELOAD trust gate (Phase 3) -------------------------------
;;;
;;; The behavioural side of the trust model: load / open consult
;;; SECURELOAD + the trusted set (TRUSTEDPATHS u implicit folders u the
;;; trusted init files) and either allow, warn-and-proceed, or block.
;;; The pure decisions live in secureload.lisp; these helpers read the
;;; host sysvars and the runtime init-file set. See
;;; documentation/clautolisp-secureload-trust-model-spec.org.

(defun %secureload-dialect-name ()
  (let ((d (ignore-errors (current-evaluation-dialect))))
    (and d (clautolisp.autolisp-reader:autolisp-dialect-name d))))

(defun %secureload-trusted-p (abs-namestring host dialect-name)
  "True when ABS-NAMESTRING is a trusted load location for the current
host / dialect."
  (let ((trustedpaths (and host (ignore-errors
                                  (%host-sysvar-string host "TRUSTEDPATHS"))))
        (implicit (and host (eq dialect-name :clautolisp)
                       (ignore-errors
                        (%host-sysvar-string
                         host "CLAUTOLISPIMPLICITLYTRUSTEDFOLDERPATHS")))))
    (secureload-path-trusted-p
     abs-namestring trustedpaths implicit
     (clautolisp.autolisp-runtime:autolisp-trusted-init-files))))

(defun %secureload-trusted-dirs ()
  "The trusted directories for the current host / dialect: the folders
named by TRUSTEDPATHS plus (under clautolisp) the implicit folders.
Used by FINDFILE (union) and FINDTRUSTEDFILE (trusted-only)."
  (let* ((host (ignore-errors (current-evaluation-host)))
         (dialect-name (%secureload-dialect-name))
         (trustedpaths (and host (ignore-errors
                                  (%host-sysvar-string host "TRUSTEDPATHS"))))
         (implicit (and host (eq dialect-name :clautolisp)
                        (ignore-errors
                         (%host-sysvar-string
                          host "CLAUTOLISPIMPLICITLYTRUSTEDFOLDERPATHS")))))
    ;; The sysvar-named dirs, plus the programmatic *AUTOLISP-TRUSTED-PATHS*
    ;; list (set-autolisp-trusted-paths) for callers that configure trust
    ;; in CL rather than via the sysvar.
    (append (trusted-spec-directories trustedpaths implicit)
            (clautolisp.autolisp-runtime:autolisp-trusted-paths))))

(defun %normalize-support-dir (dir)
  "Resolve DIR (possibly relative, '.' or './') to an absolute directory
namestring against the current directory, so a CLAUTOLISPSUPPORTFILE-
SEARCHPATH default of \"./\" behaves exactly like the cwd."
  (let ((p (uiop:ensure-directory-pathname dir))
        (cwd (uiop:ensure-directory-pathname
              (clautolisp.autolisp-runtime:autolisp-current-directory))))
    (namestring (if (uiop:absolute-pathname-p p)
                    p
                    (uiop:merge-pathnames* p cwd)))))

(defun %effective-support-dirs ()
  "The directories a relative LOAD / OPEN / FINDFILE name is searched in.
Always begins with the *AUTOLISP-SUPPORT-PATHS* list (default the cwd);
under the clautolisp dialect the CLAUTOLISPSUPPORTFILESEARCHPATH folders
(TRUSTEDPATHS syntax, default \"./\", normalised to absolute) are
appended AFTER it. So the support paths take precedence over the
clautolisp sysvar, and non-clautolisp dialects are unchanged."
  (let* ((host (ignore-errors (current-evaluation-host)))
         (dialect-name (%secureload-dialect-name))
         (base (clautolisp.autolisp-runtime:autolisp-support-paths))
         (spec (and host (eq dialect-name :clautolisp)
                    (ignore-errors
                     (%host-sysvar-string
                      host "CLAUTOLISPSUPPORTFILESEARCHPATH"))))
         (dirs (and spec (trusted-spec-directories spec))))
    (if dirs
        (remove-duplicates
         (append base (mapcar #'%normalize-support-dir dirs))
         :test #'string= :from-end t)
        base)))

(defun %secureload-guard (abs-namestring builtin-name diagnostic-code)
  "Apply the SECURELOAD gate to ABS-NAMESTRING (already known to be a
gated file). Returns :PROCEED — allow, or warn-and-proceed with a
diagnostic emitted — or :BLOCK, which the caller turns into ERRNO + a
security error. Host-less contexts (no SECURELOAD cell) default to
allow."
  (let* ((host (ignore-errors (current-evaluation-host)))
         (dialect-name (%secureload-dialect-name))
         (secureload (%host-sysvar-integer host "SECURELOAD" 0))
         (trusted-p (%secureload-trusted-p abs-namestring host dialect-name))
         (action (secureload-action secureload trusted-p)))
    (case action
      (:warn
       (clautolisp.autolisp-runtime:signal-secureload-diagnostic
        diagnostic-code
        "~A: ~A is a gated file in an untrusted location (SECURELOAD=~A); ~
on a host with SECURELOAD=2 this would be blocked. Add its folder to ~
TRUSTEDPATHS to trust it."
        builtin-name abs-namestring secureload)
       :proceed)
      (:block :block)
      (otherwise :proceed))))

(defun builtin-load (filename
                     &optional (onfailure nil onfailure-supplied-p)
                               (encoding nil encoding-supplied-p))
  ;; Documented to set ERRNO on failure. Code 73 ("Cannot open
  ;; executable file") matches the failure shape; success resets to 0.
  ;;
  ;; ENCODING is the clautolisp-only third positional argument
  ;; specified in issues/closed/encoding-dispatch.issue. A string
  ;; designator (string or symbol) per the spec's "string-designator"
  ;; type. When supplied, it overrides *AUTOLISP-FILE-ENCODING* for
  ;; this single LOAD call.
  ;;
  ;; Under --strict / --autocad / --bricscad this form is a foreign-
  ;; dialect spelling; the runtime still honours the encoding (so
  ;; user code stays runnable across dialects) but an enc-* diagnostic
  ;; is emitted at this call site via
  ;; %DISPATCH-LOAD-ENCODING-DIAGNOSTIC.
  (let* ((value (autolisp-string-value (require-string filename "LOAD")))
         (resolved (resolve-load-pathname value))
         (encoding-string (and encoding-supplied-p
                               (%coerce-encoding-designator encoding "LOAD")))
         (encoding-kw (and encoding-supplied-p
                           (%resolve-load-external-format encoding-string "LOAD"))))
    (when encoding-supplied-p
      (%dispatch-load-encoding-diagnostic encoding-string))
    (cond
      ((null resolved)
       (set-autolisp-errno 73)
       (if onfailure-supplied-p
           (evaluate-load-onfailure onfailure)
           (call-with-autolisp-error-handler
            (lambda ()
              (signal-builtin-host-error
               :load-file-not-found
               "LOAD"
               "LOAD could not locate ~A."
               value)))))
      ((member (string-downcase (or (pathname-type resolved) "")) '("vlx" "fas")
               :test #'string=)
       (set-autolisp-errno 73)
       (if onfailure-supplied-p
           (evaluate-load-onfailure onfailure)
           (call-with-autolisp-error-handler
            (lambda ()
              (signal-builtin-host-error
               :unsupported-load-file-type
               "LOAD"
               "LOAD currently supports only source files, got ~A."
               (namestring resolved))))))
      (t
       ;; Bind *AUTOLISP-LOAD-PATHNAME* to the ABSOLUTE pathname of the
       ;; file being loaded, restoring the prior value (or nil at top
       ;; level) on the way out. UNWIND-PROTECT covers both normal and
       ;; non-local exits so a failed load doesn't leave a stale value
       ;; behind. See issues/closed/autolisp-load-pathname.issue.
       (let* ((load-pathname-sym
               (clautolisp.autolisp-runtime:intern-autolisp-symbol
                "*AUTOLISP-LOAD-PATHNAME*"))
              (prior-value
               (multiple-value-bind (v boundp)
                   (clautolisp.autolisp-runtime:lookup-variable
                    load-pathname-sym)
                 (and boundp v)))
              (absolute
               (or (ignore-errors (truename resolved)) resolved))
              (absolute-as-autolisp
               (clautolisp.autolisp-runtime:make-autolisp-string
                (namestring absolute))))
         (if (eq :block (%secureload-guard (namestring absolute)
                                           "LOAD" :sec-untrusted-load))
             ;; SECURELOAD=2 + untrusted: refuse, like the not-found path.
             (progn
               (set-autolisp-errno 73)
               (if onfailure-supplied-p
                   (evaluate-load-onfailure onfailure)
                   (call-with-autolisp-error-handler
                    (lambda ()
                      (signal-builtin-host-error
                       :load-untrusted-file
                       "LOAD"
                       "LOAD blocked: ~A is not in a trusted location ~
(SECURELOAD=2). Add its folder to TRUSTEDPATHS to trust it."
                       (namestring absolute))))))
             (unwind-protect
                  (progn
                    (clautolisp.autolisp-runtime:set-variable
                     load-pathname-sym absolute-as-autolisp)
                    (let ((result (if encoding-kw
                                      (autolisp-load-file
                                       (namestring resolved)
                                       :external-format encoding-kw)
                                      (autolisp-load-file
                                       (namestring resolved)))))
                      (set-autolisp-errno 0)
                      result))
               (clautolisp.autolisp-runtime:set-variable
                load-pathname-sym prior-value))))))))

(defun builtin-autoload (filename function-list)
  (let ((path (autolisp-string-value (require-string filename "AUTOLOAD"))))
    (require-proper-list function-list "AUTOLOAD")
    (dolist (name function-list nil)
      (let* ((command-name (autolisp-string-value (require-string name "AUTOLOAD")))
             (symbol (intern-autolisp-symbol command-name))
             (stub nil))
        (setf stub
              (make-autolisp-subr
               command-name
               (lambda (&rest arguments)
                 (builtin-load (make-autolisp-string path))
                 (let ((function (resolve-autolisp-function-designator symbol)))
                   (when (eq function stub)
                     (signal-builtin-host-error
                      :autoload-definition-missing
                      "AUTOLOAD"
                      "AUTOLOAD loaded ~A but did not define ~A."
                      path
                      command-name))
                   (apply #'call-autolisp-function function arguments)))))
        (set-autolisp-symbol-function symbol stub)))))

(defun builtin-vl-catch-all-apply (function-designator arg-list)
  (require-proper-list arg-list "VL-CATCH-ALL-APPLY")
  (let* ((function (resolve-autolisp-function-designator function-designator))
         ;; Record this catch on the per-thread catch stack so the
         ;; debugger's snapshot can show it (spec §10.2). The binding pops
         ;; automatically when the apply returns or unwinds. ARG-LIST is
         ;; already the CL list of runtime arguments.
         (clautolisp.autolisp-runtime:*autolisp-catch-stack*
           (cons (clautolisp.autolisp-runtime:make-catch-frame
                  :function function :arguments arg-list)
                 clautolisp.autolisp-runtime:*autolisp-catch-stack*)))
  (handler-case
      (let ((result (apply #'call-autolisp-function function arg-list)))
        (set-autolisp-errno 0)
        result)
    (autolisp-termination (condition)
      ;; (exit) and (quit) are catchable by VL-CATCH-ALL-APPLY on
      ;; AutoCAD and BricsCAD: the vendor implementations signal a
      ;; normal error with message "quit / exit abort" that flows
      ;; through ordinary error handlers. Test frameworks (e.g.
      ;; test-unitaire.lsp's t:fail / t:throw / t:run-test path)
      ;; rely on this — wrapping the test in VL-CATCH-ALL-APPLY and
      ;; expecting a thrown (quit) to surface as a catch-all error
      ;; rather than tear down the process.
      ;;
      ;; When no VL-CATCH-ALL-APPLY is on the stack, the condition
      ;; still propagates past the runtime's top-level handler in
      ;; clautolisp/tools/clautolisp/source/main.lisp (and the
      ;; equivalent in alfe), which exits the process cleanly —
      ;; matching the vendor "exits when not trapped" surface.
      (set-autolisp-errno 1)
      (make-autolisp-catch-all-error
       ;; Vendor canonical message ("quit / exit abort") is the same
       ;; regardless of whether the source called (exit) or (quit) —
       ;; the runtime distinguishes them via the :kind slot on the
       ;; underlying condition for code that inspects the catch-all
       ;; error stack via VL-CATCH-ALL-ERROR-STACK.
       "quit / exit abort"
       condition))
    (autolisp-namespace-exit (condition)
      ;; vl-exit-with-error / vl-exit-with-value are documented as
      ;; catchable: they leave the dynamic extent of the apply with
      ;; either a catch-all error (for :error) or a returned value
      ;; (for :value). Other :kind values keep escaping until a
      ;; matching VLX boundary or back out of vl-catch-all-apply.
      (case (clautolisp.autolisp-runtime:autolisp-namespace-exit-kind condition)
        (:error
         (set-autolisp-errno 1)
         (make-autolisp-catch-all-error
          (let ((value (clautolisp.autolisp-runtime:autolisp-namespace-exit-value condition)))
            (cond ((typep value 'clautolisp.autolisp-runtime:autolisp-string)
                   (clautolisp.autolisp-runtime:autolisp-string-value value))
                  ((stringp value) value)
                  (t (princ-to-string value))))
          condition))
        (:value
         (set-autolisp-errno 0)
         (clautolisp.autolisp-runtime:autolisp-namespace-exit-value condition))
        (otherwise
         (error condition))))
    (autolisp-runtime-error (condition)
      ;; Break-on-caught (spec §10.2): off unless the debugger armed the hook.
      (when clautolisp.autolisp-runtime:*autolisp-caught-error-hook*
        (funcall clautolisp.autolisp-runtime:*autolisp-caught-error-hook* condition))
      (set-autolisp-errno
       (autolisp-runtime-error-errno condition))
      (make-autolisp-catch-all-error
       (princ-to-string condition)
       condition))
    (error (condition)
      (set-autolisp-errno 1)
      (make-autolisp-catch-all-error
       (princ-to-string condition)
       condition)))))

(defun builtin-vl-catch-all-error-p (object)
  (if (typep object 'autolisp-catch-all-error)
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-vl-catch-all-error-message (object)
  (unless (typep object 'autolisp-catch-all-error)
    (signal-builtin-argument-error
     :invalid-catch-all-object
     "VL-CATCH-ALL-ERROR-MESSAGE"
     "VL-CATCH-ALL-ERROR-MESSAGE expects a catch-all error object, got ~S."
     object))
  (make-autolisp-string (autolisp-catch-all-error-message object)))

;;; --- clautolisp exit-status channel -------------------------------
;;;
;;; autolisp-set-status / autolisp-status / (quit [status]) — a small
;;; process-exit-status channel that mirrors the alfe CAD bootstrap
;;; `autolisp-set-status`, so a single C:MAIN reports pass/fail
;;; identically under BricsCAD, AutoCAD and clautolisp without engine
;;; branches. See issues/open/autolisp-set-status-and-quit-status.issue.
;;;
;;; These are clautolisp extensions: silent under --clautolisp / --lax,
;;; and — only when the STATUS argument is actually supplied — flagged
;;; with a non-fatal out-of-dialect WARNING under --strict / --autocad /
;;; --bricscad (dialect problems warn, never error; the call still takes
;;; effect). Zero-arg (quit)/(exit) stay standard and silent.

(defun %exit-status-extension-allowed-p ()
  "True under the dialects that natively own the exit-status channel
(--clautolisp and the catch-all --lax); false elsewhere, where its use
is flagged as non-portable."
  (let* ((dialect (ignore-errors (current-evaluation-dialect)))
         (name (and dialect
                    (clautolisp.autolisp-reader:autolisp-dialect-name dialect))))
    (and (member name '(:clautolisp :lax)) t)))

(defun emit-exit-status-extension-warning (form)
  "Emit a non-fatal out-of-dialect WARNING for an exit-status-channel
FORM used under a dialect that does not natively own it. Mirrors
EMIT-TERPRI-FILE-EXTENSION-WARNING: dialect problems are flagged, never
raised. The call still takes effect."
  (let* ((dialect (ignore-errors (current-evaluation-dialect)))
         (name (and dialect
                    (clautolisp.autolisp-reader:autolisp-dialect-name dialect))))
    (format *error-output*
            "~&[exit-status-extension] `~A' is a clautolisp extension; ~
--dialect ~(~A~) flags it as non-portable (on the CAD hosts the exit ~
status is recorded via alfe's injected autolisp-set-status). Use ~
--dialect clautolisp to silence.~%"
            form (or name "default"))))

(defun require-exit-status (object operator-name)
  "Coerce OBJECT to the integer exit status carried by the channel.
AutoLISP integers pass through; a real is truncated (mirroring sysvar
integer coercion); anything else is rejected."
  (cond
    ((integerp object) object)
    ((numberp object) (truncate object))
    (t
     (signal-builtin-argument-error
      :invalid-integer-argument
      operator-name
      "~A expects an integer status, got ~S."
      operator-name
      object))))

(defun builtin-autolisp-set-status (status)
  "Record STATUS (an integer) as the pending process exit status,
returning it. Mirrors the CAD-side autolisp-set-status (minus the
STATUSFILE write)."
  (unless (%exit-status-extension-allowed-p)
    (emit-exit-status-extension-warning "(autolisp-set-status status)"))
  (let ((value (require-exit-status status "AUTOLISP-SET-STATUS")))
    (set-autolisp-exit-status value)
    value))

(defun builtin-autolisp-status ()
  "Return the pending process exit status (0 when never set)."
  (unless (%exit-status-extension-allowed-p)
    (emit-exit-status-extension-warning "(autolisp-status)"))
  (autolisp-exit-status))

(defun %terminate-with-status (kind operator form status-supplied-p status)
  "Shared body of (exit [status]) / (quit [status]). When STATUS is
supplied it becomes the process exit status (recorded via the same slot
as autolisp-set-status, after the out-of-dialect check); otherwise the
session's already-stored autolisp-status is used. Signals
autolisp-termination carrying the effective status."
  (let ((effective
          (if status-supplied-p
              (progn
                (unless (%exit-status-extension-allowed-p)
                  (emit-exit-status-extension-warning form))
                (let ((value (require-exit-status status operator)))
                  (set-autolisp-exit-status value)
                  value))
              (autolisp-exit-status))))
    (error 'autolisp-termination :kind kind :status effective)))

(defun builtin-exit (&optional (status nil status-supplied-p))
  (%terminate-with-status :exit "EXIT" "(exit status)" status-supplied-p status))

(defun builtin-quit (&optional (status nil status-supplied-p))
  (%terminate-with-status :quit "QUIT" "(quit status)" status-supplied-p status))

(defun builtin-vl-exit-with-error (message)
  (let ((text (autolisp-string-value (require-string message "VL-EXIT-WITH-ERROR"))))
    (error 'autolisp-namespace-exit :kind :error :value text)))

(defun builtin-vl-exit-with-value (value)
  (error 'autolisp-namespace-exit :kind :value :value value))

(defun builtin-mapcar (function-designator first-list &rest more-lists)
  (let* ((function (resolve-autolisp-function-designator function-designator))
         (lists (mapcar (lambda (object)
                          (require-proper-list object "MAPCAR"))
                        (cons first-list more-lists)))
         (results '()))
    (loop while (every #'consp lists)
          do (push (apply #'call-autolisp-function
                          function
                          (mapcar #'car lists))
                   results)
             (setf lists (mapcar #'cdr lists)))
    (nreverse results)))

(defun builtin-apply (function-designator argument-list)
  ;; (apply 'function list) — call function with the elements of list
  ;; spread as positional arguments. function-designator is whatever
  ;; resolve-autolisp-function-designator accepts: a subr/usubr, a
  ;; symbol naming a function, or a (lambda ...) / (quote (lambda ...))
  ;; / (function ...) form. nil is permitted in place of an empty
  ;; arg-list.
  (let ((function (resolve-autolisp-function-designator function-designator))
        (arguments (cond
                     ((null argument-list) '())
                     ((listp argument-list) argument-list)
                     (t
                      (signal-builtin-argument-error
                       :invalid-list-argument
                       "APPLY"
                       "APPLY expects a list of arguments, got ~S."
                       argument-list)))))
    (apply #'call-autolisp-function function arguments)))

(defun builtin-eval (form)
  ;; (eval expr) — evaluate the AutoLISP runtime form in the current
  ;; evaluation context. Lets programs evaluate values built at
  ;; runtime (e.g. constructed via list/cons). Routed through the
  ;; compiled-eval model (debugger-public-interface issue): under a debug
  ;; session the form is wrapped + instrumented so it is steppable; outside
  ;; a session this is a plain AUTOLISP-EVAL at full speed.
  (clautolisp.autolisp-runtime:autolisp-compiled-eval form))

(defun autolisp-equal-p (a b)
  ;; AutoLISP `equal` (autolisp-spec ch. 5, "Equality Predicates"):
  ;; structural over cons cells, content for strings, numeric across
  ;; int and real (so (equal 1 1.0) -> T), eq for everything else.
  (cond
    ((eql a b) t)
    ((and (numberp a) (numberp b)) (= a b))
    ((and (typep a 'autolisp-string) (typep b 'autolisp-string))
     (string= (autolisp-string-value a) (autolisp-string-value b)))
    ((and (consp a) (consp b))
     (and (autolisp-equal-p (car a) (car b))
          (autolisp-equal-p (cdr a) (cdr b))))
    (t nil)))

(defun builtin-eq (a b)
  ;; (eq a b) — pointer-level identity, with the standard exception
  ;; that two strings whose content is equal compare eq because the
  ;; host interns string literals (autolisp-spec ch. 5).
  (cond
    ((eql a b) (intern-autolisp-symbol "T"))
    ((and (typep a 'autolisp-string) (typep b 'autolisp-string)
          (string= (autolisp-string-value a) (autolisp-string-value b)))
     (intern-autolisp-symbol "T"))
    (t nil)))

(defun builtin-equal (a b &optional fuzz)
  ;; AutoLISP allows a third numeric `fuzz` argument that loosens
  ;; numeric comparisons by ±fuzz. When fuzz is nil or 0 the call
  ;; reduces to ordinary equal.
  (let ((tolerance (if (or (null fuzz) (and (numberp fuzz) (zerop fuzz)))
                       nil
                       fuzz)))
    (cond
      ((null tolerance)
       (if (autolisp-equal-p a b) (intern-autolisp-symbol "T") nil))
      ((not (numberp tolerance))
       (signal-builtin-argument-error
        :invalid-number-argument
        "EQUAL"
        "EQUAL fuzz must be a number, got ~S."
        fuzz))
      ((and (numberp a) (numberp b))
       (if (<= (abs (- a b)) tolerance)
           (intern-autolisp-symbol "T")
           nil))
      (t
       (if (autolisp-equal-p a b) (intern-autolisp-symbol "T") nil)))))

(defun builtin-vl-every (function-designator first-list &rest more-lists)
  (let* ((function (resolve-autolisp-function-designator function-designator))
         (lists (mapcar (lambda (object)
                          (require-proper-list object "VL-EVERY"))
                        (cons first-list more-lists))))
    (loop while (every #'consp lists)
          do (unless (autolisp-true-p
                      (apply #'call-autolisp-function
                             function
                             (mapcar #'car lists)))
               (return nil))
             (setf lists (mapcar #'cdr lists))
          finally (return (intern-autolisp-symbol "T")))))

(defun builtin-vl-some (function-designator first-list &rest more-lists)
  (let* ((function (resolve-autolisp-function-designator function-designator))
         (lists (mapcar (lambda (object)
                          (require-proper-list object "VL-SOME"))
                        (cons first-list more-lists))))
    (loop while (every #'consp lists)
          for result = (apply #'call-autolisp-function
                              function
                              (mapcar #'car lists))
          do (when (autolisp-true-p result)
               (return result))
             (setf lists (mapcar #'cdr lists))
          finally (return nil))))

(defun builtin-vl-member-if (function-designator object)
  (let ((function (resolve-autolisp-function-designator function-designator)))
    (require-proper-list object "VL-MEMBER-IF")
    (do ((tail object (cdr tail)))
        ((null tail) nil)
      (when (autolisp-true-p (call-autolisp-function function (car tail)))
        (return tail)))))

(defun builtin-vl-member-if-not (function-designator object)
  (let ((function (resolve-autolisp-function-designator function-designator)))
    (require-proper-list object "VL-MEMBER-IF-NOT")
    (do ((tail object (cdr tail)))
        ((null tail) nil)
      (when (autolisp-false-p (call-autolisp-function function (car tail)))
        (return tail)))))

(defun builtin-vl-remove-if (function-designator object)
  (let ((function (resolve-autolisp-function-designator function-designator)))
    (require-proper-list object "VL-REMOVE-IF")
    (loop for element in object
          unless (autolisp-true-p (call-autolisp-function function element))
            collect element)))

(defun builtin-vl-remove-if-not (function-designator object)
  (let ((function (resolve-autolisp-function-designator function-designator)))
    (require-proper-list object "VL-REMOVE-IF-NOT")
    (loop for element in object
          when (autolisp-true-p (call-autolisp-function function element))
            collect element)))

(defun builtin-car (object)
  (cond
    ((null object) nil)
    ((consp object) (car object))
    (t
     (signal-builtin-argument-error
      :invalid-list-argument
      "CAR"
      "CAR expects a list, got ~S."
      object))))

(defun builtin-cdr (object)
  (cond
    ((null object) nil)
    ((consp object) (cdr object))
    (t
     (signal-builtin-argument-error
      :invalid-list-argument
      "CDR"
      "CDR expects a list or dotted pair, got ~S."
      object))))

;; The CAxR / CDxR / CAxxR / CDxxR family. Each one is a composition
;; of CAR and CDR walked right-to-left over the letters between `c'
;; and the trailing `r'. Each step delegates to builtin-car /
;; builtin-cdr so a non-list argument anywhere along the chain
;; produces the standard "X expects a list" diagnostic with the
;; proper builtin name.

(defmacro define-cxxr (name letters)
  `(defun ,(intern (format nil "BUILTIN-~A" name)) (object)
     (let ((value object))
       ,@(loop for c across (reverse letters)
               collect (case c
                         (#\A `(setf value
                                     (cond
                                       ((null value) nil)
                                       ((consp value) (car value))
                                       (t (signal-builtin-argument-error
                                           :invalid-list-argument
                                           ,name
                                           ,(format nil "~A expects a list, got ~~S." name)
                                           value)))))
                         (#\D `(setf value
                                     (cond
                                       ((null value) nil)
                                       ((consp value) (cdr value))
                                       (t (signal-builtin-argument-error
                                           :invalid-list-argument
                                           ,name
                                           ,(format nil "~A expects a list, got ~~S." name)
                                           value)))))))
       value)))

(define-cxxr "CAAR"  "AA")
(define-cxxr "CADR"  "AD")
(define-cxxr "CDAR"  "DA")
(define-cxxr "CDDR"  "DD")
(define-cxxr "CAAAR" "AAA")
(define-cxxr "CAADR" "AAD")
(define-cxxr "CADAR" "ADA")
(define-cxxr "CADDR" "ADD")
(define-cxxr "CDAAR" "DAA")
(define-cxxr "CDADR" "DAD")
(define-cxxr "CDDAR" "DDA")
(define-cxxr "CDDDR" "DDD")
(define-cxxr "CAAAAR" "AAAA")
(define-cxxr "CAAADR" "AAAD")
(define-cxxr "CAADAR" "AADA")
(define-cxxr "CAADDR" "AADD")
(define-cxxr "CADAAR" "ADAA")
(define-cxxr "CADADR" "ADAD")
(define-cxxr "CADDAR" "ADDA")
(define-cxxr "CADDDR" "ADDD")
(define-cxxr "CDAAAR" "DAAA")
(define-cxxr "CDAADR" "DAAD")
(define-cxxr "CDADAR" "DADA")
(define-cxxr "CDADDR" "DADD")
(define-cxxr "CDDAAR" "DDAA")
(define-cxxr "CDDADR" "DDAD")
(define-cxxr "CDDDAR" "DDDA")
(define-cxxr "CDDDDR" "DDDD")

(defun builtin-cons (first second)
  (cons first second))

(defun builtin-list (&rest objects)
  objects)

(defun proper-list-p (object)
  (loop
    while (consp object)
    do (setf object (cdr object))
    finally (return (null object))))

(defun require-proper-list (object operator-name)
  (unless (proper-list-p object)
    (signal-builtin-argument-error
     :invalid-proper-list-argument
     operator-name
     "~A expects a proper list, got ~S."
     operator-name
     object))
  object)

(defun autolisp-value= (left right)
  (cond
    ((and (null left) (null right))
     t)
    ((and (consp left) (consp right))
     (and (autolisp-value= (car left) (car right))
          (autolisp-value= (cdr left) (cdr right))))
    ((and (integerp left) (integerp right))
     (= left right))
    ((and (numberp left) (numberp right))
     (= left right))
    ((and (typep left 'autolisp-string)
          (typep right 'autolisp-string))
     (string= (autolisp-string-value left)
              (autolisp-string-value right)))
    ((and (typep left 'autolisp-symbol)
          (typep right 'autolisp-symbol))
     (string= (autolisp-symbol-name left)
              (autolisp-symbol-name right)))
    (t
     (eql left right))))

(defun builtin-append (&rest lists)
  (if (null lists)
      nil
      (progn
        (dolist (list (butlast lists))
          (require-proper-list list "APPEND"))
        (apply #'append lists))))

(defun builtin-assoc (key alist)
  (require-proper-list alist "ASSOC")
  (dolist (entry alist nil)
    (unless (consp entry)
      (signal-builtin-argument-error
       :invalid-alist-argument
       "ASSOC"
       "ASSOC expects an alist, got entry ~S."
       entry))
    (when (autolisp-value= key (car entry))
      (return entry))))

(defun builtin-length (object)
  (require-proper-list object "LENGTH")
  (length object))

(defun builtin-nth (index object)
  (unless (typep index '(integer 0 2147483647))
    (signal-builtin-argument-error
     :invalid-index-argument
     "NTH"
     "NTH expects a non-negative AutoLISP integer index, got ~S."
     index))
  (require-proper-list object "NTH")
  (nth index object))

(defun builtin-reverse (object)
  (require-proper-list object "REVERSE")
  (reverse object))

(defun builtin-last (object)
  (require-proper-list object "LAST")
  (if (null object)
      nil
      (loop
        while (consp (cdr object))
        do (setf object (cdr object))
        finally (return (car object)))))

(defun builtin-member (item object)
  (require-proper-list object "MEMBER")
  (loop
    while (consp object)
    do (when (autolisp-value= item (car object))
         (return object))
       (setf object (cdr object))
    finally (return nil)))

(defun subst-tree (new old expr)
  (cond
    ((autolisp-value= expr old)
     new)
    ((consp expr)
     (cons (subst-tree new old (car expr))
           (subst-tree new old (cdr expr))))
    (t
     expr)))

(defun builtin-subst (new old expr)
  (subst-tree new old expr))

(defun builtin-vl-consp (object)
  (if (consp object)
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-vl-list* (&rest arguments)
  (unless arguments
    (signal-builtin-argument-error
     :wrong-number-of-arguments
     "VL-LIST*"
     "VL-LIST* expects at least one argument."))
  (if (null (rest arguments))
      (first arguments)
      (apply #'list* arguments)))

(defun require-string (object operator-name)
  (unless (typep object 'autolisp-string)
    (signal-builtin-argument-error
     :invalid-string-argument
     operator-name
     "~A expects an AutoLISP string, got ~S."
     operator-name
     object))
  object)

(defun require-file (object operator-name)
  (unless (typep object 'autolisp-file)
    (signal-builtin-argument-error
     :invalid-file-argument
     operator-name
     "~A expects an AutoLISP file descriptor, got ~S."
     operator-name
     object))
  object)

(defun require-open-file-stream (file operator-name)
  (let ((stream (autolisp-file-stream (require-file file operator-name))))
    (unless stream
      (signal-builtin-argument-error
       :closed-file-descriptor
       operator-name
       "~A expects an open file descriptor."
       operator-name))
    stream))

(defun absolute-path-string-p (string)
  (or (uiop:absolute-pathname-p (pathname string))
      (and (>= (length string) 2)
           (alpha-char-p (char string 0))
           (char= #\: (char string 1)))
      (and (>= (length string) 2)
           (char= #\\ (char string 0))
           (char= #\\ (char string 1)))))

(defun normalize-path-string (string)
  ;; AutoLISP accepts both slash and backslash delimiters in pathname-oriented APIs.
  (substitute #\/ #\\ string))

(defun directory-prefix-p (string)
  (let ((normalized (normalize-path-string string)))
    (or (absolute-path-string-p normalized)
        (position #\/ normalized))))

(defun resolve-open-pathname (string)
  (let ((normalized (normalize-path-string string)))
    (if (absolute-path-string-p normalized)
        (pathname normalized)
        (merge-pathnames normalized
                         (pathname (autolisp-current-directory))))))

(defun resolve-open-search-pathname (string)
  "Resolve STRING for OPEN. An absolute name is used directly. A relative
name is first searched through the effective support dirs (so OPEN
honours the support search path like LOAD); when no existing file
matches — e.g. creating a new file for write — it falls back to the
current directory. With the default support path (the cwd) this is
identical to a plain cwd merge."
  (let ((normalized (normalize-path-string string)))
    (cond
      ((absolute-path-string-p normalized) (pathname normalized))
      (t
       (let ((located (search-path-list-for-file normalized
                                                 (%effective-support-dirs))))
         (if located
             (pathname located)
             (merge-pathnames normalized
                              (pathname (autolisp-current-directory)))))))))

(defun search-path-list-for-file (filename directories)
  (let ((normalized (normalize-path-string filename)))
    (unless (directory-prefix-p normalized)
      (dolist (directory directories nil)
        (let* ((base (pathname directory))
               (candidate (merge-pathnames normalized base))
               (located (probe-file candidate)))
          (when located
            (return (namestring located))))))))

(defun resolve-directory-pathname (directory-string operator-name)
  (let ((normalized (normalize-path-string directory-string)))
    (handler-case
        (uiop:ensure-directory-pathname
         (if (absolute-path-string-p normalized)
             (pathname normalized)
             (merge-pathnames normalized
                              (pathname (autolisp-current-directory)))))
      (error ()
        (signal-builtin-argument-error
         :invalid-directory-argument
         operator-name
         "~A expects a valid directory pathname, got ~S."
         operator-name
         directory-string)))))

(defun pathname-entry-name (pathname directoryp)
  (if directoryp
      (let* ((components (pathname-directory (uiop:ensure-directory-pathname pathname)))
             (last-component (car (last components))))
        (etypecase last-component
          (string last-component)
          (symbol (string last-component))))
      (file-namestring pathname)))

(defun wildcard-char= (pattern-char candidate-char)
  (char-equal pattern-char candidate-char))

(defun wildcard-match-p (pattern string)
  (labels ((match (pattern-index string-index)
             (cond
               ((= pattern-index (length pattern))
                (= string-index (length string)))
               ((char= #\* (char pattern pattern-index))
                (or (match (1+ pattern-index) string-index)
                    (and (< string-index (length string))
                         (match pattern-index (1+ string-index)))))
               ((char= #\? (char pattern pattern-index))
                (and (< string-index (length string))
                     (match (1+ pattern-index) (1+ string-index))))
               ((< string-index (length string))
                (and (wildcard-char= (char pattern pattern-index)
                                     (char string string-index))
                     (match (1+ pattern-index) (1+ string-index))))
               (t
                nil))))
    (match 0 0)))

(defun normalized-directory-pattern (pattern)
  (let ((value (normalize-path-string pattern)))
    (if (string= value "*.*")
        "*"
        value)))

(defun directory-selector-kind (directories)
  (let ((selector (if (null directories)
                      1
                      (require-int32 directories "VL-DIRECTORY-FILES"))))
    (cond
      ((= selector -1) :directories)
      ((= selector 0) :both)
      ((= selector 1) :files)
      (t
       (signal-builtin-argument-error
        :invalid-directory-selector
        "VL-DIRECTORY-FILES"
        "VL-DIRECTORY-FILES selector must be -1, 0, or 1, got ~S."
        directories)))))

(defun collect-directory-entries (directory selector pattern)
  (let ((results '()))
    (flet ((maybe-add (pathname directoryp)
             (let ((name (pathname-entry-name pathname directoryp)))
               (when (wildcard-match-p pattern name)
                 (push (make-autolisp-string name) results)))))
      (when (member selector '(:files :both))
        (dolist (pathname (uiop:directory-files directory))
          (maybe-add pathname nil)))
      (when (member selector '(:directories :both))
        (dolist (pathname (uiop:subdirectories directory))
          (maybe-add pathname t))))
    (nreverse results)))

(defun split-filename-components (filename)
  (let* ((normalized (normalize-path-string filename))
         (last-separator (position #\/ normalized :from-end t))
         (directory (if last-separator
                        (subseq normalized 0 last-separator)
                        ""))
         (leaf (if last-separator
                   (subseq normalized (1+ last-separator))
                   normalized))
         (dot-position (position #\. leaf :from-end t)))
    (values directory
            leaf
            (and dot-position (> dot-position 0) dot-position))))

(defun open-direction-and-options (mode)
  (cond
    ((string= mode "r")
     (values :input nil nil))
    ((string= mode "w")
     (values :output :supersede :create))
    ((string= mode "a")
     (values :output :append :create))
    (t
     (signal-builtin-argument-error
      :invalid-open-mode
      "OPEN"
      "OPEN mode must be one of \"r\", \"w\", or \"a\", got ~S."
      mode))))

(defun normalize-encoding-name (name)
  "Map an AutoLISP / Autodesk / BricsCAD encoding name (case-folded
ASCII, with optional dashes / underscores) to a SBCL- and CCL-
compatible :external-format keyword."
  (let ((canonical (with-output-to-string (out)
                     (loop for c across name
                           unless (or (char= c #\-) (char= c #\_) (char= c #\Space))
                             do (write-char (char-upcase c) out)))))
    (cond
      ;; Autodesk's documented short names.
      ((string= canonical "UTF8")     :utf-8)
      ((string= canonical "UTF8BOM")  :utf-8)
      ((string= canonical "UTF16")    :utf-16)
      ((string= canonical "UTF16LE")  :utf-16le)
      ((string= canonical "UTF16BE")  :utf-16be)
      ((string= canonical "UTF32")    :utf-32)
      ;; The "ANSI" short name historically meant the legacy host
      ;; code page. Map it to ISO-8859-1 — a strict 1-1 byte coding
      ;; that never fails on Western text. Hosts that need
      ;; Windows-1252 specifically can pass "cp1252" / "WINDOWS-1252"
      ;; explicitly.
      ((string= canonical "ANSI")     :iso-8859-1)
      ((string= canonical "ASCII")    :ascii)
      ((string= canonical "LATIN1")   :iso-8859-1)
      ((or (string= canonical "ISO88591")
           (string= canonical "8859.1"))
       :iso-8859-1)
      ((string= canonical "WINDOWS1252") :cp1252)
      ;; Spec's CP-NNNN registry (encoding-dispatch.issue Phase 9):
      ;; CP-1252 (already above) plus the nine additional spec
      ;; codepages. Strip the optional dash and intern as :cpNNNN
      ;; which both SBCL and CCL accept as a built-in external-format
      ;; (probed live; all ten are available on SBCL 2.6.3+).
      ((and (>= (length canonical) 4)
            (string= "CP" canonical :end2 2)
            (every #'digit-char-p (subseq canonical 2)))
       (intern (concatenate 'string "CP" (subseq canonical 2))
               "KEYWORD"))
      ;; WINDOWS-NNNN → :cpNNNN (clautolisp canonical encoding-alias
      ;; spelling).
      ((and (>= (length canonical) 7)
            (string= "WINDOWS" canonical :end2 7)
            (every #'digit-char-p (subseq canonical 7)))
       (intern (concatenate 'string "CP" (subseq canonical 7))
               "KEYWORD"))
      ;; Anything else: keywordise. SBCL / CCL accept many aliases.
      (t (intern canonical "KEYWORD")))))

(defparameter *cp-nnnn-registry*
  '((:cp1252 . "Western European")
    (:cp1250 . "Central European")
    (:cp1251 . "Cyrillic")
    (:cp1253 . "Greek")
    (:cp1254 . "Turkish")
    (:cp932  . "Japanese (Shift-JIS, DBCS)")
    (:cp936  . "Simplified Chinese (GBK, DBCS)")
    (:cp949  . "Korean (EUC-KR, DBCS)")
    (:cp950  . "Traditional Chinese (Big5, DBCS)"))
  "The ten CP-NNNN code pages the spec's encoding registry promises
to support. Each entry is (CL-KEYWORD . DESCRIPTION). The keyword is
what NORMALIZE-ENCODING-NAME emits and what the underlying CL OPEN
accepts as :external-format. See encoding-dispatch.issue, section
'Code pages: the ANSI row, expanded'.")

(defun %host-cl-supports-encoding-p (keyword)
  "True when the running CL implementation accepts KEYWORD as an
:external-format value. SBCL and CCL expose introspectable
registries; on other impls we conservatively return T (let the CL
OPEN surface its own error if the keyword turns out not to work).

Used by %CHECK-OPEN-ENCODING-SUPPORTED to surface
ENC-UNSUPPORTED-TARGET when user code requests a CP-NNNN the host
doesn't ship — e.g. CP-936 on a stripped-down SBCL build."
  #+sbcl
  (not (null (ignore-errors (sb-impl::get-external-format keyword))))
  #+ccl
  (not (null (ignore-errors (ccl:lookup-character-encoding keyword))))
  #-(or sbcl ccl)
  t)

(defun parse-open-external-format (string)
  "Decode the third argument of (open path mode ENCODING). Accepted
forms (autolisp-spec ch. 16, \"OPEN External-Format Argument\"):

  - empty / nil      -> dialect default (resolved by the caller).
  - keyword literal  -> e.g. \":utf-8\" / \":iso-8859-1\".
  - sexp literal     -> a Common-Lisp external-format designator,
                         e.g. \"(:utf-8 :replacement #\\?)\".
  - Autodesk short   -> \"utf8\", \"utf8-bom\", \"ANSI\", \"ASCII\".
  - BricsCAD CCS form -> \"r,ccs=UTF-8\", \"w,ccs=ISO-8859-1\". The
                         leading mode-letter is stripped by the
                         caller; this parser only sees the trailing
                         encoding fragment, so a leading
                         \"ccs=NAME\" (with or without the comma)
                         is also accepted directly.
"
  (cond
    ((or (null string) (zerop (length string)))
     (signal-builtin-argument-error
      :invalid-external-format
      "OPEN"
      "Invalid empty external format."))
    ((or (char= (char string 0) #\:)
         (char= (char string 0) #\())
     (handler-case
         (let ((value (read-from-string string)))
           (unless (typep value '(or keyword cons))
             (signal-builtin-argument-error
              :invalid-external-format
              "OPEN"
              "Invalid external format ~S."
              string))
           value)
       (error ()
         (signal-builtin-argument-error
          :invalid-external-format
          "OPEN"
          "Invalid external format ~S."
          string))))
    ;; BricsCAD-style "MODE,ccs=NAME" or bare "ccs=NAME".
    ((let ((eq (position #\= string)))
       (and eq
            (let ((tag (subseq string 0 eq)))
              (or (string-equal tag "ccs")
                  (and (>= (length tag) 4)
                       (string-equal (subseq tag (- (length tag) 4)) ",ccs"))))))
     (let* ((eq (position #\= string))
            (name (subseq string (1+ eq))))
       (normalize-encoding-name name)))
    (t
     (normalize-encoding-name string))))

(defun builtin-numberp (object)
  (if (numberp object)
      (intern-autolisp-symbol "T")
      nil))

(defun arithmetic-result (value)
  (cond
    ((typep value '(signed-byte 32))
     value)
    ((integerp value)
     (signal-builtin-argument-error
      :integer-overflow
      "ARITHMETIC"
      "Arithmetic result is outside the AutoLISP 32-bit integer range: ~S."
      value))
    ((rationalp value)
     (coerce value 'double-float))
    ((floatp value)
     (coerce value 'double-float))
    (t
     value)))

(defun builtin-+ (&rest arguments)
  (dolist (argument arguments)
    (require-number argument "+"))
  (arithmetic-result (apply #'+ arguments)))

(defun builtin-* (&rest arguments)
  (dolist (argument arguments)
    (require-number argument "*"))
  (arithmetic-result (apply #'* arguments)))

(defun builtin-- (first-number &rest more-numbers)
  (require-number first-number "-")
  (dolist (argument more-numbers)
    (require-number argument "-"))
  (arithmetic-result
   (if more-numbers
       (apply #'- first-number more-numbers)
       (- first-number))))

(defun builtin-/ (first-number &rest more-numbers)
  ;; AutoLISP `/` follows the per-spec rule (autolisp-spec, chapter 3,
  ;; "Number Tower and Division"): every-argument-integer divisions
  ;; truncate toward zero (BricsCAD V26 probe: (/ 7 2) = 3); any real
  ;; argument promotes the entire chain to real division.
  (require-number first-number "/")
  (dolist (argument more-numbers)
    (require-number argument "/"))
  (let ((all-integer (and (integerp first-number)
                          (every #'integerp more-numbers))))
    (handler-case
        (cond
          ((null more-numbers)
           ;; Unary `/` is rare in AutoLISP corpora; preserve the
           ;; legacy CL-style reciprocal but coerce through
           ;; arithmetic-result so a real input yields a real result.
           (arithmetic-result (/ 1 first-number)))
          (all-integer
           (arithmetic-result
            (reduce (lambda (a b) (truncate a b))
                    more-numbers :initial-value first-number)))
          (t
           (arithmetic-result (apply #'/ first-number more-numbers))))
      (division-by-zero ()
       (signal-builtin-host-error
        :division-by-zero
        "/"
        "Division by zero in /.")))))

(defun builtin-1+ (object)
  (arithmetic-result (1+ (require-number object "1+"))))

(defun builtin-1- (object)
  (arithmetic-result (1- (require-number object "1-"))))

(defun builtin-max (first-number &rest more-numbers)
  (require-number first-number "MAX")
  (dolist (argument more-numbers)
    (require-number argument "MAX"))
  (arithmetic-result (apply #'max first-number more-numbers)))

(defun builtin-min (first-number &rest more-numbers)
  (require-number first-number "MIN")
  (dolist (argument more-numbers)
    (require-number argument "MIN"))
  (arithmetic-result (apply #'min first-number more-numbers)))

(defun require-int32 (object operator-name)
  (unless (typep object '(signed-byte 32))
    (signal-builtin-argument-error
     :invalid-integer-argument
     operator-name
     "~A expects a 32-bit AutoLISP integer, got ~S."
     operator-name
     object))
  object)

(defun builtin-rem (first-number second-number)
  (handler-case
      (arithmetic-result
       (rem (require-int32 first-number "REM")
            (require-int32 second-number "REM")))
    (division-by-zero ()
      (signal-builtin-host-error
       :division-by-zero
       "REM"
       "Division by zero in REM."))))

(defun builtin-gcd (&rest arguments)
  (dolist (argument arguments)
    (require-int32 argument "GCD"))
  (arithmetic-result
   (if arguments
       (apply #'gcd arguments)
       0)))

(defun builtin-lcm (&rest arguments)
  (dolist (argument arguments)
    (require-int32 argument "LCM"))
  (arithmetic-result
   (if arguments
       (apply #'lcm arguments)
       1)))

(defun builtin-~ (object)
  (arithmetic-result (lognot (require-int32 object "~"))))

(defun builtin-logand (first-integer &rest more-integers)
  (require-int32 first-integer "LOGAND")
  (dolist (argument more-integers)
    (require-int32 argument "LOGAND"))
  (arithmetic-result (apply #'logand first-integer more-integers)))

(defun builtin-logior (first-integer &rest more-integers)
  (require-int32 first-integer "LOGIOR")
  (dolist (argument more-integers)
    (require-int32 argument "LOGIOR"))
  (arithmetic-result (apply #'logior first-integer more-integers)))

(defun builtin-lsh (integer count)
  (arithmetic-result
   (ash (require-int32 integer "LSH")
        (require-int32 count "LSH"))))

(defun builtin-strcat (&rest strings)
  (make-autolisp-string
   (apply #'concatenate 'string
          (mapcar (lambda (string)
                    (autolisp-string-value
                     (require-string string "STRCAT")))
                  strings))))

(defun builtin-strlen (&rest strings)
  (let ((total 0))
    (dolist (string strings total)
      (incf total
            (length (autolisp-string-value
                     (require-string string "STRLEN")))))))

(defun builtin-substr (string start &optional length)
  (let* ((value (autolisp-string-value (require-string string "SUBSTR")))
         (start-value (require-int32 start "SUBSTR")))
    (when (<= start-value 0)
      (signal-builtin-argument-error
       :invalid-substr-start
       "SUBSTR"
       "SUBSTR expects a positive 1-based start index, got ~S."
       start))
    (when (and length (< (require-int32 length "SUBSTR") 0))
      ;; AutoLISP allows length 0 — returns the empty string —
      ;; matching vendor AutoCAD / BricsCAD behaviour. Only a
      ;; strictly negative length is an error. SCHMS+'s PK+PM
      ;; validator and cont_num/schms_separer pass a computed
      ;; length of 0 to substr; see
      ;; issues/closed/strict-dialect-autolisp-divergences.issue §3.
      (signal-builtin-argument-error
       :invalid-substr-length
       "SUBSTR"
       "SUBSTR length must be non-negative, got ~S."
       length))
    (let ((start-index (1- start-value)))
      (if (>= start-index (length value))
          (make-autolisp-string "")
          (let ((end-index (if length
                               (min (length value)
                                    (+ start-index length))
                               (length value))))
            (make-autolisp-string (subseq value start-index end-index)))))))

(defun builtin-strcase (string &optional lowercase-p)
  ;; (strcase STR [downcase-flag])
  ;; Default upcases; non-nil flag downcases.
  (let ((value (autolisp-string-value (require-string string "STRCASE"))))
    (make-autolisp-string
     (if lowercase-p
         (string-downcase value)
         (string-upcase value)))))

(defun string-trim-set (string-arg operator-name)
  ;; AutoLISP's vl-string-trim et al. take a string of characters,
  ;; each of which is trimmed. Coerce the AutoLISP string into a
  ;; CL list of host characters.
  (let ((value (autolisp-string-value (require-string string-arg operator-name))))
    (coerce value 'list)))

(defun builtin-vl-string-trim (chars-string source-string)
  (let ((chars (string-trim-set chars-string "VL-STRING-TRIM"))
        (value (autolisp-string-value
                (require-string source-string "VL-STRING-TRIM"))))
    (make-autolisp-string (string-trim chars value))))

(defun builtin-vl-string-left-trim (chars-string source-string)
  (let ((chars (string-trim-set chars-string "VL-STRING-LEFT-TRIM"))
        (value (autolisp-string-value
                (require-string source-string "VL-STRING-LEFT-TRIM"))))
    (make-autolisp-string (string-left-trim chars value))))

(defun builtin-vl-string-right-trim (chars-string source-string)
  (let ((chars (string-trim-set chars-string "VL-STRING-RIGHT-TRIM"))
        (value (autolisp-string-value
                (require-string source-string "VL-STRING-RIGHT-TRIM"))))
    (make-autolisp-string (string-right-trim chars value))))

(defun builtin-vl-string-search (pattern source &optional start)
  ;; (vl-string-search PATTERN STRING [START])
  ;; Returns the 0-based index of the first occurrence of PATTERN in
  ;; STRING at or after START (default 0), or nil if not found.
  (let ((p (autolisp-string-value (require-string pattern "VL-STRING-SEARCH")))
        (s (autolisp-string-value (require-string source "VL-STRING-SEARCH")))
        (s0 (if start (require-int32 start "VL-STRING-SEARCH") 0)))
    (when (minusp s0)
      (signal-builtin-argument-error
       :invalid-string-position
       "VL-STRING-SEARCH"
       "VL-STRING-SEARCH start must be non-negative, got ~S."
       start))
    (search p s :start2 (min s0 (length s)))))

(defun builtin-vl-string-position (char-code source &optional start from-right)
  ;; (vl-string-position CODE STRING [START [FROM-END]])
  ;; CODE is an integer character code; returns the 0-based position
  ;; of the first matching character, or nil.
  (let* ((code (require-int32 char-code "VL-STRING-POSITION"))
         (target (code-char code))
         (s (autolisp-string-value (require-string source "VL-STRING-POSITION"))))
    (unless target
      (signal-builtin-argument-error
       :invalid-character-code
       "VL-STRING-POSITION"
       "VL-STRING-POSITION code does not designate a character: ~S."
       char-code))
    (let ((s0 (if start (require-int32 start "VL-STRING-POSITION") 0)))
      (when (minusp s0)
        (signal-builtin-argument-error
         :invalid-string-position
         "VL-STRING-POSITION"
         "VL-STRING-POSITION start must be non-negative, got ~S."
         start))
      (if from-right
          (position target s :from-end t :start (min s0 (length s)))
          (position target s :start (min s0 (length s)))))))

(defun builtin-vl-string-translate (from-string to-string source)
  ;; (vl-string-translate FROM TO STRING)
  ;; Replace each character of STRING that occurs in FROM with the
  ;; character at the same position in TO. If TO is shorter than
  ;; FROM, the extra FROM characters are deleted.
  (let ((from (autolisp-string-value (require-string from-string "VL-STRING-TRANSLATE")))
        (to (autolisp-string-value (require-string to-string "VL-STRING-TRANSLATE")))
        (s (autolisp-string-value (require-string source "VL-STRING-TRANSLATE"))))
    (make-autolisp-string
     (with-output-to-string (out)
       (loop for c across s
             for at = (position c from)
             do (cond
                  ((null at) (write-char c out))
                  ((< at (length to)) (write-char (char to at) out))
                  ;; FROM character with no counterpart in TO is dropped.
                  (t nil)))))))

(defun builtin-vl-string-split (separator source)
  ;; (vl-string-split SEPARATOR STRING) -> list of strings.
  ;; Splits STRING on each character of SEPARATOR, in the spirit of
  ;; BricsCAD's vl-string-split (and the ad-hoc string-split alias
  ;; used by some scripts). Empty SEPARATOR returns the source as a
  ;; single-element list.
  (let* ((sep (autolisp-string-value
               (require-string separator "VL-STRING-SPLIT")))
         (s (autolisp-string-value (require-string source "VL-STRING-SPLIT")))
         (sep-chars (coerce sep 'list))
         (parts (cond
                  ((null sep-chars) (list s))
                  (t (loop with start = 0
                           with result = '()
                           for i from 0 below (length s)
                           when (member (char s i) sep-chars)
                             do (push (subseq s start i) result)
                                (setf start (1+ i))
                           finally (push (subseq s start) result)
                                   (return (nreverse result)))))))
    (mapcar #'make-autolisp-string parts)))

(defun builtin-vl-string-subst (new-string old-string source &optional start)
  ;; (vl-string-subst NEW OLD STRING [START])
  ;; Replace the FIRST occurrence of OLD with NEW. If OLD does not
  ;; occur, return STRING unchanged.
  (let ((new (autolisp-string-value (require-string new-string "VL-STRING-SUBST")))
        (old (autolisp-string-value (require-string old-string "VL-STRING-SUBST")))
        (s (autolisp-string-value (require-string source "VL-STRING-SUBST"))))
    (let* ((s0 (if start (require-int32 start "VL-STRING-SUBST") 0))
           (clamped-start (max 0 (min s0 (length s))))
           (hit (search old s :start2 clamped-start)))
      (if hit
          (make-autolisp-string
           (concatenate 'string
                        (subseq s 0 hit)
                        new
                        (subseq s (+ hit (length old)))))
          (make-autolisp-string s)))))

(defun builtin-vl-string-mismatch (a b)
  ;; (vl-string-mismatch S1 S2) -> integer count of leading matching characters.
  (let ((sa (autolisp-string-value (require-string a "VL-STRING-MISMATCH")))
        (sb (autolisp-string-value (require-string b "VL-STRING-MISMATCH"))))
    (loop for i below (min (length sa) (length sb))
          while (char= (char sa i) (char sb i))
          count 1)))

(defun builtin-vl-string-elt (string index)
  ;; (vl-string-elt STR I) -> character code at 0-based index.
  (let ((s (autolisp-string-value (require-string string "VL-STRING-ELT")))
        (i (require-int32 index "VL-STRING-ELT")))
    (when (or (minusp i) (>= i (length s)))
      (signal-builtin-argument-error
       :invalid-string-index
       "VL-STRING-ELT"
       "VL-STRING-ELT index ~S is out of range for a string of length ~A."
       index (length s)))
    (char-code (char s i))))

(defun builtin-vl-string->list (string)
  (let ((s (autolisp-string-value (require-string string "VL-STRING->LIST"))))
    (loop for c across s collect (char-code c))))

(defun builtin-vl-list->string (codes)
  ;; (vl-list->string LIST-OF-INTS) -> string built from those codes.
  (unless (listp codes)
    (signal-builtin-argument-error
     :invalid-list-argument
     "VL-LIST->STRING"
     "VL-LIST->STRING expects a list of integers, got ~S."
     codes))
  (make-autolisp-string
   (with-output-to-string (out)
     (dolist (code codes)
       (let ((int (require-int32 code "VL-LIST->STRING")))
         (unless (and (<= 0 int) (code-char int))
           (signal-builtin-argument-error
            :invalid-character-code
            "VL-LIST->STRING"
            "VL-LIST->STRING element ~S is not a valid character code."
            code))
         (write-char (code-char int) out))))))

(defun builtin-ascii (string)
  (let ((value (autolisp-string-value (require-string string "ASCII"))))
    (when (zerop (length value))
      (signal-builtin-argument-error
       :invalid-empty-string
       "ASCII"
       "ASCII expects a non-empty string."))
    (char-code (char value 0))))

(defun int32->character (code operator-name)
  (let ((int32 (require-int32 code operator-name)))
    (when (minusp int32)
      (signal-builtin-argument-error
       :invalid-character-code
       operator-name
       "~A code does not designate a valid character: ~S."
       operator-name
       code))
    (let ((character (code-char int32)))
      (unless character
        (signal-builtin-argument-error
         :invalid-character-code
         operator-name
         "~A code does not designate a valid character: ~S."
         operator-name
         code))
      character)))

(defun builtin-chr (code)
  (make-autolisp-string
   (string (int32->character code "CHR"))))

(defun open-default-external-format ()
  "Resolve the default file encoding for `open` when no explicit
per-open encoding argument (or BricsCAD ,ccs= suffix) is supplied.
Precedence mirrors the input/LOAD path (autolisp-runtime
AUTOLISP-LOAD-FILE-IN-CONTEXT) so a value written and read back
under the same encoding round-trips:

  1. the AutoLISP-level *AUTOLISP-FILE-ENCODING* global (settable at
     runtime, also seeded from the CLI -e flag), via
     LOOKUP-AUTOLISP-FILE-ENCODING;
  2. else the active dialect's default file encoding;
  3. else :iso-8859-1 (the historic ANSI/MBCS legacy default) when no
     dialect is in scope.

Before this consulted only tiers 2-3, so OPEN-for-write ignored
*AUTOLISP-FILE-ENCODING* / -e and always wrote ANSI bytes while the
read path honoured them — see open-write-ignores-file-encoding.issue."
  (let ((dialect (ignore-errors (current-evaluation-dialect))))
    (or (ignore-errors (clautolisp.autolisp-runtime:lookup-autolisp-file-encoding))
        (and dialect
             (clautolisp.autolisp-reader:autolisp-dialect-default-file-encoding
              dialect))
        :iso-8859-1)))

(defun %split-bricscad-mode-suffix (mode-string)
  "Parse BricsCAD's `,ccs=ENC' mode-suffix syntax from a MODE
argument to OPEN. Returns (values BASE-MODE CCS-ENCODING-STRING)
where:

- BASE-MODE is the mode-string with the `,ccs=' segment stripped
  (e.g. \"r,ccs=UTF-8\" -> \"r\").
- CCS-ENCODING-STRING is the encoding name from the suffix as a
  CL string, or nil when no suffix is present.

The BricsCAD spec accepts only `,ccs=ENC' at the tail (after the
mode letter), not arbitrary parameter ordering, so we look at the
last comma. encoding-dispatch.issue, section 'Per-dialect behavior
/ --bricscad'."
  (let ((comma-pos (position #\, mode-string :from-end t)))
    ;; COND truth-tests only consume the primary value, so a `(values
    ;; ... ...)` inside a cond clause would silently drop the
    ;; secondary value. Use a nested IF that returns the VALUES form
    ;; in tail position from the outer DEFUN so multiple-value-bind
    ;; in the caller sees both values.
    (if comma-pos
        (let ((tail (subseq mode-string (1+ comma-pos))))
          (if (and (>= (length tail) 4)
                   (string-equal "ccs=" tail :end2 4))
              (values (subseq mode-string 0 comma-pos)
                      (subseq tail 4))
              (values mode-string nil)))
        (values mode-string nil))))

(defun %autocad-encoding-literal-p (s)
  "True when S is one of the AutoCAD 2021+ third-argument literals
\"utf8\" or \"utf8-bom\" (case-insensitive). Used by the dispatcher
to route a positional encoding to the AutoCAD native form rather
than the clautolisp form when running under --autocad."
  (and (stringp s)
       (or (string-equal s "utf8")
           (string-equal s "utf8-bom"))))

(defun %autocad-supports-encoding-p (encoding-string)
  "True when AutoCAD can natively express ENCODING-STRING (a
clautolisp-canonical or AutoCAD-literal name). AutoCAD's third-arg
OPEN extension supports UTF-8 only; UTF-16 / UTF-32 are not
expressible. Used by %CHECK-OPEN-ENCODING-SUPPORTED to fire
ENC-UNSUPPORTED-TARGET under --autocad."
  (and (stringp encoding-string)
       (or (string-equal encoding-string "utf8")
           (string-equal encoding-string "utf8-bom")
           (string-equal encoding-string "UTF-8")
           (string-equal encoding-string "UTF-8-BOM")
           (string-equal encoding-string "ANSI")
           (string-equal encoding-string "MBCS")
           (string-equal encoding-string "US-ASCII")
           (string-equal encoding-string "ASCII")
           (and (>= (length encoding-string) 3)
                (string-equal "CP-" encoding-string :end2 3)))))

(defun %check-open-encoding-supported (encoding-string operator-name)
  "Emit ENC-UNSUPPORTED-TARGET when:

- The active dialect's vendor runtime can't natively express
  ENCODING-STRING (e.g. UTF-16 under --autocad: the AutoCAD runtime
  simply does not provide a UTF-16 reader), or
- The host CL implementation does not ship the corresponding
  external-format (e.g. CP-936 on a stripped SBCL build).

Informational — the runtime still attempts the open; downstream
errors are the user's signal that the encoding is actually wrong."
  (when encoding-string
    (let* ((dialect (current-evaluation-dialect))
           (name (clautolisp.autolisp-reader:autolisp-dialect-name dialect)))
      ;; Dialect-level check: AutoCAD doesn't express UTF-16 / UTF-32.
      (when (and (eq name :autocad-2026)
                 (not (%autocad-supports-encoding-p encoding-string)))
        (clautolisp.autolisp-runtime:signal-encoding-diagnostic
         :enc-unsupported-target
         "~A: encoding ~S has no AutoCAD-native expression (UTF-16 / UTF-32 are not in scope)."
         operator-name encoding-string))
      ;; Host-CL probe: catches CP-NNNN values the impl doesn't ship.
      (let* ((kw (handler-case
                     (parse-open-external-format encoding-string)
                   (error () nil))))
        (when (and kw
                   (keywordp kw)
                   (not (%host-cl-supports-encoding-p kw)))
          (clautolisp.autolisp-runtime:signal-encoding-diagnostic
           :enc-unsupported-target
           "~A: encoding ~S (~S) is not available on the running CL implementation."
           operator-name encoding-string kw))))))

(defun %check-open-host-dependent-write (encoding-string direction operator-name)
  "Emit ENC-HOST-DEPENDENT (info-level) when ENCODING-STRING resolves
to ANSI in a write context. ANSI's actual byte mapping depends on
the host's SYSCODEPAGE, so writing under ANSI yields output that
varies host-to-host — non-reproducible. Reading is fine; only
write triggers the lint."
  (when (and encoding-string
             (eq direction :output)
             (or (string-equal encoding-string "ANSI")
                 (string-equal encoding-string "MBCS")))
    (clautolisp.autolisp-runtime:signal-encoding-diagnostic
     :enc-host-dependent
     "~A: writing under ~S resolves to the host's SYSCODEPAGE at I/O time; output is not portable across hosts. Use ~S or an explicit CP-NNNN for reproducibility."
     operator-name encoding-string "CP-1252")))

(defun %dispatch-open-encoding-diagnostic (form value-string)
  "Emit the encoding-dispatch.issue diagnostic appropriate for an
OPEN call using FORM, where FORM is one of:

  :positional-autocad    third arg is \"utf8\" / \"utf8-bom\"
  :positional-clautolisp third arg is the broader clautolisp set
  :ccs-suffix            mode-string carries \",ccs=ENC\"

Per-dialect dispatch matrix (encoding-dispatch.issue, section
'Dialect matrix'):

| Dialect    | positional-autocad | positional-clautolisp | ccs-suffix |
|------------+---------------------+-----------------------+------------|
| --autocad  | accept              | foreign-dialect       | foreign    |
| --bricscad | foreign-dialect     | foreign-dialect       | accept     |
| --clautolisp | foreign-dialect   | accept                | foreign    |
| --strict   | extension-used      | extension-used        | extension  |
"
  (let* ((dialect (current-evaluation-dialect))
         (name (clautolisp.autolisp-reader:autolisp-dialect-name dialect)))
    (flet ((foreign (sub-tag)
             (clautolisp.autolisp-runtime:signal-encoding-diagnostic
              :enc-foreign-dialect
              "OPEN ~A (~S) is a ~A extension; foreign to --~(~A~)."
              form value-string sub-tag
              (case name
                (:autocad-2026 "autocad")
                (:bricscad-v26 "bricscad")
                (:clautolisp   "clautolisp")
                (t name))))
           (extension (sub-tag)
             (clautolisp.autolisp-runtime:signal-encoding-diagnostic
              :enc-extension-used
              "OPEN ~A (~S) is a ~A extension; --strict reports every encoding extension."
              form value-string sub-tag)))
      (case name
        (:autocad-2026
         (case form
           (:positional-autocad    nil)
           (:positional-clautolisp (foreign "clautolisp-positional"))
           (:ccs-suffix            (foreign "bricscad-ccs"))))
        (:bricscad-v26
         (case form
           (:positional-autocad    (foreign "autocad-positional"))
           (:positional-clautolisp (foreign "clautolisp-positional"))
           (:ccs-suffix            nil)))
        (:clautolisp
         (case form
           (:positional-autocad    (foreign "autocad-positional"))
           (:positional-clautolisp nil)
           (:ccs-suffix            (foreign "bricscad-ccs"))))
        (:strict
         (case form
           (:positional-autocad    (extension "autocad-positional"))
           (:positional-clautolisp (extension "clautolisp-positional"))
           (:ccs-suffix            (extension "bricscad-ccs"))))
        (t nil)))))

(defun builtin-open (filename mode &optional encoding)
  ;; Documented to set ERRNO on failure (autolisp-spec §16 ERRNO
  ;; :coupled). Autodesk's enumerated code-set has no dedicated
  ;; "file not found" / "cannot open" value for OPEN; we use 22
  ;; (Value out of range) as the catch-all "argument rejected by
  ;; the host" code that the AutoLISP corpus already observes.
  ;;
  ;; Three sources of encoding selection, in precedence order:
  ;;   1. The third positional ENCODING argument (clautolisp /
  ;;      AutoCAD form).
  ;;   2. The BricsCAD ,ccs=ENC mode-suffix.
  ;;   3. The dialect default.
  ;; A diagnostic is emitted for each foreign-dialect form via
  ;; %DISPATCH-OPEN-ENCODING-DIAGNOSTIC; the runtime still honours
  ;; the encoding (user code stays runnable across dialects).
  (let* ((path-string (autolisp-string-value (require-string filename "OPEN")))
         (raw-mode-string (autolisp-string-value (require-string mode "OPEN")))
         (path (resolve-open-search-pathname path-string))
         (encoding-string (when encoding
                            (autolisp-string-value
                             (require-string encoding "OPEN"))))
         (external-format nil))
    (multiple-value-bind (mode-string ccs-encoding-string)
        (%split-bricscad-mode-suffix raw-mode-string)
      (when ccs-encoding-string
        (%dispatch-open-encoding-diagnostic :ccs-suffix ccs-encoding-string))
      (when encoding-string
        (%dispatch-open-encoding-diagnostic
         (if (%autocad-encoding-literal-p encoding-string)
             :positional-autocad
             :positional-clautolisp)
         encoding-string))
      ;; ENC-UNSUPPORTED-TARGET — encoding is foreign to the host's
      ;; expressive range (e.g. UTF-16 under --autocad).
      (let ((effective-encoding-string
             (or encoding-string ccs-encoding-string)))
        (when effective-encoding-string
          (%check-open-encoding-supported effective-encoding-string "OPEN")))
      (setf external-format
            (cond
              ;; Positional wins over CCS when both supplied — more
              ;; explicit form. Document for users via the
              ;; foreign-dialect diagnostic the ccs= already emitted.
              (encoding-string
               (parse-open-external-format encoding-string))
              (ccs-encoding-string
               (parse-open-external-format ccs-encoding-string))
              (t (open-default-external-format))))
      (multiple-value-bind (direction if-exists if-does-not-exist)
          (open-direction-and-options mode-string)
        ;; ENC-HOST-DEPENDENT — writing under ANSI / MBCS yields
        ;; host-dependent output. Read paths are silent.
        (let ((effective-encoding-string
               (or encoding-string ccs-encoding-string)))
          (when effective-encoding-string
            (%check-open-host-dependent-write
             effective-encoding-string direction "OPEN")))
        ;; SECURELOAD gate: OPEN is not gated by Autodesk, but pjb
        ;; directs clautolisp to gate it for files whose extension is in
        ;; the gated set (a .lsp etc. can be read then evaluated). Only
        ;; gated extensions are affected; ordinary data files are not.
        (when (secureload-gated-extension-p path-string)
          (when (eq :block (%secureload-guard (namestring path)
                                              "OPEN" :sec-untrusted-open))
            (return-from builtin-open
              (call-with-autolisp-error-handler
               (lambda ()
                 (set-autolisp-errno 22)
                 (signal-builtin-host-error
                  :open-untrusted-file
                  "OPEN"
                  "OPEN blocked: ~A is a gated file in an untrusted ~
location (SECURELOAD=2). Add its folder to TRUSTEDPATHS to trust it."
                  path-string))))))
        (handler-case
            (let ((stream (open path
                                :direction direction
                                :if-exists if-exists
                                :if-does-not-exist if-does-not-exist
                                :external-format external-format)))
              (if stream
                  (errno-and-return 0 (make-autolisp-file stream path-string raw-mode-string))
                  (errno-and-return 22 nil)))
          (error ()
            (errno-and-return 22 nil)))))))

(defun resolve-existing-file (filename support-paths)
  ;; AutoLISP's `findfile` and `findtrustedfile` accept both absolute
  ;; and relative paths. Absolute paths are looked up directly via
  ;; probe-file; relative paths walk the configured support / trusted
  ;; path list.
  (let ((normalized (normalize-path-string filename)))
    (cond
      ((directory-prefix-p normalized)
       (let* ((path (if (absolute-path-string-p normalized)
                        (pathname normalized)
                        (merge-pathnames normalized
                                         (pathname (autolisp-current-directory)))))
              (located (probe-file path)))
         (and located (namestring located))))
      (t
       (search-path-list-for-file filename support-paths)))))

(defun builtin-findfile (filename)
  ;; FINDFILE searches the UNION of the support path and the trusted
  ;; paths, without filtering by trust (secureload trust model spec
  ;; § 'Which functions are gated'). Documented to set ERRNO on failure;
  ;; no dedicated code, so 22 (Value out of range) as for OPEN.
  (let* ((value (autolisp-string-value (require-string filename "FINDFILE")))
         (search-dirs (append (%effective-support-dirs)
                              (%secureload-trusted-dirs)))
         (located (resolve-existing-file value search-dirs)))
    (if located
        (errno-and-return 0 (make-autolisp-string located))
        (errno-and-return 22 nil))))

(defun builtin-findtrustedfile (filename)
  ;; FINDTRUSTEDFILE returns a file only when it is in a TRUSTED location
  ;; (TRUSTEDPATHS u the implicit folders) — the trusted-only intersection
  ;; (secureload trust model spec). Same ERRNO contract as FINDFILE.
  (let* ((value (autolisp-string-value (require-string filename "FINDTRUSTEDFILE")))
         (located (resolve-existing-file value (%secureload-trusted-dirs))))
    (if located
        (errno-and-return 0 (make-autolisp-string located))
        (errno-and-return 22 nil))))

(defun builtin-vl-directory-files (&optional directory pattern directories)
  (let* ((directory-value (if directory
                              (autolisp-string-value
                               (require-string directory "VL-DIRECTORY-FILES"))
                              (autolisp-current-directory)))
         (pattern-value (if pattern
                            (autolisp-string-value
                             (require-string pattern "VL-DIRECTORY-FILES"))
                            "*.*"))
         (resolved-directory (resolve-directory-pathname directory-value
                                                        "VL-DIRECTORY-FILES"))
         (selector (directory-selector-kind directories)))
    (handler-case
        (if (uiop:directory-exists-p resolved-directory)
            (let ((results (collect-directory-entries
                            resolved-directory
                            selector
                            (normalized-directory-pattern pattern-value))))
              (if results
                  results
                  nil))
            nil)
      (file-error ()
        nil))))

(defun builtin-vl-file-directory-p (filename)
  (let* ((value (autolisp-string-value
                 (require-string filename "VL-FILE-DIRECTORY-P")))
         (resolved (resolve-open-pathname value)))
    (if (uiop:directory-exists-p resolved)
        (intern-autolisp-symbol "T")
        nil)))

(defun builtin-vl-filename-base (filename)
  (multiple-value-bind (directory leaf dot-position)
      (split-filename-components
       (autolisp-string-value
        (require-string filename "VL-FILENAME-BASE")))
    (declare (ignore directory))
    (make-autolisp-string
     (if dot-position
         (subseq leaf 0 dot-position)
         leaf))))

(defun builtin-vl-filename-directory (filename)
  (multiple-value-bind (directory leaf dot-position)
      (split-filename-components
       (autolisp-string-value
        (require-string filename "VL-FILENAME-DIRECTORY")))
    (declare (ignore leaf dot-position))
    (make-autolisp-string directory)))

(defun builtin-vl-filename-extension (filename)
  (multiple-value-bind (directory leaf dot-position)
      (split-filename-components
       (autolisp-string-value
        (require-string filename "VL-FILENAME-EXTENSION")))
    (declare (ignore directory))
    (if dot-position
        (make-autolisp-string (subseq leaf dot-position))
        nil)))

(defun builtin-vl-file-delete (filename)
  (let* ((value (autolisp-string-value
                 (require-string filename "VL-FILE-DELETE")))
         (resolved (resolve-open-pathname value)))
    (handler-case
        (progn
          (delete-file resolved)
          (intern-autolisp-symbol "T"))
      (file-error ()
        nil))))

(defun builtin-vl-file-rename (old-filename new-filename)
  (let* ((old-value (autolisp-string-value
                     (require-string old-filename "VL-FILE-RENAME")))
         (new-value (autolisp-string-value
                     (require-string new-filename "VL-FILE-RENAME")))
         (old-path (resolve-open-pathname old-value))
         (new-path (resolve-open-pathname new-value)))
    (handler-case
        (if (probe-file new-path)
            nil
            (progn
              (rename-file old-path new-path)
              (intern-autolisp-symbol "T")))
      (file-error ()
        nil))))

(defun builtin-vl-file-size (filename)
  (let* ((value (autolisp-string-value
                 (require-string filename "VL-FILE-SIZE")))
         (resolved (resolve-open-pathname value)))
    (cond
      ((uiop:directory-exists-p resolved)
       0)
      ((not (probe-file resolved))
       nil)
      (t
       (handler-case
           (with-open-file (stream resolved
                                   :direction :input
                                   :element-type '(unsigned-byte 8))
             (file-length stream))
         (file-error ()
           nil))))))

(defun autolisp-day-of-week (common-lisp-day-of-week)
  ;; CL uses Monday=0..Sunday=6. AutoLISP compatibility is modeled here as
  ;; Sunday=0..Saturday=6, matching common host file-time conventions.
  (mod (1+ common-lisp-day-of-week) 7))

(defun builtin-vl-file-systime (filename)
  (let* ((value (autolisp-string-value
                 (require-string filename "VL-FILE-SYSTIME")))
         (resolved (resolve-open-pathname value))
         (write-date (ignore-errors (file-write-date resolved))))
    (if write-date
        (multiple-value-bind (second minute hour day month year day-of-week)
            (decode-universal-time write-date)
          (list year month (autolisp-day-of-week day-of-week) day hour minute second))
        nil)))

(defun copy-stream-contents (input output)
  (let ((buffer (make-array 4096 :element-type '(unsigned-byte 8)))
        (total 0))
    (loop
      for count = (read-sequence buffer input)
      until (zerop count)
      do (write-sequence buffer output :end count)
         (incf total count))
    total))

(defun builtin-vl-file-copy (source-filename destination-filename &optional append)
  (let* ((source-value (autolisp-string-value
                        (require-string source-filename "VL-FILE-COPY")))
         (destination-value (autolisp-string-value
                             (require-string destination-filename "VL-FILE-COPY")))
         (source-path (resolve-open-pathname source-value))
         (destination-path (resolve-open-pathname destination-value)))
    (cond
      ((or (uiop:directory-exists-p source-path)
           (not (probe-file source-path)))
       nil)
      ((uiop:directory-exists-p destination-path)
       nil)
      ((and (null append) (probe-file destination-path))
       nil)
      (t
       (handler-case
           (with-open-file (input source-path
                                  :direction :input
                                  :element-type '(unsigned-byte 8))
             (with-open-file (output destination-path
                                     :direction :output
                                     :element-type '(unsigned-byte 8)
                                     :if-exists (if append :append :error)
                                     :if-does-not-exist :create)
               (copy-stream-contents input output)))
         (file-error ()
           nil))))))

(defun normalize-mktemp-extension (extension)
  (cond
    ((null extension)
     "")
    ((zerop (length extension))
     "")
    ((char= #\. (char extension 0))
     extension)
    (t
     (concatenate 'string "." extension))))

(defun unique-temp-pathname (directory pattern extension)
  (loop
    for attempt from 0
    for suffix = (format nil "~36R-~36R" (get-universal-time) attempt)
    for leaf = (format nil "~A~A~A" pattern suffix extension)
    for candidate = (merge-pathnames leaf directory)
    unless (probe-file candidate)
      do (return candidate)))

(defun default-mktemp-directory ()
  (namestring (uiop:temporary-directory)))

(defun builtin-vl-filename-mktemp (&optional pattern directory extension)
  (let* ((pattern-value (if pattern
                            (autolisp-string-value
                             (require-string pattern "VL-FILENAME-MKTEMP"))
                            "tmp"))
         (directory-value (if directory
                              (autolisp-string-value
                               (require-string directory "VL-FILENAME-MKTEMP"))
                              (default-mktemp-directory)))
         (extension-value (if extension
                              (autolisp-string-value
                               (require-string extension "VL-FILENAME-MKTEMP"))
                              ""))
         (resolved-directory (resolve-directory-pathname directory-value
                                                        "VL-FILENAME-MKTEMP"))
         (candidate (unique-temp-pathname resolved-directory
                                          pattern-value
                                          (normalize-mktemp-extension
                                           extension-value))))
    (make-autolisp-string (namestring candidate))))

(defun builtin-vl-mkdir (directoryname)
  (let* ((value (autolisp-string-value
                 (require-string directoryname "VL-MKDIR")))
         (resolved (resolve-directory-pathname value "VL-MKDIR")))
    (if (uiop:directory-exists-p resolved)
        nil
        (handler-case
            (progn
              (ensure-directories-exist resolved)
              (if (uiop:directory-exists-p resolved)
                  (intern-autolisp-symbol "T")
                  nil))
          (file-error ()
            nil)))))

(defun builtin-close (file)
  (close-autolisp-file (require-file file "CLOSE")))

(defun builtin-read (string)
  (handler-case
      (autolisp-read-from-string
       (autolisp-string-value (require-string string "READ")))
    (autolisp-runtime-error (condition)
      (error 'autolisp-runtime-error
             :code :invalid-read-syntax
             :message (format nil "READ failed to parse input: ~A" condition)
             :details (list :builtin "READ"
                            :condition condition)
             :call-stack (current-autolisp-call-stack)))
    (error (condition)
      (error 'autolisp-runtime-error
             :code :invalid-read-syntax
             :message (format nil "READ failed to parse input: ~A" condition)
             :details (list :builtin "READ"
                            :condition condition)
             :call-stack (current-autolisp-call-stack)))))

(defun builtin-read-line (&optional file)
  ;; AutoLISP `(read-line [file-desc])`: the file descriptor is
  ;; OPTIONAL — when omitted, input comes from the keyboard buffer
  ;; (here *standard-input*), mirroring `read-char`. Documented to set
  ;; ERRNO on failure. EOF is the canonical failure path; we use 8
  ;; ("End of entity file") which is the nearest documented value in
  ;; the enumerated set.
  (let ((stream (if file
                    (require-open-file-stream file "READ-LINE")
                    *standard-input*)))
    (let ((line (read-line stream nil nil)))
      (if line
          (errno-and-return 0 (make-autolisp-string line))
          (errno-and-return 8 nil)))))

(defun builtin-read-char (&optional file)
  (if file
      (let ((stream (require-open-file-stream file "READ-CHAR")))
        (let ((character (read-char stream nil nil)))
          (if character
              (char-code character)
              nil)))
      (let ((character (read-char *standard-input* nil nil)))
        (if character
            (char-code character)
            nil))))

(defun builtin-write-line (string &optional file)
  ;; Documented to set ERRNO on failure. Success path resets to 0.
  ;; We don't currently surface a write-error case here; the host
  ;; CL ~write-line~ either succeeds or signals, which the
  ;; wrap-builtin-function harness converts into a runtime error
  ;; before the user sees nil.
  (let ((value (autolisp-string-value (require-string string "WRITE-LINE"))))
    (if file
        (let ((stream (require-open-file-stream file "WRITE-LINE")))
          (write-line value stream)
          (errno-and-return 0 string))
        (progn
          (write-line value *standard-output*)
          (errno-and-return 0 string)))))

(defun builtin-write-char (char-code &optional file)
  (let ((character (int32->character char-code "WRITE-CHAR")))
    (if file
        (let ((stream (require-open-file-stream file "WRITE-CHAR")))
          (write-char character stream)
          char-code)
        (progn
          (write-char character *standard-output*)
          char-code))))

;; --- atoi / atof (Phase-5 product-tested model) ----------------------
;;
;; Lex model derived from the BricsCAD V26 product test on 2026-04-26
;; (results captured in autolisp-spec/results/bricscad/macos/
;; 20260426T122808Z/results.sexp):
;;
;; * skip leading whitespace
;; * accept optional `+` or `-`
;; * parse the longest run of decimal digits (atoi) or
;;   `digits ('.' digits?)? (('e'|'E') [+-]? digits)?` (atof)
;; * a trailing non-numeric tail terminates parsing; the value of the
;;   prefix (or 0 / 0.0 if no digits matched) is returned.
;;
;; For atof we deliberately *omit* the C99 hex-float syntax accepted
;; by BricsCAD V26 (e.g. `(atof "0x1p4") -> 16.0`). This is the
;; conservative `clautolisp` choice spelled out in the autolisp-spec
;; entry for ATOF: portable AutoLISP code should not rely on hex-float
;; input. Locale sensitivity is also intentionally absent: the decimal
;; separator is `.` only.

(defun atoi-skip-whitespace (string start)
  (loop while (and (< start (length string))
                   (member (char string start)
                           '(#\Space #\Tab #\Newline #\Return #\Page)
                           :test #'char=))
        do (incf start))
  start)

(defun atoi-scan-sign (string start)
  (cond
    ((>= start (length string)) (values 1 start))
    ((char= (char string start) #\+) (values 1 (1+ start)))
    ((char= (char string start) #\-) (values -1 (1+ start)))
    (t (values 1 start))))

(defun atoi-scan-digits (string start)
  "Returns (values numeric-value end-index) or (values nil start) on no digits."
  (let ((value 0)
        (i start))
    (loop while (and (< i (length string))
                     (digit-char-p (char string i)))
          do (setf value (+ (* value 10) (digit-char-p (char string i))))
             (incf i))
    (if (= i start) (values nil start) (values value i))))

(defun parse-autolisp-integer (string)
  "Parse STRING per the AutoLISP `atoi` lex model. Returns an int32."
  (let* ((start (atoi-skip-whitespace string 0)))
    (multiple-value-bind (sign signed-start) (atoi-scan-sign string start)
      (multiple-value-bind (value end) (atoi-scan-digits string signed-start)
        (declare (ignore end))
        (if (null value)
            0
            (* sign value))))))

(defun parse-autolisp-real (string)
  "Parse STRING per the AutoLISP `atof` lex model. Returns a double-float."
  (let* ((start (atoi-skip-whitespace string 0)))
    (multiple-value-bind (sign signed-start) (atoi-scan-sign string start)
      (multiple-value-bind (int-value int-end)
          (atoi-scan-digits string signed-start)
        ;; Optional fractional part: `.` followed by zero-or-more digits.
        (let* ((have-int int-value)
               (cursor (or int-end signed-start))
               (frac-numerator 0)
               (frac-denom 1)
               (have-frac nil))
          (when (and (< cursor (length string))
                     (char= (char string cursor) #\.))
            (incf cursor)
            (multiple-value-bind (fv fe) (atoi-scan-digits string cursor)
              (when fv
                (setf frac-numerator fv
                      frac-denom (expt 10 (- fe cursor))
                      have-frac t
                      cursor fe))))
          ;; Optional exponent: (e|E) optional sign, digits.
          (let ((exponent 0))
            (when (and (< cursor (length string))
                       (or (char= (char string cursor) #\e)
                           (char= (char string cursor) #\E)))
              (let ((ec (1+ cursor)))
                (multiple-value-bind (esign esigned-start)
                    (atoi-scan-sign string ec)
                  (multiple-value-bind (ev ee)
                      (atoi-scan-digits string esigned-start)
                    (when ev
                      (setf exponent (* esign ev)
                            cursor ee))))))
            (let* ((int-part (or have-int 0)))
              (cond
                ((and (null have-int) (null have-frac))
                 0.0d0)
                (t
                 (let* ((mantissa
                          (+ (coerce int-part 'double-float)
                             (/ (coerce frac-numerator 'double-float)
                                (coerce frac-denom 'double-float))))
                        (signed-mantissa (* sign mantissa))
                        (scaled (if (zerop exponent)
                                    signed-mantissa
                                    (* signed-mantissa
                                       (expt 10.0d0 exponent)))))
                   scaled))))))))))

(defun builtin-atoi (string)
  (parse-autolisp-integer (autolisp-string-value (require-string string "ATOI"))))

(defun builtin-atof (string)
  (parse-autolisp-real (autolisp-string-value (require-string string "ATOF"))))
;; --- end atoi / atof -------------------------------------------------

(defun escape-prin1-string (string)
  (with-output-to-string (out)
    (write-char #\" out)
    (loop for character across string
          do (case character
               (#\\
                (write-string "\\\\" out))
               (#\"
                (write-string "\\\"" out))
               (t
                (write-char character out))))
    (write-char #\" out)))

(defun autolisp-value->string (object princp)
  (cond
    ((null object)
     "nil")
    ((integerp object)
     (format nil "~D" object))
    ((floatp object)
     ;; AutoLISP reals print without the CL double-float marker
     ;; ("3.14", not "3.14d0"; "1.0e20", not "1.0d20"). Binding
     ;; *read-default-float-format* to double-float tells SBCL/CCL
     ;; the marker is redundant and they elide it — same printed
     ;; form vendor AutoLISP emits.
     (let ((*read-default-float-format* 'double-float))
       (princ-to-string object)))
    ((typep object 'autolisp-string)
     (if princp
         (autolisp-string-value object)
         (escape-prin1-string (autolisp-string-value object))))
    ((typep object 'autolisp-symbol)
     (autolisp-symbol-name object))
    ((typep object 'autolisp-subr)
     (format nil "#<SUBR ~A>" (autolisp-subr-name object)))
    ((typep object 'autolisp-usubr)
     (format nil "#<USUBR ~A>" (autolisp-usubr-name object)))
    ((typep object 'autolisp-ename)
     (format nil "<Entity name: ~A>" (autolisp-ename-value object)))
    ((typep object 'autolisp-vla-object)
     (format nil "#<VLA-OBJECT ~A>" (autolisp-vla-object-value object)))
    ((typep object 'autolisp-safearray)
     (let ((data (autolisp-safearray-value object)))
       (if (typep data 'safearray-data)
           (format nil "#<SAFEARRAY ~S ~S>"
                   (safearray-data-type-tag data)
                   (safearray-data-bounds data))
           (format nil "#<SAFEARRAY>"))))
    ((typep object 'autolisp-variant)
     (let ((pair (autolisp-variant-value object)))
       (if (consp pair)
           (format nil "#<VARIANT ~S ~S>" (car pair) (cdr pair))
           (format nil "#<VARIANT>"))))
    ((consp object)
     (with-output-to-string (out)
       (labels ((emit-tail (tail)
                  (cond
                    ((null tail)
                     nil)
                    ((consp tail)
                     (write-char #\Space out)
                     (write-string (autolisp-value->string (car tail) princp) out)
                     (emit-tail (cdr tail)))
                    (t
                     (write-string " . " out)
                     (write-string (autolisp-value->string tail princp) out)))))
         (write-char #\( out)
         (write-string (autolisp-value->string (car object) princp) out)
         (emit-tail (cdr object))
         (write-char #\) out))))
    (t
     (with-output-to-string (out)
       (write object :stream out :escape (not princp))))))

(defun output-stream-for-file (file operator-name)
  (if file
      (require-open-file-stream file operator-name)
      *standard-output*))

(defun builtin-vl-prin1-to-string (object)
  (make-autolisp-string (autolisp-value->string object nil)))

(defun builtin-vl-princ-to-string (object)
  (make-autolisp-string (autolisp-value->string object t)))

(defun builtin-prin1 (object &optional file)
  (write-string (autolisp-value->string object nil)
                (output-stream-for-file file "PRIN1"))
  object)

(defun builtin-princ (&optional object file)
  (when object
    (write-string (autolisp-value->string object t)
                  (output-stream-for-file file "PRINC")))
  object)

(defun builtin-print (object &optional file)
  ;; AutoLISP `print` is `prin1` with a leading newline AND a trailing
  ;; SPACE (not a trailing newline) — confirmed by the Phase-5 BricsCAD
  ;; V26 product test on 2026-04-26 (autolisp-spec/results/bricscad/
  ;; macos/20260426T122808Z/print-string.txt contains the literal nine
  ;; characters `\n"hello" `). Bricsys's per-symbol page documents the
  ;; framing as "adds a newline \n before expression and adds an extra
  ;; space afterwards".
  (let ((stream (output-stream-for-file file "PRINT")))
    (terpri stream)
    (write-string (autolisp-value->string object nil) stream)
    (write-char #\Space stream))
  object)

(defun %terpri-file-extension-allowed-p ()
  "True when the active dialect accepts the clautolisp `(terpri file)`
extension silently. AutoCAD 2026 and BricsCAD V26 both document
`terpri` as ZERO-ARITY and \"not used for file I/O\", so the optional
file handle is a clautolisp convenience; it is silent under
--clautolisp and the catch-all --lax dialect, and merely *warned*
(not rejected) under the other dialects."
  (let* ((dialect (ignore-errors (current-evaluation-dialect)))
         (name (and dialect
                    (clautolisp.autolisp-reader:autolisp-dialect-name dialect))))
    (and (member name '(:clautolisp :lax)) t)))

(defun emit-terpri-file-extension-warning ()
  "Emit a non-fatal out-of-dialect WARNING for `(terpri <file>)` under
a dialect that does not natively accept it. Mirrors the runtime's
`emit-lambda-list-extension-warning`: dialect problems are flagged,
never raised as errors (terpri.issue / alfe-clautolisp-dialect.issue
point 4). The newline is still written."
  (let* ((dialect (ignore-errors (current-evaluation-dialect)))
         (name (and dialect
                    (clautolisp.autolisp-reader:autolisp-dialect-name dialect))))
    (format *error-output*
            "~&[terpri-file-extension] `(terpri <file>)' is a clautolisp ~
extension; --dialect ~(~A~) flags it as non-portable (AutoCAD 2026 / ~
BricsCAD V26 `terpri' is command-line-only). Use (princ \"\\n\" <file>) ~
for a portable file newline, or --dialect clautolisp to silence.~%"
            (or name "default"))))

(defun builtin-terpri (&optional (file nil file-supplied-p))
  ;; AutoLISP `terpri` prints a newline. AutoCAD 2026 and BricsCAD V26
  ;; both document it as ZERO-ARITY and command-line-only: AutoCAD says
  ;; "the terpri function is not used for file I/O" (use prin1/princ/
  ;; print), and `(terpri stream)` raises "too few / too many arguments
  ;; at [TERPRI]" in BricsCAD V26 (Phase-5 product test, 2026-04-26).
  ;;
  ;; clautolisp extends `terpri` with an OPTIONAL file handle as a
  ;; convenience (so Common-Lisp-shaped `(terpri f)` code works). The
  ;; extension is silent under --clautolisp / --lax; under --strict /
  ;; --autocad / --bricscad it emits a non-fatal out-of-dialect WARNING
  ;; (dialect problems are warnings, never errors) and still writes the
  ;; newline. Portable file newlines use `(princ "\n" f)`.
  (when (and file-supplied-p (not (%terpri-file-extension-allowed-p)))
    (emit-terpri-file-extension-warning))
  (terpri (output-stream-for-file (and file-supplied-p file) "TERPRI"))
  nil)

(defun builtin-prompt (string)
  (let ((value (autolisp-string-value (require-string string "PROMPT"))))
    (write-string value *standard-output*)
    nil))

(defun comparison-value (object operator-name)
  (cond
    ((numberp object)
     object)
    ((typep object 'autolisp-string)
     (autolisp-string-value object))
    (t
     (signal-builtin-argument-error
      :invalid-comparison-argument
      operator-name
      "~A expects numbers or strings, got ~S."
      operator-name
      object))))

(defun comparison-equal-p (a b)
  ;; AutoLISP `=` accepts arguments of any type, not just the
  ;; numeric/string pair documented in early references — production
  ;; code routinely uses it to compare symbols and lists. Numeric
  ;; pairs compare across int/real (autolisp-spec ch. 5, "Equality
  ;; Predicates"); strings compare by content; everything else falls
  ;; back to host-level identity (eql), which matches `eq` semantics
  ;; for symbols and other interned objects.
  (cond
    ((eql a b) t)
    ((and (numberp a) (numberp b)) (= a b))
    ((and (typep a 'autolisp-string) (typep b 'autolisp-string))
     (string= (autolisp-string-value a) (autolisp-string-value b)))
    (t nil)))

(defun builtin-= (&rest arguments)
  (unless arguments
    (signal-builtin-argument-error
     :wrong-number-of-arguments
     "="
     "= expects at least one argument."))
  (let ((first-arg (first arguments)))
    (if (every (lambda (argument)
                 (comparison-equal-p first-arg argument))
               (rest arguments))
        (intern-autolisp-symbol "T")
        nil)))

(defun builtin-/= (&rest arguments)
  (unless arguments
    (signal-builtin-argument-error
     :wrong-number-of-arguments
     "/="
     "/= expects at least one argument."))
  ;; `/=` is true when no two arguments compare equal — pairwise.
  (loop for tail on arguments
        do (loop for other in (rest tail)
                 when (comparison-equal-p (first tail) other)
                   do (return-from builtin-/= nil))
        finally (return (intern-autolisp-symbol "T"))))

(defun require-number (object operator-name)
  (unless (numberp object)
    (signal-builtin-argument-error
     :invalid-number-argument
     operator-name
     "~A expects a number, got ~S."
     operator-name
     object))
  object)

(defun numeric-order-p (arguments predicate operator-name)
  (declare (ignore operator-name))
  ;; AutoLISP semantics (AutoCAD / BricsCAD): the relational
  ;; operators <, <=, >, >= fold a non-numeric argument (including
  ;; nil) to nil rather than signalling a type error. Loop-guard
  ;; idioms depend on it:
  ;;   (while (<= 48 (car chars) 57) ...)
  ;; where (car chars) becomes nil at end of list and the
  ;; comparison must yield nil to stop the loop. SCHMS+'s numeric
  ;; validators (validateur_reel / _naturel / _entier) rely on
  ;; exactly this shape — see
  ;; issues/closed/strict-dialect-autolisp-divergences.issue §2.
  (cond
    ((null arguments)
     (intern-autolisp-symbol "T"))
    ((not (every #'numberp arguments))
     nil)
    ((or (null (rest arguments))
         (loop for (left right) on arguments
               while right
               always (funcall predicate left right)))
     (intern-autolisp-symbol "T"))
    (t nil)))

(defun builtin-< (&rest arguments)
  (numeric-order-p arguments #'< "<"))

(defun builtin-<= (&rest arguments)
  (numeric-order-p arguments #'<= "<="))

(defun builtin-> (&rest arguments)
  (numeric-order-p arguments #'> ">"))

(defun builtin->= (&rest arguments)
  (numeric-order-p arguments #'>= ">="))

(defun builtin-abs (object)
  (abs (require-number object "ABS")))

(defun builtin-fix (object)
  (let ((value (truncate (require-number object "FIX"))))
    (unless (typep value '(signed-byte 32))
      (signal-builtin-argument-error
       :integer-overflow
       "FIX"
       "FIX result is outside the AutoLISP 32-bit integer range: ~S."
       value))
    value))

(defun builtin-float (object)
  (coerce (require-number object "FLOAT") 'double-float))

(defun builtin-zerop (object)
  (if (zerop (require-number object "ZEROP"))
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-minusp (object)
  (if (minusp (require-number object "MINUSP"))
      (intern-autolisp-symbol "T")
      nil))

;;; --- Phase 7: function-coverage round-out ---------------------------
;;;
;;; Pure-language builtins that don't touch the host. Each entry
;;; references the autolisp-spec chapter that defines it.

;;; ERROR — signal a runtime error from user code.
(defun builtin-error (message-or-string &rest details)
  ;; (error MESSAGE)        — common signature, signals a runtime error.
  ;; (error CODE FORMAT...) — Visual LISP variant; we accept it but
  ;; coerce non-symbol first arg into the message.
  (let ((message
         (cond
           ((typep message-or-string 'autolisp-string)
            (autolisp-string-value message-or-string))
           ((stringp message-or-string)
            message-or-string)
           ((typep message-or-string 'autolisp-symbol)
            (autolisp-symbol-name message-or-string))
           (t
            (format nil "~A" message-or-string)))))
    (declare (ignore details))
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :user-error
     "~A"
     message)))

;;; --- Math (autolisp-spec ch.5) -------------------------------------

(defun builtin-sqrt (object)
  (let ((value (coerce (require-number object "SQRT") 'double-float)))
    (when (minusp value)
      (signal-builtin-argument-error
       :invalid-number-argument
       "SQRT"
       "SQRT expects a non-negative number, got ~S."
       object))
    (sqrt value)))

(defun builtin-exp (object)
  (exp (coerce (require-number object "EXP") 'double-float)))

(defun builtin-log (object)
  (let ((value (coerce (require-number object "LOG") 'double-float)))
    (when (not (plusp value))
      (signal-builtin-argument-error
       :invalid-number-argument
       "LOG"
       "LOG expects a positive number, got ~S."
       object))
    (log value)))

(defun builtin-log10 (object)
  (let ((value (coerce (require-number object "LOG10") 'double-float)))
    (when (not (plusp value))
      (signal-builtin-argument-error
       :invalid-number-argument
       "LOG10"
       "LOG10 expects a positive number, got ~S."
       object))
    (log value 10.0d0)))

(defun builtin-sin (object)
  (sin (coerce (require-number object "SIN") 'double-float)))

(defun builtin-cos (object)
  (cos (coerce (require-number object "COS") 'double-float)))

(defun builtin-tan (object)
  (tan (coerce (require-number object "TAN") 'double-float)))

(defun builtin-sinh (object)
  (sinh (coerce (require-number object "SINH") 'double-float)))

(defun builtin-cosh (object)
  (cosh (coerce (require-number object "COSH") 'double-float)))

(defun builtin-tanh (object)
  (tanh (coerce (require-number object "TANH") 'double-float)))

(defun builtin-atanh (object)
  (let ((value (coerce (require-number object "ATANH") 'double-float)))
    (when (or (<= value -1.0d0) (>= value 1.0d0))
      (signal-builtin-argument-error
       :invalid-number-argument
       "ATANH"
       "ATANH expects a value in (-1, 1), got ~S."
       object))
    (atanh value)))

(defun builtin-power (base exponent)
  ;; Synonym for EXPT — present in BricsCAD V26 alongside EXPT.
  (builtin-expt base exponent))

(defun builtin-vl-nanp (object)
  ;; (vl-nanp OBJ) -> T if OBJ is an IEEE NaN double, nil otherwise.
  ;; Portable test: NaN is the only IEEE value not equal to itself.
  (cond
    ((and (typep object 'double-float)
          (handler-case (not (= object object)) (error () nil)))
     (intern-autolisp-symbol "T"))
    (t nil)))

(defun builtin-vl-infp (object)
  ;; (vl-infp OBJ) -> T if OBJ is +/-infinity, nil otherwise.
  ;; Portable test: only an infinity satisfies x = 2*x with x /= 0.
  (cond
    ((and (typep object 'double-float)
          (not (zerop object))
          (handler-case (= object (* 2 object)) (error () nil)))
     (intern-autolisp-symbol "T"))
    (t nil)))

(defun builtin-asin (object)
  (let ((value (coerce (require-number object "ASIN") 'double-float)))
    (when (or (< value -1.0d0) (> value 1.0d0))
      (signal-builtin-argument-error
       :invalid-number-argument
       "ASIN"
       "ASIN expects a value in [-1, 1], got ~S."
       object))
    (asin value)))

(defun builtin-acos (object)
  (let ((value (coerce (require-number object "ACOS") 'double-float)))
    (when (or (< value -1.0d0) (> value 1.0d0))
      (signal-builtin-argument-error
       :invalid-number-argument
       "ACOS"
       "ACOS expects a value in [-1, 1], got ~S."
       object))
    (acos value)))

(defun builtin-atan (y &optional x)
  ;; (atan y) -> arctangent in [-pi/2, pi/2].
  ;; (atan y x) -> arctangent of y/x using the signs of both
  ;; arguments to determine the quadrant. Real-valued double-float.
  (let ((y-value (coerce (require-number y "ATAN") 'double-float)))
    (if x
        (atan y-value (coerce (require-number x "ATAN") 'double-float))
        (atan y-value))))

(defun builtin-expt (base power)
  ;; (expt base power) — real if either arg is real OR the result
  ;; would not be a 32-bit integer. Mirrors AutoLISP's int-vs-real
  ;; promotion contract.
  (require-number base "EXPT")
  (require-number power "EXPT")
  (let ((result (handler-case (expt base power)
                  (arithmetic-error ()
                   (signal-builtin-argument-error
                    :invalid-number-argument
                    "EXPT"
                    "EXPT result is undefined for ~S^~S."
                    base power)))))
    (arithmetic-result
     (if (and (integerp base) (integerp power)
              (not (minusp power))
              (integerp result))
         result
         (coerce result 'double-float)))))

(defun builtin-mod (a b)
  ;; (mod a b) — modulo. Integers stay integer; mixed-type and real
  ;; promote to real. Division by zero -> error.
  (require-number a "MOD")
  (require-number b "MOD")
  (when (zerop b)
    (signal-builtin-argument-error
     :division-by-zero
     "MOD"
     "MOD divisor is zero."))
  (cond
    ((and (integerp a) (integerp b))
     (mod a b))
    (t
     (let ((af (coerce a 'double-float))
           (bf (coerce b 'double-float)))
       (- af (* bf (floor af bf)))))))

(defun builtin-floor (object &optional divisor)
  ;; (floor n) or (floor a b) -> integer floor toward -infinity.
  (require-number object "FLOOR")
  (when divisor (require-number divisor "FLOOR"))
  (let ((value (if divisor
                   (progn
                     (when (zerop divisor)
                       (signal-builtin-argument-error
                        :division-by-zero "FLOOR" "FLOOR divisor is zero."))
                     (/ object divisor))
                   object)))
    (arithmetic-result (floor value))))

(defun builtin-ceiling (object &optional divisor)
  (require-number object "CEILING")
  (when divisor (require-number divisor "CEILING"))
  (let ((value (if divisor
                   (progn
                     (when (zerop divisor)
                       (signal-builtin-argument-error
                        :division-by-zero "CEILING" "CEILING divisor is zero."))
                     (/ object divisor))
                   object)))
    (arithmetic-result (ceiling value))))

(defun builtin-round (object &optional divisor)
  ;; AutoLISP `round` rounds to nearest, half-away-from-zero on most
  ;; hosts. CL's `round` is half-to-even; we emulate the AutoLISP
  ;; convention to match deployed behaviour.
  (require-number object "ROUND")
  (when divisor (require-number divisor "ROUND"))
  (let* ((value (if divisor
                    (progn
                      (when (zerop divisor)
                        (signal-builtin-argument-error
                         :division-by-zero "ROUND" "ROUND divisor is zero."))
                      (/ object divisor))
                    object))
         (sign (if (minusp value) -1 1))
         (mag (abs value))
         (truncated (truncate (+ mag 0.5d0))))
    (arithmetic-result (* sign truncated))))

(defparameter *autolisp-random-state* (make-random-state t))

(defun builtin-random (n)
  ;; (random N) -> integer in [0, N) for positive integer N. Real
  ;; arguments are not common in AutoLISP corpora; we restrict to
  ;; integer for predictability.
  (let ((bound (require-int32 n "RANDOM")))
    (unless (plusp bound)
      (signal-builtin-argument-error
       :invalid-number-argument
       "RANDOM"
       "RANDOM expects a positive integer, got ~S."
       n))
    (random bound *autolisp-random-state*)))

;;; --- Bitwise ---------------------------------------------------------

(defun builtin-logxor (&rest arguments)
  (dolist (argument arguments)
    (require-int32 argument "LOGXOR"))
  (arithmetic-result (apply #'logxor 0 arguments)))

(defun builtin-boole (op &rest arguments)
  ;; (boole OP I1 I2 ...) — generic bitwise reducer; OP is an
  ;; integer 0..15 selecting one of the 16 binary boolean functions
  ;; per the documented truth-table layout (AND=1, IOR=7, XOR=6,
  ;; etc.). Most user code uses LOGAND / LOGIOR / LOGXOR directly;
  ;; we map the common selectors and signal :unsupported-boole-op
  ;; for the rest.
  (let ((selector (require-int32 op "BOOLE")))
    (dolist (argument arguments)
      (require-int32 argument "BOOLE"))
    (case selector
      (1 (arithmetic-result (apply #'logand -1 arguments)))      ; AND
      (6 (arithmetic-result (apply #'logxor 0 arguments)))       ; XOR
      (7 (arithmetic-result (apply #'logior 0 arguments)))       ; IOR
      (otherwise
       (signal-builtin-argument-error
        :unsupported-boole-op
        "BOOLE"
        "BOOLE selector ~S is not implemented; use LOGAND / LOGIOR / LOGXOR."
        op)))))

;;; --- List (autolisp-spec ch.5/13) -----------------------------------

(defun builtin-vl-list-length (list)
  ;; Return the proper-list length, or nil if list is dotted /
  ;; circular.
  (cond
    ((null list) 0)
    ((not (listp list)) nil)
    (t
     (let ((slow list) (fast list) (count 0))
       (loop
         (cond
           ((null fast) (return count))
           ((not (consp fast)) (return nil))
           (t (incf count) (setf fast (cdr fast))))
         (cond
           ((null fast) (return count))
           ((not (consp fast)) (return nil))
           (t (incf count) (setf fast (cdr fast))))
         (setf slow (cdr slow))
         (when (eq fast slow) (return nil)))))))

(defun builtin-vl-position (item list)
  ;; (vl-position ITEM LIST) -> 0-based index or nil.
  (require-proper-list list "VL-POSITION")
  (loop for cell on list
        for index from 0
        when (autolisp-equal-p item (car cell))
          return index
        finally (return nil)))

(defun builtin-position (item list)
  ;; (position ITEM LIST) — BricsCAD V26 alias for vl-position.
  (builtin-vl-position item list))

(defun builtin-vl-remove (item list)
  ;; (vl-remove ITEM LIST) — synonym for REMOVE.
  (builtin-remove item list))

(defun builtin-remove (item list)
  ;; (remove ITEM LIST) -> new list with all elements equal to ITEM removed.
  (require-proper-list list "REMOVE")
  (loop for element in list
        unless (autolisp-equal-p item element)
          collect element))

(defun builtin-vl-sort (list comparator)
  ;; (vl-sort LIST PREDICATE) — sort LIST stably under PREDICATE
  ;; (a < b iff (PREDICATE a b)). Returns a fresh list.
  (require-proper-list list "VL-SORT")
  (let ((function (resolve-autolisp-function-designator comparator)))
    (sort (copy-list list)
          (lambda (a b)
            (autolisp-true-p (call-autolisp-function function a b))))))

(defun builtin-vl-sort-i (list comparator)
  ;; (vl-sort-i LIST PREDICATE) — return the list of original indices
  ;; sorted under PREDICATE.
  (require-proper-list list "VL-SORT-I")
  (let* ((function (resolve-autolisp-function-designator comparator))
         (indexed (loop for x in list for i from 0 collect (cons i x))))
    (mapcar #'car
            (sort indexed
                  (lambda (a b)
                    (autolisp-true-p
                     (call-autolisp-function function (cdr a) (cdr b))))))))

(defun builtin-distance (point-a point-b)
  ;; (distance P1 P2) -> 2D / 3D Euclidean distance between two
  ;; coordinate lists. Missing Z components default to 0.
  (require-proper-list point-a "DISTANCE")
  (require-proper-list point-b "DISTANCE")
  (let* ((coords-a (mapcar (lambda (n) (require-number n "DISTANCE")) point-a))
         (coords-b (mapcar (lambda (n) (require-number n "DISTANCE")) point-b))
         (xa (coerce (or (nth 0 coords-a) 0) 'double-float))
         (ya (coerce (or (nth 1 coords-a) 0) 'double-float))
         (za (coerce (or (nth 2 coords-a) 0) 'double-float))
         (xb (coerce (or (nth 0 coords-b) 0) 'double-float))
         (yb (coerce (or (nth 1 coords-b) 0) 'double-float))
         (zb (coerce (or (nth 2 coords-b) 0) 'double-float)))
    (sqrt (+ (expt (- xb xa) 2)
             (expt (- yb ya) 2)
             (expt (- zb za) 2)))))

(defun builtin-angle (point-a point-b)
  ;; (angle P1 P2) -> angle in radians from P1 to P2 in the XY plane.
  (require-proper-list point-a "ANGLE")
  (require-proper-list point-b "ANGLE")
  (let* ((xa (coerce (require-number (nth 0 point-a) "ANGLE") 'double-float))
         (ya (coerce (require-number (nth 1 point-a) "ANGLE") 'double-float))
         (xb (coerce (require-number (nth 0 point-b) "ANGLE") 'double-float))
         (yb (coerce (require-number (nth 1 point-b) "ANGLE") 'double-float))
         (theta (atan (- yb ya) (- xb xa))))
    (if (minusp theta) (+ theta (* 2 pi)) theta)))

(defun builtin-polar (origin angle distance)
  ;; (polar P A D) -> point at distance D from P at angle A.
  (require-proper-list origin "POLAR")
  (let* ((a (coerce (require-number angle "POLAR") 'double-float))
         (d (coerce (require-number distance "POLAR") 'double-float))
         (x (coerce (require-number (nth 0 origin) "POLAR") 'double-float))
         (y (coerce (require-number (nth 1 origin) "POLAR") 'double-float))
         (z (if (>= (length origin) 3)
                (coerce (require-number (nth 2 origin) "POLAR") 'double-float)
                0.0d0)))
    (list (+ x (* d (cos a)))
          (+ y (* d (sin a)))
          z)))

;;; --- String / conversion (autolisp-spec ch.7, 11) ------------------

(defun builtin-itoa (object)
  ;; (itoa INT) -> decimal string.
  (let ((value (require-int32 object "ITOA")))
    (make-autolisp-string (format nil "~D" value))))

(defun %format-decimal-real (n p)
  "Fixed-point (decimal) formatting for RTOS / ANGTOS: P places after
the point, but with NO trailing decimal point when P is 0 — AutoCAD's
`(rtos 1.6 2 0)` is \"2\", not CL's `~,0F` \"2.\". P is clamped to
non-negative. system-variables.issue, 'rtos/distance float-format'."
  (let ((s (format nil "~,vF" (max 0 p) n)))
    (if (and (plusp (length s))
             (char= (char s (1- (length s))) #\.))
        (subseq s 0 (1- (length s)))
        s)))

(defun %format-scientific-real (n p)
  "Scientific (mode 1) formatting for RTOS in AutoCAD style: uppercase
E, an always-signed exponent zero-padded to at least two digits, e.g.
`(rtos 100.0 1 2)' => \"1.00E+02\". CL's bare `~E' would emit the
double-float exponent marker (\"1.00d+2\") with an unpadded exponent;
the ~E exponent-digits (2) and exponent-char ('E) parameters fix both.
Exponents wider than two digits expand as needed (e.g. \"1.00E+100\").
system-variables.issue, 'rtos/distance float-format'."
  (format nil "~,v,2,,,,'EE" (max 0 p) n))

(defun %rtos-units-sysvar (name default)
  "Read an integer linear-units sysvar (LUNITS / LUPREC / DIMZIN)
from the active evaluation host for RTOS, returning DEFAULT in a
host-less context (e.g. a bare unit test) so RTOS keeps its
documented AutoCAD defaults — LUNITS 2, LUPREC 4, DIMZIN 0."
  (%host-sysvar-integer (ignore-errors (current-evaluation-host)) name default))

(defun %apply-dimzin-decimal (s dimzin)
  "Apply DIMZIN decimal zero-suppression to a fixed-point RTOS string S.
For decimal output only two DIMZIN bits are meaningful (the feet/inch
bits 0-3 are architectural):

  - bit 3 (value 8): suppress trailing zeros — \"12.5000\" -> \"12.5\",
    \"12.0000\" -> \"12\" (a now-empty fraction drops its point);
  - bit 2 (value 4): suppress a leading zero in the integer part —
    \"0.5000\" -> \".5000\", \"-0.5000\" -> \"-.5000\".

DIMZIN 0 (the default) leaves S untouched. autolisp-spec rtos Notes;
system-variables.issue 'Coupling'."
  (let ((suppress-trailing (logbitp 3 dimzin))
        (suppress-leading   (logbitp 2 dimzin))
        (result s))
    ;; Trailing zeros only matter when there is a fractional part.
    (when (and suppress-trailing (find #\. result))
      (setf result (string-right-trim "0" result))
      (when (and (plusp (length result))
                 (char= (char result (1- (length result))) #\.))
        (setf result (subseq result 0 (1- (length result))))))
    (when suppress-leading
      (cond
        ((and (>= (length result) 2)
              (char= (char result 0) #\0)
              (char= (char result 1) #\.))
         (setf result (subseq result 1)))
        ((and (>= (length result) 3)
              (char= (char result 0) #\-)
              (char= (char result 1) #\0)
              (char= (char result 2) #\.))
         (setf result (concatenate 'string "-" (subseq result 2))))))
    result))

(defun builtin-rtos (number &optional mode precision)
  ;; (rtos NUMBER [MODE [PRECISION]]) -> string. We honour MODE 1
  ;; (scientific) and 2 (decimal) and the PRECISION argument; modes
  ;; 3 (engineering), 4 (architectural), 5 (fractional) are not
  ;; useful headlessly and fall back to mode 2.
  ;;
  ;; When MODE / PRECISION are omitted, RTOS reads the LUNITS /
  ;; LUPREC system variables (autolisp-spec rtos Notes; AutoCAD
  ;; defaults LUNITS 2, LUPREC 4 match the historic hard-coded
  ;; values, so a host that never sets them is unchanged). The
  ;; decimal result is then zero-suppressed per DIMZIN. UNITMODE
  ;; affects only the engineering/architectural/fractional modes,
  ;; which fall back to decimal here, so it is currently a no-op.
  ;; system-variables.issue 'Coupling'.
  (require-number number "RTOS")
  (when mode (require-int32 mode "RTOS"))
  (when precision (require-int32 precision "RTOS"))
  (let* ((m (or mode (%rtos-units-sysvar "LUNITS" 2)))
         (p (or precision (%rtos-units-sysvar "LUPREC" 4)))
         (dimzin (%rtos-units-sysvar "DIMZIN" 0))
         (n (coerce number 'double-float)))
    (make-autolisp-string
     (case m
       (1 (%format-scientific-real n p))
       (otherwise (%apply-dimzin-decimal (%format-decimal-real n p) dimzin))))))

(defun builtin-angtos (angle &optional mode precision)
  ;; (angtos ANGLE [MODE [PRECISION]]) -> string in radians (MODE 0)
  ;; or degrees (MODE 1) by default. Modes 2-4 (grad / surveyor /
  ;; deg-min-sec) are not useful headlessly; we fall back to degrees.
  (require-number angle "ANGTOS")
  (when mode (require-int32 mode "ANGTOS"))
  (when precision (require-int32 precision "ANGTOS"))
  (let ((m (or mode 0))
        (p (or precision 4))
        (rad (coerce angle 'double-float)))
    (make-autolisp-string
     (case m
       (0 (%format-decimal-real rad p))
       (otherwise (%format-decimal-real (* rad (/ 180.0d0 pi)) p))))))

(defun builtin-distof (string &optional mode)
  (declare (ignore mode))
  (let ((value (autolisp-string-value (require-string string "DISTOF"))))
    (parse-autolisp-real value)))

(defun builtin-angtof (string &optional mode)
  ;; (angtof STRING [MODE]) -> real angle. Mode 0 = radians, 1 = deg
  ;; (default decimal). Anything else falls back to a decimal parse.
  (let ((value (autolisp-string-value (require-string string "ANGTOF")))
        (m (if mode (require-int32 mode "ANGTOF") 0)))
    (let ((parsed (parse-autolisp-real value)))
      (case m
        (0 parsed)
        (1 (* parsed (/ pi 180.0d0)))
        (otherwise parsed)))))

(defun %host-sysvar-integer (host name &optional (default 0))
  "Fetch an integer-valued sysvar from HOST as a CL integer, returning
DEFAULT when HOST is nil, the sysvar is absent or non-integer, or the
host does not support getvar (e.g. a host-less unit-test context).
Companion to %HOST-SYSVAR-STRING."
  (let ((raw (and host (ignore-errors (host-getvar host name)))))
    (if (integerp raw) raw default)))

(defun builtin-snvalid (string &optional flag)
  ;; (snvalid STRING [FLAG]) -> T when STRING is a valid symbol-table
  ;; name, nil otherwise. The rules track the EXTNAMES sysvar (see the
  ;; SNVALID / EXTNAMES entries in the spec, and
  ;; issues/open/system-variables.issue "Coupling"):
  ;;   EXTNAMES = 1 (default): extended naming — every character is
  ;;     accepted except the reserved set  < > / \ " : ? * | , = ` ;
  ;;     (spaces ARE allowed); FLAG with the 1 bit set additionally
  ;;     permits the vertical bar "|" (xref-dependent names).
  ;;   EXTNAMES = 0: restrictive R14 naming — only A-Z 0-9 $ _ - .
  ;; A name is never valid when empty.
  (let* ((value (autolisp-string-value (require-string string "SNVALID")))
         (extnames (%host-sysvar-integer (ignore-errors (current-evaluation-host))
                                         "EXTNAMES" 1))
         (permit-bar (and flag (if (integerp flag) (logbitp 0 flag) t))))
    (cond
      ((zerop (length value)) nil)
      ((eql extnames 0)
       (if (every (lambda (c) (or (alphanumericp c) (find c "$_-"))) value)
           (intern-autolisp-symbol "T")
           nil))
      (t
       (let ((reserved (if permit-bar "<>/\\\":?*,=`;" "<>/\\\":?*|,=`;")))
         (if (find-if (lambda (c) (find c reserved)) value)
             nil
             (intern-autolisp-symbol "T")))))))

(defun builtin-xstrcase (string &optional downcase-p)
  ;; vl-extension flavour of strcase that handles non-ASCII text
  ;; better. Headless: same effect as strcase.
  (builtin-strcase string downcase-p))

(defun wcmatch-pattern-p (text pattern)
  ;; Minimal AutoCAD WCMATCH grammar: `*` zero-or-more, `?` any
  ;; single, `#` digit, `@` letter, `.` any non-alnum, `~` (at start)
  ;; complements the match, `,` separates alternative patterns,
  ;; `[abc]` / `[~abc]` / `[a-z]` character classes, ``` `c ``` escapes.
  (let* ((alts (loop for s = 0 then (1+ pos)
                     for pos = (position #\, pattern :start s)
                     collect (subseq pattern s (or pos (length pattern)))
                     while pos))
         (matched
          (some (lambda (alt)
                  (let* ((negate (and (plusp (length alt)) (char= (char alt 0) #\~)))
                         (pat (if negate (subseq alt 1) alt))
                         (hit (wcmatch-single-p text pat)))
                    (if negate (not hit) hit)))
                alts)))
    matched))

(defun wcmatch-single-p (text pattern)
  ;; Recursive-descent matcher for one WCMATCH alternative.
  (let ((tlen (length text))
        (plen (length pattern)))
    (labels ((rec (ti pj)
               (cond
                 ((= pj plen) (= ti tlen))
                 ((char= (char pattern pj) #\*)
                  (or (rec ti (1+ pj))
                      (and (< ti tlen) (rec (1+ ti) pj))))
                 ((= ti tlen) nil)
                 ((char= (char pattern pj) #\?) (rec (1+ ti) (1+ pj)))
                 ((char= (char pattern pj) #\#)
                  (and (digit-char-p (char text ti)) (rec (1+ ti) (1+ pj))))
                 ((char= (char pattern pj) #\@)
                  (and (alpha-char-p (char text ti)) (rec (1+ ti) (1+ pj))))
                 ((char= (char pattern pj) #\.)
                  (and (not (alphanumericp (char text ti))) (rec (1+ ti) (1+ pj))))
                 ((char= (char pattern pj) #\`)
                  (and (< (1+ pj) plen)
                       (char= (char text ti) (char pattern (1+ pj)))
                       (rec (1+ ti) (+ 2 pj))))
                 ((char= (char pattern pj) #\[)
                  (let* ((end (position #\] pattern :start (1+ pj))))
                    (when end
                      (let* ((class (subseq pattern (1+ pj) end))
                             (negate (and (plusp (length class)) (char= (char class 0) #\~)))
                             (chars (if negate (subseq class 1) class))
                             (member-p (loop for k from 0 below (length chars)
                                             thereis
                                               (cond
                                                 ((and (< (+ k 2) (length chars))
                                                       (char= (char chars (1+ k)) #\-))
                                                  (char<= (char chars k)
                                                          (char text ti)
                                                          (char chars (+ k 2))))
                                                 (t (char= (char chars k)
                                                           (char text ti)))))))
                        (when (if negate (not member-p) member-p)
                          (rec (1+ ti) (1+ end)))))))
                 (t
                  (and (char= (char pattern pj) (char text ti))
                       (rec (1+ ti) (1+ pj)))))))
      (rec 0 0))))

(defun builtin-wcmatch (string pattern)
  (let ((s (autolisp-string-value (require-string string "WCMATCH")))
        (p (autolisp-string-value (require-string pattern "WCMATCH"))))
    (if (wcmatch-pattern-p s p) (intern-autolisp-symbol "T") nil)))

;;; --- Geometry ------------------------------------------------------

(defun builtin-inters (p1 p2 p3 p4 &optional within-segments-p)
  ;; (inters P1 P2 P3 P4 [FLAG]) -> point or nil. If FLAG is supplied
  ;; as nil, intersection may lie outside the segments. Default is to
  ;; require that the point lies on both segments.
  (require-proper-list p1 "INTERS")
  (require-proper-list p2 "INTERS")
  (require-proper-list p3 "INTERS")
  (require-proper-list p4 "INTERS")
  (let* ((require-within (if (boundp 'within-segments-p)
                             (autolisp-true-p within-segments-p)
                             t))
         (x1 (coerce (require-number (nth 0 p1) "INTERS") 'double-float))
         (y1 (coerce (require-number (nth 1 p1) "INTERS") 'double-float))
         (x2 (coerce (require-number (nth 0 p2) "INTERS") 'double-float))
         (y2 (coerce (require-number (nth 1 p2) "INTERS") 'double-float))
         (x3 (coerce (require-number (nth 0 p3) "INTERS") 'double-float))
         (y3 (coerce (require-number (nth 1 p3) "INTERS") 'double-float))
         (x4 (coerce (require-number (nth 0 p4) "INTERS") 'double-float))
         (y4 (coerce (require-number (nth 1 p4) "INTERS") 'double-float))
         (denom (- (* (- x1 x2) (- y3 y4))
                   (* (- y1 y2) (- x3 x4)))))
    (when (zerop denom) (return-from builtin-inters nil))
    (let* ((t-num (- (* (- x1 x3) (- y3 y4))
                     (* (- y1 y3) (- x3 x4))))
           (u-num (- (* (- x1 x3) (- y1 y2))
                     (* (- y1 y3) (- x1 x2))))
           (tt (/ t-num denom))
           (uu (/ u-num denom))
           (px (+ x1 (* tt (- x2 x1))))
           (py (+ y1 (* tt (- y2 y1)))))
      (cond
        ((not require-within) (list px py 0.0d0))
        ((and (<= 0.0d0 tt 1.0d0) (<= 0.0d0 uu 1.0d0)) (list px py 0.0d0))
        (t nil)))))

;;; --- Predicate helpers --------------------------------------------

(defun builtin-atoms-family (format-flag &optional symbol-list)
  ;; (atoms-family FORMAT [LIST]) -> list of names of currently-bound
  ;; symbols. FORMAT 0 = symbols, 1 = strings. With LIST, the return
  ;; is restricted to the supplied names; unbound names map to nil.
  (let ((format (require-int32 format-flag "ATOMS-FAMILY"))
        (filter symbol-list))
    (when filter (require-proper-list filter "ATOMS-FAMILY"))
    (labels ((render (name)
               (cond
                 ((zerop format) (intern-autolisp-symbol name))
                 ((= format 1) (make-autolisp-string name))
                 (t (signal-builtin-argument-error
                     :invalid-number-argument
                     "ATOMS-FAMILY"
                     "ATOMS-FAMILY format flag must be 0 or 1, got ~S."
                     format-flag)))))
      (cond
        (filter
         (mapcar (lambda (sym)
                   (let* ((name (cond
                                  ((typep sym 'autolisp-symbol)
                                   (autolisp-symbol-name sym))
                                  ((typep sym 'autolisp-string)
                                   (autolisp-string-value sym))
                                  (t (signal-builtin-argument-error
                                      :invalid-symbol-argument
                                      "ATOMS-FAMILY"
                                      "ATOMS-FAMILY list element must be a symbol or string, got ~S."
                                      sym))))
                          (resolved (clautolisp.autolisp-runtime:find-autolisp-symbol name)))
                     (if (and resolved
                              (clautolisp.autolisp-runtime:autolisp-symbol-value-bound-p resolved))
                         (render name)
                         nil)))
                 filter))
        (t
         (let ((result '()))
           (maphash (lambda (name sym)
                      (when (clautolisp.autolisp-runtime:autolisp-symbol-value-bound-p sym)
                        (push (render name) result)))
                    clautolisp.autolisp-runtime.internal::*autolisp-symbol-table*)
           (nreverse result)))))))

;;; --- Tracing / help (stubs that maintain identity) -----------------

(defun builtin-setfunhelp (function-name &rest topic)
  ;; (setfunhelp NAME [HELPTOPIC [COMMAND]]) — associates a help
  ;; topic with a function. Headless: accepted, recorded as a plist
  ;; entry on the function symbol but otherwise inert.
  (declare (ignore topic))
  (cond
    ((typep function-name 'autolisp-string)
     (intern-autolisp-symbol (autolisp-string-value function-name)))
    ((typep function-name 'autolisp-symbol)
     function-name)
    (t
     (signal-builtin-argument-error
      :invalid-symbol-argument
      "SETFUNHELP"
      "SETFUNHELP expects a function name (string or symbol), got ~S."
      function-name))))

;;; --- source-aware-defun-documentation (clautolisp-only) -----------

(defun %resolve-documentation-symbol (arg builtin-name)
  "Coerce ARG (an autolisp-symbol or autolisp-string) to an
autolisp-symbol whose binding cell carries the doc. Used by the
CLAUTOLISP-DOCUMENTATION{,-KIND} builtins."
  (cond
    ((typep arg 'autolisp-symbol) arg)
    ((typep arg 'autolisp-string)
     (intern-autolisp-symbol (autolisp-string-value arg)))
    (t
     (signal-builtin-argument-error
      :invalid-symbol-argument
      builtin-name
      "~A expects a symbol or string, got ~S."
      builtin-name arg))))

(defun builtin-clautolisp-documentation (name)
  ;; (clautolisp-documentation NAME) -> string | nil
  ;; Walks the current dynamic frame chain like value lookup and
  ;; returns the doc-string of the innermost binding for NAME.
  ;; Returns nil when the binding carries no doc OR no binding
  ;; exists. NAME is coerced to its uppercased symbol name.
  (let* ((sym (%resolve-documentation-symbol name "CLAUTOLISP-DOCUMENTATION"))
         (tag (clautolisp.autolisp-runtime:lookup-documentation sym)))
    (and tag (consp tag) (make-autolisp-string (cadr tag)))))

(defun builtin-clautolisp-documentation-kind (name)
  ;; (clautolisp-documentation-kind NAME) -> 'function | 'variable | nil
  ;; Returns the head of the doc-tag from the innermost binding cell.
  ;; Independent of the value's runtime type — reflects the last
  ;; *documented* assignment, not the current value.
  (let* ((sym (%resolve-documentation-symbol name "CLAUTOLISP-DOCUMENTATION-KIND"))
         (tag (clautolisp.autolisp-runtime:lookup-documentation sym)))
    (cond
      ((and (consp tag) (eq (car tag) :function))
       (intern-autolisp-symbol "FUNCTION"))
      ((and (consp tag) (eq (car tag) :variable))
       (intern-autolisp-symbol "VARIABLE"))
      (t nil))))

(defparameter *autolisp-backtrace-enabled-p* nil)

(defun format-call-stack-frame (frame)
  "Pretty-print a single backtrace frame (KIND . PAYLOAD) returned by
clautolisp's runtime call-stack tracker."
  (let ((kind (car frame))
        (payload (cdr frame)))
    (case kind
      (:eval        (format nil "  in EVAL: ~S" payload))
      (:special-op  (format nil "  in SPECIAL: ~S" payload))
      (:subr        (format nil "  in SUBR ~A: args ~S"
                            (car payload) (cdr payload)))
      (:usubr       (format nil "  in USUBR ~A: args ~S"
                            (car payload) (cdr payload)))
      (otherwise    (format nil "  ~A: ~S" kind payload)))))

(defun render-call-stack (stack)
  "Render STACK (most-recent-first) as a multi-line string suitable
for printing or for inclusion in a test report."
  (with-output-to-string (out)
    (format out "AutoLISP backtrace (most recent call first):~%")
    (if (null stack)
        (format out "  <empty>~%")
        (dolist (frame stack)
          (format out "~A~%" (format-call-stack-frame frame))))))

(defun builtin-vl-bt ()
  "(vl-bt) — print the AutoLISP call stack at the current evaluation
point and return nil. The stack is captured by the clautolisp runtime
through *autolisp-call-stack* and includes evaluator frames, special
forms and SUBR / USUBR calls. The output mirrors what AutoCAD and
BricsCAD show for their own vl-bt -- one line per frame, most recent
on top."
  (princ (render-call-stack
          (clautolisp.autolisp-runtime:current-autolisp-call-stack)))
  nil)

(defun builtin-vl-bt-on ()
  (setf *autolisp-backtrace-enabled-p* t)
  (intern-autolisp-symbol "T"))

(defun builtin-vl-bt-off ()
  (setf *autolisp-backtrace-enabled-p* nil)
  nil)

(defun builtin-vl-catch-all-error-stack (object)
  "(vl-catch-all-error-stack OBJECT) — clautolisp extension. Return
the AutoLISP call-stack snapshot captured at the time the catch-all
error was raised. The stack is a list of (KIND . PAYLOAD) frames,
most recent first."
  (unless (typep object 'autolisp-catch-all-error)
    (signal-builtin-argument-error
     :invalid-catch-all-object
     "VL-CATCH-ALL-ERROR-STACK"
     "VL-CATCH-ALL-ERROR-STACK expects a catch-all error object, got ~S."
     object))
  ;; Convert the CL list of conses into AutoLISP-readable values.
  ;; Each frame stays a cons (KIND . PAYLOAD); the harness can walk
  ;; it with car/cdr/foreach.
  (clautolisp.autolisp-runtime:autolisp-catch-all-error-call-stack object))
;;; --- Phase 10: entity-level builtins -------------------------------
;;;
;;; Each builtin is a thin wrapper around the corresponding HAL
;;; generic function on the active session's host backend
;;; (autolisp-spec ch.16). The current-evaluation-host helper
;;; resolves the backend through the active context; under NullHost
;;; every call signals :host-not-supported, under MockHost it
;;; reaches the methods in autolisp-mock-host/source/entity-api.lisp.

(defun require-ename (object operator-name)
  (unless (typep object 'autolisp-ename)
    (signal-builtin-argument-error
     :invalid-ename
     operator-name
     "~A expects an ENAME, got ~S."
     operator-name object))
  object)

(defun builtin-entget (ename)
  ;; Documented to set ERRNO on failure. Code 2 = "Invalid entity
  ;; or selection-set name" covers both the unknown-ename and
  ;; deleted-ename cases when the host returns nil.
  (let ((result (host-entget (current-evaluation-host)
                             (require-ename ename "ENTGET"))))
    (if result
        (errno-and-return 0 result)
        (errno-and-return 2 nil))))

(defun builtin-entmod (data)
  ;; Documented to set ERRNO on failure. Code 31 = "Attempt to
  ;; modify deleted entity" / 2 for unknown ename. We use 2 as
  ;; the conservative shared code when the host returns nil.
  (require-proper-list data "ENTMOD")
  (let ((result (host-entmod (current-evaluation-host) data)))
    (if result
        (errno-and-return 0 result)
        (errno-and-return 2 nil))))

(defun builtin-entmake (data)
  ;; Documented to set ERRNO on failure. Code 36 = "Bad entity type".
  (require-proper-list data "ENTMAKE")
  (let ((result (host-entmake (current-evaluation-host) data)))
    (if result
        (errno-and-return 0 result)
        (errno-and-return 36 nil))))

(defun builtin-entmakex (data)
  ;; Same ERRNO contract as ENTMAKE.
  (require-proper-list data "ENTMAKEX")
  (let ((result (host-entmakex (current-evaluation-host) data)))
    (if result
        (errno-and-return 0 result)
        (errno-and-return 36 nil))))

(defun builtin-entdel (ename)
  ;; Not in the canonical ERRNO :coupled list; reset on success only.
  (let ((result (host-entdel (current-evaluation-host)
                              (require-ename ename "ENTDEL"))))
    (errno-and-return 0 result)))

(defun builtin-entupd (ename)
  ;; Not in the canonical ERRNO :coupled list; reset on success only.
  (let ((result (host-entupd (current-evaluation-host)
                              (require-ename ename "ENTUPD"))))
    (errno-and-return 0 result)))

(defun builtin-entlast ()
  ;; (entlast) returning nil because the drawing has no entities is
  ;; not an error; do not touch ERRNO.
  (host-entlast (current-evaluation-host)))

(defun builtin-entnext (&optional ename)
  ;; (entnext) returning nil at end-of-list is not an error; do
  ;; not touch ERRNO.
  (host-entnext (current-evaluation-host)
                (and ename (require-ename ename "ENTNEXT"))))

(defun builtin-handent (handle-string)
  ;; Documented failure code 13 = "Invalid handle".
  (let ((result (host-handent (current-evaluation-host)
                              (autolisp-string-value
                               (require-string handle-string "HANDENT")))))
    (if result
        (errno-and-return 0 result)
        (errno-and-return 13 nil))))

(defun require-pickset (object operator-name)
  (unless (typep object 'autolisp-pickset)
    (signal-builtin-argument-error
     :invalid-pickset
     operator-name
     "~A expects a PICKSET, got ~S."
     operator-name object))
  object)

;;; --- Phase 11: selection-set builtins -----------------------------

(defun builtin-ssget (&rest arguments)
  ;; (ssget)                   -> interactive (host-not-supported)
  ;; (ssget MODE)              -> mode without filter
  ;; (ssget MODE FILTER)       -> mode + filter
  ;; (ssget FILTER)            -> "X" + filter (rare; treated as
  ;;                              "X" / FILTER for convenience)
  ;; Modes are AutoLISP-strings; FILTER is a list of dotted pairs.
  ;;
  ;; Documented ERRNO codes: 56..67 for filter-shape errors. A
  ;; null return because the host found no matching entities is
  ;; not an error and leaves ERRNO alone.
  (let* ((host (current-evaluation-host))
         mode filter)
    (cond
      ((null arguments) nil)
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string) (setf mode only))
           ((listp only) (setf mode (make-autolisp-string "X")
                              filter only))
           (t (signal-builtin-argument-error
               :invalid-ssget-arguments
               "SSGET"
               "SSGET expects (MODE [FILTER]) or (MODE) or (FILTER), got ~S."
               only)))))
      (t
       (setf mode (first arguments)
             filter (second arguments))))
    (let ((result (host-ssget host filter :mode mode)))
      (if result
          (errno-and-return 0 result)
          result))))

(defun builtin-ssadd (&rest arguments)
  ;; (ssadd)              -> empty pickset
  ;; (ssadd ENAME)        -> singleton pickset
  ;; (ssadd ENAME PICKSET) -> updated pickset
  (let ((host (current-evaluation-host)))
    (case (length arguments)
      (0 (host-ssadd host nil nil))
      (1 (host-ssadd host nil (require-ename (first arguments) "SSADD")))
      (2 (host-ssadd host
                     (require-pickset (second arguments) "SSADD")
                     (require-ename (first arguments) "SSADD")))
      (otherwise
       (signal-builtin-argument-error
        :wrong-number-of-arguments
        "SSADD"
        "SSADD expects 0, 1, or 2 arguments, got ~D."
        (length arguments))))))

(defun builtin-ssdel (ename pickset)
  (host-ssdel (current-evaluation-host)
              (require-pickset pickset "SSDEL")
              (require-ename ename "SSDEL")))

(defun builtin-ssname (pickset index)
  ;; Documented to set ERRNO on failure. Code 22 = "Value out of
  ;; range" when INDEX is past the pickset's length; the host
  ;; method returns nil in that case.
  (let ((result (host-ssname (current-evaluation-host)
                             (require-pickset pickset "SSNAME")
                             (require-int32 index "SSNAME"))))
    (if result
        (errno-and-return 0 result)
        (errno-and-return 22 nil))))

(defun builtin-sslength (pickset)
  (host-sslength (current-evaluation-host)
                 (require-pickset pickset "SSLENGTH")))

(defun builtin-ssmemb (ename pickset)
  (host-ssmemb (current-evaluation-host)
               (require-pickset pickset "SSMEMB")
               (require-ename ename "SSMEMB")))

(defun builtin-ssgetfirst ()
  (host-ssgetfirst (current-evaluation-host)))

(defun builtin-sssetfirst (grip-list &optional pickset)
  ;; AutoLISP signature: (sssetfirst GRIP-SET PICKSET). MockHost
  ;; ignores the grip set; we route the pickset to the host.
  (declare (ignore grip-list))
  (host-sssetfirst (current-evaluation-host)
                   (and pickset (require-pickset pickset "SSSETFIRST"))))

;;; --- Phase 11: table walkers --------------------------------------

(defun builtin-tblsearch (kind name &optional next-after)
  ;; Documented to set ERRNO on bad table-name argument. Code 1 =
  ;; "Invalid symbol-table name" (used for the KIND argument); a
  ;; null return because NAME is absent from a valid table is not
  ;; an error and leaves ERRNO alone.
  (declare (ignore next-after))
  (let ((result (host-tblsearch (current-evaluation-host)
                                (autolisp-string-value (require-string kind "TBLSEARCH"))
                                (autolisp-string-value (require-string name "TBLSEARCH")))))
    (if result
        (errno-and-return 0 result)
        result)))

(defun builtin-tblnext (kind &optional rewind)
  ;; (tblnext) returning nil at end-of-table is not an error.
  (host-tblnext (current-evaluation-host)
                (autolisp-string-value (require-string kind "TBLNEXT"))
                :rewind (autolisp-true-p rewind)))

(defun builtin-tblobjname (kind name)
  ;; Documented failure code 1 (Invalid symbol-table name) covers
  ;; bad KIND; a missing NAME inside a valid table is not an error.
  (let ((result (host-tblobjname (current-evaluation-host)
                                 (autolisp-string-value (require-string kind "TBLOBJNAME"))
                                 (autolisp-string-value (require-string name "TBLOBJNAME")))))
    (if result
        (errno-and-return 0 result)
        result)))

;;; --- Phase 11: sysvar access --------------------------------------

(defun %dispatch-lispsys-foreign-dialect-diagnostic (operator-name)
  "Emit enc-foreign-dialect when user code touches LISPSYS under a
dialect that does not own it. LISPSYS is AutoCAD-only (introduced
2021); BricsCAD does not expose it. clautolisp warns to flag
non-portable code, but still permits the access — encoding-dispatch.
issue, section 'Per-dialect behavior / --strict / --bricscad /
--clautolisp', and the user's answer to the LISPSYS open question
('warn loudly, do not forbid')."
  (let* ((dialect (current-evaluation-dialect))
         (name (clautolisp.autolisp-reader:autolisp-dialect-name dialect)))
    (case name
      ((:autocad-2026)
       nil) ; native; silent.
      ((:strict)
       (clautolisp.autolisp-runtime:signal-encoding-diagnostic
        :enc-extension-used
        "~A on LISPSYS: AutoCAD-only sysvar, foreign to --strict."
        operator-name))
      ((:bricscad-v26 :clautolisp)
       (clautolisp.autolisp-runtime:signal-encoding-diagnostic
        :enc-foreign-dialect
        "~A on LISPSYS: AutoCAD-only sysvar, foreign to --~(~A~)."
        operator-name
        (case name
          (:bricscad-v26 "bricscad")
          (:clautolisp   "clautolisp")
          (t name))))
      (t nil))))

(defun %validate-lispsys-value (raw-value)
  "Enforce LISPSYS's documented {0,1,2} domain. RAW-VALUE is the
post-coerce-sysvar-value integer the host would otherwise store.
Out-of-range values emit enc-lispsys-out-of-range; the write itself
still proceeds (the runtime stays a faithful mock of the vendor
behaviour, which silently accepts out-of-range writes on some
builds) so user code stays runnable."
  (when (and (integerp raw-value)
             (not (member raw-value '(0 1 2))))
    (clautolisp.autolisp-runtime:signal-encoding-diagnostic
     :enc-lispsys-out-of-range
     "(setvar \"LISPSYS\" ~A): valid values are 0 (legacy MBCS), 1, or 2 (Unicode)."
     raw-value)))

(defun %lispsys-name-p (string)
  (and (stringp string) (string-equal string "LISPSYS")))

;;; --- CL drop: CLAUTOLISPDROP / CLAL-COMMON-LISP / CLAL-BACK ----------
;;;
;;; A developer escape hatch from AutoLISP into a live Common Lisp REPL
;;; running inside the clautolisp image (cl-debugging.issue). The AutoLISP
;;; symbol CLAL-COMMON-LISP is unbound by default; setting the read/write
;;; sysvar CLAUTOLISPDROP to 1 shadows it with the builtin below (saving,
;;; and on 0 restoring, any user binding). The CL REPL, CLAL-BACK and
;;; *CLAL-ON-ERROR* live in COMMON-LISP-USER, the package the dropped REPL
;;; reads in (the issue's "must be present in COMMON-LISP-USER").

(defvar common-lisp-user::*clal-on-error* :debug
  "Policy for an unhandled Common Lisp error while CLAL-COMMON-LISP evaluates
a form or runs its REPL, including an error converting the result
(cl-debugging.issue): :DEBUG invokes the native CL debugger (the default),
:ERROR signals a catchable AutoLISP error (VL-CATCH-ALL-APPLY sees it),
:IGNORE returns AutoLISP nil, and any other value is returned — converted to
AutoLISP when it is a convertible CL object, or as-is when it is already an
AutoLISP object.")

(defvar %clal-back-tag (list '#:clal-back)
  "Unique CATCH tag that CLAL-BACK throws to, to leave the dropped CL REPL.")

(defun common-lisp-user::clal-back (&optional value)
  "Return from the innermost dropped Common Lisp REPL to AutoLISP, yielding
VALUE (default nil) from the CLAL-COMMON-LISP call (cl-debugging.issue)."
  (throw %clal-back-tag value))

(defun %clal-al->cl (value)
  "Convert an AutoLISP VALUE to a Common Lisp form (cl-debugging.issue):
integers, reals and nil pass through; strings unwrap to CL strings; symbols
are re-read with CL:READ under the current CL *package* / *readtable* (so
'(foo cl:car :kw) can become (CL-USER::FOO CL:CAR :KW)); conses convert car
and cdr recursively; any other AutoLISP object passes through unchanged."
  (typecase value
    (null            nil)
    (real            value)             ; integers and doubles pass through
    (autolisp-string (autolisp-string-value value))
    (autolisp-symbol (values (read-from-string (autolisp-symbol-name value))))
    (cons            (cons (%clal-al->cl (car value))
                           (%clal-al->cl (cdr value))))
    (t               value)))

(defun %clal-cl->al (value &optional (seen (make-hash-table :test 'eq)))
  "Convert a Common Lisp VALUE to an AutoLISP object (cl-debugging.issue): a
CL integer in AutoLISP range passes through (else a CL error); a float is cast
to double-float; a string is wrapped; a keyword becomes an AutoLISP symbol
whose name is the keyword name prefixed by a colon; a cons converts car and
cdr recursively (a cycle is a CL error); any other symbol is PRIN1-TO-STRING'd,
upcased and interned as an AutoLISP symbol (its package qualification thus
follows the current CL *package*); an object already an AutoLISP value is
returned as-is; anything else is a CL error."
  (typecase value
    (null    nil)
    (integer (if (typep value '(signed-byte 32))
                 value
                 (error "CLAL-COMMON-LISP: integer ~A is out of the AutoLISP range."
                        value)))
    (float   (coerce value 'double-float))
    (string  (make-autolisp-string value))
    (keyword (intern-autolisp-symbol
              (concatenate 'string ":" (symbol-name value))))
    (cons
     (when (gethash value seen)
       (error "CLAL-COMMON-LISP: cannot convert a circular structure to AutoLISP."))
     (setf (gethash value seen) t)
     (prog1 (cons (%clal-cl->al (car value) seen)
                  (%clal-cl->al (cdr value) seen))
       (remhash value seen)))
    (symbol  (intern-autolisp-symbol (string-upcase (prin1-to-string value))))
    (t       (if (clautolisp.autolisp-runtime:runtime-value-p value)
                 value
                 (error "CLAL-COMMON-LISP: cannot convert ~S to an AutoLISP object."
                        value)))))

(defun %clal-error-action (condition)
  "Apply COMMON-LISP-USER::*CLAL-ON-ERROR* to CONDITION. :DEBUG enters the
native CL debugger in the error's context; :ERROR re-signals as a catchable
AutoLISP error; otherwise the policy value itself is produced as the result —
returned via the caller's DONE block. Meant to run as a HANDLER-BIND handler."
  (let ((policy common-lisp-user::*clal-on-error*))
    (cond
      ((eq policy :debug)  (let ((*debugger-hook* nil)) (invoke-debugger condition)))
      ((eq policy :error)  (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                            :clal-common-lisp-error "CLAL-COMMON-LISP: ~A" condition))
      (t                   policy))))     ; :IGNORE (nil) or a value; caller returns it

(defun %clal-guarded (thunk)
  "Call THUNK (which returns an AutoLISP value) under *CLAL-ON-ERROR*. On a CL
error the policy decides: :DEBUG debugger, :ERROR AutoLISP error, :IGNORE nil,
otherwise the policy value converted to AutoLISP (as-is if already AutoLISP)."
  (block done
    (handler-bind
        ((error (lambda (condition)
                  (let ((policy (%clal-error-action condition)))
                    ;; Reached only for :IGNORE / value policies (the others
                    ;; transfer control); convert a CL policy value out.
                    (return-from done
                      (cond ((eq policy :ignore) nil)
                            ((clautolisp.autolisp-runtime:runtime-value-p policy) policy)
                            (t (%clal-cl->al policy))))))))
      (funcall thunk))))

(defun %clal-eval-cl (form)
  "Evaluate the CL FORM, returning the list of its CL values, honoring
*CLAL-ON-ERROR* on error. Used by the REPL, which prints the raw CL values."
  (block done
    (handler-bind
        ((error (lambda (condition)
                  (let ((policy (%clal-error-action condition)))
                    (return-from done
                      (if (eq policy :ignore) (list nil) (list policy)))))))
      (multiple-value-list (eval form)))))

(defun %clal-repl ()
  "Run an interactive Common Lisp REPL in COMMON-LISP-USER until (CLAL-BACK) or
end of input, reading from *STANDARD-INPUT* and printing to *STANDARD-OUTPUT*.
Returns the AutoLISP-converted value passed to CLAL-BACK (nil by default)."
  (let ((*package* (find-package '#:common-lisp-user))
        (eof (list '#:eof)))
    (%clal-cl->al
     (catch %clal-back-tag
       (loop
         (fresh-line)
         (write-string "CL-USER> ")
         (finish-output)
         (let ((form (read *standard-input* nil eof)))
           (when (eq form eof) (return nil))
           (with-simple-restart (abort "Return to the CLAL Common Lisp REPL.")
             (dolist (v (%clal-eval-cl form))
               (fresh-line)
               (prin1 v))
             (terpri))))))))

(defun builtin-clal-common-lisp (&optional (arg nil argp))
  "CLAL-COMMON-LISP (cl-debugging.issue): with no argument, run an interactive
Common Lisp REPL in COMMON-LISP-USER (leave it with (CLAL-BACK)); with a string
argument, READ one CL form from it and evaluate it; with any other AutoLISP
argument, structurally convert it to a CL form and evaluate it. The primary
value is converted back to an AutoLISP object. Errors follow *CLAL-ON-ERROR*."
  (cond
    ((not argp) (%clal-repl))
    ((typep arg 'autolisp-string)
     (let ((source (autolisp-string-value arg)))
       (%clal-guarded (lambda ()
                        (%clal-cl->al (eval (values (read-from-string source))))))))
    (t (%clal-guarded (lambda () (%clal-cl->al (eval (%clal-al->cl arg))))))))

(defun common-lisp-user::clal-common-lisp (&optional (form nil formp))
  "From Common Lisp: with no argument run the dropped CL REPL; with a string,
READ then EVAL it; otherwise EVAL FORM. Returns the raw CL value. Companion in
COMMON-LISP-USER to the AutoLISP CLAL-COMMON-LISP builtin (cl-debugging.issue)."
  (cond
    ((not formp)     (%clal-repl))
    ((stringp form)  (eval (values (read-from-string form))))
    (t               (eval form))))

(defvar *clautolisp-drop-active* nil
  "T while CLAUTOLISPDROP has shadowed CLAL-COMMON-LISP with the builtin.")

(defvar *clautolisp-drop-saved-binding* nil
  "The pre-shadow binding of CLAL-COMMON-LISP as (BOUND-P . FUNCTION), or NIL
when nothing is currently shadowed.")

(defun %clautolisp-drop-name-p (string)
  (and (stringp string) (string-equal string "CLAUTOLISPDROP")))

(defun %apply-clautolisp-drop (level)
  "React to a CLAUTOLISPDROP write (cl-debugging.issue): a non-zero LEVEL shadows
the AutoLISP symbol CLAL-COMMON-LISP with the builtin, saving any user binding;
LEVEL 0 restores that saved binding (or unbinds when there was none). Idempotent
— a write that does not change the shadow state is a no-op, so a user binding is
never overwritten by a redundant (setvar \"CLAUTOLISPDROP\" 1)."
  (let ((symbol (intern-autolisp-symbol "CLAL-COMMON-LISP")))
    (cond
      ((and (not (zerop level)) (not *clautolisp-drop-active*))
       ;; Save the raw cell (value view) so a user binding to either a
       ;; value or a function is preserved (Lisp-1: one cell — the issue's
       ;; "to a value or a function").
       (setf *clautolisp-drop-saved-binding*
             (cons (clautolisp.autolisp-runtime:autolisp-symbol-value-bound-p symbol)
                   (clautolisp.autolisp-runtime:autolisp-symbol-value symbol)))
       (set-autolisp-symbol-function
        symbol (make-core-builtin-subr "CLAL-COMMON-LISP" #'builtin-clal-common-lisp))
       (setf *clautolisp-drop-active* t))
      ((and (zerop level) *clautolisp-drop-active*)
       (destructuring-bind (bound-p . saved) *clautolisp-drop-saved-binding*
         (if bound-p
             (clautolisp.autolisp-runtime:set-autolisp-symbol-value symbol saved)
             (clautolisp.autolisp-runtime:autolisp-makunbound symbol)))
       (setf *clautolisp-drop-saved-binding* nil
             *clautolisp-drop-active* nil)))))

(defun builtin-getvar (name)
  (let ((string (autolisp-string-value (require-string name "GETVAR"))))
    (when (%lispsys-name-p string)
      (%dispatch-lispsys-foreign-dialect-diagnostic "GETVAR"))
    (host-getvar (current-evaluation-host) string)))

(defun builtin-setvar (name value)
  (let ((string (autolisp-string-value (require-string name "SETVAR"))))
    (when (%lispsys-name-p string)
      (%dispatch-lispsys-foreign-dialect-diagnostic "SETVAR")
      (%validate-lispsys-value value))
    (let ((result (host-setvar (current-evaluation-host) string value)))
      (when (%clautolisp-drop-name-p string)
        (%apply-clautolisp-drop
         (%host-sysvar-integer (current-evaluation-host) "CLAUTOLISPDROP" 0)))
      result)))

;;; --- clautolisp extensions (clal-*) -------------------------------
;;;
;;; The CLAL-* prefix marks functions that are NOT documented by
;;; either Autodesk or Bricsys; they are clautolisp-specific helpers
;;; that improve REPL ergonomics without entering the host-namespace
;;; that vendor code might reserve. See autolisp-spec §16 ~clautolisp
;;; Extensions~ for the normative entries.

(defun substring-match-ci-p (needle haystack)
  "True iff NEEDLE occurs in HAYSTACK, case-insensitively."
  (search needle haystack :test #'char-equal))

(defun builtin-clal-sysvar-list ()
  "Return the sorted list of sysvar-name strings known to the host."
  (mapcar #'make-autolisp-string
          (host-sysvar-names (current-evaluation-host))))

(defun builtin-clal-sysvar-apropos (pattern)
  "Return the subset of (clal-sysvar-list) whose names contain
PATTERN as a case-insensitive substring. PATTERN is an AutoLISP
string; the comparison is case-insensitive so (clal-sysvar-apropos
\"ang\") and (clal-sysvar-apropos \"ANG\") return the same list."
  (let* ((needle (autolisp-string-value (require-string pattern "CLAL-SYSVAR-APROPOS")))
         (all    (host-sysvar-names (current-evaluation-host))))
    (mapcar #'make-autolisp-string
            (remove-if-not (lambda (name)
                             (substring-match-ci-p needle name))
                           all))))

(defun %codepage-canonical-known-p (raw)
  "True when RAW is a codepage / encoding spelling clautolisp can map
to its canonical form (CP-NNNN / Unicode / ANSI). Used to gate
ENC-UNKNOWN-CODEPAGE emission so we don't fire on every pass-through
of an already-known UTF-* / ISO-* / etc. spelling."
  (or (null raw)
      (zerop (length raw))
      (and (>= (length raw) 3) (string-equal "CP-" raw :end2 3))
      (and (>= (length raw) 5) (string-equal "ANSI_" raw :end2 5))
      (and (>= (length raw) 8) (string-equal "WINDOWS-" raw :end2 8))
      (and (>= (length raw) 3)
           (string-equal "CP" raw :end2 2)
           (every #'digit-char-p (subseq raw 2)))
      (string-equal raw "ANSI")
      (string-equal raw "MBCS")
      (string-equal raw "US-ASCII")
      (string-equal raw "ASCII")
      (and (>= (length raw) 4) (string-equal "UTF-" raw :end2 4))
      (and (>= (length raw) 4) (string-equal "UTF8" raw :end2 4))
      (and (>= (length raw) 4) (string-equal "ISO-" raw :end2 4))))

(defun %canonical-codepage-string (raw)
  "Map a SYSCODEPAGE / DWGCODEPAGE-form string to the clautolisp
canonical form (`CP-NNNN' / `UTF-8' / `ISO-8859-1' / `US-ASCII' /
`ANSI'). Vendor strings (`ANSI_1252', `WINDOWS-1252', `CP1252')
collapse onto `CP-1252'; encoding names already in canonical form
pass through unchanged; the empty string maps to `ANSI' to
preserve the \"host-dependent\" placeholder semantics.

Emits ENC-UNKNOWN-CODEPAGE for spellings clautolisp does not
recognise (typos, vendor-specific aliases not in the table). The
helper still returns the input string so downstream code keeps
working — the diagnostic is purely informational, matching the
fall-back behaviour the spec mandates.

See issues/closed/encoding-dispatch.issue, section `Code pages: the
ANSI row, expanded'."
  (cond
    ((null raw) "ANSI")
    ((zerop (length raw)) "ANSI")
    ;; Already in clautolisp canonical form.
    ((and (>= (length raw) 3)
          (string-equal "CP-" raw :end2 3))
     raw)
    ;; Vendor "ANSI_NNNN" → "CP-NNNN".
    ((and (>= (length raw) 5)
          (string-equal "ANSI_" raw :end2 5))
     (concatenate 'string "CP-" (subseq raw 5)))
    ;; clautolisp canonical encoding name "WINDOWS-NNNN" → "CP-NNNN".
    ((and (>= (length raw) 8)
          (string-equal "WINDOWS-" raw :end2 8))
     (concatenate 'string "CP-" (subseq raw 8)))
    ;; Bare "CPNNNN" (no hyphen) → "CP-NNNN".
    ((and (>= (length raw) 3)
          (string-equal "CP" raw :end2 2)
          (every #'digit-char-p (subseq raw 2)))
     (concatenate 'string "CP-" (subseq raw 2)))
    ;; Unicode / ASCII / other already-canonical names — pass through.
    (t
     (unless (%codepage-canonical-known-p raw)
       (clautolisp.autolisp-runtime:signal-encoding-diagnostic
        :enc-unknown-codepage
        "Codepage ~S is not recognised by clautolisp; falling back to it as-is."
        raw))
     raw)))

(defun %host-sysvar-string (host name)
  "Fetch a string-valued sysvar from HOST and return it as a CL
string (unwrapping the autolisp-string wrapper applied by
present-sysvar-value). Returns nil when the sysvar is absent or
its value is not a string."
  (let ((raw (host-getvar host name)))
    (cond
      ((null raw) nil)
      ((typep raw 'autolisp-string) (autolisp-string-value raw))
      ((stringp raw) raw)
      (t nil))))

(defun builtin-clal-system-codepage ()
  "Wrap (getvar \"SYSCODEPAGE\") and return the canonical clautolisp
codepage spelling (`CP-1252', `UTF-8', `ANSI', …). The raw sysvar
may carry the vendor `ANSI_1252' form on a CAD-process bridge or
the clautolisp `WINDOWS-1252' / `UTF-8' form when the in-process
engine is running; both collapse onto the same canonical answer."
  (let ((host (current-evaluation-host)))
    (make-autolisp-string
     (%canonical-codepage-string (%host-sysvar-string host "SYSCODEPAGE")))))

(defun builtin-clal-drawing-codepage ()
  "Wrap (getvar \"DWGCODEPAGE\") and return the canonical clautolisp
codepage spelling, same vocabulary as CLAL-SYSTEM-CODEPAGE.
Defaults to SYSCODEPAGE when no drawing has been loaded — the
catalogue-time default the launch wiring writes through."
  (let ((host (current-evaluation-host)))
    (make-autolisp-string
     (%canonical-codepage-string (%host-sysvar-string host "DWGCODEPAGE")))))

(defun builtin-clal-codepage-mismatch-p ()
  "Return T when the canonical DWGCODEPAGE differs from the
canonical SYSCODEPAGE, nil otherwise. Cheap defensive check
before loading drawing-authored text: a mismatch means strings
authored under one ANSI codepage may garble when interpreted
under another."
  (let* ((host (current-evaluation-host))
         (sys (%canonical-codepage-string
               (%host-sysvar-string host "SYSCODEPAGE")))
         (dwg (%canonical-codepage-string
               (%host-sysvar-string host "DWGCODEPAGE"))))
    (if (string= sys dwg) nil (intern-autolisp-symbol "T"))))

;;; --- aldo debugger configuration (CLAL-*-ALDO-CONFIGURATION) -------
;;;
;;; The canonical configuration store is the AutoLISP global variable
;;; *CLAL-ALDO-CONFIGURATION* (command reference §8): an assoc-list of
;;; (KEY . VALUE) read at start-up from $XDG_CONFIG_HOME/clautolisp/aldo.conf
;;; (or searched along $XDG_CONFIG_DIRS), saved only on request. Persistence
;;; lives here, self-contained (the AutoLISP reader/printer + files); the
;;; debugger reads settings from the variable.

(defparameter +clal-aldo-configuration-symbol-name+ "*CLAL-ALDO-CONFIGURATION*")

(defparameter +default-aldo-configuration-source+
  "((navigator . sexp)
    (navigation-history-max . 1000)
    (break-on-caught . nil)
    (source-window-height . 24)
    (value-line-width . 72)
    (pager . on)
    (pager-height . 24)
    (theme . unicode)
    (default-user-interface . tui)
    (default-aldb-listening-address . \"127.0.0.1\")
    (default-aldb-listening-port . 4301)
    (decorations
      (current-pp  unicode (9205))
      (current-pp  ascii   \">\")
      (enabled-bp  unicode (9208))
      (enabled-bp  ascii   \"^\")
      (disabled-bp unicode (9199))
      (disabled-bp ascii   \"_\")
      (selection   unicode (12304) (12305))
      (selection   ascii   \"[\" \"]\")))"
  "The default aldo configuration, as AutoLISP source; read into runtime values
by the AutoLISP reader.")

(defun aldo-config-symbol ()
  (intern-autolisp-symbol +clal-aldo-configuration-symbol-name+))

(defun default-aldo-configuration-value ()
  "The default configuration as AutoLISP runtime data."
  (first (clautolisp.autolisp-runtime:read-runtime-from-string
          +default-aldo-configuration-source+ :source-name "aldo-default")))

(defun aldo-configuration-value ()
  "The current value of *CLAL-ALDO-CONFIGURATION*; lazily seeds and returns the
default when the variable is unbound."
  (let ((sym (aldo-config-symbol)))
    (if (autolisp-symbol-value-bound-p sym)
        (autolisp-symbol-value sym)
        (let ((default (default-aldo-configuration-value)))
          (clautolisp.autolisp-runtime:set-variable sym default)
          default))))

(defun %aldo-getenv (name)
  (let ((v (uiop:getenv name))) (if (and v (plusp (length v))) v nil)))

(defun aldo-xdg-config-home ()
  (or (%aldo-getenv "XDG_CONFIG_HOME")
      (namestring (merge-pathnames ".config/" (user-homedir-pathname)))))

(defun aldo-xdg-config-dirs ()
  (loop :for part :in (uiop:split-string (or (%aldo-getenv "XDG_CONFIG_DIRS") "/etc/xdg")
                                         :separator ":")
        :when (plusp (length part)) :collect part))

(defun aldo-config-relative-path ()
  (make-pathname :directory '(:relative "clautolisp") :name "aldo" :type "conf"))

(defun aldo-config-save-path ()
  (merge-pathnames (aldo-config-relative-path)
                   (uiop:ensure-directory-pathname (aldo-xdg-config-home))))

(defun aldo-config-load-path ()
  "The save path if it exists, else the first clautolisp/aldo.conf along
$XDG_CONFIG_DIRS, or NIL."
  (let ((home (aldo-config-save-path)))
    (if (probe-file home)
        home
        (loop :for dir :in (aldo-xdg-config-dirs)
              :for path := (merge-pathnames (aldo-config-relative-path)
                                            (uiop:ensure-directory-pathname dir))
              :when (probe-file path) :return path))))

(defun load-aldo-configuration-from (path)
  "Read the configuration from PATH (an AutoLISP sexp) and set
*CLAL-ALDO-CONFIGURATION*; return the new value, or nil if PATH is missing."
  (when (and path (probe-file path))
    (let ((value (first (clautolisp.autolisp-runtime:read-runtime-from-string
                         (uiop:read-file-string path)
                         :source-name (namestring path)))))
      (clautolisp.autolisp-runtime:set-variable (aldo-config-symbol) value)
      value)))

(defun save-aldo-configuration-to (path)
  "Write *CLAL-ALDO-CONFIGURATION* to PATH as an AutoLISP sexp (UTF-8); return
the path string (an AutoLISP string)."
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output :if-exists :supersede
                            :if-does-not-exist :create :external-format :utf-8)
    (write-string (autolisp-value->string (aldo-configuration-value) t) out)
    (terpri out))
  (make-autolisp-string (namestring path)))

(defun builtin-clal-load-aldo-configuration ()
  "Read *CLAL-ALDO-CONFIGURATION* from the available XDG aldo.conf and set the
variable; return the new value, or nil if no configuration file was found."
  (load-aldo-configuration-from (aldo-config-load-path)))

(defun builtin-clal-save-aldo-configuration ()
  "Write *CLAL-ALDO-CONFIGURATION* to $XDG_CONFIG_HOME/clautolisp/aldo.conf as
an AutoLISP sexp (UTF-8); return the path string."
  (save-aldo-configuration-to (aldo-config-save-path)))

(defun builtin-clal-break ()
  "Drop into the aldo debugger at the current poll point when a debug session is
active; a no-op otherwise (debugger command reference §1, programmatic entry).
Returns nil."
  (when clautolisp.autolisp-runtime:*debug-break-hook*
    (funcall clautolisp.autolisp-runtime:*debug-break-hook* nil))
  nil)

(defun builtin-clal-invoke-debugger (&optional message)
  "Like CLAL-BREAK, but show MESSAGE at the stop (debugger command reference §1).
Returns nil."
  (when clautolisp.autolisp-runtime:*debug-break-hook*
    (funcall clautolisp.autolisp-runtime:*debug-break-hook* message))
  nil)

(defun %clal-nav-name-string (value operator)
  "Coerce VALUE (a symbol or string) to a name string for the CLAL-NAV-* builtins."
  (cond
    ((typep value 'autolisp-symbol) (autolisp-symbol-name value))
    ((typep value 'autolisp-string) (autolisp-string-value value))
    (t (signal-builtin-argument-error
        :bad-argument operator "Expected a symbol or string, got ~S." value))))

(defun builtin-clal-nav-function (name)
  "Enter the aldo debugger navigating the source form of the global function
NAME — a symbol or a string (pre-debug navigation, aldo-pre-debug.issue). Lets
you observe a function and set breakpoints before it is ever called; the
function is instrumented on demand. A no-op (returns nil) unless a debug session
is active."
  (let ((string (%clal-nav-name-string name "CLAL-NAV-FUNCTION")))
    (when clautolisp.autolisp-runtime:*debug-nav-hook*
      (funcall clautolisp.autolisp-runtime:*debug-nav-hook* (list :function string))))
  nil)

(defun builtin-clal-nav-file (path &optional line)
  "Enter the aldo debugger navigating the top-level forms of the file PATH (a
string), starting at the form on or containing LINE (an integer) when given
(aldo-pre-debug.issue). A no-op (returns nil) unless a debug session is active."
  (let ((string (%clal-nav-name-string path "CLAL-NAV-FILE"))
        (line-n (cond ((null line) nil)
                      ((integerp line) line)
                      (t (signal-builtin-argument-error
                          :bad-argument "CLAL-NAV-FILE"
                          "LINE must be an integer, got ~S." line)))))
    (when clautolisp.autolisp-runtime:*debug-nav-hook*
      (funcall clautolisp.autolisp-runtime:*debug-nav-hook* (list :file string line-n))))
  nil)

(defun builtin-clal-nav-directory (&optional path)
  "Enter the aldo debugger browsing the directory PATH (a string; the current
directory when omitted), so you can walk the file system and enter files
(aldo-pre-debug.issue). A no-op (returns nil) unless a debug session is active."
  (let ((string (and path (%clal-nav-name-string path "CLAL-NAV-DIRECTORY"))))
    (when clautolisp.autolisp-runtime:*debug-nav-hook*
      (funcall clautolisp.autolisp-runtime:*debug-nav-hook* (list :directory string))))
  nil)

(defun builtin-clal-select-file (path line)
  "Select PATH:LINE as the source the debugger's `ls' command shows
(aldo-pre-debug.issue). Returns nil."
  (let ((string (%clal-nav-name-string path "CLAL-SELECT-FILE"))
        (line-n (if (integerp line) line
                    (signal-builtin-argument-error
                     :bad-argument "CLAL-SELECT-FILE"
                     "LINE must be an integer, got ~S." line))))
    (when clautolisp.autolisp-runtime:*debug-select-file-hook*
      (funcall clautolisp.autolisp-runtime:*debug-select-file-hook* string line-n)))
  nil)

(defun builtin-clal-define-debugger-command (names function &optional doc)
  "Register an AutoLISP debugger command (command reference §8). NAMES is a list
(KEY WORD…) of strings (the key must be the word initials, §0); FUNCTION is the
command body, applied to the command's parsed string arguments at dispatch; DOC
an optional help string. A no-op (returns nil) unless the debugger UI is loaded."
  (when clautolisp.autolisp-runtime:*debug-define-command-hook*
    (funcall clautolisp.autolisp-runtime:*debug-define-command-hook*
             (mapcar (lambda (s) (clautolisp.autolisp-runtime:autolisp-string-value s))
                     names)
             (clautolisp.autolisp-runtime:resolve-autolisp-function-designator function)
             (and doc (clautolisp.autolisp-runtime:autolisp-string-value doc))))
  nil)

;;; --- CLAL-SEDIT + CLAL-CLIPBOARD-* (sedit spec §2, §5.4) -------------
;;;
;;; The AutoLISP surface of the sedit structural editor and its clipboard.
;;; An AutoLISP value is bridged to a sedit adorned tree through its SOURCE
;;; TEXT — AUTOLISP-VALUE->STRING to print it, CLAUTOLISP.SEDIT:PARSE-FORM to
;;; read it as a tree, CLAUTOLISP.SEDIT:UNPARSE + AUTOLISP-READ-FROM-STRING to
;;; get a value back — so sedit stays a self-contained, runtime-free library.

(defun %clal-value->node (value)
  "The sedit adorned tree for an AutoLISP VALUE, via its source text."
  (clautolisp.sedit:parse-form (autolisp-value->string value nil)))

(defun %clal-node->value (node)
  "The AutoLISP value a sedit NODE denotes (read from its source text; never
evaluated), or nil for a null node."
  (and node
       (clautolisp.autolisp-runtime:autolisp-read-from-string (clautolisp.sedit:unparse node))))

(defun %clal-sedit-target (object)
  "Resolve the CLAL-SEDIT argument OBJECT to what SEDIT-OPEN expects (spec §2):
NIL -> a stand-alone nil; an AutoLISP symbol -> its (recorded) name to recall; an
AutoLISP string -> a file/directory path; any other value -> a sexp to edit."
  (cond
    ((null object) nil)
    ((typep object 'clautolisp.autolisp-runtime:autolisp-symbol)
     (intern (string-upcase (clautolisp.autolisp-runtime:autolisp-symbol-name object)) :keyword))
    ((typep object 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value object))
    (t (%clal-value->node object))))

(defun %clal-sedit-eval-hook (node)
  "EVAL / MACROEXPAND callback for sedit: evaluate NODE's form in the running
system and return the result as a node."
  (let ((value (clautolisp.autolisp-runtime:autolisp-eval
                (clautolisp.autolisp-runtime:autolisp-read-from-string
                 (clautolisp.sedit:unparse node))
                (clautolisp.autolisp-runtime:current-evaluation-context))))
    (%clal-value->node value)))

(defun %clal-sedit-load-hook (path)
  "LOAD callback for sedit: evaluate the forms of file PATH into the running
system (installing an edited definition, spec §5.7)."
  (let ((ctx (clautolisp.autolisp-runtime:current-evaluation-context)))
    (dolist (form (clautolisp.autolisp-runtime:read-runtime-from-string (uiop:read-file-string path)))
      (clautolisp.autolisp-runtime:autolisp-eval form ctx))))

(defun builtin-clal-sedit (&optional object)
  "Edit OBJECT with the sedit structural editor (spec §2): no argument -> a
stand-alone form starting at nil; a symbol -> recall its recorded definition; a
string -> a file or directory path; any other value -> edited as a sexp. Runs the
interactive editor on the terminal and returns the edited object. Sets
CLAUTOLISP.SEDIT:*CLAL-SEDIT-INITIAL-FORM* / *CLAL-SEDIT-LAST-RESULT*."
  (let* ((session (clautolisp.sedit:sedit-open (%clal-sedit-target object)
                                               :recording (clautolisp.sedit:sedit-recording)))
         (result (clautolisp.sedit:sedit-run session
                                             :input *standard-input* :output *standard-output*
                                             :eval-hook #'%clal-sedit-eval-hook
                                             :load-hook #'%clal-sedit-load-hook)))
    (%clal-node->value result)))

(defun builtin-clal-clipboard-put-text (string)
  "Set the system clipboard to STRING (clipboard-interface.org). Returns T on
success, nil otherwise."
  (if (clautolisp.sedit:clipboard-put-text
       (%clal-nav-name-string string "CLAL-CLIPBOARD-PUT-TEXT"))
      (clautolisp.autolisp-runtime:intern-autolisp-symbol "T")
      nil))

(defun builtin-clal-clipboard-get-text ()
  "Return the system clipboard contents as a string, or nil when it is empty or
unreadable."
  (let ((text (clautolisp.sedit:clipboard-get-text)))
    (and text (clautolisp.autolisp-runtime:make-autolisp-string text))))

(defun builtin-clal-clipboard-copy-sexp (value)
  "Copy VALUE to the clipboard (spec §5.4): its source text goes to the system
clipboard and the object to *clal-clipboard*. Returns nil."
  (clautolisp.sedit:clipboard-copy-node (%clal-value->node value))
  nil)

(defun builtin-clal-clipboard-paste-sexp ()
  "Return the clipboard contents parsed back into an AutoLISP object (never
evaluated — a foreign #.() cannot run): the system clipboard when available, else
the in-process *clipboard* (clipboard-interface.org §Public API). Nil when both
are empty."
  (%clal-node->value (clautolisp.sedit:clipboard-paste-node clautolisp.sedit:*clipboard*)))

;;; --- CLAL-OPTIMIZE / CLAL-OPTIMIZATION -------------------------------
;;;
;;; The optimization qualities (debugger-public-interface issue Part A) gate
;;; how EVAL and CLAL-COMPILE build a function's forks: DEBUG > 0 weaves the
;;; instrumented fork (the poll points that stepping and breakpoints ride on),
;;; SPACE trades that fork away for size, and SPEED would compile to CL — Tier 2,
;;; pinned at 0 until the compiler-to-CL lands. Levels are 0..3 (SPEED aside,
;;; the interpreter treats any non-zero DEBUG as "instrument", 3=2=1).

(defparameter *clal-optimization-qualities* '(:debug :space :speed)
  "The optimization qualities, in canonical print order.")

(defparameter *clal-optimization*
  (list (cons :debug 3) (cons :space 0) (cons :speed 0))
  "Current optimization qualities as an alist QUALITY -> level (0..3). Read by
EVAL / CLAL-COMPILE to choose the fork(s) to build; set by CLAL-OPTIMIZE.")

(defun clal-optimization-level (quality)
  "The current level (0..3) of QUALITY (:debug / :space / :speed)."
  (or (cdr (assoc quality *clal-optimization*)) 0))

(defun %clal-quality-keyword (name)
  "Map a quality NAME string (any case) to its keyword, or NIL if unknown."
  (cond ((string-equal name "DEBUG") :debug)
        ((string-equal name "SPACE") :space)
        ((string-equal name "SPEED") :speed)))

(defun %clal-optimization->autolisp ()
  "The current qualities as the AutoLISP list ((DEBUG n) (SPACE n) (SPEED n))."
  (mapcar (lambda (quality)
            (list (intern-autolisp-symbol (string-upcase (symbol-name quality)))
                  (clal-optimization-level quality)))
          *clal-optimization-qualities*))

(defun builtin-clal-optimization ()
  "Return the current optimization qualities as ((DEBUG n) (SPACE n) (SPEED n))
(debugger-public-interface issue Part A). SPEED is pinned at 0 until the
compiler-to-CL (Tier 2)."
  (%clal-optimization->autolisp))

(defun %clal-parse-optimize-element (element)
  "Parse and apply one CLAL-OPTIMIZE specifier — a bare quality symbol (level 3)
or a list (SYMBOL LEVEL). Signals on an unknown quality or an out-of-range level."
  (multiple-value-bind (symbol level)
      (cond
        ((typep element 'autolisp-symbol) (values element 3))
        ((and (consp element) (typep (first element) 'autolisp-symbol))
         (let ((lvl (second element)))
           (unless (typep lvl '(integer 0 3))
             (signal-builtin-argument-error
              :bad-argument "CLAL-OPTIMIZE"
              "Optimization level must be an integer 0..3, got ~S." lvl))
           (values (first element) lvl)))
        (t (signal-builtin-argument-error
            :bad-argument "CLAL-OPTIMIZE"
            "Expected a quality symbol or (SYMBOL LEVEL), got ~S." element)))
    (let ((quality (%clal-quality-keyword (autolisp-symbol-name symbol))))
      (unless quality
        (signal-builtin-argument-error
         :bad-argument "CLAL-OPTIMIZE"
         "Unknown optimization quality ~A (expected DEBUG, SPACE or SPEED)."
         (autolisp-symbol-name symbol)))
      (setf (cdr (assoc quality *clal-optimization*)) level))))

(defun builtin-clal-optimize (qualities)
  "Set the optimization qualities (debugger-public-interface issue Part A).
QUALITIES is an AutoLISP list; each element is a bare quality symbol (= level 3)
or (SYMBOL LEVEL). Unmentioned qualities keep their current level. SPEED is
pinned at 0 (Tier 2, no compiler-to-CL yet). Returns the new qualities."
  (require-proper-list qualities "CLAL-OPTIMIZE")
  (dolist (element qualities)
    (%clal-parse-optimize-element element))
  (setf (cdr (assoc :speed *clal-optimization*)) 0) ; pinned until Tier 2
  ;; Reflect DEBUG into the runtime instrumentation gate: DEBUG>0 weaves
  ;; instrumented forks under a session, DEBUG 0 (SPACE mode) runs plain.
  (setf clautolisp.autolisp-runtime:*debug-instrumentation-enabled*
        (plusp (clal-optimization-level :debug)))
  (%clal-optimization->autolisp))

(defun builtin-clal-compile (name lambda-expression)
  "Compile LAMBDA-EXPRESSION — a (LAMBDA lambda-list . body) form — into an
applicable function object, weaving its instrumented fork when the current
CLAL-OPTIMIZATION has DEBUG>0 (debugger-public-interface issue Part A, the
compiled-eval core). NAME is nil (anonymous) or a symbol naming the function.
Returns the function object."
  (unless (and (consp lambda-expression)
               (typep (first lambda-expression) 'autolisp-symbol)
               (string-equal (autolisp-symbol-name (first lambda-expression)) "LAMBDA"))
    (signal-builtin-argument-error
     :bad-argument "CLAL-COMPILE"
     "Expected a (LAMBDA lambda-list . body) form, got ~S." lambda-expression))
  (let* ((name-string
           (cond ((null name) "")
                 ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
                 (t (signal-builtin-argument-error
                     :bad-argument "CLAL-COMPILE"
                     "CLAL-COMPILE name must be nil or a symbol, got ~S." name))))
         (lambda-list (second lambda-expression))
         (body (cddr lambda-expression))
         (usubr (clautolisp.autolisp-runtime:make-autolisp-usubr
                 name-string lambda-list body
                 (clautolisp.autolisp-runtime:current-evaluation-context))))
    (when (and (plusp (clal-optimization-level :debug))
               clautolisp.autolisp-runtime:*instrument-usubr-hook*)
      (ignore-errors
       (funcall clautolisp.autolisp-runtime:*instrument-usubr-hook* usubr)))
    usubr))

(defun set-drawing-codepage (new-codepage-value)
  "Update the host's DWGCODEPAGE sysvar AND emit
ENC-CODEPAGE-MISMATCH when the canonicalised new value differs
from the current SYSCODEPAGE. Intended hook for drawing-load
paths: when the runtime reads a DWG codepage header it calls
through here so user code that loaded a Czech-authored drawing
on a French host sees the diagnostic at load time, not at
text-decode time.

The plain HOST-SET-DERIVED-SYSVAR bypass remains the right entry
point for launch-time DWGCODEPAGE seeding (which always matches
SYSCODEPAGE) — only the drawing-side update routes through here.
NEW-CODEPAGE-VALUE is a CL string."
  (let* ((host (current-evaluation-host))
         (sys-raw (%host-sysvar-string host "SYSCODEPAGE"))
         (sys-canonical (%canonical-codepage-string sys-raw))
         (new-canonical (%canonical-codepage-string new-codepage-value)))
    (unless (string= sys-canonical new-canonical)
      (clautolisp.autolisp-runtime:signal-encoding-diagnostic
       :enc-codepage-mismatch
       "DWGCODEPAGE (~S) differs from SYSCODEPAGE (~S); strings authored under the drawing's codepage may garble when interpreted under the host's."
       new-canonical sys-canonical))
    (clautolisp.autolisp-host:host-set-derived-sysvar
     host "DWGCODEPAGE" new-codepage-value)
    new-canonical))

(defun %sniff-file-bom (path)
  "Read the first four bytes of PATH (silently truncating to fewer
when the file is shorter) and return the canonical clautolisp
encoding name corresponding to the leading byte-order mark, or
nil when no BOM is found. Used by BUILTIN-CLAL-FILE-ENCODING.

Recognised BOMs (encoding-dispatch.issue cross-dialect table):

  FF FE 00 00          -> \"UTF-32-LE\"   (checked before UTF-16 LE)
  00 00 FE FF          -> \"UTF-32-BE\"
  FF FE                -> \"UTF-16-LE\"
  FE FF                -> \"UTF-16-BE\"
  EF BB BF             -> \"UTF-8-BOM\"

Note the UTF-32 LE / UTF-16 LE prefix ambiguity: UTF-32-LE starts
with the same two bytes as UTF-16-LE, distinguished only by the
following 00 00. Test UTF-32 first."
  (handler-case
      (with-open-file (in path :direction :input
                               :element-type '(unsigned-byte 8)
                               :if-does-not-exist nil)
        (when in
          (let ((header (make-array 4 :element-type '(unsigned-byte 8)
                                      :initial-element 0))
                (read-count 0))
            (setf read-count (read-sequence header in))
            (cond
              ;; UTF-32-LE: FF FE 00 00 — checked first because it
              ;; subsumes UTF-16-LE's two-byte prefix.
              ((and (>= read-count 4)
                    (= (aref header 0) #xFF)
                    (= (aref header 1) #xFE)
                    (= (aref header 2) #x00)
                    (= (aref header 3) #x00))
               "UTF-32-LE")
              ;; UTF-32-BE: 00 00 FE FF.
              ((and (>= read-count 4)
                    (= (aref header 0) #x00)
                    (= (aref header 1) #x00)
                    (= (aref header 2) #xFE)
                    (= (aref header 3) #xFF))
               "UTF-32-BE")
              ;; UTF-16-LE: FF FE (after UTF-32-LE eliminated).
              ((and (>= read-count 2)
                    (= (aref header 0) #xFF)
                    (= (aref header 1) #xFE))
               "UTF-16-LE")
              ;; UTF-16-BE: FE FF.
              ((and (>= read-count 2)
                    (= (aref header 0) #xFE)
                    (= (aref header 1) #xFF))
               "UTF-16-BE")
              ;; UTF-8 BOM: EF BB BF.
              ((and (>= read-count 3)
                    (= (aref header 0) #xEF)
                    (= (aref header 1) #xBB)
                    (= (aref header 2) #xBF))
               "UTF-8-BOM")
              (t nil)))))
    (error () nil)))

(defun %coerce-enc-code-designator (value operator-name)
  "Coerce VALUE to one of *ENC-DIAGNOSTIC-CODES*. Accepts an
autolisp-string or autolisp-symbol (string designator); the name
is upcased, ensured to begin with `ENC-', and interned in the
KEYWORD package. Signals :invalid-enc-code-argument for unknown
codes."
  (let* ((raw (cond
                ((typep value 'autolisp-string) (autolisp-string-value value))
                ((typep value 'autolisp-symbol) (autolisp-symbol-name value))
                (t
                 (signal-builtin-argument-error
                  :invalid-string-argument
                  operator-name
                  "~A expects an encoding-diagnostic code as a symbol or string, got ~S."
                  operator-name value))))
         (upcased (string-upcase raw))
         (prefixed (if (and (>= (length upcased) 4)
                            (string= "ENC-" upcased :end2 4))
                       upcased
                       (concatenate 'string "ENC-" upcased)))
         (keyword (intern prefixed "KEYWORD")))
    (unless (member keyword clautolisp.autolisp-runtime:*enc-diagnostic-codes*)
      (signal-builtin-argument-error
       :invalid-enc-code-argument
       operator-name
       "~A: ~S is not a recognised encoding-diagnostic code (expected one of ~{~A~^, ~})."
       operator-name raw
       (mapcar #'symbol-name clautolisp.autolisp-runtime:*enc-diagnostic-codes*)))
    keyword))

(defun %lint-form-name-p (form name)
  "True when FORM is a call to NAME (an upper-case string).
Accepts FORM as a CL cons cell whose CAR is an autolisp-symbol
with SYMBOL-NAME matching NAME case-insensitively."
  (and (consp form)
       (typep (car form) 'autolisp-symbol)
       (string-equal name (autolisp-symbol-name (car form)))))

(defun %lint-string-literal-value (form)
  "Return the underlying CL string when FORM is a literal
autolisp-string; nil otherwise. Used by the linter to read off
encoding-name literals in OPEN / LOAD calls."
  (when (typep form 'autolisp-string)
    (autolisp-string-value form)))

(defun %lint-one-form (form)
  "Inspect a single AutoLISP form for encoding extensions and
emit the matching enc-* diagnostic via SIGNAL-ENCODING-DIAGNOSTIC
(which already respects the dialect / pragma / lax gates). Used
by BUILTIN-CLAL-LINT-ENCODING-EXTENSIONS to walk a form-tree.

Recognised forms:
- (load FILE [ONFAILURE [ENCODING]])
- (open FILE MODE [ENCODING]) — both AutoCAD literal vocab and
  clautolisp's broader set.
- (open FILE MODE,ccs=ENC ...) — BricsCAD form, mode-string contains
  the ,ccs= suffix.
- (getvar \"LISPSYS\") / (setvar \"LISPSYS\" ...) — LISPSYS access."
  (cond
    ;; (load filename [onfailure [encoding]])
    ((and (%lint-form-name-p form "LOAD")
          (>= (length form) 4))
     (let ((encoding (%lint-string-literal-value (fourth form))))
       (when encoding
         (%dispatch-load-encoding-diagnostic encoding))))
    ;; (open filename mode [encoding])
    ((and (%lint-form-name-p form "OPEN")
          (>= (length form) 3))
     (let ((mode (%lint-string-literal-value (third form)))
           (encoding (and (>= (length form) 4)
                          (%lint-string-literal-value (fourth form)))))
       (when mode
         (multiple-value-bind (base ccs) (%split-bricscad-mode-suffix mode)
           (declare (ignore base))
           (when ccs
             (%dispatch-open-encoding-diagnostic :ccs-suffix ccs))))
       (when encoding
         (%dispatch-open-encoding-diagnostic
          (if (%autocad-encoding-literal-p encoding)
              :positional-autocad
              :positional-clautolisp)
          encoding))))
    ;; (getvar "LISPSYS") / (setvar "LISPSYS" ...)
    ((or (%lint-form-name-p form "GETVAR")
         (%lint-form-name-p form "SETVAR"))
     (let ((name (%lint-string-literal-value (second form))))
       (when (%lispsys-name-p name)
         (%dispatch-lispsys-foreign-dialect-diagnostic
          (autolisp-symbol-name (car form))))))))

(defun %lint-form-tree (form)
  "Walk FORM recursively, calling %LINT-ONE-FORM on each cons.
Atoms are skipped."
  (when (consp form)
    (%lint-one-form form)
    (dolist (sub form)
      (%lint-form-tree sub))))

(defun builtin-clal-lint-encoding-extensions (form)
  "Walk FORM (a parsed AutoLISP s-expression) and emit
encoding-dispatch diagnostics for every encoding-extension call
site found. The dialect / pragma / --lax gates apply normally; a
clean form-tree emits nothing.

Recognised: (load … encoding), (open … encoding), (open … ',ccs=…'),
(getvar / setvar \"LISPSYS\"). User code can pipe a file's parsed
form-tree through this builtin before evaluation to catch
encoding-extension uses statically.

Returns T (matches the AutoLISP convention that mutators / linters
return T on completion); the diagnostics are the user-visible
output."
  (%lint-form-tree form)
  (intern-autolisp-symbol "T"))

(defun builtin-clal-suppress-enc-diagnostic (&rest codes)
  "Add each CODE in CODES to the active per-code suppression list.
CODES are string designators (autolisp-string or autolisp-symbol);
each is canonicalised to a :enc-NAME keyword. Subsequent
SIGNAL-ENCODING-DIAGNOSTIC calls with a matching code emit
nothing.

Returns the (possibly truncated) list of currently-suppressed
codes as a list of AutoLISP strings.

Pragma usage at the top of a source file:

  (clal-suppress-enc-diagnostic 'enc-extension-used 'enc-foreign-dialect)

The suppression is dynamically scoped to the running AutoLISP
session — it persists across LOAD / OPEN until the user calls
CLAL-ENABLE-ENC-DIAGNOSTIC."
  (dolist (code codes)
    (let ((keyword (%coerce-enc-code-designator
                    code "CLAL-SUPPRESS-ENC-DIAGNOSTIC")))
      (pushnew keyword clautolisp.autolisp-runtime:*enc-diagnostic-suppress-codes*)))
  (mapcar (lambda (kw)
            (make-autolisp-string (string-downcase (symbol-name kw))))
          clautolisp.autolisp-runtime:*enc-diagnostic-suppress-codes*))

(defun builtin-clal-enable-enc-diagnostic (&rest codes)
  "Undo CLAL-SUPPRESS-ENC-DIAGNOSTIC for each CODE in CODES.
Returns the (possibly empty) list of currently-suppressed codes
as a list of AutoLISP strings. Called with no arguments, removes
EVERY code from the suppression list (re-enable everything)."
  (cond
    ((null codes)
     (setf clautolisp.autolisp-runtime:*enc-diagnostic-suppress-codes* nil))
    (t
     (dolist (code codes)
       (let ((keyword (%coerce-enc-code-designator
                       code "CLAL-ENABLE-ENC-DIAGNOSTIC")))
         (setf clautolisp.autolisp-runtime:*enc-diagnostic-suppress-codes*
               (remove keyword
                       clautolisp.autolisp-runtime:*enc-diagnostic-suppress-codes*))))))
  (mapcar (lambda (kw)
            (make-autolisp-string (string-downcase (symbol-name kw))))
          clautolisp.autolisp-runtime:*enc-diagnostic-suppress-codes*))

(defun builtin-clal-file-encoding (filename)
  "Sniff FILENAME for a byte-order mark and return the canonical
clautolisp encoding name as a string. Mirrors BricsCAD's
VLE-FILE-ENCODING but uses the clautolisp vocabulary (UTF-8-BOM,
UTF-16-LE, UTF-16-BE, UTF-32-LE, UTF-32-BE).

Returns \"ANSI\" when no BOM is detected — the file might be
UTF-8-without-BOM, ANSI, or anything else; without a marker the
encoding is undetermined and falls back to the host code page.
Returns nil-equivalent (\"\" wrapped as autolisp-string is the
caller-visible nil substitute) when the file does not exist or is
unreadable; the runtime's standard file-error handling surfaces
the underlying signal.

The clautolisp-only piece (compared with VLE-FILE-ENCODING) is the
UTF-8-BOM distinction: BricsCAD reports plain \"UTF-8\" for both
the BOM and no-BOM cases. The helper preserves the distinction so
user code can choose between rewriting the BOM and dropping it."
  (let* ((path-string (autolisp-string-value
                       (require-string filename "CLAL-FILE-ENCODING")))
         (resolved (resolve-load-pathname path-string)))
    (cond
      ((null resolved)
       (set-autolisp-errno 73)
       nil)
      (t
       (let ((sniffed (%sniff-file-bom (namestring resolved))))
         (set-autolisp-errno 0)
         (make-autolisp-string (or sniffed "ANSI")))))))

(defun %native-module-extension ()
  "Return the running host OS's native shared-library extension,
leading dot included: \".dll\" on Windows, \".dylib\" on macOS,
\".so\" on Linux and everywhere else. Resolved at RUN time (not
read/build time) so an image built in one environment reports the
extension of the environment it actually runs in."
  (cond
    ((uiop:os-windows-p) ".dll")
    ((uiop:os-macosx-p)  ".dylib")
    (t                   ".so")))

(defun builtin-clal-module-extension (kind)
  "Return, as a string with leading dot, the file extension clautolisp
uses for a packaged-artefact KIND on the current host — so portability
layers query clautolisp instead of hard-coding a guess. KIND is a
string, matched case-insensitively:

  \"compiled-app\"   => \".lap\"  (\"Lisp APplication\" — the clautolisp
                                   analogue of AutoCAD .vlx / BricsCAD
                                   .des; clautolisp owns the name).
  \"native-module\"  => the host OS shared-library extension
                        (\".dll\" Windows / \".dylib\" macOS / \".so\"
                        else). A clautolisp native module is a shared
                        library loaded by the host CL, so the extension
                        is OS-dependent — the .arx / .brx slot.

Signals :invalid-module-kind on any other KIND. See
issues/open/clautolisp-module-app-extensions.issue."
  (let ((k (string-downcase
            (autolisp-string-value
             (require-string kind "CLAL-MODULE-EXTENSION")))))
    (cond
      ((string= k "compiled-app")  (make-autolisp-string ".lap"))
      ((string= k "native-module") (make-autolisp-string
                                    (%native-module-extension)))
      (t (signal-builtin-argument-error
          :invalid-module-kind "CLAL-MODULE-EXTENSION"
          "CLAL-MODULE-EXTENSION expects \"compiled-app\" or ~
\"native-module\", got ~S."
          k)))))

;;; --- Phase 12: headless interaction channel -----------------------

(defun optional-prompt-string (prompt operator-name)
  (cond
    ((null prompt) nil)
    (t (require-string prompt operator-name))))

(defun builtin-initget (&rest arguments)
  ;; (initget [BITS] [KWORD-STRING])
  ;; BITS is an integer; KWORD-STRING is a space-separated list.
  ;; Accepted argument shapes:
  ;;   (initget)
  ;;   (initget BITS)
  ;;   (initget KWORDS)
  ;;   (initget BITS KWORDS)
  (let ((bits 0)
        (keywords '()))
    (cond
      ((null arguments))
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string)
            (setf keywords (split-keyword-string only)))
           ((integerp only) (setf bits only)))))
      (t
       (when (integerp (first arguments)) (setf bits (first arguments)))
       (let ((kw (or (second arguments)
                     (and (typep (first arguments) 'autolisp-string)
                          (first arguments)))))
         (when (typep kw 'autolisp-string)
           (setf keywords (split-keyword-string kw))))))
    (host-initget (current-evaluation-host) bits keywords)))

(defun split-keyword-string (autolisp-string-value)
  (let ((value (autolisp-string-value autolisp-string-value)))
    (let ((result '())
          (start 0))
      (loop for i from 0 below (length value)
            for c = (char value i)
            when (or (char= c #\Space) (char= c #\Tab))
              do (when (< start i)
                   (push (subseq value start i) result))
                 (setf start (1+ i)))
      (when (< start (length value))
        (push (subseq value start) result))
      (nreverse result))))

(defun getstring-terminate-at-space (result)
  ;; AutoLISP getstring with a nil CR flag terminates the input at the
  ;; first blank: (getstring) reading "hello world" yields "hello".
  ;; Line-oriented hosts (e.g. the MockHost) hand back the whole line,
  ;; so we replicate the space-terminates-input semantics here. This is
  ;; a no-op for a live host that already stopped reading at the blank.
  (if (typep result 'autolisp-string)
      (let* ((value (autolisp-string-value result))
             (stop  (position-if (lambda (c) (or (char= c #\Space)
                                                 (char= c #\Tab)))
                                 value)))
        (if stop
            (make-autolisp-string (subseq value 0 stop))
            result))
      result))

(defun builtin-getstring (&optional read-spaces-or-prompt prompt)
  ;; (getstring)                       ; no prompt, spaces terminate input
  ;; (getstring MSG)                   ; MSG is a string prompt, no spaces
  ;; (getstring CR)                    ; CR non-nil flag, no prompt
  ;; (getstring CR MSG)                ; CR flag + prompt string
  ;;
  ;; CR (the "carriage return" flag): when supplied and non-nil the
  ;; response may contain blanks and is only terminated by Enter; when
  ;; nil or omitted a blank terminates the input just like Enter, so the
  ;; returned string cannot contain spaces. See AutoCAD 2026 and
  ;; BricsCAD V22+ getstring references.
  (let* ((first-is-prompt (typep read-spaces-or-prompt 'autolisp-string))
         (read-spaces      (and read-spaces-or-prompt (not first-is-prompt) t))
         (effective-prompt (if first-is-prompt read-spaces-or-prompt prompt))
         (result (host-getstring (current-evaluation-host)
                                 (and effective-prompt
                                      (optional-prompt-string effective-prompt "GETSTRING"))
                                 :controls (list :read-spaces read-spaces))))
    (if read-spaces
        result
        (getstring-terminate-at-space result))))

(defun builtin-getint (&optional prompt)
  (host-getint (current-evaluation-host)
               (and prompt (optional-prompt-string prompt "GETINT"))))

(defun builtin-getreal (&optional prompt)
  (host-getreal (current-evaluation-host)
                (and prompt (optional-prompt-string prompt "GETREAL"))))

(defun builtin-getpoint (&rest arguments)
  ;; (getpoint [BASE] [PROMPT])
  (let (base prompt)
    (cond
      ((null arguments))
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string) (setf prompt only))
           ((listp only) (setf base only)))))
      (t (setf base (first arguments) prompt (second arguments))))
    (host-getpoint (current-evaluation-host)
                   (and prompt (optional-prompt-string prompt "GETPOINT"))
                   :base base)))

(defun builtin-getcorner (base &optional prompt)
  (host-getcorner (current-evaluation-host)
                  (and prompt (optional-prompt-string prompt "GETCORNER"))
                  :base base))

(defun builtin-getdist (&rest arguments)
  ;; (getdist [BASE] [PROMPT])
  (let (base prompt)
    (cond
      ((null arguments))
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string) (setf prompt only))
           ((listp only) (setf base only)))))
      (t (setf base (first arguments) prompt (second arguments))))
    (host-getdist (current-evaluation-host)
                  (and prompt (optional-prompt-string prompt "GETDIST"))
                  :base base)))

(defun builtin-getangle (&rest arguments)
  (let (base prompt)
    (cond
      ((null arguments))
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string) (setf prompt only))
           ((listp only) (setf base only)))))
      (t (setf base (first arguments) prompt (second arguments))))
    (host-getangle (current-evaluation-host)
                   (and prompt (optional-prompt-string prompt "GETANGLE"))
                   :base base)))

(defun builtin-getorient (&rest arguments)
  (let (base prompt)
    (cond
      ((null arguments))
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string) (setf prompt only))
           ((listp only) (setf base only)))))
      (t (setf base (first arguments) prompt (second arguments))))
    (host-getorient (current-evaluation-host)
                    (and prompt (optional-prompt-string prompt "GETORIENT"))
                    :base base)))

(defun builtin-getkword (&optional prompt)
  (host-getkword (current-evaluation-host)
                 (and prompt (optional-prompt-string prompt "GETKWORD"))))

;;; --- Phase 13: COM bridge (vlax-* + safearray + variant) ----------

(defun ensure-vlax-string (object operator-name)
  (etypecase object
    (autolisp-string (autolisp-string-value object))
    (string object)))

(defun builtin-vlax-create-object (progid)
  (host-vlax-create-object (current-evaluation-host)
                           (ensure-vlax-string
                            (require-string progid "VLAX-CREATE-OBJECT")
                            "VLAX-CREATE-OBJECT")))

(defun builtin-vlax-get-object (progid)
  (host-vlax-get-object (current-evaluation-host)
                        (ensure-vlax-string
                         (require-string progid "VLAX-GET-OBJECT")
                         "VLAX-GET-OBJECT")))

(defun builtin-vlax-get-or-create-object (progid)
  (or (builtin-vlax-get-object progid)
      (builtin-vlax-create-object progid)))

(defun builtin-vlax-release-object (vla)
  (host-vlax-release-object (current-evaluation-host) vla))

(defun builtin-vlax-object-released-p (vla)
  (cond
    ((typep vla 'autolisp-vla-object)
     (handler-case
         (progn (host-vlax-property-available-p (current-evaluation-host) vla "Name")
                nil)
       (autolisp-runtime-error (condition)
         (case (autolisp-runtime-error-code condition)
           ((:released-vla-object :unknown-vla-object)
            (intern-autolisp-symbol "T"))
           (t (error condition))))))
    (t nil)))

(defun builtin-vlax-get-property (vla name)
  (host-vlax-get-property (current-evaluation-host) vla
                          (cond
                            ((typep name 'autolisp-string) (autolisp-string-value name))
                            ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
                            (t name))))

(defun builtin-vlax-put-property (vla name value)
  (host-vlax-put-property (current-evaluation-host) vla
                          (cond
                            ((typep name 'autolisp-string) (autolisp-string-value name))
                            ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
                            (t name))
                          value))

(defun builtin-vlax-invoke-method (vla name &rest args)
  (host-vlax-invoke-method (current-evaluation-host) vla
                           (cond
                             ((typep name 'autolisp-string) (autolisp-string-value name))
                             ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
                             (t name))
                           args))

(defun builtin-vlax-property-available-p (vla name)
  (if (host-vlax-property-available-p
       (current-evaluation-host) vla
       (cond
         ((typep name 'autolisp-string) (autolisp-string-value name))
         ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
         (t name)))
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-vlax-method-applicable-p (vla name)
  (if (host-vlax-method-applicable-p
       (current-evaluation-host) vla
       (cond
         ((typep name 'autolisp-string) (autolisp-string-value name))
         ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
         (t name)))
      (intern-autolisp-symbol "T")
      nil))

;;; --- SAFEARRAY -----------------------------------------------------
;;
;; SAFEARRAY is a tagged multi-dimensional array with an element-
;; type marker and per-dimension lower/upper bounds. AutoLISP
;; programs use `vlax-make-safearray TYPE BOUNDS...` to allocate,
;; then `vlax-safearray-fill` / `vlax-safearray-put-element` to
;; populate. clautolisp keeps the storage as an internal struct
;; (`safearray-data`) inside the runtime's `autolisp-safearray`
;; wrapper's `value` slot.

(defstruct safearray-data
  (type-tag :variant :type keyword)
  (bounds   '() :type list)
  (storage  nil))

(defun safearray-of (object operator-name)
  (unless (typep object 'autolisp-safearray)
    (signal-builtin-argument-error
     :invalid-safearray
     operator-name
     "~A expects a SAFEARRAY, got ~S."
     operator-name object))
  (let ((data (autolisp-safearray-value object)))
    (unless (typep data 'safearray-data)
      (signal-builtin-argument-error
       :invalid-safearray
       operator-name
       "~A: SAFEARRAY storage is not a clautolisp safearray-data, got ~S."
       operator-name data))
    data))

(defun coerce-bounds-spec (raw operator-name)
  "Each dimension is given as (cons LOW HIGH); flatten into a list of
(LOW HIGH) pairs, validating integers and LOW <= HIGH."
  (unless (and raw (listp raw))
    (signal-builtin-argument-error
     :invalid-safearray-bounds
     operator-name
     "~A expects a list of (LOW . HIGH) bound pairs, got ~S."
     operator-name raw))
  (mapcar (lambda (pair)
            (unless (and (consp pair)
                         (integerp (car pair))
                         (integerp (cdr pair))
                         (<= (car pair) (cdr pair)))
              (signal-builtin-argument-error
               :invalid-safearray-bounds
               operator-name
               "~A: each bound must be (LOW . HIGH) integer pair with LOW <= HIGH, got ~S."
               operator-name pair))
            (list (car pair) (cdr pair)))
          raw))

(defun bounds-shape (bounds)
  (mapcar (lambda (pair) (1+ (- (second pair) (first pair)))) bounds))

(defun safearray-flat-index (bounds subscripts operator-name)
  (unless (= (length bounds) (length subscripts))
    (signal-builtin-argument-error
     :invalid-safearray-index
     operator-name
     "~A: ~D subscripts required, got ~D."
     operator-name (length bounds) (length subscripts)))
  (let ((flat 0)
        (stride 1))
    (loop for pair in (reverse bounds)
          for sub in (reverse subscripts)
          for low = (first pair)
          for high = (second pair)
          do (unless (and (integerp sub) (<= low sub high))
               (signal-builtin-argument-error
                :invalid-safearray-index
                operator-name
                "~A: subscript ~S out of bounds [~D..~D]."
                operator-name sub low high))
             (incf flat (* (- sub low) stride))
             (setf stride (* stride (1+ (- high low)))))
    flat))

(defun builtin-vlax-make-safearray (type &rest bounds)
  (let* ((tag (cond
                ((integerp type) type)
                ((typep type 'autolisp-symbol)
                 (intern (autolisp-symbol-name type) "KEYWORD"))
                (t :variant)))
         (parsed (coerce-bounds-spec bounds "VLAX-MAKE-SAFEARRAY"))
         (size (reduce #'* (bounds-shape parsed) :initial-value 1))
         (storage (make-array size :initial-element nil)))
    (make-autolisp-safearray
     :value (make-safearray-data :type-tag (if (keywordp tag) tag :variant)
                                  :bounds parsed
                                  :storage storage))))

(defun builtin-vlax-safearray-fill (safe values)
  (require-proper-list values "VLAX-SAFEARRAY-FILL")
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY-FILL"))
         (storage (safearray-data-storage data)))
    (loop for value in values
          for i from 0
          while (< i (length storage))
          do (setf (aref storage i) value))
    safe))

(defun builtin-vlax-safearray-put-element (safe &rest indices-and-value)
  (when (< (length indices-and-value) 2)
    (signal-builtin-argument-error
     :wrong-number-of-arguments
     "VLAX-SAFEARRAY-PUT-ELEMENT"
     "VLAX-SAFEARRAY-PUT-ELEMENT expects subscripts followed by a value."))
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY-PUT-ELEMENT"))
         (subscripts (butlast indices-and-value))
         (value (car (last indices-and-value)))
         (flat (safearray-flat-index (safearray-data-bounds data)
                                     subscripts
                                     "VLAX-SAFEARRAY-PUT-ELEMENT")))
    (setf (aref (safearray-data-storage data) flat) value)
    value))

(defun builtin-vlax-safearray-get-element (safe &rest indices)
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY-GET-ELEMENT"))
         (flat (safearray-flat-index (safearray-data-bounds data)
                                     indices
                                     "VLAX-SAFEARRAY-GET-ELEMENT")))
    (aref (safearray-data-storage data) flat)))

(defun builtin-vlax-safearray->list (safe)
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY->LIST"))
         (storage (safearray-data-storage data)))
    (coerce storage 'list)))

(defun builtin-vlax-safearray-type (safe)
  (let ((data (safearray-of safe "VLAX-SAFEARRAY-TYPE")))
    (intern-autolisp-symbol (symbol-name (safearray-data-type-tag data)))))

(defun builtin-vlax-safearray-get-l-bound (safe dim)
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY-GET-L-BOUND"))
         (i (require-int32 dim "VLAX-SAFEARRAY-GET-L-BOUND"))
         (pair (nth (1- i) (safearray-data-bounds data))))
    (cond
      ((null pair)
       (signal-builtin-argument-error
        :invalid-safearray-dimension
        "VLAX-SAFEARRAY-GET-L-BOUND"
        "Dimension ~D is out of range." dim))
      (t (first pair)))))

(defun builtin-vlax-safearray-get-u-bound (safe dim)
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY-GET-U-BOUND"))
         (i (require-int32 dim "VLAX-SAFEARRAY-GET-U-BOUND"))
         (pair (nth (1- i) (safearray-data-bounds data))))
    (cond
      ((null pair)
       (signal-builtin-argument-error
        :invalid-safearray-dimension
        "VLAX-SAFEARRAY-GET-U-BOUND"
        "Dimension ~D is out of range." dim))
      (t (second pair)))))

;;; --- VARIANT -------------------------------------------------------
;;
;; Internal storage: a (cons type-keyword inner-value) pair.
;; Inner-value is whatever the AutoLISP code supplied; type-keyword
;; is one of :integer / :real / :string / :array / :variant /
;; :short / :boolean — descriptive only, not type-checked beyond
;; the identity round-trip.

(defun variant-pair (object operator-name)
  (unless (typep object 'autolisp-variant)
    (signal-builtin-argument-error
     :invalid-variant
     operator-name
     "~A expects a VARIANT, got ~S."
     operator-name object))
  (let ((pair (autolisp-variant-value object)))
    (unless (consp pair)
      (signal-builtin-argument-error
       :invalid-variant
       operator-name
       "~A: VARIANT storage is not a (TYPE . VALUE) pair, got ~S."
       operator-name pair))
    pair))

(defun builtin-vlax-make-variant (&optional value type)
  (let* ((tag (cond
                ((null type)
                 (cond
                   ((integerp value) :integer)
                   ((numberp value) :real)
                   ((typep value 'autolisp-string) :string)
                   ((typep value 'autolisp-safearray) :array)
                   ((null value) :empty)
                   (t :variant)))
                ((typep type 'autolisp-symbol)
                 (intern (autolisp-symbol-name type) "KEYWORD"))
                ((keywordp type) type)
                ((integerp type) type)
                (t :variant))))
    (make-autolisp-variant :value (cons (if (keywordp tag) tag :variant) value))))

(defun builtin-vlax-variant-type (variant)
  (let ((tag (car (variant-pair variant "VLAX-VARIANT-TYPE"))))
    (intern-autolisp-symbol (symbol-name tag))))

(defun builtin-vlax-variant-value (variant)
  (cdr (variant-pair variant "VLAX-VARIANT-VALUE")))

(defun builtin-vlax-variant-change-type (variant new-type)
  (let* ((pair (variant-pair variant "VLAX-VARIANT-CHANGE-TYPE"))
         (target (cond
                   ((typep new-type 'autolisp-symbol)
                    (intern (autolisp-symbol-name new-type) "KEYWORD"))
                   ((keywordp new-type) new-type)
                   (t :variant))))
    (make-autolisp-variant :value (cons target (cdr pair)))))

;;; --- Phase 14b: reactor (vlr-*) builtin family ---------------------
;;;
;;; A reactor is a host-side event-callback subscription object.
;;; clautolisp's reactor surface dispatches against the runtime's
;;; per-document and per-application registries; the actual events
;;; are emitted by MockHost (and, in Phase 16, LiveHost) via the
;;; runtime's signal-document-event / signal-application-event
;;; helpers. Reactors are the AutoLISP-visible piece of the
;;; observer pattern; the host-object ontology + lifecycle is
;;; documented in clautolisp/documentation/design.org and pinned
;;; normatively in autolisp-spec ch.21 ("Host Object Ontology and
;;; Lifecycles").

(defun current-document-or-error (operator-name)
  (let* ((context (clautolisp.autolisp-runtime:current-evaluation-context))
         (document (and context
                        (clautolisp.autolisp-runtime:evaluation-context-current-document
                         context))))
    (unless document
      (signal-builtin-argument-error
       :no-current-document
       operator-name
       "~A: no current document is bound to the evaluation context."
       operator-name))
    document))

(defun current-session-or-error (operator-name)
  (let* ((context (clautolisp.autolisp-runtime:current-evaluation-context))
         (session (and context
                       (clautolisp.autolisp-runtime:evaluation-context-session
                        context))))
    (unless session
      (signal-builtin-argument-error
       :no-current-session
       operator-name
       "~A: no current session is bound to the evaluation context."
       operator-name))
    session))

(defun callbacks-list->table (alist operator-name)
  "Validate and convert an AutoLISP callback alist of the form
((reaction-name . callback-fn) ...) to a hash-table from
keyword reaction-name to AutoLISP callable. Reaction names may
be supplied as keywords, AutoLISP-strings, or AutoLISP-symbols
prefixed with `:vlr-`; we normalise to keywords."
  (require-proper-list alist operator-name)
  (let ((table (make-hash-table :test #'eq)))
    (dolist (pair alist table)
      (unless (consp pair)
        (signal-builtin-argument-error
         :invalid-reactor-callbacks
         operator-name
         "~A: each callback entry must be (REACTION-NAME . FUNCTION), got ~S."
         operator-name pair))
      (let ((name (normalise-reaction-name (car pair) operator-name)))
        (setf (gethash name table) (cdr pair))))))

(defun normalise-reaction-name (object operator-name)
  (cond
    ((keywordp object) object)
    ((typep object 'autolisp-symbol)
     (intern (string-upcase (autolisp-symbol-name object)) "KEYWORD"))
    ((typep object 'autolisp-string)
     (intern (string-upcase (autolisp-string-value object)) "KEYWORD"))
    ((stringp object) (intern (string-upcase object) "KEYWORD"))
    (t
     (signal-builtin-argument-error
      :invalid-reaction-name
      operator-name
      "~A: reaction name must be a keyword, symbol, or string, got ~S."
      operator-name object))))

(defun coerce-data-list (data operator-name)
  (cond
    ((null data) nil)
    ((listp data) data)
    (t
     (signal-builtin-argument-error
      :invalid-reactor-data
      operator-name
      "~A: data argument must be nil or a list, got ~S."
      operator-name data))))

(defun coerce-owners-list (owners operator-name)
  (cond
    ((null owners) nil)
    ((listp owners) owners)
    (t
     (signal-builtin-argument-error
      :invalid-reactor-owners
      operator-name
      "~A: owners argument must be nil or a list, got ~S."
      operator-name owners))))

(defun ensure-reactor (object operator-name)
  (unless (typep object 'reactor)
    (signal-builtin-argument-error
     :invalid-reactor
     operator-name
     "~A expects a reactor object, got ~S."
     operator-name object))
  object)

(defun build-reactor (kind &key owners data callbacks)
  (let* ((scope (reactor-type-scope kind))
         (callback-table
          (etypecase callbacks
            (hash-table callbacks)
            (list (callbacks-list->table callbacks "VLR-CONSTRUCTOR")))))
    (make-reactor :kind kind
                  :scope scope
                  :owners (coerce-owners-list owners "VLR-CONSTRUCTOR")
                  :data (coerce-data-list data "VLR-CONSTRUCTOR")
                  :callbacks callback-table)))

(defun install-new-reactor (kind owners data callbacks operator-name)
  (declare (ignore operator-name))
  (let* ((reactor (build-reactor kind
                                  :owners owners
                                  :data data
                                  :callbacks callbacks))
         (scope (reactor-scope reactor)))
    (case scope
      (:document
       (let ((document (current-document-or-error
                        (reactor-type-name kind))))
         (add-reactor-to-document document reactor)))
      (:application
       (let ((session (current-session-or-error
                       (reactor-type-name kind))))
         (add-reactor-to-session session reactor))))
    reactor))

(defmacro define-vlr-constructor (name kind requires-owners-p)
  "Generate a vlr-FOO-reactor builtin for KIND.

REQUIRES-OWNERS-P is non-nil for the constructors whose first
argument is the owners list (vlr-object-reactor and
vlr-acdb-reactor) and nil for the ones whose first argument is
the data list."
  `(defun ,name (,@(if requires-owners-p '(owners) '())
                 data callbacks)
     ,(if requires-owners-p
          `(install-new-reactor ,kind owners data callbacks ',name)
          `(install-new-reactor ,kind nil data callbacks ',name))))

(define-vlr-constructor builtin-vlr-acdb-reactor          :acdb           t)
(define-vlr-constructor builtin-vlr-command-reactor       :command        nil)
(define-vlr-constructor builtin-vlr-deepclone-reactor     :deepclone      nil)
(define-vlr-constructor builtin-vlr-document-reactor      :document       nil)
(define-vlr-constructor builtin-vlr-dwg-reactor           :dwg            nil)
(define-vlr-constructor builtin-vlr-dxf-reactor           :dxf            nil)
(define-vlr-constructor builtin-vlr-insert-reactor        :insert         nil)
(define-vlr-constructor builtin-vlr-mouse-reactor         :mouse          nil)
(define-vlr-constructor builtin-vlr-object-reactor        :object         t)
(define-vlr-constructor builtin-vlr-sysvar-reactor        :sysvar         nil)
(define-vlr-constructor builtin-vlr-toolbar-reactor       :toolbar        nil)
(define-vlr-constructor builtin-vlr-undo-reactor          :undo           nil)
(define-vlr-constructor builtin-vlr-wblock-reactor        :wblock         nil)
(define-vlr-constructor builtin-vlr-window-reactor        :window         nil)
(define-vlr-constructor builtin-vlr-xref-reactor          :xref           nil)
(define-vlr-constructor builtin-vlr-docmanager-reactor    :docmanager     nil)
(define-vlr-constructor builtin-vlr-editor-reactor        :editor         nil)
(define-vlr-constructor builtin-vlr-linker-reactor        :linker         nil)
(define-vlr-constructor builtin-vlr-lisp-reactor          :lisp           nil)
(define-vlr-constructor builtin-vlr-miscellaneous-reactor :miscellaneous  nil)

;;; Introspection / mutation -------------------------------------

(defun builtin-vlr-add (reactor)
  (ensure-reactor reactor "VLR-ADD")
  (setf (reactor-active-p reactor) t)
  (let ((scope (reactor-scope reactor)))
    (case scope
      (:document
       (add-reactor-to-document (or (reactor-document reactor)
                                    (current-document-or-error "VLR-ADD"))
                                reactor))
      (:application
       (add-reactor-to-session (current-session-or-error "VLR-ADD")
                               reactor))))
  reactor)

(defun builtin-vlr-remove (reactor)
  (ensure-reactor reactor "VLR-REMOVE")
  (let ((scope (reactor-scope reactor)))
    (case scope
      (:document
       (when (reactor-document reactor)
         (remove-reactor-from-document (reactor-document reactor) reactor)))
      (:application
       (let ((session (current-session-or-error "VLR-REMOVE")))
         (remove-reactor-from-session session reactor)))))
  (setf (reactor-active-p reactor) nil)
  reactor)

(defun builtin-vlr-remove-all (&optional kind)
  ;; (vlr-remove-all)         -> remove every reactor in scope
  ;; (vlr-remove-all KIND)    -> remove all reactors of KIND
  (let ((kw (and kind (normalise-reaction-name kind "VLR-REMOVE-ALL")))
        (session (current-session-or-error "VLR-REMOVE-ALL")))
    (dolist (reactor (all-session-reactors session))
      (when (or (null kw) (eq (reactor-kind reactor) kw))
        (builtin-vlr-remove reactor)))
    nil))

(defun builtin-vlr-data (reactor)
  (reactor-data (ensure-reactor reactor "VLR-DATA")))

(defun builtin-vlr-data-set (reactor new-data)
  (ensure-reactor reactor "VLR-DATA-SET")
  (setf (reactor-data reactor) (coerce-data-list new-data "VLR-DATA-SET"))
  new-data)

(defun builtin-vlr-owners (reactor)
  (reactor-owners (ensure-reactor reactor "VLR-OWNERS")))

(defun builtin-vlr-owner-add (reactor owner)
  (ensure-reactor reactor "VLR-OWNER-ADD")
  (unless (member owner (reactor-owners reactor) :test #'equal)
    (setf (reactor-owners reactor) (append (reactor-owners reactor) (list owner))))
  reactor)

(defun builtin-vlr-owner-remove (reactor owner)
  (ensure-reactor reactor "VLR-OWNER-REMOVE")
  (setf (reactor-owners reactor)
        (remove owner (reactor-owners reactor) :test #'equal))
  reactor)

(defun builtin-vlr-set-notification (reactor mode)
  (ensure-reactor reactor "VLR-SET-NOTIFICATION")
  (let ((kw (cond
              ((keywordp mode) mode)
              ((typep mode 'autolisp-symbol)
               (intern (string-upcase (autolisp-symbol-name mode)) "KEYWORD"))
              (t (signal-builtin-argument-error
                  :invalid-notification-mode
                  "VLR-SET-NOTIFICATION"
                  "VLR-SET-NOTIFICATION expects a notification mode keyword, got ~S."
                  mode)))))
    (setf (reactor-notification reactor)
          (case kw
            ((:active-document-only :current-document-only) :current-document-only)
            ((:disabled) :disabled)
            (otherwise :all-documents)))
    reactor))

(defun builtin-vlr-notification (reactor)
  (intern-autolisp-symbol
   (string-upcase (symbol-name
                   (reactor-notification (ensure-reactor reactor "VLR-NOTIFICATION"))))))

(defun builtin-vlr-current-reaction-name ()
  ;; In Phase 14b we don't expose the dispatch-stack to the
  ;; callback; this returns nil headlessly. Real AutoCAD would
  ;; return the symbol-name of the reaction currently being
  ;; dispatched.
  nil)

(defun builtin-vlr-reactions (reactor)
  (let ((acc '()))
    (maphash (lambda (name fn) (push (cons name fn) acc))
             (reactor-callbacks (ensure-reactor reactor "VLR-REACTIONS")))
    acc))

(defun builtin-vlr-reaction-set (reactor reaction-name new-callback)
  (ensure-reactor reactor "VLR-REACTION-SET")
  (let ((kw (normalise-reaction-name reaction-name "VLR-REACTION-SET")))
    (cond
      ((null new-callback)
       (remhash kw (reactor-callbacks reactor)))
      (t
       (setf (gethash kw (reactor-callbacks reactor)) new-callback)))
    reactor))

(defun builtin-vlr-added-p (reactor)
  (ensure-reactor reactor "VLR-ADDED-P")
  (if (reactor-active-p reactor)
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-vlr-type (reactor)
  (intern-autolisp-symbol
   (string-upcase (symbol-name
                   (reactor-kind (ensure-reactor reactor "VLR-TYPE"))))))

(defun builtin-vlr-types ()
  (mapcar (lambda (kw)
            (intern-autolisp-symbol (string-upcase (symbol-name kw))))
          (reactor-type-keywords)))

(defun builtin-vlr-reactors (&optional kind-filter)
  (let* ((session (current-session-or-error "VLR-REACTORS"))
         (kw (and kind-filter (normalise-reaction-name kind-filter "VLR-REACTORS")))
         (all (all-session-reactors session)))
    (when kw
      (setf all (remove-if-not (lambda (r) (eq (reactor-kind r) kw)) all)))
    all))

(defun builtin-vlr-trace-reaction (reactor reaction-name)
  ;; Headless: no actual trace — return reaction-name to acknowledge.
  (ensure-reactor reactor "VLR-TRACE-REACTION")
  (normalise-reaction-name reaction-name "VLR-TRACE-REACTION")
  reaction-name)

;;; Persistence --------------------------------------------------

(defun reactor-as-persistent-record (reactor)
  "Encode a reactor as a property list suitable for serialisation
through mock-host-snapshot. Callbacks must be autolisp-symbols
(closures cannot survive)."
  (let ((callbacks '()))
    (maphash (lambda (name fn)
               (cond
                 ((typep fn 'autolisp-symbol)
                  (push (cons name (autolisp-symbol-name fn)) callbacks))
                 (t
                  (signal-builtin-argument-error
                   :non-serializable-callback
                   "VLR-PERS"
                   "VLR-PERS: callback for reaction ~A must be a symbol so it can survive a save/reload cycle."
                   name))))
             (reactor-callbacks reactor))
    (list :id (princ-to-string (reactor-id reactor))
          :kind (reactor-kind reactor)
          :owners (reactor-owners reactor)
          :data (reactor-data reactor)
          :callbacks callbacks
          :notification (reactor-notification reactor))))

(defun builtin-vlr-pers (reactor)
  (ensure-reactor reactor "VLR-PERS")
  (let ((document (or (reactor-document reactor)
                      (current-document-or-error "VLR-PERS")))
        (record (reactor-as-persistent-record reactor)))
    (setf (reactor-persistent-p reactor) t)
    (setf (gethash (reactor-id reactor)
                   (document-namespace-persistent-reactor-index document))
          record)
    reactor))

(defun builtin-vlr-pers-release (reactor)
  (ensure-reactor reactor "VLR-PERS-RELEASE")
  (let ((document (reactor-document reactor)))
    (when document
      (remhash (reactor-id reactor)
               (document-namespace-persistent-reactor-index document))))
  (setf (reactor-persistent-p reactor) nil)
  reactor)

(defun builtin-vlr-pers-list (&optional document-or-name)
  (declare (ignore document-or-name))
  (let* ((document (current-document-or-error "VLR-PERS-LIST"))
         (acc '()))
    (maphash (lambda (id record)
               (declare (ignore record))
               (let ((reactor (gethash id (document-reactor-registry document))))
                 (when reactor (push reactor acc))))
             (document-namespace-persistent-reactor-index document))
    acc))

(defun builtin-vlr-pers-p (reactor)
  (ensure-reactor reactor "VLR-PERS-P")
  (if (reactor-persistent-p reactor)
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-vlr-pers-dictname ()
  ;; AutoCAD returns "ACAD_REACTORS" — the NOD entry that stores
  ;; persistent reactors. clautolisp uses the same name.
  (make-autolisp-string "ACAD_REACTORS"))

;;; --- Phase 15a: DCL (Dialog Control Language) builtins -----------
;;;
;;; Thin wrappers around the autolisp-dcl runtime. The renderer is
;;; pluggable: by default the Phase-15a terminal renderer is
;;; installed at startup; future GUI backends (Phase 15b+) install
;;; their own via dcl-runtime install-default-renderer.

(defun builtin-load-dialog (path)
  (let* ((value (autolisp-string-value (require-string path "LOAD_DIALOG")))
         (resolved (resolve-load-pathname value)))
    (cond
      ((null resolved) -1)
      (t (or (dcl-runtime-load-dialog (namestring resolved)) -1)))))

(defun builtin-unload-dialog (id)
  (dcl-runtime-unload-dialog (require-int32 id "UNLOAD_DIALOG"))
  nil)

(defun builtin-new-dialog (name id &optional action default-point)
  ;; (new_dialog DIALOG-NAME DCL-ID [DEFAULT-ACTION [DEFAULT-POINT]])
  ;; -> t on success, nil otherwise. The dialog created by this
  ;; call becomes the *active* dialog; subsequent set_tile /
  ;; action_tile / etc. target it implicitly.
  (declare (ignore default-point))
  (let* ((handle (require-int32 id "NEW_DIALOG"))
         (dialog-id (dcl-runtime-new-dialog
                     handle (autolisp-string-value
                             (require-string name "NEW_DIALOG")))))
    (when (and action (not (null action)))
      (dcl-runtime-action-tile dialog-id "" action))
    (intern-autolisp-symbol "T")))

(defun builtin-start-dialog ()
  ;; (start_dialog) — no arguments. Drives the renderer's run-fn
  ;; against the currently-active dialog and returns its terminal
  ;; status integer.
  (cond
    ((null (current-dialog-id)) 1)
    (t (dcl-runtime-start-dialog (current-dialog-id)))))

(defun builtin-done-dialog (&optional status)
  ;; (done_dialog [STATUS]) — close the active dialog.
  (let ((s (cond
             ((null status) 1)
             ((integerp status) status)
             (t 1)))
        (id (current-dialog-id)))
    (cond
      (id (dcl-runtime-done-dialog id s))
      (t s))))

(defun builtin-action-tile (key callback)
  ;; (action_tile KEY CALLBACK-STRING) -> t on success
  (dcl-runtime-action-tile
   (require-current-dialog-id "ACTION_TILE")
   (autolisp-string-value (require-string key "ACTION_TILE"))
   callback)
  (intern-autolisp-symbol "T"))

(defun builtin-set-tile (key value)
  ;; (set_tile KEY VALUE) -> VALUE
  (dcl-runtime-set-tile
   (require-current-dialog-id "SET_TILE")
   (autolisp-string-value (require-string key "SET_TILE"))
   (cond
     ((typep value 'autolisp-string) (autolisp-string-value value))
     (t (princ-to-string value))))
  value)

(defun builtin-get-tile (key)
  ;; (get_tile KEY) -> string
  (make-autolisp-string
   (or (dcl-runtime-get-tile
        (require-current-dialog-id "GET_TILE")
        (autolisp-string-value (require-string key "GET_TILE")))
       "")))

(defun builtin-mode-tile (key mode)
  ;; (mode_tile KEY MODE) -> nil
  (dcl-runtime-mode-tile
   (require-current-dialog-id "MODE_TILE")
   (autolisp-string-value (require-string key "MODE_TILE"))
   (require-int32 mode "MODE_TILE"))
  nil)

(defun builtin-client-data-tile (key &optional value)
  ;; (client_data_tile KEY [VALUE])
  (let ((id (require-current-dialog-id "CLIENT_DATA_TILE"))
        (k (autolisp-string-value (require-string key "CLIENT_DATA_TILE"))))
    (cond
      (value (dcl-runtime-set-client-data id k value))
      (t (dcl-runtime-client-data id k)))))

(defun builtin-dimx-tile (key)
  ;; (dimx_tile KEY) -> integer width. Headless: fixed value.
  (declare (ignore key))
  100)

(defun builtin-dimy-tile (key)
  (declare (ignore key))
  20)

(defun builtin-start-image (key)
  ;; (start_image KEY) — open an image-paint batch on KEY.
  (let ((k (autolisp-string-value (require-string key "START_IMAGE"))))
    (dcl-runtime-start-image k)
    (intern-autolisp-symbol "T")))

(defun builtin-end-image ()
  (dcl-runtime-end-image)
  nil)

(defun builtin-fill-image (x y width height colour)
  (let ((xi (require-int32 x "FILL_IMAGE"))
        (yi (require-int32 y "FILL_IMAGE"))
        (wi (require-int32 width "FILL_IMAGE"))
        (hi (require-int32 height "FILL_IMAGE"))
        (ci (require-int32 colour "FILL_IMAGE")))
    (dcl-runtime-image-fill xi yi wi hi ci)
    ci))

(defun builtin-vector-image (x1 y1 x2 y2 colour)
  (let ((x1i (require-int32 x1 "VECTOR_IMAGE"))
        (y1i (require-int32 y1 "VECTOR_IMAGE"))
        (x2i (require-int32 x2 "VECTOR_IMAGE"))
        (y2i (require-int32 y2 "VECTOR_IMAGE"))
        (ci  (require-int32 colour "VECTOR_IMAGE")))
    (dcl-runtime-image-vector x1i y1i x2i y2i ci)
    ci))

(defun builtin-slide-image (x y width height path)
  (let ((xi (require-int32 x "SLIDE_IMAGE"))
        (yi (require-int32 y "SLIDE_IMAGE"))
        (wi (require-int32 width "SLIDE_IMAGE"))
        (hi (require-int32 height "SLIDE_IMAGE"))
        (p (autolisp-string-value (require-string path "SLIDE_IMAGE"))))
    (dcl-runtime-image-slide xi yi wi hi p)
    nil))

(defun builtin-start-list (key &optional (operation 3) (index 0))
  ;; (start_list KEY [OPERATION [INDEX]])
  ;; OPERATION: 1 = change one item at INDEX; 2 = append;
  ;; 3 = clear and replace (default).
  (let ((k (autolisp-string-value (require-string key "START_LIST")))
        (op (cond ((null operation) 3)
                  ((integerp operation) operation)
                  (t (require-int32 operation "START_LIST"))))
        (idx (cond ((null index) 0)
                   ((integerp index) index)
                   (t (require-int32 index "START_LIST")))))
    (dcl-runtime-start-list k op idx)
    (make-autolisp-string k)))

(defun builtin-add-list (text)
  ;; (add_list STRING) -> STRING
  (let ((s (autolisp-string-value (require-string text "ADD_LIST"))))
    (dcl-runtime-add-list s)
    (make-autolisp-string s)))

(defun builtin-end-list ()
  (dcl-runtime-end-list)
  nil)

(defun builtin-term-dialog ()
  ;; Real AutoLISP's term_dialog tears down all active dialogs and
  ;; never errors when there are none. We mark every active dialog
  ;; finished with status 0 (cancel) and let the renderer's run-fn
  ;; close them out.
  (let ((active (symbol-value
                 (find-symbol "*ACTIVE-DIALOGS*"
                              :clautolisp.autolisp-dcl))))
    (when active
      (loop for id being the hash-keys of active
            do (handler-case (dcl-runtime-done-dialog id 0)
                 (error () nil)))))
  nil)

;;; --- M2: Core / Misc native (missing-functions.issue) -------------
;;;
;;; OS / process / filesystem, version / inspection, geometry / math,
;;; CLI no-ops, and *error*-mode helpers. Landed under
;;; missing-functions-plan.md M2; each function is documented in the
;;; AutoLISP Spec under its Function Entry. The CLI no-op group
;;; (GRAPHSCR / TEXTSCR / TEXTPAGE / REDRAW / SETVIEW / TABLET /
;;; MENUCMD / MENUGROUP / SHOWHTMLMODALWINDOW) ships as documented
;;; nil-returning stubs — there's no graphics surface in a headless
;;; engine, but the names must be callable for portable user code
;;; that probes `boundp' or wraps the call in `vl-catch-all-apply'.

(defparameter *autolisp-error-mode-stack* nil
  "Push-down stack of *error* protocol frames, populated by
*PUSH-ERROR-USING-COMMAND* / *PUSH-ERROR-USING-STACK* and
drained by *POP-ERROR-MODE*. Each frame is a keyword keyword:
:COMMAND or :STACK, used by host error-handlers to decide how
to format the *error* output. Sticky across calls — bounded only
by stack discipline in user code, not by session lifetime.")

(defvar *clautolisp-startup-directory*
  (or (ignore-errors (namestring (uiop:getcwd))) "")
  "Directory clautolisp was invoked from, captured the first time
this defvar is evaluated (i.e. at image build / install-core-
builtins, whichever comes first). VL-GETSTARTUPDIR returns this
string; once captured it doesn't track later `chdir' calls. A
defvar so the value survives multiple test-image reloads.")

;;; ---- OS / process / filesystem ----

(defun builtin-getenv (name)
  ;; (getenv "VAR") -> string-or-nil. Reads the process environment
  ;; via uiop:getenv. Per the AutoLISP Spec § GETENV Description,
  ;; "Returns nil if the variable is not defined" — undefined is
  ;; the ONLY nil-returning case. A defined-but-empty variable is
  ;; distinct from undefined on POSIX (and a useful signal for
  ;; flag-style env vars like NO_COLOR), so we preserve the
  ;; distinction: uiop:getenv returns nil for unset → we return
  ;; nil; uiop:getenv returns "" for set-to-empty → we return "".
  (let* ((var (autolisp-string-value (require-string name "GETENV")))
         (value (uiop:getenv var)))
    (if value
        (make-autolisp-string value)
        nil)))

(defun builtin-setenv (name value)
  ;; (setenv "VAR" "VALUE") -> "VALUE". Writes the process
  ;; environment via (setf uiop:getenv). VALUE nil deletes the
  ;; variable on hosts that support it; otherwise sets it to "".
  ;; Returns the new value (or nil if value was nil).
  (let* ((var (autolisp-string-value (require-string name "SETENV")))
         (new (cond ((null value) "")
                    (t (autolisp-string-value (require-string value "SETENV"))))))
    (setf (uiop:getenv var) new)
    (if value (make-autolisp-string new) nil)))

(defun builtin-getpid ()
  ;; (getpid) -> integer. Process ID of the running clautolisp.
  ;; UIOP doesn't expose a portable getpid for the CURRENT process
  ;; (only process-info-pid for spawned ones), so we go through
  ;; the implementation primitive directly. Returns 0 if the host
  ;; lacks one.
  (or (ignore-errors
        #+sbcl (sb-posix:getpid)
        #+ccl  (ccl::getpid)
        #-(or sbcl ccl) 0)
      0))

(defun builtin-sleep (milliseconds)
  ;; (sleep N) -> nil. AutoLISP SLEEP takes milliseconds; CL's
  ;; sleep takes seconds, so we divide. Negative or zero values
  ;; are documented as "return immediately".
  (let ((ms (require-number milliseconds "SLEEP")))
    (when (plusp ms)
      (sleep (/ (coerce ms 'double-float) 1000.0d0)))
    nil))

(defun builtin-gc ()
  ;; (gc) -> nil. Forces a garbage collection. SBCL: `sb-ext:gc`.
  ;; Other impls: best-effort via uiop where available.
  (handler-case
      (progn
        #+sbcl (sb-ext:gc :full t)
        #+ccl  (ccl:gc)
        #-(or sbcl ccl) (values))
    (error () nil))
  nil)

(defun builtin-startapp (command &optional file)
  ;; (startapp "cmd" ["file"]) -> integer-or-nil. Launches an
  ;; external program asynchronously. Autodesk returns the process
  ;; ID on success, nil on failure. We use uiop:launch-program
  ;; for the spawn; the program runs detached.
  (let* ((cmd (autolisp-string-value (require-string command "STARTAPP")))
         (arg (and file
                   (autolisp-string-value (require-string file "STARTAPP"))))
         (argv (if arg (list cmd arg) cmd)))
    (handler-case
        (let ((proc (uiop:launch-program argv :output nil :error-output nil)))
          (or (ignore-errors (uiop:process-info-pid proc)) 1))
      (error () nil))))

(defun builtin-vl-getcurrentdir ()
  ;; (vl-getcurrentdir) -> string. Current working directory.
  (make-autolisp-string (namestring (uiop:getcwd))))

(defun builtin-vl-setcurrentdir (path)
  ;; (vl-setcurrentdir "/some/path") -> string-or-nil. Returns the
  ;; new cwd on success, nil if the path doesn't exist or chdir
  ;; fails.
  (let ((target (autolisp-string-value (require-string path "VL-SETCURRENTDIR"))))
    (handler-case
        (let ((resolved (uiop:ensure-directory-pathname
                         (uiop:parse-native-namestring target))))
          (unless (uiop:directory-exists-p resolved)
            (return-from builtin-vl-setcurrentdir nil))
          (uiop:chdir resolved)
          (make-autolisp-string (namestring (uiop:getcwd))))
      (error () nil))))

(defun builtin-vl-getstartupdir ()
  ;; (vl-getstartupdir) -> string. The cwd at clautolisp's first
  ;; install of core-builtins (image build time, captured by
  ;; *clautolisp-startup-directory* via defvar).
  (make-autolisp-string *clautolisp-startup-directory*))

(defun builtin-vl-rmdir (path)
  ;; (vl-rmdir "/some/path") -> T-or-nil. Removes an EMPTY
  ;; directory; returns nil on failure (path missing, non-empty,
  ;; permission denied). Autodesk does NOT recurse — we match that
  ;; (use rm -rf at the shell for recursive removal).
  (let ((target (autolisp-string-value (require-string path "VL-RMDIR"))))
    (handler-case
        (let ((resolved (uiop:ensure-directory-pathname
                         (uiop:parse-native-namestring target))))
          (cond
            ((not (uiop:directory-exists-p resolved)) nil)
            (t
             (uiop:delete-empty-directory resolved)
             (intern-autolisp-symbol "T"))))
      (error () nil))))

(defun builtin-fnsplitl (filename)
  ;; (fnsplitl "/path/to/file.lsp") ->
  ;;     ("/path/to/" "file" ".lsp")
  ;; Autodesk's three-element split: directory + basename + extension.
  ;; The directory part keeps its trailing slash; the extension keeps
  ;; its leading dot. Names with no extension yield "" in slot 3.
  (let* ((value (autolisp-string-value (require-string filename "FNSPLITL")))
         (slash (position #\/ value :from-end t)))
    (let* ((dir (if slash
                    (subseq value 0 (1+ slash))
                    ""))
           (file-part (if slash (subseq value (1+ slash)) value))
           (dot (position #\. file-part :from-end t))
           (base (if dot (subseq file-part 0 dot) file-part))
           (ext  (if dot (subseq file-part dot) "")))
      (list (make-autolisp-string dir)
            (make-autolisp-string base)
            (make-autolisp-string ext)))))

(defun doc-clipboard-read-argv ()
  "Per-OS argv that reads the clipboard to stdout. nil on platforms
without a known reader."
  #+darwin                 '("pbpaste")
  #+linux                  '("xclip" "-selection" "clipboard" "-o")
  ;; Windows: PowerShell ships in-box on Windows 10+ (PowerShell 5.1)
  ;; — `Get-Clipboard -Raw' returns the clipboard as a single string
  ;; instead of an array of lines. -NoProfile / -NonInteractive
  ;; suppress per-user profile load + interactive prompts so the call
  ;; is reproducible.
  #+windows                '("powershell" "-NoProfile" "-NonInteractive"
                             "-Command" "Get-Clipboard -Raw")
  #-(or darwin linux windows) nil)

(defun doc-clipboard-write-argv ()
  "Per-OS argv that reads stdin and writes it to the clipboard. nil
on platforms without a known writer."
  #+darwin                 '("pbcopy")
  #+linux                  '("xclip" "-selection" "clipboard")
  ;; Windows: pipe stdin via `$input | Set-Clipboard' so we don't
  ;; have to quote-escape the text on the command line.
  #+windows                '("powershell" "-NoProfile" "-NonInteractive"
                             "-Command" "$input | Set-Clipboard")
  #-(or darwin linux windows) nil)

(defun strip-trailing-newline (string)
  "PowerShell's Get-Clipboard -Raw appends a final CRLF that doesn't
exist on the clipboard itself. Strip up to one trailing CRLF or LF
so round-trip set→get returns the user's exact text."
  (let* ((end (length string))
         (end (if (and (plusp end) (char= (char string (1- end)) #\Newline))
                  (1- end) end))
         (end (if (and (plusp end) (char= (char string (1- end)) #\Return))
                  (1- end) end)))
    (subseq string 0 end)))

(defun builtin-doc-clipboard (&optional value)
  ;; (doc_clipboard)            -> reads clipboard text, returns string or nil
  ;; (doc_clipboard "new text") -> writes, returns "new text"
  ;; macOS uses pbpaste / pbcopy. Linux uses xclip (X11 selections —
  ;; not installed on stripped-down headless boxes; falls through to
  ;; nil there). Windows uses PowerShell's Get-Clipboard /
  ;; Set-Clipboard, which ships in-box since Windows 10 (PowerShell
  ;; 5.1) and accepts the same stdin-pipe pattern as the Unix tools.
  ;; The trailing newline PowerShell adds to Get-Clipboard -Raw
  ;; output is stripped so a set→get round-trip returns the user's
  ;; exact text.
  (cond
    ((null value)
     ;; Read mode.
     (let ((argv (doc-clipboard-read-argv)))
       (cond
         ((null argv) nil)
         (t (handler-case
                (let ((output (uiop:run-program argv
                                                :output :string
                                                :ignore-error-status t)))
                  (make-autolisp-string (strip-trailing-newline output)))
              (error () nil))))))
    (t
     ;; Write mode.
     (let ((text (autolisp-string-value
                  (require-string value "DOC_CLIPBOARD")))
           (argv (doc-clipboard-write-argv)))
       (cond
         ((null argv) nil)
         (t (handler-case
                (progn
                  (uiop:run-program argv
                                    :input (make-string-input-stream text)
                                    :output nil :error-output nil)
                  (make-autolisp-string text))
              (error () nil))))))))

;;; ---- Version / inspection ----

(defun read-autolisp-version-string ()
  "Return the *AUTOLISP-VERSION* value as a CL string, falling
back to \"0.0.0\" when the global isn't installed (the bare
autolisp-runtime test image, which doesn't load the CLI's
install-transmit-variables step)."
  (multiple-value-bind (value boundp)
      (lookup-variable (intern-autolisp-symbol "*AUTOLISP-VERSION*"))
    (cond
      ((and boundp (typep value 'autolisp-string))
       (autolisp-string-value value))
      (t "0.0.0"))))

(defun builtin-ver ()
  ;; (ver) -> "clautolisp X.Y.Z". The Autodesk page returns a
  ;; vendor-prefixed string; we follow that convention so user
  ;; banner code can dispatch on substring. The vendor prefix is
  ;; the project name as styled everywhere else (binary name,
  ;; package name, docs) — lower-case, not mixed-case.
  (make-autolisp-string
   (format nil "clautolisp ~A" (read-autolisp-version-string))))

(defun builtin-lisp$version ()
  ;; (lisp$version) -> same string as (ver). Legacy Visual LISP
  ;; alias.
  (builtin-ver))

(defun extract-integers-after (text marker max-count)
  "Find MARKER in TEXT; from its end, collect up to MAX-COUNT
non-negative integers as they appear, stopping at the next
newline. Returns the list (in order); shorter than MAX-COUNT if
fewer integers fit on the marker's line, or nil if MARKER is
absent."
  (let ((start (search marker text)))
    (when start
      (let* ((cursor (+ start (length marker)))
             (eol (or (position #\Newline text :start cursor) (length text)))
             (results '()))
        (loop while (and (< cursor eol) (< (length results) max-count))
              do (let ((digit-pos (position-if #'digit-char-p text
                                               :start cursor :end eol)))
                   (cond
                     ((null digit-pos) (loop-finish))
                     (t (multiple-value-bind (n end)
                            (parse-integer text :start digit-pos
                                                :end eol
                                                :junk-allowed t)
                          (cond
                            ((null n) (loop-finish))
                            (t (push n results)
                               (setf cursor (or end eol))))))))
              finally (return (nreverse results)))))))

#+ccl
(defun ccl-room-mem-triple ()
  "Capture CCL's (room) output and parse out (USED FREE RESERVED),
all in bytes. The `Lisp Heap:' line interleaves byte-counts with
the same number expressed in K-bytes — we keep the byte columns
(positions 0, 2, 4 of the six integers on the line). The
`reserved for heap expansion.' line carries a single MB value as
a float; we round it to bytes. Returns NIL on parse failure (so
the caller can fall back to a placeholder triple)."
  (handler-case
      (let* ((text (with-output-to-string (*standard-output*)
                     (ccl::room)))
             (heap-nums (extract-integers-after text "Lisp Heap:" 6))
             (reserved-marker "reserved for heap expansion")
             (reserved-pos (search reserved-marker text)))
        (cond
          ((null heap-nums) nil)
          ((< (length heap-nums) 5) nil)
          (t
           (let* ((total (nth 0 heap-nums))
                  (free  (nth 2 heap-nums))
                  (used  (nth 4 heap-nums))
                  (reserved-bytes
                    (when reserved-pos
                      (let* ((line-start
                               (or (position #\Newline text :end reserved-pos
                                                            :from-end t)
                                   -1))
                             (line (subseq text (1+ line-start) reserved-pos))
                             (mb (with-input-from-string (in line)
                                   (read in nil nil))))
                        (when (realp mb)
                          (round (* mb 1024 1024)))))))
             (declare (ignore total))
             (list used free (or reserved-bytes 0))))))
    (error () nil)))

(defun builtin-mem ()
  ;; (mem) -> list of three integers: (used free reserved).
  ;; Autodesk's contract is "approximate values describing the
  ;; running image's allocation state". We surface the dynamic
  ;; heap snapshot:
  ;;
  ;;   - SBCL: dynamic-space-size as USED (size, not actual usage;
  ;;     SBCL has no portable cheap "currently consed bytes"
  ;;     accessor). FREE and RESERVED stay 0.
  ;;
  ;;   - CCL: parse (room) output for the Lisp Heap row's USED /
  ;;     FREE byte counts and the `reserved for heap expansion'
  ;;     MB value. Falls back to the 0-triple on parse failure.
  ;;
  ;; Stub-quality but always returns a valid triple of integers.
  ;;
  ;;; SPEC-UNCERTAIN: slot order (used/free/reserved vs another
  ;;;   permutation), units (bytes vs kilobytes), and whether
  ;;;   the Stacks / Static rows should fold into one of the
  ;;;   three slots. Probes queued in deferred-spec-research.issue
  ;;;   § MEM.
  (let ((triple
          #+ccl  (ccl-room-mem-triple)
          #+sbcl (let ((used (or (ignore-errors (sb-ext:dynamic-space-size))
                                 0)))
                   (list used 0 0))
          #-(or sbcl ccl) nil))
    (cond
      ((and triple (= 3 (length triple)) (every #'integerp triple))
       triple)
      (t (list 0 0 0)))))

(defun builtin-alloc (size)
  ;; (alloc N) -> N. Autodesk's contract: "doesn't apply to
  ;; AutoLISP / Visual LISP" — return the argument unchanged so
  ;; existing user code that calls it as a no-op tuning hook keeps
  ;; running.
  (require-int32 size "ALLOC"))

(defun builtin-help (&optional topic command-name flags)
  ;; (help [topic [cmd [flags]]]) -> nil. The CAD opens its help
  ;; viewer; in a headless engine we print a one-liner pointing
  ;; the user at the installed Info / man pages and return nil.
  ;;
  ;;; STUB: prints a one-liner pointer instead of opening the
  ;;;   actual viewer / matching node. See
  ;;;   deferred-stubbed-functions.issue § HELP for the
  ;;;   upgrade ladder (exec info, then topic-aware info, then
  ;;;   embedded WebView).
  (declare (ignore topic command-name flags))
  (format t "~&clautolisp: help is in `info clautolisp' or `man clautolisp'.~%")
  nil)

;;; ---- Geometry / math ----

(defun builtin-trans (point from to &optional displacement-p)
  ;; (trans POINT FROM TO [DISPLACEMENT-P])
  ;; Coordinate-system transform. With no host, every coordinate
  ;; space (WCS = 0, UCS = 1, DCS = 2, PSDCS = 3, entity Z-axis
  ;; ECS = (ENAME)) collapses to a single identity space — there's
  ;; no document loaded to define a UCS or a viewport DCS. We
  ;; therefore return the input point unchanged after validating
  ;; the FROM / TO arguments. This matches what Autodesk does on
  ;; a fresh empty drawing where UCS == WCS.
  ;;
  ;;; SPEC-UNCERTAIN: identity in a loaded drawing; 3D point to 2D
  ;;;   space (DCS/PSDCS) handling; DISPLACEMENT-P contract under
  ;;;   real UCS; FROM/TO as entity-name lists (ECS). Probes
  ;;;   queued in deferred-spec-research.issue § TRANS.
  (declare (ignore displacement-p))
  (require-proper-list point "TRANS")
  ;; FROM and TO may be integers (0/1/2/3) or entity-name lists.
  (unless (or (numberp from) (consp from)) ; permissive
    (signal-builtin-argument-error
     :invalid-trans-source "TRANS"
     "TRANS FROM must be an integer (0=WCS, 1=UCS, 2=DCS, 3=PSDCS) or an entity-name list, got ~S."
     from))
  (unless (or (numberp to) (consp to))
    (signal-builtin-argument-error
     :invalid-trans-target "TRANS"
     "TRANS TO must be an integer or an entity-name list, got ~S."
     to))
  ;; Coerce coordinates to double-float so the returned list is
  ;; numerically clean even if the input had integer slots.
  (let* ((x (coerce (require-number (nth 0 point) "TRANS") 'double-float))
         (y (coerce (require-number (nth 1 point) "TRANS") 'double-float))
         (z (if (>= (length point) 3)
                (coerce (require-number (nth 2 point) "TRANS") 'double-float)
                0.0d0)))
    (list x y z)))

(defun builtin-textbox (entity-list)
  ;; (textbox '((1 . "TEXT") (40 . 2.5))) -> ((x1 y1 z1) (x2 y2 z2))
  ;; Autodesk returns the bounding-box corners of a TEXT entity in
  ;; the text's OCS. Without a font-metrics back-end we approximate:
  ;; width = char-width × content-length, height = (40 . HEIGHT),
  ;; char-width = 0.6 × height (a common monospace ratio).
  ;; Returns ((0 0 0) (w h 0)). Stub-quality; full impl waits on
  ;; an SHX/TTF font loader.
  ;;
  ;;; SPEC-UNCERTAIN: char-width-to-height ratio in real CADs;
  ;;;   justification (DXF 72/73/40/41) effect on box origin;
  ;;;   behaviour on entity-lists missing group 1 or 40. Probes
  ;;;   queued in deferred-spec-research.issue § TEXTBOX.
  (require-proper-list entity-list "TEXTBOX")
  (let* ((text-pair (assoc 1 entity-list))
         (height-pair (assoc 40 entity-list))
         (text (cond ((and text-pair (typep (cdr text-pair) 'autolisp-string))
                      (autolisp-string-value (cdr text-pair)))
                     (t "")))
         (height (cond ((and height-pair (numberp (cdr height-pair)))
                        (coerce (cdr height-pair) 'double-float))
                       (t 1.0d0)))
         (width (* (length text) 0.6d0 height)))
    (list (list 0.0d0 0.0d0 0.0d0)
          (list width height 0.0d0))))

(defun builtin-vle-g-vectol ()
  ;; (vle_g_vectol) -> tolerance value used by VLE-VECTOR-* operators.
  ;; Documented as "geometric tolerance, double-float", default 1e-10.
  ;; Configurable via the same Visual LISP path Autodesk exposes — we
  ;; ship a session-scoped binding via a defparameter.
  *vle-vector-tolerance*)

(defparameter *vle-vector-tolerance* 1.0d-10
  "Tolerance used by VLE-VECTOR-* equality / parallelism /
codirectionality predicates. Land alongside VLE_G_VECTOL so
later M3 (vector math) functions can pick it up from one place.")

;;; ---- CLI no-ops (no graphics surface in a headless engine) ----
;;;
;;; All of the following ship as documented no-ops so portable user
;;; code that calls or boundp-checks them keeps running. Upgrade
;;; paths (lynx/w3m for SHOWHTMLMODALWINDOW, TUI for MENUCMD, etc.)
;;; are catalogued in `issues/open/deferred-stubbed-functions.issue'.

;;; STUB: graphics-screen toggle. See deferred-stubbed-functions.issue § Graphics-screen no-ops.
(defun builtin-graphscr ()         nil)
;;; STUB: text-screen toggle. See deferred-stubbed-functions.issue § Graphics-screen no-ops.
(defun builtin-textscr  ()         nil)
;;; STUB: text-page alias. See deferred-stubbed-functions.issue § Graphics-screen no-ops.
(defun builtin-textpage ()         nil)
;;; STUB: redraw display. See deferred-stubbed-functions.issue § Graphics-screen no-ops.
(defun builtin-redraw   (&rest _)
  (declare (ignore _))
  nil)
;;; STUB: set viewport view. See deferred-stubbed-functions.issue § SETVIEW.
(defun builtin-setview  (&rest _)
  (declare (ignore _))
  nil)
;;; STUB: tablet configuration. See deferred-stubbed-functions.issue § TABLET.
;;;
;;; Documented to set ERRNO on failure. Code 68 = "Digitizer is
;;; not a tablet" is the conservative default for any host that
;;; doesn't have a physical digitiser bound. The stubbed nil
;;; return is therefore accompanied by ERRNO=68.
(defun builtin-tablet   (&rest _)
  (declare (ignore _))
  (errno-and-return 68 nil))
;;; STUB: menu-command accessor. See deferred-stubbed-functions.issue § Menu system stubs.
(defun builtin-menucmd  (&optional _)
  (declare (ignore _))
  (make-autolisp-string ""))
;;; STUB: menu-group query. See deferred-stubbed-functions.issue § Menu system stubs.
(defun builtin-menugroup (&optional _)
  (declare (ignore _))
  nil)
;;; STUB: HTML modal dialog. See deferred-stubbed-functions.issue § SHOWHTMLMODALWINDOW.
(defun builtin-showhtmlmodalwindow (&rest _)
  (declare (ignore _))
  nil)

;;; ---- *error* mode helpers ----

(defun builtin-push-error-using-command ()
  ;; (*push-error-using-command*) -> nil. Pushes a :COMMAND frame
  ;; onto *autolisp-error-mode-stack*; host *error* handlers can
  ;; consult the top of the stack to format diagnostics using
  ;; (command) output instead of stack traces.
  (push :command *autolisp-error-mode-stack*)
  nil)

(defun builtin-push-error-using-stack ()
  ;; (*push-error-using-stack*) -> nil. Pushes a :STACK frame —
  ;; the host's *error* should emit a call stack on diagnostic.
  (push :stack *autolisp-error-mode-stack*)
  nil)

(defun builtin-pop-error-mode ()
  ;; (*pop-error-mode*) -> the popped mode keyword, or nil if the
  ;; stack was empty. Pairs with the two *push- variants above.
  (cond
    ((null *autolisp-error-mode-stack*) nil)
    (t (let ((top (pop *autolisp-error-mode-stack*)))
         (intern-autolisp-symbol (symbol-name top))))))

;;; --- end M2 -------------------------------------------------------

;;; --- M3a: VLE-* list/predicate/number helpers ---------------------
;;;
;;; Bricsys' Visual LISP Extensions library — name-prefix VLE-*.
;;; Almost all entries here have a matching Function Entry in
;;; autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org
;;; (BricsCAD V26 DevRef catalogue page is the upstream). Two
;;; classes of entry:
;;;
;;;   - "BricsCAD VLE Library Function" — full spec with
;;;     description / examples / return values. Reliable.
;;;
;;;   - "BricsCAD Extension Function" — terser one-liner of the
;;;     form "Optimised idiom for ..." with vendor-defined return
;;;     values. We follow the optimisation hint (e.g. VLE-CDRASSOC
;;;     == (cdr (assoc key alist))) and add SPEC-UNCERTAIN markers
;;;     where the exact return shape isn't pinned down.

;;; ---- Nth shortcuts (VLE-NTH0..NTH9, PUT-NTH, SUBST-NTH, REMOVE-NTH)

(defmacro define-vle-nth-shortcut (n)
  "Emit (defun builtin-vle-nthN (lst) (nth N lst)) so VLE-NTH0
through VLE-NTH9 share a single source spec without 10 hand-
written copies. Body matches the spec: 0-based index, returns
the element at position N or NIL if shorter."
  `(defun ,(intern (format nil "BUILTIN-VLE-NTH~D" n)) (lst)
     (require-proper-list lst ,(format nil "VLE-NTH~D" n))
     (nth ,n lst)))

(define-vle-nth-shortcut 0)
(define-vle-nth-shortcut 1)
(define-vle-nth-shortcut 2)
(define-vle-nth-shortcut 3)
(define-vle-nth-shortcut 4)
(define-vle-nth-shortcut 5)
(define-vle-nth-shortcut 6)
(define-vle-nth-shortcut 7)
(define-vle-nth-shortcut 8)
(define-vle-nth-shortcut 9)

(defun builtin-vle-put-nth (lst idx val)
  ;; (vle-put-nth lst idx val) — replace item at IDX; pad with NIL
  ;; if IDX > length; return lst unchanged if IDX < 0.
  (require-proper-list lst "VLE-PUT-NTH")
  (let ((i (require-int32 idx "VLE-PUT-NTH")))
    (cond
      ((minusp i) lst)
      (t (let ((result (copy-list lst)))
           (cond
             ((< i (length result))
              (setf (nth i result) val)
              result)
             (t
              ;; Pad with NIL up to position i, then append val.
              (append result
                      (make-list (- i (length result)) :initial-element nil)
                      (list val)))))))))

(defun builtin-vle-subst-nth (lst idx val)
  ;; (vle-subst-nth lst idx val) — replace item at IDX. Per spec,
  ;; the description matches VLE-PUT-NTH almost verbatim but
  ;; doesn't pin down the out-of-range behaviour. We take the
  ;; conservative interpretation: return lst unchanged when IDX
  ;; is out of range (no padding, no error).
  ;;
  ;;; SPEC-UNCERTAIN: out-of-range IDX in VLE-SUBST-NTH (pad like
  ;;;   VLE-PUT-NTH, or leave unchanged, or signal?). Probe queued
  ;;;   in deferred-spec-research.issue.
  (require-proper-list lst "VLE-SUBST-NTH")
  (let ((i (require-int32 idx "VLE-SUBST-NTH")))
    (cond
      ((or (minusp i) (>= i (length lst))) lst)
      (t (let ((result (copy-list lst)))
           (setf (nth i result) val)
           result)))))

(defun builtin-vle-remove-nth (idx lst)
  ;; (vle-remove-nth idx lst) — return lst without element at IDX.
  ;; Negative or out-of-range IDX returns lst unchanged.
  (let ((i (require-int32 idx "VLE-REMOVE-NTH")))
    (require-proper-list lst "VLE-REMOVE-NTH")
    (cond
      ((or (minusp i) (>= i (length lst))) lst)
      (t (append (subseq lst 0 i) (subseq lst (1+ i)))))))

;;; ---- List mutators (REMOVE-ALL, REMOVE-FIRST, REMOVE-LAST, LIST-SPLIT, SUBLIST)

(defun builtin-vle-remove-all (item lst)
  ;; (vle-remove-all item lst) — remove every occurrence of ITEM.
  ;; Equivalent to VL-REMOVE.
  (require-proper-list lst "VLE-REMOVE-ALL")
  (remove-if (lambda (e) (autolisp-value= e item)) lst))

(defun builtin-vle-remove-first (item lst)
  ;; (vle-remove-first item lst) — remove the first occurrence of
  ;; ITEM only.
  (require-proper-list lst "VLE-REMOVE-FIRST")
  (let ((removed nil))
    (remove-if (lambda (e)
                 (cond
                   (removed nil)
                   ((autolisp-value= e item) (setf removed t) t)
                   (t nil)))
               lst)))

(defun builtin-vle-remove-last (lst)
  ;; (vle-remove-last lst) — drop the last element (CL BUTLAST).
  ;; Spec wording ("Optimised drop-the-last-element on a list")
  ;; says ELEMENT, not "occurrence of item" — VLE-REMOVE-LAST is
  ;; a 1-arg function, not the symmetric counterpart of
  ;; VLE-REMOVE-FIRST.
  (require-proper-list lst "VLE-REMOVE-LAST")
  (butlast lst))

(defun builtin-vle-list-split (lst item)
  ;; (vle-list-split lst item) — split LST at ITEM and return both
  ;; parts. We interpret the result as a 2-list (head tail), with
  ;; ITEM dropped at the split point.
  ;;
  ;;; SPEC-UNCERTAIN: result shape (head tail) vs (head . tail);
  ;;;   whether the splitter item lands in head, in tail, or is
  ;;;   dropped; behaviour when ITEM not present. Probe queued in
  ;;;   deferred-spec-research.issue.
  (require-proper-list lst "VLE-LIST-SPLIT")
  (let ((tail (member-if (lambda (e) (autolisp-value= e item)) lst)))
    (cond
      ((null tail) (list lst nil))   ; not found
      (t (list (ldiff lst tail) (rest tail))))))

(defun builtin-vle-sublist (lst start-idx nritems)
  ;; (vle-sublist lst startidx nritems) — return NRITEMS items
  ;; from LST starting at STARTIDX (0-based). Clamps to list end.
  (require-proper-list lst "VLE-SUBLIST")
  (let* ((s (require-int32 start-idx "VLE-SUBLIST"))
         (n (require-int32 nritems   "VLE-SUBLIST"))
         (len (length lst)))
    (cond
      ((or (minusp s) (>= s len) (not (plusp n))) nil)
      (t (let ((end (min (+ s n) len)))
           (subseq lst s end))))))

;;; ---- Set-style list ops (LIST-DIFF, LIST-INTERSECT, LIST-SUBTRACT, LIST-UNION)

(defun autolisp-list-equal (a b)
  "Element-equality test matching VL-MEMBER's EQUAL-ish semantics —
the same predicate the set-style VLE-LIST-* operators apply when
deciding membership."
  (autolisp-value= a b))

(defun builtin-vle-list-diff (lst1 lst2)
  ;; (vle-list-diff lst1 lst2) — SYMMETRIC difference. Spec:
  ;; "all items, which are member of either 'lst1' or 'lst2', but
  ;; not member of both lists."
  (require-proper-list lst1 "VLE-LIST-DIFF")
  (require-proper-list lst2 "VLE-LIST-DIFF")
  (append (remove-if (lambda (x)
                       (some (lambda (y) (autolisp-list-equal x y)) lst2))
                     lst1)
          (remove-if (lambda (x)
                       (some (lambda (y) (autolisp-list-equal x y)) lst1))
                     lst2)))

(defun builtin-vle-list-intersect (lst1 lst2)
  ;; (vle-list-intersect lst1 lst2) — items in both lists.
  (require-proper-list lst1 "VLE-LIST-INTERSECT")
  (require-proper-list lst2 "VLE-LIST-INTERSECT")
  (remove-if-not (lambda (x)
                   (some (lambda (y) (autolisp-list-equal x y)) lst2))
                 lst1))

(defun builtin-vle-list-subtract (lst1 lst2)
  ;; (vle-list-subtract lst1 lst2) — set difference LST1 - LST2.
  (require-proper-list lst1 "VLE-LIST-SUBTRACT")
  (require-proper-list lst2 "VLE-LIST-SUBTRACT")
  (remove-if (lambda (x)
               (some (lambda (y) (autolisp-list-equal x y)) lst2))
             lst1))

(defun builtin-vle-list-union (lst1 lst2)
  ;; (vle-list-union lst1 lst2) — merge with duplicates removed.
  (require-proper-list lst1 "VLE-LIST-UNION")
  (require-proper-list lst2 "VLE-LIST-UNION")
  (let ((result '()))
    (dolist (x (append lst1 lst2))
      (unless (some (lambda (y) (autolisp-list-equal x y)) result)
        (push x result)))
    (nreverse result)))

;;; ---- Assoc family (CADRASSOC, CDRASSOC, SET-CDRASSOC, LIST-MASSOC)

(defun builtin-vle-cdrassoc (key alist)
  ;; (vle-cdrassoc key alist) — optimised (cdr (assoc key alist)).
  (require-proper-list alist "VLE-CDRASSOC")
  (let ((pair (assoc key alist :test #'autolisp-value=)))
    (and pair (cdr pair))))

(defun builtin-vle-cadrassoc (key alist)
  ;; (vle-cadrassoc key alist) — optimised (cadr (assoc key alist)).
  (require-proper-list alist "VLE-CADRASSOC")
  (let ((pair (assoc key alist :test #'autolisp-value=)))
    (cond
      ((null pair) nil)
      ((consp (cdr pair)) (cadr pair))
      (t nil))))

(defun builtin-vle-set-cdrassoc (key alist val)
  ;; (vle-set-cdrassoc key lst val) — set the cdr of every pair
  ;; whose car matches KEY. Returns the modified list.
  (require-proper-list alist "VLE-SET-CDRASSOC")
  (dolist (pair alist)
    (when (and (consp pair) (autolisp-value= (car pair) key))
      (setf (cdr pair) val)))
  alist)

(defun builtin-vle-list-massoc (key alist)
  ;; (vle-list-massoc key alist) — return the cdr of every pair
  ;; whose car matches KEY (multi-assoc). "all values using same
  ;; 'key' in assoc-list 'lst'".
  (require-proper-list alist "VLE-LIST-MASSOC")
  (let ((result '()))
    (dolist (pair alist)
      (when (and (consp pair) (autolisp-value= (car pair) key))
        (push (cdr pair) result)))
    (nreverse result)))

;;; ---- Other list helpers (APPEND, MEMBER, SEARCH)

(defun builtin-vle-append (&rest lists)
  ;; (vle-append . lists) — same as APPEND.
  (apply #'append lists))

(defun builtin-vle-member (item lst)
  ;; (vle-member item lst) — verifies whether LST contains ITEM.
  ;; Spec wording is loose: "verifies whether". We return the tail
  ;; starting at ITEM (matching VL-MEMBER / CL MEMBER), so the
  ;; result is truthy in IF / WHILE contexts and the user can pull
  ;; the tail when needed.
  ;;
  ;;; SPEC-UNCERTAIN: pure boolean (T/NIL) vs tail-returning. Probe
  ;;;   queued in deferred-spec-research.issue.
  (require-proper-list lst "VLE-MEMBER")
  (member item lst :test #'autolisp-value=))

(defun builtin-vle-search (item lst &optional as-idx)
  ;; (vle-search item lst asIdx) — search LST for ITEM. If ASIDX
  ;; is NIL or omitted, return the list starting at ITEM (CL
  ;; MEMBER semantics). If non-NIL, return the 0-based index.
  ;; NIL when ITEM isn't found.
  (require-proper-list lst "VLE-SEARCH")
  (let ((tail (member item lst :test #'autolisp-value=)))
    (cond
      ((null tail) nil)
      ((null as-idx) tail)
      (t (- (length lst) (length tail))))))

;;; ---- Type predicates (5 native + 4 stub)

(defun autolisp-true ()
  (intern-autolisp-symbol "T"))

(defun builtin-vle-integerp (x)
  (if (typep x '(signed-byte 32)) (autolisp-true) nil))

(defun builtin-vle-realp (x)
  (if (typep x 'double-float) (autolisp-true) nil))

(defun builtin-vle-numberp (x)
  (if (numberp x) (autolisp-true) nil))

(defun builtin-vle-stringp (x)
  (if (typep x 'autolisp-string) (autolisp-true) nil))

(defun builtin-vle-pointp (x)
  ;; A point is a list of 2 or 3 numbers.
  (cond
    ((not (consp x)) nil)
    ((not (member (length x) '(2 3))) nil)
    ((every #'numberp x) (autolisp-true))
    (t nil)))

(defun builtin-vle-enamep (x)
  ;; Stub-style native: clautolisp has an autolisp-ename type but
  ;; the runtime test image doesn't always import it; fall back
  ;; to find-symbol guarded.
  (let ((class (find-symbol "AUTOLISP-ENAME" '#:clautolisp.autolisp-runtime)))
    (if (and class (typep x class))
        (autolisp-true)
        nil)))

;;; STUB: VARIANTP — no ActiveX VARIANT type in clautolisp. See deferred-stubbed-functions.issue § VLE COM predicates.
(defun builtin-vle-variantp    (x) (declare (ignore x)) nil)
;;; STUB: SAFEARRAYP — no SAFEARRAY type. See deferred-stubbed-functions.issue § VLE COM predicates.
(defun builtin-vle-safearrayp  (x) (declare (ignore x)) nil)
;;; STUB: VLAOBJECTP — VLA objects exist only under the mock-host ActiveX bridge; not visible from the bare runtime. See deferred-stubbed-functions.issue § VLE COM predicates.
(defun builtin-vle-vlaobjectp  (x) (declare (ignore x)) nil)

(defun builtin-vle-picksetp (x)
  ;; PICKSET is a real type in autolisp-runtime — promote out of
  ;; the stub group.
  (let ((class (find-symbol "AUTOLISP-PICKSET" '#:clautolisp.autolisp-runtime)))
    (if (and class (typep x class))
        (autolisp-true)
        nil)))

;;; ---- Number conversions (CEILING, FLOOR, ROUND, ROUNDTO, ATOI32, ITOA32, INT64TO32, TAN)

(defun clamp-to-int32 (n)
  "Sign-extending 32-bit truncation matching the VLE-*32 family's
contract: AutoCAD's 32-bit integer wrap."
  (let* ((mask (1- (ash 1 32)))
         (mod  (logand n mask)))
    (if (>= mod (ash 1 31))
        (- mod (ash 1 32))
        mod)))

(defun builtin-vle-ceiling (x)
  (let ((n (require-number x "VLE-CEILING")))
    (ceiling n)))

(defun builtin-vle-floor (x)
  (let ((n (require-number x "VLE-FLOOR")))
    (floor n)))

(defun builtin-vle-round (x)
  (let ((n (require-number x "VLE-ROUND")))
    (round n)))

(defun builtin-vle-roundto (x digits)
  ;; (vle-roundto x digits) — round to DIGITS decimal places.
  (let* ((n (coerce (require-number x "VLE-ROUNDTO") 'double-float))
         (d (require-int32 digits "VLE-ROUNDTO"))
         (factor (expt 10.0d0 d)))
    (/ (coerce (round (* n factor)) 'double-float) factor)))

(defun builtin-vle-atoi32 (numstr)
  ;; (vle-atoi32 numstr) — parse string to 32-bit signed int.
  ;; Truncates 64-bit values to 32-bit (matching the BricsCAD
  ;; contract for x64 builds).
  (let* ((s (autolisp-string-value (require-string numstr "VLE-ATOI32")))
         (parsed (or (ignore-errors (parse-integer s :junk-allowed t)) 0)))
    (clamp-to-int32 parsed)))

(defun builtin-vle-itoa32 (intval)
  ;; (vle-itoa32 intval) — render integer in 32-bit form.
  (let ((clamped (clamp-to-int32 (require-int32 intval "VLE-ITOA32"))))
    (make-autolisp-string (format nil "~D" clamped))))

(defun builtin-vle-int64to32 (intval)
  ;; (vle-int64to32 intval) — truncate integer to 32-bit signed.
  (clamp-to-int32 (require-int32 intval "VLE-INT64TO32")))

(defun builtin-vle-tan (x)
  (let ((n (coerce (require-number x "VLE-TAN") 'double-float)))
    (tan n)))

;;; --- end M3a ------------------------------------------------------

;;; --- M3b: VLE-VECTOR-* math ---------------------------------------
;;;
;;; All operators in this sub-batch take 2D or 3D point/vector
;;; lists (lists of 2 or 3 numbers) and return 3D vectors / numbers
;;; / T-or-nil predicates. Z defaults to 0.0d0 when omitted on
;;; input; outputs are always 3D unless the spec explicitly says
;;; otherwise (VLE-VECTOR-TO2D). Tolerance for equality /
;;; parallelism / codirectionality predicates is read from
;;; *vle-vector-tolerance* (installed in M2 via VLE_G_VECTOL).

(defun coerce-vec3 (v operator-name)
  "Coerce a 2D or 3D point/vector list to three double-float
multiple values (x y z); Z defaults to 0.0d0 when V is a 2-element
list. Errors out via require-* helpers if V isn't a proper list of
numbers."
  (require-proper-list v operator-name)
  (let* ((len (length v)))
    (unless (member len '(2 3))
      (signal-builtin-argument-error
       :invalid-vector operator-name
       "~A vector must be a list of 2 or 3 numbers, got ~D-element list."
       operator-name len))
    (values (coerce (require-number (nth 0 v) operator-name) 'double-float)
            (coerce (require-number (nth 1 v) operator-name) 'double-float)
            (if (= len 3)
                (coerce (require-number (nth 2 v) operator-name) 'double-float)
                0.0d0))))

(defun vec3-list (x y z) (list x y z))

(defun vec3-dot (ax ay az bx by bz)
  (+ (* ax bx) (* ay by) (* az bz)))

(defun vec3-cross (ax ay az bx by bz)
  (vec3-list (- (* ay bz) (* az by))
             (- (* az bx) (* ax bz))
             (- (* ax by) (* ay bx))))

(defun vec3-length (x y z)
  (sqrt (+ (* x x) (* y y) (* z z))))

(defun vec3-zero-p (x y z &optional (tol *vle-vector-tolerance*))
  (< (vec3-length x y z) tol))

(defun vec3-normalize (x y z &optional (tol *vle-vector-tolerance*))
  "Return (values nx ny nz) for the unit vector; (values nil nil nil)
when the input is zero-length under TOL."
  (let ((len (vec3-length x y z)))
    (cond
      ((< len tol) (values nil nil nil))
      (t (values (/ x len) (/ y len) (/ z len))))))

(defun builtin-vle-vector-get (from to)
  ;; (vle-vector-get from to) -> 3D vector from FROM to TO.
  (multiple-value-bind (fx fy fz) (coerce-vec3 from "VLE-VECTOR-GET")
    (multiple-value-bind (tx ty tz) (coerce-vec3 to "VLE-VECTOR-GET")
      (vec3-list (- tx fx) (- ty fy) (- tz fz)))))

(defun builtin-vle-vector-add (v1 v2)
  (multiple-value-bind (ax ay az) (coerce-vec3 v1 "VLE-VECTOR-ADD")
    (multiple-value-bind (bx by bz) (coerce-vec3 v2 "VLE-VECTOR-ADD")
      (vec3-list (+ ax bx) (+ ay by) (+ az bz)))))

(defun builtin-vle-vector-sub (v1 v2)
  (multiple-value-bind (ax ay az) (coerce-vec3 v1 "VLE-VECTOR-SUB")
    (multiple-value-bind (bx by bz) (coerce-vec3 v2 "VLE-VECTOR-SUB")
      (vec3-list (- ax bx) (- ay by) (- az bz)))))

(defun builtin-vle-vector-negate (v)
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-NEGATE")
    (vec3-list (- x) (- y) (- z))))

(defun builtin-vle-vector-scale (v factor)
  (let ((f (coerce (require-number factor "VLE-VECTOR-SCALE") 'double-float)))
    (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-SCALE")
      (vec3-list (* x f) (* y f) (* z f)))))

(defun builtin-vle-vector-midpoint (p1 p2)
  (multiple-value-bind (ax ay az) (coerce-vec3 p1 "VLE-VECTOR-MIDPOINT")
    (multiple-value-bind (bx by bz) (coerce-vec3 p2 "VLE-VECTOR-MIDPOINT")
      (vec3-list (/ (+ ax bx) 2.0d0)
                 (/ (+ ay by) 2.0d0)
                 (/ (+ az bz) 2.0d0)))))

(defun builtin-vle-vector-normalise (v)
  ;; British spelling per the spec; AutoCAD docs use the same form.
  ;; Returns nil for a zero-length input (Autodesk's documented
  ;; "undefined" case — we surface nil instead of erroring).
  ;;
  ;;; SPEC-UNCERTAIN: zero-length input — return nil (our choice)
  ;;;   vs return zero vector vs signal. Probe queued in
  ;;;   deferred-spec-research.issue § VLE-VECTOR-NORMALISE.
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-NORMALISE")
    (multiple-value-bind (nx ny nz) (vec3-normalize x y z)
      (and nx (vec3-list nx ny nz)))))

(defun builtin-vle-vector-dotproduct (v1 v2)
  (multiple-value-bind (ax ay az) (coerce-vec3 v1 "VLE-VECTOR-DOTPRODUCT")
    (multiple-value-bind (bx by bz) (coerce-vec3 v2 "VLE-VECTOR-DOTPRODUCT")
      (vec3-dot ax ay az bx by bz))))

(defun builtin-vle-vector-crossproduct (v1 v2)
  (multiple-value-bind (ax ay az) (coerce-vec3 v1 "VLE-VECTOR-CROSSPRODUCT")
    (multiple-value-bind (bx by bz) (coerce-vec3 v2 "VLE-VECTOR-CROSSPRODUCT")
      (vec3-cross ax ay az bx by bz))))

(defun builtin-vle-vector-angleto (v1 v2)
  ;; Unsigned angle between v1 and v2 (radians, in [0, π]).
  (multiple-value-bind (ax ay az) (coerce-vec3 v1 "VLE-VECTOR-ANGLETO")
    (multiple-value-bind (bx by bz) (coerce-vec3 v2 "VLE-VECTOR-ANGLETO")
      (let* ((la (vec3-length ax ay az))
             (lb (vec3-length bx by bz)))
        (cond
          ((or (< la *vle-vector-tolerance*)
               (< lb *vle-vector-tolerance*))
           0.0d0)
          (t (let ((cos-theta (/ (vec3-dot ax ay az bx by bz) (* la lb))))
               ;; clamp cos-theta to [-1, 1] to defeat fp noise
               (acos (max -1.0d0 (min 1.0d0 cos-theta))))))))))

(defun builtin-vle-vector-angletoref (v1 v2 normal)
  ;; Signed angle between v1 and v2 in the plane defined by NORMAL.
  ;; Sign is determined by (cross v1 v2) · normal — positive when
  ;; cross is codirectional with normal.
  (multiple-value-bind (ax ay az) (coerce-vec3 v1 "VLE-VECTOR-ANGLETOREF")
    (multiple-value-bind (bx by bz) (coerce-vec3 v2 "VLE-VECTOR-ANGLETOREF")
      (multiple-value-bind (nx ny nz) (coerce-vec3 normal "VLE-VECTOR-ANGLETOREF")
        (let* ((unsigned (builtin-vle-vector-angleto v1 v2))
               (cross (vec3-cross ax ay az bx by bz))
               (sign-dot (vec3-dot (nth 0 cross) (nth 1 cross) (nth 2 cross)
                                   nx ny nz)))
          (if (minusp sign-dot) (- unsigned) unsigned))))))

(defun builtin-vle-vector-length (v)
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-LENGTH")
    (vec3-length x y z)))

(defun builtin-vle-vector-length2d (v)
  ;; XY-plane projection length.
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-LENGTH2D")
    (declare (ignore z))
    (vec3-length x y 0.0d0)))

(defun builtin-vle-vector-length2dxz (v)
  ;; XZ-plane projection length.
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-LENGTH2DXZ")
    (declare (ignore y))
    (vec3-length x 0.0d0 z)))

(defun builtin-vle-vector-length2dyz (v)
  ;; YZ-plane projection length.
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-LENGTH2DYZ")
    (declare (ignore x))
    (vec3-length 0.0d0 y z)))

(defun builtin-vle-vector-isunitlength (v)
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-ISUNITLENGTH")
    (if (< (abs (- (vec3-length x y z) 1.0d0)) *vle-vector-tolerance*)
        (autolisp-true) nil)))

(defun builtin-vle-vector-isequal (v1 v2)
  (multiple-value-bind (ax ay az) (coerce-vec3 v1 "VLE-VECTOR-ISEQUAL")
    (multiple-value-bind (bx by bz) (coerce-vec3 v2 "VLE-VECTOR-ISEQUAL")
      (if (and (< (abs (- ax bx)) *vle-vector-tolerance*)
               (< (abs (- ay by)) *vle-vector-tolerance*)
               (< (abs (- az bz)) *vle-vector-tolerance*))
          (autolisp-true) nil))))

(defun builtin-vle-vector-iszerolength (v)
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-ISZEROLENGTH")
    (if (vec3-zero-p x y z) (autolisp-true) nil)))

(defun builtin-vle-vector-isparallel (v1 v2)
  ;; Parallel iff cross product is zero (under tolerance).
  (multiple-value-bind (ax ay az) (coerce-vec3 v1 "VLE-VECTOR-ISPARALLEL")
    (multiple-value-bind (bx by bz) (coerce-vec3 v2 "VLE-VECTOR-ISPARALLEL")
      (let ((c (vec3-cross ax ay az bx by bz)))
        (if (vec3-zero-p (nth 0 c) (nth 1 c) (nth 2 c))
            (autolisp-true) nil)))))

(defun builtin-vle-vector-iscodirectional (v1 v2)
  ;; Parallel AND pointing the same way (dot > 0).
  (multiple-value-bind (ax ay az) (coerce-vec3 v1 "VLE-VECTOR-ISCODIRECTIONAL")
    (multiple-value-bind (bx by bz) (coerce-vec3 v2 "VLE-VECTOR-ISCODIRECTIONAL")
      (let* ((c (vec3-cross ax ay az bx by bz))
             (parallel-p (vec3-zero-p (nth 0 c) (nth 1 c) (nth 2 c)))
             (same-dir-p (plusp (vec3-dot ax ay az bx by bz))))
        (if (and parallel-p same-dir-p) (autolisp-true) nil)))))

(defun builtin-vle-vector-isperpendicular (v1 v2)
  ;; Perpendicular iff dot product is zero.
  (multiple-value-bind (ax ay az) (coerce-vec3 v1 "VLE-VECTOR-ISPERPENDICULAR")
    (multiple-value-bind (bx by bz) (coerce-vec3 v2 "VLE-VECTOR-ISPERPENDICULAR")
      (if (< (abs (vec3-dot ax ay az bx by bz)) *vle-vector-tolerance*)
          (autolisp-true) nil))))

(defun vec3-equal-axis-p (x y z ax ay az)
  (and (< (abs (- x ax)) *vle-vector-tolerance*)
       (< (abs (- y ay)) *vle-vector-tolerance*)
       (< (abs (- z az)) *vle-vector-tolerance*)))

(defun builtin-vle-vector-isxaxis (v)
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-ISXAXIS")
    (if (vec3-equal-axis-p x y z 1.0d0 0.0d0 0.0d0) (autolisp-true) nil)))

(defun builtin-vle-vector-isyaxis (v)
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-ISYAXIS")
    (if (vec3-equal-axis-p x y z 0.0d0 1.0d0 0.0d0) (autolisp-true) nil)))

(defun builtin-vle-vector-iszaxis (v)
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-ISZAXIS")
    (if (vec3-equal-axis-p x y z 0.0d0 0.0d0 1.0d0) (autolisp-true) nil)))

(defun builtin-vle-vector-getperpvector (v)
  ;; Returns a 3D vector perpendicular to V. Cross V with whichever
  ;; axis has the smallest absolute component (avoiding the near-
  ;; parallel case).
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-GETPERPVECTOR")
    (let* ((ax (abs x)) (ay (abs y)) (az (abs z)))
      (cond
        ((and (<= ax ay) (<= ax az))
         (vec3-cross x y z 1.0d0 0.0d0 0.0d0))
        ((and (<= ay ax) (<= ay az))
         (vec3-cross x y z 0.0d0 1.0d0 0.0d0))
        (t
         (vec3-cross x y z 0.0d0 0.0d0 1.0d0))))))

(defun builtin-vle-vector-getucs (normal)
  ;; AutoCAD's "Arbitrary Axis Algorithm" — given a Z-axis (NORMAL),
  ;; return the (X-axis Y-axis) basis pair that defines the
  ;; entity's OCS / UCS.
  ;;
  ;;; SPEC-UNCERTAIN: orientation when normal == ±world-Z (the
  ;;;   algorithm has a 1/64 threshold; we match Autodesk's
  ;;;   documented formula but haven't probe-validated against a
  ;;;   real CAD). Queued in deferred-spec-research.issue.
  (multiple-value-bind (nx ny nz) (coerce-vec3 normal "VLE-VECTOR-GETUCS")
    (multiple-value-bind (unx uny unz) (vec3-normalize nx ny nz)
      (when (null unx)
        (return-from builtin-vle-vector-getucs nil))
      (let* ((threshold (/ 1.0d0 64.0d0))
             ;; Reference up: world-Y if normal is near vertical,
             ;; otherwise world-Z.
             (use-world-y-p (and (< (abs unx) threshold)
                                 (< (abs uny) threshold)))
             (ref (if use-world-y-p
                      (list 0.0d0 1.0d0 0.0d0)
                      (list 0.0d0 0.0d0 1.0d0)))
             (ax-cross (vec3-cross (nth 0 ref) (nth 1 ref) (nth 2 ref)
                                    unx uny unz))
             (ax-vec (multiple-value-bind (x y z)
                         (vec3-normalize (nth 0 ax-cross)
                                          (nth 1 ax-cross)
                                          (nth 2 ax-cross))
                       (and x (vec3-list x y z))))
             (ay-cross (and ax-vec
                            (vec3-cross unx uny unz
                                         (nth 0 ax-vec) (nth 1 ax-vec) (nth 2 ax-vec))))
             (ay-vec  (and ay-cross
                           (multiple-value-bind (x y z)
                               (vec3-normalize (nth 0 ay-cross)
                                                (nth 1 ay-cross)
                                                (nth 2 ay-cross))
                             (and x (vec3-list x y z))))))
        (and ax-vec ay-vec (list ax-vec ay-vec))))))

(defun builtin-vle-vector-to2d (v)
  ;; Drop Z; return a 2-element list.
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-TO2D")
    (declare (ignore z))
    (list x y)))

(defun builtin-vle-vector-to3d (v)
  ;; Pad Z to 0.0 if input is 2D; pass through if already 3D.
  (multiple-value-bind (x y z) (coerce-vec3 v "VLE-VECTOR-TO3D")
    (vec3-list x y z)))

(defun builtin-vle-vector-gettolerance ()
  *vle-vector-tolerance*)

(defun builtin-vle-vector-settolerance (tol)
  (let ((new-tol (coerce (require-number tol "VLE-VECTOR-SETTOLERANCE")
                          'double-float)))
    (setf *vle-vector-tolerance* new-tol)
    new-tol))

;;; --- end M3b ------------------------------------------------------

;;; --- M3c: VLE-* string / file / color / misc ----------------------

(defun builtin-vle-string-replace (new-str old-str in-string)
  ;; (vle-string-replace newStr oldStr inString) — replace EVERY
  ;; occurrence of OLD-STR with NEW-STR in IN-STRING.
  ;;
  ;;; SPEC-UNCERTAIN: replace-first vs replace-all. The Bricsys
  ;;;   description ("new string replacing oldStr") doesn't pin
  ;;;   it down; we chose replace-all because that matches the
  ;;;   common idiom and the function isn't named "replace-first".
  ;;;   Probe queued in deferred-spec-research.issue.
  (let ((needle (autolisp-string-value (require-string old-str "VLE-STRING-REPLACE")))
        (rep    (autolisp-string-value (require-string new-str "VLE-STRING-REPLACE")))
        (hay    (autolisp-string-value (require-string in-string "VLE-STRING-REPLACE"))))
    (cond
      ((zerop (length needle)) (make-autolisp-string hay))
      (t
       (let ((out (make-string-output-stream))
             (cursor 0)
             (nl (length needle)))
         (loop
           (let ((pos (search needle hay :start2 cursor)))
             (cond
               ((null pos)
                (write-string (subseq hay cursor) out)
                (return))
               (t
                (write-string (subseq hay cursor pos) out)
                (write-string rep out)
                (setf cursor (+ pos nl))))))
         (make-autolisp-string (get-output-stream-string out)))))))

(defun builtin-vle-string-split (keys string)
  ;; (vle-string-split keys string) — tokenise STRING on any of
  ;; the characters in KEYS. Empty tokens between consecutive
  ;; delimiters are kept (matches the BricsCAD reference output).
  ;;
  ;;; SPEC-UNCERTAIN: empty-token handling between adjacent
  ;;;   delimiters. We keep them; BricsCAD might collapse them.
  ;;;   Probe queued in deferred-spec-research.issue.
  (let ((k (autolisp-string-value (require-string keys "VLE-STRING-SPLIT")))
        (s (autolisp-string-value (require-string string "VLE-STRING-SPLIT"))))
    (let ((result '())
          (cursor 0))
      (loop
        for i from cursor below (length s)
        when (find (char s i) k :test #'char=)
          do (push (make-autolisp-string (subseq s cursor i)) result)
             (setf cursor (1+ i)))
      (push (make-autolisp-string (subseq s cursor)) result)
      (nreverse result))))

(defun builtin-vle-file->list (filename comment-char)
  ;; (vle-file->list filename commentchar) — slurp FILENAME into a
  ;; list of one autolisp-string per line. When COMMENT-CHAR is
  ;; a non-NIL string, any line whose first non-whitespace
  ;; character matches its first character is dropped.
  (let* ((path (autolisp-string-value (require-string filename "VLE-FILE->LIST")))
         (skip-char
           (cond
             ((null comment-char) nil)
             ((typep comment-char 'autolisp-string)
              (let ((s (autolisp-string-value comment-char)))
                (and (plusp (length s)) (char s 0))))
             (t nil))))
    (handler-case
        (with-open-file (stream path :direction :input
                                     :if-does-not-exist nil)
          (cond
            ((null stream) nil)
            (t (let ((lines '()))
                 (loop
                   for line = (read-line stream nil nil)
                   while line
                   do (let ((first-non-ws (position-if-not
                                            (lambda (c) (member c '(#\Space #\Tab)))
                                            line)))
                        (unless (and skip-char
                                     first-non-ws
                                     (char= (char line first-non-ws) skip-char))
                          (push (make-autolisp-string line) lines))))
                 (nreverse lines)))))
      (error () nil))))

(defun builtin-vle-filep (obj)
  ;; (vle-filep obj) — T iff OBJ is an autolisp-file (OPEN'd handle).
  (let ((class (find-symbol "AUTOLISP-FILE" '#:clautolisp.autolisp-runtime)))
    (if (and class (typep obj class))
        (autolisp-true) nil)))

(defun builtin-vle-file-encoding (handle &optional encoding)
  ;; (vle-file-encoding HANDLE [ENCODING])
  ;; The actual BricsCAD function declares the encoding to use on
  ;; future I/O against HANDLE. Without a way to re-bind the
  ;; external-format on an already-open CL stream portably, we
  ;; surface this as a query-only stub: returns the session's
  ;; *autolisp-file-encoding* (which the CLI installs) and ignores
  ;; the per-handle ENCODING argument.
  ;;
  ;;; STUB: per-handle encoding re-bind. See deferred-stubbed-functions.issue
  ;;;   § VLE-FILE-ENCODING. (Possible upgrade: track the encoding in
  ;;;   the autolisp-file wrapper and re-open the underlying stream
  ;;;   on change — non-trivial but feasible.)
  (declare (ignore handle encoding))
  (multiple-value-bind (value boundp)
      (lookup-variable (intern-autolisp-symbol "*AUTOLISP-FILE-ENCODING*"))
    (cond
      ((and boundp (typep value 'autolisp-string)) value)
      (t (make-autolisp-string "UTF-8")))))

;;; ---- ACI palette + RGB conversions ----
;;;
;;; The AutoCAD Color Index (ACI) is a 256-entry palette. We ship a
;;; partial table covering the well-defined slots — 0 (ByBlock,
;;; black for paint purposes), 1-9 (basic colors), 250-255 (grayscale
;;; ramp). The 10-249 range is the algorithmic
;;; hue x saturation x brightness palette that AutoCAD computes
;;; from a fixed scheme; we leave those slots NIL until the full
;;; table is vendor-validated (entry queued in
;;; deferred-spec-research.issue § VLE-ACI2RGB).

(defparameter *aci-base-palette*
  ;; (INDEX R G B)
  '((0   0   0   0)      ; ByBlock — black on paint
    (1   255 0   0)      ; red
    (2   255 255 0)      ; yellow
    (3   0   255 0)      ; green
    (4   0   255 255)    ; cyan
    (5   0   0   255)    ; blue
    (6   255 0   255)    ; magenta
    (7   255 255 255)    ; white (or black on a white background)
    (8   128 128 128)    ; dark grey
    (9   192 192 192)    ; light grey
    (250 51  51  51)     ; grey ramp
    (251 91  91  91)
    (252 132 132 132)
    (253 173 173 173)
    (254 214 214 214)
    (255 255 255 255))
  "Well-defined entries of the AutoCAD ACI palette. Indices 10-249
are the algorithmic hue ring and are not yet covered — see
deferred-spec-research.issue § VLE-ACI2RGB.")

(defun aci-palette-lookup (index)
  "Return the (R G B) triple for INDEX, or NIL when INDEX is in
the un-tabulated 10-249 range."
  (let ((row (assoc index *aci-base-palette*)))
    (and row (rest row))))

(defun builtin-vle-aci2rgb (color)
  ;; (vle-aci2rgb color) -> (R G B) list, or NIL for indices we
  ;; haven't tabulated yet (10-249).
  ;;
  ;;; SPEC-UNCERTAIN: ACI 10-249 range. We return NIL there until
  ;;;   the full 256-entry palette is checked-in. Probe queued in
  ;;;   deferred-spec-research.issue § VLE-ACI2RGB.
  (let* ((idx (require-int32 color "VLE-ACI2RGB"))
         (rgb (aci-palette-lookup idx)))
    (and rgb (list (nth 0 rgb) (nth 1 rgb) (nth 2 rgb)))))

(defun builtin-vle-rgb2aci (rgb)
  ;; (vle-rgb2aci rgb) — find the nearest ACI index for the given
  ;; RGB. Spec is loose on the argument shape (single 24-bit
  ;; integer vs 3 separate values); we accept the most common
  ;; in-practice form: a 3-element list (R G B), each 0-255.
  ;;
  ;;; SPEC-UNCERTAIN: argument shape. Spec arguments list mentions
  ;;;   both "an integer specifying the RGB value" and three
  ;;;   separate red/green/blue ints. We accept the list form.
  ;;;   Probe queued in deferred-spec-research.issue § VLE-RGB2ACI.
  (require-proper-list rgb "VLE-RGB2ACI")
  (unless (= 3 (length rgb))
    (signal-builtin-argument-error
     :invalid-rgb "VLE-RGB2ACI"
     "VLE-RGB2ACI expects a 3-element (R G B) list, got ~D-element list."
     (length rgb)))
  (let* ((r (require-int32 (nth 0 rgb) "VLE-RGB2ACI"))
         (g (require-int32 (nth 1 rgb) "VLE-RGB2ACI"))
         (b (require-int32 (nth 2 rgb) "VLE-RGB2ACI"))
         (best-idx nil)
         (best-d2 nil))
    (dolist (row *aci-base-palette*)
      (let* ((idx (first row))
             (rr  (second row))
             (gg  (third row))
             (bb  (fourth row))
             (d2  (+ (expt (- r rr) 2)
                     (expt (- g gg) 2)
                     (expt (- b bb) 2))))
        (when (or (null best-d2) (< d2 best-d2))
          (setf best-d2 d2  best-idx idx))))
    (or best-idx 7)))

;;; ---- Misc ----

(defun builtin-vle-startapp (cmd args mode)
  ;; (vle-startapp cmd args mode) — launch CMD with optional ARGS
  ;; (string or NIL). MODE T waits for the process; NIL runs it
  ;; in the background. Returns the PID on success, NIL on failure.
  (let* ((cmd-str (autolisp-string-value (require-string cmd "VLE-STARTAPP")))
         (args-str (cond
                     ((null args) nil)
                     (t (autolisp-string-value (require-string args "VLE-STARTAPP")))))
         (argv (cond
                 ((and args-str (plusp (length args-str)))
                  (list* cmd-str (autolisp-string-tokenise args-str)))
                 (t (list cmd-str))))
         (wait-p (autolisp-true-p mode)))
    (handler-case
        (cond
          (wait-p
           (uiop:run-program argv :output nil :error-output nil
                                   :ignore-error-status t)
           (autolisp-true))
          (t
           (let ((proc (uiop:launch-program argv :output nil :error-output nil)))
             (or (ignore-errors (uiop:process-info-pid proc)) (autolisp-true)))))
      (error () nil))))

(defun autolisp-string-tokenise (s)
  "Naive whitespace split of S, returning a list of tokens. Used
by VLE-STARTAPP to convert the spec's single-string args form
into the argv list uiop:run-program wants."
  (let ((result '())
        (cursor 0))
    (loop for i from 0 below (length s)
          when (member (char s i) '(#\Space #\Tab))
            do (when (< cursor i)
                 (push (subseq s cursor i) result))
               (setf cursor (1+ i)))
    (when (< cursor (length s))
      (push (subseq s cursor) result))
    (nreverse result)))

(defun builtin-vle-ping-alive ()
  ;; (vle-ping-alive) — Windows "I'm still alive" signal; always
  ;; T in our headless engine.
  (autolisp-true))

;;; STUB: Bricsys LISP optimiser is a no-op in clautolisp (no
;;; bytecode compile step). See deferred-stubbed-functions.issue
;;; § VLE-OPTIMISER/OPTIMIZER.
(defun builtin-vle-optimiser  (flag) (declare (ignore flag)) nil)
;;; STUB: alias of OPTIMISER (US spelling).
(defun builtin-vle-optimizer  (flag) (declare (ignore flag)) nil)
;;; STUB: BricsCAD "Fast-COM" is a no-op in clautolisp (no COM).
(defun builtin-vle-fastcom    (flag) (declare (ignore flag)) nil)

;;; --- end M3c ------------------------------------------------------

;;; --- M3d: VLE-* CAD / COM / UI stubs ------------------------------
;;;
;;; These VLE-* functions all need the entity database, the
;;; ActiveX/COM bridge, the SAFEARRAY type, the pickset/selection
;;; surface, the dictionary store, the table store, or the
;;; interactive Bricsys IDE — none of which the in-process
;;; clautolisp engine carries. Each ships as a register-and-return-
;;; documented-no-op stub with a `;;; STUB:` marker pointing at the
;;; matching entry in deferred-stubbed-functions.issue.

;;; STUB: VLE-ALERT — Bricsys' message dialog. Print to *error-output* + return nil.
(defun builtin-vle-alert (msg)
  (let ((text (autolisp-string-value (require-string msg "VLE-ALERT"))))
    (format *error-output* "~&[ALERT] ~A~%" text)
    (force-output *error-output*))
  nil)

;;; STUB: VLE-COLLECTION->LIST — needs ActiveX collection. See deferred-stubbed-functions.issue.
(defun builtin-vle-collection->list (col) (declare (ignore col)) nil)
;;; STUB: VLE-COMPILE-SHAPE — SHX shape compile; out of scope.
(defun builtin-vle-compile-shape (&rest _) (declare (ignore _)) nil)
;;; STUB: VLE-CURVE-GETPERIMETER — needs entity DB.
(defun builtin-vle-curve-getperimeter (ename) (declare (ignore ename)) nil)
;;; STUB: VLE-DICTIONARY-LIST — needs named-object dictionary.
(defun builtin-vle-dictionary-list (&optional dict-ename) (declare (ignore dict-ename)) nil)
;;; STUB: VLE-DICTOBJNAME — needs dictionary store.
(defun builtin-vle-dictobjname (&rest _) (declare (ignore _)) nil)
;;; STUB: VLE-DICTSEARCH — needs dictionary store.
(defun builtin-vle-dictsearch (&rest _) (declare (ignore _)) nil)
;;; STUB: VLE-DISPLAYPAUSE — UI display pause; no-op in headless.
(defun builtin-vle-displaypause () nil)
;;; STUB: VLE-DISPLAYUPDATE — UI display refresh.
(defun builtin-vle-displayupdate () nil)
;;; STUB: VLE-EDITTEXTINPLACE — interactive in-place text edit.
(defun builtin-vle-edittextinplace (&rest _) (declare (ignore _)) nil)
;;; STUB: VLE-ENABLESERVERBUSY — Windows COM server-busy guard.
(defun builtin-vle-enableserverbusy (flag) (declare (ignore flag)) nil)
;;; STUB: VLE-ENAME-VALID — needs entity DB; with no entities, always nil.
(defun builtin-vle-ename-valid (ename) (declare (ignore ename)) nil)
;;; STUB: VLE-END-TRANSACTION — needs transaction manager.
(defun builtin-vle-end-transaction () nil)
;;; STUB: VLE-ENTGET — needs entity DB.
(defun builtin-vle-entget (ename) (declare (ignore ename)) nil)
;;; STUB: VLE-ENTGET-M — multi-entity entget; needs entity DB.
(defun builtin-vle-entget-m (enames) (declare (ignore enames)) nil)
;;; STUB: VLE-ENTGET-MASSOC — entget + cadrassoc combo.
(defun builtin-vle-entget-massoc (&rest _) (declare (ignore _)) nil)
;;; STUB: VLE-ENTMOD — entity-modify; needs entity DB.
(defun builtin-vle-entmod (data) (declare (ignore data)) nil)
;;; STUB: VLE-ENTMOD-M — batched entmod.
(defun builtin-vle-entmod-m (datas) (declare (ignore datas)) nil)
;;; STUB: VLE-EXTENSIONS-ACTIVE — BricsCAD VLE-loaded flag. T (we register the names).
(defun builtin-vle-extensions-active () (autolisp-true))
;;; STUB: VLE-GETGEOMEXTENTS — needs entity DB.
(defun builtin-vle-getgeomextents (ename) (declare (ignore ename)) nil)
;;; STUB: VLE-HIDEPROMPTMENU — interactive UI menu; no-op in headless.
(defun builtin-vle-hidepromptmenu () nil)
;;; STUB: VLE-SHOWPROMPTMENU — interactive UI menu; no-op in headless.
(defun builtin-vle-showpromptmenu (&rest _) (declare (ignore _)) nil)
;;; STUB: VLE-IS-CURVE — entity predicate; needs entity DB.
(defun builtin-vle-is-curve (ename) (declare (ignore ename)) nil)
;;; STUB: VLE-LICENSELEVEL — BricsCAD license tier; static "PRO" placeholder.
(defun builtin-vle-licenselevel () (make-autolisp-string "FULL"))
;;; STUB: VLE-LISPINSTALL — BricsCAD install path.
(defun builtin-vle-lispinstall () (make-autolisp-string ""))
;;; STUB: VLE-LISPVERSION — VLE library version string.
(defun builtin-vle-lispversion () (make-autolisp-string "0.0"))
;;; STUB: VLE-NTH<X> — spec entry is the template that VLE-NTH0..NTH9 instantiate; no callable function under that exact name. Registered as a no-op so boundp probes succeed.
(defun builtin-vle-nth<x> (&rest _) (declare (ignore _)) nil)
;;; STUB: VLE-SAFEARRAY->LIST — needs SAFEARRAY (no COM in clautolisp).
(defun builtin-vle-safearray->list (sa) (declare (ignore sa)) nil)
;;; STUB: VLE-SELECTIONSET->LIST — needs pickset surface in a driven CAD; returns nil here.
(defun builtin-vle-selectionset->list (ss) (declare (ignore ss)) nil)
;;; STUB: VLE-START-TRANSACTION — needs transaction manager.
(defun builtin-vle-start-transaction () nil)
;;; STUB: VLE-SUNID — Bricsys sun-ID generator; returns a placeholder integer.
(defun builtin-vle-sunid () 0)
;;; STUB: VLE-TABLE-LIST — needs CAD symbol-table store.
(defun builtin-vle-table-list (name) (declare (ignore name)) nil)
;;; STUB: VLE-TABLE-LIST-ALL — needs CAD symbol-table store.
(defun builtin-vle-table-list-all (name) (declare (ignore name)) nil)
;;; STUB: VLE-TBLSEARCH — needs CAD symbol-table store.
(defun builtin-vle-tblsearch (table-name entry &optional setnext) (declare (ignore table-name entry setnext)) nil)

;;; --- end M3d ------------------------------------------------------

;;; --- M4: VLISP-* IDE stubs ----------------------------------------
;;;
;;; The Visual LISP IDE family — bytecode compile, VLX-namespace
;;; symbol export/import, optimiser toggle. clautolisp has no
;;; separate compile step and no VLX/application namespace
;;; structure (every loaded file lands in the single session
;;; namespace), so all five operators ship as register-and-stub
;;; with STUB markers. Two of them (EXPORT-SYMBOL and IMPORT-SYMBOL)
;;; do record arguments into a per-session table so debuggers can
;;; observe that the calls happened, but the recorded state is
;;; never consulted — there's no namespace for it to gate.

(defparameter *vlisp-exported-symbols* nil
  "Per-session list of symbol-name strings the user has handed to
VLISP-EXPORT-SYMBOL. clautolisp has no VLX namespace, so this
list is record-only — nothing consults it. Documented so an
upgrade path (when VLX namespaces land) doesn't have to invent
the parameter from scratch.")

(defun vlisp-symbol-or-list->names (arg operator-name)
  "VLISP-EXPORT-SYMBOL / IMPORT-SYMBOL accept either a single
symbol/string or a list of them. Returns a flat list of upcased
name strings."
  (cond
    ((null arg) nil)
    ((typep arg 'autolisp-symbol)
     (list (autolisp-symbol-name arg)))
    ((typep arg 'autolisp-string)
     (list (string-upcase (autolisp-string-value arg))))
    ((consp arg)
     (let ((names '()))
       (dolist (e arg)
         (cond
           ((typep e 'autolisp-symbol)
            (push (autolisp-symbol-name e) names))
           ((typep e 'autolisp-string)
            (push (string-upcase (autolisp-string-value e)) names))
           (t
            (signal-builtin-argument-error
             :invalid-symbol-designator operator-name
             "~A list entry must be a symbol or string, got ~S."
             operator-name e))))
       (nreverse names)))
    (t (signal-builtin-argument-error
        :invalid-symbol-designator operator-name
        "~A expects a symbol, string, or list of them, got ~S."
        operator-name arg))))

;;; STUB: VLISP-COMPILE — no separate compile step in clautolisp;
;;; future upgrade could emit FASL via compile-file. See
;;; deferred-stubbed-functions.issue § VLISP-* IDE stubs.
(defun builtin-vlisp-compile (mode source-file &optional out-file)
  (declare (ignore mode source-file out-file))
  nil)

;;; STUB: VLISP-EXPORT-SYMBOL — records names in
;;; *vlisp-exported-symbols* (observable from CL) but doesn't
;;; gate any real VLX namespace. Returns T per the BricsCAD
;;; reference page's documented success value.
(defun builtin-vlisp-export-symbol (arg)
  (let ((names (vlisp-symbol-or-list->names arg "VLISP-EXPORT-SYMBOL")))
    (dolist (n names)
      (pushnew n *vlisp-exported-symbols* :test #'string=))
    (autolisp-true)))

;;; STUB: VLISP-IMPORT-SYMBOL — VLX namespaces don't exist in
;;; clautolisp, so "importing" is a no-op. Returns T.
(defun builtin-vlisp-import-symbol (arg)
  (let ((names (vlisp-symbol-or-list->names arg "VLISP-IMPORT-SYMBOL")))
    (declare (ignore names))
    (autolisp-true)))

;;; STUB: VLISP-IMPORT-EXSUBRS — pulls vendor-extension subrs
;;; into the current namespace. Already imported globally in
;;; clautolisp; no-op returning T.
(defun builtin-vlisp-import-exsubrs (&rest _)
  (declare (ignore _))
  (autolisp-true))

;;; STUB: VLISP-OPTIMIZER — no bytecode optimiser in clautolisp.
;;; Per the BricsCAD reference description: queries when called
;;; with no argument, toggles when called with T/NIL. We return
;;; nil unconditionally (no optimiser to query, nothing to
;;; toggle). See deferred-stubbed-functions.issue § VLISP-* IDE stubs.
(defun builtin-vlisp-optimizer (&optional flag)
  (declare (ignore flag))
  nil)

;;; --- end M4 -------------------------------------------------------

;;; --- M5: core/misc rest (missing-functions.issue) -----------------
;;;
;;; The remaining 70-ish core/misc operators from
;;; missing-functions.issue: VL-* management, VL-ANNOTATIVE-*,
;;; VL-SUBENT-*, VL-VPLAYER-*, VL-LOCAL-UNDO-*, VL-REGISTRY-*,
;;; ActiveX property accessors, BricsCAD-specific flags, GETCFG /
;;; SETCFG, etc. Most are stubs (CAD/COM-coupled); ~8 ship with
;;; real behaviour, two families (registry, cfg) ship with
;;; session-table impls that preserve API round-trip semantics
;;; even though state doesn't yet survive process exit.
;;;
;;; CVUNIT, COMMAND-S, and UNTIL stay deferred per
;;; missing-functions-plan.md (CVUNIT needs the acad.unt unit-
;;; definitions file; COMMAND-S waits on the COMMAND host work;
;;; UNTIL needs Autodesk-side verification — Bricsys may or may
;;; not ship it). SPEC-UNCERTAIN markers point at
;;; deferred-spec-research.issue for the open questions.

;;; ---- Native M5 ----

(defun builtin-vl-init ()
  ;; (vl-init) — Bricsys' "load Visual LISP base" call. In
  ;; clautolisp the VLE-* set is always loaded; T (success).
  (autolisp-true))

(defun builtin-vl-load-com () (autolisp-true))      ; no COM bridge; success.
(defun builtin-vl-load-reactors () (autolisp-true)) ; no reactors yet; success.
(defun builtin-vl-load-all () (autolisp-true))      ; alias of the above.

(defun builtin-vl-enable-user-cancel (flag)
  ;; (vl-enable-user-cancel T|nil) — toggle whether Ctrl-C
  ;; interrupts user code. SBCL/CCL already deliver SIGINT to
  ;; the REPL, so we accept the flag and return T (success)
  ;; without rewiring the handler.
  ;;
  ;;; SPEC-UNCERTAIN: behaviour when called mid-loop. We accept
  ;;;   the flag silently; AutoCAD may install/remove the
  ;;;   handler atomically. Probe queued in
  ;;;   deferred-spec-research.issue § VL-ENABLE-USER-CANCEL.
  (declare (ignore flag))
  (autolisp-true))

(defun builtin-layoutlist ()
  ;; (layoutlist) — list of layout-tab names. With no drawing
  ;; loaded the only layout is "Model".
  (list (make-autolisp-string "Model")))

(defun builtin-acdimenableupdate (&optional flag)
  ;; (acdimenableupdate [flag]) — toggle dimension-auto-update.
  ;; No dimensions in a headless engine; accept and return T.
  (declare (ignore flag))
  (autolisp-true))

(defun builtin-vports ()
  ;; (vports) — list of viewports. Without a drawing, return the
  ;; documented single-viewport sentinel.
  (list (list 1
              (list 0.0d0 0.0d0)        ; lower-left corner (DCS)
              (list 1.0d0 1.0d0))))     ; upper-right corner (DCS)

;;; ---- Session-state M5 (record-only registry / cfg) ----

(defparameter *vl-registry* (make-hash-table :test 'equal)
  "In-memory session-table backing VL-REGISTRY-* calls. Keyed by
the full registry path (a string); values are autolisp-strings.
Survives only for the running process — see
deferred-stubbed-functions.issue § VL-REGISTRY-* for the
JSON-backed persistent upgrade path.")

(defparameter *acad-cfg* (make-hash-table :test 'equal)
  "In-memory session-table backing GETCFG / SETCFG. Keyed by the
full ACAD-style path string; values are autolisp-strings.
Survives only for the running process — see
deferred-stubbed-functions.issue § GETCFG/SETCFG for the file-
backed persistent upgrade path.")

(defun builtin-vl-registry-read (key &optional value-name)
  ;; (vl-registry-read key [valuename]) — read a Windows-registry
  ;; key. clautolisp keeps a per-session hash backing; the
  ;; "[valuename]" sub-key is concatenated to the path for our
  ;; lookup, mirroring how VL-REGISTRY-WRITE encodes it.
  (let* ((k (autolisp-string-value (require-string key "VL-REGISTRY-READ")))
         (v (and value-name
                 (autolisp-string-value
                  (require-string value-name "VL-REGISTRY-READ"))))
         (full (if v (format nil "~A|~A" k v) k))
         (stored (gethash full *vl-registry*)))
    (or stored nil)))

(defun builtin-vl-registry-write (key value-name value)
  ;; (vl-registry-write key valuename value) — write to the
  ;; registry. Stored in *vl-registry*; returns VALUE on success.
  (let* ((k (autolisp-string-value (require-string key "VL-REGISTRY-WRITE")))
         (v (autolisp-string-value (require-string value-name "VL-REGISTRY-WRITE")))
         (data (require-string value "VL-REGISTRY-WRITE"))
         (full (format nil "~A|~A" k v)))
    (setf (gethash full *vl-registry*) data)
    data))

(defun builtin-vl-registry-delete (key &optional value-name)
  ;; (vl-registry-delete key [valuename]) — delete a key or value.
  ;; Returns T on success, NIL when the key wasn't present.
  (let* ((k (autolisp-string-value (require-string key "VL-REGISTRY-DELETE")))
         (v (and value-name
                 (autolisp-string-value
                  (require-string value-name "VL-REGISTRY-DELETE"))))
         (full (if v (format nil "~A|~A" k v) k)))
    (cond
      ((gethash full *vl-registry*)
       (remhash full *vl-registry*)
       (autolisp-true))
      (t nil))))

(defun builtin-vl-registry-descendents (key &optional value-names-p)
  ;; (vl-registry-descendents key [valuenames]) — list immediate
  ;; sub-keys (or value-names) at KEY. We do a prefix scan over
  ;; the in-memory table.
  (let* ((k (autolisp-string-value (require-string key "VL-REGISTRY-DESCENDENTS")))
         (prefix (concatenate 'string k "|"))
         (results '()))
    (maphash (lambda (full _)
               (declare (ignore _))
               (when (and (>= (length full) (length prefix))
                          (string= prefix full :end2 (length prefix)))
                 (push (subseq full (length prefix)) results)))
             *vl-registry*)
    (cond
      ((null results) nil)
      (t (mapcar #'make-autolisp-string
                 (if value-names-p
                     (sort (remove-duplicates results :test #'string=)
                           #'string<)
                     (sort (remove-duplicates results :test #'string=)
                           #'string<)))))))

(defun builtin-getcfg (path)
  ;; (getcfg path) — read a value from the AppData section.
  ;; Returns the autolisp-string value or NIL.
  (let* ((k (autolisp-string-value (require-string path "GETCFG"))))
    (or (gethash k *acad-cfg*) nil)))

(defun builtin-setcfg (path value)
  ;; (setcfg path value) — write a value into AppData. Returns
  ;; the new value on success.
  (let* ((k (autolisp-string-value (require-string path "SETCFG")))
         (v (require-string value "SETCFG")))
    (setf (gethash k *acad-cfg*) v)
    v))

;;; ---- Stubs (CAD/COM/UI-coupled, no host) ----
;;;
;;; All return nil unless documented otherwise; STUB markers point
;;; at deferred-stubbed-functions.issue § M5 stubs.

;;; STUB: ACDIM-style read-onlys. See deferred-stubbed-functions.issue § M5 stubs.
(defun builtin-ads () nil)
;;; STUB: INITDIA — initial-dialog flag.
(defun builtin-initdia (&optional flag) (declare (ignore flag)) nil)
;;; STUB: INSPECTOR — Visual LISP IDE inspector.
(defun builtin-inspector (&optional obj) (declare (ignore obj)) nil)
;;; STUB: DLG-SYSVARS — sysvar dialog (Visual LISP UI).
(defun builtin-dlg-sysvars (&rest _) (declare (ignore _)) nil)
;;; STUB: EXPAND — Lisp memory-area expansion. Auto-managed by CL GC.
(defun builtin-expand (segments) segments)
;;; STUB: LISP$INSTALL — VLISP install info.
(defun builtin-lisp$install () nil)
;;; STUB: LISP$ENABLEFASTCOM — VLISP fast-COM toggle.
(defun builtin-lisp$enablefastcom (&optional flag) (declare (ignore flag)) nil)
;;; STUB: BPOLY — boundary polyline creation; needs CAD geometry.
(defun builtin-bpoly (&rest _) (declare (ignore _)) nil)

;;; STUB: BricsCAD-specific status helpers.
(defun builtin-bcad$disable-extended-error (&optional flag) (declare (ignore flag)) nil)
(defun builtin-bcad$licenselevels () nil)

;;; STUB: VMON — Visual LISP memory monitor toggle.
(defun builtin-vmon () nil)
;;; STUB: _VLAX-SAFEARRAY-MODE — internal ActiveX SAFEARRAY policy.
(defun builtin-_vlax-safearray-mode (&optional mode) (declare (ignore mode)) nil)

;;; STUB: ActiveX property accessors — no COM in clautolisp.
(defun builtin-listallproperties (obj) (declare (ignore obj)) nil)
(defun builtin-dumpallproperties (obj &optional depth) (declare (ignore obj depth)) nil)
(defun builtin-ispropertyreadonly (obj name) (declare (ignore obj name)) nil)
(defun builtin-ispropertyvalid    (obj name) (declare (ignore obj name)) nil)
(defun builtin-getpropertyvalue   (obj name) (declare (ignore obj name)) nil)
(defun builtin-setpropertyvalue   (obj name value) (declare (ignore obj name value)) nil)

;;; STUB: VL-* management surface.
(defun builtin-vl-list-loaded-lisp ()  nil) ; we don't track per-load filenames yet
(defun builtin-vl-list-loaded-vlx ()   nil) ; no VLX system
(defun builtin-vl-vlx-loaded-p (name)  (declare (ignore name)) nil)
(defun builtin-vl-unload-vlx (name)    (declare (ignore name)) nil)
(defun builtin-vl-list-exported-functions (&optional name) (declare (ignore name)) nil)
(defun builtin-vl-vbaload  (file) (declare (ignore file)) nil)
(defun builtin-vl-vbarun   (proc) (declare (ignore proc)) nil)
(defun builtin-vl-cmdf     (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-acad-defun   (sym ns) (declare (ignore sym ns)) (autolisp-true))
(defun builtin-vl-acad-undefun (sym ns) (declare (ignore sym ns)) (autolisp-true))
(defun builtin-vl-get-resource (name)   (declare (ignore name)) nil)
(defun builtin-vl-getgeomextents (ename) (declare (ignore ename)) nil)
(defun builtin-vl-hidepromptmenu  () (autolisp-true))
(defun builtin-vl-showpromptmenu  (&rest _) (declare (ignore _)) (autolisp-true))

;;; STUB: VL-LOCAL-UNDO-* (5) — local-scope undo stack; not wired
;;; to a real transactional store. All return nil.
(defun builtin-vl-local-undo-clear ()  nil)
(defun builtin-vl-local-undo-pop ()    nil)
(defun builtin-vl-local-undo-push ()   nil)
(defun builtin-vl-local-undo-reset ()  nil)
(defun builtin-vl-local-undo-steps ()  nil)

;;; STUB: VL-ANNOTATIVE-* (11) — annotative-scale machinery.
(defun builtin-vl-annotative-addscale       (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-annotative-get            (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-annotative-getscales      (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-annotative-remove         (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-annotative-removescale    (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-annotative-reset          (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-annotative-scalelist      (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-annotative-set            (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-annotative-setscales      (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-annotative-supported      (&rest _) (declare (ignore _)) nil)

;;; STUB: VL-SUBENT-* (5) — subentity operations.
(defun builtin-vl-subent-atpoint   (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-subent-select    (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-subent-ssadd     (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-subent-ssdel     (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-subent-ssmemb    (&rest _) (declare (ignore _)) nil)

;;; STUB: VL-VPLAYER-* (9) — viewport-layer property accessors.
(defun builtin-vl-vplayer-get-color         (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-vplayer-get-linetype      (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-vplayer-get-lineweight    (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-vplayer-get-transparency  (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-vplayer-set-color         (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-vplayer-set-linetype      (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-vplayer-set-lineweight    (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-vplayer-set-transparency  (&rest _) (declare (ignore _)) nil)
(defun builtin-vl-vplayer-set-truecolor     (&rest _) (declare (ignore _)) nil)

;;; STUB: VL-VECTOR-PROJECT-POINTTOENTITY — needs entity geometry.
(defun builtin-vl-vector-project-pointtoentity (&rest _)
  (declare (ignore _))
  nil)

;;; --- end M5 -------------------------------------------------------

;;; ====================================================================
;;; M6: ALERT (real impl) + register-and-stub of the remaining
;;; AutoLISP / Visual LISP inventory.
;;;
;;; Resolves issues/closed/missing-functions.issue. After M1-M5, ~411
;;; documented operators were still not bound to anything. M6 closes
;;; the gap surface-level:
;;;
;;;   * ALERT lands as a real builtin. Vendor docs document it as a
;;;     modal-dialog UI; clautolisp is headless so the in-process
;;;     fallback the user proposed (princ "WARNING: " + message +
;;;     newline) ships as the default behaviour.
;;;
;;;   * Every other family-listed identifier is registered as a
;;;     nil-returning stub. The point is to make
;;;     (boundp 'X), (functionp #'X), and (X args...) all not signal
;;;     :undefined-function — portable code that probes the surface
;;;     for feature detection keeps running, and rather than crashing
;;;     mid-script on an unknown call, the call evaluates to nil
;;;     (the documented "no-op stub" convention used throughout M3/
;;;     M4/M5).
;;;
;;; Real implementations are gated on the Host Abstraction Layer
;;; phases (entity DB, selection sets, dictionary store, COM bridge,
;;; ActiveX SAFEARRAY type, reactor dispatch) and tracked per-family
;;; in issues/open/deferred-stubbed-functions.issue.
;;;
;;; Families covered (count from the missing-functions.issue inventory):
;;;   ACET::* internal (8)
;;;   ACET-* (258)
;;;   VLAX-* (46)
;;;   VLA-* (2)
;;;   VLR-* (4)
;;;   DOS_* (22)
;;;   LAYERSTATE-* / VL-LAYERSTATES-* (24)
;;;   ARX* (5)
;;;   ACAD* (7)
;;;   Entity / selection-set / table / dictionary database (14)
;;;   DCL dialogs / tiles (3)
;;;   GR* graphics primitives (7)
;;;   GET* / INITGET interactive prompts (6, including ALERT)

(defun builtin-alert (message)
  "(ALERT message) — surface MESSAGE to the user. AutoCAD / BricsCAD
ship a modal dialog with an OK button; clautolisp is headless, so
the in-process implementation emits a single-line
`WARNING: MESSAGE' to *standard-output*. Returns nil. Real
dialog-bridging upgrade tracked in
issues/open/deferred-stubbed-functions.issue § ALERT."
  (let ((text (autolisp-string-value (require-string message "ALERT"))))
    (princ "WARNING: ")
    (princ text)
    (terpri)
    nil))

(defun %builtin-m6-stub (&rest arguments)
  "Generic nil-returning stub the M6 inventory installs under every
documented-but-unimplemented operator. The function ignores its
arguments and returns nil. Per-family upgrade paths are tracked in
issues/open/deferred-stubbed-functions.issue."
  (declare (ignore arguments))
  nil)

(defun make-m6-stub-subr (name)
  "Build an autolisp-subr that registers NAME as a nil-returning
stub. Used by CORE-BUILTINS to bulk-install the M6 inventory."
  (make-autolisp-subr name #'%builtin-m6-stub))

(defparameter *m6-stub-names*
  ;; The 411-item inventory from issues/closed/missing-functions.issue.
  ;; ALERT is intentionally NOT in this list — it has a real impl
  ;; above. Each line below is one family from the inventory.
  '(;; ACET::* internal (8)
    "ACET::ACOS" "ACET::ARC-POINT-LIST" "ACET::EXPANDFN" "ACET::FILETYPE"
    "ACET::NAMEONLY" "ACET::NORMALIZE-FILENAME" "ACET::PATHONLY"
    "ACET::PL-POINT-LIST"
    ;; ACET-* (258)
    "ACET-ACAD-REFRESH" "ACET-ALERT" "ACET-ANGLE-EQUAL" "ACET-ANGLE-FORMAT"
    "ACET-ANNOTATION-SS" "ACET-APPID-DELETE" "ACET-ARXLOAD-OR-BUST"
    "ACET-ATT-SUBSCRIPT-DUPLICATES" "ACET-AUTOLOAD" "ACET-AUTOLOAD2"
    "ACET-AUTOLOADARX" "ACET-BLINK-AND-SHOW-OBJECT" "ACET-BLK-MATCH"
    "ACET-BLKTBL-MATCH" "ACET-BLOCK-MAKE-ANON" "ACET-BLOCK-PURGE"
    "ACET-BS-STRIP" "ACET-CALC-BITLIST" "ACET-CALC-ROUND" "ACET-CALC-TAN"
    "ACET-CLEAR-TEMP-GRAPHICS" "ACET-CMD-EXIT" "ACET-COPYM"
    "ACET-COPYTOLAYER" "ACET-CURRENTVIEWPORT-ENAME" "ACET-DCL-LIST-MAKE"
    "ACET-DICT-ENAME" "ACET-DICT-NAME-LIST" "ACET-DTOR" "ACET-DXF"
    "ACET-ELIST-ADD-DEFAULTS" "ACET-ENT-CURVEPOINTS" "ACET-ENT-GEOMEXTENTS"
    "ACET-ERROR-INIT" "ACET-ERROR-RESTORE" "ACET-EXPLODE" "ACET-FILE-ATTR"
    "ACET-FILE-BACKUP" "ACET-FILE-BACKUP-DELETE" "ACET-FILE-CHDIR"
    "ACET-FILE-COPY" "ACET-FILE-CWD" "ACET-FILE-DIR" "ACET-FILE-FIND"
    "ACET-FILE-FIND-FONT" "ACET-FILE-FIND-IMAGE" "ACET-FILE-FIND-ON-PATH"
    "ACET-FILE-MKDIR" "ACET-FILE-MOVE" "ACET-FILE-OPEN"
    "ACET-FILE-READDIALOG" "ACET-FILE-REMOVE" "ACET-FILE-RMDIR"
    "ACET-FILE-WRITEDIALOG" "ACET-FILENAME-ASSOCIATED-APP"
    "ACET-FILENAME-DIRECTORY" "ACET-FILENAME-EXT-REMOVE"
    "ACET-FILENAME-EXTENSION" "ACET-FILENAME-PATH-REMOVE"
    "ACET-FILENAME-SUPPORTPATH-REMOVE" "ACET-FILENAME-VALID"
    "ACET-FSCREEN-TOGGLE" "ACET-GENERAL-PROPS-GET"
    "ACET-GENERAL-PROPS-GET-PAIRS" "ACET-GENERAL-PROPS-SET"
    "ACET-GENERAL-PROPS-SET-PAIRS" "ACET-GEOM-ANGLE-TRANS"
    "ACET-GEOM-ARBITRARY-X" "ACET-GEOM-ARC-3P-D-ANGLE"
    "ACET-GEOM-ARC-BULGE" "ACET-GEOM-ARC-CENTER" "ACET-GEOM-ARC-D-ANGLE"
    "ACET-GEOM-CALC-ARC-ERROR" "ACET-GEOM-CROSS-PRODUCT"
    "ACET-GEOM-DELTA-VECTOR" "ACET-GEOM-IMAGE-BOUNDS"
    "ACET-GEOM-INTERSECTWITH" "ACET-GEOM-IS-ARC" "ACET-GEOM-LIST-EXTENTS"
    "ACET-GEOM-M-TRANS" "ACET-GEOM-MID-POINT" "ACET-GEOM-MIDPOINT"
    "ACET-GEOM-OBJECT-END-POINTS" "ACET-GEOM-OBJECT-FUZ"
    "ACET-GEOM-OBJECT-NORMAL-VECTOR" "ACET-GEOM-OBJECT-POINT-LIST"
    "ACET-GEOM-OBJECT-Z-AXIS" "ACET-GEOM-PIXEL-UNIT"
    "ACET-GEOM-PLINE-ARC-INFO" "ACET-GEOM-POINT-INSIDE"
    "ACET-GEOM-POINT-ROTATE" "ACET-GEOM-POINT-SCALE"
    "ACET-GEOM-RECT-POINTS" "ACET-GEOM-SELF-INTERSECT"
    "ACET-GEOM-SS-EXTENTS" "ACET-GEOM-TEXTBOX" "ACET-GEOM-UNIT-VECTOR"
    "ACET-GEOM-VECTOR-ADD" "ACET-GEOM-VECTOR-D-ANGLE"
    "ACET-GEOM-VECTOR-PARALLEL" "ACET-GEOM-VECTOR-SCALE"
    "ACET-GEOM-VECTOR-SIDE" "ACET-GEOM-VERTEX-LIST"
    "ACET-GEOM-VIEW-POINTS" "ACET-GEOM-Z-AXIS"
    "ACET-GEOM-ZOOM-FOR-SELECT" "ACET-GET-ATT" "ACET-GET-WINFONT-PATH"
    "ACET-GETVAR" "ACET-GROUP-MAKE-ANON" "ACET-GROUPS-SEL"
    "ACET-GROUPS-UNSEL" "ACET-HELP" "ACET-HELP-TRAP" "ACET-INI-GET"
    "ACET-INI-SET" "ACET-INIT-FAS-LIB" "ACET-INSERT-ATTRIB-GET"
    "ACET-INSERT-ATTRIB-MOD" "ACET-INSERT-ATTRIB-SET"
    "ACET-LAYER-LOCKED" "ACET-LAYER-OFF" "ACET-LAYER-UNLOCK-ALL"
    "ACET-LAYERP-MARK" "ACET-LAYERP-MODE" "ACET-LAYTRANS"
    "ACET-LIST-ASSOC-APPEND" "ACET-LIST-ASSOC-PUT"
    "ACET-LIST-ASSOC-REMOVE" "ACET-LIST-GROUP-BY-ASSOC"
    "ACET-LIST-IS-DOTTED-PAIR" "ACET-LIST-ISORT" "ACET-LIST-M-ASSOC"
    "ACET-LIST-PUT-NTH" "ACET-LIST-REMOVE-ADJACENT-DUPS"
    "ACET-LIST-REMOVE-DUPLICATE-POINTS" "ACET-LIST-REMOVE-DUPLICATES"
    "ACET-LIST-REMOVE-NTH" "ACET-LIST-SPLIT" "ACET-LIST-TO-SS"
    "ACET-LOAD-EXPRESSTOOLS" "ACET-LWPLINE-MAKE" "ACET-MOD-ATT"
    "ACET-MS-TO-PS" "ACET-PLINE-IS-2D" "ACET-PLINE-SEGMENT-LIST"
    "ACET-PLINE-SEGMENT-LIST-APPLY" "ACET-PLINES-EXPLODE"
    "ACET-PLINES-REBUILD" "ACET-POINT-FLAT" "ACET-PREF-SUPPORTPATH-LIST"
    "ACET-PS-TO-MS" "ACET-REG-DEL" "ACET-REG-GET"
    "ACET-REG-MACHINE-PRODKEY" "ACET-REG-PRODKEY" "ACET-REG-PUT"
    "ACET-REG-USER-PRODKEY" "ACET-ROTATE-TEXT" "ACET-RTOD"
    "ACET-SAFE-COMMAND" "ACET-SET-CMDECHO" "ACET-SETVAR"
    "ACET-SHX-LOADED" "ACET-SHX-RELOAD" "ACET-SPINNER"
    "ACET-SS-ANNOTATION-FILTER" "ACET-SS-CLEAR-PREV"
    "ACET-SS-DRAG-MOVE" "ACET-SS-DRAG-ROTATE" "ACET-SS-DRAG-SCALE"
    "ACET-SS-ENTDEL" "ACET-SS-FILTER" "ACET-SS-FILTER-CURRENT-UCS"
    "ACET-SS-FLT-CSPACE" "ACET-SS-INTERSECTION" "ACET-SS-MOD"
    "ACET-SS-NEW" "ACET-SS-REDRAW" "ACET-SS-REMOVE"
    "ACET-SS-REMOVE-DUPS" "ACET-SS-SCALE-TO-FIT" "ACET-SS-SORT"
    "ACET-SS-SSGET-FILTER" "ACET-SS-TO-LIST" "ACET-SS-UNION"
    "ACET-SS-VISIBLE" "ACET-SS-ZOOM-EXTENTS" "ACET-STR-COLLATE"
    "ACET-STR-EQUAL" "ACET-STR-ESC-WILDCARDS" "ACET-STR-FIND"
    "ACET-STR-FORMAT" "ACET-STR-LR-TRIM" "ACET-STR-M-FIND"
    "ACET-STR-REPLACE" "ACET-STR-SPACE-TRIM" "ACET-STR-TO-LIST"
    "ACET-STR-WCMATCH" "ACET-SYS-BEEP" "ACET-SYS-COMMAND"
    "ACET-SYS-CONTROL-DOWN" "ACET-SYS-FOREGROUND" "ACET-SYS-KEYSTATE"
    "ACET-SYS-LASTERR" "ACET-SYS-LMOUSE-DOWN" "ACET-SYS-MMOUSE-DOWN"
    "ACET-SYS-PROCID" "ACET-SYS-RMOUSE-DOWN" "ACET-SYS-SHIFT-DOWN"
    "ACET-SYS-SLEEP" "ACET-SYS-SPAWN" "ACET-SYS-TERM"
    "ACET-SYS-WAIT" "ACET-SYSVAR-RESTORE" "ACET-SYSVAR-SET"
    "ACET-TABLE-NAME-LIST" "ACET-TABLE-PURGE" "ACET-TBL-MATCH"
    "ACET-TEMP-SEGMENT" "ACET-TEXT2MTEXT" "ACET-TJUST"
    "ACET-TJUST-KEYWORD" "ACET-UCS-CMD" "ACET-UCS-GET"
    "ACET-UCS-SET" "ACET-UCS-SET-Z" "ACET-UCS-TO-OBJECT"
    "ACET-UI-ENTSEL" "ACET-UI-FENCE-SELECT" "ACET-UI-GET-LONG-NAME"
    "ACET-UI-GETCORNER" "ACET-UI-GETFILE" "ACET-UI-M-GET-NAMES"
    "ACET-UI-MESSAGE" "ACET-UI-PICKDIR" "ACET-UI-POLYGON-SELECT"
    "ACET-UI-PROGRESS" "ACET-UI-PROGRESS-DONE"
    "ACET-UI-PROGRESS-INIT" "ACET-UI-PROGRESS-SAFE"
    "ACET-UI-SINGLE-SELECT" "ACET-UI-STATUS" "ACET-UI-TABLE-NAME-GET"
    "ACET-UI-TABLE-NAME-GET-CMD" "ACET-UI-TABLE-NAME-GET-DLG"
    "ACET-UI-TXTED" "ACET-UNDO-BEGIN" "ACET-UNDO-END" "ACET-UTIL-VER"
    "ACET-VAR-GETVAR" "ACET-VAR-SETVAR"
    "ACET-VIEWPORT-FROZEN-LAYER-LIST" "ACET-VIEWPORT-LOCK-SET"
    "ACET-VIEWPORT-NEXT-PICKABLE" "ACET-WMFIN" "ACET-XDATA-GET"
    "ACET-XDATA-SET"
    ;; VLAX-* (46)
    "VLAX-2D-POINT" "VLAX-3D-POINT" "VLAX-ADD-CMD"
    "VLAX-CURVE-GETAREA" "VLAX-CURVE-GETCLOSESTPOINTTO"
    "VLAX-CURVE-GETCLOSESTPOINTTOPROJECTION"
    "VLAX-CURVE-GETDISTATPARAM" "VLAX-CURVE-GETDISTATPOINT"
    "VLAX-CURVE-GETENDPARAM" "VLAX-CURVE-GETENDPOINT"
    "VLAX-CURVE-GETFIRSTDERIV" "VLAX-CURVE-GETPARAMATDIST"
    "VLAX-CURVE-GETPARAMATPOINT" "VLAX-CURVE-GETPERIMETER"
    "VLAX-CURVE-GETPOINTATDIST" "VLAX-CURVE-GETPOINTATPARAM"
    "VLAX-CURVE-GETSECONDDERIV" "VLAX-CURVE-GETSTARTPARAM"
    "VLAX-CURVE-GETSTARTPOINT" "VLAX-CURVE-ISCLOSED"
    "VLAX-CURVE-ISPERIODIC" "VLAX-CURVE-ISPLANAR"
    "VLAX-DUMP-OBJECT" "VLAX-ENAME->VLA-OBJECT" "VLAX-ERASED-P"
    "VLAX-FOR" "VLAX-GET-ACAD-OBJECT" "VLAX-IMPORT-TYPE-LIBRARY"
    "VLAX-LDATA-DELETE" "VLAX-LDATA-GET" "VLAX-LDATA-LIST"
    "VLAX-LDATA-PUT" "VLAX-LDATA-TEST" "VLAX-MACHINE-PRODUCT-KEY"
    "VLAX-MAP-COLLECTION" "VLAX-PRODUCT-KEY" "VLAX-QUEUEEXPR"
    "VLAX-READ-ENABLED-P" "VLAX-REMOVE-CMD"
    "VLAX-SAFEARRAY-GET-DIM" "VLAX-SAFEARRAY-VALUE" "VLAX-TMATRIX"
    "VLAX-TYPEINFO-AVAILABLE-P" "VLAX-USER-PRODUCT-KEY"
    "VLAX-VLA-OBJECT->ENAME" "VLAX-WRITE-ENABLED-P"
    ;; VLA-* (2)
    "VLA-COLLECTION->LIST" "VLA-POSTCOMMAND"
    ;; VLR-* (4)
    "VLR-BEEP-REACTION" "VLR-DOCUMENT" "VLR-REACTION-NAME"
    "VLR-REACTION-NAMES"
    ;; DOS_* (22)
    "DOS_ACITORGB" "DOS_COMMAND" "DOS_COPY" "DOS_DELTREE" "DOS_DIR"
    "DOS_DIRP" "DOS_DIRTREE" "DOS_ENCRYPT" "DOS_ENCRYPT_V25"
    "DOS_FILEEX" "DOS_GETDIR" "DOS_GETFILEM" "DOS_GUIDGEN"
    "DOS_HLSTORGB" "DOS_MKDIR" "DOS_POPUPMENU" "DOS_RGBTOACI"
    "DOS_RGBTOHLS" "DOS_STRTOKENS" "DOS_STRTRIM" "DOS_STRTRIMLEFT"
    "DOS_STRTRIMRIGHT"
    ;; LAYERSTATE-* / VL-LAYERSTATES-* (24)
    "LAYERSTATE-ADDLAYERS" "LAYERSTATE-COMPARE" "LAYERSTATE-DELETE"
    "LAYERSTATE-EXPORT" "LAYERSTATE-GETLASTRESTORED"
    "LAYERSTATE-GETLAYERS" "LAYERSTATE-GETNAMES" "LAYERSTATE-HAS"
    "LAYERSTATE-IMPORT" "LAYERSTATE-IMPORTFROMDB"
    "LAYERSTATE-REMOVELAYERS" "LAYERSTATE-RENAME"
    "LAYERSTATE-RESTORE" "LAYERSTATE-SAVE"
    "VL-LAYERSTATES-DELETE" "VL-LAYERSTATES-GETDESCRIPTION"
    "VL-LAYERSTATES-GETPROPERTYMASK" "VL-LAYERSTATES-HAS"
    "VL-LAYERSTATES-LIST" "VL-LAYERSTATES-RENAME"
    "VL-LAYERSTATES-RESTORE" "VL-LAYERSTATES-SAVE"
    "VL-LAYERSTATES-SETDESCRIPTION" "VL-LAYERSTATES-SETPROPERTYMASK"
    ;; ARX* (5)
    "ARX" "ARXLOAD" "ARXUNLOAD" "AUTOARXLOAD" "VL-ARX-IMPORT"
    ;; ACAD* (7)
    "ACAD-POP-DBMOD" "ACAD-PUSH-DBMOD" "ACAD_COLORDLG"
    "ACAD_HELPDLG" "ACAD_STRLSORT" "ACAD_TRUECOLORCLI"
    "ACAD_TRUECOLORDLG"
    ;; Entity / selection-set / table / dictionary database (14)
    "DICTADD" "DICTNEXT" "DICTOBJNAME" "DICTREMOVE" "DICTRENAME"
    "DICTSEARCH" "ENTSEL" "NAMEDOBJDICT" "NENTSEL" "NENTSELP"
    "REGAPP" "SSNAMEX" "XDROOM" "XDSIZE"
    ;; DCL dialogs / tiles (3)
    "GET_ATTR" "INIT_DIALOG" "REDRAW_DIALOG"
    ;; Graphics primitives (GR*) (7)
    "GRARC" "GRCLEAR" "GRDRAW" "GRFILL" "GRREAD" "GRTEXT" "GRVECS"
    ;; Interactive prompts (GET*/INITGET) (5) — ALERT is the real
    ;; impl above and is NOT in this list. GETPROPERTYVALUE landed in
    ;; M2-M5 per the issue text and is excluded here.
    "GETCNAME" "GETFILED" "GET_DISKSERIALID"
    "INITCOMMANDVERSION" "OSNAP")
  "Names registered as nil-returning M6 stubs. See *m6-stub-names*'s
docstring above the def for the upgrade-path reference.")

(defun core-builtins ()
  (append
   (list
   (make-core-builtin-subr "TYPE" #'autolisp-type)
   (make-core-builtin-subr "NULL" #'autolisp-null)
   (make-core-builtin-subr "NOT" #'autolisp-not)
   (make-core-builtin-subr "ATOM" #'autolisp-atom)
   (make-core-builtin-subr "VL-SYMBOLP" #'autolisp-vl-symbolp)
   (make-core-builtin-subr "VL-SYMBOL-NAME" #'autolisp-vl-symbol-name)
   (make-core-builtin-subr "VL-SYMBOL-VALUE" #'autolisp-vl-symbol-value)
   (make-core-builtin-subr "VL-BB-REF" #'builtin-vl-bb-ref)
   (make-core-builtin-subr "VL-BB-SET" #'builtin-vl-bb-set)
   (make-core-builtin-subr "VL-PROPAGATE" #'builtin-vl-propagate)
   (make-core-builtin-subr "VL-DOC-REF" #'builtin-vl-doc-ref)
   (make-core-builtin-subr "VL-DOC-SET" #'builtin-vl-doc-set)
   (make-core-builtin-subr "VL-DOC-EXPORT" #'builtin-vl-doc-export)
   (make-core-builtin-subr "VL-DOC-IMPORT" #'builtin-vl-doc-import)
   (make-core-builtin-subr "MAPCAR" #'builtin-mapcar)
   (make-core-builtin-subr "APPLY" #'builtin-apply)
   (make-core-builtin-subr "EVAL" #'builtin-eval)
   (make-core-builtin-subr "EQ" #'builtin-eq)
   (make-core-builtin-subr "EQUAL" #'builtin-equal)
   (make-core-builtin-subr "ERROR" #'builtin-error)
   ;; Phase 7 — math
   (make-core-builtin-subr "SQRT" #'builtin-sqrt)
   (make-core-builtin-subr "EXP" #'builtin-exp)
   (make-core-builtin-subr "LOG" #'builtin-log)
   (make-core-builtin-subr "LOG10" #'builtin-log10)
   (make-core-builtin-subr "SIN" #'builtin-sin)
   (make-core-builtin-subr "COS" #'builtin-cos)
   (make-core-builtin-subr "TAN" #'builtin-tan)
   (make-core-builtin-subr "SINH" #'builtin-sinh)
   (make-core-builtin-subr "COSH" #'builtin-cosh)
   (make-core-builtin-subr "TANH" #'builtin-tanh)
   (make-core-builtin-subr "ATANH" #'builtin-atanh)
   (make-core-builtin-subr "POWER" #'builtin-power)
   (make-core-builtin-subr "VL-NANP" #'builtin-vl-nanp)
   (make-core-builtin-subr "VL-INFP" #'builtin-vl-infp)
   (make-core-builtin-subr "POSITION" #'builtin-position)
   (make-core-builtin-subr "VL-REMOVE" #'builtin-vl-remove)
   (make-core-builtin-subr "STRING-SPLIT" #'builtin-vl-string-split)
   (make-core-builtin-subr "VL-STRING-SPLIT" #'builtin-vl-string-split)
   (make-core-builtin-subr "ASIN" #'builtin-asin)
   (make-core-builtin-subr "ACOS" #'builtin-acos)
   (make-core-builtin-subr "ATAN" #'builtin-atan)
   (make-core-builtin-subr "EXPT" #'builtin-expt)
   (make-core-builtin-subr "MOD" #'builtin-mod)
   (make-core-builtin-subr "FLOOR" #'builtin-floor)
   (make-core-builtin-subr "CEILING" #'builtin-ceiling)
   (make-core-builtin-subr "ROUND" #'builtin-round)
   (make-core-builtin-subr "RANDOM" #'builtin-random)
   ;; Phase 7 — bitwise
   (make-core-builtin-subr "LOGXOR" #'builtin-logxor)
   (make-core-builtin-subr "BOOLE" #'builtin-boole)
   ;; Phase 7 — list
   (make-core-builtin-subr "VL-LIST-LENGTH" #'builtin-vl-list-length)
   (make-core-builtin-subr "VL-POSITION" #'builtin-vl-position)
   (make-core-builtin-subr "REMOVE" #'builtin-remove)
   (make-core-builtin-subr "VL-SORT" #'builtin-vl-sort)
   (make-core-builtin-subr "VL-SORT-I" #'builtin-vl-sort-i)
   ;; Phase 7 — geometry
   (make-core-builtin-subr "DISTANCE" #'builtin-distance)
   (make-core-builtin-subr "ANGLE" #'builtin-angle)
   (make-core-builtin-subr "POLAR" #'builtin-polar)
   (make-core-builtin-subr "INTERS" #'builtin-inters)
   ;; Phase 7 — string / conversion
   (make-core-builtin-subr "ITOA" #'builtin-itoa)
   (make-core-builtin-subr "RTOS" #'builtin-rtos)
   (make-core-builtin-subr "ANGTOS" #'builtin-angtos)
   (make-core-builtin-subr "DISTOF" #'builtin-distof)
   (make-core-builtin-subr "ANGTOF" #'builtin-angtof)
   (make-core-builtin-subr "SNVALID" #'builtin-snvalid)
   (make-core-builtin-subr "WCMATCH" #'builtin-wcmatch)
   (make-core-builtin-subr "XSTRCASE" #'builtin-xstrcase)
   ;; Phase 7 — predicate / introspection
   (make-core-builtin-subr "ATOMS-FAMILY" #'builtin-atoms-family)
   ;; Phase 7 — help / tracing (headless stubs)
   (make-core-builtin-subr "SETFUNHELP" #'builtin-setfunhelp)
   ;; clautolisp-only: surface the per-binding doc captured by
   ;; eval-defun-form / eval-setq-form from a preceding ;|…|; block
   ;; comment in the source (source-aware-defun-documentation).
   (make-core-builtin-subr "CLAUTOLISP-DOCUMENTATION"
                           #'builtin-clautolisp-documentation)
   (make-core-builtin-subr "CLAUTOLISP-DOCUMENTATION-KIND"
                           #'builtin-clautolisp-documentation-kind)
   (make-core-builtin-subr "VL-BT" #'builtin-vl-bt)
   (make-core-builtin-subr "VL-BT-ON" #'builtin-vl-bt-on)
   (make-core-builtin-subr "VL-BT-OFF" #'builtin-vl-bt-off)
   ;; Phase 10 — entity API (thin wrappers over the HAL)
   (make-core-builtin-subr "ENTGET"   #'builtin-entget)
   (make-core-builtin-subr "ENTMOD"   #'builtin-entmod)
   (make-core-builtin-subr "ENTMAKE"  #'builtin-entmake)
   (make-core-builtin-subr "ENTMAKEX" #'builtin-entmakex)
   (make-core-builtin-subr "ENTDEL"   #'builtin-entdel)
   (make-core-builtin-subr "ENTUPD"   #'builtin-entupd)
   (make-core-builtin-subr "ENTLAST"  #'builtin-entlast)
   (make-core-builtin-subr "ENTNEXT"  #'builtin-entnext)
   (make-core-builtin-subr "HANDENT"  #'builtin-handent)
   ;; Phase 11 — selection sets, table walkers, sysvars
   (make-core-builtin-subr "SSGET"      #'builtin-ssget)
   (make-core-builtin-subr "SSADD"      #'builtin-ssadd)
   (make-core-builtin-subr "SSDEL"      #'builtin-ssdel)
   (make-core-builtin-subr "SSNAME"     #'builtin-ssname)
   (make-core-builtin-subr "SSLENGTH"   #'builtin-sslength)
   (make-core-builtin-subr "SSMEMB"     #'builtin-ssmemb)
   (make-core-builtin-subr "SSGETFIRST" #'builtin-ssgetfirst)
   (make-core-builtin-subr "SSSETFIRST" #'builtin-sssetfirst)
   (make-core-builtin-subr "TBLSEARCH"  #'builtin-tblsearch)
   (make-core-builtin-subr "TBLNEXT"    #'builtin-tblnext)
   (make-core-builtin-subr "TBLOBJNAME" #'builtin-tblobjname)
   (make-core-builtin-subr "GETVAR"     #'builtin-getvar)
   (make-core-builtin-subr "SETVAR"     #'builtin-setvar)
   ;; clautolisp exit-status channel: autolisp-set-status keeps the CAD
   ;; bootstrap name (portable C:MAIN); autolisp-status is the native
   ;; reader. See autolisp-set-status-and-quit-status.issue.
   (make-core-builtin-subr "AUTOLISP-SET-STATUS" #'builtin-autolisp-set-status)
   (make-core-builtin-subr "AUTOLISP-STATUS"     #'builtin-autolisp-status)
   ;; clautolisp extensions (CLAL-*): not documented by Autodesk or
   ;; Bricsys; see autolisp-spec §16 ~clautolisp Extensions~.
   (make-core-builtin-subr "CLAL-SYSVAR-LIST"    #'builtin-clal-sysvar-list)
   (make-core-builtin-subr "CLAL-SYSVAR-APROPOS" #'builtin-clal-sysvar-apropos)
   (make-core-builtin-subr "CLAL-SYSTEM-CODEPAGE"     #'builtin-clal-system-codepage)
   (make-core-builtin-subr "CLAL-DRAWING-CODEPAGE"    #'builtin-clal-drawing-codepage)
   (make-core-builtin-subr "CLAL-CODEPAGE-MISMATCH-P" #'builtin-clal-codepage-mismatch-p)
   (make-core-builtin-subr "CLAL-LOAD-ALDO-CONFIGURATION" #'builtin-clal-load-aldo-configuration)
   (make-core-builtin-subr "CLAL-SAVE-ALDO-CONFIGURATION" #'builtin-clal-save-aldo-configuration)
   (make-core-builtin-subr "CLAL-BREAK"            #'builtin-clal-break)
   (make-core-builtin-subr "CLAL-INVOKE-DEBUGGER"  #'builtin-clal-invoke-debugger)
   (make-core-builtin-subr "CLAL-OPTIMIZATION"     #'builtin-clal-optimization)
   (make-core-builtin-subr "CLAL-OPTIMIZE"         #'builtin-clal-optimize)
   (make-core-builtin-subr "CLAL-COMPILE"          #'builtin-clal-compile)
   (make-core-builtin-subr "CLAL-DEFINE-DEBUGGER-COMMAND" #'builtin-clal-define-debugger-command)
   (make-core-builtin-subr "CLAL-NAV-FUNCTION"     #'builtin-clal-nav-function)
   (make-core-builtin-subr "CLAL-NAV-FILE"         #'builtin-clal-nav-file)
   (make-core-builtin-subr "CLAL-NAV-DIRECTORY"    #'builtin-clal-nav-directory)
   (make-core-builtin-subr "CLAL-SELECT-FILE"      #'builtin-clal-select-file)
   (make-core-builtin-subr "CLAL-SEDIT"                #'builtin-clal-sedit)
   (make-core-builtin-subr "CLAL-CLIPBOARD-PUT-TEXT"   #'builtin-clal-clipboard-put-text)
   (make-core-builtin-subr "CLAL-CLIPBOARD-GET-TEXT"   #'builtin-clal-clipboard-get-text)
   (make-core-builtin-subr "CLAL-CLIPBOARD-COPY-SEXP"  #'builtin-clal-clipboard-copy-sexp)
   (make-core-builtin-subr "CLAL-CLIPBOARD-PASTE-SEXP" #'builtin-clal-clipboard-paste-sexp)
   (make-core-builtin-subr "CLAL-FILE-ENCODING"       #'builtin-clal-file-encoding)
   (make-core-builtin-subr "CLAL-SUPPRESS-ENC-DIAGNOSTIC" #'builtin-clal-suppress-enc-diagnostic)
   (make-core-builtin-subr "CLAL-ENABLE-ENC-DIAGNOSTIC"   #'builtin-clal-enable-enc-diagnostic)
   (make-core-builtin-subr "CLAL-LINT-ENCODING-EXTENSIONS" #'builtin-clal-lint-encoding-extensions)
   (make-core-builtin-subr "CLAL-MODULE-EXTENSION" #'builtin-clal-module-extension)
   ;; Phase 12 — headless interaction channel (PROMPT is registered
   ;; once already as a *standard-output* writer; we keep that)
   (make-core-builtin-subr "INITGET"    #'builtin-initget)
   (make-core-builtin-subr "GETSTRING"  #'builtin-getstring)
   (make-core-builtin-subr "GETINT"     #'builtin-getint)
   (make-core-builtin-subr "GETREAL"    #'builtin-getreal)
   (make-core-builtin-subr "GETPOINT"   #'builtin-getpoint)
   (make-core-builtin-subr "GETCORNER"  #'builtin-getcorner)
   (make-core-builtin-subr "GETDIST"    #'builtin-getdist)
   (make-core-builtin-subr "GETANGLE"   #'builtin-getangle)
   (make-core-builtin-subr "GETORIENT"  #'builtin-getorient)
   (make-core-builtin-subr "GETKWORD"   #'builtin-getkword)
   ;; Phase 13 — COM bridge (vlax-* + safearray + variant)
   (make-core-builtin-subr "VLAX-CREATE-OBJECT"           #'builtin-vlax-create-object)
   (make-core-builtin-subr "VLAX-GET-OBJECT"              #'builtin-vlax-get-object)
   (make-core-builtin-subr "VLAX-GET-OR-CREATE-OBJECT"    #'builtin-vlax-get-or-create-object)
   (make-core-builtin-subr "VLAX-RELEASE-OBJECT"          #'builtin-vlax-release-object)
   (make-core-builtin-subr "VLAX-OBJECT-RELEASED-P"       #'builtin-vlax-object-released-p)
   (make-core-builtin-subr "VLAX-GET-PROPERTY"            #'builtin-vlax-get-property)
   (make-core-builtin-subr "VLAX-PUT-PROPERTY"            #'builtin-vlax-put-property)
   (make-core-builtin-subr "VLAX-INVOKE-METHOD"           #'builtin-vlax-invoke-method)
   (make-core-builtin-subr "VLAX-PROPERTY-AVAILABLE-P"    #'builtin-vlax-property-available-p)
   (make-core-builtin-subr "VLAX-METHOD-APPLICABLE-P"     #'builtin-vlax-method-applicable-p)
   (make-core-builtin-subr "VLAX-MAKE-SAFEARRAY"          #'builtin-vlax-make-safearray)
   (make-core-builtin-subr "VLAX-SAFEARRAY-FILL"          #'builtin-vlax-safearray-fill)
   (make-core-builtin-subr "VLAX-SAFEARRAY-PUT-ELEMENT"   #'builtin-vlax-safearray-put-element)
   (make-core-builtin-subr "VLAX-SAFEARRAY-GET-ELEMENT"   #'builtin-vlax-safearray-get-element)
   (make-core-builtin-subr "VLAX-SAFEARRAY->LIST"         #'builtin-vlax-safearray->list)
   (make-core-builtin-subr "VLAX-SAFEARRAY-TYPE"          #'builtin-vlax-safearray-type)
   (make-core-builtin-subr "VLAX-SAFEARRAY-GET-L-BOUND"   #'builtin-vlax-safearray-get-l-bound)
   (make-core-builtin-subr "VLAX-SAFEARRAY-GET-U-BOUND"   #'builtin-vlax-safearray-get-u-bound)
   (make-core-builtin-subr "VLAX-MAKE-VARIANT"            #'builtin-vlax-make-variant)
   (make-core-builtin-subr "VLAX-VARIANT-TYPE"            #'builtin-vlax-variant-type)
   (make-core-builtin-subr "VLAX-VARIANT-VALUE"           #'builtin-vlax-variant-value)
   (make-core-builtin-subr "VLAX-VARIANT-CHANGE-TYPE"     #'builtin-vlax-variant-change-type)
   ;; Phase 14b — reactor (vlr-*) family
   (make-core-builtin-subr "VLR-ACDB-REACTOR"          #'builtin-vlr-acdb-reactor)
   (make-core-builtin-subr "VLR-COMMAND-REACTOR"       #'builtin-vlr-command-reactor)
   (make-core-builtin-subr "VLR-DEEPCLONE-REACTOR"     #'builtin-vlr-deepclone-reactor)
   (make-core-builtin-subr "VLR-DOCUMENT-REACTOR"      #'builtin-vlr-document-reactor)
   (make-core-builtin-subr "VLR-DWG-REACTOR"           #'builtin-vlr-dwg-reactor)
   (make-core-builtin-subr "VLR-DXF-REACTOR"           #'builtin-vlr-dxf-reactor)
   (make-core-builtin-subr "VLR-INSERT-REACTOR"        #'builtin-vlr-insert-reactor)
   (make-core-builtin-subr "VLR-MOUSE-REACTOR"         #'builtin-vlr-mouse-reactor)
   (make-core-builtin-subr "VLR-OBJECT-REACTOR"        #'builtin-vlr-object-reactor)
   (make-core-builtin-subr "VLR-SYSVAR-REACTOR"        #'builtin-vlr-sysvar-reactor)
   (make-core-builtin-subr "VLR-TOOLBAR-REACTOR"       #'builtin-vlr-toolbar-reactor)
   (make-core-builtin-subr "VLR-UNDO-REACTOR"          #'builtin-vlr-undo-reactor)
   (make-core-builtin-subr "VLR-WBLOCK-REACTOR"        #'builtin-vlr-wblock-reactor)
   (make-core-builtin-subr "VLR-WINDOW-REACTOR"        #'builtin-vlr-window-reactor)
   (make-core-builtin-subr "VLR-XREF-REACTOR"          #'builtin-vlr-xref-reactor)
   (make-core-builtin-subr "VLR-DOCMANAGER-REACTOR"    #'builtin-vlr-docmanager-reactor)
   (make-core-builtin-subr "VLR-EDITOR-REACTOR"        #'builtin-vlr-editor-reactor)
   (make-core-builtin-subr "VLR-LINKER-REACTOR"        #'builtin-vlr-linker-reactor)
   (make-core-builtin-subr "VLR-LISP-REACTOR"          #'builtin-vlr-lisp-reactor)
   (make-core-builtin-subr "VLR-MISCELLANEOUS-REACTOR" #'builtin-vlr-miscellaneous-reactor)
   (make-core-builtin-subr "VLR-ADD"                   #'builtin-vlr-add)
   (make-core-builtin-subr "VLR-REMOVE"                #'builtin-vlr-remove)
   (make-core-builtin-subr "VLR-REMOVE-ALL"            #'builtin-vlr-remove-all)
   (make-core-builtin-subr "VLR-DATA"                  #'builtin-vlr-data)
   (make-core-builtin-subr "VLR-DATA-SET"              #'builtin-vlr-data-set)
   (make-core-builtin-subr "VLR-OWNERS"                #'builtin-vlr-owners)
   (make-core-builtin-subr "VLR-OWNER-ADD"             #'builtin-vlr-owner-add)
   (make-core-builtin-subr "VLR-OWNER-REMOVE"          #'builtin-vlr-owner-remove)
   (make-core-builtin-subr "VLR-SET-NOTIFICATION"      #'builtin-vlr-set-notification)
   (make-core-builtin-subr "VLR-NOTIFICATION"          #'builtin-vlr-notification)
   (make-core-builtin-subr "VLR-CURRENT-REACTION-NAME" #'builtin-vlr-current-reaction-name)
   (make-core-builtin-subr "VLR-REACTIONS"             #'builtin-vlr-reactions)
   (make-core-builtin-subr "VLR-REACTION-SET"          #'builtin-vlr-reaction-set)
   (make-core-builtin-subr "VLR-ADDED-P"               #'builtin-vlr-added-p)
   (make-core-builtin-subr "VLR-TYPE"                  #'builtin-vlr-type)
   (make-core-builtin-subr "VLR-TYPES"                 #'builtin-vlr-types)
   (make-core-builtin-subr "VLR-REACTORS"              #'builtin-vlr-reactors)
   (make-core-builtin-subr "VLR-TRACE-REACTION"        #'builtin-vlr-trace-reaction)
   (make-core-builtin-subr "VLR-PERS"                  #'builtin-vlr-pers)
   (make-core-builtin-subr "VLR-PERS-RELEASE"          #'builtin-vlr-pers-release)
   (make-core-builtin-subr "VLR-PERS-LIST"             #'builtin-vlr-pers-list)
   (make-core-builtin-subr "VLR-PERS-P"                #'builtin-vlr-pers-p)
   (make-core-builtin-subr "VLR-PERS-DICTNAME"         #'builtin-vlr-pers-dictname)
   ;; Phase 15a — DCL (Dialog Control Language) builtins
   (make-core-builtin-subr "LOAD_DIALOG"        #'builtin-load-dialog)
   (make-core-builtin-subr "UNLOAD_DIALOG"      #'builtin-unload-dialog)
   (make-core-builtin-subr "NEW_DIALOG"         #'builtin-new-dialog)
   (make-core-builtin-subr "START_DIALOG"       #'builtin-start-dialog)
   (make-core-builtin-subr "DONE_DIALOG"        #'builtin-done-dialog)
   (make-core-builtin-subr "ACTION_TILE"        #'builtin-action-tile)
   (make-core-builtin-subr "SET_TILE"           #'builtin-set-tile)
   (make-core-builtin-subr "GET_TILE"           #'builtin-get-tile)
   (make-core-builtin-subr "MODE_TILE"          #'builtin-mode-tile)
   (make-core-builtin-subr "CLIENT_DATA_TILE"   #'builtin-client-data-tile)
   (make-core-builtin-subr "DIMX_TILE"          #'builtin-dimx-tile)
   (make-core-builtin-subr "DIMY_TILE"          #'builtin-dimy-tile)
   (make-core-builtin-subr "START_IMAGE"        #'builtin-start-image)
   (make-core-builtin-subr "END_IMAGE"          #'builtin-end-image)
   (make-core-builtin-subr "FILL_IMAGE"         #'builtin-fill-image)
   (make-core-builtin-subr "VECTOR_IMAGE"       #'builtin-vector-image)
   (make-core-builtin-subr "SLIDE_IMAGE"        #'builtin-slide-image)
   (make-core-builtin-subr "START_LIST"         #'builtin-start-list)
   (make-core-builtin-subr "ADD_LIST"           #'builtin-add-list)
   (make-core-builtin-subr "END_LIST"           #'builtin-end-list)
   (make-core-builtin-subr "TERM_DIALOG"        #'builtin-term-dialog)
   (make-core-builtin-subr "VL-EVERY" #'builtin-vl-every)
   (make-core-builtin-subr "VL-MEMBER-IF" #'builtin-vl-member-if)
   (make-core-builtin-subr "VL-MEMBER-IF-NOT" #'builtin-vl-member-if-not)
   (make-core-builtin-subr "VL-REMOVE-IF" #'builtin-vl-remove-if)
   (make-core-builtin-subr "VL-REMOVE-IF-NOT" #'builtin-vl-remove-if-not)
   (make-core-builtin-subr "VL-SOME" #'builtin-vl-some)
   (make-core-builtin-subr "+" #'builtin-+)
   (make-core-builtin-subr "-" #'builtin--)
   (make-core-builtin-subr "*" #'builtin-*)
   (make-core-builtin-subr "/" #'builtin-/)
   (make-core-builtin-subr "1+" #'builtin-1+)
   (make-core-builtin-subr "1-" #'builtin-1-)
   (make-core-builtin-subr "MAX" #'builtin-max)
   (make-core-builtin-subr "MIN" #'builtin-min)
   (make-core-builtin-subr "REM" #'builtin-rem)
   (make-core-builtin-subr "GCD" #'builtin-gcd)
   (make-core-builtin-subr "LCM" #'builtin-lcm)
   (make-core-builtin-subr "~" #'builtin-~)
   (make-core-builtin-subr "LOGAND" #'builtin-logand)
   (make-core-builtin-subr "LOGIOR" #'builtin-logior)
   (make-core-builtin-subr "LSH" #'builtin-lsh)
   (make-core-builtin-subr "STRCAT" #'builtin-strcat)
   (make-core-builtin-subr "STRLEN" #'builtin-strlen)
   (make-core-builtin-subr "SUBSTR" #'builtin-substr)
   (make-core-builtin-subr "STRCASE" #'builtin-strcase)
   (make-core-builtin-subr "VL-STRING-TRIM" #'builtin-vl-string-trim)
   (make-core-builtin-subr "VL-STRING-LEFT-TRIM" #'builtin-vl-string-left-trim)
   (make-core-builtin-subr "VL-STRING-RIGHT-TRIM" #'builtin-vl-string-right-trim)
   (make-core-builtin-subr "VL-STRING-SEARCH" #'builtin-vl-string-search)
   (make-core-builtin-subr "VL-STRING-POSITION" #'builtin-vl-string-position)
   (make-core-builtin-subr "VL-STRING-TRANSLATE" #'builtin-vl-string-translate)
   (make-core-builtin-subr "VL-STRING-SUBST" #'builtin-vl-string-subst)
   (make-core-builtin-subr "VL-STRING-MISMATCH" #'builtin-vl-string-mismatch)
   (make-core-builtin-subr "VL-STRING-ELT" #'builtin-vl-string-elt)
   (make-core-builtin-subr "VL-STRING->LIST" #'builtin-vl-string->list)
   (make-core-builtin-subr "VL-LIST->STRING" #'builtin-vl-list->string)
   (make-core-builtin-subr "ASCII" #'builtin-ascii)
   (make-core-builtin-subr "CHR" #'builtin-chr)
   (make-core-builtin-subr "ATOI" #'builtin-atoi)
   (make-core-builtin-subr "ATOF" #'builtin-atof)
   (make-core-builtin-subr "READ" #'builtin-read)
   (make-core-builtin-subr "LOAD" #'builtin-load)
   (make-core-builtin-subr "AUTOLOAD" #'builtin-autoload)
   (make-core-builtin-subr "OPEN" #'builtin-open)
   (make-core-builtin-subr "CLOSE" #'builtin-close)
   (make-core-builtin-subr "READ-LINE" #'builtin-read-line)
   (make-core-builtin-subr "READ-CHAR" #'builtin-read-char)
   (make-core-builtin-subr "WRITE-LINE" #'builtin-write-line)
   (make-core-builtin-subr "WRITE-CHAR" #'builtin-write-char)
   (make-core-builtin-subr "FINDFILE" #'builtin-findfile)
   (make-core-builtin-subr "FINDTRUSTEDFILE" #'builtin-findtrustedfile)
   (make-core-builtin-subr "VL-DIRECTORY-FILES" #'builtin-vl-directory-files)
   (make-core-builtin-subr "VL-FILE-DIRECTORY-P" #'builtin-vl-file-directory-p)
   (make-core-builtin-subr "VL-FILENAME-BASE" #'builtin-vl-filename-base)
   (make-core-builtin-subr "VL-FILENAME-DIRECTORY" #'builtin-vl-filename-directory)
   (make-core-builtin-subr "VL-FILENAME-EXTENSION" #'builtin-vl-filename-extension)
   (make-core-builtin-subr "VL-FILE-DELETE" #'builtin-vl-file-delete)
   (make-core-builtin-subr "VL-FILE-RENAME" #'builtin-vl-file-rename)
   (make-core-builtin-subr "VL-FILE-SIZE" #'builtin-vl-file-size)
   (make-core-builtin-subr "VL-FILE-SYSTIME" #'builtin-vl-file-systime)
   (make-core-builtin-subr "VL-FILE-COPY" #'builtin-vl-file-copy)
   (make-core-builtin-subr "VL-FILENAME-MKTEMP" #'builtin-vl-filename-mktemp)
   (make-core-builtin-subr "VL-MKDIR" #'builtin-vl-mkdir)
   (make-core-builtin-subr "PRIN1" #'builtin-prin1)
   (make-core-builtin-subr "PRINC" #'builtin-princ)
   (make-core-builtin-subr "PRINT" #'builtin-print)
   (make-core-builtin-subr "TERPRI" #'builtin-terpri)
   (make-core-builtin-subr "PROMPT" #'builtin-prompt)
   (make-core-builtin-subr "EXIT" #'builtin-exit)
   (make-core-builtin-subr "QUIT" #'builtin-quit)
   (make-core-builtin-subr "VL-PRIN1-TO-STRING" #'builtin-vl-prin1-to-string)
   (make-core-builtin-subr "VL-PRINC-TO-STRING" #'builtin-vl-princ-to-string)
   (make-core-builtin-subr "VL-CATCH-ALL-APPLY" #'builtin-vl-catch-all-apply)
   (make-core-builtin-subr "VL-CATCH-ALL-ERROR-P" #'builtin-vl-catch-all-error-p)
   (make-core-builtin-subr "VL-CATCH-ALL-ERROR-MESSAGE"
                           #'builtin-vl-catch-all-error-message)
   (make-core-builtin-subr "VL-CATCH-ALL-ERROR-STACK"
                           #'builtin-vl-catch-all-error-stack)
   (make-core-builtin-subr "VL-EXIT-WITH-ERROR" #'builtin-vl-exit-with-error)
   (make-core-builtin-subr "VL-EXIT-WITH-VALUE" #'builtin-vl-exit-with-value)
   (make-core-builtin-subr "DEFUN-Q-LIST-REF" #'builtin-defun-q-list-ref)
   (make-core-builtin-subr "DEFUN-Q-LIST-SET" #'builtin-defun-q-list-set)
   (make-core-builtin-subr "BOUNDP" #'builtin-boundp)
   (make-core-builtin-subr "CAR" #'builtin-car)
   (make-core-builtin-subr "CDR" #'builtin-cdr)
   (make-core-builtin-subr "CAAR"  #'builtin-caar)
   (make-core-builtin-subr "CADR"  #'builtin-cadr)
   (make-core-builtin-subr "CDAR"  #'builtin-cdar)
   (make-core-builtin-subr "CDDR"  #'builtin-cddr)
   (make-core-builtin-subr "CAAAR" #'builtin-caaar)
   (make-core-builtin-subr "CAADR" #'builtin-caadr)
   (make-core-builtin-subr "CADAR" #'builtin-cadar)
   (make-core-builtin-subr "CADDR" #'builtin-caddr)
   (make-core-builtin-subr "CDAAR" #'builtin-cdaar)
   (make-core-builtin-subr "CDADR" #'builtin-cdadr)
   (make-core-builtin-subr "CDDAR" #'builtin-cddar)
   (make-core-builtin-subr "CDDDR" #'builtin-cdddr)
   (make-core-builtin-subr "CAAAAR" #'builtin-caaaar)
   (make-core-builtin-subr "CAAADR" #'builtin-caaadr)
   (make-core-builtin-subr "CAADAR" #'builtin-caadar)
   (make-core-builtin-subr "CAADDR" #'builtin-caaddr)
   (make-core-builtin-subr "CADAAR" #'builtin-cadaar)
   (make-core-builtin-subr "CADADR" #'builtin-cadadr)
   (make-core-builtin-subr "CADDAR" #'builtin-caddar)
   (make-core-builtin-subr "CADDDR" #'builtin-cadddr)
   (make-core-builtin-subr "CDAAAR" #'builtin-cdaaar)
   (make-core-builtin-subr "CDAADR" #'builtin-cdaadr)
   (make-core-builtin-subr "CDADAR" #'builtin-cdadar)
   (make-core-builtin-subr "CDADDR" #'builtin-cdaddr)
   (make-core-builtin-subr "CDDAAR" #'builtin-cddaar)
   (make-core-builtin-subr "CDDADR" #'builtin-cddadr)
   (make-core-builtin-subr "CDDDAR" #'builtin-cdddar)
   (make-core-builtin-subr "CDDDDR" #'builtin-cddddr)
   (make-core-builtin-subr "CONS" #'builtin-cons)
   (make-core-builtin-subr "LIST" #'builtin-list)
   (make-core-builtin-subr "APPEND" #'builtin-append)
   (make-core-builtin-subr "ASSOC" #'builtin-assoc)
   (make-core-builtin-subr "LENGTH" #'builtin-length)
   (make-core-builtin-subr "NTH" #'builtin-nth)
   (make-core-builtin-subr "REVERSE" #'builtin-reverse)
   (make-core-builtin-subr "LAST" #'builtin-last)
   (make-core-builtin-subr "MEMBER" #'builtin-member)
   (make-core-builtin-subr "SUBST" #'builtin-subst)
   (make-core-builtin-subr "LISTP" #'autolisp-listp)
   (make-core-builtin-subr "VL-CONSP" #'builtin-vl-consp)
   (make-core-builtin-subr "VL-LIST*" #'builtin-vl-list*)
   (make-core-builtin-subr "NUMBERP" #'builtin-numberp)
   (make-core-builtin-subr "=" #'builtin-=)
   (make-core-builtin-subr "/=" #'builtin-/=)
   (make-core-builtin-subr "<" #'builtin-<)
   (make-core-builtin-subr "<=" #'builtin-<=)
   (make-core-builtin-subr ">" #'builtin->)
   (make-core-builtin-subr ">=" #'builtin->=)
   (make-core-builtin-subr "ABS" #'builtin-abs)
   (make-core-builtin-subr "FIX" #'builtin-fix)
   (make-core-builtin-subr "FLOAT" #'builtin-float)
   (make-core-builtin-subr "ZEROP" #'builtin-zerop)
   (make-core-builtin-subr "MINUSP" #'builtin-minusp)
   ;; --- M2 OS / process / filesystem ---
   (make-core-builtin-subr "GETENV"             #'builtin-getenv)
   (make-core-builtin-subr "SETENV"             #'builtin-setenv)
   (make-core-builtin-subr "GETPID"             #'builtin-getpid)
   (make-core-builtin-subr "SLEEP"              #'builtin-sleep)
   (make-core-builtin-subr "GC"                 #'builtin-gc)
   (make-core-builtin-subr "STARTAPP"           #'builtin-startapp)
   (make-core-builtin-subr "VL-GETCURRENTDIR"   #'builtin-vl-getcurrentdir)
   (make-core-builtin-subr "VL-SETCURRENTDIR"   #'builtin-vl-setcurrentdir)
   (make-core-builtin-subr "VL-GETSTARTUPDIR"   #'builtin-vl-getstartupdir)
   (make-core-builtin-subr "VL-RMDIR"           #'builtin-vl-rmdir)
   (make-core-builtin-subr "FNSPLITL"           #'builtin-fnsplitl)
   (make-core-builtin-subr "DOC_CLIPBOARD"      #'builtin-doc-clipboard)
   ;; --- M2 version / inspection ---
   (make-core-builtin-subr "VER"                #'builtin-ver)
   (make-core-builtin-subr "LISP$VERSION"       #'builtin-lisp$version)
   (make-core-builtin-subr "MEM"                #'builtin-mem)
   (make-core-builtin-subr "ALLOC"              #'builtin-alloc)
   (make-core-builtin-subr "HELP"               #'builtin-help)
   ;; --- M2 geometry / math ---
   (make-core-builtin-subr "TRANS"              #'builtin-trans)
   (make-core-builtin-subr "TEXTBOX"            #'builtin-textbox)
   (make-core-builtin-subr "VLE_G_VECTOL"       #'builtin-vle-g-vectol)
   ;; --- M2 CLI no-ops ---
   (make-core-builtin-subr "GRAPHSCR"           #'builtin-graphscr)
   (make-core-builtin-subr "TEXTSCR"            #'builtin-textscr)
   (make-core-builtin-subr "TEXTPAGE"           #'builtin-textpage)
   (make-core-builtin-subr "REDRAW"             #'builtin-redraw)
   (make-core-builtin-subr "SETVIEW"            #'builtin-setview)
   (make-core-builtin-subr "TABLET"             #'builtin-tablet)
   (make-core-builtin-subr "MENUCMD"            #'builtin-menucmd)
   (make-core-builtin-subr "MENUGROUP"          #'builtin-menugroup)
   (make-core-builtin-subr "SHOWHTMLMODALWINDOW"#'builtin-showhtmlmodalwindow)
   ;; --- M2 *error* mode helpers ---
   (make-core-builtin-subr "*PUSH-ERROR-USING-COMMAND*"
                           #'builtin-push-error-using-command)
   (make-core-builtin-subr "*PUSH-ERROR-USING-STACK*"
                           #'builtin-push-error-using-stack)
   (make-core-builtin-subr "*POP-ERROR-MODE*"
                           #'builtin-pop-error-mode)
   ;; --- M3a VLE-* list/predicate/number helpers ---
   (make-core-builtin-subr "VLE-NTH0"          #'builtin-vle-nth0)
   (make-core-builtin-subr "VLE-NTH1"          #'builtin-vle-nth1)
   (make-core-builtin-subr "VLE-NTH2"          #'builtin-vle-nth2)
   (make-core-builtin-subr "VLE-NTH3"          #'builtin-vle-nth3)
   (make-core-builtin-subr "VLE-NTH4"          #'builtin-vle-nth4)
   (make-core-builtin-subr "VLE-NTH5"          #'builtin-vle-nth5)
   (make-core-builtin-subr "VLE-NTH6"          #'builtin-vle-nth6)
   (make-core-builtin-subr "VLE-NTH7"          #'builtin-vle-nth7)
   (make-core-builtin-subr "VLE-NTH8"          #'builtin-vle-nth8)
   (make-core-builtin-subr "VLE-NTH9"          #'builtin-vle-nth9)
   (make-core-builtin-subr "VLE-PUT-NTH"       #'builtin-vle-put-nth)
   (make-core-builtin-subr "VLE-SUBST-NTH"     #'builtin-vle-subst-nth)
   (make-core-builtin-subr "VLE-REMOVE-NTH"    #'builtin-vle-remove-nth)
   (make-core-builtin-subr "VLE-REMOVE-ALL"    #'builtin-vle-remove-all)
   (make-core-builtin-subr "VLE-REMOVE-FIRST"  #'builtin-vle-remove-first)
   (make-core-builtin-subr "VLE-REMOVE-LAST"   #'builtin-vle-remove-last)
   (make-core-builtin-subr "VLE-LIST-SPLIT"    #'builtin-vle-list-split)
   (make-core-builtin-subr "VLE-SUBLIST"       #'builtin-vle-sublist)
   (make-core-builtin-subr "VLE-LIST-DIFF"     #'builtin-vle-list-diff)
   (make-core-builtin-subr "VLE-LIST-INTERSECT" #'builtin-vle-list-intersect)
   (make-core-builtin-subr "VLE-LIST-SUBTRACT" #'builtin-vle-list-subtract)
   (make-core-builtin-subr "VLE-LIST-UNION"    #'builtin-vle-list-union)
   (make-core-builtin-subr "VLE-CDRASSOC"      #'builtin-vle-cdrassoc)
   (make-core-builtin-subr "VLE-CADRASSOC"     #'builtin-vle-cadrassoc)
   (make-core-builtin-subr "VLE-SET-CDRASSOC"  #'builtin-vle-set-cdrassoc)
   (make-core-builtin-subr "VLE-LIST-MASSOC"   #'builtin-vle-list-massoc)
   (make-core-builtin-subr "VLE-APPEND"        #'builtin-vle-append)
   (make-core-builtin-subr "VLE-MEMBER"        #'builtin-vle-member)
   (make-core-builtin-subr "VLE-SEARCH"        #'builtin-vle-search)
   (make-core-builtin-subr "VLE-INTEGERP"      #'builtin-vle-integerp)
   (make-core-builtin-subr "VLE-REALP"         #'builtin-vle-realp)
   (make-core-builtin-subr "VLE-NUMBERP"       #'builtin-vle-numberp)
   (make-core-builtin-subr "VLE-STRINGP"       #'builtin-vle-stringp)
   (make-core-builtin-subr "VLE-POINTP"        #'builtin-vle-pointp)
   (make-core-builtin-subr "VLE-ENAMEP"        #'builtin-vle-enamep)
   (make-core-builtin-subr "VLE-PICKSETP"      #'builtin-vle-picksetp)
   (make-core-builtin-subr "VLE-VARIANTP"      #'builtin-vle-variantp)
   (make-core-builtin-subr "VLE-SAFEARRAYP"    #'builtin-vle-safearrayp)
   (make-core-builtin-subr "VLE-VLAOBJECTP"    #'builtin-vle-vlaobjectp)
   (make-core-builtin-subr "VLE-CEILING"       #'builtin-vle-ceiling)
   (make-core-builtin-subr "VLE-FLOOR"         #'builtin-vle-floor)
   (make-core-builtin-subr "VLE-ROUND"         #'builtin-vle-round)
   (make-core-builtin-subr "VLE-ROUNDTO"       #'builtin-vle-roundto)
   (make-core-builtin-subr "VLE-ATOI32"        #'builtin-vle-atoi32)
   (make-core-builtin-subr "VLE-ITOA32"        #'builtin-vle-itoa32)
   (make-core-builtin-subr "VLE-INT64TO32"     #'builtin-vle-int64to32)
   (make-core-builtin-subr "VLE-TAN"           #'builtin-vle-tan)
   ;; --- M3b VLE-VECTOR-* math ---
   (make-core-builtin-subr "VLE-VECTOR-GET"             #'builtin-vle-vector-get)
   (make-core-builtin-subr "VLE-VECTOR-ADD"             #'builtin-vle-vector-add)
   (make-core-builtin-subr "VLE-VECTOR-SUB"             #'builtin-vle-vector-sub)
   (make-core-builtin-subr "VLE-VECTOR-NEGATE"          #'builtin-vle-vector-negate)
   (make-core-builtin-subr "VLE-VECTOR-SCALE"           #'builtin-vle-vector-scale)
   (make-core-builtin-subr "VLE-VECTOR-MIDPOINT"        #'builtin-vle-vector-midpoint)
   (make-core-builtin-subr "VLE-VECTOR-NORMALISE"       #'builtin-vle-vector-normalise)
   (make-core-builtin-subr "VLE-VECTOR-DOTPRODUCT"      #'builtin-vle-vector-dotproduct)
   (make-core-builtin-subr "VLE-VECTOR-CROSSPRODUCT"    #'builtin-vle-vector-crossproduct)
   (make-core-builtin-subr "VLE-VECTOR-ANGLETO"         #'builtin-vle-vector-angleto)
   (make-core-builtin-subr "VLE-VECTOR-ANGLETOREF"      #'builtin-vle-vector-angletoref)
   (make-core-builtin-subr "VLE-VECTOR-LENGTH"          #'builtin-vle-vector-length)
   (make-core-builtin-subr "VLE-VECTOR-LENGTH2D"        #'builtin-vle-vector-length2d)
   (make-core-builtin-subr "VLE-VECTOR-LENGTH2DXZ"      #'builtin-vle-vector-length2dxz)
   (make-core-builtin-subr "VLE-VECTOR-LENGTH2DYZ"      #'builtin-vle-vector-length2dyz)
   (make-core-builtin-subr "VLE-VECTOR-ISUNITLENGTH"    #'builtin-vle-vector-isunitlength)
   (make-core-builtin-subr "VLE-VECTOR-ISEQUAL"         #'builtin-vle-vector-isequal)
   (make-core-builtin-subr "VLE-VECTOR-ISZEROLENGTH"    #'builtin-vle-vector-iszerolength)
   (make-core-builtin-subr "VLE-VECTOR-ISPARALLEL"      #'builtin-vle-vector-isparallel)
   (make-core-builtin-subr "VLE-VECTOR-ISCODIRECTIONAL" #'builtin-vle-vector-iscodirectional)
   (make-core-builtin-subr "VLE-VECTOR-ISPERPENDICULAR" #'builtin-vle-vector-isperpendicular)
   (make-core-builtin-subr "VLE-VECTOR-ISXAXIS"         #'builtin-vle-vector-isxaxis)
   (make-core-builtin-subr "VLE-VECTOR-ISYAXIS"         #'builtin-vle-vector-isyaxis)
   (make-core-builtin-subr "VLE-VECTOR-ISZAXIS"         #'builtin-vle-vector-iszaxis)
   (make-core-builtin-subr "VLE-VECTOR-GETPERPVECTOR"   #'builtin-vle-vector-getperpvector)
   (make-core-builtin-subr "VLE-VECTOR-GETUCS"          #'builtin-vle-vector-getucs)
   (make-core-builtin-subr "VLE-VECTOR-TO2D"            #'builtin-vle-vector-to2d)
   (make-core-builtin-subr "VLE-VECTOR-TO3D"            #'builtin-vle-vector-to3d)
   (make-core-builtin-subr "VLE-VECTOR-GETTOLERANCE"    #'builtin-vle-vector-gettolerance)
   (make-core-builtin-subr "VLE-VECTOR-SETTOLERANCE"    #'builtin-vle-vector-settolerance)
   ;; --- M3c VLE-* string/file/color/misc ---
   (make-core-builtin-subr "VLE-STRING-REPLACE"  #'builtin-vle-string-replace)
   (make-core-builtin-subr "VLE-STRING-SPLIT"    #'builtin-vle-string-split)
   (make-core-builtin-subr "VLE-FILE->LIST"      #'builtin-vle-file->list)
   (make-core-builtin-subr "VLE-FILEP"           #'builtin-vle-filep)
   (make-core-builtin-subr "VLE-FILE-ENCODING"   #'builtin-vle-file-encoding)
   (make-core-builtin-subr "VLE-ACI2RGB"         #'builtin-vle-aci2rgb)
   (make-core-builtin-subr "VLE-RGB2ACI"         #'builtin-vle-rgb2aci)
   (make-core-builtin-subr "VLE-STARTAPP"        #'builtin-vle-startapp)
   (make-core-builtin-subr "VLE-PING-ALIVE"      #'builtin-vle-ping-alive)
   (make-core-builtin-subr "VLE-OPTIMISER"       #'builtin-vle-optimiser)
   (make-core-builtin-subr "VLE-OPTIMIZER"       #'builtin-vle-optimizer)
   (make-core-builtin-subr "VLE-FASTCOM"         #'builtin-vle-fastcom)
   ;; --- M3d VLE-* CAD / COM / UI stubs ---
   (make-core-builtin-subr "VLE-ALERT"               #'builtin-vle-alert)
   (make-core-builtin-subr "VLE-COLLECTION->LIST"    #'builtin-vle-collection->list)
   (make-core-builtin-subr "VLE-COMPILE-SHAPE"       #'builtin-vle-compile-shape)
   (make-core-builtin-subr "VLE-CURVE-GETPERIMETER"  #'builtin-vle-curve-getperimeter)
   (make-core-builtin-subr "VLE-DICTIONARY-LIST"     #'builtin-vle-dictionary-list)
   (make-core-builtin-subr "VLE-DICTOBJNAME"         #'builtin-vle-dictobjname)
   (make-core-builtin-subr "VLE-DICTSEARCH"          #'builtin-vle-dictsearch)
   (make-core-builtin-subr "VLE-DISPLAYPAUSE"        #'builtin-vle-displaypause)
   (make-core-builtin-subr "VLE-DISPLAYUPDATE"       #'builtin-vle-displayupdate)
   (make-core-builtin-subr "VLE-EDITTEXTINPLACE"     #'builtin-vle-edittextinplace)
   (make-core-builtin-subr "VLE-ENABLESERVERBUSY"    #'builtin-vle-enableserverbusy)
   (make-core-builtin-subr "VLE-ENAME-VALID"         #'builtin-vle-ename-valid)
   (make-core-builtin-subr "VLE-END-TRANSACTION"     #'builtin-vle-end-transaction)
   (make-core-builtin-subr "VLE-ENTGET"              #'builtin-vle-entget)
   (make-core-builtin-subr "VLE-ENTGET-M"            #'builtin-vle-entget-m)
   (make-core-builtin-subr "VLE-ENTGET-MASSOC"       #'builtin-vle-entget-massoc)
   (make-core-builtin-subr "VLE-ENTMOD"              #'builtin-vle-entmod)
   (make-core-builtin-subr "VLE-ENTMOD-M"            #'builtin-vle-entmod-m)
   (make-core-builtin-subr "VLE-EXTENSIONS-ACTIVE"   #'builtin-vle-extensions-active)
   (make-core-builtin-subr "VLE-GETGEOMEXTENTS"      #'builtin-vle-getgeomextents)
   (make-core-builtin-subr "VLE-HIDEPROMPTMENU"      #'builtin-vle-hidepromptmenu)
   (make-core-builtin-subr "VLE-SHOWPROMPTMENU"      #'builtin-vle-showpromptmenu)
   (make-core-builtin-subr "VLE-IS-CURVE"            #'builtin-vle-is-curve)
   (make-core-builtin-subr "VLE-LICENSELEVEL"        #'builtin-vle-licenselevel)
   (make-core-builtin-subr "VLE-LISPINSTALL"         #'builtin-vle-lispinstall)
   (make-core-builtin-subr "VLE-LISPVERSION"         #'builtin-vle-lispversion)
   (make-core-builtin-subr "VLE-NTH<X>"              #'builtin-vle-nth<x>)
   (make-core-builtin-subr "VLE-SAFEARRAY->LIST"     #'builtin-vle-safearray->list)
   (make-core-builtin-subr "VLE-SELECTIONSET->LIST"  #'builtin-vle-selectionset->list)
   (make-core-builtin-subr "VLE-START-TRANSACTION"   #'builtin-vle-start-transaction)
   (make-core-builtin-subr "VLE-SUNID"               #'builtin-vle-sunid)
   (make-core-builtin-subr "VLE-TABLE-LIST"          #'builtin-vle-table-list)
   (make-core-builtin-subr "VLE-TABLE-LIST-ALL"      #'builtin-vle-table-list-all)
   (make-core-builtin-subr "VLE-TBLSEARCH"           #'builtin-vle-tblsearch)
   ;; --- M4 VLISP-* IDE stubs ---
   (make-core-builtin-subr "VLISP-COMPILE"           #'builtin-vlisp-compile)
   (make-core-builtin-subr "VLISP-EXPORT-SYMBOL"     #'builtin-vlisp-export-symbol)
   (make-core-builtin-subr "VLISP-IMPORT-SYMBOL"     #'builtin-vlisp-import-symbol)
   (make-core-builtin-subr "VLISP-IMPORT-EXSUBRS"    #'builtin-vlisp-import-exsubrs)
   (make-core-builtin-subr "VLISP-OPTIMIZER"         #'builtin-vlisp-optimizer)
   ;; --- M5 core/misc rest ---
   ;; native
   (make-core-builtin-subr "VL-INIT"                 #'builtin-vl-init)
   (make-core-builtin-subr "VL-LOAD-COM"             #'builtin-vl-load-com)
   (make-core-builtin-subr "VL-LOAD-REACTORS"        #'builtin-vl-load-reactors)
   (make-core-builtin-subr "VL-LOAD-ALL"             #'builtin-vl-load-all)
   (make-core-builtin-subr "VL-ENABLE-USER-CANCEL"   #'builtin-vl-enable-user-cancel)
   (make-core-builtin-subr "LAYOUTLIST"              #'builtin-layoutlist)
   (make-core-builtin-subr "ACDIMENABLEUPDATE"       #'builtin-acdimenableupdate)
   (make-core-builtin-subr "VPORTS"                  #'builtin-vports)
   ;; session-state (registry + cfg)
   (make-core-builtin-subr "VL-REGISTRY-READ"        #'builtin-vl-registry-read)
   (make-core-builtin-subr "VL-REGISTRY-WRITE"       #'builtin-vl-registry-write)
   (make-core-builtin-subr "VL-REGISTRY-DELETE"      #'builtin-vl-registry-delete)
   (make-core-builtin-subr "VL-REGISTRY-DESCENDENTS" #'builtin-vl-registry-descendents)
   (make-core-builtin-subr "GETCFG"                  #'builtin-getcfg)
   (make-core-builtin-subr "SETCFG"                  #'builtin-setcfg)
   ;; misc stubs
   (make-core-builtin-subr "ADS"                     #'builtin-ads)
   (make-core-builtin-subr "INITDIA"                 #'builtin-initdia)
   (make-core-builtin-subr "INSPECTOR"               #'builtin-inspector)
   (make-core-builtin-subr "DLG-SYSVARS"             #'builtin-dlg-sysvars)
   (make-core-builtin-subr "EXPAND"                  #'builtin-expand)
   (make-core-builtin-subr "LISP$INSTALL"            #'builtin-lisp$install)
   (make-core-builtin-subr "LISP$ENABLEFASTCOM"      #'builtin-lisp$enablefastcom)
   (make-core-builtin-subr "BPOLY"                   #'builtin-bpoly)
   (make-core-builtin-subr "BCAD$DISABLE-EXTENDED-ERROR" #'builtin-bcad$disable-extended-error)
   (make-core-builtin-subr "BCAD$LICENSELEVELS"      #'builtin-bcad$licenselevels)
   (make-core-builtin-subr "VMON"                    #'builtin-vmon)
   (make-core-builtin-subr "_VLAX-SAFEARRAY-MODE"    #'builtin-_vlax-safearray-mode)
   ;; ActiveX property accessors
   (make-core-builtin-subr "LISTALLPROPERTIES"       #'builtin-listallproperties)
   (make-core-builtin-subr "DUMPALLPROPERTIES"       #'builtin-dumpallproperties)
   (make-core-builtin-subr "ISPROPERTYREADONLY"      #'builtin-ispropertyreadonly)
   (make-core-builtin-subr "ISPROPERTYVALID"         #'builtin-ispropertyvalid)
   (make-core-builtin-subr "GETPROPERTYVALUE"        #'builtin-getpropertyvalue)
   (make-core-builtin-subr "SETPROPERTYVALUE"        #'builtin-setpropertyvalue)
   ;; VL-* management stubs
   (make-core-builtin-subr "VL-LIST-LOADED-LISP"     #'builtin-vl-list-loaded-lisp)
   (make-core-builtin-subr "VL-LIST-LOADED-VLX"      #'builtin-vl-list-loaded-vlx)
   (make-core-builtin-subr "VL-VLX-LOADED-P"         #'builtin-vl-vlx-loaded-p)
   (make-core-builtin-subr "VL-UNLOAD-VLX"           #'builtin-vl-unload-vlx)
   (make-core-builtin-subr "VL-LIST-EXPORTED-FUNCTIONS" #'builtin-vl-list-exported-functions)
   (make-core-builtin-subr "VL-VBALOAD"              #'builtin-vl-vbaload)
   (make-core-builtin-subr "VL-VBARUN"               #'builtin-vl-vbarun)
   (make-core-builtin-subr "VL-CMDF"                 #'builtin-vl-cmdf)
   (make-core-builtin-subr "VL-ACAD-DEFUN"           #'builtin-vl-acad-defun)
   (make-core-builtin-subr "VL-ACAD-UNDEFUN"         #'builtin-vl-acad-undefun)
   (make-core-builtin-subr "VL-GET-RESOURCE"         #'builtin-vl-get-resource)
   (make-core-builtin-subr "VL-GETGEOMEXTENTS"       #'builtin-vl-getgeomextents)
   (make-core-builtin-subr "VL-HIDEPROMPTMENU"       #'builtin-vl-hidepromptmenu)
   (make-core-builtin-subr "VL-SHOWPROMPTMENU"       #'builtin-vl-showpromptmenu)
   ;; VL-LOCAL-UNDO-* (5)
   (make-core-builtin-subr "VL-LOCAL-UNDO-CLEAR"     #'builtin-vl-local-undo-clear)
   (make-core-builtin-subr "VL-LOCAL-UNDO-POP"       #'builtin-vl-local-undo-pop)
   (make-core-builtin-subr "VL-LOCAL-UNDO-PUSH"      #'builtin-vl-local-undo-push)
   (make-core-builtin-subr "VL-LOCAL-UNDO-RESET"     #'builtin-vl-local-undo-reset)
   (make-core-builtin-subr "VL-LOCAL-UNDO-STEPS"     #'builtin-vl-local-undo-steps)
   ;; VL-ANNOTATIVE-* (11)
   (make-core-builtin-subr "VL-ANNOTATIVE-ADDSCALE"    #'builtin-vl-annotative-addscale)
   (make-core-builtin-subr "VL-ANNOTATIVE-GET"         #'builtin-vl-annotative-get)
   (make-core-builtin-subr "VL-ANNOTATIVE-GETSCALES"   #'builtin-vl-annotative-getscales)
   (make-core-builtin-subr "VL-ANNOTATIVE-REMOVE"      #'builtin-vl-annotative-remove)
   (make-core-builtin-subr "VL-ANNOTATIVE-REMOVESCALE" #'builtin-vl-annotative-removescale)
   (make-core-builtin-subr "VL-ANNOTATIVE-RESET"       #'builtin-vl-annotative-reset)
   (make-core-builtin-subr "VL-ANNOTATIVE-SCALELIST"   #'builtin-vl-annotative-scalelist)
   (make-core-builtin-subr "VL-ANNOTATIVE-SET"         #'builtin-vl-annotative-set)
   (make-core-builtin-subr "VL-ANNOTATIVE-SETSCALES"   #'builtin-vl-annotative-setscales)
   (make-core-builtin-subr "VL-ANNOTATIVE-SUPPORTED"   #'builtin-vl-annotative-supported)
   ;; VL-SUBENT-* (5)
   (make-core-builtin-subr "VL-SUBENT-ATPOINT"       #'builtin-vl-subent-atpoint)
   (make-core-builtin-subr "VL-SUBENT-SELECT"        #'builtin-vl-subent-select)
   (make-core-builtin-subr "VL-SUBENT-SSADD"         #'builtin-vl-subent-ssadd)
   (make-core-builtin-subr "VL-SUBENT-SSDEL"         #'builtin-vl-subent-ssdel)
   (make-core-builtin-subr "VL-SUBENT-SSMEMB"        #'builtin-vl-subent-ssmemb)
   ;; VL-VPLAYER-* (9)
   (make-core-builtin-subr "VL-VPLAYER-GET-COLOR"        #'builtin-vl-vplayer-get-color)
   (make-core-builtin-subr "VL-VPLAYER-GET-LINETYPE"     #'builtin-vl-vplayer-get-linetype)
   (make-core-builtin-subr "VL-VPLAYER-GET-LINEWEIGHT"   #'builtin-vl-vplayer-get-lineweight)
   (make-core-builtin-subr "VL-VPLAYER-GET-TRANSPARENCY" #'builtin-vl-vplayer-get-transparency)
   (make-core-builtin-subr "VL-VPLAYER-SET-COLOR"        #'builtin-vl-vplayer-set-color)
   (make-core-builtin-subr "VL-VPLAYER-SET-LINETYPE"     #'builtin-vl-vplayer-set-linetype)
   (make-core-builtin-subr "VL-VPLAYER-SET-LINEWEIGHT"   #'builtin-vl-vplayer-set-lineweight)
   (make-core-builtin-subr "VL-VPLAYER-SET-TRANSPARENCY" #'builtin-vl-vplayer-set-transparency)
   (make-core-builtin-subr "VL-VPLAYER-SET-TRUECOLOR"    #'builtin-vl-vplayer-set-truecolor)
   ;; misc geometry-coupled
   (make-core-builtin-subr "VL-VECTOR-PROJECT-POINTTOENTITY"
                           #'builtin-vl-vector-project-pointtoentity)
   ;; --- M6: ALERT real, individual + bulk stubs through APPEND ----
   ;; See the M6 block comment above *m6-stub-names* for the contract
   ;; and the upgrade-path reference. ALERT is the real impl; the
   ;; rest of the M6 inventory is spliced in below via the APPEND
   ;; the defun opens with.
   (make-core-builtin-subr "ALERT" #'builtin-alert))
   (mapcar #'make-m6-stub-subr *m6-stub-names*)))

(defun find-core-builtin (name)
  (find name (core-builtins)
        :key #'autolisp-subr-name
        :test #'string=))

(defun install-core-builtins ()
  (dolist (builtin (core-builtins))
    (let ((symbol (intern-autolisp-symbol (autolisp-subr-name builtin))))
      (set-autolisp-symbol-function symbol builtin)))
  t)
