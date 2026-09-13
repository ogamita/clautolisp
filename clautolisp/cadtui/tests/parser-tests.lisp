(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 2 slice 2: meta-command parser.

(test parse-verb-with-single-target
  (let ((mc (parse-meta-command "dump(menu:Draw)")))
    (is (eq :dump (meta-command-verb mc)))
    (is (equal '((:target . "menu:Draw")) (meta-command-positionals mc)))
    (is (null (meta-command-options mc)))))

(test parse-target-plus-options
  ;; a target positional plus two options; option-vs-role:cle discrimination.
  (let ((mc (parse-meta-command "dump(active-drawing.cad-view.entities, page: 1, size: 20)")))
    (is (eq :dump (meta-command-verb mc)))
    (is (equal '((:target . "active-drawing.cad-view.entities"))
               (meta-command-positionals mc)))
    (is (equal 1 (cdr (assoc :page (meta-command-options mc)))))
    (is (equal 20 (cdr (assoc :size (meta-command-options mc)))))))

(test parse-window-tuple-and-factor
  (let ((mc (parse-meta-command "zoom(cad-view, window: (0 0 100 50))")))
    (is (eq :zoom (meta-command-verb mc)))
    (is (equal '((:target . "cad-view")) (meta-command-positionals mc)))
    (is (equal '(:tuple 0 0 100 50) (cdr (assoc :window (meta-command-options mc))))))
  (let ((mc (parse-meta-command "zoom(cad-view, factor: 2)")))
    (is (equal 2 (cdr (assoc :factor (meta-command-options mc)))))))

(test parse-multiple-positionals-with-negative-number
  (let ((mc (parse-meta-command "drag(a, 10, -5)")))
    (is (eq :drag (meta-command-verb mc)))
    (is (equal '((:target . "a") 10 -5) (meta-command-positionals mc)))))

(test parse-indexed-target
  (let ((mc (parse-meta-command "activate(drawings[2])")))
    (is (eq :activate (meta-command-verb mc)))
    (is (equal '((:target . "drawings[2]")) (meta-command-positionals mc)))))

(test parse-bare-verbs
  ;; next / previous / help appear without parens.
  (is (eq :next (meta-command-verb (parse-meta-command "next"))))
  (is (eq :previous (meta-command-verb (parse-meta-command "previous"))))
  (is (eq :help (meta-command-verb (parse-meta-command "help"))))
  (let ((mc (parse-meta-command "help()")))    ; also valid with empty parens
    (is (eq :help (meta-command-verb mc)))
    (is (null (meta-command-positionals mc)))))

(test parse-string-literal-untouched
  ;; a "..." literal keeps its content verbatim (never translated), quotes off.
  (let ((mc (parse-meta-command "input(t, \"hello world\")")))
    (is (eq :input (meta-command-verb mc)))
    (is (equal '((:target . "t") "hello world") (meta-command-positionals mc)))))

(test parse-keyword-value
  (let ((mc (parse-meta-command "dump(cad-view.entities, window: :all)")))
    (is (eq :all (cdr (assoc :window (meta-command-options mc)))))))

(test parse-malformed-signals
  (flet ((bad (s) (handler-case (progn (parse-meta-command s) :no-error)
                    (meta-command-parse-error () :err))))
    (is (eq :err (bad "dump(")))       ; unbalanced
    (is (eq :err (bad "()")))          ; missing verb
    (is (eq :err (bad "dump(x,)")))    ; trailing empty arg
    (is (eq :err (bad "")))            ; empty
    (is (eq :err (bad "zoom(v, window: (0 x))")))))  ; non-number tuple element
