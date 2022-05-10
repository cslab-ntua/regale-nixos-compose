
Ease Regale's Prototype Deployment on Grid'5000
============================================================

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
 ```
 curl -L -O https://raw.githubusercontent.com/oar-team/nix-user-chroot-companion/master/nix-user-chroot.s 
 chmod 755 nix-user-chroot.sh
```
## 3. Use

```
./nix-user-chroot.sh
```

## 4. Install nixos-compose
```
git clone https://gitlab.inria.fr/nixos-compose/nixos-compose
cd nixos-compose
poetry install
```

## 5. Clone regale-nixos-compose
```
git clone git@gricad-gitlab.univ-grenoble-alpes.fr:regale/tools/regale-nixos-compose.git
```

## 6. Clone EAR (needed to be clone because gridcad-gitlab repo is not public, apply for other tools also)  

(TBC)

# Usage

## Preambule 
It's recommanded to use **tmux** on frontend to cope with connection error between Grid'5000 and the outside.

## EAR

## OAR

## EAR-OAR

# Development
