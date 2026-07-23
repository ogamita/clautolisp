;;;; clautolisp/tools/clautolisp/tests/debugger-options-tests.lisp
;;;;
;;;; CLI parse tests for the debugger (aldo) options of
;;;; issues/open/debugger-public-interface-and-on-error.issue Parts B-D:
;;;;   --on-error / --on-interrupt / --on-quit POLICY
;;;;   --debugger-ui UI
;;;;   --aldb-listen [HOST:]PORT / --aldb-stdio
;;;; including value validation (cli-usage-error on a typo), the
;;;; --aldb-stdio exclusivity rules, and the aldb-channel implication on
;;;; the effective UI.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(defun %parse (&rest arguments)
  (clautolisp.tools.clautolisp::parse-arguments arguments))

;;; --- the --on-<event> policies ------------------------------------

(test on-event-policies-default-to-nil
  "With no --on-* option the slots stay NIL: the tool applies its
context-dependent defaults downstream (interactive REPL: on-error debug;
batch: on-error quit; on-interrupt debug; on-quit quit)."
  (let ((options (%parse "-x" "(+ 1 2)")))
    (is (null (clautolisp.autolisp-cli:cli-options-on-error options)))
    (is (null (clautolisp.autolisp-cli:cli-options-on-interrupt options)))
    (is (null (clautolisp.autolisp-cli:cli-options-on-quit options)))))

(test on-error-policy-values
  (is (eq :quit   (clautolisp.autolisp-cli:cli-options-on-error
                   (%parse "--on-error" "quit"))))
  (is (eq :debug  (clautolisp.autolisp-cli:cli-options-on-error
                   (%parse "--on-error" "DEBUG"))))
  (is (eq :ignore (clautolisp.autolisp-cli:cli-options-on-error
                   (%parse "--on-error" "ignore"))))
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--on-error" "abort")))

(test on-interrupt-policy-values
  (is (eq :debug  (clautolisp.autolisp-cli:cli-options-on-interrupt
                   (%parse "--on-interrupt" "debug"))))
  (is (eq :ignore (clautolisp.autolisp-cli:cli-options-on-interrupt
                   (%parse "--on-interrupt" "ignore"))))
  (is (eq :quit   (clautolisp.autolisp-cli:cli-options-on-interrupt
                   (%parse "--on-interrupt" "quit"))))
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--on-interrupt" "resume")))

(test on-quit-policy-values
  "The QUIT event cannot be ignored: only debug and quit are accepted."
  (is (eq :debug (clautolisp.autolisp-cli:cli-options-on-quit
                  (%parse "--on-quit" "debug"))))
  (is (eq :quit  (clautolisp.autolisp-cli:cli-options-on-quit
                  (%parse "--on-quit" "quit"))))
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--on-quit" "ignore")))

;;; --- --debugger-ui ------------------------------------------------

(test debugger-ui-values
  (is (eq :tui     (clautolisp.autolisp-cli:cli-options-user-interface
                    (%parse "--debugger-ui" "tui"))))
  (is (eq :tui     (clautolisp.autolisp-cli:cli-options-user-interface
                    (%parse "--debugger-ui" "terminal"))))
  (is (eq :ncurses (clautolisp.autolisp-cli:cli-options-user-interface
                    (%parse "--debugger-ui" "ncurses"))))
  (is (eq :aldb    (clautolisp.autolisp-cli:cli-options-user-interface
                    (%parse "--debugger-ui" "aldb"))))
  (is (eq :aldb    (clautolisp.autolisp-cli:cli-options-user-interface
                    (%parse "--debugger-ui" "emacs"))))
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--debugger-ui" "gtk")))

(test old-debugger-option-spellings-are-gone
  "The pre-issue spellings are NOT kept as aliases (CLI convention: no
legacy aliases). They now fail as unknown options."
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--aldo-user-interface" "tui"))
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--aldb-listening-address" "127.0.0.1"))
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--aldb-listening-port" "4301")))

;;; --- --aldb-listen / --aldb-stdio ---------------------------------

(test aldb-listen-bare-port
  (let ((options (%parse "--aldb-listen" "4301")))
    (is (null (clautolisp.autolisp-cli:cli-options-aldb-address options)))
    (is (eql 4301 (clautolisp.autolisp-cli:cli-options-aldb-port options)))))

(test aldb-listen-host-and-port
  (let ((options (%parse "--aldb-listen" "localhost:4301")))
    (is (equal "localhost"
               (clautolisp.autolisp-cli:cli-options-aldb-address options)))
    (is (eql 4301 (clautolisp.autolisp-cli:cli-options-aldb-port options)))))

(test aldb-listen-bracketed-ipv6
  (let ((options (%parse "--aldb-listen" "[::1]:4301")))
    (is (equal "::1"
               (clautolisp.autolisp-cli:cli-options-aldb-address options)))
    (is (eql 4301 (clautolisp.autolisp-cli:cli-options-aldb-port options)))))

(test aldb-listen-service-name-port
  (let ((options (%parse "--aldb-listen" "127.0.0.1:aldb")))
    (is (equal "127.0.0.1"
               (clautolisp.autolisp-cli:cli-options-aldb-address options)))
    (is (equal "aldb" (clautolisp.autolisp-cli:cli-options-aldb-port options)))))

(test aldb-listen-port-zero-means-pick-a-free-port
  (is (eql 0 (clautolisp.autolisp-cli:cli-options-aldb-port
              (%parse "--aldb-listen" "0")))))

(test aldb-listen-bad-values
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--aldb-listen" ":4301"))          ; empty host
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--aldb-listen" "localhost:"))     ; empty port
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--aldb-listen" "localhost:70000"))) ; port out of range

(test aldb-stdio-flag
  (is (eq t (clautolisp.autolisp-cli:cli-options-aldb-stdio-p
             (%parse "--aldb-stdio" "-l" "program.lsp")))))

(test aldb-stdio-exclusive-with-interactive
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--aldb-stdio" "--interactive")))

(test aldb-stdio-exclusive-with-aldb-listen
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%parse "--aldb-stdio" "--aldb-listen" "4301")))

;;; --- the aldb-channel implication on the effective UI -------------

(test aldb-channel-implies-aldb-ui
  (is (eq :aldb (clautolisp.tools.clautolisp::effective-user-interface
                 (%parse "--aldb-listen" "4301"))))
  (is (eq :aldb (clautolisp.tools.clautolisp::effective-user-interface
                 (%parse "--aldb-stdio")))))

(test explicit-debugger-ui-wins-over-the-implication
  (is (eq :ncurses (clautolisp.tools.clautolisp::effective-user-interface
                    (%parse "--aldb-listen" "4301"
                            "--debugger-ui" "ncurses")))))

(test no-debugger-option-means-no-ui-request
  (is (null (clautolisp.tools.clautolisp::effective-user-interface
             (%parse "-x" "(+ 1 2)")))))
