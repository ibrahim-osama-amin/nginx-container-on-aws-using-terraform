#!/bin/bash
sudo dnf update -y && sudo dnf install docker -y
sudo systemctl start docker
sudo usermod -aG docker ec2-user
newgrp docker
docker run -d -p 8080:80 nginx
