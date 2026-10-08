;;;; console-flood-probe.lsp -- does a long, chatty CAD session complete?
;;;; (issues/open/alfe-accoreconsole-console-pipe-not-drained)
;;;;
;;;; alfe used to start accoreconsole with its console on PIPES that nothing
;;;; read until the process exited. accoreconsole echoes its whole command line
;;;; there (UTF-16LE, two bytes a character), so once the pipe's buffer was
;;;; full its next console write blocked for ever and the run hung until
;;;; --timeout. Since alfe 2.3.11 the console goes to the workdir file
;;;; engine-console-stdout.txt.
;;;;
;;;; A completed run proves something only if the console really received
;;;; far more than a pipe buffer (4-64 KB). The first version PROMPTed 350 KB
;;;; and the console file grew by NOTHING (job 17028620750: 2290 bytes): a
;;;; (prompt) inside alfe's protocol evaluation does not reach accoreconsole's
;;;; stdout. So this version MEASURES: it reads the size of
;;;; engine-console-stdout.txt (alfe's capture; $CONSOLE_FLOOD_FILE overrides)
;;;; after every chunk, tries several drivers, keeps the ones that make it
;;;; grow, and stops when the console has received *flood-target* bytes.
;;;;
;;;; Drivers, in order (each until it added its share, was found dead, failed,
;;;; or spent 60 s):
;;;;   prompt   (prompt LINE) -- measured; reached nothing in job 17030198222
;;;;   princ    (apply 'princ (list LINE nil)) -- out of reach of alfe's load
;;;;            rewriter; the explicit NIL stream is required, because on
;;;;            AutoCAD alfe's princ takes (OBJ FILE) and a 1-argument call
;;;;            through APPLY failed "nombre d'arguments insuffisants" and
;;;;            ended the whole run (job 17030198222)
;;;;   setvar   (command "_.SETVAR" "USERI1" n) with CMDECHO 1: the command
;;;;            line echo of a command, which is what filled the console in
;;;;            the option-keyword runs that hung. THE PRIMARY FLOOD: its
;;;;            share is the whole target
;;;;   regen    (command "_.REGEN"), only if the console is still short
;;;; The first two are small (64 KB shares) and GUARDED: an error ends that
;;;; driver (FLOOD-DRIVER ... error), not the run. The command drivers are not
;;;; guarded -- (vl-catch-all-apply around COMMAND aborts an AutoCAD run) --
;;;; so they come last.
;;;;
;;;; Output (alfe's stdout):
;;;;   FLOOD-ENGINE  <PROGRAM> <ACADVER>
;;;;   FLOOD-FILE    <path> <bytes at start>        (or "unknown")
;;;;   FLOOD-STEP    <driver> <iterations so far> <console bytes>
;;;;   FLOOD-DRIVER  <driver> <iterations> added <bytes> <live|dead|unmeasured>
;;;;                 [error <message>]
;;;;   FLOOD-DONE    <console bytes> (<added> added)
;;;; A report without FLOOD-DONE is a session that did not complete; the last
;;;; FLOOD-STEP says how far the console had got.

(setq *flood-target* (* 1024 1024))   ; bytes the console must receive in all
(setq *flood-chunk* 200)              ; iterations between two measurements
(setq *flood-max-iterations* 40000)   ; per driver, whatever happens
(setq *flood-max-ms* 60000)           ; per driver: alfe's --timeout is 300 s

(setq *flood-line*
  "console-flood-probe 0123456789 abcdefghijklmnopqrstuvwxyz ABCDE")

(defun flood--getvar (name / v)
  (setq v (vl-catch-all-apply 'getvar (list name)))
  (if (vl-catch-all-error-p v) nil v))

(defun flood--console-file ( / env dir)
  (setq env (vl-catch-all-apply 'getenv (list "CONSOLE_FLOOD_FILE")))
  (cond
    ((and (= (type env) 'STR) (/= env "")) env)
    ((and (boundp '*AUTOLISP_STATUSFILE*) (= (type *AUTOLISP_STATUSFILE*) 'STR))
     (setq dir (vl-filename-directory *AUTOLISP_STATUSFILE*))
     (if (and dir (/= dir ""))
       (strcat dir "/engine-console-stdout.txt")))))

(setq *flood-file* (flood--console-file))

(defun flood--size ( / n)
  (if *flood-file*
    (progn
      (setq n (vl-catch-all-apply 'vl-file-size (list *flood-file*)))
      (if (numberp n) n nil))))

(defun flood--say (text) (princ (strcat text "\n")))

;; One iteration of each driver.
(defun flood--prompt (i) (prompt (strcat *flood-line* "\n")))
(defun flood--princ (i) (apply 'princ (list (strcat *flood-line* "\n") nil)))
;; COMMAND is called directly, never as (vl-catch-all-apply 'command ...):
;; AutoCAD aborts the whole run on that form.
(defun flood--setvar (i) (command "_.SETVAR" "USERI1" (rem i 30000)))
(defun flood--regen (i) (command "_.REGEN"))

;; Run DRIVER (a function of the iteration number) by chunks, measuring the
;; console after each; stop when it added SHARE bytes, when the whole target
;; is reached, when it is dead (a first chunk that added nothing), or at the
;; iteration cap. Returns the bytes it added (NIL when unmeasurable).
(defun flood--ms ( / v)
  (setq v (flood--getvar "MILLISECS"))
  (if (numberp v) v 0))

(defun flood--run (name driver share guarded / start size i stop added t0 r
                                                 failure)
  (setq start (flood--size)
        i 0
        stop nil
        failure nil
        t0 (flood--ms))
  (while (not stop)
    (repeat *flood-chunk*
      (if (not failure)
        (if guarded
          (progn
            (setq r (vl-catch-all-apply driver (list i)))
            (if (vl-catch-all-error-p r)
              (setq failure (vl-catch-all-error-message r))))
          (apply driver (list i))))
      (setq i (1+ i)))
    (if failure (setq stop T))
    (setq size (flood--size))
    (flood--say (strcat "FLOOD-STEP    " name " " (itoa i) " "
                        (if size (itoa size) "?")))
    (cond
      ((or (null size) (null start))
       (if (>= i (* 10 *flood-chunk*)) (setq stop T)))
      ((and (= i *flood-chunk*) (< (- size start) 64)) (setq stop T))
      ((>= (- size start) share) (setq stop T))
      ((>= (- size *flood-base*) *flood-target*) (setq stop T)))
    (if (>= i *flood-max-iterations*) (setq stop T))
    (if (> (- (flood--ms) t0) *flood-max-ms*) (setq stop T)))
  (setq added (if (and size start) (- size start)))
  (flood--say (strcat "FLOOD-DRIVER  " name " " (itoa i) " added "
                      (if added (itoa added) "?") " "
                      (cond ((null added) "unmeasured")
                            ((< added 64) "dead")
                            (T "live"))
                      (if failure (strcat " error " failure) "")))
  added)

(flood--say (strcat "FLOOD-ENGINE  " (vl-princ-to-string (flood--getvar "PROGRAM"))
                    " " (vl-princ-to-string (flood--getvar "ACADVER"))))
(setq *flood-base* (flood--size))
(flood--say (strcat "FLOOD-FILE    "
                    (if *flood-file* *flood-file* "unknown") " "
                    (if *flood-base* (itoa *flood-base*) "?")))

(setq *flood-old-cmdecho* (flood--getvar "CMDECHO"))
(vl-catch-all-apply 'setvar (list "CMDECHO" 1))
(setq *flood-old-useri1* (flood--getvar "USERI1"))

(defun flood--short-p ( / size)
  (setq size (flood--size))
  (or (null *flood-base*)
      (null size)
      (< (- size *flood-base*) *flood-target*)))

;; (NAME DRIVER-SYMBOL SHARE GUARDED)
(foreach entry (list (list "prompt" 'flood--prompt (* 64 1024) T)
                     (list "princ"  'flood--princ  (* 64 1024) T)
                     (list "setvar" 'flood--setvar *flood-target* nil)
                     (list "regen"  'flood--regen  *flood-target* nil))
  (if (flood--short-p)
    (flood--run (nth 0 entry) (nth 1 entry) (nth 2 entry) (nth 3 entry))))

(if *flood-old-useri1*
  (vl-catch-all-apply 'setvar (list "USERI1" *flood-old-useri1*)))
(if *flood-old-cmdecho*
  (vl-catch-all-apply 'setvar (list "CMDECHO" *flood-old-cmdecho*)))

(setq *flood-end* (flood--size))
(flood--say (strcat "FLOOD-DONE    " (if *flood-end* (itoa *flood-end*) "?")
                    " ("
                    (if (and *flood-end* *flood-base*)
                      (itoa (- *flood-end* *flood-base*)) "?")
                    " added)"))
(princ)
