/*
Variables for configuring the remote S3 backend.
These variables are provided as references for documentation and local usage.
Terraform does not automatically accept `var.*` values inside backend blocks during
`terraform init`. Provide these values via `terraform init -backend-config=...` or
set them in CI as secrets and pass them to `terraform init`.
*/

variable "s3_backend_bucket" {
  description = "Name of the S3 bucket to store the Terraform state"
  type        = string
}

variable "s3_backend_key" {
  description = "Path (key) within the S3 bucket for the state file"
  type        = string
  default     = "HAinfra/terraform.tfstate"
}

variable "s3_backend_region" {
  description = "AWS region where the S3 bucket is located"
  type        = string
  default     = "us-east-1"
}
