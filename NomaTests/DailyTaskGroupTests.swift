//
//  DailyTaskGroupTests.swift
//  NomaTests
//
//  Created by Codex on 16.05.26.
//

@testable import Noma
import XCTest

final class DailyTaskGroupTests: XCTestCase {
    func testDailyTaskGroupStoragePersistsOnlyDaysWithTasks() throws {
        let storageKey = "NomaTests-\(UUID().uuidString)"
        let defaults = UserDefaults.standard
        defer { defaults.removeObject(forKey: storageKey) }
        let calendar = Calendar(identifier: .gregorian)
        let date = try XCTUnwrap(DateComponents(calendar: calendar, year: 2026, month: 5, day: 16).date)
        let reminder = CreateReminder(id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, text: "Plan launch")
        let storage = DailyTaskGroupStorage(userDefaults: defaults, storageKey: storageKey)

        storage.save(groups: [
            DailyTaskGroup(id: "2026-05-16", date: date, reminders: [reminder]),
            DailyTaskGroup(id: "2026-05-17", date: date.addingTimeInterval(86_400), reminders: [])
        ])

        XCTAssertEqual(storage.loadGroups().map(\.id), ["2026-05-16"])
        XCTAssertEqual(storage.loadGroups().first?.reminders, [reminder])
    }

    func testDailyTaskGroupStorageScopesSavedGroupsByUserID() throws {
        let defaults = UserDefaults.standard
        let firstUserID = UUID().uuidString
        let secondUserID = UUID().uuidString
        let firstStorageKey = DailyTaskGroupStorage.storageKey(forUserID: firstUserID)
        let secondStorageKey = DailyTaskGroupStorage.storageKey(forUserID: secondUserID)
        defaults.removeObject(forKey: firstStorageKey)
        defaults.removeObject(forKey: secondStorageKey)
        defer {
            defaults.removeObject(forKey: firstStorageKey)
            defaults.removeObject(forKey: secondStorageKey)
        }
        let calendar = Calendar(identifier: .gregorian)
        let date = try XCTUnwrap(DateComponents(calendar: calendar, year: 2026, month: 5, day: 16).date)
        let firstStorage = DailyTaskGroupStorage(userDefaults: defaults, storageKey: firstStorageKey)
        let secondStorage = DailyTaskGroupStorage(userDefaults: defaults, storageKey: secondStorageKey)

        firstStorage.save(groups: [
            DailyTaskGroup(id: "2026-05-16", date: date, reminders: [CreateReminder(text: "Private task")])
        ])

        XCTAssertTrue(secondStorage.loadGroups().isEmpty)

        secondStorage.save(groups: [
            DailyTaskGroup(id: "2026-05-16", date: date, reminders: [CreateReminder(text: "Other account task")])
        ])

        XCTAssertEqual(firstStorage.loadGroups().first?.reminders.map(\.text), ["Private task"])
        XCTAssertEqual(secondStorage.loadGroups().first?.reminders.map(\.text), ["Other account task"])
    }

    @MainActor
    func testDailyTaskGroupSummaryUsesDailyGroupsProgressCopyAndCompletionState() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try XCTUnwrap(DateComponents(calendar: calendar, year: 2026, month: 5, day: 16).date)
        let summary = DailyTaskGroupSummary(
            group: DailyTaskGroup(
                id: "2026-05-16",
                date: date,
                reminders: [
                    CreateReminder(text: "One"),
                    CreateReminder(text: "Two")
                ]
            )
        )
        let completedSummary = DailyTaskGroupSummary(
            group: DailyTaskGroup(
                id: "2026-05-17",
                date: date,
                reminders: [
                    CreateReminder(text: "One", isCompleted: true)
                ]
            )
        )

        XCTAssertEqual(DailyTaskGroupsSection.headerTitleKey, "home.daily-groups.section-header")
        XCTAssertEqual(summary.taskCount, 2)
        XCTAssertEqual(summary.completedTaskCount, 0)
        XCTAssertEqual(summary.taskCountUnitKey, "home.daily-groups.task-count.plural")
        XCTAssertFalse(summary.isCompleted)
        XCTAssertTrue(completedSummary.isCompleted)
        XCTAssertEqual(completedSummary.completedTaskCount, 1)
        XCTAssertEqual(completedSummary.taskCountUnitKey, "home.daily-groups.task-count.singular")
        XCTAssertEqual(DailyTaskGroupsProgressCopy.ofKey, "home.daily-groups.progress.of")
        XCTAssertEqual(DailyTaskGroupsProgressCopy.doneKey, "home.daily-groups.progress.done")
    }

    func testDailyTaskGroupRowShowsCompletionIconOnlyWhenAllTasksAreDone() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try XCTUnwrap(DateComponents(calendar: calendar, year: 2026, month: 5, day: 16).date)
        let incompleteSummary = DailyTaskGroupSummary(
            group: DailyTaskGroup(
                id: "2026-05-16",
                date: date,
                reminders: [
                    CreateReminder(text: "One", isCompleted: true),
                    CreateReminder(text: "Two")
                ]
            )
        )
        let completedSummary = DailyTaskGroupSummary(
            group: DailyTaskGroup(
                id: "2026-05-17",
                date: date,
                reminders: [
                    CreateReminder(text: "One", isCompleted: true)
                ]
            )
        )

        XCTAssertNil(DailyTaskGroupRowStatus.systemImage(for: incompleteSummary))
        XCTAssertEqual(
            DailyTaskGroupRowStatus.systemImage(for: completedSummary),
            DailyTaskGroupRowStatus.completedSystemImage
        )
    }
}
