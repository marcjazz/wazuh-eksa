terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
# Remote Terraform backend (e.g., S3); uncomment and configure for collaboration
# terraform {
#   backend "s3" {
#     bucket = "your-terraform-state-bucket"
#     key    = "eksa/terraform.tfstate"
#     region = "us-east-1"
#   }
# }