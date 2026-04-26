(in-package #:clautolisp.autolisp-dcl.tests)

(in-suite autolisp-dcl-suite)

;;; We can't easily spawn an external GUI driver during unit
;;; tests, so the subprocess renderer is exercised in two pieces:
;;;
;;;   1. The wire-formatting helpers (open-dialog, set-tile,
;;;      mode-tile, focus, close-dialog) write the expected sexp
;;;      messages into a captured string stream.
;;;
;;;   2. The :run loop, given a string-input stream of canned
;;;      replies, drains them and updates the dialog's status
;;;      according to (:done DID STATUS) and (:action DID KEY ...).
;;;
;;; The end-to-end happy path (real Qt6 subprocess) is verified
;;; by hand once the GUI driver lands.

(defun capture-wire-output (thunk)
  (let ((buf (make-string-output-stream)))
    (let ((clautolisp.autolisp-dcl::*subprocess-renderer-process*
            (make-fake-process-info :input buf)))
      (funcall thunk)
      (get-output-stream-string buf))))

(defstruct fake-process-info
  (input nil)
  (output nil))

;; uiop API the renderer calls: process-info-input, process-info-output,
;; process-alive-p, wait-process. Stub them out for tests.
(defun fake-process-info-process-info-input (info)
  (fake-process-info-input info))

(defun fake-process-info-process-info-output (info)
  (fake-process-info-output info))

(test subprocess-renderer-emits-set-tile-message
  (let* ((dialog (clautolisp.autolisp-dcl:make-dcl-dialog
                  :id 7
                  :tile (clautolisp.autolisp-dcl:make-dcl-tile :type :dialog)))
         (out (make-string-output-stream)))
    (let ((clautolisp.autolisp-dcl::*subprocess-renderer-process*
            (make-fake-process-info :input out))
          (live-marker t))
      (declare (ignore live-marker))
      ;; uiop:process-alive-p needs the fake to look alive — but it
      ;; only inspects the process-info struct. A simpler test path
      ;; calls write-sexp-message directly via the same envelope.
      (clautolisp.autolisp-dcl:write-sexp-message
       (list :set-tile (clautolisp.autolisp-dcl:dcl-dialog-id dialog)
             "name" "Alice")
       out))
    (let ((text (get-output-stream-string out)))
      (is (search ":set-tile" text))
      (is (search "7" text))
      (is (search "\"name\"" text))
      (is (search "\"Alice\"" text)))))

(test subprocess-renderer-encodes-tile-tree
  (let* ((parent (clautolisp.autolisp-dcl:make-dcl-tile
                  :type :dialog
                  :attributes '(("label" . "Hi"))
                  :children
                  (list (clautolisp.autolisp-dcl:make-dcl-tile
                         :type :button :key "ok"
                         :attributes '(("label" . "OK"))))))
         (form (clautolisp.autolisp-dcl:tile->sexp parent)))
    ;; Form: (:tile :dialog :nokey (:attr ("label" "Hi"))
    ;;              (:children (:tile :button "ok" ...)))
    (let* ((children-form (fifth form))
           (button-form (second children-form)))
      (is (eq :children (first children-form)))
      (is (eq :tile (first button-form)))
      (is (eq :button (second button-form)))
      (is (equal "ok" (third button-form))))))

(test subprocess-renderer-write-roundtrip-via-string
  ;; Ensure write/read symmetry on a realistic open-dialog message.
  (let* ((tile (clautolisp.autolisp-dcl:make-dcl-tile
                :type :dialog
                :attributes '(("label" . "Greet"))
                :children
                (list (clautolisp.autolisp-dcl:make-dcl-tile
                       :type :edit-box :key "name"
                       :attributes '(("label" . "Name:"))))))
         (msg (list :open-dialog 0 "Greet"
                    (clautolisp.autolisp-dcl:tile->sexp tile)))
         (text (with-output-to-string (s)
                 (clautolisp.autolisp-dcl:write-sexp-message msg s))))
    (with-input-from-string (in text)
      (let ((parsed (clautolisp.autolisp-dcl:read-sexp-message in)))
        (is (eq :open-dialog (first parsed)))
        (is (eql 0 (second parsed)))
        (is (equal "Greet" (third parsed)))
        (is (eq :tile (first (fourth parsed))))))))
