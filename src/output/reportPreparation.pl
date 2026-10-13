%% A relationship between execution data and a prepared report

prepareReport(Config, result(Status, schedule(Schedule)), Instance, Stats, Cost, _, reportOptions(IsRoomGridEnabled), Date, Report) :-
    Config = config(Input, _, Strategy, Heuristic, IsOptimizationEnabled, _),
    reportState(IsOptimizationEnabled, result(Status, schedule(Schedule)), StateText, FinalText),
    Header = header(Input, Strategy, Heuristic, StateText, Date),
    Instance = instance(Settings, _, _, _, _, _),
    member(record(_, ["dias", Days]), Settings),
    member(record(_, ["franjas", DailySlotCount]), Settings),
    reportResources(Instance, GroupResources, TeacherResources, RoomResources),
    reportDetail(Schedule, Days, Detail),
    reportGrids(GroupResources, Days, DailySlotCount, Schedule, GroupGrids),
    reportGrids(TeacherResources, Days, DailySlotCount, Schedule, TeacherGrids),
    reportRoomGrids(IsRoomGridEnabled, RoomResources, Days, DailySlotCount, Schedule, RoomGrids),
    reportSessionTotals(Schedule, SessionCount, SessionSlotCount),
    reportGaps(GroupResources, Schedule, GroupGaps),
    reportGaps(TeacherResources, Schedule, TeacherGaps),
    reportNodeRate(Stats, NodeRate),
    Conclusion = summary(SessionCount, SessionSlotCount, GroupGaps, TeacherGaps, Cost, Stats, NodeRate, FinalText),
    Report = report(Header, Detail, GroupGrids, TeacherGrids, RoomGrids, Conclusion).

prepareReport(Config, result(Status, none), _, Stats, _, Diagnostic, _, Date, Report) :-
    Config = config(Input, _, Strategy, Heuristic, IsOptimizationEnabled, _),
    reportState(IsOptimizationEnabled, result(Status, none), StateText, FinalText),
    Header = header(Input, Strategy, Heuristic, StateText, Date),
    reportNodeRate(Stats, NodeRate),
    Conclusion = diagnosticBlock(FinalText, Diagnostic, Stats, NodeRate),
    Report = report(Header, none, none, none, none, Conclusion).

%% A relationship between a search result and its report state

reportState(false, result(found, schedule(_)), "SOLUTION FOUND", "First valid schedule. Best cost not proved").

reportState(true, result(found, schedule(_)), "SOLUTION FOUND", "Optimal schedule. Search finished").

reportState(_, result(noSolution, none), "NO SOLUTION", "No solution. Resolution finished").

reportState(_, result(invalidInstance, none), "INVALID INSTANCE", "Invalid instance. Search not started").

reportState(_, result(limitReached, schedule(_)), "LIMIT REACHED", "Limit reached. Best schedule found. Best cost not proved").

reportState(_, result(limitReached, none), "LIMIT REACHED", "Limit reached. No schedule found. A solution may exist").

%% A relationship between search statistics and a report node rate

reportNodeRate(unavailable, unavailable).

reportNodeRate(searchStats(_, _, CpuTime, _), notCalculable) :-
    CpuTime =:= 0.

reportNodeRate(Stats, NodeRate) :-
    Stats = searchStats(_, _, CpuTime, _),
    CpuTime > 0,
    searchNodeRate(Stats, NodeRate).

%% A relationship between instance records and report resources

reportResources(instance(_, Rooms, Teachers, Groups, _, _), GroupResources, TeacherResources, RoomResources) :-
    findall(
        groupKey(Course, Group),
        member(record(_, [Course, _, Group, _, _, _, _]), Groups),
        GroupResources
    ),
    findall(
        teacher(Teacher),
        member(record(_, [Teacher, _, _, _]), Teachers),
        TeacherResources
    ),
    findall(
        room(Room),
        member(record(_, [Room, _, _]), Rooms),
        RoomResources
    ).

%% A relationship between a schedule and its ordered detail

reportDetail(Schedule, Days, Detail) :-
    findall(
        key(Course, Group, DayIndex, Start)-Assignment,
        (
            member(Assignment, Schedule),
            Assignment = assignment(Course, Group, _, _, Day, Start, _),
            nth(DayIndex, Days, Day)
        ),
        Pairs
    ),
    keysort(Pairs, SortedPairs),
    reportDetailRows(SortedPairs, 1, Detail).

%% A relationship between ordered assignments and numbered detail rows

reportDetailRows([], _, []).

reportDetailRows([_-Assignment|SortedPairs], RowNumber, [detail(RowNumber, Assignment, Span)|Detail]) :-
    Assignment = assignment(_, _, _, _, _, Start, Duration),
    reportSpan(Start, Duration, Span),
    NextRow is RowNumber+1,
    reportDetailRows(SortedPairs, NextRow, Detail).

%% A relationship between a session start and its occupied slots

reportSpan(Start, 0, noSlots(Start)).

reportSpan(Start, Duration, slots(Start, LastSlot)) :-
    Duration > 0,
    LastSlot is Start+Duration-1.

%% A relationship between resources and their complete grids

reportGrids([], _, _, _, []).

reportGrids([Resource|Resources], Days, DailySlotCount, Schedule, [grid(Resource, Days, Rows)|Grids]) :-
    findall(
        Assignment,
        (
            member(Assignment, Schedule),
            reportResourceAssignment(Resource, Assignment)
        ),
        ResourceSchedule
    ),
    reportRows(1, DailySlotCount, Days, ResourceSchedule, Rows),
    reportGrids(Resources, Days, DailySlotCount, Schedule, Grids).

%% A relationship between a resource and its schedule assignment

reportResourceAssignment(groupKey(Course, Group), assignment(Course, Group, _, _, _, _, _)).

reportResourceAssignment(teacher(Teacher), assignment(_, _, Teachers, _, _, _, _)) :-
    member(Teacher, Teachers).

reportResourceAssignment(room(Room), assignment(_, _, _, Room, _, _, _)).

%% A relationship between daily slot positions and grid rows

reportRows(Position, DailySlotCount, _, _, []) :-
    Position > DailySlotCount.

reportRows(Position, DailySlotCount, Days, ResourceSchedule, [row(Position, Cells)|Rows]) :-
    Position =< DailySlotCount,
    reportCells(Days, Position, ResourceSchedule, Cells),
    NextPosition is Position+1,
    reportRows(NextPosition, DailySlotCount, Days, ResourceSchedule, Rows).

%% A relationship between configured days and a row's cells

reportCells([], _, _, []).

reportCells([Day|Days], Position, ResourceSchedule, [Cell|Cells]) :-
    reportCell(Day, Position, ResourceSchedule, Cell),
    reportCells(Days, Position, ResourceSchedule, Cells).

%% A relationship between a grid position and its contents

reportCell(Day, Position, ResourceSchedule, groupKey(Course, Group)) :-
    member(assignment(Course, Group, _, _, Day, Start, Duration), ResourceSchedule),
    occupiedSlot(Start, Duration, Position),
    !.

reportCell(_, _, _, empty).

%% A relationship between the room grid option and prepared room grids

reportRoomGrids(false, _, _, _, _, none).

reportRoomGrids(true, RoomResources, Days, DailySlotCount, Schedule, RoomGrids) :-
    reportGrids(RoomResources, Days, DailySlotCount, Schedule, RoomGrids).

%% A relationship between sessions and their report totals

reportSessionTotals([], 0, 0).

reportSessionTotals([assignment(_, _, _, _, _, _, Duration)|Schedule], SessionCount, SessionSlotCount) :-
    reportSessionTotals(Schedule, RestCount, RestSlotCount),
    SessionCount is RestCount+1,
    SessionSlotCount is Duration+RestSlotCount.

%% A relationship between groups or teachers and their total daily gaps

reportGaps([], _, 0).

reportGaps([Resource|Resources], Schedule, Gaps) :-
    reportOccupiedSlots(Resource, Schedule, OccupiedSlots),
    slotGaps(OccupiedSlots, CurrentGaps),
    reportGaps(Resources, Schedule, RestGaps),
    Gaps is CurrentGaps+RestGaps.

%% A relationship between a group or teacher and its occupied slots

reportOccupiedSlots(groupKey(Course, Group), Schedule, OccupiedSlots) :-
    groupOccupiedSlots(Course, Group, Schedule, OccupiedSlots).

reportOccupiedSlots(teacher(Teacher), Schedule, OccupiedSlots) :-
    findall(
        daySlot(Day, Position),
        (
            member(assignment(_, _, Teachers, _, Day, Start, Duration), Schedule),
            member(Teacher, Teachers),
            occupiedSlot(Start, Duration, Position)
        ),
        RepeatedSlots
    ),
    sort(RepeatedSlots, OccupiedSlots).
