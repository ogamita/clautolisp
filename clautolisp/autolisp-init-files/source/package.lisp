;;;; clautolisp/autolisp-init-files/source/package.lisp
;;;;
;;;; clautolisp.autolisp-init-files — discovery + load-order policy
;;;; for user init files (~/.clautolisp{,rc}{,.lsp,…},
;;;; ~/.config/clautolisp/init{,.lsp,…}, and the matching
;;;; ~/.autolisp / ~/.config/autolisp/init stems).
;;;;
;;;; Both the clautolisp executable (tools/clautolisp/source/main.lisp)
;;;; and the alfe CLI (autolisp-front-end/source/cli.lisp) consume
;;;; this module — keeping the discovery logic in one place keeps
;;;; their behaviour in lockstep and concentrates the test surface.
;;;;
;;;; Specified by ../../../issues/open/init-files.issue. The
;;;; per-stem extension preference (.lsp vs. compiled .fas/.des/.vlx
;;;; based on mtime) mirrors the legacy bash `autolisp` wrapper's
;;;; long-standing contract so users carrying an existing
;;;; ~/.autolisprc see it loaded by the new binaries too.

(defpackage #:clautolisp.autolisp-init-files
  (:use #:cl)
  (:export
   ;; Per-program default stem lists. Each entry is
   ;; (STEM-PATH REQUIRE-EXTENSION-P) — the second slot is T for the
   ;; XDG `init` slots that have no bare-stem variant.
   #:*default-clautolisp-stems*
   #:*default-alfe-stems*
   ;; Discovery API.
   #:find-init-file
   #:find-init-files
   ;; Gating helpers.
   #:no-init-requested-p
   #:env-true-p))
