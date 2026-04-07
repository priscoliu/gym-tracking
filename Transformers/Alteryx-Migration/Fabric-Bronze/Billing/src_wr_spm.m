let
    Source = SharePoint.Files("https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat", [ApiVersion = 15]),
    #"Filtered rows" = Table.SelectRows(Source, each
        [Folder Path] = "https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat/Data Library/Client Baseline/02. Raw Data/SPM/"
        and Text.EndsWith([Name], ".xlsx")
        and not Text.StartsWith([Name], "~$")
        and [Name] <> "RDS 2018 - 2019.xlsx"
        and [Name] <> "RDS 2020 - 2021.xlsx"
    ),
    #"Filtered hidden files" = Table.SelectRows(#"Filtered rows", each [Attributes]?[Hidden]? <> true),
    #"Invoke custom function" = Table.AddColumn(#"Filtered hidden files", "Transform file (5)", each #"Transform file (5)"([Content])),
    #"Renamed columns" = Table.RenameColumns(#"Invoke custom function", {{"Name", "Source.Name"}}),
    #"Removed other columns" = Table.SelectColumns(#"Renamed columns", {"Source.Name", "Transform file (5)"}),
    #"Expanded table column" = Table.ExpandTableColumn(#"Removed other columns", "Transform file (5)", Table.ColumnNames(#"Transform file (5)"(#"Sample file (5)"))),

    // Cast all columns to text first — prevents type errors from mixed-format cells
    #"Changed column type" = Table.TransformColumnTypes(#"Expanded table column", {
        {"Source", type text},
        {"Reference", type text},
        {"Operating Unit", type text},
        {"Legal Entity Name", type text},
        {"Bill To Customer", type text},
        {"Class", type text},
        {"Complete", type text},
        {"Balance Due", type text},
        {"Invoice Amount", type text},
        {"Currency", type text},
        {"Date", type text},
        {"GL Date", type text},
        {"Terms", type text},
        {"Type", type text},
        {"[ ]", type text},
        {"( )", type text},
        {"Transaction", type text},
        {"Bill To  Address", type text},
        {"Ship To Address", type text},
        {"Bill To Contact", type text},
        {"Ship To Contact", type text},
        {"Bill To Customer Number", type text},
        {"Batch", type text}
    }),

    // Convert dates and numbers with error handling
    #"Convert Dates" = Table.TransformColumns(#"Changed column type", {
        {"Date", each try Date.From(_) otherwise null, type date},
        {"GL Date", each try Date.From(_) otherwise null, type date}
    }),
    #"Convert Numbers" = Table.TransformColumns(#"Convert Dates", {
        {"Balance Due", each try Number.From(_) otherwise 0, type number},
        {"Invoice Amount", each try Number.From(_) otherwise 0, type number}
    }),

    #"Choose columns" = Table.SelectColumns(#"Convert Numbers", {
        "Reference", "Operating Unit", "Bill To Customer", "Invoice Amount",
        "Currency", "Date", "Bill To Customer Number"
    }),
    #"Appended query" = Table.Combine({#"Choose columns", #"W&R2019", #"W&R2021", #"W&R2020", #"W&R2018"}),

    // Replace all Excel error values (#N/A, #REF!, #VALUE!, etc.) with null
    #"Replaced errors" = Table.ReplaceErrorValues(
        #"Appended query",
        List.Transform(Table.ColumnNames(#"Appended query"), each {_, null})
    ),

    // Normalize column names: trim whitespace then strip any trailing underscores
    #"Normalized column names" = Table.RenameColumns(
        #"Replaced errors",
        List.Transform(
            Table.ColumnNames(#"Replaced errors"),
            each {_, Text.TrimEnd(Text.Trim(_), "_")}
        )
    )

in
    #"Normalized column names"
