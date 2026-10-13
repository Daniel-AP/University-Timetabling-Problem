%% A relationship between a session, its student count and its length

sessionDemand(session(Course, Group, _), Enrolled, Duration) :-
    group(Course, Group, _, Enrolled, _, Duration, _).

%% A relationship between two sessions and their demand order

hasGreaterDemand(First, Second) :-
    sessionDemand(First, Enrolled, _),
    sessionDemand(Second, OtherEnrolled, _),
    Enrolled > OtherEnrolled.

hasGreaterDemand(First, Second) :-
    sessionDemand(First, Enrolled, Duration),
    sessionDemand(Second, Enrolled, OtherDuration),
    Duration > OtherDuration.

%% A relationship between a session and its constraint count with pending sessions

sessionDegree(_, [], 0).

sessionDegree(Session, [Session|PendingSessions], Degree) :-
    sessionDegree(Session, PendingSessions, Degree).

sessionDegree(Session, [OtherSession|PendingSessions], Degree) :-
    Session \= OtherSession,
    pairConstraintCount(Session, OtherSession, Count),
    sessionDegree(Session, PendingSessions, RestDegree),
    Degree is Count+RestDegree.

%% A relationship between two sessions and their number of hard constraints

pairConstraintCount(Session, Session, 0).

pairConstraintCount(First, Second, Count) :-
    First \= Second,
    findall(Constraint, pairConstraint(First, Second, Constraint), RepeatedConstraints),
    sort(RepeatedConstraints, Constraints),
    length(Constraints, Count).

%% A relationship between two sessions and a hard constraint

pairConstraint(_, _, room).

pairConstraint(session(Course, Group, _), session(Course, Group, _), group).

pairConstraint(session(Course, Group, _), session(OtherCourse, OtherGroup, _), teacher(Teacher)) :-
    teaches(Course, Group, Teacher),
    teaches(OtherCourse, OtherGroup, Teacher).

pairConstraint(session(Course, Group, _), session(OtherCourse, OtherGroup, _), exclusive) :-
    exclusiveGroups(Course, Group, OtherCourse, OtherGroup).

pairConstraint(session(Course, Group, _), session(OtherCourse, OtherGroup, _), exclusive) :-
    exclusiveGroups(OtherCourse, OtherGroup, Course, Group).
