
output "bastion_host" {
  value = aws_instance.bastion_host.public_ip
}

output "private_instance" {
  value = aws_instance.private_instance.private_ip
  
}