# lambda role
resource "aws_iam_role" "iam_role_for_aws_scheduler" {
  name = "AWSSchedulerLambdaInvokeRole"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
}
EOF
}

# lambda policy
resource "aws_iam_policy" "iam_policy_for_aws_scheduler" {
  name = "AWSSchedulerLambdaInvokePolicy"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "events:ListRules",
                "events:ListTargetsByRule",
                "events:PutRule",
                "events:DeleteRule",
                "events:PutTargets",
                "events:RemoveTargets"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:*:log-stream:*",
                "arn:aws:events:*:*:rule/*",
                "arn:aws:lambda:*:*:function:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogStream",
            "Resource": "arn:aws:logs:*:*:log-group:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "xray:PutTelemetryRecords",
                "xray:PutTraceSegments"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment" {
  role = aws_iam_role.iam_role_for_aws_scheduler.name
  policy_arn = aws_iam_policy.iam_policy_for_aws_scheduler.arn
}
