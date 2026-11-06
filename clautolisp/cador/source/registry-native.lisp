;;;; clautolisp/cador/source/registry-native.lisp
;;;;
;;;; The platforms' registry stores through their BINARY APIs, by CFFI
;;;; (pjb 2026-10-04: "for things like registry, the DLL provides an API
;;;; that is more stable (and safer with data types, encodings, etc). and
;;;; indeed, the same with defaults on macOS. We should use CFFI and the
;;;; binary API for this."), replacing the reg.exe and /usr/bin/defaults
;;;; subprocesses, whose output had to be decoded from a guessed console code
;;;; page and parsed.
;;;;
;;;;   Windows: advapi32 -- RegOpenKeyExW / RegCreateKeyExW / RegQueryValueExW
;;;;            / RegSetValueExW / RegDeleteValueW / RegDeleteTreeW /
;;;;            RegEnumKeyExW / RegEnumValueW / RegCloseKey; UTF-16 strings
;;;;            end to end, no code page.
;;;;   macOS:   CoreFoundation CFPreferences -- CFPreferencesCopyAppValue /
;;;;            SetAppValue / AppSynchronize / CopyKeyList, in the domain
;;;;            org.clautolisp.vl-registry with flat "REGPATH|VALUENAME" keys,
;;;;            exactly what /usr/bin/defaults wrote (stored values stay
;;;;            readable).
;;;;
;;;; The libraries are loaded on first use and every entry point is looked
;;;; up at RUN time (FOREIGN-SYMBOL-POINTER), so this file compiles and loads
;;;; on every host; only the platform's own branch is ever called. Values
;;;; are written as strings (REG_SZ); they are read by type, as both vendors
;;;; return them (probe-triage2, 2026-10-04): REG_SZ a string, REG_EXPAND_SZ
;;;; the string EXPANDED, REG_DWORD an integer, REG_MULTI_SZ (7 "s1" ...),
;;;; REG_BINARY (3 byte ...) -- see %REG-VALUE. CFString / CFNumber read as
;;;; strings.

(in-package #:clautolisp.cador)

;;; --- Libraries -------------------------------------------------------------

(cffi:define-foreign-library advapi32
  (:windows "advapi32.dll"))

(cffi:define-foreign-library kernel32
  (:windows "kernel32.dll"))

(cffi:define-foreign-library core-foundation
  (:darwin (:framework "CoreFoundation")))

(defvar *loaded-native-libraries* '())

(defun %native-entry (library name)
  "The address of the C function NAME in LIBRARY (loaded on first use)."
  (unless (member library *loaded-native-libraries*)
    (cffi:load-foreign-library library)
    (push library *loaded-native-libraries*))
  (or (cffi:foreign-symbol-pointer name :library library)
      (error "~A: no entry point ~A" library name)))

(defmacro %advapi (name return-type &rest arguments)
  "Call the advapi32 function NAME (stdcall on 32-bit Windows; the only
convention on 64-bit)."
  `(cffi:foreign-funcall-pointer (%native-entry 'advapi32 ,name)
                                 (:convention :stdcall)
                                 ,@arguments ,return-type))

(defmacro %kernel32 (name return-type &rest arguments)
  `(cffi:foreign-funcall-pointer (%native-entry 'kernel32 ,name)
                                 (:convention :stdcall)
                                 ,@arguments ,return-type))

(defmacro %cf (name return-type &rest arguments)
  `(cffi:foreign-funcall-pointer (%native-entry 'core-foundation ,name) ()
                                 ,@arguments ,return-type))

;;; --- Windows: advapi32 ------------------------------------------------------

(defconstant +error-success+ 0)
(defconstant +error-more-data+ 234)
(defconstant +error-no-more-items+ 259)
(defconstant +key-read+ #x20019)
(defconstant +key-write+ #x20006)
(defconstant +key-set-value+ #x0002)
(defconstant +reg-sz+ 1)
(defconstant +reg-expand-sz+ 2)
(defconstant +reg-binary+ 3)
(defconstant +reg-dword+ 4)
(defconstant +reg-multi-sz+ 7)

(defun %predefined-hkey (low32)
  "A predefined root key: the 32-bit constant SIGN-EXTENDED to a pointer, as
the Windows headers define it ((HKEY)(ULONG_PTR)((LONG)0x80000001))."
  (cffi:make-pointer (if (= 8 (cffi:foreign-type-size :pointer))
                         (logior #xFFFFFFFF00000000 low32)
                         low32)))

(defun %split-registry-path (key)
  "KEY (\"HKEY_CURRENT_USER\\\\Software\\\\x\" or \"HKCU\\\\...\") as (values
ROOT-HKEY SUBKEY), or NIL for an unknown root."
  (let* ((slash (position #\\ key))
         (root (subseq key 0 (or slash (length key))))
         (sub (if slash (subseq key (1+ slash)) ""))
         (low (cond ((member root '("HKEY_CLASSES_ROOT" "HKCR") :test #'string-equal) #x80000000)
                    ((member root '("HKEY_CURRENT_USER" "HKCU") :test #'string-equal) #x80000001)
                    ((member root '("HKEY_LOCAL_MACHINE" "HKLM") :test #'string-equal) #x80000002)
                    ((member root '("HKEY_USERS" "HKU") :test #'string-equal) #x80000003)
                    ((member root '("HKEY_CURRENT_CONFIG" "HKCC") :test #'string-equal) #x80000005))))
    (and low (values (%predefined-hkey low) sub))))

(defun %wide-alloc (string)
  "STRING as a NUL-terminated UTF-16LE foreign buffer; (values pointer
byte-count-including-terminator). Free with CFFI:FOREIGN-FREE."
  (let* ((octets (babel:string-to-octets string :encoding :utf-16le))
         (n (length octets))
         (buffer (cffi:foreign-alloc :uint8 :count (+ n 2) :initial-element 0)))
    (dotimes (i n) (setf (cffi:mem-aref buffer :uint8 i) (aref octets i)))
    (values buffer (+ n 2))))

(defmacro %with-wide ((var string) &body body)
  `(let ((,var (%wide-alloc ,string)))
     (unwind-protect (progn ,@body) (cffi:foreign-free ,var))))

(defun %wide-to-string (pointer byte-count)
  "The UTF-16LE text at POINTER, BYTE-COUNT bytes long, up to its first NUL."
  (let ((octets (make-array byte-count :element-type '(unsigned-byte 8))))
    (dotimes (i byte-count) (setf (aref octets i) (cffi:mem-aref pointer :uint8 i)))
    (let ((s (babel:octets-to-string octets :encoding :utf-16le :errorp nil)))
      (subseq s 0 (or (position (code-char 0) s) (length s))))))

(defun %reg-open (key access &key create)
  "An open HKEY for KEY with ACCESS (CREATE makes it), or NIL. Close it with
%REG-CLOSE."
  (multiple-value-bind (root sub) (%split-registry-path key)
    (when root
      (cffi:with-foreign-object (result :pointer)
        (%with-wide (wsub sub)
          (let ((status
                  (if create
                      (%advapi "RegCreateKeyExW" :long
                               :pointer root :pointer wsub :uint32 0
                               :pointer (cffi:null-pointer) :uint32 0 :uint32 access
                               :pointer (cffi:null-pointer) :pointer result
                               :pointer (cffi:null-pointer))
                      (%advapi "RegOpenKeyExW" :long
                               :pointer root :pointer wsub :uint32 0 :uint32 access
                               :pointer result))))
            (and (= status +error-success+) (cffi:mem-ref result :pointer))))))))

(defun %reg-close (hkey)
  (%advapi "RegCloseKey" :long :pointer hkey))

(defmacro %with-reg-key ((var key access &key create) &body body)
  `(let ((,var (%reg-open ,key ,access :create ,create)))
     (when ,var
       (unwind-protect (progn ,@body) (%reg-close ,var)))))

(defun %expand-environment-strings (string)
  "STRING with its %NAME% references expanded (ExpandEnvironmentStringsW)."
  (%with-wide (source string)
    (let ((needed (%kernel32 "ExpandEnvironmentStringsW" :uint32
                             :pointer source :pointer (cffi:null-pointer) :uint32 0)))
      (if (zerop needed)
          string
          (let ((buffer (cffi:foreign-alloc :uint16 :count needed :initial-element 0)))
            (unwind-protect
                 (if (zerop (%kernel32 "ExpandEnvironmentStringsW" :uint32
                                       :pointer source :pointer buffer :uint32 needed))
                     string
                     (%wide-to-string buffer (* 2 needed)))
              (cffi:foreign-free buffer)))))))

(defun %reg-value (type octets)
  "The vl-registry-read value of registry data OCTETS of TYPE, as both
vendors return it (probe-triage2: AutoCAD 2022 job 16923993438, BricsCAD V25
job 16923716756): REG_SZ a string; REG_EXPAND_SZ the string expanded
(\"%SystemRoot%\\TEMP\" read as \"C:\\WINDOWS\\TEMP\"); REG_DWORD an integer;
REG_MULTI_SZ (7 \"s1\" \"s2\" ...); REG_BINARY (3 BYTE ...) -- the AutoCAD
dialects keep the (3) alone, as AutoCAD does (BUILTIN-VL-REGISTRY-READ).
Another type is NIL."
  (flet ((text () (babel:octets-to-string octets :encoding :utf-16le :errorp nil)))
    (cond
      ((= type +reg-sz+)
       (let ((s (text))) (subseq s 0 (or (position (code-char 0) s) (length s)))))
      ((= type +reg-expand-sz+)
       (let ((s (text)))
         (%expand-environment-strings (subseq s 0 (or (position (code-char 0) s) (length s))))))
      ((= type +reg-dword+)
       (and (>= (length octets) 4)
            (let ((u (logior (aref octets 0) (ash (aref octets 1) 8)
                             (ash (aref octets 2) 16) (ash (aref octets 3) 24))))
              ;; AutoLISP integers are signed 32-bit.
              (if (>= u #x80000000) (- u #x100000000) u))))
      ((= type +reg-multi-sz+)
       (cons 7 (loop with s = (text)
                     for start = 0 then (1+ end)
                     for end = (or (position (code-char 0) s :start start) (length s))
                     for item = (subseq s start end)
                     until (string= item "")
                     collect item
                     while (< end (length s)))))
      ((= type +reg-binary+)
       (cons 3 (coerce octets 'list)))
      (t nil))))

(defun %reg-read (key value-name)
  "The value stored at VALUE-NAME (NIL: the default value) under KEY, read
by type (%REG-VALUE), or NIL."
  (%with-reg-key (hkey key +key-read+)
    (%with-wide (wname (or value-name ""))
      (cffi:with-foreign-objects ((type :uint32) (size :uint32))
        (setf (cffi:mem-ref size :uint32) 0)
        (let ((status (%advapi "RegQueryValueExW" :long
                               :pointer hkey :pointer wname :pointer (cffi:null-pointer)
                               :pointer type :pointer (cffi:null-pointer) :pointer size)))
          (when (= status +error-success+)
            ;; Read with a margin: a value can grow between the two calls.
            (loop for capacity = (+ (cffi:mem-ref size :uint32) 2) then (* 2 capacity)
                  repeat 4
                  do (let ((buffer (cffi:foreign-alloc :uint8 :count capacity
                                                              :initial-element 0)))
                       (unwind-protect
                            (progn
                              (setf (cffi:mem-ref size :uint32) capacity)
                              (let ((status (%advapi "RegQueryValueExW" :long
                                                     :pointer hkey :pointer wname
                                                     :pointer (cffi:null-pointer)
                                                     :pointer type :pointer buffer
                                                     :pointer size)))
                                (cond ((= status +error-success+)
                                       (return
                                         (let* ((n (cffi:mem-ref size :uint32))
                                                (octets (make-array n :element-type '(unsigned-byte 8))))
                                           (dotimes (i n)
                                             (setf (aref octets i) (cffi:mem-aref buffer :uint8 i)))
                                           (%reg-value (cffi:mem-ref type :uint32) octets))))
                                      ((/= status +error-more-data+) (return nil)))))
                         (cffi:foreign-free buffer))))))))))

(defun %reg-write (key value-name value)
  "Store the string VALUE (REG_SZ) at VALUE-NAME under KEY, creating the key.
Returns VALUE, or NIL on failure."
  (%with-reg-key (hkey key +key-write+ :create t)
    (%with-wide (wname (or value-name ""))
      (multiple-value-bind (data bytes) (%wide-alloc value)
        (unwind-protect
             (and (= +error-success+
                     (%advapi "RegSetValueExW" :long
                              :pointer hkey :pointer wname :uint32 0 :uint32 +reg-sz+
                              :pointer data :uint32 bytes))
                  value)
          (cffi:foreign-free data))))))

(defun %reg-delete (key value-name)
  "Delete VALUE-NAME under KEY, or -- VALUE-NAME NIL -- KEY with its values
and sub-keys. True when something was deleted."
  (if value-name
      (or (%with-reg-key (hkey key +key-set-value+)
            (%with-wide (wname value-name)
              (= +error-success+ (%advapi "RegDeleteValueW" :long
                                          :pointer hkey :pointer wname))))
          nil)
      (multiple-value-bind (root sub) (%split-registry-path key)
        (and root (plusp (length sub))
             (%with-wide (wsub sub)
               (= +error-success+ (%advapi "RegDeleteTreeW" :long
                                           :pointer root :pointer wsub)))
             ;; RegDeleteTreeW leaves the key itself on some versions.
             (progn (%with-wide (wsub sub)
                      (%advapi "RegDeleteKeyW" :long :pointer root :pointer wsub))
                    t)))))

(defun %reg-descendents (key value-names-p)
  "The names of KEY's values (VALUE-NAMES-P) or immediate sub-keys, sorted."
  (let ((names '()))
    (%with-reg-key (hkey key +key-read+)
      (let ((capacity 16384))
        (cffi:with-foreign-objects ((name :uint16 capacity) (length :uint32))
          (loop for index from 0
                do (setf (cffi:mem-ref length :uint32) capacity)
                   (let ((status
                           (if value-names-p
                               (%advapi "RegEnumValueW" :long
                                        :pointer hkey :uint32 index :pointer name
                                        :pointer length :pointer (cffi:null-pointer)
                                        :pointer (cffi:null-pointer) :pointer (cffi:null-pointer)
                                        :pointer (cffi:null-pointer))
                               (%advapi "RegEnumKeyExW" :long
                                        :pointer hkey :uint32 index :pointer name
                                        :pointer length :pointer (cffi:null-pointer)
                                        :pointer (cffi:null-pointer) :pointer (cffi:null-pointer)
                                        :pointer (cffi:null-pointer)))))
                     (cond ((= status +error-success+)
                            ;; LENGTH counts characters, NUL excluded.
                            (let ((entry (%wide-to-string name (* 2 (cffi:mem-ref length :uint32)))))
                              (unless (and value-names-p (string= entry ""))
                                (pushnew entry names :test #'string-equal))))
                           ((= status +error-more-data+))
                           (t (return))))))))
    (sort names #'string-lessp)))

;;; --- macOS: CoreFoundation CFPreferences -------------------------------------

(defparameter +defaults-domain+ "org.clautolisp.vl-registry")
(defconstant +cf-string-encoding-utf8+ #x08000100)
(defconstant +cf-number-sint64-type+ 4)
(defconstant +cf-number-float64-type+ 6)

(defun %dflt-key (key value-name)
  (format nil "~A|~A" key (or value-name "")))

(defun %cf-string (string)
  "A new CFString for STRING (CFRelease it)."
  (cffi:with-foreign-string (utf8 string :encoding :utf-8)
    (%cf "CFStringCreateWithCString" :pointer
         :pointer (cffi:null-pointer) :pointer utf8 :uint32 +cf-string-encoding-utf8+)))

(defun %cf-release (object)
  (unless (cffi:null-pointer-p object)
    (%cf "CFRelease" :void :pointer object)))

(defmacro %with-cf-strings (bindings &body body)
  "Bind each (VAR STRING) to a new CFString, released on exit."
  (if (null bindings)
      `(progn ,@body)
      (destructuring-bind ((var string) &rest more) bindings
        `(let ((,var (%cf-string ,string)))
           (unwind-protect (%with-cf-strings ,more ,@body)
             (%cf-release ,var))))))

(defun %cf-string-value (cfstring)
  "The Lisp string of CFSTRING."
  (let* ((length (%cf "CFStringGetLength" :long :pointer cfstring))
         (capacity (1+ (%cf "CFStringGetMaximumSizeForEncoding" :long
                            :long length :uint32 +cf-string-encoding-utf8+))))
    (cffi:with-foreign-pointer (buffer capacity)
      (and (/= 0 (%cf "CFStringGetCString" :uint8
                      :pointer cfstring :pointer buffer :long capacity
                      :uint32 +cf-string-encoding-utf8+))
           (cffi:foreign-string-to-lisp buffer :encoding :utf-8)))))

(defun %cf-value-string (object)
  "A CFString's text, or a CFNumber's in decimal (what `defaults read'
printed); NIL for other types."
  (let ((type (%cf "CFGetTypeID" :unsigned-long :pointer object)))
    (cond ((= type (%cf "CFStringGetTypeID" :unsigned-long))
           (%cf-string-value object))
          ((= type (%cf "CFNumberGetTypeID" :unsigned-long))
           (if (/= 0 (%cf "CFNumberIsFloatType" :uint8 :pointer object))
               (cffi:with-foreign-object (out :double)
                 (%cf "CFNumberGetValue" :uint8 :pointer object
                      :long +cf-number-float64-type+ :pointer out)
                 (princ-to-string (cffi:mem-ref out :double)))
               (cffi:with-foreign-object (out :int64)
                 (%cf "CFNumberGetValue" :uint8 :pointer object
                      :long +cf-number-sint64-type+ :pointer out)
                 (princ-to-string (cffi:mem-ref out :int64)))))
          (t nil))))

(defun %cf-global (name)
  "The value of the CoreFoundation global constant NAME (a CFStringRef)."
  (cffi:mem-ref (%native-entry 'core-foundation name) :pointer))

(defun %dflt-read (key value-name)
  (%with-cf-strings ((cfkey (%dflt-key key value-name)) (domain +defaults-domain+))
    (let ((value (%cf "CFPreferencesCopyAppValue" :pointer :pointer cfkey :pointer domain)))
      (unless (cffi:null-pointer-p value)
        (unwind-protect (%cf-value-string value)
          (%cf-release value))))))

(defun %dflt-set (flat-key value)
  "Set (VALUE a string) or remove (VALUE NIL) FLAT-KEY, and synchronize."
  (%with-cf-strings ((cfkey flat-key) (domain +defaults-domain+))
    (if value
        (%with-cf-strings ((cfvalue value))
          (%cf "CFPreferencesSetAppValue" :void
               :pointer cfkey :pointer cfvalue :pointer domain))
        (%cf "CFPreferencesSetAppValue" :void
             :pointer cfkey :pointer (cffi:null-pointer) :pointer domain))
    (/= 0 (%cf "CFPreferencesAppSynchronize" :uint8 :pointer domain))))

(defun %dflt-write (key value-name value)
  (and (%dflt-set (%dflt-key key value-name) value) value))

(defun %dflt-all-keys ()
  "Every stored flat key of the domain."
  (%with-cf-strings ((domain +defaults-domain+))
    (let ((array (%cf "CFPreferencesCopyKeyList" :pointer
                      :pointer domain
                      :pointer (%cf-global "kCFPreferencesCurrentUser")
                      :pointer (%cf-global "kCFPreferencesAnyHost"))))
      (unless (cffi:null-pointer-p array)
        (unwind-protect
             (loop for i below (%cf "CFArrayGetCount" :long :pointer array)
                   for item = (%cf "CFArrayGetValueAtIndex" :pointer :pointer array :long i)
                   for name = (%cf-string-value item)
                   when name collect name)
          (%cf-release array))))))

(defun %dflt-delete (key value-name)
  (if value-name
      (and (%dflt-read key value-name)
           (%dflt-set (%dflt-key key value-name) nil))
      (let ((prefix (concatenate 'string key "|")) (any nil))
        (dolist (k (%dflt-all-keys) any)
          (when (and (>= (length k) (length prefix))
                     (string-equal prefix k :end2 (length prefix)))
            (%dflt-set k nil)
            (setf any t))))))

(defun %dflt-descendents (key value-names-p)
  (let ((names '()))
    (dolist (k (%dflt-all-keys))
      (let ((bar (position #\| k :from-end t)))
        (when bar
          (let ((path (subseq k 0 bar)) (vname (subseq k (1+ bar))))
            (if value-names-p
                (when (string-equal path key) (pushnew vname names :test #'string-equal))
                (let ((prefix (concatenate 'string (string-right-trim "\\" key) "\\")))
                  (when (and (> (length path) (length prefix))
                             (string-equal prefix path :end2 (length prefix)))
                    (let ((rest (subseq path (length prefix))))
                      (pushnew (subseq rest 0 (position #\\ rest))
                               names :test #'string-equal)))))))))
    (sort names #'string-lessp)))
