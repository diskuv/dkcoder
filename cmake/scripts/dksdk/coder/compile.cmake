##########################################################################
# File: dktool\cmake\scripts\dksdk\coder\compile.cmake                   #
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

set(DKCODER_COMPILE_VERSION 0.1.0-1)
# The SHA256 checksums for ${DKCODER_COMPILE_VERSION} are all available from
# https://gitlab.com/diskuv/distributions/1.0/dksdk-coder/-/packages/21844308 (select
# the right version of course)
set(DKCODER_SHA256_windows_x86_64 3a3d1deecb4368d9b513313c7e91561b38f2f527a145f1654a9433a5e624ea65)
set(DKCODER_SHA256_windows_x86    b20d37aadbeca8848d2ba95209c49d9b75e4cd29a44670a7eb795eae90699bd8)
set(DKCODER_SHA256_linux_x86_64   0e34fe0935e67dd81fe0b00e320e81bfc7aa1e175270152a4eab85c5fe07b177)
set(DKCODER_SHA256_linux_x86      8b2f690e6de4a1f26c654df41d62be4d33d0363281c5fbfee6fd983fc8138649)
set(DKCODER_SHA256_darwin_x86_64  todo_darwin_x86_64)
set(DKCODER_SHA256_darwin_arm64   todo_darwin_arm64)

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()

    cmake_path(APPEND DKSDK_DATA_HOME coder OUTPUT_VARIABLE DKCODER_HOME)
    cmake_path(NATIVE_PATH DKCODER_HOME DKCODER_HOME_NATIVE)

    message(${ARG_MODE} "usage: ./dk dksdk.coder.compile

Compiles Coder expressions describing an application into a
compiled CDI (Coder instruction language) file.

The `dkcoder` environment, if not already installed, will be
downloaded and installed automatically.

Examples
========

  ./dk dksdk.coder.compile SOURCE expression.ml
    Creates `expression.cdi` in the same directory as `expression.ml`

  ./dk dksdk.coder.compile SOURCE expression.ml OUTPUT ../compiled.cdi
    Creates `../compiled.cdi`

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

SOURCE filename
  The name of the file containing Coder expressions.

OUTPUT filename
  The name of the output CDI file.

NO_SYSTEM_PATH
  Do not check for an OCaml runtime environment with `dkcoder` in well-known
  locations and in the PATH. Instead, install the `dkcoder` environment if no
  environment exists at `${DKCODER_HOME_NATIVE}`.

VERSION version
  Use the version specified rather than the built-in ${DKCODER_COMPILE_VERSION}
  dkcoder version. CAUTION: Using this option causes the SHA-256 integrity checks
  to be skipped.
")
endfunction()

# Outputs:
# - DKCODER - location of dkcoder executable
# - DKCODER_OCAMLC - location of ocamlc compatible with dkcoder
# - DKCODER_OCAMLRUN - location of ocamlrun compatible with dkcoder
# - DKCODER_DUNE - location of dune compatible with dkcoder
function(install_dkcoder)
    set(noValues NO_SYSTEM_PATH ENFORCE_SHA256)
    set(singleValues VERSION)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    cmake_path(APPEND DKSDK_DATA_HOME coder OUTPUT_VARIABLE DKCODER_HOME)
    set(hints ${DKCODER_HOME}/bin)
    set(find_program_INITIAL)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND find_program_INITIAL NO_DEFAULT_PATH)
    endif()
    find_program(DKCODER NAMES dkcoder HINTS ${hints} ${find_program_INITIAL})

    if(NOT DKCODER)
        # Download into ${DKCODER_HOME} (which is one of the HINTS)
        set(downloaded)
        set(url_base "https://gitlab.com/api/v4/projects/52918795/packages/generic/stdexport/${ARG_VERSION}")
        if(CMAKE_HOST_WIN32)
            # On Windows CMAKE_HOST_SYSTEM_PROCESSOR = ENV:PROCESSOR_ARCHITECTURE
            # Values: AMD64, IA64, ARM64, x86
            # https://docs.microsoft.com/en-us/windows/win32/winprog64/wow64-implementation-details?redirectedfrom=MSDN#environment-variables
            set(out_exp .zip)
            if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL x86 OR CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL X86)
                set(dkml_host_abi windows_x86)
            else()
                set(dkml_host_abi windows_x86_64)
            endif()
        elseif(CMAKE_HOST_APPLE)
            set(out_exp .tar.gz)
            execute_process(COMMAND uname -m
                    OUTPUT_VARIABLE host_machine_type
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    COMMAND_ERROR_IS_FATAL ANY)
            if(host_machine_type STREQUAL x86_64)
                set(dkml_host_abi darwin_x86_64)
            elseif(host_machine_type STREQUAL arm64)
                set(dkml_host_abi darwin_arm64)
            else()
                message(FATAL_ERROR "Your macOS ${host_machine_type} platform is currently not supported by this download script")
            endif()
        elseif(CMAKE_HOST_LINUX)
        set(out_exp .tar.gz)
        execute_process(COMMAND uname -m
                    OUTPUT_VARIABLE host_machine_type
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    COMMAND_ERROR_IS_FATAL ANY)
            if(host_machine_type STREQUAL x86_64)
                set(dkml_host_abi linux_x86_64)
            elseif(host_machine_type STREQUAL i686)
                set(dkml_host_abi linux_x86)
            else()
                message(FATAL_ERROR "Your Linux ${host_machine_type} platform is currently not supported by this download script")
            endif()
        else()
            message(FATAL_ERROR "DkSDK Coder is only available on Windows, macOS and Linux")
        endif()

        # Download
        set(expand_EXPECTED_HASH)
        if(ARG_ENFORCE_SHA256)
            set(expand_EXPECTED_HASH EXPECTED_HASH SHA256=DKCODER_SHA256_${dkml_host_abi})
        endif()
        set(url "${url_base}/stdexport-${dkml_host_abi}${out_exp}")
        message(${loglevel} "Downloading DkSDK Coder from ${url}")
        file(DOWNLOAD ${url} ${CMAKE_CURRENT_BINARY_DIR}/stdexport${out_exp} ${expand_EXPECTED_HASH})
        message(${loglevel} "Extracting DkSDK Coder")
        file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/stdexport${out_exp} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/_e)
        file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/stdexport${out_exp})

        # Install
        #   Do file(RENAME) but work across mount volumes (ex. inside containers)
        file(REMOVE_RECURSE "${DKCODER_HOME}")
        file(MAKE_DIRECTORY "${DKCODER_HOME}")
        file(GLOB entries
            LIST_DIRECTORIES true
            RELATIVE ${CMAKE_CURRENT_BINARY_DIR}/_e
            ${CMAKE_CURRENT_BINARY_DIR}/_e/*)
        foreach(entry IN LISTS entries)
            file(COPY ${CMAKE_CURRENT_BINARY_DIR}/_e/${entry}
                DESTINATION ${DKCODER_HOME}
                FOLLOW_SYMLINK_CHAIN
                USE_SOURCE_PERMISSIONS)
        endforeach()
        file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/_e")

        find_program(DKCODER NAMES dkcoder REQUIRED HINTS ${hints})
    endif()

    # ocamlc, ocamlrun and dune must be in the same directory as dkcoder.
    cmake_path(GET DKCODER PARENT_PATH dkcoder_bindir)
    find_program(DKCODER_OCAMLC NAMES ocamlc REQUIRED NO_DEFAULT_PATH HINTS ${dkcoder_bindir})
    find_program(DKCODER_OCAMLRUN NAMES ocamlrun REQUIRED NO_DEFAULT_PATH HINTS ${dkcoder_bindir})
    find_program(DKCODER_DUNE NAMES dune REQUIRED NO_DEFAULT_PATH HINTS ${dkcoder_bindir})
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION}")

    set(noValues HELP QUIET NO_SYSTEM_PATH)
    set(singleValues VERSION)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
        help(MODE NOTICE)
        return()
    endif()

    # QUIET
    if(ARG_QUIET)
        set(loglevel DEBUG)
    else()
        set(loglevel STATUS)
    endif()

    # NO_SYSTEM_PATH
    set(expand_NO_SYSTEM_PATH)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND expand_NO_SYSTEM_PATH NO_SYSTEM_PATH)
    endif()

    # VERSION
    if(ARG_VERSION)
        set(VERSION ${ARG_VERSION})
        set(expand_ENFORCE_SHA256)        
    else()
        set(VERSION ${DKCODER_COMPILE_VERSION})
        set(expand_ENFORCE_SHA256 ENFORCE_SHA256)
    endif()

    install_dkcoder(VERSION ${VERSION} ${expand_NO_SYSTEM_PATH} ${expand_ENFORCE_SHA256})
    message(STATUS "dkcoder is at: ${DKCODER}")
endfunction()
