// Create a log group for the lambda
resource "aws_cloudwatch_log_group" "aws_scheduler_log_group" {
  name = "/aws/lambda/aws_scheduler"
}

# allow lambda to log to cloudwatch
data "aws_iam_policy_document" "aws_scheduler_cloudwatch_log_group_access_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:::*",
    ]
  }
}
