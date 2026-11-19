;;;; Tests for the cadgui multi-document workspace (multidoc.lisp) -- slice 1 of
;;;; the cooperative-scheduler integration. Two documents' getpoint-driven
;;;; evaluations INTERLEAVE through the single-runner scheduler, each reading
;;;; only its own per-document input channel. Deterministic: the test supplies
;;;; the points the Qt canvas will later supply by clicks.

(in-package #:clautolisp.cadgui.tests)

(in-suite cadgui-suite)

(test cadgui-workspace-opens-documents
  (let ((ws (cadgui-make-workspace)))
    (is (null (cadgui-workspace-docs ws)))
    (cadgui-open-document ws :a (lambda (h) (declare (ignore h))))
    (cadgui-open-document ws :b (lambda (h) (declare (ignore h))))
    (is (= 2 (length (cadgui-workspace-docs ws))))
    (cadgui-workspace-shutdown ws)))

(test cadgui-two-documents-interleave-getpoint-via-the-scheduler
  ;; A and B each read two points. They run on their own context threads and
  ;; park through the real cador bridge; the driver serves each park from THAT
  ;; document's channel. The scheduler asserts at-most-one-running internally,
  ;; so completing without error IS the single-runner proof.
  (let* ((ws (cadgui-make-workspace))
         (a '()) (b '())
         (da (cadgui-open-document ws :a
               (lambda (h)
                 (push (host-getpoint h nil) a)
                 (push (host-getpoint h nil) a))))
         (db (cadgui-open-document ws :b
               (lambda (h)
                 (push (host-getpoint h nil) b)
                 (push (host-getpoint h nil) b)))))
    (unwind-protect
         (let ((na (cadgui-workspace-start ws da))   ; A parks at getpoint #1
               (nb (cadgui-workspace-start ws db)))   ; B parks at getpoint #1
           (is (eq :park (first na)))
           (is (eq :park (first nb)))
           ;; interleave A, B, A, B through the single runner
           (cadgui-doc-supply-point da 1 1)
           (setf na (cadgui-workspace-serve ws na))   ; A -> getpoint #2 park
           (cadgui-doc-supply-point db 10 10)
           (setf nb (cadgui-workspace-serve ws nb))   ; B -> getpoint #2 park
           (is (eq :park (first na)))
           (is (eq :park (first nb)))
           (cadgui-doc-supply-point da 2 2)
           (is (eq :done (first (cadgui-workspace-serve ws na 3))))  ; A finishes
           (cadgui-doc-supply-point db 20 20)
           (is (eq :done (first (cadgui-workspace-serve ws nb 3))))  ; B finishes
           ;; each document read ONLY its own points, in order (no cross-bleed)
           (let ((ar (reverse a)) (br (reverse b)))
             (is (= 2 (length ar)))
             (is (= 2 (length br)))
             (is (= 1.0 (first (first ar))))   (is (= 1.0 (second (first ar))))
             (is (= 2.0 (first (second ar))))  (is (= 2.0 (second (second ar))))
             (is (= 10.0 (first (first br))))  (is (= 10.0 (second (first br))))
             (is (= 20.0 (first (second br)))) (is (= 20.0 (second (second br))))))
      (cadgui-workspace-shutdown ws))))

(test cadgui-workspace-run-drives-both-documents-each-drawing-in-its-own-model
  ;; The unattended batch driver: pre-supply each document's corner points, run
  ;; the workspace to quiescence, and confirm each document drew its OWN line in
  ;; its OWN model (per-document model isolation, no cross-bleed).
  (let* ((ws (cadgui-make-workspace))
         (line-thunk
           (lambda (h)
             (let ((p1 (host-getpoint h nil)) (p2 (host-getpoint h nil)))
               (clautolisp.autolisp-host:host-entmake
                h (list (cons 0 "LINE")
                        (cons 10 (list (first p1) (second p1) 0d0))
                        (cons 11 (list (first p2) (second p2) 0d0)))))))
         (da (cadgui-open-document ws :a line-thunk))
         (db (cadgui-open-document ws :b line-thunk)))
    (unwind-protect
         (progn
           (cadgui-doc-supply-point da 0 0) (cadgui-doc-supply-point da 5 5)
           (cadgui-doc-supply-point db 0 0) (cadgui-doc-supply-point db 9 9)
           (let ((served (cadgui-workspace-run ws)))
             (is (= 4 served)))              ; 2 getpoints x 2 documents
           (is (cadgui-workspace-all-finished-p ws))   ; the shell's quiescence poll
           ;; each document's own display list holds exactly its own line
           (let ((sa (cadgui-doc-display-list da))
                 (sb (cadgui-doc-display-list db)))
             (is (= 1 (length sa)))
             (is (= 1 (length sb)))
             ;; A's line ends at (5,5); B's at (9,9) -- the points did not bleed
             (is (equal '(0d0 0d0 5d0 5d0) (sixth (first sa))))
             (is (equal '(0d0 0d0 9d0 9d0) (sixth (first sb))))))
      (cadgui-workspace-shutdown ws))))

(test cadgui-multiplexing-driver-resumes-whichever-document-got-input
  ;; The LIVE driver's defining property: input can arrive OUT OF ORDER (the
  ;; user clicks in any window). Document A parks first, but B is fed first --
  ;; the driver resumes B, not A. The batch driver (serve in park order) would
  ;; block on A; this one multiplexes through one wait point.
  (let* ((ws (cadgui-make-workspace))
         (line-thunk
           (lambda (h)
             (let ((p1 (host-getpoint h nil)) (p2 (host-getpoint h nil)))
               (clautolisp.autolisp-host:host-entmake
                h (list (cons 0 "LINE")
                        (cons 10 (list (first p1) (second p1) 0d0))
                        (cons 11 (list (first p2) (second p2) 0d0)))))))
         (da (cadgui-open-document ws :a line-thunk))
         (db (cadgui-open-document ws :b line-thunk)))
    (unwind-protect
         (progn
           ;; launch both; each parks at getpoint #1 (A first, then B)
           (cadgui-workspace-launch ws da)
           (is (eq :park (cadgui-workspace-drive-step ws)))   ; A awaiting
           (cadgui-workspace-launch ws db)
           (is (eq :park (cadgui-workspace-drive-step ws)))   ; B awaiting
           ;; FEED B FIRST although A parked first -> the driver resumes B
           (cadgui-doc-feed-point ws db 0 0)
           (is (eq :input (cadgui-workspace-drive-step ws)))  ; resume B
           (is (eq :park (cadgui-workspace-drive-step ws)))   ; B parks at getpoint #2
           (cadgui-doc-feed-point ws da 0 0)
           (is (eq :input (cadgui-workspace-drive-step ws)))  ; resume A
           (is (eq :park (cadgui-workspace-drive-step ws)))   ; A parks at getpoint #2
           (cadgui-doc-feed-point ws db 9 9)
           (is (eq :input (cadgui-workspace-drive-step ws)))  ; resume B -> entmake
           (is (eq :done (cadgui-workspace-drive-step ws)))   ; B finished
           (cadgui-doc-feed-point ws da 5 5)
           (is (eq :input (cadgui-workspace-drive-step ws)))  ; resume A -> entmake
           (is (eq :done (cadgui-workspace-drive-step ws)))   ; A finished
           ;; each document drew its own line from its own (out-of-order) input
           (let ((sa (cadgui-doc-display-list da))
                 (sb (cadgui-doc-display-list db)))
             (is (= 1 (length sa)))
             (is (= 1 (length sb)))
             (is (equal '(0d0 0d0 5d0 5d0) (sixth (first sa))))
             (is (equal '(0d0 0d0 9d0 9d0) (sixth (first sb))))))
      (cadgui-workspace-shutdown ws))))

(test cadgui-workspace-state-is-structured-introspection
  ;; Action-layer get-state: the live workspace as plain data an AI / test driver
  ;; reads -- the active document, each open document's state, and the invocable
  ;; action ids.
  (let* ((ws (cadgui-make-workspace))
         (da (cadgui-open-document ws :a #'cadgui-document-command-loop))
         (db (cadgui-open-document ws :b #'cadgui-document-command-loop)))
    (unwind-protect
         (progn
           (cadgui-workspace-launch ws da) (cadgui-workspace-drive-step ws)
           (cadgui-workspace-launch ws db) (cadgui-workspace-drive-step ws)
           ;; draw a line in da through a typed command, interleaved with db idle
           (cadgui-doc-feed ws da "(command \"LINE\" (getpoint) (getpoint))")
           (cadgui-workspace-drive-step ws) (cadgui-workspace-drive-step ws)
           (cadgui-doc-feed-point ws da 0 0)
           (cadgui-workspace-drive-step ws) (cadgui-workspace-drive-step ws)
           (cadgui-doc-feed-point ws da 4 4)
           (cadgui-workspace-drive-step ws) (cadgui-workspace-drive-step ws)
           (let ((st (cadgui-workspace-state ws)))
             (is (eq :a (getf st :active)))               ; da ran last -> current
             (is (= 2 (length (getf st :documents))))
             (let ((da-st (find :a (getf st :documents) :key (lambda (p) (getf p :key))))
                   (db-st (find :b (getf st :documents) :key (lambda (p) (getf p :key)))))
               (is (= 1 (getf da-st :entities)))           ; da drew its line
               (is (= 0 (getf db-st :entities)))           ; db still empty
               (is (getf da-st :alive)) (is (getf db-st :alive)))
             (is (member :add-line (getf st :actions)))
             (is (member :eval-command (getf st :actions)))))
      (cadgui-workspace-shutdown ws))))

(test cadgui-structured-interaction-request-answer-and-entity-event-stream
  ;; Action-layer slice C: structured interaction. A scripted driver reads the
  ;; app's REQUEST (which document awaits input), answers it with a point, and
  ;; reads the structured EVENT STREAM -- including the :entity-created event the
  ;; answered command produced -- without screen-scraping. This is the headless
  ;; AI-driver protocol: observe a request, supply a typed answer, read what the
  ;; command did.
  (let* ((ws (cadgui-make-workspace))
         (line-thunk
           (lambda (h)
             (let ((p1 (host-getpoint h nil)) (p2 (host-getpoint h nil)))
               (clautolisp.autolisp-host:host-entmake
                h (list (cons 0 "LINE")
                        (cons 10 (list (first p1) (second p1) 0d0))
                        (cons 11 (list (first p2) (second p2) 0d0)))))))
         (da (cadgui-open-document ws :a line-thunk)))
    (unwind-protect
         (progn
           (cadgui-workspace-launch ws da)
           (is (eq :park (cadgui-workspace-drive-step ws)))   ; da awaits getpoint #1
           ;; the app EMITS a request the driver can read as data
           (is (equal '((:document :a :type :input))
                      (cadgui-workspace-pending-requests ws)))
           ;; answer it with a point, drive to the next park (getpoint #2)
           (cadgui-doc-feed-point ws da 0 0)
           (is (eq :input (cadgui-workspace-drive-step ws)))  ; answer delivered
           (is (eq :park (cadgui-workspace-drive-step ws)))   ; da awaits getpoint #2
           ;; answer the second point -> the LINE is drawn, da finishes
           (cadgui-doc-feed-point ws da 5 5)
           (is (eq :input (cadgui-workspace-drive-step ws)))
           (is (eq :done (cadgui-workspace-drive-step ws)))   ; entity-created noted here
           ;; no request is open any more
           (is (null (cadgui-workspace-pending-requests ws)))
           ;; the structured event stream recorded the whole interaction
           (let* ((events (cadgui-workspace-events ws))
                  (created (find :entity-created events :key #'first))
                  (done    (find :done events :key #'first)))
             (is (= 2 (count :request events :key #'first)))   ; two getpoints
             (is (= 2 (count :answer events :key #'first)))
             (is (equal :a (getf (rest (find :request events :key #'first)) :document)))
             (is (not (null created)))
             (is (equal :a (getf (rest created) :document)))
             (is (= 1 (getf (rest created) :added)))
             (is (not (null done)))
             ;; entity-created precedes done in the stream
             (is (< (position created events) (position done events)))))
      (cadgui-workspace-shutdown ws))))

(test cadgui-workspace-open-close-document-lifecycle
  ;; Multi-document lifecycle on the shared host: open two documents, list them,
  ;; see which is current, close one (ending its parked thread + its cador
  ;; document), and confirm the other is untouched.
  (let* ((ws (cadgui-make-workspace))
         (da (cadgui-open-document ws :a #'cadgui-document-command-loop))
         (db (cadgui-open-document ws :b #'cadgui-document-command-loop)))
    (unwind-protect
         (progn
           (is (equal '(:a :b) (cadgui-workspace-document-keys ws)))
           (cadgui-workspace-launch ws da) (cadgui-workspace-drive-step ws)
           (cadgui-workspace-launch ws db) (cadgui-workspace-drive-step ws)
           (is (eq db (cadgui-workspace-active-document ws)))   ; last launched is current
           ;; close da while it is parked: its thread unwinds, the cador document
           ;; closes, and it drops from the workspace
           (is (cadgui-close-document ws da))
           (is (equal '(:b) (cadgui-workspace-document-keys ws)))
           (is (eq db (cadgui-workspace-active-document ws))))  ; db unaffected
      (cadgui-workspace-shutdown ws))))

(test cadgui-document-runs-a-typed-autolisp-command-that-getpoints-and-draws
  ;; The live interactive loop: a document runs cadgui-document-command-loop; the
  ;; user TYPES an AutoLISP command, which runs in the document's scheduler
  ;; context -- its getpoints park and are answered by canvas clicks. Everything
  ;; is driven through the multiplexing driver (which a window would feed).
  (let* ((ws (cadgui-make-workspace))
         (da (cadgui-open-document ws :a #'cadgui-document-command-loop)))
    (unwind-protect
         (progn
           (cadgui-workspace-launch ws da)
           (is (eq :park (cadgui-workspace-drive-step ws)))    ; reading a command
           ;; the user types a LINE command
           (cadgui-doc-feed ws da "(command \"LINE\" (getpoint) (getpoint))")
           (is (eq :input (cadgui-workspace-drive-step ws)))   ; run it -> getpoint #1
           (is (eq :park (cadgui-workspace-drive-step ws)))
           (cadgui-doc-feed-point ws da 0 0)
           (is (eq :input (cadgui-workspace-drive-step ws)))   ; -> getpoint #2
           (is (eq :park (cadgui-workspace-drive-step ws)))
           (cadgui-doc-feed-point ws da 5 5)
           (is (eq :input (cadgui-workspace-drive-step ws)))   ; LINE draws, loop reads next
           (is (eq :park (cadgui-workspace-drive-step ws)))    ; parked reading the NEXT command
           ;; end the document's input
           (cadgui-doc-feed ws da :eof)
           (is (eq :input (cadgui-workspace-drive-step ws)))   ; :eof -> loop returns
           (is (eq :done (cadgui-workspace-drive-step ws)))
           ;; the typed command drew a line in this document's model
           (is (= 1 (length (cadgui-doc-display-list da)))))
      (cadgui-workspace-shutdown ws))))

(test cadgui-two-documents-run-typed-commands-interleaved-without-cross-bleed
  ;; Regression: the documents share ONE session, so its HAL host is one slot.
  ;; Run two TYPED LINE commands INTERLEAVED (A's command, then B's, then A's
  ;; points, ...). Without the per-document activation-hook host rebind, A's
  ;; draw would use B's host and both lines would land in one document. Each
  ;; must draw in its OWN model.
  (let* ((ws (cadgui-make-workspace))
         (da (cadgui-open-document ws :a #'cadgui-document-command-loop))
         (db (cadgui-open-document ws :b #'cadgui-document-command-loop)))
    (flet ((step! () (cadgui-workspace-drive-step ws)))
      (unwind-protect
           (progn
             (cadgui-workspace-launch ws da) (step!)   ; a reads command
             (cadgui-workspace-launch ws db) (step!)   ; b reads command
             ;; both type their command (interleaved) -> both park at getpoint #1
             (cadgui-doc-feed ws da "(command \"LINE\" (getpoint) (getpoint))") (step!) (step!)
             (cadgui-doc-feed ws db "(command \"LINE\" (getpoint) (getpoint))") (step!) (step!)
             ;; first corner each
             (cadgui-doc-feed-point ws da 0 0) (step!) (step!)
             (cadgui-doc-feed-point ws db 0 0) (step!) (step!)
             ;; second corner each -> each LINE draws, loop reads next command
             (cadgui-doc-feed-point ws da 5 5) (step!) (step!)
             (cadgui-doc-feed-point ws db 9 9) (step!) (step!)
             ;; end both
             (cadgui-doc-feed ws da :eof) (step!) (step!)
             (cadgui-doc-feed ws db :eof) (step!) (step!)
             (let ((sa (cadgui-doc-display-list da))
                   (sb (cadgui-doc-display-list db)))
               (is (= 1 (length sa)))       ; NOT 2 (A) / 0 (B)
               (is (= 1 (length sb)))
               (is (equal '(0d0 0d0 5d0 5d0) (sixth (first sa))))
               (is (equal '(0d0 0d0 9d0 9d0) (sixth (first sb))))))
        (cadgui-workspace-shutdown ws)))))
