#!/bin/bash

# Install Supporting Software
sudo apt-get install -y vim unzip libssl-dev libz-dev libpq-dev libexpat1-dev

# Allow vagrant user to use docker.
sudo usermod -a -G docker vagrant

# Setup local::lib
eval $(perl -Mlocal::lib)
echo 'eval $(perl -Mlocal::lib)' >> /home/vagrant/.bashrc

# Install packages
cpanm Dist::Zilla App::Dex; cpanm Dist::Zilla App::Dex

# Build DB package
cd /home/vagrant/BlogDB/DB
dzil build
cpanm BlogDB-DB-*.tar.gz; cpanm BlogDB-DB-*.tar.gz

# Install web package dependancies.
cd /home/vagrant/BlogDB/Web
cpanm --installdeps .; cpanm --installdeps .

# Install systemd files.
sudo cp /home/vagrant/BlogDB/system/systemd/blogdb.screenshot.service /etc/systemd/system
sudo cp /home/vagrant/BlogDB/system/systemd/blogdb.web.service /etc/systemd/system
sudo cp /home/vagrant/BlogDB/system/systemd/blogdb.worker.service /etc/systemd/system

# Import the database.
DB_FILE="/home/vagrant/BlogDB/DB/etc/schema.sql" \
    DB_PASS=$(sudo cat /root/.database_password) \
    DB_USER="blogdb" DB_NAME="blogdb" psql_import_from_env

# Install configuration file.
cat > /home/vagrant/BlogDB/Web/blogdb.yml <<EOF
---
secrets:
  - $(randpass)

database:
  blogdb: postgresql://blogdb:$(sudo cat /root/.database_password)@localhost/blogdb
  minion: postgresql://blogdb:$(sudo cat /root/.database_password)@localhost/minion

template_dir: simple

ws_screenshot:
  base_url: http://localhost:5000
EOF

# Start services
sudo systemctl start blogdb.screenshot
sudo systemctl start blogdb.web
sudo systemctl start blogdb.worker

# Enable services
sudo systemctl enable blogdb.screenshot
sudo systemctl enable blogdb.web
sudo systemctl enable blogdb.worker
