(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;;; Decoding a helper program's output (registry-api.lisp).
;;;;
;;;; Found by verify:vl-registry:windows on the French Windows runner
;;;; (2026-08-14): `reg.exe' answers in the console OEM code page, and
;;;; decoding that as UTF-8 does not merely garble it — it SIGNALS
;;;; (":UTF-8 stream decoding error … the octet sequence #(130) cannot be
;;;; decoded"), taking down every registry operation on that host.
;;;;
;;;; The code-page parsing is tested here rather than through a
;;;; subprocess, so it runs on every platform: `chcp' exists only on
;;;; Windows, but its answer is what the logic has to survive, and every
;;;; localisation of it can be exercised as a string.

(test chcp-code-page-parses-every-localisation
  "chcp answers in a localised sentence, so the parser must not depend on
any of the words — only on the trailing digits."
  (is (eql 850 (clautolisp.cador::%parse-chcp-code-page
                "Active code page: 850")))
  (is (eql 850 (clautolisp.cador::%parse-chcp-code-page
                "Page de codes active : 850")))     ; the runner that found it
  (is (eql 850 (clautolisp.cador::%parse-chcp-code-page
                "Aktive Codepage: 850")))
  (is (eql 65001 (clautolisp.cador::%parse-chcp-code-page
                  "Active code page: 65001")))
  ;; trailing whitespace / CR survives (the output is :stripped, but a CR
  ;; can still ride along on a Windows pipe)
  (is (eql 437 (clautolisp.cador::%parse-chcp-code-page
                (format nil "Active code page: 437~C" #\Return))))
  ;; a sentence naming a number FIRST must not win over the real one
  (is (eql 850 (clautolisp.cador::%parse-chcp-code-page
                "chcp 65001 failed; active code page: 850"))))

(test chcp-code-page-parse-degrades-instead-of-signalling
  "Anything unparsable yields NIL, never an error: this runs on the path
that exists because the environment is already not what we assumed."
  (is (null (clautolisp.cador::%parse-chcp-code-page "")))
  (is (null (clautolisp.cador::%parse-chcp-code-page "no digits here")))
  (is (null (clautolisp.cador::%parse-chcp-code-page nil))))

(test code-page-external-format-maps-the-oem-pages
  "The OEM pages a Windows console actually uses must map; an unknown page
must yield NIL so the caller falls back rather than inventing a format."
  (is (eq :cp850  (clautolisp.cador::%code-page-external-format 850)))
  (is (eq :cp437  (clautolisp.cador::%code-page-external-format 437)))
  (is (eq :utf-8  (clautolisp.cador::%code-page-external-format 65001)))
  (is (eq :cp1252 (clautolisp.cador::%code-page-external-format 1252)))
  (is (null (clautolisp.cador::%code-page-external-format 12345))))

(test subprocess-external-format-is-utf-8-off-windows
  "Off Windows the behaviour is unchanged — /usr/bin/defaults writes UTF-8.
Guards against the fix leaking a Windows assumption onto macOS/Linux."
  (let ((clautolisp.cador::*subprocess-external-format* :unresolved))
    (is (eq (if (uiop:os-windows-p)
                (clautolisp.cador::%subprocess-external-format)
                :utf-8)
            (clautolisp.cador::%subprocess-external-format)))))

(test subprocess-external-format-is-cached
  "The code page is a per-machine property; resolving it costs a
subprocess, so it must be resolved once and not once per registry read."
  (let ((clautolisp.cador::*subprocess-external-format* :sentinel))
    (is (eq :sentinel (clautolisp.cador::%subprocess-external-format)))))
