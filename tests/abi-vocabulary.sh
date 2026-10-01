#!/bin/sh
# The wire vocabulary of libmod-host-protocol, which abidiff cannot see: every #define in mod-host.h
# (the verb formats a host parses, the OUTPUT_SET feedback, the socket defaults) and every name in
# the host-errors.h enum with its code. Each value is the one the compiler reads off the header, so
# an alias such as ERR_LV2_INVALID_URI is written with the code it stands for.
#   abi-vocabulary.sh print <mod-host.h> <host-errors.h>
#   abi-vocabulary.sh check <mod-host.h> <host-errors.h> <frozen list>
# check fails when the headers differ from the list in any way: a verb or code removed, renamed or
# renumbered, a format changed, and also one added, which is recorded on purpose with
# 'make abi-baseline' in the commit that adds it.
set -eu
export LC_ALL=C

mode=$1
defines=$2
errors=$3
CC=${CC:-cc}

print() {
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    # a line this script cannot read is an error, never a name silently left out of the list
    sed -n '/^enum[[:space:]]*{/,/^};/p' "$errors" | sed -e '1d' -e '$d' -e 's,/\*.*\*/,,' -e '/^[[:space:]]*$/d' > "$tmp/enum"
    test -s "$tmp/enum" || { echo "FAIL no error enum read from $errors" >&2; exit 1; }
    if grep -v '^[[:space:]]*[A-Z_][A-Z0-9_]*[[:space:]]*\(=[^,]*\)\{0,1\},\{0,1\}[[:space:]]*$' "$tmp/enum" >&2; then
        echo "FAIL the lines above of the enum in $errors are not one NAME [= value], each" >&2; exit 1
    fi
    if grep '^[[:space:]]*#[[:space:]]*define' "$defines" | grep -v '^#define[[:space:]]\{1,\}[A-Z_][A-Z0-9_]*[[:space:]]\{1,\}[^[:space:]]' \
       | grep -v "^#define[[:space:]]*$(basename "$defines" .h | tr 'a-z-' 'A-Z_')_H[[:space:]]*$" >&2; then
        echo "FAIL the #defines above in $defines are not NAME value, each" >&2; exit 1
    fi
    {
        echo '#include <stdio.h>'
        echo "#include \"$(cd "$(dirname "$defines")" && pwd)/$(basename "$defines")\""
        echo "#include \"$(cd "$(dirname "$errors")" && pwd)/$(basename "$errors")\""
        echo 'int main(void) {'
        # object-like macros only; the include guard defines nothing
        sed -n 's/^#define[[:space:]]\{1,\}\([A-Z_][A-Z0-9_]*\)[[:space:]]\{1,\}\(.*\)$/\1 \2/p' "$defines" |
        while read -r name value; do
            case $value in
                \"*) echo "    printf(\"define %s \\\"%s\\\"\\n\", \"$name\", $name);" ;;
                *)   echo "    printf(\"define %s %d\\n\", \"$name\", (int)($name));" ;;
            esac
        done
        # the names of the enum, one per line as the header writes them
        sed -n 's/^[[:space:]]*\([A-Z_][A-Z0-9_]*\)[[:space:]]*\(=[^,]*\)\{0,1\},\{0,1\}[[:space:]]*$/\1/p' "$tmp/enum" |
        while read -r name; do
            echo "    printf(\"error %s %d\\n\", \"$name\", (int)($name));"
        done
        echo '    return 0;'
        echo '}'
    } > "$tmp/vocabulary.c"
    $CC -std=gnu99 -Wall -Werror -o "$tmp/vocabulary" "$tmp/vocabulary.c"
    "$tmp/vocabulary"
}

case $mode in
    print)
        print
        ;;
    check)
        frozen=$4
        test -f "$frozen" || { echo "FAIL no $frozen: record it with 'make abi-baseline'"; exit 1; }
        built=$(mktemp)
        print > "$built"
        if diff -u "$frozen" "$built"; then
            echo "ok   $(grep -c '^define ' "$frozen") defines and $(grep -c '^error ' "$frozen") error codes, as $frozen lists them"
            rm -f "$built"
            exit 0
        fi
        # a line only in the list is a name the wire loses or a value it changes; a line only in the
        # headers is an addition, which the list must record first
        if diff "$frozen" "$built" | grep -q '^<'; then
            echo "FAIL a verb, define or error code of $frozen was removed, renamed or renumbered (- frozen, + headers)"
        else
            echo "FAIL the headers add to $frozen (+): record the addition with 'make abi-baseline'"
        fi
        rm -f "$built"
        exit 1
        ;;
    *)
        echo "usage: $0 print|check <mod-host.h> <host-errors.h> [frozen list]" >&2
        exit 2
        ;;
esac
