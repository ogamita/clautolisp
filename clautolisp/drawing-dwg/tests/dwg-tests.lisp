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

;;; --- finding the native libraries of an installed release -----------
;;;
;;; clautolisp-distributed-native-libraries-not-loaded: a complete
;;; installation carried the native DWG libraries and still answered "no
;;; writer codec registered for format :DWG", because the standalone
;;; program did not contain the code that REGISTERS the codec, and
;;; because the only installed search candidate was derived from the
;;; installed ASDF SOURCES -- which a programs+libraries release does not
;;; ship. The prefix is knowable at run time from the running program,
;;; and that is now the candidate that matters.

(test dwg-tool-program-depends-on-the-codec
  "The shipped standalone must CONTAIN the DWG codec: nothing below
clautolisp-tool depends on clautolisp/drawing-dwg, so the program that
assembles the image has to, exactly as it does for the compiler. Without
the dependency a release ships the drawing core with no :DWG codec
registered, whatever native libraries sit beside it."
  (let ((deps (asdf:system-depends-on
               (asdf:find-system "clautolisp/clautolisp-tool"))))
    (is (member "clautolisp/drawing-dwg" deps :test #'equal)
        "clautolisp-tool must depend on clautolisp/drawing-dwg; deps: ~S"
        deps)))

(test dwg-running-program-prefix-candidates-knows-both-layouts
  "RUNNING-PROGRAM-PREFIX-CANDIDATES derives the installation prefix from
the program's own pathname, for the two layouts a release uses: the
bin/ one and anywhere below libexec/ (where the per-platform binaries
live and the bin/ trampoline does not pass the prefix on). The deepest
libexec wins, so a prefix that itself contains a libexec resolves."
  (flet ((cands (path)
           (mapcar #'namestring
                   (clautolisp.drawing.dwg::running-program-prefix-candidates
                    (pathname path)))))
    (is (equal '("/opt/local/") (cands "/opt/local/bin/clautolisp-sbcl")))
    (is (equal '("/opt/local/")
               (cands "/opt/local/libexec/clautolisp/binaries/linux/x86-64/clautolisp-sbcl")))
    ;; A prefix that contains a libexec component of its own.
    (is (equal '("/opt/libexec/x/")
               (cands "/opt/libexec/x/libexec/clautolisp/binaries/linux/x86-64/clautolisp-sbcl")))
    ;; Neither layout: no prefix claimed, rather than a wrong one.
    (is (null (cands "/tmp/clautolisp-sbcl")))
    (is (null (clautolisp.drawing.dwg::running-program-prefix-candidates nil)))))

(test dwg-native-library-directories-order-and-override
  "The search order is: CLAUTOLISP_DWG_LIBDIR, the development tree, the
prefixes of the RUNNING program (lib/clautolisp/<os>/<arch>/), then the
installed-ASDF-source prefix. The override comes first and the
program-derived candidate is present -- that one is what makes a
release work with no environment variable and no ASDF sources."
  (let* ((dirs (mapcar #'namestring
                       (clautolisp.drawing.dwg::native-library-directories)))
         (platform (format nil "lib/clautolisp/~A/~A/"
                           (clautolisp.drawing.dwg::%os)
                           (clautolisp.drawing.dwg::%arch))))
    (is (plusp (length dirs)))
    ;; The development tree is always a candidate.
    (is (find-if (lambda (d) (search "drawing-dwg/source/" d)) dirs)
        "the dev tree must be searched: ~S" dirs)
    ;; When the implementation names the running program, its prefix is
    ;; searched, with the platform subdirectory appended.
    (when (clautolisp.drawing.dwg::running-program-prefix-candidates)
      (is (find-if (lambda (d) (search platform d)) dirs)
          "a program-derived lib/clautolisp/<os>/<arch>/ must be searched: ~S"
          dirs))
    ;; No duplicates: the same directory must not be probed twice.
    (is (= (length dirs) (length (remove-duplicates dirs :test #'equal))))))

;;; --- a drawing BUILT here, written as DWG ---------------------------
;;;
;;; dwg-write-rejects-a-drawing-built-in-memory: dwg-write-then-read-
;;; round-trips above starts from a PARSED DWG, whose header and tables
;;; come from the file, so it never exercised what a clautolisp session
;;; actually produces. Every such session's SaveAs to .dwg failed, for two
;;; header reasons (a second $ACADVER carrying the product version, and an
;;; integer sysvar over the 16-bit group-70 range), plus the need for the
;;; standard symbol tables.

(test dwg-writes-a-drawing-built-in-memory
  "A drawing created in this process -- standard tables, a product-version
ACADVER sysvar, an out-of-16-bit-range sysvar, and an entity -- writes as
DWG and reads back as one. Both header traps are in place, so this fails
before the 2.2.101 header fixes: DWG_ERR_INVALIDDWG for the duplicate
$ACADVER, DWG_ERR_IOERROR for the group-70 overflow."
  (let* ((d (clautolisp.drawing:make-drawing :version :ac1027))
         (out (format nil "/tmp/clal-dwg-fresh-~D.dwg" (get-internal-real-time))))
    ;; The symbol tables every real drawing has; without them libredwg
    ;; cannot build a DWG at all (DWG_ERR_IOERROR).
    (dolist (spec '((:block-record "*Model_Space" "*Paper_Space")
                    (:layer "0") (:ltype "BYBLOCK" "BYLAYER" "Continuous")
                    (:style "Standard") (:dimstyle "Standard")
                    (:vport "*Active") (:appid "ACAD")))
      (dolist (name (cdr spec))
        (clautolisp.drawing:add-table-record
         d (clautolisp.drawing:make-symbol-table-record
            :kind (car spec) :name name
            :data (list (cons 0 (string-upcase (symbol-name (car spec))))
                        (cons 2 name))))))
    ;; The two header traps, as a cador document carries them.
    (clautolisp.drawing:ensure-drawing-variable d "ACADVER" :kind :string
                                                            :value "2.2.99")
    (clautolisp.drawing:ensure-drawing-variable d "CMPDIFFLIMIT"
                                                :kind :integer :value 10000000)
    (clautolisp.drawing:add-entity
     d (list (cons 0 "LINE") (cons 8 "0")
             (cons 10 0.0d0) (cons 20 0.0d0) (cons 30 0.0d0)
             (cons 11 10.0d0) (cons 21 10.0d0) (cons 31 0.0d0)))
    (unwind-protect
         (progn
           (clautolisp.drawing:write-drawing d out :format :dwg)
           (is (probe-file out))
           (let ((back (clautolisp.drawing:read-drawing out)))
             (is (eq :dwg (clautolisp.drawing:drawing-format back))
                 "the file written must read back as a DWG")
             ;; The ENTITY does not survive, and that is a separate,
             ;; pre-existing defect of the DWG round trip -- a drawing
             ;; PARSED from a DWG loses an added entity the same way, so
             ;; it is not about being built in memory. Filed as
             ;; dwg-round-trip-loses-entities; asserting it here would
             ;; only pin this test to that bug's fix.
             (is (zerop (clautolisp.drawing:drawing-entity-count back))
                 "documents today's entity loss; see dwg-round-trip-loses-entities")))
      (ignore-errors (delete-file out)))))
