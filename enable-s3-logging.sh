#!/bin/bash

# Script to enable S3 server access logging on existing buckets
# Usage: ./enable-s3-logging.sh <target-bucket-name> <log-bucket-name>

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <target-bucket-name> <log-bucket-name>"
    echo "Example: $0 my-pdf-bucket my-logs-bucket"
    exit 1
fi

TARGET_BUCKET=$1
LOG_BUCKET=$2
LOG_PREFIX="${TARGET_BUCKET}-logs/"

echo "Enabling server access logging for bucket: $TARGET_BUCKET"
echo "Logs will be stored in: $LOG_BUCKET with prefix: $LOG_PREFIX"

# Create the log bucket if it doesn't exist
if ! aws s3 ls "s3://$LOG_BUCKET" 2>&1 > /dev/null; then
    echo "Creating log bucket: $LOG_BUCKET"
    aws s3 mb "s3://$LOG_BUCKET"
    
    # Block public access on log bucket
    aws s3api put-public-access-block \
        --bucket "$LOG_BUCKET" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
fi

# Enable server access logging
aws s3api put-bucket-logging \
    --bucket "$TARGET_BUCKET" \
    --bucket-logging-status "{
        \"LoggingEnabled\": {
            \"TargetBucket\": \"$LOG_BUCKET\",
            \"TargetPrefix\": \"$LOG_PREFIX\"
        }
    }"

echo "✓ Server access logging enabled successfully!"
echo "Logs location: s3://$LOG_BUCKET/$LOG_PREFIX"
