#!/bin/sh
# The library's exports and installed headers against the frozen lists in abi/, with binutils alone.
#   abi-exports.sh <libmod-host-protocol.so.X.Y.Z> <symbols file> <headers file> <header>...
# A symbol or header that appears or disappears fails: the lists are the API, and a change to them
# is made on purpose with 'make abi-baseline' in the commit that moves the version.
set -eu
export LC_ALL=C

lib=$1
symbols=$2
headers=$3
shift 3

test -f "$symbols" || { echo "FAIL no $symbols: record it with 'make abi-baseline'"; exit 1; }
test -f "$headers" || { echo "FAIL no $headers: record it with 'make abi-baseline'"; exit 1; }

rc=0
nm -D --defined-only "$lib" | awk '{ print $2, $3 }' | sort > "$lib.symbols"
if diff -u "$symbols" "$lib.symbols"; then
    echo "ok   $(wc -l < "$symbols") exported symbols, as $symbols lists them"
else
    echo "FAIL the exports of $lib differ from $symbols (- frozen, + built)"
    rc=1
fi

for h in "$@"; do basename "$h"; done | sort > "$lib.headers"
if diff -u "$headers" "$lib.headers"; then
    echo "ok   $(wc -l < "$headers") installed headers, as $headers lists them"
else
    echo "FAIL the installed headers differ from $headers (- frozen, + installed)"
    rc=1
fi
rm -f "$lib.symbols" "$lib.headers"
exit $rc
