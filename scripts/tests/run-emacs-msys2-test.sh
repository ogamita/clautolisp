#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
work=${TMPDIR:-/tmp}/run-emacs-msys2-test-$$
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM

cat >"$work/uname" <<'EOF'
#!/bin/sh
printf '%s\n' MSYS_NT-10.0
EOF
cat >"$work/cygpath" <<'EOF'
#!/bin/sh
case "$2" in
  C:/msys64/tmp) printf '%s\n' /tmp ;;
  *) exit 1 ;;
esac
EOF
cat >"$work/emacs" <<'EOF'
#!/bin/sh
printf '%s|%s|%s\n' "$TMPDIR" "$TEMP" "$TMP"
EOF
chmod +x "$work/uname" "$work/cygpath" "$work/emacs"

actual=$(
  PATH="$work:$PATH" TMPDIR=C:/msys64/tmp TEMP=C:/msys64/tmp TMP=C:/msys64/tmp \
    sh "$repo_root/scripts/run-emacs.sh" "$work/emacs"
)
[ "$actual" = '/tmp|/tmp|/tmp' ] || {
  printf 'expected /tmp|/tmp|/tmp, got %s\n' "$actual" >&2
  exit 1
}

printf '%s\n' 'run-emacs MSYS2 temporary-directory test passed'
