(in-package #:clautolisp.cadtui)

;;;; Line classification / the escape mechanism (Phase 2 slice 1).
;;;;
;;;; The cadtui console reads one physical line at a time. A single leading
;;;; escape character (default =, spec principe 4) marks the WHOLE line as a
;;;; meta-command; a doubled leading escape (==) cancels the escape and delivers
;;;; the rest verbatim; anything else is passed through untouched. Because the
;;;; decision is by leading character, no syntactic analysis of the line is ever
;;;; needed — a pass-through line shaped like verbe(args) is never mistaken for a
;;;; meta-command (spec §Classification lines 524-551), which is the whole point
;;;; of the escape: an AutoLISP read-line may legitimately expect such a line.
;;;;
;;;; This is a PURE function. Phase 4 wires it as the READER of the console
;;;; interactor and makes the escape an interactor-stacked setting
;;;; (TUI-COMMAND-ESCAPE); *COMMAND-ESCAPE* here is the Phase-2 stand-in.

(defvar *command-escape* #\=
  "The leading character that marks a meta-command line (spec principe 4:
'=' — '!' is the shell escape, ',' the clautolisp-command escape). A doubled
leading occurrence cancels it. Phase-4 will make this an interactor-stacked
setting; for now it is a plain special.")

(defun classify-line (line &key (escape *command-escape*))
  "Classify a physical LINE, returning (values KIND PAYLOAD):
  - a single leading ESCAPE  => (values :meta-command  <rest of line>)
      the escape is stripped; PAYLOAD is the verbe(args) text (whole line).
  - a doubled leading ESCAPE => (values :pass-through <line minus one escape>)
      the escape is cancelled; the remainder (still leading a literal ESCAPE)
      is passed through verbatim.
  - anything else            => (values :pass-through LINE)   ; intact
An empty LINE is pass-through. A lone ESCAPE yields an empty meta-command (which
the parser then rejects). ESCAPE anywhere but the first character is inert."
  (let ((len (length line)))
    (cond
      ((zerop len) (values :pass-through line))
      ((char/= (char line 0) escape) (values :pass-through line))
      ;; first char IS the escape:
      ((and (>= len 2) (char= (char line 1) escape))
       ;; doubled escape => cancel: drop one escape, pass the rest through.
       (values :pass-through (subseq line 1)))
      (t
       ;; single leading escape => meta-command, escape stripped.
       (values :meta-command (subseq line 1))))))
