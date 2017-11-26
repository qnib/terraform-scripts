resource "aws_instance" "instances" {
  count                  = "${var.count}"

  instance_type          = "${var.instance_type}"
  ami                    = "${var.ami_name}"
  key_name               = "${var.key_pair_id}"
  vpc_security_group_ids = ["${var.security_group_id}"]
  subnet_id              = "${var.subnet_id}"
  private_ip             = "${lookup(var.ips_pool,count.index)}"

  tags {
      Name = "${format("%s%1d", var.group_name, count.index)}" # -> "master0"
      Group = "${var.group_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  # Provisioning

  connection {
    user = "ubuntu"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostname -b ${format("%s%1d", var.group_name, count.index)}",
      "${var.provisioner_remote_exec}",
    ]
  }
}
