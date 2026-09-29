(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; DIESEL through (menucmd "M=..."): system-variables.issue -- the DATE
;;;; family had no EDTIME consumer, and MENUCMD was a stub.

(defun %diesel (expression)
  "(menucmd \"M=EXPRESSION\") under a cador host, as a CL string."
  (autolisp-string-value
   (%al (format nil "(menucmd ~S)" (concatenate 'string "M=" expression)))))

(defun %jd (year month day &optional (day-fraction 0))
  "The DATE-sysvar value (Julian Day Number + day fraction) of a date."
  (+ (clautolisp.cador::%gregorian-julian-day-number year month day) day-fraction))

(test diesel-arithmetic-and-comparison
  (is (string= "3" (%diesel "$(+,1,2)")))
  (is (string= "6" (%diesel "$(*,1,2,3)")))
  (is (string= "0.25" (%diesel "$(/,1,4)")))
  (is (string= "-1" (%diesel "$(-,1,2)")))
  (is (string= "1" (%diesel "$(=,2,2.0)")))
  (is (string= "0" (%diesel "$(>,1,2)")))
  (is (string= "1" (%diesel "$(!=,1,2)")))
  (is (string= "2" (%diesel "$(and,6,3)")))
  (is (string= "7" (%diesel "$(or,6,3)")))
  (is (string= "3" (%diesel "$(fix,3.7)"))))

(test diesel-strings-and-control
  (is (string= "yes" (%diesel "$(if,$(=,1,1),yes,no)")))
  (is (string= "no" (%diesel "$(if,0,yes,no)")))
  (is (string= "1" (%diesel "$(eq,abc,abc)")))
  (is (string= "5" (%diesel "$(strlen,hello)")))
  (is (string= "ell" (%diesel "$(substr,hello,2,3)")))
  (is (string= "ABC" (%diesel "$(upper,abc)")))
  (is (string= "b" (%diesel "$(index,1,\"a,b,c\")")) "a quoted comma is text")
  (is (string= "c" (%diesel "$(nth,2,a,b,c)")))
  (is (string= "3" (%diesel "$(eval,$(+,1,2))")))
  (is (string= "x=2!" (%diesel "x=$(+,1,1)!")) "text around a call is copied"))

(test diesel-errors-are-the-documented-strings
  (is (string= "$(nosuch)??" (%diesel "$(nosuch,1)")))
  (is (string= "$(/,??)" (%diesel "$(/,1,0)")))
  (is (string= "$(+,??)" (%diesel "$(+,a)")))
  (is (string= "$?" (%diesel "$(+,1"))))

(test diesel-getvar-reads-the-host
  (is (string= "2" (%diesel "$(getvar,lunits)")))
  (is (string= "4" (%diesel "$(getvar,luprec)"))))

(test diesel-edtime-formats-a-julian-date
  ;; the spec's own example shape: DDDD"," D MONTH YYYY
  (let ((jd (%jd 2026 9 29)))
    (is (string= "Tuesday, 29 September 2026"
                 (%diesel (format nil "$(edtime,~F,DDDD\",\" D MONTH YYYY)" jd))))
    (is (string= "Tue Sep" (%diesel (format nil "$(edtime,~F,DDD MON)" jd))))
    (is (string= "26-09-29" (%diesel (format nil "$(edtime,~F,YY-MO-DD)" jd))))
    (is (string= "9/29/2026" (%diesel (format nil "$(edtime,~F,M/D/YYYY)" jd)))))
  (let ((jd (%jd 2026 1 5 0.75d0)))       ; 18:00
    (is (string= "06:00:00 PM" (%diesel (format nil "$(edtime,~F,HH:MM:SS AM/PM)" jd))))
    (is (string= "18:00" (%diesel (format nil "$(edtime,~F,HH:MM)" jd))))
    (is (string= "6p" (%diesel (format nil "$(edtime,~F,Ha/p)" jd)))))
  (let ((jd (%jd 2026 1 5 0)))            ; midnight: 12 AM on a 12-hour clock
    (is (string= "12 AM" (%diesel (format nil "$(edtime,~F,H AM/PM)" jd))))))

(test diesel-edtime-of-zero-is-now
  ;; $(edtime,0,...) formats the current DATE: at least the year is right.
  (multiple-value-bind (s m h d mo year) (decode-universal-time (get-universal-time))
    (declare (ignore s m h d mo))
    (is (string= (format nil "~D" year) (%diesel "$(edtime,0,YYYY)")))))

(test menucmd-other-areas-stay-empty
  (is (string= "" (autolisp-string-value (%al "(menucmd \"P1=*\")")))))
