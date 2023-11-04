#!/bin/bash

sudo apt update
sudo apt install -y fontconfig openjdk-17-jre
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt -y upgrade
sudo apt install -y jenkins

sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa 
sudo apt install -y python3.7 
sudo apt install -y python3.7-venv
sudo apt install -y build-essential
sudo apt install -y libmysqlclient-dev
sudo apt install -y python3.7-dev