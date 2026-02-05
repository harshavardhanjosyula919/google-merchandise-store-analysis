-- ============================================================================
-- 02_CONVERSION_FUNNEL.SQL
-- Google Merchandise Store Analysis
-- Purpose: Analyze conversion rates across key segments to identify gaps
-- ============================================================================

-- ============================================================================
-- SECTION 1: CONVERSION BY TRAFFIC CHANNEL
-- ============================================================================

-- 1.1 Conversion rate by channel grouping
SELECT 
    channelGrouping,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    SUM(IFNULL(totals.transactions, 0)) AS total_transactions,
    ROUND(SUM(IFNULL(totals.totalTransactionRevenue, 0)) / 1000000, 2) AS revenue_usd,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS traffic_share_pct,
    ROUND(SUM(IFNULL(totals.transactions, 0)) * 100.0 / 
          NULLIF(SUM(SUM(IFNULL(totals.transactions, 0))) OVER(), 0), 2) AS transaction_share_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY channelGrouping
ORDER BY sessions DESC;


-- 1.2 Identify channel conversion gaps (traffic share vs transaction share)
WITH channel_metrics AS (
    SELECT 
        channelGrouping,
        COUNT(*) AS sessions,
        SUM(IFNULL(totals.transactions, 0)) AS transactions,
        ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
    GROUP BY channelGrouping
)
SELECT 
    channelGrouping,
    sessions,
    transactions,
    conversion_rate,
    ROUND(sessions * 100.0 / SUM(sessions) OVER(), 2) AS traffic_share,
    ROUND(transactions * 100.0 / NULLIF(SUM(transactions) OVER(), 0), 2) AS transaction_share,
    ROUND(transactions * 100.0 / NULLIF(SUM(transactions) OVER(), 0), 2) - 
        ROUND(sessions * 100.0 / SUM(sessions) OVER(), 2) AS share_gap
FROM channel_metrics
ORDER BY share_gap ASC;


-- ============================================================================
-- SECTION 2: CONVERSION BY DEVICE
-- ============================================================================

-- 2.1 Conversion rate by device category
SELECT 
    device.deviceCategory,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS traffic_share_pct,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / 
          NULLIF(SUM(COUNTIF(totals.transactions > 0)) OVER(), 0), 2) AS transaction_share_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY device.deviceCategory
ORDER BY sessions DESC;


-- 2.2 Device + Channel cross-tabulation (find the worst combinations)
SELECT 
    device.deviceCategory,
    channelGrouping,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY device.deviceCategory, channelGrouping
HAVING sessions > 1000
ORDER BY conversion_rate_pct ASC;


-- ============================================================================
-- SECTION 3: CONVERSION BY GEOGRAPHY
-- ============================================================================

-- 3.1 Conversion rate by country (top 15 by traffic)
SELECT 
    geoNetwork.country,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(SUM(IFNULL(totals.totalTransactionRevenue, 0)) / 1000000, 2) AS revenue_usd
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY geoNetwork.country
ORDER BY sessions DESC
LIMIT 15;


-- ============================================================================
-- SECTION 4: CONVERSION BY VISITOR TYPE
-- ============================================================================

-- 4.1 New vs Returning visitor conversion
SELECT 
    CASE WHEN totals.newVisits = 1 THEN 'New Visitor' ELSE 'Returning Visitor' END AS visitor_type,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(AVG(totals.pageviews), 2) AS avg_pageviews,
    ROUND(AVG(totals.timeOnSite), 2) AS avg_time_on_site_sec
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY visitor_type;


-- 4.2 Conversion by visit number (how many visits before conversion?)
SELECT 
    CASE 
        WHEN visitNumber = 1 THEN '1st visit'
        WHEN visitNumber = 2 THEN '2nd visit'
        WHEN visitNumber = 3 THEN '3rd visit'
        WHEN visitNumber BETWEEN 4 AND 5 THEN '4-5 visits'
        WHEN visitNumber BETWEEN 6 AND 10 THEN '6-10 visits'
        ELSE '11+ visits'
    END AS visit_bucket,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY visit_bucket
ORDER BY 
    CASE visit_bucket
        WHEN '1st visit' THEN 1
        WHEN '2nd visit' THEN 2
        WHEN '3rd visit' THEN 3
        WHEN '4-5 visits' THEN 4
        WHEN '6-10 visits' THEN 5
        ELSE 6
    END;


-- ============================================================================
-- SECTION 5: ENGAGEMENT DEPTH VS CONVERSION
-- ============================================================================

-- 5.1 Conversion rate by pageviews per session
SELECT 
    CASE 
        WHEN totals.pageviews = 1 THEN '1 page'
        WHEN totals.pageviews BETWEEN 2 AND 3 THEN '2-3 pages'
        WHEN totals.pageviews BETWEEN 4 AND 6 THEN '4-6 pages'
        WHEN totals.pageviews BETWEEN 7 AND 10 THEN '7-10 pages'
        ELSE '11+ pages'
    END AS pageview_bucket,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY pageview_bucket
ORDER BY 
    CASE pageview_bucket
        WHEN '1 page' THEN 1
        WHEN '2-3 pages' THEN 2
        WHEN '4-6 pages' THEN 3
        WHEN '7-10 pages' THEN 4
        ELSE 5
    END;


-- 5.2 Conversion rate by time on site
SELECT 
    CASE 
        WHEN totals.timeOnSite IS NULL OR totals.timeOnSite = 0 THEN 'Bounce (0 sec)'
        WHEN totals.timeOnSite < 60 THEN '1-59 sec'
        WHEN totals.timeOnSite < 180 THEN '1-3 min'
        WHEN totals.timeOnSite < 300 THEN '3-5 min'
        WHEN totals.timeOnSite < 600 THEN '5-10 min'
        ELSE '10+ min'
    END AS time_bucket,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY time_bucket
ORDER BY 
    CASE time_bucket
        WHEN 'Bounce (0 sec)' THEN 1
        WHEN '1-59 sec' THEN 2
        WHEN '1-3 min' THEN 3
        WHEN '3-5 min' THEN 4
        WHEN '5-10 min' THEN 5
        ELSE 6
    END;


-- ============================================================================
-- SECTION 6: OPPORTUNITY SIZING
-- ============================================================================

-- 6.1 Top opportunity segments: high traffic, low conversion
SELECT 
    device.deviceCategory,
    channelGrouping,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS transactions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(COUNT(*) * (0.02 - COUNTIF(totals.transactions > 0) * 1.0 / COUNT(*)), 0) AS opportunity_score
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY device.deviceCategory, channelGrouping
HAVING sessions > 5000
ORDER BY opportunity_score DESC
LIMIT 10;
