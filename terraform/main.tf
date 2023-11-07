provider "aws" {
  region = "eu-west-1"
}

module "compute" {
  source = "./compute"
  vpc_id = module.network.vpc_id
}

module "network" {
  source = "./network"
}

module "load_balancer" {
  source = "./load_balancer"
  vpc_id = module.network.vpc_id
  subnet_ids = module.network.subnet_ids
  lb_sg_id = module.network.lb_sg_id
  tg_sg_id = module.network.tg_sg_id
}