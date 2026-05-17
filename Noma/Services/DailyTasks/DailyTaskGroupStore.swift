import Foundation
import Observation

@MainActor
@Observable
final class DailyTaskGroupStore {
    @ObservationIgnored
    private let userDefaults: UserDefaults

    @ObservationIgnored
    private var storage: DailyTaskGroupStorage

    @ObservationIgnored
    private let calendar: Calendar

    @ObservationIgnored
    private var userID: String?
    private(set) var groups: [DailyTaskGroup]

    init(
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        userID: String? = nil,
        storageKey: String? = nil
    ) {
        self.userDefaults = userDefaults
        self.calendar = calendar
        self.userID = userID
        self.storage = DailyTaskGroupStorage(
            userDefaults: userDefaults,
            storageKey: storageKey ?? DailyTaskGroupStorage.storageKey(forUserID: userID)
        )
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
        groups
            .filter { !$0.reminders.isEmpty }
            .map(DailyTaskGroupSummary.init(group:))
    }

    func reminders(forDayID dayID: String) -> [CreateReminder] {
        groups.first { $0.id == dayID }?.reminders ?? []
    }

    func projects(forDayID dayID: String) -> [TaskProject] {
        groups.first { $0.id == dayID }?.projects ?? []
    }

    func selectedProjectID(forDayID dayID: String) -> TaskProject.ID? {
        groups.first { $0.id == dayID }?.selectedProjectID
    }

    func switchUserID(_ userID: String?) {
        guard self.userID != userID else { return }

        self.userID = userID
        storage = DailyTaskGroupStorage(
            userDefaults: userDefaults,
            storageKey: DailyTaskGroupStorage.storageKey(forUserID: userID)
        )
        groups = storage.loadGroups()
    }

    func save(reminders: [CreateReminder], for date: Date) {
        let dayID = Self.dayID(for: date, calendar: calendar)
        save(reminders: reminders, forDayID: dayID, date: date)
    }

    func save(reminders: [CreateReminder], forDayID dayID: String) {
        let date = Self.date(forDayID: dayID, calendar: calendar) ?? Date()
        save(reminders: reminders, forDayID: dayID, date: date)
    }

    private func save(reminders: [CreateReminder], forDayID dayID: String, date: Date) {
        let projects = projects(forDayID: dayID)
        let selectedProjectID = selectedProjectID(forDayID: dayID)
        save(
            reminders: reminders,
            projects: projects,
            selectedProjectID: selectedProjectID,
            forDayID: dayID,
            date: date
        )
    }

    func save(
        reminders: [CreateReminder],
        projects: [TaskProject],
        selectedProjectID: TaskProject.ID?,
        forDayID dayID: String
    ) {
        let date = Self.date(forDayID: dayID, calendar: calendar) ?? Date()
        save(
            reminders: reminders,
            projects: projects,
            selectedProjectID: selectedProjectID,
            forDayID: dayID,
            date: date
        )
    }

    func deleteProject(withID projectID: TaskProject.ID) {
        groups = groups.compactMap { group in
            var updatedGroup = group
            updatedGroup.projects.removeAll { $0.id == projectID }
            updatedGroup.reminders.removeAll { $0.projectID == projectID }

            if updatedGroup.selectedProjectID == projectID {
                updatedGroup.selectedProjectID = nil
            }

            return updatedGroup.reminders.isEmpty && updatedGroup.projects.isEmpty ? nil : updatedGroup
        }

        persist()
    }

    func updateProject(_ project: TaskProject) {
        groups = groups.map { group in
            var updatedGroup = group
            updatedGroup.projects = group.projects.map { storedProject in
                storedProject.id == project.id ? project : storedProject
            }
            return updatedGroup
        }

        persist()
    }

    private func save(
        reminders: [CreateReminder],
        projects: [TaskProject],
        selectedProjectID: TaskProject.ID?,
        forDayID dayID: String,
        date: Date
    ) {
        let validSelectedProjectID = projects.contains { $0.id == selectedProjectID } ? selectedProjectID : nil

        if reminders.isEmpty && projects.isEmpty {
            groups.removeAll { $0.id == dayID }
        } else if let index = groups.firstIndex(where: { $0.id == dayID }) {
            groups[index] = DailyTaskGroup(
                id: dayID,
                date: date,
                reminders: reminders,
                projects: projects,
                selectedProjectID: validSelectedProjectID
            )
        } else {
            groups.append(DailyTaskGroup(
                id: dayID,
                date: date,
                reminders: reminders,
                projects: projects,
                selectedProjectID: validSelectedProjectID
            ))
        }

        groups.sort { $0.date > $1.date }
        persist()
    }

    private func persist() {
        storage.save(groups: groups)
    }
}
