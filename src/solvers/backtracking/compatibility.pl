%% A relationship between a candidate location and its compatibility with a branch

compatibleAssignment(Session, Slot, AssignedSessions) :-
    Session = session(Course, Group, _),
    allowedSlot(Course, Group, Slot),
    sessionAssignment(Session, Slot, Assignment),
    findall(
        OtherAssignment,
        (
            member(tentativeAssignment(OtherSession, OtherSlot), AssignedSessions),
            sessionAssignment(OtherSession, OtherSlot, OtherAssignment)
        ),
        Assignments
    ),
    \+ (member(Other, Assignments), assignmentConflict(Assignment, Other)),
    Assignment = assignment(_, _, Teachers, _, _, _, _),
    findall(
        [Teacher, MaxSlots],
        (member(Teacher, Teachers), teacher(Teacher, _, MaxSlots, _)),
        Limits
    ),
    checkTeachers(Limits, [Assignment|Assignments]).

%% A relationship between a session location and its common assignment representation

sessionAssignment(session(Course, Group, _), slot(Room, Day, Start), assignment(Course, Group, Teachers, Room, Day, Start, Duration)) :-
    group(Course, Group, _, _, _, Duration, _),
    groupTeachers(Course, Group, Teachers).
