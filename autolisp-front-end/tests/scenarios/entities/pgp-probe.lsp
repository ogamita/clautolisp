;;;; pgp-probe.lsp -- harvest the keyboard command ALIASES (the third, distinct
;;;; CAD locale dictionary) from the install's alias file, for cadtui
;;;; (issues/open/cadtui-locale-probe-pgp-aliases).
;;;;
;;;; The alias file (acad.pgp on AutoCAD, default.pgp on BricsCAD) is a DATA
;;;; file: aliases are purely LOCAL and are NEVER _-prefixed, kept strictly
;;;; apart from the getcname command-name dictionary. On a French install the
;;;; command-alias lines map an abbreviation to the LOCALISED command, e.g.
;;;;   L,      *LIGNE
;;;; (command aliases carry the leading "*"; the other .pgp entries are external
;;;; commands, which we skip). No CAD scripting is needed beyond LOCATING the
;;;; file and reading it — the parsing is done by the converter, so we emit the
;;;; raw lines verbatim.
;;;;
;;;; Output, tab-separated:
;;;;   PGP-ENGINE  <PROGRAM>  <ACADVER>  <PLATFORM>  <LOCALE>
;;;;   PGP-FILE    <path>
;;;;   PGP-RAW     <verbatim line>          ; one per line of the file
;;;;   PGP-DONE                             ; sentinel
;;;; or PGP-ABSENT when no alias file is found (e.g. the clautolisp dry-run,
;;;; where FINDFILE cannot locate one).

(defun emit-pgp-file (path / f line)
  "Echo every line of the alias file at PATH as a PGP-RAW record. Returns T on
success, NIL when PATH cannot be opened."
  (if (and path (setq f (open path "r")))
      (progn
        (princ (strcat "PGP-FILE\t" path "\n"))
        (while (setq line (read-line f))
          (princ (strcat "PGP-RAW\t" line "\n")))
        (close f)
        t)
      nil))

(princ (strcat "PGP-ENGINE\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "PROGRAM")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "ACADVER")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "PLATFORM")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "LOCALE")))
               "\n"))

;; Try the known alias-file names in order; the first that opens wins. AutoCAD
;; ships acad.pgp, BricsCAD default.pgp (also try the "-mac" variants seen on
;; localised macOS installs).
(or (emit-pgp-file (findfile "default.pgp"))
    (emit-pgp-file (findfile "acad.pgp"))
    (emit-pgp-file (findfile "acadmac.pgp"))
    (princ "PGP-ABSENT\tno alias file located via findfile\n"))

(princ "PGP-DONE\n")
(princ)
