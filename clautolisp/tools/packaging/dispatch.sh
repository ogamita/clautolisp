#!/bin/sh
# Relocatable launcher for the clautolisp/alfe binaries.
#
# Installed as $PREFIX/bin/<prog> (clautolisp, alfe, read-autolisp, …),
# this script dispatches to the per-platform, per-Lisp binary under
#   $PREFIX/libexec/clautolisp/binaries/<os>/<arch>/<prog>-<lisp>
# It derives $PREFIX from its own location, so the install tree is
# relocatable (no absolute paths baked in).
#
# Lisp implementation selection (downcased): the per-program override
# (ALFE_LISP for alfe), else CLAUTOLISP_LISP, else sbcl.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
prefix=$(CDPATH= cd -- "$here/.." && pwd)
# Canonical os linux/darwin/windows and arch x86-64 / arm64 (must match
# Makefile REL_OS/REL_ARCH and drawing-dwg/source/bindings.lisp %os/%arch).
os=$(uname | tr 'A-Z' 'a-z' | sed -e 's/^mingw.*/windows/' -e 's/^msys.*/windows/' -e 's/^cygwin.*/windows/')
arch=$(uname -m | tr 'A-Z' 'a-z' | sed -e 's/^x86_64$/x86-64/' -e 's/^amd64$/x86-64/' -e 's/^aarch64$/arm64/')
prog=$(basename -- "$0")

lisp=${CLAUTOLISP_LISP:-sbcl}
case "$prog" in
  alfe) lisp=${ALFE_LISP:-$lisp} ;;
esac

bin="$prefix/libexec/clautolisp/binaries/$os/$arch/$prog-$lisp"
if [ ! -x "$bin" ]; then
  echo "$prog: no binary for $os/$arch with lisp=$lisp" >&2
  echo "  expected: $bin" >&2
  exit 127
fi
exec "$bin" "$@"
