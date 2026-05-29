let
    // Connect to Fabric Lakehouse
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "1c0d3357-c170-4ddd-9738-e1c90bbe99f2"]}[Data],
    Raw = #"Navigation 1"{[Id = "src_arias_crb", ItemKind = "Table"]}[Data],

    // Step 1: Filter, Select Base Columns, and safely cast date columns (try/otherwise prevents
    // whole-table failure when an individual row is blank or unparseable).
    #"Base Columns" = Table.TransformColumns(
        Table.SelectColumns(
            Table.SelectRows(Raw,
                each not ([チーム名] = "HB")
            ),
            {"保険種類", "契約者名", "保険始期", "請求書番号", "Recurring", "保険料", "手数料（税抜)", "GCID", "Policy No"}
        ),
        {{"保険始期", each try Date.From(_) otherwise null, type date}}
    ),

    // Step 2: Add Derived Columns
    #"Derived Columns" =
        let
            t1  = Table.AddColumn(#"Base Columns", "DataSource", each "ARIAS", type text),
            t2  = Table.AddColumn(t1,  "SystemID_New", each [DataSource] & "-" & Text.From([#"Policy No"]), type text),
            t3  = Table.AddColumn(t2,  "BusinessType", each
                    if [Recurring] = "N" then "New Business"
                    else if [Recurring] = "R" then "Renewal"
                    else [Recurring], type text),
            t4  = Table.AddColumn(t3,  "RecurringRevenue_New", each
                    if [Recurring] = "R" then "Y"
                    else if [Recurring] = "N" then "N"
                    else [Recurring], type text),
            t5  = Table.AddColumn(t4,  "RevenueCountry", each "Japan",  type text),
            t6  = Table.AddColumn(t5,  "RevenueCities",  each "",       type text),
            t7  = Table.AddColumn(t6,  "Segment",        each "CRB",    type text),
            t8  = Table.AddColumn(t7,  "TX_ID_New", each
                    if [請求書番号] = null or [請求書番号] = "" then ""
                    else [DataSource] & "-" & Text.From([請求書番号]),
                    type text),
            t9  = Table.AddColumn(t8,  "Currency", each "JPY",        type text),
            t10 = Table.AddColumn(t9,  "Source",   each [DataSource], type text),
            t11 = Table.AddColumn(t10, "ClientID_Temp", each
                    if [GCID] = null or [GCID] = "" then [SystemID_New]
                    else Text.From([GCID]),
                    type text),
            // 保険始期 already type date in Lakehouse
            t12 = Table.AddColumn(t11, "DateTime_Out", each
                    try Date.From([保険始期]) otherwise null,
                    type date)
        in t12,

    // Step 3: Rename, Type, and Reorder
    #"Final Schema" =
        let
            renamed = Table.RenameColumns(#"Derived Columns", {
                {"保険種類",      "SystemProductClass"},
                {"契約者名",      "SystemClientName"},
                {"請求書番号",    "TX_ID_Original"},
                {"保険料",        "Premium"},
                {"手数料（税抜)", "Revenue"},
                {"SystemID_New",  "SystemID"},
                {"TX_ID_New",     "TX_ID"},
                {"RecurringRevenue_New", "RecurringRevenue"},
                {"DateTime_Out",  "IncomeDate/InceptionDate"}
            }),
            cleaned = Table.RemoveColumns(renamed, {"TX_ID_Original", "保険始期", "Recurring", "Policy No", "ClientID_Temp"}),
            addedClientID = Table.AddColumn(cleaned, "ClientID", each
                    if [GCID] = null or [GCID] = "" then [SystemID]
                    else Text.From([GCID]),
                    type text),
            addedDUNSNO = Table.AddColumn(addedClientID, "DUNSNO", each "", type text),
            typedNumbers = Table.TransformColumns(addedDUNSNO, {
                {"Premium", each try Number.From(_) otherwise 0, type number},
                {"Revenue", each try Number.From(_) otherwise 0, type number}
            }),
            typedText = Table.TransformColumnTypes(typedNumbers, {
                {"SystemProductClass", type text},
                {"SystemClientName",   type text},
                {"TX_ID",              type text},
                {"SystemID",           type text},
                {"RevenueCountry",     type text},
                {"ClientID",           type text},
                {"DataSource",         type text},
                {"Segment",            type text},
                {"BusinessType",       type text},
                {"RecurringRevenue",   type text},
                {"RevenueCities",      type text},
                {"DUNSNO",             type text},
                {"Currency",           type text},
                {"GCID",               type text},
                {"Source",             type text}
            }),
            reordered = Table.SelectColumns(typedText, {
                "SystemClientName",
                "SystemProductClass",
                "TX_ID",
                "IncomeDate/InceptionDate",
                "Revenue",
                "Premium",
                "SystemID",
                "RevenueCountry",
                "ClientID",
                "DataSource",
                "Segment",
                "BusinessType",
                "RecurringRevenue",
                "RevenueCities",
                "DUNSNO",
                "Currency",
                "GCID",
                "Source"
            })
        in reordered

in
    #"Final Schema"
