#!/bin/bash
#==
# Script to set up a new Debian 11 machine to support BlogDB with docker & dex.
#==

#if $UID -ne 0; then
#    echo "Error: This script must be run as root.";
#    exit -1;
#fi

#==
# Update the packages and install supporting software.
#==
apt-get update -y;
apt-get upgrade -y;
apt-get install -y git build-essential cpanminus liblocal-lib-perl expect;

#==
# Install postgresql, some database helpers, and set our DBs up.
#==
apt-get install -y postgresql postgresql-contrib postgresql-client

# Make a script to make createdb run with env vars.
cat > /bin/createdb_from_env <<'EOF';
#!/usr/bin/env expect

set username $env(DB_USER)
set password $env(DB_PASS)
set database $env(DB_NAME)

spawn createdb -h localhost -U $username -W $database
expect "Password:"
send "$password\r\n"
expect eof
EOF

# Make a script to make createuser run with env vars.
cat > /bin/createuser_from_env <<'EOF';
#!/usr/bin/env expect

set username $env(DB_USER)
set password $env(DB_PASS)

spawn createuser -d $username -P
expect "Enter password for new role:"
send "$password\r\n"
expect "Enter it again:"
send "$password\r\n"
expect eof
EOF

# Make a script to import a DB file.
cat > /bin/psql_import_from_env <<'EOF';
#!/usr/bin/env expect

set username $env(DB_USER)
set password $env(DB_PASS)
set database $env(DB_NAME)
set filename $env(DB_FILE)

spawn psql -U $username -W --host localhost -f $filename $database
expect "Password:"
send "$password\r\n"
expect eof
EOF

# Make a script to make createuser run with env vars.
cat > /bin/randpass <<'EOF';
#!/usr/bin/env perl

my @chars = ( 'A' .. 'Z', 'a' .. 'z', 0 .. 9 );

print map { $chars[int rand @chars] } ( 0 .. 48 );
EOF

# Make all our scripts executable.
chmod 755 /bin/createdb_from_env
chmod 755 /bin/createuser_from_env
chmod 755 /bin/psql_import_from_env
chmod 755 /bin/randpass

# Create a random password for the db, store it in a file so we can refer to it later.
randpass > /root/.database_password

DB_USER="blogdb" DB_PASS=$(cat /root/.database_password) sudo -Eu postgres createuser_from_env
DB_USER="blogdb" DB_PASS=$(cat /root/.database_password) DB_NAME="blogdb" createdb_from_env
DB_USER="blogdb" DB_PASS=$(cat /root/.database_password) DB_NAME="minion" createdb_from_env

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
