%% A relationship between instance facts and their finite domain model

fdPrepareModel(Model, Variables, Maps) :-
    findall(Room, room(Room, _, _), Rooms),
    instanceSetting("dias", Days),
    Maps = indexMaps(Rooms, Days),
    sessions(Sessions),
    fdPrepareSessions(Sessions, Maps, Model, Variables).

%% A relationship between sessions and their finite domain variables

fdPrepareSessions([], _, [], []).

fdPrepareSessions([Session|Sessions], Maps, [fdSession(Session, RoomIndex, DayIndex, Start, Tuples)|Model], [RoomIndex, DayIndex, Start|Variables]) :-
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
    fdPrepareSessions(Sessions, Maps, Model, Variables).

%% A relationship between a session and its indexed locations

fdIndexedSlot(Session, indexMaps(Rooms, Days), [RoomIndex, DayIndex, Start]) :-
    possibleSlot(Session, slot(Room, Day, Start)),
    fdIndexValue(Rooms, RoomIndex, Room),
    fdIndexValue(Days, DayIndex, Day).

%% A relationship between an identifier list and an indexed identifier

fdIndexValue(Values, Index, Value) :-
    append(Before, [Value|_], Values),
    length(Before, Position),
    Index is Position+1.
