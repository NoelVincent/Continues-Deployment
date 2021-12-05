# Continues Deployment System
Here, we are building a Continues Deployment System of Docker using Ansible, Jenkins,
EC2 and Git.

# Architecture
![](https://i.ibb.co/Gccp4RY/1.png)

# Includes /  Working
- Created 3 Instances
  - 1: For Jenkins and Ansible Playbook
  - 2: Server for Building the Image
  - 3: Server for testing the application. Here, will be creating the container using the image.
- Jenkins will be installed on the server and configured to run the Ansible playbook when new commits are made in the github repository
- Github repository with webhook enabled to the Jenkins server
- Ansible Playbook that build the docker image and create the container
- Docker containers

# Docker
Docker is an open platform for developing, shipping, and running applications. Docker enables you to separate your applications from your infrastructure so you can deliver software quickly. 

Docker provides the ability to package and run an application in a loosely isolated environment called a container. The isolation and security allow you to run many containers simultaneously on a given host. Containers are lightweight and contain everything needed to run the application, so you do not need to rely on what is currently installed on the host. You can easily share containers while you work too.
You can learn more about the same in the [website.](https://docs.docker.com/get-started/overview/)

# What Is a Container
A container is a standard unit of software that packages up code and all its dependencies so the application runs quickly and reliably from one computing environment to another. Docker container image is a lightweight, standalone, executable package of software that includes everything needed to run an application: code, runtime, system tools, system libraries and settings.
You can learn more about the same in the [website.](https://www.docker.com/resources/what-container)

# Jenkins
Jenkins is a self-contained, open source automation server which can be used to automate all sorts of tasks related to building, testing, and delivering or deploying software.
Jenkins can be installed through native system packages, Docker, or even run standalone by any machine with a Java Runtime Environment (JRE) installed.
You can learn more about the same in the [website.](https://www.jenkins.io/)

# Ansible
Ansible is a radically simple IT automation engine that automates cloud provisioning, configuration management, application deployment, intra-service orchestration, and many other IT needs. It is the simplest way to automate IT. Ansible is the only automation language that can be used across entire IT teams from systems and network administrators to developers and managers.
You can learn more about ansible : 
- https://www.ansible.com
- https://www.ansible.com/overview/how-ansible-works

# Intro to playbooks
Ansible Playbooks offer a repeatable, re-usable, simple configuration management and multi-machine deployment system, one that is well suited to deploying complex applications. If you need to execute a task with Ansible more than once, write a playbook and put it under source control. Then you can use the playbook to push out new configuration or confirm the configuration of remote systems.
You can learn more about the same in the [website.](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html)

# Installing Jenkins and Additional Packages
> Here I am using AWS Amazon linux server

#### Jenkins
```sh
yum install java-1.8.0-openjdk-devel -y
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
amazon-linux-extras install epel
yum -y install jenkins
systemctl start jenkins
systemctl enable jenkins
```
#### Git
```sh
yum install git -y
```
#### Ansible
```sh
amazon-linux-extras install ansible2 -y
```
Please see the [website](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installation-guide) for more information.

# Github repository
> Contains a Dockerfile and the application/code that need to be executed.
- Here, I am using a python Flask application.
```sh
vim Dockerfile
```
```sh
FROM alpine:latest
RUN  mkdir /tmp/pro-flask/
WORKDIR /tmp/pro-flask/
COPY ./project/  .
RUN apk update && apk add --no-cache python3 && apk add --no-cache py-pip
RUN pip install -r requirements.txt
EXPOSE 8081
CMD [ "python3" , "app.py"]
```
> Application code and dependencies in /project/

# Playbook
> Inventory file
```sh
vim /var/con_dep/hosts
```
```sh
[build]
3.110.195.38 ansible_user="ec2-user"

[test]
35.154.48.153 ansible_user="ec2-user"
```

```sh
vim /var/con_dep/main.yml
```
```sh
---
######################### Two Playbooks ###################################

#################### Playbook for building Image ###########################
- name: "Docker Image/Build and Image/Push"
  hosts: build
  become: true
  vars:
    repo_url: "https://github.com/NoelVincent/Continues-Deployment.git"
    repo_dest: "/var/repository/"
    image_name: "noelvincent/flaskapp"
    docker_password: "************" ###===> Your password
  tasks:
    
    - name: "Build-Setp - Docker Installation"
      shell: 'amazon-linux-extras install docker -y'
      args:
       warn: no
 
    - name: "Build-Setp - Additional package Installation"
      yum:
        name: git,python-pip
        state: present

    - name: "Build-Setp - python docker extension installation"
      pip:
        name: docker-py

    - name: "Build-Setp - Docker service restart/enable"
      service:
        name: docker
        state: restarted
        enabled: true

    - name: "Build-Setp - Cloning Repository"
      git:
        repo: "{{ repo_url }}"
        dest: "{{ repo_dest }}"
      register: repo_status

    - name: "Build-Setp - Login to remote Repository"
      when: repo_status.changed == true
      docker_login:
        username: noelvincent
        password: "{{ docker_password }}"

    - name: "Build-Setp - Building image"
      when: repo_status.changed == true
      docker_image:
        source: build
        build:
          path: "{{ repo_dest }}"
          pull: yes
        name: "{{ image_name }}"
        tag: "{{ item }}"
        push: true
        force_tag: yes
        force_source: yes
      with_items:
        - "{{ repo_status.after }}"
        - latest

    - name: "Build-Setp - removing image"
      when: repo_status.changed == true
      docker_image:
        state: absent
        name: "{{ image_name }}"
        tag: "{{ item }}"
      with_items:
        - "{{ repo_status.after }}"
        - latest

#################### Playbook for running the container ###########################
- name: "Docker Run Container"
  hosts: test
  become: true
  vars:
    image_name: "noelvincent/flaskapp"
    
  tasks:
    
    - name: "Deployment - Docker Installation"
      shell: 'amazon-linux-extras install docker -y'
      args:
        warn: no

    - name: "Deployment - Additional package Installation"
      yum:
        name: python-pip
        state: present
        
    - name: "Deployment - python docker extension installation"
      pip:
        name: docker-py

    - name: "Deployment - Docker service restart/enable"
      service:
        name: docker
        state: restarted
        enabled: true

    - name: "Deployment - Run Container"
      docker_container:
        name: webserver
        image: "{{ image_name }}:latest"
        recreate: yes
        pull: yes
        published_ports:
          - "80:5000"
```
