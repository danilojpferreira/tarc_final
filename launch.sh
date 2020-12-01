#!/bin/bash

#Update packages
sudo apt update - y && sudo apt upgrade -y

#Install Docker packages
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
sudo apt update - y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Ansible
sudo apt update
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

#Install Kubernets
sudo apt update
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt install -y kubelet kubeadm kubectl python


if ["$0" == "master"]; then 
        # Install and configure AWS account (need to upload config file)
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        aws configure set aws_access_key_id AKIARPIPWM5GVPWQYL3W 
        aws configure set aws_secret_access_key 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 
        aws configure set region us-west-2

        # Run config_kube.yml
        curl "https://raw.githubusercontent.com/danilojpferreira/tarc_final/main/config_kube.yml" -o "config_kube.yml"
        curl "https://raw.githubusercontent.com/danilojpferreira/tarc_final/main/net.yaml" -o "net.yaml"
        ansible-playbook ./config_kube.yml
        
        # Upload join file
        aws s3 cp “./join-command.sh” s3://tarc-final/join-command.sh

        # Run Pods
    else
        # Get join file
        # Run config_node.yml if is Node
fi