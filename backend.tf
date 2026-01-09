/*
S3 backend placeholder.

Best practice: do not hardcode backend values in this file. Instead provide
backend settings when running `terraform init`:

terraform init \
  -backend-config="bucket=YOUR_S3_BUCKET" \
  -backend-config="key=path/to/terraform.tfstate" \
  -backend-config="region=us-east-1"

In CI we pass these values from repository secrets to `terraform init`.
*/

terraform {
  backend "s3" {}
}
