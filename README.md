# Provisioning for Vagrant

## What you get

* Ubuntu bento/ubuntu-16.04
* Java8
* Redis latest
* Arangodb 3.1.10
* Couchdb latest 
* Couchbase 4.1.0
* Fluentd latest 
* Elasticsearch 5.2.1
* Logstash latest 
* Kibana latest 
* Postgresql 9.5
* Node 4.4.7

more to come... 

## Prereqs

* VirutalBox (https://virtualbox.org)
* Vagrant (https://vagrantup.com)

## How to use

* mkdir where you want the box 
* git clone this project into that dir
* vagrant up


Give it 2 to 3 mintues to get everything installed


It will create a private network at 192.168.55.55 that will bind to the address
couchdb will be available at 192.168.55.55:5984/_utils/index.html