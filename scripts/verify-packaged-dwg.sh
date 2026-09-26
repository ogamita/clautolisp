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
# On MS-WINDOWS there is one more rule to check, and it is the reason the
# layout has two files: a DLL carries no rpath, so clal_dwg.dll's import of
# libredwg.dll is NOT resolved by the loader just because the two sit in the
# same directory. The Lisp side pre-loads libredwg.dll by absolute path and
# reports "installed but its dependency libredwg.dll is not beside it" as its
# own case -- so this script installs the libraries, removes libredwg.dll, and
# insists on that message rather than a codec complaint. Runs under MSYS2 bash
# there (scripts/avec-bash.ps1 does the PowerShell handoff), which is why this
# stayed one script instead of being reimplemented in PowerShell.
#
# Usage: scripts/verify-packaged-dwg.sh [workdir]
# The workdir defaults to a fresh directory under TMPDIR. Exits non-zero
# on the first failure, printing what it saw.
set -u

here=$(cd "$(dirname "$0")/.." && pwd)

# Windows names programs with .exe, and `test -x' does not append it -- so
# the binary must be looked up under both spellings.
case $(uname -s 2>/dev/null) in
  MINGW*|MSYS*|CYGWIN*) host_os=windows; exe=.exe ;;
  Darwin)               host_os=macos;   exe= ;;
  *)                    host_os=linux;   exe= ;;
esac
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
bin="$prefix/bin/clautolisp$exe"
[ -x "$bin" ] || bin="$prefix/bin/clautolisp-sbcl$exe"
[ -x "$bin" ] || fail "no installed clautolisp under $prefix/bin"
libs=$(find "$prefix/lib" -name 'clal_dwg.*' 2>/dev/null | head -1)
[ -n "$libs" ] || fail "the libraries archive installed no clal_dwg under $prefix/lib"
say "program: $bin"
say "native:  $libs"

# HIDE THE DEVELOPMENT TREE'S SHIM FOR THE WHOLE CHECK, not just the
# binaries-only case at the end. The question this script asks is what a
# machine that only unpacked a RELEASE does, and such a machine has no
# checkout: the dev-tree candidate resolves through the ASDF system the image
# was built from, a path that does not exist there. On a CI machine it DOES
# exist, so leaving it in place let the program load the dev copy and the check
# proved nothing about the installed one -- silently on Linux, where that copy's
# rpath resolves its dependency, and with a confusing failure on MS-Windows,
# where it does not (the Windows run of 2026-09-26 that found this).
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
  say "hid the development tree's $(basename "$devshim") for the whole check"
fi

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
bin3="$bare/bin/clautolisp$exe"
[ -x "$bin3" ] || bin3="$bare/bin/clautolisp-sbcl$exe"
[ -x "$bin3" ] || fail "no installed clautolisp under $bare/bin"
[ -z "$(find "$bare/lib" -name 'clal_dwg.*' 2>/dev/null)" ] ||
  fail "install-programs should not have installed a native library"
# The development tree's copy is already hidden -- for the whole check, from
# the top -- so this case needs no hide/restore of its own. It did when only
# this case depended on it, which is exactly what let the earlier cases pass
# while loading the dev copy.
out3=$(run_probe "$bin3" "$work") || true
printf '%s\n' "$out3" | sed 's/^/packaged-dwg:   /'
case "$out3" in
  *"no writer codec registered"*)
    fail "a binaries-only install must name the missing library, not the codec" ;;
  *"was not found"*)
    say "the missing library is named, with the paths tried" ;;
  *)
    fail "a binaries-only install must report the missing native library" ;;
esac

# MS-WINDOWS ONLY: the shim without its dependency. The two files are not
# interchangeable halves of one thing -- clal_dwg.dll IMPORTS libredwg.dll,
# and a DLL has no rpath, so shipping one without the other cannot work. The
# program must say which file is missing (and that the archive carries both),
# not blame the codec. The relocated prefix is the one still installed here.
if [ "$host_os" = windows ]; then
  dep=$(find "$moved/lib" -name 'libredwg*.dll' 2>/dev/null | head -1)
  if [ -z "$dep" ]; then
    say "NOTE: no libredwg*.dll under $moved/lib -- the libraries phase did not"
    say "      install the runtime, so the dependency case cannot be exercised;"
    say "      that is itself a packaging failure on this platform"
    fail "the libraries archive shipped clal_dwg.dll without libredwg.dll"
  fi
  say "removing $(basename "$dep") to check the dependency is named"
  rm -f "$dep" || fail "cannot remove $dep"
  out4=$(run_probe "$bin2" "$work") || true
  printf '%s\n' "$out4" | sed 's/^/packaged-dwg:   /'
  case "$out4" in
    *"dependency libredwg.dll is not beside it"*)
      say "the missing dependency is named, with the directory looked in" ;;
    *"no writer codec registered"*)
      fail "a shim without libredwg.dll must name the dependency, not the codec" ;;
    *WROTE-DWG*)
      # Not a pass: it means the loader found libredwg.dll somewhere else
      # (MSYS2's mingw64 bin on PATH, say), so this run proves nothing about
      # what a user's machine would do.
      fail "the save succeeded without libredwg.dll beside the shim -- the loader ~
found one elsewhere on PATH, so this check cannot conclude; run it with a PATH ~
that has no libredwg.dll on it" ;;
    *)
      fail "a shim without libredwg.dll must report the missing dependency" ;;
  esac
fi

say "OK: a complete installed release writes a DWG, before and after being moved"
exit 0
