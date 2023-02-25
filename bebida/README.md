# Introduction

This composition proposes an environment with Bebida implemented on Kubernetes and and OAR.

# Main Steps
See main [README](../README.md) for more information about setting.

## Build
```bash
oarsub -I
cd regale-nixos-compose/bebida
nxc build
```

## Deploy
```bash
export $(oarsub -l nodes=4,walltime=2:0 "$(nxc helper g5k_script) 2h" | grep OAR_JOB_ID)
# Note the -k for required additional kernel parameters
nxc start -m ./OAR.$OAR_JOB_ID.stdout -W -k "intel_pstate=disable systemd.unified_cgroup_hierarchy=0"
nxc connect
```

**Remainder:** *nxc connect* is based on tmux look at its manual for useful key bindings.

## Use
```bash
#
# On frontend
#
su user1

TODO
```
