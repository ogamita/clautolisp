;;;; clautolisp/autolisp-debug-ui-dumb/tests/dumb-ui-tests.lisp

(in-package #:clautolisp.ui.dumb.tests)

(in-suite dumb-ui-suite)

(test continue-resumes-and-reports-hit
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti frob (clautolisp.debug:find-form-id-at-line (first metas) 3)
                                     :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      (is (eql 7 result))
      (is (contains output "Hit breakpoint"))
      (is (contains output "FROB"))
      (is (contains output "X = 7")))))     ; visible binding printed

(test source-listing-marks-current-line
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    ;; write the source file so lines-of can read it
    (with-open-file (out "frob.lsp" :direction :output :if-exists :supersede)
      (write-string +frob-source+ out))
    (unwind-protect
         (progn
           (clautolisp.debug:add-breakpoint
            ti frob (clautolisp.debug:find-form-id-at-line (first metas) 3) :when :before)
           (multiple-value-bind (result output)
               (run-ui (format nil "ls~%c~%") :context context :thread-info ti
                       :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                          (list (rt-sym "FROB") 7) context)))
             (declare (ignore result))
             (is (contains output ">>"))         ; current-line marker
             (is (contains output "(setq z (id x))"))))
      (ignore-errors (delete-file "frob.lsp")))))

(defparameter +two-source+
  ;; two compound statements so step-over has a next statement to land on:
  ;; 1: (defun id (a) a)
  ;; 2: (defun two (x / z)
  ;; 3:   (setq z (id x))    form 1 = setq, form 2 = (id x)
  ;; 4:   (id z))            form 3 = (id z)
  (format nil "(defun id (a) a)~%(defun two (x / z)~%  (setq z (id x))~%  (id z))"))

(test step-over-advances-statement
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    ;; break at the setq statement (form-id 1); 's' (step over the (id x)
    ;; call) then 'c'. Step over must land on the next statement (id z).
    (clautolisp.debug:add-breakpoint ti two 1 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "n~%c~%") :context context :thread-info ti
                :thunk (lambda ()
                         (clautolisp.autolisp-runtime:autolisp-eval
                          (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      ;; two stops shown: the breakpoint then the step
      (is (contains output "Hit breakpoint"))
      (is (contains output "Step")))))

(test eval-command-prints-variable
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti frob (clautolisp.debug:find-form-id-at-line (first metas) 3)
                                     :when :before)
    ;; 'e X' evaluates X in-frame (= 7), prints it, then continue
    (multiple-value-bind (result output)
        (run-ui (format nil "p X~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      (is (eql 7 result))
      (is (contains output (format nil "DBG> 7"))))))

(test eval-paren-form-prints-value
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti frob (clautolisp.debug:find-form-id-at-line (first metas) 3)
                                     :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "(setq x 99)~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      ;; (setq x 99) in-frame, then continue: frob returns z = (id x) = 99
      (is (eql 99 result))
      (is (contains output "99")))))

(test set-breakpoint-by-line-command
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    ;; break at TWO entry; 'B 4' sets a breakpoint at line 4 = (id z) (a
    ;; compound form with a poll point), then 'c' hits it, 'c' finishes.
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "b 4~%c~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "breakpoint pp"))     ; confirmation of the set (pp number)
      (is (contains output "set at line 4"))
      ;; the by-line breakpoint actually fired: a hit reported at line 4
      (is (contains output "line 4")))))

(test abort-from-error-stop
  (let* ((context (fresh-context))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (load-and-instrument context "(defun boom () (nosuchfn 1))" "BOOM")
    (multiple-value-bind (result output)
        (run-ui (format nil "q~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "BOOM")) context)))
      (is (eq :aborted result))
      (is (contains output "Error")))))

(test return-value-from-error-stop
  (let* ((context (fresh-context))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (load-and-instrument context "(defun boom () (nosuchfn 1))" "BOOM")
    (multiple-value-bind (result output)
        (run-ui (format nil "r 42~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "BOOM")) context)))
      (declare (ignore output))
      (is (eql 42 result)))))

(test inspector-navigation-and-path
  (let* ((context (fresh-context))
         (metas (load-and-instrument context
                                     (format nil "(defun id (a) a)~%(defun frob (x / z)~%  (setq z (id x))~%  z)")
                                     "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.autolisp-runtime:set-variable
     (rt-sym "L") (first (clautolisp.autolisp-runtime:read-runtime-from-string "(10 20)")) context)
    (clautolisp.debug:add-breakpoint ti frob (clautolisp.debug:find-form-id-at-line (first metas) 3) :when :before)
    (multiple-value-bind (result output)
        ;; x L : inspect global L; d 0 : descend into car; p : path; q ; c
        (run-ui (format nil "v L~%d 0~%p~%q~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      (declare (ignore result))
      (is (contains output "INSPECT>"))
      (is (contains output "car"))
      (is (contains output "(CAR L)")))))      ; composed path expression

(test help-and-unknown-command
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti frob 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "h~%zzz~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      (declare (ignore result))
      (is (contains output "commands:"))
      (is (contains output "unknown command")))))

(test eof-on-input-continues
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti frob 0 :when :before)
    ;; empty input → EOF at the prompt → continue (CI/pipe safety, §18)
    (multiple-value-bind (result output)
        (run-ui "" :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      (declare (ignore output))
      (is (eql 7 result)))))

;;; --- small helper --------------------------------------------------

(defun count-substring (string sub)
  (loop with len = (length sub)
        for start = 0 then (+ pos len)
        for pos = (search sub string :start2 start)
        while pos count 1))

(test dumb-ui-frame-and-list-commands
  ;; §0 vocabulary: lf (list frames), f/fi/fo/ft/fb (frame nav), ll/lp/lv
  (let* ((src (format nil "(defun id (a) a)~%(defun frob (x / z)~%  (setq z (id x))~%  (id x))"))
         (context (fresh-context))
         (metas (load-and-instrument context src "FROB" "ID"))
         (id-fid (fid-of (second metas)))   ; metas in name order: FROB, ID
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti id-fid 0 :when :before)  ; break at ID entry
    (multiple-value-bind (result output)
        (run-ui (format nil "lf~%fo~%lv~%fi~%c~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      (declare (ignore result))
      (is (contains output "ID"))        ; lf lists the ID frame
      (is (contains output "FROB"))      ; ... and the caller FROB frame
      (is (contains output "frame")))))  ; fo/fi report the selected frame

(test dumb-ui-advance-command
  ;; §1 advance: from TWO entry, `a 4' runs to the poll point on line 4 (id z)
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; break at TWO entry
    (multiple-value-bind (result output)
        (run-ui (format nil "a 4~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "line 4")))))   ; advanced to line 4

(test dumb-ui-delete-breakpoint
  ;; set a line-4 breakpoint, delete all, re-list (empty)
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; break at TWO entry
    (multiple-value-bind (result output)
        (run-ui (format nil "b 4~%delete~%lb~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "deleted all breakpoints"))
      (is (contains output "no breakpoints")))))   ; lb after delete-all is empty

(test breakpoint-enable-disable-firing
  ;; engine: a disabled breakpoint stays in the table but does not fire (§2)
  (let* ((ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (bp (clautolisp.debug:add-breakpoint ti 5 2 :when :before)))
    (is (clautolisp.debug:find-active-breakpoint ti 5 2 :before))      ; fires
    (clautolisp.debug:set-breakpoint-enabled bp nil)
    (is (null (clautolisp.debug:find-active-breakpoint ti 5 2 :before))) ; disabled
    (clautolisp.debug:set-breakpoint-enabled bp t)
    (is (clautolisp.debug:find-active-breakpoint ti 5 2 :before))))    ; re-enabled

(test dumb-ui-disable-enable-commands
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; break at TWO entry
    (multiple-value-bind (result output)
        (run-ui (format nil "disable~%lb~%enable~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "disabled all breakpoints"))
      (is (contains output "(disabled)"))           ; lb shows the disabled state
      (is (contains output "enabled all breakpoints")))))

(test poll-point-id-registry
  ;; globally-stable poll-point ids: id <-> (fid, form-id) round-trips, stable,
  ;; unique across poll points (command reference §2 / DN-11)
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (id-fid (fid-of (second metas)))
         (pp (clautolisp.debug:poll-point-id two 0)))
    (is (integerp pp))
    (is (equal (list two 0)
               (multiple-value-list (clautolisp.debug:poll-point-location pp))))
    (is (= pp (clautolisp.debug:poll-point-id two 0)))        ; stable
    (is (/= pp (clautolisp.debug:poll-point-id id-fid 0)))    ; unique per poll point
    (is (null (clautolisp.debug:poll-point-location 999999)))))  ; unknown id → NIL

(test dumb-ui-break-by-pp-and-list-shows-pp
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (pp (clautolisp.debug:poll-point-id
              two (clautolisp.debug:find-form-id-at-line (first metas) 4))))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; stop at entry
    (multiple-value-bind (result output)
        (run-ui (format nil "b pp~D~%lb~%c~%" pp) :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (declare (ignore result))
      (is (contains output (format nil "breakpoint pp~D set" pp)))  ; break ppN
      (is (contains output (format nil "pp~D" pp))))))              ; lb shows pp

(test dumb-ui-condition-and-ignore
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (pp (clautolisp.debug:poll-point-id
              two (clautolisp.debug:find-form-id-at-line (first metas) 4))))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)
    (multiple-value-bind (result output)
        ;; set a line-4 bp, attach a condition, then an ignore count, then run
        (run-ui (format nil "b 4~%condition ~D (id 1)~%ignore ~D 2~%c~%" pp pp)
                :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (declare (ignore result))
      (is (contains output (format nil "breakpoint pp~D condition set" pp)))
      (is (contains output (format nil "breakpoint pp~D will ignore the next 2 hit" pp))))))

(test dumb-ui-list-polls-numbers-poll-points
  ;; `list polls' lists the current function's poll points with their numbers,
  ;; lines, and breakpoint status (TUI Numbered Poll-Points)
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (pp4 (clautolisp.debug:poll-point-id
               two (clautolisp.debug:find-form-id-at-line (first metas) 4))))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; stop at entry
    (multiple-value-bind (result output)
        (run-ui (format nil "b 4~%list polls~%c~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (declare (ignore result))
      (is (contains output (format nil "pp~D  line 4" pp4)))  ; pp number + line
      (is (contains output "*breakpoint")))))                 ; the line-4 bp marked

(test dumb-ui-nav-sub-mode
  ;; `nav' opens a structural-navigation sub-mode over the current function's
  ;; reconstructed (defun …) form; d/>/q move and leave
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint
     ti frob (clautolisp.debug:find-form-id-at-line (first metas) 3) :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "nav~%d~%>~%q~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      (is (eql 7 result))
      (is (contains output "NAV"))          ; entered the nav sub-mode
      (is (contains output "DEFUN"))        ; reconstructed source form shown
      (is (contains output "【")))))         ; selection bracket

(test dumb-ui-break-once
  ;; `break once' / `bo' set a volatile breakpoint (removed on first hit)
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; stop at entry
    (multiple-value-bind (result output)
        (run-ui (format nil "break once 4~%lb~%c~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "(once)"))            ; lb shows it is volatile
      (is (contains output "set at line 4")))))

(test dumb-ui-apropos
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti frob 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "apropos frame~%apropos nosuchword~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      (declare (ignore result))
      (is (contains output "list frames"))           ; matched line(s)
      (is (contains output "no command matching")))))  ; the miss

(test dumb-ui-bpcmd-runs-then-stops
  ;; `bpcmd ppN FORM' evaluates FORM when the breakpoint hits, shows it, and
  ;; then STOPS as usual (command reference §2). Distinct from `trace'.
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (pp4 (clautolisp.debug:poll-point-id
               two (clautolisp.debug:find-form-id-at-line (first metas) 4))))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; stop at entry
    (multiple-value-bind (result output)
        ;; bp at line 4, attach a command, continue (hits 4 → prints → stops), continue
        (run-ui (format nil "b 4~%bpcmd ~D (id 1)~%lb~%c~%c~%" pp4)
                :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output (format nil "breakpoint pp~D command set" pp4)))
      (is (contains output "(bpcmd)"))                        ; lb annotation
      (is (contains output (format nil "pp~D: 1" pp4))))))     ; FORM ran, then stopped

(test dumb-ui-trace-then-continues
  ;; `trace FN' prints a trace line each time FN is entered and continues
  ;; transparently (command reference §6.4): TWO calls ID twice.
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; stop at entry
    (multiple-value-bind (result output)
        (run-ui (format nil "trace ID~%lb~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))                              ; ran to completion (no stop at ID)
      (is (contains output "tracing ID"))
      (is (contains output "(traced)"))                ; lb annotation
      (is (contains output "TRACE> ID")))))            ; the trace line fired

(test dumb-ui-rbreak-sets-breakpoints-by-wildcard
  ;; `rbreak PATTERN' sets an entry breakpoint on every instrumented function
  ;; whose name matches the wcmatch wildcard (command reference §2).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (id  (fid-of (second metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; stop at TWO entry
    (multiple-value-bind (result output)
        ;; match only ID (not TWO); lb should then show an entry bp on ID's fid.
        ;; ID is entered twice, so two further continues follow.
        (run-ui (format nil "rbreak ID~%lb~%c~%c~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "rbreak: 1 breakpoint set: ID"))
      (is (contains output (format nil "fid ~D form 0" id))))))  ; bp landed on ID entry

(test dumb-ui-catch-toggles-error-policy
  ;; `catch error|caught on|off' toggles what stops execution and reports the
  ;; policy (command reference §2).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti frob 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "catch caught on~%catch error off~%catch~%c~%")
                :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      (is (eql 7 result))
      ;; the final bare `catch' reports the toggled policy
      (is (contains output "error off"))
      (is (contains output "caught on")))))

(test dumb-ui-nav-line-mode
  ;; the `navigator line' setting makes `nav' walk poll-point lines flatly
  ;; instead of the sexp tree (command reference §8); d advances to the next.
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (clautolisp.debug.ui:*aldo-configuration*
           (let ((c (copy-tree clautolisp.debug.ui:*default-aldo-configuration*)))
             (setf (cdr (assoc :navigator c)) :line)
             c)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "nav~%d~%q~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "NAV(line"))       ; entered line mode
      (is (contains output "line 3"))         ; first poll-point line
      (is (contains output "line 4")))))      ; d advanced to the next

(test dumb-ui-value-line-width-setting-applied
  ;; the `value-line-width' setting governs single-line value previews
  ;; (command reference §8); set it small and a long value is truncated.
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (clautolisp.debug.ui:*aldo-configuration*
           (copy-tree clautolisp.debug.ui:*default-aldo-configuration*)))
    (clautolisp.debug:add-breakpoint ti frob 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "set value-line-width 8~%p \"abcdefghijklmnopqrstuvwxyz\"~%c~%")
                :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "FROB") 7) context)))
      (declare (ignore result))
      (is (contains output "…")))))            ; truncated at the configured width

(test dumb-ui-break-on-caught-setting-applied
  ;; the `break-on-caught' setting takes effect at session start: it seeds
  ;; *break-on-caught-error* (command reference §8).
  (let* ((context (fresh-context))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (captured :unset)
         (clautolisp.debug.ui:*aldo-configuration*
           (let ((c (copy-tree clautolisp.debug.ui:*default-aldo-configuration*)))
             (setf (cdr (assoc :break-on-caught c)) t)
             c)))
    (run-ui "" :context context :thread-info ti
            :thunk (lambda () (setf captured clautolisp.debug:*break-on-caught-error*)))
    (is (eq t captured))))

(test dumb-ui-return-at-normal-stop-supplies-value
  ;; `return VALUE' at a NORMAL (non-error) breakpoint stop makes the innermost
  ;; instrumented form return VALUE (command reference §1 return / spec §10.1).
  ;; Regression: apply-resume-directive used to drop :continue-with-return at a
  ;; normal stop. Break at TWO's entry, return 99 → TWO yields 99 (not 7).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; entry stop
    (multiple-value-bind (result output)
        (run-ui (format nil "r 99~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (declare (ignore output))
      (is (eql 99 result)))))           ; the returned value replaced the body

(test dumb-ui-browse-goto-definition-history-back
  ;; the source-browse stack (command reference §3): goto/definition push a
  ;; (name . position), history lists it, back pops — none of which touch
  ;; execution (TWO still returns 7).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "goto ID~%definition TWO~%history~%back~%goto NOPE~%c~%")
                :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))                                  ; browsing did not move execution
      (is (contains output "ID:"))                         ; goto displayed ID
      (is (contains output "TWO:"))                        ; definition displayed TWO
      (is (contains output "0: TWO"))                      ; history, innermost first
      (is (contains output "back to ID"))                  ; back popped to ID
      (is (contains output "no instrumented function named NOPE")))))

(test dumb-ui-search-lists-matching-functions
  ;; `search PATTERN' lists instrumented functions whose name matches the
  ;; wildcard (command reference §3, name search v1).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "search *~%search z*~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (declare (ignore result))
      (is (contains output "ID"))                          ; * matches both
      (is (contains output "TWO"))
      (is (contains output "no function name matches z*")))))  ; the miss

(test dumb-ui-jump-skips-intervening-forms
  ;; `jump 4' from the setq (line 3) resumes at (id z) (line 4) WITHOUT running
  ;; the setq, so z is never assigned and TWO returns nil instead of 7 — the
  ;; defining property of jump vs advance (command reference §1).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (setq-form (clautolisp.debug:find-form-id-at-line (first metas) 3)))
    (clautolisp.debug:add-breakpoint ti two setq-form :when :before)  ; stop at the setq
    (multiple-value-bind (result output)
        (run-ui (format nil "jump 4~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (contains output "jumping to"))
      (is (not (eql 7 result))))))    ; the setq was skipped (would have given 7)

(test dumb-ui-jump-backward-rejected
  ;; v1 supports forward jumps only; a backward target is rejected and execution
  ;; is unaffected (TWO still returns 7).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (idz-form (clautolisp.debug:find-form-id-at-line (first metas) 4)))
    (clautolisp.debug:add-breakpoint ti two idz-form :when :before)  ; stop at (id z), z already set
    (multiple-value-bind (result output)
        (run-ui (format nil "jump 3~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "backward jump not supported")))))

(test dumb-ui-watch-stops-on-change
  ;; `watch VAR' stops when the variable's value changes (a software
  ;; watchpoint; command reference §2). In TWO, z goes nil → 7 via the setq.
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)  ; stop at entry
    (multiple-value-bind (result output)
        (run-ui (format nil "watch z~%c~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "watching"))
      (is (contains output "Watchpoint"))
      (is (contains output "changed"))
      (is (contains output "7")))))               ; the new value reported

(test dumb-ui-watch-predicate-edge
  ;; `watch VAR FORM' stops when FORM first becomes true. `watch z z' stops the
  ;; moment z becomes non-nil (no arithmetic builtin needed).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "watch z z~%c~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "when"))                ; reported as a predicated watch
      (is (contains output "Watchpoint")))))

(test dumb-ui-unwatch-removes-watch
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "watch z~%unwatch z~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "unwatched z"))
      (is (not (contains output "Watchpoint"))))))  ; watch gone, never fired

(test dumb-ui-untrace-removes-tracepoint
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti two 0 :when :before)
    (multiple-value-bind (result output)
        (run-ui (format nil "trace ID~%untrace ID~%c~%") :context context :thread-info ti
                :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                   (list (rt-sym "TWO") 7) context)))
      (is (eql 7 result))
      (is (contains output "untraced ID"))
      (is (not (contains output "TRACE> ID"))))))      ; tracepoint gone, never fired
