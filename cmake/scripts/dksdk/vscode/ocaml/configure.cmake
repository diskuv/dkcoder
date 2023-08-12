function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")
    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()
    message(${ARG_MODE} [[usage: ./dk dksdk.vscode.ocaml.configure

Configures, or creates if not present, .vscode/settings.json so that
Visual Studio Code is setup for the DkSDK project.

If there is an existing settings.json file _and_ the DkSDK
configuration is not already present:
- A backup file will be made in the .vscode/ directory.
- Any JSON comments (ie. `// comment`) will be removed.
- The settings keys will be sorted.

Directory Structure
===================

.vscode/
└── settings.json

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

    set(jsonFile ${CMAKE_SOURCE_DIR}/.vscode/settings.json)
    cmake_path(NORMAL_PATH CMAKE_SOURCE_DIR OUTPUT_VARIABLE CMAKE_SOURCE_DIR_NORMALIZED)

    set(admonition [[

    You must exit Visual Studio Code and then re-launch Visual Studio
Code so that the settings take effect.
]])

    # ocaml.sandbox value
    set(template "${CMAKE_SOURCE_DIR_NORMALIZED}/dk dksdk.cmd.exec QUIET CMD $prog $args")
    set(ocamlSandbox "{
        \"kind\": \"custom\",
        \"template\": \"${template}\"
    }")
    # Create if not already present
    if(NOT EXISTS ${jsonFile})
        file(CONFIGURE OUTPUT ${jsonFile} CONTENT [[{
    "ocaml.sandbox": @ocamlSandbox@
}
]] @ONLY)
        message(STATUS "Created ${jsonFile}.${admonition}")
        return()
    endif()

    # Get the JSON content
    file(READ ${jsonFile} jsonContent)

    # Check if already added
    string(JSON kind0 ERROR_VARIABLE error1 GET "${jsonContent}" ocaml.sandbox kind)
    string(JSON template0 ERROR_VARIABLE error2 GET "${jsonContent}" ocaml.sandbox template)
    if(NOT error1 AND NOT error2 AND kind0 STREQUAL custom AND template0 STREQUAL "${template}")
        message(STATUS "ocaml.sandbox already configured in ${jsonFile}")
        return()
    endif()

    # Set/add it otherwise
    string(JSON newJsonContent SET "${jsonContent}" ocaml.sandbox "${ocamlSandbox}")
    string(TIMESTAMP now "%s")
    message(STATUS "Backup is at ${jsonFile}.${now}.bak")
    file(COPY_FILE ${jsonFile} ${jsonFile}.${now}.bak)
    file(WRITE ${jsonFile} "${newJsonContent}")
    message(STATUS "Edited ${jsonFile}.${admonition}")
endfunction()
