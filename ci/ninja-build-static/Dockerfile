##########################################################################
# File: dkcoder\ci\ninja-build-static\Dockerfile                         #
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

FROM alpine:3.20

# Install compiler toolchain and Python
RUN apk update && apk upgrade && apk add coreutils gcc g++ python3

# Download v1.12.1
ADD https://github.com/ninja-build/ninja.git#2daa09ba270b0a43e1929d29b073348aa985dfaa /usr/local/src/ninja-build/

# Build Ninja
WORKDIR /usr/local/src/ninja-build
RUN CFLAGS=-static ./configure.py --bootstrap --verbose
