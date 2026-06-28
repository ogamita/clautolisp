;;;; FiveAM tests for the aldo theme / decorations renderer
;;;; (clautolisp.debug.ui decorations, command reference §8).

(in-package #:clautolisp.ui.dumb.tests)

(in-suite dumb-ui-suite)

(defun config-with (&rest pairs)
  "A fresh default config with PAIRS (key value …) overridden."
  (let ((c (copy-tree clautolisp.debug.ui:*default-aldo-configuration*)))
    (loop :for (k v) :on pairs :by #'cddr :do (clautolisp.debug.ui:config-set k v c))
    c))

(test deco-glyph->string
  (is (string= "x" (clautolisp.debug.ui:glyph->string "x")))
  (is (string= ">" (clautolisp.debug.ui:glyph->string '(62))))    ; #\>
  (is (string= (string (code-char 9205)) (clautolisp.debug.ui:glyph->string '(9205))))
  (is (string= "ab" (clautolisp.debug.ui:glyph->string '(97 98))))
  (is (string= "" (clautolisp.debug.ui:glyph->string nil))))

(test deco-lookup
  (let ((c (config-with :theme :unicode)))
    ;; current-pp under unicode is a prefix (a code-point list)
    (is (equal '((9205)) (clautolisp.debug.ui:decoration-for :current-pp :unicode c)))
    (is (equal '(">") (clautolisp.debug.ui:decoration-for :current-pp :ascii c)))
    ;; selection under unicode is an open/close pair
    (is (equal '((12304) (12305)) (clautolisp.debug.ui:decoration-for :selection :unicode c)))
    ;; absent (situation, theme) => nil
    (is (null (clautolisp.debug.ui:decoration-for :current-pp :green-on-black c)))))

(test deco-apply-glyph-themes
  ;; unicode prefix
  (let ((c (config-with :theme :unicode)))
    (is (string= (concatenate 'string (string (code-char 9205)) "form")
                 (clautolisp.debug.ui:apply-decoration "form" :current-pp c)))
    ;; selection wraps with the open/close pair 【…】
    (is (string= (concatenate 'string (string (code-char 12304)) "x"
                              (string (code-char 12305)))
                 (clautolisp.debug.ui:apply-decoration "x" :selection c))))
  ;; ascii prefix / pair
  (let ((c (config-with :theme :ascii)))
    (is (string= ">form" (clautolisp.debug.ui:apply-decoration "form" :current-pp c)))
    (is (string= "[x]" (clautolisp.debug.ui:apply-decoration "x" :selection c))))
  ;; no decoration for the (situation, theme) => unchanged
  (is (string= "form"
               (clautolisp.debug.ui:apply-decoration
                "form" :current-pp (config-with :theme :green-on-black)))))

(test deco-apply-colour-and-attributes
  (let* ((esc (string (code-char 27)))
         ;; add a colour entry and an attributes entry for current-pp
         (decos (append (clautolisp.debug.ui:config-get
                         :decorations clautolisp.debug.ui:*default-aldo-configuration*)
                        '((:current-pp :white-on-black :red :black)
                          (:current-pp :attributes :bold :invert))))
         (c1 (config-with :theme :white-on-black :decorations decos))
         (c2 (config-with :theme :attributes :decorations decos)))
    ;; colour is gated on the runtime colour policy — enable it for the SGR path
    (let ((clautolisp.autolisp-runtime:*color-output* :yellow))
      (let ((out (clautolisp.debug.ui:apply-decoration "x" :current-pp c1)))
        (is (search (concatenate 'string esc "[") out))    ; has an SGR sequence
        (is (search "31" out))                              ; fg red = 30+1
        (is (search "40" out))                              ; bg black = 40+0
        (is (search (concatenate 'string esc "[0m") out)))  ; reset
      (let ((out (clautolisp.debug.ui:apply-decoration "x" :current-pp c2)))
        (is (search "1" out))    ; bold
        (is (search "7" out))))  ; invert
    ;; sgr-wrap with nothing requested returns the string unchanged
    (is (string= "x" (clautolisp.debug.ui:sgr-wrap "x")))))

(test deco-colour-degrades-without-colour-output
  ;; with colour disabled (NO_COLOR / pipe / --no-color → *color-output* nil), a
  ;; colour or attributes theme emits NO ANSI and falls back to the ASCII marker
  ;; so structure stays visible (command reference §8).
  (let* ((esc (string (code-char 27)))
         (decos (append (clautolisp.debug.ui:config-get
                         :decorations clautolisp.debug.ui:*default-aldo-configuration*)
                        '((:current-pp :white-on-black :red :black))))
         (c1 (config-with :theme :white-on-black :decorations decos))
         (clautolisp.autolisp-runtime:*color-output* nil))
    (let ((out (clautolisp.debug.ui:apply-decoration "x" :current-pp c1)))
      (is (null (search esc out)))            ; no ANSI escape at all
      (is (string= ">x" out)))))              ; degraded to the ascii marker

(test deco-marker-always-present
  ;; under a colour theme, situation-prefix still yields the ascii marker, so a
  ;; structural marker is present even when colour is unavailable
  (is (string= ">" (clautolisp.debug.ui:situation-prefix
                    :current-pp (config-with :theme :white-on-black))))
  (is (string= ">" (clautolisp.debug.ui:situation-prefix
                    :current-pp (config-with :theme :attributes)))))
