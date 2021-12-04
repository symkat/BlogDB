#!/bin/bash
#==
# Script to set up a new Debian 11 machine to support BlogDB with docker & dex.
#==

if $UID -ne 0; then
    echo "Error: This script must be run as root.";
    exit -1;
fi

#==
# Update the packages and install supporting software.
#==
apt-get update -y;
apt-get upgrade -y;
apt-get install -y git build-essential cpanminus liblocal-lib-perl;

#==
# Install Docker
#==

# Install packages we need to have in order to install docker.
apt-get update -y;
apt-get install -y ca-certificates curl gnupg lsb-release;

# Get keys from docker for their packages.
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg;

# Add the docker apt repo.
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list;

# Finally, actually install docker.
apt-get update -y;
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose;

# Setup local::lib for the future and then enable it for the rest of this script.

echo 'eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"' >> /root/.bashrc;
source /root/.bashrc;

# Install App::Dex
cpanm App::Dex

echo
echo
echo "The system is now setup to run docker containers from root."
echo
echo "You should exit this shell and reconnect, or source ~/.bashrc"
echo "so that your perl environment will be setup and dex will run."
echo
echo "Then, get BlogDB and proceed:"
echo "SSH:  git@github.com:symkat/BlogDB.git"
echo "HTTP: https://github.com/symkat/BlogDB.git"
echo