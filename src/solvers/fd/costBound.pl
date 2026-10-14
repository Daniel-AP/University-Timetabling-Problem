%% A relationship between a finite domain model and a lower bound on its cost

fdCostBound(Model, Maps, Bound) :-
    Maps = indexMaps(Rooms, Days),
    fdPendingSessions(Model, PendingSessions),
    findall(
        Assignment,
        (
            member(fdSession(Session, RoomIndex, DayIndex, Start, _), Model),
            ground([RoomIndex, DayIndex, Start]),
            nth(RoomIndex, Rooms, Room),
            nth(DayIndex, Days, Day),
            sessionAssignment(Session, slot(Room, Day, Start), Assignment)
        ),
        Assignments
    ),
    findall(
        Penalty,
        (
            preferredSlot(Course, Group, Day, Start, Weight),
            fdIsGroupComplete(Course, Group, PendingSessions),
            preferenceCost(Course, Group, Day, Start, Weight, Assignments, Penalty)
        ),
        PreferenceCosts
    ),
    findall(
        Penalty,
        (
            compactGroup(Course, Group, Weight),
            fdIsGroupComplete(Course, Group, PendingSessions),
            compactCost(Course, Group, Weight, Assignments, Penalty)
        ),
        CompactCosts
    ),
    costSum(PreferenceCosts, PreferenceTotal),
    costSum(CompactCosts, CompactTotal),
    Bound is PreferenceTotal+CompactTotal.

%% A relationship between a group and its lack of pending sessions

fdIsGroupComplete(Course, Group, PendingSessions) :-
    \+ member(session(Course, Group, _), PendingSessions).
