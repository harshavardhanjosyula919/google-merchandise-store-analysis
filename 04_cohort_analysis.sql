-- ============================================================================
-- 04_COHORT_ANALYSIS.SQL
-- Google Merchandise Store Analysis
-- Purpose: Analyze user behavior patterns over time and cohort retention
-- ============================================================================

-- ============================================================================
-- SECTION 1: ACQUISITION COHORT ANALYSIS
-- ============================================================================

-- 1.1 Define acquisition cohorts (month of first visit)
WITH user_first_visit AS (
    SELECT 
        fullVisitorId,
        MIN(PARSE_DATE('%Y%m%d', date)) AS first_visit_date,
        FORMAT_DATE('%Y-%m', MIN(PARSE_DATE('%Y%m%d', date))) AS acquisition_cohort
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
    GROUP BY fullVisitorId
),
user_activity AS (
    SELECT 
        s.fullVisitorId,
        u.acquisition_cohort,
        u.first_visit_date,
        PARSE_DATE('%Y%m%d', s.date) AS activity_date,
        DATE_DIFF(PARSE_DATE('%Y%m%d', s.date), u.first_visit_date, MONTH) AS months_since_acquisition,
        s.totals.transactions
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` s
    JOIN user_first_visit u ON s.fullVisitorId = u.fullVisitorId
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
)
SELECT 
    acquisition_cohort,
    months_since_acquisition,
    COUNT(DISTINCT fullVisitorId) AS active_users,
    COUNTIF(transactions > 0) AS converting_sessions,
    COUNT(*) AS total_sessions
FROM user_activity
WHERE months_since_acquisition <= 6
GROUP BY acquisition_cohort, months_since_acquisition
ORDER BY acquisition_cohort, months_since_acquisition;


-- ============================================================================
-- SECTION 2: TIME TO CONVERSION ANALYSIS
-- ============================================================================

-- 2.1 How many visits before first conversion?
WITH user_conversions AS (
    SELECT 
        fullVisitorId,
        visitNumber,
        PARSE_DATE('%Y%m%d', date) AS visit_date,
        totals.transactions,
        ROW_NUMBER() OVER (
            PARTITION BY fullVisitorId 
            ORDER BY CASE WHEN totals.transactions > 0 THEN 0 ELSE 1 END, visitNumber
        ) AS rn
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
),
first_conversion AS (
    SELECT 
        fullVisitorId,
        visitNumber AS conversion_visit_number
    FROM user_conversions
    WHERE transactions > 0 AND rn = 1
)
SELECT 
    CASE 
        WHEN conversion_visit_number = 1 THEN '1st visit'
        WHEN conversion_visit_number = 2 THEN '2nd visit'
        WHEN conversion_visit_number = 3 THEN '3rd visit'
        WHEN conversion_visit_number BETWEEN 4 AND 5 THEN '4-5 visits'
        WHEN conversion_visit_number BETWEEN 6 AND 10 THEN '6-10 visits'
        ELSE '11+ visits'
    END AS visits_to_convert,
    COUNT(*) AS converting_users,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_converters
FROM first_conversion
GROUP BY visits_to_convert
ORDER BY 
    CASE visits_to_convert
        WHEN '1st visit' THEN 1
        WHEN '2nd visit' THEN 2
        WHEN '3rd visit' THEN 3
        WHEN '4-5 visits' THEN 4
        WHEN '6-10 visits' THEN 5
        ELSE 6
    END;


-- 2.2 Days between first visit and first conversion
WITH user_first_visit AS (
    SELECT 
        fullVisitorId,
        MIN(PARSE_DATE('%Y%m%d', date)) AS first_visit_date
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
    GROUP BY fullVisitorId
),
user_first_conversion AS (
    SELECT 
        fullVisitorId,
        MIN(PARSE_DATE('%Y%m%d', date)) AS first_conversion_date
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
      AND totals.transactions > 0
    GROUP BY fullVisitorId
)
SELECT 
    CASE 
        WHEN DATE_DIFF(c.first_conversion_date, v.first_visit_date, DAY) = 0 THEN 'Same day'
        WHEN DATE_DIFF(c.first_conversion_date, v.first_visit_date, DAY) = 1 THEN 'Next day'
        WHEN DATE_DIFF(c.first_conversion_date, v.first_visit_date, DAY) <= 7 THEN '2-7 days'
        WHEN DATE_DIFF(c.first_conversion_date, v.first_visit_date, DAY) <= 14 THEN '8-14 days'
        WHEN DATE_DIFF(c.first_conversion_date, v.first_visit_date, DAY) <= 30 THEN '15-30 days'
        ELSE '31+ days'
    END AS days_to_convert,
    COUNT(*) AS users,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_converters
FROM user_first_conversion c
JOIN user_first_visit v ON c.fullVisitorId = v.fullVisitorId
GROUP BY days_to_convert
ORDER BY 
    CASE days_to_convert
        WHEN 'Same day' THEN 1
        WHEN 'Next day' THEN 2
        WHEN '2-7 days' THEN 3
        WHEN '8-14 days' THEN 4
        WHEN '15-30 days' THEN 5
        ELSE 6
    END;


-- ============================================================================
-- SECTION 3: WEEKLY TREND ANALYSIS
-- ============================================================================

-- 3.1 Weekly conversion trends
SELECT 
    DATE_TRUNC(PARSE_DATE('%Y%m%d', date), WEEK) AS week_start,
    COUNT(*) AS sessions,
    COUNT(DISTINCT fullVisitorId) AS unique_visitors,
    COUNTIF(totals.transactions > 0) AS converting_sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(SUM(IFNULL(totals.totalTransactionRevenue, 0)) / 1000000, 2) AS revenue_usd
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY week_start
ORDER BY week_start;


-- 3.2 Day of week patterns
SELECT 
    FORMAT_DATE('%A', PARSE_DATE('%Y%m%d', date)) AS day_of_week,
    EXTRACT(DAYOFWEEK FROM PARSE_DATE('%Y%m%d', date)) AS day_num,
    COUNT(*) AS sessions,
    ROUND(COUNTIF(totals.transactions > 0) * 100.0 / COUNT(*), 3) AS conversion_rate_pct,
    ROUND(AVG(totals.pageviews), 2) AS avg_pageviews
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY day_of_week, day_num
ORDER BY day_num;


-- ============================================================================
-- SECTION 4: USER LIFETIME VALUE INDICATORS
-- ============================================================================

-- 4.1 Repeat purchaser analysis
WITH user_purchases AS (
    SELECT 
        fullVisitorId,
        COUNT(DISTINCT CONCAT(date, CAST(visitId AS STRING))) AS purchase_sessions,
        SUM(totals.transactions) AS total_transactions,
        SUM(totals.totalTransactionRevenue) / 1000000 AS total_revenue_usd
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
      AND totals.transactions > 0
    GROUP BY fullVisitorId
)
SELECT 
    CASE 
        WHEN purchase_sessions = 1 THEN '1 purchase'
        WHEN purchase_sessions = 2 THEN '2 purchases'
        WHEN purchase_sessions = 3 THEN '3 purchases'
        ELSE '4+ purchases'
    END AS purchase_frequency,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_customers,
    ROUND(AVG(total_revenue_usd), 2) AS avg_revenue_usd,
    ROUND(SUM(total_revenue_usd), 2) AS total_revenue_usd,
    ROUND(SUM(total_revenue_usd) * 100.0 / SUM(SUM(total_revenue_usd)) OVER(), 2) AS pct_of_revenue
FROM user_purchases
GROUP BY purchase_frequency
ORDER BY 
    CASE purchase_frequency
        WHEN '1 purchase' THEN 1
        WHEN '2 purchases' THEN 2
        WHEN '3 purchases' THEN 3
        ELSE 4
    END;


-- 4.2 First purchase channel vs repeat purchase behavior
WITH user_first_purchase AS (
    SELECT 
        fullVisitorId,
        channelGrouping AS first_purchase_channel,
        ROW_NUMBER() OVER (PARTITION BY fullVisitorId ORDER BY date, visitId) AS rn
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
      AND totals.transactions > 0
),
user_purchase_counts AS (
    SELECT 
        fullVisitorId,
        COUNT(*) AS total_purchase_sessions
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
      AND totals.transactions > 0
    GROUP BY fullVisitorId
)
SELECT 
    f.first_purchase_channel,
    COUNT(DISTINCT f.fullVisitorId) AS customers,
    ROUND(AVG(p.total_purchase_sessions), 2) AS avg_purchase_sessions,
    COUNTIF(p.total_purchase_sessions > 1) AS repeat_customers,
    ROUND(COUNTIF(p.total_purchase_sessions > 1) * 100.0 / COUNT(*), 2) AS repeat_rate_pct
FROM user_first_purchase f
JOIN user_purchase_counts p ON f.fullVisitorId = p.fullVisitorId
WHERE f.rn = 1
GROUP BY f.first_purchase_channel
ORDER BY customers DESC;


-- ============================================================================
-- SECTION 5: ENGAGEMENT PROGRESSION ANALYSIS
-- ============================================================================

-- 5.1 Do users who engage more on visit 1 return?
WITH first_visit_engagement AS (
    SELECT 
        fullVisitorId,
        totals.pageviews AS first_visit_pageviews,
        totals.timeOnSite AS first_visit_time,
        CASE 
            WHEN totals.pageviews = 1 THEN 'Low (1 page)'
            WHEN totals.pageviews BETWEEN 2 AND 3 THEN 'Medium (2-3 pages)'
            ELSE 'High (4+ pages)'
        END AS engagement_level
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
      AND visitNumber = 1
),
user_return AS (
    SELECT 
        fullVisitorId,
        MAX(visitNumber) AS max_visit_number,
        COUNTIF(totals.transactions > 0) AS conversion_count
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
    GROUP BY fullVisitorId
)
SELECT 
    f.engagement_level,
    COUNT(*) AS users,
    ROUND(COUNTIF(r.max_visit_number > 1) * 100.0 / COUNT(*), 2) AS return_rate_pct,
    ROUND(COUNTIF(r.conversion_count > 0) * 100.0 / COUNT(*), 2) AS eventual_conversion_rate_pct
FROM first_visit_engagement f
JOIN user_return r ON f.fullVisitorId = r.fullVisitorId
GROUP BY f.engagement_level
ORDER BY 
    CASE f.engagement_level
        WHEN 'Low (1 page)' THEN 1
        WHEN 'Medium (2-3 pages)' THEN 2
        ELSE 3
    END;
