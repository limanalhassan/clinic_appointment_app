variable "env" {
  description = "The environment (e.g. dev, prod, uat)."
  type        = string
}

variable "config_root" {
  description = "Path to the env folder containing configs/ (pass path.module from the caller)."
  type        = string
}