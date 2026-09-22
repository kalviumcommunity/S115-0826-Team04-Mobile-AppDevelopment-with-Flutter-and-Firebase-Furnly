# PRD — FurniTrack

## 1. Problem statement (as given by Kalvium)
A furniture rental company manages hundreds of items rented across a city
for months at a time, but delivery and pickup events are logged only after
crews return to base. The operations team routinely discovers scheduling
conflicts, unreturned items, and billing discrepancies only when a customer
interaction forces a reconciliation.

## 2. Goal
Move event logging from "end of day, back at base" to "the moment it
happens, in the field," so conflicts, overdue items, and billing status are
always current — not reconstructed after the fact.

## 3. Users
- **Crew** — delivery/pickup staff, using the app on their phone in the
  field. They log events and take condition photos. They should not be able
  to edit or delete historical records.
- **Ops** — office staff who manage the item catalog, monitor active/overdue
  rentals, and handle billing reconciliation. They can create items, close
  out disputes, and see everything crew logs in real time.

## 4. Functional requirements

### Must-have (MVP — already scaffolded)
1. Email/password auth with a role (`crew` | `ops`) stored per user.
2. Item catalog (name, category, daily rate, status).
3. Crew can log a **delivery**: pick an item, enter customer name/phone,
   set expected return date, optionally photograph the item's condition.
   - The app MUST check for a conflicting active rental on that item
     before allowing the delivery to be logged, and block it with a clear
     message if one exists.
4. Crew can log a **pickup** against an active rental: this closes the
   rental and immediately marks billing as reconciled.
5. Ops (and crew) can see a live list of active rentals, with overdue ones
   (`expectedReturnDate` passed, no pickup event) visually flagged.
6. Ops can see a live billing-reconciliation queue: rentals that are closed
   but not yet billed out.
7. Search/filter the active-rentals list by customer or item name.

### Should-have (next iteration)
8. Automatic `totalDue` calculation: `daysRented * item.dailyRate`, computed
   at pickup time rather than left at 0.
9. Ops-only "add item" screen (currently items must be seeded manually).
10. Per-rental event history view (delivery + pickup + notes + photos),
    backed by `FirestoreService.eventsForRental()` which already exists.
11. Push/local notification to ops when a rental crosses into "overdue."
12. Offline queueing for crews logging events with no signal — Firestore's
    offline persistence should be enabled and tested for this.

### Out of scope for this sprint
- Payment processing / invoicing integration.
- Route optimization or crew scheduling/dispatch.
- Multi-city or multi-warehouse inventory logic.

## 5. Non-functional requirements
- Every write that matters to the "conflict/overdue/billing" story must be
  visible via a Firestore **stream** (`snapshots()`), not a one-time `get()`
  — the whole point is live state, not a manual refresh.
- Firestore security rules must enforce the crew/ops role boundary described
  above (already drafted in `firestore.rules`).
- The app should degrade gracefully (loading indicators, SnackBar errors)
  rather than crash on network hiccups — this matters because crews are
  using this in the field, often on weak connections.

## 6. Success criteria for the sprint deliverable
- A crew member can complete the full loop: log in → log a delivery with a
  conflict check → see it appear live in the active rentals list → log a
  pickup → see it disappear from active and appear in the billing queue.
- Attempting to double-book an item is blocked with an on-screen explanation
  before any Firestore write happens.
- An overdue rental is visibly flagged without anyone manually checking.
