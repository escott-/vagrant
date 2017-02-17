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
REDIS_CONF="/etc/redis/redis.conf"
add-apt-repository ppa:chris-lea/redis-server -y
apt-get update
apt-get install redis-server -y
sed -i "s/\(bind \).*/\bind $ADDR /" $REDIS_CONF
sed -i "s/\(protected-mode \).*/\protected-mode no /" $REDIS_CONF
service redis-server restart

# Install Arangodb
echo "BEING ARANGODB INSTALL"
ARANGO_CONF="/etc/arangodb3/arangod.conf"
echo arangodb3 arangodb3/password password | debconf-set-selections
echo arangodb3 arangodb3/password_again password | debconf-set-selections
wget https://www.arangodb.com/repositories/arangodb31/xUbuntu_16.04/Release.key
apt-key add Release.key
echo 'deb https://www.arangodb.com/repositories/arangodb31/xUbuntu_16.04/ /' | sudo tee /etc/apt/sources.list.d/arangodb.list
apt-get update -y
apt-get install arangodb3=3.1.10
sed -i "s/\(endpoint \).*/\endpoint = tcp:\/\/$ADDR:8529 /" $ARANGO_CONF
service arangodb3 restart

# Install Couchdb
echo "BEGIN COUCHDB INSTALL"
add-apt-repository ppa:couchdb/stable -y
apt-get install couchdb -y
COUCHDB_CONF="/etc/couchdb/local.ini"
sed -i "s/\(;bind_address \).*/\bind_address = $ADDR /" $COUCHDB_CONF
service couchdb restart

# Install Couchbase
echo "BEGIN COUCHBASE INSTALL"
wget https://packages.couchbase.com/releases/4.1.0/couchbase-server-community_4.1.0-ubuntu14.04_amd64.deb
dpkg-deb -x couchbase-server-community_4.1.0-ubuntu14.04_amd64.deb $HOME
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

# Add for logstash and kibana 
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
apt-get update

# Install Logstash
LOGSTASH_CONF="/etc/logstash/logstash.yml"
apt-get -y install logstash
service logstash start

# Install Kibana
KIBANA_CONF="/etc/kibana/kibana.yml"
ELASTICSEARCH="$ADDR:9200"
apt-get -y install kibana
sed -i "s/\(#server.port: \).*/server.port: 5601 /" $KIBANA_CONF
sed -i "s/\(#server.host: \).*/server.host: $ADDR /" $KIBANA_CONF
sed -i "s/\(#elasticsearch.url: \).*/elasticsearch.url: http:\/\/$ELASTICSEARCH /" $KIBANA_CONF
sed -i "s/\(#elasticsearch.url: \).*/elasticsearch.url: $ELASTICSEARCH /" $KIBANA_CONF
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
