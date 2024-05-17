##########################################################################
# File: dkcoder/cmake/scripts/dksdk/dune/run.cmake                        #
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
    message(${ARG_MODE} [[usage: ./dk dksdk.dune.run
    [BINARY_DIR <dir>]
    [OUTPUT_FILE <file>]
    [QUIET]
    ARGS <ARGS>

Examples
========

> On Windows, please read the Windows section below before running
> these examples.

./dk dksdk.dune.run ARGS build
    Builds the OCaml parts of the project.

./dk dksdk.dune.run ARGS build -w
    Builds the OCaml parts of the project in watch mode, where
    it rebuilds whenever a change is detected in an OCaml file.

./dk dksdk.dune.run ARGS fmt
    Formats the OCaml source code.

./dk dksdk.dune.run ARGS runtest
    Runs OCaml tests.

Arguments
=========

HELP
  Print this help message.

BINARY_DIR <dir>
  The CMake binary directory (sometimes called the CMake "build" directory).
  This binary directory contains a `CMakeCache.txt` file.

  The default is `build_dev` if it exists, or else `build`.

ARGS <ARGS>
  The ARGS <ARGS> are just what you would pass to dune itself, and
  are documented at https://dune.readthedocs.io/en/stable/usage.html.

OUTPUT_FILE <file>
  <file> is attached to the standard output pipe of the dune process.

QUIET
  Do not print CMake STATUS messages. This flag has no effect on Dune.

Platform Specific Instructions
==============================

Windows
-------

On Windows, you will need the Visual Studio environment variables
defined. There are three ways to do that.

1. **Only if you installed DkML**.

    You can start your commands with `with-dkml`.
    For example, instead of typing
    
      ./dk dksdk.dune.run ARGS build

    you type

      with-dkml ./dk dksdk.dune.run ARGS build
  
2. **Only if you installed DkML, or know where Visual Studio is installed**.

    Open the Command Prompt and run the `VsDevCmd.bat` script from the
    installation location. For DkML, run:

    C:\DiskuvOCaml\BuildTools\Common7\Tools\VsDevCmd.bat -arch=amd64

3. **Only if you have only one Visual Studio installation on your machine**.

    Run `x64 Native Tools Command Prompt for VS 2019` from Windows Search (just
    press the Windows key, and then start typing `x64 Native ...`).

Only then will `./dk dksdk.dune.run ARGS build` not complain about missing
`advapi32.lib` or `cl.exe`.      
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP QUIET)
    set(singleValues BINARY_DIR OUTPUT_FILE)
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

    # BINARY_DIR
    if(ARG_BINARY_DIR)
        set(binaryDir "${ARG_BINARY_DIR}")
    else()
        if(IS_DIRECTORY build_dev)
            set(binaryDir "build_dev")
        else()
            set(binaryDir "build")
        endif()
    endif()
    cmake_path(ABSOLUTE_PATH binaryDir)
    message(${loglevel} "Using BINARY_DIR: ${binaryDir}")

    # OUTPUT_FILE
    set(execute_process_args)
    if(ARG_OUTPUT_FILE)
        list(APPEND execute_process_args OUTPUT_FILE "${ARG_OUTPUT_FILE}")
        set(clicolor 0)
    else()
        set(clicolor 1)
    endif()

    # Load CMAKE_DUNE from CMakeCache.txt
    load_cache(${binaryDir} READ_WITH_PREFIX BUILD_ CMAKE_DUNE)

    if(NOT BUILD_CMAKE_DUNE)
        message(FATAL_ERROR "The CMAKE_DUNE cache variable was not found in ${binaryDir}. DkSDK projects will have that cache variable defined, but you need to configure (ex. `cmake -G Ninja ...`) the DkSDK project first.")
    endif()

    message(${loglevel} "Using dune: ${BUILD_CMAKE_DUNE} (${CMAKE_CURRENT_SOURCE_DIR})")
    execute_process(
        COMMAND
        ${CMAKE_COMMAND} -E env
            CLICOLOR=${clicolor}
            DUNE_WORKSPACE=${binaryDir}/DkSDKFiles/165/dune-workspace
        "${BUILD_CMAKE_DUNE}" ${ARG_ARGS}
        ENCODING UTF-8
        ${execute_process_args}
        COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()
