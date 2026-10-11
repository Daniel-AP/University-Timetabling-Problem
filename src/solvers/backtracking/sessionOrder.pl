%% A relationship between a candidate session and the order of assigned sessions

checkSessionOrder(_, _, []).

checkSessionOrder(Session, Slot, [tentativeAssignment(OtherSession, OtherSlot)|AssignedSessions]) :-
    checkPairOrder(Session, Slot, OtherSession, OtherSlot),
    checkSessionOrder(Session, Slot, AssignedSessions).

%% A relationship between session numbers and their time order

checkPairOrder(session(Course, _, _), _, session(OtherCourse, _, _), _) :-
    Course \= OtherCourse.

checkPairOrder(session(Course, Group, _), _, session(Course, OtherGroup, _), _) :-
    Group \= OtherGroup.

checkPairOrder(session(Course, Group, Ordinal), Slot, session(Course, Group, OtherOrdinal), OtherSlot) :-
    Ordinal < OtherOrdinal,
    slotBefore(Slot, OtherSlot).

checkPairOrder(session(Course, Group, Ordinal), Slot, session(Course, Group, OtherOrdinal), OtherSlot) :-
    Ordinal > OtherOrdinal,
    slotBefore(OtherSlot, Slot).

%% A relationship between an earlier location and a later location

slotBefore(slot(_, Day, Start), slot(_, Day, OtherStart)) :-
    Start < OtherStart.

slotBefore(slot(_, Day, _), slot(_, OtherDay, _)) :-
    instanceSetting("dias", Days),
    append(_, [Day|LaterDays], Days),
    member(OtherDay, LaterDays).
