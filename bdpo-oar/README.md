# Introduction

This composition proposes an environment with BDPO and OAR. [NAS Parallel Benchmarks](https://www.nas.nasa.gov/software/npb.html) are provided and compiled with gcc in MPI and OpenMP variants.

# Main Steps
See main [README](../README.md) for more information about setting.

## Build
```bash
oarsub -I
cd regale-nixos-compose/ear
nxc build
```

## Deploy
Nodes requirements: **Node with functional acpi-cpufreq driver (as on Lyon site)
```bash
export $(oarsub -p cluster="nova" -l nodes=4,walltime=2:0 "$(nxc helper g5k_script) 2h" | grep OAR_JOB_ID)
# Note the -k for required additional kernel parameters 
nxc start -m ./OAR.$OAR_JOB_ID.stdout -W -k "intel_pstate=disable systemd.unified_cgroup_hierarchy=0"
nxc connect
```

**Remainder:** *nxc connect* is based on tmux look at its manual for usefull key bindings.

## Use
### 
```bash
#
# On frontend
#
su user1
cd

# interactive job
oarsub -I -l nodes=2

# TO COMPLETE ...
```
