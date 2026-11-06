(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;; alfe-cad-workdir-not-in-trustedpaths (pjb, 2026-09-28): add the workdir
;;; to AutoCAD's TRUSTEDPATHS for the run, remove it afterwards. The registry
;;; is faked: a hash table keyed by (subkey . name) holding (data . kind).

(defmacro with-fake-trustedpaths ((&key (value "C:\\Tools") (alive '()))
                                  &body body)
  "Run BODY against a fake registry whose TRUSTEDPATHS starts as VALUE
(NIL: absent) and a fake process table where only ALIVE pids live. Binds
REG (the table), JOURNAL (its path) and KEY (the subkey)."
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
                (when cell (values (car cell) (cdr cell))))))
          (alfe.backend.autocad::*registry-write-function*
            (lambda (subkey name data kind)
              (setf (gethash (cons subkey name) reg) (cons data kind))
              t))
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
    (is (search "(when (eq launcher #'uiop:launch-program)" text))
    (is (search "(trust-workdir-for-run workdir)" text))))

(test trustedpaths-real-registry-round-trip-on-windows
  ;; The only test of the PowerShell transport itself, so it runs against the
  ;; REAL registry of a Windows host that has AutoCAD profiles -- the native
  ;; Windows alfe lane. A workdir name with a non-ASCII character is the
  ;; point: reg.exe's codepage would have mangled it. The entry lives for the
  ;; duration of the test and every profile must end byte-identical.
  (when (alfe.backend.cad-common:windows-p)
    (let ((subkeys (funcall alfe.backend.autocad::*trustedpaths-location-function*)))
      (when subkeys
        (let* ((before (mapcar (lambda (s)
                                 (multiple-value-list
                                  (alfe.backend.autocad::%hkcu-read-value s "TRUSTEDPATHS")))
                               subkeys))
               (workdir (merge-pathnames
                         (format nil "alfe-trust-test-é-~D/" (random 1000000))
                         (uiop:temporary-directory)))
               (entry (alfe.backend.autocad::workdir-trusted-entry workdir))
               (token (alfe.backend.autocad::trust-workdir-for-run workdir)))
          (unwind-protect
               (progn
                 (is (= (length subkeys) (length token)))
                 (dolist (s subkeys)
                   (is (member entry
                               (alfe.backend.autocad::split-trustedpaths
                                (alfe.backend.autocad::%hkcu-read-value s "TRUSTEDPATHS"))
                               :test #'string=)
                       "~A holds ~A" s entry)))
            (alfe.backend.autocad::untrust-workdir token))
          (loop for s in subkeys
                for (data) in before
                ;; an ABSENT value comes back empty: the same meaning ("none"),
                ;; and AutoCAD writes the value on its next profile save anyway
                do (is (string= (or data "")
                                (or (alfe.backend.autocad::%hkcu-read-value s "TRUSTEDPATHS") ""))
                       "~A restored" s)))))))
