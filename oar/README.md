# Introduction

This composition proposes an environment with OAR. [NAS Parallel Benchmarks](https://www.nas.nasa.gov/software/npb.html) are also provided and compiled with gcc in MPI and OpenMP variants.

# Main Steps
See main [README](../README.md) for more information about global installation and setting.

## Build
```bash
oarsub -I
cd regale-nixos-compose/ear
nxc build
```

## Deploy
Nodes requirements: **4 nodes**
```bash
export $(oarsub -l cluster=1/nodes=4,walltime=2:0 "$(nxc helper g5k_script) 2h" | grep OAR_JOB_ID)
nxc start -m ./OAR.$OAR_JOB_ID.stdout -W
nxc connect
```
**Note:** *cluster=1* in the oarsub request allows to request nodes belonging to the same cluster (homogeneous nodes).
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
# launch NAS Parallel Benchmark CG
mpirun --hostfile $OAR_NODEFILE -mca pls_rsh_agent oarsh -mca btl tcp,self cg.C.mpi

# terminate job
exit # or Ctrl-D

# passive job
# prepare script
echo "mpirun --hostfile \$OAR_NODEFILE -mca pls_rsh_agent oarsh -mca btl tcp,self cg.C.mpi" > test.sh
chmod 755 test.sh
# submit passive job
oarsub -l nodes=2 ./test.sh
# display job output
more OAR.*.stdout
```
