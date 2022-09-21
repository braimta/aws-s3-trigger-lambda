#
#
# @Braim T (braimt@gmail.com)

locals {
  # account number is added to avoid duplicates in bucket names.
  bucket_name      = format("%s-s3-triggers-lambda-%s", var.resource_prefix, data.aws_caller_identity.me.account_id)
  lambda_name      = format("%s-lambda-JpgToPngConverter", var.resource_prefix)
  lambda_role_name = format("%s-role", local.lambda_name)

  images_folder_path = "images/"
}