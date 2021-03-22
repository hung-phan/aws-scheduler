#!/usr/bin/env bash

set -e # exit on failure
set -x # log all executed commands

# bundle application
gradle buildZip

# get AWS_SCHEDULER_VERSION
export TF_VAR_AWS_SCHEDULER_VERSION="$(gradle properties -q | grep "version:" | awk '{print $2}')"

# info
echo "Current AWSScheduler version: $TF_VAR_AWS_SCHEDULER_VERSION"

# deployment
cd deployment
terraform apply

set +x
set +e
