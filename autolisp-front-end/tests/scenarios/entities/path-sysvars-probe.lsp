;;;; path-sysvars-probe.lsp -- read every path-carrying system variable and
;;;; report what this engine actually holds.
;;;;
;;;; bricscad-sysvars-on-macos.issue.  The inventory marks most of these
;;;; :host-specific, so the catalogue shows "" -- which means NOBODY MEASURED
;;;; THEM, not that they are empty on a real CAD.  This is the measurement.
;;;;
;;;; Run against BricsCAD (macOS and Windows), AutoCAD GUI and AcCoreConsole
;;;; (Windows).  The last two are run separately ON PURPOSE: the headless
;;;; engine may not populate what the GUI does, and that difference is itself
;;;; a finding -- a sysvar only the GUI fills is one clautolisp has no reason
;;;; to imitate.
;;;;
;;;; Output, one line per variable, tab-separated so it parses without
;;;; guessing where a Windows path with spaces ends:
;;;;
;;;;   PATHSYSVAR <name> <status> <value>
;;;;
;;;; status is ABSENT when getvar returns nil (the engine does not define it),
;;;; EMPTY when it returns the empty string, and VALUE otherwise.  The three
;;;; are NOT the same thing and the table needs to tell them apart.

(setq *path-sysvars*
  (list
    "ACADPREFIX" "ACTIVITYINSIGHTSPATH" "ACTPATH"
    "ACTRECPATH" "BASEFILE" "BIMDEFAULTPROPERTIESPATH"
    "BLOCKSPATH" "BLOCKSRECENTFOLDER" "BLOCKSYNCFOLDER"
    "BMFORMTEMPLATEPATH" "BMTOOLPATH" "CENTERLTYPEFILE"
    "CLOUDDOWNLOADPATH" "CLOUDTEMPFOLDER" "COLORBOOKPATH"
    "COMMUNICATORPATH" "COMPONENTSPATH" "CPROFILE"
    "CVERSIONCONTROLPATH" "DETAILSPATH" "DGNMAPPINGPATH"
    "DRAWINGPATH" "DWGPREFIX" "FBXEXPORTTEXTURESPATH"
    "HELPPREFIX" "IFCEXPORTMAPPINGPATH" "IMAGECACHEFOLDER"
    "INETLOCATION" "LOCALROOTPREFIX" "LOGFILEPATH"
    "MYDOCUMENTSPREFIX" "PARAMETRICBLOCKS2DPATH" "PDFIMPORTIMAGEPATH"
    "PLOTCFGPATH" "PLOTOUTPUTPATH" "PLOTSTYLEPATH"
    "POINTCLOUDCACHEFOLDER" "PRINTFILE" "RECENTPATH"
    "RENDERMATERIALSPATH" "ROAMABLEROOTPREFIX" "SAVEFILE"
    "SAVEFILEPATH" "SECTIONSETTINGSSEARCHPATH" "SHEETSETTEMPLATEPATH"
    "SRCHPATH" "STARTINFOLDER" "TEMPLATEPATH"
    "TEMPPREFIX" "TEXTUREMAPPATH" "TOOLPALETTEPATH"
    "VERSIONCONTROLCONFIGPATH" "VERSIONCONTROLDOWNLOADPATH" "WORKINGFOLDER"
    "XCOMPAREBAKPATH" "XLOADPATH" "_TOOLPALETTEPATH"
    ))

(defun probe-one (name / v)
  (setq v (vl-catch-all-apply 'getvar (list name)))
  (cond
    ((vl-catch-all-error-p v)
     (princ (strcat "PATHSYSVAR\t" name "\tERROR\t"
                    (vl-catch-all-error-message v))))
    ((null v)      (princ (strcat "PATHSYSVAR\t" name "\tABSENT\t")))
    ((not (eq (type v) 'STR))
     (princ (strcat "PATHSYSVAR\t" name "\tNONSTRING\t" (vl-princ-to-string v))))
    ((= v "")      (princ (strcat "PATHSYSVAR\t" name "\tEMPTY\t")))
    (t             (princ (strcat "PATHSYSVAR\t" name "\tVALUE\t" v))))
  (princ "\n")
  nil)

;; Engine identity first, so a report is never ambiguous about who produced it.
(princ (strcat "PATHSYSVAR-ENGINE\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "PROGRAM")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "ACADVER")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "PLATFORM")))
               "\n"))
(princ (strcat "PATHSYSVAR-COUNT\t" (itoa (length *path-sysvars*)) "\n"))
(foreach n *path-sysvars* (probe-one n))
(princ "PATHSYSVAR-DONE\n")
(princ)
