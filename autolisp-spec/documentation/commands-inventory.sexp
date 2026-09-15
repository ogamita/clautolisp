;;;; -*- Mode: Lisp; coding: utf-8 -*-
;;;; Commands inventory feeding the autolisp-spec Commands chapter.
;;;; Harvested from help.autodesk.com (2026 ENU) + help.bricsys.com (V25).
;;;; One plist per command, sorted by :NAME. Facts come only from the
;;;; cited vendor pages; an absent fact is NIL. Generated/merged by
;;;; scripts/merge-command-parts.lisp — do not hand-edit.
;;;; Keys, in order: NAME CATEGORY ALIASES INTL-NAME SYNOPSIS OPTIONS ARGUMENTS DESCRIPTION AVAILABILITY AUTOCAD-VERSIONS BRICSCAD-VERSIONS SOURCE-AUTOCAD SOURCE-BRICSCAD

(
(:name "-ARRAY"
 :category :MODIFY
 :aliases NIL
 :intl-name "_-ARRAY"
 :synopsis "Creates a static polar or rectangular array of entities through the command line."
 :options ("Rectangular" "Polar")
 :arguments "Select objects; array type (Rectangular/Polar); for Rectangular: rows, columns, distance between rows, distance between columns; for Polar: center point, base, number of items, angle to fill, angle between items, rotate arrayed objects."
 :description "Generates nonassociative 2D or 3D arrays of entities using command-line input rather than a dialog box, supporting rectangular (rows and columns) and polar (around a center point) patterns."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8336B4CD-5375-4290-BD08-7D9E022741F6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-array/V25/EN_US")

(:name "-ATTDEF"
 :category :ATTRIBUTE
 :aliases ("-AT")
 :intl-name "_-ATTDEF"
 :synopsis "Creates an attribute definition for storing data in a block, at the command line."
 :options ("Invisible" "Constant" "Verify" "Preset" "Lock position"
           "Annotative" "Multiple lines")
 :arguments "Attribute modes (toggle Constant/Invisible/Preset/Verify/Lock position/Annotative/Multiple lines); attribute tag name; prompt text; default value; text start point; text style; justification; height; rotation angle."
 :description "Defines attribute data used by blocks at the command line, for use in macros, scripts, and LISP routines. Attributes can store information such as part numbers and product names and be configured with various modes."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5C99524B-B5BB-4067-AE18-BD3575F29DBF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-attdef/V25/EN_US")

(:name "-ATTEXT"
 :category :ATTRIBUTE
 :aliases ("-AX")
 :intl-name "_-ATTEXT"
 :synopsis "Copies data from block attributes to a text file through the command line."
 :options ("CDF" "SDF" "DXF" "Objects")
 :arguments "Choose extract format (CDF comma-delimited / SDF space-delimited / DXF), or select objects (Objects/Entities); a template file must already exist; specify the output file."
 :description "Extracts attribute data from blocks in a drawing and exports it to a file in comma-delimited (CDF), space/fixed-width (SDF), or Drawing Interchange (DXF) format. A template file must exist before using the command."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BE49A430-DACA-4B9C-A0B0-34EB55D0EE26.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-attext/V25/EN_US")

(:name "-BEDIT"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-BEDIT"
 :synopsis "Opens the block definition in the Block Editor from the command prompt."
 :options ("?" "*")
 :arguments "Block name to open an existing block (or an unused name to create a new block); or ? to list existing blocks (* for the complete list)."
 :description "Edits the entities that make up a block in the Block Editor environment after entering the block name at the command line, and can also create new blocks."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8140793D-79BF-4A31-B062-3F1F6B6A2EB4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-bedit/V25/EN_US")

(:name "-BLOCK"
 :category :BLOCK
 :aliases ("-B")
 :intl-name "_-BLOCK"
 :synopsis "Groups entities into a block definition from selected objects, at the command line."
 :options ("?" "Annotative")
 :arguments "Block name (or ? to list existing blocks); insertion base point; Annotative option; select entities to group; paper space viewport orientation option."
 :description "Combines multiple selected entities into a single named block object, with options for insertion base point, annotative scaling, and viewport orientation control in paper space."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-816B2D9C-F518-4E8B-971F-08E0E43006E7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-block/V25/EN_US")

(:name "-BOUNDARY"
 :category :DRAW
 :aliases ("-BO")
 :intl-name "_-BOUNDARY"
 :synopsis "Creates closed polylines or regions from bounding entities using command-line input."
 :options ("Advanced" "Boundary" "Island" "Undo" "Exit")
 :arguments "Specify an internal point within an enclosed area; optionally use Advanced options to set boundary set, island detection, and object type (region or polyline); pick further points or press Enter to finish."
 :description "Generates closed polylines or regions by defining boundaries around enclosed areas from a specified internal point, with advanced options controlling boundary set, island detection, and output object type."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B95DD3D4-BDEA-40C0-85CD-1C1CD61BBDA7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-boundary/V25/EN_US")

(:name "-COLOR"
 :category :SYSTEM
 :aliases ("-COL" "-COLOUR")
 :intl-name "_-COLOR"
 :synopsis "Sets the current working color for new objects, through the command line."
 :options ("ByLayer" "ByBlock")
 :arguments "Enter a color name (Red, Yellow, Green, Cyan, Blue, Magenta, White, ByLayer, ByBlock), an ACI index number, an RGB true-color value, or a color book name."
 :description "Sets the color for new objects from the command prompt, accepting an AutoCAD Color Index name or number, a true color as RGB values, or a color from a color book."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-94630133-72B7-4EC7-859C-5798F1ADBB8C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-color/V25/EN_US")

(:name "-COPYTOLAYER"
 :category :LAYER
 :aliases NIL
 :intl-name "_-COPYTOLAYER"
 :synopsis "Copies one or more objects to another layer from the command prompt."
 :options ("?" "=")
 :arguments "Select objects to copy; specify the destination layer name (? lists layers, = selects an object to take its layer, new names create a new layer); optionally specify a base point and displacement, or Enter to copy in place."
 :description "Creates duplicates of selected entities on a specified layer. The destination layer can be chosen from existing layers, named, or created new, and the copies can be placed at a different location or in place."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4327BDE7-58FB-4199-93D4-ECD356C0E89E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-copytolayer/V25/EN_US")

(:name "-DATAEXTRACTION"
 :category :TABLE
 :aliases NIL
 :intl-name "_-DATAEXTRACTION"
 :synopsis "Extracts drawing data from a template file or inserts a data extraction table."
 :options ("Csv" "Txt" "Xlsx" "Mdb")
 :arguments "Specify the extraction template file (BricsCAD: a .dxd file; AutoCAD: a BLK, DXE, or DXEX file); then either choose an output filetype (Csv/Txt/Xlsx/Mdb) and output filepath, or specify a table insertion point."
 :description "Extracts data as specified by an existing extraction template file and either writes it to an external file (CSV, TXT, XLSX, MDB) or inserts it as a data extraction table in the drawing at a chosen insertion point."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FCF91624-D9DB-4D07-8958-6A8E823E3888.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-dataextraction/V25/EN_US")

(:name "-DGNEXPORT"
 :category :FILE
 :aliases NIL
 :intl-name "_-DGNEXPORT"
 :synopsis "Exports the current drawing to MicroStation DGN (*.dgn) format via the command line."
 :options ("DGN" "DWG" "Bind" "Detach" "Master" "Sub")
 :arguments "Specify the full DGN path and file name (~ opens a dialog); AutoCAD then prompts for DGN format (V7/V8), conversion units (Master/Sub), mapping setup, and seed file; BricsCAD prompts for external-reference handling (DGN/DWG/Bind/Detach)."
 :description "Saves the current drawing in MicroStation DGN format. AutoCAD supports V7/V8 output with conversion units, mapping setup, and seed-file selection; BricsCAD handles referenced-file conversion and binding options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9E309147-34D2-4222-8D91-BC8AF7383CA1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-dgnexport/V25/EN_US")

(:name "-DIMSTYLE"
 :category :DIMENSION
 :aliases ("-DST")
 :intl-name "_-DIMSTYLE"
 :synopsis "Creates and modifies dimension styles at the Command line."
 :options ("ANnotative" "Save" "Restore" "STatus" "Variables" "Apply" "?")
 :arguments "Option keyword [ANnotative/Save/Restore/STatus/Variables/Apply/?] <Restore>, then a dimension style name and/or a dimension selection depending on the chosen option."
 :description "At the Command prompt, creates and modifies dimension styles; you can save or restore dimensioning system variables to a selected dimension style, and apply/restore a style to existing dimensions."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-61AD7FCE-E7C5-401E-BAA4-3059F914FAD9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-dimstyle/V25/EN_US")

(:name "-ETRANSMIT"
 :category :FILE
 :aliases NIL
 :intl-name "_-ETRANSMIT"
 :synopsis "Packages a set of files (the drawing and its dependents) into a transmittal package at the Command line."
 :options ("Create" "Report Only" "Current Setup" "Choose Setup" "Sheet Set"
           "Settings" "Save format" "Output format" "FOlder structure"
           "FIle list" "Yes" "No")
 :arguments "Option keyword (e.g. Create transmittal package / Report only / choose Setup), then confirmation (Yes/No) and/or output settings depending on the chosen option."
 :description "Creates a transmittal package ZIP at the Command line, packaging the current drawing and all dependent files (xrefs, fonts, etc.); can also produce a report-only (TXT) file based on the current transmittal setup."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B6F7102A-4C14-45F0-B3B4-D5E5E4086EE5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-etransmit/V25/EN_US")

(:name "-GROUP"
 :category :SELECTION
 :aliases NIL
 :intl-name "_-GROUP"
 :synopsis "Creates and manages saved sets of objects called groups at the command line."
 :options ("?" "Order" "Add" "Remove" "Explode" "Rename" "Selectable" "Create")
 :arguments "An option keyword (?/Order/Add/Remove/Explode/Rename/Selectable/Create); for Create: the group name, an optional description, then the object selection set; for Add/Remove: the group name then objects to add or remove."
 :description "Creates and modifies named (or unnamed) groups of entities from the command line. Selecting any member of a selectable group selects the whole group, so grouped objects can be moved, copied, and edited as a unit; an object may belong to more than one group."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2AED1AD1-95C7-4445-9975-4632D809B53C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-group/V25/EN_US")

(:name "-HATCH"
 :category :DRAW
 :aliases ("-BH" "-B")
 :intl-name "_-HATCH"
 :synopsis "Uses command prompts to fill an enclosed area or selected objects with a hatch pattern, solid fill, or gradient fill."
 :options ("Properties" "Select objects" "draw Boundary" "Remove boundaries"
           "Advanced" "draw Order" "Origin" "ANnotative" "hatch COlor" "LAyer"
           "Transparency" "Solid" "User defined" "Gradient" "Undo")
 :arguments "Specify an internal point inside a closed area (or a keyword: Properties to set pattern name, Scale/Spacing and Angle; Select objects; draw Boundary; Advanced for island/boundary set; etc.); pick additional internal points or objects as needed; press Enter to apply the hatch."
 :description "Command-line version of HATCH that fills closed 2D areas or selected objects with a repeating pattern, a solid or gradient fill. Boundaries are found either by picking an internal point within an enclosed area or by selecting the bounding objects, with island detection controlling how nested areas are treated; 3D entities cannot be hatched."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-410ECEBF-7CC2-4000-A45E-18F1F6BEE423.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-hatch/V25/EN_US")

(:name "-HATCHEDIT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_-HATCHEDIT"
 :synopsis "Modifies existing hatches or fills from the Command prompt."
 :options ("Disassociate" "Style" "Properties" "Draw order" "ADd boundaries"
           "Remove boundary" "Recreate boundary" "ASsociate" "Separate hatches"
           "Origin" "ANnotative" "Hatch color" "Layer" "Transparency")
 :arguments "select hatch/gradient object -> option keyword -> keyword-specific values"
 :description "Command-line version of HATCHEDIT that edits hatch and gradient entities without a dialog. After selecting one or more hatch objects, it exposes prompts to change pattern properties, boundaries, association, origin, draw order, layer, color and transparency. Available prompts vary with the selected hatch type."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B2F5A812-81A8-48C2-83E1-C21708732CD5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-hatchedit/V25/EN_US")

(:name "-HYPERLINK"
 :category :EDIT
 :aliases NIL
 :intl-name "_-HYPERLINK"
 :synopsis "Inserts and removes hyperlinks to selected objects or areas from the Command prompt."
 :options ("Remove" "Insert" "Area" "Object")
 :arguments "Remove|Insert -> (Insert:) Area|Object -> select objects or define area corners -> hyperlink URL -> named location -> description"
 :description "Command-line version of HYPERLINK that attaches files or web pages to entities or to rectangular areas, or removes existing hyperlinks, without the dialog. Intended for use by macros and LISP routines. Supports local file paths and URLs, an optional named location, and an optional description."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-AA172BC1-5402-4884-8697-6EE4490B2FB8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-hyperlink/V25/EN_US")

(:name "-INSERT"
 :category :BLOCK
 :aliases ("-I")
 :intl-name "_-INSERT"
 :synopsis "Inserts a block or drawing into the current drawing via the command line."
 :options ("?" "~" "Corner" "XYZ" "X" "Y" "Z" "Basepoint" "Scale" "Rotate"
           "Explode" "Repeat" "Geographic" "Multiple" "Array" "Flip"
           "Direction" "SMART insert" "insertion Type" "Edit inserted entity"
           "FINISH")
 :arguments "block-name insertion-point x-scale-factor y-scale-factor rotation-angle [attribute-values when ATTDIA=0]"
 :description "Inserts a named block or an external DWG/DXF drawing through command-line prompts; the user specifies the block name (prefix * to explode, ~ for a file dialog, ? to list blocks), insertion point, X/Y/Z scale factors, and rotation angle, and is prompted for attribute values when ATTDIA is 0. BricsCAD adds Multiple/Array placement, SMART insert for connecting standard parts, and Flip/Direction options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BB831F94-6385-4490-8DE9-7C565CD1B639.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-insert/V25/EN_US")

(:name "-INTERFERE"
 :category :|3D|
 :aliases NIL
 :intl-name "_-INTERFERE"
 :synopsis "Creates a temporary 3D solid from the interferences between two sets of selected 3D solids."
 :options ("Nested selection" "Settings" "Check" "Check first set"
           "Create interference objects" "Zoom to pairs of interfering objects"
           "Next pair" "ALL")
 :arguments "first-set-selection second-set-selection [Check] [create-interference-solids? y/n]"
 :description "Compares a first set of 3D solids (ACIS entities) against a second set and highlights the intersecting volumes with a temporary 3D solid, reporting the number of objects selected and the number of interfering pairs. If only one set is given, its objects are checked against each other; Nested selection reaches solids inside blocks and xrefs, and options control whether persistent interference solids are created. In BricsCAD it reports interference volumes/areas on the INTERFERELAYER-designated layer and is available in Pro, Mechanical, and BIM editions."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A3EDAAAF-7963-46B6-8EC7-6B0F3E6654C3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-interfere/V25/EN_US")

(:name "-LAYER"
 :category :LAYER
 :aliases ("-LA")
 :intl-name "_-LAYER"
 :synopsis "Manages layers and layer properties from the Command line."
 :options ("?" "Make" "Set" "New" "Rename" "On" "Off" "Color" "Ltype" "Lweight"
           "TRansparency" "MATerial" "Plot" "Pstyle" "Freeze" "Thaw" "LOck"
           "Unlock" "stAte" "Description" "rEconcile" "Xref")
 :arguments "An option keyword, followed by that option's own values (e.g. a layer name, a color, a linetype, a lineweight, or a state sub-option), repeated as needed, then an empty string to exit the command."
 :description "The command-line version of LAYER: creates layers and layer states and changes their properties (on/off, freeze/thaw, lock/unlock, color, linetype, lineweight, transparency, material, plot, description). The current layer cannot be turned off and frozen."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2C75A883-10CA-4B6C-96AC-BCD7A7794614.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-layer/V25/EN_US")

(:name "-LINETYPE"
 :category :LAYER
 :aliases ("-LT")
 :intl-name "_-LINETYPE"
 :synopsis "Loads, sets, and creates linetypes from the Command line."
 :options ("?" "Create" "Load" "Set")
 :arguments "An option keyword (?, Create, Load, or Set) followed by that option's own values (for Create: new linetype name, descriptive text, and pattern definition; for Load: linetype name and .lin file; for Set: the linetype name to make current), then an empty string to end."
 :description "The command-line version of LINETYPE: lists, creates, loads, and sets current linetypes. A created linetype takes a description (max 47 chars) and a pattern of comma-separated numbers where positive values are dash lengths, negative values are space lengths, and zero is a dot. Setting bylayer/byblock controls inheritance."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A6089331-227F-44F1-BA0C-06BC1568C3BB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-linetype/V25/EN_US")

(:name "-MTEXT"
 :category :TEXT
 :aliases NIL
 :intl-name "_-MTEXT"
 :synopsis "Creates multiline (paragraph) text within a bounding box from the Command line."
 :options ("Justify" "Height" "Rotation" "Style" "Direction" "Width"
           "Line spacing" "Columns")
 :arguments "first corner point; opposite corner point (or an option keyword); text content"
 :description "Places formatted paragraph text in a bounding box using command-line prompts instead of the in-place editor. Options set justification, text height, rotation, style, box width, line spacing and columns; AutoCAD adds a Height/Justify prompt set while BricsCAD adds a Direction (box-expansion) option."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F94BE932-DA31-437E-9610-27F46ACD5711.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-mtext/V25/EN_US")

(:name "-OBJECTSCALE"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_-OBJECTSCALE"
 :synopsis "Adds or removes supported annotation scales for annotative objects from the Command line."
 :options ("Add" "Delete" "?")
 :arguments "selection set of annotative objects; Add or Delete; scale name (or ? to list scales)"
 :description "Modifies which annotation scales are supported by selected annotative objects such as text and hatches. Add attaches scales, Delete removes them, and ? lists the available annotation scales; a single-scale object cannot have its only scale deleted."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-56A9DC12-D049-4384-BDD3-E8D60091AF36.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-objectscale/V25/EN_US")

(:name "-OVERKILL"
 :category :MODIFY
 :aliases NIL
 :intl-name "_-OVERKILL"
 :synopsis "Deletes duplicate and overlapping objects and combines partially overlapping or contiguous ones from the Command line."
 :options ("Done" "Ignore" "Tolerance" "optimize Plines" "segment witDth"
           "Break polyline" "combine parTial overlap" "combine Endtoend"
           "Associativity" "ignore Solids" "delete or Move duplicates"
           "Combine duplicate block definitions"
           "Purge duplicate block definitions")
 :arguments "selection set of objects; option keywords (Ignore/Tolerance/...); Done to execute"
 :description "Removes redundant geometry and merges objects that overlap or share endpoints, using a configurable tolerance and property-ignore list. BricsCAD extends the AutoCAD option set with ignore Solids, delete-or-Move duplicates, and combine/purge duplicate block-definition options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0916FE53-F816-4C40-AA5E-5E8CBFD7F73F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-overkill/V25/EN_US")

(:name "-PAN"
 :category :VIEW
 :aliases ("-P")
 :intl-name "_-PAN"
 :synopsis "Moves the current view by a specified distance and direction from the Command line."
 :options ("Left" "Right" "Up" "Down" "PaGe Left" "PaGe Right" "PaGe Up"
           "PaGe Down")
 :arguments "base point (or single-point displacement); second point (the base point relocates to it)"
 :description "Repositions the drawing view without changing magnification or view direction. AutoCAD prompts for a base point and second point (a single point is treated as an X,Y displacement); BricsCAD adds directional keywords that pan 5% (Left/Right/Up/Down) or 100% (PaGe variants) and requires PERSPECTIVE set to 0."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E7E03AF4-6AEA-405E-8FC4-4C271E6F599A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-pan/V25/EN_US")

(:name "-PARAMETERS"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_-PARAMETERS"
 :synopsis "Manages dimensional-constraint parameters and user variables from the Command line."
 :options ("?" "New" "Edit" "Rename" "Delete" "Properties")
 :arguments "option keyword (New/Edit/Rename/Delete/?); variable or constraint name; expression"
 :description "Creates, edits, renames and deletes user variables and dimensional-constraint parameters; ? lists names, expressions and current values. BricsCAD adds a Properties option to set lower and upper bounds for a parameter; in AutoCAD the command is unavailable in the Block Editor and in AutoCAD LT."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-552B93BC-1F01-46B4-8A55-91196EEF909B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-parameters/V25/EN_US")

(:name "-PDFATTACH"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-PDFATTACH"
 :synopsis "Attaches a PDF file as an underlay from the Command line."
 :options ("Scale" "Size" "XY" "Rotation" "?")
 :arguments "PDF file name (or ~ for dialog); page number; insertion point; scale factor; rotation angle"
 :description "Links a PDF file to the current drawing as an underlay through command-line prompts. Prompts specify the file (~ opens a dialog), the page number (? lists pages), insertion point, scale/size, and rotation; BricsCAD also exposes XY (independent X/Y scale) and Size placement options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BF58207C-52B7-437B-87F5-5201939A1AC8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-pdfattach/V25/EN_US")

(:name "-PDFIMPORT"
 :category :DRAW
 :aliases NIL
 :intl-name "_-PDFIMPORT"
 :synopsis "Imports a PDF (or an attached PDF underlay) and converts its content to CAD objects from the Command line."
 :options ("File" "Select PDF Underlay" "Polygonal" "All" "Settings" "Keep"
           "Detach" "Unload")
 :arguments "PDF file name or PDF underlay; page number; insertion point; scale factor; rotation angle"
 :description "Imports geometry, fills, raster images and TrueType text from a PDF file or attached underlay into the drawing. AutoCAD offers File vs. Select-PDF-Underlay input, rectangular/Polygonal/All selection, a Settings option, and Keep/Detach/Unload handling of the underlay; the BricsCAD reference page lists no command-line options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-ADEE1DE4-3CEF-432D-95F2-014F326E8B2A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-pdfimport/V25/EN_US")

(:name "-PLOT"
 :category :PLOT
 :aliases NIL
 :intl-name "_-PLOT"
 :synopsis "Plots a drawing to a plotter, printer, or file from the Command line."
 :options ("Detailed plot configuration" "Layout name" "Page setup name"
           "Output device name" "Paper size" "Paper units"
           "Drawing orientation" "Plot upside down" "Plot area" "Plot scale"
           "Plot offset" "Plot with plot styles" "Plot style table name"
           "Plot with lineweights" "Shade plot" "Write plot to file"
           "Save changes to layout" "Proceed with plot")
 :arguments "detailed config Yes/No; layout name; output device (or page setup name); [paper size; paper units; orientation; plot area; plot scale; plot offset; plot styles; plot style table; lineweights; shade plot]; write plot to file Yes/No; save changes to layout; proceed with plot"
 :description "Outputs a drawing through a text-based prompt sequence suited to scripts and LISP routines. When detailed configuration is answered No only layout/page-setup/device/file/save/proceed are asked; answering Yes adds paper size, units, orientation, plot area, scale, offset, plot styles, lineweights and shade-plot prompts. BricsCAD notes an Academic-license watermark is added to output."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-625E395D-143A-494F-A1EA-1BF119B927DC.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-plot/V25/EN_US")

(:name "-POINTCLOUDATTACH"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-POINTCLOUDATTACH"
 :synopsis "Attaches a point cloud file to the current drawing from the Command line."
 :options ("Scale" "Rotation")
 :arguments "point cloud file/link; insertion point; scale factor; rotation angle"
 :description "Attaches a converted point cloud (BricsCAD BPT; AutoCAD RCS scan or RCP project file) to the current drawing via command-line prompts for insertion point, scale factor and rotation angle. In AutoCAD the -POINTCLOUDATTACH command-line variant is referenced from the POINTCLOUDATTACH command page."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E086391C-6CEA-4B70-A788-7630FD75469F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-pointcloudattach/V25/EN_US")

(:name "-PSETUPIN"
 :category :PLOT
 :aliases NIL
 :intl-name "_-PSETUPIN"
 :synopsis "Imports a user-defined page setup from another drawing via the Command line."
 :options ("?")
 :arguments "drawing file name (source of the page setup); user-defined page setup name to import"
 :description "Imports named page setups from an existing drawing into the current one for use by the plot/print and publish commands. In AutoCAD, with FILEDIA set to 0 it prompts for the source file and the page setup name (? lists available setups); the BricsCAD reference page opens a Select Page Setup From File dialog and lists no command-line options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7F2B9B98-B3DF-4404-BA01-EBB9F8467729.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-psetupin/V25/EN_US")

(:name "-PUBLISH"
 :category :PLOT
 :aliases NIL
 :intl-name "_-PUBLISH"
 :synopsis "Publishes drawings to DWF, DWFx, and PDF files, or to printers or plotters using the command line."
 :options NIL
 :arguments "Name of DSD sheet list file (or ~ to open the file-selection dialog)"
 :description "The command-line version of PUBLISH enables scripted publishing of drawing sheets from an existing DSD (Drawing Set Description) file to DWF, DWFx, PDF, or a plotter. A log file with a CSV extension, derived from the sheet-list filename, is generated automatically. In BricsCAD this command outputs the contents of a *.dsd file at the Command line."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8FA15020-3D44-4ABC-9708-E5194D2A3EFB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-publish/V25/EN_US")

(:name "-PURGE"
 :category :FILE
 :aliases ("-PU")
 :intl-name "_-PURGE"
 :synopsis "Removes unused named objects, such as block definitions and layers, from the current drawing using the command line."
 :options ("Blocks" "DEtail view styles" "Dimension styles" "Groups" "LAyers"
           "LineTypes" "MAterials" "MLine styles" "MUltileader styles"
           "Plot styles" "Regapps" "SEction view styles" "SHapes"
           "Table styles" "text STyles" "Visual styles" "Zero-length geometry"
           "Empty text objects" "Orphaned data" "All" "Yes" "No" "BAtch all")
 :arguments "Type of unused objects to purge; name(s) to purge (* for all); verify each name to be purged? (Yes/No)"
 :description "The -PURGE command removes unreferenced named objects from the drawing at the Command prompt. Only one nesting level is removed per invocation, so the command must be repeated until no unreferenced objects remain. It cannot remove unnamed objects from blocks or locked layers. BricsCAD additionally offers a BAtch all mode that purges all unused named and nested entities without prompts."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C3876E92-3478-449C-8FAB-DA760B2EDD09.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-purge/V25/EN_US")

(:name "-REFEDIT"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-REFEDIT"
 :synopsis "Edits block references and externally referenced (xref) drawings in place within the current drawing."
 :options ("Next" "Ok" "All" "Nested" "Add" "Remove" "Undo" "Yes" "No")
 :arguments "Select reference; choose nesting level (Next to descend / Ok to accept); select objects to add to the working set (All or Nested); specify whether to display attribute definitions (Yes/No)."
 :description "Enables in-place reference editing of a selected xref or block definition without opening a separate file. Selected objects form a working set that can be modified and saved back to the reference, while the rest of the drawing is faded (fading amount set by XFADECTL, 0-90). Only one reference can be edited at a time; end the session with REFCLOSE."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C2F74110-2DA4-46DA-99EB-E89CF32D30B9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-refedit/V25/EN_US")

(:name "-RENAME"
 :category :EDIT
 :aliases ("-REN")
 :intl-name "_-RENAME"
 :synopsis "Renames named objects (entities) from the Command line."
 :options ("Block" "Dimension style" "LAyer" "LineType" "text Style"
           "Table style" "Ucs" "VIew" "ViewPort" "Material" "Multileader style"
           "Plot style" "Detail view style" "Section view style")
 :arguments "Enter the keyword for the named-object type to rename (e.g. Block, LAyer, VIew); enter the current (old) name; enter the new name."
 :description "Command-line interface for renaming named objects. The user picks the object-type keyword, then supplies the existing name and the new name. Supported types include blocks, dimension styles, layers, linetypes, text styles, table styles, UCSs, views and viewports (AutoCAD additionally lists materials, multileader styles, plot styles, and detail/section view styles). Provides the same functionality as the RENAME dialog-box command."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3C68B0FF-A56F-401E-A58B-6174259252A6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-rename/V25/EN_US")

(:name "-RENDER"
 :category :RENDER
 :aliases NIL
 :intl-name "_-RENDER"
 :synopsis "Creates a photorealistic or realistically shaded image of a 3D solid or surface model from the Command prompt."
 :options ("Draft" "Low" "Medium" "High" "Presentation" "Coffee-Break" "Lunch"
           "Overnight" "Custom" "Other" "Render window" "File" "Viewport")
 :arguments "render-preset then render-destination (Render window or Viewport/File); if a window/pixel output, output width then output height; then save-to-file option and, if yes, the image file format and path"
 :description "Generates photorealistic or realistically shaded renderings of 3D solid/surface models from the command line, applying materials and lights if available. You choose a render preset (quality/ray-tracing level), a destination (render window, current viewport, or a file), pixel dimensions when rendering to a window, and optionally save the result to an image file (BMP in AutoCAD; BricsCAD saves BMP to the DWGPREFIX folder)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-318D7E8B-6ECC-421D-84E3-9CA6961742AE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-render/V25/EN_US")

(:name "-SCALELISTEDIT"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_-SCALELISTEDIT"
 :synopsis "Edits the preset scale factors available for layout viewports, page layouts, plotting, and annotative scaling, at the Command line."
 :options ("?" "Add" "Delete" "Reset")
 :arguments "an option keyword: ? (list defined scales), Add (then a ratio n:m of paper units to drawing units), Delete (then the scale to remove), or Reset (restore the default scale list)"
 :description "Adds and removes preset scale factors to and from the list used by commands such as Print/Plot and by annotative scaling, working entirely at the Command line. Options: ? lists existing scales, Add creates a new scale from an n:m ratio, Delete removes a specified scale (a current or annotatively-referenced scale cannot be deleted), and Reset removes all custom/unused scales and restores the default list."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BF3A0E9D-E009-45C1-A778-C6148C5CAEC8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-scalelistedit/V25/EN_US")

(:name "-SHADEMODE"
 :category :VIEW
 :aliases NIL
 :intl-name "_-SHADEMODE"
 :synopsis "Sets the shading display style for 3D objects at the command line."
 :options ("2dwireframe" "3d wireframe" "Hidden" "Flat" "Gouraud" "fLat+edges"
           "gOuraud+edges")
 :arguments "One shading-mode keyword: 2dwireframe, 3d wireframe, Hidden, Flat, Gouraud, fLat+edges, or gOuraud+edges."
 :description "Specifies the shading style used to display 3D solids and surfaces, ranging from 2D/3D wireframe and hidden through flat and Gouraud shading, each optionally with edges on. In BricsCAD it sets the shading style for the current drawing used by the SHADE command."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A39F669D-DD11-46DD-BD20-7C41F2FF5326.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-shademode/V25/EN_US")

(:name "-TABLE"
 :category :TABLE
 :aliases NIL
 :intl-name "_-TABLE"
 :synopsis "Creates an empty table object from the command line."
 :options ("Style" "Width" "Height" "Auto")
 :arguments "Insertion point (or a Style/Width/Height/Auto keyword), then number of columns, number of rows, column width, and row height."
 :description "Creates a table entity at the command line, either by specifying a number of columns and rows or automatically by designating a point and dragging. Options set the table style, column width, minimum row height, and enable automatic (Auto) sizing of columns and rows."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B958B73F-E812-41DC-8AA3-074A1E125BF4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-table/V25/EN_US")

(:name "-TOOLBAR"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_-TOOLBAR"
 :synopsis "Displays, hides, and customizes toolbars from the Command prompt."
 :options ("Show" "Hide" "Left" "Right" "Top" "Bottom" "Float" "All")
 :arguments "Toolbar name (or ALL); then an option keyword: Show, Hide, Left/Right/Top/Bottom (with a position of columns then rows), or Float (with number of rows)."
 :description "Toggles the display of toolbars from the Command line without opening the customize dialog. After naming a toolbar (or ALL), you choose to Show or Hide it, dock it Left/Right/Top/Bottom at a given row/column position, or Float it with a specified number of rows."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0CFBD067-D736-4198-BC09-3A9092ECE005.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-toolbar/V25/EN_US")

(:name "-UNITS"
 :category :SYSTEM
 :aliases ("-UN")
 :intl-name "_-UNITS"
 :synopsis "Sets the units and precision for linear and angular measurements at the Command line."
 :options ("Scientific" "Decimal" "Engineering" "Architectural" "Fractional"
           "Decimal degrees" "Degrees/minutes/seconds" "Grads" "Radians"
           "Surveyor's units")
 :arguments "Linear unit mode (1=Scientific 2=Decimal 3=Engineering 4=Architectural 5=Fractional); number of decimal places or fractional precision (0-8); angular unit mode (1=Decimal degrees 2=Degrees/minutes/seconds 3=Grads 4=Radians 5=Surveyor's units); number of fractional places for angles (0-8); direction for angle 0; measure angles clockwise? (Yes/No)."
 :description "Controls the precision and display formats for coordinates, distances, and angles at the Command line. It prompts in order for the linear unit format and its precision, the angular unit format and its precision, the direction of angle 0, and whether angles are measured clockwise."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D396FBFE-6171-4A89-9E68-6CB082EBE0E1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-units/V25/EN_US")

(:name "-VBARUN"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_-VBARUN"
 :synopsis "Runs a VBA macro from the Command prompt."
 :options NIL
 :arguments "macro name, given as MacroName, or Project.Module.Macro, or DVBfile!Project.Module.Macro to disambiguate an unloaded global project"
 :description "Executes a Visual Basic for Applications (VBA) macro stored in a DVB file directly from the command line, without opening a dialog box. The macro can be referenced by name alone when unique, or qualified with project, module, and DVB file names; it is intended mainly for use from scripts."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B63DFE34-A23A-49EB-9380-C87EFCD12444.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-vbarun/V25/EN_US")

(:name "-VIEW"
 :category :VIEW
 :aliases ("-V")
 :intl-name "_-VIEW"
 :synopsis "Saves and restores named model space views, layout views, and preset views from the Command prompt."
 :options ("?" "Delete" "Orthographic" "Restore" "Save" "Settings" "Window")
 :arguments "an option keyword (? / Delete / Orthographic / Restore / Save / Settings / Window), then a view name (for Save/Restore/Delete) or window corner points (for Window)"
 :description "Creates, restores, and deletes named views in the current viewport from the command line, for both model space and paper space. Supports saving the current display, defining a windowed view, restoring orthographic and preset views, and (in AutoCAD) view settings such as background, UCS, and visual style."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-21738F8B-82B0-4911-A215-227EB54FCE5D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-view/V25/EN_US")

(:name "-VISUALSTYLES"
 :category :VIEW
 :aliases NIL
 :intl-name "_-VISUALSTYLES"
 :synopsis "Creates and modifies visual styles from the command line."
 :options ("Set Current" "Save As" "Rename" "Delete" "?")
 :arguments "an option keyword (Set current / Save as / Rename / Delete / ?), then a visual style name (and a new name for Save As/Rename)"
 :description "Manages visual styles for the current viewport from the command line, letting you apply a current style, save the current style under a new name, rename or delete custom styles, and list the styles in the drawing. A visual style is a collection of settings that control the display of edges, shading, and background of 3D objects."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-080E88D6-89BB-407A-A7B4-08E8A5A4FBEE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-visualstyles/V25/EN_US")

(:name "-VPORTS"
 :category :VIEW
 :aliases NIL
 :intl-name "_-VPORTS"
 :synopsis "Creates multiple viewports in model space or paper space from the command line."
 :options ("Save" "Restore" "Delete" "Join" "SIngle" "?" "2" "3" "4" "Toggle"
           "MOde" "ON" "OFf" "Fit" "Shadeplot" "Lock" "Object" "Polygonal"
           "LAyer")
 :arguments "a numeric viewport count or an option keyword; then arrangement/placement keywords or a saved configuration name, or selection of an object for a nonrectangular layout viewport"
 :description "Creates one or more viewports in model space, or layout (paper space) viewports, from the command line. In model space it saves, restores, deletes, joins, and subdivides viewport configurations; in a layout it turns viewports on/off and creates rectangular, object-based, or polygonal viewports."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BC2E6DC6-2AC3-42AB-A07B-B36E56E4F10A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-vports/V25/EN_US")

(:name "-WBLOCK"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-WBLOCK"
 :synopsis "Saves selected objects or a block to a separate drawing file from the command line."
 :options ("=" "*" "&" "Convert to block" "Retain" "Delete" "Annotative")
 :arguments "output drawing file name; then either an existing block name (or = for same-named block, * for the whole drawing), or entity selection with an insertion base point"
 :description "Writes blocks or selected entities out to a separate DWG/DXF file from the command line. When FILEDIA is off it prompts for the file name and the source (an existing block, the whole drawing, or selected objects with an insertion base point); the new drawing's WCS is aligned to the current UCS."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F26FC1CE-45C9-4C85-9DB9-19B6A597D87B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-wblock/V25/EN_US")

(:name "-XBIND"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-XBIND"
 :synopsis "Binds one or more definitions of named objects in an xref to the current drawing."
 :options ("Block" "Dimstyle" "Layer" "Linetype" "Style" "*")
 :arguments "a symbol type (Block / Dimstyle / Layer / Linetype / Style), then the xref-dependent symbol name(s) in the form xrefname|symbolname (or * to bind all of that type)"
 :description "Binds individual xref-dependent named objects (blocks, dimension styles, layers, linetypes, text styles) from an attached external reference into the current drawing, so they can be used like any other named object. On binding, the pipe (|) separator in the dependent name is replaced by a number enclosed in dollar signs."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C3391298-3F46-4CA3-BFB9-B0EEB75E292D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-xbind/V25/EN_US")

(:name "-XREF"
 :category :BLOCK
 :aliases ("-XR")
 :intl-name "_-XREF"
 :synopsis "Manages drawings inserted as external references (xrefs) from the command prompt."
 :options ("?" "Attach" "Overlay" "Bind" "Detach" "Path" "Pathtype" "Reload"
           "Unload")
 :arguments "an option keyword (? / Attach / Overlay / Bind / Detach / Path / Reload / Unload); then a file name and insertion point/scale/rotation for Attach or Overlay, or an xref name for the other options"
 :description "Attaches, overlays, detaches, and otherwise manages external DWG references from the command line. Lists attached xrefs, binds an xref into the drawing as a block, edits saved paths, and reloads or unloads references without opening the External References palette."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-70599862-DF52-4291-B64B-8A4C45599F39.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_-xref/V25/EN_US")

(:name "3DARRAY"
 :category :MODIFY
 :aliases ("3A" "ARRAY3D")
 :intl-name "_3DARRAY"
 :synopsis "Creates nonassociative 3D rectangular or polar arrays."
 :options ("Rectangular" "Polar")
 :arguments "select objects; then the method (Rectangular or Polar); for Rectangular the number of rows, columns, and levels plus the distances between them; for Polar the number of items, angle to fill, whether to rotate the objects, the center point, and a second point on the rotation axis"
 :description "Constructs static (nonassociative) three-dimensional arrays of selected objects, either rectangular arrays organized in rows, columns, and Z-levels, or polar arrays rotated about an axis in 3D space. In both products this legacy command has been largely superseded by the enhanced ARRAY command."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-824FE05E-A1C8-4944-8092-A73F4A94B646.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_3darray/V25/EN_US")

(:name "3DDWF"
 :category :FILE
 :aliases NIL
 :intl-name "_3DDWF"
 :synopsis "Creates a 3D DWF or 3D DWFx file of your 3D model."
 :options NIL
 :arguments "none typed at the command line; the command opens the Export 3D DWF dialog box where the file name and DWF/DWFx format are chosen"
 :description "Exports the current 3D model to a 3D DWF or 3D DWFx file through the Export 3D DWF dialog box, with the default format governed by the DWFFORMAT system variable. In AutoCAD the resulting file is displayed in the DWF Viewer after publishing."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8D5FEF23-3399-4948-98FE-B3DDCF50E269.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_3ddwf/V25/EN_US")

(:name "3DFACE"
 :category :|3D|
 :aliases ("3F" "FACE")
 :intl-name "_3DFACE"
 :synopsis "Creates a three-sided or four-sided surface in 3D space."
 :options ("Invisible")
 :arguments "first point, second point, third point, and fourth point of each face (the command repeats, reusing the last two points as the start of the next face); enter Invisible before a point to make the following edge invisible"
 :description "Draws planar or non-planar three- or four-edged faces by specifying points in 3D space. Individual edges can be made invisible to model openings, and successive faces can be chained together to build more complex 3D surfaces."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5E88BB23-9110-45FB-B54A-3FF2E2002585.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_3dface/V25/EN_US")

(:name "3DMESH"
 :category :|3D|
 :aliases ("MESH")
 :intl-name "_3DMESH"
 :synopsis "Creates a free-form (M by N) polygon mesh from a grid of vertices."
 :options NIL
 :arguments "M-size (2-256), N-size (2-256), then the M×N vertex points entered row by row starting at (0,0)."
 :description "Creates a free-form polygon mesh defined by an M by N matrix of vertices; it is a legacy method intended mainly for programmatic use, and MESH is recommended for modern mesh creation. In BricsCAD display resolution is affected by FACETRES."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BA35CABA-6FDF-419C-AE83-9E28690A4B15.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_3dmesh/V25/EN_US")

(:name "3DOSNAP"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_3DOSNAP"
 :synopsis "Sets the object snap modes for 3D objects via a settings dialog."
 :options NIL
 :arguments "None; opens the 3D Object Snap settings dialog (no command-line inputs)."
 :description "Displays the settings dialog (AutoCAD: 3D Object Snap tab of Drafting Settings; BricsCAD: Settings dialog with the Entity 3D snap mode category expanded) for configuring 3D object snap behavior. The command-line variant -3DOSNAP sets running 3D snap modes via prompts."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D2C4AB61-9F54-4513-9921-B959815C6C5E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_3dosnap/V25/EN_US")

(:name "3DPOLY"
 :category :DRAW
 :aliases ("3P")
 :intl-name "_3DPOLY"
 :synopsis "Creates a 3D polyline as a single object of straight line segments."
 :options ("Close" "Undo" "Follow")
 :arguments "Start point, then successive vertex points; empty input to end, or \"Close\" to close and \"Undo\" to remove the last segment."
 :description "Creates a single 3D polyline entity from a connected sequence of straight line segments whose vertices may be non-coplanar; arc segments are not allowed. Segments can be removed with Undo or the polyline closed with Close."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-10E0EDAB-BF4C-442C-93DA-E516F6DEAA7B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_3dpoly/V25/EN_US")

(:name "3DROTATE"
 :category :MODIFY
 :aliases NIL
 :intl-name "_3DROTATE"
 :synopsis "Rotates objects and subobjects around an axis in 3D space."
 :options ("Xaxis" "Yaxis" "Zaxis" "2Points" "Object" "Last" "View" "Copy"
           "Repeat" "Base angle" "Enable connectivity mode"
           "Disable connectivity mode")
 :arguments "Select objects, base point, a rotation axis, then the rotation angle (angle start point/value and end point)."
 :description "Displays the 3D Rotate gizmo to revolve selected 3D solids, surfaces, 2D entities, or subobjects (faces, edges, vertices) around an axis at a base point. When faces of solids or surfaces are rotated, adjacent features adjust to maintain topology."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A16B7027-1346-480F-AFDC-3A3A89EB08D8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_3drotate/V25/EN_US")

(:name "ABOUT"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_ABOUT"
 :synopsis "Displays product, version, and copyright information in a dialog box."
 :options NIL
 :arguments "None; opens the About dialog box (no command-line inputs)."
 :description "Opens the About dialog box showing product and copyright information such as version, license type, and revision/serial details. In AutoCAD the product information can be exported to a text file."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CDBAD44E-F661-430C-A99E-192B83D41C10.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_about/V25/EN_US")

(:name "ACISIN"
 :category :FILE
 :aliases NIL
 :intl-name "_ACISIN"
 :synopsis "Imports an ACIS file and creates 3D solid, body, or region objects."
 :options NIL
 :arguments "ACIS file name selected via the Select/Open ACIS File dialog box."
 :description "Opens a file dialog to select an ACIS file for import into the current drawing. AutoCAD imports SAT (ASCII) files up to ACIS version 7.0; BricsCAD imports .sat or .sab files, treating all file units as DWG units regardless of INSUNITS."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-22CE4285-C2BC-437D-BBCC-5E66250C74D7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_acisin/V25/EN_US")

(:name "ACISOUT"
 :category :FILE
 :aliases NIL
 :intl-name "_ACISOUT"
 :synopsis "Exports 3D solid, region, or body objects to an ACIS file."
 :options NIL
 :arguments "Select objects to export, then the output ACIS file name via the Create ACIS File dialog box."
 :description "Exports selected 3D solids, surfaces, regions, or legacy body objects to an ACIS file, ignoring other object types. AutoCAD saves SAT (ASCII) format; BricsCAD can save either ASCII .sat or binary .sab format for use by other solid modeling programs."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2C08F928-710D-4E3D-B02C-EDFF67C28809.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_acisout/V25/EN_US")

(:name "ADDSELECTED"
 :category :DRAW
 :aliases NIL
 :intl-name "_ADDSELECTED"
 :synopsis "Creates a new object of the same type and general properties as a selected object, but with different geometric values."
 :options NIL
 :arguments "Select object (the object to base the new one on); then the remaining prompts vary by the selected object's type (geometric values such as start point, center, radius, size, location, etc.)."
 :description "Creates a new object with the same type and general properties (such as color and layer) as a selected object, but with different geometry. Special properties like style, scale, and pattern are preserved depending on the object type. In BricsCAD, selecting an existing entity automatically activates the corresponding creation command with matching properties applied."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-771C0F16-58B6-4752-A05D-792FE5D76050.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_addselected/V25/EN_US")

(:name "ALIASEDIT"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_ALIASEDIT"
 :synopsis "Creates, modifies, and deletes command aliases."
 :options NIL
 :arguments "No sequential command-line prompts; the command opens a dialog (AutoCAD: Express Tools alias editor dialog; BricsCAD: the Customize dialog box, Command Aliases tab) in which aliases are added, edited, or removed."
 :description "ALIASEDIT lets you create, modify, and delete command aliases. In AutoCAD it is an Express Tool that manages aliases for AutoCAD commands and DOS/shell commands through a dialog. In BricsCAD it opens the Customize dialog box at the Command Aliases tab."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-34DAD04D-7CA2-43B6-9287-885E61B7C918.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_aliasedit/V25/EN_US")

(:name "ALIGN"
 :category :MODIFY
 :aliases ("AL")
 :intl-name "_ALIGN"
 :synopsis "Aligns objects with other objects in 2D and 3D."
 :options NIL
 :arguments "Select objects; specify first source point; first destination point; second source point; second destination point; when two point pairs are given, answer whether to scale the objects based on the alignment points (Yes/No); optionally specify third source point and third destination point for 3D alignment."
 :description "Moves, rotates, and (optionally) scales selected objects to align them with points on another object. You specify one to three pairs of source and destination points to produce effects ranging from simple translation to full 3D rotation. In AutoCAD LT this command is available only from the command line."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D0FA10D5-76EE-4B80-A285-43C7F39916DB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_align/V25/EN_US")

(:name "ALIGNSPACE"
 :category :VIEW
 :aliases NIL
 :intl-name "_ALIGNSPACE"
 :synopsis "Adjusts the pan and zoom factor of a layout viewport based on alignment points specified in model space and paper space."
 :options NIL
 :arguments "Specify points in model space (one point, or two points to also adjust zoom), then specify the matching points in paper space; the viewport pan, zoom, and UCS rotation are adjusted to align them."
 :description "An Express Tool (AutoCAD) that positions a layout viewport by aligning points between model space and paper space. Specifying one point in each space adjusts position without changing zoom; specifying two points in each space adjusts both position and zoom. It operates only in paper space, and in BricsCAD the model-space viewport must have PERSPECTIVE mode disabled."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D5F8E293-F8A9-4E45-9441-87A21487A68C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_alignspace/V25/EN_US")

(:name "ANIPATH"
 :category :RENDER
 :aliases NIL
 :intl-name "_ANIPATH"
 :synopsis "Saves an animation of a camera moving or panning in a 3D model."
 :options NIL
 :arguments "No sequential command-line prompts; the command opens the Motion Path Animation dialog box, where the camera/target link to a point or path and the animation settings are configured before saving to a movie file."
 :description "Records the animation of a camera moving along a path or panning in a 3D model and saves it to a movie file. Invoking the command displays the Motion Path Animation dialog box, in which the camera and target are linked to a point or path and animation output settings are chosen."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4B806FDB-C6BC-41FF-879B-148F44E09D14.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_anipath/V25/EN_US")

(:name "ANNORESET"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_ANNORESET"
 :synopsis "Resets the locations of all alternate scale representations of the selected annotative objects."
 :options NIL
 :arguments "Select objects (the annotative objects whose moved scale representations are to be reset)."
 :description "Returns all alternate scale representations of selected annotative objects to the location of the object's current scale representation, undoing positioning adjustments previously made to individual scale representations with grips."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-47705AD0-651E-49AA-B23E-D12529D5BA1F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_annoreset/V25/EN_US")

(:name "ANNOUPDATE"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_ANNOUPDATE"
 :synopsis "Updates existing annotative objects to match the current properties of their styles."
 :options NIL
 :arguments "Select objects (the annotative objects to update); non-annotative entities are ignored when all drawing entities are selected."
 :description "Updates selected annotative objects (text, dimensions, hatches, blocks, etc.) so their properties match their current annotative style. Updating a non-annotative text object to an annotative style makes it annotative and adopts the style's Paper Height, while converting annotative objects to a non-annotative style removes their alternate scale representations."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-574C4E2C-C261-44EB-8E10-A01E8D1BB0C8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_annoupdate/V25/EN_US")

(:name "APPLOAD"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_APPLOAD"
 :synopsis "Loads and unloads applications and defines which applications to load at startup."
 :options NIL
 :arguments "No sequential command-line prompts; the command opens the Load/Unload Applications dialog box (BricsCAD: Load application files), where application files (LISP, ARX/BRX, DVB, etc.) are added, loaded, unloaded, and a Startup Suite defines which applications load at launch."
 :description "Displays a dialog box for loading and unloading application files and for specifying which applications load automatically at startup. AutoCAD provides a Startup Suite option, and BricsCAD loads applications listed in appload.dfs at start-up."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-47621BB1-F29D-4A69-9C99-A6E1495FBA38.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_appload/V25/EN_US")

(:name "ARC"
 :category :DRAW
 :aliases ("A")
 :intl-name "_ARC"
 :synopsis "Creates an arc."
 :options ("Center" "End" "Angle" "Direction" "Radius" "Length")
 :arguments "Supplies a start point (or the keyword \"C\" for Center), then a second point on the arc or a keyword, then an end point; construction can be refined with keywords for included Angle, chord Length, Direction of tangent, and Radius. Arcs are drawn counterclockwise by default."
 :description "Creates an arc from various combinations of start point, second point, center, end point, included angle, tangent direction, radius, and chord length. Arcs are drawn counterclockwise by default; holding Ctrl while dragging reverses the direction."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-30ECFD30-A1D6-4D60-9DD1-B487603F6772.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_arc/V25/EN_US")

(:name "ARCTEXT"
 :category :TEXT
 :aliases NIL
 :intl-name "_ARCTEXT"
 :synopsis "Places text aligned along a selected arc."
 :options NIL
 :arguments "Select an arc; the ArcAligned Text Workshop dialog then opens for entering the text and setting style, font, color, alignment, and properties (height, width factor, character spacing, offsets). Only arcs are supported (not splines, polylines, or circles)."
 :description "Creates text that follows the curve of a selected arc, or edits existing arc-aligned text. An Express Tool in AutoCAD; in BricsCAD it opens the ArcAligned Text Workshop dialog with options for alignment, convex/concave side, formatting, and text properties."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A1031C92-383E-41E7-80E0-9673D987EF2F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_arctext/V25/EN_US")

(:name "AREA"
 :category :INQUIRY
 :aliases ("AA")
 :intl-name "_AREA"
 :synopsis "Calculates the area and perimeter of objects or of defined areas."
 :options ("Object" "Add area" "Subtract area")
 :arguments "Specify first corner point or [Object/Add area/Subtract area]; then specify successive points to define a region, or select an object; the area and perimeter are reported at the command line."
 :description "Obtain measurements by selecting an object or specifying points to define what you want to measure. You can add multiple areas together or subtract areas from a running total; the area and perimeter are displayed at the Command prompt and in the tooltip."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0591351F-8750-425C-9F1C-98B1C73D9D55.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_area/V25/EN_US")

(:name "ARRAY"
 :category :MODIFY
 :aliases ("AR")
 :intl-name "_ARRAY"
 :synopsis "Creates copies of objects arranged in a rectangular, path, or polar pattern."
 :options ("Rectangular" "PAth" "POlar")
 :arguments "Select objects, then choose the array type [Rectangular/PAth/POlar]; the remaining prompts depend on the chosen array type (see ARRAYRECT, ARRAYPATH, ARRAYPOLAR)."
 :description "Creates copies of objects distributed in regularly spaced rectangular, path, or polar patterns. Works with both 2D and 3D entities; the default array type is controlled by the ARRAYTYPE system variable and the DELOBJ system variable determines whether source objects are kept."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E23F6125-E5E9-4645-9615-23717902C33B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_array/V25/EN_US")

(:name "ARRAYCLASSIC"
 :category :MODIFY
 :aliases NIL
 :intl-name "_ARRAYCLASSIC"
 :synopsis "Creates arrays using the legacy Array dialog box."
 :options NIL
 :arguments "Displays the legacy Array dialog box; select entities and set the array type (rectangular or polar) along with the count, offset, angle, and center-point settings in the dialog."
 :description "Displays a legacy Array dialog box that lets you create non-associative copies of objects arranged in regularly spaced rectangular or polar patterns. This version does not support array associativity or path arrays available through the standard ARRAY command."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-01258C43-66E4-457E-BBD3-F7A670BC5F54.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_arrayclassic/V25/EN_US")

(:name "ARRAYCLOSE"
 :category :MODIFY
 :aliases NIL
 :intl-name "_ARRAYCLOSE"
 :synopsis "Saves or discards changes made to an array's source objects and exits the array editing state."
 :options ("Yes" "No" "Cancel")
 :arguments "A message box asks \"Save changes to array?\"; answer Yes to save changes to the source object or replacement item, or No to discard them and restore the original array, then the array editing state is exited."
 :description "Exits the associative array editing state that was activated by the ARRAYEDIT Source option. It provides a choice between preserving or reverting modifications made to the source objects of the array."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D3E79D10-2151-45F4-AD49-A598DAB80723.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_arrayclose/V25/EN_US")

(:name "ARRAYEDIT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_ARRAYEDIT"
 :synopsis "Edits associative array objects and their source objects."
 :options ("Source" "REPlace" "Base point" "Rows" "Columns" "Levels" "Method"
           "Items" "Align items" "Z direction" "Angle between" "Fill angle"
           "Rotate items" "RESet" "eXit")
 :arguments "Select the associative array, then choose an editing option; the available options vary by array type (rectangular, path, or polar)."
 :description "Modifies associative arrays by editing array properties, editing source objects, or replacing items with other objects. When a single array is selected the Array Editor contextual options are shown, with the available options differing according to the array type."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BD2D21A1-ED66-4A1A-B1DE-551D41C5D7E3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_arrayedit/V25/EN_US")

(:name "ARRAYPATH"
 :category :MODIFY
 :aliases NIL
 :intl-name "_ARRAYPATH"
 :synopsis "Evenly distributes object copies along a path or a portion of a path."
 :options ("ASsociative" "Method" "Base point" "Tangent direction" "Items"
           "Rows" "Levels" "Align items" "Z direction" "eXit")
 :arguments "Select objects, then select the path curve (line, polyline, spline, arc, circle, or ellipse); then set options [Associative/Method/Base point/Tangent direction/Items/Rows/Levels/Align items/Z direction] and eXit."
 :description "Associatively distributes entity copies evenly along a path into multiple rows and levels. The command offers associative array capabilities for linked editing and multiple distribution methods (Divide, Measure)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D36C46CD-4E17-4A16-A387-C0B158EA5A9E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_arraypath/V25/EN_US")

(:name "ARRAYPOLAR"
 :category :MODIFY
 :aliases NIL
 :intl-name "_ARRAYPOLAR"
 :synopsis "Evenly distributes object copies in a circular pattern around a center point or axis of rotation."
 :options ("ASsociative" "Base point" "Items" "Angle between" "Fill angle"
           "ROWs" "Levels" "ROTate items" "eXit")
 :arguments "Select objects, then specify the center point (or Base point / axis of rotation); then set options [Associative/Items/Angle between/Fill angle/Rows/Levels/Rotate items] and eXit."
 :description "Associatively distributes entity copies evenly in a circular pattern about a center point or axis of rotation, using multiple rows and levels. It is equivalent to the Polar option in ARRAY, with the DELOBJ system variable controlling whether source objects are retained."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A6E74297-2CB3-4B1C-A07B-69CD08630052.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_arraypolar/V25/EN_US")

(:name "ARRAYRECT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_ARRAYRECT"
 :synopsis "Distributes object copies into any combination of rows, columns, and levels."
 :options ("ASsociative" "Base point" "COUnt" "Spacing" "Unit cell" "COLumns"
           "Rows" "Levels" "eXit")
 :arguments "Select objects, then set options [Associative/Base point/Count or Spacing/Columns/Rows/Levels] and eXit; columns and rows can be defined by distance or total."
 :description "Associatively distributes copies of entities into any number of rows, columns, and levels in 2D or 3D space. It is functionally equivalent to the Rectangular option in ARRAY, with the DELOBJ system variable controlling whether source objects are retained, and array parameters can be set with parametric expressions."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BB3DA888-0C3A-4C68-A3ED-E0E528781205.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_arrayrect/V25/EN_US")

(:name "ATTDEF"
 :category :ATTRIBUTE
 :aliases ("AT" "DDATTDEF")
 :intl-name "_ATTDEF"
 :synopsis "Creates an attribute definition for storing data in a block."
 :options NIL
 :arguments "Opens the Define Attribute (Attribute Definition) dialog box; set the attribute tag, prompt, and default value, the attribute flags (Invisible/Constant/Verify/Preset/Lock position/Multiple lines), the text options (style, justification, height, rotation, annotative), and the insertion point."
 :description "Creates an attribute definition, an object included with a block definition that can store data such as part numbers and product names. The command opens a dialog for configuring the attribute tag, prompt, default value, flags, and text formatting (the command-line variant is -ATTDEF)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-19B6B720-B40B-42B6-A521-888C1A383F34.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_attdef/V25/EN_US")

(:name "ATTDISP"
 :category :ATTRIBUTE
 :aliases ("AD")
 :intl-name "_ATTDISP"
 :synopsis "Controls the visibility overrides for all block attributes in a drawing."
 :options ("Normal" "ON" "OFf")
 :arguments "Enter attribute visibility setting [Normal/ON/OFF]: Normal displays each attribute according to its own visibility flag, ON forces all attributes visible (including invisible ones), OFF makes all attributes invisible; the drawing regenerates after the change."
 :description "Sets the display mode of attribute text in the drawing, toggling visibility between three states: restore original per-attribute visibility (Normal), force all attributes visible (ON), or make all attributes invisible (OFF). The drawing regenerates after visibility changes unless automatic regeneration is disabled."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BCFF32DB-6860-4812-BEF1-3BB658126B26.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_attdisp/V25/EN_US")

(:name "ATTEDIT"
 :category :ATTRIBUTE
 :aliases ("ATE")
 :intl-name "_ATTEDIT"
 :synopsis "Edits the values and properties of block attributes."
 :options ("Yes" "No" "Position" "Angle" "Text" "Style" "Color" "Height"
           "Layer" "Next" "Previous" "Quit")
 :arguments "Edit attributes one at a time? [Yes/No]; block name filter; attribute tag filter; attribute value filter; select attributes; then property to change (Position/Angle/Text/Style/Color/Height/Layer/Next/Previous/Quit)."
 :description "Changes attribute values and properties in blocks. Single-attribute mode edits values and properties; global mode edits values across many attributes. The dialog form edits values for one block; the command-line form (-ATTEDIT) edits values and properties independent of the block."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-AB03D5EE-6B27-492A-8147-671D0F536CB5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_attedit/V25/EN_US")

(:name "ATTEXT"
 :category :ATTRIBUTE
 :aliases ("AX" "DDATTEXT")
 :intl-name "_ATTEXT"
 :synopsis "Extracts block attribute data to an external file."
 :options ("CDF" "SDF" "DXX" "DXF")
 :arguments "Select blocks with attributes; choose output format (CDF/SDF/DXF); specify template file; specify output file."
 :description "Exports data from block attributes to a text file in CDF (comma-delimited), SDF (space-delimited), DXX/DXF format, using an extraction template file. Supports documentation generation and integration with external database software."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6FEA6520-430E-47E2-BA16-305508495156.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_attext/V25/EN_US")

(:name "ATTIN"
 :category :ATTRIBUTE
 :aliases NIL
 :intl-name "_ATTIN"
 :synopsis "Imports block attribute values from an external text file."
 :options NIL
 :arguments "Select the external file (tab-delimited/TXT) produced by ATTOUT; optionally assign remaining rows interactively by selecting blocks."
 :description "Reads a file formatted by ATTOUT and applies attribute value changes to block references by matching handle and block name. In AutoCAD this is an Express Tool (attin.lsp); in BricsCAD it is a native command reading a .txt file."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2B54F825-CD42-4707-883A-8EFA97F4AB3F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_attin/V25/EN_US")

(:name "ATTIPEDIT"
 :category :ATTRIBUTE
 :aliases NIL
 :intl-name "_ATTIPEDIT"
 :synopsis "Edits the textual content of an attribute within a block."
 :options NIL
 :arguments "Select attribute to edit; edit its text in the in-place text editor."
 :description "Launches an in-place text editor to change attribute text. Single-line attributes display without the formatting toolbar and ruler; multi-line attributes display them."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-42CA78B8-1A02-4C1E-97E2-A31F4CD3014B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_attipedit/V25/EN_US")

(:name "ATTOUT"
 :category :ATTRIBUTE
 :aliases NIL
 :intl-name "_ATTOUT"
 :synopsis "Exports block attribute values to an external text file."
 :options NIL
 :arguments "Specify output file name; select or name blocks to process; attribute values are written to the file."
 :description "Exports data from selected block attributes to a tab-delimited (BricsCAD: .txt) file with HANDLE, BLOCKNAME and attribute-tag columns, which can be edited externally and re-imported with ATTIN. In AutoCAD this is an Express Tool (attout.lsp); in BricsCAD it is a native command."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-899B195A-EFF0-4AEC-B0F8-7444EC75D649.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_attout/V25/EN_US")

(:name "ATTREDEF"
 :category :ATTRIBUTE
 :aliases NIL
 :intl-name "_ATTREDEF"
 :synopsis "Redefines a block and updates its associated attributes."
 :options NIL
 :arguments "Name of the block to redefine; select objects for the new block; specify insertion base point."
 :description "Redefines an existing block from selected drawing objects and updates its attributes: new attributes take default values, old attribute values are kept when included, excluded attributes are deleted, and formatting/extended data are removed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CB8237C2-EB63-4839-9B84-5B890C979CBB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_attredef/V25/EN_US")

(:name "ATTSYNC"
 :category :ATTRIBUTE
 :aliases NIL
 :intl-name "_ATTSYNC"
 :synopsis "Synchronizes attributes in block references with their block definition."
 :options ("?" "Name" "Select" "Yes" "No")
 :arguments "Choose method [?/Name/Select]; identify the block definition (list, name, or selected reference); confirm synchronization [Yes/No] per block."
 :description "Applies attribute definition changes to all references of a block. It does not change existing attribute values, but removes formatting made by ATTEDIT/EATTEDIT, deletes extended data, and may affect dynamic blocks."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-56B14079-250B-4C99-AB3D-F95BA1C32AB7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_attsync/V25/EN_US")

(:name "AUDIT"
 :category :FILE
 :aliases NIL
 :intl-name "_AUDIT"
 :synopsis "Evaluates the integrity of the current drawing and fixes errors."
 :options ("Yes" "No")
 :arguments "Fix any errors detected? [Yes/No]."
 :description "Analyzes the current drawing for errors and, optionally, repairs them. Problematic objects are placed in the Previous selection set; when AUDITCTL is enabled an ASCII .adt report is generated. Use RECOVER for errors AUDIT cannot fix."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-62DDB935-61B1-49DA-8238-3EF1CC45259B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_audit/V25/EN_US")

(:name "AUTOCONSTRAIN"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_AUTOCONSTRAIN"
 :synopsis "Automatically applies constraints to 2D geometry."
 :options ("Settings")
 :arguments "Select objects to constrain; optionally use Settings to open the Constraint Settings dialog."
 :description "Automatically applies geometric (AutoCAD) and geometric plus dimensional (BricsCAD) constraints to selected 2D geometry based on their relative orientation and the configured tolerance settings."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2E53F0A6-640C-4B3A-A650-18F1A5F781E1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_autoconstrain/V25/EN_US")

(:name "BASE"
 :category :BLOCK
 :aliases ("BA")
 :intl-name "_BASE"
 :synopsis "Sets the insertion base point for the current drawing."
 :options NIL
 :arguments "Specify the base point (X,Y,Z coordinates in the current UCS, or pick a point)."
 :description "Sets the base insertion point of the current drawing, used as the insertion point when it is inserted or referenced as a block or external reference in other drawings."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C44D8156-1A45-43A4-B0DC-65DB48371381.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_base/V25/EN_US")

(:name "BATTMAN"
 :category :ATTRIBUTE
 :aliases NIL
 :intl-name "_BATTMAN"
 :synopsis "Opens the Block Attribute Manager to edit block attribute definitions."
 :options NIL
 :arguments "Opens the Block Attribute Manager dialog; select a block, choose an attribute, edit its settings, and apply/sync to references."
 :description "Manages all attribute properties and settings of a selected block definition through the Block Attribute Manager dialog. Changes to attribute definitions can be reflected in all block references."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-40613EEB-3049-4B39-AD1D-457146EEE0CB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_battman/V25/EN_US")

(:name "BCLOSE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BCLOSE"
 :synopsis "Closes the Block Editor."
 :options ("Save" "Discard")
 :arguments "Choose to Save changes or Discard block editing changes, then the Block Editor closes."
 :description "Closes a block editing session started with BEDIT, prompting the user to save or discard the modifications made to the block definition."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C63C7855-B666-4B99-B371-F58786E1E5A8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_bclose/V25/EN_US")

(:name "BCOUNT"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_BCOUNT"
 :synopsis "Reports the number of instances of each block in a selection set or drawing."
 :options NIL
 :arguments "Select objects, or press Enter to include all block references; the count report is displayed at the command line."
 :description "Creates a report of how many instances of each block occur in a selection set or in the entire drawing. In AutoCAD this is an Express Tool (count.lsp); nested blocks and blocks in associative arrays are not counted."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2C2991B4-779F-4FEE-9E55-8B0D6B62DEF8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_bcount/V25/EN_US")

(:name "BEDIT"
 :category :BLOCK
 :aliases ("BE")
 :intl-name "_BEDIT"
 :synopsis "Opens a block definition in the Block Editor."
 :options NIL
 :arguments "In the Edit Block Definition dialog, select an existing block or type a new name, then OK opens the Block Editor. The -BEDIT command-line form takes the block name directly."
 :description "Opens the Create or Edit Block Definition dialog and then the Block Editor, where block definitions are created or modified, including dynamic behaviors via parameters, actions, and constraints. Blocked when BLOCKEDITLOCK is 1."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D57D4195-72FC-4FA5-B9F4-E021291D808C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_bedit/V25/EN_US")

(:name "BEXTEND"
 :category :MODIFY
 :aliases NIL
 :intl-name "_BEXTEND"
 :synopsis "Extends objects to boundary edges nested in blocks and external references."
 :options ("Fence" "Crossing" "Edge" "Projection" "eRase" "Undo")
 :arguments "Select boundary entities (a block or objects within a block/xref) to use as extending edges; then select objects to extend, or use Fence/Crossing/Edge/Projection/eRase/Undo. Shift-select to trim."
 :description "Uses a block, or objects nested in a block reference or xref, as a boundary to which drawing objects are extended, extending the end closest to the pick point. In AutoCAD this is an Express Tool (marked obsolete)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-ADFAA9DC-B6E9-456C-B5C7-984639963A06.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_bextend/V25/EN_US")

(:name "BLOCK"
 :category :BLOCK
 :aliases ("B")
 :intl-name "_BLOCK"
 :synopsis "Creates a block definition from selected objects (opens the Block Definition dialog box)."
 :options NIL
 :arguments "In a (command ...) call use the command-line variant -BLOCK, which supplies: block name -> insertion base point -> object selection -> Enter to finish. The GUI BLOCK command opens the Create Block Definition / Block Definition dialog box (name, base point, entity selection, behavior options) and takes no command-line arguments."
 :description "Creates a block definition in the current drawing from selected objects. The user gives the block a name, an insertion base point, and selects the entities to group; behavior options include annotative scaling, uniform scaling, and allow-exploding. The GUI form opens a dialog box; entering -BLOCK at the prompt drives the same operation from the command line."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B03434BE-0F68-4E31-BA8D-640EEC1D7FC9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_block/V25/EN_US")

(:name "BLOCKICON"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BLOCKICON"
 :synopsis "Creates and updates preview icons of blocks stored in the drawing."
 :options ("*")
 :arguments "Enter the block names to process (comma-delimited, wildcards allowed), or * to process all blocks."
 :description "Generates and refreshes the preview bitmap icons for blocks (used in DesignCenter and block dialogs), especially for blocks from earlier releases, and stores them in the drawing."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-144172C9-FCC6-4326-B69B-39E269DF1F25.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_blockicon/V25/EN_US")

(:name "BLOCKREPLACE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BLOCKREPLACE"
 :synopsis "Replaces all instances of a specified block with another block."
 :options NIL
 :arguments "Specify the block to search for (from list or picked in the drawing); specify the replacement block; optionally purge the unreferenced block."
 :description "Searches the entire drawing for a specified block and replaces every instance with another block. In AutoCAD this is an Express Tool; the unreferenced original can be removed with PURGE. BricsCAD offers options for similar inserts, parametric expressions, and purging."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C2E32C55-28E4-4FC5-BCCA-F141D5AAA614.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_blockreplace/V25/EN_US")

(:name "BLOCKTOXREF"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BLOCKTOXREF"
 :synopsis "Replaces all instances of a specified block with an external reference."
 :options NIL
 :arguments "Select the block to replace (all or particular instances); configure conversion options; specify the xref (filename) to substitute."
 :description "Searches the drawing for a specified block and replaces its references with an xref; the xref name is derived from the file name. Can be used to unbind an xref. In AutoCAD this is an Express Tool (blocktoxref.lsp)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C951209B-2844-4618-A4B3-EEBFEBB57868.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_blocktoxref/V25/EN_US")

(:name "BMPOUT"
 :category :RENDER
 :aliases NIL
 :intl-name "_BMPOUT"
 :synopsis "Saves the view or selected objects to a bitmap (BMP) file."
 :options NIL
 :arguments "In the Save Bitmap / Create Raster File dialog, specify the output file name; in AutoCAD then select objects to export."
 :description "Exports drawing content to a device-independent bitmap (.bmp) file. AutoCAD saves selected objects (capturing the current screen display); BricsCAD saves the current model or paper space view."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8E2BAC74-5B7E-4A50-A225-3C44AA126509.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_bmpout/V25/EN_US")

(:name "BOUNDARY"
 :category :DRAW
 :aliases ("BO" "BPOLY")
 :intl-name "_BOUNDARY"
 :synopsis "Creates regions or closed polylines from enclosed areas."
 :options ("New" "Islands" "Undo")
 :arguments "Pick an internal point inside an enclosed area; the command opens the Boundary Creation dialog box (the -BOUNDARY command-line version prompts on the command line)."
 :description "Generates closed polylines and regions by specifying an interior point within enclosed areas, using surrounding and interior objects to define the boundary. An Island Detection option controls whether closed interior objects are recognized. The command normally opens the Boundary Creation dialog box; the command-line version is -BOUNDARY."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5072D0D0-5DB7-4649-8B2F-1FD5A3FA3643.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_boundary/V25/EN_US")

(:name "BOX"
 :category :|3D|
 :aliases NIL
 :intl-name "_BOX"
 :synopsis "Creates a 3D solid in the shape of a box."
 :options ("Center" "Cube" "Length" "Width" "2Point")
 :arguments "Specify the first corner of the box, then the opposite corner and the height; or use the Center, Cube, Length, Width, or 2Point options."
 :description "Creates a three-dimensional rectangular or square box solid, defined by two corners, a center point, or dimensional parameters. The box is always parallel to the XY plane with its height along the Z axis. In BricsCAD Lite the AI_BOX command is used instead, as it lacks 3D solid support."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8B9B2875-3CA1-448D-ACF2-94C503DA54C6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_box/V25/EN_US")

(:name "BREAK"
 :category :MODIFY
 :aliases ("BR")
 :intl-name "_BREAK"
 :synopsis "Removes a portion of an entity between two points."
 :options ("First point")
 :arguments "Select the object; specify the first break point (or use the First point option to reselect it); specify the second break point (enter @ to break at a single point)."
 :description "Creates a gap between two specified points on an object, splitting it into two objects; points outside the object are projected onto it. Breaking a circle converts it to an arc (removing the counter-clockwise segment), a ray becomes a ray and a line, and an infinite line becomes two rays."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-36A1CDE0-3871-4B25-AC98-93235FA83863.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_break/V25/EN_US")

(:name "BREAKLINE"
 :category :DRAW
 :aliases NIL
 :intl-name "_BREAKLINE"
 :synopsis "Creates a polyline with a breakline symbol."
 :options ("Block" "Size" "Extension")
 :arguments "Specify the first point of the breakline; specify the second point; specify the location of the breakline symbol (or set the Block, Size, or Extension options first)."
 :description "Creates a polyline that includes a breakline symbol between two specified points, then places the symbol at a chosen location. The symbol size and line extensions can be controlled. In AutoCAD it is an Express Tool and the DIMSCALE system variable governs the symbol size; the symbol may be customized with a custom drawing and two reference points."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-88667D3B-C98B-4C02-85F4-232DD4950841.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_breakline/V25/EN_US")

(:name "BROWSER"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_BROWSER"
 :synopsis "Opens the default web browser."
 :options NIL
 :arguments "Enter the location (URL) to connect to."
 :description "Launches the system's default web browser (as defined in the system registry) and connects to a specified location. The browser opens in an external window that can be moved and resized while you continue working. It does not automatically prepend http:// to the address, so FTP, HTTP, HTTPS, or FILE protocols may be used."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-261973D6-B582-4584-9175-37500A336A20.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_browser/V25/EN_US")

(:name "BSAVEAS"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BSAVEAS"
 :synopsis "Saves a copy of the current block definition under a new name."
 :options NIL
 :arguments NIL
 :description "Available only within the Block Editor, this command opens the Save Block As (Save Block Definition) dialog box to save a copy of the current block definition under a new name."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-02A68BE5-AD95-475C-AB10-D3AC806C4DB0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_bsaveas/V25/EN_US")

(:name "BSCALE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BSCALE"
 :synopsis "Scales a block reference relative to its insertion point."
 :options ("Absolute" "Relative" "XYZ")
 :arguments "Select the block reference(s); specify the type of scaling [Absolute/Relative]; specify the X scale (or XYZ); specify the Y scale."
 :description "Scales block references using the insertion point as the origin of the scaling, independently in the X, Y, and Z directions. The scale can be applied as an absolute (final) value or as a relative (multiplying) factor. In AutoCAD it is an Express Tool."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-63398207-C02F-480B-BB91-F7AB4C24011C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_bscale/V25/EN_US")

(:name "BTRIM"
 :category :MODIFY
 :aliases NIL
 :intl-name "_BTRIM"
 :synopsis "Trims objects using a block or nested objects as cutting edges."
 :options ("Fence" "Crossing" "Project" "Edge" "eRase" "Undo")
 :arguments "Select the block or external reference (or the objects nested within them) to use as the cutting edge; select the object to trim, or shift-select to extend, or choose Fence/Crossing/Project/Edge/eRase/Undo."
 :description "Uses a block, external reference, or the objects nested within them as cutting edges to trim (or, with Shift held, extend) objects in the drawing. In AutoCAD it is an Express Tool."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4F925A89-6163-43F4-BB51-B0527E5E9983.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_btrim/V25/EN_US")

(:name "BURST"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BURST"
 :synopsis "Explodes blocks, converting the attribute values into text entities."
 :options NIL
 :arguments "Select the block(s) to explode, then press Enter."
 :description "Explodes selected blocks into their component objects while preserving the block's layer, and converts attribute values into text objects that adopt the layer and style of their original attribute definitions. In AutoCAD it is an Express Tool."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8B576DFE-377C-408C-B6BE-672EE46AEED2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_burst/V25/EN_US")

(:name "CAL"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_CAL"
 :synopsis "Evaluates mathematical and geometric expressions (AutoCAD); opens the calculator (BricsCAD)."
 :options NIL
 :arguments "Enter the expression to evaluate (AutoCAD); in BricsCAD the command simply opens the calculator application."
 :description "In AutoCAD, CAL is an inline geometry calculator that evaluates point, vector, real, or integer expressions at the Command prompt or transparently within another command, obtaining values from existing geometry via object snap functions and integrating with AutoLISP variables. In BricsCAD, CAL instead opens the operating system's software calculator as a separate window offering multiple calculator and converter views."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-335A5FC6-7D8F-47CA-B479-26655CDEA1AD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_cal/V25/EN_US")

(:name "CAMERA"
 :category :VIEW
 :aliases NIL
 :intl-name "_CAMERA"
 :synopsis "Sets a camera and target location to create a 3D perspective view."
 :options ("?" "Name" "LOcation" "Height" "Target" "LEns" "CLipping" "View"
           "Exit")
 :arguments "Specify the camera location; specify the target location; then optionally set Name, Height, Lens, Clipping, activate View, or Exit."
 :description "Places a camera glyph aimed at a target point to define and save a 3D perspective view. Camera properties (lens length, clipping planes, name) can be set through options, grips, or the Properties panel."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DACC085F-C72C-4F7B-9C3A-CDAF972FEF29.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_camera/V25/EN_US")

(:name "CDORDER"
 :category :MODIFY
 :aliases NIL
 :intl-name "_CDORDER"
 :synopsis "Arranges the draw order of objects based on their index color."
 :options ("Draworder" "Handles" "Front" "Back" "Modify Blocks")
 :arguments "Select entities to arrange; in the color-based draw order dialog, order the colors (first=front, last=back), choose method (Draworder/Handles), set location (Front/Back), and optionally Modify Blocks."
 :description "Controls the display (draw) order of selected objects by their index color number: colors listed first appear in front, those listed last appear in back. In AutoCAD this is an Express Tool; external reference objects are unaffected."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-06C097F8-0482-4675-8910-664BC87B4AC3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_cdorder/V25/EN_US")

(:name "CENTERDISASSOCIATE"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_CENTERDISASSOCIATE"
 :synopsis "Removes the associativity of center marks or centerlines from the objects they define."
 :options NIL
 :arguments "Select the associative center marks or centerlines whose association is to be removed."
 :description "Disassociates center mark and centerline entities from the geometry (circles, arcs, or lines) they reference, reversing the associativity created by CENTERMARK and CENTERLINE."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-96FD0416-DE6C-4220-990B-7F88A5703166.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_centerdisassociate/V25/EN_US")

(:name "CENTERLINE"
 :category :DIMENSION
 :aliases ("CL")
 :intl-name "_CENTERLINE"
 :synopsis "Creates a centerline associated with two selected lines or polyline segments."
 :options ("Layer")
 :arguments "Select the first line/segment; select the second line/segment; optionally use Layer to place the centerline on a specified layer."
 :description "Creates associative centerline geometry indicating an axis of symmetry between two selected lines or linear polyline segments; the centerline repositions automatically when the associated lines move. The pick locations determine the centerline direction."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D717F995-1A6E-40AA-851A-FF891DE21DED.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_centerline/V25/EN_US")

(:name "CENTERMARK"
 :category :DIMENSION
 :aliases ("CM")
 :intl-name "_CENTERMARK"
 :synopsis "Creates an associative center mark on a circle, arc, or polyarc."
 :options ("Layer")
 :arguments "Select a circle or arc (the command repeats for additional selections); optionally use Layer to place the mark on a specified layer."
 :description "Creates an associative, cross-shaped center mark at the center of a selected circle, arc, or polyarc; the mark follows the geometry when it moves or resizes. Appearance is controlled by system variables (e.g. CENTERMARKEXE, CENTERLAYER)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B9BBA2FD-FEB8-4793-8039-D65CD30D8264.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_centermark/V25/EN_US")

(:name "CENTERREASSOCIATE"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_CENTERREASSOCIATE"
 :synopsis "Associates or reassociates a center mark or centerline with selected objects."
 :options NIL
 :arguments "Select a center mark or centerline; then select the circle or arc (for a center mark) or the first and second lines (for a centerline)."
 :description "Links (or re-links) a center mark to a circle or arc, or a centerline to a pair of lines, restoring or establishing associativity."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E2CC39DA-55B6-4108-A394-86707DCFDE01.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_centerreassociate/V25/EN_US")

(:name "CENTERRESET"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_CENTERRESET"
 :synopsis "Resets center marks and centerlines."
 :options NIL
 :arguments "Select the center mark or centerline to reset."
 :description "Resets centerline/center mark extensions. AutoCAD resets centerline extensions to the current CENTEREXE system variable value (not the original dimensions); BricsCAD resets centerlines and center marks when their associated geometry has moved or been resized."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F6C8DB68-5A6B-44BB-AAEE-6CFE03909A58.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_centerreset/V25/EN_US")

(:name "CHAMFER"
 :category :MODIFY
 :aliases ("CHA")
 :intl-name "_CHAMFER"
 :synopsis "Creates chamfers (bevels) at the intersection of two objects or the adjacent edges of a 3D solid."
 :options ("Polyline" "Distance" "Angle" "Trim" "Method" "Multiple" "Undo"
           "Edge" "Loop" "Expression")
 :arguments "Select the first line/object (or type an option keyword such as Polyline, Distance, Angle, Trim, Method, Multiple), then select the second line/object; for 3D solids select an edge or Loop and specify the chamfer surface and distances."
 :description "Bevels or chamfers the edges of two 2D objects or the adjacent faces of a 3D solid, defined by two distances or a distance and an angle. It works between lines and polylines but not between two polylines."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B1DCF991-90A7-4DB0-96FC-BDA3FB76337C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_chamfer/V25/EN_US")

(:name "CHANGE"
 :category :MODIFY
 :aliases ("-CH")
 :intl-name "_CHANGE"
 :synopsis "Changes the properties of existing objects through the command line."
 :options ("Properties" "Color" "Elev" "Layer" "Ltype" "Ltscale" "Lweight"
           "Thickness" "Transparency" "Material" "Annotative")
 :arguments "Select objects, then specify a change point/new values (varies by object type: lines, circles, text, attribute definitions, blocks), or type Properties and choose a property (Color, Elev, Layer, Ltype, Ltscale, Lweight, Thickness, Transparency, Material, Annotative) with its new value."
 :description "Changes the properties of existing objects via the command line by relocating endpoints, adjusting dimensions such as radius or elevation, and altering visual properties. It has been largely superseded by the Properties panel."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0D1BC415-5CDC-449D-8019-885F654FB1B5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_change/V25/EN_US")

(:name "CHECKSTANDARDS"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_CHECKSTANDARDS"
 :synopsis "Checks the current drawing for inconsistencies that violate the standards."
 :options NIL
 :arguments "Takes no command-line arguments; it opens the Check Standards dialog box where violations are reviewed, fixed with a replacement, or marked as ignored."
 :description "Audits the current drawing against defined CAD standards (a .dws standards file specifying layers, dimension styles, linetypes, and text styles) and displays the Check Standards dialog box to identify and manage violations."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F47E5F56-88BE-4FC2-A0D6-D35E8DFAC7A6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_checkstandards/V25/EN_US")

(:name "CHPROP"
 :category :MODIFY
 :aliases NIL
 :intl-name "_CHPROP"
 :synopsis "Changes the properties of the selected entity."
 :options ("Color" "Truecolor" "COlorbook" "LAyer" "LineType" "linetype Scale"
           "Line Weight" "Thickness" "TRansparency" "Material" "Annotative"
           "Plotstyle")
 :arguments "Select one or more objects, then type a property keyword (Color, LAyer, LType/LineType, LtScale, LWeight, Thickness, TRansparency, Material, Annotative, Plotstyle) and supply its new value."
 :description "Changes the properties of one or more selected entities, with fewer options than the CHANGE command; when selected objects have different values for a property, \"varies\" is shown. It has been largely superseded by the Properties panel."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-05074362-FC4B-4582-A7A4-B3F6170BB4A7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_chprop/V25/EN_US")

(:name "CHSPACE"
 :category :MODIFY
 :aliases NIL
 :intl-name "_CHSPACE"
 :synopsis "On a layout, transfers selected objects between model space and paper space."
 :options ("TARGET" "SOURCE")
 :arguments "Select the objects to transfer; when multiple viewports are involved, choose the TARGET viewport and/or SOURCE viewport to control scaling of the moved objects."
 :description "Moves entities from paper space to model space and vice versa on a layout. Objects are automatically scaled to fit their new space and remain visually aligned with their former locations."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-343F7917-6CED-4823-8E38-90895FF740EB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_chspace/V25/EN_US")

(:name "CHURLS"
 :category :EDIT
 :aliases NIL
 :intl-name "_CHURLS"
 :synopsis "Changes previously placed URL addresses."
 :options NIL
 :arguments "Select an object with an attached URL; a dialog box appears to edit the URL, presenting each selected object's URL sequentially when multiple are selected."
 :description "Changes URLs previously attached to drawing entities; in BricsCAD it opens the Change URL for entities dialog box, and in AutoCAD (an Express Tool) it presents each selected object's URL for editing in a dialog."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A12668EB-396F-4637-AC24-9975642E48F5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_churls/V25/EN_US")

(:name "CIRCLE"
 :category :DRAW
 :aliases ("C")
 :intl-name "_CIRCLE"
 :synopsis "Creates a circle."
 :options ("3P" "2P" "Ttr" "Radius" "Diameter")
 :arguments "Supplies a center point followed by a radius, or the keyword \"D\" (Diameter) then a diameter value; alternatively the first response is a keyword: \"2P\" then two endpoints of a diameter, \"3P\" then three points on the circumference, or \"Ttr\" (tan-tan-radius) then two tangent objects and a radius. BricsCAD additionally offers Tan-Tan-Tan and arc-to-circle conversion."
 :description "Creates a circle using several methods: center point with radius or diameter, two points defining a diameter, three points on the circumference, or tangency-based construction (tangent-tangent-radius, and in BricsCAD tangent-tangent-tangent)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C60B6D5D-AAEB-420F-917F-6E6B47E92F48.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_circle/V25/EN_US")

(:name "CLEANSCREENOFF"
 :category :VIEW
 :aliases NIL
 :intl-name "_CLEANSCREENOFF"
 :synopsis "Displays user interface elements that were hidden by the CLEANSCREENON command."
 :options NIL
 :arguments "Takes no arguments; running it restores the interface state that existed before CLEANSCREENON was used."
 :description "Restores UI elements previously hidden in clean screen mode, returning the display to its state before CLEANSCREENON was used."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7C9CDCC6-8B1E-471D-9F6F-E1160F9AC3A8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_cleanscreenoff/V25/EN_US")

(:name "CLIPIT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_CLIPIT"
 :synopsis "Clips images, wipeouts, blocks or external references."
 :options NIL
 :arguments "Select the clipping edge (a polyline, circle, arc, ellipse or text entity), select the entity to clip, then enter the maximum allowable error distance for arc-segment resolution (default 0.02)."
 :description "Clips images, wipeouts, blocks, or external references using a clipping edge; only polyline, circle, arc, ellipse, or text entities may serve as the boundary. Curved boundaries are handled by converting arc segments into short straight segments controlled by a maximum error distance."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1200C4A7-53EC-43C3-8667-749E83FCDD35.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_clipit/V25/EN_US")

(:name "CLOSE"
 :category :FILE
 :aliases NIL
 :intl-name "_CLOSE"
 :synopsis "Closes the current drawing."
 :options NIL
 :arguments "Takes no arguments; if the drawing has unsaved changes a dialog prompts to save or discard before closing (read-only files require SAVEAS to save modifications)."
 :description "Closes the current drawing. If changes have been made since the last save, the user is prompted to save or discard them before closing."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-947A6040-0C95-413C-A1A3-2115D244B246.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_close/V25/EN_US")

(:name "COLOR"
 :category :OTHER
 :aliases ("COL" "COLOUR" "DDCOLOR" "DDCOLOUR" "SETCOLOR")
 :intl-name "_COLOR"
 :synopsis "Sets the current color for new objects via the Color dialog box."
 :options ("Index Color" "True Color" "Color Books" "ByLayer" "ByBlock")
 :arguments "Opens the Color / Select Color dialog box; the command itself supplies no command-line arguments (the -COLOR variant instead prompts for a color name or index number)."
 :description "Displays the Color (Select Color) dialog box to specify the current color for new objects and for layers, dimensions, backgrounds, and other elements. It offers three tabs: Index Color, True Color, and Color Books. The hyphen-prefixed -COLOR provides command-prompt options instead of the dialog."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F12EF623-7CD3-4864-8130-A3BF718D730D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_color/V25/EN_US")

(:name "COMMANDLINE"
 :category :VIEW
 :aliases NIL
 :intl-name "_COMMANDLINE"
 :synopsis "Displays the Command Line panel (Command window)."
 :options NIL
 :arguments "No command-line arguments; opens and displays the Command Line panel (Command window) in the current workspace."
 :description "Opens the Command Line panel (Command window) and displays it in the current workspace at its previous size and location. The window accepts command and system-variable input and shows the prompts that guide you through a command sequence. It can also be toggled with Ctrl+9."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E2D3C5EC-19AF-4694-84B4-2A36EF6A2E3D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_commandline/V25/EN_US")

(:name "COMMANDLINEHIDE"
 :category :VIEW
 :aliases NIL
 :intl-name "_COMMANDLINEHIDE"
 :synopsis "Hides the Command Line panel (Command window)."
 :options NIL
 :arguments "No command-line arguments; hides the Command Line panel (Command window) from the current workspace."
 :description "Closes/hides the Command Line panel (Command window) from the current workspace; if the panel is stacked, its tab or icon is removed from that stack. When the Command Line is hidden, commands can be entered using dynamic input boxes displayed near the cursor. Display can be toggled with Ctrl+9."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7F755A31-02FF-4BCE-B073-CAD39A9B669E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_commandlinehide/V25/EN_US")

(:name "CONE"
 :category :|3D|
 :aliases NIL
 :intl-name "_CONE"
 :synopsis "Creates a 3D solid in the shape of a cone."
 :options ("Center" "3Point" "2Point" "TTR (Tangent, Tangent, Radius)"
           "Elliptical" "Diameter" "Axis endpoint" "Top radius")
 :arguments "A base center point (or the 3Point, 2Point, TTR, or Elliptical option), then the base radius (or Diameter), then the height (or the 2Point, Axis endpoint, or Top radius option)."
 :description "Creates a 3D solid with a circular or elliptical base that tapers symmetrically to a point or to a circular or elliptical planar face. The base can be defined by center point, three points, two points, tangent-tangent-radius, or an elliptical method. A cone frustum is created with the Top radius option; curved-solid smoothness is governed by the FACETRES system variable."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EF480870-AE25-4D6E-9E54-4708D711C127.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_cone/V25/EN_US")

(:name "CONSTRAINTBAR"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_CONSTRAINTBAR"
 :synopsis "Displays or hides the geometric constraint bars on objects."
 :options ("Show" "Hide" "Reset")
 :arguments "A Show, Hide, or Reset option together with a selection set of entities constrained with geometric constraints."
 :description "Shows and hides constraint bars next to entities constrained with geometric constraints; constraint bars are initially hidden when a drawing is opened. Show displays the constraint bar for the selected entities, Hide hides it, and Reset relocates constraint bars to their default positions near the midpoint of the entity."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-078525BD-6684-4709-9FB1-E128AFCAB983.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_constraintbar/V25/EN_US")

(:name "CONVERTCTB"
 :category :PLOT
 :aliases NIL
 :intl-name "_CONVERTCTB"
 :synopsis "Converts a color-dependent plot style table (CTB) to a named plot style table (STB)."
 :options NIL
 :arguments "Opens a file dialog to select the color-dependent plot style table (CTB) file to convert (followed by a dialog to save the resulting named STB file); no command-line keyword arguments."
 :description "Converts a color-dependent plot style table (CTB) to a named plot style table (STB). It saves a copy of the CTB as an STB for use with drawings employing named plot styles without modifying the original, automatically creating named plot styles from unique plot properties and assigning generic names such as STYLE 1 and STYLE 2 that can be renamed later."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4386F6C6-CE6D-4C62-8EC3-E68B8738E537.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_convertctb/V25/EN_US")

(:name "CONVERTPOLY"
 :category :MODIFY
 :aliases NIL
 :intl-name "_CONVERTPOLY"
 :synopsis "Converts polylines between heavyweight (legacy) and lightweight (optimized) formats."
 :options ("Heavy" "Light" "3dPoly")
 :arguments "A conversion option (Heavy, Light, or 3dPoly) and a selection of the polylines to convert."
 :description "Converts 2D (and, in BricsCAD, 3D) polylines between the legacy heavyweight definition and the optimized lightweight definition, reducing file size and improving performance. Heavy converts lightweight polylines to legacy 2D polylines and Light converts legacy 2D polylines to lightweight; it does not convert curve-fit, splined polylines, or polylines with extended object data on vertices."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F3FAA27B-A9E9-46C9-BBED-857A8DCF8409.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_convertpoly/V25/EN_US")

(:name "CONVERTPSTYLES"
 :category :PLOT
 :aliases NIL
 :intl-name "_CONVERTPSTYLES"
 :synopsis "Converts the current drawing between named (STB) and color-dependent (CTB) plot style modes."
 :options NIL
 :arguments "No command-line keyword arguments; converts the current drawing to the opposite plot style mode (named or color-dependent)."
 :description "Converts the current drawing from color-dependent (CTB) to named (STB) plot style mode and vice versa; a drawing can use either mode but not both. It adjusts the PSTYLEMODE system variable and converts the drawing's plot style tables first (using CONVERTCTB), letting plot properties be managed independently of object color."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3A68A211-1E6C-4A71-8503-62722A1155A6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_convertpstyles/V25/EN_US")

(:name "CONVTOMESH"
 :category :|3D|
 :aliases NIL
 :intl-name "_CONVTOMESH"
 :synopsis "Converts eligible objects to mesh objects."
 :options NIL
 :arguments "Select one or more valid entities, then press Enter to complete the command."
 :description "Converts valid 2D and 3D objects (3D solids, surfaces, polygon/legacy meshes, 3D faces, regions, and closed polylines) into mesh objects; in BricsCAD, BIM data and GUID information are preserved. Display resolution/smoothness is controlled by mesh tessellation settings (the FACETRES system variable in BricsCAD). To reverse the process use CONVTOSOLID or CONVTOSURFACE."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-810D73BD-1C40-4985-AF31-60D9857F6E64.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_convtomesh/V25/EN_US")

(:name "CONVTOSOLID"
 :category :|3D|
 :aliases NIL
 :intl-name "_CONVTOSOLID"
 :synopsis "Converts eligible 3D objects to 3D solids."
 :options NIL
 :arguments "Select one or more valid entities, then press Enter to complete the command."
 :description "Converts qualifying 2D and 3D objects (watertight meshes, enclosing/watertight surfaces, polygon meshes, circles with thickness, and closed polylines) into 3D solid objects; in BricsCAD, BIM data and GUIDs are preserved. Conversion behavior for meshes is controlled by the SMOOTHMESHCONVERT system variable to produce either smooth or faceted results."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7A9C2DEA-961C-413D-BC20-D00654457599.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_convtosolid/V25/EN_US")

(:name "CONVTOSURFACE"
 :category :|3D|
 :aliases NIL
 :intl-name "_CONVTOSURFACE"
 :synopsis "Converts objects to 3D surfaces."
 :options NIL
 :arguments "(command \"_CONVTOSURFACE\" ss \"\") — select one or more valid entities to convert, then Enter to complete."
 :description "Converts valid 2D and 3D objects (solids, regions, polylines, lines, arcs, circles, meshes, planar faces) into surface entities. Smoothness/faceting of the result is controlled by the SMOOTHMESHCONVERT system variable."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7AF911DF-986F-4897-8651-921BE8710B14.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_convtosurface/V25/EN_US")

(:name "COPY"
 :category :MODIFY
 :aliases ("CO" "CP")
 :intl-name "_COPY"
 :synopsis "Copies objects a specified distance in a specified direction."
 :options ("Displacement" "Mode" "Array" "Multiple" "Undo" "Repeat" "Exit")
 :arguments "Selection set of entities, then a base point followed by second point(s) of displacement (or a Displacement vector). Keyword options may be supplied: \"Displacement\", \"mOde\" (Single/Multiple), \"Array\" (number of items, then second point or Fit), \"Undo\", \"Exit\". An empty string ends the command."
 :description "Duplicates selected objects, placing copies by a base point and displacement vector, a directional/linear array, or repeated multiple copies. The COPYMODE system variable governs whether multiple copies are made automatically."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1CF9287F-06E8-4D03-8377-2E130862FE02.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_copy/V25/EN_US")

(:name "COPYBASE"
 :category :EDIT
 :aliases NIL
 :intl-name "_COPYBASE"
 :synopsis "Copies selected objects to the Clipboard along with a specified base point."
 :options NIL
 :arguments "(command \"_COPYBASE\" basepoint ss \"\") — specify a base point, then select objects to copy to the Clipboard."
 :description "Copies entities to the Clipboard with a user-defined base point. When pasted (via PASTECLIP) into the same or another drawing, the objects are positioned relative to that base point."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-59113CD3-B5EC-404B-989C-F98F4B70EDB5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_copybase/V25/EN_US")

(:name "COPYCLIP"
 :category :EDIT
 :aliases NIL
 :intl-name "_COPYCLIP"
 :synopsis "Copies selected objects to the Clipboard."
 :options NIL
 :arguments "(command \"_COPYCLIP\" ss \"\") — select objects to copy to the Clipboard."
 :description "Copies selected entities to the Clipboard for pasting into drawings and other documents. Data is stored in multiple formats and the most information-rich format is used on paste; PICTUREEXPORTSCALE controls resolution for bitmap-format export."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8C693775-7BB2-48D6-9A6B-770F8A870707.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_copyclip/V25/EN_US")

(:name "COPYHIST"
 :category :EDIT
 :aliases NIL
 :intl-name "_COPYHIST"
 :synopsis "Copies the text in the command line history to the Clipboard."
 :options NIL
 :arguments "(command \"_COPYHIST\") — takes no input; copies all Command line history text to the Clipboard."
 :description "Copies all text from the Command line history to the Clipboard. The SCRLHIST system variable controls how many lines of command history are retained in the Prompt History window."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2B86E8F7-B846-4113-B9EE-1F5010A8515D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_copyhist/V25/EN_US")

(:name "COPYM"
 :category :MODIFY
 :aliases NIL
 :intl-name "_COPYM"
 :synopsis "Copies multiple objects with Repeat, Array, Divide and Measure options."
 :options ("Repeat" "Divide" "Measure" "Array")
 :arguments "(command \"_COPYM\" ss \"\" basepoint ...) — select the entities to copy, specify the base point, then supply option keyword/point input (Repeat, Divide, Measure, or Array with Pick/Measure/Divide sub-options)."
 :description "Express Tool that makes multiple copies of selected entities. After choosing objects and a base point, the user can use Repeat, Divide, Measure, or Array methods to generate copies with specified spacing and arrangement."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B850134A-4669-4FCC-8CE6-A233B5337F63.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_copym/V25/EN_US")

(:name "COPYTOLAYER"
 :category :LAYER
 :aliases NIL
 :intl-name "_COPYTOLAYER"
 :synopsis "Copies one or more objects to another layer."
 :options ("Name" "Displacement")
 :arguments "(command \"_COPYTOLAYER\" ss \"\" ...) — select objects to copy, then select an object on the destination layer (or use Name for the dialog), and optionally specify a base point/displacement for the copies."
 :description "Creates duplicates of selected entities on a layer specified by the user, either by picking an entity on the target layer or choosing the target layer in the Copy To Layer dialog. A different location can be specified for the duplicated entities."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0A1C99AD-53BE-4272-AD32-DAFECAECD6F7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_copytolayer/V25/EN_US")

(:name "CUILOAD"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_CUILOAD"
 :synopsis "Loads a customization file (CUIx)."
 :options ("Name of customization file to load")
 :arguments "(command \"_CUILOAD\" ...) — normally opens a dialog (Load/Unload Customizations in AutoCAD; Customization Groups in BricsCAD); the command-line form takes the path and filename of the customization file to load."
 :description "In AutoCAD, opens a dialog to locate and load CUIx files (the XML-based CUIx format replaced legacy MNS, MNU, and CUI types). In BricsCAD, opens the Customization Groups dialog box to load or unload partial CUI files."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B5969D87-7FE8-47B4-A02F-38E7897A6CB4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_cuiload/V25/EN_US")

(:name "CUIUNLOAD"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_CUIUNLOAD"
 :synopsis "Unloads a CUIx file."
 :options NIL
 :arguments "(command \"_CUIUNLOAD\" ...) — normally opens a dialog (Load/Unload Customizations in AutoCAD, with the same options as CUILOAD; Customization Groups in BricsCAD); the command-line form supplies the name of the customization group to unload."
 :description "In AutoCAD, opens the Load/Unload Customizations dialog box with the same options as CUILOAD, differing mainly in the Command prompts. In BricsCAD, opens the Customization Groups dialog box to manage (unload) partial CUI files."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-23680536-A347-424E-A583-A9EA40EC9503.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_cuiunload/V25/EN_US")

(:name "CUSTOMIZE"
 :category :CUSTOMIZATION
 :aliases ("CUI")
 :intl-name "_CUSTOMIZE"
 :synopsis "Opens a customization dialog box (BricsCAD: Customize dialog; AutoCAD: tool palettes/tool palette groups)."
 :options ("File" "Menus" "Toolbars" "Ribbon" "Keyboard" "Mouse" "Tablet"
           "Quad" "Entity Filter" "Properties" "Workspaces" "Command Aliases"
           "Shell Commands")
 :arguments "(command \"_CUSTOMIZE\") — takes no command-line input; opens the customization dialog box."
 :description "In BricsCAD, CUSTOMIZE opens the Customize dialog box for customizing the user interface (menus, toolbars, ribbon, keyboard, mouse, quad, workspaces, aliases, and more). In AutoCAD, CUSTOMIZE customizes tool palettes and tool palette groups via the Customize dialog box."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-82119B43-CCB5-4C52-8B57-D2F479A384F0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_customize/V25/EN_US")

(:name "CUTCLIP"
 :category :EDIT
 :aliases NIL
 :intl-name "_CUTCLIP"
 :synopsis "Copies selected objects to the Clipboard and removes them from the drawing."
 :options NIL
 :arguments "(command \"_CUTCLIP\") then a selection set of objects; the selected objects are cut to the Clipboard and erased from the drawing."
 :description "Copies selected objects to the Clipboard and removes them from the current drawing. The copied content can be pasted into other drawings or documents (in AutoCAD, as embedded OLE objects without link information)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5F5CB4BE-68F7-478A-A41A-7EEC65851BD7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_cutclip/V25/EN_US")

(:name "CVHIDE"
 :category :VIEW
 :aliases ("POINTOFF")
 :intl-name "_CVHIDE"
 :synopsis "Turns off the display of control vertices for all NURBS surfaces and curves."
 :options NIL
 :arguments "(command \"_CVHIDE\") takes no further input; it hides the control-vertex frames of all NURBS curves and surfaces in the drawing."
 :description "Hides (turns off) the display of control-vertex frames for all NURBS curves and surfaces in the current drawing. BricsCAD reports on the command line how many elements were processed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-26F8F318-4490-498E-81B4-4A2570284DAD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_cvhide/V25/EN_US")

(:name "CYLINDER"
 :category :|3D|
 :aliases ("CYL")
 :intl-name "_CYLINDER"
 :synopsis "Creates a 3D solid cylinder."
 :options ("Center" "3P" "2P" "TTR" "Elliptical" "Diameter" "2Point"
           "Axis endpoint")
 :arguments "(command \"_CYLINDER\" center-point base-radius height); or supply keyword options to define the base (3P, 2P, TTR, Elliptical) and the height (2Point or Axis endpoint)."
 :description "Creates a 3D solid in the shape of a circular or elliptical cylinder. The base is defined by a center point, three points, two points, tangent-tangent-radius, or an ellipse, and the height by a distance or an axis endpoint; the base stays parallel to the workplane. In BricsCAD Lite it invokes AI_CYLINDER instead."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-81157F00-D5A5-4307-AD0C-4332066DE2AE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_cylinder/V25/EN_US")

(:name "DATAEXTRACTION"
 :category :TABLE
 :aliases NIL
 :intl-name "_DATAEXTRACTION"
 :synopsis "Extracts drawing data and merges data from an external source to a data extraction table or external file."
 :options NIL
 :arguments "(command \"_DATAEXTRACTION\") opens the Data Extraction wizard dialog; there are no command-line arguments."
 :description "Exports object properties, block attributes, and drawing information to a data extraction table or an external data file, and can merge data from an external source such as an Excel spreadsheet. It is driven by a multi-page Data Extraction wizard."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5A39FFE8-10AC-4AE5-8EF4-D097C8261D1A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dataextraction/V25/EN_US")

(:name "DATALINK"
 :category :TABLE
 :aliases NIL
 :intl-name "_DATALINK"
 :synopsis "Displays the Data Link (Datalink Manager) dialog box."
 :options NIL
 :arguments "(command \"_DATALINK\") opens the Data Link Manager dialog; there are no command-line arguments."
 :description "Opens the Data Link Manager dialog box to create and manage links between drawing tables and data in a Microsoft Excel (XLS, XLSX, or CSV) file. Tables can be linked to whole spreadsheets, rows, columns, cells, or cell ranges."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E6AD1DCE-6A0A-4714-808E-FA4D895C2E7B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_datalink/V25/EN_US")

(:name "DATALINKUPDATE"
 :category :TABLE
 :aliases NIL
 :intl-name "_DATALINKUPDATE"
 :synopsis "Updates data to or from an established external data link."
 :options ("Update data link" "Write data link" "Select objects"
           "All data links")
 :arguments "(command \"_DATALINKUPDATE\") then choose the direction (Update data link or Write data link) and select objects or all data links to synchronize."
 :description "Synchronizes linked data between tables in the current drawing and external source files. It can update drawing tables from the external file or write drawing changes back to the source file."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1F8FE1F0-5229-4A5C-B69F-DA47CC9C25A9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_datalinkupdate/V25/EN_US")

(:name "DBLIST"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_DBLIST"
 :synopsis "Lists database information for each object in the drawing."
 :options NIL
 :arguments "(command \"_DBLIST\") takes no arguments; it lists every entity. Press Enter to continue paging or Esc to cancel."
 :description "Lists database information (such as handle, current space, layer, and color) for every object in the drawing, displayed in the text/prompt-history window. For large drawings the listing can be long, so it pauses when the window is full and can be stopped with Esc."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-AD6A2435-FF3C-4A75-BBDF-D335BA2714BC.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dblist/V25/EN_US")

(:name "DCALIGNED"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_DCALIGNED"
 :synopsis "Constrains the distance between two points on different objects."
 :options ("Object" "Point & Line" "2Lines")
 :arguments "(command \"_DCALIGNED\" ...) select constraint points or objects (Object, Point & Line, or 2Lines), then specify the dimension-line location and the distance value."
 :description "Applies an aligned dimensional constraint that locks the distance between two points, between a point and a line/entity, the length of a line/polyline segment or arc, or the distance between two lines (making them parallel). Only the distance is fixed; the entities can still move and rotate. It is equivalent to the Aligned option of DIMCONSTRAINT."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-615063B5-1E07-4756-A367-64C743BF3810.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dcaligned/V25/EN_US")

(:name "DCANGULAR"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_DCANGULAR"
 :synopsis "Constrains the angle between line or polyline segments, arcs, or three points on objects."
 :options ("Line" "Arc" "3Point")
 :arguments "(command \"_DCANGULAR\" ...) select two line/polyline segments, an arc or polyline arc, or three constraint points, then specify the dimension-line location and the angle value."
 :description "Applies an angular dimensional constraint on the angle between two lines or straight polyline segments, the angle swept by an arc or polyline arc segment, or the angle defined by three constraint points (first point is the vertex). Angle values are stored as entered but displayed per the drawing units."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B62A01C2-4AD5-49EF-AA4F-891A4D681796.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dcangular/V25/EN_US")

(:name "DCCONVERT"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_DCCONVERT"
 :synopsis "Converts associative dimensions to dimensional constraints."
 :options NIL
 :arguments "(command \"_DCCONVERT\") then a selection set of associative dimensions; each is converted to the matching dimensional constraint."
 :description "Converts associative dimensions into the appropriate dimensional constraints (for example, linear dimensions to linear constraints, diameter dimensions to diameter constraints); non-associative dimensions are filtered out of the selection. It is equivalent to the Convert option of DIMCONSTRAINT, and the resulting constraints display in gray."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4523380B-A6D7-4F08-869B-293277B23BFF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dcconvert/V25/EN_US")

(:name "DCDIAMETER"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_DCDIAMETER"
 :synopsis "Applies a diametrical dimensional constraint to a circle, arc, or polyline arc segment."
 :options NIL
 :arguments "Select a circle, arc, or polyline arc segment, then specify the dimension line location; edit the constraint value if prompted."
 :description "Constrains the diameter of a circle or an arc. It is equivalent to the Diameter option of DIMCONSTRAINT; the entity may still be moved and rotated after the diameter is fixed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EE1A1D15-05D3-4459-827A-6E1F07C6611D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dcdiameter/V25/EN_US")

(:name "DCDISPLAY"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_DCDISPLAY"
 :synopsis "Displays or hides the dynamic dimensional constraints associated with a selection set of objects."
 :options ("Show" "Hide")
 :arguments "Select the objects whose dimensional constraints are affected, then choose Show or Hide."
 :description "Toggles the display of dimensional constraints attached to selected entities between visible and hidden. Dimensional constraints are initially hidden when a drawing containing them is opened, which helps prevent clutter."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-09A78C85-9F99-4346-9DB9-F637C4F22D97.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dcdisplay/V25/EN_US")

(:name "DCHORIZONTAL"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_DCHORIZONTAL"
 :synopsis "Constrains the horizontal (X) distance between points on an object, or between two points on different objects."
 :options ("Object" "Entity")
 :arguments "Specify the first and second constraint points (or use the Object/Entity option to select a single entity), then specify the dimension line location."
 :description "Horizontally constrains the distance between two points or the length of a single entity in the X direction of the current coordinate system. It is equivalent to the Horizontal option of DIMCONSTRAINT and works with lines, polyline segments, arcs, and constraint points."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C6410EED-6B06-4139-BD02-217B46675C67.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dchorizontal/V25/EN_US")

(:name "DCLINEAR"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_DCLINEAR"
 :synopsis "Creates a horizontal or vertical dimensional constraint based on the locations of the extension line origins and the dimension line."
 :options ("Object" "Entity")
 :arguments "Specify the first and second constraint points (or use the Object/Entity option to select a single entity), then move the cursor to set horizontal or vertical direction and specify the dimension line location."
 :description "Constrains the distance between two points or the length of a single entity to be horizontal or vertical, similar to DIMLINEAR. The constraint direction depends on cursor movement during execution; it is the Linear option of DIMCONSTRAINT."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E64A038C-0928-4E8E-BC60-356FDF86CFFB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dclinear/V25/EN_US")

(:name "DCVERTICAL"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_DCVERTICAL"
 :synopsis "Constrains the vertical (Y) distance between points on an object, or between two points on different objects."
 :options ("Object" "Entity")
 :arguments "Specify the first and second constraint points (or use the Object/Entity option to select a single entity), then specify the dimension line location."
 :description "Vertically constrains the distance between two points or the length of an entity in the Y direction of the current coordinate system. When a line or arc is selected, the vertical distance between its endpoints becomes constrained; it applies to lines, arcs, and polyline segments."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9ADCF482-CDFE-453E-A48E-BCDDDB801B42.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dcvertical/V25/EN_US")

(:name "DELAY"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_DELAY"
 :synopsis "Provides a timed pause within a script."
 :options ("Milliseconds to delay")
 :arguments "Supply the number of milliseconds to wait before the next command executes."
 :description "Pauses script execution before proceeding to the next command; it is meant to be used with scripts. In AutoCAD the maximum value is 32767 milliseconds (about 33 seconds); in BricsCAD values from 0 to 2,147,483,627 (about 24 days) are accepted."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C352A9F4-0057-43AD-9642-9BAA881224F8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_delay/V25/EN_US")

(:name "DELCONSTRAINT"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_DELCONSTRAINT"
 :synopsis "Removes all geometric and dimensional constraints from a selection set of objects."
 :options ("ALL")
 :arguments "Select one or more entities, or type ALL to remove all constraints from the entire drawing."
 :description "Deletes both geometric and dimensional constraints applied to the selected entities, and can remove all constraints from the drawing at once by typing ALL. In AutoCAD the number of removed constraints is reported on the command line."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E47B6F79-C7DA-45ED-AFA6-6C0945DB6375.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_delconstraint/V25/EN_US")

(:name "DGNEXPORT"
 :category :FILE
 :aliases NIL
 :intl-name "_DGNEXPORT"
 :synopsis "Creates one or more DGN files from the current drawing."
 :options NIL
 :arguments "In the file dialog, specify the output DGN file name and location, then configure the Export DGN Settings dialog."
 :description "Exports the current drawing to a MicroStation DGN file (*.dgn), opening a file selection dialog followed by an Export DGN Settings dialog. AutoCAD supports both V8 and V7 DGN versions and warns against accented or Asian characters in filenames."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-70E12630-4067-41E0-8D38-E165B5AD139E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dgnexport/V25/EN_US")

(:name "DGNIMPORT"
 :category :FILE
 :aliases NIL
 :intl-name "_DGNIMPORT"
 :synopsis "Imports the data from a DGN file into a new DWG file or the current DWG file."
 :options NIL
 :arguments "In the Import DGN File dialog, select the .dgn file to import, then configure the Import DGN Settings dialog."
 :description "Opens a dialog to select a MicroStation .dgn file and import it into the drawing; in AutoCAD the target (new or current DWG) depends on the DGNIMPORTMODE system variable. Numerous system variables and the DGNIMPORTOPTIONS command control import behavior."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0B1EC8D0-A34C-4F4E-8E72-A71656F7EF55.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dgnimport/V25/EN_US")

(:name "DIGITALSIGN"
 :category :FILE
 :aliases NIL
 :intl-name "_DIGITALSIGN"
 :synopsis "Attaches a digital signature to a drawing, which is removed if an unauthorized change is made."
 :options NIL
 :arguments "In the Digital Signatures / Attach Digital Signatures dialog, select a digital certificate and optionally add a comment and select a time server."
 :description "Opens the Digital Signatures dialog box to attach an encrypted block of information that validates the file's origin, authenticity, and unaltered state. In AutoCAD the Attach Digital Signatures dialog opens when a valid digital ID exists on the system; in BricsCAD the signature persists after renaming and re-applies to subsequent saves until the drawing is closed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-52550D2E-2F2C-4116-833F-99058BF102E0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_digitalsign/V25/EN_US")

(:name "DIM"
 :category :DIMENSION
 :aliases ("DIMENSION")
 :intl-name "_DIM"
 :synopsis "Creates multiple dimensions and types of dimensions with a single command."
 :options ("HORizontal" "VErtical" "ALigned" "ANgular" "Leader" "OBlique"
           "ROtated" "CEnter" "Diameter" "RAdius" "Baseline" "COntinue"
           "ORdinate" "Position" "DIStribute" "Equal" "Offset" "UPdate"
           "STatus" "OVerride" "SEttings" "LAyer" "Undo" "Move away" "Break up"
           "Replace" "None")
 :arguments "Select an object or point to dimension (or enter a dimension-type keyword such as Baseline, Continue, Ordinate, Angular, Align), then pick the dimension line location; ENTER ends the command."
 :description "Creates multiple dimensions or types of dimensions at once in a single workflow. You can select objects or points on objects to dimension and then click to place the dimension line, with previews generated for the suitable dimension type when hovering over objects."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-45C1A271-9650-4927-858F-B3BDB19B3E6C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dim/V25/EN_US")

(:name "DIMALIGNED"
 :category :DIMENSION
 :aliases ("DAL" "DIMALI")
 :intl-name "_DIMALIGNED"
 :synopsis "Creates an aligned linear dimension aligned with the extension line origin points."
 :options ("Origin of first extension line" "Origin of second extension line"
           "Location of dimension line" "Select object" "Mtext" "Text" "Angle")
 :arguments "Specify the origin of the first extension line and the origin of the second extension line (or select an object), then specify the dimension line location; optional Mtext, Text, and Angle prompts follow."
 :description "Creates a linear dimension that is aligned with the origin points of the extension lines, based on the current dimension style. It can dimension isometric views to reflect actual true geometry size."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D7C05A85-8985-4576-B22C-5A795DD5B179.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimaligned/V25/EN_US")

(:name "DIMANGULAR"
 :category :DIMENSION
 :aliases ("DAN" "DIMANG")
 :intl-name "_DIMANGULAR"
 :synopsis "Creates an angular dimension measuring the angle between objects or three points."
 :options ("Select line, arc, or circle" "Other line for angular dimension"
           "Vertex of angle" "First side of angle" "Other side of angle"
           "Location of dimension arc" "Mtext" "Text" "Angle" "Quadrant")
 :arguments "Select an arc, circle, or line (or press ENTER to specify the vertex and both sides of the angle), then specify the location of the dimension arc; optional Mtext, Text, Angle, and Quadrant prompts follow."
 :description "Creates an angular dimension by selecting an entity or specifying the vertex and both sides of the angle, measuring the angle between selected geometric objects or 3 points. The dimension is based on the current dimension style."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6AB63ECB-BBCB-4D0F-B7BE-1674349A1FF9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimangular/V25/EN_US")

(:name "DIMARC"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMARC"
 :synopsis "Creates an arc length dimension measuring the length of an arc or polyline arc segment."
 :options ("Select arc or polyline arc segment" "Location of dimension arc"
           "Mtext" "Text" "Angle" "Partial" "Leader" "No Leader")
 :arguments "Select an arc or polyline arc segment, then specify the arc length dimension location; optional Mtext, Text, Angle, Partial, Leader, and No leader prompts follow."
 :description "Creates a dimension that measures the distance along an arc or polyline arc segment, based on the current dimension style. The extension lines can be orthogonal or radial, with an arc symbol displayed above or before the dimension text."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-280C95BF-1CD6-451C-8093-C70ECBF8D7E7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimarc/V25/EN_US")

(:name "DIMBASELINE"
 :category :DIMENSION
 :aliases ("DBA" "DIMBASE")
 :intl-name "_DIMBASELINE"
 :synopsis "Creates stacked linear, angular, or ordinate dimensions from a common baseline."
 :options ("Select starting dimension" "Origin of next extension line"
           "Feature location" "Undo" "Select")
 :arguments "Optionally select the base/starting dimension, then specify each next extension line origin to create successive baseline dimensions; use Undo or Select as needed; ENTER ends the command."
 :description "Creates stacked linear, angular, or ordinate dimensions from the same baseline as an existing (previous or selected) dimension. The spacing between baseline dimensions is set through the Dimension Style Manager, and the dimension style is inherited from the previous or selected dimension by default."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-19EA3161-D4A0-4280-9707-0A003C5B8A90.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimbaseline/V25/EN_US")

(:name "DIMBREAK"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMBREAK"
 :synopsis "Breaks or restores dimension lines, extension lines, and leaders where they cross other objects."
 :options ("Select dimension" "Select object" "Multiple" "Auto" "Remove"
           "Manual")
 :arguments "Select the dimension to break, then select the crossing object(s), or choose Multiple, Auto, Manual, or Remove."
 :description "Breaks dimension lines, extension lines, and leaders at the locations where they cross other entities, and can also remove such breaks. Dimension breaks can be added to linear, angular, and ordinate dimensions, among others."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-926915C5-C398-46C6-A5D8-16F0D5791760.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimbreak/V25/EN_US")

(:name "DIMCENTER"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMCENTER"
 :synopsis "Creates a non-associative center mark or centerlines at the center of a circle, arc, or polyarc."
 :options ("Select arc or circle to dimension")
 :arguments "Select an arc, polyline arc segment, or circle to place the center mark; appearance and length are controlled by the DIMCEN system variable."
 :description "Creates the non-associative center mark or the centerlines of circles and arcs. The appearance and length of the center mark lines are controlled by the DIMCEN system variable (BricsCAD notes CENTERMARK should be used for associative center marks)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A1362329-04E0-4715-B8DA-D1486C80D81F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimcenter/V25/EN_US")

(:name "DIMCONTINUE"
 :category :DIMENSION
 :aliases ("DCO" "DIMCONT")
 :intl-name "_DIMCONTINUE"
 :synopsis "Creates a dimension that continues in a line or arc from the last or a selected linear, angular, or ordinate dimension."
 :options ("Undo" "Select")
 :arguments "Supplies successive points for the next extension line origin (or a selected starting dimension), then Enter to end; optional Undo/Select keywords."
 :description "Continues creating dimensions from the second extension line of the previous or a selected linear, angular, or ordinate dimension, aligning dimension lines automatically using the current dimension style."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-27CF5248-EECB-4F5E-9A25-39ED399EA1EC.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimcontinue/V25/EN_US")

(:name "DIMDIAMETER"
 :category :DIMENSION
 :aliases ("DDI" "DIMDIA")
 :intl-name "_DIMDIAMETER"
 :synopsis "Creates a diameter dimension for a circle or an arc."
 :options ("Mtext" "Text" "Angle")
 :arguments "Selects an arc or circle, then specifies the dimension line location; optional Mtext/Text/Angle keywords."
 :description "Measures the diameter of a selected circle or arc and draws a diametric dimension with a diameter symbol, using the current dimension style; the text angle and content can be overridden."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2E64616D-5C96-46A6-BDA2-9782F9036BE3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimdiameter/V25/EN_US")

(:name "DIMDISASSOCIATE"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMDISASSOCIATE"
 :synopsis "Removes associativity from selected dimensions."
 :options NIL
 :arguments "Selects dimension objects; reports how many were disassociated."
 :description "Filters the selection to associative dimensions not on locked layers and in the current space, then removes their associativity and reports how many dimensions were disassociated."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A4291410-170D-4DB7-96AA-01B18B67B31C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimdisassociate/V25/EN_US")

(:name "DIMEDIT"
 :category :DIMENSION
 :aliases ("DED" "DIMED")
 :intl-name "_DIMEDIT"
 :synopsis "Edits dimension text and extension lines."
 :options ("Home" "New" "Rotate" "Oblique")
 :arguments "Supplies an editing keyword (Home/New/Rotate/Oblique), then selects dimensions and any required angle or text value."
 :description "Rotates, replaces, or restores dimension text and changes the oblique angle of extension lines on linear dimensions."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4C422870-32A1-457B-8D1E-BD4AF7967FF1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimedit/V25/EN_US")

(:name "DIMEX"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMEX"
 :synopsis "Exports dimension styles and their settings to an external file."
 :options ("File" "Available Dimension Styles" "Export")
 :arguments "Opens a dialog; supplies no command-line arguments (choose export file, select dimension styles, click Export)."
 :description "Opens a dialog that exports named dimension styles and their settings from the current drawing to an external file for reuse in other drawings. In AutoCAD this is provided as an Express Tool."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9DD96CAB-D7FE-4018-AA60-6309A2D4F6D3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimex/V25/EN_US")

(:name "DIMLINEAR"
 :category :DIMENSION
 :aliases ("DIMHORIZONTAL" "DIMLIN" "DIMROTATED" "DIMVERTICAL" "DLI")
 :intl-name "_DIMLINEAR"
 :synopsis "Creates a linear dimension with a horizontal, vertical, or rotated dimension line."
 :options ("Mtext" "Text" "Angle" "Horizontal" "Vertical" "Rotated"
           "Select entity")
 :arguments "Supplies first and second extension line origins (or selects an entity), then the dimension line location; optional Mtext/Text/Angle/Horizontal/Vertical/Rotated keywords."
 :description "Creates a linear dimension (horizontal, vertical, or rotated) from two extension line origins or a selected entity, using the current dimension style; text and angle can be overridden."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E908848F-4621-43D2-B377-FD3FBC2B8848.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimlinear/V25/EN_US")

(:name "DIMORDINATE"
 :category :DIMENSION
 :aliases ("DIMORD" "DOR")
 :intl-name "_DIMORDINATE"
 :synopsis "Creates ordinate dimensions."
 :options ("Xdatum" "Ydatum" "Mtext" "Text" "Angle")
 :arguments "Selects the feature location point, then the leader endpoint (direction sets X or Y); optional Xdatum/Ydatum/Mtext/Text/Angle keywords."
 :description "Creates ordinate dimensions measuring the X or Y distance from the current UCS origin (datum) to a specified feature point, using the current dimension style."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7F5C4A2C-117A-486B-A26E-6F8AC2BD9D8A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimordinate/V25/EN_US")

(:name "DIMRADIUS"
 :category :DIMENSION
 :aliases ("DIMRAD" "DRA")
 :intl-name "_DIMRADIUS"
 :synopsis "Creates a radius dimension for a circle or an arc."
 :options ("Mtext" "Text" "Angle")
 :arguments "Selects an arc or circle, then specifies the dimension line location; optional Mtext/Text/Angle keywords."
 :description "Measures the radius of a selected circle or arc and draws a radial dimension with a radius symbol, using the current dimension style; text angle and content can be overridden."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-99EED401-D7DF-4CF3-95ED-BBD107A13855.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimradius/V25/EN_US")

(:name "DIMREASSOCIATE"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMREASSOCIATE"
 :synopsis "Associates or reassociates selected dimensions to objects or points on objects."
 :options ("Disassociated")
 :arguments "Selects dimensions (or the Disassociated keyword for all disassociated dimensions), then specifies the association point or entity for each highlighted dimension in turn."
 :description "Highlights each selected dimension in turn and prompts for association points or entities, associating or reassociating linear, diameter, radius, angular, ordinate, and leader dimensions; markers show whether definition points are associated."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8CD54B4A-4BA6-40E8-819D-DDBC013114B8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimreassociate/V25/EN_US")

(:name "DIMREGEN"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMREGEN"
 :synopsis "Updates the locations of all associative dimensions."
 :options NIL
 :arguments "Takes no arguments; updates all associative dimensions in the drawing."
 :description "Updates the locations of all associative dimensions in the drawing, needed after wheel-mouse pan/zoom in layouts with model space active or after opening drawings with modified dimensioned external references."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-02EA1694-1141-45E2-8EEA-274701F00D31.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimregen/V25/EN_US")

(:name "DIMSPACE"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMSPACE"
 :synopsis "Adjusts the spacing between parallel linear or angular dimension lines."
 :options ("Auto")
 :arguments "Select the base dimension, select the dimensions to space, then enter a spacing value (0 to align) or Auto."
 :description "Makes the spacing between parallel dimension lines equal, using a base dimension as reference; applies only to parallel linear or angular dimensions sharing a common vertex. A value of 0 aligns the dimension lines, and Auto sets spacing based on the base dimension style's text height."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-18DF8B02-3E43-4531-ACE0-75FA7161F209.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimspace/V25/EN_US")

(:name "DIMSTYLE"
 :category :DIMENSION
 :aliases ("D" "DDIM" "DIMSTY" "DS" "DST" "EXPDIMSTYLES" "SETDIM")
 :intl-name "_DIMSTYLE"
 :synopsis "Creates and modifies dimension styles via a dialog."
 :options ("Overrides" "Standard")
 :arguments "Takes no command-line arguments; opens the Dimension Style Manager (AutoCAD) / Drawing Explorer Dimension Styles (BricsCAD) dialog."
 :description "Opens a dialog to create and modify dimension styles, a named collection of settings controlling the appearance of dimensions such as arrowhead style, text location, and tolerances. In AutoCAD the Dimension Style Manager is displayed; in BricsCAD the Drawing Explorer opens with Dimension Styles selected."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-39D6E54F-E12F-46A4-9DD1-68D9357289E4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimstyle/V25/EN_US")

(:name "DIMTEDIT"
 :category :DIMENSION
 :aliases ("DIMTED")
 :intl-name "_DIMTEDIT"
 :synopsis "Moves and rotates dimension text and relocates the dimension line."
 :options ("Angle" "Left" "Center" "Right" "Home" "REstore")
 :arguments "Select the dimension, then specify a new location for the dimension text or choose an option (Left/Center/Right/Home/Angle)."
 :description "Changes or restores the location, justification, and angle of dimension text and can relocate the dimension line. Left, Right, and Center apply to linear, radius, and diameter dimensions; Home/REstore resets the text to its default rotation."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B70E17BC-E284-4FD3-9F3D-A9F18C022BDE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dimtedit/V25/EN_US")

(:name "DIST"
 :category :INQUIRY
 :aliases ("DI")
 :intl-name "_DIST"
 :synopsis "Measures the distance and angle between two points."
 :options ("Multiple points" "Arc" "Line" "CLose" "Length" "Undo" "Total")
 :arguments "Specify the first point and the second point; or use Multiple points to sum distances across a series of points and arc/line segments."
 :description "Reports the distance and angle between two points, including the angle in the XY plane and the X/Y/Z distance components in current units relative to the current UCS. The Multiple points option accumulates a running total across several points, arcs, and line segments."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A72EADC7-EF79-463C-B4F1-862C6139B004.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dist/V25/EN_US")

(:name "DISTANTLIGHT"
 :category :RENDER
 :aliases NIL
 :intl-name "_DISTANTLIGHT"
 :synopsis "Creates a distant light for renderings."
 :options ("Name" "Intensity factor" "Status" "Photometry" "shadoW"
           "filterColor" "Vector")
 :arguments "Specify the light direction (two points or a vector), then optionally set name, intensity factor, status, photometry, shadow, and filter color options."
 :description "Places a distant light source representing far-off illumination such as the sun, with parallel rays and no glyph in the drawing. Options control the light's name, intensity, on/off status, photometric properties, shadows, and filter color."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CBFE8B69-3744-4BC0-BEA8-915FAD90532D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_distantlight/V25/EN_US")

(:name "DIVIDE"
 :category :DRAW
 :aliases ("DIV")
 :intl-name "_DIVIDE"
 :synopsis "Places equally spaced points or blocks along an entity."
 :options ("Block" "Yes" "No")
 :arguments "Select the object to divide, then enter the number of segments; or choose Block to insert a named block and specify whether to align it to the object."
 :description "Creates evenly spaced point objects, or block insertions, along the length or perimeter of a line, polyline, arc, circle, ellipse, or spline. The number of segments (2 to 32767) determines placement, and blocks can optionally be aligned to the object's curvature or kept at the UCS orientation."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3427CA9F-831C-4B53-A903-49EB6378335C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_divide/V25/EN_US")

(:name "DONUT"
 :category :DRAW
 :aliases ("DO" "DOUGHNUT")
 :intl-name "_DONUT"
 :synopsis "Creates a closed polyline in the shape of a donut (a filled circle or a wide ring)."
 :options ("2 Point" "3 Point" "Tangent Tangent Radius" "Width" "Diameter")
 :arguments "Supplies the inside diameter, the outside diameter, then one or more center points, terminated by an empty string; e.g. (command \"_DONUT\" inside-dia outside-dia center-pt \"\"). An inside diameter of 0 makes a filled circle."
 :description "A donut is made of two arc polylines joined end-to-end into a ring whose width is set by the inside and outside diameters; if the inside diameter is 0 the donut is a filled circle. The command keeps placing uniform donuts at each specified center point until you press Enter. BricsCAD adds 2-Point, 3-Point, and Tangent-Tangent-Radius construction methods."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-46C0F9F2-6112-415C-AB2C-29EEE5984A6F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_donut/V25/EN_US")

(:name "DRAGMODE"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_DRAGMODE"
 :synopsis "Controls the way dragged objects are displayed."
 :options ("ON" "OFF" "Auto")
 :arguments "Enter one of the modes: ON, OFF, or Auto."
 :description "Controls how objects appear while being dragged: ON permits dragging when requested, OFF ignores all drag requests, and Auto displays dragging automatically for commands that support it. BricsCAD notes the command is retained only for compatibility."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-602C614D-2857-4DC3-98DA-3F1D5623988D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dragmode/V25/EN_US")

(:name "DRAWINGRECOVERY"
 :category :FILE
 :aliases NIL
 :intl-name "_DRAWINGRECOVERY"
 :synopsis "Displays a list of drawing files that can be recovered after a failure."
 :options NIL
 :arguments "Takes no arguments; opens the Drawing Recovery Manager panel."
 :description "Opens the Drawing Recovery Manager, which lists drawing files that were open at the time of a program or system failure and can be restored. In BricsCAD it lists DWG, DWT, DWS files and unsaved drawings with autosave (.sv$) files."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A7CA7E0F-70CB-41D2-8E56-4484A27CB3E6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_drawingrecovery/V25/EN_US")

(:name "DRAWINGRECOVERYHIDE"
 :category :FILE
 :aliases NIL
 :intl-name "_DRAWINGRECOVERYHIDE"
 :synopsis "Closes the Drawing Recovery Manager."
 :options NIL
 :arguments "Takes no arguments; closes the Drawing Recovery Manager panel."
 :description "Closes (hides) the Drawing Recovery Manager panel. In BricsCAD, when the panel is stacked, closing it removes the associated tab or icon from that stack."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-707A5EA3-6D36-4CDD-9E43-07B5B188C696.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_drawingrecoveryhide/V25/EN_US")

(:name "DRAWORDER"
 :category :MODIFY
 :aliases ("DR")
 :intl-name "_DRAWORDER"
 :synopsis "Changes the display/draw order of overlapping objects and images."
 :options ("Above" "Under" "Front" "Back" "Clear all orders")
 :arguments "Select objects, then choose Above/Under (with reference objects) or Bring-to-Front/Send-to-Back."
 :description "Manages the display and plotting sequence of overlapping objects so a selected object appears in front of or behind others. It has no visible effect on objects that do not overlap."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3DC76D6E-8F81-4803-8D0A-AA7541D6357E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_draworder/V25/EN_US")

(:name "DSETTINGS"
 :category :SYSTEM
 :aliases ("DDRMODES" "RM")
 :intl-name "_DSETTINGS"
 :synopsis "Opens the Drafting Settings dialog box (grid, snap, tracking, object snap, dynamic input)."
 :options NIL
 :arguments "Opens a dialog box; no command-line arguments are supplied."
 :description "Displays the Drafting Settings / Settings dialog box for viewing and modifying grid and snap, polar and object snap tracking, object snap modes, Dynamic Input, and Quick Properties. In BricsCAD it opens the Settings dialog exposing most system variables."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-22D029BC-354B-4D7D-B800-B5308C377D6C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dsettings/V25/EN_US")

(:name "DVIEW"
 :category :VIEW
 :aliases ("DV")
 :intl-name "_DVIEW"
 :synopsis "Defines parallel projection or perspective views using a camera and target."
 :options ("CAmera" "TArget" "Distance" "POints" "PAn" "Zoom" "TWist" "CLip"
           "Hide" "Off" "Undo")
 :arguments "Select objects (or Enter for DVIEWBLOCK), then enter option keywords with their angle/distance/coordinate inputs."
 :description "Changes the 3D viewpoint interactively and turns on perspective mode by positioning a virtual camera and target. Options rotate the camera or target, set distance, twist, clipping planes, pan, and zoom."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E0078D09-8449-4A0A-A5AD-6984A01CEC33.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dview/V25/EN_US")

(:name "DWGPROPS"
 :category :FILE
 :aliases NIL
 :intl-name "_DWGPROPS"
 :synopsis "Sets and displays the file properties of the current drawing."
 :options NIL
 :arguments "Opens the Drawing Properties dialog box; no command-line arguments are supplied."
 :description "Opens the Drawing Properties dialog box to view and edit general information, summary data, statistics, and custom user-defined properties stored with the drawing file. These properties help identify and organize drawing files."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2A98E78A-9E43-4DE8-8327-BF1BF803B4B7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_dwgprops/V25/EN_US")

(:name "EATTEDIT"
 :category :ATTRIBUTE
 :aliases ("ATE")
 :intl-name "_EATTEDIT"
 :synopsis "Edits attributes contained in a single block reference."
 :options NIL
 :arguments "Prompts to select one block reference containing attributes, then opens the Enhanced/Attribute Editor dialog; no further command-line arguments."
 :description "Modifies the values, text options, and properties (layer, color, linetype, plot style) of each attribute within a single selected block using the Attribute Editor dialog box."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5878AFFC-100D-4D6E-BFA2-A08BF68A11B1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_eattedit/V25/EN_US")

(:name "EDGESURF"
 :category :|3D|
 :aliases NIL
 :intl-name "_EDGESURF"
 :synopsis "Creates a 3D polygon mesh between four contiguous edges or curves."
 :options NIL
 :arguments "Prompts in turn for object 1, object 2, object 3, and object 4 for the surface edges (four connected lines, arcs, open splines, or open polylines); no keyword options."
 :description "Generates an edge-defined polygon mesh surface from four adjoining linear entities that form a closed loop touching at their endpoints. Selection order matters: the first edge sets the M direction and its two adjacent edges form the N edges; mesh density is governed by SURFTAB1 and SURFTAB2."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8AFC0220-D8D8-49B1-8820-4380586364E6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_edgesurf/V25/EN_US")

(:name "EDITTIME"
 :category :OTHER
 :aliases NIL
 :intl-name "_EDITTIME"
 :synopsis "Tracks the amount of active editing time for a drawing."
 :options ("Reset" "Timeout" "On" "Off")
 :arguments "Enter an option keyword (Reset, Timeout, On, or Off) to control the editing timer."
 :description "Monitors how long a drawing has been actively edited, with commands to start, stop, or reset the timer. The timer automatically suspends after a specified period of inactivity (timeout)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7C2311B0-808D-4605-BE73-0A1500EE28D8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_edittime/V25/EN_US")

(:name "ELEV"
 :category :|3D|
 :aliases NIL
 :intl-name "_ELEV"
 :synopsis "Sets the current elevation and extrusion thickness for objects."
 :options ("New current elevation" "New current thickness")
 :arguments "Specify the new default (current) elevation, then the new default (current) thickness."
 :description "Controls the elevation (Z value relative to the current UCS) and extrusion thickness used for objects. In AutoCAD it sets defaults for newly created objects (resetting to 0.0 in the WCS); in BricsCAD it changes the elevation and thickness of the selected objects, so points become lines, lines become planes, and circles become cylinders."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EE3D7937-2CD7-4F0F-BC8F-0AA0DC306EAE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_elev/V25/EN_US")

(:name "ELLIPSE"
 :category :DRAW
 :aliases ("EL")
 :intl-name "_ELLIPSE"
 :synopsis "Creates an ellipse or an elliptical arc."
 :options ("Arc" "Center" "Rotation" "Isocircle" "Parameter" "Included angle")
 :arguments "Specify an axis endpoint (or Arc/Center), the other axis endpoint, then the distance to the other axis or a rotation; for arcs add start and end angle/parameter."
 :description "Creates an ellipse or elliptical arc from axis endpoints and dimensions; the first two points set the location and length of the first axis and the third point defines the half-length of the second axis. The Center, Rotation, and Arc options provide alternate construction methods."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-45F9C588-2BA9-414D-8AFD-FB6B448BF273.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_ellipse/V25/EN_US")

(:name "ERASE"
 :category :MODIFY
 :aliases ("DELETE" "E")
 :intl-name "_ERASE"
 :synopsis "Removes selected objects from the drawing."
 :options ("Last" "Previous" "All")
 :arguments "Supplies a selection set or entity name(s) to delete, or a selection option, terminated by an empty string; e.g. (command \"_ERASE\" ss \"\") or (command \"_ERASE\" ename \"\"). Options such as Last (L), Previous (P), and All are also accepted."
 :description "The ERASE command removes selected objects from the drawing without placing them on the Clipboard, and can also erase subobjects (faces, edges, vertices) of 3D solids. Instead of picking objects you may enter an option such as L (last), P (previous), or ALL. BricsCAD additionally uses it to delete openings and coplanar edges/faces of 3D solids."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-040C580C-63A2-4C98-9964-4573EF8C9514.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_erase/V25/EN_US")

(:name "ETRANSMIT"
 :category :FILE
 :aliases ("-ETRANSMIT")
 :intl-name "_ETRANSMIT"
 :synopsis "Packages a drawing and all its dependent files for transmittal."
 :options ("eTransmit" "Upload to Bricsys 24/7" "New" "Delete")
 :arguments "No command-line arguments; opens the Create Transmittal dialog (BricsCAD: Drawing Explorer with Dependencies); the -ETRANSMIT variant prompts on the command line and writes a ZIP."
 :description "Creates a transmittal package containing the current drawing together with all of its dependent files, such as external references, images, fonts, plot configurations and plot style tables. Selecting drawing files automatically pulls in their related dependent files."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-413A58AD-C86F-432F-A4AC-A2737237001A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_etransmit/V25/EN_US")

(:name "EXOFFSET"
 :category :MODIFY
 :aliases NIL
 :intl-name "_EXOFFSET"
 :synopsis "Offsets selected objects (enhanced Express Tools OFFSET)."
 :options ("Distance" "Through" "Layer" "Gaptype" "Multiple" "Options")
 :arguments "Enter an offset distance (or Through/Options), then select the object to offset and indicate the side or through point; repeat with Multiple, Enter to end."
 :description "An Express Tools enhancement of the standard OFFSET command that creates offset copies of selected entities, adding layer control, undo and a multiple-copy option beyond the standard command."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1D9AD685-C0BC-48D8-A978-3BAAFA2E8138.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_exoffset/V25/EN_US")

(:name "EXPLODE"
 :category :MODIFY
 :aliases ("X")
 :intl-name "_EXPLODE"
 :synopsis "Breaks a compound object into its component objects."
 :options NIL
 :arguments "Select the objects to explode, then press Enter."
 :description "Separates compound entities such as blocks, polylines and regions into their individual component parts so they can be edited separately; properties like color, linetype and lineweight may change and results depend on the object type. Entities on frozen or locked layers, xref-dependent blocks and MINSERT blocks are not affected."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E98BCEF4-DED6-48A6-87EB-10FE87188083.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_explode/V25/EN_US")

(:name "EXPORT"
 :category :FILE
 :aliases ("DWFOUT")
 :intl-name "_EXPORT"
 :synopsis "Saves the objects in a drawing to a different file format."
 :options ("3D DWF" "3D DWFx" "ACIS" "Bitmap" "Block" "DXX Extract"
           "Encapsulated PS" "IGES" "Lithography" "Metafile" "V7 DGN" "V8 DGN")
 :arguments "No command-line arguments; opens the Export Data dialog (BricsCAD: Export Drawing As dialog) where a filename and format are chosen."
 :description "Opens a file-selection dialog to save drawing data to a variety of formats; available formats depend on the product and license level (AutoCAD lists DWF/DWFx, ACIS, Bitmap, DGN, IGES, etc.; BricsCAD adds FBX, STL, DWG, PDF, IFC and others). The dialog remembers the last used format."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A72DB257-3410-4792-B548-6B9FC1DED72B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_export/V25/EN_US")

(:name "EXPORTPDF"
 :category :FILE
 :aliases NIL
 :intl-name "_EXPORTPDF"
 :synopsis "Generates a PDF file from the current drawing."
 :options NIL
 :arguments "No command-line arguments; opens the Save As PDF dialog (BricsCAD: Export Drawing As dialog)."
 :description "Exports the current drawing to a PDF file. In AutoCAD it can export a single layout, all layouts, or a specified area of model space and lets you override page-setup, plot-stamp and file options; in BricsCAD it launches the export dialog (academic licenses add a watermark)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E9CB4A20-A2AF-4395-A070-610A84853D48.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_exportpdf/V25/EN_US")

(:name "EXPRESSTOOLS"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_EXPRESSTOOLS"
 :synopsis "Activates and loads the Express Tools."
 :options NIL
 :arguments "No arguments; loads/activates the Express Tools."
 :description "Loads the Express Tools libraries, adds the Express folder to the search path and places the Express menu on the menu bar. Once invoked, the libraries load automatically at startup, increasing launch time but reducing first-use delay."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-87BF0045-6446-48C6-8413-DE025596396E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_expresstools/V25/EN_US")

(:name "EXTEND"
 :category :MODIFY
 :aliases ("EX")
 :intl-name "_EXTEND"
 :synopsis "Extends objects to meet the edges of other objects."
 :options ("Boundary edges" "Fence" "Crossing" "Edge" "Project" "Mode" "eRase"
           "Undo")
 :arguments "In Standard mode select boundary edges then Enter, then pick the objects to extend near the end to lengthen; in Quick mode pick objects directly; Enter to end (Shift-select to trim instead)."
 :description "Lengthens open objects so they reach boundary edges defined by other objects. It offers Quick mode (all objects act as boundaries) and Standard mode (boundaries are selected first), controlled by the TRIMEXTENDMODE/mode option, and can trim instead of extend via Shift-select."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-89DD7B0F-F4F1-410D-9A3A-5847CA5F8744.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_extend/V25/EN_US")

(:name "EXTRIM"
 :category :MODIFY
 :aliases NIL
 :intl-name "_EXTRIM"
 :synopsis "Trims all objects on one side of a selected cutting edge in one operation."
 :options NIL
 :arguments "Select one cutting-edge object (polyline, line, circle, arc, ellipse, text, mtext or attribute definition), then pick a point on the side to trim."
 :description "An Express Tools command (cookie-cutter trim) that trims every object crossing a selected cutting edge; after choosing the cutting-edge object and clicking the side to remove, all intersecting objects are trimmed to that edge in a single operation."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-06651AD3-F159-430E-81E5-AEB8E775C19E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_extrim/V25/EN_US")

(:name "EXTRUDE"
 :category :|3D|
 :aliases ("EXT")
 :intl-name "_EXTRUDE"
 :synopsis "Creates 3D solids or surfaces by extruding objects."
 :options ("Mode" "Direction" "Path" "Taper angle" "Both sides" "set Limit")
 :arguments "Select the objects (profiles) to extrude and press Enter, then specify the height of extrusion or choose Direction/Path/Taper angle/Mode (solid or surface)."
 :description "Creates a 3D solid from an object that encloses an area, or a 3D surface from an open object, by extruding open or closed 2D entities, faces, regions or boundaries. Extrusion can be orthogonal, in a specified direction, or along a path, with an optional taper angle; source-object deletion is governed by DELOBJ."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-85FD1106-8F10-4EE8-B0FB-99F1E3AEE405.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_extrude/V25/EN_US")

(:name "FIELD"
 :category :TEXT
 :aliases NIL
 :intl-name "_FIELD"
 :synopsis "Inserts a text field that updates automatically as its value changes."
 :options ("Date & Time" "Document" "Linked" "Objects" "Plot" "Variables"
           "Sheet Set" "Extensions" "Field expression")
 :arguments "No command-line arguments; opens the Field dialog box to pick a field category and property, then place the resulting text (specify start point, height and justification)."
 :description "Creates a multiline text object containing a field whose value updates automatically (governed by FIELDEVAL and UPDATEFIELD). Fields can display drawing/document properties, object properties, dates, plot settings, sheet-set data and more, and can be inserted in most kinds of text."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-742C92C3-1284-4722-B650-C46F9191C701.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_field/V25/EN_US")

(:name "FILL"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_FILL"
 :synopsis "Controls the display of filled objects such as hatches, 2D solids, and wide polylines (toggles FILLMODE)."
 :options ("On" "Off")
 :arguments "Supplies the ON or OFF keyword; requires a REGEN to update the display."
 :description "Toggles whether filled 2D entities (polylines, hatches, 2D solids, and traces) are displayed and plotted filled or as outlines only. It sets the FILLMODE system variable, and changes take effect after a drawing regeneration."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A09941AF-919C-4E72-96F4-3DF3C11922DE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_fill/V25/EN_US")

(:name "FILLET"
 :category :MODIFY
 :aliases ("F")
 :intl-name "_FILLET"
 :synopsis "Rounds or fillets the edges of two 2D objects or the adjacent faces of a 3D solid with an arc of a specified radius."
 :options ("Polyline" "Radius" "Trim" "Undo" "Multiple" "Settings" "Chain"
           "Loop" "Expression")
 :arguments "Supplies the first object (or an option keyword), then the second object; a zero radius trims/extends to a corner, and Shift on the second pick forces radius 0."
 :description "Joins two intersecting objects (lines, arcs, polyline vertices, rays, or xlines) with a tangent arc of a suitable radius, extending or trimming them at the intersection. On 3D solids it rounds adjacent faces, and the Polyline option fillets every vertex of a 2D polyline."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-64F8B700-23B3-4BD6-8C03-66121AA13E8F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_fillet/V25/EN_US")

(:name "FIND"
 :category :TEXT
 :aliases NIL
 :intl-name "_FIND"
 :synopsis "Finds the text that you specify, and can optionally replace it with other text."
 :options NIL
 :arguments "Opens the Find and Replace dialog box; no command-line arguments are supplied."
 :description "Opens the Find and Replace dialog box to locate and optionally replace text strings within the drawing, searching through text, block attributes, dimensions, tables, and hyperlinks. The search scope can be the entire drawing, the current layout, or the current selection."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6E9F237C-C93D-4E68-BCBA-31E78B2349A0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_find/V25/EN_US")

(:name "FLATSHOT"
 :category :|3D|
 :aliases NIL
 :intl-name "_FLATSHOT"
 :synopsis "Creates a 2D flattened, hidden-line representation of all 3D objects based on the current view."
 :options ("Insert new block" "Replace existing block" "Export to file"
           "Visible lines" "Hidden lines")
 :arguments "Opens the Flatshot dialog box where destination and visible/hidden line properties are configured before creating; no command-line arguments are supplied."
 :description "Projects the edges of 3D solids, surfaces, and meshes line-of-sight onto a plane parallel to the viewing plane and inserts the resulting 2D representation as a block on the XY plane of the UCS. A dialog box lets you choose the destination (new block, replace existing block, or export to file) and configure visible and hidden line properties."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-746F10D2-7CFD-412D-B51F-33574C773B95.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_flatshot/V25/EN_US")

(:name "FLATTEN"
 :category :MODIFY
 :aliases NIL
 :intl-name "_FLATTEN"
 :synopsis "Converts 2D and 3D geometry to a projected 2D representation on the current viewing plane."
 :options ("new ucs ELevation" "allow EXplode")
 :arguments "Supplies the selection set of objects to flatten, then answers whether to remove hidden lines."
 :description "An Express Tool that projects selected 2D and 3D objects onto the XY-plane of the current view, producing 2D objects that retain their original layers, linetypes, colors, and object types where possible. It can generate a 2D drawing from a 3D model or force object thickness and elevation to zero (PERSPECTIVE must be 0)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-84039380-7A83-4969-9465-73C6C8784C1E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_flatten/V25/EN_US")

(:name "FS"
 :category :SELECTION
 :aliases ("FASTSEL")
 :intl-name "_FS"
 :synopsis "Creates a selection set of all objects that touch the selected object (Fast Select)."
 :options NIL
 :arguments "Supplies the single object to select from; the touching objects returned depend on the FSMODE setting."
 :description "An Express Tool that selects lines, polylines, circles, arcs, attribute definitions, text, mtext, ellipses, and images touching the chosen object. When FSMODE is off (default) only directly touching objects are selected; when on, selection follows the chain of connected objects, and FS can be used transparently ('FS) at a Select Objects prompt."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A4FBF4EC-DE23-46A2-A576-AEED0E9847D4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_fs/V25/EN_US")

(:name "GATTE"
 :category :ATTRIBUTE
 :aliases NIL
 :intl-name "_GATTE"
 :synopsis "Globally changes attribute values for all instances of a specified block."
 :options ("Yes" "No")
 :arguments "Supplies a block (by selection or name) and an attribute (by selection or tag name), then the new text value; Yes/No controls whether all instances change automatically."
 :description "An Express Tool that updates an attribute value across every instance of a chosen block. You identify the block and the attribute tag, enter a new value, and the command replaces all matching attributes and reports how many blocks were changed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EABA451D-1351-416A-88CE-2E5C12C14B44.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gatte/V25/EN_US")

(:name "GCCOINCIDENT"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCCOINCIDENT"
 :synopsis "Constrains two points together or a point to a curve (or an extension of a curve)."
 :options ("Point" "First point" "Second point" "Object" "Multiple"
           "Autoconstrain")
 :arguments "Supplies a first point on an entity then a second point/entity to make coincident; the Object option takes an entity then a point, and Multiple repeats until Enter."
 :description "Applies a coincident geometric constraint to 2D entities so a point on one entity stays coincident with a point on another entity, or with a curve or its extension. It works with lines, polylines, circles, arcs, ellipses, and splines, and offers Object, Multiple, and Autoconstrain methods."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0309B988-6BDF-4AF5-8386-E04D68DC30D8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gccoincident/V25/EN_US")

(:name "GCCONCENTRIC"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCCONCENTRIC"
 :synopsis "Creates a concentric geometric constraint that constrains two arcs, circles, or ellipses to the same center point."
 :options NIL
 :arguments "Select first object (circle, arc, or ellipse), then select second object to make concentric with it."
 :description "Applies a concentric constraint so two circular or elliptical entities share the same center point; the first entity stays fixed while the second moves to comply. Valid objects are circles, arcs, polyline arcs, and ellipses."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4591668B-A351-4652-AEF4-6DCF956FAE79.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gcconcentric/V25/EN_US")

(:name "GCEQUAL"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCEQUAL"
 :synopsis "Creates an equal geometric constraint that resizes arcs and circles to the same radius, or lines to the same length."
 :options ("Object" "First object" "Second object" "Multiple")
 :arguments "Select first object (arc, circle, line, or polyline segment), then select second object to make equal; or use Multiple to make several successive objects equal to the first."
 :description "Applies an equal constraint so circular entities share equal radii or linear entities share equal lengths. The first entity keeps its size while subsequent selections update to match; a Multiple option constrains several objects at once."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EC45334F-107B-4169-882A-447F43762005.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gcequal/V25/EN_US")

(:name "GCFIX"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCFIX"
 :synopsis "Creates a fixed geometric constraint that locks points and curves in position."
 :options ("Specify point" "Object")
 :arguments "Specify a point to lock in place, or use the Object option to select an entity to lock."
 :description "Applies a fixed constraint that locks a point or an entire object in position. When a point is fixed, the object may still move about that locked node; when an object is fixed, it becomes immovable. Valid objects include lines, polyline segments, circles, arcs, polyline arcs, ellipses, and splines."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-99AB929E-9E93-4723-B108-FAE839FA0331.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gcfix/V25/EN_US")

(:name "GCHORIZONTAL"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCHORIZONTAL"
 :synopsis "Creates a horizontal geometric constraint causing lines or pairs of points to lie parallel to the X axis."
 :options ("2Points")
 :arguments "Select a linear entity to constrain horizontal; or use 2Points to select a first point then a second point that is made horizontal to the first."
 :description "Applies a horizontal constraint so a linear entity or a pair of points remains parallel to the X axis of the current coordinate system. A 2Points option constrains two selected constraint points instead of an object. Valid objects include lines, polyline segments, ellipses, and multiline text."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CC9A57ED-E3C6-42C3-BED2-BEDC2E17E6F0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gchorizontal/V25/EN_US")

(:name "GCPARALLEL"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCPARALLEL"
 :synopsis "Creates a parallel geometric constraint causing selected lines to lie parallel to each other."
 :options NIL
 :arguments "Select first linear entity, then select second linear entity to make parallel to the first."
 :description "Applies a parallel constraint so linear entities maintain parallel alignment. The first entity stays fixed while the second moves as needed. Valid objects include lines, polyline segments, ellipses, and multiline text."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9C3E2565-FCE9-49D9-BD81-F473DA7932B3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gcparallel/V25/EN_US")

(:name "GCPERPENDICULAR"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCPERPENDICULAR"
 :synopsis "Creates a perpendicular geometric constraint causing selected lines to lie 90 degrees to one another."
 :options NIL
 :arguments "Select first linear entity, then select second linear entity to make perpendicular to the first."
 :description "Applies a perpendicular constraint that keeps linear entities at right angles to one another; the lines need not intersect. The first entity stays fixed while the second adjusts to become perpendicular. Valid objects include lines, polyline segments, ellipses, and multiline text."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2EA9ED8A-D8EF-4607-9625-8CF064D8C486.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gcperpendicular/V25/EN_US")

(:name "GCSMOOTH"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCSMOOTH"
 :synopsis "Creates a smooth geometric constraint that constrains a spline to be contiguous and maintain G2 continuity with another curve."
 :options NIL
 :arguments "Select first spline curve, then select second curve to make continuous with the first spline."
 :description "Applies a smooth constraint so a spline maintains fluid G2 continuity with another spline, line, arc, or polyline. The first spline holds its position while the second stretches to smoothly connect, with the curve endpoints made coincident."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-090F12A3-D325-43A0-BDB3-078947849C6E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gcsmooth/V25/EN_US")

(:name "GCSYMMETRIC"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCSYMMETRIC"
 :synopsis "Creates a symmetric geometric constraint causing selected objects to become symmetric about a selected line."
 :options ("Object" "2Points")
 :arguments "Select first entity, select second entity, then select the symmetry (mirror) line; or use 2Points to select two constraint points then the symmetry line."
 :description "Applies a symmetric constraint so two entities remain symmetric about a selected mirror line; the first entity holds its position while the second becomes symmetric. For lines the angle is made symmetric, and for arcs and circles the center and radius are made symmetric. A 2Points option constrains two points instead of objects."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8ACB8055-9288-4063-9F54-8745CD8DF7A2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gcsymmetric/V25/EN_US")

(:name "GCTANGENT"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCTANGENT"
 :synopsis "Creates a tangent geometric constraint that constrains two curves to maintain a point of tangency to each other or their extensions."
 :options NIL
 :arguments "Select first entity (linear or curved), then select second entity to make tangent to the first; at least one curved entity must be selected."
 :description "Applies a tangent constraint so curved entities remain tangent to another curved or linear entity, even where they do not physically touch. The first entity holds its position while the second moves to become tangent. Valid objects include lines, polyline segments, circles, arcs, polyline arcs, and ellipses."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5B067A03-9DF0-4143-8444-F62BA90DE5F3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gctangent/V25/EN_US")

(:name "GCVERTICAL"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCVERTICAL"
 :synopsis "Causes lines or pairs of points to lie parallel to the Y axis of the current coordinate system."
 :options ("Select an object" "2Points")
 :arguments "Select a linear object to constrain vertical, or enter 2Points then specify the first (fixed) point and the second point to align vertically."
 :description "Creates a vertical geometric constraint so that linear objects or pairs of constraint points remain parallel to the Y axis. It is equivalent to the Vertical option of GEOMCONSTRAINT and works with lines, polyline segments, ellipses, mtext, and constraint points."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C0A6EF16-473C-4C63-9A3B-C312520EACF2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gcvertical/V25/EN_US")

(:name "GEOGRAPHICLOCATION"
 :category :SYSTEM
 :aliases ("GEO")
 :intl-name "_GEOGRAPHICLOCATION"
 :synopsis "Assigns geographic location information to a drawing file."
 :options ("Map" "Bing" "File")
 :arguments "Opens the Geographic Location dialog (or search via Map/Bing/File data), then specify latitude and longitude, select the corresponding model space point, and specify the north direction angle."
 :description "Assigns geographic location data to a drawing by specifying the latitude and longitude of a known location and marking the corresponding point in model space. Supports GIS coordinate systems and can override the default coordinate system."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-10A3B776-A0FA-4438-B29B-EA22C070A27E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_geographiclocation/V25/EN_US")

(:name "GEOMAP"
 :category :VIEW
 :aliases NIL
 :intl-name "_GEOMAP"
 :synopsis "Displays a map from an online maps service in the current viewport."
 :options ("Esri OpenStreetMap" "Esri Imagery" "Esri Streets" "Esri Light Gray"
           "Esri Dark Gray" "Bing Aerial" "Bing Road" "Bing Hybrid" "Map Off")
 :arguments "Specify a map style keyword (for example Esri Imagery or Bing Road) or Off to set the visibility and type of the online map shown in the current viewport."
 :description "Displays maps from an online map service within the current viewport, requiring internet access and Autodesk account authentication. Offers multiple map styles from Esri and Bing (streets, imagery, hybrid) plus an option to turn the map off; in BricsCAD a geographic location and map API key must first be set."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DEF7EA7B-6A4B-4520-9A6F-08A944F78218.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_geomap/V25/EN_US")

(:name "GEOMAPIMAGE"
 :category :DRAW
 :aliases NIL
 :intl-name "_GEOMAPIMAGE"
 :synopsis "Captures a portion of the online map to a map image object and embeds it in the drawing area."
 :options ("Viewport" "First corner")
 :arguments "Enter Viewport to capture the current viewport, or specify the first corner and opposite corner of a rectangular area to capture the online map as an embedded image."
 :description "Creates a cached rectangular image capture of the online map and embeds it in the drawing so it can be displayed and plotted offline. Requires a plan (top) view; a geographic location and map style must be set first."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-092F0E5E-BBA9-4A4E-ACF0-4779808C4384.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_geomapimage/V25/EN_US")

(:name "GEOMAPIMAGEUPDATE"
 :category :MODIFY
 :aliases NIL
 :intl-name "_GEOMAPIMAGEUPDATE"
 :synopsis "Updates map images from the online maps service and optionally resets their resolution."
 :options ("Optimize" "Reload")
 :arguments "Select the map image(s) to update; optionally optimize (reset resolution for on-screen viewing) or reload the map image."
 :description "Refreshes previously captured map imagery from the online maps service, requiring an active Autodesk account login. It can optimize the map image resolution to prevent pixelation when zoomed to the image extents."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-79DFA423-8546-4DD4-9A23-1C0F0B9DF607.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_geomapimageupdate/V25/EN_US")

(:name "GEOMCONSTRAINT"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GEOMCONSTRAINT"
 :synopsis "Applies or persists geometric relationships between objects or points on objects."
 :options ("Horizontal" "Vertical" "Perpendicular" "Parallel" "Tangent"
           "Smooth" "Coincident" "Concentric" "Collinear" "Symmetric" "Equal"
           "Fix")
 :arguments "Specify a constraint type keyword (Horizontal, Vertical, Perpendicular, Parallel, Tangent, Smooth, Coincident, Concentric, Collinear, Symmetric, Equal, or Fix), then select the object(s) or valid constraint points to constrain."
 :description "Applies geometric constraints that maintain relationships between 2D objects or fixed locations and angles. Works with lines, arcs, circles, polylines, splines, and inserted objects; results depend on selection order and the constraint points chosen."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D79452FB-DDA7-44C0-A9EA-F4EA656022D2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_geomconstraint/V25/EN_US")

(:name "GETSEL"
 :category :SELECTION
 :aliases NIL
 :intl-name "_GETSEL"
 :synopsis "Creates a selection set of objects based on layer and object type filters."
 :options NIL
 :arguments "Select an object on the source layer (or enter a layer name, or press Enter for all layers), then select an object of the type you want (or press Enter for all types); the result is retrievable with the Previous selection option."
 :description "Builds a selection set by specifying a source layer and an object type, collecting all matching objects into the current selection set. The collected set can be reselected in a later command using the P (previous) selection option; in both products this is an Express Tool."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C5227693-40C1-4AB8-A84A-BD53AA6B7963.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_getsel/V25/EN_US")

(:name "GOTOSTART"
 :category :VIEW
 :aliases NIL
 :intl-name "_GOTOSTART"
 :synopsis "Switches from the current drawing to the Start tab/page."
 :options NIL
 :arguments "No arguments; switches focus to the Start tab (Ctrl+Home is the equivalent shortcut)."
 :description "Navigates from the current drawing to the Start tab, which serves as a hub for creating new drawings from templates, opening recent files, and accessing tutorials, samples, and other resources."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E70589F5-35DE-4688-9CE0-EDEA94525740.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gotostart/V25/EN_US")

(:name "GRADIENT"
 :category :DRAW
 :aliases NIL
 :intl-name "_GRADIENT"
 :synopsis "Fills an enclosed area or selected objects with a gradient fill."
 :options NIL
 :arguments "Opens the Hatch and Gradient dialog (or the Hatch Creation ribbon tab); pick internal points of enclosed areas or select boundary objects, then choose gradient colors and orientation to apply the fill."
 :description "Creates a gradient fill that smoothly transitions between one or two colors within closed 2D areas. When the ribbon is active the Hatch Creation contextual tab is shown; otherwise the Hatch and Gradient dialog box appears."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1AE69094-DFEF-4361-9B1D-E3F5448CCB02.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_gradient/V25/EN_US")

(:name "GRAPHSCR"
 :category :VIEW
 :aliases NIL
 :intl-name "_GRAPHSCR"
 :synopsis "Switches from the text window to the graphics (drawing) window."
 :options NIL
 :arguments "No arguments; switches to the graphics screen, causing the text/Prompt History window to display behind the application window."
 :description "Switches the display from the text window (Prompt History) to the drawing window. When the command line is docked, F2 provides an alternative way to toggle window display order; TEXTSCR performs the inverse."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-01D6B038-6372-42D5-BC80-7EB26393E349.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_graphscr/V25/EN_US")

(:name "GRID"
 :category :VIEW
 :aliases ("G")
 :intl-name "_GRID"
 :synopsis "Toggles the display of the grid and sets some of its properties."
 :options ("ON" "OFF" "Snap" "Aspect" "Major" "Adaptive" "Limits" "Follow")
 :arguments "Supplies either a grid spacing value or one of the option keywords (ON, OFF, Snap, Aspect, Major, Adaptive, Limits, Follow)."
 :description "Controls grid visibility and spacing in the drawing area; the grid is a rectangular pattern used as a visual aid for alignment and distance estimation. It can be toggled on or off and configured for spacing, snap alignment, aspect ratio, major line frequency, and adaptive behavior."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7EC38AD6-FA34-4115-9E1C-6F13E1BA033D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_grid/V25/EN_US")

(:name "GROUP"
 :category :SELECTION
 :aliases NIL
 :intl-name "_GROUP"
 :synopsis "Opens the Entity grouping dialog box."
 :options ("Select objects" "Name" "Description")
 :arguments "Opens a dialog box; the GROUP command takes no command-line arguments (use -GROUP for the command-line version that prompts to select objects and assign a name and description)."
 :description "Creates and manages named sets of objects called groups; selecting any member of a group selects all its objects, allowing them to be moved, copied, rotated, or edited as a unit. The command opens a dialog box for viewing, creating, modifying, and deleting groups."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-23E1D601-0814-46A4-BC1D-02162957BF7B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_group/V25/EN_US")

(:name "HATCH"
 :category :DRAW
 :aliases ("BH" "H")
 :intl-name "_HATCH"
 :synopsis "Fills an enclosed area or selected objects with a hatch pattern, solid fill, or gradient fill."
 :options ("Pick internal point" "Select objects" "Remove boundaries"
           "Add boundaries" "Draw" "Undo" "Settings")
 :arguments "Specifies internal pick points inside closed areas (or uses the Select objects option) to define hatch boundaries, then ends selection."
 :description "Fills an enclosed area or selected objects with a hatch pattern, solid fill, or gradient fill. Boundaries can be defined by picking internal points within enclosed areas or by selecting objects, and pattern, scale, angle, origin, island detection, and other properties can be set."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-27C104F2-B687-4025-B50B-A58E37329832.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_hatch/V25/EN_US")

(:name "HATCHEDIT"
 :category :MODIFY
 :aliases ("HE")
 :intl-name "_HATCHEDIT"
 :synopsis "Edits hatches through a dialog box."
 :options NIL
 :arguments "Selects an existing hatch or gradient-fill object; the Hatch Edit dialog box then opens for modification."
 :description "Modifies an existing hatch or gradient fill. Selecting a hatch opens the Hatch Edit dialog box, whose options match those of the Hatch and Gradient dialog, letting you change pattern, scale, angle, origin, boundaries, and other properties."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2424838A-4B9D-4577-84E7-AE7949DA31AF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_hatchedit/V25/EN_US")

(:name "HATCHGENERATEBOUNDARY"
 :category :DRAW
 :aliases NIL
 :intl-name "_HATCHGENERATEBOUNDARY"
 :synopsis "Creates a non-associated polyline around a selected hatch."
 :options NIL
 :arguments "Selects one or more hatch objects; a polyline boundary is generated around them."
 :description "Creates a non-associative polyline boundary around one or more selected hatch or gradient-fill objects."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B441A558-F685-4CE8-950A-C368678B60E1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_hatchgenerateboundary/V25/EN_US")

(:name "HATCHTOBACK"
 :category :MODIFY
 :aliases NIL
 :intl-name "_HATCHTOBACK"
 :synopsis "Sets the draw order for all hatches in the drawing to be behind all other objects."
 :options NIL
 :arguments "No arguments; automatically selects all hatches and moves them behind all other overlapping objects."
 :description "Sets the draw order of all hatches in the drawing so they display behind all other overlapping objects; it automatically selects every hatch, including patterns, solid fills, and gradient fills."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F4A78D17-6BE6-4906-990C-4446268F4570.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_hatchtoback/V25/EN_US")

(:name "HELIX"
 :category :DRAW
 :aliases NIL
 :intl-name "_HELIX"
 :synopsis "Creates a 2D spiral or a 3D helix."
 :options ("Diameter" "Axis endpoint" "Turns" "Turn Height" "Twist")
 :arguments "Center point of base, base radius (or Diameter), top radius (or Diameter), helix height (or Axis endpoint), optionally Turns / Turn height / Twist direction (CW or CCW)."
 :description "Creates a 2D spiral or a 3D helix that can be used as a sweep path for springs, threads, and circular stairways. The shape is defined by a base point and radius, a top radius, a height (or axis endpoint), a number of turns, turn height, and twist direction."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C6FE985E-8978-4D11-8490-D81CFB323CDD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_helix/V25/EN_US")

(:name "HELP"
 :category :OTHER
 :aliases ("?")
 :intl-name "_HELP"
 :synopsis "Displays the online or offline Help system."
 :options NIL
 :arguments "No arguments; opens the Help system (press F1 for context help while a command is active or a tooltip is shown)."
 :description "Opens the Help system, displaying information about commands, system variables, and workflows. Pressing F1 while hovering over a tooltip or while a command is active shows help for that item."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-60C67B97-FC11-4FCD-BE40-A16E82D55076.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_help/V25/EN_US")

(:name "HIDE"
 :category :|3D|
 :aliases ("HI")
 :intl-name "_HIDE"
 :synopsis "Displays a 3D model with hidden lines suppressed for the 2D Wireframe visual style."
 :options NIL
 :arguments "No arguments; regenerates the 3D model with lines hidden behind surfaces and opaque objects suppressed."
 :description "Regenerates a 3D model with hidden lines suppressed, removing the display of lines that fall behind solids, surfaces, and other opaque objects. The effect is reversed by REGEN, ZOOM, or switching the visual style."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7C44F850-51AC-498B-B7A5-DDD361F415CC.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_hide/V25/EN_US")

(:name "HIDEOBJECTS"
 :category :VIEW
 :aliases NIL
 :intl-name "_HIDEOBJECTS"
 :synopsis "Temporarily suppresses the display of selected objects."
 :options NIL
 :arguments "Select objects prompt; select the entities to hide (restore with UNISOLATEOBJECTS)."
 :description "Temporarily suppresses the display of selected objects while keeping other objects visible; use UNISOLATEOBJECTS to restore them. Whether the hidden state persists between sessions depends on the OBJECTISOLATIONMODE system variable."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-48199A62-90B6-48C6-93E1-5ECF56EAF8B5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_hideobjects/V25/EN_US")

(:name "HYPERLINK"
 :category :EDIT
 :aliases NIL
 :intl-name "_HYPERLINK"
 :synopsis "Attaches a hyperlink to an object or modifies an existing hyperlink."
 :options NIL
 :arguments "Prompts to select objects, then opens the Insert Hyperlink or Edit Hyperlink dialog box; the dialog form takes no further command-line arguments (use -HYPERLINK to define an area associated with a hyperlink)."
 :description "Associates files or web pages with drawing entities. Selecting objects opens the Insert or Edit Hyperlink dialog depending on whether the object already has a hyperlink, letting you point to a file or URL with options for relative paths and bookmarks."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-68C8EEED-2FA2-4100-AE03-F8B1C40431E1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_hyperlink/V25/EN_US")

(:name "HYPERLINKOPTIONS"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_HYPERLINKOPTIONS"
 :synopsis "Controls the display of the hyperlink cursor, tooltips, and shortcut menu."
 :options ("Yes" "No")
 :arguments "Supplies a Yes or No value to enable or disable display of the hyperlink cursor, URL tooltip, and Hyperlink shortcut-menu option."
 :description "Toggles visibility of the hyperlink cursor, the URL tooltip, and the Hyperlink option in shortcut menus. The tooltip text is the hyperlink description defined in the HYPERLINK command."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-657896C5-DD7C-4B42-A595-8B8209EA1F16.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_hyperlinkoptions/V25/EN_US")

(:name "ID"
 :category :INQUIRY
 :aliases ("IDPOINT")
 :intl-name "_ID"
 :synopsis "Reports the X, Y, Z coordinate values of a specified location."
 :options NIL
 :arguments "Supplies one point; the command reports its X, Y, and Z coordinates in the current UCS and stores the point for reference with the @ symbol."
 :description "Displays the X, Y, and Z coordinates of a point you specify, using the current coordinate system, and stores the point for later reference with the @ symbol at subsequent point prompts."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F258AC00-5E9F-4B6B-A670-33F7708E3FB6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_id/V25/EN_US")

(:name "IMAGE"
 :category :OTHER
 :aliases ("IM")
 :intl-name "_IMAGE"
 :synopsis "Opens the palette for managing attached raster images."
 :options NIL
 :arguments "No arguments; opens the Attachments panel (BricsCAD) / External References palette (AutoCAD). Use -IMAGE for command-line options."
 :description "Displays the panel/palette used to manage raster images attached to the drawing, where images can be loaded, unloaded, and their file information reviewed. Like other dockable panels it can be floating, docked, or stacked."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-97CD5FCC-7ED8-4AA7-93F2-8C60791ED5C6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_image/V25/EN_US")

(:name "IMAGEADJUST"
 :category :MODIFY
 :aliases ("IAD")
 :intl-name "_IMAGEADJUST"
 :synopsis "Controls the brightness, contrast, and fade values of images."
 :options NIL
 :arguments "Selects one or more image entities (by their frames), then adjusts brightness, contrast, and fade values on a 0-100 scale."
 :description "Adjusts the display properties of attached raster images after selecting them. Three properties can be changed on a 0-100 scale: brightness, contrast, and fade; settings can be confirmed through the Properties palette."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FA5F80B3-1581-40DF-BFEA-E6383A9266CE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_imageadjust/V25/EN_US")

(:name "IMAGEAPP"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_IMAGEAPP"
 :synopsis "Specifies the image editor application used by the IMAGEEDIT command."
 :options NIL
 :arguments "Supplies the raster image editor application filename (or a period \".\" for the system default)."
 :description "Designates which external image-editing program (such as Microsoft Paint) is launched by the IMAGEEDIT command. In AutoCAD it is documented as an Express Tool."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-025B47FE-3A59-4BA4-8853-F9D34B80AE36.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_imageapp/V25/EN_US")

(:name "IMAGEATTACH"
 :category :OTHER
 :aliases ("IAT")
 :intl-name "_IMAGEATTACH"
 :synopsis "Attaches a reference to a raster image file."
 :options NIL
 :arguments "Selects an image file, then specifies the insertion point, scale, and rotation via the Attach Image dialog box."
 :description "Inserts a referenced raster image into the drawing. A file-selection dialog chooses the image, then an attachment dialog sets its insertion point, scale, and rotation; changes to the referenced file appear when the drawing is opened or reloaded."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0F75E36F-6138-424C-9510-5847CE1D8852.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_imageattach/V25/EN_US")

(:name "IMAGECLIP"
 :category :MODIFY
 :aliases ("ICL")
 :intl-name "_IMAGECLIP"
 :synopsis "Crops the display of a selected image to a specified clipping boundary."
 :options ("ON" "OFF" "Delete" "New boundary" "Select polyline" "Polygonal"
           "Rectangular" "Invert")
 :arguments "Selects an image, then chooses ON/OFF/Delete or New boundary; for a new boundary selects a polyline or draws a Polygonal or Rectangular boundary (Invert reverses the clipped side)."
 :description "Defines a clipping boundary for a raster image so areas outside the boundary are hidden. The boundary must lie in a plane parallel to the image, and its visibility is controlled by the IMAGEFRAME system variable."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9D652E1A-29F8-49BC-ABCC-37B9F1C7A1D0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_imageclip/V25/EN_US")

(:name "IMAGEEDIT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_IMAGEEDIT"
 :synopsis "Edits the selected image in the external editor specified by IMAGEAPP."
 :options NIL
 :arguments "Selects an image to open in the external image-editing application configured by the IMAGEAPP command."
 :description "Opens a selected raster image in an external editor (such as Microsoft Paint). The editor must first be configured with the IMAGEAPP command. In AutoCAD it is documented as an Express Tool."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D57BD5D4-FA6E-483E-BB72-6747964CC5B5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_imageedit/V25/EN_US")

(:name "IMAGEQUALITY"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_IMAGEQUALITY"
 :synopsis "Controls the display quality of attached images."
 :options ("High" "Draft")
 :arguments "Supplies the display-quality keyword: High or Draft."
 :description "Sets how attached images are displayed to balance performance against resolution. Draft mode reduces color resolution and memory use for better performance, while High mode maximizes image quality; images are always plotted at high quality."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-19368CF1-3845-4E62-B408-B5036853C261.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_imagequality/V25/EN_US")

(:name "IMPORT"
 :category :FILE
 :aliases ("IMP")
 :intl-name "_IMPORT"
 :synopsis "Imports the geometry from external files into the current drawing."
 :options NIL
 :arguments NIL
 :description "Opens the Import file dialog box to select supported external file types (DXF, DWG, WMF, EMF, DAE, DGN, OBJ, plus edition-dependent SKP, 3DM, IFC, RFA, RVT) and imports their geometry into the current drawing; in AutoCAD it displays the Import File dialog box, translating data files from other applications into DWG format."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-81A5EE76-39A7-40A4-A5C5-E4921C03B33A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_import/V25/EN_US")

(:name "INSERT"
 :category :BLOCK
 :aliases ("I" "DDINSERT")
 :intl-name "_INSERT"
 :synopsis "Inserts a block instance from a block definition into the current drawing."
 :options ("Name" "Scale" "Rotate" "Base point" "Multiple" "Flip" "Array"
           "SMART insert" "Edit inserted entity")
 :arguments "Supplies the block name (or external drawing file), then the insertion point, then X/Y/Z scale factors, then the rotation angle; e.g. (command \"_INSERT\" name pt xscale yscale rotation). BricsCAD adds keyword options (Scale, Rotate, Base point, Multiple, Flip, Array, SMART insert, etc.). In AutoCAD the bare INSERT command displays the Blocks palette; -INSERT gives the classic command-line prompt sequence."
 :description "Inserts an instance of a block definition (from the current drawing or an external file) into the drawing. BricsCAD opens the Insert Block dialog box and supports insertion modes and advanced settings. In AutoCAD 2026, INSERT displays the Blocks palette (gallery of current/recent/library blocks); -INSERT provides the command-line prompts and CLASSICINSERT opens the classic dialog. Inserting a drawing file also imports its block definitions."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B840AB4A-91E2-4FEC-900A-33E40D1E1925.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_insert/V25/EN_US")

(:name "INSERTOBJ"
 :category :BLOCK
 :aliases ("IO")
 :intl-name "_INSERTOBJ"
 :synopsis "Opens the Insert Object dialog box."
 :options ("Create new Object" "Create from File")
 :arguments NIL
 :description "Opens a dialog to insert OLE objects (linked or embedded documents) into the current drawing; you can create a new object or insert from an existing file, and linked information updates when the source changes while embedded information does not. Windows-only command."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-697B4875-F1C5-4C7C-A7C6-4D14DC1123F7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_insertobj/V25/EN_US")

(:name "INTERFERE"
 :category :|3D|
 :aliases ("INF")
 :intl-name "_INTERFERE"
 :synopsis "Shows volumes and areas of interference between two sets of ACIS entities."
 :options ("Nested selection" "Settings" "Check first Set" "ALL")
 :arguments NIL
 :description "Compares 3D solids and 2D regions from two selected sets to identify overlapping volumes or areas, placing the resulting interference geometry on the layer named by the INTERFERELAYER system variable; in BricsCAD Pro it can optionally create new ACIS solids from the common portions."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FF1ED01E-9AB5-455F-8E84-2F01C2EA3B62.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_interfere/V25/EN_US")

(:name "INTERSECT"
 :category :|3D|
 :aliases ("IN")
 :intl-name "_INTERSECT"
 :synopsis "Performs Boolean intersection operations on 3D solids and 2D regions."
 :options NIL
 :arguments "a selection set of the 3D solids and/or 2D regions to intersect, terminated by an empty return"
 :description "Removes all portions of the selected entities except those in common, retaining only the volumes and areas that exist in all selected objects; non-intersecting solids and regions are erased, and in BricsCAD Lite it works with region entities only."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-904008EB-D92A-4B69-B79F-6C3A033DB3DF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_intersect/V25/EN_US")

(:name "ISOLATEOBJECTS"
 :category :VIEW
 :aliases ("ISOLATE")
 :intl-name "_ISOLATEOBJECTS"
 :synopsis "Hides all but the entity(ies) selected."
 :options NIL
 :arguments "a selection set of the objects to keep visible (the only prompt is Select objects)"
 :description "Displays only the selected entities and hides all others; the UNISOLATEOBJECTS command reverses the action and the OBJECTISOLATIONMODE system variable controls the hidden-state behavior."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-12C177FC-E8D1-44C0-9199-A9D46FC2DA39.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_isolateobjects/V25/EN_US")

(:name "ISOPLANE"
 :category :VIEW
 :aliases ("IS")
 :intl-name "_ISOPLANE"
 :synopsis "Toggles the SNAPISOPAIR system variable."
 :options ("Left" "Right" "Top" "Toggle")
 :arguments NIL
 :description "Toggles the SNAPISOPAIR system variable to designate the current drafting plane (left, top, or right) for isometric drawing; it can be invoked transparently within another command and only affects cursor movement when the snap style is set to Isometric. AutoCAD notes it has been superseded by ISODRAFT."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9B1EEA63-BEC1-413E-B69F-541B5865F1A1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_isoplane/V25/EN_US")

(:name "JOIN"
 :category :MODIFY
 :aliases NIL
 :intl-name "_JOIN"
 :synopsis "Joins 2D entities at their common endpoints."
 :options ("Source object" "Multiple objects to join at once" "Close")
 :arguments "the source object and/or the objects to join, terminated by an empty return"
 :description "Joins lines, 2D and 3D polylines, arcs, elliptical arcs, splines, and helices at their common endpoints; the resulting entity type depends on the input entity types and their coplanarity, and construction lines, rays, and closed objects cannot be joined."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4D2A28C3-3E7F-4830-BE6A-7C9907C95488.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_join/V25/EN_US")

(:name "LAYCUR"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYCUR"
 :synopsis "Moves selected entities to the current layer."
 :options NIL
 :arguments "a selection set of the entities to move, terminated by an empty return"
 :description "Moves the selected entities to the current layer without requiring you to specify a layer name, then reports how many entities were moved and to which layer."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EA22341E-62F1-4C7D-9B14-F83526433C64.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_laycur/V25/EN_US")

(:name "LAYDEL"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYDEL"
 :synopsis "Permanently deletes a layer from the current drawing, along with all entities on it."
 :options ("Type-it" "List" "Name" "Pick<<")
 :arguments NIL
 :description "Deletes a specified layer and all objects on it, then purges the layer from the drawing; the layer can be identified by selecting an entity on it or by choosing it from a dialog, and block definitions referencing the layer are redefined without those objects."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A24D1310-E176-4A1E-943C-47211C07F94A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_laydel/V25/EN_US")

(:name "LAYER"
 :category :LAYER
 :aliases ("DDLMODES" "LA")
 :intl-name "_LAYER"
 :synopsis "Manages layers and layer properties (opens the Layer Properties Manager / Layers panel)."
 :options NIL
 :arguments "No command-line arguments; opens the Layer Properties Manager / Layers panel dialog. The -LAYER variant is the command-line-driven form."
 :description "The LAYER command opens the Layer Properties Manager (Layers panel in BricsCAD), where you control object visibility and assign layer properties such as color and linetype. Objects on a layer normally assume that layer's properties, but any layer property can be overridden per object. The panel reappears at its previous size and location."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9123091A-2DCB-4DE8-983C-F7CA38FA67BE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_layer/V25/EN_US")

(:name "LAYERP"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYERP"
 :synopsis "Restores layer properties to their previous state (undoes the last change to layer settings)."
 :options NIL
 :arguments "No arguments and no prompts; executes immediately and restores the previous layer settings one change at a time."
 :description "LAYERP (Layer Previous) undoes the most recent change made to layer settings via the Layer control, Layer Properties Manager, or -LAYER command, one change at a time. In BricsCAD it functions only when the LAYERPMODE system variable is enabled and reports \"Previous layer settings were restored.\" It cannot restore renamed layers to their original names, recover deleted or purged layers, or remove newly added layers."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F266407A-0894-4930-9544-8D4087FD66B9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_layerp/V25/EN_US")

(:name "LAYERSTATE"
 :category :LAYER
 :aliases ("LAS")
 :intl-name "_LAYERSTATE"
 :synopsis "Saves, restores, and manages sets of layer settings called layer states."
 :options NIL
 :arguments "No command-line arguments; opens the layer states manager dialog (Drawing Explorer Layer States category in BricsCAD) where states are saved, restored, edited, imported, or exported."
 :description "LAYERSTATE captures the current layer settings as a named snapshot (layer state) that can later be restored, edited, imported, or exported for use across drawings. In BricsCAD it opens the Drawing Explorer on the Layer States category; restore behavior includes handling layers not found in the state and optionally applying the state as viewport overrides in a layout viewport."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F1453A4F-C184-40D9-9EE1-E1149812501A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_layerstate/V25/EN_US")

(:name "LAYFRZ"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYFRZ"
 :synopsis "Freezes the layers of selected entities."
 :options ("Settings" "Viewports" "Vpfreeze" "Freeze" "Block selection" "Block"
           "Entity" "None" "Selection" "Undo")
 :arguments "Select one or more entities whose layers are to be frozen and press Enter; optionally choose Settings to set Viewports (Vpfreeze/Freeze) or Block selection behavior, or Undo to reverse the last freeze."
 :description "LAYFRZ freezes the layers of selected entities so all entities on those layers become invisible, which can speed display and regeneration in large drawings. Layers can be frozen in the current viewport only (Vpfreeze) or in all viewports (Freeze), and Block selection controls how layers within blocks and xrefs are handled. The command line confirms which layers were frozen or reports if the current layer cannot be frozen."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E7DB1E23-EB54-4DB7-B168-7725DFE6F100.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_layfrz/V25/EN_US")

(:name "LAYISO"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYISO"
 :synopsis "Isolates the layers of selected entities (hides or locks all other layers)."
 :options ("Settings" "Off" "Vpfreeze" "Lock" "Fade")
 :arguments "Select one or more entities on the layers to isolate and press Enter; optionally use Settings to choose whether non-isolated layers are turned Off/frozen (Vpfreeze in current viewport) or Locked (with Fade)."
 :description "LAYISO isolates the layers of the selected entities, leaving only those layers visible and unlocked while all other layers are hidden or locked depending on the current setting. Non-isolated layers can be turned off or frozen (in all viewports or only the current viewport via Vpfreeze), or locked and faded. The command line confirms which layer(s) were isolated; LAYUNISO restores the previous state."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E24B9866-9538-43BF-A3DF-AA7E2341C624.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_layiso/V25/EN_US")

(:name "LAYLCK"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYLCK"
 :synopsis "Locks the layer of a selected entity."
 :options NIL
 :arguments "Select a single entity on the layer to be locked; the command line confirms which layer was locked."
 :description "LAYLCK locks the layer of a selected entity to prevent entities on that layer from being edited or accidentally modified. Entities on locked layers are faded by default, with the fade amount controlled by the LAYLOCKFADECTL system variable."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D011ADFD-CB4B-4F29-954A-EF2246C1DFB2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_laylck/V25/EN_US")

(:name "LAYMCH"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYMCH"
 :synopsis "Changes the layer of selected entities to match a destination layer."
 :options ("Type-it" "Name")
 :arguments "Select the entities to be changed and press Enter, then select an entity on the target layer; alternatively use the Name (Type-it) option to enter the destination layer name via the Change to Layer dialog."
 :description "LAYMCH reassigns selected entities to a different layer by selecting the entities to change and then selecting an entity that resides on the desired destination layer. Instead of picking a target entity, the Name (Type-it) option lets you enter the destination layer name directly. The -LAYMCH variant displays options at the command line only."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-73F158B0-8401-4CAE-9204-94C36DF6D409.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_laymch/V25/EN_US")

(:name "LAYMCUR"
 :category :LAYER
 :aliases ("SETLAYER")
 :intl-name "_LAYMCUR"
 :synopsis "Sets the current working layer to that of a selected entity."
 :options NIL
 :arguments "Select one entity whose layer will be made the current layer."
 :description "LAYMCUR (short for \"layer make current\") sets the current working layer to that of a selected entity, providing a convenient alternative to specifying the layer name in the Layer Properties Manager. You choose one entity and its layer becomes current."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E44FA50E-DB98-48C4-AE6B-052ED7287497.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_laymcur/V25/EN_US")

(:name "LAYMRG"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYMRG"
 :synopsis "Merges layers of selected entities into a destination layer."
 :options ("Type-it" "Name" "List" "Undo")
 :arguments "Select entities on the layers to be merged and press Enter (or use Name/Type-it to enter layer names, List/* to list layers, Undo to remove a prior selection), then select an entity on the target layer, and confirm Yes to purge the merged layers."
 :description "LAYMRG moves the entities on selected layers to a target layer and then purges the emptied source layers from the drawing, reducing the layer count. Layers can be chosen by selecting objects on them or by entering layer names via dialog boxes; a confirmation prompt asks whether to continue (Yes purges the merged layers, No exits). The -LAYMRG variant displays options at the command line only."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7D66940F-EC67-4DEC-89BC-82B887EABD6E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_laymrg/V25/EN_US")

(:name "LAYOFF"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYOFF"
 :synopsis "Turns off the layers of selected objects."
 :options ("Settings" "Viewports" "Vpfreeze" "Block selection" "Block" "Entity"
           "None" "Undo")
 :arguments "Select an object on each layer to turn off and press Enter; optionally use Settings (Viewports/Block selection) or Undo. If the current layer is selected you are asked whether to turn it off."
 :description "Turns off the layers of the selected objects, hiding all objects on those layers. Settings control viewport behavior (Vpfreeze or Off) and how layers inside blocks and xrefs are treated."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BAE680D0-9AD5-4952-A139-B81732D7B5FB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_layoff/V25/EN_US")

(:name "LAYON"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYON"
 :synopsis "Turns on all layers in the drawing."
 :options NIL
 :arguments "No arguments; turns on all layers."
 :description "Turns on all layers so their objects become visible for viewing and editing. Objects on frozen layers stay hidden until thawed, and locked layers must be unlocked before editing."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-575562DA-547E-4247-8616-2F6684838B77.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_layon/V25/EN_US")

(:name "LAYOUT"
 :category :VIEW
 :aliases NIL
 :intl-name "_LAYOUT"
 :synopsis "Creates, copies, renames, and deletes layouts."
 :options ("Copy" "Delete" "New" "Template" "Rename" "SAveas" "Set" "?" "neXt"
           "Previous")
 :arguments "Supplies a layout option keyword (New, Copy, Delete, Rename, SAveas, Set, Template, ?) followed by the layout name(s) it requires; Set is the default."
 :description "Manages the layouts (paper-space sheets) in a drawing. Layouts can be created, copied, deleted, renamed, set current, imported from a template, and saved out; up to 255 layouts are allowed per drawing."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BCE3AD90-9DE0-488C-9CA4-5FDB9401DCE0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_layout/V25/EN_US")

(:name "LAYOUTMERGE"
 :category :VIEW
 :aliases NIL
 :intl-name "_LAYOUTMERGE"
 :synopsis "Merges entities from specified layouts into a single destination layout."
 :options NIL
 :arguments "Specify the source layout(s) to merge, the destination layout (an existing layout or a new name), and whether to remove/delete empty layouts afterward."
 :description "Combines the contents of one or more source layouts into a single destination layout, preserving the merged content as views. Empty layouts can optionally be removed after merging. In AutoCAD it is documented as an Express Tool."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-72D755E1-D065-403F-86CA-7730E539BB82.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_layoutmerge/V25/EN_US")

(:name "LAYTHW"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYTHW"
 :synopsis "Thaws all layers in the drawing."
 :options NIL
 :arguments "No arguments; thaws all frozen layers."
 :description "Thaws all frozen layers so their objects can be displayed and edited. Objects on turned-off layers stay invisible until those layers are turned on, and layers frozen in individual layout viewports must be thawed with VPLAYER."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8590F14F-49DE-40B1-AC90-44EB49ECC9AE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_laythw/V25/EN_US")

(:name "LAYTRANS"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYTRANS"
 :synopsis "Opens the Layer Translator to map and convert layers to specified layer standards."
 :options NIL
 :arguments "No command-line arguments; opens the Layer Translator dialog box (map layers to names and properties loaded from a DWG, DWS, or DWT file, then translate)."
 :description "Translates the layers in the current drawing to a set of layer standards by mapping them to layer names and properties from a specified drawing or standards file. Layer information can be loaded from DWG, DWS, or DWT files, and new layers can be created."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-83CFD677-78F3-492F-A5A3-5A0197D2FA2C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_laytrans/V25/EN_US")

(:name "LAYUNISO"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYUNISO"
 :synopsis "Restores layers to the state before the last LAYISO command."
 :options NIL
 :arguments "No arguments; restores the layers that were isolated by LAYISO."
 :description "Reverses the effect of the previous LAYISO command, restoring the Lock, On/Off, and VP Freeze properties of layers to their state before isolation. Layer changes made after LAYISO are preserved."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0795CBC9-7A9D-4A36-B49E-244C146FF6EA.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_layuniso/V25/EN_US")

(:name "LAYWALK"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYWALK"
 :synopsis "Displays objects on selected layers and freezes or hides objects on all other layers."
 :options NIL
 :arguments "Opens the LayerWalk dialog box; select the layers to display while all unselected layers are temporarily frozen/hidden (states are restored on exit by default)."
 :description "Opens a dialog that lists all layers and displays only the selected ones while temporarily freezing or hiding the rest, letting you review layer contents. Options include filtering layers, selecting all, restoring states on exit, and keeping layer 0 always on."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5682CC98-D131-43B0-9E46-3A403E6FC087.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_laywalk/V25/EN_US")

(:name "LEADER"
 :category :ANNOTATION
 :aliases ("LE" "LEAD")
 :intl-name "_LEADER"
 :synopsis "Creates a line that connects annotation to a feature."
 :options ("Annotation" "Format" "Spline" "Straight" "Arrow" "None" "Undo"
           "Tolerance" "Copy" "Block" "Mtext")
 :arguments "Start point, then successive leader vertices, then Enter; then annotation text or an Annotation option (Tolerance/Copy/Block/None/Mtext) and Format/Undo options."
 :description "Draws a leader line with an arrowhead that connects to annotation such as text, a tolerance, or a block; the annotation is created as an independent MTEXT entity. AutoCAD documents it as legacy and recommends the MLEADER workflow instead."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BC466DEE-ACD8-419A-B017-AB3065336AD7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_leader/V25/EN_US")

(:name "LENGTHEN"
 :category :MODIFY
 :aliases ("EDITLEN" "LEN")
 :intl-name "_LENGTHEN"
 :synopsis "Changes the length of objects and the included angle of arcs."
 :options ("DElta" "Increment" "Percent" "Total" "DYnamic" "Angle" "edit Mode")
 :arguments "An option keyword (DElta/Increment/Percent/Total/DYnamic), then the corresponding value or angle, then the object(s) to change; empty to end."
 :description "Modifies the length of open objects such as lines, polyline segments and arcs, and the included angle of arcs, measured from the endpoint nearest the selection point. It provides an alternative to TRIM or EXTEND."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-76C74C62-DBAA-41E7-8422-F0EE7E769638.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_lengthen/V25/EN_US")

(:name "LIGHT"
 :category :RENDER
 :aliases ("LIGHTING")
 :intl-name "_LIGHT"
 :synopsis "Creates a light."
 :options ("Point" "Spot" "Web" "Distant")
 :arguments "A light-type keyword (Point/Spot/Web/Distant), then that light type's own prompts (location, target, name, intensity)."
 :description "Creates a light object used to produce more realistic renderings; its prompts vary with the light type chosen and mirror the dedicated light commands. In BricsCAD the DEFAULTLIGHTING system variable must be OFF for user lights to take effect."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3239B8C2-E81A-4F08-90FE-C303234EC313.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_light/V25/EN_US")

(:name "LIGHTLIST"
 :category :RENDER
 :aliases ("LL")
 :intl-name "_LIGHTLIST"
 :synopsis "Displays a palette listing all lights in the model."
 :options ("New" "Delete" "Rename" "Select All" "Invert selection")
 :arguments NIL
 :description "Opens a palette or dialog listing every light in the drawing so lights can be selected, deleted, renamed, or have their properties edited. AutoCAD opens the Lights in Model palette; BricsCAD opens the Drawing Explorer with Lights selected."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-46B14BC9-5EED-4175-ABE4-9D8BB967F111.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_lightlist/V25/EN_US")

(:name "LIMITS"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_LIMITS"
 :synopsis "Sets an invisible rectangular boundary in the drawing area."
 :options ("ON" "OFF")
 :arguments "Lower-left corner point, then upper-right corner point; or the ON/OFF keyword to toggle limits checking."
 :description "Defines a rectangular boundary by two corner points that can limit the grid display and restrict point entry when limits checking is on. Drawing outside the boundary is refused while LIMCHECK is enabled."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6CF82FC7-E1BC-4A8C-A23D-4396E3D99632.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_limits/V25/EN_US")

(:name "LINE"
 :category :DRAW
 :aliases ("L" "3DLINE")
 :intl-name "_LINE"
 :synopsis "Creates a series of contiguous straight line segments."
 :options ("Close" "Undo" "Follow" "Length" "Angle")
 :arguments "Supplies a start point, then successive end points as coordinate points; the keyword \"C\" (Close) joins the last segment back to the first, \"U\" (Undo) removes the most recent segment, and an empty string / ENTER (\"\") ends the command. In BricsCAD the first prompt also accepts Follow, plus Angle and Length keywords to place a segment by direction and distance."
 :description "Creates a series of individual, contiguous line segments; each segment is a separate line object that can be edited independently. Points may be entered by coordinates, object snaps, or grid snap, and drawing can continue from the endpoint of a previous line, arc, or polyline."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E8C1190C-A26C-484C-ADDD-DDF81666F69F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_line/V25/EN_US")

(:name "LINETYPE"
 :category :SYSTEM
 :aliases ("DDLTYPE" "EXPLTYPES" "LT")
 :intl-name "_LINETYPE"
 :synopsis "Loads, sets, and modifies linetypes."
 :options NIL
 :arguments NIL
 :description "Opens a manager for loading and setting linetypes, which display as patterns of dashes, dots, text, and symbols or as continuous lines. AutoCAD opens the Linetype Manager (with a -LINETYPE command-line variant); BricsCAD opens the Drawing Explorer with Linetypes selected."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1D3817A0-C5C7-4D52-99A9-F0922F09D4CD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_linetype/V25/EN_US")

(:name "LIST"
 :category :INQUIRY
 :aliases ("LI" "LS")
 :intl-name "_LIST"
 :synopsis "Displays property data for selected objects."
 :options ("SOrt" "SEquential")
 :arguments "Select object(s) to list; empty to end selection."
 :description "Reports the properties of selected objects, such as object type, layer, color, linetype, lineweight, coordinates relative to the current UCS, and space (model or paper). The data can be copied to a text file."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-88FFCF22-5F25-48D9-BD43-4F248EFFCE17.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_list/V25/EN_US")

(:name "LIVESECTION"
 :category :|3D|
 :aliases NIL
 :intl-name "_LIVESECTION"
 :synopsis "Turns on live sectioning for a selected section object."
 :options ("Select section object")
 :arguments "Select a section object to toggle its live sectioning on or off."
 :description "Toggles the Live Section property of a section plane so cross sections of 3D objects intersected by the plane display in real time. It requires a section plane created with SECTIONPLANE."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2913E7CC-0542-45FB-ADEA-06B991C38696.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_livesection/V25/EN_US")

(:name "LOAD"
 :category :FILE
 :aliases NIL
 :intl-name "_LOAD"
 :synopsis "Makes shapes from compiled shape (SHX) files available."
 :options NIL
 :arguments NIL
 :description "Opens a file-selection dialog to load a compiled shape (SHX) file so its shapes become available to the SHAPE command. A shape file must be compiled before loading and must remain accessible while editing the drawing."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B372C134-AD7E-4C28-8D3B-602FF2681B57.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_load/V25/EN_US")

(:name "LOFT"
 :category :|3D|
 :aliases NIL
 :intl-name "_LOFT"
 :synopsis "Creates a 3D solid or surface in the space between several cross sections."
 :options ("Mode" "Solid" "Surface" "Guides" "Path" "Cross sections only"
           "Settings" "Continuity" "Bulge magnitude" "Join multiple edges"
           "Point")
 :arguments "Select cross-sections in lofting order, then Enter; then an option (Guides/Path/Cross-sections only/Settings) or accept to create the loft."
 :description "Creates 3D geometry that passes through a series of cross sections; at least two cross sections must be specified. Guides, a path, and continuity or draft settings control the resulting surface or solid."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0A041818-2E32-4212-A3D8-CE0361C3D229.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_loft/V25/EN_US")

(:name "LOGFILEOFF"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_LOGFILEOFF"
 :synopsis "Closes the command history log file opened by LOGFILEON."
 :options NIL
 :arguments NIL
 :description "Stops recording the text window contents and closes the log file. The command has no prompts or options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5F7F109E-56A2-4DC2-8641-7478C24EA7EB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_logfileoff/V25/EN_US")

(:name "LOGFILEON"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_LOGFILEON"
 :synopsis "Writes the command history contents to a log file."
 :options NIL
 :arguments NIL
 :description "Turns on recording of the text window contents to a log file until the program exits or LOGFILEOFF is used. Log files capture program prompts and keyboard input only; the file location is controlled by system variables such as LOGFILEPATH."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2FB60E75-7926-4344-91DC-B2A1D9F52163.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_logfileon/V25/EN_US")

(:name "LSP"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_LSP"
 :synopsis "Displays a list of available AutoLISP commands, functions, and variables."
 :options ("Commands" "Functions" "Variables" "Load")
 :arguments "An option keyword (Commands/Functions/Variables/Load)."
 :description "Provides organized listings of the available LISP commands, functions, and variables and lets you load additional applications. It is an Express Tool in AutoCAD."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5B95C736-E2C4-4FC7-B623-C259A0D2F608.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_lsp/V25/EN_US")

(:name "LSPSURF"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_LSPSURF"
 :synopsis "Opens the BLADE LISP development environment to edit and debug LISP applications."
 :options NIL
 :arguments NIL
 :description "Opens the BLADE (BricsCAD LISP Advanced Development Environment) dialog box to edit and debug LISP applications. No matching command page exists in the AutoCAD 2026 command reference."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad NIL
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_lspsurf/V25/EN_US")

(:name "LWEIGHT"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_LWEIGHT"
 :synopsis "Sets the current lineweight, lineweight display options, and lineweight units."
 :options NIL
 :arguments NIL
 :description "Opens a settings dialog for lineweight, a property assigned to objects, hatches, leaders and dimension geometry that results in thicker, darker lines. AutoCAD opens the Lineweight Settings dialog (with a -LWEIGHT command-line variant); BricsCAD opens the Settings dialog at the Lineweights category."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DFDA9EE3-D303-44AE-973F-1AA57A9BB06E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_lweight/V25/EN_US")

(:name "MASSPROP"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_MASSPROP"
 :synopsis "Calculates the mass properties of selected 2D regions or 3D solids."
 :options ("Write analysis to a file")
 :arguments "Select region or 3D solid object(s), then Enter; then Yes or No to write the analysis to a file."
 :description "Computes and reports mathematical properties such as area, perimeter or volume, centroid, and moments of inertia for selected 2D regions and 3D solids; other object types are ignored. The report can be written to an MPR file."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CAA51229-293E-4A0C-BFF3-93226252CF13.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_massprop/V25/EN_US")

(:name "MATBROWSERCLOSE"
 :category :RENDER
 :aliases NIL
 :intl-name "_MATBROWSERCLOSE"
 :synopsis "Closes the Materials Browser."
 :options NIL
 :arguments NIL
 :description "Closes the Materials Browser (Render materials panel), which can be reopened with MATBROWSEROPEN. The command has no prompts or options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F9F8F880-34BC-4F52-AF98-86EB63E2C360.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_matbrowserclose/V25/EN_US")

(:name "MATBROWSEROPEN"
 :category :RENDER
 :aliases ("MATB")
 :intl-name "_MATBROWSEROPEN"
 :synopsis "Opens the Materials Browser."
 :options NIL
 :arguments NIL
 :description "Opens the Materials Browser (Render materials panel) for navigating and managing materials used in renderings. The panel can be floated, docked, or stacked."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-905808B6-5A00-44D4-9C93-914B41688250.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_matbrowseropen/V25/EN_US")

(:name "MATCHPROP"
 :category :MODIFY
 :aliases ("MA")
 :intl-name "_MATCHPROP"
 :synopsis "Applies the properties of a selected object to other objects."
 :options ("Settings")
 :arguments "Select the source object, then select destination object(s); the Settings option chooses which properties to copy; empty to end."
 :description "Copies properties such as color, layer, linetype, linetype scale, lineweight, transparency and plot style from a source object to one or more destination objects. A Settings/Property Settings dialog controls which properties are copied."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BD476C7C-2CA4-4FB2-8A9E-EAAD5A072445.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_matchprop/V25/EN_US")

(:name "MATERIALASSIGN"
 :category :RENDER
 :aliases NIL
 :intl-name "_MATERIALASSIGN"
 :synopsis "Assigns the material defined in CMATERIAL to selected objects."
 :options ("Undo")
 :arguments "Select object(s) to receive the current material (CMATERIAL); Undo to reverse; empty to end."
 :description "Applies the material named in the CMATERIAL system variable to selected objects to enhance visual styles and renderings; the material may be BYLAYER, BYBLOCK, or a named material. In BricsCAD a paintbrush glyph assigns the material, with CTRL to apply to a single face."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FAB3820A-E322-4056-B13B-5045BA5BA55C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_materialassign/V25/EN_US")

(:name "MATERIALMAP"
 :category :RENDER
 :aliases ("SETUV")
 :intl-name "_MATERIALMAP"
 :synopsis "Adjusts how a texture is mapped to a face or an object."
 :options ("Box" "Planar" "Cylindrical" "Spherical" "Move" "Rotate"
           "sWitch mapping mode" "copY mapping to" "Reset mapping")
 :arguments "A mapping-type keyword (Box/Planar/Cylindrical/Spherical), then select face(s) or object(s), then adjust with the mapping gizmo; sWitch/copY/Reset options as needed."
 :description "Adjusts the placement and alignment of texture images on 3D solids, faces, polylines, and meshes so patterns line up with the geometry. Mapping shapes and an interactive gizmo control the alignment."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C9DFF585-97CE-4380-A41F-B632FA8EA9F6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_materialmap/V25/EN_US")

(:name "MATERIALS"
 :category :RENDER
 :aliases ("FINISH" "MAT" "RMAT")
 :intl-name "_MATERIALS"
 :synopsis "Opens the Materials Browser to view and manage materials."
 :options NIL
 :arguments NIL
 :description "Opens an interface to view, sort, search, select and modify the materials in the current drawing. AutoCAD opens the Materials Browser; BricsCAD opens the Drawing Explorer with Materials selected."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6239681A-C4E4-4515-9578-23B6EDFF6A80.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_materials/V25/EN_US")

(:name "MEASURE"
 :category :DRAW
 :aliases NIL
 :intl-name "_MEASURE"
 :synopsis "Creates point objects or blocks at measured intervals along an object."
 :options ("Block")
 :arguments "Select the object to measure, then the segment length; or the Block option to place a named block (with alignment Yes/No)."
 :description "Places points or blocks at equally spaced specified distances along the length or perimeter of a selected object. Points and blocks lie on the object with orientation set by the UCS XY plane."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-212933E8-BC53-4872-A3DC-32C48DE1B2D0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_measure/V25/EN_US")

(:name "MENU"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_MENU"
 :synopsis "Loads a customization (interface) file."
 :options NIL
 :arguments NIL
 :description "Loads a customization file that modifies the user interface. AutoCAD documents it as an obsolete command retained for script compatibility and superseded by CUILOAD; BricsCAD opens a Choose a Customization File dialog accepting CUI, CUIX, MNU, MNS, or ICM files."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9EF6BC00-4C90-47CB-BF93-6FC382FA9E81.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_menu/V25/EN_US")

(:name "MENULOAD"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_MENULOAD"
 :synopsis "Opens the Customization Groups dialog box."
 :options NIL
 :arguments "Supplies no arguments: (command \"_MENULOAD\") opens the Customization Groups dialog box, where customization (menu) groups are loaded and unloaded interactively. No command-line prompt sequence is documented."
 :description "In BricsCAD, MENULOAD opens the Customization Groups dialog box for loading and unloading customization groups (available in Lite, Pro, Mechanical, and BIM). Not documented as a command in AutoCAD 2026 (AutoCAD uses MENU/CUILOAD/CUIUNLOAD instead; MENU is retained only for script compatibility)."
 :availability :BRICSCAD-ONLY
 :autocad-versions NIL
 :bricscad-versions "all"
 :source-autocad NIL
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_menuload/V25/EN_US")

(:name "MENUUNLOAD"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_MENUUNLOAD"
 :synopsis "Opens the Customization Groups dialog box."
 :options NIL
 :arguments "Supplies no arguments: (command \"_MENUUNLOAD\") opens the Customization Groups dialog box, where customization (menu) groups can be unloaded interactively. No command-line prompt sequence is documented."
 :description "In BricsCAD, MENUUNLOAD opens the Customization Groups dialog box for managing (loading/unloading) customization groups. Not documented as a command in AutoCAD 2026 (AutoCAD uses CUILOAD/CUIUNLOAD; the legacy MENU command is retained only for script compatibility)."
 :availability :BRICSCAD-ONLY
 :autocad-versions NIL
 :bricscad-versions "all"
 :source-autocad NIL
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_menuunload/V25/EN_US")

(:name "MINSERT"
 :category :BLOCK
 :aliases NIL
 :intl-name "_MINSERT"
 :synopsis "Inserts multiple instances of a block in a rectangular array."
 :options ("Scale" "Corner" "XYZ" "Rotate" "Basepoint")
 :arguments "Block name, insertion point, X and Y scale, rotation angle, number of rows, number of columns, distance between rows, distance between columns."
 :description "Combines INSERT and ARRAY to insert a block as a rectangular array with a set number of rows and columns. Blocks inserted with MINSERT cannot be exploded and are incompatible with annotative blocks."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A780A2FA-4A2E-4574-950F-E788AB71F527.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_minsert/V25/EN_US")

(:name "MIRROR"
 :category :MODIFY
 :aliases ("MI")
 :intl-name "_MIRROR"
 :synopsis "Creates a mirrored copy of selected objects."
 :options NIL
 :arguments "Select object(s), then the first and second points of the mirror line, then Yes or No to delete the source objects."
 :description "Reflects selected objects across a mirror line defined by two points in the 2D plane, keeping or deleting the originals. The MIRRTEXT system variable controls whether text is also mirrored."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-595277C8-9B87-4CFB-A3AF-769537A22F3D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mirror/V25/EN_US")

(:name "MIRROR3D"
 :category :|3D|
 :aliases ("3DMIRROR" "3DM")
 :intl-name "_MIRROR3D"
 :synopsis "Creates a mirrored copy of selected objects across a mirroring plane."
 :options ("Object" "Last" "Zaxis" "View" "XY" "YZ" "ZX" "3points")
 :arguments "Select object(s); a mirror-plane option (3points/Object/Last/Zaxis/View/XY/YZ/ZX) with its defining points; then Yes or No to delete the source objects."
 :description "Mirrors selected entities about a mirror plane in 3D space. The plane can be defined by three points, a planar object, the last plane, a Z axis, the view plane, or a standard coordinate plane, and the originals may be kept or deleted."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E769E87D-8502-4A1E-B6F8-03889F26F944.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mirror3d/V25/EN_US")

(:name "MKLTYPE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_MKLTYPE"
 :synopsis "Creates a linetype definition based on selected objects."
 :options NIL
 :arguments "A .LIN file, the linetype name, a description, a start point, an end point, then select object(s) (line/polyline/point/shape/text)."
 :description "Generates a custom linetype definition from selected objects and stores it in a specified LIN file, then loads it into the current drawing. It is an Express Tool in AutoCAD."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7C094008-385C-459D-818A-05A2169D13DF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mkltype/V25/EN_US")

(:name "MKSHAPE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_MKSHAPE"
 :synopsis "Creates a shape definition based on selected objects."
 :options NIL
 :arguments "A .SHP file, the shape name, a resolution value, an insertion base point, then select object(s)."
 :description "Creates a reusable shape definition from selected geometry and stores it in an SHP file; the shape can then be placed with SHAPE. A resolution value trades accuracy against performance, and it is an Express Tool in AutoCAD."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-829B0626-36AB-443A-B53C-D7227297C6CE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mkshape/V25/EN_US")

(:name "MLEADER"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_MLEADER"
 :synopsis "Creates a multileader object."
 :options ("leader arrowHead first" "leader Landing first" "Content first"
           "leader tYpe" "leader lAnding" "Content type" "Maxpoints"
           "First angle" "Second angle")
 :arguments "A leader arrowhead point and landing point (or the leader Landing first / Content first option), then the content (Mtext or Block)."
 :description "Creates a multileader consisting of an arrowhead, a landing line, a leader line or curve, and content that is either an MTEXT object or a block. Multileaders can be created arrowhead first, landing first, or content first, using the current multileader style."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-764DA12B-1280-4D1A-8673-F9F8A136CB83.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mleader/V25/EN_US")

(:name "MLEADERALIGN"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_MLEADERALIGN"
 :synopsis "Aligns and spaces selected multileader objects."
 :options ("byMleader" "onpolyLine" "Parallel" "Spacing" "Circle" "Distribute")
 :arguments "Select the multileaders, then Enter; select or designate the multileader to align to; an alignment option (Distribute/Parallel/Spacing/onpolyLine/Circle) and its parameters."
 :description "Aligns the landings of two or more multileaders to each other, to a polyline, or in an array around a circle, and controls the spacing between them. Distribution and parallel options set how the leaders line up."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-14A45038-97CF-4583-9803-75EECF72CD13.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mleaderalign/V25/EN_US")

(:name "MLEADERCOLLECT"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_MLEADERCOLLECT"
 :synopsis "Collects multileaders that contain blocks into a single leader."
 :options ("Vertical" "Horizontal" "Wrap")
 :arguments "Select multileaders containing blocks, then Enter; a placement point; an arrangement option (Vertical/Horizontal/Wrap with a width or number)."
 :description "Organizes selected block-content multileaders into rows or columns and displays the result with a single leader. Options arrange the collected content vertically, horizontally, or wrapped."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CFD5E822-9F89-475D-8724-E0843EE4C5D4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mleadercollect/V25/EN_US")

(:name "MLEADEREDIT"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_MLEADEREDIT"
 :synopsis "Adds leader lines to, or removes them from, a multileader object."
 :options ("Add leaders" "Remove leaders")
 :arguments "Select a multileader; choose Add leader (then an arrowhead location) or Remove leader."
 :description "Adds or removes leader lines on an existing multileader object. New leaders are positioned to the left or right based on cursor location."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9B157447-A952-42A2-AF68-98CC7B6F12FD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mleaderedit/V25/EN_US")

(:name "MLEADERSTYLE"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_MLEADERSTYLE"
 :synopsis "Creates and modifies multileader styles."
 :options NIL
 :arguments NIL
 :description "Opens a manager for defining and adjusting the appearance of multileaders beyond the default STANDARD style. AutoCAD opens the Multileader Style Manager; BricsCAD opens the Drawing Explorer with Multileader Styles selected."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9435FC8D-7811-4C12-A9D7-7FCEF7A149A4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mleaderstyle/V25/EN_US")

(:name "MLINE"
 :category :DRAW
 :aliases ("ML")
 :intl-name "_MLINE"
 :synopsis "Creates multiple parallel lines (a multiline)."
 :options ("Justification" "Scale" "STyle" "Close" "Undo")
 :arguments "Optional Justification/Scale/STyle options, then a start point and successive points; the Close or Undo keyword; empty to end."
 :description "Creates a multiline object composed of parallel line elements defined by a series of vertices, using the current multiline style. Justification, scale, and style can be set before or during drawing."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A6839A41-0D81-44F2-953A-220307F9380A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mline/V25/EN_US")

(:name "MLSTYLE"
 :category :DRAW
 :aliases NIL
 :intl-name "_MLSTYLE"
 :synopsis "Creates, modifies, and manages multiline styles."
 :options NIL
 :arguments NIL
 :description "Manages multiline styles, which define the parallel line elements, fills, joints, and end caps used by MLINE. AutoCAD opens the Multiline Style dialog; BricsCAD opens the Drawing Explorer with Multiline Styles selected."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-548AD96E-53E5-4635-B6F8-0317407B843F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mlstyle/V25/EN_US")

(:name "MOCORO"
 :category :MODIFY
 :aliases NIL
 :intl-name "_MOCORO"
 :synopsis "Moves, copies, rotates, and scales selected objects in one command."
 :options ("Move" "Copy" "Rotate" "Scale" "Base" "Undo")
 :arguments "Select object(s) and a base point, then an option keyword (Move/Copy/Rotate/Scale/Base/Undo) with its parameters."
 :description "Combines frequently used modify operations so selected objects can be moved, copied, rotated, or scaled within a single command after picking a base point. It is an Express Tool in AutoCAD."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-385D1161-6A07-432E-B69B-71C7D19409F5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mocoro/V25/EN_US")

(:name "MOVE"
 :category :MODIFY
 :aliases ("M")
 :intl-name "_MOVE"
 :synopsis "Moves objects a specified distance in a specified direction."
 :options ("Displacement")
 :arguments "Selects objects (ending the selection with an empty string), then supplies a base point and a second point that define the displacement vector; e.g. (command \"_MOVE\" ss \"\" base-pt second-pt). A displacement vector may be given instead of two points."
 :description "The MOVE command relocates selected objects by a base point and a second point that together define the distance and direction of movement; a direct displacement value can be entered instead. BricsCAD documents the same base-point/displacement-vector behavior."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-47CE7325-84C0-4414-80A3-29DC98392709.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_move/V25/EN_US")

(:name "MOVEBAK"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_MOVEBAK"
 :synopsis "Sets the destination folder for drawing backup (BAK) files."
 :options NIL
 :arguments "A new folder name for all BAK files; a dot clears the setting, a tilde opens a folder-selection dialog."
 :description "Specifies a folder where BAK backup files are written instead of the drawing folder. In AutoCAD 2026 MOVEBAK is a system variable rather than a command, so no command reference page exists for it."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad NIL
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_movebak/V25/EN_US")

(:name "MPEDIT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_MPEDIT"
 :synopsis "Edits multiple polylines and converts lines and arcs to polylines."
 :options ("Open" "Close" "Join" "Width" "Fit" "Spline" "Decurve" "Ltype gen"
           "eXit")
 :arguments "Select object(s), Yes or No to convert lines and arcs to polylines, then an option (Open/Close/Join/Width/Fit/Spline/Decurve/Ltype gen/eXit)."
 :description "Applies PEDIT-style edits to several polylines at once and can convert multiple lines and arcs into polylines. It is an Express Tool in AutoCAD."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-01661FA3-466E-47C6-B6FF-CBF0F29D1CD2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mpedit/V25/EN_US")

(:name "MSPACE"
 :category :VIEW
 :aliases ("MS")
 :intl-name "_MSPACE"
 :synopsis "In a layout, switches from paper space to model space in a viewport."
 :options NIL
 :arguments NIL
 :description "Activates a model space viewport while in a paper space layout so views, scales, and layer properties can be adjusted inside it. Return to paper space with PSPACE or by double-clicking outside the viewport."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4FFCC0F6-ACA4-4C14-90BA-15A04E5ECA80.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mspace/V25/EN_US")

(:name "MSTRETCH"
 :category :MODIFY
 :aliases NIL
 :intl-name "_MSTRETCH"
 :synopsis "Stretches objects using multiple crossing windows and crossing polygons."
 :options ("C" "CP" "Done" "Undo" "Remove objects")
 :arguments "Define one or more crossing windows or polygons (C/CP), Done, then a base point and a second point."
 :description "Extends STRETCH by letting you define more than one crossing window or crossing polygon and stretch all the selected objects at once. It is an Express Tool in AutoCAD."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F91739FD-8944-40FD-A243-4BFFA12577CF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mstretch/V25/EN_US")

(:name "MTEXT"
 :category :TEXT
 :aliases ("MT" "T")
 :intl-name "_MTEXT"
 :synopsis "Creates a multiline text object."
 :options ("Height" "Justify" "Line spacing" "Rotation" "Style" "Width"
           "Columns" "Direction")
 :arguments "First corner and opposite corner of the text box (or options such as Height/Justify/Style/Width), then the text content."
 :description "Creates one or more paragraphs of text as a single multiline text object placed within a bounding box, with a built-in editor for formatting, columns, and boundaries. AutoCAD also provides a -MTEXT variant that bypasses the in-place editor."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E6BCE05D-B9E3-4875-BBBC-29134EA6FD51.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mtext/V25/EN_US")

(:name "MULTIPLE"
 :category :OTHER
 :aliases NIL
 :intl-name "_MULTIPLE"
 :synopsis "Repeats the next command until you press Esc."
 :options NIL
 :arguments NIL
 :description "Repeats the command that follows it until Esc is pressed; only the command name is repeated, so parameters must be re-entered each time, and dialog-box commands are not repeated. AutoCAD notes MULTIPLE cannot be used as an argument to the AutoLISP command function."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-60331A1C-1CD0-4626-BC56-F33D0A3683E9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_multiple/V25/EN_US")

(:name "MVIEW"
 :category :VIEW
 :aliases ("MV")
 :intl-name "_MVIEW"
 :synopsis "Creates and controls layout viewports."
 :options ("ON" "OFF" "Fit" "Shadeplot" "Lock" "NEw" "NAmed" "Object"
           "Polygonal" "Restore" "Layer" "2" "3" "4")
 :arguments "A viewport option (ON/OFF/Fit/Lock/Object/Polygonal/Restore/2/3/4) or the first corner and opposite corner of a rectangular viewport."
 :description "Creates and manages one or more rectangular or non-rectangular viewports in a paper space layout to display model space. The command is unavailable in model space, where VPORTS is used instead."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-731B2752-B9E2-443E-816A-9B4851296455.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mview/V25/EN_US")

(:name "MVSETUP"
 :category :VIEW
 :aliases NIL
 :intl-name "_MVSETUP"
 :synopsis "Sets up the specifications of a drawing and its layout viewports."
 :options ("Align" "Create" "Scale viewports" "Undo")
 :arguments NIL
 :description "Sets up drawing specifications and paper space viewports, then aligns, rotates, and scales them; the prompts differ depending on whether it is run from the Model or a Layout tab. It can be entered transparently."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D76CD04B-12FB-4E25-8C8B-B70F4904D1D6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_mvsetup/V25/EN_US")

(:name "NCOPY"
 :category :MODIFY
 :aliases NIL
 :intl-name "_NCOPY"
 :synopsis "Copies objects nested in an xref, block, or DGN underlay."
 :options ("Displacement" "Multiple" "Array" "Settings")
 :arguments "Select nested object(s) within an xref/block/underlay, then Enter; a base point, then a second point; or Displacement/Multiple/Array options."
 :description "Copies objects contained in an xref, block, or DGN underlay into the current drawing without exploding or binding the reference. Options support multiple copies and arrays."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-12FCCFDF-9B3B-48D0-AC46-DF1D3519B0E5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_ncopy/V25/EN_US")

(:name "NETLOAD"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_NETLOAD"
 :synopsis "Loads a .NET application."
 :options NIL
 :arguments "The .NET assembly file name when FILEDIA is 0; otherwise a Choose .NET Assembly dialog is shown."
 :description "Loads a managed .NET application (a DLL assembly) into the program. With FILEDIA set to 0 it prompts for the assembly file name at the command line instead of opening the dialog."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D954BCC1-C4F0-488B-8F60-1D02D68940E0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_netload/V25/EN_US")

(:name "NEW"
 :category :FILE
 :aliases NIL
 :intl-name "_NEW"
 :synopsis "Starts a new drawing."
 :options NIL
 :arguments "Dialog-driven: displays the Select Template dialog (or the Create New Drawing dialog when STARTUP is 1) to choose a DWT/DWG template. When FILEDIA is 0 it prompts at the command line for a template file name. A scripted (command \"_NEW\") typically supplies no further arguments unless FILEDIA is 0."
 :description "Creates a new drawing. In AutoCAD, behavior depends on the STARTUP system variable (Create New Drawing dialog vs. Select Template dialog), with FILEDIA=0 forcing a command-prompt form. In BricsCAD, NEW opens the Select Template dialog box to pick a DWT or DWG template."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-90BE41A2-7FFD-44DB-A927-B7A9277C75C2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_new/V25/EN_US")

(:name "NEWSHEETSET"
 :category :FILE
 :aliases NIL
 :intl-name "_NEWSHEETSET"
 :synopsis "Creates a new sheet set."
 :options ("Use template" "Use another sheet set" "Use existing drawings"
           "Empty")
 :arguments NIL
 :description "Opens the Create Sheet Set wizard or dialog to create a new sheet set data file for managing layouts, file paths, and project data. A sheet set can be built from a template, from an existing sheet set, from existing drawings, or empty."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2E32E0F4-E351-402A-BFA3-974B14F7B004.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_newsheetset/V25/EN_US")

(:name "OBJECTSCALE"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_OBJECTSCALE"
 :synopsis "Adds or deletes supported scales for annotative objects."
 :options ("Add" "Delete")
 :arguments "Select annotative object(s), then Enter; then Add or Delete scales via the Annotative Object Scale dialog."
 :description "Manages which annotation scales are assigned to selected annotative objects so they display correctly at different view scales. AutoCAD provides a -OBJECTSCALE command-line variant."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-96A4233D-438F-467C-A259-7B249C89950E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_objectscale/V25/EN_US")

(:name "OFFSET"
 :category :MODIFY
 :aliases ("O")
 :intl-name "_OFFSET"
 :synopsis "Creates concentric circles, parallel lines, and parallel curves."
 :options ("Through" "Erase" "Layer" "Multiple" "Undo" "Exit" "Both Sides")
 :arguments "First an offset distance (or the \"Through\" keyword to offset through a picked point), then repeatedly: select an entity to offset and a point indicating the side. Keyword options include \"Erase\", \"Layer\" (Current or Source), \"Multiple\", \"Undo\", and \"Exit\". An empty string ends the command."
 :description "Creates parallel copies of lines, polylines, splines, circles and edges at a specified distance or through a designated point; the radius of curved entities is adjusted accordingly. The command repeats automatically until the user exits."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C0E4246D-C420-42BD-A6FC-8B1852EFD005.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_offset/V25/EN_US")

(:name "OLELINKS"
 :category :EDIT
 :aliases NIL
 :intl-name "_OLELINKS"
 :synopsis "Updates, changes, and cancels linked OLE objects."
 :options NIL
 :arguments NIL
 :description "Opens the Links dialog box to view and manage linked OLE (object linking and embedding) objects in the drawing, allowing links to be updated, their source changed, or the link broken."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4D05CD71-D894-4FC4-A7FC-7962159A94E8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_olelinks/V25/EN_US")

(:name "OLEOPEN"
 :category :EDIT
 :aliases NIL
 :intl-name "_OLEOPEN"
 :synopsis "Opens the selected OLE object in its source application."
 :options NIL
 :arguments "Requires an OLE object to be selected; opens it in its source application."
 :description "Opens a selected OLE object in its source application for editing, the same as double-clicking the object. In BricsCAD it is available only on Windows and cannot open the object if the link to the source application is broken."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4D4BC523-461A-46C9-A92B-CE3DF7AA7C54.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_oleopen/V25/EN_US")

(:name "OOPS"
 :category :EDIT
 :aliases ("UNDELETE" "UNERASE")
 :intl-name "_OOPS"
 :synopsis "Restores the most recently erased objects."
 :options NIL
 :arguments NIL
 :description "Restores objects erased by the last ERASE command, including objects erased by BLOCK or WBLOCK operations; it displays no prompts and has no options. It cannot restore objects removed by PURGE."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0E72CDCD-9ECA-453A-8A04-CA2921740270.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_oops/V25/EN_US")

(:name "OPEN"
 :category :FILE
 :aliases NIL
 :intl-name "_OPEN"
 :synopsis "Opens an existing drawing file."
 :options NIL
 :arguments "Dialog-driven: displays the Select File (Open file) dialog. When FILEDIA is 0 it prompts for the name of the drawing to open (enter ~ to force the dialog). A scripted call may supply the drawing file name when FILEDIA is 0."
 :description "Opens an existing drawing for editing. AutoCAD shows the Select File dialog by default and supports Partial Open / Partial Open Read-Only to load specific geometry, views, or layers. BricsCAD opens a file dialog supporting DWG, DXF, DWI and various 3D formats depending on the edition (Lite and above)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3738384A-3047-4532-866C-23D3FFF3AA45.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_open/V25/EN_US")

(:name "OPENSHEETSET"
 :category :FILE
 :aliases NIL
 :intl-name "_OPENSHEETSET"
 :synopsis "Opens a selected sheet set via a file-selection dialog box."
 :options NIL
 :arguments "No command-line arguments; opens a standard file selection dialog to choose a sheet set data (DST) file."
 :description "Displays a file selection dialog for choosing a sheet set data (DST) file, which is loaded into the Sheet Set Manager (AutoCAD) or Sheet Sets panel (BricsCAD)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F22CB49D-7F81-4EBE-A6F0-8EBC55C9721A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_opensheetset/V25/EN_US")

(:name "OPTIONS"
 :category :SYSTEM
 :aliases ("CFG" "CONFIG" "OP" "PREFERENCES" "PREFS")
 :intl-name "_OPTIONS"
 :synopsis "Opens the Options (AutoCAD) / Settings (BricsCAD) dialog box to customize program settings."
 :options NIL
 :arguments "No command-line arguments; opens the settings dialog box where program options are viewed and modified."
 :description "Opens a dialog box to customize program settings. Options can be stored with the current drawing or in the registry/profile to affect all drawings in the session."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0504CE1C-7B56-4094-B90B-C8000E680EF9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_options/V25/EN_US")

(:name "OSNAP"
 :category :SYSTEM
 :aliases ("DDESNAP" "DDOSNAP" "OS" "SETESNAP")
 :intl-name "_OSNAP"
 :synopsis "Sets running object snap modes (opens the Drafting Settings / entity snap settings)."
 :options ("ENDpoint" "MIDpoint" "CENter" "GCEnter" "NODe" "QUAdrant"
           "INTersection" "EXTension" "INSertion" "PERpendicular" "TANgent"
           "NEArest" "APParent" "PARallel" "NONe")
 :arguments "OSNAP opens the Drafting Settings dialog (no arguments); the -OSNAP form takes a comma-separated list of object snap mode names, or none/off to disable snapping."
 :description "Sets the running object snap modes. Entered plainly it opens the Object Snap tab of the Drafting Settings dialog; the hyphen form (-OSNAP) prompts for a comma-separated list of snap modes on the command line."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CF5780AD-D1AB-4526-9608-83D7952749E7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_osnap/V25/EN_US")

(:name "OVERKILL"
 :category :MODIFY
 :aliases NIL
 :intl-name "_OVERKILL"
 :synopsis "Removes duplicate or overlapping lines, arcs, and polylines, and combines partially overlapping or contiguous ones."
 :options ("Combine duplicate block definitions")
 :arguments "Select the objects to process; a settings dialog (Delete Duplicate Entities / Delete Duplicate Objects) then controls tolerance and which duplicates are deleted or combined."
 :description "Eliminates duplicate geometry and merges overlapping or contiguous lines, arcs, and polylines. It can also combine duplicate block definitions and clean up zero-length and overlapping polyline segments."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-44B9ECFC-752C-4CC5-9DA3-84DBF3B17CA6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_overkill/V25/EN_US")

(:name "PAGESETUP"
 :category :PLOT
 :aliases NIL
 :intl-name "_PAGESETUP"
 :synopsis "Controls the page layout, plotting device, paper size, and other output settings for each layout."
 :options NIL
 :arguments "No command-line arguments; opens the Page Setup Manager (AutoCAD) or the Drawing Explorer Page Setups (BricsCAD) dialog."
 :description "Manages page setups, collections of plot device and layout settings that determine the appearance and format of final output. Page setups are stored in the drawing and can be applied to other layouts."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F5AFE4EB-9A1D-4938-AE4F-F37FD5587DE3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pagesetup/V25/EN_US")

(:name "PAN"
 :category :VIEW
 :aliases ("P")
 :intl-name "_PAN"
 :synopsis "Shifts the view without changing the viewing direction or magnification (moves the entire drawing within the current viewport)."
 :options NIL
 :arguments "Interactive real-time pan takes no scriptable input (drag with the mouse; Esc/Enter to exit). The command-line form -PAN accepts a base point (or displacement) and a second point defining the pan distance and direction, e.g. (command \"_-PAN\" pt1 pt2). In BricsCAD, PERSPECTIVE must be 0."
 :description "Moves the view in the plane of the screen so a different portion of the drawing is shown at the same magnification. In AutoCAD, real-time panning is done by dragging the cursor; the -PAN variant shifts the view by specifying up to two points. In BricsCAD, hold the left mouse button and drag; right-click for menu options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E7E03AF4-6AEA-405E-8FC4-4C271E6F599A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pan/V25/EN_US")

(:name "PASTEBLOCK"
 :category :EDIT
 :aliases NIL
 :intl-name "_PASTEBLOCK"
 :synopsis "Pastes objects from the Clipboard into the current drawing as a block."
 :options NIL
 :arguments "Specify the insertion point where the clipboard contents are pasted as a single block."
 :description "Inserts objects previously copied with COPYCLIP or COPYBASE into the drawing as a block at a specified insertion point; the new block receives an automatically generated name."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B5717F8B-096E-4880-9C35-745168992DE8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pasteblock/V25/EN_US")

(:name "PASTECLIP"
 :category :EDIT
 :aliases NIL
 :intl-name "_PASTECLIP"
 :synopsis "Pastes objects from the Clipboard into the current drawing."
 :options ("Rotate" "Scale" "Mirror")
 :arguments "Specify the insertion point (with optional Rotate, Scale, or Mirror in BricsCAD) to place the clipboard contents."
 :description "Pastes clipboard contents into the drawing, automatically selecting the format that preserves the most information (ASCII text becomes mtext, spreadsheets become tables, other content becomes OLE objects)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F7A49705-42BC-46AC-922A-862EE6836CCF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pasteclip/V25/EN_US")

(:name "PASTEORIG"
 :category :EDIT
 :aliases NIL
 :intl-name "_PASTEORIG"
 :synopsis "Pastes objects from the Clipboard into a different drawing using the original coordinates."
 :options NIL
 :arguments "No point input; the clipboard contents are placed at their original source coordinates. Operates only when the clipboard holds data from a different drawing."
 :description "Inserts clipboard objects into the active drawing at the coordinates they had in the source drawing. It works only when the clipboard contains CAD data copied from a different drawing than the current one."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7B4B41C4-E9E2-40D5-936F-6BF591E7A2A8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pasteorig/V25/EN_US")

(:name "PASTESPEC"
 :category :EDIT
 :aliases ("PA")
 :intl-name "_PASTESPEC"
 :synopsis "Opens the Paste Special dialog box to paste Clipboard contents and control the data format."
 :options ("Picture Metafile" "Bitmap" "CAD Entities" "CAD Block" "Paste Link"
           "Display As Icon")
 :arguments "Opens the Paste Special dialog to pick a format; when pasting as CAD entities, specify the insertion point (with optional Rotate, Scale, or Mirror). Windows only in BricsCAD."
 :description "Opens the Paste Special dialog box so the user can choose the format for pasting clipboard content (metafile, bitmap, CAD entities, block, or link). In BricsCAD this feature is available on Windows only."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0223840C-D96F-41E9-8D33-1CEFA8D07B3C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pastespec/V25/EN_US")

(:name "PDFADJUST"
 :category :OTHER
 :aliases NIL
 :intl-name "_PDFADJUST"
 :synopsis "Adjusts the fade, contrast, and monochrome settings of a PDF underlay."
 :options ("Fade" "Contrast" "Monochrome")
 :arguments "Select the PDF underlay(s), then set the Fade (0-100), Contrast (0-100), and Monochrome (on/off) values."
 :description "Modifies the graphical display properties (fade, contrast, and monochrome) of one or more PDF underlays. The same settings can also be changed through the Properties panel."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9C576B12-7544-4ED4-942D-95F3C8585366.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pdfadjust/V25/EN_US")

(:name "PDFATTACH"
 :category :OTHER
 :aliases NIL
 :intl-name "_PDFATTACH"
 :synopsis "Attaches a PDF file as an underlay into the current drawing."
 :options NIL
 :arguments "Select the PDF file, then specify page number, insertion point, scale factor, rotation angle, and path type through the attachment dialog."
 :description "Links a referenced PDF file to the current drawing as an underlay. Changes to the referenced file are reflected when the drawing is opened or reloaded, and the underlay can then be adjusted and clipped."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-77D6192C-925B-46A3-8717-240702ED5715.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pdfattach/V25/EN_US")

(:name "PDFCLIP"
 :category :MODIFY
 :aliases NIL
 :intl-name "_PDFCLIP"
 :synopsis "Clips a PDF underlay to a specified clipping boundary."
 :options ("On" "Off" "Delete" "New" "Polygonal" "Rectangular" "Invert")
 :arguments "Select the PDF underlay, then choose a clipping option (On, Off, Delete, or New boundary via a selected polyline, polygonal, or rectangular boundary)."
 :description "Crops the display of a selected PDF underlay to a clipping boundary defined in a plane parallel to the underlay. Clipping can be toggled on or off, inverted, or deleted, with frame visibility controlled by the FRAME system variable."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FA342EAF-0D4D-4DA2-81D7-5DCA8DF552EC.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pdfclip/V25/EN_US")

(:name "PDFIMPORT"
 :category :FILE
 :aliases NIL
 :intl-name "_PDFIMPORT"
 :synopsis "Imports a PDF and converts its geometry, fills, raster images, and text to CAD entities."
 :options ("File" "Specify area" "Polygonal" "All" "Settings" "Keep" "Detach"
           "Unload")
 :arguments "Choose an input file or an attached PDF underlay, specify the area (first/opposite corner, Polygonal, or All), set import Settings, and decide whether to Keep, Detach, or Unload the underlay."
 :description "Converts PDF content into CAD entities such as polylines, splines, mtext, hatches, and raster images. It works from a standalone PDF file through a dialog or from an already-attached PDF underlay, with rectangular, polygonal, or all-area selection."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-02D97F82-47EC-4EE8-9429-E9CF6198EF34.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pdfimport/V25/EN_US")

(:name "PDFLAYERS"
 :category :LAYER
 :aliases NIL
 :intl-name "_PDFLAYERS"
 :synopsis "Controls the display of layers in a PDF underlay."
 :options NIL
 :arguments "Select a PDF underlay; the Underlay Layers dialog box then opens for toggling layer visibility."
 :description "Opens the Underlay Layers dialog box to manage which layers are displayed in a PDF underlay. The related ULAYERS command performs the same function for all underlay types."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3BD29D3C-B645-486F-B88A-E282F3F64A22.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pdflayers/V25/EN_US")

(:name "PEDIT"
 :category :MODIFY
 :aliases ("EDITPLINE" "PE")
 :intl-name "_PEDIT"
 :synopsis "Edits polylines, objects to be joined to polylines, and 3D meshes."
 :options ("Multiple" "Close" "Open" "Join" "Width" "Edit vertex" "Fit"
           "Spline" "Decurve" "Ltype gen" "Reverse" "Taper" "Undo")
 :arguments "Select a polyline (or Multiple objects); if the object is not a polyline, confirm conversion, then choose editing options such as Close, Join, Width, Edit vertex, Fit, Spline, or Decurve."
 :description "Modifies polylines, 3D polylines, and 3D meshes, and converts other 2D objects such as lines and arcs into polylines. Available options vary with the entity being edited."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0C422AA9-23DD-4650-AD66-68E9D7989E3F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pedit/V25/EN_US")

(:name "PFACE"
 :category :|3D|
 :aliases NIL
 :intl-name "_PFACE"
 :synopsis "Creates a 3D polyface mesh, vertex by vertex."
 :options ("Color" "Layer")
 :arguments "Specify each vertex location in turn, press Enter, then define each face by entering its vertex numbers (a negative number makes the following edge invisible); Color and Layer set edge properties."
 :description "Constructs multi-sided polyface meshes by specifying vertices individually and then defining faces from those vertices. It is intended mainly for use within macros, and edge visibility is controlled with negative vertex numbers."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3779DF52-AA24-47D2-B72C-018D4A9011DD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pface/V25/EN_US")

(:name "PLAN"
 :category :VIEW
 :aliases NIL
 :intl-name "_PLAN"
 :synopsis "Displays an orthographic plan view of the XY plane of a specified coordinate system."
 :options ("Current" "UCS" "World")
 :arguments "Enter Current UCS, a named UCS (with a name or ? to list), or World to display the plan view of that coordinate system."
 :description "Generates a top-down orthographic view of the drawing relative to the current UCS, a named UCS, or the World Coordinate System, showing the model looking straight down on the XY plane."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-11883C70-6435-4F80-8FB4-F6E933B8FD94.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_plan/V25/EN_US")

(:name "PLINE"
 :category :DRAW
 :aliases ("PL" "POLYLINE")
 :intl-name "_PLINE"
 :synopsis "Creates a 2D polyline, a single object composed of connected line and arc segments."
 :options ("Arc" "Close" "Halfwidth" "Length" "Undo" "Width")
 :arguments "Supplies a start point, then successive vertex points; keywords switch modes and set attributes: \"A\" (Arc) enters arc-segment mode (with Angle, CEnter, CLose, Direction, Radius, Second pt sub-keywords) and \"L\" returns to Line mode, \"W\" (Width) and \"H\" (Halfwidth) set segment width, \"U\" (Undo) removes the last segment, and \"C\" (Close) closes the polyline. ENTER ends the command."
 :description "Creates a single 2D polyline object made of connected straight and/or arc segments. Segments can have uniform or tapering width, arc mode can be toggled mid-command, and the Close option joins the last vertex to the first. The PLINETYPE system variable controls the type of 2D polyline created."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-11883C70-6435-4F80-8FB4-F6E933B8FD94.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pline/V25/EN_US")

(:name "PLOT"
 :category :PLOT
 :aliases NIL
 :intl-name "_PLOT"
 :synopsis "Plots a drawing to a plotter, printer, or file."
 :options NIL
 :arguments "No command-line arguments; opens the Plot (AutoCAD) / Print (BricsCAD) dialog box to configure and execute plotting."
 :description "Opens a dialog box to configure and execute plotting of the current drawing to any installed output device, print-to-file, or PDF. On macOS/Linux, BricsCAD can only print to PDF."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3F5861A1-9A63-42A6-8F12-3395771BAA6D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_plot/V25/EN_US")

(:name "PLOTSTAMP"
 :category :PLOT
 :aliases NIL
 :intl-name "_PLOTSTAMP"
 :synopsis "Places a plot stamp with information such as date, time, and scale on plotted output."
 :options NIL
 :arguments "No command-line arguments; opens the Plot Stamp dialog box to configure headers, footers, fields, font, and size."
 :description "Opens the Plot Stamp dialog box to add drawing information (date, time, scale, and other fields) to the edge of a plotted drawing and optionally log it to a file. The stamp is rendered with pen/color 7."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C2A21C73-CCA6-42E6-8D7B-D2B429046FB0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_plotstamp/V25/EN_US")

(:name "PLOTSTYLE"
 :category :PLOT
 :aliases NIL
 :intl-name "_PLOTSTYLE"
 :synopsis "Sets the current named plot style attached to the layout and assignable to objects."
 :options ("ByLayer" "ByBlock" "Normal")
 :arguments "In BricsCAD choose ByLayer, ByBlock, or Normal; opens the Current Plot Style dialog (no objects selected) or the Select Plot Style dialog (with objects selected)."
 :description "Controls the named plot styles attached to the current layout for drawings in named plot style mode. The dialog shown depends on whether objects are selected; color-dependent drawings must be converted with CONVERTPSTYLES."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F77C31FE-9266-4293-A251-A8BA1F91D818.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_plotstyle/V25/EN_US")

(:name "PLT2DWG"
 :category :FILE
 :aliases NIL
 :intl-name "_PLT2DWG"
 :synopsis "Imports legacy HPGL plot (PLT) files into the current drawing."
 :options NIL
 :arguments "Specify the PLT file (or enter ~ in AutoCAD to display the file dialog); opens a file-selection dialog in BricsCAD."
 :description "An Express Tool that imports plot output files in the legacy HPGL vector format into the current drawing, retaining colors. HPGL/2 and Draftpro variants are not supported."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2D2ECCF3-1CD4-4115-A823-E4B7EC165A0F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_plt2dwg/V25/EN_US")

(:name "POINT"
 :category :DRAW
 :aliases ("PO")
 :intl-name "_POINT"
 :synopsis "Creates a point object."
 :options ("Multiple" "Settings")
 :arguments "Specify the location of the point; the current elevation is used when Z is omitted. Appearance is governed by PDMODE and PDSIZE."
 :description "Creates one or more point objects that act as nodes for snapping other objects, positioned in 2D or 3D space. Point display style and size are controlled by the PDMODE and PDSIZE system variables."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3F5861A1-9A63-42A6-8F12-3395771BAA6D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_point/V25/EN_US")

(:name "POINTCLOUDATTACH"
 :category :OTHER
 :aliases NIL
 :intl-name "_POINTCLOUDATTACH"
 :synopsis "Attaches a point cloud scan or project file into the current drawing."
 :options ("File" "fOlder")
 :arguments "Select a point cloud file or folder, then specify the data name, insertion point, scale, rotation, and (if needed) coordinate units through the Attach Point Cloud dialog."
 :description "Inserts point cloud data (RCS/RCP in AutoCAD; also E57, LAS, LAZ, PTS, PTX and others in BricsCAD) into the drawing. Files are preprocessed into a cache, and insertion options are set through a dialog."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E086391C-6CEA-4B70-A788-7630FD75469F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pointcloudattach/V25/EN_US")

(:name "POINTCLOUDCOLORMAP"
 :category :OTHER
 :aliases NIL
 :intl-name "_POINTCLOUDCOLORMAP"
 :synopsis "Colorizes a point cloud and defines its color-map stylization settings."
 :options ("Intensity" "Elevation" "Classification" "Scan" "Object" "Normals"
           "X-Ray")
 :arguments "In AutoCAD, opens the Point Cloud Color Map dialog (no arguments); in BricsCAD, choose a stylization type and color scheme via the context panel or command line."
 :description "Colorizes a point cloud based on a chosen stylization (intensity, elevation, classification, scan data, object color, normals, or X-Ray) using predefined or custom color schemes."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8EB71740-97AD-415F-AAC7-F6D8006CDFC9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pointcloudcolormap/V25/EN_US")

(:name "POINTCLOUDCROP"
 :category :MODIFY
 :aliases NIL
 :intl-name "_POINTCLOUDCROP"
 :synopsis "Creates a crop boundary on a point cloud to restrict displayed points."
 :options ("Rectangular" "Circular" "Polygonal" "Invert" "Inside" "Outside")
 :arguments "Select the point cloud (if more than one), choose a boundary type (Rectangular, Circular, or Polygonal), specify the boundary, and set inside/outside or invert."
 :description "Establishes a crop boundary on an attached point cloud so only points in a specific area are shown. Boundaries are stored relative to the point cloud and transform with it, and multiple crops can be applied."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BDD08C89-13C3-4AD4-B3F9-D73965DDA28E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pointcloudcrop/V25/EN_US")

(:name "POINTLIGHT"
 :category :RENDER
 :aliases NIL
 :intl-name "_POINTLIGHT"
 :synopsis "Creates a point light that radiates in all directions from its location."
 :options ("Name" "Intensity factor" "Status" "Photometry" "shadoW"
           "Attenuation" "filterColor" "Color")
 :arguments "Specify the source location, then optionally set Name, Intensity, Status, Photometry, Shadow, Attenuation, and Filter Color before ending the command."
 :description "Places point lights for renderings that illuminate in all directions like a bare bulb, with no target. Multiple point lights are allowed, and since AutoCAD 2016-based products standard lights are photometric."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C685641B-3565-40CC-AAC5-E0578EF9F814.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pointlight/V25/EN_US")

(:name "POLYGON"
 :category :DRAW
 :aliases ("POL")
 :intl-name "_POLYGON"
 :synopsis "Creates an equilateral closed polyline in the shape of a polygon."
 :options ("Edge" "Inscribed" "Circumscribed")
 :arguments "Enter the number of sides (3-1024), then specify the center and choose Inscribed or Circumscribed with a radius, or use Edge to define the polygon by the endpoints of one edge."
 :description "Creates a closed polyline with equal sides. The polygon can be defined by center and radius (inscribed in or circumscribed about a circle) or by the endpoints of one edge."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E5CD464D-C0DC-4464-BFDF-50C4ABEC8B91.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_polygon/V25/EN_US")

(:name "POLYSOLID"
 :category :|3D|
 :aliases ("PSO")
 :intl-name "_POLYSOLID"
 :synopsis "Creates a 3D solid in the shape of a wide, extruded polyline (wall)."
 :options ("Object" "Height" "Width" "Justify" "Arc" "Close" "Undo")
 :arguments "Specify a start point and successive vertices (or select an existing 2D Object as the path), setting Height, Width, and Justify as needed, ending with Enter or Close."
 :description "Creates 3D solid walls with constant height and width from line and arc segments, similar to drawing a polyline. Existing lines, polylines, arcs, and circles can be converted; PSOLWIDTH and PSOLHEIGHT set defaults."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-22AE6A38-3404-4BF4-88C2-42CE3822ACD8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_polysolid/V25/EN_US")

(:name "PREVIEW"
 :category :PLOT
 :aliases ("PRE")
 :intl-name "_PREVIEW"
 :synopsis "Displays the drawing as it will be plotted."
 :options NIL
 :arguments "No command-line arguments; opens the plot preview window with pan, zoom, and print controls."
 :description "Shows how the drawing will appear when plotted based on the current plot configuration, reflecting lineweights, fill patterns, and plot styles. A None printer must not be active."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C66B4986-DEB5-46DE-817A-1D5990FC61DA.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_preview/V25/EN_US")

(:name "PROJECTGEOMETRY"
 :category :|3D|
 :aliases NIL
 :intl-name "_PROJECTGEOMETRY"
 :synopsis "Projects points, lines, or curves onto a 3D solid or surface to create edges."
 :options ("View" "UCS" "Points")
 :arguments "Select the geometry to project and the receiving solid/surface; set the projection direction (View, UCS, or a vector defined by Points)."
 :description "Projects 2D geometry (points, lines, arcs, circles, splines, helixes) onto regions, surfaces, or 3D solids to create additional edge line work. The projection direction can follow the view, the UCS Z axis, or a two-point vector."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F884BC67-070F-4BAD-87EF-A8A77E23FB93.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_projectgeometry/V25/EN_US")

(:name "PROPERTIES"
 :category :MODIFY
 :aliases ("CH" "DDCHPROP" "DDMODIFY" "MO" "PR" "PROPS")
 :intl-name "_PROPERTIES"
 :synopsis "Opens the Properties palette/panel to control properties of existing objects."
 :options NIL
 :arguments "No command-line arguments; opens the Properties palette (AutoCAD) or Properties panel (BricsCAD)."
 :description "Displays the Properties palette showing the properties of selected objects; when several are selected only common properties appear, and with none selected the current general settings are shown."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DC3674C5-A4C7-4CF6-9148-9B124DF29B78.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_properties/V25/EN_US")

(:name "PROPERTIESCLOSE"
 :category :OTHER
 :aliases ("PRC")
 :intl-name "_PROPERTIESCLOSE"
 :synopsis "Closes the Properties palette/panel."
 :options NIL
 :arguments "No command-line arguments; hides the Properties palette (AutoCAD) or panel (BricsCAD)."
 :description "Closes the Properties palette. In AutoCAD the palette can alternatively auto-hide; in BricsCAD, if the panel is stacked its tab or icon is removed from the stack."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6F265AEA-496D-43B6-8643-D1528E8AF0E6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_propertiesclose/V25/EN_US")

(:name "PROPULATE"
 :category :FILE
 :aliases NIL
 :intl-name "_PROPULATE"
 :synopsis "Lists, removes, or updates drawing properties data using templates."
 :options ("Active template" "Edit template" "List" "Remove" "Update"
           "Current drawing" "Other drawings")
 :arguments "Choose an option: set the Active template, Edit a template, List properties (current or other drawings, optionally searching subdirectories), Remove, or Update properties."
 :description "An Express Tool that manages drawing properties data across single drawings or folders using templates. It can extract attribute values from title blocks and generate lists of attached xrefs, images, and fonts."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BD03320F-3430-4C2F-80A3-AAC1167AF019.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_propulate/V25/EN_US")

(:name "PSBSCALE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_PSBSCALE"
 :synopsis "Sets or updates the scale of block references relative to paper space."
 :options ("Set" "Update" "XYZ")
 :arguments "Choose Set or Update, then specify the block display size in paper space units (or XYZ scale factors)."
 :description "An Express Tool that specifies the paper space display size of blocks inserted in model space. The Update option readjusts previously scaled blocks when viewport zoom factors change."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-20C3AD1E-34CC-471C-9842-2C8A3F622907.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_psbscale/V25/EN_US")

(:name "PSPACE"
 :category :VIEW
 :aliases ("PS")
 :intl-name "_PSPACE"
 :synopsis "Switches from model space in a layout viewport to paper space."
 :options NIL
 :arguments "No command-line arguments; switches the current layout tab from model space (inside a viewport) back to paper space."
 :description "Returns from model space within a layout viewport to paper space so title blocks, viewports, text, and dimensions can be created and edited. It works only in a layout tab currently in paper space mode."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-38E17265-2CF0-4A9F-8DF5-BC6A317C3683.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pspace/V25/EN_US")

(:name "PSTSCALE"
 :category :TEXT
 :aliases NIL
 :intl-name "_PSTSCALE"
 :synopsis "Sets or updates the scale of text entities relative to paper space."
 :options ("Set" "Update")
 :arguments "Choose Set or Update, then specify the paper space height for the selected single-line and multiline text entities."
 :description "An Express Tool that sets or updates the paper space height of single-line and multiline text from within a model space layout viewport. The Update option adjusts previously scaled text when viewport scale factors change."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D68BA47B-A79D-4F58-9715-0569CC24BCEF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pstscale/V25/EN_US")

(:name "PUBLISH"
 :category :PLOT
 :aliases NIL
 :intl-name "_PUBLISH"
 :synopsis "Publishes/batch-prints a set of drawings, layouts, and sheets to devices or files."
 :options NIL
 :arguments "No command-line arguments; opens the Publish dialog box to assemble drawings/layouts and send them to a printer or export as DWF, DWFx, or PDF."
 :description "Assembles multiple drawings, layouts, and sheets into a set and outputs them to printers/plotters or to DWF, DWFx, and PDF files, useful for batch printing books of drawings. A DSD file can drive the set."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EE9F55FF-D253-4AEC-B95B-69DA4EBE90E8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_publish/V25/EN_US")

(:name "PURGE"
 :category :FILE
 :aliases ("PU")
 :intl-name "_PURGE"
 :synopsis "Removes unused named items, such as block definitions and layers, from the drawing."
 :options NIL
 :arguments "No command-line arguments; opens the Purge dialog box to select unused named objects (and zero-length geometry, empty text, orphaned data) to remove. The -PURGE form runs on the command line."
 :description "Removes unreferenced named objects such as blocks, dimension styles, groups, layers, linetypes, and text styles, plus zero-length geometry, empty text, and orphaned DGN linestyle data. Nested items can be purged in one pass."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7385C843-BA65-4E9D-9FF6-61753E539416.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_purge/V25/EN_US")

(:name "PYRAMID"
 :category :|3D|
 :aliases ("PYR")
 :intl-name "_PYRAMID"
 :synopsis "Creates a 3D solid in the shape of a pyramid."
 :options ("Edge" "Sides" "Inscribed" "Circumscribed" "2Point" "Axis endpoint"
           "Top radius")
 :arguments "Specify the base center point (or Edge to define by an edge), optionally set Sides, give the base radius (Inscribed or Circumscribed) or edge length, optionally a Top radius for a frustum, then the height (a value, Axis endpoint, or 2Point)."
 :description "Generates a three-dimensional pyramid solid defined by a base center point, an edge point, and a height. Supports multiple sides, inscribed or circumscribed base orientation, and a truncated pyramid (frustum) via a top radius."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DA8A78E3-5954-415A-B279-E1C69F465D87.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pyramid/V25/EN_US")

(:name "QCCLOSE"
 :category :OTHER
 :aliases NIL
 :intl-name "_QCCLOSE"
 :synopsis "Closes the QuickCalc calculator."
 :options NIL
 :arguments "Takes no arguments; invoked simply as (command \"QCCLOSE\")."
 :description "Terminates and hides the QuickCalc calculator panel from the current workspace. When the panel is part of a stacked group, closing it removes its tab or icon from that stack."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B8DF860D-98B6-44A8-9864-375FF028EB86.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qcclose/V25/EN_US")

(:name "QDIM"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_QDIM"
 :synopsis "Quickly creates a series of dimensions from selected objects."
 :options ("Continuous" "Staggered" "Baseline" "Ordinate" "Radius" "Diameter"
           "datumPoint" "Edit" "seTtings")
 :arguments "Select the geometry to dimension, specify the dimension line position, then choose a dimensioning mode (Continuous, Staggered, Baseline, Ordinate, Radius, or Diameter)."
 :description "Rapidly generates multiple dimensions from selected geometry, useful for baseline, continued, staggered, ordinate, and radial dimensions. The user selects the objects and specifies where the dimension lines appear."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1FB628B7-C2AF-4B6D-B83E-20ADDD70614D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qdim/V25/EN_US")

(:name "QLATTACHSET"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_QLATTACHSET"
 :synopsis "Globally attaches leader lines to mtext, tolerance, or block reference objects."
 :options NIL
 :arguments "Select the leader entities and the annotation objects to associate together."
 :description "An Express Tool that connects leader entities to their corresponding annotations (mtext, tolerance, or block references). In AutoCAD it is an obsolete tool superseded by the multileader commands; BricsCAD reports the count of attached leaders and annotations."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-50B5F962-00A6-4D84-A472-A397A801B5BE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qlattachset/V25/EN_US")

(:name "QLDETACHSET"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_QLDETACHSET"
 :synopsis "Detaches leader lines from mtext, tolerance, or block reference objects."
 :options NIL
 :arguments "Select the leader entities to disassociate from their annotations."
 :description "An Express Tool that removes the association between leader entities and their linked annotations. In AutoCAD it is an obsolete tool superseded by the multileader commands; BricsCAD reports the count of detached leaders and annotations."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E33A1FCA-3B6D-4FD5-BE6E-FBB0BD7A6A26.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qldetachset/V25/EN_US")

(:name "QLEADER"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_QLEADER"
 :synopsis "Creates a leader and leader annotation."
 :options ("Settings" "Width" "Tolerance" "Block")
 :arguments "Specify the first leader point, then the next point(s) and the to point, then supply the annotation (text, a tolerance, or a block); enter Settings to open the QLeader settings dialog."
 :description "Creates leader objects with associated annotations, configurable through a settings dialog. MLEADER is recommended for most cases, but QLEADER allows control of annotation format, text attachment, leader segment limits, and angle constraints."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5FEC133A-5EBD-4EFA-9E44-771E85480DAD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qleader/V25/EN_US")

(:name "QNEW"
 :category :FILE
 :aliases NIL
 :intl-name "_QNEW"
 :synopsis "Starts a new drawing from the default drawing template file."
 :options NIL
 :arguments "Supplies no arguments: (command \"_QNEW\") starts a new drawing using the configured default template. If no default template is set (template = None / unspecified) and FILEDIA is on, AutoCAD presents the Select Template File dialog; behavior also depends on the STARTUP and FILEDIA system variables."
 :description "Opens a new drawing/document tab based on the default template file and current user profile settings (\"quick new\"). In AutoCAD the default template is the one set for QNEW in Options; if unset, a template-selection dialog appears. In BricsCAD it opens a new document with the default template and profile settings."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CF3C039B-CF22-4933-928A-93A3AA71C4FA.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qnew/V25/EN_US")

(:name "QSAVE"
 :category :FILE
 :aliases NIL
 :intl-name "_QSAVE"
 :synopsis "Saves the current drawing immediately using the default file format."
 :options NIL
 :arguments "No arguments when the drawing already has a name (saves immediately with no prompts). If the drawing is unnamed or opened read-only, the Save Drawing As dialog appears and a file name must be supplied."
 :description "Quick-saves the current drawing without prompting when it has already been named; otherwise the Save Drawing As dialog is displayed. In AutoCAD the save may be incremental or full depending on ISAVEPERCENT (format conversion forces a full save). Behavior is equivalent in BricsCAD (\"quick save\")."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-99900C99-230D-4709-B8DD-A44435328A13.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qsave/V25/EN_US")

(:name "QSELECT"
 :category :SELECTION
 :aliases NIL
 :intl-name "_QSELECT"
 :synopsis "Creates a selection set based on filtering criteria."
 :options NIL
 :arguments "Opens the Quick Select dialog (Properties panel in Quick Select mode); no command-line arguments are supplied."
 :description "Builds a selection set by filtering objects according to type and properties (for example, all multiline text objects using a specified text style). In BricsCAD it opens the Properties panel in Quick Select mode; in AutoCAD it opens the Quick Select dialog box."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-40893D34-ADBE-406A-8993-9035F2771F1D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qselect/V25/EN_US")

(:name "QTEXT"
 :category :TEXT
 :aliases ("QT")
 :intl-name "_QTEXT"
 :synopsis "Toggles quick-text display of text as bounding boxes (QTEXTMODE)."
 :options ("On" "Off" "Toggle")
 :arguments "Enter On, Off, or Toggle to set QTEXTMODE, then use REGEN or REGENALL to update the display."
 :description "Controls the display and plotting of text and attribute objects, showing them as rectangular bounding boxes rather than rendered text to speed up regeneration. Changes take effect after a REGEN or REGENALL."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DFBE6C48-893B-4CE1-9B28-0656FABFAAB7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qtext/V25/EN_US")

(:name "QUICKCALC"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_QUICKCALC"
 :synopsis "Opens the QuickCalc calculator panel."
 :options NIL
 :arguments "No command-line arguments; opens the QuickCalc calculator panel."
 :description "Opens a dockable calculator that performs mathematical, scientific, and geometric calculations, supports variables and unit conversion, and can be used standalone or inside commands and the Properties palette."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0797E82E-FE80-43D6-8464-398725546A2A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_quickcalc/V25/EN_US")

(:name "QUIT"
 :category :FILE
 :aliases ("EXIT")
 :intl-name "_QUIT"
 :synopsis "Closes all open drawings and exits the program."
 :options NIL
 :arguments "No command-line arguments; exits the program, prompting to save any drawings with unsaved changes."
 :description "Terminates the application after closing all open drawings, prompting to save or discard unsaved changes. For read-only files, SAVEAS with a new name should be used to keep changes."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EEBB22C5-8F6F-495D-80B1-50D991D010FB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_quit/V25/EN_US")

(:name "RAY"
 :category :DRAW
 :aliases NIL
 :intl-name "_RAY"
 :synopsis "Creates a linear object that starts at a point and continues infinitely in one direction."
 :options ("Horizontal" "Vertical" "Angle" "Bisect" "Parallel")
 :arguments "Specify the start point and a through point to define the ray's direction; continue placing rays and press Enter to end. BricsCAD adds Horizontal, Vertical, Angle, Bisect, and Parallel construction options."
 :description "Creates a ray (a semi-infinite line) extending from a start point through a second point to infinity in one direction. Multiple rays can be created in sequence, and BricsCAD offers extra construction methods."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A7A32623-24A4-453C-B3DD-877A6E4D6216.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_ray/V25/EN_US")

(:name "RECOVER"
 :category :FILE
 :aliases NIL
 :intl-name "_RECOVER"
 :synopsis "Repairs and then opens a damaged drawing file."
 :options NIL
 :arguments "Select a damaged DWG, DWT, DWS, or DXF file through the file dialog (or enter ~ when FILEDIA is 0) to recover it."
 :description "Extracts recoverable data from a damaged drawing file (DWG/DWT/DWS) and opens it, with results shown in the text window. For DXF files it simply opens the file without repair."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-78F5B1AB-583F-410F-85DA-6D03768832C8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_recover/V25/EN_US")

(:name "RECOVERALL"
 :category :FILE
 :aliases NIL
 :intl-name "_RECOVERALL"
 :synopsis "Repairs a damaged drawing file along with all attached xrefs."
 :options NIL
 :arguments "Select a damaged DWG, DWT, DWS, or DXF file (or enter ~ when FILEDIA is 0); the file and all nested xrefs are recovered."
 :description "Recovers or audits a drawing and all of its nested external references, opening, repairing, resaving, and closing each. Results appear in a Drawing Recovery Log window, and BAK backups are created."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3925BB47-5AB2-4BDB-A5D7-54CF8008B18C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_recoverall/V25/EN_US")

(:name "RECTANG"
 :category :DRAW
 :aliases ("REC" "RECT" "RECTANGLE")
 :intl-name "_RECTANG"
 :synopsis "Creates a closed rectangular polyline."
 :options ("Chamfer" "Elevation" "Fillet" "Thickness" "Width" "Area"
           "Dimensions" "Rotation")
 :arguments "Optionally supplies a keyword (Chamfer/Fillet/Elevation/Thickness/Width/Area/Dimensions/Rotation) to set properties, then the first corner point and the opposite corner point; e.g. (command \"_RECTANG\" p1 p2)."
 :description "Creates a closed four-sided rectangular polyline defined by two diagonal corner points, or by area plus a length/width, with optional chamfered or filleted corners, rotation, elevation, thickness, and line width. BricsCAD lists five construction methods for the rectangle."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-188B2DDA-6CD8-4D37-BF26-E6CF27C34C75.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_rectang/V25/EN_US")

(:name "REDEFINE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_REDEFINE"
 :synopsis "Restores internal commands that were overridden by the UNDEFINE command."
 :options NIL
 :arguments "Enter the name of a previously undefined command to reactivate it."
 :description "Reverses the effect of UNDEFINE, restoring access to a built-in command through its normal name. Even while a command is undefined, it can still be invoked by prefixing its name with a period."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E2B53E4D-28AE-4F6E-96E4-6FABE3FF823C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_redefine/V25/EN_US")

(:name "REDIR"
 :category :FILE
 :aliases NIL
 :intl-name "_REDIR"
 :synopsis "Redefines hard-coded paths in xrefs, images, shapes, styles, and rtext."
 :options ("options" "*" "?")
 :arguments "Supplies the old directory to find (or * for all paths), then the new directory to substitute; object types acted on are set by REDIRMODE."
 :description "An Express Tool that acts as a find-and-replace utility for directory names embedded in external references, images, shapes, styles and rtext objects. Paths can be redefined across object types or stripped entirely so files are found through the support search path."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DA60459B-378F-4A27-BD1F-6290ACA7083D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_redir/V25/EN_US")

(:name "REDIRMODE"
 :category :FILE
 :aliases NIL
 :intl-name "_REDIRMODE"
 :synopsis "Sets the object types that REDIR finds and replaces directories for."
 :options ("x" "s" "i" "r" "*")
 :arguments "Supplies the object types to include when REDIR runs (xrefs, styles, images, rtext), entered as abbreviations separated by commas, or * for all; -REDIRMODE runs it at the command line instead of the dialog."
 :description "An Express Tool that configures which object types the REDIR command acts upon when redefining hard-coded paths. At least one object type must be selected; REDIRMODE opens a settings dialog while -REDIRMODE prompts on the command line."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0E4D49B7-E701-428D-A279-A32797C2811C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_redirmode/V25/EN_US")

(:name "REDO"
 :category :EDIT
 :aliases NIL
 :intl-name "_REDO"
 :synopsis "Reverses the effects of the previous U or UNDO command."
 :options NIL
 :arguments "Takes no input; must be entered immediately after a U or UNDO command."
 :description "Restores entities to the state they were in before the most recent undo operation. It works only when executed immediately after a U or UNDO command and displays no prompts or options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BA4CEE11-D8AD-4644-8488-7CEBCA50AFFE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_redo/V25/EN_US")

(:name "REDRAW"
 :category :VIEW
 :aliases ("R")
 :intl-name "_REDRAW"
 :synopsis "Refreshes the display in the current viewport."
 :options NIL
 :arguments "Takes no input; refreshes the current viewport."
 :description "Redraws the current viewport, removing temporary graphics such as blip marks or drag marks left by prior operations. It displays no prompts and has no options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6AD77E11-D549-47E7-AE4C-EFE372A0F0C4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_redraw/V25/EN_US")

(:name "REDRAWALL"
 :category :VIEW
 :aliases ("RA")
 :intl-name "_REDRAWALL"
 :synopsis "Refreshes the display in all viewports."
 :options NIL
 :arguments "Takes no input; refreshes every viewport."
 :description "Redraws entities across all viewports, removing temporary graphics such as blip or drag marks. It displays no prompts and has no options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8CCABD96-4B68-4678-8E69-0335928DAEF9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_redrawall/V25/EN_US")

(:name "REFCLOSE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_REFCLOSE"
 :synopsis "Saves back or discards changes made during in-place editing of a reference."
 :options ("Save" "Discard")
 :arguments "Supplies the Save or Discard keyword to end an in-place reference-editing session started by REFEDIT."
 :description "Finalizes an in-place editing session on an xref or block definition. Save writes the working-set changes back to the source drawing or block definition; Discard abandons the working set and returns the reference to its original state."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F75E70EF-31EB-4F69-9FB9-9BBA1EC41EEF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_refclose/V25/EN_US")

(:name "REFEDIT"
 :category :BLOCK
 :aliases NIL
 :intl-name "_REFEDIT"
 :synopsis "Edits an xref or a block definition directly within the current drawing."
 :options ("OK" "Next" "All" "Nested")
 :arguments "Supplies the block reference or xref to edit and the nested objects that form the working set; the session is ended with REFCLOSE."
 :description "Allows in-place editing of a selected block reference or external reference without opening the reference file separately. The selected working set appears distinct while other objects are faded, and only one reference can be edited at a time."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C2F74110-2DA4-46DA-99EB-E89CF32D30B9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_refedit/V25/EN_US")

(:name "REFSET"
 :category :BLOCK
 :aliases NIL
 :intl-name "_REFSET"
 :synopsis "Adds or removes objects from the working set during in-place editing of a reference."
 :options ("Add" "Remove")
 :arguments "Supplies the Add or Remove keyword and then the objects to transfer between the working set and the host drawing; works only after REFEDIT."
 :description "Manages which objects belong to the working set during an in-place reference edit. Objects added become part of the reference on save, while removed objects are deleted from both the reference and the current drawing."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B441D1B3-A1F6-49F7-A43F-B74DB39FAAA2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_refset/V25/EN_US")

(:name "REGEN"
 :category :VIEW
 :aliases ("RE")
 :intl-name "_REGEN"
 :synopsis "Regenerates the drawing from within the current viewport."
 :options NIL
 :arguments "No input arguments; (command \"_REGEN\") regenerates the current viewport and returns immediately with no prompts or options."
 :description "Recomputes the locations and visibility of all objects in the current viewport, reindexes the drawing database for optimum display and object-selection performance, and resets the area available for realtime panning and zooming. AutoCAD and BricsCAD describe identical behavior."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CC98095F-B4C4-4B25-9097-A7B6EF4260B2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_regen/V25/EN_US")

(:name "REGENALL"
 :category :VIEW
 :aliases ("REA")
 :intl-name "_REGENALL"
 :synopsis "Regenerates the entire drawing and refreshes all viewports."
 :options NIL
 :arguments "Takes no input; regenerates every viewport."
 :description "Recomputes entity locations and visibility across all viewports, reindexes the drawing database, and resets the zoom and pan area in each viewport. It displays no prompts and has no options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-27B2FFB6-BC98-43F2-AE8B-332E9C547CA9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_regenall/V25/EN_US")

(:name "REGENAUTO"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_REGENAUTO"
 :synopsis "Controls automatic regeneration of the drawing (toggles the REGENMODE system variable)."
 :options ("On" "Off" "Toggle")
 :arguments "Supplies On, Off, or Toggle to set automatic regeneration; can be entered transparently."
 :description "In BricsCAD this toggles the REGENMODE system variable that controls whether the display regenerates automatically when needed, and can be invoked transparently. On the AutoCAD page the command is described as obsolete and no longer functional."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A91310A5-C3D2-43DB-9D4E-0BCE7C138FA2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_regenauto/V25/EN_US")

(:name "REGION"
 :category :DRAW
 :aliases ("REG")
 :intl-name "_REGION"
 :synopsis "Converts closed objects or loops that enclose an area into 2D region objects."
 :options NIL
 :arguments "Supplies the closed entities or sets of entities that enclose a space, then an empty response to end selection; each closed loop becomes one region."
 :description "Creates 2D region objects from closed entities or sets of entities that enclose a space, such as polylines, lines, arcs, circles, ellipses, and splines. Each closed loop produces one region, and the DELOBJ system variable controls whether the source geometry is deleted."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-ADD055CD-D351-424C-91F0-B8E5526B106C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_region/V25/EN_US")

(:name "REINIT"
 :category :SYSTEM
 :aliases ("RI")
 :intl-name "_REINIT"
 :synopsis "Reinitializes the digitizer, I/O port, and reloads the program parameters (PGP/alias) file."
 :options NIL
 :arguments "Takes no command input; a dialog box confirms reinitialization or reload."
 :description "In BricsCAD, reloads the alias (PGP) file after it has been edited externally, confirming via a dialog box. On the AutoCAD page it reinitializes the digitizer, the digitizer I/O port, and the program parameters file through a re-initialization dialog."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F68C58E5-9C43-447B-85F0-3918CC346DA0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_reinit/V25/EN_US")

(:name "RENAME"
 :category :EDIT
 :aliases ("DDRENAME" "REN")
 :intl-name "_RENAME"
 :synopsis "Changes the names assigned to named objects such as layers, styles, and blocks."
 :options NIL
 :arguments "Opens a dialog with no command-line input; use -RENAME to supply the object type, old name, and new name at the prompt."
 :description "Renames named objects (layers, dimension styles, table styles, text styles, and similar) through a dialog box. Certain items cannot be renamed, and the command-line variant -RENAME prompts for the type, old name, and new name instead of showing the dialog."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-99C5072C-C71E-4BF7-9B3B-69B3BEA07940.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_rename/V25/EN_US")

(:name "RENDERPRESETS"
 :category :RENDER
 :aliases ("ROPTIONS")
 :intl-name "_RENDERPRESETS"
 :synopsis "Creates, edits, and manages reusable render presets for rendering an image."
 :options ("Materials" "Shadows" "Ray Tracing" "Max Depth" "Max Reflections"
           "Max Refractions" "Processing" "Tile Size" "Tile Order")
 :arguments "Opens a dialog/palette with no command-line input; render preset parameters are set interactively."
 :description "Manages named collections of rendering parameters (render presets) used to produce rendered images. BricsCAD opens the Drawing Explorer on the RenderPresets category, while AutoCAD opens the Render Presets Manager palette."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A50FEF2A-0FEA-4207-B091-76BEBDED397D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_renderpresets/V25/EN_US")

(:name "REPURLS"
 :category :EDIT
 :aliases NIL
 :intl-name "_REPURLS"
 :synopsis "Finds and replaces a text string in URLs of hyperlinks attached to selected objects."
 :options NIL
 :arguments "Supplies the entities whose hyperlinks are searched, then the find and replace strings via the Replace URL dialog."
 :description "An Express Tool that replaces a specified text string in the URLs of hyperlinks attached to selected objects, supporting both complete and partial URL substitutions. After selecting entities, a dialog box handles the find-and-replace operation."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0F9B7467-74F3-4884-8DFA-747F0D6952E2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_repurls/V25/EN_US")

(:name "RESETBLOCK"
 :category :BLOCK
 :aliases NIL
 :intl-name "_RESETBLOCK"
 :synopsis "Resets one or more block references to the default values of the block definition."
 :options NIL
 :arguments "Supplies the block references to reset to their default state."
 :description "Restores selected block references that have been modified back to the default values of their block definition. BricsCAD describes this for parametric blocks and AutoCAD for dynamic block references."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3845BE0A-3F39-4D63-956E-0BAD7D195516.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_resetblock/V25/EN_US")

(:name "RESUME"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_RESUME"
 :synopsis "Continues a script that has been interrupted."
 :options NIL
 :arguments "Takes no input; resumes a suspended script."
 :description "Resumes execution of a macro script that was suspended by pressing Esc (or Backspace) or that paused on an input error, continuing it without restarting from the beginning."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-448BF284-F801-485F-BF76-E8888A9359FE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_resume/V25/EN_US")

(:name "REVCLOUD"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_REVCLOUD"
 :synopsis "Creates or modifies a polyline in the shape of a revision cloud."
 :options ("Arc length" "Object" "Entity" "Rectangular" "Polygonal" "Freehand"
           "Style" "Modify" "Reverse" "Undo")
 :arguments "Supplies option keywords and the points, dragged path, or object that define the revision cloud."
 :description "Creates a closed polyline shaped like a revision cloud to highlight areas of a drawing under review, or converts an existing object into one. Clouds can be drawn rectangular, polygonal, or freehand, with selectable arc length and Normal or Calligraphy style."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7BC6D4B1-5279-4B5F-90E0-AC87DA861E78.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_revcloud/V25/EN_US")

(:name "REVERT"
 :category :FILE
 :aliases NIL
 :intl-name "_REVERT"
 :synopsis "Closes the current drawing without saving and reopens it."
 :options NIL
 :arguments "Takes no input; prompts to confirm discarding unsaved changes if any exist."
 :description "An Express Tool that closes the active drawing and immediately reopens it, discarding any unsaved changes. If modifications are pending, it prompts the user to confirm before proceeding."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0F2A37BE-752F-4812-825D-FAF595192B7A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_revert/V25/EN_US")

(:name "REVOLVE"
 :category :|3D|
 :aliases ("REV")
 :intl-name "_REVOLVE"
 :synopsis "Creates a 3D solid or surface by revolving objects about an axis."
 :options ("MOde" "Axis start point" "Axis endpoint" "Object" "X" "Y" "Z"
           "2Points" "Start angle" "Angle of revolution" "Reverse" "Expression")
 :arguments "Supplies the profiles to revolve, the axis (by points or X/Y/Z or an object), an optional start angle, and the angle of revolution."
 :description "Revolves open or closed 2D entities, solid edges, faces, regions, or closed boundaries about an axis to create 3D solids or surfaces. Open profiles produce surfaces while closed profiles can produce a solid or a surface."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6FF936FD-99BA-432A-A43B-4573FD924AF3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_revolve/V25/EN_US")

(:name "REVSURF"
 :category :|3D|
 :aliases NIL
 :intl-name "_REVSURF"
 :synopsis "Creates a 3D mesh surface by revolving a profile curve about an axis."
 :options ("Start angle" "Included angle")
 :arguments "Supplies the path curve to revolve, the object defining the axis of revolution, the start angle, and the included angle."
 :description "Creates a polygon mesh surface by revolving a path curve (line, arc, circle, polyline, or spline) around an axis defined by a line or polyline. Mesh density is governed by the SURFTAB1 and SURFTAB2 system variables, and a start angle and included angle control the rotation extent."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-669D3ECF-99C7-4109-830D-A9D095A46F25.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_revsurf/V25/EN_US")

(:name "RIBBON"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_RIBBON"
 :synopsis "Displays (opens) the ribbon."
 :options NIL
 :arguments "Takes no input; opens the ribbon."
 :description "Makes the ribbon visible, restoring it to its previous size and location. The ribbon organizes tools into logical groupings and, like other dockable panels, can float, dock, or stack."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EC71B17B-1C58-4060-9EAA-528B93851022.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_ribbon/V25/EN_US")

(:name "RIBBONCLOSE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_RIBBONCLOSE"
 :synopsis "Hides (closes) the ribbon."
 :options NIL
 :arguments "Takes no input; closes the ribbon."
 :description "Hides the ribbon from the current workspace. If the ribbon is stacked when closed, its tab or icon is removed from the stack."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A9EE8263-2DCD-4EC5-9CEB-DCB66EEFBE2E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_ribbonclose/V25/EN_US")

(:name "ROTATE"
 :category :MODIFY
 :aliases ("RO")
 :intl-name "_ROTATE"
 :synopsis "Rotates objects around a base point."
 :options ("Copy" "Reference")
 :arguments "Selection set of entities, then a base point, then a rotation angle. Instead of an angle, the keyword \"Copy\" makes a rotated duplicate, or \"Reference\" specifies a reference angle followed by the new absolute angle. Positive angles rotate counterclockwise, negative clockwise."
 :description "Rotates selected entities about a specified base point to an absolute angle; the rotation axis passes through the base point parallel to the Z axis of the current UCS. Positive values rotate counterclockwise, negative values clockwise, measured from the positive x-axis at 0 degrees."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1C265537-FBAC-48D5-B448-B72E777071E5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_rotate/V25/EN_US")

(:name "ROTATE3D"
 :category :|3D|
 :aliases ("3R")
 :intl-name "_ROTATE3D"
 :synopsis "Rotates entities around an axis in 3D space."
 :options ("Object" "Last" "View" "Xaxis" "Yaxis" "Zaxis" "2Points"
           "Rotation angle" "Reference" "Copy")
 :arguments "Supplies the objects to rotate, the axis (by object, X/Y/Z, view, or two points), and the rotation angle (or a reference angle)."
 :description "Rotates 3D solids, surfaces, 2D entities, faces, or vertices around an axis in 3D space. The axis can be defined by an existing object, a coordinate axis, the current view, or two points, and rotating a solid's face adjusts adjacent faces and edges to maintain topology."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BEA9136E-DE85-4EBD-BC8B-F2911B29A026.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_rotate3d/V25/EN_US")

(:name "RSCRIPT"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_RSCRIPT"
 :synopsis "Reruns the most recently loaded script (SCR) file."
 :options NIL
 :arguments "Takes no input; reruns the last script and can be entered transparently as 'rscript."
 :description "Repeats the currently loaded script file after it has been run once, useful for demonstrations that must loop continuously until Esc is pressed. It is typically placed as the last line of a script and can be entered transparently."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2C697967-C51E-4615-A670-294C2397949F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_rscript/V25/EN_US")

(:name "RTEDIT"
 :category :TEXT
 :aliases NIL
 :intl-name "_RTEDIT"
 :synopsis "Edits existing remote text (rtext) objects."
 :options ("Style" "Height" "Rotation" "Edit")
 :arguments "Supplies the rtext object to edit and an option keyword to change its style, height, rotation, or content."
 :description "An Express Tool for modifying existing remote text (rtext) objects, offering options to change the text style, height, rotation, and content. New rtext objects are created with the RTEXT command, and RTEXTAPP sets the text editor used."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4133A11F-C914-43F4-8ADB-B4F0E01AEA73.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_rtedit/V25/EN_US")

(:name "RTEXT"
 :category :TEXT
 :aliases NIL
 :intl-name "_RTEXT"
 :synopsis "Creates a remote text (rtext) object from an external file or a DIESEL expression."
 :options ("Style" "Height" "Rotation" "File" "Diesel")
 :arguments "Supplies option keywords, chooses File or Diesel as the source, the insertion point, and the text style, height, and rotation."
 :description "An Express Tool that creates remote text (rtext) objects displaying frequently used text such as sheet notes or disclaimers, sourced from an external text file or a DIESEL expression. Rtext renders like AutoCAD text and mtext but references its content externally, and is edited with RTEDIT."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-28585C1C-65B8-41E0-90A3-7C043123EF7A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_rtext/V25/EN_US")

(:name "RTUCS"
 :category :VIEW
 :aliases NIL
 :intl-name "_RTUCS"
 :synopsis "Rotates the UCS dynamically using the pointing device."
 :options ("Save" "Restore" "Delete" "Cycle" "Angle" "Origin" "View" "World"
           "Undo")
 :arguments "Drags perpendicular to the active axis to rotate the UCS, pressing Tab to change the axis, or supplies an option keyword."
 :description "Dynamically rotates the User Coordinate System by clicking and dragging the pointer perpendicular to the active axis, with Tab switching which axis is rotated about (default X). The UCS is incremented by the value set with the Angle option, and named UCS definitions can be saved, restored, and deleted. Provided as an Express Tool in AutoCAD."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2750036B-5E46-4D54-8023-8CB263294FE8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_rtucs/V25/EN_US")

(:name "SAVE"
 :category :FILE
 :aliases ("SA")
 :intl-name "_SAVE"
 :synopsis "Saves the current drawing, opening the Save Drawing As dialog box."
 :options NIL
 :arguments "Opens a dialog with no command-line input (unless FILEDIA is 0); a file name and format are chosen interactively."
 :description "Saves the current drawing to a DWG, DXF, DWT, or DWS file. BricsCAD opens the Save drawing as dialog with a choice of file formats and versions; AutoCAD saves under a new name or location without changing the current drawing (identical to QSAVE in AutoCAD LT)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-155255B4-ADFA-4C21-958F-601DE09260EB.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_save/V25/EN_US")

(:name "SAVEALL"
 :category :FILE
 :aliases NIL
 :intl-name "_SAVEALL"
 :synopsis "Saves all open drawings, leaving them open for continued editing."
 :options NIL
 :arguments "Takes no input; prompts for a file name for any unnamed drawing."
 :description "Saves every open drawing that has been modified since its last save, leaving the drawings open. If a drawing has no file name yet, the user is prompted to provide one. Provided as an Express Tool in AutoCAD."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C3E8083E-6C0D-4975-B05F-BCA5E9AE1FA7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_saveall/V25/EN_US")

(:name "SAVEAS"
 :category :FILE
 :aliases NIL
 :intl-name "_SAVEAS"
 :synopsis "Saves a copy of the current drawing under a new file name or location."
 :options NIL
 :arguments "Opens a dialog with no command-line input (unless FILEDIA is 0); a file name and format are chosen interactively."
 :description "Saves the current drawing to a DWG, DXF, DWT, or DWS file under a new name or location, making the newly saved file the current drawing. The available file types are the same as for the SAVE command."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1FF801F9-7FEE-4494-854D-4704A7784232.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_saveas/V25/EN_US")

(:name "SCALE"
 :category :MODIFY
 :aliases ("SC")
 :intl-name "_SCALE"
 :synopsis "Enlarges or reduces selected objects, keeping the proportions of the object the same after scaling."
 :options ("Copy" "Reference")
 :arguments "Selection set of entities, then a base point, then a scale factor. Instead of a factor, the keyword \"Copy\" scales a duplicate, or \"Reference\" specifies a reference length followed by the new length. A factor above 1 enlarges, between 0 and 1 shrinks, and a negative value scales in the opposite direction."
 :description "Resizes 2D and 3D entities uniformly about a base point by a scale factor or a reference length, keeping proportions the same. Values above 1 enlarge, values between 0 and 1 reduce, and negative values scale in the opposite direction."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D4E17E51-5000-4AB6-8D6A-6D2AB4863C75.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_scale/V25/EN_US")

(:name "SCALELISTEDIT"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_SCALELISTEDIT"
 :synopsis "Controls the list of scales available for layout viewports, page layouts, and plotting."
 :options NIL
 :arguments "Opens the Edit Scale List dialog with no command-line input; use -SCALELISTEDIT to add, edit, or delete scales at the prompt."
 :description "Opens the Edit Scale List dialog to add, edit, delete, and reorder the predefined scales used throughout the program. The 1:1 scale cannot be deleted, and -SCALELISTEDIT provides the command-line equivalent."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-97BBBAA5-04D2-4CFC-B64D-999A046CCA1B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_scalelistedit/V25/EN_US")

(:name "SCRIPT"
 :category :SYSTEM
 :aliases ("SCR")
 :intl-name "_SCRIPT"
 :synopsis "Executes a sequence of commands from a script (SCR) file."
 :options NIL
 :arguments "Opens a file-selection dialog with no command-line input (unless FILEDIA is 0); the chosen script runs immediately."
 :description "Runs a script file, a text file with an .scr extension in which each line contains a command to be executed at the Command prompt. A file-selection dialog appears (or a prompt when FILEDIA is 0), and the script can be stopped with Esc."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DB55FE5C-6B51-40AE-AE3D-4C3A28ADC5D9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_script/V25/EN_US")

(:name "SECTION"
 :category :|3D|
 :aliases ("SEC")
 :intl-name "_SECTION"
 :synopsis "Creates a 2D region from the intersection of a plane with 3D solids, surfaces, or meshes."
 :options ("Object" "Zaxis" "View" "XY" "YZ" "ZX" "3points")
 :arguments "Supplies the objects to section, then defines the cutting plane by object, Z axis, view, a standard plane, or three points."
 :description "Creates a 2D cross-section region where a plane intersects 3D solids, surfaces, polyface meshes, or 3D faces. Unlike SECTIONPLANE, the resulting region has no live-sectioning capability."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C649EE10-5FE3-4703-9301-C97AEF7C5BD7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_section/V25/EN_US")

(:name "SECTIONPLANE"
 :category :|3D|
 :aliases ("SPLANE")
 :intl-name "_SECTIONPLANE"
 :synopsis "Creates a section object that acts as a cutting plane through 3D objects."
 :options ("Face" "Draw" "Orthographic" "Through point" "Type")
 :arguments "Supplies a face or point to locate the section line, or an option keyword such as Draw or Orthographic to define the section object."
 :description "Creates a section plane object that cuts through 3D solids, surfaces, meshes, and (in AutoCAD) point clouds, letting you see inside a model. Section planes support live sectioning, can be saved as blocks, and can be edited or deleted."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3AC2CA12-2085-4782-B66A-7964B73B55EA.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_sectionplane/V25/EN_US")

(:name "SECTIONPLANESETTINGS"
 :category :|3D|
 :aliases NIL
 :intl-name "_SECTIONPLANESETTINGS"
 :synopsis "Sets display options for a selected section plane."
 :options NIL
 :arguments "Opens a dialog with no command-line input; section-plane display properties are set interactively."
 :description "Opens a settings dialog to configure how a selected section plane is displayed. BricsCAD exposes the Section Planes category of Drawing Explorer for 2D, 3D, and live sections, controlling intersection boundaries, fills, background and hidden lines, and cut-away geometry."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D061EB7A-6B8D-4CB9-9C2F-6C68B711FA33.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_sectionplanesettings/V25/EN_US")

(:name "SECURITYOPTIONS"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_SECURITYOPTIONS"
 :synopsis "Opens the Security Options dialog box."
 :options NIL
 :arguments "Opens a dialog with no command-line input; security settings are configured interactively."
 :description "Opens the Security Options dialog box. BricsCAD uses it to set password protection and encryption for the drawing, while the AutoCAD page describes it as controlling security restrictions for running executable files in the product."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2199A941-E183-4CAC-914C-E4538468DE64.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_securityoptions/V25/EN_US")

(:name "SELECT"
 :category :SELECTION
 :aliases NIL
 :intl-name "_SELECT"
 :synopsis "Selects entities and places them in the Previous selection set."
 :options ("Window" "Last" "Crossing" "BOX" "ALL" "Fence" "WPolygon" "CPolygon"
           "Group" "Add" "Remove" "Multiple" "Previous" "Undo" "AUto" "Single")
 :arguments "Supplies a selection-method keyword and/or points defining a selection region (or a pickset), repeated until an empty response ends selection; the chosen entities become the Previous selection set."
 :description "Selects one or more entities using a variety of selection methods; the resulting selection set can be reused in subsequent commands with the Previous option. In 3D products Ctrl can be held to select subobjects such as vertices, edges, and faces."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0DD5DA73-9DC5-4424-8FED-7BBE3BE52A4D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_select/V25/EN_US")

(:name "SELECTSIMILAR"
 :category :SELECTION
 :aliases NIL
 :intl-name "_SELECTSIMILAR"
 :synopsis "Selects objects of the same type that match the properties of selected objects."
 :options ("Settings" "Color" "Layer" "Linetype" "Linetypescale" "Plotstyle"
           "Objectstyle" "Name")
 :arguments "Supplies the sample object(s) to select, optionally the SEttings keyword to configure which properties are matched; matching objects in the drawing are added to the selection set."
 :description "Finds all objects within the current drawing that match the properties of selected sample objects and adds them to the selection set. The properties used for matching (Layer and object type/Name by default) are configured through the Settings option."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C160A9C9-1287-4111-8D27-05AFBAA7C29F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_selectsimilar/V25/EN_US")

(:name "SETBYLAYER"
 :category :MODIFY
 :aliases NIL
 :intl-name "_SETBYLAYER"
 :synopsis "Changes the property overrides of selected objects to ByLayer."
 :options ("Settings" "Color" "Linetype" "Lineweight" "Material" "Plotstyle"
           "Transparency")
 :arguments "Supplies the objects to reset (or 'all' for all non-frozen entities), then answers the Change ByBlock to ByLayer? and Include blocks? prompts; a Settings option selects which properties are reset."
 :description "Resets overridden object properties (color, linetype, lineweight, material, plot style, and transparency) back to their default ByLayer value. The SETBYLAYERMODE system variable controls which properties are affected, and blocks on unlocked layers can optionally be included."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A9D9FF14-4EF6-4A25-B0F4-506C6B792E9E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_setbylayer/V25/EN_US")

(:name "SETVAR"
 :category :SYSTEM
 :aliases ("SET")
 :intl-name "_SETVAR"
 :synopsis "Lists or changes the values of system variables."
 :options ("?")
 :arguments "Supplies a system variable name and then a new value for it, or '?' to list variable names; can be invoked transparently ('SETVAR)."
 :description "Displays and changes the values of system variables at the command line. System variable names can also be entered directly without using this command, and it can be entered transparently."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-01E38833-6D3A-4AA5-A446-C03B44E7AB56.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_setvar/V25/EN_US")

(:name "SHADEMODE"
 :category :VIEW
 :aliases NIL
 :intl-name "_SHADEMODE"
 :synopsis "Controls the display / shading style of 3D objects in the current drawing."
 :options ("2Dwireframe" "Wireframe" "Hidden" "Realistic" "Conceptual" "Shaded"
           "shaded with Edges" "shades of Grey" "Sketchy" "X-ray" "Other"
           "cUrrent")
 :arguments "Supplies the name of a preset visual style (or a shading keyword) to apply as the current display mode."
 :description "Specifies the shading/visual style used for the current drawing. In AutoCAD-based 3D products it starts the VSCURRENT command for selecting a visual style, while in AutoCAD LT it toggles between wireframe and hidden-line display."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A2D7CD17-516B-42EB-AE65-49D974570B90.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_shademode/V25/EN_US")

(:name "SHAPE"
 :category :DRAW
 :aliases NIL
 :intl-name "_SHAPE"
 :synopsis "Inserts a shape from a loaded SHX shape file into the drawing."
 :options ("?")
 :arguments "Supplies the shape name, then the insertion point, the scale, and the rotation angle."
 :description "Places shapes from an SHX shape file (previously loaded with the LOAD command) into the drawing at a specified insertion point, scale, and rotation. The '?' option lists the names of loaded shapes and their source files."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9750CDBE-028A-4E6B-AD51-ABB107737A63.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_shape/V25/EN_US")

(:name "SHEETSET"
 :category :FILE
 :aliases ("SSM")
 :intl-name "_SHEETSET"
 :synopsis "Opens the Sheet Set Manager (Sheet Sets panel)."
 :options NIL
 :arguments "Opens a panel with no command-line input."
 :description "Opens the Sheet Set Manager / Sheet Sets panel, a central location to create and manage sheet sets, which are named collections of drawing sheets where each sheet corresponds to a layout in a DWG file. The panel can be floated, docked, or stacked like other dockable panels."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EF38E77D-1938-40EC-ACBE-2CC715AEC6E0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_sheetset/V25/EN_US")

(:name "SHEETSETHIDE"
 :category :FILE
 :aliases NIL
 :intl-name "_SHEETSETHIDE"
 :synopsis "Closes the Sheet Set Manager (Sheet Sets panel)."
 :options NIL
 :arguments "Closes a panel with no command-line input."
 :description "Closes the Sheet Set Manager / Sheet Sets panel to hide it from the current workspace. When the panel is stacked, closing it removes the Sheet Sets tab or icon from that stack."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5D092A7D-AC59-42A6-8BDE-08ADEF6F2670.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_sheetsethide/V25/EN_US")

(:name "SHELL"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_SHELL"
 :synopsis "Accesses operating system commands / opens the command prompt window."
 :options NIL
 :arguments "Supplies the name of an operating-system program/command to run, or an empty response to open an interactive OS command prompt window."
 :description "Runs operating system commands or other applications from within the program; you can specify a program to run, or press Enter to open an interactive command prompt window and return to the Command prompt afterward."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-675A6BDA-681C-445E-9A32-B8D3713F258A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_shell/V25/EN_US")

(:name "SHOWURLS"
 :category :EDIT
 :aliases NIL
 :intl-name "_SHOWURLS"
 :synopsis "Displays all URLs attached in the drawing and allows them to be edited."
 :options ("Show URL" "Edit" "Replace")
 :arguments "Opens a dialog with no command-line input; URLs are viewed, edited, or replaced interactively."
 :description "An Express Tool that lists every URL attached to objects in the drawing and lets you view, edit, and replace them through a dialog box. It can shift the view to locate objects associated with a selected URL, and edits can apply to multiple selected URLs at once."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3AEBE6CA-E53D-4857-81A6-4FABD9423A02.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_showurls/V25/EN_US")

(:name "SHP2BLK"
 :category :BLOCK
 :aliases NIL
 :intl-name "_SHP2BLK"
 :synopsis "Converts all instances of a selected shape object into an equivalent block reference."
 :options NIL
 :arguments "Supplies the shape entity to convert and the name for the replacement block."
 :description "An Express Tool that creates a block definition from a selected shape object and replaces all instances of that shape throughout the drawing with references to the new block. A temporary block is generated during processing and then removed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-882CCB78-CF99-4E4F-945A-0E46FEC25946.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_shp2blk/V25/EN_US")

(:name "SIGVALIDATE"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_SIGVALIDATE"
 :synopsis "Displays information about the digital signature attached to a drawing and its xrefs."
 :options ("View Signature")
 :arguments "Opens a dialog with no command-line input; use -SIGVALIDATE for a command-line report."
 :description "Opens the Validate Digital Signatures dialog to review the digital signature status of a drawing and its cross-references, indicating whether files are validly signed, unsigned, have unknown certificates, or failed validation. The -SIGVALIDATE variant reports at the command line, and the SIGWARN system variable governs signature warnings."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C28D46C3-4C3D-4D37-86B9-E0D235F82EC6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_sigvalidate/V25/EN_US")

(:name "SKETCH"
 :category :DRAW
 :aliases ("FREEHAND")
 :intl-name "_SKETCH"
 :synopsis "Creates a series of freehand line segments."
 :options ("Type" "Increment" "Tolerance")
 :arguments "Supplies the object type (line, polyline, or spline), the segment increment, and the tolerance, then sketches freehand with the pointer."
 :description "Creates freehand geometry by sketching with the pointing device or a digitizer, producing individual lines, a polyline, or a spline depending on the object type (in BricsCAD governed by SKPOLY). Before sketching you set the object type, increment, and tolerance."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EFF06F5D-E8B2-44D9-8CE6-D8C100A37AAA.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_sketch/V25/EN_US")

(:name "SLICE"
 :category :|3D|
 :aliases ("SL")
 :intl-name "_SLICE"
 :synopsis "Splits 3D solids and surfaces into pieces along a cutting plane."
 :options ("Object" "Surface" "Zaxis" "View" "XY" "YZ" "ZX" "3points" "Both")
 :arguments "Supplies the objects to slice, defines the cutting plane (by object, surface, Z axis, view, standard plane, or points), and indicates which side(s) to keep."
 :description "Creates new 3D solids and surfaces by slicing existing objects along a defined cutting plane. The plane can be set by points, a planar object, a surface, or a UCS plane, and one or both sides of the result can be kept; new objects inherit the original layer and color."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-27593C5E-4B89-41F2-872B-927D69517CBF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_slice/V25/EN_US")

(:name "SNAP"
 :category :SYSTEM
 :aliases ("SN")
 :intl-name "_SNAP"
 :synopsis "Restricts cursor movement to specified snap intervals."
 :options ("ON" "OFF" "Aspect" "Rotate" "Style" "Standard" "Isometric" "Type")
 :arguments "Supplies a snap spacing value or an option keyword (On/Off, Aspect, Rotate, Style, or Type)."
 :description "Constrains cursor movement to a grid-based increment, with options to turn snapping on or off and to set spacing, aspect ratio, rotation, style (standard or isometric), and type (grid or polar)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F47F4AAF-4859-45D4-846C-3742268834A9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_snap/V25/EN_US")

(:name "SOLID"
 :category :DRAW
 :aliases ("PLANE" "SO")
 :intl-name "_SOLID"
 :synopsis "Creates solid-filled triangles and quadrilaterals (2D solid-filled polygons)."
 :options ("Rectangle" "Square" "Triangle")
 :arguments "Supplies successive corner points: first, second, third, then a fourth point (or empty string to make a triangle), ending with an empty string; e.g. (command \"_SOLID\" p1 p2 p3 p4 \"\"). Fill shows only when FILLMODE is on and the view is orthogonal to the solid."
 :description "The SOLID command creates 3- and 4-sided solid-filled 2D polygons (not 3D solids); pressing Enter at the fourth point makes a filled triangle and giving the fourth point makes a quadrilateral, and successive point pairs chain further faces into one object. Filled display requires FILLMODE on and an orthogonal view. BricsCAD additionally offers predefined Rectangle, Square, and Triangle shape options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0998E0EE-7829-4AA4-9282-4FC703F9B1F4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_solid/V25/EN_US")

(:name "SOLIDEDIT"
 :category :|3D|
 :aliases NIL
 :intl-name "_SOLIDEDIT"
 :synopsis "Edits faces, edges, and bodies of 3D solids and 2D regions."
 :options ("Face" "Edge" "Body" "Undo" "eXit")
 :arguments "Supplies Face, Edge, or Body, then a sub-option (such as Extrude, Move, Rotate, Offset, Taper, Imprint, Shell, or Clean) and the faces, edges, or solid to edit."
 :description "Modifies 3D solids (and 2D regions) at the face, edge, and body level. Face operations include extrude, move, rotate, offset, taper, delete, copy, and color; edge operations copy and color; body operations imprint, separate, shell, clean, and check."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D54C266B-2B68-4660-ACA5-0579432F149C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_solidedit/V25/EN_US")

(:name "SOLPROF"
 :category :|3D|
 :aliases NIL
 :intl-name "_SOLPROF"
 :synopsis "Creates 2D profile images (hidden and visible lines) of 3D solids for display in a layout viewport."
 :options ("Display hidden profile lines on separate layer (Yes/No)"
           "Project profile lines onto a plane (Yes/No)"
           "Delete tangential edges (Yes/No)")
 :arguments "selection set of 3D solids; Yes/No for separate hidden-line layer; Yes/No for project onto plane; Yes/No for delete tangential edges"
 :description "Projects selected 3D solids onto a 2D plane parallel with the current layout viewport, generating hidden and visible profile lines as blocks on separate layers displayed only in that viewport. Works only in model space of a layout viewport."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-080247BF-BDAB-49F6-A0A5-966412CEDCE9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_solprof/V25/EN_US")

(:name "SPELL"
 :category :TEXT
 :aliases ("SP")
 :intl-name "_SPELL"
 :synopsis "Checks spelling of text in the drawing."
 :options ("Entire drawing" "Selected entities" "Start" "Ignore" "Ignore All"
           "Change" "Change All" "Add" "Lookup" "Change Dictionaries")
 :arguments "opens the Check Spelling dialog box (no command-line arguments)"
 :description "Opens a spell-checking dialog that finds and corrects potential spelling errors in text, mtext, leaders, multileaders, tables, and block attributes, across the entire drawing or a selection."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5FDA1883-8A61-4762-9D83-0432E323729B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_spell/V25/EN_US")

(:name "SPHERE"
 :category :|3D|
 :aliases NIL
 :intl-name "_SPHERE"
 :synopsis "Creates a 3D solid sphere."
 :options ("Radius" "Diameter" "3P" "2P" "TTR")
 :arguments "center point; radius (or Diameter option)"
 :description "Creates a three-dimensional solid sphere by specifying a center point and a radius or diameter; it can also be defined with the 3P, 2P, or TTR options. FACETRES controls smoothness in shaded or hidden views."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D003D7B2-A309-4C19-9CCF-AB9A7BA8833D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_sphere/V25/EN_US")

(:name "SPLINE"
 :category :DRAW
 :aliases ("SPL")
 :intl-name "_SPLINE"
 :synopsis "Creates a 2D or 3D spline (NURBS) through fit points or from control vertices."
 :options ("Method (Fit/CV)" "Object" "Knots" "start Tangency" "end Tangency"
           "toLerance" "Degree" "Close" "Undo")
 :arguments "first point; next points; Enter to finish (or options such as Method, Close, tangencies)"
 :description "Creates a smooth nonuniform rational B-spline that passes through or near a set of fit points, or is defined by control vertices, or converts an eligible object to a spline. Splines can be open or closed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5E7D51E2-1595-4E0C-85F8-2D7CBD166A08.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_spline/V25/EN_US")

(:name "SPLINEDIT"
 :category :MODIFY
 :aliases ("SPE")
 :intl-name "_SPLINEDIT"
 :synopsis "Modifies the parameters of a spline or converts a spline to a polyline."
 :options ("Close" "Open" "Join" "Fit Data" "Edit vertex" "convert to Polyline"
           "Reverse" "Undo" "eXit")
 :arguments "select spline; option (Close/Join/Fit Data/Edit vertex/Convert to Polyline/Reverse/Undo/eXit)"
 :description "Edits spline fit data, control vertices, weights, tolerance, and tangents; joins a spline with adjoining objects; reverses direction; and converts a spline to a polyline. Spline-fit polylines are converted automatically."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5530922C-6828-48B1-804C-EDD9053535BD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_splinedit/V25/EN_US")

(:name "SSX"
 :category :SELECTION
 :aliases NIL
 :intl-name "_SSX"
 :synopsis "Creates a selection set based on a selected template object using filters."
 :options ("Block name" "Color" "Entity" "Flag" "LAyer" "LType" "Pick" "Style"
           "Thickness" "Vector")
 :arguments "select template object (or Enter for none); filter options; result available as the Previous selection set"
 :description "Builds a selection set of objects matching a selected template object exactly or by adjusted filter criteria. Can be invoked at the Command prompt or at any Select objects prompt. An Express Tool in both products."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-386ADF5E-C709-4940-8DB4-909C2760A23F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_ssx/V25/EN_US")

(:name "STANDARDS"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_STANDARDS"
 :synopsis "Associates and manages CAD standards (DWS) files for the current drawing."
 :options NIL
 :arguments "opens the Configure Standards dialog box (no command-line arguments)"
 :description "Associates one or more standards (DWS) files with the current drawing to define common properties such as layers, dimension styles, linetypes, multileader styles, and text styles for consistency across drawing sets."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6AE2A5E5-651F-4C3B-8E3C-DE8DED6AA94C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_standards/V25/EN_US")

(:name "STATUS"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_STATUS"
 :synopsis "Displays drawing statistics, modes, and extents."
 :options NIL
 :arguments "no arguments (reports status to the command line / text window)"
 :description "Reports drawing statistics including the number of objects, coordinate and extents information, current settings for layers, colors, and linetypes, and system resources. When used at the DIM prompt it lists dimensioning variables."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FB3C7BE6-BF43-4623-8662-0D42B37DC7FC.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_status/V25/EN_US")

(:name "STLOUT"
 :category :FILE
 :aliases NIL
 :intl-name "_STLOUT"
 :synopsis "Exports 3D solids and watertight meshes to an STL file for stereolithography and 3D printing."
 :options ("Create a binary STL file (Yes/No)" "smoothness Low/Medium/High")
 :arguments "selection set of 3D solids or watertight meshes; Yes/No for binary STL file; output file name"
 :description "Stores selected 3D solids and watertight meshes in STL format, converting the geometry to a faceted triangle representation suitable for stereolithography apparatus and 3D printing. FACETRES controls triangulation fineness."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5E9946B5-D769-4881-BC0F-21F54840683D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_stlout/V25/EN_US")

(:name "STRETCH"
 :category :MODIFY
 :aliases ("S")
 :intl-name "_STRETCH"
 :synopsis "Stretches objects crossed by a selection window or polygon."
 :options ("CPolygon" "Crossing")
 :arguments "selection set (crossing window or polygon); base point; second point (displacement)"
 :description "Moves the endpoints and vertices that lie within a crossing selection while leaving the rest of each object unchanged; objects fully enclosed or individually selected are moved. Certain objects such as circles, ellipses, and blocks are moved rather than stretched."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F000A502-D39E-4D31-A8E2-4A626473FB72.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_stretch/V25/EN_US")

(:name "STYLE"
 :category :TEXT
 :aliases ("DDSTYLE" "EXPFONTS" "EXPSTYLE" "EXPSTYLES" "ST")
 :intl-name "_STYLE"
 :synopsis "Creates, modifies, or specifies text styles."
 :options NIL
 :arguments "opens the Text Style dialog box (BricsCAD: Drawing Explorer, Text Styles); use -STYLE for command-line prompts"
 :description "Displays a dialog for creating and modifying text styles that control the font, height, width factor, oblique angle, and orientation of new text. In BricsCAD it opens the Drawing Explorer with Text Styles selected."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F8EA1280-BF0E-4674-ABCF-EEA0D41752D6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_style/V25/EN_US")

(:name "STYLESMANAGER"
 :category :PLOT
 :aliases NIL
 :intl-name "_STYLESMANAGER"
 :synopsis "Displays the Plot Style Manager for creating and editing plot style tables."
 :options NIL
 :arguments "opens the Plot Style Manager (no command-line arguments)"
 :description "Opens the Plot Style Manager where CTB or STB plot style tables can be created with the Add-a-Plot-Style-Table wizard or edited in the Plot Style Table Editor."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6FA49011-C308-46E7-A288-CC07F6CD3BFD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_stylesmanager/V25/EN_US")

(:name "SUBTRACT"
 :category :|3D|
 :aliases ("SU")
 :intl-name "_SUBTRACT"
 :synopsis "Creates a new object by subtracting one set of overlapping 3D solids or 2D regions from another."
 :options NIL
 :arguments "first selection set (objects to subtract from); second selection set (objects to subtract)"
 :description "Performs a Boolean subtraction: objects in the second selection set are removed from those in the first to produce a single resulting 3D solid or 2D region. The outcome depends on selection order. In BricsCAD Lite it applies to regions only."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-14872FC1-8827-4D3B-978E-20936F9A78E5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_subtract/V25/EN_US")

(:name "SUNPROPERTIES"
 :category :RENDER
 :aliases ("SUN")
 :intl-name "_SUNPROPERTIES"
 :synopsis "Displays the Sun Properties palette for sun and sky settings."
 :options NIL
 :arguments "opens the Sun Properties palette / Drawing Explorer Lights (no command-line arguments)"
 :description "Opens the Sun Properties palette (in BricsCAD, the Drawing Explorer with Lights selected) to control sun status, intensity, shadows, date, time, and geographic-based sun angle for simulating sunlight."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DC2FC4DC-9B40-4B3C-9E5C-41E68559A028.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_sunproperties/V25/EN_US")

(:name "SUPERHATCH"
 :category :DRAW
 :aliases NIL
 :intl-name "_SUPERHATCH"
 :synopsis "Hatches an area using a selected image, block, xref, or wipeout as the hatch pattern."
 :options ("Image" "Block" "Xref Attach" "Wipeout" "Select existing")
 :arguments "select pattern type (Image/Block/Xref/Wipeout); insertion point; scale; rotation; internal pick point for the boundary"
 :description "Express Tool that fills an area with a repeating pattern created from an image, block, external reference, or wipeout object, with control over scale, rotation, and curve error tolerance."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-89FB15FE-28B9-4A51-BACA-A393469EE1A6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_superhatch/V25/EN_US")

(:name "SWEEP"
 :category :|3D|
 :aliases NIL
 :intl-name "_SWEEP"
 :synopsis "Creates a 3D solid or surface by sweeping a 2D object or subobject along an open or closed path."
 :options ("Mode" "Alignment" "Base point" "Scale" "Twist" "Bank")
 :arguments "profile selection set; sweep path; options (Mode/Alignment/Base point/Scale/Twist)"
 :description "Sweeps a profile such as a spline, polyline, circle, arc, or region along a path to create a 3D solid or surface. Open profiles produce surfaces; enclosed profiles can produce solids or surfaces. Alignment, base point, scale, twist, and banking can be controlled."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2391CE97-3794-402C-8BC1-E2DCB452DD13.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_sweep/V25/EN_US")

(:name "SYSVDLG"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_SYSVDLG"
 :synopsis "Views, edits, saves, and restores system variable settings in a dialog box."
 :options NIL
 :arguments "opens the System Variables dialog box (no command-line arguments)"
 :description "Express Tool that provides a dialog for viewing, filtering, editing, saving, and restoring system variable settings, including saving settings to files for later use or as scripts."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E79F7A56-E373-48EC-AEB7-652CEDBE26D7.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_sysvdlg/V25/EN_US")

(:name "SYSWINDOWS"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_SYSWINDOWS"
 :synopsis "Arranges application windows and icons."
 :options ("Cascade" "tile Horizontally" "tile Vertically" "Arrange icons")
 :arguments "option (Cascade/tile Horizontally/tile Vertically/Arrange icons)"
 :description "Arranges open document windows in cascaded or tiled layouts and arranges minimized icons, useful when the application window is shared with external applications."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-34A6D747-B9EC-4D1C-897A-D93F55F1BF2A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_syswindows/V25/EN_US")

(:name "TABLE"
 :category :TABLE
 :aliases NIL
 :intl-name "_TABLE"
 :synopsis "Creates an empty table object."
 :options NIL
 :arguments "opens the Insert Table dialog box; insertion point (use -TABLE for command-line prompts)"
 :description "Creates a table object, a compound object of rows and columns, from an empty table, a table style, external data, or a data link. The Insert Table dialog box is displayed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-367470A6-6E6E-4181-9E53-9B0EC88F50DC.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_table/V25/EN_US")

(:name "TABLEDIT"
 :category :TABLE
 :aliases NIL
 :intl-name "_TABLEDIT"
 :synopsis "Edits text in a table cell."
 :options NIL
 :arguments "pick a table cell; enter or edit the cell text"
 :description "Edits the text within a table cell using the in-place text editor, operating like the MTEXT text formatting interface. In BricsCAD, TABLEMOD is used to change cell formatting rather than content."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-44D79B63-B21B-4F1D-9E0D-1C3B69970BF3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tabledit/V25/EN_US")

(:name "TABLESTYLE"
 :category :TABLE
 :aliases NIL
 :intl-name "_TABLESTYLE"
 :synopsis "Creates, modifies, or specifies table styles."
 :options NIL
 :arguments "opens the Table Style dialog box (BricsCAD: Drawing Explorer, Table Styles) (no command-line arguments)"
 :description "Opens a dialog for creating and modifying table styles that control the appearance of tables, including cell styles (Title, Header, Data), text properties, margins, borders, and table direction."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-64621CE7-B7A2-42CD-897F-67ABE475D684.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tablestyle/V25/EN_US")

(:name "TABLET"
 :category :SYSTEM
 :aliases ("TA")
 :intl-name "_TABLET"
 :synopsis "Calibrates, configures, and turns on and off an attached digitizing tablet."
 :options ("ON" "OFF" "CALibrate" "CFG" "Orthogonal" "Affine" "Projective")
 :arguments "option (ON/OFF/CALibrate/ConFiGure); calibration points or configuration corners as prompted"
 :description "Manages digitizing tablet operations: toggling tablet mode on and off, calibrating the tablet to map its points to drawing coordinates, and configuring tablet menu and screen pointing areas. BricsCAD requires Wintab32.dll on Windows."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6ED485A6-EAF0-47EF-84FC-4975BBAE3DA3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tablet/V25/EN_US")

(:name "TABSURF"
 :category :|3D|
 :aliases NIL
 :intl-name "_TABSURF"
 :synopsis "Creates a mesh surface by extruding a curve along a straight direction-vector path."
 :options NIL
 :arguments "object for path curve (the profile to sweep); object for direction vector (line or open polyline)"
 :description "Creates a tabulated polygon mesh by sweeping a selected curve such as a line, arc, circle, ellipse, or polyline in the direction and length of a selected direction vector. SURFTAB1 controls mesh density; MESHTYPE controls mesh type."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-59FB536E-3597-4BFB-B89A-13D9903D3749.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tabsurf/V25/EN_US")

(:name "TCIRCLE"
 :category :TEXT
 :aliases NIL
 :intl-name "_TCIRCLE"
 :synopsis "Draws a circle, slot, or rectangle around each selected text or mtext object."
 :options ("Circles" "Slots" "Rectangles" "Constant" "Variable")
 :arguments "selection set of text/mtext; distance offset factor; shape (Circles/Slots/Rectangles)"
 :description "Express Tool that encloses selected text, mtext, or attribute definitions with circles, slots, or rectangles of constant size or variable size based on each object's dimensions and an offset factor."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DEB79D5D-671A-437E-9C0F-3DE44F9C92A5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tcircle/V25/EN_US")

(:name "TCOUNT"
 :category :TEXT
 :aliases NIL
 :intl-name "_TCOUNT"
 :synopsis "Adds sequential numbering to text and mtext as a prefix, suffix, or replacement."
 :options ("X" "Y" "Select-order" "Overwrite" "Prefix" "Suffix" "Find&replace")
 :arguments "selection set of text; sort method (X/Y/Select-order); start,increment; placement (Overwrite/Prefix/Suffix/Find&replace)"
 :description "Express Tool that applies sequential numbers to selected text objects and each line of multiline text. The starting number, increment (which may be negative), sort order, and placement method are configurable."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4B92219C-DA94-4D71-B308-D3818D3C6B8F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tcount/V25/EN_US")

(:name "TEXT"
 :category :DRAW
 :aliases ("TX")
 :intl-name "_TEXT"
 :synopsis "Creates a single-line text object."
 :options ("Justify" "Style" "Align" "Fit" "Center" "Middle" "Right" "TL" "TC"
           "TR" "ML" "MC" "MR" "BL" "BC" "BR")
 :arguments "Supplies a text insertion (start) point, a text height, a rotation angle, then the text string; alternatively the first response is \"J\" (Justify) followed by a justification keyword (Align, Fit, Center, Middle, Right, or the nine TL/TC/TR/ML/MC/MR/BL/BC/BR positions) or \"S\" (Style) followed by a text style name. Each line entered creates an independent text object."
 :description "Creates single-line text; each line entered is an independent object that can be moved, formatted, or edited separately. Height and rotation are prompted (height is skipped for fixed-height styles), and justification and text style can be set via keywords. In BricsCAD, text can evaluate LISP expressions when TEXTEVAL is 1, and for annotative styles the height value is paper-space height."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D1C664DD-63D9-467E-8EC1-2F5A1777A924.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_text/V25/EN_US")

(:name "TEXTEDIT"
 :category :TEXT
 :aliases NIL
 :intl-name "_TEXTEDIT"
 :synopsis "Edits a selected single-line text, multiline text, or dimension object."
 :options ("Undo" "Mode (Single/Multiple)")
 :arguments "select an annotation (text/mtext/dimension) object; edit the text in place"
 :description "Opens the in-place text editor to modify the content of a selected single-line text, multiline text, or dimension object. In AutoCAD the Mode option controls whether editing repeats for multiple objects."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B184DB8A-7566-4756-A78E-3721960D86DE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_textedit/V25/EN_US")

(:name "TEXTFIT"
 :category :TEXT
 :aliases NIL
 :intl-name "_TEXTFIT"
 :synopsis "Expands or compresses the width of a text object to fit between two points."
 :options ("Start point")
 :arguments "select text object; end point (or Start point option to set a new start point)"
 :description "Express Tool that stretches or shrinks a single-line text object in width to fit between a start point and a specified end point without changing its height. Mtext must be exploded to text first."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9F512EAB-FB32-471F-84F2-5A402FEEE3A5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_textfit/V25/EN_US")

(:name "TEXTMASK"
 :category :TEXT
 :aliases NIL
 :intl-name "_TEXTMASK"
 :synopsis "Creates a mask (blank area) behind selected text or mtext objects."
 :options ("Wipeout" "3dface" "Solid" "Offset")
 :arguments "mask type (Wipeout/3dface/Solid); offset distance; selection set of text/mtext"
 :description "Express Tool that places a mask behind selected text or mtext so underlying objects are hidden, offset from the text by a specified distance. The text and mask are grouped so they move and copy together; removed with TEXTUNMASK."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C16E8C64-1DB8-4706-A44D-3C5E0655540D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_textmask/V25/EN_US")

(:name "TEXTSCR"
 :category :VIEW
 :aliases NIL
 :intl-name "_TEXTSCR"
 :synopsis "Opens the text window showing the command and prompt history."
 :options NIL
 :arguments "no arguments (opens the text window; F2 toggles it)"
 :description "Displays the text window showing the recent command and prompt history for the current session. Press F2 or enter GRAPHSCR to return to the graphics screen; the SCRLHIST system variable controls the number of lines retained."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-63EF020A-C718-43A1-8510-CC2FD7EC80E8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_textscr/V25/EN_US")

(:name "TEXTTOFRONT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_TEXTTOFRONT"
 :synopsis "Brings text, dimensions, and leaders in front of all other objects."
 :options ("Text" "Dimensions" "Leaders" "All")
 :arguments "option (Text/Dimensions/Leaders/All)"
 :description "Changes the draw order so that text, dimensions, and/or leaders display in front of all other objects. Text and dimensions inside blocks and xrefs cannot be brought forward independently of their container."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DE1673FF-A97E-480A-8BE2-54B52F21D75C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_texttofront/V25/EN_US")

(:name "TEXTUNMASK"
 :category :TEXT
 :aliases NIL
 :intl-name "_TEXTUNMASK"
 :synopsis "Removes the mask from behind selected text or mtext objects."
 :options NIL
 :arguments "selection set of masked text/mtext objects"
 :description "Express Tool that removes masks previously applied to text or mtext objects with the TEXTMASK command, restoring the objects to an unmasked state."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C59A6D3D-C666-42A2-98A4-F856BB2D4A1F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_textunmask/V25/EN_US")

(:name "TFRAMES"
 :category :VIEW
 :aliases NIL
 :intl-name "_TFRAMES"
 :synopsis "Toggles the display of frames for all wipeout and image objects."
 :options ("ON" "OFF")
 :arguments "no arguments (toggles frame visibility on or off)"
 :description "Express Tool that toggles the visibility of the frame borders around all wipeout and image objects in the drawing; when off, frames are hidden, and when on they are shown."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-088EFB42-AA6C-4C0F-8AD7-34C7615D10C4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tframes/V25/EN_US")

(:name "TIME"
 :category :INQUIRY
 :aliases ("TI")
 :intl-name "_TIME"
 :synopsis "Displays the date and time statistics of a drawing."
 :options ("Display" "ON" "OFF" "Reset")
 :arguments "option (Display/ON/OFF/Reset) for the user elapsed timer"
 :description "Reports the current time, the drawing's creation and last-update times, the total editing time, and time until the next automatic save, and controls a user-resettable elapsed timer."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-990C8D36-CD20-48C0-A711-4F03B33C084C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_time/V25/EN_US")

(:name "TJUST"
 :category :TEXT
 :aliases NIL
 :intl-name "_TJUST"
 :synopsis "Changes the justification point of text, mtext, and attribute definitions without moving the text."
 :options ("Start" "Center" "Middle" "Right" "TL" "TC" "TR" "ML" "MC" "MR" "BL"
           "BC" "BR")
 :arguments "selection set of text/mtext/attribute definitions; new justification option"
 :description "Express Tool that changes the justification (anchor) point of text, mtext, and attribute definitions without moving the text, altering where the Insert object snap is and the direction text expands on later edits."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-41833749-A62B-4696-BF9C-80538DC25485.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tjust/V25/EN_US")

(:name "TOLERANCE"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_TOLERANCE"
 :synopsis "Creates geometric tolerance feature control frames."
 :options NIL
 :arguments "opens the Geometric Tolerance dialog box; insertion point for the feature control frame"
 :description "Opens the Geometric Tolerance dialog box to create feature control frames that show acceptable deviations of form, profile, orientation, location, and runout. Frames can also be created with LEADER or QLEADER."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F83AC6CE-B180-458F-BB88-6EEF424F99C4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tolerance/V25/EN_US")

(:name "TOOLBAR"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_TOOLBAR"
 :synopsis "Displays, hides, and customizes toolbars."
 :options ("Show" "Hide" "Left" "Right" "Top" "Bottom" "Float" "All")
 :arguments "toolbar name (or All); display/position option (Show/Hide/Left/Right/Top/Bottom/Float); use -TOOLBAR for command-line control"
 :description "Controls toolbar visibility and position. In AutoCAD it opens the Customize User Interface dialog; in BricsCAD it shows or hides named toolbars and docks or floats them. The command-line version is -TOOLBAR."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B6DFB514-F06E-44A4-99AF-6ACF22F78523.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_toolbar/V25/EN_US")

(:name "TOOLPALETTES"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_TOOLPALETTES"
 :synopsis "Opens the Tool Palettes window."
 :options NIL
 :arguments "no arguments (opens the Tool Palettes window)"
 :description "Opens the Tool Palettes window, a tabbed window that organizes blocks, hatches, and command tools with customizable tabs and right-click options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-167A8594-92CB-4FCC-B72C-0F546383E97C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_toolpalettes/V25/EN_US")

(:name "TOOLPALETTESCLOSE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_TOOLPALETTESCLOSE"
 :synopsis "Closes the Tool Palettes window."
 :options NIL
 :arguments "no arguments (closes the Tool Palettes window)"
 :description "Closes the Tool Palettes window, hiding it from the current workspace. When the panel is stacked (BricsCAD), closing it removes its tab or icon from the stack."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C72F06BE-BA0D-4BB0-BD61-F11FF734D24B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_toolpalettesclose/V25/EN_US")

(:name "TORIENT"
 :category :TEXT
 :aliases NIL
 :intl-name "_TORIENT"
 :synopsis "Rotates text, mtext, attribute definitions, and attributed blocks to a new orientation for readability."
 :options ("Most Readable" "Align with line" "New absolute rotation")
 :arguments "selection set of text objects; rotation angle or option (Most Readable / Align with line)"
 :description "Express Tool that rotates selected text, mtext, attribute definitions, and blocks with attributes about their middle point in 180-degree increments for readability, or to a specified absolute rotation, without changing their location."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3A9CCCD9-7B1D-4C83-944C-2D66F5FF32DF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_torient/V25/EN_US")

(:name "TORUS"
 :category :|3D|
 :aliases ("TOR")
 :intl-name "_TORUS"
 :synopsis "Creates a donut-shaped 3D solid."
 :options ("Radius" "Diameter" "3P" "2P" "TTR")
 :arguments "center point; radius or diameter of the whole torus; radius or diameter of the tube"
 :description "Creates a torus (donut-shaped) 3D solid defined by a center point, the radius or diameter of the torus, and the radius or diameter of the tube. FACETRES controls smoothness in shaded or hidden views. BricsCAD Lite runs AI_TORUS instead."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F7F2E0D8-58D2-4068-BBC1-60740D1A024A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_torus/V25/EN_US")

(:name "TPNAVIGATE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_TPNAVIGATE"
 :synopsis "Displays a specified tool palette or palette group."
 :options ("Palette" "palette Group")
 :arguments "tool palette name or palette group name to display"
 :description "Loads and displays a named tool palette or palette group at the Command line, opening the Tool Palettes window if it is not already shown. Intended for use in macros."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B2C547A7-AB22-475E-948E-9846748333A3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tpnavigate/V25/EN_US")

(:name "TRACE"
 :category :DRAW
 :aliases NIL
 :intl-name "_TRACE"
 :synopsis "BricsCAD: draws solid traces (wide lines with mitered vertices); AutoCAD 2026: opens and manages collaboration Traces (markups)."
 :options ("New" "Open" "Delete" "Rename" "Close")
 :arguments "BricsCAD: trace width; successive vertex points (each trace segment is drawn one vertex behind)"
 :description "In BricsCAD, TRACE draws solid traces resembling wide lines with automatically mitered vertices, affected by FILLMODE. In AutoCAD 2026, TRACE instead opens and manages collaboration Traces, markup overlays for feedback that do not alter drawing content. The two products' TRACE commands are unrelated."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D5D7D88B-6C2F-46F9-84F0-FD7B438BDCED.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_trace/V25/EN_US")

(:name "TRANSPARENCY"
 :category :MODIFY
 :aliases NIL
 :intl-name "_TRANSPARENCY"
 :synopsis "Controls whether background pixels of an image are transparent or opaque."
 :options ("ON" "OFF")
 :arguments "selection set of images; transparency mode (ON/OFF)"
 :description "Sets whether the background pixels of a selected image are transparent (objects beneath show through) or opaque. Works with images that have alpha channels or monotone/bitonal images."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6F50ABBC-726B-4513-9B2E-89503EEDD54F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_transparency/V25/EN_US")

(:name "TREX"
 :category :MODIFY
 :aliases NIL
 :intl-name "_TREX"
 :synopsis "Combines the TRIM and EXTEND operations in one command."
 :options ("Undo")
 :arguments "select cutting/boundary edges (or Enter for all); click objects to trim, Shift+click to extend"
 :description "Express Tool that trims or extends objects in a single command: after selecting boundary edges (or all objects), clicking an object trims it and Shift+clicking extends it. In AutoCAD this tool is considered obsolete in favor of TRIM and EXTEND."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-02FCA8B9-55C5-402C-AEA2-D1A6D0FE29B1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_trex/V25/EN_US")

(:name "TRIM"
 :category :MODIFY
 :aliases ("TR")
 :intl-name "_TRIM"
 :synopsis "Trims objects to meet the edges of other objects."
 :options ("Mode (Quick/Standard)" "cuTting edges" "Fence" "Crossing" "Project"
           "Edge" "eRase" "Undo")
 :arguments "cutting edges selection (Standard mode) or automatic (Quick mode); objects to trim (Shift-select to extend)"
 :description "Shortens objects so they end at cutting edges defined by other objects. Quick mode uses all objects as potential cutting edges; Standard mode requires selecting cutting edges first. Shift-select extends instead of trims."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B1A185EF-07C6-4C53-A76F-05ADE11F5C32.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_trim/V25/EN_US")

(:name "TSCALE"
 :category :TEXT
 :aliases NIL
 :intl-name "_TSCALE"
 :synopsis "Scales text, mtext, attributes, and attribute definitions about their justification points."
 :options ("Scale" "Height" "Existing" "justification options")
 :arguments "selection set of text/attributes; justification to use as base point; Scale factor or Height value"
 :description "Express Tool that scales selected text, mtext, attributes, and attribute definitions, each about its own justification point or a specified justification, using either a scale factor or a final text height."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D0836C0C-FC99-4521-8220-06D42D9F46FE.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_tscale/V25/EN_US")

(:name "TXT2MTXT"
 :category :TEXT
 :aliases ("COMBINETEXT")
 :intl-name "_TXT2MTXT"
 :synopsis "Converts or combines TEXT and MTEXT objects into one or more MTEXT objects."
 :options ("SEttings")
 :arguments "selection set of TEXT and MTEXT objects (or SEttings option for the options dialog)"
 :description "Express Tool that converts and combines selected single-line and multiline text into one or more mtext objects, preserving size, font, and color where possible. Behavior is governed by COMBINETEXTMODE settings."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1E68C8B2-520F-4084-BD20-51DC4A32A7E5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_txt2mtxt/V25/EN_US")

(:name "TXTEXP"
 :category :TEXT
 :aliases NIL
 :intl-name "_TXTEXP"
 :synopsis "Explodes text and mtext into polylines."
 :options NIL
 :arguments "selection set of text/mtext objects to explode"
 :description "Express Tool that converts TEXT and MTEXT objects into polyline and polyarc outlines (SHX and TrueType fonts supported), which can then be extruded or further broken into segments. Does not work on attributes within blocks or text in tables."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-80BE94B9-2ECE-438E-AEF8-984F7D27E0F9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_txtexp/V25/EN_US")

(:name "U"
 :category :EDIT
 :aliases NIL
 :intl-name "_U"
 :synopsis "Reverses the most recent operation."
 :options NIL
 :arguments "no arguments (undoes the single most recent command)"
 :description "Undoes the effect of the single most recent command; entering it repeatedly steps back through the session. It displays no prompts and has no options. Operations external to the drawing, such as plotting, cannot be reversed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-87AAEC8D-45D9-49F9-8DB8-FBABDAB1BB96.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_u/V25/EN_US")

(:name "UCS"
 :category :VIEW
 :aliases NIL
 :intl-name "_UCS"
 :synopsis "Sets the origin and orientation of the current user coordinate system (UCS)."
 :options ("Face" "NAmed" "Object" "Previous" "View" "World" "X" "Y" "Z"
           "ZAxis" "Move" "Apply")
 :arguments "new UCS origin (one to three points) or an option (Face/Object/View/World/X/Y/Z/ZAxis/Named/Previous)"
 :description "Defines a movable Cartesian user coordinate system that sets the XY work plane, axes of rotation, and directional references, by specifying an origin and orientation or by choosing alignment options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0BE49DA1-B323-4758-B49B-4C497D194C7A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_ucs/V25/EN_US")

(:name "UCSICON"
 :category :VIEW
 :aliases NIL
 :intl-name "_UCSICON"
 :synopsis "Controls the visibility, placement, and appearance of the UCS icon."
 :options ("ON" "OFF" "All" "Noorigin" "ORigin" "Selectable" "Properties")
 :arguments "option (ON/OFF/All/Noorigin/ORigin/Selectable/Properties)"
 :description "Controls whether the UCS icon is displayed, where it appears (at the origin or in a viewport corner), its appearance, and whether it is selectable. The icon indicates the location and orientation of the current UCS."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EA2D8ACA-336A-4656-BFD3-43BC371C6171.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_ucsicon/V25/EN_US")

(:name "UNDEFINE"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_UNDEFINE"
 :synopsis "Suppresses a built-in command so an application-defined command can override it."
 :options NIL
 :arguments "command name to undefine"
 :description "Temporarily disables access to a named built-in command so it can be replaced by an application-defined version or restricted. The command can still be run by prefixing its name with a period; REDEFINE restores it."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FC323813-D88D-4507-8665-67B215BF9EAD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_undefine/V25/EN_US")

(:name "UNDO"
 :category :EDIT
 :aliases NIL
 :intl-name "_UNDO"
 :synopsis "Reverses the effect of one or more commands."
 :options ("Auto" "Control" "BEgin" "End" "Mark" "Back" "Number")
 :arguments "number of operations to undo, or an option (Mark/Back/BEgin/End/Control/Auto)"
 :description "Reverses one or more previous operations, reporting the commands undone, and provides Mark/Back and Begin/End grouping and Control options that govern how undo information is recorded. Certain commands cannot be undone."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2729A466-B199-4840-B92B-4D8A38A8ADB8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_undo/V25/EN_US")

(:name "UNGROUP"
 :category :MODIFY
 :aliases NIL
 :intl-name "_UNGROUP"
 :synopsis "Disassociates the objects of a group."
 :options ("Name" "All" "?" "Accept" "Next")
 :arguments "select a group (or Name option to type the group name)"
 :description "Removes the grouping from a selected or named group so its objects are no longer associated. Options list existing groups or cycle through nested groups."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8FD85180-69F4-4F4C-8DC1-F072111AF664.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_ungroup/V25/EN_US")

(:name "UNION"
 :category :|3D|
 :aliases ("UNI")
 :intl-name "_UNION"
 :synopsis "Combines two or more 3D solids, surfaces, or 2D regions into one composite object."
 :options NIL
 :arguments "selection set of 3D solids, surfaces, or regions to combine"
 :description "Performs a Boolean union, merging selected objects of the same type into a single composite 3D solid, surface, or region; mixed selections are joined in separate subsets. In BricsCAD Lite it applies to regions only."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C38426A3-B4CA-4788-A6B9-F132DD705CA0.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_union/V25/EN_US")

(:name "UNISOLATEOBJECTS"
 :category :VIEW
 :aliases ("UNHIDE" "UNHIDEOBJECTS" "UNISOLATE")
 :intl-name "_UNISOLATEOBJECTS"
 :synopsis "Displays objects previously hidden with ISOLATEOBJECTS or HIDEOBJECTS."
 :options NIL
 :arguments "no arguments (restores visibility of previously isolated/hidden objects)"
 :description "Restores the visibility of objects that were hidden using the ISOLATEOBJECTS or HIDEOBJECTS commands."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B21B3F6C-7F67-465A-A97E-5E8ADC87B6D4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_unisolateobjects/V25/EN_US")

(:name "UNITS"
 :category :SYSTEM
 :aliases ("DDUNITS" "UN")
 :intl-name "_UNITS"
 :synopsis "Controls the precision and display formats for coordinates, distances, and angles."
 :options NIL
 :arguments "Normally opens a dialog box (Drawing Units in AutoCAD; Settings in BricsCAD); the hyphen form -UNITS prompts at the command line for unit format, precision, and angle settings."
 :description "Sets the format, precision, and display settings for coordinates, distances, and angles used in the drawing; these settings are saved in the current drawing and can be stored in templates."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1DAE2080-84E4-413E-BB4E-F5D2A96CB14A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_units/V25/EN_US")

(:name "VBAIDE"
 :category :CUSTOMIZATION
 :aliases ("VBA")
 :intl-name "_VBAIDE"
 :synopsis "Displays the Visual Basic Editor."
 :options NIL
 :arguments "Takes no arguments; opens the Microsoft Visual Basic (VBA) editing window for writing and debugging VBA code."
 :description "Opens the Visual Basic Editor for editing code, forms, and references in VBA projects, and for debugging and running projects. Available on Windows only."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-07122CCD-8E45-48BF-A5BB-7E9900E048B9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vbaide/V25/EN_US")

(:name "VBALOAD"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_VBALOAD"
 :synopsis "Loads a global VBA project into the current work session."
 :options ("-VBALOAD")
 :arguments "Displays a file selection dialog to choose a .dvb (or .vbi) VBA project file to load; the -VBALOAD form displays command prompts instead of the dialog."
 :description "Loads a VBA project stored in a DVB file so its modules and macros become available in the Macros dialog box; multiple projects and referenced projects can be loaded."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CA16C415-2CC0-4707-8018-23A464F019AD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vbaload/V25/EN_US")

(:name "VBAMAN"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_VBAMAN"
 :synopsis "Manages VBA project operations using a dialog box."
 :options NIL
 :arguments "Takes no arguments; opens the VBA Manager dialog box."
 :description "Loads, unloads, saves, creates, embeds, and extracts VBA projects through the VBA Manager dialog box."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E8DE3E52-F249-4147-94E3-C5436319846F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vbaman/V25/EN_US")

(:name "VBARUN"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_VBARUN"
 :synopsis "Runs a VBA macro."
 :options ("-VBARUN")
 :arguments "Opens the Macros (Run VBA macro) dialog box to run, edit, create, or delete a macro; the -VBARUN form displays options at the command line."
 :description "Provides access to run, create, edit, and delete VBA macros, configure VBA options, and access the VBA Manager."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9711DBC3-3A4C-4B38-93B9-AE7CD854CAB8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vbarun/V25/EN_US")

(:name "VBAUNLOAD"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_VBAUNLOAD"
 :synopsis "Unloads a global VBA project."
 :options NIL
 :arguments "Accepts an optional VBA project name; if omitted, the active global project is unloaded."
 :description "Removes (unloads) a global Visual Basic for Applications DVB project from memory."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F60C4525-DA15-47A1-8107-1C5CF107A958.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vbaunload/V25/EN_US")

(:name "VIEW"
 :category :VIEW
 :aliases ("DDVIEW" "EXPVIEWS" "V")
 :intl-name "_VIEW"
 :synopsis "Saves and restores named model space views, layout views, and preset views."
 :options NIL
 :arguments "Opens the View Manager (AutoCAD) or the Drawing Explorer Views dialog (BricsCAD); cannot be used transparently."
 :description "Saves specific views by name for later restoration and lets you view and modify named and preset views in the current drawing."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-157824E8-6791-410F-A412-E183D69F3D71.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_view/V25/EN_US")

(:name "VIEWBASE"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWBASE"
 :synopsis "Creates a base view from model space or Autodesk Inventor models."
 :options ("Model space" "File" "Select" "Remove" "Entire model" "Layout"
           "Representation" "Orientation" "Hidden Lines" "Scale" "Visibility"
           "Move" "Exit")
 :arguments "Select objects (or Enter for the entire model), specify the layout, pick the location of the base view, then place projected views and configure options."
 :description "Creates the initial base drawing view in a paper space layout from a 3D model, from which other associative orthographic and isometric views are derived; views update when the model changes."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E0F79E2F-8838-4470-B8D0-8626343A22D2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_viewbase/V25/EN_US")

(:name "VIEWDETAIL"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWDETAIL"
 :synopsis "Creates a detail view of a portion of a model documentation drawing view."
 :options ("Scale" "Hidden lines" "Tangent lines" "Anchor" "Geometry"
           "Annotation" "Identifier" "Label" "Boundary" "Model edge" "Move"
           "Exit")
 :arguments "Select the parent view, specify the center of the detail, choose the boundary type (circular or rectangular), then pick the location of the detail view in the layout."
 :description "Creates a magnified detail view (circular or rectangular) of an existing drawing view in a paper space layout, with configurable scale, display, and edge options."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EDA005E8-85E5-40DB-AB8E-B664B01627C4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_viewdetail/V25/EN_US")

(:name "VIEWEDIT"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWEDIT"
 :synopsis "Edits an existing model documentation drawing view."
 :options ("Representation" "Hidden Lines" "Scale" "Visibility" "Projection"
           "Depth" "Boundary" "Annotation" "Hatch" "Exit")
 :arguments "Select the drawing view(s) to edit (or Enter to select all views in the current layout), then change the available properties; the options offered depend on the view type."
 :description "Modifies properties such as scale and hidden-line visibility of drawing views created with VIEWBASE, VIEWSECTION, or VIEWDETAIL. Operates in paper space."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3DAE7BC9-8F39-484F-B0F8-C039510E4F22.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_viewedit/V25/EN_US")

(:name "VIEWPROJ"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWPROJ"
 :synopsis "Creates one or more projected views from an existing model documentation drawing view."
 :options ("Isometric geometry" "Exit")
 :arguments "Select the parent (base) view, then specify locations for the projected views; press Exit to finish."
 :description "Generates orthogonal and isometric projected views from an existing base drawing view in paper space; new views inherit scale and display settings from the parent and are aligned automatically."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DC444927-6392-4F3C-88FC-33BBDF9AC464.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_viewproj/V25/EN_US")

(:name "VIEWRES"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWRES"
 :synopsis "Sets the tessellation (view resolution) for curved objects in the current viewport."
 :options NIL
 :arguments "Prompts whether to do fast zooms, then a circle zoom percent (view resolution) value in the range 1-20000 (default 100)."
 :description "Controls how circles, arcs, splines, and arced polylines are approximated on screen; higher values make curves smoother but can increase regeneration time."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-77B1C617-E4BB-4D1E-823A-8E2B055B258E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_viewres/V25/EN_US")

(:name "VIEWSECTION"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWSECTION"
 :synopsis "Creates a section view of a 3D model that was created in AutoCAD or Autodesk Inventor."
 :options ("Full" "Half" "Offset" "Aligned" "Object" "Scale" "Hidden lines"
           "Tangent lines" "Anchor" "Geometry" "Annotation" "Identifier"
           "Label" "Depth" "Projection" "Rotate view" "Hatch" "Exit")
 :arguments "Select the parent view, define the section line (the points required depend on the section type: Full, Half, Offset, Aligned, or Object), then place the section view and configure options."
 :description "Generates a cross-section view of an existing drawing view in a paper space layout by cutting the 3D model with a section line; supports associative dimensions that update when the model changes."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7C281B02-D7D1-47FD-A1D4-0AF9E7544934.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_viewsection/V25/EN_US")

(:name "VIEWSECTIONSTYLE"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWSECTIONSTYLE"
 :synopsis "Creates and modifies section view styles."
 :options NIL
 :arguments "Takes no command-line arguments; opens the Section View Style Manager (AutoCAD) or the Drawing Explorer View Section Styles dialog (BricsCAD)."
 :description "Manages named section view styles that control the appearance of section views and section lines, including identifiers, arrows, hatching, and cutting plane lines."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-81DCE438-A0DF-4950-9380-4A190B3E684C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_viewsectionstyle/V25/EN_US")

(:name "VIEWUPDATE"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWUPDATE"
 :synopsis "Updates drawing views that have become out-of-date because the source model has changed."
 :options ("Select drawing views" "All")
 :arguments "Select the drawing views to update, or choose All to update every view in the current layout."
 :description "Manually refreshes drawing views created by VIEWBASE and VIEWSECTION when automatic updating is disabled."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8C6FECB1-F8FA-4AD4-8843-A94D02119514.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_viewupdate/V25/EN_US")

(:name "VLISP"
 :category :CUSTOMIZATION
 :aliases ("VLIDE")
 :intl-name "_VLISP"
 :synopsis "Displays the AutoLISP development environment."
 :options NIL
 :arguments "Takes no arguments; opens the LISP IDE (BLADE in BricsCAD; the Visual LISP IDE or Visual Studio Code in AutoCAD, per LISPSYS)."
 :description "Launches an integrated development environment for creating, testing, and debugging AutoLISP programs in an external window."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5601ACC6-C4F6-4375-9C2C-3DBCAE2880B1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vlisp/V25/EN_US")

(:name "VPCLIP"
 :category :VIEW
 :aliases NIL
 :intl-name "_VPCLIP"
 :synopsis "Redefines a layout viewport object while retaining its properties."
 :options ("Clipping Object" "Polygonal" "Delete")
 :arguments "Select the viewport to clip, then select a clipping object or specify a polygonal boundary; Delete removes the clip and restores the rectangular viewport."
 :description "Sets a new clipping boundary for a layout (paper space) viewport from a selected closed object or specified points, so only part of the drawing is displayed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D5FD4D1A-5785-4A8E-B0D1-D12079C0A4FF.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vpclip/V25/EN_US")

(:name "VPLAYER"
 :category :LAYER
 :aliases NIL
 :intl-name "_VPLAYER"
 :synopsis "Sets layer visibility and properties within layout viewports."
 :options ("?" "Color" "Ltype" "Lweight" "Pstyle" "Transparency" "Freeze"
           "Thaw" "Reset" "Removeoverrides" "Newfrz" "Vpvisdflt" "All" "Select"
           "Current" "Except current")
 :arguments "Choose an option (Freeze, Thaw, Color, Ltype, etc.), specify the affected layer(s), then choose the viewport scope (All, Select, Current, or Except current)."
 :description "Controls layer visibility, freezing, and per-viewport property overrides in paper space viewports, allowing different viewports to display distinct layer configurations."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EB4DA3DA-5466-4D48-9AEC-6828B82BDEF9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vplayer/V25/EN_US")

(:name "VPMAX"
 :category :VIEW
 :aliases NIL
 :intl-name "_VPMAX"
 :synopsis "Expands the current layout viewport for editing."
 :options NIL
 :arguments "Takes no arguments; in paper space with a single viewport it is selected automatically, otherwise select a viewport to maximize."
 :description "Maximizes the current viewport to fill the screen and switches to model space; use VPMIN to restore it."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-15D5EEC7-D131-49F6-89A7-424455480935.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vpmax/V25/EN_US")

(:name "VPMIN"
 :category :VIEW
 :aliases NIL
 :intl-name "_VPMIN"
 :synopsis "Restores the current layout viewport."
 :options NIL
 :arguments "Takes no arguments; restores the maximized viewport to its previous center point and magnification."
 :description "Minimizes a viewport that was maximized with VPMAX, returning it to its state before maximization."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A18E5FA1-2A4E-461B-A606-EFF5AB14E0E5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vpmin/V25/EN_US")

(:name "VPOINT"
 :category :VIEW
 :aliases ("-VIEWPOINT" "-VP" "-VPOINT" "VIEWPOINT")
 :intl-name "_VPOINT"
 :synopsis "Sets the viewing direction for a 3D visualization of the drawing."
 :options ("Rotate" "Plan" "Perspective" "Front clipping" "Back clipping")
 :arguments "Specify a view point by X,Y,Z coordinates, or choose Rotate to enter angles, or Plan view."
 :description "Changes the 3D viewpoint of the current viewport. The LookFrom widget or the Viewpoint Presets dialog offers an easier way to set the direction."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-82771983-982A-4F34-886E-FDAC966DF16D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vpoint/V25/EN_US")

(:name "VPORTS"
 :category :VIEW
 :aliases ("VIEWPORTS" "VPORT" "VW")
 :intl-name "_VPORTS"
 :synopsis "Creates multiple viewports in model space or in a layout (paper space)."
 :options ("?" "Save" "Restore" "Delete" "Single" "Join" "2" "3" "4"
           "Horizontal" "Vertical")
 :arguments "Opens the Viewports dialog box; the -VPORTS form prompts for an option (Save, Restore, Delete, Single, Join, or the number of viewports) and the layout arrangement."
 :description "Divides the drawing area into multiple rectangular viewports and saves, restores, and manages viewport configurations."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BF45C5E3-ACA3-436A-B8E9-A17001A6F1D8.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vports/V25/EN_US")

(:name "VPSCALE"
 :category :VIEW
 :aliases NIL
 :intl-name "_VPSCALE"
 :synopsis "Displays the scale of a selected layout viewport."
 :options NIL
 :arguments "Works only in a layout; when paper space is active it prompts to select the edge of a layout viewport, then reports that viewport scale."
 :description "An Express Tool (AutoCAD) and command (BricsCAD) that reports the scale factor of the current or selected layout viewport."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D8D8E81C-A6B0-4337-97AA-2CB060DA7659.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vpscale/V25/EN_US")

(:name "VPSYNC"
 :category :VIEW
 :aliases NIL
 :intl-name "_VPSYNC"
 :synopsis "Aligns the views in one or more adjacent layout viewports with a master (reference) viewport."
 :options NIL
 :arguments "Select the master (reference) viewport, then select the viewports to be aligned to it."
 :description "An Express Tool (AutoCAD) and command (BricsCAD) that synchronizes selected layout viewports to the view orientation and zoom of a master viewport. Works only in paper space."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1D273873-9F33-422A-95CD-45CD52623A7E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vpsync/V25/EN_US")

(:name "VSCURRENT"
 :category :VIEW
 :aliases NIL
 :intl-name "_VSCURRENT"
 :synopsis "Sets the visual style in the current viewport."
 :options ("2dwireframe" "Wireframe" "Hidden" "Realistic" "Conceptual" "Shaded"
           "Shaded with Edges" "Shades of Gray" "Sketchy" "X-ray" "Other" "?")
 :arguments "Enter a visual style option (such as 2dwireframe, Realistic, or Conceptual), or Other to name a visual style; ? lists the available styles."
 :description "Changes how objects are displayed in the current viewport by applying a named visual style that controls edge display, lighting, and shading."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7990D01B-F913-497A-8623-631646AF135B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vscurrent/V25/EN_US")

(:name "VSLIDE"
 :category :VIEW
 :aliases ("VS" "VSNAPSHOT")
 :intl-name "_VSLIDE"
 :synopsis "Displays an image slide file in the current viewport."
 :options NIL
 :arguments "Displays a file selection dialog to choose a slide file (SLD/SLB, or also WMF/EMF in BricsCAD) to view in the current viewport; with FILEDIA=0 a slide name (or library(slide)) can be typed. Use REDRAW to remove it."
 :description "Opens and displays a previously made slide image in the current viewport."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-255CE777-3419-4AC1-B3AF-C622EE84A78C.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vslide/V25/EN_US")

(:name "VTOPTIONS"
 :category :VIEW
 :aliases NIL
 :intl-name "_VTOPTIONS"
 :synopsis "Opens the view transition options dialog box."
 :options NIL
 :arguments "Takes no arguments; opens the View Transitions dialog (AutoCAD) or the Settings dialog with the View Transition Options category expanded (BricsCAD)."
 :description "Controls the system variables that determine when and how a change in view is displayed as a smooth transition (VTENABLE, VTDURATION, VTFPS)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-84A975F9-99B7-4791-9043-5D6FCEAA8FA2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_vtoptions/V25/EN_US")

(:name "WBLOCK"
 :category :BLOCK
 :aliases ("W")
 :intl-name "_WBLOCK"
 :synopsis "Saves selected objects or converts a block to a specified drawing file."
 :options ("-WBLOCK")
 :arguments "Opens the Write Block dialog box; the -WBLOCK form displays a file selection dialog for the output DWG name followed by command prompts (block source: Block, Entire drawing, or selected objects)."
 :description "Writes a block definition, the entire drawing, or selected objects out to a new external DWG file."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-297ED4C5-DADC-4C3B-B4FA-94C56A04721B.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_wblock/V25/EN_US")

(:name "WEBLIGHT"
 :category :RENDER
 :aliases NIL
 :intl-name "_WEBLIGHT"
 :synopsis "Creates a precise 3D representation (web) of the light intensity distribution of a light source."
 :options ("Name" "Intensity factor" "Status" "Photometry" "Color" "Web"
           "Shadow" "filterColor" "Exit")
 :arguments "Specify the source location and target location, then set options such as Name, Intensity factor, Status, Photometry, Web (IES file and rotations), Shadow, and Filter color. Requires LIGHTINGUNITS to be non-zero."
 :description "Creates a web light whose intensity distribution is defined by an IES photometric data file supplied by a lighting manufacturer."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-378DF00F-2595-4678-8B18-EA991A267E2F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_weblight/V25/EN_US")

(:name "WEDGE"
 :category :|3D|
 :aliases ("WE")
 :intl-name "_WEDGE"
 :synopsis "Creates a 3D solid in the shape of a wedge."
 :options ("Center" "Cube" "Length" "2Point")
 :arguments "Specify the first corner and the opposite corner of the base, then the height; or use Center to specify a center point, with Cube or Length options."
 :description "Creates a three-dimensional solid wedge whose sloped face tapers along the X axis; the height can be drawn in the positive or negative Z direction."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-479D1F58-6629-430B-8E8A-901D646A55E6.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_wedge/V25/EN_US")

(:name "WHOHAS"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_WHOHAS"
 :synopsis "Displays information about who has a drawing file open."
 :options NIL
 :arguments "Displays a file selection dialog to pick a DWG file, then reports the file path, the user login and computer name, and the time the drawing was opened."
 :description "Identifies which user currently has a specified drawing file open and when it was accessed."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7E20A4D7-EB74-4354-8ADE-7EF172F0E16D.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_whohas/V25/EN_US")

(:name "WIPEOUT"
 :category :DRAW
 :aliases NIL
 :intl-name "_WIPEOUT"
 :synopsis "Creates a wipeout object, and controls whether wipeout frames are displayed."
 :options ("Frames" "Polyline" "Undo" "Close")
 :arguments "Specify the first point and subsequent points of the polygonal boundary (Close/Undo to adjust), or use Polyline to select a closed polyline (then choose whether to erase it); Frames toggles frame display."
 :description "Creates a polygonal area that masks underlying objects with the current background color, with a frame that can be shown, hidden during plotting, or turned off."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4AD79F4F-A759-4310-A62D-4792FAA7B0EA.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_wipeout/V25/EN_US")

(:name "WMFIN"
 :category :FILE
 :aliases ("WI")
 :intl-name "_WMFIN"
 :synopsis "Imports a Windows metafile (WMF/EMF) into the current drawing."
 :options ("Scale" "Corner" "XYZ" "Rotate" "PScale" "PRotate")
 :arguments "Displays a file selection dialog to choose a WMF/EMF file, then prompts for the insertion point, X and Y scale, and rotation angle."
 :description "Imports vector (and in AutoCAD, block-referenced) data from a WMF/EMF file, letting you place, scale, and rotate the imported content."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EAC08DDA-5D62-4A2A-8A84-37F20779941A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_wmfin/V25/EN_US")

(:name "WMFOUT"
 :category :FILE
 :aliases ("WO")
 :intl-name "_WMFOUT"
 :synopsis "Saves objects from the current drawing to a Windows metafile."
 :options NIL
 :arguments "Displays a file selection dialog for the output file name (WMF, and in BricsCAD also SLD/EMF), then prompts to select the objects to export."
 :description "Exports selected drawing objects to a Windows metafile (WMF) format file."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6B7ECC84-F2D5-402C-8719-E8FE2171AE96.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_wmfout/V25/EN_US")

(:name "WORKSPACE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_WORKSPACE"
 :synopsis "Creates, modifies, and saves workspaces and makes a workspace current."
 :options ("Set Current" "Save As" "Edit" "Rename" "Delete" "Settings" "?")
 :arguments "Enter a workspace name to set it current, or choose an option (Save As, Edit, Rename, Delete, Settings, or ? to list workspaces)."
 :description "Manages workspace configurations, including creating, renaming, deleting, and switching the current workspace."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8B5DFCAD-7CE6-4C57-9CA3-5243E54D5EB1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_workspace/V25/EN_US")

(:name "WSSAVE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_WSSAVE"
 :synopsis "Saves the current workspace."
 :options ("-WSSAVE")
 :arguments "Opens the Save Workspace dialog box to name and save the current workspace; the -WSSAVE form prompts at the command line."
 :description "Saves the current arrangement of the user interface as a named workspace that can be recalled later."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3821F72C-A62E-4DB7-AEED-EEC09FD9622E.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_wssave/V25/EN_US")

(:name "WSSETTINGS"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_WSSETTINGS"
 :synopsis "Sets options for workspaces."
 :options NIL
 :arguments "Takes no arguments; opens the Workspace Settings dialog box (AutoCAD) or the Customize dialog box (BricsCAD)."
 :description "Configures workspace behavior such as display, menu order, and save settings for the user interface."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-97AAABD6-8232-43CD-9D97-ED13F13D2D80.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_wssettings/V25/EN_US")

(:name "XATTACH"
 :category :BLOCK
 :aliases ("XA")
 :intl-name "_XATTACH"
 :synopsis "Attaches selected DWG files as external references (xrefs)."
 :options NIL
 :arguments "Displays a file selection dialog to pick a DWG file, then, via the Attach External Reference dialog, specify the path type, reference type, insertion point, scale, and rotation."
 :description "Links an external drawing file into the current drawing as an xref, so changes to the referenced drawing appear when the current drawing is opened or reloaded."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BFD18916-9DFE-4FFF-8C98-4AE38A50A7F3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_xattach/V25/EN_US")

(:name "XCLIP"
 :category :BLOCK
 :aliases NIL
 :intl-name "_XCLIP"
 :synopsis "Crops the display of a selected external reference or block reference to a specified boundary."
 :options ("On" "Off" "Clipdepth" "Delete" "Generate Polyline" "New boundary"
           "Invert" "Polygonal" "Rectangular" "Select polyline")
 :arguments "Select the xref or block references, then choose an option (New boundary, On, Off, Clipdepth, Delete, or Invert) and define the boundary (Rectangular, Polygonal, or select a polyline)."
 :description "Defines a clipping boundary that controls which portion of an xref or block reference is visible; visibility of the boundary itself is governed by the XCLIPFRAME system variable."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-104EDB9F-F025-4F67-B5C9-B3F174CFE2F3.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_xclip/V25/EN_US")

(:name "XDATA"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_XDATA"
 :synopsis "Attaches extended object data (xdata) to a selected object."
 :options ("3Real" "DIR" "DISP" "DIST" "Hand" "Int" "LAyer" "LOng" "Pos" "Real"
           "SCale" "STr" "eXit")
 :arguments "Select an object, enter an application name (application ID), then add typed data items via the options (3Real, Int, Real, Dist, Layer, Str, etc.) until eXit."
 :description "An Express Tool (AutoCAD) and command (BricsCAD) that attaches application-specific extended entity data to an object; attached xdata can be viewed with XDLIST."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F0299B36-232F-446E-9F81-98F300B36991.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_xdata/V25/EN_US")

(:name "XDLIST"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_XDLIST"
 :synopsis "Lists the extended entity data (xdata) associated with an entity."
 :options ("*")
 :arguments "Select an entity, then enter an application name (or * / press Enter to list all applications)."
 :description "An Express Tool (AutoCAD) and command (BricsCAD) that retrieves and displays the extended data attached to a selected object for a given application name."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B3926E8E-1477-4086-8244-C813EB05FF04.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_xdlist/V25/EN_US")

(:name "XEDGES"
 :category :|3D|
 :aliases NIL
 :intl-name "_XEDGES"
 :synopsis "Creates wireframe geometry from the edges of a 3D solid, surface, mesh, region, or subobject."
 :options NIL
 :arguments "Select 3D solids, surfaces, meshes, regions, or subobjects (press and hold Ctrl to select faces, edges, and component objects); edges are extracted as 2D or wireframe geometry at the source location on the current layer."
 :description "Extracts edges from 3D objects, creating lines, arcs, splines, or 3D polylines along those edges."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6B6E69D0-62C1-4D96-B568-1818E3C997F4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_xedges/V25/EN_US")

(:name "XLINE"
 :category :DRAW
 :aliases ("INFLINE" "XL")
 :intl-name "_XLINE"
 :synopsis "Creates a construction line (xline) of infinite length."
 :options ("Point" "Hor" "Ver" "Ang" "Bisect" "Offset")
 :arguments "Specify a point then a through point; or choose an option first (Hor, Ver, Ang, Bisect, or Offset). The command repeats until you press Enter."
 :description "Creates infinitely long construction/reference lines that extend in both directions, used for trimming boundaries and alignment."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-40650DCE-E8CA-483C-8E25-7FA9AB6992C1.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_xline/V25/EN_US")

(:name "XLIST"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_XLIST"
 :synopsis "Lists the type, block name, layer name, color and linetype of a nested object in a block or an xref."
 :options ("-XLIST")
 :arguments "Select a nested object within a block or xref; its properties are displayed in a dialog box (or at the command line with the -XLIST form)."
 :description "An Express Tool (AutoCAD) and command (BricsCAD) that reports the properties of an object nested inside a block or external reference."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CDEF1C56-AFA4-4DE3-B01E-1662B8C33FBD.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_xlist/V25/EN_US")

(:name "XOPEN"
 :category :FILE
 :aliases NIL
 :intl-name "_XOPEN"
 :synopsis "Opens a selected drawing reference (xref) in a new window."
 :options NIL
 :arguments "Select an attached xref to open it for editing in a separate window/tab; if it contains nested xrefs, a dialog lets you choose which to open."
 :description "Opens an externally referenced drawing in its own window for editing."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6CD56F5F-AB89-482C-B1DC-57A95987ABED.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_xopen/V25/EN_US")

(:name "XPLODE"
 :category :MODIFY
 :aliases ("X")
 :intl-name "_XPLODE"
 :synopsis "Breaks a compound object into its component objects, with specified properties for the resulting objects."
 :options ("Individually" "All" "Color" "Layer" "LType" "LWeight" "ltScale"
           "Inherit from parent" "Explode")
 :arguments "Select objects to explode, choose Individually or Globally/All, then set the resulting objects' properties (Color, Layer, LType, LWeight, ltScale, or Inherit from parent block)."
 :description "Explodes compound objects while controlling the color, layer, linetype, lineweight, and linetype scale of the resulting objects. Does not work on xrefs, frozen-layer objects, or simple primitives."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FC4139AB-D527-4743-8E68-F83DA6E5D192.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_xplode/V25/EN_US")

(:name "XREF"
 :category :BLOCK
 :aliases ("XR" "CLASSICXREF" "ER" "EXTERNALREFERENCES")
 :intl-name "_XREF"
 :synopsis "Opens the External References palette (Attachments panel) for managing attached drawings."
 :options ("-XREF")
 :arguments "Takes no arguments; opens the External References palette / Attachments panel. The -XREF form displays options at the command line."
 :description "Starts the EXTERNALREFERENCES command, displaying the palette used to attach, overlay, and manage external reference drawings."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7DD70C3C-B8AD-40F1-8A69-5D1EECEAB013.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_xref/V25/EN_US")

(:name "ZOOM"
 :category :VIEW
 :aliases ("Z")
 :intl-name "_ZOOM"
 :synopsis "Increases or decreases the magnification of the view in the current viewport."
 :options ("All" "Center" "Dynamic" "Extents" "Previous" "Scale" "Window"
           "Object" "In" "Out" "Left" "Right" "Realtime")
 :arguments "Optionally a corner point of a window, or one of the keyword options: \"All\", \"Center\" (center point then magnification/height), \"Dynamic\", \"Extents\", \"Previous\", \"Scale\" (a value, optionally suffixed with x or xp), \"Window\" (two corner points), \"Object\" (a selection set), \"In\", \"Out\". With no argument it enters real-time zoom."
 :description "Changes the magnification of the view in the current viewport, like a camera zoom, without altering the absolute size of objects in the drawing. Provides options to view different portions and scales of the drawing (extents, window, scale factor, previous, object, etc.)."
 :availability :BOTH
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-66E7DB72-B2A7-4166-9970-9E19CC06F739.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_zoom/V25/EN_US")

)
