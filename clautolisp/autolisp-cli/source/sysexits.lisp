;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;
;;;; The process exit statuses of the clautolisp programs (clautolisp,
;;;; read-autolisp, alfe), in ONE table (sysexits-exit-statuses.issue).
;;;;
;;;; pjb, 2026-10-06: "unopenable -l is an error, exit status. [...] linux
;;;; defines sysexits.h with some "semistandard" exit codes for various
;;;; conditions. We should use them on all systems, if applicable."
;;;;
;;;; The values and their meanings are those of <sysexits.h> (BSD 4.3,
;;;; shipped by glibc, musl and the BSDs; see sysexits.h(3head)). They are
;;;; written out here rather than taken from the C header, so the programs
;;;; exit with the SAME status on every system -- MS-Windows included, which
;;;; has no such header: a script that tests for 66 works everywhere.
;;;;
;;;; Only the documented 64..78 are used; nothing is invented in that range.
;;;; Two statuses outside it are the programs' own, and are named here too:
;;;;
;;;;  - 1, +EXIT-AUTOLISP-ERROR+: the user's AutoLISP program failed (an
;;;;    uncaught runtime error). That is not a sysexits condition -- the
;;;;    command line, the input files and the engine were all fine; the
;;;;    program ran and failed, which is what 1 conventionally means (like
;;;;    a failing test or a `false').  A program's own (exit N) / (quit N) /
;;;;    (autolisp-set-status N) is passed through unchanged, and may of
;;;;    course be any value.
;;;;
;;;;  - 130, +EXIT-INTERRUPTED+: the run was interrupted by Control-C
;;;;    (SIGINT) and the policy was to quit. 128 + the signal number is the
;;;;    shell's convention for a death by signal, which is what the user
;;;;    sees from a shell either way.
;;;;
;;;; This file is its own small system (clautolisp/sysexits) with no
;;;; dependency, so that read-autolisp -- which does not carry the
;;;; evaluator -- shares the table.

(defpackage #:clautolisp.sysexits
  (:use #:cl)
  (:export #:+ex-ok+
           #:+ex-usage+
           #:+ex-dataerr+
           #:+ex-noinput+
           #:+ex-nouser+
           #:+ex-nohost+
           #:+ex-unavailable+
           #:+ex-software+
           #:+ex-oserr+
           #:+ex-osfile+
           #:+ex-cantcreat+
           #:+ex-ioerr+
           #:+ex-tempfail+
           #:+ex-protocol+
           #:+ex-noperm+
           #:+ex-config+
           #:+exit-autolisp-error+
           #:+exit-interrupted+
           #:*exit-statuses*
           #:exit-status-name
           #:exit-status-description))

(in-package #:clautolisp.sysexits)

(defconstant +ex-ok+          0  "EX_OK: successful termination.")
(defconstant +ex-usage+      64  "EX_USAGE: the command was used incorrectly (wrong number of arguments, a bad flag, a bad syntax in a parameter).")
(defconstant +ex-dataerr+    65  "EX_DATAERR: the input data was incorrect in some way (user data, not system files).")
(defconstant +ex-noinput+    66  "EX_NOINPUT: an input file (not a system file) did not exist or was not readable.")
(defconstant +ex-nouser+     67  "EX_NOUSER: the user specified did not exist.")
(defconstant +ex-nohost+     68  "EX_NOHOST: the host specified did not exist.")
(defconstant +ex-unavailable+ 69 "EX_UNAVAILABLE: a service is unavailable; a support program or file does not exist.")
(defconstant +ex-software+   70  "EX_SOFTWARE: an internal software error has been detected.")
(defconstant +ex-oserr+      71  "EX_OSERR: an operating system error (e.g. cannot fork, cannot create a pipe).")
(defconstant +ex-osfile+     72  "EX_OSFILE: some system file does not exist, cannot be opened, or has an error.")
(defconstant +ex-cantcreat+  73  "EX_CANTCREAT: a (user specified) output file cannot be created.")
(defconstant +ex-ioerr+      74  "EX_IOERR: an error occurred while doing I/O on some file.")
(defconstant +ex-tempfail+   75  "EX_TEMPFAIL: temporary failure; the user is invited to retry.")
(defconstant +ex-protocol+   76  "EX_PROTOCOL: the remote system returned something not possible during a protocol exchange.")
(defconstant +ex-noperm+     77  "EX_NOPERM: insufficient permission to perform the operation (not a file system problem).")
(defconstant +ex-config+     78  "EX_CONFIG: something was found in an unconfigured or misconfigured state.")

(defconstant +exit-autolisp-error+ 1
  "The user's AutoLISP program failed: an uncaught AutoLISP runtime error.
Not a sysexits condition (see the file header).")

(defconstant +exit-interrupted+ 130
  "Interrupted by Control-C (SIGINT) under the quit policy: 128 + SIGINT,
the shell's convention.")

(defparameter *exit-statuses*
  '((0   "EX_OK"          "success")
    (1   nil              "the AutoLISP program failed (uncaught runtime error)")
    (64  "EX_USAGE"       "command line usage error")
    (65  "EX_DATAERR"     "data format error")
    (66  "EX_NOINPUT"     "cannot open input")
    (67  "EX_NOUSER"      "addressee unknown")
    (68  "EX_NOHOST"      "host name unknown")
    (69  "EX_UNAVAILABLE" "service unavailable")
    (70  "EX_SOFTWARE"    "internal software error")
    (71  "EX_OSERR"       "system error (e.g., can't fork)")
    (72  "EX_OSFILE"      "critical OS file missing")
    (73  "EX_CANTCREAT"   "can't create (user) output file")
    (74  "EX_IOERR"       "input/output error")
    (75  "EX_TEMPFAIL"    "temp failure; user is invited to retry")
    (76  "EX_PROTOCOL"    "remote error in protocol")
    (77  "EX_NOPERM"      "permission denied")
    (78  "EX_CONFIG"      "configuration error")
    (130 nil              "interrupted (Control-C, SIGINT)"))
  "(STATUS SYSEXITS-NAME DESCRIPTION) for every status the programs choose
themselves. The sysexits descriptions are the comments of <sysexits.h>.")

(defun exit-status-name (status)
  "The <sysexits.h> name of STATUS (\"EX_NOINPUT\"), or NIL when STATUS is
not a sysexits code."
  (second (assoc status *exit-statuses*)))

(defun exit-status-description (status)
  "A short description of STATUS, or NIL when the programs never choose it."
  (third (assoc status *exit-statuses*)))
