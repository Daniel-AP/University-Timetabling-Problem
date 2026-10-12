%% A relationship between instance facts and their sessions

sessions(Sessions) :-
    findall([Course, Group, WeeklySessions], group(Course, Group, _, _, WeeklySessions, _, _), Groups),
    buildSessions(Groups, Sessions).

%% A relationship between group requirements and their sessions

buildSessions([], []).

buildSessions([[Course, Group, WeeklySessions]|Groups], Sessions) :-
    groupSessions(Course, Group, 1, WeeklySessions, CurrentSessions),
    buildSessions(Groups, RestSessions),
    append(CurrentSessions, RestSessions, Sessions).

%% A relationship between a group, its session numbers and its sessions

groupSessions(_, _, Ordinal, WeeklySessions, []) :-
    Ordinal > WeeklySessions.

groupSessions(Course, Group, Ordinal, WeeklySessions, [session(Course, Group, Ordinal)|Sessions]) :-
    Ordinal =< WeeklySessions,
    NextOrdinal is Ordinal+1,
    groupSessions(Course, Group, NextOrdinal, WeeklySessions, Sessions).

%% A relationship between sessions and their possible locations

sessionDomains([], []).

sessionDomains([Session|Sessions], [domain(Session, Slots)|Domains]) :-
    sessionDomain(Session, Slots),
    sessionDomains(Sessions, Domains).

%% A relationship between a session and its possible locations

sessionDomain(Session, Slots) :-
    findall(Slot, possibleSlot(Session, Slot), Slots).

%% A relationship between a session and a location it can use

possibleSlot(session(Course, Group, _), slot(Room, Day, Start)) :-
    group(Course, Group, _, Enrolled, _, Duration, Requirement),
    instanceSetting("dias", Days),
    instanceSetting("franjas", DailySlotCount),
    LastStart is DailySlotCount-Duration+1,
    findall(
        Availability,
        (
            teaches(Course, Group, Teacher),
            teacher(Teacher, _, _, Availability)
        ),
        Availabilities
    ),
    room(Room, Capacity, Type),
    Capacity >= Enrolled,
    roomTypeCompatible(Requirement, Type),
    member(Day, Days),
    slotBetween(1, LastStart, Start),
    Start =< DailySlotCount,
    groupAvailable(Availabilities, Day, Start).

%% A relationship between a number range and its numbers in order

slotBetween(CurrentSlot, LastSlot, CurrentSlot) :-
    CurrentSlot =< LastSlot.

slotBetween(CurrentSlot, LastSlot, Slot) :-
    CurrentSlot < LastSlot,
    NextSlot is CurrentSlot+1,
    slotBetween(NextSlot, LastSlot, Slot).

%% A relationship between a requirement and a compatible room type

roomTypeCompatible("teoria", "teoria").

roomTypeCompatible("teoria", "mixta").

roomTypeCompatible("laboratorio", "laboratorio").

roomTypeCompatible("laboratorio", "mixta").

roomTypeCompatible("mixta", _).

%% A relationship between group teachers and a start they can all use

groupAvailable([], _, _).

groupAvailable([Availability|Availabilities], Day, Start) :-
    availableStart(Availability, Day, Start),
    groupAvailable(Availabilities, Day, Start).

%% A relationship between availability and a session start

availableStart(all, _, _).

availableStart([dayRange(daySlot(Day, FirstSlot), daySlot(Day, LastSlot))|_], Day, Start) :-
    Start >= FirstSlot,
    Start =< LastSlot,
    !.

availableStart([_|Ranges], Day, Start) :-
    availableStart(Ranges, Day, Start).
