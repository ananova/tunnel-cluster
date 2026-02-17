#!/bin/sh

# Port Forward to RDS via ECS Container
#
# This script establishes a secure tunnel to an RDS instance through an ECS container
# using AWS Session Manager. It automatically determines the environment
# (staging/production) based on your AWS credentials and sets up the appropriate connection.
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
if [[ -z "${1:-}" || -z "${2:-}" || -z "${3:-}" || -z "${4:-}" || -z "${5:-}" || -z "${6:-}" ]]; then
  >&2 echo "Usage: $0 <aws_region> <cluster> <task_arn> <remote_host> <remote_port> <local_port>"
  exit 2
fi
aws_region="$1"
cluster="$2"
task_arn="$3"
remote_host="$4"
remote_port="$5"
local_port="$6"

task_runtime_id=$(aws ecs describe-tasks \
    --cluster "$cluster" \
    --tasks "$task_arn" \
    --region "$aws_region" \
    --query 'tasks[0].containers[0].runtimeId' \
    --output text)

if [ -z "$task_runtime_id" ] || [ "$task_runtime_id" = "None" ]; then
    echo "Error: Unable to retrieve ECS task runtime ID" >&2
    exit 1
fi

echo "Connecting to task: ${task_arn}..."
echo "Forwarding port ${remote_port} => ${local_port} for remote host: ${remote_host}"
echo ""

task_id=$(echo "$task_runtime_id" | cut -d'-' -f1)

exec aws ssm start-session \
    --target "ecs:${cluster}_${task_id}_${task_runtime_id}" \
    --region "$aws_region" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"$remote_host\"],\"portNumber\":[\"$remote_port\"], \"localPortNumber\":[\"$local_port\"]}"
