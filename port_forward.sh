#!/usr/bin/env bash

set -uo pipefail

# Require AWS credentials are set
if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
  >&2 echo "ERROR: No AWS credentials found, exiting."
  exit 1
fi

# Accept and validate input arguments
if [[ -z "${1:-}" || -z "${2:-}" || -z "${3:-}" || -z "${4:-}" || -z "${5:-}" || -z "${6:-}" ]]; then
  >&2 echo "Usage: $0 <aws_region> <remote_host> <remote_port> <local_port> <expected_aws_account_id> <expected_aws_account_name>"
  exit 2
fi
aws_region="$1"
remote_host="$2"
remote_port="$3"
local_port="$4"
expected_aws_account_id="$5"
expected_aws_account_name="$6"
shift 4

>&2 echo -n "Validating AWS account details: "
IFS=',' read account_id account_name < <(aws account get-account-information --query '[AccountId,AccountName]' --output text | tr '\t' ',')
if [[ "${expected_aws_account_id}" != "${account_id}" ]]; then
  >&2 echo "ERROR: incorrect AWS account -- expected ${expected_aws_account_name} (${expected_aws_account_id}), but got ${account_name} (${account_id}). Exiting."
  exit 3
fi
>&2 echo "${account_name} (${account_id}) OK"

# Find bastion
>&2 echo -n "Finding bastion ID: "
bastion_instance_id=$(aws ec2 describe-instances  \
  --region ${aws_region} \
  --filters "Name=tag:GpetBastion,Values=true" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[] | [0].InstanceId" \
  --output text
)
if [[ -z "${bastion_instance_id}" || "${bastion_instance_id}" == "None" ]]; then
  >&2 echo "ERROR: Unable to find bastion ID, exiting. Please contact #gpet-helpline for help."
  exit 4
fi

>&2 echo "${bastion_instance_id}"

# Open tunnel
>&2 echo "Opening tunnel to ${remote_host}:${remote_port}, listening on local port ${local_port}"
aws ssm start-session \
  --region ${aws_region} \
  --target ${bastion_instance_id} \
  --document-name arn:aws:ssm:${aws_region}:909551307430:document/bastion-ssm-session-portforwarding-document \
  --parameters host="${remote_host}",portNumber="${remote_port}",localPortNumber="${local_port}"
