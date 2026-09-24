# Hybrid Icarus Server Feature Summary

A breakdown of the features in this Hybrid Icarus Dedicated Server project.

---

## 🏗️ Architecture & Infrastructure

* **Hybrid Cloud Hosting**: Runs the CPU- and RAM-heavy Icarus server locally in Docker, and a small traffic gateway on an AWS Lightsail nano instance.
* **IP Masking**: All player traffic and web traffic goes through the Lightsail static IP, so players never see your home IP address.
* **Reverse UDP Tunneling (FRP)**: A token-authenticated Fast Reverse Proxy (FRP) tunnel carries the game port (`17777/udp`) and the Steam query port (`27015/udp`) from the gateway to your home server. It gets around NAT/CGNAT without opening any router ports.
* **Infrastructure as Code (IaC)**: Terraform provisions the Lightsail instance, static IP, firewall rules, 2GB swap file, Docker install and SSH key pair. It also generates the local `frpc.toml` tunnel config.
* **Automated SSL/TLS**: A dockerized Caddy web server issues HTTPS certificates automatically for your DuckDNS domain.
* **DuckDNS Integration**: A free DuckDNS subdomain gives players a memorable address. Terraform points it at the gateway's static IP during provisioning.

---

## 🌐 Web Status Page

* **Live Server Status**: A public HTTPS page shows the gateway tunnel status, the game server status (from a Steam A2S query) and the current server version, refreshing every 30 seconds.
* **Patch Notes Link**: The server version links to its SteamDB patch notes.
* **Player Connection Guide**: The page walks players through adding the server to their Steam favourites and joining from Icarus.
* **FRP Management Dashboard**: A password-protected FRP dashboard, served over HTTPS on `:7500` and at `/dashboard/`, shows tunnel and proxy state.

---

## 🎮 Game Server & Data Management

* **Env-Based Configuration**: All server settings live in a git-ignored `local/.env`: name, passwords, max players, lobby timeouts, admin rules, Steam branch, update and cleanup schedules.
* **Prospect Migration & Loading**: You can move a local world to the dedicated server and load it with `make load-prospect`. `ResumeProspect` then keeps it loaded across restarts.
* **Scheduled Updates & Cleanup**: You can set cron schedules for game updates and for pruning old prospects.
* **Stuck Update Recovery**: A pre-update hook detects and resets SteamCMD's stuck update state (`0x6`) automatically. `make local-fix-update` does the same by hand.
* **Encrypted Automated Backups**: A Restic container backs up the world data every 4 hours and keeps 7 daily and 4 weekly snapshots, with documented restore steps.
* **Resource Safety**: The game container has a configurable memory limit, a 2-minute graceful shutdown window for saving, and rotated logs.
* **Streamlined CLI Operations**: A Makefile runs common tasks as single commands: deploying and destroying the cloud gateway, starting and stopping the local stack, viewing logs, SSHing into the gateway, querying server status, listing online players and loading prospects (`make help` lists them all).
