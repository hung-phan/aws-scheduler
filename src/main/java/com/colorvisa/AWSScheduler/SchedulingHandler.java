package com.colorvisa.AWSScheduler;

import com.amazonaws.services.eventbridge.AmazonEventBridgeAsync;
import com.amazonaws.services.eventbridge.AmazonEventBridgeAsyncClient;
import com.amazonaws.services.eventbridge.model.*;
import com.amazonaws.services.lambda.AWSLambdaAsync;
import com.amazonaws.services.lambda.AWSLambdaAsyncClient;
import com.amazonaws.services.lambda.model.AWSLambdaException;
import com.amazonaws.services.lambda.model.AddPermissionRequest;
import com.amazonaws.services.lambda.model.AddPermissionResult;
import com.amazonaws.services.lambda.model.RemovePermissionRequest;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.UUID;

public class SchedulingHandler
    implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {
  final ObjectMapper objectMapper = new ObjectMapper();
  final AWSLambdaAsync lambda = AWSLambdaAsyncClient.asyncBuilder().build();
  final AmazonEventBridgeAsync eventBridge = AmazonEventBridgeAsyncClient.asyncBuilder().build();

  @Override
  public APIGatewayProxyResponseEvent handleRequest(
      APIGatewayProxyRequestEvent event, Context context) {
    try {
      final RequestParams requestParams =
          objectMapper.readValue(event.getBody(), RequestParams.class);
      final String ruleName = String.format("%s-%s", Constants.RULE_PREFIX, UUID.randomUUID());

      final PutRuleResult ruleResult =
          putRule(ruleName, requestParams.getSchedulerExpression(), context);

      addPermission(
          ruleName, requestParams.getTargetFunctionName(), ruleResult.getRuleArn(), context);

      final PutTargetsResult putTargetsResult =
          putTargets(
              ruleName, requestParams.getTargetFunctionName(), requestParams.getTarget(), context);

      return new APIGatewayProxyResponseEvent().withStatusCode(200).withBody("OK");
    } catch (Exception ex) {
      return new APIGatewayProxyResponseEvent().withStatusCode(500).withBody(ex.getMessage());
    }
  }

  private PutRuleResult putRule(String ruleName, String schedulerExpression, Context context) {
    try {
      return eventBridge.putRule(
          new PutRuleRequest().withName(ruleName).withScheduleExpression(schedulerExpression));
    } catch (AmazonEventBridgeException ex) {
      context
          .getLogger()
          .log(
              String.format(
                  "[%s] Encounter error when putRule: %s",
                  context.getAwsRequestId(), ex.getMessage()));

      throw ex;
    }
  }

  private AddPermissionResult addPermission(
      String ruleName, String targetFunctionName, String ruleArn, Context context) {
    try {
      return lambda.addPermission(
          new AddPermissionRequest()
              .withAction("lambda:InvokeFunction")
              .withFunctionName(targetFunctionName)
              .withPrincipal("events.amazonaws.com")
              .withStatementId(ruleName)
              .withSourceArn(ruleArn));
    } catch (AWSLambdaException ex) {
      eventBridge.deleteRule(new DeleteRuleRequest().withName(ruleName));

      context
          .getLogger()
          .log(
              String.format(
                  "[%s] Encounter error when addPermission: %s",
                  context.getAwsRequestId(), ex.getMessage()));

      throw ex;
    }
  }

  private PutTargetsResult putTargets(
      String ruleName, String targetFunctionName, Target target, Context context) {
    try {
      return eventBridge.putTargets(new PutTargetsRequest().withRule(ruleName).withTargets(target));
    } catch (AmazonEventBridgeException ex) {
      lambda.removePermission(
          new RemovePermissionRequest()
              .withFunctionName(targetFunctionName)
              .withStatementId(ruleName));
      eventBridge.deleteRule(new DeleteRuleRequest().withName(ruleName));

      context
          .getLogger()
          .log(
              String.format(
                  "[%s] Encounter error when putTargets: %s",
                  context.getAwsRequestId(), ex.getMessage()));

      throw ex;
    }
  }
}
