### Launching 2 ec2 with ubuntu 20.0.4
### And installing them k3s

### Kubernetes architecture involves a Master node and Worker Nodes. Their functions are as follows:

- Master – controls the cluster, API calls, e.t.c.
- Workers – these handles the workloads, where the pods are deployed and applications ran. They can be added and removed from the cluster.

- To setup a k3s cluster you need at least two hosts, the master node and one worker node.

### Step 1: Update Ubuntu system
sudo apt update
sudo apt -y upgrade && sudo systemctl reboot

### Step 2: Map the hostnames on each node

- Add the IP and hostname of each node in the /etc/hosts file of each host-.

sudo nano /etc/hosts
172.31.13.75 master (private ip)
172.31.6.142 worker (private ip)

### Step 3: Install Docker on Ubuntu 20.04

sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

- Install Docker CE 

sudo apt update
sudo apt install docker-ce -y

# This has to be done on all the hosts including the master node. After successful installation, start and enable the service.

sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker

- After that you can check the service status, it is active and running

# Add your user to Docker group to avoid typing sudo everytime you run docker commands.

sudo usermod -aG docker ${USER}
newgrp docker

# Step 4: Setup the Master k3s Node

- we shall install and prepare the master node. This involves installing the k3s service and starting it.

curl -sfL https://get.k3s.io | sh -s - --docker

- Run the command above to install k3s on the master node. The script installs k3s and starts it automatically.

- check the system

sudo systemctl status k3s

- After that you can check master node is working by this;

sudo kubectl get nodes -o wide

# Step 5: Allow ports on firewall
In this step if you did when you are launching ec2 and setting the security groups, you don*t need this.

- allow ports that will will be used to communicate between the master and the worker nodes. The ports are 443 and 6443.

sudo ufw allow 6443/tcp
sudo ufw allow 443/tcp

- when you connecting to k3s worker node you need the masters token. You can look the token on master:

sudo cat /var/lib/rancher/k3s/server/node-token

# Step 6: Install k3s on worker nodes and connect them to the master

- install k3s on the worker nodes. Run the commands below to install k3s on worker nodes:

curl -sfL http://get.k3s.io | K3S_URL=https://<master_IP>:6443 K3S_TOKEN=<join_token> sh -s - --docker

curl -sfL http://get.k3s.io | K3S_URL=https://172.31.12.168:6443 K3S_TOKEN="K10394fdb5abfdb46c803e75fdcd08da861beb601e98ec7aa4285bc1f5c963491f2::server:5f8cd029e125204617b7f6f61fbe2e87" sh -s - --docker


- Where master_IP is the IP of the master node and join_token is the token obtained from the master. e.g:

curl -sfL http://get.k3s.io | K3S_URL=https://<master_ip>:6443 K3S_TOKEN=K1078f2861628c95aa328595484e77f831adc3b58041e9ba9a8b2373926c8b034a3::server:417a7c6f46330b601954d0aaaa1d0f5b sh -s - --docker

- You can verify if the k3s-agent on the worker nodes is running by:

sudo systemctl status k3s-agent

- To verify that our nodes have successfully been added to the cluster, run :

sudo kubectl get nodes

After this step you can deploy addons and you can check the cpu utilization

# Step 7: Deploy Addons to K3s
- K3s is a lightweight kubernetes tool that doesn’t come packaged with all the tools but you can install them separately.

# Install Helm Commandline tool on k3s
- Download the latest version of Helm commandline tool from this page.
- Extract the tar file using tar -xvcf <downloaded-file>
- Move the binary file to /usr/local/bin/helm
- sudo mv linux-amd64/helm /usr/local/bin/helm

# Check version

helm version

- Add the helm chart repository to allow installation of applications using helm:

helm repo add stable https://charts.helm.sh/stable
helm repo update

### Demo Application Deploy

# Deploy Nginx Web-proxy on K3s

- Nginx can be used as a web proxy to expose ingress web traffic routes in and out of the cluster.

- We can install nginx web-proxy using Helm:

helm install nginx-ingress stable/nginx-ingress --namespace kube-system \
  --set defaultBackend.enabled=false

- We can test if the application has been installed by:

kubectl get pods -n kube-system -l app=nginx-ingress -o wide

### Step 9: Removing k3s

- After all the steps if you completed your task, you can remove k3s on the worker nodes

sudo /usr/local/bin/k3s-agent-uninstall.sh
sudo rm -rf /var/lib/rancher

- and master node:
sudo /usr/local/bin/k3s-uninstall.sh
sudo rm -rf /var/lib/rancher