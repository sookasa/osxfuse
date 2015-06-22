#!/bin/bash -
#=======================================================================
#
#   DESCRIPTION: Build OSXFUSE for Sookasa app
#       COMPANY: Sookasa Inc.
#       CREATED: 05.01.2015-13:27:38
#      REVISION: 1.0
#=======================================================================

SCRIPT=$(basename "$0")
DIR=$(dirname "$0")
USAGE="Usage: $0 <sign-identity>"
EXAMPLE="Example: $0 UFEM256A84"
PWD=$(pwd)

if [ $# != 1 ]; then
    echo $USAGE
    echo $EXAMPLE
    exit 1
fi

identity=$1

# check build script
build="$DIR/build.sh"
test -f "$DIR/build.sh" || { echo "-E- couldn't find builder script $build"; exit 1; }

# check config files
config="$DIR/fuse/kernel/configure.ac"
test -f $config || { echo "-E- couldn't find $config"; exit 1; }

# locate version 
#ver=`grep AC_INIT fuse/kernel/configure.ac | awk '{print $2}' | cut -d\. -f1-3`
ver=`grep "#define OSXFUSE_VERSION_LITERAL" kext/common/fuse_version.h | awk  '{print $3}'`
shortver=`echo $ver| cut -d\. -f1-2`
pkg="/tmp/osxfuse-$shortver/OSXFUSE.pkg"
rm "$pkg" &> /dev/null

echo "-I- Detected version $ver"
echo "-I- Package location"

# build project
$build -t clean # comment this out to start clean
cmd="$build -q -t dist -i $identity -j $identity"
echo "-I- Running $cmd"
$cmd || { echo "-E- Build failed"; exit 2; }
echo "-I- Build complete!"
test -f "$pkg" || { echo "-E- couldn't find $pkg, abort"; exit 2; }

# locate destination
apps=`cd "$DIR"/../../; pwd; cd - &> /dev/null`
product_script="$apps"/Mac/Sookasa\ for\ OSX/Sookasa\ for\ OSX/pkg/scripts/ProjectProductPath.sh
pkg_dst_dir="$apps/Mac/Sookasa for OSX/Sookasa for OSX"
pkg_dst="$pkg_dst_dir/OSXFUSE.pkg"
test -f "$pkg_dst" && echo "-I- Found previous $pkg_dst, removing.." && rm "$pkg_dst"

# copy new file to destination
cp "$pkg" "$pkg_dst" || { echo "-E- failed to copy $pkg to $pkg_dst!"; exit 3; }

# done
echo "-I- $pkg_dst is ready!"
echo "-I- DONE!"
