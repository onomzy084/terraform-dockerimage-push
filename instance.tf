resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "terraform-key"

  tags = {
    Name = "docker server"
  }
}

resource "null_resource" "name" {
  connection {
    type = "ssh"
    host = aws_instance.ec2_instance.public_ip
    user = "ec2-user"
    password = ""
    private_key = file("private-key/terraform-key.pem")
  }

  # copy the password file for your docker hub account
  # from your computer to the ec2 instance 
  provisioner "file" {
    source      = "~/Downloads/my_password.txt"
    destination = "/home/ec2-user/my_password.txt"
  }

  # copy the dockerfile from your computer to the ec2 instance 
  provisioner "file" {
    source      = "Dockerfile"
    destination = "/home/ec2-user/Dockerfile"
  }

  # copy the build_docker_image.sh from your computer to the ec2 instance 
  provisioner "file" {
    source      = "build_docker_image.sh"
    destination = "/home/ec2-user/build_docker_image.sh"
  }

  # set permissions and run the build_docker_image.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/ec2-user/build_docker_image.sh",
      "sh /home/ec2-user/build_docker_image.sh",
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.ec2_instance]
}

