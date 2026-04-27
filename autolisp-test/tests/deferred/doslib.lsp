;;;; tests/deferred/doslib.lsp -- DOS_* (DOSLib third-party extension)
;;;;
;;;; DOSLib is Windows-oriented and ships separately. Tests are tagged
;;;; (windows doslib) so non-Windows targets see NOT-APPLICABLE.

(deftest-skip "dos_alert-deferred"
  '((operator . "DOS_ALERT") (area . "doslib") (profile . strict)
    (platform-tags . (windows)) (runtime-tags . (doslib)))
  '(dos_alert "msg")
  "deferred: requires DOSLib runtime")

(deftest-skip "dos_strtokens-deferred"
  '((operator . "DOS_STRTOKENS") (area . "doslib") (profile . strict)
    (platform-tags . (windows)) (runtime-tags . (doslib)))
  '(dos_strtokens "a,b,c" ",")
  "deferred: requires DOSLib runtime")

(deftest-skip "dos_filename-deferred"
  '((operator . "DOS_FILENAME") (area . "doslib") (profile . strict)
    (platform-tags . (windows)) (runtime-tags . (doslib)))
  '(dos_filename "/path/to/file.lsp")
  "deferred: requires DOSLib runtime")

(deftest-skip "dos_pathname-deferred"
  '((operator . "DOS_PATHNAME") (area . "doslib") (profile . strict)
    (platform-tags . (windows)) (runtime-tags . (doslib)))
  '(dos_pathname "/path/to/file.lsp")
  "deferred: requires DOSLib runtime")
