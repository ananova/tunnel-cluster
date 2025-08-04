#!/bin/sh

# ECS Container Shell Access
#
# This script provides interactive shell access to an ECS container using AWS ECS Exec.
# It automatically connects to the appropriate container based on the provided parameters.
#
# Prerequisites:
#   - AWS CLI configured with valid credentials
#   - AWS Systems Session Manager plugin installed
#   - Appropriate IAM permissions for ECS and SSM
#

set -euo pipefail

# Require AWS credentials are set
if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
  >&2 echo "ERROR: No AWS credentials found, exiting."
  exit 1
fi

# Accept and validate input arguments
if [[ -z "${1:-}" || -z "${2:-}" || -z "${3:-}" || -z "${4:-}" ]]; then
  >&2 echo "Usage: $0 <aws_region> <cluster> <service> <container>"
  exit 2
fi
aws_region="$1"
cluster="$2"
service="$3"
container="$4"

task_arn=$(aws ecs list-tasks \
    --cluster "$cluster" \
    --service-name "$service" \
    --region "$aws_region" \
    --query 'taskArns[0]' \
    --output text)

if [ -z "$task_arn" ] || [ "$task_arn" = "None" ]; then
    echo "Error: Unable to retrieve ECS task ARN" >&2
    exit 1
fi

echo "Connecting to task: ${task_arn}..."
exec aws ecs execute-command \
    --cluster "$cluster" \
    --task "$task_arn" \
    --container "$container" \
    --region "$aws_region" \
    --command "/bin/bash" \
    --interactive
