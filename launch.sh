#!/bin/bash

type=node
workers=1
instanceType=t2.micro
subnetId=subnet-9a8704c5
keyName=TARC_KEY
region=us-east-1
securityGroups=sg-46d3de73

for ((i = 1; i <= $#; i++)); do
    if [ ${!i} = "--type" ]; then
        ((i++))
        type=${!i}

    elif [ ${!i} = "--workers" ]; then
        ((i++))
        workers=${!i}

    elif [ ${!i} = "--instanceType" ]; then
        ((i++))
        instanceType=${!i}

    elif [ ${!i} = "--subnetId" ]; then
        ((i++))
        subnetId=${!i}

    elif [ ${!i} = "--keyName" ]; then
        ((i++))
        keyName=${!i}

    elif [ ${!i} = "--securityGroups" ]; then
        ((i++))
        securityGroups=${!i}

    elif [ ${!i} = "--region" ]; then
        ((i++))
        region=${!i}

    elif [ ${!i} = "--aws-key" ]; then
        ((i++))
        awsKey=${!i}

    elif [ ${!i} = "--aws-pass" ]; then
        ((i++))
        awsPass=${!i}
    fi
done

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

if [ $type = "master" ]; then
    printf "\\n\\n\\t### -> I'm the Master Node!\\n\\n"
    # Install and configure AWS account (need to upload config file)
    printf "\\n\\n\\t### -> Install and configure AWS account (need to upload config file)!\\n\\n"
    sudo apt install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    aws configure set aws_access_key_id $awsKey
    aws configure set aws_secret_access_key $awsPass
    aws configure set region $region

    # Run init kube
    printf "\\n\\n\\t### -> Run init kube\\n\\n"
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16 #--ignore-preflight-errors=NumCPU
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
    aws s3 cp "./join-command.sh" s3://tarc-bucket/join-command.sh

    # Run Pods
    printf "\\n\\n\\t### -> Run Pods\\n\\n"
    curl "https://raw.githubusercontent.com/danilojpferreira/tarc_final/main/run-pods.sh" -o "run-pods.sh"
    sudo sh ./run-pods.sh

    # Create others instances
    for counter in `seq 1 $workers`; do
        random=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^0*//' | head --bytes 3)
        aws ec2 run-instances --region $region --image-id ami-0885b1f6bd170450c --count 1 --instance-type $instanceType --key-name $keyName --security-group-ids $securityGroups --subnet-id $subnetId --tag-specifications "ResourceType=instance,Tags=[{Key=hash,Value=$random},{Key=TARC,Value=true},{Key=nodeType,Value=worker}]" --user-data file://launch.sh
        instance=$(aws ec2 describe-instances --region $region --filters "Name=tag:hash,Values=$random" --query Reservations[*].Instances[*].[InstanceId] --output text)
        sleep 60
        aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-1:807587852252:targetgroup/TARC-TARGET-GROUP/a499ba73d38018c2 --targets Id=$instance
    done
else
    printf "\\n\\n\\t### -> I'm a Worker Node!\\n\\n"
    printf "\\n\\n\\t### -> Getting Join File\\n\\n"
    curl "https://tarc-bucket.s3.amazonaws.com/join-command.sh" -o "join-command.sh"
    printf "\\n\\n\\t### -> Joing\\n\\n"
    sudo sh ./join-command.sh
fi
