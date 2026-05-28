;;;; -*- Mode: Lisp; coding: utf-8 -*-
;;;; tests/sysvar/inventory-coverage.lsp
;;;;
;;;; THIS FILE IS GENERATED. Regenerate by running
;;;;   sbcl --non-interactive --load autolisp-test/tools/generate-sysvar-corpus.lisp \
;;;;        --eval '(generate)'
;;;;
;;;; Source: autolisp-spec/documentation/system-variables-inventory.sexp
;;;; Records: 1836
;;;;
;;;; Per inventory entry we emit:
;;;;   - a sysvar-NAME-getvar-type test asserting (type (getvar "NAME"))
;;;;     matches the inventory's :type field;
;;;;   - a sysvar-NAME-setvar-readonly-signals test for read-only cells,
;;;;     asserting setvar signals :sysvar-read-only;
;;;;   - a sysvar-NAME-getvar-default test asserting the documented
;;;;     default value, but ONLY when the :default is a fixed literal
;;;;     (host-derived markers like (:host-specific) / (:drawing) are
;;;;     not asserted -- the value varies per the vendor docs).
;;;;
;;;; Profile defaults to STRICT for vendor :both / :autocad entries,
;;;; BRICSCAD for vendor :bricscad. Selection happens at run time via
;;;; the harness's --profile flag.

(deftest "sysvar-3dconversionmode-getvar-type"
  '((operator . "3DCONVERSIONMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "3DCONVERSIONMODE"))
  'int)

(deftest "sysvar-3dconversionmode-getvar-default"
  '((operator . "3DCONVERSIONMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "3DCONVERSIONMODE")
  1)

(deftest "sysvar-3ddwfprec-getvar-type"
  '((operator . "3DDWFPREC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "3DDWFPREC"))
  'int)

(deftest "sysvar-3ddwfprec-getvar-default"
  '((operator . "3DDWFPREC") (area . "sysvar") (profile . STRICT))
  '(getvar "3DDWFPREC")
  2)

(deftest "sysvar-3dosmode-getvar-type"
  '((operator . "3DOSMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "3DOSMODE"))
  'int)

(deftest "sysvar-3dosmode-getvar-default"
  '((operator . "3DOSMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "3DOSMODE")
  139)

(deftest "sysvar-3dselectionmode-getvar-type"
  '((operator . "3DSELECTIONMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "3DSELECTIONMODE"))
  'int)

(deftest "sysvar-3dselectionmode-getvar-default"
  '((operator . "3DSELECTIONMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "3DSELECTIONMODE")
  1)

(deftest "sysvar-acadlspasdoc-getvar-type"
  '((operator . "ACADLSPASDOC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACADLSPASDOC"))
  'int)

(deftest "sysvar-acadlspasdoc-getvar-default"
  '((operator . "ACADLSPASDOC") (area . "sysvar") (profile . STRICT))
  '(getvar "ACADLSPASDOC")
  0)

(deftest "sysvar-acadprefix-getvar-type"
  '((operator . "ACADPREFIX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACADPREFIX"))
  'str)

(deftest-error "sysvar-acadprefix-setvar-readonly-signals"
  '((operator . "ACADPREFIX") (area . "sysvar") (profile . STRICT))
  '(setvar "ACADPREFIX" "")
  'sysvar-read-only)

(deftest "sysvar-acadver-getvar-type"
  '((operator . "ACADVER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACADVER"))
  'str)

(deftest-error "sysvar-acadver-setvar-readonly-signals"
  '((operator . "ACADVER") (area . "sysvar") (profile . STRICT))
  '(setvar "ACADVER" "")
  'sysvar-read-only)

(deftest "sysvar-acishlrresolution-getvar-type"
  '((operator . "ACISHLRRESOLUTION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ACISHLRRESOLUTION"))
  'real)

(deftest "sysvar-acishlrresolution-getvar-default"
  '((operator . "ACISHLRRESOLUTION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ACISHLRRESOLUTION")
  -1.0)

(deftest "sysvar-acisoutver-getvar-type"
  '((operator . "ACISOUTVER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACISOUTVER"))
  'int)

(deftest "sysvar-acisoutver-getvar-default"
  '((operator . "ACISOUTVER") (area . "sysvar") (profile . STRICT))
  '(getvar "ACISOUTVER")
  70)

(deftest "sysvar-acissaveasmode-getvar-type"
  '((operator . "ACISSAVEASMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ACISSAVEASMODE"))
  'int)

(deftest "sysvar-acissaveasmode-getvar-default"
  '((operator . "ACISSAVEASMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ACISSAVEASMODE")
  0)

(deftest "sysvar-activityinsightspath-getvar-type"
  '((operator . "ACTIVITYINSIGHTSPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACTIVITYINSIGHTSPATH"))
  'str)

(deftest "sysvar-activityinsightspath-getvar-default"
  '((operator . "ACTIVITYINSIGHTSPATH") (area . "sysvar") (profile . STRICT))
  '(getvar "ACTIVITYINSIGHTSPATH")
  "C:\\Users\\{username}\\AppData\\Local\\Autodesk\\ActivityInsights\\Common")

(deftest "sysvar-activityinsightsstate-getvar-type"
  '((operator . "ACTIVITYINSIGHTSSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACTIVITYINSIGHTSSTATE"))
  'int)

(deftest "sysvar-activityinsightsstate-getvar-default"
  '((operator . "ACTIVITYINSIGHTSSTATE") (area . "sysvar") (profile . STRICT))
  '(getvar "ACTIVITYINSIGHTSSTATE")
  0)

(deftest "sysvar-activityinsightssupport-getvar-type"
  '((operator . "ACTIVITYINSIGHTSSUPPORT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACTIVITYINSIGHTSSUPPORT"))
  'int)

(deftest "sysvar-activityinsightssupport-getvar-default"
  '((operator . "ACTIVITYINSIGHTSSUPPORT") (area . "sysvar") (profile . STRICT))
  '(getvar "ACTIVITYINSIGHTSSUPPORT")
  3)

(deftest "sysvar-activityinsightsviewedlogging-getvar-type"
  '((operator . "ACTIVITYINSIGHTSVIEWEDLOGGING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACTIVITYINSIGHTSVIEWEDLOGGING"))
  'int)

(deftest "sysvar-activityinsightsviewedlogging-getvar-default"
  '((operator . "ACTIVITYINSIGHTSVIEWEDLOGGING") (area . "sysvar") (profile . STRICT))
  '(getvar "ACTIVITYINSIGHTSVIEWEDLOGGING")
  1)

(deftest "sysvar-actpath-getvar-type"
  '((operator . "ACTPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACTPATH"))
  'str)

(deftest "sysvar-actpath-getvar-default"
  '((operator . "ACTPATH") (area . "sysvar") (profile . STRICT))
  '(getvar "ACTPATH")
  "")

(deftest "sysvar-actrecorderstate-getvar-type"
  '((operator . "ACTRECORDERSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACTRECORDERSTATE"))
  'int)

(deftest-error "sysvar-actrecorderstate-setvar-readonly-signals"
  '((operator . "ACTRECORDERSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "ACTRECORDERSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-actrecpath-getvar-type"
  '((operator . "ACTRECPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACTRECPATH"))
  'str)

(deftest "sysvar-actui-getvar-type"
  '((operator . "ACTUI") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ACTUI"))
  'int)

(deftest "sysvar-actui-getvar-default"
  '((operator . "ACTUI") (area . "sysvar") (profile . STRICT))
  '(getvar "ACTUI")
  6)

(deftest "sysvar-adaptivegridstepsize-getvar-type"
  '((operator . "ADAPTIVEGRIDSTEPSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ADAPTIVEGRIDSTEPSIZE"))
  'real)

(deftest "sysvar-adaptivegridstepsize-getvar-default"
  '((operator . "ADAPTIVEGRIDSTEPSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ADAPTIVEGRIDSTEPSIZE")
  4.0)

(deftest "sysvar-adcstate-getvar-type"
  '((operator . "ADCSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ADCSTATE"))
  'int)

(deftest-error "sysvar-adcstate-setvar-readonly-signals"
  '((operator . "ADCSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "ADCSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-aflags-getvar-type"
  '((operator . "AFLAGS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AFLAGS"))
  'int)

(deftest "sysvar-aligndimensiononisometric-getvar-type"
  '((operator . "ALIGNDIMENSIONONISOMETRIC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ALIGNDIMENSIONONISOMETRIC"))
  'int)

(deftest "sysvar-aligndimensiononisometric-getvar-default"
  '((operator . "ALIGNDIMENSIONONISOMETRIC") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ALIGNDIMENSIONONISOMETRIC")
  1)

(deftest "sysvar-allowedbendangles-getvar-type"
  '((operator . "ALLOWEDBENDANGLES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ALLOWEDBENDANGLES"))
  'int)

(deftest "sysvar-allowedbendangles-getvar-default"
  '((operator . "ALLOWEDBENDANGLES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ALLOWEDBENDANGLES")
  1)

(deftest "sysvar-allowtabexternalmove-getvar-type"
  '((operator . "ALLOWTABEXTERNALMOVE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ALLOWTABEXTERNALMOVE"))
  'int)

(deftest "sysvar-allowtabexternalmove-getvar-default"
  '((operator . "ALLOWTABEXTERNALMOVE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ALLOWTABEXTERNALMOVE")
  1)

(deftest "sysvar-allowtabmove-getvar-type"
  '((operator . "ALLOWTABMOVE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ALLOWTABMOVE"))
  'int)

(deftest "sysvar-allowtabmove-getvar-default"
  '((operator . "ALLOWTABMOVE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ALLOWTABMOVE")
  1)

(deftest "sysvar-allowtabsplit-getvar-type"
  '((operator . "ALLOWTABSPLIT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ALLOWTABSPLIT"))
  'int)

(deftest "sysvar-allowtabsplit-getvar-default"
  '((operator . "ALLOWTABSPLIT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ALLOWTABSPLIT")
  1)

(deftest "sysvar-ampowerdimdisplay-getvar-type"
  '((operator . "AMPOWERDIMDISPLAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "AMPOWERDIMDISPLAY"))
  'int)

(deftest "sysvar-ampowerdimdisplay-getvar-default"
  '((operator . "AMPOWERDIMDISPLAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "AMPOWERDIMDISPLAY")
  1)

(deftest "sysvar-amsymscale-getvar-type"
  '((operator . "AMSYMSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AMSYMSCALE"))
  'real)

(deftest "sysvar-amsymscale-getvar-default"
  '((operator . "AMSYMSCALE") (area . "sysvar") (profile . STRICT))
  '(getvar "AMSYMSCALE")
  1.0)

(deftest "sysvar-angbase-getvar-type"
  '((operator . "ANGBASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ANGBASE"))
  'real)

(deftest "sysvar-angdir-getvar-type"
  '((operator . "ANGDIR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ANGDIR"))
  'int)

(deftest "sysvar-angdir-getvar-default"
  '((operator . "ANGDIR") (area . "sysvar") (profile . STRICT))
  '(getvar "ANGDIR")
  0)

(deftest "sysvar-annoallvisible-getvar-type"
  '((operator . "ANNOALLVISIBLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ANNOALLVISIBLE"))
  'int)

(deftest "sysvar-annoautoscale-getvar-type"
  '((operator . "ANNOAUTOSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ANNOAUTOSCALE"))
  'int)

(deftest "sysvar-annomonitor-getvar-type"
  '((operator . "ANNOMONITOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ANNOMONITOR"))
  'int)

(deftest "sysvar-annoscalezoom-getvar-type"
  '((operator . "ANNOSCALEZOOM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ANNOSCALEZOOM"))
  'int)

(deftest "sysvar-annoscalezoom-getvar-default"
  '((operator . "ANNOSCALEZOOM") (area . "sysvar") (profile . STRICT))
  '(getvar "ANNOSCALEZOOM")
  0)

(deftest "sysvar-annotativedwg-getvar-type"
  '((operator . "ANNOTATIVEDWG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ANNOTATIVEDWG"))
  'int)

(deftest "sysvar-annotativedwg-getvar-default"
  '((operator . "ANNOTATIVEDWG") (area . "sysvar") (profile . STRICT))
  '(getvar "ANNOTATIVEDWG")
  0)

(deftest "sysvar-antialiasrender-getvar-type"
  '((operator . "ANTIALIASRENDER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ANTIALIASRENDER"))
  'int)

(deftest "sysvar-antialiasrender-getvar-default"
  '((operator . "ANTIALIASRENDER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ANTIALIASRENDER")
  2)

(deftest "sysvar-antialiasscreen-getvar-type"
  '((operator . "ANTIALIASSCREEN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ANTIALIASSCREEN"))
  'int)

(deftest "sysvar-antialiasscreen-getvar-default"
  '((operator . "ANTIALIASSCREEN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ANTIALIASSCREEN")
  1)

(deftest "sysvar-apbox-getvar-type"
  '((operator . "APBOX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "APBOX"))
  'int)

(deftest "sysvar-apbox-getvar-default"
  '((operator . "APBOX") (area . "sysvar") (profile . STRICT))
  '(getvar "APBOX")
  0)

(deftest "sysvar-aperture-getvar-type"
  '((operator . "APERTURE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "APERTURE"))
  'int)

(deftest "sysvar-appautoload-getvar-type"
  '((operator . "APPAUTOLOAD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "APPAUTOLOAD"))
  'int)

(deftest "sysvar-appautoload-getvar-default"
  '((operator . "APPAUTOLOAD") (area . "sysvar") (profile . STRICT))
  '(getvar "APPAUTOLOAD")
  14)

(deftest "sysvar-applyglobalopacities-getvar-type"
  '((operator . "APPLYGLOBALOPACITIES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "APPLYGLOBALOPACITIES"))
  'int)

(deftest "sysvar-applyglobalopacities-getvar-default"
  '((operator . "APPLYGLOBALOPACITIES") (area . "sysvar") (profile . STRICT))
  '(getvar "APPLYGLOBALOPACITIES")
  0)

(deftest "sysvar-apstate-getvar-type"
  '((operator . "APSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "APSTATE"))
  'int)

(deftest-error "sysvar-apstate-setvar-readonly-signals"
  '((operator . "APSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "APSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-area-getvar-type"
  '((operator . "AREA") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AREA"))
  'real)

(deftest-error "sysvar-area-setvar-readonly-signals"
  '((operator . "AREA") (area . "sysvar") (profile . STRICT))
  '(setvar "AREA" 0.0)
  'sysvar-read-only)

(deftest "sysvar-areaprec-getvar-type"
  '((operator . "AREAPREC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "AREAPREC"))
  'int)

(deftest "sysvar-areaprec-getvar-default"
  '((operator . "AREAPREC") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "AREAPREC")
  -1)

(deftest "sysvar-areaunits-getvar-type"
  '((operator . "AREAUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "AREAUNITS"))
  'str)

(deftest "sysvar-areaunits-getvar-default"
  '((operator . "AREAUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "AREAUNITS")
  "in ft mi µm mm cm m km")

(deftest "sysvar-arrayassociativity-getvar-type"
  '((operator . "ARRAYASSOCIATIVITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ARRAYASSOCIATIVITY"))
  'int)

(deftest "sysvar-arrayassociativity-getvar-default"
  '((operator . "ARRAYASSOCIATIVITY") (area . "sysvar") (profile . STRICT))
  '(getvar "ARRAYASSOCIATIVITY")
  1)

(deftest "sysvar-arrayeditstate-getvar-type"
  '((operator . "ARRAYEDITSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ARRAYEDITSTATE"))
  'int)

(deftest-error "sysvar-arrayeditstate-setvar-readonly-signals"
  '((operator . "ARRAYEDITSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "ARRAYEDITSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-arraytype-getvar-type"
  '((operator . "ARRAYTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ARRAYTYPE"))
  'int)

(deftest "sysvar-assistantstate-getvar-type"
  '((operator . "ASSISTANTSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ASSISTANTSTATE"))
  'int)

(deftest-error "sysvar-assistantstate-setvar-readonly-signals"
  '((operator . "ASSISTANTSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "ASSISTANTSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-attdia-getvar-type"
  '((operator . "ATTDIA") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ATTDIA"))
  'int)

(deftest "sysvar-attdia-getvar-default"
  '((operator . "ATTDIA") (area . "sysvar") (profile . STRICT))
  '(getvar "ATTDIA")
  1)

(deftest "sysvar-attfullupdate-getvar-type"
  '((operator . "ATTFULLUPDATE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ATTFULLUPDATE"))
  'int)

(deftest "sysvar-attfullupdate-getvar-default"
  '((operator . "ATTFULLUPDATE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ATTFULLUPDATE")
  1)

(deftest "sysvar-attipe-getvar-type"
  '((operator . "ATTIPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ATTIPE"))
  'int)

(deftest "sysvar-attipe-getvar-default"
  '((operator . "ATTIPE") (area . "sysvar") (profile . STRICT))
  '(getvar "ATTIPE")
  0)

(deftest "sysvar-attmode-getvar-type"
  '((operator . "ATTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ATTMODE"))
  'int)

(deftest "sysvar-attmulti-getvar-type"
  '((operator . "ATTMULTI") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ATTMULTI"))
  'int)

(deftest "sysvar-attmulti-getvar-default"
  '((operator . "ATTMULTI") (area . "sysvar") (profile . STRICT))
  '(getvar "ATTMULTI")
  1)

(deftest "sysvar-attractiondistance-getvar-type"
  '((operator . "ATTRACTIONDISTANCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ATTRACTIONDISTANCE"))
  'int)

(deftest "sysvar-attractiondistance-getvar-default"
  '((operator . "ATTRACTIONDISTANCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ATTRACTIONDISTANCE")
  4)

(deftest "sysvar-attreq-getvar-type"
  '((operator . "ATTREQ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ATTREQ"))
  'int)

(deftest "sysvar-attreq-getvar-default"
  '((operator . "ATTREQ") (area . "sysvar") (profile . STRICT))
  '(getvar "ATTREQ")
  1)

(deftest "sysvar-auditctl-getvar-type"
  '((operator . "AUDITCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUDITCTL"))
  'int)

(deftest "sysvar-auditctl-getvar-default"
  '((operator . "AUDITCTL") (area . "sysvar") (profile . STRICT))
  '(getvar "AUDITCTL")
  0)

(deftest "sysvar-auditerrorcount-getvar-type"
  '((operator . "AUDITERRORCOUNT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUDITERRORCOUNT"))
  'int)

(deftest-error "sysvar-auditerrorcount-setvar-readonly-signals"
  '((operator . "AUDITERRORCOUNT") (area . "sysvar") (profile . STRICT))
  '(setvar "AUDITERRORCOUNT" 0)
  'sysvar-read-only)

(deftest "sysvar-aunits-getvar-type"
  '((operator . "AUNITS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUNITS"))
  'int)

(deftest "sysvar-auprec-getvar-type"
  '((operator . "AUPREC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUPREC"))
  'int)

(deftest "sysvar-autocompletedelay-getvar-type"
  '((operator . "AUTOCOMPLETEDELAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUTOCOMPLETEDELAY"))
  'real)

(deftest "sysvar-autocompletedelay-getvar-default"
  '((operator . "AUTOCOMPLETEDELAY") (area . "sysvar") (profile . STRICT))
  '(getvar "AUTOCOMPLETEDELAY")
  0.3)

(deftest "sysvar-autocompletemode-getvar-type"
  '((operator . "AUTOCOMPLETEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUTOCOMPLETEMODE"))
  'int)

(deftest "sysvar-autocompletemode-getvar-default"
  '((operator . "AUTOCOMPLETEMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "AUTOCOMPLETEMODE")
  47)

(deftest "sysvar-autodwfpublish-getvar-type"
  '((operator . "AUTODWFPUBLISH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUTODWFPUBLISH"))
  'int)

(deftest "sysvar-autodwfpublish-getvar-default"
  '((operator . "AUTODWFPUBLISH") (area . "sysvar") (profile . STRICT))
  '(getvar "AUTODWFPUBLISH")
  0)

(deftest "sysvar-automaticconnection-getvar-type"
  '((operator . "AUTOMATICCONNECTION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "AUTOMATICCONNECTION"))
  'int)

(deftest "sysvar-automaticconnection-getvar-default"
  '((operator . "AUTOMATICCONNECTION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "AUTOMATICCONNECTION")
  1)

(deftest "sysvar-automaticpub-getvar-type"
  '((operator . "AUTOMATICPUB") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUTOMATICPUB"))
  'int)

(deftest "sysvar-automaticpub-getvar-default"
  '((operator . "AUTOMATICPUB") (area . "sysvar") (profile . STRICT))
  '(getvar "AUTOMATICPUB")
  0)

(deftest "sysvar-automaticstairsectionbehavior-getvar-type"
  '((operator . "AUTOMATICSTAIRSECTIONBEHAVIOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "AUTOMATICSTAIRSECTIONBEHAVIOR"))
  'int)

(deftest "sysvar-automaticstairsectionbehavior-getvar-default"
  '((operator . "AUTOMATICSTAIRSECTIONBEHAVIOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "AUTOMATICSTAIRSECTIONBEHAVIOR")
  0)

(deftest "sysvar-automatictees-getvar-type"
  '((operator . "AUTOMATICTEES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "AUTOMATICTEES"))
  'int)

(deftest "sysvar-automatictees-getvar-default"
  '((operator . "AUTOMATICTEES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "AUTOMATICTEES")
  0)

(deftest "sysvar-autoplacement-getvar-type"
  '((operator . "AUTOPLACEMENT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUTOPLACEMENT"))
  'int)

(deftest "sysvar-autoplacement-getvar-default"
  '((operator . "AUTOPLACEMENT") (area . "sysvar") (profile . STRICT))
  '(getvar "AUTOPLACEMENT")
  1)

(deftest "sysvar-autoresetscales-getvar-type"
  '((operator . "AUTORESETSCALES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "AUTORESETSCALES"))
  'int)

(deftest "sysvar-autoresetscales-getvar-default"
  '((operator . "AUTORESETSCALES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "AUTORESETSCALES")
  0)

(deftest "sysvar-autosavechecksonlyfirstbitdbmod-getvar-type"
  '((operator . "AUTOSAVECHECKSONLYFIRSTBITDBMOD") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "AUTOSAVECHECKSONLYFIRSTBITDBMOD"))
  'int)

(deftest "sysvar-autosavechecksonlyfirstbitdbmod-getvar-default"
  '((operator . "AUTOSAVECHECKSONLYFIRSTBITDBMOD") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "AUTOSAVECHECKSONLYFIRSTBITDBMOD")
  1)

(deftest "sysvar-autosnap-getvar-type"
  '((operator . "AUTOSNAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUTOSNAP"))
  'int)

(deftest "sysvar-autotrackingveccolor-getvar-type"
  '((operator . "AUTOTRACKINGVECCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "AUTOTRACKINGVECCOLOR"))
  'int)

(deftest "sysvar-autotrackingveccolor-getvar-default"
  '((operator . "AUTOTRACKINGVECCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "AUTOTRACKINGVECCOLOR")
  171)

(deftest "sysvar-autovpfitting-getvar-type"
  '((operator . "AUTOVPFITTING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "AUTOVPFITTING"))
  'int)

(deftest "sysvar-autovpfitting-getvar-default"
  '((operator . "AUTOVPFITTING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "AUTOVPFITTING")
  1)

(deftest "sysvar-backgroundplot-getvar-type"
  '((operator . "BACKGROUNDPLOT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BACKGROUNDPLOT"))
  'int)

(deftest "sysvar-backz-getvar-type"
  '((operator . "BACKZ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BACKZ"))
  'real)

(deftest-error "sysvar-backz-setvar-readonly-signals"
  '((operator . "BACKZ") (area . "sysvar") (profile . STRICT))
  '(setvar "BACKZ" 0.0)
  'sysvar-read-only)

(deftest "sysvar-bactionbarmode-getvar-type"
  '((operator . "BACTIONBARMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BACTIONBARMODE"))
  'int)

(deftest "sysvar-bactionbarmode-getvar-default"
  '((operator . "BACTIONBARMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "BACTIONBARMODE")
  1)

(deftest "sysvar-bactioncolor-getvar-type"
  '((operator . "BACTIONCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BACTIONCOLOR"))
  'str)

(deftest "sysvar-bactioncolor-getvar-default"
  '((operator . "BACTIONCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "BACTIONCOLOR")
  "7")

(deftest "sysvar-basefile-getvar-type"
  '((operator . "BASEFILE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BASEFILE"))
  'str)

(deftest "sysvar-bcfsourceurl-getvar-type"
  '((operator . "BCFSOURCEURL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BCFSOURCEURL"))
  'str)

(deftest "sysvar-bconstatusmode-getvar-type"
  '((operator . "BCONSTATUSMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BCONSTATUSMODE"))
  'int)

(deftest "sysvar-bconstatusmode-getvar-default"
  '((operator . "BCONSTATUSMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "BCONSTATUSMODE")
  0)

(deftest "sysvar-bconvertlayer-getvar-type"
  '((operator . "BCONVERTLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BCONVERTLAYER"))
  'int)

(deftest "sysvar-bconvertlayer-getvar-default"
  '((operator . "BCONVERTLAYER") (area . "sysvar") (profile . STRICT))
  '(getvar "BCONVERTLAYER")
  1)

(deftest "sysvar-bdependencyhighlight-getvar-type"
  '((operator . "BDEPENDENCYHIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BDEPENDENCYHIGHLIGHT"))
  'int)

(deftest "sysvar-bdependencyhighlight-getvar-default"
  '((operator . "BDEPENDENCYHIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "BDEPENDENCYHIGHLIGHT")
  1)

(deftest "sysvar-beditassocmode-getvar-type"
  '((operator . "BEDITASSOCMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BEDITASSOCMODE"))
  'int)

(deftest "sysvar-beditassocmode-getvar-default"
  '((operator . "BEDITASSOCMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BEDITASSOCMODE")
  1)

(deftest "sysvar-bgcorepublish-getvar-type"
  '((operator . "BGCOREPUBLISH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BGCOREPUBLISH"))
  'int)

(deftest "sysvar-bgcorepublish-getvar-default"
  '((operator . "BGCOREPUBLISH") (area . "sysvar") (profile . STRICT))
  '(getvar "BGCOREPUBLISH")
  1)

(deftest "sysvar-bgripobjcolor-getvar-type"
  '((operator . "BGRIPOBJCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BGRIPOBJCOLOR"))
  'str)

(deftest "sysvar-bgripobjcolor-getvar-default"
  '((operator . "BGRIPOBJCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "BGRIPOBJCOLOR")
  "141")

(deftest "sysvar-bgripobjsize-getvar-type"
  '((operator . "BGRIPOBJSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BGRIPOBJSIZE"))
  'int)

(deftest "sysvar-bgripobjsize-getvar-default"
  '((operator . "BGRIPOBJSIZE") (area . "sysvar") (profile . STRICT))
  '(getvar "BGRIPOBJSIZE")
  8)

(deftest "sysvar-billofmaterialssettings-getvar-type"
  '((operator . "BILLOFMATERIALSSETTINGS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BILLOFMATERIALSSETTINGS"))
  'int)

(deftest "sysvar-billofmaterialssettings-getvar-default"
  '((operator . "BILLOFMATERIALSSETTINGS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BILLOFMATERIALSSETTINGS")
  10)

(deftest "sysvar-bimdefaultpropertiespath-getvar-type"
  '((operator . "BIMDEFAULTPROPERTIESPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BIMDEFAULTPROPERTIESPATH"))
  'str)

(deftest "sysvar-bimdefaultpropertiespath-getvar-default"
  '((operator . "BIMDEFAULTPROPERTIESPATH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BIMDEFAULTPROPERTIESPATH")
  "bimproj_user.xml;bimproj_IFC.xml;bimproj_quantity.xml")

(deftest "sysvar-bimmatchprop-getvar-type"
  '((operator . "BIMMATCHPROP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BIMMATCHPROP"))
  'int)

(deftest "sysvar-bimmatchprop-getvar-default"
  '((operator . "BIMMATCHPROP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BIMMATCHPROP")
  1)

(deftest "sysvar-bimosmode-getvar-type"
  '((operator . "BIMOSMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BIMOSMODE"))
  'int)

(deftest "sysvar-bimosmode-getvar-default"
  '((operator . "BIMOSMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BIMOSMODE")
  3)

(deftest "sysvar-bimprofilestandards-getvar-type"
  '((operator . "BIMPROFILESTANDARDS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BIMPROFILESTANDARDS"))
  'str)

(deftest "sysvar-bindtype-getvar-type"
  '((operator . "BINDTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BINDTYPE"))
  'int)

(deftest "sysvar-bindtype-getvar-default"
  '((operator . "BINDTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "BINDTYPE")
  0)

(deftest "sysvar-bkgcolor-getvar-type"
  '((operator . "BKGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BKGCOLOR"))
  'str)

(deftest "sysvar-bkgcolor-getvar-default"
  '((operator . "BKGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BKGCOLOR")
  "RGB:24,25,28")

(deftest "sysvar-bkgcolorps-getvar-type"
  '((operator . "BKGCOLORPS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BKGCOLORPS"))
  'str)

(deftest "sysvar-bkgcolorps-getvar-default"
  '((operator . "BKGCOLORPS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BKGCOLORPS")
  "RGB:250,250,250")

(deftest "sysvar-blipmode-getvar-type"
  '((operator . "BLIPMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLIPMODE"))
  'int)

(deftest "sysvar-blipmode-getvar-default"
  '((operator . "BLIPMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "BLIPMODE")
  0)

(deftest "sysvar-blockcreatemode-getvar-type"
  '((operator . "BLOCKCREATEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKCREATEMODE"))
  'int)

(deftest "sysvar-blockcreatemode-getvar-default"
  '((operator . "BLOCKCREATEMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "BLOCKCREATEMODE")
  0)

(deftest "sysvar-blockeditlock-getvar-type"
  '((operator . "BLOCKEDITLOCK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKEDITLOCK"))
  'int)

(deftest "sysvar-blockeditlock-getvar-default"
  '((operator . "BLOCKEDITLOCK") (area . "sysvar") (profile . STRICT))
  '(getvar "BLOCKEDITLOCK")
  0)

(deftest "sysvar-blockeditor-getvar-type"
  '((operator . "BLOCKEDITOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKEDITOR"))
  'int)

(deftest-error "sysvar-blockeditor-setvar-readonly-signals"
  '((operator . "BLOCKEDITOR") (area . "sysvar") (profile . STRICT))
  '(setvar "BLOCKEDITOR" 0)
  'sysvar-read-only)

(deftest "sysvar-blockexcludecolor-getvar-type"
  '((operator . "BLOCKEXCLUDECOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKEXCLUDECOLOR"))
  'int)

(deftest "sysvar-blockexcludecolor-getvar-default"
  '((operator . "BLOCKEXCLUDECOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "BLOCKEXCLUDECOLOR")
  7)

(deftest "sysvar-blockifymode-getvar-type"
  '((operator . "BLOCKIFYMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BLOCKIFYMODE"))
  'int)

(deftest "sysvar-blockifymode-getvar-default"
  '((operator . "BLOCKIFYMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BLOCKIFYMODE")
  71)

(deftest "sysvar-blockifytolerance-getvar-type"
  '((operator . "BLOCKIFYTOLERANCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BLOCKIFYTOLERANCE"))
  'real)

(deftest "sysvar-blockifytolerance-getvar-default"
  '((operator . "BLOCKIFYTOLERANCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BLOCKIFYTOLERANCE")
  -1.0)

(deftest "sysvar-blockincludecolor-getvar-type"
  '((operator . "BLOCKINCLUDECOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKINCLUDECOLOR"))
  'int)

(deftest "sysvar-blockincludecolor-getvar-default"
  '((operator . "BLOCKINCLUDECOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "BLOCKINCLUDECOLOR")
  3)

(deftest "sysvar-blocklevelofdetail-getvar-type"
  '((operator . "BLOCKLEVELOFDETAIL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BLOCKLEVELOFDETAIL"))
  'int)

(deftest "sysvar-blocklevelofdetail-getvar-default"
  '((operator . "BLOCKLEVELOFDETAIL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BLOCKLEVELOFDETAIL")
  1)

(deftest "sysvar-blockmrulist-getvar-type"
  '((operator . "BLOCKMRULIST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKMRULIST"))
  'int)

(deftest "sysvar-blockmrulist-getvar-default"
  '((operator . "BLOCKMRULIST") (area . "sysvar") (profile . STRICT))
  '(getvar "BLOCKMRULIST")
  50)

(deftest "sysvar-blocknavigate-getvar-type"
  '((operator . "BLOCKNAVIGATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKNAVIGATE"))
  'str)

(deftest "sysvar-blocknavigate-getvar-default"
  '((operator . "BLOCKNAVIGATE") (area . "sysvar") (profile . STRICT))
  '(getvar "BLOCKNAVIGATE")
  "")

(deftest "sysvar-blockredefinemode-getvar-type"
  '((operator . "BLOCKREDEFINEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKREDEFINEMODE"))
  'int)

(deftest "sysvar-blockredefinemode-getvar-default"
  '((operator . "BLOCKREDEFINEMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "BLOCKREDEFINEMODE")
  1)

(deftest "sysvar-blocksdatacollection-getvar-type"
  '((operator . "BLOCKSDATACOLLECTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKSDATACOLLECTION"))
  'int)

(deftest "sysvar-blocksdatacollection-getvar-default"
  '((operator . "BLOCKSDATACOLLECTION") (area . "sysvar") (profile . STRICT))
  '(getvar "BLOCKSDATACOLLECTION")
  1)

(deftest "sysvar-blockspath-getvar-type"
  '((operator . "BLOCKSPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BLOCKSPATH"))
  'str)

(deftest "sysvar-blocksrecentfolder-getvar-type"
  '((operator . "BLOCKSRECENTFOLDER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKSRECENTFOLDER"))
  'str)

(deftest "sysvar-blockstate-getvar-type"
  '((operator . "BLOCKSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKSTATE"))
  'int)

(deftest-error "sysvar-blockstate-setvar-readonly-signals"
  '((operator . "BLOCKSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "BLOCKSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-blocksyncfolder-getvar-type"
  '((operator . "BLOCKSYNCFOLDER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKSYNCFOLDER"))
  'str)

(deftest "sysvar-blocktargetcolor-getvar-type"
  '((operator . "BLOCKTARGETCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKTARGETCOLOR"))
  'int)

(deftest "sysvar-blocktargetcolor-getvar-default"
  '((operator . "BLOCKTARGETCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "BLOCKTARGETCOLOR")
  3)

(deftest "sysvar-blocktestwindow-getvar-type"
  '((operator . "BLOCKTESTWINDOW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BLOCKTESTWINDOW"))
  'int)

(deftest-error "sysvar-blocktestwindow-setvar-readonly-signals"
  '((operator . "BLOCKTESTWINDOW") (area . "sysvar") (profile . STRICT))
  '(setvar "BLOCKTESTWINDOW" 0)
  'sysvar-read-only)

(deftest "sysvar-bmautoupdate-getvar-type"
  '((operator . "BMAUTOUPDATE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BMAUTOUPDATE"))
  'int)

(deftest "sysvar-bmautoupdate-getvar-default"
  '((operator . "BMAUTOUPDATE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BMAUTOUPDATE")
  1)

(deftest "sysvar-bmexternalizeillegalsymbols-getvar-type"
  '((operator . "BMEXTERNALIZEILLEGALSYMBOLS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BMEXTERNALIZEILLEGALSYMBOLS"))
  'int)

(deftest "sysvar-bmexternalizeillegalsymbols-getvar-default"
  '((operator . "BMEXTERNALIZEILLEGALSYMBOLS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BMEXTERNALIZEILLEGALSYMBOLS")
  3)

(deftest "sysvar-bmformtemplatepath-getvar-type"
  '((operator . "BMFORMTEMPLATEPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BMFORMTEMPLATEPATH"))
  'str)

(deftest "sysvar-bmtoolpath-getvar-type"
  '((operator . "BMTOOLPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BMTOOLPATH"))
  'str)

(deftest "sysvar-bmtoolpath-getvar-default"
  '((operator . "BMTOOLPATH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BMTOOLPATH")
  "C:\\Program Files\\Bricsys\\BricsCAD V26 en_US\\UserDataCache\\Support\\en_US\\DesignLibrary\\Tools\\")

(deftest "sysvar-bmupdatemode-getvar-type"
  '((operator . "BMUPDATEMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BMUPDATEMODE"))
  'int)

(deftest "sysvar-bmupdatemode-getvar-default"
  '((operator . "BMUPDATEMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BMUPDATEMODE")
  0)

(deftest "sysvar-boltingasmdefaultlengthincrement-getvar-type"
  '((operator . "BOLTINGASMDEFAULTLENGTHINCREMENT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BOLTINGASMDEFAULTLENGTHINCREMENT"))
  'real)

(deftest "sysvar-boltingasmdefaultlengthincrement-getvar-default"
  '((operator . "BOLTINGASMDEFAULTLENGTHINCREMENT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BOLTINGASMDEFAULTLENGTHINCREMENT")
  25.4)

(deftest "sysvar-boltingasmdefaultnut-getvar-type"
  '((operator . "BOLTINGASMDEFAULTNUT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BOLTINGASMDEFAULTNUT"))
  'str)

(deftest "sysvar-boltingasmdefaultnut-getvar-default"
  '((operator . "BOLTINGASMDEFAULTNUT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BOLTINGASMDEFAULTNUT")
  "ASME B18.2.2 Heavy Hex Nut")

(deftest "sysvar-boltingasmdefaultnutsnumber-getvar-type"
  '((operator . "BOLTINGASMDEFAULTNUTSNUMBER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BOLTINGASMDEFAULTNUTSNUMBER"))
  'int)

(deftest "sysvar-boltingasmdefaultnutsnumber-getvar-default"
  '((operator . "BOLTINGASMDEFAULTNUTSNUMBER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BOLTINGASMDEFAULTNUTSNUMBER")
  4)

(deftest "sysvar-boltingasmdefaultstud-getvar-type"
  '((operator . "BOLTINGASMDEFAULTSTUD") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BOLTINGASMDEFAULTSTUD"))
  'str)

(deftest "sysvar-boltingasmdefaultstud-getvar-default"
  '((operator . "BOLTINGASMDEFAULTSTUD") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BOLTINGASMDEFAULTSTUD")
  "ASME B18.31.2 Continuous Thread Flange Bolting Stud")

(deftest "sysvar-bomfiltersettings-getvar-type"
  '((operator . "BOMFILTERSETTINGS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BOMFILTERSETTINGS"))
  'int)

(deftest "sysvar-bomfiltersettings-getvar-default"
  '((operator . "BOMFILTERSETTINGS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BOMFILTERSETTINGS")
  1)

(deftest "sysvar-bompropertyset-getvar-type"
  '((operator . "BOMPROPERTYSET") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BOMPROPERTYSET"))
  'int)

(deftest "sysvar-bompropertyset-getvar-default"
  '((operator . "BOMPROPERTYSET") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BOMPROPERTYSET")
  1)

(deftest "sysvar-bomtemplate-getvar-type"
  '((operator . "BOMTEMPLATE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BOMTEMPLATE"))
  'str)

(deftest "sysvar-bomtemplate-getvar-default"
  '((operator . "BOMTEMPLATE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BOMTEMPLATE")
  "\" \"")

(deftest "sysvar-bomthumbnailheight-getvar-type"
  '((operator . "BOMTHUMBNAILHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BOMTHUMBNAILHEIGHT"))
  'int)

(deftest "sysvar-bomthumbnailheight-getvar-default"
  '((operator . "BOMTHUMBNAILHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BOMTHUMBNAILHEIGHT")
  200)

(deftest "sysvar-bomthumbnailwidth-getvar-type"
  '((operator . "BOMTHUMBNAILWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BOMTHUMBNAILWIDTH"))
  'int)

(deftest "sysvar-bomthumbnailwidth-getvar-default"
  '((operator . "BOMTHUMBNAILWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BOMTHUMBNAILWIDTH")
  200)

(deftest "sysvar-boundarycolor-getvar-type"
  '((operator . "BOUNDARYCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BOUNDARYCOLOR"))
  'int)

(deftest "sysvar-boundarycolor-getvar-default"
  '((operator . "BOUNDARYCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BOUNDARYCOLOR")
  95)

(deftest "sysvar-bparametercolor-getvar-type"
  '((operator . "BPARAMETERCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BPARAMETERCOLOR"))
  'str)

(deftest "sysvar-bparametercolor-getvar-default"
  '((operator . "BPARAMETERCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "BPARAMETERCOLOR")
  "170")

(deftest "sysvar-bparameterfont-getvar-type"
  '((operator . "BPARAMETERFONT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BPARAMETERFONT"))
  'str)

(deftest "sysvar-bparameterfont-getvar-default"
  '((operator . "BPARAMETERFONT") (area . "sysvar") (profile . STRICT))
  '(getvar "BPARAMETERFONT")
  "Simplex.shx")

(deftest "sysvar-bparametersize-getvar-type"
  '((operator . "BPARAMETERSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BPARAMETERSIZE"))
  'int)

(deftest "sysvar-bparametersize-getvar-default"
  '((operator . "BPARAMETERSIZE") (area . "sysvar") (profile . STRICT))
  '(getvar "BPARAMETERSIZE")
  12)

(deftest "sysvar-bptexthorizontal-getvar-type"
  '((operator . "BPTEXTHORIZONTAL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BPTEXTHORIZONTAL"))
  'int)

(deftest "sysvar-bptexthorizontal-getvar-default"
  '((operator . "BPTEXTHORIZONTAL") (area . "sysvar") (profile . STRICT))
  '(getvar "BPTEXTHORIZONTAL")
  1)

(deftest "sysvar-bsearchincludeexistingblocks-getvar-type"
  '((operator . "BSEARCHINCLUDEEXISTINGBLOCKS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BSEARCHINCLUDEEXISTINGBLOCKS"))
  'int)

(deftest "sysvar-bsearchincludeexistingblocks-getvar-default"
  '((operator . "BSEARCHINCLUDEEXISTINGBLOCKS") (area . "sysvar") (profile . STRICT))
  '(getvar "BSEARCHINCLUDEEXISTINGBLOCKS")
  3)

(deftest "sysvar-bsyslibcopyoverwrite-getvar-type"
  '((operator . "BSYSLIBCOPYOVERWRITE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "BSYSLIBCOPYOVERWRITE"))
  'int)

(deftest "sysvar-bsyslibcopyoverwrite-getvar-default"
  '((operator . "BSYSLIBCOPYOVERWRITE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "BSYSLIBCOPYOVERWRITE")
  0)

(deftest "sysvar-btmarkdisplay-getvar-type"
  '((operator . "BTMARKDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BTMARKDISPLAY"))
  'int)

(deftest "sysvar-btmarkdisplay-getvar-default"
  '((operator . "BTMARKDISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "BTMARKDISPLAY")
  1)

(deftest "sysvar-bvmode-getvar-type"
  '((operator . "BVMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "BVMODE"))
  'int)

(deftest "sysvar-cachelayout-getvar-type"
  '((operator . "CACHELAYOUT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CACHELAYOUT"))
  'int)

(deftest "sysvar-cachelayout-getvar-default"
  '((operator . "CACHELAYOUT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CACHELAYOUT")
  1)

(deftest "sysvar-cachemaxfiles-getvar-type"
  '((operator . "CACHEMAXFILES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CACHEMAXFILES"))
  'int)

(deftest "sysvar-cachemaxfiles-getvar-default"
  '((operator . "CACHEMAXFILES") (area . "sysvar") (profile . STRICT))
  '(getvar "CACHEMAXFILES")
  256)

(deftest "sysvar-cachemaxtotalsize-getvar-type"
  '((operator . "CACHEMAXTOTALSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CACHEMAXTOTALSIZE"))
  'int)

(deftest "sysvar-cachemaxtotalsize-getvar-default"
  '((operator . "CACHEMAXTOTALSIZE") (area . "sysvar") (profile . STRICT))
  '(getvar "CACHEMAXTOTALSIZE")
  1024)

(deftest "sysvar-calcinput-getvar-type"
  '((operator . "CALCINPUT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CALCINPUT"))
  'int)

(deftest "sysvar-calcinput-getvar-default"
  '((operator . "CALCINPUT") (area . "sysvar") (profile . STRICT))
  '(getvar "CALCINPUT")
  1)

(deftest "sysvar-cameradisplay-getvar-type"
  '((operator . "CAMERADISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CAMERADISPLAY"))
  'int)

(deftest "sysvar-cameradisplay-getvar-default"
  '((operator . "CAMERADISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "CAMERADISPLAY")
  0)

(deftest "sysvar-cameraheight-getvar-type"
  '((operator . "CAMERAHEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CAMERAHEIGHT"))
  'real)

(deftest "sysvar-cannoscale-getvar-type"
  '((operator . "CANNOSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CANNOSCALE"))
  'str)

(deftest "sysvar-cannoscale-getvar-default"
  '((operator . "CANNOSCALE") (area . "sysvar") (profile . STRICT))
  '(getvar "CANNOSCALE")
  "1:1")

(deftest "sysvar-cannoscalevalue-getvar-type"
  '((operator . "CANNOSCALEVALUE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CANNOSCALEVALUE"))
  'real)

(deftest-error "sysvar-cannoscalevalue-setvar-readonly-signals"
  '((operator . "CANNOSCALEVALUE") (area . "sysvar") (profile . STRICT))
  '(setvar "CANNOSCALEVALUE" 0.0)
  'sysvar-read-only)

(deftest "sysvar-capturethumbnails-getvar-type"
  '((operator . "CAPTURETHUMBNAILS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CAPTURETHUMBNAILS"))
  'int)

(deftest "sysvar-capturethumbnails-getvar-default"
  '((operator . "CAPTURETHUMBNAILS") (area . "sysvar") (profile . STRICT))
  '(getvar "CAPTURETHUMBNAILS")
  1)

(deftest "sysvar-cbartransparency-getvar-type"
  '((operator . "CBARTRANSPARENCY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CBARTRANSPARENCY"))
  'int)

(deftest "sysvar-cbartransparency-getvar-default"
  '((operator . "CBARTRANSPARENCY") (area . "sysvar") (profile . STRICT))
  '(getvar "CBARTRANSPARENCY")
  50)

(deftest "sysvar-cconstraintform-getvar-type"
  '((operator . "CCONSTRAINTFORM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CCONSTRAINTFORM"))
  'int)

(deftest "sysvar-cconstraintform-getvar-default"
  '((operator . "CCONSTRAINTFORM") (area . "sysvar") (profile . STRICT))
  '(getvar "CCONSTRAINTFORM")
  0)

(deftest "sysvar-cdate-getvar-type"
  '((operator . "CDATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CDATE"))
  'real)

(deftest-error "sysvar-cdate-setvar-readonly-signals"
  '((operator . "CDATE") (area . "sysvar") (profile . STRICT))
  '(setvar "CDATE" 0.0)
  'sysvar-read-only)

(deftest "sysvar-cecolor-getvar-type"
  '((operator . "CECOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CECOLOR"))
  'str)

(deftest "sysvar-cecolor-getvar-default"
  '((operator . "CECOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "CECOLOR")
  "BYLAYER")

(deftest "sysvar-celtscale-getvar-type"
  '((operator . "CELTSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CELTSCALE"))
  'real)

(deftest "sysvar-celtype-getvar-type"
  '((operator . "CELTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CELTYPE"))
  'str)

(deftest "sysvar-celtype-getvar-default"
  '((operator . "CELTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "CELTYPE")
  "BYLAYER")

(deftest "sysvar-celweight-getvar-type"
  '((operator . "CELWEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CELWEIGHT"))
  'int)

(deftest "sysvar-centercrossgap-getvar-type"
  '((operator . "CENTERCROSSGAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CENTERCROSSGAP"))
  'str)

(deftest "sysvar-centercrosssize-getvar-type"
  '((operator . "CENTERCROSSSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CENTERCROSSSIZE"))
  'str)

(deftest "sysvar-centerexe-getvar-type"
  '((operator . "CENTEREXE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CENTEREXE"))
  'real)

(deftest "sysvar-centerlayer-getvar-type"
  '((operator . "CENTERLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CENTERLAYER"))
  'str)

(deftest "sysvar-centerltscale-getvar-type"
  '((operator . "CENTERLTSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CENTERLTSCALE"))
  'real)

(deftest "sysvar-centerltype-getvar-type"
  '((operator . "CENTERLTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CENTERLTYPE"))
  'str)

(deftest "sysvar-centerltypefile-getvar-type"
  '((operator . "CENTERLTYPEFILE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CENTERLTYPEFILE"))
  'str)

(deftest "sysvar-centermarkexe-getvar-type"
  '((operator . "CENTERMARKEXE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CENTERMARKEXE"))
  'int)

(deftest "sysvar-centermarkexe-getvar-default"
  '((operator . "CENTERMARKEXE") (area . "sysvar") (profile . STRICT))
  '(getvar "CENTERMARKEXE")
  1)

(deftest "sysvar-centermt-getvar-type"
  '((operator . "CENTERMT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CENTERMT"))
  'int)

(deftest "sysvar-centermt-getvar-default"
  '((operator . "CENTERMT") (area . "sysvar") (profile . STRICT))
  '(getvar "CENTERMT")
  0)

(deftest "sysvar-cetransparency-getvar-type"
  '((operator . "CETRANSPARENCY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CETRANSPARENCY"))
  'int)

(deftest "sysvar-cgeocs-getvar-type"
  '((operator . "CGEOCS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CGEOCS"))
  'str)

(deftest-error "sysvar-cgeocs-setvar-readonly-signals"
  '((operator . "CGEOCS") (area . "sysvar") (profile . STRICT))
  '(setvar "CGEOCS" "")
  'sysvar-read-only)

(deftest "sysvar-chamfera-getvar-type"
  '((operator . "CHAMFERA") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CHAMFERA"))
  'real)

(deftest "sysvar-chamferb-getvar-type"
  '((operator . "CHAMFERB") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CHAMFERB"))
  'real)

(deftest "sysvar-chamferc-getvar-type"
  '((operator . "CHAMFERC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CHAMFERC"))
  'real)

(deftest "sysvar-chamferd-getvar-type"
  '((operator . "CHAMFERD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CHAMFERD"))
  'real)

(deftest "sysvar-chammode-getvar-type"
  '((operator . "CHAMMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CHAMMODE"))
  'int)

(deftest "sysvar-checkdwlpresence-getvar-type"
  '((operator . "CHECKDWLPRESENCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CHECKDWLPRESENCE"))
  'int)

(deftest "sysvar-circlerad-getvar-type"
  '((operator . "CIRCLERAD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CIRCLERAD"))
  'real)

(deftest "sysvar-circulararrowheadlength-getvar-type"
  '((operator . "CIRCULARARROWHEADLENGTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CIRCULARARROWHEADLENGTH"))
  'real)

(deftest "sysvar-circulararrowheadwidth-getvar-type"
  '((operator . "CIRCULARARROWHEADWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CIRCULARARROWHEADWIDTH"))
  'real)

(deftest "sysvar-circulararrowleaderradius-getvar-type"
  '((operator . "CIRCULARARROWLEADERRADIUS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CIRCULARARROWLEADERRADIUS"))
  'real)

(deftest "sysvar-circulararrowleaderrotation-getvar-type"
  '((operator . "CIRCULARARROWLEADERROTATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CIRCULARARROWLEADERROTATION"))
  'real)

(deftest "sysvar-circulararrowleaderrotation-getvar-default"
  '((operator . "CIRCULARARROWLEADERROTATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CIRCULARARROWLEADERROTATION")
  90.0)

(deftest "sysvar-circulararrowthickness-getvar-type"
  '((operator . "CIRCULARARROWTHICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CIRCULARARROWTHICKNESS"))
  'real)

(deftest "sysvar-clayer-getvar-type"
  '((operator . "CLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CLAYER"))
  'str)

(deftest "sysvar-clayer-getvar-default"
  '((operator . "CLAYER") (area . "sysvar") (profile . STRICT))
  '(getvar "CLAYER")
  "0")

(deftest "sysvar-clayout-getvar-type"
  '((operator . "CLAYOUT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CLAYOUT"))
  'str)

(deftest "sysvar-cleanscreenoptions-getvar-type"
  '((operator . "CLEANSCREENOPTIONS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLEANSCREENOPTIONS"))
  'int)

(deftest "sysvar-cleanscreenoptions-getvar-default"
  '((operator . "CLEANSCREENOPTIONS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLEANSCREENOPTIONS")
  15)

(deftest "sysvar-cleanscreenstate-getvar-type"
  '((operator . "CLEANSCREENSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CLEANSCREENSTATE"))
  'int)

(deftest-error "sysvar-cleanscreenstate-setvar-readonly-signals"
  '((operator . "CLEANSCREENSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "CLEANSCREENSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-clipboardformat-getvar-type"
  '((operator . "CLIPBOARDFORMAT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLIPBOARDFORMAT"))
  'int)

(deftest "sysvar-clipboardformat-getvar-default"
  '((operator . "CLIPBOARDFORMAT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLIPBOARDFORMAT")
  4)

(deftest "sysvar-clipboardformats-getvar-type"
  '((operator . "CLIPBOARDFORMATS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLIPBOARDFORMATS"))
  'int)

(deftest "sysvar-clipboardformats-getvar-default"
  '((operator . "CLIPBOARDFORMATS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLIPBOARDFORMATS")
  127)

(deftest "sysvar-clipromptlines-getvar-type"
  '((operator . "CLIPROMPTLINES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CLIPROMPTLINES"))
  'int)

(deftest "sysvar-clipromptupdate-getvar-type"
  '((operator . "CLIPROMPTUPDATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CLIPROMPTUPDATE"))
  'int)

(deftest "sysvar-clipromptupdate-getvar-default"
  '((operator . "CLIPROMPTUPDATE") (area . "sysvar") (profile . STRICT))
  '(getvar "CLIPROMPTUPDATE")
  1)

(deftest "sysvar-clistate-getvar-type"
  '((operator . "CLISTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CLISTATE"))
  'int)

(deftest-error "sysvar-clistate-setvar-readonly-signals"
  '((operator . "CLISTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "CLISTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-closechecksonlyfirstbitdbmod-getvar-type"
  '((operator . "CLOSECHECKSONLYFIRSTBITDBMOD") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLOSECHECKSONLYFIRSTBITDBMOD"))
  'int)

(deftest "sysvar-closechecksonlyfirstbitdbmod-getvar-default"
  '((operator . "CLOSECHECKSONLYFIRSTBITDBMOD") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLOSECHECKSONLYFIRSTBITDBMOD")
  0)

(deftest "sysvar-clouddownloadpath-getvar-type"
  '((operator . "CLOUDDOWNLOADPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLOUDDOWNLOADPATH"))
  'str)

(deftest "sysvar-clouddownloadpath-getvar-default"
  '((operator . "CLOUDDOWNLOADPATH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLOUDDOWNLOADPATH")
  "{User}Documents/Bricsys247")

(deftest "sysvar-cloudlog-getvar-type"
  '((operator . "CLOUDLOG") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLOUDLOG"))
  'int)

(deftest "sysvar-cloudlog-getvar-default"
  '((operator . "CLOUDLOG") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLOUDLOG")
  0)

(deftest "sysvar-cloudlogverbose-getvar-type"
  '((operator . "CLOUDLOGVERBOSE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLOUDLOGVERBOSE"))
  'int)

(deftest "sysvar-cloudlogverbose-getvar-default"
  '((operator . "CLOUDLOGVERBOSE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLOUDLOGVERBOSE")
  0)

(deftest "sysvar-cloudonmodified-getvar-type"
  '((operator . "CLOUDONMODIFIED") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLOUDONMODIFIED"))
  'int)

(deftest "sysvar-cloudonmodified-getvar-default"
  '((operator . "CLOUDONMODIFIED") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLOUDONMODIFIED")
  1)

(deftest "sysvar-cloudserver-getvar-type"
  '((operator . "CLOUDSERVER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLOUDSERVER"))
  'str)

(deftest "sysvar-cloudserver-getvar-default"
  '((operator . "CLOUDSERVER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLOUDSERVER")
  "https://my.bricsys247.com/")

(deftest "sysvar-cloudssoclientid-getvar-type"
  '((operator . "CLOUDSSOCLIENTID") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLOUDSSOCLIENTID"))
  'str)

(deftest "sysvar-cloudssoclientid-getvar-default"
  '((operator . "CLOUDSSOCLIENTID") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLOUDSSOCLIENTID")
  "bricscad")

(deftest "sysvar-cloudssoscope-getvar-type"
  '((operator . "CLOUDSSOSCOPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLOUDSSOSCOPE"))
  'str)

(deftest "sysvar-cloudssoscope-getvar-default"
  '((operator . "CLOUDSSOSCOPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLOUDSSOSCOPE")
  "openid profile email")

(deftest "sysvar-cloudtempfolder-getvar-type"
  '((operator . "CLOUDTEMPFOLDER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLOUDTEMPFOLDER"))
  'str)

(deftest "sysvar-cloudtempfolder-getvar-default"
  '((operator . "CLOUDTEMPFOLDER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLOUDTEMPFOLDER")
  "{User}AppData/Local/Temp/Bricsys_24_7")

(deftest "sysvar-clouduploaddependencies-getvar-type"
  '((operator . "CLOUDUPLOADDEPENDENCIES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CLOUDUPLOADDEPENDENCIES"))
  'int)

(deftest "sysvar-clouduploaddependencies-getvar-default"
  '((operator . "CLOUDUPLOADDEPENDENCIES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CLOUDUPLOADDEPENDENCIES")
  1)

(deftest "sysvar-cmaterial-getvar-type"
  '((operator . "CMATERIAL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMATERIAL"))
  'str)

(deftest "sysvar-cmaterial-getvar-default"
  '((operator . "CMATERIAL") (area . "sysvar") (profile . STRICT))
  '(getvar "CMATERIAL")
  "BYLAYER")

(deftest "sysvar-cmdactive-getvar-type"
  '((operator . "CMDACTIVE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMDACTIVE"))
  'int)

(deftest-error "sysvar-cmdactive-setvar-readonly-signals"
  '((operator . "CMDACTIVE") (area . "sysvar") (profile . STRICT))
  '(setvar "CMDACTIVE" 0)
  'sysvar-read-only)

(deftest "sysvar-cmddia-getvar-type"
  '((operator . "CMDDIA") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMDDIA"))
  'int)

(deftest "sysvar-cmddia-getvar-default"
  '((operator . "CMDDIA") (area . "sysvar") (profile . STRICT))
  '(getvar "CMDDIA")
  1)

(deftest "sysvar-cmdecho-getvar-type"
  '((operator . "CMDECHO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMDECHO"))
  'int)

(deftest "sysvar-cmdecho-getvar-default"
  '((operator . "CMDECHO") (area . "sysvar") (profile . STRICT))
  '(getvar "CMDECHO")
  1)

(deftest "sysvar-cmdinputhistorymax-getvar-type"
  '((operator . "CMDINPUTHISTORYMAX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMDINPUTHISTORYMAX"))
  'int)

(deftest "sysvar-cmdinputhistorymax-getvar-default"
  '((operator . "CMDINPUTHISTORYMAX") (area . "sysvar") (profile . STRICT))
  '(getvar "CMDINPUTHISTORYMAX")
  20)

(deftest "sysvar-cmdlineeditbgcolor-getvar-type"
  '((operator . "CMDLINEEDITBGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEEDITBGCOLOR"))
  'str)

(deftest "sysvar-cmdlineeditbgcolor-getvar-default"
  '((operator . "CMDLINEEDITBGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEEDITBGCOLOR")
  "RGB: 50 54 56 (Settings dialog) #323638 (Command line)")

(deftest "sysvar-cmdlineeditfgcolor-getvar-type"
  '((operator . "CMDLINEEDITFGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEEDITFGCOLOR"))
  'str)

(deftest "sysvar-cmdlineeditfgcolor-getvar-default"
  '((operator . "CMDLINEEDITFGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEEDITFGCOLOR")
  "White (Settings dialog) #FFFFFF (Command line)")

(deftest "sysvar-cmdlinefadinglogbgcolor-getvar-type"
  '((operator . "CMDLINEFADINGLOGBGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEFADINGLOGBGCOLOR"))
  'str)

(deftest "sysvar-cmdlinefadinglogbgcolor-getvar-default"
  '((operator . "CMDLINEFADINGLOGBGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEFADINGLOGBGCOLOR")
  "RGB: 50 54 56 (Settings dialog) #323638 (Command line)")

(deftest "sysvar-cmdlinefadinglogfadedelay-getvar-type"
  '((operator . "CMDLINEFADINGLOGFADEDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEFADINGLOGFADEDELAY"))
  'real)

(deftest "sysvar-cmdlinefadinglogfadedelay-getvar-default"
  '((operator . "CMDLINEFADINGLOGFADEDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEFADINGLOGFADEDELAY")
  2.0)

(deftest "sysvar-cmdlinefadinglogfgcolor-getvar-type"
  '((operator . "CMDLINEFADINGLOGFGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEFADINGLOGFGCOLOR"))
  'str)

(deftest "sysvar-cmdlinefadinglogfgcolor-getvar-default"
  '((operator . "CMDLINEFADINGLOGFGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEFADINGLOGFGCOLOR")
  "White")

(deftest "sysvar-cmdlinefadinglogtransparency-getvar-type"
  '((operator . "CMDLINEFADINGLOGTRANSPARENCY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEFADINGLOGTRANSPARENCY"))
  'int)

(deftest "sysvar-cmdlinefadinglogtransparency-getvar-default"
  '((operator . "CMDLINEFADINGLOGTRANSPARENCY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEFADINGLOGTRANSPARENCY")
  30)

(deftest "sysvar-cmdlinefontname-getvar-type"
  '((operator . "CMDLINEFONTNAME") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEFONTNAME"))
  'str)

(deftest "sysvar-cmdlinefontname-getvar-default"
  '((operator . "CMDLINEFONTNAME") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEFONTNAME")
  "Consolas")

(deftest "sysvar-cmdlinefontsize-getvar-type"
  '((operator . "CMDLINEFONTSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEFONTSIZE"))
  'int)

(deftest "sysvar-cmdlinefontsize-getvar-default"
  '((operator . "CMDLINEFONTSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEFONTSIZE")
  10)

(deftest "sysvar-cmdlineframeactivetransparency-getvar-type"
  '((operator . "CMDLINEFRAMEACTIVETRANSPARENCY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEFRAMEACTIVETRANSPARENCY"))
  'int)

(deftest "sysvar-cmdlineframeactivetransparency-getvar-default"
  '((operator . "CMDLINEFRAMEACTIVETRANSPARENCY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEFRAMEACTIVETRANSPARENCY")
  10)

(deftest "sysvar-cmdlineframeinactivetransparency-getvar-type"
  '((operator . "CMDLINEFRAMEINACTIVETRANSPARENCY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEFRAMEINACTIVETRANSPARENCY"))
  'int)

(deftest "sysvar-cmdlineframeinactivetransparency-getvar-default"
  '((operator . "CMDLINEFRAMEINACTIVETRANSPARENCY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEFRAMEINACTIVETRANSPARENCY")
  30)

(deftest "sysvar-cmdlineframeusetextscr-getvar-type"
  '((operator . "CMDLINEFRAMEUSETEXTSCR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEFRAMEUSETEXTSCR"))
  'int)

(deftest "sysvar-cmdlineframeusetextscr-getvar-default"
  '((operator . "CMDLINEFRAMEUSETEXTSCR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEFRAMEUSETEXTSCR")
  1)

(deftest "sysvar-cmdlinelistbgcolor-getvar-type"
  '((operator . "CMDLINELISTBGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINELISTBGCOLOR"))
  'str)

(deftest "sysvar-cmdlinelistbgcolor-getvar-default"
  '((operator . "CMDLINELISTBGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINELISTBGCOLOR")
  "RGB:130,130,130")

(deftest "sysvar-cmdlinelistfgcolor-getvar-type"
  '((operator . "CMDLINELISTFGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINELISTFGCOLOR"))
  'str)

(deftest "sysvar-cmdlinelistfgcolor-getvar-default"
  '((operator . "CMDLINELISTFGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINELISTFGCOLOR")
  "White")

(deftest "sysvar-cmdlineoptionbgcolor-getvar-type"
  '((operator . "CMDLINEOPTIONBGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEOPTIONBGCOLOR"))
  'str)

(deftest "sysvar-cmdlineoptionbgcolor-getvar-default"
  '((operator . "CMDLINEOPTIONBGCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEOPTIONBGCOLOR")
  "RGB:121,132,142")

(deftest "sysvar-cmdlineoptionshortcutcolor-getvar-type"
  '((operator . "CMDLINEOPTIONSHORTCUTCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEOPTIONSHORTCUTCOLOR"))
  'str)

(deftest "sysvar-cmdlineoptionshortcutcolor-getvar-default"
  '((operator . "CMDLINEOPTIONSHORTCUTCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEOPTIONSHORTCUTCOLOR")
  "RGB:255,187,0")

(deftest "sysvar-cmdlineuseminiframe-getvar-type"
  '((operator . "CMDLINEUSEMINIFRAME") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLINEUSEMINIFRAME"))
  'int)

(deftest "sysvar-cmdlineuseminiframe-getvar-default"
  '((operator . "CMDLINEUSEMINIFRAME") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLINEUSEMINIFRAME")
  1)

(deftest "sysvar-cmdlntext-getvar-type"
  '((operator . "CMDLNTEXT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMDLNTEXT"))
  'str)

(deftest "sysvar-cmdlntext-getvar-default"
  '((operator . "CMDLNTEXT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMDLNTEXT")
  ":")

(deftest "sysvar-cmdnames-getvar-type"
  '((operator . "CMDNAMES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMDNAMES"))
  'str)

(deftest-error "sysvar-cmdnames-setvar-readonly-signals"
  '((operator . "CMDNAMES") (area . "sysvar") (profile . STRICT))
  '(setvar "CMDNAMES" "")
  'sysvar-read-only)

(deftest "sysvar-cmfadecolor-getvar-type"
  '((operator . "CMFADECOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMFADECOLOR"))
  'int)

(deftest "sysvar-cmfadecolor-getvar-default"
  '((operator . "CMFADECOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "CMFADECOLOR")
  60)

(deftest "sysvar-cmfadeopacity-getvar-type"
  '((operator . "CMFADEOPACITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMFADEOPACITY"))
  'int)

(deftest "sysvar-cmfadeopacity-getvar-default"
  '((operator . "CMFADEOPACITY") (area . "sysvar") (profile . STRICT))
  '(getvar "CMFADEOPACITY")
  40)

(deftest "sysvar-cmleaderstyle-getvar-type"
  '((operator . "CMLEADERSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMLEADERSTYLE"))
  'str)

(deftest "sysvar-cmleaderstyle-getvar-default"
  '((operator . "CMLEADERSTYLE") (area . "sysvar") (profile . STRICT))
  '(getvar "CMLEADERSTYLE")
  "Standard")

(deftest "sysvar-cmljust-getvar-type"
  '((operator . "CMLJUST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMLJUST"))
  'int)

(deftest "sysvar-cmljust-getvar-default"
  '((operator . "CMLJUST") (area . "sysvar") (profile . STRICT))
  '(getvar "CMLJUST")
  0)

(deftest "sysvar-cmlscale-getvar-type"
  '((operator . "CMLSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMLSCALE"))
  'real)

(deftest "sysvar-cmlstyle-getvar-type"
  '((operator . "CMLSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMLSTYLE"))
  'str)

(deftest "sysvar-cmlstyle-getvar-default"
  '((operator . "CMLSTYLE") (area . "sysvar") (profile . STRICT))
  '(getvar "CMLSTYLE")
  "Standard")

(deftest "sysvar-cmosnap-getvar-type"
  '((operator . "CMOSNAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMOSNAP"))
  'int)

(deftest "sysvar-cmosnap-getvar-default"
  '((operator . "CMOSNAP") (area . "sysvar") (profile . STRICT))
  '(getvar "CMOSNAP")
  1)

(deftest "sysvar-cmpclrmiss-getvar-type"
  '((operator . "CMPCLRMISS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMPCLRMISS"))
  'int)

(deftest "sysvar-cmpclrmiss-getvar-default"
  '((operator . "CMPCLRMISS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMPCLRMISS")
  1)

(deftest "sysvar-cmpclrmod1-getvar-type"
  '((operator . "CMPCLRMOD1") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMPCLRMOD1"))
  'int)

(deftest "sysvar-cmpclrmod1-getvar-default"
  '((operator . "CMPCLRMOD1") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMPCLRMOD1")
  253)

(deftest "sysvar-cmpclrmod2-getvar-type"
  '((operator . "CMPCLRMOD2") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMPCLRMOD2"))
  'int)

(deftest "sysvar-cmpclrmod2-getvar-default"
  '((operator . "CMPCLRMOD2") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMPCLRMOD2")
  2)

(deftest "sysvar-cmpclrnew-getvar-type"
  '((operator . "CMPCLRNEW") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMPCLRNEW"))
  'int)

(deftest "sysvar-cmpclrnew-getvar-default"
  '((operator . "CMPCLRNEW") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMPCLRNEW")
  3)

(deftest "sysvar-cmpdifflimit-getvar-type"
  '((operator . "CMPDIFFLIMIT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMPDIFFLIMIT"))
  'int)

(deftest "sysvar-cmpdifflimit-getvar-default"
  '((operator . "CMPDIFFLIMIT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMPDIFFLIMIT")
  10000000)

(deftest "sysvar-cmpfadectl-getvar-type"
  '((operator . "CMPFADECTL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CMPFADECTL"))
  'int)

(deftest "sysvar-cmpfadectl-getvar-default"
  '((operator . "CMPFADECTL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CMPFADECTL")
  80)

(deftest "sysvar-cmplog-getvar-type"
  '((operator . "CMPLOG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CMPLOG"))
  'int)

(deftest "sysvar-cmplog-getvar-default"
  '((operator . "CMPLOG") (area . "sysvar") (profile . STRICT))
  '(getvar "CMPLOG")
  0)

(deftest "sysvar-colorbookpath-getvar-type"
  '((operator . "COLORBOOKPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COLORBOOKPATH"))
  'str)

(deftest "sysvar-colorpickbox-getvar-type"
  '((operator . "COLORPICKBOX") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COLORPICKBOX"))
  'int)

(deftest "sysvar-colorpickbox-getvar-default"
  '((operator . "COLORPICKBOX") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "COLORPICKBOX")
  7)

(deftest "sysvar-colortheme-getvar-type"
  '((operator . "COLORTHEME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COLORTHEME"))
  'int)

(deftest "sysvar-colorx-getvar-type"
  '((operator . "COLORX") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COLORX"))
  'int)

(deftest "sysvar-colorx-getvar-default"
  '((operator . "COLORX") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "COLORX")
  11)

(deftest "sysvar-colory-getvar-type"
  '((operator . "COLORY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COLORY"))
  'int)

(deftest "sysvar-colory-getvar-default"
  '((operator . "COLORY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "COLORY")
  112)

(deftest "sysvar-colorz-getvar-type"
  '((operator . "COLORZ") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COLORZ"))
  'int)

(deftest "sysvar-colorz-getvar-default"
  '((operator . "COLORZ") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "COLORZ")
  150)

(deftest "sysvar-comacadcompatibility-getvar-type"
  '((operator . "COMACADCOMPATIBILITY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COMACADCOMPATIBILITY"))
  'int)

(deftest "sysvar-comacadcompatibility-getvar-default"
  '((operator . "COMACADCOMPATIBILITY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "COMACADCOMPATIBILITY")
  0)

(deftest "sysvar-combinetextmode-getvar-type"
  '((operator . "COMBINETEXTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COMBINETEXTMODE"))
  'int)

(deftest "sysvar-combinetextmode-getvar-default"
  '((operator . "COMBINETEXTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "COMBINETEXTMODE")
  11)

(deftest "sysvar-commandassist-getvar-type"
  '((operator . "COMMANDASSIST") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COMMANDASSIST"))
  'int)

(deftest "sysvar-commandmacrosstate-getvar-type"
  '((operator . "COMMANDMACROSSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMMANDMACROSSTATE"))
  'int)

(deftest-error "sysvar-commandmacrosstate-setvar-readonly-signals"
  '((operator . "COMMANDMACROSSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "COMMANDMACROSSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-commandpreview-getvar-type"
  '((operator . "COMMANDPREVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMMANDPREVIEW"))
  'int)

(deftest "sysvar-commandpreview-getvar-default"
  '((operator . "COMMANDPREVIEW") (area . "sysvar") (profile . STRICT))
  '(getvar "COMMANDPREVIEW")
  1)

(deftest "sysvar-commenthighlight-getvar-type"
  '((operator . "COMMENTHIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMMENTHIGHLIGHT"))
  'int)

(deftest "sysvar-commenthighlight-getvar-default"
  '((operator . "COMMENTHIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "COMMENTHIGHLIGHT")
  1)

(deftest "sysvar-communicatorbackgroundmode-getvar-type"
  '((operator . "COMMUNICATORBACKGROUNDMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COMMUNICATORBACKGROUNDMODE"))
  'int)

(deftest "sysvar-communicatorbackgroundmode-getvar-default"
  '((operator . "COMMUNICATORBACKGROUNDMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "COMMUNICATORBACKGROUNDMODE")
  0)

(deftest "sysvar-communicatorpath-getvar-type"
  '((operator . "COMMUNICATORPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COMMUNICATORPATH"))
  'str)

(deftest "sysvar-comparecolor1-getvar-type"
  '((operator . "COMPARECOLOR1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARECOLOR1"))
  'int)

(deftest "sysvar-comparecolor1-getvar-default"
  '((operator . "COMPARECOLOR1") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARECOLOR1")
  82)

(deftest "sysvar-comparecolor2-getvar-type"
  '((operator . "COMPARECOLOR2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARECOLOR2"))
  'int)

(deftest "sysvar-comparecolor2-getvar-default"
  '((operator . "COMPARECOLOR2") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARECOLOR2")
  1)

(deftest "sysvar-comparecolorcommon-getvar-type"
  '((operator . "COMPARECOLORCOMMON") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARECOLORCOMMON"))
  'int)

(deftest "sysvar-comparecolorcommon-getvar-default"
  '((operator . "COMPARECOLORCOMMON") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARECOLORCOMMON")
  253)

(deftest "sysvar-comparefront-getvar-type"
  '((operator . "COMPAREFRONT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPAREFRONT"))
  'int)

(deftest "sysvar-comparefront-getvar-default"
  '((operator . "COMPAREFRONT") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPAREFRONT")
  1)

(deftest "sysvar-comparehatch-getvar-type"
  '((operator . "COMPAREHATCH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPAREHATCH"))
  'int)

(deftest "sysvar-comparehatch-getvar-default"
  '((operator . "COMPAREHATCH") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPAREHATCH")
  0)

(deftest "sysvar-compareprops-getvar-type"
  '((operator . "COMPAREPROPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPAREPROPS"))
  'int)

(deftest "sysvar-compareprops-getvar-default"
  '((operator . "COMPAREPROPS") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPAREPROPS")
  0)

(deftest "sysvar-comparercmargin-getvar-type"
  '((operator . "COMPARERCMARGIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARERCMARGIN"))
  'int)

(deftest "sysvar-comparercmargin-getvar-default"
  '((operator . "COMPARERCMARGIN") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARERCMARGIN")
  5)

(deftest "sysvar-comparercshape-getvar-type"
  '((operator . "COMPARERCSHAPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARERCSHAPE"))
  'int)

(deftest "sysvar-comparercshape-getvar-default"
  '((operator . "COMPARERCSHAPE") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARERCSHAPE")
  0)

(deftest "sysvar-compareshow1-getvar-type"
  '((operator . "COMPARESHOW1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARESHOW1"))
  'int)

(deftest "sysvar-compareshow1-getvar-default"
  '((operator . "COMPARESHOW1") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARESHOW1")
  1)

(deftest "sysvar-compareshow2-getvar-type"
  '((operator . "COMPARESHOW2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARESHOW2"))
  'int)

(deftest "sysvar-compareshow2-getvar-default"
  '((operator . "COMPARESHOW2") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARESHOW2")
  1)

(deftest "sysvar-compareshowcommon-getvar-type"
  '((operator . "COMPARESHOWCOMMON") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARESHOWCOMMON"))
  'int)

(deftest "sysvar-compareshowcommon-getvar-default"
  '((operator . "COMPARESHOWCOMMON") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARESHOWCOMMON")
  1)

(deftest "sysvar-compareshowcontext-getvar-type"
  '((operator . "COMPARESHOWCONTEXT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARESHOWCONTEXT"))
  'int)

(deftest "sysvar-compareshowcontext-getvar-default"
  '((operator . "COMPARESHOWCONTEXT") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARESHOWCONTEXT")
  1)

(deftest "sysvar-compareshowrc-getvar-type"
  '((operator . "COMPARESHOWRC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARESHOWRC"))
  'int)

(deftest "sysvar-compareshowrc-getvar-default"
  '((operator . "COMPARESHOWRC") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARESHOWRC")
  1)

(deftest "sysvar-comparetext-getvar-type"
  '((operator . "COMPARETEXT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARETEXT"))
  'int)

(deftest "sysvar-comparetext-getvar-default"
  '((operator . "COMPARETEXT") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARETEXT")
  1)

(deftest "sysvar-comparetolerance-getvar-type"
  '((operator . "COMPARETOLERANCE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPARETOLERANCE"))
  'int)

(deftest "sysvar-comparetolerance-getvar-default"
  '((operator . "COMPARETOLERANCE") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPARETOLERANCE")
  6)

(deftest "sysvar-compass-getvar-type"
  '((operator . "COMPASS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPASS"))
  'int)

(deftest "sysvar-compass-getvar-default"
  '((operator . "COMPASS") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPASS")
  0)

(deftest "sysvar-complexltpreview-getvar-type"
  '((operator . "COMPLEXLTPREVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COMPLEXLTPREVIEW"))
  'int)

(deftest "sysvar-complexltpreview-getvar-default"
  '((operator . "COMPLEXLTPREVIEW") (area . "sysvar") (profile . STRICT))
  '(getvar "COMPLEXLTPREVIEW")
  1)

(deftest "sysvar-componentsconfig-getvar-type"
  '((operator . "COMPONENTSCONFIG") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COMPONENTSCONFIG"))
  'str)

(deftest "sysvar-componentspath-getvar-type"
  '((operator . "COMPONENTSPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COMPONENTSPATH"))
  'str)

(deftest "sysvar-constraintbardisplay-getvar-type"
  '((operator . "CONSTRAINTBARDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CONSTRAINTBARDISPLAY"))
  'int)

(deftest "sysvar-constraintbarmode-getvar-type"
  '((operator . "CONSTRAINTBARMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CONSTRAINTBARMODE"))
  'int)

(deftest "sysvar-constraintbarmode-getvar-default"
  '((operator . "CONSTRAINTBARMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "CONSTRAINTBARMODE")
  4095)

(deftest "sysvar-constraintinfer-getvar-type"
  '((operator . "CONSTRAINTINFER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CONSTRAINTINFER"))
  'int)

(deftest "sysvar-constraintinfer-getvar-default"
  '((operator . "CONSTRAINTINFER") (area . "sysvar") (profile . STRICT))
  '(getvar "CONSTRAINTINFER")
  0)

(deftest "sysvar-constraintnameformat-getvar-type"
  '((operator . "CONSTRAINTNAMEFORMAT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CONSTRAINTNAMEFORMAT"))
  'int)

(deftest "sysvar-constraintnameformat-getvar-default"
  '((operator . "CONSTRAINTNAMEFORMAT") (area . "sysvar") (profile . STRICT))
  '(getvar "CONSTRAINTNAMEFORMAT")
  2)

(deftest "sysvar-constraintsolvemode-getvar-type"
  '((operator . "CONSTRAINTSOLVEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CONSTRAINTSOLVEMODE"))
  'int)

(deftest "sysvar-constraintsolvemode-getvar-default"
  '((operator . "CONSTRAINTSOLVEMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "CONSTRAINTSOLVEMODE")
  1)

(deftest "sysvar-continuousmotion-getvar-type"
  '((operator . "CONTINUOUSMOTION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CONTINUOUSMOTION"))
  'int)

(deftest "sysvar-continuousmotion-getvar-default"
  '((operator . "CONTINUOUSMOTION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CONTINUOUSMOTION")
  0)

(deftest "sysvar-convertodmax-getvar-type"
  '((operator . "CONVERTODMAX") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CONVERTODMAX"))
  'real)

(deftest "sysvar-convertodmax-getvar-default"
  '((operator . "CONVERTODMAX") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CONVERTODMAX")
  1.1)

(deftest "sysvar-convertodmin-getvar-type"
  '((operator . "CONVERTODMIN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CONVERTODMIN"))
  'real)

(deftest "sysvar-convertodmin-getvar-default"
  '((operator . "CONVERTODMIN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CONVERTODMIN")
  0.95)

(deftest "sysvar-convertthmax-getvar-type"
  '((operator . "CONVERTTHMAX") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CONVERTTHMAX"))
  'real)

(deftest "sysvar-convertthmax-getvar-default"
  '((operator . "CONVERTTHMAX") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CONVERTTHMAX")
  2.0)

(deftest "sysvar-convertthmin-getvar-type"
  '((operator . "CONVERTTHMIN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CONVERTTHMIN"))
  'real)

(deftest "sysvar-convertthmin-getvar-default"
  '((operator . "CONVERTTHMIN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CONVERTTHMIN")
  0.5)

(deftest "sysvar-coords-getvar-type"
  '((operator . "COORDS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COORDS"))
  'int)

(deftest "sysvar-copyguided3ddisplaysourcefaces-getvar-type"
  '((operator . "COPYGUIDED3DDISPLAYSOURCEFACES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "COPYGUIDED3DDISPLAYSOURCEFACES"))
  'int)

(deftest "sysvar-copyguided3ddisplaysourcefaces-getvar-default"
  '((operator . "COPYGUIDED3DDISPLAYSOURCEFACES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "COPYGUIDED3DDISPLAYSOURCEFACES")
  1)

(deftest "sysvar-copymode-getvar-type"
  '((operator . "COPYMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COPYMODE"))
  'int)

(deftest "sysvar-countcheck-getvar-type"
  '((operator . "COUNTCHECK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COUNTCHECK"))
  'int)

(deftest "sysvar-countcheck-getvar-default"
  '((operator . "COUNTCHECK") (area . "sysvar") (profile . STRICT))
  '(getvar "COUNTCHECK")
  2)

(deftest "sysvar-countcolor-getvar-type"
  '((operator . "COUNTCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COUNTCOLOR"))
  'int)

(deftest "sysvar-countcolor-getvar-default"
  '((operator . "COUNTCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "COUNTCOLOR")
  3)

(deftest "sysvar-counterrorcolor-getvar-type"
  '((operator . "COUNTERRORCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COUNTERRORCOLOR"))
  'int)

(deftest "sysvar-counterrorcolor-getvar-default"
  '((operator . "COUNTERRORCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "COUNTERRORCOLOR")
  1)

(deftest "sysvar-counterrornum-getvar-type"
  '((operator . "COUNTERRORNUM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COUNTERRORNUM"))
  'int)

(deftest-error "sysvar-counterrornum-setvar-readonly-signals"
  '((operator . "COUNTERRORNUM") (area . "sysvar") (profile . STRICT))
  '(setvar "COUNTERRORNUM" 0)
  'sysvar-read-only)

(deftest "sysvar-countnumber-getvar-type"
  '((operator . "COUNTNUMBER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COUNTNUMBER"))
  'int)

(deftest-error "sysvar-countnumber-setvar-readonly-signals"
  '((operator . "COUNTNUMBER") (area . "sysvar") (profile . STRICT))
  '(setvar "COUNTNUMBER" 0)
  'sysvar-read-only)

(deftest "sysvar-countpalettestate-getvar-type"
  '((operator . "COUNTPALETTESTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COUNTPALETTESTATE"))
  'int)

(deftest-error "sysvar-countpalettestate-setvar-readonly-signals"
  '((operator . "COUNTPALETTESTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "COUNTPALETTESTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-countservice-getvar-type"
  '((operator . "COUNTSERVICE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "COUNTSERVICE"))
  'int)

(deftest "sysvar-countservice-getvar-default"
  '((operator . "COUNTSERVICE") (area . "sysvar") (profile . STRICT))
  '(getvar "COUNTSERVICE")
  1)

(deftest "sysvar-cplotstyle-getvar-type"
  '((operator . "CPLOTSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CPLOTSTYLE"))
  'str)

(deftest "sysvar-cplotstyle-getvar-default"
  '((operator . "CPLOTSTYLE") (area . "sysvar") (profile . STRICT))
  '(getvar "CPLOTSTYLE")
  "ByColor")

(deftest "sysvar-cprofile-getvar-type"
  '((operator . "CPROFILE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CPROFILE"))
  'str)

(deftest-error "sysvar-cprofile-setvar-readonly-signals"
  '((operator . "CPROFILE") (area . "sysvar") (profile . STRICT))
  '(setvar "CPROFILE" "")
  'sysvar-read-only)

(deftest "sysvar-crashreportsending-getvar-type"
  '((operator . "CRASHREPORTSENDING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CRASHREPORTSENDING"))
  'int)

(deftest "sysvar-crashreportsending-getvar-default"
  '((operator . "CRASHREPORTSENDING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CRASHREPORTSENDING")
  0)

(deftest "sysvar-createsketchfeature-getvar-type"
  '((operator . "CREATESKETCHFEATURE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CREATESKETCHFEATURE"))
  'int)

(deftest "sysvar-createsketchfeature-getvar-default"
  '((operator . "CREATESKETCHFEATURE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CREATESKETCHFEATURE")
  0)

(deftest "sysvar-createthumbnailonthefly-getvar-type"
  '((operator . "CREATETHUMBNAILONTHEFLY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CREATETHUMBNAILONTHEFLY"))
  'int)

(deftest "sysvar-createthumbnailonthefly-getvar-default"
  '((operator . "CREATETHUMBNAILONTHEFLY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CREATETHUMBNAILONTHEFLY")
  1)

(deftest "sysvar-createviewports-getvar-type"
  '((operator . "CREATEVIEWPORTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CREATEVIEWPORTS"))
  'int)

(deftest "sysvar-createviewports-getvar-default"
  '((operator . "CREATEVIEWPORTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CREATEVIEWPORTS")
  1)

(deftest "sysvar-crosshairdrawmode-getvar-type"
  '((operator . "CROSSHAIRDRAWMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CROSSHAIRDRAWMODE"))
  'int)

(deftest "sysvar-crossingareacolor-getvar-type"
  '((operator . "CROSSINGAREACOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CROSSINGAREACOLOR"))
  'int)

(deftest "sysvar-ctab-getvar-type"
  '((operator . "CTAB") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CTAB"))
  'str)

(deftest "sysvar-ctab-getvar-default"
  '((operator . "CTAB") (area . "sysvar") (profile . STRICT))
  '(getvar "CTAB")
  "Model")

(deftest "sysvar-ctablestyle-getvar-type"
  '((operator . "CTABLESTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CTABLESTYLE"))
  'str)

(deftest "sysvar-ctablestyle-getvar-default"
  '((operator . "CTABLESTYLE") (area . "sysvar") (profile . STRICT))
  '(getvar "CTABLESTYLE")
  "Standard")

(deftest "sysvar-ctrl3dmouse-getvar-type"
  '((operator . "CTRL3DMOUSE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CTRL3DMOUSE"))
  'int)

(deftest "sysvar-ctrl3dmouse-getvar-default"
  '((operator . "CTRL3DMOUSE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CTRL3DMOUSE")
  1)

(deftest "sysvar-ctrlmbutton-getvar-type"
  '((operator . "CTRLMBUTTON") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CTRLMBUTTON"))
  'str)

(deftest "sysvar-ctrlmouse-getvar-type"
  '((operator . "CTRLMOUSE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CTRLMOUSE"))
  'int)

(deftest "sysvar-ctrlmouse-getvar-default"
  '((operator . "CTRLMOUSE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CTRLMOUSE")
  1)

(deftest "sysvar-cullingobj-getvar-type"
  '((operator . "CULLINGOBJ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CULLINGOBJ"))
  'int)

(deftest "sysvar-cullingobj-getvar-default"
  '((operator . "CULLINGOBJ") (area . "sysvar") (profile . STRICT))
  '(getvar "CULLINGOBJ")
  1)

(deftest "sysvar-cullingobjselection-getvar-type"
  '((operator . "CULLINGOBJSELECTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CULLINGOBJSELECTION"))
  'int)

(deftest "sysvar-cullingobjselection-getvar-default"
  '((operator . "CULLINGOBJSELECTION") (area . "sysvar") (profile . STRICT))
  '(getvar "CULLINGOBJSELECTION")
  0)

(deftest "sysvar-cursorbadge-getvar-type"
  '((operator . "CURSORBADGE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CURSORBADGE"))
  'int)

(deftest "sysvar-cursorbadge-getvar-default"
  '((operator . "CURSORBADGE") (area . "sysvar") (profile . STRICT))
  '(getvar "CURSORBADGE")
  2)

(deftest "sysvar-cursormode-getvar-type"
  '((operator . "CURSORMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CURSORMODE"))
  'str)

(deftest "sysvar-cursorsize-getvar-type"
  '((operator . "CURSORSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CURSORSIZE"))
  'int)

(deftest "sysvar-cursortype-getvar-type"
  '((operator . "CURSORTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CURSORTYPE"))
  'int)

(deftest "sysvar-cursortype-getvar-default"
  '((operator . "CURSORTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "CURSORTYPE")
  0)

(deftest "sysvar-cvallowbreaklinecrossings-getvar-type"
  '((operator . "CVALLOWBREAKLINECROSSINGS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVALLOWBREAKLINECROSSINGS"))
  'int)

(deftest "sysvar-cvallowbreaklinecrossings-getvar-default"
  '((operator . "CVALLOWBREAKLINECROSSINGS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVALLOWBREAKLINECROSSINGS")
  1)

(deftest "sysvar-cvanglesamplinginterval-getvar-type"
  '((operator . "CVANGLESAMPLINGINTERVAL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVANGLESAMPLINGINTERVAL"))
  'real)

(deftest "sysvar-cvanglesamplinginterval-getvar-default"
  '((operator . "CVANGLESAMPLINGINTERVAL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVANGLESAMPLINGINTERVAL")
  5.0)

(deftest "sysvar-cvarctessellationgrading-getvar-type"
  '((operator . "CVARCTESSELLATIONGRADING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVARCTESSELLATIONGRADING"))
  'real)

(deftest "sysvar-cvarctessellationgrading-getvar-default"
  '((operator . "CVARCTESSELLATIONGRADING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVARCTESSELLATIONGRADING")
  0.01)

(deftest "sysvar-cvarctessellationsurface-getvar-type"
  '((operator . "CVARCTESSELLATIONSURFACE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVARCTESSELLATIONSURFACE"))
  'real)

(deftest "sysvar-cvarctessellationsurface-getvar-default"
  '((operator . "CVARCTESSELLATIONSURFACE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVARCTESSELLATIONSURFACE")
  0.01)

(deftest "sysvar-cvarctessellationtemplateelement-getvar-type"
  '((operator . "CVARCTESSELLATIONTEMPLATEELEMENT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVARCTESSELLATIONTEMPLATEELEMENT"))
  'real)

(deftest "sysvar-cvarctessellationtemplateelement-getvar-default"
  '((operator . "CVARCTESSELLATIONTEMPLATEELEMENT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVARCTESSELLATIONTEMPLATEELEMENT")
  0.01)

(deftest "sysvar-cvassociativity-getvar-type"
  '((operator . "CVASSOCIATIVITY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVASSOCIATIVITY"))
  'int)

(deftest "sysvar-cvassociativity-getvar-default"
  '((operator . "CVASSOCIATIVITY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVASSOCIATIVITY")
  15)

(deftest "sysvar-cvdefaultcurvetypeha-getvar-type"
  '((operator . "CVDEFAULTCURVETYPEHA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVDEFAULTCURVETYPEHA"))
  'int)

(deftest "sysvar-cvdefaultcurvetypeha-getvar-default"
  '((operator . "CVDEFAULTCURVETYPEHA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVDEFAULTCURVETYPEHA")
  0)

(deftest "sysvar-cvdefaultcurvetypeva-getvar-type"
  '((operator . "CVDEFAULTCURVETYPEVA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVDEFAULTCURVETYPEVA"))
  'int)

(deftest "sysvar-cvdefaultcurvetypeva-getvar-default"
  '((operator . "CVDEFAULTCURVETYPEVA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVDEFAULTCURVETYPEVA")
  2)

(deftest "sysvar-cvelevationatbreaklinecrossings-getvar-type"
  '((operator . "CVELEVATIONATBREAKLINECROSSINGS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVELEVATIONATBREAKLINECROSSINGS"))
  'int)

(deftest "sysvar-cvelevationatbreaklinecrossings-getvar-default"
  '((operator . "CVELEVATIONATBREAKLINECROSSINGS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVELEVATIONATBREAKLINECROSSINGS")
  0)

(deftest "sysvar-cversioncontrolpath-getvar-type"
  '((operator . "CVERSIONCONTROLPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVERSIONCONTROLPATH"))
  'str)

(deftest "sysvar-cvgradeunit-getvar-type"
  '((operator . "CVGRADEUNIT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVGRADEUNIT"))
  'int)

(deftest "sysvar-cvgradeunit-getvar-default"
  '((operator . "CVGRADEUNIT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVGRADEUNIT")
  0)

(deftest "sysvar-cvgradeunitprec-getvar-type"
  '((operator . "CVGRADEUNITPREC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVGRADEUNITPREC"))
  'int)

(deftest "sysvar-cvgradeunitprec-getvar-default"
  '((operator . "CVGRADEUNITPREC") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVGRADEUNITPREC")
  2)

(deftest "sysvar-cviewdetailstyle-getvar-type"
  '((operator . "CVIEWDETAILSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CVIEWDETAILSTYLE"))
  'str)

(deftest "sysvar-cvlengthsamplinginterval-getvar-type"
  '((operator . "CVLENGTHSAMPLINGINTERVAL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVLENGTHSAMPLINGINTERVAL"))
  'real)

(deftest "sysvar-cvlengthsamplinginterval-getvar-default"
  '((operator . "CVLENGTHSAMPLINGINTERVAL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVLENGTHSAMPLINGINTERVAL")
  1.0)

(deftest "sysvar-cvport-getvar-type"
  '((operator . "CVPORT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "CVPORT"))
  'int)

(deftest "sysvar-cvslopeunit-getvar-type"
  '((operator . "CVSLOPEUNIT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVSLOPEUNIT"))
  'int)

(deftest "sysvar-cvslopeunit-getvar-default"
  '((operator . "CVSLOPEUNIT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVSLOPEUNIT")
  0)

(deftest "sysvar-cvslopeunitprec-getvar-type"
  '((operator . "CVSLOPEUNITPREC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVSLOPEUNITPREC"))
  'int)

(deftest "sysvar-cvslopeunitprec-getvar-default"
  '((operator . "CVSLOPEUNITPREC") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVSLOPEUNITPREC")
  1)

(deftest "sysvar-cvstationunit-getvar-type"
  '((operator . "CVSTATIONUNIT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVSTATIONUNIT"))
  'int)

(deftest "sysvar-cvstationunit-getvar-default"
  '((operator . "CVSTATIONUNIT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVSTATIONUNIT")
  3)

(deftest "sysvar-cvstationunitprec-getvar-type"
  '((operator . "CVSTATIONUNITPREC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "CVSTATIONUNITPREC"))
  'int)

(deftest "sysvar-cvstationunitprec-getvar-default"
  '((operator . "CVSTATIONUNITPREC") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "CVSTATIONUNITPREC")
  2)

(deftest "sysvar-datacollection-getvar-type"
  '((operator . "DATACOLLECTION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DATACOLLECTION"))
  'int)

(deftest "sysvar-datacollection-getvar-default"
  '((operator . "DATACOLLECTION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DATACOLLECTION")
  -2)

(deftest "sysvar-datacollectionenabled-getvar-type"
  '((operator . "DATACOLLECTIONENABLED") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DATACOLLECTIONENABLED"))
  'int)

(deftest-error "sysvar-datacollectionenabled-setvar-readonly-signals"
  '((operator . "DATACOLLECTIONENABLED") (area . "sysvar") (profile . BRICSCAD))
  '(setvar "DATACOLLECTIONENABLED" 0)
  'sysvar-read-only)

(deftest "sysvar-datacollectionlogintype-getvar-type"
  '((operator . "DATACOLLECTIONLOGINTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DATACOLLECTIONLOGINTYPE"))
  'int)

(deftest-error "sysvar-datacollectionlogintype-setvar-readonly-signals"
  '((operator . "DATACOLLECTIONLOGINTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(setvar "DATACOLLECTIONLOGINTYPE" 0)
  'sysvar-read-only)

(deftest "sysvar-datacollectionoptions-getvar-type"
  '((operator . "DATACOLLECTIONOPTIONS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DATACOLLECTIONOPTIONS"))
  'int)

(deftest "sysvar-datacollectionoptions-getvar-default"
  '((operator . "DATACOLLECTIONOPTIONS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DATACOLLECTIONOPTIONS")
  0)

(deftest "sysvar-datalinknotify-getvar-type"
  '((operator . "DATALINKNOTIFY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DATALINKNOTIFY"))
  'int)

(deftest "sysvar-date-getvar-type"
  '((operator . "DATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DATE"))
  'real)

(deftest-error "sysvar-date-setvar-readonly-signals"
  '((operator . "DATE") (area . "sysvar") (profile . STRICT))
  '(setvar "DATE" 0.0)
  'sysvar-read-only)

(deftest "sysvar-dbcstate-getvar-type"
  '((operator . "DBCSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DBCSTATE"))
  'int)

(deftest-error "sysvar-dbcstate-setvar-readonly-signals"
  '((operator . "DBCSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "DBCSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-dblclkedit-getvar-type"
  '((operator . "DBLCLKEDIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DBLCLKEDIT"))
  'int)

(deftest "sysvar-dblclkedit-getvar-default"
  '((operator . "DBLCLKEDIT") (area . "sysvar") (profile . STRICT))
  '(getvar "DBLCLKEDIT")
  1)

(deftest "sysvar-dbmod-getvar-type"
  '((operator . "DBMOD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DBMOD"))
  'int)

(deftest-error "sysvar-dbmod-setvar-readonly-signals"
  '((operator . "DBMOD") (area . "sysvar") (profile . STRICT))
  '(setvar "DBMOD" 0)
  'sysvar-read-only)

(deftest "sysvar-dctcust-getvar-type"
  '((operator . "DCTCUST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DCTCUST"))
  'str)

(deftest "sysvar-dctmain-getvar-type"
  '((operator . "DCTMAIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DCTMAIN"))
  'str)

(deftest "sysvar-defaultbsyslibimperial-getvar-type"
  '((operator . "DEFAULTBSYSLIBIMPERIAL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTBSYSLIBIMPERIAL"))
  'str)

(deftest "sysvar-defaultbsyslibmetric-getvar-type"
  '((operator . "DEFAULTBSYSLIBMETRIC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTBSYSLIBMETRIC"))
  'str)

(deftest "sysvar-defaultgizmo-getvar-type"
  '((operator . "DEFAULTGIZMO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DEFAULTGIZMO"))
  'int)

(deftest "sysvar-defaultgizmo-getvar-default"
  '((operator . "DEFAULTGIZMO") (area . "sysvar") (profile . STRICT))
  '(getvar "DEFAULTGIZMO")
  0)

(deftest "sysvar-defaultlighting-getvar-type"
  '((operator . "DEFAULTLIGHTING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DEFAULTLIGHTING"))
  'int)

(deftest "sysvar-defaultlightingtype-getvar-type"
  '((operator . "DEFAULTLIGHTINGTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DEFAULTLIGHTINGTYPE"))
  'int)

(deftest "sysvar-defaultlightingtype-getvar-default"
  '((operator . "DEFAULTLIGHTINGTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "DEFAULTLIGHTINGTYPE")
  1)

(deftest "sysvar-defaultlightshadowblur-getvar-type"
  '((operator . "DEFAULTLIGHTSHADOWBLUR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTLIGHTSHADOWBLUR"))
  'int)

(deftest "sysvar-defaultlightshadowblur-getvar-default"
  '((operator . "DEFAULTLIGHTSHADOWBLUR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DEFAULTLIGHTSHADOWBLUR")
  8)

(deftest "sysvar-defaultnewsheettemplate-getvar-type"
  '((operator . "DEFAULTNEWSHEETTEMPLATE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTNEWSHEETTEMPLATE"))
  'str)

(deftest "sysvar-defaultplotstyletable-getvar-type"
  '((operator . "DEFAULTPLOTSTYLETABLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTPLOTSTYLETABLE"))
  'str)

(deftest "sysvar-defaultspaceheight-getvar-type"
  '((operator . "DEFAULTSPACEHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTSPACEHEIGHT"))
  'real)

(deftest "sysvar-defaultstorynamingscheme-getvar-type"
  '((operator . "DEFAULTSTORYNAMINGSCHEME") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTSTORYNAMINGSCHEME"))
  'str)

(deftest "sysvar-defaultstylepipecross-getvar-type"
  '((operator . "DEFAULTSTYLEPIPECROSS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTSTYLEPIPECROSS"))
  'str)

(deftest "sysvar-defaultstylepipecross-getvar-default"
  '((operator . "DEFAULTSTYLEPIPECROSS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DEFAULTSTYLEPIPECROSS")
  "ASME B16.9 Cross")

(deftest "sysvar-defaultstylepipeeccentricreducer-getvar-type"
  '((operator . "DEFAULTSTYLEPIPEECCENTRICREDUCER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTSTYLEPIPEECCENTRICREDUCER"))
  'str)

(deftest "sysvar-defaultstylepipeeccentricreducer-getvar-default"
  '((operator . "DEFAULTSTYLEPIPEECCENTRICREDUCER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DEFAULTSTYLEPIPEECCENTRICREDUCER")
  "ASME B16.9 Eccentric Reducer")

(deftest "sysvar-defaultstylepipeelbow45-getvar-type"
  '((operator . "DEFAULTSTYLEPIPEELBOW45") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTSTYLEPIPEELBOW45"))
  'str)

(deftest "sysvar-defaultstylepipeelbow45-getvar-default"
  '((operator . "DEFAULTSTYLEPIPEELBOW45") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DEFAULTSTYLEPIPEELBOW45")
  "ASME B16.9 Elbow LR 45 Deg")

(deftest "sysvar-defaultstylepipeelbow90-getvar-type"
  '((operator . "DEFAULTSTYLEPIPEELBOW90") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTSTYLEPIPEELBOW90"))
  'str)

(deftest "sysvar-defaultstylepipeelbow90-getvar-default"
  '((operator . "DEFAULTSTYLEPIPEELBOW90") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DEFAULTSTYLEPIPEELBOW90")
  "ASME B16.9 Elbow LR 90 Deg")

(deftest "sysvar-defaultstylepipereducer-getvar-type"
  '((operator . "DEFAULTSTYLEPIPEREDUCER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTSTYLEPIPEREDUCER"))
  'str)

(deftest "sysvar-defaultstylepipereducer-getvar-default"
  '((operator . "DEFAULTSTYLEPIPEREDUCER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DEFAULTSTYLEPIPEREDUCER")
  "ASME B16.9 Reducer")

(deftest "sysvar-defaultstylepipesegment-getvar-type"
  '((operator . "DEFAULTSTYLEPIPESEGMENT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTSTYLEPIPESEGMENT"))
  'str)

(deftest "sysvar-defaultstylepipesegment-getvar-default"
  '((operator . "DEFAULTSTYLEPIPESEGMENT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DEFAULTSTYLEPIPESEGMENT")
  "ASME B36.10M Pipe")

(deftest "sysvar-defaultstylepipetee-getvar-type"
  '((operator . "DEFAULTSTYLEPIPETEE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DEFAULTSTYLEPIPETEE"))
  'str)

(deftest "sysvar-defaultstylepipetee-getvar-default"
  '((operator . "DEFAULTSTYLEPIPETEE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DEFAULTSTYLEPIPETEE")
  "ASME B16.9 Tee")

(deftest "sysvar-deflplstyle-getvar-type"
  '((operator . "DEFLPLSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DEFLPLSTYLE"))
  'str)

(deftest "sysvar-deflplstyle-getvar-default"
  '((operator . "DEFLPLSTYLE") (area . "sysvar") (profile . STRICT))
  '(getvar "DEFLPLSTYLE")
  "Normal")

(deftest "sysvar-defplstyle-getvar-type"
  '((operator . "DEFPLSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DEFPLSTYLE"))
  'str)

(deftest "sysvar-defplstyle-getvar-default"
  '((operator . "DEFPLSTYLE") (area . "sysvar") (profile . STRICT))
  '(getvar "DEFPLSTYLE")
  "ByLayer")

(deftest "sysvar-deletetool-getvar-type"
  '((operator . "DELETETOOL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DELETETOOL"))
  'int)

(deftest "sysvar-deletetool-getvar-default"
  '((operator . "DELETETOOL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DELETETOOL")
  0)

(deftest "sysvar-delobj-getvar-type"
  '((operator . "DELOBJ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DELOBJ"))
  'int)

(deftest "sysvar-demandload-getvar-type"
  '((operator . "DEMANDLOAD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DEMANDLOAD"))
  'int)

(deftest "sysvar-detailspath-getvar-type"
  '((operator . "DETAILSPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DETAILSPATH"))
  'str)

(deftest "sysvar-dgnexpxrefmode-getvar-type"
  '((operator . "DGNEXPXREFMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNEXPXREFMODE"))
  'int)

(deftest "sysvar-dgnexpxrefmode-getvar-default"
  '((operator . "DGNEXPXREFMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNEXPXREFMODE")
  0)

(deftest "sysvar-dgnframe-getvar-type"
  '((operator . "DGNFRAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DGNFRAME"))
  'int)

(deftest "sysvar-dgnimp2dclosedbsplinecurveimportmode-getvar-type"
  '((operator . "DGNIMP2DCLOSEDBSPLINECURVEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMP2DCLOSEDBSPLINECURVEIMPORTMODE"))
  'int)

(deftest "sysvar-dgnimp2dclosedbsplinecurveimportmode-getvar-default"
  '((operator . "DGNIMP2DCLOSEDBSPLINECURVEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMP2DCLOSEDBSPLINECURVEIMPORTMODE")
  0)

(deftest "sysvar-dgnimp2dellipseimportmode-getvar-type"
  '((operator . "DGNIMP2DELLIPSEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMP2DELLIPSEIMPORTMODE"))
  'int)

(deftest "sysvar-dgnimp2dellipseimportmode-getvar-default"
  '((operator . "DGNIMP2DELLIPSEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMP2DELLIPSEIMPORTMODE")
  0)

(deftest "sysvar-dgnimp2dshapeimportmode-getvar-type"
  '((operator . "DGNIMP2DSHAPEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMP2DSHAPEIMPORTMODE"))
  'int)

(deftest "sysvar-dgnimp2dshapeimportmode-getvar-default"
  '((operator . "DGNIMP2DSHAPEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMP2DSHAPEIMPORTMODE")
  0)

(deftest "sysvar-dgnimp3dclosedbsplinecurveimportmode-getvar-type"
  '((operator . "DGNIMP3DCLOSEDBSPLINECURVEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMP3DCLOSEDBSPLINECURVEIMPORTMODE"))
  'int)

(deftest "sysvar-dgnimp3dclosedbsplinecurveimportmode-getvar-default"
  '((operator . "DGNIMP3DCLOSEDBSPLINECURVEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMP3DCLOSEDBSPLINECURVEIMPORTMODE")
  1)

(deftest "sysvar-dgnimp3dellipseimportmode-getvar-type"
  '((operator . "DGNIMP3DELLIPSEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMP3DELLIPSEIMPORTMODE"))
  'int)

(deftest "sysvar-dgnimp3dellipseimportmode-getvar-default"
  '((operator . "DGNIMP3DELLIPSEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMP3DELLIPSEIMPORTMODE")
  0)

(deftest "sysvar-dgnimp3dobjectimportmode-getvar-type"
  '((operator . "DGNIMP3DOBJECTIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMP3DOBJECTIMPORTMODE"))
  'int)

(deftest "sysvar-dgnimp3dobjectimportmode-getvar-default"
  '((operator . "DGNIMP3DOBJECTIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMP3DOBJECTIMPORTMODE")
  1)

(deftest "sysvar-dgnimp3dshapeimportmode-getvar-type"
  '((operator . "DGNIMP3DSHAPEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMP3DSHAPEIMPORTMODE"))
  'int)

(deftest "sysvar-dgnimp3dshapeimportmode-getvar-default"
  '((operator . "DGNIMP3DSHAPEIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMP3DSHAPEIMPORTMODE")
  1)

(deftest "sysvar-dgnimpbreakdimensionassociation-getvar-type"
  '((operator . "DGNIMPBREAKDIMENSIONASSOCIATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPBREAKDIMENSIONASSOCIATION"))
  'int)

(deftest "sysvar-dgnimpbreakdimensionassociation-getvar-default"
  '((operator . "DGNIMPBREAKDIMENSIONASSOCIATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPBREAKDIMENSIONASSOCIATION")
  0)

(deftest "sysvar-dgnimpconvertdgncolorindicestotruecolors-getvar-type"
  '((operator . "DGNIMPCONVERTDGNCOLORINDICESTOTRUECOLORS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPCONVERTDGNCOLORINDICESTOTRUECOLORS"))
  'int)

(deftest "sysvar-dgnimpconvertdgncolorindicestotruecolors-getvar-default"
  '((operator . "DGNIMPCONVERTDGNCOLORINDICESTOTRUECOLORS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPCONVERTDGNCOLORINDICESTOTRUECOLORS")
  0)

(deftest "sysvar-dgnimpconvertemptydatafieldstospaces-getvar-type"
  '((operator . "DGNIMPCONVERTEMPTYDATAFIELDSTOSPACES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPCONVERTEMPTYDATAFIELDSTOSPACES"))
  'int)

(deftest "sysvar-dgnimpconvertemptydatafieldstospaces-getvar-default"
  '((operator . "DGNIMPCONVERTEMPTYDATAFIELDSTOSPACES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPCONVERTEMPTYDATAFIELDSTOSPACES")
  1)

(deftest "sysvar-dgnimperaseunusedresources-getvar-type"
  '((operator . "DGNIMPERASEUNUSEDRESOURCES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPERASEUNUSEDRESOURCES"))
  'int)

(deftest "sysvar-dgnimperaseunusedresources-getvar-default"
  '((operator . "DGNIMPERASEUNUSEDRESOURCES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPERASEUNUSEDRESOURCES")
  0)

(deftest "sysvar-dgnimpexplodetextnodes-getvar-type"
  '((operator . "DGNIMPEXPLODETEXTNODES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPEXPLODETEXTNODES"))
  'int)

(deftest "sysvar-dgnimpexplodetextnodes-getvar-default"
  '((operator . "DGNIMPEXPLODETEXTNODES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPEXPLODETEXTNODES")
  0)

(deftest "sysvar-dgnimpimportactivemodeltomodelspace-getvar-type"
  '((operator . "DGNIMPIMPORTACTIVEMODELTOMODELSPACE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPIMPORTACTIVEMODELTOMODELSPACE"))
  'int)

(deftest "sysvar-dgnimpimportactivemodeltomodelspace-getvar-default"
  '((operator . "DGNIMPIMPORTACTIVEMODELTOMODELSPACE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPIMPORTACTIVEMODELTOMODELSPACE")
  1)

(deftest "sysvar-dgnimpimportdgtextsasdbmtexts-getvar-type"
  '((operator . "DGNIMPIMPORTDGTEXTSASDBMTEXTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPIMPORTDGTEXTSASDBMTEXTS"))
  'int)

(deftest "sysvar-dgnimpimportdgtextsasdbmtexts-getvar-default"
  '((operator . "DGNIMPIMPORTDGTEXTSASDBMTEXTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPIMPORTDGTEXTSASDBMTEXTS")
  0)

(deftest "sysvar-dgnimpimportinvisibleelements-getvar-type"
  '((operator . "DGNIMPIMPORTINVISIBLEELEMENTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPIMPORTINVISIBLEELEMENTS"))
  'int)

(deftest "sysvar-dgnimpimportinvisibleelements-getvar-default"
  '((operator . "DGNIMPIMPORTINVISIBLEELEMENTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPIMPORTINVISIBLEELEMENTS")
  1)

(deftest "sysvar-dgnimpimportpaperspacemodels-getvar-type"
  '((operator . "DGNIMPIMPORTPAPERSPACEMODELS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPIMPORTPAPERSPACEMODELS"))
  'int)

(deftest "sysvar-dgnimpimportpaperspacemodels-getvar-default"
  '((operator . "DGNIMPIMPORTPAPERSPACEMODELS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPIMPORTPAPERSPACEMODELS")
  1)

(deftest "sysvar-dgnimpimportviewindex-getvar-type"
  '((operator . "DGNIMPIMPORTVIEWINDEX") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPIMPORTVIEWINDEX"))
  'int)

(deftest "sysvar-dgnimpimportviewindex-getvar-default"
  '((operator . "DGNIMPIMPORTVIEWINDEX") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPIMPORTVIEWINDEX")
  -1)

(deftest "sysvar-dgnimportmax-getvar-type"
  '((operator . "DGNIMPORTMAX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DGNIMPORTMAX"))
  'int)

(deftest "sysvar-dgnimportmax-getvar-default"
  '((operator . "DGNIMPORTMAX") (area . "sysvar") (profile . STRICT))
  '(getvar "DGNIMPORTMAX")
  10000000)

(deftest "sysvar-dgnimportmode-getvar-type"
  '((operator . "DGNIMPORTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DGNIMPORTMODE"))
  'int)

(deftest "sysvar-dgnimportmode-getvar-default"
  '((operator . "DGNIMPORTMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "DGNIMPORTMODE")
  0)

(deftest "sysvar-dgnimprecomputedimensionsafterimport-getvar-type"
  '((operator . "DGNIMPRECOMPUTEDIMENSIONSAFTERIMPORT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPRECOMPUTEDIMENSIONSAFTERIMPORT"))
  'int)

(deftest "sysvar-dgnimprecomputedimensionsafterimport-getvar-default"
  '((operator . "DGNIMPRECOMPUTEDIMENSIONSAFTERIMPORT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPRECOMPUTEDIMENSIONSAFTERIMPORT")
  0)

(deftest "sysvar-dgnimpsymbolresourcefiles-getvar-type"
  '((operator . "DGNIMPSYMBOLRESOURCEFILES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPSYMBOLRESOURCEFILES"))
  'str)

(deftest "sysvar-dgnimpxrefimportmode-getvar-type"
  '((operator . "DGNIMPXREFIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DGNIMPXREFIMPORTMODE"))
  'int)

(deftest "sysvar-dgnimpxrefimportmode-getvar-default"
  '((operator . "DGNIMPXREFIMPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DGNIMPXREFIMPORTMODE")
  2)

(deftest "sysvar-dgnmappingpath-getvar-type"
  '((operator . "DGNMAPPINGPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DGNMAPPINGPATH"))
  'str)

(deftest-error "sysvar-dgnmappingpath-setvar-readonly-signals"
  '((operator . "DGNMAPPINGPATH") (area . "sysvar") (profile . STRICT))
  '(setvar "DGNMAPPINGPATH" "")
  'sysvar-read-only)

(deftest "sysvar-dgnosnap-getvar-type"
  '((operator . "DGNOSNAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DGNOSNAP"))
  'int)

(deftest "sysvar-dgnosnap-getvar-default"
  '((operator . "DGNOSNAP") (area . "sysvar") (profile . STRICT))
  '(getvar "DGNOSNAP")
  1)

(deftest "sysvar-diastat-getvar-type"
  '((operator . "DIASTAT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIASTAT"))
  'int)

(deftest-error "sysvar-diastat-setvar-readonly-signals"
  '((operator . "DIASTAT") (area . "sysvar") (profile . STRICT))
  '(setvar "DIASTAT" 0)
  'sysvar-read-only)

(deftest "sysvar-dimadec-getvar-type"
  '((operator . "DIMADEC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMADEC"))
  'int)

(deftest "sysvar-dimalt-getvar-type"
  '((operator . "DIMALT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMALT"))
  'int)

(deftest "sysvar-dimalt-getvar-default"
  '((operator . "DIMALT") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMALT")
  0)

(deftest "sysvar-dimaltd-getvar-type"
  '((operator . "DIMALTD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMALTD"))
  'int)

(deftest "sysvar-dimaltf-getvar-type"
  '((operator . "DIMALTF") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMALTF"))
  'real)

(deftest "sysvar-dimaltrnd-getvar-type"
  '((operator . "DIMALTRND") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMALTRND"))
  'real)

(deftest "sysvar-dimalttd-getvar-type"
  '((operator . "DIMALTTD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMALTTD"))
  'int)

(deftest "sysvar-dimalttz-getvar-type"
  '((operator . "DIMALTTZ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMALTTZ"))
  'int)

(deftest "sysvar-dimalttz-getvar-default"
  '((operator . "DIMALTTZ") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMALTTZ")
  0)

(deftest "sysvar-dimaltu-getvar-type"
  '((operator . "DIMALTU") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMALTU"))
  'int)

(deftest "sysvar-dimaltz-getvar-type"
  '((operator . "DIMALTZ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMALTZ"))
  'int)

(deftest "sysvar-dimanno-getvar-type"
  '((operator . "DIMANNO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMANNO"))
  'int)

(deftest-error "sysvar-dimanno-setvar-readonly-signals"
  '((operator . "DIMANNO") (area . "sysvar") (profile . STRICT))
  '(setvar "DIMANNO" 0)
  'sysvar-read-only)

(deftest "sysvar-dimapost-getvar-type"
  '((operator . "DIMAPOST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMAPOST"))
  'str)

(deftest "sysvar-dimapost-getvar-default"
  '((operator . "DIMAPOST") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMAPOST")
  "")

(deftest "sysvar-dimarcsym-getvar-type"
  '((operator . "DIMARCSYM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMARCSYM"))
  'int)

(deftest "sysvar-dimaso-getvar-type"
  '((operator . "DIMASO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMASO"))
  'int)

(deftest "sysvar-dimaso-getvar-default"
  '((operator . "DIMASO") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMASO")
  1)

(deftest "sysvar-dimassoc-getvar-type"
  '((operator . "DIMASSOC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMASSOC"))
  'int)

(deftest "sysvar-dimasz-getvar-type"
  '((operator . "DIMASZ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMASZ"))
  'real)

(deftest "sysvar-dimatfit-getvar-type"
  '((operator . "DIMATFIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMATFIT"))
  'int)

(deftest "sysvar-dimaunit-getvar-type"
  '((operator . "DIMAUNIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMAUNIT"))
  'int)

(deftest "sysvar-dimazin-getvar-type"
  '((operator . "DIMAZIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMAZIN"))
  'int)

(deftest "sysvar-dimblk-getvar-type"
  '((operator . "DIMBLK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMBLK"))
  'str)

(deftest "sysvar-dimblk-getvar-default"
  '((operator . "DIMBLK") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMBLK")
  "")

(deftest "sysvar-dimblk1-getvar-type"
  '((operator . "DIMBLK1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMBLK1"))
  'str)

(deftest "sysvar-dimblk1-getvar-default"
  '((operator . "DIMBLK1") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMBLK1")
  "")

(deftest "sysvar-dimblk2-getvar-type"
  '((operator . "DIMBLK2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMBLK2"))
  'str)

(deftest "sysvar-dimblk2-getvar-default"
  '((operator . "DIMBLK2") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMBLK2")
  "")

(deftest "sysvar-dimcen-getvar-type"
  '((operator . "DIMCEN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMCEN"))
  'real)

(deftest "sysvar-dimclrd-getvar-type"
  '((operator . "DIMCLRD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMCLRD"))
  'int)

(deftest "sysvar-dimclre-getvar-type"
  '((operator . "DIMCLRE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMCLRE"))
  'int)

(deftest "sysvar-dimclrt-getvar-type"
  '((operator . "DIMCLRT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMCLRT"))
  'int)

(deftest "sysvar-dimconstrainticon-getvar-type"
  '((operator . "DIMCONSTRAINTICON") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMCONSTRAINTICON"))
  'int)

(deftest "sysvar-dimconstrainticon-getvar-default"
  '((operator . "DIMCONSTRAINTICON") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMCONSTRAINTICON")
  3)

(deftest "sysvar-dimcontinuemode-getvar-type"
  '((operator . "DIMCONTINUEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMCONTINUEMODE"))
  'int)

(deftest "sysvar-dimdec-getvar-type"
  '((operator . "DIMDEC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMDEC"))
  'int)

(deftest "sysvar-dimdle-getvar-type"
  '((operator . "DIMDLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMDLE"))
  'real)

(deftest "sysvar-dimdli-getvar-type"
  '((operator . "DIMDLI") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMDLI"))
  'real)

(deftest "sysvar-dimdsep-getvar-type"
  '((operator . "DIMDSEP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMDSEP"))
  'str)

(deftest "sysvar-dimexe-getvar-type"
  '((operator . "DIMEXE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMEXE"))
  'real)

(deftest "sysvar-dimexo-getvar-type"
  '((operator . "DIMEXO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMEXO"))
  'real)

(deftest "sysvar-dimfit-getvar-type"
  '((operator . "DIMFIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMFIT"))
  'int)

(deftest "sysvar-dimfit-getvar-default"
  '((operator . "DIMFIT") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMFIT")
  3)

(deftest "sysvar-dimfrac-getvar-type"
  '((operator . "DIMFRAC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMFRAC"))
  'int)

(deftest "sysvar-dimfxl-getvar-type"
  '((operator . "DIMFXL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMFXL"))
  'real)

(deftest "sysvar-dimfxlon-getvar-type"
  '((operator . "DIMFXLON") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMFXLON"))
  'int)

(deftest "sysvar-dimfxlon-getvar-default"
  '((operator . "DIMFXLON") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMFXLON")
  0)

(deftest "sysvar-dimgap-getvar-type"
  '((operator . "DIMGAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMGAP"))
  'real)

(deftest "sysvar-dimjogang-getvar-type"
  '((operator . "DIMJOGANG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMJOGANG"))
  'real)

(deftest "sysvar-dimjust-getvar-type"
  '((operator . "DIMJUST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMJUST"))
  'int)

(deftest "sysvar-dimlayer-getvar-type"
  '((operator . "DIMLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMLAYER"))
  'str)

(deftest "sysvar-dimldrblk-getvar-type"
  '((operator . "DIMLDRBLK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMLDRBLK"))
  'str)

(deftest "sysvar-dimldrblk-getvar-default"
  '((operator . "DIMLDRBLK") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMLDRBLK")
  "")

(deftest "sysvar-dimlfac-getvar-type"
  '((operator . "DIMLFAC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMLFAC"))
  'real)

(deftest "sysvar-dimlim-getvar-type"
  '((operator . "DIMLIM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMLIM"))
  'int)

(deftest "sysvar-dimlim-getvar-default"
  '((operator . "DIMLIM") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMLIM")
  0)

(deftest "sysvar-dimltex1-getvar-type"
  '((operator . "DIMLTEX1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMLTEX1"))
  'str)

(deftest "sysvar-dimltex1-getvar-default"
  '((operator . "DIMLTEX1") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMLTEX1")
  "")

(deftest "sysvar-dimltex2-getvar-type"
  '((operator . "DIMLTEX2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMLTEX2"))
  'str)

(deftest "sysvar-dimltex2-getvar-default"
  '((operator . "DIMLTEX2") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMLTEX2")
  "")

(deftest "sysvar-dimltype-getvar-type"
  '((operator . "DIMLTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMLTYPE"))
  'str)

(deftest "sysvar-dimltype-getvar-default"
  '((operator . "DIMLTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMLTYPE")
  "")

(deftest "sysvar-dimlunit-getvar-type"
  '((operator . "DIMLUNIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMLUNIT"))
  'int)

(deftest "sysvar-dimlwd-getvar-type"
  '((operator . "DIMLWD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMLWD"))
  'int)

(deftest "sysvar-dimlwe-getvar-type"
  '((operator . "DIMLWE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMLWE"))
  'int)

(deftest "sysvar-dimmarktype-getvar-type"
  '((operator . "DIMMARKTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DIMMARKTYPE"))
  'int)

(deftest "sysvar-dimmarktype-getvar-default"
  '((operator . "DIMMARKTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DIMMARKTYPE")
  0)

(deftest "sysvar-dimpickbox-getvar-type"
  '((operator . "DIMPICKBOX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMPICKBOX"))
  'int)

(deftest "sysvar-dimpickbox-getvar-default"
  '((operator . "DIMPICKBOX") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMPICKBOX")
  5)

(deftest "sysvar-dimpost-getvar-type"
  '((operator . "DIMPOST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMPOST"))
  'str)

(deftest "sysvar-dimpost-getvar-default"
  '((operator . "DIMPOST") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMPOST")
  "")

(deftest "sysvar-dimrnd-getvar-type"
  '((operator . "DIMRND") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMRND"))
  'real)

(deftest "sysvar-dimsah-getvar-type"
  '((operator . "DIMSAH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMSAH"))
  'int)

(deftest "sysvar-dimsah-getvar-default"
  '((operator . "DIMSAH") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMSAH")
  0)

(deftest "sysvar-dimscale-getvar-type"
  '((operator . "DIMSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMSCALE"))
  'real)

(deftest "sysvar-dimsd1-getvar-type"
  '((operator . "DIMSD1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMSD1"))
  'int)

(deftest "sysvar-dimsd1-getvar-default"
  '((operator . "DIMSD1") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMSD1")
  0)

(deftest "sysvar-dimsd2-getvar-type"
  '((operator . "DIMSD2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMSD2"))
  'int)

(deftest "sysvar-dimsd2-getvar-default"
  '((operator . "DIMSD2") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMSD2")
  0)

(deftest "sysvar-dimse1-getvar-type"
  '((operator . "DIMSE1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMSE1"))
  'int)

(deftest "sysvar-dimse1-getvar-default"
  '((operator . "DIMSE1") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMSE1")
  0)

(deftest "sysvar-dimse2-getvar-type"
  '((operator . "DIMSE2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMSE2"))
  'int)

(deftest "sysvar-dimse2-getvar-default"
  '((operator . "DIMSE2") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMSE2")
  0)

(deftest "sysvar-dimsho-getvar-type"
  '((operator . "DIMSHO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMSHO"))
  'int)

(deftest "sysvar-dimsho-getvar-default"
  '((operator . "DIMSHO") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMSHO")
  1)

(deftest "sysvar-dimsoxd-getvar-type"
  '((operator . "DIMSOXD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMSOXD"))
  'int)

(deftest "sysvar-dimsoxd-getvar-default"
  '((operator . "DIMSOXD") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMSOXD")
  0)

(deftest "sysvar-dimstyle-getvar-type"
  '((operator . "DIMSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMSTYLE"))
  'str)

(deftest-error "sysvar-dimstyle-setvar-readonly-signals"
  '((operator . "DIMSTYLE") (area . "sysvar") (profile . STRICT))
  '(setvar "DIMSTYLE" "")
  'sysvar-read-only)

(deftest "sysvar-dimtad-getvar-type"
  '((operator . "DIMTAD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTAD"))
  'int)

(deftest "sysvar-dimtdec-getvar-type"
  '((operator . "DIMTDEC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTDEC"))
  'int)

(deftest "sysvar-dimtfac-getvar-type"
  '((operator . "DIMTFAC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTFAC"))
  'real)

(deftest "sysvar-dimtfill-getvar-type"
  '((operator . "DIMTFILL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTFILL"))
  'int)

(deftest "sysvar-dimtfillclr-getvar-type"
  '((operator . "DIMTFILLCLR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTFILLCLR"))
  'int)

(deftest "sysvar-dimtih-getvar-type"
  '((operator . "DIMTIH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTIH"))
  'int)

(deftest "sysvar-dimtix-getvar-type"
  '((operator . "DIMTIX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTIX"))
  'int)

(deftest "sysvar-dimtix-getvar-default"
  '((operator . "DIMTIX") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMTIX")
  0)

(deftest "sysvar-dimtm-getvar-type"
  '((operator . "DIMTM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTM"))
  'real)

(deftest "sysvar-dimtmove-getvar-type"
  '((operator . "DIMTMOVE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTMOVE"))
  'int)

(deftest "sysvar-dimtofl-getvar-type"
  '((operator . "DIMTOFL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTOFL"))
  'int)

(deftest "sysvar-dimtoh-getvar-type"
  '((operator . "DIMTOH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTOH"))
  'int)

(deftest "sysvar-dimtol-getvar-type"
  '((operator . "DIMTOL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTOL"))
  'int)

(deftest "sysvar-dimtol-getvar-default"
  '((operator . "DIMTOL") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMTOL")
  0)

(deftest "sysvar-dimtolj-getvar-type"
  '((operator . "DIMTOLJ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTOLJ"))
  'int)

(deftest "sysvar-dimtp-getvar-type"
  '((operator . "DIMTP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTP"))
  'real)

(deftest "sysvar-dimtsz-getvar-type"
  '((operator . "DIMTSZ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTSZ"))
  'real)

(deftest "sysvar-dimtvp-getvar-type"
  '((operator . "DIMTVP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTVP"))
  'real)

(deftest "sysvar-dimtxsty-getvar-type"
  '((operator . "DIMTXSTY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTXSTY"))
  'str)

(deftest "sysvar-dimtxsty-getvar-default"
  '((operator . "DIMTXSTY") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMTXSTY")
  "Standard")

(deftest "sysvar-dimtxt-getvar-type"
  '((operator . "DIMTXT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTXT"))
  'real)

(deftest "sysvar-dimtxtdirection-getvar-type"
  '((operator . "DIMTXTDIRECTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTXTDIRECTION"))
  'int)

(deftest "sysvar-dimtxtdirection-getvar-default"
  '((operator . "DIMTXTDIRECTION") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMTXTDIRECTION")
  0)

(deftest "sysvar-dimtxtruler-getvar-type"
  '((operator . "DIMTXTRULER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTXTRULER"))
  'int)

(deftest "sysvar-dimtxtruler-getvar-default"
  '((operator . "DIMTXTRULER") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMTXTRULER")
  1)

(deftest "sysvar-dimtzin-getvar-type"
  '((operator . "DIMTZIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMTZIN"))
  'int)

(deftest "sysvar-dimunit-getvar-type"
  '((operator . "DIMUNIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMUNIT"))
  'int)

(deftest "sysvar-dimunit-getvar-default"
  '((operator . "DIMUNIT") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMUNIT")
  2)

(deftest "sysvar-dimupt-getvar-type"
  '((operator . "DIMUPT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMUPT"))
  'int)

(deftest "sysvar-dimupt-getvar-default"
  '((operator . "DIMUPT") (area . "sysvar") (profile . STRICT))
  '(getvar "DIMUPT")
  0)

(deftest "sysvar-dimzin-getvar-type"
  '((operator . "DIMZIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIMZIN"))
  'int)

(deftest "sysvar-displayaxes-getvar-type"
  '((operator . "DISPLAYAXES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DISPLAYAXES"))
  'int)

(deftest "sysvar-displayaxes-getvar-default"
  '((operator . "DISPLAYAXES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DISPLAYAXES")
  0)

(deftest "sysvar-displayaxesformep-getvar-type"
  '((operator . "DISPLAYAXESFORMEP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DISPLAYAXESFORMEP"))
  'int)

(deftest "sysvar-displayaxesformep-getvar-default"
  '((operator . "DISPLAYAXESFORMEP") (area . "sysvar") (profile . STRICT))
  '(getvar "DISPLAYAXESFORMEP")
  0)

(deftest "sysvar-displayscaling-getvar-type"
  '((operator . "DISPLAYSCALING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DISPLAYSCALING"))
  'int)

(deftest-error "sysvar-displayscaling-setvar-readonly-signals"
  '((operator . "DISPLAYSCALING") (area . "sysvar") (profile . BRICSCAD))
  '(setvar "DISPLAYSCALING" 0)
  'sysvar-read-only)

(deftest "sysvar-displaysidesandends-getvar-type"
  '((operator . "DISPLAYSIDESANDENDS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DISPLAYSIDESANDENDS"))
  'int)

(deftest "sysvar-displaysidesandends-getvar-default"
  '((operator . "DISPLAYSIDESANDENDS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DISPLAYSIDESANDENDS")
  0)

(deftest "sysvar-displaysnapmarkerinallviews-getvar-type"
  '((operator . "DISPLAYSNAPMARKERINALLVIEWS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DISPLAYSNAPMARKERINALLVIEWS"))
  'int)

(deftest "sysvar-displaysnapmarkerinallviews-getvar-default"
  '((operator . "DISPLAYSNAPMARKERINALLVIEWS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DISPLAYSNAPMARKERINALLVIEWS")
  0)

(deftest "sysvar-displaytooltips-getvar-type"
  '((operator . "DISPLAYTOOLTIPS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DISPLAYTOOLTIPS"))
  'int)

(deftest "sysvar-displaytooltips-getvar-default"
  '((operator . "DISPLAYTOOLTIPS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DISPLAYTOOLTIPS")
  1)

(deftest "sysvar-displaytruedimension-getvar-type"
  '((operator . "DISPLAYTRUEDIMENSION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DISPLAYTRUEDIMENSION"))
  'int)

(deftest "sysvar-displaytruedimension-getvar-default"
  '((operator . "DISPLAYTRUEDIMENSION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DISPLAYTRUEDIMENSION")
  1)

(deftest "sysvar-disppaperbkg-getvar-type"
  '((operator . "DISPPAPERBKG") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DISPPAPERBKG"))
  'int)

(deftest "sysvar-disppaperbkg-getvar-default"
  '((operator . "DISPPAPERBKG") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DISPPAPERBKG")
  1)

(deftest "sysvar-disppapermargins-getvar-type"
  '((operator . "DISPPAPERMARGINS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DISPPAPERMARGINS"))
  'int)

(deftest "sysvar-disppapermargins-getvar-default"
  '((operator . "DISPPAPERMARGINS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DISPPAPERMARGINS")
  1)

(deftest "sysvar-dispsilh-getvar-type"
  '((operator . "DISPSILH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DISPSILH"))
  'int)

(deftest "sysvar-dispsilh-getvar-default"
  '((operator . "DISPSILH") (area . "sysvar") (profile . STRICT))
  '(getvar "DISPSILH")
  0)

(deftest "sysvar-dispsilhblocks-getvar-type"
  '((operator . "DISPSILHBLOCKS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DISPSILHBLOCKS"))
  'int)

(deftest "sysvar-dispsilhblocks-getvar-default"
  '((operator . "DISPSILHBLOCKS") (area . "sysvar") (profile . STRICT))
  '(getvar "DISPSILHBLOCKS")
  1)

(deftest "sysvar-distance-getvar-type"
  '((operator . "DISTANCE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DISTANCE"))
  'real)

(deftest-error "sysvar-distance-setvar-readonly-signals"
  '((operator . "DISTANCE") (area . "sysvar") (profile . STRICT))
  '(setvar "DISTANCE" 0.0)
  'sysvar-read-only)

(deftest "sysvar-divmeshboxheight-getvar-type"
  '((operator . "DIVMESHBOXHEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHBOXHEIGHT"))
  'int)

(deftest "sysvar-divmeshboxheight-getvar-default"
  '((operator . "DIVMESHBOXHEIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHBOXHEIGHT")
  3)

(deftest "sysvar-divmeshboxlength-getvar-type"
  '((operator . "DIVMESHBOXLENGTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHBOXLENGTH"))
  'int)

(deftest "sysvar-divmeshboxlength-getvar-default"
  '((operator . "DIVMESHBOXLENGTH") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHBOXLENGTH")
  3)

(deftest "sysvar-divmeshboxwidth-getvar-type"
  '((operator . "DIVMESHBOXWIDTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHBOXWIDTH"))
  'int)

(deftest "sysvar-divmeshboxwidth-getvar-default"
  '((operator . "DIVMESHBOXWIDTH") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHBOXWIDTH")
  3)

(deftest "sysvar-divmeshconeaxis-getvar-type"
  '((operator . "DIVMESHCONEAXIS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHCONEAXIS"))
  'int)

(deftest "sysvar-divmeshconeaxis-getvar-default"
  '((operator . "DIVMESHCONEAXIS") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHCONEAXIS")
  8)

(deftest "sysvar-divmeshconebase-getvar-type"
  '((operator . "DIVMESHCONEBASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHCONEBASE"))
  'int)

(deftest "sysvar-divmeshconebase-getvar-default"
  '((operator . "DIVMESHCONEBASE") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHCONEBASE")
  3)

(deftest "sysvar-divmeshconeheight-getvar-type"
  '((operator . "DIVMESHCONEHEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHCONEHEIGHT"))
  'int)

(deftest "sysvar-divmeshconeheight-getvar-default"
  '((operator . "DIVMESHCONEHEIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHCONEHEIGHT")
  3)

(deftest "sysvar-divmeshcylaxis-getvar-type"
  '((operator . "DIVMESHCYLAXIS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHCYLAXIS"))
  'int)

(deftest "sysvar-divmeshcylaxis-getvar-default"
  '((operator . "DIVMESHCYLAXIS") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHCYLAXIS")
  8)

(deftest "sysvar-divmeshcylbase-getvar-type"
  '((operator . "DIVMESHCYLBASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHCYLBASE"))
  'int)

(deftest "sysvar-divmeshcylbase-getvar-default"
  '((operator . "DIVMESHCYLBASE") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHCYLBASE")
  3)

(deftest "sysvar-divmeshcylheight-getvar-type"
  '((operator . "DIVMESHCYLHEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHCYLHEIGHT"))
  'int)

(deftest "sysvar-divmeshcylheight-getvar-default"
  '((operator . "DIVMESHCYLHEIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHCYLHEIGHT")
  3)

(deftest "sysvar-divmeshpyrbase-getvar-type"
  '((operator . "DIVMESHPYRBASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHPYRBASE"))
  'int)

(deftest "sysvar-divmeshpyrbase-getvar-default"
  '((operator . "DIVMESHPYRBASE") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHPYRBASE")
  3)

(deftest "sysvar-divmeshpyrheight-getvar-type"
  '((operator . "DIVMESHPYRHEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHPYRHEIGHT"))
  'int)

(deftest "sysvar-divmeshpyrheight-getvar-default"
  '((operator . "DIVMESHPYRHEIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHPYRHEIGHT")
  3)

(deftest "sysvar-divmeshpyrlength-getvar-type"
  '((operator . "DIVMESHPYRLENGTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHPYRLENGTH"))
  'int)

(deftest "sysvar-divmeshpyrlength-getvar-default"
  '((operator . "DIVMESHPYRLENGTH") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHPYRLENGTH")
  3)

(deftest "sysvar-divmeshsphereaxis-getvar-type"
  '((operator . "DIVMESHSPHEREAXIS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHSPHEREAXIS"))
  'int)

(deftest "sysvar-divmeshsphereaxis-getvar-default"
  '((operator . "DIVMESHSPHEREAXIS") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHSPHEREAXIS")
  12)

(deftest "sysvar-divmeshsphereheight-getvar-type"
  '((operator . "DIVMESHSPHEREHEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHSPHEREHEIGHT"))
  'int)

(deftest "sysvar-divmeshsphereheight-getvar-default"
  '((operator . "DIVMESHSPHEREHEIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHSPHEREHEIGHT")
  6)

(deftest "sysvar-divmeshtoruspath-getvar-type"
  '((operator . "DIVMESHTORUSPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHTORUSPATH"))
  'int)

(deftest "sysvar-divmeshtoruspath-getvar-default"
  '((operator . "DIVMESHTORUSPATH") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHTORUSPATH")
  8)

(deftest "sysvar-divmeshtorussection-getvar-type"
  '((operator . "DIVMESHTORUSSECTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHTORUSSECTION"))
  'int)

(deftest "sysvar-divmeshtorussection-getvar-default"
  '((operator . "DIVMESHTORUSSECTION") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHTORUSSECTION")
  8)

(deftest "sysvar-divmeshwedgebase-getvar-type"
  '((operator . "DIVMESHWEDGEBASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHWEDGEBASE"))
  'int)

(deftest "sysvar-divmeshwedgebase-getvar-default"
  '((operator . "DIVMESHWEDGEBASE") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHWEDGEBASE")
  3)

(deftest "sysvar-divmeshwedgeheight-getvar-type"
  '((operator . "DIVMESHWEDGEHEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHWEDGEHEIGHT"))
  'int)

(deftest "sysvar-divmeshwedgeheight-getvar-default"
  '((operator . "DIVMESHWEDGEHEIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHWEDGEHEIGHT")
  3)

(deftest "sysvar-divmeshwedgelength-getvar-type"
  '((operator . "DIVMESHWEDGELENGTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHWEDGELENGTH"))
  'int)

(deftest "sysvar-divmeshwedgelength-getvar-default"
  '((operator . "DIVMESHWEDGELENGTH") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHWEDGELENGTH")
  4)

(deftest "sysvar-divmeshwedgeslope-getvar-type"
  '((operator . "DIVMESHWEDGESLOPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHWEDGESLOPE"))
  'int)

(deftest "sysvar-divmeshwedgeslope-getvar-default"
  '((operator . "DIVMESHWEDGESLOPE") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHWEDGESLOPE")
  3)

(deftest "sysvar-divmeshwedgewidth-getvar-type"
  '((operator . "DIVMESHWEDGEWIDTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DIVMESHWEDGEWIDTH"))
  'int)

(deftest "sysvar-divmeshwedgewidth-getvar-default"
  '((operator . "DIVMESHWEDGEWIDTH") (area . "sysvar") (profile . STRICT))
  '(getvar "DIVMESHWEDGEWIDTH")
  3)

(deftest "sysvar-dmauditlevel-getvar-type"
  '((operator . "DMAUDITLEVEL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DMAUDITLEVEL"))
  'int)

(deftest "sysvar-dmauditlevel-getvar-default"
  '((operator . "DMAUDITLEVEL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DMAUDITLEVEL")
  1)

(deftest "sysvar-dmautoupdate-getvar-type"
  '((operator . "DMAUTOUPDATE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DMAUTOUPDATE"))
  'int)

(deftest "sysvar-dmautoupdate-getvar-default"
  '((operator . "DMAUTOUPDATE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DMAUTOUPDATE")
  1)

(deftest "sysvar-dmconnectioncuttype-getvar-type"
  '((operator . "DMCONNECTIONCUTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DMCONNECTIONCUTTYPE"))
  'int)

(deftest "sysvar-dmconnectioncuttype-getvar-default"
  '((operator . "DMCONNECTIONCUTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DMCONNECTIONCUTTYPE")
  0)

(deftest "sysvar-dmpushpullsubtract-getvar-type"
  '((operator . "DMPUSHPULLSUBTRACT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DMPUSHPULLSUBTRACT"))
  'int)

(deftest "sysvar-dmpushpullsubtract-getvar-default"
  '((operator . "DMPUSHPULLSUBTRACT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DMPUSHPULLSUBTRACT")
  0)

(deftest "sysvar-dmrecognize-getvar-type"
  '((operator . "DMRECOGNIZE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DMRECOGNIZE"))
  'int)

(deftest "sysvar-dmrecognize-getvar-default"
  '((operator . "DMRECOGNIZE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DMRECOGNIZE")
  0)

(deftest "sysvar-dockpriority-getvar-type"
  '((operator . "DOCKPRIORITY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DOCKPRIORITY"))
  'int)

(deftest "sysvar-dockpriority-getvar-default"
  '((operator . "DOCKPRIORITY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DOCKPRIORITY")
  1)

(deftest "sysvar-doctabposition-getvar-type"
  '((operator . "DOCTABPOSITION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DOCTABPOSITION"))
  'int)

(deftest "sysvar-doctabposition-getvar-default"
  '((operator . "DOCTABPOSITION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DOCTABPOSITION")
  0)

(deftest "sysvar-donutid-getvar-type"
  '((operator . "DONUTID") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DONUTID"))
  'real)

(deftest "sysvar-donutod-getvar-type"
  '((operator . "DONUTOD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DONUTOD"))
  'real)

(deftest "sysvar-dragmode-getvar-type"
  '((operator . "DRAGMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DRAGMODE"))
  'int)

(deftest "sysvar-dragmodeconstraints-getvar-type"
  '((operator . "DRAGMODECONSTRAINTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAGMODECONSTRAINTS"))
  'int)

(deftest "sysvar-dragmodeconstraints-getvar-default"
  '((operator . "DRAGMODECONSTRAINTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAGMODECONSTRAINTS")
  1)

(deftest "sysvar-dragmodefaces-getvar-type"
  '((operator . "DRAGMODEFACES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAGMODEFACES"))
  'int)

(deftest "sysvar-dragmodefaces-getvar-default"
  '((operator . "DRAGMODEFACES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAGMODEFACES")
  1)

(deftest "sysvar-dragmodehide-getvar-type"
  '((operator . "DRAGMODEHIDE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAGMODEHIDE"))
  'int)

(deftest "sysvar-dragmodehide-getvar-default"
  '((operator . "DRAGMODEHIDE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAGMODEHIDE")
  0)

(deftest "sysvar-dragmodeinterrupt-getvar-type"
  '((operator . "DRAGMODEINTERRUPT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAGMODEINTERRUPT"))
  'int)

(deftest "sysvar-dragmodeinterrupt-getvar-default"
  '((operator . "DRAGMODEINTERRUPT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAGMODEINTERRUPT")
  1)

(deftest "sysvar-dragopen-getvar-type"
  '((operator . "DRAGOPEN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAGOPEN"))
  'int)

(deftest "sysvar-dragopen-getvar-default"
  '((operator . "DRAGOPEN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAGOPEN")
  1)

(deftest "sysvar-dragp1-getvar-type"
  '((operator . "DRAGP1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DRAGP1"))
  'int)

(deftest "sysvar-dragp2-getvar-type"
  '((operator . "DRAGP2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DRAGP2"))
  'int)

(deftest "sysvar-dragsnap-getvar-type"
  '((operator . "DRAGSNAP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAGSNAP"))
  'int)

(deftest "sysvar-dragsnap-getvar-default"
  '((operator . "DRAGSNAP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAGSNAP")
  1)

(deftest "sysvar-dragvs-getvar-type"
  '((operator . "DRAGVS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DRAGVS"))
  'str)

(deftest "sysvar-dragvs-getvar-default"
  '((operator . "DRAGVS") (area . "sysvar") (profile . STRICT))
  '(getvar "DRAGVS")
  "")

(deftest "sysvar-drawingpath-getvar-type"
  '((operator . "DRAWINGPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAWINGPATH"))
  'str)

(deftest "sysvar-drawingviewasm-getvar-type"
  '((operator . "DRAWINGVIEWASM") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAWINGVIEWASM"))
  'int)

(deftest "sysvar-drawingviewasm-getvar-default"
  '((operator . "DRAWINGVIEWASM") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAWINGVIEWASM")
  0)

(deftest "sysvar-drawingviewents-getvar-type"
  '((operator . "DRAWINGVIEWENTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAWINGVIEWENTS"))
  'int)

(deftest "sysvar-drawingviewents-getvar-default"
  '((operator . "DRAWINGVIEWENTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAWINGVIEWENTS")
  0)

(deftest "sysvar-drawingviewflags-getvar-type"
  '((operator . "DRAWINGVIEWFLAGS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAWINGVIEWFLAGS"))
  'int)

(deftest "sysvar-drawingviewflags-getvar-default"
  '((operator . "DRAWINGVIEWFLAGS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAWINGVIEWFLAGS")
  0)

(deftest "sysvar-drawingviewpreset-getvar-type"
  '((operator . "DRAWINGVIEWPRESET") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAWINGVIEWPRESET"))
  'str)

(deftest "sysvar-drawingviewpreset-getvar-default"
  '((operator . "DRAWINGVIEWPRESET") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAWINGVIEWPRESET")
  "")

(deftest "sysvar-drawingviewpresethidden-getvar-type"
  '((operator . "DRAWINGVIEWPRESETHIDDEN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAWINGVIEWPRESETHIDDEN"))
  'int)

(deftest "sysvar-drawingviewpresethidden-getvar-default"
  '((operator . "DRAWINGVIEWPRESETHIDDEN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAWINGVIEWPRESETHIDDEN")
  0)

(deftest "sysvar-drawingviewpresetscale-getvar-type"
  '((operator . "DRAWINGVIEWPRESETSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAWINGVIEWPRESETSCALE"))
  'str)

(deftest "sysvar-drawingviewpresettangent-getvar-type"
  '((operator . "DRAWINGVIEWPRESETTANGENT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAWINGVIEWPRESETTANGENT"))
  'int)

(deftest "sysvar-drawingviewpresettangent-getvar-default"
  '((operator . "DRAWINGVIEWPRESETTANGENT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAWINGVIEWPRESETTANGENT")
  0)

(deftest "sysvar-drawingviewpresettrailing-getvar-type"
  '((operator . "DRAWINGVIEWPRESETTRAILING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DRAWINGVIEWPRESETTRAILING"))
  'int)

(deftest "sysvar-drawingviewpresettrailing-getvar-default"
  '((operator . "DRAWINGVIEWPRESETTRAILING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DRAWINGVIEWPRESETTRAILING")
  1)

(deftest "sysvar-drawingviewquality-getvar-type"
  '((operator . "DRAWINGVIEWQUALITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DRAWINGVIEWQUALITY"))
  'int)

(deftest "sysvar-drawingviewquality-getvar-default"
  '((operator . "DRAWINGVIEWQUALITY") (area . "sysvar") (profile . STRICT))
  '(getvar "DRAWINGVIEWQUALITY")
  1)

(deftest "sysvar-draworderctl-getvar-type"
  '((operator . "DRAWORDERCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DRAWORDERCTL"))
  'int)

(deftest "sysvar-drstate-getvar-type"
  '((operator . "DRSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DRSTATE"))
  'int)

(deftest-error "sysvar-drstate-setvar-readonly-signals"
  '((operator . "DRSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "DRSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-dwfformat-getvar-type"
  '((operator . "DWFFORMAT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DWFFORMAT"))
  'int)

(deftest "sysvar-dwfformat-getvar-default"
  '((operator . "DWFFORMAT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DWFFORMAT")
  1)

(deftest "sysvar-dwfframe-getvar-type"
  '((operator . "DWFFRAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DWFFRAME"))
  'int)

(deftest "sysvar-dwfosnap-getvar-type"
  '((operator . "DWFOSNAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DWFOSNAP"))
  'int)

(deftest "sysvar-dwfosnap-getvar-default"
  '((operator . "DWFOSNAP") (area . "sysvar") (profile . STRICT))
  '(getvar "DWFOSNAP")
  1)

(deftest "sysvar-dwfversion-getvar-type"
  '((operator . "DWFVERSION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DWFVERSION"))
  'int)

(deftest "sysvar-dwfversion-getvar-default"
  '((operator . "DWFVERSION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DWFVERSION")
  2)

(deftest "sysvar-dwgcheck-getvar-type"
  '((operator . "DWGCHECK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DWGCHECK"))
  'int)

(deftest "sysvar-dwgcodepage-getvar-type"
  '((operator . "DWGCODEPAGE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DWGCODEPAGE"))
  'str)

(deftest-error "sysvar-dwgcodepage-setvar-readonly-signals"
  '((operator . "DWGCODEPAGE") (area . "sysvar") (profile . STRICT))
  '(setvar "DWGCODEPAGE" "")
  'sysvar-read-only)

(deftest "sysvar-dwgguidcloudai-getvar-type"
  '((operator . "DWGGUIDCLOUDAI") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DWGGUIDCLOUDAI"))
  'str)

(deftest "sysvar-dwgguidcloudai-getvar-default"
  '((operator . "DWGGUIDCLOUDAI") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DWGGUIDCLOUDAI")
  "\" \"")

(deftest "sysvar-dwgname-getvar-type"
  '((operator . "DWGNAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DWGNAME"))
  'str)

(deftest-error "sysvar-dwgname-setvar-readonly-signals"
  '((operator . "DWGNAME") (area . "sysvar") (profile . STRICT))
  '(setvar "DWGNAME" "")
  'sysvar-read-only)

(deftest "sysvar-dwgprefix-getvar-type"
  '((operator . "DWGPREFIX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DWGPREFIX"))
  'str)

(deftest-error "sysvar-dwgprefix-setvar-readonly-signals"
  '((operator . "DWGPREFIX") (area . "sysvar") (profile . STRICT))
  '(setvar "DWGPREFIX" "")
  'sysvar-read-only)

(deftest "sysvar-dwgtitled-getvar-type"
  '((operator . "DWGTITLED") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DWGTITLED"))
  'int)

(deftest-error "sysvar-dwgtitled-setvar-readonly-signals"
  '((operator . "DWGTITLED") (area . "sysvar") (profile . STRICT))
  '(setvar "DWGTITLED" 0)
  'sysvar-read-only)

(deftest "sysvar-dx12framerateunlimited-getvar-type"
  '((operator . "DX12FRAMERATEUNLIMITED") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DX12FRAMERATEUNLIMITED"))
  'int)

(deftest "sysvar-dx12framerateunlimited-getvar-default"
  '((operator . "DX12FRAMERATEUNLIMITED") (area . "sysvar") (profile . STRICT))
  '(getvar "DX12FRAMERATEUNLIMITED")
  0)

(deftest "sysvar-dxeval-getvar-type"
  '((operator . "DXEVAL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DXEVAL"))
  'int)

(deftest "sysvar-dxftextadjustalignment-getvar-type"
  '((operator . "DXFTEXTADJUSTALIGNMENT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DXFTEXTADJUSTALIGNMENT"))
  'int)

(deftest "sysvar-dxftextadjustalignment-getvar-default"
  '((operator . "DXFTEXTADJUSTALIGNMENT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DXFTEXTADJUSTALIGNMENT")
  1)

(deftest "sysvar-dynconstraintmode-getvar-type"
  '((operator . "DYNCONSTRAINTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DYNCONSTRAINTMODE"))
  'int)

(deftest "sysvar-dynconstraintmode-getvar-default"
  '((operator . "DYNCONSTRAINTMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "DYNCONSTRAINTMODE")
  1)

(deftest "sysvar-dyndigrip-getvar-type"
  '((operator . "DYNDIGRIP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DYNDIGRIP"))
  'int)

(deftest "sysvar-dyndimaperture-getvar-type"
  '((operator . "DYNDIMAPERTURE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DYNDIMAPERTURE"))
  'int)

(deftest "sysvar-dyndimaperture-getvar-default"
  '((operator . "DYNDIMAPERTURE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DYNDIMAPERTURE")
  20)

(deftest "sysvar-dyndimcolorhot-getvar-type"
  '((operator . "DYNDIMCOLORHOT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DYNDIMCOLORHOT"))
  'int)

(deftest "sysvar-dyndimcolorhot-getvar-default"
  '((operator . "DYNDIMCOLORHOT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DYNDIMCOLORHOT")
  142)

(deftest "sysvar-dyndimcolorhover-getvar-type"
  '((operator . "DYNDIMCOLORHOVER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DYNDIMCOLORHOVER"))
  'int)

(deftest "sysvar-dyndimcolorhover-getvar-default"
  '((operator . "DYNDIMCOLORHOVER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DYNDIMCOLORHOVER")
  142)

(deftest "sysvar-dyndimdistance-getvar-type"
  '((operator . "DYNDIMDISTANCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DYNDIMDISTANCE"))
  'real)

(deftest "sysvar-dyndimdistance-getvar-default"
  '((operator . "DYNDIMDISTANCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DYNDIMDISTANCE")
  1.0)

(deftest "sysvar-dyndimlinetype-getvar-type"
  '((operator . "DYNDIMLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DYNDIMLINETYPE"))
  'int)

(deftest "sysvar-dyndimlinetype-getvar-default"
  '((operator . "DYNDIMLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DYNDIMLINETYPE")
  0)

(deftest "sysvar-dyndivis-getvar-type"
  '((operator . "DYNDIVIS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DYNDIVIS"))
  'int)

(deftest "sysvar-dyninfotips-getvar-type"
  '((operator . "DYNINFOTIPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DYNINFOTIPS"))
  'int)

(deftest "sysvar-dyninfotips-getvar-default"
  '((operator . "DYNINFOTIPS") (area . "sysvar") (profile . STRICT))
  '(getvar "DYNINFOTIPS")
  1)

(deftest "sysvar-dyninputtransparency-getvar-type"
  '((operator . "DYNINPUTTRANSPARENCY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "DYNINPUTTRANSPARENCY"))
  'int)

(deftest "sysvar-dyninputtransparency-getvar-default"
  '((operator . "DYNINPUTTRANSPARENCY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "DYNINPUTTRANSPARENCY")
  90)

(deftest "sysvar-dynmode-getvar-type"
  '((operator . "DYNMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DYNMODE"))
  'int)

(deftest "sysvar-dynpicoords-getvar-type"
  '((operator . "DYNPICOORDS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DYNPICOORDS"))
  'int)

(deftest "sysvar-dynpiformat-getvar-type"
  '((operator . "DYNPIFORMAT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DYNPIFORMAT"))
  'int)

(deftest "sysvar-dynpiformat-getvar-default"
  '((operator . "DYNPIFORMAT") (area . "sysvar") (profile . STRICT))
  '(getvar "DYNPIFORMAT")
  0)

(deftest "sysvar-dynpivis-getvar-type"
  '((operator . "DYNPIVIS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DYNPIVIS"))
  'int)

(deftest "sysvar-dynpivis-getvar-default"
  '((operator . "DYNPIVIS") (area . "sysvar") (profile . STRICT))
  '(getvar "DYNPIVIS")
  1)

(deftest "sysvar-dynprompt-getvar-type"
  '((operator . "DYNPROMPT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DYNPROMPT"))
  'int)

(deftest "sysvar-dynprompt-getvar-default"
  '((operator . "DYNPROMPT") (area . "sysvar") (profile . STRICT))
  '(getvar "DYNPROMPT")
  1)

(deftest "sysvar-dyntooltips-getvar-type"
  '((operator . "DYNTOOLTIPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "DYNTOOLTIPS"))
  'int)

(deftest "sysvar-dyntooltips-getvar-default"
  '((operator . "DYNTOOLTIPS") (area . "sysvar") (profile . STRICT))
  '(getvar "DYNTOOLTIPS")
  1)

(deftest "sysvar-edgemode-getvar-type"
  '((operator . "EDGEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EDGEMODE"))
  'int)

(deftest "sysvar-edgemode-getvar-default"
  '((operator . "EDGEMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "EDGEMODE")
  0)

(deftest "sysvar-elevation-getvar-type"
  '((operator . "ELEVATION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ELEVATION"))
  'real)

(deftest "sysvar-enableattraction-getvar-type"
  '((operator . "ENABLEATTRACTION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ENABLEATTRACTION"))
  'int)

(deftest "sysvar-enableattraction-getvar-default"
  '((operator . "ENABLEATTRACTION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ENABLEATTRACTION")
  1)

(deftest "sysvar-enablebimbkupdate-getvar-type"
  '((operator . "ENABLEBIMBKUPDATE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ENABLEBIMBKUPDATE"))
  'int)

(deftest "sysvar-enablebimbkupdate-getvar-default"
  '((operator . "ENABLEBIMBKUPDATE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ENABLEBIMBKUPDATE")
  0)

(deftest "sysvar-enablehyperlinkmenu-getvar-type"
  '((operator . "ENABLEHYPERLINKMENU") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ENABLEHYPERLINKMENU"))
  'int)

(deftest "sysvar-enablehyperlinkmenu-getvar-default"
  '((operator . "ENABLEHYPERLINKMENU") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ENABLEHYPERLINKMENU")
  1)

(deftest "sysvar-enablehyperlinktooltip-getvar-type"
  '((operator . "ENABLEHYPERLINKTOOLTIP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ENABLEHYPERLINKTOOLTIP"))
  'int)

(deftest "sysvar-enablehyperlinktooltip-getvar-default"
  '((operator . "ENABLEHYPERLINKTOOLTIP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ENABLEHYPERLINKTOOLTIP")
  0)

(deftest "sysvar-enablesyncpdf-getvar-type"
  '((operator . "ENABLESYNCPDF") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ENABLESYNCPDF"))
  'int)

(deftest "sysvar-enablesyncpdf-getvar-default"
  '((operator . "ENABLESYNCPDF") (area . "sysvar") (profile . STRICT))
  '(getvar "ENABLESYNCPDF")
  1)

(deftest "sysvar-enterprisemenu-getvar-type"
  '((operator . "ENTERPRISEMENU") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ENTERPRISEMENU"))
  'str)

(deftest-error "sysvar-enterprisemenu-setvar-readonly-signals"
  '((operator . "ENTERPRISEMENU") (area . "sysvar") (profile . STRICT))
  '(setvar "ENTERPRISEMENU" "")
  'sysvar-read-only)

(deftest "sysvar-erhighlight-getvar-type"
  '((operator . "ERHIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ERHIGHLIGHT"))
  'int)

(deftest "sysvar-erhighlight-getvar-default"
  '((operator . "ERHIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "ERHIGHLIGHT")
  1)

(deftest "sysvar-errno-getvar-type"
  '((operator . "ERRNO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ERRNO"))
  'int)

(deftest-error "sysvar-errno-setvar-readonly-signals"
  '((operator . "ERRNO") (area . "sysvar") (profile . STRICT))
  '(setvar "ERRNO" 0)
  'sysvar-read-only)

(deftest "sysvar-erstate-getvar-type"
  '((operator . "ERSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ERSTATE"))
  'int)

(deftest-error "sysvar-erstate-setvar-readonly-signals"
  '((operator . "ERSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "ERSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-experimentalmode-getvar-type"
  '((operator . "EXPERIMENTALMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXPERIMENTALMODE"))
  'int)

(deftest "sysvar-experimentalmode-getvar-default"
  '((operator . "EXPERIMENTALMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "EXPERIMENTALMODE")
  0)

(deftest "sysvar-experimentalonstartpage-getvar-type"
  '((operator . "EXPERIMENTALONSTARTPAGE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXPERIMENTALONSTARTPAGE"))
  'int)

(deftest "sysvar-experimentalonstartpage-getvar-default"
  '((operator . "EXPERIMENTALONSTARTPAGE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "EXPERIMENTALONSTARTPAGE")
  1)

(deftest "sysvar-expert-getvar-type"
  '((operator . "EXPERT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPERT"))
  'int)

(deftest "sysvar-expinsalign-getvar-type"
  '((operator . "EXPINSALIGN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXPINSALIGN"))
  'int)

(deftest "sysvar-expinsalign-getvar-default"
  '((operator . "EXPINSALIGN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "EXPINSALIGN")
  0)

(deftest "sysvar-expinsangle-getvar-type"
  '((operator . "EXPINSANGLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXPINSANGLE"))
  'real)

(deftest "sysvar-expinsangle-getvar-default"
  '((operator . "EXPINSANGLE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "EXPINSANGLE")
  0.0)

(deftest "sysvar-expinsfixangle-getvar-type"
  '((operator . "EXPINSFIXANGLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXPINSFIXANGLE"))
  'int)

(deftest "sysvar-expinsfixangle-getvar-default"
  '((operator . "EXPINSFIXANGLE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "EXPINSFIXANGLE")
  1)

(deftest "sysvar-expinsfixscale-getvar-type"
  '((operator . "EXPINSFIXSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXPINSFIXSCALE"))
  'int)

(deftest "sysvar-expinsfixscale-getvar-default"
  '((operator . "EXPINSFIXSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "EXPINSFIXSCALE")
  1)

(deftest "sysvar-expinsscale-getvar-type"
  '((operator . "EXPINSSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXPINSSCALE"))
  'real)

(deftest "sysvar-expinsscale-getvar-default"
  '((operator . "EXPINSSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "EXPINSSCALE")
  1.0)

(deftest "sysvar-explmode-getvar-type"
  '((operator . "EXPLMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPLMODE"))
  'int)

(deftest "sysvar-export3dpdfwriter-getvar-type"
  '((operator . "EXPORT3DPDFWRITER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORT3DPDFWRITER"))
  'int)

(deftest "sysvar-export3dpdfwriter-getvar-default"
  '((operator . "EXPORT3DPDFWRITER") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPORT3DPDFWRITER")
  1)

(deftest "sysvar-exportacisassemblywriter-getvar-type"
  '((operator . "EXPORTACISASSEMBLYWRITER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTACISASSEMBLYWRITER"))
  'int)

(deftest "sysvar-exportacisassemblywriter-getvar-default"
  '((operator . "EXPORTACISASSEMBLYWRITER") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPORTACISASSEMBLYWRITER")
  0)

(deftest "sysvar-exportacisformatversion-getvar-type"
  '((operator . "EXPORTACISFORMATVERSION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXPORTACISFORMATVERSION"))
  'int)

(deftest "sysvar-exportacisformatversion-getvar-default"
  '((operator . "EXPORTACISFORMATVERSION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "EXPORTACISFORMATVERSION")
  0)

(deftest "sysvar-exportcatiav4formatversion-getvar-type"
  '((operator . "EXPORTCATIAV4FORMATVERSION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTCATIAV4FORMATVERSION"))
  'int)

(deftest "sysvar-exportcatiav4formatversion-getvar-default"
  '((operator . "EXPORTCATIAV4FORMATVERSION") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPORTCATIAV4FORMATVERSION")
  0)

(deftest "sysvar-exportcatiav5formatversion-getvar-type"
  '((operator . "EXPORTCATIAV5FORMATVERSION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXPORTCATIAV5FORMATVERSION"))
  'int)

(deftest "sysvar-exportcatiav5formatversion-getvar-default"
  '((operator . "EXPORTCATIAV5FORMATVERSION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "EXPORTCATIAV5FORMATVERSION")
  0)

(deftest "sysvar-exporteplotformat-getvar-type"
  '((operator . "EXPORTEPLOTFORMAT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTEPLOTFORMAT"))
  'int)

(deftest "sysvar-exporteplotformat-getvar-default"
  '((operator . "EXPORTEPLOTFORMAT") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPORTEPLOTFORMAT")
  2)

(deftest "sysvar-exportgeometryflags-getvar-type"
  '((operator . "EXPORTGEOMETRYFLAGS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTGEOMETRYFLAGS"))
  'int)

(deftest "sysvar-exportgeometryflags-getvar-default"
  '((operator . "EXPORTGEOMETRYFLAGS") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPORTGEOMETRYFLAGS")
  0)

(deftest "sysvar-exporthiddenparts-getvar-type"
  '((operator . "EXPORTHIDDENPARTS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTHIDDENPARTS"))
  'int)

(deftest "sysvar-exporthiddenparts-getvar-default"
  '((operator . "EXPORTHIDDENPARTS") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPORTHIDDENPARTS")
  0)

(deftest "sysvar-exportmodelspace-getvar-type"
  '((operator . "EXPORTMODELSPACE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTMODELSPACE"))
  'int)

(deftest "sysvar-exportpagesetup-getvar-type"
  '((operator . "EXPORTPAGESETUP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTPAGESETUP"))
  'int)

(deftest "sysvar-exportpaperspace-getvar-type"
  '((operator . "EXPORTPAPERSPACE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTPAPERSPACE"))
  'int)

(deftest "sysvar-exportparasolidformatversion-getvar-type"
  '((operator . "EXPORTPARASOLIDFORMATVERSION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXPORTPARASOLIDFORMATVERSION"))
  'int)

(deftest "sysvar-exportparasolidformatversion-getvar-default"
  '((operator . "EXPORTPARASOLIDFORMATVERSION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "EXPORTPARASOLIDFORMATVERSION")
  0)

(deftest "sysvar-exportproductstructure-getvar-type"
  '((operator . "EXPORTPRODUCTSTRUCTURE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTPRODUCTSTRUCTURE"))
  'int)

(deftest "sysvar-exportproductstructure-getvar-default"
  '((operator . "EXPORTPRODUCTSTRUCTURE") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPORTPRODUCTSTRUCTURE")
  1)

(deftest "sysvar-exportstepformatversion-getvar-type"
  '((operator . "EXPORTSTEPFORMATVERSION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTSTEPFORMATVERSION"))
  'int)

(deftest "sysvar-exportstepformatversion-getvar-default"
  '((operator . "EXPORTSTEPFORMATVERSION") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPORTSTEPFORMATVERSION")
  1)

(deftest "sysvar-exportxcgmformatversion-getvar-type"
  '((operator . "EXPORTXCGMFORMATVERSION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPORTXCGMFORMATVERSION"))
  'int)

(deftest "sysvar-exportxcgmformatversion-getvar-default"
  '((operator . "EXPORTXCGMFORMATVERSION") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPORTXCGMFORMATVERSION")
  0)

(deftest "sysvar-expvalue-getvar-type"
  '((operator . "EXPVALUE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPVALUE"))
  'real)

(deftest "sysvar-expvalue-getvar-default"
  '((operator . "EXPVALUE") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPVALUE")
  8.8)

(deftest "sysvar-expwhitebalance-getvar-type"
  '((operator . "EXPWHITEBALANCE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXPWHITEBALANCE"))
  'real)

(deftest "sysvar-expwhitebalance-getvar-default"
  '((operator . "EXPWHITEBALANCE") (area . "sysvar") (profile . STRICT))
  '(getvar "EXPWHITEBALANCE")
  6500.0)

(deftest "sysvar-extmax-getvar-type"
  '((operator . "EXTMAX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXTMAX"))
  'list)

(deftest-error "sysvar-extmax-setvar-readonly-signals"
  '((operator . "EXTMAX") (area . "sysvar") (profile . STRICT))
  '(setvar "EXTMAX" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-extmin-getvar-type"
  '((operator . "EXTMIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXTMIN"))
  'list)

(deftest-error "sysvar-extmin-setvar-readonly-signals"
  '((operator . "EXTMIN") (area . "sysvar") (profile . STRICT))
  '(setvar "EXTMIN" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-extnames-getvar-type"
  '((operator . "EXTNAMES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "EXTNAMES"))
  'int)

(deftest "sysvar-extnames-getvar-default"
  '((operator . "EXTNAMES") (area . "sysvar") (profile . STRICT))
  '(getvar "EXTNAMES")
  1)

(deftest "sysvar-extrudeinside-getvar-type"
  '((operator . "EXTRUDEINSIDE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXTRUDEINSIDE"))
  'int)

(deftest "sysvar-extrudeoutside-getvar-type"
  '((operator . "EXTRUDEOUTSIDE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "EXTRUDEOUTSIDE"))
  'int)

(deftest "sysvar-faceterdevnormal-getvar-type"
  '((operator . "FACETERDEVNORMAL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FACETERDEVNORMAL"))
  'real)

(deftest "sysvar-faceterdevnormal-getvar-default"
  '((operator . "FACETERDEVNORMAL") (area . "sysvar") (profile . STRICT))
  '(getvar "FACETERDEVNORMAL")
  40.0)

(deftest "sysvar-faceterdevsurface-getvar-type"
  '((operator . "FACETERDEVSURFACE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FACETERDEVSURFACE"))
  'real)

(deftest "sysvar-faceterdevsurface-getvar-default"
  '((operator . "FACETERDEVSURFACE") (area . "sysvar") (profile . STRICT))
  '(getvar "FACETERDEVSURFACE")
  0.001)

(deftest "sysvar-facetermaxedgelength-getvar-type"
  '((operator . "FACETERMAXEDGELENGTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FACETERMAXEDGELENGTH"))
  'real)

(deftest "sysvar-facetermaxedgelength-getvar-default"
  '((operator . "FACETERMAXEDGELENGTH") (area . "sysvar") (profile . STRICT))
  '(getvar "FACETERMAXEDGELENGTH")
  0.0)

(deftest "sysvar-facetermaxgrid-getvar-type"
  '((operator . "FACETERMAXGRID") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FACETERMAXGRID"))
  'int)

(deftest "sysvar-facetermaxgrid-getvar-default"
  '((operator . "FACETERMAXGRID") (area . "sysvar") (profile . STRICT))
  '(getvar "FACETERMAXGRID")
  4096)

(deftest "sysvar-facetermeshtype-getvar-type"
  '((operator . "FACETERMESHTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FACETERMESHTYPE"))
  'int)

(deftest "sysvar-facetermeshtype-getvar-default"
  '((operator . "FACETERMESHTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "FACETERMESHTYPE")
  0)

(deftest "sysvar-faceterminvgrid-getvar-type"
  '((operator . "FACETERMINVGRID") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FACETERMINVGRID"))
  'int)

(deftest "sysvar-faceterminvgrid-getvar-default"
  '((operator . "FACETERMINVGRID") (area . "sysvar") (profile . STRICT))
  '(getvar "FACETERMINVGRID")
  0)

(deftest "sysvar-faceterprimitivemode-getvar-type"
  '((operator . "FACETERPRIMITIVEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FACETERPRIMITIVEMODE"))
  'int)

(deftest "sysvar-faceterprimitivemode-getvar-default"
  '((operator . "FACETERPRIMITIVEMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "FACETERPRIMITIVEMODE")
  1)

(deftest "sysvar-facetersmoothlev-getvar-type"
  '((operator . "FACETERSMOOTHLEV") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FACETERSMOOTHLEV"))
  'int)

(deftest "sysvar-facetersmoothlev-getvar-default"
  '((operator . "FACETERSMOOTHLEV") (area . "sysvar") (profile . STRICT))
  '(getvar "FACETERSMOOTHLEV")
  1)

(deftest "sysvar-facetratio-getvar-type"
  '((operator . "FACETRATIO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FACETRATIO"))
  'int)

(deftest "sysvar-facetres-getvar-type"
  '((operator . "FACETRES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FACETRES"))
  'real)

(deftest "sysvar-fastshadedmode-getvar-type"
  '((operator . "FASTSHADEDMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FASTSHADEDMODE"))
  'int)

(deftest "sysvar-fastshadedmode-getvar-default"
  '((operator . "FASTSHADEDMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "FASTSHADEDMODE")
  1)

(deftest "sysvar-fbxexportcameras-getvar-type"
  '((operator . "FBXEXPORTCAMERAS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FBXEXPORTCAMERAS"))
  'int)

(deftest "sysvar-fbxexportcameras-getvar-default"
  '((operator . "FBXEXPORTCAMERAS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FBXEXPORTCAMERAS")
  1)

(deftest "sysvar-fbxexportentities-getvar-type"
  '((operator . "FBXEXPORTENTITIES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FBXEXPORTENTITIES"))
  'int)

(deftest "sysvar-fbxexportentities-getvar-default"
  '((operator . "FBXEXPORTENTITIES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FBXEXPORTENTITIES")
  1)

(deftest "sysvar-fbxexportentitiesseltype-getvar-type"
  '((operator . "FBXEXPORTENTITIESSELTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FBXEXPORTENTITIESSELTYPE"))
  'int)

(deftest "sysvar-fbxexportentitiesseltype-getvar-default"
  '((operator . "FBXEXPORTENTITIESSELTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FBXEXPORTENTITIESSELTYPE")
  0)

(deftest "sysvar-fbxexportlights-getvar-type"
  '((operator . "FBXEXPORTLIGHTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FBXEXPORTLIGHTS"))
  'int)

(deftest "sysvar-fbxexportlights-getvar-default"
  '((operator . "FBXEXPORTLIGHTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FBXEXPORTLIGHTS")
  1)

(deftest "sysvar-fbxexportmaterials-getvar-type"
  '((operator . "FBXEXPORTMATERIALS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FBXEXPORTMATERIALS"))
  'int)

(deftest "sysvar-fbxexportmaterials-getvar-default"
  '((operator . "FBXEXPORTMATERIALS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FBXEXPORTMATERIALS")
  1)

(deftest "sysvar-fbxexporttextures-getvar-type"
  '((operator . "FBXEXPORTTEXTURES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FBXEXPORTTEXTURES"))
  'int)

(deftest "sysvar-fbxexporttextures-getvar-default"
  '((operator . "FBXEXPORTTEXTURES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FBXEXPORTTEXTURES")
  0)

(deftest "sysvar-fbxexporttexturespath-getvar-type"
  '((operator . "FBXEXPORTTEXTURESPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FBXEXPORTTEXTURESPATH"))
  'str)

(deftest "sysvar-featurecolors-getvar-type"
  '((operator . "FEATURECOLORS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FEATURECOLORS"))
  'int)

(deftest "sysvar-featurecolors-getvar-default"
  '((operator . "FEATURECOLORS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FEATURECOLORS")
  1)

(deftest "sysvar-fielddisplay-getvar-type"
  '((operator . "FIELDDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FIELDDISPLAY"))
  'int)

(deftest "sysvar-fielddisplay-getvar-default"
  '((operator . "FIELDDISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "FIELDDISPLAY")
  1)

(deftest "sysvar-fieldeval-getvar-type"
  '((operator . "FIELDEVAL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FIELDEVAL"))
  'int)

(deftest "sysvar-filedia-getvar-type"
  '((operator . "FILEDIA") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FILEDIA"))
  'int)

(deftest "sysvar-filedia-getvar-default"
  '((operator . "FILEDIA") (area . "sysvar") (profile . STRICT))
  '(getvar "FILEDIA")
  1)

(deftest "sysvar-filetabpreview-getvar-type"
  '((operator . "FILETABPREVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FILETABPREVIEW"))
  'int)

(deftest "sysvar-filetabpreview-getvar-default"
  '((operator . "FILETABPREVIEW") (area . "sysvar") (profile . STRICT))
  '(getvar "FILETABPREVIEW")
  1)

(deftest "sysvar-filetabstate-getvar-type"
  '((operator . "FILETABSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FILETABSTATE"))
  'int)

(deftest-error "sysvar-filetabstate-setvar-readonly-signals"
  '((operator . "FILETABSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "FILETABSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-filetabthumbhover-getvar-type"
  '((operator . "FILETABTHUMBHOVER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FILETABTHUMBHOVER"))
  'int)

(deftest "sysvar-filetabthumbhover-getvar-default"
  '((operator . "FILETABTHUMBHOVER") (area . "sysvar") (profile . STRICT))
  '(getvar "FILETABTHUMBHOVER")
  1)

(deftest "sysvar-filletpolyarc-getvar-type"
  '((operator . "FILLETPOLYARC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FILLETPOLYARC"))
  'int)

(deftest "sysvar-filletpolyarc-getvar-default"
  '((operator . "FILLETPOLYARC") (area . "sysvar") (profile . STRICT))
  '(getvar "FILLETPOLYARC")
  1)

(deftest "sysvar-filletrad-getvar-type"
  '((operator . "FILLETRAD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FILLETRAD"))
  'real)

(deftest "sysvar-filletweldingcombineadjacent-getvar-type"
  '((operator . "FILLETWELDINGCOMBINEADJACENT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FILLETWELDINGCOMBINEADJACENT"))
  'int)

(deftest "sysvar-filletweldingcombineadjacent-getvar-default"
  '((operator . "FILLETWELDINGCOMBINEADJACENT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FILLETWELDINGCOMBINEADJACENT")
  1)

(deftest "sysvar-filletweldingmaxgapratio-getvar-type"
  '((operator . "FILLETWELDINGMAXGAPRATIO") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FILLETWELDINGMAXGAPRATIO"))
  'real)

(deftest "sysvar-filletweldingmaxgapratio-getvar-default"
  '((operator . "FILLETWELDINGMAXGAPRATIO") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FILLETWELDINGMAXGAPRATIO")
  0.4)

(deftest "sysvar-filletweldingzsize-getvar-type"
  '((operator . "FILLETWELDINGZSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FILLETWELDINGZSIZE"))
  'real)

(deftest "sysvar-filletweldingzsize-getvar-default"
  '((operator . "FILLETWELDINGZSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FILLETWELDINGZSIZE")
  5.0)

(deftest "sysvar-fillmode-getvar-type"
  '((operator . "FILLMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FILLMODE"))
  'int)

(deftest "sysvar-fillmode-getvar-default"
  '((operator . "FILLMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "FILLMODE")
  1)

(deftest "sysvar-fitlinefitarcmode-getvar-type"
  '((operator . "FITLINEFITARCMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FITLINEFITARCMODE"))
  'int)

(deftest "sysvar-fitlinefitarcmode-getvar-default"
  '((operator . "FITLINEFITARCMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "FITLINEFITARCMODE")
  0)

(deftest "sysvar-fittingradiustype-getvar-type"
  '((operator . "FITTINGRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FITTINGRADIUSTYPE"))
  'int)

(deftest "sysvar-fittingradiustype-getvar-default"
  '((operator . "FITTINGRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FITTINGRADIUSTYPE")
  0)

(deftest "sysvar-fittingradiusvalue-getvar-type"
  '((operator . "FITTINGRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FITTINGRADIUSVALUE"))
  'real)

(deftest "sysvar-fittingradiusvalue-getvar-default"
  '((operator . "FITTINGRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FITTINGRADIUSVALUE")
  1.5)

(deftest "sysvar-flangeasmdefaultgasket-getvar-type"
  '((operator . "FLANGEASMDEFAULTGASKET") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "FLANGEASMDEFAULTGASKET"))
  'str)

(deftest "sysvar-flangeasmdefaultgasket-getvar-default"
  '((operator . "FLANGEASMDEFAULTGASKET") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "FLANGEASMDEFAULTGASKET")
  "ASME B16.21 Gasket FullFace for ASME B16.5")

(deftest "sysvar-fontalt-getvar-type"
  '((operator . "FONTALT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FONTALT"))
  'str)

(deftest "sysvar-fontalt-getvar-default"
  '((operator . "FONTALT") (area . "sysvar") (profile . STRICT))
  '(getvar "FONTALT")
  "simplex.shx")

(deftest "sysvar-fontmap-getvar-type"
  '((operator . "FONTMAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FONTMAP"))
  'str)

(deftest "sysvar-frame-getvar-type"
  '((operator . "FRAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FRAME"))
  'int)

(deftest "sysvar-frameselection-getvar-type"
  '((operator . "FRAMESELECTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FRAMESELECTION"))
  'int)

(deftest "sysvar-frameselection-getvar-default"
  '((operator . "FRAMESELECTION") (area . "sysvar") (profile . STRICT))
  '(getvar "FRAMESELECTION")
  1)

(deftest "sysvar-frontz-getvar-type"
  '((operator . "FRONTZ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FRONTZ"))
  'real)

(deftest-error "sysvar-frontz-setvar-readonly-signals"
  '((operator . "FRONTZ") (area . "sysvar") (profile . STRICT))
  '(setvar "FRONTZ" 0.0)
  'sysvar-read-only)

(deftest "sysvar-fullopen-getvar-type"
  '((operator . "FULLOPEN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FULLOPEN"))
  'int)

(deftest-error "sysvar-fullopen-setvar-readonly-signals"
  '((operator . "FULLOPEN") (area . "sysvar") (profile . STRICT))
  '(setvar "FULLOPEN" 0)
  'sysvar-read-only)

(deftest "sysvar-fullplotpath-getvar-type"
  '((operator . "FULLPLOTPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "FULLPLOTPATH"))
  'int)

(deftest "sysvar-fullplotpath-getvar-default"
  '((operator . "FULLPLOTPATH") (area . "sysvar") (profile . STRICT))
  '(getvar "FULLPLOTPATH")
  1)

(deftest "sysvar-galleryview-getvar-type"
  '((operator . "GALLERYVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GALLERYVIEW"))
  'int)

(deftest "sysvar-galleryview-getvar-default"
  '((operator . "GALLERYVIEW") (area . "sysvar") (profile . STRICT))
  '(getvar "GALLERYVIEW")
  1)

(deftest "sysvar-gearteethnumber-getvar-type"
  '((operator . "GEARTEETHNUMBER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GEARTEETHNUMBER"))
  'int)

(deftest "sysvar-gearteethnumber-getvar-default"
  '((operator . "GEARTEETHNUMBER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GEARTEETHNUMBER")
  1)

(deftest "sysvar-generateassocattrs-getvar-type"
  '((operator . "GENERATEASSOCATTRS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GENERATEASSOCATTRS"))
  'int)

(deftest "sysvar-generateassocviews-getvar-type"
  '((operator . "GENERATEASSOCVIEWS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GENERATEASSOCVIEWS"))
  'int)

(deftest "sysvar-geocsmappriority-getvar-type"
  '((operator . "GEOCSMAPPRIORITY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GEOCSMAPPRIORITY"))
  'str)

(deftest "sysvar-geolatlongformat-getvar-type"
  '((operator . "GEOLATLONGFORMAT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GEOLATLONGFORMAT"))
  'int)

(deftest "sysvar-geolocatemode-getvar-type"
  '((operator . "GEOLOCATEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GEOLOCATEMODE"))
  'int)

(deftest-error "sysvar-geolocatemode-setvar-readonly-signals"
  '((operator . "GEOLOCATEMODE") (area . "sysvar") (profile . STRICT))
  '(setvar "GEOLOCATEMODE" 0)
  'sysvar-read-only)

(deftest "sysvar-geomapmode-getvar-type"
  '((operator . "GEOMAPMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GEOMAPMODE"))
  'int)

(deftest-error "sysvar-geomapmode-setvar-readonly-signals"
  '((operator . "GEOMAPMODE") (area . "sysvar") (profile . STRICT))
  '(setvar "GEOMAPMODE" 0)
  'sysvar-read-only)

(deftest "sysvar-geomarkervisibility-getvar-type"
  '((operator . "GEOMARKERVISIBILITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GEOMARKERVISIBILITY"))
  'int)

(deftest "sysvar-geomarkervisibility-getvar-default"
  '((operator . "GEOMARKERVISIBILITY") (area . "sysvar") (profile . STRICT))
  '(getvar "GEOMARKERVISIBILITY")
  1)

(deftest "sysvar-geomarkpositionsize-getvar-type"
  '((operator . "GEOMARKPOSITIONSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GEOMARKPOSITIONSIZE"))
  'int)

(deftest "sysvar-geomarkpositionsize-getvar-default"
  '((operator . "GEOMARKPOSITIONSIZE") (area . "sysvar") (profile . STRICT))
  '(getvar "GEOMARKPOSITIONSIZE")
  1)

(deftest "sysvar-geomrelations-getvar-type"
  '((operator . "GEOMRELATIONS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GEOMRELATIONS"))
  'int)

(deftest "sysvar-geomrelations-getvar-default"
  '((operator . "GEOMRELATIONS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GEOMRELATIONS")
  0)

(deftest "sysvar-getstarted-getvar-type"
  '((operator . "GETSTARTED") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GETSTARTED"))
  'int)

(deftest "sysvar-getstarted-getvar-default"
  '((operator . "GETSTARTED") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GETSTARTED")
  1)

(deftest "sysvar-gfang-getvar-type"
  '((operator . "GFANG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GFANG"))
  'real)

(deftest "sysvar-gfclr1-getvar-type"
  '((operator . "GFCLR1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GFCLR1"))
  'str)

(deftest "sysvar-gfclr2-getvar-type"
  '((operator . "GFCLR2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GFCLR2"))
  'str)

(deftest "sysvar-gfclrlum-getvar-type"
  '((operator . "GFCLRLUM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GFCLRLUM"))
  'real)

(deftest "sysvar-gfclrstate-getvar-type"
  '((operator . "GFCLRSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GFCLRSTATE"))
  'int)

(deftest "sysvar-gfclrstate-getvar-default"
  '((operator . "GFCLRSTATE") (area . "sysvar") (profile . STRICT))
  '(getvar "GFCLRSTATE")
  0)

(deftest "sysvar-gfname-getvar-type"
  '((operator . "GFNAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GFNAME"))
  'int)

(deftest "sysvar-gfshift-getvar-type"
  '((operator . "GFSHIFT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GFSHIFT"))
  'int)

(deftest "sysvar-gfshift-getvar-default"
  '((operator . "GFSHIFT") (area . "sysvar") (profile . STRICT))
  '(getvar "GFSHIFT")
  0)

(deftest "sysvar-globalopacity-getvar-type"
  '((operator . "GLOBALOPACITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GLOBALOPACITY"))
  'int)

(deftest "sysvar-globalopacity-getvar-default"
  '((operator . "GLOBALOPACITY") (area . "sysvar") (profile . STRICT))
  '(getvar "GLOBALOPACITY")
  100)

(deftest "sysvar-glswapmode-getvar-type"
  '((operator . "GLSWAPMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GLSWAPMODE"))
  'int)

(deftest "sysvar-glswapmode-getvar-default"
  '((operator . "GLSWAPMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GLSWAPMODE")
  2)

(deftest "sysvar-gradientcolorbottom-getvar-type"
  '((operator . "GRADIENTCOLORBOTTOM") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GRADIENTCOLORBOTTOM"))
  'str)

(deftest "sysvar-gradientcolorbottom-getvar-default"
  '((operator . "GRADIENTCOLORBOTTOM") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GRADIENTCOLORBOTTOM")
  "RGB:210,210,210")

(deftest "sysvar-gradientcolormiddle-getvar-type"
  '((operator . "GRADIENTCOLORMIDDLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GRADIENTCOLORMIDDLE"))
  'str)

(deftest "sysvar-gradientcolormiddle-getvar-default"
  '((operator . "GRADIENTCOLORMIDDLE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GRADIENTCOLORMIDDLE")
  "RGB:250,250,250")

(deftest "sysvar-gradientcolortop-getvar-type"
  '((operator . "GRADIENTCOLORTOP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GRADIENTCOLORTOP"))
  'str)

(deftest "sysvar-gradientcolortop-getvar-default"
  '((operator . "GRADIENTCOLORTOP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GRADIENTCOLORTOP")
  "White")

(deftest "sysvar-gradientmode-getvar-type"
  '((operator . "GRADIENTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GRADIENTMODE"))
  'int)

(deftest "sysvar-gradientmode-getvar-default"
  '((operator . "GRADIENTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GRADIENTMODE")
  0)

(deftest "sysvar-gridaxiscolor-getvar-type"
  '((operator . "GRIDAXISCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GRIDAXISCOLOR"))
  'int)

(deftest "sysvar-gridaxiscolor-getvar-default"
  '((operator . "GRIDAXISCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GRIDAXISCOLOR")
  254)

(deftest "sysvar-griddisplay-getvar-type"
  '((operator . "GRIDDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIDDISPLAY"))
  'int)

(deftest "sysvar-gridmajor-getvar-type"
  '((operator . "GRIDMAJOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIDMAJOR"))
  'int)

(deftest "sysvar-gridmajorcolor-getvar-type"
  '((operator . "GRIDMAJORCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GRIDMAJORCOLOR"))
  'int)

(deftest "sysvar-gridminorcolor-getvar-type"
  '((operator . "GRIDMINORCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GRIDMINORCOLOR"))
  'int)

(deftest "sysvar-gridminorcolor-getvar-default"
  '((operator . "GRIDMINORCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GRIDMINORCOLOR")
  250)

(deftest "sysvar-gridmode-getvar-type"
  '((operator . "GRIDMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIDMODE"))
  'int)

(deftest "sysvar-gridstyle-getvar-type"
  '((operator . "GRIDSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIDSTYLE"))
  'int)

(deftest "sysvar-gridunit-getvar-type"
  '((operator . "GRIDUNIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIDUNIT"))
  'list)

(deftest "sysvar-gridxyztint-getvar-type"
  '((operator . "GRIDXYZTINT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GRIDXYZTINT"))
  'int)

(deftest "sysvar-gridxyztint-getvar-default"
  '((operator . "GRIDXYZTINT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GRIDXYZTINT")
  1)

(deftest "sysvar-gripblock-getvar-type"
  '((operator . "GRIPBLOCK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPBLOCK"))
  'int)

(deftest "sysvar-gripblock-getvar-default"
  '((operator . "GRIPBLOCK") (area . "sysvar") (profile . STRICT))
  '(getvar "GRIPBLOCK")
  0)

(deftest "sysvar-gripcolor-getvar-type"
  '((operator . "GRIPCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPCOLOR"))
  'int)

(deftest "sysvar-gripcolor-getvar-default"
  '((operator . "GRIPCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "GRIPCOLOR")
  72)

(deftest "sysvar-gripcontour-getvar-type"
  '((operator . "GRIPCONTOUR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPCONTOUR"))
  'int)

(deftest "sysvar-gripcontour-getvar-default"
  '((operator . "GRIPCONTOUR") (area . "sysvar") (profile . STRICT))
  '(getvar "GRIPCONTOUR")
  251)

(deftest "sysvar-gripdyncolor-getvar-type"
  '((operator . "GRIPDYNCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPDYNCOLOR"))
  'int)

(deftest "sysvar-griphot-getvar-type"
  '((operator . "GRIPHOT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPHOT"))
  'int)

(deftest "sysvar-griphover-getvar-type"
  '((operator . "GRIPHOVER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPHOVER"))
  'int)

(deftest "sysvar-gripmultifunctional-getvar-type"
  '((operator . "GRIPMULTIFUNCTIONAL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPMULTIFUNCTIONAL"))
  'int)

(deftest "sysvar-gripmultifunctional-getvar-default"
  '((operator . "GRIPMULTIFUNCTIONAL") (area . "sysvar") (profile . STRICT))
  '(getvar "GRIPMULTIFUNCTIONAL")
  3)

(deftest "sysvar-gripobjlimit-getvar-type"
  '((operator . "GRIPOBJLIMIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPOBJLIMIT"))
  'int)

(deftest "sysvar-grips-getvar-type"
  '((operator . "GRIPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPS"))
  'int)

(deftest "sysvar-gripsize-getvar-type"
  '((operator . "GRIPSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPSIZE"))
  'int)

(deftest "sysvar-gripsubobjmode-getvar-type"
  '((operator . "GRIPSUBOBJMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPSUBOBJMODE"))
  'int)

(deftest "sysvar-gripsubobjmode-getvar-default"
  '((operator . "GRIPSUBOBJMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "GRIPSUBOBJMODE")
  1)

(deftest "sysvar-griptips-getvar-type"
  '((operator . "GRIPTIPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GRIPTIPS"))
  'int)

(deftest "sysvar-griptips-getvar-default"
  '((operator . "GRIPTIPS") (area . "sysvar") (profile . STRICT))
  '(getvar "GRIPTIPS")
  1)

(deftest "sysvar-groupdisplaymode-getvar-type"
  '((operator . "GROUPDISPLAYMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GROUPDISPLAYMODE"))
  'int)

(deftest "sysvar-groupdisplaymode-getvar-default"
  '((operator . "GROUPDISPLAYMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "GROUPDISPLAYMODE")
  2)

(deftest "sysvar-gsdevicetype2d-getvar-type"
  '((operator . "GSDEVICETYPE2D") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GSDEVICETYPE2D"))
  'int)

(deftest "sysvar-gsdevicetype2d-getvar-default"
  '((operator . "GSDEVICETYPE2D") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GSDEVICETYPE2D")
  0)

(deftest "sysvar-gsdevicetype3d-getvar-type"
  '((operator . "GSDEVICETYPE3D") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "GSDEVICETYPE3D"))
  'int)

(deftest "sysvar-gsdevicetype3d-getvar-default"
  '((operator . "GSDEVICETYPE3D") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "GSDEVICETYPE3D")
  1)

(deftest "sysvar-gtauto-getvar-type"
  '((operator . "GTAUTO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GTAUTO"))
  'int)

(deftest "sysvar-gtauto-getvar-default"
  '((operator . "GTAUTO") (area . "sysvar") (profile . STRICT))
  '(getvar "GTAUTO")
  1)

(deftest "sysvar-gtdefault-getvar-type"
  '((operator . "GTDEFAULT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GTDEFAULT"))
  'int)

(deftest "sysvar-gtdefault-getvar-default"
  '((operator . "GTDEFAULT") (area . "sysvar") (profile . STRICT))
  '(getvar "GTDEFAULT")
  0)

(deftest "sysvar-gtlocation-getvar-type"
  '((operator . "GTLOCATION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "GTLOCATION"))
  'int)

(deftest "sysvar-gtlocation-getvar-default"
  '((operator . "GTLOCATION") (area . "sysvar") (profile . STRICT))
  '(getvar "GTLOCATION")
  1)

(deftest "sysvar-halogap-getvar-type"
  '((operator . "HALOGAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HALOGAP"))
  'int)

(deftest "sysvar-handles-getvar-type"
  '((operator . "HANDLES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HANDLES"))
  'int)

(deftest-error "sysvar-handles-setvar-readonly-signals"
  '((operator . "HANDLES") (area . "sysvar") (profile . STRICT))
  '(setvar "HANDLES" 0)
  'sysvar-read-only)

(deftest "sysvar-handseed-getvar-type"
  '((operator . "HANDSEED") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "HANDSEED"))
  'str)

(deftest-error "sysvar-handseed-setvar-readonly-signals"
  '((operator . "HANDSEED") (area . "sysvar") (profile . BRICSCAD))
  '(setvar "HANDSEED" "")
  'sysvar-read-only)

(deftest "sysvar-helpprefix-getvar-type"
  '((operator . "HELPPREFIX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HELPPREFIX"))
  'str)

(deftest "sysvar-hideprecision-getvar-type"
  '((operator . "HIDEPRECISION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HIDEPRECISION"))
  'int)

(deftest "sysvar-hideprecision-getvar-default"
  '((operator . "HIDEPRECISION") (area . "sysvar") (profile . STRICT))
  '(getvar "HIDEPRECISION")
  0)

(deftest "sysvar-hidesystemprinters-getvar-type"
  '((operator . "HIDESYSTEMPRINTERS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HIDESYSTEMPRINTERS"))
  'int)

(deftest "sysvar-hidesystemprinters-getvar-default"
  '((operator . "HIDESYSTEMPRINTERS") (area . "sysvar") (profile . STRICT))
  '(getvar "HIDESYSTEMPRINTERS")
  0)

(deftest "sysvar-hidetext-getvar-type"
  '((operator . "HIDETEXT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HIDETEXT"))
  'int)

(deftest "sysvar-hidexrefscales-getvar-type"
  '((operator . "HIDEXREFSCALES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HIDEXREFSCALES"))
  'int)

(deftest "sysvar-hidexrefscales-getvar-default"
  '((operator . "HIDEXREFSCALES") (area . "sysvar") (profile . STRICT))
  '(getvar "HIDEXREFSCALES")
  1)

(deftest "sysvar-highlight-getvar-type"
  '((operator . "HIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HIGHLIGHT"))
  'int)

(deftest "sysvar-highlight-getvar-default"
  '((operator . "HIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "HIGHLIGHT")
  1)

(deftest "sysvar-highlightcolor-getvar-type"
  '((operator . "HIGHLIGHTCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "HIGHLIGHTCOLOR"))
  'int)

(deftest "sysvar-highlightcolor-getvar-default"
  '((operator . "HIGHLIGHTCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "HIGHLIGHTCOLOR")
  150)

(deftest "sysvar-highlighteffect-getvar-type"
  '((operator . "HIGHLIGHTEFFECT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "HIGHLIGHTEFFECT"))
  'int)

(deftest "sysvar-highlighteffect-getvar-default"
  '((operator . "HIGHLIGHTEFFECT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "HIGHLIGHTEFFECT")
  3)

(deftest "sysvar-highlight_alpha-getvar-type"
  '((operator . "HIGHLIGHT_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "HIGHLIGHT_ALPHA"))
  'int)

(deftest "sysvar-highlight_alpha-getvar-default"
  '((operator . "HIGHLIGHT_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "HIGHLIGHT_ALPHA")
  85)

(deftest "sysvar-horizonbkg_enable-getvar-type"
  '((operator . "HORIZONBKG_ENABLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "HORIZONBKG_ENABLE"))
  'int)

(deftest "sysvar-horizonbkg_enable-getvar-default"
  '((operator . "HORIZONBKG_ENABLE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "HORIZONBKG_ENABLE")
  1)

(deftest "sysvar-horizonbkg_groundhorizon-getvar-type"
  '((operator . "HORIZONBKG_GROUNDHORIZON") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HORIZONBKG_GROUNDHORIZON"))
  'str)

(deftest "sysvar-horizonbkg_groundhorizon-getvar-default"
  '((operator . "HORIZONBKG_GROUNDHORIZON") (area . "sysvar") (profile . STRICT))
  '(getvar "HORIZONBKG_GROUNDHORIZON")
  "RGB:67,74,80")

(deftest "sysvar-horizonbkg_groundorigin-getvar-type"
  '((operator . "HORIZONBKG_GROUNDORIGIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HORIZONBKG_GROUNDORIGIN"))
  'str)

(deftest "sysvar-horizonbkg_groundorigin-getvar-default"
  '((operator . "HORIZONBKG_GROUNDORIGIN") (area . "sysvar") (profile . STRICT))
  '(getvar "HORIZONBKG_GROUNDORIGIN")
  "RGB:95,103,112")

(deftest "sysvar-horizonbkg_skyhigh-getvar-type"
  '((operator . "HORIZONBKG_SKYHIGH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HORIZONBKG_SKYHIGH"))
  'str)

(deftest "sysvar-horizonbkg_skyhigh-getvar-default"
  '((operator . "HORIZONBKG_SKYHIGH") (area . "sysvar") (profile . STRICT))
  '(getvar "HORIZONBKG_SKYHIGH")
  "RGB:204,229,234")

(deftest "sysvar-horizonbkg_skyhorizon-getvar-type"
  '((operator . "HORIZONBKG_SKYHORIZON") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HORIZONBKG_SKYHORIZON"))
  'str)

(deftest "sysvar-horizonbkg_skyhorizon-getvar-default"
  '((operator . "HORIZONBKG_SKYHORIZON") (area . "sysvar") (profile . STRICT))
  '(getvar "HORIZONBKG_SKYHORIZON")
  "RGB:238,248,250")

(deftest "sysvar-horizonbkg_skylow-getvar-type"
  '((operator . "HORIZONBKG_SKYLOW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HORIZONBKG_SKYLOW"))
  'str)

(deftest "sysvar-horizonbkg_skylow-getvar-default"
  '((operator . "HORIZONBKG_SKYLOW") (area . "sysvar") (profile . STRICT))
  '(getvar "HORIZONBKG_SKYLOW")
  "RGB:238,248,250")

(deftest "sysvar-hotkeyassistant-getvar-type"
  '((operator . "HOTKEYASSISTANT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "HOTKEYASSISTANT"))
  'int)

(deftest "sysvar-hotkeyassistant-getvar-default"
  '((operator . "HOTKEYASSISTANT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "HOTKEYASSISTANT")
  1)

(deftest "sysvar-hpang-getvar-type"
  '((operator . "HPANG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPANG"))
  'real)

(deftest "sysvar-hpannotative-getvar-type"
  '((operator . "HPANNOTATIVE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPANNOTATIVE"))
  'int)

(deftest "sysvar-hpannotative-getvar-default"
  '((operator . "HPANNOTATIVE") (area . "sysvar") (profile . STRICT))
  '(getvar "HPANNOTATIVE")
  0)

(deftest "sysvar-hpassoc-getvar-type"
  '((operator . "HPASSOC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPASSOC"))
  'int)

(deftest "sysvar-hpassoc-getvar-default"
  '((operator . "HPASSOC") (area . "sysvar") (profile . STRICT))
  '(getvar "HPASSOC")
  1)

(deftest "sysvar-hpbackgroundcolor-getvar-type"
  '((operator . "HPBACKGROUNDCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPBACKGROUNDCOLOR"))
  'str)

(deftest "sysvar-hpbound-getvar-type"
  '((operator . "HPBOUND") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPBOUND"))
  'int)

(deftest "sysvar-hpboundretain-getvar-type"
  '((operator . "HPBOUNDRETAIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPBOUNDRETAIN"))
  'int)

(deftest "sysvar-hpcolor-getvar-type"
  '((operator . "HPCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPCOLOR"))
  'str)

(deftest "sysvar-hpdlgmode-getvar-type"
  '((operator . "HPDLGMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPDLGMODE"))
  'int)

(deftest "sysvar-hpdlgmode-getvar-default"
  '((operator . "HPDLGMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "HPDLGMODE")
  2)

(deftest "sysvar-hpdouble-getvar-type"
  '((operator . "HPDOUBLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPDOUBLE"))
  'int)

(deftest "sysvar-hpdrawmode-getvar-type"
  '((operator . "HPDRAWMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPDRAWMODE"))
  'int)

(deftest "sysvar-hpdrawmode-getvar-default"
  '((operator . "HPDRAWMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "HPDRAWMODE")
  0)

(deftest "sysvar-hpdraworder-getvar-type"
  '((operator . "HPDRAWORDER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPDRAWORDER"))
  'int)

(deftest "sysvar-hpgaptol-getvar-type"
  '((operator . "HPGAPTOL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPGAPTOL"))
  'real)

(deftest "sysvar-hpislanddetection-getvar-type"
  '((operator . "HPISLANDDETECTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPISLANDDETECTION"))
  'int)

(deftest "sysvar-hpislanddetectionmode-getvar-type"
  '((operator . "HPISLANDDETECTIONMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPISLANDDETECTIONMODE"))
  'int)

(deftest "sysvar-hpislanddetectionmode-getvar-default"
  '((operator . "HPISLANDDETECTIONMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "HPISLANDDETECTIONMODE")
  1)

(deftest "sysvar-hplayer-getvar-type"
  '((operator . "HPLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPLAYER"))
  'str)

(deftest "sysvar-hplinetype-getvar-type"
  '((operator . "HPLINETYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPLINETYPE"))
  'int)

(deftest "sysvar-hplinetype-getvar-default"
  '((operator . "HPLINETYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "HPLINETYPE")
  0)

(deftest "sysvar-hpmaxareas-getvar-type"
  '((operator . "HPMAXAREAS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPMAXAREAS"))
  'int)

(deftest "sysvar-hpmaxcontourpoints-getvar-type"
  '((operator . "HPMAXCONTOURPOINTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "HPMAXCONTOURPOINTS"))
  'int)

(deftest "sysvar-hpmaxcontourpoints-getvar-default"
  '((operator . "HPMAXCONTOURPOINTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "HPMAXCONTOURPOINTS")
  100000)

(deftest "sysvar-hpmaxlines-getvar-type"
  '((operator . "HPMAXLINES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPMAXLINES"))
  'int)

(deftest "sysvar-hpmaxlines-getvar-default"
  '((operator . "HPMAXLINES") (area . "sysvar") (profile . STRICT))
  '(getvar "HPMAXLINES")
  100000)

(deftest "sysvar-hpname-getvar-type"
  '((operator . "HPNAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPNAME"))
  'str)

(deftest "sysvar-hpobjwarning-getvar-type"
  '((operator . "HPOBJWARNING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPOBJWARNING"))
  'int)

(deftest "sysvar-hporigin-getvar-type"
  '((operator . "HPORIGIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPORIGIN"))
  'list)

(deftest "sysvar-hporiginmode-getvar-type"
  '((operator . "HPORIGINMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPORIGINMODE"))
  'int)

(deftest "sysvar-hporiginmode-getvar-default"
  '((operator . "HPORIGINMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "HPORIGINMODE")
  0)

(deftest "sysvar-hppathalignment-getvar-type"
  '((operator . "HPPATHALIGNMENT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPPATHALIGNMENT"))
  'int)

(deftest "sysvar-hppathalignment-getvar-default"
  '((operator . "HPPATHALIGNMENT") (area . "sysvar") (profile . STRICT))
  '(getvar "HPPATHALIGNMENT")
  1)

(deftest "sysvar-hppathwidth-getvar-type"
  '((operator . "HPPATHWIDTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPPATHWIDTH"))
  'real)

(deftest "sysvar-hppathwidth-getvar-default"
  '((operator . "HPPATHWIDTH") (area . "sysvar") (profile . STRICT))
  '(getvar "HPPATHWIDTH")
  0.25)

(deftest "sysvar-hppickmode-getvar-type"
  '((operator . "HPPICKMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPPICKMODE"))
  'int)

(deftest-error "sysvar-hppickmode-setvar-readonly-signals"
  '((operator . "HPPICKMODE") (area . "sysvar") (profile . STRICT))
  '(setvar "HPPICKMODE" 0)
  'sysvar-read-only)

(deftest "sysvar-hpquickpreview-getvar-type"
  '((operator . "HPQUICKPREVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPQUICKPREVIEW"))
  'int)

(deftest "sysvar-hpquickpreview-getvar-default"
  '((operator . "HPQUICKPREVIEW") (area . "sysvar") (profile . STRICT))
  '(getvar "HPQUICKPREVIEW")
  1)

(deftest "sysvar-hpquickprevtimeout-getvar-type"
  '((operator . "HPQUICKPREVTIMEOUT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPQUICKPREVTIMEOUT"))
  'int)

(deftest "sysvar-hpquickprevtimeout-getvar-default"
  '((operator . "HPQUICKPREVTIMEOUT") (area . "sysvar") (profile . STRICT))
  '(getvar "HPQUICKPREVTIMEOUT")
  2)

(deftest "sysvar-hpscale-getvar-type"
  '((operator . "HPSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPSCALE"))
  'real)

(deftest "sysvar-hpseparate-getvar-type"
  '((operator . "HPSEPARATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPSEPARATE"))
  'int)

(deftest "sysvar-hpseparate-getvar-default"
  '((operator . "HPSEPARATE") (area . "sysvar") (profile . STRICT))
  '(getvar "HPSEPARATE")
  0)

(deftest "sysvar-hpspace-getvar-type"
  '((operator . "HPSPACE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPSPACE"))
  'real)

(deftest "sysvar-hptransparency-getvar-type"
  '((operator . "HPTRANSPARENCY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HPTRANSPARENCY"))
  'str)

(deftest "sysvar-hyperlinkbase-getvar-type"
  '((operator . "HYPERLINKBASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "HYPERLINKBASE"))
  'str)

(deftest "sysvar-hyperlinkbase-getvar-default"
  '((operator . "HYPERLINKBASE") (area . "sysvar") (profile . STRICT))
  '(getvar "HYPERLINKBASE")
  "")

(deftest "sysvar-iblenvironment-getvar-type"
  '((operator . "IBLENVIRONMENT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IBLENVIRONMENT"))
  'int)

(deftest "sysvar-iblenvironment-getvar-default"
  '((operator . "IBLENVIRONMENT") (area . "sysvar") (profile . STRICT))
  '(getvar "IBLENVIRONMENT")
  0)

(deftest "sysvar-ifccreateuniqueguid-getvar-type"
  '((operator . "IFCCREATEUNIQUEGUID") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCCREATEUNIQUEGUID"))
  'int)

(deftest "sysvar-ifccreateuniqueguid-getvar-default"
  '((operator . "IFCCREATEUNIQUEGUID") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCCREATEUNIQUEGUID")
  3)

(deftest "sysvar-ifcexplodeexternalreferences-getvar-type"
  '((operator . "IFCEXPLODEEXTERNALREFERENCES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPLODEEXTERNALREFERENCES"))
  'int)

(deftest "sysvar-ifcexplodeexternalreferences-getvar-default"
  '((operator . "IFCEXPLODEEXTERNALREFERENCES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPLODEEXTERNALREFERENCES")
  0)

(deftest "sysvar-ifcexportauthor-getvar-type"
  '((operator . "IFCEXPORTAUTHOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTAUTHOR"))
  'str)

(deftest "sysvar-ifcexportauthor-getvar-default"
  '((operator . "IFCEXPORTAUTHOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTAUTHOR")
  "\" \"")

(deftest "sysvar-ifcexportauthorization-getvar-type"
  '((operator . "IFCEXPORTAUTHORIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTAUTHORIZATION"))
  'str)

(deftest "sysvar-ifcexportauthorization-getvar-default"
  '((operator . "IFCEXPORTAUTHORIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTAUTHORIZATION")
  "\" \"")

(deftest "sysvar-ifcexportbasequantities-getvar-type"
  '((operator . "IFCEXPORTBASEQUANTITIES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTBASEQUANTITIES"))
  'int)

(deftest "sysvar-ifcexportbasequantities-getvar-default"
  '((operator . "IFCEXPORTBASEQUANTITIES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTBASEQUANTITIES")
  0)

(deftest "sysvar-ifcexportelementsonoffandfrozenlayer-getvar-type"
  '((operator . "IFCEXPORTELEMENTSONOFFANDFROZENLAYER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTELEMENTSONOFFANDFROZENLAYER"))
  'int)

(deftest "sysvar-ifcexportelementsonoffandfrozenlayer-getvar-default"
  '((operator . "IFCEXPORTELEMENTSONOFFANDFROZENLAYER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTELEMENTSONOFFANDFROZENLAYER")
  1)

(deftest "sysvar-ifcexportidspropertiesonly-getvar-type"
  '((operator . "IFCEXPORTIDSPROPERTIESONLY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTIDSPROPERTIESONLY"))
  'int)

(deftest "sysvar-ifcexportidspropertiesonly-getvar-default"
  '((operator . "IFCEXPORTIDSPROPERTIESONLY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTIDSPROPERTIESONLY")
  0)

(deftest "sysvar-ifcexportmappingpath-getvar-type"
  '((operator . "IFCEXPORTMAPPINGPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IFCEXPORTMAPPINGPATH"))
  'str)

(deftest "sysvar-ifcexportmappingpath-getvar-default"
  '((operator . "IFCEXPORTMAPPINGPATH") (area . "sysvar") (profile . STRICT))
  '(getvar "IFCEXPORTMAPPINGPATH")
  "\" \"")

(deftest "sysvar-ifcexportmultiplyelementsasaggregated-getvar-type"
  '((operator . "IFCEXPORTMULTIPLYELEMENTSASAGGREGATED") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTMULTIPLYELEMENTSASAGGREGATED"))
  'int)

(deftest "sysvar-ifcexportmultiplyelementsasaggregated-getvar-default"
  '((operator . "IFCEXPORTMULTIPLYELEMENTSASAGGREGATED") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTMULTIPLYELEMENTSASAGGREGATED")
  0)

(deftest "sysvar-ifcexportorganization-getvar-type"
  '((operator . "IFCEXPORTORGANIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTORGANIZATION"))
  'str)

(deftest "sysvar-ifcexportorganization-getvar-default"
  '((operator . "IFCEXPORTORGANIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTORGANIZATION")
  "\" \"")

(deftest "sysvar-ifcexportprofilecenterofgravity-getvar-type"
  '((operator . "IFCEXPORTPROFILECENTEROFGRAVITY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTPROFILECENTEROFGRAVITY"))
  'int)

(deftest "sysvar-ifcexportprofilecenterofgravity-getvar-default"
  '((operator . "IFCEXPORTPROFILECENTEROFGRAVITY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTPROFILECENTEROFGRAVITY")
  0)

(deftest "sysvar-ifcexportsubtractopenings-getvar-type"
  '((operator . "IFCEXPORTSUBTRACTOPENINGS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTSUBTRACTOPENINGS"))
  'int)

(deftest "sysvar-ifcexportsubtractopenings-getvar-default"
  '((operator . "IFCEXPORTSUBTRACTOPENINGS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTSUBTRACTOPENINGS")
  0)

(deftest "sysvar-ifcexportsweptsolidsasbrep-getvar-type"
  '((operator . "IFCEXPORTSWEPTSOLIDSASBREP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTSWEPTSOLIDSASBREP"))
  'int)

(deftest "sysvar-ifcexportsweptsolidsasbrep-getvar-default"
  '((operator . "IFCEXPORTSWEPTSOLIDSASBREP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTSWEPTSOLIDSASBREP")
  0)

(deftest "sysvar-ifcexporttesselation-getvar-type"
  '((operator . "IFCEXPORTTESSELATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTTESSELATION"))
  'int)

(deftest "sysvar-ifcexporttesselation-getvar-default"
  '((operator . "IFCEXPORTTESSELATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTTESSELATION")
  0)

(deftest "sysvar-ifcexportvalidatemodel-getvar-type"
  '((operator . "IFCEXPORTVALIDATEMODEL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCEXPORTVALIDATEMODEL"))
  'int)

(deftest "sysvar-ifcexportvalidatemodel-getvar-default"
  '((operator . "IFCEXPORTVALIDATEMODEL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IFCEXPORTVALIDATEMODEL")
  0)

(deftest "sysvar-ifcsettingsconfig-getvar-type"
  '((operator . "IFCSETTINGSCONFIG") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IFCSETTINGSCONFIG"))
  'str)

(deftest "sysvar-ifctesselatebsplinecurvesandsurfaces-getvar-type"
  '((operator . "IFCTESSELATEBSPLINECURVESANDSURFACES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IFCTESSELATEBSPLINECURVESANDSURFACES"))
  'int)

(deftest "sysvar-ifctesselatebsplinecurvesandsurfaces-getvar-default"
  '((operator . "IFCTESSELATEBSPLINECURVESANDSURFACES") (area . "sysvar") (profile . STRICT))
  '(getvar "IFCTESSELATEBSPLINECURVESANDSURFACES")
  0)

(deftest "sysvar-imageasync-getvar-type"
  '((operator . "IMAGEASYNC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IMAGEASYNC"))
  'int)

(deftest "sysvar-imageasync-getvar-default"
  '((operator . "IMAGEASYNC") (area . "sysvar") (profile . STRICT))
  '(getvar "IMAGEASYNC")
  1)

(deftest "sysvar-imagecachefolder-getvar-type"
  '((operator . "IMAGECACHEFOLDER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMAGECACHEFOLDER"))
  'str)

(deftest "sysvar-imagecachefolder-getvar-default"
  '((operator . "IMAGECACHEFOLDER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMAGECACHEFOLDER")
  "{User}AppData/Local/Temp/ImageCache")

(deftest "sysvar-imagecachemaxmemory-getvar-type"
  '((operator . "IMAGECACHEMAXMEMORY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMAGECACHEMAXMEMORY"))
  'int)

(deftest "sysvar-imagecachemaxmemory-getvar-default"
  '((operator . "IMAGECACHEMAXMEMORY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMAGECACHEMAXMEMORY")
  160)

(deftest "sysvar-imagediskcache-getvar-type"
  '((operator . "IMAGEDISKCACHE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMAGEDISKCACHE"))
  'int)

(deftest "sysvar-imagediskcache-getvar-default"
  '((operator . "IMAGEDISKCACHE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMAGEDISKCACHE")
  1)

(deftest "sysvar-imageframe-getvar-type"
  '((operator . "IMAGEFRAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IMAGEFRAME"))
  'int)

(deftest "sysvar-imagehlt-getvar-type"
  '((operator . "IMAGEHLT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IMAGEHLT"))
  'int)

(deftest "sysvar-imagehlt-getvar-default"
  '((operator . "IMAGEHLT") (area . "sysvar") (profile . STRICT))
  '(getvar "IMAGEHLT")
  0)

(deftest "sysvar-imagenotify-getvar-type"
  '((operator . "IMAGENOTIFY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMAGENOTIFY"))
  'int)

(deftest "sysvar-imagenotify-getvar-default"
  '((operator . "IMAGENOTIFY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMAGENOTIFY")
  0)

(deftest "sysvar-impliedface-getvar-type"
  '((operator . "IMPLIEDFACE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IMPLIEDFACE"))
  'int)

(deftest "sysvar-impliedface-getvar-default"
  '((operator . "IMPLIEDFACE") (area . "sysvar") (profile . STRICT))
  '(getvar "IMPLIEDFACE")
  1)

(deftest "sysvar-importcatiav5edgeattributes-getvar-type"
  '((operator . "IMPORTCATIAV5EDGEATTRIBUTES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTCATIAV5EDGEATTRIBUTES"))
  'int)

(deftest "sysvar-importcatiav5edgeattributes-getvar-default"
  '((operator . "IMPORTCATIAV5EDGEATTRIBUTES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTCATIAV5EDGEATTRIBUTES")
  1)

(deftest "sysvar-importcatiav5representation-getvar-type"
  '((operator . "IMPORTCATIAV5REPRESENTATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTCATIAV5REPRESENTATION"))
  'int)

(deftest "sysvar-importcatiav5representation-getvar-default"
  '((operator . "IMPORTCATIAV5REPRESENTATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTCATIAV5REPRESENTATION")
  1)

(deftest "sysvar-importcatiav5searchpathspreference-getvar-type"
  '((operator . "IMPORTCATIAV5SEARCHPATHSPREFERENCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTCATIAV5SEARCHPATHSPREFERENCE"))
  'int)

(deftest "sysvar-importcatiav5searchpathspreference-getvar-default"
  '((operator . "IMPORTCATIAV5SEARCHPATHSPREFERENCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTCATIAV5SEARCHPATHSPREFERENCE")
  1)

(deftest "sysvar-importcolors-getvar-type"
  '((operator . "IMPORTCOLORS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IMPORTCOLORS"))
  'int)

(deftest "sysvar-importcolors-getvar-default"
  '((operator . "IMPORTCOLORS") (area . "sysvar") (profile . STRICT))
  '(getvar "IMPORTCOLORS")
  1)

(deftest "sysvar-importcreoalternatesearchpaths-getvar-type"
  '((operator . "IMPORTCREOALTERNATESEARCHPATHS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTCREOALTERNATESEARCHPATHS"))
  'str)

(deftest "sysvar-importcreoconfiguration-getvar-type"
  '((operator . "IMPORTCREOCONFIGURATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTCREOCONFIGURATION"))
  'str)

(deftest "sysvar-importcuifileexists-getvar-type"
  '((operator . "IMPORTCUIFILEEXISTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTCUIFILEEXISTS"))
  'int)

(deftest "sysvar-importcuifileexists-getvar-default"
  '((operator . "IMPORTCUIFILEEXISTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTCUIFILEEXISTS")
  0)

(deftest "sysvar-importhiddenparts-getvar-type"
  '((operator . "IMPORTHIDDENPARTS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IMPORTHIDDENPARTS"))
  'int)

(deftest "sysvar-importhiddenparts-getvar-default"
  '((operator . "IMPORTHIDDENPARTS") (area . "sysvar") (profile . STRICT))
  '(getvar "IMPORTHIDDENPARTS")
  0)

(deftest "sysvar-importigessimplify-getvar-type"
  '((operator . "IMPORTIGESSIMPLIFY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTIGESSIMPLIFY"))
  'int)

(deftest "sysvar-importigessimplify-getvar-default"
  '((operator . "IMPORTIGESSIMPLIFY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTIGESSIMPLIFY")
  1)

(deftest "sysvar-importigesstitch-getvar-type"
  '((operator . "IMPORTIGESSTITCH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTIGESSTITCH"))
  'int)

(deftest "sysvar-importigesstitch-getvar-default"
  '((operator . "IMPORTIGESSTITCH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTIGESSTITCH")
  1)

(deftest "sysvar-importinventoralternatesearchpaths-getvar-type"
  '((operator . "IMPORTINVENTORALTERNATESEARCHPATHS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTINVENTORALTERNATESEARCHPATHS"))
  'str)

(deftest "sysvar-importinventorsearchpathspreference-getvar-type"
  '((operator . "IMPORTINVENTORSEARCHPATHSPREFERENCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTINVENTORSEARCHPATHSPREFERENCE"))
  'int)

(deftest "sysvar-importinventorsearchpathspreference-getvar-default"
  '((operator . "IMPORTINVENTORSEARCHPATHSPREFERENCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTINVENTORSEARCHPATHSPREFERENCE")
  1)

(deftest "sysvar-importjtrepresentation-getvar-type"
  '((operator . "IMPORTJTREPRESENTATION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IMPORTJTREPRESENTATION"))
  'int)

(deftest "sysvar-importjtrepresentation-getvar-default"
  '((operator . "IMPORTJTREPRESENTATION") (area . "sysvar") (profile . STRICT))
  '(getvar "IMPORTJTREPRESENTATION")
  1)

(deftest "sysvar-importnxalternatesearchpaths-getvar-type"
  '((operator . "IMPORTNXALTERNATESEARCHPATHS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTNXALTERNATESEARCHPATHS"))
  'str)

(deftest "sysvar-importnxconfiguration-getvar-type"
  '((operator . "IMPORTNXCONFIGURATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTNXCONFIGURATION"))
  'str)

(deftest "sysvar-importnxsearchpathspreference-getvar-type"
  '((operator . "IMPORTNXSEARCHPATHSPREFERENCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTNXSEARCHPATHSPREFERENCE"))
  'int)

(deftest "sysvar-importnxsearchpathspreference-getvar-default"
  '((operator . "IMPORTNXSEARCHPATHSPREFERENCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTNXSEARCHPATHSPREFERENCE")
  1)

(deftest "sysvar-importpmi-getvar-type"
  '((operator . "IMPORTPMI") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTPMI"))
  'int)

(deftest "sysvar-importpmi-getvar-default"
  '((operator . "IMPORTPMI") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTPMI")
  1)

(deftest "sysvar-importproductstructure-getvar-type"
  '((operator . "IMPORTPRODUCTSTRUCTURE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTPRODUCTSTRUCTURE"))
  'int)

(deftest "sysvar-importproductstructure-getvar-default"
  '((operator . "IMPORTPRODUCTSTRUCTURE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTPRODUCTSTRUCTURE")
  2)

(deftest "sysvar-importrepair-getvar-type"
  '((operator . "IMPORTREPAIR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTREPAIR"))
  'int)

(deftest "sysvar-importrepair-getvar-default"
  '((operator . "IMPORTREPAIR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTREPAIR")
  0)

(deftest "sysvar-importsimplify-getvar-type"
  '((operator . "IMPORTSIMPLIFY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTSIMPLIFY"))
  'int)

(deftest "sysvar-importsimplify-getvar-default"
  '((operator . "IMPORTSIMPLIFY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTSIMPLIFY")
  0)

(deftest "sysvar-importsolidedgealternatesearchpaths-getvar-type"
  '((operator . "IMPORTSOLIDEDGEALTERNATESEARCHPATHS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTSOLIDEDGEALTERNATESEARCHPATHS"))
  'str)

(deftest "sysvar-importsolidedgesearchpathspreference-getvar-type"
  '((operator . "IMPORTSOLIDEDGESEARCHPATHSPREFERENCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTSOLIDEDGESEARCHPATHSPREFERENCE"))
  'int)

(deftest "sysvar-importsolidedgesearchpathspreference-getvar-default"
  '((operator . "IMPORTSOLIDEDGESEARCHPATHSPREFERENCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTSOLIDEDGESEARCHPATHSPREFERENCE")
  1)

(deftest "sysvar-importsolidworksalternatesearchpaths-getvar-type"
  '((operator . "IMPORTSOLIDWORKSALTERNATESEARCHPATHS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTSOLIDWORKSALTERNATESEARCHPATHS"))
  'str)

(deftest "sysvar-importsolidworksconfiguration-getvar-type"
  '((operator . "IMPORTSOLIDWORKSCONFIGURATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTSOLIDWORKSCONFIGURATION"))
  'str)

(deftest "sysvar-importsolidworksrepresentation-getvar-type"
  '((operator . "IMPORTSOLIDWORKSREPRESENTATION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "IMPORTSOLIDWORKSREPRESENTATION"))
  'int)

(deftest "sysvar-importsolidworksrepresentation-getvar-default"
  '((operator . "IMPORTSOLIDWORKSREPRESENTATION") (area . "sysvar") (profile . STRICT))
  '(getvar "IMPORTSOLIDWORKSREPRESENTATION")
  1)

(deftest "sysvar-importsolidworksrotateyz-getvar-type"
  '((operator . "IMPORTSOLIDWORKSROTATEYZ") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTSOLIDWORKSROTATEYZ"))
  'int)

(deftest "sysvar-importsolidworksrotateyz-getvar-default"
  '((operator . "IMPORTSOLIDWORKSROTATEYZ") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTSOLIDWORKSROTATEYZ")
  1)

(deftest "sysvar-importsolidworkssearchpathspreference-getvar-type"
  '((operator . "IMPORTSOLIDWORKSSEARCHPATHSPREFERENCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTSOLIDWORKSSEARCHPATHSPREFERENCE"))
  'int)

(deftest "sysvar-importsolidworkssearchpathspreference-getvar-default"
  '((operator . "IMPORTSOLIDWORKSSEARCHPATHSPREFERENCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTSOLIDWORKSSEARCHPATHSPREFERENCE")
  1)

(deftest "sysvar-importsteprotateyz-getvar-type"
  '((operator . "IMPORTSTEPROTATEYZ") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTSTEPROTATEYZ"))
  'int)

(deftest "sysvar-importsteprotateyz-getvar-default"
  '((operator . "IMPORTSTEPROTATEYZ") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTSTEPROTATEYZ")
  0)

(deftest "sysvar-importstitch-getvar-type"
  '((operator . "IMPORTSTITCH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "IMPORTSTITCH"))
  'int)

(deftest "sysvar-importstitch-getvar-default"
  '((operator . "IMPORTSTITCH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "IMPORTSTITCH")
  0)

(deftest "sysvar-includeplotstamp-getvar-type"
  '((operator . "INCLUDEPLOTSTAMP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "INCLUDEPLOTSTAMP"))
  'int)

(deftest "sysvar-includeplotstamp-getvar-default"
  '((operator . "INCLUDEPLOTSTAMP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "INCLUDEPLOTSTAMP")
  1)

(deftest "sysvar-indexctl-getvar-type"
  '((operator . "INDEXCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INDEXCTL"))
  'int)

(deftest "sysvar-inetlocation-getvar-type"
  '((operator . "INETLOCATION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INETLOCATION"))
  'str)

(deftest "sysvar-inputhistorymode-getvar-type"
  '((operator . "INPUTHISTORYMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INPUTHISTORYMODE"))
  'int)

(deftest "sysvar-inputhistorymode-getvar-default"
  '((operator . "INPUTHISTORYMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "INPUTHISTORYMODE")
  15)

(deftest "sysvar-inputsearchdelay-getvar-type"
  '((operator . "INPUTSEARCHDELAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INPUTSEARCHDELAY"))
  'int)

(deftest "sysvar-inputsearchdelay-getvar-default"
  '((operator . "INPUTSEARCHDELAY") (area . "sysvar") (profile . STRICT))
  '(getvar "INPUTSEARCHDELAY")
  300)

(deftest "sysvar-insbase-getvar-type"
  '((operator . "INSBASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INSBASE"))
  'list)

(deftest "sysvar-insname-getvar-type"
  '((operator . "INSNAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INSNAME"))
  'str)

(deftest "sysvar-insunits-getvar-type"
  '((operator . "INSUNITS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INSUNITS"))
  'int)

(deftest "sysvar-insunitsdefsource-getvar-type"
  '((operator . "INSUNITSDEFSOURCE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INSUNITSDEFSOURCE"))
  'int)

(deftest "sysvar-insunitsdeftarget-getvar-type"
  '((operator . "INSUNITSDEFTARGET") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INSUNITSDEFTARGET"))
  'int)

(deftest "sysvar-insunitsscaling-getvar-type"
  '((operator . "INSUNITSSCALING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "INSUNITSSCALING"))
  'int)

(deftest "sysvar-insunitsscaling-getvar-default"
  '((operator . "INSUNITSSCALING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "INSUNITSSCALING")
  1)

(deftest "sysvar-intelligentupdate-getvar-type"
  '((operator . "INTELLIGENTUPDATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INTELLIGENTUPDATE"))
  'int)

(deftest "sysvar-intelligentupdate-getvar-default"
  '((operator . "INTELLIGENTUPDATE") (area . "sysvar") (profile . STRICT))
  '(getvar "INTELLIGENTUPDATE")
  20)

(deftest "sysvar-interferecolor-getvar-type"
  '((operator . "INTERFERECOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INTERFERECOLOR"))
  'str)

(deftest "sysvar-interferelayer-getvar-type"
  '((operator . "INTERFERELAYER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "INTERFERELAYER"))
  'str)

(deftest "sysvar-interferelayer-getvar-default"
  '((operator . "INTERFERELAYER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "INTERFERELAYER")
  "\"Interferences\"")

(deftest "sysvar-interferencelevel-getvar-type"
  '((operator . "INTERFERENCELEVEL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "INTERFERENCELEVEL"))
  'int)

(deftest "sysvar-interferencelevel-getvar-default"
  '((operator . "INTERFERENCELEVEL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "INTERFERENCELEVEL")
  0)

(deftest "sysvar-interfereobjvs-getvar-type"
  '((operator . "INTERFEREOBJVS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INTERFEREOBJVS"))
  'str)

(deftest "sysvar-interfereobjvs-getvar-default"
  '((operator . "INTERFEREOBJVS") (area . "sysvar") (profile . STRICT))
  '(getvar "INTERFEREOBJVS")
  "Realistic")

(deftest "sysvar-interferevpvs-getvar-type"
  '((operator . "INTERFEREVPVS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INTERFEREVPVS"))
  'str)

(deftest "sysvar-interferevpvs-getvar-default"
  '((operator . "INTERFEREVPVS") (area . "sysvar") (profile . STRICT))
  '(getvar "INTERFEREVPVS")
  "Wireframe")

(deftest "sysvar-interiorelevationminlength-getvar-type"
  '((operator . "INTERIORELEVATIONMINLENGTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "INTERIORELEVATIONMINLENGTH"))
  'real)

(deftest "sysvar-interiorelevationoffset-getvar-type"
  '((operator . "INTERIORELEVATIONOFFSET") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "INTERIORELEVATIONOFFSET"))
  'real)

(deftest "sysvar-intersectedentities-getvar-type"
  '((operator . "INTERSECTEDENTITIES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "INTERSECTEDENTITIES"))
  'int)

(deftest "sysvar-intersectioncolor-getvar-type"
  '((operator . "INTERSECTIONCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INTERSECTIONCOLOR"))
  'int)

(deftest "sysvar-intersectiondisplay-getvar-type"
  '((operator . "INTERSECTIONDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "INTERSECTIONDISPLAY"))
  'int)

(deftest "sysvar-intersectiondisplay-getvar-default"
  '((operator . "INTERSECTIONDISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "INTERSECTIONDISPLAY")
  0)

(deftest "sysvar-isavebak-getvar-type"
  '((operator . "ISAVEBAK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ISAVEBAK"))
  'int)

(deftest "sysvar-isavebak-getvar-default"
  '((operator . "ISAVEBAK") (area . "sysvar") (profile . STRICT))
  '(getvar "ISAVEBAK")
  1)

(deftest "sysvar-isavepercent-getvar-type"
  '((operator . "ISAVEPERCENT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ISAVEPERCENT"))
  'int)

(deftest "sysvar-isolines-getvar-type"
  '((operator . "ISOLINES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ISOLINES"))
  'int)

(deftest "sysvar-jigzoommax-getvar-type"
  '((operator . "JIGZOOMMAX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "JIGZOOMMAX"))
  'int)

(deftest "sysvar-jigzoommax-getvar-default"
  '((operator . "JIGZOOMMAX") (area . "sysvar") (profile . STRICT))
  '(getvar "JIGZOOMMAX")
  0)

(deftest "sysvar-jigzoommin-getvar-type"
  '((operator . "JIGZOOMMIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "JIGZOOMMIN"))
  'int)

(deftest "sysvar-jigzoommin-getvar-default"
  '((operator . "JIGZOOMMIN") (area . "sysvar") (profile . STRICT))
  '(getvar "JIGZOOMMIN")
  0)

(deftest "sysvar-keepconnections-getvar-type"
  '((operator . "KEEPCONNECTIONS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "KEEPCONNECTIONS"))
  'int)

(deftest "sysvar-keepconnections-getvar-default"
  '((operator . "KEEPCONNECTIONS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "KEEPCONNECTIONS")
  1)

(deftest "sysvar-largeobjectsupport-getvar-type"
  '((operator . "LARGEOBJECTSUPPORT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LARGEOBJECTSUPPORT"))
  'int)

(deftest "sysvar-largeobjectsupport-getvar-default"
  '((operator . "LARGEOBJECTSUPPORT") (area . "sysvar") (profile . STRICT))
  '(getvar "LARGEOBJECTSUPPORT")
  0)

(deftest "sysvar-lastangle-getvar-type"
  '((operator . "LASTANGLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LASTANGLE"))
  'real)

(deftest-error "sysvar-lastangle-setvar-readonly-signals"
  '((operator . "LASTANGLE") (area . "sysvar") (profile . STRICT))
  '(setvar "LASTANGLE" 0.0)
  'sysvar-read-only)

(deftest "sysvar-lastpoint-getvar-type"
  '((operator . "LASTPOINT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LASTPOINT"))
  'list)

(deftest "sysvar-lastpoint-getvar-default"
  '((operator . "LASTPOINT") (area . "sysvar") (profile . STRICT))
  '(getvar "LASTPOINT")
  '(0.0 0.0 0.0))

(deftest "sysvar-lastprompt-getvar-type"
  '((operator . "LASTPROMPT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LASTPROMPT"))
  'str)

(deftest-error "sysvar-lastprompt-setvar-readonly-signals"
  '((operator . "LASTPROMPT") (area . "sysvar") (profile . STRICT))
  '(setvar "LASTPROMPT" "")
  'sysvar-read-only)

(deftest "sysvar-latitude-getvar-type"
  '((operator . "LATITUDE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LATITUDE"))
  'real)

(deftest "sysvar-layerdlgmode-getvar-type"
  '((operator . "LAYERDLGMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYERDLGMODE"))
  'int)

(deftest "sysvar-layerdlgmode-getvar-default"
  '((operator . "LAYERDLGMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "LAYERDLGMODE")
  1)

(deftest "sysvar-layereval-getvar-type"
  '((operator . "LAYEREVAL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYEREVAL"))
  'int)

(deftest "sysvar-layereval-getvar-default"
  '((operator . "LAYEREVAL") (area . "sysvar") (profile . STRICT))
  '(getvar "LAYEREVAL")
  0)

(deftest "sysvar-layerevalctl-getvar-type"
  '((operator . "LAYEREVALCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYEREVALCTL"))
  'int)

(deftest "sysvar-layerevalctl-getvar-default"
  '((operator . "LAYEREVALCTL") (area . "sysvar") (profile . STRICT))
  '(getvar "LAYEREVALCTL")
  1)

(deftest "sysvar-layerfilteralert-getvar-type"
  '((operator . "LAYERFILTERALERT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYERFILTERALERT"))
  'int)

(deftest "sysvar-layerfilteralert-getvar-default"
  '((operator . "LAYERFILTERALERT") (area . "sysvar") (profile . STRICT))
  '(getvar "LAYERFILTERALERT")
  2)

(deftest "sysvar-layerfilterexcess-getvar-type"
  '((operator . "LAYERFILTEREXCESS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LAYERFILTEREXCESS"))
  'int)

(deftest "sysvar-layerfilterexcess-getvar-default"
  '((operator . "LAYERFILTEREXCESS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "LAYERFILTEREXCESS")
  250)

(deftest "sysvar-layermanagerstate-getvar-type"
  '((operator . "LAYERMANAGERSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYERMANAGERSTATE"))
  'int)

(deftest-error "sysvar-layermanagerstate-setvar-readonly-signals"
  '((operator . "LAYERMANAGERSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "LAYERMANAGERSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-layernotify-getvar-type"
  '((operator . "LAYERNOTIFY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYERNOTIFY"))
  'int)

(deftest "sysvar-layernotify-getvar-default"
  '((operator . "LAYERNOTIFY") (area . "sysvar") (profile . STRICT))
  '(getvar "LAYERNOTIFY")
  0)

(deftest "sysvar-layeroverridehighlight-getvar-type"
  '((operator . "LAYEROVERRIDEHIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYEROVERRIDEHIGHLIGHT"))
  'int)

(deftest "sysvar-layeroverridehighlight-getvar-default"
  '((operator . "LAYEROVERRIDEHIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "LAYEROVERRIDEHIGHLIGHT")
  0)

(deftest "sysvar-layerpmode-getvar-type"
  '((operator . "LAYERPMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYERPMODE"))
  'int)

(deftest "sysvar-laylockfadectl-getvar-type"
  '((operator . "LAYLOCKFADECTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYLOCKFADECTL"))
  'int)

(deftest "sysvar-layoutcreateviewport-getvar-type"
  '((operator . "LAYOUTCREATEVIEWPORT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYOUTCREATEVIEWPORT"))
  'int)

(deftest "sysvar-layoutcreateviewport-getvar-default"
  '((operator . "LAYOUTCREATEVIEWPORT") (area . "sysvar") (profile . STRICT))
  '(getvar "LAYOUTCREATEVIEWPORT")
  1)

(deftest "sysvar-layoutregenctl-getvar-type"
  '((operator . "LAYOUTREGENCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYOUTREGENCTL"))
  'int)

(deftest "sysvar-layouttab-getvar-type"
  '((operator . "LAYOUTTAB") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LAYOUTTAB"))
  'int)

(deftest "sysvar-layouttab-getvar-default"
  '((operator . "LAYOUTTAB") (area . "sysvar") (profile . STRICT))
  '(getvar "LAYOUTTAB")
  1)

(deftest "sysvar-legacycodesearch-getvar-type"
  '((operator . "LEGACYCODESEARCH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LEGACYCODESEARCH"))
  'int)

(deftest-error "sysvar-legacycodesearch-setvar-readonly-signals"
  '((operator . "LEGACYCODESEARCH") (area . "sysvar") (profile . STRICT))
  '(setvar "LEGACYCODESEARCH" 0)
  'sysvar-read-only)

(deftest "sysvar-legacyctrlpick-getvar-type"
  '((operator . "LEGACYCTRLPICK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LEGACYCTRLPICK"))
  'int)

(deftest "sysvar-legacyctrlpick-getvar-default"
  '((operator . "LEGACYCTRLPICK") (area . "sysvar") (profile . STRICT))
  '(getvar "LEGACYCTRLPICK")
  2)

(deftest "sysvar-lengthunits-getvar-type"
  '((operator . "LENGTHUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LENGTHUNITS"))
  'str)

(deftest "sysvar-lengthunits-getvar-default"
  '((operator . "LENGTHUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "LENGTHUNITS")
  "\"in ft mi µm mm cm m km\"")

(deftest "sysvar-lenslength-getvar-type"
  '((operator . "LENSLENGTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LENSLENGTH"))
  'real)

(deftest-error "sysvar-lenslength-setvar-readonly-signals"
  '((operator . "LENSLENGTH") (area . "sysvar") (profile . STRICT))
  '(setvar "LENSLENGTH" 0.0)
  'sysvar-read-only)

(deftest "sysvar-levelofdetail-getvar-type"
  '((operator . "LEVELOFDETAIL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LEVELOFDETAIL"))
  'int)

(deftest "sysvar-levelofdetail-getvar-default"
  '((operator . "LEVELOFDETAIL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "LEVELOFDETAIL")
  0)

(deftest "sysvar-licflags-getvar-type"
  '((operator . "LICFLAGS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LICFLAGS"))
  'int)

(deftest-error "sysvar-licflags-setvar-readonly-signals"
  '((operator . "LICFLAGS") (area . "sysvar") (profile . BRICSCAD))
  '(setvar "LICFLAGS" 0)
  'sysvar-read-only)

(deftest "sysvar-lightglyphcolor-getvar-type"
  '((operator . "LIGHTGLYPHCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LIGHTGLYPHCOLOR"))
  'int)

(deftest "sysvar-lightglyphcolor-getvar-default"
  '((operator . "LIGHTGLYPHCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "LIGHTGLYPHCOLOR")
  30)

(deftest "sysvar-lightglyphdisplay-getvar-type"
  '((operator . "LIGHTGLYPHDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LIGHTGLYPHDISPLAY"))
  'int)

(deftest "sysvar-lightglyphdisplay-getvar-default"
  '((operator . "LIGHTGLYPHDISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "LIGHTGLYPHDISPLAY")
  1)

(deftest "sysvar-lightingunits-getvar-type"
  '((operator . "LIGHTINGUNITS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LIGHTINGUNITS"))
  'int)

(deftest "sysvar-lightsinblocks-getvar-type"
  '((operator . "LIGHTSINBLOCKS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LIGHTSINBLOCKS"))
  'int)

(deftest "sysvar-lightsinblocks-getvar-default"
  '((operator . "LIGHTSINBLOCKS") (area . "sysvar") (profile . STRICT))
  '(getvar "LIGHTSINBLOCKS")
  1)

(deftest "sysvar-lightwebglyphcolor-getvar-type"
  '((operator . "LIGHTWEBGLYPHCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LIGHTWEBGLYPHCOLOR"))
  'int)

(deftest "sysvar-lightwebglyphcolor-getvar-default"
  '((operator . "LIGHTWEBGLYPHCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "LIGHTWEBGLYPHCOLOR")
  1)

(deftest "sysvar-limcheck-getvar-type"
  '((operator . "LIMCHECK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LIMCHECK"))
  'int)

(deftest "sysvar-limcheck-getvar-default"
  '((operator . "LIMCHECK") (area . "sysvar") (profile . STRICT))
  '(getvar "LIMCHECK")
  0)

(deftest "sysvar-limmax-getvar-type"
  '((operator . "LIMMAX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LIMMAX"))
  'list)

(deftest "sysvar-limmin-getvar-type"
  '((operator . "LIMMIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LIMMIN"))
  'list)

(deftest "sysvar-lineararrowheadlength-getvar-type"
  '((operator . "LINEARARROWHEADLENGTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LINEARARROWHEADLENGTH"))
  'real)

(deftest "sysvar-lineararrowheadwidth-getvar-type"
  '((operator . "LINEARARROWHEADWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LINEARARROWHEADWIDTH"))
  'real)

(deftest "sysvar-lineararrowthickness-getvar-type"
  '((operator . "LINEARARROWTHICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LINEARARROWTHICKNESS"))
  'real)

(deftest "sysvar-linearbrightness-getvar-type"
  '((operator . "LINEARBRIGHTNESS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LINEARBRIGHTNESS"))
  'int)

(deftest "sysvar-linearbrightness-getvar-default"
  '((operator . "LINEARBRIGHTNESS") (area . "sysvar") (profile . STRICT))
  '(getvar "LINEARBRIGHTNESS")
  0)

(deftest "sysvar-linearcontrast-getvar-type"
  '((operator . "LINEARCONTRAST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LINEARCONTRAST"))
  'int)

(deftest "sysvar-linearcontrast-getvar-default"
  '((operator . "LINEARCONTRAST") (area . "sysvar") (profile . STRICT))
  '(getvar "LINEARCONTRAST")
  0)

(deftest "sysvar-linefading-getvar-type"
  '((operator . "LINEFADING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LINEFADING"))
  'int)

(deftest "sysvar-linefading-getvar-default"
  '((operator . "LINEFADING") (area . "sysvar") (profile . STRICT))
  '(getvar "LINEFADING")
  1)

(deftest "sysvar-linefadinglevel-getvar-type"
  '((operator . "LINEFADINGLEVEL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LINEFADINGLEVEL"))
  'int)

(deftest "sysvar-linefadinglevel-getvar-default"
  '((operator . "LINEFADINGLEVEL") (area . "sysvar") (profile . STRICT))
  '(getvar "LINEFADINGLEVEL")
  2)

(deftest "sysvar-linetype3dpline-getvar-type"
  '((operator . "LINETYPE3DPLINE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LINETYPE3DPLINE"))
  'int)

(deftest "sysvar-linetype3dpline-getvar-default"
  '((operator . "LINETYPE3DPLINE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "LINETYPE3DPLINE")
  0)

(deftest "sysvar-lispinit-getvar-type"
  '((operator . "LISPINIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LISPINIT"))
  'int)

(deftest "sysvar-lispinit-getvar-default"
  '((operator . "LISPINIT") (area . "sysvar") (profile . STRICT))
  '(getvar "LISPINIT")
  1)

(deftest "sysvar-lispsys-getvar-type"
  '((operator . "LISPSYS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LISPSYS"))
  'int)

(deftest "sysvar-lispsys-getvar-default"
  '((operator . "LISPSYS") (area . "sysvar") (profile . STRICT))
  '(getvar "LISPSYS")
  1)

(deftest "sysvar-loadmechanical2d-getvar-type"
  '((operator . "LOADMECHANICAL2D") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LOADMECHANICAL2D"))
  'int)

(deftest "sysvar-loadmechanical2d-getvar-default"
  '((operator . "LOADMECHANICAL2D") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "LOADMECHANICAL2D")
  1)

(deftest "sysvar-locale-getvar-type"
  '((operator . "LOCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOCALE"))
  'str)

(deftest-error "sysvar-locale-setvar-readonly-signals"
  '((operator . "LOCALE") (area . "sysvar") (profile . STRICT))
  '(setvar "LOCALE" "")
  'sysvar-read-only)

(deftest "sysvar-localrootprefix-getvar-type"
  '((operator . "LOCALROOTPREFIX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOCALROOTPREFIX"))
  'str)

(deftest-error "sysvar-localrootprefix-setvar-readonly-signals"
  '((operator . "LOCALROOTPREFIX") (area . "sysvar") (profile . STRICT))
  '(setvar "LOCALROOTPREFIX" "")
  'sysvar-read-only)

(deftest "sysvar-lockui-getvar-type"
  '((operator . "LOCKUI") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOCKUI"))
  'int)

(deftest "sysvar-loftang1-getvar-type"
  '((operator . "LOFTANG1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOFTANG1"))
  'real)

(deftest "sysvar-loftang2-getvar-type"
  '((operator . "LOFTANG2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOFTANG2"))
  'real)

(deftest "sysvar-loftmag1-getvar-type"
  '((operator . "LOFTMAG1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOFTMAG1"))
  'real)

(deftest "sysvar-loftmag2-getvar-type"
  '((operator . "LOFTMAG2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOFTMAG2"))
  'real)

(deftest "sysvar-loftnormals-getvar-type"
  '((operator . "LOFTNORMALS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOFTNORMALS"))
  'int)

(deftest "sysvar-loftparam-getvar-type"
  '((operator . "LOFTPARAM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOFTPARAM"))
  'int)

(deftest "sysvar-logfilemode-getvar-type"
  '((operator . "LOGFILEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOGFILEMODE"))
  'int)

(deftest "sysvar-logfilemode-getvar-default"
  '((operator . "LOGFILEMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "LOGFILEMODE")
  0)

(deftest "sysvar-logfilename-getvar-type"
  '((operator . "LOGFILENAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOGFILENAME"))
  'str)

(deftest-error "sysvar-logfilename-setvar-readonly-signals"
  '((operator . "LOGFILENAME") (area . "sysvar") (profile . STRICT))
  '(setvar "LOGFILENAME" "")
  'sysvar-read-only)

(deftest "sysvar-logfilepath-getvar-type"
  '((operator . "LOGFILEPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOGFILEPATH"))
  'str)

(deftest "sysvar-loggedinstatus-getvar-type"
  '((operator . "LOGGEDINSTATUS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LOGGEDINSTATUS"))
  'int)

(deftest-error "sysvar-loggedinstatus-setvar-readonly-signals"
  '((operator . "LOGGEDINSTATUS") (area . "sysvar") (profile . BRICSCAD))
  '(setvar "LOGGEDINSTATUS" 0)
  'sysvar-read-only)

(deftest "sysvar-loginname-getvar-type"
  '((operator . "LOGINNAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LOGINNAME"))
  'str)

(deftest-error "sysvar-loginname-setvar-readonly-signals"
  '((operator . "LOGINNAME") (area . "sysvar") (profile . STRICT))
  '(setvar "LOGINNAME" "")
  'sysvar-read-only)

(deftest "sysvar-longitude-getvar-type"
  '((operator . "LONGITUDE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LONGITUDE"))
  'real)

(deftest "sysvar-lookfromdirectionmode-getvar-type"
  '((operator . "LOOKFROMDIRECTIONMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LOOKFROMDIRECTIONMODE"))
  'int)

(deftest "sysvar-lookfromdirectionmode-getvar-default"
  '((operator . "LOOKFROMDIRECTIONMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "LOOKFROMDIRECTIONMODE")
  1)

(deftest "sysvar-lookfromfeedback-getvar-type"
  '((operator . "LOOKFROMFEEDBACK") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LOOKFROMFEEDBACK"))
  'int)

(deftest "sysvar-lookfromfeedback-getvar-default"
  '((operator . "LOOKFROMFEEDBACK") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "LOOKFROMFEEDBACK")
  1)

(deftest "sysvar-lookfromzoomextents-getvar-type"
  '((operator . "LOOKFROMZOOMEXTENTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LOOKFROMZOOMEXTENTS"))
  'int)

(deftest "sysvar-ltgapselection-getvar-type"
  '((operator . "LTGAPSELECTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LTGAPSELECTION"))
  'int)

(deftest "sysvar-ltgapselection-getvar-default"
  '((operator . "LTGAPSELECTION") (area . "sysvar") (profile . STRICT))
  '(getvar "LTGAPSELECTION")
  1)

(deftest "sysvar-ltscale-getvar-type"
  '((operator . "LTSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LTSCALE"))
  'real)

(deftest "sysvar-lunits-getvar-type"
  '((operator . "LUNITS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LUNITS"))
  'int)

(deftest "sysvar-luprec-getvar-type"
  '((operator . "LUPREC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LUPREC"))
  'int)

(deftest "sysvar-lwdefault-getvar-type"
  '((operator . "LWDEFAULT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LWDEFAULT"))
  'int)

(deftest "sysvar-lwdisplay-getvar-type"
  '((operator . "LWDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LWDISPLAY"))
  'int)

(deftest "sysvar-lwdisplay-getvar-default"
  '((operator . "LWDISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "LWDISPLAY")
  0)

(deftest "sysvar-lwdispscale-getvar-type"
  '((operator . "LWDISPSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "LWDISPSCALE"))
  'real)

(deftest "sysvar-lwdispscale-getvar-default"
  '((operator . "LWDISPSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "LWDISPSCALE")
  0.55)

(deftest "sysvar-lwunits-getvar-type"
  '((operator . "LWUNITS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "LWUNITS"))
  'int)

(deftest "sysvar-macroinsightssupport-getvar-type"
  '((operator . "MACROINSIGHTSSUPPORT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MACROINSIGHTSSUPPORT"))
  'int)

(deftest "sysvar-macroinsightssupport-getvar-default"
  '((operator . "MACROINSIGHTSSUPPORT") (area . "sysvar") (profile . STRICT))
  '(getvar "MACROINSIGHTSSUPPORT")
  1)

(deftest "sysvar-macronotify-getvar-type"
  '((operator . "MACRONOTIFY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MACRONOTIFY"))
  'int)

(deftest "sysvar-macronotify-getvar-default"
  '((operator . "MACRONOTIFY") (area . "sysvar") (profile . STRICT))
  '(getvar "MACRONOTIFY")
  1)

(deftest "sysvar-macrorec-getvar-type"
  '((operator . "MACROREC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MACROREC"))
  'int)

(deftest "sysvar-macrorec-getvar-default"
  '((operator . "MACROREC") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MACROREC")
  0)

(deftest "sysvar-manipulator-getvar-type"
  '((operator . "MANIPULATOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MANIPULATOR"))
  'int)

(deftest "sysvar-manipulator-getvar-default"
  '((operator . "MANIPULATOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MANIPULATOR")
  2)

(deftest "sysvar-manipulatorcolortheme-getvar-type"
  '((operator . "MANIPULATORCOLORTHEME") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MANIPULATORCOLORTHEME"))
  'int)

(deftest "sysvar-manipulatorcolortheme-getvar-default"
  '((operator . "MANIPULATORCOLORTHEME") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MANIPULATORCOLORTHEME")
  1)

(deftest "sysvar-manipulatorduration-getvar-type"
  '((operator . "MANIPULATORDURATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MANIPULATORDURATION"))
  'int)

(deftest "sysvar-manipulatorduration-getvar-default"
  '((operator . "MANIPULATORDURATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MANIPULATORDURATION")
  250)

(deftest "sysvar-manipulatorhandle-getvar-type"
  '((operator . "MANIPULATORHANDLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MANIPULATORHANDLE"))
  'int)

(deftest "sysvar-manipulatorhandle-getvar-default"
  '((operator . "MANIPULATORHANDLE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MANIPULATORHANDLE")
  0)

(deftest "sysvar-manipulatorsize-getvar-type"
  '((operator . "MANIPULATORSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MANIPULATORSIZE"))
  'real)

(deftest "sysvar-manipulatorsize-getvar-default"
  '((operator . "MANIPULATORSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MANIPULATORSIZE")
  1.0)

(deftest "sysvar-markupassistmode-getvar-type"
  '((operator . "MARKUPASSISTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MARKUPASSISTMODE"))
  'int)

(deftest "sysvar-markupassistmode-getvar-default"
  '((operator . "MARKUPASSISTMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "MARKUPASSISTMODE")
  1)

(deftest "sysvar-markuppaperdisplay-getvar-type"
  '((operator . "MARKUPPAPERDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MARKUPPAPERDISPLAY"))
  'int)

(deftest "sysvar-markuppaperdisplay-getvar-default"
  '((operator . "MARKUPPAPERDISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "MARKUPPAPERDISPLAY")
  1)

(deftest "sysvar-markuppapertransparency-getvar-type"
  '((operator . "MARKUPPAPERTRANSPARENCY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MARKUPPAPERTRANSPARENCY"))
  'int)

(deftest "sysvar-markuppapertransparency-getvar-default"
  '((operator . "MARKUPPAPERTRANSPARENCY") (area . "sysvar") (profile . STRICT))
  '(getvar "MARKUPPAPERTRANSPARENCY")
  90)

(deftest "sysvar-markupselectionmode-getvar-type"
  '((operator . "MARKUPSELECTIONMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MARKUPSELECTIONMODE"))
  'int)

(deftest "sysvar-markupselectionmode-getvar-default"
  '((operator . "MARKUPSELECTIONMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "MARKUPSELECTIONMODE")
  1)

(deftest "sysvar-massprec-getvar-type"
  '((operator . "MASSPREC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MASSPREC"))
  'int)

(deftest "sysvar-massprec-getvar-default"
  '((operator . "MASSPREC") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MASSPREC")
  -1)

(deftest "sysvar-masspropaccuracy-getvar-type"
  '((operator . "MASSPROPACCURACY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MASSPROPACCURACY"))
  'int)

(deftest "sysvar-masspropaccuracy-getvar-default"
  '((operator . "MASSPROPACCURACY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MASSPROPACCURACY")
  2)

(deftest "sysvar-massunits-getvar-type"
  '((operator . "MASSUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MASSUNITS"))
  'str)

(deftest "sysvar-massunits-getvar-default"
  '((operator . "MASSUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MASSUNITS")
  "oz lb st mg g kg t")

(deftest "sysvar-matbrowserstate-getvar-type"
  '((operator . "MATBROWSERSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MATBROWSERSTATE"))
  'int)

(deftest-error "sysvar-matbrowserstate-setvar-readonly-signals"
  '((operator . "MATBROWSERSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "MATBROWSERSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-mateditorstate-getvar-type"
  '((operator . "MATEDITORSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MATEDITORSTATE"))
  'int)

(deftest-error "sysvar-mateditorstate-setvar-readonly-signals"
  '((operator . "MATEDITORSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "MATEDITORSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-maxactvp-getvar-type"
  '((operator . "MAXACTVP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MAXACTVP"))
  'int)

(deftest "sysvar-maxhatch-getvar-type"
  '((operator . "MAXHATCH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MAXHATCH"))
  'int)

(deftest "sysvar-maxhatch-getvar-default"
  '((operator . "MAXHATCH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MAXHATCH")
  100000)

(deftest "sysvar-maxintersectioncurvepoints-getvar-type"
  '((operator . "MAXINTERSECTIONCURVEPOINTS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MAXINTERSECTIONCURVEPOINTS"))
  'int)

(deftest "sysvar-maxintersectioncurvepoints-getvar-default"
  '((operator . "MAXINTERSECTIONCURVEPOINTS") (area . "sysvar") (profile . STRICT))
  '(getvar "MAXINTERSECTIONCURVEPOINTS")
  300)

(deftest "sysvar-maxsort-getvar-type"
  '((operator . "MAXSORT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MAXSORT"))
  'int)

(deftest "sysvar-maxthreads-getvar-type"
  '((operator . "MAXTHREADS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MAXTHREADS"))
  'int)

(deftest "sysvar-maxthreads-getvar-default"
  '((operator . "MAXTHREADS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MAXTHREADS")
  0)

(deftest "sysvar-mbstate-getvar-type"
  '((operator . "MBSTATE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MBSTATE"))
  'int)

(deftest-error "sysvar-mbstate-setvar-readonly-signals"
  '((operator . "MBSTATE") (area . "sysvar") (profile . BRICSCAD))
  '(setvar "MBSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-mbuttonpan-getvar-type"
  '((operator . "MBUTTONPAN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MBUTTONPAN"))
  'int)

(deftest "sysvar-measureinit-getvar-type"
  '((operator . "MEASUREINIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MEASUREINIT"))
  'int)

(deftest "sysvar-measurement-getvar-type"
  '((operator . "MEASUREMENT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MEASUREMENT"))
  'int)

(deftest "sysvar-mech2dsaveformat-getvar-type"
  '((operator . "MECH2DSAVEFORMAT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MECH2DSAVEFORMAT"))
  'int)

(deftest "sysvar-mech2dsaveformat-getvar-default"
  '((operator . "MECH2DSAVEFORMAT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MECH2DSAVEFORMAT")
  2022)

(deftest "sysvar-mechanicalblocks-getvar-type"
  '((operator . "MECHANICALBLOCKS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MECHANICALBLOCKS"))
  'int)

(deftest "sysvar-mechanicalblocks-getvar-default"
  '((operator . "MECHANICALBLOCKS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MECHANICALBLOCKS")
  1)

(deftest "sysvar-mechanicalblocksoptions-getvar-type"
  '((operator . "MECHANICALBLOCKSOPTIONS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MECHANICALBLOCKSOPTIONS"))
  'int)

(deftest "sysvar-mechanicalblocksoptions-getvar-default"
  '((operator . "MECHANICALBLOCKSOPTIONS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MECHANICALBLOCKSOPTIONS")
  0)

(deftest "sysvar-mechanicalbrowsersettings-getvar-type"
  '((operator . "MECHANICALBROWSERSETTINGS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MECHANICALBROWSERSETTINGS"))
  'int)

(deftest "sysvar-mechanicalbrowsersettings-getvar-default"
  '((operator . "MECHANICALBROWSERSETTINGS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MECHANICALBROWSERSETTINGS")
  179)

(deftest "sysvar-menubar-getvar-type"
  '((operator . "MENUBAR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MENUBAR"))
  'int)

(deftest "sysvar-menuctl-getvar-type"
  '((operator . "MENUCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MENUCTL"))
  'int)

(deftest "sysvar-menuctl-getvar-default"
  '((operator . "MENUCTL") (area . "sysvar") (profile . STRICT))
  '(getvar "MENUCTL")
  1)

(deftest "sysvar-menuecho-getvar-type"
  '((operator . "MENUECHO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MENUECHO"))
  'int)

(deftest "sysvar-menuname-getvar-type"
  '((operator . "MENUNAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MENUNAME"))
  'str)

(deftest-error "sysvar-menuname-setvar-readonly-signals"
  '((operator . "MENUNAME") (area . "sysvar") (profile . STRICT))
  '(setvar "MENUNAME" "")
  'sysvar-read-only)

(deftest "sysvar-meshtype-getvar-type"
  '((operator . "MESHTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MESHTYPE"))
  'int)

(deftest "sysvar-middleclickclose-getvar-type"
  '((operator . "MIDDLECLICKCLOSE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MIDDLECLICKCLOSE"))
  'int)

(deftest "sysvar-middleclickclose-getvar-default"
  '((operator . "MIDDLECLICKCLOSE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MIDDLECLICKCLOSE")
  1)

(deftest "sysvar-millisecs-getvar-type"
  '((operator . "MILLISECS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MILLISECS"))
  'int)

(deftest-error "sysvar-millisecs-setvar-readonly-signals"
  '((operator . "MILLISECS") (area . "sysvar") (profile . STRICT))
  '(setvar "MILLISECS" 0)
  'sysvar-read-only)

(deftest "sysvar-mirrhatch-getvar-type"
  '((operator . "MIRRHATCH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MIRRHATCH"))
  'int)

(deftest "sysvar-mirrhatch-getvar-default"
  '((operator . "MIRRHATCH") (area . "sysvar") (profile . STRICT))
  '(getvar "MIRRHATCH")
  0)

(deftest "sysvar-mirrtext-getvar-type"
  '((operator . "MIRRTEXT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MIRRTEXT"))
  'int)

(deftest "sysvar-mirrtext-getvar-default"
  '((operator . "MIRRTEXT") (area . "sysvar") (profile . STRICT))
  '(getvar "MIRRTEXT")
  0)

(deftest "sysvar-mleaderlayer-getvar-type"
  '((operator . "MLEADERLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MLEADERLAYER"))
  'str)

(deftest "sysvar-mleaderlayer-getvar-default"
  '((operator . "MLEADERLAYER") (area . "sysvar") (profile . STRICT))
  '(getvar "MLEADERLAYER")
  "use current")

(deftest "sysvar-mleaderscale-getvar-type"
  '((operator . "MLEADERSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MLEADERSCALE"))
  'real)

(deftest "sysvar-modemacro-getvar-type"
  '((operator . "MODEMACRO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MODEMACRO"))
  'str)

(deftest "sysvar-modemacro-getvar-default"
  '((operator . "MODEMACRO") (area . "sysvar") (profile . STRICT))
  '(getvar "MODEMACRO")
  "")

(deftest "sysvar-msltscale-getvar-type"
  '((operator . "MSLTSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MSLTSCALE"))
  'int)

(deftest "sysvar-msmstate-getvar-type"
  '((operator . "MSMSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MSMSTATE"))
  'int)

(deftest-error "sysvar-msmstate-setvar-readonly-signals"
  '((operator . "MSMSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "MSMSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-msolescale-getvar-type"
  '((operator . "MSOLESCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MSOLESCALE"))
  'real)

(deftest "sysvar-mtextautostack-getvar-type"
  '((operator . "MTEXTAUTOSTACK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MTEXTAUTOSTACK"))
  'int)

(deftest "sysvar-mtextautostack-getvar-default"
  '((operator . "MTEXTAUTOSTACK") (area . "sysvar") (profile . STRICT))
  '(getvar "MTEXTAUTOSTACK")
  1)

(deftest "sysvar-mtextcolumn-getvar-type"
  '((operator . "MTEXTCOLUMN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MTEXTCOLUMN"))
  'int)

(deftest "sysvar-mtextdetectspace-getvar-type"
  '((operator . "MTEXTDETECTSPACE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MTEXTDETECTSPACE"))
  'int)

(deftest "sysvar-mtextdetectspace-getvar-default"
  '((operator . "MTEXTDETECTSPACE") (area . "sysvar") (profile . STRICT))
  '(getvar "MTEXTDETECTSPACE")
  1)

(deftest "sysvar-mtexted-getvar-type"
  '((operator . "MTEXTED") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MTEXTED"))
  'str)

(deftest "sysvar-mtexted-getvar-default"
  '((operator . "MTEXTED") (area . "sysvar") (profile . STRICT))
  '(getvar "MTEXTED")
  "\"Internal\"")

(deftest "sysvar-mtextedencoding-getvar-type"
  '((operator . "MTEXTEDENCODING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MTEXTEDENCODING"))
  'int)

(deftest "sysvar-mtextedencoding-getvar-default"
  '((operator . "MTEXTEDENCODING") (area . "sysvar") (profile . STRICT))
  '(getvar "MTEXTEDENCODING")
  0)

(deftest "sysvar-mtextfixed-getvar-type"
  '((operator . "MTEXTFIXED") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MTEXTFIXED"))
  'int)

(deftest "sysvar-mtexttoolbar-getvar-type"
  '((operator . "MTEXTTOOLBAR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MTEXTTOOLBAR"))
  'int)

(deftest "sysvar-mtflags-getvar-type"
  '((operator . "MTFLAGS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MTFLAGS"))
  'int)

(deftest "sysvar-mtflags-getvar-default"
  '((operator . "MTFLAGS") (area . "sysvar") (profile . STRICT))
  '(getvar "MTFLAGS")
  3015)

(deftest "sysvar-mtjigstring-getvar-type"
  '((operator . "MTJIGSTRING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MTJIGSTRING"))
  'str)

(deftest "sysvar-mtjigstring-getvar-default"
  '((operator . "MTJIGSTRING") (area . "sysvar") (profile . STRICT))
  '(getvar "MTJIGSTRING")
  "\"abc\"")

(deftest "sysvar-multiselectangulartolerance-getvar-type"
  '((operator . "MULTISELECTANGULARTOLERANCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "MULTISELECTANGULARTOLERANCE"))
  'real)

(deftest "sysvar-multiselectangulartolerance-getvar-default"
  '((operator . "MULTISELECTANGULARTOLERANCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "MULTISELECTANGULARTOLERANCE")
  3.0)

(deftest "sysvar-mviewpreview-getvar-type"
  '((operator . "MVIEWPREVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MVIEWPREVIEW"))
  'int)

(deftest "sysvar-mviewpreview-getvar-default"
  '((operator . "MVIEWPREVIEW") (area . "sysvar") (profile . STRICT))
  '(getvar "MVIEWPREVIEW")
  0)

(deftest "sysvar-mydocumentsprefix-getvar-type"
  '((operator . "MYDOCUMENTSPREFIX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "MYDOCUMENTSPREFIX"))
  'str)

(deftest-error "sysvar-mydocumentsprefix-setvar-readonly-signals"
  '((operator . "MYDOCUMENTSPREFIX") (area . "sysvar") (profile . STRICT))
  '(setvar "MYDOCUMENTSPREFIX" "")
  'sysvar-read-only)

(deftest "sysvar-navbardisplay-getvar-type"
  '((operator . "NAVBARDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVBARDISPLAY"))
  'int)

(deftest "sysvar-navbardisplay-getvar-default"
  '((operator . "NAVBARDISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "NAVBARDISPLAY")
  1)

(deftest "sysvar-navswheelmode-getvar-type"
  '((operator . "NAVSWHEELMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVSWHEELMODE"))
  'int)

(deftest "sysvar-navswheelmode-getvar-default"
  '((operator . "NAVSWHEELMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "NAVSWHEELMODE")
  2)

(deftest "sysvar-navswheelopacitybig-getvar-type"
  '((operator . "NAVSWHEELOPACITYBIG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVSWHEELOPACITYBIG"))
  'int)

(deftest "sysvar-navswheelopacitybig-getvar-default"
  '((operator . "NAVSWHEELOPACITYBIG") (area . "sysvar") (profile . STRICT))
  '(getvar "NAVSWHEELOPACITYBIG")
  50)

(deftest "sysvar-navswheelopacitymini-getvar-type"
  '((operator . "NAVSWHEELOPACITYMINI") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVSWHEELOPACITYMINI"))
  'int)

(deftest "sysvar-navswheelopacitymini-getvar-default"
  '((operator . "NAVSWHEELOPACITYMINI") (area . "sysvar") (profile . STRICT))
  '(getvar "NAVSWHEELOPACITYMINI")
  50)

(deftest "sysvar-navswheelsizebig-getvar-type"
  '((operator . "NAVSWHEELSIZEBIG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVSWHEELSIZEBIG"))
  'int)

(deftest "sysvar-navswheelsizebig-getvar-default"
  '((operator . "NAVSWHEELSIZEBIG") (area . "sysvar") (profile . STRICT))
  '(getvar "NAVSWHEELSIZEBIG")
  1)

(deftest "sysvar-navswheelsizemini-getvar-type"
  '((operator . "NAVSWHEELSIZEMINI") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVSWHEELSIZEMINI"))
  'int)

(deftest "sysvar-navswheelsizemini-getvar-default"
  '((operator . "NAVSWHEELSIZEMINI") (area . "sysvar") (profile . STRICT))
  '(getvar "NAVSWHEELSIZEMINI")
  1)

(deftest "sysvar-navvcubedisplay-getvar-type"
  '((operator . "NAVVCUBEDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVVCUBEDISPLAY"))
  'int)

(deftest "sysvar-navvcubelocation-getvar-type"
  '((operator . "NAVVCUBELOCATION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVVCUBELOCATION"))
  'int)

(deftest "sysvar-navvcubeopacity-getvar-type"
  '((operator . "NAVVCUBEOPACITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVVCUBEOPACITY"))
  'int)

(deftest "sysvar-navvcubeorient-getvar-type"
  '((operator . "NAVVCUBEORIENT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVVCUBEORIENT"))
  'int)

(deftest "sysvar-navvcubesize-getvar-type"
  '((operator . "NAVVCUBESIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NAVVCUBESIZE"))
  'int)

(deftest "sysvar-navvcubesize-getvar-default"
  '((operator . "NAVVCUBESIZE") (area . "sysvar") (profile . STRICT))
  '(getvar "NAVVCUBESIZE")
  4)

(deftest "sysvar-nearestdistance-getvar-type"
  '((operator . "NEARESTDISTANCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "NEARESTDISTANCE"))
  'int)

(deftest "sysvar-nearestdistance-getvar-default"
  '((operator . "NEARESTDISTANCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "NEARESTDISTANCE")
  1)

(deftest "sysvar-nomutt-getvar-type"
  '((operator . "NOMUTT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NOMUTT"))
  'int)

(deftest "sysvar-nomutt-getvar-default"
  '((operator . "NOMUTT") (area . "sysvar") (profile . STRICT))
  '(getvar "NOMUTT")
  0)

(deftest "sysvar-northdirection-getvar-type"
  '((operator . "NORTHDIRECTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "NORTHDIRECTION"))
  'real)

(deftest "sysvar-objectisolationmode-getvar-type"
  '((operator . "OBJECTISOLATIONMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OBJECTISOLATIONMODE"))
  'int)

(deftest "sysvar-obscuredcolor-getvar-type"
  '((operator . "OBSCUREDCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OBSCUREDCOLOR"))
  'int)

(deftest "sysvar-obscuredltype-getvar-type"
  '((operator . "OBSCUREDLTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OBSCUREDLTYPE"))
  'int)

(deftest "sysvar-offsetdist-getvar-type"
  '((operator . "OFFSETDIST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OFFSETDIST"))
  'real)

(deftest "sysvar-offsetdist-getvar-default"
  '((operator . "OFFSETDIST") (area . "sysvar") (profile . STRICT))
  '(getvar "OFFSETDIST")
  -1.0)

(deftest "sysvar-offseterase-getvar-type"
  '((operator . "OFFSETERASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OFFSETERASE"))
  'int)

(deftest "sysvar-offsetgaptype-getvar-type"
  '((operator . "OFFSETGAPTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OFFSETGAPTYPE"))
  'int)

(deftest "sysvar-offsetgaptype-getvar-default"
  '((operator . "OFFSETGAPTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "OFFSETGAPTYPE")
  0)

(deftest "sysvar-oleframe-getvar-type"
  '((operator . "OLEFRAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OLEFRAME"))
  'int)

(deftest "sysvar-olehide-getvar-type"
  '((operator . "OLEHIDE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OLEHIDE"))
  'int)

(deftest "sysvar-olequality-getvar-type"
  '((operator . "OLEQUALITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OLEQUALITY"))
  'int)

(deftest "sysvar-olestartup-getvar-type"
  '((operator . "OLESTARTUP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OLESTARTUP"))
  'int)

(deftest "sysvar-olestartup-getvar-default"
  '((operator . "OLESTARTUP") (area . "sysvar") (profile . STRICT))
  '(getvar "OLESTARTUP")
  0)

(deftest "sysvar-opmstate-getvar-type"
  '((operator . "OPMSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OPMSTATE"))
  'int)

(deftest-error "sysvar-opmstate-setvar-readonly-signals"
  '((operator . "OPMSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "OPMSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-orbitautotarget-getvar-type"
  '((operator . "ORBITAUTOTARGET") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ORBITAUTOTARGET"))
  'int)

(deftest "sysvar-orthomode-getvar-type"
  '((operator . "ORTHOMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ORTHOMODE"))
  'int)

(deftest "sysvar-orthomode-getvar-default"
  '((operator . "ORTHOMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "ORTHOMODE")
  0)

(deftest "sysvar-osmode-getvar-type"
  '((operator . "OSMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OSMODE"))
  'int)

(deftest "sysvar-osnapcoord-getvar-type"
  '((operator . "OSNAPCOORD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OSNAPCOORD"))
  'int)

(deftest "sysvar-osnapnodelegacy-getvar-type"
  '((operator . "OSNAPNODELEGACY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OSNAPNODELEGACY"))
  'int)

(deftest "sysvar-osnapnodelegacy-getvar-default"
  '((operator . "OSNAPNODELEGACY") (area . "sysvar") (profile . STRICT))
  '(getvar "OSNAPNODELEGACY")
  0)

(deftest "sysvar-osnapoverride-getvar-type"
  '((operator . "OSNAPOVERRIDE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OSNAPOVERRIDE"))
  'int)

(deftest "sysvar-osnapoverride-getvar-default"
  '((operator . "OSNAPOVERRIDE") (area . "sysvar") (profile . STRICT))
  '(getvar "OSNAPOVERRIDE")
  0)

(deftest "sysvar-osnapz-getvar-type"
  '((operator . "OSNAPZ") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OSNAPZ"))
  'int)

(deftest "sysvar-osnapz-getvar-default"
  '((operator . "OSNAPZ") (area . "sysvar") (profile . STRICT))
  '(getvar "OSNAPZ")
  0)

(deftest "sysvar-osoptions-getvar-type"
  '((operator . "OSOPTIONS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "OSOPTIONS"))
  'int)

(deftest "sysvar-overkilllayer-getvar-type"
  '((operator . "OVERKILLLAYER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "OVERKILLLAYER"))
  'str)

(deftest "sysvar-overkilllayer-getvar-default"
  '((operator . "OVERKILLLAYER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "OVERKILLLAYER")
  "Duplicate Entities")

(deftest "sysvar-paletteopaque-getvar-type"
  '((operator . "PALETTEOPAQUE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PALETTEOPAQUE"))
  'int)

(deftest "sysvar-paletteopaque-getvar-default"
  '((operator . "PALETTEOPAQUE") (area . "sysvar") (profile . STRICT))
  '(getvar "PALETTEOPAQUE")
  0)

(deftest "sysvar-panbuffer-getvar-type"
  '((operator . "PANBUFFER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PANBUFFER"))
  'int)

(deftest "sysvar-panbuffer-getvar-default"
  '((operator . "PANBUFFER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PANBUFFER")
  1)

(deftest "sysvar-panelbuttonsize-getvar-type"
  '((operator . "PANELBUTTONSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PANELBUTTONSIZE"))
  'int)

(deftest "sysvar-panelbuttonsize-getvar-default"
  '((operator . "PANELBUTTONSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PANELBUTTONSIZE")
  1)

(deftest "sysvar-paperupdate-getvar-type"
  '((operator . "PAPERUPDATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PAPERUPDATE"))
  'int)

(deftest "sysvar-paperupdate-getvar-default"
  '((operator . "PAPERUPDATE") (area . "sysvar") (profile . STRICT))
  '(getvar "PAPERUPDATE")
  0)

(deftest "sysvar-parametercopymode-getvar-type"
  '((operator . "PARAMETERCOPYMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PARAMETERCOPYMODE"))
  'int)

(deftest "sysvar-parametermatchmode-getvar-type"
  '((operator . "PARAMETERMATCHMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PARAMETERMATCHMODE"))
  'int)

(deftest "sysvar-parametermatchmode-getvar-default"
  '((operator . "PARAMETERMATCHMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PARAMETERMATCHMODE")
  0)

(deftest "sysvar-parametersstatus-getvar-type"
  '((operator . "PARAMETERSSTATUS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PARAMETERSSTATUS"))
  'int)

(deftest-error "sysvar-parametersstatus-setvar-readonly-signals"
  '((operator . "PARAMETERSSTATUS") (area . "sysvar") (profile . STRICT))
  '(setvar "PARAMETERSSTATUS" 0)
  'sysvar-read-only)

(deftest "sysvar-parametricblocks2dpath-getvar-type"
  '((operator . "PARAMETRICBLOCKS2DPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PARAMETRICBLOCKS2DPATH"))
  'str)

(deftest "sysvar-parametrizeconnections-getvar-type"
  '((operator . "PARAMETRIZECONNECTIONS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PARAMETRIZECONNECTIONS"))
  'int)

(deftest "sysvar-parametrizeconnections-getvar-default"
  '((operator . "PARAMETRIZECONNECTIONS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PARAMETRIZECONNECTIONS")
  1)

(deftest "sysvar-pastespecmode-getvar-type"
  '((operator . "PASTESPECMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PASTESPECMODE"))
  'int)

(deftest "sysvar-pastespecmode-getvar-default"
  '((operator . "PASTESPECMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "PASTESPECMODE")
  0)

(deftest "sysvar-pblockreferenceoperationsvisualization-getvar-type"
  '((operator . "PBLOCKREFERENCEOPERATIONSVISUALIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PBLOCKREFERENCEOPERATIONSVISUALIZATION"))
  'int)

(deftest "sysvar-pblockreferenceoperationsvisualization-getvar-default"
  '((operator . "PBLOCKREFERENCEOPERATIONSVISUALIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PBLOCKREFERENCEOPERATIONSVISUALIZATION")
  0)

(deftest "sysvar-pcmstate-getvar-type"
  '((operator . "PCMSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PCMSTATE"))
  'int)

(deftest-error "sysvar-pcmstate-setvar-readonly-signals"
  '((operator . "PCMSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "PCMSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-pdfanimationfps-getvar-type"
  '((operator . "PDFANIMATIONFPS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFANIMATIONFPS"))
  'int)

(deftest "sysvar-pdfanimationfps-getvar-default"
  '((operator . "PDFANIMATIONFPS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFANIMATIONFPS")
  24)

(deftest "sysvar-pdfcache-getvar-type"
  '((operator . "PDFCACHE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFCACHE"))
  'int)

(deftest "sysvar-pdfcreatebookmarks-getvar-type"
  '((operator . "PDFCREATEBOOKMARKS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFCREATEBOOKMARKS"))
  'int)

(deftest "sysvar-pdfcreatebookmarks-getvar-default"
  '((operator . "PDFCREATEBOOKMARKS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFCREATEBOOKMARKS")
  1)

(deftest "sysvar-pdfembeddedttf-getvar-type"
  '((operator . "PDFEMBEDDEDTTF") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFEMBEDDEDTTF"))
  'int)

(deftest "sysvar-pdfembeddedttf-getvar-default"
  '((operator . "PDFEMBEDDEDTTF") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFEMBEDDEDTTF")
  1)

(deftest "sysvar-pdfexporthyperlinks-getvar-type"
  '((operator . "PDFEXPORTHYPERLINKS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFEXPORTHYPERLINKS"))
  'int)

(deftest "sysvar-pdfexporthyperlinks-getvar-default"
  '((operator . "PDFEXPORTHYPERLINKS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFEXPORTHYPERLINKS")
  1)

(deftest "sysvar-pdfframe-getvar-type"
  '((operator . "PDFFRAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDFFRAME"))
  'int)

(deftest "sysvar-pdfimageantialias-getvar-type"
  '((operator . "PDFIMAGEANTIALIAS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMAGEANTIALIAS"))
  'int)

(deftest "sysvar-pdfimageantialias-getvar-default"
  '((operator . "PDFIMAGEANTIALIAS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMAGEANTIALIAS")
  1)

(deftest "sysvar-pdfimagecompression-getvar-type"
  '((operator . "PDFIMAGECOMPRESSION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMAGECOMPRESSION"))
  'int)

(deftest "sysvar-pdfimagecompression-getvar-default"
  '((operator . "PDFIMAGECOMPRESSION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMAGECOMPRESSION")
  1)

(deftest "sysvar-pdfimagedpi-getvar-type"
  '((operator . "PDFIMAGEDPI") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMAGEDPI"))
  'int)

(deftest "sysvar-pdfimagedpi-getvar-default"
  '((operator . "PDFIMAGEDPI") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMAGEDPI")
  300)

(deftest "sysvar-pdfimportapplylineweight-getvar-type"
  '((operator . "PDFIMPORTAPPLYLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTAPPLYLINEWEIGHT"))
  'int)

(deftest "sysvar-pdfimportapplylineweight-getvar-default"
  '((operator . "PDFIMPORTAPPLYLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTAPPLYLINEWEIGHT")
  1)

(deftest "sysvar-pdfimportasblock-getvar-type"
  '((operator . "PDFIMPORTASBLOCK") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTASBLOCK"))
  'int)

(deftest "sysvar-pdfimportasblock-getvar-default"
  '((operator . "PDFIMPORTASBLOCK") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTASBLOCK")
  0)

(deftest "sysvar-pdfimportcharspacefactor-getvar-type"
  '((operator . "PDFIMPORTCHARSPACEFACTOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTCHARSPACEFACTOR"))
  'real)

(deftest "sysvar-pdfimportcharspacefactor-getvar-default"
  '((operator . "PDFIMPORTCHARSPACEFACTOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTCHARSPACEFACTOR")
  0.6)

(deftest "sysvar-pdfimportcombinetextobjects-getvar-type"
  '((operator . "PDFIMPORTCOMBINETEXTOBJECTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTCOMBINETEXTOBJECTS"))
  'int)

(deftest "sysvar-pdfimportcombinetextobjects-getvar-default"
  '((operator . "PDFIMPORTCOMBINETEXTOBJECTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTCOMBINETEXTOBJECTS")
  0)

(deftest "sysvar-pdfimportconvertsolidstohatches-getvar-type"
  '((operator . "PDFIMPORTCONVERTSOLIDSTOHATCHES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTCONVERTSOLIDSTOHATCHES"))
  'int)

(deftest "sysvar-pdfimportconvertsolidstohatches-getvar-default"
  '((operator . "PDFIMPORTCONVERTSOLIDSTOHATCHES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTCONVERTSOLIDSTOHATCHES")
  0)

(deftest "sysvar-pdfimportfilter-getvar-type"
  '((operator . "PDFIMPORTFILTER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDFIMPORTFILTER"))
  'int)

(deftest "sysvar-pdfimportfilter-getvar-default"
  '((operator . "PDFIMPORTFILTER") (area . "sysvar") (profile . STRICT))
  '(getvar "PDFIMPORTFILTER")
  8)

(deftest "sysvar-pdfimportimagepath-getvar-type"
  '((operator . "PDFIMPORTIMAGEPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDFIMPORTIMAGEPATH"))
  'str)

(deftest "sysvar-pdfimportjoinlineandarcsegments-getvar-type"
  '((operator . "PDFIMPORTJOINLINEANDARCSEGMENTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTJOINLINEANDARCSEGMENTS"))
  'int)

(deftest "sysvar-pdfimportlayers-getvar-type"
  '((operator . "PDFIMPORTLAYERS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDFIMPORTLAYERS"))
  'int)

(deftest "sysvar-pdfimportlayers-getvar-default"
  '((operator . "PDFIMPORTLAYERS") (area . "sysvar") (profile . STRICT))
  '(getvar "PDFIMPORTLAYERS")
  0)

(deftest "sysvar-pdfimportlayersusetype-getvar-type"
  '((operator . "PDFIMPORTLAYERSUSETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTLAYERSUSETYPE"))
  'int)

(deftest "sysvar-pdfimportlayersusetype-getvar-default"
  '((operator . "PDFIMPORTLAYERSUSETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTLAYERSUSETYPE")
  0)

(deftest "sysvar-pdfimportmode-getvar-type"
  '((operator . "PDFIMPORTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDFIMPORTMODE"))
  'int)

(deftest "sysvar-pdfimportmode-getvar-default"
  '((operator . "PDFIMPORTMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "PDFIMPORTMODE")
  6)

(deftest "sysvar-pdfimportrasterimages-getvar-type"
  '((operator . "PDFIMPORTRASTERIMAGES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTRASTERIMAGES"))
  'int)

(deftest "sysvar-pdfimportsolidfills-getvar-type"
  '((operator . "PDFIMPORTSOLIDFILLS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTSOLIDFILLS"))
  'int)

(deftest "sysvar-pdfimportsolidfills-getvar-default"
  '((operator . "PDFIMPORTSOLIDFILLS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTSOLIDFILLS")
  1)

(deftest "sysvar-pdfimportspacefactor-getvar-type"
  '((operator . "PDFIMPORTSPACEFACTOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTSPACEFACTOR"))
  'real)

(deftest "sysvar-pdfimportspacefactor-getvar-default"
  '((operator . "PDFIMPORTSPACEFACTOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTSPACEFACTOR")
  1.5)

(deftest "sysvar-pdfimporttruetypetext-getvar-type"
  '((operator . "PDFIMPORTTRUETYPETEXT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTTRUETYPETEXT"))
  'int)

(deftest "sysvar-pdfimporttruetypetext-getvar-default"
  '((operator . "PDFIMPORTTRUETYPETEXT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTTRUETYPETEXT")
  1)

(deftest "sysvar-pdfimporttruetypetextasgeometry-getvar-type"
  '((operator . "PDFIMPORTTRUETYPETEXTASGEOMETRY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTTRUETYPETEXTASGEOMETRY"))
  'int)

(deftest "sysvar-pdfimporttruetypetextasgeometry-getvar-default"
  '((operator . "PDFIMPORTTRUETYPETEXTASGEOMETRY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTTRUETYPETEXTASGEOMETRY")
  0)

(deftest "sysvar-pdfimportuseclipping-getvar-type"
  '((operator . "PDFIMPORTUSECLIPPING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTUSECLIPPING"))
  'int)

(deftest "sysvar-pdfimportuseclipping-getvar-default"
  '((operator . "PDFIMPORTUSECLIPPING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTUSECLIPPING")
  0)

(deftest "sysvar-pdfimportusegeometryoptimization-getvar-type"
  '((operator . "PDFIMPORTUSEGEOMETRYOPTIMIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTUSEGEOMETRYOPTIMIZATION"))
  'int)

(deftest "sysvar-pdfimportusegeometryoptimization-getvar-default"
  '((operator . "PDFIMPORTUSEGEOMETRYOPTIMIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTUSEGEOMETRYOPTIMIZATION")
  1)

(deftest "sysvar-pdfimportuseimageclipping-getvar-type"
  '((operator . "PDFIMPORTUSEIMAGECLIPPING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTUSEIMAGECLIPPING"))
  'int)

(deftest "sysvar-pdfimportuseimageclipping-getvar-default"
  '((operator . "PDFIMPORTUSEIMAGECLIPPING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTUSEIMAGECLIPPING")
  0)

(deftest "sysvar-pdfimportusepageborderclipping-getvar-type"
  '((operator . "PDFIMPORTUSEPAGEBORDERCLIPPING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTUSEPAGEBORDERCLIPPING"))
  'int)

(deftest "sysvar-pdfimportusepageborderclipping-getvar-default"
  '((operator . "PDFIMPORTUSEPAGEBORDERCLIPPING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTUSEPAGEBORDERCLIPPING")
  0)

(deftest "sysvar-pdfimportvectorgeometry-getvar-type"
  '((operator . "PDFIMPORTVECTORGEOMETRY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFIMPORTVECTORGEOMETRY"))
  'int)

(deftest "sysvar-pdfimportvectorgeometry-getvar-default"
  '((operator . "PDFIMPORTVECTORGEOMETRY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFIMPORTVECTORGEOMETRY")
  1)

(deftest "sysvar-pdflayerssetting-getvar-type"
  '((operator . "PDFLAYERSSETTING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFLAYERSSETTING"))
  'int)

(deftest "sysvar-pdflayerssetting-getvar-default"
  '((operator . "PDFLAYERSSETTING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFLAYERSSETTING")
  1)

(deftest "sysvar-pdflayoutstoexport-getvar-type"
  '((operator . "PDFLAYOUTSTOEXPORT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFLAYOUTSTOEXPORT"))
  'int)

(deftest "sysvar-pdflayoutstoexport-getvar-default"
  '((operator . "PDFLAYOUTSTOEXPORT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFLAYOUTSTOEXPORT")
  0)

(deftest "sysvar-pdfmergecontrol-getvar-type"
  '((operator . "PDFMERGECONTROL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFMERGECONTROL"))
  'int)

(deftest "sysvar-pdfmergecontrol-getvar-default"
  '((operator . "PDFMERGECONTROL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFMERGECONTROL")
  0)

(deftest "sysvar-pdfnotify-getvar-type"
  '((operator . "PDFNOTIFY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFNOTIFY"))
  'int)

(deftest "sysvar-pdfnotify-getvar-default"
  '((operator . "PDFNOTIFY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFNOTIFY")
  0)

(deftest "sysvar-pdfopeninviewer-getvar-type"
  '((operator . "PDFOPENINVIEWER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFOPENINVIEWER"))
  'str)

(deftest "sysvar-pdfosnap-getvar-type"
  '((operator . "PDFOSNAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDFOSNAP"))
  'int)

(deftest "sysvar-pdfosnap-getvar-default"
  '((operator . "PDFOSNAP") (area . "sysvar") (profile . STRICT))
  '(getvar "PDFOSNAP")
  1)

(deftest "sysvar-pdfpaperheight-getvar-type"
  '((operator . "PDFPAPERHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFPAPERHEIGHT"))
  'int)

(deftest "sysvar-pdfpaperheight-getvar-default"
  '((operator . "PDFPAPERHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFPAPERHEIGHT")
  297)

(deftest "sysvar-pdfpapersizeoverride-getvar-type"
  '((operator . "PDFPAPERSIZEOVERRIDE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFPAPERSIZEOVERRIDE"))
  'int)

(deftest "sysvar-pdfpapersizeoverride-getvar-default"
  '((operator . "PDFPAPERSIZEOVERRIDE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFPAPERSIZEOVERRIDE")
  0)

(deftest "sysvar-pdfpaperwidth-getvar-type"
  '((operator . "PDFPAPERWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFPAPERWIDTH"))
  'int)

(deftest "sysvar-pdfpaperwidth-getvar-default"
  '((operator . "PDFPAPERWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFPAPERWIDTH")
  210)

(deftest "sysvar-pdfpdfa-getvar-type"
  '((operator . "PDFPDFA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFPDFA"))
  'int)

(deftest "sysvar-pdfpdfa-getvar-default"
  '((operator . "PDFPDFA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFPDFA")
  0)

(deftest "sysvar-pdfprccompression-getvar-type"
  '((operator . "PDFPRCCOMPRESSION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFPRCCOMPRESSION"))
  'int)

(deftest "sysvar-pdfprccompression-getvar-default"
  '((operator . "PDFPRCCOMPRESSION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFPRCCOMPRESSION")
  0)

(deftest "sysvar-pdfprcexport-getvar-type"
  '((operator . "PDFPRCEXPORT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFPRCEXPORT"))
  'int)

(deftest "sysvar-pdfprcexport-getvar-default"
  '((operator . "PDFPRCEXPORT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFPRCEXPORT")
  0)

(deftest "sysvar-pdfprcprojection-getvar-type"
  '((operator . "PDFPRCPROJECTION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFPRCPROJECTION"))
  'int)

(deftest "sysvar-pdfprcprojection-getvar-default"
  '((operator . "PDFPRCPROJECTION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFPRCPROJECTION")
  0)

(deftest "sysvar-pdfprcviewmode-getvar-type"
  '((operator . "PDFPRCVIEWMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFPRCVIEWMODE"))
  'int)

(deftest "sysvar-pdfprcviewmode-getvar-default"
  '((operator . "PDFPRCVIEWMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFPRCVIEWMODE")
  0)

(deftest "sysvar-pdfshx-getvar-type"
  '((operator . "PDFSHX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDFSHX"))
  'int)

(deftest "sysvar-pdfshx-getvar-default"
  '((operator . "PDFSHX") (area . "sysvar") (profile . STRICT))
  '(getvar "PDFSHX")
  1)

(deftest "sysvar-pdfshxbestfont-getvar-type"
  '((operator . "PDFSHXBESTFONT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDFSHXBESTFONT"))
  'int)

(deftest "sysvar-pdfshxbestfont-getvar-default"
  '((operator . "PDFSHXBESTFONT") (area . "sysvar") (profile . STRICT))
  '(getvar "PDFSHXBESTFONT")
  0)

(deftest "sysvar-pdfshxlayer-getvar-type"
  '((operator . "PDFSHXLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDFSHXLAYER"))
  'int)

(deftest "sysvar-pdfshxlayer-getvar-default"
  '((operator . "PDFSHXLAYER") (area . "sysvar") (profile . STRICT))
  '(getvar "PDFSHXLAYER")
  1)

(deftest "sysvar-pdfshxtextasgeometry-getvar-type"
  '((operator . "PDFSHXTEXTASGEOMETRY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFSHXTEXTASGEOMETRY"))
  'int)

(deftest "sysvar-pdfshxtextasgeometry-getvar-default"
  '((operator . "PDFSHXTEXTASGEOMETRY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFSHXTEXTASGEOMETRY")
  0)

(deftest "sysvar-pdfshxthreshold-getvar-type"
  '((operator . "PDFSHXTHRESHOLD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDFSHXTHRESHOLD"))
  'int)

(deftest "sysvar-pdfshxthreshold-getvar-default"
  '((operator . "PDFSHXTHRESHOLD") (area . "sysvar") (profile . STRICT))
  '(getvar "PDFSHXTHRESHOLD")
  95)

(deftest "sysvar-pdfsimplegeomoptimization-getvar-type"
  '((operator . "PDFSIMPLEGEOMOPTIMIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFSIMPLEGEOMOPTIMIZATION"))
  'int)

(deftest "sysvar-pdfsimplegeomoptimization-getvar-default"
  '((operator . "PDFSIMPLEGEOMOPTIMIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFSIMPLEGEOMOPTIMIZATION")
  1)

(deftest "sysvar-pdfttftextasgeometry-getvar-type"
  '((operator . "PDFTTFTEXTASGEOMETRY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFTTFTEXTASGEOMETRY"))
  'int)

(deftest "sysvar-pdfttftextasgeometry-getvar-default"
  '((operator . "PDFTTFTEXTASGEOMETRY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFTTFTEXTASGEOMETRY")
  0)

(deftest "sysvar-pdfuseplotstyles-getvar-type"
  '((operator . "PDFUSEPLOTSTYLES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFUSEPLOTSTYLES"))
  'int)

(deftest "sysvar-pdfuseplotstyles-getvar-default"
  '((operator . "PDFUSEPLOTSTYLES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFUSEPLOTSTYLES")
  1)

(deftest "sysvar-pdfvectorresolutiondpi-getvar-type"
  '((operator . "PDFVECTORRESOLUTIONDPI") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFVECTORRESOLUTIONDPI"))
  'int)

(deftest "sysvar-pdfvectorresolutiondpi-getvar-default"
  '((operator . "PDFVECTORRESOLUTIONDPI") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFVECTORRESOLUTIONDPI")
  2400)

(deftest "sysvar-pdfzoomtoextentsmode-getvar-type"
  '((operator . "PDFZOOMTOEXTENTSMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PDFZOOMTOEXTENTSMODE"))
  'int)

(deftest "sysvar-pdfzoomtoextentsmode-getvar-default"
  '((operator . "PDFZOOMTOEXTENTSMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PDFZOOMTOEXTENTSMODE")
  1)

(deftest "sysvar-pdmode-getvar-type"
  '((operator . "PDMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDMODE"))
  'int)

(deftest "sysvar-pdsize-getvar-type"
  '((operator . "PDSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PDSIZE"))
  'real)

(deftest "sysvar-peditaccept-getvar-type"
  '((operator . "PEDITACCEPT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PEDITACCEPT"))
  'int)

(deftest "sysvar-peditaccept-getvar-default"
  '((operator . "PEDITACCEPT") (area . "sysvar") (profile . STRICT))
  '(getvar "PEDITACCEPT")
  0)

(deftest "sysvar-pellipse-getvar-type"
  '((operator . "PELLIPSE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PELLIPSE"))
  'int)

(deftest "sysvar-pellipse-getvar-default"
  '((operator . "PELLIPSE") (area . "sysvar") (profile . STRICT))
  '(getvar "PELLIPSE")
  0)

(deftest "sysvar-perimeter-getvar-type"
  '((operator . "PERIMETER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PERIMETER"))
  'real)

(deftest-error "sysvar-perimeter-setvar-readonly-signals"
  '((operator . "PERIMETER") (area . "sysvar") (profile . STRICT))
  '(setvar "PERIMETER" 0.0)
  'sysvar-read-only)

(deftest "sysvar-perspective-getvar-type"
  '((operator . "PERSPECTIVE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PERSPECTIVE"))
  'int)

(deftest "sysvar-perspectiveclip-getvar-type"
  '((operator . "PERSPECTIVECLIP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PERSPECTIVECLIP"))
  'real)

(deftest "sysvar-perspectiveclip-getvar-default"
  '((operator . "PERSPECTIVECLIP") (area . "sysvar") (profile . STRICT))
  '(getvar "PERSPECTIVECLIP")
  5.0)

(deftest "sysvar-pfacevmax-getvar-type"
  '((operator . "PFACEVMAX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PFACEVMAX"))
  'int)

(deftest-error "sysvar-pfacevmax-setvar-readonly-signals"
  '((operator . "PFACEVMAX") (area . "sysvar") (profile . STRICT))
  '(setvar "PFACEVMAX" 0)
  'sysvar-read-only)

(deftest "sysvar-pickadd-getvar-type"
  '((operator . "PICKADD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PICKADD"))
  'int)

(deftest "sysvar-pickauto-getvar-type"
  '((operator . "PICKAUTO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PICKAUTO"))
  'int)

(deftest "sysvar-pickbox-getvar-type"
  '((operator . "PICKBOX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PICKBOX"))
  'int)

(deftest "sysvar-pickdrag-getvar-type"
  '((operator . "PICKDRAG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PICKDRAG"))
  'int)

(deftest "sysvar-pickfirst-getvar-type"
  '((operator . "PICKFIRST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PICKFIRST"))
  'int)

(deftest "sysvar-pickfirst-getvar-default"
  '((operator . "PICKFIRST") (area . "sysvar") (profile . STRICT))
  '(getvar "PICKFIRST")
  1)

(deftest "sysvar-pickstyle-getvar-type"
  '((operator . "PICKSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PICKSTYLE"))
  'int)

(deftest "sysvar-pictureexportscale-getvar-type"
  '((operator . "PICTUREEXPORTSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PICTUREEXPORTSCALE"))
  'real)

(deftest "sysvar-pictureexportscale-getvar-default"
  '((operator . "PICTUREEXPORTSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PICTUREEXPORTSCALE")
  1.0)

(deftest "sysvar-placementswitch-getvar-type"
  '((operator . "PLACEMENTSWITCH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLACEMENTSWITCH"))
  'int)

(deftest "sysvar-placementswitch-getvar-default"
  '((operator . "PLACEMENTSWITCH") (area . "sysvar") (profile . STRICT))
  '(getvar "PLACEMENTSWITCH")
  1)

(deftest "sysvar-placesbarfolder1-getvar-type"
  '((operator . "PLACESBARFOLDER1") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PLACESBARFOLDER1"))
  'int)

(deftest "sysvar-placesbarfolder1-getvar-default"
  '((operator . "PLACESBARFOLDER1") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PLACESBARFOLDER1")
  0)

(deftest "sysvar-placesbarfolder2-getvar-type"
  '((operator . "PLACESBARFOLDER2") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PLACESBARFOLDER2"))
  'int)

(deftest "sysvar-placesbarfolder2-getvar-default"
  '((operator . "PLACESBARFOLDER2") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PLACESBARFOLDER2")
  1)

(deftest "sysvar-placesbarfolder3-getvar-type"
  '((operator . "PLACESBARFOLDER3") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PLACESBARFOLDER3"))
  'int)

(deftest "sysvar-placesbarfolder3-getvar-default"
  '((operator . "PLACESBARFOLDER3") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PLACESBARFOLDER3")
  3)

(deftest "sysvar-placesbarfolder4-getvar-type"
  '((operator . "PLACESBARFOLDER4") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PLACESBARFOLDER4"))
  'int)

(deftest "sysvar-placesbarfolder4-getvar-default"
  '((operator . "PLACESBARFOLDER4") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PLACESBARFOLDER4")
  5)

(deftest "sysvar-platform-getvar-type"
  '((operator . "PLATFORM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLATFORM"))
  'str)

(deftest-error "sysvar-platform-setvar-readonly-signals"
  '((operator . "PLATFORM") (area . "sysvar") (profile . STRICT))
  '(setvar "PLATFORM" "")
  'sysvar-read-only)

(deftest "sysvar-plinecache-getvar-type"
  '((operator . "PLINECACHE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PLINECACHE"))
  'int)

(deftest "sysvar-plinecache-getvar-default"
  '((operator . "PLINECACHE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PLINECACHE")
  0)

(deftest "sysvar-plineconvertmode-getvar-type"
  '((operator . "PLINECONVERTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLINECONVERTMODE"))
  'int)

(deftest "sysvar-plinegcenmax-getvar-type"
  '((operator . "PLINEGCENMAX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLINEGCENMAX"))
  'int)

(deftest "sysvar-plinegcenmax-getvar-default"
  '((operator . "PLINEGCENMAX") (area . "sysvar") (profile . STRICT))
  '(getvar "PLINEGCENMAX")
  50000)

(deftest "sysvar-plinegen-getvar-type"
  '((operator . "PLINEGEN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLINEGEN"))
  'int)

(deftest "sysvar-plinegen-getvar-default"
  '((operator . "PLINEGEN") (area . "sysvar") (profile . STRICT))
  '(getvar "PLINEGEN")
  0)

(deftest "sysvar-plinereversewidths-getvar-type"
  '((operator . "PLINEREVERSEWIDTHS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLINEREVERSEWIDTHS"))
  'int)

(deftest "sysvar-plinereversewidths-getvar-default"
  '((operator . "PLINEREVERSEWIDTHS") (area . "sysvar") (profile . STRICT))
  '(getvar "PLINEREVERSEWIDTHS")
  0)

(deftest "sysvar-plinetype-getvar-type"
  '((operator . "PLINETYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLINETYPE"))
  'int)

(deftest "sysvar-plinewid-getvar-type"
  '((operator . "PLINEWID") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLINEWID"))
  'real)

(deftest "sysvar-plotcfgpath-getvar-type"
  '((operator . "PLOTCFGPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PLOTCFGPATH"))
  'str)

(deftest "sysvar-plotid-getvar-type"
  '((operator . "PLOTID") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLOTID"))
  'str)

(deftest "sysvar-plotoffset-getvar-type"
  '((operator . "PLOTOFFSET") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLOTOFFSET"))
  'int)

(deftest "sysvar-plotoffset-getvar-default"
  '((operator . "PLOTOFFSET") (area . "sysvar") (profile . STRICT))
  '(getvar "PLOTOFFSET")
  0)

(deftest "sysvar-plotoutputpath-getvar-type"
  '((operator . "PLOTOUTPUTPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PLOTOUTPUTPATH"))
  'str)

(deftest "sysvar-plotrotmode-getvar-type"
  '((operator . "PLOTROTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLOTROTMODE"))
  'int)

(deftest "sysvar-plotrotmode-getvar-default"
  '((operator . "PLOTROTMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "PLOTROTMODE")
  2)

(deftest "sysvar-plotstylepath-getvar-type"
  '((operator . "PLOTSTYLEPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PLOTSTYLEPATH"))
  'str)

(deftest "sysvar-plotter-getvar-type"
  '((operator . "PLOTTER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLOTTER"))
  'int)

(deftest "sysvar-plottransparencyoverride-getvar-type"
  '((operator . "PLOTTRANSPARENCYOVERRIDE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLOTTRANSPARENCYOVERRIDE"))
  'int)

(deftest "sysvar-plquiet-getvar-type"
  '((operator . "PLQUIET") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PLQUIET"))
  'int)

(deftest "sysvar-plquiet-getvar-default"
  '((operator . "PLQUIET") (area . "sysvar") (profile . STRICT))
  '(getvar "PLQUIET")
  0)

(deftest "sysvar-pointcloud2dvsdisplay-getvar-type"
  '((operator . "POINTCLOUD2DVSDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUD2DVSDISPLAY"))
  'int)

(deftest "sysvar-pointcloudadaptivedisplay-getvar-type"
  '((operator . "POINTCLOUDADAPTIVEDISPLAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "POINTCLOUDADAPTIVEDISPLAY"))
  'int)

(deftest "sysvar-pointcloudadaptivedisplay-getvar-default"
  '((operator . "POINTCLOUDADAPTIVEDISPLAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "POINTCLOUDADAPTIVEDISPLAY")
  0)

(deftest "sysvar-pointcloudautoupdate-getvar-type"
  '((operator . "POINTCLOUDAUTOUPDATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDAUTOUPDATE"))
  'int)

(deftest "sysvar-pointcloudautoupdate-getvar-default"
  '((operator . "POINTCLOUDAUTOUPDATE") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDAUTOUPDATE")
  1)

(deftest "sysvar-pointcloudboundary-getvar-type"
  '((operator . "POINTCLOUDBOUNDARY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDBOUNDARY"))
  'int)

(deftest "sysvar-pointcloudcachefolder-getvar-type"
  '((operator . "POINTCLOUDCACHEFOLDER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "POINTCLOUDCACHEFOLDER"))
  'str)

(deftest "sysvar-pointcloudcachefolder-getvar-default"
  '((operator . "POINTCLOUDCACHEFOLDER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "POINTCLOUDCACHEFOLDER")
  "C:\\Users\\%username%\\AppData\\Roaming\\Bricsys\\BricsCAD\\ V26 x64\\en_US\\PointCloudCache")

(deftest "sysvar-pointcloudcachesize-getvar-type"
  '((operator . "POINTCLOUDCACHESIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDCACHESIZE"))
  'int)

(deftest "sysvar-pointcloudcachesize-getvar-default"
  '((operator . "POINTCLOUDCACHESIZE") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDCACHESIZE")
  512)

(deftest "sysvar-pointcloudclipframe-getvar-type"
  '((operator . "POINTCLOUDCLIPFRAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDCLIPFRAME"))
  'int)

(deftest "sysvar-pointcloudclipframe-getvar-default"
  '((operator . "POINTCLOUDCLIPFRAME") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDCLIPFRAME")
  2)

(deftest "sysvar-pointclouddensity-getvar-type"
  '((operator . "POINTCLOUDDENSITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDDENSITY"))
  'int)

(deftest "sysvar-pointclouddensity-getvar-default"
  '((operator . "POINTCLOUDDENSITY") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDDENSITY")
  15)

(deftest "sysvar-pointclouddollhouse-getvar-type"
  '((operator . "POINTCLOUDDOLLHOUSE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "POINTCLOUDDOLLHOUSE"))
  'int)

(deftest "sysvar-pointclouddollhouse-getvar-default"
  '((operator . "POINTCLOUDDOLLHOUSE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "POINTCLOUDDOLLHOUSE")
  0)

(deftest "sysvar-pointcloudeyedomelighting-getvar-type"
  '((operator . "POINTCLOUDEYEDOMELIGHTING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "POINTCLOUDEYEDOMELIGHTING"))
  'str)

(deftest "sysvar-pointcloudgapfilling-getvar-type"
  '((operator . "POINTCLOUDGAPFILLING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "POINTCLOUDGAPFILLING"))
  'str)

(deftest "sysvar-pointcloudhspc-getvar-type"
  '((operator . "POINTCLOUDHSPC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "POINTCLOUDHSPC"))
  'int)

(deftest "sysvar-pointcloudhspc-getvar-default"
  '((operator . "POINTCLOUDHSPC") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "POINTCLOUDHSPC")
  1)

(deftest "sysvar-pointcloudignoregeotags-getvar-type"
  '((operator . "POINTCLOUDIGNOREGEOTAGS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "POINTCLOUDIGNOREGEOTAGS"))
  'int)

(deftest "sysvar-pointcloudignoregeotags-getvar-default"
  '((operator . "POINTCLOUDIGNOREGEOTAGS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "POINTCLOUDIGNOREGEOTAGS")
  1)

(deftest "sysvar-pointcloudlighting-getvar-type"
  '((operator . "POINTCLOUDLIGHTING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDLIGHTING"))
  'int)

(deftest "sysvar-pointcloudlighting-getvar-default"
  '((operator . "POINTCLOUDLIGHTING") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDLIGHTING")
  2)

(deftest "sysvar-pointcloudlightsource-getvar-type"
  '((operator . "POINTCLOUDLIGHTSOURCE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDLIGHTSOURCE"))
  'int)

(deftest "sysvar-pointcloudlightsource-getvar-default"
  '((operator . "POINTCLOUDLIGHTSOURCE") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDLIGHTSOURCE")
  0)

(deftest "sysvar-pointcloudlock-getvar-type"
  '((operator . "POINTCLOUDLOCK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDLOCK"))
  'int)

(deftest "sysvar-pointcloudlock-getvar-default"
  '((operator . "POINTCLOUDLOCK") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDLOCK")
  0)

(deftest "sysvar-pointcloudlod-getvar-type"
  '((operator . "POINTCLOUDLOD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDLOD"))
  'int)

(deftest "sysvar-pointcloudlod-getvar-default"
  '((operator . "POINTCLOUDLOD") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDLOD")
  10)

(deftest "sysvar-pointcloudnormals-getvar-type"
  '((operator . "POINTCLOUDNORMALS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "POINTCLOUDNORMALS"))
  'int)

(deftest "sysvar-pointcloudnormals-getvar-default"
  '((operator . "POINTCLOUDNORMALS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "POINTCLOUDNORMALS")
  1)

(deftest "sysvar-pointcloudpointmax-getvar-type"
  '((operator . "POINTCLOUDPOINTMAX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDPOINTMAX"))
  'int)

(deftest "sysvar-pointcloudpointmaxlegacy-getvar-type"
  '((operator . "POINTCLOUDPOINTMAXLEGACY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDPOINTMAXLEGACY"))
  'int)

(deftest "sysvar-pointcloudpointmaxlegacy-getvar-default"
  '((operator . "POINTCLOUDPOINTMAXLEGACY") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDPOINTMAXLEGACY")
  1)

(deftest "sysvar-pointcloudpointsize-getvar-type"
  '((operator . "POINTCLOUDPOINTSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDPOINTSIZE"))
  'int)

(deftest "sysvar-pointcloudrtdensity-getvar-type"
  '((operator . "POINTCLOUDRTDENSITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDRTDENSITY"))
  'int)

(deftest "sysvar-pointcloudrtdensity-getvar-default"
  '((operator . "POINTCLOUDRTDENSITY") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDRTDENSITY")
  5)

(deftest "sysvar-pointcloudshading-getvar-type"
  '((operator . "POINTCLOUDSHADING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDSHADING"))
  'int)

(deftest "sysvar-pointcloudshading-getvar-default"
  '((operator . "POINTCLOUDSHADING") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDSHADING")
  0)

(deftest "sysvar-pointcloudvisretain-getvar-type"
  '((operator . "POINTCLOUDVISRETAIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POINTCLOUDVISRETAIN"))
  'int)

(deftest "sysvar-pointcloudvisretain-getvar-default"
  '((operator . "POINTCLOUDVISRETAIN") (area . "sysvar") (profile . STRICT))
  '(getvar "POINTCLOUDVISRETAIN")
  1)

(deftest "sysvar-polaraddang-getvar-type"
  '((operator . "POLARADDANG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POLARADDANG"))
  'str)

(deftest "sysvar-polaraddang-getvar-default"
  '((operator . "POLARADDANG") (area . "sysvar") (profile . STRICT))
  '(getvar "POLARADDANG")
  "")

(deftest "sysvar-polarang-getvar-type"
  '((operator . "POLARANG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POLARANG"))
  'real)

(deftest "sysvar-polardist-getvar-type"
  '((operator . "POLARDIST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POLARDIST"))
  'real)

(deftest "sysvar-polarmode-getvar-type"
  '((operator . "POLARMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POLARMODE"))
  'int)

(deftest "sysvar-polysides-getvar-type"
  '((operator . "POLYSIDES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POLYSIDES"))
  'int)

(deftest "sysvar-polysides-getvar-default"
  '((operator . "POLYSIDES") (area . "sysvar") (profile . STRICT))
  '(getvar "POLYSIDES")
  4)

(deftest "sysvar-poperationscolor-getvar-type"
  '((operator . "POPERATIONSCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "POPERATIONSCOLOR"))
  'str)

(deftest "sysvar-poperationscolor-getvar-default"
  '((operator . "POPERATIONSCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "POPERATIONSCOLOR")
  "RGB:238,173,60")

(deftest "sysvar-popups-getvar-type"
  '((operator . "POPUPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "POPUPS"))
  'int)

(deftest-error "sysvar-popups-setvar-readonly-signals"
  '((operator . "POPUPS") (area . "sysvar") (profile . STRICT))
  '(setvar "POPUPS" 0)
  'sysvar-read-only)

(deftest "sysvar-previewcreationtransparency-getvar-type"
  '((operator . "PREVIEWCREATIONTRANSPARENCY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PREVIEWCREATIONTRANSPARENCY"))
  'int)

(deftest "sysvar-previewcreationtransparency-getvar-default"
  '((operator . "PREVIEWCREATIONTRANSPARENCY") (area . "sysvar") (profile . STRICT))
  '(getvar "PREVIEWCREATIONTRANSPARENCY")
  60)

(deftest "sysvar-previewdelay-getvar-type"
  '((operator . "PREVIEWDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PREVIEWDELAY"))
  'int)

(deftest "sysvar-previewdelay-getvar-default"
  '((operator . "PREVIEWDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PREVIEWDELAY")
  30)

(deftest "sysvar-previeweffect-getvar-type"
  '((operator . "PREVIEWEFFECT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PREVIEWEFFECT"))
  'int)

(deftest "sysvar-previeweffect-getvar-default"
  '((operator . "PREVIEWEFFECT") (area . "sysvar") (profile . STRICT))
  '(getvar "PREVIEWEFFECT")
  2)

(deftest "sysvar-previewfilter-getvar-type"
  '((operator . "PREVIEWFILTER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PREVIEWFILTER"))
  'int)

(deftest "sysvar-previewtype-getvar-type"
  '((operator . "PREVIEWTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PREVIEWTYPE"))
  'int)

(deftest "sysvar-previewwndinopendlg-getvar-type"
  '((operator . "PREVIEWWNDINOPENDLG") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PREVIEWWNDINOPENDLG"))
  'int)

(deftest "sysvar-printfile-getvar-type"
  '((operator . "PRINTFILE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PRINTFILE"))
  'str)

(deftest "sysvar-printfile-getvar-default"
  '((operator . "PRINTFILE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PRINTFILE")
  ".")

(deftest "sysvar-printpdfpreview-getvar-type"
  '((operator . "PRINTPDFPREVIEW") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PRINTPDFPREVIEW"))
  'int)

(deftest "sysvar-printpdfpreview-getvar-default"
  '((operator . "PRINTPDFPREVIEW") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PRINTPDFPREVIEW")
  1)

(deftest "sysvar-product-getvar-type"
  '((operator . "PRODUCT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PRODUCT"))
  'str)

(deftest-error "sysvar-product-setvar-readonly-signals"
  '((operator . "PRODUCT") (area . "sysvar") (profile . STRICT))
  '(setvar "PRODUCT" "")
  'sysvar-read-only)

(deftest "sysvar-profileoffsetbehavior-getvar-type"
  '((operator . "PROFILEOFFSETBEHAVIOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROFILEOFFSETBEHAVIOR"))
  'int)

(deftest "sysvar-profileoffsetbehavior-getvar-default"
  '((operator . "PROFILEOFFSETBEHAVIOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROFILEOFFSETBEHAVIOR")
  0)

(deftest "sysvar-progbar-getvar-type"
  '((operator . "PROGBAR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROGBAR"))
  'int)

(deftest "sysvar-progbar-getvar-default"
  '((operator . "PROGBAR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROGBAR")
  1)

(deftest "sysvar-program-getvar-type"
  '((operator . "PROGRAM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROGRAM"))
  'str)

(deftest-error "sysvar-program-setvar-readonly-signals"
  '((operator . "PROGRAM") (area . "sysvar") (profile . STRICT))
  '(setvar "PROGRAM" "")
  'sysvar-read-only)

(deftest "sysvar-projectaware-getvar-type"
  '((operator . "PROJECTAWARE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROJECTAWARE"))
  'int)

(deftest-error "sysvar-projectaware-setvar-readonly-signals"
  '((operator . "PROJECTAWARE") (area . "sysvar") (profile . STRICT))
  '(setvar "PROJECTAWARE" 0)
  'sysvar-read-only)

(deftest "sysvar-projectiontype-getvar-type"
  '((operator . "PROJECTIONTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROJECTIONTYPE"))
  'int)

(deftest "sysvar-projectiontype-getvar-default"
  '((operator . "PROJECTIONTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "PROJECTIONTYPE")
  0)

(deftest "sysvar-projectlocationvisibility-getvar-type"
  '((operator . "PROJECTLOCATIONVISIBILITY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROJECTLOCATIONVISIBILITY"))
  'int)

(deftest "sysvar-projectlocationvisibility-getvar-default"
  '((operator . "PROJECTLOCATIONVISIBILITY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROJECTLOCATIONVISIBILITY")
  1)

(deftest "sysvar-projectname-getvar-type"
  '((operator . "PROJECTNAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROJECTNAME"))
  'str)

(deftest "sysvar-projectname-getvar-default"
  '((operator . "PROJECTNAME") (area . "sysvar") (profile . STRICT))
  '(getvar "PROJECTNAME")
  "")

(deftest "sysvar-projectsearchpaths-getvar-type"
  '((operator . "PROJECTSEARCHPATHS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROJECTSEARCHPATHS"))
  'str)

(deftest "sysvar-projmode-getvar-type"
  '((operator . "PROJMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROJMODE"))
  'int)

(deftest "sysvar-promptmenu-getvar-type"
  '((operator . "PROMPTMENU") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROMPTMENU"))
  'int)

(deftest "sysvar-promptmenu-getvar-default"
  '((operator . "PROMPTMENU") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROMPTMENU")
  0)

(deftest "sysvar-promptmenuflags-getvar-type"
  '((operator . "PROMPTMENUFLAGS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROMPTMENUFLAGS"))
  'int)

(deftest "sysvar-promptmenuflags-getvar-default"
  '((operator . "PROMPTMENUFLAGS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROMPTMENUFLAGS")
  0)

(deftest "sysvar-promptoptionformat-getvar-type"
  '((operator . "PROMPTOPTIONFORMAT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROMPTOPTIONFORMAT"))
  'int)

(deftest "sysvar-promptoptionformat-getvar-default"
  '((operator . "PROMPTOPTIONFORMAT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROMPTOPTIONFORMAT")
  0)

(deftest "sysvar-promptoptiontranslatekeywords-getvar-type"
  '((operator . "PROMPTOPTIONTRANSLATEKEYWORDS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROMPTOPTIONTRANSLATEKEYWORDS"))
  'int)

(deftest "sysvar-promptoptiontranslatekeywords-getvar-default"
  '((operator . "PROMPTOPTIONTRANSLATEKEYWORDS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROMPTOPTIONTRANSLATEKEYWORDS")
  1)

(deftest "sysvar-propagatesearchspace-getvar-type"
  '((operator . "PROPAGATESEARCHSPACE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROPAGATESEARCHSPACE"))
  'int)

(deftest "sysvar-propagatesearchspace-getvar-default"
  '((operator . "PROPAGATESEARCHSPACE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROPAGATESEARCHSPACE")
  0)

(deftest "sysvar-propagatetolerance-getvar-type"
  '((operator . "PROPAGATETOLERANCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROPAGATETOLERANCE"))
  'real)

(deftest "sysvar-propagatetolerance-getvar-default"
  '((operator . "PROPAGATETOLERANCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROPAGATETOLERANCE")
  0.00001)

(deftest "sysvar-propertypreview-getvar-type"
  '((operator . "PROPERTYPREVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROPERTYPREVIEW"))
  'int)

(deftest "sysvar-propertypreview-getvar-default"
  '((operator . "PROPERTYPREVIEW") (area . "sysvar") (profile . STRICT))
  '(getvar "PROPERTYPREVIEW")
  1)

(deftest "sysvar-propertypreviewdelay-getvar-type"
  '((operator . "PROPERTYPREVIEWDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROPERTYPREVIEWDELAY"))
  'int)

(deftest "sysvar-propertypreviewdelay-getvar-default"
  '((operator . "PROPERTYPREVIEWDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROPERTYPREVIEWDELAY")
  500)

(deftest "sysvar-propertypreviewobjlimit-getvar-type"
  '((operator . "PROPERTYPREVIEWOBJLIMIT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROPERTYPREVIEWOBJLIMIT"))
  'int)

(deftest "sysvar-propertypreviewobjlimit-getvar-default"
  '((operator . "PROPERTYPREVIEWOBJLIMIT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROPERTYPREVIEWOBJLIMIT")
  500)

(deftest "sysvar-propobjlimit-getvar-type"
  '((operator . "PROPOBJLIMIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROPOBJLIMIT"))
  'int)

(deftest "sysvar-propprevtimeout-getvar-type"
  '((operator . "PROPPREVTIMEOUT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROPPREVTIMEOUT"))
  'int)

(deftest "sysvar-propunits-getvar-type"
  '((operator . "PROPUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROPUNITS"))
  'int)

(deftest "sysvar-propunits-getvar-default"
  '((operator . "PROPUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROPUNITS")
  47)

(deftest "sysvar-proxygraphics-getvar-type"
  '((operator . "PROXYGRAPHICS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROXYGRAPHICS"))
  'int)

(deftest "sysvar-proxygraphics-getvar-default"
  '((operator . "PROXYGRAPHICS") (area . "sysvar") (profile . STRICT))
  '(getvar "PROXYGRAPHICS")
  1)

(deftest "sysvar-proxynotice-getvar-type"
  '((operator . "PROXYNOTICE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROXYNOTICE"))
  'int)

(deftest "sysvar-proxynotice-getvar-default"
  '((operator . "PROXYNOTICE") (area . "sysvar") (profile . STRICT))
  '(getvar "PROXYNOTICE")
  1)

(deftest "sysvar-proxyserverenabled-getvar-type"
  '((operator . "PROXYSERVERENABLED") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROXYSERVERENABLED"))
  'int)

(deftest "sysvar-proxyserverenabled-getvar-default"
  '((operator . "PROXYSERVERENABLED") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "PROXYSERVERENABLED")
  0)

(deftest "sysvar-proxyserverhttp-getvar-type"
  '((operator . "PROXYSERVERHTTP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROXYSERVERHTTP"))
  'str)

(deftest "sysvar-proxyserverhttpport-getvar-type"
  '((operator . "PROXYSERVERHTTPPORT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROXYSERVERHTTPPORT"))
  'str)

(deftest "sysvar-proxyserverhttps-getvar-type"
  '((operator . "PROXYSERVERHTTPS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROXYSERVERHTTPS"))
  'str)

(deftest "sysvar-proxyserverhttpsport-getvar-type"
  '((operator . "PROXYSERVERHTTPSPORT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROXYSERVERHTTPSPORT"))
  'str)

(deftest "sysvar-proxyserverpassword-getvar-type"
  '((operator . "PROXYSERVERPASSWORD") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROXYSERVERPASSWORD"))
  'str)

(deftest "sysvar-proxyserveruser-getvar-type"
  '((operator . "PROXYSERVERUSER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "PROXYSERVERUSER"))
  'str)

(deftest "sysvar-proxyshow-getvar-type"
  '((operator . "PROXYSHOW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROXYSHOW"))
  'int)

(deftest "sysvar-proxywebsearch-getvar-type"
  '((operator . "PROXYWEBSEARCH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PROXYWEBSEARCH"))
  'int)

(deftest "sysvar-proxywebsearch-getvar-default"
  '((operator . "PROXYWEBSEARCH") (area . "sysvar") (profile . STRICT))
  '(getvar "PROXYWEBSEARCH")
  1)

(deftest "sysvar-psltscale-getvar-type"
  '((operator . "PSLTSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PSLTSCALE"))
  'int)

(deftest "sysvar-psolheight-getvar-type"
  '((operator . "PSOLHEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PSOLHEIGHT"))
  'real)

(deftest "sysvar-psolwidth-getvar-type"
  '((operator . "PSOLWIDTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PSOLWIDTH"))
  'real)

(deftest "sysvar-pstylemode-getvar-type"
  '((operator . "PSTYLEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PSTYLEMODE"))
  'int)

(deftest-error "sysvar-pstylemode-setvar-readonly-signals"
  '((operator . "PSTYLEMODE") (area . "sysvar") (profile . STRICT))
  '(setvar "PSTYLEMODE" 0)
  'sysvar-read-only)

(deftest "sysvar-pstylepolicy-getvar-type"
  '((operator . "PSTYLEPOLICY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PSTYLEPOLICY"))
  'int)

(deftest "sysvar-psvpscale-getvar-type"
  '((operator . "PSVPSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PSVPSCALE"))
  'real)

(deftest "sysvar-publishallsheets-getvar-type"
  '((operator . "PUBLISHALLSHEETS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PUBLISHALLSHEETS"))
  'int)

(deftest "sysvar-publishcollate-getvar-type"
  '((operator . "PUBLISHCOLLATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PUBLISHCOLLATE"))
  'int)

(deftest "sysvar-publishhatch-getvar-type"
  '((operator . "PUBLISHHATCH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PUBLISHHATCH"))
  'int)

(deftest "sysvar-publishhatch-getvar-default"
  '((operator . "PUBLISHHATCH") (area . "sysvar") (profile . STRICT))
  '(getvar "PUBLISHHATCH")
  1)

(deftest "sysvar-pucsbase-getvar-type"
  '((operator . "PUCSBASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PUCSBASE"))
  'str)

(deftest-error "sysvar-pucsbase-setvar-readonly-signals"
  '((operator . "PUCSBASE") (area . "sysvar") (profile . STRICT))
  '(setvar "PUCSBASE" "")
  'sysvar-read-only)

(deftest "sysvar-pushtodocsstate-getvar-type"
  '((operator . "PUSHTODOCSSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "PUSHTODOCSSTATE"))
  'int)

(deftest-error "sysvar-pushtodocsstate-setvar-readonly-signals"
  '((operator . "PUSHTODOCSSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "PUSHTODOCSSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-qaflags-getvar-type"
  '((operator . "QAFLAGS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "QAFLAGS"))
  'int)

(deftest "sysvar-qaflags-getvar-default"
  '((operator . "QAFLAGS") (area . "sysvar") (profile . STRICT))
  '(getvar "QAFLAGS")
  0)

(deftest "sysvar-qcstate-getvar-type"
  '((operator . "QCSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "QCSTATE"))
  'int)

(deftest-error "sysvar-qcstate-setvar-readonly-signals"
  '((operator . "QCSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "QCSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-qplocation-getvar-type"
  '((operator . "QPLOCATION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "QPLOCATION"))
  'int)

(deftest "sysvar-qplocation-getvar-default"
  '((operator . "QPLOCATION") (area . "sysvar") (profile . STRICT))
  '(getvar "QPLOCATION")
  0)

(deftest "sysvar-qpmode-getvar-type"
  '((operator . "QPMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "QPMODE"))
  'int)

(deftest "sysvar-qpmode-getvar-default"
  '((operator . "QPMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "QPMODE")
  -1)

(deftest "sysvar-qtextmode-getvar-type"
  '((operator . "QTEXTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "QTEXTMODE"))
  'int)

(deftest "sysvar-qtextmode-getvar-default"
  '((operator . "QTEXTMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "QTEXTMODE")
  0)

(deftest "sysvar-quadcommandlaunch-getvar-type"
  '((operator . "QUADCOMMANDLAUNCH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADCOMMANDLAUNCH"))
  'int)

(deftest "sysvar-quadcommandlaunch-getvar-default"
  '((operator . "QUADCOMMANDLAUNCH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADCOMMANDLAUNCH")
  0)

(deftest "sysvar-quaddisplay-getvar-type"
  '((operator . "QUADDISPLAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADDISPLAY"))
  'int)

(deftest "sysvar-quaddisplay-getvar-default"
  '((operator . "QUADDISPLAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADDISPLAY")
  3)

(deftest "sysvar-quadexpanddelay-getvar-type"
  '((operator . "QUADEXPANDDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADEXPANDDELAY"))
  'int)

(deftest "sysvar-quadexpanddelay-getvar-default"
  '((operator . "QUADEXPANDDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADEXPANDDELAY")
  160)

(deftest "sysvar-quadexpandtabdelay-getvar-type"
  '((operator . "QUADEXPANDTABDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADEXPANDTABDELAY"))
  'int)

(deftest "sysvar-quadexpandtabdelay-getvar-default"
  '((operator . "QUADEXPANDTABDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADEXPANDTABDELAY")
  50)

(deftest "sysvar-quadgotransparent-getvar-type"
  '((operator . "QUADGOTRANSPARENT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADGOTRANSPARENT"))
  'int)

(deftest "sysvar-quadgotransparent-getvar-default"
  '((operator . "QUADGOTRANSPARENT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADGOTRANSPARENT")
  0)

(deftest "sysvar-quadhidedelay-getvar-type"
  '((operator . "QUADHIDEDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADHIDEDELAY"))
  'int)

(deftest "sysvar-quadhidedelay-getvar-default"
  '((operator . "QUADHIDEDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADHIDEDELAY")
  350)

(deftest "sysvar-quadhidemargin-getvar-type"
  '((operator . "QUADHIDEMARGIN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADHIDEMARGIN"))
  'int)

(deftest "sysvar-quadhidemargin-getvar-default"
  '((operator . "QUADHIDEMARGIN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADHIDEMARGIN")
  50)

(deftest "sysvar-quadiconsize-getvar-type"
  '((operator . "QUADICONSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADICONSIZE"))
  'int)

(deftest "sysvar-quadiconsize-getvar-default"
  '((operator . "QUADICONSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADICONSIZE")
  1)

(deftest "sysvar-quadiconspace-getvar-type"
  '((operator . "QUADICONSPACE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADICONSPACE"))
  'int)

(deftest "sysvar-quadiconspace-getvar-default"
  '((operator . "QUADICONSPACE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADICONSPACE")
  1)

(deftest "sysvar-quadmostrecentitems-getvar-type"
  '((operator . "QUADMOSTRECENTITEMS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADMOSTRECENTITEMS"))
  'int)

(deftest "sysvar-quadmostrecentitems-getvar-default"
  '((operator . "QUADMOSTRECENTITEMS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADMOSTRECENTITEMS")
  4)

(deftest "sysvar-quadpopupcorner-getvar-type"
  '((operator . "QUADPOPUPCORNER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADPOPUPCORNER"))
  'int)

(deftest "sysvar-quadpopupcorner-getvar-default"
  '((operator . "QUADPOPUPCORNER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADPOPUPCORNER")
  1)

(deftest "sysvar-quadshowdelay-getvar-type"
  '((operator . "QUADSHOWDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADSHOWDELAY"))
  'int)

(deftest "sysvar-quadshowdelay-getvar-default"
  '((operator . "QUADSHOWDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADSHOWDELAY")
  150)

(deftest "sysvar-quadwidth-getvar-type"
  '((operator . "QUADWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "QUADWIDTH"))
  'int)

(deftest "sysvar-quadwidth-getvar-default"
  '((operator . "QUADWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "QUADWIDTH")
  6)

(deftest "sysvar-qvdrawingpin-getvar-type"
  '((operator . "QVDRAWINGPIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "QVDRAWINGPIN"))
  'int)

(deftest "sysvar-qvdrawingpin-getvar-default"
  '((operator . "QVDRAWINGPIN") (area . "sysvar") (profile . STRICT))
  '(getvar "QVDRAWINGPIN")
  0)

(deftest "sysvar-qvlayoutpin-getvar-type"
  '((operator . "QVLAYOUTPIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "QVLAYOUTPIN"))
  'int)

(deftest "sysvar-qvlayoutpin-getvar-default"
  '((operator . "QVLAYOUTPIN") (area . "sysvar") (profile . STRICT))
  '(getvar "QVLAYOUTPIN")
  0)

(deftest "sysvar-r12saveaccuracy-getvar-type"
  '((operator . "R12SAVEACCURACY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "R12SAVEACCURACY"))
  'int)

(deftest "sysvar-r12saveaccuracy-getvar-default"
  '((operator . "R12SAVEACCURACY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "R12SAVEACCURACY")
  8)

(deftest "sysvar-r12savedeviation-getvar-type"
  '((operator . "R12SAVEDEVIATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "R12SAVEDEVIATION"))
  'real)

(deftest "sysvar-r12savedeviation-getvar-default"
  '((operator . "R12SAVEDEVIATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "R12SAVEDEVIATION")
  0.0)

(deftest "sysvar-rasterdpi-getvar-type"
  '((operator . "RASTERDPI") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RASTERDPI"))
  'int)

(deftest "sysvar-rasterdpi-getvar-default"
  '((operator . "RASTERDPI") (area . "sysvar") (profile . STRICT))
  '(getvar "RASTERDPI")
  300)

(deftest "sysvar-rasterpercent-getvar-type"
  '((operator . "RASTERPERCENT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RASTERPERCENT"))
  'int)

(deftest "sysvar-rasterpercent-getvar-default"
  '((operator . "RASTERPERCENT") (area . "sysvar") (profile . STRICT))
  '(getvar "RASTERPERCENT")
  20)

(deftest "sysvar-rasterpreview-getvar-type"
  '((operator . "RASTERPREVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RASTERPREVIEW"))
  'int)

(deftest "sysvar-rasterpreview-getvar-default"
  '((operator . "RASTERPREVIEW") (area . "sysvar") (profile . STRICT))
  '(getvar "RASTERPREVIEW")
  1)

(deftest "sysvar-rasterthreshold-getvar-type"
  '((operator . "RASTERTHRESHOLD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RASTERTHRESHOLD"))
  'int)

(deftest "sysvar-rasterthreshold-getvar-default"
  '((operator . "RASTERTHRESHOLD") (area . "sysvar") (profile . STRICT))
  '(getvar "RASTERTHRESHOLD")
  20)

(deftest "sysvar-realtimespeedup-getvar-type"
  '((operator . "REALTIMESPEEDUP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REALTIMESPEEDUP"))
  'int)

(deftest "sysvar-realtimespeedup-getvar-default"
  '((operator . "REALTIMESPEEDUP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REALTIMESPEEDUP")
  5)

(deftest "sysvar-realworldscale-getvar-type"
  '((operator . "REALWORLDSCALE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REALWORLDSCALE"))
  'int)

(deftest "sysvar-realworldscale-getvar-default"
  '((operator . "REALWORLDSCALE") (area . "sysvar") (profile . STRICT))
  '(getvar "REALWORLDSCALE")
  1)

(deftest "sysvar-rebuild2dcv-getvar-type"
  '((operator . "REBUILD2DCV") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REBUILD2DCV"))
  'int)

(deftest "sysvar-rebuild2dcv-getvar-default"
  '((operator . "REBUILD2DCV") (area . "sysvar") (profile . STRICT))
  '(getvar "REBUILD2DCV")
  6)

(deftest "sysvar-rebuild2ddegree-getvar-type"
  '((operator . "REBUILD2DDEGREE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REBUILD2DDEGREE"))
  'int)

(deftest "sysvar-rebuild2ddegree-getvar-default"
  '((operator . "REBUILD2DDEGREE") (area . "sysvar") (profile . STRICT))
  '(getvar "REBUILD2DDEGREE")
  3)

(deftest "sysvar-rebuild2doption-getvar-type"
  '((operator . "REBUILD2DOPTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REBUILD2DOPTION"))
  'int)

(deftest "sysvar-rebuild2doption-getvar-default"
  '((operator . "REBUILD2DOPTION") (area . "sysvar") (profile . STRICT))
  '(getvar "REBUILD2DOPTION")
  1)

(deftest "sysvar-rebuilddegreeu-getvar-type"
  '((operator . "REBUILDDEGREEU") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REBUILDDEGREEU"))
  'int)

(deftest "sysvar-rebuilddegreeu-getvar-default"
  '((operator . "REBUILDDEGREEU") (area . "sysvar") (profile . STRICT))
  '(getvar "REBUILDDEGREEU")
  3)

(deftest "sysvar-rebuilddegreev-getvar-type"
  '((operator . "REBUILDDEGREEV") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REBUILDDEGREEV"))
  'int)

(deftest "sysvar-rebuilddegreev-getvar-default"
  '((operator . "REBUILDDEGREEV") (area . "sysvar") (profile . STRICT))
  '(getvar "REBUILDDEGREEV")
  3)

(deftest "sysvar-rebuildoptions-getvar-type"
  '((operator . "REBUILDOPTIONS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REBUILDOPTIONS"))
  'int)

(deftest "sysvar-rebuildoptions-getvar-default"
  '((operator . "REBUILDOPTIONS") (area . "sysvar") (profile . STRICT))
  '(getvar "REBUILDOPTIONS")
  1)

(deftest "sysvar-rebuildu-getvar-type"
  '((operator . "REBUILDU") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REBUILDU"))
  'int)

(deftest "sysvar-rebuildu-getvar-default"
  '((operator . "REBUILDU") (area . "sysvar") (profile . STRICT))
  '(getvar "REBUILDU")
  6)

(deftest "sysvar-rebuildv-getvar-type"
  '((operator . "REBUILDV") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REBUILDV"))
  'int)

(deftest "sysvar-rebuildv-getvar-default"
  '((operator . "REBUILDV") (area . "sysvar") (profile . STRICT))
  '(getvar "REBUILDV")
  6)

(deftest "sysvar-recentfiles-getvar-type"
  '((operator . "RECENTFILES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RECENTFILES"))
  'int)

(deftest "sysvar-recentfiles-getvar-default"
  '((operator . "RECENTFILES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RECENTFILES")
  30)

(deftest "sysvar-recentpath-getvar-type"
  '((operator . "RECENTPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RECENTPATH"))
  'str)

(deftest "sysvar-recoverauto-getvar-type"
  '((operator . "RECOVERAUTO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RECOVERAUTO"))
  'int)

(deftest "sysvar-recoverauto-getvar-default"
  '((operator . "RECOVERAUTO") (area . "sysvar") (profile . STRICT))
  '(getvar "RECOVERAUTO")
  0)

(deftest "sysvar-recoverymode-getvar-type"
  '((operator . "RECOVERYMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RECOVERYMODE"))
  'int)

(deftest "sysvar-recoverymode-getvar-default"
  '((operator . "RECOVERYMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "RECOVERYMODE")
  2)

(deftest "sysvar-redhilitefull_edge_alpha-getvar-type"
  '((operator . "REDHILITEFULL_EDGE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEFULL_EDGE_ALPHA"))
  'int)

(deftest "sysvar-redhilitefull_edge_alpha-getvar-default"
  '((operator . "REDHILITEFULL_EDGE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEFULL_EDGE_ALPHA")
  100)

(deftest "sysvar-redhilitefull_edge_color-getvar-type"
  '((operator . "REDHILITEFULL_EDGE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEFULL_EDGE_COLOR"))
  'str)

(deftest "sysvar-redhilitefull_edge_color-getvar-default"
  '((operator . "REDHILITEFULL_EDGE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEFULL_EDGE_COLOR")
  "0, 122, 255 (Settings dialog) #007AFF (Command line)")

(deftest "sysvar-redhilitefull_edge_showhidden-getvar-type"
  '((operator . "REDHILITEFULL_EDGE_SHOWHIDDEN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEFULL_EDGE_SHOWHIDDEN"))
  'int)

(deftest "sysvar-redhilitefull_edge_showhidden-getvar-default"
  '((operator . "REDHILITEFULL_EDGE_SHOWHIDDEN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEFULL_EDGE_SHOWHIDDEN")
  0)

(deftest "sysvar-redhilitefull_edge_smoothing-getvar-type"
  '((operator . "REDHILITEFULL_EDGE_SMOOTHING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEFULL_EDGE_SMOOTHING"))
  'int)

(deftest "sysvar-redhilitefull_edge_smoothing-getvar-default"
  '((operator . "REDHILITEFULL_EDGE_SMOOTHING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEFULL_EDGE_SMOOTHING")
  1)

(deftest "sysvar-redhilitefull_edge_thickness-getvar-type"
  '((operator . "REDHILITEFULL_EDGE_THICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEFULL_EDGE_THICKNESS"))
  'real)

(deftest "sysvar-redhilitefull_edge_thickness-getvar-default"
  '((operator . "REDHILITEFULL_EDGE_THICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEFULL_EDGE_THICKNESS")
  2.0)

(deftest "sysvar-redhilitefull_face_alpha-getvar-type"
  '((operator . "REDHILITEFULL_FACE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEFULL_FACE_ALPHA"))
  'int)

(deftest "sysvar-redhilitefull_face_alpha-getvar-default"
  '((operator . "REDHILITEFULL_FACE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEFULL_FACE_ALPHA")
  10)

(deftest "sysvar-redhilitefull_face_color-getvar-type"
  '((operator . "REDHILITEFULL_FACE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEFULL_FACE_COLOR"))
  'str)

(deftest "sysvar-redhilitepartial_selectededgeglow_alpha-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGEGLOW_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDEDGEGLOW_ALPHA"))
  'int)

(deftest "sysvar-redhilitepartial_selectededgeglow_alpha-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGEGLOW_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDEDGEGLOW_ALPHA")
  75)

(deftest "sysvar-redhilitepartial_selectededgeglow_color-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGEGLOW_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDEDGEGLOW_COLOR"))
  'str)

(deftest "sysvar-redhilitepartial_selectededgeglow_color-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGEGLOW_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDEDGEGLOW_COLOR")
  "White (Settings dialog) #FFFFFF (Command line)")

(deftest "sysvar-redhilitepartial_selectededgeglow_smoothing-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGEGLOW_SMOOTHING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDEDGEGLOW_SMOOTHING"))
  'int)

(deftest "sysvar-redhilitepartial_selectededgeglow_smoothing-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGEGLOW_SMOOTHING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDEDGEGLOW_SMOOTHING")
  1)

(deftest "sysvar-redhilitepartial_selectededgeglow_thickness-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGEGLOW_THICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDEDGEGLOW_THICKNESS"))
  'real)

(deftest "sysvar-redhilitepartial_selectededgeglow_thickness-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGEGLOW_THICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDEDGEGLOW_THICKNESS")
  3.0)

(deftest "sysvar-redhilitepartial_selectededge_alpha-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDEDGE_ALPHA"))
  'int)

(deftest "sysvar-redhilitepartial_selectededge_alpha-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDEDGE_ALPHA")
  100)

(deftest "sysvar-redhilitepartial_selectededge_color-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDEDGE_COLOR"))
  'str)

(deftest "sysvar-redhilitepartial_selectededge_color-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDEDGE_COLOR")
  "255, 128, 0 (Settings dialog) #FF8000 (Command line)")

(deftest "sysvar-redhilitepartial_selectededge_showglow-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGE_SHOWGLOW") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDEDGE_SHOWGLOW"))
  'int)

(deftest "sysvar-redhilitepartial_selectededge_showglow-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGE_SHOWGLOW") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDEDGE_SHOWGLOW")
  1)

(deftest "sysvar-redhilitepartial_selectededge_smoothing-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGE_SMOOTHING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDEDGE_SMOOTHING"))
  'int)

(deftest "sysvar-redhilitepartial_selectededge_smoothing-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGE_SMOOTHING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDEDGE_SMOOTHING")
  1)

(deftest "sysvar-redhilitepartial_selectededge_thickness-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGE_THICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDEDGE_THICKNESS"))
  'real)

(deftest "sysvar-redhilitepartial_selectededge_thickness-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDEDGE_THICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDEDGE_THICKNESS")
  2.0)

(deftest "sysvar-redhilitepartial_selectedface_alpha-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDFACE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDFACE_ALPHA"))
  'int)

(deftest "sysvar-redhilitepartial_selectedface_alpha-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDFACE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDFACE_ALPHA")
  10)

(deftest "sysvar-redhilitepartial_selectedface_color-getvar-type"
  '((operator . "REDHILITEPARTIAL_SELECTEDFACE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_SELECTEDFACE_COLOR"))
  'str)

(deftest "sysvar-redhilitepartial_selectedface_color-getvar-default"
  '((operator . "REDHILITEPARTIAL_SELECTEDFACE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_SELECTEDFACE_COLOR")
  "#007AFF")

(deftest "sysvar-redhilitepartial_unselectededge_showhidden-getvar-type"
  '((operator . "REDHILITEPARTIAL_UNSELECTEDEDGE_SHOWHIDDEN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITEPARTIAL_UNSELECTEDEDGE_SHOWHIDDEN"))
  'int)

(deftest "sysvar-redhilitepartial_unselectededge_showhidden-getvar-default"
  '((operator . "REDHILITEPARTIAL_UNSELECTEDEDGE_SHOWHIDDEN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITEPARTIAL_UNSELECTEDEDGE_SHOWHIDDEN")
  1)

(deftest "sysvar-redhilite_ducslocked_face_alpha-getvar-type"
  '((operator . "REDHILITE_DUCSLOCKED_FACE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITE_DUCSLOCKED_FACE_ALPHA"))
  'int)

(deftest "sysvar-redhilite_ducslocked_face_alpha-getvar-default"
  '((operator . "REDHILITE_DUCSLOCKED_FACE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITE_DUCSLOCKED_FACE_ALPHA")
  25)

(deftest "sysvar-redhilite_ducslocked_face_color-getvar-type"
  '((operator . "REDHILITE_DUCSLOCKED_FACE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITE_DUCSLOCKED_FACE_COLOR"))
  'str)

(deftest "sysvar-redhilite_ducslocked_face_color-getvar-default"
  '((operator . "REDHILITE_DUCSLOCKED_FACE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITE_DUCSLOCKED_FACE_COLOR")
  "#007AFF")

(deftest "sysvar-redhilite_hiddenedge_alpha-getvar-type"
  '((operator . "REDHILITE_HIDDENEDGE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITE_HIDDENEDGE_ALPHA"))
  'int)

(deftest "sysvar-redhilite_hiddenedge_alpha-getvar-default"
  '((operator . "REDHILITE_HIDDENEDGE_ALPHA") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITE_HIDDENEDGE_ALPHA")
  50)

(deftest "sysvar-redhilite_hiddenedge_color-getvar-type"
  '((operator . "REDHILITE_HIDDENEDGE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDHILITE_HIDDENEDGE_COLOR"))
  'str)

(deftest "sysvar-redhilite_hiddenedge_color-getvar-default"
  '((operator . "REDHILITE_HIDDENEDGE_COLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDHILITE_HIDDENEDGE_COLOR")
  "White (Settings dialog) #FFFFFF (Command line)")

(deftest "sysvar-redsdklinesmoothing-getvar-type"
  '((operator . "REDSDKLINESMOOTHING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDSDKLINESMOOTHING"))
  'int)

(deftest "sysvar-redsdklinesmoothing-getvar-default"
  '((operator . "REDSDKLINESMOOTHING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDSDKLINESMOOTHING")
  0)

(deftest "sysvar-reducelengthtype-getvar-type"
  '((operator . "REDUCELENGTHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDUCELENGTHTYPE"))
  'int)

(deftest "sysvar-reducelengthtype-getvar-default"
  '((operator . "REDUCELENGTHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDUCELENGTHTYPE")
  0)

(deftest "sysvar-reducelengthvalue-getvar-type"
  '((operator . "REDUCELENGTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REDUCELENGTHVALUE"))
  'real)

(deftest "sysvar-reducelengthvalue-getvar-default"
  '((operator . "REDUCELENGTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REDUCELENGTHVALUE")
  0.5)

(deftest "sysvar-refeditlocknotinworkset-getvar-type"
  '((operator . "REFEDITLOCKNOTINWORKSET") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REFEDITLOCKNOTINWORKSET"))
  'int)

(deftest "sysvar-refeditlocknotinworkset-getvar-default"
  '((operator . "REFEDITLOCKNOTINWORKSET") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REFEDITLOCKNOTINWORKSET")
  0)

(deftest "sysvar-refeditname-getvar-type"
  '((operator . "REFEDITNAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REFEDITNAME"))
  'str)

(deftest-error "sysvar-refeditname-setvar-readonly-signals"
  '((operator . "REFEDITNAME") (area . "sysvar") (profile . STRICT))
  '(setvar "REFEDITNAME" "")
  'sysvar-read-only)

(deftest "sysvar-refpathtype-getvar-type"
  '((operator . "REFPATHTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REFPATHTYPE"))
  'int)

(deftest "sysvar-regenmode-getvar-type"
  '((operator . "REGENMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REGENMODE"))
  'int)

(deftest "sysvar-regenmode-getvar-default"
  '((operator . "REGENMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "REGENMODE")
  1)

(deftest "sysvar-regexpand-getvar-type"
  '((operator . "REGEXPAND") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REGEXPAND"))
  'int)

(deftest "sysvar-regexpand-getvar-default"
  '((operator . "REGEXPAND") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REGEXPAND")
  1)

(deftest "sysvar-rememberfolders-getvar-type"
  '((operator . "REMEMBERFOLDERS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REMEMBERFOLDERS"))
  'int)

(deftest "sysvar-rendercompositionmaterial-getvar-type"
  '((operator . "RENDERCOMPOSITIONMATERIAL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RENDERCOMPOSITIONMATERIAL"))
  'int)

(deftest "sysvar-rendercompositionmaterial-getvar-default"
  '((operator . "RENDERCOMPOSITIONMATERIAL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RENDERCOMPOSITIONMATERIAL")
  0)

(deftest "sysvar-renderenvstate-getvar-type"
  '((operator . "RENDERENVSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RENDERENVSTATE"))
  'int)

(deftest-error "sysvar-renderenvstate-setvar-readonly-signals"
  '((operator . "RENDERENVSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "RENDERENVSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-renderlevel-getvar-type"
  '((operator . "RENDERLEVEL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RENDERLEVEL"))
  'int)

(deftest "sysvar-renderlevel-getvar-default"
  '((operator . "RENDERLEVEL") (area . "sysvar") (profile . STRICT))
  '(getvar "RENDERLEVEL")
  5)

(deftest "sysvar-renderlightcalc-getvar-type"
  '((operator . "RENDERLIGHTCALC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RENDERLIGHTCALC"))
  'int)

(deftest "sysvar-renderlightcalc-getvar-default"
  '((operator . "RENDERLIGHTCALC") (area . "sysvar") (profile . STRICT))
  '(getvar "RENDERLIGHTCALC")
  1)

(deftest "sysvar-rendermaterialdownload-getvar-type"
  '((operator . "RENDERMATERIALDOWNLOAD") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RENDERMATERIALDOWNLOAD"))
  'int)

(deftest "sysvar-rendermaterialdownload-getvar-default"
  '((operator . "RENDERMATERIALDOWNLOAD") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RENDERMATERIALDOWNLOAD")
  1)

(deftest "sysvar-rendermaterialspath-getvar-type"
  '((operator . "RENDERMATERIALSPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RENDERMATERIALSPATH"))
  'str)

(deftest "sysvar-renderprefsstate-getvar-type"
  '((operator . "RENDERPREFSSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RENDERPREFSSTATE"))
  'int)

(deftest-error "sysvar-renderprefsstate-setvar-readonly-signals"
  '((operator . "RENDERPREFSSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "RENDERPREFSSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-rendertarget-getvar-type"
  '((operator . "RENDERTARGET") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RENDERTARGET"))
  'int)

(deftest "sysvar-rendertarget-getvar-default"
  '((operator . "RENDERTARGET") (area . "sysvar") (profile . STRICT))
  '(getvar "RENDERTARGET")
  0)

(deftest "sysvar-rendertime-getvar-type"
  '((operator . "RENDERTIME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RENDERTIME"))
  'int)

(deftest "sysvar-rendertime-getvar-default"
  '((operator . "RENDERTIME") (area . "sysvar") (profile . STRICT))
  '(getvar "RENDERTIME")
  10)

(deftest "sysvar-renderuserlights-getvar-type"
  '((operator . "RENDERUSERLIGHTS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RENDERUSERLIGHTS"))
  'int)

(deftest "sysvar-renderuserlights-getvar-default"
  '((operator . "RENDERUSERLIGHTS") (area . "sysvar") (profile . STRICT))
  '(getvar "RENDERUSERLIGHTS")
  1)

(deftest "sysvar-renderusinghardware-getvar-type"
  '((operator . "RENDERUSINGHARDWARE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RENDERUSINGHARDWARE"))
  'int)

(deftest "sysvar-renderusinghardware-getvar-default"
  '((operator . "RENDERUSINGHARDWARE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RENDERUSINGHARDWARE")
  1)

(deftest "sysvar-reporterror-getvar-type"
  '((operator . "REPORTERROR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REPORTERROR"))
  'int)

(deftest "sysvar-reporterror-getvar-default"
  '((operator . "REPORTERROR") (area . "sysvar") (profile . STRICT))
  '(getvar "REPORTERROR")
  1)

(deftest "sysvar-reportpanelmode-getvar-type"
  '((operator . "REPORTPANELMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "REPORTPANELMODE"))
  'int)

(deftest "sysvar-reportpanelmode-getvar-default"
  '((operator . "REPORTPANELMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "REPORTPANELMODE")
  2)

(deftest "sysvar-restoreconnections-getvar-type"
  '((operator . "RESTORECONNECTIONS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RESTORECONNECTIONS"))
  'int)

(deftest "sysvar-restoreconnections-getvar-default"
  '((operator . "RESTORECONNECTIONS") (area . "sysvar") (profile . STRICT))
  '(getvar "RESTORECONNECTIONS")
  1)

(deftest "sysvar-restorelostfocus-getvar-type"
  '((operator . "RESTORELOSTFOCUS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RESTORELOSTFOCUS"))
  'int)

(deftest "sysvar-retainedgraphics-getvar-type"
  '((operator . "RETAINEDGRAPHICS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RETAINEDGRAPHICS"))
  'int)

(deftest "sysvar-retainedgraphics-getvar-default"
  '((operator . "RETAINEDGRAPHICS") (area . "sysvar") (profile . STRICT))
  '(getvar "RETAINEDGRAPHICS")
  1)

(deftest "sysvar-revcloudapproxarclen-getvar-type"
  '((operator . "REVCLOUDAPPROXARCLEN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REVCLOUDAPPROXARCLEN"))
  'real)

(deftest "sysvar-revcloudapproxarclen-getvar-default"
  '((operator . "REVCLOUDAPPROXARCLEN") (area . "sysvar") (profile . STRICT))
  '(getvar "REVCLOUDAPPROXARCLEN")
  0.0)

(deftest "sysvar-revcloudarcstyle-getvar-type"
  '((operator . "REVCLOUDARCSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REVCLOUDARCSTYLE"))
  'int)

(deftest "sysvar-revcloudarcstyle-getvar-default"
  '((operator . "REVCLOUDARCSTYLE") (area . "sysvar") (profile . STRICT))
  '(getvar "REVCLOUDARCSTYLE")
  0)

(deftest "sysvar-revcloudarcvariance-getvar-type"
  '((operator . "REVCLOUDARCVARIANCE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REVCLOUDARCVARIANCE"))
  'int)

(deftest "sysvar-revcloudarcvariance-getvar-default"
  '((operator . "REVCLOUDARCVARIANCE") (area . "sysvar") (profile . STRICT))
  '(getvar "REVCLOUDARCVARIANCE")
  1)

(deftest "sysvar-revcloudcreatemode-getvar-type"
  '((operator . "REVCLOUDCREATEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REVCLOUDCREATEMODE"))
  'int)

(deftest "sysvar-revcloudgrips-getvar-type"
  '((operator . "REVCLOUDGRIPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REVCLOUDGRIPS"))
  'int)

(deftest "sysvar-revcloudgrips-getvar-default"
  '((operator . "REVCLOUDGRIPS") (area . "sysvar") (profile . STRICT))
  '(getvar "REVCLOUDGRIPS")
  1)

(deftest "sysvar-revcloudlayer-getvar-type"
  '((operator . "REVCLOUDLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REVCLOUDLAYER"))
  'str)

(deftest "sysvar-revcloudlayer-getvar-default"
  '((operator . "REVCLOUDLAYER") (area . "sysvar") (profile . STRICT))
  '(getvar "REVCLOUDLAYER")
  "\"use current\"")

(deftest "sysvar-revcloudmaxarclength-getvar-type"
  '((operator . "REVCLOUDMAXARCLENGTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REVCLOUDMAXARCLENGTH"))
  'real)

(deftest "sysvar-revcloudminarclength-getvar-type"
  '((operator . "REVCLOUDMINARCLENGTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REVCLOUDMINARCLENGTH"))
  'real)

(deftest "sysvar-revcloudscalemode-getvar-type"
  '((operator . "REVCLOUDSCALEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "REVCLOUDSCALEMODE"))
  'int)

(deftest "sysvar-revcloudscalemode-getvar-default"
  '((operator . "REVCLOUDSCALEMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "REVCLOUDSCALEMODE")
  0)

(deftest "sysvar-re_init-getvar-type"
  '((operator . "RE_INIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RE_INIT"))
  'int)

(deftest-error "sysvar-re_init-setvar-readonly-signals"
  '((operator . "RE_INIT") (area . "sysvar") (profile . STRICT))
  '(setvar "RE_INIT" 0)
  'sysvar-read-only)

(deftest "sysvar-rhinoversion-getvar-type"
  '((operator . "RHINOVERSION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RHINOVERSION"))
  'int)

(deftest "sysvar-rhinoversion-getvar-default"
  '((operator . "RHINOVERSION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RHINOVERSION")
  0)

(deftest "sysvar-ribbonbgload-getvar-type"
  '((operator . "RIBBONBGLOAD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RIBBONBGLOAD"))
  'int)

(deftest "sysvar-ribbonbgload-getvar-default"
  '((operator . "RIBBONBGLOAD") (area . "sysvar") (profile . STRICT))
  '(getvar "RIBBONBGLOAD")
  1)

(deftest "sysvar-ribboncontextsellim-getvar-type"
  '((operator . "RIBBONCONTEXTSELLIM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RIBBONCONTEXTSELLIM"))
  'int)

(deftest "sysvar-ribboncontextsellim-getvar-default"
  '((operator . "RIBBONCONTEXTSELLIM") (area . "sysvar") (profile . STRICT))
  '(getvar "RIBBONCONTEXTSELLIM")
  2500)

(deftest "sysvar-ribbondockedheight-getvar-type"
  '((operator . "RIBBONDOCKEDHEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RIBBONDOCKEDHEIGHT"))
  'int)

(deftest "sysvar-ribboniconresize-getvar-type"
  '((operator . "RIBBONICONRESIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RIBBONICONRESIZE"))
  'int)

(deftest "sysvar-ribboniconresize-getvar-default"
  '((operator . "RIBBONICONRESIZE") (area . "sysvar") (profile . STRICT))
  '(getvar "RIBBONICONRESIZE")
  1)

(deftest "sysvar-ribbonpanelmargin-getvar-type"
  '((operator . "RIBBONPANELMARGIN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RIBBONPANELMARGIN"))
  'int)

(deftest "sysvar-ribbonpanelmargin-getvar-default"
  '((operator . "RIBBONPANELMARGIN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RIBBONPANELMARGIN")
  8)

(deftest "sysvar-ribbonselectmode-getvar-type"
  '((operator . "RIBBONSELECTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RIBBONSELECTMODE"))
  'int)

(deftest "sysvar-ribbonselectmode-getvar-default"
  '((operator . "RIBBONSELECTMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "RIBBONSELECTMODE")
  1)

(deftest "sysvar-ribbonsettingsenabled-getvar-type"
  '((operator . "RIBBONSETTINGSENABLED") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RIBBONSETTINGSENABLED"))
  'int)

(deftest "sysvar-ribbonsettingsenabled-getvar-default"
  '((operator . "RIBBONSETTINGSENABLED") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RIBBONSETTINGSENABLED")
  1)

(deftest "sysvar-ribbonstate-getvar-type"
  '((operator . "RIBBONSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RIBBONSTATE"))
  'int)

(deftest-error "sysvar-ribbonstate-setvar-readonly-signals"
  '((operator . "RIBBONSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "RIBBONSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-roamablerootprefix-getvar-type"
  '((operator . "ROAMABLEROOTPREFIX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ROAMABLEROOTPREFIX"))
  'str)

(deftest-error "sysvar-roamablerootprefix-setvar-readonly-signals"
  '((operator . "ROAMABLEROOTPREFIX") (area . "sysvar") (profile . STRICT))
  '(setvar "ROAMABLEROOTPREFIX" "")
  'sysvar-read-only)

(deftest "sysvar-rolloveropacity-getvar-type"
  '((operator . "ROLLOVEROPACITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ROLLOVEROPACITY"))
  'int)

(deftest "sysvar-rolloverparams-getvar-type"
  '((operator . "ROLLOVERPARAMS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ROLLOVERPARAMS"))
  'int)

(deftest "sysvar-rolloverparams-getvar-default"
  '((operator . "ROLLOVERPARAMS") (area . "sysvar") (profile . STRICT))
  '(getvar "ROLLOVERPARAMS")
  1)

(deftest "sysvar-rolloverselectionset-getvar-type"
  '((operator . "ROLLOVERSELECTIONSET") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "ROLLOVERSELECTIONSET"))
  'int)

(deftest "sysvar-rolloverselectionset-getvar-default"
  '((operator . "ROLLOVERSELECTIONSET") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "ROLLOVERSELECTIONSET")
  2)

(deftest "sysvar-rollovertips-getvar-type"
  '((operator . "ROLLOVERTIPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ROLLOVERTIPS"))
  'int)

(deftest "sysvar-rtdisplay-getvar-type"
  '((operator . "RTDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RTDISPLAY"))
  'int)

(deftest "sysvar-rtisolateselection-getvar-type"
  '((operator . "RTISOLATESELECTION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RTISOLATESELECTION"))
  'int)

(deftest "sysvar-rtisolateselection-getvar-default"
  '((operator . "RTISOLATESELECTION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RTISOLATESELECTION")
  0)

(deftest "sysvar-rtregenauto-getvar-type"
  '((operator . "RTREGENAUTO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RTREGENAUTO"))
  'int)

(deftest "sysvar-rtregenauto-getvar-default"
  '((operator . "RTREGENAUTO") (area . "sysvar") (profile . STRICT))
  '(getvar "RTREGENAUTO")
  1)

(deftest "sysvar-rtrotationspeedfactor-getvar-type"
  '((operator . "RTROTATIONSPEEDFACTOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RTROTATIONSPEEDFACTOR"))
  'real)

(deftest "sysvar-rtrotationspeedfactor-getvar-default"
  '((operator . "RTROTATIONSPEEDFACTOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RTROTATIONSPEEDFACTOR")
  1.0)

(deftest "sysvar-rubberbandcolor-getvar-type"
  '((operator . "RUBBERBANDCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RUBBERBANDCOLOR"))
  'int)

(deftest "sysvar-rubberbandcolor-getvar-default"
  '((operator . "RUBBERBANDCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RUBBERBANDCOLOR")
  40)

(deftest "sysvar-rubberbandstyle-getvar-type"
  '((operator . "RUBBERBANDSTYLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RUBBERBANDSTYLE"))
  'int)

(deftest "sysvar-rubberbandstyle-getvar-default"
  '((operator . "RUBBERBANDSTYLE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RUBBERBANDSTYLE")
  1)

(deftest "sysvar-rubbersheetsensibility_for_os_x-getvar-type"
  '((operator . "RUBBERSHEETSENSIBILITY_FOR_OS_X") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RUBBERSHEETSENSIBILITY_FOR_OS_X"))
  'int)

(deftest "sysvar-rubbersheetsensibility_for_os_x-getvar-default"
  '((operator . "RUBBERSHEETSENSIBILITY_FOR_OS_X") (area . "sysvar") (profile . STRICT))
  '(getvar "RUBBERSHEETSENSIBILITY_FOR_OS_X")
  5)

(deftest "sysvar-rubbersheet_for_os_x-getvar-type"
  '((operator . "RUBBERSHEET_FOR_OS_X") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RUBBERSHEET_FOR_OS_X"))
  'int)

(deftest "sysvar-rubbersheet_for_os_x-getvar-default"
  '((operator . "RUBBERSHEET_FOR_OS_X") (area . "sysvar") (profile . STRICT))
  '(getvar "RUBBERSHEET_FOR_OS_X")
  1)

(deftest "sysvar-rulerdisplay-getvar-type"
  '((operator . "RULERDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RULERDISPLAY"))
  'int)

(deftest "sysvar-rulerdisplay-getvar-default"
  '((operator . "RULERDISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "RULERDISPLAY")
  1)

(deftest "sysvar-rulertextcolor-getvar-type"
  '((operator . "RULERTEXTCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "RULERTEXTCOLOR"))
  'str)

(deftest "sysvar-rulertextcolor-getvar-default"
  '((operator . "RULERTEXTCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "RULERTEXTCOLOR")
  "#c8c8c8")

(deftest "sysvar-runaslevel-getvar-type"
  '((operator . "RUNASLEVEL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RUNASLEVEL"))
  'int)

(deftest "sysvar-runaslevel-getvar-default"
  '((operator . "RUNASLEVEL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RUNASLEVEL")
  5)

(deftest "sysvar-rvtrfalevelofdetail-getvar-type"
  '((operator . "RVTRFALEVELOFDETAIL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RVTRFALEVELOFDETAIL"))
  'int)

(deftest "sysvar-rvtrfalevelofdetail-getvar-default"
  '((operator . "RVTRFALEVELOFDETAIL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RVTRFALEVELOFDETAIL")
  3)

(deftest "sysvar-rvtvalidatebrep-getvar-type"
  '((operator . "RVTVALIDATEBREP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "RVTVALIDATEBREP"))
  'int)

(deftest "sysvar-rvtvalidatebrep-getvar-default"
  '((operator . "RVTVALIDATEBREP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "RVTVALIDATEBREP")
  1)

(deftest "sysvar-safemode-getvar-type"
  '((operator . "SAFEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SAFEMODE"))
  'int)

(deftest-error "sysvar-safemode-setvar-readonly-signals"
  '((operator . "SAFEMODE") (area . "sysvar") (profile . STRICT))
  '(setvar "SAFEMODE" 0)
  'sysvar-read-only)

(deftest "sysvar-savechangetolayout-getvar-type"
  '((operator . "SAVECHANGETOLAYOUT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SAVECHANGETOLAYOUT"))
  'int)

(deftest "sysvar-savechangetolayout-getvar-default"
  '((operator . "SAVECHANGETOLAYOUT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SAVECHANGETOLAYOUT")
  1)

(deftest "sysvar-savefidelity-getvar-type"
  '((operator . "SAVEFIDELITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SAVEFIDELITY"))
  'int)

(deftest "sysvar-savefidelity-getvar-default"
  '((operator . "SAVEFIDELITY") (area . "sysvar") (profile . STRICT))
  '(getvar "SAVEFIDELITY")
  1)

(deftest "sysvar-savefile-getvar-type"
  '((operator . "SAVEFILE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SAVEFILE"))
  'str)

(deftest-error "sysvar-savefile-setvar-readonly-signals"
  '((operator . "SAVEFILE") (area . "sysvar") (profile . STRICT))
  '(setvar "SAVEFILE" "")
  'sysvar-read-only)

(deftest "sysvar-savefilepath-getvar-type"
  '((operator . "SAVEFILEPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SAVEFILEPATH"))
  'str)

(deftest "sysvar-saveformat-getvar-type"
  '((operator . "SAVEFORMAT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SAVEFORMAT"))
  'int)

(deftest "sysvar-saveformat-getvar-default"
  '((operator . "SAVEFORMAT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SAVEFORMAT")
  1)

(deftest "sysvar-savelayersnapshot-getvar-type"
  '((operator . "SAVELAYERSNAPSHOT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SAVELAYERSNAPSHOT"))
  'int)

(deftest "sysvar-savelayersnapshot-getvar-default"
  '((operator . "SAVELAYERSNAPSHOT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SAVELAYERSNAPSHOT")
  1)

(deftest "sysvar-savename-getvar-type"
  '((operator . "SAVENAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SAVENAME"))
  'str)

(deftest-error "sysvar-savename-setvar-readonly-signals"
  '((operator . "SAVENAME") (area . "sysvar") (profile . STRICT))
  '(setvar "SAVENAME" "")
  'sysvar-read-only)

(deftest "sysvar-saveondocswitch-getvar-type"
  '((operator . "SAVEONDOCSWITCH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SAVEONDOCSWITCH"))
  'int)

(deftest "sysvar-saveondocswitch-getvar-default"
  '((operator . "SAVEONDOCSWITCH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SAVEONDOCSWITCH")
  0)

(deftest "sysvar-saveroundtrip-getvar-type"
  '((operator . "SAVEROUNDTRIP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SAVEROUNDTRIP"))
  'int)

(deftest "sysvar-saveroundtrip-getvar-default"
  '((operator . "SAVEROUNDTRIP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SAVEROUNDTRIP")
  1)

(deftest "sysvar-savetime-getvar-type"
  '((operator . "SAVETIME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SAVETIME"))
  'int)

(deftest "sysvar-screenboxes-getvar-type"
  '((operator . "SCREENBOXES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SCREENBOXES"))
  'int)

(deftest-error "sysvar-screenboxes-setvar-readonly-signals"
  '((operator . "SCREENBOXES") (area . "sysvar") (profile . STRICT))
  '(setvar "SCREENBOXES" 0)
  'sysvar-read-only)

(deftest "sysvar-screenmode-getvar-type"
  '((operator . "SCREENMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SCREENMODE"))
  'int)

(deftest-error "sysvar-screenmode-setvar-readonly-signals"
  '((operator . "SCREENMODE") (area . "sysvar") (profile . STRICT))
  '(setvar "SCREENMODE" 0)
  'sysvar-read-only)

(deftest "sysvar-screensize-getvar-type"
  '((operator . "SCREENSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SCREENSIZE"))
  'list)

(deftest-error "sysvar-screensize-setvar-readonly-signals"
  '((operator . "SCREENSIZE") (area . "sysvar") (profile . STRICT))
  '(setvar "SCREENSIZE" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-scrlhist-getvar-type"
  '((operator . "SCRLHIST") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SCRLHIST"))
  'int)

(deftest "sysvar-scrlhist-getvar-default"
  '((operator . "SCRLHIST") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SCRLHIST")
  256)

(deftest "sysvar-sdi-getvar-type"
  '((operator . "SDI") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SDI"))
  'int)

(deftest-error "sysvar-sdi-setvar-readonly-signals"
  '((operator . "SDI") (area . "sysvar") (profile . STRICT))
  '(setvar "SDI" 0)
  'sysvar-read-only)

(deftest "sysvar-sectionoffsetinc-getvar-type"
  '((operator . "SECTIONOFFSETINC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SECTIONOFFSETINC"))
  'real)

(deftest "sysvar-sectionoffsetinc-getvar-default"
  '((operator . "SECTIONOFFSETINC") (area . "sysvar") (profile . STRICT))
  '(getvar "SECTIONOFFSETINC")
  6.0)

(deftest "sysvar-sectionresultinterval-getvar-type"
  '((operator . "SECTIONRESULTINTERVAL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SECTIONRESULTINTERVAL"))
  'real)

(deftest "sysvar-sectionresultinterval-getvar-default"
  '((operator . "SECTIONRESULTINTERVAL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SECTIONRESULTINTERVAL")
  400.0)

(deftest "sysvar-sectionscale-getvar-type"
  '((operator . "SECTIONSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SECTIONSCALE"))
  'real)

(deftest "sysvar-sectionscale-getvar-default"
  '((operator . "SECTIONSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SECTIONSCALE")
  0.02)

(deftest "sysvar-sectionsettingssearchpath-getvar-type"
  '((operator . "SECTIONSETTINGSSEARCHPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SECTIONSETTINGSSEARCHPATH"))
  'str)

(deftest "sysvar-sectionsheetsettemplateimperial-getvar-type"
  '((operator . "SECTIONSHEETSETTEMPLATEIMPERIAL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SECTIONSHEETSETTEMPLATEIMPERIAL"))
  'str)

(deftest "sysvar-sectionsheetsettemplateimperial-getvar-default"
  '((operator . "SECTIONSHEETSETTEMPLATEIMPERIAL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SECTIONSHEETSETTEMPLATEIMPERIAL")
  "BIM-section-imperial.dst")

(deftest "sysvar-sectionsheetsettemplatemetric-getvar-type"
  '((operator . "SECTIONSHEETSETTEMPLATEMETRIC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SECTIONSHEETSETTEMPLATEMETRIC"))
  'str)

(deftest "sysvar-sectionsheetsettemplatemetric-getvar-default"
  '((operator . "SECTIONSHEETSETTEMPLATEMETRIC") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SECTIONSHEETSETTEMPLATEMETRIC")
  "BIM-section-metric.dst")

(deftest "sysvar-sectionthicknessinc-getvar-type"
  '((operator . "SECTIONTHICKNESSINC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SECTIONTHICKNESSINC"))
  'real)

(deftest "sysvar-sectionthicknessinc-getvar-default"
  '((operator . "SECTIONTHICKNESSINC") (area . "sysvar") (profile . STRICT))
  '(getvar "SECTIONTHICKNESSINC")
  1.0)

(deftest "sysvar-secureload-getvar-type"
  '((operator . "SECURELOAD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SECURELOAD"))
  'int)

(deftest-error "sysvar-secureload-setvar-readonly-signals"
  '((operator . "SECURELOAD") (area . "sysvar") (profile . STRICT))
  '(setvar "SECURELOAD" 0)
  'sysvar-read-only)

(deftest "sysvar-secureremoteaccess-getvar-type"
  '((operator . "SECUREREMOTEACCESS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SECUREREMOTEACCESS"))
  'int)

(deftest "sysvar-secureremoteaccess-getvar-default"
  '((operator . "SECUREREMOTEACCESS") (area . "sysvar") (profile . STRICT))
  '(getvar "SECUREREMOTEACCESS")
  1)

(deftest "sysvar-selectionannodisplay-getvar-type"
  '((operator . "SELECTIONANNODISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SELECTIONANNODISPLAY"))
  'int)

(deftest "sysvar-selectionannodisplay-getvar-default"
  '((operator . "SELECTIONANNODISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "SELECTIONANNODISPLAY")
  1)

(deftest "sysvar-selectionarea-getvar-type"
  '((operator . "SELECTIONAREA") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SELECTIONAREA"))
  'int)

(deftest "sysvar-selectionarea-getvar-default"
  '((operator . "SELECTIONAREA") (area . "sysvar") (profile . STRICT))
  '(getvar "SELECTIONAREA")
  1)

(deftest "sysvar-selectionareaopacity-getvar-type"
  '((operator . "SELECTIONAREAOPACITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SELECTIONAREAOPACITY"))
  'int)

(deftest "sysvar-selectioncycling-getvar-type"
  '((operator . "SELECTIONCYCLING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SELECTIONCYCLING"))
  'int)

(deftest "sysvar-selectioncycling-getvar-default"
  '((operator . "SELECTIONCYCLING") (area . "sysvar") (profile . STRICT))
  '(getvar "SELECTIONCYCLING")
  0)

(deftest "sysvar-selectioneffect-getvar-type"
  '((operator . "SELECTIONEFFECT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SELECTIONEFFECT"))
  'int)

(deftest "sysvar-selectioneffect-getvar-default"
  '((operator . "SELECTIONEFFECT") (area . "sysvar") (profile . STRICT))
  '(getvar "SELECTIONEFFECT")
  1)

(deftest "sysvar-selectioneffectcolor-getvar-type"
  '((operator . "SELECTIONEFFECTCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SELECTIONEFFECTCOLOR"))
  'int)

(deftest "sysvar-selectioneffectcolor-getvar-default"
  '((operator . "SELECTIONEFFECTCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "SELECTIONEFFECTCOLOR")
  0)

(deftest "sysvar-selectionmodes-getvar-type"
  '((operator . "SELECTIONMODES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SELECTIONMODES"))
  'int)

(deftest "sysvar-selectionmodes-getvar-default"
  '((operator . "SELECTIONMODES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SELECTIONMODES")
  0)

(deftest "sysvar-selectionoffscreen-getvar-type"
  '((operator . "SELECTIONOFFSCREEN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SELECTIONOFFSCREEN"))
  'int)

(deftest "sysvar-selectionoffscreen-getvar-default"
  '((operator . "SELECTIONOFFSCREEN") (area . "sysvar") (profile . STRICT))
  '(getvar "SELECTIONOFFSCREEN")
  1)

(deftest "sysvar-selectionpreview-getvar-type"
  '((operator . "SELECTIONPREVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SELECTIONPREVIEW"))
  'int)

(deftest "sysvar-selectionpreviewlimit-getvar-type"
  '((operator . "SELECTIONPREVIEWLIMIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SELECTIONPREVIEWLIMIT"))
  'int)

(deftest "sysvar-selectionpreviewlimit-getvar-default"
  '((operator . "SELECTIONPREVIEWLIMIT") (area . "sysvar") (profile . STRICT))
  '(getvar "SELECTIONPREVIEWLIMIT")
  20000)

(deftest "sysvar-selectsimilarmode-getvar-type"
  '((operator . "SELECTSIMILARMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SELECTSIMILARMODE"))
  'int)

(deftest "sysvar-setbylayermode-getvar-type"
  '((operator . "SETBYLAYERMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SETBYLAYERMODE"))
  'int)

(deftest "sysvar-shadedge-getvar-type"
  '((operator . "SHADEDGE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHADEDGE"))
  'int)

(deftest "sysvar-shadedif-getvar-type"
  '((operator . "SHADEDIF") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHADEDIF"))
  'int)

(deftest "sysvar-sharedviewstate-getvar-type"
  '((operator . "SHAREDVIEWSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHAREDVIEWSTATE"))
  'int)

(deftest-error "sysvar-sharedviewstate-setvar-readonly-signals"
  '((operator . "SHAREDVIEWSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "SHAREDVIEWSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-shareviewproperties-getvar-type"
  '((operator . "SHAREVIEWPROPERTIES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHAREVIEWPROPERTIES"))
  'int)

(deftest "sysvar-shareviewproperties-getvar-default"
  '((operator . "SHAREVIEWPROPERTIES") (area . "sysvar") (profile . STRICT))
  '(getvar "SHAREVIEWPROPERTIES")
  0)

(deftest "sysvar-shareviewtype-getvar-type"
  '((operator . "SHAREVIEWTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHAREVIEWTYPE"))
  'int)

(deftest "sysvar-shareviewtype-getvar-default"
  '((operator . "SHAREVIEWTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SHAREVIEWTYPE")
  0)

(deftest "sysvar-sheetnumberleadingzeroes-getvar-type"
  '((operator . "SHEETNUMBERLEADINGZEROES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SHEETNUMBERLEADINGZEROES"))
  'int)

(deftest "sysvar-sheetnumberleadingzeroes-getvar-default"
  '((operator . "SHEETNUMBERLEADINGZEROES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SHEETNUMBERLEADINGZEROES")
  1)

(deftest "sysvar-sheetsetautobackup-getvar-type"
  '((operator . "SHEETSETAUTOBACKUP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SHEETSETAUTOBACKUP"))
  'int)

(deftest "sysvar-sheetsetautobackup-getvar-default"
  '((operator . "SHEETSETAUTOBACKUP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SHEETSETAUTOBACKUP")
  1)

(deftest "sysvar-sheetsettemplatepath-getvar-type"
  '((operator . "SHEETSETTEMPLATEPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHEETSETTEMPLATEPATH"))
  'str)

(deftest "sysvar-shortcutmenu-getvar-type"
  '((operator . "SHORTCUTMENU") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHORTCUTMENU"))
  'int)

(deftest "sysvar-shortcutmenuduration-getvar-type"
  '((operator . "SHORTCUTMENUDURATION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHORTCUTMENUDURATION"))
  'int)

(deftest "sysvar-shortcutmenuduration-getvar-default"
  '((operator . "SHORTCUTMENUDURATION") (area . "sysvar") (profile . STRICT))
  '(getvar "SHORTCUTMENUDURATION")
  250)

(deftest "sysvar-showdoctabs-getvar-type"
  '((operator . "SHOWDOCTABS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SHOWDOCTABS"))
  'int)

(deftest "sysvar-showdoctabs-getvar-default"
  '((operator . "SHOWDOCTABS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SHOWDOCTABS")
  1)

(deftest "sysvar-showfullpathintitle-getvar-type"
  '((operator . "SHOWFULLPATHINTITLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHOWFULLPATHINTITLE"))
  'int)

(deftest "sysvar-showfullpathintitle-getvar-default"
  '((operator . "SHOWFULLPATHINTITLE") (area . "sysvar") (profile . STRICT))
  '(getvar "SHOWFULLPATHINTITLE")
  0)

(deftest "sysvar-showhist-getvar-type"
  '((operator . "SHOWHIST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHOWHIST"))
  'int)

(deftest "sysvar-showhist-getvar-default"
  '((operator . "SHOWHIST") (area . "sysvar") (profile . STRICT))
  '(getvar "SHOWHIST")
  1)

(deftest "sysvar-showidspropertiesonly-getvar-type"
  '((operator . "SHOWIDSPROPERTIESONLY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SHOWIDSPROPERTIESONLY"))
  'int)

(deftest "sysvar-showidspropertiesonly-getvar-default"
  '((operator . "SHOWIDSPROPERTIESONLY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SHOWIDSPROPERTIESONLY")
  0)

(deftest "sysvar-showlayerusage-getvar-type"
  '((operator . "SHOWLAYERUSAGE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHOWLAYERUSAGE"))
  'int)

(deftest "sysvar-showlayerusage-getvar-default"
  '((operator . "SHOWLAYERUSAGE") (area . "sysvar") (profile . STRICT))
  '(getvar "SHOWLAYERUSAGE")
  0)

(deftest "sysvar-shownewstate-getvar-type"
  '((operator . "SHOWNEWSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHOWNEWSTATE"))
  'int)

(deftest "sysvar-shownewstate-getvar-default"
  '((operator . "SHOWNEWSTATE") (area . "sysvar") (profile . STRICT))
  '(getvar "SHOWNEWSTATE")
  0)

(deftest "sysvar-showpalettestate-getvar-type"
  '((operator . "SHOWPALETTESTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHOWPALETTESTATE"))
  'int)

(deftest-error "sysvar-showpalettestate-setvar-readonly-signals"
  '((operator . "SHOWPALETTESTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "SHOWPALETTESTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-showscrollbuttons-getvar-type"
  '((operator . "SHOWSCROLLBUTTONS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SHOWSCROLLBUTTONS"))
  'int)

(deftest "sysvar-showscrollbuttons-getvar-default"
  '((operator . "SHOWSCROLLBUTTONS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SHOWSCROLLBUTTONS")
  1)

(deftest "sysvar-showtabclosebutton-getvar-type"
  '((operator . "SHOWTABCLOSEBUTTON") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SHOWTABCLOSEBUTTON"))
  'int)

(deftest "sysvar-showtabclosebutton-getvar-default"
  '((operator . "SHOWTABCLOSEBUTTON") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SHOWTABCLOSEBUTTON")
  0)

(deftest "sysvar-showtabclosebuttonactive-getvar-type"
  '((operator . "SHOWTABCLOSEBUTTONACTIVE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SHOWTABCLOSEBUTTONACTIVE"))
  'int)

(deftest "sysvar-showtabclosebuttonactive-getvar-default"
  '((operator . "SHOWTABCLOSEBUTTONACTIVE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SHOWTABCLOSEBUTTONACTIVE")
  0)

(deftest "sysvar-showtabclosebuttonall-getvar-type"
  '((operator . "SHOWTABCLOSEBUTTONALL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SHOWTABCLOSEBUTTONALL"))
  'int)

(deftest "sysvar-showtabclosebuttonall-getvar-default"
  '((operator . "SHOWTABCLOSEBUTTONALL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SHOWTABCLOSEBUTTONALL")
  1)

(deftest "sysvar-showwindowlistbutton-getvar-type"
  '((operator . "SHOWWINDOWLISTBUTTON") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SHOWWINDOWLISTBUTTON"))
  'int)

(deftest "sysvar-showwindowlistbutton-getvar-default"
  '((operator . "SHOWWINDOWLISTBUTTON") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SHOWWINDOWLISTBUTTON")
  1)

(deftest "sysvar-shpname-getvar-type"
  '((operator . "SHPNAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SHPNAME"))
  'str)

(deftest "sysvar-sigwarn-getvar-type"
  '((operator . "SIGWARN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SIGWARN"))
  'int)

(deftest "sysvar-sigwarn-getvar-default"
  '((operator . "SIGWARN") (area . "sysvar") (profile . STRICT))
  '(getvar "SIGWARN")
  1)

(deftest "sysvar-singletonmode-getvar-type"
  '((operator . "SINGLETONMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SINGLETONMODE"))
  'int)

(deftest "sysvar-singletonmode-getvar-default"
  '((operator . "SINGLETONMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SINGLETONMODE")
  0)

(deftest "sysvar-sitelocationvisibility-getvar-type"
  '((operator . "SITELOCATIONVISIBILITY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SITELOCATIONVISIBILITY"))
  'int)

(deftest "sysvar-sitelocationvisibility-getvar-default"
  '((operator . "SITELOCATIONVISIBILITY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SITELOCATIONVISIBILITY")
  1)

(deftest "sysvar-sketchfeaturecopymode-getvar-type"
  '((operator . "SKETCHFEATURECOPYMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SKETCHFEATURECOPYMODE"))
  'int)

(deftest "sysvar-sketchfeaturecopymode-getvar-default"
  '((operator . "SKETCHFEATURECOPYMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SKETCHFEATURECOPYMODE")
  1)

(deftest "sysvar-sketchinc-getvar-type"
  '((operator . "SKETCHINC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SKETCHINC"))
  'real)

(deftest "sysvar-sketchinc-getvar-default"
  '((operator . "SKETCHINC") (area . "sysvar") (profile . STRICT))
  '(getvar "SKETCHINC")
  1.0)

(deftest "sysvar-skpoly-getvar-type"
  '((operator . "SKPOLY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SKPOLY"))
  'int)

(deftest "sysvar-skpoly-getvar-default"
  '((operator . "SKPOLY") (area . "sysvar") (profile . STRICT))
  '(getvar "SKPOLY")
  0)

(deftest "sysvar-skystatus-getvar-type"
  '((operator . "SKYSTATUS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SKYSTATUS"))
  'int)

(deftest "sysvar-smassemblyexportmode-getvar-type"
  '((operator . "SMASSEMBLYEXPORTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMASSEMBLYEXPORTMODE"))
  'int)

(deftest "sysvar-smassemblyexportreportpathtype-getvar-type"
  '((operator . "SMASSEMBLYEXPORTREPORTPATHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMASSEMBLYEXPORTREPORTPATHTYPE"))
  'int)

(deftest "sysvar-smassemblyexportreportpathtype-getvar-default"
  '((operator . "SMASSEMBLYEXPORTREPORTPATHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMASSEMBLYEXPORTREPORTPATHTYPE")
  0)

(deftest "sysvar-smassemblyexportsolidtypesinreports-getvar-type"
  '((operator . "SMASSEMBLYEXPORTSOLIDTYPESINREPORTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMASSEMBLYEXPORTSOLIDTYPESINREPORTS"))
  'int)

(deftest "sysvar-smassemblyexportsolidtypesinreports-getvar-default"
  '((operator . "SMASSEMBLYEXPORTSOLIDTYPESINREPORTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMASSEMBLYEXPORTSOLIDTYPESINREPORTS")
  1)

(deftest "sysvar-smattributeslayercolor-getvar-type"
  '((operator . "SMATTRIBUTESLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMATTRIBUTESLAYERCOLOR"))
  'int)

(deftest "sysvar-smattributeslayercolor-getvar-default"
  '((operator . "SMATTRIBUTESLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMATTRIBUTESLAYERCOLOR")
  7)

(deftest "sysvar-smattributeslayertextheight-getvar-type"
  '((operator . "SMATTRIBUTESLAYERTEXTHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMATTRIBUTESLAYERTEXTHEIGHT"))
  'real)

(deftest "sysvar-smattributeslayertextheight-getvar-default"
  '((operator . "SMATTRIBUTESLAYERTEXTHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMATTRIBUTESLAYERTEXTHEIGHT")
  0.01)

(deftest "sysvar-smattributeslayertextheighttype-getvar-type"
  '((operator . "SMATTRIBUTESLAYERTEXTHEIGHTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMATTRIBUTESLAYERTEXTHEIGHTTYPE"))
  'int)

(deftest "sysvar-smattributeslayertextheighttype-getvar-default"
  '((operator . "SMATTRIBUTESLAYERTEXTHEIGHTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMATTRIBUTESLAYERTEXTHEIGHTTYPE")
  0)

(deftest "sysvar-smbendannotationslayercolor-getvar-type"
  '((operator . "SMBENDANNOTATIONSLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMBENDANNOTATIONSLAYERCOLOR"))
  'int)

(deftest "sysvar-smbendannotationslayercolor-getvar-default"
  '((operator . "SMBENDANNOTATIONSLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMBENDANNOTATIONSLAYERCOLOR")
  5)

(deftest "sysvar-smbendannotationslayertextheight-getvar-type"
  '((operator . "SMBENDANNOTATIONSLAYERTEXTHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMBENDANNOTATIONSLAYERTEXTHEIGHT"))
  'real)

(deftest "sysvar-smbendannotationslayertextheight-getvar-default"
  '((operator . "SMBENDANNOTATIONSLAYERTEXTHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMBENDANNOTATIONSLAYERTEXTHEIGHT")
  0.01)

(deftest "sysvar-smbendannotationslayertextheighttype-getvar-type"
  '((operator . "SMBENDANNOTATIONSLAYERTEXTHEIGHTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMBENDANNOTATIONSLAYERTEXTHEIGHTTYPE"))
  'int)

(deftest "sysvar-smbendannotationslayertextheighttype-getvar-default"
  '((operator . "SMBENDANNOTATIONSLAYERTEXTHEIGHTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMBENDANNOTATIONSLAYERTEXTHEIGHTTYPE")
  0)

(deftest "sysvar-smbendlinesdownlayercolor-getvar-type"
  '((operator . "SMBENDLINESDOWNLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMBENDLINESDOWNLAYERCOLOR"))
  'int)

(deftest "sysvar-smbendlinesdownlayercolor-getvar-default"
  '((operator . "SMBENDLINESDOWNLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMBENDLINESDOWNLAYERCOLOR")
  1)

(deftest "sysvar-smbendlinesdownlayerlinetype-getvar-type"
  '((operator . "SMBENDLINESDOWNLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMBENDLINESDOWNLAYERLINETYPE"))
  'str)

(deftest "sysvar-smbendlinesdownlayerlinetype-getvar-default"
  '((operator . "SMBENDLINESDOWNLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMBENDLINESDOWNLAYERLINETYPE")
  "CONTINUOUS")

(deftest "sysvar-smbendlinesdownlayerlineweight-getvar-type"
  '((operator . "SMBENDLINESDOWNLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMBENDLINESDOWNLAYERLINEWEIGHT"))
  'int)

(deftest "sysvar-smbendlinesdownlayerlineweight-getvar-default"
  '((operator . "SMBENDLINESDOWNLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMBENDLINESDOWNLAYERLINEWEIGHT")
  -3)

(deftest "sysvar-smbendlinesuplayercolor-getvar-type"
  '((operator . "SMBENDLINESUPLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMBENDLINESUPLAYERCOLOR"))
  'int)

(deftest "sysvar-smbendlinesuplayercolor-getvar-default"
  '((operator . "SMBENDLINESUPLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMBENDLINESUPLAYERCOLOR")
  1)

(deftest "sysvar-smbendlinesuplayerlinetype-getvar-type"
  '((operator . "SMBENDLINESUPLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMBENDLINESUPLAYERLINETYPE"))
  'str)

(deftest "sysvar-smbendlinesuplayerlinetype-getvar-default"
  '((operator . "SMBENDLINESUPLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMBENDLINESUPLAYERLINETYPE")
  "CONTINUOUS")

(deftest "sysvar-smbendlinesuplayerlineweight-getvar-type"
  '((operator . "SMBENDLINESUPLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMBENDLINESUPLAYERLINEWEIGHT"))
  'int)

(deftest "sysvar-smbendlinesuplayerlineweight-getvar-default"
  '((operator . "SMBENDLINESUPLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMBENDLINESUPLAYERLINEWEIGHT")
  -3)

(deftest "sysvar-smbevelfeaturecolor-getvar-type"
  '((operator . "SMBEVELFEATURECOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMBEVELFEATURECOLOR"))
  'int)

(deftest "sysvar-smbevelfeaturecolor-getvar-default"
  '((operator . "SMBEVELFEATURECOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMBEVELFEATURECOLOR")
  6)

(deftest "sysvar-smcolorbend-getvar-type"
  '((operator . "SMCOLORBEND") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORBEND"))
  'str)

(deftest "sysvar-smcolorbend-getvar-default"
  '((operator . "SMCOLORBEND") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORBEND")
  "#FFDC50")

(deftest "sysvar-smcolorbendrelief-getvar-type"
  '((operator . "SMCOLORBENDRELIEF") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORBENDRELIEF"))
  'str)

(deftest "sysvar-smcolorbendrelief-getvar-default"
  '((operator . "SMCOLORBENDRELIEF") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORBENDRELIEF")
  "#64D296")

(deftest "sysvar-smcolorbevel-getvar-type"
  '((operator . "SMCOLORBEVEL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORBEVEL"))
  'str)

(deftest "sysvar-smcolorbevel-getvar-default"
  '((operator . "SMCOLORBEVEL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORBEVEL")
  "#C0CE93")

(deftest "sysvar-smcolorcornerrelief-getvar-type"
  '((operator . "SMCOLORCORNERRELIEF") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORCORNERRELIEF"))
  'str)

(deftest "sysvar-smcolorcornerrelief-getvar-default"
  '((operator . "SMCOLORCORNERRELIEF") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORCORNERRELIEF")
  "#64D296")

(deftest "sysvar-smcolorflange-getvar-type"
  '((operator . "SMCOLORFLANGE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORFLANGE"))
  'str)

(deftest "sysvar-smcolorflange-getvar-default"
  '((operator . "SMCOLORFLANGE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORFLANGE")
  "#90A4AE")

(deftest "sysvar-smcolorflangereferenceside-getvar-type"
  '((operator . "SMCOLORFLANGEREFERENCESIDE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORFLANGEREFERENCESIDE"))
  'str)

(deftest "sysvar-smcolorflangereferenceside-getvar-default"
  '((operator . "SMCOLORFLANGEREFERENCESIDE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORFLANGEREFERENCESIDE")
  "#68A4AE")

(deftest "sysvar-smcolorform-getvar-type"
  '((operator . "SMCOLORFORM") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORFORM"))
  'str)

(deftest "sysvar-smcolorform-getvar-default"
  '((operator . "SMCOLORFORM") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORFORM")
  "#8791E1")

(deftest "sysvar-smcolorhem-getvar-type"
  '((operator . "SMCOLORHEM") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORHEM"))
  'str)

(deftest "sysvar-smcolorhem-getvar-default"
  '((operator . "SMCOLORHEM") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORHEM")
  "#FCAED6")

(deftest "sysvar-smcolorjog-getvar-type"
  '((operator . "SMCOLORJOG") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORJOG"))
  'str)

(deftest "sysvar-smcolorjog-getvar-default"
  '((operator . "SMCOLORJOG") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORJOG")
  "#CC7722")

(deftest "sysvar-smcolorjunction-getvar-type"
  '((operator . "SMCOLORJUNCTION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORJUNCTION"))
  'str)

(deftest "sysvar-smcolorjunction-getvar-default"
  '((operator . "SMCOLORJUNCTION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORJUNCTION")
  "#FF6E40")

(deftest "sysvar-smcolorloftedbend-getvar-type"
  '((operator . "SMCOLORLOFTEDBEND") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORLOFTEDBEND"))
  'str)

(deftest "sysvar-smcolorloftedbend-getvar-default"
  '((operator . "SMCOLORLOFTEDBEND") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORLOFTEDBEND")
  "#A0DCFA")

(deftest "sysvar-smcolormiter-getvar-type"
  '((operator . "SMCOLORMITER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORMITER"))
  'str)

(deftest "sysvar-smcolormiter-getvar-default"
  '((operator . "SMCOLORMITER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORMITER")
  "#AF46D8")

(deftest "sysvar-smcolorrollededge-getvar-type"
  '((operator . "SMCOLORROLLEDEDGE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORROLLEDEDGE"))
  'str)

(deftest "sysvar-smcolorrollededge-getvar-default"
  '((operator . "SMCOLORROLLEDEDGE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORROLLEDEDGE")
  "#8791E1")

(deftest "sysvar-smcolortab-getvar-type"
  '((operator . "SMCOLORTAB") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORTAB"))
  'str)

(deftest "sysvar-smcolortab-getvar-default"
  '((operator . "SMCOLORTAB") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORTAB")
  "#FDA542")

(deftest "sysvar-smcolorwrongbend-getvar-type"
  '((operator . "SMCOLORWRONGBEND") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORWRONGBEND"))
  'str)

(deftest "sysvar-smcolorwrongbend-getvar-default"
  '((operator . "SMCOLORWRONGBEND") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORWRONGBEND")
  "#FF3300")

(deftest "sysvar-smcolorwrongflange-getvar-type"
  '((operator . "SMCOLORWRONGFLANGE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCOLORWRONGFLANGE"))
  'str)

(deftest "sysvar-smcolorwrongflange-getvar-default"
  '((operator . "SMCOLORWRONGFLANGE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCOLORWRONGFLANGE")
  "#A82000")

(deftest "sysvar-smcontourslayercolor-getvar-type"
  '((operator . "SMCONTOURSLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONTOURSLAYERCOLOR"))
  'int)

(deftest "sysvar-smcontourslayercolor-getvar-default"
  '((operator . "SMCONTOURSLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONTOURSLAYERCOLOR")
  7)

(deftest "sysvar-smcontourslayerlinetype-getvar-type"
  '((operator . "SMCONTOURSLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONTOURSLAYERLINETYPE"))
  'str)

(deftest "sysvar-smcontourslayerlinetype-getvar-default"
  '((operator . "SMCONTOURSLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONTOURSLAYERLINETYPE")
  "CONTINUOUS")

(deftest "sysvar-smcontourslayerlineweight-getvar-type"
  '((operator . "SMCONTOURSLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONTOURSLAYERLINEWEIGHT"))
  'int)

(deftest "sysvar-smcontourslayerlineweight-getvar-default"
  '((operator . "SMCONTOURSLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONTOURSLAYERLINEWEIGHT")
  30)

(deftest "sysvar-smconvertmaximalbevelangle-getvar-type"
  '((operator . "SMCONVERTMAXIMALBEVELANGLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTMAXIMALBEVELANGLE"))
  'real)

(deftest "sysvar-smconvertmaximalbevelangle-getvar-default"
  '((operator . "SMCONVERTMAXIMALBEVELANGLE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTMAXIMALBEVELANGLE")
  80.0)

(deftest "sysvar-smconvertminimalbevelangle-getvar-type"
  '((operator . "SMCONVERTMINIMALBEVELANGLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTMINIMALBEVELANGLE"))
  'real)

(deftest "sysvar-smconvertminimalbevelangle-getvar-default"
  '((operator . "SMCONVERTMINIMALBEVELANGLE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTMINIMALBEVELANGLE")
  10.0)

(deftest "sysvar-smconvertpreferformfeatures-getvar-type"
  '((operator . "SMCONVERTPREFERFORMFEATURES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTPREFERFORMFEATURES"))
  'int)

(deftest "sysvar-smconvertpreferformfeatures-getvar-default"
  '((operator . "SMCONVERTPREFERFORMFEATURES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTPREFERFORMFEATURES")
  0)

(deftest "sysvar-smconvertpreferhemfeatures-getvar-type"
  '((operator . "SMCONVERTPREFERHEMFEATURES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTPREFERHEMFEATURES"))
  'int)

(deftest "sysvar-smconvertpreferhemfeatures-getvar-default"
  '((operator . "SMCONVERTPREFERHEMFEATURES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTPREFERHEMFEATURES")
  1)

(deftest "sysvar-smconvertpreferjogfeatures-getvar-type"
  '((operator . "SMCONVERTPREFERJOGFEATURES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTPREFERJOGFEATURES"))
  'int)

(deftest "sysvar-smconvertpreferjogfeatures-getvar-default"
  '((operator . "SMCONVERTPREFERJOGFEATURES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTPREFERJOGFEATURES")
  0)

(deftest "sysvar-smconvertpreferzerobendfeatures-getvar-type"
  '((operator . "SMCONVERTPREFERZEROBENDFEATURES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTPREFERZEROBENDFEATURES"))
  'int)

(deftest "sysvar-smconvertpreferzerobendfeatures-getvar-default"
  '((operator . "SMCONVERTPREFERZEROBENDFEATURES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTPREFERZEROBENDFEATURES")
  1)

(deftest "sysvar-smconvertrecognizebevels-getvar-type"
  '((operator . "SMCONVERTRECOGNIZEBEVELS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTRECOGNIZEBEVELS"))
  'int)

(deftest "sysvar-smconvertrecognizebevels-getvar-default"
  '((operator . "SMCONVERTRECOGNIZEBEVELS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTRECOGNIZEBEVELS")
  1)

(deftest "sysvar-smconvertrecognizeholes-getvar-type"
  '((operator . "SMCONVERTRECOGNIZEHOLES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTRECOGNIZEHOLES"))
  'int)

(deftest "sysvar-smconvertrecognizeholes-getvar-default"
  '((operator . "SMCONVERTRECOGNIZEHOLES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTRECOGNIZEHOLES")
  0)

(deftest "sysvar-smconvertrecognizeribcontrolcurves-getvar-type"
  '((operator . "SMCONVERTRECOGNIZERIBCONTROLCURVES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTRECOGNIZERIBCONTROLCURVES"))
  'int)

(deftest "sysvar-smconvertrecognizeribcontrolcurves-getvar-default"
  '((operator . "SMCONVERTRECOGNIZERIBCONTROLCURVES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTRECOGNIZERIBCONTROLCURVES")
  0)

(deftest "sysvar-smconvertwrongfeaturethicknessdeviationtype-getvar-type"
  '((operator . "SMCONVERTWRONGFEATURETHICKNESSDEVIATIONTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTWRONGFEATURETHICKNESSDEVIATIONTYPE"))
  'int)

(deftest "sysvar-smconvertwrongfeaturethicknessdeviationtype-getvar-default"
  '((operator . "SMCONVERTWRONGFEATURETHICKNESSDEVIATIONTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTWRONGFEATURETHICKNESSDEVIATIONTYPE")
  0)

(deftest "sysvar-smconvertwrongfeaturethicknessdeviationvalue-getvar-type"
  '((operator . "SMCONVERTWRONGFEATURETHICKNESSDEVIATIONVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMCONVERTWRONGFEATURETHICKNESSDEVIATIONVALUE"))
  'real)

(deftest "sysvar-smconvertwrongfeaturethicknessdeviationvalue-getvar-default"
  '((operator . "SMCONVERTWRONGFEATURETHICKNESSDEVIATIONVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMCONVERTWRONGFEATURETHICKNESSDEVIATIONVALUE")
  0.2)

(deftest "sysvar-smdefaultbendlineextenttype-getvar-type"
  '((operator . "SMDEFAULTBENDLINEEXTENTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTBENDLINEEXTENTTYPE"))
  'int)

(deftest "sysvar-smdefaultbendlineextenttype-getvar-default"
  '((operator . "SMDEFAULTBENDLINEEXTENTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTBENDLINEEXTENTTYPE")
  0)

(deftest "sysvar-smdefaultbendlineextentvalue-getvar-type"
  '((operator . "SMDEFAULTBENDLINEEXTENTVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTBENDLINEEXTENTVALUE"))
  'real)

(deftest "sysvar-smdefaultbendlineextentvalue-getvar-default"
  '((operator . "SMDEFAULTBENDLINEEXTENTVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTBENDLINEEXTENTVALUE")
  0.25)

(deftest "sysvar-smdefaultbendradiustype-getvar-type"
  '((operator . "SMDEFAULTBENDRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTBENDRADIUSTYPE"))
  'int)

(deftest "sysvar-smdefaultbendradiustype-getvar-default"
  '((operator . "SMDEFAULTBENDRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTBENDRADIUSTYPE")
  2)

(deftest "sysvar-smdefaultbendradiusvalue-getvar-type"
  '((operator . "SMDEFAULTBENDRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTBENDRADIUSVALUE"))
  'real)

(deftest "sysvar-smdefaultbendradiusvalue-getvar-default"
  '((operator . "SMDEFAULTBENDRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTBENDRADIUSVALUE")
  1.0)

(deftest "sysvar-smdefaultbendreliefwidthtype-getvar-type"
  '((operator . "SMDEFAULTBENDRELIEFWIDTHTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMDEFAULTBENDRELIEFWIDTHTYPE"))
  'int)

(deftest "sysvar-smdefaultbendreliefwidthtype-getvar-default"
  '((operator . "SMDEFAULTBENDRELIEFWIDTHTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SMDEFAULTBENDRELIEFWIDTHTYPE")
  0)

(deftest "sysvar-smdefaultbendreliefwidthvalue-getvar-type"
  '((operator . "SMDEFAULTBENDRELIEFWIDTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTBENDRELIEFWIDTHVALUE"))
  'real)

(deftest "sysvar-smdefaultbendreliefwidthvalue-getvar-default"
  '((operator . "SMDEFAULTBENDRELIEFWIDTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTBENDRELIEFWIDTHVALUE")
  0.5)

(deftest "sysvar-smdefaultbevelfeatureunfoldmode-getvar-type"
  '((operator . "SMDEFAULTBEVELFEATUREUNFOLDMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTBEVELFEATUREUNFOLDMODE"))
  'int)

(deftest "sysvar-smdefaultbevelfeatureunfoldmode-getvar-default"
  '((operator . "SMDEFAULTBEVELFEATUREUNFOLDMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTBEVELFEATUREUNFOLDMODE")
  2)

(deftest "sysvar-smdefaultcornerreliefdiametervalue-getvar-type"
  '((operator . "SMDEFAULTCORNERRELIEFDIAMETERVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTCORNERRELIEFDIAMETERVALUE"))
  'real)

(deftest "sysvar-smdefaultcornerreliefdiametervalue-getvar-default"
  '((operator . "SMDEFAULTCORNERRELIEFDIAMETERVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTCORNERRELIEFDIAMETERVALUE")
  -1.0)

(deftest "sysvar-smdefaultflangesplitextensiontype-getvar-type"
  '((operator . "SMDEFAULTFLANGESPLITEXTENSIONTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMDEFAULTFLANGESPLITEXTENSIONTYPE"))
  'int)

(deftest "sysvar-smdefaultflangesplitextensiontype-getvar-default"
  '((operator . "SMDEFAULTFLANGESPLITEXTENSIONTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SMDEFAULTFLANGESPLITEXTENSIONTYPE")
  0)

(deftest "sysvar-smdefaultflangesplitextensionvalue-getvar-type"
  '((operator . "SMDEFAULTFLANGESPLITEXTENSIONVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTFLANGESPLITEXTENSIONVALUE"))
  'real)

(deftest "sysvar-smdefaultflangesplitextensionvalue-getvar-default"
  '((operator . "SMDEFAULTFLANGESPLITEXTENSIONVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTFLANGESPLITEXTENSIONVALUE")
  0.1)

(deftest "sysvar-smdefaultflangesplitgaptype-getvar-type"
  '((operator . "SMDEFAULTFLANGESPLITGAPTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTFLANGESPLITGAPTYPE"))
  'int)

(deftest "sysvar-smdefaultflangesplitgaptype-getvar-default"
  '((operator . "SMDEFAULTFLANGESPLITGAPTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTFLANGESPLITGAPTYPE")
  0)

(deftest "sysvar-smdefaultflangesplitgapvalue-getvar-type"
  '((operator . "SMDEFAULTFLANGESPLITGAPVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTFLANGESPLITGAPVALUE"))
  'real)

(deftest "sysvar-smdefaultflangesplitgapvalue-getvar-default"
  '((operator . "SMDEFAULTFLANGESPLITGAPVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTFLANGESPLITGAPVALUE")
  0.1)

(deftest "sysvar-smdefaultformfeatureunfoldmode-getvar-type"
  '((operator . "SMDEFAULTFORMFEATUREUNFOLDMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTFORMFEATUREUNFOLDMODE"))
  'int)

(deftest "sysvar-smdefaultformfeatureunfoldmode-getvar-default"
  '((operator . "SMDEFAULTFORMFEATUREUNFOLDMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTFORMFEATUREUNFOLDMODE")
  4)

(deftest "sysvar-smdefaultgussetdepthtype-getvar-type"
  '((operator . "SMDEFAULTGUSSETDEPTHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTGUSSETDEPTHTYPE"))
  'int)

(deftest "sysvar-smdefaultgussetdepthtype-getvar-default"
  '((operator . "SMDEFAULTGUSSETDEPTHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTGUSSETDEPTHTYPE")
  0)

(deftest "sysvar-smdefaultgussetdepthvalue-getvar-type"
  '((operator . "SMDEFAULTGUSSETDEPTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTGUSSETDEPTHVALUE"))
  'real)

(deftest "sysvar-smdefaultgussetdepthvalue-getvar-default"
  '((operator . "SMDEFAULTGUSSETDEPTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTGUSSETDEPTHVALUE")
  8.0)

(deftest "sysvar-smdefaultgussetfilletradiustype-getvar-type"
  '((operator . "SMDEFAULTGUSSETFILLETRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTGUSSETFILLETRADIUSTYPE"))
  'int)

(deftest "sysvar-smdefaultgussetfilletradiustype-getvar-default"
  '((operator . "SMDEFAULTGUSSETFILLETRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTGUSSETFILLETRADIUSTYPE")
  0)

(deftest "sysvar-smdefaultgussetfilletradiusvalue-getvar-type"
  '((operator . "SMDEFAULTGUSSETFILLETRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTGUSSETFILLETRADIUSVALUE"))
  'real)

(deftest "sysvar-smdefaultgussetfilletradiusvalue-getvar-default"
  '((operator . "SMDEFAULTGUSSETFILLETRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTGUSSETFILLETRADIUSVALUE")
  1.0)

(deftest "sysvar-smdefaultgussettype-getvar-type"
  '((operator . "SMDEFAULTGUSSETTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTGUSSETTYPE"))
  'int)

(deftest "sysvar-smdefaultgussettype-getvar-default"
  '((operator . "SMDEFAULTGUSSETTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTGUSSETTYPE")
  1)

(deftest "sysvar-smdefaultgussetwidthtype-getvar-type"
  '((operator . "SMDEFAULTGUSSETWIDTHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTGUSSETWIDTHTYPE"))
  'int)

(deftest "sysvar-smdefaultgussetwidthtype-getvar-default"
  '((operator . "SMDEFAULTGUSSETWIDTHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTGUSSETWIDTHTYPE")
  0)

(deftest "sysvar-smdefaultgussetwidthvalue-getvar-type"
  '((operator . "SMDEFAULTGUSSETWIDTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTGUSSETWIDTHVALUE"))
  'real)

(deftest "sysvar-smdefaultgussetwidthvalue-getvar-default"
  '((operator . "SMDEFAULTGUSSETWIDTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTGUSSETWIDTHVALUE")
  6.0)

(deftest "sysvar-smdefaulthemgaptype-getvar-type"
  '((operator . "SMDEFAULTHEMGAPTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTHEMGAPTYPE"))
  'int)

(deftest "sysvar-smdefaulthemgaptype-getvar-default"
  '((operator . "SMDEFAULTHEMGAPTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTHEMGAPTYPE")
  0)

(deftest "sysvar-smdefaulthemgapvalue-getvar-type"
  '((operator . "SMDEFAULTHEMGAPVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTHEMGAPVALUE"))
  'int)

(deftest "sysvar-smdefaulthemgapvalue-getvar-default"
  '((operator . "SMDEFAULTHEMGAPVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTHEMGAPVALUE")
  0)

(deftest "sysvar-smdefaulthemrelativebenddeduction-getvar-type"
  '((operator . "SMDEFAULTHEMRELATIVEBENDDEDUCTION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTHEMRELATIVEBENDDEDUCTION"))
  'real)

(deftest "sysvar-smdefaulthemrelativebenddeduction-getvar-default"
  '((operator . "SMDEFAULTHEMRELATIVEBENDDEDUCTION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTHEMRELATIVEBENDDEDUCTION")
  2.4)

(deftest "sysvar-smdefaultjoganglevalue-getvar-type"
  '((operator . "SMDEFAULTJOGANGLEVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTJOGANGLEVALUE"))
  'real)

(deftest "sysvar-smdefaultjoganglevalue-getvar-default"
  '((operator . "SMDEFAULTJOGANGLEVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTJOGANGLEVALUE")
  45.0)

(deftest "sysvar-smdefaultjogheighttype-getvar-type"
  '((operator . "SMDEFAULTJOGHEIGHTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTJOGHEIGHTTYPE"))
  'int)

(deftest "sysvar-smdefaultjogheighttype-getvar-default"
  '((operator . "SMDEFAULTJOGHEIGHTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTJOGHEIGHTTYPE")
  0)

(deftest "sysvar-smdefaultjogheightvalue-getvar-type"
  '((operator . "SMDEFAULTJOGHEIGHTVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTJOGHEIGHTVALUE"))
  'real)

(deftest "sysvar-smdefaultjogheightvalue-getvar-default"
  '((operator . "SMDEFAULTJOGHEIGHTVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTJOGHEIGHTVALUE")
  1.001)

(deftest "sysvar-smdefaultjogradiustype-getvar-type"
  '((operator . "SMDEFAULTJOGRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTJOGRADIUSTYPE"))
  'int)

(deftest "sysvar-smdefaultjogradiustype-getvar-default"
  '((operator . "SMDEFAULTJOGRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTJOGRADIUSTYPE")
  0)

(deftest "sysvar-smdefaultjogradiusvalue-getvar-type"
  '((operator . "SMDEFAULTJOGRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTJOGRADIUSVALUE"))
  'real)

(deftest "sysvar-smdefaultjogradiusvalue-getvar-default"
  '((operator . "SMDEFAULTJOGRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTJOGRADIUSVALUE")
  1.0)

(deftest "sysvar-smdefaultjunctionalignmenttorelief-getvar-type"
  '((operator . "SMDEFAULTJUNCTIONALIGNMENTTORELIEF") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTJUNCTIONALIGNMENTTORELIEF"))
  'int)

(deftest "sysvar-smdefaultjunctionalignmenttorelief-getvar-default"
  '((operator . "SMDEFAULTJUNCTIONALIGNMENTTORELIEF") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTJUNCTIONALIGNMENTTORELIEF")
  0)

(deftest "sysvar-smdefaultjunctiongaptype-getvar-type"
  '((operator . "SMDEFAULTJUNCTIONGAPTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTJUNCTIONGAPTYPE"))
  'int)

(deftest "sysvar-smdefaultjunctiongaptype-getvar-default"
  '((operator . "SMDEFAULTJUNCTIONGAPTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTJUNCTIONGAPTYPE")
  0)

(deftest "sysvar-smdefaultjunctiongapvalue-getvar-type"
  '((operator . "SMDEFAULTJUNCTIONGAPVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTJUNCTIONGAPVALUE"))
  'real)

(deftest "sysvar-smdefaultjunctiongapvalue-getvar-default"
  '((operator . "SMDEFAULTJUNCTIONGAPVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTJUNCTIONGAPVALUE")
  0.001)

(deftest "sysvar-smdefaultkfactor-getvar-type"
  '((operator . "SMDEFAULTKFACTOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTKFACTOR"))
  'real)

(deftest "sysvar-smdefaultkfactor-getvar-default"
  '((operator . "SMDEFAULTKFACTOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTKFACTOR")
  0.27324)

(deftest "sysvar-smdefaultloftedbendnumbersamples-getvar-type"
  '((operator . "SMDEFAULTLOFTEDBENDNUMBERSAMPLES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTLOFTEDBENDNUMBERSAMPLES"))
  'int)

(deftest "sysvar-smdefaultloftedbendnumbersamples-getvar-default"
  '((operator . "SMDEFAULTLOFTEDBENDNUMBERSAMPLES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTLOFTEDBENDNUMBERSAMPLES")
  10)

(deftest "sysvar-smdefaultreliefextensiontype-getvar-type"
  '((operator . "SMDEFAULTRELIEFEXTENSIONTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMDEFAULTRELIEFEXTENSIONTYPE"))
  'int)

(deftest "sysvar-smdefaultreliefextensiontype-getvar-default"
  '((operator . "SMDEFAULTRELIEFEXTENSIONTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SMDEFAULTRELIEFEXTENSIONTYPE")
  0)

(deftest "sysvar-smdefaultreliefextensionvalue-getvar-type"
  '((operator . "SMDEFAULTRELIEFEXTENSIONVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTRELIEFEXTENSIONVALUE"))
  'real)

(deftest "sysvar-smdefaultreliefextensionvalue-getvar-default"
  '((operator . "SMDEFAULTRELIEFEXTENSIONVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTRELIEFEXTENSIONVALUE")
  0.1)

(deftest "sysvar-smdefaultribfilletradiustype-getvar-type"
  '((operator . "SMDEFAULTRIBFILLETRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTRIBFILLETRADIUSTYPE"))
  'int)

(deftest "sysvar-smdefaultribfilletradiustype-getvar-default"
  '((operator . "SMDEFAULTRIBFILLETRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTRIBFILLETRADIUSTYPE")
  0)

(deftest "sysvar-smdefaultribfilletradiusvalue-getvar-type"
  '((operator . "SMDEFAULTRIBFILLETRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTRIBFILLETRADIUSVALUE"))
  'real)

(deftest "sysvar-smdefaultribfilletradiusvalue-getvar-default"
  '((operator . "SMDEFAULTRIBFILLETRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTRIBFILLETRADIUSVALUE")
  5.0)

(deftest "sysvar-smdefaultribprofileradiustype-getvar-type"
  '((operator . "SMDEFAULTRIBPROFILERADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTRIBPROFILERADIUSTYPE"))
  'int)

(deftest "sysvar-smdefaultribprofileradiustype-getvar-default"
  '((operator . "SMDEFAULTRIBPROFILERADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTRIBPROFILERADIUSTYPE")
  0)

(deftest "sysvar-smdefaultribprofileradiusvalue-getvar-type"
  '((operator . "SMDEFAULTRIBPROFILERADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTRIBPROFILERADIUSVALUE"))
  'real)

(deftest "sysvar-smdefaultribprofileradiusvalue-getvar-default"
  '((operator . "SMDEFAULTRIBPROFILERADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTRIBPROFILERADIUSVALUE")
  2.0)

(deftest "sysvar-smdefaultribroundradiustype-getvar-type"
  '((operator . "SMDEFAULTRIBROUNDRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTRIBROUNDRADIUSTYPE"))
  'int)

(deftest "sysvar-smdefaultribroundradiustype-getvar-default"
  '((operator . "SMDEFAULTRIBROUNDRADIUSTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTRIBROUNDRADIUSTYPE")
  0)

(deftest "sysvar-smdefaultribroundradiusvalue-getvar-type"
  '((operator . "SMDEFAULTRIBROUNDRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTRIBROUNDRADIUSVALUE"))
  'real)

(deftest "sysvar-smdefaultribroundradiusvalue-getvar-default"
  '((operator . "SMDEFAULTRIBROUNDRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTRIBROUNDRADIUSVALUE")
  1.0)

(deftest "sysvar-smdefaultsharpbendradiuslimitratio-getvar-type"
  '((operator . "SMDEFAULTSHARPBENDRADIUSLIMITRATIO") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTSHARPBENDRADIUSLIMITRATIO"))
  'real)

(deftest "sysvar-smdefaultsharpbendradiuslimitratio-getvar-default"
  '((operator . "SMDEFAULTSHARPBENDRADIUSLIMITRATIO") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTSHARPBENDRADIUSLIMITRATIO")
  5.0)

(deftest "sysvar-smdefaulttabchamferdistancetype-getvar-type"
  '((operator . "SMDEFAULTTABCHAMFERDISTANCETYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMDEFAULTTABCHAMFERDISTANCETYPE"))
  'int)

(deftest "sysvar-smdefaulttabchamferdistancetype-getvar-default"
  '((operator . "SMDEFAULTTABCHAMFERDISTANCETYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SMDEFAULTTABCHAMFERDISTANCETYPE")
  0)

(deftest "sysvar-smdefaulttabchamferdistancevalue-getvar-type"
  '((operator . "SMDEFAULTTABCHAMFERDISTANCEVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTTABCHAMFERDISTANCEVALUE"))
  'real)

(deftest "sysvar-smdefaulttabchamferdistancevalue-getvar-default"
  '((operator . "SMDEFAULTTABCHAMFERDISTANCEVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTTABCHAMFERDISTANCEVALUE")
  0.1)

(deftest "sysvar-smdefaulttabclearancetype-getvar-type"
  '((operator . "SMDEFAULTTABCLEARANCETYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMDEFAULTTABCLEARANCETYPE"))
  'int)

(deftest "sysvar-smdefaulttabclearancetype-getvar-default"
  '((operator . "SMDEFAULTTABCLEARANCETYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SMDEFAULTTABCLEARANCETYPE")
  0)

(deftest "sysvar-smdefaulttabclearancevalue-getvar-type"
  '((operator . "SMDEFAULTTABCLEARANCEVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTTABCLEARANCEVALUE"))
  'real)

(deftest "sysvar-smdefaulttabclearancevalue-getvar-default"
  '((operator . "SMDEFAULTTABCLEARANCEVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTTABCLEARANCEVALUE")
  0.1)

(deftest "sysvar-smdefaulttabdistancetype-getvar-type"
  '((operator . "SMDEFAULTTABDISTANCETYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMDEFAULTTABDISTANCETYPE"))
  'int)

(deftest "sysvar-smdefaulttabdistancetype-getvar-default"
  '((operator . "SMDEFAULTTABDISTANCETYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SMDEFAULTTABDISTANCETYPE")
  0)

(deftest "sysvar-smdefaulttabdistancevalue-getvar-type"
  '((operator . "SMDEFAULTTABDISTANCEVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTTABDISTANCEVALUE"))
  'real)

(deftest "sysvar-smdefaulttabdistancevalue-getvar-default"
  '((operator . "SMDEFAULTTABDISTANCEVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTTABDISTANCEVALUE")
  20.0)

(deftest "sysvar-smdefaulttabedgetype-getvar-type"
  '((operator . "SMDEFAULTTABEDGETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTTABEDGETYPE"))
  'int)

(deftest "sysvar-smdefaulttabedgetype-getvar-default"
  '((operator . "SMDEFAULTTABEDGETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTTABEDGETYPE")
  0)

(deftest "sysvar-smdefaulttabfilletradiustype-getvar-type"
  '((operator . "SMDEFAULTTABFILLETRADIUSTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMDEFAULTTABFILLETRADIUSTYPE"))
  'int)

(deftest "sysvar-smdefaulttabfilletradiustype-getvar-default"
  '((operator . "SMDEFAULTTABFILLETRADIUSTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SMDEFAULTTABFILLETRADIUSTYPE")
  0)

(deftest "sysvar-smdefaulttabfilletradiusvalue-getvar-type"
  '((operator . "SMDEFAULTTABFILLETRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTTABFILLETRADIUSVALUE"))
  'real)

(deftest "sysvar-smdefaulttabfilletradiusvalue-getvar-default"
  '((operator . "SMDEFAULTTABFILLETRADIUSVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTTABFILLETRADIUSVALUE")
  0.1)

(deftest "sysvar-smdefaulttabheighttype-getvar-type"
  '((operator . "SMDEFAULTTABHEIGHTTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMDEFAULTTABHEIGHTTYPE"))
  'int)

(deftest "sysvar-smdefaulttabheighttype-getvar-default"
  '((operator . "SMDEFAULTTABHEIGHTTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SMDEFAULTTABHEIGHTTYPE")
  0)

(deftest "sysvar-smdefaulttabheightvalue-getvar-type"
  '((operator . "SMDEFAULTTABHEIGHTVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTTABHEIGHTVALUE"))
  'real)

(deftest "sysvar-smdefaulttabheightvalue-getvar-default"
  '((operator . "SMDEFAULTTABHEIGHTVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTTABHEIGHTVALUE")
  1.0)

(deftest "sysvar-smdefaulttablengthtype-getvar-type"
  '((operator . "SMDEFAULTTABLENGTHTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMDEFAULTTABLENGTHTYPE"))
  'int)

(deftest "sysvar-smdefaulttablengthtype-getvar-default"
  '((operator . "SMDEFAULTTABLENGTHTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SMDEFAULTTABLENGTHTYPE")
  0)

(deftest "sysvar-smdefaulttablengthvalue-getvar-type"
  '((operator . "SMDEFAULTTABLENGTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTTABLENGTHVALUE"))
  'real)

(deftest "sysvar-smdefaulttablengthvalue-getvar-default"
  '((operator . "SMDEFAULTTABLENGTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTTABLENGTHVALUE")
  4.0)

(deftest "sysvar-smdefaulttabslotnumber-getvar-type"
  '((operator . "SMDEFAULTTABSLOTNUMBER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTTABSLOTNUMBER"))
  'int)

(deftest "sysvar-smdefaulttabslotnumber-getvar-default"
  '((operator . "SMDEFAULTTABSLOTNUMBER") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMDEFAULTTABSLOTNUMBER")
  2)

(deftest "sysvar-smdefaultthickness-getvar-type"
  '((operator . "SMDEFAULTTHICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMDEFAULTTHICKNESS"))
  'real)

(deftest "sysvar-smexportosmapproximationaccuracy-getvar-type"
  '((operator . "SMEXPORTOSMAPPROXIMATIONACCURACY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMEXPORTOSMAPPROXIMATIONACCURACY"))
  'real)

(deftest "sysvar-smexportosmminimaledgelength-getvar-type"
  '((operator . "SMEXPORTOSMMINIMALEDGELENGTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMEXPORTOSMMINIMALEDGELENGTH"))
  'real)

(deftest "sysvar-smformfeaturesdowncolor-getvar-type"
  '((operator . "SMFORMFEATURESDOWNCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMFORMFEATURESDOWNCOLOR"))
  'int)

(deftest "sysvar-smformfeaturesdowncolor-getvar-default"
  '((operator . "SMFORMFEATURESDOWNCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMFORMFEATURESDOWNCOLOR")
  6)

(deftest "sysvar-smformfeaturesdownlayerlinetype-getvar-type"
  '((operator . "SMFORMFEATURESDOWNLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMFORMFEATURESDOWNLAYERLINETYPE"))
  'str)

(deftest "sysvar-smformfeaturesdownlayerlinetype-getvar-default"
  '((operator . "SMFORMFEATURESDOWNLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMFORMFEATURESDOWNLAYERLINETYPE")
  "CONTINUOUS")

(deftest "sysvar-smformfeaturesdownlayerlineweight-getvar-type"
  '((operator . "SMFORMFEATURESDOWNLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMFORMFEATURESDOWNLAYERLINEWEIGHT"))
  'int)

(deftest "sysvar-smformfeaturesdownlayerlineweight-getvar-default"
  '((operator . "SMFORMFEATURESDOWNLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMFORMFEATURESDOWNLAYERLINEWEIGHT")
  -3)

(deftest "sysvar-smformfeaturesupcolor-getvar-type"
  '((operator . "SMFORMFEATURESUPCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMFORMFEATURESUPCOLOR"))
  'int)

(deftest "sysvar-smformfeaturesupcolor-getvar-default"
  '((operator . "SMFORMFEATURESUPCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMFORMFEATURESUPCOLOR")
  6)

(deftest "sysvar-smformfeaturesuplayerlinetype-getvar-type"
  '((operator . "SMFORMFEATURESUPLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMFORMFEATURESUPLAYERLINETYPE"))
  'str)

(deftest "sysvar-smformfeaturesuplayerlinetype-getvar-default"
  '((operator . "SMFORMFEATURESUPLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMFORMFEATURESUPLAYERLINETYPE")
  "CONTINUOUS")

(deftest "sysvar-smformfeaturesuplayerlineweight-getvar-type"
  '((operator . "SMFORMFEATURESUPLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMFORMFEATURESUPLAYERLINEWEIGHT"))
  'int)

(deftest "sysvar-smformfeaturesuplayerlineweight-getvar-default"
  '((operator . "SMFORMFEATURESUPLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMFORMFEATURESUPLAYERLINEWEIGHT")
  -3)

(deftest "sysvar-smhemcreateclosedhemgap-getvar-type"
  '((operator . "SMHEMCREATECLOSEDHEMGAP") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMHEMCREATECLOSEDHEMGAP"))
  'real)

(deftest "sysvar-smhemcreateclosedhemgap-getvar-default"
  '((operator . "SMHEMCREATECLOSEDHEMGAP") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMHEMCREATECLOSEDHEMGAP")
  0.02)

(deftest "sysvar-smjunctioncreatehealcoincident-getvar-type"
  '((operator . "SMJUNCTIONCREATEHEALCOINCIDENT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMJUNCTIONCREATEHEALCOINCIDENT"))
  'int)

(deftest "sysvar-smjunctioncreatehealcoincident-getvar-default"
  '((operator . "SMJUNCTIONCREATEHEALCOINCIDENT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMJUNCTIONCREATEHEALCOINCIDENT")
  0)

(deftest "sysvar-smoothmeshconvert-getvar-type"
  '((operator . "SMOOTHMESHCONVERT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMOOTHMESHCONVERT"))
  'int)

(deftest "sysvar-smoothmeshgrid-getvar-type"
  '((operator . "SMOOTHMESHGRID") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMOOTHMESHGRID"))
  'int)

(deftest "sysvar-smoothmeshgrid-getvar-default"
  '((operator . "SMOOTHMESHGRID") (area . "sysvar") (profile . STRICT))
  '(getvar "SMOOTHMESHGRID")
  3)

(deftest "sysvar-smoothmeshmaxface-getvar-type"
  '((operator . "SMOOTHMESHMAXFACE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMOOTHMESHMAXFACE"))
  'int)

(deftest "sysvar-smoothmeshmaxface-getvar-default"
  '((operator . "SMOOTHMESHMAXFACE") (area . "sysvar") (profile . STRICT))
  '(getvar "SMOOTHMESHMAXFACE")
  1000000)

(deftest "sysvar-smoothmeshmaxlev-getvar-type"
  '((operator . "SMOOTHMESHMAXLEV") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMOOTHMESHMAXLEV"))
  'int)

(deftest "sysvar-smoothmeshmaxlev-getvar-default"
  '((operator . "SMOOTHMESHMAXLEV") (area . "sysvar") (profile . STRICT))
  '(getvar "SMOOTHMESHMAXLEV")
  4)

(deftest "sysvar-smoverallannotationslayercolor-getvar-type"
  '((operator . "SMOVERALLANNOTATIONSLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMOVERALLANNOTATIONSLAYERCOLOR"))
  'int)

(deftest "sysvar-smoverallannotationslayercolor-getvar-default"
  '((operator . "SMOVERALLANNOTATIONSLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMOVERALLANNOTATIONSLAYERCOLOR")
  3)

(deftest "sysvar-smoverallannotationslayerlinetype-getvar-type"
  '((operator . "SMOVERALLANNOTATIONSLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMOVERALLANNOTATIONSLAYERLINETYPE"))
  'str)

(deftest "sysvar-smoverallannotationslayerlinetype-getvar-default"
  '((operator . "SMOVERALLANNOTATIONSLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMOVERALLANNOTATIONSLAYERLINETYPE")
  "CONTINUOUS")

(deftest "sysvar-smoverallannotationslayerlineweight-getvar-type"
  '((operator . "SMOVERALLANNOTATIONSLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMOVERALLANNOTATIONSLAYERLINEWEIGHT"))
  'int)

(deftest "sysvar-smoverallannotationslayerlineweight-getvar-default"
  '((operator . "SMOVERALLANNOTATIONSLAYERLINEWEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMOVERALLANNOTATIONSLAYERLINEWEIGHT")
  -3)

(deftest "sysvar-smparametrizeholesparametrization-getvar-type"
  '((operator . "SMPARAMETRIZEHOLESPARAMETRIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMPARAMETRIZEHOLESPARAMETRIZATION"))
  'int)

(deftest "sysvar-smparametrizeholesparametrization-getvar-default"
  '((operator . "SMPARAMETRIZEHOLESPARAMETRIZATION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMPARAMETRIZEHOLESPARAMETRIZATION")
  3)

(deftest "sysvar-smrepairloftedbendmerge-getvar-type"
  '((operator . "SMREPAIRLOFTEDBENDMERGE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMREPAIRLOFTEDBENDMERGE"))
  'int)

(deftest "sysvar-smrepairloftedbendmerge-getvar-default"
  '((operator . "SMREPAIRLOFTEDBENDMERGE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMREPAIRLOFTEDBENDMERGE")
  0)

(deftest "sysvar-smrollededgeannotationslayercolor-getvar-type"
  '((operator . "SMROLLEDEDGEANNOTATIONSLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMROLLEDEDGEANNOTATIONSLAYERCOLOR"))
  'int)

(deftest "sysvar-smrollededgeannotationslayercolor-getvar-default"
  '((operator . "SMROLLEDEDGEANNOTATIONSLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMROLLEDEDGEANNOTATIONSLAYERCOLOR")
  5)

(deftest "sysvar-smrollededgeannotationslayertextheight-getvar-type"
  '((operator . "SMROLLEDEDGEANNOTATIONSLAYERTEXTHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMROLLEDEDGEANNOTATIONSLAYERTEXTHEIGHT"))
  'real)

(deftest "sysvar-smrollededgeannotationslayertextheight-getvar-default"
  '((operator . "SMROLLEDEDGEANNOTATIONSLAYERTEXTHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMROLLEDEDGEANNOTATIONSLAYERTEXTHEIGHT")
  0.01)

(deftest "sysvar-smrollededgeannotationslayertextheighttype-getvar-type"
  '((operator . "SMROLLEDEDGEANNOTATIONSLAYERTEXTHEIGHTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMROLLEDEDGEANNOTATIONSLAYERTEXTHEIGHTTYPE"))
  'int)

(deftest "sysvar-smrollededgeannotationslayertextheighttype-getvar-default"
  '((operator . "SMROLLEDEDGEANNOTATIONSLAYERTEXTHEIGHTTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMROLLEDEDGEANNOTATIONSLAYERTEXTHEIGHTTYPE")
  0)

(deftest "sysvar-smrollededgelinesdownlayercolor-getvar-type"
  '((operator . "SMROLLEDEDGELINESDOWNLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMROLLEDEDGELINESDOWNLAYERCOLOR"))
  'int)

(deftest "sysvar-smrollededgelinesdownlayercolor-getvar-default"
  '((operator . "SMROLLEDEDGELINESDOWNLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMROLLEDEDGELINESDOWNLAYERCOLOR")
  1)

(deftest "sysvar-smrollededgelinesdownlayerlinetype-getvar-type"
  '((operator . "SMROLLEDEDGELINESDOWNLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMROLLEDEDGELINESDOWNLAYERLINETYPE"))
  'str)

(deftest "sysvar-smrollededgelinesdownlayerlinetype-getvar-default"
  '((operator . "SMROLLEDEDGELINESDOWNLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMROLLEDEDGELINESDOWNLAYERLINETYPE")
  "Continuous")

(deftest "sysvar-smrollededgelinesdownlayerlineweight-getvar-type"
  '((operator . "SMROLLEDEDGELINESDOWNLAYERLINEWEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMROLLEDEDGELINESDOWNLAYERLINEWEIGHT"))
  'int)

(deftest "sysvar-smrollededgelinesdownlayerlineweight-getvar-default"
  '((operator . "SMROLLEDEDGELINESDOWNLAYERLINEWEIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "SMROLLEDEDGELINESDOWNLAYERLINEWEIGHT")
  -3)

(deftest "sysvar-smrollededgelinesuplayercolor-getvar-type"
  '((operator . "SMROLLEDEDGELINESUPLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMROLLEDEDGELINESUPLAYERCOLOR"))
  'int)

(deftest "sysvar-smrollededgelinesuplayercolor-getvar-default"
  '((operator . "SMROLLEDEDGELINESUPLAYERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMROLLEDEDGELINESUPLAYERCOLOR")
  1)

(deftest "sysvar-smrollededgelinesuplayerlinetype-getvar-type"
  '((operator . "SMROLLEDEDGELINESUPLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMROLLEDEDGELINESUPLAYERLINETYPE"))
  'str)

(deftest "sysvar-smrollededgelinesuplayerlinetype-getvar-default"
  '((operator . "SMROLLEDEDGELINESUPLAYERLINETYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMROLLEDEDGELINESUPLAYERLINETYPE")
  "Continuous")

(deftest "sysvar-smrollededgelinesuplayerlineweight-getvar-type"
  '((operator . "SMROLLEDEDGELINESUPLAYERLINEWEIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SMROLLEDEDGELINESUPLAYERLINEWEIGHT"))
  'int)

(deftest "sysvar-smrollededgelinesuplayerlineweight-getvar-default"
  '((operator . "SMROLLEDEDGELINESUPLAYERLINEWEIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "SMROLLEDEDGELINESUPLAYERLINEWEIGHT")
  -3)

(deftest "sysvar-smsmartfeatures-getvar-type"
  '((operator . "SMSMARTFEATURES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMSMARTFEATURES"))
  'int)

(deftest "sysvar-smsmartfeatures-getvar-default"
  '((operator . "SMSMARTFEATURES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMSMARTFEATURES")
  3)

(deftest "sysvar-smsplitambiguousinput-getvar-type"
  '((operator . "SMSPLITAMBIGUOUSINPUT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMSPLITAMBIGUOUSINPUT"))
  'int)

(deftest "sysvar-smsplitambiguousinput-getvar-default"
  '((operator . "SMSPLITAMBIGUOUSINPUT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMSPLITAMBIGUOUSINPUT")
  0)

(deftest "sysvar-smsplitconvertbendtojunction-getvar-type"
  '((operator . "SMSPLITCONVERTBENDTOJUNCTION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMSPLITCONVERTBENDTOJUNCTION"))
  'int)

(deftest "sysvar-smsplitconvertbendtojunction-getvar-default"
  '((operator . "SMSPLITCONVERTBENDTOJUNCTION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMSPLITCONVERTBENDTOJUNCTION")
  1)

(deftest "sysvar-smsplithealcoincident-getvar-type"
  '((operator . "SMSPLITHEALCOINCIDENT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMSPLITHEALCOINCIDENT"))
  'int)

(deftest "sysvar-smsplithealcoincident-getvar-default"
  '((operator . "SMSPLITHEALCOINCIDENT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMSPLITHEALCOINCIDENT")
  0)

(deftest "sysvar-smsplitorthogonalbendsplit-getvar-type"
  '((operator . "SMSPLITORTHOGONALBENDSPLIT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMSPLITORTHOGONALBENDSPLIT"))
  'int)

(deftest "sysvar-smsplitorthogonalbendsplit-getvar-default"
  '((operator . "SMSPLITORTHOGONALBENDSPLIT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMSPLITORTHOGONALBENDSPLIT")
  0)

(deftest "sysvar-smtargetcam-getvar-type"
  '((operator . "SMTARGETCAM") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMTARGETCAM"))
  'str)

(deftest "sysvar-smunfoldappearance-getvar-type"
  '((operator . "SMUNFOLDAPPEARANCE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SMUNFOLDAPPEARANCE"))
  'int)

(deftest "sysvar-smunfoldappearance-getvar-default"
  '((operator . "SMUNFOLDAPPEARANCE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SMUNFOLDAPPEARANCE")
  1)

(deftest "sysvar-snapang-getvar-type"
  '((operator . "SNAPANG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SNAPANG"))
  'real)

(deftest "sysvar-snapbase-getvar-type"
  '((operator . "SNAPBASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SNAPBASE"))
  'list)

(deftest "sysvar-snapgridlegacy-getvar-type"
  '((operator . "SNAPGRIDLEGACY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SNAPGRIDLEGACY"))
  'int)

(deftest "sysvar-snapgridlegacy-getvar-default"
  '((operator . "SNAPGRIDLEGACY") (area . "sysvar") (profile . STRICT))
  '(getvar "SNAPGRIDLEGACY")
  0)

(deftest "sysvar-snapisopair-getvar-type"
  '((operator . "SNAPISOPAIR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SNAPISOPAIR"))
  'int)

(deftest "sysvar-snapmarkercolor-getvar-type"
  '((operator . "SNAPMARKERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SNAPMARKERCOLOR"))
  'int)

(deftest "sysvar-snapmarkercolor-getvar-default"
  '((operator . "SNAPMARKERCOLOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SNAPMARKERCOLOR")
  122)

(deftest "sysvar-snapmarkersize-getvar-type"
  '((operator . "SNAPMARKERSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SNAPMARKERSIZE"))
  'int)

(deftest "sysvar-snapmarkersize-getvar-default"
  '((operator . "SNAPMARKERSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SNAPMARKERSIZE")
  8)

(deftest "sysvar-snapmarkerthickness-getvar-type"
  '((operator . "SNAPMARKERTHICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SNAPMARKERTHICKNESS"))
  'int)

(deftest "sysvar-snapmarkerthickness-getvar-default"
  '((operator . "SNAPMARKERTHICKNESS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SNAPMARKERTHICKNESS")
  2)

(deftest "sysvar-snapmode-getvar-type"
  '((operator . "SNAPMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SNAPMODE"))
  'int)

(deftest "sysvar-snapmode-getvar-default"
  '((operator . "SNAPMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "SNAPMODE")
  0)

(deftest "sysvar-snapstyl-getvar-type"
  '((operator . "SNAPSTYL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SNAPSTYL"))
  'int)

(deftest "sysvar-snaptype-getvar-type"
  '((operator . "SNAPTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SNAPTYPE"))
  'int)

(deftest "sysvar-snapunit-getvar-type"
  '((operator . "SNAPUNIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SNAPUNIT"))
  'list)

(deftest "sysvar-solidcheck-getvar-type"
  '((operator . "SOLIDCHECK") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SOLIDCHECK"))
  'int)

(deftest "sysvar-solidcheck-getvar-default"
  '((operator . "SOLIDCHECK") (area . "sysvar") (profile . STRICT))
  '(getvar "SOLIDCHECK")
  1)

(deftest "sysvar-solidhist-getvar-type"
  '((operator . "SOLIDHIST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SOLIDHIST"))
  'int)

(deftest "sysvar-solidhist-getvar-default"
  '((operator . "SOLIDHIST") (area . "sysvar") (profile . STRICT))
  '(getvar "SOLIDHIST")
  0)

(deftest "sysvar-sortents-getvar-type"
  '((operator . "SORTENTS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SORTENTS"))
  'int)

(deftest "sysvar-sortorder-getvar-type"
  '((operator . "SORTORDER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SORTORDER"))
  'int)

(deftest "sysvar-sortorder-getvar-default"
  '((operator . "SORTORDER") (area . "sysvar") (profile . STRICT))
  '(getvar "SORTORDER")
  1)

(deftest "sysvar-spaadjustmode-getvar-type"
  '((operator . "SPAADJUSTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPAADJUSTMODE"))
  'int)

(deftest "sysvar-spaadjustmode-getvar-default"
  '((operator . "SPAADJUSTMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPAADJUSTMODE")
  0)

(deftest "sysvar-spaceswitch-getvar-type"
  '((operator . "SPACESWITCH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SPACESWITCH"))
  'int)

(deftest "sysvar-spaceswitch-getvar-default"
  '((operator . "SPACESWITCH") (area . "sysvar") (profile . STRICT))
  '(getvar "SPACESWITCH")
  1)

(deftest "sysvar-spachecklevel-getvar-type"
  '((operator . "SPACHECKLEVEL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPACHECKLEVEL"))
  'int)

(deftest "sysvar-spachecklevel-getvar-default"
  '((operator . "SPACHECKLEVEL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPACHECKLEVEL")
  10)

(deftest "sysvar-spagridaspectratio-getvar-type"
  '((operator . "SPAGRIDASPECTRATIO") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPAGRIDASPECTRATIO"))
  'real)

(deftest "sysvar-spagridaspectratio-getvar-default"
  '((operator . "SPAGRIDASPECTRATIO") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPAGRIDASPECTRATIO")
  0.0)

(deftest "sysvar-spagridmode-getvar-type"
  '((operator . "SPAGRIDMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPAGRIDMODE"))
  'int)

(deftest "sysvar-spagridmode-getvar-default"
  '((operator . "SPAGRIDMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPAGRIDMODE")
  1)

(deftest "sysvar-spamaxfacetedgelength-getvar-type"
  '((operator . "SPAMAXFACETEDGELENGTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPAMAXFACETEDGELENGTH"))
  'real)

(deftest "sysvar-spamaxfacetedgelength-getvar-default"
  '((operator . "SPAMAXFACETEDGELENGTH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPAMAXFACETEDGELENGTH")
  0.0)

(deftest "sysvar-spamaxnumgridlines-getvar-type"
  '((operator . "SPAMAXNUMGRIDLINES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPAMAXNUMGRIDLINES"))
  'int)

(deftest "sysvar-spamaxnumgridlines-getvar-default"
  '((operator . "SPAMAXNUMGRIDLINES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPAMAXNUMGRIDLINES")
  3000)

(deftest "sysvar-spaminugridlines-getvar-type"
  '((operator . "SPAMINUGRIDLINES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPAMINUGRIDLINES"))
  'int)

(deftest "sysvar-spaminugridlines-getvar-default"
  '((operator . "SPAMINUGRIDLINES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPAMINUGRIDLINES")
  0)

(deftest "sysvar-spaminvgridlines-getvar-type"
  '((operator . "SPAMINVGRIDLINES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPAMINVGRIDLINES"))
  'int)

(deftest "sysvar-spaminvgridlines-getvar-default"
  '((operator . "SPAMINVGRIDLINES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPAMINVGRIDLINES")
  0)

(deftest "sysvar-spanormaltol-getvar-type"
  '((operator . "SPANORMALTOL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPANORMALTOL"))
  'real)

(deftest "sysvar-spanormaltol-getvar-default"
  '((operator . "SPANORMALTOL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPANORMALTOL")
  15.0)

(deftest "sysvar-spasurfacetol-getvar-type"
  '((operator . "SPASURFACETOL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPASURFACETOL"))
  'real)

(deftest "sysvar-spasurfacetol-getvar-default"
  '((operator . "SPASURFACETOL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPASURFACETOL")
  -1.0)

(deftest "sysvar-spatriangmode-getvar-type"
  '((operator . "SPATRIANGMODE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPATRIANGMODE"))
  'int)

(deftest "sysvar-spatriangmode-getvar-default"
  '((operator . "SPATRIANGMODE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPATRIANGMODE")
  1)

(deftest "sysvar-spausefacetres-getvar-type"
  '((operator . "SPAUSEFACETRES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SPAUSEFACETRES"))
  'int)

(deftest "sysvar-spausefacetres-getvar-default"
  '((operator . "SPAUSEFACETRES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SPAUSEFACETRES")
  1)

(deftest "sysvar-spldegree-getvar-type"
  '((operator . "SPLDEGREE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SPLDEGREE"))
  'int)

(deftest "sysvar-spldegree-getvar-default"
  '((operator . "SPLDEGREE") (area . "sysvar") (profile . STRICT))
  '(getvar "SPLDEGREE")
  3)

(deftest "sysvar-splframe-getvar-type"
  '((operator . "SPLFRAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SPLFRAME"))
  'int)

(deftest "sysvar-splframe-getvar-default"
  '((operator . "SPLFRAME") (area . "sysvar") (profile . STRICT))
  '(getvar "SPLFRAME")
  0)

(deftest "sysvar-splinesegs-getvar-type"
  '((operator . "SPLINESEGS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SPLINESEGS"))
  'int)

(deftest "sysvar-splinetype-getvar-type"
  '((operator . "SPLINETYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SPLINETYPE"))
  'int)

(deftest "sysvar-splinetype-getvar-default"
  '((operator . "SPLINETYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "SPLINETYPE")
  6)

(deftest "sysvar-splknots-getvar-type"
  '((operator . "SPLKNOTS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SPLKNOTS"))
  'int)

(deftest "sysvar-splknots-getvar-default"
  '((operator . "SPLKNOTS") (area . "sysvar") (profile . STRICT))
  '(getvar "SPLKNOTS")
  0)

(deftest "sysvar-splmethod-getvar-type"
  '((operator . "SPLMETHOD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SPLMETHOD"))
  'int)

(deftest "sysvar-splmethod-getvar-default"
  '((operator . "SPLMETHOD") (area . "sysvar") (profile . STRICT))
  '(getvar "SPLMETHOD")
  0)

(deftest "sysvar-splperiodic-getvar-type"
  '((operator . "SPLPERIODIC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SPLPERIODIC"))
  'int)

(deftest "sysvar-splperiodic-getvar-default"
  '((operator . "SPLPERIODIC") (area . "sysvar") (profile . STRICT))
  '(getvar "SPLPERIODIC")
  1)

(deftest "sysvar-srchpath-getvar-type"
  '((operator . "SRCHPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SRCHPATH"))
  'str)

(deftest "sysvar-ssfound-getvar-type"
  '((operator . "SSFOUND") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SSFOUND"))
  'str)

(deftest-error "sysvar-ssfound-setvar-readonly-signals"
  '((operator . "SSFOUND") (area . "sysvar") (profile . STRICT))
  '(setvar "SSFOUND" "")
  'sysvar-read-only)

(deftest "sysvar-sslocate-getvar-type"
  '((operator . "SSLOCATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SSLOCATE"))
  'int)

(deftest "sysvar-ssmautoopen-getvar-type"
  '((operator . "SSMAUTOOPEN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SSMAUTOOPEN"))
  'int)

(deftest "sysvar-ssmopenmode-getvar-type"
  '((operator . "SSMOPENMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SSMOPENMODE"))
  'int)

(deftest "sysvar-ssmopenmode-getvar-default"
  '((operator . "SSMOPENMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "SSMOPENMODE")
  0)

(deftest "sysvar-ssmpolltime-getvar-type"
  '((operator . "SSMPOLLTIME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SSMPOLLTIME"))
  'int)

(deftest "sysvar-ssmsheetstatus-getvar-type"
  '((operator . "SSMSHEETSTATUS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SSMSHEETSTATUS"))
  'int)

(deftest "sysvar-ssmstate-getvar-type"
  '((operator . "SSMSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SSMSTATE"))
  'int)

(deftest-error "sysvar-ssmstate-setvar-readonly-signals"
  '((operator . "SSMSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "SSMSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-stackpaneltype-getvar-type"
  '((operator . "STACKPANELTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STACKPANELTYPE"))
  'int)

(deftest "sysvar-stackpaneltype-getvar-default"
  '((operator . "STACKPANELTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STACKPANELTYPE")
  2)

(deftest "sysvar-stampfontsize-getvar-type"
  '((operator . "STAMPFONTSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STAMPFONTSIZE"))
  'real)

(deftest "sysvar-stampfontsize-getvar-default"
  '((operator . "STAMPFONTSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STAMPFONTSIZE")
  0.2)

(deftest "sysvar-stampfontstyle-getvar-type"
  '((operator . "STAMPFONTSTYLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STAMPFONTSTYLE"))
  'str)

(deftest "sysvar-stampfontstyle-getvar-default"
  '((operator . "STAMPFONTSTYLE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STAMPFONTSTYLE")
  "Arial")

(deftest "sysvar-stampfooter-getvar-type"
  '((operator . "STAMPFOOTER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STAMPFOOTER"))
  'str)

(deftest "sysvar-stampfooteroffsetx-getvar-type"
  '((operator . "STAMPFOOTEROFFSETX") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STAMPFOOTEROFFSETX"))
  'real)

(deftest "sysvar-stampfooteroffsetx-getvar-default"
  '((operator . "STAMPFOOTEROFFSETX") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STAMPFOOTEROFFSETX")
  0.0)

(deftest "sysvar-stampfooteroffsety-getvar-type"
  '((operator . "STAMPFOOTEROFFSETY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STAMPFOOTEROFFSETY"))
  'real)

(deftest "sysvar-stampfooteroffsety-getvar-default"
  '((operator . "STAMPFOOTEROFFSETY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STAMPFOOTEROFFSETY")
  0.0)

(deftest "sysvar-stampheader-getvar-type"
  '((operator . "STAMPHEADER") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STAMPHEADER"))
  'str)

(deftest "sysvar-stampheaderoffsetx-getvar-type"
  '((operator . "STAMPHEADEROFFSETX") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STAMPHEADEROFFSETX"))
  'real)

(deftest "sysvar-stampheaderoffsetx-getvar-default"
  '((operator . "STAMPHEADEROFFSETX") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STAMPHEADEROFFSETX")
  0.0)

(deftest "sysvar-stampheaderoffsety-getvar-type"
  '((operator . "STAMPHEADEROFFSETY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STAMPHEADEROFFSETY"))
  'real)

(deftest "sysvar-stampheaderoffsety-getvar-default"
  '((operator . "STAMPHEADEROFFSETY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STAMPHEADEROFFSETY")
  0.0)

(deftest "sysvar-stampunits-getvar-type"
  '((operator . "STAMPUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STAMPUNITS"))
  'int)

(deftest "sysvar-stampunits-getvar-default"
  '((operator . "STAMPUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STAMPUNITS")
  0)

(deftest "sysvar-standardsoptions-getvar-type"
  '((operator . "STANDARDSOPTIONS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "STANDARDSOPTIONS"))
  'int)

(deftest "sysvar-standardsoptions-getvar-default"
  '((operator . "STANDARDSOPTIONS") (area . "sysvar") (profile . STRICT))
  '(getvar "STANDARDSOPTIONS")
  0)

(deftest "sysvar-standardsviolation-getvar-type"
  '((operator . "STANDARDSVIOLATION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "STANDARDSVIOLATION"))
  'int)

(deftest "sysvar-startinfolder-getvar-type"
  '((operator . "STARTINFOLDER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "STARTINFOLDER"))
  'str)

(deftest-error "sysvar-startinfolder-setvar-readonly-signals"
  '((operator . "STARTINFOLDER") (area . "sysvar") (profile . STRICT))
  '(setvar "STARTINFOLDER" "")
  'sysvar-read-only)

(deftest "sysvar-startmode-getvar-type"
  '((operator . "STARTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "STARTMODE"))
  'int)

(deftest "sysvar-startmode-getvar-default"
  '((operator . "STARTMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "STARTMODE")
  1)

(deftest "sysvar-startup-getvar-type"
  '((operator . "STARTUP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "STARTUP"))
  'int)

(deftest "sysvar-statusbar-getvar-type"
  '((operator . "STATUSBAR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "STATUSBAR"))
  'int)

(deftest "sysvar-statusbar-getvar-default"
  '((operator . "STATUSBAR") (area . "sysvar") (profile . STRICT))
  '(getvar "STATUSBAR")
  1)

(deftest "sysvar-stepsize-getvar-type"
  '((operator . "STEPSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "STEPSIZE"))
  'real)

(deftest "sysvar-stepspersec-getvar-type"
  '((operator . "STEPSPERSEC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "STEPSPERSEC"))
  'real)

(deftest "sysvar-stlpositivequadrant-getvar-type"
  '((operator . "STLPOSITIVEQUADRANT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STLPOSITIVEQUADRANT"))
  'int)

(deftest "sysvar-stlpositivequadrant-getvar-default"
  '((operator . "STLPOSITIVEQUADRANT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STLPOSITIVEQUADRANT")
  1)

(deftest "sysvar-storybar-getvar-type"
  '((operator . "STORYBAR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STORYBAR"))
  'int)

(deftest "sysvar-storybar-getvar-default"
  '((operator . "STORYBAR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STORYBAR")
  0)

(deftest "sysvar-structuretreeconfig-getvar-type"
  '((operator . "STRUCTURETREECONFIG") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "STRUCTURETREECONFIG"))
  'str)

(deftest "sysvar-structuretreeconfig-getvar-default"
  '((operator . "STRUCTURETREECONFIG") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "STRUCTURETREECONFIG")
  "default.cst")

(deftest "sysvar-studentdrawing-getvar-type"
  '((operator . "STUDENTDRAWING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "STUDENTDRAWING"))
  'int)

(deftest-error "sysvar-studentdrawing-setvar-readonly-signals"
  '((operator . "STUDENTDRAWING") (area . "sysvar") (profile . STRICT))
  '(setvar "STUDENTDRAWING" 0)
  'sysvar-read-only)

(deftest "sysvar-stylusforcethreshold-getvar-type"
  '((operator . "STYLUSFORCETHRESHOLD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "STYLUSFORCETHRESHOLD"))
  'int)

(deftest "sysvar-stylusforcethreshold-getvar-default"
  '((operator . "STYLUSFORCETHRESHOLD") (area . "sysvar") (profile . STRICT))
  '(getvar "STYLUSFORCETHRESHOLD")
  2)

(deftest "sysvar-subobjselectionmode-getvar-type"
  '((operator . "SUBOBJSELECTIONMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SUBOBJSELECTIONMODE"))
  'int)

(deftest "sysvar-subobjselectionmode-getvar-default"
  '((operator . "SUBOBJSELECTIONMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "SUBOBJSELECTIONMODE")
  0)

(deftest "sysvar-sunpropertiesstate-getvar-type"
  '((operator . "SUNPROPERTIESSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SUNPROPERTIESSTATE"))
  'int)

(deftest-error "sysvar-sunpropertiesstate-setvar-readonly-signals"
  '((operator . "SUNPROPERTIESSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "SUNPROPERTIESSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-sunstatus-getvar-type"
  '((operator . "SUNSTATUS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SUNSTATUS"))
  'int)

(deftest "sysvar-sunstatus-getvar-default"
  '((operator . "SUNSTATUS") (area . "sysvar") (profile . STRICT))
  '(getvar "SUNSTATUS")
  0)

(deftest "sysvar-suppressalerts-getvar-type"
  '((operator . "SUPPRESSALERTS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SUPPRESSALERTS"))
  'int)

(deftest "sysvar-suppressalerts-getvar-default"
  '((operator . "SUPPRESSALERTS") (area . "sysvar") (profile . STRICT))
  '(getvar "SUPPRESSALERTS")
  0)

(deftest "sysvar-surfaceassociativity-getvar-type"
  '((operator . "SURFACEASSOCIATIVITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SURFACEASSOCIATIVITY"))
  'int)

(deftest "sysvar-surfaceassociativity-getvar-default"
  '((operator . "SURFACEASSOCIATIVITY") (area . "sysvar") (profile . STRICT))
  '(getvar "SURFACEASSOCIATIVITY")
  1)

(deftest "sysvar-surfaceassociativitydrag-getvar-type"
  '((operator . "SURFACEASSOCIATIVITYDRAG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SURFACEASSOCIATIVITYDRAG"))
  'int)

(deftest "sysvar-surfaceassociativitydrag-getvar-default"
  '((operator . "SURFACEASSOCIATIVITYDRAG") (area . "sysvar") (profile . STRICT))
  '(getvar "SURFACEASSOCIATIVITYDRAG")
  1)

(deftest "sysvar-surfaceautotrim-getvar-type"
  '((operator . "SURFACEAUTOTRIM") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SURFACEAUTOTRIM"))
  'int)

(deftest "sysvar-surfaceautotrim-getvar-default"
  '((operator . "SURFACEAUTOTRIM") (area . "sysvar") (profile . STRICT))
  '(getvar "SURFACEAUTOTRIM")
  0)

(deftest "sysvar-surfacemodelingmode-getvar-type"
  '((operator . "SURFACEMODELINGMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SURFACEMODELINGMODE"))
  'int)

(deftest "sysvar-surfacemodelingmode-getvar-default"
  '((operator . "SURFACEMODELINGMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "SURFACEMODELINGMODE")
  0)

(deftest "sysvar-surftab1-getvar-type"
  '((operator . "SURFTAB1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SURFTAB1"))
  'int)

(deftest "sysvar-surftab2-getvar-type"
  '((operator . "SURFTAB2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SURFTAB2"))
  'int)

(deftest "sysvar-surftab2-getvar-default"
  '((operator . "SURFTAB2") (area . "sysvar") (profile . STRICT))
  '(getvar "SURFTAB2")
  6)

(deftest "sysvar-surftype-getvar-type"
  '((operator . "SURFTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SURFTYPE"))
  'int)

(deftest "sysvar-surfu-getvar-type"
  '((operator . "SURFU") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SURFU"))
  'int)

(deftest "sysvar-surfv-getvar-type"
  '((operator . "SURFV") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SURFV"))
  'int)

(deftest "sysvar-svgblendedgradients-getvar-type"
  '((operator . "SVGBLENDEDGRADIENTS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGBLENDEDGRADIENTS"))
  'int)

(deftest "sysvar-svgblendedgradients-getvar-default"
  '((operator . "SVGBLENDEDGRADIENTS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SVGBLENDEDGRADIENTS")
  0)

(deftest "sysvar-svgcolorpolicy-getvar-type"
  '((operator . "SVGCOLORPOLICY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGCOLORPOLICY"))
  'int)

(deftest "sysvar-svgcolorpolicy-getvar-default"
  '((operator . "SVGCOLORPOLICY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SVGCOLORPOLICY")
  1)

(deftest "sysvar-svgdefaultimageextension-getvar-type"
  '((operator . "SVGDEFAULTIMAGEEXTENSION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGDEFAULTIMAGEEXTENSION"))
  'str)

(deftest "sysvar-svgdefaultimageextension-getvar-default"
  '((operator . "SVGDEFAULTIMAGEEXTENSION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SVGDEFAULTIMAGEEXTENSION")
  ".png")

(deftest "sysvar-svggenericfontfamily-getvar-type"
  '((operator . "SVGGENERICFONTFAMILY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGGENERICFONTFAMILY"))
  'int)

(deftest "sysvar-svggenericfontfamily-getvar-default"
  '((operator . "SVGGENERICFONTFAMILY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SVGGENERICFONTFAMILY")
  0)

(deftest "sysvar-svgimagebase-getvar-type"
  '((operator . "SVGIMAGEBASE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGIMAGEBASE"))
  'str)

(deftest "sysvar-svgimageurl-getvar-type"
  '((operator . "SVGIMAGEURL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGIMAGEURL"))
  'str)

(deftest "sysvar-svglineweightscale-getvar-type"
  '((operator . "SVGLINEWEIGHTSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGLINEWEIGHTSCALE"))
  'real)

(deftest "sysvar-svglineweightscale-getvar-default"
  '((operator . "SVGLINEWEIGHTSCALE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SVGLINEWEIGHTSCALE")
  1.0)

(deftest "sysvar-svgoutputheight-getvar-type"
  '((operator . "SVGOUTPUTHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGOUTPUTHEIGHT"))
  'int)

(deftest "sysvar-svgoutputheight-getvar-default"
  '((operator . "SVGOUTPUTHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SVGOUTPUTHEIGHT")
  768)

(deftest "sysvar-svgoutputwidth-getvar-type"
  '((operator . "SVGOUTPUTWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGOUTPUTWIDTH"))
  'int)

(deftest "sysvar-svgoutputwidth-getvar-default"
  '((operator . "SVGOUTPUTWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SVGOUTPUTWIDTH")
  1024)

(deftest "sysvar-svgprecision-getvar-type"
  '((operator . "SVGPRECISION") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGPRECISION"))
  'int)

(deftest "sysvar-svgprecision-getvar-default"
  '((operator . "SVGPRECISION") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SVGPRECISION")
  6)

(deftest "sysvar-svgscalefactor-getvar-type"
  '((operator . "SVGSCALEFACTOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "SVGSCALEFACTOR"))
  'real)

(deftest "sysvar-svgscalefactor-getvar-default"
  '((operator . "SVGSCALEFACTOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "SVGSCALEFACTOR")
  0.0)

(deftest "sysvar-syscodepage-getvar-type"
  '((operator . "SYSCODEPAGE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SYSCODEPAGE"))
  'str)

(deftest-error "sysvar-syscodepage-setvar-readonly-signals"
  '((operator . "SYSCODEPAGE") (area . "sysvar") (profile . STRICT))
  '(setvar "SYSCODEPAGE" "")
  'sysvar-read-only)

(deftest "sysvar-sysfloating-getvar-type"
  '((operator . "SYSFLOATING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SYSFLOATING"))
  'int)

(deftest "sysvar-sysfloating-getvar-default"
  '((operator . "SYSFLOATING") (area . "sysvar") (profile . STRICT))
  '(getvar "SYSFLOATING")
  0)

(deftest "sysvar-sysmon-getvar-type"
  '((operator . "SYSMON") (area . "sysvar") (profile . STRICT))
  '(type (getvar "SYSMON"))
  'int)

(deftest "sysvar-sysmon-getvar-default"
  '((operator . "SYSMON") (area . "sysvar") (profile . STRICT))
  '(getvar "SYSMON")
  1)

(deftest "sysvar-tabcontrolheight-getvar-type"
  '((operator . "TABCONTROLHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TABCONTROLHEIGHT"))
  'int)

(deftest "sysvar-tabcontrolheight-getvar-default"
  '((operator . "TABCONTROLHEIGHT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TABCONTROLHEIGHT")
  25)

(deftest "sysvar-tableindicator-getvar-type"
  '((operator . "TABLEINDICATOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TABLEINDICATOR"))
  'int)

(deftest "sysvar-tableindicator-getvar-default"
  '((operator . "TABLEINDICATOR") (area . "sysvar") (profile . STRICT))
  '(getvar "TABLEINDICATOR")
  1)

(deftest "sysvar-tablelayer-getvar-type"
  '((operator . "TABLELAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TABLELAYER"))
  'str)

(deftest "sysvar-tablelayer-getvar-default"
  '((operator . "TABLELAYER") (area . "sysvar") (profile . STRICT))
  '(getvar "TABLELAYER")
  "\"use current\"")

(deftest "sysvar-tabletoolbar-getvar-type"
  '((operator . "TABLETOOLBAR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TABLETOOLBAR"))
  'int)

(deftest "sysvar-tabletoolbar-getvar-default"
  '((operator . "TABLETOOLBAR") (area . "sysvar") (profile . STRICT))
  '(getvar "TABLETOOLBAR")
  2)

(deftest "sysvar-tabmode-getvar-type"
  '((operator . "TABMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TABMODE"))
  'int)

(deftest "sysvar-tabmode-getvar-default"
  '((operator . "TABMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "TABMODE")
  0)

(deftest "sysvar-tabsfixedwidth-getvar-type"
  '((operator . "TABSFIXEDWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TABSFIXEDWIDTH"))
  'int)

(deftest "sysvar-tabsfixedwidth-getvar-default"
  '((operator . "TABSFIXEDWIDTH") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TABSFIXEDWIDTH")
  0)

(deftest "sysvar-tangentlengthtype-getvar-type"
  '((operator . "TANGENTLENGTHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TANGENTLENGTHTYPE"))
  'int)

(deftest "sysvar-tangentlengthtype-getvar-default"
  '((operator . "TANGENTLENGTHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TANGENTLENGTHTYPE")
  0)

(deftest "sysvar-tangentlengthvalue-getvar-type"
  '((operator . "TANGENTLENGTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TANGENTLENGTHVALUE"))
  'real)

(deftest "sysvar-tangentlengthvalue-getvar-default"
  '((operator . "TANGENTLENGTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TANGENTLENGTHVALUE")
  0.0)

(deftest "sysvar-target-getvar-type"
  '((operator . "TARGET") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TARGET"))
  'list)

(deftest-error "sysvar-target-setvar-readonly-signals"
  '((operator . "TARGET") (area . "sysvar") (profile . STRICT))
  '(setvar "TARGET" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-tbcustomize-getvar-type"
  '((operator . "TBCUSTOMIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TBCUSTOMIZE"))
  'int)

(deftest "sysvar-tbcustomize-getvar-default"
  '((operator . "TBCUSTOMIZE") (area . "sysvar") (profile . STRICT))
  '(getvar "TBCUSTOMIZE")
  1)

(deftest "sysvar-tbshowshortcuts-getvar-type"
  '((operator . "TBSHOWSHORTCUTS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TBSHOWSHORTCUTS"))
  'str)

(deftest "sysvar-tbshowshortcuts-getvar-default"
  '((operator . "TBSHOWSHORTCUTS") (area . "sysvar") (profile . STRICT))
  '(getvar "TBSHOWSHORTCUTS")
  "YES")

(deftest "sysvar-tdcreate-getvar-type"
  '((operator . "TDCREATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TDCREATE"))
  'real)

(deftest-error "sysvar-tdcreate-setvar-readonly-signals"
  '((operator . "TDCREATE") (area . "sysvar") (profile . STRICT))
  '(setvar "TDCREATE" 0.0)
  'sysvar-read-only)

(deftest "sysvar-tdindwg-getvar-type"
  '((operator . "TDINDWG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TDINDWG"))
  'real)

(deftest-error "sysvar-tdindwg-setvar-readonly-signals"
  '((operator . "TDINDWG") (area . "sysvar") (profile . STRICT))
  '(setvar "TDINDWG" 0.0)
  'sysvar-read-only)

(deftest "sysvar-tducreate-getvar-type"
  '((operator . "TDUCREATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TDUCREATE"))
  'real)

(deftest-error "sysvar-tducreate-setvar-readonly-signals"
  '((operator . "TDUCREATE") (area . "sysvar") (profile . STRICT))
  '(setvar "TDUCREATE" 0.0)
  'sysvar-read-only)

(deftest "sysvar-tdupdate-getvar-type"
  '((operator . "TDUPDATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TDUPDATE"))
  'real)

(deftest-error "sysvar-tdupdate-setvar-readonly-signals"
  '((operator . "TDUPDATE") (area . "sysvar") (profile . STRICT))
  '(setvar "TDUPDATE" 0.0)
  'sysvar-read-only)

(deftest "sysvar-tdusrtimer-getvar-type"
  '((operator . "TDUSRTIMER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TDUSRTIMER"))
  'real)

(deftest-error "sysvar-tdusrtimer-setvar-readonly-signals"
  '((operator . "TDUSRTIMER") (area . "sysvar") (profile . STRICT))
  '(setvar "TDUSRTIMER" 0.0)
  'sysvar-read-only)

(deftest "sysvar-tduupdate-getvar-type"
  '((operator . "TDUUPDATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TDUUPDATE"))
  'real)

(deftest-error "sysvar-tduupdate-setvar-readonly-signals"
  '((operator . "TDUUPDATE") (area . "sysvar") (profile . STRICT))
  '(setvar "TDUUPDATE" 0.0)
  'sysvar-read-only)

(deftest "sysvar-teetangentlengthtype-getvar-type"
  '((operator . "TEETANGENTLENGTHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TEETANGENTLENGTHTYPE"))
  'int)

(deftest "sysvar-teetangentlengthtype-getvar-default"
  '((operator . "TEETANGENTLENGTHTYPE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TEETANGENTLENGTHTYPE")
  0)

(deftest "sysvar-teetangentlengthvalue-getvar-type"
  '((operator . "TEETANGENTLENGTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TEETANGENTLENGTHVALUE"))
  'real)

(deftest "sysvar-teetangentlengthvalue-getvar-default"
  '((operator . "TEETANGENTLENGTHVALUE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TEETANGENTLENGTHVALUE")
  0.5)

(deftest "sysvar-templatepath-getvar-type"
  '((operator . "TEMPLATEPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TEMPLATEPATH"))
  'str)

(deftest "sysvar-tempoverrides-getvar-type"
  '((operator . "TEMPOVERRIDES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEMPOVERRIDES"))
  'int)

(deftest "sysvar-tempoverrides-getvar-default"
  '((operator . "TEMPOVERRIDES") (area . "sysvar") (profile . STRICT))
  '(getvar "TEMPOVERRIDES")
  1)

(deftest "sysvar-tempprefix-getvar-type"
  '((operator . "TEMPPREFIX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEMPPREFIX"))
  'str)

(deftest "sysvar-textalignmode-getvar-type"
  '((operator . "TEXTALIGNMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTALIGNMODE"))
  'int)

(deftest "sysvar-textalignmode-getvar-default"
  '((operator . "TEXTALIGNMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "TEXTALIGNMODE")
  9)

(deftest "sysvar-textalignspacing-getvar-type"
  '((operator . "TEXTALIGNSPACING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTALIGNSPACING"))
  'int)

(deftest "sysvar-textalignspacing-getvar-default"
  '((operator . "TEXTALIGNSPACING") (area . "sysvar") (profile . STRICT))
  '(getvar "TEXTALIGNSPACING")
  2)

(deftest "sysvar-textallcaps-getvar-type"
  '((operator . "TEXTALLCAPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTALLCAPS"))
  'int)

(deftest "sysvar-textallcaps-getvar-default"
  '((operator . "TEXTALLCAPS") (area . "sysvar") (profile . STRICT))
  '(getvar "TEXTALLCAPS")
  0)

(deftest "sysvar-textangle-getvar-type"
  '((operator . "TEXTANGLE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TEXTANGLE"))
  'real)

(deftest "sysvar-textautocorrectcaps-getvar-type"
  '((operator . "TEXTAUTOCORRECTCAPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTAUTOCORRECTCAPS"))
  'int)

(deftest "sysvar-textautocorrectcaps-getvar-default"
  '((operator . "TEXTAUTOCORRECTCAPS") (area . "sysvar") (profile . STRICT))
  '(getvar "TEXTAUTOCORRECTCAPS")
  1)

(deftest "sysvar-texted-getvar-type"
  '((operator . "TEXTED") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTED"))
  'int)

(deftest "sysvar-texteditmode-getvar-type"
  '((operator . "TEXTEDITMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTEDITMODE"))
  'int)

(deftest "sysvar-texteval-getvar-type"
  '((operator . "TEXTEVAL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTEVAL"))
  'int)

(deftest "sysvar-texteval-getvar-default"
  '((operator . "TEXTEVAL") (area . "sysvar") (profile . STRICT))
  '(getvar "TEXTEVAL")
  0)

(deftest "sysvar-textfill-getvar-type"
  '((operator . "TEXTFILL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTFILL"))
  'int)

(deftest "sysvar-textgapselection-getvar-type"
  '((operator . "TEXTGAPSELECTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTGAPSELECTION"))
  'int)

(deftest "sysvar-textgapselection-getvar-default"
  '((operator . "TEXTGAPSELECTION") (area . "sysvar") (profile . STRICT))
  '(getvar "TEXTGAPSELECTION")
  0)

(deftest "sysvar-textjustify-getvar-type"
  '((operator . "TEXTJUSTIFY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTJUSTIFY"))
  'str)

(deftest-error "sysvar-textjustify-setvar-readonly-signals"
  '((operator . "TEXTJUSTIFY") (area . "sysvar") (profile . STRICT))
  '(setvar "TEXTJUSTIFY" "")
  'sysvar-read-only)

(deftest "sysvar-textlayer-getvar-type"
  '((operator . "TEXTLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTLAYER"))
  'str)

(deftest "sysvar-textlayer-getvar-default"
  '((operator . "TEXTLAYER") (area . "sysvar") (profile . STRICT))
  '(getvar "TEXTLAYER")
  "use current")

(deftest "sysvar-textoutputfileformat-getvar-type"
  '((operator . "TEXTOUTPUTFILEFORMAT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTOUTPUTFILEFORMAT"))
  'int)

(deftest "sysvar-textoutputfileformat-getvar-default"
  '((operator . "TEXTOUTPUTFILEFORMAT") (area . "sysvar") (profile . STRICT))
  '(getvar "TEXTOUTPUTFILEFORMAT")
  0)

(deftest "sysvar-textqlty-getvar-type"
  '((operator . "TEXTQLTY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTQLTY"))
  'int)

(deftest "sysvar-textsize-getvar-type"
  '((operator . "TEXTSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTSIZE"))
  'real)

(deftest "sysvar-textstyle-getvar-type"
  '((operator . "TEXTSTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTSTYLE"))
  'str)

(deftest "sysvar-textstyle-getvar-default"
  '((operator . "TEXTSTYLE") (area . "sysvar") (profile . STRICT))
  '(getvar "TEXTSTYLE")
  "Standard")

(deftest "sysvar-texttoattribute-getvar-type"
  '((operator . "TEXTTOATTRIBUTE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TEXTTOATTRIBUTE"))
  'str)

(deftest "sysvar-texttoattribute-getvar-default"
  '((operator . "TEXTTOATTRIBUTE") (area . "sysvar") (profile . STRICT))
  '(getvar "TEXTTOATTRIBUTE")
  "1")

(deftest "sysvar-texturemappath-getvar-type"
  '((operator . "TEXTUREMAPPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TEXTUREMAPPATH"))
  'str)

(deftest "sysvar-thickness-getvar-type"
  '((operator . "THICKNESS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "THICKNESS"))
  'real)

(deftest "sysvar-threaddisplay-getvar-type"
  '((operator . "THREADDISPLAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "THREADDISPLAY"))
  'int)

(deftest "sysvar-threaddisplay-getvar-default"
  '((operator . "THREADDISPLAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "THREADDISPLAY")
  0)

(deftest "sysvar-thumbsave-getvar-type"
  '((operator . "THUMBSAVE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "THUMBSAVE"))
  'int)

(deftest "sysvar-thumbsave-getvar-default"
  '((operator . "THUMBSAVE") (area . "sysvar") (profile . STRICT))
  '(getvar "THUMBSAVE")
  1)

(deftest "sysvar-thumbsize-getvar-type"
  '((operator . "THUMBSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "THUMBSIZE"))
  'int)

(deftest "sysvar-thumbsize2d-getvar-type"
  '((operator . "THUMBSIZE2D") (area . "sysvar") (profile . STRICT))
  '(type (getvar "THUMBSIZE2D"))
  'int)

(deftest "sysvar-thumbsize2d-getvar-default"
  '((operator . "THUMBSIZE2D") (area . "sysvar") (profile . STRICT))
  '(getvar "THUMBSIZE2D")
  0)

(deftest "sysvar-tilemode-getvar-type"
  '((operator . "TILEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TILEMODE"))
  'int)

(deftest "sysvar-tilemodelightsynch-getvar-type"
  '((operator . "TILEMODELIGHTSYNCH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TILEMODELIGHTSYNCH"))
  'int)

(deftest "sysvar-tilemodelightsynch-getvar-default"
  '((operator . "TILEMODELIGHTSYNCH") (area . "sysvar") (profile . STRICT))
  '(getvar "TILEMODELIGHTSYNCH")
  1)

(deftest "sysvar-timezone-getvar-type"
  '((operator . "TIMEZONE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TIMEZONE"))
  'int)

(deftest "sysvar-toolbarmargin-getvar-type"
  '((operator . "TOOLBARMARGIN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TOOLBARMARGIN"))
  'int)

(deftest "sysvar-toolbarmargin-getvar-default"
  '((operator . "TOOLBARMARGIN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TOOLBARMARGIN")
  0)

(deftest "sysvar-toolbuttonsize-getvar-type"
  '((operator . "TOOLBUTTONSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TOOLBUTTONSIZE"))
  'int)

(deftest "sysvar-toolbuttonsize-getvar-default"
  '((operator . "TOOLBUTTONSIZE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TOOLBUTTONSIZE")
  0)

(deftest "sysvar-tooliconpadding-getvar-type"
  '((operator . "TOOLICONPADDING") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TOOLICONPADDING"))
  'int)

(deftest "sysvar-tooliconpadding-getvar-default"
  '((operator . "TOOLICONPADDING") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TOOLICONPADDING")
  4)

(deftest "sysvar-toolpalettepath-getvar-type"
  '((operator . "TOOLPALETTEPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TOOLPALETTEPATH"))
  'str)

(deftest "sysvar-tooltipdelay-getvar-type"
  '((operator . "TOOLTIPDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TOOLTIPDELAY"))
  'int)

(deftest "sysvar-tooltipdelay-getvar-default"
  '((operator . "TOOLTIPDELAY") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TOOLTIPDELAY")
  500)

(deftest "sysvar-tooltipmerge-getvar-type"
  '((operator . "TOOLTIPMERGE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TOOLTIPMERGE"))
  'int)

(deftest "sysvar-tooltipmerge-getvar-default"
  '((operator . "TOOLTIPMERGE") (area . "sysvar") (profile . STRICT))
  '(getvar "TOOLTIPMERGE")
  0)

(deftest "sysvar-tooltips-getvar-type"
  '((operator . "TOOLTIPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TOOLTIPS"))
  'int)

(deftest "sysvar-tooltips-getvar-default"
  '((operator . "TOOLTIPS") (area . "sysvar") (profile . STRICT))
  '(getvar "TOOLTIPS")
  1)

(deftest "sysvar-tooltiptransparency-getvar-type"
  '((operator . "TOOLTIPTRANSPARENCY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TOOLTIPTRANSPARENCY"))
  'int)

(deftest "sysvar-tooltiptransparency-getvar-default"
  '((operator . "TOOLTIPTRANSPARENCY") (area . "sysvar") (profile . STRICT))
  '(getvar "TOOLTIPTRANSPARENCY")
  0)

(deftest "sysvar-touchmode-getvar-type"
  '((operator . "TOUCHMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TOUCHMODE"))
  'int)

(deftest "sysvar-touchmode-getvar-default"
  '((operator . "TOUCHMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "TOUCHMODE")
  0)

(deftest "sysvar-tpstate-getvar-type"
  '((operator . "TPSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TPSTATE"))
  'int)

(deftest-error "sysvar-tpstate-setvar-readonly-signals"
  '((operator . "TPSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "TPSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-tracecurrent-getvar-type"
  '((operator . "TRACECURRENT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACECURRENT"))
  'str)

(deftest-error "sysvar-tracecurrent-setvar-readonly-signals"
  '((operator . "TRACECURRENT") (area . "sysvar") (profile . STRICT))
  '(setvar "TRACECURRENT" "")
  'sysvar-read-only)

(deftest "sysvar-tracedisplaymode-getvar-type"
  '((operator . "TRACEDISPLAYMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACEDISPLAYMODE"))
  'int)

(deftest-error "sysvar-tracedisplaymode-setvar-readonly-signals"
  '((operator . "TRACEDISPLAYMODE") (area . "sysvar") (profile . STRICT))
  '(setvar "TRACEDISPLAYMODE" 0)
  'sysvar-read-only)

(deftest "sysvar-tracefadectl-getvar-type"
  '((operator . "TRACEFADECTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACEFADECTL"))
  'int)

(deftest "sysvar-tracefadectl-getvar-default"
  '((operator . "TRACEFADECTL") (area . "sysvar") (profile . STRICT))
  '(getvar "TRACEFADECTL")
  40)

(deftest "sysvar-tracemarkupfadectl-getvar-type"
  '((operator . "TRACEMARKUPFADECTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACEMARKUPFADECTL"))
  'int)

(deftest-error "sysvar-tracemarkupfadectl-setvar-readonly-signals"
  '((operator . "TRACEMARKUPFADECTL") (area . "sysvar") (profile . STRICT))
  '(setvar "TRACEMARKUPFADECTL" 0)
  'sysvar-read-only)

(deftest "sysvar-tracemode-getvar-type"
  '((operator . "TRACEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACEMODE"))
  'int)

(deftest-error "sysvar-tracemode-setvar-readonly-signals"
  '((operator . "TRACEMODE") (area . "sysvar") (profile . STRICT))
  '(setvar "TRACEMODE" 0)
  'sysvar-read-only)

(deftest "sysvar-traceosnap-getvar-type"
  '((operator . "TRACEOSNAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACEOSNAP"))
  'int)

(deftest "sysvar-traceosnap-getvar-default"
  '((operator . "TRACEOSNAP") (area . "sysvar") (profile . STRICT))
  '(getvar "TRACEOSNAP")
  0)

(deftest "sysvar-tracepalettestate-getvar-type"
  '((operator . "TRACEPALETTESTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACEPALETTESTATE"))
  'int)

(deftest-error "sysvar-tracepalettestate-setvar-readonly-signals"
  '((operator . "TRACEPALETTESTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "TRACEPALETTESTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-tracepaperctl-getvar-type"
  '((operator . "TRACEPAPERCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACEPAPERCTL"))
  'int)

(deftest-error "sysvar-tracepaperctl-setvar-readonly-signals"
  '((operator . "TRACEPAPERCTL") (area . "sysvar") (profile . STRICT))
  '(setvar "TRACEPAPERCTL" 0)
  'sysvar-read-only)

(deftest "sysvar-tracevpsupport-getvar-type"
  '((operator . "TRACEVPSUPPORT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACEVPSUPPORT"))
  'int)

(deftest "sysvar-tracevpsupport-getvar-default"
  '((operator . "TRACEVPSUPPORT") (area . "sysvar") (profile . STRICT))
  '(getvar "TRACEVPSUPPORT")
  1)

(deftest "sysvar-tracewid-getvar-type"
  '((operator . "TRACEWID") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACEWID"))
  'real)

(deftest "sysvar-tracewid-getvar-default"
  '((operator . "TRACEWID") (area . "sysvar") (profile . STRICT))
  '(getvar "TRACEWID")
  1.0)

(deftest "sysvar-trackpath-getvar-type"
  '((operator . "TRACKPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRACKPATH"))
  'int)

(deftest "sysvar-transparencydisplay-getvar-type"
  '((operator . "TRANSPARENCYDISPLAY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRANSPARENCYDISPLAY"))
  'int)

(deftest "sysvar-transparencydisplay-getvar-default"
  '((operator . "TRANSPARENCYDISPLAY") (area . "sysvar") (profile . STRICT))
  '(getvar "TRANSPARENCYDISPLAY")
  1)

(deftest "sysvar-trayicons-getvar-type"
  '((operator . "TRAYICONS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRAYICONS"))
  'int)

(deftest "sysvar-trayicons-getvar-default"
  '((operator . "TRAYICONS") (area . "sysvar") (profile . STRICT))
  '(getvar "TRAYICONS")
  1)

(deftest "sysvar-traynotify-getvar-type"
  '((operator . "TRAYNOTIFY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRAYNOTIFY"))
  'int)

(deftest "sysvar-traynotify-getvar-default"
  '((operator . "TRAYNOTIFY") (area . "sysvar") (profile . STRICT))
  '(getvar "TRAYNOTIFY")
  1)

(deftest "sysvar-traytimeout-getvar-type"
  '((operator . "TRAYTIMEOUT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRAYTIMEOUT"))
  'int)

(deftest "sysvar-treedepth-getvar-type"
  '((operator . "TREEDEPTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TREEDEPTH"))
  'int)

(deftest "sysvar-treemax-getvar-type"
  '((operator . "TREEMAX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TREEMAX"))
  'int)

(deftest "sysvar-treemax-getvar-default"
  '((operator . "TREEMAX") (area . "sysvar") (profile . STRICT))
  '(getvar "TREEMAX")
  10000000)

(deftest "sysvar-trimedges-getvar-type"
  '((operator . "TRIMEDGES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRIMEDGES"))
  'int)

(deftest "sysvar-trimedges-getvar-default"
  '((operator . "TRIMEDGES") (area . "sysvar") (profile . STRICT))
  '(getvar "TRIMEDGES")
  1)

(deftest "sysvar-trimextendmode-getvar-type"
  '((operator . "TRIMEXTENDMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRIMEXTENDMODE"))
  'int)

(deftest "sysvar-trimextendmode-getvar-default"
  '((operator . "TRIMEXTENDMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "TRIMEXTENDMODE")
  1)

(deftest "sysvar-trimmode-getvar-type"
  '((operator . "TRIMMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRIMMODE"))
  'int)

(deftest "sysvar-trimmode-getvar-default"
  '((operator . "TRIMMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "TRIMMODE")
  1)

(deftest "sysvar-trustedpaths-getvar-type"
  '((operator . "TRUSTEDPATHS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TRUSTEDPATHS"))
  'str)

(deftest-error "sysvar-trustedpaths-setvar-readonly-signals"
  '((operator . "TRUSTEDPATHS") (area . "sysvar") (profile . STRICT))
  '(setvar "TRUSTEDPATHS" "")
  'sysvar-read-only)

(deftest "sysvar-tspacefac-getvar-type"
  '((operator . "TSPACEFAC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TSPACEFAC"))
  'real)

(deftest "sysvar-tspacetype-getvar-type"
  '((operator . "TSPACETYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TSPACETYPE"))
  'int)

(deftest "sysvar-tstackalign-getvar-type"
  '((operator . "TSTACKALIGN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TSTACKALIGN"))
  'int)

(deftest "sysvar-tstacksize-getvar-type"
  '((operator . "TSTACKSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TSTACKSIZE"))
  'int)

(deftest "sysvar-ttfastext-getvar-type"
  '((operator . "TTFASTEXT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "TTFASTEXT"))
  'int)

(deftest "sysvar-ttfastext-getvar-default"
  '((operator . "TTFASTEXT") (area . "sysvar") (profile . STRICT))
  '(getvar "TTFASTEXT")
  1)

(deftest "sysvar-tutorialsonstartpage-getvar-type"
  '((operator . "TUTORIALSONSTARTPAGE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "TUTORIALSONSTARTPAGE"))
  'int)

(deftest "sysvar-tutorialsonstartpage-getvar-default"
  '((operator . "TUTORIALSONSTARTPAGE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "TUTORIALSONSTARTPAGE")
  1)

(deftest "sysvar-ucs2ddisplaysetting-getvar-type"
  '((operator . "UCS2DDISPLAYSETTING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCS2DDISPLAYSETTING"))
  'int)

(deftest "sysvar-ucs2ddisplaysetting-getvar-default"
  '((operator . "UCS2DDISPLAYSETTING") (area . "sysvar") (profile . STRICT))
  '(getvar "UCS2DDISPLAYSETTING")
  1)

(deftest "sysvar-ucs3dparadisplaysetting-getvar-type"
  '((operator . "UCS3DPARADISPLAYSETTING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCS3DPARADISPLAYSETTING"))
  'int)

(deftest "sysvar-ucs3dparadisplaysetting-getvar-default"
  '((operator . "UCS3DPARADISPLAYSETTING") (area . "sysvar") (profile . STRICT))
  '(getvar "UCS3DPARADISPLAYSETTING")
  1)

(deftest "sysvar-ucs3dperpdisplaysetting-getvar-type"
  '((operator . "UCS3DPERPDISPLAYSETTING") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCS3DPERPDISPLAYSETTING"))
  'int)

(deftest "sysvar-ucs3dperpdisplaysetting-getvar-default"
  '((operator . "UCS3DPERPDISPLAYSETTING") (area . "sysvar") (profile . STRICT))
  '(getvar "UCS3DPERPDISPLAYSETTING")
  1)

(deftest "sysvar-ucsaxisang-getvar-type"
  '((operator . "UCSAXISANG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSAXISANG"))
  'int)

(deftest "sysvar-ucsbase-getvar-type"
  '((operator . "UCSBASE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSBASE"))
  'str)

(deftest "sysvar-ucsdetect-getvar-type"
  '((operator . "UCSDETECT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSDETECT"))
  'int)

(deftest "sysvar-ucsfollow-getvar-type"
  '((operator . "UCSFOLLOW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSFOLLOW"))
  'int)

(deftest "sysvar-ucsfollow-getvar-default"
  '((operator . "UCSFOLLOW") (area . "sysvar") (profile . STRICT))
  '(getvar "UCSFOLLOW")
  0)

(deftest "sysvar-ucsicon-getvar-type"
  '((operator . "UCSICON") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSICON"))
  'int)

(deftest "sysvar-ucsiconpos-getvar-type"
  '((operator . "UCSICONPOS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "UCSICONPOS"))
  'int)

(deftest "sysvar-ucsiconpos-getvar-default"
  '((operator . "UCSICONPOS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "UCSICONPOS")
  1)

(deftest "sysvar-ucsname-getvar-type"
  '((operator . "UCSNAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSNAME"))
  'str)

(deftest-error "sysvar-ucsname-setvar-readonly-signals"
  '((operator . "UCSNAME") (area . "sysvar") (profile . STRICT))
  '(setvar "UCSNAME" "")
  'sysvar-read-only)

(deftest "sysvar-ucsorg-getvar-type"
  '((operator . "UCSORG") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSORG"))
  'list)

(deftest-error "sysvar-ucsorg-setvar-readonly-signals"
  '((operator . "UCSORG") (area . "sysvar") (profile . STRICT))
  '(setvar "UCSORG" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-ucsortho-getvar-type"
  '((operator . "UCSORTHO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSORTHO"))
  'int)

(deftest "sysvar-ucsselectmode-getvar-type"
  '((operator . "UCSSELECTMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSSELECTMODE"))
  'int)

(deftest "sysvar-ucsselectmode-getvar-default"
  '((operator . "UCSSELECTMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "UCSSELECTMODE")
  1)

(deftest "sysvar-ucsview-getvar-type"
  '((operator . "UCSVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSVIEW"))
  'int)

(deftest "sysvar-ucsview-getvar-default"
  '((operator . "UCSVIEW") (area . "sysvar") (profile . STRICT))
  '(getvar "UCSVIEW")
  1)

(deftest "sysvar-ucsvp-getvar-type"
  '((operator . "UCSVP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSVP"))
  'int)

(deftest "sysvar-ucsvp-getvar-default"
  '((operator . "UCSVP") (area . "sysvar") (profile . STRICT))
  '(getvar "UCSVP")
  1)

(deftest "sysvar-ucsxdir-getvar-type"
  '((operator . "UCSXDIR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSXDIR"))
  'list)

(deftest-error "sysvar-ucsxdir-setvar-readonly-signals"
  '((operator . "UCSXDIR") (area . "sysvar") (profile . STRICT))
  '(setvar "UCSXDIR" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-ucsydir-getvar-type"
  '((operator . "UCSYDIR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UCSYDIR"))
  'list)

(deftest-error "sysvar-ucsydir-setvar-readonly-signals"
  '((operator . "UCSYDIR") (area . "sysvar") (profile . STRICT))
  '(setvar "UCSYDIR" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-undoctl-getvar-type"
  '((operator . "UNDOCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UNDOCTL"))
  'int)

(deftest-error "sysvar-undoctl-setvar-readonly-signals"
  '((operator . "UNDOCTL") (area . "sysvar") (profile . STRICT))
  '(setvar "UNDOCTL" 0)
  'sysvar-read-only)

(deftest "sysvar-undomarks-getvar-type"
  '((operator . "UNDOMARKS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UNDOMARKS"))
  'int)

(deftest-error "sysvar-undomarks-setvar-readonly-signals"
  '((operator . "UNDOMARKS") (area . "sysvar") (profile . STRICT))
  '(setvar "UNDOMARKS" 0)
  'sysvar-read-only)

(deftest "sysvar-unitesurfaces-getvar-type"
  '((operator . "UNITESURFACES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "UNITESURFACES"))
  'int)

(deftest "sysvar-unitesurfaces-getvar-default"
  '((operator . "UNITESURFACES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "UNITESURFACES")
  0)

(deftest "sysvar-unitmode-getvar-type"
  '((operator . "UNITMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UNITMODE"))
  'int)

(deftest "sysvar-unitmode-getvar-default"
  '((operator . "UNITMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "UNITMODE")
  0)

(deftest "sysvar-uosnap-getvar-type"
  '((operator . "UOSNAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UOSNAP"))
  'int)

(deftest "sysvar-uosnap-getvar-default"
  '((operator . "UOSNAP") (area . "sysvar") (profile . STRICT))
  '(getvar "UOSNAP")
  1)

(deftest "sysvar-updatethumbnail-getvar-type"
  '((operator . "UPDATETHUMBNAIL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "UPDATETHUMBNAIL"))
  'int)

(deftest "sysvar-updatethumbnail-getvar-default"
  '((operator . "UPDATETHUMBNAIL") (area . "sysvar") (profile . STRICT))
  '(getvar "UPDATETHUMBNAIL")
  15)

(deftest "sysvar-usecommunicator-getvar-type"
  '((operator . "USECOMMUNICATOR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "USECOMMUNICATOR"))
  'int)

(deftest "sysvar-usecommunicator-getvar-default"
  '((operator . "USECOMMUNICATOR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "USECOMMUNICATOR")
  1)

(deftest "sysvar-usenewstatusbar-getvar-type"
  '((operator . "USENEWSTATUSBAR") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "USENEWSTATUSBAR"))
  'int)

(deftest "sysvar-usenewstatusbar-getvar-default"
  '((operator . "USENEWSTATUSBAR") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "USENEWSTATUSBAR")
  0)

(deftest "sysvar-useri1-getvar-type"
  '((operator . "USERI1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERI1"))
  'int)

(deftest "sysvar-useri1-getvar-default"
  '((operator . "USERI1") (area . "sysvar") (profile . STRICT))
  '(getvar "USERI1")
  0)

(deftest "sysvar-useri2-getvar-type"
  '((operator . "USERI2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERI2"))
  'int)

(deftest "sysvar-useri2-getvar-default"
  '((operator . "USERI2") (area . "sysvar") (profile . STRICT))
  '(getvar "USERI2")
  0)

(deftest "sysvar-useri3-getvar-type"
  '((operator . "USERI3") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERI3"))
  'int)

(deftest "sysvar-useri3-getvar-default"
  '((operator . "USERI3") (area . "sysvar") (profile . STRICT))
  '(getvar "USERI3")
  0)

(deftest "sysvar-useri4-getvar-type"
  '((operator . "USERI4") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERI4"))
  'int)

(deftest "sysvar-useri4-getvar-default"
  '((operator . "USERI4") (area . "sysvar") (profile . STRICT))
  '(getvar "USERI4")
  0)

(deftest "sysvar-useri5-getvar-type"
  '((operator . "USERI5") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERI5"))
  'int)

(deftest "sysvar-useri5-getvar-default"
  '((operator . "USERI5") (area . "sysvar") (profile . STRICT))
  '(getvar "USERI5")
  0)

(deftest "sysvar-userr1-getvar-type"
  '((operator . "USERR1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERR1"))
  'real)

(deftest "sysvar-userr1-getvar-default"
  '((operator . "USERR1") (area . "sysvar") (profile . STRICT))
  '(getvar "USERR1")
  0.0)

(deftest "sysvar-userr2-getvar-type"
  '((operator . "USERR2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERR2"))
  'real)

(deftest "sysvar-userr2-getvar-default"
  '((operator . "USERR2") (area . "sysvar") (profile . STRICT))
  '(getvar "USERR2")
  0.0)

(deftest "sysvar-userr3-getvar-type"
  '((operator . "USERR3") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERR3"))
  'real)

(deftest "sysvar-userr3-getvar-default"
  '((operator . "USERR3") (area . "sysvar") (profile . STRICT))
  '(getvar "USERR3")
  0.0)

(deftest "sysvar-userr4-getvar-type"
  '((operator . "USERR4") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERR4"))
  'real)

(deftest "sysvar-userr4-getvar-default"
  '((operator . "USERR4") (area . "sysvar") (profile . STRICT))
  '(getvar "USERR4")
  0.0)

(deftest "sysvar-userr5-getvar-type"
  '((operator . "USERR5") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERR5"))
  'real)

(deftest "sysvar-userr5-getvar-default"
  '((operator . "USERR5") (area . "sysvar") (profile . STRICT))
  '(getvar "USERR5")
  0.0)

(deftest "sysvar-users1-getvar-type"
  '((operator . "USERS1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERS1"))
  'str)

(deftest "sysvar-users1-getvar-default"
  '((operator . "USERS1") (area . "sysvar") (profile . STRICT))
  '(getvar "USERS1")
  "")

(deftest "sysvar-users2-getvar-type"
  '((operator . "USERS2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERS2"))
  'str)

(deftest "sysvar-users3-getvar-type"
  '((operator . "USERS3") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERS3"))
  'str)

(deftest "sysvar-users4-getvar-type"
  '((operator . "USERS4") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERS4"))
  'str)

(deftest "sysvar-users5-getvar-type"
  '((operator . "USERS5") (area . "sysvar") (profile . STRICT))
  '(type (getvar "USERS5"))
  'str)

(deftest "sysvar-usestandardopenfiledialog-getvar-type"
  '((operator . "USESTANDARDOPENFILEDIALOG") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "USESTANDARDOPENFILEDIALOG"))
  'int)

(deftest "sysvar-usestandardopenfiledialog-getvar-default"
  '((operator . "USESTANDARDOPENFILEDIALOG") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "USESTANDARDOPENFILEDIALOG")
  0)

(deftest "sysvar-vbamacros-getvar-type"
  '((operator . "VBAMACROS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "VBAMACROS"))
  'int)

(deftest "sysvar-vbamacros-getvar-default"
  '((operator . "VBAMACROS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "VBAMACROS")
  1)

(deftest "sysvar-vendorname-getvar-type"
  '((operator . "VENDORNAME") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "VENDORNAME"))
  'str)

(deftest "sysvar-vendorname-getvar-default"
  '((operator . "VENDORNAME") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "VENDORNAME")
  "Bricsys")

(deftest "sysvar-verbosebimsectionupdate-getvar-type"
  '((operator . "VERBOSEBIMSECTIONUPDATE") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "VERBOSEBIMSECTIONUPDATE"))
  'int)

(deftest "sysvar-verbosebimsectionupdate-getvar-default"
  '((operator . "VERBOSEBIMSECTIONUPDATE") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "VERBOSEBIMSECTIONUPDATE")
  1)

(deftest "sysvar-versioncontrolconfigpath-getvar-type"
  '((operator . "VERSIONCONTROLCONFIGPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "VERSIONCONTROLCONFIGPATH"))
  'str)

(deftest "sysvar-versioncontroldownloadpath-getvar-type"
  '((operator . "VERSIONCONTROLDOWNLOADPATH") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "VERSIONCONTROLDOWNLOADPATH"))
  'str)

(deftest "sysvar-versioncustomizablefiles-getvar-type"
  '((operator . "VERSIONCUSTOMIZABLEFILES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VERSIONCUSTOMIZABLEFILES"))
  'str)

(deftest-error "sysvar-versioncustomizablefiles-setvar-readonly-signals"
  '((operator . "VERSIONCUSTOMIZABLEFILES") (area . "sysvar") (profile . STRICT))
  '(setvar "VERSIONCUSTOMIZABLEFILES" "")
  'sysvar-read-only)

(deftest "sysvar-viewbackstatus-getvar-type"
  '((operator . "VIEWBACKSTATUS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VIEWBACKSTATUS"))
  'int)

(deftest "sysvar-viewctr-getvar-type"
  '((operator . "VIEWCTR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VIEWCTR"))
  'list)

(deftest-error "sysvar-viewctr-setvar-readonly-signals"
  '((operator . "VIEWCTR") (area . "sysvar") (profile . STRICT))
  '(setvar "VIEWCTR" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-viewdir-getvar-type"
  '((operator . "VIEWDIR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VIEWDIR"))
  'list)

(deftest-error "sysvar-viewdir-setvar-readonly-signals"
  '((operator . "VIEWDIR") (area . "sysvar") (profile . STRICT))
  '(setvar "VIEWDIR" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-viewfwdstatus-getvar-type"
  '((operator . "VIEWFWDSTATUS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VIEWFWDSTATUS"))
  'int)

(deftest "sysvar-viewmode-getvar-type"
  '((operator . "VIEWMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VIEWMODE"))
  'int)

(deftest-error "sysvar-viewmode-setvar-readonly-signals"
  '((operator . "VIEWMODE") (area . "sysvar") (profile . STRICT))
  '(setvar "VIEWMODE" 0)
  'sysvar-read-only)

(deftest "sysvar-viewportlayer-getvar-type"
  '((operator . "VIEWPORTLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VIEWPORTLAYER"))
  'str)

(deftest "sysvar-viewportlayer-getvar-default"
  '((operator . "VIEWPORTLAYER") (area . "sysvar") (profile . STRICT))
  '(getvar "VIEWPORTLAYER")
  "\"use current\"")

(deftest "sysvar-viewsize-getvar-type"
  '((operator . "VIEWSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VIEWSIZE"))
  'real)

(deftest-error "sysvar-viewsize-setvar-readonly-signals"
  '((operator . "VIEWSIZE") (area . "sysvar") (profile . STRICT))
  '(setvar "VIEWSIZE" 0.0)
  'sysvar-read-only)

(deftest "sysvar-viewsketchmode-getvar-type"
  '((operator . "VIEWSKETCHMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VIEWSKETCHMODE"))
  'int)

(deftest-error "sysvar-viewsketchmode-setvar-readonly-signals"
  '((operator . "VIEWSKETCHMODE") (area . "sysvar") (profile . STRICT))
  '(setvar "VIEWSKETCHMODE" 0)
  'sysvar-read-only)

(deftest "sysvar-viewtwist-getvar-type"
  '((operator . "VIEWTWIST") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VIEWTWIST"))
  'real)

(deftest-error "sysvar-viewtwist-setvar-readonly-signals"
  '((operator . "VIEWTWIST") (area . "sysvar") (profile . STRICT))
  '(setvar "VIEWTWIST" 0.0)
  'sysvar-read-only)

(deftest "sysvar-viewupdateauto-getvar-type"
  '((operator . "VIEWUPDATEAUTO") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VIEWUPDATEAUTO"))
  'int)

(deftest "sysvar-viewupdateauto-getvar-default"
  '((operator . "VIEWUPDATEAUTO") (area . "sysvar") (profile . STRICT))
  '(getvar "VIEWUPDATEAUTO")
  1)

(deftest "sysvar-visretain-getvar-type"
  '((operator . "VISRETAIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VISRETAIN"))
  'int)

(deftest "sysvar-visretainmode-getvar-type"
  '((operator . "VISRETAINMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VISRETAINMODE"))
  'int)

(deftest "sysvar-visretainmode-getvar-default"
  '((operator . "VISRETAINMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "VISRETAINMODE")
  0)

(deftest "sysvar-volumeprec-getvar-type"
  '((operator . "VOLUMEPREC") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "VOLUMEPREC"))
  'int)

(deftest "sysvar-volumeprec-getvar-default"
  '((operator . "VOLUMEPREC") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "VOLUMEPREC")
  -1)

(deftest "sysvar-volumeunits-getvar-type"
  '((operator . "VOLUMEUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "VOLUMEUNITS"))
  'str)

(deftest "sysvar-volumeunits-getvar-default"
  '((operator . "VOLUMEUNITS") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "VOLUMEUNITS")
  "in ft mi µm mm cm m km")

(deftest "sysvar-vpcontrol-getvar-type"
  '((operator . "VPCONTROL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VPCONTROL"))
  'int)

(deftest "sysvar-vpcontrol-getvar-default"
  '((operator . "VPCONTROL") (area . "sysvar") (profile . STRICT))
  '(getvar "VPCONTROL")
  1)

(deftest "sysvar-vplayeroverrides-getvar-type"
  '((operator . "VPLAYEROVERRIDES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VPLAYEROVERRIDES"))
  'int)

(deftest-error "sysvar-vplayeroverrides-setvar-readonly-signals"
  '((operator . "VPLAYEROVERRIDES") (area . "sysvar") (profile . STRICT))
  '(setvar "VPLAYEROVERRIDES" 0)
  'sysvar-read-only)

(deftest "sysvar-vplayeroverridesmode-getvar-type"
  '((operator . "VPLAYEROVERRIDESMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VPLAYEROVERRIDESMODE"))
  'int)

(deftest "sysvar-vplayeroverridesmode-getvar-default"
  '((operator . "VPLAYEROVERRIDESMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "VPLAYEROVERRIDESMODE")
  1)

(deftest "sysvar-vpmaximizedstate-getvar-type"
  '((operator . "VPMAXIMIZEDSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VPMAXIMIZEDSTATE"))
  'int)

(deftest-error "sysvar-vpmaximizedstate-setvar-readonly-signals"
  '((operator . "VPMAXIMIZEDSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "VPMAXIMIZEDSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-vprotateassoc-getvar-type"
  '((operator . "VPROTATEASSOC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VPROTATEASSOC"))
  'int)

(deftest "sysvar-vprotateassoc-getvar-default"
  '((operator . "VPROTATEASSOC") (area . "sysvar") (profile . STRICT))
  '(getvar "VPROTATEASSOC")
  1)

(deftest "sysvar-vsacurvaturehigh-getvar-type"
  '((operator . "VSACURVATUREHIGH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSACURVATUREHIGH"))
  'real)

(deftest "sysvar-vsacurvaturehigh-getvar-default"
  '((operator . "VSACURVATUREHIGH") (area . "sysvar") (profile . STRICT))
  '(getvar "VSACURVATUREHIGH")
  1.0)

(deftest "sysvar-vsacurvaturelow-getvar-type"
  '((operator . "VSACURVATURELOW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSACURVATURELOW"))
  'real)

(deftest "sysvar-vsacurvaturelow-getvar-default"
  '((operator . "VSACURVATURELOW") (area . "sysvar") (profile . STRICT))
  '(getvar "VSACURVATURELOW")
  -1.0)

(deftest "sysvar-vsacurvaturetype-getvar-type"
  '((operator . "VSACURVATURETYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSACURVATURETYPE"))
  'int)

(deftest "sysvar-vsacurvaturetype-getvar-default"
  '((operator . "VSACURVATURETYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "VSACURVATURETYPE")
  0)

(deftest "sysvar-vsadraftanglehigh-getvar-type"
  '((operator . "VSADRAFTANGLEHIGH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSADRAFTANGLEHIGH"))
  'real)

(deftest "sysvar-vsadraftanglehigh-getvar-default"
  '((operator . "VSADRAFTANGLEHIGH") (area . "sysvar") (profile . STRICT))
  '(getvar "VSADRAFTANGLEHIGH")
  3.0)

(deftest "sysvar-vsazebracolor1-getvar-type"
  '((operator . "VSAZEBRACOLOR1") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSAZEBRACOLOR1"))
  'str)

(deftest "sysvar-vsazebracolor1-getvar-default"
  '((operator . "VSAZEBRACOLOR1") (area . "sysvar") (profile . STRICT))
  '(getvar "VSAZEBRACOLOR1")
  "RGB:255,255,255")

(deftest "sysvar-vsazebracolor2-getvar-type"
  '((operator . "VSAZEBRACOLOR2") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSAZEBRACOLOR2"))
  'str)

(deftest "sysvar-vsazebracolor2-getvar-default"
  '((operator . "VSAZEBRACOLOR2") (area . "sysvar") (profile . STRICT))
  '(getvar "VSAZEBRACOLOR2")
  "RGB:0,0,0")

(deftest "sysvar-vsazebradirection-getvar-type"
  '((operator . "VSAZEBRADIRECTION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSAZEBRADIRECTION"))
  'int)

(deftest "sysvar-vsazebradirection-getvar-default"
  '((operator . "VSAZEBRADIRECTION") (area . "sysvar") (profile . STRICT))
  '(getvar "VSAZEBRADIRECTION")
  90)

(deftest "sysvar-vsazebrasize-getvar-type"
  '((operator . "VSAZEBRASIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSAZEBRASIZE"))
  'int)

(deftest "sysvar-vsazebrasize-getvar-default"
  '((operator . "VSAZEBRASIZE") (area . "sysvar") (profile . STRICT))
  '(getvar "VSAZEBRASIZE")
  45)

(deftest "sysvar-vsazebratype-getvar-type"
  '((operator . "VSAZEBRATYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSAZEBRATYPE"))
  'int)

(deftest "sysvar-vsazebratype-getvar-default"
  '((operator . "VSAZEBRATYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "VSAZEBRATYPE")
  1)

(deftest "sysvar-vsbackgrounds-getvar-type"
  '((operator . "VSBACKGROUNDS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSBACKGROUNDS"))
  'int)

(deftest "sysvar-vsbackgrounds-getvar-default"
  '((operator . "VSBACKGROUNDS") (area . "sysvar") (profile . STRICT))
  '(getvar "VSBACKGROUNDS")
  1)

(deftest "sysvar-vsedgecolor-getvar-type"
  '((operator . "VSEDGECOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSEDGECOLOR"))
  'str)

(deftest "sysvar-vsedgecolor-getvar-default"
  '((operator . "VSEDGECOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "VSEDGECOLOR")
  "BYENTITY")

(deftest "sysvar-vsedgejitter-getvar-type"
  '((operator . "VSEDGEJITTER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSEDGEJITTER"))
  'int)

(deftest "sysvar-vsedgejitter-getvar-default"
  '((operator . "VSEDGEJITTER") (area . "sysvar") (profile . STRICT))
  '(getvar "VSEDGEJITTER")
  -2)

(deftest "sysvar-vsedgelex-getvar-type"
  '((operator . "VSEDGELEX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSEDGELEX"))
  'int)

(deftest "sysvar-vsedgelex-getvar-default"
  '((operator . "VSEDGELEX") (area . "sysvar") (profile . STRICT))
  '(getvar "VSEDGELEX")
  -6)

(deftest "sysvar-vsedges-getvar-type"
  '((operator . "VSEDGES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSEDGES"))
  'int)

(deftest "sysvar-vsedges-getvar-default"
  '((operator . "VSEDGES") (area . "sysvar") (profile . STRICT))
  '(getvar "VSEDGES")
  1)

(deftest "sysvar-vsedgesmooth-getvar-type"
  '((operator . "VSEDGESMOOTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSEDGESMOOTH"))
  'int)

(deftest "sysvar-vsedgesmooth-getvar-default"
  '((operator . "VSEDGESMOOTH") (area . "sysvar") (profile . STRICT))
  '(getvar "VSEDGESMOOTH")
  1)

(deftest "sysvar-vsfacecolormode-getvar-type"
  '((operator . "VSFACECOLORMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSFACECOLORMODE"))
  'int)

(deftest "sysvar-vsfacecolormode-getvar-default"
  '((operator . "VSFACECOLORMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "VSFACECOLORMODE")
  0)

(deftest "sysvar-vsfacehighlight-getvar-type"
  '((operator . "VSFACEHIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSFACEHIGHLIGHT"))
  'int)

(deftest "sysvar-vsfacehighlight-getvar-default"
  '((operator . "VSFACEHIGHLIGHT") (area . "sysvar") (profile . STRICT))
  '(getvar "VSFACEHIGHLIGHT")
  -30)

(deftest "sysvar-vsfaceopacity-getvar-type"
  '((operator . "VSFACEOPACITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSFACEOPACITY"))
  'int)

(deftest "sysvar-vsfaceopacity-getvar-default"
  '((operator . "VSFACEOPACITY") (area . "sysvar") (profile . STRICT))
  '(getvar "VSFACEOPACITY")
  -60)

(deftest "sysvar-vsfacestyle-getvar-type"
  '((operator . "VSFACESTYLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSFACESTYLE"))
  'int)

(deftest "sysvar-vsfacestyle-getvar-default"
  '((operator . "VSFACESTYLE") (area . "sysvar") (profile . STRICT))
  '(getvar "VSFACESTYLE")
  0)

(deftest "sysvar-vshalogap-getvar-type"
  '((operator . "VSHALOGAP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSHALOGAP"))
  'int)

(deftest "sysvar-vshalogap-getvar-default"
  '((operator . "VSHALOGAP") (area . "sysvar") (profile . STRICT))
  '(getvar "VSHALOGAP")
  0)

(deftest "sysvar-vsintersectioncolor-getvar-type"
  '((operator . "VSINTERSECTIONCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSINTERSECTIONCOLOR"))
  'int)

(deftest "sysvar-vsintersectioncolor-getvar-default"
  '((operator . "VSINTERSECTIONCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "VSINTERSECTIONCOLOR")
  7)

(deftest "sysvar-vsintersectionedges-getvar-type"
  '((operator . "VSINTERSECTIONEDGES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSINTERSECTIONEDGES"))
  'int)

(deftest "sysvar-vsintersectionedges-getvar-default"
  '((operator . "VSINTERSECTIONEDGES") (area . "sysvar") (profile . STRICT))
  '(getvar "VSINTERSECTIONEDGES")
  0)

(deftest "sysvar-vsintersectionltype-getvar-type"
  '((operator . "VSINTERSECTIONLTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSINTERSECTIONLTYPE"))
  'int)

(deftest "sysvar-vsintersectionltype-getvar-default"
  '((operator . "VSINTERSECTIONLTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "VSINTERSECTIONLTYPE")
  1)

(deftest "sysvar-vsisoontop-getvar-type"
  '((operator . "VSISOONTOP") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSISOONTOP"))
  'int)

(deftest "sysvar-vsisoontop-getvar-default"
  '((operator . "VSISOONTOP") (area . "sysvar") (profile . STRICT))
  '(getvar "VSISOONTOP")
  0)

(deftest "sysvar-vslightingquality-getvar-type"
  '((operator . "VSLIGHTINGQUALITY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSLIGHTINGQUALITY"))
  'int)

(deftest "sysvar-vslightingquality-getvar-default"
  '((operator . "VSLIGHTINGQUALITY") (area . "sysvar") (profile . STRICT))
  '(getvar "VSLIGHTINGQUALITY")
  1)

(deftest "sysvar-vsmaterialmode-getvar-type"
  '((operator . "VSMATERIALMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSMATERIALMODE"))
  'int)

(deftest "sysvar-vsmaterialmode-getvar-default"
  '((operator . "VSMATERIALMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "VSMATERIALMODE")
  0)

(deftest "sysvar-vsmax-getvar-type"
  '((operator . "VSMAX") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSMAX"))
  'list)

(deftest-error "sysvar-vsmax-setvar-readonly-signals"
  '((operator . "VSMAX") (area . "sysvar") (profile . STRICT))
  '(setvar "VSMAX" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-vsmin-getvar-type"
  '((operator . "VSMIN") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSMIN"))
  'list)

(deftest-error "sysvar-vsmin-setvar-readonly-signals"
  '((operator . "VSMIN") (area . "sysvar") (profile . STRICT))
  '(setvar "VSMIN" '(0.0 0.0))
  'sysvar-read-only)

(deftest "sysvar-vsmonocolor-getvar-type"
  '((operator . "VSMONOCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSMONOCOLOR"))
  'str)

(deftest "sysvar-vsmonocolor-getvar-default"
  '((operator . "VSMONOCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "VSMONOCOLOR")
  "RGB:255,255,255")

(deftest "sysvar-vsoccludedcolor-getvar-type"
  '((operator . "VSOCCLUDEDCOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSOCCLUDEDCOLOR"))
  'str)

(deftest "sysvar-vsoccludedcolor-getvar-default"
  '((operator . "VSOCCLUDEDCOLOR") (area . "sysvar") (profile . STRICT))
  '(getvar "VSOCCLUDEDCOLOR")
  "ByEntity")

(deftest "sysvar-vsoccludededges-getvar-type"
  '((operator . "VSOCCLUDEDEDGES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSOCCLUDEDEDGES"))
  'int)

(deftest "sysvar-vsoccludededges-getvar-default"
  '((operator . "VSOCCLUDEDEDGES") (area . "sysvar") (profile . STRICT))
  '(getvar "VSOCCLUDEDEDGES")
  1)

(deftest "sysvar-vsoccludedltype-getvar-type"
  '((operator . "VSOCCLUDEDLTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSOCCLUDEDLTYPE"))
  'int)

(deftest "sysvar-vsoccludedltype-getvar-default"
  '((operator . "VSOCCLUDEDLTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "VSOCCLUDEDLTYPE")
  1)

(deftest "sysvar-vsshadows-getvar-type"
  '((operator . "VSSHADOWS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSSHADOWS"))
  'int)

(deftest "sysvar-vsshadows-getvar-default"
  '((operator . "VSSHADOWS") (area . "sysvar") (profile . STRICT))
  '(getvar "VSSHADOWS")
  0)

(deftest "sysvar-vssilhedges-getvar-type"
  '((operator . "VSSILHEDGES") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSSILHEDGES"))
  'int)

(deftest "sysvar-vssilhedges-getvar-default"
  '((operator . "VSSILHEDGES") (area . "sysvar") (profile . STRICT))
  '(getvar "VSSILHEDGES")
  0)

(deftest "sysvar-vssilhwidth-getvar-type"
  '((operator . "VSSILHWIDTH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSSILHWIDTH"))
  'int)

(deftest "sysvar-vssilhwidth-getvar-default"
  '((operator . "VSSILHWIDTH") (area . "sysvar") (profile . STRICT))
  '(getvar "VSSILHWIDTH")
  5)

(deftest "sysvar-vsstate-getvar-type"
  '((operator . "VSSTATE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VSSTATE"))
  'int)

(deftest-error "sysvar-vsstate-setvar-readonly-signals"
  '((operator . "VSSTATE") (area . "sysvar") (profile . STRICT))
  '(setvar "VSSTATE" 0)
  'sysvar-read-only)

(deftest "sysvar-vtduration-getvar-type"
  '((operator . "VTDURATION") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VTDURATION"))
  'int)

(deftest "sysvar-vtenable-getvar-type"
  '((operator . "VTENABLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VTENABLE"))
  'int)

(deftest "sysvar-vtfps-getvar-type"
  '((operator . "VTFPS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "VTFPS"))
  'int)

(deftest "sysvar-warningmessages-getvar-type"
  '((operator . "WARNINGMESSAGES") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "WARNINGMESSAGES"))
  'int)

(deftest "sysvar-warningmessages-getvar-default"
  '((operator . "WARNINGMESSAGES") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "WARNINGMESSAGES")
  1048575)

(deftest "sysvar-wblockcreatemode-getvar-type"
  '((operator . "WBLOCKCREATEMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WBLOCKCREATEMODE"))
  'int)

(deftest "sysvar-wblockcreatemode-getvar-default"
  '((operator . "WBLOCKCREATEMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "WBLOCKCREATEMODE")
  1)

(deftest "sysvar-whiparc-getvar-type"
  '((operator . "WHIPARC") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WHIPARC"))
  'int)

(deftest "sysvar-whipthread-getvar-type"
  '((operator . "WHIPTHREAD") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WHIPTHREAD"))
  'int)

(deftest "sysvar-windowareacolor-getvar-type"
  '((operator . "WINDOWAREACOLOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WINDOWAREACOLOR"))
  'int)

(deftest "sysvar-wipeoutframe-getvar-type"
  '((operator . "WIPEOUTFRAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WIPEOUTFRAME"))
  'int)

(deftest "sysvar-wmfbkgnd-getvar-type"
  '((operator . "WMFBKGND") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WMFBKGND"))
  'int)

(deftest "sysvar-wmfforegnd-getvar-type"
  '((operator . "WMFFOREGND") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WMFFOREGND"))
  'int)

(deftest "sysvar-wmfttfastext-getvar-type"
  '((operator . "WMFTTFASTEXT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "WMFTTFASTEXT"))
  'int)

(deftest "sysvar-wmfttfastext-getvar-default"
  '((operator . "WMFTTFASTEXT") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "WMFTTFASTEXT")
  0)

(deftest "sysvar-wndlmain-getvar-type"
  '((operator . "WNDLMAIN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "WNDLMAIN"))
  'int)

(deftest "sysvar-wndlmain-getvar-default"
  '((operator . "WNDLMAIN") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "WNDLMAIN")
  2)

(deftest "sysvar-wndlscrl-getvar-type"
  '((operator . "WNDLSCRL") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "WNDLSCRL"))
  'int)

(deftest "sysvar-wndlscrl-getvar-default"
  '((operator . "WNDLSCRL") (area . "sysvar") (profile . BRICSCAD))
  '(getvar "WNDLSCRL")
  0)

(deftest "sysvar-wndltext-getvar-type"
  '((operator . "WNDLTEXT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "WNDLTEXT"))
  'int)

(deftest "sysvar-wndpmain-getvar-type"
  '((operator . "WNDPMAIN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "WNDPMAIN"))
  'list)

(deftest "sysvar-wndptext-getvar-type"
  '((operator . "WNDPTEXT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "WNDPTEXT"))
  'list)

(deftest "sysvar-wndsmain-getvar-type"
  '((operator . "WNDSMAIN") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "WNDSMAIN"))
  'list)

(deftest "sysvar-wndstext-getvar-type"
  '((operator . "WNDSTEXT") (area . "sysvar") (profile . BRICSCAD))
  '(type (getvar "WNDSTEXT"))
  'list)

(deftest "sysvar-workingfolder-getvar-type"
  '((operator . "WORKINGFOLDER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WORKINGFOLDER"))
  'str)

(deftest-error "sysvar-workingfolder-setvar-readonly-signals"
  '((operator . "WORKINGFOLDER") (area . "sysvar") (profile . STRICT))
  '(setvar "WORKINGFOLDER" "")
  'sysvar-read-only)

(deftest "sysvar-workspacelabel-getvar-type"
  '((operator . "WORKSPACELABEL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WORKSPACELABEL"))
  'int)

(deftest "sysvar-workspacelabel-getvar-default"
  '((operator . "WORKSPACELABEL") (area . "sysvar") (profile . STRICT))
  '(getvar "WORKSPACELABEL")
  0)

(deftest "sysvar-worlducs-getvar-type"
  '((operator . "WORLDUCS") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WORLDUCS"))
  'int)

(deftest-error "sysvar-worlducs-setvar-readonly-signals"
  '((operator . "WORLDUCS") (area . "sysvar") (profile . STRICT))
  '(setvar "WORLDUCS" 0)
  'sysvar-read-only)

(deftest "sysvar-worldview-getvar-type"
  '((operator . "WORLDVIEW") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WORLDVIEW"))
  'int)

(deftest "sysvar-writestat-getvar-type"
  '((operator . "WRITESTAT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WRITESTAT"))
  'int)

(deftest-error "sysvar-writestat-setvar-readonly-signals"
  '((operator . "WRITESTAT") (area . "sysvar") (profile . STRICT))
  '(setvar "WRITESTAT" 0)
  'sysvar-read-only)

(deftest "sysvar-wsautosave-getvar-type"
  '((operator . "WSAUTOSAVE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WSAUTOSAVE"))
  'int)

(deftest "sysvar-wsautosave-getvar-default"
  '((operator . "WSAUTOSAVE") (area . "sysvar") (profile . STRICT))
  '(getvar "WSAUTOSAVE")
  1)

(deftest "sysvar-wscurrent-getvar-type"
  '((operator . "WSCURRENT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "WSCURRENT"))
  'str)

(deftest "sysvar-xclipframe-getvar-type"
  '((operator . "XCLIPFRAME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XCLIPFRAME"))
  'int)

(deftest "sysvar-xcomparebakpath-getvar-type"
  '((operator . "XCOMPAREBAKPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XCOMPAREBAKPATH"))
  'str)

(deftest "sysvar-xcomparebaksize-getvar-type"
  '((operator . "XCOMPAREBAKSIZE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XCOMPAREBAKSIZE"))
  'int)

(deftest "sysvar-xcomparebaksize-getvar-default"
  '((operator . "XCOMPAREBAKSIZE") (area . "sysvar") (profile . STRICT))
  '(getvar "XCOMPAREBAKSIZE")
  500)

(deftest "sysvar-xcomparecolormode-getvar-type"
  '((operator . "XCOMPARECOLORMODE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XCOMPARECOLORMODE"))
  'int)

(deftest "sysvar-xcomparecolormode-getvar-default"
  '((operator . "XCOMPARECOLORMODE") (area . "sysvar") (profile . STRICT))
  '(getvar "XCOMPARECOLORMODE")
  1)

(deftest "sysvar-xcompareenable-getvar-type"
  '((operator . "XCOMPAREENABLE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XCOMPAREENABLE"))
  'int)

(deftest "sysvar-xcompareenable-getvar-default"
  '((operator . "XCOMPAREENABLE") (area . "sysvar") (profile . STRICT))
  '(getvar "XCOMPAREENABLE")
  1)

(deftest "sysvar-xdwgfadectl-getvar-type"
  '((operator . "XDWGFADECTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XDWGFADECTL"))
  'int)

(deftest "sysvar-xedit-getvar-type"
  '((operator . "XEDIT") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XEDIT"))
  'int)

(deftest "sysvar-xedit-getvar-default"
  '((operator . "XEDIT") (area . "sysvar") (profile . STRICT))
  '(getvar "XEDIT")
  1)

(deftest "sysvar-xfadectl-getvar-type"
  '((operator . "XFADECTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XFADECTL"))
  'int)

(deftest "sysvar-xloadctl-getvar-type"
  '((operator . "XLOADCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XLOADCTL"))
  'int)

(deftest "sysvar-xloadpath-getvar-type"
  '((operator . "XLOADPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XLOADPATH"))
  'str)

(deftest "sysvar-xnotifytime-getvar-type"
  '((operator . "XNOTIFYTIME") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XNOTIFYTIME"))
  'int)

(deftest "sysvar-xnotifytime-getvar-default"
  '((operator . "XNOTIFYTIME") (area . "sysvar") (profile . STRICT))
  '(getvar "XNOTIFYTIME")
  5)

(deftest "sysvar-xrefctl-getvar-type"
  '((operator . "XREFCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XREFCTL"))
  'int)

(deftest "sysvar-xrefctl-getvar-default"
  '((operator . "XREFCTL") (area . "sysvar") (profile . STRICT))
  '(getvar "XREFCTL")
  0)

(deftest "sysvar-xreflayer-getvar-type"
  '((operator . "XREFLAYER") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XREFLAYER"))
  'str)

(deftest "sysvar-xreflayer-getvar-default"
  '((operator . "XREFLAYER") (area . "sysvar") (profile . STRICT))
  '(getvar "XREFLAYER")
  "use current")

(deftest "sysvar-xrefnotify-getvar-type"
  '((operator . "XREFNOTIFY") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XREFNOTIFY"))
  'int)

(deftest "sysvar-xrefoverride-getvar-type"
  '((operator . "XREFOVERRIDE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XREFOVERRIDE"))
  'int)

(deftest "sysvar-xrefregappctl-getvar-type"
  '((operator . "XREFREGAPPCTL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XREFREGAPPCTL"))
  'int)

(deftest "sysvar-xrefregappctl-getvar-default"
  '((operator . "XREFREGAPPCTL") (area . "sysvar") (profile . STRICT))
  '(getvar "XREFREGAPPCTL")
  2)

(deftest "sysvar-xreftype-getvar-type"
  '((operator . "XREFTYPE") (area . "sysvar") (profile . STRICT))
  '(type (getvar "XREFTYPE"))
  'int)

(deftest "sysvar-xreftype-getvar-default"
  '((operator . "XREFTYPE") (area . "sysvar") (profile . STRICT))
  '(getvar "XREFTYPE")
  0)

(deftest "sysvar-zoomfactor-getvar-type"
  '((operator . "ZOOMFACTOR") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ZOOMFACTOR"))
  'int)

(deftest "sysvar-zoomwheel-getvar-type"
  '((operator . "ZOOMWHEEL") (area . "sysvar") (profile . STRICT))
  '(type (getvar "ZOOMWHEEL"))
  'int)

(deftest "sysvar-_toolpalettepath-getvar-type"
  '((operator . "_TOOLPALETTEPATH") (area . "sysvar") (profile . STRICT))
  '(type (getvar "_TOOLPALETTEPATH"))
  'str)

