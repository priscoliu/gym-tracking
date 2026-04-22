---
name: fabric-de
description: Workflow for building and validating Fabric Data Engineering PySpark notebooks, from Bronze to Silver to Gold.
---

# Fabric Data Engineering Workflow

This workflow outlines the standard process for building and executing Microsoft Fabric Data Engineering tasks using PySpark, incorporating our standardized WTW-Data-Solutions standards.

## Step 1: Planning and Setup
- Determine the source Bronze tables and the target Lakehouse.
- Identify any required Reference lookup tables.
- Set up the notebook with standard imports and configure cross-workspace target variables if needed.
- **CRITICAL**: Ensure the notebook format is `.ipynb` and the JSON `source` field uses an array of strings. No emojis allowed except in Power BI outputs!

## Step 2: Load and Profile Bronze Data
- Load the raw Bronze data into a PySpark DataFrame.
- Profile the data using `printSchema()`, `display(df.limit(3))`, and `df.count()` to ensure it loaded correctly.

## Step 3: Transformations
- Perform data type casting first (e.g. `F.coalesce` and `.cast()`).
- Handle special character column names using backticks (`` `COL NAME` ``).
- Standardize column names before applying any unions.

## Step 4: Reference Joins
- Prepare the reference table by standardizing the join key (`TRIM` + `UPPER`).
- Join the main DataFrame with the reference table using `TRIM` and `UPPER` on both sides.
- Drop the temporary join key from the resulting DataFrame.

## Step 5: Final Select and Write
- Apply the `STANDARD_COLUMNS` selection for the target layer. Ensure casting happens BEFORE aliasing in the final select.
- Write the DataFrame to the target Lakehouse using Delta format (`mode("overwrite")`, `option("overwriteSchema", "true")`).
- If writing cross-workspace, use the constructed `abfss://` `TARGET_PATH`.
- Verify the write operation by reading the target table back and asserting row count and schema correctness.
