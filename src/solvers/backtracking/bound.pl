%% A relationship between a branch and a lower bound on its cost

lowerBound(btState(PendingSessions, AssignedSessions), Bound) :-
    findall(
        Assignment,
        (
            member(tentativeAssignment(Session, Slot), AssignedSessions),
            sessionAssignment(Session, Slot, Assignment)
        ),
        Assignments
    ),
    findall(
        Penalty,
        (
            preferredSlot(Course, Group, Day, Start, Weight),
            completeGroup(Course, Group, PendingSessions),
            preferenceCost(Course, Group, Day, Start, Weight, Assignments, Penalty)
        ),
        PreferenceCosts
    ),
    findall(
        Penalty,
        (
            compactGroup(Course, Group, Weight),
            completeGroup(Course, Group, PendingSessions),
            compactCost(Course, Group, Weight, Assignments, Penalty)
        ),
        CompactCosts
    ),
    costSum(PreferenceCosts, PreferenceTotal),
    costSum(CompactCosts, CompactTotal),
    Bound is PreferenceTotal+CompactTotal.

%% A relationship between a group and the absence of its pending sessions

completeGroup(Course, Group, PendingSessions) :-
    \+ member(session(Course, Group, _), PendingSessions).
