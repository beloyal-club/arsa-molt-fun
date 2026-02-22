#!/bin/bash
# Post a comment on a YouTube video
# Usage: youtube-comment.sh VIDEO_ID "Comment text"
# Returns: Comment ID on success

set -e

VIDEO_ID="$1"
COMMENT_TEXT="$2"

if [ -z "$VIDEO_ID" ] || [ -z "$COMMENT_TEXT" ]; then
    echo "Usage: youtube-comment.sh VIDEO_ID \"Comment text\""
    exit 1
fi

# Get access token
SCRIPT_DIR="$(dirname "$0")"
ACCESS_TOKEN=$("$SCRIPT_DIR/youtube-auth.sh")

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
    echo "ERROR: Failed to get access token"
    exit 1
fi

# Post comment
RESPONSE=$(curl -s -X POST "https://www.googleapis.com/youtube/v3/commentThreads?part=snippet" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"snippet\": {
            \"videoId\": \"$VIDEO_ID\",
            \"topLevelComment\": {
                \"snippet\": {
                    \"textOriginal\": \"$COMMENT_TEXT\"
                }
            }
        }
    }")

# Check for error
ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty')
if [ -n "$ERROR" ]; then
    echo "ERROR: $ERROR"
    exit 1
fi

# Return comment ID
COMMENT_ID=$(echo "$RESPONSE" | jq -r '.id')
echo "Posted comment: $COMMENT_ID"
echo "Video: https://youtube.com/watch?v=$VIDEO_ID"
