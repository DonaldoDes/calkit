# calkit

macOS calendar CLI. Every provider, zero config.

## Description

Swift CLI for macOS using EventKit to read and write calendars and reminders. Aggregates all providers (iCloud, Google, Office 365, Fastmail, CalDAV) through the accounts already configured in System Settings -- no extra authentication required.

## Requirements

- macOS Catalina (10.15)+
- Xcode Command Line Tools

## Installation

```bash
git clone https://github.com/DonaldoDes/calkit
cd calkit
make build
make install   # copies to /usr/local/bin
```

On first launch, macOS will prompt for Calendars access. Allow it.

## Usage

```
calkit -- CLI macOS pour gerer calendriers et rappels (tous fournisseurs, zero config)

Usage: calkit <domaine> <commande> [options]

Domaines:
  calendars   Lister les calendriers disponibles et leur fournisseur
  events      Consulter, rechercher, creer, modifier et supprimer des evenements
  reminders   Gerer les rappels (listes, consultation, CRUD)

Options globales:
  --help, -h  Afficher l'aide

Exemples:
  calkit calendars list
  calkit events today
  calkit events create "Reunion" --start 2026-03-20T14:00:00 --end 2026-03-20T15:00:00
  calkit --help

Lancez 'calkit <domaine> --help' pour l'aide detaillee d'un domaine.
```

### Events

```bash
# Today's events
calkit events today

# Events over a date range
calkit events range 2026-03-20 2026-03-27

# Search events by keyword
calkit events search "standup"

# Create an event
calkit events create "Standup" --start 2026-03-20T09:00:00 --end 2026-03-20T09:30:00

# Update an event
calkit events update <event-id> --title "New Title"

# Delete an event
calkit events delete <event-id>
```

### Calendars

```bash
# List all calendars with their source provider
calkit calendars list
```

## LLM Usage

calkit works well as a tool for LLMs with Bash access. Add this to your `CLAUDE.md` (or equivalent):

```
`calkit` is installed -- macOS CLI to manage calendars and reminders (all providers) via EventKit. Run `calkit --help` for available commands.
```

## JSON Output

All read commands support `--json` for machine-readable output:

```bash
calkit events today --json
calkit calendars list --json
```

## Status

- **M1 (Calendar)**: Done -- calendars list, events CRUD, search, range queries
- **M2 (Reminders)**: Planned -- reminders lists, CRUD, completion tracking
