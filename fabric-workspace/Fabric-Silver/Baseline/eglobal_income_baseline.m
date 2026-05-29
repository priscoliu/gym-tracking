let
    // Configuration - Country/Currency mapping
    CountryMapping = #table(
        {"FilePattern", "Revenue Country", "Currency"},
        {
            {"_AU_", "Australia", "AUD"},
            {"_CN.", "China", "CNY"},
            {"_HK.", "Hong Kong", "HKD"},
            {"_ID.", "Indonesia", "IDR"},
            {"_KR.", "South Korea", "KRW"},
            {"_NZ.", "New Zealand", "NZD"},
            {"_PH_", "Philippines", "PHP"},
            {"_RO.", "Australia", "AUD"},
            {"_SG.", "Singapore", "SGD"},
            {"_TW.", "Taiwan", "TWD"}
        }
    ),
    // Connect to Fabric Lakehouse
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "1c0d3357-c170-4ddd-9738-e1c90bbe99f2"]}[Data],
    Raw = #"Navigation 1"{[Id = "src_eglobal_income_report", ItemKind = "Table"]}[Data],

        // Trim trailing spaces from source columns
        #"Cleaned Headers" = Table.RenameColumns(Raw, {
            {"Company ",       "Company"},
            {"Inv Date ",      "Inv Date"},
            {"Industry Code ", "Industry Code"}
        }, MissingField.Ignore),

        // Step 1: Filter, Select Base Columns, and safely cast date columns (try/otherwise prevents
        // whole-table failure when an individual row is blank or unparseable).
        #"Base CRB Columns" = Table.TransformColumns(
            Table.SelectColumns(
                Table.SelectRows(#"Cleaned Headers",
                    each not List.Contains({"EMB", "RET", "EBD", "EBC", "EBM", "EBS", "ECS", "GBM", "BEB", "MEB", "PEB", "SEB", "AEB", "CEB", "WEB", "UEB", "HBB","HCB"}, [Department])
                ),
                {"Client No", "Client Name", "Department", "PREMIUM", "TOTAL INCOME", "Company", "Branch", "Risk", "Inv No", "EFFECTIVE DATE", "INCOME CLASS", "PARTY ID", "DUNS NUMBER", "Source_Name"}
            ),
            {{"EFFECTIVE DATE", each try DateTime.From(_) otherwise null, type datetime}}
    ),
    // Step 2: Add Business Logic Columns
    #"Business Logic" =
        let
            t1 = Table.AddColumn(#"Base CRB Columns", "BusinessType", each
                if [#"INCOME CLASS"] = "RRN" then "Renewal"
                else if List.Contains({"MDIAC", "MDI"}, [#"INCOME CLASS"]) then "MDI"
                else "New Business", type text),
            t2 = Table.AddColumn(t1, "RecurringRevenue", each
                if List.Contains({"RRN", "RNE", "RNN"}, [#"INCOME CLASS"]) then "Y" else "N", type text)
        in t2,

    // Step 3: Add Derived Columns (SystemID, Country, Currency)
    #"Derived Columns" =
        let
            GetCountryInfo = (fileName as text, field as text) =>
                let
                    Match = List.First(List.Select(Table.ToRecords(CountryMapping), (r) => Text.Contains(fileName, r[FilePattern])), null)
                in
                    if Match <> null then Record.Field(Match, field) else "",

            t1 = Table.AddColumn(#"Business Logic", "SystemID", each Text.Combine({[Company], [Branch], [#"Client No"]}), type text),
            t2 = Table.AddColumn(t1, "RevenueCountry", each GetCountryInfo([Source_Name], "Revenue Country"), type text),
            t3 = Table.AddColumn(t2, "Currency", each GetCountryInfo([Source_Name], "Currency"), type text),
            t4 = Table.AddColumn(t3, "ClientID", each if [#"PARTY ID"] = null then [SystemID] else Text.From([#"PARTY ID"]), type text),
            t5 = Table.AddColumn(t4, "Source", each "eGlobal", type text),
            t6 = Table.AddColumn(t5, "RevenueCities", each "", type text)
        in t6,

    // Step 4: Rename, Type, and Reorder
    #"Final Schema" =
        let
            renamed = Table.RenameColumns(#"Derived Columns", {
                {"Client Name",    "SystemClientName"},
                {"Risk",           "SystemProductClass"},
                {"Inv No",         "TX_ID"},
                {"EFFECTIVE DATE", "IncomeDate/InceptionDate"},
                {"TOTAL INCOME",   "Revenue"},
                {"PREMIUM",        "Premium"},
                {"PARTY ID",       "GCID"},
                {"Source_Name",    "DataSource"},
                {"DUNS NUMBER",    "DUNSNO"},
                {"Department",     "Segment"}
            }),
            typed = Table.TransformColumnTypes(renamed, {
                {"TX_ID",      type text},
                {"GCID",       type text},
                {"DataSource", type text}
            }),
            typedNumbers = Table.TransformColumns(typed, {
                {"Premium", each try Number.From(_) otherwise 0, type number},
                {"Revenue", each try Number.From(_) otherwise 0, type number}
            }),
            typedDate = Table.TransformColumns(typedNumbers, {
                {"IncomeDate/InceptionDate", each try Date.From(_) otherwise null, type date}
            }),
            dataSourceFixed = Table.TransformColumns(typedDate, {
                {"DataSource", each "eGlobal", type text},
                {"Segment",    each "CRB",     type text}
            }),
            reordered = Table.SelectColumns(dataSourceFixed, {
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