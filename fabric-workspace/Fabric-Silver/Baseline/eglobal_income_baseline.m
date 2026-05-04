let
    // Configuration - Country/Currency mapping
    CountryMapping = #table(
        {"FilePattern", "Revenue Country", "Currency"},
        {
            {"_AU_", "Australia", "AUD"},
            {"_CN.", "China", "CNY"},
            {"_HK.", "Hong Kong", "HKD"},
            {"_ID.", "Indonesia", "IDR"},
            {"_KR.", "Korea", "KRW"},
            {"_NZ.", "New Zealand", "NZD"},
            {"_RO.", "Australia", "AUD"},
            {"_TW.", "Taiwan", "TWD"}
        }
    ),

    // Connect to Fabric Lakehouse
    Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
    Navigation_1 = Pattern{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Navigation_2 = Navigation_1{[lakehouseId = "1c0d3357-c170-4ddd-9738-e1c90bbe99f2"]}[Data],
    Raw = Navigation_2{[Id = "src_eglobal_income_report", ItemKind = "Table"]}[Data],

    // Step 1: Filter and Select Base Columns
    // Column names match Fabric-normalized names from src_eglobal_income_report Bronze
    #"Base CRB Columns" = Table.SelectColumns(
        Table.SelectRows(Raw,
            each not List.Contains({"EMB", "RET", "EBD", "EBC", "EBM", "EBS", "ECS", "GBM", "BEB", "MEB", "PEB", "SEB", "AEB", "CEB", "WEB", "UEB"}, [Department])
        ),
        {"Client No", "Client Name", "Department", "PREMIUM", "TOTAL INCOME", "Company", "Branch", "Risk", "Inv No", "EFFECTIVE DATE", "INCOME CLASS", "PARTY ID", "DUNS NUMBER", "Source.Name"}
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
            t2 = Table.AddColumn(t1, "RevenueCountry", each GetCountryInfo([#"Source.Name"], "Revenue Country"), type text),
            t3 = Table.AddColumn(t2, "Currency", each GetCountryInfo([#"Source.Name"], "Currency"), type text),
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
                {"Source.Name",    "DataSource"},
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
