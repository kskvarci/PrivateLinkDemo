#!/bin/sh

touch /tmp/WebSetup_start

sudo apt-get update -y
sudo apt-get install nginx -y

touch /tmp/WebSetup_end