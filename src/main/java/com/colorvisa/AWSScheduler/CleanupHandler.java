package com.colorvisa.AWSScheduler;

import com.amazonaws.services.eventbridge.AmazonEventBridgeAsync;
import com.amazonaws.services.eventbridge.AmazonEventBridgeAsyncClient;
import com.amazonaws.services.eventbridge.model.*;
import com.amazonaws.services.lambda.AWSLambdaAsync;
import com.amazonaws.services.lambda.AWSLambdaAsyncClient;
import com.amazonaws.services.lambda.model.RemovePermissionRequest;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.ScheduledEvent;
import com.cronutils.model.definition.CronDefinition;
import com.cronutils.model.definition.CronDefinitionBuilder;
import com.cronutils.model.time.ExecutionTime;
import com.cronutils.parser.CronParser;

import java.time.ZonedDateTime;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class CleanupHandler implements RequestHandler<ScheduledEvent, String> {
  final AWSLambdaAsync lambda = AWSLambdaAsyncClient.asyncBuilder().build();
  final AmazonEventBridgeAsync eventBridge = AmazonEventBridgeAsyncClient.asyncBuilder().build();
  final Pattern pattern = Pattern.compile("cron\\((.+)\\)");
  final CronDefinition cronDefinition =
      CronDefinitionBuilder.defineCron()
          .withMinutes()
          .withValidRange(0, 59)
          .and()
          .withHours()
          .withValidRange(0, 23)
          .and()
          .withDayOfMonth()
          .supportsHash()
          .supportsL()
          .supportsW()
          .supportsQuestionMark()
          .and()
          .withMonth()
          .withValidRange(1, 12)
          .and()
          .withDayOfWeek()
          .withIntMapping(7, 0) // we support non-standard non-zero-based numbers!
          .supportsHash()
          .supportsL()
          .supportsW()
          .supportsQuestionMark()
          .and()
          .withYear()
          .and()
          .instance();
  final CronParser cronParser = new CronParser(cronDefinition);

  @Override
  public String handleRequest(ScheduledEvent input, Context context) {
    String nextToken = null;

    try {
      do {
        final ListRulesResult listRulesResult =
            eventBridge.listRules(
                new ListRulesRequest()
                    .withNamePrefix(Constants.RULE_PREFIX)
                    .withLimit(Constants.FETCHING_RULES_LIMIT)
                    .withNextToken(nextToken));

        for (final Rule rule : listRulesResult.getRules()) {
          if (isExpired(rule.getScheduleExpression())) {
            cleanup(rule, context);
          }
        }

        nextToken = listRulesResult.getNextToken();
      } while (Objects.nonNull(nextToken));
    } catch (Exception ex) {
      context
          .getLogger()
          .log(
              String.format(
                  "[%s] Encounter error when cleanup: %s",
                  context.getAwsRequestId(), ex.getMessage()));

      return "500 ERROR";
    }

    return "200 OK";
  }

  private void tryFunc(Runnable func, Rule rule, Context context) {
    try {
      func.run();
    } catch (Exception ex) {
      context
          .getLogger()
          .log(
              String.format(
                  "[%s] Encounter error when cleanup: %s (%s)",
                  context.getAwsRequestId(), rule.getArn(), ex.getMessage()));
    }
  }

  private void cleanup(Rule rule, Context context) {
    final String ruleName = rule.getName();

    final ListTargetsByRuleResult listTargetsByRuleResult =
        eventBridge.listTargetsByRule(new ListTargetsByRuleRequest().withRule(ruleName));

    for (final Target target : listTargetsByRuleResult.getTargets()) {
      tryFunc(
          () ->
              lambda.removePermission(
                  new RemovePermissionRequest()
                      .withFunctionName(target.getId())
                      .withStatementId(ruleName)),
          rule,
          context);
      tryFunc(
          () ->
              eventBridge.removeTargets(
                  new RemoveTargetsRequest().withRule(ruleName).withIds(target.getId())),
          rule,
          context);
    }

    tryFunc(
        () -> eventBridge.deleteRule(new DeleteRuleRequest().withName(ruleName)), rule, context);
  }

  private boolean isExpired(String scheduleExpression) {
    if (scheduleExpression.startsWith("rate")) {
      return false;
    }

    final Matcher matcher = pattern.matcher(scheduleExpression);

    if (!matcher.find()) {
      return false;
    }

    return !ExecutionTime.forCron(cronParser.parse(matcher.group(1)))
        .nextExecution(ZonedDateTime.now())
        .isPresent();
  }
}
