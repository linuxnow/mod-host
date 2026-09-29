#!/bin/bash
#
# Build the mod-host RPMs from a mod-host checkout with the audinux spec.
#
#   utils/build-rpm.sh <mod-host checkout> <dir with mod-host.spec> <output dir>
#
# The checkout replaces the spec's Source0: commit0 is set to the checkout's sha and
# `git archive` of it becomes the tarball the spec names. Each Patch the spec lists is
# tried on that tree in order: one that reverses cleanly is already there and is
# dropped, one that applies is kept, and one that does neither is dropped with a
# warning (a patch the tree carries in a later form). The build dependencies are
# installed with dnf, so run it where that is wanted (a build container). The RPMs
# are copied to the output dir, every package's files and what
# libmod-host-plumbing.so.0 exports are printed, and an empty build is an error.

set -euo pipefail

if [ $# -ne 3 ]; then
    echo "usage: $0 <mod-host checkout> <dir with mod-host.spec> <output dir>" >&2
    exit 2
fi

src="$(realpath "$1")"
specdir="$(realpath "$2")"
mkdir -p "$3"
out="$(realpath "$3")"

top="$(mktemp -d)"
spec="$top/SPECS/mod-host.spec"
mkdir -p "$top/SOURCES" "$top/SPECS" "$top/RPMS"

sha="$(git -C "$src" rev-parse HEAD)"
cp "$specdir"/mod-host*.patch "$specdir"/mod-host.service "$top/SOURCES/"
sed "s/^%global commit0 .*/%global commit0 $sha/" "$specdir/mod-host.spec" > "$spec"
grep -q "^%global commit0 $sha\$" "$spec"

work="$(mktemp -d)"
git -C "$src" archive HEAD | tar -x -C "$work"
drop=""
while read -r tag file; do
    if (cd "$work" && patch -p1 -R -s -f --fuzz=0 --dry-run < "$top/SOURCES/$file" > /dev/null); then
        echo "$tag $file: already in this tree, dropped"
        drop="$drop $tag"
    elif (cd "$work" && patch -p1 -s -f --fuzz=0 --dry-run < "$top/SOURCES/$file" > /dev/null); then
        (cd "$work" && patch -p1 -s -f --fuzz=0 < "$top/SOURCES/$file")
        echo "$tag $file: applies, kept"
    else
        echo "::warning::$tag $file neither applies to nor reverses on this tree; dropped"
        drop="$drop $tag"
    fi
done < <(sed -n 's/^\(Patch[0-9]*\):[[:space:]]*\(.*\)$/\1 \2/p' "$spec")
for tag in $drop; do
    sed -i "/^$tag:/d" "$spec"
done
rm -rf "$work"

dnf builddep -y "$spec"
tarball="$(rpmspec -P "$spec" | sed -n 's/^Source0:.*#\/\(.*\)$/\1/p')"
test -n "$tarball"
git -C "$src" archive --prefix="mod-host-$sha/" HEAD | gzip > "$top/SOURCES/$tarball"
echo "Source0: $tarball from $sha"
grep -E '^(Version|Release|Patch[0-9]+):' "$spec"

rpmbuild --define "_topdir $top" -bb "$spec"

find "$top/RPMS" -name '*.rpm' | sort > "$top/built.txt"
if [ ! -s "$top/built.txt" ]; then
    echo "::error::no RPM was produced"
    exit 1
fi
while read -r rpm; do
    echo "== $(basename "$rpm")"
    rpm -qlp "$rpm"
    cp "$rpm" "$out/"
done < "$top/built.txt"

root="$(mktemp -d)"
for rpm in "$out"/mod-host-[0-9]*.rpm; do
    (cd "$root" && rpm2cpio "$rpm" | cpio -id --quiet)
done
lib="$(find "$root" -name 'libmod-host-plumbing.so.0' | head -n 1)"
if [ -z "$lib" ]; then
    echo "::error::libmod-host-plumbing.so.0 is not in the mod-host package"
    exit 1
fi
echo "== nm -D --defined-only libmod-host-plumbing.so.0"
nm -D --defined-only "$lib"
