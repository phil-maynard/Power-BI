let
    Source = fnCalendar(#date(2014, 4, 1), 4, 1),

    // Friendly "Financial" naming
    Calendar_Financial =
        Table.RenameColumns(
            Source,
            {
                {"FY_YearNumber",   "Financial Year Number"},
                {"FY_YearShort",    "Financial Year"},
                {"FY_YearLong",     "Financial Year Long Name"},
                {"FY_PeriodNumber", "Financial Period Number"},
                {"FY_PeriodLabel",  "Financial Period"},
                {"FY_QuarterNumber","Financial Quarter Number"},
                {"FY_QuarterShort", "Financial Quarter"}
            }
        )
in
    Calendar_Financial
