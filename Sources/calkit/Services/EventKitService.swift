import EventKit
import Foundation

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
    func fetchCalendars() -> [CKCalendar] {
        let ekCalendars = store.calendars(for: .event)
        return ekCalendars.map { cal in
            CKCalendar(
                id: cal.calendarIdentifier,
                title: cal.title,
                source: sourceTypeName(cal.source.sourceType),
                color: cgColorToHex(cal.cgColor)
            )
        }
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

    /// Public helper for hex conversion from RGB floats (0.0-1.0).
    static func hexFromRGB(r: CGFloat, g: CGFloat, b: CGFloat) -> String {
        let ri = Int(round(r * 255.0))
        let gi = Int(round(g * 255.0))
        let bi = Int(round(b * 255.0))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
