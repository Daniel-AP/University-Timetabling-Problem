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

%% A relationship between a group's gaps and their cost

compactCost(Course, Group, Weight, Schedule, Cost) :-
    groupOccupiedSlots(Course, Group, Schedule, OccupiedSlots),
    slotGaps(OccupiedSlots, Gaps),
    Cost is Weight*Gaps.

%% A relationship between a group and its occupied slots

groupOccupiedSlots(Course, Group, Schedule, OccupiedSlots) :-
    findall(
        daySlot(Day, Position),
        (
            member(assignment(Course, Group, _, _, Day, Start, Duration), Schedule),
            occupiedSlot(Start, Duration, Position)
        ),
        RepeatedSlots
    ),
    sort(RepeatedSlots, OccupiedSlots).

%% A relationship between a session start, its length and its occupied slots

occupiedSlot(Start, Duration, Start) :-
    Duration > 0.

occupiedSlot(Start, Duration, Position) :-
    Duration > 1,
    NextStart is Start+1,
    RemainingDuration is Duration-1,
    occupiedSlot(NextStart, RemainingDuration, Position).

%% A relationship between sorted occupied slots and their daily gaps

slotGaps([], 0).

slotGaps([_], 0).

slotGaps([daySlot(Day, Current), daySlot(Day, Next)|OccupiedSlots], Gaps) :-
    slotGaps([daySlot(Day, Next)|OccupiedSlots], RestGaps),
    Gaps is Next-Current-1+RestGaps.

slotGaps([daySlot(Day, _), daySlot(OtherDay, Next)|OccupiedSlots], Gaps) :-
    Day \= OtherDay,
    slotGaps([daySlot(OtherDay, Next)|OccupiedSlots], Gaps).

%% A relationship between penalties and their sum

costSum([], 0).

costSum([Penalty|Penalties], Cost) :-
    costSum(Penalties, RestCost),
    Cost is Penalty+RestCost.
