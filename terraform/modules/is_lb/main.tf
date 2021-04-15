
resource "ibm_is_lb" "is_lb" {
  name = var.name
  profile = "network-fixed"
  subnets = [var.subnet_id]
}
