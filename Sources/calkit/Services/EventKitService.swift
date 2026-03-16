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

    /// Public helper for hex conversion from RGB floats (0.0-1.0).
    static func hexFromRGB(r: CGFloat, g: CGFloat, b: CGFloat) -> String {
        let ri = Int(round(r * 255.0))
        let gi = Int(round(g * 255.0))
        let bi = Int(round(b * 255.0))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
