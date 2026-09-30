#!/bin/sh
# libmod-host-protocol against the baseline in abi/, with libabigail.
#   abi-check.sh <libmod-host-protocol.so.X.Y.Z> <include dir> <baseline.abi>
# An added function is compatible and needs a new PROTOCOL_VERSION minor. A function or variable
# removed or changed, and a type whose size or layout changes, is incompatible and needs a new
# PROTOCOL_SOVERSION, whose first build records a new baseline. host_backend_t is allocated by the
# host and read by the library, so a field appended to it is incompatible too: a host built
# against the shorter table would be read past its end.
set -eu
export LC_ALL=C

lib=$1
headers=$2
baseline=$3
dir=$(dirname "$lib")
out=$dir/new.abi
report=$dir/abidiff.txt

abidw --headers-dir "$headers" --out-file "$out" "$lib"
test -s "$out" || { echo "FAIL abidw wrote nothing for $lib"; exit 1; }
test -f "$baseline" || { echo "FAIL no baseline $baseline: record it with 'make abi-baseline' and commit it"; exit 1; }

soname_of() { sed -n "s/.*soname='\([^']*\)'.*/\1/p" "$1" | head -1; }
version_of() { sed -n "s/.*path='[^']*\.so\.\([0-9][0-9.]*\)'.*/\1/p" "$1" | head -1; }

old_soname=$(soname_of "$baseline")
new_soname=$(soname_of "$out")
old_version=$(version_of "$baseline")
new_version=$(version_of "$out")
test -n "$old_soname" && test -n "$new_soname" && test -n "$old_version" && test -n "$new_version" \
    || { echo "FAIL the soname and the version could not be read off the baseline ($old_soname $old_version) and the build ($new_soname $new_version)"; exit 1; }

rc=0
abidiff "$baseline" "$out" > "$report" || rc=$?
cat "$report"
echo "abidiff exit $rc: baseline $old_soname $old_version, build $new_soname $new_version"

if [ "$new_soname" != "$old_soname" ]; then
    echo "ok   a new soname ($old_soname to $new_soname): the new major's first build; record its baseline"
    exit 0
fi
if [ $((rc & 1)) -ne 0 ] || [ $((rc & 2)) -ne 0 ]; then
    echo "FAIL abidiff could not compare"
    exit 1
fi

# abidiff calls a change reached through a pointer compatible (4); every type here is reached
# through one, so the report is read instead of trusting the bit
if [ $((rc & 8)) -ne 0 ] \
   || grep -Eq "Removed function|Removed variable|data member|offset changed|type size changed|return type changed|parameter [0-9]+ of type .* changed|enumerator|Changed variable|Changed function" "$report"; then
    echo "FAIL an incompatible change under the soname $old_soname: it needs a new PROTOCOL_SOVERSION"
    exit 1
fi
if [ $((rc & 4)) -ne 0 ]; then
    if [ "$new_version" = "$old_version" ]; then
        echo "FAIL a compatible change (an addition) under the version $old_version: it needs a new PROTOCOL_VERSION minor"
        exit 1
    fi
    echo "ok   a compatible change, and the version moved $old_version to $new_version"
    exit 0
fi
echo "ok   no change in the ABI since $old_version"
