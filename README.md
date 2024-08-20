# ritual-node
Guide Ritual Node

0. Register wallet:
https://basescan.org/address/0x8d871ef2826ac9001fb2e33fdd6379b6aabf449c#writeContract

1. Preparations:
```Bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git jq lz4 build-essential screen
```

3. Install Docker & Docker Compose:
```Bash
sudo apt update && sudo apt install apt-transport-https ca-certificates curl software-properties-common -y && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin && sudo apt-get install docker-compose-plugin
```
```Bash
sudo apt install git-all
```
```Bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```
```Bash
sudo apt-get update
```
```Bash
sudo apt-get install ca-certificates curl gnupg lsb-release
```
```Bash
sudo mkdir -m 0755 -p /etc/apt/keyrings
```
```Bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 
echo  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
```Bash
sudo apt-get update
```
```Bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
```Bash
sudo docker run hello-world
```

3. Clone The Starter Repository:
```Bash
git clone https://github.com/ritual-net/infernet-container-starter && cd infernet-container-starter
```

5. Run The hello-world Container:
```Bash
sudo apt install screen
```
```Bash
sudo screen -S ritual
```
```Bash
project=hello-world make deploy-container
```
Exit= Ctrl + A + D
-Check docker
docker container ls

**Change port:
nano ~/infernet-container-starter/deploy/docker-compose.yaml
>>> (4000 > 5000)

**Save wallet_factory address: 0x.......

5. Change The Configuration:
```Bash
rm  ~/infernet-container-starter/deploy/config.json && nano ~/infernet-container-starter/deploy/config.json
```

nano ~/infernet-container-starter/projects/hello-world/container/config.json
>>Change:
"rpc_url": "https://base-rpc.publicnode.com"
"registry_address": "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170"
"private_key": "0x + your wallet's private key"
"image": "ritualnetwork/infernet-node:1.0.0"
"allowed_addresses": "0xF6168876932289D073567f347121A267095f3DD6"


nano ~/infernet-container-starter/projects/hello-world/contracts/Makefile
>>Change:
"sender" = 0x + your wallet's private key
"RPC_URL" to: https://base-rpc.publicnode.com

nano ~/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol
>>Change:
address registry = 0x3B1554f346DFe5c482Bb4BA31b880c1C18412170;
sGM saysGm = new SaysGM(registry);

6. Update version:
nano ~/infernet-container-starter/deploy/docker-compose.yaml
*If=1.0.0 >> OK

cd infernet-container-starter/deploy
docker compose down && docker compose up -d

7. Update containers:
docker restart infernet-anvil
docker restart hello-world
docker restart infernet-node
docker restart deploy-fluentbit-1
docker restart deploy-redis-1

8. install foundery
cd
mkdir foundry && cd foundry
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup

**Remove old data:
cd ~/infernet-container-starter/projects/hello-world/contracts/lib
rm -rf forge-std
rm -rf infernet-sdk

-Run....
cd
cd ~/infernet-container-starter/projects/hello-world/contracts
forge install --no-commit foundry-rs/forge-std
forge install --no-commit ritual-net/infernet-sdk
cd ../../../

9. Deploy contracts:
cd infernet-container-starter && project=hello-world make deploy-contracts

>>Save Deployed SaysHello:  0xcxxxxxx

nano ~/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol

- Chang "Deployed SaysHello" = 0xcxxxxxx
10. Start:
make call-contract project=hello-world

----------THE END----------------------------------

