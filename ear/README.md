# Introduction

This composition is a simple demonstration a EAR use with simulated OAR interaction. [NAS Parallel Benchmarks](https://www.nas.nasa.gov/software/npb.html) are provided and compiled with gcc in MPI and OpenMP variants.

# Quick start
See main [README](../README.md) for more information about setting.

## Build
```bash
oarsub -I
cd regale-nixos-compose/ear
nxc build
```

## Deploy
Nodes requirements: **4 nodes**
```bash
export $(oarsub -l nodes=4,walltime=2:0 "$(nxc helper g5k_script) 2h" | grep OAR_JOB_ID)
nxc start -m ./OAR.$OAR_JOB_ID.stdout -W
nxc connect
```
## Use
### On node1 or node2
```bash
#
# On node1 or node2
#
# create a node file for MPI
yes node1  | head -n 8 > machines && yes node2  | head -n 8 >> machines
uniq machines > uniq_machines

# Set OAR variable and signal the start job to EAR
export OAR_JOB_ID=1
export OAR_USER=user1
oar-ejob 50001 newjob uniq_machines

# Launch cg.C.mpi with approriate LD_PRELOAD
# Note: TCP is used for communication
mpirun --hostfile machines -np 16  --mca btl tcp,self \
-x LD_PRELOAD=${EAR_INSTALL_PATH}/lib/libearld.so \
-x OAR_EAR_LOAD_MPI_VERSION=ompi \
-x OAR_EAR_LOADER_VERBOSE=4 \
-x OAR_STEP_NUM_NODES=2 \
-x OAR_JOB_ID=$OAR_JOB_ID\
-x OAR_STEP_ID=0\
cg.C.mpi

# Signal the job end to EAR
oar-ejob 50001 endjob uniq_machines

# After some lapse of time
ereport
eacct

# On eardb Node
# to explore the database
mysql -D ear
select * from Jobs;
select * from Applications;
select * from Signatures;
```