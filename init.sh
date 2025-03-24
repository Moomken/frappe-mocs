#!/bin/bash

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, skipping init"
    cd frappe-bench
    bench start
else
    echo "🚉 Starting the script from the beginning"
fi

# Enable error handling
set -e

echo "🚀 Starting initialization script..."

# Install dependencies
echo "📦 Installing dependencies..."
sudo apt update -y
sudo apt install -y git python3-pip python3-dev python3-setuptools python3-venv virtualenv redis pipx supervisor nodejs npm
sudo apt install -y xvfb libfontconfig wkhtmltopdf

# Install Yarn
echo "📦 Installing Yarn..."
sudo npm install -g yarn

# Ensure required directories exist
echo "📂 Creating necessary directories..."
#sudo mkdir -p /home/frappe/.local /home/frappe/.cache /home/frappe/.config
sudo chown -R frappe:frappe /home/frappe


export PATH="${NVM_DIR}/versions/node/v${NODE_VERSION_DEVELOP}/bin/:${PATH}"


# Set up pipx and install bench
echo "⚙️ Setting up pipx and bench..."
pipx ensurepath
pipx install --force frappe-bench
pipx install honcho

# Continue with bench setup or restart
if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "✅ Bench already exists. Restarting..."
    bench start || echo "⚠️ Bench restart failed, please check logs."
else
    echo "🚀 Creating new Bench..."
    cd /home/frappe
    bench init --skip-redis-config-generation frappe-bench
    # bench init --frappe-branch version-15 frappe-bench
    cd frappe-bench
    
    bench set-mariadb-host mariadb
    bench set-redis-cache-host redis:6379
    bench set-redis-queue-host redis:6379
    bench set-redis-socketio-host redis:6379


    # Remove redis, watch from Procfile
    sed -i '/redis/d' ./Procfile
    sed -i '/watch/d' ./Procfile

    bench get-app lms
    bench get-app builder --branch develop
    bench get-app insights --branch version-3
    
    bench new-site lms.localhost \
        --force \
        --mariadb-root-password Moomkenwe0909 \
        --admin-password admin \
        --mariadb-user-host-login-scope='%'
        
    bench --site lms.localhost install-app lms
    bench --site lms.localhost install-app builder
    bench --site lms.localhost install-app insights
    
    bench --site lms.localhost set-config developer_mode 1
    bench --site lms.localhost clear-cache
    bench use lms.localhost
    echo "✅ New Bench setup complete!"
fi

# Start Bench in foreground
echo "🚀 Starting Bench..."
cd /home/frappe/frappe-bench/
bench start
