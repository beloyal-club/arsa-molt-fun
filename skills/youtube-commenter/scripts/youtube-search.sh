#!/bin/bash
# Search YouTube videos
# Usage: youtube-search.sh "query" [max_results]
# Returns: JSON with video IDs, titles, channels, publish dates

set -e

QUERY="${1:-NYC events}"
MAX_RESULTS="${2:-10}"

# Get access token
SCRIPT_DIR="$(dirname "$0")"
ACCESS_TOKEN=$("$SCRIPT_DIR/youtube-auth.sh")

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
    echo "ERROR: Failed to get access token"
    exit 1
fi

# Search videos (published in last 7 days, sorted by date)
PUBLISHED_AFTER=$(date -u -d '7 days ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-7d '+%Y-%m-%dT%H:%M:%SZ')

curl -s "https://www.googleapis.com/youtube/v3/search" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -G \
    --data-urlencode "part=snippet" \
    --data-urlencode "q=$QUERY" \
    --data-urlencode "type=video" \
    --data-urlencode "order=date" \
    --data-urlencode "publishedAfter=$PUBLISHED_AFTER" \
    --data-urlencode "maxResults=$MAX_RESULTS" \
    --data-urlencode "regionCode=US" \
    --data-urlencode "relevanceLanguage=en" | jq '{
        videos: [.items[] | {
            id: .id.videoId,
            title: .snippet.title,
            channel: .snippet.channelTitle,
            published: .snippet.publishedAt,
            description: .snippet.description[:200]
        }]
    }'
