%% A relationship between a heuristic, pending sessions and the next session

fdSelectSession(original, Model, _, Session) :-
    fdPendingSessions(Model, [Session|_]).

fdSelectSession(lcv, Model, _, Session) :-
    fdPendingSessions(Model, [Session|_]).

fdSelectSession(mrv, Model, Maps, SelectedSession) :-
    fdPendingSessions(Model, [Session|Sessions]),
    fdCompatibleSlots(Session, Model, Maps, ViableSlots),
    length(ViableSlots, SlotCount),
    fdSelectMrv(Sessions, Model, Maps, Session, SlotCount, SelectedSession).

fdSelectSession(degree, Model, _, SelectedSession) :-
    fdPendingSessions(Model, PendingSessions),
    PendingSessions = [Session|Sessions],
    sessionDegree(Session, PendingSessions, Degree),
    fdSelectDegree(Sessions, PendingSessions, Session, Degree, SelectedSession).

fdSelectSession(demand, Model, _, SelectedSession) :-
    fdPendingSessions(Model, [Session|Sessions]),
    fdSelectDemand(Sessions, Session, SelectedSession).

%% A relationship between prepared sessions and their pending sessions

fdPendingSessions([], []).

fdPendingSessions([fdSession(_, RoomIndex, DayIndex, Start, _)|Model], PendingSessions) :-
    ground([RoomIndex, DayIndex, Start]),
    fdPendingSessions(Model, PendingSessions).

fdPendingSessions([fdSession(Session, RoomIndex, DayIndex, Start, _)|Model], [Session|PendingSessions]) :-
    \+ ground([RoomIndex, DayIndex, Start]),
    fdPendingSessions(Model, PendingSessions).

%% A relationship between sessions and the one with the fewest compatible locations

fdSelectMrv([], _, _, BestSession, _, BestSession).

fdSelectMrv([Session|Sessions], Model, Maps, _, BestSlotCount, SelectedSession) :-
    fdCompatibleSlots(Session, Model, Maps, ViableSlots),
    length(ViableSlots, SlotCount),
    SlotCount < BestSlotCount,
    !,
    fdSelectMrv(Sessions, Model, Maps, Session, SlotCount, SelectedSession).

fdSelectMrv([_|Sessions], Model, Maps, BestSession, BestSlotCount, SelectedSession) :-
    fdSelectMrv(Sessions, Model, Maps, BestSession, BestSlotCount, SelectedSession).

%% A relationship between sessions and the one with the most shared rules

fdSelectDegree([], _, BestSession, _, BestSession).

fdSelectDegree([Session|Sessions], PendingSessions, _, BestDegree, SelectedSession) :-
    sessionDegree(Session, PendingSessions, Degree),
    Degree > BestDegree,
    !,
    fdSelectDegree(Sessions, PendingSessions, Session, Degree, SelectedSession).

fdSelectDegree([_|Sessions], PendingSessions, BestSession, BestDegree, SelectedSession) :-
    fdSelectDegree(Sessions, PendingSessions, BestSession, BestDegree, SelectedSession).

%% A relationship between sessions and the one with the greatest demand

fdSelectDemand([], BestSession, BestSession).

fdSelectDemand([Session|Sessions], BestSession, SelectedSession) :-
    greaterDemand(Session, BestSession),
    !,
    fdSelectDemand(Sessions, Session, SelectedSession).

fdSelectDemand([_|Sessions], BestSession, SelectedSession) :-
    fdSelectDemand(Sessions, BestSession, SelectedSession).
