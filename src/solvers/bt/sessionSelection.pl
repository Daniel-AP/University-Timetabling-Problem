%% A relationship between a heuristic, pending sessions and the next session

btSelectSession(original, [Session|_], _, _, Session).

btSelectSession(lcv, [Session|_], _, _, Session).

btSelectSession(mrv, [Session|Sessions], Domains, AssignedSessions, SelectedSession) :-
    member(domain(Session, Slots), Domains),
    btCompatibleSlots(Session, Slots, AssignedSessions, CompatibleSlots),
    length(CompatibleSlots, SlotCount),
    btSelectMrv(Sessions, Domains, AssignedSessions, Session, SlotCount, SelectedSession).

btSelectSession(degree, [Session|Sessions], _, _, SelectedSession) :-
    PendingSessions = [Session|Sessions],
    sessionDegree(Session, PendingSessions, Degree),
    btSelectDegree(Sessions, PendingSessions, Session, Degree, SelectedSession).

btSelectSession(demand, [Session|Sessions], _, _, SelectedSession) :-
    btSelectDemand(Sessions, Session, SelectedSession).

%% A relationship between sessions and the one with the fewest compatible locations

btSelectMrv([], _, _, BestSession, _, BestSession).

btSelectMrv([Session|Sessions], Domains, AssignedSessions, _, BestSlotCount, SelectedSession) :-
    member(domain(Session, Slots), Domains),
    btCompatibleSlots(Session, Slots, AssignedSessions, CompatibleSlots),
    length(CompatibleSlots, SlotCount),
    SlotCount < BestSlotCount,
    !,
    btSelectMrv(Sessions, Domains, AssignedSessions, Session, SlotCount, SelectedSession).

btSelectMrv([_|Sessions], Domains, AssignedSessions, BestSession, BestSlotCount, SelectedSession) :-
    btSelectMrv(Sessions, Domains, AssignedSessions, BestSession, BestSlotCount, SelectedSession).

%% A relationship between sessions and the one with the most shared rules

btSelectDegree([], _, BestSession, _, BestSession).

btSelectDegree([Session|Sessions], PendingSessions, _, BestDegree, SelectedSession) :-
    sessionDegree(Session, PendingSessions, Degree),
    Degree > BestDegree,
    !,
    btSelectDegree(Sessions, PendingSessions, Session, Degree, SelectedSession).

btSelectDegree([_|Sessions], PendingSessions, BestSession, BestDegree, SelectedSession) :-
    btSelectDegree(Sessions, PendingSessions, BestSession, BestDegree, SelectedSession).

%% A relationship between sessions and the one with the greatest demand

btSelectDemand([], BestSession, BestSession).

btSelectDemand([Session|Sessions], BestSession, SelectedSession) :-
    isGreaterDemand(Session, BestSession),
    !,
    btSelectDemand(Sessions, Session, SelectedSession).

btSelectDemand([_|Sessions], BestSession, SelectedSession) :-
    btSelectDemand(Sessions, BestSession, SelectedSession).
