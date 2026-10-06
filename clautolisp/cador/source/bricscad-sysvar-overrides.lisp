(in-package #:clautolisp.cador)

;;;; BricsCAD-dialect sysvar overlay.
;;;;
;;;; cador's sysvar catalogue (sysvar-catalogue.lisp) is
;;;; generated from the AutoCAD-2026 system-variables inventory, so by
;;;; default `clautolisp --bricscad` reports the *AutoCAD* sysvar set —
;;;; every dialect answers GETVAR identically (see
;;;; issues/open/bricscad-dialect-sysvar-parity.issue). This overlay
;;;; specialises the table for the bricscad dialect at launch time.
;;;;
;;;; Phase 1 (this file) covers *existence* only: the variables BricsCAD
;;;; does not define are dropped from the table, so GETVAR returns nil and
;;;; SETVAR signals unknown-sysvar — matching a real BricsCAD. Existence
;;;; is locale-, profile-, platform- and drawing-independent, so it is the
;;;; one class we can adopt unconditionally from a single probe.
;;;;
;;;; NOT touched here, by design:
;;;;   - engine identity (PROGRAM / VENDORNAME / PLATFORM / ACADVER /
;;;;     PRODUCT) — clautolisp keeps its own identity, stamped by
;;;;     APPLY-CLAUTOLISP-HOST-IDENTITY;
;;;;   - dynamic state (SYSCODEPAGE / DWGCODEPAGE / DATE / CDATE /
;;;;     MILLISECS / ERRNO …) — already computed live;
;;;;   - the genuine static *value* differences (factory defaults that
;;;;     BricsCAD and AutoCAD set differently) — deferred until they can
;;;;     be re-harvested from a *pristine* BricsCAD profile rather than a
;;;;     customised session. The data shape below already accommodates
;;;;     them (a :VALUE override), so Phase 2 only adds rows.
;;;;
;;;; Provenance of *BRICSCAD-ABSENT-SYSVARS*
;;;; ---------------------------------------
;;;; The 382 names below are the INTERSECTION of two independent sources:
;;;;   (a) the inventory's per-variable  :versions (… :bricscad nil)
;;;;       marker (autolisp-spec/.../system-variables-inventory.sexp);
;;;;   (b) a live `alfe --bricscad` probe of BricsCAD V26 on macOS that
;;;;       returned nil for the variable
;;;;       (sysvars-alfe-Darwin-bricscad.txt).
;;;; Requiring agreement keeps out the 39 inventory rows the V26 probe
;;;; contradicts (e.g. 3DOSMODE, BPARAMETERFONT — BricsCAD *does* define
;;;; them; the inventory marker is stale) and the 98 probe-nil rows the
;;;; inventory still lists for BricsCAD (edition-/platform-specific
;;;; absences we must not assume hold on every BricsCAD build). Both
;;;; residues are tracked in the issue.
;;;;
;;;; 2026-10-05: 8 names were taken out of this list -- APPAUTOLOAD CLAYOUT
;;;; PDFSHXBESTFONT PDFSHXLAYER PDFSHXTHRESHOLD SPLDEGREE SPLKNOTS SPLMETHOD:
;;;; BricsCAD V26 defines them (macOS harvest, job 16913315157), V25 does not
;;;; (Windows harvest, job 16921381045, ACADVER "25.0 BricsCAD"). They are
;;;; V26 additions, dropped for the V25 dialects only
;;;; (*BRICSCAD-V25-ABSENT-SYSVARS*).

(defparameter *bricscad-absent-sysvars*
  '(
    "3DCONVERSIONMODE" "3DDWFPREC" "3DSELECTIONMODE"
    "ACTIVITYINSIGHTSPATH" "ACTIVITYINSIGHTSSTATE" "ACTIVITYINSIGHTSSUPPORT"
    "ACTIVITYINSIGHTSVIEWEDLOGGING" "ACTPATH" "ACTRECORDERSTATE"
    "ACTRECPATH" "ACTUI" "ADCSTATE"
    "ANNOSCALEZOOM" "APPLYGLOBALOPACITIES"
    "APSTATE" "ASSISTANTSTATE" "ATTIPE"
    "ATTMULTI" "AUTODWFPUBLISH" "AUTOMATICPUB"
    "AUTOPLACEMENT" "BCONSTATUSMODE" "BCONVERTLAYER"
    "BGCOREPUBLISH" "BLOCKCREATEMODE" "BLOCKEXCLUDECOLOR"
    "BLOCKINCLUDECOLOR" "BLOCKMRULIST" "BLOCKNAVIGATE"
    "BLOCKREDEFINEMODE" "BLOCKSDATACOLLECTION" "BLOCKSRECENTFOLDER"
    "BLOCKSTATE" "BLOCKSYNCFOLDER" "BLOCKTARGETCOLOR"
    "BSEARCHINCLUDEEXISTINGBLOCKS" "CACHEMAXFILES" "CACHEMAXTOTALSIZE"
    "CALCINPUT" "CAPTURETHUMBNAILS" "CBARTRANSPARENCY"
    "CCONSTRAINTFORM" "CMDINPUTHISTORYMAX"
    "CMFADECOLOR" "CMFADEOPACITY" "CMOSNAP"
    "COMMANDMACROSSTATE" "COMMENTHIGHLIGHT" "COMPARECOLOR1"
    "COMPARECOLOR2" "COMPARECOLORCOMMON" "COMPAREFRONT"
    "COMPAREHATCH" "COMPAREPROPS" "COMPARERCMARGIN"
    "COMPARERCSHAPE" "COMPARESHOW1" "COMPARESHOW2"
    "COMPARESHOWCOMMON" "COMPARESHOWCONTEXT" "COMPARESHOWRC"
    "COMPARETEXT" "COMPARETOLERANCE" "COMPLEXLTPREVIEW"
    "CONSTRAINTBARMODE" "CONSTRAINTINFER" "CONSTRAINTNAMEFORMAT"
    "CONSTRAINTSOLVEMODE" "COUNTCHECK" "COUNTCOLOR"
    "COUNTERRORCOLOR" "COUNTERRORNUM" "COUNTNUMBER"
    "COUNTPALETTESTATE" "COUNTSERVICE" "CULLINGOBJ"
    "CULLINGOBJSELECTION" "CURSORBADGE" "CURSORTYPE"
    "CVIEWDETAILSTYLE" "DEFAULTGIZMO" "DEFAULTLIGHTINGTYPE"
    "DGNIMPORTMAX" "DGNIMPORTMODE" "DGNMAPPINGPATH"
    "DIMCONSTRAINTICON" "DIMPICKBOX" "DIMTXTRULER"
    "DISPSILHBLOCKS" "DIVMESHBOXHEIGHT" "DIVMESHBOXLENGTH"
    "DIVMESHBOXWIDTH" "DIVMESHCONEAXIS" "DIVMESHCONEBASE"
    "DIVMESHCONEHEIGHT" "DIVMESHCYLAXIS" "DIVMESHCYLBASE"
    "DIVMESHCYLHEIGHT" "DIVMESHPYRBASE" "DIVMESHPYRHEIGHT"
    "DIVMESHPYRLENGTH" "DIVMESHSPHEREAXIS" "DIVMESHSPHEREHEIGHT"
    "DIVMESHTORUSPATH" "DIVMESHTORUSSECTION" "DIVMESHWEDGEBASE"
    "DIVMESHWEDGEHEIGHT" "DIVMESHWEDGELENGTH" "DIVMESHWEDGESLOPE"
    "DIVMESHWEDGEWIDTH" "DRAGVS" "DRSTATE"
    "DX12FRAMERATEUNLIMITED" "DYNPIFORMAT" "DYNPIVIS"
    "DYNPROMPT" "DYNTOOLTIPS" "ENABLESYNCPDF"
    "ENTERPRISEMENU" "ERHIGHLIGHT" "ERSTATE"
    "EXPORTEPLOTFORMAT" "EXPVALUE" "EXPWHITEBALANCE"
    "FACETERDEVNORMAL" "FACETERDEVSURFACE" "FACETERMAXEDGELENGTH"
    "FACETERMAXGRID" "FACETERMESHTYPE" "FACETERMINVGRID"
    "FACETERPRIMITIVEMODE" "FACETERSMOOTHLEV" "FASTSHADEDMODE"
    "FILETABPREVIEW" "FILETABSTATE" "FILETABTHUMBHOVER"
    "FILLETPOLYARC" "FULLPLOTPATH" "GALLERYVIEW"
    "GEOLOCATEMODE" "GEOMARKPOSITIONSIZE" "GLOBALOPACITY"
    "GRIPCONTOUR" "GRIPSUBOBJMODE" "GTAUTO"
    "GTDEFAULT" "GTLOCATION" "HELPPREFIX"
    "HPDLGMODE" "HPDRAWMODE" "HPISLANDDETECTIONMODE"
    "HPPATHALIGNMENT" "HPPATHWIDTH" "HPPICKMODE"
    "HPQUICKPREVTIMEOUT" "IBLENVIRONMENT" "IMAGEASYNC"
    "IMPLIEDFACE" "INPUTHISTORYMODE" "INTELLIGENTUPDATE"
    "JIGZOOMMAX" "JIGZOOMMIN" "LARGEOBJECTSUPPORT"
    "LAYERDLGMODE" "LAYEREVAL" "LAYERFILTERALERT"
    "LAYERMANAGERSTATE" "LAYERNOTIFY" "LAYEROVERRIDEHIGHLIGHT"
    "LAYOUTCREATEVIEWPORT" "LEGACYCTRLPICK" "LIGHTSINBLOCKS"
    "LINEFADING" "LINEFADINGLEVEL" "MACROINSIGHTSSUPPORT"
    "MACRONOTIFY" "MARKUPASSISTMODE" "MARKUPPAPERDISPLAY"
    "MARKUPPAPERTRANSPARENCY" "MARKUPSELECTIONMODE" "MATBROWSERSTATE"
    "MATEDITORSTATE" "MAXINTERSECTIONCURVEPOINTS" "MLEADERLAYER"
    "MSMSTATE" "MTEXTEDENCODING" "MTJIGSTRING"
    "MVIEWPREVIEW" "NAVSWHEELMODE" "NAVSWHEELOPACITYBIG"
    "NAVSWHEELOPACITYMINI" "NAVSWHEELSIZEBIG" "NAVSWHEELSIZEMINI"
    "NAVVCUBESIZE" "OSNAPNODELEGACY" "OSNAPOVERRIDE"
    "PALETTEOPAQUE" "PARAMETERSSTATUS" "PASTESPECMODE"
    "PCMSTATE" "PDFIMPORTFILTER" "PDFIMPORTLAYERS"
    "PDFIMPORTMODE" 
    "PERSPECTIVECLIP" "PLACEMENTSWITCH"
    "PLINEGCENMAX" "PLOTOFFSET" "POINTCLOUDAUTOUPDATE"
    "POINTCLOUDCACHESIZE" "POINTCLOUDCLIPFRAME" "POINTCLOUDDENSITY"
    "POINTCLOUDLIGHTING" "POINTCLOUDLIGHTSOURCE" "POINTCLOUDLOCK"
    "POINTCLOUDLOD" "POINTCLOUDPOINTMAXLEGACY" "POINTCLOUDRTDENSITY"
    "POINTCLOUDSHADING" "POINTCLOUDVISRETAIN" "PREVIEWCREATIONTRANSPARENCY"
    "PROJECTAWARE" "PUBLISHHATCH" "PUSHTODOCSSTATE"
    "QCSTATE" "QPLOCATION" "QPMODE"
    "QVDRAWINGPIN" "QVLAYOUTPIN" "RASTERDPI"
    "RASTERPERCENT" "RASTERTHRESHOLD" "REBUILD2DCV"
    "REBUILD2DDEGREE" "REBUILD2DOPTION" "REBUILDDEGREEU"
    "REBUILDDEGREEV" "REBUILDOPTIONS" "REBUILDU"
    "REBUILDV" "RECOVERAUTO" "RECOVERYMODE"
    "RENDERENVSTATE" "RENDERLEVEL" "RENDERLIGHTCALC"
    "RENDERPREFSSTATE" "RENDERTARGET" "RENDERTIME"
    "RENDERUSERLIGHTS" "REPORTERROR" "REVCLOUDAPPROXARCLEN"
    "REVCLOUDARCVARIANCE" "REVCLOUDLAYER" "REVCLOUDSCALEMODE"
    "RIBBONBGLOAD" "RIBBONCONTEXTSELLIM" "RIBBONICONRESIZE"
    "RTREGENAUTO" "SECTIONOFFSETINC" "SECTIONTHICKNESSINC"
    "SECUREREMOTEACCESS" "SELECTIONEFFECT" "SELECTIONEFFECTCOLOR"
    "SELECTIONOFFSCREEN" "SELECTIONPREVIEWLIMIT" "SHAREDVIEWSTATE"
    "SHAREVIEWPROPERTIES" "SHAREVIEWTYPE" "SHOWHIST"
    "SHOWNEWSTATE" "SHOWPALETTESTATE" "SMOOTHMESHGRID"
    "SMOOTHMESHMAXFACE" "SMOOTHMESHMAXLEV" "SNAPGRIDLEGACY"
    "SOLIDHIST" "SORTORDER" "SPACESWITCH"
    "SPLPERIODIC" "SSMOPENMODE" "STARTINFOLDER"
    "STUDENTDRAWING" "STYLUSFORCETHRESHOLD" "SUBOBJSELECTIONMODE"
    "SUNPROPERTIESSTATE" "SURFACEASSOCIATIVITY" "SURFACEASSOCIATIVITYDRAG"
    "SURFACEAUTOTRIM" "SURFACEMODELINGMODE" "SYSFLOATING"
    "SYSMON" "TABLEINDICATOR" "TABLELAYER"
    "TABLETOOLBAR" "TBCUSTOMIZE" "TBSHOWSHORTCUTS"
    "TEMPOVERRIDES" "TEXTALIGNMODE" "TEXTALIGNSPACING"
    "TEXTALLCAPS" "TEXTAUTOCORRECTCAPS" "TEXTGAPSELECTION"
    "TEXTJUSTIFY" "TEXTLAYER" "TEXTOUTPUTFILEFORMAT"
    "TEXTTOATTRIBUTE" "THUMBSAVE" "THUMBSIZE2D"
    "TOOLTIPMERGE" "TOOLTIPTRANSPARENCY" "TOUCHMODE"
    "TRACECURRENT" "TRACEDISPLAYMODE" "TRACEFADECTL"
    "TRACEMARKUPFADECTL" "TRACEMODE" "TRACEOSNAP"
    "TRACEPALETTESTATE" "TRACEPAPERCTL" "TRACEVPSUPPORT"
    "UCS2DDISPLAYSETTING" "UCS3DPARADISPLAYSETTING" "UCS3DPERPDISPLAYSETTING"
    "UCSSELECTMODE" "UOSNAP" "UPDATETHUMBNAIL"
    "VIEWBACKSTATUS" "VIEWFWDSTATUS" "VIEWPORTLAYER"
    "VIEWSKETCHMODE" "VISRETAINMODE" "VPCONTROL"
    "VPLAYEROVERRIDES" "VSACURVATUREHIGH" "VSACURVATURELOW"
    "VSACURVATURETYPE" "VSADRAFTANGLEHIGH" "VSAZEBRACOLOR1"
    "VSAZEBRACOLOR2" "VSAZEBRADIRECTION" "VSAZEBRASIZE"
    "VSAZEBRATYPE" "VSBACKGROUNDS" "VSEDGECOLOR"
    "VSEDGEJITTER" "VSEDGELEX" "VSEDGES"
    "VSEDGESMOOTH" "VSFACECOLORMODE" "VSFACEHIGHLIGHT"
    "VSFACEOPACITY" "VSHALOGAP" "VSINTERSECTIONCOLOR"
    "VSINTERSECTIONEDGES" "VSINTERSECTIONLTYPE" "VSISOONTOP"
    "VSLIGHTINGQUALITY" "VSMATERIALMODE" "VSMONOCOLOR"
    "VSOCCLUDEDCOLOR" "VSOCCLUDEDEDGES" "VSOCCLUDEDLTYPE"
    "VSSHADOWS" "VSSILHEDGES" "VSSILHWIDTH"
    "VSSTATE" "WBLOCKCREATEMODE" "WORKINGFOLDER"
    "WORKSPACELABEL" "XCOMPAREBAKPATH" "XCOMPAREBAKSIZE"
    "XCOMPARECOLORMODE" "XCOMPAREENABLE" "XREFLAYER"
    "XREFREGAPPCTL")
  "The 382 catalogue sysvars BricsCAD V26 does not define, confirmed by
both the inventory's :bricscad version marker and a live BricsCAD V26
probe. Dropped from the host table under the bricscad dialect so GETVAR
returns nil. See the file header for provenance.")

;;;; Phase 2 — factory-default value overlay
;;;; ----------------------------------------
;;;; Beyond *existence* (Phase 1), BricsCAD sets a number of *shared*
;;;; sysvars to different factory defaults than AutoCAD (the issue's
;;;; "174 genuine value disagreements"). Each such divergence is one row
;;;; here: (SYSVAR-NAME-STRING . VALUE). At launch, under the bricscad
;;;; dialect only, APPLY-BRICSCAD-DIALECT-SYSVARS pushes VALUE into that
;;;; sysvar's catalogue cell (via HOST-SET-DERIVED-SYSVAR, which coerces
;;;; to the cell's kind, bypasses the read-only flag for host-populated
;;;; cells, and silently no-ops on names the catalogue does not carry).
;;;;
;;;; SEEDED EMPTY on purpose. The only BricsCAD reference dump we have is
;;;; a customised / French-locale / metric session (see the issue's
;;;; "IMPORTANT caveat"): its values conflate real factory defaults with
;;;; locale, loaded-template and profile state, so bulk-importing them
;;;; would ship wrong defaults. Populating this table requires a CLEAN
;;;; re-harvest — a pristine BricsCAD profile plus a freshly-created
;;;; default drawing — classified with scripts/classify-sysvar-diff.py.
;;;; See the "Phase 2 runbook" in
;;;; issues/open/bricscad-dialect-sysvar-parity.issue. Do NOT invent
;;;; values: leave this empty until the pristine-profile dump is
;;;; classified and human-vetted for locale/template rows.

(defparameter *bricscad-v25-absent-sysvars*
  '("APPAUTOLOAD" "CLAYOUT" "PDFSHXBESTFONT" "PDFSHXLAYER" "PDFSHXTHRESHOLD"
    "SPLDEGREE" "SPLKNOTS" "SPLMETHOD")
  "Sysvars BricsCAD V26 defines and V25 does not (V26 macOS harvest job
16913315157 vs V25 Windows harvest job 16921381045): dropped under a BricsCAD
dialect of version 25 or older, kept from V26.")

(defparameter *bricscad-factory-defaults*
  ;; ADOPTED 2026-10-03 from harvest:sysvars:bricscad:macos (job
  ;; 16913315157, BricsCAD V26 macOS, profile <<Profil sans nom>>), vetted
  ;; row by row: only sysvars saved in the REGISTRY / preferences (never a
  ;; drawing-saved one: the reference drawing came from a French metric
  ;; template), never locale, identity, session or window state, and ONLY
  ;; where the measured value equals the BricsCAD default the vendor
  ;; documentation states (system-variables-inventory.sexp :divergence).
  ;; Two independent sources per row. 32 more registry rows matched no
  ;; documented default and are left out -- see bricscad-dialect-sysvar-
  ;; parity.issue, "Phase 2 harvest (2026-10-03)".
  '(
    ("AUTOSNAP" . 127)
    ("CLIPROMPTLINES" . 4)
    ("CROSSINGAREACOLOR" . 91)
    ("DELOBJ" . 1)
    ("DRAGP1" . 10)
    ("DRAGP2" . 25)
    ("DWGCHECK" . 0)
    ("FONTMAP" . "default.fmp")
    ;; 2026-10-05 (probe-triage3 repr + both harvests, V25 Windows / V26 macOS):
    ;; BricsCAD's own values where AutoCAD's differ or are doc text.
    ("INETLOCATION" . "http://www.bricsys.com")
    ("INTERFERECOLOR" . "BYLAYER")
    ("RULERTEXTCOLOR" . "#C8C8C8")
    ("HORIZONBKG_GROUNDHORIZON" . "#434A50")
    ("HORIZONBKG_GROUNDORIGIN" . "#5F6770")
    ("HORIZONBKG_SKYHIGH" . "#CCE5EA")
    ("HORIZONBKG_SKYHORIZON" . "#EEF8FA")
    ("HORIZONBKG_SKYLOW" . "#EEF8FA")
    ("GRIPHOT" . 240)
    ("GRIPHOVER" . 150)
    ("GRIPSIZE" . 4)
    ("HPMAXAREAS" . 0)
    ("HPOBJWARNING" . 10000)
    ("INSUNITSDEFSOURCE" . 0)
    ("INSUNITSDEFTARGET" . 0)
    ("MAXSORT" . 200)
    ("MENUBAR" . 1)
    ("MTEXTCOLUMN" . 0)
    ("NAVVCUBEORIENT" . 0)
    ("OSMODE" . 4135)
    ("PARAMETERCOPYMODE" . 3)
    ("PICKADD" . 1)
    ("PICKBOX" . 4)
    ("PICKDRAG" . 0)
    ("POLARMODE" . 1)
    ("PROPOBJLIMIT" . 1000)
    ("PUBLISHCOLLATE" . 0)
    ("REVCLOUDMAXARCLENGTH" . 0.375d0)
    ("REVCLOUDMINARCLENGTH" . 0.375d0)
    ("RIBBONDOCKEDHEIGHT" . 0)
    ("RTDISPLAY" . 0)
    ("SAVETIME" . 20)
    ("SMOOTHMESHCONVERT" . 2)
    ("SNAPTYPE" . 2)
    ("SSMPOLLTIME" . 15)
    ("UCSORTHO" . 0)
    ("WHIPARC" . 1)
    ("WHIPTHREAD" . 0)
    ("XDWGFADECTL" . 70)
    ("XFADECTL" . 50)
    ("XLOADCTL" . 1)
    ("XREFNOTIFY" . 1)
    ("ZOOMFACTOR" . 40)
    ;; ADOPTED 2026-10-04: 26 of the 32 registry rows above that matched no
    ;; documented default, now with a SECOND, independent measurement --
    ;; harvest:sysvars:bricscad:windows (job 16921381045, BricsCAD V26 on
    ;; the Windows runner) agrees with the macOS harvest. The 6 that differ
    ;; between the two platforms are left out (3DOSMODE 11/10,
    ;; COMMANDASSIST 1/0, CROSSHAIRDRAWMODE 3/2, GLSWAPMODE 0/2, MTFLAGS
    ;; 2048/3015, USECOMMUNICATOR 0/1).
    ("BPARAMETERFONT" . "simplex.shx")
    ("CLIPBOARDFORMAT" . 1)
    ("DEFLPLSTYLE" . "ByColor")
    ("DRAWINGVIEWPRESET" . "None")
    ("DYNINFOTIPS" . 0)
    ("EXPORTGEOMETRYFLAGS" . 12)
    ("GEOLATLONGFORMAT" . 1)
    ("GRIDMAJORCOLOR" . 251)
    ("GROUPDISPLAYMODE" . 0)
    ("HPQUICKPREVIEW" . 0)
    ("LAYEREVALCTL" . 0)
    ("LAYERPMODE" . 1)
    ("LOOKFROMZOOMEXTENTS" . 1)
    ("MTEXTTOOLBAR" . 1)
    ("NAVBARDISPLAY" . 0)
    ("PDFIMAGECOMPRESSION" . 0)
    ("PDFIMPORTJOINLINEANDARCSEGMENTS" . 1)
    ("PDFSHX" . 0)
    ("PREVIEWWNDINOPENDLG" . 1)
    ("RIBBONSELECTMODE" . 0)
    ("RIBBONSTATE" . 1)
    ("SELECTIONCYCLING" . 2)
    ("SMROLLEDEDGELINESDOWNLAYERLINETYPE" . "CONTINUOUS")
    ("SMROLLEDEDGELINESUPLAYERLINETYPE" . "CONTINUOUS")
    ("SMSMARTFEATURES" . 7)
    ("USENEWSTATUSBAR" . 1)
    ;; LISPSYS 0 on both BricsCAD V26 harvests (the documentation states no
    ;; default; dialect-platform-version-axis, 2026-10-04).
    ("LISPSYS" . 0)
    )
  "Alist of (SYSVAR-NAME-STRING . VALUE) BricsCAD factory-default value
overrides, applied to the AutoCAD-derived catalogue under the bricscad
dialect only. Rows naming an unknown or BricsCAD-absent sysvar are skipped
harmlessly.")

(defparameter *bricscad-platform-factory-defaults*
  ;; The registry rows the two BricsCAD harvests (V26 macOS job 16913315157,
  ;; V25 Windows job 16921381045) both answered but with DIFFERENT values: a
  ;; platform default each, applied by the dialect's platform facet
  ;; (bricscad-mac -> :macos; bricscad, bricscad-v26 -> :windows; Linux not
  ;; measured -> none).
  ;; CAVEAT (2026-10-05): the Windows harvest is BricsCAD V25 (ACADVER "25.0
  ;; BricsCAD"), not V26 as first recorded, so each difference may be the
  ;; VERSION rather than the platform; a V26 Windows harvest would tell.
  '((:macos ("3DOSMODE" . 11) ("COMMANDASSIST" . 1) ("CROSSHAIRDRAWMODE" . 3)
            ("GLSWAPMODE" . 0) ("MTFLAGS" . 2048) ("USECOMMUNICATOR" . 0))
    (:windows ("3DOSMODE" . 10) ("COMMANDASSIST" . 0) ("CROSSHAIRDRAWMODE" . 2)
              ("GLSWAPMODE" . 2) ("MTFLAGS" . 3015) ("USECOMMUNICATOR" . 1)))
  "Platform -> (SYSVAR . VALUE) BricsCAD factory defaults that differ by OS.")

(defun %current-dialect-version ()
  (let ((dialect (ignore-errors (clautolisp.autolisp-runtime:current-evaluation-dialect))))
    (and dialect
         (ignore-errors (clautolisp.autolisp-reader:autolisp-dialect-version dialect)))))

(defun %current-dialect-platform ()
  (let ((dialect (ignore-errors (clautolisp.autolisp-runtime:current-evaluation-dialect))))
    (and dialect
         (ignore-errors (clautolisp.autolisp-reader:autolisp-dialect-platform dialect)))))

(defparameter *bricscad-writable-sysvars*
  ;; Read-only in the catalogue (AutoCAD's), settable on BricsCAD -- measured:
  ;; (setvar "SDI" 1) => 1, read back 1, on V25 Windows and V26 macOS
  ;; (probe-conformance E8); AutoCAD 2022 rejects it.
  '("SDI"))

(defun apply-bricscad-dialect-sysvars (host)
  "Launch-time bricscad-dialect sysvar overlay. Two effects, both
bricscad-dialect only, never touching autocad/clautolisp:

  Phase 1 (existence): drop the catalogue entries BricsCAD does not
  define from HOST, so GETVAR on them returns nil and SETVAR signals
  unknown-sysvar, as on a real BricsCAD.

  Phase 2 (factory defaults): for each (NAME . VALUE) row in
  *BRICSCAD-FACTORY-DEFAULTS*, override that sysvar's catalogue default
  cell with VALUE. Applied AFTER the removals, so a row that happens to
  name a dropped sysvar simply no-ops (HOST-SET-DERIVED-SYSVAR skips
  unknown names). Empty until the clean harvest, so this is inert today.

cador only; no-ops on hosts without a sysvar table. Returns HOST."
  (when host
    (dolist (name *bricscad-absent-sysvars*)
      (clautolisp.autolisp-host:host-undefine-sysvar host name))
    (let ((version (%current-dialect-version)))
      (when (and (integerp version) (<= version 25))
        (dolist (name *bricscad-v25-absent-sysvars*)
          (clautolisp.autolisp-host:host-undefine-sysvar host name))))
    (dolist (row *bricscad-factory-defaults*)
      ;; HOST-SET-DERIVED-SYSVAR coerces to the cell's kind, bypasses the
      ;; read-only flag (these are host-populated defaults), and silently
      ;; no-ops when the name is absent/unknown — so an unknown or
      ;; just-dropped name is skipped without error.
      (clautolisp.autolisp-host:host-set-derived-sysvar
       host (car row) (cdr row)))
    (dolist (row (rest (assoc (%current-dialect-platform) *bricscad-platform-factory-defaults*)))
      (clautolisp.autolisp-host:host-set-derived-sysvar host (car row) (cdr row)))
    (dolist (name *bricscad-writable-sysvars*)
      (let ((cell (ignore-errors (cador-sysvar host name))))
        (when cell (setf (sysvar-cell-read-only-p cell) nil)))))
  host)
