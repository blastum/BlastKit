# TIPS Calendar Generation Plan

## Overview

Create a general-purpose command-line application that generates an iCal (`.ics`) calendar file from TIPS account holdings. The calendar will contain events for each payout date with detailed information about payouts organized by account and CUSIP. The tool will be designed to run periodically in GitHub Actions and publish the calendar to GitHub Pages.

## Objectives

1. Generate iCal calendar events for all TIPS payout dates from input accounts
2. Include comprehensive payout details in each event (by account, by CUSIP)
3. Mark unadjusted payouts with asterisks (*) to indicate estimates
4. Support command-line interface for flexible input (CSV files, JSON, etc.)
5. Designed for automated runs in GitHub Actions with GitHub Pages publishing

## Data Requirements

### Input Data

- **TIPS Accounts**: Array of `TIPSAccount` objects (already supported infrastructure)
  - Can be loaded from CSV files via `CSVLoader`
  - Can be provided via JSON or other formats
  - Contains holdings with CUSIP, purchase date, and count

### Required Infrastructure (Already Available)

- ✅ `TIPSService`: Fetches summary and detail data from Treasury API
- ✅ Payout calculation logic: `calculatePayouts()`, `calculateAllPayouts()`
- ✅ Aggregation logic: `aggregatePayouts()` → `PayoutCalendar`
- ✅ `PayoutCalendar` structure with per-account and aggregate payouts
- ✅ `AccountPayout` and `AggregatePayout` structures

### Output Format

**iCal (.ics) file** with events following RFC 5545 specification:
- One event per payout date
- UID based on payout date + unique constant
- DTSTART/DTEND as full dates
- DTSTAMP marking generation time
- SUMMARY: "TIPS: $XXXX" or "TIPS: $XXXX*" (asterisk for unadjusted)
- DESCRIPTION: Formatted text with account-by-account breakdown

## iCal Event Specification

### Required Fields

1. **UID** (Unique Identifier)
   - Format: `{payout_date_YYYYMMDD}@tipscalendarkit.{unique_domain}`
   - Example: `20250715@tipscalendarkit.github.io`
   - Must be globally unique for calendar system compatibility

2. **DTSTART**
   - Format: `DTSTART;VALUE=DATE:YYYYMMDD`
   - Full date of the payout (no time component)
   - Example: `DTSTART;VALUE=DATE:20250715`

3. **DTEND**
   - Format: `DTEND;VALUE=DATE:YYYYMMDD`
   - Same as DTSTART (all-day event, so end is next day)
   - Example: `DTEND;VALUE=DATE:20250716`

4. **DTSTAMP**
   - Format: `DTSTAMP:YYYYMMDDTHHMMSSZ` (UTC)
   - Timestamp when calendar was generated
   - Example: `DTSTAMP:20250115T120000Z`

5. **SUMMARY**
   - Format: `TIPS: $XXXX` or `TIPS: $XXXX*`
   - Total aggregate payout amount for that date
   - Asterisk (*) appended if any payout is unadjusted (no index ratio available)
   - Example: `TIPS: $12,345.67` or `TIPS: $12,345.67*`

6. **DESCRIPTION**
   - Multi-line text describing all payouts for that date
   - Organized by account, then by CUSIP within each account
   - Format:
     ```
     Account: [Account Name] - $X,XXX.XX[*]
     [Account Name]:
       • CUSIP: XXXXXX, Count: XX, Payout: $X,XXX.XX[*]
       • CUSIP: XXXXXX, Count: XX, Payout: $X,XXX.XX[*]
     
     Account: [Account Name] - $X,XXX.XX[*]
     ...
     
     Aggregate Total: $XX,XXX.XX[*]
     ```
   - Asterisk indicates unadjusted amounts (no index ratio)

### Optional Fields

- **SEQUENCE**: Increment on updates (for future versioning)
- **LAST-MODIFIED**: Same as DTSTAMP (for cache management)
- **CREATED**: Same as DTSTAMP (when event was created)

## Process Flow

### Step 1: Accept Input ✅ (Infrastructure Exists)

1. Command-line arguments:
   - Multiple `--input` or `-i` flags for input files (CSV or JSON)
   - Format auto-detected from file extension (`.csv`, `.json`)
   - Each file can contain one or more accounts
2. Load `TIPSAccount` objects from all input files:
   - For CSV files: Parse holdings and create account (use filename or account name from file)
   - For JSON files: Parse array of `TIPSAccount` objects
   - Combine accounts from all files into single list
3. Create `TIPSService` instance and add all accounts

### Step 2: Calculate All Payouts ✅ (Infrastructure Exists)

1. Extract unique CUSIPs from all accounts
2. Fetch `TIPSSummary` data for each CUSIP
3. Generate payout date schedules for each holding
4. Fetch `TIPSDetail` (index ratio) data for payout dates
5. Calculate all payouts using `calculateAllPayouts()`
6. Aggregate payouts using `aggregatePayouts()` → `PayoutCalendar`

### Step 3: Generate iCal Calendar Events

For each `AggregatePayout` in `PayoutCalendar`:

1. **Generate UID**:
   ```swift
   let uid = "\(dateString)@tipscalendarkit.github.io"
   ```

2. **Format DTSTART/DTEND**:
   ```swift
   // YYYYMMDD format for all-day events
   let dtStart = formatDateAsICal(date)
   let dtEnd = formatDateAsICal(date.addingTimeInterval(86400)) // Next day
   ```

3. **Format DTSTAMP**:
   ```swift
   let dtStamp = formatDateTimeAsICal(Date()) // Current time in UTC
   ```

4. **Format SUMMARY**:
   ```swift
   let summary = formatSummary(aggregatePayout)
   // "TIPS: $12,345.67" or "TIPS: $12,345.67*"
   ```

5. **Format DESCRIPTION**:
   ```swift
   let description = formatDescription(aggregatePayout)
   // Account-by-account, CUSIP-by-CUSIP breakdown
   ```

6. **Write iCal Event**:
   ```
   BEGIN:VEVENT
   UID:{uid}
   DTSTART;VALUE=DATE:{dtStart}
   DTEND;VALUE=DATE:{dtEnd}
   DTSTAMP:{dtStamp}
   SUMMARY:{summary}
   DESCRIPTION:{description}
   SEQUENCE:0
   END:VEVENT
   ```

### Step 4: Assemble Complete iCal File

1. **Write iCal Header**:
   ```
   BEGIN:VCALENDAR
   VERSION:2.0
   PRODID:-//TIPS Calendar Kit//TIPS Payout Calendar//EN
   CALSCALE:GREGORIAN
   METHOD:PUBLISH
   ```

2. **Write All Events** (from Step 3)

3. **Write iCal Footer**:
   ```
   END:VCALENDAR
   ```

### Step 5: Output Calendar File

1. Write iCal content:
   - If `--output` specified: write to file path
   - If `--output` not specified: write to **stdout**
   - This allows flexible usage: pipe to file, redirect, process further, etc.
2. Validate iCal format (optional but recommended)

## Implementation Tasks

### Phase 1: Core Calendar Generation Module

1. **Create `ICalEvent` struct** (in TIPSCalendarKit):
   ```swift
   struct ICalEvent {
       let uid: String
       let dtStart: String
       let dtEnd: String
       let dtStamp: String
       let summary: String
       let description: String
   }
   ```

2. **Create `ICalCalendar` struct**:
   ```swift
   struct ICalCalendar {
       let events: [ICalEvent]
       func render() -> String
   }
   ```

3. **Date Formatting Utilities**:
   - `formatDateAsICal(Date) -> String` (YYYYMMDD)
   - `formatDateTimeAsICal(Date) -> String` (YYYYMMDDTHHMMSSZ, UTC)
   - Handle timezone conversion to UTC

4. **Amount Formatting Utilities**:
   - `formatCurrency(Double) -> String` ($X,XXX.XX)
   - `formatSummary(AggregatePayout) -> String` (with asterisk logic)
   - `formatDescription(AggregatePayout) -> String` (multi-line, escaped)

### Phase 2: Calendar Generator Service

1. **Create `CalendarGenerator` class**:
   ```swift
   class CalendarGenerator {
       func generate(from payoutCalendar: PayoutCalendar) -> ICalCalendar
       func formatEvent(from aggregatePayout: AggregatePayout, generatedAt: Date) -> ICalEvent
   }
   ```

2. **UID Generation Logic**:
   - Domain constant: `tipscalendarkit.github.io` (or configurable)
   - Format: `{date}@{domain}`
   - Ensure uniqueness per payout date

3. **Description Formatting**:
   - Iterate through `AggregatePayout.accountPayouts`
   - For each `AccountPayout`, list individual `TIPSPayout` records
   - Group by CUSIP, show count and total per CUSIP
   - Include account totals with asterisk if any unadjusted
   - Include aggregate total at end

### Phase 3: Command-Line Application

1. **Create executable target** in `Package.swift`:
   ```swift
   .executableTarget(
       name: "TIPSCalendarGenerator",
       dependencies: ["TIPSCalendarKit", "TIPSKit"]
   )
   ```

2. **Main entry point** (`main.swift` or `@main`):
   - Parse command-line arguments:
     - `--input` or `-i`: Input file path(s) - **can be specified multiple times**
       - Example: `--input ira.csv --input roth.csv`
     - `--output` or `-o`: Output `.ics` file path (optional)
       - If not specified: write to **stdout**
       - If specified: write to file
       - Example: `swift run TIPSCalendarGenerator --input ira.csv > calendar.ics`
   - **Auto-detect format from file extension**:
     - `.csv` → CSV format (CUSIP, Count, [PurchaseDate])
     - `.json` → JSON format (array of TIPSAccount objects)
     - Error if extension not recognized or format cannot be determined
   - Load accounts from all input files:
     - Process each input file based on its extension
     - Combine all accounts into single list
     - Add all accounts to TIPSService
   - Run payout calculation pipeline
   - Generate calendar
   - Write output (to file if `--output` specified, otherwise stdout)

3. **Input File Loading Logic**:
   - **CSV files**: 
     - Format: `CUSIP,Count[,PurchaseDate]`
     - Each CSV file becomes one account (account name from filename or specified)
     - If no purchase date column, require purchase date via argument or config
   - **JSON files**:
     - Format: Array of `TIPSAccount` objects or single `TIPSAccount`
     - Can contain multiple accounts per file
   - Combine all accounts from all files into single list

4. **Error Handling**:
   - Handle file I/O errors
   - Handle unsupported file extensions
   - Handle API fetch errors
   - Handle calculation errors
   - Provide user-friendly error messages

### Phase 4: GitHub Actions Integration

1. **Create GitHub Actions workflow** (`.github/workflows/generate-calendar.yml`):
   ```yaml
   name: Generate TIPS Calendar
   on:
     schedule:
       - cron: '0 0 * * 0'  # Weekly on Sunday
     workflow_dispatch:  # Manual trigger
   jobs:
     generate:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - name: Setup Swift
           uses: swift-actions/setup-swift@v1
         - name: Generate Calendar
           run: swift run TIPSCalendarGenerator --input ira.csv --input roth.csv > calendar.ics
         - name: Publish to GitHub Pages
           # Commit calendar.ics to gh-pages branch or deploy
   ```

2. **GitHub Pages Publishing**:
   - Option 1: Commit `.ics` file to `gh-pages` branch
   - Option 2: Use GitHub Pages action to deploy
   - Configure calendar file to be accessible via HTTPS URL

## Data Structures

### ICalEvent

```swift
public struct ICalEvent {
    public let uid: String
    public let dtStart: String          // YYYYMMDD format
    public let dtEnd: String            // YYYYMMDD format
    public let dtStamp: String          // YYYYMMDDTHHMMSSZ format (UTC)
    public let summary: String
    public let description: String
    public let sequence: Int
    
    public func render() -> String {
        // Generate iCal VEVENT block
    }
}
```

### ICalCalendar

```swift
public struct ICalCalendar {
    public let events: [ICalEvent]
    public let prodId: String
    public let version: String = "2.0"
    public let calScale: String = "GREGORIAN"
    public let method: String = "PUBLISH"
    
    public func render() -> String {
        // Generate complete .ics file content
    }
}
```

### CalendarGenerator

```swift
public class CalendarGenerator {
    public let uidDomain: String
    
    public init(uidDomain: String = "tipscalendarkit.github.io") {
        self.uidDomain = uidDomain
    }
    
    public func generate(
        from payoutCalendar: PayoutCalendar,
        generatedAt: Date = Date()
    ) -> ICalCalendar {
        // Convert PayoutCalendar to ICalCalendar
    }
    
    private func formatEvent(
        from aggregatePayout: AggregatePayout,
        generatedAt: Date
    ) -> ICalEvent {
        // Convert AggregatePayout to ICalEvent
    }
    
    private func formatDescription(
        from aggregatePayout: AggregatePayout
    ) -> String {
        // Generate multi-line description with account/CUSIP breakdown
    }
    
    private func formatSummary(
        from aggregatePayout: AggregatePayout
    ) -> String {
        // "TIPS: $X,XXX.XX" or "TIPS: $X,XXX.XX*"
    }
}
```

## Formatting Details

### Summary Format

- **Definitive** (all payouts adjusted): `TIPS: $12,345.67`
- **Estimated** (any unadjusted payouts): `TIPS: $12,345.67*`
- Format: `"TIPS: \(formattedAmount)\(hasUnadjusted ? "*" : "")"`

### Description Format

Example output:
```
Account: IRA Ladder - $8,234.56
IRA Ladder:
  • CUSIP: 912828ZP8, Count: 45, Payout: $2,812.50
  • CUSIP: 91282CDH4, Count: 30, Payout: $5,422.06

Account: Existing Roth TIPS Ladder - $4,111.11*
Existing Roth TIPS Ladder:
  • CUSIP: 91282CCM1, Count: 78, Payout: $4,111.11*

Aggregate Total: $12,345.67*
```

**Key Points**:
- Account summary line: `Account: {name} - ${total}[*]`
- Per-CUSIP lines with indentation (bullet points)
- Aggregate total at end with asterisk if any account has unadjusted
- Asterisk indicates unadjusted (no index ratio) amounts
- All amounts formatted as currency ($X,XXX.XX)

### iCal Escaping Rules

- Escape commas, semicolons, backslashes in text fields
- Replace `\n` with `\\n` for line breaks in DESCRIPTION
- DESCRIPTION field values may be folded (wrapped at 75 characters)

## Edge Cases

1. **Empty PayoutCalendar**: Generate empty but valid iCal file
2. **No adjusted payouts**: All events marked with asterisk
3. **Multiple payouts same CUSIP same account**: Aggregate in description
4. **Date formatting**: Ensure timezone handling (UTC for DTSTAMP, dates only for DTSTART/DTEND)
5. **Special characters in account names**: Escape for iCal format
6. **Very large descriptions**: iCal line folding (75 chars), but aim for reasonable length
7. **Future payouts beyond Treasury data**: All marked as unadjusted (expected)

## Future Considerations

1. **Calendar Updates**: Increment SEQUENCE on regeneration, handle UID stability
2. **Multiple Calendars**: Support per-account calendars vs. aggregate calendar
3. **Reminder/Alarm Settings**: Optional alarm reminders before payout dates
4. **Calendar Metadata**: Add CALNAME, CALDESC properties
5. **Recurrence Rules**: Could use RRULE for semi-annual pattern (but dates vary by CUSIP, so individual events preferred)
6. **Caching Strategy**: Cache API responses for faster regeneration
7. **Validation**: iCal format validation before writing file
8. **Web Subscription**: Make calendar subscribable via webcal:// URL

## Success Criteria

1. Generate valid iCal (.ics) file from TIPS account input
2. All payout dates represented as calendar events
3. Accurate amount formatting with asterisk for unadjusted amounts
4. Comprehensive description with account and CUSIP breakdown
5. Globally unique UIDs per payout date
6. Command-line tool works with CSV and potentially JSON input
7. Calendar file can be imported into calendar applications (iCal, Google Calendar, etc.)
8. GitHub Actions workflow successfully generates and publishes calendar
9. Published calendar accessible via HTTPS URL for subscription

## File Structure

```
Sources/TIPSCalendarKit/
  - CSVLoader.swift (existing)
  - ICalEvent.swift (new)
  - ICalCalendar.swift (new)
  - CalendarGenerator.swift (new)
  - DateFormatter+ICal.swift (new)
  - CurrencyFormatter.swift (new)

Sources/TIPSCalendarGenerator/ (new executable target)
  - main.swift

.github/workflows/
  - generate-calendar.yml (new)
```

## Testing Considerations

1. **Unit Tests**:
   - Date formatting utilities
   - Currency formatting
   - UID generation
   - iCal event rendering
   - Description formatting

2. **Integration Tests**:
   - End-to-end: CSV input → iCal output
   - Validate generated .ics file with iCal parser library or online validator

3. **Sample Data**:
   - Use existing CSV files (IRALadder.csv, RothLadder.csv)
   - Verify calendar events match expected payouts
   - Test with both adjusted and unadjusted payouts

## Implementation Order

1. ✅ **Phase 1**: Core calendar generation module (ICalEvent, ICalCalendar, formatters) - COMPLETE
2. ✅ **Phase 2**: CalendarGenerator service (conversion from PayoutCalendar) - COMPLETE
3. ✅ **Phase 3**: Command-line application (main.swift, argument parsing) - COMPLETE
4. ✅ **Phase 4**: GitHub Actions workflow and publishing setup - COMPLETE

**Note**: To enable GitHub Pages deployment:
- Go to repository Settings → Pages
- Select "GitHub Actions" as the source
- The workflow will deploy automatically on schedule (weekly Sundays) or manual trigger

