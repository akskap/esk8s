data "template_file" "init" {
  template = "${file("${path.module}/setup.sh")}"
}

resource "aws_instance" "esk8s_instance" {
  ami                         = "${var.instance_ami_id}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = true
  tags                        = "${var.instance_tags}"
  subnet_id                   = "${var.instance_subnet_id}"
  vpc_security_group_ids      = ["${aws_security_group.esk8s_instance_sg.id}"]
  user_data                   = "${data.template_file.init.rendered}"
  key_name                    = "${var.instance_key_name}"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = 200
  }
}

resource "aws_security_group" "esk8s_instance_sg" {
  vpc_id = "${var.instance_vpc_id}"
  name_prefix   = "esk8s_instance_sg"
}

resource "aws_security_group_rule" "esk8s_sg_ingress_1" {
  from_port         = 0
  protocol          = "All"
  security_group_id = "${aws_security_group.esk8s_instance_sg.id}"
  to_port           = 65535
  type              = "ingress"
  cidr_blocks       = ["92.218.249.130/32"]
}

resource "aws_security_group_rule" "esk8s_sg_ingress_2" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.esk8s_instance_sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_egress" {
  from_port         = -1
  protocol          = "All"
  security_group_id = "${aws_security_group.esk8s_instance_sg.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = -1
  type              = "egress"
}

provider "aws" {
  region  = "eu-central-1"
  profile = "onelogin"
}

