module "fluentbit_s3_bucket" {
  count = var.fluent_bit_s3_bucket_enable ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.6.1"

  bucket = "fluentbit-log-bucket-${random_string.s3_suffix.result}"

  versioning = {
    enabled = false
  }

  resource "random_string" "s3_suffix" {
    length  = 8
    special = false
    upper   = false
  }

  lifecycle_rules = [
    {
      id                                     = "log-expiration"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7

      expiration = {
        days = 90
      }

      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "ONEZONE_IA"
        }
      ]
    }
  ]
}
