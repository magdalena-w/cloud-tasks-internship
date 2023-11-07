variable "vpc_id" {
  description = "ID of the VPC where the compute resources will be created"
}

variable "subnet_ids" {
  description = "ID of the Subnets where the compute resources will be created"
}

variable "lb_sg_id" {
    description = "ID of the Security Group for loadbalancer"
}

variable "tg_sg_id" {
    description = "ID of the Security Group for Target Group"
}