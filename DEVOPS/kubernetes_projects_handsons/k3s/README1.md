Launch 2 instances with Amazon Ubuntu 20.04 image, t3.medium (2CPU and 4GI) one will be master, one will be the worker
Open port TCP 6443 to anywhere and port TCP TCP 22 to MyIP in the security group
Update both the instances with "sudo apt update -y" and "sudo apt upgrade -y" commands
Reboot the instances with "sudo systemctl reboot"
Change the master node's hostname with "sudo hostname master&&bash"
Change the worker node's hostname with "sudo hostname worker&&bash"

Only after performing the steps mentioned above proceed with the following:

MASTER NODE K3S SERVER INSTALLATION

Connect via ssh to the master node with "ssh -i <pem-key> ubuntu@master-ip
Establish in which mode to write k3s configutation when not running as root with ; export K3S_KUBECONFIG_MODE="644"
Run installer with " curl -sfL https://get.k3s.io | sh -
Verify the status ;  sudo systemctl status k3s
Get details on the " nodes with  kubectl get nodes -o wide "
Save access token (we need it in the nex steps when setting worker node)  with: sudo cat /var/lib/rancher/k3s/server/node-token


Worker NODE k3s INSTALLATION

Connect via ssh to the worker node with "ssh -i <pem-key> ubuntu@worker-ip
Configure environment variables with : export K3S_KUBECONFIG_MODE="644"; export K3S_URL="https:master_private_ip:6443", export K3S_TOKEN="......"
Or You can use this command only; run the installer with "curl -sfL https://get.k3s.io | K3S_URL=https://<master_private_ip>:6443 K3s_TOKEN="....." sh -
Verify the status with sudo systemctl status k3s-agent
Go to master node and make sure the node has been added : kubectl get nodes -o wide