import json

path = r'c:/Users/LiuPr/OneDrive - Willis Towers Watson/Documents/WTW-Data-Solutions/fabric-workspace/Fabric-Bronze/Billing/01_bronze_notebook_crb_billings.ipynb'
with open(path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

for i, cell in enumerate(nb['cells']):
    src = ''.join(cell['source']) if isinstance(cell['source'], list) else cell['source']
    if 'Cell 12: CIS Historical' in src:
        cell['source'] = [
            '# =============================================================================\n',
            '# Cell 12: CIS Historical Data (raw)\n',
            '# Folder : billing/cis_historical/\n',
            '#          NOTE: pipeline source folder is "Historical CIS Data (Before 2023)",\n',
            '#          NOT "CRM CIS Historical Data" -- update pipeline if 404 persists.\n',
            '# File   : CIS Historical Data (WR+EX+ICT+INV) before 2023.xlsx\n',
            '# Sheet  : Sheet1  |  Header: row 1\n',
            '# Output : src_billing_cis_historical\n',
            '#\n',
            '# Pure ingestion. The following move to dbt downstream:\n',
            '#   - stg_billing__cis_historical : column renames + type casts\n',
            '#   - int_billing__cis_historical_enriched : <2023-01-01 filter, Source="CIS" hardcode,\n',
            '#     conform to baseline 18+ col schema for the unified mart\n',
            '#\n',
            '# Tolerant of a missing folder: if the CIS copy pipeline activity has not yet\n',
            '# succeeded, this cell logs a warning and skips rather than failing the whole run.\n',
            '# =============================================================================\n',
            'folder = f"{FILES_BASE}cis_historical/"\n',
            '\n',
            'if not os.path.isdir(folder):\n',
            '    print(f"WARNING: {folder} does not exist -- CIS pipeline activity likely still failing (check 404).")\n',
            '    print("Skipping CIS Historical -- rerun this cell after the pipeline succeeds.")\n',
            'else:\n',
            '    dfs = []\n',
            '    for fname in sorted(os.listdir(folder)):\n',
            '        if fname.endswith(".xlsx") and not fname.startswith("~$"):\n',
            '            fpath = os.path.join(folder, fname)\n',
            '            df_tmp = pd.read_excel(fpath, sheet_name="Sheet1", header=0, dtype=str)\n',
            '            df_tmp["Source_Name"] = fname\n',
            '            df_tmp = normalize_cols(df_tmp)\n',
            '            print(f"Loaded {fname}: {len(df_tmp)} rows, {len(df_tmp.columns)} cols")\n',
            '            dfs.append(df_tmp)\n',
            '\n',
            '    if not dfs:\n',
            '        print(f"WARNING: {folder} exists but contains no xlsx files -- skipping.")\n',
            '    else:\n',
            '        df_pandas = pd.concat(dfs, ignore_index=True)\n',
            '        print(f"Total rows: {len(df_pandas)} | Cols: {len(df_pandas.columns)}")\n',
            '        print(list(df_pandas.columns))\n',
            '\n',
            '        df_cis_historical = spark.createDataFrame(df_pandas)\n',
            '        df_cis_historical.printSchema()\n',
            '        display(df_cis_historical.limit(3))\n',
            '\n',
            '        write_table(df_cis_historical, "src_billing_cis_historical")',
        ]
        print(f'Made Cell 12 tolerant of missing folder (index {i})')
        break

with open(path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, ensure_ascii=False, indent=1)

print('Done.')
