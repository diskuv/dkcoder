##########################################################################
# File: dktool\cmake\scripts\dksdk\project\get.cmake                     #
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

    message(${ARG_MODE} "usage: ./dk dksdk.project.get

Get the dependencies stated in the `dkproject.jsonc` file.

Directory Structure
===================

The dependencies will be placed into the `fetch/` directory.

./
├── cmake
│   └── scripts
│       └── __dk-find-scripts
├── dk
├── dk.cmd
├── dkproject.jsonc
└── fetch/
    ├── .gitignore
    ├── dune
    ├── project1/
    ├── project2/
    ├── ...
    └── projectN/

If `fetch/.gitignore` does not exist, it will be created but not overwritten.
The file will instruct Git to not look at the contents of the `fetch/` directory
during a `git add`.

If `fetch/dune` does not exist, it will be created but not overwritten.
The file will instruct Dune to not scan the `fetch/` directory during a `dune build`.

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

FETCH_DIR <dir>
  The directory to place the dependencies. Defaults to `fetch/`.
  Relative paths are interpreted relative to the `./dk` and `./dk.cmd` scripts.

NONINTERACTIVE
  Best effort attempt to stop `git` and any other source fetching tools from asking
  interactive questions like username/password prompts. Use when scripting.
")
endfunction()

function(dksdk_project_get)
    set(noValues NONINTERACTIVE)
    set(singleValues LOG_LEVEL FETCH_DIR CONFIG_FILE)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    message(${ARG_LOG_LEVEL} "Fetching dependencies into ${ARG_FETCH_DIR} ...")

    if(ARG_NONINTERACTIVE)
        set(interactive 0)
    else()
        set(interactive 1)
    endif()

    # Fetch dksdk-access
    FetchContent_Populate(dksdk-access
            QUIET
            GIT_REPOSITORY https://gitlab.com/diskuv/dksdk-access.git
            GIT_TAG main
            GIT_SUBMODULES_RECURSE OFF)

    # Do file exclusions now so that IDEs + build systems don't see/scan
    # content during the 'Do get' step

    #   Write .gitignore
    if(NOT EXISTS "${ARG_FETCH_DIR}/.gitignore")
        file(CONFIGURE OUTPUT "${ARG_FETCH_DIR}/.gitignore" CONTENT [[
# Generated by ./dk dksdk.project.get
#   Exclude everything except [dune] which [./dk dksdk.project.get] generates,
#   and exclude this file [.gitignore]
*
!dune
!.gitignore
]] @ONLY NEWLINE_STYLE UNIX)
    endif()

    #   Write dune
    if(NOT EXISTS "${ARG_FETCH_DIR}/dune")
        file(CONFIGURE OUTPUT "${ARG_FETCH_DIR}/dune" CONTENT [[
; Generated by ./dk dksdk.project.get
(dirs) ; disable scanning of any subdirectories
]] @ONLY NEWLINE_STYLE UNIX)
    endif()

    # Do get
    execute_process(
            COMMAND
            "${CMAKE_COMMAND}"
            -D INTERACTIVE=${interactive}
            -D "CONFIG_FILE=${ARG_CONFIG_FILE}"
            -D "COMMAND_GET=${ARG_FETCH_DIR}"
            -D "CACHE_DIR=${CMAKE_CURRENT_BINARY_DIR}"
            -P "${dksdk-access_SOURCE_DIR}/cmake/run/get.cmake"
            COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP QUIET NONINTERACTIVE)
    set(singleValues FETCH_DIR)
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

    # FETCH_DIR
    set(fetchDir fetch)
    if(ARG_FETCH_DIR)
        set(fetchDir ${ARG_FETCH_DIR})
    endif()
    cmake_path(ABSOLUTE_PATH fetchDir BASE_DIRECTORY "${CMAKE_SOURCE_DIR}" NORMALIZE
            OUTPUT_VARIABLE fetchDirAbs)

    # NONINTERACTIVE
    set(expand_NONINTERACTIVE)
    if(ARG_NONINTERACTIVE)
        set(expand_NONINTERACTIVE NONINTERACTIVE)
    endif()

    # configFile
    set(configFile dkproject.jsonc)
    cmake_path(ABSOLUTE_PATH configFile BASE_DIRECTORY "${CMAKE_SOURCE_DIR}" NORMALIZE
            OUTPUT_VARIABLE configFileAbs)

    dksdk_project_get(LOG_LEVEL ${logLevel}
            FETCH_DIR "${fetchDirAbs}"
            CONFIG_FILE "${configFileAbs}"
            ${expand_NONINTERACTIVE})
    message(STATUS "Project dependencies have been updated.")
endfunction()
