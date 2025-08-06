# Terraform AWS VPC Setup with Bastion Host and Private EC2

This Terraform project provisions a secure AWS Virtual Private Cloud (VPC) with the following architecture:

- A VPC with public and private subnets across two availability zones
- A Bastion Host (EC2) in the public subnet for SSH access
- A private EC2 instance in the private subnet
- Security groups to restrict access:
  - Bastion SG: allows inbound SSH from a trusted IP
  - Private EC2 SG: allows SSH only from the Bastion host

## 📦 Resources Created

- VPC
- Internet Gateway
- Public and Private Subnets
- Route Tables and Associations
- EC2 Instances:
  - Bastion (public subnet)
  - Private instance (private subnet)
- Security Groups
  - With ingress and egress rules
- Elastic IP for NAT Gateway
- NAT Gateway for private subnet internet access

## 📁 Project Structure

