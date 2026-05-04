let
  Source = SharePoint.Files("https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat", [ApiVersion = 15]),
  #"Filtered rows" = Table.SelectRows(Source, each ([Folder Path] = "https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat/Data Library/Client Baseline/02. Raw Data/eGlobal/")),
  #"Filtered rows 1" = Table.SelectRows(#"Filtered rows", each Text.StartsWith([Name], "IncomebyDepartmentandClient")),
  #"Filtered hidden files" = Table.SelectRows(#"Filtered rows 1", each [Attributes]?[Hidden]? <> true),
  #"Invoke custom function" = Table.AddColumn(#"Filtered hidden files", "Transform file (2)", each #"Transform file (2)"([Content])),
  #"Renamed columns" = Table.RenameColumns(#"Invoke custom function", {{"Name", "Source.Name"}}),
  #"Removed other columns" = Table.SelectColumns(#"Renamed columns", {"Source.Name", "Transform file (2)"}),
  #"Expanded table column" = Table.ExpandTableColumn(#"Removed other columns", "Transform file (2)", Table.ColumnNames(#"Transform file (2)"(#"Sample file (2)"))),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded table column", {{"Column1", type text}, {"Column2", type text}, {"Column3", type text}, {"Column4", type text}, {"Column14", type text}, {"Column15", type text}, {"Column16", type text}, {"Column17", type text}, {"Column18", type text}, {"Column20", type text}, {"Column21", type text}, {"Column22", type text}, {"Column23", type text}, {"Column24", type text}, {"Column25", type text}, {"Column26", type text}, {"Column27", type text}, {"Column29", type text}, {"Column31", type text}, {"Column36", type text}, {"Column38", type text}, {"Column39", type text}, {"Column40", type text}}),
  #"Removed top rows" = Table.Skip(#"Changed column type", 2),
  #"Promoted headers" = Table.PromoteHeaders(#"Removed top rows", [PromoteAllScalars = true]),

  // Normalize column names to match Fabric Delta storage: trim whitespace, replace spaces with underscores
  #"Normalized column names" = Table.RenameColumns(
    #"Promoted headers",
    List.Transform(
      Table.ColumnNames(#"Promoted headers"),
      each {_, Text.Replace(Text.Trim(_), " ", "_")}
    )
  ),

  // Safe numeric conversion - ALL as nullable number (no Int64)
  #"Safe Numeric Conversion" = Table.TransformColumns(#"Normalized column names", {
    {"PREMIUM",        each try Number.From(_) otherwise 0,    type nullable number},
    {"CEQUAKE",        each try Number.From(_) otherwise 0,    type nullable number},
    {"BSC_FEE",        each try Number.From(_) otherwise 0,    type nullable number},
    {"ADMIN_FEE",      each try Number.From(_) otherwise 0,    type nullable number},
    {"POLICY_FEE",     each try Number.From(_) otherwise 0,    type nullable number},
    {"BROKERAGE",      each try Number.From(_) otherwise 0,    type nullable number},
    {"DISCOUNT",       each try Number.From(_) otherwise 0,    type nullable number},
    {"SUB_AGENT",      each try Number.From(_) otherwise 0,    type nullable number},
    {"TOTAL_INCOME",   each try Number.From(_) otherwise 0,    type nullable number},
    {"EXCHANGE_RATE",  each try Number.From(_) otherwise null, type nullable number}
  }),

  // Safe date conversion
  #"Safe Date Conversion" = Table.TransformColumns(#"Safe Numeric Conversion", {
    {"Inv_Date",         each try Date.From(_) otherwise null, type nullable date},
    {"INCEPTION_DATE",   each try Date.From(_) otherwise null, type nullable date},
    {"EFFECTIVE_DATE",   each try Date.From(_) otherwise null, type nullable date},
    {"RENEWAL_DATE",     each try Date.From(_) otherwise null, type nullable date},
    {"LAST_RENEWAL_DATE",each try Date.From(_) otherwise null, type nullable date},
    {"INCOME_DATE",      each try Date.From(_) otherwise null, type nullable date}
  }),

  // Set text types
  #"Set Text Types" = Table.TransformColumnTypes(#"Safe Date Conversion", {
    {"Client_No",        type text},
    {"Inv_No",           type text},
    {"Cover_No",         type text},
    {"Ver._No",          type text},
    {"NO_OF_INSTALMENTS",type text},
    {"PARTY_ID",         type text},
    {"DUNS_NUMBER",      type text}
  })

in
  #"Set Text Types"
