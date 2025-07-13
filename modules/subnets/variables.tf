variable "vpc_id" {}
variable "public_subnet_cidrs" {
  type = list(string)
}
variable "azs" {
  type = list(string)
}