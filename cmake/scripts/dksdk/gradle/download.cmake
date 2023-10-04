##########################################################################
# File: dktool/cmake/scripts/dksdk/gradle/download.cmake                 #
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

    message(${ARG_MODE} "usage: ./dk dksdk.gradle.download

Downloads Gradle and if needed Java JDK as well.

Directory Structure
===================

Places Gradle in .ci/local/share/gradle:

.ci/local/share/
└── gradle
    ├── bin/
    │   ├── gradle
    │   └── gradle.bat
    └── lib/
        ├── agents/
        │   └── gradle-instrumentation-agent-8.2.1.jar
        ├── annotations-24.0.0.jar
        ├── ant-1.10.13.jar
        ├── ...
        ├── plugins/
        │   ├── aws-java-sdk-core-1.12.365.jar
        │   ├── ...
        │   └── testng-6.3.1.jar
        └── xml-apis-1.4.01.jar

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

VERSION <version>
  Use a specific version of Gradle.

  The following versions are supported:
  - 7.6
  - 8.3

ALL
  Use the 'all' distribution type for Gradle, which
  allows IDE code-completion and navigation to Gradle
  source code. You won't need this flag for CI builds
  like GitHub Actions and GitLab CI/CD.

NO_SYSTEM_PATH
  Do not check for Gradle in well-known locations and in the PATH.
  Instead, if no Gradle exists at `.ci/local/share/gradle`, then
  1. Install Gradle at `.ci/local/share/gradle`
  2. If the JDK hadn't been installed at `.ci/local/share/jdk`
     then install the JDK at `.ci/local/share/jdk`
")
endfunction()

function(install_java_gradle)
    set(noValues NO_SYSTEM_PATH ALL)
    set(singleValues VERSION)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(version ${ARG_VERSION})
    if(NOT version)
        set(version 8.3)
    endif()

    # VERSION map
    if(version STREQUAL 7.6)
        if(ARG_ALL)
            set(url https://services.gradle.org/distributions/gradle-7.6-all.zip)
            set(urlhash SHA256=312eb12875e1747e05c2f81a4789902d7e4ec5defbd1eefeaccc08acf096505d)
        else()
            set(url https://services.gradle.org/distributions/gradle-7.6-bin.zip)
            set(urlhash SHA256=7ba68c54029790ab444b39d7e293d3236b2632631fb5f2e012bb28b4ff669e4b)
        endif()
    elseif(version STREQUAL 8.3)
        if(ARG_ALL)
            set(url https://services.gradle.org/distributions/gradle-8.3-all.zip)
            set(urlhash SHA256=bb09982fdf52718e4c7b25023d10df6d35a5fff969860bdf5a5bd27a3ab27a9e)
        else()
            set(url https://services.gradle.org/distributions/gradle-8.3-bin.zip)
            set(urlhash SHA256=591855b517fc635b9e04de1d05d5e76ada3f89f5fc76f87978d1b245b4f69225)
        endif()
    else()
        message(FATAL_ERROR "The only supported versions of Gradle are 7.6 and 8.3, not ${version}")
    endif()

    set(hints ${CMAKE_SOURCE_DIR}/.ci/local/share/gradle/bin)
    set(find_program_INITIAL)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND find_program_INITIAL NO_DEFAULT_PATH)
    endif()
    if(CMAKE_HOST_WIN32)
        set(GRADLE_FILENAME gradle.bat)
    else()
        set(GRADLE_FILENAME gradle)
    endif()
    find_program(GRADLE NAMES ${GRADLE_FILENAME} HINTS ${hints} ${find_program_INITIAL})

    if(NOT GRADLE)
        # Download into .ci/local/share/gradle/bin (which is one of the HINTS)
        if(CMAKE_HOST_UNIX OR CMAKE_HOST_WIN32)
            message(${loglevel} "Downloading Gradle from ${url}")
            file(DOWNLOAD ${url}
                ${CMAKE_CURRENT_BINARY_DIR}/gradle.zip
                EXPECTED_HASH ${urlhash})
            message(${loglevel} "Extracting Gradle")
            file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/gradle.zip
                DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

            file(REMOVE_RECURSE ${CMAKE_CURRENT_BINARY_DIR}/gradle)
            file(RENAME ${CMAKE_CURRENT_BINARY_DIR}/gradle-${version} ${CMAKE_CURRENT_BINARY_DIR}/gradle)
            file(REMOVE_RECURSE ${CMAKE_SOURCE_DIR}/.ci/local/share/gradle)
            file(COPY ${CMAKE_CURRENT_BINARY_DIR}/gradle DESTINATION ${CMAKE_SOURCE_DIR}/.ci/local/share)
        else()
            message(FATAL_ERROR "Your platform is currently not supported by this download script")
        endif()

        find_program(GRADLE NAMES ${GRADLE_FILENAME} REQUIRED HINTS ${hints})
    endif()
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION}")

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;QUIET;NO_SYSTEM_PATH;ALL" "VERSION" "")

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

    # NO_SYSTEM_PATH
    set(expand_NO_SYSTEM_PATH)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND expand_NO_SYSTEM_PATH NO_SYSTEM_PATH)
    endif()

    # ALL
    set(expand_ALL)
    if(ARG_ALL)
        list(APPEND expand_ALL ALL)
    endif()

    # VERSION
    set(expand_VERSION)
    if(ARG_VERSION)
        list(APPEND expand_VERSION VERSION ${ARG_VERSION})
    endif()

    # Get helper functions from other commands
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../java/jdk/download.cmake)

    # Do prereqs
    install_java_jdk(${expand_NO_SYSTEM_PATH})

    install_java_gradle(${expand_NO_SYSTEM_PATH} ${expand_ALL} ${expand_VERSION}) # Sets GRADLE

    # gitignore (done after install_java_gradle() since that removes the gradle dir)
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/local/share/gradle")
    file(COPY_FILE
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../__dk-tmpl/all.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/local/share/gradle/.gitignore"
        ONLY_IF_DIFFERENT)

    message(STATUS "Gradle is at: ${GRADLE}")
endfunction()
