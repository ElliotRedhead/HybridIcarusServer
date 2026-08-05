TF_DIR := cloud
KEY_FILE := $(TF_DIR)/id_rsa.pem
SSH_USER := ubuntu
GET_IP = $(shell cd $(TF_DIR) && terraform output -raw public_ip)

# --- Cloud Targets ---

.PHONY: cloud-ip
cloud-ip: ## Output the public IP of the Lightsail instance
	@echo "$(GET_IP)"

.PHONY: cloud-ssh
cloud-ssh: ## SSH into the Lightsail instance
	@echo "Connecting to $(GET_IP)..."
	ssh -i $(KEY_FILE) $(SSH_USER)@$(GET_IP)

.PHONY: cloud-deploy
cloud-deploy: ## Apply Terraform changes (Auto-Approve)
	cd $(TF_DIR) && terraform init && terraform apply -auto-approve

.PHONY: cloud-destroy
cloud-destroy: ## Destroy the cloud infrastructure
	cd $(TF_DIR) && terraform destroy -auto-approve

# --- Local Server Targets ---

.PHONY: local-up
local-up: ## Start local Icarus server, Backup & Tunnel
	cd local && docker compose up -d

.PHONY: local-down
local-down: ## Stop local servers
	cd local && docker compose down

.PHONY: local-logs
local-logs: ## View logs for the Icarus server
	cd local && docker compose logs -f icarus

.PHONY: frpc-logs
frpc-logs: ## View logs for the local FRP client
	cd local && docker compose logs -f frpc

.PHONY: backup-logs
backup-logs: ## View logs for the backup container
	cd local && docker compose logs -f backup

# --- Utilities ---

.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z_-]+:.*## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort
