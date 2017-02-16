#!/bin/sh
sudo -i

# vagrant init bento/ubuntu-16.04; vagrant up --provider virtualbox
ADDR=192.168.55.55

NODE_VERSION=4.4.7

PG_PASS=postgres
PG_VERSION=9.5

# Set language and locale
apt-get install -y language-pack-en

# Some basics
apt-get -qq update
apt-get install -y \
wget \
git \
unzip \
build-essential \
libssl-dev \
software-properties-common -y \
ntp \
inotify-tools \
tcl8.5

# Install Java
echo "BEGIN JAVA INSTALL"
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
add-apt-repository ppa:webupd8team/java -y
apt-get update
apt-get install oracle-java8-installer -y

# Install Redis
echo "BEGIN REDIS INSTALL"
wget http://download.redis.io/releases/redis-stable.tar.gz
tar xzf redis-stable.tar.gz
cd redis-stable
make
make test
make install
cd utils
./install_server.sh
REDIS_CONF="/etc/redis/6379.conf"
sed -i "s/\(bind \).*/\bind $ADDR /" $REDIS_CONF
service redis_6379 start

# Install Couchdb
echo "BEGIN COUCHDB INSTALL"
add-apt-repository ppa:couchdb/stable -y
apt-get install couchdb -y
COUCHDB_CONF="/etc/couchdb/local.ini"
sed -i "s/\(;bind_address \).*/\bind_address = $ADDR /" $COUCHDB_CONF
service couchdb restart

# Install Couchbase
echo "BEGIN COUCHBASE INSTALL"
wget https://packages.couchbase.com/releases/4.5.0/couchbase-server-community_4.5.0-ubuntu14.04_amd64.deb
dpkg-deb -x couchbase-server-community_4.5.0-ubuntu14.04_amd64.deb $HOME
cd $HOME/opt/couchbase
./bin/install/reloc.sh `pwd`
./bin/couchbase-server -- -noinput -detached

# Install Elasticsearch
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.2.1.deb
dpkg -i elasticsearch-5.2.1.deb
ELASTIC_CONF="/etc/elasticsearch/elasticsearch.yml"
sed -i "s/\(#network.host: \).*/network.host: $ADDR /" $ELASTIC_CONF
sed -i "s/\(#http.port: \).*/http.port: 9200 /" $ELASTIC_CONF
service elasticsearch start

# Install Kibana
KIBANA_CONF="/etc/kibana/kibana.yml"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
apt-get update
apt-get -y install kibana
service kibana start

# Postgres
echo "BEGIN POSTGRES INSTALL"
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
apt-get update
apt-get -y install postgresql-$PG_VERSION postgresql-contrib-$PG_VERSION

PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
echo "client_encoding = utf8" >> "$PG_CONF" # Set client encoding to UTF8
service postgresql restart

cat << EOF | su - postgres -c psql
ALTER USER postgres WITH ENCRYPTED PASSWORD '$PG_PASS';
EOF

# Install nodejs and npm
export NVM_DIR="$HOME/.nvm" && (
  git clone https://github.com/creationix/nvm.git "$NVM_DIR"
  cd "$NVM_DIR"
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" origin`
) && . "$NVM_DIR/nvm.sh"

nvm install $NODE_VERSION
nvm use $NODE_VERSION
