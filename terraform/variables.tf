variable "service_account_key_file" {
  description = "Auth key file path"
  type = string
  default = "secret.authorized_key.json"
  sensitive = true
}

variable "server_name" {
  description = "Instance name"
  type        = string
  default = "test"
}

variable "server_zone" {
  description = "Instance yandex cloud zone"
  type        = string
  default     = "ru-central1-d"
}

variable "node_cpu" {
  description = "Instance CPU cores"
  type        = number
  default     = "2"
}

variable "node_ram" {
  description = "Instance RAM memory resource"
  type        = number
  default     = "4"
}

variable "yc_folder_id" {
  description = "Working folder id"
  type        = string
}

variable "yc_cloud_id" {
  description = "Working cloud id"
  type        = string
}

variable "node_disk_size" {
  description = "Disk size for worker k8s node"
  type = number
  default = 30
}

variable "kubernetes_version" {
  description = "Stable kubernetes version"
  type = string
  default = "1.33"
}

variable "node_platform_id" {
  description = "Node group standart platform"
  type        = string
  default     = "standard-v3"
}

variable "node_count" {
  type        = number
  default     = 1
  description = "Count kubernetes worker nodes"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "bulletin_board"
}

variable "db_user" {
  description = "PostgreSQL application user"
  type        = string
  default     = "bulletin_app"
}