(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;; --- Phase 12: headless interaction channel -----------------------

(defun cador-with-input (lines)
  "Build a MockHost with PROMPT-STREAM bound to a string-input
stream containing LINES (one per get* read)."
  (let ((mock (make-cador)))
    (setf (cador-prompt-stream mock)
          (make-string-input-stream
           (with-output-to-string (out)
             (dolist (line lines)
               (write-line line out)))))
    mock))

(test host-prompt-writes-to-prompt-output
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-prompt mock "Pick a point: ")
    (is (search "Pick a point: "
                (get-output-stream-string (cador-prompt-output mock))))))

(test host-getstring-reads-one-line
  (let ((mock (cador-with-input '("hello world"))))
    (let ((value (clautolisp.autolisp-host:host-getstring mock nil)))
      (is (typep value 'clautolisp.autolisp-runtime:autolisp-string))
      (is (string= "hello world"
                   (clautolisp.autolisp-runtime:autolisp-string-value value))))))

(test host-getstring-on-empty-input-returns-nil
  (let ((mock (make-cador)))
    (is (null (clautolisp.autolisp-host:host-getstring mock nil)))))

(test host-getint-parses-integer
  (let ((mock (cador-with-input '("42"))))
    (is (eql 42 (clautolisp.autolisp-host:host-getint mock nil)))))

(test host-getint-on-non-integer-returns-nil
  (let ((mock (cador-with-input '("abc"))))
    (is (null (clautolisp.autolisp-host:host-getint mock nil)))))

(test host-getreal-parses-double-float
  (let ((mock (cador-with-input '("3.25"))))
    (is (= 3.25d0 (clautolisp.autolisp-host:host-getreal mock nil)))))

(test host-getpoint-parses-2d-and-pads-z
  (let ((mock (cador-with-input '("1.0 2.0"))))
    (let ((p (clautolisp.autolisp-host:host-getpoint mock nil)))
      (is (= 3 (length p)))
      (is (= 1.0d0 (first p)))
      (is (= 2.0d0 (second p)))
      (is (= 0.0d0 (third p))))))

(test host-getpoint-parses-3d
  (let ((mock (cador-with-input '("1.0 2.0 3.0"))))
    (let ((p (clautolisp.autolisp-host:host-getpoint mock nil)))
      (is (equalp '(1.0d0 2.0d0 3.0d0) p)))))

(test host-getdist-parses-real
  (let ((mock (cador-with-input '("12.5"))))
    (is (= 12.5d0 (clautolisp.autolisp-host:host-getdist mock nil)))))

(test host-getangle-parses-radian-real
  ;; 0.5 round-trips losslessly through CL's reader; 1.5708 would
  ;; lose precision in the single-float -> double-float coerce.
  (let ((mock (cador-with-input '("0.5"))))
    (is (= 0.5d0 (clautolisp.autolisp-host:host-getangle mock nil)))))

(defun %angle= (mock expected)
  "Read an angle from MOCK's host-getangle and compare it to EXPECTED
radians within a small tolerance (single->double coercion of decimal
degrees is not bit-exact)."
  (let ((got (clautolisp.autolisp-host:host-getangle mock nil)))
    (and (numberp got) (< (abs (- got expected)) 1d-9))))

(test host-getangle-degrees-explicit-unit
  (is (%angle= (cador-with-input '("45 deg")) (/ pi 4)))
  (is (%angle= (cador-with-input '("45 degree")) (/ pi 4)))
  (is (%angle= (cador-with-input '("90 degrees")) (/ pi 2))))

(test host-getangle-degrees-decimal
  (is (%angle= (cador-with-input '("45.3321 deg"))
               (* 45.3321d0 (/ pi 180)))))

(test host-getangle-degrees-minutes-seconds
  ;; 43 deg 23 min 15 sec, markers ' (minute) and " (second). Order of
  ;; the minute/second markers is irrelevant to the sum.
  (let ((expected (* (+ 43 (/ 23 60) (/ 15 3600)) (/ pi 180))))
    (is (%angle= (cador-with-input '("43 deg 23' 15\"")) expected))
    (is (%angle= (cador-with-input '("43 deg 15\" 23'")) expected))))

(test host-getangle-radians-decimal
  (is (%angle= (cador-with-input '("2.34 rd")) 2.34d0)))

(test host-getangle-radians-pi-expressions
  (is (%angle= (cador-with-input '("pi rd")) pi))
  (is (%angle= (cador-with-input '("2pi rd")) (* 2 pi)))
  (is (%angle= (cador-with-input '("2 pi rd")) (* 2 pi)))
  (is (%angle= (cador-with-input '("4/3 pi rd")) (* 4/3 pi)))
  (is (%angle= (cador-with-input '("-3/2 pi rd")) (* -3/2 pi)))
  ;; pi with no explicit rd is still radians.
  (is (%angle= (cador-with-input '("pi")) pi)))

(test host-getangle-bare-number-is-radians
  ;; Back-compat: an un-united number is taken as radians.
  (is (%angle= (cador-with-input '("0.5")) 0.5d0)))

(test host-getangle-rejects-garbage
  (is (null (clautolisp.autolisp-host:host-getangle
             (cador-with-input '("banana")) nil))))

(test host-getorient-shares-the-angle-parser
  (is (%angle= (cador-with-input '("90 deg")) (/ pi 2)))
  (let ((got (clautolisp.autolisp-host:host-getorient
              (cador-with-input '("90 deg")) nil)))
    (is (and (numberp got) (< (abs (- got (/ pi 2))) 1d-9)))))

(test host-getkword-matches-keyword
  (let ((mock (cador-with-input '("Yes"))))
    (clautolisp.autolisp-host:host-initget mock 0 '("Yes" "No" "Maybe"))
    (let ((kw (clautolisp.autolisp-host:host-getkword mock nil)))
      (is (typep kw 'clautolisp.autolisp-runtime:autolisp-string))
      (is (string= "Yes"
                   (clautolisp.autolisp-runtime:autolisp-string-value kw))))))

(test host-getkword-rejects-non-keyword-input
  (let ((mock (cador-with-input '("Foo"))))
    (clautolisp.autolisp-host:host-initget mock 0 '("Yes" "No"))
    (is (null (clautolisp.autolisp-host:host-getkword mock nil)))))

(test host-getkword-without-initget-returns-line
  (let ((mock (cador-with-input '("anything"))))
    (let ((kw (clautolisp.autolisp-host:host-getkword mock nil)))
      (is (string= "anything"
                   (clautolisp.autolisp-runtime:autolisp-string-value kw))))))

(test initget-state-is-one-shot
  (let ((mock (cador-with-input '("first" "second"))))
    (clautolisp.autolisp-host:host-initget mock 0 '("OK" "Cancel"))
    ;; First call sees the initget keywords (and rejects "first").
    (is (null (clautolisp.autolisp-host:host-getkword mock nil)))
    ;; Second call: initget state already consumed; falls through to
    ;; "return whatever line".
    (let ((kw (clautolisp.autolisp-host:host-getkword mock nil)))
      (is (string= "second"
                   (clautolisp.autolisp-runtime:autolisp-string-value kw))))))

(test prompt-text-precedes-input-prompt
  (let ((mock (cador-with-input '("ok"))))
    (clautolisp.autolisp-host:host-getstring
     mock (clautolisp.autolisp-runtime:make-autolisp-string "Enter: "))
    (is (search "Enter: "
                (get-output-stream-string (cador-prompt-output mock))))))

;;; --- Interactive-input parking (cador-2 slice 3f) -----------------

(test prompt-input-status-classifies-string-streams-synchronously
  ;; The CI-determinism guard: a string-input-stream -- every scripted / batch /
  ;; --mock-input source -- classifies :ready or :eof and NEVER :would-block, so
  ;; a batch cador run never reaches the park branch. The peeked char is unread,
  ;; not lost.
  (let ((s (make-string-input-stream "hi")))
    (is (eq :ready (clautolisp.cador::%prompt-input-status s)))
    (is (eql #\h (read-char s)))
    (is (eql #\i (read-char s))))
  (let ((empty (make-string-input-stream "")))
    (is (eq :eof (clautolisp.cador::%prompt-input-status empty)))))

(test read-prompt-line-scripted-stream-stays-synchronous
  ;; A scripted host (no scheduler) reads exactly as before through the rewritten
  ;; read-prompt-line -- get-family values unchanged, no thread, no park.
  (let ((mock (cador-with-input '("hello" "42"))))
    (is (string= "hello"
                 (clautolisp.autolisp-runtime:autolisp-string-value
                  (clautolisp.autolisp-host:host-getstring mock nil))))
    (is (eql 42 (clautolisp.autolisp-host:host-getint mock nil)))))

(test cador-maybe-park-read-degrades-synchronously-without-scheduler
  ;; Off a context thread / with no scheduler on the active session, the bridge
  ;; just calls the reader and returns its value.
  (let ((mock (make-cador)))
    (is (equal "sync"
               (clautolisp.cador::%cador-maybe-park-read
                mock (lambda () "sync"))))))

(test cador-prompt-read-parks-via-bridge-and-resumes
  ;; End-to-end: a scheduler-backed context on its own thread reads through the
  ;; cador prompt bridge; the read yields to the driver (scheduler-park), which
  ;; supplies the value on its own thread and resumes the context -- proving
  ;; cador reaches the scheduler purely through the per-thread active context.
  (let* ((mock (make-cador))
         (session (make-runtime-session))
         (sched (make-document-scheduler))
         (ns (make-document-namespace :name "D"))
         (ctx (make-evaluation-context :session session
                                       :current-document ns
                                       :current-namespace ns))
         (x (make-scheduled-context :context ctx :document-key "D"))
         (results (make-park-mailbox)))
    (setf (document-namespace-host-document-key ns) "D")
    (setf (session-scheduler session) sched)
    (scheduler-register-context sched x)
    (scheduler-spawn-context sched x
      (lambda ()
        (park-mailbox-push results
                           (clautolisp.cador::%cador-maybe-park-read
                            mock (lambda () "canned-line")))))
    (unwind-protect
         (progn
           (scheduler-start sched x)
           (let ((note (scheduler-await-park sched 5)))
             (is (eq :park (first note)))
             (scheduler-serve-park sched note))
           (is (equal "canned-line" (park-mailbox-pop results 5))))
      (let ((th (scheduled-context-thread x)))
        (when (and th (bordeaux-threads:thread-alive-p th))
          (ignore-errors (park-mailbox-push (scheduled-context-mailbox x) :exit))
          (ignore-errors (bordeaux-threads:join-thread th)))))))
