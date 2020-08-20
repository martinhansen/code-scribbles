#!/bin/bash

# *WARNING* This script will overwrite your current ~/.aws/credentials file, make sure to take a backup
#       `cp ~/.aws/credentials ~/.aws/credentials.backup`

# Prerequisites:
# 1. Put this script, and a aws_mfa_device file in ~/.aws/ folder.
# 2. Add device arn to the "aws_mfa_device" file.
# 2. Update your ~/.aws/config file with a new profile:

#       [profile mfa]
#       region=eu-west-1

# 3. Copy your ~/.aws/credentials file to ~/.aws/credentials.org

# DO NOT UPDATE ~/.aws/credentials manually anymore, update ~/.aws/credentials.org instead, and run this script afterwards, to get everything up to date.

# Usage:
# run this script with an authentication token as the only argument

# Pro Tip; add symlink for this, and add it to the PATH variable.

#       `ln -s /home/user/.aws/aws-mfa-refresh.sh /home/user/aws/mfa-refresh`

# Example (from anywhere, with symlink): 'mfa-refresh xxxxxx'

# usage with aws cli is then (for services that need mfa: "aws s3 ls --profile mfa"
# this can be used in code by specifying AWS_PROFILE=mfa environment variable

if [ ! -f ~/.aws/aws-mfa-device ]; then
    echo "aws-mfa-device file not found. (aws-mfa-device), exiting"
    exit 1
fi

if [ ! -f ~/.aws/credentials.org ]; then
    echo "original credentials file not found. (credentials.org), exiting"
    exit 1
fi

if [ "$#" -lt 1 ]; then
    echo 'please specify one-time Authentication token from device'
    exit 1
fi

MFA_TOKEN=$1
MFA_DEVICE_ARN=$(cat ~/.aws/aws-mfa-device)
ORG_CRED_FILE=$(cat ~/.aws/credentials.org)

session_token_resp="$(aws sts get-session-token --serial-number ${MFA_DEVICE_ARN} --token-code ${MFA_TOKEN})"

#identify aws cli response code, if 0, all ok, anything else means error, and should exit.
if [ "$?" != 0 ]; then
    exit 1
fi

access_key_id="$(echo ${session_token_resp} | jq -r .Credentials.AccessKeyId)"
secret_access_key=$(echo ${session_token_resp} | jq -r .Credentials.SecretAccessKey)
session_token="$(echo ${session_token_resp} | jq -r .Credentials.SessionToken)"

MFA_PROFILE=$(cat <<-END
[mfa]
region = eu-west-1
aws_access_key_id = ${access_key_id}
aws_secret_access_key = ${secret_access_key}
aws_session_token = ${session_token}
END
)

printf "${ORG_CRED_FILE}\n\n${MFA_PROFILE}" > ~/.aws/credentials

echo "Done updating credentials file."
