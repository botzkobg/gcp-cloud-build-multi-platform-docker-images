# Create service account to be used by the VM
resource "google_service_account" "ubuntu_docker_sa" {
  project = google_compute_instance.ubuntu_docker_vm.project
  account_id   = "ubuntu-docker"
  display_name = "VM Service Account (docker)"
  description  = "Account used by VM to access the GCP docker repository"
}
# Give the VM service account the role `roles/iam.serviceAccountUser`
resource "google_project_iam_member" "ubuntu_docker_sa_iam_serviceAccountUser" {
  project = google_compute_instance.ubuntu_docker_vm.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.ubuntu_docker_sa.email}"
}
# Give the VM service account permission to push images to the GCP Docker Artifact Registry
resource "google_artifact_registry_repository_iam_member" "ubuntu_docker_sa_iam_cloud_build_artifactregistry_writer" {
  project    = data.google_artifact_registry_repository.docker.project
  location   = data.google_artifact_registry_repository.docker.location
  repository = data.google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ubuntu_docker_sa.email}"
}

# Create the arm64 VM
resource "google_compute_instance" "ubuntu_docker_vm" {
  name         = "ubuntu-docker-vm"
  machine_type = "c4a-standard-2" # Arm-based Axion processor
  zone         = local.defaults.zone

  boot_disk {
    initialize_params {
      # Use arm64 image for c4a (Arm) machine types
      image = "ubuntu-os-cloud/ubuntu-2404-lts-arm64"
    }
  }

  network_interface {
    network = data.google_compute_subnetwork.default.name
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Update and install Docker + Buildx
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh

    useradd -m -s /bin/bash builder
    mkdir /home/builder/.ssh
    chmod 700 /home/builder/.ssh
    echo "${google_secret_manager_secret_version.vm_ssh_public_key.secret_data}" > /home/builder/.ssh/authorized_keys
    chmod 600 /home/builder/.ssh/authorized_keys
    chown -R builder:builder /home/builder/.ssh

    usermod -aG docker builder

    # Authenticate Docker for your specific region's Artifact Registry
    # Replace 'europe-west2' with your actual registry region (~/.docker/config.json)
    sudo -u builder gcloud auth configure-docker europe-west2-docker.pkg.dev --quiet
  EOF

  metadata = {
    enable-oslogin = "TRUE"
  }

  service_account {
    email = google_service_account.ubuntu_docker_sa[0].email
    # This unlocks all IAM roles attached to the SA
    scopes = ["cloud-platform"]
  }
}






