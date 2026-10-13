%% A relationship between prepared sessions and their time order

fdConstrainSessionOrder([]).

fdConstrainSessionOrder([_]).

fdConstrainSessionOrder([FdSession, OtherFdSession|Model]) :-
    fdConstrainSessionPairOrder(FdSession, OtherFdSession),
    fdConstrainSessionOrder([OtherFdSession|Model]).

%% A relationship between consecutive sessions and their time order

fdConstrainSessionPairOrder(fdSession(session(Course, _, _), _, _, _, _), fdSession(session(OtherCourse, _, _), _, _, _, _)) :-
    Course \= OtherCourse.

fdConstrainSessionPairOrder(fdSession(session(Course, Group, _), _, _, _, _), fdSession(session(Course, OtherGroup, _), _, _, _, _)) :-
    Group \= OtherGroup.

fdConstrainSessionPairOrder(fdSession(session(Course, Group, _), _, DayIndex, Start, _), fdSession(session(Course, Group, _), _, OtherDayIndex, OtherStart, _)) :-
    group(Course, Group, _, _, _, Duration, _),
    Duration > 0,
    IsEarlierDay #<=> (DayIndex #< OtherDayIndex),
    IsSameDayEarlierStart #<=> ((DayIndex #= OtherDayIndex) #/\ (Start #< OtherStart)),
    fd_all_different([IsEarlierDay, IsSameDayEarlierStart]).

fdConstrainSessionPairOrder(fdSession(session(Course, Group, _), _, DayIndex, Start, _), fdSession(session(Course, Group, _), _, OtherDayIndex, OtherStart, _)) :-
    group(Course, Group, _, _, _, 0, _),
    (DayIndex #< OtherDayIndex) #\/
    ((DayIndex #= OtherDayIndex) #/\
    (Start #=< OtherStart)).
