%% A relationship between prepared sessions and their hard constraints

fdConstrainSessions([], _) :-
    findall(
        [Course, Group, WeeklySessions, Duration],
        group(Course, Group, _, _, WeeklySessions, Duration, _),
        Groups
    ),
    findall([Teacher, MaxSlots], teacher(Teacher, _, MaxSlots, _), TeacherLimits),
    fdConstrainTeacherLoads(TeacherLimits, Groups).

fdConstrainSessions([FdSession|Model], Maps) :-
    fdConstrainSessionDomains([FdSession], Maps),
    fdConstrainSessionPairs(FdSession, Model),
    fdConstrainSessions(Model, Maps).

%% A relationship between session domains and their permitted locations

fdConstrainSessionDomains([], _).

fdConstrainSessionDomains([FdSession|Model], indexMaps(Rooms, Days)) :-
    FdSession = fdSession(session(Course, Group, _), RoomIndex, DayIndex, Start, Tuples),
    findall(
        [TupleRoomIndex, TupleDayIndex, TupleStart],
        (
            member([TupleRoomIndex, TupleDayIndex, TupleStart], Tuples),
            fdIndexValue(Rooms, TupleRoomIndex, Room),
            fdIndexValue(Days, TupleDayIndex, Day),
            isAllowedSlot(Course, Group, slot(Room, Day, TupleStart))
        ),
        AllowedTuples
    ),
    AllowedTuples = [_|_],
    fd_relation(AllowedTuples, [RoomIndex, DayIndex, Start]),
    fdConstrainSessionDomains(Model, indexMaps(Rooms, Days)).

%% A relationship between a session and its lack of conflicts with other sessions

fdConstrainSessionPairs(fdSession(session(Course, Group, _), _, _, _, _), _) :-
    group(Course, Group, _, _, _, 0, _),
    !.

fdConstrainSessionPairs(_, []).

fdConstrainSessionPairs(FdSession, [fdSession(session(OtherCourse, OtherGroup, _), _, _, _, _)|Model]) :-
    group(OtherCourse, OtherGroup, _, _, _, 0, _),
    !,
    fdConstrainSessionPairs(FdSession, Model).

fdConstrainSessionPairs(FdSession, [fdSession(OtherSession, _, OtherDayIndex, OtherStart, _)|Model]) :-
    FdSession = fdSession(Session, _, DayIndex, Start, _),
    Session = session(Course, Group, _),
    OtherSession = session(OtherCourse, OtherGroup, _),
    group(Course, Group, _, _, _, Duration, _),
    group(OtherCourse, OtherGroup, _, _, _, OtherDuration, _),
    pairConstraint(Session, OtherSession, Constraint),
    Constraint \= room,
    !,
    (DayIndex #\= OtherDayIndex) #\/
    (Start+Duration #=< OtherStart) #\/
    (OtherStart+OtherDuration #=< Start),
    fdConstrainSessionPairs(FdSession, Model).

fdConstrainSessionPairs(FdSession, [fdSession(OtherSession, OtherRoomIndex, OtherDayIndex, OtherStart, _)|Model]) :-
    FdSession = fdSession(Session, RoomIndex, DayIndex, Start, _),
    Session = session(Course, Group, _),
    OtherSession = session(OtherCourse, OtherGroup, _),
    group(Course, Group, _, _, _, Duration, _),
    group(OtherCourse, OtherGroup, _, _, _, OtherDuration, _),
    (RoomIndex #\= OtherRoomIndex) #\/
    (DayIndex #\= OtherDayIndex) #\/
    (Start+Duration #=< OtherStart) #\/
    (OtherStart+OtherDuration #=< Start),
    fdConstrainSessionPairs(FdSession, Model).

%% A relationship between teacher loads and their weekly limits

fdConstrainTeacherLoads([], _).

fdConstrainTeacherLoads([[Teacher, MaxSlots]|TeacherLimits], Groups) :-
    teacherRequiredSlots(Teacher, Groups, RequiredSlots),
    RequiredSlots =< MaxSlots,
    fdConstrainTeacherLoads(TeacherLimits, Groups).
