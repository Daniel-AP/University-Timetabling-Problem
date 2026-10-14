%% A relationship between instance facts and their finite domain model

fdPrepareModel(Model, Maps) :-
    findall(Room, room(Room, _, _), Rooms),
    instanceSetting("dias", Days),
    length(Rooms, RoomCount),
    length(Days, DayCount),
    instanceSetting("franjas", DailySlotCount),
    fd_vector_max(CurrentVectorMax),
    RequiredVectorMax is max(CurrentVectorMax, max(RoomCount, max(DayCount, DailySlotCount))),
    fd_set_vector_max(RequiredVectorMax),
    Maps = indexMaps(Rooms, Days),
    sessions(Sessions),
    fdPrepareSessions(Sessions, Maps, Model).

%% A relationship between sessions and their finite domain model

fdPrepareSessions([], _, []).

fdPrepareSessions([Session|Sessions], Maps, [fdSession(Session, RoomIndex, DayIndex, Start, Tuples)|Model]) :-
    Session = session(Course, Group, _),
    Maps = indexMaps(Rooms, Days),
    group(Course, Group, _, _, _, Duration, _),
    instanceSetting("franjas", DailySlotCount),
    length(Rooms, RoomCount),
    length(Days, DayCount),
    LastStart is DailySlotCount-Duration+1,
    findall(Tuple, fdIndexedSlot(Session, Maps, Tuple), Tuples),
    Tuples = [_|_],
    fd_domain(RoomIndex, 1, RoomCount),
    fd_domain(DayIndex, 1, DayCount),
    fd_domain(Start, 1, LastStart),
    fd_relation(Tuples, [RoomIndex, DayIndex, Start]),
    fdPrepareSessions(Sessions, Maps, Model).

%% A relationship between a session and its indexed locations

fdIndexedSlot(Session, indexMaps(Rooms, Days), [RoomIndex, DayIndex, Start]) :-
    possibleSlot(Session, slot(Room, Day, Start)),
    nth(RoomIndex, Rooms, Room),
    nth(DayIndex, Days, Day).
