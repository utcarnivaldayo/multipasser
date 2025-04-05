# resource "aws_key_pair" "ec2_ssh_key" {
#  key_name   = var.key_name
#  public_key = "${var.public_key}"
# }

resource "aws_instance" "cms" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ssh_sg.id, aws_security_group.http_sg.id]
  subnet_id = aws_subnet.public_subnet_1a.id
  # key_name = aws_key_pair.ec2_ssh_key.key_name
  user_data = file(var.cloud_init_file)
  tags = {
    Name = "${var.environment}-${var.project}-${var.owner}-common-cms:${var.branch}"
  }

  root_block_device {
    volume_size = 30 # 単位GB
    volume_type = "gp3"
  }

  lifecycle {
    ignore_changes = [
      # インスタンスに変更を加えようとしたら、AMIが新しくなっていてインスタンス再作成が要求されるのを防止
      ami
    ]
  }
}
