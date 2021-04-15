output "ipaddress_master01_floating" {
  value = module.is_instance_masternodes.floating_ip
}


output "ipaddress_master01_private" {
  value = module.is_instance_masternodes.private_ip
}

output "lb_ips" {
  value = module.is_lb.lb_ips
}