provider "aws"
{
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}


resource "aws_vpc" "Rahul-TF" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.Rahul-TF.id}"
}


resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.Rahul-TF.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_eip" "tf" {
  vpc      = true
}

resource "aws_subnet" "TF-Pub" {
  vpc_id                  = "${aws_vpc.Rahul-TF.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags {
        Name = "TF-Pub"
  }
}

resource "aws_subnet" "TF-Pvt" {
  vpc_id                  = "${aws_vpc.Rahul-TF.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags {
   Name ="TF-Pvt"
  }
}

resource "aws_subnet" "TF-Pub2" {
  vpc_id                  = "${aws_vpc.Rahul-TF.id}"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
  tags {
        Name = "TF-Pub2"
  }
}

resource "aws_subnet" "TF-Pvt2" {
  vpc_id                  = "${aws_vpc.Rahul-TF.id}"
  cidr_block              = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags {
   Name ="TF-Pvt2"
  }
}


resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.tf.id}"
  subnet_id     = "${aws_subnet.TF-Pub.id}"
}


resource "aws_route_table" "PubRtb" {
  vpc_id = "${aws_vpc.Rahul-TF.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "PubRtb"
  }
}
resource "aws_route_table" "PvtRtb" {
  vpc_id = "${aws_vpc.Rahul-TF.id}"

  route {
    cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.gw.id}"
 }

  tags {
    Name = "main"
  }
}


resource "aws_route_table_association" "a" {
  subnet_id         = "${aws_subnet.TF-Pub.id}"
  route_table_id = "${aws_route_table.PubRtb.id}"
}

resource "aws_route_table_association" "b" {
  subnet_id         = "${aws_subnet.TF-Pub2.id}"
  route_table_id = "${aws_route_table.PubRtb.id}"
}

resource "aws_route_table_association" "c" {
  subnet_id         =  "${aws_subnet.TF-Pvt.id}"
  route_table_id =  "${aws_route_table.PvtRtb.id}"
}

resource "aws_route_table_association" "d" {
  subnet_id         =  "${aws_subnet.TF-Pvt2.id}"
  route_table_id = "${aws_route_table.PvtRtb.id}"
}

resource "aws_security_group" "SG4TF" {
  name        = "SG4TF"
  vpc_id      = "${aws_vpc.Rahul-TF.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["72.196.48.126/32"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["72.196.48.126/32"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "SG4TF-Pvt" {
  name        = "SG4TF-Pvt"
  vpc_id      = "${aws_vpc.Rahul-TF.id}"

 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_network_interface" "net_interface" {
subnet_id = "${aws_subnet.TF-Pub.id}"
security_groups = [ "${aws_security_group.SG4TF.id}" ]
}

resource "aws_network_interface" "net_interface2" {
subnet_id = "${aws_subnet.TF-Pub2.id}"
security_groups = [ "${aws_security_group.SG4TF.id}" ]
}


resource "aws_instance" "Bitnami" {

  instance_type = "t2.micro"

  ami = "ami-89f68a9f"

  key_name =  "Rahul"

  tags {

 Name = "Rahul-Tf-Bnami"
 Project = "learning"
 Owner = "rahul.perumandla"
 Environment = "dev"
 NoShutdown = "yes"
}


 network_interface {
network_interface_id = "${aws_network_interface.net_interface.id}"
device_index = 0
}

ebs_block_device {
device_name = "/dev/sda1"
volume_type = "io1"
volume_size = 10
iops = 100
}

}

resource "aws_instance" "LAMP"
 {

 instance_type = "t2.micro"

 ami = "ami-a4c7edb2"

 key_name =  "Metron"

 tags {

 Name = "Rahul-Tf-LAMP"
 Project = "learning"
 Owner = "rahul.perumandla"
 Environment = "dev"
 NoShutdown = "yes"
}

 network_interface {
 network_interface_id = "${aws_network_interface.net_interface2.id}"
 device_index = 0
 }


ebs_block_device {
device_name = "/dev/sdm"
volume_type = "io1"
volume_size = 10
iops = 100
}

user_data = "${data.template_file.user_data_shell.rendered}"
        tags {
                        Name = "Rahul-LAMP"
        }
}

data "template_file" "user_data_shell" {
        template = <<-EOF
                   #!/bin/bash
                   sudo yum -y update
                   cd /home/ec2-user
                   curl -L https://www.opscode.com/chef/install.sh | sudo bash
                   sudo yum -y install git
                   sudo git clone https://github.com/RahulPerumandla/chef-cft.git
                   cd chef-cft
                   sudo chef-solo -c solo.rb -j lamp.json
                   sudo echo '<?php phpinfo(); ?>' > /var/www/html/phpinfo.php
                   EOF
}
