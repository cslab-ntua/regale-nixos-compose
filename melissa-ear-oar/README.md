# Introduction

This composition proposes an environment with EAR and OAR. [NAS Parallel Benchmarks](https://www.nas.nasa.gov/software/npb.html) are provided and compiled with gcc in MPI and OpenMP variants.

# Main Steps
See main [README](../README.md) for more information about setting.

## Build
```bash
oarsub -I
cd regale-nixos-compose/ear
nxc build
```

## Deploy
Nodes requirements: **5 nodes**
```bash
export $(oarsub -l cluster=1/nodes=5,walltime=2:0 "$(nxc helper g5k_script) 2h" | grep OAR_JOB_ID)
nxc start -m ./OAR.$OAR_JOB_ID.stdout -W
nxc connect
```
**Note:** *cluster=1* in the oarsub request allows to
**Remainder:** *nxc connect* is based on tmux look at its manual for usefull key bindings.

## Start melissa

To use melissa, you can start with the official examples folders from melissa.

First connect to the frontend, and clone melissa repository.

```bash
nxc connect frontend
su user1

# Your g5k home is accessible so you ca do this step only once
cd /home/<you-g5k-user>/ && git clone git@gitlab.inria.fr:melissa/melissa-combined.git

cd melissa-combined/examples/heat-pde-sa
```

Edit the file config_oar.json with this content:


```json
{
    "server_filename": "heatpde_sa_server.py",
    "server_class": "HeatPDEServerSA",
    "output_dir": "DEBUG",
    "study_options": {
        "field_names": ["temperature"],
        "num_clients": 100,
        "group_size": 1,
        "num_samples": 100,
        "nb_parameters": 5,
        "simulation_timeout": 400,
        "checkpoint_interval": 300,
        "crashes_before_redraw": 1000,
        "verbosity": 3
    },
    "SA_CONFIG": {
        "mean": true
    },
    "launcher_config": {
    "http_token": "pot-pourri",
        "scheduler": "oar",
        "num_server_processes": 1,
        "num_client_processes": 1,
        "job_limit": 10,
        "executable_options": [
                " -x LD_PRELOAD=$EAR_INSTALL_PATH/lib/libearld.so",
                "-x OAR_EAR_LOAD_MPI_VERSION=ompi",
                "-x OAR_EAR_LOADER_VERBOSE=4",
                "-x OAR_STEP_NUM_NODES=$(uniq $OAR_NODEFILE | wc -l)",
                "-x OAR_JOB_ID=$OAR_JOB_ID",
                "-x OAR_STEP_ID=0"
        ],
        "scheduler_arg_client": [
            "nodes=1",
            ",walltime=00:30:00"
        ],
        "scheduler_arg_server": [
            "nodes=1",
            ",walltime=10:00:00"
        ],
        "no_fault_tolerance": false,
        "client_executable": "heatc",
        "verbosity": 3
    }
}
```

Then start the melissa simulation with `melissa-launcer --project_dir $PWD --config_name config_oar`.
