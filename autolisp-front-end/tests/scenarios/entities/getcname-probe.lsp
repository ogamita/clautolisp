;;;; getcname-probe.lsp -- harvest the localised CAD COMMAND NAMES a real,
;;;; localised AutoCAD/BricsCAD install knows, for cadtui's locale dictionaries
;;;; (issues/open/cadtui-locale-probe-getcname).
;;;;
;;;; This CANNOT be produced headless in clautolisp: getcname is a nil stub
;;;; there, so a --clautolisp run only proves the probe itself is well-formed
;;;; (every line ABSENT + the DONE sentinel). The payload comes from a localised
;;;; real CAD -- the runners' BricsCAD is a French install, so getcname there
;;;; returns the real fr_FR names (spec autolisp getcname page: (getcname
;;;; "_STRETCH") => "ETIRER", (getcname "ETIRER") => "_STRETCH").
;;;;
;;;; getcname is symmetric: give it either form, get the other. We know the
;;;; INTERNATIONAL (canonical English) names a priori, so for each we call
;;;;   (getcname "_NAME")            international -> local
;;;; and, when that yields a string, the round trip
;;;;   (getcname <local>)            local -> international
;;;; which must return "_NAME" on a correct install (a mismatch is itself data).
;;;;
;;;; Output, one line per call, tab-separated:
;;;;   GETCNAME    <input>   <status>   <result>      ; international -> local
;;;;   GETCNAME-RT <local>   <status>   <result>      ; local -> international
;;;; status: VALUE (a string came back), IDENTITY (result = input sans the
;;;; leading _, i.e. an English install or an untranslated command), ABSENT
;;;; (nil -- the clautolisp stub, or a command this engine does not know),
;;;; ERROR. The converter (scripts/cadtui-getcname-to-sexp.py) keeps only the
;;;; VALUE lines whose round trip closes.

;; International (canonical English) command names common to AutoCAD & BricsCAD.
;; A curated common set first (the issue: scope narrowly, expand later); the
;; converter and the fr_FR dictionary grow as this list does.
(setq *getcname-commands*
  (list
    "LINE" "XLINE" "RAY" "PLINE" "POLYGON" "RECTANG" "ARC" "CIRCLE"
    "SPLINE" "ELLIPSE" "POINT" "DONUT" "REVCLOUD" "MLINE" "SKETCH"
    "HATCH" "GRADIENT" "BOUNDARY" "REGION" "WIPEOUT" "SOLID"
    "TEXT" "MTEXT" "DTEXT" "TABLE" "FIELD" "SPELL"
    "DIMLINEAR" "DIMALIGNED" "DIMANGULAR" "DIMRADIUS" "DIMDIAMETER"
    "DIMBASELINE" "DIMCONTINUE" "DIMORDINATE" "LEADER" "MLEADER"
    "ERASE" "COPY" "MIRROR" "OFFSET" "ARRAY" "MOVE" "ROTATE" "SCALE"
    "STRETCH" "LENGTHEN" "TRIM" "EXTEND" "BREAK" "JOIN" "CHAMFER"
    "FILLET" "BLEND" "EXPLODE" "ALIGN" "PEDIT" "SPLINEDIT"
    "BLOCK" "WBLOCK" "INSERT" "MINSERT" "XREF" "XATTACH" "XBIND"
    "BEDIT" "REFEDIT" "ATTDEF" "ATTEDIT" "EATTEDIT" "PURGE"
    "LAYER" "LINETYPE" "COLOR" "LTSCALE" "PROPERTIES" "MATCHPROP"
    "STYLE" "DIMSTYLE" "TABLESTYLE" "MLSTYLE" "UNITS" "GROUP"
    "NEW" "OPEN" "CLOSE" "SAVE" "QSAVE" "SAVEAS" "QUIT" "EXPORT"
    "IMPORT" "PLOT" "PREVIEW" "PAGESETUP" "PUBLISH" "RECOVER" "AUDIT"
    "ZOOM" "PAN" "REGEN" "REDRAW" "VIEW" "VPORTS" "REDRAWALL"
    "UNDO" "REDO" "OOPS" "DIST" "AREA" "ID" "LIST" "MASSPROP"
    "MEASURE" "DIVIDE" "OSNAP" "SNAP" "GRID" "ORTHO" "LIMITS"
    "MODEL" "LAYOUT" "MVIEW" "MSPACE" "PSPACE" "SCALELISTEDIT"
    "3DORBIT" "EXTRUDE" "REVOLVE" "SWEEP" "LOFT" "UNION"
    "SUBTRACT" "INTERSECT" "SLICE" "SECTION" "BOX" "SPHERE"
    "CYLINDER" "CONE" "WEDGE" "TORUS" "RENDER"))

(defun getcname-of (input / v)
  "Call getcname on INPUT under an error guard; return (status . result) where
status is a string and result the returned name or an error message."
  (setq v (vl-catch-all-apply 'getcname (list input)))
  (cond
    ((vl-catch-all-error-p v) (cons "ERROR" (vl-catch-all-error-message v)))
    ((null v)                 (cons "ABSENT" ""))
    ((not (eq (type v) 'STR)) (cons "NONSTRING" (vl-princ-to-string v)))
    (t                        (cons "VALUE" v))))

(defun strip-underscore (s)
  (if (and (> (strlen s) 0) (= (substr s 1 1) "_")) (substr s 2) s))

(defun probe-one (name / intl sr status local rt)
  (setq intl (strcat "_" name))
  (setq sr (getcname-of intl) status (car sr) local (cdr sr))
  ;; IDENTITY: the engine returned the English name unchanged (no localisation).
  (if (and (= status "VALUE") (= (strcase local) (strcase name)))
      (setq status "IDENTITY"))
  (princ (strcat "GETCNAME\t" intl "\t" status "\t" local "\n"))
  ;; Round trip only when a distinct local name came back.
  (if (= status "VALUE")
      (progn
        (setq rt (getcname-of local))
        (princ (strcat "GETCNAME-RT\t" local "\t" (car rt) "\t" (cdr rt) "\n"))))
  nil)

;; Engine identity + LOCALE first, so a report is never ambiguous about who
;; produced it or in which language.
(princ (strcat "GETCNAME-ENGINE\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "PROGRAM")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "ACADVER")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "PLATFORM")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "LOCALE")))
               "\n"))
(princ (strcat "GETCNAME-COUNT\t" (itoa (length *getcname-commands*)) "\n"))
(foreach n *getcname-commands* (probe-one n))
(princ "GETCNAME-DONE\n")
(princ)
