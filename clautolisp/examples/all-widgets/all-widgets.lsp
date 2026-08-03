;;; all-widgets.lsp -- driver for all-widgets.dcl.
;;;
;;; Loads the dialog, wires a $value-recording action on every interactive
;;; tile, then on accept prints ONE labelled report of every tile's final
;;; value.  The report format is identical in AutoCAD, BricsCAD and
;;; clautolisp (GUI and TUI), so a human can diff the four runs.
;;;
;;; Standard AutoLISP only.  The .dcl is loaded by a RELATIVE name, so run
;;; this from the directory that contains all-widgets.dcl (on clautolisp a
;;; relative load_dialog resolves against the current working directory; in
;;; AutoCAD/BricsCAD put the directory on the support-file search path or
;;; run from it).  No absolute paths are committed here.

;; The value-bearing tiles, paired with a human label for the report.
;; Order is fixed so the four environments produce byte-comparable output.
(setq *aw-report-tiles*
      '(("edit_box  name"            . "name")
        ("toggle    shout (0/1)"     . "shout")
        ("popup_list colour (index)" . "colour")
        ("radio     size  (key)"     . "size")
        ("list_box  fruit (index)"   . "fruit")
        ("slider    volume"          . "volume")))

(defun all-widgets-report ( / )
  (princ "\n===== all-widgets report =====")
  (foreach kv *aw-report-tiles*
    (princ (strcat "\n" (car kv) " : \"" (get_tile (cdr kv)) "\"")))
  ;; image / image_button carry no readable value (get_tile is empty); they
  ;; are painted, not queried -- noted here for completeness.
  (princ "\nimage     swatch : (no value -- painted)")
  (princ "\nimage_btn logo   : (no value -- click action only)")
  (princ "\n==============================")
  (princ))

(defun c:all-widgets ( / id st)
  (setq id (load_dialog "all-widgets.dcl"))
  (cond
    ((< id 0)
     (princ "\nCould not load all-widgets.dcl -- run from the example directory."))
    (T
     (new_dialog "all_widgets" id)
     ;; Seed defaults so an un-touched run still reports meaningful values.
     (set_tile "name" "World")
     ;; Populate the two lists.
     (start_list "colour") (add_list "Red") (add_list "Green") (add_list "Blue") (end_list)
     (start_list "fruit")
     (add_list "Apple") (add_list "Banana") (add_list "Cherry") (add_list "Date")
     (end_list)
     ;; Record every interactive tile's $value/$reason as it changes.
     (foreach k '("name" "shout" "colour" "size" "fruit" "volume")
       (action_tile k
         "(princ (strcat \"\\n[action] \" $key \" = \\\"\" $value \"\\\" reason \" (itoa $reason)))"))
     (action_tile "logo" "(princ \"\\n[action] logo image_button clicked\")")
     (action_tile "reset"
       "(progn (set_tile \"name\" \"\") (set_tile \"shout\" \"0\") (set_tile \"volume\" \"0\")
               (princ \"\\n[action] reset\"))")
     (action_tile "accept" "(all-widgets-report) (done_dialog 1)")
     (action_tile "cancel" "(done_dialog 0)")
     (setq st (start_dialog))
     (unload_dialog id)
     (if (= st 1)
         (princ "\nall-widgets: accepted.")
         (princ "\nall-widgets: cancelled."))))
  (princ))

;; Auto-run when loaded as a script (harmless in an interactive CAD too).
(c:all-widgets)
