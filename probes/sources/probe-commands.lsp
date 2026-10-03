;;;; probes/sources/probe-commands.lsp
;;;;
;;;; What each core-now CAD command MAKES, measured -- so cador implements
;;;; commands against the vendors' output, not against their documentation
;;;; (autolisp-spec-alref-commands.issue, Phase 4).
;;;;
;;;; Each case drives one (command ...) sequence with every input supplied,
;;;; then records the entities it created as a portable summary: the entity
;;;; type, layer, text / name groups and the geometry groups (points, reals,
;;;; flags, counts), reals fixed to 6 decimals. Handles, enames, owners,
;;;; subclass markers and display properties are left out: they cannot be
;;;; compared across hosts. The first value of each record is the number of
;;;; entities created.
;;;;
;;;; Object snaps would move the supplied points, so OSMODE is 0 for the
;;;; run (restored after); a command left waiting for input is cancelled
;;;; before the next case so one malformed sequence cannot feed the next.

(defun cad-probe--cmd-fmt (v)
  ;; A group value as whitespace-free text.
  (cond ((= (type v) 'REAL) (rtos v 2 6))
        ((= (type v) 'INT) (itoa v))
        ((= (type v) 'STR) (if (= v "") "\"\"" v))
        ((and (listp v) v (numberp (car v)))
         (apply 'strcat (cons (cad-probe--cmd-fmt (car v))
                              (mapcar '(lambda (x) (strcat "," (cad-probe--cmd-fmt x)))
                                      (cdr v)))))
        (T "?")))

(defun cad-probe--cmd-keep-p (code)
  ;; The groups that describe what a command made.
  (or (member code '(0 1 2 3 7 8 38 39 62))
      (and (>= code 10) (<= code 18))
      (and (>= code 40) (<= code 51))
      (and (>= code 70) (<= code 79))
      (and (>= code 90) (<= code 99))))

(defun cad-probe--cmd-summary (e / out)
  ;; ("CIRCLE|8=0|10=1.000000,2.000000,0.000000|40=3.000000" ...) for one entity.
  (setq out "")
  (foreach g (entget e)
    (if (and (= (type (car g)) 'INT) (cad-probe--cmd-keep-p (car g)))
      (setq out (strcat out (if (= out "") "" "|")
                        (itoa (car g)) "=" (cad-probe--cmd-fmt (cdr g))))))
  out)

(defun cad-probe--cmd-cancel ( / n)
  ;; End whatever command is still waiting for input. CMDACTIVE is a BIT
  ;; field: only bit 1 is "a command is active". Under a script -- how CI
  ;; drives accoreconsole -- bit 4 stays set for the whole run, so the
  ;; first version, (while (> (getvar "CMDACTIVE") 0) (command)), never
  ;; ended on AutoCAD and the job ran into its 30-minute timeout
  ;; (2026-10-03). Bit 1 only, and a bounded number of tries.
  (setq n 0)
  (while (and (< n 5)
              (getvar "CMDACTIVE")
              (= 1 (logand 1 (getvar "CMDACTIVE"))))
    (command)
    (setq n (1+ n))))

(setq cad-probe--may-be-absent
  ;; Commands seen missing on a headless engine (AutoCAD 2022's console has
  ;; no MATCHPROP) or provided by Express Tools: only these are checked --
  ;; GETCNAME does not know every command (it reported RECTANG unknown).
  '("MATCHPROP" "ADDSELECTED" "SETBYLAYER" "COPYM" "FLATTEN" "XPLODE"
    "3DROTATE" "-OVERKILL" "OVERKILL" "3DARRAY"))

(defun cad-probe--known-command-p (name)
  ;; Whether this engine has the command NAME: built in (GETCNAME resolves
  ;; its "_" form) or a LISP command (Express Tools define C:NAME).
  ;; 2026-10-03: AutoCAD's console has no MATCHPROP; the case's remaining
  ;; input reached the Command prompt and the job hung to its timeout.
  ;; An engine whose GETCNAME cannot even resolve _LINE (a stub, as on
  ;; clautolisp) tells nothing: then every command counts as known.
  ;; On AutoCAD every listed command is skipped outright: neither GETCNAME
  ;; nor C:NAME is reliable there (C:3DARRAY is an autoload stub whose
  ;; file the console cannot load -- job 16915457382 hung on it), and one
  ;; hang loses the whole run.
  (cond ((not (member name cad-probe--may-be-absent)) T)
        ((= cad-probe-product "autocad") nil)
        ((not (getcname "_LINE")) T)
        ((getcname (strcat "_" name)) T)
        (T (and (eval (read (strcat "c:" name))) t))))

(setq cad-probe--unknown nil)

(defun cad-probe--cmd-args (args / name)
  ;; Run (command . ARGS) when its command, "_.NAME" first, is known;
  ;; otherwise note it and do nothing.
  (setq name (substr (car args) 3))
  (if (cad-probe--known-command-p name)
      (apply 'command args)
      (setq cad-probe--unknown name)))

(defun cad-probe--token-list-commands (args / out)
  ;; The "_.NAME" command names inside a token list.
  (foreach a args
    (if (and (= (type a) 'STR) (> (strlen a) 2) (= (substr a 1 2) "_."))
      (setq out (cons (substr a 3) out))))
  (reverse out))

(defun cad-probe--cmd-case (name args / marker e out n)
  ;; Run (command . ARGS) and record what it made, as one probe result.
  ;; The case name goes to the console FIRST: on 2026-10-03 AutoCAD 2022
  ;; broke into its LISP debugger ("Passage en mode debogage") somewhere
  ;; in this suite and waited out the job timeout, leaving no results --
  ;; the job log is then the only witness of which case it was.
  (princ (strcat "\ncad-probe: commands case " name "\n"))
  (cad-probe-capture "commands" name
    (function (lambda ()
      ;; The REAL last entity: ENTLAST names the last MAIN entity, whose
      ;; VERTEX / ATTRIB / SEQEND run ENTNEXT would otherwise walk first.
      (setq marker (entlast))
      (while (and marker (entnext marker)) (setq marker (entnext marker)))
      ;; ARGS is a token list, or a function that drives the commands
      ;; itself (to select by ename: a headless AutoCAD has no view, so
      ;; window and point picks find nothing there). A function's TYPE
      ;; depends on compilation -- the list (LAMBDA ...) interpreted, a
      ;; USUBR / SUBR compiled -- so test the shape we control instead:
      ;; a token list starts with the command name, a string.
      (setq cad-probe--unknown nil)
      (if (and (= (type args) 'LIST) (= (type (car args)) 'STR))
          (progn
            (foreach c (cad-probe--token-list-commands args)
              (if (and (not cad-probe--unknown) (not (cad-probe--known-command-p c)))
                (setq cad-probe--unknown c)))
            (if (not cad-probe--unknown) (apply 'command args)))
          (apply args '()))
      (cad-probe--cmd-cancel)
      (setq e (if marker (entnext marker) (entnext))
            out '()
            n 0)
      (while e
        (setq out (cons (cad-probe--cmd-summary e) out)
              n (1+ n)
              e (entnext e)))
      (if cad-probe--unknown
          (strcat "UNKNOWN-COMMAND " cad-probe--unknown)
          (cons n (reverse out)))))))

(defun cad-probe-run-command-probes ( / osmode cmdecho)
  (setq osmode (getvar "OSMODE") cmdecho (getvar "CMDECHO"))
  (setvar "OSMODE" 0)
  (setvar "CMDECHO" 0)
  (cad-probe--cmd-cancel)

  ;; Already implemented in cador -- the baseline the new ones join.
  (cad-probe--cmd-case "LINE two segments" '("_.LINE" "0,0" "4,0" "4,3" ""))
  (cad-probe--cmd-case "CIRCLE center radius" '("_.CIRCLE" "1,2" "3"))
  (cad-probe--cmd-case "ARC three points" '("_.ARC" "0,0" "1,1" "2,0"))
  (cad-probe--cmd-case "PLINE three vertices" '("_.PLINE" "0,0" "4,0" "4,3" ""))
  (cad-probe--cmd-case "DONUT inside outside center" '("_.DONUT" "1" "2" "5,5" ""))

  ;; S1 draw constructions.
  (cad-probe--cmd-case "POINT" '("_.POINT" "1,2"))
  (cad-probe--cmd-case "RAY base through" '("_.RAY" "0,0" "1,1" ""))
  (cad-probe--cmd-case "XLINE point through" '("_.XLINE" "0,0" "1,2" ""))
  (cad-probe--cmd-case "ELLIPSE axis endpoints + distance" '("_.ELLIPSE" "0,0" "4,0" "1"))
  (cad-probe--cmd-case "ELLIPSE center" '("_.ELLIPSE" "_C" "0,0" "4,0" "1"))
  (cad-probe--cmd-case "POLYGON 6 inscribed r2" '("_.POLYGON" "6" "0,0" "_I" "2"))
  (cad-probe--cmd-case "POLYGON 5 circumscribed r2" '("_.POLYGON" "5" "0,0" "_C" "2"))
  (cad-probe--cmd-case "POLYGON 4 by edge" '("_.POLYGON" "4" "_E" "0,0" "2,0"))
  (cad-probe--cmd-case "RECTANG two corners" '("_.RECTANG" "0,0" "3,2"))
  (cad-probe--cmd-case "RECTANG reversed corners" '("_.RECTANG" "3,2" "0,0"))
  (cad-probe--cmd-case "SPLINE four fit points" '("_.SPLINE" "0,0" "1,1" "2,0" "3,1" "" "" ""))
  (cad-probe--cmd-case "3DPOLY three vertices" '("_.3DPOLY" "0,0,0" "1,0,1" "1,1,2" ""))
  (cad-probe--cmd-case "HELIX center r1 r2 height" '("_.HELIX" "0,0" "1" "2" "3"))
  (cad-probe--cmd-case "TRACE width then points" '("_.TRACE" "0.5" "0,0" "4,0" "4,3" ""))
  (cad-probe--cmd-case "MLINE three points" '("_.MLINE" "0,0" "4,0" "4,3" ""))
  (cad-probe--cmd-case "REGION from a circle"
    (list "_.CIRCLE" "20,20" "1" "_.REGION" "_L" ""))

  ;; S2 modify / properties: each case makes its own object, then edits
  ;; it; the record is the object's final state (plus anything created).
  (cad-probe--cmd-case "SCALE a circle by 2 about the origin"
    '("_.CIRCLE" "1,0" "1" "_.SCALE" "_L" "" "0,0" "2"))
  (cad-probe--cmd-case "STRETCH a line end by a crossing window"
    '("_.LINE" "0,0" "4,0" "" "_.STRETCH" "_C" "3,-1" "5,1" "" "4,0" "6,1"))
  (cad-probe--cmd-case "ALIGN a line onto another direction"
    '("_.LINE" "0,0" "2,0" "" "_.ALIGN" "_L" "" "0,0" "1,1" "2,0" "1,3" "" "_N"))
  (cad-probe--cmd-case "CHPROP color 1"
    '("_.CIRCLE" "0,0" "1" "_.CHPROP" "_L" "" "_C" "1" ""))
  (cad-probe--cmd-case "CHANGE a line endpoint"
    '("_.LINE" "0,0" "2,0" "" "_.CHANGE" "_L" "" "3,3"))
  ;; Object picks as (ename point), the entsel form: a headless AutoCAD has
  ;; no view to resolve a bare point, and a pick it cannot resolve leaves
  ;; the command waiting -- whose cancel then poisons every later case
  ;; (2026-10-03: DIVIDE "_L" did exactly that, job 16914406699).
  (cad-probe--cmd-case "LENGTHEN a line by delta 1 at its end"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" ""))
      (cad-probe--cmd-args (list "_.LENGTHEN" "_DE" "1" (list (entlast) '(4.0 0.0 0.0)) "")))))
  (cad-probe--cmd-case "JOIN two collinear lines"
    (function (lambda ( / e1)
      (cad-probe--cmd-args (list "_.LINE" "0,0" "2,0" ""))
      (setq e1 (entlast))
      (cad-probe--cmd-args (list "_.LINE" "2,0" "4,0" ""))
      (cad-probe--cmd-args (list "_.JOIN" e1 (entlast) "")))))
  (cad-probe--cmd-case "CONVERTPOLY light to heavy"
    '("_.PLINE" "0,0" "2,0" "2,1" "" "_.CONVERTPOLY" "_H" "_L" ""))
  (cad-probe--cmd-case "MATCHPROP layer and color"
    (function (lambda ( / src)
      (cad-probe--cmd-args (list "_.CIRCLE" "0,0" "1" "_.CHPROP" "_L" "" "_C" "3" ""))
      (setq src (entlast))
      (cad-probe--cmd-args (list "_.LINE" "5,5" "6,6" ""))
      (cad-probe--cmd-args (list "_.MATCHPROP" src (entlast) "")))))
  (cad-probe--cmd-case "SETBYLAYER color"
    '("_.CIRCLE" "0,0" "1" "_.CHPROP" "_L" "" "_C" "2" "" "_.SETBYLAYER" "_L" "" "_Y" "_Y"))

  ;; S5 geometry: picks as (ename point); classic TRIM / EXTEND (edges
  ;; first, then the object), when the sysvar exists.
  (vl-catch-all-apply 'setvar (list "TRIMEXTENDMODE" 0))
  (cad-probe--cmd-case "TRIM a line at a cutting edge"
    (function (lambda ( / a)
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" "")) (setq a (entlast))
      (cad-probe--cmd-args (list "_.LINE" "2,-1" "2,1" ""))
      (cad-probe--cmd-args (list "_.TRIM" (entlast) "" (list a '(3.0 0.0 0.0)) "")))))
  (cad-probe--cmd-case "EXTEND a line to a boundary"
    (function (lambda ( / a)
      (cad-probe--cmd-args (list "_.LINE" "0,0" "1,0" "")) (setq a (entlast))
      (cad-probe--cmd-args (list "_.LINE" "3,-1" "3,1" ""))
      (cad-probe--cmd-args (list "_.EXTEND" (entlast) "" (list a '(1.0 0.0 0.0)) "")))))
  (cad-probe--cmd-case "FILLET two lines radius 1"
    (function (lambda ( / a)
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" "")) (setq a (entlast))
      (cad-probe--cmd-args (list "_.LINE" "4,0" "4,4" ""))
      (cad-probe--cmd-args (list "_.FILLET" "_R" "1"))
      (cad-probe--cmd-args (list "_.FILLET" (list a '(2.0 0.0 0.0)) (list (entlast) '(4.0 2.0 0.0)))))))
  (cad-probe--cmd-case "CHAMFER two lines distances 1 1"
    (function (lambda ( / a)
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" "")) (setq a (entlast))
      (cad-probe--cmd-args (list "_.LINE" "4,0" "4,4" ""))
      (cad-probe--cmd-args (list "_.CHAMFER" "_D" "1" "1"))
      (cad-probe--cmd-args (list "_.CHAMFER" (list a '(2.0 0.0 0.0)) (list (entlast) '(4.0 2.0 0.0)))))))
  (cad-probe--cmd-case "OFFSET a line by 1 to the left"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" ""))
      (cad-probe--cmd-args (list "_.OFFSET" "1" (list (entlast) '(2.0 0.0 0.0)) "2,1" "")))))
  (cad-probe--cmd-case "OFFSET a circle by 1 outward"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.CIRCLE" "0,0" "2"))
      (cad-probe--cmd-args (list "_.OFFSET" "1" (list (entlast) '(2.0 0.0 0.0)) "5,0" "")))))
  (cad-probe--cmd-case "BREAK a line between two points"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" ""))
      (cad-probe--cmd-args (list "_.BREAK" (list (entlast) '(1.0 0.0 0.0)) "3,0")))))
  (cad-probe--cmd-case "PEDIT a line into a polyline of width 0.5"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" ""))
      (cad-probe--cmd-args (list "_.PEDIT" (list (entlast) '(2.0 0.0 0.0)) "_Y" "_W" "0.5" "")))))

  ;; S2, second batch (several are Express Tools: their absence on a
  ;; headless engine is an answer too). Selection by ename throughout.
  (cad-probe--cmd-case "DIVIDE by ename into 4"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" ""))
      (cad-probe--cmd-args (list "_.DIVIDE" (entlast) "4")))))
  (cad-probe--cmd-case "MEASURE by ename by 1.5"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" ""))
      (cad-probe--cmd-args (list "_.MEASURE" (entlast) "1.5")))))
  (cad-probe--cmd-case "ADDSELECTED a circle"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.CIRCLE" "0,0" "1"))
      (cad-probe--cmd-args (list "_.ADDSELECTED" (entlast) "5,5" "2")))))
  (cad-probe--cmd-case "-ARRAY rectangular 2 rows 3 columns"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.CIRCLE" "0,0" "0.5"))
      (cad-probe--cmd-args (list "_.-ARRAY" (entlast) "" "_R" "2" "3" "2" "3")))))
  (cad-probe--cmd-case "-ARRAY polar 4 items over 360"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.CIRCLE" "2,0" "0.5"))
      (cad-probe--cmd-args (list "_.-ARRAY" (entlast) "" "_P" "0,0" "4" "360" "_Y")))))
  (cad-probe--cmd-case "ARRAYRECT non-associative 3x2"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.CIRCLE" "0,0" "0.5"))
      (cad-probe--cmd-args (list "_.ARRAYRECT" (entlast) "" "_AS" "_N" "_COU" "3" "2" "_S" "3" "2" "_X")))))
  (cad-probe--cmd-case "ARRAYPOLAR non-associative 4 items"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.CIRCLE" "2,0" "0.5"))
      (cad-probe--cmd-args (list "_.ARRAYPOLAR" (entlast) "" "0,0" "_AS" "_N" "_I" "4" "_X")))))
  (cad-probe--cmd-case "3DARRAY rectangular 2x2x2"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.CIRCLE" "0,0" "0.5"))
      (cad-probe--cmd-args (list "_.3DARRAY" (entlast) "" "_R" "2" "2" "2" "1" "1" "1")))))

  ;; Express Tools (COPYM FLATTEN XPLODE) and the 3DROTATE gizmo may be
  ;; missing on a headless engine: run them late, so a missing command
  ;; cannot spoil the cases above.
  (cad-probe--cmd-case "COPYM two copies"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.CIRCLE" "0,0" "1"))
      (cad-probe--cmd-args (list "_.COPYM" (entlast) "" "0,0" "3,0" "6,0" "")))))
  (cad-probe--cmd-case "FLATTEN a 3D line"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.LINE" "0,0,1" "2,0,3" ""))
      (cad-probe--cmd-args (list "_.FLATTEN" (entlast) "" "_N")))))
  (cad-probe--cmd-case "3DROTATE a line 90 about Z"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.LINE" "0,0" "2,0" ""))
      (cad-probe--cmd-args (list "_.3DROTATE" (entlast) "" "0,0,0" "_Z" "90")))))
  (cad-probe--cmd-case "XPLODE a rectangle"
    (function (lambda ()
      (cad-probe--cmd-args (list "_.RECTANG" "0,0" "2,1"))
      (cad-probe--cmd-args (list "_.XPLODE" (entlast) "" "_E")))))

  ;; S4 arrays: classic -ARRAY, and the array commands made NON-associative
  ;; (_AS _N) so the result is plain copies rather than an array object.

  (cad-probe--cmd-case "OVERKILL two identical lines"
    (function (lambda ( / a)
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" "")) (setq a (entlast))
      (cad-probe--cmd-args (list "_.LINE" "0,0" "4,0" ""))
      (cad-probe--cmd-args (list "_.-OVERKILL" a (entlast) "" "")))))

  ;; ARRAY _R left AutoCAD 2022's console waiting (job 16915375455): late.
  (cad-probe--cmd-case "ARRAY rectangular non-associative"
    (function (lambda ()
      ;; AutoCAD 2022's console has ARRAY but leaves it waiting on this
      ;; input, which hangs the whole job: skipped there.
      (if (= cad-probe-product "autocad")
          (setq cad-probe--unknown "ARRAY (SKIPPED-ON-AUTOCAD)")
          (progn
            (cad-probe--cmd-args (list "_.CIRCLE" "0,0" "0.5"))
            (cad-probe--cmd-args (list "_.ARRAY" (entlast) "" "_R" "_AS" "_N"
                                       "_COU" "2" "2" "_S" "3" "3" "_X")))))))

  ;; LAST: from LISP, AutoCAD's EXPLODE takes one object and ends, so a
  ;; trailing "" repeats it and leaves it waiting -- it derailed every
  ;; later case on 2026-10-03 (job 16914186872). No trailing "".
  (cad-probe--cmd-case "EXPLODE a rectangle"
    '("_.RECTANG" "0,0" "2,1" "_.EXPLODE" "_L"))

  (setvar "CMDECHO" cmdecho)
  (setvar "OSMODE" osmode)
  (princ))
