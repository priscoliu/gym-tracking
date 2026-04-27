# Cross-Sell Intelligence Dashboard — Summary Page Design
**Stage 3 · Summary Page Spec**
R&B SalesOps · Global · April 2026

---

## Purpose

Single-page view that answers one question for a global CRB leader in 30 seconds:

> "Are we growing our share of wallet, and where is the biggest opportunity?"

Everything on the page pivots from penetration. The page is shared by two audiences — executives read the top third, analysts interact with the rest.

---

## Audience & Decision Context

| Audience | Goal | Time on page |
|---|---|---|
| Global CRB leader / executive | Confirm portfolio health, spot trajectory | 30 seconds |
| Sales analyst / ops | Identify which geographies and products need focus | 3–5 minutes |

---

## Canvas

- **Size**: 1440 × 1080 px (Operational mode)
- **Grid**: 12-column, 60px side margins
- **Filter scope**: Geography slicer cross-filters **all** visuals on the page

---

## Layout — Three Zones

### Zone 1 — Executive strip (top ~360px)

Four KPI tiles in a horizontal strip:

| Tile | Measure | Sub-label |
|---|---|---|
| **Multi-LOB %** (hero) | `Multi LOB %` | YoY delta: `Multi-LOB % YoY` (e.g. ▲ 2.3pp vs last year) |
| Total Clients | `Global Client Count` (DISTINCTCOUNT GlobalPartyId) | — |
| Single-LOB Revenue % | `Single LOB Revenue %` | Revenue at risk framing |
| Avg LOBs / Client | derived from `LOB Count` / `Global Client Count` | — |

Hero tile is visually larger (purple accent, 28px value). Supporting three tiles are uniform.

---

### Zone 2 — Analyst core (middle ~480px)

Two-column layout:

**Left (~60% width) — LOB Distribution**
- Visual type: Clustered bar or horizontal bar chart
- X-axis: LOB bucket (1 / 2 / 3 / 4+)
- Y-axis: Client count
- Secondary: % label per bar
- Purpose: explains the penetration rate — shows the shape of the problem, not the hero itself

**Right (~40% width) — Geography + Revenue at Risk**
- Geography parameter slicer — three levels: Financial Geography → Region → Country (from `gold_salesops_dim_financialgeography`)
- Single-LOB revenue at risk callout: total revenue held by 1-LOB clients, formatted as dollar value + % of total revenue
- These two sit stacked vertically in the right column

---

### Zone 3 — Heatmap (bottom ~240px)

- Visual type: Native Power BI Matrix (not HTML card — avoids 1M row Direct Lake limit)
- Rows: **Industry** (`gold_salesops_dim_client[IndustryName]`) — answers "which industries are under-penetrated in which products?"
- Columns: `gold_salesops_dim_product[GlobalProductClass]` (13 classes)
- Values: `Global Client Count` with conditional formatting — color scale `#F3EBF9` → `#7F35B2`
- Role: directional overview only. Co-occurrence detail and client lookup live on the dedicated Cross-Sell page.

---

## Geography Parameter

Three-level hierarchy from `gold_salesops_dim_financialgeography`:

1. Financial Geography (finest grain)
2. Region (e.g. APAC, EMEA, Americas)
3. Country

Implemented as a **Field Parameter** slicer. Selecting any level cross-filters all three zones.

---

## Measures Required

### New measures needed

| Measure | Logic | Display folder |
|---|---|---|
| `Multi-LOB % YoY` | `Multi LOB %` vs same measure in prior year via `DATEADD` | 6. Time Intelligence |
| `Single LOB Revenue %` | Revenue of single-LOB clients / Total Revenue | 2. Revenue |
| `Avg LOBs Per Client` | `LOB Count` / `Global Client Count` | 3. LOB Penetration |
| `Single LOB Revenue` | `Total Revenue` filtered to clients with LOB count = 1 | 2. Revenue |

### Existing measures used

- `Global Client Count`
- `Multi LOB %`
- `Total Revenue`
- `Clients with 1 LOB` (bucket measure, for LOB distribution chart)
- `Clients with 2 LOBs`, `Clients with 3 LOBs`, `Clients with 4+ LOBs`

---

## Open Questions

- Single-LOB revenue: should it include clients who had 1 LOB lifetime, or 1 LOB in the current filter period only?
- Geography slicer default: show all (global) or default to user's region?

## Resolved

- All time intelligence (YoY delta) uses `dim_date` table — `InceptionDate` as the date key.
- Geography slicer scope: three levels (Financial Geography / Region / Country) all cross-filter everything.

---

## Dedicated Cross-Sell Page (separate spec)

The following are explicitly out of scope for the summary page and belong on a dedicated page:

- **Co-occurrence matrix** — Product Class × Product Class, value = % of clients holding both
- **Client lookup panel** — select a client → see held products highlighted in co-occurrence matrix → whitespace ranked by co-occurrence score
- This page is the analyst decision tool; the summary page is the executive health check.

---

## Out of Scope (this page)

- Client-level lookup — dedicated panel, separate page or drill-through
- Heatmap detail (co-occurrence scores, whitespace recommendations) — dedicated heatmap page
- Trend line / time series — future Stage 4

---

## Next Steps

1. Build 4 new DAX measures (see table above)
2. Create LOB Buckets helper table (4 rows, Import)
3. Build summary page canvas at 1440×1080
4. Wire geography field parameter
5. Apply WTW conditional formatting to matrix (Corporate palette)