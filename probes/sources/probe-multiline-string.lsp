;;;; probes/sources/probe-multiline-string.lsp
;;;;
;;;; Ground-truth for a LINE BREAK WRITTEN LITERALLY INSIDE A STRING
;;;; LITERAL -- the Common Lisp idiom
;;;;
;;;;     (setq s "ab
;;;;     cd")
;;;;
;;;; THE QUESTION. Does the engine accept it, and what does the string
;;;; then contain: the line break as written (LF, CR LF, lone CR),
;;;; normalised to LF, or something else? And does the reader carry on
;;;; with the NEXT form in the file afterwards?
;;;;
;;;; The autolisp-spec Reader Syntax Entry "String Literal" gives only
;;;; string ::= "\"" string-char* "\"" and does not say whether a line
;;;; break is a string-char.
;;;;
;;;; TWO READERS ARE ASKED, because they need not agree:
;;;;
;;;;   - READ, on a string built at run time with (chr 10) / (chr 13).
;;;;   - LOAD, on the committed fixtures in sources/fixtures/mls-*.lsp.
;;;;     This is the case the question is really about.
;;;;
;;;; THE FIXTURES ARE COMMITTED, BYTE-EXACT (fixtures/.gitattributes says
;;;; -text), rather than written by this suite: AutoCAD on Windows writes
;;;; (write-char 10 f) as CR LF, so a fixture written from AutoLISP cannot
;;;; hold a bare LF there -- the first version of this probe measured CR LF
;;;; twice and called one of them LF. Nor are the forms written in THIS
;;;; file: an engine that took the line break as the end of the string
;;;; would desynchronise on its own source and refuse the whole suite (see
;;;; probe-load-refusal.lsp).
;;;;
;;;; Each fixture sets cad-probe-mls-v and then, as a SEPARATE following
;;;; form, cad-probe-mls-after: the marker says the reader resynchronised
;;;; after the string. The fixtures' bytes inside the string:
;;;;
;;;;   mls-lf.lsp           LF               (whole file LF)
;;;;   mls-crlf.lsp         CR LF            (whole file CR LF)
;;;;   mls-lf-indent.lsp    LF LF sp sp sp   (whole file LF)
;;;;   mls-crlf-indent.lsp  CR LF CR LF sp sp sp (whole file CR LF)
;;;;   mls-cr.lsp           CR               (rest of the file LF)
;;;;   mls-crcr-crlf.lsp    CR CR            (rest of the file CR LF)
;;;;
;;;; Values are recorded as CHARACTER CODE LISTS, never as strings, so
;;;; nothing about how a host prints a newline in a string can blur them.
;;;;
;;;; Not covered: typing a line break inside a string at the CAD command
;;;; line (the "_> continuation prompt). That needs an interactive session.
;;;;
;;;; Run it alone with:  PROBE_SUITES=multiline-string

(defun cad-probe-mls--capture (case thunk)
  (cad-probe-capture "multiline-string" case thunk))

(defun cad-probe-mls--load (name)
  ;; => (CODES-OF-THE-STRING MARKER), or an error status if LOAD signals.
  (setq cad-probe-mls-v nil)
  (setq cad-probe-mls-after nil)
  (load (strcat cad-probe-sources-directory "fixtures/mls-" name ".lsp"))
  (list (if (= (type cad-probe-mls-v) 'STR)
          (vl-string->list cad-probe-mls-v)
          cad-probe-mls-v)
        cad-probe-mls-after))

(defun cad-probe-mls--read (separator)
  (vl-string->list
   (read (strcat "\"ab" (apply 'strcat (mapcar 'chr separator)) "cd\""))))

(defun cad-probe-mls--read-then-next ()
  ;; The string must end where its closing quote is, with the list going
  ;; on after it. => (CODES X)
  (mapcar (function (lambda (e) (if (= (type e) 'STR) (vl-string->list e) e)))
          (read (strcat "(\"ab" (chr 10) "cd\" x)"))))

(defun cad-probe-mls--case (name label)
  (cad-probe-mls--capture
   (strcat "load fixtures/mls-" name ".lsp: " label " -- (string codes, marker)")
   (function (lambda () (cad-probe-mls--load name)))))

(defun cad-probe-run-multiline-string-probes ()
  (cad-probe-note "multiline-string" "platform" (getvar "PLATFORM"))
  (cad-probe-note "multiline-string" "acadver" (getvar "ACADVER"))
  ;; READ first: it cannot hang the suite.
  (cad-probe-mls--capture "read: \"ab<LF>cd\""
                          (function (lambda () (cad-probe-mls--read '(10)))))
  (cad-probe-mls--capture "read: \"ab<CR><LF>cd\""
                          (function (lambda () (cad-probe-mls--read '(13 10)))))
  (cad-probe-mls--capture "read: \"ab<CR>cd\""
                          (function (lambda () (cad-probe-mls--read '(13)))))
  (cad-probe-mls--capture "read: (\"ab<LF>cd\" x) -- list after the string"
                          (function cad-probe-mls--read-then-next))
  ;; LOAD: the question proper. LF first, the commonest case.
  (cad-probe-mls--case "lf" "\"ab<LF>cd\", LF file")
  (cad-probe-mls--case "crlf" "\"ab<CR><LF>cd\", CRLF file")
  (cad-probe-mls--case "lf-indent" "\"ab<LF><LF>   cd\", LF file")
  (cad-probe-mls--case "crlf-indent" "\"ab<CR><LF><CR><LF>   cd\", CRLF file")
  (cad-probe-mls--case "cr" "\"ab<CR>cd\", lone CR, LF file")
  (cad-probe-mls--case "crcr-crlf" "\"ab<CR><CR>cd\", CRLF file"))
