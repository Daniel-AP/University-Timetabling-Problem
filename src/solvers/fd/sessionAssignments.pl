%% A relationship between completed finite domain sessions and their schedule

fdAssignmentsSchedule([], _, []).

fdAssignmentsSchedule([fdSession(Session, RoomIndex, DayIndex, Start, _)|Model], Maps, [Assignment|Schedule]) :-
    ground([RoomIndex, DayIndex, Start]),
    Maps = indexMaps(Rooms, Days),
    fdIndexValue(Rooms, RoomIndex, Room),
    fdIndexValue(Days, DayIndex, Day),
    sessionAssignment(Session, slot(Room, Day, Start), Assignment),
    fdAssignmentsSchedule(Model, Maps, Schedule).
