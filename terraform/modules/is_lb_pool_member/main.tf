resource "ibm_is_lb_pool_member" "testacc_lb_mem" {
  lb             =  var.lb_id
  pool           = var.lb_pool_id
  port           = 6443
  target_id      = var.masters[0].id
  weight         = 60
}
