;;;; FiveAM tests for the aldo settings / configuration core
;;;; (clautolisp.debug.ui settings, command reference §8).

(in-package #:clautolisp.ui.dumb.tests)

(in-suite dumb-ui-suite)

(defmacro with-fresh-config (&body body)
  "Run BODY with a fresh copy of the default configuration, isolated from the
global store."
  `(let ((clautolisp.debug.ui:*aldo-configuration*
           (copy-tree clautolisp.debug.ui:*default-aldo-configuration*)))
     ,@body))

(test settings-defaults
  (with-fresh-config
    (is (eq :sexp (clautolisp.debug.ui:get-aldo-setting :navigator)))
    (is (eql 1000 (clautolisp.debug.ui:get-aldo-setting :navigation-history-max)))
    (is (eql 24 (clautolisp.debug.ui:get-aldo-setting :pager-height)))
    (is (eq :unicode (clautolisp.debug.ui:get-aldo-setting :theme)))
    (is (eq :tui (clautolisp.debug.ui:get-aldo-setting :default-user-interface)))
    ;; case-insensitive key lookup
    (is (eq :sexp (clautolisp.debug.ui:get-aldo-setting "NAVIGATOR")))))

(test settings-config-set-get
  (with-fresh-config
    (clautolisp.debug.ui:config-set :pager-height 40)
    (is (eql 40 (clautolisp.debug.ui:get-aldo-setting :pager-height)))
    ;; a brand-new key is created
    (clautolisp.debug.ui:config-set :a-new-key 7)
    (is (eql 7 (clautolisp.debug.ui:config-get :a-new-key)))))

(test settings-set-enum
  (with-fresh-config
    ;; value is normalised to a keyword, case-insensitively
    (is (eq :line (clautolisp.debug.ui:set-aldo-setting "navigator" "line")))
    (is (eq :line (clautolisp.debug.ui:get-aldo-setting :navigator)))
    (is (eq :ascii (clautolisp.debug.ui:set-aldo-setting "THEME" "AsCiI")))
    (is (eq :ascii (clautolisp.debug.ui:get-aldo-setting :theme)))
    (is (eq :ncurses (clautolisp.debug.ui:set-aldo-setting "default-user-interface" "ncurses")))))

(test settings-set-scalar-types
  (with-fresh-config
    (is (eql 80 (clautolisp.debug.ui:set-aldo-setting "source-window-height" "80")))
    (is (eq t   (clautolisp.debug.ui:set-aldo-setting "break-on-caught" "on")))
    (is (eq nil (clautolisp.debug.ui:set-aldo-setting "break-on-caught" "off")))
    (is (eq :off (clautolisp.debug.ui:set-aldo-setting "pager" "off")))
    (is (eq :on  (clautolisp.debug.ui:set-aldo-setting "pager" "on")))
    ;; port: a number stays an integer, a service name stays a string
    (is (eql 4321 (clautolisp.debug.ui:set-aldo-setting "default-aldb-listening-port" "4321")))
    (is (string= "swank" (clautolisp.debug.ui:set-aldo-setting "default-aldb-listening-port" "swank")))
    ;; address is a string
    (is (string= "::1" (clautolisp.debug.ui:set-aldo-setting "default-aldb-listening-address" "::1")))))

(test settings-set-errors
  (with-fresh-config
    (fiveam:signals error (clautolisp.debug.ui:set-aldo-setting "no-such-setting" "x"))
    (fiveam:signals error (clautolisp.debug.ui:set-aldo-setting "navigator" "bogus"))
    (fiveam:signals error (clautolisp.debug.ui:set-aldo-setting "pager-height" "not-a-number"))))

(test settings-listing
  (with-fresh-config
    (clautolisp.debug.ui:set-aldo-setting "navigator" "line")
    (clautolisp.debug.ui:set-aldo-setting "pager" "off")
    (let ((lines (clautolisp.debug.ui:aldo-settings-lines)))
      (is (member "navigator = line" lines :test #'string=))
      (is (member "pager = off" lines :test #'string=))
      (is (member "theme = unicode" lines :test #'string=)))))

(test settings-xdg-paths
  ;; the save path ends in clautolisp/aldo.conf
  (let ((p (clautolisp.debug.ui:aldo-config-save-path)))
    (is (string= "aldo" (pathname-name p)))
    (is (string= "conf" (pathname-type p)))
    (is (equal '("clautolisp")
               (last (pathname-directory p)))))
  ;; xdg-config-dirs is a non-empty list of strings
  (is (every #'stringp (clautolisp.debug.ui:xdg-config-dirs))))

(test settings-save-load-roundtrip
  (let ((path (merge-pathnames "aldo-roundtrip-test.conf" (uiop:temporary-directory))))
    (unwind-protect
         (with-fresh-config
           (clautolisp.debug.ui:set-aldo-setting "navigator" "line")
           (clautolisp.debug.ui:set-aldo-setting "pager-height" "42")
           (clautolisp.debug.ui:set-aldo-setting "break-on-caught" "on")
           (clautolisp.debug.ui:save-aldo-configuration path)
           (is (probe-file path))
           ;; reset, then load back from the file
           (clautolisp.debug.ui:reset-aldo-configuration)
           (is (eq :sexp (clautolisp.debug.ui:get-aldo-setting :navigator))) ; back to default
           (clautolisp.debug.ui:load-aldo-configuration path)
           (is (eq :line (clautolisp.debug.ui:get-aldo-setting :navigator)))
           (is (eql 42 (clautolisp.debug.ui:get-aldo-setting :pager-height)))
           (is (eq t (clautolisp.debug.ui:get-aldo-setting :break-on-caught)))
           ;; the nested decorations survive the round trip (code points + strings)
           (let ((decos (clautolisp.debug.ui:config-get :decorations)))
             (is (consp decos))
             (is (member '(:current-pp :unicode (9205)) decos :test #'equal))
             (is (member '(:current-pp :ascii ">") decos :test #'equal))))
      (ignore-errors (delete-file path))
      (clautolisp.debug.ui:reset-aldo-configuration))))

(test dumb-ui-settings-commands
  ;; the TUI `,settings' / `set' commands drive the configuration core
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint
     ti frob (clautolisp.debug:find-form-id-at-line (first metas) 3) :when :before)
    (let ((clautolisp.debug.ui:*aldo-configuration*
            (copy-tree clautolisp.debug.ui:*default-aldo-configuration*)))
      (multiple-value-bind (result output)
          (run-ui (format nil ",settings~%set navigator line~%,settings navigator~%c~%")
                  :context context :thread-info ti
                  :thunk (lambda ()
                           (clautolisp.autolisp-runtime:autolisp-eval
                            (list (rt-sym "FROB") 7) context)))
        (declare (ignore result))
        (is (contains output "navigator = sexp"))  ; the initial ,settings listing
        (is (contains output "navigator = line"))  ; set echo + ,settings NAME
        (is (eq :line (clautolisp.debug.ui:get-aldo-setting :navigator)))))))

(test settings-conf-file-is-ascii-friendly
  ;; with code-point glyphs (the default), the saved file is pure ASCII and
  ;; uses bare lower-case symbols (no keywords, no raw Unicode)
  (let ((path (merge-pathnames "aldo-ascii-test.conf" (uiop:temporary-directory))))
    (unwind-protect
         (with-fresh-config
           (clautolisp.debug.ui:save-aldo-configuration path)
           (let ((text (uiop:read-file-string path)))
             (is (every (lambda (ch) (< (char-code ch) 128)) text)) ; pure ASCII
             (is (contains text "navigator"))
             (is (not (contains text ":navigator")))   ; bare symbol, not keyword
             (is (contains text "9205"))))             ; current-pp glyph as code point
      (ignore-errors (delete-file path))
      (clautolisp.debug.ui:reset-aldo-configuration))))

;;; --- display / undisplay (command reference §4) -------------------

(test dumb-ui-display-auto-prints-after-stop
  ;; a source with two compound statements, so step-over from line 3 lands on
  ;; the line-4 form (line 4 must be compound — an atom carries no poll point)
  (let* ((src (format nil "(defun id (a) a)~%(defun frob (x / z)~%  (setq z (id x))~%  (id x))"))
         (context (fresh-context))
         (metas (load-and-instrument context src "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint
     ti frob (clautolisp.debug:find-form-id-at-line (first metas) 3) :when :before)
    (multiple-value-bind (result output)
        ;; register a display, then step: the step's stop re-prints it
        (run-ui (format nil "display X~%n~%c~%") :context context :thread-info ti
                :thunk (lambda ()
                         (clautolisp.autolisp-runtime:autolisp-eval
                          (list (rt-sym "FROB") 7) context)))
      (declare (ignore result))
      (is (contains output "display 1: X"))     ; registration echo
      (is (contains output "display 1: X = 7")))))  ; auto-printed at the step stop

(test dumb-ui-undisplay-removes
  (let* ((ui (clautolisp.ui.dumb:make-dumb-ui
              :input (make-string-input-stream "") :output (make-string-output-stream))))
    (clautolisp.ui.dumb::display-cmd ui "X")
    (clautolisp.ui.dumb::display-cmd ui "Y")
    (is (equal '("X" "Y") (clautolisp.ui.dumb::dumb-ui-displays ui)))
    (clautolisp.ui.dumb::undisplay-cmd ui "1")
    (is (equal '("Y") (clautolisp.ui.dumb::dumb-ui-displays ui)))
    (clautolisp.ui.dumb::undisplay-cmd ui nil)   ; all
    (is (null (clautolisp.ui.dumb::dumb-ui-displays ui)))))

(test dumb-ui-type-command
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint
     ti frob (clautolisp.debug:find-form-id-at-line (first metas) 3) :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "type X~%c~%") :context context :thread-info ti
                :thunk (lambda ()
                         (clautolisp.autolisp-runtime:autolisp-eval
                          (list (rt-sym "FROB") 7) context)))
      (declare (ignore result))
      ;; X is the integer 7 -> AutoLISP type INT
      (is (contains output "INT")))))

(test settings-decoration-glyph-per-theme
  ;; The enabled-breakpoint decoration is ⏸ (U+23F8) under the unicode theme and
  ;; ^ under the ascii theme (TUI spec decoration table).
  (with-fresh-config
    (is (string= (string (code-char 9208))
                 (clautolisp.debug.ui:aldo-decoration-glyph :enabled-bp)))   ; ⏸
    (is (string= (string (code-char 9205))
                 (clautolisp.debug.ui:aldo-decoration-glyph :current-pp)))   ; ⏵
    (clautolisp.debug.ui:set-aldo-setting "theme" "ascii")
    (is (string= "^" (clautolisp.debug.ui:aldo-decoration-glyph :enabled-bp)))
    (is (string= "_" (clautolisp.debug.ui:aldo-decoration-glyph :disabled-bp)))))

;;;; ---------------------------------------------------------------------------
;;;; The LISP-interactor configuration and the aldo-over-lisp stacking
;;;; (lisp-configuration.issue).

(defmacro with-empty-layers (&body body)
  "Run BODY with both configuration layers empty — i.e. nothing explicitly
set, everything resolving from the built-in defaults."
  `(let ((clautolisp.debug.ui:*aldo-configuration* nil)
         (clautolisp.debug.ui:*lisp-configuration* nil))
     ,@body))

(test lisp-config-defaults-resolve-from-empty-layers
  ;; The layers hold only explicit settings, so an empty store must still
  ;; answer with the built-in default rather than NIL. This is what every
  ;; existing reader depends on.
  (with-empty-layers
    (is (eq :ask (clautolisp.debug.ui:lisp-setting :sedit-on-quit)))
    (is (eq :ask (clautolisp.debug.ui:debugger-setting :sedit-on-quit)))
    ;; an aldo-only key still resolves at DBG> through the same fallback
    (is (eql 24 (clautolisp.debug.ui:debugger-setting :pager-height)))))

(test lisp-config-explicit-is-distinguishable-from-default
  ;; The whole feature rests on this: "present in the conf" must be
  ;; distinguishable from "equal to the built-in default", or the debugger
  ;; could never fall through to the lisp layer.
  (with-empty-layers
    (is (null (nth-value 1 (clautolisp.debug.ui:config-explicit
                            :sedit-on-quit
                            clautolisp.debug.ui:*aldo-configuration*))))
    (clautolisp.debug.ui:set-aldo-setting "sedit-on-quit" "ask")
    ;; same VALUE as the default, but now explicitly set
    (is (eq t (nth-value 1 (clautolisp.debug.ui:config-explicit
                            :sedit-on-quit
                            clautolisp.debug.ui:*aldo-configuration*))))))

(test lisp-config-debugger-falls-through-to-lisp-layer
  ;; Set ONLY at the REPL: the debugger must pick it up, since aldo.conf says
  ;; nothing about it.
  (with-empty-layers
    (clautolisp.debug.ui:set-lisp-setting "sedit-on-quit" "auto-save")
    (is (eq :auto-save (clautolisp.debug.ui:lisp-setting :sedit-on-quit)))
    (is (eq :auto-save (clautolisp.debug.ui:debugger-setting :sedit-on-quit)))))

(test lisp-config-aldo-shadows-lisp-and-writes-stay-on-their-layer
  (with-empty-layers
    (clautolisp.debug.ui:set-lisp-setting "sedit-on-quit" "auto-save")
    (clautolisp.debug.ui:set-aldo-setting "sedit-on-quit" "do-not-save")
    ;; aldo over lisp inside the debugger...
    (is (eq :do-not-save (clautolisp.debug.ui:debugger-setting :sedit-on-quit)))
    ;; ...while the REPL keeps its own: a write goes to the ACTIVE layer only
    (is (eq :auto-save (clautolisp.debug.ui:lisp-setting :sedit-on-quit)))
    ;; dropping the aldo layer re-exposes the lisp one
    (let ((clautolisp.debug.ui:*aldo-configuration* nil))
      (is (eq :auto-save (clautolisp.debug.ui:debugger-setting :sedit-on-quit))))))

(defun %errors-p (thunk)
  "True when THUNK signals. This package :USEs only CL and imports FiveAM
name by name, so SIGNALS / IS-TRUE / IS-FALSE are NOT available here even
though IS is — and a missing import shows up as an unbound-variable at run
time, not as a compile error."
  (handler-case (progn (funcall thunk) nil)
    (error () t)))

(test lisp-config-set-validates-like-aldo
  (with-empty-layers
    (is (%errors-p (lambda ()
                     (clautolisp.debug.ui:set-lisp-setting "sedit-on-quit" "banana"))))
    (is (%errors-p (lambda ()
                     (clautolisp.debug.ui:set-lisp-setting "no-such-key" "1"))))
    ;; keys are case-insensitive, like aldo's
    (clautolisp.debug.ui:set-lisp-setting "SEDIT-ON-QUIT" "do-not-save")
    (is (eq :do-not-save (clautolisp.debug.ui:lisp-setting :sedit-on-quit)))))

(test lisp-config-settings-lines-mark-defaults
  (with-empty-layers
    (let ((lines (clautolisp.debug.ui:lisp-settings-lines)))
      (is (= 1 (length lines)))
      (is (search "(default)" (first lines))))
    (clautolisp.debug.ui:set-lisp-setting "sedit-on-quit" "auto-save")
    (let ((lines (clautolisp.debug.ui:lisp-settings-lines)))
      (is (search "auto-save" (first lines)))
      (is (null (search "(default)" (first lines)))))))

(test lisp-config-file-round-trip
  (with-empty-layers
    (uiop:with-temporary-file (:pathname path :type "conf" :keep nil)
      (clautolisp.debug.ui:set-lisp-setting "sedit-on-quit" "do-not-save")
      (clautolisp.debug.ui:save-lisp-configuration path)
      (let ((clautolisp.debug.ui:*lisp-configuration* nil))
        (is (eq :ask (clautolisp.debug.ui:lisp-setting :sedit-on-quit)))
        (clautolisp.debug.ui:load-lisp-configuration path)
        (is (eq :do-not-save (clautolisp.debug.ui:lisp-setting :sedit-on-quit)))))))

(test lisp-config-save-writes-only-explicit-settings
  ;; The visible consequence of holding explicit settings only: a conf file is
  ;; a diff against the defaults, not a full dump.
  (with-empty-layers
    (clautolisp.debug.ui:set-aldo-setting "pager-height" "40")
    (let ((written (with-output-to-string (out)
                     (clautolisp.debug.ui:write-aldo-configuration out))))
      (is (search "pager-height" written))
      (is (null (search "navigator" written))))))
