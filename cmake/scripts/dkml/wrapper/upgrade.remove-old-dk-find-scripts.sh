#!/bin/sh
##########################################################################
# File: dktool\cmake\scripts\dkml\wrapper\upgrade.remove-old-dk-find-scripts.sh#
#                                                                        #
# Copyright 2024 Diskuv, Inc.                                            #
#                                                                        #
# Licensed under the Open Software License version 3.0                   #
# (the "License"); you may not use this file except in compliance        #
# with the License. You may obtain a copy of the License at              #
#                                                                        #
#     https://opensource.org/license/osl-3-0-php/                        #
#                                                                        #
##########################################################################

set -eux

if ! [ -x /usr/bin/dos2unix ]; then
    echo "Needs dos2unix"; exit 1
fi
if ! [ -x /usr/bin/unix2dos ]; then
    echo "Needs unix2dos"; exit 1
fi

git log --format=%H 3df563c0f760d79cf0df8dfbc5bde8ac4f50a510..HEAD -- cmake/scripts/__dk-find-scripts.cmake | while read -r gitref; do
    if [ -x /usr/bin/shasum ] || [ -x /bin/shasum ]; then
        git show "${gitref}:cmake/scripts/__dk-find-scripts.cmake" | PATH=/usr/bin:/bin shasum -a 256
        git show "${gitref}:cmake/scripts/__dk-find-scripts.cmake" | /usr/bin/dos2unix -c ascii | PATH=/usr/bin:/bin shasum -a 256
        git show "${gitref}:cmake/scripts/__dk-find-scripts.cmake" | /usr/bin/dos2unix -c mac | PATH=/usr/bin:/bin shasum -a 256
        git show "${gitref}:cmake/scripts/__dk-find-scripts.cmake" | /usr/bin/unix2dos -c ascii | PATH=/usr/bin:/bin shasum -a 256
        git show "${gitref}:cmake/scripts/__dk-find-scripts.cmake" | /usr/bin/unix2dos -c mac | PATH=/usr/bin:/bin shasum -a 256
    else
        git show "${gitref}:cmake/scripts/__dk-find-scripts.cmake" | PATH=/usr/bin:/bin sha256sum
        git show "${gitref}:cmake/scripts/__dk-find-scripts.cmake" | /usr/bin/dos2unix -c ascii | PATH=/usr/bin:/bin sha256sum
        git show "${gitref}:cmake/scripts/__dk-find-scripts.cmake" | /usr/bin/dos2unix -c mac | PATH=/usr/bin:/bin sha256sum
        git show "${gitref}:cmake/scripts/__dk-find-scripts.cmake" | /usr/bin/unix2dos -c ascii | PATH=/usr/bin:/bin sha256sum
        git show "${gitref}:cmake/scripts/__dk-find-scripts.cmake" | /usr/bin/unix2dos -c mac | PATH=/usr/bin:/bin sha256sum
    fi
done | awk -v dq='"' '{print dq $1 dq}' | sort -u
