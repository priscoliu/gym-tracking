# Global Loom — Executive Summary

**Project**: Policy Administration System (PAS) Data Warehouse
**Lakehouse**: The_Global_Loom
**Platform**: Microsoft Fabric (F16)
**Date**: March 2026
**Status**: Ready for Implementation

---

## Business Objective

Build a unified data warehouse from WTW's Policy Administration System (PAS) to enable:
- **Cross-sell analytics** — Identify clients buying one insurance product but not another
- **Financial reporting** — Premium, brokerage, and claims analysis across 56 global data sources
- **AI-powered insights** — Enable agent queries at transaction detail level

---

## Data Landscape

### Source System: PAS Silver Layer
- **18 tables** across 2 schemas (ref + rpt)
- **56 data sources** worldwide (Epic US, Eclipse, WIBS, eGlobal, etc.)
- **471 million** transaction detail rows
- **20 million** unique policies
- **3.7 million** parties (clients, carriers, brokers)

### Key Discovery Findings

| Finding | Business Impact |
|---------|-----------------|
| **471M transaction details** aggregate to **85M transactions** | Power BI can handle 85M rows (F16 capacity = 300M/table) |
| **20M genuinely unique policies** across 56 data sources | No deduplication needed — each policy is distinct |
| **626K global party entities** group 3.7M local parties | Enables cross-sell analysis across data sources |
| **16 product classes** (Property, Casualty, Marine, etc.) | Clear categories for cross-sell matrix |
| **Zero data quality issues** — all FK relationships validated | Production-ready data |

---

## Proposed Semantic Model

### Star Schema Design

```
                    ┌─────────────┐
                    │  dim_date   │
                    │  (~13K)     │
                    └──────┬──────┘
                           │
    ┌──────────┐    ┌──────▼──────────┐    ┌──────────────┐
    │dim_party │◄───┤fact_transaction │───►│ dim_product  │
    │ (3.7M)   │    │    (85M rows)   │    │   (31K)      │
    └────┬─────┘    └─────────────────┘    └──────────────┘
         │                  │
         │                  ▼
         │          ┌───────────────┐
         │          │ dim_geography │
         │          │    (1K)       │
         │          └───────────────┘
         ▼
┌─────────────────┐         ┌────────────────┐
│bridge_policy_   │────────►│  dim_policy    │
│  party (48.7M)  │         │    (20M)       │
└─────────────────┘         └────────────────┘
```

### Table Inventory (10 tables)

| Table | Rows | Purpose |
|-------|------|---------|
| **fact_transaction** | 85M | Premium, brokerage, fees, claims by transaction |
| **dim_date** | 13K | Australian FY calendar (Jul-Jun) |
| **dim_party** | 3.7M | Clients, carriers, brokers (with GlobalPartyId for cross-sell) |
| **dim_policy** | 20M | Policy master data |
| **dim_product** | 31K | Product hierarchy (16 classes → 73 lines → 330 products) |
| **dim_geography** | 1K | 9-level hierarchy (Region → Office → Location) |
| **dim_financial_segment** | 4K | Business segment hierarchy (CRB/HCB/IRR) |
| **dim_data_source** | 81 | Source system metadata (56 production + 25 test) |
| **dim_industry** | 1K | SIC87 industry classification |
| **bridge_policy_party** | 48.7M | Many-to-many: policies ↔ parties ↔ roles |

**Total Model Size**: ~157M rows (well within F16 capacity of 1.5B)

---

## Cross-Sell Analytics Design

### Business Question
*"Which clients buy Property insurance but NOT Marine insurance?"*

### Query Pattern
```
1. Start with dim_party (filter: GlobalPartyRole = 'Client')
2. → bridge_policy_party (filter: IsPrimaryParty = true)
3. → dim_policy
4. → fact_transaction
5. → dim_product (group by GlobalProductClass)
```

### Example Output

| Client (GlobalPartyId) | Property | Casualty | Marine | Benefits | Cross-Sell Opportunity |
|------------------------|----------|----------|--------|----------|------------------------|
| Global Client A | ✅ $2.5M | ✅ $800K | ❌ | ❌ | Marine, Benefits |
| Global Client B | ✅ $5.1M | ❌ | ❌ | ✅ $3.2M | Casualty, Marine |
| Global Client C | ❌ | ✅ $1.2M | ✅ $600K | ❌ | Property, Benefits |

**Key Enabler**: `GlobalPartyId` links the same client across different data sources (e.g., Epic US + Eclipse + WIBS = one global client).

---

## Financial Metrics Available

### Transaction-Level Measures (15 total)
- **Revenue**: GrossPremium, NetPremium, GrossBrokerage, NetBrokerage, GrossFee, NetFee
- **Income**: MarketDerivedIncome, AdditionalCommission, ContingentCommission
- **Costs**: CostOtherExpense, CostCompanyExpense
- **Shared**: SharedBrokerage, SharedFee
- **Other**: Claim, Deduction

### Coverage by Data Source
- **85.2%** of transactions have product classification
- **95.2%** of transactions have financial details
- **100%** FK integrity (zero orphan records)

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Bronze** | Delta Lake | Raw ingestion from PAS |
| **Silver** | Delta Lake | 18 cleaned source tables |
| **Gold** | Delta Lake | 10-table star schema |
| **Semantic** | Power BI Direct Lake | Real-time reporting (no data copy) |
| **Compute** | Fabric F16 | 300M rows/table, 1.5B total model capacity |

---

## Implementation Timeline

### Phase 1: Gold Layer Build (Complete)
- ✅ Data discovery (471M rows profiled)
- ✅ Star schema design (10 tables specified)
- ✅ Notebook creation (10/10 complete)

### Phase 2: Execution (Next 2 Weeks)
- Build 10 gold tables (~90 min runtime)
- Validate data quality (row counts, FK integrity, financial totals)

### Phase 3: Semantic Model (Week 3-4)
- Create Power BI Direct Lake model
- Build measure library (15 financial metrics)
- Implement role-playing dates (transaction date, inception date, expiry date)

### Phase 4: Reporting (Week 5-6)
- Cross-sell dashboard
- Financial performance reports
- Product mix analysis

**Total Timeline**: 6 weeks to production

---

## Business Value

### Immediate (Phase 3)
- **Cross-sell revenue opportunity identification** — Target clients with product gaps
- **Unified global view** — 56 data sources in one model (vs 56 separate reports today)
- **Real-time reporting** — Direct Lake = no nightly refresh delays

### Medium-Term (Phase 4+)
- **AI-powered insights** — 471M detail rows available for agent queries (carrier-level analysis)
- **Predictive analytics** — 20M policies × 5 years history = trend analysis
- **Data governance** — Single source of truth for PAS data

### Financial Impact (Estimated)
- **3-5% cross-sell revenue uplift** from targeted campaigns
- **50+ hours/month saved** consolidating 56 data source reports into one
- **Zero incremental licensing cost** (Fabric F16 already provisioned)

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| **20M dim_policy too large for Power BI** | F16 supports up to 300M rows/table — 20M is 6.7% of limit. Monitor refresh time. |
| **Complex many-to-many (bridge table)** | Power BI handles bridge tables natively. Well-documented pattern. |
| **Data source coverage gaps** | 95%+ coverage validated. Gaps documented and acceptable. |

**Overall Risk Level**: ✅ Low

---

## Recommendations

1. **Approve gold layer build** — All discovery complete, zero blockers
2. **Allocate F16 capacity** — 90 min runtime for initial build, then incremental refreshes
3. **Prioritize cross-sell use case** — Highest business value, clear ROI
4. **Plan Phase 4 (AI agent)** — 471M detail rows ready for advanced analytics

---

## Appendices

- **Detailed exploration results**: [00_data_exploration_results.md](docs/00_data_exploration_results.md)
- **Star schema plan**: [01_star_schema_plan.md](docs/01_star_schema_plan.md)
- **Validation summary**: [02_validation_summary.md](docs/02_validation_summary.md)
- **Action items**: [ACTION_ITEMS.md](ACTION_ITEMS.md)

---

**Contact**: Prisco Liu
**Workspace**: The_Global_Loom
**Fabric Capacity**: F16
**Next Review**: After Phase 2 execution complete
