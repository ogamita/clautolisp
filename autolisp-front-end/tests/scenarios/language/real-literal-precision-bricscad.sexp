(:name "real-literal-precision-bricscad"
 :description "A real literal of a -l file reaches the engine exactly, on BricsCAD (skipped unless BricsCAD is detected and $ALFE_VENDOR_CONFORMANCE is set): (= x (read \"1.5707963267948966\")) holds for the loaded literal and (rtos x 2 16) of a loaded 1.2345678901234 gives back all its digits. alfe-cad-transport-rounds-reals: the CAD backends used to re-print every loaded form, which kept 6 significant digits on AutoCAD and 14 on BricsCAD. The same fixture runs on every backend."
 :classification :bricscad-only
 :argv ("--bricscad" "-l" "real-literals.lsp")
 :setup-files (("real-literals.lsp" ";; real literals must reach the engine with every digit
;; (alfe-cad-transport-rounds-reals: alfe used to re-print each loaded form
;; for AutoCAD / BricsCAD, rounding a real to 6 / 14 significant digits).
(setq rlp-a 1.5707963267948966)
(setq rlp-e 1.2345678901234)
(princ (strcat \"REAL-LITERAL \" (if (= rlp-a (read \"1.5707963267948966\")) \"EXACT\" \"ROUNDED\") \"\\n\"))
(princ (strcat \"REAL-RTOS \" (rtos rlp-e 2 16) \"\\n\"))
"))
 :expected-exit 0
 :expected-stdout-includes ("REAL-LITERAL EXACT" "REAL-RTOS 1.2345678901234")
 :expected-stdout-excludes ("ROUNDED")
 :covers-options ("--bricscad" "-l"))
