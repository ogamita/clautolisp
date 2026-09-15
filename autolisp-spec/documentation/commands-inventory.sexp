;;;; -*- Mode: Lisp; coding: utf-8 -*-
;;;; Commands inventory feeding the autolisp-spec Commands chapter.
;;;; Harvested from help.autodesk.com (2026 ENU) + help.bricsys.com (V25).
;;;; One plist per command, sorted by :NAME. Facts come only from the
;;;; cited vendor pages; an absent fact is NIL. Generated/merged by
;;;; scripts/merge-command-parts.lisp — do not hand-edit.
;;;; Keys, in order: NAME CATEGORY ALIASES INTL-NAME SYNOPSIS OPTIONS ARGUMENTS DESCRIPTION AVAILABILITY AUTOCAD-VERSIONS BRICSCAD-VERSIONS SOURCE-AUTOCAD SOURCE-BRICSCAD

(
(:name "-ACTUSERMESSAGE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_-ACTUSERMESSAGE"
 :synopsis "Inserts a user message into an action macro."
 :options ("Message to play during playback")
 :arguments "At the \"Message to play during playback\" prompt, enter up to 256 characters of message text."
 :description "Inserts a user message into an action macro. The message you enter is displayed in a dialog box when the action macro is played back, and the macro continues when the dialog box is dismissed."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-240E7E85-69FC-4919-863E-4E041B7A460B.htm"
 :source-bricscad NIL)

(:name "-ARCHIVE"
 :category :FILE
 :aliases NIL
 :intl-name "_-ARCHIVE"
 :synopsis "Packages the current sheet set files for storage."
 :options ("Sheet set name" "Create archive package" "Report only" "?")
 :arguments NIL
 :description "Packages the current sheet set files for storage. The -ARCHIVE command creates an archive package from a specified sheet set, and a report file is automatically included with archive packages."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-22509544-FC8E-4E87-9BFA-F9D896B96557.htm"
 :source-bricscad NIL)

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

(:name "-ATTACH"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-ATTACH"
 :synopsis "Inserts references to external files such as other drawings, raster images, point clouds, coordination models, and underlays."
 :options ("Path to file" "Insertion point" "Base image size" "Scale factor"
           "Rotation" "Reference type" "PScale" "PRotate" "?" "*")
 :arguments NIL
 :description "Inserts references to external files such as other drawings, raster images, point clouds, coordination models, and underlays (DWG, DWF, DWFx, PDF, and DGN files). Point clouds and coordination models are unavailable in AutoCAD LT, and the command prompts differ based on the file type being attached."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A58A40E8-6586-4025-8F76-E05AA0E67B9A.htm"
 :source-bricscad NIL)

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

(:name "-BREPLACE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-BREPLACE"
 :synopsis "Replaces specified block references with a different block."
 :options ("Blocks to Replace" "Substitute Block" "Name" "Pick" "External File"
           "File as a Block" "?")
 :arguments NIL
 :description "Replaces one or more block references in a drawing with a different block. The replacement block can be selected from the current drawing, imported from an external file, or inserted as a drawing file."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-06BD6E4D-5060-4628-B4DC-88BE802AD32E.htm"
 :source-bricscad NIL)

(:name "-BSEARCH"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-BSEARCH"
 :synopsis "Converts the selected entities and identical instances into blocks."
 :options ("Objects to convert to blocks" "Instances" "Source Objects Only"
           "New block" "Pick" "Enter block name" "Block from file"
           "File as block")
 :arguments NIL
 :description "Converts selected geometry into blocks at the command prompt. Users can choose whether to convert instances alongside source objects or source objects only, then select or create a block for the conversion."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6C8167C4-2849-4823-8003-37B3C79941F5.htm"
 :source-bricscad NIL)

(:name "-BVSTATE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-BVSTATE"
 :synopsis "Creates, sets, or deletes a visibility state in a dynamic block."
 :options ("New" "Hide All" "Show All" "Current Visibility" "Set" "Delete")
 :arguments NIL
 :description "Creates, sets, or deletes a visibility state in a dynamic block at the command prompt. New states can be created hiding all objects, showing all objects, or matching the current visibility, and existing states can be set as current or removed entirely."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-02DEB284-3E53-4AFA-8924-87864CBB330B.htm"
 :source-bricscad NIL)

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

(:name "-COMPARE"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_-COMPARE"
 :synopsis "Compares a specified drawing to the current drawing."
 :options ("Enter name of drawing to compare")
 :arguments "Type -COMPARE, then at the \"Enter name of drawing to compare:\" prompt specify the location and name of the drawing to compare with the current drawing."
 :description "Compares the current drawing with another drawing file. The DWG Compare toolbar displays upon execution, enabling users to identify and visualize differences between the two drawings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5EBAB3C3-AE1F-42FC-BE56-F018E2E17E0E.htm"
 :source-bricscad NIL)

(:name "-COORDINATIONMODELATTACH"
 :category :BLOCK
 :aliases ("-CMATTACH")
 :intl-name "_-COORDINATIONMODELATTACH"
 :synopsis "Inserts references to coordination models such as NWD and NWC Navisworks files."
 :options ("Path to file" "Insertion point" "Scale factor" "Rotation")
 :arguments NIL
 :description "Inserts references to coordination models such as NWD and NWC Navisworks files. When you attach a coordination model, you link that referenced file to the current drawing, and any changes to the referenced file display in the current drawing when it opens or reloads."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FE727B97-4918-480C-9C90-DF148371BE47.htm"
 :source-bricscad NIL)

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

(:name "-DGNATTACH"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-DGNATTACH"
 :synopsis "Attach a DGN underlay from the command line."
 :options ("Path to DGN File to Attach" "Enter Name of Model or ?"
           "Enter Model(s) to list <*>"
           "Conversion Units (Master Units or Sub Units)" "Insertion Point"
           "Scale Factor" "Rotation")
 :arguments "Supply the DGN file path, then the model name, insertion point coordinates, scale factor, and rotation angle (entered at the command prompt or selected onscreen)."
 :description "Attaches a DGN file as an underlay from the command line, linking that referenced file to the current drawing. Any changes to the referenced file are displayed in the current drawing when it is opened or reloaded."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-05666320-4737-4599-9D0A-03165E161657.htm"
 :source-bricscad NIL)

(:name "-DGNBIND"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-DGNBIND"
 :synopsis "Binds DGN underlays to the current drawing."
 :options ("DGN Underlay Names")
 :arguments NIL
 :description "Binds DGN underlays to the current drawing, converting a specified DGN reference into a block to make it permanent. DGN-dependent named objects (like layer names) are added to the drawing, with the vertical bar replaced by a number between dollar signs."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-757D2268-C0BB-465D-A304-321FCFEE80A1.htm"
 :source-bricscad NIL)

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

(:name "-DIMINSPECT"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_-DIMINSPECT"
 :synopsis "Adds or removes inspection information from a selected dimension."
 :options ("Add Inspection Data" "Remove" "Selection dimensions"
           "Shape option (Round, Angular, None)" "Label data" "Inspection rate")
 :arguments NIL
 :description "Adds or removes inspection information from a selected dimension through command-line prompts. When adding inspection data, users specify shape options, labels, and inspection rates."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A8AC3ACB-6722-44E1-B4F8-1E4F1CE45B78.htm"
 :source-bricscad NIL)

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

(:name "-DWFATTACH"
 :category :BLOCK
 :aliases NIL
 :intl-name "_-DWFATTACH"
 :synopsis "Attaches a DWF or DWFx file as an underlay from the Command prompt."
 :options ("Path to DWF file" "Name of sheet" "?" "Insertion point"
           "Scale factor" "Rotation")
 :arguments "Supplies the DWF/DWFx file path, the sheet name (or ? to list sheets), an insertion point, a scale factor, and a rotation angle."
 :description "From the Command prompt, attaches a DWF or DWFx file as an underlay linked to the current drawing; changes to the referenced file display automatically when the drawing is opened or reloaded."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8CBD320C-1A80-43A0-B8C1-BC9A35AC5960.htm"
 :source-bricscad NIL)

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

(:name "-EXPORT"
 :category :FILE
 :aliases NIL
 :intl-name "_-EXPORT"
 :synopsis "Creates a DWF, DWFx, or PDF file from the command line."
 :options ("File Format" "Plot Area" "Detailed Plot Configuration" "Paper Size"
           "Paper Units" "Drawing Orientation" "Plot Scale"
           "Plot with Plot Styles" "Plot Style Table Name"
           "Plot with Lineweights")
 :arguments "Supplies interactive prompt answers for file format (DWF/DWFx/PDF), plot area, paper size and units, orientation, plot scale, and plot-style/lineweight options, suitable for scripting."
 :description "The command-prompt version of EXPORTDWF, EXPORTDWFX, and EXPORTPDF; provides an interface for publishing drawing sheets that can be controlled by a script."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EC98464B-D222-4673-BBE1-AF4B20EBF150.htm"
 :source-bricscad NIL)

(:name "-FIND"
 :category :TEXT
 :aliases NIL
 :intl-name "_-FIND"
 :synopsis "Searches for the text that you specify in the entire drawing, the current space or layout, or selected objects."
 :options ("What To Find" "Find Where" "Entire drawing"
           "Current space or layout" "Selected objects" "Previous" "Next")
 :arguments "Supplies the text string to find, the search scope (entire drawing, current space or layout, or selected objects), and navigation keywords to cycle through matches."
 :description "Locates specified text throughout a drawing or within a defined scope; its behavior can be customized with related commands controlling which object types are included and how text comparisons are performed."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F207F801-0111-49C1-9A79-2AD3C8746EE1.htm"
 :source-bricscad NIL)

(:name "-GRAPHICSCONFIG"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_-GRAPHICSCONFIG"
 :synopsis "Sets hardware acceleration on or off and provides access to display performance options on the command line."
 :options ("Acceleration" "Hardware" "Software" "Adaptive Degradation"
           "General Options" "Rendering" "Plot Emulation" "Exit")
 :arguments "Supplies keyword answers to the graphics-performance prompts (acceleration on/off, hardware/software mode and sub-options, adaptive degradation, general options, rendering, plot emulation)."
 :description "Displays graphics performance options at the command line and provides access to advanced graphics settings unavailable in the Graphics Performance dialog box, controlling hardware acceleration and display quality settings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0A5B89D1-0A3F-4895-8392-4FAF876D5048.htm"
 :source-bricscad NIL)

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

(:name "-IMAGEADJUST"
 :category :MODIFY
 :aliases NIL
 :intl-name "_-IMAGEADJUST"
 :synopsis "Controls the brightness, contrast, and fade values of images."
 :options ("Brightness" "Contrast" "Fade")
 :arguments "After selecting one or more images, supplies brightness, contrast, and fade values via command-line prompts."
 :description "Adjusts image display properties from the command line; multiple images can be selected simultaneously to modify their brightness, contrast, and fade settings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-27E2796C-642F-4649-A903-5FE6597263C4.htm"
 :source-bricscad NIL)

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

(:name "-LAYDEL"
 :category :LAYER
 :aliases NIL
 :intl-name "_-LAYDEL"
 :synopsis "Deletes all objects on a layer and purges the layer."
 :options ("Select object on layer to delete" "Undo" "Name" "?")
 :arguments "Supplies either a selected object on the target layer or the layer name (Name keyword, or ? to list), then confirms deletion."
 :description "Removes all objects on a specified layer and then purges that layer from the drawing, at the Command prompt."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D34784C7-4C6F-4DCE-B0F2-A26E97BD01F0.htm"
 :source-bricscad NIL)

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

(:name "-LAYMCH"
 :category :LAYER
 :aliases NIL
 :intl-name "_-LAYMCH"
 :synopsis "Changes the layer of a selected object to match the layer of a selected destination object."
 :options ("Select Objects" "Select Object on Destination Layer" "Name")
 :arguments "Supplies the objects to change, then a selected object on the destination layer (or the layer name via the Name keyword)."
 :description "If you create an object on the wrong layer, you can change its layer by selecting an object on the destination layer; reassigns the selected objects' layer to match the referenced layer."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EB2CEB75-FF85-4719-94DF-9A9DC8BFA8A7.htm"
 :source-bricscad NIL)

(:name "-LAYMRG"
 :category :LAYER
 :aliases NIL
 :intl-name "_-LAYMRG"
 :synopsis "Merges selected layers into a target layer at the Command prompt."
 :options ("Select object on layer to merge" "Select object on target layer"
           "Name" "?" "Do you wish to continue? (Yes/No)")
 :arguments "Supplies the source layer(s) (by selected object or Name/? keyword), the target layer, and a Yes/No confirmation to continue."
 :description "Combines source layers into a designated target layer; the source layers are deleted after the merge, and the user is prompted to confirm before it executes."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0976544F-76F9-444C-86D3-91BEAABECCD8.htm"
 :source-bricscad NIL)

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

(:name "-LWEIGHT"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_-LWEIGHT"
 :synopsis "Sets the current lineweight, lineweight display options, and lineweight units."
 :options ("Default Lineweight" "?")
 :arguments "Supplies a default lineweight value (such as BYLAYER, BYBLOCK, or DEFAULT), or ? to list the valid lineweight values in the current units."
 :description "Configures the default lineweight for objects and controls how lineweights are displayed; values can be set to fixed settings like BYLAYER, BYBLOCK, or DEFAULT, in inches or millimeters."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B67E6B06-D2FE-49FB-8289-96DBD74F8A0C.htm"
 :source-bricscad NIL)

(:name "-MARKUPASSIST"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_-MARKUPASSIST"
 :synopsis "Analyzes an imported markup and can help place text callouts and revision clouds faster and with less manual effort."
 :options NIL
 :arguments NIL
 :description "Processes an imported markup document to assist in positioning text callouts and revision clouds more efficiently and with reduced manual work."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-26A9073B-A2E2-4E2C-AB90-53614C9F9795.htm"
 :source-bricscad NIL)

(:name "-MARKUPIMPORT"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_-MARKUPIMPORT"
 :synopsis "Imports a marked up drawing (image/pdf) in-place into your DWG as a new trace."
 :options NIL
 :arguments NIL
 :description "Imports a marked-up drawing in image or PDF format directly into the DWG, where it becomes a new trace object positioned in-place."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5B1F0D89-D858-45DB-89C5-4093037DF959.htm"
 :source-bricscad NIL)

(:name "-MLEDIT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_-MLEDIT"
 :synopsis "Edits multiline intersections, breaks, and vertices."
 :options ("CC" "OC" "MC" "CT" "OT" "MT" "CJ" "AV" "DV" "CS" "CA" "WA")
 :arguments NIL
 :description "Modifies multiline objects by creating various types of intersections (closed-cross, open-cross, merged-cross, closed-tee, open-tee, merged-tee, and corner joints), adding or removing vertices, creating visual breaks, and rejoining cut segments."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-92446C44-2F3B-464B-8F8E-6CD8D96BC8EC.htm"
 :source-bricscad NIL)

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

(:name "-PAGESETUP"
 :category :PLOT
 :aliases NIL
 :intl-name "_-PAGESETUP"
 :synopsis "Modifies the current page layout settings for the plotting device, paper size, plot scale, and several other settings in the command line."
 :options ("Display" "Extents" "Limits" "Layout" "View" "Window" "Fit" "Center"
           "Portrait" "Landscape" "Yes" "No" "As displayed" "legacy Wireframe"
           "legacy Hidden" "Visual styles" "Rendered" "Inches" "Millimeters")
 :arguments "Responds in order to prompts for: output device name, paper size, paper units, drawing orientation, plot upside down, plot area, plot scale, plot offset, plot with plot styles, plot style table name, plot with lineweights, and shade plot setting."
 :description "Configures page layout parameters via command-line prompts, allowing adjustment of output devices, paper dimensions, orientation, plot area boundaries, scaling, and visual rendering options for plotting or printing drawings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8BCC8A24-E396-4FFB-BA91-10D8DCB3359E.htm"
 :source-bricscad NIL)

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

(:name "-PDFSHXTEXT"
 :category :TEXT
 :aliases NIL
 :intl-name "_-PDFSHXTEXT"
 :synopsis "Converts the SHX geometry imported from PDF files into individual multiline text objects from the command line."
 :options ("Select Objects" "Settings" "Add Font" "Remove Font"
           "Success Threshold" "Layer" "Best Match")
 :arguments NIL
 :description "Processes geometric objects representing SHX text that was imported from PDF files. It lets users configure font matching settings, specify layer assignment, and determine whether the best-matching font or the first acceptable match is used for the conversion."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-178F4A46-2D7B-419D-BC4D-F7F3BCA87E40.htm"
 :source-bricscad NIL)

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

(:name "-PLOTSTAMP"
 :category :PLOT
 :aliases NIL
 :intl-name "_-PLOTSTAMP"
 :synopsis "Places a plot stamp on a specified corner of each drawing and logs it to a file."
 :options ("On" "Off" "Fields" "User fields" "Log file" "Location"
           "Text Properties" "Units")
 :arguments "Responds in order to prompts for: On/Off status, Fields selection, User-defined fields, Log file configuration, Location (TL/TR/BL/BR, orientation, offset), Text properties (font, height, line wrapping), and Units (Inches/Millimeters/Pixels)."
 :description "Adds plot stamp information (such as drawing name, date/time, and scale) to plotted drawings. It can be integrated into plotting scripts and is configured through various prompts, with settings stored in PSS files as defaults."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C137FAE3-04A1-4BDE-8D64-D4C969E52060.htm"
 :source-bricscad NIL)

(:name "-PLOTSTYLE"
 :category :PLOT
 :aliases NIL
 :intl-name "_-PLOTSTYLE"
 :synopsis "Lists all available plotstyles in the current drawing and to set a plotstyle current."
 :options ("?" "Current")
 :arguments NIL
 :description "Displays available plot styles from the attached plot style table and enables users to designate a plot style for newly created objects."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-559D1E6D-23CD-4BF3-A6E4-42FF90E9F2C2.htm"
 :source-bricscad NIL)

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

(:name "-VPOINT"
 :category :VIEW
 :aliases NIL
 :intl-name "_-VPOINT"
 :synopsis "Sets the viewing direction for a 3D visualization of the drawing."
 :options ("View Point" "Rotate" "Compass and Axis Tripod")
 :arguments "Supplies either a vector coordinate (View Point), two angle values (Rotate: first angle in the XY plane from the X axis, second angle from the XY plane), or interactive compass and axis tripod selection."
 :description "Defines how a 3D drawing appears by specifying a viewing direction, as if observing from a particular point back toward the origin. It offers multiple methods for establishing this perspective."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1E89B0D5-BFE2-4D2C-8396-07929A9416E8.htm"
 :source-bricscad NIL)

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

(:name "3DALIGN"
 :category :MODIFY
 :aliases NIL
 :intl-name "_3DALIGN"
 :synopsis "Aligns objects with other objects in 2D and 3D."
 :options ("Select objects" "Base point" "Second point" "Third point"
           "Continue" "Copy" "First destination point"
           "Second destination point" "Third destination point" "Exit")
 :arguments NIL
 :description "Moves and rotates selected objects so their base points and X/Y axes align with a destination in 3D space. It supports dynamic UCS for alignment with solid object faces and allows up to three points on source and destination objects to define the alignment."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-26823DD2-BAA5-4494-81A0-713B746DD94B.htm"
 :source-bricscad NIL)

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

(:name "3DCLIP"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DCLIP"
 :synopsis "Opens the Adjust Clipping Planes window, where you can specify what portions of a 3D model to display."
 :options NIL
 :arguments NIL
 :description "Provides a viewing interface for controlling which parts of a 3D model are visible by adjusting clipping planes. This is primarily a visualization tool, distinct from creating permanent sections using related commands like SECTIONPLANE or SECTION."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EB201BB0-E1DD-41C5-AF2D-F7EB97CF666B.htm"
 :source-bricscad NIL)

(:name "3DCORBIT"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DCORBIT"
 :synopsis "Rotates the view in 3D space with continuous motion."
 :options NIL
 :arguments NIL
 :description "Enables viewing of entire drawings or selected objects from different angles, maintaining continuous rotation while active, with additional options available via the right-click menu. Performance may be affected on large models."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-37B17D6B-2B21-4D41-9769-27CDEBD663D2.htm"
 :source-bricscad NIL)

(:name "3DDISTANCE"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DDISTANCE"
 :synopsis "Starts the interactive 3D view and makes objects appear closer or farther away."
 :options NIL
 :arguments NIL
 :description "When active, the cursor displays as a line with opposing arrows. Users click and drag in the viewport to adjust camera position: dragging upward moves the camera closer (enlarging objects), while dragging downward moves it away (reducing their size)."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-34CE9B45-F3CB-44BE-978B-6450C5D0B194.htm"
 :source-bricscad NIL)

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

(:name "3DEDITBAR"
 :category :MODIFY
 :aliases NIL
 :intl-name "_3DEDITBAR"
 :synopsis "Reshapes splines and NURBS surfaces, including their tangency properties."
 :options ("Select a NURBS Surface or Curve to Edit"
           "Select Point on Curve or Select Point on NURBS Surface"
           "Base Point" "Displacement" "Undo" "Exit")
 :arguments NIL
 :description "Enables modification of splines and NURBS surfaces using a 3D Edit Bar gizmo with multiple grip types. Users can move points, adjust tangent directions and magnitudes, and reshape objects in the U, V, and W directions on surfaces."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5A1D1B60-B9DF-447F-BA38-188EE797EF9B.htm"
 :source-bricscad NIL)

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

(:name "3DFLY"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DFLY"
 :synopsis "Changes the 3D view in a drawing interactively to create the appearance of flying through the model."
 :options ("W (forward)" "A (left)" "S (back)" "D (right)"
           "F (toggle between walk and flight)")
 :arguments NIL
 :description "Activates a fly mode in the current viewport that lets you navigate through or around a 3D model. Flight direction is controlled with the arrow keys or the W, A, S, D, and F keys, and the Position Locator window shows the top-view position by default."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6A1B8B91-AF54-419D-9AD0-0CCE864FC971.htm"
 :source-bricscad NIL)

(:name "3DFORBIT"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DFORBIT"
 :synopsis "Rotates the view in 3D space without constraining roll."
 :options NIL
 :arguments NIL
 :description "Activates a 3D Free Orbit view in the current viewport and displays an arcball to help define the viewing angle. Unlike 3DORBIT, 3DFORBIT does not constrain the orbit to a vertical or horizontal plane."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8EE0E22A-1D66-40C6-9AEB-78F74AEB47E7.htm"
 :source-bricscad NIL)

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

(:name "3DMOVE"
 :category :MODIFY
 :aliases NIL
 :intl-name "_3DMOVE"
 :synopsis "Displays the 3D Move gizmo to aid in moving 3D objects a specified distance in a specified direction."
 :options ("Select objects" "Stretch point" "Copy" "Base point" "Second point"
           "Displacement")
 :arguments "Select objects to move, then specify a base point and a second point of displacement (or use the Displacement/Copy options)."
 :description "The 3D Move gizmo lets you move selected objects and subobjects freely or constrained to an axis or plane. The gizmo appears at the center of the selected 3D objects by default and offers options for alignment and for switching gizmos via the shortcut menu."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-35FD374D-CD9F-4EC6-B50E-7C368B67DFB5.htm"
 :source-bricscad NIL)

(:name "3DORBIT"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DORBIT"
 :synopsis "Provides interactive viewing in 3D with the mouse."
 :options NIL
 :arguments NIL
 :description "3DORBIT activates a 3D Orbit view in the current viewport and the 3D Orbit cursor icon appears; you cannot edit objects while it is active. Dragging horizontally moves the camera parallel to the XY plane of the WCS, and dragging vertically moves the camera along the Z axis."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-85CE824C-0AF4-4890-8487-ADBC92BF08F1.htm"
 :source-bricscad NIL)

(:name "3DORBITCTR"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DORBITCTR"
 :synopsis "Sets a specific center of rotation in 3D Orbit view."
 :options NIL
 :arguments "Specify the center of rotation with the pointing device or by entering coordinates."
 :description "Starts a 3D Orbit view and uses a center of rotation that you specify, either with your pointing device or by entering coordinates. If you specify a point outside the current view, the specified point is ignored and the default center of rotation is used instead."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-85427F3B-0880-4B28-9E26-85BE84FFEB80.htm"
 :source-bricscad NIL)

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

(:name "3DPAN"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DPAN"
 :synopsis "Shifts the view without changing the viewing direction or magnification."
 :options NIL
 :arguments NIL
 :description "Shifts the view without changing the viewing direction or magnification. The page states that 3DPAN has been merged with the PAN command."
 :availability :AUTOCAD-ONLY
 :autocad-versions "merged with the PAN command"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8D216DAA-9C16-4C7C-949A-A244E104B1D3.htm"
 :source-bricscad NIL)

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

(:name "3DPRINT"
 :category :PLOT
 :aliases NIL
 :intl-name "_3DPRINT"
 :synopsis "Specifies 3D Plot settings, and prepares your drawing for 3D printing."
 :options NIL
 :arguments "Select the objects to prepare for 3D printing, then interact with the 3D Print Options dialog box."
 :description "After you select objects to print, the command displays the 3D Print Options dialog box and optionally launches Autodesk Print Studio (if previously installed). Print Studio offered tools for preparing models for specific printers and materials, though it is no longer available for download."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-117F46FA-AD52-4436-8972-63E419C72F86.htm"
 :source-bricscad NIL)

(:name "3DPRINTSERVICE"
 :category :PLOT
 :aliases NIL
 :intl-name "_3DPRINTSERVICE"
 :synopsis "Creates an STL file that can be sent to a 3D printing service."
 :options NIL
 :arguments "Select solids or watertight meshes, then interact with the 3D Print Options and Create STL File dialog boxes."
 :description "After you select objects to print, the 3D Print Options dialog box and the Create STL File dialog box are displayed. You select 3D solids or watertight meshes (mesh objects with no gaps), and only geometry within selected blocks and xrefs is included in the output file."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-68587522-C86C-4C41-B973-E68D950C6F76.htm"
 :source-bricscad NIL)

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

(:name "3DSCALE"
 :category :MODIFY
 :aliases NIL
 :intl-name "_3DSCALE"
 :synopsis "In a 3D view, displays the 3D Scale gizmo to aid in resizing 3D objects."
 :options ("Select objects" "Specify base point" "Pick a scale axis or plane"
           "Specify scale factor" "Copy" "Reference")
 :arguments "Select objects, specify a base point, pick a scale axis or plane, then specify a scale factor (or use the Reference/Copy options)."
 :description "The 3D Scale gizmo lets you resize selected objects and subobjects along an axis or plane, or uniformly. A shortcut menu provides options for alignment, movement, or switching to another gizmo."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DCF3573A-268A-42D3-92F7-7B8A290C8427.htm"
 :source-bricscad NIL)

(:name "3DSIN"
 :category :FILE
 :aliases NIL
 :intl-name "_3DSIN"
 :synopsis "Imports a 3ds Max (3DS) file."
 :options NIL
 :arguments "Select a file in the 3D Studio File Import dialog box, then configure settings in the 3D Studio File Import Options dialog box."
 :description "Imports a 3ds Max (3DS) file; importable data includes meshes, materials, mappings, lights, and cameras, while procedural materials, smoothing groups, and keyframe data cannot be imported. You select a file via the 3D Studio File Import dialog box, then configure settings in the 3D Studio File Import Options dialog box."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A28A2118-11C4-49D3-B8E5-A99EE46C1D32.htm"
 :source-bricscad NIL)

(:name "3DSWIVEL"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DSWIVEL"
 :synopsis "Changes the target of the view in the direction that you drag."
 :options NIL
 :arguments NIL
 :description "Simulates panning with a camera in the direction that you drag; the target of the view changes. You can swivel the view along the XY plane or along the Z axis."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D73E5086-144A-42F4-A7AB-2506BFA562EE.htm"
 :source-bricscad NIL)

(:name "3DWALK"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DWALK"
 :synopsis "Changes the 3D view in a drawing interactively to create the appearance of walking through the model."
 :options NIL
 :arguments ""
 :description "Activates a walk mode in the current viewport, allowing interactive navigation through a 3D model. You control the direction of movement with the keyboard and the viewing direction with the mouse, and can toggle to fly mode."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6AFE55B7-C031-40C7-AB11-A2EE566A65F9.htm"
 :source-bricscad NIL)

(:name "3DZOOM"
 :category :VIEW
 :aliases NIL
 :intl-name "_3DZOOM"
 :synopsis "Zooms in and out in a perspective view."
 :options ("All" "Extents" "Window" "Previous" "Object" "Real time")
 :arguments ""
 :description "Zooms in and out in a perspective view, simulating moving the camera closer to or farther from the target. It changes how objects appear without altering the actual camera position."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0F2FE0AA-01AD-47B2-9923-06AACECEC8FD.htm"
 :source-bricscad NIL)

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

(:name "ACADINFO"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_ACADINFO"
 :synopsis "Creates a file that stores information about your AutoCAD installation and current setup."
 :options NIL
 :arguments ""
 :description "An Express Tool that generates a text file named acadinfo.txt containing general installation details, file-loading information (including loaded ARX applications for troubleshooting), and system variable settings useful for comparing configurations across installations."
 :availability :AUTOCAD-ONLY
 :autocad-versions "Express Tool"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6921516E-3158-43AF-9612-CA7A8BBD6FAC.htm"
 :source-bricscad NIL)

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

(:name "ACTBASEPOINT"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_ACTBASEPOINT"
 :synopsis "Inserts a base point or base point prompt in an action macro."
 :options ("Base point")
 :arguments ""
 :description "Inserts a pause during action macro recording that prompts for a base point. When the macro plays back, it pauses until a point is specified, and subsequent actions are positioned relative to that base point."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F2AC63E6-7DA4-4501-A6A7-BC152392256C.htm"
 :source-bricscad NIL)

(:name "ACTIVITYINSIGHTSCLOSE"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_ACTIVITYINSIGHTSCLOSE"
 :synopsis "Closes the Activity Insights palette which displays activities for the current drawing."
 :options NIL
 :arguments ""
 :description "Closes the Activity Insights palette. This palette is used to view teammate contributions to shared drawing files and compare version histories in collaborative AutoCAD environments."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-236D94C3-FAD9-4F45-832F-A76D71C0EAB6.htm"
 :source-bricscad NIL)

(:name "ACTIVITYINSIGHTSOPEN"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_ACTIVITYINSIGHTSOPEN"
 :synopsis "Opens the Activity Insights palette to view activities for the current drawing."
 :options NIL
 :arguments ""
 :description "Opens the Activity Insights palette, enabling users to monitor teammate contributions to shared drawing files. Once open, the palette supports filtering activities by date, user, activity type, or file name."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8FB3681A-F022-466E-B5C6-C13B0758EA3A.htm"
 :source-bricscad NIL)

(:name "ACTMANAGER"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_ACTMANAGER"
 :synopsis "Manages action macro files."
 :options NIL
 :arguments ""
 :description "Displays the Action Macro Manager, which allows users to copy, rename, modify, or delete action macro files."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1DA03958-D894-4FD4-BCA2-42C5517D2FE3.htm"
 :source-bricscad NIL)

(:name "ACTRECORD"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_ACTRECORD"
 :synopsis "Starts the recording of an action macro."
 :options NIL
 :arguments ""
 :description "Starts recording an action macro. The sequence of commands you enter is captured in a script from the time you start recording until you stop (by right-clicking and choosing Action Recorder > Stop, or entering ACTSTOP)."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FC7560BC-9367-49C2-A813-288AC89E8907.htm"
 :source-bricscad NIL)

(:name "ACTSTOP"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_ACTSTOP"
 :synopsis "Stops the Action Recorder and provides the option of saving the recorded actions to an action macro file."
 :options NIL
 :arguments ""
 :description "Stops the Action Recorder. When recording is halted, the captured actions are saved to an action macro file, with the Action Macro dialog box appearing by default unless suppressed. The page also references a command-line variant, -ACTSTOP."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-94B6E003-B7BF-4A65-8E62-AF92D757C43B.htm"
 :source-bricscad NIL)

(:name "ACTUSERINPUT"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_ACTUSERINPUT"
 :synopsis "Pauses action macro playback to allow user input at specified points."
 :options NIL
 :arguments ""
 :description "Inserts a pause in an action macro that halts execution during playback to wait for user input. The pause point can be set on any value node in the Action Tree and supports input types such as coordinates, measurements, or numeric values."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6E613662-D0B1-4AD2-803A-15C00070FDDE.htm"
 :source-bricscad NIL)

(:name "ACTUSERMESSAGE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_ACTUSERMESSAGE"
 :synopsis "Inserts a user message into an action macro."
 :options NIL
 :arguments ""
 :description "Opens the Insert User Message dialog where text can be entered. When the action macro plays back, the message displays in a dialog box and macro execution resumes once the dialog is dismissed. The page also references a command-line variant, -ACTUSERMESSAGE."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9893C613-2DD1-4E14-B830-1DEF59D971F2.htm"
 :source-bricscad NIL)

(:name "ADCCLOSE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_ADCCLOSE"
 :synopsis "Closes DesignCenter."
 :options NIL
 :arguments ""
 :description "Closes the DesignCenter window, which provides functionality for locating content such as drawing files, block definitions, and hatches."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5ACFF611-AC97-4EBA-AA23-83530C0EFE26.htm"
 :source-bricscad NIL)

(:name "ADCENTER"
 :category :BLOCK
 :aliases NIL
 :intl-name "_ADCENTER"
 :synopsis "Manages and inserts content such as blocks, xrefs, and hatch patterns."
 :options NIL
 :arguments ""
 :description "Opens the DesignCenter window, which organizes access to drawing content including blocks, hatches, and external files. Users can locate and insert design elements into their drawings through a dedicated interface."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-00527F82-BE93-4E36-AA2E-35B042059347.htm"
 :source-bricscad NIL)

(:name "ADCNAVIGATE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_ADCNAVIGATE"
 :synopsis "Loads a specified drawing file, folder, or network path in the DesignCenter Folders tab."
 :options NIL
 :arguments "A pathname string: either a folder path or a folder path plus a filename (local drive or mapped drive); UNC network paths are not supported."
 :description "Navigates to and opens a specified drawing file or folder within the DesignCenter Folders tab. It works with local paths and mapped drives but does not support UNC network paths, prompting for the pathname at the command line."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FE421165-22DD-4030-AEC1-2A5B0934326A.htm"
 :source-bricscad NIL)

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

(:name "ADJUST"
 :category :MODIFY
 :aliases NIL
 :intl-name "_ADJUST"
 :synopsis "Modifies fade, contrast, and monochrome settings for selected images and underlays (DWF, DWFx, PDF, DGN)."
 :options ("Fade" "Contrast" "Brightness" "Monochrome")
 :arguments "Select image(s) or underlay(s), then specify fade value, contrast value, and brightness (images only) or monochrome setting (underlays only); settings are confirmed via the Properties palette."
 :description "Controls several display settings for selected images and underlays, including fade, contrast, and monochrome appearance. Brightness applies to images only, while monochrome applies to underlays only, with settings confirmed through the Properties palette."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0EB806F7-5FA0-4944-B39D-A7B2A5F6B346.htm"
 :source-bricscad NIL)

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

(:name "AMECONVERT"
 :category :|3D|
 :aliases NIL
 :intl-name "_AMECONVERT"
 :synopsis "Converts AME solid models to AutoCAD solid objects."
 :options NIL
 :arguments "Select one or more AME Release 2 or 2.1 regions and solids to convert; all other object types are ignored."
 :description "Converts Advanced Modeling Extension (AME) Release 2 or 2.1 regions and solids into native AutoCAD solid objects. Converted models may appear slightly different due to the new solid modeler's increased accuracy and finer tolerance, which can affect aligned features like fillets, chamfers, and holes."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3535641E-8090-41C7-A910-200C559D5720.htm"
 :source-bricscad NIL)

(:name "ANALYSISCURVATURE"
 :category :|3D|
 :aliases NIL
 :intl-name "_ANALYSISCURVATURE"
 :synopsis "Displays a color gradient onto a surface to evaluate different aspects of its curvature."
 :options ("Select solids, surfaces to analyze" "Turn off")
 :arguments "Select 3D solids/surfaces to analyze; the curvature color gradient is then displayed. Display settings are set via the Curvature tab of the Analysis Options dialog."
 :description "Displays a color gradient onto a surface to evaluate Gaussian, minimum, maximum, and mean curvature. Green indicates maximum/positive values and blue indicates minimum/negative values, helping assess whether surfaces are bowl-like, saddle-shaped, or flat."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-98134942-122F-4874-BE3D-7EA35A603DA0.htm"
 :source-bricscad NIL)

(:name "ANALYSISDRAFT"
 :category :|3D|
 :aliases NIL
 :intl-name "_ANALYSISDRAFT"
 :synopsis "Displays a color gradient onto a 3D model to evaluate whether there is adequate space between a part and its mold."
 :options ("Select solids, surfaces to analyze" "Turn off")
 :arguments "Select 3D solids/surfaces to analyze; the draft-angle color gradient is then displayed. Display settings are set via the Draft Angle tab of the Analysis Options dialog."
 :description "Displays a color gradient onto a 3D model to evaluate draft angles relative to the current UCS, indicating whether there is adequate space between a part and its mold. Surface normals parallel to the construction plane yield 90.0 degrees, perpendicular surfaces 0 degrees, and opposite-facing normals -90.0 degrees."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C28E9ECC-289A-4CFF-8D6C-DB2AD004EDBA.htm"
 :source-bricscad NIL)

(:name "ANALYSISOPTIONS"
 :category :|3D|
 :aliases NIL
 :intl-name "_ANALYSISOPTIONS"
 :synopsis "Sets the display options for zebra, curvature, and draft analysis."
 :options NIL
 :arguments ""
 :description "Opens the Analysis Options dialog box, where the display settings for zebra striping, curvature evaluation, and draft angle analysis of 3D models are configured. This command is dialog-only with no command-line prompts."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-975AAD9B-6979-4F72-ADBF-FE30C92E6523.htm"
 :source-bricscad NIL)

(:name "ANALYSISZEBRA"
 :category :|3D|
 :aliases NIL
 :intl-name "_ANALYSISZEBRA"
 :synopsis "Projects stripes onto a 3D model to analyze surface continuity."
 :options ("Select solids, surfaces to analyze" "Turn off")
 :arguments "Select 3D solids/surfaces to analyze; zebra striping is then displayed on the selected objects. Display settings are set via the Zebra Analysis tab of the Analysis Options dialog."
 :description "Projects stripe patterns onto a 3D model to analyze continuity between surfaces. The alignment of the stripes at surface intersections helps evaluate tangency and curvature and identify surface discontinuities."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-59583A47-B141-42FA-9B8D-E7591CB81F8B.htm"
 :source-bricscad NIL)

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

(:name "APERTURE"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_APERTURE"
 :synopsis "Controls the size of the object snap target box."
 :options ("Object snap target height")
 :arguments "Supplies an integer pixel value for the object snap target box height, e.g. (command \"APERTURE\" 10)."
 :description "Controls the size of the object snap target box. Object snaps activate when the target box passes over object locations such as intersections or endpoints; higher pixel values create a larger target box."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C8603032-7E55-4EEF-B2DF-CD2FD9EDEF91.htm"
 :source-bricscad NIL)

(:name "APPAUTOLOADER"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_APPAUTOLOADER"
 :synopsis "Lists or reloads all plug-ins in the application plug-in folder."
 :options ("List" "Reload")
 :arguments "Supplies the List or Reload keyword, e.g. (command \"APPAUTOLOADER\" \"Reload\")."
 :description "Lists or reloads all plug-ins in the application plug-in folder. The List option displays all currently installed plug-in applications, and the Reload option reloads all plug-ins using the verbose setting of the APPAUTOLOAD system variable."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CD3386C1-9E69-4C88-8BE6-046C081AEB41.htm"
 :source-bricscad NIL)

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

(:name "APPSTORE"
 :category :OTHER
 :aliases NIL
 :intl-name "_APPSTORE"
 :synopsis "Opens the Autodesk App Store website."
 :options NIL
 :arguments ""
 :description "Opens the Autodesk App Store website, where users can browse and download product add-ons and extensions. The command was previously named EXCHANGE."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-51D7FD80-6761-44CA-99B1-61EC5F5F8218.htm"
 :source-bricscad NIL)

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

(:name "ARCHIVE"
 :category :FILE
 :aliases NIL
 :intl-name "_ARCHIVE"
 :synopsis "Packages the current sheet set files for storage."
 :options NIL
 :arguments ""
 :description "A Sheet Set management command that packages the current sheet set files as a single archive for storage. It opens the Archive a Sheet Set dialog box; a command-line variant, -ARCHIVE, is referenced on the page."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BBC54E74-523D-49BF-BA4A-C32847218625.htm"
 :source-bricscad NIL)

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

(:name "ARX"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_ARX"
 :synopsis "Loads, unloads, and provides information about ObjectARX applications."
 :options ("Files" "Groups" "Commands" "Classes" "Services" "Load" "Unload")
 :arguments "An option keyword: Files, Groups, Commands, Classes, Services, Load, or Unload; Load/Unload then prompt for the ObjectARX application to load or unload."
 :description "Manages ObjectARX (AutoCAD Runtime Extension) applications, letting you load and unload compiled programs and query information about loaded applications, registered commands, classes, and services."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-477DDABE-C3D3-47A2-B481-60401C50492F.htm"
 :source-bricscad NIL)

(:name "ASSISTANTCLOSE"
 :category :OTHER
 :aliases NIL
 :intl-name "_ASSISTANTCLOSE"
 :synopsis "Closes the Autodesk Assistant palette."
 :options NIL
 :arguments ""
 :description "Closes the Autodesk Assistant palette, which displays links to help-related content from several sources along with an option to contact support."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all (Autodesk Assistant; limited product/language availability)"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2C5BCE28-7CC1-4A0F-8E12-FDC6BDECE2C2.htm"
 :source-bricscad NIL)

(:name "ASSISTANTOPEN"
 :category :OTHER
 :aliases NIL
 :intl-name "_ASSISTANTOPEN"
 :synopsis "Displays the Autodesk Assistant palette."
 :options NIL
 :arguments ""
 :description "Displays the Autodesk Assistant palette, which shows links to help-related content from several sources along with an option to contact support. The palette provides actions to contact a support agent, give feedback, and restart or end the chat; it is available in a limited suite of products and languages."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all (Autodesk Assistant; limited product/language availability)"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-476DD718-E097-40F3-B1D9-765987D7F6FD.htm"
 :source-bricscad NIL)

(:name "ATTACH"
 :category :BLOCK
 :aliases NIL
 :intl-name "_ATTACH"
 :synopsis "Inserts references to external files such as other drawings, raster images, point clouds, coordination models, and underlays."
 :options NIL
 :arguments ""
 :description "Opens the Select Reference File dialog box to attach external files to the current drawing, including DWG drawings, DWF/DWFx/PDF/DGN underlays, RCP/RCS point clouds, and NWD/NWC coordination models. Multiple DWG files can be selected at once, while other formats allow a single file. A command-line variant, -ATTACH, is referenced on the page."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-928B7980-2174-4F1E-8059-9F1B1884E7C8.htm"
 :source-bricscad NIL)

(:name "ATTACHURL"
 :category :OTHER
 :aliases NIL
 :intl-name "_ATTACHURL"
 :synopsis "Attaches hyperlinks to objects or areas in a drawing."
 :options ("Area" "Object")
 :arguments "An option (Area or Object); for Area, the corners of the rectangular area (a polyline is created on the URLLAYER); then the URL string to attach."
 :description "Attaches hyperlink URLs to drawing elements. You can attach a hyperlink to a defined area, which creates a polyline on the URLLAYER, or to existing objects; hovering over a linked element changes the cursor to indicate an active hyperlink."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-14669460-2D12-46A0-8DA1-DEE70953A58C.htm"
 :source-bricscad NIL)

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

(:name "AUTOPUBLISH"
 :category :PLOT
 :aliases NIL
 :intl-name "_AUTOPUBLISH"
 :synopsis "Publishes drawings to DWF, DWFx, or PDF files automatically to a specified location."
 :options ("AutoPublish DWF" "Location")
 :arguments ""
 :description "Automates exporting drawings to DWF, DWFx, or PDF for distribution and viewing. Opens the Auto Publish dialog to specify the file format, and the Location option opens a folder dialog to choose the target directory for generated files."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F51F83E2-304F-461F-9EA5-6DDB05321E65.htm"
 :source-bricscad NIL)

(:name "BACTION"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BACTION"
 :synopsis "Adds an action to a dynamic block definition."
 :options ("Move" "Scale" "Stretch" "Polar Stretch" "Rotate" "Flip" "Array"
           "Lookup")
 :arguments "Interactive in the Block Editor: select the parameter to associate, choose the action type, select the objects the action affects, and specify parameter points/locations as prompted."
 :description "Available only in the Block Editor, adds an action to a dynamic block definition that controls how the block's geometry moves or changes when its custom properties are manipulated. Each action is associated with a parameter."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-98CCB318-60F6-46C9-8F90-C2B8614553C4.htm"
 :source-bricscad NIL)

(:name "BACTIONBAR"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BACTIONBAR"
 :synopsis "Displays or hides action bars for parameter objects in the Block Editor."
 :options ("Show" "Hide" "Reset")
 :arguments "Select parameter objects, then an option: Show, Hide, or Reset (Reset also restores default action-bar positioning)."
 :description "Controls the display of action bars (toolbar-like elements listing associated actions) for parameter objects in the Block Editor. Available only when the BACTIONBARMODE system variable is set to 1; action bars can be shown, hidden, or reset to their default positions."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-91A5FCE7-E8B1-495D-8F3E-72BF184A2B63.htm"
 :source-bricscad NIL)

(:name "BACTIONSET"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BACTIONSET"
 :synopsis "Specifies the selection set of objects associated with an action in a dynamic block definition."
 :options ("Remove" "CPolygon")
 :arguments "In the Block Editor: select the action object, then add or Remove objects to redefine the action's selection set; for stretch-type actions also specify the stretch frame (opposite corner or CPolygon)."
 :description "Redefines which objects are associated with an action within a dynamic block. It functions exclusively in the Block Editor and becomes unavailable when the BACTIONBARMODE system variable equals 1."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6A08174B-1ED3-4BB6-8093-02F3AC92F1B3.htm"
 :source-bricscad NIL)

(:name "BACTIONTOOL"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BACTIONTOOL"
 :synopsis "Adds an action to a dynamic block definition."
 :options ("Array" "Lookup" "Flip" "Move" "Rotate" "Scale" "Stretch"
           "Polar Stretch")
 :arguments "In the Block Editor: choose the action type, select the associated parameter, select the objects, and specify the action location and any action-specific values (base type, multiplier, offset, XY)."
 :description "Associates actions with parameters in the Block Editor, defining how block geometry moves or changes when custom properties are manipulated. Actions define behavioral modifications to dynamic block references during drawing manipulation."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-86B3A05A-B637-440D-8310-49915CB09BF2.htm"
 :source-bricscad NIL)

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

(:name "BASSOCIATE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BASSOCIATE"
 :synopsis "Associates an action with a parameter in a dynamic block definition."
 :options NIL
 :arguments "In the Block Editor: select the orphaned action object, then select the parameter to associate with the action (specifying a parameter point when required)."
 :description "Reconnects orphaned actions to parameters within the Block Editor. An action becomes orphaned when its associated parameter is removed from the block definition. This command is unavailable when BACTIONBARMODE is set to 1."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D2B17901-1FF8-4683-B38B-6FF84BCCA6DC.htm"
 :source-bricscad NIL)

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

(:name "BATTORDER"
 :category :ATTRIBUTE
 :aliases NIL
 :intl-name "_BATTORDER"
 :synopsis "Specifies the order of attributes for a block."
 :options NIL
 :arguments ""
 :description "Displays the Attribute Order dialog box, which manages the sequence in which block attributes appear when inserting or editing block references. It functions exclusively within the Block Editor environment."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-93CA12A7-41AA-41CB-B84B-6C1C5FC146E7.htm"
 :source-bricscad NIL)

(:name "BAUTHORPALETTE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BAUTHORPALETTE"
 :synopsis "Opens the Block Authoring Palettes window in the Block Editor."
 :options NIL
 :arguments ""
 :description "Displays the Block Authoring Palettes window, which is accessible only from within the Block Editor. The window organizes block authoring tools across multiple tabs for parameter and action management."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F583E874-59A9-43E5-BF71-C313DBAABCEF.htm"
 :source-bricscad NIL)

(:name "BAUTHORPALETTECLOSE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BAUTHORPALETTECLOSE"
 :synopsis "Closes the Block Authoring Palettes window in the Block Editor."
 :options NIL
 :arguments ""
 :description "Closes the Block Authoring Palettes window display. The operation can only be executed when working within the Block Editor environment, not from the main drawing interface."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2A496147-BFF0-4B97-8167-C1D21B9EC1CD.htm"
 :source-bricscad NIL)

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

(:name "BCONSTRUCTION"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BCONSTRUCTION"
 :synopsis "Converts block geometry into construction geometry, which may be hidden or displayed."
 :options ("Convert" "Revert" "Show All" "Hide All")
 :arguments "In the Block Editor: Convert selected geometry into construction geometry (or Revert it back), or choose Show All / Hide All to control construction-geometry visibility."
 :description "Used in the Block Editor to convert geometry into construction geometry for reference purposes. Construction geometry appears as gray dashed lines in the editor but remains hidden in block references, and its visual properties cannot be modified."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C3E47F1B-C6A0-46A8-BA1E-66801D1F703C.htm"
 :source-bricscad NIL)

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

(:name "BCPARAMETER"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_BCPARAMETER"
 :synopsis "Applies constraint parameters to selected objects, or converts dimensional constraints to parameter constraints."
 :options ("Linear" "Horizontal" "Vertical" "Aligned" "Angular" "Radial"
           "Diameter" "Convert")
 :arguments "In the Block Editor: choose the constraint parameter type (Linear/Horizontal/Vertical/Aligned/Angular/Radial/Diameter), then select the objects or constraint points; or use Convert to change existing dimensional constraints into parameter constraints."
 :description "Used in the Block Editor to apply constraint parameters to objects or between constraint points. It enables users to create various types of parametric constraints that govern geometric relationships and dimensions within dynamic blocks."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F22AD919-40DF-4AC3-8339-CD212D79EB94.htm"
 :source-bricscad NIL)

(:name "BCYCLEORDER"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BCYCLEORDER"
 :synopsis "Changes the cycling order of grips for a dynamic block reference."
 :options NIL
 :arguments ""
 :description "Opens the Insertion Cycling Order dialog box and operates exclusively within the Block Editor. It allows users to modify how grips cycle when used as insertion points for dynamic block references."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DCE0441E-A6F5-4307-B5F2-DD73B0455FA0.htm"
 :source-bricscad NIL)

(:name "BDETECT"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BDETECT"
 :synopsis "Displays the Detect palette where you can start object detection and manage the objects that are eligible for conversion."
 :options NIL
 :arguments ""
 :description "BDETECT leverages Autodesk AI to identify and group similar objects in a drawing for streamlined block conversion. The palette automatically begins detection upon opening, presenting matching object sets that users can convert into new or existing blocks, or edit the primary instance via menu options."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all (previously named DETECT)"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6E72038E-140D-4FDC-8C65-8942DEB03FBC.htm"
 :source-bricscad NIL)

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

(:name "BESETTINGS"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BESETTINGS"
 :synopsis "Displays the Block Editor Settings dialog box."
 :options NIL
 :arguments ""
 :description "Opens a dialog for configuring Block Editor display preferences. It provides access to settings for color, text, grip, constraint, and other display options within the Block Editor environment."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-86714B3E-3450-48F0-9DB9-C5FDD9897E6E.htm"
 :source-bricscad NIL)

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

(:name "BGRIPSET"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BGRIPSET"
 :synopsis "Creates, deletes, or resets grips associated with a parameter."
 :options ("0" "1" "2" "4" "Reposition")
 :arguments "In the Block Editor: select a parameter in the current dynamic block definition, enter the number of grips to display (0, 1, 2, or 4), and optionally select Reposition to restore grips to their default locations."
 :description "Allows users to specify the number of grips displayed for a parameter in dynamic block definitions and restore grips to their default positions. You can only use the BGRIPSET command in the Block Editor."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6795C9A3-CB54-4513-9C77-32C967B49F7E.htm"
 :source-bricscad NIL)

(:name "BLEND"
 :category :MODIFY
 :aliases NIL
 :intl-name "_BLEND"
 :synopsis "Creates a spline in the gap between two selected lines or curves."
 :options ("CONtinuity" "Tangent" "Smooth")
 :arguments "Select the first source object near an endpoint, then the second source object; the CONtinuity option chooses Tangent or Smooth before the shape is created."
 :description "Select each object near an endpoint. The shape of the resulting spline depends on the specified continuity. The lengths of the selected objects remain unchanged."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9EF74C66-88CA-4C16-B761-CB1119C0F897.htm"
 :source-bricscad NIL)

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

(:name "BLOCK?"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_BLOCK?"
 :synopsis "Lists the objects in a block definition."
 :options NIL
 :arguments "Enter a block name or press Enter to select an inserted block, then enter an entity type (such as line or text) or press Enter to list all objects."
 :description "Enter a block name or select an inserted block, and then specify an object type, such as line or text, to list. You can press Enter to list all objects in the block definition."
 :availability :AUTOCAD-ONLY
 :autocad-versions "Express Tool"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5DAE4FA4-808E-4E1F-8565-3D115B406226.htm"
 :source-bricscad NIL)

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

(:name "BLOCKSDATAOPTION"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_BLOCKSDATAOPTION"
 :synopsis "Displays the data collection consent dialog box."
 :options NIL
 :arguments NIL
 :description "The data collection consent dialog box is displayed after you complete a smart block workflow for the first time. By agreeing to the data collection, the content data used in the workflow is shared with AutoCAD. You can still continue to work with smart blocks even if you choose not to consent to the data collection."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4B0812A4-DC54-4262-9BAF-1BFAE2FF6252.htm"
 :source-bricscad NIL)

(:name "BLOCKSPALETTE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BLOCKSPALETTE"
 :synopsis "Displays the Blocks palette, which you can use to insert blocks and drawings into the current drawing."
 :options NIL
 :arguments NIL
 :description "The Blocks palette allows you to insert blocks defined in the current drawing along with the recent or favorite blocks and blocks defined in other drawings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-77C0C748-2152-476D-BC78-A7FB193D7330.htm"
 :source-bricscad NIL)

(:name "BLOCKSPALETTECLOSE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BLOCKSPALETTECLOSE"
 :synopsis "Closes the Blocks palette."
 :options NIL
 :arguments NIL
 :description "Closes the Blocks palette when currently displayed, either in an auto-hidden state or open state."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5ECF72B1-69E6-434B-BFEB-808E9F721E4A.htm"
 :source-bricscad NIL)

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

(:name "BLOOKUPTABLE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BLOOKUPTABLE"
 :synopsis "Displays or creates a lookup table for a dynamic block definition."
 :options NIL
 :arguments NIL
 :description "When a lookup action is applied to a lookup parameter, the Property Lookup Table dialog box is automatically displayed. If a table is already defined for the lookup action, then that table is displayed in the dialog box. The BLOOKUPTABLE command is disabled when the BACTIONBARMODE system variable is set to 1."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C894797E-3FC5-42AB-8C62-2971B68E6EB4.htm"
 :source-bricscad NIL)

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

(:name "BPARAMETER"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BPARAMETER"
 :synopsis "Adds a parameter with grips to a dynamic block definition."
 :options ("Alignment" "Base" "Point" "Linear" "Polar" "XY" "Rotation" "Flip"
           "Visibility" "Lookup")
 :arguments "Enter a parameter-type keyword (Alignment, Base, Point, Linear, Polar, XY, Rotation, Flip, Visibility, or Lookup), then specify the locations for that parameter's grips in the Block Editor."
 :description "You can use the BPARAMETER command only in the Block Editor. A parameter defines custom properties for the block reference. After you add a parameter, you must associate an action with the parameter to make the block dynamic."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E4460179-F0FC-4AC6-85D7-35B05D018D16.htm"
 :source-bricscad NIL)

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

(:name "BREAKATPOINT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_BREAKATPOINT"
 :synopsis "Breaks the selected object into two objects at a specified point."
 :options NIL
 :arguments "Select the open 2D object to break, then specify the break point on the object (a point off the object is projected onto it)."
 :description "You can break an open, 2D object into two objects at a specified point on the object. If the point is located off of the object, it's automatically projected onto the object. Valid objects include lines, arcs, and open polylines. Closed objects such as circles cannot be broken at a single point."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E0439DE0-B2C3-4233-BB4D-5A574A00694B.htm"
 :source-bricscad NIL)

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

(:name "BREP"
 :category :|3D|
 :aliases NIL
 :intl-name "_BREP"
 :synopsis "Removes the history from 3D solids and composite solids, and associativity from surfaces."
 :options NIL
 :arguments NIL
 :description "When a solid loses the history of the original parts from which it was created, the original parts can no longer be selected and modified. BREP also removes surface associativity. When a surface loses associativity it loses any mathematical expressions or information about how the surface was created."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-AE581A57-7045-41AC-B1C4-3E8FDED0ACBA.htm"
 :source-bricscad NIL)

(:name "BREPLACE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BREPLACE"
 :synopsis "Replaces specified block references with a different block."
 :options NIL
 :arguments "Select one or more block references to replace, then choose the replacement block from a drawing or from the list of recent or suggested blocks via the block replacement panel."
 :description "You can replace one or more blocks with another block you specify from a drawing, or from a list of recent or suggested blocks. Select one or more blocks to replace specifies the block references you want replaced, and the block replacement panel displays."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9856FE72-45DC-4EDC-A808-EB9FD79A9F78.htm"
 :source-bricscad NIL)

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

(:name "BSAVE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BSAVE"
 :synopsis "Saves the current block definition."
 :options NIL
 :arguments NIL
 :description "Saves changes to the current block definition. You can only use the BSAVE command in the Block Editor."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4571EA8F-A188-4676-9648-8D6F455480DA.htm"
 :source-bricscad NIL)

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

(:name "BSEARCH"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BSEARCH"
 :synopsis "Displays the Convert dialog box, which provides options to convert selected entities and identical instances into blocks."
 :options ("Instances" "Source objects only")
 :arguments "Select the objects to convert to blocks, then choose Instances or Source objects only."
 :description "When you specify a geometry for conversion, AutoCAD identifies and highlights all instances of the same geometry. You can then choose to convert the source object or the instances into a new or existing block."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-22BD7584-47CD-4D31-8AA5-52637ABAC3CD.htm"
 :source-bricscad NIL)

(:name "BTABLE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BTABLE"
 :synopsis "Stores variations of a block in the Block Properties Table."
 :options ("Parameter location" "Number of Grips" "Palette")
 :arguments "In the Block Editor, specify the parameter location, number of grips, and palette for the Block Properties Table."
 :description "This command is available only in the Block Editor. The Block Properties Table includes properties such as legacy parameters, parameter constraints, user parameters, and attributes. Each row in the table defines a different variation of the block reference, and can be accessed by the lookup grip."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CA2F55B9-5EE2-44FF-A3FD-673B84602BC2.htm"
 :source-bricscad NIL)

(:name "BTESTBLOCK"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BTESTBLOCK"
 :synopsis "Displays a window within the Block Editor to test a dynamic block."
 :options NIL
 :arguments NIL
 :description "You can only use the BTESTBLOCK command in the Block Editor. With the Test Block window you can test a dynamic block without closing the Block Editor. You can test dynamic grips or display the Properties palette and test the behavior when changing the properties."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0F0D71D2-99E2-4B57-8AA6-41A0C9F878ED.htm"
 :source-bricscad NIL)

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

(:name "BVHIDE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BVHIDE"
 :synopsis "Makes objects invisible in the current visibility state or all visibility states in a dynamic block definition."
 :options ("Current" "All")
 :arguments "Select objects to hide, then choose to hide for the current state or all visibility states."
 :description "Makes objects invisible for the current visibility state. You can only use the BVHIDE command in the Block Editor."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E0842E5F-5F7B-4015-B46D-1F9172826958.htm"
 :source-bricscad NIL)

(:name "BVSHOW"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BVSHOW"
 :synopsis "Makes objects visible in the current visibility state or all visibility states in a dynamic block definition."
 :options NIL
 :arguments "Select objects to make visible, then choose to make visible for the current state or all visibility states."
 :description "Allows you to make objects visible for visibility states. You can only use the BVSHOW command in the Block Editor."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2E2946C7-0F8F-4592-B398-4EBA2E4250C3.htm"
 :source-bricscad NIL)

(:name "BVSTATE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_BVSTATE"
 :synopsis "Creates, sets, or deletes a visibility state in a dynamic block."
 :options NIL
 :arguments NIL
 :description "Displays the Visibility States dialog box. You can only use the BVSTATE command in the Block Editor after a visibility parameter has been added to the block definition."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D99B6173-7399-40D0-8EDF-F271025E4C43.htm"
 :source-bricscad NIL)

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

(:name "CHAMFEREDGE"
 :category :|3D|
 :aliases NIL
 :intl-name "_CHAMFEREDGE"
 :synopsis "Bevels the edges of 3D solids and surfaces."
 :options ("Select an Edge" "Distance 1" "Distance 2" "Loop" "Expression")
 :arguments "Select an edge (more than one on the same face is allowed), then enter a value for the chamfer distance or drag the chamfer grips."
 :description "You can select more than one edge at a time, as long as they belong to the same face. Enter a value for the chamfer distance or click and drag the chamfer grips; after selecting a loop edge you are prompted to Accept the current selection or choose the Next loop."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9CE971E3-1CCF-4212-9CD7-EA2606529206.htm"
 :source-bricscad NIL)

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

(:name "CLASSICGROUP"
 :category :SELECTION
 :aliases NIL
 :intl-name "_CLASSICGROUP"
 :synopsis "Opens the legacy Object Grouping dialog box."
 :options NIL
 :arguments NIL
 :description "Opens the legacy Object Grouping dialog box."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-12F72970-3EAC-4E83-A237-1EFA73807FF5.htm"
 :source-bricscad NIL)

(:name "CLASSICIMAGE"
 :category :FILE
 :aliases NIL
 :intl-name "_CLASSICIMAGE"
 :synopsis "Manages referenced image files in the current drawing."
 :options NIL
 :arguments NIL
 :description "The legacy Image Manager is displayed. The IMAGE command now displays the External References palette. Note: this command will be removed in future releases."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all; to be removed in future releases"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C36F6E33-401F-437C-A3A7-449B0162048A.htm"
 :source-bricscad NIL)

(:name "CLASSICINSERT"
 :category :BLOCK
 :aliases NIL
 :intl-name "_CLASSICINSERT"
 :synopsis "Inserts a block or drawing into the current drawing using the classic version of the INSERT command."
 :options NIL
 :arguments NIL
 :description "The classic Insert dialog box is displayed. If you enter -INSERT at the Command prompt, options are displayed. A good practice is to insert a block from a block library."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C032DA5B-E1FD-4443-BF60-815CABA8733B.htm"
 :source-bricscad NIL)

(:name "CLASSICLAYER"
 :category :LAYER
 :aliases NIL
 :intl-name "_CLASSICLAYER"
 :synopsis "Opens the legacy Layer Properties Manager."
 :options NIL
 :arguments NIL
 :description "The legacy Layer Properties Manager is displayed. The LAYER command displays the current Layer Properties Manager. Note: This command will be removed in future releases."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all; to be removed in future releases"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-12A5AAE3-65A1-4DB4-98C5-A9675C330481.htm"
 :source-bricscad NIL)

(:name "CLASSICXREF"
 :category :FILE
 :aliases NIL
 :intl-name "_CLASSICXREF"
 :synopsis "Manages referenced drawing files in the current drawing."
 :options NIL
 :arguments NIL
 :description "Displays the legacy Xref Manager. The EXTERNALREFERENCES command provides an alternative by displaying the current External References palette. This command will be removed in future releases."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all; to be removed in future releases"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-19675BE4-E59A-450F-8995-01D959CDDEA1.htm"
 :source-bricscad NIL)

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

(:name "CLIP"
 :category :MODIFY
 :aliases NIL
 :intl-name "_CLIP"
 :synopsis "Crops selected objects such as blocks, external references, images, viewports, and underlays to a specified boundary."
 :options ("On" "Off" "Delete" "New Boundary" "Select Polyline" "Polygonal"
           "Rectangular" "Invert Clip" "Clipdepth" "Front Clip Point"
           "Distance" "Remove" "Generate Polyline" "Clipping Object")
 :arguments "Select the object to clip, then respond to the object-type-specific prompts (underlay/image, external reference, or viewport)."
 :description "Defines a clipping boundary that hides portions of images, underlays, viewports, or external references. Visibility of the boundary is controlled by the FRAME system variable. The prompts available depend on whether you are clipping an underlay, image, external reference, or viewport."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A8E1834D-2A1F-4C2A-92CF-B6A3424DB1B1.htm"
 :source-bricscad NIL)

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

(:name "CLOSEALL"
 :category :FILE
 :aliases NIL
 :intl-name "_CLOSEALL"
 :synopsis "Closes all currently open drawings."
 :options NIL
 :arguments NIL
 :description "All open drawings are closed, and a message box appears for each unsaved drawing, allowing you to save changes before closing."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E5BAAD2B-C4E5-4DF0-A483-95C8AD89BE91.htm"
 :source-bricscad NIL)

(:name "CLOSEALLOTHER"
 :category :FILE
 :aliases NIL
 :intl-name "_CLOSEALLOTHER"
 :synopsis "Closes all other open drawings, except the current drawing."
 :options NIL
 :arguments NIL
 :description "All open drawings except the current one are closed. For each unsaved drawing, a message box appears allowing you to save changes before closing."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3E5E969F-1546-4B9D-80F0-E46319DCD5EB.htm"
 :source-bricscad NIL)

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

(:name "COMMANDMACROS"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_COMMANDMACROS"
 :synopsis "Opens the Command Macros palette from which you can manage and use command macro recommendations."
 :options NIL
 :arguments NIL
 :description "Launches the Command Macros palette, which displays previously saved command macros and new macro recommendations identified from your executed command sequences. The palette provides two tabs, Saved and Insights, enabling you to run macros, edit them, save new ones, and provide feedback on recommendations."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F7A4A421-6B72-4005-B9A3-0EB8DCDCF7DF.htm"
 :source-bricscad NIL)

(:name "COMMANDMACROSCLOSE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_COMMANDMACROSCLOSE"
 :synopsis "Closes the Command Macros palette."
 :options NIL
 :arguments NIL
 :description "Closes the Command Macros palette. No additional parameters or options are documented."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-72DD30DD-3618-433C-8FA8-1B2521908727.htm"
 :source-bricscad NIL)

(:name "COMPARE"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COMPARE"
 :synopsis "Compares a specified drawing file with the current drawing file, highlighting the differences with color within revision clouds."
 :options ("Find")
 :arguments "The Select a Drawing to Compare dialog box is displayed (via the Find option) to specify the comparison drawing; the DWG Compare toolbar then appears."
 :description "Provides a visual comparison between the current drawing and another specified drawing, typically different revisions. After selecting a comparison drawing through the Select a Drawing to Compare dialog, the DWG Compare toolbar appears at the top of the drawing area, providing access to comparison tools and display options."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4B96F5FD-C9CF-4E2E-996E-E00914F8D99E.htm"
 :source-bricscad NIL)

(:name "COMPARECLOSE"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COMPARECLOSE"
 :synopsis "Closes the DWG Compare toolbar and ends the comparison."
 :options NIL
 :arguments NIL
 :description "Available only during an active drawing comparison session. It terminates the comparison process and closes the associated toolbar interface."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-FC244EA1-6580-46C1-91B4-9F67F6E97929.htm"
 :source-bricscad NIL)

(:name "COMPAREEXPORT"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COMPAREEXPORT"
 :synopsis "Exports comparison results into a new drawing file called a snapshot drawing."
 :options NIL
 :arguments NIL
 :description "Creates a new drawing file that combines the compared drawing files into two overlapping blocks while maintaining the visual appearance of the comparison; the file follows the naming format _compare_current drawing name vs compared drawing name.dwg. Upon completion a balloon notification alerts the user, and opening the snapshot drawing displays the DWG Compare Snapshot toolbar for controlling display settings and navigating change sets. This command is only accessible during an active drawing comparison."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-21DDB9BA-29E4-4781-BBC5-D5D800B371BA.htm"
 :source-bricscad NIL)

(:name "COMPILE"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_COMPILE"
 :synopsis "Compiles shape files and PostScript font files into SHX files."
 :options NIL
 :arguments "The Select Shape or Font File dialog box (a standard file selection dialog box) is displayed; enter the SHP or PFB file name in the dialog box."
 :description "Displays the Select Shape or Font File dialog box in which you enter the SHP or PFB file name. The resulting compiled file receives the same name with a .shx extension."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-54F4D0CE-EC71-42DA-A56E-469252287C12.htm"
 :source-bricscad NIL)

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

(:name "CONSTRAINTSETTINGS"
 :category :PARAMETRIC
 :aliases ("+CONSTRAINTSETTINGS")
 :intl-name "_CONSTRAINTSETTINGS"
 :synopsis "Controls the display of geometric constraints on constraint bars."
 :options NIL
 :arguments NIL
 :description "Opens the Constraint Settings dialog box, which manages how geometric constraints are displayed in constraint bars. You can visually confirm which objects are associated with specific constraints and what constraints relate to any given object."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BFDACE2C-1494-4275-B8A4-FAA143BFD5C4.htm"
 :source-bricscad NIL)

(:name "CONVERT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_CONVERT"
 :synopsis "Converts \"legacy\" 2D polylines and hatches for use with later product releases."
 :options ("Hatch" "Polyline" "All")
 :arguments "Enter object type to convert (Hatch/Polyline/All), then choose All or Select objects."
 :description "Legacy hatches and 2D (\"heavy\") polylines created before AutoCAD Release 14 or AutoCAD LT 97 are updated to improve performance and reduce file size; drawings from Release 14 or later may still contain legacy 2D polylines through third-party applications or block insertion and explosion."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-16097276-A292-4AFD-BA08-29F735FDB091.htm"
 :source-bricscad NIL)

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

(:name "CONVERTOLDLIGHTS"
 :category :RENDER
 :aliases NIL
 :intl-name "_CONVERTOLDLIGHTS"
 :synopsis "Converts lights created in previous drawing file formats to the current format."
 :options NIL
 :arguments NIL
 :description "The lights in the drawing that were originally created in a previous drawing file format are updated to the current drawing file format; the conversion may not be correct in all cases and you may need to adjust intensity, for example."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-03D2843F-3FB5-488C-BA33-6C45EE1FA299.htm"
 :source-bricscad NIL)

(:name "CONVERTOLDMATERIALS"
 :category :RENDER
 :aliases NIL
 :intl-name "_CONVERTOLDMATERIALS"
 :synopsis "Converts older materials to use the current materials format."
 :options NIL
 :arguments NIL
 :description "Materials that were created in a previous materials format are updated to the current materials format; the conversion may not be correct in all cases and you may need to adjust material mapping, for example."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-667D8E9E-6F68-4124-8673-76FA8E8B74A0.htm"
 :source-bricscad NIL)

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

(:name "COORDINATIONMODELATTACH"
 :category :FILE
 :aliases ("CMATTACH")
 :intl-name "_COORDINATIONMODELATTACH"
 :synopsis "Inserts references to coordination models such as NWD and NWC Navisworks files."
 :options NIL
 :arguments NIL
 :description "When you attach a coordination model, you link that referenced file to the current drawing; any changes to the referenced file display in the current drawing when it opens or reloads."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-389266F7-F981-4354-BCDB-369D34FF0EDA.htm"
 :source-bricscad NIL)

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

(:name "COPYFROMTRACE"
 :category :EDIT
 :aliases NIL
 :intl-name "_COPYFROMTRACE"
 :synopsis "Copies objects from a trace into the drawing."
 :options NIL
 :arguments "Select objects from the open trace, then press Enter to add them to the drawing."
 :description "While a trace is open with TRACEBACK on, start COPYFROMTRACE, select objects in the trace, and press Enter to add the objects to the drawing."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-982D3DA5-3212-4A0F-8776-57C5B028CF50.htm"
 :source-bricscad NIL)

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

(:name "COPYLINK"
 :category :EDIT
 :aliases NIL
 :intl-name "_COPYLINK"
 :synopsis "Copies the current view to the Clipboard for linking to other OLE applications."
 :options NIL
 :arguments NIL
 :description "You can copy the current view to the Clipboard and then paste the contents of the Clipboard into another document as a linked OLE object."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-17979B4A-4887-420D-8658-41AB87460C50.htm"
 :source-bricscad NIL)

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

(:name "COUNT"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COUNT"
 :synopsis "Counts and highlights the instances of the selected object in the drawing."
 :options ("First Corner" "Opposite Corner" "Current Area" "Entire Model Space"
           "Object" "Polygonal" "Start Point" "Next Point")
 :arguments "Select an object or block to count, or specify a count area."
 :description "When you are in an active count, the Count toolbar is displayed at the top of the drawing area, and all the instances of the selected object or block are highlighted."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3A0C3460-6ABC-4D13-BF1F-D2BFCD399851.htm"
 :source-bricscad NIL)

(:name "COUNTAREA"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COUNTAREA"
 :synopsis "Defines the area to count the instances of an object or block."
 :options ("First Corner" "Opposite Corner" "Current Area" "Entire Model Space"
           "Object" "Polygonal" "Start Point" "Next Point")
 :arguments "Specify a rectangular or polygonal selection area, the entire model space, or select a valid closed-polyline boundary object."
 :description "Specify a rectangular or polygonal selection area, the entire model space, or select a valid object as a count area; a valid boundary object must be a closed polyline that consists of line segments and does not intersect with itself, and the count area defined in the previous count session can also be used in the current count."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DF9EC102-60A9-46D2-8A8C-7ED08140472E.htm"
 :source-bricscad NIL)

(:name "COUNTAREACLOSE"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COUNTAREACLOSE"
 :synopsis "Cancels the count selection area."
 :options NIL
 :arguments NIL
 :description "This command is available only during an active count."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CF3BD46E-EFB5-48C1-806A-956A88FC2D98.htm"
 :source-bricscad NIL)

(:name "COUNTCLOSE"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COUNTCLOSE"
 :synopsis "Closes the Count toolbar and exits the count."
 :options NIL
 :arguments NIL
 :description "This command is available only during an active count."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2E02F8AA-DCD8-4AF2-B6C5-93987E250B39.htm"
 :source-bricscad NIL)

(:name "COUNTFIELD"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COUNTFIELD"
 :synopsis "Creates a field that's set to the value of the current count."
 :options NIL
 :arguments NIL
 :description "This command is available only during an active count."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A27E1B7C-8D82-480F-A35D-E45CC5AECC1A.htm"
 :source-bricscad NIL)

(:name "COUNTLIST"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COUNTLIST"
 :synopsis "Opens the Count palette to display and manage the counted blocks."
 :options NIL
 :arguments "No command-line arguments; opens the Count palette."
 :description "Opens the Count palette, which enables viewing of blocks in the current drawing and inserting a table containing specified blocks with their corresponding count values into the drawing."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-86778E28-1E40-4C06-80E8-FDEF2F0E3D38.htm"
 :source-bricscad NIL)

(:name "COUNTLISTCLOSE"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COUNTLISTCLOSE"
 :synopsis "Closes the Count palette."
 :options NIL
 :arguments "No command-line arguments; closes the Count palette."
 :description "Closes the Count palette used by the block-counting feature set."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-01900DB9-2C5B-4BC7-BD5F-750FA427C2D1.htm"
 :source-bricscad NIL)

(:name "COUNTNAVNEXT"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COUNTNAVNEXT"
 :synopsis "Zooms to the next object in the count result."
 :options NIL
 :arguments "No command-line arguments; available only during an active count."
 :description "Zooms to the next object in the count result. This command is available only during an active count."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B077D951-61E2-40BC-8705-61F82F2B8D46.htm"
 :source-bricscad NIL)

(:name "COUNTNAVPREV"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COUNTNAVPREV"
 :synopsis "Zooms to the previous object in the count result."
 :options NIL
 :arguments "No command-line arguments; available only during an active count."
 :description "Zooms to the previous object in the count result. This command is available only during an active count."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-58570EEF-5478-4017-AE39-5556BD6D69C6.htm"
 :source-bricscad NIL)

(:name "COUNTTABLE"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_COUNTTABLE"
 :synopsis "Inserts a table containing the block names and the corresponding count of each block in the drawing."
 :options NIL
 :arguments "No command-line keywords documented; inserts a count table. If block quantities change, UPDATEFIELD refreshes the count values."
 :description "Generates a table that lists the blocks present in a drawing alongside their instance counts. If block quantities change after the table is inserted, the UPDATEFIELD command refreshes the count values within the table."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EA75F772-B340-4052-930E-9317EFC59DB6.htm"
 :source-bricscad NIL)

(:name "CUI"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_CUI"
 :synopsis "Manages the customized user interface elements in the product."
 :options NIL
 :arguments "No command-line arguments; opens the Customize User Interface dialog box."
 :description "Opens the Customize User Interface dialog box, which manages workspaces, ribbon panels, toolbars, menus, shortcut menus, and keyboard shortcuts. It uses XML-based CUIx files, replacing the legacy CUI, MNS, and MNU file formats from earlier AutoCAD versions."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7F8F4B26-EFAF-4033-B7B7-CA39FC4E104A.htm"
 :source-bricscad NIL)

(:name "CUIEXPORT"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_CUIEXPORT"
 :synopsis "Exports customized settings from the main CUIx file to an enterprise or partial CUIx file."
 :options NIL
 :arguments "No command-line arguments; opens the Customize User Interface dialog box with the Transfer tab active."
 :description "Transfers customization information from the main CUIx file to an enterprise or partial CUIx file. It opens the Customize User Interface dialog box with the Transfer tab active, displaying the main CUIx file (acad.cuix or acadlt.cuix) in the left pane, allowing items to be dragged between files."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-AD49B73D-5534-42CB-8D12-ABA91248642F.htm"
 :source-bricscad NIL)

(:name "CUIIMPORT"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_CUIIMPORT"
 :synopsis "Imports customized settings from an enterprise or partial CUIx file to the main CUIx file."
 :options NIL
 :arguments "No command-line arguments; opens the Customize User Interface dialog box with the Transfer tab active."
 :description "Transfers customization information from an enterprise or partial CUIx file to the main CUIx file. It opens the Transfer tab within the Customize User Interface dialog box, allowing items to be dragged between CUIx files and changes applied to update the configuration."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BF2F3165-E8D7-4A87-863C-F831ACAF1F81.htm"
 :source-bricscad NIL)

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

(:name "CUTBASE"
 :category :EDIT
 :aliases NIL
 :intl-name "_CUTBASE"
 :synopsis "Copies selected objects to the Clipboard, along with a specified base point, and removes them from the drawing."
 :options NIL
 :arguments "Specify a base point; select the objects to cut."
 :description "Cuts selected objects to the Clipboard while designating a base point for clipboard storage, removing them from the drawing. When pasted into documents or drawings as embedded OLE objects, the cut items are positioned relative to the specified base point. CUTBASE does not generate OLE link information."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1383482F-C675-468A-B3C1-75276E3FF9EA.htm"
 :source-bricscad NIL)

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

(:name "CVADD"
 :category :|3D|
 :aliases NIL
 :intl-name "_CVADD"
 :synopsis "Adds control vertices to NURBS surfaces and splines."
 :options ("Point" "Insert Knots" "Insert Edit Point" "Direction")
 :arguments "Select a NURBS surface or spline; then respond to prompts (Point; on surfaces: Insert Knots and Direction U/V; on splines: Insert Edit Point)."
 :description "Adds control vertices in the U or V direction on NURBS surfaces, or inserts points directly on surfaces and splines. When applied to surfaces, vertices can be added along a specified direction; when used with splines, points can be placed directly on the curve."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-84231102-AE32-4C30-814C-D99BD49B11E4.htm"
 :source-bricscad NIL)

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

(:name "CVREMOVE"
 :category :|3D|
 :aliases NIL
 :intl-name "_CVREMOVE"
 :synopsis "Removes control vertices from NURBS surfaces and curves."
 :options ("Point" "Remove Knots" "Remove Edit Point" "Direction")
 :arguments "Select a valid NURBS surface or curve; then respond to prompts (Point; on surfaces: Remove Knots and Direction U/V; on splines: Remove Edit Point). A minimum of two control vertices must remain in any direction."
 :description "Removes control vertices from NURBS surfaces and curves in either the U or V direction. A minimum of two control vertices must remain in any direction; attempting to remove more triggers an error."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7BF8CDE4-9440-4860-9D84-9341006E600A.htm"
 :source-bricscad NIL)

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

(:name "DBCCLOSE"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_DBCCLOSE"
 :synopsis "Closes the Select Data Object dialog box (dbConnect Manager)."
 :options NIL
 :arguments "No command-line arguments; closes the Select Data Object dialog box."
 :description "Closes the Select Data Object dialog box, which is part of the dbConnect Manager interface used for database connectivity operations."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-32DF0138-7F5E-4C67-A5F1-89B4C4F2AB1F.htm"
 :source-bricscad NIL)

(:name "DBCCONFIGURE"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_DBCCONFIGURE"
 :synopsis "Opens the Configure a Data Source dialog box (dbConnect Manager)."
 :options NIL
 :arguments "No command-line arguments; opens the Configure a Data Source dialog box."
 :description "Launches the Configure a Data Source dialog box, which allows setting up external database connections for program access via the dbConnect Manager."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-527B5B1F-9306-4EAF-9DA9-249519E4408F.htm"
 :source-bricscad NIL)

(:name "DBCDEFINELLT"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_DBCDEFINELLT"
 :synopsis "Opens the Select a Database Object dialog box."
 :options NIL
 :arguments "No command-line arguments; opens the Select a Database Object dialog box."
 :description "Opens a dialog that displays database objects (link templates, label templates, and queries) associated with the current drawing, allowing one to be selected and applied to the current operation."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CE34922F-6149-453C-8975-9234C25B9F6C.htm"
 :source-bricscad NIL)

(:name "DBCDEFINELT"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_DBCDEFINELT"
 :synopsis "Opens the Select Data Object dialog box (dbConnect Manager)."
 :options NIL
 :arguments "No command-line arguments; opens the Select Data Object dialog box."
 :description "Launches the Select Data Object dialog box, which displays the Data Sources node of the dbConnect Manager so a database table can be chosen for the current operation."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F0A2A37B-3484-4AF8-9C3A-E48F513CF304.htm"
 :source-bricscad NIL)

(:name "DBCONNECT"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_DBCONNECT"
 :synopsis "Provides an interface to external database tables."
 :options NIL
 :arguments "No command-line arguments; displays the dbConnect Manager and adds the dbConnect menu to the menu bar."
 :description "Displays the dbConnect Manager and adds the dbConnect menu to the menu bar, enabling connectivity to external databases through four primary interfaces: the dbConnect Manager, the Data View window, the Query Editor, and the Link Select dialog box."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-56352196-BB2D-47A1-B091-5BD367A6F195.htm"
 :source-bricscad NIL)

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

(:name "DCFORM"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_DCFORM"
 :synopsis "Specifies whether the dimensional constraint being created is dynamic or annotational."
 :options ("Annotational" "Dynamic")
 :arguments "Enter a keyword: Annotational or Dynamic, to set the Constraint Form property for dimensional constraints being created."
 :description "Determines the form type of dimensional constraints being created by setting the Constraint Form property. Annotational applies annotational dimensional constraints; Dynamic applies dynamic dimensional constraints."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-15259693-4C27-4B50-8C8B-67AA4F34E418.htm"
 :source-bricscad NIL)

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

(:name "DETACHURL"
 :category :EDIT
 :aliases NIL
 :intl-name "_DETACHURL"
 :synopsis "Removes hyperlinks in a drawing."
 :options NIL
 :arguments "Select the objects whose hyperlinks are to be removed. When an area is selected, the associated polyline is deleted; PURGE can then remove the URLLAYER layer."
 :description "Removes hyperlinks from selected objects. When an area is selected, the associated polyline is deleted. The URLLAYER layer can afterward be removed with PURGE."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-51D50D97-AA7F-4201-AB57-20424F7F2F07.htm"
 :source-bricscad NIL)

(:name "DETECTCLOSE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_DETECTCLOSE"
 :synopsis "Ends the detection review."
 :options NIL
 :arguments "No command-line arguments; ends the detection review."
 :description "Terminates the detection review process associated with the Smart Blocks Detect and Convert feature, which analyzes drawings to identify objects convertible to blocks."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-940A6C03-953D-47D7-9CD9-83F5B3078000.htm"
 :source-bricscad NIL)

(:name "DETECTCONVERT"
 :category :BLOCK
 :aliases NIL
 :intl-name "_DETECTCONVERT"
 :synopsis "Displays the Convert dialog box, which provides options to convert the detected objects and instances into blocks."
 :options NIL
 :arguments "No command-line arguments; opens the Convert dialog box."
 :description "Opens the Convert dialog box, which enables converting identified objects and instances into blocks. This supports the Smart Blocks Detect and Convert feature, which analyzes drawings to identify convertible objects."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-90D4816E-58EC-494A-87A0-345FF25A4065.htm"
 :source-bricscad NIL)

(:name "DETECTPRIMARY"
 :category :BLOCK
 :aliases NIL
 :intl-name "_DETECTPRIMARY"
 :synopsis "Specifies the detected instance from which a new block definition is created."
 :options NIL
 :arguments "Specify the detected instance from which the new block definition is created."
 :description "Specifies the detected instance from which a new block definition is created, as part of the Smart Blocks Detect and Convert workflow."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-91E949ED-F5F7-4375-9CD0-EB27D584E3DF.htm"
 :source-bricscad NIL)

(:name "DETECTREMOVE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_DETECTREMOVE"
 :synopsis "Removes selected instances from the set."
 :options NIL
 :arguments "Select the instances to remove from the set."
 :description "Removes selected instances from the detected set, as part of the Smart Blocks Detect and Convert workflow."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3FE11ECF-E549-49D8-9DC8-88FD69CE6F37.htm"
 :source-bricscad NIL)

(:name "DETECTREVIEWPREV"
 :category :BLOCK
 :aliases NIL
 :intl-name "_DETECTREVIEWPREV"
 :synopsis "Displays the previous set of detected objects."
 :options NIL
 :arguments "No command-line arguments; displays the previous set of detected objects."
 :description "Navigates backward through previously identified objects in the Smart Blocks detection workflow, enabling review of earlier detection results."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5070F9F4-B6B3-4D08-961B-494734A4C190.htm"
 :source-bricscad NIL)

(:name "DGNADJUST"
 :category :MODIFY
 :aliases NIL
 :intl-name "_DGNADJUST"
 :synopsis "Adjust the fade, contrast, and monochrome settings of a DGN underlay."
 :options ("Fade" "Contrast" "Monochrome")
 :arguments "Select one or more DGN underlays; then set Fade (0-100), Contrast (0-100), and Monochrome (on/off)."
 :description "Modifies the fade, contrast, and monochrome settings across single or multiple DGN underlays. Higher fade increases transparency; higher contrast intensifies pixel colors; monochrome converts linework to grayscale while preserving luminance. The ADJUST command provides an alternative that works with multiple underlay types plus images."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0424CD48-345B-4134-9382-66E65D8E7EF5.htm"
 :source-bricscad NIL)

(:name "DGNATTACH"
 :category :FILE
 :aliases NIL
 :intl-name "_DGNATTACH"
 :synopsis "Inserts a DGN file as an underlay into the current drawing."
 :options NIL
 :arguments "Opens the Select DGN File dialog box to choose a DGN file, then the Attach DGN Underlay dialog for insertion point, scale, and rotation. The command-line variant -DGNATTACH accepts these as prompts."
 :description "Links a DGN file to the drawing as an underlay. Changes made to the referenced DGN file automatically display when the drawing is opened or reloaded. The DGN's layer structure combines into a single layer placed on the current working layer; visibility can be managed by freezing the attachment layer."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-39114E63-84C1-4A5F-BB85-3639E6F04527.htm"
 :source-bricscad NIL)

(:name "DGNCLIP"
 :category :MODIFY
 :aliases NIL
 :intl-name "_DGNCLIP"
 :synopsis "Crops the display of a selected DGN underlay to a specified boundary."
 :options ("On" "Off" "Delete" "New Boundary" "Polyline" "Polygonal"
           "Rectangular" "Invert Clip")
 :arguments "Select the DGN underlay to clip; then an option keyword (On/Off/Delete/New Boundary/Invert Clip); for New Boundary choose Polyline, Polygonal, or Rectangular and pick the boundary points."
 :description "Defines a clipping boundary that hides the portions of a DGN underlay lying outside that boundary. The boundary visibility is controlled by the DGNFRAME system variable, and the boundary must lie in a plane parallel to the underlay."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5345F9BC-A0AB-489D-95CE-EE5871BFA4FC.htm"
 :source-bricscad NIL)

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

(:name "DGNLAYERS"
 :category :LAYER
 :aliases NIL
 :intl-name "_DGNLAYERS"
 :synopsis "Controls the display of layers in a DGN underlay."
 :options NIL
 :arguments "Select a DGN underlay; the Underlay Layers dialog box opens to manage layer visibility."
 :description "Manages the visibility of layers within a DGN underlay. After a DGN underlay is selected, the Underlay Layers dialog opens. This command handles DGN underlays specifically, while the ULAYERS command provides similar functionality for all underlay types (DWF, DWFx, PDF, and DGN)."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DED7F1A9-B176-4188-9807-915C9B0AFA1D.htm"
 :source-bricscad NIL)

(:name "DGNMAPPING"
 :category :FILE
 :aliases NIL
 :intl-name "_DGNMAPPING"
 :synopsis "Allows you to create, modify, rename, or delete DGN mapping setups."
 :options NIL
 :arguments "No command-line arguments; opens the DGN Mapping Setups dialog box."
 :description "Opens the DGN Mapping Setups dialog box, enabling creation, modification, renaming, or deletion of custom mapping translations for DGN/DWG import-export operations. Level names, line styles, lineweights, and color mappings can be adjusted to align with company CAD standards."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0B1BC4E3-A19C-4794-9D35-AA6788C2CDC0.htm"
 :source-bricscad NIL)

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

(:name "DIMINSPECT"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMINSPECT"
 :synopsis "Adds or removes inspection information for a selected dimension."
 :options NIL
 :arguments "Opens the Inspection Dimension dialog box to add or remove inspection information; the command-line variant -DIMINSPECT prompts for the settings and dimension selection."
 :description "Adds or removes inspection dimensions from existing dimensions. Inspection dimensions communicate how often manufactured parts need checking to verify that dimension values and tolerances remain within specified ranges."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CC40F9D5-D70D-41D0-8AEC-3775045A502E.htm"
 :source-bricscad NIL)

(:name "DIMJOGGED"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMJOGGED"
 :synopsis "Creates jogged dimensions for circles and arcs."
 :options ("Mtext" "Text" "Angle")
 :arguments "Select an arc or circle; specify a center location override; specify the dimension line location (or Mtext/Text/Angle); specify the jog location."
 :description "Generates jogged (foreshortened) radius dimensions for circles and arcs when their centers are positioned off the layout. It measures the radius and displays the dimension with a radius symbol, allowing an alternative center location to be specified."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3FC7CFBD-DAAC-48E0-8C4E-1DC795A34D12.htm"
 :source-bricscad NIL)

(:name "DIMJOGLINE"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMJOGLINE"
 :synopsis "Adds or removes a jog line on a linear or aligned dimension."
 :options ("Add" "Remove")
 :arguments "Select the linear or aligned dimension to add a jog to (or Remove); specify the jog location, or press Enter to place it at the midpoint between the dimension text and first extension line."
 :description "Adds or removes a jog line on a linear or aligned dimension. Jog lines indicate breaks in dimensioned objects; the dimension value represents the actual distance rather than the measured distance in the drawing."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0FC8D2AB-18BE-4E93-A697-5350FDBC4226.htm"
 :source-bricscad NIL)

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

(:name "DIMROTATED"
 :category :DIMENSION
 :aliases NIL
 :intl-name "_DIMROTATED"
 :synopsis "Creates a rotated linear dimension."
 :options ("Mtext" "Text" "Angle")
 :arguments "Specify the angle of the dimension line; specify the first and second extension line origins (or Select object); specify the dimension line location (or Mtext/Text/Angle)."
 :description "Creates a linear dimension featuring a rotated dimension line. The rotation angle is specified relative to the X axis; extension line origins are defined by selecting points or an object; the dimension line is positioned and the resulting text can be customized."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-79E3EEEE-4F8E-4370-848A-AFD4E0DF17B8.htm"
 :source-bricscad NIL)

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

(:name "DOWNLOADMANAGER"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_DOWNLOADMANAGER"
 :synopsis "Reports the status of the current download."
 :options NIL
 :arguments "No command-line arguments; no user prompts appear during execution."
 :description "Displays the status of the current download and allows resuming interrupted downloads. Currently this command applies only to downloading the Autodesk Medium Image Library."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-76354652-821C-449D-A950-68FE08CDC2F2.htm"
 :source-bricscad NIL)

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

(:name "DWFADJUST"
 :category :MODIFY
 :aliases NIL
 :intl-name "_DWFADJUST"
 :synopsis "Adjust the fade, contrast, and monochrome settings of a DWF or DWFx underlay."
 :options ("Fade" "Contrast" "Monochrome")
 :arguments "Select one or more DWF or DWFx underlays; then set Fade (0-100), Contrast (0-100), and Monochrome."
 :description "Modifies the default display properties of single or multiple DWF and DWFx underlays. Fade (0-100) lightens the linework; Contrast (0-100) forces each pixel toward its primary or secondary color; Monochrome displays linework in grayscale variations based on background luminance."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-60EDB2E8-046A-4811-B340-6305970D61B9.htm"
 :source-bricscad NIL)

(:name "DWFATTACH"
 :category :FILE
 :aliases NIL
 :intl-name "_DWFATTACH"
 :synopsis "Inserts a DWF or DWFx file as an underlay into the current drawing."
 :options NIL
 :arguments "Opens the Select DWF File dialog to choose a DWF/DWFx file, then the Attach DWF Underlay dialog for insertion point, scale, and rotation. The command-line variant -DWFATTACH accepts these as prompts."
 :description "Inserts a DWF or DWFx file as an underlay by choosing a file and configuring it in the Attach DWF Underlay dialog. It establishes a link between the referenced file and the current drawing, automatically updating the display when the drawing is opened or reloaded."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-28E5C393-E0C3-45DF-A82A-0A78DB916619.htm"
 :source-bricscad NIL)

(:name "DWFCLIP"
 :category :MODIFY
 :aliases NIL
 :intl-name "_DWFCLIP"
 :synopsis "Crops the display of a selected DWF or DWFx underlay to a specified boundary."
 :options ("On" "Off" "Delete" "New Boundary" "Polyline" "Polygonal"
           "Rectangular" "Invert Clip")
 :arguments "Select the DWF/DWFx underlay; then an option keyword (On/Off/Delete/New Boundary/Invert Clip); for New Boundary choose Select Polyline, Polygonal, or Rectangular and pick the boundary points."
 :description "Crops the display of a selected DWF or DWFx underlay to a specified boundary, hiding the portion outside the boundary. The boundary must be parallel to the underlay; clipping can be toggled on/off, deleted, or created as a new rectangular or polygonal area."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-35C28583-A6F7-4D8F-801A-CB1FE24F72DC.htm"
 :source-bricscad NIL)

(:name "DWFFORMAT"
 :category :FILE
 :aliases NIL
 :intl-name "_DWFFORMAT"
 :synopsis "Sets the default format to DWF or DWFx for output in specific commands."
 :options ("DWF" "DWFx")
 :arguments "Specify the default output format: DWF or DWFx."
 :description "Designates whether output files use the DWF or DWFx format in specific commands. DWFx uses Microsoft's XML Paper Specification (XPS) to provide viewing and publishing capabilities independent from Autodesk software, and DWFx files are compatible with Microsoft's XPS Viewer."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-AED4E528-9976-4716-91F8-A849956F128E.htm"
 :source-bricscad NIL)

(:name "DWGCONVERT"
 :category :FILE
 :aliases NIL
 :intl-name "_DWGCONVERT"
 :synopsis "Converts drawing format version for selected drawing files."
 :options NIL
 :arguments "No command-line arguments; opens the DWG Convert dialog box where files are marked for conversion."
 :description "Opens the DWG Convert dialog box, where the files to be converted are marked with checkmarks. Right-clicking in the file display area accesses a shortcut menu with additional options."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1C2163A6-29CC-4EC2-974C-5B6017B948C4.htm"
 :source-bricscad NIL)

(:name "DWGLOG"
 :category :FILE
 :aliases NIL
 :intl-name "_DWGLOG"
 :synopsis "Creates and maintains an individual log file for each drawing file as it is accessed."
 :options NIL
 :arguments "No command-line arguments documented."
 :description "An Express Tool that logs drawing file access events in network environments. When enabled, it creates or updates a drawing history (.DWH) file documenting when drawings are opened, closed, or attached as xrefs, including user and machine information, helping identify which users have files open on shared networks."
 :availability :AUTOCAD-ONLY
 :autocad-versions "Express Tool"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B63A635F-DA7D-4D84-8DE6-52861F03A180.htm"
 :source-bricscad NIL)

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

(:name "DXBIN"
 :category :FILE
 :aliases NIL
 :intl-name "_DXBIN"
 :synopsis "Imports an AutoCAD DXB (drawing interchange binary) file."
 :options NIL
 :arguments "Opens a file selection dialog to specify the DXB file to import."
 :description "Imports 2D vector data stored in AutoCAD's binary DXB format. The vectors are converted to line objects using the current layer and object properties. A standard file selection dialog appears for the user to specify the file."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9EB8FC2A-50E9-4555-8ADD-80DB8D4DE8AB.htm"
 :source-bricscad NIL)

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

(:name "EATTEXT"
 :category :ATTRIBUTE
 :aliases NIL
 :intl-name "_EATTEXT"
 :synopsis "Exports block attribute information to a table or to an external file."
 :options NIL
 :arguments "Opens the Data Extraction wizard; the command-line variant -EATTEXT displays available options at the Command prompt."
 :description "Extracts and exports block attribute data to a table or external file. It has been superseded by the Data Extraction wizard (DATAEXTRACTION), which now handles the attribute-extraction functionality this command previously managed."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all (superseded by the Data Extraction wizard)"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-30D85568-2BCF-4F6C-A95E-FC6F394C5D3A.htm"
 :source-bricscad NIL)

(:name "EDGE"
 :category :|3D|
 :aliases NIL
 :intl-name "_EDGE"
 :synopsis "Changes the visibility of 3D face edges."
 :options ("Display" "All" "Select")
 :arguments "Select the edge of a 3D face to toggle its visibility (or Display to expose hidden edges: All shows all hidden edges, Select shows hidden edges of partially visible 3D faces)."
 :description "Toggles the visibility of edges of 3D faces created with the 3DFACE command, making invisible edges visible again and vice versa. When edges of multiple 3D faces are collinear, visibility is modified for all collinear edges together."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7B71EC97-47C1-401B-B1A7-10B47318CE34.htm"
 :source-bricscad NIL)

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

(:name "EXPORTDWF"
 :category :PLOT
 :aliases NIL
 :intl-name "_EXPORTDWF"
 :synopsis "Creates a DWF file and allows you to set individual page setup overrides on a sheet-by-sheet basis."
 :options NIL
 :arguments "Opens the Save as DWF dialog box to name the file and set page setup overrides, plot stamps, and file options; the Export to DWF Options dialog configures layer information and file location."
 :description "Creates a DWF file while allowing device driver page setup options to be adjusted, plot stamps applied, and file settings modified through the Save as DWF dialog box. Layer information inclusion, file location changes, and other file options are configured via the Export to DWF Options dialog."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5A044F50-C31B-442B-A232-13FF6248A39D.htm"
 :source-bricscad NIL)

(:name "EXPORTDWFX"
 :category :PLOT
 :aliases NIL
 :intl-name "_EXPORTDWFX"
 :synopsis "Creates a DWFx file where you can set individual page setup overrides on a sheet-by-sheet basis."
 :options NIL
 :arguments "Opens the Save as DWFx dialog box to name the file and set page setup overrides, plot stamps, and file options; the Export to DWF/PDF Options dialog configures layer information and file location."
 :description "Creates a DWFx file while allowing device driver page setup options to be overridden, plot stamps applied, and file options modified through the Save as DWFx dialog box. Advanced settings such as layer information and file location are configured via the Export to DWF/PDF Options dialog."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DF787DAC-2A78-43E6-82F2-7604F91C26FC.htm"
 :source-bricscad NIL)

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

(:name "EXPORTSETTINGS"
 :category :PLOT
 :aliases NIL
 :intl-name "_EXPORTSETTINGS"
 :synopsis "Adjusts the page setup and drawing selection when exporting to a DWF, DWFx, or PDF file."
 :options ("Preview" "DWF Options" "PDF Options" "Page Setup" "Window Select"
           "Export Window")
 :arguments NIL
 :description "Configures export parameters before saving a drawing in DWF, DWFx, or PDF format, giving access to preview, format-specific options, page setup, and selective (window) area export."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F71C40AA-7B9F-4ACC-BC8D-A67C396C58EE.htm"
 :source-bricscad NIL)

(:name "EXPORTTOAUTOCAD"
 :category :FILE
 :aliases NIL
 :intl-name "_EXPORTTOAUTOCAD"
 :synopsis "Creates a version of a drawing file that can be opened in products such as AutoCAD and previous releases of a toolset."
 :options ("Filename" "Format" "Bind" "Bind Type" "Maintain" "Prefix" "Suffix"
           "? List Settings")
 :arguments "Command-line prompts set the export options (Format for the DWG version, Bind and Bind Type for xrefs, Maintain, filename Prefix and Suffix), then a file dialog collects the output drawing name; custom AEC objects are converted to basic objects and the original file is unaffected."
 :description "Generates a new drawing file with custom AEC (proxy) objects exploded into basic AutoCAD objects so it can be opened in AutoCAD or earlier releases. The exported file loses the intelligence of specialized objects but remains viewable where object enablers are unavailable; the original drawing is unchanged."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-86C80CA1-F237-4AE6-8A43-2E9CA06A03A8.htm"
 :source-bricscad NIL)

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

(:name "EXTERNALREFERENCES"
 :category :BLOCK
 :aliases NIL
 :intl-name "_EXTERNALREFERENCES"
 :synopsis "Opens the External References palette."
 :options NIL
 :arguments NIL
 :description "Opens the External References palette, which organizes and manages referenced files including DWG xrefs, DWF/DWFx/PDF and DGN underlays, raster images, point clouds, and coordination models. Only DWG, DWF, DWFx, PDF, and raster image files can be opened directly from the palette; point clouds and coordination models are unavailable in AutoCAD LT."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7947385D-1A5D-4474-9AB9-FD5E46ADEF53.htm"
 :source-bricscad NIL)

(:name "EXTERNALREFERENCESCLOSE"
 :category :BLOCK
 :aliases NIL
 :intl-name "_EXTERNALREFERENCESCLOSE"
 :synopsis "Closes the External References palette."
 :options NIL
 :arguments NIL
 :description "Closes the External References palette when it is currently displayed, whether in an auto-hidden state or an open state."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3E60812F-8EFA-4D94-8DAE-B8A20AC3B411.htm"
 :source-bricscad NIL)

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

(:name "FADEMARKUP"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_FADEMARKUP"
 :synopsis "Fade individual markups so they are less visible on a trace."
 :options ("Unfade Markup" "All")
 :arguments "Select the markup assist boxes to fade, or choose All to fade every markup assist box; the Unfade Markup option restores visibility."
 :description "Fades markup assist boxes on a trace so they are less visible. Options let you fade individual markups, fade all markup boxes at once, or unfade markups."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D8793553-96C2-4177-A082-5359A4A85F45.htm"
 :source-bricscad NIL)

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

(:name "FILETAB"
 :category :VIEW
 :aliases NIL
 :intl-name "_FILETAB"
 :synopsis "Displays the file tabs at the top of the drawing area."
 :options NIL
 :arguments NIL
 :description "Displays the file tabs at the top of the drawing area for quick access to all open drawings. Tabs show the filename, allow opening a new drawing with the plus (+) button, and accept drawings dragged in from File Explorer."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1A2A6927-5916-4207-A3FB-379A94A27527.htm"
 :source-bricscad NIL)

(:name "FILETABCLOSE"
 :category :VIEW
 :aliases NIL
 :intl-name "_FILETABCLOSE"
 :synopsis "Hides the file tabs at the top of the drawing area."
 :options NIL
 :arguments NIL
 :description "Hides the file tabs at the top of the drawing area. When the tabs are hidden, Ctrl+TAB can be used to move between open drawings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-76F07387-6685-4E07-9843-473AEBCE8D43.htm"
 :source-bricscad NIL)

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

(:name "FILLETEDGE"
 :category :|3D|
 :aliases NIL
 :intl-name "_FILLETEDGE"
 :synopsis "Rounds and fillets the edges of solid objects."
 :options ("Chain" "Loop" "Radius" "Accept" "Next loop")
 :arguments "Select one or more edges of a 3D solid; use Chain to select tangent edges or Loop to select edges on a face; set the fillet Radius by entering a value or dragging the grip, then Accept."
 :description "Rounds and fillets the edges of 3D solid objects. You can select multiple edges and specify the fillet radius either by entering a numeric value or by dragging an interactive grip."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0546E8D5-6775-436C-B91A-57A2D8D75A59.htm"
 :source-bricscad NIL)

(:name "FILTER"
 :category :SELECTION
 :aliases NIL
 :intl-name "_FILTER"
 :synopsis "Creates a list of requirements that an object must meet to be included in a selection set."
 :options NIL
 :arguments NIL
 :description "Creates a reusable list of requirements that an object must meet to be included in a selection set. The command displays the Object Selection Filters dialog box for specifying and naming selection criteria."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-61BA6C74-7C01-49D4-AD9F-180E039AA984.htm"
 :source-bricscad NIL)

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

(:name "FINDINCLUDE"
 :category :TEXT
 :aliases NIL
 :intl-name "_FINDINCLUDE"
 :synopsis "Controls the types of text objects included in a search when using the -FIND command."
 :options ("Blocks" "Block Attributes" "Xrefs" "Text" "Table text"
           "Dimleader text" "Hidden items" "Exit")
 :arguments "At each prompt toggle whether a text-object type is included in -FIND searches (Blocks, Block Attributes, Xrefs, Text, Table text, Dimleader text, Hidden items), then Exit."
 :description "Controls which categories of text objects are included in a search when using the -FIND command, letting you include or exclude blocks, block attributes, xrefs, text, table text, dimension/leader text, and hidden items."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-33B7E791-5910-4260-8A91-EA069AA9138B.htm"
 :source-bricscad NIL)

(:name "FINDMATCH"
 :category :TEXT
 :aliases NIL
 :intl-name "_FINDMATCH"
 :synopsis "Controls how the entered text string is compared with text in objects when using the -FIND command."
 :options ("Match case" "Whole words only" "Use wildcards" "Match diacritics"
           "Half or full width" "Exit")
 :arguments "At each prompt toggle a comparison setting (Match case, Whole words only, Use wildcards, Match diacritics, Half or full width), then Exit."
 :description "Controls how the entered text string is compared with text in objects when using the -FIND command, exposing options for case sensitivity, whole-word matching, wildcards, diacritics, and half/full-width character matching."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-578736D2-2CC8-4971-9C2B-688771C127B8.htm"
 :source-bricscad NIL)

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

(:name "FREESPOT"
 :category :RENDER
 :aliases NIL
 :intl-name "_FREESPOT"
 :synopsis "Creates a free spotlight which is a spotlight without a specified target."
 :options ("Name" "Intensity factor" "Status" "Photometry" "Hotspot" "Falloff"
           "Color" "Shadow" "Attenuation")
 :arguments "Specify the source location (coordinates or a point), then respond to the successive prompts for Name, Intensity factor, Status, Photometry, hotspot and falloff angles, shadow, attenuation, and filter color."
 :description "Creates a free spotlight, a spotlight without a specified target. Since AutoCAD 2016 all standard lights are photometric; photometric lighting is enabled by setting the LIGHTINGUNITS system variable to 1 or 2."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C1DFCAC8-C52F-4D9A-AA30-C88D13715D2B.htm"
 :source-bricscad NIL)

(:name "FREEWEB"
 :category :RENDER
 :aliases NIL
 :intl-name "_FREEWEB"
 :synopsis "Creates a free web light which is a web light without a specified target."
 :options ("Name" "Intensity factor" "Status" "Photometry" "Web" "Shadow"
           "Filter color")
 :arguments "Specify the source location, then respond to the prompts for Name, Intensity factor, Status, Photometry, Web (web-distribution file and X/Y/Z), Shadow, and filter Color; the LIGHTINGUNITS system variable must be nonzero."
 :description "Creates a free web light, a web light without a specified target. A web light distributes intensity according to a photometric web file; the LIGHTINGUNITS system variable must be set to a nonzero value before use."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3AC71AD8-911F-43FC-8A94-47018B7281F5.htm"
 :source-bricscad NIL)

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

(:name "GCCOLLINEAR"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_GCCOLLINEAR"
 :synopsis "Causes two or more line segments to lie along the same line."
 :options ("Multiple")
 :arguments "Select the first object, then the second object to be made collinear; or use Multiple to select successive objects to constrain to the same line."
 :description "Applies a collinear geometric constraint so that two or more line segments lie along the same line. It is equivalent to the Collinear option of GEOMCONSTRAINT; valid objects include lines, polyline segments, ellipse axes, and lines within blocks."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-43FD615E-81AC-4A7F-AC01-3EF28761EFBB.htm"
 :source-bricscad NIL)

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

(:name "GEOMARKLATLONG"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_GEOMARKLATLONG"
 :synopsis "Places a position marker at a location defined by latitude and longitude."
 :options NIL
 :arguments "Specify Latitude (decimal degrees, or degrees/minutes/seconds, validated between +90 and -90) and Longitude (validated between +180 and -180); the drawing must already contain geographic location information."
 :description "Places a position marker at a location defined by latitude and longitude. A position marker is an annotation, typically a point with a leader line and multiline text; this is the latitude-longitude option of GEOMARKPOSITION and requires the drawing to contain geographic location information."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-845EBCCC-5367-4B35-A30A-3E72584C5940.htm"
 :source-bricscad NIL)

(:name "GEOMARKME"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_GEOMARKME"
 :synopsis "Places a position marker in the drawing area at the coordinates corresponding to your current position."
 :options NIL
 :arguments NIL
 :description "Places a position marker at the coordinates corresponding to your current position. A position marker is an annotation consisting of a point, a leader line, and multiline text; this is the My Location option of GEOMARKPOSITION and requires the drawing to contain geographic location information."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7FC15721-B9DD-454C-A040-7A25D7E4A28E.htm"
 :source-bricscad NIL)

(:name "GEOMARKPOINT"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_GEOMARKPOINT"
 :synopsis "Places a position marker at a specified point in model space."
 :options NIL
 :arguments "Specify a point in model space (enter x,y coordinates or click a location); the drawing must already contain geographic location information."
 :description "Places a position marker at a specified point in model space. A position marker is an annotation consisting of a point, a leader line, and multiline text; this is the Point option of GEOMARKPOSITION and requires the drawing to contain geographic location information."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-65CF58B6-A65D-499E-BE43-1DBDA18CAA34.htm"
 :source-bricscad NIL)

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

(:name "GEOREMOVE"
 :category :OTHER
 :aliases NIL
 :intl-name "_GEOREMOVE"
 :synopsis "Removes all geographic location information from the drawing file."
 :options NIL
 :arguments NIL
 :description "Removes all geographic location information from the drawing file, deleting the geographic marker and the assigned GIS coordinate system and removing the ability to turn on the map. Position markers are not removed."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-AF24B18E-6871-486E-A676-14D4DFFA3A80.htm"
 :source-bricscad NIL)

(:name "GEOREORIENTMARKER"
 :category :OTHER
 :aliases NIL
 :intl-name "_GEOREORIENTMARKER"
 :synopsis "Changes the north direction and position of the geographic marker in model space, without changing its latitude and longitude."
 :options NIL
 :arguments "Select a point for the new marker location, then specify the north direction as an angle or by a first and second point relative to the World Coordinate System."
 :description "Changes the north direction and position of the geographic marker in model space without changing its latitude and longitude. You select a new marker location and define the north direction relative to the WCS."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8D59534A-43C0-454E-9ABC-FAA46BF0FA05.htm"
 :source-bricscad NIL)

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

(:name "GOTOURL"
 :category :OTHER
 :aliases NIL
 :intl-name "_GOTOURL"
 :synopsis "Opens the file or web page associated with the hyperlink attached to an object."
 :options NIL
 :arguments "Select an object that has an attached hyperlink; the associated file or web page (URL) then opens."
 :description "Opens the file or web page associated with the hyperlink attached to an object. You select an object that has an attached hyperlink and the associated URL or file is opened."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B5E72B5A-C971-4099-ACC4-76E5EB13645B.htm"
 :source-bricscad NIL)

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

(:name "GRAPHICSCONFIG"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_GRAPHICSCONFIG"
 :synopsis "Sets hardware acceleration on or off and provides access to display performance options."
 :options NIL
 :arguments NIL
 :description "Displays the Graphics Performance dialog box, where hardware acceleration is turned on or off and display performance options are tuned. A command-line-only version is available as -GRAPHICSCONFIG."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3DCD7A3D-5CE8-413D-80ED-37DE73F607E3.htm"
 :source-bricscad NIL)

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

(:name "GROUPEDIT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_GROUPEDIT"
 :synopsis "Adds and removes objects from the selected group, or renames a selected group."
 :options ("Add Objects" "Remove Objects" "Rename")
 :arguments "Select a group (pick a member object in the drawing area or enter its name), then choose to Add Objects, Remove Objects, or Rename the group."
 :description "Adds objects to or removes objects from a selected group, or renames a selected group. You select a group in the drawing area or enter its name; if the selected object has no group membership you are prompted again."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9228E5A6-4929-42DB-8A48-420632E95F28.htm"
 :source-bricscad NIL)

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

(:name "HATCHSETBOUNDARY"
 :category :DRAW
 :aliases NIL
 :intl-name "_HATCHSETBOUNDARY"
 :synopsis "Redefines a selected hatch or fill to conform to a different closed boundary."
 :options NIL
 :arguments "Select the hatch object, then select the objects to be used for the new closed boundary; the hatch is trimmed to within the selected boundary or geometry."
 :description "Redefines a selected hatch or fill to conform to a different closed boundary, trimming a selected hatch to within a selected boundary or geometry."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-7154390E-EF9F-41E6-8DAE-321D6C03A37A.htm"
 :source-bricscad NIL)

(:name "HATCHSETORIGIN"
 :category :DRAW
 :aliases NIL
 :intl-name "_HATCHSETORIGIN"
 :synopsis "Controls the starting location of hatch pattern generation for a selected hatch."
 :options NIL
 :arguments "Select the hatch object (one or more), then specify the new hatch origin point that controls where pattern generation starts."
 :description "Controls the starting location of hatch pattern generation for a selected hatch. It sets the hatch origin point and can modify multiple hatch objects at once (excluding solid and gradient fills)."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-64137838-F62E-461B-BFB1-12A7793A9C8B.htm"
 :source-bricscad NIL)

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

(:name "HIDEPALETTES"
 :category :VIEW
 :aliases NIL
 :intl-name "_HIDEPALETTES"
 :synopsis "Hides all displayed palettes, along with the ribbon and the drawing tabs."
 :options NIL
 :arguments NIL
 :description "Hides all currently displayed palettes, along with the ribbon and the drawing tabs. The complementary SHOWPALETTES command restores them, and Ctrl+Shift+H toggles between hiding and showing these interface components."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0C234107-7EBC-44EE-876A-6A4C0CC17DFE.htm"
 :source-bricscad NIL)

(:name "HIGHLIGHTNEW"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_HIGHLIGHTNEW"
 :synopsis "Controls whether new and changed features in product updates are highlighted in the user interface with an orange dot."
 :options NIL
 :arguments NIL
 :description "Controls whether new and changed features from product updates are highlighted in the user interface with an orange dot on ribbon buttons, dialog options, and palettes. It is accessible only from the Help menu for updates and its state is stored in the SHOWNEWSTATE system variable."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6D863F55-669A-4A65-807E-E4D305097A1D.htm"
 :source-bricscad NIL)

(:name "HLSETTINGS"
 :category :VIEW
 :aliases NIL
 :intl-name "_HLSETTINGS"
 :synopsis "Sets the display of such properties as hidden lines."
 :options NIL
 :arguments NIL
 :description "Sets the display of properties such as hidden lines. In AutoCAD it opens the Visual Styles Manager; in AutoCAD LT it opens the Hidden Line Settings dialog box."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5FE86582-3202-4221-9F90-0022685CE268.htm"
 :source-bricscad NIL)

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

(:name "IGESEXPORT"
 :category :FILE
 :aliases NIL
 :intl-name "_IGESEXPORT"
 :synopsis "Saves selected objects in the current drawing to a new IGES (*.igs, *.iges) file."
 :options NIL
 :arguments "The Export File dialog box collects the IGES output name and location; thereafter you specify which objects to export, and a notification bubble confirms completion."
 :description "Saves selected objects in the current drawing to a new IGES (*.igs, *.iges) file. It displays the Export File dialog box for the output name, then prompts for the objects to export."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C3F00D33-08E9-47DB-9608-94A366E48319.htm"
 :source-bricscad NIL)

(:name "IGESIMPORT"
 :category :FILE
 :aliases NIL
 :intl-name "_IGESIMPORT"
 :synopsis "Imports data from an IGES (*.igs or *.iges) file into the current drawing."
 :options NIL
 :arguments "The Select IGES File dialog box locates and selects the .igs or .iges file to import; large imports run in the background and a notification bubble prompts you to insert the imported data."
 :description "Imports data from an IGES (*.igs or *.iges) file into the current drawing. It displays the Select IGES File dialog box; if processing exceeds 5 seconds the import runs in the background, and a notification bubble prompts insertion on completion."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0C73F1E2-B4F6-4F11-BCC4-22631E616693.htm"
 :source-bricscad NIL)

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

(:name "IMAGEASYNCWAIT"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_IMAGEASYNCWAIT"
 :synopsis "Ensures that raster images being loaded in the background during file opening are complete before proceeding."
 :options NIL
 :arguments NIL
 :description "Ensures that raster images being loaded in the background during file opening are fully loaded before proceeding. It is intended for scripts and AutoLISP programs and should be invoked at the start of any script or program that might trigger the affected commands."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BE447BB9-476C-416E-9C0E-773589B02A2B.htm"
 :source-bricscad NIL)

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

(:name "INPUTSEARCHOPTIONS"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_INPUTSEARCHOPTIONS"
 :synopsis "Opens a dialog box that controls settings for display of the command line suggestion list for commands, system variables, and named objects."
 :options NIL
 :arguments NIL
 :description "Opens the Input Search Options dialog box, which controls how the command-line suggestion list displays commands, system variables, and named objects. A command-line-only version is available as -INPUTSEARCHOPTIONS."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8679C971-4CFA-40E7-82BE-5EE281747559.htm"
 :source-bricscad NIL)

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

(:name "ISODRAFT"
 :category :DRAW
 :aliases NIL
 :intl-name "_ISODRAFT"
 :synopsis "Turns isometric drafting settings on or off, and specifies the current 2D isometric drafting plane."
 :options ("Orthographic" "Isoplane left" "Isoplane top" "Isoplane right")
 :arguments "Enter the drafting plane option: Orthographic (isometric off), or Isoplane left, Isoplane top, or Isoplane right; Ctrl+E or F5 cycles through the isoplanes."
 :description "Turns isometric drafting settings on or off and specifies the current 2D isometric drafting plane, adjusting ortho, snap, grid, polar tracking, and isometric circle orientation together. It supersedes ISOPLANE by integrating control of all associated settings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-061FA171-5425-481C-B24C-887C4E195A7B.htm"
 :source-bricscad NIL)

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

(:name "JPGOUT"
 :category :FILE
 :aliases NIL
 :intl-name "_JPGOUT"
 :synopsis "Saves selected objects to a file in JPEG file format."
 :options ("All objects and viewports")
 :arguments "A file dialog collects the JPEG output name (or, when FILEDIA is 0, the name is entered at the prompt); then Select objects, or choose All objects and viewports; shade plot settings are maintained."
 :description "Saves selected objects to a file in JPEG file format, maintaining shade plot settings. Light glyphs displayed in the drawing appear in the new file even when the light's Plot Glyph property is set to No."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1A2C1CB7-2323-456E-AF23-1FBA900E5EFC.htm"
 :source-bricscad NIL)

(:name "JULIAN"
 :category :OTHER
 :aliases NIL
 :intl-name "_JULIAN"
 :synopsis "Contains the DATE tool and several AutoCAD Julian date and calendar date conversion routines."
 :options ("DATE" "CTOJ" "DTOJ" "JTOC" "JTOD" "JTOW")
 :arguments "JULIAN is not entered directly; enter DATE to display the current date and time. The AutoLISP functions are (ctoj year month day hour minute second), (dtoj YYYYMMDD.HHMMSSmsec), (jtoc julian), (jtod julian), and (jtow julian)."
 :description "Express Tool that provides the DATE command plus several AutoLISP routines for converting between Julian dates and calendar dates. JULIAN itself is not meant to be entered in the Command window; DATE shows the current date and time."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all (Express Tool)"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-65FBB1A0-F94D-4F75-A56D-3E5BD055ADF8.htm"
 :source-bricscad NIL)

(:name "JUSTIFYTEXT"
 :category :TEXT
 :aliases NIL
 :intl-name "_JUSTIFYTEXT"
 :synopsis "Changes the justification point of selected text objects without changing their locations."
 :options ("Left" "Align" "Fit" "Center" "Middle" "Right" "TL" "TC" "TR" "ML"
           "MC" "MR" "BL" "BC" "BR")
 :arguments "Select the text objects, then enter a justification option; single-line text supports Left, Align, Fit, Center, Middle, Right, TL, TC, TR, ML, MC, MR, BL, BC, BR (multiline text options differ slightly)."
 :description "Changes the justification point of selected text objects without changing their locations. It works with single-line text, multiline text, leader text, and attribute objects; the available justification options differ slightly between single-line and multiline text."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-72F7D0C0-20B3-4F70-998A-794ABEAE431C.htm"
 :source-bricscad NIL)

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

(:name "LAYERCLOSE"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYERCLOSE"
 :synopsis "Closes the Layer Properties Manager."
 :options NIL
 :arguments NIL
 :description "Closes the Layer Properties Manager."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9D0D75C7-3717-4358-9987-66B90DA1F093.htm"
 :source-bricscad NIL)

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

(:name "LAYERPALETTE"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYERPALETTE"
 :synopsis "Opens the modeless Layer Properties Manager."
 :options NIL
 :arguments NIL
 :description "Opens the modeless Layer Properties Manager palette."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DD91EB0C-5D3E-421E-BAB0-F4C2C292FD66.htm"
 :source-bricscad NIL)

(:name "LAYERPMODE"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYERPMODE"
 :synopsis "Turns on and off the tracking of changes made to layer settings for use by the LAYERP command."
 :options ("On" "Off")
 :arguments "Enter On or Off to enable or disable tracking of changes made to layer settings (as used by the LAYERP command)."
 :description "Turns on and off the tracking of changes made to layer settings for use by the LAYERP command. When on, it records modifications to layer settings; the LAYERP topic details which layer changes are tracked and which are excluded."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-249DBD51-2A59-4932-9E63-591C293D7FE9.htm"
 :source-bricscad NIL)

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

(:name "LAYERSTATESAVE"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYERSTATESAVE"
 :synopsis "Displays the New Layer State to Save dialog box, where you can provide a name and a description for a new layer state."
 :options NIL
 :arguments "The New Layer State to Save dialog box collects a name and description; the current layer settings are saved as a named layer state that can later be restored, edited, imported, and exported."
 :description "Displays the New Layer State to Save dialog box, where you provide a name and description for a new layer state that captures the current layer settings. Saved layer states can be restored, edited, imported, and exported for use across drawings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CA2A1FF0-0BF9-4D47-B268-23261B289035.htm"
 :source-bricscad NIL)

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

(:name "LAYOUTWIZARD"
 :category :PLOT
 :aliases NIL
 :intl-name "_LAYOUTWIZARD"
 :synopsis "Creates a new layout tab and specifies page and plot settings."
 :options NIL
 :arguments NIL
 :description "Creates a new layout tab and specifies page and plot settings by displaying the Layout wizard, which guides you through creating a new layout. A layout is a 2D working environment for creating drawing sheets."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-70FBE671-9B34-436E-A6B0-04C7A58D2057.htm"
 :source-bricscad NIL)

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

(:name "LAYVPI"
 :category :LAYER
 :aliases NIL
 :intl-name "_LAYVPI"
 :synopsis "Freezes selected layers in all layout viewports except the current viewport."
 :options ("Settings" "All Layouts" "Current Layout" "Block" "Entity" "None")
 :arguments "Select objects on the layer to be isolated in the viewport; Settings controls Layouts (All Layouts or Current Layout) and Block Selection (Block, Entity, or None); TILEMODE must be 0 with multiple paper space viewports."
 :description "Freezes the selected objects' layers in all layout viewports except the current viewport, automating the VP Freeze property in the Layer Properties Manager. It requires TILEMODE set to 0 and multiple paper space viewports."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DFCF08D6-5E63-4EC4-85D5-B1BA32008A36.htm"
 :source-bricscad NIL)

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

(:name "LIGHTLISTCLOSE"
 :category :RENDER
 :aliases NIL
 :intl-name "_LIGHTLISTCLOSE"
 :synopsis "Closes the Lights in Model palette."
 :options NIL
 :arguments NIL
 :description "Closes the Lights in Model palette."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-49126197-1723-47AB-876E-7F652678066B.htm"
 :source-bricscad NIL)

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

(:name "LTSCALE"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_LTSCALE"
 :synopsis "Sets the global linetype scale factor."
 :options NIL
 :arguments "Enter a new linetype scale factor (a numeric value); changing it regenerates the drawing. The default is 1.00, and smaller values produce more pattern repetitions per drawing unit."
 :description "Sets the global linetype scale factor, changing the scale factor of linetypes for all objects in a drawing. Changing the factor regenerates the drawing; the default is 1.00 and smaller values produce more pattern repetitions per drawing unit."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-47B3793A-37BF-45FC-94CB-670433ADD366.htm"
 :source-bricscad NIL)

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

(:name "MAKELISPAPP"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_MAKELISPAPP"
 :synopsis "Compiles one or more AutoLISP (LSP) source files into an application (VLX) file that can be distributed to users and protect your code."
 :options ("Make" "Properties" "Rebuild" "Wizard")
 :arguments NIL
 :description "Compiles one or more AutoLISP (LSP) source files into an application (VLX) file that can be distributed to users and that protects your code. It is available only when LISPSYS is set to 1; VLX files built with that setting include Unicode support and are incompatible with AutoCAD 2020 and earlier."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1A8B50AA-1DEA-4853-AAA8-09AF0827A0ED.htm"
 :source-bricscad NIL)

(:name "MARKUP"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_MARKUP"
 :synopsis "Opens the Markup Set Manager."
 :options NIL
 :arguments NIL
 :description "Opens the Markup Set Manager, used to view and manage markups on DWF or DWFx files. Reviewers mark up published designs in Autodesk Design Review and return the files, so designers can respond to the markups and republish them for further review cycles."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8B48AEB0-7BB2-47F9-B09C-90BD5246FB0E.htm"
 :source-bricscad NIL)

(:name "MARKUPASSIST"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_MARKUPASSIST"
 :synopsis "Analyzes an imported markup and can help place text callouts and revision clouds faster and with less manual effort."
 :options NIL
 :arguments NIL
 :description "Analyzes an imported markup and helps place text callouts and revision clouds faster and with less manual effort. It operates at the Command prompt to process imported markup files."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8B8F1A10-82C1-4FB8-BC0D-8E22CA25A97F.htm"
 :source-bricscad NIL)

(:name "MARKUPCLOSE"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_MARKUPCLOSE"
 :synopsis "Closes the Markup Set Manager."
 :options NIL
 :arguments NIL
 :description "Closes the Markup Set Manager window."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3D73A8F8-13A0-4FBE-A345-034B50291D8D.htm"
 :source-bricscad NIL)

(:name "MARKUPIMPORT"
 :category :ANNOTATION
 :aliases NIL
 :intl-name "_MARKUPIMPORT"
 :synopsis "Imports a marked up drawing (image/pdf) in-place into your DWG as a new trace."
 :options NIL
 :arguments NIL
 :description "Imports a marked-up drawing (an image or PDF) in place into the current DWG as a new trace. A -MARKUPIMPORT command-line variant also exists."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-193B08A6-74C5-4DB3-A80D-499746344B3B.htm"
 :source-bricscad NIL)

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

(:name "MATEDITORCLOSE"
 :category :RENDER
 :aliases NIL
 :intl-name "_MATEDITORCLOSE"
 :synopsis "Closes the Materials Editor."
 :options NIL
 :arguments NIL
 :description "Closes the Materials Editor."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-07E1F8D5-6840-4428-97CE-37917A5271D8.htm"
 :source-bricscad NIL)

(:name "MATEDITOROPEN"
 :category :RENDER
 :aliases NIL
 :intl-name "_MATEDITOROPEN"
 :synopsis "Opens the Materials Editor."
 :options NIL
 :arguments NIL
 :description "Opens the Materials Editor, which is displayed when the command is executed."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-31215BDF-E805-4AAF-A9BA-12CA1B48F62E.htm"
 :source-bricscad NIL)

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

(:name "MATERIALATTACH"
 :category :RENDER
 :aliases NIL
 :intl-name "_MATERIALATTACH"
 :synopsis "Associates materials with layers."
 :options NIL
 :arguments NIL
 :description "Associates materials with layers. The Material Attachment Options dialog box is displayed, enabling you to link materials to layers."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C8761059-E777-46E2-A2F1-AAB0EAF0FF15.htm"
 :source-bricscad NIL)

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

(:name "MATERIALSCLOSE"
 :category :RENDER
 :aliases NIL
 :intl-name "_MATERIALSCLOSE"
 :synopsis "Closes the Materials Browser."
 :options NIL
 :arguments NIL
 :description "Closes the Materials Browser. You can reopen it using the MATBROWSEROPEN command."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6ECF14D2-7642-4997-8FE3-E6F6F6313E22.htm"
 :source-bricscad NIL)

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

(:name "MEASUREGEOM"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_MEASUREGEOM"
 :synopsis "Measures the distance, radius, angle, area, and volume of selected objects, a sequence of points, or dynamically."
 :options ("Quick" "Distance" "Radius" "Angle" "Area" "Volume" "Mode" "eXit")
 :arguments "Supplies an option keyword (Distance, Radius, Angle, Area, Volume, Quick, Mode, or eXit) followed by the points or objects that option requires."
 :description "MEASUREGEOM performs calculations similar to the AREA, DIST, and MASSPROP commands, displaying results at the Command prompt and in dynamic tooltips using the current units format. The Quick option reviews dimensions dynamically in plan view, marking 90-degree angles with orange squares. Clicking an enclosed space highlights it green and shows its value, and Shift-click accumulates multiple areas and island perimeters."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5D5B0EE1-DD90-47AE-8A55-642FBFF5E4E4.htm"
 :source-bricscad NIL)

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

(:name "MESH"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESH"
 :synopsis "Creates a 3D mesh primitive object such as a box, cone, cylinder, pyramid, sphere, wedge, or torus."
 :options ("Box" "Cone" "Cylinder" "Pyramid" "Sphere" "Wedge" "Torus"
           "Settings")
 :arguments "Supplies a primitive keyword (Box, Cone, Cylinder, Pyramid, Sphere, Wedge, Torus, or Settings) followed by the defining points and dimensions for that primitive."
 :description "The basic mesh forms, known as mesh primitives, are the equivalent of the primitive forms for 3D solids. You can reshape mesh objects by smoothing, creasing, refining, and splitting faces. You can also drag edges, faces, and vertices to mold the overall form."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C0251558-62FC-4169-ADA2-DED728278556.htm"
 :source-bricscad NIL)

(:name "MESHCAP"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHCAP"
 :synopsis "Creates a mesh face that connects open edges."
 :options ("Edges" "Chain")
 :arguments "Selects connecting mesh edges (Edges or Chain), then answers Try to chain closed loop? with Y or N to create the new mesh face."
 :description "You can close gaps in mesh objects by selecting the edges of the surrounding mesh faces. For best results, the faces should be on the same plane."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A9EC33F4-D6BF-45D4-AF68-DCA81D3B0BBE.htm"
 :source-bricscad NIL)

(:name "MESHCOLLAPSE"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHCOLLAPSE"
 :synopsis "Merges the vertices of selected mesh faces or edges."
 :options NIL
 :arguments "Selects a mesh face or edge to collapse."
 :description "You can cause the vertices of surrounding mesh faces to converge at the center of a selected edge or face. The shapes of surrounding faces change to accommodate the loss of one or more vertices."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-134A56D9-6F56-4DE0-BF65-96A974E35337.htm"
 :source-bricscad NIL)

(:name "MESHCREASE"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHCREASE"
 :synopsis "Sharpens the edges of selected mesh subobjects."
 :options ("Always")
 :arguments "Selects mesh subobjects to crease, then supplies a crease value (or Always; 0 removes an existing crease)."
 :description "You can sharpen, or crease, the edges of mesh objects. Creasing deforms mesh faces and edges that are adjacent to the selected subobject. Creases added to mesh that has no smoothness are not apparent until the mesh is smoothed."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F176266D-C615-4A0B-95ED-E8FBE1D4E392.htm"
 :source-bricscad NIL)

(:name "MESHEXTRUDE"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHEXTRUDE"
 :synopsis "Extends a mesh face into 3D space."
 :options ("Direction" "Path" "Taper angle" "Setting")
 :arguments "Selects the mesh face(s) to extrude, then supplies a height of extrusion or an option (Direction, Path, or Taper angle); Setting controls whether adjacent mesh faces are joined."
 :description "MESHEXTRUDE extrudes or extends mesh faces into three dimensions. You can control the extrusion shape and set whether extruding adjacent faces produces joined or separate results, using height-based, directional, path-based, or tapered extrusion methods."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5F78E17E-06B7-4157-909D-5CBED1570246.htm"
 :source-bricscad NIL)

(:name "MESHMERGE"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHMERGE"
 :synopsis "Merges adjacent faces into a single face."
 :options NIL
 :arguments "Selects adjacent faces to merge."
 :description "You can merge two or more adjacent mesh faces to form a single face. The merge operation is performed only on mesh faces that are adjacent; other types of subobjects are removed from the selection set. Merging faces that wrap a corner can have unintended results (the mesh might no longer be watertight), so for best results restrict merging to faces on the same plane."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-11D222C2-7393-4C5F-97A1-8E0D530D81D0.htm"
 :source-bricscad NIL)

(:name "MESHREFINE"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHREFINE"
 :synopsis "Multiplies the number of faces in selected mesh objects or faces."
 :options NIL
 :arguments "Selects the mesh objects or mesh face subobjects to refine."
 :description "Refining a mesh object increases the number of editable faces, providing additional control over fine modeling details. To preserve program memory, you can refine specific faces instead of the entire object. Refining an object resets its smoothing level to 0, which becomes the new baseline below which smoothness can no longer be decreased; refining a subobject does not reset the smoothing level."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-36077075-B5DF-452E-A9C1-8575A4763864.htm"
 :source-bricscad NIL)

(:name "MESHSMOOTH"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHSMOOTH"
 :synopsis "Converts 3D objects such as polygon meshes, surfaces, and solids to mesh objects."
 :options NIL
 :arguments "Selects the 3D objects (solids, surfaces, 3D faces, legacy meshes, regions, or closed polylines) to convert, then Enter to end selection."
 :description "Converts eligible 3D geometry (solids, surfaces, 3D faces, legacy meshes, regions, and closed polylines) into mesh objects, with smoothness governed by the mesh tessellation settings. Use CONVTOSOLID or CONVTOSURFACE to reverse the conversion."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8823F3EB-A053-437A-94DB-081B654B8F3F.htm"
 :source-bricscad NIL)

(:name "MESHSMOOTHLESS"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHSMOOTHLESS"
 :synopsis "Decreases the level of smoothness for mesh objects by one level."
 :options NIL
 :arguments "Selects the mesh object(s) whose smoothness to decrease, then Enter to end selection."
 :description "Reduces the smoothness of selected mesh objects by one level. Smoothness can only be decreased for objects at level 1 or higher, refined objects cannot be decreased, and multiple objects at differing levels are each decreased by one level."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D8F075B5-3714-4C45-9564-4F2716BE3815.htm"
 :source-bricscad NIL)

(:name "MESHSPIN"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHSPIN"
 :synopsis "Spins the adjoining edge of two triangular mesh faces."
 :options NIL
 :arguments "Selects the first triangular mesh face, then the adjacent second triangular mesh face whose shared edge is spun."
 :description "Rotates the edge that joins two triangular mesh faces so the shared edge spins to intersect the apex of each face, modifying their shapes. Use MESHSPLIT with the Vertex option to first divide rectangular faces into triangular ones."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A4B6F1FF-68C3-433C-831A-E184667F4C3F.htm"
 :source-bricscad NIL)

(:name "MESHSPLIT"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHSPLIT"
 :synopsis "Splits a mesh face into two faces."
 :options ("Vertex")
 :arguments "Selects the mesh face to split, then the start and end points on its edges (or the Vertex option)."
 :description "Splits a mesh face to add detail to an area without fully refining it, using specified start and end points on face edges to control the split location. The Vertex option creates triangular faces from rectangular ones for precise work with MESHSPIN."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-09A02699-5AAB-40E9-B6DE-B8976708D2A8.htm"
 :source-bricscad NIL)

(:name "MESHUNCREASE"
 :category :|3D|
 :aliases NIL
 :intl-name "_MESHUNCREASE"
 :synopsis "Removes the crease from selected mesh faces, edges, or vertices."
 :options NIL
 :arguments "Selects the creased mesh faces, edges, or vertices to uncrease, then Enter to end selection."
 :description "Restores smoothness to mesh subobjects that have been creased. Creased subobjects can be selected without pressing Ctrl, and crease removal can also be done through the Properties palette by setting the Type value to None."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CD7FDDA6-DC23-4E1C-9607-45CB2DDC8434.htm"
 :source-bricscad NIL)

(:name "MIGRATEMATERIALS"
 :category :RENDER
 :aliases NIL
 :intl-name "_MIGRATEMATERIALS"
 :synopsis "Finds any legacy materials in Tool Palettes and converts them to generic type."
 :options NIL
 :arguments "NIL (no prompts; finds and converts legacy materials when invoked)."
 :description "Identifies outdated (legacy) materials within tool palettes and converts them to generic type materials. The converted materials are added to the Materials Browser library, which is stored in the Application Data folder."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-32007B6A-8B73-4F8C-A7DC-E72B6C646A74.htm"
 :source-bricscad NIL)

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

(:name "MLEDIT"
 :category :MODIFY
 :aliases NIL
 :intl-name "_MLEDIT"
 :synopsis "Edits multiline intersections, breaks, and vertices."
 :options NIL
 :arguments NIL
 :description "Opens the Multiline Edit Tools dialog box for modifying multiline objects. Multilines are composed of parallel lines called elements."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BDA85006-C833-4165-85A0-1788A92BC912.htm"
 :source-bricscad NIL)

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

(:name "MODEL"
 :category :VIEW
 :aliases NIL
 :intl-name "_MODEL"
 :synopsis "Switches from a named layout tab to the Model tab."
 :options NIL
 :arguments NIL
 :description "Returns to the Model tab from a named layout tab. On the Model tab you create drawings in model space and can make design changes, pan, and zoom without affecting layout viewport views; performance can be tuned with the LAYOUTREGENCTL system variable."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2FC06AB4-8085-407E-A54B-D44057AEDC3B.htm"
 :source-bricscad NIL)

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

(:name "MREDO"
 :category :EDIT
 :aliases NIL
 :intl-name "_MREDO"
 :synopsis "Reverses the effects of several previous UNDO or U commands."
 :options ("All" "Last")
 :arguments NIL
 :description "Reverses the effects of several previous UNDO or U commands, undoing multiple prior undo operations. You can specify the number of actions to reverse, or reverse all actions or the last action."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B7FA1535-51E4-4980-A6F7-CDF98C86B3B6.htm"
 :source-bricscad NIL)

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

(:name "MTEDIT"
 :category :TEXT
 :aliases NIL
 :intl-name "_MTEDIT"
 :synopsis "Edits multiline text."
 :options NIL
 :arguments NIL
 :description "Displays either the multiline text tab on the ribbon or the In-Place Text Editor to modify the formatting or content of the selected mtext object."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-435E2E51-D38D-4717-91F2-8229F32676B6.htm"
 :source-bricscad NIL)

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

(:name "NAVBAR"
 :category :VIEW
 :aliases NIL
 :intl-name "_NAVBAR"
 :synopsis "Provides access to viewing tools from a unified interface."
 :options ("On" "Off")
 :arguments NIL
 :description "The navigation bar provides access to product-specific viewing tools such as wheel, pan, and zoom functions from a unified interface. The command toggles display of the navigation bar."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-90981580-5028-4E74-A117-21EFA734017F.htm"
 :source-bricscad NIL)

(:name "NAVSMOTION"
 :category :VIEW
 :aliases NIL
 :intl-name "_NAVSMOTION"
 :synopsis "Provides an on-screen display for creating and playing back cinematic camera animations for design review, presentation, and bookmark-style navigation."
 :options NIL
 :arguments NIL
 :description "Provides an on-screen display (ShowMotion) for creating and playing back cinematic camera animations for design review, presentation, and bookmark-style navigation. The display is divided into three main parts: control bar, shot sequence thumbnails, and shot thumbnails."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4663E071-6D64-4892-AD27-8E629834535B.htm"
 :source-bricscad NIL)

(:name "NAVSWHEEL"
 :category :VIEW
 :aliases NIL
 :intl-name "_NAVSWHEEL"
 :synopsis "Provides access to enhanced navigation tools that are quickly accessible from the cursor."
 :options NIL
 :arguments NIL
 :description "Displays a wheel-based navigation interface accessible from the cursor; you press and drag on a wedge to select a navigation tool, then release to return to the wheel. In AutoCAD LT it displays a 2D Navigation wheel; in AutoCAD the display depends on the NAVSWHEELMODE system variable."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-07D418EE-9508-41F0-A7A1-46EDED94D10F.htm"
 :source-bricscad NIL)

(:name "NAVVCUBE"
 :category :VIEW
 :aliases NIL
 :intl-name "_NAVVCUBE"
 :synopsis "Indicates the current viewing direction. Dragging or clicking the ViewCube rotates the scene."
 :options ("ON" "OFF" "Properties")
 :arguments NIL
 :description "The ViewCube indicates the current viewing direction; dragging or clicking it rotates the scene. The command toggles ViewCube display or opens its settings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3889B35C-790A-4C95-9DF2-174CB956D227.htm"
 :source-bricscad NIL)

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

(:name "NEWSHOT"
 :category :VIEW
 :aliases NIL
 :intl-name "_NEWSHOT"
 :synopsis "Creates a named view with motion that is played back when viewed with ShowMotion."
 :options NIL
 :arguments NIL
 :description "Creates a named view with motion that is played back when viewed with ShowMotion. Displays the New View / Shot Properties dialog box with the Shot Properties tab active."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-AE028758-AF87-474E-ACB9-5E3ED57EFEA6.htm"
 :source-bricscad NIL)

(:name "NEWVIEW"
 :category :VIEW
 :aliases NIL
 :intl-name "_NEWVIEW"
 :synopsis "Saves a new, named view from the display in the current viewport, or by defining a rectangular window."
 :options NIL
 :arguments NIL
 :description "Saves a new, named view from the display in the current viewport, or by defining a rectangular window. Displays the New View / Shot Properties dialog box with the View Properties tab active (AutoCAD), or the New View dialog box (AutoCAD LT)."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F465283F-5208-4E6C-970E-C7460C3ECBB6.htm"
 :source-bricscad NIL)

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

(:name "OFFSETEDGE"
 :category :MODIFY
 :aliases NIL
 :intl-name "_OFFSETEDGE"
 :synopsis "Creates a closed polyline or spline object that is offset at a specified distance from the edges of a selected planar face on a 3D solid or surface."
 :options ("Distance" "Corner" "Sharp" "Rounded")
 :arguments "Selects a planar face on a 3D solid or surface, then specifies a through point or the Distance option (an offset value plus a point indicating the offset side); the Corner option sets Sharp or Rounded corners."
 :description "Generates offset geometry from a planar face on a 3D solid or surface; the resulting closed polyline or spline lies on the same plane as the face and can be placed inside or outside the original edges. The offset object can then be used with PRESSPULL or EXTRUDE to create new solids."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F18EAB59-3921-429A-80CE-567AB8918E81.htm"
 :source-bricscad NIL)

(:name "OLECONVERT"
 :category :EDIT
 :aliases NIL
 :intl-name "_OLECONVERT"
 :synopsis "Specifies a different source application for an embedded OLE object, and controls whether the OLE object is represented by an icon."
 :options NIL
 :arguments NIL
 :description "Specifies a different source application for a selected embedded OLE object and controls whether the OLE object is represented by an icon. An OLE object must be selected before running the command; the Convert dialog box is then displayed."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3D953E45-345E-4A8A-9E6E-C47056F58236.htm"
 :source-bricscad NIL)

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

(:name "OLERESET"
 :category :EDIT
 :aliases NIL
 :intl-name "_OLERESET"
 :synopsis "Restores the selected OLE object to its original size and shape."
 :options NIL
 :arguments NIL
 :description "Restores the selected OLE object to its original size and shape, useful when an OLE object has been resized or reshaped and needs to be returned to its unaltered state."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DE1FEACE-92AA-4B3C-B896-1A899C79EE5B.htm"
 :source-bricscad NIL)

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

(:name "OPENDWFMARKUP"
 :category :FILE
 :aliases NIL
 :intl-name "_OPENDWFMARKUP"
 :synopsis "Opens a DWF or DWFx file that contains markups."
 :options NIL
 :arguments NIL
 :description "Displays the Open Markup DWF dialog box (a standard file selection dialog box) to load a DWF or DWFx file that contains markups into the Markup Set Manager for review. Opening a digitally signed DWFx file warns that saving a new version invalidates the attached digital signature."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D27DCF31-179A-42A4-A59E-FA50C2392B0E.htm"
 :source-bricscad NIL)

(:name "OPENFROMWEBMOBILE"
 :category :FILE
 :aliases NIL
 :intl-name "_OPENFROMWEBMOBILE"
 :synopsis "Opens a drawing file from your online Autodesk Account."
 :options NIL
 :arguments NIL
 :description "Opens a drawing file from your online Autodesk Account, working like the OPEN command but defaulting to the AutoCAD Web & Mobile folder. The Open from AutoCAD Web & Mobile dialog box is displayed."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-79C33702-07E6-4261-92E1-D69595ED1B6D.htm"
 :source-bricscad NIL)

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

(:name "ORTHO"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_ORTHO"
 :synopsis "Constrains cursor movement to the horizontal or vertical direction."
 :options NIL
 :arguments NIL
 :description "Constrains cursor movement to the horizontal or vertical direction relative to the current UCS, where horizontal aligns with the X axis and vertical with the Y axis; in 3D views it also constrains movement parallel to the Z axis. It improves precision when specifying points with a pointing device."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-128AC5D7-72B0-498F-958D-7F619A73EC5F.htm"
 :source-bricscad NIL)

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

(:name "PARAMETERS"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_PARAMETERS"
 :synopsis "Opens the Parameters Manager palette that includes all dimensional constraint parameters, reference parameters, and user variables in the current drawing."
 :options NIL
 :arguments NIL
 :description "Opens the Parameters Manager palette, which lists all dimensional constraint parameters, reference parameters, and user variables in the current drawing. Its content varies depending on whether it is accessed from the drawing or the Block Editor. A -PARAMETERS command-line variant also exists."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9A7DB9D7-A577-45DB-B176-F1F2297814D6.htm"
 :source-bricscad NIL)

(:name "PARAMETERSCLOSE"
 :category :PARAMETRIC
 :aliases NIL
 :intl-name "_PARAMETERSCLOSE"
 :synopsis "Closes the Parameters Manager palette."
 :options NIL
 :arguments NIL
 :description "Closes the Parameters Manager palette. It is the counterpart to the PARAMETERS command, which opens the palette for managing dimensional constraints, reference parameters, and user variables."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9D53789F-0468-45F9-ABD9-8CA78827878D.htm"
 :source-bricscad NIL)

(:name "PARTIALOAD"
 :category :FILE
 :aliases NIL
 :intl-name "_PARTIALOAD"
 :synopsis "Loads additional geometry into a partially opened drawing."
 :options NIL
 :arguments "NIL (opens the Partial Load dialog box; usable only in a partially open drawing)."
 :description "Loads additional geometry into a partially opened drawing. The Partial Load dialog box is displayed. PARTIALOAD can be used only in a partially open drawing, and any information loaded with it cannot be unloaded, not even with UNDO."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4AC37B22-86C9-4CF9-9DB7-4B1E511918B5.htm"
 :source-bricscad NIL)

(:name "PARTIALOPEN"
 :category :FILE
 :aliases NIL
 :intl-name "_PARTIALOPEN"
 :synopsis "Loads geometry and named objects from a selected view or layer into a drawing."
 :options NIL
 :arguments "When FILEDIA is set to 0, entering PARTIALOPEN prompts for the drawing name to open, the view to load, the layers to load, and whether to unload all xrefs on open; otherwise partial opening is done via OPEN and Partial Open in the Select File dialog box."
 :description "Loads geometry and named objects from a selected view or layer into a drawing. It is recommended that you partially open a drawing by using OPEN and choosing Partial Open in the Select File dialog box."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-762EC6D8-29AC-4797-B8BE-8C3AF5BE84FB.htm"
 :source-bricscad NIL)

(:name "PASTEASHYPERLINK"
 :category :EDIT
 :aliases NIL
 :intl-name "_PASTEASHYPERLINK"
 :synopsis "Creates a hyperlink to a file, and associates it with a selected object."
 :options NIL
 :arguments "NIL (no input sequence documented; after copying a document to the Clipboard you select the object to associate the hyperlink with)."
 :description "Creates a hyperlink to a file and associates it with a selected object. First copy a document (such as a text, spreadsheet, drawing, or image file) to the Clipboard, then use this command to associate a hyperlink to that document with any selected object."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E7CA3B34-BE5D-44CB-AFAE-5A220EB5911F.htm"
 :source-bricscad NIL)

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

(:name "PCEXTRACTCENTERLINE"
 :category :DRAW
 :aliases NIL
 :intl-name "_PCEXTRACTCENTERLINE"
 :synopsis "Creates a line through the center axis of a cylindrical segment in a point cloud."
 :options NIL
 :arguments "Selects a cylindrical segment in the point cloud; a preview of the centerline is shown before it is placed."
 :description "Creates a line through the center axis of a cylindrical segment in a point cloud. This is useful for creating reference geometry from a point cloud."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-256B8CF8-AE03-4D76-9A8B-78A39400CFB4.htm"
 :source-bricscad NIL)

(:name "PCEXTRACTCORNER"
 :category :|3D|
 :aliases NIL
 :intl-name "_PCEXTRACTCORNER"
 :synopsis "Creates a point object at the intersection of three planar segments in a point cloud."
 :options NIL
 :arguments "Select first plane; select second plane; select third plane (three planar segments in a point cloud)."
 :description "Creates a point object where three planar segments intersect in a point cloud. Point appearance is governed by PDMODE and PDSIZE; if PDMODE is 0 or 1 it is set to 35 for better visibility."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-14D33BF5-DA2A-4788-A8B7-86477972977C.htm"
 :source-bricscad NIL)

(:name "PCEXTRACTEDGE"
 :category :|3D|
 :aliases NIL
 :intl-name "_PCEXTRACTEDGE"
 :synopsis "Infers the intersection between two adjacent planar segments, and creates a line along the edge."
 :options NIL
 :arguments "Select first plane; select second (adjacent) plane; the intersection is inferred and an edge line is created."
 :description "Creates reference geometry from point cloud data by inferring where two adjacent planar segments meet and drawing a line along that edge."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4567D48E-590E-403A-AAC2-0579E4592672.htm"
 :source-bricscad NIL)

(:name "PCEXTRACTSECTION"
 :category :|3D|
 :aliases NIL
 :intl-name "_PCEXTRACTSECTION"
 :synopsis "Generates 2D geometry from a section through a point cloud."
 :options NIL
 :arguments "Select a point cloud that has a section object with live section enabled; the Extract Section Line from Point Cloud dialog box then appears."
 :description "Extracts 2D section geometry from a point cloud intersected with a section plane object. Live section must be enabled on the section object, and the section boundary determines which points are used to generate the geometry."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8C66CA40-AA84-439F-9A4F-0D675F2578A9.htm"
 :source-bricscad NIL)

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

(:name "PDFSHXTEXT"
 :category :TEXT
 :aliases NIL
 :intl-name "_PDFSHXTEXT"
 :synopsis "Converts the SHX geometry imported from PDF files into individual multiline text objects."
 :options ("Settings")
 :arguments "Specify first corner and opposite corner (window/crossing) to select the SHX geometry to convert; a Settings option opens the PDF Text Recognition Settings dialog box."
 :description "Converts geometry representing SHX-font text imported from PDF files into editable mtext objects. PDF cannot store AutoCAD SHX fonts natively so SHX text is preserved as geometry; this command restores editability. Asian-language big fonts are not supported."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A0F80ABD-0F1C-47FB-B7E3-E4C699DAEE83.htm"
 :source-bricscad NIL)

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

(:name "PERFANALYZER"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_PERFANALYZER"
 :synopsis "Opens the Performance Analyzer palette from which you can diagnose operations in AutoCAD that seem slow or unresponsive."
 :options ("Start Recording" "Stop Recording" "Cancel")
 :arguments "No command-line prompts; opens the Performance Analyzer palette whose buttons control recording (Start Recording, Stop Recording, Cancel)."
 :description "Opens the Performance Analyzer palette used to diagnose slow or unresponsive AutoCAD operations. It must run with Administrator privileges, and users should return to limited privileges after use."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4D50F190-E406-4548-8847-2F0B96606EE8.htm"
 :source-bricscad NIL)

(:name "PERFANALYZERCLOSE"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_PERFANALYZERCLOSE"
 :synopsis "Closes the Performance Analyzer palette."
 :options NIL
 :arguments "No prompts or arguments; entering the command closes the Performance Analyzer palette."
 :description "Closes the Performance Analyzer palette. Alternatively, the Auto-hide option can collapse the palette when the cursor moves away from it."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-58E00F25-8B26-42B1-922B-802C18CD9DB8.htm"
 :source-bricscad NIL)

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

(:name "PLANESURF"
 :category :|3D|
 :aliases NIL
 :intl-name "_PLANESURF"
 :synopsis "Creates a planar surface."
 :options ("Object")
 :arguments "Specify first corner then other corner to define a rectangular planar surface, or choose the Object option and select one or more closed objects; DELOBJ controls deletion of selected objects."
 :description "Creates a planar surface either by specifying opposite corners of a rectangle (the surface aligns with the work plane) or by selecting closed objects (lines, circles, arcs, ellipses, elliptical arcs, 2D polylines, planar 3D polylines, and 2D splines). SURFU and SURFV control the number of display lines on the surface."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5E36FD08-A8AC-4ADC-B5BF-6162AE64E3BD.htm"
 :source-bricscad NIL)

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

(:name "POINTCLOUDMANAGER"
 :category :VIEW
 :aliases NIL
 :intl-name "_POINTCLOUDMANAGER"
 :synopsis "Displays the Point Cloud Manager palette, used to control display of point cloud projects, regions, and scans."
 :options ("Tree View" "List View" "Project" "Regions" "Unassigned Points"
           "Scans" "Hide/Show" "Search")
 :arguments "No prompts; opens the Point Cloud Manager palette. (command \"POINTCLOUDMANAGER\") takes no further arguments; all interaction is through the palette."
 :description "Opens the Point Cloud Manager palette for point cloud data attached to the drawing, presenting hierarchically organized project files, regions, individual scans, and unassigned point sections, with controls to toggle visibility, highlight regions, and search by name."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A8CA3DA7-E19A-49C9-95C5-46B29235732F.htm"
 :source-bricscad NIL)

(:name "POINTCLOUDMANAGERCLOSE"
 :category :VIEW
 :aliases NIL
 :intl-name "_POINTCLOUDMANAGERCLOSE"
 :synopsis "Closes the Point Cloud Manager."
 :options NIL
 :arguments "No prompts or arguments; closes the Point Cloud Manager palette."
 :description "Terminates (closes) the Point Cloud Manager palette. No additional descriptive text is provided on the page."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D2D62D65-B03E-4BD9-80E3-6B924E5E7A28.htm"
 :source-bricscad NIL)

(:name "POINTCLOUDSTYLIZE"
 :category :VIEW
 :aliases NIL
 :intl-name "_POINTCLOUDSTYLIZE"
 :synopsis "Controls the coloration of point clouds."
 :options ("RGB" "Object Color" "Normal" "Intensity" "Elevation"
           "Classification")
 :arguments "Presents a stylization selection (dropdown) where one of the coloring options is chosen; unavailable options are grayed out based on data present in the scan."
 :description "By default point clouds display RGB scan colors, but this command lets you apply alternate coloring schemes: RGB (scan colors or inferred grayscale), Object Color (point cloud object color property), Normal (point direction), Intensity (laser pulse return intensity, customizable Spectrum), Elevation (Z values, customizable Earth), and Classification (LAS standard classification). Availability of each option depends on the data present in the source scan."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D07C9957-EAF1-4BA7-93F9-CF26AE4376EA.htm"
 :source-bricscad NIL)

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

(:name "PRESSPULL"
 :category :|3D|
 :aliases NIL
 :intl-name "_PRESSPULL"
 :synopsis "Dynamically modifies objects by extrusion and offset."
 :options ("Multiple")
 :arguments "Prompts: \"Select object or bounded area\" then, depending on selection, \"Specify extrusion height\" (for 2D objects) or \"Specify offset distance\" (for 3D solid faces) — move cursor or enter a distance; repeats until Esc/Enter/spacebar."
 :description "Provides visual feedback as you move the cursor after selecting a 2D object, a closed boundary area, or a 3D solid face. Open 2D objects extrude to surfaces, closed 2D objects and bounded areas extrude to 3D solids, and 3D solid faces are offset to expand or condense the solid. The command repeats automatically until terminated with Esc, Enter, or spacebar; the Multiple option (or Shift+click) specifies multiple selections."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9D072BB2-D97F-41DB-8414-41BC83A16EFA.htm"
 :source-bricscad NIL)

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

(:name "PSOUT"
 :category :FILE
 :aliases NIL
 :intl-name "_PSOUT"
 :synopsis "Creates a PostScript file from a DWG file."
 :options NIL
 :arguments "Displays the Create PostScript File dialog box; supplies a file name/location and converts the drawing to Encapsulated PostScript (EPS)."
 :description "Displays the Create PostScript File dialog box and converts the drawing file into Encapsulated PostScript (EPS) format."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EBF19D46-BF5B-41B6-8930-AD98E5E083AD.htm"
 :source-bricscad NIL)

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

(:name "PTYPE"
 :category :DRAW
 :aliases NIL
 :intl-name "_PTYPE"
 :synopsis "Specifies the display style and size of point objects."
 :options NIL
 :arguments "Displays the Point Style dialog box; supplies the point display style and size settings."
 :description "Controls how point objects appear in the drawing by displaying the Point Style dialog box, which provides the interface for configuring point display style and dimensions."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2ECD656C-989D-40EE-8D1A-AF010A5CD2A2.htm"
 :source-bricscad NIL)

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

(:name "PURGEAECDATA"
 :category :FILE
 :aliases NIL
 :intl-name "_PURGEAECDATA"
 :synopsis "Removes the invisible AEC data (AutoCAD Architecture and AutoCAD Civil 3D custom objects) in the drawing."
 :options ("Yes" "No")
 :arguments "Prompts \"Purge the Invisible AEC Data?\" requiring a Yes/No response."
 :description "Removes invisible AEC objects (AutoCAD Architecture and AutoCAD Civil 3D custom objects) from the drawing at the command prompt. It cannot process drawings with attached xrefs and cancels if visible AEC objects are detected; the Civil 3D Object Enabler is required to purge Civil 3D custom objects. Use the PURGE command instead to remove unused named items such as block definitions."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-43A97087-BC81-44D3-AFCA-F9FF675A7870.htm"
 :source-bricscad NIL)

(:name "PUSHTODOCSCLOSE"
 :category :FILE
 :aliases ("P2DCLOSE")
 :intl-name "_PUSHTODOCSCLOSE"
 :synopsis "Closes the Push to Autodesk Docs palette."
 :options NIL
 :arguments "None; (command \"PUSHTODOCSCLOSE\") takes no further input — it closes the Push to Autodesk Docs palette."
 :description "Closes the Push to Autodesk Docs palette. An Auto-hide option can collapse the palette when the cursor is moved away from it. P2DCLOSE is a predefined alias for this command."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-540D45AB-5039-4231-B0C9-D64721BA75ED.htm"
 :source-bricscad NIL)

(:name "PUSHTODOCSOPEN"
 :category :FILE
 :aliases ("P2D")
 :intl-name "_PUSHTODOCSOPEN"
 :synopsis "Opens the Push to Autodesk Docs palette where you can select AutoCAD layouts to upload as PDFs to Autodesk Docs."
 :options NIL
 :arguments "None; (command \"PUSHTODOCSOPEN\") takes no further input — it opens the Push to Autodesk Docs palette for selecting layouts, setting PDF file names, and choosing a destination folder."
 :description "Opens the Push to Autodesk Docs palette, where you select AutoCAD layouts (sheets) to upload as PDFs to Autodesk Docs. The palette provides sections to add/remove layouts and load/save sheet lists, to edit the PDF file name (formatted as <drawing name>-<layout name>.PDF), and to select the destination project and folder in Autodesk Docs. P2D is a predefined alias for this command."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C5144996-E3D2-4129-98BB-9B226A5D6E61.htm"
 :source-bricscad NIL)

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

(:name "QUICKCUI"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_QUICKCUI"
 :synopsis "Displays the Customize User Interface Editor in a collapsed state."
 :options NIL
 :arguments "None; (command \"QUICKCUI\") takes no further input — it displays the Customize User Interface (CUI) Editor in a collapsed state."
 :description "Displays the Customize User Interface Editor in a collapsed state. For more information, see CUI in the Command Reference, or User Interface Customization in the Customization Guide."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F85443FC-B41F-4B6D-AC8F-698EDC96BCB2.htm"
 :source-bricscad NIL)

(:name "QUICKPROPERTIES"
 :category :VIEW
 :aliases NIL
 :intl-name "_QUICKPROPERTIES"
 :synopsis "Displays quick property data for selected objects."
 :options NIL
 :arguments "None; (command \"QUICKPROPERTIES\") takes no further input — it displays the Quick Properties palette for the selected objects."
 :description "Displays the Quick Properties palette that shows a customizable list of object properties for one or more selected objects. The behavior of the Quick Properties palette is controlled by settings on the Quick Properties tab of the Drafting Settings dialog box (DSETTINGS). The QPMODE system variable controls whether the palette is displayed automatically when objects are selected."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D3D5A070-C448-4D23-86EF-F2069B342F26.htm"
 :source-bricscad NIL)

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

(:name "QVDRAWING"
 :category :VIEW
 :aliases NIL
 :intl-name "_QVDRAWING"
 :synopsis "Displays open drawings and layouts in a drawing using preview images."
 :options NIL
 :arguments "None; (command \"QVDRAWING\") takes no further input — it displays the two-level preview-image structure of open drawings and their layouts."
 :description "Displays a two-level structure of preview images at the bottom of the application. The first level displays the images of open drawings and the second level displays the images for model space and layouts in a drawing."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E0DEEC79-D8D3-4B27-B1B7-F9E36180C27E.htm"
 :source-bricscad NIL)

(:name "QVDRAWINGCLOSE"
 :category :VIEW
 :aliases NIL
 :intl-name "_QVDRAWINGCLOSE"
 :synopsis "Closes preview images of open drawings and their layouts."
 :options NIL
 :arguments "None; (command \"QVDRAWINGCLOSE\") takes no further input — it closes the preview images of open drawings and their layouts."
 :description "Closes preview images of open drawings and their layouts."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2AF12B5B-9812-4239-A648-64996A80A1DB.htm"
 :source-bricscad NIL)

(:name "QVLAYOUT"
 :category :VIEW
 :aliases NIL
 :intl-name "_QVLAYOUT"
 :synopsis "Displays preview images of model space and layouts for the current drawing."
 :options NIL
 :arguments "None; (command \"QVLAYOUT\") takes no further input — it displays preview images of model space and layouts for the current drawing."
 :description "Preview images of model space and layouts for the current drawing are displayed in a row at the bottom of the application."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A8128F99-85F5-498C-90EE-766E7787EBA6.htm"
 :source-bricscad NIL)

(:name "QVLAYOUTCLOSE"
 :category :VIEW
 :aliases NIL
 :intl-name "_QVLAYOUTCLOSE"
 :synopsis "Closes preview images of model space and layouts in the current drawing."
 :options NIL
 :arguments "None; (command \"QVLAYOUTCLOSE\") takes no further input — it closes the preview images of model space and layouts in the current drawing."
 :description "Closes preview images of model space and layouts in the current drawing."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B597AF81-02AC-4F1A-8131-DDBEFDDB336F.htm"
 :source-bricscad NIL)

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

(:name "REGEN3"
 :category :RENDER
 :aliases NIL
 :intl-name "_REGEN3"
 :synopsis "Regenerates the views in a drawing to repair anomalies in the display of 3D solids and surfaces."
 :options NIL
 :arguments NIL
 :description "When a 3D display problem occurs, REGEN3 rebuilds all 3D graphics in the displayed views, including all 3D solid and surface tessellations."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-811C3544-0660-41C6-AB93-47DC1E86E5BC.htm"
 :source-bricscad NIL)

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

(:name "RENDERCROP"
 :category :RENDER
 :aliases NIL
 :intl-name "_RENDERCROP"
 :synopsis "Renders a specified rectangular area, called a crop window, within a viewport."
 :options NIL
 :arguments "Two points: the first corner (Pick crop window to render (first point)) and the opposite second point defining the crop window."
 :description "Renders the contents within a specified rectangular region of the viewport while leaving the remainder unchanged, useful for testing render settings and effects on a portion of the model. The current render destination and rendering procedure are disregarded during this operation."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D5187468-D7BA-49BD-A7FA-6FE7EB5A80C4.htm"
 :source-bricscad NIL)

(:name "RENDERENVIRONMENT"
 :category :RENDER
 :aliases NIL
 :intl-name "_RENDERENVIRONMENT"
 :synopsis "Controls the settings related to the rendering environment."
 :options NIL
 :arguments NIL
 :description "Displays the Render Environment & Exposure palette, which is used to set up image-based lighting (IBL), lighting exposure, or a background image."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1DC47F52-39EA-4AD0-9D69-16EBB37FC81A.htm"
 :source-bricscad NIL)

(:name "RENDEREXPOSURECLOSE"
 :category :RENDER
 :aliases NIL
 :intl-name "_RENDEREXPOSURECLOSE"
 :synopsis "Closes the Render Environment & Exposure palette."
 :options NIL
 :arguments NIL
 :description "Closes the Render Environment & Exposure palette when it is currently displayed. Rendering environment and exposure settings that affect rendered images can be modified using the RENDEREXPOSURE command prior to executing the RENDER command."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E0D3E242-42C9-4681-8CA2-96ED88B4201E.htm"
 :source-bricscad NIL)

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

(:name "RENDERPRESETSCLOSE"
 :category :RENDER
 :aliases NIL
 :intl-name "_RENDERPRESETSCLOSE"
 :synopsis "Closes the Render Presets Manager palette."
 :options NIL
 :arguments NIL
 :description "Closes the Render Presets Manager palette if it is currently visible, whether in an auto-hidden or open state."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-551FE653-C249-41B4-80A9-8462EB8CD88A.htm"
 :source-bricscad NIL)

(:name "RENDERWINDOW"
 :category :RENDER
 :aliases NIL
 :intl-name "_RENDERWINDOW"
 :synopsis "Displays the Render window without starting a rendering operation."
 :options NIL
 :arguments NIL
 :description "Opens the Render window, but no rendering starts automatically. Use the RENDER command separately to render the current drawing view."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A17D4D1E-C814-4EA3-83B5-80EE3FE8C03E.htm"
 :source-bricscad NIL)

(:name "RENDERWINDOWCLOSE"
 :category :RENDER
 :aliases NIL
 :intl-name "_RENDERWINDOWCLOSE"
 :synopsis "Closes the Render window."
 :options NIL
 :arguments NIL
 :description "If the Render window is currently displayed, it is closed. A rendered image of a model can be created with the RENDER command or the Render window can be displayed with the RENDERWINDOW command."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8C78739A-A90D-4A01-B665-77E116D595EC.htm"
 :source-bricscad NIL)

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

(:name "REVCLOUDPROPERTIES"
 :category :MODIFY
 :aliases NIL
 :intl-name "_REVCLOUDPROPERTIES"
 :synopsis "Controls the approximate chord length for the arcs in a selected revision cloud."
 :options ("Arc length")
 :arguments "Select a revision cloud object, then specify an approximate chord length for each arc (the distance between the arc endpoints); the default derives from the first revision cloud created in the drawing."
 :description "Adjusts the arc chord-length property of an existing, selected revision cloud object. The chord length is the distance between the endpoints of each arc; the REVCLOUDARCVARIANCE system variable controls whether the arc chord lengths vary or are uniform. Can also be set through the Properties palette."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3E6C3A78-D839-4555-8E0D-721C247D67DE.htm"
 :source-bricscad NIL)

(:name "REVERSE"
 :category :MODIFY
 :aliases NIL
 :intl-name "_REVERSE"
 :synopsis "Reverses the vertices of selected lines, polylines, splines, and helixes, useful for linetypes with included text or wide polylines with differing beginning and ending widths."
 :options ("Select objects")
 :arguments "Select the lines, polylines, splines, or helixes whose vertex order is to be reversed."
 :description "Reverses the vertex order of selected lines, polylines, splines, and helixes. This is useful when a linetype containing text appears upside down because of the relative rotation set in the LIN file; reversing the vertices flips such text accordingly. Text specified as upright is not affected."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EAE8C2C3-B780-4501-9CBD-C06346CC9F2E.htm"
 :source-bricscad NIL)

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

(:name "RPREF"
 :category :RENDER
 :aliases ("RPP")
 :intl-name "_RPREF"
 :synopsis "Displays the Render Presets Manager palette used to configure rendering settings."
 :options NIL
 :arguments "Takes no command-line arguments; invoking it opens the Render Presets Manager palette where predefined or custom render settings are chosen."
 :description "Displays the Render Presets Manager palette, which is used to configure rendering settings by choosing from predefined render settings or specifying custom settings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EA823109-6AFA-4993-9911-71C55A408196.htm"
 :source-bricscad NIL)

(:name "RPREFCLOSE"
 :category :RENDER
 :aliases NIL
 :intl-name "_RPREFCLOSE"
 :synopsis "Closes the Render Settings Manager palette."
 :options NIL
 :arguments "Takes no arguments; if the palette is displayed (open or auto-hidden) it is closed."
 :description "Closes the Render Settings Manager palette. If the palette is currently displayed, either in an auto-hidden state or an open state, it is closed. The RPREF command displays the palette."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D806BB9F-DE46-4C0C-A8BE-5BB0CC33D53C.htm"
 :source-bricscad NIL)

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

(:name "SAVETOWEBMOBILE"
 :category :FILE
 :aliases NIL
 :intl-name "_SAVETOWEBMOBILE"
 :synopsis "Saves a copy of the current drawing to your Autodesk Account."
 :options ("Package reference files")
 :arguments "Displays the Save to AutoCAD Web & Mobile dialog box; specify the file name and location (defaulting to the AutoCAD Web & Mobile folder) and optionally package reference files (xrefs and images) as a compressed *.dwgzip."
 :description "Saves a copy of the current drawing to your Autodesk Account so it can be accessed from desktop, web, and mobile devices with an AutoCAD subscription. The Save to AutoCAD Web & Mobile dialog box appears; like SAVEAS it defaults to the AutoCAD Web & Mobile folder and keeps the current DWG format (defaulting to AutoCAD 2018). Reference files can be packaged and become read-only to avoid conflicts between online and local versions; the companion command is OPENFROMWEBMOBILE."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A7507398-50B1-4B00-B79B-EB99A068DACA.htm"
 :source-bricscad NIL)

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

(:name "SCALETEXT"
 :category :TEXT
 :aliases NIL
 :intl-name "_SCALETEXT"
 :synopsis "Enlarges or reduces selected text objects without changing their locations."
 :options ("Existing" "Left" "Center" "Middle" "Right" "TL" "TC" "TR" "ML" "MC"
           "MR" "BL" "BC" "BR" "Scale factor" "Paper height" "Match object"
           "New model height")
 :arguments "Select the text objects; choose a base point option (Existing, Left, Center, Middle, Right, TL, TC, TR, ML, MC, MR, BL, BC, BR); then choose a scaling method — New model height (a text height for non-annotative objects), Paper height (for annotative objects), Match object (match another selected text object's size), or Scale factor (a reference length and a new length) — and supply the corresponding value."
 :description "Enlarges or reduces selected text objects without changing their locations. Each text object is scaled about a base point that you choose, so insertion points relative to the text are preserved. Scaling can be done by specifying a new model height, a paper height (for annotative objects), by matching another text object, or by a scale factor based on a reference length and a new length."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A6C97247-F81C-4D83-BF2B-BE9F6BD55EB0.htm"
 :source-bricscad NIL)

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

(:name "SCRIPTCALL"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_SCRIPTCALL"
 :synopsis "Executes a sequence of commands and nested scripts from a script file."
 :options NIL
 :arguments "Displays the Select Script File dialog box; enter the file name of a script (.scr) to run it. When FILEDIA is set to 0, SCRIPTCALL displays a prompt for the script file name instead of the dialog box."
 :description "Executes a sequence of commands and nested scripts from a script file. Unlike SCRIPT, SCRIPTCALL lets scripts execute nested scripts and commands from text files with an .scr extension, where each line holds a command executable at the Command prompt or a reference to another script file. The Select Script File dialog box is displayed to choose the script to run."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-77FF5E24-4ECD-41D6-BD8A-9DD5AAD468EE.htm"
 :source-bricscad NIL)

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

(:name "SECTIONPLANEJOG"
 :category :|3D|
 :aliases NIL
 :intl-name "_SECTIONPLANEJOG"
 :synopsis "Adds a jogged segment to a section object."
 :options NIL
 :arguments "Select the section object, then specify a point on the section line where the jog is added."
 :description "Adds a jog or angle to a section object; the jog is created on the section line, with the jogged segment placed at a 90-degree angle to it. The SECTIONPLANEJOG command was previously named JOGSECTION."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all (previously named JOGSECTION)"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4A6A1386-9247-47A2-9934-F62D328C5460.htm"
 :source-bricscad NIL)

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

(:name "SECTIONSPINNERS"
 :category :|3D|
 :aliases NIL
 :intl-name "_SECTIONSPINNERS"
 :synopsis "Displays the dialog box to set the increment value for the Section Object Offset and Slice Thickness controls in the Section Plane ribbon contextual tab."
 :options NIL
 :arguments "Takes no arguments; opens the Section Panel Spinner Controls dialog box."
 :description "Displays the dialog box to set the increment value for the Section Object Offset and Slice Thickness controls in the Section Plane ribbon contextual tab. The Section Panel Spinner Controls dialog box is displayed."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D8F761E3-BA9F-4DAE-8BAA-71170B015F6F.htm"
 :source-bricscad NIL)

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

(:name "SELECTCOUNT"
 :category :SELECTION
 :aliases NIL
 :intl-name "_SELECTCOUNT"
 :synopsis "Finds all objects within the current count that match the properties of the selected objects, and then adds them to the selection set."
 :options NIL
 :arguments "Takes no arguments; select one or more objects during an active counting operation to add matching objects to the selection set."
 :description "Finds all objects within the current count that match the properties of the selected objects, and then adds them to the selection set. This is available only during an active counting operation."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-215C571E-0806-45B1-934C-5346EB188CE2.htm"
 :source-bricscad NIL)

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

(:name "SHARE"
 :category :FILE
 :aliases NIL
 :intl-name "_SHARE"
 :synopsis "Share a link to a copy of the current drawing to view or edit in AutoCAD on the web or AutoCAD on mobile."
 :options ("Can edit" "View only" "Edit and save a copy")
 :arguments "Takes no arguments; opens the sharing dialog where a link (edit or view-only) is generated."
 :description "Shares a link to a copy of the current drawing to view or edit in AutoCAD on the web or on mobile. For files stored in Autodesk Docs, edit or view-only permissions can be granted; for other files, an editable copy or a view-only link is shared, and links expire seven days after creation."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-6CDBBD68-B8CA-4548-ADF5-84CF8BF9F282.htm"
 :source-bricscad NIL)

(:name "SHAREDVIEWS"
 :category :FILE
 :aliases NIL
 :intl-name "_SHAREDVIEWS"
 :synopsis "Opens the Shared Views palette."
 :options NIL
 :arguments "Takes no arguments; opens the Shared Views palette."
 :description "Opens the Shared Views palette, which displays a list of shared views, posted messages, and replies about shared views temporarily uploaded to the cloud. These messages can reference specific locations and areas within a drawing to facilitate online collaboration."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C9055F88-D079-441F-938B-37A7E0E390D9.htm"
 :source-bricscad NIL)

(:name "SHAREDVIEWSCLOSE"
 :category :FILE
 :aliases NIL
 :intl-name "_SHAREDVIEWSCLOSE"
 :synopsis "Closes the Shared Views palette."
 :options NIL
 :arguments "Takes no arguments; closes the Shared Views palette."
 :description "Closes the Shared Views palette. The palette supports online collaboration, allowing users to work together on shared content."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A0BD1C2B-726A-4D43-A3AD-11339EBB1D99.htm"
 :source-bricscad NIL)

(:name "SHAREVIEW"
 :category :FILE
 :aliases NIL
 :intl-name "_SHAREVIEW"
 :synopsis "Publishes a representation of the current space or the entire drawing for online viewing and sharing."
 :options NIL
 :arguments "Takes no arguments; opens the Share View dialog box (use -SHAREVIEW at the Command prompt for command-line options)."
 :description "Publishes a representation of the current space or the entire drawing for online viewing and sharing. Named views need not be created beforehand, as the data is extracted automatically from the drawing file; the Share View dialog box opens on invocation."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-60AA1F13-40AC-4D5C-A48F-E9D7969DB65B.htm"
 :source-bricscad NIL)

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

(:name "SHOWPALETTES"
 :category :VIEW
 :aliases NIL
 :intl-name "_SHOWPALETTES"
 :synopsis "Restores the display of hidden palettes, the ribbon, and the drawing tabs."
 :options NIL
 :arguments "Takes no arguments; restores the palettes, ribbon, and drawing tabs previously hidden by HIDEPALETTES."
 :description "Restores the display of hidden palettes, the ribbon, and the drawing tabs that were hidden using the HIDEPALETTES command. The keyboard shortcut Ctrl+Shift+H toggles between hiding and showing these elements."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EEE9EDD3-3A4D-494B-8CA2-F2A86F36D541.htm"
 :source-bricscad NIL)

(:name "SHOWRENDERGALLERY"
 :category :RENDER
 :aliases NIL
 :intl-name "_SHOWRENDERGALLERY"
 :synopsis "Displays the images that were rendered and stored in your Autodesk account."
 :options NIL
 :arguments "No command-line arguments; provides access to rendered images stored in your Autodesk account."
 :description "Provides access to the images that were rendered and stored in your Autodesk account."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-78DB8222-DCE2-457C-B5DA-0ECCBC15EE91.htm"
 :source-bricscad NIL)

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

(:name "SOLDRAW"
 :category :|3D|
 :aliases NIL
 :intl-name "_SOLDRAW"
 :synopsis "Generates profiles and sections in layout viewports created with SOLVIEW."
 :options NIL
 :arguments "Select viewports to draw (layout viewports previously created with SOLVIEW), then confirm the viewport selection."
 :description "Generates profiles and sections in layout viewports created with SOLVIEW. Visible and hidden lines representing the silhouette and edges of solids are created and projected perpendicular to the viewing direction; for sectional views, cross-hatching is generated using the current hatch system variables. Existing profiles and sections in selected viewports are deleted and regenerated."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C2D29999-EB0D-44E3-9107-2365666F120F.htm"
 :source-bricscad NIL)

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

(:name "SOLVIEW"
 :category :|3D|
 :aliases NIL
 :intl-name "_SOLVIEW"
 :synopsis "Creates orthographic views, layers, and layout viewports automatically for 3D solids."
 :options ("UCS" "Ortho" "Auxiliary" "Section")
 :arguments "Choose the view creation method (UCS, Ortho, Auxiliary, or Section); for UCS: named/World/Current coordinate system, view scale, and new viewport center; for Ortho: viewport side; for Auxiliary: two points defining the inclined plane plus new viewport center; for Section: two points defining the sectioning plane, viewing side, view scale, and new viewport center."
 :description "Creates orthographic views, layers, and layout viewports automatically for 3D solids. SOLVIEW must run on a layout tab and creates viewport objects on the VPORTS layer, along with associated layers for visible lines, hidden lines, hatching, and dimensions that SOLDRAW uses for final drawing generation."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-08FE95F0-B91A-424A-B19F-821D5100CCB9.htm"
 :source-bricscad NIL)

(:name "SPACETRANS"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_SPACETRANS"
 :synopsis "Calculates equivalent model space and paper space distances in a layout."
 :options NIL
 :arguments "When in model space within a layout viewport: prompts for a paper space distance. When in paper space on a layout: prompts to select a viewport (if multiple exist), then prompts for a model space distance."
 :description "Calculates equivalent model space and paper space distances in a layout. SPACETRANS converts lengths from either model space or paper space to its equivalent in the other space, typically for text heights, and is intended to work transparently at prompts for length values."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-EF67ED5B-E250-4BA4-834D-61A641DAD8DB.htm"
 :source-bricscad NIL)

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

(:name "SUNPROPERTIESCLOSE"
 :category :RENDER
 :aliases NIL
 :intl-name "_SUNPROPERTIESCLOSE"
 :synopsis "Closes the Sun Properties palette."
 :options NIL
 :arguments "No command-line arguments; closes the Sun Properties palette."
 :description "Closes the Sun Properties palette."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D61D3C53-36E7-4EF2-A042-A2DAFEBC05B6.htm"
 :source-bricscad NIL)

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

(:name "SURFBLEND"
 :category :|3D|
 :aliases NIL
 :intl-name "_SURFBLEND"
 :synopsis "Creates a continuous blend surface between two existing surfaces."
 :options ("Chain" "Continuity" "Bulge magnitude")
 :arguments "Select the first surface edge, select the second surface edge, specify the continuity level (default G1), and set the bulge magnitude value (default 0.5)."
 :description "Creates a continuous blend surface between two existing surfaces. When blending two surfaces you can specify surface continuity and bulge magnitude. Setting SURFACEASSOCIATIVITY to 1 creates a relationship between the blend surface and the originating curves."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-BD4E2F9B-5B2D-462E-AE9B-E0A3B0324E6A.htm"
 :source-bricscad NIL)

(:name "SURFEXTEND"
 :category :|3D|
 :aliases NIL
 :intl-name "_SURFEXTEND"
 :synopsis "Lengthens a surface by a specified distance."
 :options ("Extend" "Stretch" "Merge" "Append")
 :arguments "Specify the extension distance (via expression formula or numeric value), select the extrusion mode (Extend or Stretch), and select the creation type (Merge or Append)."
 :description "Lengthens a surface by a specified distance. The extension surface can be merged as part of the original surface, or appended as a second surface adjacent to it. The command offers two extrusion modes: one that mimics the surface shape and one that does not."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A999554C-9AFE-4589-A704-1BB785AC3AD6.htm"
 :source-bricscad NIL)

(:name "SURFEXTRACTCURVE"
 :category :|3D|
 :aliases NIL
 :intl-name "_SURFEXTRACTCURVE"
 :synopsis "Creates curves on surfaces and 3D solids."
 :options ("Chain" "Direction" "Spline points")
 :arguments "Select a surface, solid, or face; then select a point on the surface or choose from the Chain, Direction, or Spline points options."
 :description "Creates curves (lines, polylines, arcs, or splines) in the U and V directions on a surface, a 3D solid, or a face of a 3D solid, based on the surface or solid shape."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D733EC46-4A91-4E9A-9D59-5EC5A7D7DD5A.htm"
 :source-bricscad NIL)

(:name "SURFFILLET"
 :category :|3D|
 :aliases NIL
 :intl-name "_SURFFILLET"
 :synopsis "Creates a filleted surface between two other surfaces."
 :options ("Radius" "Trim surface" "Expression")
 :arguments "Select the first and second surfaces or regions, specify the fillet radius (using the Fillet grip or entering a value), choose whether to trim the original surfaces, and optionally enter a formula or equation for the radius."
 :description "Creates a filleted surface between two other surfaces. The fillet surface has a constant radius profile and is tangent to the original surfaces. The original surfaces are automatically trimmed to connect the edges of the fillet surface."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-AFDD7F94-A404-4CDC-8E51-A40BE9D712F8.htm"
 :source-bricscad NIL)

(:name "SURFOFFSET"
 :category :|3D|
 :aliases NIL
 :intl-name "_SURFOFFSET"
 :synopsis "Creates a parallel surface a specified distance from the original surface."
 :options ("Flip direction" "Both sides" "Solid" "Connect" "Expression")
 :arguments "Specify an offset distance, then optionally flip the direction, offset both sides, create a solid, connect surfaces, or enter an expression-based distance value."
 :description "Creates a parallel surface a specified distance from the original surface. You can reverse the offset direction, create offsets on both sides, convert to a solid, or connect multiple offset surfaces."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F242D0E4-0D58-4469-AE69-99BC842D0B25.htm"
 :source-bricscad NIL)

(:name "SURFPATCH"
 :category :|3D|
 :aliases NIL
 :intl-name "_SURFPATCH"
 :synopsis "Creates a new surface by fitting a cap over a surface edge that forms a closed loop."
 :options ("Chain" "Curves" "Continuity" "Bulge magnitude" "Guides")
 :arguments "Select the surface edges or curves forming a closed loop; accept the patch surface; specify the continuity value (default G0); enter the bulge magnitude value between 0 and 1 (default 0.5); and optionally add guide curves or points to shape the surface."
 :description "Creates a new surface by fitting a cap over a surface edge that forms a closed loop. The command generates a patch surface spanning selected edges and allows optional guide curves for additional constraint. Surface continuity and bulge magnitude can be specified, with associativity maintained if the SURFACEASSOCIATIVITY system variable is enabled."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F594A1AE-71B4-44D4-A867-AC95C43AF1E6.htm"
 :source-bricscad NIL)

(:name "SURFSCULPT"
 :category :|3D|
 :aliases NIL
 :intl-name "_SURFSCULPT"
 :synopsis "Trims and combines a set of surfaces or meshes that completely enclose a volume to create a 3D solid."
 :options NIL
 :arguments "Select the surfaces or meshes that completely enclose a watertight volume; the enclosed region is converted into a 3D solid."
 :description "Trims and combines a set of surfaces or meshes that completely enclose a volume to create a 3D solid. The surfaces or meshes must form a closed volume without gaps and with continuous (G0) intersections. When used with meshes, they are smoothed according to the SMOOTHMESHCONVERT system variable, and the command also works with 3D solids that share a common surface."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0436666E-08CB-40CA-81B3-F79BD3447006.htm"
 :source-bricscad NIL)

(:name "SURFTRIM"
 :category :|3D|
 :aliases NIL
 :intl-name "_SURFTRIM"
 :synopsis "Trims portions of a surface where it meets another surface or type of geometry."
 :options ("Extend" "Projection direction")
 :arguments "Select one or more surfaces or regions to trim, select the cutting curves, surfaces, or regions, then select the area(s) on the surface to remove."
 :description "Trims portions of a surface where it meets another surface or type of geometry. Parts of surfaces or regions are removed at their intersections with curves, regions, or other surfaces. When surface associativity is enabled, trimmed surfaces update automatically if the trimming edges are modified."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-5FF7E92D-8F12-4404-8C1F-AC44377F608A.htm"
 :source-bricscad NIL)

(:name "SURFUNTRIM"
 :category :|3D|
 :aliases NIL
 :intl-name "_SURFUNTRIM"
 :synopsis "Replaces surface areas removed by the SURFTRIM command."
 :options ("SURfaces")
 :arguments "Select the edges of trimmed areas to replace, or enter SUR to untrim surfaces and then select a surface to replace all its trimmed areas."
 :description "Replaces surface areas removed by the SURFTRIM command. If the trimmed edge depends on another surface edge that has also been trimmed, full restoration may not be possible. The command cannot restore areas removed by the SURFAUTOTRIM system variable or by PROJECTGEOMETRY."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-9EB95641-0E3E-45F3-89E6-0ED6CDCC9B05.htm"
 :source-bricscad NIL)

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

(:name "SYSVARMONITOR"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_SYSVARMONITOR"
 :synopsis "Monitors a list of system variables and sends notifications when there are changes to any one in the list."
 :options NIL
 :arguments "No command-line arguments; displays the System Variable Monitor dialog box."
 :description "Monitors a list of system variables and sends notifications when there are changes to any one in the list. The command displays the System Variable Monitor dialog box, which tracks system variables and reports when they are modified from their preferred settings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-82BACF96-AC90-446A-8E60-3CC3072F8060.htm"
 :source-bricscad NIL)

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

(:name "TASKBAR"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_TASKBAR"
 :synopsis "Controls the Peek/Preview behavior of the application's button in the Windows taskbar when multiple drawings are open."
 :options ("0" "1")
 :arguments "Enter a new value for TASKBAR: 0 for Peek/Preview of the current drawing only, or 1 for all open drawings."
 :description "Controls the Peek/Preview behavior of the application's button in the Windows taskbar when multiple drawings are open. When Windows combines taskbar buttons from multiple instances, the preview display depends on each instance's taskbar setting, letting you specify whether Peek/Preview applies only to the current drawing (0) or to all open drawings within a program instance (1)."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C72AE884-5FDE-4F67-8549-0A6183AC04BB.htm"
 :source-bricscad NIL)

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

(:name "TEXTALIGN"
 :category :TEXT
 :aliases NIL
 :intl-name "_TEXTALIGN"
 :synopsis "Aligns multiple text objects vertically, horizontally, or obliquely."
 :options ("Distribute" "Set spacing" "Current vertical" "Current horizontal")
 :arguments "Select two or more text objects to align, choose the alignment orientation, select the base text object to align to, then pick a second point to set the target position (or access Options)."
 :description "Aligns multiple text objects vertically, horizontally, or obliquely. The command aligns multiple text objects to a base object with a preview, providing various alignment orientations plus options for distributing and spacing objects evenly."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CC1BE498-4908-434E-8FDA-0DE87E05EA15.htm"
 :source-bricscad NIL)

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

(:name "THICKEN"
 :category :|3D|
 :aliases NIL
 :intl-name "_THICKEN"
 :synopsis "Converts a surface into a 3D solid with a specified thickness."
 :options NIL
 :arguments "Select one or more surfaces to thicken, then specify the thickness value."
 :description "Converts a surface into a 3D solid with a specified thickness. A 3D curved solid is created by first building a surface, then converting it to a solid through thickening; mesh faces can be converted to solids or surfaces before completing the operation. The DELOBJ system variable determines whether the original surface persists after thickening."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-50CAFB97-22BA-4224-9B48-60D6E7ABFCF1.htm"
 :source-bricscad NIL)

(:name "TIFOUT"
 :category :FILE
 :aliases NIL
 :intl-name "_TIFOUT"
 :synopsis "Saves selected objects to a file in TIFF file format."
 :options NIL
 :arguments "In the Create Raster File dialog box, enter a file name; then select the objects to export, or press Enter to include all objects in the viewports."
 :description "Saves selected objects to a file in TIFF file format. The command exports drawing objects as a TIFF raster image file; you can choose specific objects or include all viewport contents, and the resulting file reflects the current screen display."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-DB78721A-4674-4A24-A2DC-722997E32A1E.htm"
 :source-bricscad NIL)

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

(:name "TRACEBACK"
 :category :VIEW
 :aliases NIL
 :intl-name "_TRACEBACK"
 :synopsis "Changes the active trace to view mode so you can edit the parent drawing while the trace is still visible."
 :options NIL
 :arguments "No command-line arguments; switches the active trace to view mode."
 :description "Changes the active trace to view mode so you can edit the parent drawing while the trace is still visible. The command displays the host drawing with full saturation while dimming the trace geometry. Traces are created across AutoCAD applications to provide feedback and markups without altering drawing content."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8B2037E1-D1E3-496F-BF67-ACBC4155AE89.htm"
 :source-bricscad NIL)

(:name "TRACEEDIT"
 :category :VIEW
 :aliases NIL
 :intl-name "_TRACEEDIT"
 :synopsis "Changes the active trace to edit mode so you can contribute to the trace."
 :options NIL
 :arguments "No command-line arguments; switches the active trace to edit mode."
 :description "Changes the active trace to edit mode so you can contribute to the trace. It displays the active trace with full saturation while dimming the host drawing geometry, allowing you to add feedback, comments, markups, and design exploration across AutoCAD web, mobile, and desktop without modifying the underlying drawing content."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B830702F-25E9-4548-BE97-BFF2152934B9.htm"
 :source-bricscad NIL)

(:name "TRACEPALETTECLOSE"
 :category :VIEW
 :aliases NIL
 :intl-name "_TRACEPALETTECLOSE"
 :synopsis "Closes the Trace palette where you view and manage traces in the current drawing."
 :options NIL
 :arguments "No command-line arguments; closes the Trace palette."
 :description "Closes the Trace palette where you view and manage traces in the current drawing. The Trace palette is a feature that allows users to provide feedback, comments, markups, and design exploration without modifying the drawing's content."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-189DED05-AFC1-4F83-A616-937D3D50C293.htm"
 :source-bricscad NIL)

(:name "TRACEPALETTEOPEN"
 :category :VIEW
 :aliases NIL
 :intl-name "_TRACEPALETTEOPEN"
 :synopsis "Opens the Trace palette where you can view and manage traces in the current drawing."
 :options NIL
 :arguments "No command-line arguments; opens the Trace palette."
 :description "Opens the Trace palette where you can view and manage traces in the current drawing. Traces are feedback mechanisms created in AutoCAD web and mobile apps that let users add comments, markups, and design notes without modifying the drawing content."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-13413FA0-13B1-4323-BD6A-CEEE3A688C09.htm"
 :source-bricscad NIL)

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

(:name "TRAYSETTINGS"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_TRAYSETTINGS"
 :synopsis "Controls the display of icons and notifications in the status bar tray."
 :options NIL
 :arguments "No command-line arguments; opens the Tray Settings dialog box."
 :description "Controls the display of icons and notifications in the status bar tray. The command opens the Tray Settings dialog box, letting you manage how icons and service notifications appear in the application's status bar tray area."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-26392CF2-0403-4E6F-BD27-9C2EB4547756.htm"
 :source-bricscad NIL)

(:name "TREESTAT"
 :category :INQUIRY
 :aliases NIL
 :intl-name "_TREESTAT"
 :synopsis "Displays information about the drawing's current spatial index."
 :options NIL
 :arguments "No command-line arguments; reports spatial index information at the command line."
 :description "Displays information about the drawing's current spatial index. The spatial index is a tree-structured system with branching nodes to which objects are attached; the command reports on both the paper space quad-tree (2D) and model space oct-tree (2D or 3D) branches, including node count, object count, maximum depth, and average objects per node."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-A9337C6A-9153-4D20-8696-7CE9096AAA86.htm"
 :source-bricscad NIL)

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

(:name "UCSMAN"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_UCSMAN"
 :synopsis "Manages UCS definitions."
 :options NIL
 :arguments "No command-line arguments; opens the UCS dialog box."
 :description "Manages UCS definitions. The command opens the UCS dialog box, letting you manage named User Coordinate System definitions and preset orientations in both 2D and 3D environments."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-96651DBC-3F2F-4B65-91DF-02AE7F2C4161.htm"
 :source-bricscad NIL)

(:name "ULAYERS"
 :category :LAYER
 :aliases NIL
 :intl-name "_ULAYERS"
 :synopsis "Controls the display of layers in a DWF, DWFx, PDF, or DGN underlay."
 :options NIL
 :arguments "Select a DWF, DWFx, PDF, or DGN underlay; the Underlay Layers dialog box then opens to turn its layers on and off."
 :description "Controls the display of layers in a DWF, DWFx, PDF, or DGN underlay. After you select an underlay, the Underlay Layers dialog box opens, enabling you to turn layers on and off within the imported underlay."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-498506C3-7C42-4CFF-BB3E-021B1D050CF4.htm"
 :source-bricscad NIL)

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

(:name "UPDATETHUMBSNOW"
 :category :SYSTEM
 :aliases NIL
 :intl-name "_UPDATETHUMBSNOW"
 :synopsis "Manually updates thumbnail previews for named views, drawings, and layouts."
 :options NIL
 :arguments "No command-line arguments; immediately refreshes thumbnail previews."
 :description "Manually updates thumbnail previews for named views, drawings, and layouts. The command refreshes visual previews used in the Sheet Set Manager and Quick View displays, performing an immediate manual refresh; the UPDATETHUMBNAIL system variable governs automatic updates."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-99DAEB10-7364-4B0B-809B-1E75DED6981E.htm"
 :source-bricscad NIL)

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

(:name "VBAPREF"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_VBAPREF"
 :synopsis "Provides access to some of the VBA environment settings."
 :options NIL
 :arguments "No command-line arguments; opens the VBA Options dialog box."
 :description "Provides access to some of the VBA environment settings. The command opens the VBA Options dialog box, where settings such as macro virus protection, break on errors, and auto embedding can be configured."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4C071022-BDBC-43EB-824B-9B950AC83DE2.htm"
 :source-bricscad NIL)

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

(:name "VIEWBACK"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWBACK"
 :synopsis "Restores sequential views backward after changing the view."
 :options NIL
 :arguments "No command-line arguments; restores the next view backward in the view sequence."
 :description "Restores sequential views backward after changing the view. The command functions similarly to Zoom Previous, with the key distinction that it does not affect the undo list, allowing navigation through previously viewed perspectives without altering the command history."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-67E5CB2D-7CED-4B1D-86E9-988A7E399798.htm"
 :source-bricscad NIL)

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

(:name "VIEWCOMPONENT"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWCOMPONENT"
 :synopsis "Selects components from a drawing view for editing."
 :options ("None" "Section" "Slice")
 :arguments "Select a component from a drawing view, then specify its section participation behavior (None, Section, or Slice)."
 :description "Selects components from a drawing view for editing. The command lets you modify which component properties affect section view behavior; highlighted components appear when hovering over the model documentation drawing view."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-81DE46E8-99C9-43E6-A547-74DF70DFFF20.htm"
 :source-bricscad NIL)

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

(:name "VIEWGO"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWGO"
 :synopsis "Restores the view you specify to the current viewport."
 :options NIL
 :arguments "Specify the name of the named view to restore to the current viewport."
 :description "Restores the view you specify to the current viewport. If the view was saved with associated settings such as layer state, UCS, live section, visual style, or background, those are also restored along with the view."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-8747BD5F-B7C0-49F7-A2DF-E796BD51A76B.htm"
 :source-bricscad NIL)

(:name "VIEWPLAY"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWPLAY"
 :synopsis "Plays the animation associated to a named view."
 :options NIL
 :arguments "Enter the name of the named view whose associated animation is to be played."
 :description "Plays the animation associated to the named view entered. The command terminates if the specified view name does not exist in the drawing or has no assigned animation properties."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-63CB1832-0274-44AB-A8E5-EF6076BEDA52.htm"
 :source-bricscad NIL)

(:name "VIEWPLOTDETAILS"
 :category :PLOT
 :aliases NIL
 :intl-name "_VIEWPLOTDETAILS"
 :synopsis "Displays information about completed plot and publish jobs."
 :options NIL
 :arguments "No command-line arguments; opens the Plot and Publish Details dialog box."
 :description "Displays information about completed plot and publish jobs. The command opens the Plot and Publish Details dialog box, where you can review detailed information about all completed plotting and publishing operations, filter results to show only errors, and copy the displayed information to the clipboard."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-23072042-6A25-448A-8567-0354E5636EF5.htm"
 :source-bricscad NIL)

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

(:name "VIEWSETPROJ"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWSETPROJ"
 :synopsis "Specifies the active project file for drawings containing model documentation drawing views from Inventor models."
 :options NIL
 :arguments "Select a project file in the file selection dialog box."
 :description "Specifies the active project file for drawings containing model documentation drawing views from Inventor models. Project files specify the locations of files referenced by Inventor models; if any open drawings contain Inventor model views when the command is invoked, AutoCAD must be restarted for the setting to apply."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B99EBA1D-12E4-4907-8163-D4D9931983DC.htm"
 :source-bricscad NIL)

(:name "VIEWSKETCHCLOSE"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWSKETCHCLOSE"
 :synopsis "Exits the symbol sketch mode."
 :options NIL
 :arguments "No command-line arguments; exits symbol sketch mode, prompting to save or discard any construction geometry that was added."
 :description "Exits the symbol sketch mode. The command terminates the symbol sketch mode activated by VIEWSYMBOLSKETCH; on exit you are prompted to save or discard any construction geometry added to the drawing view."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-58033C26-764B-40A5-B159-12E266F06F73.htm"
 :source-bricscad NIL)

(:name "VIEWSTD"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWSTD"
 :synopsis "Defines the default settings for model documentation drawing views."
 :options NIL
 :arguments "No command-line arguments; opens the Drafting Standards dialog box."
 :description "Defines the default settings for model documentation drawing views. The command opens the Drafting Standards dialog box, letting you configure default settings that apply only to newly created base views without modifying drawing views already present in a layout."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-2650ABC3-F838-4911-A19C-C4EC1396DD3D.htm"
 :source-bricscad NIL)

(:name "VIEWSYMBOLSKETCH"
 :category :VIEW
 :aliases NIL
 :intl-name "_VIEWSYMBOLSKETCH"
 :synopsis "Constrains section lines and detail boundaries to drawing view geometry."
 :options NIL
 :arguments "Select a section or detail symbol to constrain to the drawing view geometry."
 :description "Opens an editing environment to constrain section lines or detail boundaries to drawing view geometry. It lets you add geometrical and dimensional constraints so that section lines and detail boundaries maintain their positions relative to features when drawing views update, providing access to the Parametric ribbon tab and supporting construction geometry."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-35771218-F9F8-432A-85D6-78E644D764F5.htm"
 :source-bricscad NIL)

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

(:name "VISUALSTYLESCLOSE"
 :category :VIEW
 :aliases NIL
 :intl-name "_VISUALSTYLESCLOSE"
 :synopsis "Closes the Visual Styles Manager."
 :options NIL
 :arguments "No command-line arguments; closes the Visual Styles Manager."
 :description "Closes the Visual Styles Manager. Visual styles control how edges, lighting, and shading appear in viewports; this command dismisses the manager when it is no longer needed."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-4ED2D58F-043A-4F82-A483-79FA3E0E32B6.htm"
 :source-bricscad NIL)

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

(:name "WALKFLYSETTINGS"
 :category :VIEW
 :aliases NIL
 :intl-name "_WALKFLYSETTINGS"
 :synopsis "Controls the walk and fly navigation settings."
 :options NIL
 :arguments "No command-line arguments; opens the Walk and Fly Settings dialog box."
 :description "Controls the walk and fly navigation settings. The command opens the Walk and Fly Settings dialog box, letting you configure navigation parameters used to simulate walking and flying through 3D drawings."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D3AC721E-95BE-4DB7-BF52-BD857B23D9E8.htm"
 :source-bricscad NIL)

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

(:name "WEBLOAD"
 :category :CUSTOMIZATION
 :aliases NIL
 :intl-name "_WEBLOAD"
 :synopsis "Loads a JavaScript file from a URL, and then executes the JavaScript code contained in the file."
 :options NIL
 :arguments "Enter the name of a URL pointing to a JavaScript file (for example, https://website/filename.js) to load and execute."
 :description "Loads a JavaScript file from a URL, and then executes the JavaScript code contained in the file. The loaded file must contain both a function definition and an invocation of that function; any JavaScript or AutoCAD JavaScript API function can be called, with the exception of the prompt() function."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CFDF041A-ABED-47D7-AC86-50F0419E5474.htm"
 :source-bricscad NIL)

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

(:name "XBIND"
 :category :BLOCK
 :aliases NIL
 :intl-name "_XBIND"
 :synopsis "Binds one or more definitions of named objects in an xref to the current drawing."
 :options NIL
 :arguments "Select the xref-dependent named object definitions (blocks, dimension styles, layers, linetypes, or text styles) to bind to the current drawing."
 :description "Binds one or more definitions of named objects in an xref to the current drawing. XBIND merges xref-dependent named objects such as blocks, dimension styles, layers, linetypes, and text styles into your current drawing; unlike the Bind option of XREF, which binds entire xref files, XBIND allows selective binding of individual dependent definitions. Entering -xbind at the Command prompt displays command-line options."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D4B26149-C3A2-4547-A532-FF7A0D1CB2C9.htm"
 :source-bricscad NIL)

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

(:name "XCOMPARECLOSE"
 :category :VIEW
 :aliases NIL
 :intl-name "_XCOMPARECLOSE"
 :synopsis "Closes the Xref Compare toolbar and ends the comparison."
 :options NIL
 :arguments "No command-line arguments; closes the Xref Compare toolbar and ends the comparison."
 :description "Closes the Xref Compare toolbar and ends the comparison. The command terminates an active xref comparison session and is available only while you are actively comparing xrefs."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0FE2EA37-E394-421B-92A3-974D066DEF76.htm"
 :source-bricscad NIL)

(:name "XCOMPARERCNEXT"
 :category :VIEW
 :aliases NIL
 :intl-name "_XCOMPARERCNEXT"
 :synopsis "Zooms to the next change set of the xref comparison result."
 :options NIL
 :arguments "No command-line arguments; zooms to the next change set of the xref comparison result."
 :description "Zooms to the next change set of the xref comparison result. The command navigates through xref comparison results by advancing to subsequent change sets, and functions only within an active xref comparison workflow for systematically reviewing differences between an attached xref and its referenced drawing file."
 :availability :AUTOCAD-ONLY
 :autocad-versions "all"
 :bricscad-versions NIL
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-F5E0A078-1B44-440E-BCB6-3F6A56F67A3C.htm"
 :source-bricscad NIL)

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
