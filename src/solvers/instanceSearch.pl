%% A relationship between an instance search and its results

searchInstance(Config, Result, Stats, []) :-
    Config = config(_, _, bt, _, _, _),
    sessions(Sessions),
    sessionDomains(Sessions, Domains),
    searchBacktracking(Config, Sessions, Domains, Result, Stats).

searchInstance(Config, Result, Stats, []) :-
    Config = config(_, _, clpfd, _, _, _),
    fdPrepareModel(Model, Maps),
    fdConstrainSessions(Model, Maps),
    fdConstrainSessionOrder(Model),
    equivalentRoomGroups(RoomGroups),
    fdConstrainRoomAppearanceOrder(RoomGroups, Model, Maps),
    !,
    searchFiniteDomains(Config, Model, Maps, Result, Stats).

searchInstance(config(_, _, clpfd, _, _, _), result(noSolution, none), Stats, ["Inconsistent finite domain constraints"]) :-
    finishMeasurement(0, 0, Stats).
