%% A relationship between instance facts and errors that prevent a solution

instanceInconsistencies(Errors) :-
    findall(
        [Course, Group, WeeklySessions, Duration],
        group(Course, Group, _, _, WeeklySessions, Duration, _),
        Groups
    ),
    findall(
        Message,
        (
            member([Course, Group, _, _], Groups),
            groupInconsistency(Course, Group, Message)
        ),
        GroupErrors
    ),
    findall(
        Message,
        (
            teacher(Teacher, _, _, _),
            teacherInconsistency(Teacher, Groups, Message)
        ),
        TeacherErrors
    ),
    append(GroupErrors, TeacherErrors, Errors).

%% A relationship between a group and an error that prevents a solution

groupInconsistency(Course, Group, Message) :-
    group(Course, Group, _, Enrolled, WeeklySessions, _, Requirement),
    WeeklySessions > 0,
    \+ groupHasRoom(Enrolled, Requirement),
    append("Group ", Course, Message1),
    append(Message1, "/", Message2),
    append(Message2, Group, Message3),
    append(Message3, ": No room with the required type and capacity", Message).

groupInconsistency(Course, Group, Message) :-
    group(Course, Group, _, Enrolled, WeeklySessions, _, Requirement),
    WeeklySessions > 0,
    groupHasRoom(Enrolled, Requirement),
    groupAllowedSlots(Course, Group, []),
    append("Group ", Course, Message1),
    append(Message1, "/", Message2),
    append(Message2, Group, Message3),
    append(Message3, ": No allowed location", Message).

groupInconsistency(Course, Group, Message) :-
    group(Course, Group, _, _, WeeklySessions, Duration, _),
    WeeklySessions > 0,
    Duration > 0,
    groupAllowedSlots(Course, Group, Slots),
    Slots = [_|_],
    findall(daySlot(Day, Start), member(slot(_, Day, Start), Slots), RepeatedTimes),
    sort(RepeatedTimes, Times),
    groupSessionCapacity(Times, Duration, SessionCapacity),
    WeeklySessions > SessionCapacity,
    number_codes(WeeklySessions, WeeklyDigits),
    number_codes(SessionCapacity, MaxDigits),
    append("Group ", Course, Message1),
    append(Message1, "/", Message2),
    append(Message2, Group, Message3),
    append(Message3, ": Required sessions ", Message4),
    append(Message4, WeeklyDigits, Message5),
    append(Message5, " exceed the number that fit ", Message6),
    append(Message6, MaxDigits, Message).

%% A relationship between group requirements and a suitable room

groupHasRoom(Enrolled, Requirement) :-
    room(_, Capacity, Type),
    Capacity >= Enrolled,
    roomTypeCompatible(Requirement, Type),
    !.

%% A relationship between a group and its allowed locations

groupAllowedSlots(Course, Group, Slots) :-
    group(Course, Group, _, _, _, _, _),
    sessionDomain(session(Course, Group, 1), BaseSlots),
    findall(
        slot(Room, Day, Start),
        (
            member(slot(Room, Day, Start), BaseSlots),
            allowedSlot(Course, Group, slot(Room, Day, Start))
        ),
        Slots
    ).

%% A relationship between session starts and the maximum number of sessions that fit

groupSessionCapacity([], _, 0).

groupSessionCapacity([daySlot(Day, Start)|Times], Duration, SessionCapacity) :-
    NextStart is Start+Duration,
    findall(
        daySlot(OtherDay, OtherStart),
        (
            member(daySlot(OtherDay, OtherStart), Times),
            \+ (
                OtherDay = Day,
                OtherStart < NextStart
            )
        ),
        RemainingTimes
    ),
    groupSessionCapacity(RemainingTimes, Duration, RestCapacity),
    SessionCapacity is RestCapacity+1.

%% A relationship between a teacher and an error that prevents a solution

teacherInconsistency(Teacher, Groups, Message) :-
    teacher(Teacher, _, MaxSlots, _),
    teacherRequiredSlots(Teacher, Groups, RequiredSlots),
    RequiredSlots > MaxSlots,
    number_codes(RequiredSlots, RequiredDigits),
    number_codes(MaxSlots, MaxDigits),
    append("Teacher ", Teacher, Message1),
    append(Message1, ": Required slots ", Message2),
    append(Message2, RequiredDigits, Message3),
    append(Message3, " exceed the weekly limit ", Message4),
    append(Message4, MaxDigits, Message).

teacherInconsistency(Teacher, Groups, Message) :-
    teacherRequiredSlots(Teacher, Groups, RequiredSlots),
    teacherSlotCoverage(Teacher, Groups, Coverage),
    RequiredSlots > Coverage,
    number_codes(RequiredSlots, RequiredDigits),
    number_codes(Coverage, CoverageDigits),
    append("Teacher ", Teacher, Message1),
    append(Message1, ": Required slots ", Message2),
    append(Message2, RequiredDigits, Message3),
    append(Message3, " exceed available slots ", Message4),
    append(Message4, CoverageDigits, Message).

%% A relationship between a teacher and a group they teach

teacherHasGroup(Teacher, Course, Group) :-
    teaches(Course, Group, Teacher),
    !.

%% A relationship between a teacher's groups and their required weekly slots

teacherRequiredSlots(_, [], 0).

teacherRequiredSlots(Teacher, [[_, _, 0, _]|Groups], RequiredSlots) :-
    teacherRequiredSlots(Teacher, Groups, RequiredSlots).

teacherRequiredSlots(Teacher, [[Course, Group, WeeklySessions, _]|Groups], RequiredSlots) :-
    WeeklySessions > 0,
    \+ teacherHasGroup(Teacher, Course, Group),
    teacherRequiredSlots(Teacher, Groups, RequiredSlots).

teacherRequiredSlots(Teacher, [[Course, Group, WeeklySessions, Duration]|Groups], RequiredSlots) :-
    WeeklySessions > 0,
    teacherHasGroup(Teacher, Course, Group),
    teacherRequiredSlots(Teacher, Groups, RestRequiredSlots),
    RequiredSlots is WeeklySessions*Duration+RestRequiredSlots.

%% A relationship between a teacher and their possible slot count

teacherSlotCoverage(Teacher, Groups, Coverage) :-
    findall(
        daySlot(Day, Position),
        (
            member([Course, Group, WeeklySessions, Duration], Groups),
            WeeklySessions > 0,
            teacherHasGroup(Teacher, Course, Group),
            groupAllowedSlots(Course, Group, Slots),
            member(slot(_, Day, Start), Slots),
            LastSlot is Start+Duration-1,
            slotBetween(Start, LastSlot, Position)
        ),
        RepeatedTimes
    ),
    sort(RepeatedTimes, CoveredTimes),
    length(CoveredTimes, Coverage).
