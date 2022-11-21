terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "LeeSQSqueue" {
}

# Create a new EventBridge Rule
resource "aws_cloudwatch_event_rule" "LeeEventRule" {
  event_pattern = <<PATTERN
{
  "account": ["${data.aws_caller_identity.current.account_id}"],
  "source": ["demo.sqs"]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "LeeRuleTarget" {
  rule = aws_cloudwatch_event_rule.LeeEventRule.name
  arn  = aws_sqs_queue.LeeSQSqueue.arn
}

resource "aws_sqs_queue_policy" "test" {
  queue_url = aws_sqs_queue.LeeSQSqueue.id
  policy    = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.LeeSQSqueue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_cloudwatch_event_rule.LeeEventRule.arn}"
        }
      }
    }
  ]
}
POLICY
}

output "SQS-QUEUE" {
  value       = aws_sqs_queue.LeeSQSqueue.id
  description = "The SQS Queue URL"
}