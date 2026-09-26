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
             ;; The ENTITY still does not survive from a drawing built
             ;; ENTIRELY here, and the reason is now known precisely
             ;; (dwg-round-trip-loses-entities): libredwg needs the
             ;; entity's owner handle to RESOLVE -- which it now does,
             ;; group 330 is written and the record carries the handle --
             ;; AND a properly formed BLOCKS section, with the
             ;; *Model_Space BLOCK header carrying its own handle, owner
             ;; and AcDbEntity / AcDbBlockBegin markers. Our writer emits
             ;; a bare BLOCK / ENDBLK pair, so the second half is missing.
             ;; A drawing PARSED from a DWG has both and round-trips its
             ;; entities (dwg-parsed-drawing-keeps-its-entities below).
             (is (zerop (clautolisp.drawing:drawing-entity-count back))
                 "documents what a bare skeleton still loses; see ~
dwg-round-trip-loses-entities")))
      (ignore-errors (delete-file out)))))

(test dwg-parsed-drawing-keeps-its-entities
  "A drawing read from a DWG, given one more entity, comes back from a DWG
round trip with ONE MORE than the same drawing round-tripped unchanged.
That is the half dwg-round-trip-loses-entities fixed: an entity is now
written with its owner block record (group 330), which libredwg requires
and our writer did not emit -- a LINE used to vanish into a successful
save.

The comparison is against the SAME drawing round-tripped without the
addition, not against the source, because libredwg's own writer does not
keep every entity type of a rich sample: example_2000.dwg goes in with
228 entities and comes out with 183, and an entity ADDED to it is lost
among them. sample_2000.dwg is small and lossless (6 in, 6 out), which is
why it is the fixture here; example_r13 and example_r14 behave too. What
must hold is the DELTA: adding one entity adds one."
  (let* ((source (sample-dwg "sample_2000.dwg"))
         (plain (clautolisp.drawing:read-drawing source))
         (with-line (clautolisp.drawing:read-drawing source))
         (out-plain (format nil "/tmp/clal-dwg-plain-~D.dwg" (get-internal-real-time)))
         (out-line (format nil "/tmp/clal-dwg-line-~D.dwg" (get-internal-real-time))))
    (clautolisp.drawing:add-entity
     with-line (list (cons 0 "LINE") (cons 8 "0")
                     (cons 10 0.0d0) (cons 20 0.0d0) (cons 30 0.0d0)
                     (cons 11 7.0d0) (cons 21 7.0d0) (cons 31 0.0d0)))
    (unwind-protect
         (progn
           (clautolisp.drawing:write-drawing plain out-plain :format :dwg)
           (clautolisp.drawing:write-drawing with-line out-line :format :dwg)
           (let ((back-plain (clautolisp.drawing:drawing-entity-count
                              (clautolisp.drawing:read-drawing out-plain)))
                 (back-line (clautolisp.drawing:drawing-entity-count
                             (clautolisp.drawing:read-drawing out-line))))
             (is (plusp back-plain) "the sample's entities must survive at all")
             (is (= (1+ back-plain) back-line)
                 "the added entity must survive: ~D without it, ~D with it"
                 back-plain back-line)))
      (ignore-errors (delete-file out-plain))
      (ignore-errors (delete-file out-line)))))

(test dwg-a-drawing-from-the-template-keeps-its-entities
  "dwg-round-trip-loses-entities, the other half: a drawing created from
the DXF TEMPLATE -- not hand-assembled -- writes as DWG and reads back
WITH its entity. The template carries what a bare skeleton cannot: real
symbol table records and properly formed *Model_Space / *Paper_Space block
definitions, which libredwg needs on top of a resolving owner handle.

It is DXF, so creating the drawing needs no native library; only this test
needs one, to write the DWG."
  (let* ((d (clautolisp.drawing:make-drawing-from-template :name "T.dwg"))
         (out (format nil "/tmp/clal-dwg-template-~D.dwg" (get-internal-real-time))))
    (is (probe-file (clautolisp.drawing:drawing-template-path))
        "the template must ship with the drawing system")
    (is (zerop (clautolisp.drawing:drawing-entity-count d))
        "a new drawing from the template starts with no entities")
    (is (plusp (hash-table-count (clautolisp.drawing:drawing-blocks d)))
        "but it does carry block definitions")
    (clautolisp.drawing:add-entity
     d (list (cons 0 "LINE") (cons 8 "0")
             (cons 10 0.0d0) (cons 20 0.0d0) (cons 30 0.0d0)
             (cons 11 7.0d0) (cons 21 7.0d0) (cons 31 0.0d0)))
    (unwind-protect
         (progn
           (clautolisp.drawing:write-drawing d out :format :dwg)
           (let ((back (clautolisp.drawing:read-drawing out)))
             (is (eq :dwg (clautolisp.drawing:drawing-format back)))
             (is (= 1 (clautolisp.drawing:drawing-entity-count back))
                 "the entity must survive: this is what a hand-built ~
skeleton loses")))
      (ignore-errors (delete-file out)))))
