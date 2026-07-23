(in-package #:clautolisp.debug)

;;;; Virtual (deferred) breakpoints — aldo-pre-debug.issue.
;;;;
;;;; A breakpoint requested while browsing a file that is NOT loaded
;;;; yet: no usubr, no metadata, no poll point exists, so nothing can be
;;;; armed in the breakpoint table. The request is recorded here
;;;; instead, keyed by the file and the name of the enclosing
;;;; (defun NAME …) top-level form, with the target's position kept
;;;; RELATIVE to that top-level form — its anchor is the start line of
;;;; the defun's first body form, the same position the instrumenter
;;;; later stores as the metadata's SOURCE-POSITION. Anchoring makes the
;;;; record survive the top-level forms MOVING in the file between
;;;; browsing and loading (lines added or removed above the defun), the
;;;; issue's "toplevel form-relative positions" requirement.
;;;;
;;;; Arming: when the function is instrumented — the file is loaded and
;;;; the function first runs under the debugger, or it is reached
;;;; explicitly (`g NAME', CLAL-NAV-FUNCTION, ENSURE-METADATA-FOR-NAME)
;;;; — INSTRUMENT-USUBR calls MATERIALIZE-VIRTUAL-BREAKPOINTS, which
;;;; shifts the recorded position by the anchor delta, resolves it to a
;;;; poll point of the fresh metadata, and arms a real breakpoint on the
;;;; recorded thread-debug-info. Instrumentation happens before any of
;;;; the function's poll points run, so the breakpoint fires on the very
;;;; first execution after the load.

(defstruct virtual-breakpoint
  (id 0 :type fixnum)              ; the vbN the UIs list / delete by
  (file "" :type string)           ; namestring of the browsed source file
  (function-name "" :type string)  ; enclosing (defun NAME …) top-level form
  (line 0 :type fixnum)            ; target form start line, at record time
  (col 0 :type fixnum)             ; target form start column, at record time
  (anchor-line 0 :type fixnum)     ; first body form start line, at record time
  ti)                              ; thread-debug-info the real breakpoint goes on

(defvar *virtual-breakpoints* '()
  "The pending virtual breakpoints, newest first (aldo-pre-debug.issue).
Global — they exist precisely because no per-function table can hold them
yet; each record carries the thread-debug-info it will arm on.")

(defvar *virtual-breakpoint-id-counter* 0)

(defun add-virtual-breakpoint (ti file function-name line col anchor-line)
  "Record a virtual breakpoint: when FUNCTION-NAME — the enclosing
(defun NAME …) top-level form of FILE — is loaded and instrumented, arm a
real breakpoint on TI at the poll point recorded as (LINE, COL), anchored
to ANCHOR-LINE (the start line of the defun's first body form, both at
record time). Returns (values VIRTUAL-BREAKPOINT NEW-P): an equivalent
pending record is returned instead of duplicated, NEW-P NIL."
  (let ((existing (find-if (lambda (vb)
                             (and (string-equal (virtual-breakpoint-function-name vb)
                                                function-name)
                                  (equal (virtual-breakpoint-file vb) file)
                                  (eql (virtual-breakpoint-line vb) line)
                                  (eql (virtual-breakpoint-col vb) col)))
                           *virtual-breakpoints*)))
    (if existing
        (values existing nil)
        (let ((vb (make-virtual-breakpoint
                   :id (incf *virtual-breakpoint-id-counter*)
                   :file file :function-name function-name
                   :line line :col col :anchor-line anchor-line :ti ti)))
          (push vb *virtual-breakpoints*)
          (values vb t)))))

(defun list-virtual-breakpoints ()
  "Every pending virtual breakpoint, oldest first."
  (reverse *virtual-breakpoints*))

(defun find-virtual-breakpoint (id)
  "The pending virtual breakpoint numbered ID (the vbN of the listings), or NIL."
  (find id *virtual-breakpoints* :key #'virtual-breakpoint-id))

(defun remove-virtual-breakpoint (vb)
  "Drop the pending record VB (it was armed, or the user deleted it)."
  (setf *virtual-breakpoints* (remove vb *virtual-breakpoints*))
  vb)

(defun clear-virtual-breakpoints ()
  "Drop every pending virtual breakpoint."
  (setf *virtual-breakpoints* '()))

(defun same-source-file-p (a b)
  "True when the file designator strings A and B name the same source file:
equal namestrings, or equal truenames when both resolve (a browsed path and
the loader's resolved path may spell the same file differently)."
  (and (stringp a) (stringp b)
       (or (equal a b)
           (let ((ta (ignore-errors (truename a)))
                 (tb (ignore-errors (truename b))))
             (and ta tb (equal (namestring ta) (namestring tb)))))))

(defun virtual-breakpoints-for-file (file)
  "The pending virtual breakpoints recorded on FILE, oldest first — for the
navigator's decorations (the browsed source shows them before the load)."
  (remove-if-not (lambda (vb) (same-source-file-p (virtual-breakpoint-file vb) file))
                 (list-virtual-breakpoints)))

(defun materialize-virtual-breakpoints (metadata)
  "Arm every pending virtual breakpoint that names METADATA's freshly
instrumented function in its recorded file. Called by INSTRUMENT-USUBR right
after the metadata is registered. The recorded position is shifted by the
anchor delta — the metadata's SOURCE-POSITION (the first body form) minus the
record-time anchor line — so a defun that MOVED in the file still resolves;
then it maps to a poll point exactly (LINE:COL), falling back to the innermost
poll point on the line (a within-form reformat). A record that resolves is
armed on its thread-debug-info and dropped; one that does not stays pending
(it may match a later redefinition). Returns the list of (VB . BREAKPOINT)
pairs armed."
  (let ((source (function-debug-metadata-source-position metadata))
        (armed '()))
    (when (source-position-p source)
      (dolist (vb (list-virtual-breakpoints))
        (when (and (string-equal (virtual-breakpoint-function-name vb)
                                 (function-debug-metadata-name metadata))
                   (same-source-file-p (virtual-breakpoint-file vb)
                                       (source-position-file source)))
          (let* ((delta (- (source-position-start-line source)
                           (virtual-breakpoint-anchor-line vb)))
                 (line (+ (virtual-breakpoint-line vb) delta))
                 (form-id (or (form-id-at-line-col metadata line
                                                   (virtual-breakpoint-col vb))
                              (find-form-id-at-line metadata line))))
            (when (and form-id (thread-debug-info-p (virtual-breakpoint-ti vb)))
              (let ((bp (add-breakpoint (virtual-breakpoint-ti vb)
                                        (function-debug-metadata-function-id metadata)
                                        form-id)))
                (remove-virtual-breakpoint vb)
                (push (cons vb bp) armed)))))))
    (nreverse armed)))
