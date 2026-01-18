# Create the SSH private key secret
resource "google_secret_manager_secret" "vm_ssh_private_key" {
  secret_id = "VM_SSH_PRIVATE_KEY"

  replication {
    auto {}
  }
}
# Set the SSH private key
resource "google_secret_manager_secret_version" "vm_ssh_private_key_version" {
  secret = google_secret_manager_secret.vm_ssh_private_key.id
  secret_data = filebase64("/path/to/id_rsa-cloud")
  is_secret_data_base64 = true
}
# Give permission to the Cloud Build service account to read the private ssh key
resource "google_secret_manager_secret_iam_member" "cloud_build_iam_secret_vm_ssh_private_key_secretAccessor" {
  secret_id = google_secret_manager_secret.vm_ssh_private_key.id
  role      = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.service_account_cloud_build.email}"
}

# Create the SSH public key secret
resource "google_secret_manager_secret" "vm_ssh_public_key" {
  secret_id = "VM_SSH_PUBLIC_KEY"

  replication {
    auto {}
  }
}
# Set the SSH public key
resource "google_secret_manager_secret_version" "vm_ssh_public_key_version" {
  secret = google_secret_manager_secret.vm_ssh_public_key[0].id
  secret_data = filebase64("/path/to/id_rsa-cloud.pub")
  is_secret_data_base64 = true
}
# Give permission to the Cloud Build service account to read the public ssh key
resource "google_secret_manager_secret_iam_member" "cloud_build_iam_secret_vm_ssh_public_key_secretAccessor" {
  secret_id = google_secret_manager_secret.vm_ssh_public_key.id
  role      = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.service_account_cloud_build.email}"
}
