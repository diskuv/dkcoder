##########################################################################
# File: dktool/cmake/scripts/dkml/wrapper/upgrade.cmake                  #
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
    message(${ARG_MODE} [[usage: ./dk dkml.wrapper.upgrade

Upgrade ./dk, ./dk.cmd and cmake/scripts/__dk-find-scripts.cmake.

If there is a .git/ directory and no .gitattributes then a 
default .gitattributes configuration file is added.

And if there is a .git/ directory the .gitattributes, ./dk, ./dk.cmd
and cmake/scripts/__dk-find-scripts.cmake are added to Git.

Usage
=====

TLDR: Run the upgrade twice.

On Windows you may see an error when an upgrade includes an
update to ./dk.cmd. That is because Windows will:

1. Run a portion of the old ./dk.cmd
2. Save its position in ./dk.cmd
3. Do the upgrade of ./dk.cmd
4. "Continue" running the updated ./dk.cmd with the old (incorrect)
   position.

To avoid the problem, you should always upgrade once, then ignore any
error, and then run the upgrade again.

Arguments
=========

HELP
  Print this help message.

HERE
  Do the upgrade in the current directory rather than the
  directory that ./dk lives.
  This is useful as the first step in adding ./dk to a
  new project:
    git clone https://gitlab.com/diskuv/dktool.git
    dktool/dk user.dkml.wrapper.upgrade HERE

DONE
  Remove the dktool/ created by a prior invocation of:
    git clone https://gitlab.com/diskuv/dktool.git
  This is useful as the final step in adding ./dk to a
  new project.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;HERE;DONE" "" "")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    if(ARG_HERE AND ARG_DONE)
      help(MODE NOTICE)
      message(FATAL_ERROR "You cannot use both HERE and DONE arguments")
      return()
    endif()

    # <dktool>/cmake/scripts/dkml/wrapper/upgrade.cmake -> <dktool>
    cmake_path(GET CMAKE_CURRENT_FUNCTION_LIST_DIR PARENT_PATH d)
    cmake_path(GET d PARENT_PATH d)
    cmake_path(GET d PARENT_PATH d)
    cmake_path(GET d PARENT_PATH d)
    cmake_path(SET path_dk "dk")
    cmake_path(SET path_dkcmd "dk.cmd")
    cmake_path(SET path_gitattributes ".gitattributes")
    cmake_path(SET path_cmake "cmake")
    cmake_path(APPEND path_cmake "scripts" "__dk-find-scripts.cmake" OUTPUT_VARIABLE path_dkfindscriptscmake)
    cmake_path(APPEND d ${path_dk} OUTPUT_VARIABLE file_dk)
    cmake_path(APPEND d ${path_dkcmd} OUTPUT_VARIABLE file_dkcmd)
    cmake_path(APPEND d ${path_gitattributes} OUTPUT_VARIABLE file_gitattributes)
    cmake_path(APPEND d ${path_dkfindscriptscmake} OUTPUT_VARIABLE file_dkfindscriptscmake)

    # validate
    if(NOT EXISTS ${file_dk})
      message(FATAL_ERROR "Missing 'dk' at expected ${file_dk}")
    endif()
    if(NOT EXISTS ${file_dkcmd})
      message(FATAL_ERROR "Missing 'dk.cmd' at expected ${file_dkcmd}")
    endif()
    if(NOT EXISTS ${file_dkfindscriptscmake})
      message(FATAL_ERROR "Missing '__dk-find-scripts.cmake' at expected ${file_dkfindscriptscmake}")
    endif()

    # DONE?
    if(ARG_DONE)
      # we already checked that no [HERE] argument
      if(IS_DIRECTORY "${CMAKE_SOURCE_DIR}/dktool" AND IS_DIRECTORY "${CMAKE_SOURCE_DIR}/dktool/.git")
        file(REMOVE_RECURSE "${CMAKE_SOURCE_DIR}/dktool")
      endif()
      message(NOTICE [[

Congratulations. Let's get building!

  Announcements | https://twitter.com/diskuv
  DkML          | https://diskuv.com/dkmlbook/
  DkSDK         | https://diskuv.com/pricing/
  Second OCaml  | https://www.youtube.com/@diskuv/
]])
      return()
    endif()

    # destination
    set(dest "${CMAKE_SOURCE_DIR}")
    if(ARG_HERE)
      set(dest "${DKTOOL_PWD}")
    endif()

    # install
    file(INSTALL "${file_dkcmd}"
        DESTINATION "${dest}"
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
    file(INSTALL "${file_dkfindscriptscmake}"
        DESTINATION "${dest}/cmake/scripts"
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
    file(INSTALL "${file_dk}"
        DESTINATION "${dest}"
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    
    # Prompt next steps for HERE users
    if(ARG_HERE)
      set(invocation ./dk)
      if(WIN32)
        set(invocation [[.\dk]])
      endif()
      message(NOTICE "
The final installation step is to run:

  ${invocation} dkml.wrapper.upgrade DONE
")
    endif()

    # Do Git operations automatically
    if(IS_DIRECTORY "${dest}/.git")
      find_package(Git QUIET REQUIRED)

      # install .gitattributes
      file(INSTALL "${file_gitattributes}"
        DESTINATION "${dest}"
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

      # add the four files
      execute_process(WORKING_DIRECTORY "${dest}"
        COMMAND "${GIT_EXECUTABLE}" add "${path_dk}" "${path_dkcmd}" "${path_dkfindscriptscmake}" "${path_gitattributes}"
        COMMAND_ERROR_IS_FATAL ANY)

      # for Windows, the *_EXECUTE permissions earlier do nothing. And a subsequent `git add` will not set the
      # git chmod +x bit. So we force it.
      execute_process(WORKING_DIRECTORY "${dest}"
        COMMAND "${GIT_EXECUTABLE}" update-index --chmod=+x "${path_dk}"
        COMMAND_ERROR_IS_FATAL ANY)
    endif()
endfunction()
