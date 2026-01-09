# HAinfra

## Terraform S3 backend

This repository uses a remote S3 backend for Terraform state. The repository includes
`variables.tf` (for documentation) and a `backend.tf` placeholder. Terraform backend
values must be provided during `terraform init` using `-backend-config` flags.

Local init example:

```bash
terraform init \
	-backend-config="bucket=your-s3-bucket" \
	-backend-config="key=HAinfra/terraform.tfstate" \
	-backend-config="region=us-east-1"
```

CI (GitHub Actions): set the following repository secrets and the workflow will
pass them to `terraform init` automatically:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `S3_BACKEND_BUCKET`
- `S3_BACKEND_KEY` (e.g. `HAinfra/terraform.tfstate`)
- `S3_BACKEND_REGION`

If you prefer not to auto-apply from CI, I can update the workflow to only run
`plan` on push/PR and require a manual apply.
