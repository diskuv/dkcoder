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

.github
└── workflows
    └── dkml.yml (Not overwritten if exists)

.gitlab-ci.yml (Not overwritten if exists)

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

set(github_matrix_windows [[
          - gh_os: windows-2019
            abi_pattern: win32-windows_x86
            dkml_host_abi: windows_x86
          - gh_os: windows-2019
            abi_pattern: win32-windows_x86_64
            dkml_host_abi: windows_x86_64
]])
set(github_matrix_linux [[
          - gh_os: ubuntu-latest
            abi_pattern: manylinux2014-linux_x86
            dkml_host_abi: linux_x86
          - gh_os: ubuntu-latest
            abi_pattern: manylinux2014-linux_x86_64
            dkml_host_abi: linux_x86_64
]])
set(github_matrix_darwin [[
          - gh_os: macos-latest
            abi_pattern: macos-darwin_all
            dkml_host_abi: darwin_x86_64
]])
set(github_setup_windows [[
      - name: Setup DkML compilers on a Windows host
        if: startsWith(matrix.dkml_host_abi, 'windows_')
        uses: ./.ci/dkml-compilers/gh-windows/pre
        with:
          DKML_COMPILER: ${{ env.DKML_COMPILER }}
          CACHE_PREFIX: ${{ env.CACHE_PREFIX }}
]])
set(github_setup_linux [[
      - name: Setup DkML compilers on a Linux host
        if: startsWith(matrix.dkml_host_abi, 'linux_')
        uses: ./.ci/dkml-compilers/gh-linux/pre
        with:
          DKML_COMPILER: ${{ env.DKML_COMPILER }}
          CACHE_PREFIX: ${{ env.CACHE_PREFIX }}
]])
set(github_setup_darwin [[
      - name: Setup DkML compilers on a Darwin host
        if: startsWith(matrix.dkml_host_abi, 'darwin_')
        uses: ./.ci/dkml-compilers/gh-darwin/pre
        with:
          DKML_COMPILER: ${{ env.DKML_COMPILER }}
          CACHE_PREFIX: ${{ env.CACHE_PREFIX }}
]])

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION})

    set(noValues PRERELEASE HELP)
    set(singleValues)
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
    set(has_GitLab OFF)
    set(has_GitHub OFF)
    if(ARG_CI)
      set(gh_source_dirs_VARNAME source_dirs_ignored)
      foreach(ci IN LISTS ARG_CI)
        if(ci STREQUAL GitHub)
          set(gh_source_dirs_VARNAME source_dirs)
          set(has_GitHub ON)
        elseif(ci STREQUAL GitLab)
          list(APPEND source_dirs gl)
          set(has_GitLab ON)
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
      set(has_GitLab ON)
      set(has_GitHub ON)
    endif()

    # Which operating systems?
    set(github_matrix "\n")
    set(github_setup "\n")
    set(has_Windows OFF)
    if(ARG_OS)
      foreach(os IN LISTS ARG_OS)
        if(os STREQUAL Windows)
          list(APPEND ${gh_source_dirs_VARNAME} gh-windows)
          list(APPEND file_FILTERS PATTERN "*-windows*")
          string(APPEND github_matrix "${github_matrix_windows}")
          string(APPEND github_setup "${github_setup_windows}")
          set(has_Windows ON)
        elseif(os STREQUAL Linux)
          list(APPEND ${gh_source_dirs_VARNAME} gh-linux)
          list(APPEND file_FILTERS PATTERN "*-linux*")
          string(APPEND github_matrix "${github_matrix_linux}")
          string(APPEND github_setup "${github_setup_linux}")
        elseif(os STREQUAL Darwin)
          list(APPEND ${gh_source_dirs_VARNAME} gh-darwin)
          list(APPEND file_FILTERS PATTERN "*-darwin*")
          string(APPEND github_matrix "${github_matrix_darwin}")
          string(APPEND github_setup "${github_setup_darwin}")
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
      string(APPEND github_matrix "${github_matrix_windows}${github_matrix_linux}${github_matrix_darwin}")
      string(APPEND github_setup "${github_setup_windows}${github_setup_linux}${github_setup_darwin}")
      set(has_Windows ON)
    endif()

    # gitignore
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/dkml-compilers")
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/msys64")
    file(COPY_FILE # .ci/dkml-compilers gitignore is non-simple; it needs to be checked in
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../__dk-tmpl/dkml-compilers.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/dkml-compilers/.gitignore"
        ONLY_IF_DIFFERENT)
    file(COPY_FILE # msys64/ used on Windows. We want the .gitignore checked in
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../__dk-tmpl/all-except-gitignore.gitignore"
        "${CMAKE_SOURCE_DIR}/msys64/.gitignore"
        ONLY_IF_DIFFERENT)

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

    # CI provider scripts
    set(ARGV_PRETTY)
    list(JOIN ARGV " " ARGV_SPACE_SEPARATED)

    if(NOT EXISTS ${CMAKE_SOURCE_DIR}/ci/build-test.sh)
      configure_file(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/compilers-build-test.in.sh
        ${CMAKE_CURRENT_BINARY_DIR}/build-test.sh
        @ONLY)
      file(INSTALL ${CMAKE_CURRENT_BINARY_DIR}/build-test.sh
        DESTINATION ${CMAKE_SOURCE_DIR}/ci
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    endif()

    if(has_Windows AND has_GitHub AND NOT EXISTS ${CMAKE_SOURCE_DIR}/.github/workflows/dkml.yml)
      configure_file(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/compilers-github-workflows-dkml.in.yml
        ${CMAKE_CURRENT_BINARY_DIR}/dkml.yml
        @ONLY)
      file(INSTALL ${CMAKE_CURRENT_BINARY_DIR}/dkml.yml
        DESTINATION ${CMAKE_SOURCE_DIR}/.github/workflows)
    endif()

    if(has_GitLab AND NOT EXISTS ${CMAKE_SOURCE_DIR}/.gitlab-ci.yml)
      configure_file(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/compilers-gitlab-ci.in.yml
        ${CMAKE_CURRENT_BINARY_DIR}/.gitlab-ci.yml
        @ONLY)
      file(INSTALL ${CMAKE_CURRENT_BINARY_DIR}/.gitlab-ci.yml
        DESTINATION ${CMAKE_SOURCE_DIR})
    endif()
endfunction()
