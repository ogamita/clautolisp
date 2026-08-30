;;;; autolisp-front-end/source/empty-drawing.lisp
;;;;
;;;; The empty drawing alfe hands a CAD, as a resource in the image.
;;;;
;;;; WHY A FRESH FILE EVERY TIME (issues/open/empty-ressource.issue, pjb
;;;; 2026-08-30). Passing the same empty.dwg to successive runs produces
;;;; MODAL DIALOGS -- "the drawing is in use by another instance", "open
;;;; read-only?" -- because a previous CAD still holds the lock, or left
;;;; one behind, or modified the file. A modal dialog in a batch run is
;;;; not a slow run, it is a hung one: the launcher waits for a READY
;;;; that a dialog is sitting in front of.
;;;;
;;;; So each invocation gets its OWN drawing, written into that
;;;; invocation's workdir, which is already unique per run and already
;;;; cleaned up afterwards. Nothing is shared, so nothing can be locked
;;;; by anyone else.
;;;;
;;;; WHY IN THE IMAGE rather than on disk. alfe is shipped as a single
;;;; executable and is expected to work with nothing installed beside it;
;;;; a resource it must find at run time is one more thing that can be
;;;; missing, mislocated, or stale relative to the binary. At 13 KB the
;;;; drawing is cheaper to carry than to look for. (The eventual
;;;; /opt/local/share/clautolisp/... resource directory is still the right
;;;; answer for the larger case -- templates, documents -- but alfe stays
;;;; standalone.)
;;;;
;;;; The bytes are read AT COMPILE TIME, by a macro, so they land in the
;;;; fasl and then in the dumped image. LOAD-TIME-VALUE would be wrong
;;;; here: it runs when the FASL is loaded, and at that moment
;;;; *LOAD-TRUENAME* names the fasl in the ASDF cache, not this directory.

(defpackage #:alfe.drawing
  (:use #:cl)
  (:export #:*empty-dwg-contents*
           #:save-empty-dwg
           #:fresh-empty-dwg
           #:empty-dwg-size))

(in-package #:alfe.drawing)

(defmacro %embedded-empty-dwg ()
  "Expand to the contents of empty.dwg, read from beside THIS SOURCE FILE
at compile time."
  (let* ((here (or *compile-file-truename* *load-truename*
                   (error "%EMBEDDED-EMPTY-DWG: no source location; ~
                           compile or load this file from its directory.")))
         (path (merge-pathnames "empty.dwg" here)))
    (with-open-file (in path :element-type '(unsigned-byte 8))
      (let ((bytes (make-array (file-length in)
                               :element-type '(unsigned-byte 8))))
        (read-sequence bytes in)
        `(quote ,bytes)))))

(defparameter *empty-dwg-contents* (%embedded-empty-dwg)
  "The bytes of an empty drawing, carried in the image.

AC1032 (AutoCAD 2018-2020), which both AutoCAD 2026 and BricsCAD V26
open. A .dwg is a vendor binary bound to a format version, so this is a
thing to REPLACE rather than to edit if a future engine refuses it --
and the failure would be loud (the CAD declines to open it), not
subtle.")

(defun empty-dwg-size ()
  "How many bytes the embedded empty drawing has. For diagnostics, and
for a test that can tell `the resource is present' from `the resource is
an empty vector because something went wrong at compile time'."
  (length *empty-dwg-contents*))

(defun save-empty-dwg (path)
  "Write the embedded empty drawing to PATH, replacing anything there.
Returns the truename."
  (with-open-file (out path :element-type '(unsigned-byte 8)
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
    (write-sequence *empty-dwg-contents* out))
  (truename path))

(defun fresh-empty-dwg (directory &key (name "empty.dwg"))
  "Write a NEW empty drawing into DIRECTORY and return its pathname.

DIRECTORY is a run's workdir: unique to the invocation, so the drawing
is too, which is the whole point -- see the header. Returns NIL rather
than signalling if the write fails, so a backend can fall back to
whatever template discovery finds instead of failing the run over a
drawing it was only providing as a courtesy."
  (handler-case
      (let ((path (merge-pathnames name (uiop:ensure-directory-pathname directory))))
        (ensure-directories-exist path)
        (save-empty-dwg path))
    (error (condition)
      (warn "alfe.drawing: could not write a fresh empty drawing into ~A: ~A"
            directory condition)
      nil)))
