# ZENIGMA LOG PROCESS
## _This document is a system that automates continuous logging, log cycling, and process management within a Docker container._
##### zenigma_logger.sh

The zenigma_logger.sh script appends "Hello Zenigma!" to the zenigma.log file every 15 seconds.
```sh
#!/bin/bash  

LOG_FILE="/app/zenigma.log"  

while true; do  
    echo "$(date +"%Y-%m-%d %H:%M:%S") Merhaba Zenigma!" >> "$LOG_FILE"  
    sleep 15  
done  
```

##### zenigma_killer.sh
The zenigma_killer.sh script checks if the zenigma.log file has 20 or more lines. If so, it terminates the logger process, deletes the log file, and restarts the logger, logging each action to killer.log.
```sh
#!/bin/bash  

LOG_FILE="/app/zenigma.log"  
PID_FILE="/app/zenigma_logger.pid"  
KILLER_LOG="/app/killer.log"  

if [[ -f "$LOG_FILE" ]]; then  
    LINE_COUNT=$(wc -l < "$LOG_FILE")  
else  
    LINE_COUNT=0  
fi  

if [[ "$LINE_COUNT" -ge 20 ]]; then  
    if [[ -f "$PID_FILE" ]]; then  
        kill -9 $(cat "$PID_FILE") 2>/dev/null  
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Logger process terminated. Line count: $LINE_COUNT" >> "$KILLER_LOG"
        rm -f "$PID_FILE"  
    fi  

    rm -f "$LOG_FILE"  
    echo "$(date +"%Y-%m-%d %H:%M:%S") - zenigma.log deleted." >> "$KILLER_LOG"  

    nohup bash /app/zenigma_logger.sh &> /dev/null &  
    echo $! > "$PID_FILE"  
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Logger restarted." >> "$KILLER_LOG"  
fi
```
##### .entrypoint.sh
The entrypoint.sh script is responsible for starting the logger script in the background using nohup, while continuously checking the log file with the killer.sh script every 5 minutes.
```sh
#!/bin/bash  
nohup bash /app/zenigma_logger.sh &> /dev/null &  
echo $! > /app/zenigma_logger.pid  

while true; do  
    bash /app/zenigma_killer.sh  
    sleep 300
done  
```
##### Dockerfile
The Dockerfile sets up an Ubuntu-based container and copies the necessary scripts into the container. The scripts are then made executable, and an entry point is defined to run the entrypoint.sh script.
```sh
FROM ubuntu:latest  
WORKDIR /app  
COPY zenigma_logger.sh zenigma_killer.sh entrypoint.sh ./  
RUN chmod +x zenigma_logger.sh zenigma_killer.sh entrypoint.sh  
ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
```
# PET CLINIC APP
## _This document contains all devops processes of a new petclinic application._

## Installation Guide
- Docker
- Kubectl
- Helm
- RKE2
- Chartmuseum
- ArgoCD

## Overview
This document provides a step-by-step guide for deploying the Spring Petclinic application on Kubernetes, covering containerization, infrastructure provisioning, and CI/CD pipeline automation. The process includes:

Containerization: The application is packaged as a Docker container using a Dockerfile based on OpenJDK.
Infrastructure Automation: A Kubernetes cluster is provisioned using Ansible, with RKE2 as the preferred distribution.
CI/CD Pipeline: GitHub Actions automates the build, containerization, and deployment process.
Artifact Management: A container registry (Docker Hub) is used for storing and managing Docker images.
Deployment: The application is deployed on a Kubernetes cluster and exposed via a public IP for accessibility.
This guide ensures a fully automated DevOps workflow, from development to production, enabling scalability, maintainability, and streamlined operations.
## Setup
#### 1. Docker
Enables containerization for deploying the Python application.
```sh
#!/bin/bash

sudo apt-get install -y ca-certificates curl software-properties-common
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing Docker and required components..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Docker installation completed. Checking version..."
docker --version

sudo usermod -aG docker $USER
newgrp docker
```
#### 2. Kubectl
CLI tool for managing Kubernetes clusters.
```sh
!/bin/bash

echo "Installing prerequisites..."
sudo apt-get install -y apt-transport-https ca-certificates curl

echo "Adding Kubernetes GPG key..."
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

echo "Adding Kubernetes apt repository..."
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "Updating package lists after adding Kubernetes repo..."
sudo apt-get update

echo "Installing kubectl..."
sudo apt-get install -y kubectl

echo "Verifying kubectl installation..."
kubectl version --client
```
#### 3. Helm
Kubernetes package manager for deploying and managing applications.
```sh
#!/bin/bash

echo "Downloading Helm GPG key..."
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null

echo "Installing APT transport-https..."
sudo apt-get install apt-transport-https --yes

echo "Adding Helm repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

echo "Updating package lists..."
sudo apt-get update

echo "Installing Helm..."
sudo apt-get install helm --yes

echo "Checking Helm version..."
helm version
```
# Installation
### Create RKE2 Cluster with Ansible
##### Directory Structure
.
```sh
.
├── inventory.ini
├── main.yml
├── roles
│   ├── installation
│   │   └── tasks
│   │       ├── install_master.yml
│   │       ├── join_master.yml
│   │       ├── join_worker.yml
│   └── requirements
│       └── tasks
│           └── requirements.yml
└── vars
   └── vars.yml
```
##### Playbook Files
-> inventory.ini
Server inventory file. Contains IP addresses and SSH connection information of master and worker nodes.
```sh
[allnode:children]
master-firstnode
workers

[master-firstnode]
rke2-node1 ansible_host=13.49.207.89 ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/case.pem

[workers]
rke2-worker-node1 ansible_host=16.171.203.157 ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/case.pem
rke2-worker-node2 ansible_host=51.20.20.206 ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/case.pem

[allnode:vars]
ansible_user=root
remote_tmp=/tmp/.ansible-${USER}/tmp
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
```
-> vars.yml
File where variables are defined. Contains the necessary paths and parameters for RKE2 configuration.
```sh
##Installing ENV
confvar: "/var/lib/rancher/rke2/server"
confdir: "/etc/rancher/rke2"
conffile: "{{ confdir }}/config.yaml"
clustername: "test"
kubeconfig: "/etc/rancher/rke2/rke2.yaml"
```
-> install_master.yml
Contains tasks for setting up the master node.
```sh
---
    - name: Create RKE2 Directory
      file:
        path: "{{ confdir }}"
        state: directory
        owner: root
        group: root
        mode: '0770'
        recurse: yes

    - name: Installing RKE2 Server
      shell: |
          curl -sfL https://get.rke2.io |  INSTALL_RKE2_TYPE=server sh -

    - name: Start rke2-server service
      service:
        name: rke2-server
        state: started
        enabled: yes

    - name: Simlink kubectl
      shell: |
        ln -s $(find /var/lib/rancher/rke2/data/ -name kubectl) /usr/local/bin/kubectl
      ignore_errors: yes

    - name: Append /var/lib/rancher/rke2/bin/ to PATH env
      lineinfile:
        path: /root/.bash_profile
        line: export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
        create: yes
        backup: yes

    - name: Create RKE2 config.yaml for joining
      shell: "echo server: https://{{ ansible_host }}:9345 > {{ confvar }}/config.yaml; \
              echo token: $(cat {{ confvar }}/node-token) >> {{ confvar }}/config.yaml"

    - name: Fetch Token From Master
      fetch:
       src: "{{ confvar }}/config.yaml"
       dest: "/tmp/rke2_{{ clustername }}_config.yaml"
       flat: yes
```
-> join_master.yml
Contains tasks to incorporate master nodes into the cluster.
```sh
---
  - name: Create RKE2 Directory
    file:
       path: "{{ confdir }}"
       state: directory
       owner: root
       group: root
       mode: '0770'
       recurse: yes

  - name: Installing RKE2 Server
    shell: |
        curl -sfL https://get.rke2.io |  INSTALL_RKE2_TYPE=server sh -


  - name: Copy Master Rancher Config file
    copy:
     src: /tmp/rke2_{{ clustername }}_config.yaml
     dest: /etc/rancher/rke2/config.yaml
     owner: root
     group: root
     mode: '0660'

  - name: Start rke2-server service
    service:
      name: rke2-server
      state: started
      enabled: yes

  - name: Simlink kubectl
    shell: |
      ln -s $(find /var/lib/rancher/rke2/data/ -name kubectl) /usr/local/bin/kubectl
    ignore_errors: yes

  - name: Append /var/lib/rancher/rke2/bin/ to PATH env
    lineinfile:
      path: /root/.bash_profile
      line: export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
      create: yes
      backup: yes
```
-> join_worker.yml
Contains tasks to add worker nodes to the cluster.
```sh
---
  - name: Create RKE2 Directory
    file:
       path: "{{ confdir }}"
       state: directory
       owner: root
       group: root
       mode: '0770'
       recurse: yes

  - name: Installing RKE2 Agent on Workers
    shell: |
        curl -sfL https://get.rke2.io |  INSTALL_RKE2_TYPE=agent sh -

  - name: Copy Master Rancher Config file
    copy:
     src: /tmp/rke2_{{ clustername }}_config.yaml
     dest: /etc/rancher/rke2/config.yaml
     owner: root
     group: root
     mode: '0660'

  - name: Start rke2-agent service
    service:
      name: rke2-agent
      state: started
      enabled: yes

  - name: Simlink kubectl
    shell: |
      ln -s $(find /var/lib/rancher/rke2/data/ -name kubectl) /usr/local/bin/kubectl
    ignore_errors: yes

  - name: Append /var/lib/rancher/rke2/bin/ to PATH env
    lineinfile:
      path: /root/.bash_profile
      line: export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
      create: yes
      backup: yes
```
-> main.yml
Main Ansible playbook. Sets up master and worker nodes in order.
```sh
---
- hosts: master-firstnode
  become: yes
  tasks:
    - name: Include vars
      include_vars:
        dir: vars

    - name: Install RKE2 Master Server
      include_role:
        name: installation
        tasks_from: install_master.yml

- hosts: master-nextnodes
  become: yes
  tasks:
    - name: Include vars
      include_vars:
        dir: vars

    - name: Install RKE2 Next Master Nodes
      include_role:
        name: installation
        tasks_from: join_master.yml

- hosts: workers
  become: yes
  tasks:
    - name: Include vars
      include_vars:
        dir: vars

    - name: Install RKE2 Next Master Nodes
      include_role:
        name: installation
        tasks_from: join_worker.yml
```
To run Playbook we used the following command:
```sh
ansible-playbook main.yml -i inventory.ini
```
#### Docker Build and Push
This Dockerfile uses a multi-stage build to optimize the container size. The first stage compiles the Spring Petclinic application using Maven, and the second stage runs the application with a lightweight Eclipse Temurin JDK 17 base image. 
```sh
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app
COPY . .
RUN mvn package -DskipTests

FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app
COPY --from=builder /app/target/spring-petclinic-3.4.0-SNAPSHOT.jar app.jar

EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```
This GitHub Actions workflow builds and pushes a Docker image for the Spring Petclinic app. It logs into Docker Hub, extracts the Git commit SHA, and tags the image before pushing it.
```sh
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_ACCESS_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Extract Git Commit SHA
        run: echo "GIT_COMMIT_SHA=$(echo $GITHUB_SHA | cut -c1-7)" >> $GITHUB_ENV

      - name: Build and Push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: |
            ${{ secrets.DOCKER_HUB_USERNAME }}/petclinic:latest
            ${{ secrets.DOCKER_HUB_USERNAME }}/petclinic:${{ env.GIT_COMMIT_SHA }}
```
### Chartmuseum Installation
By using ChartMuseum, we will store the application's Helm packages in a publicly accessible central repository. This way, when using ArgoCD, we can pull the Helm resources from there.
```sh
helm repo add chartmuseum https://chartmuseum.github.io/charts
helm install helm-repo chartmuseum/chartmuseum -f values.yaml
```
```sh
env:
  open:
    DISABLE_API: false
```
NOTE: 
Ensures that the application's API is active.
#### Helm Package And Helm Push:
Packages the Helm chart into a .tgz file and pushes it to a Helm chart repository for versioned storage and distribution.
```sh
      - name: Set up Helm
        uses: azure/setup-helm@v4.2.0
        with:
          version: latest
        env:
          GIT_COMMIT_SHA: ${{ github.sha }}

      - name: Get Current Version
        id: get_version
        run: |
          # Get the current version from Chart.yaml
          VERSION=$(grep "version:" devops/Chart.yaml | awk '{print $2}')
          echo "Current version is $VERSION"

      - name: Set the chart version based on run number
        run: |
          sed -i "s/^version:.*/version: $GITHUB_RUN_NUMBER/" devops/Chart.yaml
          cat devops/Chart.yaml

      - name: Package Helm Chart
        id: package_helm_chart
        run: |
          cd devops/
          rm -f petclinic-*.tgz
          helm package .
          CHART_TGZ=$(ls petclinic-*.tgz)
          echo "Chart package name is $CHART_TGZ"
          echo "::set-output name=chart_tgz::$CHART_TGZ"

      - name: Push Helm Chart to Repository using curl
        run: |
          cd devops/
          curl --data-binary "@${{ steps.package_helm_chart.outputs.chart_tgz }}" \
          -H "Content-Type: application/x-gzip" \
          http://13.49.207.89:30511/api/charts
```
### ArgoCD Installation
This section explains how to set up ArgoCD to deploy the petclinic project with a Helm chart from a private repository.

1.Create a Secret for Repository Credentials
To authenticate ArgoCD to access the private Helm repository, create a secret:
```sh
apiVersion: v1
kind: Secret
metadata:
  name: museum-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  project: app
  type: helm
  url: http://helm-repo-chartmuseum.default.svc.cluster.local:8080
```
2.Define ArgoCD Project
Define a project within ArgoCD that uses the above repository for deployment:
```sh
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: app
spec:
  description: "Pet Clinic project"
  sourceRepos:
    - 'http://helm-repo-chartmuseum.default.svc.cluster.local:8080'
  destinations:
    - namespace: applications
      server: 'https://kubernetes.default.svc'
```
3.Create ArgoCD Application For Backend 
Create an ArgoCD application to deploy the Helm chart from the repository:
```sh
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app
spec:
  destination:
    name: ''
    namespace: applications
    server: 'https://kubernetes.default.svc'
  project: app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
  sources:
  - repoURL: 'http://helm-repo-chartmuseum.default.svc.cluster.local:8080'
    chart: petclinic
    targetRevision: '*'
```
To retrieve the initial admin password for ArgoCD, you can use the following kubectl command:
```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
This configuration enables ArgoCD to deploy the petclinic project from a private Helm repository and manage its lifecycle in Kubernetes.
