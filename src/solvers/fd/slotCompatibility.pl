%% A relationship between a session and its compatible locations

fdCompatibleSlots(Session, Model, Maps, ViableSlots) :-
    Maps = indexMaps(Rooms, Days),
    member(fdSession(Session, RoomIndex, DayIndex, Start, Tuples), Model),
    findall(
        slot(Room, Day, TupleStart),
        (
            member([TupleRoomIndex, TupleDayIndex, TupleStart], Tuples),
            RoomIndex = TupleRoomIndex,
            DayIndex = TupleDayIndex,
            Start = TupleStart,
            fdIndexValue(Rooms, TupleRoomIndex, Room),
            fdIndexValue(Days, TupleDayIndex, Day)
        ),
        ViableSlots
    ).
