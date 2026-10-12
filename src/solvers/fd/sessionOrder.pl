%% A relationship between prepared sessions and their chronological order

fdConstrainSessionOrder([]).

fdConstrainSessionOrder([_]).

fdConstrainSessionOrder([FdSession, OtherFdSession|Model]) :-
    fdConstrainSessionPairOrder(FdSession, OtherFdSession),
    fdConstrainSessionOrder([OtherFdSession|Model]).

%% A relationship between consecutive sessions and their chronological order

fdConstrainSessionPairOrder(fdSession(session(Course, _, _), _, _, _, _), fdSession(session(OtherCourse, _, _), _, _, _, _)) :-
    Course \= OtherCourse.

fdConstrainSessionPairOrder(fdSession(session(Course, Group, _), _, _, _, _), fdSession(session(Course, OtherGroup, _), _, _, _, _)) :-
    Group \= OtherGroup.

fdConstrainSessionPairOrder(fdSession(session(Course, Group, _), _, DayIndex, Start, _), fdSession(session(Course, Group, _), _, OtherDayIndex, OtherStart, _)) :-
    (DayIndex #< OtherDayIndex) #\/
    ((DayIndex #= OtherDayIndex) #/\
    (Start #< OtherStart)).
