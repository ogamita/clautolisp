#!/bin/sh
# ci-build-cache.sh -- CONTENT-KEYED build caches for CI
# (issues/open/ci-cache-tool-builds.issue).
#
#   sh scripts/ci-build-cache.sh restore fasl|libredwg   first thing in a job
#   sh scripts/ci-build-cache.sh save    fasl|libredwg   last thing in a job
#   sh scripts/ci-build-cache.sh key     fasl|libredwg   print the key
#   sh scripts/ci-build-cache.sh inputs  fasl|libredwg   print what is hashed
#
# Run from the repository root (CI_PROJECT_DIR). The GitLab `cache:' of the
# job holds .ci-cache/<kind>/ and nothing else; this script moves the build
# products between that directory and the place the build expects them.
#
# WHY NOT A PLAIN GitLab cache OF THE BUILD DIRECTORY
# ---------------------------------------------------
# Every build involved here (ASDF, make, cmake) decides what is stale by
# comparing FILE TIMES, and a CI checkout makes file times meaningless:
#
#   - a fresh clone gives every source the checkout time, and the runner
#     restores a cache with the times the files had when it was SAVED, i.e.
#     older. Every output looks stale, everything is rebuilt, and the cache
#     saves nothing. Measured: release:linux:arm64 "Successfully extracted"
#     its libredwg cache on release-2.1.0 and release-2.2.1 and recompiled
#     all 27 C objects both times (29 minutes each);
#   - the opposite case -- outputs that look NEWER than the sources (an
#     extractor that does not keep times, a working tree that survives
#     between jobs) -- is worse: a changed source is NOT recompiled, and the
#     product silently contains the old code. Reproduced in the CI image
#     (2026-10-06): the fasls of an unchanged tree, made newer than a
#     checkout whose alfe version.lisp had changed, gave an alfe-sbcl in 6
#     seconds that reported the OLD version. release-1.9.0's Windows
#     binaries reporting 1.8.56 were attributed to a surviving fasl cache.
#
# So times are never trusted. A cached build is reused ONLY when it was
# produced from EXACTLY the same inputs, which the KEY below names by
# content (git object ids, tool versions). On a hit the products are
# touched so that the build tool, which only understands times, sees them
# as up to date; on any difference the cache is discarded whole and the
# build is cold. There is no "partially valid" cache, no per-file reuse:
# that would trust the build tool's dependency graph, and ASDF's does not
# see the files read at compile time (#. reads, embedded empty.dwg, locale
# dictionaries...).
#
# The key is checked INSIDE the job, against a KEY file stored with the
# cache, rather than being the GitLab cache key itself: GitLab can only key
# on predefined variables or on up to two files, neither of which can name
# the content of a source tree. The GitLab key is therefore stable per job
# (see .gitlab-ci.yml) and this script is what makes a stale entry harmless.
#
# Every failure of this script is a cache MISS, never a job failure: the
# worst it can do is cost a cold build.
#
# THE KINDS
#   fasl      the project's ASDF fasls. WIRED on the Linux docker lanes and
#             the macOS unit lanes (.gitlab-ci.yml, .gitlab/native.yml).
#   libredwg  the vendored LibreDWG build + the CFFI shim. WIRED on
#             verify:packaged-dwg:linux (since clautolisp 2.2.230), the one
#             non-release Linux lane that builds it; such a lane needs
#             GIT_SUBMODULE_STRATEGY: recursive, since a submodule not
#             checked out at restore time is a miss. It was held back until
#             LibreDWG stopped carrying clautolisp's `git describe' as its
#             version: config.h, included by every object, changed on every
#             clautolisp commit, so a hit still recompiled all 27 objects.
#             build-libredwg.sh now stamps the release recorded in
#             clautolisp/third-party/libredwg.release and runs cmake inside
#             the submodule (issues/closed/
#             libredwg-version-is-superproject-describe.issue), and a hit
#             from another clautolisp commit compiles 0 objects.

set -u

op=${1:-}
kind=${2:-}
case "$op:$kind" in
  restore:fasl|restore:libredwg|save:fasl|save:libredwg|key:fasl|key:libredwg|inputs:fasl|inputs:libredwg) ;;
  *) echo "usage: sh scripts/ci-build-cache.sh restore|save|key|inputs fasl|libredwg" >&2
     exit 2 ;;
esac

root=$(pwd -P)
store=".ci-cache/$kind"            # what the GitLab cache: holds
started=".ci-cache/$kind.started"  # the key at restore time (NOT cached)
tag="ci-build-cache[$kind]"

nl='
'

say() { echo "$tag: $*"; }

sha() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -c1-64
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | cut -c1-64
  else openssl dgst -sha256 | sed 's/.*= *//'
  fi
}

# --- what the products depend on ------------------------------------------

# The source: every top-level entry of the commit, by git object id (a
# content hash of the whole subtree), except the ones that are prose and
# bookkeeping only. Excluding is the safe direction: a new top-level
# directory is hashed until someone decides otherwise. Nothing excluded here
# is read by any build (checked 2026-10-06: the Lisp systems mention
# probe-results/ and documentation/ only in docstrings).
source_tree() {
  t=$(git ls-tree HEAD) && [ -n "$t" ] || return 1
  printf '%s\n' "$t" |
    grep -v -E "$(printf '\t')(issues|documentation|probe-results|\.github|AGENTS\.md|README\.md|RELEASE_NOTES\.org|INSTALL\.org|SPEC\.md|COPYING)\$"
  return 0
}

# The machine: an image rebuild that changes any installed package (the
# Debian ones, SBCL/CCL themselves, the compiler) changes the key.
machine() {
  uname -sm
  if command -v dpkg-query >/dev/null 2>&1; then
    echo "dpkg $(dpkg-query -W 2>/dev/null | sha)"
  fi
}

lisps() {
  for l in "${SBCL:-sbcl}" "${CCL:-ccl}"; do
    if command -v "$l" >/dev/null 2>&1; then
      echo "lisp $l: $(command -v "$l") $("$l" --version 2>&1 </dev/null | head -n 1)"
    fi
  done
  # The libraries compiled INTO the fasls (macros, inline functions,
  # constants): the Quicklisp dists and the releases installed from them.
  for d in "$HOME"/quicklisp/dists/*; do
    [ -d "$d" ] || continue
    echo "dist $d"
    cat "$d/distinfo.txt" 2>/dev/null
    # one file per release, naming its versioned directory
    cat "$d"/installed/releases/*.txt 2>/dev/null
  done
  # Local projects can shadow a dist's systems; their presence changes the
  # key. (The project's own systems depend on none of them.)
  ls "$HOME/quicklisp/local-projects" 2>/dev/null
}

compiler() {
  cc=${CC:-cc}
  echo "cc $cc: $(command -v "$cc" 2>/dev/null)"
  "$cc" -dumpmachine 2>&1
  "$cc" --version 2>&1 | head -n 1
  cmake --version 2>&1 | head -n 1
}

inputs() {
  echo "scheme ci-build-cache $kind v1"
  echo "root $root"
  machine
  case "$kind" in
    fasl)
      source_tree || return 1
      lisps ;;
    libredwg)
      # The submodule commit (its gitlink, which also pins jsmn), the
      # build script and the shim (all of drawing-dwg), and the toolchain.
      l=$(git rev-parse HEAD:clautolisp/third-party/libredwg) || return 1
      w=$(git rev-parse HEAD:clautolisp/drawing-dwg) || return 1
      echo "libredwg $l"
      echo "drawing-dwg $w"
      compiler ;;
  esac
}

# A key is only as good as its inputs: if git cannot name the source there
# is NO key -- an empty source list would hash the same for every commit.
key() {
  i=$(inputs) || return 1
  printf '%s\n' "$i" | sha
}

# Anything that makes the checkout differ from HEAD makes the key a lie.
# Modified or untracked (non-ignored) files, or a submodule not at its
# gitlink, are a miss and are never saved. Changes INSIDE a submodule are
# ignored: build-libredwg.sh rewrites libredwg's CMakeLists.txt on purpose
# (the same way every run), and its own build directory lives there.
# For the fasl kind a submodule's checkout is ignored ALTOGETHER: no Lisp
# source is compiled from it, its pinned commit is already in the key (the
# clautolisp/ tree id), and jobs that skip submodule setup reuse a build
# directory where an earlier job left libredwg at another commit (seen as
# " M clautolisp/third-party/libredwg" in MR !444's first pipeline, which made
# build:alfe:sbcl and test:clautolisp:sbcl never save). The libredwg kind
# checks its submodule's commit explicitly below.
dirty() {
  if [ "$kind" = libredwg ]; then submodules=dirty; else submodules=all; fi
  st=$(git status --porcelain --ignore-submodules=$submodules --untracked-files=normal) ||
    { echo "git status failed"; return 0; }
  [ -z "$st" ] || printf '%s\n' "$st" | head -n 5
  if [ "$kind" = libredwg ]; then
    want=$(git rev-parse HEAD:clautolisp/third-party/libredwg 2>/dev/null)
    have=$(git -C clautolisp/third-party/libredwg rev-parse HEAD 2>/dev/null)
    [ -n "$have" ] && [ "$want" = "$have" ] || echo "libredwg submodule at '$have', commit pins '$want'"
  fi
}

# --- where the products live ---------------------------------------------

xdg=${XDG_CACHE_HOME:-$root/clautolisp/.cache}

# fasl: the project's own subtree of every implementation's ASDF output
# cache (<xdg>/common-lisp/<impl><absolute source path>). The libraries'
# fasls (Quicklisp, prebuilt in the CI image) are not ours to cache.
fasl_dirs() {
  for d in "$xdg"/common-lisp/*; do
    [ -d "$d$root" ] && echo "$d$root"
  done
}

libredwg_paths="clautolisp/third-party/libredwg/build clautolisp/drawing-dwg/source/clal_dwg.so clautolisp/drawing-dwg/source/clal_dwg.dylib"

discard_products() {
  case "$kind" in
    fasl) fasl_dirs | while IFS= read -r d; do rm -rf "$d"; done ;;
    libredwg) for p in $libredwg_paths; do rm -rf "$p"; done ;;
  esac
}

# --- restore -------------------------------------------------------------

restore() {
  mkdir -p .ci-cache
  rm -f "$started"
  if ! k=$(key) || [ -z "$k" ]; then
    say "MISS -- cannot compute the key; cold build"
    discard_products; rm -rf "$store"; return 0
  fi
  echo "$k" > "$started"
  say "key $k"
  d=$(dirty)
  if [ -n "$d" ]; then
    say "MISS -- the checkout is not HEAD, so no key can name it; cold build:"
    echo "$d"
    rm -f "$started"
    discard_products; rm -rf "$store"; return 0
  fi
  if [ ! -f "$store/KEY" ]; then
    say "MISS -- no cache; cold build"
    discard_products; rm -rf "$store"; return 0
  fi
  cached=$(cat "$store/KEY")
  if [ "$cached" != "$k" ]; then
    say "MISS -- the cache was built from other inputs ($cached); discarded, cold build"
    discard_products; rm -rf "$store"; return 0
  fi

  # A hit: same inputs, byte for byte. Put the products in place and make
  # them newer than every source, which the checkout has just stamped
  # with the current time. The sleeps make "newer" strict at the
  # one-second resolution the build tools compare at, both ways: products
  # newer than the checkout, and anything a job WRITES later newer than
  # the products.
  discard_products
  case "$kind" in
    fasl)
      for t in "$store"/tree/*; do
        [ -d "$t" ] || continue
        impl=$(basename "$t")
        dest="$xdg/common-lisp/$impl$root"
        mkdir -p "$(dirname "$dest")"
        mv "$t" "$dest" || { say "MISS -- cannot install $dest; cold build"; discard_products; rm -rf "$store"; return 0; }
      done
      products=$(fasl_dirs) ;;
    libredwg)
      products=""
      for p in $libredwg_paths; do
        if [ -e "$store/files/$p" ]; then
          mkdir -p "$(dirname "$p")"
          mv "$store/files/$p" "$p" || { say "MISS -- cannot install $p; cold build"; discard_products; rm -rf "$store"; return 0; }
          products="$products$nl$p"
        fi
      done ;;
  esac
  sleep 1
  n=0
  oldifs=$IFS; IFS=$nl
  for p in $products; do
    [ -n "$p" ] || continue
    find "$p" -type f -exec touch {} +
    n=$((n + $(find "$p" -type f | wc -l | tr -d " ")))
  done
  IFS=$oldifs
  sleep 1
  rm -rf "$store"
  say "HIT -- reusing $n files built from these exact inputs (no rebuild expected)"
}

# --- save ----------------------------------------------------------------

save() {
  if [ ! -f "$started" ]; then
    say "not saving -- no clean restore ran in this job"
    rm -rf "$store"; return 0
  fi
  k=$(key)
  if [ "$k" != "$(cat "$started")" ]; then
    say "not saving -- the inputs changed during the job"
    rm -rf "$store"; return 0
  fi
  d=$(dirty)
  if [ -n "$d" ]; then
    say "not saving -- the job modified the checkout:"
    echo "$d"
    rm -rf "$store"; return 0
  fi
  rm -rf "$store"
  case "$kind" in
    fasl)
      mkdir -p "$store/tree"
      dirs=$(fasl_dirs)
      oldifs=$IFS; IFS=$nl
      for d in $dirs; do
        impl=$(basename "${d%"$root"}")
        cp -R -p "$d" "$store/tree/$impl" || { IFS=$oldifs; say "not saving -- copy failed"; rm -rf "$store"; return 0; }
      done
      IFS=$oldifs ;;
    libredwg)
      mkdir -p "$store/files"
      for p in $libredwg_paths; do
        if [ -e "$p" ]; then
          mkdir -p "$store/files/$(dirname "$p")"
          cp -R -p "$p" "$store/files/$p" || { say "not saving -- copy failed"; rm -rf "$store"; return 0; }
        fi
      done ;;
  esac
  n=$(find "$store" -type f | wc -l | tr -d " ")
  if [ "$n" -eq 0 ]; then
    say "not saving -- nothing was built"
    rm -rf "$store"; return 0
  fi
  echo "$k" > "$store/KEY"          # LAST: a KEY means a complete copy
  say "saved $n files under key $k"
}

case "$op" in
  restore) restore ;;
  save)    save ;;
  key)     key ;;
  inputs)  inputs ;;
esac
exit 0
