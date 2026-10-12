%% A relationship between an output path and its written schedule

writeSchedule(Path, Schedule) :-
    catch(open(Path, write, Stream), Cause, throw(scheduleWriteError(Path, Cause))),
    writeScheduleStream(Path, Stream, Schedule, ExpectedBytes),
    checkScheduleSize(Path, ExpectedBytes).

%% A relationship between an open file, its schedule and its byte count

writeScheduleStream(Path, Stream, Schedule, ExpectedBytes) :-
    catch(
        (
            write(Stream, ':- dynamic(asignacion/7).'),
            nl(Stream),
            writeScheduleAssignments(Stream, Schedule),
            character_count(Stream, ExpectedBytes),
            close(Stream)
        ),
        Cause,
        (
            catch(close(Stream, [force(true)]), _, true),
            throw(scheduleWriteError(Path, Cause))
        )
    ),
    !.

writeScheduleStream(Path, Stream, _, _) :-
    catch(close(Stream, [force(true)]), _, true),
    throw(scheduleWriteError(Path, "Could not write schedule")).

%% A relationship between a written file and its expected size

checkScheduleSize(Path, ExpectedBytes) :-
    catch(file_property(Path, size(ExpectedBytes)), Cause, throw(scheduleWriteError(Path, Cause))),
    !.

checkScheduleSize(Path, _) :-
    throw(scheduleWriteError(Path, "Incomplete schedule")).

%% A relationship between schedule assignments and their written facts

writeScheduleAssignments(_, []).

writeScheduleAssignments(Stream, [assignment(Course, Group, Teachers, Room, Day, Start, Duration)|Schedule]) :-
    writeq(Stream, asignacion(Course, Group, Teachers, Room, Day, Start, Duration)),
    write(Stream, '.'),
    nl(Stream),
    writeScheduleAssignments(Stream, Schedule).
