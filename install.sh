#!/bin/bash

# Function to display logo
display_logo() {
  sleep 2
  curl -s https://raw.githubusercontent.com/ToanBm/user-info/main/logo.sh | bash
  sleep 1
}

# Function to display menu
display_menu() {
  clear
  display_logo
  echo "===================================================="
  echo "     RITUAL NETWORK INFERNET AUTO INSTALLER         "
  echo "===================================================="
  echo ""
  echo "Please select an option:"
  echo "1) Install Ritual Network Infernet"
  echo "2) Uninstall Ritual Network Infernet"
  echo "3) Exit"
  echo ""
  echo "===================================================="
  read -p "Enter your choice (1-3): " choice
}

# Function to install Ritual Network Infernet
install_ritual() {
  clear
  display_logo
  echo "===================================================="
  echo "     ?? INSTALLING RITUAL NETWORK INFERNET ??       "
  echo "===================================================="
  echo ""
  
  # Ask for private key with hidden input
  echo "Please enter your private key (with 0x prefix if needed)"
  echo "Note: Input will be hidden for security"
  read -s private_key
  echo "Private key received (hidden for security)"
  
  # Add 0x prefix if missing
  if [[ ! $private_key =~ ^0x ]]; then
    private_key="0x$private_key"
    echo "Added 0x prefix to private key"
  fi
  
  echo "Installing dependencies..."
  
  # Update packages & build tools
  sudo apt update && sudo apt upgrade -y
  sudo apt -qy install curl git jq lz4 build-essential screen
  
  # Install Docker
  echo "Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo docker run hello-world
  
  # Install Docker Compose
  echo "Installing Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  mkdir -p $DOCKER_CONFIG/cli-plugins
  curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
  chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
  docker compose version
  sudo usermod -aG docker $USER
  docker run hello-world
  
  # Clone Repository
  echo "Cloning repository..."
  git clone https://github.com/ritual-net/infernet-container-starter
  cd infernet-container-starter
  
  # Create config files
  echo "Creating configuration files..."
  
  # Create config.json with private key
  cat > ~/infernet-container-starter/deploy/config.json << EOL
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
          "private_key": "${private_key}",
          "allowed_sim_errors": []
        },
        "snapshot_sync": {
          "sleep": 3,
          "batch_size": 10000,
          "starting_sub_id": 180000,
          "sync_period": 30
        }
    },
    "startup_wait": 1.0,
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
EOL

  # Copy config to container folder
  cp ~/infernet-container-starter/deploy/config.json ~/infernet-container-starter/projects/hello-world/container/config.json
  
  # Create Deploy.s.sol
  cat > ~/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol << EOL
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
EOL

  # Create Makefile
  cat > ~/infernet-container-starter/projects/hello-world/contracts/Makefile << EOL
# phony targets are targets that don't actually create a file
.phony: deploy

# anvil's third default address
sender := ${private_key}
RPC_URL := https://mainnet.base.org/

# deploying the contract
deploy:
	@PRIVATE_KEY=\$(sender) forge script script/Deploy.s.sol:Deploy --broadcast --rpc-url \$(RPC_URL)

# calling sayGM()
call-contract:
	@PRIVATE_KEY=\$(sender) forge script script/CallContract.s.sol:CallContract --broadcast --rpc-url \$(RPC_URL)
EOL

  # Edit node version in docker-compose.yaml
  sed -i 's/infernet-node:.*/infernet-node:1.4.0/g' ~/infernet-container-starter/deploy/docker-compose.yaml
  
  # Deploy container using systemd instead of screen
  echo "Creating systemd service for Ritual Network..."
  cd ~/infernet-container-starter
  
  # Create a script to be run by systemd
  cat > ~/ritual-service.sh << EOL
#!/bin/bash
cd ~/infernet-container-starter
echo "Starting container deployment at \$(date)" > ~/ritual-deployment.log
project=hello-world make deploy-container >> ~/ritual-deployment.log 2>&1
echo "Container deployment completed at \$(date)" >> ~/ritual-deployment.log

# Keep containers running
cd ~/infernet-container-starter
while true; do
  echo "Checking containers at \$(date)" >> ~/ritual-deployment.log
  if ! docker ps | grep -q "infernet"; then
    echo "Containers stopped. Restarting at \$(date)" >> ~/ritual-deployment.log
    docker compose -f deploy/docker-compose.yaml up -d >> ~/ritual-deployment.log 2>&1
  else
    echo "Containers running normally at \$(date)" >> ~/ritual-deployment.log
  fi
  sleep 300
done
EOL
  
  chmod +x ~/ritual-service.sh
  
  # Create systemd service file
  sudo tee /etc/systemd/system/ritual-network.service > /dev/null << EOL
[Unit]
Description=Ritual Network Infernet Service
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
ExecStart=/bin/bash /root/ritual-service.sh
Restart=always
RestartSec=30
StandardOutput=append:/root/ritual-service.log
StandardError=append:/root/ritual-service.log

[Install]
WantedBy=multi-user.target
EOL

  # Reload systemd, enable and start service
  sudo systemctl daemon-reload
  sudo systemctl enable ritual-network.service
  sudo systemctl start ritual-network.service
  
  # Verify service is running
  sleep 5
  if sudo systemctl is-active --quiet ritual-network.service; then
    echo "? Ritual Network service started successfully!"
  else
    echo "?? Warning: Service might not have started correctly. Checking status..."
    sudo systemctl status ritual-network.service
  fi
  
  echo "Service logs are being saved to ~/ritual-deployment.log"
  echo "You can check service status with: sudo systemctl status ritual-network.service"
  echo "Continuing with installation..."
  echo ""
  
  # Wait a bit for deployment to start
  echo "Waiting for deployment to initialize..."
  sleep 10
  
  # Check service status again
  echo "Verifying service status..."
  if sudo systemctl is-active --quiet ritual-network.service; then
    echo "? Ritual Network service is running properly."
  else
    echo "?? Service not running correctly. Attempting to restart..."
    sudo systemctl restart ritual-network.service
    sleep 5
    sudo systemctl status ritual-network.service
  fi
  
  # Start containers
  echo "Starting containers..."
  docker compose -f deploy/docker-compose.yaml up -d
}

# Main program
main() {
  while true; do
    display_menu
    
    case $choice in
      1)
        install_ritual
        ;;
      2)
        uninstall_ritual
        ;;
      3)
        clear
        display_logo
        echo "Thank you for using the Ritual Network Infernet Auto Installer!"
        echo "Exiting..."
        exit 0
        ;;
      *)
        echo "Invalid option. Press any key to try again..."
        read -n 1
        ;;
    esac
  done
}

# Run the main program
main
