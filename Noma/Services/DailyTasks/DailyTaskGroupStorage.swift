import Foundation

struct DailyTaskGroupStorage {
    nonisolated static let defaultStorageKey = "noma.daily-task-groups"
    nonisolated static let signedOutStorageScope = "signed-out"

    private let userDefaults: UserDefaults
    private let storageKey: String

    nonisolated static func storageKey(forUserID userID: String?) -> String {
        let scope = userID ?? signedOutStorageScope
        return "\(defaultStorageKey).\(scope)"
    }

    init(userDefaults: UserDefaults = .standard, storageKey: String = DailyTaskGroupStorage.defaultStorageKey) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    func loadGroups() -> [DailyTaskGroup] {
        guard let data = userDefaults.data(forKey: storageKey),
              let groups = try? JSONDecoder().decode([DailyTaskGroup].self, from: data) else {
            return []
        }

        return groups
            .filter { !$0.reminders.isEmpty || !$0.projects.isEmpty }
            .sorted { $0.date > $1.date }
    }

    func save(groups: [DailyTaskGroup]) {
        guard let data = try? JSONEncoder().encode(groups) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
