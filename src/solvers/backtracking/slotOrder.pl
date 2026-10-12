%% A relationship between a heuristic and sorted compatible locations

btOrderSlots(original, _, Slots, _, _, _, Slots).

btOrderSlots(mrv, _, Slots, _, _, _, Slots).

btOrderSlots(degree, _, Slots, _, _, _, Slots).

btOrderSlots(demand, _, Slots, _, _, _, Slots).

btOrderSlots(lcv, Session, CompatibleSlots, OtherPendingSessions, Domains, AssignedSessions, OrderedSlots) :-
    findall(
        Key-Slot,
        (
            member(Slot, CompatibleSlots),
            HypotheticalAssignments = [tentativeAssignment(Session, Slot)|AssignedSessions],
            btRemainingSlotCount(OtherPendingSessions, Domains, HypotheticalAssignments, Count),
            Key is -Count
        ),
        Pairs
    ),
    keysort(Pairs, SortedPairs),
    findall(Slot, member(_-Slot, SortedPairs), OrderedSlots).

%% A relationship between pending sessions and their compatible location count

btRemainingSlotCount([], _, _, 0).

btRemainingSlotCount([Session|Sessions], Domains, AssignedSessions, TotalSlotCount) :-
    member(domain(Session, Slots), Domains),
    btCompatibleSlots(Session, Slots, AssignedSessions, CompatibleSlots),
    length(CompatibleSlots, CurrentSlotCount),
    btRemainingSlotCount(Sessions, Domains, AssignedSessions, RestSlotCount),
    TotalSlotCount is CurrentSlotCount+RestSlotCount.
