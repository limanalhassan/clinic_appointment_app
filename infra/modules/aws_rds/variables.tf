variable "vpc_subnet_ids" {
  description = "Map of subnet IDs by subnet key, used to resolve subnet_keys references."
  type        = map(string)
  default     = {}
}

variable "vpc_security_group_ids" {
  description = "Map of security group IDs by SG key, used to resolve vpc_security_group_keys references."
  type        = map(string)
  default     = {}
}

variable "databases" {
  description = "Map of RDS instance configurations keyed by a logical name."
  type = map(object({
    identifier                     = string
    engine                         = string
    engine_version                 = string
    instance_class                 = string
    allocated_storage              = number
    max_allocated_storage          = number
    storage_type                   = string
    db_name                        = string
    port                           = number
    create_db_subnet_group         = bool
    subnet_keys                    = list(string)
    db_subnet_group_description    = string
    vpc_security_group_keys        = list(string)
    backup_retention_period        = number
    multi_az                       = bool
    publicly_accessible            = bool
    deletion_protection            = bool
    credentials_secret_name        = string
    skip_final_snapshot            = bool
    copy_tags_to_snapshot          = bool
    enable_performance_insights    = bool
    enable_cloudwatch_logs_exports = list(string)
    create_parameter_group         = bool
    parameter_group_family         = string
    parameter_group_description    = string
  }))
  default = {}
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "database_tags" {
  description = "Per-database additional tags, keyed by database key."
  type        = map(map(string))
  default     = {}
}
