output "masters" {
  value = module.is_instance_masternodes
}

output "lb_ip" {
  value = module.is_lb.lb_ip
}

output "lb_id" {
  value = module.is_lb.lb_id
}

output "lb_pool_id" {
  value = module.is_lb.lb_pool_id
}
