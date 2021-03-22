variable AWS_REGION {
  default = "us-east-1"
}

variable BUILD_LOCATION {
  default = "./../build/distributions/"
}

variable SCHEDULING_FUNCTION_HANDLER {
  default = "com.colorvisa.AWSScheduler.SchedulingHandler"
}

variable CLEANUP_FUNCTION_HANDLER {
  default = "com.colorvisa.AWSScheduler.CleanupHandler"
}

variable CLEANUP_INTERVAL {
  default = "rate(7 days)"
}

variable LAMBDA_RUNTIME {
  default = "java8"
}

variable API_GATE_WAY_PROXY_PATH {
  default = "{proxy+}"
}

variable "DEPLOY_BUCKET" {}

variable API_GATE_WAY_ENV_STAGE_NAME {
  default = "aws-scheduler-lambda"
}

variable AWS_SCHEDULER_VERSION {
  type = string
}
