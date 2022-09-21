
Ease Regale's Prototype Deployment on Grid'5000
============================================================

**IMPORTANT !!!**: **Rewrite of this page  is pending**
- We are preparing a Nixos-Compose Tutorial (for the end of septembre):  https://nixos-compose.gitlabpages.inria.fr/tuto-nxc/ (WIP)
- When Nixos-compose tutorial is finished, this page will be updated accordingly

We use Nixos-compose to package and pre-deploy

# Installation

## 1. Get Grid'5000 account
 - Go https://www.grid5000.fr/w/Grid5000:Get_an_account
 - Go to the FORM for academics in France
 - Fill the form, for Grid’5000 Access Group field select datamove
 - Get some practice: 
   Getting Started page to discover Grid’5000
   
## 2. Install Nix with script helper
 - Visit: https://github.com/oar-team/nix-user-chroot-companion
 - Installation (on frontend repeat once per site)   
 ```bash
 curl -L -O https://raw.githubusercontent.com/oar-team/nix-user-chroot-companion/master/nix-user-chroot.s 
 chmod 755 nix-user-chroot.sh
```
## 3. Use

```bash
./nix-user-chroot.sh
```

## 4. Install nixos-compose
```bash
git clone https://gitlab.inria.fr/nixos-compose/nixos-compose
cd nixos-compose
poetry install
```

## 5. Clone regale-nixos-compose
```bash
git clone git@gricad-gitlab.univ-grenoble-alpes.fr:regale/tools/regale-nixos-compose.git
```

## 6. Clone EAR (needed to be clone because gridcad-gitlab repo is not public, apply for other tools also)
```bash
git clone git@gricad-gitlab.univ-grenoble-alpes.fr:regale/tools/ear.git
```

(To Complete)

# Usage

## Preambule 
It's recommanded to use **tmux** on frontend to cope with connection error between Grid'5000 and the outside.

**setup.toml** adaptation:
This file is present in each directory. It allows to apply some selectable parameters for image building.
Below example with two setup g5k and dev

```toml
[project]
selected = "dev"
        
[g5k.options]
nix-flags = "--impure --override-input nxc path:/home/orichard/nixos-compose/dev --override-input kapack path:/home/orichard/nur-kapack/ear"
          
[g5k.overrides.nur.kapack]
ear = { src = "/home/orichard/regale-ear" }

[dev.options]
nix-flags = "--impure --override-input kapack path:/home/auguste/dev/nur-kapack/ear"

[dev.overrides.nur.kapack]
ear = { src = "/home/auguste/dev/regale-ear" }
```

The main adpatation is to *change orichard with your username* 
```bash
sed -i 's/orichard/'$USER'/' setup.toml
```

## Common steps

### Build (ramdisk) image
```bash
# build on dedicated node not on frontend 
# reserve one node
oarsub -I
# activate nixos-compose env
cd nixos-compose
poetry shell
# activate nix
cd
./nix-user-chroot.sh
# build EAR image
cd regale-nixos-compose/ear
nxc build -s g5k -f g5k-ramdisk
```
### Deploy 

```bash
# activate nixos-compose env
cd nixos-compose
poetry shell
# reserve some nodes and retrieve $OAR_JOB_ID in one step
export $(oarsub -l nodes=5,walltime=2:0 "$(nxc helper g5k_script) 2h" | grep OAR_JOB_ID)
# deploy (use last built image)
nxc start -m ./OAR.$OAR_JOB_ID.stdout -W
# connect spawn new tmux
nxc connect
```

## EAR
Resources requirement: 4 nodes
```bash
# on node12

yes node12  | head -n 8 > machines && yes node11  | head -n 8 >> machines
   
# on each nodes !!!
export OAR_JOB_ID=1
# on each nodes !!!
ejob 50001 newjob

# on node12
mpirun --hostfile machines -np 16  --mca btl tcp,self \
 -x LD_PRELOAD=${EAR_INSTALL_PATH}/lib/libearld.so \
 -x OAR_EAR_LOAD_MPI_VERSION=ompi \
 -x OAR_EAR_LOADER_VERBOSE=4 \
 -x OAR_STEP_NUM_NODES=2 \
 -x OAR_JOB_ID=$OAR_JOB_ID\
 -x OAR_STEP_ID=0\
 cg.C.mpi

# on each nodes !!! 
ejob 50001 endjob
```
## OAR
Resources requirement: 4 nodes
```bash
# on frontend
su user1
cd
# ask 2 nodes in interactive mode
oarsub -I nodes=2
```

## EAR-OAR
Resources requirement: 5 nodes
(To Complete)

# Development
(To Complete)
