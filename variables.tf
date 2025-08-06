#1 define a CIDR block
variable "region" {
  type = string
  description = "AWS region to deploy resources"
  default = "eu-north-1"
  
}
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