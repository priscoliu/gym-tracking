let
    // Connect to Fabric Lakehouse
    Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
    Navigation_1 = Pattern{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Navigation_2 = Navigation_1{[lakehouseId = "1c0d3357-c170-4ddd-9738-e1c90bbe99f2"]}[Data],
    Raw = Navigation_2{[Id = "src_Saiba_crb", ItemKind = "Table"]}[Data],

    // Step 1: Filter and Select Base Columns
    // Fabric normalizes column names: spaces become underscores
    #"Base Columns" = Table.SelectColumns(
        Table.SelectRows(Raw,
            each [Department] <> "EB" and [Department] <> "HB" and [Department] <> "H&B"
        ),
        {"CNo", "InstNo", "CustName", "CustCode", "GCID", "Policy Type", "BizType", "StartDate", "Brok Prem_", "Brokerage"}
    ),

    // Step 2: Add Derived Columns
    #"Derived Columns" =
        let
            t1  = Table.AddColumn(#"Base Columns", "DataSource", each "Saiba", type text),
            t2  = Table.AddColumn(t1, "SystemID_New", each
                    if [CustCode] = null or [CustCode] = "" then ""
                    else [DataSource] & "-" & [CustCode],
                    type text),
            t3  = Table.AddColumn(t2, "ClientID", each
                    let gcidValue = Text.Trim(Text.From([GCID] ?? ""))
                    in  if gcidValue = "" or gcidValue = "-" then [SystemID_New] else [GCID],
                    type text),
            t4  = Table.AddColumn(t3,  "RecurringRevenue", each "",       type text),
            t5  = Table.AddColumn(t4,  "RevenueCountry",   each "India",  type text),
            t6  = Table.AddColumn(t5,  "RevenueCities",    each "",       type text),
            t7  = Table.AddColumn(t6,  "Segment",          each "CRB",    type text),
            t8  = Table.AddColumn(t7,  "TX_ID_New", each
                    if [CNo] = null or [CNo] = "" then ""
                    else [CNo] & (if [InstNo] = null or [InstNo] = "" then "" else [InstNo]),
                    type text),
            t9  = Table.AddColumn(t8,  "BusinessType", each
                    if [BizType] = "Expanded" then "New Business"
                    else if [BizType] = "New" then "New Business"
                    else [BizType],
                    type text),
            t10 = Table.AddColumn(t9,  "Currency", each "INR",        type text),
            t11 = Table.AddColumn(t10, "Source",   each [DataSource], type text)
        in t11,

    // Step 3: Rename, Type, and Reorder
    #"Final Schema" =
        let
            renamed = Table.RenameColumns(#"Derived Columns", {
                {"CustName",    "SystemClientName"},
                {"Policy Type", "SystemProductClass"},
                {"StartDate",   "IncomeDate/InceptionDate"},
                {"Brok Prem_",  "Premium"},
                {"Brokerage",   "Revenue"},
                {"SystemID_New","SystemID"},
                {"TX_ID_New",   "TX_ID"}
            }),
            addedDUNSNO = Table.AddColumn(renamed, "DUNSNO", each "", type text),
            typedDate = Table.TransformColumns(addedDUNSNO, {
                {"IncomeDate/InceptionDate", each try Date.From(_) otherwise null, type date}
            }),
            typedText = Table.TransformColumnTypes(typedDate, {
                {"TX_ID",    type text},
                {"SystemID", type text},
                {"GCID",     type text}
            }),
            typedNumbers = Table.TransformColumns(typedText, {
                {"Premium", each try Number.From(_) otherwise 0, type number},
                {"Revenue", each try Number.From(_) otherwise 0, type number}
            }),
            reordered = Table.SelectColumns(typedNumbers, {
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