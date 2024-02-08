##########################################################################
# File: dktool\cmake\scripts\dksdk\project\inspect.cmake                 #
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

    message(${ARG_MODE} "usage: ./dk dksdk.project.inspect <command> [options]

Inspect the project.

Directory Structure
===================

The project folder is expected to contain at least:

./
├── cmake
│   └── scripts
│       └── __dk-find-scripts
├── dk
├── dk.cmd
└── dkproject.jsonc

Commands
========

VARIABLES
    Show variables available to `dkproject.jsonc`.

DEPENDENCIES
    Show dependencies defined by `dkproject.jsonc`. May contain sensitive
    data like authentication credentials so do not dump to CI console or
    any log file without a URL masker.

HELP
  Print this help message.

Common Options
==============

QUIET
  Do not print CMake STATUS messages.
")
endfunction()

function(dksdk_project_inspect_variables)
    set(noValues NONINTERACTIVE)
    set(singleValues LOG_LEVEL CONFIG_FILE)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # Fetch dksdk-access
    FetchContent_Populate(dksdk-access
            QUIET
            GIT_REPOSITORY https://gitlab.com/diskuv/dksdk-access.git
            GIT_TAG main
            GIT_SUBMODULES_RECURSE OFF)

    # Do get
    execute_process(
            COMMAND
            "${CMAKE_COMMAND}"
            -D "CONFIG_FILE=${ARG_CONFIG_FILE}"
            -D COMMAND_DUMP_VARIABLES=1
            -P "${dksdk-access_SOURCE_DIR}/cmake/run/get.cmake"
            COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()

function(dksdk_project_inspect_dependencies)
    set(noValues NONINTERACTIVE)
    set(singleValues LOG_LEVEL CONFIG_FILE)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # Fetch dksdk-access
    FetchContent_Populate(dksdk-access
            QUIET
            GIT_REPOSITORY https://gitlab.com/diskuv/dksdk-access.git
            GIT_TAG main
            GIT_SUBMODULES_RECURSE OFF)

    # Do get
    execute_process(
            COMMAND
            "${CMAKE_COMMAND}"
            -D "CONFIG_FILE=${ARG_CONFIG_FILE}"
            -D COMMAND_DUMP_DEPENDENCIES=1
            -P "${dksdk-access_SOURCE_DIR}/cmake/run/get.cmake"
            COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP QUIET VARIABLES DEPENDENCIES)
    set(singleValues)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
        help(MODE NOTICE)
        return()
    endif()

    # QUIET
    if(ARG_QUIET)
        set(logLevel DEBUG)
    else()
        set(logLevel STATUS)
    endif()

    # configFile
    set(configFile dkproject.jsonc)
    cmake_path(ABSOLUTE_PATH configFile BASE_DIRECTORY "${CMAKE_SOURCE_DIR}" NORMALIZE
            OUTPUT_VARIABLE configFileAbs)

    if(ARG_VARIABLES)
        dksdk_project_inspect_variables(LOG_LEVEL ${logLevel}
                CONFIG_FILE "${configFileAbs}")
    endif()
    if(ARG_DEPENDENCIES)
        dksdk_project_inspect_dependencies(LOG_LEVEL ${logLevel}
                CONFIG_FILE "${configFileAbs}")
    endif()
endfunction()
