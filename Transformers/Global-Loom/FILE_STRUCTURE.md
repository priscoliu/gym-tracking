# Global Loom — File Structure

**Last Updated**: 2026-03-16
**Total Files**: 50+ organized into logical folders

---

## 📂 Root Level (Quick Access)

```
Global-Loom/
├── README.md                      ← Start here (project overview)
├── INDEX.md                       ← File navigation guide
├── EXECUTIVE_SUMMARY.md           ← For stakeholders/boss
├── ACTION_ITEMS.md                ← What needs to be done next
└── FILE_STRUCTURE.md              ← This file
```

**What to read first**:
1. **Stakeholder presenting?** → [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)
2. **Implementing next steps?** → [ACTION_ITEMS.md](ACTION_ITEMS.md)
3. **Understanding the project?** → [README.md](README.md)
4. **Finding a specific file?** → [INDEX.md](INDEX.md)

---

## 📚 Documentation Folder (`docs/`)

```
docs/
├── 00_data_exploration_results.md    ← Phase 0: 471M rows profiled
├── 01_star_schema_plan.md            ← Phase 1: Star schema design
└── 02_validation_summary.md          ← Validation report (all questions resolved)
```

**Read in order**: 00 → 01 → 02

**Page count**: ~45 pages total (15 + 18 + 12)

**Purpose**: Complete technical documentation of discovery, design, and validation.

---

## 🔍 Exploration Folder (`exploration/`)

```
exploration/
├── 00_explore_pas_silver.ipynb        ← Initial profiling (18 tables)
├── 00_explore_deep_dive.ipynb         ← Deep dive queries (23 total)
└── deep_dive_results/                 ← 23 JSON query results
    ├── Q1a_policy_uniqueness.json
    ├── Q1b_policy_by_datasource.json
    ├── Q1c_policy_duplicates.json
    ├── Q2a_invoice_fk_integrity.json
    ├── Q2b_transaction_invoice_coverage.json
    ├── Q2c_invoices_per_transaction.json
    ├── Q2d_invoice_product_coverage.json
    ├── Q2e_invoice_dimension_coverage.json
    ├── Q3a_transaction_counts.json
    ├── Q3b_detail_orphans.json
    ├── Q3c_headers_without_details.json
    ├── Q3d_detail_distribution.json
    ├── Q3d_details_per_transaction.json
    ├── Q4a_product_counts.json
    ├── Q4b_product_hierarchy.json
    ├── Q4c_product_coverage.json
    ├── Q4d_product_fk_integrity.json
    ├── Q5a_invoice_summary.json
    ├── Q5b_invoice_document_types.json
    ├── Q5c_invoice_party_roles.json
    ├── Q5d_invoice_financials.json
    ├── Q5e_invoice_date_range.json
    └── Q5f_invoice_cfparty_join.json
```

**Purpose**: Phase 0 data discovery work. JSON files contain query results referenced in [docs/00_data_exploration_results.md](docs/00_data_exploration_results.md).

**JSON Naming Convention**: `Q[#][letter]_[description].json`
- Q1 = Policy analysis
- Q2 = Invoice chain
- Q3 = Transaction → Detail chain
- Q4 = Product analysis
- Q5 = CFInvoice feasibility

---

## 📓 Notebooks Folder (`notebooks/`)

### Dimensions (`notebooks/dimensions/`)

```
notebooks/dimensions/
├── 03_gold_dim_date.ipynb                    ✅ Ready (~13K rows)
├── 03_gold_dim_data_source.ipynb             ✅ Ready (81 rows)
├── 03_gold_dim_financial_segment.ipynb       ✅ Ready (4K rows)
├── 03_gold_dim_geography.ipynb               ✅ Ready (1K rows)
├── 03_gold_dim_product.ipynb                 ✅ Ready (31K rows)
├── 03_gold_dim_party.ipynb                   ⚠️  NEEDS MODIFICATION (3.7M rows)
├── 03_gold_dim_policy.ipynb                  ✅ Ready (20M rows)
└── 03_gold_dim_carrier.ipynb                 🔴 DELETE (merged into dim_party)
```

**Missing**: `03_gold_dim_industry.ipynb` (1K rows) — needs to be created

**Status**: 7/8 ready, 1 needs modification, 1 to delete, 1 to create

### Facts (`notebooks/facts/`)

```
notebooks/facts/
├── 03_gold_fact_transaction.ipynb      ✅ Ready (85M rows, ~30 min runtime)
└── 03_gold_fact_invoice.ipynb          ❌ Deferred (9.7M rows, only 3/56 DSIs)
```

**Status**: 1/2 ready, 1 deferred to Phase 2

### Bridge (`notebooks/bridge/`)

```
notebooks/bridge/
└── 03_gold_bridge_policy_party.ipynb   ✅ Ready (48.7M rows)
```

**Status**: 1/1 ready

---

## 📊 Summary Statistics

### Files by Type

| Type | Count | Location |
|------|-------|----------|
| **Markdown docs** | 8 | Root (4) + docs/ (3) + this file |
| **Exploration notebooks** | 2 | exploration/ |
| **Dimension notebooks** | 8 | notebooks/dimensions/ (7 ready, 1 to modify, 1 to delete) |
| **Fact notebooks** | 2 | notebooks/facts/ (1 ready, 1 deferred) |
| **Bridge notebooks** | 1 | notebooks/bridge/ |
| **JSON query results** | 23 | exploration/deep_dive_results/ |
| **Total files** | 44 | Across all folders |

### Notebooks by Status

| Status | Count | Notes |
|--------|-------|-------|
| ✅ Ready | 9 | Can execute immediately |
| ⚠️ Needs modification | 1 | dim_party (add carrier hierarchy) |
| 🔴 Delete | 1 | dim_carrier (merged into party) |
| 🔴 Missing | 1 | dim_industry (needs creation) |
| ❌ Deferred | 1 | fact_invoice (Phase 2) |

---

## 🎯 File Organization Principles

### 1. **Separation by Phase**
- **exploration/** = Phase 0 (data discovery)
- **notebooks/** = Phase 2+ (gold layer build)
- **docs/** = Documentation (all phases)

### 2. **Descriptive JSON Names**
- ❌ Before: `untitled (1).json`, `untitled (2).json`
- ✅ After: `Q1a_policy_uniqueness.json`, `Q1b_policy_by_datasource.json`

### 3. **Logical Notebook Grouping**
- Dimensions together (most are independent, can run in parallel)
- Facts separate (depend on dimensions)
- Bridge separate (depends on dimensions)

### 4. **Quick Access at Root**
- Executive summary for stakeholders
- Action items for implementers
- README for project overview
- INDEX for navigation

---

## 🔎 Finding Files Quickly

### By Purpose

| I need to... | Go to... |
|--------------|----------|
| **Present to my boss** | [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md) |
| **Know what to do next** | [ACTION_ITEMS.md](ACTION_ITEMS.md) |
| **Understand the project** | [README.md](README.md) |
| **Find a specific file** | [INDEX.md](INDEX.md) |
| **See data profiling** | [docs/00_data_exploration_results.md](docs/00_data_exploration_results.md) |
| **Understand star schema** | [docs/01_star_schema_plan.md](docs/01_star_schema_plan.md) |
| **Review validation** | [docs/02_validation_summary.md](docs/02_validation_summary.md) |
| **Check query results** | [exploration/deep_dive_results/](exploration/deep_dive_results/) |
| **Modify a dimension** | [notebooks/dimensions/](notebooks/dimensions/) |
| **Build the fact table** | [notebooks/facts/03_gold_fact_transaction.ipynb](notebooks/facts/03_gold_fact_transaction.ipynb) |

### By Question

| Question | File |
|----------|------|
| "Why 20M policies?" | [exploration/deep_dive_results/Q1a_policy_uniqueness.json](exploration/deep_dive_results/Q1a_policy_uniqueness.json) |
| "Which DSIs feed CFInvoice?" | [exploration/deep_dive_results/Q5a_invoice_summary.json](exploration/deep_dive_results/Q5a_invoice_summary.json) |
| "Are there orphan detail rows?" | [exploration/deep_dive_results/Q3b_detail_orphans.json](exploration/deep_dive_results/Q3b_detail_orphans.json) |
| "Product coverage on transactions?" | [exploration/deep_dive_results/Q4c_product_coverage.json](exploration/deep_dive_results/Q4c_product_coverage.json) |
| "How many details per transaction?" | [exploration/deep_dive_results/Q3d_detail_distribution.json](exploration/deep_dive_results/Q3d_detail_distribution.json) |

---

## 📋 Execution Checklist

Before running notebooks in Fabric:

- [ ] Read [ACTION_ITEMS.md](ACTION_ITEMS.md)
- [ ] Investigate SIC code linkage (SQL queries provided)
- [ ] Create [notebooks/dimensions/03_gold_dim_industry.ipynb](notebooks/dimensions/) (if linkage found)
- [ ] Modify [notebooks/dimensions/03_gold_dim_party.ipynb](notebooks/dimensions/03_gold_dim_party.ipynb) (add carrier hierarchy)
- [ ] Delete [notebooks/dimensions/03_gold_dim_carrier.ipynb](notebooks/dimensions/03_gold_dim_carrier.ipynb)
- [ ] Update [README.md](README.md) (if needed)

**Then**: Execute notebooks in dependency order (see [README.md](README.md) Execution Plan)

---

## 🗂️ Empty Folders (Intentional)

```
exploration/results/        ← Empty (reserved for future profiling outputs)
```

This folder exists for consistency but is currently unused. Query results are in `exploration/deep_dive_results/` instead.

---

## 💾 Backup Recommendation

**Before making changes**, backup these critical files:

```bash
# Key notebooks (in case modifications go wrong)
notebooks/dimensions/03_gold_dim_party.ipynb
notebooks/facts/03_gold_fact_transaction.ipynb

# Documentation (in case rewrites are needed)
docs/00_data_exploration_results.md
docs/01_star_schema_plan.md
docs/02_validation_summary.md
```

**Backup location**: Consider Git commit or OneDrive version history.

---

## 📞 Questions?

- **Owner**: Prisco Liu
- **Workspace**: The_Global_Loom
- **Fabric SKU**: F16
- **Last Organized**: 2026-03-16

**Next review**: After Phase 2 execution complete
