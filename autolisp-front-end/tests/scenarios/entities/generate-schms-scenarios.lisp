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
                              lsp-file lsp-text pass-line observations
                              observations-default covers)
  (format out "(:name ~S~%" name)
  (format out " :description ~S~%" description)
  (format out " :classification :~(~A~)~%" (symbol-name classification))
  (format out " :argv ~S~%" argv)
  (format out " :setup-files ((~S " lsp-file)
  (prin1 lsp-text out)
  (format out "))~%")
  (format out " :expected-exit 0~%")
  ;; Probe-model scenarios (autolisp-spec ch.25) carry per-target
  ;; :expected-observations (+ an optional default for the portable
  ;; checks); the pre-observation probes still key on a stdout pass-line.
  (cond
    ((or observations observations-default)
     (when observations
       (format out " :expected-observations (~%")
       (dolist (o observations)
         (format out "   ~S~%" o))
       (format out "  )~%"))
     (when observations-default
       (format out " :expected-observations-default ~S~%" observations-default)))
    (t (format out " :expected-stdout-includes (~S)~%" pass-line)))
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
       ;; --- drawing-data expected observations (autolisp-spec ch.25) ---
       ;; The portable observations every target must exhibit identically.
       (dd-obs-portable
        '(("regapp.fresh" "name")
          ("xdata.hidden-without-applist" "yes")
          ("xdata.surfaced-with-applist" "yes")
          ("xdata.pair-count" "8")
          ("xdata.1000-string" "yes")
          ("xdata.1040-real" "yes")
          ("xdata.1070-int16" "yes")
          ("xdata.1071-int32" "yes")
          ("xdata.1005-handle" "yes")
          ("xdata.single-app-count" "1")
          ("xdata.wildcard-count" "2")
          ("dict.namedobjdict-ename" "yes")
          ("dict.entmakex-xrecord-ename" "yes")
          ("dict.dictadd-ename" "yes")
          ("dict.dictsearch-found" "yes")
          ("dict.dictsearch-type" "XRECORD")
          ("dict.dictsearch-payload" "payload")
          ("dict.duplicate-key" "nil")
          ("dict.dictremove-gone" "yes")
          ("table.layer-0" "yes")
          ("table.ltype-continuous" "yes")
          ("table.style-standard" "yes")
          ("table.appid-acad" "yes")
          ("table.absent-nil" "yes")
          ("table.tblnext-record" "yes")
          ("table.tblnext-group2-str" "yes")))
       ;; Divergence D3 (entmod on an XRECORD entry): the autolisp-spec
       ;; adopts AutoCAD's NO-OP (readback "payload") as normative. The
       ;; normative targets (clautolisp under the strict default, AutoCAD)
       ;; exhibit "payload" -> CONFORMS; BricsCAD mutates ("payload2") ->
       ;; KNOWN-DIVERGENCE (3rd token = the normative value).
       (dd-obs-normative
        (append dd-obs-portable '(("dict.entmod-xrecord-entry" "payload"))))
       (dd-obs-bricscad
        (append dd-obs-portable
                '(("dict.entmod-xrecord-entry" "payload2" "payload"))))
       ;; --- entity-lifecycle: portable checks default to "yes"; only the
       ;; D1 marker policy is divergent. Normative (clautolisp under the
       ;; strict default, AutoCAD) rejects marker-less R13+ data -> CONFORMS;
       ;; BricsCAD synthesises and creates -> KNOWN-DIVERGENCE.
       (el-obs-normative
        '(("d1.markerless-ellipse"    "rejected")
          ("d1.markerless-lwpolyline" "rejected")
          ("d1.markerless-ray"        "rejected")
          ("d1.markerless-xline"      "rejected")))
       (el-obs-bricscad
        '(("d1.markerless-ellipse"    "created" "rejected")
          ("d1.markerless-lwpolyline" "created" "rejected")
          ("d1.markerless-ray"        "created" "rejected")
          ("d1.markerless-xline"      "created" "rejected"))))
  ;; --- drawing-data ---
  (write-scenario "drawing-data.sexp"
    :name "drawing-data-clautolisp"
    :description "Portable drawing-data-structures probe (drawing-data-probe.lsp) run under the clautolisp backend with the mock host: REGAPP; the full XData group-code set (1000/1002/1003/1005/1040/1070/1071) round-tripped through entget/entmod preserving order and multiplicity; multi-application xdata filtering; the named-object-dictionary tree with an XRECORD create/read/mutate/remove lifecycle; and tblsearch/tblnext over LAYER/LTYPE/STYLE/APPID. The identical .lsp runs unchanged on BricsCAD/AutoCAD via alfe."
    :classification :clautolisp-only
    ;; Runs under the normative dialect (strict, the --clautolisp default),
    ;; so entmod on an XRECORD entry is a no-op -> "payload" -> CONFORMS.
    :argv '("--clautolisp" "--host" "mock" "-l" "drawing-data-probe.lsp")
    :lsp-file dd-lsp :lsp-text dd-text :observations dd-obs-normative
    :covers '("--clautolisp" "--host" "-l"))
  (write-scenario "drawing-data-bricscad.sexp"
    :name "drawing-data-bricscad"
    :description "The SAME portable drawing-data-structures probe (drawing-data-probe.lsp), run UNCHANGED on BricsCAD via alfe. Classified bricscad-only: the conformance runner SKIPS it unless BricsCAD is detected on the host — the vendor-verification tail for the drawing-data-structures-parity work (BLOCKED on real CAD access). When a BricsCAD install is present it must print the same ALL DRAWING-DATA PROBES PASSED line."
    :classification :bricscad-only
    :argv '("--bricscad" "-l" "drawing-data-probe.lsp")
    :lsp-file dd-lsp :lsp-text dd-text :observations dd-obs-bricscad
    :covers '("--bricscad" "-l"))
  (write-scenario "drawing-data-autocad.sexp"
    :name "drawing-data-autocad"
    :description "The SAME portable drawing-data-structures probe (drawing-data-probe.lsp), run UNCHANGED on AutoCAD via alfe. Classified autocad-only: the conformance runner SKIPS it unless AutoCAD is detected on the host — the vendor-verification tail for the drawing-data-structures-parity work (BLOCKED on real CAD access). When an AutoCAD install is present it must print the same ALL DRAWING-DATA PROBES PASSED line."
    :classification :autocad-only
    :argv '("--autocad" "-l" "drawing-data-probe.lsp")
    :lsp-file dd-lsp :lsp-text dd-text :observations dd-obs-normative
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
    :lsp-file el-lsp :lsp-text el-text
    :observations el-obs-normative :observations-default "yes"
    :covers '("--clautolisp" "--host" "-l"))
  (write-scenario "entity-lifecycle-bricscad.sexp"
    :name "entities-lifecycle-bricscad"
    :description "The SAME portable entity CRUD lifecycle probe (entity-lifecycle-probe.lsp), run UNCHANGED on BricsCAD via alfe. Classified bricscad-only: the conformance runner SKIPS it unless BricsCAD is detected on the host — it is the vendor-verification tail for the entity-mutation-parity work (BLOCKED on real CAD access). When a BricsCAD install is present it must print the same ALL ENTITY PROBES PASSED line."
    :classification :bricscad-only
    :argv '("--bricscad" "-l" "entity-lifecycle-probe.lsp")
    :lsp-file el-lsp :lsp-text el-text
    :observations el-obs-bricscad :observations-default "yes"
    :covers '("--bricscad" "-l"))
  (write-scenario "entity-lifecycle-autocad.sexp"
    :name "entities-lifecycle-autocad"
    :description "The SAME portable entity CRUD lifecycle probe (entity-lifecycle-probe.lsp), run UNCHANGED on AutoCAD via alfe. Classified autocad-only: the conformance runner SKIPS it unless AutoCAD is detected on the host — it is the vendor-verification tail for the entity-mutation-parity work (BLOCKED on real CAD access). When an AutoCAD install is present it must print the same ALL ENTITY PROBES PASSED line."
    :classification :autocad-only
    :argv '("--autocad" "-l" "entity-lifecycle-probe.lsp")
    :lsp-file el-lsp :lsp-text el-text
    :observations el-obs-normative :observations-default "yes"
    :covers '("--autocad" "-l"))
  (format t "~&Generated 9 SCHMS scenarios.~%"))
