let
    // ═══════════════════════════════════════════════════════
    // FACT_QUOTES — Lean (11 columns)
    // ═══════════════════════════════════════════════════════
    // Added: InsuredName (FK → dim_clients), CreationDateKey (FK → dim_date), IsConverted

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_quote_marketing", ItemKind = "Table"]}[Data],

    // === STEP 1: Filter out test data ===
    #"Filtered" = Table.SelectRows(Raw, each [TestData] <> "Yes"),

    // === STEP 2: Keep only required columns ===
    #"Selected columns" = Table.SelectColumns(#"Filtered", {
        "Insured", "QuoteType", "CreationDate", "LastModifiedDate",
        "PolicyNumber", "QuoteReference", "QuoteStatus",
        "BasePremium", "TotalPremium"
    }),

    // === STEP 3: Clean currency columns (strip $ and commas) ===
    #"Cleaned currency" = Table.TransformColumns(#"Selected columns", {
        {"BasePremium", each
            let
                asText = if Value.Is(_, type text) then _ else Text.From(_ ?? "0"),
                stripped = Text.Replace(Text.Replace(Text.Replace(asText, "$", ""), ",", ""), " ", "")
            in
                if stripped = "" or stripped = null then 0 else Number.From(stripped),
         type number},
        {"TotalPremium", each
            let
                asText = if Value.Is(_, type text) then _ else Text.From(_ ?? "0"),
                stripped = Text.Replace(Text.Replace(Text.Replace(asText, "$", ""), ",", ""), " ", "")
            in
                if stripped = "" or stripped = null then 0 else Number.From(stripped),
         type number}
    }),

    // === STEP 4: Rename Insured → InsuredName ===
    #"Renamed" = Table.RenameColumns(#"Cleaned currency", {
        {"Insured", "InsuredName"}
    }),

    // === STEP 5: Set types ===
    #"Set types" = Table.TransformColumnTypes(#"Renamed", {
        {"InsuredName", type text},
        {"QuoteType", type text},
        {"CreationDate", type date},
        {"LastModifiedDate", type date},
        {"PolicyNumber", type text},
        {"QuoteReference", type text},
        {"QuoteStatus", type text},
        {"BasePremium", Currency.Type},
        {"TotalPremium", Currency.Type}
    }),

    // === STEP 6: Trim text + UPPER InsuredName (match dim_clients) ===
    #"Trimmed" = Table.TransformColumns(#"Set types", {
        {"InsuredName",     each Text.Upper(Text.Trim(Text.Clean(_ ?? ""))), type text},
        {"QuoteType",       each Text.Trim(_ ?? ""), type text},
        {"PolicyNumber",    each Text.Trim(_ ?? ""), type text},
        {"QuoteReference",  each Text.Trim(_ ?? ""), type text},
        {"QuoteStatus",     each Text.Trim(_ ?? ""), type text}
    }),

    // === STEP 7: Add CreationDateKey (YYYYMMDD int → FK to dim_date) ===
    #"Added DateKey" = Table.AddColumn(#"Trimmed", "CreationDateKey", each
        if [CreationDate] = null then null
        else Date.Year([CreationDate]) * 10000
           + Date.Month([CreationDate]) * 100
           + Date.Day([CreationDate]),
        Int64.Type),

    // === STEP 8: Add IsConverted flag (Complete = converted to sale) ===
    #"Added IsConverted" = Table.AddColumn(#"Added DateKey", "IsConverted", each
        [QuoteStatus] = "Complete", type logical),

    // === FINAL: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Added IsConverted", {
        "InsuredName", "QuoteReference", "CreationDateKey", "CreationDate",
        "LastModifiedDate", "QuoteType", "QuoteStatus", "IsConverted",
        "PolicyNumber", "BasePremium", "TotalPremium"
    })
in
    #"Reordered"
