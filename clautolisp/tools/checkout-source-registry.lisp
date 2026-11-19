;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;
;;;; checkout-source-registry.lisp -- make the systems of THIS tree win
;;;; over any other copy ASDF's inherited source-registry can see.
;;;;
;;;; issues/closed/make-test-loads-installed-clautolisp.issue: the test
;;;; and build images load the checkout's clautolisp.asd with
;;;; ASDF:LOAD-ASD, but ASDF:FIND-SYSTEM searches the source-registry
;;;; BEFORE it looks at what is already registered, and reloads the .asd
;;;; from the registry when the paths differ. So when the inherited
;;;; registry reaches an installed copy -- XDG_DATA_DIRS=/opt/local/share
;;;; (share/common-lisp/systems/clautolisp.asd and the source/ tree), the
;;;; XDG_CONFIG_DIRS=/opt/local/etc that 50-clautolisp.conf asks for, a
;;;; CL_SOURCE_REGISTRY -- the image silently runs the INSTALLED sources:
;;;; on poseidon, `make test' ran 2.4.16's suite against 2.4.16's data-less
;;;; install while testing a 2.4.33 checkout (41 cador failures).
;;;;
;;;; Load this file after (require :asdf) and before the first LOAD-ASD.
;;;; It re-initialises the source-registry with this tree's systems FIRST
;;;; (the first registry entry naming a system wins), then everything that
;;;; was inherited, so third-party systems are still found as before:
;;;;
;;;;   - the clautolisp subproject as a :tree (clautolisp.asd, and
;;;;     tui-core.asd, clautolisp-tui-curses.asd, clautolisp-charms.asd in
;;;;     their subdirectories), minus the directories that hold no system
;;;;     of ours but are large to walk (vendored C, cmake builds, the fasl
;;;;     cache);
;;;;   - the sibling subprojects autolisp-front-end/ and autolisp-test/ as
;;;;     plain :directory entries (their .asd is at their root; absent in
;;;;     an installed tree, where they are simply not found).
;;;;
;;;; The paths come from *LOAD-TRUENAME*, never from the Makefile: under
;;;; MSYS2 `pwd' spells /c/..., which a native Windows Lisp cannot parse.
;;;; Being a .lisp file it is installed with the systems too, where it does
;;;; the same thing relative to the installed tree.

(in-package "COMMON-LISP-USER")

(let* ((tools      (uiop:pathname-directory-pathname *load-truename*))
       (subproject (uiop:pathname-parent-directory-pathname tools))
       (repository (uiop:pathname-parent-directory-pathname subproject)))
  (asdf:initialize-source-registry
   `(:source-registry
     (:also-exclude "third-party" "build" ".cache")
     (:tree ,subproject)
     (:directory ,(merge-pathnames #P"autolisp-front-end/" repository))
     (:directory ,(merge-pathnames #P"autolisp-test/" repository))
     :inherit-configuration)))

;;;; THE END ;;;;
