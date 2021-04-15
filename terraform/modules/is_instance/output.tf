output "floating_ips" {
    value = ibm_is_floating_ip.fip
//  value = ibm_is_floating_ip.fip.address
}

output "instances" {
    value = ibm_is_instance.is_instance
//  value = ibm_is_instance.is_instance[0].primary_network_interface.0.primary_ipv4_address
}
