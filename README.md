# DevOps
[![buddy pipeline](https://app.buddy.works/ru31337/devops/pipelines/pipeline/172357/badge.svg?token=31fa9fb1d6f9009c4b1729288488ef5366eb18bd8871a3d678eec45af4fda87f "buddy pipeline")](https://app.buddy.works/ru31337/devops/pipelines/pipeline/172357)

## Install
```bash
wget -qO - https://raw.githubusercontent.com/intech/devops/master/startup.sh | bash
```
### Install tools
- mc
- htop
- curl
- git
- net-tools

### Create SWAP by calculate available RAM

| RAM  | SWAP |
|------|------|
| >4G  | 4G   |
| 1-4G | 1-4G |
| <1G  | 1G   |

### Install docker
Get and install latest version

### Install docker-compose
Get and install latest version

### Install tinc vpn

## Manual install and run only tinc vpn in docker
```bash
wget -qO - https://raw.githubusercontent.com/intech/devops/master/tinc.sh | GIT='https://login:secret@github.com/user/repo.git' bash
```