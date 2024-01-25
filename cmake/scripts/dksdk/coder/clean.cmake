##########################################################################
# File: dktool\cmake\scripts\dksdk\coder\clean.cmake                     #
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

    message(${ARG_MODE} "usage: ./dk dksdk.coder.clean

Removes the `dkcoder` environment if it was installed.

Use when you need to reclaim the space from `${DKCODER_HOME_NATIVE}` and
`${DKCODER_COMPILEDIR_NATIVE}.

You can also force an upgrade to the latest `dkcoder` environment by running
this `dksdk.coder.clean` command, and then doing any other `dksdk.coder.*`
command like `dksdk.coder.compile`.

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.
")
endfunction()

function(dkcoder_uninstall)
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

    set(noValues HELP QUIET)
    set(singleValues)
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

    dkcoder_uninstall(LOGLEVEL ${loglevel})
endfunction()
