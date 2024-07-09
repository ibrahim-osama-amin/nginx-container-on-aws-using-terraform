provider "aws" {
     region = "eu-west-3"
}

# Variables
variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}

#VPC
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

#Subnet
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-subnet-1"
    }
}

#Route table
resource "aws_route_table" "myapp-route-table"{
    vpc_id = aws_vpc.myapp-vpc.id

    route { 
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp_igw.id
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}

#Internet Gateway
resource "aws_internet_gateway" "myapp_igw"{
    vpc_id = aws_vpc.myapp-vpc.id
        tags = {
        Name: "${var.env_prefix}-igw"
    }
}

#Associating a subnet to the route table 
resource "aws_route_table_association" "a-rtb-subnet"{
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
}

#security group creation
resource "aws_security_group" "myapp-sg"{
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
        ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
        tags = {
        Name: "${var.env_prefix}-sg"
    }
}

#read the most Amazon linux image code
data "aws_ami" "latest-amazon-linux-image"{
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
    }
}

# just to confirm our read is yielding the correct image
output "aws_ami_id"{
    value = data.aws_ami.latest-amazon-linux-image.id
}

#key creation

resource "aws_key_pair" "ssh-key"{
    key_name = "server-key"
    public_key = file(var.public_key_location)
}

#EC2 creation

resource "aws_instance" "myapp-server"{
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address  = true 
    key_name = aws_key_pair.ssh-key.key_name
    
    user_data = file ("entry-script.sh")


    tags = {
        Name = "${var.env_prefix}-server"
    }

    
}