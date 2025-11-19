# DevShell Quick Start

## 🚀 Fast Track Setup (5 Minutes)

### Prerequisites
- GitHub account
- SSH key pair (`~/.ssh/id_ed25519.pub`)
- Access to Synology NAS via SSH

---

## Step 1: GitHub (2 min)

```bash
# Navigate to project
cd ~/docker/projects/devshell

# Initialize git
git init
git add .
git commit -m "Initial devshell"

# Create repo on GitHub (via web):
# https://github.com/new → Repository name: "devshell" → Create

# Push
git remote add origin https://github.com/YOUR_USERNAME/devshell.git
git branch -M main
git push -u origin main
```

**Wait for Actions build** (check GitHub → Actions tab, ~3-5 min)

---

## Step 2: NAS Setup (2 min)

```bash
# SSH to NAS
ssh msn0624c@ngaged.synology.me -p 54321

# Get Docker GID
DOCKER_GID=$(stat -c %g /var/run/docker.sock)
echo "Docker GID: $DOCKER_GID"

# Create stack
mkdir -p /volume1/docker/stacks/devshell/ssh
cd /volume1/docker/stacks/devshell

# Create .env (replace YOUR_USERNAME and use your DOCKER_GID)
cat > .env <<'EOF'
USERNAME=msn0624c
USER_UID=1026
USER_GID=100
ADMIN_GID=101
DOCKER_GID=999
GITHUB_USERNAME=YOUR_USERNAME
EOF

# Edit .env to fix values
nano .env  # Update DOCKER_GID and GITHUB_USERNAME
```

---

## Step 3: Copy Files to NAS (1 min)

```bash
# From your LOCAL machine in ~/docker/projects/devshell/
scp -P 54321 docker-compose.yml msn0624c@ngaged.synology.me:/volume1/docker/stacks/devshell/

# Add your SSH key
cat ~/.ssh/id_ed25519.pub | ssh msn0624c@ngaged.synology.me -p 54321 \
  "cat >> /volume1/docker/stacks/devshell/ssh/authorized_keys && chmod 600 /volume1/docker/stacks/devshell/ssh/authorized_keys"
```

---

## Step 4: Deploy (30 sec)

```bash
# SSH to NAS
ssh msn0624c@ngaged.synology.me -p 54321

# Deploy
cd /volume1/docker/stacks/devshell
/usr/local/bin/docker compose pull
/usr/local/bin/docker compose up -d

# Check
/usr/local/bin/docker compose logs -f
```

---

## Step 5: Connect (10 sec)

```bash
# Test LAN
ssh -p 2222 msn0624c@192.168.0.164

# Inside container, test Docker
docker ps
docker compose version
```

---

## Optional: External Access

### DNS (Cloudflare)
- A record: `devshell.nsystems.live` → Your WAN IP
- Proxy: OFF

### Router
- Forward: External 22 → 192.168.0.164:2222

### Test
```bash
ssh msn0624c@devshell.nsystems.live
```

---

## VS Code Remote-SSH

Add to `~/.ssh/config`:

```
Host devshell
  HostName devshell.nsystems.live
  User msn0624c
```

Then: VS Code → Remote-SSH → Connect to Host → devshell

---

## Done! 🎉

Your Ubuntu 24.04 devshell is running with:
- ✅ SSH key-only auth
- ✅ Docker CLI + Compose v2
- ✅ Host Docker socket access
- ✅ Auto-updates via GHCR
- ✅ Synology user identity mirroring

Update anytime:
```bash
git push  # GitHub Actions builds automatically
# Then on NAS:
docker compose pull && docker compose up -d
```
