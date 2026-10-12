%% A relationship between a location and the assignments it can join

btCompatibleSlot(Session, Slot, AssignedSessions) :-
    Session = session(Course, Group, _),
    allowedSlot(Course, Group, Slot),
    sessionAssignment(Session, Slot, Assignment),
    assignmentsSchedule(AssignedSessions, Assignments),
    \+ (
        member(Other, Assignments),
        assignmentConflict(Assignment, Other)
    ),
    Assignment = assignment(_, _, Teachers, _, _, _, _),
    findall(
        [Teacher, MaxSlots],
        (
            member(Teacher, Teachers),
            teacher(Teacher, _, MaxSlots, _)
        ),
        TeacherLimits
    ),
    checkTeacherLoads(TeacherLimits, [Assignment|Assignments]).

%% A relationship between a session domain and its compatible locations

btCompatibleSlots(_, [], _, []).

btCompatibleSlots(Session, [Slot|Slots], AssignedSessions, CompatibleSlots) :-
    btCompatibleSlot(Session, Slot, AssignedSessions),
    !,
    CompatibleSlots = [Slot|RestCompatibleSlots],
    btCompatibleSlots(Session, Slots, AssignedSessions, RestCompatibleSlots).

btCompatibleSlots(Session, [_|Slots], AssignedSessions, CompatibleSlots) :-
    btCompatibleSlots(Session, Slots, AssignedSessions, CompatibleSlots).
