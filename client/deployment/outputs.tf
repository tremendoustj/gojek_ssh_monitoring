output "public_instance_id" {
  value = aws_instance.client_instance.*.id
}

output "public_instance_ip" {
  value = aws_instance.client_instance.*.public_ip
}
