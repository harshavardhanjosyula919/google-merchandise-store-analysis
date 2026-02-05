# Conversion Optimization Analysis: Executive Summary

**Google Merchandise Store | February 2025**  
**Prepared by:** Sri Harshavardhan Josyula

---

## The Question

> Which user segments have the highest conversion potential but lowest current conversion rates — and what intervention would close the gap?

---

## Key Findings

### Finding 1: The Social Traffic Problem

| Channel | Traffic Share | Transaction Share | Conversion Rate |
|---------|---------------|-------------------|-----------------|
| **Social** | **25.0%** | **1.1%** | **0.05%** |
| Organic Search | 42.2% | 29.6% | 0.90% |
| Referral | 11.6% | 45.8% | 5.08% |
| Direct | 15.8% | 18.3% | 1.44% |

**Insight:** Social media is driving a quarter of all traffic but almost zero revenue. This is low-intent traffic that never converts. Meanwhile, Referral (only 11.6% of traffic) drives nearly half of all transactions.

---

### Finding 2: Visit Frequency is the Conversion Lever

| Visit Number | Conversion Rate | Lift vs. 1st Visit |
|--------------|-----------------|---------------------|
| 1st visit | 0.64% | Baseline |
| 2nd visit | 2.72% | **4.3x** |
| 3rd visit | 4.01% | **6.3x** |
| 4-5 visits | 4.69% | **7.4x** |

**Insight:** Getting someone to return even once increases conversion probability by 4.3x. The sweet spot is visits 2-5; after that, diminishing returns.

---

### Finding 3: Returning Visitors Convert 5.5x Better

| Visitor Type | Conversion Rate | Share of Sessions |
|--------------|-----------------|-------------------|
| New | 0.64% | 77.8% |
| Returning | 3.53% | 22.2% |

**Insight:** First-visit conversion is nearly impossible (0.64%). The path to revenue runs through re-engagement.

---

## Recommendations

### Priority 1: Fix Social or Reallocate
- **Problem:** 25% of traffic at 0.05% conversion = wasted resources
- **Action:** Audit Social targeting; if quality can't improve, shift budget to Referral
- **Impact:** 10x improvement in Social would still only match Organic Search

### Priority 2: Accelerate Return Visits
- **Problem:** 77.8% of visitors never return; conversion dies at 0.64%
- **Action:** Email capture on first visit + 7-day remarketing sequence
- **Impact:** Converting 10% of new → returning could lift transactions 20%+

### Priority 3: Scale Referral Partnerships
- **Problem:** Best channel (5.08% conversion) is only 11.6% of traffic
- **Action:** Identify top referral sources, expand partnerships
- **Impact:** Referral already drives 45% of revenue; scaling multiplies

---

## What I'd Test Next

1. **Social audience audit** — Are we targeting the right demographics? Test interest-based vs. lookalike audiences

2. **Return visit acceleration** — A/B test email capture timing (immediate vs. exit intent) and remarketing cadence (3-day vs. 7-day)

3. **Referral attribution deep-dive** — Which specific referral sources drive the 5% conversion? Can we replicate?

---

## Methodology

- **Data Source:** Google Analytics sample dataset (BigQuery public data)
- **Time Period:** August 2016 – August 2017 (903,653 sessions)
- **Tools:** SQL (BigQuery), Python (pandas, matplotlib)

---

*This analysis demonstrates my approach to strategic analytics: framing business questions, conducting rigorous quantitative analysis, and translating findings into prioritized, actionable recommendations.*
```

