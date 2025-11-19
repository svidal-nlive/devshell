#!/bin/bash
# DevShell Project Initialization
# Run this to verify and prepare for GitHub push

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          DevShell Project Initialization                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check we're in the right directory
if [ ! -f "Dockerfile" ] || [ ! -f "entrypoint.sh" ]; then
    echo "❌ ERROR: Run this script from the devshell project directory"
    exit 1
fi

echo "📁 Project directory: $(pwd)"
echo ""

# Verify all required files exist
echo "🔍 Verifying project files..."
REQUIRED_FILES=(
    "Dockerfile"
    "entrypoint.sh"
    "docker-compose.yml"
    ".github/workflows/build-and-push.yml"
    "README.md"
    "DEPLOYMENT.md"
    "QUICKSTART.md"
    ".env.example"
    ".gitignore"
)

ALL_PRESENT=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ Missing: $file"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    echo ""
    echo "❌ Some required files are missing!"
    exit 1
fi

echo ""
echo "✅ All required files present"
echo ""

# Check git status
if [ ! -d ".git" ]; then
    echo "📦 Git repository not initialized"
    read -p "Initialize git repository? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git init
        echo "✅ Git initialized"
    else
        echo "⏭️  Skipping git initialization"
    fi
else
    echo "✅ Git repository already initialized"
fi

echo ""

# Check for GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME
if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ GitHub username is required"
    exit 1
fi

echo ""
echo "🔧 Configuration Summary"
echo "────────────────────────────────────────────────────────────"
echo "GitHub Username: $GITHUB_USERNAME"
echo "Repository: https://github.com/$GITHUB_USERNAME/devshell"
echo "Image: ghcr.io/$GITHUB_USERNAME/devshell:latest"
echo ""

# Provide next steps
echo "📋 Next Steps:"
echo "────────────────────────────────────────────────────────────"
echo ""
echo "1️⃣  Create GitHub repository:"
echo "   • Go to: https://github.com/new"
echo "   • Repository name: devshell"
echo "   • Visibility: Public (or Private with GHCR auth)"
echo "   • Don't initialize with README"
echo ""
echo "2️⃣  Add and commit files:"
echo "   git add ."
echo "   git commit -m \"Initial devshell setup\""
echo ""
echo "3️⃣  Add remote and push:"
echo "   git remote add origin https://github.com/$GITHUB_USERNAME/devshell.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "4️⃣  Monitor GitHub Actions:"
echo "   https://github.com/$GITHUB_USERNAME/devshell/actions"
echo "   (Wait 3-5 min for build to complete)"
echo ""
echo "5️⃣  Deploy to NAS:"
echo "   Read: QUICKSTART.md (fast) or DEPLOYMENT.md (detailed)"
echo ""
echo "────────────────────────────────────────────────────────────"
echo ""

# Offer to create a reminder file
read -p "Create deployment-notes.txt with your configuration? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat > deployment-notes.txt <<EOF
# DevShell Deployment Notes
# Created: $(date)

## Configuration
GitHub Username: $GITHUB_USERNAME
Repository: https://github.com/$GITHUB_USERNAME/devshell
Image: ghcr.io/$GITHUB_USERNAME/devshell:latest

## NAS Details
NAS Host: ngaged.synology.me:54321
NAS IP: 192.168.0.164
Stack Path: /volume1/docker/stacks/devshell

## Required Environment Variables (for NAS .env)
USERNAME=msn0624c
USER_UID=1026
USER_GID=100
ADMIN_GID=101
DOCKER_GID=<get from: stat -c %g /var/run/docker.sock>
GITHUB_USERNAME=$GITHUB_USERNAME

## Access Methods
LAN: ssh -p 2222 msn0624c@192.168.0.164
External: ssh msn0624c@devshell.nsystems.live (requires DNS + port forwarding)

## Quick Commands
# On NAS:
cd /volume1/docker/stacks/devshell
/usr/local/bin/docker compose pull
/usr/local/bin/docker compose up -d
/usr/local/bin/docker compose logs -f

# Update:
git push  # On local machine
docker compose pull && docker compose up -d  # On NAS
EOF
    echo "✅ Created deployment-notes.txt"
    echo "   (This file is in .gitignore - safe for local use)"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✨ DevShell project is ready!                            ║"
echo "║  📖 Read QUICKSTART.md for fast deployment                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
