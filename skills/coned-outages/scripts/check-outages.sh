#!/bin/bash
# Check Con Edison outages for NYC and Westchester
# Outputs JSON with summary and area breakdowns

set -e

BASE_URL="https://outagemap.coned.com/resources/data/external/interval_generation_data"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

# Get current data directory from metadata
METADATA=$(curl -s --compressed "$BASE_URL/metadata.json" -H "User-Agent: $UA")
DIR=$(echo "$METADATA" | jq -r '.directory')

if [ -z "$DIR" ] || [ "$DIR" = "null" ]; then
    echo '{"error": "Failed to fetch metadata"}'
    exit 1
fi

DATA_URL="$BASE_URL/$DIR"

# Fetch all data in parallel
SUMMARY=$(curl -s --compressed "$DATA_URL/data.json" -H "User-Agent: $UA")
NYC=$(curl -s --compressed "$DATA_URL/report_nyc.json" -H "User-Agent: $UA")
WESTCHESTER=$(curl -s --compressed "$DATA_URL/report_westchester.json" -H "User-Agent: $UA")

# Extract summary stats
TOTAL_OUTAGES=$(echo "$SUMMARY" | jq '.summaryFileData.total_outages')
TOTAL_AFFECTED=$(echo "$SUMMARY" | jq '.summaryFileData.total_cust_a.val')
TOTAL_SERVED=$(echo "$SUMMARY" | jq '.summaryFileData.total_cust_s')
GENERATED=$(echo "$SUMMARY" | jq -r '.summaryFileData.date_generated')

# Extract NYC borough data
NYC_DATA=$(echo "$NYC" | jq '{
    total_outages: .file_data.areas[0].total_outages,
    total_affected: .file_data.areas[0].cust_a.val,
    etr: .file_data.areas[0].etr,
    boroughs: [.file_data.areas[0].areas[] | {
        name: .area_name,
        outages: .total_outages,
        affected: .cust_a.val,
        served: .cust_s,
        etr: .etr
    }]
}')

# Extract Westchester data
WESTCHESTER_DATA=$(echo "$WESTCHESTER" | jq '{
    total_outages: .file_data.areas[0].total_outages,
    total_affected: .file_data.areas[0].cust_a.val,
    etr: .file_data.areas[0].etr
}')

# Find areas with significant outages (>0 customers affected)
AREAS_WITH_OUTAGES=$(echo "$NYC" | jq '[
    .file_data.areas[0].areas[] | 
    select(.cust_a.val > 0) | 
    {borough: .area_name, affected: .cust_a.val, outages: .total_outages, etr: .etr},
    (.areas[]? | select(.cust_a.val > 0) | {area: .area_name, affected: .cust_a.val, etr: .etr})
] | sort_by(-.affected)')

# Combine into final output
jq -n \
    --argjson total_outages "$TOTAL_OUTAGES" \
    --argjson total_affected "$TOTAL_AFFECTED" \
    --argjson total_served "$TOTAL_SERVED" \
    --arg generated "$GENERATED" \
    --argjson nyc "$NYC_DATA" \
    --argjson westchester "$WESTCHESTER_DATA" \
    --argjson areas_with_outages "$AREAS_WITH_OUTAGES" \
    '{
        summary: {
            total_outages: $total_outages,
            total_affected: $total_affected,
            total_served: $total_served,
            generated: $generated
        },
        nyc: $nyc,
        westchester: $westchester,
        areas_with_outages: $areas_with_outages
    }'
