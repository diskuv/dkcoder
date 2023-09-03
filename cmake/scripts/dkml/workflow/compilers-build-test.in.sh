#!/bin/sh
##########################################################################
# File: dktool/cmake/scripts/dkml/workflow/compilers-build-test.in.sh    #
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

# Updating
# --------
#
# 1. Delete this file.
# 2. Run dk with your original arguments:
#        ./dk dkml.workflow.compilers @ARGV_SPACE_SEPARATED@
#    or get help to come up with new arguments:
#        ./dk dkml.workflow.compilers HELP

set -euf

# Set project directory
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$CI_PROJECT_DIR"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$PC_PROJECT_DIR"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    PROJECT_DIR="$GITHUB_WORKSPACE"
else
    PROJECT_DIR="$PWD"
fi
if [ -x /usr/bin/cygpath ]; then
    PROJECT_DIR=$(/usr/bin/cygpath -au "$PROJECT_DIR")
fi

# PATH. Add opamrun
export PATH="$PROJECT_DIR/.ci/sd4/opamrun:$PATH"

# Initial Diagnostics (optional but useful)
opamrun switch
opamrun list
opamrun var
opamrun config report
opamrun option
opamrun exec -- ocamlc -config

# Update
opamrun update

# Make your own build logic! It may look like ...
opamrun install . --deps-only --with-test --yes
opamrun exec -- dune runtest
