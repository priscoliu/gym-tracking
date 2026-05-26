let
    // Connect to Fabric Lakehouse
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "1c0d3357-c170-4ddd-9738-e1c90bbe99f2"]}[Data],
    Raw = #"Navigation 1"{[Id = "src_gswin_crb", ItemKind = "Table"]}[Data],

    // Step 1: Filter and Select Base Columns
    // Note: "New/ #(lf)Renew" — the column header in Excel contains a literal line-feed; pandas preserves it
    #"Base Columns" = Table.SelectColumns(
        Table.SelectRows(Raw,
            each [#"Willis Line"] <> "H&B"
        ),
        {"ClientID", "Client Name", "Policy Number", "Policy Type Name", "Renewable",
         "New/ #(lf)Renew", "Inception Date", "Cury Code", "Premium USD",
         "Total Brokerage in USD", "Willis Line", "GCID"}
    ),

    // Step 2: Add Derived Columns
    #"Derived Columns" =
        let
            t1 = Table.AddColumn(#"Base Columns", "DataSource", each "GSWin", type text),
            t2 = Table.AddColumn(t1, "SystemID_New", each [DataSource] & "-" & [ClientID], type text),
            t3 = Table.AddColumn(t2, "RecurringRevenue", each
                    if [Renewable] = "R" then "Y"
                    else if [Renewable] = "N" then "N"
                    else "N", type text),
            t4 = Table.AddColumn(t3, "BusinessType", each
                    if [#"New/ #(lf)Renew"] = "N" then "New Business"
                    else if [#"New/ #(lf)Renew"] = "R" then "Renewal"
                    else [#"New/ #(lf)Renew"], type text),
            t5 = Table.AddColumn(t4, "RevenueCountry", each "Vietnam", type text),
            t6 = Table.AddColumn(t5, "RevenueCities", each "", type text),
            t7 = Table.AddColumn(t6, "ClientID_Temp", each if [GCID] = null then [SystemID_New] else [GCID], type text),
            t8 = Table.AddColumn(t7, "Source", each [DataSource], type text),
            t9 = Table.AddColumn(t8, "Currency", each "USD", type text)
        in t9,

    // Step 3: Rename, Type, and Reorder
    #"Final Schema" =
        let
            renamed = Table.RenameColumns(#"Derived Columns", {
                {"Client Name",             "SystemClientName"},
                {"Policy Type Name",        "SystemProductClass"},
                {"Policy Number",           "TX_ID"},
                {"Inception Date",          "IncomeDate/InceptionDate"},
                {"Total Brokerage in USD",  "Revenue"},
                {"Premium USD",             "Premium"},
                {"Willis Line",             "Segment"},
                {"SystemID_New",            "SystemID"}
            }),
            removedOldClientID = Table.RemoveColumns(renamed, {"ClientID"}),
            renamedClientID    = Table.RenameColumns(removedOldClientID, {{"ClientID_Temp", "ClientID"}}),
            addedDUNSNO        = Table.AddColumn(renamedClientID, "DUNSNO", each "", type text),
            typedNumbers = Table.TransformColumns(addedDUNSNO, {
                {"Premium", each try Number.From(_) otherwise 0, type number},
                {"Revenue", each try Number.From(_) otherwise 0, type number}
            }),
            typedDate = Table.TransformColumns(typedNumbers, {
                {"IncomeDate/InceptionDate", each try Date.From(_) otherwise null, type date}
            }),
            typedText = Table.TransformColumnTypes(typedDate, {
                {"TX_ID",    type text},
                {"SystemID", type text},
                {"GCID",     type text},
                {"ClientID", type text}
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
