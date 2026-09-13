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
