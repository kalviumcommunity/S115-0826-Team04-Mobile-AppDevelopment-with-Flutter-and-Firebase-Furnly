# Phases — FurniTrack build plan

Mapped to the Kalvium Module 3 concept list (Flutter + Firebase, 5-week
sprint). Phase 0 is already built (see the existing `lib/` tree) — phases
1+ are what's left. Work through phases in order; each is meant to be
independently testable before moving on.

## Phase 0 — Scaffold (DONE)
Concepts: 3.1–3.4, 3.9–3.19, 3.23–3.35, 3.42, 3.46, 3.47
- Project setup, Dart/Flutter fundamentals, Firebase Auth (sign up/in/out,
  role storage), Firestore models + create/read, security rules, bottom
  nav, loading/error/SnackBar feedback.
- Delivered: auth flow, item dropdown, delivery logging with conflict
  check, pickup logging that closes a rental, active/overdue rentals list
  with search, billing dashboard (read-only).

## Phase 1 — Billing math
Concepts: 3.37 (Update Data), 3.34 (Data Model Mapping)
- Fetch the `Item` (for `dailyRate`) inside `LogPickupScreen` before
  closing the rental.
- Compute `totalDue = daysRented * item.dailyRate` and pass it into
  `FirestoreService.closeRental` instead of the current placeholder `0.0`.
- Test: closing a rental after N days at a known daily rate produces the
  expected `totalDue` in the `rentals` doc.

## Phase 2 — Item management (ops-only)
Concepts: 3.16–3.19 (Forms/Input/Validation), 3.35 (Add Data), 3.42 (Rules)
- New `AddItemScreen` (ops role only, gate with the stored `role` from
  `users/{uid}`) using `FirestoreService.addItem`, which already exists.
- Add an "Items" tab or entry point from `HomeScreen`.
- Test: a `crew`-role user cannot reach or successfully submit this screen
  (both UI-gated and rules-gated).

## Phase 3 — Event history per rental
Concepts: 3.20 (Displaying Lists), 3.39 (Querying Data), 3.40 (Real-Time)
- New `RentalDetailScreen` showing a rental's full event log via
  `FirestoreService.eventsForRental()`, which already exists but is unused.
- Show timestamp, type, notes, and condition photo (if any) per event,
  chronologically.
- Reachable by tapping a rental anywhere it's listed.

## Phase 4 — Offline resilience
Concepts: 3.21 (Loading Indicators), 3.22/3.25 (Error/Exception Handling)
- Enable Firestore offline persistence explicitly and verify
  `LogDeliveryScreen`/`LogPickupScreen` queue writes gracefully when
  offline, syncing once signal returns.
- Add a visible "offline — will sync" indicator rather than letting a
  pending write look identical to a confirmed one.

## Phase 5 — Notifications for overdue rentals
Concepts: 3.40 (Real-Time Data), stretch — outside the given concept list,
confirm with instructor before building
- A scheduled check (Cloud Function or client-side on ops app open) that
  flags newly-overdue rentals. Treat as optional/stretch; the live
  `overdueRentalsStream()` already satisfies the core problem statement
  without this.

## Non-code deliverables (do alongside, not blocking the app)
Concepts: 3.7 (PRD Playbook), 3.8 (Mock UX)
- `PRD.md` in this repo already covers 3.7.
- 3.8 (wireframes/prototypes) is a separate design-tool deliverable, not
  code — don't try to generate it as Flutter screens; it precedes them.

## Definition of done for the sprint
All of Phase 0–3 complete and manually walked through end-to-end:
crew signs up → ops adds an item → crew logs a delivery (conflict check
proven by trying to double-book) → item shows as active/overdue correctly
→ crew logs a pickup → billing dashboard shows correct `totalDue` → rental
detail shows both events with photos.
