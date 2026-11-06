;; Minimal language-only reproducer: no CAD host or SCHMS installation needed.
(setq resultat (rem 12.0 16))
(if (and (= (type resultat) 'REAL) (equal resultat 12.0 1e-12))
  (princ "PASS: REM accepts real operands")
  (progn (princ "FAIL: unexpected REM value/type") (exit)))
(princ)
