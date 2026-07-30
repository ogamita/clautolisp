(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; The `..'-path portability warning (cad-path-dotdot-resolution).
;;;;
;;;; `..' resolution is not portable: POSIX hosts (clautolisp everywhere,
;;;; BricsCAD on macOS) walk the tree physically (UP), Windows CADs
;;;; collapse `..' textually (BACK), and the two disagree once a symbolic
;;;; link precedes the `..'. So open / findfile / load warn on any path
;;;; with a `..' component in every dialect EXCEPT --lax. Probed matrix
;;;; and decision: see the issue.

;;; --- the pure component predicate -------------------------------------

(test path-dotdot-predicate-detects-real-components
  (flet ((hit (p) (clautolisp.autolisp-runtime:autolisp-path-has-dotdot-component-p p)))
    ;; positives — `..' is a whole path component (either separator)
    (is (hit ".."))
    (is (hit "../x"))
    (is (hit "a/../b"))
    (is (hit "a/b/.."))
    (is (hit "/abs/../x"))
    (is (hit "a\\..\\b"))
    (is (hit "C:\\t\\..\\u"))
    ;; negatives — `..' only as a substring, or no `..' at all
    (is (not (hit "a..b")))
    (is (not (hit "..foo")))
    (is (not (hit "foo..")))
    (is (not (hit "a/b/c.txt")))
    (is (not (hit "")))
    (is (not (hit "dotdot/notup.txt")))))

;;; --- the dialect-gated warning ----------------------------------------

(defun %set-test-dialect (name)
  "Point the current session's dialect at the descriptor named NAME."
  (clautolisp.autolisp-runtime:set-runtime-session-dialect
   (clautolisp.autolisp-runtime:evaluation-context-session
    (clautolisp.autolisp-runtime:current-evaluation-context))
   (clautolisp.autolisp-reader:find-autolisp-dialect name)))

(defun %warning-for (dialect path who)
  "Run WHO's emitter for PATH under DIALECT and return what reached
*ERROR-OUTPUT* (fresh session per call, so dedup never masks the result)."
  (setup-mock-evaluation-context)
  (%set-test-dialect dialect)
  (let ((*error-output* (make-string-output-stream)))
    (clautolisp.autolisp-runtime:emit-dotdot-path-portability-warning path who)
    (get-output-stream-string *error-output*)))

(test path-dotdot-warns-in-strict-and-vendor-and-clautolisp
  (dolist (dialect '("strict" "autocad-2026" "bricscad-v26" "clautolisp"))
    (is (search "path-dotdot" (%warning-for dialect "a/sub/../t.txt" "FINDFILE"))
        "dialect ~A should warn on a ..-path" dialect)))

(test path-dotdot-silent-in-lax
  (is (zerop (length (%warning-for "lax" "a/sub/../t.txt" "OPEN")))))

(test path-dotdot-silent-on-clean-path
  (is (zerop (length (%warning-for "strict" "a/sub/t.txt" "OPEN")))))

(test path-dotdot-deduped-per-path-per-session
  (setup-mock-evaluation-context)
  (%set-test-dialect "strict")
  (let ((*error-output* (make-string-output-stream)))
    ;; same path twice -> one warning; a different ..-path -> another
    (clautolisp.autolisp-runtime:emit-dotdot-path-portability-warning "a/../t.txt" "OPEN")
    (clautolisp.autolisp-runtime:emit-dotdot-path-portability-warning "a/../t.txt" "OPEN")
    (clautolisp.autolisp-runtime:emit-dotdot-path-portability-warning "b/../u.txt" "OPEN")
    (let ((n (with-input-from-string
                 (s (get-output-stream-string *error-output*))
               (loop for line = (read-line s nil) while line
                     count (search "path-dotdot" line)))))
      (is (eql 2 n)))))

(test path-dotdot-fires-through-builtin-findfile
  (setup-mock-evaluation-context)
  (%set-test-dialect "strict")
  (let ((*error-output* (make-string-output-stream)))
    ;; the target need not exist — the warning is about the path shape
    (clautolisp.autolisp-builtins-core::builtin-findfile
     (clautolisp.autolisp-runtime:make-autolisp-string "no/such/../file.txt"))
    (is (search "path-dotdot" (get-output-stream-string *error-output*)))))
