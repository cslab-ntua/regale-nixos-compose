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

# Interactive job
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

## Install drawgantt and monika

The OAR web interfaces monika and drawgantt can be activated and accessed for the OAR3 of the composition.

The first step is to enable the related services (dranwgantt and monika) into the `composition.nix` file under the frontend role.

```nix
  frontend = { ... }: {
    [ .. ]
    services.oar.web.enable = true;
    services.oar.web.drawgantt.enable = true;
    services.oar.web.monika.enable = true;
  };
```

After a (re-)build and a fresh deployment, the frontend should have the services activated.

The next step is to find which G5K node runs the frontend. This information is located into the deployment file into the `deploy` folder.
In the case of a the `g5k-nfs-store` flavour, the file should be: `deploy/composition\:\:g5k-nfs-store.json`.

For instance, this command retrieve the host that runs the frontend:
```
host $(cat deploy/composition\:\:g5k-nfs-store.json  | jq -r '.deployment | to_entries[] | select(.value.role == "frontend") | "\(.key)"')
```

Following this [tutorial](https://www.grid5000.fr/w/HTTP/HTTPs_access), the drawgantt interface should be accessible at the `/drawgantt` url.
For instance, if the frontend is deployed on the node `dahu-32`, the final url will be `https://dahu-32.grenoble.http.proxy.grid5000.fr/drawgantt`.
