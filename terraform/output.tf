output "masters" {
  value = module.is_instance_masternodes
}

output "lb_ip" {
  value = module.is_lb.lb_ip
}