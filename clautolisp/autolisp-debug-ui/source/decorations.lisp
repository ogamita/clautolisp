;;;; aldo decoration / theme renderer.
;;;;
;;;; Turns the `decorations' grammar of *aldo-configuration* (command reference
;;;; §8) into the actual prefix / surrounding pair / ANSI SGR for a situation
;;;; under the active `theme'.  A decoration entry is
;;;;
;;;;   (SITUATION THEME . PARAMS)
;;;;
;;;; where THEME is one of the six theme values; for the glyph themes
;;;; (:unicode / :ascii) PARAMS is (PREFIX) or (OPEN CLOSE); for the colour
;;;; themes (:white-on-black / :black-on-white / :green-on-black) it is
;;;; (FOREGROUND BACKGROUND); for :attributes it is (ATTRIBUTE...).  Any string
;;;; may be written as a list of integer code points (so aldo.conf stays ASCII);
;;;; GLYPH->STRING accepts either form.

(in-package #:clautolisp.debug.ui)

(defparameter +ansi-color-codes+
  '((:black . 0) (:red . 1) (:green . 2) (:yellow . 3)
    (:blue . 4) (:magenta . 5) (:cyan . 6) (:white . 7))
  "ANSI SGR colour offsets (foreground = 30+, background = 40+).")

(defparameter +ansi-attribute-codes+
  '((:bold . 1) (:underline . 4) (:invert . 7))
  "ANSI SGR attribute codes used by the :attributes theme.")

(defun glyph->string (glyph)
  "A decoration glyph as a string. GLYPH is either a string (returned as is) or
a list of integer Unicode code points (turned into the corresponding string)."
  (cond ((stringp glyph) glyph)
        ((and (consp glyph) (every #'integerp glyph))
         (map 'string #'code-char glyph))
        ((null glyph) "")
        ((integerp glyph) (string (code-char glyph)))
        (t (princ-to-string glyph))))

(defun theme-of (&optional (config *aldo-configuration*))
  "The active decoration theme keyword."
  (or (config-get :theme config) :unicode))

(defun decoration-entries (situation &optional (config *aldo-configuration*))
  "All decoration entries for SITUATION (case-insensitive)."
  (let ((s (normalize-config-key situation)))
    (remove-if-not (lambda (entry) (eq (first entry) s))
                   (config-get :decorations config))))

(defun decoration-for (situation theme &optional (config *aldo-configuration*))
  "The PARAMS (the list after the theme tag) of the decoration for SITUATION
under THEME, or NIL if none is configured."
  (let ((s (normalize-config-key situation))
        (th (normalize-config-key theme)))
    (loop :for (es et . params) :in (config-get :decorations config)
          :when (and (eq es s) (eq et th)) :return params)))

(defun color-theme-p (theme)
  (member (normalize-config-key theme)
          '(:white-on-black :black-on-white :green-on-black)))

(defun sgr-wrap (string &key fg bg attrs)
  "Wrap STRING in an ANSI SGR sequence for foreground FG, background BG and the
list of ATTRS; reset afterwards. With no styling requested, returns STRING
unchanged."
  (let ((codes (append (when fg (let ((c (cdr (assoc (normalize-config-key fg)
                                                     +ansi-color-codes+))))
                                  (when c (list (+ 30 c)))))
                       (when bg (let ((c (cdr (assoc (normalize-config-key bg)
                                                     +ansi-color-codes+))))
                                  (when c (list (+ 40 c)))))
                       (loop :for a :in attrs
                             :for c := (cdr (assoc (normalize-config-key a)
                                                   +ansi-attribute-codes+))
                             :when c :collect c))))
    (if codes
        (format nil "~C[~{~D~^;~}m~A~C[0m" #\Escape codes string #\Escape)
        string)))

(defun color-output-enabled-p ()
  "True when ANSI colour is permitted on the current output — the runtime's
resolved colour policy (*COLOR-OUTPUT*), which honours NO_COLOR / --no-color and
non-tty pipes. The decoration renderer consults it so colour / attributes themes
degrade gracefully (command reference §8: a colour theme is never colour alone)."
  (and clautolisp.autolisp-runtime:*color-output* t))

(defun apply-decoration (string situation &optional (config *aldo-configuration*))
  "Decorate STRING for SITUATION under the active theme of CONFIG: prefix it or
wrap it (glyph themes), or apply ANSI colour / attributes (colour / attributes
themes). With no decoration configured for (situation, theme), returns STRING
unchanged. Colour / attributes themes emit ANSI only when colour is enabled
(COLOR-OUTPUT-ENABLED-P); when it is not (NO_COLOR, a pipe, --no-color) they
degrade to the always-present ASCII marker so structure stays visible."
  (let* ((theme (theme-of config))
         (params (decoration-for situation theme config)))
    (cond
      ((null params) string)
      ((or (color-theme-p theme) (eq theme :attributes))
       (cond
         ((not (color-output-enabled-p))
          ;; colour suppressed → fall back to the structural ASCII marker
          (concatenate 'string (situation-prefix situation config) string))
         ((color-theme-p theme)
          (sgr-wrap string :fg (first params) :bg (second params)))
         (t (sgr-wrap string :attrs params))))
      ;; glyph theme: one PARAM => prefix; two => open/close pair
      ((= (length params) 1)
       (concatenate 'string (glyph->string (first params)) string))
      ((>= (length params) 2)
       (concatenate 'string (glyph->string (first params)) string
                    (glyph->string (second params))))
      (t string))))

(defun situation-prefix (situation &optional (config *aldo-configuration*))
  "The plain (un-coloured) prefix string for SITUATION under the active glyph
theme, or \"\" — useful as the always-present ASCII/Unicode marker even when a
colour theme is active (a marker is never colour alone)."
  (let* ((theme (theme-of config))
         ;; for colour/attributes themes fall back to the ascii marker so a
         ;; structural marker is always present (command reference §8).
         (glyph-theme (if (or (color-theme-p theme) (eq theme :attributes))
                          :ascii theme))
         (params (decoration-for situation glyph-theme config)))
    (if (and params (= (length params) 1))
        (glyph->string (first params))
        "")))
