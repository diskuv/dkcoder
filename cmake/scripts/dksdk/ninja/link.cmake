##########################################################################
# File: dktool/cmake/scripts/dksdk/ninja/link.cmake                      #
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
    message(${ARG_MODE} [[usage: ./dk dksdk.ninja.link

Creates a symlink, or a copy if symlinking is not available,
of the Ninja executable into .ci/ninja/bin/.

Directory Structure
===================

.ci/ninja/bin
└── ninja

On Windows the file will be named ninja.exe in the ./ci/ninja/bin/ directory.

Arguments
=========

HELP
  Print this help message.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP" "" "")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    # gitignore
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/ninja")
    file(COPY_FILE
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../__dk-tmpl/all.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/ninja/.gitignore"
        ONLY_IF_DIFFERENT)

    set(ENV{CMAKE_INSTALL_MODE} ABS_SYMLINK_OR_COPY)
    file(INSTALL ${CMAKE_MAKE_PROGRAM}
        DESTINATION ${CMAKE_SOURCE_DIR}/.ci/ninja/bin
        FOLLOW_SYMLINK_CHAIN
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
endfunction()
