terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "google" {
  credentials = file("glassy-droplet-447812-d6-2351280f0ff1.json")
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow_traffic" {
  name    = "allow-${var.environment}-traffic"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = var.allowed_ports
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.network_tags
}

resource "google_compute_instance" "instance" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.default.self_link
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
  EOT

  tags = var.network_tags
}

data "google_compute_image" "default" {
  family  = var.image_family
  project = var.image_project
}
