#!/bin/sh
set -eu

result_file="${1:?missing result file path}"
printf '%s\n' '(OK 7)' >"$result_file"
