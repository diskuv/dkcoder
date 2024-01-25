##########################################################################
# File: dktool/cmake/scripts/dksdk/build/open.cmake                      #
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
    message(${ARG_MODE} [[usage: ./dk dksdk.build.open
    [BINARY_DIR <dir>]
    [QUIET]

Opens the project in a supported IDE:

- Xcode
- Other IDEs are guessed by CMake and operating system logic

Examples
========

./dk dksdk.build.open
    Opens the project generated in the `build_dev/` directory
    if it exists, otherwise opens the project in `build/`

./dk dksdk.build.open BINARY_DIR build
    Opens the project generated in the `build/` directory.

Arguments
=========

HELP
  Print this help message.

BINARY_DIR <dir>
  The CMake binary directory (sometimes called the CMake "build" directory).
  This binary directory contains a `CMakeCache.txt` file.

  The default is `build_dev` if it exists, or else `build`.

QUIET
  Do not print CMake STATUS messages. This flag has no effect on Dune.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP QUIET)
    set(singleValues BINARY_DIR)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    # QUIET
    if (ARG_QUIET)
        set(loglevel DEBUG)
    else ()
        set(loglevel STATUS)
    endif ()

    # BINARY_DIR
    if (ARG_BINARY_DIR)
        set(binaryDir "${ARG_BINARY_DIR}")
    else ()
        if (IS_DIRECTORY build_dev)
            set(binaryDir "build_dev")
        else ()
            set(binaryDir "build")
        endif ()
    endif ()
    cmake_path(ABSOLUTE_PATH binaryDir)
    message(${loglevel} "Using BINARY_DIR: ${binaryDir}")

    # Load CMAKE_GENERATOR and CMAKE_PROJECT_NAME from CMakeCache.txt
    load_cache(${binaryDir} READ_WITH_PREFIX BUILD_ CMAKE_GENERATOR CMAKE_PROJECT_NAME)

    if (NOT BUILD_CMAKE_GENERATOR)
        message(FATAL_ERROR "The CMAKE_GENERATOR cache variable was not found in ${binaryDir}. Re-configure your build directory.")
    endif ()
    if (NOT BUILD_CMAKE_PROJECT_NAME)
        message(FATAL_ERROR "The CMAKE_PROJECT_NAME cache variable was not found in ${binaryDir}. Re-configure your build directory.")
    endif ()

    set(opened)
    if (CMAKE_HOST_APPLE AND EXISTS ${binaryDir}/${BUILD_CMAKE_PROJECT_NAME}.xcodeproj)
        find_program(XED NAMES xed)
        if (XED)
            message(${loglevel} "Opening the project in Xcode")
            execute_process(
                    COMMAND
                    "${XED}" .
                    WORKING_DIRECTORY
                    "${binaryDir}"
                    COMMAND_ERROR_IS_FATAL ANY
            )
            set(opened TRUE)
        endif ()
    endif ()
    if (NOT opened)
        message(${loglevel} "Opening the project using an IDE selected by CMake")
        execute_process(
                COMMAND
                ${CMAKE_COMMAND} --open ${binaryDir}
                COMMAND_ERROR_IS_FATAL ANY
        )
    endif ()
endfunction()
