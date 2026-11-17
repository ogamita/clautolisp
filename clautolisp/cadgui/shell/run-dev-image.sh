#!/bin/bash
# Run cadgui-dev.image (built by build-dev-image.sh): an ECL REPL with the whole
# clautolisp/cadgui closure frozen in. Sets the finite large stack and points at
# the source-built ECL's libdir so libecl.so resolves. Reads REPL forms from
# stdin / args, exactly like `ecl`.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
img="$here/cadgui-dev.image"
ecllib="${ECL_LIBDIR:-/home/claude/opt/ecl-24.5.10/lib}"
if [ ! -x "$img" ]; then echo "run-dev-image: $img not found -- run build-dev-image.sh"; exit 2; fi
{ ulimit -s 262144 2>/dev/null || ulimit -s 131072 2>/dev/null || ulimit -s 65536 2>/dev/null || true; }
export LD_LIBRARY_PATH="$ecllib:${LD_LIBRARY_PATH:-}"
exec "$img" "$@"
