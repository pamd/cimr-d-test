#!/bin/bash
#
# This script will be triggered when "master" branch is updated.
# It copies new files in "submitted_data" and "processed_data" to S3 buckets,
# then cleans up everything in "submitted_data" directory and commits the
# change back to remote repo.

set -e -x

# Git config
git config --global user.email "cimrroot@gmail.com"
git config --global user.name "cimrroot"
git config --global push.default simple

cd ~/cimr-d/
git lfs install

# Sync files in "submitted_data" directory to private S3 bucket "cimr-root",
if [ -f my_request.done ]; then
    aws s3 sync s3://cimr-root/ s3://cimr-root

    git rm my_request.yml
    git commit -m "CircleCI: remove my_request.yml [skip ci]"
    git push --force --quiet origin master

    # Sync files in "processed_data" directory to public S3 bucket "cimr-d"
    aws s3 sync processed_data s3://cimr-d
fi
