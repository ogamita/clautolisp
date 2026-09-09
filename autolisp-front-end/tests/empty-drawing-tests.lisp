;;;; autolisp-front-end/tests/empty-drawing-tests.lisp
;;;;
;;;; The empty drawing alfe hands a CAD (issues/closed/empty-ressource.issue).
;;;;
;;;; What matters about it is not that it exists but that every
;;;; invocation gets its OWN: sharing one file across runs is what
;;;; produced the modal "in use by another instance" / "open read-only?"
;;;; dialogs that hang a batch launch. So the tests are mostly about
;;;; SEPARATENESS and about the resource surviving into the image.

(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

(defun %temp-dir (tag)
  (let ((path (merge-pathnames (format nil "alfe-dwg-test-~A-~D/" tag (random 100000))
                               (uiop:temporary-directory))))
    (ensure-directories-exist path)
    path))

(test the-empty-drawing-is-carried-in-the-image
  "The bytes are read at COMPILE time and live in the image, so alfe
needs nothing beside it on disk. A zero-length resource would mean the
compile-time read silently produced nothing, which is the failure this
checks for -- everything downstream would still `work' and hand the CAD
an empty file."
  (is (plusp (alfe.drawing:empty-dwg-size)))
  (is (= (alfe.drawing:empty-dwg-size) (length alfe.drawing:*empty-dwg-contents*)))
  ;; a DWG announces its format in the first six bytes; AC1032 is
  ;; AutoCAD 2018, which both AutoCAD 2026 and BricsCAD V26 open.
  (is (string= "AC1032"
               (map 'string #'code-char (subseq alfe.drawing:*empty-dwg-contents* 0 6)))))

(test each-invocation-gets-its-own-drawing
  "The point of the whole exercise. Two runs must not be handed the same
file: one CAD holding the lock is what makes the next one show a modal."
  (let* ((a (alfe.drawing:fresh-empty-dwg (%temp-dir "a")))
         (b (alfe.drawing:fresh-empty-dwg (%temp-dir "b"))))
    (is (not (null a)))
    (is (not (null b)))
    (is (not (equal (namestring a) (namestring b))))
    (is (probe-file a))
    (is (probe-file b))))

(test a-fresh-drawing-is-a-faithful-copy
  "It has to be the SAME drawing every time, or a run's behaviour would
depend on which copy it got."
  (let ((path (alfe.drawing:fresh-empty-dwg (%temp-dir "copy"))))
    (with-open-file (in path :element-type '(unsigned-byte 8))
      (let ((bytes (make-array (file-length in) :element-type '(unsigned-byte 8))))
        (read-sequence bytes in)
        (is (equalp bytes alfe.drawing:*empty-dwg-contents*))))))

(test a-fresh-drawing-replaces-whatever-was-there
  "A workdir is fresh per run, but the name inside it is fixed, so
writing must not depend on the file being absent -- and must not append
to a partial file left by a crash."
  (let* ((dir (%temp-dir "clobber"))
         (path (merge-pathnames "empty.dwg" dir)))
    (with-open-file (out path :direction :output :if-exists :supersede)
      (write-string "not a drawing" out))
    (alfe.drawing:fresh-empty-dwg dir)
    (with-open-file (in path :element-type '(unsigned-byte 8))
      (is (= (file-length in) (alfe.drawing:empty-dwg-size))))))

(test an-unwritable-directory-declines-rather-than-fails-the-run
  "FRESH-EMPTY-DWG is a courtesy: a backend that cannot get a drawing
here still has its template discovery to fall back on, so this must
return NIL rather than signal and take the run down with it."
  (handler-bind ((warning #'muffle-warning))
    (is (null (alfe.drawing:fresh-empty-dwg "/proc/definitely/not/writable/")))))
