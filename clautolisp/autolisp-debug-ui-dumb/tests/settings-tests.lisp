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
