let
    // Connect to Fabric Lakehouse
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "1c0d3357-c170-4ddd-9738-e1c90bbe99f2"]}[Data],
    Raw = #"Navigation 1"{[Id = "src_eclipse_crb", ItemKind = "Table"]}[Data],

    // Step 1: Filter, Select Base Columns, and safely cast date columns (try/otherwise prevents
    // whole-table failure when an individual row is blank or unparseable).
    #"Base Columns" = Table.TransformColumns(
        Table.SelectColumns(
            Table.SelectRows(Raw,
                each [LegalEntity] <> "PT. Willis Reinsurance Brokers Indonesia"
                  and [LegalEntity] <> "Willis Towers Watson Taiwan Limited"
            ),
            {"LegalEntity", "BusinessUnit", "Team", "PolicyRef", "InceptionDate", "ExpiryDate",
             "Insured", "NetBkgeUSDPlan", "GrossPremNonTtyUSDPlan", "ClassOfBusiness",
             "Willis Party ID", "Dun and Bradstreet No", "Revenue Type", "InsuredID", "BUSegment"}
        ),
        {{"InceptionDate", each try DateTime.From(_) otherwise null, type datetime},
         {"ExpiryDate",    each try DateTime.From(_) otherwise null, type datetime}}
    ),

    // Step 2: Add Derived Columns
    #"Derived Columns" =
        let
            t1  = Table.AddColumn(#"Base Columns", "GCID", each [#"Willis Party ID"], type text),
            t2  = Table.AddColumn(t1,  "DataSource", each "ECLIPSE", type text),
            t3  = Table.AddColumn(t2,  "SystemID", each [DataSource] & "-" & Text.From([InsuredID]), type text),
            t4  = Table.AddColumn(t3,  "RecurringRevenue", each
                    if [#"Revenue Type"] = "New/Existing-One Off" then "N"
                    else if [#"Revenue Type"] = "New / New - One-Off" then "N"
                    else "Y", type text),
            t5  = Table.AddColumn(t4,  "BusinessType", each
                    if [#"Revenue Type"] = "New/Existing-One Off" then "New Business"
                    else if [#"Revenue Type"] = "New/New - Recurring" then "Renewal"
                    else if [#"Revenue Type"] = "New" then "New Business"
                    else if [#"Revenue Type"] = "New / New - One-Off" then "New Business"
                    else [#"Revenue Type"], type text),
            t6  = Table.AddColumn(t5,  "IdentifySGRetail", each [BusinessUnit] & "+" & [Team], type text),
            t7  = Table.AddColumn(t6,  "RevenueCountry", each
                    if List.Contains({"Retail+Corporate", "Retail+Commercial", "SG Retail",
                        "Retail+FINEX OR Identify", "Retail+Network",
                        "Retail+Asia Placement M&A", "Retail+Client Service Team 1",
                        "Retail+Client Service Team 2", "Retail+Client Service Team 3"},
                        [IdentifySGRetail]) then "Singapore"
                    else if Text.Contains([LegalEntity], "Hong Kong") then "Hong Kong"
                    else if Text.Contains([LegalEntity], "Philippines") then "Philippines"
                    else if Text.Contains([LegalEntity], "Indonesia") then "Indonesia"
                    else "Asia Virtual", type text),
            t8  = Table.AddColumn(t7,  "RevenueCities", each "", type text),
            t9  = Table.AddColumn(t8,  "SystemProductMapping", each [BusinessUnit] & "+" & [Team] & "+" & [ClassOfBusiness], type text),
            t10 = Table.AddColumn(t9,  "ClientID_Temp", each if [GCID] = null then [SystemID] else [GCID], type text),
            t11 = Table.AddColumn(t10, "Source", each [DataSource], type text),
            t12 = Table.AddColumn(t11, "SystemProductClass", each [SystemProductMapping], type text),
            t13 = Table.AddColumn(t12, "SystemProductClass2", each [ClassOfBusiness], type text),
            t14 = Table.AddColumn(t13, "Currency", each "USD", type text)
        in t14,

    // Step 3: Rename, Type, and Reorder
    #"Final Schema" =
        let
            renamed = Table.RenameColumns(#"Derived Columns", {
                {"PolicyRef",              "TX_ID"},
                {"InceptionDate",          "IncomeDate/InceptionDate"},
                {"ExpiryDate",             "PolicyEndsDate"},
                {"Insured",                "SystemClientName"},
                {"NetBkgeUSDPlan",         "Revenue"},
                {"GrossPremNonTtyUSDPlan", "Premium"},
                {"Dun and Bradstreet No",  "DUNSNO"},
                {"BUSegment",              "Segment"},
                {"ClientID_Temp",          "ClientID"}
            }),
            typed = Table.TransformColumnTypes(renamed, {
                {"TX_ID",                    type text},
                {"IncomeDate/InceptionDate", type datetime},
                {"PolicyEndsDate",           type datetime},
                {"Revenue",                  type number},
                {"Premium",                  type number},
                {"GCID",                     type text},
                {"InsuredID",                type text},
                {"ClientID",                 type text}
            }),
            reordered = Table.SelectColumns(typed, {
                "SystemClientName",
                "SystemProductClass",
                "SystemProductClass2",
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
            }, MissingField.UseNull)
        in reordered

in
    #"Final Schema"
