;;;; encoding-roundtrip.lsp — *AUTOLISP-FILE-ENCODING* write/load round-trip
;;;;
;;;; test-file-encodings.issue part 3: an AutoLISP program that loops over
;;;; the *AUTOLISP-FILE-ENCODING* values, writes a fixture in each, loads
;;;; it back under the SAME encoding, and checks the accented text
;;;; round-trips — plus the wrong-encoding error case. Pure-ASCII source
;;;; (the accent is built with (chr N)), so the source encoding cannot
;;;; confound the file encoding under test. clautolisp honours
;;;; *AUTOLISP-FILE-ENCODING* for BOTH the write (open "w" + princ) and
;;;; the read (load); this program asserts that symmetry.
;;;;
;;;; Last line: "ALL ENCODING ROUNDTRIP PASSED" or "ENCODING ROUNDTRIP
;;;; FAILED: <n>".

(setq *rt-pass* 0 *rt-fail* 0)

(defun chk (label ok / )
  (if ok (setq *rt-pass* (1+ *rt-pass*))
      (progn (setq *rt-fail* (1+ *rt-fail*))
             (princ (strcat "  FAIL " label "\n"))))
  ok)

;; The accented probe text: A <e-acute 233> <a-grave 224> B — code points
;; that exist in both UTF-8 and ISO-8859-1, so the round-trip is meaningful
;; for each. Built via (chr N) to keep THIS file pure ASCII.
(setq *accent* (strcat "A" (chr 233) (chr 224) "B"))

;; Fixture path. The FiveAM wrapper (encoding-roundtrip-tests.lisp) prepends
;; a (setq *rt-dir* "<abs-tmp-dir>/") so the fixture lives at a KNOWN
;; ABSOLUTE path. Earlier this program used the bare relative name
;; "enc-rt.lsp"; clautolisp's (load) resolves a bare name through the CWD
;; probe + support-search-path (resolve-load-pathname), which resolves
;; differently on Windows than the test's uiop:with-current-directory — so
;; the load threw there. An absolute path takes that resolution out of play.
;; Falls back to "" (the current directory) for a standalone run.
(if (null *rt-dir*) (setq *rt-dir* ""))
(setq *rt-file* (strcat *rt-dir* "enc-rt.lsp"))

;; decoded code points of S as "n n n" (diagnostic on failure); "nil" / a
;; type tag when S is not a string.
(defun rt-cp (s / i n out)
  (cond ((null s) "nil")
        ((/= (type s) 'STR) "not-a-string")
        (T (setq out "" i 1 n (strlen s))
           (while (<= i n)
             (setq out (strcat out (itoa (ascii (substr s i 1))) " "))
             (setq i (1+ i)))
           out)))

(defun write-fixture (path enc / f)
  (setq *AUTOLISP-FILE-ENCODING* enc)
  (setq f (open path "w"))
  ;; write:  (setq rt "A<é><à>B")   — the ASCII frame + the accented literal,
  ;; the whole line encoded in ENC.
  (princ (strcat "(setq rt \"" *accent* "\")\n") f)
  (close f))

;; load PATH under ENC, never throwing (a decode / resolution error just
;; leaves rt nil). Returns rt.
(defun load-fixture (path enc / )
  (setq *AUTOLISP-FILE-ENCODING* enc)
  (setq rt nil)
  (vl-catch-all-apply 'load (list path))
  rt)

(defun run-encoding-roundtrip ( / r)
  (princ "=== encoding round-trip ===\n")
  (princ (strcat "rt-file = " *rt-file* "\n"))
  ;; 1. same-encoding round-trip for each writable encoding
  (foreach enc '("UTF-8" "ISO-8859-1")
    (write-fixture *rt-file* enc)
    (setq r (load-fixture *rt-file* enc))
    (if (not (chk (strcat enc " write+load round-trips the accents")
                  (equal r *accent*)))
        (princ (strcat "    got cp: " (rt-cp r)
                       " (findfile: " (if (findfile *rt-file*) "yes" "NO") ")\n"))))
  ;; 2. wrong-encoding: bytes written UTF-8, read as US-ASCII -> the >127
  ;; bytes cannot decode, so load must FAIL (soft) and rt must NOT be set.
  (write-fixture *rt-file* "UTF-8")
  (setq *AUTOLISP-FILE-ENCODING* "US-ASCII" rt nil)
  (setq r (vl-catch-all-apply 'load (list *rt-file*)))
  (chk "UTF-8 bytes loaded as US-ASCII fail to decode"
       (or (vl-catch-all-error-p r) (not (equal rt *accent*))))
  ;; 3. wrong-encoding the other way: ISO-8859-1 é (0xE9) read as UTF-8 is
  ;; an invalid lead byte -> load fails too.
  (write-fixture *rt-file* "ISO-8859-1")
  (setq *AUTOLISP-FILE-ENCODING* "UTF-8" rt nil)
  (setq r (vl-catch-all-apply 'load (list *rt-file*)))
  (chk "ISO-8859-1 bytes loaded as UTF-8 fail to decode"
       (or (vl-catch-all-error-p r) (not (equal rt *accent*))))
  (princ (strcat "\nsummary: " (itoa *rt-pass*) " passed, " (itoa *rt-fail*) " failed\n"))
  (if (= *rt-fail* 0)
      (princ "ALL ENCODING ROUNDTRIP PASSED\n")
      (princ (strcat "ENCODING ROUNDTRIP FAILED: " (itoa *rt-fail*) "\n")))
  (princ))

(run-encoding-roundtrip)
