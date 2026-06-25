;;;; probes/sources/probe-secureload.lsp
;;;;
;;;; Ground-truth for the SECURELOAD / TRUSTEDPATHS trust model
;;;; (documentation/clautolisp-secureload-trust-model-spec.org,
;;;; issues/open/note-secureload.txt). Captures the host's trust sysvars
;;;; and the search behaviour of findfile / findtrustedfile, which are
;;;; the functions clautolisp gates in Phase 3.
;;;;
;;;; NOTE: this probe does NOT attempt to (load) a gated file — that
;;;; would have side effects and could trip the host's own security
;;;; prompt. The load/open gating behaviour is captured separately and
;;;; manually where a sandboxed drawing is available; here we record the
;;;; inputs to that behaviour (the sysvars and the file-search results).

(defun cad-probe--findfile (name)
  (cad-probe-capture "findfile"
    (strcat "(findfile " (vl-prin1-to-string name) ")")
    (function (lambda () (findfile name)))))

(defun cad-probe--findtrustedfile (name)
  (cad-probe-capture "findtrustedfile"
    (strcat "(findtrustedfile " (vl-prin1-to-string name) ")")
    (function (lambda () (findtrustedfile name)))))

(defun cad-probe-run-secureload-probes ( / names)
  ;; The trust sysvars (also captured by probe-sysvars; repeated here so
  ;; a secureload-only run is self-contained).
  (cad-probe-sysvar "secureload" "SECURELOAD")
  (cad-probe-sysvar "secureload" "TRUSTEDPATHS")

  ;; A spread of names: a bare support-path resource, a gated-extension
  ;; resource, an absolute path, and a clearly absent file. findfile
  ;; searches the support path (no trust filter); findtrustedfile
  ;; restricts to trusted folders. Diffing the two columns reveals the
  ;; trust boundary on each host.
  (setq names
    (list "acad.lsp" "acad.pat" "acadiso.lin"
          "base.dcl" "gcad.lsp"
          "definitely-not-present-9e3a.lsp"))
  (foreach n names
    (cad-probe--findfile n)
    (cad-probe--findtrustedfile n))
  (princ))
