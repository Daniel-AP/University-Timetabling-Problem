%% A relationship between a heuristic and sorted compatible locations

sortSlots(original, _, Slots, _, _, _, Slots).

sortSlots(mrv, _, Slots, _, _, _, Slots).

sortSlots(degree, _, Slots, _, _, _, Slots).

sortSlots(demand, _, Slots, _, _, _, Slots).

sortSlots(lcv, Session, CompatibleSlots, OtherPendingSessions, Domains, AssignedSessions, SortedSlots) :-
    findall(
        Key-Slot,
        (
            member(Slot, CompatibleSlots),
            HypotheticalAssignments = [tentativeAssignment(Session, Slot)|AssignedSessions],
            remainingSlotCount(OtherPendingSessions, Domains, HypotheticalAssignments, Count),
            Key is -Count
        ),
        Pairs
    ),
    keysort(Pairs, SortedPairs),
    findall(Slot, member(_-Slot, SortedPairs), SortedSlots).

%% A relationship between pending sessions and their compatible location count

remainingSlotCount([], _, _, 0).

remainingSlotCount([Session|Sessions], Domains, AssignedSessions, Total) :-
    member(domain(Session, Slots), Domains),
    compatibleSlots(Session, Slots, AssignedSessions, CompatibleSlots),
    length(CompatibleSlots, Count),
    remainingSlotCount(Sessions, Domains, AssignedSessions, RestCount),
    Total is Count+RestCount.
