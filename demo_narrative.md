# Furnly Demo Narrative

## Rehearsal Goal

Show the change from delayed, end-of-day reconciliation to a live operations
loop: a crew member records what happened in the field, while the dispatcher
sees conflicts, rental activity, and timing signals immediately.

## Before and After

Before Furnly, delivery and pickup details were reconstructed after crews
returned to base. That delay hid double-booked items, made the current rental
state uncertain, and left the team without a reliable measure of how quickly
an event was logged.

After Furnly, the crew logs a delivery or pickup at the moment it happens,
optionally adds a condition photo, and the write updates the event history and
item status. The dispatcher dashboard listens to Firestore streams, surfaces
every active conflict, and opens the affected rental for review. Rental Detail
also shows how long it took to log the first delivery after the rental began.

## Day 18-20 Script

### 1. Set the scene

“We are following one rental from creation through delivery. The problem we
are solving is not just data entry: the operations team needs the current truth
while the rental is active.”

Open the app and sign in as an operations user. Start on the dispatcher
dashboard and briefly show the live Items and Rentals views.

### 2. Create the operational state

Create a rental for one item with a start date a few hours in the past and an
expected return date in the future. Create two more active rentals that use the
same item and overlap the first rental's date range.

“This deliberately creates a three-way conflict so we can show that each
affected rental is reported, not just the first pair found.”

Open the Rentals tab. Point out one conflict alert for each of the three
rentals. Each alert lists the other rentals it conflicts with. Tap Review on
each alert and show that it opens that alert's rental detail screen.

### 3. Log the real-world event

Open the crew event flow and log a delivery for the test rental. Use the item
and rental IDs from the setup, and add a short note or condition photo if the
demo environment supports it.

“The event is written as an event record, and the corresponding item status is
updated in the same service flow. The UI reports success immediately, including
when Firestore has queued the write offline; the offline indicator warns the
crew that synchronization is still pending.”

Return to Rental Detail. The event appears in the live Event History stream,
and the item status is visible in the dashboard without a manual refresh.

### 4. Show the time-to-log metric

On Rental Detail, point to the blue metric above Event History:

“Delivery logged X hours Y minutes after rental start.”

“This metric is calculated from the rental start date and the earliest delivery
event. Because it is inside the events stream, it appears when the delivery is
logged and updates if an earlier delivery event is added.”

### 5. Close with the outcome

“Before Furnly, the conflict and delivery timeline was reconstructed later.
After Furnly, the crew action, item state, conflict visibility, event history,
and time-to-log signal are connected in one live workflow.”

## Technical Walkthrough Notes

- `DispatcherDashboardScreen` listens to active rentals with a Firestore
  `snapshots()` stream.
- `_findConflictGroups` compares every active rental with every other active
  rental, matching shared items and overlapping date ranges. The result maps
  each affected rental ID to all of its conflicting rental IDs.
- The dashboard renders one `ConflictAlert` per map entry. Review navigates to
  the corresponding `RentalDetailScreen`.
- `LogEventScreen` creates the event through `EventService`; the service writes
  the event, updates the item status, and applies pickup billing when needed.
- `RentalDetailScreen` listens to events for the rental and calculates the
  gap from `startDate` to the earliest delivery timestamp.
- Firestore streams keep the dashboard and rental detail views current without
  a manual refresh.

## Verification Checklist

- [ ] Three active rentals share one item and have overlapping date ranges.
- [ ] Dashboard shows three conflict alerts, one for each affected rental.
- [ ] Each Review button opens the correct rental detail.
- [ ] A delivery event appears in Rental Detail and updates the item state.
- [ ] The time-to-log metric shows the expected hours and minutes.
- [ ] Adding an earlier delivery event changes the metric live.
- [ ] Offline event logging shows the pending-sync warning and later syncs.
