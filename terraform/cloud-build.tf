# Give the Cloud Build service account permission to use the IAP
resource "google_project_iam_member" "ubuntu_docker_sa_iam_iap_tunnelResourceAccessor" {
  project = google_compute_instance.ubuntu_docker_vm.project
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${data.google_service_account.clound_build_sa.email}"
}

# Give the Cloud Build service account role `roles/compute.viewer`, required by IAP to create connections without an IP address
resource "google_project_iam_member" "ubuntu_docker_sa_iam_compute_viewer" {
  project = google_compute_instance.ubuntu_docker_vm.project
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${data.google_service_account.clound_build_sa.email}"
}