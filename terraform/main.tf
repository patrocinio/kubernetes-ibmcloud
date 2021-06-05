provider "ibm" {
  region = "${var.CLOUD_REGION}"
}

# https://cloud.ibm.com/docs/vpc?topic=solution-tutorials-vpc-public-app-private-backend

# Documentation: https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-vpc-gen2-resources

data "ibm_is_images" "ds_images" {
}

module "kube_base" {
  source = "./modules/kube_base"

  RESOURCE_PREFIX = var.RESOURCE_PREFIX
  SSH_PUBLIC_KEY  = var.SSH_PUBLIC_KEY
  zone            = var.zone
}


module "is_instance_masters" {
  source = "./modules/is_instance"

  name                = "${var.RESOURCE_PREFIX}-master"
  num_instances       = var.NUM_MASTERS
  resource_group      = module.kube_base.resource_group_id
  subnet_id           = module.kube_base.subnet_id
  security_group_id   = module.kube_base.security_group_id
  vpc_id              = module.kube_base.vpc_id
  ssh_key_id          = module.kube_base.ssh_key_id
  zone                = var.zone
}

module "is_instance_workers" {
  source = "./modules/is_instance"

  name                = "${var.RESOURCE_PREFIX}-worker"
  num_instances       = var.NUM_WORKERS
  resource_group      = module.kube_base.resource_group_id
  subnet_id           = module.kube_base.subnet_id
  security_group_id   = module.kube_base.security_group_id
  vpc_id              = module.kube_base.vpc_id
  ssh_key_id          = module.kube_base.ssh_key_id
  zone                = var.zone
}

module "is_lb_pool_member" {
  source = "./modules/is_lb_pool_member"

  lb_pool_id        = module.kube_base.lb_pool_id
  lb_id             = module.kube_base.lb_id
  masters           = module.is_instance_masters.instances
}

