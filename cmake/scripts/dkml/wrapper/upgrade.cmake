function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")
    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()
    message(${ARG_MODE} [[usage: ./dk dkml.wrapper.upgrade

Upgrade ./dk, ./dk.cmd and cmake/FindDkToolScripts.cmake.

Arguments
=========

HELP
  Print this help message.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP" "" "")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    # <dktool>/cmake/scripts/dkml/wrapper/upgrade.cmake -> <dktool>
    cmake_path(GET CMAKE_CURRENT_FUNCTION_LIST_DIR PARENT_PATH d)
    cmake_path(GET d PARENT_PATH d)
    cmake_path(GET d PARENT_PATH d)
    cmake_path(GET d PARENT_PATH d)
    cmake_path(APPEND d "dk" OUTPUT_VARIABLE file_dk)
    cmake_path(APPEND d "dk.cmd" OUTPUT_VARIABLE file_dkcmd)
    cmake_path(APPEND d "cmake" "FindDkToolScripts.cmake" OUTPUT_VARIABLE file_cmake_finddktoolsscriptscmake)

    # validate
    if(NOT EXISTS ${file_dk})
      message(FATAL_ERROR "Missing 'dk' at expected ${file_dk}")
    endif()
    if(NOT EXISTS ${file_dkcmd})
      message(FATAL_ERROR "Missing 'dk.cmd' at expected ${file_dkcmd}")
    endif()
    if(NOT EXISTS ${file_cmake_finddktoolsscriptscmake})
      message(FATAL_ERROR "Missing 'FindDkToolScripts.cmake' at expected ${file_cmake_finddktoolsscriptscmake}")
    endif()

    # install
    file(INSTALL "${file_dkcmd}"
        DESTINATION ${CMAKE_SOURCE_DIR}
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
    file(INSTALL "${file_cmake_finddktoolsscriptscmake}"
        DESTINATION ${CMAKE_SOURCE_DIR}/cmake
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
    file(INSTALL "${file_dk}"
        DESTINATION ${CMAKE_SOURCE_DIR}
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
endfunction()
