;;;; console-flood-probe.lsp -- does a long, chatty CAD session complete?
;;;; (issues/open/alfe-accoreconsole-console-pipe-not-drained)
;;;;
;;;; alfe used to start accoreconsole with its console on PIPES that nothing
;;;; read until the process exited. accoreconsole echoes its whole command line
;;;; there (UTF-16LE, two bytes a character), so once the pipe's buffer was
;;;; full its next console write blocked for ever and the run hung until
;;;; --timeout. Since alfe 2.3.11 the console goes to files in the workdir.
;;;;
;;;; This probe writes N kilobytes to the CAD's OWN command line with PROMPT --
;;;; not PRINC, which alfe captures into its protocol and which therefore never
;;;; reaches the console -- for growing N, all in ONE session. Each block is
;;;; bracketed by captured markers, so the report shows how far the session
;;;; got: with the pipe undrained it stops at the block that crosses the
;;;; buffer, with the fix every block completes.
;;;;
;;;; Output (alfe's stdout):
;;;;   FLOOD-ENGINE  <PROGRAM>  <ACADVER>
;;;;   FLOOD-BEGIN   <N> KB   (cumulative <C> KB before it)
;;;;   FLOOD-END     <N> KB   (cumulative <C> KB)
;;;;   FLOOD-DONE    <C> KB
;;;; A report without FLOOD-DONE is a session that did not complete.

(setq *flood-blocks* (list 2 4 8 16 64 256))

;; 63 characters + the newline PROMPT is given = 64 characters a line, so
;; 16 lines are one kilobyte of console text (two on a UTF-16LE console).
(setq *flood-line*
  "console-flood-probe 0123456789 abcdefghijklmnopqrstuvwxyz ABCDE")

(defun flood--getvar (name / v)
  (setq v (vl-catch-all-apply 'getvar (list name)))
  (if (vl-catch-all-error-p v) nil v))

(defun flood--block (kb / i)
  (setq i 0)
  (while (< i (* 16 kb))
    (prompt (strcat *flood-line* "\n"))
    (setq i (1+ i))))

(princ (strcat "FLOOD-ENGINE  " (vl-princ-to-string (flood--getvar "PROGRAM"))
               "  " (vl-princ-to-string (flood--getvar "ACADVER")) "\n"))

(setq *flood-total* 0)
(foreach kb *flood-blocks*
  (princ (strcat "FLOOD-BEGIN   " (itoa kb) " KB   (cumulative "
                 (itoa *flood-total*) " KB before it)\n"))
  (flood--block kb)
  (setq *flood-total* (+ *flood-total* kb))
  (princ (strcat "FLOOD-END     " (itoa kb) " KB   (cumulative "
                 (itoa *flood-total*) " KB)\n")))

(princ (strcat "FLOOD-DONE    " (itoa *flood-total*) " KB\n"))
(princ)
