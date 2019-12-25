#!/bin/sh

touch /tmp/WebSetup_start

#  Install Bind9
#  https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-caching-or-forwarding-dns-server-on-ubuntu-14-04
sudo apt-get update -y
sudo apt-get install nginx -y

touch /tmp/WebSetup_end