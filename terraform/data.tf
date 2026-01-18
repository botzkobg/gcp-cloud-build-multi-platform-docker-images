data "google_artifact_registry_repository" "docker"  {
  location      = ""
  repository_id = ""
}

data "google_service_account" "clound_build_sa" {
  account_id = ""
}

data "google_compute_subnetwork" "default" {
  name = ""
  region = ""
}
