# Introduction

This composition is a simple demonstration a EXAMON.

# Main Steps
See main [README](../README.md) for more information about setting.

## Build
```bash
oarsub -I
cd regale-nixos-compose/examon
nxc build
```

## Deploy
Nodes requirements: **2 nodes**
```bash
export $(oarsub -l nodes=2,walltime=2:0 "$(nxc helper g5k_script) 2h" | grep OAR_JOB_ID)
nxc start -m ./OAR.$OAR_JOB_ID.stdout -W
nxc connect
```
## Use

```bash
#
# TODO
#
```
