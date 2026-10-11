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
    append(Message3, ": No compatible room with sufficient capacity", Message).

groupInconsistency(Course, Group, Message) :-
    group(Course, Group, _, Enrolled, WeeklySessions, _, Requirement),
    WeeklySessions > 0,
    groupHasRoom(Enrolled, Requirement),
    groupSlots(Course, Group, []),
    append("Group ", Course, Message1),
    append(Message1, "/", Message2),
    append(Message2, Group, Message3),
    append(Message3, ": No permitted location", Message).

groupInconsistency(Course, Group, Message) :-
    group(Course, Group, _, _, WeeklySessions, Duration, _),
    WeeklySessions > 0, Duration > 0,
    groupSlots(Course, Group, Slots),
    Slots = [_|_],
    findall(daySlot(Day, Start), member(slot(_, Day, Start), Slots), RepeatedTimes),
    sort(RepeatedTimes, Times),
    groupMaxSessions(Times, Duration, MaxSessions),
    WeeklySessions > MaxSessions,
    number_codes(WeeklySessions, WeeklyDigits),
    number_codes(MaxSessions, MaxDigits),
    append("Group ", Course, Message1),
    append(Message1, "/", Message2),
    append(Message2, Group, Message3),
    append(Message3, ": Required sessions ", Message4),
    append(Message4, WeeklyDigits, Message5),
    append(Message5, " exceed temporal capacity ", Message6),
    append(Message6, MaxDigits, Message).

%% A relationship between group requirements and a suitable room

groupHasRoom(Enrolled, Requirement) :-
    room(_, Capacity, Type),
    Capacity >= Enrolled,
    roomTypeCompatible(Requirement, Type), !.

%% A relationship between a group and its allowed locations

groupSlots(Course, Group, Slots) :-
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

groupMaxSessions([], _, 0).

groupMaxSessions([daySlot(Day, Start)|Times], Duration, MaxSessions) :-
    NextStart is Start+Duration,
    findall(
        daySlot(OtherDay, OtherStart),
        (
            member(daySlot(OtherDay, OtherStart), Times),
            \+ (OtherDay = Day, OtherStart < NextStart)
        ),
        RemainingTimes
    ),
    groupMaxSessions(RemainingTimes, Duration, RestMax),
    MaxSessions is RestMax+1.

%% A relationship between a teacher and an error that prevents a solution

teacherInconsistency(Teacher, Groups, Message) :-
    teacher(Teacher, _, MaxSlots, _),
    teacherDemand(Teacher, Groups, Demand),
    Demand > MaxSlots,
    number_codes(Demand, DemandDigits),
    number_codes(MaxSlots, MaxDigits),
    append("Teacher ", Teacher, Message1),
    append(Message1, ": Required slots ", Message2),
    append(Message2, DemandDigits, Message3),
    append(Message3, " exceed weekly maximum ", Message4),
    append(Message4, MaxDigits, Message).

teacherInconsistency(Teacher, Groups, Message) :-
    teacherDemand(Teacher, Groups, Demand),
    teacherMaxCoverage(Teacher, Groups, Coverage),
    Demand > Coverage,
    number_codes(Demand, DemandDigits),
    number_codes(Coverage, CoverageDigits),
    append("Teacher ", Teacher, Message1),
    append(Message1, ": Required slots ", Message2),
    append(Message2, DemandDigits, Message3),
    append(Message3, " exceed possible coverage ", Message4),
    append(Message4, CoverageDigits, Message).

%% A relationship between a teacher and a group they teach

teacherHasGroup(Teacher, Course, Group) :-
    teaches(Course, Group, Teacher), !.

%% A relationship between a teacher's groups and their required weekly slots

teacherDemand(_, [], 0).

teacherDemand(Teacher, [[_, _, 0, _]|Groups], Demand) :-
    teacherDemand(Teacher, Groups, Demand).

teacherDemand(Teacher, [[Course, Group, WeeklySessions, _]|Groups], Demand) :-
    WeeklySessions > 0,
    \+ teacherHasGroup(Teacher, Course, Group),
    teacherDemand(Teacher, Groups, Demand).

teacherDemand(Teacher, [[Course, Group, WeeklySessions, Duration]|Groups], Demand) :-
    WeeklySessions > 0,
    teacherHasGroup(Teacher, Course, Group),
    teacherDemand(Teacher, Groups, RestDemand),
    Demand is WeeklySessions*Duration+RestDemand.

%% A relationship between a teacher and their possible slot count

teacherMaxCoverage(Teacher, Groups, Coverage) :-
    findall(
        daySlot(Day, Position),
        (
            member([Course, Group, WeeklySessions, Duration], Groups),
            WeeklySessions > 0,
            teacherHasGroup(Teacher, Course, Group),

            groupSlots(Course, Group, Slots),
            member(slot(_, Day, Start), Slots),

            Last is Start + Duration - 1,
            startBetween(Start, Last, Position)
        ),
        RepeatedTimes
    ),

    sort(RepeatedTimes, CoveredTimes),
    length(CoveredTimes, Coverage).
