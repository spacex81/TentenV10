
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

variable "appsync_api_name" {
  default = "UserAppSyncAPI"
}

# AppSync GraphQL API (without resolvers)
resource "aws_appsync_graphql_api" "user_api" {
  name                = var.appsync_api_name
  authentication_type = "API_KEY"
  
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logging_role.arn
    field_log_level          = "ALL"
  }
}

# IAM Role for CloudWatch Logging
resource "aws_iam_role" "appsync_logging_role" {
  name = "AppSyncLoggingRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "appsync.amazonaws.com" }
      },
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "appsync_logging_policy_attachment" {
  role       = aws_iam_role.appsync_logging_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs"
}

# API Key for accessing AppSync
resource "aws_appsync_api_key" "user_api_key" {
  api_id = aws_appsync_graphql_api.user_api.id
}

# Upload the schema using a null_resource with a local-exec provisioner
resource "null_resource" "upload_schema" {
  provisioner "local-exec" {
    command = "aws appsync start-schema-creation --api-id ${aws_appsync_graphql_api.user_api.id} --region ap-northeast-2 --definition fileb://schema.graphql"
  }

  # Use 'triggers' to force re-run if schema.graphql changes
  triggers = {
    schema_file_md5 = filemd5("schema.graphql")
  }

  # Ensure this runs after the AppSync API is created
  depends_on = [aws_appsync_graphql_api.user_api]
}

# Poll for schema creation completion
resource "null_resource" "wait_for_schema" {
  provisioner "local-exec" {
    command = <<EOT
      while true; do
        STATUS=$(aws appsync get-schema-creation-status --api-id ${aws_appsync_graphql_api.user_api.id} --region ap-northeast-2 --query "status" --output text)
        echo "Schema status: $STATUS"
        if [ "$STATUS" == "SUCCESS" ]; then
          echo "Schema creation completed successfully."
          exit 0
        elif [ "$STATUS" == "FAILED" ]; then
          echo "Schema creation failed."
          exit 1
        fi
        sleep 5
      done
    EOT
  }

  # Ensure this waits for the schema upload to finish
  depends_on = [null_resource.upload_schema]
}
