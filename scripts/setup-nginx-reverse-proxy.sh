#!/bin/bash

# Exit on error
set -e

# Get the internal Minikube IP and NodePort
MINIKUBE_IP=$(minikube ip)
NODE_PORT=30080
TARGET="$MINIKUBE_IP:$NODE_PORT"

echo "🔍 Detected Minikube service at: $TARGET"

# Install nginx if not present
if ! command -v nginx &> /dev/null; then
  echo "📦 Installing nginx..."
  sudo apt update
  sudo apt install -y nginx
else
  echo "✅ Nginx is already installed."
fi

# Backup old config
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# Write new reverse proxy config
echo "📝 Updating nginx config to proxy to $TARGET"
sudo bash -c "cat > /etc/nginx/sites-available/default" <<EOF
server {
    listen 80;

    location / {
        proxy_pass http://$TARGET;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Test and restart nginx
echo "🧪 Testing nginx configuration..."
if sudo nginx -t; then
  echo "✅ Config test passed. Restarting nginx..."
  sudo systemctl restart nginx
  echo "🚀 Nginx reverse proxy is now active at http://<your-ec2-public-ip>/api/..."
else
  echo "❌ Nginx configuration is invalid. Reverting..."
  sudo cp /etc/nginx/sites-available/default.bak /etc/nginx/sites-available/default
  exit 1
fi
