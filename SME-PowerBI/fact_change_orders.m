let
    // ═══════════════════════════════════════════════════════
    // FACT_CHANGE_ORDERS — Change Requests (Technology page)
    // ═══════════════════════════════════════════════════════
    // Added: ApprovedDateKey (FK → dim_date)
    // Approved Cost column removed from source by stakeholder

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_change_technology", ItemKind = "Table"]}[Data],

    // === STEP 1: Filter out header/junk rows (Status = year like "2026") ===
    #"Filtered junk" = Table.SelectRows(Raw, each
        [Change Request Number] <> null and [Change Request Number] <> ""
    ),

    // === STEP 2: Rename to PascalCase ===
    #"Renamed" = Table.RenameColumns(#"Filtered junk", {
        {"Change Request", "ChangeRequestDesc"},
        {"Change Request Number", "ChangeRequestNumber"},
        {"Approved date", "ApprovedDate"},
        {"Target Release Date to UAT", "TargetReleaseUAT"},
        {"Release Date _Actual Release to Prod_", "ActualReleaseProd"},
        {"Cost Type", "CostType"},
        {"% Completion | Time and Materials", "CompletionPct"},
        {"Due date _Based on change order_", "DueDateNote"}
    }),

    // === STEP 3: Trim text ===
    #"Trimmed" = Table.TransformColumns(#"Renamed", {
        {"ChangeRequestNumber", each Text.Trim(_ ?? ""), type text},
        {"ChangeRequestDesc",   each Text.Trim(_ ?? ""), type text},
        {"Status",              each Text.Trim(_ ?? ""), type text},
        {"TargetReleaseUAT",    each Text.Trim(_ ?? ""), type text},
        {"CostType",            each Text.Trim(_ ?? ""), type text},
        {"CompletionPct",       each Text.Trim(_ ?? ""), type text},
        {"DueDateNote",         each Text.Trim(_ ?? ""), type text}
    }),
    // === STEP 4: Handle nulls — no cost column anymore ===
    #"Cleaned" = #"Trimmed",

    // === STEP 5: Add IsOpen flag ===
    #"Added IsOpen" = Table.AddColumn(#"Cleaned", "IsOpen", each
        [Status] <> "Completed" and [Status] <> "Closed" and [Status] <> "Cancelled",
        type logical),

    // === STEP 6: Set types ===
    #"Set types" = Table.TransformColumnTypes(#"Added IsOpen", {
        {"ChangeRequestNumber", type text},
        {"ChangeRequestDesc", type text},
        {"Status", type text},
        {"ApprovedDate", type date},
        {"TargetReleaseUAT", type text},
        {"ActualReleaseProd", type date},
        {"CostType", type text},
        {"CompletionPct", type text},
        {"DueDateNote", type text}
    }),

    // === STEP 7: Add ApprovedDateKey (YYYYMMDD int → FK to dim_date) ===
    #"Added DateKey" = Table.AddColumn(#"Set types", "ApprovedDateKey", each
        if [ApprovedDate] = null then null
        else Date.Year([ApprovedDate]) * 10000
           + Date.Month([ApprovedDate]) * 100
           + Date.Day([ApprovedDate]),
        Int64.Type),

    // === FINAL: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Added DateKey", {
        "ChangeRequestNumber", "ChangeRequestDesc", "Status", "IsOpen",
        "ApprovedDateKey", "ApprovedDate", "TargetReleaseUAT", "ActualReleaseProd", "DueDateNote",
        "CostType", "CompletionPct"
    })
in
    #"Reordered"
