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
