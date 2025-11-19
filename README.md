# DevShell - Ubuntu 24.04 Development Container

A clean, isolated Ubuntu 24.04 development environment with SSH access, Docker CLI, and Docker Compose v2 integration for Synology NAS.

## Features

- **Ubuntu 24.04 LTS** base image
- **SSH-only authentication** (no passwords)
- **Docker CLI + Compose v2** with host socket passthrough
- **User identity mirroring** (UID/GID matching Synology user)
- **GitHub Actions CI/CD** for automated builds
- **GHCR image distribution** (no local builds needed)

## Architecture

The devshell runs on your Synology NAS but is built externally via GitHub Actions to avoid CPU/resource constraints on the DS220+.

### Build & Deployment Flow

```
GitHub Push → Actions Build → GHCR Push → NAS Pull → Container Start
```

## Prerequisites

### On GitHub

1. Fork or create this repository
2. Enable GitHub Actions
3. GitHub Container Registry is automatically available with `GITHUB_TOKEN`

### On Synology NAS

1. Get Docker socket GID:
   ```bash
   stat -c %g /var/run/docker.sock
   ```

2. Create SSH keys directory:
   ```bash
   mkdir -p /volume1/docker/stacks/devshell/ssh
   ```

3. Add your public SSH key:
   ```bash
   cat ~/.ssh/id_ed25519.pub >> /volume1/docker/stacks/devshell/ssh/authorized_keys
   chmod 600 /volume1/docker/stacks/devshell/ssh/authorized_keys
   ```

## Deployment on NAS

### 1. Create Stack Directory

```bash
ssh msn0624c@ngaged.synology.me -p 54321
cd /volume1/docker/stacks
mkdir -p devshell/ssh
cd devshell
```

### 2. Copy docker-compose.yml

Use the provided `docker-compose.yml` file from this repository.

### 3. Create .env File

```bash
nano .env
```

Add:
```env
USERNAME=msn0624c
USER_UID=1026
USER_GID=100
ADMIN_GID=101
DOCKER_GID=999  # Use the value from stat command above
GITHUB_USERNAME=YOUR_GITHUB_USERNAME
```

### 4. Deploy

```bash
# Pull latest image from GHCR
docker compose pull

# Start container
docker compose up -d

# Check logs
docker compose logs -f
```

## DNS Configuration

Set up DNS record for external access:

- **Type**: A record
- **Name**: `devshell.nsystems.live`
- **Value**: Your WAN IP
- **Proxy**: OFF (DNS only)

## Router Configuration

Forward external port 22 to NAS internal port 2222:

- **External**: Port 22
- **Internal**: Port 2222 → 192.168.0.164

## Access Methods

### External (Public)

```bash
ssh msn0624c@devshell.nsystems.live
```

### Internal (LAN)

```bash
ssh -p 2222 msn0624c@192.168.0.164
```

### VS Code Remote-SSH

Add to `~/.ssh/config`:

```
Host devshell
  HostName devshell.nsystems.live
  User msn0624c
  Port 22

Host devshell-lan
  HostName 192.168.0.164
  User msn0624c
  Port 2222
```

## Updating

When you push changes to the GitHub repository:

1. GitHub Actions automatically builds new image
2. Image is pushed to GHCR with `:latest` and `:sha-xxxxx` tags
3. On NAS, pull and restart:

```bash
cd /volume1/docker/stacks/devshell
docker compose pull
docker compose up -d
```

## Troubleshooting

### Check container logs
```bash
docker compose logs devshell
```

### Verify Docker socket access
```bash
docker exec devshell docker ps
```

### Check SSH configuration
```bash
docker exec devshell cat /etc/ssh/sshd_config
```

### Verify user permissions
```bash
docker exec devshell id msn0624c
docker exec devshell groups msn0624c
```

### Test SSH key
```bash
docker exec devshell ls -la /home/msn0624c/.ssh/
```

## Security Notes

- **No password authentication** - SSH keys only
- **No root login** - Root SSH access disabled
- **Passwordless sudo** - User has sudo without password (trust-based)
- **Docker socket access** - User can control host Docker (intentional for dev environment)

## Directory Structure

```
devshell/
├── .github/
│   └── workflows/
│       └── build-and-push.yml    # CI/CD workflow
├── Dockerfile                     # Container image definition
├── entrypoint.sh                  # Runtime configuration script
├── docker-compose.yml             # NAS deployment configuration
├── .env.example                   # Environment variables template
└── README.md                      # This file

# On NAS:
/volume1/docker/stacks/devshell/
├── docker-compose.yml
├── .env
└── ssh/
    └── authorized_keys            # Your SSH public keys
```

## License

MIT
