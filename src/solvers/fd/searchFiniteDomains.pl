:- dynamic(fdSearchControl/2).

%% A relationship between search inputs, their result and their statistics

searchFiniteDomains(Config, Model, Maps, Result, Stats) :-
    retractall(fdSearchControl(_, _)),
    assertz(fdSearchControl(fdControl(0, none), 0)),
    catch(
        (
            catch(
                fdRunSearch(Config, Model, Maps, Stop),
                fdSearchStop(Stop),
                true
            ),
            fdSearchControl(fdControl(Nodes, Best), Backtracks),
            fdSearchResult(Stop, Best, Result),
            finishMeasurement(Nodes, Backtracks, Stats)
        ),
        Error,
        (
            retractall(fdSearchControl(_, _)),
            throw(Error)
        )
    ),
    retractall(fdSearchControl(_, _)).

%% A relationship between an initial model and search exhaustion

fdRunSearch(Config, Model, Maps, exhausted) :-
    Config = config(_, _, _, _, _, Limit),
    fdVisitNode(Limit),
    \+ fdSearchModel(Config, Model, Maps).

%% A relationship between a branch model and its complete schedules

fdSearchModel(Config, Model, Maps) :-
    fdPendingSessions(Model, []),
    Config = config(_, _, _, _, IsOptimizationEnabled, _),
    fdAssignmentsSchedule(Model, Maps, Schedule),
    checkSchedule(Schedule),
    fdRecordSchedule(IsOptimizationEnabled, Schedule).

fdSearchModel(Config, Model, Maps) :-
    fdPendingSessions(Model, [_|_]),
    Config = config(_, _, _, Heuristic, _, Limit),
    fdBranchSlots(Heuristic, Model, Maps, Session, Slots),
    member(Slot, Slots),
    fdVisitNode(Limit),
    \+ fdTryAssignment(Config, Model, Maps, Session, Slot),
    fdCountBacktrack,
    fail.

%% A relationship between a heuristic, a model and its next session locations

fdBranchSlots(ff, Model, Maps, Session, Slots) :-
    fdBranchSlots(mrv, Model, Maps, Session, Slots).

fdBranchSlots(Heuristic, Model, Maps, Session, Slots) :-
    Heuristic \= ff,
    fdSelectSession(Heuristic, Model, Maps, Session),
    fdCompatibleSlots(Session, Model, Maps, ViableSlots),
    fdOrderSlots(Heuristic, Session, ViableSlots, Model, Maps, Slots).

%% A relationship between a candidate location and its next branch

fdTryAssignment(Config, Model, Maps, Session, Slot) :-
    Config = config(_, _, _, _, IsOptimizationEnabled, _),
    fdAssignSession(Session, Slot, Model, Maps),
    fdIsBranchAllowed(IsOptimizationEnabled, Model, Maps),
    fdSearchModel(Config, Model, Maps).

%% A relationship between a session location and its original model decisions

fdAssignSession(Session, slot(Room, Day, TupleStart), Model, indexMaps(Rooms, Days)) :-
    member(fdSession(Session, RoomIndex, DayIndex, Start, _), Model),
    fdIndexValue(Rooms, TupleRoomIndex, Room),
    fdIndexValue(Days, TupleDayIndex, Day),
    fdAssignDecision(RoomIndex, TupleRoomIndex),
    fdAssignDecision(DayIndex, TupleDayIndex),
    fdAssignDecision(Start, TupleStart).

%% A relationship between an original decision and its chosen value

fdAssignDecision(Decision, Value) :-
    Decision #>= Value,
    fdLabelDecision(Decision, Value).

%% A relationship between a decision and its chosen value

fdLabelDecision(Decision, Value) :-
    integer(Decision),
    Decision = Value.

fdLabelDecision(Decision, Value) :-
    \+ integer(Decision),
    fd_labeling(Decision, [value_method(min)]),
    !,
    Decision = Value.

%% A relationship between optimization, a model and a cost worth exploring

fdIsBranchAllowed(false, _, _).

fdIsBranchAllowed(true, _, _) :-
    fdSearchControl(fdControl(_, none), _).

fdIsBranchAllowed(true, Model, Maps) :-
    fdSearchControl(fdControl(_, best(_, BestCost)), _),
    fdCostBound(Model, Maps, Bound),
    Bound < BestCost.

%% A relationship between optimization and a complete valid schedule

fdRecordSchedule(false, Schedule) :-
    fdSaveSchedule(Schedule),
    throw(fdSearchStop(found)).

fdRecordSchedule(true, Schedule) :-
    fdSaveSchedule(Schedule),
    fail.

%% A relationship between a valid schedule and the best stored schedule

fdSaveSchedule(Schedule) :-
    fdSearchControl(fdControl(Nodes, none), Backtracks),
    scheduleCost(Schedule, Cost),
    retract(fdSearchControl(fdControl(Nodes, none), Backtracks)),
    assertz(fdSearchControl(fdControl(Nodes, best(Schedule, Cost)), Backtracks)).

fdSaveSchedule(Schedule) :-
    fdSearchControl(fdControl(Nodes, best(_, BestCost)), Backtracks),
    scheduleCost(Schedule, Cost),
    Cost < BestCost,
    retract(fdSearchControl(fdControl(Nodes, best(_, BestCost)), Backtracks)),
    assertz(fdSearchControl(fdControl(Nodes, best(Schedule, Cost)), Backtracks)).

%% A relationship between a search limit and the next counted node

fdVisitNode(Limit) :-
    fdSearchControl(fdControl(Nodes, _), _),
    fdCheckNodeLimit(Limit, Nodes),
    retract(fdSearchControl(fdControl(Nodes, Best), Backtracks)),
    NextNodes is Nodes+1,
    assertz(fdSearchControl(fdControl(NextNodes, Best), Backtracks)).

%% A relationship between a search limit and the current node count

fdCheckNodeLimit(none, _).

fdCheckNodeLimit(Limit, Nodes) :-
    integer(Limit),
    Nodes >= Limit,
    throw(fdSearchStop(limitReached)).

fdCheckNodeLimit(Limit, Nodes) :-
    integer(Limit),
    Nodes < Limit.

%% A relationship between a backtrack and its count

fdCountBacktrack :-
    retract(fdSearchControl(Control, Backtracks)),
    NextBacktracks is Backtracks+1,
    assertz(fdSearchControl(Control, NextBacktracks)).

%% A relationship between a search stop, its best schedule and its result

fdSearchResult(found, best(Schedule, _), result(found, schedule(Schedule))).

fdSearchResult(exhausted, best(Schedule, _), result(found, schedule(Schedule))).

fdSearchResult(exhausted, none, result(noSolution, none)).

fdSearchResult(limitReached, best(Schedule, _), result(limitReached, schedule(Schedule))).

fdSearchResult(limitReached, none, result(limitReached, none)).
