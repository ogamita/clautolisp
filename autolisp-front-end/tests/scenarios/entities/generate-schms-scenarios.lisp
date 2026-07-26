;;;; generate-schms-scenarios.lisp
;;;;
;;;; Regenerate the .sexp conformance scenarios for the SCHMS
;;;; drawing-data + selection probes from the canonical .lsp sources, so
;;;; the embedded copies stay byte-identical. Run from this directory:
;;;;
;;;;   sbcl --script generate-schms-scenarios.lisp
;;;;
;;;; It (re)writes: drawing-data{,-bricscad,-autocad}.sexp and
;;;; selection{,-bricscad,-autocad}.sexp.

(defun slurp (path)
  ;; Read exactly the characters of PATH. NB: (file-length) counts OCTETS,
  ;; so `(make-string (file-length in))' over-allocates for UTF-8 files
  ;; with multibyte characters (em-dashes in the probe comments) and
  ;; leaves trailing NUL padding — which bloats the embedded copy and
  ;; makes the .sexp read as binary. Read char-by-char instead.
  (with-open-file (in path :direction :input :external-format :utf-8)
    (with-output-to-string (out)
      (loop for ch = (read-char in nil nil)
            while ch do (write-char ch out)))))

(defun emit-scenario (out &key name description classification argv
                              lsp-file lsp-text pass-line covers)
  (format out "(:name ~S~%" name)
  (format out " :description ~S~%" description)
  (format out " :classification :~(~A~)~%" (symbol-name classification))
  (format out " :argv ~S~%" argv)
  (format out " :setup-files ((~S " lsp-file)
  (prin1 lsp-text out)
  (format out "))~%")
  (format out " :expected-exit 0~%")
  (format out " :expected-stdout-includes (~S)~%" pass-line)
  (format out " :covers-options ~S)~%" covers))

(defun write-scenario (sexp-name &rest args)
  (with-open-file (out sexp-name :direction :output :if-exists :supersede
                                 :if-does-not-exist :create :external-format :utf-8)
    (apply #'emit-scenario out args)))

(let* ((dd-lsp "drawing-data-probe.lsp")
       (sel-lsp "selection-probe.lsp")
       (el-lsp "entity-lifecycle-probe.lsp")
       (dd-text (slurp dd-lsp))
       (sel-text (slurp sel-lsp))
       (el-text (slurp el-lsp))
       (dd-pass "ALL DRAWING-DATA PROBES PASSED")
       (sel-pass "ALL SELECTION PROBES PASSED")
       (el-pass "ALL ENTITY PROBES PASSED"))
  ;; --- drawing-data ---
  (write-scenario "drawing-data.sexp"
    :name "drawing-data-clautolisp"
    :description "Portable drawing-data-structures probe (drawing-data-probe.lsp) run under the clautolisp backend with the mock host: REGAPP; the full XData group-code set (1000/1002/1003/1005/1040/1070/1071) round-tripped through entget/entmod preserving order and multiplicity; multi-application xdata filtering; the named-object-dictionary tree with an XRECORD create/read/mutate/remove lifecycle; and tblsearch/tblnext over LAYER/LTYPE/STYLE/APPID. The identical .lsp runs unchanged on BricsCAD/AutoCAD via alfe."
    :classification :clautolisp-only
    ;; --lax: the probe's XRECORD entmod-mutate assertion exercises the
    ;; DEVIANT (BricsCAD) side of divergence D3; the autolisp-spec adopts
    ;; AutoCAD's no-op as normative, so the normative dialects would leave
    ;; the value unchanged. --lax reproduces the mutation silently (see
    ;; the ENTMOD *** clautolisp note, ch.25).
    :argv '("--clautolisp" "--lax" "--host" "mock" "-l" "drawing-data-probe.lsp")
    :lsp-file dd-lsp :lsp-text dd-text :pass-line dd-pass
    :covers '("--clautolisp" "--lax" "--host" "-l"))
  (write-scenario "drawing-data-bricscad.sexp"
    :name "drawing-data-bricscad"
    :description "The SAME portable drawing-data-structures probe (drawing-data-probe.lsp), run UNCHANGED on BricsCAD via alfe. Classified bricscad-only: the conformance runner SKIPS it unless BricsCAD is detected on the host — the vendor-verification tail for the drawing-data-structures-parity work (BLOCKED on real CAD access). When a BricsCAD install is present it must print the same ALL DRAWING-DATA PROBES PASSED line."
    :classification :bricscad-only
    :argv '("--bricscad" "-l" "drawing-data-probe.lsp")
    :lsp-file dd-lsp :lsp-text dd-text :pass-line dd-pass
    :covers '("--bricscad" "-l"))
  (write-scenario "drawing-data-autocad.sexp"
    :name "drawing-data-autocad"
    :description "The SAME portable drawing-data-structures probe (drawing-data-probe.lsp), run UNCHANGED on AutoCAD via alfe. Classified autocad-only: the conformance runner SKIPS it unless AutoCAD is detected on the host — the vendor-verification tail for the drawing-data-structures-parity work (BLOCKED on real CAD access). When an AutoCAD install is present it must print the same ALL DRAWING-DATA PROBES PASSED line."
    :classification :autocad-only
    :argv '("--autocad" "-l" "drawing-data-probe.lsp")
    :lsp-file dd-lsp :lsp-text dd-text :pass-line dd-pass
    :covers '("--autocad" "-l"))
  ;; --- selection ---
  (write-scenario "selection.sexp"
    :name "selection-clautolisp"
    :description "Portable selection + snapshot probe (selection-probe.lsp) run under the clautolisp backend with the mock host: the non-interactive whole-database scan (ssget \"X\") with the full filter grammar — entity type (0), comma-alternation, the -4 logical operators (<OR/<AND/<NOT) and relational comparison, and the -3 XData application filter — plus sslength/ssname/ssadd/ssdel/ssmemb membership semantics and entnext/entlast traversal. Every scan is fenced to the probe's own entities by an XData application filter, so the assertions hold on a non-empty drawing too. The identical .lsp runs unchanged on BricsCAD/AutoCAD via alfe."
    :classification :clautolisp-only
    :argv '("--clautolisp" "--host" "mock" "-l" "selection-probe.lsp")
    :lsp-file sel-lsp :lsp-text sel-text :pass-line sel-pass
    :covers '("--clautolisp" "--host" "-l"))
  (write-scenario "selection-bricscad.sexp"
    :name "selection-bricscad"
    :description "The SAME portable selection + snapshot probe (selection-probe.lsp), run UNCHANGED on BricsCAD via alfe. Classified bricscad-only: the conformance runner SKIPS it unless BricsCAD is detected on the host — the vendor-verification tail for the selection-and-snapshot-parity work (BLOCKED on real CAD access). When a BricsCAD install is present it must print the same ALL SELECTION PROBES PASSED line."
    :classification :bricscad-only
    :argv '("--bricscad" "-l" "selection-probe.lsp")
    :lsp-file sel-lsp :lsp-text sel-text :pass-line sel-pass
    :covers '("--bricscad" "-l"))
  (write-scenario "selection-autocad.sexp"
    :name "selection-autocad"
    :description "The SAME portable selection + snapshot probe (selection-probe.lsp), run UNCHANGED on AutoCAD via alfe. Classified autocad-only: the conformance runner SKIPS it unless AutoCAD is detected on the host — the vendor-verification tail for the selection-and-snapshot-parity work (BLOCKED on real CAD access). When an AutoCAD install is present it must print the same ALL SELECTION PROBES PASSED line."
    :classification :autocad-only
    :argv '("--autocad" "-l" "selection-probe.lsp")
    :lsp-file sel-lsp :lsp-text sel-text :pass-line sel-pass
    :covers '("--autocad" "-l"))
  ;; --- entity-lifecycle ---
  (write-scenario "entity-lifecycle.sexp"
    :name "entities-lifecycle-clautolisp"
    :description "Portable entity CRUD lifecycle probe (entity-lifecycle-probe.lsp) run under the clautolisp backend with the mock host. Create -> read -> modify -> read -> delete -> restore for LINE POINT CIRCLE ARC ELLIPSE TEXT LWPOLYLINE SOLID 3DFACE RAY XLINE, plus the entmakex/entmake return contract, xdata applist filtering, and entnext traversal. The R13+ entities carry their (100 . \"AcDb...\") subclass markers, so the probe is portable across every dialect and both vendors. The identical .lsp runs unchanged on BricsCAD/AutoCAD via alfe."
    :classification :clautolisp-only
    :argv '("--clautolisp" "--host" "mock" "-l" "entity-lifecycle-probe.lsp")
    :lsp-file el-lsp :lsp-text el-text :pass-line el-pass
    :covers '("--clautolisp" "--host" "-l"))
  (write-scenario "entity-lifecycle-bricscad.sexp"
    :name "entities-lifecycle-bricscad"
    :description "The SAME portable entity CRUD lifecycle probe (entity-lifecycle-probe.lsp), run UNCHANGED on BricsCAD via alfe. Classified bricscad-only: the conformance runner SKIPS it unless BricsCAD is detected on the host — it is the vendor-verification tail for the entity-mutation-parity work (BLOCKED on real CAD access). When a BricsCAD install is present it must print the same ALL ENTITY PROBES PASSED line."
    :classification :bricscad-only
    :argv '("--bricscad" "-l" "entity-lifecycle-probe.lsp")
    :lsp-file el-lsp :lsp-text el-text :pass-line el-pass
    :covers '("--bricscad" "-l"))
  (write-scenario "entity-lifecycle-autocad.sexp"
    :name "entities-lifecycle-autocad"
    :description "The SAME portable entity CRUD lifecycle probe (entity-lifecycle-probe.lsp), run UNCHANGED on AutoCAD via alfe. Classified autocad-only: the conformance runner SKIPS it unless AutoCAD is detected on the host — it is the vendor-verification tail for the entity-mutation-parity work (BLOCKED on real CAD access). When an AutoCAD install is present it must print the same ALL ENTITY PROBES PASSED line."
    :classification :autocad-only
    :argv '("--autocad" "-l" "entity-lifecycle-probe.lsp")
    :lsp-file el-lsp :lsp-text el-text :pass-line el-pass
    :covers '("--autocad" "-l"))
  (format t "~&Generated 9 SCHMS scenarios.~%"))
