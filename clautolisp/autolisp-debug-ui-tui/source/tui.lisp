(in-package #:clautolisp.ui.tui)

;;;; The screen protocol (spec §19.3). Coordinates are 0-based (row, col).
;;;; ATTR is a keyword the backend interprets — :normal, :bold, or a colour
;;;; name (:blue :red :yellow :green :cyan …). A key returned by
;;;; TUI-READ-KEY is either a character or a keyword: :up :down :left
;;;; :right :enter :backspace :escape :resize :eof.

(defgeneric tui-start (screen)
  (:documentation "Enter full-screen mode (no-op for the mock).")
  (:method (screen) (declare (ignore screen)) nil))
(defgeneric tui-stop (screen)
  (:method (screen) (declare (ignore screen)) nil))
(defgeneric tui-size (screen)
  (:documentation "Return (values rows cols)."))
(defgeneric tui-clear (screen))
(defgeneric tui-put (screen row col string &key attr)
  (:documentation "Write STRING at (ROW, COL), clipped to the screen."))
(defgeneric tui-refresh (screen)
  (:method (screen) (declare (ignore screen)) nil))
(defgeneric tui-read-key (screen)
  (:documentation "Read one key; return a character or a key keyword."))

(defun key-char-p (key char)
  "True iff KEY is the character CHAR (case-insensitive)."
  (and (characterp key) (char-equal key char)))

;;;; --- panes and layout ----------------------------------------------

(defstruct pane
  (title "" :type string)
  (top 0 :type fixnum)
  (left 0 :type fixnum)
  (height 0 :type fixnum)
  (width 0 :type fixnum))

(defun pane-interior-height (pane) (max 0 (- (pane-height pane) 2)))
(defun pane-interior-width (pane) (max 0 (- (pane-width pane) 2)))

(defun draw-box (screen pane &key active)
  "Draw PANE's border and title. ACTIVE panes get a bold title."
  (let* ((top (pane-top pane)) (left (pane-left pane))
         (h (pane-height pane)) (w (pane-width pane))
         (right (+ left w -1)) (bottom (+ top h -1)))
    (when (or (< h 2) (< w 2)) (return-from draw-box))
    (tui-put screen top left
             (format nil "+~A+" (make-string (- w 2) :initial-element #\-)))
    (tui-put screen bottom left
             (format nil "+~A+" (make-string (- w 2) :initial-element #\-)))
    (loop for r from (1+ top) below bottom
          do (tui-put screen r left "|")
             (tui-put screen r right "|"))
    (let ((title (pane-title pane)))
      (when (plusp (length title))
        (tui-put screen top (+ left 1)
                 (truncate-string (format nil " ~A " title) (- w 2))
                 :attr (if active :bold :normal))))))

(defun pane-put-line (screen pane line text &key attr)
  "Write TEXT on interior row LINE (0-based) of PANE, clipped to width."
  (when (< -1 line (pane-interior-height pane))
    (tui-put screen (+ (pane-top pane) 1 line) (+ (pane-left pane) 1)
             (pad-string (truncate-string text (pane-interior-width pane))
                         (pane-interior-width pane))
             :attr attr)))

(defun pane-clear (screen pane)
  "Blank PANE's interior."
  (dotimes (line (pane-interior-height pane))
    (pane-put-line screen pane line "")))

(defun truncate-string (string width)
  (cond ((<= width 0) "")
        ((<= (length string) width) string)
        ((<= width 1) (subseq string 0 width))
        (t (concatenate 'string (subseq string 0 (1- width)) "…"))))

(defun pad-string (string width)
  (if (>= (length string) width)
      string
      (concatenate 'string string (make-string (- width (length string))
                                                :initial-element #\Space))))

(defun four-pane-layout (rows cols)
  "Spec §19 layout: stack (top-left), source (top-right), interactor
(bottom-left), repl (bottom-right). Returns the four panes in that order."
  (let* ((split-col (floor cols 2))
         (split-row (floor rows 2))
         (left-w split-col)
         (right-w (- cols split-col))
         (top-h split-row)
         (bottom-h (- rows split-row)))
    (list (make-pane :title "stack"      :top 0         :left 0         :height top-h    :width left-w)
          (make-pane :title "source"     :top 0         :left split-col :height top-h    :width right-w)
          (make-pane :title "interactor" :top split-row :left 0         :height bottom-h :width left-w)
          (make-pane :title "repl"       :top split-row :left split-col :height bottom-h :width right-w))))

;;;; --- mock backend (no curses; for tests) ---------------------------

(defclass mock-screen ()
  ((rows :initarg :rows :initform 24 :reader mock-screen-rows)
   (cols :initarg :cols :initform 80 :reader mock-screen-cols)
   (grid :accessor mock-grid)
   (attrs :accessor mock-attrs)
   (keys :initarg :keys :initform '() :accessor mock-keys)))

(defmethod initialize-instance :after ((screen mock-screen) &key)
  (reset-grid screen))

(defun reset-grid (screen)
  (let ((rows (mock-screen-rows screen)) (cols (mock-screen-cols screen)))
    (setf (mock-grid screen) (make-array (list rows cols)
                                         :initial-element #\Space)
          (mock-attrs screen) (make-array (list rows cols)
                                          :initial-element :normal))))

(defun make-mock-screen (&key (rows 24) (cols 80) keys)
  (make-instance 'mock-screen :rows rows :cols cols :keys keys))

(defmethod tui-size ((screen mock-screen))
  (values (mock-screen-rows screen) (mock-screen-cols screen)))

(defmethod tui-clear ((screen mock-screen))
  (reset-grid screen))

(defmethod tui-put ((screen mock-screen) row col string &key (attr :normal))
  (when (< -1 row (mock-screen-rows screen))
    (loop for i from 0 below (length string)
          for c from col
          while (< c (mock-screen-cols screen))
          when (>= c 0)
            do (setf (aref (mock-grid screen) row c) (char string i)
                     (aref (mock-attrs screen) row c) attr))))

(defmethod tui-read-key ((screen mock-screen))
  (if (mock-keys screen) (pop (mock-keys screen)) :eof))

(defun mock-feed-keys (screen keys)
  "Append KEYS (a list) to the mock's scripted key queue."
  (setf (mock-keys screen) (append (mock-keys screen) keys)))

(defun mock-grid-lines (screen)
  "Return the grid as a list of row strings (trailing blanks trimmed)."
  (loop for r from 0 below (mock-screen-rows screen)
        collect (string-right-trim
                 " "
                 (coerce (loop for c from 0 below (mock-screen-cols screen)
                               collect (aref (mock-grid screen) r c))
                         'string))))

(defun mock-attr-at (screen row col)
  (aref (mock-attrs screen) row col))

(defun mock-find-line (screen substring)
  "Return the row index of the first grid line containing SUBSTRING, or NIL."
  (loop for line in (mock-grid-lines screen)
        for r from 0
        when (search substring line) do (return r)))
