# First-Run Demo V2

## Goal
Teach a brand-new user the fastest path to value in the app within the first 15 to 25 seconds.

The demo should answer:
- Where do I search?
- How do I run a search?
- What am I looking at when results appear?

## Recommended Direction
Use a hybrid onboarding flow:

1. Full-screen intro panel on first launch only.
2. Three live coach-mark steps over the real `Discover` screen.
3. End immediately after the user understands the first result card.

This is better than a slideshow because it teaches the real UI instead of abstract screenshots.

## Recommended User Flow

### Step 0: Intro Overlay
Purpose: set context without overwhelming the user.

Copy:
- Title: `Find your first contract fast`
- Body: `We’ll show you the three actions that matter in Discover.`
- Primary CTA: `Start Demo`
- Secondary CTA: `Skip`

Visual:
- Use a built-in SwiftUI mock of the `Discover` screen.
- Keep it branded and polished, but do not make this a dependency on exported assets.

### Step 1: Highlight Search Field
Purpose: show where the workflow begins.

Target:
- Keyword search field in `Discover`

Copy:
- `Start here. Enter a keyword like software to narrow opportunities.`

Behavior:
- Tapping the highlighted field focuses it.
- If empty, auto-fill `software`.
- Advance to the next step immediately after the tap.

### Step 2: Highlight Search Button
Purpose: teach the primary action.

Target:
- `Search Opportunities` button

Copy:
- `Tap Search to pull matching opportunities.`

Behavior:
- Tapping the highlighted button should not hit the live network.
- It should hide the keyboard.
- It should instantly reveal one mock result card.
- Advance to the next step immediately.

### Step 3: Highlight Result Card
Purpose: teach what a result looks like and what to do next.

Target:
- Top demo result card

Copy:
- `This is a result card. Open cards like this to review an opportunity.`

Behavior:
- Tapping the highlighted card completes the walkthrough.
- Do not navigate during the demo.
- Leave the user on `Discover` with `software` still in the field.

## UX Rules
- Show automatically only on first launch in the V2 shell.
- If the user skips, never auto-show again.
- If the user completes it, never auto-show again.
- If the app closes mid-demo, resume from the exact saved step.
- While coach marks are active, only the highlighted target and `Skip` should be tappable.
- Keep the flow short. No more than 3 live interaction steps.

## Why This Flow Works
- It teaches by doing, not by reading.
- It keeps the user on the highest-value screen: `Discover`.
- It avoids fake complexity like teaching filters, watchlist, alerts, or workspace too early.
- It makes the app feel easier immediately after install.

## Visual Direction
- Use a dimmed overlay with a punched-out highlight around the active element.
- Use the current V2 cyberpunk visual language:
  - neon cyan and violet accents
  - dark glass surfaces
  - strong contrast
- Keep the coach-mark card compact and readable.
- Avoid giant paragraphs or multiple buttons beyond `Skip`.

## Content Rules
- Keep copy action-based, not marketing-heavy.
- Use short instructions tied to exactly one target.
- Do not explain every feature.
- Focus on the first successful search only.

## Good v1 Scope
- Intro panel
- Search field highlight
- Search button highlight
- Result card highlight
- Skip and resume support

## Out of Scope for v1
- Replay from Settings
- Multi-slide onboarding
- Tooltips for every tab
- Workspace tutorial
- Alerts tutorial
- API-backed demo search
- Video or animated product tour

## Future Ideas

### Option A: Replay From Settings
Add `Replay Demo` later if support tickets show users still miss the flow.

### Option B: Progressive Tips
After the first-run demo, show one-time contextual nudges later:
- first save to bookmarks
- first alert creation
- first workspace task

### Option C: Role-Specific Demo
If the app later supports different user types, tailor the intro:
- independent consultant
- small business owner
- capture manager

## Suggested Build Notes
- Keep walkthrough state in a small persisted controller.
- Keep demo data local to the UI layer.
- Do not route walkthrough logic through the repository or live search path.
- Register highlight targets from the real view hierarchy so it scales across iPhone and iPad.

## Execution Plan

### Phase 1: Lock the Product Flow
Status: `Done`

Steps:
1. Confirm the walkthrough is V2-only.
2. Keep the flow to one intro screen plus three live steps.
3. Lock the exact step order:
   1. search field
   2. search button
   3. result card
4. Lock the completion rules:
   1. skip once -> never auto-show again
   2. complete once -> never auto-show again
   3. app closes mid-flow -> resume exact step

Findings:
- A live coach-mark flow is a better fit than exported tutorial screenshots because it teaches the actual `Discover` UI.
- The right v1 scope is narrow. Teaching filters, watchlist, alerts, or workspace in the first-run flow would dilute the main action.

### Phase 2: State and Persistence
Status: `In Progress`

Steps:
1. Add a root-owned first-run demo controller.
2. Persist the exact step in `UserDefaults`.
3. Expose helper state for:
   1. intro visibility
   2. live coach-mark visibility
   3. active target
4. Ensure `completed` and `skipped` permanently suppress auto-show.

Findings:
- The controller shape is already the right abstraction for resume and suppression behavior.
- Persisting a single step value is enough for v1. No separate onboarding profile is needed.

### Phase 3: V2 Shell Wiring
Status: `In Progress`

Steps:
1. Attach the controller only to the V2 shell.
2. Force the app onto `Discover` whenever the demo starts or resumes.
3. Prevent bottom-tab interaction during the demo.
4. Leave the legacy shell unchanged.

Findings:
- Root-level ownership is the correct place to control initial presentation and tab locking.
- The walkthrough should never be mixed into the legacy shell because that would create two onboarding paths to maintain.

### Phase 4: Discover Coach Marks
Status: `In Progress`

Steps:
1. Register real target frames for:
   1. search field
   2. search CTA
   3. top result card
2. Add a dimmed overlay with a punched-out highlight.
3. Make only the highlighted target and `Skip` tappable.
4. Auto-fill `software` during the search field step.
5. Reveal a mock result card during the search CTA step.
6. Complete the walkthrough on result-card tap without navigating.

Findings:
- Using the real `Discover` layout means the overlay needs frame registration from the live view hierarchy.
- The result-card step must stay UI-local. It should not go through the live repository or network path.

### Phase 5: Validation and Polish
Status: `In Progress`

Steps:
1. Verify fresh install behavior.
2. Verify skip behavior.
3. Verify exact-step resume after interruption.
4. Verify iPhone and iPad highlight alignment.
5. Verify the walkthrough leaves `software` in the search field on completion.
6. Add focused tests for controller persistence.

Findings:
- The highest-risk part is not the copy. It is overlay alignment and tap gating across different screen sizes.

## Acceptance Criteria
- Fresh install shows the intro automatically in V2.
- `Skip` dismisses and never auto-shows again.
- `Start Demo` moves into live coach marks.
- Step order is:
  1. search field
  2. search button
  3. result card
- Search field step auto-fills `software` if empty.
- Search step reveals a mock result without calling the API.
- Result card tap completes the demo.
- Closing the app mid-demo resumes the exact same step.

## Current Progress
- `Done`: brainstorm and product flow note
- `Done`: saved this working document in the repo
- `In Progress`: first-run demo controller, V2 shell wiring, and `Discover` target registration
- `In Progress`: intro overlay and live coach-mark overlay
- `In Progress`: walkthrough-only mock result path
- `Done`: clean build after walkthrough integration
- `In Progress`: focused test run and verification pass
- `Pending`: on-device walkthrough verification

## Current Blockers
- No current compile blocker.
- Current verification gap: the focused simulator test run is stalling during test-runner startup, so persistence tests are not yet confirmed from XCTest output.
- Next action: finish the focused test pass, then verify the walkthrough behavior on device or simulator interaction.

## Progress Log
- `2026-03-15`: Created the first-run walkthrough concept note.
- `2026-03-15`: Broke the work into 5 implementation phases with concrete steps.
- `2026-03-15`: Confirmed the current integration blocker from build output: `FirstRunDemoV2.swift` invalid redeclaration of `body`.
- `2026-03-15`: Fixed the SwiftUI naming collision in `FirstRunDemoV2.swift` by renaming the coach-mark message property.
- `2026-03-15`: Rebuilt the app successfully after the walkthrough integration changes.
- `2026-03-15`: Started a focused `FirstRunDemoControllerTests` run; compile path is clean, final XCTest summary still pending because the simulator runner is slow/stalled.

## Recommendation
Ship the hybrid first-run demo before expanding into deeper onboarding.

It is the highest-signal, lowest-friction way to help new users understand the app immediately.
