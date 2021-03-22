package com.colorvisa.AWSScheduler;

import com.amazonaws.services.eventbridge.model.Target;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class RequestParams {
  @JsonProperty("targetFunctionName")
  private String targetFunctionName;

  @JsonProperty("schedulerExpression")
  private String schedulerExpression;

  @JsonProperty("target")
  Target target;
}
