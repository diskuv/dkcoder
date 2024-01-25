##########################################################################
# File: dktool/cmake/scripts/dksdk/android/studio/run.cmake              #
#                                                                        #
# Copyright 2023 Diskuv, Inc.                                            #
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
    message(${ARG_MODE} [[usage: ./dk dksdk.android.studio.run
    [QUIET]
    ARGS <ARGS>

Searches for Android Studio and then runs it.

Examples
========

./dk dksdk.android.studio.run
    Runs Android Studio

Arguments
=========

HELP
  Print this help message.

ARGS <ARGS>
  The ARGS <ARGS> are just what you would pass to Android Studio itself.

QUIET
  Do not print CMake STATUS messages. This flag has no effect on Android Studio.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP QUIET)
    set(singleValues BINARY_DIR OUTPUT_FILE JAVA_HOME)
    set(multiValues ARGS)
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

    # Get helper functions from other commands
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/download.cmake)

    # Do prereqs
    install_android_studio()

    execute_process(
        COMMAND
        "${ANDROID_STUDIO}" ${ARG_ARGS}
        ENCODING UTF-8
        COMMAND_ERROR_IS_FATAL ANY)
endfunction()
