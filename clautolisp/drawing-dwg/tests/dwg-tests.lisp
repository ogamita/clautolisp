(in-package #:clautolisp.drawing.dwg.tests)

(in-suite drawing-dwg-suite)

(defun sample-dwg (name)
  "A DWG fixture from the vendored libredwg test corpus."
  (asdf:system-relative-pathname
   :clautolisp/drawing-dwg
   (format nil "third-party/libredwg/test/test-data/~A" name)))

;;; --- Read real DWGs via libredwg ---------------------------------

(test dwg-reads-real-sample-2000
  (let ((d (clautolisp.drawing:read-drawing (sample-dwg "example_2000.dwg"))))
    (is (eq :dwg (clautolisp.drawing:drawing-format d)))
    (is (plusp (clautolisp.drawing:drawing-entity-count d)))
    (is (plusp (hash-table-count (clautolisp.drawing:drawing-blocks d))))
    (let ((layers 0))
      (clautolisp.drawing:map-table-records
       (lambda (r) (declare (ignore r)) (incf layers)) d :layer)
      (is (plusp layers)))))

(test dwg-reads-multiple-versions
  (dolist (f '("example_r14.dwg" "example_2010.dwg" "example_2018.dwg"))
    (let ((d (clautolisp.drawing:read-drawing (sample-dwg f))))
      (is (plusp (clautolisp.drawing:drawing-entity-count d))
          "~A should yield entities" f))))

;;; --- Write a DWG, then read it back ------------------------------
;;;
;;; The write path goes drawing -> DXF -> libredwg -> DWG. libredwg's
;;; DXF reader needs a reasonably complete document, so we exercise the
;;; round trip with a drawing that already carries full structure (read
;;; from a real DWG). Exact write fidelity (entity counts, handle
;;; preservation) is not yet guaranteed — the read path is the Phase-17e
;;; priority — so we assert the round trip *completes* and yields a
;;; non-empty drawing, not an exact match.

(test dwg-write-then-read-round-trips
  (uiop:with-temporary-file (:pathname p :type "dwg")
    (let ((original (clautolisp.drawing:read-drawing (sample-dwg "example_2000.dwg"))))
      (clautolisp.drawing:write-drawing original p :format :dwg)
      (is (probe-file p))
      (let ((restored (clautolisp.drawing:read-drawing p)))
        (is (eq :dwg (clautolisp.drawing:drawing-format restored)))
        (is (plusp (clautolisp.drawing:drawing-entity-count restored)))))))
