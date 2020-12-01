#!/bin/bash

#Update packages
printf "\\n\\n\\t### -> Update Packages\\n\\n"
sudo apt update && sudo apt upgrade -y

#Install and enable Docker packages
printf "\\n\\n\\t### -> Install and enable Docker packages\\n\\n"
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
sudo apt update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

# Install Ansible
printf "\\n\\n\\t### -> Install Ansible\\n\\n"
sudo apt update
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Install Kubernetes packages
printf "\\n\\n\\t### -> Install Kubernetes packages\\n\\n"
sudo apt update
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt install -y kubelet kubeadm kubectl python
sudo apt-mark hold docker-ce kubelet kubeadm kubectl

#Enable the iptables bridge
printf "\\n\\n\\t### -> Enable the iptables bridge\\n\\n"
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

if [ "$0" == "master" ]
    then 
        printf "\\n\\n\\t### -> I'm the Master!\\n\\n"
        # Install and configure AWS account (need to upload config file)
        printf "\\n\\n\\t### -> Install and configure AWS account (need to upload config file)!\\n\\n"
        sudo apt install -y unzip
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        aws configure set aws_access_key_id AKIARPIPWM5GVPWQYL3W 
        aws configure set aws_secret_access_key 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 
        aws configure set region us-west-2

        # Run init kube
        printf "\\n\\n\\t### -> Run init kube\\n\\n"
        sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

        # Create join Command
        printf "\\n\\n\\t### -> Create join Command\\n\\n"
        curl "https://raw.githubusercontent.com/danilojpferreira/tarc_final/main/config_kube.yml" -o "config_kube.yml"
        ansible-playbook ./config_kube.yml
        
        # Set Flannel network add on.
        printf "\\n\\n\\t### -> Set Flannel network add on\\n\\n"
        kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

        # Upload join file
        printf "\\n\\n\\t### -> Upload join file\\n\\n"
        # aws s3 rm s3://tarc-final/join-command.sh #if needed delete
        aws s3 cp “./join-command.sh” s3://tarc-final/join-command.sh

        # Run Pods
    else
        printf "\\n\\n\\t### -> I'm a Node!\\n\\n"
        # Get join file
        # Run config_node.yml if is Node

fi
