;; Minimal XRecord payload regression; independent of SCHMS+.
(setq pkpm-repro-payload '((102 . "{") (60 . 900) (60 . 1000) (102 . "}")))
(setq pkpm-repro-xr
  (entmakex (append '((0 . "XRECORD") (100 . "AcDbXrecord")) pkpm-repro-payload)))
(setq pkpm-repro-actual (member '(102 . "{") (entget pkpm-repro-xr)))
(setq pkpm-repro-ok (equal pkpm-repro-payload pkpm-repro-actual))
(princ "EXPECTED: ") (prin1 pkpm-repro-payload) (terpri)
(princ "ACTUAL: ") (prin1 pkpm-repro-actual) (terpri)
(princ (if pkpm-repro-ok "PASS: XRecord payload preserved" "FAIL: XRecord payload lost"))
(terpri)
(if (entget pkpm-repro-xr) (entdel pkpm-repro-xr))
(setq pkpm-repro-xr nil)
