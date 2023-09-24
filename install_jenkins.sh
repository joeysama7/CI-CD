#!/bin/bash

#Create a Script to Automate the Installation of Jenkins on the EC2 Instance
sudo apt-get update -y

# Install Java (OpenJDK 11)
sudo apt-get install openjdk-11-jdk -y

# Add Jenkins Debian package repository key
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -

# Add Jenkins Debian package repository
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Update the package list again to fetch the latest repository information
sudo apt-get update -y

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y 
sudo apt-get install jenkins -y

# Install Maven
sudo apt install maven -y

# Enable Jenkins to start on boot
sudo systemctl enable jenkins

# Start the Jenkins service
sudo systemctl start jenkins

# Print the Jenkins initial admin password
echo 'clearing screen...' && sleep 5
clear
echo 'jenkins is installed'
echo 'this is the default password :' $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)