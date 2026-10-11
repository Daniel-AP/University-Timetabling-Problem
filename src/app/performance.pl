%% A relationship between a run and the start of its time measurements

startMeasure :-
    statistics(real_time, _),
    statistics(cpu_time, _).

%% A relationship between search counts and elapsed times

finishMeasure(Nodes, Backtracks, searchStats(Nodes, Backtracks, CpuTime, TotalTime)) :-
    statistics(cpu_time, [_, CpuMilliseconds]),
    statistics(real_time, [_, WallMilliseconds]),
    CpuTime is CpuMilliseconds/1000.0,
    TotalTime is WallMilliseconds/1000.0.

%% A relationship between search statistics and the number of nodes per second

nodeRate(searchStats(Nodes, _, CpuTime, _), Rate) :-
    Rate is Nodes/CpuTime.
