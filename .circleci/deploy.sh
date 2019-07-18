#!/bin/bash
#
# This script will be triggered when "master" branch is updated.
# It copies new files in "submitted_data" and "processed_data" to S3 buckets,
# then cleans up everything in "submitted_data" directory and commits the
# change back to remote repo.

set -e -x

function delete_requests() {
    if [ -f submitted/*.yml ] || [ -f submitted/*.yaml ]; then
	git rm --ignore-unmatch submitted/*.yml submitted/*.yaml
	git commit -m "CircleCI: Delete requests in submitted/ dir [skip ci]"
	git push --force --quiet origin master
    fi
}

# Git config
git config --global user.email "cimrroot@gmail.com"
git config --global user.name "cimrroot"
git config --global push.default simple

cd ~/cimr-d/
git lfs install

LATEST_COMMIT_HASH=$(git log -1 --pretty=format:%H)
GITHUB_SEARCH_URL="https://api.github.com/search/issues?q=sha:${LATEST_COMMIT_HASH}"
PR_NUMBER=$(curl -s $GITHUB_SEARCH_URL | jq '.items[0].number')

# If we're not merging a PR, clean up "submitted/" dir and exit.
if [ $PR_NUMBER == 'null' ]; then
    delete_requests
    exit 0
fi

# If we are merging a PR, but the indicator object is not found in S3 bucket,
# data processing must either fail or not start at all, so we exit too.
INDICATOR_KEY="test-only/work-in-progress/PR-${PR_NUMBER}/req_success.txt"
aws s3api head-object --bucket cimr-root --key $INDICATOR_KEY || NO_PROCESSED_DATA=true
if [ $NO_PROCESSED_DATA ]; then
    delete_requests
    exit 0
fi

# Sync files in "submitted_data" directory to private S3 bucket "cimr-root",
aws s3 mv s3://cimr-d/test-only/work-in-progress/PR-${PR_NUMBER}/ s3://cimr-d/test-only/ --recursive
aws s3 mv s3://cimr-root/test-only/work-in-progress/PR-${PR_NUMBER}/ s3://cimr-root/test-only/ --recursive

# Add new commits
mkdir -p processed/PR-${PR_NUMBER}/
git mv -k submitted/*.yml submitted/*.yaml processed/PR-${PR_NUMBER}/
git commit -m "CircleCI: Save requests to processed/ dir [skip ci]"
git push --force --quiet origin master
