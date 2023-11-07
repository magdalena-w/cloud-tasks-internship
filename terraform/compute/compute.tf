resource "aws_instance" "temp_vm" {
  ami           = "ami-047bb4163c506cd98"
  instance_type = "t2.micro"
  tags = {
    Owner = "mwalesa"
    Project = "2023_internship_wro"
    Name = "temp_vm_terraform_task"
  }
  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    echo "This is webserver" > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
    EOF
}

output "instance_id" {
  value = aws_instance.temp_vm.id
}