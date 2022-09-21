#
#
# @Braim T (braimt@gmail.com)

##
## Start by provisioning an S3 bucket.
## 
# 
resource "aws_s3_bucket" "my_bucket" {
  bucket = local.bucket_name

  force_destroy = true

  tags = { Name = local.bucket_name }
}

# disable versioning
resource "aws_s3_bucket_versioning" "my_bucket_versioning" {

  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status = "Disabled"
  }
}

# make the bucket private
resource "aws_s3_bucket_acl" "my_bucket_acl" {
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "private"
}

# create a folders images inside the bucket. Whenever a jpg image would be uploaded in that 
# folder, we'll convert it to png.
resource "aws_s3_object" "my_images_folder" {
  bucket       = aws_s3_bucket.my_bucket.id
  acl          = "private"
  key          = local.images_folder_path
  content_type = "application/x-directory"
}

# call lambda function whenever an object that ends up with .jpg is created 
# in the images folder. 
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.my_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.my_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = local.images_folder_path
    filter_suffix       = ".jpg"
  }
}


##
## Create the lambda function.
## 

# give S3 permission to access our lambda function.
resource "aws_lambda_permission" "allow_bucket" {
  #  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.my_bucket.arn
}

# Create the lambda (upload the jar)
resource "aws_lambda_function" "my_lambda_function" {
  filename      = "${path.module}/lambdas/JpgToPngConverter/target/JpgToPngConverter-1.0-SNAPSHOT.jar"
  function_name = local.lambda_name
  description   = "Function that converts JPG images to PNG."
  role          = aws_iam_role.my_lambda_assume_role.arn
  handler       = "be.braim.JpgToPngConverter::handleRequest"
  runtime       = "java11"
  timeout       = 600  # 10 minutes in seconds
  memory_size   = 2048 # 2GB memory

  #
  tags = { Name = local.lambda_name }

  # before creating the lambda, we need to make sure to build it. 
  depends_on = [
    null_resource.my_lambda_function_build
  ]
}

# We used maven to build our lambda function.
resource "null_resource" "my_lambda_function_build" {
  provisioner "local-exec" {
    command = "mvn -f ./lambdas/JpgToPngConverter/pom.xml clean package"
  }
}

# 
# IAM role for lamba - needed to grant the requirement permissions.
# 
resource "aws_iam_role" "my_lambda_assume_role" {
  name               = local.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.my_lambda_assume_role_policy.json

  #
  tags = { Name = local.lambda_role_name }
}

# Provides minimum permissions for a Lambda function to execute while accessing a resource within a VPC 
# - create, describe, delete network interfaces and write permissions to CloudWatch Logs.
# quoted from documentation (https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html)
resource "aws_iam_role_policy_attachment" "my_lambda_role_attachment_1" {
  role       = aws_iam_role.my_lambda_assume_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# 
resource "aws_iam_policy" "my_lambda_access_policy" {
  # name        = format("%s-s3-lambda-JpgToPngConverter-iam-policy", var.resource_prefix)
  description = "A policy allowing Lambda function to S3 bucket."
  policy      = data.aws_iam_policy_document.my_lambda_access_policy.json
}

# allow lambda to access the bucket previously created.
resource "aws_iam_role_policy_attachment" "my_lambda_role_attachment_2" {
  role       = aws_iam_role.my_lambda_assume_role.id
  policy_arn = aws_iam_policy.my_lambda_access_policy.arn
}
