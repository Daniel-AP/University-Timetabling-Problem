%% A relationship between a branch and a lower bound on its cost

btCostBound(btState(PendingSessions, AssignedSessions), Bound) :-
    assignmentsSchedule(AssignedSessions, Assignments),
    findall(
        Penalty,
        (
            preferredSlot(Course, Group, Day, Start, Weight),
            btIsGroupComplete(Course, Group, PendingSessions),
            preferenceCost(Course, Group, Day, Start, Weight, Assignments, Penalty)
        ),
        PreferenceCosts
    ),
    findall(
        Penalty,
        (
            compactGroup(Course, Group, Weight),
            btIsGroupComplete(Course, Group, PendingSessions),
            compactCost(Course, Group, Weight, Assignments, Penalty)
        ),
        CompactCosts
    ),
    costSum(PreferenceCosts, PreferenceTotal),
    costSum(CompactCosts, CompactTotal),
    Bound is PreferenceTotal+CompactTotal.

%% A relationship between a group and its lack of pending sessions

btIsGroupComplete(Course, Group, PendingSessions) :-
    \+ member(session(Course, Group, _), PendingSessions).
