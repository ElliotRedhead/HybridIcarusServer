# Hybrid Icarus Dedicated Server

This project deploys a secure Icarus dedicated server using a Hybrid Cloud Architecture.

- **Game Server**: Runs locally, dockerized on your hardware, utilizing your CPU and RAM.
- **Gateway**: Runs on a cheap AWS Lightsail instance (provisioned with Terraform).
- **Tunnel**: UDP Traffic is securely tunneled via FRP from the Cloud to your local server.
- **Web Dashboard**: Serves a secure HTTPS server status page to easily check if the game is online.

## Prerequisites
- Terraform installed
- Docker & Docker Compose installed locally
- DuckDNS Account & Token
- AWS Account with Lightsail permissions

## Quick Setup
1. Copy `cloud/terraform.tfvars.template` to `cloud/terraform.tfvars` and fill it in.
2. Run `make cloud-deploy` to provision the AWS infrastructure.
3. Copy `local/.env.template` to `local/.env` and configure your Icarus server name/passwords.
4. Run `make local-up` to start the Icarus game server, the FRP tunnel client, and the automated backup container.

Players can connect via the domain name you set up, using port `17777`.
Visit `https://yourdomain.duckdns.org` in a browser to view the server status.
