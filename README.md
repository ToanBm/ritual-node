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
## 5. Node Configuration:
### - container/config.json
```Bash
rm ~/infernet-container-starter/projects/hello-world/container/config.json && nano ~/infernet-container-starter/projects/hello-world/container/config.json
```
Edit file `config.json` with `your-private-key (include prefix 0x)` as in the code below. 
(Ctrl + X, Y and Enter will do to save)
```Bash
{
    "log_path": "infernet_node.log",
    "server": {
        "port": 4000,
        "rate_limit": {
            "num_requests": 100,
            "period": 100
        }
    },
    "chain": {
        "enabled": true,
        "trail_head_blocks": 3,
        "rpc_url": "https://mainnet.base.org/",
        "registry_address": "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170",
        "wallet": {
            "max_gas_limit": 4000000,
            "private_key": "0x+<your-private-key>",
            "allowed_sim_errors": []
        },
        "snapshot_sync": {
            "sleep": 3,
            "batch_size": 1800,
            "starting_sub_id": 0
        }
    },
    "startup_wait": 1.0,
    "docker": {
        "username": "your-username",
        "password": ""
    },
    "redis": {
        "host": "redis",
        "port": 6379
    },
    "forward_stats": true,
    "containers": [
        {
            "id": "hello-world",
            "image": "ritualnetwork/hello-world-infernet:latest",
            "external": true,
            "port": "3000",
            "allowed_delegate_addresses": [],
            "allowed_addresses": [],
            "allowed_ips": [],
            "command": "--bind=0.0.0.0:3000 --workers=2",
            "env": {},
            "volumes": [],
            "accepted_payments": {},
            "generates_proofs": false
        }
    ]
}
```
### - contracts/script/Deploy.s.sol
```Bash
rm ~/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol && nano ~/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol
```
Edit file `Deploy.s.sol` as in the code below. 
(Ctrl + X, Y and Enter will do to save)
```Bash
// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SaysGM} from "../src/SaysGM.sol";

contract Deploy is Script {
    function run() public {
        // Setup wallet
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Log address
        address deployerAddress = vm.addr(deployerPrivateKey);
        console2.log("Loaded deployer: ", deployerAddress);

        address registry = 0x3B1554f346DFe5c482Bb4BA31b880c1C18412170;
        // Create consumer
        SaysGM saysGm = new SaysGM(registry);
        console2.log("Deployed SaysHello: ", address(saysGm));

        // Execute
        vm.stopBroadcast();
        vm.broadcast();
    }
}
```
### - contracts/Makefile
```Bash
rm ~/infernet-container-starter/projects/hello-world/contracts/Makefile && nano ~/infernet-container-starter/projects/hello-world/contracts/Makefile
```
Edit file `Makefile` with `your-private-key (include prefix 0x)` as in the code below. 
(Ctrl + X, Y and Enter will do to save)
```Bash
# phony targets are targets that don't actually create a file
.phony: deploy

# anvil's third default address
sender := 0x+<your-private-key>
RPC_URL := https://mainnet.base.org/

# deploying the contract
deploy:
	@PRIVATE_KEY=$(sender) forge script script/Deploy.s.sol:Deploy --broadcast --rpc-url $(RPC_URL)

# calling sayGM()
call-contract:
	@PRIVATE_KEY=$(sender) forge script script/CallContract.s.sol:CallContract --broadcast --rpc-url $(RPC_URL)
```
### - docker-compose.yaml
```Bash
rm ~/infernet-container-starter/deploy/docker-compose.yaml && nano ~/infernet-container-starter/deploy/docker-compose.yaml
```
Edit file `docker-compose.yaml` with `as in the code below.
(Ctrl + X, Y and Enter will do to save)
```Bash
services:
  node:
    image: ritualnetwork/infernet-node:1.2.0
    ports:
      - "0.0.0.0:4000:4000"
    volumes:
      - ./config.json:/app/config.json
      - node-logs:/logs
      - /var/run/docker.sock:/var/run/docker.sock
    tty: true
    networks:
      - network
    depends_on:
      - redis
      - infernet-anvil
    restart:
      on-failure
    extra_hosts:
      - "host.docker.internal:host-gateway"
    stop_grace_period: 1m
    container_name: infernet-node

  redis:
    image: redis:7.4.0
    ports:
    - "6379:6379"
    networks:
      - network
    volumes:
      - ./redis.conf:/usr/local/etc/redis/redis.conf
      - redis-data:/data
    restart:
      on-failure

  fluentbit:
    image: fluent/fluent-bit:3.1.4
    expose:
      - "24224"
    environment:
      - FLUENTBIT_CONFIG_PATH=/fluent-bit/etc/fluent-bit.conf
    volumes:
      - ./fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf
      - /var/log:/var/log:ro
    networks:
      - network
    restart:
      on-failure

  infernet-anvil:
    image: ritualnetwork/infernet-anvil:1.0.0
    command: --host 0.0.0.0 --port 3000 --load-state infernet_deployed.json -b 1
    ports:
      - "8545:3000"
    networks:
      - network
    container_name: infernet-anvil

networks:
  network:

volumes:
  node-logs:
  redis-data:
```
## 6. Running hello-world:
```Bash
screen -S ritual
```
```Bash
project=hello-world make deploy-container
```
Detach from your session with:: CTRL + A + D
## 7. Docker containers:
```Bash
docker container ls
```
## 8. Initialize Configuration:
### - Restart node:
```Bash
docker compose -f deploy/docker-compose.yaml down && docker compose -f deploy/docker-compose.yaml up -d
```
### - Check log:
```Bash
docker ps
```
```Bash
docker logs -f infernet-anvil
```
```Bash
docker logs -f hello-world
```
```Bash
docker logs -f infernet-node
```
```Bash
docker logs -f deploy-fluentbit-1
```
```Bash
docker logs -f deploy-redis-1
```
### Ctrl + C to exit log.
## 9. Install Foundry:
```Bash
cd
mkdir foundry && cd foundry
curl -L https://foundry.paradigm.xyz | bash
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

