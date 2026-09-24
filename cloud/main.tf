terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "tls_private_key" "vpn_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_lightsail_key_pair" "vpn_key_pair" {
  name       = "icarus-vpn-key"
  public_key = tls_private_key.vpn_key.public_key_openssh
}

resource "local_file" "ssh_key" {
  content         = tls_private_key.vpn_key.private_key_pem
  filename        = "${path.module}/id_rsa.pem"
  file_permission = "0600"
}

resource "aws_lightsail_instance" "vpn_proxy" {
  name              = "icarus-vpn-proxy"
  availability_zone = var.availability_zone
  blueprint_id      = "ubuntu_22_04"
  bundle_id         = "nano_3_0" # 512MB RAM instance
  key_pair_name     = aws_lightsail_key_pair.vpn_key_pair.name
}

resource "null_resource" "server_setup" {
  depends_on = [
    aws_lightsail_instance.vpn_proxy,
    aws_lightsail_static_ip_attachment.attach,
    aws_lightsail_instance_public_ports.firewall
  ]

  triggers = {
    instance_id = aws_lightsail_instance.vpn_proxy.id
    index_hash  = filemd5("${path.module}/index.html.tpl")
    caddy_hash  = filemd5("${path.module}/Caddyfile.tpl")
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = aws_lightsail_static_ip.vpn_static_ip.ip_address
    private_key = tls_private_key.vpn_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/index.html.tpl", { duckdns_domain = var.duckdns_domain })
    destination = "/home/ubuntu/index.html"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/Caddyfile.tpl", { duckdns_domain = var.duckdns_domain })
    destination = "/home/ubuntu/Caddyfile"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "cloud-init status --wait",
      "if [ ! -f '/swapfile' ]; then sudo dd if='/dev/zero' of='/swapfile' bs=1M count=2048 status=progress && sudo chmod 600 '/swapfile' && sudo mkswap '/swapfile' && sudo swapon '/swapfile' && echo '/swapfile swap swap defaults 0 0' | sudo tee -a '/etc/fstab'; fi",
      "if ! command -v docker > /dev/null 2>&1; then curl -fsSL 'https://get.docker.com' -o get-docker.sh && sudo sh get-docker.sh && sudo usermod -aG docker ubuntu; fi",
      "sudo mkdir -p /etc/frp /opt/icarus-status /opt/caddy/data /opt/caddy/config",

      # Write FRPS Config for UDP tunneling
      <<-EOF
      sudo tee /etc/frp/frps.toml << "FRPS"
      bindPort = 7000
      auth.method = "token"
      auth.token = "${var.auth_token}"

      [webServer]
      addr = "127.0.0.1"
      port = 7501
      user = "${var.frp_dashboard_creds.user}"
      password = "${var.frp_dashboard_creds.pwd}"
      FRPS
      EOF
      ,

      "[ -f '/home/ubuntu/index.html' ] && sudo mv '/home/ubuntu/index.html' '/opt/icarus-status/index.html'",
      "[ -f '/home/ubuntu/Caddyfile' ] && sudo mv '/home/ubuntu/Caddyfile' '/opt/caddy/Caddyfile'",

      "sudo docker rm -f status-web frps duckdns 2>/dev/null || true",

      "sudo docker run -d --name status-web --restart always --network host -v '/opt/icarus-status:/usr/share/caddy:ro' -v '/opt/caddy/Caddyfile:/etc/caddy/Caddyfile:ro' -v '/opt/caddy/data:/data' -v '/opt/caddy/config:/config' caddy:alpine",
      "sleep 3",

      "sudo docker run -d --name frps --restart always --network host -v '/etc/frp/frps.toml:/etc/frp/frps.toml' snowdreamtech/frps",
      "sleep 3",

      "sudo docker run -d --name duckdns --restart always --network host -e SUBDOMAINS='${var.duckdns_domain}' -e TOKEN='${var.duckdns_token}' lscr.io/linuxserver/duckdns:latest",
      "sleep 3",

      # Setup Healthcheck Script
      <<-EOF
      sudo tee "/usr/local/bin/healthcheck.sh" << "HEALTHCHECK"
      #!/bin/bash
      
      # 1. Check Gateway Tunnel (FRP Connection)
      FRP_RES=$(curl -s -u "${var.frp_dashboard_creds.user}:${var.frp_dashboard_creds.pwd}" "http://127.0.0.1:7501/api/proxy/udp/icarus-game")

      if echo "$FRP_RES" | grep -q "\"status\":\"online\""; then
          GATEWAY="online"
      else
          GATEWAY="offline"
      fi

      # 2. Check Game Server (Steam Query Port 27015)
      if python3 -c 'import socket
try:
    s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(2)
    s.sendto(bytes.fromhex("FFFFFFFF54536F7572636520456E67696E6520517565727900"), ("127.0.0.1", 27015))
    d, _ = s.recvfrom(1024)
    if d.startswith(bytes.fromhex("FFFFFFFF")):
        exit(0)
except Exception:
    pass
exit(1)'; then
          SERVER="online"
      else
          SERVER="offline"
      fi

      VERSION=$(curl -sf --max-time 2 http://127.0.0.1:7502 || echo "Unknown")
      if [ -z "$VERSION" ]; then VERSION="Unknown"; fi

      echo "{\"gateway\": \"$GATEWAY\", \"server\": \"$SERVER\", \"version\": \"$VERSION\"}" > "/opt/icarus-status/health.json"
      chmod 644 "/opt/icarus-status/health.json"
HEALTHCHECK
      EOF
      ,
      "sudo chmod +x '/usr/local/bin/healthcheck.sh'",
      "echo '* * * * * root /usr/local/bin/healthcheck.sh' | sudo tee '/etc/cron.d/icarus-healthcheck'",
      "sudo systemctl restart cron",
      "sudo /usr/local/bin/healthcheck.sh"
    ]
  }
}

resource "aws_lightsail_static_ip" "vpn_static_ip" {
  name = "icarus-static-ip"
}

resource "aws_lightsail_static_ip_attachment" "attach" {
  static_ip_name = aws_lightsail_static_ip.vpn_static_ip.name
  instance_name  = aws_lightsail_instance.vpn_proxy.name

  lifecycle {
    replace_triggered_by = [
      aws_lightsail_instance.vpn_proxy
    ]
  }
}

resource "aws_lightsail_instance_public_ports" "firewall" {
  instance_name = aws_lightsail_instance.vpn_proxy.name

  depends_on = [aws_lightsail_static_ip_attachment.attach]

  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
  }

  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
  }

  port_info {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
  }

  port_info {
    protocol  = "tcp"
    from_port = 7000
    to_port   = 7000
  }

  port_info {
    protocol  = "tcp"
    from_port = 7500
    to_port   = 7500
  }

  port_info {
    protocol  = "udp"
    from_port = 17777
    to_port   = 17777
  }

  port_info {
    protocol  = "udp"
    from_port = 27015
    to_port   = 27015
  }
}

output "public_ip" {
  value = aws_lightsail_static_ip.vpn_static_ip.ip_address
}

variable "aws_region" {
  description = "AWS region for the Lightsail gateway (pick one close to your players)"
  type        = string
  default     = "eu-west-2"
}

variable "availability_zone" {
  description = "Lightsail availability zone, must be in aws_region"
  type        = string
  default     = "eu-west-2b"
}

variable "aws_profile" {
  description = "AWS CLI profile to use (null uses the default credential chain)"
  type        = string
  default     = null
}

variable "auth_token" {
  type      = string
  sensitive = true
}

variable "duckdns_token" {
  type      = string
  sensitive = true
}

variable "duckdns_domain" {
  type = string
}

variable "frp_dashboard_creds" {
  description = "FRP Dashboard Login"
  type = object({
    user = string
    pwd  = string
  })
  sensitive = true
}

resource "local_file" "home_config" {
  content = <<-EOF
  serverAddr = "${aws_lightsail_static_ip.vpn_static_ip.ip_address}"
  serverPort = 7000
  auth.method = "token"
  auth.token = "${var.auth_token}"

  [[proxies]]
  name = "icarus-game"
  type = "udp"
  localIP = "icarus"
  localPort = 17777
  remotePort = 17777

  [[proxies]]
  name = "icarus-query"
  type = "udp"
  localIP = "icarus"
  localPort = 27015
  remotePort = 27015

  [[proxies]]
  name = "icarus-version"
  type = "tcp"
  localIP = "version-server"
  localPort = 80
  remotePort = 7502
  EOF

  filename        = "${path.module}/../local/frpc.toml"
  file_permission = "0644"
}
