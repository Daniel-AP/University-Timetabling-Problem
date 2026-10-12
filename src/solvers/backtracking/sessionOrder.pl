%% A relationship between a candidate session and the order of assigned sessions

btCheckSessionOrder(_, _, []).

btCheckSessionOrder(Session, Slot, [tentativeAssignment(OtherSession, OtherSlot)|AssignedSessions]) :-
    btCheckSessionPairOrder(Session, Slot, OtherSession, OtherSlot),
    btCheckSessionOrder(Session, Slot, AssignedSessions).

%% A relationship between session numbers and their time order

btCheckSessionPairOrder(session(Course, _, _), _, session(OtherCourse, _, _), _) :-
    Course \= OtherCourse.

btCheckSessionPairOrder(session(Course, Group, _), _, session(Course, OtherGroup, _), _) :-
    Group \= OtherGroup.

btCheckSessionPairOrder(session(Course, Group, Ordinal), Slot, session(Course, Group, OtherOrdinal), OtherSlot) :-
    Ordinal < OtherOrdinal,
    btSlotBefore(Slot, OtherSlot).

btCheckSessionPairOrder(session(Course, Group, Ordinal), Slot, session(Course, Group, OtherOrdinal), OtherSlot) :-
    Ordinal > OtherOrdinal,
    btSlotBefore(OtherSlot, Slot).

%% A relationship between an earlier location and a later location

btSlotBefore(slot(_, Day, Start), slot(_, Day, OtherStart)) :-
    Start < OtherStart.

btSlotBefore(slot(_, Day, _), slot(_, OtherDay, _)) :-
    instanceSetting("dias", Days),
    append(_, [Day|LaterDays], Days),
    member(OtherDay, LaterDays).
