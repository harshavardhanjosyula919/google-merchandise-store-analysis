-- ============================================================================
-- 01_DATA_EXPLORATION.SQL
-- Google Merchandise Store Analysis
-- Purpose: Initial data profiling, quality checks, and baseline metrics
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATASET OVERVIEW
-- ============================================================================

-- 1.1 Count total sessions and date range
SELECT 
    COUNT(*) AS total_sessions,
    COUNT(DISTINCT fullVisitorId) AS unique_visitors,
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date,
    COUNT(DISTINCT date) AS days_in_dataset
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801';


-- 1.2 Sessions per day (check for anomalies)
SELECT 
    date,
    COUNT(*) AS sessions,
    COUNT(DISTINCT fullVisitorId) AS unique_visitors
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY date
ORDER BY date;


-- ============================================================================
-- SECTION 2: TRAFFIC SOURCE BREAKDOWN
-- ============================================================================

-- 2.1 Traffic by channel grouping
SELECT 
    channelGrouping,
    COUNT(*) AS sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_traffic,
    COUNT(DISTINCT fullVisitorId) AS unique_visitors
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY channelGrouping
ORDER BY sessions DESC;


-- 2.2 Traffic by source/medium (more granular)
SELECT 
    trafficSource.source,
    trafficSource.medium,
    COUNT(*) AS sessions,
    COUNT(DISTINCT fullVisitorId) AS unique_visitors
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY trafficSource.source, trafficSource.medium
ORDER BY sessions DESC
LIMIT 20;


-- ============================================================================
-- SECTION 3: DEVICE & GEO BREAKDOWN
-- ============================================================================

-- 3.1 Traffic by device category
SELECT 
    device.deviceCategory,
    COUNT(*) AS sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_traffic,
    COUNT(DISTINCT fullVisitorId) AS unique_visitors
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY device.deviceCategory
ORDER BY sessions DESC;


-- 3.2 Traffic by country (top 10)
SELECT 
    geoNetwork.country,
    COUNT(*) AS sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_traffic
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY geoNetwork.country
ORDER BY sessions DESC
LIMIT 10;


-- ============================================================================
-- SECTION 4: TRANSACTION BASELINE
-- ============================================================================

-- 4.1 Overall conversion rate
SELECT 
    COUNT(*) AS total_sessions,
    COUNTIF(totals.transactions > 0) AS sessions_with_transaction,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    SUM(totals.transactions) AS total_transactions,
    ROUND(SUM(totals.totalTransactionRevenue) / 1000000, 2) AS total_revenue_usd
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801';


-- 4.2 Transactions by month (trend)
SELECT 
    SUBSTR(date, 1, 6) AS month,
    COUNT(*) AS sessions,
    COUNTIF(totals.transactions > 0) AS transactions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(SUM(totals.totalTransactionRevenue) / 1000000, 2) AS revenue_usd
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY month
ORDER BY month;


-- ============================================================================
-- SECTION 5: USER BEHAVIOR BASELINE
-- ============================================================================

-- 5.1 Distribution of pageviews per session
SELECT 
    CASE 
        WHEN totals.pageviews = 1 THEN '1 page'
        WHEN totals.pageviews BETWEEN 2 AND 3 THEN '2-3 pages'
        WHEN totals.pageviews BETWEEN 4 AND 6 THEN '4-6 pages'
        WHEN totals.pageviews BETWEEN 7 AND 10 THEN '7-10 pages'
        ELSE '11+ pages'
    END AS pageview_bucket,
    COUNT(*) AS sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_sessions
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


-- 5.2 New vs returning visitors
SELECT 
    CASE WHEN totals.newVisits = 1 THEN 'New' ELSE 'Returning' END AS visitor_type,
    COUNT(*) AS sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_sessions,
    COUNT(DISTINCT fullVisitorId) AS unique_visitors
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY visitor_type;


-- 5.3 Bounce rate by channel
SELECT 
    channelGrouping,
    COUNT(*) AS sessions,
    COUNTIF(totals.bounces = 1) AS bounces,
    ROUND(COUNTIF(totals.bounces = 1) * 100.0 / COUNT(*), 2) AS bounce_rate_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY channelGrouping
ORDER BY sessions DESC;


-- ============================================================================
-- SECTION 6: DATA QUALITY CHECKS
-- ============================================================================

-- 6.1 Check for null/missing values in key fields
SELECT 
    COUNTIF(fullVisitorId IS NULL) AS null_visitor_id,
    COUNTIF(date IS NULL) AS null_date,
    COUNTIF(channelGrouping IS NULL) AS null_channel,
    COUNTIF(device.deviceCategory IS NULL) AS null_device,
    COUNTIF(geoNetwork.country IS NULL) AS null_country,
    COUNTIF(totals.pageviews IS NULL) AS null_pageviews,
    COUNTIF(totals.transactions IS NULL) AS null_transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801';
