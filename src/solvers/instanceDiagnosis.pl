%% A relationship between an unsolved instance, its cause and complete measurements

instanceDiagnosis(_, _, result(found, schedule(_)), Stats, none, Stats).

instanceDiagnosis(_, _, result(limitReached, _), Stats, none, Stats).

instanceDiagnosis(Instance, Config, result(noSolution, none), SearchStats, Cause, Stats) :-
    Instance = instance(Settings, Rooms, Teachers, Groups, Teaching, Records),
    hardRestrictionRecords(Records, HardRecords),
    BaseInstance = instance(Settings, Rooms, Teachers, Groups, Teaching, []),
    searchDiagnosticInstance(BaseInstance, Config, BaseResult, BaseStats),
    firstBlockingRestriction(HardRecords, [], BaseInstance, Config, BaseResult, Cause, RestrictionStats),
    registerInstance(Instance),
    finishMeasurement(0, 0, RestoreStats),
    addSearchStats(SearchStats, BaseStats, Stats1),
    addSearchStats(Stats1, RestrictionStats, Stats2),
    addSearchStats(Stats2, RestoreStats, Stats).

%% A relationship between restriction records and their hard declarations

hardRestrictionRecords([], []).

hardRestrictionRecords([Record|Records], [Record|HardRecords]) :-
    Record = record(_, [Type|_]),
    member(Type, ["aula_fija", "prohibida", "excluyentes"]),
    !,
    hardRestrictionRecords(Records, HardRecords).

hardRestrictionRecords([_|Records], HardRecords) :-
    hardRestrictionRecords(Records, HardRecords).

%% A relationship between declared restrictions and their first blocking record

firstBlockingRestriction(_, [], _, _, result(noSolution, none), implicitConstraints, searchStats(0, 0, 0.0, 0.0)).

firstBlockingRestriction(_, AppliedRecords, _, _, result(noSolution, none), blockingRestriction(Record), searchStats(0, 0, 0.0, 0.0)) :-
    AppliedRecords = [_|_],
    append(_, [Record], AppliedRecords).

firstBlockingRestriction([Record|Records], AppliedRecords, Instance, Config, result(found, schedule(_)), Cause, Stats) :-
    append(AppliedRecords, [Record], NextRecords),
    Instance = instance(Settings, Rooms, Teachers, Groups, Teaching, _),
    NextInstance = instance(Settings, Rooms, Teachers, Groups, Teaching, NextRecords),
    searchDiagnosticInstance(NextInstance, Config, Result, CurrentStats),
    firstBlockingRestriction(Records, NextRecords, Instance, Config, Result, Cause, RestStats),
    addSearchStats(CurrentStats, RestStats, Stats).

%% A relationship between a diagnostic instance and its feasibility search

searchDiagnosticInstance(Instance, config(Input, Output, Strategy, Heuristic, _, _), Result, Stats) :-
    registerInstance(Instance),
    Config = config(Input, Output, Strategy, Heuristic, false, none),
    searchInstance(Config, Result, Stats, _).
