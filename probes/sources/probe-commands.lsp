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
      ;; window and point picks find nothing there).
      (if (and (= (type args) 'LIST) (/= (car args) 'LAMBDA))
          (apply 'command args)
          (apply args '()))
      (cad-probe--cmd-cancel)
      (setq e (if marker (entnext marker) (entnext))
            out '()
            n 0)
      (while e
        (setq out (cons (cad-probe--cmd-summary e) out)
              n (1+ n)
              e (entnext e)))
      (cons n (reverse out))))))

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
  (cad-probe--cmd-case "DIVIDE a line into 4"
    '("_.LINE" "0,0" "4,0" "" "_.DIVIDE" "_L" "4"))
  (cad-probe--cmd-case "MEASURE a line by 1.5"
    '("_.LINE" "0,0" "4,0" "" "_.MEASURE" "_L" "1.5"))
  (cad-probe--cmd-case "LENGTHEN a line by delta 1 at its end"
    '("_.LINE" "0,0" "4,0" "" "_.LENGTHEN" "_DE" "1" "4,0" ""))
  (cad-probe--cmd-case "JOIN two collinear lines"
    (function (lambda ( / e1)
      (command "_.LINE" "0,0" "2,0" "")
      (setq e1 (entlast))
      (command "_.LINE" "2,0" "4,0" "")
      (command "_.JOIN" e1 (entlast) ""))))
  (cad-probe--cmd-case "CONVERTPOLY light to heavy"
    '("_.PLINE" "0,0" "2,0" "2,1" "" "_.CONVERTPOLY" "_H" "_L" ""))
  (cad-probe--cmd-case "MATCHPROP layer and color"
    '("_.CIRCLE" "0,0" "1" "_.CHPROP" "_L" "" "_C" "3" ""
      "_.LINE" "5,5" "6,6" "" "_.MATCHPROP" "0.7071,0.7071" "5.5,5.5" ""))
  (cad-probe--cmd-case "SETBYLAYER color"
    '("_.CIRCLE" "0,0" "1" "_.CHPROP" "_L" "" "_C" "2" "" "_.SETBYLAYER" "_L" "" "_Y" "_Y"))

  ;; LAST: from LISP, AutoCAD's EXPLODE takes one object and ends, so a
  ;; trailing "" repeats it and leaves it waiting -- it derailed every
  ;; later case on 2026-10-03 (job 16914186872). No trailing "".
  (cad-probe--cmd-case "EXPLODE a rectangle"
    '("_.RECTANG" "0,0" "2,1" "_.EXPLODE" "_L"))

  (setvar "CMDECHO" cmdecho)
  (setvar "OSMODE" osmode)
  (princ))
