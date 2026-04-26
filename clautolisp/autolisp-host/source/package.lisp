(defpackage #:clautolisp.autolisp-host
  (:use #:cl)
  (:import-from #:clautolisp.autolisp-runtime
                #:signal-autolisp-runtime-error)
  (:export
   ;; Protocol class hierarchy
   #:host
   #:null-host
   #:make-null-host
   #:*null-host*
   #:host-name
   ;; Predicates / introspection
   #:hostp
   ;; --- Entity API (autolisp-spec ch.16) -------------------------
   #:host-entget
   #:host-entmod
   #:host-entmake
   #:host-entmakex
   #:host-entdel
   #:host-entupd
   #:host-entlast
   #:host-entnext
   #:host-handent
   ;; --- Selection-set API ----------------------------------------
   #:host-ssget
   #:host-ssadd
   #:host-ssdel
   #:host-ssname
   #:host-sslength
   #:host-ssmemb
   #:host-ssgetfirst
   #:host-sssetfirst
   ;; --- Symbol tables --------------------------------------------
   #:host-tblsearch
   #:host-tblnext
   #:host-tblobjname
   ;; --- Dictionaries ---------------------------------------------
   #:host-namedobjdict
   #:host-dictsearch
   #:host-dictnext
   #:host-dictadd
   #:host-dictremove
   #:host-dictrename
   ;; --- System variables -----------------------------------------
   #:host-getvar
   #:host-setvar
   ;; --- Command dispatch -----------------------------------------
   #:host-command
   ;; --- Interactive prompts (autolisp-spec ch.18) ---------------
   #:host-prompt
   #:host-initget
   #:host-getstring
   #:host-getint
   #:host-getreal
   #:host-getpoint
   #:host-getcorner
   #:host-getdist
   #:host-getangle
   #:host-getorient
   #:host-getkword
   ;; --- Graphics -------------------------------------------------
   #:host-grdraw
   #:host-grtext
   #:host-grvecs
   #:host-grclear
   #:host-grread
   #:host-redraw))
