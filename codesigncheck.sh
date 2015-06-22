#!/bin/bash -
#=======================================================================
#
#   DESCRIPTION: Check kext sign
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
kext=`ls -d /tmp/osxfuse-core-*/osxfuse/Library/Filesystems/osxfusefs.fs/Support/osxfusefs.kext`
test ! -z "$kext" || { echo "-E- couldn't find kext path"; exit 1; }
kextbase=`basename "$kext"`
# check codesign
echo "-I- codesign output:"
codesign -dvvv "$kext" || { echo "-E- codesign verification failed!"; exit 1; }

# check if sign has kext permission to load
echo ""
echo "-I- kextutil output:"
kextutil -nv  "$kext" || { echo "-E- codesign verification failed!"; exit 1; }

echo ""
echo "-I- $kextbase is signed correctly"

exit 0
