#
#
# @Braim T (braimt@gmail.com)

provider "aws" {
  profile = var.aws_cli_profile
  region  = "eu-west-1"

     default_tags {
      tags = {
        "Created_By" = "Terraform", 
        "Description" = "Demo to triggers lambda from S3"
      }
     }
}

