output "lb_ip" {
  value = ibm_is_lb.is_lb.public_ips[0]
}

