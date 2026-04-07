let
    Source = SharePoint.Files("https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat", [ApiVersion = 15]),
    #"Filtered rows 1" = Table.SelectRows(Source, each [Folder Path] = "https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat/Data Library/Client Baseline/02. Raw Data/Oracle (RET)/"),
    #"Filtered hidden files" = Table.SelectRows(#"Filtered rows 1", each [Attributes]?[Hidden]? <> true),
    #"Renamed columns" = Table.RenameColumns(#"Filtered hidden files", {{"Name", "Source.Name"}}),
    #"Invoke custom function" = Table.AddColumn(#"Renamed columns", "Transform file (4)", each #"Transform file (4)"([Content])),

    // Keep Source.Name so Silver can identify the file for Fiscal Period fix
    #"Removed other columns" = Table.SelectColumns(#"Invoke custom function", {"Source.Name", "Transform file (4)"}),
    #"Expanded table column" = Table.ExpandTableColumn(#"Removed other columns", "Transform file (4)", Table.ColumnNames(#"Transform file (4)"(#"Sample file (4)"))),

    #"Changed column type" = Table.TransformColumnTypes(#"Expanded table column", {
        {"Primary Customer Account Number", type text}, {"Fiscal Period Number", type text}, {"Project Number", type text},
        {"Customer Name", type text}, {"TW_CIS Company Name", type text}, {"TW_Time Period", type text},
        {"Fiscal Quarter", type text}, {"Project Name", type text}, {"Project Organization Name", type text},
        {"Project ""Bill to"" Country", type text}, {"TW_Service_Offering", type text},
        {"Project Segment Code", type text}, {"Project Segment Name", type text},
        {"Project Line of Business Code", type text}, {"Project Line of Business Name", type text},
        {"Project Practice Code", type text}, {"Project Practice Name", type text},
        {"Project Region Name", type text}, {"Project Office Code", type text},
        {"Project Market Cluster Name", type text}, {"TW_OU Number", type text},
        {"Project Manager Name", type text}, {"Employee Region", type text}, {"Employee Division", type text},
        {"Employee Market Cluster", type text}, {"Employee Office Code", type text}, {"Employee Name", type text},
        {"Employee Segment Code", type text}, {"Employee Segment", type text},
        {"Employee LOB Code", type text}, {"Employee LOB", type text},
        {"Employee Practice Code", type text}, {"Employee Practice", type text},
        {"Currency Code", type text}, {"Country Leader", type text},
        {"TW_CIS Company Number", type text}, {"CLIENT GROUP Global DUNS Number", type text},
        {"TW_CIS Parent Company Number", type text}, {"Employee Number", type text},
        {"Fiscal Period", type date},
        {"Fiscal Year", type nullable number}, {"Project Description", type nullable number},
        {"Project Team Code", type nullable number}, {"TW_Project Discount %", type nullable number},
        {"Employee Team Code", type nullable number},
        {"Billable hours", type number}, {"Rack rate time charges", type number},
        {"Systematic project discounts versus rack rate charges", type number},
        {"Time charged to project WIP", type number}, {"TW_Admin and Tech Charges", type number},
        {"TW_Billable Client Expenses", type number},
        {"Total WIP charges (time + admin + 3rd party expenses)", type number},
        {"TW_Planned Realization Event", type number}, {"TW_Unplanned Realization Amount", type number},
        {"TW_A/R Write-Off", type nullable number}, {"Combined WIP and AR write-offs", type number},
        {"TW_Fees, Other Commissions and Adj", type nullable number},
        {"TW_Intellectual Capital", type nullable number}, {"TW_Brokerage Commissions", type nullable number},
        {"TW_Brokerage Investment Income", type nullable number},
        {"TW_Software and Other Product Revenue", type nullable number},
        {"Revenue Amount", type number}
    }),

    // Replace all Excel error values (#N/A, #REF!, #VALUE!, etc.) with null
    #"Replaced errors" = Table.ReplaceErrorValues(
        #"Changed column type",
        List.Transform(Table.ColumnNames(#"Changed column type"), each {_, null})
    ),

    // Normalize column names: trim whitespace then strip any trailing underscores
    // Prevents Fabric from storing trailing _ caused by trailing spaces or punctuation in Excel headers
    #"Normalized column names" = Table.RenameColumns(
        #"Replaced errors",
        List.Transform(
            Table.ColumnNames(#"Replaced errors"),
            each {_, Text.TrimEnd(Text.Trim(_), "_")}
        )
    )

in
    #"Normalized column names"
