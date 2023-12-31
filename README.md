
Ease Regale's Prototypes Deployment on Grid'5000 with NixOS-Compose
===================================================================

[![pipeline status](https://gricad-gitlab.univ-grenoble-alpes.fr/regale/tools/regale-nixos-compose/badges/main/pipeline.svg)](https://gricad-gitlab.univ-grenoble-alpes.fr/regale/tools/regale-nixos-compose/-/commits/main)

# Introduction
Each Regale prototype is an integration of non-trivial distributed systems and applications.
To facilitate their development and ensure their reproducibility, we propose the use of
[NixOS-Compose (NXC)](https://github.com/oar-team/nixos-compose).

## Nixos Compose references
- [Documentation](https://nixos-compose.gitlabpages.inria.fr/nixos-compose/)(WIP)
- [Tutorial](https://nixos-compose.gitlabpages.inria.fr/tuto-nxc/)
- [IEEE Cluster article](https://hal.archives-ouvertes.fr/hal-03723771)([bibtex](https://hal.archives-ouvertes.fr/hal-03723771v1/bibtex))

# List of prototype/integration compositions
| Directory                    | Description      | Status    | CI@Grid5000 |
|------------------------------|------------------|-----------|------------------|
| [BEBIDA-OAR](bebida/README.md) |              | WIP       | TODO             |
| [BDPO](bdpo/README.md)       | demo             | PoC (WIP) | -                |
| [BDPO-OAR](bdpo-oar/README.md) | demo           | PoC (WIP) | -                |
| [EAR](ear/README.md)         | demo             |        |  :white_check_mark:  |
| [EXAMON](examon/README.md)   | demo             | PoC (WIP) | -                |
| [OAR](oar/README.md)         | demo             |        |  :white_check_mark:  |
| [EAR-OAR](ear-oar/README.md) | base integration | PoC       | :white_check_mark:  |
| [Melissa-EAR-OAR](melissa-ear-oar/README.md)   | demo             | (WIP) | -                |
| [OAR-ICCS](oar-iccs/README.md)   | demo             | (WIP) |  :white_check_mark:  |

# Requirements

## 1. Get Grid'5000 account
 - Go https://www.grid5000.fr/w/Grid5000:Get_an_account
 - Go to the FORM for academics in France
 - Fill the form, for Grid’5000 Access Group field select datamove
 - Get some practice: 
   Getting Started page to discover Grid’5000
## 2. Access to Gricad-gitlab's private repositories from Grid'5000
As repositories in Regale/Tools are private public ssh key must be added to your Gricad-gitlab user profile.
You can use `~/.ssh/id_rsa.pub` from your Grid'5000's home. This pubkey was automatically generated during your Grid'5000 account generation (it is use to move between sites and connect nodes w/o password).
Alternatively you can generate a new pair of ssh keys. **Put** then in the https://gricad-gitlab.univ-grenoble-alpes.fr/-/profile/keys form
## 3. Install Nixos-Compose
 - Installation
 ```bash
 pip install nixos-compose
 ```
 - You might need to modify your `$PATH`:
 ```bash
 export PATH=$PATH:~/.local/bin
  ```
 - To upgrade
 ```bash
 pip install --upgrade nixos-compose
 ```
 ## 4. Install NIX with the help of Nixos-Compose
 - The following command will install a standalone and static Nix version in `~/.local/bin`
 ```bash
 nxc helper install-nix
 ```
# Use
## 1. Clone regale-nixos-compose repository on Grid'5000

```bash
git clone git@gricad-gitlab.univ-grenoble-alpes.fr:regale/tools/regale-nixos-compose.git
```
## 2. Interactive session
We take EAR case as example.

### Build image to deploy
We preconise to build on dedicated node not on frontend to avoid its overloading. 
```bash
# build on dedicated node not on frontend 
# reserve one node
oarsub -I
# go to EAR directory
cd reagle-nixos-compose/ear
# build default image (flavour g5k-nfs-store)
nxc build
```

### Deploy image on nodes

```bash
# reserve some 4 nodes for 2 hours and retrieve $OAR_JOB_ID in one step
export $(oarsub -l nodes=4,walltime=2:0 "$(nxc helper g5k_script) 2h" | grep OAR_JOB_ID)
# deploy (use last built image)
nxc start -m ./OAR.$OAR_JOB_ID.stdout -W
# connect and spawn new tmux with pane for each node
nxc connect
```
**Note:** *nxc connect* can be use to connect to only one node *nxc connect <node>*. Also **nxc connect** is really useful only if a minimal set of **[tmux](https://github.com/tmux/tmux/wiki/Getting-Started)**'s key bindings are mastered (like Ctrl-b + Up, Down, Right, Left to change pane, see tmux manul for other key bindings.

### Time to experiment
Depends of each prototype/integration.
See EAR's [README](ear/README.md) for concrete example.

### Terminate session
```bash
oardel $OAR_JOB_ID
```
Note: `oarstat -u` to list user's jobs.

## 3. Non-interactive session
Todo

# Elements for development

## Build customization via setup.toml

**setup.toml**: is a file present in each directory. It allows to apply some selectable parameters for image building, by example to change source for specific application (useful during development or test).

Below example with two setup **g5k-dev** and **laptop** selectable by option `-s`, e.g. `nxc build -s g5k-dev` or `nxc build -s laptop` 

```toml
[project]
    
[g5k-dev.options]
nix-flags = "--impure" # required when source is not committed (here in /home/orichard/ear)

[g5k-dev.build.nur.repos.kapack.ear]
src = "/home/orichard/ear"

[laptop.options]
nix-flags = "--impure"

[laptop.build.nur.repos.kapack.ear]
src = "/home/auguste/dev/ear"
```
The entry `[g5k-dev.build.nur.repos.kapack.ear]` specify that the source file for EAR is located in `/home/orichard/ear` directory.



# Tips

- **tmux**: It's recommended to use **[tmux](https://github.com/tmux/tmux/wiki/Getting-Started)** on frontend to cope with connection error between Grid'5000 and the outside.

Launch a new session:

    tmux

Attach to a previous session (typically after and broken network connection)
    
    tmux a

Display help and keyboard shortcuts:

    CTRL-b ?

Some command shortcuts:

    CTRL-b "          split vertically 
    CTRL-b %          split horizontally (left/right)

    CTRL-b left       go to pane on the left
    CTRL-b right      go to pane on the right 
    CTRL-b up         go to pane on the up 
    CTRL-b down       go to pane on the down 

    CTRL-b x          kill current pane


- **Redeployment**: If the number of nodes is the same or lower than the deployed ones it not needed to submit a new job, just execute a new `nxc start -m NODES_FILE` command with `NODES_FILE` contained the apprioate number of machine.
