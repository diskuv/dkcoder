##########################################################################
# File: dkcoder/cmake/scripts/dksdk/project/new.cmake                     #
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

include_guard()

# Only follow symlinks during file(GLOB_RECURSE) when
# FOLLOW_SYMLINKS is given.
if(POLICY CMP0009)
    cmake_policy(SET CMP0009 NEW)
endif()

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")
    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()
    message(${ARG_MODE} [[usage: ./dk dksdk.project.new <ARGS>

                ---------------------
                WARNING: EXPERIMENTAL 
                ---------------------

This script has a high likelihood of disappearing or
drastically changing its behavior.

Arguments
=========

HELP
  Print this help message.

NAME name: Required. The name of the new project. The first letter must be
  a capital letter, and the whole name must not be all capital letters.
  It is strongly recommended to use a short prefix for your organization,
  like Dk for Diskuv.

  Example: DkHelloWorld.

DIR dir: Required. The location of the new project.

UPDATE: Flag you should use when you are updating an existing project.
  - Does not create files in <new project>/src/, <new project>/tests/
  - or <new project>/dependencies/
  - Does not create <new project>/README.md

Examples
========

./dk dksdk.project.new NAME DkExample DIR ../new-project
]])
endfunction()

function(do_install_file)
    set(noValues)
    set(singleValues PROJECT_NAME DESTINATION FILENAME)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(DESTDIR "${ARG_DESTINATION}")
    cmake_path(ABSOLUTE_PATH DESTDIR BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" NORMALIZE)

    file(READ ${ARG_FILENAME} contents)

    set(destmatch "${ARG_FILENAME}")
    message(NOTICE "-- Configuring: ${DESTDIR}/${destmatch}")

    string(REPLACE DkHelloWorld "${ARG_PROJECT_NAME}" contents "${contents}")
    #   Ex. DkHelloWorld_HelloLib.opam -> <name>_HelloLib.opam
    string(REPLACE DkHelloWorld_ "${ARG_PROJECT_NAME}_" destmatch "${destmatch}")
    #   Ex. DkHelloWorld.iml -> <name>.iml
    string(REPLACE DkHelloWorld. "${ARG_PROJECT_NAME}." destmatch "${destmatch}")

    # Write the file with proper permissions
    cmake_path(GET ARG_FILENAME EXTENSION LAST_ONLY extension)
    if(extension STREQUAL .sh)
        # Need shell scripts to have UNIX LF endings. That means we need
        # either file(CONFIGURE) or file(GENERATE) or configure_file().
        # All will transform the file tokens; we don't want it to, so we
        # use @ONLY to minimize the chance.
        file(CONFIGURE OUTPUT "${DESTDIR}/${destmatch}" CONTENT "${contents}"
            @ONLY NEWLINE_STYLE UNIX)
        file(CHMOD "${DESTDIR}/${destmatch}"
            FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    else()
        file(WRITE "${DESTDIR}/${destmatch}" "${contents}")
    endif()
endfunction()

function(do_install_files)
    set(noValues)
    set(singleValues PROJECT_NAME DESTINATION)
    set(multiValues SUBDIRS GLOBS)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    foreach(subdir IN LISTS ARG_SUBDIRS)
        set(SUBDIRGLOBS "${ARG_GLOBS}")
        list(TRANSFORM SUBDIRGLOBS PREPEND "${subdir}/")

        file(GLOB_RECURSE matches
            LIST_DIRECTORIES FALSE
            RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
            ${SUBDIRGLOBS})

        foreach(match IN LISTS matches)
            do_install_file(
                PROJECT_NAME ${ARG_PROJECT_NAME}
                DESTINATION ${ARG_DESTINATION}
                FILENAME ${match})
        endforeach()
    endforeach()
endfunction()

set(envrc [[#!/bin/sh
# Recommendation: Place this file in source control.
# Auto-generated by `./dk dksdk.project.new` of DkHelloWorld.
#
# If you need to modify the rules, do not edit this file,
# but place your changes in `user.envrc` in this directory.
for _dksdk_build_dir in build_dev build; do
    if [ -e "$_dksdk_build_dir/DkSDKFiles/ocaml_project.source.sh" ]; then
        # shellcheck disable=SC1090
        dotenv "$_dksdk_build_dir/DkSDKFiles/ocaml_project.source.sh"
        break
    fi
done
unset _dksdk_build_dir
if [ -n "${CMAKE_COMMAND_DIR:-}" ] && [ -x "$CMAKE_COMMAND_DIR/cmake" ]; then
    PATH_add "$CMAKE_COMMAND_DIR"
fi
if [ -n "${CMAKE_DUNE_DIR:-}" ] && [ -x "$CMAKE_DUNE_DIR/dune" ]; then
    PATH_add "$CMAKE_DUNE_DIR"
fi
if [ -n "${CMAKE_OCAMLDUNE_OPAM_HOME:-}" ] && [ -x "$CMAKE_OCAMLDUNE_OPAM_HOME/bin/opam" ]; then
    PATH_add "$CMAKE_OCAMLDUNE_OPAM_HOME/bin"
fi

# Lets you add your own modifications
source_env_if_exists user.envrc

# Advanced: If you uncomment, your IDEs won't work, but you can inspect your project with `opam list`.
# if [ -n "${CMAKE_OCAMLDUNE_OPAM_ROOT:-}" ] && [ -e "$CMAKE_OCAMLDUNE_OPAM_ROOT/config" ]; then
#     export OPAMROOT="$CMAKE_OCAMLDUNE_OPAM_ROOT"
# fi
# if [ -e "_dn/_opam/.opam-switch/switch-config" ]; then
#     export OPAMSWITCH="$(expand_path _dn)"
# fi
]])

set(build_and_test [[# Recommendation: Place this file in source control.
# Auto-generated by `./dk dksdk.project.new` of DkHelloWorld.

# These tests are for `ctest --build-and-test` style tests.
# They are not used often, but are useful when
# - Your project defines CMake functions for use by other
#   projects. Those CMake functions can be tested here in
#   a CMake project separate from the main CMake project.
# - Your project generates source code. That source code
#   can be generated in the main CMake project and then
#   tested here in a separate CMake project.
]])

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP UPDATE)
    set(singleValues NAME DIR)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    if(NOT ARG_NAME OR NOT ARG_DIR)
        help()
    endif()

    set(OUTPUT_DIR "${ARG_DIR}")
    cmake_path(ABSOLUTE_PATH OUTPUT_DIR)

    set(toplevel_files
        _all_cmake.dune
        .clang-format
        .gitattributes
        .gitignore
        .gitlab-ci.yml
        .ocamlformat
        CMakePresets.json
        CMakeUserPresets-SUGGESTED.json
        CTestConfig.cmake
        dk.cmd
        dune
    )
    set(toplevel_executables
        dk
    )
    if(NOT ARG_UPDATE)
        list(APPEND toplevel_files README.md)
    endif()
    file(INSTALL ${toplevel_files}
        DESTINATION ${OUTPUT_DIR})
    file(INSTALL ${toplevel_executables}
        DESTINATION ${OUTPUT_DIR}
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    do_install_file(
        PROJECT_NAME ${ARG_NAME}
        DESTINATION ${OUTPUT_DIR}
        FILENAME CMakeLists.txt)
    do_install_file(
        PROJECT_NAME ${ARG_NAME}
        DESTINATION ${OUTPUT_DIR}
        FILENAME dune-project)
    do_install_file(
        PROJECT_NAME ${ARG_NAME}
        DESTINATION ${OUTPUT_DIR}
        FILENAME DkSDK.md)

    file(INSTALL ci
        DESTINATION ${OUTPUT_DIR}
        FILES_MATCHING
        PATTERN "*.yml"
        PATTERN "dune")
    do_install_files(
        PROJECT_NAME ${ARG_NAME}
        SUBDIRS ci
        DESTINATION ${OUTPUT_DIR}
        GLOBS "*.sh" "*.cmd")

    file(INSTALL cmake
        DESTINATION ${OUTPUT_DIR}
        FILES_MATCHING
        # dkml/ and dksdk/ are system scripts that are automatically
        # downloaded by [dkcoder]
        REGEX "scripts/dkml" EXCLUDE
        REGEX "scripts/dksdk" EXCLUDE
        PATTERN "*.cmake")

    set(subdirs packaging)
    if(NOT ARG_UPDATE)
      list(APPEND subdirs dependencies src tests)
    endif()
    file(INSTALL ${subdirs}
        DESTINATION ${OUTPUT_DIR}
        FILES_MATCHING
        PATTERN "opam"
        PATTERN "*.md")
    do_install_files(
        PROJECT_NAME ${ARG_NAME}
        SUBDIRS ${subdirs}
        DESTINATION ${OUTPUT_DIR}
        GLOBS "CMakeLists.txt" "dune" "*.dune" "*.c" "*.h" "*.ml" "*.mli")

    # IntelliJ, CLion and other JetBrains. See .gitignore
    # for what can be included, or see
    # https://intellij-support.jetbrains.com/hc/en-us/articles/206544839
    do_install_files(
            PROJECT_NAME ${ARG_NAME}
            SUBDIRS .idea
            DESTINATION ${OUTPUT_DIR}
            GLOBS
            # .idea/
            "*.iml" .gitignore misc.xml modules.xml vcs.xml
            # .idea/codeStyles/
            Project.xml
            codeStyleConfig.xml
    )

    # Visual Studio Code
    do_install_files(
            PROJECT_NAME ${ARG_NAME}
            SUBDIRS .vscode
            DESTINATION ${OUTPUT_DIR}
            GLOBS
            c_cpp_properties.json extensions.json
    )

    # Not checked into git, so manually create
    message(NOTICE "-- Generating: ${OUTPUT_DIR}/CMakeUserPresets.json")
    configure_file(CMakeUserPresets-SUGGESTED.json ${OUTPUT_DIR}/CMakeUserPresets.json COPYONLY)

    # Not checked into git, so manually create
    message(NOTICE "-- Generating: ${OUTPUT_DIR}/.envrc")
    file(CONFIGURE OUTPUT ${OUTPUT_DIR}/.envrc
            CONTENT "${envrc}" @ONLY NEWLINE_STYLE LF)

    # We don't want the code generation integration tests in new projects, so
    # replace it with no-op
    message(NOTICE "-- Generating: ${OUTPUT_DIR}/tests/build-and-test/CMakeLists.txt")
    file(CONFIGURE OUTPUT ${OUTPUT_DIR}/tests/build-and-test/CMakeLists.txt
        CONTENT "${build_and_test}" @ONLY NEWLINE_STYLE LF)
endfunction()
