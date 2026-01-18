# Create a router to allow the VM to access the Internet
resource "google_compute_router" "router" {
  name    = "vm-router"
  region  = local.region
  network = data.google_compute_subnetwork.default.network
}
# Allow the VM to access the Internet
resource "google_compute_router_nat" "nat" {
  name                               = "vm-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = data.google_compute_subnetwork.default.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

