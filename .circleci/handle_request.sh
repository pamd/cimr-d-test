#!/bin/bash
#
# This script is executed at the end of data crunching to save downloaded and
# decompressed files in a temporary location in private S3 bucket.

set -e -x

# Do nothing if it is not in a PR
if [ -z $CIRCLE_PULL_REQUEST ]; then
    exit 0
fi

# Extract PR number from CIRCLE_PULL_REQUEST, see more options at:
# https://stackoverflow.com/q/3162385
PR_NUMBER=$(echo ${CIRCLE_PULL_REQUEST##*/})

# Install awscli (so that "aws" command is available)
sudo pip install awscli

# Key of the S3 object whose existence indicates that user request has been
# handled successfully.
INDICATOR_KEY="test-only/work-in-progress/PR-${PR_NUMBER}/req_success.txt"

# Delete the indicator file (if it exists)
aws s3api delete-object --bucket cimr-root --key ${INDICATOR_KEY}

# Parse user request, download data (and extract tarball file, if available)
python3 .circleci/parse_yaml.py

# Process submitted data
python3 .circleci/process_submitted_data.py

# Save submitted data to a temporary location in private S3 bucket
if [ -d submitted_data ]; then
    aws s3 sync submitted_data s3://cimr-root/test-only/work-in-progress/PR-${PR_NUMBER}/
fi

# Save processed data to a temporary location in public S3 bucket
if [ -d processed_data ]; then
    aws s3 sync processed_data s3://cimr-d/test-only/work-in-progress/PR-${PR_NUMBER}/
fi

# Create a new object in S3 to indicate that user request has been handled successfully
aws s3api put-object --bucket cimr-root --key ${INDICATOR_KEY}
