;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;
;;;; Generate the user manual's annex of dialect warnings from the
;;;; register in autolisp-runtime/source/portability.lisp.
;;;;
;;;; The register is the ONE source: a warning's message template, the
;;;; detail of how the dialects diverge, and the reference material all
;;;; live in the entry the emitter formats from, so the annex cannot
;;;; drift from what the program actually prints. Re-run this after
;;;; changing an entry:
;;;;
;;;;     make -C clautolisp dialect-warnings-annex
;;;;
;;;; or by hand, from the clautolisp/ directory:
;;;;
;;;;     sbcl --non-interactive --load tools/generate-dialect-warnings-annex.lisp
;;;;
;;;; The output file is tracked in git (it ships in the manual and is
;;;; built to PDF/Info by `make documentation'), so a change to the
;;;; register must be committed together with the regenerated annex.
;;;; The `check-dialect-warnings-annex' target is what keeps that
;;;; honest: it regenerates into a temporary file and fails if the
;;;; tracked one differs.

(let ((quicklisp (merge-pathnames #P"quicklisp/setup.lisp"
                                  (user-homedir-pathname))))
  (when (probe-file quicklisp)
    (load quicklisp)))

(require :asdf)

(asdf:load-asd (merge-pathnames "clautolisp.asd" (uiop:getcwd)))
(asdf:load-system "clautolisp/autolisp-runtime")

(defparameter *annex-path*
  (or (second sb-ext:*posix-argv*)
      "documentation/clautolisp-dialect-warnings.org")
  "Where to write. Overridable by an argument so the consistency check
can render to a temporary file and diff it against the tracked one.")

(with-open-file (out *annex-path*
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create
                     :external-format :utf-8)
  (clautolisp.autolisp-runtime:render-dialect-warnings-annex out))

(format t "~&Wrote ~A~%" *annex-path*)
