;;;; clautolisp/autolisp-init-files/tests/api-tests.lisp
;;;;
;;;; FiveAM tests for the discovery + gating helpers.
;;;;
;;;; Every test that touches the file system creates a fresh
;;;; per-test tmpdir, writes fixture files into it, and points the
;;;; stem-list at absolute paths *inside* that tmpdir — so the
;;;; user's real ~/.autolisp file (if any) is never observed and
;;;; tests don't pollute $HOME.

(in-package #:clautolisp.autolisp-init-files.tests)

(in-suite autolisp-init-files-suite)

;;; --- fixture helpers ----------------------------------------------

(defun make-tmpdir (prefix)
  "Create a fresh tmpdir under the system temp directory and return
its pathname. The caller is responsible for DELETE-DIRECTORY-TREE
on teardown."
  (let* ((stem (format nil "alfe-init-files-~A-~D-~D/"
                       prefix
                       #+sbcl (sb-posix:getpid)
                       #+ccl  (ccl::getpid)
                       #-(or sbcl ccl) 0
                       (random 1000000)))
         (path (merge-pathnames stem (uiop:temporary-directory))))
    (ensure-directories-exist path)
    path))

(defun delete-tmpdir (path)
  (when (uiop:directory-exists-p path)
    (uiop:delete-directory-tree path :validate t
                                     :if-does-not-exist :ignore)))

(defun touch (path &optional (content ""))
  "Create PATH with CONTENT. Returns the pathname."
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
    (write-string content out))
  path)

(defun touch-with-older-mtime (path content seconds-older)
  "Touch PATH then back-date its mtime by SECONDS-OLDER seconds.
Used to construct fixtures where one file is provably older than
another. SB-POSIX on ms-windows does not provide UTIME — the symbol is
probed with FBOUNDP (and spelled with :: so the file READS everywhere);
there the mtime is set through PowerShell instead. Falls back to the
unmodified mtime when neither path applies."
  (let ((p (touch path content)))
    (cond
      #+sbcl
      ((fboundp 'sb-posix::utime)
       (let* ((now (get-universal-time))
              (target (- now seconds-older))
              ;; sb-posix:utime takes Unix epoch seconds; CL's
              ;; get-universal-time is offset by 2208988800.
              (target-unix (- target 2208988800)))
         (handler-case (funcall 'sb-posix::utime (namestring p)
                                target-unix target-unix)
           (error () nil))))
      ((uiop:os-windows-p)
       (ignore-errors
         (uiop:run-program
          (list "powershell" "-NoProfile" "-Command"
                (format nil "(Get-Item '~A').LastWriteTime = (Get-Date).AddSeconds(-~D)"
                        (namestring p) seconds-older))))))
    p))

;;; --- env-true-p ----------------------------------------------------

(test env-true-p-recognises-truthy-spellings
  "Match the legacy bash wrapper's permissive read of
$AUTOLISP_NO_INIT: 1 / y / yes / true / on (case-insensitive)
count as truthy; anything else is false."
  (is (env-true-p "1"))
  (is (env-true-p "yes"))
  (is (env-true-p "YES"))
  (is (env-true-p "true"))
  (is (env-true-p "on"))
  (is (not (env-true-p "0")))
  (is (not (env-true-p "")))
  (is (not (env-true-p nil)))
  (is (not (env-true-p "false")))
  (is (not (env-true-p "maybe"))))

;;; --- find-init-file: bare wins ------------------------------------

(test find-init-file-bare-wins-when-present
  "When the bare stem file exists and REQUIRE-EXTENSION-P is NIL,
the bare file is the resolved pathname — regardless of whether
.lsp or compiled variants also exist."
  (let ((dir (make-tmpdir "bare-wins")))
    (unwind-protect
        (let ((stem (namestring (merge-pathnames "init" dir))))
          (touch stem "(setq marker :bare)")
          (touch (concatenate 'string stem ".lsp") "(setq marker :lsp)")
          (touch (concatenate 'string stem ".fas") "(setq marker :fas)")
          (let ((resolved (find-init-file stem :require-extension-p nil)))
            (is (equalp (truename stem)
                        (truename resolved)))))
      (delete-tmpdir dir))))

(test find-init-file-bare-rejected-when-extension-required
  "XDG `init` slots disallow the bare stem. With
REQUIRE-EXTENSION-P T, a bare file is invisible even when present."
  (let ((dir (make-tmpdir "no-bare")))
    (unwind-protect
        (let ((stem (namestring (merge-pathnames "init" dir))))
          (touch stem "ignored")
          (touch (concatenate 'string stem ".lsp") "(setq marker :lsp)")
          (let ((resolved (find-init-file stem :require-extension-p t)))
            (is (equalp (truename (concatenate 'string stem ".lsp"))
                        (truename resolved)))))
      (delete-tmpdir dir))))

;;; --- find-init-file: compiled vs source preference ----------------

(test find-init-file-compiled-newer-than-lsp-wins
  "When a compiled variant is strictly newer than .lsp, it wins
over .lsp. We backdate the .lsp by a few seconds so the mtime
comparison is unambiguous."
  (let ((dir (make-tmpdir "compiled-newer")))
    (unwind-protect
        (let ((stem (namestring (merge-pathnames "init" dir))))
          (touch-with-older-mtime
           (concatenate 'string stem ".lsp")
           "(setq marker :lsp)" 60)
          (touch (concatenate 'string stem ".fas")
                 "(setq marker :fas)")
          (let ((resolved (find-init-file stem :require-extension-p t)))
            (is (equalp (truename (concatenate 'string stem ".fas"))
                        (truename resolved)))))
      (delete-tmpdir dir))))

(test find-init-file-lsp-wins-when-newer-than-compiled
  "When the .lsp source has been edited since the cached compile,
the compiled form is stale and the picker falls back to .lsp."
  (let ((dir (make-tmpdir "source-newer")))
    (unwind-protect
        (let ((stem (namestring (merge-pathnames "init" dir))))
          (touch-with-older-mtime
           (concatenate 'string stem ".fas")
           "(setq marker :fas)" 60)
          (touch (concatenate 'string stem ".lsp")
                 "(setq marker :lsp)")
          (let ((resolved (find-init-file stem :require-extension-p t)))
            (is (equalp (truename (concatenate 'string stem ".lsp"))
                        (truename resolved)))))
      (delete-tmpdir dir))))

(test find-init-file-newest-compiled-wins-when-multiple-qualify
  "Among compiled variants that all qualify (each newer than .lsp,
or .lsp absent), the newest one wins. Fixture: .fas backdated by
60 s, .des backdated by 30 s, no .lsp — .des wins."
  (let ((dir (make-tmpdir "newest-compiled")))
    (unwind-protect
        (let ((stem (namestring (merge-pathnames "init" dir))))
          (touch-with-older-mtime
           (concatenate 'string stem ".fas")
           "(setq marker :fas)" 60)
          (touch-with-older-mtime
           (concatenate 'string stem ".des")
           "(setq marker :des)" 30)
          (let ((resolved (find-init-file stem :require-extension-p t)))
            (is (equalp (truename (concatenate 'string stem ".des"))
                        (truename resolved)))))
      (delete-tmpdir dir))))

(test find-init-file-miss-returns-nil
  "No bare file, no .lsp, no compiled — returns NIL, not an error.
Missing init files are a normal case, not a failure."
  (let ((dir (make-tmpdir "miss")))
    (unwind-protect
        (let ((stem (namestring (merge-pathnames "init" dir))))
          (is (null (find-init-file stem :require-extension-p nil)))
          (is (null (find-init-file stem :require-extension-p t))))
      (delete-tmpdir dir))))

;;; --- find-init-files: walk the list -------------------------------

(test find-init-files-walks-order-and-filters-nils
  "find-init-files returns resolved paths in stem-list order. Stems
with no matching file are silently filtered out — the result list
contains only the files actually present."
  (let ((dir (make-tmpdir "walk")))
    (unwind-protect
        (let ((stem1 (namestring (merge-pathnames "first" dir)))
              (stem2 (namestring (merge-pathnames "second" dir)))
              (stem3 (namestring (merge-pathnames "third" dir))))
          (touch (concatenate 'string stem1 ".lsp") "")
          ;; stem2 has no fixture — should be skipped.
          (touch stem3 "")
          (let ((files (find-init-files
                        (list (list stem1 t)
                              (list stem2 t)
                              (list stem3 nil)))))
            (is (= 2 (length files)))
            (is (equalp (truename (concatenate 'string stem1 ".lsp"))
                        (truename (first files))))
            (is (equalp (truename stem3)
                        (truename (second files))))))
      (delete-tmpdir dir))))

(test find-init-files-empty-stems-empty-result
  "An empty stem list returns an empty list — and never touches the
file system."
  (is (equal nil (find-init-files nil))))

;;; --- default stem lists -------------------------------------------

(test default-stems-have-four-slots
  "Each default stem list has exactly four entries, matching the
contract in issues/open/init-files.issue. The XDG slots
(positions 2 and 4) have REQUIRE-EXTENSION-P set; the HOME slots
do not."
  (is (= 4 (length *default-clautolisp-stems*)))
  (is (= 4 (length *default-alfe-stems*)))
  (is (null (second (nth 0 *default-clautolisp-stems*))))
  (is (eq t (second (nth 1 *default-clautolisp-stems*))))
  (is (null (second (nth 2 *default-clautolisp-stems*))))
  (is (eq t (second (nth 3 *default-clautolisp-stems*))))
  (is (null (second (nth 0 *default-alfe-stems*))))
  (is (eq t (second (nth 1 *default-alfe-stems*))))
  (is (null (second (nth 2 *default-alfe-stems*))))
  (is (eq t (second (nth 3 *default-alfe-stems*)))))

(test default-stems-share-autolisp-slots
  "Both default lists START with the shared ~/.autolisp +
~/.config/autolisp/init pair (positions 0 and 1) so a user
maintaining a single ~/.autolisp file sees it loaded by both
binaries before each program's specific files override."
  (is (equal (subseq *default-clautolisp-stems* 0 2)
             (subseq *default-alfe-stems* 0 2))))

;;; --- gating --------------------------------------------------------

(defun with-env-unset-helper (names thunk)
  "Run THUNK with every env var in NAMES temporarily unset.
Tests use this to make sure leftover state from another test's
fixture doesn't bleed into a gating assertion."
  (let ((saved (mapcar (lambda (name)
                         (cons name (uiop:getenv name)))
                       names)))
    (unwind-protect
        (progn
          #+sbcl (dolist (n names) (ignore-errors (sb-posix:unsetenv n)))
          #+ccl  (dolist (n names) (ignore-errors (ccl::unsetenv n)))
          (funcall thunk))
      (dolist (entry saved)
        (when (cdr entry)
          (setf (uiop:getenv (car entry)) (cdr entry)))))))

(defmacro with-env-unset ((&rest names) &body body)
  `(with-env-unset-helper ',names (lambda () ,@body)))

(test no-init-requested-p-honours-cli-flag
  "When the CLI flag is set, the helper returns T unconditionally —
the env vars are not even consulted."
  (with-env-unset ("AUTOLISP_NO_INIT" "CLAUTOLISP_NO_INIT" "ALFE_NO_INIT")
    (is (no-init-requested-p t))
    (is (no-init-requested-p t "CLAUTOLISP_NO_INIT"))))

(test no-init-requested-p-honours-shared-env
  "$AUTOLISP_NO_INIT is the shared kill-switch. Truthy → T even
when no program-specific env var is set."
  (with-env-unset ("AUTOLISP_NO_INIT" "CLAUTOLISP_NO_INIT" "ALFE_NO_INIT")
    (setf (uiop:getenv "AUTOLISP_NO_INIT") "1")
    (is (no-init-requested-p nil))
    (is (no-init-requested-p nil "CLAUTOLISP_NO_INIT"))
    (is (no-init-requested-p nil "ALFE_NO_INIT"))))

(test no-init-requested-p-honours-program-env
  "Per-program env vars gate only their own program."
  (with-env-unset ("AUTOLISP_NO_INIT" "CLAUTOLISP_NO_INIT" "ALFE_NO_INIT")
    (setf (uiop:getenv "CLAUTOLISP_NO_INIT") "1")
    (is (no-init-requested-p nil "CLAUTOLISP_NO_INIT"))
    ;; alfe's call doesn't pass CLAUTOLISP_NO_INIT, so it stays NIL.
    (is (not (no-init-requested-p nil "ALFE_NO_INIT")))))

(test no-init-requested-p-all-clear-returns-nil
  "No flag, no env vars — the helper says 'don't skip'."
  (with-env-unset ("AUTOLISP_NO_INIT" "CLAUTOLISP_NO_INIT" "ALFE_NO_INIT")
    (is (not (no-init-requested-p nil)))
    (is (not (no-init-requested-p nil "CLAUTOLISP_NO_INIT")))
    (is (not (no-init-requested-p nil "ALFE_NO_INIT" "CLAUTOLISP_NO_INIT")))))
