import EventKit
import Foundation

/// Errors specific to reminder operations.
enum ReminderError: Error {
    case notFound(String)
    case listNotFound(String)
    case listAmbiguous(String)
}

/// Extension to EventKitService for reminder operations.
extension EventKitService {

    // MARK: - Permission

    /// Request reminder access. Calls completion with true if granted, false otherwise.
    func requestReminderAccess(completion: @escaping (Bool) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .authorized, .fullAccess:
            completion(true)
        case .notDetermined:
            if #available(macOS 14.0, *) {
                store.requestFullAccessToReminders { granted, _ in
                    completion(granted)
                }
            } else {
                store.requestAccess(to: .reminder) { granted, _ in
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }

    /// Request reminder access synchronously using a semaphore. Returns true if granted.
    func requestReminderAccessSync() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var granted = false
        requestReminderAccess { result in
            granted = result
            semaphore.signal()
        }
        semaphore.wait()
        return granted
    }

    // MARK: - Lists (US-008)

    /// Fetch all reminder lists mapped to CKReminderList.
    func fetchReminderLists() -> [CKReminderList] {
        let ekCalendars = store.calendars(for: .reminder)
        let semaphore = DispatchSemaphore(value: 0)
        var lists: [CKReminderList] = []

        // Fetch incomplete reminders count per list
        for cal in ekCalendars {
            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: nil,
                ending: nil,
                calendars: [cal]
            )
            var count = 0
            store.fetchReminders(matching: predicate) { reminders in
                count = reminders?.count ?? 0
                semaphore.signal()
            }
            semaphore.wait()

            lists.append(CKReminderList(
                id: cal.calendarIdentifier,
                title: cal.title,
                source: formatReminderSource(title: cal.source.title, type: cal.source.sourceType),
                color: cgColorToHex(cal.cgColor),
                pendingCount: count
            ))
        }

        return lists.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    /// Build the source display string for reminders.
    private func formatReminderSource(title: String, type: EKSourceType) -> String {
        let typeName = reminderSourceTypeName(type)
        if title == typeName { return title }
        return "\(title) (\(typeName))"
    }

    private func reminderSourceTypeName(_ type: EKSourceType) -> String {
        switch type {
        case .local:     return "Local"
        case .exchange:  return "Exchange"
        case .calDAV:    return "CalDAV"
        case .mobileMe:  return "iCloud"
        case .subscribed: return "Subscribed"
        case .birthdays: return "Birthdays"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Fetch Reminders (US-009)

    /// Fetch reminders with optional filters.
    /// By default returns incomplete reminders from all lists.
    func fetchReminders(listName: String?, includeCompleted: Bool, dueBefore: String?) throws -> [CKReminder] {
        // Resolve calendar filter
        var calendars: [EKCalendar]? = nil
        if let name = listName {
            calendars = [try resolveCalendar(named: name, for: .reminder)]
        }

        let semaphore = DispatchSemaphore(value: 0)
        var fetchedReminders: [EKReminder] = []

        if includeCompleted {
            // Fetch both completed and incomplete
            let incompletePredicate = store.predicateForIncompleteReminders(
                withDueDateStarting: nil, ending: nil, calendars: calendars
            )
            let completedPredicate = store.predicateForCompletedReminders(
                withCompletionDateStarting: nil, ending: nil, calendars: calendars
            )

            var incompleteResults: [EKReminder] = []
            var completedResults: [EKReminder] = []

            store.fetchReminders(matching: incompletePredicate) { reminders in
                incompleteResults = reminders ?? []
                semaphore.signal()
            }
            semaphore.wait()

            store.fetchReminders(matching: completedPredicate) { reminders in
                completedResults = reminders ?? []
                semaphore.signal()
            }
            semaphore.wait()

            fetchedReminders = incompleteResults + completedResults
        } else {
            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: nil, ending: nil, calendars: calendars
            )
            store.fetchReminders(matching: predicate) { reminders in
                fetchedReminders = reminders ?? []
                semaphore.signal()
            }
            semaphore.wait()
        }

        // Map EKReminder → CKReminder
        var results = fetchedReminders.map { mapReminder($0) }

        // Apply due-before filter post-fetch
        if let dueBefore = dueBefore, let cutoff = EventDateParser.parseDate(dueBefore) {
            // Set cutoff to end of day if date-only
            let adjustedCutoff: Date
            if dueBefore.count <= 10 {
                let cal = Calendar.current
                adjustedCutoff = cal.date(bySettingHour: 23, minute: 59, second: 59, of: cutoff) ?? cutoff
            } else {
                adjustedCutoff = cutoff
            }

            results = results.filter { reminder in
                guard let dueStr = reminder.dueDate else { return false }
                let dateOnly = EventDateParser.extractDate(dueStr)
                guard let reminderDate = EventDateParser.parseDate(dateOnly) else { return false }
                return reminderDate <= adjustedCutoff
            }
        }

        return results
    }

    /// Map an EKReminder to a CKReminder.
    private func mapReminder(_ ekReminder: EKReminder) -> CKReminder {
        var dueDateStr: String? = nil
        if let dueDateComponents = ekReminder.dueDateComponents,
           let dueDate = Calendar.current.date(from: dueDateComponents) {
            dueDateStr = EventDateParser.formatISO8601(dueDate)
        }

        var creationDateStr: String? = nil
        if let creationDate = ekReminder.creationDate {
            creationDateStr = EventDateParser.formatISO8601(creationDate)
        }

        var completionDateStr: String? = nil
        if let completionDate = ekReminder.completionDate {
            completionDateStr = EventDateParser.formatISO8601(completionDate)
        }

        // Map alarms: extract absoluteDate from each EKAlarm
        var alarmsArr: [String]? = nil
        if let ekAlarms = ekReminder.alarms, !ekAlarms.isEmpty {
            let dates = ekAlarms.compactMap { alarm -> String? in
                guard let absDate = alarm.absoluteDate else { return nil }
                return EventDateParser.formatISO8601(absDate)
            }
            if !dates.isEmpty {
                alarmsArr = dates
            }
        }

        // Map recurrence rules via RecurrenceParser.format()
        var rulesArr: [String]? = nil
        if let ekRules = ekReminder.recurrenceRules, !ekRules.isEmpty {
            rulesArr = ekRules.map { RecurrenceParser.format($0) }
        }

        var urlStr: String? = nil
        if let url = ekReminder.url {
            urlStr = url.absoluteString
        }

        var lastModifiedDateStr: String? = nil
        if let lastModifiedDate = ekReminder.lastModifiedDate {
            lastModifiedDateStr = EventDateParser.formatISO8601(lastModifiedDate)
        }

        return CKReminder(
            id: ekReminder.calendarItemIdentifier,
            title: ekReminder.title ?? "",
            list: ekReminder.calendar?.title ?? "",
            listId: ekReminder.calendar?.calendarIdentifier ?? "",
            isCompleted: ekReminder.isCompleted,
            priority: ekReminder.priority,
            dueDate: dueDateStr,
            notes: ekReminder.notes,
            creationDate: creationDateStr,
            completionDate: completionDateStr,
            alarms: alarmsArr,
            recurrenceRules: rulesArr,
            url: urlStr,
            lastModifiedDate: lastModifiedDateStr
        )
    }

    // MARK: - Create Reminder (US-010)

    /// Create a new reminder in EventKit. Returns the created CKReminder.
    func createReminder(title: String, listName: String?, dueDate: String?,
                        priority: Int, notes: String?,
                        alarm: String?, recurrence: String?,
                        url: String? = nil) throws -> CKReminder {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title

        // Calendar resolution
        if let name = listName {
            reminder.calendar = try resolveCalendar(named: name, for: .reminder)
        } else {
            reminder.calendar = store.defaultCalendarForNewReminders()
        }

        // Due date
        if let dueDateStr = dueDate, let date = EventDateParser.parseDate(dueDateStr) {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
        }

        reminder.priority = priority

        if let notes = notes {
            reminder.notes = notes
        }

        // Alarm
        if let alarmStr = alarm, let alarmDate = EventDateParser.parseDate(alarmStr) {
            let ekAlarm = EKAlarm(absoluteDate: alarmDate)
            reminder.addAlarm(ekAlarm)
        }

        // Recurrence rule
        if let rruleStr = recurrence, let rule = RecurrenceParser.parse(rruleStr) {
            reminder.addRecurrenceRule(rule)
        }

        // URL
        if let urlStr = url, let parsedURL = URL(string: urlStr) {
            reminder.url = parsedURL
        }

        try store.save(reminder, commit: true)

        return mapReminder(reminder)
    }

    // MARK: - Complete Reminder (US-011)

    /// Mark a reminder as completed. Returns (title, alreadyCompleted).
    func completeReminder(id: String) throws -> (title: String, alreadyCompleted: Bool) {
        guard let item = store.calendarItem(withIdentifier: id) as? EKReminder else {
            throw ReminderError.notFound(id)
        }

        let title = item.title ?? ""
        let wasAlreadyCompleted = item.isCompleted

        if !wasAlreadyCompleted {
            item.isCompleted = true
            item.completionDate = Date()
            try store.save(item, commit: true)
        }

        return (title: title, alreadyCompleted: wasAlreadyCompleted)
    }

    // MARK: - Delete Reminder (US-012)

    /// Delete a reminder by its identifier. Returns the title of the deleted reminder.
    func deleteReminder(id: String) throws -> String {
        guard let item = store.calendarItem(withIdentifier: id) as? EKReminder else {
            throw ReminderError.notFound(id)
        }

        let title = item.title ?? ""
        try store.remove(item, commit: true)
        return title
    }
}
