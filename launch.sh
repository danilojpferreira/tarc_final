#Update packages
sudo apt update - y && sudo apt upgrade -y

#Install Docker packages
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
sudo apt update - y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Ansible
sudo apt update -y
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

#Install Kubernets
sudo apt update -y
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt install -y kubelet kubeadm kubectl python