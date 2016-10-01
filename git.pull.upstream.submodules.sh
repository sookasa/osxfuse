#!/bin/bash -
#=======================================================================
#
#   DESCRIPTION: Pull upstream code
#  REQUIREMENTS: git
#       COMPANY: Sookasa Inc.
#      REVISION: 1.0
#=======================================================================

SCRIPT=`basename $0`
DIR=`dirname $0`
USAGE="Usage: $0 [dir]"
EXAMPLE="Example: $0 ."
HSCRIPT="git.pull.upstream.sh"

# process input
if [ $# -gt 1 ]; then
    echo $USAGE
    echo $EXAMPLE
    exit 1
fi

if [ $# == 1 ]; then
    wdir=$1
else
    wdir=.
fi

for i in `find "$wdir" | egrep [a-z]/$HSCRIPT`; do
    echo "-I- Pulling: $i"
    cd `dirname $i`
    sh `basename $i`
    cd -
done

exit 0
