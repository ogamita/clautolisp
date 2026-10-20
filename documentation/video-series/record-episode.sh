#!/bin/bash
# Record one episode's terminal demo and render it to GIF and MP4.
#
#   documentation/video-series/record-episode.sh e02 [OUTDIR]
#
# Needs: asciinema, python3-pexpect, ffmpeg, agg (AGG=path, default `agg`),
# and the clautolisp programs on PATH (e.g. make install-programs PREFIX=/opt/local
# then PATH=/opt/local/bin:$PATH).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
episode=$1
out=${2:-$here/out}
agg=${AGG:-agg}
session=$here/$episode/session.json
mkdir -p "$out"
cast=$out/$episode.cast
read -r cols rows < <(python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); print(s.get("cols",90), s.get("rows",24))' "$session")
TERM=xterm-256color asciinema rec -q --overwrite --cols "$cols" --rows "$rows" \
    -c "env PS1='\$ ' python3 '$here/type-session.py' '$session'" "$cast"
"$agg" --theme monokai --font-size 20 --idle-time-limit 3 "$cast" "$out/$episode.gif" >/dev/null 2>&1
ffmpeg -y -loglevel error -i "$out/$episode.gif" -movflags +faststart -pix_fmt yuv420p \
    -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2,fps=30" -c:v libx264 -crf 18 "$out/$episode.mp4"
echo "$out/$episode.mp4 ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out/$episode.mp4") s)"
