;;;; block-comment-probe.lsp -- VERIFY that alfe's CAD-side loader treats an
;;;; AutoLISP ;| ... |; block comment as a comment on the real CADs
;;;; (issues/open/alfe-cad-source-loader-evaluates-block-comments.issue).
;;;;
;;;; alfe does not load an -l file with the CAD's own LOAD: its CAD-side
;;;; loader splits the file into top-level forms itself, and up to alfe 2.3.12
;;;; it knew only the line comment, so the lines of a block comment after the
;;;; first were read as code (SCHMS job 529707: `no function definition:
;;;; SYMBOLE'). Every (boom) below sits in a comment; if one is evaluated the
;;;; load fails there and BLKC-DONE is never printed.
;;;;
;;;; Output, one line per observation:
;;;;   BLKC <case> <ran|...>    a form around a comment ran
;;;;   BLKC-VALUES <a b c d e>  the variables the forms set (expected 1..5)
;;;;   BLKC-DONE
;;;; Keep this file ASCII.

;| @Global
  Nom d'une cle de propriete (symbole ou autre valeur), en majuscules.
  @Param key A: cle lue dans la liste de proprietes ; "quote ( paren
  @Returns string: par exemple ":OWN-LIST"
|;
(setq blkc-a nil blkc-b nil blkc-c nil blkc-d nil blkc-e nil)
(princ "BLKC leading-doc-block ran\n")
(setq blkc-a 1) ;| inline (boom) |; (setq blkc-b 2)
(princ "BLKC string-delimiters ;| not a comment |;\n")
(setq blkc-c ;| inside a form (boom) |; 3)
;| several
(boom)
|; (princ "BLKC after-multiline-block ran\n")
(princ "BLKC same-line-1 ran\n");|between (boom)|;(princ "BLKC same-line-2 ran\n")
(setq blkc-d 4) ;| opened after a form
(boom)
|;
; a line comment ;| does not open a block
(setq blkc-e 5)
(princ (strcat "BLKC-VALUES "
               (vl-princ-to-string (list blkc-a blkc-b blkc-c blkc-d blkc-e))
               "\n"))
(princ "BLKC-DONE\n")
(princ)
