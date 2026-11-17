#!/bin/bash
# Build cadgui-dev.image: an ECL development image with clautolisp/cadgui frozen
# in, starting on the REPL (ecl skill EC10). Builds COLD -- the ecl-* fasl cache
# is cleared first so make-build's own ASDF planning does not hit the warm-cache
# PLAN::STAMP C-stack overflow. The resulting image never plans against the
# cache at runtime (the closure is linked in + registered immutable), so it
# starts instantly and (load "file.lisp") reloads just the edited file.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"             # .../clautolisp (holds clautolisp.asd)
export CADGUI_CLAUTOLISP_DIR="$root"
echo "build-dev-image: clearing the ecl-* asdf cache for a clean cold build ..."
rm -rf "$HOME/.cache/common-lisp/ecl-"* 2>/dev/null || true
{ ulimit -s 262144 2>/dev/null || ulimit -s 131072 2>/dev/null || ulimit -s 65536 2>/dev/null || true; }
cd "$root" || exit 3
exec ecl --norc --load "$here/build-dev-image.lisp" </dev/null
