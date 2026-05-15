//
//  NomaTests.swift
//  NomaTests
//
//  Created by Elias Papavlassopoulos on 15.05.26.
//

@testable import Noma
import XCTest

final class NomaTests: XCTestCase {
    func testSpacingContractExposesXsToken() {
        XCTAssertEqual(NomaSpacing.xs, 4)
    }

    func testCreateViewDoesNotFocusInputWhenInitialDelayIsCancelled() async {
        let shouldFocus = await CreateView.shouldApplyInitialFocus {
            throw CancellationError()
        }

        XCTAssertFalse(shouldFocus)
    }

    func testCreateViewFocusesInputAfterInitialDelayCompletes() async {
        let shouldFocus = await CreateView.shouldApplyInitialFocus {}

        XCTAssertTrue(shouldFocus)
    }

    func testProjectEmptyStateOmitsCTAUntilProjectCreationFlowExists() {
        XCTAssertNil(CreateProjectEmptyState.placeholder.cta)
    }
}
