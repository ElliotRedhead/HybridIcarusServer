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

## Migrating a Local World to the Server

If you have been playing locally with friends and want to move your progress to this dedicated server, follow these steps:

1. **Start the server once** by running `make local-up` to ensure the folder structure is generated, then stop it via `make local-down`.
2. On your gaming PC, press **Win + R**, paste `%LocalAppData%\Icarus\Saved\PlayerData`, and hit Enter.
3. Open the folder named after your SteamID64, then open the `Prospects` folder. Locate the `.json` file of the world you want to transfer.
4. Copy this `.json` file to the equivalent folder on your server machine: 
   `local/data/Saved/PlayerData/DedicatedServer/Prospects/` (create the folders if they don't exist).
5. In your `local/data/Saved/Config/WindowsServer/ServerSettings.ini` file, set the following options to match your save name (without the `.json` extension):
   ```ini
   LoadProspect=YourSaveFileName
   ResumeProspect=True
   ```
6. Start the server again using `make local-up`. Your friends will now connect to the shared world!

*Note: Character progression (level, talents, unlocks) is stored locally on each player's PC. This means your progression stays with you seamlessly when moving between local play and the dedicated server!*
