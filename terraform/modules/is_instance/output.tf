output "floating_ips" {
    value = ibm_is_floating_ip.fip
}

output "instances" {
    value = ibm_is_instance.is_instance
}
