# Used for configuring ELBs.
output "instance_ids" {
    value = ["${aws_instance.instances.*.id}"]
}
