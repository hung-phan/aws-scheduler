# AWS Scheduler

AWSScheduler is a scheduling system used to invoke any lambdas using EventBridge rule.
You can find out about supported schedulerExpression from https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-schedule-expressions.html

The design of this functionality is originated from https://aws.amazon.com/blogs/mt/build-scheduler-as-a-service-amazon-cloudwatch-events-amazon-eventbridge-aws-lambda/.
However, this has an additional cleanup function that will try to clean up expiring rule, so you
won't run into the issue of having unused scheduling rules.


## How to use
Example of making a request to schedule another lambda

```bash
curl --location --request POST 'https://bv8zd56pw1.execute-api.us-east-1.amazonaws.com/aws-scheduler-lambda' \
--header 'Content-Type: application/json' \
--data-raw '{
    "schedulerExpression": "cron(5 17 11 4 ? 2021)",
    "targetFunctionName": "aws_scheduler_cleanup",
    "target": {
        "id": "aws_scheduler_cleanup",
        "arn": "arn:aws:lambda:us-east-1:108317574226:function:aws_scheduler_cleanup",
        "input": "{ \"data\": \"Just some random data\" }"
    }
}'

```

`targetFunctionName` must be equal to `target.id` 

## Deployment

This deployment script assumes that you use terraform and already setup correct
permission for terraform to run.

### Deploy
```bash
./deploy-script.sh
```

### Tear down
```bash
./tear-down-script.sh
```

