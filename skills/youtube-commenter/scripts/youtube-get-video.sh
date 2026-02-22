#!/bin/bash
# Get video details and top comments for context
# Usage: youtube-get-video.sh VIDEO_ID
# Returns: Video info + top comments

set -e

VIDEO_ID="$1"

if [ -z "$VIDEO_ID" ]; then
    echo "Usage: youtube-get-video.sh VIDEO_ID"
    exit 1
fi

# Get access token
SCRIPT_DIR="$(dirname "$0")"
ACCESS_TOKEN=$("$SCRIPT_DIR/youtube-auth.sh")

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
    echo "ERROR: Failed to get access token"
    exit 1
fi

# Get video details
echo "=== VIDEO ==="
curl -s "https://www.googleapis.com/youtube/v3/videos" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -G \
    --data-urlencode "part=snippet,statistics" \
    --data-urlencode "id=$VIDEO_ID" | jq '.items[0] | {
        title: .snippet.title,
        channel: .snippet.channelTitle,
        published: .snippet.publishedAt,
        description: .snippet.description[:500],
        views: .statistics.viewCount,
        likes: .statistics.likeCount,
        comments: .statistics.commentCount
    }'

# Get top comments
echo ""
echo "=== TOP COMMENTS ==="
curl -s "https://www.googleapis.com/youtube/v3/commentThreads" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -G \
    --data-urlencode "part=snippet" \
    --data-urlencode "videoId=$VIDEO_ID" \
    --data-urlencode "order=relevance" \
    --data-urlencode "maxResults=5" | jq '[.items[] | {
        author: .snippet.topLevelComment.snippet.authorDisplayName,
        text: .snippet.topLevelComment.snippet.textDisplay[:200],
        likes: .snippet.topLevelComment.snippet.likeCount
    }]'
