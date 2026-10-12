:- dynamic(searchControl/2).

%% A relationship between a search and its chosen variant

searchVariant(forward).

%% A relationship between search inputs, their result and their statistics

searchBacktracking(Config, OriginalSessions, Domains, Result, Stats) :-
    retractall(searchControl(_, _)),
    assertz(searchControl(btControl(0, none), 0)),
    searchVariant(Variant),
    equivalentRoomGroups(RoomGroups),
    State = btState(OriginalSessions, []),
    catch(runSearch(Config, Variant, Domains, RoomGroups, OriginalSessions, State, Stop), searchStop(Stop), true),
    searchControl(btControl(Nodes, Best), Backtracks),
    searchResult(Stop, Best, Result),
    finishMeasure(Nodes, Backtracks, Stats),
    retractall(searchControl(_, _)).

%% A relationship between an initial branch and search exhaustion

runSearch(Config, Variant, Domains, RoomGroups, OriginalSessions, State, exhausted) :-
    Config = config(_, _, _, _, _, Limit),
    visitNode(Limit),
    \+ searchState(Config, Variant, Domains, RoomGroups, OriginalSessions, State).

%% A relationship between a branch and its complete schedules

searchState(Config, _, _, _, _, btState([], AssignedSessions)) :-
    Config = config(_, _, _, _, Optimize, _),
    assignedSchedule(AssignedSessions, Schedule),
    checkSchedule(Schedule),
    recordSchedule(Optimize, Schedule).

searchState(Config, Variant, Domains, RoomGroups, OriginalSessions, State) :-
    State = btState([_|_], _),
    Config = config(_, _, _, Heuristic, _, Limit),
    branchSlots(Variant, Heuristic, State, Domains, Session, Slots),
    member(Slot, Slots),
    visitNode(Limit),
    \+ tryAssignment(Config, Variant, Domains, RoomGroups, OriginalSessions, State, Session, Slot),
    countBacktrack,
    fail.

%% A relationship between a candidate location and its next branch

tryAssignment(Config, Variant, Domains, RoomGroups, OriginalSessions, State, Session, Slot) :-
    State = btState(_, AssignedSessions),
    Config = config(_, _, _, _, Optimize, _),
    checkSessionOrder(Session, Slot, AssignedSessions),
    assignSession(State, Session, Slot, NextState),
    checkRoomAppearanceOrder(RoomGroups, OriginalSessions, NextState),
    branchAllowed(Optimize, NextState),
    searchState(Config, Variant, Domains, RoomGroups, OriginalSessions, NextState).

%% A relationship between a variant, a branch and its next session locations

branchSlots(basic, _, btState([Session|_], _), Domains, Session, Slots) :-
    member(domain(Session, Slots), Domains).

branchSlots(forward, Heuristic, btState(PendingSessions, AssignedSessions), Domains, Session, Slots) :-
    selectSession(Heuristic, PendingSessions, Domains, AssignedSessions, Session),
    member(domain(Session, DomainSlots), Domains),
    compatibleSlots(Session, DomainSlots, AssignedSessions, CompatibleSlots),
    delete(PendingSessions, Session, OtherPendingSessions),
    sortSlots(Heuristic, Session, CompatibleSlots, OtherPendingSessions, Domains, AssignedSessions, Slots).

%% A relationship between a branch, a session location and the updated branch

assignSession(btState(PendingSessions, AssignedSessions), Session, Slot, btState(OtherPendingSessions, [tentativeAssignment(Session, Slot)|AssignedSessions])) :-
    delete(PendingSessions, Session, OtherPendingSessions).

%% A relationship between assigned sessions and their common schedule

assignedSchedule([], []).

assignedSchedule([tentativeAssignment(Session, Slot)|AssignedSessions], [Assignment|Schedule]) :-
    sessionAssignment(Session, Slot, Assignment),
    assignedSchedule(AssignedSessions, Schedule).

%% A relationship between optimization, a branch and a cost worth exploring

branchAllowed(false, _).

branchAllowed(true, _) :-
    searchControl(btControl(_, none), _).

branchAllowed(true, State) :-
    searchControl(btControl(_, best(_, Cost)), _),
    lowerBound(State, Bound),
    Bound < Cost.

%% A relationship between optimization and a complete valid schedule

recordSchedule(false, Schedule) :-
    saveSchedule(Schedule),
    throw(searchStop(found)).

recordSchedule(true, Schedule) :-
    saveSchedule(Schedule),
    fail.

%% A relationship between a valid schedule and the best stored schedule

saveSchedule(Schedule) :-
    scheduleCost(Schedule, Cost),
    retract(searchControl(btControl(Nodes, _), Backtracks)),
    assertz(searchControl(btControl(Nodes, best(Schedule, Cost)), Backtracks)).

%% A relationship between a search limit and the next counted node

visitNode(Limit) :-
    searchControl(btControl(Nodes, _), _),
    checkNodeLimit(Limit, Nodes),
    retract(searchControl(btControl(Nodes, Best), Backtracks)),
    NextNodes is Nodes+1,
    assertz(searchControl(btControl(NextNodes, Best), Backtracks)).

%% A relationship between a search limit and the current node count

checkNodeLimit(none, _).

checkNodeLimit(Limit, Nodes) :-
    integer(Limit),
    Nodes >= Limit,
    throw(searchStop(limitReached)).

checkNodeLimit(Limit, Nodes) :-
    integer(Limit),
    Nodes < Limit.

%% A relationship between a return to a parent branch and its search count

countBacktrack :-
    retract(searchControl(Control, Backtracks)),
    NextBacktracks is Backtracks+1,
    assertz(searchControl(Control, NextBacktracks)).

%% A relationship between a search stop, its best schedule and its result

searchResult(found, best(Schedule, _), result(found, schedule(Schedule))).

searchResult(exhausted, best(Schedule, _), result(found, schedule(Schedule))).

searchResult(exhausted, none, result(noSolution, none)).

searchResult(limitReached, best(Schedule, _), result(limitReached, schedule(Schedule))).

searchResult(limitReached, none, result(limitReached, none)).
