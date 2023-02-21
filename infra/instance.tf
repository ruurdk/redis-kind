resource "google_compute_instance" "node1" {
  name         = "${var.yourname}-${var.env}-1"
  machine_type = var.machine_type
  zone         = "${var.region_name}-b" //TODO
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-1804-lts"
      size = 30 //GB
    }
  }
  labels = {
    owner = var.yourname
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/google_compute_engine.pub")}"
    startup-script = templatefile("${path.module}/scripts/instance.sh", {
      cluster_dns = "cluster.${var.yourname}.${var.dns_zone_dns_name}",
      node_id  = 1
      node_1_ip   = ""
      kind_release = var.kind_release
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_dns_record_set" "node1" {
  name = "node1.${var.yourname}.${var.dns_zone_dns_name}."
  type = "A"
  ttl  = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.node1.network_interface.0.access_config.0.nat_ip]
}

resource "google_dns_record_set" "name_servers" {
  name = "cluster.${var.yourname}.${var.dns_zone_dns_name}."
  type = "NS"
  ttl  = 60
  managed_zone = var.dns_managed_zone

  rrdatas = flatten([local.n1])
}

locals {
  n1 = google_dns_record_set.node1.name
} 

resource "random_password" "password" {
  length           = 12
  special          = true
  override_special = "_"
}
