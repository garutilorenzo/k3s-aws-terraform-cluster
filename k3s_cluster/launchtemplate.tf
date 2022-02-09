resource "aws_launch_template" "k3s_server" {
  name_prefix   = "k3s_server_tpl"
  image_id      = var.AMIS[var.AWS_REGION]
  instance_type = var.default_instance_type
  user_data     = data.template_cloudinit_config.k3s_server.rendered

  iam_instance_profile {
    name = var.instance_profile_name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      encrypted   = true
    }
  }

  key_name = aws_key_pair.my_ssh_public_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow-strict.id]
  }
}

resource "aws_launch_template" "k3s_agent" {
  name_prefix   = "k3s_agent_tpl"
  image_id      = var.AMIS[var.AWS_REGION]
  instance_type = var.default_instance_type
  user_data     = data.template_cloudinit_config.k3s_agent.rendered

  iam_instance_profile {
    name = var.instance_profile_name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      encrypted   = true
    }
  }

  key_name = aws_key_pair.my_ssh_public_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow-strict.id]
  }
}