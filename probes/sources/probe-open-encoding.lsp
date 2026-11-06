;;;; probes/sources/probe-open-encoding.lsp
;;;;
;;;; OPEN's encoding argument (encoding-situations-cli-options, section 6
;;;; point 5: forward -Efile to the CAD by defaulting OPEN's encoding there).
;;;; AutoCAD documents a third argument, "utf8" / "utf8-bom" (LISPSYS >= 1);
;;;; BricsCAD a mode suffix ",ccs=UTF-8" / ",ccs=UTF-16LE". Measured for
;;;; BricsCAD write only; AutoCAD's third argument never. One suite,
;;;; open-encoding: for each form of OPEN, write "A" e-acute "B" (3 chars),
;;;; then report the FILE SIZE -- 3 bytes = a single-octet code page, 4 =
;;;; UTF-8, 7 = UTF-8 with a BOM, 6 / 8 = UTF-16 (with a BOM) -- and what a
;;;; plain (open f "r") and an (open f "r" "utf8") read back (char codes).
;;;; APPEND: alfe forwards -Efile-write to a plain "a" too on BricsCAD/Windows
;;;; (",ccs=" appended), which was never measured: does an append in an
;;;; encoding that writes a BOM write it AGAIN in the middle of the file? Each
;;;; append case writes "A" e-acute "B" with the first mode, appends one e-acute
;;;; with the second, and reports both sizes: UTF-8 with a BOM is 7 then 9 (no
;;;; second BOM) or 12 (a second one); UTF-16LE with a BOM 8 then 10 or 12.
;;;; Pure ASCII source: the e-acute is (chr 233).
;;;; Every step under VL-CATCH-ALL-APPLY.

(defun cad-probe--oe-show (cad-probe--oe-thunk / r)
  (setq r (vl-catch-all-apply cad-probe--oe-thunk '()))
  (if (vl-catch-all-error-p r)
      (strcat "ERROR " (vl-catch-all-error-message r))
      (vl-prin1-to-string r)))

(defun cad-probe--oe (name cad-probe--oe-fn)
  (cad-probe-capture "open-encoding" name
    (function (lambda () (cad-probe--oe-show cad-probe--oe-fn)))))

(defun cad-probe--oe-read-codes (path open-args / f c acc)
  (setq f (apply 'open (cons path open-args)))
  (if f
    (progn
      (while (setq c (read-char f)) (setq acc (cons c acc)))
      (close f)
      (reverse acc))
    :OPEN-RETURNED-NIL))

(defun cad-probe--oe-case (label path open-args / f)
  ;; write
  (cad-probe--oe (strcat label ": write A e-acute B, then the file size")
    (function (lambda ()
                (setq f (apply 'open (cons path open-args)))
                (if f
                  (progn
                    (write-char 65 f) (write-char 233 f) (write-char 66 f)
                    (close f)
                    (vl-file-size path))
                  :OPEN-RETURNED-NIL))))
  (cad-probe--oe (strcat label ": read back with (open f \"r\")")
    (function (lambda () (cad-probe--oe-read-codes path '("r")))))
  (cad-probe--oe (strcat label ": read back with (open f \"r\" \"utf8\")")
    (function (lambda () (cad-probe--oe-read-codes path '("r" "utf8")))))
  (cad-probe--oe (strcat label ": read back with (open f \"r,ccs=UTF-8\")")
    (function (lambda () (cad-probe--oe-read-codes path '("r,ccs=UTF-8"))))))

(defun cad-probe--oe-append-case (label path write-args append-args / f)
  (cad-probe--oe (strcat label ": write A e-acute B, append e-acute, (size-after-write size-after-append)")
    (function (lambda ( / s1)
                (setq f (apply 'open (cons path write-args)))
                (write-char 65 f) (write-char 233 f) (write-char 66 f)
                (close f)
                (setq s1 (vl-file-size path))
                (setq f (apply 'open (cons path append-args)))
                (if f
                  (progn (write-char 233 f) (close f)
                         (list s1 (vl-file-size path)))
                  (list s1 :APPEND-OPEN-RETURNED-NIL)))))
  (cad-probe--oe (strcat label ": read back with (open f \"r\")")
    (function (lambda () (cad-probe--oe-read-codes path '("r"))))))

(defun cad-probe-run-open-encoding-probes ( / dir)
  (setq dir (getvar "TEMPPREFIX"))
  (cad-probe--oe "(getvar \"LISPSYS\")" (function (lambda () (getvar "LISPSYS"))))
  (cad-probe--oe-case "(open f \"w\")"
                      (strcat dir "prb-oe-default.txt") '("w"))
  (cad-probe--oe-case "(open f \"w\" \"utf8\")"
                      (strcat dir "prb-oe-utf8.txt") '("w" "utf8"))
  (cad-probe--oe-case "(open f \"w\" \"utf8-bom\")"
                      (strcat dir "prb-oe-utf8bom.txt") '("w" "utf8-bom"))
  (cad-probe--oe-case "(open f \"w,ccs=UTF-8\")"
                      (strcat dir "prb-oe-ccsutf8.txt") '("w,ccs=UTF-8"))
  (cad-probe--oe-case "(open f \"w,ccs=UTF-16LE\")"
                      (strcat dir "prb-oe-ccsutf16.txt") '("w,ccs=UTF-16LE"))
  (cad-probe--oe-append-case "\"w,ccs=UTF-8\" then \"a,ccs=UTF-8\""
                             (strcat dir "prb-oe-app-ccsutf8.txt")
                             '("w,ccs=UTF-8") '("a,ccs=UTF-8"))
  (cad-probe--oe-append-case "\"w,ccs=UTF-16LE\" then \"a,ccs=UTF-16LE\""
                             (strcat dir "prb-oe-app-ccsutf16.txt")
                             '("w,ccs=UTF-16LE") '("a,ccs=UTF-16LE"))
  (cad-probe--oe-append-case "\"w,ccs=UTF-8\" then a plain \"a\""
                             (strcat dir "prb-oe-app-plain.txt")
                             '("w,ccs=UTF-8") '("a"))
  (cad-probe--oe-append-case "\"w\" \"utf8\" then \"a\" \"utf8\""
                             (strcat dir "prb-oe-app-utf8.txt")
                             '("w" "utf8") '("a" "utf8"))
  (cad-probe--oe "(open f \"w\" \"cp1252\") -- an unknown third argument"
    (function (lambda () (open (strcat dir "prb-oe-bad.txt") "w" "cp1252")))))
