#!/bin/sh
set -x

# Melissa will paste the `preprocessing_instructions`
echo bash commands
echo go here

# melissa-launcher will find and replace 'melissa_set_env_file'
# automatically, do not change this line.
# . /nix/store/m1n912x94plcks3rg8xm1bkwad4kipbr-melissa-launcher-1.0/lib/python3.10/site-packages/melissa_set_env.sh

# User can set this part of the client script up automatically
# by ensuring that the keys in their `client_config` dictionary
# match the keywords below.  
# For example:
# melissa-launcher will search and replace "executable_command"
# automatically with the "executable_command" set in the 
# client_config file.

exec heatc 100 100 100 "$@"

