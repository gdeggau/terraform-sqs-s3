terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_sqs_queue" "dowhile_2021_dlq" {
  name = "rocketseat_dowhile_2021_dlq"
  tags = local.tags
}

resource "aws_sqs_queue" "dowhile_2021" {
  name                       = "rocketseat_dowhile_2021"
  delay_seconds              = 0
  max_message_size           = 262144
  receive_wait_time_seconds  = 0
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 30

  tags = local.tags

  redrive_policy = jsonencode({
    maxReceiveCount     = 10
    deadLetterTargetArn = aws_sqs_queue.dowhile_2021_dlq.arn
  })

  # Create SQS Queue Policy to allow S3 to send messages
  policy = <<POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": "*",
          "Action": "sqs:SendMessage",
          "Resource": "arn:aws:sqs:*:*:rocketseat_dowhile_2021",
          "Condition": {
            "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.dowhile_2021.arn}" }
          } 
        }
      ]
    }
  POLICY
}

resource "aws_s3_bucket" "dowhile_2021" {
  bucket = "terraform-rocketseat-dowhile-2021-bucket"
  tags   = local.tags
}

# Create S3 bucket notification event
resource "aws_s3_bucket_notification" "dowhile_2021" {
  bucket = aws_s3_bucket.dowhile_2021.id

  queue {
    queue_arn = aws_sqs_queue.dowhile_2021.arn
    events    = ["s3:ObjectCreated:Put"]

    # Only trigger the event when suffix matches
    # filter_suffix = ".log"
  }
}
