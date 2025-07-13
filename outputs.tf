output "ec2_public_ip" {
  value = aws_instance.python_ec2.public_ip
}

output "key_file_location" {
  value = local_file.private_key.filename
}