##########################################################################
# File: dktool/cmake/scripts/dksdk/cmake/link.cmake                      #
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
    message(${ARG_MODE} [[usage: ./dk dksdk.cmake.link

Creates a symlink, or a copy if symlinking is not available,
of the CMake, CTest and CPack executables into .ci/cmake/bin/.

Use `./dk dksdk.cmake.copy` if a full CMake installation is
needed inside .ci/cmake/.

Directory Structure
===================

.ci/cmake/bin
├── cmake
├── cpack
└── ctest

On Windows the files will be named cmake.exe, cpack.exe,
and ctest.exe in the ./ci/cmake/bin/ directory.

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print what files are being installed.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;QUIET" "" "")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    # QUIET
    if(ARG_QUIET)
        set(file_COMMAND COPY)
    else()
        set(file_COMMAND INSTALL)
    endif()

    # gitignore
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/cmake")
    file(COPY_FILE
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../_templates/all.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/cmake/.gitignore"
        ONLY_IF_DIFFERENT)

    set(ENV{CMAKE_INSTALL_MODE} ABS_SYMLINK_OR_COPY)
    file(${file_COMMAND} ${CMAKE_COMMAND} ${CMAKE_CTEST_COMMAND} ${CMAKE_CPACK_COMMAND}
        DESTINATION ${CMAKE_SOURCE_DIR}/.ci/cmake/bin
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
endfunction()
