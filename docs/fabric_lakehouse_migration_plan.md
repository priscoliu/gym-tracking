# Fabric Lakehouse Migration Plan: CRM & Sales Data

## 1. Executive Summary
The goal of this migration is to transition the current data architecture (which relies heavily on complex SQL views and Power BI Dataflows Gen2/Gen1) to an optimized, Fabric-native Medallion architecture (Bronze/Silver/Gold). 

By using native PySpark notebooks and Delta Lake tables instead of on-the-fly SQL views and Dataflows, we will achieve:
* **Lower compute costs (Fabric CUs)** by processing data once instead of on-the-fly or inside Dataflows.
* **Faster Power BI refresh times** using Direct Lake mode against Gold Delta tables.
* **Standardized logic** adhering to the `fabric-de` engineering guidelines.

---

## 2. Current State vs. Target State

| Feature | Current State | Target State |
| :--- | :--- | :--- |
| **Ingestion (Bronze)** | Data Factory pipelines with heavy T-SQL (`UNION ALL`, formatting) prior to ingestion. | 1:1 raw table extraction from source systems to Bronze Lakehouse Delta tables. |
| **Transformation (Silver)** | `CREATE VIEW` SQL scripts with on-the-fly `UNION` and `NOT EXISTS` logic. | Scheduled PySpark Notebooks performing `left_anti` joins, writing physical Delta tables. |
| **Consumption (Gold)** | Power BI Dataflows (heavy compute, slow refresh). | PySpark generating Star Schema Delta tables; Power BI connects via Direct Lake mode. |

---

## 3. Phased Implementation Plan

### Stage 1: Simplify Bronze Layer (Ingestion)
**Goal:** Remove transformation logic from ingestion pipelines. Bronze should be an exact, raw replica of the source data.
* **Tasks:**
  1. Review `01_bronze_pipeline_crm.json`.
  2. Strip out all custom T-SQL (like the `AllAccountTags` query containing `UNION ALL`).
  3. Ensure the pipeline extracts raw tables (e.g., `account`, `rs_account_rs_tagslist`, `rs_tagslist`, `opportunity`, `systemuser`) using simple `SELECT *` or native copy directly into `APAC_CRM_Analytics_LH` as Delta tables.
  4. Ensure `Legacy CIS` data is included in the raw ingestion.

### Stage 2: Build Silver Layer (Transformation)
**Goal:** Convert all SQL Views (`.sql`) into standardized PySpark notebooks (`.ipynb`), writing cleansed data to physical Delta tables.
* **Tasks:**
  1. Convert `02_silver_clean_crm_account.sql` to `02_silver_notebook_crm_account.ipynb`. 
     * Replace non-deterministic `ROW_NUMBER()` with stable hashes (e.g., `hash(GCID + AccountName)`).
     * Replace `NOT EXISTS` SQL clauses with PySpark `left_anti` joins.
  2. Convert `02_silver_clean_crm_opportunity_unified.sql` and `02_silver_clean_crm_opportunity.sql` into a single, cohesive PySpark notebook.
  3. Convert Product, Profit Center, and User SQL scripts to reference notebooks.
  4. Enforce the `STANDARD_COLUMNS` format and write as physical tables (e.g., `clean_crm_account`) in `APAC_Reporting_LH`.

### Stage 3: Build Gold Layer (Star Schema)
**Goal:** Move the logic currently locked inside Power BI Dataflows into PySpark notebooks to create the final Star Schema.
* **Tasks:**
  1. Analyze the logic inside existing Dataflows (`Account_Goals_GoalsActivity`, `Activity`, `ANZ_Leads`, `APAC Leads_`, `Opportunity`).
  2. Create Gold PySpark notebooks (e.g., `03_gold_fact_opportunity.ipynb`, `03_gold_dim_account.ipynb`) that read the Silver tables and output final Fact and Dimension Delta tables.
  3. Pre-aggregate or group data in PySpark if specifically required by the Semantic Models.

### Stage 4: Power BI & Dataflow Retirement (Direct Lake)
**Goal:** Connect Power BI and remove legacy Dataflow dependencies.
* **Tasks:**
  1. Update Power BI Semantic Models to connect directly to the Gold Delta tables in the Lakehouse via **Direct Lake**.
  2. Validate data parity between the new models and the old Dataflow models.
  3. Delete the legacy Dataflows to free up workspace clutter and Fabric capacity.

---

## 4. Next Steps
We will begin with **Stage 1: Simplify Bronze Layer**. 
