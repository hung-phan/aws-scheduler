resource "aws_lambda_function" "scheduling_func" {
  runtime = var.LAMBDA_RUNTIME
  s3_bucket = aws_s3_bucket.deploy_bucket.id
  s3_key = "${var.AWS_SCHEDULER_VERSION}.zip"
  function_name = "aws_scheduler"
  handler = var.SCHEDULING_FUNCTION_HANDLER

  timeout = 60
  memory_size = 512

  role = aws_iam_role.iam_role_for_aws_scheduler.arn
  depends_on = [
    aws_cloudwatch_log_group.aws_scheduler_log_group,
    aws_s3_bucket_object.upload_code_to_s3
  ]
}

resource "aws_lambda_permission" "scheduling_func_permission" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduling_func.function_name
  principal = "apigateway.amazonaws.com"
  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  //  source_arn = "${aws_api_gateway_deployment.aws_scheduler_deploy.execution_arn}/*/*"
  source_arn = "${replace(aws_api_gateway_deployment.aws_scheduler_deploy.execution_arn, var.API_GATE_WAY_ENV_STAGE_NAME, "")}*/*"
}

resource "aws_lambda_function" "cleanup_func" {
  runtime = var.LAMBDA_RUNTIME
  s3_bucket = aws_s3_bucket.deploy_bucket.id
  s3_key = "${var.AWS_SCHEDULER_VERSION}.zip"
  function_name = "aws_scheduler_cleanup"
  handler = var.CLEANUP_FUNCTION_HANDLER

  timeout = 60
  memory_size = 512

  role = aws_iam_role.iam_role_for_aws_scheduler.arn
  depends_on = [
    aws_cloudwatch_log_group.aws_scheduler_log_group,
    aws_s3_bucket_object.upload_code_to_s3
  ]
}

resource "aws_cloudwatch_event_rule" "cleanup_interval" {
  name = "AWSScheduler-Cleanup"
  description = "AWSScheduler clean up interval"
  schedule_expression = var.CLEANUP_INTERVAL
}

resource "aws_cloudwatch_event_target" "allow_cleanup_interval" {
  rule = aws_cloudwatch_event_rule.cleanup_interval.name
  target_id = aws_lambda_function.cleanup_func.function_name
  arn = aws_lambda_function.cleanup_func.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_cleanup_func" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanup_func.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.cleanup_interval.arn
}
