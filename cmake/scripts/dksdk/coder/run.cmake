##########################################################################
# File: dktool\cmake\scripts\dksdk\coder\run.cmake                       #
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

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()

    cmake_path(APPEND DKSDK_DATA_HOME coder h OUTPUT_VARIABLE DKCODER_HOME)
    cmake_path(APPEND DKSDK_DATA_HOME coder c OUTPUT_VARIABLE DKCODER_COMPILEDIR)
    cmake_path(NATIVE_PATH DKCODER_HOME DKCODER_HOME_NATIVE)
    cmake_path(NATIVE_PATH DKCODER_COMPILEDIR DKCODER_COMPILEDIR_NATIVE)

    message(${ARG_MODE} "usage: ./dk dksdk.coder.run [VERSION v] [QUIET] <options>

Installs and runs the `dkcoder` program. All <options> are passed through to
the `dkcoder` program except the HELP command.

Arguments
=========

HELP
  Print this help message.

VERSION version
  Use and possibly install the version specified rather than the built-in
  dkcoder version.
  See `./dk dksdk.coder.compile HELP` for cautions about using this option.

QUIET
  Do not print CMake STATUS messages.

--help
  Print the full help available for the built-in dkcoder version or for the
  `VERSION version` if you specify it.

Options
=======

... full options listed if you run this command with --help ...
")
endfunction()

function(dkcoder_run)
    set(noValues)
    set(singleValues LOGLEVEL)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # Default LOGLEVEL
    if(NOT ARG_LOGLEVEL)
        set(ARG_LOGLEVEL "STATUS")
    endif()

    # Set the DkSDK Coder home and compile directory
    cmake_path(APPEND DKSDK_DATA_HOME coder h OUTPUT_VARIABLE DKCODER_HOME)
    cmake_path(APPEND DKSDK_DATA_HOME coder c OUTPUT_VARIABLE DKCODER_COMPILEDIR)

    if(IS_DIRECTORY "${DKCODER_HOME}")
        message(${ARG_LOGLEVEL} "Removing ${DKCODER_HOME}")
        file(REMOVE_RECURSE "${DKCODER_HOME}")
    endif()
    if(IS_DIRECTORY "${DKCODER_COMPILEDIR}")
        message(${ARG_LOGLEVEL} "Removing ${DKCODER_COMPILEDIR}")
        file(REMOVE_RECURSE "${DKCODER_COMPILEDIR}")
    endif()
    message(${ARG_LOGLEVEL} "DkSDK Coder uninstalled.")
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    # NOTE: All of these arguments except HELP must be passed-through in
    # [dksdk-coder/src/Gen/exe/gen_main.ml:argv_without_dk ()]
    set(noValues HELP QUIET)
    set(singleValues VERSION)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
        help(MODE NOTICE)
        return()
    endif()

    # Get other helper functions (which overrides help())
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/compile.cmake)

    # VERSION
    if(ARG_VERSION)
        set(VERSION ${ARG_VERSION})
        set(expand_ENFORCE_SHA256)
    else()
        set(VERSION ${DKCODER_COMPILE_VERSION})
        set(expand_ENFORCE_SHA256 ENFORCE_SHA256)
    endif()

    # QUIET
    if(ARG_QUIET)
        set(loglevel DEBUG)
    else()
        set(loglevel STATUS)
    endif()

    # Make sure a safe dkcoder environment is installed if none exists
    dkcoder_install(VERSION ${VERSION} LOGLEVEL ${loglevel} ${expand_ENFORCE_SHA256})

    # Run the command as a post script. Why? We want cmdliner driven
    # command line arguments given to dkcoder.exe.
    if(CMAKE_HOST_WIN32)
        cmake_path(NATIVE_PATH DKCODER DKCODER_NATIVE)
        file(CONFIGURE OUTPUT "${DKTOOL_POST_SCRIPT}" CONTENT [[@ECHO OFF
SET DKCODER_PROGRAM=./dk dksdk.coder.run
"@DKCODER_NATIVE@" %*
]]
            @ONLY NEWLINE_STYLE DOS)
    else()
        file(CONFIGURE OUTPUT "${DKTOOL_POST_SCRIPT}" CONTENT [[#!/bin/sh
set -euf
export DKCODER_PROGRAM='./dk dksdk.coder.run'
exec "@DKCODER@" "$@"
]]
            @ONLY NEWLINE_STYLE DOS)
    endif()
endfunction()
