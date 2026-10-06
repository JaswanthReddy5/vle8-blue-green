output "instance_id" {
  value = aws_instance.jenkins.id
}

output "public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "security_group_id" {
  value = aws_security_group.jenkins_sg.id
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "app_url" {
  value = "http://${aws_instance.jenkins.public_ip}"
}
