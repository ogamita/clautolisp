;;;; Tests for the cadgui multi-document workspace (multidoc.lisp) -- slice 1 of
;;;; the cooperative-scheduler integration. Two documents' getpoint-driven
;;;; evaluations INTERLEAVE through the single-runner scheduler, each reading
;;;; only its own per-document input channel. Deterministic: the test supplies
;;;; the points the Qt canvas will later supply by clicks.

(in-package #:clautolisp.cadgui.tests)

(in-suite cadgui-suite)

(test cadgui-workspace-opens-documents
  (let ((ws (cadgui-make-workspace)))
    (is (null (cadgui-workspace-docs ws)))
    (cadgui-open-document ws :a (lambda (h) (declare (ignore h))))
    (cadgui-open-document ws :b (lambda (h) (declare (ignore h))))
    (is (= 2 (length (cadgui-workspace-docs ws))))
    (cadgui-workspace-shutdown ws)))

(test cadgui-two-documents-interleave-getpoint-via-the-scheduler
  ;; A and B each read two points. They run on their own context threads and
  ;; park through the real cador bridge; the driver serves each park from THAT
  ;; document's channel. The scheduler asserts at-most-one-running internally,
  ;; so completing without error IS the single-runner proof.
  (let* ((ws (cadgui-make-workspace))
         (a '()) (b '())
         (da (cadgui-open-document ws :a
               (lambda (h)
                 (push (host-getpoint h nil) a)
                 (push (host-getpoint h nil) a))))
         (db (cadgui-open-document ws :b
               (lambda (h)
                 (push (host-getpoint h nil) b)
                 (push (host-getpoint h nil) b)))))
    (unwind-protect
         (let ((na (cadgui-workspace-start ws da))   ; A parks at getpoint #1
               (nb (cadgui-workspace-start ws db)))   ; B parks at getpoint #1
           (is (eq :park (first na)))
           (is (eq :park (first nb)))
           ;; interleave A, B, A, B through the single runner
           (cadgui-doc-supply-point da 1 1)
           (setf na (cadgui-workspace-serve ws na))   ; A -> getpoint #2 park
           (cadgui-doc-supply-point db 10 10)
           (setf nb (cadgui-workspace-serve ws nb))   ; B -> getpoint #2 park
           (is (eq :park (first na)))
           (is (eq :park (first nb)))
           (cadgui-doc-supply-point da 2 2)
           (is (eq :timeout (cadgui-workspace-serve ws na 3)))  ; A finishes
           (cadgui-doc-supply-point db 20 20)
           (is (eq :timeout (cadgui-workspace-serve ws nb 3)))  ; B finishes
           ;; each document read ONLY its own points, in order (no cross-bleed)
           (let ((ar (reverse a)) (br (reverse b)))
             (is (= 2 (length ar)))
             (is (= 2 (length br)))
             (is (= 1.0 (first (first ar))))   (is (= 1.0 (second (first ar))))
             (is (= 2.0 (first (second ar))))  (is (= 2.0 (second (second ar))))
             (is (= 10.0 (first (first br))))  (is (= 10.0 (second (first br))))
             (is (= 20.0 (first (second br)))) (is (= 20.0 (second (second br))))))
      (cadgui-workspace-shutdown ws))))
