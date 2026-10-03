;;;; probes/sources/probe-block-walk.lsp
;;;;
;;;; The four SPEC-UNCERTAIN choices vla-entity-property-bridge left behind
;;;; (issues/open/deferred-spec-research.issue, "Entity COM properties and
;;;; the block walk"), batched in one scenario as that ticket suggests:
;;;; build a block, insert it, walk it, read the properties back.
;;;;
;;;;   1. entmakex on a BLOCK / LINE / ENDBLK definition: what each returns
;;;;      (an ename? the ENDBLK's -- an ename, the name, nil?).
;;;;   2. the entnext walk from the block header: does it return the ENDBLK
;;;;      entity itself before ending, or stop at the last member?
;;;;   3. Name vs EffectiveName of a reference to an ORDINARY block (they
;;;;      should agree; a DYNAMIC block cannot be built from AutoLISP, so
;;;;      that half stays a documented limit).
;;;;   4. text width: GetBoundingBox (ActiveX) and TEXTBOX (plain AutoLISP)
;;;;      for a wide and a narrow string in the current style, height 1 --
;;;;      the real font's width per character.
;;;;
;;;; Every case runs under vl-catch-all-apply (cad-probe-capture): on a host
;;;; without the ActiveX layer -- accoreconsole -- the vla cases record an
;;;; `error' and the AutoLISP ones still answer. Values are recorded as
;;;; portable types (type names, strings, numbers), never as raw enames.

(defun cad-probe--kind (x)
  ;; The type of X as a string, "NIL" for nil.
  (if x (vl-symbol-name (type x)) "NIL"))

(defun cad-probe--block-name ()
  ;; A name no earlier run of this suite has used in this drawing.
  (strcat "PRBLK" (itoa (rem (fix (* 86400000.0 (- (getvar "DATE") (fix (getvar "DATE"))))) 100000000))))

(defun cad-probe-run-block-walk-probes ( / name hdr ins txt-wide txt-narrow)
  (setq name (cad-probe--block-name))

  ;; 1. entmakex on the definition, one call per entity.
  (cad-probe-capture "block-walk" "entmakex BLOCK returns"
    (function (lambda ()
      (cad-probe--kind
        (entmakex (list '(0 . "BLOCK") (cons 2 name) '(70 . 0) '(10 0.0 0.0 0.0)))))))
  (cad-probe-capture "block-walk" "entmakex LINE inside the definition returns"
    (function (lambda ()
      (cad-probe--kind
        (entmakex (list '(0 . "LINE") '(8 . "0") '(10 0.0 0.0 0.0) '(11 1.0 1.0 0.0)))))))
  (cad-probe-capture "block-walk" "entmakex ENDBLK returns (type)"
    (function (lambda ()
      (setq cad-probe--endblk (entmakex '((0 . "ENDBLK"))))
      (cad-probe--kind cad-probe--endblk))))
  (cad-probe-capture "block-walk" "entmakex ENDBLK returns (value when a string)"
    (function (lambda ()
      (if (= (type cad-probe--endblk) 'STR) cad-probe--endblk "not a string"))))
  (cad-probe-capture "block-walk" "the block definition exists afterwards"
    (function (lambda () (if (tblsearch "BLOCK" name) "yes" "no"))))

  ;; 2. The entnext walk from the block header.
  (cad-probe-capture "block-walk" "entnext walk from the header: entity types"
    (function (lambda ( / e types)
      (setq e (entnext (tblobjname "BLOCK" name)))
      (while e
        (setq types (cons (cdr (assoc 0 (entget e))) types))
        (setq e (entnext e)))
      (reverse types))))

  ;; 3. Name / EffectiveName of a reference to the ordinary block.
  (setq ins (entmakex (list '(0 . "INSERT") (cons 2 name) '(10 0.0 0.0 0.0))))
  (cad-probe-capture "block-walk" "INSERT of the block (type)"
    (function (lambda () (cad-probe--kind ins))))
  (cad-probe-capture "block-walk" "vla Name of the INSERT is the block name"
    (function (lambda ()
      (vl-load-com)
      (if (= (vla-get-Name (vlax-ename->vla-object ins)) name) "yes" "no"))))
  (cad-probe-capture "block-walk" "vla EffectiveName of the INSERT is the block name"
    (function (lambda ()
      (vl-load-com)
      (if (= (vla-get-EffectiveName (vlax-ename->vla-object ins)) name) "yes" "no"))))

  ;; 4. Text width in the current style, height 1.
  (setq txt-wide (entmakex '((0 . "TEXT") (8 . "0") (10 0.0 0.0 0.0) (40 . 1.0) (1 . "MMMMMMMMMM"))))
  (setq txt-narrow (entmakex '((0 . "TEXT") (8 . "0") (10 0.0 0.0 0.0) (40 . 1.0) (1 . "iiiiiiiiii"))))
  (cad-probe-capture "block-walk" "current text style"
    (function (lambda () (getvar "TEXTSTYLE"))))
  (cad-probe-capture "block-walk" "textbox of 10 x M, height 1"
    (function (lambda () (textbox (entget txt-wide)))))
  (cad-probe-capture "block-walk" "textbox of 10 x i, height 1"
    (function (lambda () (textbox (entget txt-narrow)))))
  (cad-probe-capture "block-walk" "GetBoundingBox of 10 x M, height 1"
    (function (lambda ( / mn mx)
      (vl-load-com)
      (vla-GetBoundingBox (vlax-ename->vla-object txt-wide) 'mn 'mx)
      (list (vlax-safearray->list mn) (vlax-safearray->list mx)))))
  (cad-probe-capture "block-walk" "GetBoundingBox of 10 x i, height 1"
    (function (lambda ( / mn mx)
      (vl-load-com)
      (vla-GetBoundingBox (vlax-ename->vla-object txt-narrow) 'mn 'mx)
      (list (vlax-safearray->list mn) (vlax-safearray->list mx)))))

  ;; 5. The default font's width per character: TEXTBOX of each printable
  ;; ASCII character repeated ten times, height 1, in the current style. A
  ;; per-character table replaces clautolisp's single 0.6 ratio, which
  ;; measures M and i alike. Ten copies so inter-character spacing counts.
  (cad-probe-run-text-metrics)
  (princ))

(defun cad-probe-run-text-metrics ( / code s)
  (setq code 32)
  (while (<= code 126)
    (setq s (strcat (chr code) (chr code) (chr code) (chr code) (chr code)
                    (chr code) (chr code) (chr code) (chr code) (chr code)))
    (cad-probe-capture "text-metrics" (strcat "textbox 10 x char " (itoa code))
      (function (lambda ()
        (textbox (list '(0 . "TEXT") '(10 0.0 0.0 0.0) '(40 . 1.0) (cons 1 s))))))
    (setq code (1+ code)))
  ;; and EVERY single character, which separates the glyph from its spacing:
  ;; 10 copies give 9 advances + the last glyph's ink, 1 copy the ink alone.
  (setq code 32)
  (while (<= code 126)
    (cad-probe-capture "text-metrics" (strcat "textbox 1 x char " (itoa code))
      (function (lambda ()
        (textbox (list '(0 . "TEXT") '(10 0.0 0.0 0.0) '(40 . 1.0) (cons 1 (chr code)))))))
    (setq code (1+ code)))
  ;; kerning: does a pair measure less than its two advances?
  (foreach s (list "AV" "VA" "To" "AA" "VV" "oo")
    (cad-probe-capture "text-metrics" (strcat "textbox pair " s)
      (function (lambda ()
        (textbox (list '(0 . "TEXT") '(10 0.0 0.0 0.0) '(40 . 1.0) (cons 1 s)))))))
  (princ))
