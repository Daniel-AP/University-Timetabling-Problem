%% A relationship between a group and its teachers without duplicates

groupTeachers(Course, Group, Teachers) :-
    findall(Teacher, teaches(Course, Group, Teacher), RepeatedTeachers),
    sort(RepeatedTeachers, Teachers).

%% A relationship between a session location and its schedule assignment

sessionAssignment(session(Course, Group, _), slot(Room, Day, Start), assignment(Course, Group, Teachers, Room, Day, Start, Duration)) :-
    group(Course, Group, _, _, _, Duration, _),
    groupTeachers(Course, Group, Teachers).

%% A relationship between assigned sessions and their common schedule

assignmentsSchedule([], []).

assignmentsSchedule([tentativeAssignment(Session, Slot)|AssignedSessions], [Assignment|Schedule]) :-
    sessionAssignment(Session, Slot, Assignment),
    assignmentsSchedule(AssignedSessions, Schedule).
