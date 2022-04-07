resource "aws_instance" "test_instance" {
  ami = "ami-0c3fd0f5d3313134a76"
  instance_type = "t3.micro"
}