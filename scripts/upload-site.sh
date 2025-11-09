#!/usr/bin/env bash
set -euo pipefail


# Usage: ./upload-site.sh <s3-bucket-name>
BUCKET=${1:-}
if [[ -z "$BUCKET" ]]; then
echo "Usage: $0 <s3-bucket-name>"
exit 2
fi


echo "Uploading site/ to s3://$BUCKET ..."
aws s3 sync ./site s3://$BUCKET --delete --acl private


echo "Upload complete."