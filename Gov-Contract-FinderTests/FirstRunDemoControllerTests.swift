import Foundation
import Testing
@testable import Gov_Contract_Finder

@MainActor
struct FirstRunDemoControllerTests {
    @Test func freshControllerStartsAtIntro() {
        let suiteName = "first-run-demo-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let controller = FirstRunDemoController(defaults: defaults)

        #expect(controller.step == .intro)
        #expect(controller.isActive)
        #expect(controller.isShowingIntro)
    }

    @Test func controllerPersistsExactLiveStepAcrossInstances() {
        let suiteName = "first-run-demo-resume-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let controller = FirstRunDemoController(defaults: defaults)
        controller.startDemo()
        controller.advanceFromSearchField()

        let reloaded = FirstRunDemoController(defaults: defaults)

        #expect(reloaded.step == .searchCTA)
        #expect(reloaded.isShowingCoachMarks)
        #expect(reloaded.activeTarget == .searchCTA)
    }

    @Test func skipPreventsFutureAutoShow() {
        let suiteName = "first-run-demo-skip-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let controller = FirstRunDemoController(defaults: defaults)
        controller.skip()

        let reloaded = FirstRunDemoController(defaults: defaults)

        #expect(reloaded.step == .skipped)
        #expect(!reloaded.isActive)
        #expect(!reloaded.isShowingIntro)
    }

    @Test func completionPreventsFutureAutoShow() {
        let suiteName = "first-run-demo-complete-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let controller = FirstRunDemoController(defaults: defaults)
        controller.startDemo()
        controller.advanceFromSearchField()
        controller.advanceFromSearchCTA()
        controller.complete()

        let reloaded = FirstRunDemoController(defaults: defaults)

        #expect(reloaded.step == .completed)
        #expect(!reloaded.isActive)
        #expect(reloaded.activeTarget == nil)
    }
}
