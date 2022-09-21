

data "aws_caller_identity" "me" {}


# IAM policy document for lambda assume role
data "aws_iam_policy_document" "my_lambda_assume_role_policy" {
  version = "2012-10-17"

  statement {
    sid     = "LambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}



#
data "aws_iam_policy_document" "my_lambda_access_policy" {
  version = "2012-10-17"

  statement {
    sid    = "1"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.my_bucket.arn}/*",
      "${aws_s3_bucket.my_bucket.arn}"
    ]
  }
}
