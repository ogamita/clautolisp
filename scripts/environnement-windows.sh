# environnement-windows.sh --- PATH and variables for the Windows jobs.
#
# TO BE SOURCED, not executed:
#     . "$(dirname "$0")/environnement-windows.sh"
#
# ADAPTED from run-forest-run/scripts/environnement-windows.sh (pjb), trimmed
# to what the clautolisp release lane needs (no MSBuild/.NET/EPURE). Fix the
# original there and re-vendor, as with scripts/check-versions.sh.
#
# Why not simply source the machine's bashrc: it opens with an interactivity
# guard --
#
#     case $- in *i*) ;; *) return ;; esac
#
# and a CI shell is NOT interactive, so the source returns at that line having
# defined nothing. `bash -l' does not help either: LOGIN is not INTERACTIVE
# (measured: bash -l script gives login_shell=yes but $- = hB, no `i').

# --- The path-form rule ---------------------------------------------------
#
# Two worlds coexist, and a value meant for one does not suit the other:
#
#   MSYS program     -> Unix path. "/" is the install root, so /usr/bin/cc
#                       means c:/msys64/usr/bin/cc. This is the form for
#                       anything read by bash, make, cmake, or a binary
#                       compiled under MSYS.
#   Windows program  -> "c:/" prefix. Native tools do not know the MSYS root.
#
# This is not fussiness: a "C:" travelling through a value meant for a Unix
# tool gets cut at the colon by whoever reads that as a separator -- see the
# CMAKE_C_COMPILER truncation below.

ew_ajouter_chemin() {
    local d
    for d in "$@"; do
        [ -d "$d" ] || continue
        case ":$PATH:" in
            *":$d:"*) ;;
            *) PATH="$d:$PATH" ;;
        esac
    done
}

# Move a directory to the FRONT even when already present further along. The
# difference from ew_ajouter_chemin is essential for the MSYS2 tools: the
# inherited Windows PATH may already carry Git Bash and a native make ahead of
# /usr/bin. Letting those win would mix two MSYS roots and convert path
# variables as they cross into the Windows program.
ew_mettre_chemin_en_tete() {
    local d entree nouveau ancien_ifs
    for d in "$@"; do
        [ -d "$d" ] || continue
        nouveau=
        ancien_ifs=$IFS
        IFS=:
        for entree in $PATH; do
            [ "$entree" = "$d" ] && continue
            nouveau="${nouveau:+$nouveau:}$entree"
        done
        IFS=$ancien_ifs
        PATH="$d${nouveau:+:$nouveau}"
    done
}

ew_utilisateur="${USERNAME:-${USER:-inconnu}}"

case "${MSYSTEM:-}" in
    MINGW32) ew_ajouter_chemin /mingw32/bin ;;
    MINGW64) ew_ajouter_chemin /mingw64/bin ;;
    UCRT64)  ew_ajouter_chemin /ucrt64/bin  ;;
    CLANG64) ew_ajouter_chemin /clang64/bin ;;
esac

# Native Windows tools: sbcl and friends live here, and an MSYS2 login
# profile knows nothing about them.
ew_ajouter_chemin \
    "/c/Program Files/Git/bin" \
    "/c/Program Files/Git/usr/bin" \
    "/c/Program Files/make-4.4.1-with-guile-w32/bin" \
    "/c/Program Files/binutils-2.46-w32/bin" \
    "/c/Program Files/findutils-4.2.30-5-w64/bin" \
    "/c/Program Files/Steel Bank Common Lisp" \
    "/c/Users/${ew_utilisateur}/.local/bin" \
    "/c/msys64/home/${ew_utilisateur}/bin"

ew_ajouter_chemin /usr/local/bin /usr/bin /bin /opt/local/bin

# Guarantee ONE MSYS family for make's subprocesses. The call order is
# deliberate: each move prefixes, so /mingw64/bin ends up ahead of /usr/bin.
ew_mettre_chemin_en_tete /usr/bin
[ -d /mingw64/bin ] && ew_mettre_chemin_en_tete /mingw64/bin

# --- The C compiler, set HERE and not from PowerShell ----------------------
#
# In the MSYS shell "/" is the install root, and a path written that way stays
# that way. Set from PowerShell instead, the MSYS layer converts the value at
# process entry and "/mingw64/bin/gcc" comes out as
# "C:/msys64/mingw64/bin/gcc".
#
# That mattered: build-libredwg.sh does `command -v "$CC"' then passes the
# result to cmake as -DCMAKE_C_COMPILER=. CMake splits its -D on ":", so
# "C:/..." arrived truncated to just "C", giving
#     The CMAKE_C_COMPILER: C  is not a full path
# The POSIX form travels intact, having no colon.
if [ -z "${CC:-}" ] || case "${CC}" in *:*) true ;; *) false ;; esac; then
    # MINGW64 first if it exists, whatever MSYSTEM says: the clautolisp DWG
    # codec refuses UCRT64 and CLANG64, which import private UCRT API sets
    # that the native SBCL does not have.
    if [ -x /mingw64/bin/gcc ]; then
        CC=/mingw64/bin/gcc
    else
        case "${MSYSTEM:-}" in
            MINGW32) CC=/mingw32/bin/gcc ;;
            MINGW64) CC=/mingw64/bin/gcc ;;
            UCRT64)  CC=/ucrt64/bin/gcc  ;;
            CLANG64) CC=/clang64/bin/gcc ;;
            *)       CC=gcc ;;
        esac
    fi
    export CC
fi
export CMAKE_C_COMPILER="$CC"

# Should a native Windows tool be invoked anyway, stop MSYS2 converting
# CC=/mingw64/bin/gcc into C:/msys64/mingw64/bin/gcc at the process boundary.
case ";${MSYS2_ENV_CONV_EXCL:-};" in
    *';CC;'*) ;;
    *) MSYS2_ENV_CONV_EXCL="CC${MSYS2_ENV_CONV_EXCL:+;$MSYS2_ENV_CONV_EXCL}" ;;
esac
export MSYS2_ENV_CONV_EXCL

# Windows locations the native programs expect. The runner's service account
# does not necessarily have the interactive session's, so set only if absent.
[ -z "${USERPROFILE:-}" ]  && export USERPROFILE="C:/Users/${ew_utilisateur}"
[ -z "${LOCALAPPDATA:-}" ] && export LOCALAPPDATA="$USERPROFILE/AppData/Local"
[ -z "${APPDATA:-}" ]      && export APPDATA="$USERPROFILE/AppData/Roaming"

export PATH
unset ew_utilisateur
unset -f ew_ajouter_chemin ew_mettre_chemin_en_tete
