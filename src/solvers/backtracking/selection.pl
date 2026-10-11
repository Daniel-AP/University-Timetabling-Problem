%% A relationship between a heuristic, pending sessions and the next session

selectSession(original, [Session|_], _, _, Session).

selectSession(lcv, [Session|_], _, _, Session).

selectSession(mrv, [Session|Sessions], Domains, AssignedSessions, SelectedSession) :-
    member(domain(Session, Slots), Domains),
    compatibleSlots(Session, Slots, AssignedSessions, CompatibleSlots),
    length(CompatibleSlots, Count),
    selectMrv(Sessions, Domains, AssignedSessions, Session, Count, SelectedSession).

selectSession(degree, [Session|Sessions], _, _, SelectedSession) :-
    PendingSessions = [Session|Sessions],
    degree(Session, PendingSessions, Degree),
    selectDegree(Sessions, PendingSessions, Session, Degree, SelectedSession).

selectSession(demand, [Session|Sessions], _, _, SelectedSession) :-
    selectDemand(Sessions, Session, SelectedSession).

%% A relationship between sessions and the one with the fewest compatible locations

selectMrv([], _, _, BestSession, _, BestSession).

selectMrv([Session|Sessions], Domains, AssignedSessions, _, BestCount, SelectedSession) :-
    member(domain(Session, Slots), Domains),
    compatibleSlots(Session, Slots, AssignedSessions, CompatibleSlots),
    length(CompatibleSlots, Count),
    Count < BestCount, !,
    selectMrv(Sessions, Domains, AssignedSessions, Session, Count, SelectedSession).

selectMrv([_|Sessions], Domains, AssignedSessions, BestSession, BestCount, SelectedSession) :-
    selectMrv(Sessions, Domains, AssignedSessions, BestSession, BestCount, SelectedSession).

%% A relationship between sessions and the one with the most shared rules

selectDegree([], _, BestSession, _, BestSession).

selectDegree([Session|Sessions], PendingSessions, _, BestDegree, SelectedSession) :-
    degree(Session, PendingSessions, Degree),
    Degree > BestDegree, !,
    selectDegree(Sessions, PendingSessions, Session, Degree, SelectedSession).

selectDegree([_|Sessions], PendingSessions, BestSession, BestDegree, SelectedSession) :-
    selectDegree(Sessions, PendingSessions, BestSession, BestDegree, SelectedSession).

%% A relationship between sessions and the one with the greatest demand

selectDemand([], BestSession, BestSession).

selectDemand([Session|Sessions], BestSession, SelectedSession) :-
    greaterDemand(Session, BestSession), !,
    selectDemand(Sessions, Session, SelectedSession).

selectDemand([_|Sessions], BestSession, SelectedSession) :-
    selectDemand(Sessions, BestSession, SelectedSession).
