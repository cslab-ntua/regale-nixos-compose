#!/bin/sh
set -x

# Melissa will paste the `preprocessing_instructions`


# the remainder of this file should be left untouched. 
# melissa-launcher will find and replace values in 
# curly brackets (e.g. /nix/store/m1n912x94plcks3rg8xm1bkwad4kipbr-melissa-launcher-1.0/lib/python3.10/site-packages/melissa_set_env.sh) with 
# the proper values.
# . /nix/store/m1n912x94plcks3rg8xm1bkwad4kipbr-melissa-launcher-1.0/lib/python3.10/site-packages/melissa_set_env.sh

echo "DATE                      =$(date)"
echo "Hostname                  =$(hostname -s)"
echo "Working directory         =$(pwd)"
echo ""
echo $PYTHONPATH

set -e

exec melissa-server --project_dir /home/afaure/code/melissa/examples/heat-pde/heat-pde-sa/ --config_name config_oar
