# HybridMCServer Feature Summary

A comprehensive breakdown of the features enabled by [HybridMCServer](https://github.com/ElliotRedhead/HybridMCServer).

---

## 🏗️ Architecture & Infrastructure

* **Hybrid Cloud Hosting**: Offloads heavy Minecraft server compute and RAM workloads to local home hardware (via Docker) while deploying a lightweight traffic gateway on AWS Lightsail.
* **IP Masking & DDoS Shielding**: Protects your home network by routing all player connections and web traffic through AWS Lightsail, hiding your home IP address from external users.
* **Secure Reverse Tunneling (FRP)**: Establishes an encrypted Fast Reverse Proxy (FRP) connection between the AWS gateway and home server, bypassing home NAT/CGNAT without requiring open incoming router ports.
* **Infrastructure as Code (IaC)**: Fully automates cloud infrastructure provisioning (AWS Lightsail instance, static IP, firewall rules, swap memory setup, and SSH key generation) using Terraform.
* **Automated SSL/TLS Encryption**: Features zero-config automatic SSL certificate issuance and HTTPS routing via a dockerized Caddy web server.
* **Dynamic DNS Updates**: Integrates DuckDNS to dynamically sync IP updates across cloud and home containers.

---

## 🌐 Web Frontend & Player Onboarding

* **Live Server Status Dashboard**: Renders a public HTTPS web page showing real-time health for the host hardware, FRP tunnel, and game server, alongside active online player lists.
* **Automated Modpack Distribution**: Automatically fetches CurseForge base modpacks, injects custom client `.jar` mods and configs, packages them into a `.zip` archive (`build-modpack.sh`), and serves the download directly on the HTTPS status page for one-click import into CurseForge.
* **CurseForge Modpack Auto-Syncing**: Automatically queries CurseForge APIs to install server modpacks and syncs active modpack names and version numbers (`modpack.json`) to the web status interface.
* **FRP Management Dashboard**: Provides a password-protected, SSL-proxied tunnel dashboard (`:7500`) to monitor network connection state, active proxies, and traffic statistics.

---

## 🎮 Game Server & Data Management

* **Split Configuration System**: Separates public game settings (`minecraft-public.env`) from sensitive secrets, whitelists, ops, and credentials (`minecraft-private.env`) to prevent exposing private data in Git repositories.
* **Automated & Manual World Backups**: Features automated hourly Restic backups via `mc-backup`, as well as pre-update backup scripts with progress bar indicators (`pv`) triggered via RCON save commands.
* **Player Playtime Statistics**: Provides a custom utility command (`make mc-playtime`) that parses local Minecraft statistics files and queries the Mojang API to calculate and display total played hours per player.
* **Java 21 & Garbage Collector Tuning**: Includes pre-configured G1GC JVM options optimized for large modpack performance and reduced lag spikes.
* **Streamlined CLI Operations**: Includes a comprehensive Makefile for single-command operations, including checking online players, backing up worlds, upgrading server images, monitoring container logs, and SSHing into the cloud gateway.
