#!/bin/bash
# Stage the recursive PE import closure. Run under the build's MSYS2 environment.
# The optional second argument also deploys library dependencies beside the
# dispatch executables: Windows searches the EXE directory for DLL imports.
set -euo pipefail
stage=$1
mirror=${2:-}
objdump=${OBJDUMP:-objdump}
system=$(cygpath -u "${WINDIR:-C:\\Windows}")/System32
declare -A visited
declare -A licensed

license_for() {
    local source=$1 package file destination found=0
    package=$(pacman -Qqo "$source") || {
        echo "Cannot identify license owner of $source" >&2; exit 1;
    }
    [[ ${licensed[$package]:-} ]] && return
    licensed[$package]=1
    destination="$stage/share/doc/clautolisp/runtime-licenses/$package"
    mkdir -p "$destination"
    while IFS= read -r file; do
        if [[ $file == */share/licenses/* && -f $file ]]; then
            cp "$file" "$destination/$(basename "$file")"
            found=1
        fi
    done < <(pacman -Qlq "$package")
    [[ $found == 1 ]] || { echo "No license files for $package" >&2; exit 1; }
    # Package version + origin, without embedding build-machine paths.
    pacman -Q "$package" > "$destination/package.txt"
    printf '%s\n' 'Source: https://github.com/msys2/MINGW-packages' >> "$destination/package.txt"
}

bundle() {
    local binary=$1 directory=$2 key imports name lower source search
    key="$directory/$(basename "$binary" | tr '[:upper:]' '[:lower:]')"
    [[ ${visited[$key]:-} ]] && return
    visited[$key]=1
    imports=$("$objdump" -p "$binary") # A failed inspection must fail staging.
    while IFS= read -r name; do
        [[ -n $name ]] || continue
        lower=${name,,}
        case "$lower" in
            api-ms-win-*|ext-ms-win-*) continue ;;
            msys-2.0.dll|cygwin1.dll)
                echo "Non-native Windows dependency: $binary -> $name" >&2; exit 1 ;;
        esac
        [[ -f "$system/$name" ]] && continue
        source="$directory/$name"
        if [[ ! -f $source ]]; then
            source=
            # Resolve against the importing module first, then the build PATH.
            IFS=: read -ra search <<< "$PATH"
            for search in "$(dirname "$binary")" "${search[@]}"; do
                if [[ -f "$search/$name" ]]; then source="$search/$name"; break; fi
            done
            [[ -n $source ]] || { echo "Missing runtime DLL: $binary -> $name" >&2; exit 1; }
            license_for "$source"
            cp "$source" "$directory/$name"
            echo "runtime: $name -> ${directory#"$stage/"}"
        fi
        if [[ -n $mirror && $directory != "$mirror" ]]; then
            mkdir -p "$mirror"
            cp "$directory/$name" "$mirror/$name"
        fi
        bundle "$directory/$name" "$directory"
    done < <(printf '%s\n' "$imports" | sed -n 's/^[[:space:]]*DLL Name: \(.*\)\r*$/\1/p' | tr -d '\r')
}

while IFS= read -r -d '' binary; do
    bundle "$binary" "$(dirname "$binary")"
done < <(find "$stage" -type f \( -iname '*.exe' -o -iname '*.dll' \) -print0)
