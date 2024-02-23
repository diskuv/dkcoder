##########################################################################
# File: dktool/cmake/scripts/dksdk/cmd/exec.cmake                        #
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

# `${CMAKE_COMMAND} -E env --modify` only in 3.25+
cmake_minimum_required(VERSION 3.25)

function(help)
    message(FATAL_ERROR [[usage: ./dk dksdk.cmd.exec
    [BINARY_DIR <dir>]
    [QUIET]
    CMD <PROG> <ARGS>

Sets up the correct PATH and other environment variables so that the following
<PROG> can be run from the command line, especially in IDEs like Visual Studio Code,
if they have been built in DkSDK:
    dune
    flexlink
    ocamlc
    ocamlfind
    ocamllsp

Typically you build the DevTools target to ensure all the above binaries are available.

Examples
========

./dk dksdk.cmd.exec CMD ocamllsp
    Run the OCaml Language Server.

Visual Studio Code
==================

1. Build the DevTools target first (or at least the ocamllsp-Build target).
2. You have two choices to select the *sandbox* (View > Command Palette, and then
   "OCaml: Select a Sandbox for this Workspace").

   Either:
   1. Use "Global OCaml". Prerequisite: You will need to have launched Visual
      Studio Code with `./dk dksdk.cmd.exec CMD code .`
   2. Use "Custom" sandbox with the following command line (change the path):

      # Windows
      C:\source\DkHelloWorld\dk.cmd dksdk.cmd.exec QUIET CMD $prog $args

      # macOS or Linux
      /Volumes/Source/DkHelloWorld/dk dksdk.cmd.exec QUIET CMD $prog $args

Arguments
=========

BINARY_DIR <dir>
  The CMake binary directory (sometimes called the CMake "build" directory).
  This binary directory contains a `CMakeCache.txt` file.

  The default is `build_dev` if it exists, or else `build`.

CMD <PROG> <ARGS>
  The <PROG> <ARGS> are the command line to run. dksdk.cmd.exec will
  search for <PROG> if it is not an absolute path.

QUIET
  Do not print CMake STATUS messages. This flag has no effect on the
  executed CMD.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues QUIET)
    set(singleValues BINARY_DIR)
    set(multiValues CMD)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(NOT ARG_CMD)
        help()
    endif()

    # QUIET
    if(ARG_QUIET)
        set(loglevel DEBUG)
    else()
        set(loglevel STATUS)
    endif()

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

    # Logs
    file(APPEND ${CMAKE_CURRENT_SOURCE_DIR}/_build/dksdk-cmd-exe.log "${ARG_CMD}\n")

    # Load CMAKE_DUNE from CMakeCache.txt
    set(cmakeExecutableVars CMAKE_DUNE CMAKE_FLEXLINK CMAKE_OCAMLFIND)
    load_cache(${binaryDir} READ_WITH_PREFIX BUILD_
        ${cmakeExecutableVars}
        CMAKE_OCamlDune_COMPILER CMAKE_OCamlDune_COMPILER_HOST)

    # Get locations where generated binaries are
    list(GET ARG_CMD 0 prog)
    set(hints)
    list(APPEND hints ${CMAKE_CURRENT_SOURCE_DIR}/_build/install/default/bin)
    if(BUILD_CMAKE_OCamlDune_COMPILER_HOST)
        cmake_path(GET BUILD_CMAKE_OCamlDune_COMPILER_HOST PARENT_PATH hostBinDir)
        list(APPEND hints ${hostBinDir})
    elseif(BUILD_CMAKE_OCamlDune_COMPILER)
        cmake_path(GET BUILD_CMAKE_OCamlDune_COMPILER PARENT_PATH hostBinDir)
        list(APPEND hints ${hostBinDir})
    endif()
    foreach(execVar IN LISTS cmakeExecutableVars)
        if(BUILD_${execVar})
            cmake_path(GET BUILD_${execVar} PARENT_PATH execBinDir)
            list(APPEND hints ${execBinDir})
        endif()
    endforeach()
    list(REMOVE_DUPLICATES hints)

    # Also include DkSDKFiles/dune-home/dune since CMAKE_DUNE is often 'CMAKE_DUNE-NOTFOUND'
    list(APPEND hints "${binaryDir}/DkSDKFiles/dune-home")

    # Find the program asked for
    find_program(PROG_EXE NAMES ${prog} HINTS ${hints})

    set(cmdPrefix)

    # For ocamllsp in particular ...
    if(prog STREQUAL ocamllsp)
        # It needs to know where dune is ...
        # | Internal error: Uncaught exception.
        # | jsonrpc response error { "code": -32603, "message": "dune binary not found" }
        # | Raised at Jsonrpc.Response.Error.raise in file "_dn/_opam/.opam-switch/build/ocaml-lsp-server.1.15.1-4.14/jsonrpc/src/jsonrpc.ml", line 188, characters 18-29
        # | Called from Ocaml_lsp_server__Merlin_config.get_process in file "_dn/_opam/.opam-switch/build/ocaml-lsp-server.1.15.1-4.14/ocaml-lsp-server/src/m", line 267, characters 19-37
        # | Called from Ocaml_lsp_server__Merlin_config.config in file "_dn/_opam/.opam-switch/build/ocaml-lsp-server.1.15.1-4.14/ocaml-lsp-server/src/m", line 410, characters 17-54
        # | Called from Fiber__Scheduler.exec in file "_dn/fiber/src/fiber/scheduler.ml", line 73, characters 8-11
        # \-----------------------------------------------------------------------
        cmake_path(GET BUILD_CMAKE_DUNE PARENT_PATH duneBinDir)
        list(APPEND cmdPrefix ${CMAKE_COMMAND} -E env --modify "PATH=path_list_prepend:${duneBinDir}")

        # It needs to know where ocamlformat is ...
        # | [Error - 8:45:40 AM] Request textDocument/formatting failed.
        # |   Message: Unable to find ocamlformat binary. You need to install ocamlformat manually to use the formatting feature.
        # |  Code: -32600
        find_program(OCAMLFORMAT_EXE NAMES ocamlformat HINTS ${hints})
        cmake_path(GET OCAMLFORMAT_EXE PARENT_PATH ocamlformatBinDir)
        list(APPEND cmdPrefix ${CMAKE_COMMAND} -E env --modify "PATH=path_list_prepend:${ocamlformatBinDir}")
    endif()

    if(EXISTS "${PROG_EXE}.cmd")
        # Windows batch scripts need to go through CMD.EXE /C
        set(newCmdline ${ARG_CMD})
        list(REMOVE_AT newCmdline 0)
        list(PREPEND newCmdline "CMD.EXE" "/C" "${PROG_EXE}")
    else()
        # Normal executables should just get the absolute path to
        # what was found, but otherwise the arguments are the same.
        set(newCmdline ${ARG_CMD})
        list(REMOVE_AT newCmdline 0)
        list(PREPEND newCmdline "${PROG_EXE}")
    endif()

    if(PROG_EXE)
        execute_process(
            COMMAND
            ${cmdPrefix} ${newCmdline}
            ENCODING UTF-8
            ${execute_process_args}
            COMMAND_ERROR_IS_FATAL ANY
        )
    else()
        message(FATAL_ERROR "${prog} (${ARG_CMD}) not found with hints: ${hints}")
    endif()

endfunction()
