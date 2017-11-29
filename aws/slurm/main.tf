//  Setup the core provider information.
provider "aws" {
  region  = "${var.region}"
}

resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "Main VPC"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.vpc_main.id}"
}

resource "aws_route" "internet_access" {
  route_table_id          = "${aws_vpc.vpc_main.main_route_table_id}"
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = "${aws_internet_gateway.default.id}"
}

# Create a public subnet to launch our load balancers
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.vpc_main.id}"
  cidr_block              = "10.0.1.0/24" # 10.0.1.0 - 10.0.1.255 (256)
  map_public_ip_on_launch = true
}

# Create a private subnet to launch our backend instances
resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.vpc_main.id}"
  cidr_block              = "10.0.16.0/24" # 10.0.16.0 - 10.0.31.255 (4096)
  map_public_ip_on_launch = true
}


# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "sec_group_elb"
  description = "Security group for public facing ELBs"
  vpc_id      = "${aws_vpc.vpc_main.id}"

  # HTTP access from anywhere
  #ingress {
  #  from_port   = 80
  #  to_port     = 80
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "sec_group_private"
  description = "Security group for backend servers and private ELBs"
  vpc_id      = "${aws_vpc.vpc_main.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all from private subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  # ping access from anywhere
  ingress {
     from_port = 8
     to_port = 0
     protocol = "icmp"
     cidr_blocks = ["0.0.0.0/0"]
   }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "qnib-terraform"
  public_key = "${file(var.public_key_path)}"
}

module "master" {
    source                  = "./instance"
    subnet_id               = "${aws_subnet.private.id}"
    key_pair_id             = "${aws_key_pair.auth.id}"
    security_group_id       = "${aws_security_group.default.id}"
    ami_name                = "ami-8ffe61f5" //aws-docker-slurm 1511970730
    instance_type           = "t2.micro"
    count                   = 1
    private_ip              = "10.0.16.10"
    group_name              = "master"
    provisioner_remote_exec = "sudo systemctl disable slurmd && echo master |sudo tee /opt/slurm-type"
}

module "login" {
    source                  = "./instance"
    subnet_id               = "${aws_subnet.private.id}"
    key_pair_id             = "${aws_key_pair.auth.id}"
    security_group_id       = "${aws_security_group.default.id}"
    ami_name                = "ami-8ffe61f5" //aws-docker-slurm 1511970730
    instance_type           = "t2.micro"
    count                   = 1
    private_ip              = "10.0.16.40"
    group_name              = "login"
    provisioner_remote_exec = "sudo systemctl disable slurmctld slurmd && echo login |sudo tee /opt/slurm-type"
}

module "cpu" {
    source                  = "./instances"
    subnet_id               = "${aws_subnet.private.id}"
    key_pair_id             = "${aws_key_pair.auth.id}"
    security_group_id       = "${aws_security_group.default.id}"
    ami_name                = "ami-8ffe61f5" //aws-docker-slurm 1511970730
    instance_type           = "t2.medium"
    count                   = 3
    group_name              = "cpu"
    provisioner_remote_exec = "sudo systemctl disable slurmctld && echo client |sudo tee /opt/slurm-type"
}

module "gpu" {
    source                  = "./instance"
    subnet_id               = "${aws_subnet.private.id}"
    key_pair_id             = "${aws_key_pair.auth.id}"
    security_group_id       = "${aws_security_group.default.id}"
    ami_name                = "ami-6f2ebd15" //aws-docker-gpu-slurm 1511815842
    instance_type           = "p2.xlarge"
    private_ip              = "10.0.16.30"
    group_name              = "gpu"
    provisioner_remote_exec = "sudo systemctl disable slurmctld && echo client |sudo tee /opt/slurm-type"
}
