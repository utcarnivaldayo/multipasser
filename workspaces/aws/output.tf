
# パブリックIPを出力
output "public_ip" {
  value = aws_instance.cms.public_ip
}

# sshコマンドを出力
output "ssh_command" {
  value = "ssh ec2-user@${aws_instance.cms.public_ip}"
}
