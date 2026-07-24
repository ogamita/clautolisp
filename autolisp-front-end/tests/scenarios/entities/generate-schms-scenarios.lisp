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
  (with-open-file (in path :direction :input :external-format :utf-8)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

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
       (dd-text (slurp dd-lsp))
       (sel-text (slurp sel-lsp))
       (dd-pass "ALL DRAWING-DATA PROBES PASSED")
       (sel-pass "ALL SELECTION PROBES PASSED"))
  ;; --- drawing-data ---
  (write-scenario "drawing-data.sexp"
    :name "drawing-data-clautolisp"
    :description "Portable drawing-data-structures probe (drawing-data-probe.lsp) run under the clautolisp backend with the mock host: REGAPP; the full XData group-code set (1000/1002/1003/1005/1040/1070/1071) round-tripped through entget/entmod preserving order and multiplicity; multi-application xdata filtering; the named-object-dictionary tree with an XRECORD create/read/mutate/remove lifecycle; and tblsearch/tblnext over LAYER/LTYPE/STYLE/APPID. The identical .lsp runs unchanged on BricsCAD/AutoCAD via alfe."
    :classification :clautolisp-only
    :argv '("--clautolisp" "--host" "mock" "-l" "drawing-data-probe.lsp")
    :lsp-file dd-lsp :lsp-text dd-text :pass-line dd-pass
    :covers '("--clautolisp" "--host" "-l"))
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
  (format t "~&Generated 6 SCHMS scenarios.~%"))
