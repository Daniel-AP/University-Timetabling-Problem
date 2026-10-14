%% A relationship between a heuristic and sorted compatible locations

fdOrderSlots(original, _, Slots, _, _, Slots).

fdOrderSlots(mrv, _, Slots, _, _, Slots).

fdOrderSlots(degree, _, Slots, _, _, Slots).

fdOrderSlots(demand, _, Slots, _, _, Slots).

fdOrderSlots(lcv, Session, Slots, Model, Maps, OrderedSlots) :-
    fdPendingSessions(Model, PendingSessions),
    findall(
        OtherSession,
        (
            member(OtherSession, PendingSessions),
            Session \= OtherSession
        ),
        OtherPendingSessions
    ),
    Maps = indexMaps(Rooms, Days),
    member(fdSession(Session, RoomIndex, DayIndex, Start, _), Model),
    findall(
        Key-Slot,
        (
            member(Slot, Slots),
            Slot = slot(Room, Day, TupleStart),
            nth(TupleRoomIndex, Rooms, Room),
            nth(TupleDayIndex, Days, Day),
            RoomIndex = TupleRoomIndex,
            DayIndex = TupleDayIndex,
            Start = TupleStart,
            fdRemainingSlotCount(OtherPendingSessions, Model, Maps, Count),
            Key is -Count
        ),
        Pairs
    ),
    keysort(Pairs, SortedPairs),
    findall(Slot, member(_-Slot, SortedPairs), OrderedSlots).

%% A relationship between pending sessions and their compatible location count

fdRemainingSlotCount([], _, _, 0).

fdRemainingSlotCount([Session|Sessions], Model, Maps, TotalSlotCount) :-
    fdCompatibleSlots(Session, Model, Maps, ViableSlots),
    length(ViableSlots, CurrentSlotCount),
    fdRemainingSlotCount(Sessions, Model, Maps, RestSlotCount),
    TotalSlotCount is CurrentSlotCount+RestSlotCount.
