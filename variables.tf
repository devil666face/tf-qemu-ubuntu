variable "source_disk_path" {
  description = "Path to the source qcow2 disk"
  default     = "https://cloud-images.ubuntu.com/noble/20250805/noble-server-cloudimg-amd64.img"
}

variable "source_pool_path" {
  description = "Path to pool"
  default     = "/path/to/pool"
}

variable "ip_address" {
  type    = string
  default = "192.168.200.20"
}

variable "hostname" {
  type    = string
  default = "ubuntu01"
}

variable "disk_size" {
  type    = string
  default = "32G"
}
