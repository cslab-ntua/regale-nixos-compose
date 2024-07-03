# Introduction

This composition proposes an environment with the development of OAR3 from the ICCS team focusing on performance/energy efficiency. [NAS Parallel Benchmarks](https://www.nas.nasa.gov/software/npb.html) are provided.

## Main Steps
See main [README](../README.md) for more information about setting.

# Build
## For Docker
1. Download the OAR3 code and the Nix composition:
```bash
git clone -b devel https://github.com/cslab-ntua/regale-nixos-compose.git
git clone -b devel https://github.com/cslab-ntua/oar3
```
2. Modify the path of OAR3 src in `regale-nixos-compose/oar-iccs/setup.toml` to the absolute path of the download version of OAR3.
3. Allow kernel to use the LSM BPF module by passing the parameter `lsm=bpf` in the kernel parameters of the host machine (probably reboot is needed): e.g.
```bash
BOOT_IMAGE=/boot/vmlinuz-5.4.0-163-generic root=UUID=1af66e54-f61a-42c0-96c0-62568c110533 ro quiet splash lsm=bpf
```
4. Create a Python environment e.g.
```bash
conda create -n oar-iccs Python=3.10
conda activate oar-iccs
```
5. Install NixOS Compose (nxc) [version 0.5.4]:
```bash
pip install nixos-compose==0.5.4
```
6. Install nix with the help of nxc:
```bash
nxc helper install-nix
```
7. Build the image
```bash
cd regale-nixos-compose/oar-iccs
nxc build -f docker -s iccs
```  
8. Activate kernel parameter: `systemd.unified_cgroup_hierarchy=0`. You could follow the instructions at https://wiki.archlinux.org/title/Cgroups#Tips_and_tricks or run:
```bash
sudo cp /proc/cmdline /root/cmdline
sudo sed -i 's/$/ systemd.unified_cgroup_hierarchy=0/' /root/cmdline
sudo mount -n --bind -o ro /root/cmdline /proc/cmdline
```
**Reminder**: If you want to re-build, you probably need to `umount /proc/cmdline` first, otherwise docker might not work.

9. After successfully built, run:
```bash
nxc start -f docker -s iccs
```
in order to deploy all virtual nodes. Use `nxc stop` to remove them.
10. Use  `nxc connect frontend; su user1; oarsub -l /core=5 'sleep 60' type=spread`
11. Observe Monika and DrawGantt from: http://localhost:8000/monika and http://localhost:8000/drawgantt respectively.

## For Grid5000 (g5k) nfs-store:
1. Download the OAR3 code and the Nix composition (main branch):
```bash
git clone -b 4011ca5e5a255480b751ace9c340ad56a1aafb1f https://github.com/cslab-ntua/regale-nixos-compose.git
git clone -b devel https://github.com/cslab-ntua/oar3
```
Follow the rest of the Docker-built steps apart from 3 and 8. If nxc not found export path by typing: `export PATH=$PATH:~/.local/bin;`
* Step 7 will changed to:
```bash
cd regale-nixos-compose/oar-iccs
nxc build -f g5k-nfs-store -s iccs
```
* Step 9 will need to reserve nodes before deployment, so:
```bash
export $(oarsub -l nodes=4,walltime=1:0:0 "$(nxc helper g5k_script) 1h" | grep OAR_JOB_ID)
```
* Check state of Job when it's in **R** by typing: `oarstat -u user` and the deploy:
```bash
nxc start -s iccs -m OAR.$OAR_JOB_ID.stdout -W -f g5k-nfs-store
```
* Observe Monika and DrawGantt from: https://machine.site.http.proxy.grid5000.fr/monika and https://machine.site.http.proxy.grid5000.fr/drawgantt respectively, where the machine is the first node allocated at step 9.

* ## For Grid5000 (g5k) image:
You have to use the latest nixos-compose: https://github.com/oar-team/nixos-compose/tree/c1445485285566bd5b3236c350199cfde15a2489
```
pip -U install https://github.com/oar-team/nixos-compose
```
and add `-t deploy` when reserving nodes, following a sleep command similar to the walltime. Then you have to create the machines file and `nxc start`.
Steps:
```
export PATH=$PATH:~/.local/bin;
oarsub -l nodes=10,walltime=01:30:10 -t deploy -p "cluster='dahu'" "sleep 90m"
# or
# oarsub -l nodes=10,walltime=03:00:10 -t deploy -p "cluster='grvingt'" -q production "sleep 180m"

oarstat -u -J | jq --raw-output 'to_entries | .[0].value.assigned_network_address | .[]' > machines
nxc start -s iccs -m machines -f g5k-image
```
* In case of errors in kedeploy you can monitor the allocated nodes by running the below command and resubmitting the `nxc start` command:
`kaconsole3 -m dahu-32`
