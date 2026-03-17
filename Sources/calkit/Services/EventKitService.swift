import EventKit
import Foundation

/// Errors specific to event creation.
enum CreateEventError: Error {
    case calendarNotFound(String)
    case ambiguousCalendar(String)
}

/// Errors specific to event update.
enum UpdateEventError: Error {
    case notFound(String)
}

/// Errors specific to event deletion.
enum DeleteEventError: Error {
    case notFound(String)
}

class EventKitService {
    static let shared = EventKitService()

    private let store = EKEventStore()

    private init() {}

    /// Request calendar access. Calls completion with true if granted, false otherwise.
    func requestAccess(completion: @escaping (Bool) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess:
            completion(true)
        case .notDetermined:
            if #available(macOS 14.0, *) {
                store.requestFullAccessToEvents { granted, _ in
                    completion(granted)
                }
            } else {
                store.requestAccess(to: .event) { granted, _ in
                    completion(granted)
                }
            }
        default:
            // denied, restricted, or writeOnly
            completion(false)
        }
    }

    /// Request access synchronously using a semaphore. Returns true if granted.
    func requestAccessSync() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var granted = false
        requestAccess { result in
            granted = result
            semaphore.signal()
        }
        semaphore.wait()
        return granted
    }

    /// Fetch all calendars mapped to CKCalendar.
    /// Source format: "account (type)" using source.title (account name) + sourceType.
    /// When source.title matches the type name (e.g. "iCloud"), no duplication: just "iCloud".
    func fetchCalendars() -> [CKCalendar] {
        let ekCalendars = store.calendars(for: .event)
        return ekCalendars.map { cal in
            CKCalendar(
                id: cal.calendarIdentifier,
                title: cal.title,
                source: formatSource(title: cal.source.title, type: cal.source.sourceType),
                color: cgColorToHex(cal.cgColor)
            )
        }
    }

    /// Build the source display string: "account (type)" or just "title" if redundant.
    private func formatSource(title: String, type: EKSourceType) -> String {
        let typeName = sourceTypeName(type)
        // If the title is the same as the type name, no need to duplicate
        if title == typeName {
            return title
        }
        return "\(title) (\(typeName))"
    }

    /// Convert EKSourceType to human-readable string.
    private func sourceTypeName(_ type: EKSourceType) -> String {
        switch type {
        case .local:
            return "Local"
        case .exchange:
            return "Exchange"
        case .calDAV:
            return "CalDAV"
        case .mobileMe:
            return "iCloud"
        case .subscribed:
            return "Subscribed"
        case .birthdays:
            return "Birthdays"
        @unknown default:
            return "Unknown"
        }
    }

    /// Convert CGColor to hex string "#RRGGBB".
    private func cgColorToHex(_ cgColor: CGColor) -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = components[0]
        let g = components[1]
        let b = components[2]
        return EventKitService.hexFromRGB(r: r, g: g, b: b)
    }

    /// Fetch events in a date range, optionally filtered by calendar name.
    /// Maps EKEvent → CKEvent.
    func fetchEvents(from startDate: Date, to endDate: Date, calendarName: String?) -> [CKEvent] {
        var calendars: [EKCalendar]? = nil
        if let name = calendarName {
            let matching = store.calendars(for: .event).filter { $0.title == name }
            if matching.isEmpty {
                return []
            }
            calendars = matching
        }

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let ekEvents = store.events(matching: predicate)

        return ekEvents.map { ev in
            CKEvent(
                id: ev.calendarItemIdentifier,
                title: ev.title ?? "",
                start: EventDateParser.formatISO8601(ev.startDate),
                end: EventDateParser.formatISO8601(ev.endDate),
                calendar: ev.calendar?.title ?? "",
                calendarId: ev.calendar?.calendarIdentifier ?? "",
                location: ev.location ?? "",
                notes: ev.notes ?? "",
                isAllDay: ev.isAllDay,
                url: ev.url?.absoluteString ?? ""
            )
        }
    }

    /// Search events by term (case-insensitive) on title and notes within a date range.
    /// Returns matching events with a matchedOn indicator ("title", "notes", or "title,notes").
    func searchEvents(term: String, from startDate: Date, to endDate: Date, calendarName: String?) -> [(event: CKEvent, matchedOn: String)] {
        let allEvents = fetchEvents(from: startDate, to: endDate, calendarName: calendarName)
        var results: [(event: CKEvent, matchedOn: String)] = []

        for event in allEvents {
            let titleMatch = event.title.localizedCaseInsensitiveContains(term)
            let notesMatch = event.notes.localizedCaseInsensitiveContains(term)

            if titleMatch || notesMatch {
                let matchedOn: String
                if titleMatch && notesMatch {
                    matchedOn = "title,notes"
                } else if titleMatch {
                    matchedOn = "title"
                } else {
                    matchedOn = "notes"
                }
                results.append((event: event, matchedOn: matchedOn))
            }
        }

        return results
    }

    /// Create a new event in EventKit. Returns the created CKEvent.
    /// Throws if the save fails or if the specified calendar is not found/ambiguous.
    func createEvent(title: String, start: Date, end: Date, calendarName: String?,
                     location: String?, notes: String?, recurrenceRule: String?) throws -> CKEvent {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end

        // Calendar resolution
        if let name = calendarName {
            let allCalendars = store.calendars(for: .event)
            // Try exact match first
            let exactMatches = allCalendars.filter { $0.title == name }
            if exactMatches.count == 1 {
                event.calendar = exactMatches[0]
            } else if exactMatches.count > 1 {
                throw CreateEventError.ambiguousCalendar(name)
            } else {
                // Try substring match
                let substringMatches = allCalendars.filter {
                    $0.title.localizedCaseInsensitiveContains(name)
                }
                if substringMatches.count == 1 {
                    event.calendar = substringMatches[0]
                } else if substringMatches.count > 1 {
                    throw CreateEventError.ambiguousCalendar(name)
                } else {
                    throw CreateEventError.calendarNotFound(name)
                }
            }
        } else {
            event.calendar = store.defaultCalendarForNewEvents
        }

        if let loc = location {
            event.location = loc
        }
        if let n = notes {
            event.notes = n
        }
        if let rruleStr = recurrenceRule, let rule = RecurrenceParser.parse(rruleStr) {
            event.addRecurrenceRule(rule)
        }

        try store.save(event, span: .thisEvent, commit: true)

        return CKEvent(
            id: event.calendarItemIdentifier,
            title: event.title ?? "",
            start: EventDateParser.formatISO8601(event.startDate),
            end: EventDateParser.formatISO8601(event.endDate),
            calendar: event.calendar?.title ?? "",
            calendarId: event.calendar?.calendarIdentifier ?? "",
            location: event.location ?? "",
            notes: event.notes ?? "",
            isAllDay: event.isAllDay,
            url: event.url?.absoluteString ?? ""
        )
    }

    /// Update an existing event. Only non-nil fields are modified.
    /// Throws UpdateEventError.notFound if the event ID is unknown.
    func updateEvent(id: String, title: String?, start: Date?, end: Date?,
                     location: String?, notes: String?) throws -> CKEvent {
        guard let ekEvent = store.event(withIdentifier: id) else {
            throw UpdateEventError.notFound(id)
        }

        if let title = title {
            ekEvent.title = title
        }
        if let start = start {
            ekEvent.startDate = start
        }
        if let end = end {
            ekEvent.endDate = end
        }
        if let location = location {
            ekEvent.location = location
        }
        if let notes = notes {
            ekEvent.notes = notes
        }

        try store.save(ekEvent, span: .thisEvent, commit: true)

        return CKEvent(
            id: ekEvent.calendarItemIdentifier,
            title: ekEvent.title ?? "",
            start: EventDateParser.formatISO8601(ekEvent.startDate),
            end: EventDateParser.formatISO8601(ekEvent.endDate),
            calendar: ekEvent.calendar?.title ?? "",
            calendarId: ekEvent.calendar?.calendarIdentifier ?? "",
            location: ekEvent.location ?? "",
            notes: ekEvent.notes ?? "",
            isAllDay: ekEvent.isAllDay,
            url: ekEvent.url?.absoluteString ?? ""
        )
    }

    /// Delete an event by its identifier with the specified span.
    /// Returns the title of the deleted event and the span string used.
    /// Throws DeleteEventError.notFound if the event ID is unknown.
    func deleteEvent(id: String, span: EKSpan) throws -> (title: String, span: String) {
        guard let ekEvent = store.event(withIdentifier: id) else {
            throw DeleteEventError.notFound(id)
        }

        let title = ekEvent.title ?? ""
        let spanStr = span == .futureEvents ? "futureEvents" : "thisEvent"

        try store.remove(ekEvent, span: span, commit: true)

        return (title: title, span: spanStr)
    }

    /// Public helper for hex conversion from RGB floats (0.0-1.0).
    static func hexFromRGB(r: CGFloat, g: CGFloat, b: CGFloat) -> String {
        let ri = Int(round(r * 255.0))
        let gi = Int(round(g * 255.0))
        let bi = Int(round(b * 255.0))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
