##########################################################################
# File: dktool\cmake\scripts\dksdk\coder\compile.cmake                   #
#                                                                        #
# Copyright 2024 Diskuv, Inc.                                            #
#                                                                        #
# Licensed under the Open Software License version 3.0                   #
# (the "License"); you may not use this file except in compliance        #
# with the License. You may obtain a copy of the License at              #
#                                                                        #
#     https://opensource.org/license/osl-3-0-php/                        #
#                                                                        #
##########################################################################

set(DKCODER_COMPILE_VERSION 0.1.0-1)
# The SHA256 checksums for ${DKCODER_COMPILE_VERSION} are all available from
# https://gitlab.com/diskuv/distributions/1.0/dksdk-coder/-/packages/21844308 (select
# the right version of course)
set(DKCODER_SHA256_windows_x86_64 3a3d1deecb4368d9b513313c7e91561b38f2f527a145f1654a9433a5e624ea65)
set(DKCODER_SHA256_windows_x86    b20d37aadbeca8848d2ba95209c49d9b75e4cd29a44670a7eb795eae90699bd8)
set(DKCODER_SHA256_linux_x86_64   0e34fe0935e67dd81fe0b00e320e81bfc7aa1e175270152a4eab85c5fe07b177)
set(DKCODER_SHA256_linux_x86      8b2f690e6de4a1f26c654df41d62be4d33d0363281c5fbfee6fd983fc8138649)
set(DKCODER_SHA256_darwin_x86_64  todo_darwin_x86_64)
set(DKCODER_SHA256_darwin_arm64   todo_darwin_arm64)

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()

    cmake_path(APPEND DKSDK_DATA_HOME coder h OUTPUT_VARIABLE DKCODER_HOME)
    cmake_path(NATIVE_PATH DKCODER_HOME DKCODER_HOME_NATIVE)

    message(${ARG_MODE} "usage: ./dk dksdk.coder.compile

Compiles Coder expressions describing an application into a
compiled CDI (Coder instruction language) file.

The `dkcoder` environment, if not already installed, will be
downloaded and installed automatically.

Examples
========

  ./dk dksdk.coder.compile EXPRESSION Expression.ml
    Creates `Expression.cdi` in the same directory as `Expression.ml`.

  ./dk dksdk.coder.compile EXPRESSION Expression.ml OUTPUT ../compiled.cdi
    Creates `../compiled.cdi`.

  ./dk dksdk.coder.compile EXPRESSION Expression.ml MODULES Extra.ml
    Creates `Expression.cdi` where `Expression.ml` may use the module
    named `Extra` defined by the contents of the file `Extra.ml`.

File Naming
===========

Any `.ml` files must be specified with their first letter capitalized.
On case-sensitive filesystems (Linux, modern NTFS drives on Windows, but
not macOS and older FAT/FAT32 Windows drives) that means the `.ml`
files must be capitalized.

So name and refer to your files as `Expression.ml` (etc.) not
`expression.ml` (etc.).

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

EXPRESSION filename
  The path of the file containing Coder expressions. The path may
  start with a tilde (~) which will be treated as the home
  directory on Unix or the USERPROFILE directory on Windows.

  The file MUST contain the `module E` and the `blocks` field at
  minimum:

    open DkSDKCoder_Std
    module E (I : Cdinst.Lang.SYM) = struct
        let blocks = []
    end

  That absolute minimum will not generate any source code. A more
  realistic minimum is the following:

    open DkSDKCoder_Std
    module E (I : Cdinst.Lang.SYM) = struct
      open I
      let blocks = [
        block
          (label ~project:\"p\" ~deployment:\"d\" \"somename\" [])
          [declare (typeregister \"Hi\") unit]
          noop
      ]
    end

MODULES module_filenames
  Optional list of module filenames that can be used by the EXPRESSION.

OUTPUT filename
  The name of the output CDI file. The path may
  start with a tilde (~) which will be treated as the home
  directory on Unix or the USERPROFILE directory on Windows.

NO_SYSTEM_PATH
  Do not check for an OCaml runtime environment with `dkcoder` in well-known
  locations and in the PATH. Instead, install the `dkcoder` environment if no
  environment exists at `${DKCODER_HOME_NATIVE}`.

VERSION version
  Use the version specified rather than the built-in ${DKCODER_COMPILE_VERSION}
  dkcoder version.

  CAUTION: Using this option causes the SHA-256 integrity checks to be skipped.

  CAUTION: If the version is a branch rather than a specific version number,
  there is no way for `dksdk.coder.compile` to know about branch updates. The
  branch version will never be updated once downloaded initially. You will need
  to delete the branch at `${DKCODER_HOME_NATIVE}` manually to overcome this
  limitation.

POLL seconds
  Watch the file system for changes to the EXPRESSION file and the MODULES files
  (if any) by waking up every `seconds` seconds. `seconds` may be a floating
  point number like `0.5`.

WATCH
  (EXPERIMENTAL)
  Watch the file system for changes to the EXPRESSION file and the MODULES files
  (if any). Whenever there is a change recreate the OUTPUT file. You will need
  to press Ctrl-C to exit the watch mode.

  This mode only works on filesystems with support for symlinks. Linux and macOS
  will have no problems, but early Windows 10 machines or Windows FAT/FAT32
  drives will not detect the file changes in watch mode.

  ERRATA: This command may never work since Dune (the underlying build tool) only
  watches within the project directory and does not travel through symlinks (at
  least on Windows).

  ERRATA: Ctrl-C should abort the watch mode but due to a bug with CMake (at
  least on Windows 3.25.3) it may not work. Instead use `taskkill /F /IM dune.exe`
  on Windows or `pkill -f dune.exe` on Unix. Confer with
  https://stackoverflow.com/questions/75071180/pass-ctrlc-to-cmake-custom-command-under-vscode

Optimizations
=============

1. The first time you run `dksdk.coder.compile` will download and install DkSDK
   Coder cached on the [VERSION]. Subsequent times will not redownload nor
   reinstall DkSDK Coder unless the [VERSION] is different.
2. A compilation directory will be created and cached based on the absolute
   path to the [EXPRESSION filename] and any [MODULES filenames]. That means first time
   compilations for a EXPRESSION and MODULES may take a few seconds, but subsequent
   compiles should be quick (assuming the EXPRESSION and MODULES are not terribly
   complicated).
")
endfunction()

function(dkcoder_compile)
    set(noValues WATCH)
    set(singleValues EXPRESSION_PATH OUTPUT_PATH POLL)
    set(multiValues EXTRA_MODULE_PATHS)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # Make absolute path to EXPRESSION_PATH, including expanding tilde (~)
    file(REAL_PATH "${ARG_EXPRESSION_PATH}" expression_abspath EXPAND_TILDE)
    dkcoder_get_validated_module_name(${expression_abspath})

    # Make absolute path to OUTPUT_PATH, including expanding tilde (~)
    file(REAL_PATH "${ARG_OUTPUT_PATH}" output_abspath EXPAND_TILDE)

    # EXPRESSION and EXECUTABLE_NAME is for dune.tmpl and to name a generated file below
    set(EXPRESSION "${MODULE_NAME}")
    set(main_module "${EXPRESSION}Main")
    set(EXECUTABLE_NAME "${main_module}")

    # Convert EXTRA_MODULE_PATHS to absolute paths
    set(all_modules "${EXPRESSION}" "${main_module}")
    set(extra_module_paths)
    foreach(extra_module_path IN LISTS ARG_EXTRA_MODULE_PATHS)
        file(REAL_PATH "${extra_module_path}" m_abspath EXPAND_TILDE)
        dkcoder_get_validated_module_name(${m_abspath})
        list(APPEND all_modules "${MODULE_NAME}")
        list(APPEND extra_module_paths "${m_abspath}")
    endforeach()

    # MODULES is for dune.tmpl
    list(JOIN all_modules " " MODULES)

    # Read the footer
    file(READ "${DKCODER_ETC}/Main.ml.tmpl" FOOTER_CONTENTS)

    # Hash (which normalizes first) to make a compilation identifier
    cmake_path(HASH expression_abspath pathhash)
    set(compile_id_inputs ${pathhash})
    foreach(extra_module_path IN LISTS extra_module_paths)
        cmake_path(HASH extra_module_path pathhash)
        list(APPEND compile_id_inputs ${pathhash})
    endforeach()
    string(SHA256 COMPILE_ID "${compile_id_inputs}")
    string(SUBSTRING "${COMPILE_ID}" 0 8 COMPILE_ID)

    # Compile directory
    cmake_path(APPEND DKSDK_DATA_HOME coder c ${COMPILE_ID} OUTPUT_VARIABLE compile_dir)
    file(MAKE_DIRECTORY "${compile_dir}")

    # Place template files into compile directory
    file(COPY_FILE "${DKCODER_ETC}/dune-project.tmpl" "${compile_dir}/dune-project" ONLY_IF_DIFFERENT)
    #   Uses @EXECUTABLE_NAME@ and @MODULES@
    configure_file("${DKCODER_ETC}/dune.tmpl" "${compile_dir}/dune" @ONLY)
    #   Uses @EXPRESSION@
    configure_file("${DKCODER_ETC}/Main.ml.tmpl" "${compile_dir}/${main_module}.ml" @ONLY)
    #   The expression file itself.
    file(CREATE_LINK "${expression_abspath}" "${compile_dir}/${EXPRESSION}.ml" COPY_ON_ERROR SYMBOLIC)
    #   And extra modules
    foreach(extra_module_path IN LISTS extra_module_paths)
        cmake_path(GET extra_module_path FILENAME m_filename)
        file(CREATE_LINK "${extra_module_path}" "${compile_dir}/${m_filename}" COPY_ON_ERROR SYMBOLIC)
    endforeach()

    # Make a findlib.conf
    set(FINDLIB_PATH "${DKCODER_LIB}")
    set(FINDLIB_DESTDIR "${DKCODER_LIB}")
    if(CMAKE_HOST_WIN32)
        cmake_path(NATIVE_PATH FINDLIB_PATH FINDLIB_PATH)
        cmake_path(NATIVE_PATH FINDLIB_DESTDIR FINDLIB_DESTDIR)
        # Escape backslashes
        string(REPLACE "\\" "\\\\" FINDLIB_PATH "${FINDLIB_PATH}")
        string(REPLACE "\\" "\\\\" FINDLIB_DESTDIR "${FINDLIB_DESTDIR}")
    endif()
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../__dk-tmpl/coder-findlib.conf" "${compile_dir}/findlib.conf" @ONLY)

    # Now we are ready to make the output directory
    cmake_path(GET output_abspath PARENT_PATH output_dir)
    file(MAKE_DIRECTORY "${output_dir}")

    # Execute the `@gen-cdi` rule
    set(build_args)
    set(execute_args COMMAND_ERROR_IS_FATAL ANY)
    set(should_poll OFF)
    set(sticky_error OFF)
    if(ARG_WATCH)
        set(build_args "--watch")
    elseif(ARG_POLL)
        set(should_poll ON)
        set(execute_args RESULT_VARIABLE gen_cdi_error)
    endif()
    while(1)
        # Should we execute? Not if the output .cdi is newer than the input files.
        # We'll always run though if we are not polling.
        # However, if we are in sticky error mode we don't want any execution
        # unless there is a change to the input files.
        if(should_poll OR sticky_error)
            set(should_execute OFF)
            if(sticky_error)
                set(wait_until_change_after "${compile_dir}/error.tstamp")
            else()
                set(wait_until_change_after "${output_abspath}")
            endif()
            if (NOT EXISTS ${wait_until_change_after})
                set(should_execute ON)
            elseif(${expression_abspath} IS_NEWER_THAN ${wait_until_change_after})
                set(should_execute ON)
            else()
                foreach(extra_module_path IN LISTS extra_module_paths)
                    if(${extra_module_path} IS_NEWER_THAN ${wait_until_change_after})
                        set(should_execute ON)
                        break()
                    endif()                    
                endforeach()
            endif()
        else()
            set(should_execute ON)
        endif()

        if(should_execute)
            execute_process(
                COMMAND

                # Environment variables tested at dksdk-coder/ci/test-std-helper-dunebuild.sh.
                # Since we have a rule that does [ocamlrun], which depends on
                # compiling a bytecode executable, we have to do union of environments for
                # both ocamlc + ocamlrun.
                "${CMAKE_COMMAND}" -E env
                "OCAMLLIB=${DKCODER_LIB}/ocaml"
                "OCAMLFIND_CONF=${compile_dir}/findlib.conf"
                #"CAML_LD_LIBRARY_PATH=${DKCODER_LIB}/ocaml/stublibs;${DKCODER_LIB}/stublibs"
                "CDI_OUTPUT=${output_abspath}" # This environment variable is communication to `@gen-cdi` rule
                #   Unclear why CAML_LD_LIBRARY_PATH is needed by Dune 3.12.1 when invoking [ocamlc] on Windows to get
                #   dllunix.dll (etc.), but it is. That is fine; we can do both PATH and CAML_LD_LIBRARY_PATH.
                --modify "CAML_LD_LIBRARY_PATH=path_list_prepend:${DKCODER_LIB}/stublibs"
                --modify "CAML_LD_LIBRARY_PATH=path_list_prepend:${DKCODER_LIB}/ocaml/stublibs"
                --modify "PATH=path_list_prepend:${DKCODER_LIB}/stublibs"
                --modify "PATH=path_list_prepend:${DKCODER_LIB}/ocaml/stublibs"
                --modify "PATH=path_list_prepend:${DKCODER_BIN}"
                --

                "${DKCODER_DUNE}" build
                --root "${compile_dir}"
                --display=short
                --no-buffer
                --no-print-directory
                --no-config
                ${build_args}
                "@gen-cdi"                

                ${execute_args}
            )
            if(gen_cdi_error)
                set(sticky_error ON)
                file(TOUCH "${compile_dir}/error.tstamp")
            else()
                set(sticky_error OFF)
                file(REMOVE "${compile_dir}/error.tstamp")
            endif()
        endif()

        # Any polling?
        if(NOT should_poll)
            break()
        endif()

        # Yes, so wait before trying again.
        execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep ${ARG_POLL} COMMAND_ERROR_IS_FATAL ANY)
    endwhile()
endfunction()

# Outputs:
# - DKCODER - location of dkcoder executable
# - DKCODER_BIN - location of bin directory
# - DKCODER_ETC - location of etc/dkcoder directory
# - DKCODER_LIB - location of lib/ directory containing lib/ocaml/ and other libraries compatible with dkcoder
# - DKCODER_OCAMLC - location of ocamlc compatible with dkcoder
# - DKCODER_OCAMLRUN - location of ocamlrun compatible with dkcoder
# - DKCODER_DUNE - location of dune compatible with dkcoder
function(dkcoder_install)
    set(noValues NO_SYSTEM_PATH ENFORCE_SHA256)
    set(singleValues VERSION)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # Make a DkSDK Coder home
    cmake_path(APPEND DKSDK_DATA_HOME coder h ${ARG_VERSION} OUTPUT_VARIABLE DKCODER_HOME)

    set(hints ${DKCODER_HOME}/bin)
    set(find_program_INITIAL)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND find_program_INITIAL NO_DEFAULT_PATH)
    endif()
    find_program(DKCODER NAMES dkcoder HINTS ${hints} ${find_program_INITIAL})

    if(NOT DKCODER)
        # Download into ${DKCODER_HOME} (which is one of the HINTS)
        set(downloaded)
        set(url_base "https://gitlab.com/api/v4/projects/52918795/packages/generic/stdexport/${ARG_VERSION}")
        if(CMAKE_HOST_WIN32)
            # On Windows CMAKE_HOST_SYSTEM_PROCESSOR = ENV:PROCESSOR_ARCHITECTURE
            # Values: AMD64, IA64, ARM64, x86
            # https://docs.microsoft.com/en-us/windows/win32/winprog64/wow64-implementation-details?redirectedfrom=MSDN#environment-variables
            set(out_exp .zip)
            if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL x86 OR CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL X86)
                set(dkml_host_abi windows_x86)
            else()
                set(dkml_host_abi windows_x86_64)
            endif()
        elseif(CMAKE_HOST_APPLE)
            set(out_exp .tar.gz)
            execute_process(COMMAND uname -m
                    OUTPUT_VARIABLE host_machine_type
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    COMMAND_ERROR_IS_FATAL ANY)
            if(host_machine_type STREQUAL x86_64)
                set(dkml_host_abi darwin_x86_64)
            elseif(host_machine_type STREQUAL arm64)
                set(dkml_host_abi darwin_arm64)
            else()
                message(FATAL_ERROR "Your macOS ${host_machine_type} platform is currently not supported by this download script")
            endif()
        elseif(CMAKE_HOST_LINUX)
        set(out_exp .tar.gz)
        execute_process(COMMAND uname -m
                    OUTPUT_VARIABLE host_machine_type
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    COMMAND_ERROR_IS_FATAL ANY)
            if(host_machine_type STREQUAL x86_64)
                set(dkml_host_abi linux_x86_64)
            elseif(host_machine_type STREQUAL i686)
                set(dkml_host_abi linux_x86)
            else()
                message(FATAL_ERROR "Your Linux ${host_machine_type} platform is currently not supported by this download script")
            endif()
        else()
            message(FATAL_ERROR "DkSDK Coder is only available on Windows, macOS and Linux")
        endif()

        # Download
        set(expand_EXPECTED_HASH)
        if(ARG_ENFORCE_SHA256)
            set(expand_EXPECTED_HASH EXPECTED_HASH SHA256=DKCODER_SHA256_${dkml_host_abi})
        endif()
        set(url "${url_base}/stdexport-${dkml_host_abi}${out_exp}")
        message(${loglevel} "Downloading DkSDK Coder from ${url}")
        file(DOWNLOAD ${url} ${CMAKE_CURRENT_BINARY_DIR}/stdexport${out_exp} ${expand_EXPECTED_HASH})
        message(${loglevel} "Extracting DkSDK Coder")
        file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/stdexport${out_exp} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/_e)
        file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/stdexport${out_exp})

        # Install
        #   Do file(RENAME) but work across mount volumes (ex. inside containers)
        file(REMOVE_RECURSE "${DKCODER_HOME}")
        file(MAKE_DIRECTORY "${DKCODER_HOME}")
        file(GLOB entries
            LIST_DIRECTORIES true
            RELATIVE ${CMAKE_CURRENT_BINARY_DIR}/_e
            ${CMAKE_CURRENT_BINARY_DIR}/_e/*)
        foreach(entry IN LISTS entries)
            file(COPY ${CMAKE_CURRENT_BINARY_DIR}/_e/${entry}
                DESTINATION ${DKCODER_HOME}
                FOLLOW_SYMLINK_CHAIN
                USE_SOURCE_PERMISSIONS)
        endforeach()
        file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/_e")

        find_program(DKCODER NAMES dkcoder REQUIRED HINTS ${hints})
    endif()

    cmake_path(GET DKCODER PARENT_PATH dkcoder_bindir)
    cmake_path(GET dkcoder_bindir PARENT_PATH dkcoder_rootdir)

    # ocamlc, ocamlrun and dune must be in the same directory as dkcoder.
    find_program(DKCODER_OCAMLC NAMES ocamlc REQUIRED NO_DEFAULT_PATH HINTS ${dkcoder_bindir})
    find_program(DKCODER_OCAMLRUN NAMES ocamlrun REQUIRED NO_DEFAULT_PATH HINTS ${dkcoder_bindir})
    find_program(DKCODER_DUNE NAMES dune REQUIRED NO_DEFAULT_PATH HINTS ${dkcoder_bindir})

    # bin
    cmake_path(APPEND dkcoder_rootdir bin OUTPUT_VARIABLE dkcoder_bin)
    if(NOT IS_DIRECTORY "${dkcoder_bin}")
        message(FATAL_ERROR "Expected ${dkcoder_bin} to be present")
    endif()
    set(DKCODER_BIN "${dkcoder_bin}" PARENT_SCOPE)

    # etc/dkcoder
    cmake_path(APPEND dkcoder_rootdir etc dkcoder OUTPUT_VARIABLE dkcoder_etc)
    if(NOT IS_DIRECTORY "${dkcoder_etc}")
        message(FATAL_ERROR "Expected ${dkcoder_etc} to be present")
    endif()
    set(DKCODER_ETC "${dkcoder_etc}" PARENT_SCOPE)

    # lib
    cmake_path(APPEND dkcoder_rootdir lib OUTPUT_VARIABLE dkcoder_lib)
    if(NOT IS_DIRECTORY "${dkcoder_lib}")
        message(FATAL_ERROR "Expected ${dkcoder_lib} to be present")
    endif()
    set(DKCODER_LIB "${dkcoder_lib}" PARENT_SCOPE)
endfunction()

# Output - MODULE_NAME
function(dkcoder_get_validated_module_name path)
    if(path STREQUAL "")
        message(FATAL_ERROR "The path to the module is required.")
    endif()
    cmake_path(GET path FILENAME name)
    string(TOUPPER "${name}" name_upper)
    string(SUBSTRING "${name}" 0 1 first_char)
    string(SUBSTRING "${name_upper}" 0 1 first_char_upper)
    if(NOT first_char STREQUAL first_char_upper)
        message(FATAL_ERROR "The name of a module must start with a capital letter. Instead '${name}' was used.")
    endif()
    cmake_path(REMOVE_EXTENSION name OUTPUT_VARIABLE module_name)
    set(MODULE_NAME "${module_name}" PARENT_SCOPE)
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION}")

    set(noValues HELP QUIET NO_SYSTEM_PATH WATCH)
    set(singleValues VERSION EXPRESSION OUTPUT POLL)
    set(multiValues MODULES)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

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

    # WATCH
    set(expand_WATCH)
    if(ARG_WATCH)
        list(APPEND expand_WATCH WATCH)
    endif()

    # POLL
    set(expand_POLL)
    if(ARG_POLL)
        list(APPEND expand_POLL POLL ${ARG_POLL})
    endif()

    # VERSION
    if(ARG_VERSION)
        set(VERSION ${ARG_VERSION})
        set(expand_ENFORCE_SHA256)
    else()
        set(VERSION ${DKCODER_COMPILE_VERSION})
        set(expand_ENFORCE_SHA256 ENFORCE_SHA256)
    endif()

    # EXPRESSION
    if(NOT ARG_EXPRESSION)
        help(MODE NOTICE)
        message(NOTICE "Missing EXPRESSION argument")
        return()
    endif()

    # OUTPUT
    if(ARG_OUTPUT)
        set(OUTPUT ${ARG_OUTPUT})
    else()
        cmake_path(REPLACE_EXTENSION ARG_EXPRESSION LAST_ONLY .cdi OUTPUT_VARIABLE OUTPUT)
    endif()

    dkcoder_install(VERSION ${VERSION} ${expand_NO_SYSTEM_PATH} ${expand_ENFORCE_SHA256})
    dkcoder_compile(EXPRESSION_PATH ${ARG_EXPRESSION} EXTRA_MODULE_PATHS ${ARG_MODULES} OUTPUT_PATH ${OUTPUT}
        ${expand_WATCH} ${expand_POLL})
endfunction()
