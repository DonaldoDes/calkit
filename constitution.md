# calkit Constitution

> EventKit CLI for LLM-driven calendar and reminder management on macOS.

---

## 1. Core Principles (Immutable)

These principles are non-negotiable. Any change requires an ADR with explicit justification.

1. **EventKit Only** -- All calendar and reminder access goes through Apple's EventKit framework. No third-party calendar APIs, no direct CalDAV implementation, no network calls. EventKit handles provider abstraction (Gmail, Office 365, iCloud, Fastmail, CalDAV) via System Settings > Internet Accounts.

2. **Zero External Dependencies** -- No Swift Package Manager, no CocoaPods, no Carthage, no swift-argument-parser. The only allowed frameworks are Apple system frameworks (EventKit, Foundation). The binary must compile with `swiftc` alone.

3. **Single Autonomous Binary** -- The deliverable is one static binary (~1 MB), copyable to any macOS machine. No runtime dependencies, no config files, no data directories. First launch triggers the system permission dialog for Calendar/Reminders access.

4. **LLM-First CLI Design** -- The help system is semantic, hierarchical, and example-rich. Every command and subcommand produces help text that an LLM can parse to understand capabilities, arguments, and usage patterns without external documentation.

5. **Read-Write Symmetry** -- calkit is not read-only. It creates, updates, and deletes events and reminders. Write operations require explicit identifiers and produce confirmation output.

---

## 2. Stack & Constraints

| Aspect | Value |
|--------|-------|
| Language | Swift (system version shipped with Xcode CLT) |
| Minimum target | macOS 10.15 Catalina |
| Frameworks | EventKit, Foundation |
| Build tool | `swiftc` via Xcode Command Line Tools |
| Package manager | None (forbidden) |
| Binary type | Single executable, no dylibs |
| Permissions | Calendar + Reminders (granted at first launch via system dialog) |
| Deployment | Copy binary to target machine, run once to trigger permission prompt |

### Swift version policy

Use the Swift version installed with the current Xcode Command Line Tools. No version pinning. Avoid language features that require Swift 5.9+ unless macOS Catalina support is verified.

---

## 3. Project Structure

```
calkit/
  constitution.md          # This file
  Makefile                 # Build, clean, install targets
  Sources/
    calkit/
      main.swift           # Entry point, argument routing
      CLI/
        ArgumentParser.swift   # Hand-rolled argument parsing
        HelpGenerator.swift    # Semantic help text generation
        CommandRouter.swift    # Routes parsed args to command handlers
      Commands/
        CalendarCommands.swift # calendars list
        EventCommands.swift    # events today|range|search|create|update|delete
        ReminderCommands.swift # reminders lists|list|create|complete|delete
      Services/
        CalendarService.swift  # EventKit EKEventStore calendar operations
        ReminderService.swift  # EventKit EKEventStore reminder operations
        PermissionService.swift # Permission request and status checking
      Models/
        CalendarModel.swift    # Internal calendar representation
        EventModel.swift       # Internal event representation
        ReminderModel.swift    # Internal reminder representation
        RecurrenceRule.swift   # Recurrence rule parsing and creation
      Output/
        JSONFormatter.swift    # --json output formatting
        TextFormatter.swift    # Human-readable default output
        ErrorFormatter.swift   # Structured error messages with exit codes
```

### File responsibility rule

One file = one responsibility. No file exceeds 300 lines. If it does, split by sub-responsibility.

---

## 4. CLI Design Principles

### 4.1 Command hierarchy

```
calkit <domain> <action> [arguments] [options]
```

Domains: `calendars`, `events`, `reminders`.
Each domain has its own set of actions. No global actions exist outside domains.

### 4.2 Help system

Every level produces help:

```
calkit --help              # Top-level: lists domains with descriptions
calkit events --help       # Domain: lists actions with descriptions
calkit events create --help # Action: full usage, arguments, options, examples
```

Help text follows this structure:
- **Usage line** -- exact syntax
- **Description** -- one sentence explaining what the command does
- **Arguments** -- required positional args with types
- **Options** -- optional flags with defaults and types
- **Examples** -- 2-3 concrete examples with realistic data

### 4.3 Date/time formats

- Date input: `YYYY-MM-DD` (e.g., `2026-03-16`)
- DateTime input: `YYYY-MM-DDTHH:MM` (e.g., `2026-03-16T14:30`)
- Shorthand: `today`, `tomorrow`, `yesterday` accepted where a date is expected
- Output: ISO 8601 in JSON mode, localized human-readable in text mode

### 4.4 Output modes

- **Default (text)**: Human-readable, aligned columns, no trailing whitespace
- **JSON (`--json`)**: Machine-parseable, one JSON object per line for lists, single object for single items. Always valid JSON. No extra text outside the JSON structure.

### 4.5 Identifier format

Events and reminders are referenced by their EventKit `calendarItemIdentifier`. This is a stable UUID string. Commands that return items always include the identifier. Commands that modify items accept the identifier as the first positional argument.

---

## 5. Code Conventions

### 5.1 Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Types, protocols, enums | PascalCase | `EventCommand`, `OutputFormat` |
| Functions, methods, variables | camelCase | `fetchEvents`, `startDate` |
| Constants | camelCase | `defaultCalendarName` |
| Enum cases | camelCase | `.thisEvent`, `.futureEvents` |
| Files | PascalCase matching primary type | `EventCommands.swift` |

### 5.2 Error handling

- All EventKit operations use `do/catch` blocks
- Errors produce structured messages to stderr: `calkit: error: <message>`
- Never crash. Never `fatalError()` in production paths. Never force-unwrap optionals from external data.

### 5.3 Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (invalid arguments, unknown command) |
| 2 | Permission denied (Calendar or Reminders access not granted) |
| 3 | Not found (calendar, event, or reminder ID does not exist) |
| 4 | EventKit operation failed (save/delete error from the store) |

### 5.4 Async/sync pattern

EventKit requires the main run loop for permission callbacks. Use `DispatchSemaphore` or `RunLoop` to bridge async EventKit APIs into the synchronous CLI flow. No async/await unless macOS 12+ only features are needed (and they are not, given Catalina target).

### 5.5 Permission flow

1. Check current authorization status for Calendar and Reminders
2. If not determined, request access and wait for response
3. If denied, print a clear message explaining how to grant access via System Settings, then exit with code 2
4. Never proceed with EventKit operations without confirmed authorization

---

## 6. Commands

### Build

```bash
swiftc -o calkit \
  Sources/calkit/main.swift \
  Sources/calkit/CLI/*.swift \
  Sources/calkit/Commands/*.swift \
  Sources/calkit/Services/*.swift \
  Sources/calkit/Models/*.swift \
  Sources/calkit/Output/*.swift \
  -framework EventKit \
  -framework Foundation \
  -O
```

### Clean

```bash
rm -f calkit
```

### Install (local)

```bash
cp calkit /usr/local/bin/calkit
```

### Verify

```bash
./calkit --help
./calkit calendars list
./calkit events today
./calkit reminders lists
```

---

## 7. Quality Gates

### Compilation

- `swiftc` must produce zero warnings. Treat warnings as errors during development.
- Build must succeed on a clean machine with only Xcode Command Line Tools installed.

### Static analysis

- Run `swiftlint` if available on the machine. Not a hard requirement (no external deps rule), but recommended during development.
- No force unwraps (`!`) on optionals from external sources (EventKit results, user input).
- No `print()` to stdout for errors -- errors go to stderr via `FileHandle.standardError`.

### Manual testing checklist

Before any release, verify these commands produce correct output:

- [ ] `calkit --help` -- displays full help
- [ ] `calkit calendars list` -- lists all visible calendars
- [ ] `calkit calendars list --json` -- valid JSON output
- [ ] `calkit events today` -- shows today's events
- [ ] `calkit events create "Test" --start 2026-03-16T10:00 --end 2026-03-16T11:00` -- creates event
- [ ] `calkit events delete <id>` -- deletes the created event
- [ ] `calkit reminders lists` -- lists all reminder lists
- [ ] `calkit reminders create "Test task" --list Reminders` -- creates reminder
- [ ] `calkit reminders complete <id>` -- completes the reminder
- [ ] `calkit reminders delete <id>` -- deletes the reminder
- [ ] Invalid command produces helpful error message and exit code 1
- [ ] Running without Calendar permission produces clear message and exit code 2

### Output validation

- JSON mode: every output must be valid JSON (parseable by `jq .`)
- Text mode: no trailing whitespace, consistent column alignment
- Error messages: always prefixed with `calkit: error:`, always to stderr

---

## 8. Governance

### Adding external dependencies

**Forbidden.** If a use case seems to require an external dependency, an ADR must be written explaining:
1. Why the system frameworks are insufficient
2. What the dependency would provide
3. The impact on binary size, deployment, and the zero-deps principle

The ADR must be approved before any implementation. The expectation is that the answer is always "find a way with Foundation/EventKit".

### Adding new commands

Every new command must:
1. Follow the existing `calkit <domain> <action>` hierarchy
2. Include complete `--help` output with examples
3. Be added to the manual testing checklist in section 7
4. Be documented in the CLI reference section of this constitution

### Modifying exit codes

Exit codes are part of the public API (LLMs rely on them). Adding new exit codes requires updating this constitution. Changing existing codes is a breaking change.

### Modifying output format

JSON output structure is part of the public API. Field additions are non-breaking. Field removals or renames are breaking changes requiring a version bump and ADR.

### Version policy

No SemVer for now. The binary has no version flag until the CLI is stable enough to warrant one. When added, it will follow `calkit --version` outputting `calkit X.Y.Z`.
