(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;;; Document management (HAL D1 Group 1) — cador-2 slice 1.
;;;; The host holds a set of open documents, each with its own drawing;
;;;; ACTIVE-DRAWING points at the current one. Single-document behaviour is
;;;; unchanged (a fresh cador has exactly one, always current).

(test cador-starts-with-one-current-document
  (let ((host (make-cador)))
    (is (= 1 (length (host-document-list host))))
    (is (stringp (host-current-document host)))
    (is (member (host-current-document host) (host-document-list host)
                :test #'string=))
    ;; the current document's drawing IS the active drawing
    (is (eq (cador-active-drawing host)
            (cdr (assoc (host-current-document host) (cador-documents host)
                        :test #'string=))))))

(test host-open-document-adds-without-switching
  (let* ((host (make-cador))
         (first-key (host-current-document host))
         (k (host-open-document host "Second.dwg")))
    (is (= 2 (length (host-document-list host))))
    (is (member k (host-document-list host) :test #'string=))
    ;; opening does NOT change the current document
    (is (string= first-key (host-current-document host)))))

(test host-open-document-uniquifies-colliding-names
  ;; the initial document is "Drawing.dwg"; opening another by the same name
  ;; must get a distinct key.
  (let* ((host (make-cador))
         (k2 (host-open-document host "Drawing.dwg")))
    (is (not (string= "Drawing.dwg" k2)))
    (is (= 2 (length (remove-duplicates (host-document-list host)
                                        :test #'string=))))))

(test host-activate-document-switches-the-active-drawing
  (let* ((host (make-cador))
         (k (host-open-document host "Other.dwg")))
    (host-activate-document host k)
    (is (string= k (host-current-document host)))
    (is (eq (cador-active-drawing host)
            (cdr (assoc k (cador-documents host) :test #'string=))))))

(test host-activate-unknown-document-signals
  (let ((host (make-cador))
        (code nil))
    (handler-case (host-activate-document host "no-such-key")
      (autolisp-runtime-error (e) (setf code (autolisp-runtime-error-code e))))
    (is (eq :no-such-document code))))

(test documents-have-isolated-entity-databases
  ;; The core isolation guarantee (C5): an entity made in document A is not
  ;; visible in document B, and switching back finds it again.
  (let* ((host (make-cador))
         (doc-a (host-current-document host))
         (doc-b (host-open-document host "B.dwg")))
    (host-entmake host (make-line-data))
    (is (not (null (host-entlast host))))       ; A has the entity
    (host-activate-document host doc-b)
    (is (null (host-entlast host)))             ; B is empty
    (host-activate-document host doc-a)
    (is (not (null (host-entlast host))))       ; A still has it
    ;; and the two documents own distinct drawing objects
    (is (not (eq (cdr (assoc doc-a (cador-documents host) :test #'string=))
                 (cdr (assoc doc-b (cador-documents host) :test #'string=)))))))

(test host-close-document-removes-and-reactivates
  (let* ((host (make-cador))
         (a (host-current-document host))
         (b (host-open-document host "B.dwg")))
    (host-activate-document host b)
    (is (eq t (host-close-document host b)))
    (is (= 1 (length (host-document-list host))))
    ;; closing the current document reactivated the remaining one
    (is (string= a (host-current-document host)))
    ;; an unknown key closes nothing
    (is (null (host-close-document host "ghost")))))

(test host-close-last-document-is-refused
  (let ((host (make-cador))
        (code nil))
    (handler-case (host-close-document host (host-current-document host))
      (autolisp-runtime-error (e) (setf code (autolisp-runtime-error-code e))))
    (is (eq :cannot-close-last-document code))
    (is (= 1 (length (host-document-list host))))))

;;; --- Runtime<->host document lock-step (cador-2 slice 2b) ----------

(test runtime-current-document-switch-drives-cador-active-drawing
  ;; The host layer installs *document-activation-hook* at load; a runtime
  ;; document namespace linked (host-document-key) to a cador document, in a
  ;; session whose host is that cador, makes cador's active drawing follow the
  ;; runtime current document in lock-step.
  (let* ((host (make-cador))
         (key-a (host-current-document host))          ; the initial cador doc
         (key-b (host-open-document host "B.dwg"))
         (drawing-a (cdr (assoc key-a (cador-documents host) :test #'string=)))
         (drawing-b (cdr (assoc key-b (cador-documents host) :test #'string=)))
         (session (make-runtime-session))
         (ns-a (make-document-namespace :name "A"))
         (ns-b (make-document-namespace :name "B")))
    (set-runtime-session-host session host)
    (setf (document-namespace-host-document-key ns-a) key-a
          (document-namespace-host-document-key ns-b) key-b)
    ;; switch runtime current document to B -> cador activates B
    (set-runtime-session-current-document session ns-b)
    (is (string= key-b (host-current-document host)))
    (is (eq drawing-b (cador-active-drawing host)))
    ;; switch to A -> cador activates A
    (set-runtime-session-current-document session ns-a)
    (is (string= key-a (host-current-document host)))
    (is (eq drawing-a (cador-active-drawing host)))))

;;; --- Sysvars are per-document (cador-2 slice 3c) ------------------

(test cador-sysvars-are-per-document
  ;; Sysvars live on the ACTIVE document's drawing header variables, so each
  ;; document carries its own — a direct consequence of the document->drawing
  ;; registry (slice 1a). A value set in document A does not leak to document B
  ;; and survives a round-trip through B. (OSMODE is in the default sysvar set;
  ;; CMDECHO likewise rides the active drawing, absent-means-on.)
  (let* ((host (make-cador))
         (key-a (host-current-document host))
         (key-b (host-open-document host "B.dwg")))
    (host-setvar host "OSMODE" 5)                     ; A's OSMODE := 5
    (is (eql 5 (host-getvar host "OSMODE")))
    (host-activate-document host key-b)               ; B active (its own drawing)
    (is (not (eql 5 (ignore-errors (host-getvar host "OSMODE")))))  ; A's 5 not in B
    (host-activate-document host key-a)               ; back to A
    (is (eql 5 (host-getvar host "OSMODE")))))        ; A still 5

;;; --- the template a NEW document is created from -------------------
;;;
;;; pjb, 2026-09-26: "il doit y avoir une sysvar pour specifier un template
;;; non?" -- and that is the right shape. dwg-round-trip-loses-entities was
;;; BLOCKED on a model decision: wiring cador to the bundled template makes a
;;; DWG saved from a fresh session keep its entities, but it also makes a NEW
;;; DOCUMENT NON-EMPTY, which 22 cador tests assert. A sysvar dissolves the
;;; dilemma: empty stays the default, and a session that wants the structure
;;; asks for it.

(test new-document-is-empty-when-no-template-is-set
  "The DEFAULT is unchanged: CLAUTOLISPNEWDRAWINGTEMPLATE is empty, so a new
document is the empty shell every other cador test assumes. This test exists to
make that assumption explicit rather than incidental -- if the default ever
changes, this fails first and names why 22 other tests are about to."
  (let ((host (make-cador)))
    (let ((cell (cador-sysvar host "CLAUTOLISPNEWDRAWINGTEMPLATE")))
      (is (typep cell 'sysvar-cell))
      (is (string= "" (sysvar-cell-value cell))))
    (is (null (clautolisp.cador:cador-new-drawing-template host)))
    (let ((drawing (clautolisp.cador:cador-make-new-drawing host)))
      (is (zerop (clautolisp.drawing:drawing-entity-count drawing)))
      ;; the empty shell carries no block definitions; the template does
      (is (zerop (hash-table-count (clautolisp.drawing:drawing-blocks drawing)))))))

(test new-document-uses-the-template-the-sysvar-names
  "With the sysvar pointing at the bundled template, a new document carries a
real drawing's structure -- which is what libredwg needs to keep entities
through a DWG round trip."
  (let ((host (make-cador))
        (template (clautolisp.drawing:drawing-template-path)))
    (if (not (and template (probe-file template)))
        ;; A checkout without the template installed: say so rather than
        ;; passing vacuously.
        (is (null template) "no bundled template to point the sysvar at")
        (progn
          (cador-set-sysvar host "CLAUTOLISPNEWDRAWINGTEMPLATE"
                            (namestring template))
          (is (equal (namestring template)
                     (namestring (clautolisp.cador:cador-new-drawing-template host))))
          (let ((drawing (clautolisp.cador:cador-make-new-drawing
                          host :name "Fresh.dwg")))
            (is (equal "Fresh.dwg" (clautolisp.drawing:drawing-name drawing)))
            (is (plusp (hash-table-count (clautolisp.drawing:drawing-blocks drawing)))
                "the template's block definitions (*Model_Space etc.) must be there")
            ;; and the template's own name/path did not leak into the new drawing
            (is (null (clautolisp.drawing:drawing-path drawing))))))))

(test new-document-template-that-cannot-be-read-warns-and-stays-empty
  "An unreadable value is reported on *error-output* and the document is still
created, empty. Neither an error (a typo in a sysvar must not end the session)
nor silence (the drawing would not be what was asked for, with no explanation)."
  (let* ((host (make-cador))
         (missing "/nonexistent/template-xyz.dwt")
         (drawing nil)
         (text (with-output-to-string (err)
                 (let ((*error-output* err))
                   (cador-set-sysvar host "CLAUTOLISPNEWDRAWINGTEMPLATE" missing)
                   (setf drawing (clautolisp.cador:cador-make-new-drawing host))))))
    (is (search "CLAUTOLISPNEWDRAWINGTEMPLATE" text))
    (is (search "cannot be read" text))
    (is (zerop (clautolisp.drawing:drawing-entity-count drawing)))))

(test new-document-template-resolves-a-relative-name-against-templatepath
  "A relative CLAUTOLISPNEWDRAWINGTEMPLATE is resolved against BricsCAD's
TEMPLATEPATH (the Templates folder), so a script can name just the file the way
it would in BricsCAD."
  (let ((host (make-cador))
        (template (clautolisp.drawing:drawing-template-path)))
    (if (not (and template (probe-file template)))
        (is (null template) "no bundled template to point the sysvar at")
        (progn
          (cador-set-sysvar host "TEMPLATEPATH"
                            (namestring (uiop:pathname-directory-pathname template)))
          (cador-set-sysvar host "CLAUTOLISPNEWDRAWINGTEMPLATE"
                            (file-namestring template))
          (is (equal (namestring (truename template))
                     (namestring (truename (clautolisp.cador:cador-new-drawing-template
                                            host)))))))))

(test startup-document-follows-the-environment-not-the-sysvar
  "The STARTUP document is built in an :initform, before any sysvar table
exists, so the ENVIRONMENT variable is its knob -- which is why
$CLAUTOLISPNEWDRAWINGTEMPLATE exists beside the sysvar rather than instead of
it. Measured through %STARTUP-DRAWING's template argument, so no environment
variable has to be set in-process."
  (let ((template (clautolisp.drawing:drawing-template-path)))
    ;; unset: the empty shell clautolisp has always started with
    (let ((drawing (clautolisp.cador::%startup-drawing nil)))
      (is (zerop (clautolisp.drawing:drawing-entity-count drawing)))
      (is (zerop (hash-table-count (clautolisp.drawing:drawing-blocks drawing)))))
    (if (not (and template (probe-file template)))
        (is (null template) "no bundled template to start from")
        (let ((drawing (clautolisp.cador::%startup-drawing template)))
          (is (equal "Drawing.dwg" (clautolisp.drawing:drawing-name drawing)))
          (is (plusp (hash-table-count (clautolisp.drawing:drawing-blocks drawing)))
              "with the template, the startup document carries its structure")))))
