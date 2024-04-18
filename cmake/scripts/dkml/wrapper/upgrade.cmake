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

Upgrade ./dk, ./dk.cmd and __dk.cmake.

If there is a .git/ directory and no .gitattributes then a 
default .gitattributes configuration file is added.

And if there is a .git/ directory the .gitattributes, ./dk, ./dk.cmd
and __dk.cmake are added to Git.

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

set(old_dk_find_scripts_UNIX_CKSUM256
  # git log --format=%H 3df563c0f760d79cf0df8dfbc5bde8ac4f50a510..HEAD -- cmake/scripts/__dk-find-scripts.cmake | while read gitref; do git show ${gitref}:cmake/scripts/__dk-find-scripts.cmake | shasum -a 256; done | awk -v dq='"' '{print dq $1 dq}' | sort
  "022982a5b7343a6beefdff59a4dd0f92835f4b6cc89e7d0cf6e02cf4f074beb3"
  "08b473f97455fe6086b7b8b2d6efb3ed68c2d1f4bdb803a8d9365ba4e4081014"
  "1cc8d90ee79e0515762a0d457a28881b7eda911783c41d7788d3730bac124c56"
  "1d62727ecd52d813d8f698bec3a335c34a169c4606cae74e099fddd72927ca98"
  "221f7845f290a1ab447d6d1de785a7bbbbe221c88d7774982f89d4a2e4f8bdc6"
  "22bf9a43151985f0a375da97b4511bc7a58993dde2810ed84746c0a1c23597d7"
  "23d6fe3c6f2d9a1c3e4d95636ba6059809019f2cdc6e10175a044484e208e9e0"
  "2acc0b5f80e870d83adff2cbad2d69b27d97396cc2d26571786d343305284a78"
  "2c12c647a60dc1d74ded10b69df4f36a0670854dcb17833f08151be716c7c14e"
  "38c0b118762dd42ee91d504201fcbd641f5afbbfd6700d160f4b60c42a25d6b1"
  "396f7f71c3b97a865ae008b2d94a122717736672a744e099691f7dcc8fcb8c9c"
  "3b93cb01e337b276592f9b0675c25506b2fb7d77f433ae6e5e0c3ccd7d6849be"
  "482afa5c884a1e56e32f8405ac562421a10ac17e00eae22aa80dc232bcd98801"
  "4857dfe208b38a91adb64d578a1f6d09becc421796588193b4315fa595fb414c"
  "48694dbebcc8fd640f99ab96fdc5c172dedf78ea278c914619f8964f85fc8b4f"
  "4e55a8afb363075422a0f9eb374c9246f67e3d0372ad782ec0c5f5faebbd57b0"
  "5758f125e9e9867010fd875579fb9a6d83dd9084efdeb3d42760f2e0bddf5942"
  "58664f2c49ce71a5443e6a14954d93d44ffb27553142691a0270109aa84f772f"
  "5a975344bd2fbe3f4e46f134f93a3bb30ad569e6058dbe0dacdcbd155b231490"
  "5e456ab7fe8c4cd0621311c2b741eb1e318e651bd78cd289785c7a4f99319145"
  "5e69c10651682ad210358d5f4d671b2c3d79d2e90133b50fff89c918828fd1a1"
  "612af8209293bed3ee40abd05b1d43c67d1445d99a60bbb0fd0369543c2c28ed"
  "645bc1a907c49da858806bf8b1f48628000fea735144dc64b360cfceebd29488"
  "6792293e89756329eae8061b9ffca527ae573dfa2dd601b4b8f9cc48e1c0d457"
  "69c7af1efc0ee9963dc841e3860ae2df34b59cd21409fec16d5019a5315a588c"
  "6ffd7079a01fd2bafcac89f9f2501b58bb30c0e6383f4b5bc088e544cf6adb58"
  "733846401973a59d524519d1e0f56756bb35f02797a6c4a55ada8964f96f27a4"
  "87ea7913be878c1b9ad1518a260a8595479368baafb0d9c9026a40f7f49496b1"
  "9beb25ab0e465349335a3280d5e3b950e8f89edab431ac9188b098992feb490b"
  "9d0e50b192ea90b172a41ca714557604e51121769b3e9229ae440c0e04915262"
  "9d23765bd0e43ab9e160cd81fd5f1a99756d888fa933b34a40aa9e88b1362efd"
  "9dc85398fa9bf89958cf8b94b2bd4c5cae94a331af90592b4c6803b4999d9062"
  "a4d982c88c4f48b83ed0b62b2a043267041860f99b9110e4c80f651f97d2e12c"
  "a8771418412bf0f1a73ec0b09491158f1b6cda592e5c2f5d63a1656578fde803"
  "ae1858823722580ab45011b027df97e033c2ef4d3e0b6d745d65f33992797c73"
  "af3a81a087e8a3d4843d7ccb7b7077a3f1ce99e905db33a49a2b57fa2f63df70"
  "b56eda45d41fe951059a6418c3e74cafe79027dcb5a188f5f6a45d643033c416"
  "b602ee08310d5df9d5b17a60de2954153e2efe9974a75b2a268b4648508a1cf7"
  "bcc02624c54b982ebccbef8d12123bfb85e5b0418d3adef82b70d8e40794a9c9"
  "c1dfc6ca51cb6f0a2660a52c99e0c98be025bd8d3eea183c657f947ba6189de8"
  "c3c62eef95a179a06f6f5b75c3deefa791913051736acc041fa53db1e9c8d4e8"
  "ca3944b08b33221ad567e15c9cf2bbd60d38b7c720eec6c23ec4230842ff33b4"
  "ce4471f56092ed846f15b9861f9f704648225c71a7feb694fd650418cb9e0de7"
  "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  "e8edf408a74dc15b52cf070b52e2799677d328fe049d7b9569a3eb3fa9801781"
  "e91460c7edd9267cf18d73680124b7ac095028a42ddc00282ca8df5738b47fc6"
  "eabf0b4dbc200e31767092cebb7601d602d42afcab1bcd4ac2e8c089f203fc80"
  "f21da85ea7b805ead733b4141529ea835cb8f6eddeb0c22c4adc51f862f21275"
  "f523a76accfc5b513a8c3c0ed80d82dec0ca810e13a2a13c8f1488c6d55f41f9"
  "fba565f53cdd73692ed2313003eff746f2386e1accf0b471db808cc6a0ff1563")

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
    cmake_path(SET path_dkfindscriptscmake "__dk.cmake")
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
      message(FATAL_ERROR "Missing '__dk.cmake' at expected ${file_dkfindscriptscmake}")
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
        DESTINATION "${dest}"
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
    file(INSTALL "${file_dk}"
        DESTINATION "${dest}"
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    set(paths_ADDED "${path_dk}" "${path_dkcmd}" "${path_dkfindscriptscmake}")

    # deletions
    set(paths_DELETED)
    if(EXISTS "${dest}/cmake/scripts/__dk-find-scripts.cmake")
      file(SHA256 "${dest}/cmake/scripts/__dk-find-scripts.cmake" dkfindscriptscmake_cksum256)
      set(delete OFF)
      if(dkfindscriptscmake_cksum256 IN_LIST old_dk_find_scripts_UNIX_CKSUM256)
        set(delete ON)
      endif()
      if(delete)
        file(REMOVE "${dest}/cmake/scripts/__dk-find-scripts.cmake")
        list(APPEND paths_DELETED "cmake/scripts/__dk-find-scripts.cmake")
      endif()
      unset(delete)
    endif()
    
    # Do Git operations automatically
    if(IS_DIRECTORY "${dest}/.git")
      find_package(Git QUIET REQUIRED)

      # install .gitattributes
      if(NOT EXISTS "${dest}/${path_gitattributes}")
        file(INSTALL "${file_gitattributes}"
          DESTINATION "${dest}"
          FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
        list(APPEND paths_ADDED "${path_gitattributes}")
      endif()

      # add the four files
      execute_process(WORKING_DIRECTORY "${dest}"
        COMMAND "${GIT_EXECUTABLE}" add ${paths_ADDED}
        COMMAND_ERROR_IS_FATAL ANY)
      
      # deletions
      if(paths_DELETED)
          execute_process(WORKING_DIRECTORY "${dest}"
            COMMAND "${GIT_EXECUTABLE}" rm -f ${paths_DELETED}
            COMMAND_ERROR_IS_FATAL ANY)
      endif()

      # for Windows, the *_EXECUTE permissions earlier do nothing. And a subsequent `git add` will not set the
      # git chmod +x bit. So we force it.
      execute_process(WORKING_DIRECTORY "${dest}"
        COMMAND "${GIT_EXECUTABLE}" update-index --chmod=+x "${path_dk}"
        COMMAND_ERROR_IS_FATAL ANY)
    endif()

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
endfunction()
