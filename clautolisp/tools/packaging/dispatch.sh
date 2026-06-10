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
os=$(uname | tr 'A-Z' 'a-z')
arch=$(uname -m | tr 'A-Z' 'a-z')
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
