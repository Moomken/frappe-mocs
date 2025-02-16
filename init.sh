#!/bin/bash

set -e  # Exit on error

# Set variables
BENCH_DIR="/home/frappe/frappe-bench"
SITE_NAME="lms.localhost"
MYSQL_ROOT_PASSWORD="Moomkenwe0909"  # Use an environment variable or secret management
ADMIN_PASSWORD="Moomkenwe0909"
NODE_VERSION="16"  # Set appropriate Node.js version

# Ensure required environment variables are set
export PATH="${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/:${PATH}"

# Check if Bench already exists
if [ -d "$BENCH_DIR/apps/frappe" ]; then
    echo "Bench already exists, skipping init"
    cd "$BENCH_DIR"
else
    echo "Creating new Bench..."
    bench init --skip-redis-config-generation "$BENCH_DIR"
    cd "$BENCH_DIR"
fi

# Set database and caching hosts for containers
bench set-mariadb-host mariadb
bench set-redis-cache-host redis:6379
bench set-redis-queue-host redis:6379
bench set-redis-socketio-host redis:6379

# Remove unnecessary services from Procfile
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile

# Install required applications
bench get-app lms
bench get-app builder --branch main  # Use stable branch
bench get-app insights --branch version-3  # Ensure this is a production-ready branch

# Create site with secure settings
bench new-site "$SITE_NAME" \
    --force \
    --mariadb-root-password "$MYSQL_ROOT_PASSWORD" \
    --admin-password "$ADMIN_PASSWORD" \
    --no-mariadb-socket \
    --db-host mariadb

# Install applications on the site
bench --site "$SITE_NAME" install-app lms
bench --site "$SITE_NAME" install-app builder
bench --site "$SITE_NAME" install-app insights

# Set production mode
bench --site "$SITE_NAME" set-config developer_mode 0
bench --site "$SITE_NAME" clear-cache
bench use "$SITE_NAME"

# Set Bench for production
bench setup production frappe
