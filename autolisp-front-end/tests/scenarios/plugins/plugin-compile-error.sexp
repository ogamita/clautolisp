(:name "plugin-compile-error"
 :description "--compile-plugin on a file that is not there reports it on
standard error and exits EX_NOINPUT (66)."
 :classification :portable
 :argv ("--compile-plugin" "not-there.lisp")
 :expected-exit 66
 :expected-stderr-includes ("--compile-plugin")
 :covers-options ("--compile-plugin"))
