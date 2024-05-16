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

################################################################
#                                                              #
# CREATE IAM ROLES                                             #
#                                                              #
################################################################

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

resource "aws_iam_role" "codebuild_role" {
  
  name   = "c2-g4-tf-codebuild-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "codebuild.amazonaws.com"
                ]
            }
        }
    ]
  })
  
}

resource "aws_iam_role" "codepipeline_role" {
  
  name   = "c2-g4-tf-codepipeline-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "codepipeline.amazonaws.com"
                ]
            }
        }
    ]
  })
  
}

resource "aws_iam_role" "ecs_task_role" {
  
  name   = "c2-g4-tf-ecs-task-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ecs-tasks.amazonaws.com"
                ]
            }
        }
    ]
  })
  
}


################################################################
#                                                              #
# CREATE CUSTOM POLICIES                                       #
#                                                              #
################################################################

# this could porbably be replaced by a standard AWS lambda policy or role?
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

# we initially used an aws_iam_role_policy
resource "aws_iam_policy" "codebuild_policy" {
  
  name = "c2-g4-tf-codebuild-policy"
  path = "/"
  description  = "AWS IAM Policy for running CodebBuild"  
  #role = aws_iam_role.codebuild_role.id
 
 policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:us-west-2:962804699607:log-group:/aws/codebuild/c2-g4-tf-codebuild",
                "arn:aws:logs:us-west-2:962804699607:log-group:/aws/codebuild/c2-g4-tf-codebuild:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.codepipeline_bucket.arn}",
                "${aws_s3_bucket.codepipeline_bucket.arn}/*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:us-west-2:962804699607:report-group/c2-g4-tf-codebuild-*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "codepipeline_policy" {
  
  name = "c2-g4-tf-codepipeline-policy"
  path = "/"  
   description  = "AWS IAM Policy for managing codepipeline"
  #role = aws_iam_role.codepipeline_role.id
 
 policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*"
      ],
      "Resource":"*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource":"arn:aws:codestar-connections:us-west-2:962804699607:connection/90bf0db7-428f-4ee9-acba-6ebe7a54cc29"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplication",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource": "*"
    }    
  ]
}
EOF
}
 

################################################################
#                                                              #
# ATTACH POLICIES TO ROLES                                     #
#                                                              #
################################################################

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role         = aws_iam_role.lambda_role.name
 policy_arn   = aws_iam_policy.iam_policy_for_lambda.arn # this, from above, could porbably be replaced by a standard AWS lambda policy or role?
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role        = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_codebuild_role" {
  policy_arn  = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  role        = aws_iam_role.codebuild_role.name
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_codepipeline_role" {
  policy_arn  = aws_iam_policy.codepipeline_policy.arn
  role        = aws_iam_role.codepipeline_role.name
} 

resource "aws_iam_role_policy_attachment" "attach_cb_policy_to_codebuild_role" {
  policy_arn  = aws_iam_policy.codebuild_policy.arn
  role        = aws_iam_role.codebuild_role.name
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_ecs_task_role" {
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role        = aws_iam_role.ecs_task_role.name
}

################################################################
#                                                              #
# CREATE S3 BUCKET TO STORE TODO-DATA.JSON                     #
#                                                              #
################################################################ 
 
# create the bucket itself
resource "aws_s3_bucket" "to_do_list_bucket" {
	
	bucket 	= "c2-g4-tf-us-west-2-962804699607"

}

# create an object in the bucket, which will be our json file
resource "aws_s3_bucket_object" "object" {

  bucket = aws_s3_bucket.to_do_list_bucket.id
  key    = "todo-data.json"
  source = "todo-data.json"

}

################################################################
#                                                              #
# CREATE LAMBDA                                                #
#                                                              #
################################################################ 

# first zip the lambda_function code
data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/lambda_function.zip"
}

# then define the lambda itself, and logic using our zip file defined above
resource "aws_lambda_function" "terraform_lambda_func" {
  filename                       = "${path.module}/python/lambda_function.zip"
  function_name                  = "c2-g4-tf-get-to-do"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "lambda_function.lambda_handler"
  runtime                        = "python3.10"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

################################################################
#                                                              #
# CREATE THE API GATEWAY                                       #
#                                                              #
################################################################ 

# the basics, create the resource
resource "aws_api_gateway_rest_api" "my_api" {

  name = "c2-g4-tf-todo-api"
  description = "Lambda API gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
}

# define the path to the endpoint
resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "get-todo"
}

# define a method for our resource/path defined above to be hit by our users
resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = "GET"
  authorization = "NONE"
}

# define the handoff from the gateway to the lambda
# - note the integration_http_method below is POST though we receive a GET above
# - the gateway METHOD above can accept any http_method and we're receiving a GET from the user
# - but the lambda wants to receive a POST in the handoff from the gateway to the lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type = "AWS"
  uri = aws_lambda_function.terraform_lambda_func.invoke_arn
}

# define the response from the lambda back to the gateway
# - note the response_templates definition, which was required before we could get this API fully working
resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code
  
   response_templates = {
       "application/json" = ""
   }   

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.lambda_integration
  ]
}

# define the response from the gateway back to the user
resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

}

# define the stage for the gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    #aws_api_gateway_integration.lambda_integration_options, # Add this line if we return the OPTIONS method back to our resource/path
  ]

  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name = "prod"
}

################################################################
#                                                              #
# CONNECT OUR GATEWAY TO OUR LAMBDA                            #
#                                                              #
################################################################ 

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/GET/get-todo"
}

################################################################
#                                                              #
# CREATE OUR ECR REPO                                          #
#                                                              #
################################################################ 

resource "aws_ecr_repository" "my_first_ecr_repo" {
  name = "c2-g4-tf-ecr-repo" # Naming my repository
}


################################################################
#                                                              #
# CREATE CODEBUILD                                             #
#                                                              #
################################################################ 

resource "aws_codebuild_project" "codebuild_definition" {
  name         = "c2-g4-tf-codebuild"
  description  = "CodeBuild built from terraform"
  service_role = aws_iam_role.codebuild_role.arn
 
  artifacts {
    type = "NO_ARTIFACTS"
  }
 
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
 
    privileged_mode = true
 
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "962804699607"
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-west-2"
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.my_first_ecr_repo.id
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
    environment_variable {
      name  = "CLUSTER_NAME"
      value = aws_ecs_cluster.cluster_definition.id
    }
    environment_variable {
      name  = "SERVICE_NAME"
      value = aws_ecs_service.service_definition.id
    }
  }
 
  source {
    type            = "GITHUB"
    location        = "https://github.com/mierj2/react-new-todo"
    git_clone_depth = 1
  }
  
}
 