;;;; tests/sysvar/coupling-date.lsp
;;;;
;;;; DATE / CDATE / MILLISECS are live clock sysvars: each GETVAR
;;;; reports the current time, so these tests assert structure (type and
;;;; range), not exact values. DATE is a Julian day + fraction-of-day;
;;;; CDATE is the decimal YYYYMMDD.HHMMSS; MILLISECS is a monotonic
;;;; millisecond tick.

(deftest-pred "sysvar-date-is-julian-day-with-fraction"
  '((operator . "DATE") (area . "sysvar") (profile . strict))
  '(getvar "DATE")
  '(and (< 2400000.0 *result*)                 ; modern Julian day numbers
        (< *result* 2500000.0)
        (>= (- *result* (fix *result*)) 0.0)   ; day fraction in [0,1)
        (< (- *result* (fix *result*)) 1.0)))

(deftest-pred "sysvar-cdate-integer-is-yyyymmdd"
  '((operator . "CDATE") (area . "sysvar") (profile . strict))
  '(fix (getvar "CDATE"))
  '(and (> *result* 19000000) (< *result* 99999999)))

(deftest-pred "sysvar-millisecs-is-nonnegative-integer"
  '((operator . "MILLISECS") (area . "sysvar") (profile . strict))
  '(getvar "MILLISECS")
  '(and (= *result* (fix *result*)) (>= *result* 0)))

(deftest-pred "sysvar-date-cdate-share-the-calendar-day"
  '((operator . "CDATE") (area . "sysvar") (profile . strict))
  '(list (fix (getvar "DATE")) (fix (getvar "CDATE")))
  '(and (< 2400000 (car *result*)) (> (cadr *result*) 19000000)))
