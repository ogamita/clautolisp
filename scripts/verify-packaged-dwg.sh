#!/bin/bash
# Does a COMPLETE INSTALLED RELEASE find its native DWG libraries and use
# them, with nothing helping it?
#
# clautolisp-distributed-native-libraries-not-loaded: an installation that
# contained lib/clautolisp/<os>/<arch>/clal_dwg.so still answered "no writer
# codec registered for format :DWG", because the shipped program did not
# contain the code that registers the codec and because the only installed
# search candidate was derived from the ASDF SOURCES, which a
# programs+libraries release does not ship. Both are fixed; this is the
# check that says so from the outside, the way a user meets it:
#
#   - install programs + libraries into a prefix that DOES NOT EXIST yet
#     and whose path CONTAINS A SPACE;
#   - unset CLAUTOLISP_DWG_LIBDIR and every library-path variable;
#   - run the installed binary from an unrelated working directory;
#   - write a DWG through the drawing API and read it back.
#
# Then do it again after MOVING the prefix, because a release is staged,
# archived and unpacked somewhere else entirely: nothing may embed the
# path it was built at.
#
# Usage: scripts/verify-packaged-dwg.sh [workdir]
# The workdir defaults to a fresh directory under TMPDIR. Exits non-zero
# on the first failure, printing what it saw.
set -u

here=$(cd "$(dirname "$0")/.." && pwd)
work=${1:-$(mktemp -d "${TMPDIR:-/tmp}/clal-packaged-XXXXXX")}
prefix="$work/a prefix with spaces"
moved="$work/moved elsewhere"

say() { printf '%s\n' "packaged-dwg: $*"; }
fail() { printf '%s\n' "packaged-dwg: FAILED -- $*" >&2; exit 1; }

say "prefix: $prefix"
mkdir -p "$prefix" || fail "cannot create the prefix"

say "installing programs and libraries"
make -C "$here/clautolisp" install-programs install-libraries \
     PREFIX="$prefix" > "$work/install.log" 2>&1 ||
  { tail -20 "$work/install.log"; fail "make install failed"; }

# What a release carries: the program, and the platform's native libraries.
bin="$prefix/bin/clautolisp"
[ -x "$bin" ] || bin="$prefix/bin/clautolisp-sbcl"
[ -x "$bin" ] || fail "no installed clautolisp under $prefix/bin"
libs=$(find "$prefix/lib" -name 'clal_dwg.*' 2>/dev/null | head -1)
[ -n "$libs" ] || fail "the libraries archive installed no clal_dwg under $prefix/lib"
say "program: $bin"
say "native:  $libs"

probe="$work/probe.lsp"
cat > "$probe" <<'LISP'
(vl-load-com)
(setq d (vla-get-activedocument (vlax-get-acad-object)))
(setq ms (vla-get-modelspace d))
(vla-addline ms (vlax-3d-point 0.0 0.0 0.0) (vlax-3d-point 10.0 10.0 0.0))
(vla-saveas d (strcat (getenv "CLAL_PROBE_DIR") "/packaged.dwg"))
(princ "WROTE-DWG")
(princ)
LISP

run_probe() {
  # $1 = the program to run, $2 = where to write. No CLAUTOLISP_DWG_LIBDIR,
  # no LD_LIBRARY_PATH, and an unrelated current directory.
  ( cd / && \
    env -u CLAUTOLISP_DWG_LIBDIR -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH \
        CLAL_PROBE_DIR="$2" \
        "$1" -norc -q -l "$probe" 2>&1 )
}

say "running from / with no overrides"
out=$(run_probe "$bin" "$work") || true
printf '%s\n' "$out" | sed 's/^/packaged-dwg:   /'
case "$out" in
  *"no writer codec registered"*)
    fail "the codec is not registered in the shipped program" ;;
  *WROTE-DWG*) : ;;
  *) fail "the save did not report success" ;;
esac
[ -s "$work/packaged.dwg" ] || fail "no DWG was written"
say "wrote $(wc -c < "$work/packaged.dwg") bytes"

say "moving the prefix, to prove nothing embedded its path"
mv "$prefix" "$moved" || fail "cannot move the prefix"
bin2=${bin/$prefix/$moved}
out2=$(run_probe "$bin2" "$work") || true
printf '%s\n' "$out2" | sed 's/^/packaged-dwg:   /'
case "$out2" in
  *"no writer codec registered"*) fail "the relocated install lost its codec" ;;
  *WROTE-DWG*) : ;;
  *) fail "the relocated install did not save" ;;
esac

# An installation of the BINARIES ARCHIVE ALONE must say what is missing,
# not "no writer codec registered": the codec is there, the library is not.
bare="$work/binaries only"
say "installing the programs WITHOUT the libraries into: $bare"
mkdir -p "$bare" || fail "cannot create the bare prefix"
make -C "$here/clautolisp" install-programs PREFIX="$bare" \
     > "$work/install-bare.log" 2>&1 ||
  { tail -20 "$work/install-bare.log"; fail "make install-programs failed"; }
bin3="$bare/bin/clautolisp"
[ -x "$bin3" ] || bin3="$bare/bin/clautolisp-sbcl"
[ -x "$bin3" ] || fail "no installed clautolisp under $bare/bin"
[ -z "$(find "$bare/lib" -name 'clal_dwg.*' 2>/dev/null)" ] ||
  fail "install-programs should not have installed a native library"
# To exercise this the DEVELOPMENT TREE's copy has to be out of the way:
# the installed program still probes it, because the dev-tree candidate
# resolves through the ASDF system it was built from -- a path that does
# not exist on a machine which only unpacked a release. Move it aside and
# put it back, with a trap so an interrupted run restores it.
devshim=$(find "$here/clautolisp/drawing-dwg" -maxdepth 2 -name 'clal_dwg.*' | head -1)
restore_devshim() {
  if [ -n "${devshim:-}" ] && [ -f "$devshim.hidden-by-packaged-check" ]; then
    mv "$devshim.hidden-by-packaged-check" "$devshim"
    say "restored $devshim"
  fi
}
trap restore_devshim EXIT INT TERM
if [ -n "$devshim" ]; then
  mv "$devshim" "$devshim.hidden-by-packaged-check" || fail "cannot hide the dev shim"
  say "hid the development tree's $(basename "$devshim") for this case"
fi
out3=$(run_probe "$bin3" "$work") || true
printf '%s\n' "$out3" | sed 's/^/packaged-dwg:   /'
restore_devshim
trap - EXIT INT TERM
case "$out3" in
  *"no writer codec registered"*)
    fail "a binaries-only install must name the missing library, not the codec" ;;
  *"was not found"*)
    say "the missing library is named, with the paths tried" ;;
  *)
    fail "a binaries-only install must report the missing native library" ;;
esac

say "OK: a complete installed release writes a DWG, before and after being moved"
exit 0
