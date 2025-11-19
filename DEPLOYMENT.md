# DevShell Deployment Guide

## Step-by-Step Deployment to Synology NAS

### Phase 1: GitHub Repository Setup

1. **Create GitHub Repository**
   ```bash
   # On your local machine
   cd ~/docker/projects/devshell
   git init
   git add .
   git commit -m "Initial devshell setup"
   ```

2. **Create Repository on GitHub**
   - Go to https://github.com/new
   - Repository name: `devshell`
   - Visibility: Public or Private (both work with GHCR)
   - Don't initialize with README (we already have one)

3. **Push to GitHub**
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/devshell.git
   git branch -M main
   git push -u origin main
   ```

4. **Verify GitHub Actions**
   - Go to repository → Actions tab
   - Build should start automatically
   - Wait for build to complete (creates image in GHCR)

5. **Configure Package Visibility (if needed)**
   - Go to repository → Packages → devshell
   - Settings → Change visibility to Public (or configure auth for private)

### Phase 2: NAS Preparation

1. **Get Docker Socket GID**
   ```bash
   ssh msn0624c@ngaged.synology.me -p 54321
   stat -c %g /var/run/docker.sock
   # Note this number (typically 999 or 998)
   ```

2. **Create Stack Directory**
   ```bash
   mkdir -p /volume1/docker/stacks/devshell/ssh
   cd /volume1/docker/stacks/devshell
   ```

3. **Add SSH Public Key**
   ```bash
   # From your local machine
   cat ~/.ssh/id_ed25519.pub | ssh msn0624c@ngaged.synology.me -p 54321 \
     "cat >> /volume1/docker/stacks/devshell/ssh/authorized_keys"
   
   # Fix permissions
   ssh msn0624c@ngaged.synology.me -p 54321 \
     "chmod 600 /volume1/docker/stacks/devshell/ssh/authorized_keys"
   ```

### Phase 3: Deploy Stack

1. **Copy docker-compose.yml to NAS**
   ```bash
   # From your local machine in projects/devshell/
   scp -P 54321 docker-compose.yml \
     msn0624c@ngaged.synology.me:/volume1/docker/stacks/devshell/
   ```

2. **Create .env on NAS**
   ```bash
   ssh msn0624c@ngaged.synology.me -p 54321
   cd /volume1/docker/stacks/devshell
   nano .env
   ```
   
   Add:
   ```env
   USERNAME=msn0624c
   USER_UID=1026
   USER_GID=100
   ADMIN_GID=101
   DOCKER_GID=999  # Use value from stat command
   GITHUB_USERNAME=YOUR_GITHUB_USERNAME
   ```

3. **Authenticate to GHCR (if repository is private)**
   ```bash
   # Create a GitHub Personal Access Token with read:packages scope
   # Go to: Settings → Developer settings → Personal access tokens → Tokens (classic)
   # Generate new token with read:packages permission
   
   echo "YOUR_GITHUB_TOKEN" | /usr/local/bin/docker login ghcr.io \
     -u YOUR_GITHUB_USERNAME --password-stdin
   ```

4. **Pull and Start Container**
   ```bash
   cd /volume1/docker/stacks/devshell
   /usr/local/bin/docker compose pull
   /usr/local/bin/docker compose up -d
   ```

5. **Verify Deployment**
   ```bash
   # Check container status
   /usr/local/bin/docker compose ps
   
   # View logs
   /usr/local/bin/docker compose logs -f
   
   # You should see:
   # - User configuration
   # - Docker socket GID alignment
   # - SSH keys configured
   # - sshd started
   ```

### Phase 4: Network Configuration

1. **DNS Setup (Cloudflare)**
   - Type: A
   - Name: devshell
   - Value: Your WAN IP
   - Proxy: OFF (DNS only)
   - TTL: Auto

2. **Router Port Forwarding**
   - External Port: 22
   - Internal IP: 192.168.0.164 (NAS)
   - Internal Port: 2222
   - Protocol: TCP

### Phase 5: Test Access

1. **Test LAN Access**
   ```bash
   ssh -p 2222 msn0624c@192.168.0.164
   ```

2. **Test External Access**
   ```bash
   ssh msn0624c@devshell.nsystems.live
   ```

3. **Verify Docker Access**
   ```bash
   # Once connected via SSH
   docker ps
   docker compose version
   ```

4. **Configure VS Code Remote-SSH**
   
   Edit `~/.ssh/config`:
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
   
   Then in VS Code: Remote-SSH → Connect to Host → devshell

## Updating DevShell

Whenever you push changes to GitHub:

1. **Update Automatically Builds**
   - Push to GitHub triggers Actions
   - New image automatically built and pushed to GHCR

2. **Update on NAS**
   ```bash
   ssh msn0624c@ngaged.synology.me -p 54321
   cd /volume1/docker/stacks/devshell
   /usr/local/bin/docker compose pull
   /usr/local/bin/docker compose up -d
   ```

## Troubleshooting

### Container won't start
```bash
# Check logs
/usr/local/bin/docker compose logs

# Common issues:
# - Wrong DOCKER_GID in .env
# - Missing SSH authorized_keys
# - Permission issues on ssh/ directory
```

### Can't connect via SSH
```bash
# From NAS, test sshd config
/usr/local/bin/docker exec devshell cat /etc/ssh/sshd_config

# Check if sshd is running
/usr/local/bin/docker exec devshell pgrep sshd

# Check authorized_keys
/usr/local/bin/docker exec devshell cat /home/msn0624c/.ssh/authorized_keys
```

### Docker commands don't work inside container
```bash
# Verify docker socket is mounted
/usr/local/bin/docker exec devshell ls -la /var/run/docker.sock

# Verify user is in docker group
/usr/local/bin/docker exec devshell groups msn0624c

# Check docker socket GID matches
stat -c %g /var/run/docker.sock  # On NAS
/usr/local/bin/docker exec devshell stat -c %g /var/run/docker.sock  # In container
```

### Image pull fails (private repo)
```bash
# Login to GHCR
echo "YOUR_PAT" | /usr/local/bin/docker login ghcr.io \
  -u YOUR_USERNAME --password-stdin

# Or make repository package public:
# GitHub → Repository → Packages → devshell → Package settings → Change visibility
```

## Adding More Users

1. **Add SSH Key**
   ```bash
   echo "ssh-ed25519 AAAA... user@host" >> \
     /volume1/docker/stacks/devshell/ssh/authorized_keys
   ```

2. **Restart Container**
   ```bash
   /usr/local/bin/docker compose restart
   ```

All users connect as `msn0624c` but use their own SSH keys for authentication.
