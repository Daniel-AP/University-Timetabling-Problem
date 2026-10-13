%% A relationship between command line arguments and process termination

main :-
    argument_list(Arguments),
    main(Arguments, ExitCode),
    halt(ExitCode).

%% A relationship between execution arguments and their termination code

main(Arguments, ExitCode) :-
    catch(
        (
            parseArguments(Arguments, Config, ExecutionOptions),
            runExecution(Config, ExecutionOptions, RunExitCode)
        ),
        Error,
        (
            writeExecutionError(Arguments, Error),
            RunExitCode = 1
        )
    ),
    !,
    clearInstance,
    retractall(btSearchControl(_, _)),
    ExitCode = RunExitCode.

main(_, 1) :-
    clearInstance,
    retractall(btSearchControl(_, _)),
    format(user_error, "Could not complete execution~n", []).

%% A relationship between execution settings and their complete output

runExecution(Config, executionOptions(PrologOutput, IsRoomGridEnabled), ExitCode) :-
    Config = config(Input, Output, _, _, _, _),
    startMeasurement,
    readInstance(Input, Bytes),
    parseInstance(Bytes, Instance),
    validateInstance(Instance, ValidationErrors),
    checkInstanceErrors(Input, ValidationErrors),
    registerInstance(Instance),
    searchSpaceSize(Size),
    sessionCount(TotalSessions),
    format("Search space estimate: ~w~nRequired sessions: ~d~n", [Size, TotalSessions]),
    instanceInconsistencies(InconsistencyErrors),
    checkInstanceErrors(Input, InconsistencyErrors),
    searchInstance(Config, Result, SearchStats, SearchDiagnostic),
    instanceDiagnosis(Instance, Config, Result, SearchStats, Cause, Stats),
    diagnosticCauseLines(Cause, CauseLines),
    append(SearchDiagnostic, CauseLines, DiagnosticLines),
    prepareResultData(Result, DiagnosticLines, TotalSessions, Cost, Diagnostic, ExitCode),
    executionDate(Date),
    prepareReport(Config, Result, Instance, Stats, Cost, Diagnostic, reportOptions(IsRoomGridEnabled), Date, Report),
    writeReport(Output, Report),
    writeResultSchedule(PrologOutput, Result),
    format("Report written: ~a~n", [Output]).

%% A relationship between detected instance errors and execution interruption

checkInstanceErrors(_, []).

checkInstanceErrors(Input, [Error|Errors]) :-
    finishMeasurement(0, 0, Stats),
    throw(instanceErrors(Input, [Error|Errors], Stats)).

%% A relationship between a search result and its output data

prepareResultData(result(found, schedule(Schedule)), _, _, Cost, [], 0) :-
    scheduleCost(Schedule, Cost).

prepareResultData(result(limitReached, schedule(Schedule)), _, _, Cost, [], 3) :-
    scheduleCost(Schedule, Cost).

prepareResultData(result(noSolution, none), SearchDiagnostic, TotalSessions, unavailable, Diagnostic, 2) :-
    prepareDiagnostic(TotalSessions, SearchDiagnostic, Diagnostic).

prepareResultData(result(limitReached, none), SearchDiagnostic, TotalSessions, unavailable, Diagnostic, 3) :-
    prepareDiagnostic(TotalSessions, SearchDiagnostic, Diagnostic).

%% A relationship between instance measures and available diagnostic lines

prepareDiagnostic(TotalSessions, SearchDiagnostic, Diagnostic) :-
    instanceSetting("dias", Days),
    length(Days, DayCount),
    instanceSetting("franjas", DailySlotCount),
    WeeklySlotCount is DayCount*DailySlotCount,
    findall(Room, room(Room, _, _), Rooms),
    length(Rooms, RoomCount),
    WeeklyRoomSlotCount is RoomCount*WeeklySlotCount,
    findall([Course, Group, WeeklySessions, Duration], group(Course, Group, _, _, WeeklySessions, Duration, _), Groups),
    findall(
        groupKey(Course, Group)-RequiredSlots,
        (
            member([Course, Group, WeeklySessions, Duration], Groups),
            RequiredSlots is WeeklySessions*Duration
        ),
        GroupLoads
    ),
    findall(
        teacher(Teacher)-RequiredSlots,
        (
            teacher(Teacher, _, _, _),
            teacherRequiredSlots(Teacher, Groups, RequiredSlots)
        ),
        TeacherLoads
    ),
    append(GroupLoads, TeacherLoads, RequiredLoads),
    greatestRequiredLoad(RequiredLoads, none, Greatest),
    diagnosticLoadLine(Greatest, LoadLine),
    number_codes(TotalSessions, SessionDigits),
    number_codes(WeeklySlotCount, SlotDigits),
    number_codes(WeeklyRoomSlotCount, RoomSlotDigits),
    append("Required sessions: ", SessionDigits, SessionLine),
    append("Weekly time slots: ", SlotDigits, SlotLine),
    append("Weekly room slots: ", RoomSlotDigits, RoomSlotLine),
    append([SessionLine, SlotLine, RoomSlotLine, LoadLine], SearchDiagnostic, Diagnostic).

%% A relationship between required resource loads and the greatest one

greatestRequiredLoad([], Greatest, Greatest).

greatestRequiredLoad([RequiredLoad|RequiredLoads], none, Greatest) :-
    !,
    greatestRequiredLoad(RequiredLoads, RequiredLoad, Greatest).

greatestRequiredLoad([Resource-RequiredSlots|RequiredLoads], _-GreatestSlots, Greatest) :-
    RequiredSlots > GreatestSlots,
    !,
    greatestRequiredLoad(RequiredLoads, Resource-RequiredSlots, Greatest).

greatestRequiredLoad([_|RequiredLoads], CurrentGreatest, Greatest) :-
    greatestRequiredLoad(RequiredLoads, CurrentGreatest, Greatest).

%% A relationship between the greatest required load and its diagnostic text

diagnosticLoadLine(none, "Largest required weekly load: no groups or teachers").

diagnosticLoadLine(groupKey(Course, Group)-RequiredSlots, Line) :-
    number_codes(RequiredSlots, Digits),
    append("Largest required weekly load: group ", Course, Line1),
    append(Line1, "/", Line2),
    append(Line2, Group, Line3),
    append(Line3, ", ", Line4),
    append(Line4, Digits, Line5),
    append(Line5, " slots", Line).

diagnosticLoadLine(teacher(Teacher)-RequiredSlots, Line) :-
    number_codes(RequiredSlots, Digits),
    append("Largest required weekly load: teacher ", Teacher, Line1),
    append(Line1, ", ", Line2),
    append(Line2, Digits, Line3),
    append(Line3, " slots", Line).

%% A relationship between a proven scheduling cause and diagnostic lines

diagnosticCauseLines(none, []).

diagnosticCauseLines(implicitConstraints, ["The implicit hard constraints have no complete schedule", "No declared restriction is needed to prove this conflict", "Diagnostic searches have no node limit", "Measurements include diagnostic searches"]).

diagnosticCauseLines(blockingRestriction(record(Line, ["aula_fija", Course, Group, Room])), [LineText, RestrictionText, "Impact: removes all schedules allowed by earlier declarations", "Diagnostic searches have no node limit", "Measurements include diagnostic searches"]) :-
    number_codes(Line, LineDigits),
    append("First blocking declared restriction: line ", LineDigits, LineText),
    append("Fixed room: ", Course, Text1),
    append(Text1, "/", Text2),
    append(Text2, Group, Text3),
    append(Text3, " in ", Text4),
    append(Text4, Room, RestrictionText).

diagnosticCauseLines(blockingRestriction(record(Line, ["prohibida", Course, Group, daySlot(Day, Slot)])), [LineText, RestrictionText, "Impact: removes all schedules allowed by earlier declarations", "Diagnostic searches have no node limit", "Measurements include diagnostic searches"]) :-
    number_codes(Line, LineDigits),
    number_codes(Slot, SlotDigits),
    append("First blocking declared restriction: line ", LineDigits, LineText),
    append("Forbidden slot: ", Course, Text1),
    append(Text1, "/", Text2),
    append(Text2, Group, Text3),
    append(Text3, " at ", Text4),
    append(Text4, Day, Text5),
    append(Text5, SlotDigits, RestrictionText).

diagnosticCauseLines(blockingRestriction(record(Line, ["excluyentes", Course, Group, OtherCourse, OtherGroup])), [LineText, RestrictionText, "Impact: removes all schedules allowed by earlier declarations", "Diagnostic searches have no node limit", "Measurements include diagnostic searches"]) :-
    number_codes(Line, LineDigits),
    append("First blocking declared restriction: line ", LineDigits, LineText),
    append("Exclusive groups: ", Course, Text1),
    append(Text1, "/", Text2),
    append(Text2, Group, Text3),
    append(Text3, " and ", Text4),
    append(Text4, OtherCourse, Text5),
    append(Text5, "/", Text6),
    append(Text6, OtherGroup, RestrictionText).

%% A relationship between the execution date and its text bytes

executionDate(Date) :-
    date_time(dt(Year, Month, DayOfMonth, Hour, Minute, Second)),
    number_codes(Year, YearDigits),
    twoDigitBytes(Month, MonthTens, MonthUnits),
    twoDigitBytes(DayOfMonth, DayTens, DayUnits),
    twoDigitBytes(Hour, HourTens, HourUnits),
    twoDigitBytes(Minute, MinuteTens, MinuteUnits),
    twoDigitBytes(Second, SecondTens, SecondUnits),
    append(YearDigits, [45, MonthTens, MonthUnits, 45, DayTens, DayUnits, 32, HourTens, HourUnits, 58, MinuteTens, MinuteUnits, 58, SecondTens, SecondUnits], Date).

%% A relationship between a two digit number and its digit bytes

twoDigitBytes(Number, TensByte, UnitsByte) :-
    TensByte is 48+Number//10,
    UnitsByte is 48+Number mod 10.

%% A relationship between a requested output and the result schedule

writeResultSchedule(none, _) :-
    !.

writeResultSchedule(prologFile(PrologPath), result(_, none)) :-
    format("No complete schedule to export: ~a~n", [PrologPath]).

writeResultSchedule(prologFile(PrologPath), result(_, schedule(Schedule))) :-
    writeSchedule(PrologPath, Schedule).

%% A relationship between execution errors and their terminal messages

writeExecutionError(_, argumentError(Argument, Cause)) :-
    !,
    format(user_error, "Argument ~w: ", [Argument]),
    writeExecutionCause(Cause),
    nl(user_error),
    format(user_error, "Usage: horarios.sh INPUT OUTPUT bt|clpfd [OPTIONS]~n", []),
    format(user_error, "Options: --optimizar --heuristica=original|mrv|degree|demand|lcv|ff --limite=N~n", []),
    format(user_error, "         --exportar-prolog=PATH --horarios-por-aula~nff requires clpfd~n", []).

writeExecutionError(_, instanceReadError(Path, Cause)) :-
    !,
    finishMeasurement(0, 0, Stats),
    format(user_error, "Could not read ~a: ", [Path]),
    writeExecutionCause(Cause),
    nl(user_error),
    writeReportStats(user_error, Stats).

writeExecutionError([Input|_], instanceParseError(Line, Cause)) :-
    !,
    finishMeasurement(0, 0, Stats),
    format(user_error, "Input ~a, line ~d: ", [Input, Line]),
    writeExecutionCause(Cause),
    nl(user_error),
    writeReportStats(user_error, Stats).

writeExecutionError(_, instanceErrors(Input, Errors, Stats)) :-
    !,
    format(user_error, "Instance errors in ~a~n", [Input]),
    writeReportDiagnostic(user_error, Errors),
    writeReportStats(user_error, Stats).

writeExecutionError(_, reportWriteError(Path, Cause)) :-
    !,
    format(user_error, "Could not write report ~a: ", [Path]),
    writeExecutionCause(Cause),
    nl(user_error).

writeExecutionError(_, scheduleWriteError(Path, Cause)) :-
    !,
    format(user_error, "Could not write schedule ~a: ", [Path]),
    writeExecutionCause(Cause),
    nl(user_error).

writeExecutionError([Input|_], Error) :-
    format(user_error, "Execution error in ~a: ", [Input]),
    writeExecutionCause(Error),
    nl(user_error).

%% A relationship between an error cause and its readable text

writeExecutionCause(Cause) :-
    is_list(Cause),
    !,
    format(user_error, "~s", [Cause]).

writeExecutionCause(error(existence_error(source_sink, _), _)) :-
    !,
    format(user_error, "Path does not exist", []).

writeExecutionCause(error(permission_error(_, source_sink, _), _)) :-
    !,
    format(user_error, "Permission denied", []).

writeExecutionCause(Cause) :-
    writeq(user_error, Cause).
