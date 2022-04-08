resource "aws_instance" "test_instance" {
  ami = "ami-0521a4a0a1329ff86"
  instance_type = "t3.micro"
  tags = {
    Name = "hoge_instance"
  }
  user_data = <<EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd.service
EOF
}