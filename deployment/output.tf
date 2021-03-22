output "aws_scheduler_api_gateway_url" {
  value = aws_api_gateway_deployment.aws_scheduler_deploy.invoke_url
}
