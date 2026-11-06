(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 2 slice 1: line classifier / escape mechanism.

(defun %classify (line)
  "classify-line as a (kind . payload) cons, for easy comparison."
  (multiple-value-bind (kind payload) (classify-line line)
    (cons kind payload)))

(test classify-single-escape-is-meta-command
  ;; A single leading escape marks the whole line a meta-command; escape stripped.
  (is (equal '(:meta-command . "dump(console)") (%classify "=dump(console)")))
  (is (equal '(:meta-command . "aide()") (%classify "=aide()")))
  (is (equal '(:meta-command . "suite") (%classify "=suite"))))

(test classify-doubled-escape-is-pass-through-minus-one
  ;; == cancels the escape: one escape removed, the rest passed through verbatim
  ;; (so it still leads with a literal '=').
  (is (equal '(:pass-through . "=dump(x)") (%classify "==dump(x)")))
  (is (equal '(:pass-through . "=") (%classify "=="))))

(test classify-plain-line-is-pass-through-intact
  ;; A line with no leading escape is passed through unchanged — including one
  ;; shaped like verbe(args), the case that motivates the escape (an AutoLISP
  ;; read-line may legitimately expect such a line).
  (is (equal '(:pass-through . "LINE") (%classify "LINE")))
  (is (equal '(:pass-through . "(setq a 1)") (%classify "(setq a 1)")))
  (is (equal '(:pass-through . "foo(bar)") (%classify "foo(bar)")))
  (is (equal '(:pass-through . "touche(f2)") (%classify "touche(f2)")))
  (is (equal '(:pass-through . "@10,5") (%classify "@10,5"))))

(test classify-empty-and-lone-escape
  (is (equal '(:pass-through . "") (%classify "")))
  ;; a lone escape is an (empty) meta-command; the parser rejects it later.
  (is (equal '(:meta-command . "") (%classify "="))))

(test classify-escape-mid-line-is-inert
  ;; The escape is only special as the FIRST character.
  (is (equal '(:pass-through . "a=b") (%classify "a=b")))
  (is (equal '(:pass-through . "x = y") (%classify "x = y"))))

(test classify-honours-a-custom-escape
  ;; The escape is a parameter (Phase 4 makes it an interactor setting).
  (multiple-value-bind (kind payload) (classify-line "!cmd()" :escape #\!)
    (is (eq :meta-command kind))
    (is (string= "cmd()" payload)))
  ;; with a custom escape, '=' is no longer special.
  (multiple-value-bind (kind payload) (classify-line "=dump(x)" :escape #\!)
    (is (eq :pass-through kind))
    (is (string= "=dump(x)" payload))))
