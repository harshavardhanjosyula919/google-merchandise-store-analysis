-- ============================================================================
-- 03_SEGMENT_DEEP_DIVE.SQL
-- Google Merchandise Store Analysis
-- Purpose: Deep dive into high-potential segments to understand behavior
-- ============================================================================

-- ============================================================================
-- SECTION 1: SOCIAL TRAFFIC DEEP DIVE
-- (Identified as high-traffic, low-conversion segment)
-- ============================================================================

-- 1.1 Social traffic by device
SELECT 
    device.deviceCategory,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(COUNTIF(totals.bounces = 1) * 100.0 / COUNT(*), 2) AS bounce_rate_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
  AND channelGrouping = 'Social'
GROUP BY device.deviceCategory
ORDER BY sessions DESC;


-- 1.2 Social traffic by source (which social platforms?)
SELECT 
    trafficSource.source,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(AVG(totals.pageviews), 2) AS avg_pageviews
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
  AND channelGrouping = 'Social'
GROUP BY trafficSource.source
ORDER BY sessions DESC
LIMIT 15;


-- ============================================================================
-- SECTION 2: REFERRAL TRAFFIC DEEP DIVE
-- (High-converting segment - understand why)
-- ============================================================================

-- 2.1 Top referral sources
SELECT 
    trafficSource.source,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(SUM(IFNULL(totals.totalTransactionRevenue, 0)) / 1000000, 2) AS revenue_usd
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
  AND channelGrouping = 'Referral'
GROUP BY trafficSource.source
ORDER BY revenue_usd DESC
LIMIT 15;


-- 2.2 Referral traffic behavior comparison
SELECT 
    channelGrouping,
    COUNT(*) AS sessions,
    ROUND(AVG(totals.pageviews), 2) AS avg_pageviews,
    ROUND(AVG(totals.timeOnSite), 2) AS avg_time_on_site_sec,
    ROUND(COUNTIF(totals.bounces = 1) * 100.0 / COUNT(*), 2) AS bounce_rate_pct,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY channelGrouping
ORDER BY conversion_rate_pct DESC;


-- ============================================================================
-- SECTION 3: RETURNING VISITOR ANALYSIS
-- (5.5x higher conversion - understand the pattern)
-- ============================================================================

-- 3.1 How quickly do returning visitors come back?
WITH visitor_sessions AS (
    SELECT 
        fullVisitorId,
        visitNumber,
        PARSE_DATE('%Y%m%d', date) AS visit_date,
        totals.transactions
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
),
return_gaps AS (
    SELECT 
        fullVisitorId,
        visitNumber,
        visit_date,
        transactions,
        LAG(visit_date) OVER (PARTITION BY fullVisitorId ORDER BY visitNumber) AS prev_visit_date,
        DATE_DIFF(visit_date, LAG(visit_date) OVER (PARTITION BY fullVisitorId ORDER BY visitNumber), DAY) AS days_since_last_visit
    FROM visitor_sessions
)
SELECT 
    CASE 
        WHEN days_since_last_visit IS NULL THEN 'First visit'
        WHEN days_since_last_visit <= 1 THEN 'Same/next day'
        WHEN days_since_last_visit <= 7 THEN '2-7 days'
        WHEN days_since_last_visit <= 14 THEN '8-14 days'
        WHEN days_since_last_visit <= 30 THEN '15-30 days'
        ELSE '31+ days'
    END AS return_window,
    COUNT(*) AS sessions,
    COUNTIF(transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct
FROM return_gaps
GROUP BY return_window
ORDER BY 
    CASE return_window
        WHEN 'First visit' THEN 1
        WHEN 'Same/next day' THEN 2
        WHEN '2-7 days' THEN 3
        WHEN '8-14 days' THEN 4
        WHEN '15-30 days' THEN 5
        ELSE 6
    END;


-- 3.2 What channels bring back returning visitors?
SELECT 
    channelGrouping,
    COUNTIF(totals.newVisits = 1) AS new_visitor_sessions,
    COUNTIF(totals.newVisits IS NULL OR totals.newVisits != 1) AS returning_visitor_sessions,
    ROUND(COUNTIF(totals.newVisits IS NULL OR totals.newVisits != 1) * 100.0 / COUNT(*), 2) AS returning_pct,
    ROUND(
        COUNTIF((totals.newVisits IS NULL OR totals.newVisits != 1) AND totals.transactions > 0) * 100.0 / 
        NULLIF(COUNTIF(totals.newVisits IS NULL OR totals.newVisits != 1), 0)
    , 3) AS returning_conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY channelGrouping
ORDER BY returning_visitor_sessions DESC;


-- ============================================================================
-- SECTION 4: HIGH-ENGAGEMENT USER ANALYSIS
-- ============================================================================

-- 4.1 Users with 4+ pageviews: traffic source comparison
SELECT 
    channelGrouping,
    COUNT(*) AS high_engagement_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 2) AS conversion_rate_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
  AND totals.pageviews >= 4
GROUP BY channelGrouping
ORDER BY high_engagement_sessions DESC;


-- 4.2 Time of day patterns
SELECT 
    EXTRACT(HOUR FROM TIMESTAMP_SECONDS(visitStartTime)) AS hour_of_day,
    COUNT(*) AS sessions,
    COUNTIF(totals.pageviews >= 4) AS high_engagement_sessions,
    ROUND(COUNTIF(totals.pageviews >= 4) * 100.0 / COUNT(*), 2) AS high_engagement_rate_pct,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- ============================================================================
-- SECTION 5: LANDING PAGE ANALYSIS
-- ============================================================================

-- 5.1 Top landing pages by traffic and conversion
SELECT 
    hits.page.pagePath AS landing_page,
    COUNT(DISTINCT CONCAT(fullVisitorId, CAST(visitId AS STRING))) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(COUNTIF(totals.bounces = 1) * 100.0 / COUNT(*), 2) AS bounce_rate_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
  AND hits.hitNumber = 1
  AND hits.type = 'PAGE'
GROUP BY landing_page
HAVING sessions > 500
ORDER BY sessions DESC
LIMIT 20;
