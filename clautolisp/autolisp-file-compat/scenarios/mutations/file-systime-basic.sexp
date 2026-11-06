(:name "file-systime-basic"
 :description "Return an eight-element file timestamp list (year month
day-of-week day-of-month hours minutes seconds milliseconds). Both
vendors' reference pages state seven elements, but every probed engine
-- AutoCAD 2022, BricsCAD V25 and V26 -- returns the trailing
milliseconds field, and the Bricsys page's own sample return shows
eight values under its seven-element format line. See
issues/open/vl-file-systime-parity.issue."
 :kind :builtin
 :classification :host-sensitive
 :tags (:builtin :file :systime)
 :setup-files ((:relative-path "stamp.txt" :input-text "stamp"))
 :builtin-name "VL-FILE-SYSTIME"
 :arguments ("stamp.txt")
 :expected-value (:predicate :list-length 8))
