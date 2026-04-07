let
    // Connect to Fabric Lakehouse
    // Bronze table already includes GCID (OracleID Mapping join done at Bronze layer)
    Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
    Navigation_1 = Pattern{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Navigation_2 = Navigation_1{[lakehouseId = "1c0d3357-c170-4ddd-9738-e1c90bbe99f2"]}[Data],
    Raw = Navigation_2{[Id = "src_ret_oracle", ItemKind = "Table"]}[Data],

    // OracleID Mapping join — adds GCID from lookup table in Power BI model
    #"Merged queries" = Table.NestedJoin(Raw, {"Primary Customer Account Number"}, #"OracleID Mapping", {"OracleID"}, "OracleID Mapping", JoinKind.LeftOuter),
    #"With GCID" = Table.ExpandTableColumn(#"Merged queries", "OracleID Mapping", {"GCID"}, {"GCID"}),

    // Step 1: Filter and Select Base Columns
    #"Base Columns" = Table.SelectColumns(
        Table.SelectRows(#"With GCID",
            each Text.StartsWith([TW_Service_Offering], "RET")
        ),
        {"Customer Name", "CLIENT GROUP Global DUNS Number", "Fiscal Period",
         "Fiscal Period Number", "Project Number", "TW_Service_Offering",
         "Project Office Code", "Project Market Cluster Name", "Employee Market Cluster",
         "Revenue Amount", "Primary Customer Account Number", "GCID", "Source.Name"}
    ),

    // Step 2: Fix Fiscal Period
    // Some annual files store dates as YYYYMM integers — reconstruct to first-of-month date
    #"Fixed Fiscal Period" = Table.AddColumn(#"Base Columns", "Fiscal Period Fixed", each
        if List.Contains(
            {"Retirement Project Revenue Dec 2018 YTD .xlsx",
             "Retirement Project Revenue Dec 2019 YTD .xlsx",
             "Retirement Project Revenue December YTD 2020.xlsx",
             "Retirement Project Revenue YTD 2021.xlsx",
             "Retirement Project Revenue YTD 2022.xlsx",
             "Retirement Project Revenue YTD 2023.xlsx",
             "Retirement Project Revenue YTD 2024.xlsx",
             "Retirement Project Revenue December YTD 2025.xlsx"},
            [#"Source.Name"]
        )
        then Date.FromText(
            Text.Start([#"Fiscal Period Number"], 4) & "-" &
            Text.End([#"Fiscal Period Number"], 2) & "-01"
        )
        else [#"Fiscal Period"],
        type date),

    // Step 3: Add Derived Columns
    #"Derived Columns" =
        let
            t1  = Table.AddColumn(#"Fixed Fiscal Period", "DataSource",       each "Oracle",   type text),
            t2  = Table.AddColumn(t1,  "Segment",         each "RET",          type text),
            t3  = Table.AddColumn(t2,  "BusinessType",    each "Renewal",      type text),
            t4  = Table.AddColumn(t3,  "RecurringRevenue",each "Y",            type text),
            t5  = Table.AddColumn(t4,  "RevenueCities", each
                    if [#"Project Office Code"] = "HKG1" then "Hong Kong"
                    else if [#"Project Office Code"] = "PH$5" then "Manila"
                    else if [#"Project Office Code"] = "MEL2" then "Melbourne"
                    else if [#"Project Office Code"] = "BEI1" then "Beijing"
                    else if [#"Project Office Code"] = "JPM2" then "Osaka"
                    else if [#"Project Office Code"] = "SYD1" then "Sydney"
                    else if [#"Project Office Code"] = "ISA1" then "Mount Isa"
                    else if [#"Project Office Code"] = "THA1" then "Bangkok"
                    else if [#"Project Office Code"] = "GUR3" then "Gurgaon"
                    else if [#"Project Office Code"] = "BAN1" then "Bangalore"
                    else if [#"Project Office Code"] = "KOL1" then "Kolkata"
                    else if [#"Project Office Code"] = "SHA1" then "Shanghai"
                    else if [#"Project Office Code"] = "MUM1" then "Mumbai"
                    else if [#"Project Office Code"] = "TWN1" then "Taipei"
                    else if [#"Project Office Code"] = "SKO1" then "Seoul"
                    else if [#"Project Office Code"] = "SHE1" then "Shenyang"
                    else if [#"Project Office Code"] = "SGP2" then "Singapore"
                    else if [#"Project Office Code"] = "MLS2" then "Kuala Lumpur"
                    else if [#"Project Office Code"] = "PHP4" then "Manila"
                    else if [#"Project Office Code"] = "PHP1" then "Manila"
                    else if [#"Project Office Code"] = "PHP2" then "Manila"
                    else "", type text),
            t6  = Table.AddColumn(t5,  "RevenueCountry_Temp", each
                    Text.Replace([#"Employee Market Cluster"], "Market", ""), type text),
            t7  = Table.AddColumn(t6,  "RevenueCountry", each
                    if [RevenueCountry_Temp] = "AP DATA MANAGEMENT CENTER" then "Philippines"
                    else if Text.Trim([RevenueCountry_Temp]) = "India Consulting" then "India"
                    else [RevenueCountry_Temp], type text),
            t8  = Table.AddColumn(t7,  "SystemID_New", each
                    let cleanID =
                        if [#"Primary Customer Account Number"] <> null and
                           [#"Primary Customer Account Number"] <> "" and
                           [#"Primary Customer Account Number"] <> "0"
                        then [#"Primary Customer Account Number"]
                        else [#"Customer Name"]
                    in [DataSource] & "-" & cleanID, type text),
            t9  = Table.AddColumn(t8,  "ClientID", each if [GCID] = null then [SystemID_New] else [GCID], type text),
            t10 = Table.AddColumn(t9,  "Source",   each [DataSource], type text),
            t11 = Table.AddColumn(t10, "Currency", each "USD",        type text)
        in t11,

    // Step 4: Rename, Type, and Reorder
    #"Final Schema" =
        let
            renamed = Table.RenameColumns(#"Derived Columns", {
                {"Customer Name",                  "SystemClientName"},
                {"TW_Service_Offering",            "SystemProductClass"},
                {"Project Number",                 "TX_ID"},
                {"Fiscal Period Fixed",            "IncomeDate/InceptionDate"},
                {"Revenue Amount",                 "Revenue"},
                {"CLIENT GROUP Global DUNS Number","DUNSNO"},
                {"SystemID_New",                   "SystemID"}
            }),
            addedPremium = Table.AddColumn(renamed, "Premium", each 0, type number),
            typed = Table.TransformColumnTypes(addedPremium, {
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
                {"Source",                   type text}
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
