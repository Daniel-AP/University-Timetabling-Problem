%% A relationship between instance facts and their total weekly sessions

sessionCount(TotalSessions) :-
    findall(WeeklySessions, group(_, _, _, _, WeeklySessions, _, _), WeeklyCounts),
    sessionSum(WeeklyCounts, TotalSessions).

%% A relationship between weekly session counts and their sum

sessionSum([], 0).

sessionSum([WeeklySessions|WeeklyCounts], TotalSessions) :-
    sessionSum(WeeklyCounts, RestTotal),
    TotalSessions is WeeklySessions+RestTotal.
