
resource "ibm_is_lb" "is_lb" {
  name            = var.name
  subnets         = [var.subnet_id]
  resource_group  = var.resource_group
  security_groups   = [var.security_group_id]
}

resource "ibm_is_lb_pool" "is_lb_pool" {
  name           = var.name
  lb             = ibm_is_lb.is_lb.id
  algorithm      = "round_robin"
  protocol       = "tcp"
  health_delay   = 60
  health_retries = 5
  health_timeout = 30
  health_type    = "tcp"
}

resource "null_resource" "is_target_region" {
    provisioner "local-exec" {
      command = "ibmcloud target -r us-south"
    }
}

resource "null_resource" "is_lb_listener" {
    provisioner "local-exec" {
      command = "ibmcloud  is lb-lc ${ibm_is_lb.is_lb.id} 6443 tcp --default-pool ${ibm_is_lb_pool.is_lb_pool.pool_id}"
    }
}
/*
resource "ibm_is_lb_listener" "is_lb_listener" {
  lb                    = ibm_is_lb.is_lb.id
  port                  = 6443
  protocol              = "https"
  certificate_instance  = 
}
*/




