(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;; alfe-cad-workdir-not-in-trustedpaths (pjb, 2026-09-28): add the workdir
;;; to AutoCAD's TRUSTEDPATHS for the run, remove it afterwards. The registry
;;; is faked: a hash table keyed by (subkey . name) holding (data . kind).

(defmacro with-fake-trustedpaths ((&key (value "C:\\Tools") (alive '()))
                                  &body body)
  "Run BODY against a fake registry whose TRUSTEDPATHS starts as VALUE
(NIL: absent) and a fake process table where only ALIVE pids live. Binds
REG (the table), JOURNAL (its path) and KEY (the subkey). The registry
hooks have the real ones' contract: a read answers (VALUES NIL :ABSENT)
for a missing value, a write is a compare-and-set."
  `(let* ((reg (make-hash-table :test 'equal))
          (key "Software\\Autodesk\\AutoCAD\\R24.1\\ACAD-5101:409\\Profiles\\<<Unnamed Profile>>\\Variables")
          (journal (merge-pathnames
                    (format nil "alfe-trustedpaths-test-~D.txt" (random 1000000))
                    (uiop:temporary-directory)))
          (alfe.backend.autocad::*trustedpaths-location-function*
            (lambda () (list key)))
          (alfe.backend.autocad::*registry-read-function*
            (lambda (subkey name)
              (let ((cell (gethash (cons subkey name) reg)))
                (if cell
                    (values (car cell) (cdr cell))
                    (values nil :absent)))))
          (alfe.backend.autocad::*registry-write-function*
            (lambda (subkey name expected data kind)
              ;; compare-and-set, as %HKCU-WRITE-VALUE does under its mutex
              (if (equal expected (car (gethash (cons subkey name) reg)))
                  (progn (setf (gethash (cons subkey name) reg) (cons data kind))
                         :ok)
                  :changed)))
          (alfe.backend.autocad::*process-alive-function*
            (lambda (pid) (or (member pid ',alive)
                              (eql pid (alfe.workdir::current-pid)))))
          (alfe.backend.autocad::*trustedpaths-journal-function*
            (lambda () journal)))
     (declare (ignorable key))
     (when ,value
       (setf (gethash (cons key "TRUSTEDPATHS") reg) (cons ,value "String")))
     (unwind-protect (progn ,@body)
       (when (probe-file journal) (delete-file journal)))))

(defun %trustedpaths-now (reg key)
  (car (gethash (cons key "TRUSTEDPATHS") reg)))

(test trustedpaths-value-arithmetic
  (is (equal '("C:\\a" "D:\\b\\...")
             (alfe.backend.autocad::split-trustedpaths " C:\\a ;;.;D:\\b\\...;")))
  (is (string= "C:\\a;C:\\w\\..."
               (alfe.backend.autocad::add-trusted-entry "C:\\a" "C:\\w\\...")))
  ;; already there, spelled differently -> unchanged
  (is (string= "C:\\a;c:/W\\..."
               (alfe.backend.autocad::add-trusted-entry "C:\\a;c:/W\\..." "C:\\w\\...")))
  (is (string= "C:\\w\\..." (alfe.backend.autocad::add-trusted-entry "" "C:\\w\\...")))
  (is (string= "C:\\a"
               (alfe.backend.autocad::remove-trusted-entries
                "C:\\a;C:\\w\\..."
                (lambda (e) (alfe.backend.autocad::%same-trusted-entry-p e "c:\\W\\..."))))))

(test trustedpaths-entry-is-the-recursive-workdir
  (let ((entry (alfe.backend.autocad::workdir-trusted-entry #p"/tmp/alfe-autocad-12-abc123/")))
    (is (uiop:string-suffix-p entry "alfe-autocad-12-abc123\\..."))
    (is (not (search "/\\..." entry)))))

(test trustedpaths-entry-pid-only-for-generated-workdirs
  (is (eql 4242 (alfe.backend.autocad::trusted-entry-workdir-pid
                 "C:\\Users\\Frédéric\\AppData\\Local\\Temp\\alfe-autocad-4242-k3j9x0\\...")))
  (is (null (alfe.backend.autocad::trusted-entry-workdir-pid "C:\\Tools\\...")))
  (is (null (alfe.backend.autocad::trusted-entry-workdir-pid "C:\\alfe-autocad-x-k3j9x0\\..."))))

(test trustedpaths-trust-then-untrust-leaves-the-value-as-found
  (with-fake-trustedpaths (:value "C:\\Tools")
    (let* ((workdir #p"/tmp/alfe-autocad-77-zz11aa/")
           (entry (alfe.backend.autocad::workdir-trusted-entry workdir))
           (token (alfe.backend.autocad::trust-workdir-for-run workdir)))
      (is (not (null token)))
      (is (string= (format nil "C:\\Tools;~A" entry) (%trustedpaths-now reg key)))
      (is (not (null (probe-file journal))) "the journal is written")
      (alfe.backend.autocad::untrust-workdir token)
      (is (string= "C:\\Tools" (%trustedpaths-now reg key)))
      (is (null (probe-file journal)) "the journal line is gone"))))

(test trustedpaths-untrust-keeps-what-others-added-meanwhile
  (with-fake-trustedpaths (:value "C:\\Tools")
    (let ((token (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/")))
      ;; the user (or another run) adds an entry while ours is there
      (setf (car (gethash (cons key "TRUSTEDPATHS") reg))
            (concatenate 'string (%trustedpaths-now reg key) ";E:\\Mine"))
      (alfe.backend.autocad::untrust-workdir token)
      (is (string= "C:\\Tools;E:\\Mine" (%trustedpaths-now reg key))))))

(test trustedpaths-absent-value-is-created-and-emptied
  (with-fake-trustedpaths (:value nil)
    (let ((token (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/")))
      (is (not (null token)))
      (alfe.backend.autocad::untrust-workdir token)
      (is (string= "" (%trustedpaths-now reg key))))))

(test trustedpaths-every-profile-is-trusted-and-restored
  ;; Measured on the runner: the Profiles default said `Epure', CPROFILE said
  ;; `<<Profil sans nom>>'. Both profiles get the entry, both lose it.
  (with-fake-trustedpaths (:value "C:\\Tools")
    (let* ((other "Software\\Autodesk\\AutoCAD\\R24.1\\ACAD-5101:409\\Profiles\\Epure\\Variables")
           (alfe.backend.autocad::*trustedpaths-location-function*
             (lambda () (list key other))))
      (setf (gethash (cons other "TRUSTEDPATHS") reg) (cons "" "String"))
      (let ((token (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/")))
        (is (= 2 (length token)))
        (is (search "alfe-autocad-77-zz11aa" (car (gethash (cons other "TRUSTEDPATHS") reg))))
        (alfe.backend.autocad::untrust-workdir token)
        (is (string= "C:\\Tools" (%trustedpaths-now reg key)))
        (is (string= "" (car (gethash (cons other "TRUSTEDPATHS") reg))))
        (is (null (probe-file journal)))))))

(test trustedpaths-keeps-the-value-kind
  (with-fake-trustedpaths (:value nil)
    (setf (gethash (cons key "TRUSTEDPATHS") reg) (cons "%APPDATA%\\x" "ExpandString"))
    (alfe.backend.autocad::untrust-workdir
     (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/"))
    (is (equal '("%APPDATA%\\x" . "ExpandString") (gethash (cons key "TRUSTEDPATHS") reg)))))

(test trustedpaths-no-profile-changes-nothing
  (with-fake-trustedpaths (:value "C:\\Tools")
    (let ((alfe.backend.autocad::*trustedpaths-location-function* (lambda () nil)))
      (is (null (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/")))
      (is (string= "C:\\Tools" (%trustedpaths-now reg key))))))

(test trustedpaths-sweep-removes-what-killed-runs-left
  ;; 999001 is dead and journalled; 999002 is dead, not journalled, but its
  ;; entry names an alfe-generated workdir (a killed AutoCAD saved it back);
  ;; 999003 is alive -- another run in progress, which must keep its trust.
  (with-fake-trustedpaths (:value "C:\\Tools;C:\\u\\...;C:\\T\\alfe-autocad-999002-aaaaaa\\...;C:\\T\\alfe-autocad-999003-bbbbbb\\..."
                           :alive (999003))
    (alfe.backend.autocad::%write-journal
     (list (list 999001 key "TRUSTEDPATHS" "C:\\u\\...")))
    (alfe.backend.autocad::untrust-workdir
     (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/"))
    (is (string= "C:\\Tools;C:\\T\\alfe-autocad-999003-bbbbbb\\..."
                 (%trustedpaths-now reg key)))
    (is (null (probe-file journal)))))

;;; Two processes of the same user -- the GitLab runner and a `make test'
;;; over ssh, both as COMMUN\PPBN02261 on pfenny, 2026-11-15 -- read the
;;; same TRUSTEDPATHS, each appended its own entry and wrote back what it
;;; had read plus that entry: the second write erased the first's entry
;;; (alfe-trustedpaths-real-registry-flaky). A write is therefore a
;;; compare-and-set against the value read, retried on a change.

(defun %concurrent-writer (reg key entry)
  "A write hook that, on its FIRST call only, lets another process append
ENTRY to the value just before our write lands -- then behaves as the
fake compare-and-set registry."
  (let ((raced nil))
    (lambda (subkey name expected data kind)
      (unless raced
        (setf raced t)
        (let ((cell (gethash (cons key "TRUSTEDPATHS") reg)))
          (setf (gethash (cons key "TRUSTEDPATHS") reg)
                (cons (alfe.backend.autocad::add-trusted-entry (car cell) entry)
                      (or (cdr cell) "String")))))
      (if (equal expected (car (gethash (cons subkey name) reg)))
          (progn (setf (gethash (cons subkey name) reg) (cons data kind))
                 :ok)
          :changed))))

(test trustedpaths-trust-keeps-an-entry-written-concurrently
  (with-fake-trustedpaths (:value "C:\\Tools")
    (let ((alfe.backend.autocad::*registry-write-function*
            (%concurrent-writer reg key "E:\\Other\\...")))
      (let ((token (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/")))
        (is (= 1 (length token)))
        (is (string= (format nil "C:\\Tools;E:\\Other\\...;~A"
                             (alfe.backend.autocad::workdir-trusted-entry
                              #p"/tmp/alfe-autocad-77-zz11aa/"))
                     (%trustedpaths-now reg key)))))))

(test trustedpaths-untrust-keeps-an-entry-written-concurrently
  (with-fake-trustedpaths (:value "C:\\Tools")
    (let ((token (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/")))
      (let ((alfe.backend.autocad::*registry-write-function*
              (%concurrent-writer reg key "E:\\Other\\...")))
        (alfe.backend.autocad::untrust-workdir token))
      (is (string= "C:\\Tools;E:\\Other\\..." (%trustedpaths-now reg key)))
      (is (null (probe-file journal))))))

(test trustedpaths-a-value-that-keeps-changing-is-given-up
  ;; bounded: a value rewritten on every attempt ends in a warning, never a hang
  (with-fake-trustedpaths (:value "C:\\Tools")
    (let ((alfe.backend.autocad::*registry-write-function* (constantly :changed)))
      (is (null (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/"))))))

;;; A read that FAILED (PowerShell did not answer) is not an absent value.
;;; Taken for one, trust would replace the user's whole TRUSTEDPATHS with
;;; alfe's lone entry, and untrust would report the entry gone and drop its
;;; journal line while the entry stayed in the profile.

(test trustedpaths-an-unreadable-value-is-never-written
  (with-fake-trustedpaths (:value "C:\\Tools")
    (let ((alfe.backend.autocad::*registry-read-function* (constantly nil))
          (writes 0))
      (let ((alfe.backend.autocad::*registry-write-function*
              (lambda (&rest args) (declare (ignore args)) (incf writes) :ok)))
        (is (null (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/")))
        (is (zerop writes)))
      (is (string= "C:\\Tools" (%trustedpaths-now reg key))))))

(test trustedpaths-an-unreadable-value-keeps-the-journal-line
  (with-fake-trustedpaths (:value "C:\\Tools")
    (let ((token (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/")))
      (let ((alfe.backend.autocad::*registry-read-function* (constantly nil)))
        (alfe.backend.autocad::untrust-workdir token))
      (is (not (null (probe-file journal)))
          "the entry may still be there: the journal keeps it for the next sweep"))))

(test trustedpaths-a-failed-write-is-not-a-token
  (with-fake-trustedpaths (:value "C:\\Tools")
    (let ((alfe.backend.autocad::*registry-write-function* (constantly nil)))
      (is (null (alfe.backend.autocad::trust-workdir-for-run #p"/tmp/alfe-autocad-77-zz11aa/"))))))

(test trustedpaths-powershell-transport-is-ascii
  (let ((expr (alfe.backend.autocad::ps-string "C:\\Users\\Frédéric")))
    (is (every (lambda (c) (< (char-code c) 128)) expr))
    (is (search "233" expr) "é travels as its code number"))
  (is (string= "Frédéric" (alfe.backend.autocad::parse-code-numbers "70 114 233 100 233 114 105 99")))
  ;; -EncodedCommand is base64 of UTF-16LE: "ab" -> 61 00 62 00
  (is (string= "YQBiAA==" (alfe.backend.autocad::powershell-encoded-command "ab"))))

(test trustedpaths-not-touched-by-a-fake-launcher
  ;; --print-command and every test start the engine with their own launcher;
  ;; a dry run must never write the user's registry. Guarded in START-ENGINE
  ;; by (EQ LAUNCHER #'UIOP:LAUNCH-PROGRAM); this pins the source to it.
  (let ((text (uiop:read-file-string
               (asdf:system-relative-pathname "autolisp-front-end"
                                              "source/backend-autocad.lisp"))))
    (is (search "(when (and (eq variant :batch)" text))
    (is (search "(eq launcher #'uiop:launch-program))" text))
    (is (search "(trust-workdir-for-run workdir)" text))))

(defun %foreign-trusted-entry-p (entry)
  "An entry another run may add or remove while a real-registry test runs:
an alfe workdir, or another test's own entry. Such entries are not part of
what a test must find restored."
  (or (alfe.backend.autocad::trusted-entry-workdir-pid entry)
      (search "alfe-trust-test-" entry)))

(defun %own-entries (value)
  (remove-if #'%foreign-trusted-entry-p
             (alfe.backend.autocad::split-trustedpaths value)))

(test trustedpaths-real-registry-round-trip-on-windows
  ;; The test of the PowerShell transport on real profiles, so it runs
  ;; against the REAL registry of a Windows host that has AutoCAD profiles
  ;; -- the native Windows alfe lane. A path with a non-ASCII character is
  ;; the point: reg.exe's codepage would have mangled it. The workdir is
  ;; named as alfe names its own, so a killed test leaves an entry the next
  ;; run's sweep removes. Another run of this suite may share the profiles
  ;; (the runner and a developer use the same account on the Windows box):
  ;; its entries come and go, so what must be restored is the rest.
  (when (alfe.backend.cad-common:windows-p)
    (let ((subkeys (funcall alfe.backend.autocad::*trustedpaths-location-function*)))
      (when subkeys
        (let* ((before (mapcar (lambda (s)
                                 (multiple-value-list
                                  (alfe.backend.autocad::%hkcu-read-value s "TRUSTEDPATHS")))
                               subkeys))
               (workdir (merge-pathnames
                         (format nil "alfe-trust-test-é/alfe-trusttest-~D-~(~36,6,'0R~)/"
                                 (alfe.workdir::current-pid) (random (expt 36 6)))
                         (uiop:temporary-directory)))
               (entry (alfe.backend.autocad::workdir-trusted-entry workdir))
               (token (alfe.backend.autocad::trust-workdir-for-run workdir)))
          (is (alfe.backend.autocad::trusted-entry-workdir-pid entry)
              "~A is named like an alfe workdir" entry)
          (unwind-protect
               (progn
                 (is (= (length subkeys) (length token)))
                 (dolist (s subkeys)
                   (let ((read-back (multiple-value-list
                                     (alfe.backend.autocad::%hkcu-read-value s "TRUSTEDPATHS"))))
                     (is (member entry
                                 (alfe.backend.autocad::split-trustedpaths (first read-back))
                                 :test #'string=)
                         "~A holds ~A~%read back: ~S" s entry read-back))))
            (alfe.backend.autocad::untrust-workdir token))
          (loop for s in subkeys
                for (data) in before
                for after = (multiple-value-list
                             (alfe.backend.autocad::%hkcu-read-value s "TRUSTEDPATHS"))
                do (is (not (member entry
                                    (alfe.backend.autocad::split-trustedpaths (first after))
                                    :test #'string=))
                       "~A no longer holds ~A~%read back: ~S" s entry after)
                   ;; an ABSENT value comes back empty: the same meaning ("none")
                   (is (equal (%own-entries data) (%own-entries (first after)))
                       "~A restored~%before: ~S~%after:  ~S" s data after)))))))

(defun %powershell-or-fail (script)
  (let ((output (alfe.backend.autocad::%run-powershell script)))
    (is (search "DONE" (or output "")) "PowerShell ran: ~S" output)
    output))

(test trustedpaths-concurrent-updates-of-a-real-value-all-land
  ;; The compare-and-set and its mutex against the real registry, on any
  ;; Windows host (no AutoCAD needed): four threads each add their own entry
  ;; to ONE scratch value at the same time, then each removes it. A plain
  ;; read-modify-write loses entries here, because every PowerShell start
  ;; leaves a wide window between a read and the write after it.
  (when (alfe.backend.cad-common:windows-p)
    (let* ((subkey (format nil "Software\\clautolisp-tests\\trustedpaths-~D"
                           (alfe.workdir::current-pid)))
           (name "TRUSTEDPATHS")
           (entries (loop for i from 1 to 4
                          collect (format nil "C:\\alfe-trust-test-é-~D\\..." i)))
           (lock (bordeaux-threads:make-lock "results"))
           (results '()))
      (%powershell-or-fail
       (format nil "[void][Microsoft.Win32.Registry]::CurrentUser.CreateSubKey(~A);'DONE'"
               (alfe.backend.autocad::ps-string subkey)))
      (flet ((in-parallel (function)
               (setf results '())
               (mapc #'bordeaux-threads:join-thread
                     (mapcar (lambda (entry)
                               (bordeaux-threads:make-thread
                                (lambda ()
                                  (let ((result (ignore-errors (funcall function entry))))
                                    (bordeaux-threads:with-lock-held (lock)
                                      (push result results))))))
                             entries))
               results)
             (now ()
               (alfe.backend.autocad::split-trustedpaths
                (alfe.backend.autocad::%hkcu-read-value subkey name))))
        (unwind-protect
             (progn
               (is (every (lambda (r) (eq r :written))
                          (in-parallel
                           (lambda (entry)
                             (alfe.backend.autocad::%update-registry-value
                              subkey name
                              (lambda (data)
                                (values (alfe.backend.autocad::add-trusted-entry (or data "") entry)
                                        t))))))
                   "every add was written: ~S" results)
               (is (equal (sort (copy-list entries) #'string<) (sort (now) #'string<))
                   "all four entries are there")
               (is (every (lambda (r) (eq r :written))
                          (in-parallel
                           (lambda (entry)
                             (alfe.backend.autocad::%update-registry-value
                              subkey name
                              (lambda (data)
                                (alfe.backend.autocad::remove-trusted-entries
                                 (or data "")
                                 (lambda (e) (string= e entry))))))))
                   "every removal was written: ~S" results)
               (is (null (now)) "all four entries are gone"))
          (%powershell-or-fail
           ;; and the parent, once no concurrent run of this test uses it
           (format nil "$r=[Microsoft.Win32.Registry]::CurrentUser;$r.DeleteSubKeyTree(~A,$false);~
$p=$r.OpenSubKey('Software\\clautolisp-tests');~
if($p -and $p.SubKeyCount -eq 0 -and $p.ValueCount -eq 0){$p.Close();$r.DeleteSubKey('Software\\clautolisp-tests',$false)};'DONE'"
                   (alfe.backend.autocad::ps-string subkey))))))))
