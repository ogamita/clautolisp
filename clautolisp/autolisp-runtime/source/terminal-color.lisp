(in-package #:clautolisp.autolisp-runtime)

;;; Implementation-specific isatty(3) glue for OUTPUT-STREAM-IS-TTY-P.
;;; SB-POSIX exposes neither isatty nor a portable fd-stream accessor
;;; in the version range this project targets, so we go straight to
;;; sb-alien and bind the libc symbol ourselves. CCL exports an
;;; internal ISATTY in the CCL package which we resolve lazily via
;;; FIND-SYMBOL so a build on a future CCL that has dropped or
;;; renamed it degrades gracefully (the tty check returns NIL, i.e.
;;; colour is conservatively disabled, instead of failing to load).
#+sbcl (eval-when (:compile-toplevel :load-toplevel :execute)
         (sb-alien:define-alien-routine ("isatty" %sbcl-isatty)
             sb-alien:int
           (fd sb-alien:int)))

;;;; Terminal colour-output policy for AutoLISP value printers.
;;;;
;;;; *COLOR-OUTPUT* is the single switch the PRINT-OBJECT method on
;;;; AUTOLISP-SYMBOL (in model.lisp) consults: when it is NIL the
;;;; method writes the bare symbol name, when it is a keyword it
;;;; wraps the name in an ANSI SGR sequence selecting that colour.
;;;;
;;;; The CLI sets the parameter once at startup via RESOLVE-COLOR-POLICY,
;;;; which combines the user-visible --no-color flag, the $NO_COLOR
;;;; environment variable (https://no-color.org), an isatty check on
;;;; the output stream, and a best-effort luminance probe of the
;;;; controlling terminal. Library callers never flip it; production
;;;; code outside the CLI sees the default NIL and the printer behaves
;;;; exactly as before.
;;;;
;;;; The luminance probe cascades: explicit override
;;;; ($CLAUTOLISP_BACKGROUND), then $COLORFGBG (rxvt convention), then
;;;; an OSC 11 query of /dev/tty with tmux / screen passthrough. The
;;;; query is spawned through /bin/sh so each platform's stty / dd
;;;; handles the raw-mode dance — saves us from per-implementation
;;;; termios bindings, and the script's whole pipeline runs only once
;;;; per CLI invocation.

;;; --- ANSI helpers ---------------------------------------------------

(defparameter *color-output* nil
  "Active colour-output policy for AutoLISP PRINT-OBJECT methods.
NIL disables colour entirely. A non-NIL value is a colour spec, in
one of two shapes:

  - A bare keyword (e.g. :YELLOW, :BLUE) — foreground only. This is
    what the luminance-based default uses; kept as a first-class
    shape for backwards compatibility and ergonomic ergonomics in
    let-binders.
  - A list (FOREGROUND BACKGROUND) — both axes. Either element may
    be NIL to leave that SGR axis bare. This is the shape the
    $CLAUTOLISP_SYMBOL_{FOREGROUND,BACKGROUND} env vars produce.

The CLI sets this once via RESOLVE-COLOR-POLICY. Code outside the
CLI must not bind it for incidental output — the printer contract
is observed by every error message, trace line, and REPL display,
so a stray binding will leak through the entire pipeline.")

(defparameter *ansi-foreground-table*
  '((:black          . 30) (:red            . 31) (:green          . 32)
    (:yellow         . 33) (:blue           . 34) (:magenta        . 35)
    (:cyan           . 36) (:white          . 37)
    (:bright-black   . 90) (:bright-red     . 91) (:bright-green   . 92)
    (:bright-yellow  . 93) (:bright-blue    . 94) (:bright-magenta . 95)
    (:bright-cyan    . 96) (:bright-white   . 97)
    ;; Common synonyms — terminal users write `grey' / `gray' for
    ;; the bright-black palette slot.
    (:grey           . 90) (:gray           . 90))
  "Mapping from colour keyword to ANSI SGR foreground parameter. The
bright variants follow the de-facto 90..97 / 100..107 range, present
on every terminal we target. Extend cautiously; an unknown keyword
silently leaves the foreground SGR axis bare.")

(defparameter *ansi-background-table*
  '((:black          . 40) (:red            . 41) (:green          . 42)
    (:yellow         . 43) (:blue           . 44) (:magenta        . 45)
    (:cyan           . 46) (:white          . 47)
    (:bright-black   . 100) (:bright-red    . 101) (:bright-green  . 102)
    (:bright-yellow  . 103) (:bright-blue   . 104) (:bright-magenta . 105)
    (:bright-cyan    . 106) (:bright-white  . 107)
    (:grey           . 100) (:gray          . 100))
  "Background-colour sibling of *ANSI-FOREGROUND-TABLE*. Indexed by
the same keywords so a user writing both `CLAUTOLISP_SYMBOL_FOREGROUND
=white' and `CLAUTOLISP_SYMBOL_BACKGROUND=white' gets the consistent
pair without having to know the SGR number ranges.")

(defun %sgr-foreground-code (colour)
  (cdr (assoc colour *ansi-foreground-table*)))

(defun %sgr-background-code (colour)
  (cdr (assoc colour *ansi-background-table*)))

(defun %normalize-colour-spec (spec)
  "Return SPEC as a (FOREGROUND BACKGROUND) list. NIL → NIL; a bare
keyword → (KEYWORD NIL); a list → its first two elements. Anything
else returns NIL (the caller treats this as 'no colour'), so a
malformed *COLOR-OUTPUT* binding can never crash PRINT-OBJECT."
  (cond
    ((null spec) nil)
    ((keywordp spec) (list spec nil))
    ((consp spec) (list (first spec) (second spec)))
    (t nil)))

(defun %ansi-sgr-parts (spec)
  "Return the list of SGR numeric parameters implied by SPEC, with
unrecognised colours dropped silently."
  (let* ((pair (%normalize-colour-spec spec))
         (fg (and pair (%sgr-foreground-code (first pair))))
         (bg (and pair (%sgr-background-code (second pair)))))
    (remove nil (list fg bg))))

(defun ansi-colorize (string spec)
  "Wrap STRING in an ANSI SGR sequence selecting the attributes named
by SPEC, with a trailing reset (\\e[0m). SPEC is NIL (no colour), a
bare keyword (foreground only — backwards-compatible shape), or a
list (FOREGROUND BACKGROUND) where either element may be NIL.

When SPEC names nothing recognisable — NIL, an unknown keyword, or
a pair of unknowns — STRING is returned unchanged. The reset is
emitted whenever any attribute fires, so downstream output never
inherits an accidental colour."
  (let ((parts (%ansi-sgr-parts spec)))
    (cond
      ((null parts) string)
      (t (concatenate 'string
                      (format nil "~C[~{~A~^;~}m" #\Esc parts)
                      string
                      (format nil "~C[0m" #\Esc))))))

(defun write-ansi-colorized (string spec stream)
  "Stream-oriented sibling of ANSI-COLORIZE. Writes STRING to STREAM
surrounded by the SGR sequence implied by SPEC, falling back to a
plain WRITE-STRING when SPEC names nothing recognisable. Avoids the
intermediate-string allocation a PRINT-OBJECT method would otherwise
pay for on every value rendered."
  (let ((parts (%ansi-sgr-parts spec)))
    (cond
      ((null parts) (write-string string stream))
      (t (format stream "~C[~{~A~^;~}m~A~C[0m"
                 #\Esc parts string #\Esc)))))

;;; --- Environment-variable probes -----------------------------------

(defun env-no-color-set-p ()
  "True iff $NO_COLOR is set to any non-empty value, per
https://no-color.org. The mere presence of the variable disables
colour; the value content is intentionally ignored so users can
follow the no-color.org convention of simply `export NO_COLOR=1`."
  (let ((v (uiop:getenv "NO_COLOR")))
    (and v (plusp (length v)))))

(defun env-clautolisp-background ()
  "Explicit user override: $CLAUTOLISP_BACKGROUND=dark|light short-
circuits the probe cascade and forces the result. Returns :DARK,
:LIGHT, or NIL when the variable is unset / unrecognised."
  (let ((v (uiop:getenv "CLAUTOLISP_BACKGROUND")))
    (cond
      ((null v) nil)
      ((string-equal v "dark")  :dark)
      ((string-equal v "light") :light)
      (t nil))))

(defun parse-colour-name (string)
  "Map a user-supplied colour name (e.g. \"yellow\", \"Bright-Blue\",
\"  GREY  \") to the keyword used as a key in the *ANSI-*-TABLE
alists. Returns NIL when STRING is empty, when it spells one of the
sentinel \"clear this axis\" tokens (\"default\", \"none\", \"off\"),
or when no characters remain after trimming. Unknown names intern
as upper-cased keywords that the SGR lookup tables will simply not
match — the colorize helpers drop the unrecognised axis silently."
  (when (and string (plusp (length string)))
    (let ((trimmed (string-trim '(#\Space #\Tab) string)))
      (cond
        ((zerop (length trimmed)) nil)
        ((or (string-equal trimmed "default")
             (string-equal trimmed "none")
             (string-equal trimmed "off"))
         nil)
        (t (intern (string-upcase trimmed) :keyword))))))

(defun env-symbol-foreground ()
  "Parse $CLAUTOLISP_SYMBOL_FOREGROUND. Returns a colour keyword (a
key into *ANSI-FOREGROUND-TABLE*) or NIL when unset / blank / set to
a sentinel. See PARSE-COLOUR-NAME for the accepted spellings."
  (parse-colour-name (uiop:getenv "CLAUTOLISP_SYMBOL_FOREGROUND")))

(defun env-symbol-background ()
  "Parse $CLAUTOLISP_SYMBOL_BACKGROUND — sibling of
ENV-SYMBOL-FOREGROUND, indexed against *ANSI-BACKGROUND-TABLE*."
  (parse-colour-name (uiop:getenv "CLAUTOLISP_SYMBOL_BACKGROUND")))

(defun env-symbol-colour-spec ()
  "Return a (FOREGROUND BACKGROUND) list when either
$CLAUTOLISP_SYMBOL_FOREGROUND or $CLAUTOLISP_SYMBOL_BACKGROUND
resolves to a colour keyword; either slot may be NIL when only its
sibling is set. Returns NIL when neither env var is meaningfully
set, so RESOLVE-COLOR-POLICY can fall through to the luminance
probe (or the dark default) without further branching.

The pair returned here is fed directly into *COLOR-OUTPUT*, which
ANSI-COLORIZE understands in both keyword and (FG BG) shapes."
  (let ((fg (env-symbol-foreground))
        (bg (env-symbol-background)))
    (when (or fg bg)
      (list fg bg))))

(defun parse-colorfgbg ()
  "Parse $COLORFGBG (rxvt-style \"fg;bg\" — e.g. \"15;0\"). The second
number is the ANSI palette index for the background. Indices 0..6
plus 8 (bright black) indicate a dark background; everything else
indicates light. Returns :DARK / :LIGHT / NIL."
  (let ((v (uiop:getenv "COLORFGBG")))
    (when (and v (plusp (length v)))
      ;; Some terminals add a third field (default-bg index) —
      ;; FROM-END keeps us picking the background, not the default.
      (let ((semi (position #\; v :from-end nil)))
        (when semi
          (let* ((tail (subseq v (1+ semi)))
                 (semi2 (position #\; tail))
                 (bg-str (if semi2 (subseq tail 0 semi2) tail))
                 (bg (parse-integer bg-str :junk-allowed t)))
            (when bg
              (if (or (and (>= bg 0) (<= bg 6)) (= bg 8))
                  :dark
                  :light))))))))

;;; --- OSC 11 probe via shell helper ---------------------------------
;;;
;;; Doing the raw-mode dance in pure Lisp would mean reaching into
;;; sb-posix / ccl::syscall for tcgetattr / tcsetattr and a select(2)
;;; with timeout — three per-implementation surfaces that all have to
;;; agree on which constants are exported. A 50-line shell pipeline
;;; spawned once at CLI startup is portable, gracefully degrades when
;;; /dev/tty is missing (subprocess / cron / CI), and never freezes
;;; the parent because `stty time' caps the read at ~tenths-of-second.

(defun parse-hex-quietly (s)
  (when (and s (plusp (length s)))
    (handler-case (parse-integer s :radix 16 :junk-allowed t)
      (error () nil))))

(defun parse-osc11-response (s)
  "Parse a terminal's OSC 11 reply (\"\\e]11;rgb:RRRR/GGGG/BBBB\\e\\\"
or the BEL-terminated variant) into a list of three 16-bit unsigned
integers, or NIL on a malformed response. Tolerates leading garbage
and stray whitespace because dd can over-read the response window."
  (when (and s (plusp (length s)))
    (let ((pos (search "rgb:" s)))
      (when pos
        (let* ((tail (subseq s (+ pos 4)))
               (parts (uiop:split-string
                       tail
                       :separator (list #\/ #\Esc #\Bel #\\ #\Newline #\Space))))
          (when (>= (length parts) 3)
            (let ((r (parse-hex-quietly (nth 0 parts)))
                  (g (parse-hex-quietly (nth 1 parts)))
                  (b (parse-hex-quietly (nth 2 parts))))
              (when (and r g b)
                (list r g b)))))))))

(defun luminance-of-rgb (rgb)
  "Compute Rec-601 relative luminance (0.0..1.0) for an (R G B) list
of 16-bit values. Returns NIL when RGB is malformed. The 0.5
threshold callers use for the dark/light cut is conventional —
matches Vim's `background' heuristic."
  (when (and (consp rgb) (= 3 (length rgb))
             (every #'integerp rgb))
    (let* ((r (/ (nth 0 rgb) 65535.0))
           (g (/ (nth 1 rgb) 65535.0))
           (b (/ (nth 2 rgb) 65535.0)))
      (+ (* 0.299 r) (* 0.587 g) (* 0.114 b)))))

(defparameter *osc11-tmux-passthrough*
  "\\033Ptmux;\\033\\033]11;?\\033\\033\\\\\\033\\\\"
  "OSC 11 query wrapped in a tmux passthrough envelope. tmux swallows
naked CSI / OSC sequences directed at the underlying terminal unless
they are wrapped in `\\ePtmux;…\\e\\' — see tmux(1) under DCS.")

(defparameter *osc11-screen-passthrough*
  "\\033P\\033]11;?\\033\\033\\\\\\033\\\\"
  "OSC 11 query wrapped in a GNU screen passthrough envelope (DCS …
ST). Same idea as tmux but with screen's narrower wrapper.")

(defparameter *osc11-bare*
  "\\033]11;?\\033\\\\"
  "Plain OSC 11 query — `\\e]11;?\\e\\'. The terminator is ST
(`\\e\\') rather than BEL (`\\a') because BEL has historical
side effects in some terminals; ST is the standards form.")

(defun %select-osc11-query ()
  (cond
    ((let ((v (uiop:getenv "TMUX")))
       (and v (plusp (length v))))
     *osc11-tmux-passthrough*)
    ((let ((v (uiop:getenv "STY")))
       (and v (plusp (length v))))
     *osc11-screen-passthrough*)
    (t *osc11-bare*)))

(defun %build-osc11-probe-script (query-printf tenths)
  "Compose the /bin/sh pipeline that probes the terminal. The script
saves the current terminal state, switches to non-canonical mode with
a (~TENTHS * 0.1 s) read timeout, emits the OSC 11 query on the tty,
reads the response off the tty, restores the original state, and
echoes the raw response on its own stdout. Failure modes (no
controlling tty, missing stty, missing dd) abort with a non-zero
status which the caller maps to NIL."
  (format nil
          "exec 3</dev/tty 2>/dev/null || exit 1~%~
           exec 4>/dev/tty 2>/dev/null || exit 1~%~
           old=$(stty -g <&3 2>/dev/null) || exit 1~%~
           trap 'stty \"$old\" <&3 2>/dev/null' EXIT~%~
           stty -icanon -echo min 0 time ~D <&3 2>/dev/null || exit 1~%~
           printf '~A' >&4~%~
           dd bs=64 count=1 <&3 2>/dev/null~%"
          tenths query-printf))

(defun probe-terminal-background-via-osc11 (&key (timeout-millis 150))
  "Send an OSC 11 query to the controlling terminal and parse the rgb
response. Spawns /bin/sh once with a short timeout so the parent never
blocks on a non-responding terminal. Returns the parsed (R G B) list
of 16-bit unsigned integers, or NIL on any failure (no tty, parse
error, timeout, missing utilities, exception, …).

Honours $TMUX / $STY by wrapping the query in the matching
multiplexer passthrough — without it, the multiplexer eats the
OSC sequence before the underlying terminal sees it."
  (handler-case
      (let* ((tenths (max 1 (round (/ timeout-millis 100))))
             (query  (%select-osc11-query))
             (script (%build-osc11-probe-script query tenths))
             (stdout (with-output-to-string (out)
                       (uiop:run-program
                        (list "/bin/sh" "-c" script)
                        :output out
                        :error-output nil
                        :ignore-error-status t))))
        (parse-osc11-response stdout))
    (error () nil)))

;;; --- top-level luminance probe and CLI policy ----------------------

(defun terminal-background-luminance (&key (probe-osc11-p t))
  "Best-effort detection of the controlling terminal's background.
Returns :DARK, :LIGHT, or NIL when nothing yields an answer.

Cascade (cheap first, so most calls return without spawning a
subprocess):
  1. $CLAUTOLISP_BACKGROUND=dark|light — explicit user override.
  2. $COLORFGBG — present on rxvt, urxvt, mintty, mlterm, others.
  3. OSC 11 probe via /bin/sh — modern terminals (xterm, iTerm2,
     Alacritty, Kitty, recent GNOME Terminal, WezTerm). Skipped when
     PROBE-OSC11-P is NIL so unit tests can pin the cheap branches."
  (or (env-clautolisp-background)
      (parse-colorfgbg)
      (when probe-osc11-p
        (let ((rgb (probe-terminal-background-via-osc11)))
          (when rgb
            (let ((l (luminance-of-rgb rgb)))
              (cond
                ((null l)   nil)
                ((> l 0.5)  :light)
                (t          :dark))))))))

(defun output-stream-is-tty-p (stream)
  "Best-effort isatty check on STREAM. Implementation-specific because
INTERACTIVE-STREAM-P (the only CL standard probe) is not consistently
wired to the underlying file descriptor — SBCL returns NIL for a
synonym stream wrapping a tty fd-stream, for example. Returns T / NIL;
never signals, so a hostile stream simply yields NIL (colour off)."
  (declare (ignorable stream))
  (or #+sbcl
      (handler-case
          (let ((fd (sb-sys:fd-stream-fd
                     (if (typep stream 'synonym-stream)
                         (symbol-value (synonym-stream-symbol stream))
                         stream))))
            (and fd (not (zerop (%sbcl-isatty fd)))))
        (error () nil))
      #+ccl
      (handler-case
          (let ((fd (ccl::stream-device stream :output))
                (isatty-fn (find-symbol "ISATTY" '#:ccl)))
            (and fd isatty-fn (funcall isatty-fn fd)))
        (error () nil))
      ;; Last-resort fallback for non-SBCL / non-CCL hosts: the CL
      ;; standard INTERACTIVE-STREAM-P. Useful precisely when the
      ;; implementation-specific branches above didn't fire.
      (handler-case (interactive-stream-p stream) (error () nil))))

(defun %probe-osc11-opt-in-p ()
  "True iff the user has opted into the active OSC 11 probe via
$CLAUTOLISP_PROBE_OSC11. The probe spawns /bin/sh + stty + dd
against /dev/tty; on platforms / process-group configurations where
the child receives SIGTTOU and stops, the parent's WAIT blocks
indefinitely (observed first on macOS arm64 when the child shell
landed in a background pgrp). Until the subprocess-termination
story is bullet-proof we leave the active probe off by default and
let users explicitly enable it — the cheap rungs of the cascade
($CLAUTOLISP_BACKGROUND, $COLORFGBG) still run."
  (let ((v (uiop:getenv "CLAUTOLISP_PROBE_OSC11")))
    (and v (plusp (length v)))))

(defun resolve-color-policy
    (&key
       (no-color-flag nil)
       (stream *standard-output*)
       (probe-luminance-p t)
       (probe-osc11-p (%probe-osc11-opt-in-p)))
  "Compute the value the CLI should install into *COLOR-OUTPUT* for
this run. Returns NIL (no colour) or a colour keyword — :YELLOW for
a dark background, :BLUE for a light one.

Colour is disabled when:
  - NO-COLOR-FLAG is true (the --no-color CLI flag), OR
  - $NO_COLOR is set (https://no-color.org convention), OR
  - STREAM is not a tty (output is being captured to a file / pipe).

Otherwise the luminance probe (cascade documented in
TERMINAL-BACKGROUND-LUMINANCE) picks a contrasting accent: yellow on
dark, blue on light, defaulting to yellow when the cascade is
inconclusive (this matches the convention most CLI tools follow on
hosts where they cannot detect the background).

PROBE-OSC11-P defaults to NIL unless $CLAUTOLISP_PROBE_OSC11 is set
(see %PROBE-OSC11-OPT-IN-P for the rationale). When NIL, the cascade
runs only the cheap env-var rungs ($CLAUTOLISP_BACKGROUND,
$COLORFGBG); when one of those yields a definite value the colour
is set accordingly, otherwise we default to :YELLOW (dark).

Resolution order, once the tty / env-disable gates have been
passed:

  1. $CLAUTOLISP_SYMBOL_FOREGROUND / $CLAUTOLISP_SYMBOL_BACKGROUND
     — explicit per-axis user choice. Either or both may be set;
     unspecified axes simply stay bare in the rendered SGR.
     This rung wins over the luminance probe so a user who wants
     a specific look gets it deterministically.
  2. Luminance probe (only when PROBE-LUMINANCE-P is true). :LIGHT
     ⇒ :BLUE foreground, anything else ⇒ :YELLOW foreground.
  3. Fallback :YELLOW (dark default)."
  (cond
    (no-color-flag                          nil)
    ((env-no-color-set-p)                   nil)
    ((not (output-stream-is-tty-p stream))  nil)
    (t (or (env-symbol-colour-spec)
           (when probe-luminance-p
             (let ((luminance (terminal-background-luminance
                               :probe-osc11-p probe-osc11-p)))
               (case luminance
                 (:light :blue)
                 (otherwise :yellow))))
           :yellow))))
