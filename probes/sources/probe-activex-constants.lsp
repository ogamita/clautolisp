;;;; probes/sources/probe-activex-constants.lsp
;;;;
;;;; The ActiveX enumeration constants (acAlignmentMiddleLeft, acByLayer,
;;;; acLnWt025, ...) the vendors expose to AutoLISP with COM support
;;;; (cador-activex-enumeration-constants-unbound.issue, 2026-10-06). One
;;;; suite, activex-constants:
;;;;   - before (vl-load-com): are they bound already?  Only meaningful when
;;;;     this suite runs alone (PROBE_SUITES=activex-constants): other suites
;;;;     call (vl-load-com) before it in a normal run, and BricsCAD's own
;;;;     vle-extension.lsp calls it at startup;
;;;;   - after (vl-load-com): (boundp value) of every constant of the four
;;;;     families clautolisp binds (AcAlignment, AcAttributeMode, AcColor,
;;;;     AcLineWeight), the case naming the documented value;
;;;;   - a user binding across a second (vl-load-com): kept or reset? a name
;;;;     set to nil: rebound?  (acRed is restored afterwards);
;;;;   - the inventory: (boundp value) of every name in BricsCAD's list of AC
;;;;     constants (DevRef "AC... (constants) functions", V14, 934 names), so
;;;;     the families clautolisp does not bind yet can be read off a run.
;;;; Every step under VL-CATCH-ALL-APPLY. Pure ASCII.

(defun cad-probe--acx-show (cad-probe--acx-thunk / r)
  (setq r (vl-catch-all-apply cad-probe--acx-thunk '()))
  (if (vl-catch-all-error-p r)
      (strcat "ERROR " (vl-catch-all-error-message r))
      r))

;; Distinct parameter names throughout: AutoLISP binds dynamically, and a
;; wrapper's free THUNK would resolve to the callee's own parameter.
(defun cad-probe--acx (name cad-probe--acx-fn)
  (cad-probe-capture "activex-constants" name
    (function (lambda () (cad-probe--acx-show cad-probe--acx-fn)))))

(defun cad-probe--acx-state (cad-probe--acx-sym)
  ;; (boundp value) of the symbol.
  (list (if (boundp cad-probe--acx-sym) T nil) (eval cad-probe--acx-sym)))

(setq cad-probe--acx-families
  '(
    ("AcAlignment" (acAlignmentLeft . 0) (acAlignmentCenter . 1)
      (acAlignmentRight . 2) (acAlignmentAligned . 3) (acAlignmentMiddle . 4)
      (acAlignmentFit . 5) (acAlignmentTopLeft . 6) (acAlignmentTopCenter . 7)
      (acAlignmentTopRight . 8) (acAlignmentMiddleLeft . 9)
      (acAlignmentMiddleCenter . 10) (acAlignmentMiddleRight . 11)
      (acAlignmentBottomLeft . 12) (acAlignmentBottomCenter . 13)
      (acAlignmentBottomRight . 14))
    ("AcAttributeMode" (acAttributeModeNormal . 0)
      (acAttributeModeInvisible . 1) (acAttributeModeConstant . 2)
      (acAttributeModeVerify . 4) (acAttributeModePreset . 8)
      (acAttributeModeLockPosition . 16) (acAttributeModeMultipleLine . 32))
    ("AcColor" (acByBlock . 0) (acRed . 1) (acYellow . 2) (acGreen . 3)
      (acCyan . 4) (acBlue . 5) (acMagenta . 6) (acWhite . 7)
      (acByLayer . 256))
    ("AcLineWeight" (acLnWt000 . 0) (acLnWt005 . 5) (acLnWt009 . 9)
      (acLnWt013 . 13) (acLnWt015 . 15) (acLnWt018 . 18) (acLnWt020 . 20)
      (acLnWt025 . 25) (acLnWt030 . 30) (acLnWt035 . 35) (acLnWt040 . 40)
      (acLnWt050 . 50) (acLnWt053 . 53) (acLnWt060 . 60) (acLnWt070 . 70)
      (acLnWt080 . 80) (acLnWt090 . 90) (acLnWt100 . 100) (acLnWt106 . 106)
      (acLnWt120 . 120) (acLnWt140 . 140) (acLnWt158 . 158) (acLnWt200 . 200)
      (acLnWt211 . 211) (acLnWtByLayer . -1) (acLnWtByBlock . -2)
      (acLnWtByLwDefault . -3))
   ))

(setq cad-probe--acx-inventory
  '(
    ac0degrees ac1_1 ac1_10 ac1_100 ac1_128in_1ft ac1_16 ac1_16in_1ft ac1_2
    ac1_20 ac1_2in_1ft ac1_30 ac1_32in_1ft ac1_4 ac1_40 ac1_4in_1ft ac1_50
    ac1_64in_1ft ac1_8 ac1_8in_1ft ac10_1 ac100_1 ac180degrees ac1ft_1ft
    ac1in_1ft ac2_1 ac2000_dwg ac2000_dxf ac2000_template ac2004_dwg
    ac2004_dxf ac2004_template ac2007_dwg ac2007_dxf ac2007_template
    ac270degrees ac3_16in_1ft ac3_32in_1ft ac3_4in_1ft ac3_8in_1ft ac3dface
    ac3dpolyline ac3dsolid ac3in_1ft ac4_1 ac6in_1ft ac8_1 ac90degrees acabove
    acactiveviewport acalignmentaligned acalignmentbottomcenter
    acalignmentbottomleft acalignmentbottomright acalignmentcenter
    acalignmentfit acalignmentleft acalignmentmiddle acalignmentmiddlecenter
    acalignmentmiddleleft acalignmentmiddleright acalignmentproperty
    acalignmentright acalignmenttopcenter acalignmenttopleft
    acalignmenttopright acalignpntacquisitionautomatic
    acalignpntacquisitionshifttoacquire acallcellproperties acallnormal
    acallviewports acalwaysrightreadingangle acangular acany acapplied acarc
    acarchitectural acarea acarrowarchtick acarrowboxblank acarrowboxfilled
    acarrowclosed acarrowclosedblank acarrowdatumblank acarrowdatumfilled
    acarrowdefault acarrowdot acarrowdotblank acarrowdotsmall acarrowintegral
    acarrownone acarrowoblique acarrowopen acarrowopen30 acarrowopen90
    acarroworigin acarroworigin2 acarrowsmall acarrowsonly acarrowuserdefined
    acattachmentallline acattachmentbottomline acattachmentbottomofbottom
    acattachmentbottomoftop acattachmentbottomoftopline acattachmentmiddle
    acattachmentmiddleofbottom acattachmentmiddleoftop
    acattachmentpointbottomcenter acattachmentpointbottomleft
    acattachmentpointbottomright acattachmentpointmiddlecenter
    acattachmentpointmiddleleft acattachmentpointmiddleright
    acattachmentpointtopcenter acattachmentpointtopleft
    acattachmentpointtopright acattachmenttopoftop acattribute
    acattributemodeconstant acattributemodeinvisible
    acattributemodelockposition acattributemodemultipleline
    acattributemodenormal acattributemodepreset acattributemodeverify
    acattributereference acautoscale acbackgroundcolor acbasemenugroup
    acbestfit acbeziersurfacemesh acbitproperties acblockbox acblockcell
    acblockcircle acblockcontent acblockhexagon acblockimperial
    acblockreference acblockslot acblocktriangle acblockuserdefined acblue
    acbottom acbottomcenter acbottomleft acbottommask acbottomright
    acbottomtotop acbuffer acbyblock acbylayer acbystyle
    accastsandreceivesshadows accastsshadows acccw accellalign
    accellbackgroundcolor accellbackgroundfillnone accellbottomgridcolor
    accellbottomgridlineweight accellbottomvisibility accellcontentcolor
    accellcontentlayoutflow accellcontentlayoutstackedhorizontal
    accellcontentlayoutstackedvertical accellcontenttypeblock
    accellcontenttypefield accellcontenttypeunknown accellcontenttypevalue
    accelldatatype accellleftgridcolor accellleftgridlineweight
    accellleftvisibility accellmarginbottom accellmarginhorzspacing
    accellmarginleft accellmarginright accellmargintop accellmarginvertspacing
    accellrightgridcolor accellrightgridlineweight accellrightvisibility
    accellstatecontentlocked accellstatecontentmodified
    accellstatecontentreadonly accellstateformatlocked
    accellstateformatmodified accellstateformatreadonly accellstatelinked
    accellstatenone accelltextheight accelltextstyle accelltopgridcolor
    accelltopgridlineweight accelltopvisibility accenteralignment accenterline
    accentermark accenternone accircle accolormethodbyaci accolormethodbyblock
    accolormethodbylayer accolormethodbyrgb accolormethodforeground
    acconnectbase acconnectextents accontentcolor accontentlayout
    accontentproperties accubicspline3dpoly accubicsplinepoly
    accubicsurfacemesh accw accyan acdataformat acdatahorzbottomcolor
    acdatahorzbottomlineweight acdatahorzbottomvisibility
    acdatahorzinsidecolor acdatahorzinsidelineweight
    acdatahorzinsidevisibility acdatahorztopcolor acdatahorztoplineweight
    acdatahorztopvisibility acdatarow acdatarowalignment acdatarowcolor
    acdatarowdatatype acdatarowfillcolor acdatarowfillnone acdatarowtextheight
    acdatarowtextstyle acdatatype acdatatypeandformat acdatavertinsidecolor
    acdatavertinsidelineweight acdatavertinsidevisibility acdatavertleftcolor
    acdatavertleftlineweight acdatavertleftvisibility acdatavertrightcolor
    acdatavertrightlineweight acdatavertrightvisibility acdate acdecimal
    acdefaultunits acdegreeminuteseconds acdegrees acdegrees000 acdegrees090
    acdegrees15 acdegrees180 acdegrees270 acdegrees30 acdegrees45 acdegrees60
    acdegrees90 acdegreesany acdegreeshorz acdegreesunknown
    acdemandloadcmdinvoke acdemandloaddisabled acdemandloadenabled
    acdemandloadenabledwithcopy acdemandloadonobjectdetect acdemanloaddisable
    acdgnunderlay acdiagonal acdim3pointangular acdimaligned acdimangular
    acdimarchitectural acdimarchitecturalstacked acdimarclength acdimdecimal
    acdimdiametric acdimenableupdate acdimengineering acdimfractional
    acdimfractionalstacked acdimlarchitectural acdimldecimal acdimlengineering
    acdimlfractional acdimlinewithtext acdimlscientific acdimlwindowsdesktop
    acdimordinate acdimprecisioneight acdimprecisionfive acdimprecisionfour
    acdimprecisionone acdimprecisionseven acdimprecisionsix
    acdimprecisionthree acdimprecisiontwo acdimprecisionzero acdimradial
    acdimradiallarge acdimrotated acdimscientific acdimwindowsdesktop
    acdisplay acdisplaydcs acdistance acdouble acdragdisplayautomatically
    acdragdisplayonrequest acdragdonotdisplay acdrawcontentfirst
    acdrawleaderfirst acdrawleaderheadfirst acdrawleadertailfirst
    acdwfunderlay acedrepeatlastcommand acedscm acellipse
    acenablebackgroundcolor acenablescm acenablescmoptions acendsnormal
    acengineering acenglish acenter acextendboth acextendnone
    acextendotherentity acextendthisentity acextents acexternalreference
    acfalse acfirstextensionline acfirstnormal acfitcurvepoly acflowdirbtot
    acflowdirection acfontbold acfontbolditalic acfontitalic acfontregular
    acforediting acforexpression acfractional acfullpreview acgeneral
    acgradientobject acgrads acgreen acgridlinestyledouble
    acgridlinestylesingle acgroup achatch achatchlooptypedefault
    achatchlooptypederived achatchlooptypeexternal achatchlooptypepolyline
    achatchlooptypetextbox achatchobject achatchpatterntypecustomdefined
    achatchpatterntypepredefined achatchpatterntypeuserdefined
    achatchstyleignore achatchstylenormal achatchstyleouter
    acheaderhorzbottomcolor acheaderhorzbottomlineweight
    acheaderhorzbottomvisibility acheaderhorzinsidecolor
    acheaderhorzinsidelineweight acheaderhorzinsidevisibility
    acheaderhorztopcolor acheaderhorztoplineweight acheaderhorztopvisibility
    acheaderrow acheaderrowalignment acheaderrowcolor acheaderrowdatatype
    acheaderrowfillcolor acheaderrowfillnone acheaderrowtextheight
    acheaderrowtextstyle acheadersuppressed acheadervertinsidecolor
    acheadervertinsidelineweight acheadervertinsidevisibility
    acheadervertleftcolor acheadervertleftlineweight
    acheadervertleftvisibility acheadervertrightcolor
    acheadervertrightlineweight acheadervertrightvisibility acheight
    achorizontal achorizontalalignmentaligned achorizontalalignmentcenter
    achorizontalalignmentfit achorizontalalignmentleft
    achorizontalalignmentmiddle achorizontalalignmentright achorizontalangle
    achorzbottom achorzcellmargin achorzcentered achorzinside achorztop
    acignoremtextformat acignoreshadows acinches acinsertangle
    acinsertunitsangstroms acinsertunitsastronomicalunits
    acinsertunitsautoassign acinsertunitscentimeters acinsertunitsdecameters
    acinsertunitsdecimeters acinsertunitsfeet acinsertunitsgigameters
    acinsertunitshectometers acinsertunitsinches acinsertunitskilometers
    acinsertunitslightyears acinsertunitsmeters acinsertunitsmicroinches
    acinsertunitsmicrons acinsertunitsmiles acinsertunitsmillimeters
    acinsertunitsmils acinsertunitsnanometers acinsertunitsparsecs
    acinsertunitsprompt acinsertunitsunitless acinsertunitsyards
    acintersection acinvalidcellproperty acinvalidgridline acinvisibleleader
    acjis ackeyboardentry ackeyboardentryexceptscripts
    ackeyboardrunningobjsnap aclastnormal aclayout acleader acleftalignment
    acleftmask aclefttoright aclimits acline aclinenoarrow
    aclinespacingstyleatleast aclinespacingstyleexactly aclinewitharrow
    aclnwt000 aclnwt005 aclnwt009 aclnwt013 aclnwt015 aclnwt018 aclnwt020
    aclnwt025 aclnwt030 aclnwt035 aclnwt040 aclnwt050 aclnwt053 aclnwt060
    aclnwt070 aclnwt080 aclnwt090 aclnwt100 aclnwt106 aclnwt120 aclnwt140
    aclnwt158 aclnwt200 aclnwt211 aclnwtbyblock aclnwtbylayer
    aclnwtbylwdefault aclock aclong aclsall aclscolor aclsfrozen aclslinetype
    aclslineweight aclslocked aclsnewviewport aclsnone aclson aclsplot
    aclsplotstyle acmagenta acmarginbottom acmarginleft acmarginright
    acmargintop acmax acmenufilecompiled acmenufilesource acmenuitem
    acmenuseparator acmenusubmenu acmergeall
    acmergecellstyleconvertduplicatestooverrides
    acmergecellstylecopyduplicates acmergecellstyleignorenewstyles
    acmergecellstylenone acmergecellstyleoverwriteduplicates acmetric
    acmiddlecenter acmiddleleft acmiddleright acmillimeters acmin
    acminsertblock acmleader acmline acmodelspace acmovetextaddleader
    acmovetextnoleader acmtext acmtextcontent acnative
    acnodrawingareashortcutmenu acnonecontent acnooverrides acnorm
    acnotstacked acnounits acobjectid acocs acoff acon acopqhighgraphics
    acopqlowgraphics acopqmonochrome acoqgraphics acoqhighphoto acoqlineart
    acoqphoto acoqtext acotembedded acotlink acotstatic acoutside
    acoverfirstextension acoversecondextension acpalettebydrawing
    acpalettebysession acpaperspace acpaperspacedcs acparseoptionnone
    acpartialmenugroup acpartialpreview acpenwidth013 acpenwidth018
    acpenwidth025 acpenwidth035 acpenwidth050 acpenwidth070 acpenwidth100
    acpenwidth140 acpenwidth200 acpenwidthunk acpixels
    acplotorientationlandscape acplotorientationportrait acpoint acpoint2d
    acpoint3d acpolicylegacy acpolicylegacydefault acpolicylegacylegacy
    acpolicylegacyquery acpolicynamed acpolicynewdefault acpolicynewlegacy
    acpolyfacemesh acpolyline acpolylinelight acpolymesh acpredefinedgradient
    acpreferenceclassic acpreferencecustom acpreservemtextformat
    acprinteralertonce acprinteralwaysalert acprinterneveralert
    acprinterneveralertlogonce acproxyboundingbox acproxynotshow acproxyshow
    acpviewport acquadspline3dpoly acquadsplinepoly acquadsurfacemesh
    acr12_dxf acr13_dwg acr13_dxf acr14_dwg acr14_dxf acr15_dwg acr15_dxf
    acr15_template acr18_dwg acr18_dxf acr18_template acradians acraster acray
    acreceivesshadows acred acregion acrepeatlastcommand acresbuf
    acrightalignment acrightmask acrighttoleft acrotation acruled acscale
    acscaletofit acscientific acscm acsecondextensionline
    acsectiongenerationdestinationfile acsectiongenerationdestinationnewblock
    acsectiongenerationdestinationreplaceblock
    acsectiongenerationsourceallobjects
    acsectiongenerationsourceselectedobjects acsectionstateboundary
    acsectionstateplane acsectionstatevolume acsectionsubitembackline
    acsectionsubitembacklinebottom acsectionsubitembacklinetop
    acsectionsubitemknone acsectionsubitemsectionline
    acsectionsubitemsectionlinebottom acsectionsubitemsectionlinetop
    acsectionsubitemverticallinebottom acsectionsubitemverticallinetop
    acsectiontype2dsection acsectiontype3dsection acsectiontypelivesection
    acselectionsetall acselectionsetcrossing acselectionsetcrossingpolygon
    acselectionsetfence acselectionsetlast acselectionsetprevious
    acselectionsetwindow acselectionsetwindowpolygon acsetdefaultformat
    acshadeplotasdisplayed acshadeplothidden acshadeplotrendered
    acshadeplotwireframe acshape acsimple3dpoly acsimplemesh acsimplepoly
    acsmooth acsolid acspline acsplineleader acsplinenoarrow acsplinewitharrow
    acstraightleader acstring acsubtraction acsymabove acsyminfront acsymnone
    actable actablebottomtotop actableflowdownorup actableflowleft
    actableflowright actableselectcrossing actableselectwindow
    actabletoptobottom actext actextandarrows actextcell actextflagbackward
    actextflagupsidedown actextheight actextonly actextstyle action_tile
    actitlehorzbottomcolor actitlehorzbottomlineweight
    actitlehorzbottomvisibility actitlehorzinsidecolor
    actitlehorzinsidelineweight actitlehorzinsidevisibility
    actitlehorztopcolor actitlehorztoplineweight actitlehorztopvisibility
    actitlerow actitlerowalignment actitlerowcolor actitlerowdatatype
    actitlerowfillcolor actitlerowfillnone actitlerowtextheight
    actitlerowtextstyle actitlesuppressed actitlevertinsidecolor
    actitlevertinsidelineweight actitlevertinsidevisibility
    actitlevertleftcolor actitlevertleftlineweight actitlevertleftvisibility
    actitlevertrightcolor actitlevertrightlineweight
    actitlevertrightvisibility actolbasic actolbottom actoldeviation
    actolerance actollimits actolmiddle actolnone actolsymmetrical actoltop
    actoolbarbutton actoolbarcontrol actoolbardockbottom actoolbardockleft
    actoolbardockright actoolbardocktop actoolbarfloating actoolbarflyout
    actoolbarseparator actop actopcenter actopleft actopmask actopright
    actoptobottom actrace actrue acturnheight acturns acucs acuniform acunion
    acunitangle acunitarea acunitdistance acunitless acunitvolume acunknown
    acunknowncell acunknowndatatype acunknownrow acupdatedatafromsource
    acupdateoptionincludexrefs acupdateoptionnone
    acupdateoptionoverwritecontentmodifiedafterupdate
    acupdateoptionoverwriteformatmodifiedafterupdate
    acupdateoptionupdatefullsourcerange acupdatesourcefromdata
    acusedefaultdrawingareashortcutmenu acusedraftangles acusemaximumprecision
    acuserdefinedgradient acvertcellmargin acvertcentered
    acverticalalignmentbaseline acverticalalignmentbottom
    acverticalalignmentmiddle acverticalalignmenttop acvertinside acvertleft
    acvertright acview acviewport2horizontal acviewport2vertical
    acviewport3above acviewport3below acviewport3horizontal acviewport3left
    acviewport3right acviewport3vertical acviewport4 acvp1 acvp1_1 acvp1_10
    acvp1_100 acvp1_128in_1ft acvp1_16 acvp1_16in_1ft acvp1_2 acvp1_20
    acvp1_2in_1ft acvp1_30 acvp1_32in_1ft acvp1_4 acvp1_40 acvp1_4in_1ft
    acvp1_50 acvp1_64in_1ft acvp1_8 acvp1_8in_1ft acvp10 acvp10_1 acvp100
    acvp100_1 acvp11 acvp12 acvp13 acvp14 acvp15 acvp16 acvp17 acvp18 acvp19
    acvp1and1_2in_1ft acvp1ft_1ft acvp1in_1ft acvp2 acvp2_1 acvp20 acvp21
    acvp22 acvp23 acvp24 acvp25 acvp26 acvp27 acvp28 acvp29 acvp3
    acvp3_16in_1ft acvp3_32in_1ft acvp3_4in_1ft acvp3_8in_1ft acvp30 acvp31
    acvp32 acvp33 acvp34 acvp35 acvp36 acvp37 acvp38 acvp39 acvp3in_1ft acvp4
    acvp4_1 acvp40 acvp41 acvp42 acvp43 acvp44 acvp45 acvp46 acvp47 acvp48
    acvp49 acvp5 acvp50 acvp51 acvp52 acvp53 acvp54 acvp55 acvp56 acvp57
    acvp58 acvp59 acvp6 acvp60 acvp61 acvp62 acvp63 acvp64 acvp65 acvp66
    acvp67 acvp68 acvp69 acvp6in_1ft acvp7 acvp70 acvp71 acvp72 acvp73 acvp74
    acvp75 acvp76 acvp77 acvp78 acvp79 acvp8 acvp8_1 acvp80 acvp81 acvp82
    acvp83 acvp84 acvp85 acvp86 acvp87 acvp88 acvp89 acvp9 acvp90 acvp91
    acvp92 acvp93 acvp94 acvp95 acvp96 acvp97 acvp98 acvp99 acvpcustomscale
    acvpscaletofit acwhite acwindow acworld acxline acyellow aczero
    aczoomscaledabsolute aczoomscaledrelative aczoomscaledrelativepspace
   ))

(defun cad-probe-run-activex-constants-probes ( / cad-probe--acx-family
                                                   cad-probe--acx-entry
                                                   cad-probe--acx-old)
  ;; --- before ---------------------------------------------------------------
  (cad-probe--acx "before vl-load-com: (boundp value) acAlignmentMiddleLeft"
    (function (lambda () (cad-probe--acx-state 'acAlignmentMiddleLeft))))
  (cad-probe--acx "before vl-load-com: (boundp value) acRed"
    (function (lambda () (cad-probe--acx-state 'acRed))))
  (cad-probe--acx "before vl-load-com: (boundp value) acLnWt025"
    (function (lambda () (cad-probe--acx-state 'acLnWt025))))
  (cad-probe--acx "(vl-load-com)"
    (function (lambda () (vl-load-com))))
  ;; --- the families clautolisp binds ----------------------------------------
  (foreach cad-probe--acx-family cad-probe--acx-families
    (foreach cad-probe--acx-entry (cdr cad-probe--acx-family)
      (cad-probe--acx
        (strcat (car cad-probe--acx-family) " "
                (vl-symbol-name (car cad-probe--acx-entry))
                " (documented " (itoa (cdr cad-probe--acx-entry)) ")")
        (function (lambda () (cad-probe--acx-state (car cad-probe--acx-entry)))))))
  ;; --- user bindings across a second (vl-load-com) --------------------------
  (setq cad-probe--acx-old acRed)
  (cad-probe--acx "(setq acRed 99) (vl-load-com): acRed"
    (function (lambda () (setq acRed 99) (vl-load-com) acRed)))
  (cad-probe--acx "(setq acRed nil) (vl-load-com): acRed"
    (function (lambda () (setq acRed nil) (vl-load-com) acRed)))
  (setq acRed cad-probe--acx-old)
  (cad-probe--acx "restored acRed"
    (function (lambda () acRed)))
  ;; --- the inventory ----------------------------------------------------------
  (foreach cad-probe--acx-entry cad-probe--acx-inventory
    (cad-probe--acx (strcat "inventory " (vl-symbol-name cad-probe--acx-entry))
      (function (lambda () (cad-probe--acx-state cad-probe--acx-entry)))))
  (princ))
