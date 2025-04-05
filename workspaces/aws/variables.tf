
variable "project" {
  type        = string
  description = "project name"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "cms envrironment"
}

variable "owner" {
  type        = string
  description = "owner name"
}

variable "branch" {
  type        = string
  default = "unknown"
  description = "branch name"
}

variable "region" {
  type        = string
  default     = "ap-northeast-1"
  description = "aws region"
}

variable "ami" {
  type        = string
  default     = "ami-0a0b7b240264a48d7"
  description = "aws ec2 instance image"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "aws instance type"
}

variable "key_name" {
  type        = string
  description = "aws key pair name"
}

variable "public_key" {
  type        = string
  # default = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBACMgKGQkzed1UAaxdfECKJNEgNR/AmTstSwoZLauEcZXGlgHaQe5gKiVTPq8ppUOsHp/QJP6oUJtmeVz2GGubUVCwC8taY8f8m271PJ9J0uiBI4UXTxK86B4cdvTaY8WHdVFlJdi5qhP1M3fuyVf5oYZoS1S9o1PI3uGdIj+y3Sih0goQ== 2024-08-18T02:27:03+09:00-aarch64-apple-darwin-ut.local"
  description = "public key"
}

variable "cloud_init_file" {
  type        = string
  description = "cloud init file"
}
