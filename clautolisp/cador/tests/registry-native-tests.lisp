(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;;; The host-independent parts of the native registry backends
;;;; (registry-native.lisp). The advapi32 and CFPreferences calls themselves
;;;; run on Windows / macOS only: scripts/verify-vl-registry.lisp, the
;;;; verify:vl-registry:windows / :macos CI jobs.

(test registry-path-roots-parse-in-both-spellings
  (multiple-value-bind (root sub)
      (clautolisp.cador::%split-registry-path "HKEY_CURRENT_USER\\Software\\clautolisp")
    (is (not (null root)))
    (is (string= "Software\\clautolisp" sub)))
  (multiple-value-bind (root sub)
      (clautolisp.cador::%split-registry-path "HKLM\\SOFTWARE")
    (is (not (null root)))
    (is (string= "SOFTWARE" sub)))
  (is (string= "" (nth-value 1 (clautolisp.cador::%split-registry-path "HKCU"))))
  (is (null (clautolisp.cador::%split-registry-path "HKEY_NOWHERE\\x"))))

(test predefined-root-keys-are-sign-extended
  ;; (HKEY)(ULONG_PTR)((LONG)0x80000001): on a 64-bit Lisp the high half is
  ;; all ones -- a zero-extended handle names no root key.
  (let ((address (cffi:pointer-address (clautolisp.cador::%predefined-hkey #x80000001))))
    (if (= 8 (cffi:foreign-type-size :pointer))
        (is (= #xFFFFFFFF80000001 address))
        (is (= #x80000001 address)))))

(test wide-strings-round-trip-with-a-two-byte-terminator
  (dolist (text '("" "LISPSYS" "Opération terminée" "中国 €"))
    (multiple-value-bind (pointer bytes) (clautolisp.cador::%wide-alloc text)
      (unwind-protect
           (progn
             ;; UTF-16LE plus a NUL code unit.
             (is (= bytes (+ 2 (length (babel:string-to-octets text :encoding :utf-16le)))))
             (is (zerop (cffi:mem-aref pointer :uint8 (- bytes 1))))
             (is (zerop (cffi:mem-aref pointer :uint8 (- bytes 2))))
             (is (string= text (clautolisp.cador::%wide-to-string pointer bytes))))
        (cffi:foreign-free pointer)))))

(test registry-values-read-by-type
  ;; What vl-registry-read returns per registry type, as AutoCAD 2022 and
  ;; BricsCAD V25 do (probe-triage2, jobs 16923993438 / 16923716756).
  (flet ((utf16 (string)
           (babel:string-to-octets string :encoding :utf-16le))
         (octets (&rest bytes)
           (make-array (length bytes) :element-type '(unsigned-byte 8)
                                      :initial-contents bytes)))
    (is (equal "abc" (clautolisp.cador::%reg-value 1 (utf16 (format nil "abc~C" (code-char 0))))))
    (is (eql 0 (clautolisp.cador::%reg-value 4 (octets 0 0 0 0))))
    (is (eql 1 (clautolisp.cador::%reg-value 4 (octets 1 0 0 0))))
    (is (eql -1 (clautolisp.cador::%reg-value 4 (octets 255 255 255 255))))
    (is (equal '(7 "System Reserved" "EMS")
               (clautolisp.cador::%reg-value
                7 (utf16 (format nil "System Reserved~CEMS~C~C"
                                 (code-char 0) (code-char 0) (code-char 0))))))
    (is (equal '(3 158 62 7) (clautolisp.cador::%reg-value 3 (octets 158 62 7))))
    (is (null (clautolisp.cador::%reg-value 11 (octets 1 0 0 0 0 0 0 0))))
    ;; The AutoLISP value: AutoCAD keeps REG_BINARY's type code alone.
    (is (equal '(3) (clautolisp.autolisp-builtins-core::%registry-value->autolisp
                     '(3 158 62 7) :autocad)))
    (is (equal '(3 158 62 7) (clautolisp.autolisp-builtins-core::%registry-value->autolisp
                              '(3 158 62 7) :bricscad)))
    (is (eql 1 (clautolisp.autolisp-builtins-core::%registry-value->autolisp 1 :autocad)))
    (let ((multi (clautolisp.autolisp-builtins-core::%registry-value->autolisp
                  '(7 "a" "b") :bricscad)))
      (is (eql 7 (first multi)))
      (is (equal '("a" "b")
                 (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value (rest multi)))))))

