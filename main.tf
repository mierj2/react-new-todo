terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
    profile = "default"
    region="us-west-2"
}

resource "aws_ecr_repository" "my_first_ecr_repo" {
  name = "c2-g4-tf-ecr-repo" # Naming my repository
}

resource "aws_s3_bucket" "to_do_list_bucket" {
	
	bucket 	= "c2-g4-tf-us-west-2-962804699607"

}

resource "aws_s3_bucket_object" "object" {

  bucket = aws_s3_bucket.to_do_list_bucket.id
  key    = "todo-data.json"
  source = "todo-data.json"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  # etag = filemd5("ptodo-data.json")
}

resource "aws_iam_role" "lambda_role" {
name   = "c2-g4-tf-lambda-role"
assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}
#assume_role_policy = <<EOF
#{
# "Version": "2012-10-17",
# "Statement": [
#   {
#     "Action": "sts:AssumeRole",
#     "Principal": {
#       "Service": "lambda.amazonaws.com"
#     },
#     "Effect": "Allow",
#     "Sid": ""
#   }
# ]
#}
#EOF
#}

resource "aws_iam_policy" "iam_policy_for_lambda" {
 
 name         = "c2-g4-tf-iam-lambda-policy"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "s3:GetObject"
     ],
     "Resource": "arn:aws:s3:::*",
     "Effect": "Allow"
   },
   {
     "Action": [
       "logs:CreateLogGroup"
     ],
     "Resource": "arn:aws:logs:us-west-2:962804699607:*",
     "Effect": "Allow"
   },
   {
     "Action": [
      "logs:CreateLogStream",
      "logs:PutLogEvents"     
     ],
     "Resource": "arn:aws:logs:us-west-2:962804699607:log-group:/aws/lambda/c2-g4-tf-get-to-do:*",
     "Effect": "Allow"
   }
   
 ]
}
EOF
}
 
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}
 
data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/todo-lambda.zip"
}
 
resource "aws_lambda_function" "terraform_lambda_func" {
  filename                       = "${path.module}/python/todo-lambda.zip"
  function_name                  = "c2-g4-tf-get-to-do"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "todo.lambda_handler"
  runtime                        = "python3.10"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}


#Policies:
#        - Statement:
#            - Effect: Allow
#              Action:
#                - s3:GetObject
#              Resource: arn:aws:s3:::*
#            - Effect: Allow
#              Action:
#                - logs:CreateLogGroup
#              Resource: arn:aws:logs:us-west-2:962804699607:*
#            - Effect: Allow
#              Action:
#                - logs:CreateLogStream
#                - logs:PutLogEvents
#              Resource:
#                - >-
#                  arn:aws:logs:us-west-2:962804699607:log-group:/aws/lambda/c2-g4-get-to-do:*