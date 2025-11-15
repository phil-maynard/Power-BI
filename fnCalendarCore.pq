// fnDateCore
// Low-level engine: builds a date table between StartDate and EndDate
// with calendar + fiscal (FY_*) columns.
//
// Parameters:
//   StartDate            - first date to include
//   EndDate              - last date to include
//   FiscalYearStartMonth - month (1–12) financial year starts (e.g. 4 = April)

(StartDate as date, EndDate as date, FiscalYearStartMonth as number) as table =>
let
    // Ensure dates are in the right order
    StartDateFixed = Date.From(StartDate),
    EndDateFixed   = Date.From(EndDate),

    DayCount = Duration.Days(EndDateFixed - StartDateFixed) + 1,
    Dates    = List.Dates(StartDateFixed, DayCount, #duration(1, 0, 0, 0)),

    BaseTable =
        Table.FromList(
            Dates,
            Splitter.SplitByNothing(),
            {"Date"}
        ),

    #"Typed Date" =
        Table.TransformColumnTypes(
            BaseTable,
            {{"Date", type date}}
        ),

    // =====================================
    // Calendar (Gregorian) attributes
    // =====================================

    #"Added DateKey" =
        Table.AddColumn(
            #"Typed Date",
            "DateKey",
            each Date.Year([Date]) * 10000
               + Date.Month([Date]) * 100
               + Date.Day([Date]),
            Int64.Type
        ),

    #"Added Calendar Year" =
        Table.AddColumn(
            #"Added DateKey",
            "Calendar Year",
            each Date.Year([Date]),
            Int64.Type
        ),

    #"Added Calendar Month Number" =
        Table.AddColumn(
            #"Added Calendar Year",
            "Calendar Month Number",
            each Date.Month([Date]),
            Int64.Type
        ),

    #"Added Calendar Month" =
        Table.AddColumn(
            #"Added Calendar Month Number",
            "Calendar Month",
            each Date.ToText([Date], "MMMM"),
            type text
        ),

    #"Added Calendar Year-Month" =
        Table.AddColumn(
            #"Added Calendar Month",
            "Calendar Year-Month",
            each
                Text.From([Calendar Year])
                & "-"
                & Text.PadStart(Text.From([Calendar Month Number]), 2, "0"),
            type text
        ),

    #"Added Calendar Quarter Number" =
        Table.AddColumn(
            #"Added Calendar Year-Month",
            "Calendar Quarter Number",
            each Date.QuarterOfYear([Date]),
            Int64.Type
        ),

    #"Added Calendar Quarter" =
        Table.AddColumn(
            #"Added Calendar Quarter Number",
            "Calendar Quarter",
            each
                "Q"
                & Text.From([Calendar Quarter Number])
                & " "
                & Text.From([Calendar Year]),
            type text
        ),

    #"Added Calendar Week Number" =
        Table.AddColumn(
            #"Added Calendar Quarter",
            "Calendar Week Number",
            each Date.WeekOfYear([Date], Day.Monday),
            Int64.Type
        ),

    #"Added Day of Month" =
        Table.AddColumn(
            #"Added Calendar Week Number",
            "Day of Month",
            each Date.Day([Date]),
            Int64.Type
        ),

    #"Added Day of Week Number" =
        Table.AddColumn(
            #"Added Day of Month",
            "Day of Week Number",
            each Date.DayOfWeek([Date], Day.Monday) + 1,   // Monday = 1
            Int64.Type
        ),

    #"Added Day of Week" =
        Table.AddColumn(
            #"Added Day of Week Number",
            "Day of Week",
            each Date.ToText([Date], "dddd"),
            type text
        ),

    #"Added Is Weekend" =
        Table.AddColumn(
            #"Added Day of Week",
            "Is Weekend",
            each [Day of Week Number] >= 6,
            type logical
        ),

    // =====================================
    // Fiscal / Financial attributes (FY_*)
    // =====================================

    // Financial year number (e.g. 2024 for 2024/25)
    #"Added FY_YearNumber" =
        Table.AddColumn(
            #"Added Is Weekend",
            "FY_YearNumber",
            each
                let
                    year = Date.Year([Date])
                in
                    if Date.Month([Date]) < FiscalYearStartMonth then
                        year - 1
                    else
                        year,
            Int64.Type
        ),

    // Short label (e.g. 24-25)
    #"Added FY_YearShort" =
        Table.AddColumn(
            #"Added FY_YearNumber",
            "FY_YearShort",
            each
                let
                    fy      = [FY_YearNumber],
                    startYY = Text.PadStart(Text.End(Text.From(fy), 2), 2, "0"),
                    endYY   = Text.PadStart(Text.End(Text.From(fy + 1), 2), 2, "0")
                in
                    startYY & "-" & endYY,
            type text
        ),

    // Long label (e.g. 2024/25)
    #"Added FY_YearLong" =
        Table.AddColumn(
            #"Added FY_YearShort",
            "FY_YearLong",
            each
                let
                    fy    = [FY_YearNumber],
                    endYY = Text.PadStart(Text.End(Text.From(fy + 1), 2), 2, "0")
                in
                    Text.From(fy) & "/" & endYY,
            type text
        ),

    // Fiscal period number (1–12) based on FiscalYearStartMonth
    #"Added FY_PeriodNumber" =
        Table.AddColumn(
            #"Added FY_YearLong",
            "FY_PeriodNumber",
            each
                let
                    m = Date.Month([Date])
                in
                    if m >= FiscalYearStartMonth then
                        m - FiscalYearStartMonth + 1
                    else
                        m + (12 - FiscalYearStartMonth + 1),
            Int64.Type
        ),

    // Simple period label (e.g. P01, P02, ...)
    #"Added FY_PeriodLabel" =
        Table.AddColumn(
            #"Added FY_PeriodNumber",
            "FY_PeriodLabel",
            each "P" & Text.PadStart(Text.From([FY_PeriodNumber]), 2, "0"),
            type text
        ),

    // Fiscal quarter number (1–4) based on FY period
    #"Added FY_QuarterNumber" =
        Table.AddColumn(
            #"Added FY_PeriodLabel",
            "FY_QuarterNumber",
            each Number.RoundUp([FY_PeriodNumber] / 3),
            Int64.Type
        ),

    // Simple quarter label (e.g. 24-25 Q1)
    #"Added FY_QuarterShort" =
        Table.AddColumn(
            #"Added FY_QuarterNumber",
            "FY_QuarterShort",
            each [FY_YearShort] & " Q" & Text.From([FY_QuarterNumber]),
            type text
        ),

    // Final column order (tweak to taste)
    Final =
        Table.ReorderColumns(
            #"Added FY_QuarterShort",
            {
                "Date",
                "DateKey",

                "Calendar Year",
                "Calendar Month Number",
                "Calendar Month",
                "Calendar Year-Month",
                "Calendar Quarter Number",
                "Calendar Quarter",
                "Calendar Week Number",
                "Day of Month",
                "Day of Week Number",
                "Day of Week",
                "Is Weekend",

                "FY_YearNumber",
                "FY_YearShort",
                "FY_YearLong",
                "FY_PeriodNumber",
                "FY_PeriodLabel",
                "FY_QuarterNumber",
                "FY_QuarterShort"
            }
        )
in
    Final
