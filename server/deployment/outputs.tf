output "public_instance_id" {
  value = aws_instance.monitoring_server.id
}

output "public_instance_ip" {
  value = aws_instance.monitoring_server.public_ip
}
