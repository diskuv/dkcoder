##########################################################################
# File: dkcoder/cmake/scripts/dksdk/java/jdk/download.cmake               #
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

    message(${ARG_MODE} "usage: ./dk dksdk.java.jdk.download

Downloads Java JDK if a JDK is not detected.

Directory Structure
===================

Places the JDK in .ci/local/share/jdk:

.ci/local/share/
└── jdk
    ├── bin
    │   ├── jar
    │   ├── jarsigner
    │   ├── java
    │   ├── javac
    │   ├── ...
    │   ├── keytool
    │   ├── rmiregistry
    │   └── serialver
    ├── conf
    ├── include
    ├── lib
    └── release

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

JDK 17
  Install JDK 17 (the default).

JDK 8
  Install JDK 8 to .ci/local/share/jdk8 rather than the default JDK 17.

NO_SYSTEM_PATH
  Do not check for a JDK in well-known locations and in the PATH.
  Instead, install a JDK if no JDK exists at `.ci/local/share/jdk`.
")
endfunction()

macro(set_jdk_folder)
    if(JDK_VERSION EQUAL 8)
        set(JDK_FOLDER jdk8)
    else()
        set(JDK_FOLDER jdk)
    endif()
endmacro()

# This is used by other scripts to find the JAVA_HOME.
#
# If the JAVA_HOME environment variable is already defined
# and non-empty and present on the file system, it is used.
#
# JDK_VERSION: A optional minimum version like "17". Defaults to 8.
#   Currently only works on macOS which has a robust JDK Version
#   search. On other operating systems, the first JDK in the PATH
#   will be used.
#
# Outputs:
# - JAVA_HOME - May be empty if, for example, java is /usr/bin/java.
function(get_jdk_home)
    set(noValues)
    set(singleValues JDK_VERSION)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(JDK_VERSION 8)
    if(ARG_JDK_VERSION)
        set(JDK_VERSION ${ARG_JDK_VERSION})
    endif()
    set_jdk_folder()

    # JAVA_HOME in the environment
    if(DEFINED ENV{JAVA_HOME} AND IS_DIRECTORY "$ENV{JAVA_HOME}")
        set(JAVA_HOME $ENV{JAVA_HOME} PARENT_SCOPE)
        return()
    endif()

    # Apple has a standard to locate JDKs. But we'll prefer the local JDK if present.
    if(CMAKE_HOST_APPLE)
        set(JAVA_HOME "${CMAKE_SOURCE_DIR}/.ci/local/share/jdk/Contents/Home")
        if(EXISTS "${JAVA_HOME}/bin/javac")
            set(JAVA_HOME "${JAVA_HOME}" PARENT_SCOPE)
            return()
        endif()
        execute_process(
            COMMAND /usr/libexec/java_home -v "${JDK_VERSION}"
            OUTPUT_VARIABLE JAVA_HOME
            OUTPUT_STRIP_TRAILING_WHITESPACE
            COMMAND_ERROR_IS_FATAL ANY)
        set(JAVA_HOME "${JAVA_HOME}" PARENT_SCOPE)
        return()
    endif()

    set(hints "${CMAKE_SOURCE_DIR}/.ci/local/share/jdk/bin")

    # Search for [javac] which is part of the JDK but not the JRE
    find_program(JAVAC NAMES javac REQUIRED HINTS ${hints})
    # /usr/bin/javac -> /usr/bin
    cmake_path(GET JAVAC PARENT_PATH JAVAC_DIR)

    # From [javac] find a sibling [java]
    find_program(JAVA NAMES java REQUIRED HINTS "${JAVAC_DIR}" ${hints})

    # On Windows we can get [C:\Program Files\Common Files\Oracle\Java\javapath\javac.exe]
    # which is _not_ the location of JAVA_HOME. We use
    # [java -XshowSettings:properties -version] to find the Java home:
    #   Property settings:
    #       ...
    #       java.home = C:\Program Files\Java\jdk-17.0.3.1
    execute_process(
        COMMAND ${JAVA} -XshowSettings:properties -version
        ERROR_VARIABLE javaProperties
        RESULT_VARIABLE javaFailed
    )
    if(NOT javaFailed)
        # Ex. java.home = C:\Program Files\Java\jdk-17.0.3.1
        string(REGEX MATCH " +java.home = [^\n]+" JAVA_HOME_LINE "${javaProperties}")
        if(JAVA_HOME_LINE)
            # Ex. C:\Program Files\Java\jdk-17.0.3.1
            string(REGEX REPLACE " +java.home = " "" JAVA_HOME "${JAVA_HOME_LINE}")
        endif()
        set(JAVA_HOME "${JAVA_HOME}" PARENT_SCOPE)
        return()
    endif()

    # Fallback: Guess from the location of javac ... but only if
    # a .../bin/javac location that is not a Linux FHS directory like
    # /usr/bin or /usr/local/bin

    # /usr/bin -> bin
    cmake_path(GET JAVAC_DIR FILENAME JAVAC_DIRNAME)
    if(JAVAC_DIRNAME STREQUAL "bin" AND
        NOT JAVAC_DIR STREQUAL /usr/bin AND
        NOT JAVAC_DIR STREQUAL /usr/local/bin)
        cmake_path(GET JAVAC_DIR PARENT_PATH JAVA_HOME)
    endif()
    set(JAVA_HOME "${JAVA_HOME}" PARENT_SCOPE)
endfunction()

# Java is needed to run the Android SDK Manager.
# We use Temurin for JDK when needed and if available. Recommended by
# https://formulae.brew.sh/cask/android-commandlinetools.
# Temurin and alternatives are at: https://adoptium.net/marketplace/
#
# Outputs:
# - JAVAC
# - JAVA
function(install_java_jdk)
    set(noValues NO_SYSTEM_PATH)
    set(singleValues JDK_VERSION)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(JDK_VERSION ${ARG_JDK_VERSION})
    set_jdk_folder()

    set(hints "${CMAKE_SOURCE_DIR}/.ci/local/share/${JDK_FOLDER}/bin")
    if(CMAKE_HOST_APPLE)
        list(PREPEND hints "${CMAKE_SOURCE_DIR}/.ci/local/share/${JDK_FOLDER}/Contents/Home/bin")
    endif()
    set(find_program_INITIAL)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND find_program_INITIAL NO_DEFAULT_PATH)
    endif()
    find_program(JAVAC NAMES javac HINTS ${hints} ${find_program_INITIAL})

    if(NOT JAVAC)
        # Download into .ci/local/share/jdk/bin (which is one of the HINTS)
        set(downloaded)
        if(CMAKE_HOST_WIN32)
            set(url https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1%2B1/OpenJDK17U-jdk_x64_windows_hotspot_17.0.8.1_1.zip)
            set(out_base jdk-17.0.8.1+1)
            message(${loglevel} "Downloading Temurin JDK from ${url}")
            file(DOWNLOAD ${url}
                ${CMAKE_CURRENT_BINARY_DIR}/java.zip
                EXPECTED_HASH SHA256=651a795155dc918c06cc9fd4b37253b9cbbca5ec8e76d4a8fa7cdaeb1f52761c)
            message(${loglevel} "Extracting JDK")
            file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/java.zip DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
            set(downloaded ON)
        elseif(CMAKE_HOST_APPLE)
            execute_process(COMMAND uname -m
                    OUTPUT_VARIABLE host_machine_type
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    COMMAND_ERROR_IS_FATAL ANY)
            if(host_machine_type STREQUAL x86_64)
                set(url https://aka.ms/download-jdk/microsoft-jdk-17.0.8.1-macOS-x64.tar.gz)
                set(out_base jdk-17.0.8.1+1)
                set(expected_sha256 e67ed748b9ef6d4557da24beefe9d9ec193e9d9f843be5ff6559a275e0d230b6)
            elseif(host_machine_type STREQUAL arm64)
                if(JDK_VERSION EQUAL 8)
                    set(url https://cdn.azul.com/zulu/bin/zulu8.78.0.19-ca-jdk8.0.412-macosx_aarch64.tar.gz)
                    set(out_base zulu8.78.0.19-ca-jdk8.0.412-macosx_aarch64)
                    set(expected_sha256 35bc35808379400e4a70e1f7ee379778881799b93c2cc9fe1ae515c03c2fb057)
                else()
                    set(url https://aka.ms/download-jdk/microsoft-jdk-17.0.8.1-macOS-aarch64.tar.gz)
                    set(out_base jdk-17.0.8.1+1)
                    set(expected_sha256 8acda4fa59946902180a9283ee191b3db19b8c1146fb8dfa209d316ec78f9a5f)
                endif()
            else()
                message(FATAL_ERROR "Your APPLE ${host_machine_type} platform is currently not supported by this download script")
            endif()
            message(${loglevel} "Downloading JDK from ${url}")                
            file(DOWNLOAD ${url} ${CMAKE_CURRENT_BINARY_DIR}/java.tar.gz EXPECTED_HASH SHA256=${expected_sha256})
            message(${loglevel} "Extracting JDK")
            file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/java.tar.gz DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
            set(downloaded ON)
        elseif(CMAKE_HOST_UNIX)
            execute_process(COMMAND uname -m
                    OUTPUT_VARIABLE host_machine_type
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    COMMAND_ERROR_IS_FATAL ANY)
            if(host_machine_type STREQUAL x86_64)
                set(url https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.6%2B10/OpenJDK17U-jdk_x64_linux_hotspot_17.0.6_10.tar.gz)
                set(out_base jdk-17.0.6+10)
                message(${loglevel} "Downloading Temurin JDK from ${url}")
                file(DOWNLOAD ${url}
                    ${CMAKE_CURRENT_BINARY_DIR}/java.tar.gz
                    EXPECTED_HASH SHA256=a0b1b9dd809d51a438f5fa08918f9aca7b2135721097f0858cf29f77a35d4289)
            elseif(host_machine_type STREQUAL i686)
                set(url https://cdn.azul.com/zulu/bin/zulu17.42.19-ca-jdk17.0.7-linux_i686.tar.gz)
                set(out_base zulu17.42.19-ca-jdk17.0.7-linux_i686)
                message(${loglevel} "Downloading Zulu JDK from ${url}")
                file(DOWNLOAD ${url}
                    ${CMAKE_CURRENT_BINARY_DIR}/java.tar.gz
                    EXPECTED_HASH SHA256=53a66b711d828deae801870143b00be2cf4563ce283d393b08b7b96a846dabd8)
            else()
                message(FATAL_ERROR "Your UNIX ${host_machine_type} platform is currently not supported by this download script")
            endif()
            message(${loglevel} "Extracting JDK")
            file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/java.tar.gz DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
            set(downloaded ON)
        endif()
        if(downloaded)
            file(REMOVE_RECURSE "${CMAKE_SOURCE_DIR}/.ci/local/share/${JDK_FOLDER}")
            file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/local/share/${JDK_FOLDER}")

            # gitignore
            file(COPY_FILE
                "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../__dk-tmpl/all.gitignore"
                "${CMAKE_SOURCE_DIR}/.ci/local/share/${JDK_FOLDER}/.gitignore"
                ONLY_IF_DIFFERENT)

            # Do file(RENAME) but work across mount volumes (ex. inside containers)
            file(GLOB entries
                LIST_DIRECTORIES true
                RELATIVE "${CMAKE_CURRENT_BINARY_DIR}/${out_base}"
                ${CMAKE_CURRENT_BINARY_DIR}/${out_base}/*)
            foreach(entry IN LISTS entries)
                file(COPY "${CMAKE_CURRENT_BINARY_DIR}/${out_base}/${entry}"
                    DESTINATION "${CMAKE_SOURCE_DIR}/.ci/local/share/${JDK_FOLDER}"
                    # [FOLLOW_SYMLINK_CHAIN] fails on JDK8 macos with bin -> bin
                    USE_SOURCE_PERMISSIONS)
            endforeach()
            file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/${out_base}")
        else()
            message(FATAL_ERROR "Your platform is currently not supported by this download script")
        endif()

        find_program(JAVAC NAMES javac REQUIRED HINTS ${hints})
    endif()
    find_program(JAVA NAMES java REQUIRED HINTS ${hints})
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;QUIET;NO_SYSTEM_PATH" "JDK" "")

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

    # JDK
    set(args_JDK JDK_VERSION 17)
    if(ARG_JDK EQUAL 8)
        set(args_JDK JDK_VERSION 8)
    endif()

    # NO_SYSTEM_PATH
    set(expand_NO_SYSTEM_PATH)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND expand_NO_SYSTEM_PATH NO_SYSTEM_PATH)
    endif()

    install_java_jdk(${expand_NO_SYSTEM_PATH} ${args_JDK})
    message(STATUS "javac compiler is at: ${JAVAC}")
endfunction()
