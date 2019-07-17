#!/bin/bash
#
# This script is executed at the end of data crunching to save downloaded and
# decompressed files in a temporary location in private S3 bucket.

set -e -x

REQ_FILENAME='request.yml'

# Do nothing if user request file doesn't exist
if [ ! -f $REQ_FILENAME ]; then
    exit 0
fi

# Do nothing if it is not in a PR
# dhu: uncomment this block when tests are done
#if [ ! -z $CIRCLE_PR_NUMBER ]; then
#    exit 0
#fi

# dhu: test only (remove this block when tests are done)
if [ -z $CIRCLE_PR_NUMBER ]; then
    CIRCLE_PR_NUMBER=999
fi

REQ_INDICATOR="req_success.txt"

# Install awscli for "aws" command
sudo pip install awscli

# Delete the indicator file (if it exists)
aws s3 rm s3://cimr-root/submitted_data/PR_${CIRCLE_PR_NUMBER}/$REQ_INDICATOR

# Parse user request, download data, and extract the tarball file
python3 .circleci/parse_yaml.py $REQ_FILENAME

# Process submitted data
python3 .circleci/process_submitted_data.py

# Save submitted data to private S3 bucket
if [ -d submitted_data ]; then
    aws s3 sync submitted_data s3://cimr-root/test-submitted/PR_${CIRCLE_PR_NUMBER}/
    aws s3 cp   $REQ_FILENAME  s3://cimr-root/test-submitted/PR_${CIRCLE_PR_NUMBER}/
fi

# Save processed data to private S3 bucket as well
if [ -d processed_data ]; then
    aws s3 sync processed_data s3://cimr-root/test-processed/PR_${CIRCLE_PR_NUMBER}/
fi

# Create a new local indicator file to tell whether user request is handled successfully
rm -f /tmp/$REQ_INDICATOR
touch /tmp/$REQ_INDICATOR

# Copy the indicator file to S3
aws s3 cp /tmp/$REQ_INDICATOR s3://cimr-root/test-submitted/PR_${CIRCLE_PR_NUMBER}/
