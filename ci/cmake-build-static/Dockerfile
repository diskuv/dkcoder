##########################################################################
# File: dkcoder\ci\cmake-build-static\Dockerfile                         #
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

# Install compiler toolchain including samurai (a ninja clone)
# Install CMake Linux dependencies
#RUN apk update && apk upgrade && apk add coreutils gcc g++ samurai linux-headers openssl-dev make
RUN apk update && apk upgrade && apk add coreutils gcc g++ linux-headers openssl-dev openssl-libs-static cmake make

# Download v3.25.2
ADD https://github.com/Kitware/CMake.git#e2be23a2b39f4380f32fe65ba770addc154579c7 /usr/local/src/cmake/

# Build CMake with CMake.
#   No ccmake needed.
#   No cmake-gui needed.
#   Static openssl is partially a problem:
#       - Used by file(DOWNLOAD), etc: https://discourse.cmake.org/t/feature-request-curl-executable/1619/3
#       - TLS verification will expect same paths on end-user machine as on build machine (so Alpine paths)
#         That won't work for most people. Confer
#         https://forum.crystal-lang.org/t/alpine-static-compiled-binary-failed-with-routinescertificate-verify-failed-openssl-error-when-run-it-on-centos-8/4946
#       - But TLS verification is disabled by default: https://cmake.org/cmake/help/latest/command/file.html#transfer
WORKDIR /usr/local/src/cmake
#   static executables: https://github.com/Kitware/CMake/blob/master/Utilities/Release/linux/x86_64/cache.txt
#   related: https://stackoverflow.com/a/24671474/21513816 for building static executables
RUN cmake -S . -B build \
    -D CMAKE_MAKE_PROGRAM=make \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_EXE_LINKER_FLAGS=-static \
    -D BUILD_CursesDialog=OFF \
    -D BUILD_QtDialog=OFF \
    -D "OPENSSL_CRYPTO_LIBRARY=/usr/lib/libcrypto.a;-pthread" \
    -D "OPENSSL_SSL_LIBRARY=/usr/lib/libssl.a" \
    -D BUILD_SHARED_LIBS=OFF \
    && cmake --build build \
    && cmake --install build --prefix /usr/local/cmake
