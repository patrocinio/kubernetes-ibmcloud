
resource "ibm_is_lb" "is_lb" {
  name = var.name
  subnets = [var.subnet_id]
}

resource "ibm_is_lb_pool" "is_lb_pool" {
  name           = var.name
  lb             = ibm_is_lb.is_lb.id
  algorithm      = "round_robin"
  protocol       = "https"
  health_delay   = 60
  health_retries = 5
  health_timeout = 30
  health_type    = "https"
  proxy_protocol = "v1"
}
