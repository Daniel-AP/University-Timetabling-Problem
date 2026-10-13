%% A relationship between a run and the start of its time measurements

startMeasurement :-
    statistics(real_time, _),
    statistics(cpu_time, _).

%% A relationship between search counts and elapsed times

finishMeasurement(Nodes, Backtracks, searchStats(Nodes, Backtracks, CpuTime, WallTime)) :-
    statistics(cpu_time, [_, CpuMilliseconds]),
    statistics(real_time, [_, WallMilliseconds]),
    CpuTime is CpuMilliseconds/1000.0,
    WallTime is WallMilliseconds/1000.0.

%% A relationship between search statistics and the number of nodes per second

searchNodeRate(searchStats(Nodes, _, CpuTime, _), Rate) :-
    Rate is Nodes/CpuTime.

%% A relationship between measured search intervals and their totals

addSearchStats(searchStats(FirstNodes, FirstBacktracks, FirstCpuTime, FirstWallTime), searchStats(SecondNodes, SecondBacktracks, SecondCpuTime, SecondWallTime), searchStats(Nodes, Backtracks, CpuTime, WallTime)) :-
    Nodes is FirstNodes+SecondNodes,
    Backtracks is FirstBacktracks+SecondBacktracks,
    CpuTime is FirstCpuTime+SecondCpuTime,
    WallTime is FirstWallTime+SecondWallTime.
