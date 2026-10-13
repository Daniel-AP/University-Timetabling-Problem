%% A relationship between an instance search, its result and measurements

searchInstance(Config, Result, Stats, []) :-
    Config = config(_, _, bt, _, _, _),
    sessions(Sessions),
    sessionDomains(Sessions, Domains),
    searchBacktracking(Config, Sessions, Domains, Result, Stats).

searchInstance(Config, Result, Stats, []) :-
    Config = config(_, _, clpfd, _, _, _),
    fdPrepareModel(Model, _Variables, Maps),
    fdConstrainSessions(Model, Maps),
    fdConstrainSessionOrder(Model),
    equivalentRoomGroups(RoomGroups),
    fdConstrainRoomAppearanceOrder(RoomGroups, Model, Maps),
    !,
    searchFiniteDomains(Config, Model, Maps, Result, Stats).

searchInstance(config(_, _, clpfd, _, _, _), result(noSolution, none), Stats, ["Finite domain constraints are inconsistent before search"]) :-
    finishMeasurement(0, 0, Stats).
