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

.ci/cmake/
├── bin
│   ├── cmake -> .../cmake-MAJOR.MINOR.PATCH/bin/cmake
│   ├── cmake.exe -> cmake
│   ├── cpack -> .../cmake-MAJOR.MINOR.PATCH/bin/cpack
│   ├── cpack.exe -> cpack
│   └── ctest -> .../cmake-MAJOR.MINOR.PATCH/bin/ctest
│   └── ctest.exe -> ctest
└── share
    └── cmake-MAJOR.MINOR -> .../cmake-MAJOR.MINOR.PATCH/share/cmake-MAJOR.MINOR/
        ├── include
        ├── Modules
        └── Templates

On Windows the files will be named cmake.exe, cpack.exe,
and ctest.exe in the ./ci/cmake/bin/ directory, and no
cmake, cpack and ctest files will exist.

On Unix only the cmake, cpack and ctest files will exist,
unless the EXE flag is used. With the EXE flag the cmake.exe,
cpack.exe, and ctest.exe symlinks will be created.

The share/cmake-MAJOR.MINOR directory (the CMAKE_ROOT) may
have contents different from what you see above. The entire
CMAKE_ROOT is linked (or copied if symlinks are not available).

Arguments
=========

HELP
  Print this help message.

EXE
  Create cmake.exe, cpack.exe and ctest.exe symlinks to the
  cmake, cpack and ctest binaries on Unix. Does nothing on
  Windows. This flag exists for the use of tools like Visual Studio
  Code extension CMake Tools that must use hardcoded paths
  that can't vary across operating systems, especially
  when saved in shareable files like .vscode/settings.json.

QUIET
  Do not print what files are being installed.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;QUIET;EXE" "" "")

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
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../__dk-tmpl/all.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/cmake/.gitignore"
        ONLY_IF_DIFFERENT)

    # bin/
    set(ENV{CMAKE_INSTALL_MODE} ABS_SYMLINK_OR_COPY)
    set(dest_BIN ${CMAKE_SOURCE_DIR}/.ci/cmake/bin)
    file(${file_COMMAND} ${CMAKE_COMMAND} ${CMAKE_CTEST_COMMAND} ${CMAKE_CPACK_COMMAND}
        DESTINATION ${dest_BIN}
        FOLLOW_SYMLINK_CHAIN
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

    if(CMAKE_HOST_UNIX AND ARG_EXE)
        file(CREATE_LINK cmake ${dest_BIN}/cmake.exe COPY_ON_ERROR SYMBOLIC)
        file(CREATE_LINK cpack ${dest_BIN}/cpack.exe COPY_ON_ERROR SYMBOLIC)
        file(CREATE_LINK ctest ${dest_BIN}/ctest.exe COPY_ON_ERROR SYMBOLIC)
    endif()

    # <CMAKE_ROOT>/
    file(${file_COMMAND} ${CMAKE_ROOT} DESTINATION ${CMAKE_SOURCE_DIR}/.ci/cmake/share FOLLOW_SYMLINK_CHAIN)
endfunction()
