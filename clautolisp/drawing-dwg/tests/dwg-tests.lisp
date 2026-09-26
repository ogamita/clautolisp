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
  "Every kind of candidate is PRESENT: the development tree, and the prefixes
of the RUNNING program (lib/clautolisp/<os>/<arch>/) -- the latter is what
makes a release work with no environment variable and no ASDF sources -- with
no duplicates.

This test only ever checked PRESENCE, although its docstring used to recite an
order (override, dev tree, program, installed). It therefore passed unchanged
when the order was corrected to put the program's own library BEFORE the
development tree, which is a fair warning about prose that claims more than the
assertions below it. The order itself is asserted by
NATIVE-LIBRARY-ORDER-PUTS-THE-PROGRAM-BEFORE-THE-DEVELOPMENT-TREE."
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

;;; --- choosing among candidate native libraries --------------------
;;;
;;; clautolisp-distributed-native-libraries-not-loaded, measured on the
;;; Windows runner 2026-09-26: a complete installed release FAILED to save a
;;; DWG because the search took the first candidate that EXISTED -- the
;;; development tree's clal_dwg.dll, which has no libredwg.dll beside it --
;;; and died on it, although the program's own lib/clautolisp/<os>/<arch>/
;;; carried a complete pair. On ELF the same wrong pick is invisible (the dev
;;; copy's rpath resolves its dependency), which is why the Linux check had
;;; been passing without ever loading the installed library.
;;;
;;; The choice is tested here with injected probe/try functions: no real
;;; library, no platform dependency, and the Windows case reproducible on
;;; Linux.

(defun %fake-shim-selection (candidates existing usable)
  "Run the selection over CANDIDATES where EXISTING names the ones on disk and
USABLE the ones that load. Returns (values PATH SKIPPED-NAMES)."
  (multiple-value-bind (path skipped)
      (clautolisp.drawing.dwg::%select-usable-shim
       candidates
       :probe (lambda (p) (member p existing :test #'equal))
       :try (lambda (p)
              (if (member p usable :test #'equal)
                  t
                  (values nil "no libredwg.dll beside it"))))
    (values path (mapcar #'car skipped))))

(test shim-selection-falls-through-an-existing-but-unusable-candidate
  (let ((dev "/checkout/drawing-dwg/source/clal_dwg.dll")
        (installed "/prefix/lib/clautolisp/windows/x86-64/clal_dwg.dll"))
    ;; The reported case: both exist, the dev one cannot load.
    (multiple-value-bind (path skipped)
        (%fake-shim-selection (list dev installed) (list dev installed) (list installed))
      (is (equal installed path)
          "the installed library must be used when the dev copy cannot load")
      (is (equal (list dev) skipped)
          "and the skipped candidate is reported, so nobody silently runs an ~
older library"))))

(test shim-selection-prefers-the-first-usable-candidate
  (let ((dev "/checkout/drawing-dwg/source/clal_dwg.so")
        (installed "/prefix/lib/clautolisp/linux/x86-64/clal_dwg.so"))
    ;; A developer's own build still wins when it works: the order is right,
    ;; only the give-up-on-first-existing was wrong.
    (multiple-value-bind (path skipped)
        (%fake-shim-selection (list dev installed) (list dev installed)
                              (list dev installed))
      (is (equal dev path))
      (is (null skipped)))))

(test shim-selection-skips-what-is-not-on-disk
  (let ((absent "/nowhere/clal_dwg.so")
        (installed "/prefix/lib/clautolisp/linux/x86-64/clal_dwg.so"))
    (multiple-value-bind (path skipped)
        (%fake-shim-selection (list absent installed) (list installed) (list installed))
      (is (equal installed path))
      (is (null skipped) "a candidate that does not exist is not a rejection"))))

(test shim-selection-reports-every-rejection-when-none-works
  (let ((a "/a/clal_dwg.dll") (b "/b/clal_dwg.dll"))
    (multiple-value-bind (path skipped)
        (%fake-shim-selection (list a b) (list a b) '())
      (is (null path))
      (is (equal (list a b) skipped)
          "all of them, in order: the error message names each one and why"))))

;;; --- the ORDER of the candidate directories -----------------------
;;;
;;; The fall-through above keeps a broken candidate from ending the search;
;;; this is the root cause it was masking. A library shipped BESIDE THE
;;; PROGRAM belongs to that program; a build tree merely happens to be on the
;;; same machine. The Windows run of 2026-09-26 had an installed release load
;;; the checkout's clal_dwg.dll and fail to save.

(test native-library-order-puts-the-program-before-the-development-tree
  (let ((program "/prefix/lib/clautolisp/windows/x86-64/")
        (dev "/checkout/clautolisp/drawing-dwg/source/")
        (installed "/usr/share/common-lisp/.../")
        (override "/from/the/environment/"))
    ;; the whole order, with every piece present
    (is (equal (list override program dev installed)
               (clautolisp.drawing.dwg::%native-library-directories
                :override override :program-dirs (list program)
                :dev-dir dev :installed-libdir installed)))
    ;; an explicit instruction still outranks everything
    (is (equal override
               (first (clautolisp.drawing.dwg::%native-library-directories
                       :override override :program-dirs (list program)
                       :dev-dir dev))))
    ;; the case that was wrong: program before dev tree
    (is (equal (list program dev)
               (clautolisp.drawing.dwg::%native-library-directories
                :program-dirs (list program) :dev-dir dev)))))

(test native-library-order-leaves-a-developer-with-the-development-tree
  ;; Running from a checkout there is no program-owned library at all (the host
  ;; Lisp's prefix carries none), so the dev tree is still first -- which is
  ;; why this order costs a developer nothing.
  (let ((dev "/checkout/clautolisp/drawing-dwg/source/"))
    (is (equal (list dev)
               (clautolisp.drawing.dwg::%native-library-directories
                :program-dirs '() :dev-dir dev)))))

(test native-library-order-keeps-several-program-prefixes-in-order
  ;; Two layouts ship (below libexec, and plain bin/); both are candidates and
  ;; the more specific one stays first.
  (let ((a "/prefix/lib/clautolisp/linux/x86-64/")
        (b "/other/lib/clautolisp/linux/x86-64/")
        (dev "/checkout/clautolisp/drawing-dwg/source/"))
    (is (equal (list a b dev)
               (clautolisp.drawing.dwg::%native-library-directories
                :program-dirs (list a b) :dev-dir dev)))))

(test native-library-directories-is-duplicate-free-and-ordered-for-real
  ;; The real function, in this image: whatever it yields, it must be free of
  ;; duplicates and must not put the development tree before a program
  ;; directory. (In the test image the host Lisp owns no clautolisp library, so
  ;; this mostly proves the wiring is the pure function above.)
  (let* ((dirs (clautolisp.drawing.dwg::native-library-directories))
         (dev (uiop:pathname-directory-pathname
               (asdf:system-relative-pathname
                :clautolisp/drawing-dwg "drawing-dwg/source/x")))
         (dev-at (position dev dirs :test #'equal))
         (program-at (position-if (lambda (d)
                                    (search "lib/clautolisp/"
                                            (namestring d)))
                                  dirs)))
    (is (equal dirs (remove-duplicates dirs :test #'equal :from-end t)))
    (is (integerp dev-at) "the development tree is among the candidates")
    (is (or (null program-at) (< program-at dev-at))
        "a program-owned directory, when there is one, comes first")))

;;; --- the libredwg DLL's name is toolchain-dependent ----------------
;;;
;;; Measured on the Windows runner (2026-09-26): MSYS2 links libredwg as
;;; msys-redwg.dll. The pre-load check hard-coded "libredwg.dll", so a
;;; correctly installed pair was reported as a shim without its dependency --
;;; twice, once blaming the development tree and once the installed prefix.

(test libredwg-dependency-is-recognised-under-every-toolchain-spelling
  (flet ((found (&rest names)
           (let ((hit (clautolisp.drawing.dwg::%libredwg-dependency-in
                       (mapcar #'pathname names))))
             (and hit (file-namestring hit)))))
    ;; the spelling that actually shipped on the runner
    (is (equal "msys-redwg.dll" (found "/lib/clal_dwg.dll" "/lib/msys-redwg.dll")))
    ;; and the others in the wild
    (is (equal "libredwg.dll" (found "/lib/libredwg.dll")))
    (is (equal "libredwg-0.dll" (found "/lib/libredwg-0.dll")))
    (is (equal "cygredwg-0.dll" (found "/lib/cygredwg-0.dll")))
    (is (equal "redwg.dll" (found "/lib/redwg.dll")))
    ;; case does not decide it
    (is (equal "LibReDWG.dll" (found "/lib/LibReDWG.dll")))))

(test libredwg-dependency-does-not-mistake-the-shim-for-itself
  ;; clal_dwg contains "dwg" but not "redwg" -- which is why that is the test.
  (is (null (clautolisp.drawing.dwg::%libredwg-dependency-in
             (list (pathname "/lib/clal_dwg.dll")))))
  (is (null (clautolisp.drawing.dwg::%libredwg-dependency-in '())))
  ;; an unrelated DLL beside it is not the dependency either
  (is (null (clautolisp.drawing.dwg::%libredwg-dependency-in
             (list (pathname "/lib/clal_dwg.dll") (pathname "/lib/zlib1.dll"))))))
