# Design — FurniTrack

## Design intent
This is a **field ops tool**, not a consumer app. Crew members use it with
one hand, often outdoors, sometimes with poor signal, while standing at a
customer's door. Optimize every screen for that context over polish:

- Large tap targets, minimal typing.
- Every async action shows a loading state (`CircularProgressIndicator`)
  and every failure shows a clear, actionable message (`SnackBar`) — never
  fail silently.
- Prefer pickers (dropdowns, date pickers, camera) over free text wherever
  the data is structured (item selection, return date). Free text is only
  for customer name/phone/notes.
- Errors that come from business logic (e.g. `SchedulingConflictException`)
  must show their full message to the user verbatim — that message is
  written to be read by a crew member on the spot, not just logged.

## Visual system
- Material 3 (`useMaterial3: true`), seeded color scheme
  (`colorSchemeSeed: Colors.indigo`) — already set in `main.dart`. Don't
  hand-roll custom theming beyond this unless asked; consistency across
  screens matters more than novelty here.
- Status is always communicated with the `StatusPill` widget
  (`lib/widgets/status_pill.dart`), color-coded:
  - Green — active / available / on-track.
  - Red — overdue / conflict / error.
  - (Extend this palette rather than inventing new one-off badge widgets.)
- Lists are the dominant layout (`ListView.builder`), not grids — this data
  is inherently list-shaped (a queue of rentals, a queue of billing items)
  and crews scan it top-to-bottom by urgency (overdue first).

## Navigation model
- `AuthGate` (in `main.dart`) is the only place that decides Login vs Home
  — it listens to `authStateChanges` directly. Don't add manual
  `Navigator.push` calls to "log out" flows elsewhere; sign-out should just
  clear auth state and let `AuthGate` react.
- `HomeScreen` is a bottom-nav shell with two tabs (Rentals, Billing) plus a
  floating action button for "Log Delivery" — the FAB is deliberately not a
  third tab, because starting a new delivery is the single most frequent
  action a crew member takes and should be one tap from anywhere in the
  shell.
- Pickup is *not* reachable from the FAB — it's reached by tapping a
  specific rental in the active list (`OverdueItemsScreen` →
  `LogPickupScreen`), because a pickup only makes sense in the context of
  an existing rental, not as a standalone action.

## Screen-by-screen notes
| Screen | Primary job | Don't |
|---|---|---|
| `LoginScreen` / `SignupScreen` | Get crew/ops authenticated fast | Don't add social auth or password reset UI unless asked — out of scope |
| `HomeScreen` | Navigation shell | Don't put business logic here — it's routing only |
| `OverdueItemsScreen` | Scan active rentals, spot overdue ones, jump to pickup | Don't hide overdue items — they should sort/stand out, not require a filter tap |
| `LogDeliveryScreen` | Get a new rental logged with a condition photo, blocked on conflict | Don't let the form submit without picking an item — validated in `_submit` |
| `LogPickupScreen` | Close a rental, capture condition, trigger billing | Don't let this screen silently record `totalDue: 0` once billing math is wired in — that's the current known gap, see `architecture.md` |
| `BillingDashboardScreen` | Show the live reconciliation queue | Read-only for now — don't add edit/delete actions without ops-only guard |

## Copy/tone
- Error and confirmation messages are written for someone standing in a
  doorway, not a developer: short, concrete, next-action-oriented.
  Good: `"Sofa is already out to Priya until Aug 30. Log a pickup for that
  rental before starting a new one."`
  Bad: `"Conflict detected: rentalId already active."`
- Dates are shown as plain `YYYY-MM-DD` via `.toLocal()` split — no need for
  a fancy date-formatting library beyond `intl` unless a specific screen
  calls for it.

## Accessibility / robustness baseline
- Every form field has a validator; don't remove validation to "simplify."
- Every stream-backed screen handles three states explicitly: loading
  (`!snapshot.hasData`), error (`snapshot.hasError`), and empty (`list.isEmpty`)
  — follow the pattern already used in `OverdueItemsScreen` and
  `BillingDashboardScreen` for any new stream-backed screen.
