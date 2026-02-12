# Gov-Contract-Finder — PRD (Draft)

## Product Definition (One Sentence)
Gov-Contract-Finder modernizes how small businesses discover and act on government contract opportunities by making search, evaluation, document access, and outreach fast and simple.

## 1) Product Overview
**Goal:** Make it fast and easy for small businesses (and consultants/agency users later) to find, review, and act on government contract opportunities. The app should feel modern and simple, avoiding the outdated UX typical of government portals.

**Primary outcome:** Users can quickly search, filter, view opportunity details, download documents, and initiate emails to contacts with minimal friction.

## 2) Target Users
- **Primary:** Small businesses seeking contract opportunities.
- **Secondary:** Government contracting consultants.
- **Tertiary:** Agencies (if adoption grows).

## 3) MVP Scope (Phase 1)
### Must-have
- **Modern, polished UI** in SwiftUI (clean, fast, intuitive).
- **Search** contracts via SAM.gov API.
- **Filters** (MVP required): keyword + date range (MM/dd/yyyy) + agency + NAICS.
- **Results list** with key highlights (title, agency, posted date, set-aside, NAICS).
- **Detail view** with:
  - Agency / office / parent path
  - Posted date / response due date
  - NAICS + set-aside
  - Contact(s) with quick email and phone actions
  - Links to SAM.gov and attachments
- **Document access**:
  - Open / download documents to device
  - Share via iOS share sheet
- **Email actions**:
  - Tap-to-compose in default mail app
  - Prefill subject/body with opportunity details for copy/paste

### Not in MVP (Phase 2+)
- Login / accounts
- Favorites / saved opportunities
- Saved searches + alerts
- AI assistance or built-in AI drafting
- Cross-platform (macOS/Android)

## 4) Phase 2+ Roadmap
- Favorites / saved opportunities
- Saved searches + notifications for updates
- Expanded filters (agency, NAICS/PSC, location, set-aside)
- Sorting options (relevance, posted date)
- Share actions (share sheet with SAM.gov link + summary text)
- Add additional contract sources (other websites/APIs) and evaluate scraper-based ingestion where allowed
- Account system (optional) for cross-device sync

## 5) User Stories (MVP)
- As a small business owner, I can search government opportunities by keyword.
- As a user, I can open a contract detail page and understand the opportunity quickly.
- As a user, I can download or open all attached documents.
- As a user, I can tap an email link that opens my email app with key info prefilled.
- As a user, I can call the point of contact directly from the app.

## 6) Functional Requirements (MVP)
- **Search API:** Use SAM.gov Opportunities endpoint.
- **Pagination:** Load more results as user scrolls.
- **Error handling:** Show friendly errors for missing key, rate limits, or bad queries.
- **Performance:** First results in < 2 seconds (typical network).
- **Share sheet:** For documents and key links.

## 7) Non-Functional Requirements
- **Platform:** iOS first (iPhone + iPad).
- **Design:** Modern, clean, professional; feel “new and updated.”
- **Accessibility:** Dynamic type, VoiceOver labels.

## 8) Success Metrics (first 30–60 days)
- **Active users** (DAU/WAU) growth
- **Searches per day**
- **Email clicks** (tap-to-compose usage)

## 9) Open Questions
- Which filters are most important for MVP (agency/NAICS vs. date range only)?

## 10) Risks
- SAM.gov rate limits or API reliability
- Document links with non-text content (PDFs/ZIPs)
- Users expecting AI assistance earlier than planned

---

**Source of truth:** This PRD is a living document and should evolve as product decisions are validated.

## Appendix A) Phase 1 Checklist (MVP Build)
### Product decisions
- Confirm MVP filters: agency, NAICS, date range
- Confirm excluded items: login, favorites, AI export
- Define success events: search, filter apply, detail open, attachment open, email tap

### Design system (AD + luxury noise)
- Create theme tokens (colors, typography, spacing, radii)
- Build `LuxuryBackground` (base + gradient + noise layer)
- Add `noiseTexture` asset (512x512 PNG, grayscale, 2–3% opacity usage)
- Define card style (radius 14–16, soft shadow)
- Define button styles (primary teal, secondary navy)

### Search UX
- Build modern search header (title + subtitle)
- Implement search field + debounce or submit
- Add filter chips row (Agency / NAICS / Dates)
- Add results count + sort label

### Results list
- Redesign `OpportunityCardView` to match new style
- Show: title, agency, NAICS, set-aside, posted/due
- Add quick actions: Open, Email

### Filter sheet
- Agency picker (search + list)
- NAICS picker (search + list)
- Date range (MM/dd/yyyy)
- Clear + Apply actions

### Detail view
- Structured sections (overview, dates, contacts, links)
- Attachment list with open/share
- Email actions with prefilled subject/body
- “Open in SAM.gov” + copy link

### Data + API
- Map filters to SAM.gov params
- Pagination (offset/limit + total count; verify in implementation)
- Error mapping + friendly messages
- Date formatting helper (display)

### Polish
- Empty state (no results)
- Loading state (skeleton / progress)
- Accessibility labels + dynamic type
- Light instrumentation for metrics

## Appendix B) Phase 2 Checklist
### Features
- Favorites / saved opportunities (local only)
- Saved searches + update alerts (local notifications)
- Expanded filters: agency, NAICS/PSC, location, set-aside
- Sorting options (relevance, posted date)
- Share actions (share sheet with SAM.gov link + summary text)

### Additional sources
- Integrate other contract APIs (prioritize official APIs)
- Scraper-based ingestion where allowed as a fallback

### Data + UX
- Cached results for faster repeat searches
- Saved search management UI
- Alerts configuration (frequency, opt-in)
