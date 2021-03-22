resource "aws_api_gateway_rest_api" "aws_scheduler" {
  name = "aws_scheduler_api"
  description = "AWS Scheduler on Terraform"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.aws_scheduler.id
  parent_id = aws_api_gateway_rest_api.aws_scheduler.root_resource_id
  path_part = var.API_GATE_WAY_PROXY_PATH
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.aws_scheduler.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.aws_scheduler.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.scheduling_func.invoke_arn
}

# Unfortunately the proxy resource cannot match an empty path at the root of the API.
# To handle that, a similar configuration must be applied to the root resource that is built in to the REST API object:
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.aws_scheduler.id
  resource_id = aws_api_gateway_rest_api.aws_scheduler.root_resource_id
  http_method = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.aws_scheduler.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.scheduling_func.invoke_arn
}

resource "aws_api_gateway_deployment" "aws_scheduler_deploy" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]
  rest_api_id = aws_api_gateway_rest_api.aws_scheduler.id
  stage_name = var.API_GATE_WAY_ENV_STAGE_NAME
}
