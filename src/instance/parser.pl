%% A relationship between file bytes and a complete instance

parseInstance(Bytes, Instance) :-
    parseLines(Bytes, 1, none, [], ParsedInstance),
    Instance = ParsedInstance.

%% A relationship between remaining lines and their grouped records

parseLines([], _, _, _, instance([], [], [], [], [], [])).

parseLines([Byte|Bytes], Line, Section, SeenSections, Instance) :-
    takeLine([Byte|Bytes], LineBytes, RemainingBytes),
    parseLine(LineBytes, Line, Section, Entry),
    NextLine is Line+1,
    parseEntry(Entry, RemainingBytes, NextLine, Section, SeenSections, Instance).

%% A relationship between bytes, a line and the remaining bytes

takeLine([], [], []).

takeLine([10|Bytes], [], Bytes) :- !.

takeLine([Byte|Bytes], [Byte|LineBytes], RemainingBytes) :-
    takeLine(Bytes, LineBytes, RemainingBytes).

%% A relationship between a line and its entry

parseLine([], _, _, skip) :- !.

parseLine([35, 58|Name], _, _, section(Section)) :-
    member([Name, Section], [["CONFIG", config], ["AULA", rooms], ["PROFESOR", teachers],
        ["CURSO", groups], ["IMPARTE", teaching], ["RESTRICCION", restrictions]]), !.

parseLine([35, 58|_], Line, _, _) :-
    !,
    throw(instanceParseError(Line, "Expected a known section name after #:")).

parseLine([35|_], _, _, skip) :- !.

parseLine(_, Line, none, _) :-
    !,
    throw(instanceParseError(Line, "A data record appears before any section")).

parseLine(LineBytes, Line, _, _) :-
    member(35, LineBytes), !,
    throw(instanceParseError(Line, "Unexpected # in a data record")).

parseLine(LineBytes, Line, Section, record(Line, Values)) :-
    splitBytes(LineBytes, 59, Fields),
    trimFields(Fields, TrimmedFields),
    parseRecord(Section, TrimmedFields, Line, Values).

%% A relationship between an entry and the remaining instance

parseEntry(skip, Bytes, Line, Section, SeenSections, Instance) :-
    parseLines(Bytes, Line, Section, SeenSections, Instance).

parseEntry(section(Section), _, NextLine, _, SeenSections, _) :-
    member(Section, SeenSections), !,
    Line is NextLine-1,
    throw(instanceParseError(Line, "A section header appears more than once")).

parseEntry(section(Section), Bytes, Line, _, SeenSections, Instance) :-
    parseLines(Bytes, Line, Section, [Section|SeenSections], Instance).

parseEntry(record(RecordLine, Values), Bytes, Line, Section, SeenSections, Instance) :-
    parseLines(Bytes, Line, Section, SeenSections, RemainingInstance),
    addRecord(Section, record(RecordLine, Values), RemainingInstance, Instance).

%% A relationship between a record and its section list

addRecord(config, Record, instance(Settings, Rooms, Teachers, Groups, Teaching, Restrictions),
        instance([Record|Settings], Rooms, Teachers, Groups, Teaching, Restrictions)).

addRecord(rooms, Record, instance(Settings, Rooms, Teachers, Groups, Teaching, Restrictions),
        instance(Settings, [Record|Rooms], Teachers, Groups, Teaching, Restrictions)).

addRecord(teachers, Record, instance(Settings, Rooms, Teachers, Groups, Teaching, Restrictions),
        instance(Settings, Rooms, [Record|Teachers], Groups, Teaching, Restrictions)).

addRecord(groups, Record, instance(Settings, Rooms, Teachers, Groups, Teaching, Restrictions),
        instance(Settings, Rooms, Teachers, [Record|Groups], Teaching, Restrictions)).

addRecord(teaching, Record, instance(Settings, Rooms, Teachers, Groups, Teaching, Restrictions),
        instance(Settings, Rooms, Teachers, Groups, [Record|Teaching], Restrictions)).

addRecord(restrictions, Record, instance(Settings, Rooms, Teachers, Groups, Teaching, Restrictions),
        instance(Settings, Rooms, Teachers, Groups, Teaching, [Record|Restrictions])).

%% A relationship between section fields and their values

parseRecord(config, ["dias", Bytes], _, ["dias", Days]) :-
    parseDays(Bytes, Days), !.

parseRecord(config, ["franjas", Bytes], _, ["franjas", Slots]) :-
    parseNumber(Bytes, Slots), !.

parseRecord(config, ["inicio", Bytes], _, ["inicio", Time]) :-
    parseTime(Bytes, Time), !.

parseRecord(config, ["duracion_franja", Bytes], _, ["duracion_franja", Duration]) :-
    parseNumber(Bytes, Duration), !.

parseRecord(config, _, Line, _) :-
    throw(instanceParseError(Line, "Expected a known configuration key and a correctly formatted value")).

parseRecord(rooms, [Code, CapacityBytes, Type], _, [Code, Capacity, Type]) :-
    Code = [_|_],
    parseNumber(CapacityBytes, Capacity),
    member(Type, ["teoria", "laboratorio", "mixta"]), !.

parseRecord(rooms, _, Line, _) :-
    throw(instanceParseError(Line, "Expected a nonempty room code, nonnegative capacity and a known room type")).

parseRecord(teachers, [Code, Name, MaxBytes, AvailabilityBytes], _,
        [Code, Name, MaxSlots, Availability]) :-
    Code = [_|_], Name = [_|_],
    parseNumber(MaxBytes, MaxSlots),
    parseAvailability(AvailabilityBytes, Availability), !.

parseRecord(teachers, _, Line, _) :-
    throw(instanceParseError(Line, "Expected nonempty teacher code and name, nonnegative maximum and valid availability")).

parseRecord(groups, [Course, Name, Group, EnrolledBytes, WeeklyBytes, DurationBytes, Requirement], _,
        [Course, Name, Group, Enrolled, WeeklySessions, Duration, Requirement]) :-
    Course = [_|_], Name = [_|_], Group = [_|_],
    parseNumber(EnrolledBytes, Enrolled),
    parseNumber(WeeklyBytes, WeeklySessions),
    parseNumber(DurationBytes, Duration),
    member(Requirement, ["teoria", "laboratorio", "mixta"]), !.

parseRecord(groups, _, Line, _) :-
    throw(instanceParseError(Line, "Expected seven course fields with nonempty text, nonnegative integers and a known requirement")).

parseRecord(teaching, [Course, Group, Teacher], _, [Course, Group, Teacher]) :-
    Course = [_|_], Group = [_|_], Teacher = [_|_], !.

parseRecord(teaching, _, Line, _) :-
    throw(instanceParseError(Line, "Expected nonempty course, group and teacher codes")).

parseRecord(restrictions, ["aula_fija", Course, Group, Room], _, ["aula_fija", Course, Group, Room]) :-
    Course = [_|_], Group = [_|_], Room = [_|_], !.

parseRecord(restrictions, ["prohibida", Course, Group, SlotBytes], _, ["prohibida", Course, Group, Slot]) :-
    Course = [_|_], Group = [_|_],
    parseDaySlot(SlotBytes, Slot), !.

parseRecord(restrictions, ["excluyentes", Course, Group, OtherCourse, OtherGroup], _,
        ["excluyentes", Course, Group, OtherCourse, OtherGroup]) :-
    Course = [_|_], Group = [_|_], OtherCourse = [_|_], OtherGroup = [_|_], !.

parseRecord(restrictions, ["prefiere", Course, Group, SlotBytes, WeightBytes], _,
        ["prefiere", Course, Group, Slot, Weight]) :-
    Course = [_|_], Group = [_|_],
    parseDaySlot(SlotBytes, Slot),
    parseNumber(WeightBytes, Weight), !.

parseRecord(restrictions, ["compacta", Course, Group, WeightBytes], _,
        ["compacta", Course, Group, Weight]) :-
    Course = [_|_], Group = [_|_],
    parseNumber(WeightBytes, Weight), !.

parseRecord(restrictions, _, Line, _) :-
    throw(instanceParseError(Line, "Expected a known restriction type with its nonempty arguments and valid numeric fields")).
