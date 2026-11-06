;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               backend-autocad-trustedpaths.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;
;;;;    Trust alfe's workdir in AutoCAD's TRUSTEDPATHS for the run, and
;;;;    remove it afterwards (alfe-cad-workdir-not-in-trustedpaths).
;;;;
;;;;    pjb, 2026-09-28: "add to TRUSTEDPATHS for the run and restore after".
;;;;
;;;;    WHY BEFORE THE LAUNCH. With SECURELOAD=2 AutoCAD loads executable
;;;;    files only from TRUSTEDPATHS, and the first thing it loads is alfe's
;;;;    run-common.lsp, from the fresh temporary workdir. That load is itself
;;;;    refused, before any expression of ours runs, so no (setvar
;;;;    "TRUSTEDPATHS" ...) could ever take effect. The value has to be in
;;;;    the profile (the registry) when AutoCAD starts.
;;;;
;;;;    WHY REMOVE, NOT RESTORE. The workdir is added as ONE entry,
;;;;    "<workdir>\..." (recursive: runtime\ and protocol\ are under it),
;;;;    and afterwards exactly that entry is removed from whatever the value
;;;;    is THEN. Writing back the value read at the start would undo what
;;;;    anybody else changed meanwhile -- another alfe run, or the user.
;;;;
;;;;    WHY AFTER THE CAD IS GONE. AutoCAD saves its profile when it exits,
;;;;    TRUSTEDPATHS included. Removing the entry while the AutoCAD we
;;;;    created still runs would let its exit write the entry back.
;;;;
;;;;    A RUN THAT IS KILLED cannot remove its entry, and an entry left
;;;;    behind is a directory trusted for ever: the removal matters more
;;;;    than the addition. Two nets, both swept at the start of every run:
;;;;      - a JOURNAL outside the workdir (next to alfe-created-cad.txt)
;;;;        names each entry with the pid of the alfe that added it; a
;;;;        line whose pid is dead is removed from the registry;
;;;;      - an entry naming an alfe-GENERATED workdir
;;;;        (alfe-<backend>-<pid>-<tag>) whose pid is dead is removed even
;;;;        without a journal line -- the case of a killed AutoCAD that
;;;;        saved its profile after our removal.
;;;;
;;;;    WHY POWERSHELL, NOT reg.exe. reg.exe prints in the console codepage,
;;;;    which the ProgID lookup decodes as Latin-1 -- fine for ASCII
;;;;    ProgIDs, but TRUSTEDPATHS holds paths, and the workdir itself lives
;;;;    under %TEMP%, i.e. under a user name that may well be `Frédéric'.
;;;;    Reading that through the wrong codepage and writing it back would
;;;;    corrupt the user's value. PowerShell's .NET registry API is exact,
;;;;    and the transport is kept ASCII both ways: the script goes in as
;;;;    -EncodedCommand, strings go in and come out as UTF-16 code numbers.
;;;;    It also keeps the value KIND (REG_SZ vs REG_EXPAND_SZ, unexpanded).
;;;;
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;LEGAL
;;;;    AGPL3
;;;;**************************************************************************

(in-package #:alfe.backend.autocad)

;;; --- the value: pure string arithmetic ----------------------------------

(defun split-trustedpaths (value)
  "The entries of a TRUSTEDPATHS VALUE, in order. `;' separates; empty
entries and the `.' / \"\" meaning none are dropped."
  (remove-if (lambda (entry) (or (string= entry "") (string= entry ".")))
             (mapcar (lambda (entry) (string-trim '(#\Space #\Tab) entry))
                     (uiop:split-string (or value "") :separator ";"))))

(defun join-trustedpaths (entries)
  (format nil "~{~A~^;~}" entries))

(defun %same-trusted-entry-p (a b)
  "Windows paths: compare case-insensitively, and ignore the separator."
  (string-equal (substitute #\\ #\/ a) (substitute #\\ #\/ b)))

(defun workdir-trusted-entry (workdir)
  "The ONE entry that trusts WORKDIR and everything under it: its native
name with no trailing separator, then `\\...' (TRUSTEDPATHS' recursive
suffix)."
  (let ((name (uiop:native-namestring (uiop:ensure-directory-pathname workdir))))
    (concatenate 'string (string-right-trim "\\/" name) "\\...")))

(defun add-trusted-entry (value entry)
  "VALUE with ENTRY appended, or VALUE's entries unchanged if it is there."
  (let ((entries (split-trustedpaths value)))
    (join-trustedpaths
     (if (member entry entries :test #'%same-trusted-entry-p)
         entries
         (append entries (list entry))))))

(defun remove-trusted-entries (value predicate)
  "VALUE without the entries satisfying PREDICATE. Second value: true
when something was removed."
  (let* ((entries (split-trustedpaths value))
         (kept (remove-if predicate entries)))
    (values (join-trustedpaths kept) (/= (length kept) (length entries)))))

(defun trusted-entry-workdir-pid (entry)
  "The alfe pid encoded in ENTRY when it names an alfe-GENERATED workdir
(`...\\alfe-<backend>-<pid>-<tag>\\...'), else NIL."
  (let* ((path (substitute #\\ #\/ entry))
         (path (if (uiop:string-suffix-p path "\\...")
                   (subseq path 0 (- (length path) 4))
                   path))
         (name (subseq path (1+ (or (position #\\ path :from-end t) -1)))))
    (when (alfe.workdir:alfe-generated-workdir-name-p
           (concatenate 'string "/x/" name "/"))
      (parse-integer (third (uiop:split-string name :separator "-"))))))

;;; --- the registry: hooks, so the tests need no Windows -------------------

(defvar *trustedpaths-location-function* '%autocad-trustedpaths-locations
  "Function () -> the list of SUBKEYs under HKEY_CURRENT_USER whose
TRUSTEDPATHS value is to hold the workdir -- NIL when there is none (then
nothing is trusted, and the run proceeds as before).")

(defparameter *trustedpaths-value-name* "TRUSTEDPATHS")

(defvar *registry-read-function* '%hkcu-read-value
  "Function (SUBKEY NAME) -> (values DATA KIND), or NIL when absent.")

(defvar *registry-write-function* '%hkcu-write-value
  "Function (SUBKEY NAME DATA KIND) -> true on success.")

(defvar *process-alive-function* '%windows-pid-alive-p
  "Function (PID) -> true while that process exists.")

(defvar *trustedpaths-journal-function* 'trustedpaths-journal-path
  "Function () -> the journal pathname.")

(defun trustedpaths-journal-path ()
  "Deliberately OUTSIDE any workdir, like alfe-created-cad.txt: a killed
run's workdir may be removed by hand, and the journal must outlive it."
  (merge-pathnames "alfe-trustedpaths.txt" (uiop:temporary-directory)))

;;; --- PowerShell transport -------------------------------------------------

(defun %base64 (octets)
  (let ((alphabet "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"))
    (with-output-to-string (out)
      (loop for i from 0 below (length octets) by 3
            for n = (min 3 (- (length octets) i))
            for word = (logior (ash (aref octets i) 16)
                               (if (> n 1) (ash (aref octets (+ i 1)) 8) 0)
                               (if (> n 2) (aref octets (+ i 2)) 0))
            do (loop for k from 0 below 4
                     do (write-char (if (<= k n)
                                        (char alphabet (ldb (byte 6 (- 18 (* 6 k))) word))
                                        #\=)
                                    out))))))

(defun powershell-encoded-command (script)
  "SCRIPT as PowerShell's -EncodedCommand wants it: base64 of UTF-16LE."
  (let ((octets (make-array (* 2 (length script)) :element-type '(unsigned-byte 8))))
    (loop for ch across script
          for i from 0 by 2
          do (setf (aref octets i) (ldb (byte 8 0) (char-code ch))
                   (aref octets (1+ i)) (ldb (byte 8 8) (char-code ch))))
    (%base64 octets)))

(defun ps-string (string)
  "A PowerShell expression for STRING that is pure ASCII whatever STRING
holds -- no quoting, no codepage."
  (if (zerop (length string))
      "([string]'')"
      (format nil "(-join ([char[]](~{~D~^,~})))" (map 'list #'char-code string))))

(defun %run-powershell (script)
  "SCRIPT's standard output, or NIL. Windows only."
  (when (windows-p)
    (ignore-errors
     (uiop:run-program (list "powershell" "-NoProfile" "-NonInteractive"
                             "-EncodedCommand" (powershell-encoded-command script))
                       :output :string :error-output nil
                       :external-format :latin-1
                       :ignore-error-status t))))

(defun parse-code-numbers (text)
  "The string whose UTF-16 code numbers TEXT lists, separated by spaces."
  (map 'string #'code-char
       (mapcar #'parse-integer
               (uiop:split-string (string-trim '(#\Space #\Tab #\Return #\Newline) text)
                                  :separator " "))))

(defun %hkcu-read-value (subkey name)
  (let ((output (%run-powershell
                 (format nil "$k=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(~A);~
if($k -eq $null -or ($k.GetValueNames() -notcontains ~A)){'ABSENT'}else{~
$v=[string]$k.GetValue(~A,'',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);~
'KIND '+$k.GetValueKind(~A);'DATA '+(([int[]][char[]]$v) -join ' ')}"
                         (ps-string subkey) (ps-string name) (ps-string name) (ps-string name)))))
    (when output
      (let ((kind nil) (data nil))
        (dolist (line (uiop:split-string output :separator '(#\Newline)))
          (let ((line (string-trim '(#\Return #\Space) line)))
            (cond ((uiop:string-prefix-p "KIND " line) (setf kind (subseq line 5)))
                  ((string= line "DATA") (setf data ""))
                  ((uiop:string-prefix-p "DATA " line)
                   (setf data (parse-code-numbers (subseq line 5)))))))
        (when (and kind data)
          (values data kind))))))

(defun %hkcu-write-value (subkey name data kind)
  (let ((output (%run-powershell
                 (format nil "$k=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(~A,$true);~
if($k -eq $null){'NOKEY'}else{$k.SetValue(~A,~A,[Microsoft.Win32.RegistryValueKind]::~A);'OK'}"
                         (ps-string subkey) (ps-string name) (ps-string data)
                         (if (string-equal kind "ExpandString") "ExpandString" "String")))))
    (and output (search "OK" output) t)))

(defun %windows-pid-alive-p (pid)
  (let ((output (%run-powershell
                 (format nil "if(Get-Process -Id ~D -ErrorAction SilentlyContinue){'ALIVE'}else{'DEAD'}"
                         pid))))
    ;; Cannot tell -> ALIVE: never take away another run's trust on a guess.
    (or (null output) (and (search "ALIVE" output) t))))

(defun %autocad-trustedpaths-locations ()
  "EVERY AutoCAD profile of this user: each
HKCU\\Software\\Autodesk\\AutoCAD\\<release>\\<product>\\Profiles\\<profile>\\Variables.

WHY ALL OF THEM, measured on the Windows runner (probe:trustedpaths-
registry:windows, 2026-09-28): `the current profile' is not one answer.
The Profiles key's default value said `Epure' while its CPROFILE value
said `<<Profil sans nom>>' -- and the TRUSTEDPATHS somebody had set by
hand for CI was in the latter. Which one AutoCAD, or accoreconsole, starts
with is its business; trusting the workdir in one profile only would be a
guess that fails silently under the other. The entry exists only for the
run, so the wider write costs nothing that lasts."
  (let ((output (%run-powershell
                 (format nil "$r=[Microsoft.Win32.Registry]::CurrentUser;$b='Software\\Autodesk\\AutoCAD';~
$a=$r.OpenSubKey($b);if($a){foreach($rel in $a.GetSubKeyNames()){~
$k=$r.OpenSubKey($b+'\\'+$rel);if($k){foreach($prod in $k.GetSubKeyNames()){~
$pk=$r.OpenSubKey($b+'\\'+$rel+'\\'+$prod+'\\Profiles');if($pk){foreach($prof in $pk.GetSubKeyNames()){~
$s=$b+'\\'+$rel+'\\'+$prod+'\\Profiles\\'+$prof+'\\Variables';~
if($r.OpenSubKey($s)){'KEY '+(([int[]][char[]]$s) -join ' ')}}}}}}}"))))
    (when output
      (loop for line in (uiop:split-string output :separator '(#\Newline))
            for trimmed = (string-trim '(#\Return #\Space) line)
            when (uiop:string-prefix-p "KEY " trimmed)
              collect (parse-code-numbers (subseq trimmed 4))))))

;;; --- journal ----------------------------------------------------------------

(defun %read-journal ()
  (let ((path (funcall *trustedpaths-journal-function*)))
    (when (probe-file path)
      (with-open-file (in path :external-format :utf-8)
        (loop for line = (read-line in nil nil)
              while line
              for fields = (uiop:split-string line :separator '(#\Tab))
              when (= 4 (length fields))
                collect (list (ignore-errors (parse-integer (first fields)))
                              (second fields) (third fields) (fourth fields)))))))

(defun %write-journal (lines)
  (let ((path (funcall *trustedpaths-journal-function*)))
    (if (null lines)
        (when (probe-file path) (ignore-errors (delete-file path)))
        (with-open-file (out path :direction :output :if-exists :supersede
                                  :external-format :utf-8)
          (dolist (line lines)
            (format out "~{~A~^	~}~%" line))))))

;;; --- the operations -------------------------------------------------------

(defun %remove-from-registry (subkey name predicate why)
  "Remove the entries satisfying PREDICATE from SUBKEY\\NAME. True when
the value no longer holds any of them."
  (multiple-value-bind (data kind) (funcall *registry-read-function* subkey name)
    (if (null data)
        t
        (multiple-value-bind (new removed) (remove-trusted-entries data predicate)
          (cond ((not removed) t)
                ((funcall *registry-write-function* subkey name new kind)
                 (log-verbose "backend AUTOCAD: TRUSTEDPATHS: removed ~A from ~A" why subkey)
                 t)
                (t
                 (log-warn "backend AUTOCAD: TRUSTEDPATHS: could not remove ~A ~
from HKCU\\~A\\~A -- remove it by hand" why subkey name)
                 nil))))))

(defun %getpid () (alfe.workdir::current-pid))

(defun sweep-stale-trusted-entries (subkeys)
  "Remove what killed runs left behind: journal lines whose alfe is dead,
and, in each of SUBKEYS, entries naming an alfe-generated workdir whose
alfe is dead. A pid that cannot be judged counts as ALIVE: another run's
trust is never taken away on a guess."
  (let ((keep '()))
    (dolist (line (%read-journal))
      (destructuring-bind (pid jsubkey jname entry) line
        (if (and pid (/= pid (%getpid))
                 (not (funcall *process-alive-function* pid)))
            (unless (%remove-from-registry
                     jsubkey jname (lambda (e) (%same-trusted-entry-p e entry))
                     (format nil "~A (left by dead alfe ~D)" entry pid))
              (push line keep))
            (push line keep))))
    (%write-journal (nreverse keep)))
  (dolist (subkey subkeys)
    (%remove-from-registry
     subkey *trustedpaths-value-name*
     (lambda (entry)
       (let ((pid (trusted-entry-workdir-pid entry)))
         (and pid (/= pid (%getpid))
              (not (funcall *process-alive-function* pid)))))
     "stale alfe workdir entries")))

(defun trust-workdir-for-run (workdir)
  "Add WORKDIR to TRUSTEDPATHS in every AutoCAD profile. Returns a TOKEN
for UNTRUST-WORKDIR -- the (SUBKEY NAME ENTRY) triples actually written --
or NIL when nothing was changed (not Windows, no profile, writes refused):
the run then proceeds as it always has, which works whenever SECURELOAD is
below 2."
  (let ((subkeys (funcall *trustedpaths-location-function*))
        (name *trustedpaths-value-name*)
        (entry (workdir-trusted-entry workdir))
        (token '()))
    (cond
      ((null subkeys)
       (log-debug "backend AUTOCAD: TRUSTEDPATHS: no AutoCAD profile found; not trusting the workdir")
       nil)
      (t
       (ignore-errors (sweep-stale-trusted-entries subkeys))
       (dolist (subkey subkeys)
         (multiple-value-bind (data kind) (funcall *registry-read-function* subkey name)
           (let ((new (add-trusted-entry (or data "") entry)))
             (unless (and data (string= new (join-trustedpaths (split-trustedpaths data))))
               ;; JOURNAL FIRST: dying between the two leaves a line whose
               ;; entry may be absent, which the sweep removes harmlessly;
               ;; the other order could leave a trust nobody knows about.
               (%write-journal (append (%read-journal)
                                       (list (list (%getpid) subkey name entry))))
               (if (funcall *registry-write-function* subkey name new (or kind "String"))
                   (push (list subkey name entry) token)
                   (log-warn "backend AUTOCAD: TRUSTEDPATHS: could not add ~A to ~
HKCU\\~A\\~A; a CAD with SECURELOAD=2 using that profile will refuse alfe's runtime"
                             entry subkey name))))))
       (when token
         (log-verbose "backend AUTOCAD: TRUSTEDPATHS: trusting ~A for this run (~D profile~:P)"
                      entry (length token)))
       (nreverse token)))))

(defun untrust-workdir (token)
  "Undo TRUST-WORKDIR-FOR-RUN: remove exactly its entry from each profile
it wrote, then the journal lines. Idempotent; TOKEN NIL does nothing."
  (dolist (triple token)
    (destructuring-bind (subkey name entry) triple
      (when (%remove-from-registry subkey name
                                   (lambda (e) (%same-trusted-entry-p e entry))
                                   entry)
        (%write-journal (remove-if (lambda (line)
                                     (and (eql (first line) (%getpid))
                                          (equal (second line) subkey)
                                          (%same-trusted-entry-p (fourth line) entry)))
                                   (%read-journal)))))))
