%% A relationship between instance facts and their required sessions

sessions(Sessions) :-
    findall([Course, Group, WeeklySessions], group(Course, Group, _, _, WeeklySessions, _, _), Groups),
    buildSessions(Groups, Sessions).

%% A relationship between group requirements and their sessions

buildSessions([], []).

buildSessions([[Course, Group, WeeklySessions]|Groups], Sessions) :-
    groupSessions(Course, Group, 1, WeeklySessions, CurrentSessions),
    buildSessions(Groups, RestSessions),
    append(CurrentSessions, RestSessions, Sessions).

%% A relationship between a group, its weekly ordinals and their sessions

groupSessions(_, _, Ordinal, WeeklySessions, []) :-
    Ordinal > WeeklySessions.

groupSessions(Course, Group, Ordinal, WeeklySessions,
        [session(Course, Group, Ordinal)|Sessions]) :-
    Ordinal =< WeeklySessions,
    NextOrdinal is Ordinal+1,
    groupSessions(Course, Group, NextOrdinal, WeeklySessions, Sessions).

%% A relationship between sessions and their base domains

sessionDomains([], []).

sessionDomains([Session|Sessions], [domain(Session, Slots)|Domains]) :-
    sessionDomain(Session, Slots),
    sessionDomains(Sessions, Domains).

%% A relationship between a session and its individual locations

sessionDomain(Session, Slots) :-
    findall(Slot, possibleSlot(Session, Slot), Slots).

%% A relationship between a session and an individual location it can use

possibleSlot(session(Course, Group, _), slot(Room, Day, Start)) :-
    group(Course, Group, _, Enrolled, _, Duration, Requirement),
    instanceSetting("dias", Days),
    instanceSetting("franjas", Slots),
    LastStart is Slots-Duration+1,
    findall(
        Availability,
        (teaches(Course, Group, Teacher), teacher(Teacher, _, _, Availability)),
        Availabilities
    ),
    room(Room, Capacity, Type),
    Capacity >= Enrolled,
    roomTypeCompatible(Requirement, Type),
    member(Day, Days),
    startBetween(1, LastStart, Start),
    Start =< Slots,
    groupAvailable(Availabilities, Day, Start).

%% A relationship between inclusive bounds and their ascending integers

startBetween(Current, Last, Current) :-
    Current =< Last.

startBetween(Current, Last, Start) :-
    Current < Last,
    Next is Current+1,
    startBetween(Next, Last, Start).

%% A relationship between a requirement and a compatible room type

roomTypeCompatible("teoria", "teoria").

roomTypeCompatible("teoria", "mixta").

roomTypeCompatible("laboratorio", "laboratorio").

roomTypeCompatible("laboratorio", "mixta").

roomTypeCompatible("mixta", _).

%% A relationship between all group teachers and an available start

groupAvailable([], _, _).

groupAvailable([Availability|Availabilities], Day, Start) :-
    availableStart(Availability, Day, Start),
    groupAvailable(Availabilities, Day, Start).

%% A relationship between availability and a concrete session start

availableStart(all, _, _).

availableStart([dayRange(daySlot(Day, First), daySlot(Day, Last))|_], Day, Start) :-
    Start >= First, Start =< Last, !.

availableStart([_|Ranges], Day, Start) :-
    availableStart(Ranges, Day, Start).
