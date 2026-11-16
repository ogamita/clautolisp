;;;; probes/sources/probe-load-encoding.lsp
;;;;
;;;; windows-runner-sunset-probe-campaign, batch B6 (AC-crit). What
;;;; probe-open-encoding.lsp does not cover -- LOAD:
;;;;
;;;;   - LOAD of a missing file: the error, the ERRNO, and the ONFAILURE
;;;;     argument (a symbol, a string), with and without an extension;
;;;;   - LOAD of a source file written in each of the encodings OPEN can
;;;;     produce here -- the default, "utf8", "utf8-bom" (AutoCAD's third
;;;;     argument), ",ccs=UTF-8" / ",ccs=UTF-16LE" (BricsCAD's mode suffix) --
;;;;     holding (setq cad-probe-le-v "A<e-acute>B"). Each case records the
;;;;     file's SIZE (which bytes were written: 3 chars -> 29 + 1..4 bytes for
;;;;     the e-acute and the BOM) and the char codes LOAD made of the string
;;;;     (65 233 66 when it decoded what was written; 65 195 169 66 when it
;;;;     read UTF-8 as a single-byte code page; ...).
;;;;
;;;; LISPSYS is recorded, not changed (changing it persists: quarantined in
;;;; probe-lispsys.lsp). Pure ASCII source: the e-acute is (chr 233).
;;;; Each case under VL-CATCH-ALL-APPLY; record (RESULT ERRNO).

(defun cad-probe--le-run (cad-probe--le-text / r errno)
  (vl-catch-all-apply 'setvar (list "ERRNO" 0))
  (setq r (vl-catch-all-apply (function (lambda () (eval (read cad-probe--le-text)))) nil))
  (setq errno (getvar "ERRNO"))
  (list (if (vl-catch-all-error-p r) (list 'error (vl-catch-all-error-message r)) r)
        errno))

(defun cad-probe--le (cad-probe--le-case)
  (cad-probe-capture "load-encoding" cad-probe--le-case
    (function (lambda () (vl-prin1-to-string (cad-probe--le-run cad-probe--le-case))))))

(defun cad-probe--le-path (cad-probe--le-tag)
  (strcat (getenv "TEMP") "\\clautolisp-b6-" cad-probe--le-tag ".lsp"))

(defun cad-probe--le-roundtrip (cad-probe--le-tag cad-probe--le-open-args
                                / path f size r)
  ;; Write (setq cad-probe-le-v "A<e-acute>B") with OPEN-ARGS, then LOAD it.
  ;; Record (SIZE CODES-OF-V) -- or why it could not be written / loaded.
  (setq path (if (getenv "TEMP")
                 (cad-probe--le-path cad-probe--le-tag)
                 (strcat "/tmp/clautolisp-b6-" cad-probe--le-tag ".lsp")))
  (setq cad-probe-le-v nil)
  (setq f (vl-catch-all-apply 'open (cons path cad-probe--le-open-args)))
  (cond
    ((vl-catch-all-error-p f) (list 'open-error (vl-catch-all-error-message f)))
    ((null f) 'open-returned-nil)
    (t
     (write-line (strcat "(setq cad-probe-le-v \"A" (chr 233) "B\")") f)
     (close f)
     (setq size (vl-file-size path))
     (setq r (vl-catch-all-apply 'load (list path)))
     (vl-file-delete path)
     (list size
           (if (vl-catch-all-error-p r)
               (list 'load-error (vl-catch-all-error-message r))
               (if (= (type cad-probe-le-v) 'STR)
                   (vl-string->list cad-probe-le-v)
                   cad-probe-le-v))))))

(defun cad-probe-run-load-encoding-probes ()
  (cad-probe-note "load-encoding" "lispsys"
    "LISPSYS of this session (recorded, never changed)")
  (cad-probe--le "(getvar \"LISPSYS\")")

  (cad-probe-note "load-encoding" "missing"
    "(RESULT ERRNO) of LOAD of a file that does not exist, with and without ONFAILURE")
  (cad-probe--le "(load \"clautolisp-b6-no-such-file.lsp\")")
  (cad-probe--le "(load \"clautolisp-b6-no-such-file\")")
  (cad-probe--le "(load \"clautolisp-b6-no-such-file.lsp\" 'cad-probe-le-failed)")
  (cad-probe--le "(load \"clautolisp-b6-no-such-file.lsp\" \"failed\")")
  (cad-probe--le "(load \"clautolisp-b6-no-such-file.lsp\" nil)")
  (cad-probe--le "(load \"\")")

  (cad-probe-note "load-encoding" "roundtrip"
    "((SIZE CODES-OF-V) ERRNO): a source written with each OPEN encoding, then LOADed")
  (cad-probe--le "(cad-probe--le-roundtrip \"default\" '(\"w\"))")
  (cad-probe--le "(cad-probe--le-roundtrip \"utf8\" '(\"w\" \"utf8\"))")
  (cad-probe--le "(cad-probe--le-roundtrip \"utf8bom\" '(\"w\" \"utf8-bom\"))")
  (cad-probe--le "(cad-probe--le-roundtrip \"ccs-utf8\" '(\"w,ccs=UTF-8\"))")
  (cad-probe--le "(cad-probe--le-roundtrip \"ccs-utf16\" '(\"w,ccs=UTF-16LE\"))")
  (princ))
