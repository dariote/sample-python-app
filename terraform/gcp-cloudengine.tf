provider "google" {

    credentials = file("terraform-sa-key.json")
    project = var.gcp_project_id
    region = "us-central1"
    zone = "us-central1-c"
    # version = "~> 3.38"
}

#IP ADDRESS
resource "google_compute_address" "ip_address" {
  name = "app-ip-${terraform.workspace}"
}
#NETWORK

data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_network" "default" {
  name = "default"
  auto_create_subnetworks = true
  description = "Default network for the project"
}
#FIREWALL RULE
resource "google_compute_firewall" "allow-http" {
  name    = "allow-http-${terraform.workspace}"
  network = google_compute_network.default.name

#   allow {
#     protocol = "icmp"
#   }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["allow-http-${terraform.workspace}"]
}

# resource "google_compute_network" "default" {
#   name = "test-network"
# }

#OS IMAGE

data "google_compute_image" "cos_image" {
  family  = "cos-85-lts"
  project = "cos-cloud"
}

#COMPUTE ENGINE INSTANCE

resource "google_compute_instance" "instance" {
  name         = "${var.app_name}-vm-${terraform.workspace}"
  machine_type = var.gcp_machine_type
  zone         = "us-central1-a"

  tags = google_compute_firewall.allow-http.target_tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos_image.self_link
    }
  }

  // Local SSD disk if caching
#   scratch_disk {
#     interface = "SCSI"
#   }

  network_interface {
    network = data.google_compute_network.default.name

    access_config {
      nat_ip = google_compute_address.ip_address.address
    }
  }

#   metadata = {
#     foo = "bar"
#   }

#   metadata_startup_script = "echo hi > /test.txt"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    scopes = ["storage-ro"]
  }
}

