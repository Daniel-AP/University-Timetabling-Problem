%% A relationship between a session, its student count and its length

demandData(session(Course, Group, _), Enrolled, Duration) :-
    group(Course, Group, _, Enrolled, _, Duration, _).

%% A relationship between two sessions where the first has greater demand

greaterDemand(First, Second) :-
    demandData(First, Enrolled, _),
    demandData(Second, OtherEnrolled, _),
    Enrolled > OtherEnrolled.

greaterDemand(First, Second) :-
    demandData(First, Enrolled, Duration),
    demandData(Second, Enrolled, OtherDuration),
    Duration > OtherDuration.

%% A relationship between a session and its rule count with pending sessions

degree(_, [], 0).

degree(Session, [Session|PendingSessions], Degree) :-
    degree(Session, PendingSessions, Degree).

degree(Session, [OtherSession|PendingSessions], Degree) :-
    Session \= OtherSession,
    pairRuleCount(Session, OtherSession, Count),
    degree(Session, PendingSessions, RestDegree),
    Degree is Count+RestDegree.

%% A relationship between two sessions and their number of hard rules

pairRuleCount(Session, Session, 0).

pairRuleCount(First, Second, Count) :-
    First \= Second,
    findall(Constraint, pairConstraint(First, Second, Constraint), RepeatedConstraints),
    sort(RepeatedConstraints, Constraints),
    length(Constraints, Count).

%% A relationship between two sessions and a hard rule

pairConstraint(_, _, room).

pairConstraint(session(Course, Group, _), session(Course, Group, _), group).

pairConstraint(session(Course, Group, _), session(OtherCourse, OtherGroup, _), teacher(Teacher)) :-
    teaches(Course, Group, Teacher),
    teaches(OtherCourse, OtherGroup, Teacher).

pairConstraint(session(Course, Group, _), session(OtherCourse, OtherGroup, _), exclusive) :-
    exclusiveGroups(Course, Group, OtherCourse, OtherGroup).

pairConstraint(session(Course, Group, _), session(OtherCourse, OtherGroup, _), exclusive) :-
    exclusiveGroups(OtherCourse, OtherGroup, Course, Group).
