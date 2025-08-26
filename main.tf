terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "tf" {
  name = "tf"
  type = "dir"
  target {
    path = var.source_pool_path
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/cloudinit.cfg")
}

data "template_file" "network_data" {
  template = file("${path.module}/network.cfg")
  vars = {
    ip_address = var.ip_address
  }
}

resource "libvirt_cloudinit_disk" "ubuntu_cloudinit" {
  name           = "ubuntu01.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_data.rendered
  pool           = libvirt_pool.tf.name
}

resource "libvirt_volume" "ubuntu" {
  name   = "ubuntu01.qcow2"
  pool   = libvirt_pool.tf.name
  source = var.source_disk_path
  format = "qcow2"
}

resource "null_resource" "resize_volume" {
  provisioner "local-exec" {
    command = <<EOT
      sudo qemu-img resize ${libvirt_volume.ubuntu.id} ${var.disk_size}
    EOT
  }

  depends_on = [libvirt_volume.ubuntu]
}

resource "libvirt_domain" "ubuntu" {
  name       = var.hostname
  memory     = "2048"
  vcpu       = "2"
  autostart  = true
  qemu_agent = true

  cloudinit = libvirt_cloudinit_disk.ubuntu_cloudinit.id

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.ubuntu.id
  }

  boot_device {
    dev = ["hd"]
  }

  network_interface {
    hostname     = var.hostname
    network_name = "default"
    bridge       = "virbr0"
    addresses = [
      var.ip_address,
    ]
    mac            = "52:54:00:7e:48:80"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  depends_on = [null_resource.resize_volume]
}

output "ubuntu" {
  value = libvirt_domain.ubuntu.network_interface[0].addresses[0]
}
