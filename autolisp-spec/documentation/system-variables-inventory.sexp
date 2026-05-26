;;;; -*- Mode: Lisp; coding: utf-8 -*-
;;;; Phase 1 deliverable: enumerated AutoCAD + BricsCAD system
;;;; variables. Generated from help.bricsys.com (V25) and
;;;; help.autodesk.com (2026 ENU). One plist per sysvar,
;;;; sorted alphabetically by :NAME.
;;;;
;;;; Schema: see issues/open/system-variables.issue.
;;;; Provenance: every record carries :versions and :source.

(
  :name "ACADLSPASDOC"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "on_start.lsp for each doc: Loads the on_start_default.lsp, on_start.lsp, on_doc_load.lsp and on_doc_load_default.lsp files, for every new drawing. If off, only loads these files for the first drawing."
  :coupled ("load")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/acadlspasdoc-system-variable")
)

(
  :name "ACADPREFIX"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Program folder path: List of support paths, with path separators if necessary."
  :coupled ("findfile" "getenv")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/acadprefix-system-variable")
)

(
  :name "ACADVER"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "AutoCAD version: Shows the AutoCAD® compatible program version number."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/acadver-system-variable")
)

(
  :name "ACISHLRRESOLUTION"
  :type :real
  :default -1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hidden line removal resolution: Controls the smallest distance used for Hidden Line Removal calculation. Negative value is Auto-calibration based on the size of the model (recommended). For very small entities the value can be set to 0.001 or smaller. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/acishlrresolution-system-variable")
)

(
  :name "ACISOUTVER"
  :type :short
  :default 70
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Acisout version: Controls the ACIS version of the SAT files for the ACISOUT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/acisoutver-system-variable")
)

(
  :name "ACISSAVEASMODE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Acis save as mode: Controls the explode mode of ACIS entities (3DSolids, Bodies, Regions) when saved to R12. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/acissaveasmode-system-variable")
)

(
  :name "ADAPTIVEGRIDSTEPSIZE"
  :type :real
  :default 4.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Adaptive grid step size: Controls the snap spacing for 'Adaptive Grid Snap' mode of SNAPTYPE system variable, in pixels. Also Controls the step size of the Manipulator ruler. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/adaptivegridstepsize-system-variable")
)

(
  :name "AFLAGS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 63)
  :bitcoded T
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Attribute options: Sets the default options for attribute creation."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/aflags-system-variable")
)

(
  :name "ALIGNDIMENSIONONISOMETRIC"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Dimension alignment: Enables isometric dimensions. Dimensions are aligned to the geometry. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/aligndimensiononisometric-system-variable")
)

(
  :name "ALLOWEDBENDANGLES"
  :type :short
  :default 1
  :read-only NIL
  :range (1 31)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Allowed bend angles: Sets allowed bend angles for MEP elements. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/allowedbendangles-system-variable")
)

(
  :name "ALLOWTABEXTERNALMOVE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Move tabs externally (Mac & Linux): Allows a tab to be moved to another tab control, in the documents tab. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/allowtabexternalmove-system-variable")
)

(
  :name "ALLOWTABMOVE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Move tabs (Mac & Linux): Allows a tab to be dragged horizontally, in the documents tab. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/allowtabmove-system-variable")
)

(
  :name "ALLOWTABSPLIT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Split tabs (Mac & Linux): Allows drag to split the tab control, in the documents tab. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/allowtabsplit-system-variable")
)

(
  :name "AMPOWERDIMDISPLAY"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mechanical 2D Editor: Controls the opening the Edit Dimensioning dialog box after placing a power dimension. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/ampowerdimdisplay-system-variable")
)

(
  :name "AMSYMSCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Mechanical2D annotation scaling: Controls the display of Mechanical2D symbols and text in Model Space."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/amsymscale-system-variable")
)

(
  :name "ANGBASE"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Angle base: Controls the start location of angle 0."
  :coupled ("angtos" "angle" "getangle" "getorient" "rtos")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/angbase-system-variable")
)

(
  :name "ANGDIR"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Angle direction: Toggles the angle direction clockwise/Counterclockwise."
  :coupled ("angtos" "angle" "getangle" "getorient")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/angdir-system-variable")
)

(
  :name "ANNOALLVISIBLE"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Annotation visibility: Hides or displays annotative entities that do not support the current annotation scale. The setting is saved individually for model space and each layout."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/annoallvisible-system-variable")
)

(
  :name "ANNOAUTOSCALE"
  :type :short
  :default -4
  :read-only NIL
  :range NIL
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Annotation scaling: Synchronizes new annotative entities with the current annotation scale."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/annoautoscale-system-variable")
)

(
  :name "ANNOMONITOR"
  :type :short
  :default -2
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Annotation monitor: Turns the annotation monitor on or off. When ON, a warning sign is displayed near the disassociated dimension."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/annomonitor-system-variable")
)

(
  :name "ANNOTATIVEDWG"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Annotative drawing: Creates an annotative block when this drawing is inserted into another drawing. Note: The ANNOTATIVEDWG system variable becomes read-only if the drawing contains annotative entities"
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/annotativedwg-system-variable")
)

(
  :name "ANTIALIASRENDER"
  :type :short
  :default 2
  :read-only NIL
  :range (1 5)
  :bitcoded T
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Anti-alias amount for render: Controls the smoothness of the output of the RENDER command. For values higher than 1, an anti-aliased output is calculated, at a cost, this increases with bigger values. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/antialiasrender-system-variable")
)

(
  :name "ANTIALIASSCREEN"
  :type :short
  :default 1
  :read-only NIL
  :range (1 5)
  :bitcoded T
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Anti-alias amount for screen: Controls the smoothness of display output. When the value is greater than 1, the RedSdkLineSmoothing option is ignored. For values greater than 1, an anti-aliased output is calculated. This calculation incurs a performance cost which increases with the value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/antialiasscreen-system-variable")
)

(
  :name "APBOX"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Entity snap aperture box: Displays the Entity Snap aperture box, at the cursor, during a pick action. Entity snaps are activated when the aperture box passes over an entity. See also the APERTURE system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/apbox-system-variable")
)

(
  :name "APERTURE"
  :type :short
  :default 10
  :read-only NIL
  :range (1 50)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Entity snap sensitivity: Controls the Aperture Box size, in pixels. Entity snaps are activated when the aperture box passes over an entity. To display the aperture box switch on the APBOX system variable. Values between 1 and 50 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/aperture-system-variable")
)

(
  :name "AREA"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Area: The last calculated area by the AREA, LIST or DBLIST commands."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/area-system-variable")
)

(
  :name "AREAPREC"
  :type :short
  :default -1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Area precision: Controls the number of decimal places displayed for areas, if area properties are formatted with the PROPUNITS system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/areaprec-system-variable")
)

(
  :name "AREAUNITS"
  :type :string
  :default "in ft mi µm mm cm m km"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Area units: Controls a list of units used to display areas, if area properties are formatted with the PROPUNITS system variable. If empty, all areas match the drawing. Note: The string contains a space-separated list of unit abbreviations. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/areaunits-system-variable")
)

(
  :name "ARRAYASSOCIATIVITY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Associative arrays: Creates new arrays as associative arrays."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/arrayassociativity-system-variable")
)

(
  :name "ARRAYEDITSTATE"
  :type :integer
  :default 0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Array edit state: Displays if an associative array's source entity is currently being edited."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/arrayeditstate-system-variable")
)

(
  :name "ARRAYTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Array type: Controls the default associative array type. See also the ARRAYASSOCIATIVITY system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/arraytype-system-variable")
)

(
  :name "ATTDIA"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Attribute dialog: Shows a dialog box for attribute values for the INSERT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/attdia-system-variable")
)

(
  :name "ATTFULLUPDATE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Reset attributes after editing the block record: If on, the attributes in the associated block references are synchronized. That is, their parameters, such as rotation angle, position, height of the font, etc. (except the text values), are set in accordance with those of the attribute definitions. Additionally, the missing attributes are restored, and those that have no definitions are removed. If off, nothing is done. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/attfullupdate-system-variable")
)

(
  :name "ATTMODE"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Attribute display mode: Controls the display of attributes. Note: If the ATTMODE variable is set to 2, all attributes display, including Hidden attributes."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/attmode-system-variable")
)

(
  :name "ATTRACTIONDISTANCE"
  :type :short
  :default 4
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Grips attraction distance: Sets the grip attraction distance. See also the ENABLEATTRACTION system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/attractiondistance-system-variable")
)

(
  :name "ATTREQ"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Insertion default settings: Controls attribute settings for a block inserted with the INSERT command. If off, uses default values. If on, uses a prompt."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/attreq-system-variable")
)

(
  :name "AUDITCTL"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Audit control: Creates an audit report (ADT) file when the AUDIT command is used. When you turn on the AUDITCTL settings variable, AUDIT creates an ASCII file describing problems and the action taken. This report, with the file extension ADT, is placed in the same directory as the current drawing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/auditctl-system-variable")
)

(
  :name "AUDITERRORCOUNT"
  :type :short
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Audit Error Count: The number of errors found in the last audit (AUDIT command)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/auditerrorcount-system-variable")
)

(
  :name "AUNITS"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Angular unit type: Controls the unit type for angles."
  :coupled ("angtos" "getangle" "getorient")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/aunits-system-variable")
)

(
  :name "AUPREC"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Angular unit precision: Controls the number of decimal places for angular units."
  :coupled ("angtos" "getangle" "getorient")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/auprec-system-variable")
)

(
  :name "AUTOCOMPLETEDELAY"
  :type :real
  :default 0.3
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Auto complete delay: Controls the delay before features display at the Command line. See also the AUTOCOMPLETEMODE system variable. Values between 0.0 and 10.0 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/autocompletedelay-system-variable")
)

(
  :name "AUTOCOMPLETEMODE"
  :type :short
  :default 47
  :read-only NIL
  :range (0 63)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Auto complete mode: Controls the types features shown at the Command line."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/autocompletemode-system-variable")
)

(
  :name "AUTOMATICCONNECTION"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Automatic connection: Controls automatic creation of connections for the BIMLINEARSOLID and BIMAPPLYPROFILE commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/automaticconnection-system-variable")
)

(
  :name "AUTOMATICSTAIRSECTIONBEHAVIOR"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Automatic stair section behavior: Controls the generation of 2D representations of BIM stair entities during a section generation. Affects only the automatic stair sectioning behavior. See the BIMGENERATE2DSTAIR command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/automaticstairsectionbehavior-system-variable")
)

(
  :name "AUTOMATICTEES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Automatic tees: Controls the automatic creation of T type connections during the BIMFLOWCONNECT command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/automatictees-system-variable")
)

(
  :name "AUTORESETSCALES"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Purge unused scales: Controls how unused annotation scales are managed, when a drawing containing a large number of scales is loaded. A large number of annotation scales decreases performance. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/autoresetscales-system-variable")
)

(
  :name "AUTOSAVECHECKSONLYFIRSTBITDBMOD"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Ignore all but first bit of DBMOD for autosave: Does not create autosave files for drawings, when they have been viewed but not edited (includes zoom and pan actions). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/autosavechecksonlyfirstbitdbmod-system-variable")
)

(
  :name "AUTOSNAP"
  :type :short
  :default 127
  :read-only NIL
  :range (0 127)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "AutoSnap: Toggles polar and entity snap tracking and controls the display of a snap marker, tooltips and magnet."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/autosnap-system-variable")
)

(
  :name "AUTOTRACKINGVECCOLOR"
  :type :short
  :default 171
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Auto tracking vector color: Controls the color of polar/snap tracking markers."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/autotrackingveccolor-system-variable")
)

(
  :name "AUTOVPFITTING"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Automatically resize viewports: Controls if viewport borders automatically adjust to fit, when a viewport is updated. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/a/autovpfitting-system-variable")
)

(
  :name "BACKGROUNDPLOT"
  :type :short
  :default 2
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Background plotting: Controls if background plotting is enabled for plot and/or publish actions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/backgroundplot-system-variable")
)

(
  :name "BACKZ"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Back clipping plane offset: The value of the CLipping option of the DVIEW command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/backz-system-variable")
)

(
  :name "BASEFILE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Template: The file path and default template file name for new drawings. If empty, uses built-in defaults. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/basefile-system-variable")
)

(
  :name "BCFSOURCEURL"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "BCF source url: The address (URL) of the BCF source. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bcfsourceurl-system-variable")
)

(
  :name "BEDITASSOCMODE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Associative identifiers in BEDIT: Controls if additional service data is generated during the BEDIT command. This enables the automatic re-association of constraints and dimensions attached to the references of the block, including references in other documents. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/beditassocmode-system-variable")
)

(
  :name "BILLOFMATERIALSSETTINGS"
  :type :short
  :default 10
  :read-only NIL
  :range NIL
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bill of materials defaults: Sets the default options for BOMs (Bill Of Materials). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/billofmaterialssettings-system-variable")
)

(
  :name "BIMDEFAULTPROPERTIESPATH"
  :type :string
  :default "bimproj_user.xml;bimproj_IFC.xml;bimproj_quantity.xml"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default properties path: The file paths for properties, loaded when a new document is opened. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bimdefaultpropertiespath-system-variable")
)

(
  :name "BIMMATCHPROP"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Match BIM Properties: Matches BIM properties during the MATCHPROP command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bimmatchprop-system-variable")
)

(
  :name "BIMOSMODE"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "BIM snap mode: Overrules the OSMODE and 3DOSMODE system variables for BIM entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bimosmode-system-variable")
)

(
  :name "BIMPROFILESTANDARDS"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Profile’s standards: Controls the profiles standards used in the Profiles dialog box and panel. Separate entries with semicolons (;). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bimprofilestandards-system-variable")
)

(
  :name "BINDTYPE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Xref bind type: Controls how XRefs names are handled when XRefs are bound or edited in place. If on, uses insert-like behavior. If off, uses traditional bind behavior."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bindtype-system-variable")
)

(
  :name "BKGCOLOR"
  :type :string
  :default "RGB:24,25,28"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Background color: Controls the background color of the drawing window in model space. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bkgcolor-system-variable")
)

(
  :name "BKGCOLORPS"
  :type :string
  :default "RGB:250,250,250"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Paper space background color: Controls the background color of the drawing window in paper space. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bkgcolorps-system-variable")
)

(
  :name "BLIPMODE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Blip mode: Determines whether or not marker blips are displayed."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/blipmode-system-variable")
)

(
  :name "BLOCKEDITLOCK"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Block editor lock: Disables the Block Editor (BEdit mode). Blocks cannot be edited."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/blockeditlock-system-variable")
)

(
  :name "BLOCKEDITOR"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Block editor: Shows if the Block Editor (BEdit mode) is open or not."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/blockeditor-system-variable")
)

(
  :name "BLOCKIFYMODE"
  :type :short
  :default 71
  :read-only NIL
  :range (0 871)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Blockify settings: Controls the behavior of the BLOCKIFY command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/blockifymode-system-variable")
)

(
  :name "BLOCKIFYTOLERANCE"
  :type :real
  :default -1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Blockify tolerance: Controls the relative tolerance used in the BLOCKIFY command to determine if two entities are equal. A negative value means the program will determine the optimal tolerance (recommended). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/blockifytolerance-system-variable")
)

(
  :name "BLOCKLEVELOFDETAIL"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Block Level of detail: Controls the block level of detail (LOD). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/blocklevelofdetail-system-variable")
)

(
  :name "BLOCKSPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Blocks path: Specifies the file path used for the fifth folder on the left side of the Select Drawing File dialog box, opened with the INSERT command when the Browse option is selected. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/blockspath-system-variable")
)

(
  :name "BMAUTOUPDATE"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Update external components: Controls when external assembly components are reloaded to reflect the changes in their definition files. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bmautoupdate-system-variable")
)

(
  :name "BMEXTERNALIZEILLEGALSYMBOLS"
  :type :short
  :default 3
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Illegal symbols treatment: Defines treatment of symbols that are not allowed in file names. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bmexternalizeillegalsymbols-system-variable")
)

(
  :name "BMFORMTEMPLATEPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "BMFORM template path: The file path and name of the default BMFORM command Template file. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bmformtemplatepath-system-variable")
)

(
  :name "BMTOOLPATH"
  :type :string
  :default "C:\\Program Files\\Bricsys\\BricsCAD V26 en_US\\UserDataCache\\Support\\en_US\\DesignLibrary\\Tools\\"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Assembly Inspect tool search paths: The file paths used for searching tool files in Assembly Inspect. Separate file paths with semicolons (;). If left empty, it defaults to the installed Design library Tools folder. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bmtoolpath-system-variable")
)

(
  :name "BMUPDATEMODE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Assembly components update mode: Controls if external assembly components are reloaded if they are modified, or unconditionally. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bmupdatemode-system-variable")
)

(
  :name "BOLTINGASMDEFAULTLENGTHINCREMENT"
  :type :real
  :default 25.4
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default length increment: Controls the default length increment for the default stud, see the BOLTINGASMDEFAULTSTUD system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/boltingasmdefaultlengthincrement-system-variable")
)

(
  :name "BOLTINGASMDEFAULTNUT"
  :type :string
  :default "ASME B18.2.2 Heavy Hex Nut"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default nut: Controls the default nut used to generate bolt assemblies. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/boltingasmdefaultnut-system-variable")
)

(
  :name "BOLTINGASMDEFAULTNUTSNUMBER"
  :type :short
  :default 4
  :read-only NIL
  :range (2 4)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default nuts number: Controls the default nuts number used to generate bolt assemblies. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/boltingasmdefaultnutsnumber-system-variable")
)

(
  :name "BOLTINGASMDEFAULTSTUD"
  :type :string
  :default "ASME B18.31.2 Continuous Thread Flange Bolting Stud"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default stud: Controls the default stud used to generate bolt assemblies. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/boltingasmdefaultstud-system-variable")
)

(
  :name "BOMFILTERSETTINGS"
  :type :short
  :default 1
  :read-only NIL
  :range (0 127)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default BOM filter settings: Sets the default filter settings, defines which objects to include. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bomfiltersettings-system-variable")
)

(
  :name "BOMPROPERTYSET"
  :type :short
  :default 1
  :read-only NIL
  :range (1 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default BOM property set: Sets the default set of properties for BOM tables. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bompropertyset-system-variable")
)

(
  :name "BOMTEMPLATE"
  :type :string
  :default "\" \""
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default template: Controls the file path for the default BOM template. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bomtemplate-system-variable")
)

(
  :name "BOMTHUMBNAILHEIGHT"
  :type :short
  :default 200
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default thumbnail height, px: Sets the default thumbnail height for BOM (Bill Of Material) tables, in pixels. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bomthumbnailheight-system-variable")
)

(
  :name "BOMTHUMBNAILWIDTH"
  :type :short
  :default 200
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default thumbnail width, px: Sets the default thumbnail width for BOM tables, in pixels. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bomthumbnailwidth-system-variable")
)

(
  :name "BOUNDARYCOLOR"
  :type :short
  :default 95
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Detected Boundary Color: Controls the color used to detect boundaries. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/boundarycolor-system-variable")
)

(
  :name "BSYSLIBCOPYOVERWRITE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bsyslib copy overwrite: Controls how materials or compositions with a name that already exists in the target drawing are copied. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bsyslibcopyoverwrite-system-variable")
)

(
  :name "BVMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Block Visibility Mode: Controls how hidden entities are displayed in Block Editor ."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/b/bvmode-system-variable")
)

(
  :name "CACHELAYOUT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Cache layout: Caches layouts - reduces the time needed to switch between layouts. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cachelayout-system-variable")
)

(
  :name "CAMERADISPLAY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Camera display: Displays a visual representation of a camera for all camera locations."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cameradisplay-system-variable")
)

(
  :name "CAMERAHEIGHT"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Camera height: Controls the default height, in drawing units, for new cameras."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cameraheight-system-variable")
)

(
  :name "CANNOSCALE"
  :type :string
  :default "1:1"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Annotation scale name: Controls the name of the current annotation scale for the current space."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cannoscale-system-variable")
)

(
  :name "CANNOSCALEVALUE"
  :type :real
  :default 1.0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Annotation scale value: Displays the value of the current annotation scale."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cannoscalevalue-system-variable")
)

(
  :name "CDATE"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Calendar date: Shows the current date and time, in decimal format."
  :coupled ("menucmd")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cdate-system-variable")
)

(
  :name "CECOLOR"
  :type :string
  :default "ByLayer"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Entity color: Sets the color for new entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cecolor-system-variable")
)

(
  :name "CELTSCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Entity linetype scale: Sets the current entity linetype scale multiplier."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/celtscale-system-variable")
)

(
  :name "CELTYPE"
  :type :string
  :default "ByLayer"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Entity linetype: Sets the linetype for new entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/celtype-system-variable")
)

(
  :name "CELWEIGHT"
  :type :short
  :default -1
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Entity lineweight: Sets the lineweight of new entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/celweight-system-variable")
)

(
  :name "CENTERCROSSGAP"
  :type :string
  :default "0.05x"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Center mark cross gap: Controls the gap between the center mark and its centerlines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/centercrossgap-system-variable")
)

(
  :name "CENTERCROSSSIZE"
  :type :string
  :default "0.1x"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Center mark cross size: Controls the size of an associative center mark."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/centercrosssize-system-variable")
)

(
  :name "CENTEREXE"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Centerline extension length: Controls the extension length of a centerline."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/centerexe-system-variable")
)

(
  :name "CENTERLAYER"
  :type :string
  :default "."
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Default layer for center mark or centerline: Controls a default layer for new centermarks or centerlines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/centerlayer-system-variable")
)

(
  :name "CENTERLTSCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Linetype scale for center mark or centerline: Controls the linetype scale used to create center marks and centerlines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/centerltscale-system-variable")
)

(
  :name "CENTERLTYPE"
  :type :string
  :default "CENTER2"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Center mark/centerline linetype: Controls the linetype used by center marks and centerlines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/centerltype-system-variable")
)

(
  :name "CENTERLTYPEFILE"
  :type :string
  :default "Default in imperial unit drawings: default.lin . Default in metric unit drawings: iso.lin ."
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Linetype file for center mark or centerline: Controls the linetype file used to create center marks and centerlines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/centerltypefile-system-variable")
)

(
  :name "CENTERMARKEXE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Automatic extension for center mark or centerline: Automatically extends centerlines for new center marks and centerlines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/centermarkexe-system-variable")
)

(
  :name "CETRANSPARENCY"
  :type :string
  :default "ByLayer"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Transparency: Sets the transparency for new entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cetransparency-system-variable")
)

(
  :name "CHAMFERA"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Chamfer first distance: Controls the first chamfer distance when the CHAMMODE system variable is Distance-Distance."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/chamfera-system-variable")
)

(
  :name "CHAMFERB"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Chamfer second distance: Controls the second chamfer distance when the CHAMMODE system variable is Distance-Distance."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/chamferb-system-variable")
)

(
  :name "CHAMFERC"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Chamfer length: Controls the chamfer length when the CHAMMODE system variable is Length-Angle."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/chamferc-system-variable")
)

(
  :name "CHAMFERD"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Chamfer angle: Controls the chamfer angle when the CHAMMODE system variable is Length-Angle."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/chamferd-system-variable")
)

(
  :name "CHAMMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Chamfer mode: Controls the default chamfer creation method."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/chammode-system-variable")
)

(
  :name "CHECKDWLPRESENCE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Check DWL file existence before open: Warn if there is a DWL lock file when a drawing is opened, indicates that another user has the drawing open. The content of the lock files allows to inform other users trying to open that drawing, that it is in use, since when, and by whom. This is typically useful for drawings on a shared folder that can be accessed by multiple users from different operating systems. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/checkdwlpresence-system-variable")
)

(
  :name "CIRCLERAD"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Circle radius: Controls the default circle radius. A value of zero means no default."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/circlerad-system-variable")
)

(
  :name "CIRCULARARROWHEADLENGTH"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default head length: Sets the default head length of circular arrows. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/circulararrowheadlength-system-variable")
)

(
  :name "CIRCULARARROWHEADWIDTH"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default head width: Sets the default head width of circular arrows. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/circulararrowheadwidth-system-variable")
)

(
  :name "CIRCULARARROWLEADERRADIUS"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default leader radius: Sets the default leader radius of circular arrows. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/circulararrowleaderradius-system-variable")
)

(
  :name "CIRCULARARROWLEADERROTATION"
  :type :real
  :default 90.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default leader rotation: Sets the default leader rotation of circular arrows. Values between 20.0 and 320.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/circulararrowleaderrotation-system-variable")
)

(
  :name "CIRCULARARROWTHICKNESS"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default thickness: Sets the default thickness of circular arrows. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/circulararrowthickness-system-variable")
)

(
  :name "CLAYER"
  :type :string
  :default "0"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Current layer: Sets the layer for new entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/clayer-system-variable")
)

(
  :name "CLEANSCREENOPTIONS"
  :type :short
  :default 15
  :read-only NIL
  :range (0 127)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Clean screen options: Controls which UI elements are hidden by the CLEANSCREENON command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cleanscreenoptions-system-variable")
)

(
  :name "CLEANSCREENSTATE"
  :type :integer
  :default 0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Clean screen state: Indicates if clean screen state is active. Use the CLEANSCREENON and CLEANSCREENOFF commands. Activating the clean screen state makes the drawing area larger by hiding elements of the user interface."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cleanscreenstate-system-variable")
)

(
  :name "CLIPBOARDFORMAT"
  :type :short
  :default 4
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Clipboard DWG format: Controls the drawing format version used to copy to the clipboard. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/clipboardformat-system-variable")
)

(
  :name "CLIPBOARDFORMATS"
  :type :short
  :default 127
  :read-only NIL
  :range (0 127)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Clipboard Formats: Controls the types of data that can be copied to the clipboard. Reduce the number of data types to improve performance. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/clipboardformats-system-variable")
)

(
  :name "CLIPROMPTLINES"
  :type :short
  :default 4
  :read-only NIL
  :range (0 64)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Prompt Lines: Controls the maximum number of floating lines of text momentarily displayed above the Command line. Applies only if the Command line is hidden, or floating with the CMDLINEUSEMINIFRAME system variable set to on (1). Values between 0 and 64 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/clipromptlines-system-variable")
)

(
  :name "CLISTATE"
  :type :integer
  :default 1
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Command line state: Command line status."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/clistate-system-variable")
)

(
  :name "CLOSECHECKSONLYFIRSTBITDBMOD"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Ignore all but first bit of DBMOD for close: If on, does not ask to save drawings, when they have been viewed but not edited (includes zoom and pan actions). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/closechecksonlyfirstbitdbmod-system-variable")
)

(
  :name "CLOUDDOWNLOADPATH"
  :type :string
  :default "{User}Documents/Bricsys247"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Cloud download path: The folder path for files downloaded through the Bricsys 24/7 Panel. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/clouddownloadpath-system-variable")
)

(
  :name "CLOUDLOG"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Cloud log: Controls if data exchanged with Bricsys 24/7 is logged or not. If set to \"Log file\" a log file will be written in the folder set in the LOGFILEPATH system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cloudlog-system-variable")
)

(
  :name "CLOUDLOGVERBOSE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Cloud log verbose: Creates a verbose log for Bricsys 24/7. If switched on, more information is logged and Bricsys 24/7 actions will be slower. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cloudlogverbose-system-variable")
)

(
  :name "CLOUDONMODIFIED"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Cloud on modified: Specifies what to do when a file opened from Bricsys 24/7 is modified and saved locally. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cloudonmodified-system-variable")
)

(
  :name "CLOUDSERVER"
  :type :string
  :default "https://my.bricsys247.com/"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Cloud server: The address of the Bricsys 24/7 server. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cloudserver-system-variable")
)

(
  :name "CLOUDSSOCLIENTID"
  :type :string
  :default "bricscad"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Cloud SSO Client ID: The client_id used to connect to the SSO service. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cloudssoclientid-system-variable")
)

(
  :name "CLOUDSSOSCOPE"
  :type :string
  :default "openid profile email"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Cloud SSO Scope: Controls scopes or permissions used to connect to the SSO service. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cloudssoscope-system-variable")
)

(
  :name "CLOUDTEMPFOLDER"
  :type :string
  :default "{User}AppData/Local/Temp/Bricsys_24_7"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Cloud temporary folder: The file path for temporary Bricsys 24/7 files. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cloudtempfolder-system-variable")
)

(
  :name "CLOUDUPLOADDEPENDENCIES"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Cloud upload dependencies: Controls what to do with dependencies, such as XRefs, when a drawing is uploaded to Bricsys 24/7. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/clouduploaddependencies-system-variable")
)

(
  :name "CMATERIAL"
  :type :string
  :default "ByLayer"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Current material: Controls the default render material for new entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmaterial-system-variable")
)

(
  :name "CMDACTIVE"
  :type :short
  :default 1
  :read-only T
  :range NIL
  :bitcoded T
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Active command: Indicates the type of the current command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdactive-system-variable")
)

(
  :name "CMDDIA"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command dialogs: Controls if dialog boxes are shown for commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmddia-system-variable")
)

(
  :name "CMDECHO"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Command echo: Displays prompts and input during a LISP 'command' function."
  :coupled ("command" "vl-cmdf")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdecho-system-variable")
)

(
  :name "CMDLINEEDITBGCOLOR"
  :type :string
  :default "RGB: 50 54 56 (Settings dialog) #323638 (Command line)"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line edit background color: The Command line edit field background color. Color may be represented as a name (for standard colors) or as RGB values. At the Command line, color may be entered as a name (for standard colors), RGB values, or HTML color. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlineeditbgcolor-system-variable")
)

(
  :name "CMDLINEEDITFGCOLOR"
  :type :string
  :default "White (Settings dialog) #FFFFFF (Command line)"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line edit foreground color: The Command line edit field foreground color. Color may be represented as a name (for standard colors) or as RGB values. At the Command line, color may be entered as a name (for standard colors), RGB values, or HTML color. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlineeditfgcolor-system-variable")
)

(
  :name "CMDLINEFADINGLOGBGCOLOR"
  :type :string
  :default "RGB: 50 54 56 (Settings dialog) #323638 (Command line)"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line fade log background color: The Command line fade log background color. Color may be represented as a name (for standard colors) or as RGB values. At the Command line, color may be entered as a name (for standard colors), RGB values, or HTML color. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlinefadinglogbgcolor-system-variable")
)

(
  :name "CMDLINEFADINGLOGFADEDELAY"
  :type :real
  :default 2.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line fading log fade delay: The delay before Command line's log starts to fade. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlinefadinglogfadedelay-system-variable")
)

(
  :name "CMDLINEFADINGLOGFGCOLOR"
  :type :string
  :default "White"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line fade log foreground color: The Command line fade log foreground color. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlinefadinglogfgcolor-system-variable")
)

(
  :name "CMDLINEFADINGLOGTRANSPARENCY"
  :type :short
  :default 30
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line fade log transparency: Controls the Command line fade log transparency. Values between 0 and 100 are accepted. A value of zero means fully opaque, 100 is fully transparent. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlinefadinglogtransparency-system-variable")
)

(
  :name "CMDLINEFONTNAME"
  :type :string
  :default "Consolas"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line font name: The Command line font. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlinefontname-system-variable")
)

(
  :name "CMDLINEFONTSIZE"
  :type :short
  :default 10
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line font size: The height of the Command line font in pixels. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlinefontsize-system-variable")
)

(
  :name "CMDLINEFRAMEACTIVETRANSPARENCY"
  :type :short
  :default 10
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line frame transparency when active: Controls Command line frame transparency when active. Values between 0 and 100 are accepted. A value of zero means fully opaque, 100 if fully transparent. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlineframeactivetransparency-system-variable")
)

(
  :name "CMDLINEFRAMEINACTIVETRANSPARENCY"
  :type :short
  :default 30
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line frame transparency when inactive: Controls the Command line frame transparency when inactive. Values between 0 and 100 are accepted. A value of zero means fully opaque, 100 is fully transparent. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlineframeinactivetransparency-system-variable")
)

(
  :name "CMDLINEFRAMEUSETEXTSCR"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line frame TEXTSCR: When the Command line is floating, controls the effect of TEXTSCR command, also impacts log prompt delay. If on, displays a separate window, the same as in the docked state. If off, displays as a mini-frame. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlineframeusetextscr-system-variable")
)

(
  :name "CMDLINELISTBGCOLOR"
  :type :string
  :default "RGB:130,130,130"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line list background color: The Command line history list background color. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlinelistbgcolor-system-variable")
)

(
  :name "CMDLINELISTFGCOLOR"
  :type :string
  :default "White"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line list foreground color: The Command line history list foreground color. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlinelistfgcolor-system-variable")
)

(
  :name "CMDLINEOPTIONBGCOLOR"
  :type :string
  :default "RGB:121,132,142"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line option background color: The Command line options background color. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlineoptionbgcolor-system-variable")
)

(
  :name "CMDLINEOPTIONSHORTCUTCOLOR"
  :type :string
  :default "RGB:255,187,0"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line option shortcut color: The Command line option shortcut color. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlineoptionshortcutcolor-system-variable")
)

(
  :name "CMDLINEUSEMINIFRAME"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Command line mini floating frame: Controls if the mini-frame is used when the Command line floats. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlineuseminiframe-system-variable")
)

(
  :name "CMDLNTEXT"
  :type :string
  :default ":"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Prompt prefix: Controls the prefix text shown in the Command line when no command is active. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdlntext-system-variable")
)

(
  :name "CMDNAMES"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Active Command Name: The names of any active or transparent commands."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmdnames-system-variable")
)

(
  :name "CMLEADERSTYLE"
  :type :string
  :default "Standard"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Multileader style: Controls the multileader style for entities created with the MLEADER command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmleaderstyle-system-variable")
)

(
  :name "CMLJUST"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Multiline justification: Controls the justification of multilines relative to the cursor, for the MLINE command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmljust-system-variable")
)

(
  :name "CMLSCALE"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Multiline scale: Controls the overall distance between lines created with the MLINE command. A negative value mirrors the offset lines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmlscale-system-variable")
)

(
  :name "CMLSTYLE"
  :type :string
  :default "Standard"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Multiline style: Controls the multiline style for entities created with the MLINE command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmlstyle-system-variable")
)

(
  :name "CMPCLRMISS"
  :type :short
  :default 1
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of missing entities - DWGCOMPARE: Controls the color of missing entities during the DWGCOMPARE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmpclrmiss-system-variable")
)

(
  :name "CMPCLRMOD1"
  :type :short
  :default 253
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of modified entities- DWGCOMPARE: Controls the color of modified entities during the DWGCOMPARE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmpclrmod1-system-variable")
)

(
  :name "CMPCLRMOD2"
  :type :short
  :default 2
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of modified entities in the second drawing- DWGCOMPARE: Controls the color of modified entities in the second drawing during the DWGCOMPARE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmpclrmod2-system-variable")
)

(
  :name "CMPCLRNEW"
  :type :short
  :default 3
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of new entities in - DWGCOMPARE: Controls the color of new entities during the DWGCOMPARE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmpclrnew-system-variable")
)

(
  :name "CMPDIFFLIMIT"
  :type :integer
  :default 10000000
  :read-only NIL
  :range (1 10000000)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximum number of entities - DWGCOMPARE: Controls the limit for entities to compare during the DWGCOMPARE command. Values between 1 and 10,000,000 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmpdifflimit-system-variable")
)

(
  :name "CMPFADECTL"
  :type :short
  :default 80
  :read-only NIL
  :range (0 90)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Fade - DWGCOMPARE: Controls the fade level for unmodified entities during the DWGCOMPARE command. Values between 0 and 90 are accepted. A value of zero means Maximum opacity, 90 means maximum transparency. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmpfadectl-system-variable")
)

(
  :name "CMPLOG"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Log control - DWGCOMPARE: Toggles the creation of a log report (cmplog) for the DWGCOMPARE command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cmplog-system-variable")
)

(
  :name "COLORBOOKPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color book file search path: The file path(s) for color books. Separate file paths with semicolons (;). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/colorbookpath-system-variable")
)

(
  :name "COLORPICKBOX"
  :type :short
  :default 7
  :read-only NIL
  :range (0 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Pickbox color: Sets the color for the pickbox. Values between 0 and 255 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/colorpickbox-system-variable")
)

(
  :name "COLORTHEME"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UI color theme: Applies a dark or light color theme to the user interface."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/colortheme-system-variable")
)

(
  :name "COLORX"
  :type :short
  :default 11
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "X axis color: Controls the color of the X-axis. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/colorx-system-variable")
)

(
  :name "COLORY"
  :type :short
  :default 112
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Y axis color: Controls the color of the Y-axis. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/colory-system-variable")
)

(
  :name "COLORZ"
  :type :short
  :default 150
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Z axis color: Controls the color of the Z-axis. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/colorz-system-variable")
)

(
  :name "COMACADCOMPATIBILITY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "COM Acad compatibility: Use registry settings to improve support for existing VB applications. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/comacadcompatibility-system-variable")
)

(
  :name "COMBINETEXTMODE"
  :type :short
  :default 11
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Combined text mode: Controls the order of the text selection word-wrap method and linespacing style, for the TXT2MTXT command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/combinetextmode-system-variable")
)

(
  :name "COMMANDASSIST"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "AI Predict Command line: Controls the use of personalized, AI command suggestions. Only possible if Application Data collection is enabled in the DATACOLLECTIONOPTIONS system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/commandassist-system-variable")
)

(
  :name "COMMUNICATORBACKGROUNDMODE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Perform import and export in background: Enables user interaction while import or export is performed. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/communicatorbackgroundmode-system-variable")
)

(
  :name "COMMUNICATORPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Communicator path (Mac & Linux): The file path used to install the Communicator for BricsCAD . BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/communicatorpath-system-variable")
)

(
  :name "COMPASS"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Compass: Toggles the display of the 3D compass on/off in the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/compass-system-variable")
)

(
  :name "COMPONENTSCONFIG"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Library Panel Configuration: The name of the active Library panel configuration file. Controls what is shown in the Library panel. Use the SRCHPATH command to find the file. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/componentsconfig-system-variable")
)

(
  :name "COMPONENTSPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Library directory path: The file path(s) for user created components. Separate file paths with semicolons (;). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/componentspath-system-variable")
)

(
  :name "CONSTRAINTBARDISPLAY"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Constraint Display: Controls when constraints are shown."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/constraintbardisplay-system-variable")
)

(
  :name "CONTINUOUSMOTION"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Continuous motion: Controls if rotation continues after the mouse is released during the ROTATE commands BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/continuousmotion-system-variable")
)

(
  :name "CONVERTODMAX"
  :type :real
  :default 1.1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximal multiplier for an outer diameter: BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/convertodmax-system-variable")
)

(
  :name "CONVERTODMIN"
  :type :real
  :default 0.95
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Minimal multiplier for an outer diameter: BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/convertodmin-system-variable")
)

(
  :name "CONVERTTHMAX"
  :type :real
  :default 2.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximal multiplier for a thickness: BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/convertthmax-system-variable")
)

(
  :name "CONVERTTHMIN"
  :type :real
  :default 0.5
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Minimal multiplier for a thickness: BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/convertthmin-system-variable")
)

(
  :name "COORDS"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Coordinates: Controls the format and update frequency of the coordinate field in the Status bar."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/coords-system-variable")
)

(
  :name "COPYGUIDED3DDISPLAYSOURCEFACES"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "COPYGUIDED3D source faces: Displays source faces during the COPYGUIDED3D command. Source faces are used to position the copied entity/entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/copyguided3ddisplaysourcefaces-system-variable")
)

(
  :name "COPYMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Copy mode: Controls if the COPY command creates a single copy or multiple copies, by default."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/copymode-system-variable")
)

(
  :name "CPLOTSTYLE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Current plot style: Controls the plot style for new entities. In color-dependent mode drawings this is \"BYCOLOR\" and is read-only. In named-plot-style mode drawings, the options: \"BYLAYER\" (default), \"BYBLOCK\", \"NORMAL\" and \"USER DEFINED\", this can be changed. See also the PSTYLEMODE system variable. Use the CONVERTPSTYLES command to convert the current drawing to use named or color-dependent plot styles. Note: To convert the current drawing to use named or color-dependent..."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cplotstyle-system-variable")
)

(
  :name "CPROFILE"
  :type :string
  :default "Default"
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Current profile: The name of the current user profile."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cprofile-system-variable")
)

(
  :name "CRASHREPORTSENDING"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Crash report sending (Windows): Controls the preferences of sharing the crash report and showing the Crash report dialog box. Sending a crash report helps identify and fix any issues and improve BricsCAD for all users. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/crashreportsending-system-variable")
)

(
  :name "CREATESKETCHFEATURE"
  :type :integer
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Sketch based feature (experimental): Links 3D entities created with the EXTRUDE, LOFT, SWEEP, and REVOLVE commands and their options Subtract and Unite to the 2D entities used to create them and converts the 2D entities into a sketch. Any modifications to the sketch are reflected in the 3D entity. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/createsketchfeature-system-variable")
)

(
  :name "CREATETHUMBNAILONTHEFLY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Create preview thumbnail on the fly: Generates a preview thumbnail in the Open dialog box, if a drawing doesn't have a thumbnail. Does not apply if the drawing was saved with RASTERPREVIEW system variable switched on (1). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/createthumbnailonthefly-system-variable")
)

(
  :name "CREATEVIEWPORTS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Automatic viewport creation: Controls if a viewport is automatically included when a new layout is created. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/createviewports-system-variable")
)

(
  :name "CROSSHAIRDRAWMODE"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Crosshair rendering mode: Controls the way the mouse cursor is rendered while inside the drawing window (crosshair, pickbox, etc.) for 3D visualization. Rendering by RedSDK will be faster, but some old systems might not support rendering by RedSDK. In 2dwireframe, render the crosshair in OpengGL. Attempts to eliminate cursor duplicates or flickering, which may happen using the window toolkit. In RedSDK visual styles, render the crosshair by RedSDK. Rendering the cursor by..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/crosshairdrawmode-system-variable")
)

(
  :name "CROSSINGAREACOLOR"
  :type :short
  :default 91
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Crossing area color: Controls the color for the crossing selection areas (right-left). Note: In effect only when SELECTIONAREA setting is on."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/crossingareacolor-system-variable")
)

(
  :name "CTAB"
  :type :string
  :default "Model"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Current tab: The name of the current tab, model or layout."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/ctab-system-variable")
)

(
  :name "CTABLESTYLE"
  :type :string
  :default "Standard"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Current table style: Sets the table style for new table entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/ctablestyle-system-variable")
)

(
  :name "CTRL3DMOUSE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "3D mouse mode: Enables a 3Dconnexion 3D mouse. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/ctrl3dmouse-system-variable")
)

(
  :name "CTRLMBUTTON"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Middle Button Click: The CTRLMBUTTON system variable turns On or Off the Temporary tracking points entity snap when the middle mouse button (mouse wheel) is used during a command. If CTRLMBUTTON is set to 1 for ON , pressing the middle mouse button during a command runs the TK transparent shortcut and prompts you in the Command line to specify the temporary tracking points. This is the default option. If CTRLMBUTTON is set to 0 for OFf , the system variable turns Off the T..."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/ctrlmbutton-system-variable")
)

(
  :name "CTRLMOUSE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mouse shortcuts: Toggles mouse shortcuts on/off. For Windows and Linux short cuts include: Ctrl+Shift + Left button for realtime zoom. Ctrl+Shift + Right button for realtime pan. Ctrl + middle button for view rotation. Ctrl + right button for view rotation with fixed Z-axis. For macOS short cuts include: Cmd+Shift + Left button for realtime zoom. Cmd+Shift + Right button for realtime pan. Cmd + middle button for view rotation. Cmd + right button for view rotation with fixe..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/ctrlmouse-system-variable")
)

(
  :name "CURSORMODE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Crosshair displaying mode: Controls how the crosshair is displayed. Values 0 and 1 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cursormode-system-variable")
)

(
  :name "CURSORSIZE"
  :type :short
  :default 5
  :read-only NIL
  :range (1 100)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Crosshair size: Controls the crosshair size, as a percentage of the screen size."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cursorsize-system-variable")
)

(
  :name "CVALLOWBREAKLINECROSSINGS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Allow breakline crossings: If on, intersections between breakline segments are calculated and added as points to the TIN surface. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvallowbreaklinecrossings-system-variable")
)

(
  :name "CVANGLESAMPLINGINTERVAL"
  :type :real
  :default 5.0d0
  :read-only NIL
  :range (0 90)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Angle sampling interval: Controls the angle sampling interval in decimal degrees, used to round gradings at convex vertices. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvanglesamplinginterval-system-variable")
)

(
  :name "CVARCTESSELLATIONGRADING"
  :type :real
  :default 0.01
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Arc approximation mid-ordinate distance: Controls the grading mid-ordinate distance, the maximum distance between the arc and the chord (straight) segment, used for arc approximation. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvarctessellationgrading-system-variable")
)

(
  :name "CVARCTESSELLATIONSURFACE"
  :type :real
  :default 0.01
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Arc approximation mid-ordinate distance: Controls the surface mid-ordinate distance, the maximum distance between the arc and the chord (straight) segment, used for arc approximation. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvarctessellationsurface-system-variable")
)

(
  :name "CVARCTESSELLATIONTEMPLATEELEMENT"
  :type :real
  :default 0.01
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Template Element arc approximation mid-ordinate distance: Controls the corridor mid-ordinate distance (1), the maximum distance between the arc and the chord (straight) segment, used for arc approximation. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvarctessellationtemplateelement-system-variable")
)

(
  :name "CVASSOCIATIVITY"
  :type :short
  :default 15
  :read-only NIL
  :range NIL
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Associativity: Controls if Civil entities are associative. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvassociativity-system-variable")
)

(
  :name "CVDEFAULTCURVETYPEHA"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default curve type for horizontal alignment: Controls the curve type, used to create new horizontal alignment or to add a new PI. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvdefaultcurvetypeha-system-variable")
)

(
  :name "CVDEFAULTCURVETYPEVA"
  :type :short
  :default 2
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default curve type for vertical alignments: Controls the curve type, used to create new vertical alignment or to add a new PVI. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvdefaultcurvetypeva-system-variable")
)

(
  :name "CVELEVATIONATBREAKLINECROSSINGS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Elevation at breakline crossings: Controls the elevation at breakline crossings. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvelevationatbreaklinecrossings-system-variable")
)

(
  :name "CVERSIONCONTROLPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Current version control path: The file path used to store the current version control project. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cversioncontrolpath-system-variable")
)

(
  :name "CVGRADEUNIT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Format: Controls the unit format for grade units BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvgradeunit-system-variable")
)

(
  :name "CVGRADEUNITPREC"
  :type :short
  :default 2
  :read-only NIL
  :range (0 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Precision: Controls the number of decimal places displayed for grade units BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvgradeunitprec-system-variable")
)

(
  :name "CVLENGTHSAMPLINGINTERVAL"
  :type :real
  :default 1.00
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Sampling interval for straight segments: Controls the length of sampling intervals, used to sample straight segments. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvlengthsamplinginterval-system-variable")
)

(
  :name "CVPORT"
  :type :short
  :default 2
  :read-only NIL
  :range (1 NIL)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Current viewport: Changes the identification number of the current viewport on three conditions: The identification number is an active viewport. Cursor movement in that viewport is not locked by a command in progress. Tablet mode is off."
  :coupled ("vports" "setview")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvport-system-variable")
)

(
  :name "CVSLOPEUNIT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Format: Controls the unit format for slope units BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvslopeunit-system-variable")
)

(
  :name "CVSLOPEUNITPREC"
  :type :short
  :default 1
  :read-only NIL
  :range (0 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Precision: Controls the number of decimal places displayed for slope units BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvslopeunitprec-system-variable")
)

(
  :name "CVSTATIONUNIT"
  :type :short
  :default 3
  :read-only NIL
  :range (0 5)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Station delimiter position: Controls the delimiter position for station units BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvstationunit-system-variable")
)

(
  :name "CVSTATIONUNITPREC"
  :type :short
  :default 2
  :read-only NIL
  :range (0 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Precision: Controls the number of decimal places displayed for station units BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/c/cvstationunitprec-system-variable")
)

(
  :name "DATACOLLECTION"
  :type :short
  :default -2
  :read-only NIL
  :range (-2 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Diagnostics and usage data collection: Controls the sharing of anonymous usage data. This helps personalize the program and significantly enhances the user experience for everyone. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/datacollection-system-variable")
)

(
  :name "DATACOLLECTIONENABLED"
  :type :integer
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Current state of data collection: Controls diagnostic and usage data collection. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/datacollectionenabled-system-variable")
)

(
  :name "DATACOLLECTIONLOGINTYPE"
  :type :short
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Latest type of login for data collection: The login type for data collection. See the DATACOLLECTIONOPTIONS system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/datacollectionlogintype-system-variable")
)

(
  :name "DATACOLLECTIONOPTIONS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 7)
  :bitcoded T
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Data Collection Options: Controls what anonymous data is shared. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/datacollectionoptions-system-variable")
)

(
  :name "DATALINKNOTIFY"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Data link Notifications: Controls data link notifications."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/datalinknotify-system-variable")
)

(
  :name "DATE"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Current date: Shows the current date and time in Julian Day format."
  :coupled ("menucmd")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/date-system-variable")
)

(
  :name "DBCSTATE"
  :type :integer
  :default 0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "DbConnect state: Shows if the dbConnect Manager is active or not."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dbcstate-system-variable")
)

(
  :name "DBLCLKEDIT"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Double click editing: Enables Block Editor (BEdit mode) and Reference Editor (RefEdit mode) on double click of Blocks and XRefs."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dblclkedit-system-variable")
)

(
  :name "DBMOD"
  :type :short
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded T
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Modification status: The status of drawing modifications."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dbmod-system-variable")
)

(
  :name "DCTCUST"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Custom spelling dictionary: The file path and file name of the current, custom spelling dictionary. During a spelling check, the SPELL command matches the words in the drawing or the current selection set to the words in the current main dictionary and the current custom dictionary. Custom dictionaries are used for discipline-specific words, such as medical or mechanical."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dctcust-system-variable")
)

(
  :name "DCTMAIN"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Main spelling dictionary: The file name of the current, main spelling dictionary. Stored in the support folder. Note: Keywords can be used to set this variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dctmain-system-variable")
)

(
  :name "DEFAULTBSYSLIBIMPERIAL"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default Bsyslib imperial: Default location of the Bsyslib central database when MEASUREMENT is 0 (imperial). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultbsyslibimperial-system-variable")
)

(
  :name "DEFAULTBSYSLIBMETRIC"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default Bsyslib metric: Default location of the Bsyslib central database when MEASUREMENT is 1 (metric). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultbsyslibmetric-system-variable")
)

(
  :name "DEFAULTLIGHTING"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Default lighting: Controls if default lighting overrides other lights in the drawing. Default lighting is a distant light that follows the view direction, can be set per viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultlighting-system-variable")
)

(
  :name "DEFAULTLIGHTSHADOWBLUR"
  :type :short
  :default 8
  :read-only NIL
  :range (1 40)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default light shadow blur: Controls the default shadow blur for lights. Values between 1 and 40 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultlightshadowblur-system-variable")
)

(
  :name "DEFAULTNEWSHEETTEMPLATE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default new sheet template: The default drawing template file (DWG or DWT) for new sheets. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultnewsheettemplate-system-variable")
)

(
  :name "DEFAULTPLOTSTYLETABLE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default plot style table: Controls the default plot style table for new page setups and new layouts. Note: Changing this preference will not apply to the layouts that already exist. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultplotstyletable-system-variable")
)

(
  :name "DEFAULTSPACEHEIGHT"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default Space Height: Default height of a space. Used if there are no ceilings to connect to or walls to get the height from. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultspaceheight-system-variable")
)

(
  :name "DEFAULTSTORYNAMINGSCHEME"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default Story Naming Scheme: Defines the story naming scheme for new buildings. Use $0 or $1 to control the numbering. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultstorynamingscheme-system-variable")
)

(
  :name "DEFAULTSTYLEPIPECROSS"
  :type :string
  :default "ASME B16.9 Cross"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default style for pipe cross: Controls the default style in use while BIM FlowFittings cross is converts to a Std part. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultstylepipecross-system-variable")
)

(
  :name "DEFAULTSTYLEPIPEECCENTRICREDUCER"
  :type :string
  :default "ASME B16.9 Eccentric Reducer"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default style for pipe eccentric reducer: Controls the default style in use while BIM FlowFittings eccentric converts to an Std part. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultstylepipeeccentricreducer-system-variable")
)

(
  :name "DEFAULTSTYLEPIPEELBOW45"
  :type :string
  :default "ASME B16.9 Elbow LR 45 Deg"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default style for pipe elbow (45 deg): Controls the default style in use while BIM FlowBends with 45 degrees angle converts to an Std part. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultstylepipeelbow45-system-variable")
)

(
  :name "DEFAULTSTYLEPIPEELBOW90"
  :type :string
  :default "ASME B16.9 Elbow LR 90 Deg"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default style for pipe elbow (90 deg): Controls the default style in use while BIM FlowBends with 90 degrees angle converts to an Std part. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultstylepipeelbow90-system-variable")
)

(
  :name "DEFAULTSTYLEPIPEREDUCER"
  :type :string
  :default "ASME B16.9 Reducer"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default style for pipe reducer: Controls the default style in use while BIM FlowFittings reducer converts to an Std part. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultstylepipereducer-system-variable")
)

(
  :name "DEFAULTSTYLEPIPESEGMENT"
  :type :string
  :default "ASME B36.10M Pipe"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default style for pipe segment: Controls the default style in use while BIM FlowSegments converts to an Std part. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultstylepipesegment-system-variable")
)

(
  :name "DEFAULTSTYLEPIPETEE"
  :type :string
  :default "ASME B16.9 Tee"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default style for pipe tee: Controls the default style in use while BIM FlowFittings tee is converts to an Std part. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defaultstylepipetee-system-variable")
)

(
  :name "DEFLPLSTYLE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Default layer plot style: Controls the default plot style for layer 0. \"BYCOLOR\" in color-dependent mode drawings, read-only. \"NORMAL\" in named-plot-style mode drawings, can be changed. See also the PSTYLEMODE system variable. Note: To convert the current drawing to use named or color-dependent plot styles, use CONVERTPSTYLES"
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/deflplstyle-system-variable")
)

(
  :name "DEFPLSTYLE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Default entity plot style: Controls the default plot style for new entities. \"BYCOLOR\" in color-dependent mode drawings, read-only. \"NORMAL\" in named-plot-style mode drawings, can be changed. See also the PSTYLEMODE system variable. Use the CONVERTPSTYLES command to convert the current drawing to use named or color-dependent plot styles."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/defplstyle-system-variable")
)

(
  :name "DELETETOOL"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Delete tool: Controls the behavior of the SUBTRACT command. If on, entities used to subtract are deleted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/deletetool-system-variable")
)

(
  :name "DELOBJ"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Delete source entity: Controls if source entities, used to create 3D entities (with commands such as EXTRUDE, REVOLVE and LOFT) are retained or deleted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/delobj-system-variable")
)

(
  :name "DEMANDLOAD"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Demand load: Controls how the program handles custom entities created by third-party applications."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/demandload-system-variable")
)

(
  :name "DETAILSPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Details directory path: The file path(s) for user created detail files. Separate file paths with semicolons (;). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/detailspath-system-variable")
)

(
  :name "DGNEXPXREFMODE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export Conversion of XRefs: Controls the conversion of XRefs for DGN export. The dependent files themselves are not converted when exporting the parent. They must be converted separately. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnexpxrefmode-system-variable")
)

(
  :name "DGNFRAME"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "DGN frame: Controls the visibility of DGN frames, if the FRAME system variable is set to 'Use individual system variables' (3)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnframe-system-variable")
)

(
  :name "DGNIMP2DCLOSEDBSPLINECURVEIMPORTMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "2D closed B-spline curve import mode: Controls how to convert DGN closed 2D B-Spline curve elements. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimp2dclosedbsplinecurveimportmode-system-variable")
)

(
  :name "DGNIMP2DELLIPSEIMPORTMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "2D ellipse import mode: Controls how to convert DGN 2D Ellipse elements. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimp2dellipseimportmode-system-variable")
)

(
  :name "DGNIMP2DSHAPEIMPORTMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "2D shape import mode: Controls how to convert DGN 2D Shape and 2D Complex Shape elements. If an element is filled, then a hatch is created as well. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimp2dshapeimportmode-system-variable")
)

(
  :name "DGNIMP3DCLOSEDBSPLINECURVEIMPORTMODE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "3D closed B-spline curve import mode: Controls how to convert DGN closed 3D B-Spline curve elements. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimp3dclosedbsplinecurveimportmode-system-variable")
)

(
  :name "DGNIMP3DELLIPSEIMPORTMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "3D ellipse import mode: Controls how to convert DGN 3D Ellipse elements. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimp3dellipseimportmode-system-variable")
)

(
  :name "DGNIMP3DOBJECTIMPORTMODE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "3D entity import mode: Controls how 3D entities are converted during DGN import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimp3dobjectimportmode-system-variable")
)

(
  :name "DGNIMP3DSHAPEIMPORTMODE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "3D shape import mode: Controls how to convert DGN 3D Shape and 3D Complex Shape elements. If an element is filled, a hatch is created as well. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimp3dshapeimportmode-system-variable")
)

(
  :name "DGNIMPBREAKDIMENSIONASSOCIATION"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Break dimension association: Breaks DGN dimension associations during DGN import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpbreakdimensionassociation-system-variable")
)

(
  :name "DGNIMPCONVERTDGNCOLORINDICESTOTRUECOLORS"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Convert DGN color indices to true colors: Converts DGN color indexes to RGB true colors. If off, DGN color indexes are converted to DWG color indexes. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpconvertdgncolorindicestotruecolors-system-variable")
)

(
  :name "DGNIMPCONVERTEMPTYDATAFIELDSTOSPACES"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Convert empty data fields to spaces: Replaces empty field values from a DGN file with space symbols. If off, empty field values from a DGN file are replaced with underscore symbols (\"_\"). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpconvertemptydatafieldstospaces-system-variable")
)

(
  :name "DGNIMPERASEUNUSEDRESOURCES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Erase unused resources: Erases unreferenced items (text styles, linetypes, etc.) during DGN import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimperaseunusedresources-system-variable")
)

(
  :name "DGNIMPEXPLODETEXTNODES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Explode text nodes: Imports DGN text nodes as a set of simple entities (text, line, etc.). If off, DGN text nodes are converted to multiline text. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpexplodetextnodes-system-variable")
)

(
  :name "DGNIMPIMPORTACTIVEMODELTOMODELSPACE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import active model to Model Space: Imports the active DGN model to Model Space, during DGN import. If off, imports only the first DGN design model from the model table. Note: Microstation uses the phrase “design model” for model space, and “active model” for the current view of a model. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpimportactivemodeltomodelspace-system-variable")
)

(
  :name "DGNIMPIMPORTDGTEXTSASDBMTEXTS"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import Texts as MTexts: Imports simple DGN text entities as multiline texts. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpimportdgtextsasdbmtexts-system-variable")
)

(
  :name "DGNIMPIMPORTINVISIBLEELEMENTS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import invisible elements: Imports invisible DGN elements as invisible entities. If off invisible DGN elements are not imported. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpimportinvisibleelements-system-variable")
)

(
  :name "DGNIMPIMPORTPAPERSPACEMODELS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import Paper Space models: Imports all DGN sheet models to paper space layouts. If off, sheet models are not imported. Note: Microstation uses the phrase “sheet model” for paper space. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpimportpaperspacemodels-system-variable")
)

(
  :name "DGNIMPIMPORTVIEWINDEX"
  :type :short
  :default -1
  :read-only NIL
  :range (-1 7)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import view index: Controls the number of DGN views, level masks and view settings to use. Values between -1 and 7 are accepted. -1 means that the view is not defined and view settings and level masks are not used. Note: Microstation uses the word \"level\" for layers; a \"mask\" hides content in areas or levels/layers. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpimportviewindex-system-variable")
)

(
  :name "DGNIMPRECOMPUTEDIMENSIONSAFTERIMPORT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Recompute dimensions after import: Converts DGN dimensions to DWG-based dimensions. If off creates DGN-based dimensions. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimprecomputedimensionsafterimport-system-variable")
)

(
  :name "DGNIMPSYMBOLRESOURCEFILES"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Symbol resource files: The file path for DGN resource RSC files - fonts, line styles, etc. Analog of the MS_SYMBRSRC MicroStation system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpsymbolresourcefiles-system-variable")
)

(
  :name "DGNIMPXREFIMPORTMODE"
  :type :short
  :default 2
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "External references import mode: Controls DGN attachment import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnimpxrefimportmode-system-variable")
)

(
  :name "DGNOSNAP"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "DGN entity snap: Enables entity snap for DGN underlay files."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dgnosnap-system-variable")
)

(
  :name "DIASTAT"
  :type :integer
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dialog state: Shows how the most recent dialog box was exited."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/diastat-system-variable")
)

(
  :name "DIMADEC"
  :type :short
  :default 0
  :read-only NIL
  :range (-1 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim Angle Precision: Controls the number of decimal places for angular dimensions. A value of -1 uses the DIMDEC system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimadec-system-variable")
)

(
  :name "DIMALT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Alt units: Enables alternate units in dimensions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimalt-system-variable")
)

(
  :name "DIMALTD"
  :type :short
  :default 2
  :read-only NIL
  :range (0 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Alt precision: Controls the number of decimal places for alternate dimension units."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimaltd-system-variable")
)

(
  :name "DIMALTF"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Alt multiplier: Controls the conversion of alternate units. See also the DIMALT system variable. Multiples the primary unit to give alternate units. If one drawing unit equals 1 inch and the value is set to 25.4, alternate linear dimensions are expressed in mm."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimaltf-system-variable")
)

(
  :name "DIMALTRND"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Alt roundoff: Controls the roundoff for alternate units."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimaltrnd-system-variable")
)

(
  :name "DIMALTTD"
  :type :short
  :default 3
  :read-only NIL
  :range (0 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Alt tolerance precision: Controls the tolerance precision in the alternate dimension units."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimalttd-system-variable")
)

(
  :name "DIMALTTZ"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Alt tolerance suppress zeros: Controls the suppression of zeros in tolerance values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimalttz-system-variable")
)

(
  :name "DIMALTU"
  :type :short
  :default 2
  :read-only NIL
  :range (1 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Alt unit type: Controls the alternate unit type for linear dimensions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimaltu-system-variable")
)

(
  :name "DIMALTZ"
  :type :short
  :default 0
  :read-only NIL
  :range (0 12)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Alt suppress zeros: Suppresses leading and/or trailing zeros for alternate unit dimension."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimaltz-system-variable")
)

(
  :name "DIMANNO"
  :type :integer
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Style is annotative: Indicates if the current dimension style is annotative."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimanno-system-variable")
)

(
  :name "DIMAPOST"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Alt units prefix/suffix: Controls the prefix and/or suffix that appears in the alternate dimension text, does not apply to angular dimensions. See also the Drawing Explorer > Dimension Styles (DIMSTYLE command). Set to '' to turn off, or use the suffix string 'prefix[]suffix'. Insert a single linefeed with '\\X' (often when alternate units are active)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimapost-system-variable")
)

(
  :name "DIMARCSYM"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Arc symbol: Controls the display of arc symbols, in arc length dimensions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimarcsym-system-variable")
)

(
  :name "DIMASO"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Associativity (obsolete): Replaced by DIMASSOC. Has no effect except to preserve the integrity of scripts."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimaso-system-variable")
)

(
  :name "DIMASSOC"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Associativity: Controls the associativity of dimension entities or if exploded dimensions are created."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimassoc-system-variable")
)

(
  :name "DIMASZ"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Arrow size: Controls the size of dimension and leader line arrowheads."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimasz-system-variable")
)

(
  :name "DIMATFIT"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Arrow and text fit: Controls how dimension text and arrows are arranged when there is insufficient space between the extension lines. When the DIMTMOVE system variable is set to 1, a leader is added if the dimension text is placed outside."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimatfit-system-variable")
)

(
  :name "DIMAUNIT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim angle units: Controls the angular dimension unit type."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimaunit-system-variable")
)

(
  :name "DIMAZIN"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Suppress angle zeros: Suppresses leading and/or trailing zeros for angular dimensions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimazin-system-variable")
)

(
  :name "DIMBLK"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Arrow: The name of the block displayed at the ends of dimension and leader lines, when the DIMSAH system variable is set to Set by DIMBLK . The block name can be either a standard name or refer to a user-defined arrowhead block."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimblk-system-variable")
)

(
  :name "DIMBLK1"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Arrow 1: The name of the block displayed at the first end of a dimension line, when the DIMSAH system variable is set to Set by DIMBLK1 and DIMBLK2 ."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimblk1-system-variable")
)

(
  :name "DIMBLK2"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Arrow 2: The name of the block displayed at the second end of a dimension line, when the DIMSAH system variable is set to Set by DIMBLK1 and DIMBLK2 ."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimblk2-system-variable")
)

(
  :name "DIMCEN"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Center mark: Controls if and how center marks and centerlines of circles and arcs are drawn with the DIMCENTER, DIMDIAMETER and DIMRADIUS commands. A value of zero means no center mark. Negative numbers mean a line. Positive numbers mean a mark."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimcen-system-variable")
)

(
  :name "DIMCLRD"
  :type :short
  :default 0
  :read-only NIL
  :range (0 256)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim line color: The color of dimension lines, arrowheads and dimension leader lines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimclrd-system-variable")
)

(
  :name "DIMCLRE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 256)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ext line color: Controls the color for dimension extension lines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimclre-system-variable")
)

(
  :name "DIMCLRT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 256)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text color: Controls the default dimension text color."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimclrt-system-variable")
)

(
  :name "DIMCONTINUEMODE"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim continue mode: Controls if dimension styles and layers are inherited from the starting dimension, for continued or baseline dimension."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimcontinuemode-system-variable")
)

(
  :name "DIMDEC"
  :type :short
  :default 4
  :read-only NIL
  :range (0 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim precision: Controls the number of decimal places for primary dimension units. Values between 0 and 8 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimdec-system-variable")
)

(
  :name "DIMDLE"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim line ext: Controls the length of dimension lines beyond the extension lines, when obliques or architectural ticks are drawn instead of arrowheads."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimdle-system-variable")
)

(
  :name "DIMDLI"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim baseline spacing: Controls the spacing between baselines dimension lines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimdli-system-variable")
)

(
  :name "DIMDSEP"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Decimal separator: Sets the decimal separator character. You can set a single character to use as the decimal separator for dimensions in decimal format."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimdsep-system-variable")
)

(
  :name "DIMEXE"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ext line ext: Controls the extension of dimension extension lines beyond the dimension line."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimexe-system-variable")
)

(
  :name "DIMEXO"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ext line offset: Controls the offset of dimension extension lines from their origin points."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimexo-system-variable")
)

(
  :name "DIMFIT"
  :type :short
  :default 3
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim fit (obsolete): Replaced by DIMATFIT and DIMTMOVE."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimfit-system-variable")
)

(
  :name "DIMFRAC"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Fractional type: Controls the fraction format for Architectural or Fractional linear dimensions. See also the DIMLUNIT system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimfrac-system-variable")
)

(
  :name "DIMFXL"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ext line fixed length: Controls the length of extension lines, if the DIMFXLON system variable is on (1)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimfxl-system-variable")
)

(
  :name "DIMFXLON"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ext line fixed: Fixes the length of extension lines on dimensions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimfxlon-system-variable")
)

(
  :name "DIMGAP"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text offset: Controls the offset distance around dimension text, and the distance between annotations and hook lines created with the LEADER command. See the DIMTAD system variable. Negative numbers mean draws a box around the dimension or annotation text."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimgap-system-variable")
)

(
  :name "DIMJOGANG"
  :type :real
  :default 45.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Jogged angle: Controls the angle of oblique dimension line segments, in jogged radius dimensions. Note: Jogged radius dimensions are often created when the center point is located off the page."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimjogang-system-variable")
)

(
  :name "DIMJUST"
  :type :short
  :default 0
  :read-only NIL
  :range (0 4)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text Position Horizontal: Controls the horizontal position of dimension text."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimjust-system-variable")
)

(
  :name "DIMLAYER"
  :type :string
  :default "."
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Default layer for new dimensions: The default layer for new dimensions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimlayer-system-variable")
)

(
  :name "DIMLDRBLK"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Leader arrow: Controls the arrowhead block for leaders."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimldrblk-system-variable")
)

(
  :name "DIMLFAC"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim Scale Linear: Controls the scale multiplier for linear dimensions, including radius, diameter and ordinate dimensions. Linear dimensions are multiplied by DIMLFAC. Positive values mean that it is used for model space and paper space. Negative values mean paper space only."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimlfac-system-variable")
)

(
  :name "DIMLIM"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tolerance method: Generates dimension limits as the default text for dimensions. If On, switches DIMTOL Off."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimlim-system-variable")
)

(
  :name "DIMLTEX1"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ext line 1 linetype: Controls the linetype for the first extension line of a dimension."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimltex1-system-variable")
)

(
  :name "DIMLTEX2"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ext line 2 linetype: Controls the linetype for the second extension line of a dimension."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimltex2-system-variable")
)

(
  :name "DIMLTYPE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim line linetype: Controls the linetype for dimension lines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimltype-system-variable")
)

(
  :name "DIMLUNIT"
  :type :short
  :default 2
  :read-only NIL
  :range (1 6)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim units: Controls the primary unit type for linear dimensions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimlunit-system-variable")
)

(
  :name "DIMLWD"
  :type :short
  :default (:unknown)
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim line LW: Controls the lineweight of dimension lines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimlwd-system-variable")
)

(
  :name "DIMLWE"
  :type :short
  :default (:unknown)
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ext line LW: Controls the lineweight of dimension extension lines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimlwe-system-variable")
)

(
  :name "DIMMARKTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Dimension override marking: Automatically displays overridden associative dimensions with a special marking, when they do not include the default dimension text. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimmarktype-system-variable")
)

(
  :name "DIMPOST"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim prefix/suffix: Controls the prefix and/or suffix added to dimension text. See also the Drawing Explorer > Dimension Styles (DIMSTYLE command). Set to '' to turn off, or use the suffix string 'prefix[]suffix'. Insert a single linefeed with '\\X' when alternate units are active."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimpost-system-variable")
)

(
  :name "DIMRND"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim round: Controls the roundoff rules for linear dimensions. Note: It does not effect angular dimensions. A value of 0.1 rounds to the nearest 0.1 unit, a value of 1 rounds to the nearest whole number. The number of decimal places is limited by the DIMDEC system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimrnd-system-variable")
)

(
  :name "DIMSAH"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Arrowheads: Controls how dimension line arrowhead blocks are set."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimsah-system-variable")
)

(
  :name "DIMSCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range (0 NIL)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim scale overall: Applies a scale multiplier to dimension variables that specify the size of the components of dimension entities, such as text height, distance or offsets. Note: It does not affect measured lengths, coordinates, or angles."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimscale-system-variable")
)

(
  :name "DIMSD1"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim line 1: Suppresses the first part of dimension lines - from the first extension line to the text origin."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimsd1-system-variable")
)

(
  :name "DIMSD2"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim line 2: Suppresses the second part of dimension lines - from the text origin to the second extension line."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimsd2-system-variable")
)

(
  :name "DIMSE1"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ext line 1: Suppresses the first extension line of a dimension."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimse1-system-variable")
)

(
  :name "DIMSE2"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ext line 2: Suppresses the second extension line of a dimension."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimse2-system-variable")
)

(
  :name "DIMSHO"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dimension show (Obsolete): Has no effect except to preserve the integrity of scripts. Controls the redefinition of dimension entities while dragging."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimsho-system-variable")
)

(
  :name "DIMSOXD"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim line inside: Suppresses arrowheads outside extension lines if there is insufficient room inside the extension lines and if the DIMTIX system variable is on (1)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimsoxd-system-variable")
)

(
  :name "DIMSTYLE"
  :type :string
  :default "Standard"
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dimension style: The current dimension style."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimstyle-system-variable")
)

(
  :name "DIMTAD"
  :type :short
  :default 0
  :read-only NIL
  :range (0 4)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text Position Vert: Controls the vertical position of text in relation to dimension lines. The position above dimension line is set by the DIMGAP system variable. The Above dimension line option does not apply if the DIMTIH system variable is set to Horizontal and the dimension line is not horizontal."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtad-system-variable")
)

(
  :name "DIMTDEC"
  :type :short
  :default 4
  :read-only NIL
  :range (0 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tolerance precision: Controls the number of decimal places for tolerance values in the primary dimension units."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtdec-system-variable")
)

(
  :name "DIMTFAC"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tolerance text height: Controls the scale multiplier used to calculate the text height for dimension fractions and tolerances, relative to the dimension text height, set with the DIMTXT system variable. Only applies if the DIMLUNIT system variable is set to Fractional (5)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtfac-system-variable")
)

(
  :name "DIMTFILL"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text fill: Controls the dimension text background."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtfill-system-variable")
)

(
  :name "DIMTFILLCLR"
  :type :short
  :default 0
  :read-only NIL
  :range (0 256)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text fill color: Controls dimension text background color, when the DIMTFILL system variable is set to 2."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtfillclr-system-variable")
)

(
  :name "DIMTIH"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text inside align: Controls the dimension text position on dimensions. Note: It does not apply to ordinate dimensions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtih-system-variable")
)

(
  :name "DIMTIX"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text inside: Draws dimension text between extension lines, even if there is insufficient room. Note: It does not apply to radius and diameter dimensions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtix-system-variable")
)

(
  :name "DIMTM"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tolerance limit lower: Controls the minimum (lower) tolerance limit for dimension text when the DIMTOL or DIMLIM system variable is on."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtm-system-variable")
)

(
  :name "DIMTMOVE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text movement: Controls how dimension text moves."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtmove-system-variable")
)

(
  :name "DIMTOFL"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim line forced: Forces a dimension line to be drawn between dimension extension lines, even when text is placed outside."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtofl-system-variable")
)

(
  :name "DIMTOH"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text outside align: Places dimension text outside extension lines horizontally."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtoh-system-variable")
)

(
  :name "DIMTOL"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tolerance display: Adds tolerances to dimension text."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtol-system-variable")
)

(
  :name "DIMTOLJ"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tolerance pos vert: Controls the vertical position for tolerance values relative to the primary dimension text."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtolj-system-variable")
)

(
  :name "DIMTP"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tolerance limit upper: Controls the maximum (upper) tolerance limit for dimension text when the DIMTOL or DIMLIM system variable is on."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtp-system-variable")
)

(
  :name "DIMTSZ"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim tick size: Controls the size of tick marks drawn instead of arrowheads for linear, radius and diameter dimensions. If the value is zero, arrowheads are drawn."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtsz-system-variable")
)

(
  :name "DIMTVP"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text offset vertical: Controls the vertical position of dimension above or below the dimension line. Acts as a multiplier of the DIMTXT system variable, when the DIMTAD system variable is set to Centered between extension lines . A value of 1.0 is equivalent to setting the DIMTAD system variable to on (1)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtvp-system-variable")
)

(
  :name "DIMTXSTY"
  :type :string
  :default "Standard"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text style: Controls the default dimension text style."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtxsty-system-variable")
)

(
  :name "DIMTXT"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text height: Controls the default dimension text height, if the text style set in the DIMTXSTY system variable has no fixed height."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtxt-system-variable")
)

(
  :name "DIMTXTDIRECTION"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text direction: Controls the dimension text direction."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtxtdirection-system-variable")
)

(
  :name "DIMTZIN"
  :type :short
  :default 0
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tolerance suppress zeros: Controls the suppression of zeros in tolerance values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimtzin-system-variable")
)

(
  :name "DIMUNIT"
  :type :short
  :default 2
  :read-only NIL
  :range (1 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dim unit type (obsolete): Replaced by DIMLUNIT and DIMFRAC system variables."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimunit-system-variable")
)

(
  :name "DIMUPT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Place text manually: Toggles the placement of dimension text during dimension creation."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimupt-system-variable")
)

(
  :name "DIMZIN"
  :type :short
  :default 0
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Suppress dim zeros: Suppresses leading and/or trailing zeros for primary units."
  :coupled ("rtos")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dimzin-system-variable")
)

(
  :name "DISPLAYAXES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Display Axes: Displays the axes of structural elements. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/displayaxes-system-variable")
)

(
  :name "DISPLAYAXESFORMEP"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Display axes: Controls the display of MEP element axes."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/displayaxesformep-system-variable")
)

(
  :name "DISPLAYSCALING"
  :type :short
  :default 100
  :read-only T
  :range (50 1000)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Automatic display scaling: Current display scaling - the same as the system display settings. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/displayscaling-system-variable")
)

(
  :name "DISPLAYSIDESANDENDS"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Display Sides and Ends: Displays the sides and ends of structural entities on selection. If on, these are selectable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/displaysidesandends-system-variable")
)

(
  :name "DISPLAYSNAPMARKERINALLVIEWS"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Snap marker in all views: Controls if snap markers display in all viewports. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/displaysnapmarkerinallviews-system-variable")
)

(
  :name "DISPLAYTOOLTIPS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Snap tooltips: Toggles the display of snap tooltips on/off. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/displaytooltips-system-variable")
)

(
  :name "DISPLAYTRUEDIMENSION"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default dimension type: Sets the default dimension type placed on an isometric view. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/displaytruedimension-system-variable")
)

(
  :name "DISPPAPERBKG"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Paper background: Displays a paper sheet in paper space. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/disppaperbkg-system-variable")
)

(
  :name "DISPPAPERMARGINS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Printable area: Displays the printable area of a layout in paper space. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/disppapermargins-system-variable")
)

(
  :name "DISPSILH"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Display silhouette curves: Displays silhouette curves on solid entities in Wireframe modes (2D and 3D). Note: To view changes on existing entities, perform a REGEN."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dispsilh-system-variable")
)

(
  :name "DISTANCE"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Distance: The last calculated distance of the DIST command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/distance-system-variable")
)

(
  :name "DMAUDITLEVEL"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "DMAUDIT command, level of detail: Controls the message types displayed for the DMAUDIT command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dmauditlevel-system-variable")
)

(
  :name "DMAUTOUPDATE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "3D constraints recalculation mode: Updates the model automatically, when constraints are applied or modified. If off, use the DMUPDATE command to update the model. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dmautoupdate-system-variable")
)

(
  :name "DMCONNECTIONCUTTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Connection type: Controls the type of connection created by the BIMSTRUCTURALCONNECT command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dmconnectioncuttype-system-variable")
)

(
  :name "DMPUSHPULLSUBTRACT"
  :type :integer
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "DMPUSHPULL subtract: Controls what happens when an entity, modified with the DMPUSHPULL command, touches an existing entity. When OFF, a solid that intersects with another solid, no longer subtracts the intersecting areas from the other solid. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dmpushpullsubtract-system-variable")
)

(
  :name "DMRECOGNIZE"
  :type :short
  :default 0
  :read-only NIL
  :range (-1 1023)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Automatic 3D geometry constraints recognition: Automatically constrains geometrical relations between surfaces, when 3D entities are edited or 3D constraints are recalculated. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dmrecognize-system-variable")
)

(
  :name "DOCKPRIORITY"
  :type :short
  :default 1
  :read-only NIL
  :range (1 14)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Docking Priority: Controls the dock priority of top, left, right and bottom docking bars. Note: A restart is required. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dockpriority-system-variable")
)

(
  :name "DOCTABPOSITION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tabs position: Controls where the document control tab is displayed. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/doctabposition-system-variable")
)

(
  :name "DONUTID"
  :type :real
  :default 0.5
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Donut inside diameter: The default inside diameter for the DONUT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/donutid-system-variable")
)

(
  :name "DONUTOD"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Donut outside diameter: The default outside diameter for the DONUT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/donutod-system-variable")
)

(
  :name "DRAGMODE"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Entity drag mode: Controls if a preview displays during the MOVE and COPY commands."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dragmode-system-variable")
)

(
  :name "DRAGMODECONSTRAINTS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Solve 3D constraints dynamically: Solves 3D constraints live when entities are moved. Turn off to optimize performance. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dragmodeconstraints-system-variable")
)

(
  :name "DRAGMODEFACES"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "MOVE face: Controls the behavior of the MOVE and DMMOVE commands, if these commands are used to move a face. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dragmodefaces-system-variable")
)

(
  :name "DRAGMODEHIDE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hide during drag: Hides the original entity during move and stretch actions. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dragmodehide-system-variable")
)

(
  :name "DRAGMODEINTERRUPT"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Drag interruption mode: Controls the recalculation/redrawing of the model is interrupted when the cursor is in motion. If on, display a live preview. If off, every drag action must first be completed. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dragmodeinterrupt-system-variable")
)

(
  :name "DRAGOPEN"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Drag open: Controls what to do when a drawing is dragged from the explorer to the program. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dragopen-system-variable")
)

(
  :name "DRAGP1"
  :type :short
  :default 10
  :read-only NIL
  :range (0 32767)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Regen-drag rate: Controls the regen-drag input sampling rate."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dragp1-system-variable")
)

(
  :name "DRAGP2"
  :type :short
  :default 25
  :read-only NIL
  :range (0 32767)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Fast-drag rate: Controls the fast-drag input sampling rate."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dragp2-system-variable")
)

(
  :name "DRAGSNAP"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Snap dragged entities: Enables rubber band dynamics during modify commands: COPY, PASTECLIP, PASTEBLOCK, MOVE, ROTATE, MIRROR, SCALE, STRETCH and more. The DRAGSNAP system variable controls the snap behavior while dragging. DRAGSNAP controls whether rubberband dynamics are displayed at the current cursor location or at the current entity snap location. Note: Rubber band dynamics means that the cursor and the entity being modified will jump to the active snap point, this wi..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dragsnap-system-variable")
)

(
  :name "DRAWINGPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Drawings path: The file path used for the fifth folder on the left of the OPEN, SAVEAS and INSERT command dialogs (Windows only). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/drawingpath-system-variable")
)

(
  :name "DRAWINGVIEWASM"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Assemblies optimization: Enables the use of assembly data structures, optimizes the generation of views created with the VIEWBASE command. Toggles between normal analytical hidden line removal (HLR) and ASM_HLR procedure. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/drawingviewasm-system-variable")
)

(
  :name "DRAWINGVIEWENTS"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Additional entities: Controls entities that will be processed in drawing views created by VIEWBASE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/drawingviewents-system-variable")
)

(
  :name "DRAWINGVIEWFLAGS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Drawing View Flags: Enables the settings for drawing view related commands (for example, VIEWBASE, VIEWUPDATE). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/drawingviewflags-system-variable")
)

(
  :name "DRAWINGVIEWPRESET"
  :type :string
  :default ""
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Drawing view preset: Controls the view preset for the VIEWBASE command. Presets specify the types of generated drawings and their placement in the layout. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/drawingviewpreset-system-variable")
)

(
  :name "DRAWINGVIEWPRESETHIDDEN"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Drawing view hidden lines preset: Controls the hidden lines preset for the VIEWBASE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/drawingviewpresethidden-system-variable")
)

(
  :name "DRAWINGVIEWPRESETSCALE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Scale for drawing view preset: Controls the annotation scale for the current drawing view preset. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/drawingviewpresetscale-system-variable")
)

(
  :name "DRAWINGVIEWPRESETTANGENT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Drawing view tangent lines preset: Controls the tangent lines preset for the VIEWBASE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/drawingviewpresettangent-system-variable")
)

(
  :name "DRAWINGVIEWPRESETTRAILING"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Drawing view trailing lines preset: Controls the trailing lines preset for the VIEWBASE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/drawingviewpresettrailing-system-variable")
)

(
  :name "DRAWINGVIEWQUALITY"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Quality of drawing views: Controls the quality of views created with the VIEWBASE command. Turn off to significantly reduce the time needed to generate drawing views. Views with draft-quality geometry are created, it is not possible to put annotations on the edges of entities in these views. However, they look very similar to a precise (high-quality) drawing view and you can use them to quickly create layouts."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/drawingviewquality-system-variable")
)

(
  :name "DRAWORDERCTL"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Draworder control: Controls draw order functionality. Limits the draw order, use if some editing operations take slightly longer."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/draworderctl-system-variable")
)

(
  :name "DWFFORMAT"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default DWF format: Controls the default export format for the 3DDWF command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dwfformat-system-variable")
)

(
  :name "DWFFRAME"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "DWF frame: Controls the visibility of DWF or DWFx underlay frames, if the FRAME system variable is set to Use individual system variables (3)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dwfframe-system-variable")
)

(
  :name "DWFOSNAP"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "DWF entity snap: Enables entity snap for DWF underlay files."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dwfosnap-system-variable")
)

(
  :name "DWFVERSION"
  :type :short
  :default 2
  :read-only NIL
  :range (1 10)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "DWF version: Controls the DWF export version. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dwfversion-system-variable")
)

(
  :name "DWGCHECK"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Drawing check: Executes an automatic data integrity check when a drawing is opened."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dwgcheck-system-variable")
)

(
  :name "DWGCODEPAGE"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Drawing codepage: Displays the drawing code page, same as the SYSCODEPAGE system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dwgcodepage-system-variable")
)

(
  :name "DWGGUIDCLOUDAI"
  :type :string
  :default "\" \""
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Drawing Guid: Unique GUID (Globally Unique Identifier) for this drawing. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dwgguidcloudai-system-variable")
)

(
  :name "DWGNAME"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Drawing name: The name of the current drawing."
  :coupled ("findfile")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dwgname-system-variable")
)

(
  :name "DWGPREFIX"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Drawing prefix: The folder path of the current drawing."
  :coupled ("findfile")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dwgprefix-system-variable")
)

(
  :name "DWGTITLED"
  :type :integer
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Drawing titled: Shows if the current drawing has been named."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dwgtitled-system-variable")
)

(
  :name "DXEVAL"
  :type :short
  :default 12
  :read-only NIL
  :range (0 511)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Data extraction update mode: Controls the notification for data extraction tables."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dxeval-system-variable")
)

(
  :name "DXFTEXTADJUSTALIGNMENT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "DXF text adjust alignment: Controls if alignment is adjusted when text is loaded from a DXF. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dxftextadjustalignment-system-variable")
)

(
  :name "DYNCONSTRAINTMODE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dynamic Constraint Mode: Displays hidden dimensional constraints when constrained entities are selected."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dynconstraintmode-system-variable")
)

(
  :name "DYNDIGRIP"
  :type :short
  :default 31
  :read-only NIL
  :range (0 31)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Show dynamic dimensions: Controls which dynamic dimensions are shown."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dyndigrip-system-variable")
)

(
  :name "DYNDIMAPERTURE"
  :type :short
  :default 20
  :read-only NIL
  :range (0 500)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Dynamic dimension aperture: Controls the radius around the cursor, used to detect the nearest entity during a command, in pixels. Applies only when the DYNMODE system variable is set to Nearest entity dynamic dimensions . Values between 1 and 500 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dyndimaperture-system-variable")
)

(
  :name "DYNDIMCOLORHOT"
  :type :short
  :default 142
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Dynamic dimension hot color: The color of dynamic dimensions, during a grip move action. Values between 1 and 255 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dyndimcolorhot-system-variable")
)

(
  :name "DYNDIMCOLORHOVER"
  :type :short
  :default 142
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Dynamic dimension hover color: The color of dynamic dimensions, when the cursor hovers over a grip point. Values between 1 and 255 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dyndimcolorhover-system-variable")
)

(
  :name "DYNDIMDISTANCE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Dynamic dimension distance: Controls the position of the dynamic dimension box - the offset distance from the entity. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dyndimdistance-system-variable")
)

(
  :name "DYNDIMLINETYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (-1 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Dynamic dimension linetype: Controls the linetype visualization of dynamic dimensions during a grip move action. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dyndimlinetype-system-variable")
)

(
  :name "DYNDIVIS"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dynamic dimension visibility: Controls which dynamic dimensions are displayed when grips are moved."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dyndivis-system-variable")
)

(
  :name "DYNINPUTTRANSPARENCY"
  :type :short
  :default 90
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Transparency of dynamic input fields: Controls the transparency of dynamic input fields, as a percentage. A value of zero means fully transparent. A value of 100 means fully opaque. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dyninputtransparency-system-variable")
)

(
  :name "DYNMODE"
  :type :short
  :default 3
  :read-only NIL
  :range (-31 31)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dynamic input mode: Toggles dynamic input features on/off."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dynmode-system-variable")
)

(
  :name "DYNPICOORDS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Default mode for dynamic coordinates input: The default mode for coordinate entry, during dynamic input."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/d/dynpicoords-system-variable")
)

(
  :name "EDGEMODE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Edge mode: Controls how cutting and boundary edges are checked with the TRIM and EXTEND commands, with or without extension."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/edgemode-system-variable")
)

(
  :name "ELEVATION"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Elevation: The elevation (Z-axis) for new entities, relative to the current UCS."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/elevation-system-variable")
)

(
  :name "ENABLEATTRACTION"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Grips attraction: Enables grip to grip attraction during move or modify actions on a grip point. Note: The OSMODE system variable may override this behavior. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/enableattraction-system-variable")
)

(
  :name "ENABLEBIMBKUPDATE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Enable section update in background: Enables section update in the background, see the BIMBKUPDATE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/enablebimbkupdate-system-variable")
)

(
  :name "ENABLEHYPERLINKMENU"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hyperlink menu: Toggles the hyperlink menu on/off. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/enablehyperlinkmenu-system-variable")
)

(
  :name "ENABLEHYPERLINKTOOLTIP"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hyperlink tooltip: Toggles the display of the hyperlink tooltip on/off. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/enablehyperlinktooltip-system-variable")
)

(
  :name "ERRNO"
  :type :short
  :default 0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Error number: Reports the error type of a LISP program."
  :coupled ("open" "read-line" "write-line" "load" "findfile" "entget" "entmod" "entmake" "ssget" "ssname" "nentsel" "entsel")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/errno-system-variable")
)

(
  :name "EXPERIMENTALMODE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Enable experimental features: You may experience bugs or performance issues in BricsCAD when the experimental mode is enabled. We encourage you to report them. Experimental features can change or be removed from future versions. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/experimentalmode-system-variable")
)

(
  :name "EXPERIMENTALONSTARTPAGE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Experimental features on start page: Switch to control whether experimental features can be managed from the start page. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/experimentalonstartpage-system-variable")
)

(
  :name "EXPERT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 5)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Expert: Controls the display of certain prompts. If prompts are suppressed, continues as though y(es) was entered. Can affect scripts, menu macros, LISP and command functions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/expert-system-variable")
)

(
  :name "EXPINSALIGN"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Explorer Insert Aligned: Align blocks inserted from the Drawing Explorer with selected entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/expinsalign-system-variable")
)

(
  :name "EXPINSANGLE"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Explorer Insert Angle: The rotation angle used for blocks inserted from the Drawing Explorer. Applies if the EXPINSFIXANGLE system variable is switched on. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/expinsangle-system-variable")
)

(
  :name "EXPINSFIXANGLE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Explorer Insert Fix Angle: Uses a rotation angle for blocks inserted from the Drawing Explorer. See also the EXPINSANGLE system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/expinsfixangle-system-variable")
)

(
  :name "EXPINSFIXSCALE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Explorer Insert Fix Scale: Inserts blocks from Drawing Explorer at a fixed scale. See the EXPINSSCALE system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/expinsfixscale-system-variable")
)

(
  :name "EXPINSSCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Explorer Insert Scale: The scale multiplier used for blocks inserted from the Drawing Explorer. Applies if the EXPINSFIXSCALE system variable is switched on (1). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/expinsscale-system-variable")
)

(
  :name "EXPLMODE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Explode mode: Enables the EXPLODE command on nonuniformly scaled (NUS) blocks."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/explmode-system-variable")
)

(
  :name "EXPORT3DPDFWRITER"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "3D PDF writer: Controls the writer used to save 3D PDF files."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/export3dpdfwriter-system-variable")
)

(
  :name "EXPORTACISASSEMBLYWRITER"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "ASAT/ASAB writer: Controls the writer used to save ASAT/ASAB files. The internal ASAT/ASAB writer used if the Communicator for BricsCAD is not installed."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportacisassemblywriter-system-variable")
)

(
  :name "EXPORTACISFORMATVERSION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 19)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "ACIS export format version: Controls the ACIS file version to export to. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportacisformatversion-system-variable")
)

(
  :name "EXPORTCATIAV4FORMATVERSION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 6)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "CATIA V4 export format version: Controls CATIA V4 file version to export to."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportcatiav4formatversion-system-variable")
)

(
  :name "EXPORTCATIAV5FORMATVERSION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 21)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "CATIA V5 export format version: Controls CATIA V5 file version to export to. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportcatiav5formatversion-system-variable")
)

(
  :name "EXPORTGEOMETRYFLAGS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Export Geometry Flags: Controls how geometry representations in IGES and STEP formats are exported."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportgeometryflags-system-variable")
)

(
  :name "EXPORTHIDDENPARTS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hidden parts: Controls how hidden parts are exported. Entities can be invisible because of: The result of the HIDEOBJECTS command. Sitting on a hidden layer. Owned by an invisible component."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exporthiddenparts-system-variable")
)

(
  :name "EXPORTMODELSPACE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Export model space: Controls what part of model space to export to DWF, DWFx or PDF."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportmodelspace-system-variable")
)

(
  :name "EXPORTPAGESETUP"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Export page setup: Toggles the page setup for DWF, DWFx or PDF export."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportpagesetup-system-variable")
)

(
  :name "EXPORTPAPERSPACE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Export paper space: Controls which layout(s) to export to DWF, DWFx or PDF, from paper space."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportpaperspace-system-variable")
)

(
  :name "EXPORTPARASOLIDFORMATVERSION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 27)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Parasolid export format version: Controls the Parasolid file version to export to. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportparasolidformatversion-system-variable")
)

(
  :name "EXPORTPRODUCTSTRUCTURE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Product structure: Controls if a product structure is exported."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportproductstructure-system-variable")
)

(
  :name "EXPORTSTEPFORMATVERSION"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "STEP export format version: Controls the STEP file version to export to."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportstepformatversion-system-variable")
)

(
  :name "EXPORTXCGMFORMATVERSION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 16)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "XCGM export format version: Controls the XCGM file version to export to."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/exportxcgmformatversion-system-variable")
)

(
  :name "EXTMAX"
  :type :point3d
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Extents maximum: The drawing extents' upper-right coordinate. It increases as new entities are created outside the existing extents."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/extmax-system-variable")
)

(
  :name "EXTMIN"
  :type :point3d
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Extents minimum: The drawing extents' lower-left coordinates."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/extmin-system-variable")
)

(
  :name "EXTNAMES"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Extend names: Controls the maximum characters for the names of named entities (for example: linetypes and layers) saved in symbol tables."
  :coupled ("snvalid")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/extnames-system-variable")
)

(
  :name "EXTRUDEINSIDE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Extrude behavior inside: Controls how new entities, modify a parent entity when they intersect. Applies to entities as they are created with the EXTRUDE and REVOLVE commands, when the Auto option is selected. A parent entity is any entity that touches the contour from which the extruded/revolved entity was created. The EXTRUDEINSIDE system variable is one of the four system variables found under the Extrude mode group. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/extrudeinside-system-variable")
)

(
  :name "EXTRUDEOUTSIDE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Extrude behavior outside: Controls how new entities, modify a parent entity when they touch. Applies to entities as they are created with the EXTRUDE and REVOLVE commands, when the Auto option is selected. A parent entity is any entity that touches the contour from which extruded/revolved entity was created. The EXTRUDEOUTSIDE system variable is one of the four system variables found under the Extrude mode group. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/e/extrudeoutside-system-variable")
)

(
  :name "FACETRATIO"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Faceting aspect ratio: Controls the aspect ratio of faceting for cylindrical and conic ACIS solids."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/facetratio-system-variable")
)

(
  :name "FACETRES"
  :type :real
  :default 0.5
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Facet resolution: Controls the smoothness of shaded, rendered and hidden line views. Values between 0.01 and 10.0 are accepted. Large values can have a significant impact on memory usage and performance."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/facetres-system-variable")
)

(
  :name "FBXEXPORTCAMERAS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "FBX Export Cameras: Enables the export of cameras to FBX. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fbxexportcameras-system-variable")
)

(
  :name "FBXEXPORTENTITIES"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "FBX Export Entities: Enables the export of entities to FBX. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fbxexportentities-system-variable")
)

(
  :name "FBXEXPORTENTITIESSELTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "FBX entities to export: Controls which entities are exported to FBX. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fbxexportentitiesseltype-system-variable")
)

(
  :name "FBXEXPORTLIGHTS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "FBX Export Lights: Enables the export of lights to FBX. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fbxexportlights-system-variable")
)

(
  :name "FBXEXPORTMATERIALS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "FBX Export Materials: Enables the export of materials to FBX. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fbxexportmaterials-system-variable")
)

(
  :name "FBXEXPORTTEXTURES"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "FBX Export Textures: Sets the material type used for an FBX file export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fbxexporttextures-system-variable")
)

(
  :name "FBXEXPORTTEXTURESPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Fbx Export Textures path: The file path for FBX Export Textures. This setting is only used when the FBXEXPORTTEXTURES system variable is set to 2. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fbxexporttexturespath-system-variable")
)

(
  :name "FEATURECOLORS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Feature colors: Colors sheet metal parts based on feature type. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/featurecolors-system-variable")
)

(
  :name "FIELDDISPLAY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Field display: Applies a gray fill behind field text."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fielddisplay-system-variable")
)

(
  :name "FIELDEVAL"
  :type :short
  :default 31
  :read-only NIL
  :range (0 31)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Field update mode: Controls the way fields are updated."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fieldeval-system-variable")
)

(
  :name "FILEDIA"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "File dialog: Toggles the display of file dialog boxes. If off, enter a tilde (~) to bring up the file dialog. This also works for LISP functions and command fields in tool definitions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/filedia-system-variable")
)

(
  :name "FILLETRAD"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Fillet radius: The last radius used with the FILLET command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/filletrad-system-variable")
)

(
  :name "FILLETWELDINGCOMBINEADJACENT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Combine adjacent fillet welds: Makes it possible to combine adjacent fillet weld segments into one fillet welding feature. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/filletweldingcombineadjacent-system-variable")
)

(
  :name "FILLETWELDINGMAXGAPRATIO"
  :type :real
  :default 0.4
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximal ratio of a gap to a weld size: Sets the default maximal ratio of a gap between a welding part and the fillet weld size, see the FILLETWELDINGZSIZE system variable. Values between 0.0 and 0.8 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/filletweldingmaxgapratio-system-variable")
)

(
  :name "FILLETWELDINGZSIZE"
  :type :real
  :default 5.0d0
  :read-only NIL
  :range (0 50)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default fillet weld Z size: Sets default Z-size of symmetric fillet welds. Values between 0 and 50 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/filletweldingzsize-system-variable")
)

(
  :name "FILLMODE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Fill mode: Shows fills for multilines, traces, solids, hatches (includes solid-fill), and wide polylines. A REGEN is required. If off, all filled entities display and print as outlines, this will also reduce the time it takes to display or print a drawing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fillmode-system-variable")
)

(
  :name "FITLINEFITARCMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 255)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "FitLine FitArc mode: The FITLINEFITARCMODE system variable sets the values for the options Use entire drawing , Fit in 3d , and Delete original entities after fitting , that are used by the FITLINE and FITARC commands. The value is stored as a bit code using the sum of the values of all selected options. Note: This system variable is only available at the Command line."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fitlinefitarcmode-system-variable")
)

(
  :name "FITTINGRADIUSTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Fitting Radius Type: Sets the default flow fitting radius type. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fittingradiustype-system-variable")
)

(
  :name "FITTINGRADIUSVALUE"
  :type :real
  :default 1.5
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Fitting Radius Value: Sets default flow fitting radius value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fittingradiusvalue-system-variable")
)

(
  :name "FLANGEASMDEFAULTGASKET"
  :type :string
  :default "ASME B16.21 Gasket FullFace for ASME B16.5"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default gasket: Controls the default gasket for flange assemblies. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/flangeasmdefaultgasket-system-variable")
)

(
  :name "FONTALT"
  :type :string
  :default "simplex.shx"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Alternate font: The substitute font used when a text font cannot be found."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fontalt-system-variable")
)

(
  :name "FONTMAP"
  :type :string
  :default "default.fmp"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Font mapping file: The font mapping file for existing fonts."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fontmap-system-variable")
)

(
  :name "FRAME"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Frame: Controls the visibility of frames for XRefs, images and underlays. Overrides the IMAGEFRAME, DWFFRAME, PDFFRAME, DGNFRAME, and XCLIPFRAME system variables."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/frame-system-variable")
)

(
  :name "FRAMESELECTION"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Frame selection: Controls if the hidden frame of an image, underlay, clipped XRefs, or wipeout can be selected."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/frameselection-system-variable")
)

(
  :name "FRONTZ"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Front clipping plane offset: Displays the CLipping option of the DVIEW command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/frontz-system-variable")
)

(
  :name "FULLOPEN"
  :type :short
  :default (:unknown)
  :read-only T
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Full open: Indicates the state of the current drawing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/f/fullopen-system-variable")
)

(
  :name "GEARTEETHNUMBER"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximum number of sproket teeth: Controls the number of teeth for sprockets, during the -BMHARDWARE command. Use this option to insert sprockets with simplified or full geometry. Values between 0 and 1000 are accepted. Note: This number must be greater or equal to the number of teeth of the inserted sproket to create a sproket with full geometry. 1000 is enough to insert any sproket from the library with a full set of teeth. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gearteethnumber-system-variable")
)

(
  :name "GENERATEASSOCATTRS"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Generate associative attributes: Enables the generation of associative attributes on 3D entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/generateassocattrs-system-variable")
)

(
  :name "GENERATEASSOCVIEWS"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Generate associative drawings: Enables associative dimensions for drawings generated with the BIMSECTIONUPDATE, VIEWBASE and VIEWSECTION commands. As a result, dimensions are updated in the associated Paper Space viewports and BIM section drawings. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/generateassocviews-system-variable")
)

(
  :name "GEOCSMAPPRIORITY"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "CSMAP priority: Controls priority of CSMAP engine over internal engine. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/geocsmappriority-system-variable")
)

(
  :name "GEOLATLONGFORMAT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Geographic latitude/longitude format: Controls the format of geographical latitude and longitude values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/geolatlongformat-system-variable")
)

(
  :name "GEOMARKERVISIBILITY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Geographic marker visibility: Controls the visibility of the geographic marker."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/geomarkervisibility-system-variable")
)

(
  :name "GEOMRELATIONS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Geometric relationship indication: Controls if geometric relationships are recognized and maintained when a 2D entity is dragged. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/geomrelations-system-variable")
)

(
  :name "GETSTARTED"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Get Started: Controls if the Launcher is displayed on startup. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/getstarted-system-variable")
)

(
  :name "GFANG"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Gradient fill angle: Controls the default gradient fill angle."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gfang-system-variable")
)

(
  :name "GFCLR1"
  :type :string
  :default "5"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Gradient fill primary color: Controls the default first color of a gradient fill."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gfclr1-system-variable")
)

(
  :name "GFCLR2"
  :type :string
  :default "7"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Gradient fill secondary color: Controls the default second color of a gradient fill."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gfclr2-system-variable")
)

(
  :name "GFCLRLUM"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Gradient fill tint level: Controls the default tint intensity in a one-color gradient fill."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gfclrlum-system-variable")
)

(
  :name "GFCLRSTATE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Number of colors for a gradient fill: Controls the default number of colors for a gradient fill."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gfclrstate-system-variable")
)

(
  :name "GFNAME"
  :type :short
  :default 1
  :read-only NIL
  :range (1 9)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Gradient fill name: Controls the pattern of a gradient fill."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gfname-system-variable")
)

(
  :name "GFSHIFT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Gradient fill shift: Controls if a gradient fill pattern is centered or is shifted up and to the left."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gfshift-system-variable")
)

(
  :name "GLSWAPMODE"
  :type :short
  :default 2
  :read-only NIL
  :range (0 4)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "GL Swap Mode: Controls the swap method used when drawing with the GL engine. Depending on the hardware driver used, the visual effect may differ between these options. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/glswapmode-system-variable")
)

(
  :name "GRADIENTCOLORBOTTOM"
  :type :string
  :default "RGB:210,210,210"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Background gradient color bottom: Controls the default bottom color for gradient backgrounds and the default for solid view backgrounds. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gradientcolorbottom-system-variable")
)

(
  :name "GRADIENTCOLORMIDDLE"
  :type :string
  :default "RGB:250,250,250"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Background gradient color middle: Controls the default middle color for gradient backgrounds. Applies only if the GRADIENTMODE system variable is set to Three-color gradient . BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gradientcolormiddle-system-variable")
)

(
  :name "GRADIENTCOLORTOP"
  :type :string
  :default "White"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Background gradient color top: Controls the default top color for gradient backgrounds. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gradientcolortop-system-variable")
)

(
  :name "GRADIENTMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Background gradient mode: Controls if and how a gradient is applied in the default background. Can be adjusted in the Background dialog box. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gradientmode-system-variable")
)

(
  :name "GRIDAXISCOLOR"
  :type :short
  :default 254
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Grid axis color: Controls the color of the grid axis lines. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gridaxiscolor-system-variable")
)

(
  :name "GRIDDISPLAY"
  :type :short
  :default 2
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grid display: Controls how the grid is displayed."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/griddisplay-system-variable")
)

(
  :name "GRIDMAJOR"
  :type :short
  :default 5
  :read-only NIL
  :range (1 100)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grid major: Controls the frequency of major versus minor grid lines. Values between 1 and 100 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gridmajor-system-variable")
)

(
  :name "GRIDMAJORCOLOR"
  :type :short
  :default (:unknown)
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Grid major color: Controls the color of the major grid lines. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gridmajorcolor-system-variable")
)

(
  :name "GRIDMINORCOLOR"
  :type :short
  :default 250
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Grid minor color: Controls the color of the minor grid lines. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gridminorcolor-system-variable")
)

(
  :name "GRIDMODE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grid mode: Turns the grid on."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gridmode-system-variable")
)

(
  :name "GRIDSTYLE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 7)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grid style: Controls if the grid is displayed as dots or lines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gridstyle-system-variable")
)

(
  :name "GRIDUNIT"
  :type :point
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grid unit: Controls the X and Y grid spacing for the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gridunit-system-variable")
)

(
  :name "GRIDXYZTINT"
  :type :short
  :default 1
  :read-only NIL
  :range (0 7)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Grid XYZ tint: Applies the UCS axis colors for grid lines. See also the COLORX, COLORY and COLORZ system variables. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gridxyztint-system-variable")
)

(
  :name "GRIPBLOCK"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grips in blocks: Displays grips on entities inside a block, when a block is selected. The insertion point of the block is displayed regardless of this setting."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gripblock-system-variable")
)

(
  :name "GRIPCOLOR"
  :type :short
  :default 72
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grip color: Controls the color of unselected grips."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gripcolor-system-variable")
)

(
  :name "GRIPDYNCOLOR"
  :type :short
  :default 140
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Dynamic grip color: Controls the color of custom grips for dynamic blocks."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gripdyncolor-system-variable")
)

(
  :name "GRIPHOT"
  :type :short
  :default 240
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Selected grip color: Controls the color of selected grips."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/griphot-system-variable")
)

(
  :name "GRIPHOVER"
  :type :short
  :default 150
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hover grip color: Controls the color of an unselected grip, when the cursor hovers over it."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/griphover-system-variable")
)

(
  :name "GRIPOBJLIMIT"
  :type :short
  :default 100
  :read-only NIL
  :range (0 32767)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grip entity limit: Sets the maximum number of grips to display for a selection. Values between 0 and 32767 are accepted. The display of grips is suppressed if the number of selected entities exceeds the value of this system variable. If set to 0, grips are always displayed."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gripobjlimit-system-variable")
)

(
  :name "GRIPS"
  :type :short
  :default 2
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grips: Controls how grips display when entities are selected."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/grips-system-variable")
)

(
  :name "GRIPSIZE"
  :type :short
  :default 4
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grip size: Controls the grip display size, in pixels. Values between 1 and 255 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gripsize-system-variable")
)

(
  :name "GRIPTIPS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Grip tips: Controls if grip tips display when the cursor hovers over grips on custom entities or dynamic blocks that support grip tips (Not yet supported)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/griptips-system-variable")
)

(
  :name "GSDEVICETYPE2D"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "2D graphic system device: Sets current graphic system device used for wireframe. GDI+ option is strongly recommended, extra options are available only for testing purposes. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gsdevicetype2d-system-variable")
)

(
  :name "GSDEVICETYPE3D"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "3D graphic system device: Set current graphic system device for rendered output for Hidden, Gouraud (with edges) and Flat (with edges) visual styles. Other rendered visual styles, such as Modeling and Realistic, will always use RedOpenGL. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/g/gsdevicetype3d-system-variable")
)

(
  :name "HALOGAP"
  :type :short
  :default 0
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Halo gap: Controls the value of the gap displayed if an entity is hidden by another entity. Applies to 2D views only. Specified as a percent of one drawing unit, independent of the zoom level."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/halogap-system-variable")
)

(
  :name "HANDLES"
  :type :integer
  :default 1
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Publish Handles: Shows if entity handles can be accessed by applications or not."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/handles-system-variable")
)

(
  :name "HANDSEED"
  :type :string
  :default "25"
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Handle seed: Indicates the handle used to create new entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/handseed-system-variable")
)

(
  :name "HIDEPRECISION"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hide and shade precision: Controls the accuracy of hides and shades. If on, uses double precision, more memory is needed, which might affect performance."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hideprecision-system-variable")
)

(
  :name "HIDESYSTEMPRINTERS"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hide system printers: Hides system printers."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hidesystemprinters-system-variable")
)

(
  :name "HIDETEXT"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hide text on HIDE: Controls if text can be hidden with the HIDE command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hidetext-system-variable")
)

(
  :name "HIDEXREFSCALES"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hide xref scales: Hides XRefs scales."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hidexrefscales-system-variable")
)

(
  :name "HIGHLIGHT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Highlight: Highlights entities when they are selected. Note: Does not affect entities selected with grips."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/highlight-system-variable")
)

(
  :name "HIGHLIGHTCOLOR"
  :type :short
  :default 150
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Selection Highlight Color: Controls the highlight color used when GLSelectionHighlightStyle is set to Use a different color for highlight . Note: The HIGHLIGHTCOLOR system variable is effective only in the 2dWireframe visual style. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/highlightcolor-system-variable")
)

(
  :name "HIGHLIGHTEFFECT"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Selection Highlight Style: Controls how entities are highlighted. Note: The HIGHLIGHTEFFECT system variable is effective only in the 2dWireframe visual style. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/highlighteffect-system-variable")
)

(
  :name "HIGHLIGHT_ALPHA"
  :type :short
  :default 85
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Highlighted area transparency: Controls the transparency of a filled area when selected. Values between 0 and 100 are accepted. A value of zero means fully transparent. A value of 100 means fully opaque. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/highlight_alpha-system-variable")
)

(
  :name "HORIZONBKG_ENABLE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Horizon background: Controls if horizon background is shown in perspective views. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/horizonbkg_enable-system-variable")
)

(
  :name "HORIZONBKG_GROUNDHORIZON"
  :type :string
  :default "RGB:67,74,80"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ground horizon: Controls the color of the ground horizon."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/horizonbkg_groundhorizon-system-variable")
)

(
  :name "HORIZONBKG_GROUNDORIGIN"
  :type :string
  :default "RGB:95,103,112"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ground origin: Controls the color of the ground."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/horizonbkg_groundorigin-system-variable")
)

(
  :name "HORIZONBKG_SKYHIGH"
  :type :string
  :default "RGB:204,229,234"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sky high: Controls the color of the higher regions of the sky."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/horizonbkg_skyhigh-system-variable")
)

(
  :name "HORIZONBKG_SKYHORIZON"
  :type :string
  :default "RGB:238,248,250"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sky horizon: Controls the color at the lowest part of the sky at the horizon. This effect can be very subtle. This color is also used as the color of the \"sky\" when the camera is below the \"earth\"."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/horizonbkg_skyhorizon-system-variable")
)

(
  :name "HORIZONBKG_SKYLOW"
  :type :string
  :default "RGB:238,248,250"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sky low: Controls the color of the lower regions of the sky."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/horizonbkg_skylow-system-variable")
)

(
  :name "HOTKEYASSISTANT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hotkey Assistant: Displays the Hotkey Assistant. The Hotkey Assistant appears in the bottom-middle of the screen and displays keyboard shortcut tips, during some commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hotkeyassistant-system-variable")
)

(
  :name "HPANG"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern angle: The hatch pattern angle."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpang-system-variable")
)

(
  :name "HPANNOTATIVE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern annotative: Controls if new hatch patterns are created as annotative hatch patterns."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpannotative-system-variable")
)

(
  :name "HPASSOC"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern associativity: Controls if new hatch patterns and gradient fills are associative. Associative hatches and gradient fills are updated automatically when their boundaries change."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpassoc-system-variable")
)

(
  :name "HPBACKGROUNDCOLOR"
  :type :string
  :default "."
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch background default color: The default hatch background color. Enter '.' for none."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpbackgroundcolor-system-variable")
)

(
  :name "HPBOUND"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern boundary: Controls the entity type created by the BHATCH and BOUNDARY commands."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpbound-system-variable")
)

(
  :name "HPBOUNDRETAIN"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern boundary retain: Creates boundary entities for hatches and gradient fills."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpboundretain-system-variable")
)

(
  :name "HPCOLOR"
  :type :string
  :default "."
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch default color: Controls the default hatch foreground color. Enter '.' to use the current color, defined by the CECOLOR system variables."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpcolor-system-variable")
)

(
  :name "HPDOUBLE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern doubling: Controls user-defined hatch pattern crosshatching. If on, creates a cross hatch. If off, creates a single hatch."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpdouble-system-variable")
)

(
  :name "HPDRAWORDER"
  :type :short
  :default 3
  :read-only NIL
  :range (0 4)
  :bitcoded T
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern draw order: Controls the draw order of hatches and gradient fills, defined by the Draw order setting in the Hatch and Gradient dialog box."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpdraworder-system-variable")
)

(
  :name "HPGAPTOL"
  :type :real
  :default 0.0
  :read-only NIL
  :range (0 NIL)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern gap tolerance: Controls the tolerance for a boundary created with the BHATCH or BOUNDARY commands. When zoomed in closely, boundary detection will fail. When zoomed so the contour 'looks' closed, the boundary is detectable. Values between 0.0 and 500.0 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpgaptol-system-variable")
)

(
  :name "HPISLANDDETECTION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern island detection: Controls hatch creation when islands are within a hatch boundary."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpislanddetection-system-variable")
)

(
  :name "HPLAYER"
  :type :string
  :default "<Use Current>"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Default layer for new hatches: The default layer for new hatches."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hplayer-system-variable")
)

(
  :name "HPLINETYPE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern linetype: Applies non-continuous linetypes to hatch entities (decreases performance). When turned off, lines in the hatch pattern display as continuous, even if a non-continuous linetype is applied to the hatch entity. When turned on, lines in the hatch pattern display with the linetype that’s applied to the hatch entity. This is not recommended because it can impact performance. Instead, you can choose a hatch pattern that is predefined with a non-continuous..."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hplinetype-system-variable")
)

(
  :name "HPMAXAREAS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Fill mode for sparse hatches: Converts sparse hatches to fills."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpmaxareas-system-variable")
)

(
  :name "HPMAXCONTOURPOINTS"
  :type :short
  :default 100000
  :read-only NIL
  :range (0 10000000)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximum number of points on a hatch contour: Controls the maximum number of points on a contour (outline) that a hatch entity can contain and still render. Values between 0 and 10,000,000 are accepted. Hatches do not render if the number of points exceeds the specified value. Setting to 0 disables the check, meaning the variable is not used. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpmaxcontourpoints-system-variable")
)

(
  :name "HPNAME"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern name: The default hatch pattern name."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpname-system-variable")
)

(
  :name "HPOBJWARNING"
  :type :integer
  :default 10000
  :read-only NIL
  :range (1 100000000)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern entity warning: Controls how many hatch boundary entities can be selected before a warning message appears. Values between 1 and 100,000,000 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpobjwarning-system-variable")
)

(
  :name "HPORIGIN"
  :type :point
  :default (0 0)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern origin: Stores the origin point for new hatches, relative to the current UCS."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hporigin-system-variable")
)

(
  :name "HPSCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern scale: The default hatch pattern scale."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpscale-system-variable")
)

(
  :name "HPSEPARATE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern separate: Controls if separate hatches or a single hatch is created when several hatch boundaries are selected, during the HATCH command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpseparate-system-variable")
)

(
  :name "HPSPACE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hatch pattern spacing: Controls the hatch pattern line spacing for user-defined hatch patterns."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hpspace-system-variable")
)

(
  :name "HPTRANSPARENCY"
  :type :string
  :default "."
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Default transparency for new hatches: The default transparency for new hatches, as a percentage. Values accepted: ByLayer, ByBlock, '.' (use current), 0 (fully opaque), and 90 (maximum transparency)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hptransparency-system-variable")
)

(
  :name "HYPERLINKBASE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hyperlink base: The file path for relative hyperlinks in the drawing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/h/hyperlinkbase-system-variable")
)

(
  :name "IFCCREATEUNIQUEGUID"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export with unique guids: Controls if unique GUIDs (Globally Unique Identifiers) for nested elements are generated during IFC export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifccreateuniqueguid-system-variable")
)

(
  :name "IFCEXPLODEEXTERNALREFERENCES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Explode external references in IFC spatial structure: Explodes external references in IFC spatial structures during IFC export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexplodeexternalreferences-system-variable")
)

(
  :name "IFCEXPORTAUTHOR"
  :type :string
  :default "\" \""
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export Author Name: Author name defined in the IFC file header. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportauthor-system-variable")
)

(
  :name "IFCEXPORTAUTHORIZATION"
  :type :string
  :default "\" \""
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export Authorization: Authorization defined in the IFC file header. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportauthorization-system-variable")
)

(
  :name "IFCEXPORTBASEQUANTITIES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export base quantities: Export derived base quantities (quantities calculated from two or more measurements) from BIM entities during IFC export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportbasequantities-system-variable")
)

(
  :name "IFCEXPORTELEMENTSONOFFANDFROZENLAYER"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export elements on Off and Frozen layers: Exports elements on Off and Froze layers during IFC export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportelementsonoffandfrozenlayer-system-variable")
)

(
  :name "IFCEXPORTIDSPROPERTIESONLY"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export IDS Properties Only: When an IDS-XML file has been imported, this setting controls whether only the properties required by the IDS file should be exported to the IFC file or all properties should be exported. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportidspropertiesonly-system-variable")
)

(
  :name "IFCEXPORTMAPPINGPATH"
  :type :string
  :default "\" \""
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Export mapping file path: Exports file paths during IFC export."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportmappingpath-system-variable")
)

(
  :name "IFCEXPORTMULTIPLYELEMENTSASAGGREGATED"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export multi-ply elements as aggregated elements: Export multi-ply elements as aggregated elements. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportmultiplyelementsasaggregated-system-variable")
)

(
  :name "IFCEXPORTORGANIZATION"
  :type :string
  :default "\" \""
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export Organization Name: Organization defined in the IFC file header. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportorganization-system-variable")
)

(
  :name "IFCEXPORTPROFILECENTEROFGRAVITY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export profile center of gravity: Export profile center of gravity during IFC export, applies only to IFC2x3. Warning: May cause linear solids to appear in the wrong position. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportprofilecenterofgravity-system-variable")
)

(
  :name "IFCEXPORTSUBTRACTOPENINGS"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Subtracts the openings from the host geometry before export: Use this to increase the reliability of the geometry when opening in another software (it avoids relying on the boolean operations of the target software). It will make editing the model in the target software more difficult. Note: This behavior is the default for IFC4 Reference View file export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportsubtractopenings-system-variable")
)

(
  :name "IFCEXPORTSWEPTSOLIDSASBREP"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Always export swept solids as BRep: Exports extrusions, revolutions, swept 3D solids with clippings and subtractions with a boundary representation during IFC export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportsweptsolidsasbrep-system-variable")
)

(
  :name "IFCEXPORTTESSELATION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Level of tessellation: Controls the exported geometry tessellation level during IFC export. When the Current faceting option is chosen, no regeneration is required, the faceting as set by FACETRES system variables or the Modeler Properties. The Low , Medium , or High options cause regeneration of facets, which takes longer. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexporttesselation-system-variable")
)

(
  :name "IFCEXPORTVALIDATEMODEL"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Apply IFC model validation: Checks that an IFC model complies with schema rules during IFC export. Problems are reported in an export log next to IFC file. Warning: Validation takes extra time and can slow down the export of big IFC files. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcexportvalidatemodel-system-variable")
)

(
  :name "IFCSETTINGSCONFIG"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "IFC settings configuration: Specifies the name of the IFC settings configuration file. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifcimportsettingsconfig-system-variable")
)

(
  :name "IFCTESSELATEBSPLINECURVESANDSURFACES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tessellate complex curves and surfaces: Tessellates BSpline curves and surfaces in IFC4 and IFC4.1 during IFC export. Note: BSpline curves are not supported by some software products in IFC import."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/ifctesselatebsplinecurvesandsurfaces-system-variable")
)

(
  :name "IMAGECACHEFOLDER"
  :type :string
  :default "{User}AppData/Local/Temp/ImageCache"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Image disk cache folder: The file path used to store temporary image cache file. See the IMAGEDISKCACHE system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/imagecachefolder-system-variable")
)

(
  :name "IMAGECACHEMAXMEMORY"
  :type :short
  :default 160
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximum used memory: Maximum size of the in-memory image cache, in MiB. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/imagecachemaxmemory-system-variable")
)

(
  :name "IMAGEDISKCACHE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Image disk cache: Stores temporary image cache files. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/imagediskcache-system-variable")
)

(
  :name "IMAGEFRAME"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Image frame: Controls the visibility of image frames, if the FRAME system variable is set to Use individual system variables (3)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/imageframe-system-variable")
)

(
  :name "IMAGEHLT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Image highlight: Controls how an image is highlighted when selected. If on, highlights the whole image. If off, highlights the border only."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/imagehlt-system-variable")
)

(
  :name "IMAGENOTIFY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Image notify: Displays a warning, when a drawing is opened, if there are missing raster images. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/imagenotify-system-variable")
)

(
  :name "IMPORTCATIAV5EDGEATTRIBUTES"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import edge attributes mode: Controls the import of edge attributes, by edge type, during a Catia V5 import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importcatiav5edgeattributes-system-variable")
)

(
  :name "IMPORTCATIAV5REPRESENTATION"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import representation: Controls the data that the Communicator for BricsCAD imports during a Catia V5 import. Preview graphics are only imported and shown if the COMMUNICATORBACKGROUNDMODE system variable is on. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importcatiav5representation-system-variable")
)

(
  :name "IMPORTCATIAV5SEARCHPATHSPREFERENCE"
  :type :short
  :default 1
  :read-only NIL
  :range (1 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Search path preference: Controls the priority of file paths during a Catia V5 import. Note: This option is taken into account only when import in background is enabled (COMMUNICATORBACKGROUNDMODE system variable is ON). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importcatiav5searchpathspreference-system-variable")
)

(
  :name "IMPORTCOLORS"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Translate colors: Controls how colors are converted during import."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importcolors-system-variable")
)

(
  :name "IMPORTCREOALTERNATESEARCHPATHS"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Alternate search paths: The alternate file used during a Creo import. Separate values with semicolons (;). Note: Paths must be absolute (fully qualified) and separated with a semicolon. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importcreoalternatesearchpaths-system-variable")
)

(
  :name "IMPORTCREOCONFIGURATION"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import configuration: Sets the name of the configuration to import. If no configuration name is specified, then the part's default configuration is imported. Note: A named configuration sets a collection of body entities in a part that can be imported as a group while suppressing the import of other body entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importcreoconfiguration-system-variable")
)

(
  :name "IMPORTCUIFILEEXISTS"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import cui file exists: Controls what to do when a CUI file already exists, when a MNU or CUIX file is imported. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importcuifileexists-system-variable")
)

(
  :name "IMPORTHIDDENPARTS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Hidden parts: Controls how hidden parts are imported."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importhiddenparts-system-variable")
)

(
  :name "IMPORTIGESSIMPLIFY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Perform simplification: Automatically runs the DMSIMPLIFY command during an IGES import. If on, overrides the IMPORTSIMPLIFY system variable on IGES models. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importigessimplify-system-variable")
)

(
  :name "IMPORTIGESSTITCH"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Perform stitching: Automatically runs the DMSTITCH command during an IGES import. If on, overrides the IMPORTSTITCH system variable on IGES models. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importigesstitch-system-variable")
)

(
  :name "IMPORTINVENTORALTERNATESEARCHPATHS"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Alternate search paths: Controls the list of alternate file system paths used during an Inventor file import. Separate values with semicolons (;). Note: Paths must be absolute (fully qualified) and separated with semicolon. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importinventoralternatesearchpaths-system-variable")
)

(
  :name "IMPORTINVENTORSEARCHPATHSPREFERENCE"
  :type :short
  :default 1
  :read-only NIL
  :range (1 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Search paths preference: Controls the priority order of search paths during an Inventor file import. Note: This option is taken into account only when import in background is enabled (COMMUNICATORBACKGROUNDMODE system variable is ON). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importinventorsearchpathspreference-system-variable")
)

(
  :name "IMPORTJTREPRESENTATION"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Import representation: Controls the data to import during a JT import. Note: This option is only taken into account when import in background is enabled."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importjtrepresentation-system-variable")
)

(
  :name "IMPORTNXALTERNATESEARCHPATHS"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Alternate search paths: Controls the list of alternate file paths used during an NX import. Separate values with semicolons (;). Note: Paths must be absolute (fully qualified) and separated with semicolon. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importnxalternatesearchpaths-system-variable")
)

(
  :name "IMPORTNXCONFIGURATION"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import configuration: Sets the name of the configuration that should be imported. If no configuration name is specified, then the part's default configuration will be imported. Note: A named configuration sets a collection of body entities in a part that can be imported as a group while suppressing the import of other body entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importnxconfiguration-system-variable")
)

(
  :name "IMPORTNXSEARCHPATHSPREFERENCE"
  :type :short
  :default 1
  :read-only NIL
  :range (1 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Search paths preference: Controls the priority of file paths during an NX import. Note: This option is taken into account only when import in background is enabled (COMMUNICATORBACKGROUNDMODE system variable is ON). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importnxsearchpathspreference-system-variable")
)

(
  :name "IMPORTPMI"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Product and manufacturing information: Enables the import of product and manufacture information. Note: Currently, such information is imported as exploded data (lines, text, etc.) instead of compound entities (for example: annotations). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importpmi-system-variable")
)

(
  :name "IMPORTPRODUCTSTRUCTURE"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Product structure: Controls the way a product structure is represented for an imported model. As mechanical blocks automatically runs the BMMECH command after import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importproductstructure-system-variable")
)

(
  :name "IMPORTREPAIR"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Repair model on import: Automatically runs the DMAUDITALL command on imported models. 3D geometry is analyzed and problems are fixed automatically, in order to improve the quality of the imported geometry. Geometry modeled in CAD systems which use a kernel different from ACIS, often needs to be healed because of possible flaws. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importrepair-system-variable")
)

(
  :name "IMPORTSIMPLIFY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Perform simplification: Automatically runs the DMSIMPLIFY command on imported models. See also the IMPORTIGESSIMPLIFY system variable. Note: The IMPORTIGESSIMPLIFY system variable can set an override for the IGES file format. Convert imported splines into canonical surfaces. Simplify topology (remove imprinted edges) if possible. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importsimplify-system-variable")
)

(
  :name "IMPORTSOLIDEDGEALTERNATESEARCHPATHS"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Alternate search paths: Controls the list of alternate file paths used during a Solid Edge file import. Separate values with semicolons (;). Note: Paths must be absolute (fully qualified) and separated with semicolon. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importsolidedgealternatesearchpaths-system-variable")
)

(
  :name "IMPORTSOLIDEDGESEARCHPATHSPREFERENCE"
  :type :short
  :default 1
  :read-only NIL
  :range (1 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Search paths preference: Controls the priority order of files paths during a Solid Edge file import. Note: This option is taken into account only when import in background is enabled (COMMUNICATORBACKGROUNDMODE system variable is ON). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importsolidedgesearchpathspreference-system-variable")
)

(
  :name "IMPORTSOLIDWORKSALTERNATESEARCHPATHS"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Alternate search paths: Controls the list of alternate file system paths to search during a SolidWorks® import. Separate values with semicolons (;). Note: Paths must be absolute (fully qualified) and separated with a semicolon. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importsolidworksalternatesearchpaths-system-variable")
)

(
  :name "IMPORTSOLIDWORKSCONFIGURATION"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import configuration: Sets the name of the configuration that should be imported. If no configuration name is specified, then the part's default configuration will be imported. Note: A named configuration sets a collection of body entities in a part that can be imported as a group while suppressing the import of other body entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importsolidworksconfiguration-system-variable")
)

(
  :name "IMPORTSOLIDWORKSREPRESENTATION"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Import representation: Controls the data imported during a SolidWorks® import. Preview graphics are only imported and shown if the COMMUNICATORBACKGROUNDMODE system variable is on."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importsolidworksrepresentation-system-variable")
)

(
  :name "IMPORTSOLIDWORKSROTATEYZ"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Map SolidWorks Y to current Z axis: Enables the conversion of a SolidWorks coordinate system to the current coordinate system. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importsolidworksrotateyz-system-variable")
)

(
  :name "IMPORTSOLIDWORKSSEARCHPATHSPREFERENCE"
  :type :short
  :default 1
  :read-only NIL
  :range (1 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Search paths preference: Controls the priority order for search paths during a SolidWorks® import. Note: This option is taken into account only when import in background is enabled (COMMUNICATORBACKGROUNDMODE system variable is ON). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importsolidworkssearchpathspreference-system-variable")
)

(
  :name "IMPORTSTEPROTATEYZ"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Map Y to current Z axis: Enables conversion of a SolidWorks coordinate system to the current coordinate system, during a STEP import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importsteprotateyz-system-variable")
)

(
  :name "IMPORTSTITCH"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Perform stitching: Automatically runs the DMSTITCH command on imported models. See the IMPORTIGESSTITCH system variable. In some cases, imported geometry represents solid geometry as a set of separate surfaces. Use the DMSTITCH command to work with solid operations on the imported geometry. If IMPORTSTITCH is set to ON, the DMSTITCH command is executed automatically when the geometry is imported. Note: Stitch operations are time-consuming when importing large files. Check..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/importstitch-system-variable")
)

(
  :name "INCLUDEPLOTSTAMP"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Include Plot Stamp: Includes a plot stamp when printing. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/includeplotstamp-system-variable")
)

(
  :name "INDEXCTL"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Index control: Controls if layer and/or spatial indexes are created and saved."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/indexctl-system-variable")
)

(
  :name "INETLOCATION"
  :type :string
  :default "\"http://www.bricsys.com\""
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Internet location: The default website for the BROWSER command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/inetlocation-system-variable")
)

(
  :name "INSBASE"
  :type :point3d
  :default (0 0 0)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Insertion base point: The drawing's insertion point, used when the drawing is inserted into other drawings as a block. Set by the BASE command, and expressed as a UCS coordinate for the current space."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/insbase-system-variable")
)

(
  :name "INSNAME"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Insertion name: Stores the default block name for the INSERT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/insname-system-variable")
)

(
  :name "INSUNITS"
  :type :short
  :default 1
  :read-only NIL
  :range (0 24)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Insertion units: Controls the unit used to scale blocks, images or XRefs, when they are inserted into a drawing. When both the INSUNITS and PROPUNITS system variables are on, length, area, volume and/or inertia properties are formatted with their respective unit(s). Note: It does not convert current drawing units. See also the LUNITS and MEASUREMENT system variables"
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/insunits-system-variable")
)

(
  :name "INSUNITSDEFSOURCE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 24)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Insertion units default source: Controls the source content units value. Note: If INSUNITS in the source drawing is Unspecified , INSUNITSDEFSOURCE is used instead."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/insunitsdefsource-system-variable")
)

(
  :name "INSUNITSDEFTARGET"
  :type :short
  :default 0
  :read-only NIL
  :range (0 24)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Insertion units default target: Controls the target drawing units value, if the INSUNITS system variable is zero. Values between 0 and 20 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/insunitsdeftarget-system-variable")
)

(
  :name "INSUNITSSCALING"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Insertion units scaling: Controls how the INSUNITS system variable is applied when entities are inserted, imported or pasted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/insunitsscaling-system-variable")
)

(
  :name "INTERFERECOLOR"
  :type :string
  :default "ByLayer"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Interference color: Controls the color of interference entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/interferecolor-system-variable")
)

(
  :name "INTERFERELAYER"
  :type :string
  :default "\"Interferences\""
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Interference layer: Controls the layer used for interference entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/interferelayer-system-variable")
)

(
  :name "INTERFERENCELEVEL"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Interference Check Level: Controls the interference check between details, copied details and/or the rest of the model. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/interferencelevel-system-variable")
)

(
  :name "INTERFEREOBJVS"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Interference entity visual style: Controls the interference entity visual style."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/interfereobjvs-system-variable")
)

(
  :name "INTERFEREVPVS"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Interference viewport visual style: Controls the interference checking visual style for the viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/interferevpvs-system-variable")
)

(
  :name "INTERIORELEVATIONMINLENGTH"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Interior Elevation Minimum Length: Minimum length of a wall for an Interior Elevation to generate. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/interiorelevationminlength-system-variable")
)

(
  :name "INTERIORELEVATIONOFFSET"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Interior Elevation Offset Distance: Offset distance, for an Interior Elevation volume, from wall surfaces. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/interiorelevationoffset-system-variable")
)

(
  :name "INTERSECTEDENTITIES"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Resolve intersection: Controls how new entities, modify existing entities when they intersect. Applies to entities as they are created with the EXTRUDE and REVOLVE commands, when the Auto option is selected. The INTERSECTEDENTITIES system variable is one of the four system variables found under the Extrude mode group. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/intersectedentities-system-variable")
)

(
  :name "INTERSECTIONCOLOR"
  :type :short
  :default 257
  :read-only NIL
  :range (0 257)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Intersection color: Controls the polyline color at the intersection of 3D surfaces in 2D Wireframe views, if INTERSECTIONDISPLAY is on (Not yet supported)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/intersectioncolor-system-variable")
)

(
  :name "INTERSECTIONDISPLAY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Intersection display: Toggles the display of polylines at the intersection of 3D surfaces in 2D Wireframe views (Not yet supported)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/intersectiondisplay-system-variable")
)

(
  :name "ISAVEBAK"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Incremental save backup: Creates backup files (BAK) for active drawings. If off, improves the speed of incremental saves, especially for large drawings."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/isavebak-system-variable")
)

(
  :name "ISAVEPERCENT"
  :type :short
  :default 50
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Save percent: Controls the \"wasted space\" allowed for QUICKSAVE actions, before a full save is executed,as a percentage. Values between 0 and 100 are accepted. A value of zero means Each save is a full save."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/isavepercent-system-variable")
)

(
  :name "ISOLINES"
  :type :short
  :default 4
  :read-only NIL
  :range (0 2047)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Isolines: Controls the number of isolines (contour lines) per curved surface. Values between 0 and 2047 are accepted. Note: To view changes on existing entities, perform a REGEN."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/i/isolines-system-variable")
)

(
  :name "KEEPCONNECTIONS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Solve interferences and gaps: Controls whether interferences or gaps should be solved. If on: When a modification of a solid through TCONNECT, BIMUPDATETHICKNESS, BIMATTACHCOMPOSITION or BIMAUTOMATCH, causes interferences, these will be subtracted from the other solids; when it causes gaps, these will be filled. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/k/keepconnections-system-variable")
)

(
  :name "LASTANGLE"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Last angle: The end angle of the last arc drawn."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lastangle-system-variable")
)

(
  :name "LASTPOINT"
  :type :point3d
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Last point: The coordinates of the last point entered - the value used by the '@' symbol in the Command line. Note: Expressed as a UCS coordinate for the current space; referenced by the at symbol (@) during keyboard entry."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lastpoint-system-variable")
)

(
  :name "LASTPROMPT"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Last prompt: The last string in Command line."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lastprompt-system-variable")
)

(
  :name "LATITUDE"
  :type :real
  :default 37.795
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Latitude: Controls the latitude of the current drawing, in decimal format. Values between -90.0 and 90.0 are accepted. Positive values represent north latitudes."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/latitude-system-variable")
)

(
  :name "LAYERFILTEREXCESS"
  :type :short
  :default 250
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Layer Filter Excess: Specifies the maximum number of layer filters allowed in a drawing before suggesting some be removed. You can create any number of layer filters. However, if the number of layer filters exceeds this value and exceeds the number of layers, a message dialog displays the next time you open the drawing. It recommends deleting all layer filters to improve performance. If LAYERFILTEREXCESS is 0, dialog is suppressed. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/layerfilterexcess-system-variable")
)

(
  :name "LAYERPMODE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Layer previous mode: Tracks layer settings modification and enables the LAYERP command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/layerpmode-system-variable")
)

(
  :name "LAYLOCKFADECTL"
  :type :short
  :default 50
  :read-only NIL
  :range (-90 90)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Locked layer fade control: Controls the fade level for entities on locked layers to contrast them with entities on unlocked layers and reduces the visual complexity of a drawing. Entities on locked layers are still visible for reference and for object snapping. Values between -90 and 90 are accepted. Negative values disable fading."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/laylockfadectl-system-variable")
)

(
  :name "LAYOUTREGENCTL"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Layout regeneration control: Controls how the display of the Model and layout tabs is updated. If performance is poor in general or when switching between tabs. Setting LAYOUTREGENCTL to 1 or 0 might improve performance."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/layoutregenctl-system-variable")
)

(
  :name "LAYOUTTAB"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Layout and model tabs: Controls the display of layout and model tabs."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/layouttab-system-variable")
)

(
  :name "LEGACYCODESEARCH"
  :type :integer
  :default 0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Legacy code search mode: Enables unsafe search for executable code in drawing folders."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/legacycodesearch-system-variable")
)

(
  :name "LENGTHUNITS"
  :type :string
  :default "\"in ft mi µm mm cm m km\""
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Length units: Controls a list of units used to display lengths, if length properties are formatted with the PROPUNITS system variable. The string contains a space-separated list of unit abbreviations. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lengthunits-system-variable")
)

(
  :name "LENSLENGTH"
  :type :real
  :default 50.0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Lens length: Displays the current viewport's lens length, in millimeters, used for perspective mode."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lenslength-system-variable")
)

(
  :name "LEVELOFDETAIL"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Composition Level of detail: Controls the composition level of detail (LOD). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/levelofdetail-system-variable")
)

(
  :name "LICFLAGS"
  :type :short
  :default 0
  :read-only T
  :range (0 7)
  :bitcoded T
  :scope :session
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Licensed components: Controls if certain components are licensed or not. The value is stored as a bitcode using the sum of the values of all selected options. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/licflags-system-variable")
)

(
  :name "LIGHTGLYPHCOLOR"
  :type :short
  :default 30
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color for light glyph: Controls the color of light glyphs (icons used to indicate the placement of lights in model space). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lightglyphcolor-system-variable")
)

(
  :name "LIGHTGLYPHDISPLAY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Light display: Displays a visual representation of lights for all light locations."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lightglyphdisplay-system-variable")
)

(
  :name "LIGHTINGUNITS"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Lighting units: Controls the light units type."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lightingunits-system-variable")
)

(
  :name "LIGHTWEBGLYPHCOLOR"
  :type :short
  :default 1
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color for web light glyph: Controls the color for web light glyphs (icons used to indicate the placement of web lights in model space). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lightwebglyphcolor-system-variable")
)

(
  :name "LIMCHECK"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Limits check: Prevent the creation of entities outside the drawing limits."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/limcheck-system-variable")
)

(
  :name "LIMMAX"
  :type :point
  :default (12 9)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Limits maximum: The upper-right corner of the drawing limits, expressed in world coordinates."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/limmax-system-variable")
)

(
  :name "LIMMIN"
  :type :point
  :default (0 0)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Limits minimum: The lower-left corner of the drawing limits, expressed in world coordinates."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/limmin-system-variable")
)

(
  :name "LINEARARROWHEADLENGTH"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default head length: Sets the default head length of linear arrows. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lineararrowheadlength-system-variable")
)

(
  :name "LINEARARROWHEADWIDTH"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default head width: Sets the default head width of linear arrows. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lineararrowheadwidth-system-variable")
)

(
  :name "LINEARARROWTHICKNESS"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Default thickness: Sets the default thickness of linear arrows. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lineararrowthickness-system-variable")
)

(
  :name "LINEARBRIGHTNESS"
  :type :short
  :default 0
  :read-only NIL
  :range (-10 10)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Linear brightness (deprecated): Controls the intensity of lights, can be specified per viewport. Values between -10 and 10 are accepted. A value of zero means no scaling. Smaller values decrease light intensity and bigger values increase light intensity. This setting can be specified per viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/linearbrightness-system-variable")
)

(
  :name "LINEARCONTRAST"
  :type :short
  :default 0
  :read-only NIL
  :range (-10 10)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Linear contrast (deprecated): Controls ambient light intensity. Only effects materials with a non-black ambient color, can be set per viewport. Values between -10 and 10 are accepted. A value of -10 means maximum ambient light. A value of 10 means no ambient light. This setting only has effect on materials that have a non-black ambient color. This setting can be specified per viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/linearcontrast-system-variable")
)

(
  :name "LINETYPE3DPLINE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "3D Polyline linetype: Controls applying line type to 3D Polyline. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/linetype3dpline-system-variable")
)

(
  :name "LISPINIT"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "LISP init: Controls if LISP variables and functions are preserved between drawings."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lispinit-system-variable")
)

(
  :name "LISPSYS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "2021+" :bricscad nil)
  :vendor :autocad
  :divergence "BricsCAD has no LISPSYS sysvar; engine selection happens differently."
  :summary "Selects the AutoLISP engine (legacy vs. modern). Read by load and open to choose the loader and source-file encoding."
  :coupled ("load" "open")
  :source (:autocad "https://help.autodesk.com/view/ACD/2026/ENU/?guid=GUID-09E1B7E9-D8E5-4E1B-B30F-2EAE5DAC8FC8" :bricscad NIL)
)

(
  :name "LOADMECHANICAL2D"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mechanical 2D Editor: Controls if Mechanical 2D enablers can load. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/loadmechanical2d-system-variable")
)

(
  :name "LOCALE"
  :type :string
  :default "\"en_US\""
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Locale: The ISO language code of this version of the program."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/locale-system-variable")
)

(
  :name "LOCALROOTPREFIX"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Local root prefix: The path of the folder, where local files for the current user, such as templates, were installed. The Template and Textures folders are in this location, and you can add any customizable files that you do not want to roam on the network. See ROAMABLEROOTPREFIX for the location of the roamable files."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/localrootprefix-system-variable")
)

(
  :name "LOCKUI"
  :type :short
  :default 0
  :read-only NIL
  :range (-7 7)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Lock user interface elements: Locks interface elements and prevents repositioning. Windows and Linux: hold the Ctrl key to override. macOS: hold the Cmd key to override."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lockui-system-variable")
)

(
  :name "LOFTANG1"
  :type :real
  :default 90.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Loft angle 1: Sets the angle at the first cross-section, for the LOFT command, modifies the loft shape. Works only if the LOFTNORMALS system variable is set to Surface uses draft angle and magnitude . Values between 0.0 and 360.0 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/loftang1-system-variable")
)

(
  :name "LOFTANG2"
  :type :real
  :default 90.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Loft angle 2: Sets the angle at the last cross-section, for the LOFT command, modifies the loft shape. Works only if the LOFTNORMALS system variable is set to Surface uses draft angle and magnitude . Values between 0.0 and 360.0 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/loftang2-system-variable")
)

(
  :name "LOFTMAG1"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Loft magnitude 1: Sets the relative distance of the surface from the cross section in the direction of the LOFTANG1 system variable, before the surface starts to bend towards the next section. Works only if the LOFTNORMALS system variable is set to Surface uses draft angle and magnitude ."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/loftmag1-system-variable")
)

(
  :name "LOFTMAG2"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Loft magnitude 2: Sets the relative distance of the surface from the cross section in the direction of the LOFTANG2 system variable, before the surface starts to bend towards the next section. Works only if the LOFTNORMALS system variable is set to Surface uses draft angle and magnitude ."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/loftmag2-system-variable")
)

(
  :name "LOFTNORMALS"
  :type :short
  :default 1
  :read-only NIL
  :range (0 6)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Loft normals: Controls the behavior of surfaces and solids created with the LOFT command as they pass through a cross section."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/loftnormals-system-variable")
)

(
  :name "LOFTPARAM"
  :type :short
  :default 7
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Loft param: Controls the shape of surfaces and solids created with the LOFT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/loftparam-system-variable")
)

(
  :name "LOGFILEMODE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Log file mode: Maintains a logfile. A logfile contains each executed command. These logfiles are saved in the folder specified by the LOGFILEPATH system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/logfilemode-system-variable")
)

(
  :name "LOGFILENAME"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Log file name: The name of the log file. See also the LOGFILEMODE system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/logfilename-system-variable")
)

(
  :name "LOGFILEPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Log file path: The file path used for the log file."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/logfilepath-system-variable")
)

(
  :name "LOGGEDINSTATUS"
  :type :integer
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Logged in: Shows if a Bricsys account is currently logged in to this version of the program. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/loggedinstatus-system-variable")
)

(
  :name "LOGINNAME"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Login name: Shows the Windows login name, saved to the file properties statistics of the drawing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/loginname-system-variable")
)

(
  :name "LONGITUDE"
  :type :real
  :default -122.394
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Longitude: Controls the longitude of the drawing, in decimal format. Values between -180.0 and 180.0 are accepted. Positive values represent east longitudes."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/longitude-system-variable")
)

(
  :name "LOOKFROMDIRECTIONMODE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "LookFrom direction mode: Controls how many view directions can be selected in isometric mode. Windows and Linux: hold the Ctrl key to switch from top to down directions. macOS: hold the Cmd key to switch from top to down directions. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lookfromdirectionmode-system-variable")
)

(
  :name "LOOKFROMFEEDBACK"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "LookFrom feedback: Controls if the LookFrom control displays messages in tooltips or on the Status bar. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lookfromfeedback-system-variable")
)

(
  :name "LOOKFROMZOOMEXTENTS"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "LookFrom zoom extents: Zooms to extents whenever a view direction is selected from the LookFrom control. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lookfromzoomextents-system-variable")
)

(
  :name "LTGAPSELECTION"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Linetype gap selection: Makes it possible to snap to gaps on non-continuous linetypes."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/ltgapselection-system-variable")
)

(
  :name "LTSCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Linetype scale: Sets the default linetype scale multiplier."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/ltscale-system-variable")
)

(
  :name "LUNITS"
  :type :short
  :default 2
  :read-only NIL
  :range (1 5)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Linear unit type: Controls the unit type for lengths."
  :coupled ("rtos" "distance" "getdist" "getreal")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lunits-system-variable")
)

(
  :name "LUPREC"
  :type :short
  :default 4
  :read-only NIL
  :range (0 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Linear unit precision: Controls the number of decimal places displayed for linear units. See also the MEASUREMENT and INSUINTS system variables."
  :coupled ("rtos" "distance" "getdist")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/luprec-system-variable")
)

(
  :name "LWDEFAULT"
  :type :short
  :default 25
  :read-only NIL
  :range (0 211)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Default lineweight: Controls the default lineweight, in hundredths of millimeters."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lwdefault-system-variable")
)

(
  :name "LWDISPLAY"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Lineweight display: Displays lineweights."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lwdisplay-system-variable")
)

(
  :name "LWDISPSCALE"
  :type :real
  :default 0.55
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Lineweight display scale: Controls the lineweight display scale in Model space. Values between 0.0 and 1.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lwdispscale-system-variable")
)

(
  :name "LWUNITS"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Lineweight units: Controls the lineweight display unit."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/l/lwunits-system-variable")
)

(
  :name "MACROREC"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Macro recording: Controls if a macro is currently being recorded. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/macrorec-system-variable")
)

(
  :name "MANIPULATOR"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Manipulator behavior: Controls when the Manipulator is displayed. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/manipulator-system-variable")
)

(
  :name "MANIPULATORCOLORTHEME"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color theme of Manipulator: Controls the color theme of the Manipulator. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/manipulatorcolortheme-system-variable")
)

(
  :name "MANIPULATORDURATION"
  :type :integer
  :default 250
  :read-only NIL
  :range (100 10000)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Manipulator duration: Controls the delay before the Manipulator is displayed, on a long left-click, when an entity is selected, in milliseconds. Values between 100 and 10,000 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/manipulatorduration-system-variable")
)

(
  :name "MANIPULATORHANDLE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Manipulator handle: Controls the behavior of the Manipulator anchor handles (the bars of the Manipulator). The handle can be used for unconstrained move and copy operations. Unconstrained meaning: not along an axis or constrained to a plane. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/manipulatorhandle-system-variable")
)

(
  :name "MANIPULATORSIZE"
  :type :real
  :default 1.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Size of Manipulator: Controls the size of the Manipulator. Values between 0.5 and 2.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/manipulatorsize-system-variable")
)

(
  :name "MASSPREC"
  :type :short
  :default -1
  :read-only NIL
  :range (-1 8)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mass precision: Controls the number of decimal places displayed for masses, if mass properties are formatted with the PROPUNITS system variable. Note: If negative, LUPREC (Linear Unit Precision) is used. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/massprec-system-variable")
)

(
  :name "MASSPROPACCURACY"
  :type :short
  :default 2
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mass properties calculation relative accuracy: Controls the accuracy used for mass properties calculations. This accuracy is relative. For a value of 3 the calculated values may deviate up to 0.1% from the actual value, for 12 it is 1.e-10%. For value of 2 the deviation may exceptionally exceed 1% and we assume a margin of 2%. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/masspropaccuracy-system-variable")
)

(
  :name "MASSUNITS"
  :type :string
  :default "oz lb st mg g kg t"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mass units: Controls the units used to display mass, if mass properties are formatted with the PROPUNITS system variable. If empty, all masses are displayed without units. The MASSUNITS setting affects the mass values only. Other mass properties such as density or moments of inertia are formatted in SI units for the metric system and in imperial units for the imperial system, regardless of the MASSUNITS setting. The string contains a space-separated list of unit abbreviati..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/massunits-system-variable")
)

(
  :name "MAXACTVP"
  :type :short
  :default 64
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Maximum active viewports: Controls the maximum number of viewports that can be active simultaneously in a layout. Has no effect on the number of viewports that are plotted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/maxactvp-system-variable")
)

(
  :name "MAXHATCH"
  :type :short
  :default 100000
  :read-only NIL
  :range (100 10000000)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximum hatch dashes: Controls the maximum number of dashes in a hatch pattern. Hatches of which the number of dashes exceeds the maximum number of dashes cannot be created. Values between 100 and 10,000,000 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/maxhatch-system-variable")
)

(
  :name "MAXSORT"
  :type :short
  :default 200
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Maximum sort: Controls the maximum number of symbol, file and/or block names sorted by commands that list. If the number of items exceeds this value, the items are not sorted into alphabetical order. Values between 0 and 200 are accepted."
  :coupled ("acad_strlsort")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/maxsort-system-variable")
)

(
  :name "MAXTHREADS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 16)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximum number of threads: Controls the maximum number of threads used to display and load drawings and point cloud operations. See also the MTFLAGS system variable. Values between 0 and 16 are accepted. A value of zero means automatically use the optimal number of threads. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/maxthreads-system-variable")
)

(
  :name "MBSTATE"
  :type :short
  :default 1
  :read-only T
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mechanical browser state: Mechanical browser status. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mbstate-system-variable")
)

(
  :name "MBUTTONPAN"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Middle button pan: Controls how the middle mouse button/wheel responds."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mbuttonpan-system-variable")
)

(
  :name "MEASUREINIT"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Measurement initial: Controls drawing units as Imperial or Metric for new drawings Also controls the hatch pattern and linetype files used: ANSI for Imperial and ISO for Metric units."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/measureinit-system-variable")
)

(
  :name "MEASUREMENT"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Measurement: Controls the current drawing units as Imperial or Metric, also controls if ANSI or ISO hatch pattern and linetype files are used. See also the LUNITS and INSUNITS system variables."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/measurement-system-variable")
)

(
  :name "MECH2DSAVEFORMAT"
  :type :short
  :default 2022
  :read-only NIL
  :range (2013 2022)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mechanical 2D save format: Controls the save format of Mechanical 2D entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mech2dsaveformat-system-variable")
)

(
  :name "MECHANICALBLOCKS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mechanical blocks: Enables or disables mechanical blocks as an alternative to mechanical components. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mechanicalblocks-system-variable")
)

(
  :name "MECHANICALBLOCKSOPTIONS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mechanical blocks options: Controls how blocks and mechanical blocks are used in the drawing. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mechanicalblocksoptions-system-variable")
)

(
  :name "MECHANICALBROWSERSETTINGS"
  :type :short
  :default 179
  :read-only NIL
  :range (0 511)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Mechanical browser options: Sets the default mechanical browser options. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mechanicalbrowsersettings-system-variable")
)

(
  :name "MENUBAR"
  :type :integer
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Menu bar: Displays the Menu bar."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/menubar-except-os-x-system-variable")
)

(
  :name "MENUCTL"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Menu control: Controls if the screen menu switches pages in response to keyboard command entry."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/menuctl-system-variable")
)

(
  :name "MENUECHO"
  :type :short
  :default 0
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Menu echo: Controls menu echo and prompt control."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/menuecho-system-variable")
)

(
  :name "MENUNAME"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Menu name: The file path for the menu file."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/menuname-system-variable")
)

(
  :name "MESHTYPE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Mesh type: Controls the type of mesh that is created by REVSURF, TABSURF, RULESURF and EDGESURF commands (Not yet supported)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/meshtype-system-variable")
)

(
  :name "MIDDLECLICKCLOSE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Middle click close (Mac & Linux): Allows a tab to be closed with a middle button click on the tab bar. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/middleclickclose-system-variable")
)

(
  :name "MILLISECS"
  :type :integer
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Milliseconds: Counts the number of milliseconds that have passed since system startup."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/millisecs-system-variable")
)

(
  :name "MIRRHATCH"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Mirror hatch patterns: Controls if hatch patterns are mirrored by the MIRROR command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mirrhatch-system-variable")
)

(
  :name "MIRRTEXT"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Mirror text: Controls if text is mirrored by the MIRROR command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mirrtext-system-variable")
)

(
  :name "MLEADERSCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Multileader scale: Controls the width scale for entities created with the MLEADER command. Note: The scale must have a positive value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mleaderscale-system-variable")
)

(
  :name "MODEMACRO"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Mode macro: Displays a text string on the status line, such as the name of the current drawing,time/date stamp or special modes. Used to help debug Diesel programs."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/modemacro-system-variable")
)

(
  :name "MSLTSCALE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Model space linetype scale: Controls the linetype annotation scale behavior, in model space. Note: When changing MSLTSCALE, REGEN or REGENALL is needed to update the display."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/msltscale-system-variable")
)

(
  :name "MSOLESCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Model space OLE scale: Controls the size of an OLE (Object Linking & Embedding) entity, that contains text, when pasted into model space. Entities already placed in the drawing are not affected. If set to zero, uses the DIMSCALE system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/msolescale-system-variable")
)

(
  :name "MTEXTCOLUMN"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Multiline text column setting: Controls the default column property for multi-line text."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mtextcolumn-system-variable")
)

(
  :name "MTEXTDETECTSPACE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Space detection for creating lists in mtext editor: Creates formatted list items, when the space bar is pressed after a letter, number or symbol, in mtext editor mode."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mtextdetectspace-system-variable")
)

(
  :name "MTEXTED"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Multiline text editor: Controls the text editors to use for multiline text entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mtexted-system-variable")
)

(
  :name "MTEXTFIXED"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Multiline text fixed: Controls whether the application zooms, rotates and/or pans the view to fit the multiline text to be edited."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mtextfixed-system-variable")
)

(
  :name "MTEXTTOOLBAR"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "MText Formatting toolbar: Controls if the formatting toolbar is displayed when multiline text is edited."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mtexttoolbar-system-variable")
)

(
  :name "MTFLAGS"
  :type :short
  :default 3015
  :read-only NIL
  :range (0 4095)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Multi-Threading Flags: Bit flags for parallel processing of display and loading."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mtflags-system-variable")
)

(
  :name "MULTISELECTANGULARTOLERANCE"
  :type :real
  :default 3.0d0
  :read-only NIL
  :range (0 90)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "BimMultiSelect angular tolerance: Controls the maximum angle between two linear solids axes, for these solids to still be considered parallel. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/multiselectangulartolerance-system-variable")
)

(
  :name "MYDOCUMENTSPREFIX"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "MyDocuments root prefix: The path of the user documents folder."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/m/mydocumentsprefix-system-variable")
)

(
  :name "NAVVCUBEDISPLAY"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "LookFrom display: Toggles the LookFrom control on/off. The LookFrom is the navigation control, by default this appears in the top-right corner."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/n/navvcubedisplay-system-variable")
)

(
  :name "NAVVCUBELOCATION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "LookFrom location: Controls the location of the LookFrom control."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/n/navvcubelocation-system-variable")
)

(
  :name "NAVVCUBEOPACITY"
  :type :short
  :default 50
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "LookFrom opacity: Controls the opacity of the LookFrom control while inactive."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/n/navvcubeopacity-system-variable")
)

(
  :name "NAVVCUBEORIENT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "LookFrom orientation: Controls if the LookFrom control reflects the current WCS (World Coordinate System) or UCS (User Coordinate System)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/n/navvcubeorient-system-variable")
)

(
  :name "NEARESTDISTANCE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Nearest Distance: Controls nearest distance dimension between a pair of selected entities. The value is stored as a bitcode using the sum of the values of all selected options. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/n/nearestdistance-system-variable")
)

(
  :name "NOMUTT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "No muttering: Suppresses text in the Command line. When on, the Command line will stop prompting all the options and actions."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/n/nomutt-system-variable")
)

(
  :name "NORTHDIRECTION"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "North direction: Controls the angle of the sun, from north, in the context of the world coordinate system (WCS)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/n/northdirection-system-variable")
)

(
  :name "OBJECTISOLATIONMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Object Isolation Mode: Controls if entities hidden with HIDEOBJECTS or ISOLATEOBJECTS commands remain hidden after a drawing is saved, closed and reopened."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/objectisolationmode-system-variable")
)

(
  :name "OBSCUREDCOLOR"
  :type :short
  :default 257
  :read-only NIL
  :range (0 257)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Obscured color: Controls the color of obscured lines. Visible only if the OBSCUREDLTYPE system variable is in use."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/obscuredcolor-system-variable")
)

(
  :name "OBSCUREDLTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 11)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Obscured linetype: Controls the linetype of obscured lines. Unlike regular linetypes, obscured linetypes are zoom level independent."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/obscuredltype-system-variable")
)

(
  :name "OFFSETDIST"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Offset distance: Stores the last distance used for the OFFSET command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/offsetdist-system-variable")
)

(
  :name "OFFSETERASE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Offset erase: Erases the source entity for the OFFSET command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/offseterase-system-variable")
)

(
  :name "OFFSETGAPTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Offset gap type: Controls how possible gaps, in parallel copies of closed polylines, are filled."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/offsetgaptype-system-variable")
)

(
  :name "OLEFRAME"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "OLE frame: Controls the display of a frame around an OLE object, if the FRAME system variable is set to Use individual system variables (3)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/oleframe-system-variable")
)

(
  :name "OLEHIDE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "OLE hide: Controls the visibility of OLE objects for both screen display and plotting."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/olehide-system-variable")
)

(
  :name "OLEQUALITY"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "OLE quality: Controls the default plot quality of OLE entities. When set to Automatically Select (3), the quality level is assigned automatically depending on the entity type (for example, photographs are set to High )."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/olequality-system-variable")
)

(
  :name "OLESTARTUP"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "OLE startup: Loads the OLE entity source when plotting."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/olestartup-system-variable")
)

(
  :name "OPMSTATE"
  :type :short
  :default 1
  :read-only T
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Properties panel state: Properties panel status."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/opmstate-system-variable")
)

(
  :name "ORBITAUTOTARGET"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Orbit Auto Target: Controls the behavior of the RTROT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/orbitautotarget-system-variable")
)

(
  :name "ORTHOMODE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Orthogonal mode: Constrains cursor movement perpendicularly. When on the cursor can only move horizontally or vertically, relative to the current UCS and grid rotation angle. See also the SNAPANG system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/orthomode-system-variable")
)

(
  :name "OSMODE"
  :type :short
  :default 4135
  :read-only NIL
  :range (0 32767)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Entity snap mode: Controls the 2D entity snap types."
  :coupled ("osnap")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/osmode-system-variable")
)

(
  :name "OSNAPCOORD"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Entity snap coordinates: Controls if entity snaps override manually entered coordinates."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/osnapcoord-system-variable")
)

(
  :name "OSNAPZ"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ignore entity snap elevation: Overrides the Z coordinate of an entity snap with the current ELEVATION system variable value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/osnapz-system-variable")
)

(
  :name "OSOPTIONS"
  :type :short
  :default 7
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Entity snap options: Suppresses entity snaps on certain entity types."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/osoptions-system-variable")
)

(
  :name "OVERKILLLAYER"
  :type :string
  :default "Duplicate Entities"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Duplicate Entities Layer: The layer that entities are moved to during the OVERKILL command - the Move duplicates to Duplicate Entities layer option. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/o/overkilllayer-system-variable")
)

(
  :name "PANBUFFER"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Pan buffer: Enables faster panning, particularly in complex drawings. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/panbuffer-system-variable")
)

(
  :name "PANELBUTTONSIZE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Panel control button size: Controls the size of the icons used for panels. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/panelbuttonsize-system-variable")
)

(
  :name "PAPERUPDATE"
  :type :integer
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Paper update: Controls paper size adaption when printers are switched in the Print dialog box. If Off: does not update the paper size, preserving the paper size currently selected. If the printer has no close match, the size will be displayed as Previous paper size . On print, your confirmation is required before substitution with default values. If On: updates the paper size, using the default paper size of the selected printer."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/paperupdate-system-variable")
)

(
  :name "PARAMETERCOPYMODE"
  :type :short
  :default 3
  :read-only NIL
  :range (0 4)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Parameter copy mode: Controls how constraints and related parameters are copied with the COPY command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/parametercopymode-system-variable")
)

(
  :name "PARAMETERMATCHMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Match Parametric Blocks by parameters: The option is not stored in registry, however for some designated blocks it is known that the individual copy is required for each separate insert. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/parametermatchmode-system-variable")
)

(
  :name "PARAMETRICBLOCKS2DPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Parametric blocks 2D directory path: The file path(s) for user created 2D Parametric Blocks files. Separate file paths with semicolons (;). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/parametricblocks2dpath-system-variable")
)

(
  :name "PARAMETRIZECONNECTIONS"
  :type :integer
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Parametrize Connections: Controls if constraints connect components for the BMCONVERT, BMCONNECT and BMINSERT (SMART insert option) commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/parametrizeconnections-system-variable")
)

(
  :name "PBLOCKREFERENCEOPERATIONSVISUALIZATION"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Visualize parametric operations on block references: Enables the visualization of the parametric operations' information when hovering the cursor over parametric block references. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pblockreferenceoperationsvisualization-system-variable")
)

(
  :name "PDFANIMATIONFPS"
  :type :short
  :default 24
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Frames per second: Controls the number of frames per second for an animation. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfanimationfps-system-variable")
)

(
  :name "PDFCACHE"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF cache: Enables/disables the PDF cache. A multi-resolution persistent image cache is used to display attached Pdf underlays, enabling (very) fast zoom and pan operations. The highest cached resolution is 5000 x 5000 pixels. Still, when zooming in very close, the display of the Pdf underlay will become pixelated. So a hybrid modus can be used which switches to real-time generation of crisp Pdf underlay display when zooming in very close. The initial generation of the ima..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfcache-system-variable")
)

(
  :name "PDFCREATEBOOKMARKS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Create bookmarks: Create bookmarks for PDF exports. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfcreatebookmarks-system-variable")
)

(
  :name "PDFEMBEDDEDTTF"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Pdf embedded fonts: Embeds True Type fonts for PDF exports. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfembeddedttf-system-variable")
)

(
  :name "PDFEXPORTHYPERLINKS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Export hyperlinks: Exports entity hyperlinks for PDF exports. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfexporthyperlinks-system-variable")
)

(
  :name "PDFFRAME"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "PDF frame: Controls the visibility of PDF underlay frames, if the FRAME system variable is set to Use individual system variables (3)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfframe-system-variable")
)

(
  :name "PDFIMAGEANTIALIAS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Image anti-aliasing: Enables anti-aliasing for images that are upscaled during PDF export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimageantialias-system-variable")
)

(
  :name "PDFIMAGECOMPRESSION"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Image compression: Compresses images to JPEG during PDF export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimagecompression-system-variable")
)

(
  :name "PDFIMAGEDPI"
  :type :short
  :default 300
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Image DPI: Controls the minimal resolution for an image exported to PDF. Cannot exceed the value of the PDFVECTORRESOLUTIONDPI system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimagedpi-system-variable")
)

(
  :name "PDFIMPORTAPPLYLINEWEIGHT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Apply lineweight properties: Retains the lineweight properties of imported entities, during PDF import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportapplylineweight-system-variable")
)

(
  :name "PDFIMPORTASBLOCK"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import as block: Imports PDF files as blocks. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportasblock-system-variable")
)

(
  :name "PDFIMPORTCHARSPACEFACTOR"
  :type :real
  :default 0.6
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Inter-character space factor: The multiplier for the width of the space between characters in a word, used during PDF import. If the distance between the text objects in the string is less than the width of the space taken from the font metric multiplied by this factor, the text objects are combined into one word. Note: Applies only if PDFIMPORTCOMBINETEXTOBJECTS is turned on. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportcharspacefactor-system-variable")
)

(
  :name "PDFIMPORTCOMBINETEXTOBJECTS"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Combine text entities: Controls if text entities, that use the same font and are on the same line, are combined, during PDF import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportcombinetextobjects-system-variable")
)

(
  :name "PDFIMPORTCONVERTSOLIDSTOHATCHES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Convert solid fills to hatches: Converts 2D solid entities into solid-filled hatches, during PDF import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportconvertsolidstohatches-system-variable")
)

(
  :name "PDFIMPORTIMAGEPATH"
  :type :string
  :default "PDF Images"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Raster Images Folder: The file path used to save images, during PDF import, absolute or relative. If relative, the PDF image path is relative to the folder of the current drawing file. If empty, the folder of the current drawing is used, if the drawing has not yet been saved the images will be saved in the same folder as the imported PDF."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportimagepath-system-variable")
)

(
  :name "PDFIMPORTJOINLINEANDARCSEGMENTS"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Join line and arc segments: Joins continuous segments into a polyline, where possible, during PDF import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportjoinlineandarcsegments-system-variable")
)

(
  :name "PDFIMPORTLAYERSUSETYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Layers: Controls layers during PDF import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportlayersusetype-system-variable")
)

(
  :name "PDFIMPORTRASTERIMAGES"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Raster Images: Extracts images to PNG files and attaches these to the current drawing, during PDF import. These images are stored in the folder set in the PDFIMPORTIMAGEPATH system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportrasterimages-system-variable")
)

(
  :name "PDFIMPORTSOLIDFILLS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Solid fills: Ignore or import solid-filled areas during PDF import, if the information is in the PDF. Solid-filled areas include solid-filled hatches, 2D solids, wipeout entities, wide polylines, and triangular arrowheads. Note: Solid-filled hatches are assigned a 50% transparency. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportsolidfills-system-variable")
)

(
  :name "PDFIMPORTSPACEFACTOR"
  :type :real
  :default 1.5
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Inter-word space factor: Controls the multiplier for the width of the space between words on a line. If the distance between the text objects in the string is greater than the width of the space between characters in a word (specified by the PDFIMPORTCHARSPACEFACTOR system variable), but less than the width of the space taken from the font metrics multiplied by this factor, the text objects are combined into one word. Note: Applies only if PDFIMPORTCOMBINETEXTOBJECTS is tu..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportspacefactor-system-variable")
)

(
  :name "PDFIMPORTTRUETYPETEXT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "TrueType text: Import TrueType text as a TrueType text, the textstyle named is inherited from the font, during PDF import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimporttruetypetext-system-variable")
)

(
  :name "PDFIMPORTTRUETYPETEXTASGEOMETRY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import True Type text as geometry: Imports True Type Text as geometry, during PDF import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimporttruetypetextasgeometry-system-variable")
)

(
  :name "PDFIMPORTUSECLIPPING"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Apply clipping: Clips entities, during PDF import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportuseclipping-system-variable")
)

(
  :name "PDFIMPORTUSEGEOMETRYOPTIMIZATION"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Import geometry with optimization: Optimizes geometry, during PDF import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportusegeometryoptimization-system-variable")
)

(
  :name "PDFIMPORTUSEIMAGECLIPPING"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Clip images: Clips images during a PDF import. The clipped part images becomes transparent. Note: Applies only if PDFIMPORTUSECLIPPING is on (1). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportuseimageclipping-system-variable")
)

(
  :name "PDFIMPORTUSEPAGEBORDERCLIPPING"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Apply clipping at page border: Clips entities at the page border during, PDF import. Note: Applies only if the PDFIMPORTUSECLIPPING system variable is on (1). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportusepageborderclipping-system-variable")
)

(
  :name "PDFIMPORTVECTORGEOMETRY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Vector geometry: Imports vector geometry during PDF import. If on, linear paths and Beziér curves are imported as polylines within a tolerance. Curves that resemble arcs, circles, and ellipses are also converted. Solid-filled areas are imported as 2D solids or solid-filled hatches. Patterned hatches are imported as many separate entities. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfimportvectorgeometry-system-variable")
)

(
  :name "PDFLAYERSSETTING"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF layer support: Controls the way layers are exported to PDF. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdflayerssetting-system-variable")
)

(
  :name "PDFLAYOUTSTOEXPORT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF layouts to export: Controls the layout(s) exported to PDF (paper space). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdflayoutstoexport-system-variable")
)

(
  :name "PDFMERGECONTROL"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF Merge Control: Controls the appearance of lines that cross in PDF exports. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfmergecontrol-system-variable")
)

(
  :name "PDFNOTIFY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF notify: Displays a warning, when a drawing is opened, if there are missing PDFs. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfnotify-system-variable")
)

(
  :name "PDFOPENINVIEWER"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Open in viewer: Open result file in system default PDF viewer. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfopeninviewer-system-variable")
)

(
  :name "PDFOSNAP"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "PDF entity snap: Enables entity snap for PDF underlay files."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfosnap-system-variable")
)

(
  :name "PDFPAPERHEIGHT"
  :type :short
  :default 297
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF override - paper height: Paper height for PDF export, in millimeters, if the PDFPAPERSIZEOVERRIDE system variable is on (1). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfpaperheight-system-variable")
)

(
  :name "PDFPAPERSIZEOVERRIDE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF papersize override: Enables papersize override for PDF export. If On, the papersize as defined in the BricsCAD Print settings is overridden. The papersize width and height defined by PDFPAPERWIDTH and PDFPAPERHEIGHT are used instead. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfpapersizeoverride-system-variable")
)

(
  :name "PDFPAPERWIDTH"
  :type :short
  :default 210
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF override - paper width: Paper width for PDF export, in millimeters, if the PDFPAPERSIZEOVERRIDE system variable is on (1). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfpaperwidth-system-variable")
)

(
  :name "PDFPDFA"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF/A format support: Controls archived PDF support. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfpdfa-system-variable")
)

(
  :name "PDFPRCCOMPRESSION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PRC Compression: Controls the compression of PRC 3D data (3D PDF). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfprccompression-system-variable")
)

(
  :name "PDFPRCEXPORT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PRC Export Mode: PRC mode for the export of PRC 3D data (3D PDFs). Export as BREP is an experimental mode which may work incorrectly. We recommend using Export as Mesh mode. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfprcexport-system-variable")
)

(
  :name "PDFPRCPROJECTION"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PRC Projection: Controls the projection type for PRC 3D data (3D PDF). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfprcprojection-system-variable")
)

(
  :name "PDFPRCVIEWMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PRC View mode: Controls how 2D entities and 3D entities are exported for PRC PDFs (3D PDFs). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfprcviewmode-system-variable")
)

(
  :name "PDFSHXTEXTASGEOMETRY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF SHX text as geometry: Converts SHX font text to geometry for PDF exports. This might be necessary if the receiving party does not have the same SHX fonts on their computer. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfshxtextasgeometry-system-variable")
)

(
  :name "PDFSIMPLEGEOMOPTIMIZATION"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Pdf simple geometry optimization: Simplifies geometry for PDF exports (merges separate line segments to one polyline and uses Bezier curve control points). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfsimplegeomoptimization-system-variable")
)

(
  :name "PDFTTFTEXTASGEOMETRY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF TTF text as geometry: Converts True Type font text to geometry for PDF exports. This is useful for when the TTF files are covered by a license that prohibits sharing, or you want to make it harder to extract text. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfttftextasgeometry-system-variable")
)

(
  :name "PDFUSEPLOTSTYLES"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Use PDF plotstyles: Enables plotstyles for PDF exports. If On, the plotstyle of the layout controls the color and lineweight in the PDF export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfuseplotstyles-system-variable")
)

(
  :name "PDFVECTORRESOLUTIONDPI"
  :type :short
  :default 2400
  :read-only NIL
  :range (72 40000)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Vector Resolution DPI: Resolution of vector graphics for PDF export from model space. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfvectorresolutiondpi-system-variable")
)

(
  :name "PDFZOOMTOEXTENTSMODE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "PDF zoom to extents mode: Scales the layout geometry of papersize layouts for PDF exports. If switched off, uses the scale and papersize from the pagesetup data. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdfzoomtoextentsmode-system-variable")
)

(
  :name "PDMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 100)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Point display mode: Controls the display style for point entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdmode-system-variable")
)

(
  :name "PDSIZE"
  :type :real
  :default 0.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Point display size: Controls the display size for point entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pdsize-system-variable")
)

(
  :name "PEDITACCEPT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polyline edit accept: Displays a warning, when non-polylines are selected during the PEDIT command. When suppressed, the selected entity is automatically converted to a polyline."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/peditaccept-system-variable")
)

(
  :name "PELLIPSE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polyline ellipse: Controls the entity type created with the ELLIPSE command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pellipse-system-variable")
)

(
  :name "PERIMETER"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Last perimeter: The last perimeter calculated by the AREA, LIST, or DBLIST commands."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/perimeter-system-variable")
)

(
  :name "PERSPECTIVE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Perspective: Turns on perspective view for the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/perspective-system-variable")
)

(
  :name "PFACEVMAX"
  :type :short
  :default 4
  :read-only T
  :range (3 NIL)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polyface mesh maximum vertices: The maximum number of vertices for each face."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pfacevmax-system-variable")
)

(
  :name "PICKADD"
  :type :integer
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Pick add: Controls how the Shift key selects entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pickadd-system-variable")
)

(
  :name "PICKAUTO"
  :type :short
  :default 5
  :read-only NIL
  :range (-7 7)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Selection window behavior: Controls the selection behavior - window and lasso - used to select multiple entities at the same time. See also the PICKDRAG system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pickauto-system-variable")
)

(
  :name "PICKBOX"
  :type :short
  :default 4
  :read-only NIL
  :range (0 50)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Pick box: Controls the selection area size around the cursor, in pixels. Values between 0 and 50 are accepted. Note: If you select an entity by clicking, the Pick Box must touch or overlap the entity."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pickbox-system-variable")
)

(
  :name "PICKDRAG"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Pick drag: Controls the window selection behavior used to select multiple entities at the same time. See also the PICKAUTO system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pickdrag-system-variable")
)

(
  :name "PICKFIRST"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Pick first: Makes it possible to select entities first, then issue a command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pickfirst-system-variable")
)

(
  :name "PICKSTYLE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Pick style: Controls the selection of groups and associative hatches. Use Ctrl+H to toggle this system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pickstyle-except-os-x-system-variable")
)

(
  :name "PICTUREEXPORTSCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Picture format export scale factor: Controls the output resolution scale for WMF, EMF or BMP exports. Used in commands EXPORT, WMFOUT, COPYCLIP, CUTCLIP and in COM/VBA function AcadDocument. The output view size is the current view size-in pixels, multiplied by this value. Trouble: Scale values of 10 or more may cause slow system response. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pictureexportscale-system-variable")
)

(
  :name "PLACESBARFOLDER1"
  :type :short
  :default 0
  :read-only NIL
  :range (0 5)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "First folder: Controls the first folder in the places bar of the nonstandard Open file dialog box (Windows only). This enables you to place shortcuts to your favorite drawing folders on your desktop or in your Favorites folder. See also the USESTANDARDOPENFILEDIALOG system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/placesbarfolder1-system-variable")
)

(
  :name "PLACESBARFOLDER2"
  :type :short
  :default 1
  :read-only NIL
  :range (0 5)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Second folder: Controls the second folder in the places bar of the nonstandard Open file dialog box (Windows platform only). This enables you to place shortcuts to your favorite drawing folders on your desktop or in your Favorites folder. See also the USESTANDARDOPENFILEDIALOG system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/placesbarfolder2-system-variable")
)

(
  :name "PLACESBARFOLDER3"
  :type :short
  :default 3
  :read-only NIL
  :range (0 5)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Third folder: Controls the third folder in the places bar of the nonstandard Open file dialog box (Windows platform only). This enables you to place shortcuts to your favorite drawing folders on your desktop or in your Favorites folder. See also the USESTANDARDOPENFILEDIALOG system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/placesbarfolder3-system-variable")
)

(
  :name "PLACESBARFOLDER4"
  :type :short
  :default 5
  :read-only NIL
  :range (0 5)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Fourth folder (Windows): Controls the fourth folder in the places bar of the nonstandard Open file dialog box (Windows platform only). This enables you to place shortcuts to your favorite drawing folders on your desktop or in your Favorites folder. See also the USESTANDARDOPENFILEDIALOG system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/placesbarfolder4-system-variable")
)

(
  :name "PLATFORM"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Platform: Displays the current Operating System version."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/platform-system-variable")
)

(
  :name "PLINECACHE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Polyline cache: Controls the creation of a cache of polyline vertices, when a drawing is opened. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plinecache-system-variable")
)

(
  :name "PLINECONVERTMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polyline convert mode: Controls how splines are converted to polylines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plineconvertmode-system-variable")
)

(
  :name "PLINEGEN"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polyline generation: Controls how linetype patterns are generated around 2D polyline vertices. Linetypes are normally generated from vertex to vertex (0). Polylines of which the vertices are very close together might be rendered as a continuous line, if the linetype pattern does not fit between two subsequent vertices. When set to 1, the linetype is drawn from one end of the polyline to the other end, instead of from vertex to vertex."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plinegen-system-variable")
)

(
  :name "PLINETYPE"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polyline type: Controls how polylines are created with the PLINE command and if old-format polylines are converted. It saves disk space and memory by using the optimized format."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plinetype-system-variable")
)

(
  :name "PLINEWID"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polyline width: The default width for new polyline."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plinewid-system-variable")
)

(
  :name "PLOTCFGPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Plotter configuration path: The file path used for the Plotter configuration folders. Separate file paths with semicolons (;). When printing a layout, the available paper size settings are controlled by a Plotter Configuration File. The Printer/Plotter Configuration list is composed of all printer drivers that are installed on your computer. The Printer Configuration are the files in the folder which is specified by the Plotter Configuration Path. If this is set to a large..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plotcfgpath-system-variable")
)

(
  :name "PLOTID"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Plot id (Obsolete): Obsolete, has no effect except to preserve the integrity of old scripts and LISP routines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plotid-system-variable")
)

(
  :name "PLOTOUTPUTPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Plot output path: The default file path used for the creation of plot files. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plotoutputpath-system-variable")
)

(
  :name "PLOTSTYLEPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Plot styles path: The file path used for the Plot styles folders. Separate file paths with semicolons (;). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plotstylepath-system-variable")
)

(
  :name "PLOTTER"
  :type :short
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Plotter (Obsolete): Has no effect except to preserve the integrity of older scripts and LISP routines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plotter-system-variable")
)

(
  :name "PLOTTRANSPARENCYOVERRIDE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Plot transparency override: Controls if transparencies are enabled for print."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plottransparencyoverride-system-variable")
)

(
  :name "PLQUIET"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Plot quiet: Controls if optional dialog boxes and nonfatal errors display during batch plot or when a script is run."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/plquiet-system-variable")
)

(
  :name "POINTCLOUD2DVSDISPLAY"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Toggle show/hide bounding box in 2d wireframe mode: Controls the display of a bounding box and warning message when the 2D Wireframe visual style is active and there are point clouds in the drawing. Point clouds are not displayed when the 2D Wireframe visual style is active."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloud2dvsdisplay-system-variable")
)

(
  :name "POINTCLOUDADAPTIVEDISPLAY"
  :type :integer
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Toggle adaptive vs. fixed point sizes: Uses adaptive point sizes for point cloud display. If off, uses fixed point sizes. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloudadaptivedisplay-system-variable")
)

(
  :name "POINTCLOUDBOUNDARY"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Show/hide point cloud extent boundary: Controls how the point cloud boundary is displayed."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloudboundary-system-variable")
)

(
  :name "POINTCLOUDCACHEFOLDER"
  :type :string
  :default "C:\\Users\\%username%\\AppData\\Roaming\\Bricsys\\BricsCAD\\ V26 x64\\en_US\\PointCloudCache"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Disk cache folder: The file path(s) used to store point cloud cache files. Separate file paths with semicolons (;). Note: Multiple paths are supported. The first one is used for adding new cached or preprocessed data. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloudcachefolder-system-variable")
)

(
  :name "POINTCLOUDDOLLHOUSE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Enable/disable dollhouse render mode: When true, the interior of the point cloud is visible because points with normal vector pointing away from the viewpoint are not shown. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointclouddollhouse-system-variable")
)

(
  :name "POINTCLOUDEYEDOMELIGHTING"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Eye dome lighting strength: Eye dome lighting strength. If 0, eye dome lighting is disabled. Values between 0 and 10 are accepted (default 1). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloudeyedomelighting-system-variable")
)

(
  :name "POINTCLOUDGAPFILLING"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Gap filling size: Gap between points to fill in pixels. If 0, gap filling is disabled. Values between 0 and 10 are accepted (default 0). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloudgapfilling-system-variable")
)

(
  :name "POINTCLOUDHSPC"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "HSPC mode: Toggles the format used to preprocess point clouds HSPC/BCAD. Note: The HSPC file format (Hexagon Smart Point Cloud) is a proprietary format developed by Hexagon VCH (Visual Computing Hub). Using this format enables storing per point information which will be used to have more point cloud functionalities (in the future). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloudhspc-system-variable")
)

(
  :name "POINTCLOUDIGNOREGEOTAGS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Ignore geo tags in source data (deprecated!): Ignores geo tags in source data. The setting is kept for v25 but has no effect. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloudignoregeotags-system-variable")
)

(
  :name "POINTCLOUDNORMALS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Normal calculation: Calculates normals during point cloud preprocessing, used to identify planar (flat surfaces) such as walls and floors. Applies if the POINTCLOUDHSPC system variable is on (1). Note: When a point cloud is structured (in other words it has bubbles), the normal vectors will be computed automatically during preprocessing. Structured point clouds already available in the cache in HSPC which have no normal vectors yet can be computed with the POINTCLOUDNORMAL..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloudnormals-system-variable")
)

(
  :name "POINTCLOUDPOINTMAX"
  :type :short
  :default 10
  :read-only NIL
  :range (1 50)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Maximum number of points displayed on screen (in millions): Maximum number of points displayed per point cloud. This is independent of the number of points in the dataset. Note: Values between 1 and 50 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloudpointmax-system-variable")
)

(
  :name "POINTCLOUDPOINTSIZE"
  :type :short
  :default 2
  :read-only NIL
  :range (1 10)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Point size: Point cloud point display size, in pixels. Values between 1 and 10 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pointcloudpointsize-system-variable")
)

(
  :name "POLARADDANG"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polar add angles: Contains a list of custom polar snap angles, if the POLARMODE system variable is set to Use additional polar tracking angles . Up to 10 angles, up to 25 characters each, separated with semicolons (;). Requires POLARMODE flag 0x04 to be set ( Use additional polar tracking angles ). The AUNITS system variable sets the format for display of angles. Unlike POLARANG, POLARADDANG angles do not result in multiples of their values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/polaraddang-system-variable")
)

(
  :name "POLARANG"
  :type :real
  :default 90.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polar angle: Controls the polar angle increments, in degrees."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/polarang-system-variable")
)

(
  :name "POLARDIST"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polar distance: Controls the snap increment for polar snap (if the SNAPTYPE system variable is set to Polar snap )."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/polardist-system-variable")
)

(
  :name "POLARMODE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polar mode: Controls entity snap tracking and polar snap tracking."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/polarmode-system-variable")
)

(
  :name "POLYSIDES"
  :type :short
  :default 4
  :read-only NIL
  :range (3 1024)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polygon sides: The number of sides last used with the POLYGON command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/polysides-system-variable")
)

(
  :name "POPERATIONSCOLOR"
  :type :string
  :default "RGB:238,173,60"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Parametric operations color: Controls the color of the parametric operations' geometry. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/poperationscolor-system-variable")
)

(
  :name "POPUPS"
  :type :integer
  :default 1
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Popups: Shows the status of the currently configured display driver."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/popups-system-variable")
)

(
  :name "PREVIEWDELAY"
  :type :short
  :default 30
  :read-only NIL
  :range (0 1000)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Delay to preview selection: Controls the delay, before entities are highlighted on hover, in milliseconds. Values between 0 and 1000 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/previewdelay-system-variable")
)

(
  :name "PREVIEWEFFECT"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Selection preview effect: Controls how a selection preview is displayed (Not yet supported)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/previeweffect-system-variable")
)

(
  :name "PREVIEWFILTER"
  :type :short
  :default 3
  :read-only NIL
  :range (0 63)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Selection filter: Controls the entity types that can not be selected."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/previewfilter-system-variable")
)

(
  :name "PREVIEWTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Preview type: Controls which view is used for drawing preview thumbnails (Not yet supported)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/previewtype-system-variable")
)

(
  :name "PREVIEWWNDINOPENDLG"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Preview window in open dialog: Shows a file preview in the Open dialog box. Can be set from the dialog (checkbox). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/previewwndinopendlg-system-variable")
)

(
  :name "PRINTFILE"
  :type :string
  :default "."
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Print file: Alternate name for plot files. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/printfile-system-variable")
)

(
  :name "PRINTPDFPREVIEW"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Print As PDF Preview: Controls if the Print As PDF preview uses the system default PDF viewer or an internal program window. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/printpdfpreview-system-variable")
)

(
  :name "PRODUCT"
  :type :string
  :default "BricsCAD"
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Product: Displays the product name."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/product-system-variable")
)

(
  :name "PROFILEOFFSETBEHAVIOR"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Profile offset behavior: Controls the position of a solid or its axis, when the profile offset is changed. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/profileoffsetbehavior-system-variable")
)

(
  :name "PROGBAR"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Progress bar: Controls the display of the progress bar. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/progbar-system-variable")
)

(
  :name "PROGRAM"
  :type :string
  :default "BRICSCAD"
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Program: Displays the program name."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/program-system-variable")
)

(
  :name "PROJECTAWARE"
  :type :integer
  :default (:drawing)
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "2026+" :bricscad nil)
  :vendor :autocad
  :divergence "BricsCAD has no PROJECTAWARE sysvar (no Autodesk Docs project model)."
  :summary "Informs the user or developer of the project path state of the current drawing in Autodesk Docs Connected Support Files."
  :coupled ()
  :source (:autocad "https://help.autodesk.com/view/ACD/2026/ENU/?guid=GUID-AE3E169F-556E-41A5-A9D8-7A97A797B0ED" :bricscad NIL)
)

(
  :name "PROJECTIONTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Drawing view projection type: Switches between first and third angle projection types. These angle projections are a way to represent 3D entities in 2D drawing views. These projection types will show the same views but the difference between the two types is the position of these views (top, right, left, bottom). See Generated drawing views to learn more about it."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/projectiontype-system-variable")
)

(
  :name "PROJECTLOCATIONVISIBILITY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Project location marker visibility: Controls the visibility of the Project location marker. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/projectlocationvisibility-system-variable")
)

(
  :name "PROJECTNAME"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Project name: The project name of the current drawing. Project names help to keep track of Xrefs and images easier by assigning additional support paths specific to the project only."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/projectname-system-variable")
)

(
  :name "PROJECTSEARCHPATHS"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Project search paths: Stores a list of project names, each with a list of file paths to search. If external references and images are not found in the saved path, the project search paths are used to find the external references and images. Separate file paths with semicolons (;). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/projectsearchpaths-system-variable")
)

(
  :name "PROJMODE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Projection mode: Controls the projection mode for the TRIM and EXTEND commands. If the cutting entity is not in the same plane as the entity you want to TRIM/EXTEND, this system variable defines how the intersection is to be calculated."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/projmode-system-variable")
)

(
  :name "PROMPTMENU"
  :type :short
  :default 0
  :read-only NIL
  :range (0 5)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Prompt menu: Controls the command prompt menu dialog. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/promptmenu-system-variable")
)

(
  :name "PROMPTMENUFLAGS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 7)
  :bitcoded T
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Prompt menu flags: Controls the behavior of the prompt menu. See the PROMPTMENU system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/promptmenuflags-system-variable")
)

(
  :name "PROMPTOPTIONFORMAT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 4)
  :bitcoded T
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Prompt option format: Controls how command options are displayed in the Command line. A command option has a keyword, a description and a shortcut. The shortcut is the keyword without lower case characters (a-z). For example, the third option of the CIRCLE command: Keyword = TanTanRad Description = Tangent-Tangent-Radius Shortcut = TTR Note: The PROMPTOPTIONTRANSLATEKEYWORDS system variable controls whether translations of command option keywords are loaded or not. If disa..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/promptoptionformat-system-variable")
)

(
  :name "PROMPTOPTIONTRANSLATEKEYWORDS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Prompt option translate keywords: Loads translated command option keywords. If disabled, English keywords are used and global shortcuts can be used without an underscore. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/promptoptiontranslatekeywords-system-variable")
)

(
  :name "PROPAGATESEARCHSPACE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Search space: Asks for a search space during the BIMPROPAGATE command. Limits the locations and entity can be propagated to. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/propagatesearchspace-system-variable")
)

(
  :name "PROPAGATETOLERANCE"
  :type :real
  :default 0.00001
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Position tolerance: The position tolerance used for the BIMPROPAGATE command, in drawing units. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/propagatetolerance-system-variable")
)

(
  :name "PROPERTYPREVIEW"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Property Preview: Shows property changes, on hover of combo box list values, in Properties panel, for selected entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/propertypreview-system-variable")
)

(
  :name "PROPERTYPREVIEWDELAY"
  :type :short
  :default 500
  :read-only NIL
  :range (100 10000)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Property Preview Delay: Controls the delay before property changes show, on hover of combo box list values in Properties panel, in milliseconds. Applies if the PROPERTYPREVIEW system variable is on (1). Values between 100 and 10000 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/propertypreviewdelay-system-variable")
)

(
  :name "PROPERTYPREVIEWOBJLIMIT"
  :type :short
  :default 500
  :read-only NIL
  :range (1 30000)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Property Preview Object Limit: Controls the maximum number of entities that can support hover properties. Values between 1 and 30,000 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/propertypreviewobjlimit-system-variable")
)

(
  :name "PROPOBJLIMIT"
  :type :integer
  :default 1000
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Properties entity limit: Controls the limit of entities displayed in the Properties panel to improve performance. Values between 0 and 100000 are accepted. A value of 0 turns off the limitation."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/propobjlimit-system-variable")
)

(
  :name "PROPPREVTIMEOUT"
  :type :short
  :default 1
  :read-only NIL
  :range (1 5)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Property Preview Timeout: Controls the delay before hover properties display, in seconds. Values between 1 and 5 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/propprevtimeout-system-variable")
)

(
  :name "PROPUNITS"
  :type :short
  :default 47
  :read-only NIL
  :range (0 255)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Property units: Automatically formats length, area, volume, dimension and mass units, in panels and input boxes. For example, 2000mm will be displayed as 2m. Applies if the INSUNITS system variable is active. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/propunits-system-variable")
)

(
  :name "PROXYGRAPHICS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Proxy graphics: Saves images of proxy entities to the drawing. If switched off, a bounding box displays instead."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxygraphics-system-variable")
)

(
  :name "PROXYNOTICE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Proxy notice: Displays a notice when you open a drawing containing custom entities created by an application that is not present."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxynotice-system-variable")
)

(
  :name "PROXYSERVERENABLED"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Proxy server: BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxyserverenabled-system-variable")
)

(
  :name "PROXYSERVERHTTP"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "HTTP server: The address of proxy server for HTTP protocol. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxyserverhttp-system-variable")
)

(
  :name "PROXYSERVERHTTPPORT"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "HTTP server port: The port number of proxy server for HTTP protocol. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxyserverhttpport-system-variable")
)

(
  :name "PROXYSERVERHTTPS"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "HTTPS server: The address of proxy server for HTTPS protocol. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxyserverhttps-system-variable")
)

(
  :name "PROXYSERVERHTTPSPORT"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "HTTPS server port: The port number of proxy server for HTTPS protocol. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxyserverhttpsport-system-variable")
)

(
  :name "PROXYSERVERPASSWORD"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "User password: The user password to log in to proxy server. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxyserverpassword-system-variable")
)

(
  :name "PROXYSERVERUSER"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "User name: The user name to log in to proxy server. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxyserveruser-system-variable")
)

(
  :name "PROXYSHOW"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Proxy show: Controls how proxy entities display in a drawing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxyshow-system-variable")
)

(
  :name "PROXYWEBSEARCH"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Proxy web search: Toggles the check for entity enablers."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/proxywebsearch-system-variable")
)

(
  :name "PSLTSCALE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Paper space linetype scale: Controls the linetype scaling in paper space. If Viewport scaling governs linetype scaling is active, the length of the dashes is based on paper space drawing units - linetypes display identically, in all viewports, even if scaled differently. A REGEN is required."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/psltscale-system-variable")
)

(
  :name "PSOLHEIGHT"
  :type :real
  :default 80.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polysolid height: Controls the default height, in drawing units, for the POLYSOLID command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/psolheight-system-variable")
)

(
  :name "PSOLWIDTH"
  :type :real
  :default 5.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Polysolid width: Controls the default width, in drawing units, for the POLYSOLID command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/psolwidth-system-variable")
)

(
  :name "PSTYLEMODE"
  :type :short
  :default 1
  :read-only T
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Plot style mode: The plot style mode of the current drawing. To convert the current drawing to use named or color-dependent plot styles, use CONVERTPSTYLES."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pstylemode-system-variable")
)

(
  :name "PSTYLEPOLICY"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Plot style policy: Controls if the color of an entity is associated with its plot style. Note: If PSTYLEPOLICY is 0, the plot style for new entities is set to the default defined in DEFPLSTYLE and the plot style for new layers is set to the default defined in DEFLPLSTYLE."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pstylepolicy-system-variable")
)

(
  :name "PSVPSCALE"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Paper space viewport scale: Controls the scale multiplier for new viewports created with the VPORTS command. Note: The view scale multiplier is defined by comparing the ratio of units in paper space to the units in newly created model space viewports. The view scale multiplier you set is used with the VPORTS command. A value of 0 means the scale multiplier is Scaled to Fit."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/psvpscale-system-variable")
)

(
  :name "PUBLISHALLSHEETS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Publish all sheets: Controls how layouts are loaded to the Publish dialog box. If on, loads all layouts from all active drawings. If off, loads only the layouts from the current drawing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/publishallsheets-system-variable")
)

(
  :name "PUBLISHCOLLATE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Collate published sheets: Combines published sheets with equal output configurations into single multi-page plot job."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/publishcollate-system-variable")
)

(
  :name "PUCSBASE"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Paper space UCS base: The name of the UCS that controls the orthographic UCS in paper space."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/p/pucsbase-system-variable")
)

(
  :name "QAFLAGS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 32767)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Quality Assurance flags: Internal system variable with flags for Quality Assurance and testing. Note: This is subject to change, and not intended for regular use. Some of these options could have unpredictable or unwanted side-effects."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/qaflags-system-variable")
)

(
  :name "QTEXTMODE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Quick text mode: Controls how text entities are displayed. When On: this turns on quick text mode, rendering all text – text, mtext, attributes, dimension text, and so on—as rectangles. When Off (0): this turns off quick text mode, returning text to its normal display. This is useful when drawings contain much text, thereby slowing down the display of the drawing, but you still need to see the location of the text. The rectangles display the color of the text as well. Note..."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/qtextmode-system-variable")
)

(
  :name "QUADCOMMANDLAUNCH"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad default command launch: Controls how the first Quad command is activated. The default quad command depends on which command from the quad is used last. When 0: hover over an entity to see the quad and click on the command button to launch the command. When 1: hover over an entity to see the quad and right-click on the entity to launch the command, instead of clicking on the command button first. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadcommandlaunch-system-variable")
)

(
  :name "QUADDISPLAY"
  :type :short
  :default 3
  :read-only NIL
  :range (-15 15)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad display: Determines when to display the Quad. BricsCAD only Note: When the SELECTIONPREVIEW system variable is Off, the Display the Quad when the cursor hovers over an entity option of the QUADDISPLAY system variable is ignored, and the Quad is not displayed."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quaddisplay-system-variable")
)

(
  :name "QUADEXPANDDELAY"
  :type :short
  :default 160
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad expand delay: Controls the delay for the Quad to expand, after the cursor moves over the Quad, in milliseconds. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadexpanddelay-system-variable")
)

(
  :name "QUADEXPANDTABDELAY"
  :type :short
  :default 50
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad expand tab delay: Controls the delay for a Quad tab to expand, after the cursor moves over the Quad, in milliseconds. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadexpandtabdelay-system-variable")
)

(
  :name "QUADGOTRANSPARENT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad go transparent: Controls if the Quad goes transparent when the mouse moves away from it. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadgotransparent-system-variable")
)

(
  :name "QUADHIDEDELAY"
  :type :short
  :default 350
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad hide delay: Controls the delay before the Quad hides, when the mouse is inactive, in milliseconds. Applies to the zone set in the QUADHIDEMARGIN system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadhidedelay-system-variable")
)

(
  :name "QUADHIDEMARGIN"
  :type :short
  :default 50
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad hide margin: Controls the width of the active margin area around the Quad. As long as the mouse keeps moving inside this margin, the Quad will stay visible. The Quad will still gradually go transparent if QUADGOTRANSPARENT system variable is on. As soon as the mouse movement stops, or when the mouse is moved beyond the margin, the quad will disappear. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadhidemargin-system-variable")
)

(
  :name "QUADICONSIZE"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad icon size: Controls the Quad icon size. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadiconsize-system-variable")
)

(
  :name "QUADICONSPACE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad icon space: Controls the spacing between icons. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadiconspace-system-variable")
)

(
  :name "QUADMOSTRECENTITEMS"
  :type :short
  :default 4
  :read-only NIL
  :range (0 16)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad most recent items: Controls how many most recent items are displayed in the top bar of the Quad, remaining slots are filled by AI. Values between 0 and 16 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadmostrecentitems-system-variable")
)

(
  :name "QUADPOPUPCORNER"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad popup corner: Controls where the Quad will popup relative to the current cursor position. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadpopupcorner-system-variable")
)

(
  :name "QUADSHOWDELAY"
  :type :short
  :default 150
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad show delay: Controls the delay before the Quad shows, on hover, in milliseconds. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadshowdelay-system-variable")
)

(
  :name "QUADWIDTH"
  :type :short
  :default 6
  :read-only NIL
  :range (4 16)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Quad width: Controls the number of columns in the Quad. Values between 4 and 16 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/q/quadwidth-system-variable")
)

(
  :name "R12SAVEACCURACY"
  :type :short
  :default 8
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "R12 Save accuracy: Controls the number of segments between spline control segments or on 90 degrees elliptical arcs when saved to R12. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/r12saveaccuracy-system-variable")
)

(
  :name "R12SAVEDEVIATION"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "R12 Save deviation: Controls the deviation for ellipses and splines when saved to R12. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/r12savedeviation-system-variable")
)

(
  :name "RASTERPREVIEW"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Raster preview: Controls if preview image is saved with the drawing. This image is displayed by file managers and other programs."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rasterpreview-system-variable")
)

(
  :name "REALTIMESPEEDUP"
  :type :short
  :default 5
  :read-only NIL
  :range (0 10)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Realtime speedup: Controls the number of mouse messages that are skipped during Pan operations. Values between 0 and 10 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/realtimespeedup-system-variable")
)

(
  :name "REALWORLDSCALE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Real world scale: Renders materials with units set to real-world scale."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/realworldscale-system-variable")
)

(
  :name "RECENTFILES"
  :type :short
  :default 30
  :read-only NIL
  :range (0 60)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Recent file list max count: Controls the maximum number of files shown in the Recent Files section in the File menu (MRU's) and the Start page. Values between 0 and 60 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/recentfiles-system-variable")
)

(
  :name "RECENTPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Recent path: Most recently used file path. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/recentpath-system-variable")
)

(
  :name "REDHILITEFULL_EDGE_ALPHA"
  :type :short
  :default 100
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Edge opacity: Controls the transparency of an edge, when a whole entity is selected. Values between 0 and 100 are accepted. A value of zero means fully transparent. A value of 100 is fully opaque. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitefull_edge_alpha-system-variable")
)

(
  :name "REDHILITEFULL_EDGE_COLOR"
  :type :string
  :default "0, 122, 255 (Settings dialog) #007AFF (Command line)"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Edge color: Controls the color of an edge, when a whole entity is selected. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitefull_edge_color-system-variable")
)

(
  :name "REDHILITEFULL_EDGE_SHOWHIDDEN"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hidden edges: Displays hidden edges, when a whole entity is selected. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitefull_edge_showhidden-system-variable")
)

(
  :name "REDHILITEFULL_EDGE_SMOOTHING"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Edge smoothing: Controls if smooth (anti-aliased) lines are shown, when a whole entity is selected. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitefull_edge_smoothing-system-variable")
)

(
  :name "REDHILITEFULL_EDGE_THICKNESS"
  :type :real
  :default 2.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Edge thickness: Controls the thickness of an edge, when a whole entity is selected. Values between 0.0 and 20.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitefull_edge_thickness-system-variable")
)

(
  :name "REDHILITEFULL_FACE_ALPHA"
  :type :short
  :default 10
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Face transparency: Controls the transparency of a face when selected. Values between 0 and 100 are accepted. A value of zero means fully transparent. A value of 100 means fully opaque. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitefull_face_alpha-system-variable")
)

(
  :name "REDHILITEFULL_FACE_COLOR"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Face color: Controls the color of a face, when a whole entity is selected. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitefull_face_color-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDEDGEGLOW_ALPHA"
  :type :short
  :default 75
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Glow transparency: Controls the transparency of the glow. See also the REDHILITEPARTIAL_SELECTEDEDGE_SHOWGLOW system variable. Values between 0 and 100 are accepted. A value of zero means fully transparent. A value of 100 is fully opaque. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectededgeglow_alpha-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDEDGEGLOW_COLOR"
  :type :string
  :default "White (Settings dialog) #FFFFFF (Command line)"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Glow color: Controls the color of the glow effect on an edge, when selected. See also the REDHILITEPARTIAL_SELECTEDEDGE_SHOWGLOW system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectededgeglow_color-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDEDGEGLOW_SMOOTHING"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Glow smoothing: Displays smooth (anti-aliased) lines for the glow effect on an edge, when selected. See also the REDHILITEPARTIAL_SELECTEDEDGE_SHOWGLOW system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectededgeglow_smoothing-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDEDGEGLOW_THICKNESS"
  :type :real
  :default 3.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Glow thickness: Controls the thickness of the glow effect on an edge, when selected, in pixels. See also the REDHILITEPARTIAL_SELECTEDEDGE_SHOWGLOW system variable. Values between 0.0 and 20.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectededgeglow_thickness-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDEDGE_ALPHA"
  :type :short
  :default 100
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Edge opacity: Controls the transparency of an edge, when selected. Values between 0 and 100 are accepted. 0 is fully transparent. 100 is fully opaque. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectededge_alpha-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDEDGE_COLOR"
  :type :string
  :default "255, 128, 0 (Settings dialog) #FF8000 (Command line)"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Edge color: Controls the color of an edge, when selected. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectededge_color-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDEDGE_SHOWGLOW"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Glow: Toggles a glow effect on an edge, when selected. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectededge_showglow-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDEDGE_SMOOTHING"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Edge smoothing: Displays smooth (anti-aliased) lines when, when selected. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectededge_smoothing-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDEDGE_THICKNESS"
  :type :real
  :default 2.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Edge thickness: Controls the thickness of an edge, when selected, in pixels. Values between 0.0 and 20.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectededge_thickness-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDFACE_ALPHA"
  :type :short
  :default 10
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Face opacity: Controls the transparency of a face, when selected. Values between 0 and 100 are accepted. A value of zero means fully transparent. A value of 100 is fully opaque. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectedface_alpha-system-variable")
)

(
  :name "REDHILITEPARTIAL_SELECTEDFACE_COLOR"
  :type :string
  :default "#007AFF"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Face color: Controls the color of a face, when selected. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_selectedface_color-system-variable")
)

(
  :name "REDHILITEPARTIAL_UNSELECTEDEDGE_SHOWHIDDEN"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hidden edges: Controls if hidden edges are be displayed on selection. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilitepartial_unselectededge_showhidden-system-variable")
)

(
  :name "REDHILITE_DUCSLOCKED_FACE_ALPHA"
  :type :short
  :default 25
  :read-only NIL
  :range (25 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Face opacity: Controls the transparency of a selected face. Values between 0 and 100 are accepted. A value of zero means fully transparent. A value of 100 is fully opaque. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilite_ducslocked_face_alpha-system-variable")
)

(
  :name "REDHILITE_DUCSLOCKED_FACE_COLOR"
  :type :string
  :default "#007AFF"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Face color: Controls the highlight color of a Dynamic UCS locked face. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilite_ducslocked_face_color-system-variable")
)

(
  :name "REDHILITE_HIDDENEDGE_ALPHA"
  :type :short
  :default 50
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Edge opacity: Controls the transparency hidden edges, when a whole entity is selected, if the REDHILITEFULL_EDGE_SHOWHIDDEN system variable is on (1). Values between 0 and 100 are accepted. A value of zero means fully transparent. A value of 100 is fully opaque. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilite_hiddenedge_alpha-system-variable")
)

(
  :name "REDHILITE_HIDDENEDGE_COLOR"
  :type :string
  :default "White (Settings dialog) #FFFFFF (Command line)"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hidden edge color: Controls the color of hidden edges, when a whole entity is selected, if the REDHILITEFULL_EDGE_SHOWHIDDEN system variable is on (1). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redhilite_hiddenedge_color-system-variable")
)

(
  :name "REDSDKLINESMOOTHING"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Line smoothing: Enables line smoothing for 3D rendering modes. Note: It has no effect if anti-aliasing is on. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/redsdklinesmoothing-system-variable")
)

(
  :name "REDUCELENGTHTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Reduce Length Type: Sets default flow fitting reduce length type. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/reducelengthtype-system-variable")
)

(
  :name "REDUCELENGTHVALUE"
  :type :real
  :default 0.5
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Reduce Length Value: Sets default flow fitting reduce length value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/reducelengthvalue-system-variable")
)

(
  :name "REFEDITLOCKNOTINWORKSET"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Refedit lock: Locks entities that are not in the XRef, when in Reference Edit mode (REFEDIT). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/refeditlocknotinworkset-system-variable")
)

(
  :name "REFEDITNAME"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Refedit name: The name of the XRef currently being edited."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/refeditname-system-variable")
)

(
  :name "REFPATHTYPE"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Default path type of reference files: Controls if reference files are attached using full, relative or no paths, when they are attached for the first time."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/refpathtype-system-variable")
)

(
  :name "REGENMODE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Regeneration mode: Toggles automatic regeneration on/off. See also the REGENAUTO command. BricsCAD will regenerate the display automatically when REGENMODE is On, but in a few cases a forced regeneration of the drawing might be necessary. This is done by the REGEN command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/regenmode-system-variable")
)

(
  :name "REGEXPAND"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Registry paths expanding type: Controls the types of paths stored to a registry (absolute or expandable). Note: A re-start is required. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/regexpand-system-variable")
)

(
  :name "REMEMBERFOLDERS"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Remember folders: The file path used for the standard file selection dialog boxes. When 0: When you start the program by double-clicking a shortcut icon, if a Start In path is specified for the icon, that path is used as the default for all standard file selection dialog boxes. When 1: The default path in each standard file selection dialog box is the last path used in that dialog box. The Start In folder specified for the shortcut icon is not used."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rememberfolders-system-variable")
)

(
  :name "RENDERCOMPOSITIONMATERIAL"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Render Composition Material: Renders the materials of compositions and their plies. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rendercompositionmaterial-system-variable")
)

(
  :name "RENDERMATERIALDOWNLOAD"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Download missing resources for render materials: Automatically downloads missing render materials resources. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rendermaterialdownload-system-variable")
)

(
  :name "RENDERMATERIALSPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Render materials directory path: The file path(s) for user created render material files. Separate file paths with semicolons (;). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rendermaterialspath-system-variable")
)

(
  :name "RENDERUSINGHARDWARE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Render using hardware: Controls if hardware is used to render. Switch this off if there are problems caused by the graphics card or driver. A restart may be required. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/renderusinghardware-system-variable")
)

(
  :name "REPORTPANELMODE"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Report panel mode: Controls the look of the Report panel. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/reportpanelmode-system-variable")
)

(
  :name "RESTORECONNECTIONS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Restore Connections: Restores structural connections after commands."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/restoreconnections-system-variable")
)

(
  :name "RESTORELOSTFOCUS"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Restore lost focus (Linux): Controls lost focus recovery. Dependent on the window manager, focus may be lost by when short-lived windows like Quad and rollover tips are used."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/restorelostfocus-system-variable")
)

(
  :name "RETAINEDGRAPHICS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Retained Graphics: Toggles the use of retained graphics. Retained graphics can improve the performance of certain operations, for example, rotating and panning the camera."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/retainedgraphics-system-variable")
)

(
  :name "REVCLOUDARCSTYLE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Revision cloud default arc style: Controls the default arc style for revision clouds."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/revcloudarcstyle-system-variable")
)

(
  :name "REVCLOUDCREATEMODE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Revision cloud creation mode: Controls the default revision cloud creation mode."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/revcloudcreatemode-system-variable")
)

(
  :name "REVCLOUDGRIPS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Revision cloud grips: Uses custom grips for revision clouds."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/revcloudgrips-system-variable")
)

(
  :name "REVCLOUDMAXARCLENGTH"
  :type :real
  :default 0.375
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Revision cloud default maximum arc length: Controls the default maximum arc length for revision clouds. The maximum arc length is multiplied by the value of the DIMSCALE system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/revcloudmaxarclength-system-variable")
)

(
  :name "REVCLOUDMINARCLENGTH"
  :type :real
  :default 0.375
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Revision cloud default minimum arc length: Controls the default minimum arc length for revision clouds. The minimum arc length is multiplied by the value of the DIMSCALE system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/revcloudminarclength-system-variable")
)

(
  :name "RE_INIT"
  :type :short
  :default 0
  :read-only T
  :range (0 21)
  :bitcoded T
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Reinitialize Aliases: Reinitializes the digitizer, digitizer port and/or reloads PGP file (command aliases)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/re_init-system-variable")
)

(
  :name "RHINOVERSION"
  :type :short
  :default 0
  :read-only NIL
  :range (0 60)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Rhino Export version: The 3DM version used to export to Rhino. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rhinoversion-system-variable")
)

(
  :name "RIBBONDOCKEDHEIGHT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 500)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ribbon docked height: Controls the height of the Ribbon. Values between 0 and 500 are accepted. Values lower than the current Ribbon content will be disregarded. A value of 0 means Automatic height. Note: Values below 124 are effective only in certain circumstances."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/ribbondockedheight-system-variable")
)

(
  :name "RIBBONPANELMARGIN"
  :type :short
  :default 8
  :read-only NIL
  :range (0 50)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Panel margin: The size, in pixels, of the blank space at the Ribbon panel edges. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/ribbonpanelmargin-system-variable")
)

(
  :name "RIBBONSETTINGSENABLED"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Ribbon interface settings control on/off: Toggles the display of the Interface Settings control in the ribbon on/off. Note: A restart may be required. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/ribbonsettingsenabled-system-variable")
)

(
  :name "RIBBONSTATE"
  :type :integer
  :default 0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ribbon state: Indicates if the Ribbon is on. The ribbon can be closed with the RIBBONCLOSE command and can be displayed with the RIBBON command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/ribbonstate-system-variable")
)

(
  :name "ROAMABLEROOTPREFIX"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Roamable root prefix: The path of the root folder where roamable files for the current user such as menus and plotstyles, were installed."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/roamablerootprefix-system-variable")
)

(
  :name "ROLLOVEROPACITY"
  :type :short
  :default 100
  :read-only NIL
  :range (10 100)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Rollover opacity: Controls the opacity of the Quad. Values between 10 and 100 are accepted. A value of 10 means maximum transparency. A value of 100 means full opacity."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rolloveropacity-system-variable")
)

(
  :name "ROLLOVERPARAMS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Rollover parameters: Show block parameters in the rollover tips."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rolloverparams-system-variable")
)

(
  :name "ROLLOVERSELECTIONSET"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Rollover selection set: Controls the behavior of properties in the rollover tips, when mixed entities are selected. Setting the value to Properties shared by all selected entities decreases performance on large selections. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rolloverselectionset-system-variable")
)

(
  :name "ROLLOVERTIPS"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Rollover tips: Display entity properties in Quad, either on hover or on demand from Quad titlebar. Note: When the SELECTIONPREVIEW system variable is Off, the ROLLOVERTIPS system variable is ignored, and entity properties are not displayed when you hover the cursor over entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rollovertips-system-variable")
)

(
  :name "RTDISPLAY"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Realtime display: Controls how raster images and OLE entities display during ZOOM or PAN action."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rtdisplay-system-variable")
)

(
  :name "RTISOLATESELECTION"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Realtime selection isolation: Controls if the active selection is automatically isolated during realtime rotation. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rtisolateselection-system-variable")
)

(
  :name "RTROTATIONSPEEDFACTOR"
  :type :real
  :default 1.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Realtime Rotation Speed Factor: Controls the rotation speed for the Look and Walk tools (RTLOOK and RTWALK commands). Values between 0.01 and 100.00 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rtrotationspeedfactor-system-variable")
)

(
  :name "RUBBERBANDCOLOR"
  :type :short
  :default 40
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Rubber band color: Controls the color of the rubber band line, used for temporary snap tracking. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rubberbandcolor-system-variable")
)

(
  :name "RUBBERBANDSTYLE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Rubber band dashed style: Enables a dashed linestyle for the rubber band line, used for temporary snap tracking. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rubberbandstyle-system-variable")
)

(
  :name "RUBBERSHEETSENSIBILITY_FOR_OS_X"
  :type :short
  :default 5
  :read-only NIL
  :range (0 10)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Rubbersheet gesture activation sensibility: Controls the sensitivity of gestures. Values of 0 to 10 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rubbersheetsensibility-for-os-x-system-variable")
)

(
  :name "RUBBERSHEET_FOR_OS_X"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Rubbersheet Touchpad: Enable simultaneous zoom/rotate/pan with dual finger movements on the touchpad."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rubbersheet-for-os-x-system-variable")
)

(
  :name "RULERDISPLAY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ruler display: Shows a ruler during Manipulator operations."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rulerdisplay-system-variable")
)

(
  :name "RULERTEXTCOLOR"
  :type :string
  :default "#c8c8c8"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Ruler Text Color: Controls the text color of the Manipulator ruler. Applies only if the RULERDISPLAY system variable is on (1)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rulertextcolor-system-variable")
)

(
  :name "RUNASLEVEL"
  :type :short
  :default 5
  :read-only NIL
  :range (0 5)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Run as license level: Runs the program in a different (lower) level than the licensed level. If the licensed level is lower than RUNASLEVEL, RUNASLEVEL is ignored. Note: A restart is required. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/runaslevel-system-variable")
)

(
  :name "RVTRFALEVELOFDETAIL"
  :type :short
  :default 3
  :read-only NIL
  :range (1 3)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Level of detail: Controls the level of detail (LOD) for RVT and RFA import. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rvtrfalevelofdetail-system-variable")
)

(
  :name "RVTVALIDATEBREP"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Validate BREP geometry: Validate BREP geometry during an RVT import. Warning: Disabling this may import more geometry without no check on integrity. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/r/rvtvalidatebrep-system-variable")
)

(
  :name "SAFEMODE"
  :type :integer
  :default 0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Safe mode: Indicates if executable code can be loaded and executed in the current session. Starting in a clean environment can help to eliminate potential causes of a crash."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/safemode-system-variable")
)

(
  :name "SAVECHANGETOLAYOUT"
  :type :integer
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Save changes to layout: Saves changes to a layout from the Print dialog box. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/savechangetolayout-system-variable")
)

(
  :name "SAVEFIDELITY"
  :type :integer
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Save fidelity: Controls if this drawing is saved with visual fidelity."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/savefidelity-system-variable")
)

(
  :name "SAVEFILE"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Save file name: The current automatic save file name."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/savefile-system-variable")
)

(
  :name "SAVEFILEPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Save file path: The file path where automatic saves and temporary files are stored."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/savefilepath-system-variable")
)

(
  :name "SAVEFORMAT"
  :type :short
  :default 1
  :read-only NIL
  :range (1 39)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Save format: Controls the default save format. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/saveformat-system-variable")
)

(
  :name "SAVELAYERSNAPSHOT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Save Layer Snapshot with view: Saves the current layer settings and uses them for new views. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/savelayersnapshot-system-variable")
)

(
  :name "SAVENAME"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Saved drawing name: The file name and folder path of the current drawing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/savename-system-variable")
)

(
  :name "SAVEONDOCSWITCH"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Save on document switch: Saves the drawing automatically when another drawing tab is activated. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/saveondocswitch-system-variable")
)

(
  :name "SAVEROUNDTRIP"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Save roundtrip: Allows information, in a database file, not supported in the drawing to be saved. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/saveroundtrip-system-variable")
)

(
  :name "SAVETIME"
  :type :short
  :default 20
  :read-only NIL
  :range (0 240)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Save time interval: Controls the interval for automatic saves, in minutes. Values between 0 and 240 are accepted. If set to zero, automatic saves are turned off."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/savetime-system-variable")
)

(
  :name "SCREENBOXES"
  :type :short
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Screen menu boxes: Contains the number of boxes displayed in the screen menu. If the screen menu is turned off, the value is zero."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/screenboxes-system-variable")
)

(
  :name "SCREENMODE"
  :type :short
  :default (:unknown)
  :read-only T
  :range (0 3)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Screen mode: Stores the graphic/text state of the program display."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/screenmode-system-variable")
)

(
  :name "SCREENSIZE"
  :type :point
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Screen size: The size of the current viewport, in pixels (width x height)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/screensize-system-variable")
)

(
  :name "SCRLHIST"
  :type :short
  :default 256
  :read-only NIL
  :range (0 NIL)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Scroll history: Controls the number of lines stored in the history of the Command line. Values between 0 and 256 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/scrlhist-system-variable")
)

(
  :name "SDI"
  :type :short
  :default 0
  :read-only T
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Single-document interface (Windows): Controls if a drawing is opened in a new application instance or an existing instance. Partially implemented: SDI variable controls double-click behavior for drawings, but it is still possible to open multiple documents in each application instance. Note: SDI setting 2 and 3 are not saved. If SDI is set to 3, the program switches it back to 1 when the application that doesn't support multiple drawings is unloaded."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sdi-system-variable")
)

(
  :name "SECTIONRESULTINTERVAL"
  :type :real
  :default 400.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Section result interval: The distance between generated section blocks in model space. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sectionresultinterval-system-variable")
)

(
  :name "SECTIONSCALE"
  :type :real
  :default 0.02
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Section scale: The default scale used to generate sections. Values between 0.000001 and 1000000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sectionscale-system-variable")
)

(
  :name "SECTIONSETTINGSSEARCHPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Section settings search path: The file path for BIM section styles, BIM tag styles and drawing customizations. Separate paths with semicolons (;). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sectionsettingssearchpath-system-variable")
)

(
  :name "SECTIONSHEETSETTEMPLATEIMPERIAL"
  :type :string
  :default "BIM-section-imperial.dst"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Section sheet set template imperial: The file path for the Sheet Set file (DST) used as template for a new section. Applies only when MEASUREMENT system variable is 0 (imperial). The default file is BIM-section-imperial.dst, which can be found in the {SheetSetTemplatePath} folder. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sectionsheetsettemplateimperial-system-variable")
)

(
  :name "SECTIONSHEETSETTEMPLATEMETRIC"
  :type :string
  :default "BIM-section-metric.dst"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Section sheet set template metric: The file path for Sheet Set file (dst), used as template for a new section. Applies only when the MEASUREMENT system variable is 1 (metric). The default file is BIM-section-metric.dst, which can be found in the {SheetSetTemplatePath} folder. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sectionsheetsettemplatemetric-system-variable")
)

(
  :name "SECURELOAD"
  :type :short
  :default 0
  :read-only T
  :range (0 2)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Executable file security policy: The security policy used to load executable files."
  :coupled ("load" "open" "findtrustedfile")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/secureload-system-variable")
)

(
  :name "SELECTIONANNODISPLAY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Show all annotation scales on selection: Displays an annotated entity, in all scales, on selection."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/selectionannodisplay-system-variable")
)

(
  :name "SELECTIONAREA"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Selection area: Controls the display of selection area effects."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/selectionarea-system-variable")
)

(
  :name "SELECTIONAREAOPACITY"
  :type :short
  :default 25
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Selection area opacity: Controls the transparency of the selection area. Applies only when SELECTIONAREA setting is on. Values between 0 and 100 are accepted. A value of zero means Fully Transparent. A value of 100 means fully opaque."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/selectionareaopacity-system-variable")
)

(
  :name "SELECTIONCYCLING"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Selection cycling: Controls the display options associated with overlapping objects and selection cycling. Note: When the SELECTIONPREVIEW system variable is Off, the SELECTIONCYCLING system variable is ignored, and no badge or selection dialog box is displayed when you hover the cursor over entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/selectioncycling-system-variable")
)

(
  :name "SELECTIONMODES"
  :type :short
  :default 0
  :read-only NIL
  :range (0 16399)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Selection modes: Controls what is selected by default: whole entities, subentities or boundaries. Use the TAB key, on hover, to cycle through the options. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/selectionmodes-system-variable")
)

(
  :name "SELECTIONPREVIEW"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Selection preview display: Controls the rules used to highlight entities when the pickbox cursor hovers over an entity. Note: When the SELECTIONPREVIEW system variable is Off: The Display the Quad when the cursor hovers on an entity option of the QUADDISPLAY system variable is ignored and the Quad is not displayed. The ROLLOVERTIPS system variable is ignored and entity properties are not displayed (the Quad is not displayed). The SELECTIONCYCLING system variable is ignored..."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/selectionpreview-system-variable")
)

(
  :name "SELECTSIMILARMODE"
  :type :short
  :default 130
  :read-only NIL
  :range (0 255)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Match options for SELECTSIMILAR: Controls which properties must match for the SELECTSIMILAR command. For this command to operate as intended, at least one property must be turned on. When all properties are turned off, this command selects only the entity(ies) you pick at the Select entities prompt."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/selectsimilarmode-system-variable")
)

(
  :name "SETBYLAYERMODE"
  :type :short
  :default 255
  :read-only NIL
  :range (0 255)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Set by layer mode: Controls which layer properties are applied with the SETBYLAYER command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/setbylayermode-system-variable")
)

(
  :name "SHADEDGE"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Shading edges: Controls how faces and edges display in rendered views."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/shadedge-system-variable")
)

(
  :name "SHADEDIF"
  :type :short
  :default 70
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Shading diffusion: Controls the ratio of diffuse reflective light to ambient light as a percentage of diffuse reflective light when the SHADEDGE system variable is set to 0 or 1."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/shadedif-system-variable")
)

(
  :name "SHEETNUMBERLEADINGZEROES"
  :type :short
  :default 1
  :read-only NIL
  :range (1 8)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Sheet number leading zeroes: Controls the number of zeros that prefix new sheet 'Number' values. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sheetnumberleadingzeroes-system-variable")
)

(
  :name "SHEETSETAUTOBACKUP"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Sheet set automatic backup: Creates a backup file when a Sheet Set file is opened. The backup files must have the same name as the Sheet Set file but with a 'ds$' extension. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sheetsetautobackup-system-variable")
)

(
  :name "SHEETSETTEMPLATEPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sheet Set template path: The file path for the Sheet Set Templates folder. The default path is: \\Users\\%username%\\AppData\\Local\\Bricsys\\BricsCAD\\ V26 x64\\en_US\\Templates ."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sheetsettemplatepath-system-variable")
)

(
  :name "SHORTCUTMENU"
  :type :short
  :default 11
  :read-only NIL
  :range (0 63)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Shortcut menus: Controls the status of the DEFAULT, EDIT and COMMAND (right-click) context menus."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/shortcutmenu-system-variable")
)

(
  :name "SHORTCUTMENUDURATION"
  :type :integer
  :default 250
  :read-only NIL
  :range (100 10000)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Shortcut menu duration: Controls the delay between right-click and the appearance of the (right-click) context menu, in milliseconds. Values between 100 and 10,000 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/shortcutmenuduration-system-variable")
)

(
  :name "SHOWDOCTABS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tabs visibility: Toggles tabs on/off, in the documents tab. You can make the drawing area larger by hiding the document tabs from the user interface. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/showdoctabs-system-variable")
)

(
  :name "SHOWFULLPATHINTITLE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Display full path in title: Displays the full path of a drawing in the title bar. If off, displays only the file name."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/showfullpathintitle-system-variable")
)

(
  :name "SHOWIDSPROPERTIESONLY"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Show IDS Properties Only: When an IDS-XML file has been imported, this setting controls whether only the properties required by the IDS should be shown in the Properties panel, or all properties should be shown. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/showidspropertiesonly-system-variable")
)

(
  :name "SHOWLAYERUSAGE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Layer Usage: Shows information about layer usage in the Layers panel. In the column Current , the Layer Usage icons indicate when viewport settings for the current layout and paper space viewport are different from model space settings: : Current layer with viewport overrides. : Layer with viewport overrides. : Empty layer with viewport overrides."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/showlayerusage-system-variable")
)

(
  :name "SHOWSCROLLBUTTONS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Scroll buttons (Mac & Linux): Displays left and right scroll buttons. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/showscrollbuttons-system-variable")
)

(
  :name "SHOWTABCLOSEBUTTON"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Close button on tabs (Mac & Linux): Toggles the close button on the tab bars on/off, in the documents tab. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/showtabclosebutton-system-variable")
)

(
  :name "SHOWTABCLOSEBUTTONACTIVE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Close button on active tab (Mac & Linux): Toggles the close button on the active tab only on/off, in the documents tab. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/showtabclosebuttonactive-system-variable")
)

(
  :name "SHOWTABCLOSEBUTTONALL"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Close button on all tabs (Mac & Linux): Toggles the close button on all tabs on/off, in the documents tab. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/showtabclosebuttonall-system-variable")
)

(
  :name "SHOWWINDOWLISTBUTTON"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Window list button (Mac & Linux): Shows a drop-down list of windows. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/showwindowlistbutton-system-variable")
)

(
  :name "SHPNAME"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Shape name: The default shape name according to naming conventions. '.' means no default. Note: Shapes are an early version of blocks that were efficient, but difficult to code. Shapes are rarely used anymore."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/shpname-system-variable")
)

(
  :name "SIGWARN"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Signature warning: Controls the Signature dialog behavior, when a drawing with a signature is opened."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sigwarn-system-variable")
)

(
  :name "SINGLETONMODE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Singleton mode: Switch to control whether one or more instances of BricsCAD can run simultaneously. When set to Off, you can launch two or more copies of BricsCAD at the same time. When set to On, only a single instance of BricsCAD runs if the profile name and current workspace name are the same, and the background instance is responsive, with no command or modal dialog active. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/singletonmode-system-variable")
)

(
  :name "SITELOCATIONVISIBILITY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Site location marker visibility: Controls the visibility of the Site location marker. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sitelocationvisibility-system-variable")
)

(
  :name "SKETCHFEATURECOPYMODE"
  :type :integer
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Sketch feature copy mode: Controls how sketch features will be copied. If ON, copies of sketch features will be independent of their source (new blocks of the sketches/paths/guide curves/etc. will be created). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sketchfeaturecopymode-system-variable")
)

(
  :name "SKETCHINC"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sketch increment: The length of segments created with the SKETCH command, in drawings units."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sketchinc-system-variable")
)

(
  :name "SKPOLY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sketch poly: Controls the entity type created with the SKETCH command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/skpoly-system-variable")
)

(
  :name "SKYSTATUS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sky status: Controls if sky illumination is computed at render time (Not yet supported)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/skystatus-system-variable")
)

(
  :name "SMASSEMBLYEXPORTMODE"
  :type :short
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SmAssemblyExport mode: Controls how data is exported by the SMASSEMBLYEXPORT command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smassemblyexportmode-system-variable")
)

(
  :name "SMASSEMBLYEXPORTREPORTPATHTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Report file path type: Controls whether absolute or relative file paths are used in the reports generated by the SMASSEMBLYEXPORT command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smassemblyexportreportpathtype-system-variable")
)

(
  :name "SMASSEMBLYEXPORTSOLIDTYPESINREPORTS"
  :type :short
  :default 1
  :read-only NIL
  :range (0 15)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Solid types in reports: Controls the types of solids present in command reports for the SMASSEMBLYEXPORT command. Sheet metal and poor sheet metal solids are always present in reports. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smassemblyexportsolidtypesinreports-system-variable")
)

(
  :name "SMATTRIBUTESLAYERCOLOR"
  :type :short
  :default 7
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the attributes layer: Controls the color of the 'Attributes' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smattributeslayercolor-system-variable")
)

(
  :name "SMATTRIBUTESLAYERTEXTHEIGHT"
  :type :real
  :default 0.01
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Height of the text: Controls the text height of the 'Attributes' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smattributeslayertextheight-system-variable")
)

(
  :name "SMATTRIBUTESLAYERTEXTHEIGHTTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Type of the text height: Controls the text height type for the 'Attributes' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smattributeslayertextheighttype-system-variable")
)

(
  :name "SMBENDANNOTATIONSLAYERCOLOR"
  :type :short
  :default 5
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the bend annotations text layer: Controls the color of the 'Bend Annotations' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smbendannotationslayercolor-system-variable")
)

(
  :name "SMBENDANNOTATIONSLAYERTEXTHEIGHT"
  :type :real
  :default 0.01
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Height of the text: Controls the text height of the 'Bend Annotations' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smbendannotationslayertextheight-system-variable")
)

(
  :name "SMBENDANNOTATIONSLAYERTEXTHEIGHTTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Type of the text height: Controls the text height type for the 'Bend Annotations' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smbendannotationslayertextheighttype-system-variable")
)

(
  :name "SMBENDLINESDOWNLAYERCOLOR"
  :type :short
  :default 1
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the bend down lines layer: Controls the color of the 'Bends Down' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smbendlinesdownlayercolor-system-variable")
)

(
  :name "SMBENDLINESDOWNLAYERLINETYPE"
  :type :string
  :default "CONTINUOUS"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Linetype of the bend down lines layer: Controls the linetype of the 'Bends Down' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smbendlinesdownlayerlinetype-system-variable")
)

(
  :name "SMBENDLINESDOWNLAYERLINEWEIGHT"
  :type :short
  :default -3
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Lineweight of the bend down layer: Controls the lineweight of the 'Bends Down' layer, created by the SMUNFOLD and SMEXPORT2D commands. Values between -3 and 211 are accepted. -1=ByLayer -2=ByBlock -3=Default BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smbendlinesdownlayerlineweight-system-variable")
)

(
  :name "SMBENDLINESUPLAYERCOLOR"
  :type :short
  :default 1
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the bend up lines layer: Controls the line color of the 'Bends Up' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smbendlinesuplayercolor-system-variable")
)

(
  :name "SMBENDLINESUPLAYERLINETYPE"
  :type :string
  :default "CONTINUOUS"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Linetype of the bend up lines layer: Controls the linetype of the 'Bends Up' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smbendlinesuplayerlinetype-system-variable")
)

(
  :name "SMBENDLINESUPLAYERLINEWEIGHT"
  :type :short
  :default -3
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Lineweight of the bend up layer: Controls the lineweight of the 'Bends Up' layer, created by the SMUNFOLD and SMEXPORT2D commands. Values between -3 and 211 are accepted. -1=ByLayer -2=ByBlock -3=Default BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smbendlinesuplayerlineweight-system-variable")
)

(
  :name "SMBEVELFEATURECOLOR"
  :type :short
  :default 6
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the bevel features layer: Controls the color of the 'Bevel Features' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smbevelfeaturecolor-system-variable")
)

(
  :name "SMCOLORBEND"
  :type :string
  :default "#FFDC50"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bend feature color: Controls the display color of sheet metal bends. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorbend-system-variable")
)

(
  :name "SMCOLORBENDRELIEF"
  :type :string
  :default "#64D296"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bend relief feature color: Controls the display color of sheet metal reliefs. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorbendrelief-system-variable")
)

(
  :name "SMCOLORBEVEL"
  :type :string
  :default "#C0CE93"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bevel feature color: Controls the display color of sheet metal bevels. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorbevel-system-variable")
)

(
  :name "SMCOLORCORNERRELIEF"
  :type :string
  :default "#64D296"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Corner relief feature color: Controls the display color of sheet metal corner reliefs. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorcornerrelief-system-variable")
)

(
  :name "SMCOLORFLANGE"
  :type :string
  :default "#90A4AE"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Flange feature color: Controls the display color of sheet metal flanges. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorflange-system-variable")
)

(
  :name "SMCOLORFLANGEREFERENCESIDE"
  :type :string
  :default "#68A4AE"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Flange feature reference side color: Controls the display color of sheet metal faces on the reference side of a flange. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorflangereferenceside-system-variable")
)

(
  :name "SMCOLORFORM"
  :type :string
  :default "#8791E1"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Form feature color: Controls the display color of sheet metal forms. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorform-system-variable")
)

(
  :name "SMCOLORHEM"
  :type :string
  :default "#FCAED6"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hem feature color: Controls the display color of sheet metal hems. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorhem-system-variable")
)

(
  :name "SMCOLORJOG"
  :type :string
  :default "#CC7722"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Jog feature color: Controls the display color of sheet metal jogs. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorjog-system-variable")
)

(
  :name "SMCOLORJUNCTION"
  :type :string
  :default "#FF6E40"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Junction feature color: Controls the display color of sheet metal junctions. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorjunction-system-variable")
)

(
  :name "SMCOLORLOFTEDBEND"
  :type :string
  :default "#A0DCFA"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Lofted bend feature color: Controls the display color of sheet metal lofted bends. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorloftedbend-system-variable")
)

(
  :name "SMCOLORMITER"
  :type :string
  :default "#AF46D8"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Miter feature color: Controls the display color of sheet metal miters. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolormiter-system-variable")
)

(
  :name "SMCOLORROLLEDEDGE"
  :type :string
  :default "#8791E1"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Rolled edge feature color: Controls the display color of sheet metal rolled edges. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorrollededge-system-variable")
)

(
  :name "SMCOLORTAB"
  :type :string
  :default "#FDA542"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tab feature color: Controls the display color of sheet metal tabs. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolortab-system-variable")
)

(
  :name "SMCOLORWRONGBEND"
  :type :string
  :default "#FF3300"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Wrong bend feature color: Controls the display color of sheet metal wrong bends. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorwrongbend-system-variable")
)

(
  :name "SMCOLORWRONGFLANGE"
  :type :string
  :default "#A82000"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Wrong flange feature color: Controls the display color of sheet metal wrong flanges. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcolorwrongflange-system-variable")
)

(
  :name "SMCONTOURSLAYERCOLOR"
  :type :short
  :default 7
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the contour layer: Controls the color of the '2D dxf layer', contains unfolded geometry created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcontourslayercolor-system-variable")
)

(
  :name "SMCONTOURSLAYERLINETYPE"
  :type :string
  :default "CONTINUOUS"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Linetype of the contour layer: Controls the linetype of the 'Contour' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcontourslayerlinetype-system-variable")
)

(
  :name "SMCONTOURSLAYERLINEWEIGHT"
  :type :short
  :default 30
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Lineweight of the contour layer: Controls the line weight of the 'Contour' layer, created by the SMUNFOLD and SMEXPORT2D commands. Values between -3 and 211 are accepted. -1=ByLayer -2=ByBlock -3=Default BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smcontourslayerlineweight-system-variable")
)

(
  :name "SMCONVERTMAXIMALBEVELANGLE"
  :type :real
  :default 80.0d0
  :read-only NIL
  :range (0 90)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximal angle of bevel: Controls the maximal angle of bevel during the SMCONVERT command. Values between 0.0 and 90.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertmaximalbevelangle-system-variable")
)

(
  :name "SMCONVERTMINIMALBEVELANGLE"
  :type :real
  :default 10.0d0
  :read-only NIL
  :range (0 90)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Minimal angle of bevel: Controls the minimal angle of a bevel during the SMCONVERT command. Values between 0.0 and 90.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertminimalbevelangle-system-variable")
)

(
  :name "SMCONVERTPREFERFORMFEATURES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Prefer form features to flanges and bends: Controls how features are recognized on solid faces, for the SMCONVERT command, single form features or bends and flanges. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertpreferformfeatures-system-variable")
)

(
  :name "SMCONVERTPREFERHEMFEATURES"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Prefer hem features to flanges and bends: Controls how features are recognized on solid faces, for the SMCONVERT command, single hem features or bends and flanges. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertpreferhemfeatures-system-variable")
)

(
  :name "SMCONVERTPREFERJOGFEATURES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Prefer jog features to flanges and bends: Controls how features are recognized on solid faces, during the SMCONVERT command, single jog features or bends and flanges. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertpreferjogfeatures-system-variable")
)

(
  :name "SMCONVERTPREFERZEROBENDFEATURES"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Prefer zero bend features to wrong bends: Controls how features are recognized on solid faces, during the SMCONVERT command, zero bend features or wrong bend features. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertpreferzerobendfeatures-system-variable")
)

(
  :name "SMCONVERTRECOGNIZEBEVELS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Recognize bevel features: Recognizes bevel features during the SMCONVERT command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertrecognizebevels-system-variable")
)

(
  :name "SMCONVERTRECOGNIZEHOLES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Recognize holes: Recognizes holes on flanges as features during the SMCONVERT command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertrecognizeholes-system-variable")
)

(
  :name "SMCONVERTRECOGNIZERIBCONTROLCURVES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Recognize bead control curves: Recognizes 2D control curves for bead features, during the SMCONVERT command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertrecognizeribcontrolcurves-system-variable")
)

(
  :name "SMCONVERTWRONGFEATURETHICKNESSDEVIATIONTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Type of deviation of wrong feature thickness: Controls if the deviation value is treated as ratio to model thickness or an absolute value. See the SMCONVERTWRONGFEATURETHICKNESSDEVIATIONVALUE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertwrongfeaturethicknessdeviationtype-system-variable")
)

(
  :name "SMCONVERTWRONGFEATURETHICKNESSDEVIATIONVALUE"
  :type :real
  :default 0.2
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Deviation value of wrong feature thickness: Sets the allowed deviation between model thickness and the thickness of a given wrong feature. Values between 0 and 1,000,000 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smconvertwrongfeaturethicknessdeviationvalue-system-variable")
)

(
  :name "SMDEFAULTBENDLINEEXTENTTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bend line extent type: Controls if the SMDEFAULTBENDLINEEXTENTVALUE system variable is a ratio to the thickness or an absolute value. The value will be used to initialize sheet metal settings in the document. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultbendlineextenttype-system-variable")
)

(
  :name "SMDEFAULTBENDLINEEXTENTVALUE"
  :type :real
  :default 0.25
  :read-only NIL
  :range (-1000000 1000000)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bend line extent value: Controls sheet metal bend lines. Values between -1,000,000 and 1,000,000.0 are accepted. Positive value = Stretches past a contour Negative value = Does not reach it Zero = Just touches BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultbendlineextentvalue-system-variable")
)

(
  :name "SMDEFAULTBENDRADIUSTYPE"
  :type :short
  :default 2
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bend radius type: Controls the default sheet metal bend radius. Absolute value toggles the Thickness ratio. Override bend radius in SMCONVERT controls if the bend radius is taken from SMDEFAULTBENDRADIUSVALUE or from the model. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultbendradiustype-system-variable")
)

(
  :name "SMDEFAULTBENDRADIUSVALUE"
  :type :real
  :default 1.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bend radius value: Controls the default sheet metal bend radius, in drawing units. See also the SMDEFAULTBENDRADIUSTYPE system variable. Values between 0.0001 and 1,000,000 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultbendradiusvalue-system-variable")
)

(
  :name "SMDEFAULTBENDRELIEFWIDTHTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Bend relief type: Controls if the SMDEFAULTBENDRELIEFWIDTHVALUE system variable is a ratio to the thickness or an absolute value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultbendreliefwidthtype-system-variable")
)

(
  :name "SMDEFAULTBENDRELIEFWIDTHVALUE"
  :type :real
  :default 0.5
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bend relief width value: Controls the default value for a sheet metal bend relief width. Values between 0.0 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultbendreliefwidthvalue-system-variable")
)

(
  :name "SMDEFAULTBEVELFEATUREUNFOLDMODE"
  :type :short
  :default 2
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bevel unfolding mode: Controls the appearance of bevels in an unfolded part. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultbevelfeatureunfoldmode-system-variable")
)

(
  :name "SMDEFAULTCORNERRELIEFDIAMETERVALUE"
  :type :real
  :default -1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Corner relief diameter value: Controls the default diameter for a sheet metal corner relief. Values between -1.0 and 1,000,000.0 are accepted. Set to -1.0 for automatic determination of least feasible for given corner relief. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultcornerreliefdiametervalue-system-variable")
)

(
  :name "SMDEFAULTFLANGESPLITEXTENSIONTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Miter extension type: Controls if the SMDEFAULTFLANGESPLITEXTENSIONVALUE system variable is a ratio to the thickness or an absolute value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultflangesplitextensiontype-system-variable")
)

(
  :name "SMDEFAULTFLANGESPLITEXTENSIONVALUE"
  :type :real
  :default 0.1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Miter extension value: Controls the default value for a sheet metal miter extension. Values between 0.0 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultflangesplitextensionvalue-system-variable")
)

(
  :name "SMDEFAULTFLANGESPLITGAPTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Miter gap type: Controls if the SMDEFAULTFLANGESPLITGAPVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultflangesplitgaptype-system-variable")
)

(
  :name "SMDEFAULTFLANGESPLITGAPVALUE"
  :type :real
  :default 0.1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Miter gap value: Controls the default value for sheet metal miter gap size. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultflangesplitgapvalue-system-variable")
)

(
  :name "SMDEFAULTFORMFEATUREUNFOLDMODE"
  :type :short
  :default 4
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Form feature unfolding mode: Controls the appearance of form features in an unfolded part. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultformfeatureunfoldmode-system-variable")
)

(
  :name "SMDEFAULTGUSSETDEPTHTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Gusset depth type: Controls if the SMDEFAULTGUSSETDEPTHVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultgussetdepthtype-system-variable")
)

(
  :name "SMDEFAULTGUSSETDEPTHVALUE"
  :type :real
  :default 8.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Gusset height value: Controls the default sheet metal gusset height. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultgussetdepthvalue-system-variable")
)

(
  :name "SMDEFAULTGUSSETFILLETRADIUSTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Gusset fillet radius type: Controls if the SMDEFAULTGUSSETFILLETRADIUSVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultgussetfilletradiustype-system-variable")
)

(
  :name "SMDEFAULTGUSSETFILLETRADIUSVALUE"
  :type :real
  :default 1.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Gusset fillet radius value: Controls the default sheet metal gusset radius. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultgussetfilletradiusvalue-system-variable")
)

(
  :name "SMDEFAULTGUSSETTYPE"
  :type :short
  :default 1
  :read-only NIL
  :range (1 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Gusset type: Toggles between a round or flat sheet metal gusset type. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultgussettype-system-variable")
)

(
  :name "SMDEFAULTGUSSETWIDTHTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Gusset width type: Controls if the SMDEFAULTGUSSETWIDTHVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultgussetwidthtype-system-variable")
)

(
  :name "SMDEFAULTGUSSETWIDTHVALUE"
  :type :real
  :default 6.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Gusset width value: Controls the default sheet metal gusset width. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultgussetwidthvalue-system-variable")
)

(
  :name "SMDEFAULTHEMGAPTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Open Hem gap type: Controls if the SMDEFAULTHEMGAPVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulthemgaptype-system-variable")
)

(
  :name "SMDEFAULTHEMGAPVALUE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Open Hem gap value (in addition to the thickness): Controls the default sheet metal open hem gap size. Values between 0.001 and 100.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulthemgapvalue-system-variable")
)

(
  :name "SMDEFAULTHEMRELATIVEBENDDEDUCTION"
  :type :real
  :default 2.4
  :read-only NIL
  :range (0 10)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hem relative bend deduction value: Sets a bend deduction value, relative to the thickness, used for closed hem unfolding. Values between 0.0 (hem lengthen) and 10.0 (shorten bend zone by a value equal to 8 times the thickness) are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulthemrelativebenddeduction-system-variable")
)

(
  :name "SMDEFAULTJOGANGLEVALUE"
  :type :real
  :default 45.0d0
  :read-only NIL
  :range (0 180)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Jog angle value: Controls the default sheet metal jog angle. Values between 0.0 and 180.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultjoganglevalue-system-variable")
)

(
  :name "SMDEFAULTJOGHEIGHTTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Jog height type: Controls if the SMDEFAULTJOGHEIGHTVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultjogheighttype-system-variable")
)

(
  :name "SMDEFAULTJOGHEIGHTVALUE"
  :type :real
  :default 1.001
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Jog height value: Controls the default sheet metal jog height. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultjogheightvalue-system-variable")
)

(
  :name "SMDEFAULTJOGRADIUSTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Jog radius type: Controls if the SMDEFAULTJOGRADIUSVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultjogradiustype-system-variable")
)

(
  :name "SMDEFAULTJOGRADIUSVALUE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Jog radius value: Controls the default sheet metal jog radius. Values between 1.0 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultjogradiusvalue-system-variable")
)

(
  :name "SMDEFAULTJUNCTIONALIGNMENTTORELIEF"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Junction alignment to relief: Forces sheet metal junction faces to align to adjacent relief faces. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultjunctionalignmenttorelief-system-variable")
)

(
  :name "SMDEFAULTJUNCTIONGAPTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Junction gap type: Controls if the SMDEFAULTJUNCTIONGAPVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultjunctiongaptype-system-variable")
)

(
  :name "SMDEFAULTJUNCTIONGAPVALUE"
  :type :real
  :default 0.001
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Junction gap value: Controls the default sheet metal for the open junction gap size. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultjunctiongapvalue-system-variable")
)

(
  :name "SMDEFAULTKFACTOR"
  :type :real
  :default 0.27324
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "K-Factor value: Sets the location ratio of the neutral surface (the surface not stretched or squeezed when the sheet is bent) to the material thickness. Values between 0.00000 (internal bend radius) and 1.00000 (external bend radius) are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultkfactor-system-variable")
)

(
  :name "SMDEFAULTLOFTEDBENDNUMBERSAMPLES"
  :type :short
  :default 10
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Lofted bend subdivisions: Controls the default value for sheet metal lofted bend subdivisions. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultloftedbendnumbersamples-system-variable")
)

(
  :name "SMDEFAULTRELIEFEXTENSIONTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Relief extension type: Controls if the SMDEFAULTRELIEFEXTENSIONTYPE system variable is a ratio to the thickness or an absolute value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultreliefextensiontype-system-variable")
)

(
  :name "SMDEFAULTRELIEFEXTENSIONVALUE"
  :type :real
  :default 0.1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Relief extension value: Controls the default value for a sheet metal relief extension. Values between 0.0 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultreliefextensionvalue-system-variable")
)

(
  :name "SMDEFAULTRIBFILLETRADIUSTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bead fillet radius type: Controls if the SMDEFAULTRIBFILLETRADIUSVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultribfilletradiustype-system-variable")
)

(
  :name "SMDEFAULTRIBFILLETRADIUSVALUE"
  :type :real
  :default 5.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bead fillet radius value: Controls the default radius for a sheet metal bead fillet. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultribfilletradiusvalue-system-variable")
)

(
  :name "SMDEFAULTRIBPROFILERADIUSTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bead profile radius type: Controls if the SMDEFAULTRIBPROFILERADIUSVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultribprofileradiustype-system-variable")
)

(
  :name "SMDEFAULTRIBPROFILERADIUSVALUE"
  :type :real
  :default 2.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bead profile radius value: Controls the default radius for a sheet metal bead profile. Values between -1.0 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultribprofileradiusvalue-system-variable")
)

(
  :name "SMDEFAULTRIBROUNDRADIUSTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bead round radius type: Controls if the SMDEFAULTRIBROUNDRADIUSVALUE system variable is a ratio to the thickness or an absolute value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultribroundradiustype-system-variable")
)

(
  :name "SMDEFAULTRIBROUNDRADIUSVALUE"
  :type :real
  :default 1.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Bead round radius value: Controls the default radius for a sheet metal bead, round. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultribroundradiusvalue-system-variable")
)

(
  :name "SMDEFAULTSHARPBENDRADIUSLIMITRATIO"
  :type :real
  :default 5.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Sharp bend radius limit ratio: Controls the default sheet metal sharp bend radius limit, as a ratio to the thickness. Values between 0.0 and 1,000,000.0 are accepted BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultsharpbendradiuslimitratio-system-variable")
)

(
  :name "SMDEFAULTTABCHAMFERDISTANCETYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tab chamfer distance type: Controls if the SMDEFAULTTABCHAMFERDISTANCEVALUE system variable is a ratio to the thickness or an absolute value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabchamferdistancetype-system-variable")
)

(
  :name "SMDEFAULTTABCHAMFERDISTANCEVALUE"
  :type :real
  :default 0.1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tab chamfer distance value: Controls the default chamfer distance of sheet metal tabs. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabchamferdistancevalue-system-variable")
)

(
  :name "SMDEFAULTTABCLEARANCETYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tab clearance type: Controls if the SMDEFAULTTABCLEARANCEVALUE system variable is a ratio to the thickness or an absolute value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabclearancetype-system-variable")
)

(
  :name "SMDEFAULTTABCLEARANCEVALUE"
  :type :real
  :default 0.1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tab clearance value: Controls the default clearance of sheet metal tabs. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabclearancevalue-system-variable")
)

(
  :name "SMDEFAULTTABDISTANCETYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tab distance type: Controls if the SMDEFAULTTABDISTANCEVALUE system variable is a ratio to the thickness or an absolute value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabdistancetype-system-variable")
)

(
  :name "SMDEFAULTTABDISTANCEVALUE"
  :type :real
  :default 20.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tab distance value: Controls the default distance of sheet metal tabs. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabdistancevalue-system-variable")
)

(
  :name "SMDEFAULTTABEDGETYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tab edge type: Controls if sheet metal tabs have sharp, round or chamfered edges. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabedgetype-system-variable")
)

(
  :name "SMDEFAULTTABFILLETRADIUSTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tab fillet radius type: Controls if the SMDEFAULTTABFILLETRADIUSVALUE system variable is a ratio to the thickness or an absolute value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabfilletradiustype-system-variable")
)

(
  :name "SMDEFAULTTABFILLETRADIUSVALUE"
  :type :real
  :default 0.1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tab fillet radius value: Controls the default fillet radius of sheet metal tabs. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabfilletradiusvalue-system-variable")
)

(
  :name "SMDEFAULTTABHEIGHTTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tab height type: Controls if the SMDEFAULTTABHEIGHTVALUE system variable is a ratio to the thickness or an absolute value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabheighttype-system-variable")
)

(
  :name "SMDEFAULTTABHEIGHTVALUE"
  :type :real
  :default 1.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tab height value: Controls the default height of sheet metal tab slots. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabheightvalue-system-variable")
)

(
  :name "SMDEFAULTTABLENGTHTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tab length type: Controls if the SMDEFAULTTABLENGTHTYPE system variable is a ratio to the thickness or an absolute value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttablengthtype-system-variable")
)

(
  :name "SMDEFAULTTABLENGTHVALUE"
  :type :real
  :default 4.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tab length value: Controls the default length of sheet metal tabs. Values between 0.0001 and 1,000,000.0 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttablengthvalue-system-variable")
)

(
  :name "SMDEFAULTTABSLOTNUMBER"
  :type :short
  :default 2
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tab slot number: Controls the default number of sheet metal tab slots. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaulttabslotnumber-system-variable")
)

(
  :name "SMDEFAULTTHICKNESS"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Thickness value: Controls the default sheet metal thickness, in drawing units. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smdefaultthickness-system-variable")
)

(
  :name "SMEXPORTOSMAPPROXIMATIONACCURACY"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Accuracy of the approximation: Controls absolute deviation between the smooth edge geometry of 3D part and its .osm representation with lines and arcs, during the SMEXPORTOSM command, in drawing units. The lower the value, the better the precision. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smexportosmapproximationaccuracy-system-variable")
)

(
  :name "SMEXPORTOSMMINIMALEDGELENGTH"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Minimal edge length: Controls the minimal edge length for the SMEXPORTOSM command, in drawing units. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smexportosmminimaledgelength-system-variable")
)

(
  :name "SMFORMFEATURESDOWNCOLOR"
  :type :short
  :default 6
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the form features down layer: Controls the color of the 'Form Features Down' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smformfeaturesdowncolor-system-variable")
)

(
  :name "SMFORMFEATURESDOWNLAYERLINETYPE"
  :type :string
  :default "CONTINUOUS"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Linetype of the form features down layer: Controls the linetype of the 'Form Features Down' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smformfeaturesdownlayerlinetype-system-variable")
)

(
  :name "SMFORMFEATURESDOWNLAYERLINEWEIGHT"
  :type :short
  :default -3
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Lineweight of the form features down layer: Controls the lineweight of the 'Form Features Down' layer, created by the SMUNFOLD and SMEXPORT2D commands. Values between -3 and 211 are accepted. -1=ByLayer -2=ByBlock -3=Default BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smformfeaturesdownlayerlineweight-system-variable")
)

(
  :name "SMFORMFEATURESUPCOLOR"
  :type :short
  :default 6
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the form features up layer: Controls the color of the 'Form Features Up' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smformfeaturesupcolor-system-variable")
)

(
  :name "SMFORMFEATURESUPLAYERLINETYPE"
  :type :string
  :default "CONTINUOUS"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Linetype of the form features up layer: Controls the linetype of the 'Form Features Up' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smformfeaturesuplayerlinetype-system-variable")
)

(
  :name "SMFORMFEATURESUPLAYERLINEWEIGHT"
  :type :short
  :default -3
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Lineweight of the form features up layer: Controls the lineweight of the 'Form Features Up' layer, created by the SMUNFOLD and SMEXPORT2D commands. Values between -3 and 211 are accepted. -1=ByLayer -2=ByBlock -3=Default BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smformfeaturesuplayerlineweight-system-variable")
)

(
  :name "SMHEMCREATECLOSEDHEMGAP"
  :type :real
  :default 0.02
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Closed Hem, Teardrop, and Round gap value: Controls the bend radius of a Closed hem and the gap between the base Flange and a Teardrop or Round hem, for the SMHEM command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smhemcreateclosedhemgap-system-variable")
)

(
  :name "SMJUNCTIONCREATEHEALCOINCIDENT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Heal coincident junction faces: Controls how junctions with coincident faces are recognized and converted to regular junctions, during the SMJUNCTIONCREATE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smjunctioncreatehealcoincident-system-variable")
)

(
  :name "SMOOTHMESHCONVERT"
  :type :short
  :default 2
  :read-only NIL
  :range (1 3)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Mesh conversion mode: Controls the conversion mode of meshes to 3D solids or surfaces, with the CONVTOSOLID or CONVTOSURFACE commands."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smoothmeshconvert-system-variable")
)

(
  :name "SMOVERALLANNOTATIONSLAYERCOLOR"
  :type :short
  :default 3
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the overall dimensions annotations layer: Controls the color of the 'Overall Dimensions' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smoverallannotationslayercolor-system-variable")
)

(
  :name "SMOVERALLANNOTATIONSLAYERLINETYPE"
  :type :string
  :default "CONTINUOUS"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Linetype of the overall annotation layer: Controls the linetype of the 'Overall Dimensions' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smoverallannotationslayerlinetype-system-variable")
)

(
  :name "SMOVERALLANNOTATIONSLAYERLINEWEIGHT"
  :type :short
  :default -3
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Lineweight of the overall annotation layer: Controls the lineweight of the 'Overall Dimensions' layer, created by the SMUNFOLD and SMEXPORT2D commands. Values between -3 and 211 are accepted. -1=ByLayer -2=ByBlock -3=Default BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smoverallannotationslayerlineweight-system-variable")
)

(
  :name "SMPARAMETRIZEHOLESPARAMETRIZATION"
  :type :short
  :default 3
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Hole parametrization: Controls how straight holes are converted, during the SMPARAMETRIZE command. If Convert holes to array is on, holes on flanges are converted into parametric, rectangular arrays. If Parametrize holes is on, holes, not already included in arrays, are constrained. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smparametrizeholesparametrization-system-variable")
)

(
  :name "SMREPAIRLOFTEDBENDMERGE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Merge lofted bends: Merges lofted bends that touch into a single lofted bend, during the SMREPAIR command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smrepairloftedbendmerge-system-variable")
)

(
  :name "SMROLLEDEDGEANNOTATIONSLAYERCOLOR"
  :type :short
  :default 5
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the rolled edge annotations text layer: Controls the color of the 'Rolled Edge Annotations' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smrollededgeannotationslayercolor-system-variable")
)

(
  :name "SMROLLEDEDGEANNOTATIONSLAYERTEXTHEIGHT"
  :type :real
  :default 0.01
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Height of the text: Controls the text height of the 'Rolled Edge Annotations' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smrollededgeannotationslayertextheight-system-variable")
)

(
  :name "SMROLLEDEDGEANNOTATIONSLAYERTEXTHEIGHTTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Type of the text height: Controls the text height type for the 'Rolled Edge Annotations' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smrollededgeannotationslayertextheighttype-system-variable")
)

(
  :name "SMROLLEDEDGELINESDOWNLAYERCOLOR"
  :type :short
  :default 1
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the rolled edge down lines layer: Controls the color of the 'Rolled Edge Down' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smrollededgelinesdownlayercolor-system-variable")
)

(
  :name "SMROLLEDEDGELINESDOWNLAYERLINETYPE"
  :type :string
  :default "Continuous"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Linetype of the rolled edge down lines layer: Controls the linetype of the 'Rolled Edge Down' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smrollededgelinesdownlayerlinetype-system-variable")
)

(
  :name "SMROLLEDEDGELINESDOWNLAYERLINEWEIGHT"
  :type :short
  :default -3
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Lineweight of the rolled edge down layer: Controls the lineweight of the 'Rolled Edge Down' layer, created by the SMUNFOLD and SMEXPORT2D commands."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smrollededgelinesdownlayerlineweight-system-variable")
)

(
  :name "SMROLLEDEDGELINESUPLAYERCOLOR"
  :type :short
  :default 1
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Color of the rolled edge up lines layer: Controls the color of the 'Rolled Edge Up' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smrollededgelinesuplayercolor-system-variable")
)

(
  :name "SMROLLEDEDGELINESUPLAYERLINETYPE"
  :type :string
  :default "Continuous"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Linetype of the rolled edge up lines layer: Controls the linetype of the 'Rolled Edge Up' layer, created by the SMUNFOLD and SMEXPORT2D commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smrollededgelinesuplayerlinetype-system-variable")
)

(
  :name "SMROLLEDEDGELINESUPLAYERLINEWEIGHT"
  :type :short
  :default -3
  :read-only NIL
  :range (-3 211)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Lineweight of the rolled edge up layer: Controls the lineweight of the 'Rolled Edge Up' layer, created by the SMUNFOLD and SMEXPORT2D commands."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smrollededgelinesuplayerlineweight-system-variable")
)

(
  :name "SMSMARTFEATURES"
  :type :short
  :default 3
  :read-only NIL
  :range (0 7)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Automatic update features after sheet metal commands: Controls how sheet metal features are rebuilt after sheet metal commands. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smsmartfeatures-system-variable")
)

(
  :name "SMSPLITAMBIGUOUSINPUT"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Ambiguous input behavior: Controls how the SMSPLIT command resolves issues when it can not detect a face, entity, point or 2D curve that it relates to. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smsplitambiguousinput-system-variable")
)

(
  :name "SMSPLITCONVERTBENDTOJUNCTION"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Convert bend to junction: Controls how a split that passes through a bend is solved with the SMSPLIT command. If on, the shortest side of the bend is automatically converted to a junction. If off, a split through a bend will retain the bend geometry on both sides of the split. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smsplitconvertbendtojunction-system-variable")
)

(
  :name "SMSPLITHEALCOINCIDENT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Heal coincident miter faces: Enables the Heal coincident miter faces option for the SMSPLIT command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smsplithealcoincident-system-variable")
)

(
  :name "SMSPLITORTHOGONALBENDSPLIT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Orthogonal bend split: Controls how a split that touches a bend is solved with the SMSPLIT command. If on, the split direction for a bend is orthogonal to the bend axis (changes to a 90° angle as it passes through the bend). If off, the split direction is tangential to the split curve (does not change direction as it passes through the bend). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smsplitorthogonalbendsplit-system-variable")
)

(
  :name "SMTARGETCAM"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Target CAM: Controls the target CAM system, for sheet metal parts unfolded with SMUNFOLD command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smtargetcam-system-variable")
)

(
  :name "SMUNFOLDAPPEARANCE"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Unfold appearance: Controls the text height for the SMUNFOLD command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/smunfoldappearance-system-variable")
)

(
  :name "SNAPANG"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Snap angle: Controls the rotation of snap, the grid, and the crosshair, for the current viewport, relative to the current UCS."
  :coupled ("setvar")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/snapang-system-variable")
)

(
  :name "SNAPBASE"
  :type :point
  :default (0 0)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Snap base: Controls the origin point of snap and the grid, in the current viewport, relative to the current UCS."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/snapbase-system-variable")
)

(
  :name "SNAPISOPAIR"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Snap isometric pair: Controls the current viewport's isometric plane (left, top or right), if the SNAPSTYL system variable is set to isometric . Press F5 function key to set the appropriate drawing plane: Left , Top or Right ."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/snapisopair-system-variable")
)

(
  :name "SNAPMARKERCOLOR"
  :type :short
  :default 122
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Snap marker color: Controls the color of snap markers. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/snapmarkercolor-system-variable")
)

(
  :name "SNAPMARKERSIZE"
  :type :short
  :default 8
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Snap marker size: Controls the size of snap markers. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/snapmarkersize-system-variable")
)

(
  :name "SNAPMARKERTHICKNESS"
  :type :short
  :default 2
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Snap marker thickness: Controls the thickness of the snap marker. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/snapmarkerthickness-system-variable")
)

(
  :name "SNAPMODE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Snap mode: Toggles snap On or Off for the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/snapmode-system-variable")
)

(
  :name "SNAPSTYL"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Snap style: Controls the snap style for the current viewport - rectangular or isometric."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/snapstyl-system-variable")
)

(
  :name "SNAPTYPE"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Snap type: Controls the snap type for the current viewport. For Adaptive Grid Snap , see also the ADAPTIVEGRIDSTEPSIZE system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/snaptype-system-variable")
)

(
  :name "SNAPUNIT"
  :type :point
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Snap unit: Controls the current viewport's snap spacing. Adjusts itself automatically to reflect the isometric snap, if SNAPSTYL is set to Isometric snap (1). Note: There is no snap in the Z direction."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/snapunit-system-variable")
)

(
  :name "SOLIDCHECK"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Solid check: Toggles the 3D solid validation for the current application session."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/solidcheck-system-variable")
)

(
  :name "SORTENTS"
  :type :short
  :default 127
  :read-only NIL
  :range (0 127)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sort entities: Controls the entity display sort order."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sortents-system-variable")
)

(
  :name "SPAADJUSTMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Adjust mode: Controls the adjustment mode used for triangle smoothing. Ignored if FACETRES is used. Adjust mode identifies which facet nodes are to be adjusted (smoothed) to other than their initial grid positions. Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spaadjustmode-system-variable")
)

(
  :name "SPACHECKLEVEL"
  :type :short
  :default 10
  :read-only NIL
  :range (0 70)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Check level: Check level used in AUDIT and SOLIDEDIT for checking ACIS entities. Audit is used to repair drawings that are open. The SOLIDEDIT command edits the faces, edges and bodies of 3D solids and 2D regions. Value 10 is the lowest, used for fast checking. Value 70 is the maximum, used for comprehensive time consuming check. Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spachecklevel-system-variable")
)

(
  :name "SPAGRIDASPECTRATIO"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Grid aspect ratio: Controls the aspect ratio of each cell in a grid. Ignored if the FACETRES system variable is in use. A value of 1 is square. This does not guarantee the aspect ratio of the facet, which may consist of only a part of a cell. Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spagridaspectratio-system-variable")
)

(
  :name "SPAGRIDMODE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Grid mode: Controls how grids are used in the mesh process. This variable is ignored if FACETRES is used. The grid mode specifies whether a grid is used and whether the points where the grid cuts the edges should be inserted into the edge discretization. Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spagridmode-system-variable")
)

(
  :name "SPAMAXFACETEDGELENGTH"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximum facet edge length: Controls the maximum length of a facet side. Ignored if the FACETRES system variable is used. A value of zero means uses defaults (recommend). CAUTION: Lengths that are too small cause high memory consumption and poor performance. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spamaxfacetedgelength-system-variable")
)

(
  :name "SPAMAXNUMGRIDLINES"
  :type :integer
  :default 3000
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Maximum number of grid lines: Controls the maximum number of grid subdivisions, this limits the face facet data size. Does not apply if the FACETRES system variable is in use. Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spamaxnumgridlines-system-variable")
)

(
  :name "SPAMINUGRIDLINES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Minimum number of U grid lines: ontrols the minimum number of U grid lines - the minimum number of grid lines generated in the U direction. Ignored if the FACETRES system variable is in use. Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spaminugridlines-system-variable")
)

(
  :name "SPAMINVGRIDLINES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Minimum number of V grid lines: Controls the minimum number of V grid lines - the minimum number of grid lines generated in the V direction. Ignored if the FACETRES system variable is in use. Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spaminvgridlines-system-variable")
)

(
  :name "SPANORMALTOL"
  :type :real
  :default 15.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Normal tolerance: Controls the maximum deviation allowed between two normals on two adjacent facet nodes, in degrees. This value is independent of the model size. This variable is ignored if the FACETRES system variable is on (1). Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spanormaltol-system-variable")
)

(
  :name "SPASURFACETOL"
  :type :real
  :default -1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Surface tolerance: Controls the maximum distance between a facet edge and the true surface. The value is dependent on the model size. This variable is ignored for output to STL and PDF if the FACETRES system variable is in use. Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spasurfacetol-system-variable")
)

(
  :name "SPATRIANGMODE"
  :type :short
  :default 1
  :read-only NIL
  :range (0 5)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Triangulation mode: Identifies what portion of a mesh is triangulated. Ignored if the FACETRES system variable is in use. Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spatriangmode-system-variable")
)

(
  :name "SPAUSEFACETRES"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Use FACETRES system variable: Use the FACETRES system variable in place of normal tolerances. Note: Spa is short for Spatial, the maker of ACIS. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/spausefacetres-system-variable")
)

(
  :name "SPLFRAME"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Spline frame: Displays control polygons for splines and spline-fit polylines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/splframe-system-variable")
)

(
  :name "SPLINESEGS"
  :type :short
  :default 8
  :read-only NIL
  :range (-32768 32767)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Spline segments: Controls how many line segments are generated when a spline is converted to a polyline with the PEDIT command. Values between -32768 and 32767 are accepted. For negative values, a fit-type curve is applied, composed of arc-segments, yields a smoother curve, but it takes longer to generate."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/splinesegs-system-variable")
)

(
  :name "SPLINETYPE"
  :type :short
  :default 6
  :read-only NIL
  :range (5 6)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Spline type: Controls the curve type generated by the Spline option of the PEDIT command: Quadratic B-spline or Cubic B-spline."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/splinetype-system-variable")
)

(
  :name "SRCHPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Support file search path: The file path for text fonts, customization files, plugins, drawings to insert, linetypes, and hatch patterns, not in the current folder. Separate file paths with semicolons (;). BricsCAD only"
  :coupled ("findfile" "load" "acet-pref-supportpath-list")
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/srchpath-system-variable")
)

(
  :name "SSFOUND"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sheet Set found: Displays the sheet set file name and path that is associated with the current drawing file."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/ssfound-system-variable")
)

(
  :name "SSLOCATE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sheet Set locate: Opens any associated sheets sets when a drawing is opened."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/sslocate-system-variable")
)

(
  :name "SSMAUTOOPEN"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sheet Set manager auto open: Opens Sheet Set panel automatically when a drawing is opened that is associated with a Sheet Set. The SSMAUTOOPEN and SSLOCATE system variables must both be switched on to display the Sheet Set automatically."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/ssmautoopen-system-variable")
)

(
  :name "SSMPOLLTIME"
  :type :short
  :default 15
  :read-only NIL
  :range (10 600)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sheet Set manager poll time: Controls the time interval between automatic refreshes of the status data in a Sheet Set. The SSMSHEETSTATUS system variable must be set to 2 for the timer to operate. Values between 10 and 600 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/ssmpolltime-system-variable")
)

(
  :name "SSMSHEETSTATUS"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sheet Set manager status: Controls how the status data in a Sheet Set is refreshed."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/ssmsheetstatus-system-variable")
)

(
  :name "SSMSTATE"
  :type :short
  :default 0
  :read-only T
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Sheet Set manager state: Controls if the Sheet Set Manager is active or not."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/ssmstate-system-variable")
)

(
  :name "STACKPANELTYPE"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Stack panel type: The style of stacked docking panel containers. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stackpaneltype-system-variable")
)

(
  :name "STAMPFONTSIZE"
  :type :real
  :default 0.2
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Font Size: Controls the font size for the plot stamp. See also the INCLUDEPLOTSTAMP system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stampfontsize-system-variable")
)

(
  :name "STAMPFONTSTYLE"
  :type :string
  :default "Arial"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Font Style: Controls the font style for the plot stamp. See also the INCLUDEPLOTSTAMP system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stampfontstyle-system-variable")
)

(
  :name "STAMPFOOTER"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Footer: Controls the footer for the plot stamp. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stampfooter-system-variable")
)

(
  :name "STAMPFOOTEROFFSETX"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Stamp footer X offset: Controls the offset of the plot stamp footer from the bottom of the printable area. See also the INCLUDEPLOTSTAMP system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stampfooteroffsetx-system-variable")
)

(
  :name "STAMPFOOTEROFFSETY"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Stamp footer Y offset: Controls the offset of the plot stamp footer from the bottom of the printable area. See also the INCLUDEPLOTSTAMP system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stampfooteroffsety-system-variable")
)

(
  :name "STAMPHEADER"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Header: Controls the header for the plot stamp. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stampheader-system-variable")
)

(
  :name "STAMPHEADEROFFSETX"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Stamp header X offset: Controls the offset of the plot stamp header from the top of the printable area. See also the INCLUDEPLOTSTAMP system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stampheaderoffsetx-system-variable")
)

(
  :name "STAMPHEADEROFFSETY"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Stamp header Y offset: Controls the offset of the plot stamp header from the top of the printable area. See also the INCLUDEPLOTSTAMP system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stampheaderoffsety-system-variable")
)

(
  :name "STAMPUNITS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Units: Controls the units for the font size of the plot stamp. See the INCLUDEPLOTSTAMP system variable. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stampunits-system-variable")
)

(
  :name "STANDARDSOPTIONS"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Standards validation options: Options to control the standards check procedure."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/standardsoptions-system-variable")
)

(
  :name "STANDARDSVIOLATION"
  :type :short
  :default 2
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Standards Violation Notification: Controls how a user is notified of standards violations. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/standardsviolation-system-variable")
)

(
  :name "STARTUP"
  :type :short
  :default 3
  :read-only NIL
  :range (0 4)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Startup: Controls the display of the Create New Drawing and Startup dialog boxes."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/startup-system-variable")
)

(
  :name "STATUSBAR"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Status bar: Controls the display of the Status bar. Note: The only reason to turn off the status bar is to gain a bit more drawing area. It is far more useful to leave it on"
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/statusbar-system-variable")
)

(
  :name "STEPSIZE"
  :type :real
  :default 2.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Step size: Controls the size of each step, in drawing units, when in walk or fly mode."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stepsize-system-variable")
)

(
  :name "STEPSPERSEC"
  :type :real
  :default 24.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Steps per second: Controls the number of steps per second, when in walk or fly mode. Values between 1.0 and 30.0 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stepspersec-system-variable")
)

(
  :name "STLPOSITIVEQUADRANT"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "STL export coordinates adjustment: Moves coordinates to all-positive values during an STL export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/stlpositivequadrant-system-variable")
)

(
  :name "STORYBAR"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Display Story Bar: Controls the visibility and position of the Story Bar . BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/storybar-system-variable")
)

(
  :name "STRUCTURETREECONFIG"
  :type :string
  :default "default.cst"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Structure Tree Configuration: Displays the name of the active Structure Tree Configuration file used by the Structure panel. Type SRCHPATH in the Command line to find the file. Loading a different CST file than the default file changes the way that the STRUCTUREPANEL command presents drawing data. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/structuretreeconfig-system-variable")
)

(
  :name "SURFTAB1"
  :type :short
  :default 6
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Surface tabulation 1: Controls the number of tabulations to be created for RULESURF and TABSURF commands. Also controls the mesh density in the M direction for REVSURF and EDGESURF commands. When extruding entities with arc segments: the SURFTAB1 system variable divides them in a number of equal length intervals. When revolving entities: the SURFTAB1 variable controls the number of segments of the revolution surface."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/surftab1-system-variable")
)

(
  :name "SURFTAB2"
  :type :short
  :default 6
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Surface tabulation 2: Controls the mesh density in the N direction for REVSURF and EDGESURF commands. The SURFTAB2 variable controls the number of segments of each arc segment in the revolved entity."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/surftab2-system-variable")
)

(
  :name "SURFTYPE"
  :type :short
  :default 6
  :read-only NIL
  :range (5 8)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Surface-fitting type: Controls the surface-fitting type used with the Desmooth option of the PEDIT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/surftype-system-variable")
)

(
  :name "SURFU"
  :type :short
  :default 6
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Surface U: Controls the surface density in the M direction and the U isolines density on surface entities for the Smooth option of the PEDIT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/surfu-system-variable")
)

(
  :name "SURFV"
  :type :short
  :default 6
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Surface V: Controls the surface density in the N direction and the V isolines density on surface entities for the Smooth option of the PEDIT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/surfv-system-variable")
)

(
  :name "SVGBLENDEDGRADIENTS"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Blended Gradients: Toggles the use of blended gradients for complex gradient fills for SVG export. The use of complex gradient fills makes the file size larger. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svgblendedgradients-system-variable")
)

(
  :name "SVGCOLORPOLICY"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Color Policy: Color policy for an SVG export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svgcolorpolicy-system-variable")
)

(
  :name "SVGDEFAULTIMAGEEXTENSION"
  :type :string
  :default ".png"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Default Image Extension: Controls the default image extension type. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svgdefaultimageextension-system-variable")
)

(
  :name "SVGGENERICFONTFAMILY"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded T
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Generic Font Family: Substitute font to use if the font is missing for SVG export. The following generic font families are supported in SVG: serif , sans-serif , cursive , fantasy , monospace . Sans-serif - fonts without serifs, like Arial Serif - fonts with serifs, like Times Roman Cursive - fonts that look handwritten Fantasy - unusual fonts Monospace - fonts where each character takes up the same space (non-proportional spacing), such as Courier BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svggenericfontfamily-system-variable")
)

(
  :name "SVGIMAGEBASE"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Image base path: The image file path for SVG export. If not set, absolute file paths are written to the SVG. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svgimagebase-system-variable")
)

(
  :name "SVGIMAGEURL"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Image Url: The file path for images for SVG export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svgimageurl-system-variable")
)

(
  :name "SVGLINEWEIGHTSCALE"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Line Weight Scale: Scales lineweights for an SVG export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svglineweightscale-system-variable")
)

(
  :name "SVGOUTPUTHEIGHT"
  :type :short
  :default 768
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Output Height: Page height, in pixels, for SVG export. Valid only if SVGSCALEFACTOR system variable is set to zero. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svgoutputheight-system-variable")
)

(
  :name "SVGOUTPUTWIDTH"
  :type :short
  :default 1024
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Output Width: Page width, in pixels, for SVG export. Valid only if SVGSCALEFACTOR system variable is set to zero. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svgoutputwidth-system-variable")
)

(
  :name "SVGPRECISION"
  :type :short
  :default 6
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Floating Point Precision: Number of decimal digits (as in printf(\"%.9g\",...) - 9 digits ) for an SVG export. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svgprecision-system-variable")
)

(
  :name "SVGSCALEFACTOR"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "SVG Scale Factor: Scales the SVG during an export. Dependent files need to be converted separately. 1 Drawing unit = X SVG pixel. If set to zero, scales the current view to fit within the page size set with the SVGOUTPUTWIDTH and SVGOUTPUTHEIGHT variables. If set to a positive value, SVG page size is calculated automatically to correspond to required scale. For example, 96dpi / 25.4 = 3.7795 - the corresponding scale factor for the conversion of 1 DWG unit into 1 mm SVG. B..."
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/svgscalefactor-system-variable")
)

(
  :name "SYSCODEPAGE"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "System code page: Displays the system code page, determined by the operating system."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/s/syscodepage-system-variable")
)

(
  :name "TABCONTROLHEIGHT"
  :type :short
  :default 25
  :read-only NIL
  :range (0 NIL)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tab control height in pixels (Mac & Linux): Controls the height of the document control tab, in pixels. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tabcontrolheight-system-variable")
)

(
  :name "TABMODE"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tablet mode: Allows the use of a tablet. Use the TABLET command to configure the tablet."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tabmode-system-variable")
)

(
  :name "TABSFIXEDWIDTH"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tabs fixed width (Mac & Linux): Applies the same width to all tabs, in the documents tab. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tabsfixedwidth-system-variable")
)

(
  :name "TANGENTLENGTHTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tangent Length Type: Sets default flow fitting tangent length type. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tangentlengthtype-system-variable")
)

(
  :name "TANGENTLENGTHVALUE"
  :type :real
  :default 0.0d0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tangent Length Value: Sets default flow fitting tangent length value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tangentlengthvalue-system-variable")
)

(
  :name "TARGET"
  :type :point3d
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Target: The coordinates for perspective projection of the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/target-system-variable")
)

(
  :name "TDCREATE"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Time/Date create: The time and date the drawing was created, in Julian Day format."
  :coupled ("menucmd")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tdcreate-system-variable")
)

(
  :name "TDINDWG"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Time/Date in drawing: The total current drawing edit time, in days. Format: >number of days<.>decimal fraction of a day<"
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tdindwg-system-variable")
)

(
  :name "TDUCREATE"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Time/Date universal create: The universal time and date the drawing was created, Julian Day format."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tducreate-system-variable")
)

(
  :name "TDUPDATE"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Time/Date update: The local time and date, the drawing was last saved or updated, in Julian Day format."
  :coupled ("menucmd")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tdupdate-system-variable")
)

(
  :name "TDUSRTIMER"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Time/Date user timer: The user-elapsed timer value. Start, stop and reset the timer with the TIME command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tdusrtimer-system-variable")
)

(
  :name "TDUUPDATE"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Time/Date universal update: The universal time and date the drawing was last saved or updated - in Julian Day format."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tduupdate-system-variable")
)

(
  :name "TEETANGENTLENGTHTYPE"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tee Length Type: Sets default tee tangent length type. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/teetangentlengthtype-system-variable")
)

(
  :name "TEETANGENTLENGTHVALUE"
  :type :real
  :default 0.5
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tee Length Value: Sets default tee tangent length value. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/teetangentlengthvalue-system-variable")
)

(
  :name "TEMPLATEPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Template path: Specifies the file path used for the Templates folder. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/templatepath-system-variable")
)

(
  :name "TEMPPREFIX"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Temporary prefix: The folder name for temporary files."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tempprefix-system-variable")
)

(
  :name "TEXTANGLE"
  :type :real
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Text angle: The angle of the last added text entity. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/textangle-system-variable")
)

(
  :name "TEXTED"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text editor for single line text entities: Controls the editor type used for single line text entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/texted-system-variable")
)

(
  :name "TEXTEDITMODE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text edit mode: Controls if DDEDIT command automatically repeats entity selections or not."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/texteditmode-system-variable")
)

(
  :name "TEXTEVAL"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text evaluation: Controls the interpretation of Command line text strings. When the TEXTEVAL system variable is set to 1, this command evaluates LISP expressions: Text: (* pi 2) The result of the equation (pi x 2) is placed as text: 6.283185"
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/texteval-system-variable")
)

(
  :name "TEXTFILL"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text fill: Controls if TrueType fonts are filled or outlined for renders and the PSOUT command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/textfill-system-variable")
)

(
  :name "TEXTQLTY"
  :type :short
  :default 50
  :read-only NIL
  :range (0 100)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text quality (Mac & Linux): Controls the smoothness of TrueType fonts for plot and render. Values between 0 and 100 are accepted. A value of zero means no smoothing. A value of 100 is maximum smoothing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/textqlty-system-variable")
)

(
  :name "TEXTSIZE"
  :type :real
  :default 2.5
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text size: The default height for new text entities, has no effect if the current text style has a fixed height."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/textsize-system-variable")
)

(
  :name "TEXTSTYLE"
  :type :string
  :default "Standard"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text style: The current text style."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/textstyle-system-variable")
)

(
  :name "TEXTUREMAPPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Texture map path: The file paths for texture maps. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/texturemappath-system-variable")
)

(
  :name "THICKNESS"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Thickness: The default thickness for 2D entities."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/thickness-system-variable")
)

(
  :name "THREADDISPLAY"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Thread representation: Controls the thread display for part created, during the -BMHARDWARE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/threaddisplay-system-variable")
)

(
  :name "THUMBSIZE"
  :type :short
  :default 3
  :read-only NIL
  :range (0 8)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Thumbnail preview image size: Controls the maximum generated size for thumbnail previews, in pixels."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/thumbsize-system-variable")
)

(
  :name "TILEMODE"
  :type :short
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tile mode: Switches the active tab, model or paper space."
  :coupled ("vports" "setview")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tilemode-system-variable")
)

(
  :name "TILEMODELIGHTSYNCH"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tile mode light synch: Synchronizes lighting in all model space viewports (Internal use only)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tilemodelightsynch-system-variable")
)

(
  :name "TIMEZONE"
  :type :short
  :default -8000
  :read-only NIL
  :range (-12000 13000)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Timezone: Controls the time zone for the sun. Note: Setting a geographic location also controls the time zone."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/timezone-system-variable")
)

(
  :name "TOOLBARMARGIN"
  :type :short
  :default 0
  :read-only NIL
  :range (0 63)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Toolbar margin: Controls the toolbar row margin size, in pixels. Values between 0 and 63 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/toolbarmargin-system-variable")
)

(
  :name "TOOLBUTTONSIZE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tool button size: Controls size of Toolbar buttons and icons. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/toolbuttonsize-system-variable")
)

(
  :name "TOOLICONPADDING"
  :type :short
  :default 4
  :read-only NIL
  :range (0 15)
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tool icon padding: Controls the size of toolbar buttons. Changes the spacing, in pixels, does not change the size of the icons. Values between 0 and 15 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tooliconpadding-system-variable")
)

(
  :name "TOOLPALETTEPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tool palettes path: Specify the path(s) to the Tool Palettes."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/toolpalettepath-system-variable")
)

(
  :name "TOOLTIPDELAY"
  :type :short
  :default 500
  :read-only NIL
  :range (0 NIL)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tooltip delay: Controls the delay for tooltips (hover tips) to appear, in milliseconds. Applies only if tooltips are enabled in the TOOLTIPS system variable. Values between 0 and 500 are accepted. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tooltipdelay-system-variable")
)

(
  :name "TOOLTIPS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tooltips: Toggles the display of tooltips for toolbars, the Ribbon, the Quad and the Properties."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tooltips-system-variable")
)

(
  :name "TPSTATE"
  :type :short
  :default 0
  :read-only T
  :range (0 1)
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tool Palettes Panel state: The status of the Tool Palettes panel."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tpstate-system-variable")
)

(
  :name "TRACEWID"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Trace width: Controls the default width for new traces, for the TRACE command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tracewid-system-variable")
)

(
  :name "TRACKPATH"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Track path: Controls the display of polar and entity snap tracking paths."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/trackpath-system-variable")
)

(
  :name "TRANSPARENCYDISPLAY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Transparency display: Displays transparencies."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/transparencydisplay-system-variable")
)

(
  :name "TRAYICONS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tray icons: Toggles the display of the notification icons in the Status bar."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/trayicons-system-variable")
)

(
  :name "TRAYNOTIFY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tray notify: Toggles the display of notification balloons."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/traynotify-system-variable")
)

(
  :name "TRAYTIMEOUT"
  :type :short
  :default 0
  :read-only NIL
  :range (0 60)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tray timeout: Controls the display time for service notifications, in seconds. Applies only if the TRAYNOTIFY system variable is on. Values between 0 and 60 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/traytimeout-system-variable")
)

(
  :name "TREEDEPTH"
  :type :short
  :default 3020
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tree depth: Controls the maximum number of times an index can be divided into branches. A value of zero suppresses the spatial index entirely, entities are always processed in database order. Positive numbers turn on spatial indexing, an integer, five digits maximum, the first three digits refer to model space, the remaining digits refer to paper space. For negative numbers Z coordinate is ignored in model space, recommended for 2D drawings."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/treedepth-system-variable")
)

(
  :name "TREEMAX"
  :type :integer
  :default 10000000
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Tree maximum: Limits the use of memory, limits the number of nodes in the spatial index (oct-tree) when a drawing is regenerated. By imposing a fixed limit with TREEMAX, you can load drawings created on systems with more memory than your system and with a larger TREEDEPTH than your system can handle. These drawings, if left unchecked, have an oct-tree large enough to eventually consume more memory than is available to your computer. TREEMAX also provides a safeguard agains..."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/treemax-system-variable")
)

(
  :name "TRIMEDGES"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "TRIM and EXTEND to hatches: Controls whether hatch patterns are considered when trimming and extending in Quick mode."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/trimedges-system-variable")
)

(
  :name "TRIMEXTENDMODE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "TRIM and EXTEND mode: Controls how TRIM and EXTEND commands use streamlined inputs."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/trimextendmode-system-variable")
)

(
  :name "TRIMMODE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Trim mode: Controls if the length of selected entities or polyline segments for chamfers and fillets are adjusted (trimmed or lengthened)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/trimmode-system-variable")
)

(
  :name "TRUSTEDPATHS"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Trusted executable file locations: File path(s) to use to load executable files. Separate file paths with semicolons (;)"
  :coupled ("load" "open" "findtrustedfile")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/trustedpaths-system-variable")
)

(
  :name "TSPACEFAC"
  :type :real
  :default 1.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text space factor: Controls the line spacing distance of multiline text, measured as a multiplier of text height. Values between 0.25 and 4.0 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tspacefac-system-variable")
)

(
  :name "TSPACETYPE"
  :type :short
  :default 1
  :read-only NIL
  :range (1 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text space type: Controls the type of line spacing used for multiline text. At least: adjusts line spacing based on the tallest character(s) in a line Exactly: uses the specified line spacing, regardless of individual character sizes Note: The mtexts created with the MLEADER command are also influenced by this system variable's value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tspacetype-system-variable")
)

(
  :name "TSTACKALIGN"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text stack align: Controls the vertical alignment of stacked text."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tstackalign-system-variable")
)

(
  :name "TSTACKSIZE"
  :type :short
  :default 70
  :read-only NIL
  :range (25 125)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Text stack size: Controls the stacked text height, as a percentage, relative to the height of the selected text. Values between 25 and 125 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tstacksize-system-variable")
)

(
  :name "TTFASTEXT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "TrueType Text displaying mode: Controls if TrueType text is drawn as vectorized graphics or as text."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/ttfastext-system-variable")
)

(
  :name "TUTORIALSONSTARTPAGE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Tutorials on start page: Switch to control whether tutorials can be accessed from the start page. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/t/tutorialsonstartpage-system-variable")
)

(
  :name "UCSAXISANG"
  :type :real
  :default 90.0d0
  :read-only NIL
  :range (5 180)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS axis angle: Controls the default rotation angle around the X, Y, or Z axis, for the UCS command. Values between 5 and 180 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsaxisang-system-variable")
)

(
  :name "UCSBASE"
  :type :string
  :default "WORLD"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS base: The name of the UCS that defines the orthographic UCS."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsbase-system-variable")
)

(
  :name "UCSDETECT"
  :type :short
  :default 1
  :read-only NIL
  :range (-3 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS detect: Controls the dynamic UCS behavior. Dynamic UCS is a temporary UCS that activates automatically when the cursor hovers over a face, region or 2D entity. A negative value is the same as 0, but helps in storing the earlier value."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsdetect-system-variable")
)

(
  :name "UCSFOLLOW"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS follow: Controls if a plan view (a top view zoomed to extents) is generated automatically whenever the UCS changes. If on, turn off the UCSDETECT system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsfollow-system-variable")
)

(
  :name "UCSICON"
  :type :short
  :default 3
  :read-only NIL
  :range (0 3)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS icon: Controls the display and position of the UCS icon for the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsicon-system-variable")
)

(
  :name "UCSICONPOS"
  :type :short
  :default 1
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "UCS icon position: Controls the location of the UCS icon when the origin point is not visible. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsiconpos-system-variable")
)

(
  :name "UCSNAME"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS name: The name of the UCS for the current viewport, in the current workspace."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsname-system-variable")
)

(
  :name "UCSORG"
  :type :point3d
  :default (0 0 0)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS origin: The current coordinate system's origin point for the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsorg-system-variable")
)

(
  :name "UCSORTHO"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS orthographic: Sets the UCS to follow the current view, automatically switches the drawing plane to match the current view plane. Only works if an orthographic view is selected with the -VIEW command or the LookFrom widget. Does not work if the NAVVCUBEORIENT system variable is set to UCS."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsortho-system-variable")
)

(
  :name "UCSVIEW"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS view: Controls if the current UCS is saved with a named view."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsview-system-variable")
)

(
  :name "UCSVP"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS viewports: Controls if the UCS in all viewports is fixed, or changes to reflect the currently active viewport's UCS."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsvp-system-variable")
)

(
  :name "UCSXDIR"
  :type :point3d
  :default (1 0 0)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS X direction: The X direction for the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsxdir-system-variable")
)

(
  :name "UCSYDIR"
  :type :point3d
  :default (0 1 0)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "UCS Y direction: The Y direction for the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/ucsydir-system-variable")
)

(
  :name "UNDOCTL"
  :type :short
  :default 5
  :read-only T
  :range NIL
  :bitcoded T
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Undo control: Controls the behavior of the UNDO command."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/undoctl-system-variable")
)

(
  :name "UNDOMARKS"
  :type :short
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Undo marks: Shows the current number of marks placed in the Undo control using the MARK option. The MARK and BACK options are not available if a group is currently active."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/undomarks-system-variable")
)

(
  :name "UNITESURFACES"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Unite adjacent surfaces: Unites extruded/revolved surfaces that touch. The UNITESURFACES system variable is one of the four system variables found under the Extrude mode group. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/unitesurfaces-system-variable")
)

(
  :name "UNITMODE"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Unit mode: Controls how Imperial units are displayed."
  :coupled ("rtos" "angtos")
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/unitmode-system-variable")
)

(
  :name "USECOMMUNICATOR"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Use Communicator: Shows if the Communicator for BricsCAD is in use. If active, also shows the license type. 0: no license, Communicator for BricsCAD import and export formats are not available. 1: trial, runs Communicator for BricsCAD in trial mode, expiring after 30 days. 2: full, runs the full Communicator for BricsCAD import-export set. If the license is changed, the new level comes into effect after restarting the program. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/usecommunicator-system-variable")
)

(
  :name "USENEWSTATUSBAR"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Status Bar Preview: Determines the type of status bar that is displayed. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/usenewstatusbar-system-variable")
)

(
  :name "USERI1"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User integer 1: First of 5 variables that can be used to store integer values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/useri1-system-variable")
)

(
  :name "USERI2"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User integer 2: Second of 5 variables that can be used to store integer values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/useri2-system-variable")
)

(
  :name "USERI3"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User integer 3: Third of 5 variables that can be used to store integer values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/useri3-system-variable")
)

(
  :name "USERI4"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User integer 4: Fourth of 5 variables that can be used to store integer values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/useri4-system-variable")
)

(
  :name "USERI5"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User integer 5: Fifth of 5 variables that can be used to store integer values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/useri5-system-variable")
)

(
  :name "USERR1"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User real 1: First of 5 variables that can be used to store real numerical values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/userr1-system-variable")
)

(
  :name "USERR2"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User real 2: Second of 5 variables that can be used to store real numerical values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/userr2-system-variable")
)

(
  :name "USERR3"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User real 3: Third of 5 variables that can be used to store real numerical values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/userr3-system-variable")
)

(
  :name "USERR4"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User real 4: Fourth of 5 variables that can be used to store real numerical values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/userr4-system-variable")
)

(
  :name "USERR5"
  :type :real
  :default 0.0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User real 5: Fifth of 5 variables that can be used to store real numerical values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/userr5-system-variable")
)

(
  :name "USERS1"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User string 1: First of 5 variables that can be used to store string values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/users1-system-variable")
)

(
  :name "USERS2"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User string 2: Second of 5 variables that can be used to store string values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/users2-system-variable")
)

(
  :name "USERS3"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User string 3: Third of 5 variables that can be used to store string values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/users3-system-variable")
)

(
  :name "USERS4"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User string 4: Fourth of 5 variables that can be used to store string values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/users4-system-variable")
)

(
  :name "USERS5"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "User string 5: Fifth of 5 variables that can be used to store string values."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/users5-system-variable")
)

(
  :name "USESTANDARDOPENFILEDIALOG"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Use standard open file dialog (Windows): Uses a standard (non-customizable) dialog for the OPEN, SAVEAS and INSERT commands (Windows only). See also the DRAWINGPATH, BLOCKSPATH and PLACESBARFOLDER system variables. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/u/usestandardopenfiledialog-system-variable")
)

(
  :name "VBAMACROS"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Enable macros: Enables macros when a VBA-project is loaded. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/vbamacros-system-variable")
)

(
  :name "VENDORNAME"
  :type :string
  :default "Bricsys"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Vendor name (obsolete): Shows the vendor name. BricsCAD only Read-only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/vendorname-system-variable")
)

(
  :name "VERBOSEBIMSECTIONUPDATE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Additional diagnostics while section update: Displays additional diagnostics for the BIMSECTIONUPDATE command. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/verbosebimsectionupdate-system-variable")
)

(
  :name "VERSIONCONTROLCONFIGPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Version Control config path: The file path used to store version control settings. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/versioncontrolconfigpath-system-variable")
)

(
  :name "VERSIONCONTROLDOWNLOADPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Version Control download path: The file path used to store version control projects. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/versioncontroldownloadpath-system-variable")
)

(
  :name "VERSIONCUSTOMIZABLEFILES"
  :type :string
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :preference
  :saved-in :preference
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Version customizable files: Shows the current version of the CUI and PGP files."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/versioncustomizablefiles-system-variable")
)

(
  :name "VIEWCTR"
  :type :point3d
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "View center: The coordinates for the center point of the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/viewctr-system-variable")
)

(
  :name "VIEWDIR"
  :type :point3d
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "View direction: Displays the view direction of the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/viewdir-system-variable")
)

(
  :name "VIEWMODE"
  :type :short
  :default (:unknown)
  :read-only T
  :range (0 31)
  :bitcoded T
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "View mode: The current viewport's View mode. If off, the front clipping plane passes through the camera point (vectors behind the camera are not displayed) unless front-clipping is off. If Front clip not at eye is on, the FRONTZ system variable controls the front clipping plane."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/viewmode-system-variable")
)

(
  :name "VIEWSIZE"
  :type :real
  :default 0.0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "View size: The height of the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/viewsize-system-variable")
)

(
  :name "VIEWTWIST"
  :type :real
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "View twist: The view twist angle relative to the WCS for the current viewport."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/viewtwist-system-variable")
)

(
  :name "VIEWUPDATEAUTO"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Automatically update drawing views: Turns on automatic updates to drawing views (in paper space) when the source model changes. When turned off, the VIEWUPDATE command manually updates the drawing views created by VIEWBASE and VIEWSECTION commands. This only works in paper space."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/viewupdateauto-system-variable")
)

(
  :name "VISRETAIN"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Visibility retain: Controls the visibility, color, linetype and lineweight of an XRef, and if path changes to nested XRefs are saved. If the PSTYLEPOLICY system variable is off (0), also controls the plotstyles of XRef-dependent layers. If Off (0): Changes made to XRefs-dependent layers in the current drawing are valid in the current session only and are not saved with the drawing. When the current drawing is reopened, the layer table is reloaded from the reference drawing..."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/visretain-system-variable")
)

(
  :name "VOLUMEPREC"
  :type :short
  :default -1
  :read-only NIL
  :range (-1 8)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Volume precision: Controls the number of decimal places displayed for volumes, if volume properties are formatted with the PROPUNITS system variable. If negative, LUPREC (Linear Unit Precision) is used. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/volumeprec-system-variable")
)

(
  :name "VOLUMEUNITS"
  :type :string
  :default "in ft mi µm mm cm m km"
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Volume units: Controls a list of units used to display volume, if volume properties are formatted with the PROPUNITS system variable. If empty, all volumes match the drawing. Note: The string contains a space-separated list of unit abbreviations. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/volumeunits-system-variable")
)

(
  :name "VPMAXIMIZEDSTATE"
  :type :integer
  :default 0
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Viewport maximized: Displays a value to indicate if the viewport is maximized. Note: You cannot plot or publish when the viewport is maximized. This system variable is available only at the Command line."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/vpmaximizedstate-system-variable")
)

(
  :name "VPROTATEASSOC"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Rotate view: Rotates a view with the viewport, in paper space."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/vprotateassoc-system-variable")
)

(
  :name "VSMAX"
  :type :point3d
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Virtual screen maximum: The current viewport's upper-right corner coordinates."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/vsmax-system-variable")
)

(
  :name "VSMIN"
  :type :point3d
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Virtual screen minimum: The current viewport's lower-left corner coordinates."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/vsmin-system-variable")
)

(
  :name "VTDURATION"
  :type :short
  :default 750
  :read-only NIL
  :range (0 5000)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "View transition duration: Controls the duration of animated view transitions in milliseconds. Values between 0 and 5000 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/vtduration-system-variable")
)

(
  :name "VTENABLE"
  :type :short
  :default 3
  :read-only NIL
  :range (0 7)
  :bitcoded T
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Enable view transitions: Enables animation transitions during pan, zoom and rotation view actions in model space. See also, the VTFPS system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/vtenable-system-variable")
)

(
  :name "VTFPS"
  :type :short
  :default 7
  :read-only NIL
  :range (1 30)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "View transition minimum FPS: Controls the minimum FPS required to enable animated view transitions. Values between 1 and 30 are accepted. The default value is 7, which means that the redraw time should take less than 143 (=1000/7) milliseconds. If the computer is not capable to redraw the view fast enough, no animation will be available."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/v/vtfps-system-variable")
)

(
  :name "WARNINGMESSAGES"
  :type :integer
  :default 1048575
  :read-only NIL
  :range NIL
  :bitcoded T
  :scope :preference
  :saved-in :preference
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Warning messages: Controls which warning messages are displayed. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/warningmessages-system-variable")
)

(
  :name "WHIPARC"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Whip arcs: Controls if circles and circular arcs display as true (smooth) circles or as a series of angular lines."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/whiparc-system-variable")
)

(
  :name "WHIPTHREAD"
  :type :short
  :default 0
  :read-only NIL
  :range (0 3)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Whip thread: Controls if the REGEN and REDRAW commands use multithreading, if the machine has multiple processors (Not yet supported). When multithreaded processing is used for redraw operations (value 2 or 3), the order of entities specified with the DRAWORDER command is not guaranteed to be preserved for display but is preserved for plotting."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/whipthread-system-variable")
)

(
  :name "WINDOWAREACOLOR"
  :type :short
  :default 150
  :read-only NIL
  :range (1 255)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Window area color: Controls the color for window selection areas (left-right). It has effect only when SELECTIONAREA system variable is on."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/windowareacolor-system-variable")
)

(
  :name "WIPEOUTFRAME"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Wipeout frame: Controls the display of frames for wipeout entities, if the FRAME system variable is set to Use individual system variables (3)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wipeoutframe-system-variable")
)

(
  :name "WMFBKGND"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Windows Meta File background: Controls how the background of a WMF (Windows Meta File) or Copy Clip is created and displayed in other applications."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wmfbkgnd-system-variable")
)

(
  :name "WMFFOREGND"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Windows Meta File foreground: Controls how the foreground of a WMF (Windows Meta File) or Copy Clip is created and displayed in other applications. WMFFOREGND applies only when WMFBKGND is set to 0."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wmfforegnd-system-variable")
)

(
  :name "WMFTTFASTEXT"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "TrueType Text mode for Windows Meta File: Controls if TrueType text is exported as vectorized graphics or as text to a WMF (Windows Meta File). BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wmfttfastext-system-variable")
)

(
  :name "WNDLMAIN"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Main window state: The state of the main graphics window. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wndlmain-system-variable")
)

(
  :name "WNDLSCRL"
  :type :integer
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :workspace
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Window scrollbars (Windows): Controls the display of scrollbars on the main graphics window. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wndlscrl-system-variable")
)

(
  :name "WNDLTEXT"
  :type :short
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Text window state: The text window status. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wndltext-system-variable")
)

(
  :name "WNDPMAIN"
  :type :point
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Main window top-left: The top-left position of the main graphics window. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wndpmain-system-variable")
)

(
  :name "WNDPTEXT"
  :type :point
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Text window top left: The top-left position of the text window. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wndptext-system-variable")
)

(
  :name "WNDSMAIN"
  :type :point
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Main window size: The size of the main graphics window. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wndsmain-system-variable")
)

(
  :name "WNDSTEXT"
  :type :point
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad nil :bricscad "V20+")
  :vendor :bricscad
  :divergence NIL
  :summary "Text window size: The size of the text window. BricsCAD only"
  :coupled ()
  :source (:autocad NIL :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wndstext-system-variable")
)

(
  :name "WORLDUCS"
  :type :integer
  :default (:unknown)
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "World UCS: Displays if the UCS matches the WCS or not."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/worlducs-system-variable")
)

(
  :name "WORLDVIEW"
  :type :short
  :default 1
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "World view: Controls if the DVIEW or VPOINT commands change the current UCS to the WCS."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/worldview-system-variable")
)

(
  :name "WRITESTAT"
  :type :integer
  :default 1
  :read-only T
  :range NIL
  :bitcoded NIL
  :scope :session
  :saved-in :session
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Write status: The state of the open drawing - read-only or writable. Used in LISP to determine the write status of drawing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/writestat-system-variable")
)

(
  :name "WSAUTOSAVE"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Workspace autosave: Automatically saves workspace changes."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wsautosave-system-variable")
)

(
  :name "WSCURRENT"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Current workspace: The name of the current workspace."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/w/wscurrent-system-variable")
)

(
  :name "XCLIPFRAME"
  :type :short
  :default 2
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Xref clipping frame: Controls the display of XRef and Block Reference clipping boundaries, if the FRAME system variable is set to Use individual system variables (3)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/x/xclipframe-system-variable")
)

(
  :name "XDWGFADECTL"
  :type :short
  :default 70
  :read-only NIL
  :range (-90 90)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "XRef database fade control: Controls the transparency for XRefs. Values between -90 and 90 are accepted. Negative values disable fading."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/x/xdwgfadectl-system-variable")
)

(
  :name "XEDIT"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "XRef editable: Allows in-place editing on the current drawing, if it is referenced in another drawing."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/x/xedit-system-variable")
)

(
  :name "XFADECTL"
  :type :short
  :default 50
  :read-only NIL
  :range (0 90)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Reference editing fade control: Controls the transparency for XRefs during edit mode. This system variable affects only the entities that are not being edited in the reference. Values between 0 and 90 are accepted. A value of zero means fully opaque. A value of 90 means maximum transparency."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/x/xfadectl-system-variable")
)

(
  :name "XLOADCTL"
  :type :short
  :default 1
  :read-only NIL
  :range (0 2)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "XRef load control: Controls XRef demand loading and if a copy or the original drawing is opened (Not yet supported)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/x/xloadctl-system-variable")
)

(
  :name "XLOADPATH"
  :type :string
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "XRef load path: Controls a path to store temporary copies of demand-loaded XRefs. See also the XREFCTL system variable."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/x/xloadpath-system-variable")
)

(
  :name "XNOTIFYTIME"
  :type :short
  :default 5
  :read-only NIL
  :range (0 10080)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Xnotify time: Controls how often the program checks for modified XRefs, images and PDF documents, in minutes. This is if XREFNOTIFY, IMAGENOTIFY and/or PDFNOTIFY is ON. Values between 0 and 10,080 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/x/xnotifytime-system-variable")
)

(
  :name "XREFCTL"
  :type :integer
  :default (:unknown)
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "XRef control: Creates XRef log files (XLG)."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/x/xrefctl-system-variable")
)

(
  :name "XREFNOTIFY"
  :type :integer
  :default 1
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "XRef notify: Displays a warning, when a drawing is opened, if there are missing XRefs."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/x/xrefnotify-system-variable")
)

(
  :name "XREFOVERRIDE"
  :type :short
  :default 0
  :read-only NIL
  :range (0 1)
  :bitcoded NIL
  :scope :drawing
  :saved-in :drawing
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "XRef override: Controls the display of entity visual properties (such as color, linetype, lineweight, transparency, or plot style) on referenced layers. If 0: When the properties of the entities on the XREF drawing are set to ByLayer, any changes to the xref layer properties are displayed in the current drawing. If 1: When the properties of the entities on the XREF drawing are not set to ByLayer, entities on xref layers are treated as if their properties are set to ByLayer..."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/x/xrefoverride-system-variable")
)

(
  :name "ZOOMFACTOR"
  :type :short
  :default 40
  :read-only NIL
  :range (3 100)
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Zoom factor: Controls the incremental zoom change with respect to the mouse-wheel. When zooming in, the incremental step decreases gradually allowing to focus on a particularly detail easily. Values between 3 and 100 are accepted."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/z/zoomfactor-system-variable")
)

(
  :name "ZOOMWHEEL"
  :type :short
  :default 0
  :read-only NIL
  :range NIL
  :bitcoded NIL
  :scope :registry
  :saved-in :registry
  :versions (:autocad "all" :bricscad "V20+")
  :vendor :both
  :divergence NIL
  :summary "Mouse wheel zoom direction: Toggles the mouse wheel zoom direction."
  :coupled ()
  :source (:autocad "AutoCAD 2026: per-sysvar GUID on help.autodesk.com (cross-checked via name)" :bricscad "https://help.bricsys.com/en-us/document/system-variable-reference/z/zoomwheel-system-variable")
)

