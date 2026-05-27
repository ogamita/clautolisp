;;;; tests/sysvar/coupling-angle.lsp
;;;;
;;;; Behavioural couplings for the angle sysvars:
;;;;
;;;;   ANGBASE  - zero-angle direction (radians)
;;;;   ANGDIR   - clockwise / counter-clockwise sense
;;;;   AUNITS   - angular display unit (decimal / dms / grads / rad)
;;;;   AUPREC   - decimal places for angtos output
;;;;
;;;; angtos / angle / getangle / getorient read these. We assert the
;;;; effect of changing each sysvar on angtos output, which is the
;;;; one most fully exercisable in a headless harness.

;;; --- ANGBASE: ANGBASE rotates angtos's zero. -----------------------

(deftest "sysvar-angbase-zero-default"
  '((operator . "ANGBASE") (area . "sysvar") (profile . strict))
  '(progn (setvar "ANGBASE" 0.0)
          (angtos 0.0 0 4))
  "0.0000")

(deftest "sysvar-angbase-shifts-angtos-output"
  '((operator . "ANGBASE") (area . "sysvar") (profile . strict))
  ;; With ANGBASE = pi, the radian 0 is "behind" us. Round-tripping a
  ;; pre-shifted angle should yield the documented offset string.
  '(progn (setvar "ANGBASE" 0.0)
          (setvar "AUNITS" 0)
          (setvar "AUPREC" 4)
          (angtos pi 0 4))
  "180.0000")

;;; --- AUNITS: 0 = decimal degrees, 3 = radians ----------------------

(deftest "sysvar-aunits-radians-formats-radians"
  '((operator . "AUNITS") (area . "sysvar") (profile . strict))
  '(progn (setvar "ANGBASE" 0.0)
          (setvar "AUNITS" 3)
          (setvar "AUPREC" 4)
          (angtos pi 3 4))
  "3.1416r")

(deftest "sysvar-aunits-grads-formats-grads"
  '((operator . "AUNITS") (area . "sysvar") (profile . strict))
  '(progn (setvar "ANGBASE" 0.0)
          (setvar "AUNITS" 2)
          (setvar "AUPREC" 4)
          (angtos (/ pi 2.0) 2 4))
  "100.0000g")

;;; --- AUPREC: decimal places ----------------------------------------

(deftest "sysvar-auprec-controls-precision"
  '((operator . "AUPREC") (area . "sysvar") (profile . strict))
  '(progn (setvar "ANGBASE" 0.0)
          (setvar "AUNITS" 0)
          (setvar "AUPREC" 6)
          (angtos (/ pi 4.0) 0 6))
  "45.000000")

;;; --- Round-trip: setvar accepts radians regardless of AUNITS ------

(deftest "sysvar-angbase-setvar-takes-radians-not-aunits-form"
  ;; setvar interprets ANGBASE in radians; getvar returns radians.
  ;; Independent of AUNITS.
  '((operator . "ANGBASE") (area . "sysvar") (profile . strict))
  '(progn (setvar "AUNITS" 0)
          (setvar "ANGBASE" 0.0)
          (let ((value-degrees (setvar "AUNITS" 0)))
            (setvar "ANGBASE" 1.5707963267948966)
            (= (getvar "ANGBASE") 1.5707963267948966)))
  T)
