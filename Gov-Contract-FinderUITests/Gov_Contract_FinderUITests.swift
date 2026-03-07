import XCTest

final class Gov_Contract_FinderUITests: XCTestCase {
    private let uiTestDetailLaunchArg = "-uiTest-openDetailFixture"
    private let uiTestEnableV2Arg = "-uiTest-enableV2"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDetailScreenTextStaysWithinVisibleScreenWidth() throws {
        let app = XCUIApplication()
        app.activate()
        app.launchArguments.append(uiTestDetailLaunchArg)
        app.launch()

        XCTAssertTrue(app.otherElements["opportunity_detail_screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.scrollViews["opportunity_detail_scroll"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["UI Test Opportunity"].waitForExistence(timeout: 5))

        let scroll = app.scrollViews["opportunity_detail_scroll"]
        for _ in 0..<6 {
            assertVisibleTextFramesWithinWindowWidth(app: app, scroll: scroll)
            scroll.swipeUp()
        }

        for _ in 0..<2 {
            scroll.swipeDown()
            assertVisibleTextFramesWithinWindowWidth(app: app, scroll: scroll)
        }
    }

    @MainActor
    func testV2ShellShowsAllTabs() throws {
        let app = XCUIApplication()
        app.activate()
        app.launchArguments.append(uiTestEnableV2Arg)
        app.launch()

        XCTAssertTrue(app.buttons["Discover"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Watchlist"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Alerts"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Workspace"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))

        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    private func assertVisibleTextFramesWithinWindowWidth(
        app: XCUIApplication,
        scroll: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let window = app.windows.element(boundBy: 0)
        XCTAssertTrue(window.exists, "App window should exist", file: file, line: line)
        let windowFrame = window.frame.insetBy(dx: 1, dy: 0)

        let visibleTexts = scroll
            .descendants(matching: .staticText)
            .allElementsBoundByIndex
            .filter { element in
                element.exists &&
                element.isHittable &&
                !element.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

        XCTAssertFalse(visibleTexts.isEmpty, "Expected visible text elements in detail screen", file: file, line: line)

        for text in visibleTexts {
            let frame = text.frame
            XCTAssertGreaterThanOrEqual(
                frame.minX,
                windowFrame.minX,
                "Text starts offscreen on the left: '\(text.label)' frame=\(NSCoder.string(for: frame))",
                file: file,
                line: line
            )
            XCTAssertLessThanOrEqual(
                frame.maxX,
                windowFrame.maxX,
                "Text extends offscreen on the right: '\(text.label)' frame=\(NSCoder.string(for: frame))",
                file: file,
                line: line
            )
        }
    }
}
