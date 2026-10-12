:- dynamic(btSearchControl/2).

%% A relationship between a search and its chosen variant

btSearchVariant(forward).

%% A relationship between search inputs, their result and their statistics

searchBacktracking(Config, OriginalSessions, Domains, Result, Stats) :-
    retractall(btSearchControl(_, _)),
    assertz(btSearchControl(btControl(0, none), 0)),
    btSearchVariant(Variant),
    equivalentRoomGroups(RoomGroups),
    State = btState(OriginalSessions, []),
    catch(btRunSearch(Config, Variant, Domains, RoomGroups, OriginalSessions, State, Stop), btSearchStop(Stop), true),
    btSearchControl(btControl(Nodes, Best), Backtracks),
    btSearchResult(Stop, Best, Result),
    finishMeasurement(Nodes, Backtracks, Stats),
    retractall(btSearchControl(_, _)).

%% A relationship between an initial branch and search exhaustion

btRunSearch(Config, Variant, Domains, RoomGroups, OriginalSessions, State, exhausted) :-
    Config = config(_, _, _, _, _, Limit),
    btVisitNode(Limit),
    \+ btSearchState(Config, Variant, Domains, RoomGroups, OriginalSessions, State).

%% A relationship between a branch and its complete schedules

btSearchState(Config, _, _, _, _, btState([], AssignedSessions)) :-
    Config = config(_, _, _, _, Optimize, _),
    assignmentsSchedule(AssignedSessions, Schedule),
    checkSchedule(Schedule),
    btRecordSchedule(Optimize, Schedule).

btSearchState(Config, Variant, Domains, RoomGroups, OriginalSessions, State) :-
    State = btState([_|_], _),
    Config = config(_, _, _, Heuristic, _, Limit),
    btBranchSlots(Variant, Heuristic, State, Domains, Session, Slots),
    member(Slot, Slots),
    btVisitNode(Limit),
    \+ btTryAssignment(Config, Variant, Domains, RoomGroups, OriginalSessions, State, Session, Slot),
    btCountBacktrack,
    fail.

%% A relationship between a candidate location and its next branch

btTryAssignment(Config, Variant, Domains, RoomGroups, OriginalSessions, State, Session, Slot) :-
    State = btState(_, AssignedSessions),
    Config = config(_, _, _, _, Optimize, _),
    btCheckSessionOrder(Session, Slot, AssignedSessions),
    btAssignSession(State, Session, Slot, NextState),
    btCheckRoomAppearanceOrder(RoomGroups, OriginalSessions, NextState),
    btBranchAllowed(Optimize, NextState),
    btSearchState(Config, Variant, Domains, RoomGroups, OriginalSessions, NextState).

%% A relationship between a variant, a branch and its next session locations

btBranchSlots(basic, _, btState([Session|_], _), Domains, Session, Slots) :-
    member(domain(Session, Slots), Domains).

btBranchSlots(forward, Heuristic, btState(PendingSessions, AssignedSessions), Domains, Session, Slots) :-
    btSelectSession(Heuristic, PendingSessions, Domains, AssignedSessions, Session),
    member(domain(Session, DomainSlots), Domains),
    btCompatibleSlots(Session, DomainSlots, AssignedSessions, CompatibleSlots),
    delete(PendingSessions, Session, OtherPendingSessions),
    btOrderSlots(Heuristic, Session, CompatibleSlots, OtherPendingSessions, Domains, AssignedSessions, Slots).

%% A relationship between a branch, a session location and the updated branch

btAssignSession(btState(PendingSessions, AssignedSessions), Session, Slot, btState(OtherPendingSessions, [tentativeAssignment(Session, Slot)|AssignedSessions])) :-
    delete(PendingSessions, Session, OtherPendingSessions).

%% A relationship between optimization, a branch and a cost worth exploring

btBranchAllowed(false, _).

btBranchAllowed(true, _) :-
    btSearchControl(btControl(_, none), _).

btBranchAllowed(true, State) :-
    btSearchControl(btControl(_, best(_, Cost)), _),
    btCostBound(State, Bound),
    Bound < Cost.

%% A relationship between optimization and a complete valid schedule

btRecordSchedule(false, Schedule) :-
    btSaveSchedule(Schedule),
    throw(btSearchStop(found)).

btRecordSchedule(true, Schedule) :-
    btSaveSchedule(Schedule),
    fail.

%% A relationship between a valid schedule and the best stored schedule

btSaveSchedule(Schedule) :-
    scheduleCost(Schedule, Cost),
    retract(btSearchControl(btControl(Nodes, _), Backtracks)),
    assertz(btSearchControl(btControl(Nodes, best(Schedule, Cost)), Backtracks)).

%% A relationship between a search limit and the next counted node

btVisitNode(Limit) :-
    btSearchControl(btControl(Nodes, _), _),
    btCheckNodeLimit(Limit, Nodes),
    retract(btSearchControl(btControl(Nodes, Best), Backtracks)),
    NextNodes is Nodes+1,
    assertz(btSearchControl(btControl(NextNodes, Best), Backtracks)).

%% A relationship between a search limit and the current node count

btCheckNodeLimit(none, _).

btCheckNodeLimit(Limit, Nodes) :-
    integer(Limit),
    Nodes >= Limit,
    throw(btSearchStop(limitReached)).

btCheckNodeLimit(Limit, Nodes) :-
    integer(Limit),
    Nodes < Limit.

%% A relationship between a backtrack and its count

btCountBacktrack :-
    retract(btSearchControl(Control, Backtracks)),
    NextBacktracks is Backtracks+1,
    assertz(btSearchControl(Control, NextBacktracks)).

%% A relationship between a search stop, its best schedule and its result

btSearchResult(found, best(Schedule, _), result(found, schedule(Schedule))).

btSearchResult(exhausted, best(Schedule, _), result(found, schedule(Schedule))).

btSearchResult(exhausted, none, result(noSolution, none)).

btSearchResult(limitReached, best(Schedule, _), result(limitReached, schedule(Schedule))).

btSearchResult(limitReached, none, result(limitReached, none)).
