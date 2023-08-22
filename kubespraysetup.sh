#!/bin/bash
sudo apt update && sudo apt install git python3 python3-pip -y
git clone https://github.com/kubernetes-incubator/kubespray.git
cd kubespray
pip install -r requirements.txt

cp -rfp inventory/sample inventory/mycluster
declare -a IPS=(ip)
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

ssh-copy-id $USER@${IPS[@]}
#add ansible user to sudo group
echo "@USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/@USER
#disable firewall on all the nodes
ansible all -i inventory/mycluster/hosts.yaml -m shell -a "sudo systemctl stop firewalld && sudo systemctl disable firewalld"
#enable IPv4 forwarding and disable swap on all the nodes
ansible all -i inventory/mycluster/hosts.yaml -m shell -a "echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf"
ansible all -i inventory/mycluster/hosts.yaml -m shell -a "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && sudo swapoff -a"

ansible-playbook -i inventory/mycluster/hosts.yaml --become --become-user=root cluster.yml

sudo kubectl get pods -A
