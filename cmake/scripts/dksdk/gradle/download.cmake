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

Downloads Gradle.

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
")
endfunction()

function(install_java_gradle)
    set(hints ${CMAKE_SOURCE_DIR}/.ci/local/share/gradle/bin)
    if(CMAKE_HOST_WIN32)
        set(GRADLE_FILENAME gradle.bat)
    else()
        set(GRADLE_FILENAME gradle)
    endif()
    find_program(GRADLE NAMES ${GRADLE_FILENAME} HINTS ${hints})

    if(NOT GRADLE)
        # Download into .ci/local/share/gradle/bin (which is one of the HINTS)
        if(CMAKE_HOST_UNIX OR CMAKE_HOST_WIN32)
            set(url https://services.gradle.org/distributions/gradle-8.2.1-bin.zip)
            message(${loglevel} "Downloading Gradle from ${url}")
            file(DOWNLOAD ${url}
                ${CMAKE_CURRENT_BINARY_DIR}/gradle.zip
                EXPECTED_HASH SHA256=03ec176d388f2aa99defcadc3ac6adf8dd2bce5145a129659537c0874dea5ad1)
            message(${loglevel} "Extracting Gradle")
            file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/gradle.zip
                DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

            file(REMOVE_RECURSE ${CMAKE_CURRENT_BINARY_DIR}/gradle)
            file(RENAME ${CMAKE_CURRENT_BINARY_DIR}/gradle-8.2.1 ${CMAKE_CURRENT_BINARY_DIR}/gradle)
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

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;QUIET" "" "")

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
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../java/jdk/download.cmake)

    # Do prereqs
    install_java_jdk()

    install_java_gradle() # Set GRADLE
    message(STATUS "Gradle is at: ${GRADLE}")
endfunction()
