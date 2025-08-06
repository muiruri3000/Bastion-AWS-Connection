
provider "aws" {
  region = "eu-north-1"
}

#1 define a CIDR block
variable "cidr_block" {
  default = "10.0.0.0/16"
  
}
#my IP address
variable "my_ip" {
 type = string
 description = "My IP address for SSH access"
 default = "102.0.0.242/32"
}

#list of availability zones
variable "azs" {
  default = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  description = "values for availability zones"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
 
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners =["137112412989"] 
}


#2 create a VPC with the CIDR block defined above
resource "aws_vpc" "main_vpc" {
  cidr_block = var.cidr_block

enable_dns_hostnames = true
enable_dns_support = true
instance_tenancy = "default"
  tags = {
    Name = "main_vpc"
  }  
}

#3 create Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}
#4 create public subnets

resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone = var.azs[count.index]
    map_public_ip_on_launch = true


    tags = {
        Name = "public_subnet_${count.index + 1}"
        Tier = "Public"
    }


}

#5 create private subnets
resource "aws_subnet" "Private" {
    vpc_id = aws_vpc.main_vpc.id
    count = 2
    cidr_block = cidrsubnet(var.cidr_block, 8, count.index + 2)
    availability_zone = var.azs[count.index]
  
    tags = {
        Name = "private_subnet_${count.index + 1}"
        Tier = "Private"
    }
}

#6 create a route table for public subnets
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main_vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main_igw.id

      

    }
      tags = {
            Name = "public_rt"
        }
}

#7 associate the public route table with the public subnets
resource "aws_route_table_association" "public_association" {
    count = 2
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public_rt.id
}


#11 create a NAT Gateway in the public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id = aws_subnet.public[0].id   
tags = {
  Name = "nat_gw-1"
}

depends_on = [ aws_internet_gateway.main_igw, aws_eip.nat_eip[0] ]
}

#8 create a route table for private subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw.id
    }
  tags = {
    Name = "private_rt"
  }
}

#9 associate the private route table with the private subnets
resource "aws_route_table_association" "private_association" {
  count = 2
  subnet_id = aws_subnet.Private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
#10 allocate an Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip"  {
  
  count = 1
  tags = {
    Name = "nat_eip-${count.index + 1}"
  }
  
}

#12 create key pair for bastion host
resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion_key"
  public_key = file("~/.ssh/id_rsa.pub") 
}

#13 create a security group for the bastion host
resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main_vpc.id



    tags = {
        Name = "bastion_sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.bastion_sg.id
  
  from_port         = 22
  to_port           = 22
  ip_protocol          = "tcp"
  cidr_ipv4      = var.my_ip
  description       = "Allow SSH from bastion host"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_to_my_ip" {
  security_group_id = aws_security_group.private_ec2_sg.id
  depends_on = [ aws_security_group.private_ec2_sg ]
  ip_protocol          = "-1"
  cidr_ipv4       = "0.0.0.0/0"

  
}

#14 create a bastion host in the public subnet
resource "aws_instance" "bastion_host" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[0].id
  key_name      = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  tags = {
        Name = "bastion_host"
    }
}

#15 create a security group for the private EC2 instances

resource "aws_security_group" "private_ec2_sg" {
  name        = "private_ec2_sg"
  description = "Security group for private EC2 instances"
  vpc_id      = aws_vpc.main_vpc.id


  tags = {
    Name = "private_ec2_sg"
  }
  
}

#create ec2 instance in the private subnet
resource "aws_instance" "private_instance" {
    ami          = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    subnet_id     = aws_subnet.Private[0].id
    key_name      = aws_key_pair.bastion_key.key_name
    vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]
    tags = {
        Name = "private_instance"   
    
}

}
#15 create a security group for the private instances

resource "aws_vpc_security_group_ingress_rule" "allow_bastion" {
  security_group_id = aws_security_group.private_ec2_sg.id
referenced_security_group_id = aws_security_group.bastion_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  
  description       = "Allow SSH from bastion host"
}

output "bastion_host" {
  value = aws_instance.bastion_host.public_ip
}

output "private_instance" {
  value = aws_instance.private_instance.private_ip
  
}