#!/usr/bin/env bash
# Produce a truly-empty DWG (0 graphical entities) that AutoCAD / BricsCAD open,
# using clautolisp's OWN drawing-dwg codec (libredwg) -- no CAD needed, portable.
#
#   scripts/make-empty-dwg.sh <base.dwg> <out.dwg>
#
# It reads <base.dwg> (any valid DWG -- a libredwg sample, a CAD template, or a
# CONTAMINATED empty.dwg you want to clean), removes every graphical entity
# while keeping the standard table/block/dictionary structure libredwg (and the
# CADs) require, and writes <out.dwg>. The output is R2000 (AC1015) format.
#
# Why: the vendor probes copy c:/gitlab-runner/dwg/empty.dwg per run; if that
# file isn't actually empty (stray entities from an old ._QSAVE) the selection
# counts are poisoned. Regenerate a clean one with this, e.g.:
#   scripts/make-empty-dwg.sh /c/gitlab-runner/dwg/empty.dwg /c/gitlab-runner/dwg/empty.dwg
# (The probes also self-clean at seed time -- see clean-slate in
# selection-probe.lsp -- so this is belt-and-suspenders / canonical test data.)
#
# A null (make-drawing) drawing can't be written -- libredwg needs the standard
# tables -- so a structural base DWG is required. Needs the drawing-dwg library
# built (make -C .. build-libraries) and a DWG-capable SBCL.
set -eu

base="${1:?usage: make-empty-dwg.sh <base.dwg> <out.dwg>}"
out="${2:?usage: make-empty-dwg.sh <base.dwg> <out.dwg>}"
root="${CI_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

[ -f "$base" ] || { echo "base DWG not found: $base" >&2; exit 2; }

tmp="$(mktemp "${TMPDIR:-/tmp}/mkempty.XXXXXX.lisp")"
trap 'rm -f "$tmp"' EXIT
cat > "$tmp" <<LISP
(require :asdf)
(asdf:initialize-source-registry
 (list :source-registry (list :tree (truename "$root/")) :inherit-configuration))
(handler-case
    (progn
      (asdf:load-system "clautolisp/drawing-dwg")
      (let* ((p  (find-package "CLAUTOLISP.DRAWING"))
             (rd (find-symbol "READ-DRAWING" p))
             (wr (find-symbol "WRITE-DRAWING" p))
             (es (find-symbol "DRAWING-ENTITIES" p))
             (gp (find-symbol "GRAPHICAL-ENTITY-P" p))
             (ec (find-symbol "DRAWING-ENTITY-COUNT" p))
             (d  (funcall rd "$base"))
             (rm '()))
        (maphash (lambda (h e) (when (funcall gp e) (push h rm))) (funcall es d))
        (dolist (h rm) (remhash h (funcall es d)))
        (funcall wr d "$out" :format :dwg)
        (format t "~&make-empty-dwg: wrote ~A (removed ~D graphical entities; count now ~D)~%"
                "$out" (length rm) (funcall ec d))))
  (error (e) (format t "~&make-empty-dwg ERROR: ~A~%" e) (sb-ext:exit :code 1)))
LISP

sbcl --non-interactive --load "$tmp"
