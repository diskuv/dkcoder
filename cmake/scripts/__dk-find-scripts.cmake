##########################################################################
# File: dktool/cmake/scripts/__dk-find-scripts.cmake                     #
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

# Recommendation: Place this file in source control.
# Auto-generated by `./dk dksdk.project.new` of dktool.

include(FetchContent)

function(parse_dktool_command_line)
    # The first argument is <command>. All dots will be replaced with a
    # triple underscore as a convenience and to be pretty for the user.
    # However, we do not error if no <command> is given ... we'll do
    # that later.
    set(command)
    set(expected_function_name)
    set(quotedArgs "")
    if(ARGC EQUAL 0 OR (ARGC EQUAL 1 AND ARGV0 STREQUAL HELP))
        message(NOTICE [[Usage:
  ./dk <command> HELP
  ./dk <command> [args]
]])
    else()
        set(command ${ARGV0})
        string(REPLACE "." "___" expected_function_name ${command})
        message(VERBOSE "Searching for ${expected_function_name}")

        # Parse the remainder of the arguments [args]
        # * Use technique from [Professional CMake: A Practical Guide - Forwarding Command Arguments]
        #   to be able to forward arguments correctly to an inner function (the <command> function).
        cmake_parse_arguments(PARSE_ARGV 1 FWD "" "" "")
        foreach(arg IN LISTS FWD_UNPARSED_ARGUMENTS)
            string(APPEND quotedArgs " [===[${arg}]===]")
        endforeach()
    endif()

    # Set policies (we are in a new EVAL CODE context)
    #   Included scripts do automatic cmake_policy PUSH and POP
    if(POLICY CMP0011)
        cmake_policy(SET CMP0011 NEW)
    endif()
    #   Allow GIT_SUBMODULES empty to mean no submodules
    if(POLICY CMP0097)
        cmake_policy(SET CMP0097 NEW)
    endif()

    # Setup the binary directory
    if(NOT DKTOOL_WORKDIR)
        message(FATAL_ERROR "Illegal state. Expecting DKTOOL_WORKDIR")
    endif()
    set(CMAKE_BINARY_DIR "${DKTOOL_WORKDIR}")
    set(CMAKE_CURRENT_BINARY_DIR "${CMAKE_BINARY_DIR}")

    # Search in all the user scripts
    set(dot_function_names)
    file(GLOB_RECURSE command_files
            LIST_DIRECTORIES FALSE
            RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/scripts
            cmake/scripts/*.cmake)
    foreach(command_file IN LISTS command_files)
        # Exclude files and directories that start with: __dk-
        if(command_file MATCHES "(^|/)__dk-")
            continue()
        endif()

        # Normalize and lowercase
        cmake_path(NORMAL_PATH command_file)
        string(TOLOWER "${command_file}" command_file)
        cmake_path(REMOVE_EXTENSION command_file OUTPUT_VARIABLE command_file_no_ext)

        # Convert to list
        string(REPLACE "/" ";" command_stems_no_namespace ${command_file_no_ext})

        # Make a pretty description only for validation
        set(pretty_stems ${command_stems_no_namespace})
        list(TRANSFORM pretty_stems PREPEND "'")
        list(TRANSFORM pretty_stems APPEND "'")
        string(JOIN ", " pretty_stems_str ${pretty_stems})
        string(REGEX REPLACE ",([^,]*)" " and \\1" pretty_stems_str "${pretty_stems_str}")

        # Validate that only alphanumeric with underscores (but not the reserved three underscores)
        string(REGEX MATCH "[/a-z0-9_]*" only_alphanum_and_underscores "${command_file_no_ext}")
        if(NOT only_alphanum_and_underscores STREQUAL "${command_file_no_ext}")
            message(WARNING "Ignoring user script ${CMAKE_CURRENT_SOURCE_DIR}/${command_file}.
The stems of the user script (${pretty_stems_str}) must only contain letters, numbers and underscores.")
            continue()
        endif()
        string(FIND "${command_file_no_ext}" "___" reserved_underscores)
        if(reserved_underscores GREATER_EQUAL 0)
            message(WARNING "Ignoring user script ${CMAKE_CURRENT_SOURCE_DIR}/${command_file}.
No stem of the user script (${pretty_stems_str}) can contain a triple underscore ('___').")
            continue()
        endif()

        # Translate dev/xxx.cmake to the "user" namespaced function name
        # `user__dev__xxx` and `user.dev.xxx`.
        set(command_stems ${command_stems_no_namespace})
        list(PREPEND command_stems "user")
        string(JOIN "___" command_function_name ${command_stems})
        string(JOIN "." dot_function_name ${command_stems})
        list(APPEND dot_function_names ${dot_function_name})

        # In a new scope (to avoid a global, leaky namespace) register the function.
        message(VERBOSE "Shimming ${command_function_name}")
        cmake_language(EVAL CODE "
function(${command_function_name})
    include(\"${CMAKE_CURRENT_SOURCE_DIR}/cmake/scripts/${command_file}\")
    if(COMMAND run)
        run(${quotedArgs})
    else()
        message(FATAL_ERROR [[The user script ${CMAKE_CURRENT_SOURCE_DIR}/cmake/scripts/${command_file} was missing:
  function(run)
    # Your user code
  endfunction()
]])
    endif()
endfunction()
")
    endforeach()

    # Include all the system scripts.
    # - Since the system scripts come after the user scripts, the user scripts
    #   don't override the system scripts unless the user scripts use deferred
    #   hooks or redefine CMake built-in functions. Regardless, the user
    #   scripts are namespaced with `user__` prefix
    if(NOT IS_DIRECTORY cmake/scripts/dksdk)
        # If this project (ex. dktool) has the system scripts, it must
        # have all of them. Otherwise we download the system scripts.
        # But we don't want to download every time we run the script.
        #
        #   The default, but explicit so we know where it is.
        set(dktool_subbuild_dir "${CMAKE_CURRENT_BINARY_DIR}/dktool-subbuild")
        #   Also the default, but explicit since we don't always call FetchContent_Populate().
        set(dktool_src_dir "${CMAKE_CURRENT_BINARY_DIR}/dktool-src")
        #   Prior downloads are fine if done within the last one hour.
        set(ttl_MINUTES 60)
        if(DEFINED ENV{DKTOOL_TTL_MINUTES})
            set(ttl_MINUTES "$ENV{DKTOOL_TTL_MINUTES}")
        endif()
        string(TIMESTAMP now_EPOCHSECS "%s")
        math(EXPR min_valid_EPOCHSECS "${now_EPOCHSECS} - 60*${ttl_MINUTES}")
        set(tstamp_EPOCHSECS 0)
        if(EXISTS "${dktool_subbuild_dir}/build.ninja")
            file(TIMESTAMP "${dktool_subbuild_dir}/build.ninja" tstamp_EPOCHSECS "%s")
        endif()
        if(NOT tstamp_EPOCHSECS OR tstamp_EPOCHSECS LESS_EQUAL min_valid_EPOCHSECS)
            # Cache miss. Time to update dktool.
            FetchContent_Populate(dktool
                QUIET
                SOURCE_DIR "${dktool_src_dir}"
                SUBBUILD_DIR "${dktool_subbuild_dir}"
                GIT_REPOSITORY https://gitlab.com/diskuv/dktool.git
                GIT_TAG 1.0
                # As of 3.25.3 the bug https://gitlab.kitware.com/cmake/cmake/-/issues/24578
                # has still not been fixed. That means empty strings get removed.
                # ExternalProject_Add(GIT_SUBMODULES) in dktool-subbuild/CMakeLists.txt
                # means fetch all submodules.
                # https://gitlab.kitware.com/cmake/cmake/-/issues/20579#note_734045
                # has a workaround.
                GIT_SUBMODULES cmake # Non-git-submodule dir that already exists
                GIT_SUBMODULES_RECURSE OFF)
        endif()
        file(GLOB_RECURSE system_command_files
            LIST_DIRECTORIES FALSE
            RELATIVE ${dktool_src_dir}/cmake/scripts
            ${dktool_src_dir}/cmake/scripts/dkml/*.cmake
            ${dktool_src_dir}/cmake/scripts/dksdk/*.cmake)
        foreach(command_file IN LISTS system_command_files)
            # Normalize and lowercase
            cmake_path(NORMAL_PATH command_file)
            string(TOLOWER "${command_file}" command_file)
            cmake_path(REMOVE_EXTENSION command_file OUTPUT_VARIABLE command_file_no_ext)

            # Convert to list
            string(REPLACE "/" ";" command_stems_no_namespace ${command_file_no_ext})

            # Translate dksdk/xxx.cmake to the function name `dksdk__xxx` and `dksdk.xxx`
            set(command_stems ${command_stems_no_namespace})
            string(JOIN "___" command_function_name ${command_stems})
            string(JOIN "." dot_function_name ${command_stems})
            list(APPEND dot_function_names ${dot_function_name})

            # In a new scope (to avoid a global, leaky namespace) register the function.
            message(VERBOSE "Shimming ${command_function_name}")
            cmake_language(EVAL CODE "
function(${command_function_name})
    include(\"${dktool_src_dir}/cmake/scripts/${command_file}\")
    if(COMMAND run)
        run(${quotedArgs})
    else()
        message(FATAL_ERROR [[The system script ${dktool_src_dir}/cmake/scripts/${command_file} was missing:
  function(run)
    # The system code
  endfunction()
]])
    endif()
endfunction()
")

        endforeach()
    endif()

    # Pretty function names that are available
    set(pretty_function_names ${dot_function_names})
    list(TRANSFORM pretty_function_names PREPEND "  ")
    list(TRANSFORM pretty_function_names APPEND "\n")
    string(JOIN "" str_pretty_function_names ${pretty_function_names})

    # Exit if no <command>
    if(NOT command)
        message(NOTICE "The following commands are available:
${str_pretty_function_names}")
        return()
    endif()

    # Validate the <command> exists
    if(NOT COMMAND ${expected_function_name})
        message(FATAL_ERROR "No command '${command}' exists. The following commands are available:
${str_pretty_function_names}")
        message(FATAL_ERROR "No command '${command}' exists")
    endif()

    # Make space for <command>
    set(CMAKE_CURRENT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${expected_function_name}")
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

    # Call the <command> function
    cmake_language(EVAL CODE "${expected_function_name}()")
endfunction()

# DkSDK data home
if(WIN32)
    set(DKSDK_DATA_HOME "$ENV{LOCALAPPDATA}/Programs/DkSDK")
elseif(DEFINED ENV{XDG_DATA_HOME})
    set(DKSDK_DATA_HOME "$ENV{XDG_DATA_HOME}/dksdk")
else()
    set(DKSDK_DATA_HOME "$ENV{HOME}/.local/share/dksdk")
endif()
cmake_path(NORMAL_PATH DKSDK_DATA_HOME)

# Nonce script
if(CMAKE_HOST_WIN32)
    set(post_script_suffix .cmd)
else()
    set(post_script_suffix .sh)
endif()
cmake_path(APPEND DKTOOL_WORKDIR "${DKTOOL_NONCE}${post_script_suffix}" OUTPUT_VARIABLE DKTOOL_POST_SCRIPT)
cmake_path(NORMAL_PATH DKTOOL_POST_SCRIPT)

# Escape any escape characters before EVAL CODE
string(REPLACE "\\" "\\\\" DKTOOL_CMDLINE "${DKTOOL_CMDLINE}")

# Splat DKTOOL_CMDLINE
cmake_language(EVAL CODE "parse_dktool_command_line(${DKTOOL_CMDLINE})")
