resource "aws_security_group" "security_group_for_ec2" {
  name = "security_group_for_ec2"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress = [ {
    from_port = 0 
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  } ]
}

resource "aws_instance" "test_instance" {
  ami = "ami-0521a4a0a1329ff86"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.security_group_for_ec2.id]
  tags = {
    Name = "hoge_instance"
  }
  user_data = <<EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd.service
EOF
}

output "example_public_dns" {
  value = aws_instance.test_instance.public_dns
}