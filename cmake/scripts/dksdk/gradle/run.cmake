##########################################################################
# File: dktool/cmake/scripts/dksdk/gradle/run.cmake                      #
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
    message(${ARG_MODE} [[usage: ./dk dksdk.gradle.run
    [OUTPUT_FILE <file>]
    [JAVA_HOME <JAVA_HOME>]
    [QUIET]
    ARGS <ARGS>

Searches for a JDK and then run Gradle.

Since the Android Gradle Plugin 8.1.0 requires JDK 17+ as of
2023, a limited search is performed for JDK 17+. Only macOS
has a robust JDK version search; other platforms just use
whatever JDK is in the PATH.

The minimum JDK version may be increased over time as Android
Gradle Plugin and other critical Gradle functionality raises
their minimums. If you want a stable JDK, use the JAVA_HOME
argument.

Examples
========

./dk dksdk.gradle.run ARGS tasks
    Print the Gradle tasks in the current project.

./dk dksdk.gradle.run ARGS build
    Build the Gradle project.

./dk dksdk.gradle.run ARGS -stop
    Stop all Gradle Daemons.

Arguments
=========

HELP
  Print this help message.

ARGS <ARGS>
  The ARGS <ARGS> are just what you would pass to Gradle itself, and
  are documented at https://docs.gradle.org/current/userguide/command_line_interface.html.

JAVA_HOME <JAVA_HOME>
  The location of the Java home. On Windows, spaces and backslashes cannot
  be encoded simply on the command line; for this situation use the
  JAVA_HOME environment variable.

OUTPUT_FILE <file>
  <file> is attached to the standard output pipe of the Gradle process.

QUIET
  Do not print CMake STATUS messages. This flag has no effect on Gradle.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP QUIET)
    set(singleValues OUTPUT_FILE JAVA_HOME)
    set(multiValues ARGS)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    if(NOT ARG_ARGS)
        help()
    endif()

    # QUIET
    if(ARG_QUIET)
        set(loglevel DEBUG)
    else()
        set(loglevel STATUS)
    endif()

    # OUTPUT_FILE
    set(execute_process_args)
    if(ARG_OUTPUT_FILE)
        list(APPEND execute_process_args OUTPUT_FILE "${ARG_OUTPUT_FILE}")
        set(clicolor 0)
    else()
        set(clicolor 1)
    endif()

    # Get helper functions from other commands
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../gradle/download.cmake)
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../java/jdk/download.cmake)

    # Do prereqs
    install_java_gradle()
    #   Set JAVA_HOME if available.
    #   Need JDK 17 since Android Gradle Plugin needs 17
    if(ARG_JAVA_HOME)
        set(JAVA_HOME ${ARG_JAVA_HOME})
    else()
        get_jdk_home(JDK_VERSION 17)
    endif()

    message(${loglevel} "Using JAVA_HOME: ${JAVA_HOME}")
    execute_process(
        COMMAND
        ${CMAKE_COMMAND} -E env
            JAVA_HOME=${JAVA_HOME}
            # Gradle jvmToolchain detection has problems if the Java
            # is not in the PATH.
            # https://github.com/ankidroid/Anki-Android/issues/13340#issuecomment-1445218572
            --modify "PATH=path_list_prepend:${JAVA_HOME}/bin"
        "${GRADLE}" ${ARG_ARGS}
        ENCODING UTF-8
        ${execute_process_args}
        COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()
