// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !! PLEASE CHANGE in a terraform.tfvars
// yourname="...."
// credentials="GCP IAM service account key file.json"
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
variable "yourname" {
  # No default
  # Use CLI or interactive input. It is best to setup your own terraform.tfvars
}
variable "credentials" {
  default = "central-beach-194106-fda731676157.json"
}
// other optional edits *************************************
variable "clustersize" {
  # You should use 3 for some more realistic installation
  default = "1"
}

variable "kind_release"{
  default = "https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64"
}

variable "project" {
  default = "central-beach-194106"
}
variable "machine_type" {
  default = "n2-standard-64" // 2 vCPU 8GB
  // https://gcpinstances.info/?cost_duration=monthly
  // example with minimal 2vcpu 4GB RAM
  // which leaves about 1.4GB for Redis DB
  // machine_type = "custom-2-4096" // https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
  // other machines of interest:
  //
  // e2-highmem-8   // 8 vCPU 64 GB
  // n2-highcpu-16  // 16 vCPU 32 GB
}
// machine name will be "<yourname>-<env>-node1"
variable "env" {
  default = "dev"
}
variable "RS_admin" {
  default = "admin@redis.io"
}
variable "region_name" {
  default = "europe-west1"
}

// other possible edits ************************************* networking

// must be a zone that already exist - we will not create it but will add to it
variable "dns_managed_zone" {
  default = "demo-clusters"
}
// RS DNS and cluster will be
// cluster.<yourname>.demo.redislabs.com
// node1.<yourname>.demo.redislabs.com
// ......<yourname>.demo.redislabs.com
// node3.<yourname>.demo.redislabs.com
variable "dns_zone_dns_name" {
  default = "demo.redislabs.com"
}
// optional edits *************************************
variable "rs_private_subnet" {
  default = "10.26.1.0/24"
}
variable "rs_public_subnet" {
  default = "10.26.2.0/24"
}
