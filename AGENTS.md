# AGENTS.md

## Purpose
Provide a clear, shared planning checklist for the Gov-Contract-Finder app so any AI agent can pick up work consistently.

## Current State (quick audit)
- App entry point references `SearchView`, but the file does not exist (build will fail).
- `ContentView.swift` is the unused template view.
- Basic SAM.gov search client exists with env-var API key only.

## Phase 1: Make the app build + baseline UX
- Add `SearchView` with basic layout and wiring to `SearchViewModel`.
- Connect `SearchFiltersView` and a simple results list using `OpportunityCardView`.
- Show loading + error states.
- Remove or ignore unused template `ContentView` (no functional change yet).

## Phase 2: SAM.gov API (core)
- Access/setup:
  - Create SAM.gov API account and request API key (developer access).
  - Confirm required scopes for Opportunities API.
  - Store API key securely for dev and production (not hardcoded).
- Client hardening:
  - Add support for pagination and total counts.
  - Add robust error mapping (HTTP errors, quota, auth errors).
  - Add retry/backoff for transient failures.
  - Add caching for recent searches.
- Data mapping:
  - Expand `Opportunity` fields (NAICS/PSC, set-aside, response date, etc.).
  - Normalize and format date fields.

## Phase 3: Filters + Search UX
- Add filters: agency, NAICS/PSC, posted date range, set-aside, location.
- Persist recent searches and filters.
- Allow sorting (relevance, posted date).

## Phase 4: Persistence + Alerts
- Save/favorite opportunities.
- Saved searches with update alerts (local notifications).
- Optional: user accounts if cross-device sync is desired.

## Phase 5: App polish + release
- Accessibility and empty states.
- App icon, launch screen, basic onboarding.
- Privacy policy and App Store metadata.

## API To-Do: SAM.gov enablement (step-by-step)
1) Create a SAM.gov account and request an API key (developer access).
2) Verify access to the Opportunities API and note any rate limits.
3) Define required endpoints and query parameters for the MVP.
4) Create a secure key strategy:
   - Dev: load from environment or a local config file excluded from git.
   - Prod: secure storage or remote config.
5) Implement API client with:
   - Auth parameter injection
   - Pagination support
   - Error handling + response validation
   - Rate limit handling
6) Add mock responses for UI/testing.

