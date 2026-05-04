let
    // Connect to Fabric Lakehouse
    Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
    Navigation_1 = Pattern{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Navigation_2 = Navigation_1{[lakehouseId = "1c0d3357-c170-4ddd-9738-e1c90bbe99f2"]}[Data],
    Raw = Navigation_2{[Id = "src_wr_spm", ItemKind = "Table"]}[Data],

    // OracleID Mapping join — adds GCID from lookup table in Power BI model
    #"Merged queries" = Table.NestedJoin(Raw, {"Bill To Customer Number"}, #"OracleID Mapping", {"OracleID"}, "OracleID Mapping", JoinKind.LeftOuter),
    #"With GCID" = Table.ExpandTableColumn(#"Merged queries", "OracleID Mapping", {"GCID"}, {"GCID"}),

    // Step 1: Filter and Select Base Columns
    #"Base Columns" = Table.SelectColumns(
        Table.SelectRows(#"With GCID",
            each [#"Operating Unit"] = "TW OU HK 3022-Hong Kong" or
                 [#"Operating Unit"] = "TW OU TW 3121-Delaware Taiwan" or
                 [#"Operating Unit"] = "TW OU CN 3241-Shanghai" or
                 [#"Operating Unit"] = "TW OU PH 3101-Philippines" or
                 [#"Operating Unit"] = "TW OU CN 3243-Beijing Br" or
                 [#"Operating Unit"] = "TW OU SG 3042- Willis Towers Watson Consulting (Singapore) Pte Ltd" or
                 [#"Operating Unit"] = "TW OU MY 3081-Malaysia" or
                 [#"Operating Unit"] = "TW OU ID 3162-Indonesia" or
                 [#"Operating Unit"] = "TW OU CN 3248-TW Mgmt Cons Shenzhen" or
                 [#"Operating Unit"] = "TW OU TH 3221-Thailand" or
                 [#"Operating Unit"] = "TW OU JP 3062-KK" or
                 [#"Operating Unit"] = "TW OU KR 3183-Willis Towers Watson Consulting Korea Limited" or
                 [#"Operating Unit"] = "TW OU IN 3002-India Pvt" or
                 [#"Operating Unit"] = "TW OU AU 3141-Australia"
        ),
        {"Reference", "Operating Unit", "Bill To Customer", "Invoice Amount",
         "Currency", "Date", "Bill To Customer Number", "GCID"}
    ),

    // Step 2: Add Derived Columns
    #"Derived Columns" =
        let
            t1  = Table.AddColumn(#"Base Columns", "DataSource", each "SPM", type text),
            t2  = Table.AddColumn(t1, "RevenueCountry", each
                    if [#"Operating Unit"] = "TW OU HK 3022-Hong Kong" then "Hong Kong"
                    else if [#"Operating Unit"] = "TW OU TW 3121-Delaware Taiwan" then "Taiwan"
                    else if [#"Operating Unit"] = "TW OU CN 3241-Shanghai" then "China"
                    else if [#"Operating Unit"] = "TW OU PH 3101-Philippines" then "Philippines"
                    else if [#"Operating Unit"] = "TW OU CN 3243-Beijing Br" then "China"
                    else if [#"Operating Unit"] = "TW OU SG 3042- Willis Towers Watson Consulting (Singapore) Pte Ltd" then "Singapore"
                    else if [#"Operating Unit"] = "TW OU MY 3081-Malaysia" then "Malaysia"
                    else if [#"Operating Unit"] = "TW OU ID 3162-Indonesia" then "Indonesia"
                    else if [#"Operating Unit"] = "TW OU CN 3248-TW Mgmt Cons Shenzhen" then "China"
                    else if [#"Operating Unit"] = "TW OU TH 3221-Thailand" then "Thailand"
                    else if [#"Operating Unit"] = "TW OU JP 3062-KK" then "Japan"
                    else if [#"Operating Unit"] = "TW OU KR 3183-Willis Towers Watson Consulting Korea Limited" then "Korea"
                    else if [#"Operating Unit"] = "TW OU IN 3002-India Pvt" then "India"
                    else if [#"Operating Unit"] = "TW OU AU 3141-Australia" then "Australia"
                    else "NONE", type text),
            t3  = Table.AddColumn(t2, "RevenueCities", each
                    if [#"Operating Unit"] = "TW OU HK 3022-Hong Kong" then "HONG KONG"
                    else if [#"Operating Unit"] = "TW OU TW 3121-Delaware Taiwan" then "Taiwan"
                    else if [#"Operating Unit"] = "TW OU CN 3241-Shanghai" then "Shanghai"
                    else if [#"Operating Unit"] = "TW OU PH 3101-Philippines" then "Philippines"
                    else if [#"Operating Unit"] = "TW OU CN 3243-Beijing Br" then "Beijing"
                    else if [#"Operating Unit"] = "TW OU SG 3042- Willis Towers Watson Consulting (Singapore) Pte Ltd" then "Singapore"
                    else if [#"Operating Unit"] = "TW OU MY 3081-Malaysia" then "Malaysia"
                    else if [#"Operating Unit"] = "TW OU ID 3162-Indonesia" then "Indonesia"
                    else if [#"Operating Unit"] = "TW OU CN 3248-TW Mgmt Cons Shenzhen" then "Shenzhen"
                    else if [#"Operating Unit"] = "TW OU TH 3221-Thailand" then "Thailand"
                    else if [#"Operating Unit"] = "TW OU JP 3062-KK" then "Japan"
                    else if [#"Operating Unit"] = "TW OU KR 3183-Willis Towers Watson Consulting Korea Limited" then "Korea"
                    else if [#"Operating Unit"] = "TW OU IN 3002-India Pvt" then "India"
                    else if [#"Operating Unit"] = "TW OU AU 3141-Australia" then "Australia"
                    else "NONE", type text),
            t4  = Table.AddColumn(t3,  "Segment",          each "W&R",          type text),
            t5  = Table.AddColumn(t4,  "RecurringRevenue", each "Y",             type text),
            t6  = Table.AddColumn(t5,  "BusinessType",     each "Renewal",       type text),
            t7  = Table.AddColumn(t6,  "SystemProductClass", each "RDI",         type text),
            t8  = Table.AddColumn(t7,  "SubProduct/Service", each "RDI",         type text),
            t9  = Table.AddColumn(t8,  "Product/Service",    each "RDI",         type text),
            t10 = Table.AddColumn(t9,  "SystemID_New", each
                    [DataSource] & "-" & [#"Bill To Customer Number"], type text),
            t11 = Table.AddColumn(t10, "ClientID", each
                    if [GCID] = null then [SystemID_New] else [GCID], type text),
            t12 = Table.AddColumn(t11, "Source", each [DataSource], type text)
        in t12,

    // Step 3: Rename, Type, and Reorder
    #"Final Schema" =
        let
            renamed = Table.RenameColumns(#"Derived Columns", {
                {"Bill To Customer", "SystemClientName"},
                {"Reference",        "TX_ID"},
                {"Date",             "IncomeDate/InceptionDate"},
                {"Invoice Amount",   "Revenue"},
                {"SystemID_New",     "SystemID"}
            }),
            addedPremium = Table.AddColumn(renamed, "Premium", each 0, type number),
            addedDUNSNO  = Table.AddColumn(addedPremium, "DUNSNO", each "", type text),
            typed = Table.TransformColumnTypes(addedDUNSNO, {
                {"SystemClientName",         type text},
                {"SystemProductClass",       type text},
                {"TX_ID",                    type text},
                {"IncomeDate/InceptionDate", type date},
                {"Revenue",                  type number},
                {"SystemID",                 type text},
                {"RevenueCountry",           type text},
                {"ClientID",                 type text},
                {"DataSource",               type text},
                {"Segment",                  type text},
                {"BusinessType",             type text},
                {"RecurringRevenue",         type text},
                {"RevenueCities",            type text},
                {"DUNSNO",                   type text},
                {"Currency",                 type text},
                {"GCID",                     type text},
                {"Source",                   type text},
                {"SubProduct/Service",       type text},
                {"Product/Service",          type text}
            }),
            reordered = Table.SelectColumns(typed, {
                "SystemClientName",
                "SystemProductClass",
                "TX_ID",
                "IncomeDate/InceptionDate",
                "Revenue",
                "Premium",
                "SystemID",
                "RevenueCountry",
                "SubProduct/Service",
                "Product/Service",
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
