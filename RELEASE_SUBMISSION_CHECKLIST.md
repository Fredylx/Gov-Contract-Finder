# Release Submission Checklist

## Blockers
- [ ] Replace Release placeholders in `Config.release.xcconfig`:
  - [ ] `GAD_APPLICATION_IDENTIFIER`
  - [ ] `ADMOB_SEARCH_INTERSTITIAL_AD_UNIT_ID`
  - [ ] `SAM_API_KEY`
- [ ] Create and submit In-App Purchases in App Store Connect:
  - [ ] `com.fredy.lopez.govcontractfinder.tip.small`
  - [ ] `com.fredy.lopez.govcontractfinder.tip.medium`
  - [ ] `com.fredy.lopez.govcontractfinder.tip.large`
- [ ] Complete App Privacy questionnaire in App Store Connect
- [ ] Confirm Support URL and Privacy Policy URL in App Store Connect

## Validation
- [ ] Archive Release build (device)
- [ ] Validate archive in Xcode Organizer
- [ ] TestFlight smoke test:
  - [ ] Search ad trigger does not block app flow
  - [ ] ATT flow works as expected
  - [ ] Tip jar purchase success/cancel/pending
  - [ ] Release Settings does not show Local Data/Debug cards

## Metadata
- [ ] Home Screen Name (CFBundleDisplayName): `GovHunter`
- [ ] App Store Name: `Gov Contract Hunter`
- [ ] App Subtitle: `Government Contract Finder`
- [ ] Final app description, subtitle, keywords
- [ ] Category and age rating
- [ ] App screenshots for required device classes

## Deferred TODO
- [ ] Revisit deployment target strategy (currently 18.6)
