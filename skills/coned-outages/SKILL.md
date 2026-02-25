---
name: coned-outages
description: Check NYC Con Edison power outages. Use when asked about power outages, blackouts, or electricity status in NYC, Bronx, Brooklyn, Manhattan, Queens, Staten Island, or Westchester. Reports current outage counts, affected customers, and restoration times by area.
---

# Con Edison Outages

Check real-time power outage data from Con Edison's outage map.

## Usage

Run the check script:

```bash
bash skills/coned-outages/scripts/check-outages.sh
```

The script outputs JSON with:
- `summary`: Total outages, customers affected, timestamp
- `nyc`: Breakdown by borough (Bronx, Brooklyn, Manhattan, Queens, Staten Island)
- `westchester`: Westchester county breakdown
- `areas_with_outages`: List of areas with active outages

## Data Source

Data is fetched from Con Edison's public outage map API (outagemap.coned.com).
Updates every 15-30 minutes.

## Interpreting Results

- `cust_a`: Customers affected (accounts, not individuals)
- `cust_s`: Customers served (total accounts in area)
- `total_outages`: Number of separate outage incidents
- `etr`: Estimated Time of Restoration (ISO timestamp or "ETR-NULL"/"ETR-EXP")

## Example Report Format

When reporting to user, summarize like:

> **Con Edison Outages** (as of 4:05 PM ET)
> 
> **NYC Total:** 405 outages affecting 3,523 customers
> - Brooklyn: 1,658 customers (216 outages) — ETA tomorrow 11 PM
> - Queens: 919 customers (136 outages) — ETA tomorrow 11 PM
> - Bronx: 601 customers (19 outages) — ETA 7:30 PM
> - Manhattan: 344 customers (33 outages) — ETA 9 PM
> - Staten Island: 1 customer — ETA 5 PM
>
> **Westchester:** 1 outage affecting 2 customers
