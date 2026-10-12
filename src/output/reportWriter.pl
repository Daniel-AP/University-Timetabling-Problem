%% A relationship between an output path and its written report

writeReport(Path, Report) :-
    catch(open(Path, write, Stream), Cause, throw(reportWriteError(Path, Cause))),
    writeReportStream(Path, Stream, Report, ExpectedBytes),
    checkReportSize(Path, ExpectedBytes).

%% A relationship between an open file, its report and its byte count

writeReportStream(Path, Stream, Report, ExpectedBytes) :-
    catch(
        (
            writeReportBlocks(Stream, Report),
            character_count(Stream, ExpectedBytes),
            close(Stream)
        ),
        Cause,
        (
            catch(close(Stream, [force(true)]), _, true),
            throw(reportWriteError(Path, Cause))
        )
    ),
    !.

writeReportStream(Path, Stream, _, _) :-
    catch(close(Stream, [force(true)]), _, true),
    throw(reportWriteError(Path, "Could not write report")).

%% A relationship between a written file and its expected size

checkReportSize(Path, ExpectedBytes) :-
    catch(file_property(Path, size(ExpectedBytes)), Cause, throw(reportWriteError(Path, Cause))),
    !.

checkReportSize(Path, _) :-
    throw(reportWriteError(Path, "Incomplete report")).

%% A relationship between a prepared report and its written blocks

writeReportBlocks(Stream, report(Header, Detail, GroupGrids, TeacherGrids, RoomGrids, Conclusion)) :-
    writeReportHeader(Stream, Header),
    writeReportDetail(Stream, Detail),
    writeReportGrids(Stream, GroupGrids),
    writeReportGrids(Stream, TeacherGrids),
    writeReportGrids(Stream, RoomGrids),
    writeReportConclusion(Stream, Conclusion).

%% A relationship between a report header and its written fields

writeReportHeader(Stream, header(Input, Strategy, Heuristic, StateText, Date)) :-
    format(Stream, "================================================================~nUNIVERSITY TIMETABLING~n================================================================~n", []),
    format(Stream, "Instance: ~a~nStrategy: ~a~nHeuristic: ~a~nState: ~s~nDate: ~s~n", [Input, Strategy, Heuristic, StateText, Date]),
    format(Stream, "----------------------------------------------------------------~n", []).

%% A relationship between report detail and its written table

writeReportDetail(_, none) :-
    !.

writeReportDetail(Stream, Detail) :-
    format(Stream, "~nASSIGNMENT DETAIL~n# | Course | Group | Teachers | Room | Day | Slots~n", []),
    writeReportDetailRows(Stream, Detail).

%% A relationship between detail rows and their written assignments

writeReportDetailRows(_, []).

writeReportDetailRows(Stream, [detail(RowNumber, assignment(Course, Group, Teachers, Room, Day, _, _), Span)|Detail]) :-
    format(Stream, "~d | ~s | ~s | ", [RowNumber, Course, Group]),
    writeReportTeachers(Stream, Teachers),
    format(Stream, " | ~s | ~s | ", [Room, Day]),
    writeReportSpan(Stream, Span),
    nl(Stream),
    writeReportDetailRows(Stream, Detail).

%% A relationship between a teacher list and its written identifiers

writeReportTeachers(Stream, [Teacher]) :-
    !,
    format(Stream, "~s", [Teacher]).

writeReportTeachers(Stream, [Teacher|Teachers]) :-
    format(Stream, "~s, ", [Teacher]),
    writeReportTeachers(Stream, Teachers).

%% A relationship between a session span and its written slots

writeReportSpan(Stream, slots(Start, Start)) :-
    !,
    format(Stream, "~d", [Start]).

writeReportSpan(Stream, slots(Start, LastSlot)) :-
    format(Stream, "~d-~d", [Start, LastSlot]).

writeReportSpan(Stream, noSlots(Start)) :-
    format(Stream, "none (start ~d)", [Start]).

%% A relationship between report grids and their written tables

writeReportGrids(_, none).

writeReportGrids(_, []).

writeReportGrids(Stream, [grid(Resource, Days, Rows)|Grids]) :-
    writeReportResource(Stream, Resource),
    format(Stream, "Slot", []),
    writeReportDays(Stream, Days),
    writeReportRows(Stream, Rows),
    writeReportGrids(Stream, Grids).

%% A relationship between a grid resource and its written heading

writeReportResource(Stream, groupKey(Course, Group)) :-
    format(Stream, "~nSCHEDULE FOR GROUP: ~s ~s~n", [Course, Group]).

writeReportResource(Stream, teacher(Teacher)) :-
    format(Stream, "~nSCHEDULE FOR TEACHER: ~s~n", [Teacher]).

writeReportResource(Stream, room(Room)) :-
    format(Stream, "~nSCHEDULE FOR ROOM: ~s~n", [Room]).

%% A relationship between grid days and their written columns

writeReportDays(Stream, []) :-
    nl(Stream).

writeReportDays(Stream, [Day|Days]) :-
    format(Stream, " | ~s", [Day]),
    writeReportDays(Stream, Days).

%% A relationship between grid rows and their written positions and cells

writeReportRows(_, []).

writeReportRows(Stream, [row(Position, Cells)|Rows]) :-
    format(Stream, "~d", [Position]),
    writeReportCells(Stream, Cells),
    nl(Stream),
    writeReportRows(Stream, Rows).

%% A relationship between grid cells and their written contents

writeReportCells(_, []).

writeReportCells(Stream, [empty|Cells]) :-
    format(Stream, " | --", []),
    writeReportCells(Stream, Cells).

writeReportCells(Stream, [groupKey(Course, Group)|Cells]) :-
    format(Stream, " | ~s/~s", [Course, Group]),
    writeReportCells(Stream, Cells).

%% A relationship between a report conclusion and its written summary or diagnostic

writeReportConclusion(Stream, summary(SessionCount, SessionSlotCount, GroupGaps, TeacherGaps, Cost, Stats, NodeRate, FinalText)) :-
    format(Stream, "~n----------------------------------------------------------------~nSUMMARY~n", []),
    format(Stream, "Scheduled sessions: ~d~nOccupied session slots: ~d~nGroup gaps: ~d~nTeacher gaps: ~d~nSoft constraint cost: ~w~n", [SessionCount, SessionSlotCount, GroupGaps, TeacherGaps, Cost]),
    writeReportStats(Stream, Stats),
    writeReportNodeRate(Stream, NodeRate),
    format(Stream, "Final state: ~s~n----------------------------------------------------------------~n", [FinalText]).

writeReportConclusion(Stream, diagnosticBlock(FinalText, Diagnostic, Stats, NodeRate)) :-
    format(Stream, "~n----------------------------------------------------------------~nDIAGNOSTIC~n", []),
    writeReportDiagnostic(Stream, Diagnostic),
    writeReportStats(Stream, Stats),
    writeReportNodeRate(Stream, NodeRate),
    format(Stream, "Final state: ~s~n----------------------------------------------------------------~n", [FinalText]).

%% A relationship between diagnostic lines and their written information

writeReportDiagnostic(Stream, []) :-
    format(Stream, "Diagnostic information: unavailable~n", []).

writeReportDiagnostic(Stream, [Line]) :-
    !,
    format(Stream, "~s~n", [Line]).

writeReportDiagnostic(Stream, [Line|Lines]) :-
    format(Stream, "~s~n", [Line]),
    writeReportDiagnostic(Stream, Lines).

%% A relationship between search statistics and their written metrics

writeReportStats(Stream, unavailable) :-
    format(Stream, "Explored nodes: unavailable~nBacktracks: unavailable~nCPU time (s): unavailable~nWall time (s): unavailable~n", []).

writeReportStats(Stream, searchStats(Nodes, Backtracks, CpuTime, WallTime)) :-
    format(Stream, "Explored nodes: ~d~nBacktracks: ~d~nCPU time (s): ~w~nWall time (s): ~w~n", [Nodes, Backtracks, CpuTime, WallTime]).

%% A relationship between a report node rate and its written value

writeReportNodeRate(Stream, unavailable) :-
    !,
    format(Stream, "Nodes per second: unavailable~n", []).

writeReportNodeRate(Stream, notCalculable) :-
    !,
    format(Stream, "Nodes per second: not calculable~n", []).

writeReportNodeRate(Stream, NodeRate) :-
    format(Stream, "Nodes per second: ~w~n", [NodeRate]).
