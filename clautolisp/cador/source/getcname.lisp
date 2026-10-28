(in-package #:clautolisp.cador)

;;;; GETCNAME (cadtui-locale-probe-getcname).
;;;;
;;;; Measured by the getcname probe on French installs (2026-10-26, MR !494:
;;;; AutoCAD 2022 GUI job 17460836644, AcCoreConsole 17460836645, BricsCAD
;;;; V25 Windows 17460836643):
;;;;
;;;;   - a leading _ asks for the LOCAL name of an international one:
;;;;     "_LINE" / "_line" -> "LIGNE", "_ZOOM" -> "ZOOM"; anything else is
;;;;     taken as a local name: "LIGNE" / "ligne" -> "_LINE";
;;;;   - so an international name without its _ is unknown ("LINE" -> nil on
;;;;     a French install), as is a local one with it ("_LIGNE" -> nil);
;;;;   - the - of a command-line command is part of its name: "_-LAYER" ->
;;;;     "-CALQUE", "-CALQUE" -> "_-LAYER", "-_LAYER" -> nil;
;;;;   - AutoCAD also strips the . and ' prefixes, the _ deciding the way:
;;;;     "_.LINE" -> "LIGNE", ".LIGNE" -> "_LINE", "'ZOOM" / "'_ZOOM" ->
;;;;     "_ZOOM", "_'ZOOM" -> "ZOOM"; BricsCAD answers nil to all of them;
;;;;   - AutoCAD takes a local name with or without its accents ("ETIRER" and
;;;;     "ÉTIRER" -> "_STRETCH"); BricsCAD V25, whose name is ETIRER, does not;
;;;;   - the answer is upper case; a user C: command, "" and "_" give nil;
;;;;   - each product knows its own command set (a French AutoCAD answers nil
;;;;     for _RECTANG, _MTEXT, _PROPERTIES ..., BricsCAD for _BLEND, _XBIND).
;;;;
;;;; The tables (data/getcname/<locale>.sexp, scripts/getcname-to-cador.py)
;;;; hold what each product answered, the commands named the same in both
;;;; languages included. Under a locale with no table (English) a command
;;;; of the product's table is its own local name: "_LINE" -> "LINE",
;;;; "LINE" -> "_LINE". The language is the session's (LANG ...); the
;;;; product the dialect's, AutoCAD's rules for the non-vendor dialects.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun %read-getcname-table (path)
    (with-open-file (in path :external-format :utf-8)
      (with-standard-io-syntax
        (let ((*read-eval* nil) (*package* (find-package :keyword)))
          (read in))))))

(defmacro %embed-getcname-tables (glob)
  "The tables of the files matching GLOB (relative to this source file),
read at compile time: ((LOCALE . ((PRODUCT (INTERNATIONAL . LOCAL) ...) ...)) ...)."
  (let ((here (or *compile-file-truename* *load-truename*)))
    `',(loop for file in (directory (merge-pathnames glob here))
             collect (cons (pathname-name file) (%read-getcname-table file)))))

(defparameter *getcname-tables* (%embed-getcname-tables "../data/getcname/*.sexp")
  "What each product's GETCNAME answers, per locale (see above).")

(defun %getcname-table (product locale)
  "PRODUCT's (INTERNATIONAL . LOCAL) table under LOCALE (\"fr_FR\", or a
language \"fr\"), or NIL when no table matches."
  (let ((tables (and locale
                     (or (cdr (assoc locale *getcname-tables* :test #'string-equal))
                         (let ((language (subseq locale 0 (or (position #\_ locale)
                                                              (length locale)))))
                           (cdr (assoc-if (lambda (name)
                                            (and (> (length name) (length language))
                                                 (string-equal language name
                                                               :end2 (length language))
                                                 (char= #\_ (char name (length language)))))
                                          *getcname-tables*)))))))
    (cdr (assoc product tables))))

(defparameter *getcname-version-overrides*
  ;; ((PRODUCT VERSION LOCALE) (INTERNATIONAL . LOCAL) ...): where a version
  ;; answers otherwise than the version its product's table was measured on
  ;; (V25 Windows). BricsCAD V26 macOS (getcname probe job 17538633594,
  ;; 2026-10-28) spells STRETCH with its accent. Its 3D commands answering nil
  ;; there (BOX, EXTRUDE, LOFT, RENDER, REVOLVE, SECTION, SLICE, SWEEP) look
  ;; like that install's edition, not the version: not encoded.
  '(((:bricscad 26 "fr_FR") ("_STRETCH" . "ÉTIRER"))))

(defun %getcname-overridden (table product version locale)
  "TABLE with the overrides of (PRODUCT VERSION LOCALE) in place."
  (let ((overrides (and version locale
                        (cdr (assoc-if (lambda (key)
                                         (and (eq product (first key))
                                              (eql version (second key))
                                              (string-equal locale (third key))))
                                       *getcname-version-overrides*)))))
    (if overrides
        (append overrides
                (remove-if (lambda (pair) (assoc (car pair) overrides :test #'string=)) table))
        table)))

(defun %getcname-english-table (product)
  "Under a locale with no table: PRODUCT's commands, each its own local name."
  (let ((seen (make-hash-table :test #'equal)))
    (loop for (nil . tables) in *getcname-tables*
          append (loop for (international . nil) in (cdr (assoc product tables))
                       unless (gethash international seen)
                         do (setf (gethash international seen) t)
                         and collect (cons international (subseq international 1))))))

(defun %fold-accents (string)
  (map 'string (lambda (c)
                 (let ((at (position c "ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ")))
                   (if at (char "AAAAAACEEEEIIIINOOOOOUUUUY" at) c)))
       string))

(defun cador-getcname (name product locale &optional version)
  "GETCNAME of the string NAME for PRODUCT (:AUTOCAD / :BRICSCAD) VERSION
(26, or NIL) under LOCALE (\"fr_FR\", or NIL): the other form of the
command name, or NIL."
  (let* ((upper (string-upcase name))
         (international-p (and (plusp (length upper)) (char= #\_ (char upper 0))))
         (core (if (eq product :bricscad)
                   (if international-p (subseq upper 1) upper)
                   (string-left-trim "_.'" upper)))
         (table (or (let ((measured (%getcname-table product locale)))
                      (and measured (%getcname-overridden measured product version locale)))
                    (%getcname-english-table product))))
    (cond
      ((zerop (length core)) nil)
      (international-p
       (cdr (assoc (concatenate 'string "_" core) table :test #'string=)))
      (t
       (car (or (rassoc core table :test #'string=)
                (and (eq product :autocad)
                     (rassoc (%fold-accents core) table
                             :test (lambda (a b) (string= a (%fold-accents b)))))))))))

(defmethod host-getcname ((host cador) name)
  (let ((dialect (ignore-errors (clautolisp.autolisp-runtime:current-evaluation-dialect))))
    (cador-getcname name
                    (if (eq (%current-product) :bricscad) :bricscad :autocad)
                    (%locale-language-territory)
                    (and dialect
                         (ignore-errors (clautolisp.autolisp-reader:autolisp-dialect-version dialect))))))
