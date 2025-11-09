#!/usr/bin/env bash
set -euo pipefail


# Usage: ./invalidate-cache.sh <cloudfront-distribution-id> [paths]
DIST_ID=${1:-}
PATHS=${2:-"/*"}


if [[ -z "$DIST_ID" ]]; then
echo "Usage: $0 <cloudfront-distribution-id> [paths]"
exit 2
fi


echo "Creating invalidation for $DIST_ID paths: $PATHS"
aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths $PATHS


echo "Invalidation requested."