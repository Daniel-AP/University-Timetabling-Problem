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
    isRoomTypeCompatible(Requirement, Type),
    member(Day, Days),
    slotBetween(1, LastStart, Start),
    Start =< DailySlotCount,
    isGroupAvailable(Availabilities, Day, Start).

%% A relationship between a number range and its numbers in order

slotBetween(CurrentSlot, LastSlot, CurrentSlot) :-
    CurrentSlot =< LastSlot.

slotBetween(CurrentSlot, LastSlot, Slot) :-
    CurrentSlot < LastSlot,
    NextSlot is CurrentSlot+1,
    slotBetween(NextSlot, LastSlot, Slot).

%% A relationship between a requirement and a compatible room type

isRoomTypeCompatible("teoria", "teoria").

isRoomTypeCompatible("teoria", "mixta").

isRoomTypeCompatible("laboratorio", "laboratorio").

isRoomTypeCompatible("laboratorio", "mixta").

isRoomTypeCompatible("mixta", _).

%% A relationship between group teachers and a start they can all use

isGroupAvailable([], _, _).

isGroupAvailable([Availability|Availabilities], Day, Start) :-
    isAvailableStart(Availability, Day, Start),
    isGroupAvailable(Availabilities, Day, Start).

%% A relationship between availability and a session start

isAvailableStart(all, _, _).

isAvailableStart([dayRange(daySlot(Day, FirstSlot), daySlot(Day, LastSlot))|_], Day, Start) :-
    Start >= FirstSlot,
    Start =< LastSlot,
    !.

isAvailableStart([_|Ranges], Day, Start) :-
    isAvailableStart(Ranges, Day, Start).
