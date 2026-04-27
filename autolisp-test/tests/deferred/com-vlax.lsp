;;;; tests/deferred/com-vlax.lsp -- VLAX/VLA COM bridge
;;;;
;;;; COM bridge tests require Windows + a real ActiveX-capable host
;;;; (or a clautolisp COM emulation that does not yet exist). All
;;;; entries are tagged (com vlax/vla) and platform (windows) so they
;;;; show NOT-APPLICABLE on Linux/macOS or non-COM-capable hosts.

(deftest-skip "vlax-create-object-deferred"
  '((operator . "VLAX-CREATE-OBJECT") (area . "vlax") (profile . strict)
    (platform-tags . (windows)) (runtime-tags . (com vlax)))
  '(vlax-create-object "Excel.Application")
  "deferred: requires Windows host with ActiveX")

(deftest-skip "vlax-get-object-deferred"
  '((operator . "VLAX-GET-OBJECT") (area . "vlax") (profile . strict)
    (platform-tags . (windows)) (runtime-tags . (com vlax)))
  '(vlax-get-object "Excel.Application")
  "deferred: requires Windows host with ActiveX")

(deftest-skip "vlax-get-property-deferred"
  '((operator . "VLAX-GET-PROPERTY") (area . "vlax") (profile . strict)
    (platform-tags . (windows)) (runtime-tags . (com vlax)))
  '(vlax-get-property nil 'name)
  "deferred: requires Windows host with ActiveX")

(deftest-skip "vlax-put-property-deferred"
  '((operator . "VLAX-PUT-PROPERTY") (area . "vlax") (profile . strict)
    (platform-tags . (windows)) (runtime-tags . (com vlax)))
  '(vlax-put-property nil 'name "value")
  "deferred: requires Windows host with ActiveX")

(deftest-skip "vlax-invoke-method-deferred"
  '((operator . "VLAX-INVOKE-METHOD") (area . "vlax") (profile . strict)
    (platform-tags . (windows)) (runtime-tags . (com vlax)))
  '(vlax-invoke-method nil 'doSomething)
  "deferred: requires Windows host with ActiveX")

(deftest-skip "vla-get-application-deferred"
  '((operator . "VLA-GET-APPLICATION") (area . "vla") (profile . strict)
    (platform-tags . (windows)) (runtime-tags . (com vla)))
  '(vla-get-application nil)
  "deferred: requires Windows host with ActiveX")
