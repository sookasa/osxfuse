#!/bin/bash -
#=======================================================================
#
#   DESCRIPTION: Build OSXFUSE for Sookasa app
#       COMPANY: Sookasa Inc.
#       CREATED: 05.01.2015-13:27:38
#      REVISION: 1.2
#=======================================================================

SCRIPT=$(basename "$0")
DIR=$(dirname "$0")
USAGE="Usage: $0 <sign-identity>"
EXAMPLE="Example: $0 UFEM256A85"
PWD=$(pwd)
PLATF="10.7 10.8 10.9 10.10 10.11"
ans="yes"

if [ $# != 1 ]; then
    echo $USAGE
    echo $EXAMPLE
    exit 1
fi

# parse args
identity=$1

# check build script
build="$DIR/build.sh"
test -f "$DIR/build.sh" || { echo "-E- couldn't find builder script $build"; exit 1; }

# check suported platforms
platforms=`$build -h|grep 'platform is one of:' | cut -d: -f2 | cut -d\( -f1`
platforms=`echo $platforms`
echo "-I- Supported platforms $platforms"
[ "$platforms" = "$PLATF" ] || { echo "-I- Missing platforms sdk (found $platforms but expected $PLATF), do you want to continue?"; read -p "[yes]/no: " ans; }
[ $ans = "no" ] && { echo "-I- stopped!"; exit 1; }

# locate apps path
apps=`cd "$DIR"/../../; pwd; cd - &> /dev/null`
test -d "$apps/Mac" || { echo "-E- couldn't find Mac dir under $apps"; read -p "Enter path manually: " apps; }

# locate destination
pkg_dst_dir="$apps/Mac/Sookasa for OSX/Sookasa for OSX"
pkg_dst="$pkg_dst_dir/OSXFUSE.pkg"
csum_dst="$pkg_dst_dir/OSXFUSE.csum"

# calc current csum
csum=`find "$DIR" -type f -name "*.c" -not -path '*build*' -not -path '*Template*' -exec md5 {} + | awk '{print $4}' | sort | md5`
echo "-I- Current csum  $csum"
csum2=00000000000000000000000000000000
test -f "$csum_dst" && csum2=`cat "$csum_dst"`
echo "-I- Existing csum $csum2"
[ $csum = $csum2 ] && { echo "-I- existing pkg has same csum, do you want to continue?"; read -p "[yes]/no: " ans; }
[ $ans = "no" ] && { echo "-I- stopped!"; exit 1; }

# locate version
ver=`grep "#define OSXFUSE_VERSION_LITERAL" kext/common/fuse_version.h | awk  '{print $3}'`
shortver=`echo $ver| cut -d\. -f1-2`
prefix="/tmp"
pkg="$prefix/osxfuse-$shortver/OSXFUSE.pkg"
rm "$pkg" &> /dev/null

echo "-I- Detected version $ver"
echo "-I- Package location $pkg"

# cleanups
cmd="$build -t clean"
echo "-I- Running $cmd"
$cmd || { echo "-E- Cleanup failed"; exit 2; }
echo "-I- Cleanup complete!"

# build project
cmd="$build -c Release -q -t dist -i $identity -j $identity"
echo "-I- Running $cmd"
$cmd || { echo "-E- Build failed"; exit 2; }
echo "-I- Build complete! ($ver)"
test -f "$pkg" || { echo "-E- couldn't find $pkg, abort"; exit 2; }

# check codesign
kexts=`ls -d $prefix/osxfuse-core-*/osxfuse/Library/Filesystems/osxfusefs.fs/Support/osxfusefs.kext`
test ! -z "$kexts" || { echo "-E- couldn't find kext path"; exit 1; }
ver=0
for kext in $kexts; do
    codesign -dv "$kext"  &> /dev/null || { echo "-W- codesign verification failed $kext"; }
    kextutil -nv "$kext"  &> /dev/null || { echo "-W- kextutil verification failed $kext"; }
    ver=1
done

[ $ver = 0 ] && { echo "-W- file verification failed, do you want to continue?"; read -p "[yes]/no: " ans; }
[ $ans = "no" ] && { echo "-I- stopped!"; exit 1; }

# remove old files
test -f "$pkg_dst"  && echo "-I- Remove old pkg file " && rm "$pkg_dst"
test -f "$csum_dst" && echo "-I- Remove old csum file" && rm "$csum_dst"

# copy new file to destination
cp "$pkg" "$pkg_dst"     || { echo "-E- failed to copy $pkg to $pkg_dst!"; exit 3; }
echo $csum > "$csum_dst" || { echo "-E- failed to create csum file $csum_dst!"; exit 3; }

# done
size=`du -sh "$pkg_dst" | awk '{print $1}'`
echo "-I- Created $csum_dst ($csum)"
echo "-I- Created $pkg_dst  ($size)"
echo "-I- DONE!"
