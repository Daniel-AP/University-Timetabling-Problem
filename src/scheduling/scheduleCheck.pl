%% A relationship between a complete schedule and its validity

checkSchedule(Schedule) :-
    checkAssignments(Schedule),
    findall([Course, Group, WeeklySessions], group(Course, Group, _, _, WeeklySessions, _, _), Groups),
    checkGroupSessionCounts(Groups, Schedule),
    checkAssignmentPairs(Schedule),
    findall([Teacher, MaxSlots], teacher(Teacher, _, MaxSlots, _), TeacherLimits),
    checkTeacherLoads(TeacherLimits, Schedule).

%% A relationship between assignments and their validity

checkAssignments([]).

checkAssignments([Assignment|Assignments]) :-
    checkAssignment(Assignment),
    checkAssignments(Assignments).

%% A relationship between an assignment and its rules

checkAssignment(assignment(Course, Group, GivenTeachers, Room, Day, Start, Duration)) :-
    group(Course, Group, _, Enrolled, _, Duration, Requirement),
    groupTeachers(Course, Group, ExpectedTeachers),
    sort(GivenTeachers, ExpectedTeachers),
    length(ExpectedTeachers, TeacherCount),
    length(GivenTeachers, TeacherCount),
    room(Room, Capacity, Type),
    Capacity >= Enrolled,
    isRoomTypeCompatible(Requirement, Type),
    instanceSetting("dias", Days),
    member(Day, Days),
    instanceSetting("franjas", DailySlotCount),
    Start >= 1,
    Start =< DailySlotCount,
    LastSlot is Start+Duration-1,
    LastSlot =< DailySlotCount,
    findall(
        Availability,
        (
            member(Teacher, ExpectedTeachers),
            teacher(Teacher, _, _, Availability)
        ),
        Availabilities
    ),
    isGroupAvailable(Availabilities, Day, Start),
    isAllowedSlot(Course, Group, slot(Room, Day, Start)).

%% A relationship between groups and their required session counts

checkGroupSessionCounts([], _).

checkGroupSessionCounts([[Course, Group, WeeklySessions]|Groups], Schedule) :-
    findall(1, member(assignment(Course, Group, _, _, _, _, _), Schedule), Matches),
    length(Matches, WeeklySessions),
    checkGroupSessionCounts(Groups, Schedule).

%% A relationship between assignments and their lack of conflicts

checkAssignmentPairs([]).

checkAssignmentPairs([Assignment|Assignments]) :-
    \+ (
        member(Other, Assignments),
        hasAssignmentConflict(Assignment, Other)
    ),
    checkAssignmentPairs(Assignments).

%% A relationship between two assignments and a hard conflict

hasAssignmentConflict(First, Second) :-
    First = assignment(Course, Group, _, _, _, _, _),
    Second = assignment(Course, Group, _, _, _, _, _),
    hasAssignmentOverlap(First, Second).

hasAssignmentConflict(First, Second) :-
    First = assignment(_, _, _, Room, _, _, _),
    Second = assignment(_, _, _, Room, _, _, _),
    hasAssignmentOverlap(First, Second).

hasAssignmentConflict(First, Second) :-
    First = assignment(_, _, Teachers, _, _, _, _),
    Second = assignment(_, _, OtherTeachers, _, _, _, _),
    member(Teacher, Teachers),
    member(Teacher, OtherTeachers),
    hasAssignmentOverlap(First, Second).

hasAssignmentConflict(First, Second) :-
    First = assignment(Course, Group, _, _, _, _, _),
    Second = assignment(OtherCourse, OtherGroup, _, _, _, _, _),
    exclusiveGroups(Course, Group, OtherCourse, OtherGroup),
    hasAssignmentOverlap(First, Second).

hasAssignmentConflict(First, Second) :-
    First = assignment(Course, Group, _, _, _, _, _),
    Second = assignment(OtherCourse, OtherGroup, _, _, _, _, _),
    exclusiveGroups(OtherCourse, OtherGroup, Course, Group),
    hasAssignmentOverlap(First, Second).

%% A relationship between two assignments and their shared time

hasAssignmentOverlap(assignment(_, _, _, _, Day, Start, Duration), assignment(_, _, _, _, Day, OtherStart, OtherDuration)) :-
    Duration > 0,
    OtherDuration > 0,
    EndExclusive is Start+Duration,
    OtherEndExclusive is OtherStart+OtherDuration,
    Start < OtherEndExclusive,
    OtherStart < EndExclusive.

%% A relationship between teachers and their weekly limits

checkTeacherLoads([], _).

checkTeacherLoads([[Teacher, MaxSlots]|TeacherLimits], Schedule) :-
    teacherAssignedSlots(Teacher, Schedule, AssignedSlots),
    AssignedSlots =< MaxSlots,
    checkTeacherLoads(TeacherLimits, Schedule).

%% A relationship between a teacher and their weekly slot count

teacherAssignedSlots(_, [], 0).

teacherAssignedSlots(Teacher, [assignment(_, _, Teachers, _, _, _, Duration)|Assignments], AssignedSlots) :-
    member(Teacher, Teachers),
    teacherAssignedSlots(Teacher, Assignments, RestAssignedSlots),
    AssignedSlots is Duration+RestAssignedSlots.

teacherAssignedSlots(Teacher, [assignment(_, _, Teachers, _, _, _, _)|Assignments], AssignedSlots) :-
    \+ member(Teacher, Teachers),
    teacherAssignedSlots(Teacher, Assignments, AssignedSlots).
