##########################################################################
# File: dktool/cmake/scripts/dkml/workflow/compilers.cmake               #
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
    message(${ARG_MODE} [[usage: ./dk dkml.workflow.compilers

Downloads DkML compiler setup scripts in .ci/dkml-compilers/.

Typically used within a CI provider like GitHub Actions or GitLab
CI, but can also be run from your desktop.

Once the setup scripts are available, you will need to execute
those setup scripts inside your CI provider (or on your desktop).
That documentation is available at:

  https://github.com/diskuv/dkml-workflows#readme

Directory Structure
===================

.ci/dkml-compilers
├── gh-darwin
│   ├── post
│   │   └── action.yml
│   └── pre
│       └── action.yml
├── gh-linux
│   ├── post
│   │   └── action.yml
│   └── pre
│       └── action.yml
├── gh-windows
│   ├── post
│   │   └── action.yml
│   └── pre
│       └── action.yml
├── gl
│   └── setup-dkml.gitlab-ci.yml
└── pc
    ├── setup-dkml-darwin_x86_64.sh
    ├── setup-dkml-linux_x86_64.sh
    ├── setup-dkml-linux_x86.sh
    ├── setup-dkml-windows_x86_64.ps1
    └── setup-dkml-windows_x86.ps1

Arguments
=========

HELP
  Print this help message.

OS [Windows] [Linux] [Darwin]
  Download only the compiler setup scripts for the matching list of
  operating systems. By default all operating systems are downloaded.

CI [GitHub] [GitLab] [Desktop]
  Download only the compiler setup scripts for the matching list of
  CI environments. By default all CI environments are downloaded.

PRERELEASE
  Use the bleeding edge DkML compilers.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION})

    set(noValues PRERELEASE)
    set(singleValues HELP)
    set(multiValues OS CI)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    # Which git repository
    set(git_repository https://github.com/diskuv/dkml-workflows.git)
    if(ARG_PRERELEASE)
      set(git_repository https://github.com/diskuv/dkml-workflows-prerelease.git)
    endif()

    # Which CI environments?
    set(source_dirs)
    set(source_dirs_ignored)
    set(file_FILTERS)
    if(ARG_CI)
      set(gh_source_dirs_VARNAME source_dirs_ignored)
      foreach(ci IN LISTS ARG_CI)
        if(ci STREQUAL GitHub)
          set(gh_source_dirs_VARNAME source_dirs)
        elseif(ci STREQUAL GitLab)
          list(APPEND source_dirs gl)
        elseif(ci STREQUAL Desktop)
          list(APPEND source_dirs pc)
        else()
          help(MODE NOTICE)
          message(FATAL_ERROR "The CI arguments must be one or more of: GitHub, GitLab and Desktop")
        endif()
      endforeach()
    else()
      list(APPEND source_dirs pc gl)
      set(gh_source_dirs_VARNAME source_dirs)
    endif()

    # Which operating systems?
    if(ARG_OS)
      foreach(os IN LISTS ARG_OS)
        if(os STREQUAL Windows)
          list(APPEND ${gh_source_dirs_VARNAME} gh-windows)
          list(APPEND file_FILTERS PATTERN "*-windows*")
        elseif(os STREQUAL Linux)
          list(APPEND ${gh_source_dirs_VARNAME} gh-linux)
          list(APPEND file_FILTERS PATTERN "*-linux*")
        elseif(os STREQUAL Darwin)
          list(APPEND ${gh_source_dirs_VARNAME} gh-darwin)
          list(APPEND file_FILTERS PATTERN "*-darwin*")
        else()
          help(MODE NOTICE)
          message(FATAL_ERROR "The OS arguments must be one or more of: Windows, Linux and Darwin")
        endif()
      endforeach()
    else()
      list(APPEND file_FILTERS
        PATTERN "*.ps1"
        PATTERN "*.sh"
        PATTERN "*.yml")
      list(APPEND ${gh_source_dirs_VARNAME} gh-windows gh-linux gh-darwin)
    endif()

    # Download the full project
    FetchContent_Populate(dkml-workflows
        QUIET
        GIT_REPOSITORY ${git_repository}
        GIT_TAG v1
    )

    # Only populate in .ci/dkml-compilers/ what was asked for
    list(TRANSFORM source_dirs PREPEND "${dkml-workflows_SOURCE_DIR}/test/")
    file(INSTALL ${source_dirs}
      DESTINATION ${CMAKE_SOURCE_DIR}/.ci/dkml-compilers
      FILES_MATCHING
      PATTERN action.yml
      PATTERN setup-dkml.gitlab-ci.yml
      ${file_FILTERS}
    )
endfunction()
