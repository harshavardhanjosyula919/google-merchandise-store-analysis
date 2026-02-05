# Google Merchandise Store: Conversion Optimization Analysis

## Executive Summary

**Business Question:** Which user segments have the highest conversion potential but lowest current conversion rates — and what intervention would close the gap?

**Key Finding:** Social traffic represents a massive untapped opportunity — it accounts for **25% of all traffic but only 1% of transactions** (conversion rate: 0.05%). Meanwhile, Referral traffic (only 11.6% of sessions) drives **45.75% of all transactions**. The data also shows that returning visitors convert at **5.5x the rate of new visitors**, suggesting re-engagement is a higher-ROI lever than new acquisition.

**Recommendation:** Deprioritize Social as an acquisition channel unless engagement quality can be improved. Double down on Referral partnerships. Implement aggressive re-engagement within the first 7 days to convert one-time visitors into returning customers.

---

## Project Overview

This analysis uses Google's public BigQuery dataset containing Google Analytics data from the Google Merchandise Store — an ecommerce site selling Google-branded merchandise. The dataset includes **903,653 sessions** with user behavior, traffic sources, device information, and transaction data.

### Why This Analysis Matters

Google's SMB advertising business depends on helping small businesses understand which traffic sources and user behaviors actually drive revenue. This analysis demonstrates the diagnostic framework used to identify conversion gaps and prioritize interventions.

---

## Repository Structure
```
├── README.md                      # This file
├── 01_data_exploration.sql        # Initial data profiling and quality checks
├── 02_conversion_funnel.sql       # Funnel analysis by segment
├── 03_segment_deep_dive.sql       # High-potential segment identification
├── 04_cohort_analysis.sql         # User behavior patterns over time
├── findings_memo.md               # Executive summary (1-page)
└── visuals/                       # Charts and diagrams
```

---

## Key Findings

### Finding 1: The Social Traffic Problem

| Channel | Traffic Share | Transaction Share | Conversion Rate | Gap |
|---------|---------------|-------------------|-----------------|-----|
| **Social** | **25.0%** | **1.1%** | **0.05%** | **-23.9pp** |
| Organic Search | 42.2% | 29.6% | 0.90% | -12.7pp |
| Referral | 11.6% | 45.8% | 5.08% | +34.2pp |
| Direct | 15.8% | 18.3% | 1.44% | +2.5pp |

**Insight:** Social media drives a quarter of all traffic but almost zero transactions. This traffic is likely low-intent browsers. Referral traffic, despite being only 11.6% of sessions, generates nearly half of all revenue.

---

### Finding 2: Visit Frequency is the #1 Conversion Lever

| Visit Number | Conversion Rate | Lift vs. 1st Visit |
|--------------|-----------------|---------------------|
| 1st visit | 0.64% | Baseline |
| 2nd visit | 2.72% | **4.3x** |
| 3rd visit | 4.01% | **6.3x** |
| 4-5 visits | 4.69% | **7.4x** |
| 6-10 visits | 4.69% | 7.4x |
| 11+ visits | 3.31% | 5.2x |

**Insight:** Users who return just once convert at 4.3x the rate of first-time visitors. The conversion rate peaks at 4-5 visits (7.4x lift), then slightly declines.

---

### Finding 3: Returning Visitors Convert 5.5x Better

| Visitor Type | Sessions | Conversion Rate | Lift |
|--------------|----------|-----------------|------|
| New | 703,060 (77.8%) | 0.64% | Baseline |
| Returning | 200,593 (22.2%) | 3.53% | **5.5x** |

**Insight:** First-visit conversion is extremely difficult (0.64%). The path to revenue runs through re-engagement.

---

## Recommendations

### Priority 1: Fix the Social Traffic Problem
- **Why:** 25% of traffic, 0.05% conversion rate — massive inefficiency
- **Action:** Audit Social audience targeting; likely attracting low-intent browsers
- **Expected Impact:** Even modest improvement (0.05% → 0.5%) would 10x Social's transaction contribution

### Priority 2: Accelerate Return Visits
- **Why:** 2nd visit = 4.3x conversion lift; diminishing returns after visit 5
- **Action:** Implement email capture + 7-day remarketing sequence for new visitors
- **Expected Impact:** Converting 10% of new visitors to returning could increase transactions by 20%+

### Priority 3: Double Down on Referral
- **Why:** 5.08% conversion rate — 5x higher than any other major channel
- **Action:** Identify top referral sources, expand partnerships
- **Expected Impact:** Referral already drives 45% of transactions; scaling this channel compounds

---

## Technical Stack

- **Data Source:** `bigquery-public-data.google_analytics_sample`
- **SQL:** Google BigQuery (Standard SQL)
- **Python:** pandas, matplotlib, seaborn
- **Analysis Period:** August 2016 – August 2017

---

## How to Run

### BigQuery Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/bigquery)
2. Create a project (free tier is sufficient)
3. Copy SQL from `.sql` files and run in BigQuery editor

---

## About

**Author:** Sri Harshavardhan Josyula  
**Contact:** harshajosyula75@gmail.com | [LinkedIn](https://linkedin.com/in/harshajosyula)

This project demonstrates my approach to strategic analytics: framing business questions, conducting rigorous analysis, and translating findings into actionable recommendations.
