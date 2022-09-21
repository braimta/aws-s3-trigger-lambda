
# Introduction

This stack illustrates how an S3 bucket can trigger a lambda function. The lambda function converts a JPG file uploaded in a specific directory on the bucket to PNG. The result is stored in the same directory. 


# Pre-requisites

1. AWS CLI: This small demo runs on AWS and shouldn't cost anything. Also, we should create an AWS named profile. In our case, it's called "personal". 
1. Terraform : The AWS resources are provisioned using terraform. 
2. Java 11: Needed to build the code.
3. Maven: Used as dependency and build tool.


# Usage 

Before deploying the stack, make sure the `aws_cli_profile` is correct in the defaults.tfvars. Then, use terraform to deploy it. Terraform also calls maven to build the artifact with the lambda function.

The following command shows the list of resources that are about to be provisioned.
```
% terraform plan -out=tfplan -var-file=defaults.tfvars 
```

To apply those changes: 
```
% terraform apply "tfplan"
```

Validate by uploading a file in the images folder.

Logs could be found in CloudWatch as well.


----
Braim (braimt@gmail.com)