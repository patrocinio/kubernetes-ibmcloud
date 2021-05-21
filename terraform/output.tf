/*
output "masters" {
  value = module.is_instance_masters
}

output "workers" {
  value = module.is_instance_workers
}

output "lb_hostname" {
  value = module.is_lb.lb_hostname
}

output "lb_id" {
  value = module.is_lb.lb_id
}

output "lb_pool_id" {
  value = module.is_lb.lb_pool_id
}

output "first_master_ip" {
  value = module.is_instance_masters.instances[0].primary_network_interface[0].primary_ipv4_address
}
*/