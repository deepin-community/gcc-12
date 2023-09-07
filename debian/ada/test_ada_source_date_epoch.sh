#!/bin/sh
# Basic checks for debian/patches/ada-lib-info-source-date-epoch.diff.

# Copyright (C) 2020 Nicolas Boulenguez <nicolas@debian.org>

# Usage:
#   build GCC
#   sh debian/ada/test_ada_source_date_epoch.sh
#   rm -fr build/test_ada_source_data_epoch

set -C -e -u -x

# Inside the GCC tree:
mkdir build/test_ada_source_data_epoch
cd build/test_ada_source_data_epoch
export LD_LIBRARY_PATH=../gcc/ada/rts:`echo ../*/libgnat_util/.libs`
gnatmake="../gcc/gnatmake --RTS=`echo ../*/libada` --GCC=../gcc/xgcc -c -v"
# For local tests:
# gnatmake="gnatmake -c -v"

cat > lib.ads <<EOF
package Lib is
   Message : constant String := "Hello";
end Lib;
EOF
cat > main.adb <<EOF
with Ada.Text_IO;
with Lib;
procedure Main is
begin
   Ada.Text_IO.Put_Line (Lib.Message);
end Main;
EOF

touch lib.ads -d @20

echo ______________________________________________________________________
echo 'No ALI nor object'

rm -f lib.ali lib.o
$gnatmake main.adb
grep '^D lib\.ads\s\+19700101000020'  lib.ali
grep '^D lib\.ads\s\+19700101000020' main.ali

rm -f lib.ali lib.o
SOURCE_DATE_EPOCH=10 $gnatmake main.adb
grep '^D lib\.ads\s\+19700101000010'  lib.ali
grep '^D lib\.ads\s\+19700101000010' main.ali # gnat-9.3.0-8 says 20

rm -f lib.ali lib.o
SOURCE_DATE_EPOCH=30 $gnatmake main.adb
grep '^D lib\.ads\s\+19700101000020'  lib.ali
grep '^D lib\.ads\s\+19700101000020' main.ali

echo ______________________________________________________________________
echo 'ALI older than object'

touch lib.ali -d @40
touch lib.o   -d @50
$gnatmake main.adb
grep '^D lib\.ads\s\+19700101000020'  lib.ali
grep '^D lib\.ads\s\+19700101000020' main.ali

touch lib.ali -d @40
touch lib.o   -d @50
SOURCE_DATE_EPOCH=10 $gnatmake main.adb
grep '^D lib\.ads\s\+19700101000010'  lib.ali # gnat-9.3.0-8 says 20
grep '^D lib\.ads\s\+19700101000010' main.ali # gnat-9.3.0-8 says 20

touch lib.ali -d @40
touch lib.o   -d @50
SOURCE_DATE_EPOCH=30 $gnatmake main.adb
grep '^D lib\.ads\s\+19700101000020'  lib.ali
grep '^D lib\.ads\s\+19700101000020' main.ali

echo ______________________________________________________________________
echo 'Object older than ALI'

touch lib.o   -d @40
touch lib.ali -d @50
$gnatmake main.adb
grep '^D lib\.ads\s\+19700101000020'  lib.ali
grep '^D lib\.ads\s\+19700101000020' main.ali

touch lib.o   -d @40
touch lib.ali -d @50
SOURCE_DATE_EPOCH=10 $gnatmake main.adb
grep '^D lib\.ads\s\+19700101000010'  lib.ali
grep '^D lib\.ads\s\+19700101000010' main.ali # gnat-9.3.0-8 says 20

touch lib.o   -d @40
touch lib.ali -d @50
SOURCE_DATE_EPOCH=30 $gnatmake main.adb
grep '^D lib\.ads\s\+19700101000020'  lib.ali
grep '^D lib\.ads\s\+19700101000020' main.ali

echo "All tests passed"
