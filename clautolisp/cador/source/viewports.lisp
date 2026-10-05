;;;; cador/source/viewports.lisp
;;;;
;;;; Viewports: VPORTS, CVPORT and the -VPORTS command, as measured by
;;;; probes/sources/probe-viewports.lsp (MR !417; AutoCAD 2022 job
;;;; 16937174509, BricsCAD V25 Windows job 16937174513, BricsCAD V26 macOS
;;;; job 16937174510):
;;;;
;;;;   - a drawing starts with ONE tiled viewport, number 2 (CVPORT 2):
;;;;     (vports) => ((2 (0.0 0.0) (1.0 1.0))) on both products -- not the
;;;;     ((1 ...)) of the documentation's example;
;;;;   - -VPORTS 2 Vertical splits the current viewport in two halves and the
;;;;     new one gets the next number; the current viewport keeps the RIGHT
;;;;     half under AutoCAD, the LEFT one under BricsCAD; (vports) lists the
;;;;     current one first;
;;;;   - -VPORTS SIngle leaves one viewport over the whole screen: the
;;;;     highest-numbered under AutoCAD (3 after the split above, and CVPORT
;;;;     follows), the current one under BricsCAD;
;;;;   - TILEMODE 0: CVPORT 1, and (vports) is the sheet, viewport 1, then the
;;;;     layout's floating viewport 2 at (25.7 19.5) (231.3 175.5) on both;
;;;;     viewport 1's corners are the products' own display extents, kept as
;;;;     measured: AutoCAD (0.0 0.0) (15.8893 9.0), BricsCAD (-28.613 -13.59)
;;;;     (285.613 208.59).
;;;; Only those -VPORTS options are implemented: 3 / 4, Horizontal, Save,
;;;; Restore, Join ... were not measured and leave the viewports unchanged.

(in-package #:clautolisp.cador)

(defun %viewport-product ()
  "The product whose measured viewport behaviour applies: :BRICSCAD under a
BricsCAD dialect, :AUTOCAD otherwise (strict / clautolisp follow AutoCAD)."
  (let ((dialect (ignore-errors (clautolisp.autolisp-runtime:current-evaluation-dialect))))
    (if (and dialect (eq :bricscad (clautolisp.autolisp-reader:autolisp-dialect-product dialect)))
        :bricscad
        :autocad)))

(defun cador-model-viewports (host)
  "HOST's current document's tiled viewports, (ID LLX LLY URX URY), the
current one first."
  (or (%cador-model-viewports host)
      (setf (%cador-model-viewports host) (list (list 2 0d0 0d0 1d0 1d0)))))

(defun cador-tilemode (host)
  (let ((cell (ignore-errors (cador-sysvar host "TILEMODE"))))
    (if (and cell (eql 0 (sysvar-cell-value cell))) 0 1)))

(defun cador-current-viewport-id (host)
  "CVPORT: 1 (the sheet) in paper space, else the current tiled viewport."
  (if (zerop (cador-tilemode host))
      1
      (first (first (cador-model-viewports host)))))

(defun %paper-sheet-viewport ()
  (if (eq (%viewport-product) :bricscad)
      (list 1 (list -28.613d0 -13.59d0) (list 285.613d0 208.59d0))
      (list 1 (list 0d0 0d0) (list 15.8893d0 9d0))))

(defmethod host-viewports ((host cador))
  (if (zerop (cador-tilemode host))
      (list (%paper-sheet-viewport)
            (list 2 (list 25.7d0 19.5d0) (list 231.3d0 175.5d0)))
      (mapcar (lambda (v)
                (destructuring-bind (id llx lly urx ury) v
                  (list id (list llx lly) (list urx ury))))
              (cador-model-viewports host))))

(defun %vports-split-vertical (host)
  (destructuring-bind ((id llx lly urx ury) &rest others) (cador-model-viewports host)
    (let* ((mid (/ (+ llx urx) 2d0))
           (new (1+ (reduce #'max (cons id (mapcar #'first others)))))
           (left (list llx lly mid ury))
           (right (list mid lly urx ury)))
      (setf (%cador-model-viewports host)
            (if (eq (%viewport-product) :bricscad)
                (list* (cons id left) (cons new right) others)
                (list* (cons id right) (cons new left) others))))))

(defun %vports-single (host)
  (let* ((viewports (cador-model-viewports host))
         (id (if (eq (%viewport-product) :bricscad)
                 (first (first viewports))
                 (reduce #'max (mapcar #'first viewports)))))
    (setf (%cador-model-viewports host) (list (list id 0d0 0d0 1d0 1d0)))))

;;; -VPORTS: "2" then "V" (Vertical), or "SI" (SIngle). Model space only.
(defun %cmd-vports (host tokens)
  (let ((option (pop tokens)))
    (when (= 1 (cador-tilemode host))
      (cond ((or (eql option 2) (%command-option-p option "2"))
             (let ((orientation (first tokens)))
               (when (%command-option-p orientation "V" "VERTICAL")
                 (pop tokens)
                 (%vports-split-vertical host))))
            ((%command-option-p option "SI" "SINGLE")
             (%vports-single host)))))
  tokens)

(define-cador-command "-VPORTS" '%cmd-vports)
