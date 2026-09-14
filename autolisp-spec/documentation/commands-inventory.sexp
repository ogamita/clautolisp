;;;; -*- Mode: Lisp; coding: utf-8 -*-
;;;; Commands inventory: enumerated AutoCAD + BricsCAD drawing,
;;;; modify, view, file, customization, and block commands.
;;;; Harvested from help.autodesk.com (2026 ENU) and
;;;; help.bricsys.com (V25) on 2026-09-14.
;;;;
;;;; This is a generated artifact feeding the autolisp-spec
;;;; "Commands" chapter. One plist per command, sorted
;;;; alphabetically by :NAME. Facts come only from the vendor
;;;; pages cited in :SOURCE-AUTOCAD / :SOURCE-BRICSCAD; a fact
;;;; absent from a page is recorded as NIL.
;;;;
;;;; Each plist has EXACTLY these keys, in this order:
;;;;   :name :category :aliases :intl-name :synopsis :options
;;;;   :arguments :description :availability :autocad-versions
;;;;   :bricscad-versions :source-autocad :source-bricscad

(

(:name "ARC"
 :category :draw
 :aliases ("A")
 :intl-name "_ARC"
 :synopsis "Creates an arc."
 :options ("Center" "End" "Angle" "Direction" "Radius" "Length")
 :arguments "Supplies a start point (or the keyword \"C\" for Center), then a second point on the arc or a keyword, then an end point; construction can be refined with keywords for included Angle, chord Length, Direction of tangent, and Radius. Arcs are drawn counterclockwise by default."
 :description "Creates an arc from various combinations of start point, second point, center, end point, included angle, tangent direction, radius, and chord length. Arcs are drawn counterclockwise by default; holding Ctrl while dragging reverses the direction."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-30ECFD30-A1D6-4D60-9DD1-B487603F6772.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_arc/V25/EN_US")

(:name "BLOCK"
 :category :block
 :aliases ("B")
 :intl-name "_BLOCK"
 :synopsis "Creates a block definition from selected objects (opens the Block Definition dialog box)."
 :options ()
 :arguments "In a (command ...) call use the command-line variant -BLOCK, which supplies: block name -> insertion base point -> object selection -> Enter to finish. The GUI BLOCK command opens the Create Block Definition / Block Definition dialog box (name, base point, entity selection, behavior options) and takes no command-line arguments."
 :description "Creates a block definition in the current drawing from selected objects. The user gives the block a name, an insertion base point, and selects the entities to group; behavior options include annotative scaling, uniform scaling, and allow-exploding. The GUI form opens a dialog box; entering -BLOCK at the prompt drives the same operation from the command line."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B03434BE-0F68-4E31-BA8D-640EEC1D7FC9.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_block/V25/EN_US")

(:name "CIRCLE"
 :category :draw
 :aliases ("C")
 :intl-name "_CIRCLE"
 :synopsis "Creates a circle."
 :options ("3P" "2P" "Ttr" "Radius" "Diameter")
 :arguments "Supplies a center point followed by a radius, or the keyword \"D\" (Diameter) then a diameter value; alternatively the first response is a keyword: \"2P\" then two endpoints of a diameter, \"3P\" then three points on the circumference, or \"Ttr\" (tan-tan-radius) then two tangent objects and a radius. BricsCAD additionally offers Tan-Tan-Tan and arc-to-circle conversion."
 :description "Creates a circle using several methods: center point with radius or diameter, two points defining a diameter, three points on the circumference, or tangency-based construction (tangent-tangent-radius, and in BricsCAD tangent-tangent-tangent)."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C60B6D5D-AAEB-420F-917F-6E6B47E92F48.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_circle/V25/EN_US")

(:name "COPY"
 :category :modify
 :aliases ("CO" "CP")
 :intl-name "_COPY"
 :synopsis "Copies objects a specified distance in a specified direction."
 :options ("Displacement" "Mode" "Array" "Multiple" "Undo" "Repeat" "Exit")
 :arguments "Selection set of entities, then a base point followed by second point(s) of displacement (or a Displacement vector). Keyword options may be supplied: \"Displacement\", \"mOde\" (Single/Multiple), \"Array\" (number of items, then second point or Fit), \"Undo\", \"Exit\". An empty string ends the command."
 :description "Duplicates selected objects, placing copies by a base point and displacement vector, a directional/linear array, or repeated multiple copies. The COPYMODE system variable governs whether multiple copies are made automatically."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1CF9287F-06E8-4D03-8377-2E130862FE02.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_copy/V25/EN_US")

(:name "DONUT"
 :category :draw
 :aliases ("DO" "DOUGHNUT")
 :intl-name "_DONUT"
 :synopsis "Creates a closed polyline in the shape of a donut (a filled circle or a wide ring)."
 :options ("2 Point" "3 Point" "Tangent Tangent Radius" "Width" "Diameter")
 :arguments "Supplies the inside diameter, the outside diameter, then one or more center points, terminated by an empty string; e.g. (command \"_DONUT\" inside-dia outside-dia center-pt \"\"). An inside diameter of 0 makes a filled circle."
 :description "A donut is made of two arc polylines joined end-to-end into a ring whose width is set by the inside and outside diameters; if the inside diameter is 0 the donut is a filled circle. The command keeps placing uniform donuts at each specified center point until you press Enter. BricsCAD adds 2-Point, 3-Point, and Tangent-Tangent-Radius construction methods."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-46C0F9F2-6112-415C-AB2C-29EEE5984A6F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_donut/V25/EN_US")

(:name "ERASE"
 :category :modify
 :aliases ("DELETE" "E")
 :intl-name "_ERASE"
 :synopsis "Removes selected objects from the drawing."
 :options ("Last" "Previous" "All")
 :arguments "Supplies a selection set or entity name(s) to delete, or a selection option, terminated by an empty string; e.g. (command \"_ERASE\" ss \"\") or (command \"_ERASE\" ename \"\"). Options such as Last (L), Previous (P), and All are also accepted."
 :description "The ERASE command removes selected objects from the drawing without placing them on the Clipboard, and can also erase subobjects (faces, edges, vertices) of 3D solids. Instead of picking objects you may enter an option such as L (last), P (previous), or ALL. BricsCAD additionally uses it to delete openings and coplanar edges/faces of 3D solids."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-040C580C-63A2-4C98-9964-4573EF8C9514.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_erase/V25/EN_US")

(:name "INSERT"
 :category :block
 :aliases ("I" "DDINSERT")
 :intl-name "_INSERT"
 :synopsis "Inserts a block instance from a block definition into the current drawing."
 :options ("Name" "Scale" "Rotate" "Base point" "Multiple" "Flip" "Array" "SMART insert" "Edit inserted entity")
 :arguments "Supplies the block name (or external drawing file), then the insertion point, then X/Y/Z scale factors, then the rotation angle; e.g. (command \"_INSERT\" name pt xscale yscale rotation). BricsCAD adds keyword options (Scale, Rotate, Base point, Multiple, Flip, Array, SMART insert, etc.). In AutoCAD the bare INSERT command displays the Blocks palette; -INSERT gives the classic command-line prompt sequence."
 :description "Inserts an instance of a block definition (from the current drawing or an external file) into the drawing. BricsCAD opens the Insert Block dialog box and supports insertion modes and advanced settings. In AutoCAD 2026, INSERT displays the Blocks palette (gallery of current/recent/library blocks); -INSERT provides the command-line prompts and CLASSICINSERT opens the classic dialog. Inserting a drawing file also imports its block definitions."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-B840AB4A-91E2-4FEC-900A-33E40D1E1925.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_insert/V25/EN_US")

(:name "LINE"
 :category :draw
 :aliases ("L" "3DLINE")
 :intl-name "_LINE"
 :synopsis "Creates a series of contiguous straight line segments."
 :options ("Close" "Undo" "Follow" "Length" "Angle")
 :arguments "Supplies a start point, then successive end points as coordinate points; the keyword \"C\" (Close) joins the last segment back to the first, \"U\" (Undo) removes the most recent segment, and an empty string / ENTER (\"\") ends the command. In BricsCAD the first prompt also accepts Follow, plus Angle and Length keywords to place a segment by direction and distance."
 :description "Creates a series of individual, contiguous line segments; each segment is a separate line object that can be edited independently. Points may be entered by coordinates, object snaps, or grid snap, and drawing can continue from the endpoint of a previous line, arc, or polyline."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E8C1190C-A26C-484C-ADDD-DDF81666F69F.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_line/V25/EN_US")

(:name "MENULOAD"
 :category :customization
 :aliases ()
 :intl-name "_MENULOAD"
 :synopsis "Opens the Customization Groups dialog box."
 :options ()
 :arguments "Supplies no arguments: (command \"_MENULOAD\") opens the Customization Groups dialog box, where customization (menu) groups are loaded and unloaded interactively. No command-line prompt sequence is documented."
 :description "In BricsCAD, MENULOAD opens the Customization Groups dialog box for loading and unloading customization groups (available in Lite, Pro, Mechanical, and BIM). Not documented as a command in AutoCAD 2026 (AutoCAD uses MENU/CUILOAD/CUIUNLOAD instead; MENU is retained only for script compatibility)."
 :availability :bricscad-only
 :autocad-versions NIL
 :bricscad-versions "all"
 :source-autocad NIL
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_menuload/V25/EN_US")

(:name "MENUUNLOAD"
 :category :customization
 :aliases ()
 :intl-name "_MENUUNLOAD"
 :synopsis "Opens the Customization Groups dialog box."
 :options ()
 :arguments "Supplies no arguments: (command \"_MENUUNLOAD\") opens the Customization Groups dialog box, where customization (menu) groups can be unloaded interactively. No command-line prompt sequence is documented."
 :description "In BricsCAD, MENUUNLOAD opens the Customization Groups dialog box for managing (loading/unloading) customization groups. Not documented as a command in AutoCAD 2026 (AutoCAD uses CUILOAD/CUIUNLOAD; the legacy MENU command is retained only for script compatibility)."
 :availability :bricscad-only
 :autocad-versions NIL
 :bricscad-versions "all"
 :source-autocad NIL
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_menuunload/V25/EN_US")

(:name "MOVE"
 :category :modify
 :aliases ("M")
 :intl-name "_MOVE"
 :synopsis "Moves objects a specified distance in a specified direction."
 :options ("Displacement")
 :arguments "Selects objects (ending the selection with an empty string), then supplies a base point and a second point that define the displacement vector; e.g. (command \"_MOVE\" ss \"\" base-pt second-pt). A displacement vector may be given instead of two points."
 :description "The MOVE command relocates selected objects by a base point and a second point that together define the distance and direction of movement; a direct displacement value can be entered instead. BricsCAD documents the same base-point/displacement-vector behavior."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-47CE7325-84C0-4414-80A3-29DC98392709.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_move/V25/EN_US")

(:name "NEW"
 :category :file
 :aliases ()
 :intl-name "_NEW"
 :synopsis "Starts a new drawing."
 :options ()
 :arguments "Dialog-driven: displays the Select Template dialog (or the Create New Drawing dialog when STARTUP is 1) to choose a DWT/DWG template. When FILEDIA is 0 it prompts at the command line for a template file name. A scripted (command \"_NEW\") typically supplies no further arguments unless FILEDIA is 0."
 :description "Creates a new drawing. In AutoCAD, behavior depends on the STARTUP system variable (Create New Drawing dialog vs. Select Template dialog), with FILEDIA=0 forcing a command-prompt form. In BricsCAD, NEW opens the Select Template dialog box to pick a DWT or DWG template."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-90BE41A2-7FFD-44DB-A927-B7A9277C75C2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_new/V25/EN_US")

(:name "OFFSET"
 :category :modify
 :aliases ("O")
 :intl-name "_OFFSET"
 :synopsis "Creates concentric circles, parallel lines, and parallel curves."
 :options ("Through" "Erase" "Layer" "Multiple" "Undo" "Exit" "Both Sides")
 :arguments "First an offset distance (or the \"Through\" keyword to offset through a picked point), then repeatedly: select an entity to offset and a point indicating the side. Keyword options include \"Erase\", \"Layer\" (Current or Source), \"Multiple\", \"Undo\", and \"Exit\". An empty string ends the command."
 :description "Creates parallel copies of lines, polylines, splines, circles and edges at a specified distance or through a designated point; the radius of curved entities is adjusted accordingly. The command repeats automatically until the user exits."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-C0E4246D-C420-42BD-A6FC-8B1852EFD005.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_offset/V25/EN_US")

(:name "OPEN"
 :category :file
 :aliases ()
 :intl-name "_OPEN"
 :synopsis "Opens an existing drawing file."
 :options ()
 :arguments "Dialog-driven: displays the Select File (Open file) dialog. When FILEDIA is 0 it prompts for the name of the drawing to open (enter ~ to force the dialog). A scripted call may supply the drawing file name when FILEDIA is 0."
 :description "Opens an existing drawing for editing. AutoCAD shows the Select File dialog by default and supports Partial Open / Partial Open Read-Only to load specific geometry, views, or layers. BricsCAD opens a file dialog supporting DWG, DXF, DWI and various 3D formats depending on the edition (Lite and above)."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-3738384A-3047-4532-866C-23D3FFF3AA45.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_open/V25/EN_US")

(:name "PAN"
 :category :view
 :aliases ("P")
 :intl-name "_PAN"
 :synopsis "Shifts the view without changing the viewing direction or magnification (moves the entire drawing within the current viewport)."
 :options ()
 :arguments "Interactive real-time pan takes no scriptable input (drag with the mouse; Esc/Enter to exit). The command-line form -PAN accepts a base point (or displacement) and a second point defining the pan distance and direction, e.g. (command \"_-PAN\" pt1 pt2). In BricsCAD, PERSPECTIVE must be 0."
 :description "Moves the view in the plane of the screen so a different portion of the drawing is shown at the same magnification. In AutoCAD, real-time panning is done by dragging the cursor; the -PAN variant shifts the view by specifying up to two points. In BricsCAD, hold the left mouse button and drag; right-click for menu options."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-E7E03AF4-6AEA-405E-8FC4-4C271E6F599A.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pan/V25/EN_US")

(:name "PLINE"
 :category :draw
 :aliases ("PL" "POLYLINE")
 :intl-name "_PLINE"
 :synopsis "Creates a 2D polyline, a single object composed of connected line and arc segments."
 :options ("Arc" "Close" "Halfwidth" "Length" "Undo" "Width")
 :arguments "Supplies a start point, then successive vertex points; keywords switch modes and set attributes: \"A\" (Arc) enters arc-segment mode (with Angle, CEnter, CLose, Direction, Radius, Second pt sub-keywords) and \"L\" returns to Line mode, \"W\" (Width) and \"H\" (Halfwidth) set segment width, \"U\" (Undo) removes the last segment, and \"C\" (Close) closes the polyline. ENTER ends the command."
 :description "Creates a single 2D polyline object made of connected straight and/or arc segments. Segments can have uniform or tapering width, arc mode can be toggled mid-command, and the Close option joins the last vertex to the first. The PLINETYPE system variable controls the type of 2D polyline created."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-11883C70-6435-4F80-8FB4-F6E933B8FD94.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_pline/V25/EN_US")

(:name "QNEW"
 :category :file
 :aliases ()
 :intl-name "_QNEW"
 :synopsis "Starts a new drawing from the default drawing template file."
 :options ()
 :arguments "Supplies no arguments: (command \"_QNEW\") starts a new drawing using the configured default template. If no default template is set (template = None / unspecified) and FILEDIA is on, AutoCAD presents the Select Template File dialog; behavior also depends on the STARTUP and FILEDIA system variables."
 :description "Opens a new drawing/document tab based on the default template file and current user profile settings (\"quick new\"). In AutoCAD the default template is the one set for QNEW in Options; if unset, a template-selection dialog appears. In BricsCAD it opens a new document with the default template and profile settings."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CF3C039B-CF22-4933-928A-93A3AA71C4FA.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qnew/V25/EN_US")

(:name "QSAVE"
 :category :file
 :aliases ()
 :intl-name "_QSAVE"
 :synopsis "Saves the current drawing immediately using the default file format."
 :options ()
 :arguments "No arguments when the drawing already has a name (saves immediately with no prompts). If the drawing is unnamed or opened read-only, the Save Drawing As dialog appears and a file name must be supplied."
 :description "Quick-saves the current drawing without prompting when it has already been named; otherwise the Save Drawing As dialog is displayed. In AutoCAD the save may be incremental or full depending on ISAVEPERCENT (format conversion forces a full save). Behavior is equivalent in BricsCAD (\"quick save\")."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-99900C99-230D-4709-B8DD-A44435328A13.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_qsave/V25/EN_US")

(:name "RECTANG"
 :category :draw
 :aliases ("REC" "RECT" "RECTANGLE")
 :intl-name "_RECTANG"
 :synopsis "Creates a closed rectangular polyline."
 :options ("Chamfer" "Elevation" "Fillet" "Thickness" "Width" "Area" "Dimensions" "Rotation")
 :arguments "Optionally supplies a keyword (Chamfer/Fillet/Elevation/Thickness/Width/Area/Dimensions/Rotation) to set properties, then the first corner point and the opposite corner point; e.g. (command \"_RECTANG\" p1 p2)."
 :description "Creates a closed four-sided rectangular polyline defined by two diagonal corner points, or by area plus a length/width, with optional chamfered or filleted corners, rotation, elevation, thickness, and line width. BricsCAD lists five construction methods for the rectangle."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-188B2DDA-6CD8-4D37-BF26-E6CF27C34C75.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_rectang/V25/EN_US")

(:name "REGEN"
 :category :view
 :aliases ("RE")
 :intl-name "_REGEN"
 :synopsis "Regenerates the drawing from within the current viewport."
 :options ()
 :arguments "No input arguments; (command \"_REGEN\") regenerates the current viewport and returns immediately with no prompts or options."
 :description "Recomputes the locations and visibility of all objects in the current viewport, reindexes the drawing database for optimum display and object-selection performance, and resets the area available for realtime panning and zooming. AutoCAD and BricsCAD describe identical behavior."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-CC98095F-B4C4-4B25-9097-A7B6EF4260B2.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_regen/V25/EN_US")

(:name "ROTATE"
 :category :modify
 :aliases ("RO")
 :intl-name "_ROTATE"
 :synopsis "Rotates objects around a base point."
 :options ("Copy" "Reference")
 :arguments "Selection set of entities, then a base point, then a rotation angle. Instead of an angle, the keyword \"Copy\" makes a rotated duplicate, or \"Reference\" specifies a reference angle followed by the new absolute angle. Positive angles rotate counterclockwise, negative clockwise."
 :description "Rotates selected entities about a specified base point to an absolute angle; the rotation axis passes through the base point parallel to the Z axis of the current UCS. Positive values rotate counterclockwise, negative values clockwise, measured from the positive x-axis at 0 degrees."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-1C265537-FBAC-48D5-B448-B72E777071E5.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_rotate/V25/EN_US")

(:name "SCALE"
 :category :modify
 :aliases ("SC")
 :intl-name "_SCALE"
 :synopsis "Enlarges or reduces selected objects, keeping the proportions of the object the same after scaling."
 :options ("Copy" "Reference")
 :arguments "Selection set of entities, then a base point, then a scale factor. Instead of a factor, the keyword \"Copy\" scales a duplicate, or \"Reference\" specifies a reference length followed by the new length. A factor above 1 enlarges, between 0 and 1 shrinks, and a negative value scales in the opposite direction."
 :description "Resizes 2D and 3D entities uniformly about a base point by a scale factor or a reference length, keeping proportions the same. Values above 1 enlarge, values between 0 and 1 reduce, and negative values scale in the opposite direction."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D4E17E51-5000-4AB6-8D6A-6D2AB4863C75.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_scale/V25/EN_US")

(:name "SOLID"
 :category :draw
 :aliases ("PLANE" "SO")
 :intl-name "_SOLID"
 :synopsis "Creates solid-filled triangles and quadrilaterals (2D solid-filled polygons)."
 :options ("Rectangle" "Square" "Triangle")
 :arguments "Supplies successive corner points: first, second, third, then a fourth point (or empty string to make a triangle), ending with an empty string; e.g. (command \"_SOLID\" p1 p2 p3 p4 \"\"). Fill shows only when FILLMODE is on and the view is orthogonal to the solid."
 :description "The SOLID command creates 3- and 4-sided solid-filled 2D polygons (not 3D solids); pressing Enter at the fourth point makes a filled triangle and giving the fourth point makes a quadrilateral, and successive point pairs chain further faces into one object. Filled display requires FILLMODE on and an orthogonal view. BricsCAD additionally offers predefined Rectangle, Square, and Triangle shape options."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-0998E0EE-7829-4AA4-9282-4FC703F9B1F4.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_solid/V25/EN_US")

(:name "TEXT"
 :category :draw
 :aliases ("TX")
 :intl-name "_TEXT"
 :synopsis "Creates a single-line text object."
 :options ("Justify" "Style" "Align" "Fit" "Center" "Middle" "Right" "TL" "TC" "TR" "ML" "MC" "MR" "BL" "BC" "BR")
 :arguments "Supplies a text insertion (start) point, a text height, a rotation angle, then the text string; alternatively the first response is \"J\" (Justify) followed by a justification keyword (Align, Fit, Center, Middle, Right, or the nine TL/TC/TR/ML/MC/MR/BL/BC/BR positions) or \"S\" (Style) followed by a text style name. Each line entered creates an independent text object."
 :description "Creates single-line text; each line entered is an independent object that can be moved, formatted, or edited separately. Height and rotation are prompted (height is skipped for fixed-height styles), and justification and text style can be set via keywords. In BricsCAD, text can evaluate LISP expressions when TEXTEVAL is 1, and for annotative styles the height value is paper-space height."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-D1C664DD-63D9-467E-8EC1-2F5A1777A924.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_text/V25/EN_US")

(:name "ZOOM"
 :category :view
 :aliases ("Z")
 :intl-name "_ZOOM"
 :synopsis "Increases or decreases the magnification of the view in the current viewport."
 :options ("All" "Center" "Dynamic" "Extents" "Previous" "Scale" "Window" "Object" "In" "Out" "Left" "Right" "Realtime")
 :arguments "Optionally a corner point of a window, or one of the keyword options: \"All\", \"Center\" (center point then magnification/height), \"Dynamic\", \"Extents\", \"Previous\", \"Scale\" (a value, optionally suffixed with x or xp), \"Window\" (two corner points), \"Object\" (a selection set), \"In\", \"Out\". With no argument it enters real-time zoom."
 :description "Changes the magnification of the view in the current viewport, like a camera zoom, without altering the absolute size of objects in the drawing. Provides options to view different portions and scales of the drawing (extents, window, scale factor, previous, object, etc.)."
 :availability :both
 :autocad-versions "all"
 :bricscad-versions "all"
 :source-autocad "https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-66E7DB72-B2A7-4166-9970-9E19CC06F739.htm"
 :source-bricscad "https://help.bricsys.com/document/_commandreference--CMD_zoom/V25/EN_US")

)
