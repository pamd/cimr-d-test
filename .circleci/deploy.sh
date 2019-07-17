#!/bin/bash
#
# This script will be triggered when "master" branch is updated.
# It copies new files in "submitted_data" and "processed_data" to S3 buckets,
# then cleans up everything in "submitted_data" directory and commits the
# change back to remote repo.

set -e -x

function clear_submitted_dir() {
    if [ -f submitted/* ]; then
	git rm submitted/*
	git commit -m "CircleCI: keep submitted dir empty [skip ci]"
    fi
}

# Git config
git config --global user.email "cimrroot@gmail.com"
git config --global user.name "cimrroot"
git config --global push.default simple

cd ~/cimr-d/
git lfs install

LATEST_COMMIT_ID=$(git log -1 --pretty=format:%h)
GITHUB_SEARCH_URL="https://api.github.com/search/issues?q=sha:${LATEST_COMMIT_ID}"
PR_NUMBER=curl -s $GITHUB_SEARCH_URL | jq '.items[0].number'

# If we're not merging a PR, clean up "submitted/" dir and exit.
if [ $PR_NUMBER='null' ]; then
    clear_submitted_dir
    exit 0
fi

# If we are merging a PR, but the indicator file doesn't exist in "cimr-root"
# S3 bucket, data processing must either fail or not get involved, so we exit too.
INDICATOR_KEY=test-submitted/PR_$PR_NUMBER/req_success.txt
aws s3api head-object --bucket cimr-root --key $INDICATOR_KEY || NO_PROCESSED_DATA=true
if [ $NO_PROCESSED_DATA ]; then
    clear_submitted_dir
    exit 0
fi

# Sync files in "submitted_data" directory to private S3 bucket "cimr-root",
aws s3 sync s3://cimr-root/test_processed/PR_${PR_NUMBER}/ s3://cimr-d/
git mv submitted/* processed
git commit -m "CircleCI: save request(s) to processed/ [skip ci]"
git push --force --quiet origin master
