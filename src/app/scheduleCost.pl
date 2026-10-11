%% A relationship between a complete schedule and its cost

scheduleCost(Schedule, Cost) :-
    findall(
        Penalty,
        (
            preferredSlot(Course, Group, Day, Start, Weight),
            preferenceCost(Course, Group, Day, Start, Weight, Schedule, Penalty)
        ),
        PreferenceCosts
    ),
    findall(
        Penalty,
        (
            compactGroup(Course, Group, Weight),
            compactCost(Course, Group, Weight, Schedule, Penalty)
        ),
        CompactCosts
    ),
    costSum(PreferenceCosts, PreferenceTotal),
    costSum(CompactCosts, CompactTotal),
    Cost is PreferenceTotal+CompactTotal.

%% A relationship between a preferred start and its penalty

preferenceCost(Course, Group, Day, Start, _, Schedule, 0) :-
    \+ \+ member(assignment(Course, Group, _, _, Day, Start, _), Schedule).

preferenceCost(Course, Group, Day, Start, Weight, Schedule, Weight) :-
    \+ member(assignment(Course, Group, _, _, Day, Start, _), Schedule).

%% A relationship between a group's gaps and their weighted penalty

compactCost(Course, Group, Weight, Schedule, Cost) :-
    groupOccupation(Course, Group, Schedule, Occupied),
    slotGaps(Occupied, Gaps),
    Cost is Weight*Gaps.

%% A relationship between a group and its distinct occupied slots

groupOccupation(Course, Group, Schedule, Occupied) :-
    findall(
        daySlot(Day, Position),
        (
            member(assignment(Course, Group, _, _, Day, Start, Duration), Schedule),
            occupiedSlot(Start, Duration, Position)
        ),
        RepeatedSlots
    ),
    sort(RepeatedSlots, Occupied).

%% A relationship between a session's start, duration and occupied positions

occupiedSlot(Start, Duration, Start) :-
    Duration > 0.

occupiedSlot(Start, Duration, Position) :-
    Duration > 1,
    NextStart is Start+1,
    RemainingDuration is Duration-1,
    occupiedSlot(NextStart, RemainingDuration, Position).

%% A relationship between sorted distinct occupied slots and their daily gaps

slotGaps([], 0).

slotGaps([_], 0).

slotGaps([daySlot(Day, Current), daySlot(Day, Next)|Slots], Gaps) :-
    slotGaps([daySlot(Day, Next)|Slots], RestGaps),
    Gaps is Next-Current-1+RestGaps.

slotGaps([daySlot(Day, _), daySlot(OtherDay, Next)|Slots], Gaps) :-
    Day \= OtherDay,
    slotGaps([daySlot(OtherDay, Next)|Slots], Gaps).

%% A relationship between penalties and their sum

costSum([], 0).

costSum([Penalty|Penalties], Cost) :-
    costSum(Penalties, RestCost),
    Cost is Penalty+RestCost.
