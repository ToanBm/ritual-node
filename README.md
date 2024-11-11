# Ritual Infernet Node Setup

## 0. Register wallet:
https://basescan.org/address/0x8d871ef2826ac9001fb2e33fdd6379b6aabf449c#writeContract

## 1. Install Packages & Tools:
```Bash
sudo apt update & sudo apt upgrade -y
sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 -y
```
## 2. Install Docker:
```Bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
docker version
```
## 3. Install Docker Compose:
```Bash
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)

curl -L "https://github.com/docker/compose/releases/download/"$VER"/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose
docker-compose --version
```
## 4. Starter Repository:
```Bash
git clone https://github.com/ritual-net/infernet-container-starter && cd infernet-container-starter
```
## 5. Running hello-world:
```Bash
screen -S ritual
```
```Bash
project=hello-world make deploy-container
```
Detach from your session with:: CTRL + A + D
## 6. Node Configuration:
### - container/config.json
```Bash
nano ~/infernet-container-starter/deploy/config.json
```
```Bash
nano ~/infernet-container-starter/projects/hello-world/container/config.json
```
Edit file `config.json` with `your-private-key (include prefix 0x)` as in the code below. 
(Ctrl + X, Y and Enter will do to save)
```Bash
-RPC URL: https://mainnet.base.org/
-Registry address: 0x3B1554f346DFe5c482Bb4BA31b880c1C18412170
-Private Key: Enter your private key: 0x........
-Edit the snapshot sync:
    "snapshot_sync": {
        "sleep": 3,
        "starting_sub_id": 180000,
        "batch_size": 800,
        "sync_period": 30
    },
-Remove this lines:
    "docker": {
        "username": "username",
        "password": ""
    },
```
### - contracts/script/Deploy.s.sol
```Bash
nano ~/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol
```
Edit file `Deploy.s.sol` as in the code below. 
(Ctrl + X, Y and Enter will do to save)
```Bash
-Registry address: 0x3B1554f346DFe5c482Bb4BA31b880c1C18412170
```
### - contracts/Makefile
```Bash
nano ~/infernet-container-starter/projects/hello-world/contracts/Makefile
```
Edit file `Makefile` with `your-private-key (include prefix 0x)` as in the code below. 
(Ctrl + X, Y and Enter will do to save)
```Bash
sender := 0x<your-private-key>
RPC_URL := https://mainnet.base.org/
```
### - docker-compose.yaml
```Bash
nano ~/infernet-container-starter/deploy/docker-compose.yaml
```
Edit file `docker-compose.yaml` with `as in the code below.
(Ctrl + X, Y and Enter will do to save)
```Bash
image: ritualnetwork/infernet-node:1.4.0
change port: 8545 > 8585
```
## 7. Docker containers:
```Bash
docker container ls
```
## 8. Initialize Configuration:
### - Restart node:
```Bash
cd && docker compose -f infernet-container-starter/deploy/docker-compose.yaml down && docker compose -f infernet-container-starter/deploy/docker-compose.yaml up -d
```
### - Check log:
```Bash
docker ps
```
```Bash
docker logs -f infernet-node
```
```Bash
docker logs -f infernet-fluentbit
```
```Bash
docker logs -f infernet-anvil
```
```Bash
docker logs -f infernet-redis
```
```Bash
docker logs -f hello-world
```
### Ctrl + C to exit log.
## 9. Install Foundry:
```Bash
cd
mkdir foundry && cd foundry
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
source ~/.bashrc
foundryup
```
## 10. Installing required libraries and SDKs:
### - Remove old data:
```Bash
rm -rf ~/infernet-container-starter/projects/hello-world/contracts/lib/forge-std
rm -rf ~/infernet-container-starter/projects/hello-world/contracts/lib/infernet-sdk
```
### - Installing
```Bash
cd
cd ~/infernet-container-starter/projects/hello-world/contracts
forge install --no-commit foundry-rs/forge-std
forge install --no-commit ritual-net/infernet-sdk
cd ../../../
```
## 11. Deploy Consumer Contract:
### In `infernet-container-starter` folder
```Bash
project=hello-world make deploy-contracts
```
* Contract Address:  0x... (Your-Contract)

## 12. Call Contract:
```Bash
nano ~/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol
```
Change `CallContract.s.sol` with `SaysGM saysGm = SaysGM(Your-Contract)`
(Ctrl + X, Y and Enter will do to save)
```Bash
make call-contract project=hello-world
```
##                    ----------THE END--------------

