#!/bin/bash
# usage: drive-catalogue.sh RUNNER RESULT   -- relance RUNNER apres chaque plantage
runner=$1; result=$2; : > "$result"; start=0; n=0
while [ $n -lt 40 ]; do
  n=$((n+1)); out=lancement-$n
  "$runner" "$out" $start PCAT >/dev/null 2>&1
  if [ ! -f "$out/catalogue-log.txt" ]; then echo "run $n: pas demarre, nouvel essai" >&2; continue; fi
  grep -v '^BEGIN' "$out/catalogue-log.txt" >> "$result"
  last=$(tail -1 "$out/catalogue-log.txt")
  case "$last" in
    "=== PCAT DONE") echo "termine en $n lancements" >&2; break;;
    BEGIN*) i=${last#BEGIN }; echo "CASE $i CRASH (moteur termine ou bloque sur ce cas)" >> "$result"; start=$((i+1)); echo "plantage cas $i" >&2;;
    *) echo "fin inattendue: $last" >&2; break;;
  esac
done
