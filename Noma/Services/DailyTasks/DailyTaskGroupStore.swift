import Foundation
import Observation

struct DailyTaskGroup: Codable, Equatable, Identifiable {
    let id: String
    let date: Date
    var reminders: [CreateReminder]

    var taskCount: Int { reminders.count }
}

struct DailyTaskGroupSummary: Equatable, Identifiable {
    let group: DailyTaskGroup

    var id: String { group.id }
    var taskCount: Int { group.taskCount }
    var completedTaskCount: Int { group.reminders.filter(\.isCompleted).count }
    var isCompleted: Bool { taskCount > 0 && completedTaskCount == taskCount }
    var taskCountUnitKey: String {
        taskCount == 1 ? "home.daily-groups.task-count.singular" : "home.daily-groups.task-count.plural"
    }

    var title: String {
        group.date.formatted(date: .abbreviated, time: .omitted)
    }
}

enum DailyTaskGroupsSection {
    static let headerTitleKey = "home.daily-groups.section-header"
}

enum DailyTaskGroupsProgressCopy {
    static let ofKey = "home.daily-groups.progress.of"
    static let doneKey = "home.daily-groups.progress.done"
}

@MainActor
@Observable
final class DailyTaskGroupStore {
    @ObservationIgnored
    private let storage: DailyTaskGroupStorage

    @ObservationIgnored
    private let calendar: Calendar

    private(set) var groups: [DailyTaskGroup]

    init(
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        storageKey: String = DailyTaskGroupStorage.defaultStorageKey
    ) {
        self.storage = DailyTaskGroupStorage(userDefaults: userDefaults, storageKey: storageKey)
        self.calendar = calendar
        self.groups = storage.loadGroups()
    }

    nonisolated static func todayID(calendar: Calendar = .current) -> String {
        dayID(for: Date(), calendar: calendar)
    }

    nonisolated static func dayID(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    nonisolated static func date(forDayID dayID: String, calendar: Calendar = .current) -> Date? {
        let parts = dayID.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return DateComponents(calendar: calendar, year: parts[0], month: parts[1], day: parts[2]).date
    }

    func todayID() -> String {
        Self.todayID(calendar: calendar)
    }

    func summaries() -> [DailyTaskGroupSummary] {
        groups.map(DailyTaskGroupSummary.init(group:))
    }

    func reminders(forDayID dayID: String) -> [CreateReminder] {
        groups.first { $0.id == dayID }?.reminders ?? []
    }

    func save(reminders: [CreateReminder], for date: Date) {
        save(reminders: reminders, forDayID: Self.dayID(for: date, calendar: calendar), date: date)
    }

    func save(reminders: [CreateReminder], forDayID dayID: String) {
        let date = Self.date(forDayID: dayID, calendar: calendar) ?? Date()
        save(reminders: reminders, forDayID: dayID, date: date)
    }

    private func save(reminders: [CreateReminder], forDayID dayID: String, date: Date) {
        if reminders.isEmpty {
            groups.removeAll { $0.id == dayID }
        } else if let index = groups.firstIndex(where: { $0.id == dayID }) {
            groups[index] = DailyTaskGroup(id: dayID, date: date, reminders: reminders)
        } else {
            groups.append(DailyTaskGroup(id: dayID, date: date, reminders: reminders))
        }

        groups.sort { $0.date > $1.date }
        persist()
    }

    private func persist() {
        storage.save(groups: groups)
    }
}
