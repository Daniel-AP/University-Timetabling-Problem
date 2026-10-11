%% Start the CPU and wall time measurements

startMeasure :-
    statistics(real_time, _),
    statistics(cpu_time, _).

%% A relationship between search counts and elapsed times

finishMeasure(Nodes, Backtracks, searchStats(Nodes, Backtracks, CpuTime, TotalTime)) :-
    statistics(cpu_time, [_, CpuMilliseconds]),
    statistics(real_time, [_, WallMilliseconds]),
    CpuTime is CpuMilliseconds/1000.0,
    TotalTime is WallMilliseconds/1000.0.

%% A relationship between search statistics and the search rate

nodeRate(searchStats(Nodes, _, CpuTime, _), Rate) :-
    Rate is Nodes/CpuTime.
