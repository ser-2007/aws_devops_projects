# #! /bin/bash
# apt-get update -y
# apt-get upgrade -y
# hostnamectl set-hostname k3s-master
# # curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -
# curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE=${var.kubeconfig_mode} sh -
# # kubectl get nodes -o wide
# sudo cat <<EOF /var/lib/rancher/k3s/server/node-token
# EOF



#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
hostnamectl set-hostname k3s-master
curl -sfL https://get.k3s.io | sh -
export K3S_KUBECONFIG_MODE="644"
token = "sudo cat /var/lib/rancher/k3s/server/node-token"
