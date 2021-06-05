resource "ibm_is_lb_pool_member" "testacc_lb_mem" {
  count          = length(var.masters)
  lb             =  var.lb_id
  pool           = var.lb_pool_id
  port           = 6443
  target_address = var.masters[count.index].primary_network_interface[0].primary_ipv4_address
  weight         = 60
}
