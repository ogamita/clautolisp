(in-package #:clautolisp.cadtui)

;;;; Structured text dump of the UI-node tree (Phase 1 slice 2).
;;;;
;;;; The dump is the only rendering backend of Phase 1 (cadtui-text). One line
;;;; per node, "ROLE:KEY  LABEL  ATTR=VALUE ..." with hierarchical indentation
;;;; (spec §"Dump : format et pagination"). A paginated list dump is preceded by
;;;; a D<n> header; DUMP-NODE itself (a structural tree dump) emits no header —
;;;; the header/counter machinery here is the seam the Phase-5 entity/list dumps
;;;; and the Phase-2 suite/precedent verbs plug into, so no unpaginated dump is
;;;; ever written over a list that can grow.
;;;;
;;;; The walker touches only the generic node attributes and CHILDREN; per-role
;;;; detail is contributed by NODE-DUMP-ATTRIBUTES (an APPEND generic), never by
;;;; the walker reaching into subclass slots.

;;; --- Per-role dump attributes -------------------------------------

(defgeneric node-dump-attributes (node)
  (:method-combination append)
  (:documentation "An alist of (NAME . VALUE) extra attributes to render after
a node's ROLE:KEY [LABEL] on its dump line. APPEND-combined so each subclass
contributes only its own; the base method contributes the non-normal state."))

(defmethod node-dump-attributes append ((node ui-node))
  ;; The one attribute every node may carry: a non-default display state.
  (unless (eq (ui-state node) :normal)
    (list (cons "state" (ui-state node)))))

(defmethod node-dump-attributes append ((node ui-band))
  (list (cons "style" (ui-band-style node))))

(defmethod node-dump-attributes append ((node ui-drawing))
  (when (ui-filename node)
    (list (cons "file" (ui-filename node)))))

(defmethod node-dump-attributes append ((node ui-entity))
  (append (when (ui-entity-type node) (list (cons "type" (ui-entity-type node))))
          (when (ui-layer node) (list (cons "layer" (ui-layer node))))))

(defmethod node-dump-attributes append ((node ui-tile))
  (when (ui-tile-type node)
    (list (cons "type" (ui-tile-type node)))))

(defmethod node-dump-attributes append ((node ui-alert))
  (when (ui-severity node)
    (list (cons "severity" (ui-severity node)))))

;;; --- Line rendering -----------------------------------------------

(defun %format-dump-value (value)
  "Render an attribute VALUE for the dump: strings verbatim, symbols/keywords
downcased, everything else via PRINC-TO-STRING."
  (typecase value
    (string value)
    (symbol (string-downcase (symbol-name value)))
    (t (princ-to-string value))))

(defun %node-dump-line (node)
  "The single dump line for NODE (no indentation, no newline):
ROLE:KEY, then LABEL when set, then each extra attribute as NAME=VALUE, fields
separated by two spaces."
  (with-output-to-string (s)
    (format s "~A:~A"
            (string-downcase (symbol-name (ui-role node)))
            (ui-key node))
    (when (ui-label node)
      (format s "  ~A" (ui-label node)))
    (dolist (attr (node-dump-attributes node))
      (format s "  ~A=~A" (car attr) (%format-dump-value (cdr attr))))))

;;; --- The tree dump ------------------------------------------------

(defun dump-node (node &key depth (stream *standard-output*) (indent 0)
                            page taille)
  "Write NODE and, unless DEPTH is 0, its descendants to STREAM, one line per
node, indented by nesting. DEPTH NIL is unlimited; DEPTH 0 dumps NODE alone
(spec: profondeur: 0, to inspect one node's state); DEPTH N descends N levels.
PAGE/TAILLE are accepted for signature stability but inert until pagination
(Phase 5) — a structural tree dump like this one is small and unpaginated."
  (declare (ignore page taille))
  (format stream "~A~A~%"
          (make-string (* 2 indent) :initial-element #\Space)
          (%node-dump-line node))
  (when (or (null depth) (> depth 0))
    (let ((child-depth (and depth (1- depth))))
      (dolist (child (ui-children node))
        (dump-node child :depth child-depth :stream stream
                         :indent (1+ indent)))))
  (values))

(defun dump-node-to-string (node &rest args)
  "DUMP-NODE into a string. Convenience for tests and for verbs that capture a
dump for later relative addressing."
  (with-output-to-string (s)
    (apply #'dump-node node :stream s args)))

;;; --- Pagination header seam (inert in Phase 1) --------------------
;;;
;;; A paginated LIST dump (entities, console history, list_box contents) is
;;; preceded by a D<n> header and keeps its D<n> across pages (suite/precedent
;;; operate on the last paginated dump). Phase 1 dumps only small fixed
;;; branches, so this is the seam, exercised in isolation, that Phase 5 fills.

(defvar *dump-counter* 0
  "Monotonic counter for paginated-dump numbers (the D<n> in a dump header).")

(defvar *last-dump* nil
  "The last paginated dump's descriptor, for suite/precedent (Phase 2/5).")

(defun next-dump-number ()
  "Allocate the next D<n> dump number."
  (incf *dump-counter*))

(defun dump-header (relative-path total
                    &key (shown total) (page-size 50) (number (next-dump-number))
                         (stream *standard-output*))
  "Write the paginated-dump header line: D<n> <relative-path> (<shown>/<total>,
<page-size> per page). Returns the dump NUMBER."
  (format stream "D~D ~A (~D/~D, ~D per page)~%"
          number relative-path shown total page-size)
  number)
