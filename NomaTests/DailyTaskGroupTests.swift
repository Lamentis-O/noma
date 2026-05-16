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

    func testDailyTaskMetricsCountsTodayProgressAndStreak() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = try XCTUnwrap(DateComponents(calendar: calendar, year: 2026, month: 5, day: 16).date)
        let yesterday = try XCTUnwrap(DateComponents(calendar: calendar, year: 2026, month: 5, day: 15).date)
        let twoDaysAgo = try XCTUnwrap(DateComponents(calendar: calendar, year: 2026, month: 5, day: 14).date)

        let metrics = DailyTaskMetrics.make(
            groups: [
                DailyTaskGroup(
                    id: "2026-05-16",
                    date: today,
                    reminders: [
                        CreateReminder(text: "One", isCompleted: true),
                        CreateReminder(text: "Two")
                    ]
                ),
                DailyTaskGroup(
                    id: "2026-05-15",
                    date: yesterday,
                    reminders: [
                        CreateReminder(text: "Three")
                    ]
                ),
                DailyTaskGroup(
                    id: "2026-05-14",
                    date: twoDaysAgo,
                    reminders: [
                        CreateReminder(text: "Four", isCompleted: true)
                    ]
                )
            ],
            today: today,
            calendar: calendar
        )

        XCTAssertEqual(metrics.todayCompletedCount, 1)
        XCTAssertEqual(metrics.todayTargetCount, 2)
        XCTAssertEqual(metrics.streakCount, 3)
    }

    func testDailyTaskMetricsSectionIsOnlyVisibleForProAndUsesSharedLayoutTokens() {
        XCTAssertFalse(DailyTaskMetricsSectionVisibility.isVisible(for: .free))
        XCTAssertTrue(DailyTaskMetricsSectionVisibility.isVisible(for: .pro))
        XCTAssertEqual(DailyTaskMetricsSectionLayout.cardSpacing, NomaSpacing.md)
        XCTAssertEqual(DailyMetricCardLayout.cornerRadius, NomaRadius.xl)
        XCTAssertEqual(DailyMetricCardLayout.contentPadding, NomaSpacing.lg)
        XCTAssertEqual(HomeViewLayout.contentTopPadding, NomaSpacing.xl)
    }
}
