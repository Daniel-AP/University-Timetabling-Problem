%% A relationship between a complete schedule and its validity

checkSchedule(Schedule) :-
    checkAssignments(Schedule),
    findall(
        [Course, Group, WeeklySessions],
        group(Course, Group, _, _, WeeklySessions, _, _),
        Groups
    ),
    checkGroups(Groups, Schedule),
    checkPairs(Schedule),
    findall([Teacher, MaxSlots], teacher(Teacher, _, MaxSlots, _), Teachers),
    checkTeachers(Teachers, Schedule).

%% A relationship between assignments and their individual validity

checkAssignments([]).

checkAssignments([Assignment|Assignments]) :-
    checkAssignment(Assignment),
    checkAssignments(Assignments).

%% A relationship between an assignment and its individual restrictions

checkAssignment(assignment(Course, Group, Professors, Room, Day, Start, Duration)) :-
    group(Course, Group, _, Enrolled, _, Duration, Requirement),
    groupTeachers(Course, Group, Teachers),
    sort(Professors, Teachers),
    length(Teachers, TeacherCount),
    length(Professors, TeacherCount),
    room(Room, Capacity, Type),
    Capacity >= Enrolled,
    roomTypeCompatible(Requirement, Type),
    instanceSetting("dias", Days),
    member(Day, Days),
    instanceSetting("franjas", Slots),
    Start >= 1, Start =< Slots,
    Last is Start+Duration-1,
    Last =< Slots,
    findall(
        Availability,
        (member(Teacher, Teachers), teacher(Teacher, _, _, Availability)),
        Availabilities
    ),
    groupAvailable(Availabilities, Day, Start),
    allowedSlot(Course, Group, slot(Room, Day, Start)).

%% A relationship between group requirements and their exact session counts

checkGroups([], _).

checkGroups([[Course, Group, WeeklySessions]|Groups], Schedule) :-
    findall(
        1,
        member(assignment(Course, Group, _, _, _, _, _), Schedule),
        Matches
    ),
    length(Matches, WeeklySessions),
    checkGroups(Groups, Schedule).

%% A relationship between distinct session pairs and their lack of conflicts

checkPairs([]).

checkPairs([Assignment|Assignments]) :-
    \+ (member(Other, Assignments), assignmentConflict(Assignment, Other)),
    checkPairs(Assignments).

%% A relationship between two assignments and a hard conflict

assignmentConflict(First, Second) :-
    First = assignment(Course, Group, _, _, _, _, _),
    Second = assignment(Course, Group, _, _, _, _, _),
    assignmentOverlap(First, Second).

assignmentConflict(First, Second) :-
    First = assignment(_, _, _, Room, _, _, _),
    Second = assignment(_, _, _, Room, _, _, _),
    assignmentOverlap(First, Second).

assignmentConflict(First, Second) :-
    First = assignment(_, _, Teachers, _, _, _, _),
    Second = assignment(_, _, OtherTeachers, _, _, _, _),
    member(Teacher, Teachers),
    member(Teacher, OtherTeachers),
    assignmentOverlap(First, Second).

assignmentConflict(First, Second) :-
    First = assignment(Course, Group, _, _, _, _, _),
    Second = assignment(OtherCourse, OtherGroup, _, _, _, _, _),
    exclusiveGroups(Course, Group, OtherCourse, OtherGroup),
    assignmentOverlap(First, Second).

assignmentConflict(First, Second) :-
    First = assignment(Course, Group, _, _, _, _, _),
    Second = assignment(OtherCourse, OtherGroup, _, _, _, _, _),
    exclusiveGroups(OtherCourse, OtherGroup, Course, Group),
    assignmentOverlap(First, Second).

%% A relationship between two assignments and their positive occupied overlap

assignmentOverlap(assignment(_, _, _, _, Day, Start, Duration),
        assignment(_, _, _, _, Day, OtherStart, OtherDuration)) :-
    Duration > 0, OtherDuration > 0,
    End is Start+Duration,
    OtherEnd is OtherStart+OtherDuration,
    Start < OtherEnd, OtherStart < End.

%% A relationship between teachers and their respected weekly limits

checkTeachers([], _).

checkTeachers([[Teacher, MaxSlots]|Teachers], Schedule) :-
    teacherLoad(Teacher, Schedule, Load),
    Load =< MaxSlots,
    checkTeachers(Teachers, Schedule).

%% A relationship between a group and its distinct registered teachers

groupTeachers(Course, Group, Teachers) :-
    findall(Teacher, teaches(Course, Group, Teacher), RepeatedTeachers),
    sort(RepeatedTeachers, Teachers).

%% A relationship between a teacher and the load of physical sessions

teacherLoad(_, [], 0).

teacherLoad(Teacher, [assignment(_, _, Teachers, _, _, _, Duration)|Assignments], Load) :-
    member(Teacher, Teachers),
    teacherLoad(Teacher, Assignments, RestLoad),
    Load is Duration+RestLoad.

teacherLoad(Teacher, [assignment(_, _, Teachers, _, _, _, _)|Assignments], Load) :-
    \+ member(Teacher, Teachers),
    teacherLoad(Teacher, Assignments, Load).
