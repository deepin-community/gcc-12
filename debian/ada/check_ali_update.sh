#!/bin/sh

# Helper for debian/rules2.

# Please 'sh test_check_ali_update.sh' after any change.

# A modification of libgnat sources invalidates the .ali checksums in
# reverse dependencies as described in the Debian Policy for Ada.  GCC
# cannot afford the recommended passage through NEW, but this check at
# least reports the issue before causing random FTBFS.

set -Ceu

[ $# = 2 ]
# Argument 1: dir with Ada runtime from build-dependencies,
#   usually under $gcc_lib_dir,
#   containing adainclude/*.ad[bs] adalib/*.ali from build-dependencies
# Argument 2: dir with freshly built *.ad[bs] *.ali

# $1 includes the built major version, so a missing $1/adainclude
# means that we are building gnat-X with gnat-Y.
# A check is probably unneeded, and would require network access.
[ -d "$1"/adainclude ] || exit 0

vanished=
changed=

for ali1 in "$1"/adalib/*.ali; do
    unit=`basename "$ali1" .ali`
    ali2="$2/$unit.ali"

    if [ ! -r "$ali2" ]; then
	vanished="$vanished $unit.ali"
        continue
    fi

    # Strip the timestamp field, we are only interested in checksums.
    lines1=`sed -En "s/^D $unit[.]ad[bs]\t+[0-9]{14} //p" "$ali1"`
    lines2=`sed -En "s/^D $unit[.]ad[bs]\t+[0-9]{14} //p" "$ali2"`
    if [ "$lines1" != "$lines2" ]; then
        changed="$changed $unit.ali"
    fi
done

if [ -n "$vanished$changed" ]; then
    echo 'error: changes in Ada Library Information files.'
    echo 'You are seeing this because'
    echo ' * build and host GCC major versions match.'
    echo ' * build_type=build-native and with_libgnat=yes in debian/rules.defs.'
    echo ""
    if [ -n "$vanished" ]; then
        echo " * vanished files :$vanished"
    fi
    if [ -n "$changed" ]; then
        echo " * differing files:$changed"
    fi
    echo ""
    # A change in a single source file invalidates all depending
    # .ali files, so a diff of all sources is probably more useful.
    # Report changes in modified or vanished sources (.adb .ads or
    # both), ignore new or unrelated files in $2.
    diff -Nu "$1"/adainclude/* --to-file="$2" 2>&1 | sed '/^\(\+\+\+\|---\)/s/\t.*//'
    echo
    echo 'This may break Ada packages, see https://people.debian.org/~lbrenta/debian-ada-policy.html.'
    echo 'If you are uploading to Debian, please contact debian-ada@lists.debian.org.'
    if [ -n "$DEB_FAIL_ON_ADA_LIB_INFO_CHANGE" ]; then
        echo
        echo 'Build interrupted by DEB_FAIL_ON_ADA_LIB_INFO_CHANGE (from env or rules.defs).'
	exit 1
    fi
fi

exit 0
