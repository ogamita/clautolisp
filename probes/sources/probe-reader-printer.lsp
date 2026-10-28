;;;; probes/sources/probe-reader-printer.lsp
;;;;
;;;; windows-runner-sunset-probe-campaign, batch B3 (AC-crit: the reader /
;;;; printer authority is lost with the Windows runner). From the ch.2 / 12 /
;;;; 13 / 14 spec harvest:
;;;;
;;;;   - READ and comments: a trailing ; comment, a ;| ... |; block comment
;;;;     between or before tokens, inside a list;
;;;;   - the real-literal reader: .5, 1., 1.e6, +.5, -.5, 1E+03, 1e3, 1d3 --
;;;;     and that 1. reads as the REAL 1.0, not an integer;
;;;;   - the symbol-token grammar: a#b, a[b], a:b, |a b|, a.b, a'b, a,b;
;;;;   - the string-literal escape repertoire: \101 (octal), \x41, A,
;;;;     \e, \n, \t, \\, \" and an unknown escape \q;
;;;;   - the PRIN1 escape repertoire on control characters, an embedded quote
;;;;     and backslash, non-ASCII (e-acute 233, euro 8364) and an astral
;;;;     character (128512), and whether READ gives the string back.
;;;;
;;;; Every input string with a quote or a backslash is BUILT at run time with
;;;; CHR (34 = ", 92 = \) rather than written as a nested literal, so one
;;;; level of string syntax is all the probe file itself relies on, and a
;;;; string's contents are recorded as its character codes
;;;; (VL-STRING->LIST): no encoding of the results file can blur them.
;;;;
;;;; Portability (probes/README.org): each case is a STRING (eval (read ...))'d,
;;;; so a host that refuses one form fails THAT case only. The case name is the
;;;; exact expression.

(defun cad-probe--rp (case-text)
  (cad-probe-capture "reader-printer" case-text
    (function (lambda () (vl-prin1-to-string (eval (read case-text)))))))

;; Helpers the cases call (named so a case stays one readable expression).
(defun cad-probe--rp-typed (cad-probe--rp-v)
  ;; (VALUE TYPE), a symbol also by its name -- so 1 and 1.0, a symbol and a
  ;; string, are told apart in the record
  (list cad-probe--rp-v (type cad-probe--rp-v)
        (if (= (type cad-probe--rp-v) 'SYM) (vl-symbol-name cad-probe--rp-v))))

(defun cad-probe--rp-quoted (cad-probe--rp-body)
  ;; BODY between double quotes: the text of a string literal
  (strcat (chr 34) cad-probe--rp-body (chr 34)))

(defun cad-probe--rp-read-string (cad-probe--rp-body / s)
  ;; READ of the string literal "BODY", as character codes (or what came back)
  (setq s (read (cad-probe--rp-quoted cad-probe--rp-body)))
  (if (= (type s) 'STR) (vl-string->list s) (list 'not-a-string s (type s))))

(defun cad-probe--rp-print (cad-probe--rp-s / p)
  ;; PRIN1 of the string S as character codes, and whether READ gives S back
  (setq p (vl-prin1-to-string cad-probe--rp-s))
  (list (vl-string->list p) (equal (read p) cad-probe--rp-s)))

(defun cad-probe-run-reader-printer-probes ()
  ;; --- READ and comments ----------------------------------------------
  (cad-probe-note "reader-printer" "read-comments"
    "a ; comment after a token, a ;| |; block before / between tokens, in a list")
  (cad-probe--rp "(read \"1 ; two\")")
  (cad-probe--rp "(read \"1 ;| c |; 2\")")
  (cad-probe--rp "(read \";| c |; 3\")")
  (cad-probe--rp "(read \"(1 ;| c |; 2)\")")
  (cad-probe--rp "(read (strcat \"(1 ; c\" (chr 10) \" 2)\"))")
  (cad-probe--rp "(read \"; only a comment\")")

  ;; --- real-literal reader ---------------------------------------------
  (cad-probe-note "reader-printer" "real-literals"
    "(VALUE TYPE): .5 1. 1.e6 +.5 -.5 1E+03 1e3 1d3 -- does 1. read as REAL 1.0?")
  (cad-probe--rp "(cad-probe--rp-typed (read \".5\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"1.\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"1.e6\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"+.5\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"-.5\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"1E+03\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"1e3\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"1d3\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"+5\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"1.5.2\"))")

  ;; --- symbol-token grammar ----------------------------------------------
  (cad-probe-note "reader-printer" "symbol-tokens"
    "(VALUE TYPE NAME): a#b a[b] a:b |a b| a.b a'b a,b -- one symbol, several tokens, or an error?")
  (cad-probe--rp "(cad-probe--rp-typed (read \"a#b\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"a[b]\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"a:b\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"|a b|\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"a.b\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"a'b\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"a,b\"))")
  (cad-probe--rp "(cad-probe--rp-typed (read \"Ab\"))")
  (cad-probe--rp "(read \"(a.b)\")")
  (cad-probe--rp "(read \"(a . b)\")")

  ;; --- string-literal escapes (READ) ---------------------------------------
  ;; the body is BUILT: (chr 92) is the backslash
  (cad-probe-note "reader-printer" "string-escapes"
    "READ of \"A<escape>B\" as character codes: octal \\101, \\x41, \\u0041, \\e \\n \\t \\\\ \\\", unknown \\q")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) \"101B\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) \"x41B\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) \"u0041B\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) \"eB\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) \"nB\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) \"tB\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) \"rB\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) (chr 92) \"B\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) (chr 34) \"B\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) \"qB\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) \"0B\"))")
  (cad-probe--rp "(cad-probe--rp-read-string (strcat \"A\" (chr 92) \"377B\"))")

  ;; --- PRIN1 escapes, and READ of what PRIN1 wrote ---------------------------
  (cad-probe-note "reader-printer" "prin1-escapes"
    "(PRINTED-CODES READ-GIVES-IT-BACK) of PRIN1 on control chars, quote, backslash, non-ASCII, astral")
  (cad-probe--rp "(cad-probe--rp-print (chr 7))")
  (cad-probe--rp "(cad-probe--rp-print (chr 9))")
  (cad-probe--rp "(cad-probe--rp-print (chr 10))")
  (cad-probe--rp "(cad-probe--rp-print (chr 13))")
  (cad-probe--rp "(cad-probe--rp-print (chr 27))")
  (cad-probe--rp "(cad-probe--rp-print (chr 127))")
  (cad-probe--rp "(cad-probe--rp-print (chr 34))")
  (cad-probe--rp "(cad-probe--rp-print (chr 92))")
  (cad-probe--rp "(cad-probe--rp-print (strcat \"a\" (chr 34) \"b\" (chr 92) \"c\"))")
  (cad-probe--rp "(cad-probe--rp-print (chr 233))")
  (cad-probe--rp "(cad-probe--rp-print (chr 8364))")
  (cad-probe--rp "(cad-probe--rp-print (chr 128512))")
  (cad-probe--rp "(cad-probe--rp-print \"\")")
  (princ))
