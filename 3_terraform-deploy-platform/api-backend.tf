resource "aws_instance" "workshop0001-api-backend" {
  ami                         = data.aws_ami.workshop0001-ngx-plus.id # eu-west-2
  instance_type               = "t2.medium"
  key_name                    = "workshop0001-nginx-server-key"
  security_groups             = [aws_security_group.workshop0001-nginx-web-facing.id]
  subnet_id                   = aws_subnet.workshop0001-main.id
  private_ip                  = "10.0.1.90"


  tags = {
    Name = "workshop0001-nginx-api-backend"
  }

}

resource "null_resource" "api-backend-join-controller" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    trigger1 = aws_route53_record.workshop0001-api-backend.ttl
  }
  
  provisioner "remote-exec" {
  
    connection {
    type     = "ssh"
    user     = "centos"
	private_key = file("~/.ssh/nginx-server-key.pem")
    host     = aws_instance.workshop0001-api-backend.public_ip
  }
  
        inline = [
		"#until sudo apt-get update -y; do sleep 10; done",
		"#until sudo apt-get upgrade -y; do sleep 10; done",
		"sudo sh -c 'echo -n ${ data.local_file.foo.content } >>/etc/hosts'",
		"sudo sh -c 'echo \" controller.workshop0001.nginxdemo.net\" >>/etc/hosts'",
		"ansible-playbook connect_nginx_server_to_controller.yaml",
		"sudo yum install docker -y",
		"sudo systemctl start docker",
		"sudo docker pull bkimminich/juice-shop",
		"sudo docker run --rm -d -p 3000:3000 bkimminich/juice-shop"

    ]
  }
  
}
