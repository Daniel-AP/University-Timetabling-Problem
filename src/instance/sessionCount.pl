%% A relationship between instance facts and their total weekly sessions

sessionCount(TotalSessions) :-
    findall(WeeklySessions, group(_, _, _, _, WeeklySessions, _, _), WeeklyCounts),
    sessionCountSum(WeeklyCounts, TotalSessions).

%% A relationship between weekly session counts and their sum

sessionCountSum([], 0).

sessionCountSum([WeeklySessions|WeeklyCounts], TotalSessions) :-
    sessionCountSum(WeeklyCounts, RestTotal),
    TotalSessions is WeeklySessions+RestTotal.
