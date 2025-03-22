#!/bin/bash

# Setup script for JSON Bucket Server
# Run as root or with sudo privileges

APP_DIR="/var/www/json-buckets"
VENV_DIR="$APP_DIR/venv"
SERVICE_FILE="/etc/systemd/system/jsonbuckets.service"
NGINX_SITE="/etc/nginx/sites-available/buckets.nodorks.net"
NGINX_ENABLED="/etc/nginx/sites-enabled/buckets.nodorks.net"

# --- Install dependencies ---
apt update
apt install -y python3 python3-venv python3-pip mysql-server nginx

# --- Set up Flask app ---
mkdir -p $APP_DIR
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

deactivate

# --- Create WSGI file ---
cat <<EOF > $APP_DIR/wsgi.py
from app import app

if __name__ == "__main__":
    app.run()
EOF

# --- Setup MySQL database ---
mysql -u root < $APP_DIR/db_init.sql

# --- Create .env file ---
cat <<EOF > $APP_DIR/.env
# Database Configuration
MYSQL_HOST=localhost
MYSQL_USER=bucketuser
MYSQL_PASSWORD=bucketpass
MYSQL_DB=jsonbuckets

# Flask Configuration
FLASK_ENV=production
FLASK_DEBUG=0

# Rate Limiting
RATELIMIT_STORAGE_URL=memory://
EOF

# --- Create MySQL user ---
mysql -u root <<EOF
CREATE USER IF NOT EXISTS 'bucketuser'@'localhost' IDENTIFIED BY 'bucketpass';
GRANT ALL PRIVILEGES ON jsonbuckets.* TO 'bucketuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# --- Setup Gunicorn systemd service ---
cat <<EOF > $SERVICE_FILE
[Unit]
Description=Gunicorn instance to serve JSON Buckets
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=$VENV_DIR/bin"
EnvironmentFile=$APP_DIR/.env
ExecStart=$VENV_DIR/bin/gunicorn --workers 3 --bind unix:$APP_DIR/json-buckets.sock wsgi:app

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl enable --now jsonbuckets

# --- Setup Nginx site config ---
cat <<EOF > $NGINX_SITE
server {
    listen 80;
    server_name buckets.nodorks.net;

    location / {
        include proxy_params;
        proxy_pass http://unix:$APP_DIR/json-buckets.sock;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
    }
}
EOF

ln -s $NGINX_SITE $NGINX_ENABLED || true
systemctl restart nginx

# --- Set proper permissions ---
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR
chmod 640 $APP_DIR/.env

# --- Done ---
echo "✅ JSON Bucket Server is now set up at http://buckets.nodorks.net"
echo "⚠️  Please update the .env file with secure credentials before using in production"
