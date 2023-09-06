#!/bin/sh
# Basic checks for check_ali_update.sh.

# Copyright (C) 2021 Nicolas Boulenguez <nicolas@debian.org>

set -Ceuvx

# Stop here if test_check_ali_update_tmp/ already exists.
mkdir test_check_ali_update_tmp

cd test_check_ali_update_tmp
mkdir d2

check() {
    status=0
    sh ../check_ali_update.sh d1 d2 > stdout 2> stderr || status=$?
    test $status = $1
    diff -u expected_out stdout
    echo -n | diff -u - stderr
    rm expected_out stderr stdout
}

mkdir d1

echo -n > expected_out
DEB_FAIL_ON_ADA_LIB_INFO_CHANGE=  check 0

echo -n > expected_out
DEB_FAIL_ON_ADA_LIB_INFO_CHANGE=1 check 0

mkdir d1/adainclude d1/adalib

echo 'normal spec' > d1/adainclude/normal.ads
echo 'normal body' > d1/adainclude/normal.adb
cat > d1/adalib/normal.ali <<EOF
normal ali file
D normal.ads 01
EOF
cp d1/adainclude/normal.ads d1/adainclude/normal.adb d1/adalib/normal.ali d2

echo -n > expected_out
DEB_FAIL_ON_ADA_LIB_INFO_CHANGE=  check 0

echo -n > expected_out
DEB_FAIL_ON_ADA_LIB_INFO_CHANGE=1 check 0

echo 'new spec' > d2/news.ads
cat > d2/new.ali <<EOF
new ali file
D new.ads 01
EOF

echo -n > expected_out
DEB_FAIL_ON_ADA_LIB_INFO_CHANGE=  check 0

echo -n > expected_out
DEB_FAIL_ON_ADA_LIB_INFO_CHANGE=1 check 0

echo 'vanished spec' > d1/adainclude/changed.ads
cat > d1/adalib/changed.ali <<EOF
changed ali file
D changed.ads 02
EOF

cat > expected_out <<EOF
error: changes in Ada Library Information files.
You are seeing this because
 * build and host GCC major versions match.
 * build_type=build-native and with_libgnat=yes in debian/rules.defs.

 * vanished files : changed.ali

diff: d2/changed.ads: No such file or directory

This may break Ada packages, see https://people.debian.org/~lbrenta/debian-ada-policy.html.
If you are uploading to Debian, please contact debian-ada@lists.debian.org.
EOF
DEB_FAIL_ON_ADA_LIB_INFO_CHANGE= check 0

cat > expected_out <<EOF
error: changes in Ada Library Information files.
You are seeing this because
 * build and host GCC major versions match.
 * build_type=build-native and with_libgnat=yes in debian/rules.defs.

 * vanished files : changed.ali

diff: d2/changed.ads: No such file or directory

This may break Ada packages, see https://people.debian.org/~lbrenta/debian-ada-policy.html.
If you are uploading to Debian, please contact debian-ada@lists.debian.org.

Build interrupted by DEB_FAIL_ON_ADA_LIB_INFO_CHANGE (from env or rules.defs).
EOF
DEB_FAIL_ON_ADA_LIB_INFO_CHANGE=1 check 1

sed s/vanished/changed/ d1/adainclude/changed.ads > d2/changed.ads
sed s/02/03/            d1/adalib/changed.ali     > d2/changed.ali

cat > expected_out <<EOF
error: changes in Ada Library Information files.
You are seeing this because
 * build and host GCC major versions match.
 * build_type=build-native and with_libgnat=yes in debian/rules.defs.

 * differing files: changed.ali

--- d1/adainclude/changed.ads
+++ d2/changed.ads
@@ -1 +1 @@
-vanished spec
+changed spec

This may break Ada packages, see https://people.debian.org/~lbrenta/debian-ada-policy.html.
If you are uploading to Debian, please contact debian-ada@lists.debian.org.
EOF
DEB_FAIL_ON_ADA_LIB_INFO_CHANGE= check 0

cat > expected_out <<EOF
error: changes in Ada Library Information files.
You are seeing this because
 * build and host GCC major versions match.
 * build_type=build-native and with_libgnat=yes in debian/rules.defs.

 * differing files: changed.ali

--- d1/adainclude/changed.ads
+++ d2/changed.ads
@@ -1 +1 @@
-vanished spec
+changed spec

This may break Ada packages, see https://people.debian.org/~lbrenta/debian-ada-policy.html.
If you are uploading to Debian, please contact debian-ada@lists.debian.org.

Build interrupted by DEB_FAIL_ON_ADA_LIB_INFO_CHANGE (from env or rules.defs).
EOF
DEB_FAIL_ON_ADA_LIB_INFO_CHANGE=1 check 1

cd ..
rm -fr test_check_ali_update_tmp/
echo "All tests passed"
