// fnCalendar
// Dynamic financial calendar with UI-friendly parameters.
// - StartDate: earliest date to include (fixed, e.g. first FY you care about)
// - FiscalYearStartMonth: month (1–12) the financial year starts (e.g. 4 = April)
// - YearsAhead: how many FULL financial years beyond the *current* FY to include

(StartDate as date, FiscalYearStartMonth as number, YearsAhead as number) as table =>
let
    Today = Date.From(DateTimeZone.UtcNow()),

    // Work out current financial year number (e.g. 2024 for 2024/25)
    CurrentFY =
        let
            y = Date.Year(Today)
        in
            if Date.Month(Today) < FiscalYearStartMonth then
                y - 1
            else
                y,

    EndFY   = CurrentFY + YearsAhead,
    EndDate = Date.AddDays(#date(EndFY + 1, FiscalYearStartMonth, 1), -1),

    Result = fnCalendarCore(StartDate, EndDate, FiscalYearStartMonth)
in
    Result
