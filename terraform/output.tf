output "ipaddress_master01_floating" {
  value = module.is_instance_master01.floating_ip
}


output "ipaddress_master01_private" {
  value = module.is_instance_master01.private_ip
}