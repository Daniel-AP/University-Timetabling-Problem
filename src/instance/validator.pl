%% A relationship between an instance and its errors

validateInstance(Instance, Errors) :-
    Instance = instance(Settings, Rooms, Teachers, Groups, Teaching, Restrictions),
    validateSettings(Settings, IsDaysValid, IsSlotsValid, SettingErrors),
    validateRecords(rooms, Rooms, Instance, IsDaysValid, IsSlotsValid, RoomErrors),
    validateRecords(teachers, Teachers, Instance, IsDaysValid, IsSlotsValid, TeacherErrors),
    validateRecords(groups, Groups, Instance, IsDaysValid, IsSlotsValid, GroupErrors),
    validateRecords(teaching, Teaching, Instance, IsDaysValid, IsSlotsValid, TeachingErrors),
    validateRecords(restrictions, Restrictions, Instance, IsDaysValid, IsSlotsValid, RestrictionErrors),
    append(SettingErrors, RoomErrors, Errors1),
    append(Errors1, TeacherErrors, Errors2),
    append(Errors2, GroupErrors, Errors3),
    append(Errors3, TeachingErrors, Errors4),
    append(Errors4, RestrictionErrors, Errors).

%% A relationship between settings and their checks

validateSettings(Settings, IsDaysValid, IsSlotsValid, Errors) :-
    Keys = ["dias", "franjas", "inicio", "duracion_franja"],
    validateRequiredSettings(Keys, Settings, MissingErrors),
    validateSettings(Settings, Settings, 0, 0, IsDaysValid, IsSlotsValid, RecordErrors),
    append(MissingErrors, RecordErrors, Errors).

%% A relationship between settings and key counts

validateSettings([], _, 1, 1, true, true, []).

validateSettings([], _, 1, SlotCount, true, false, []) :-
    SlotCount =\= 1.

validateSettings([], _, DayCount, 1, false, true, []) :-
    DayCount =\= 1.

validateSettings([], _, DayCount, SlotCount, false, false, []) :-
    DayCount =\= 1, SlotCount =\= 1.

validateSettings([record(Line, ["dias", _])|Records], Settings, DayCount, SlotCount,
        IsDaysValid, IsSlotsValid, Errors) :-
    validateDuplicate(config, "dias", Line, Settings, CurrentErrors),
    NextCount is DayCount+1,
    validateSettings(Records, Settings, NextCount, SlotCount, IsDaysValid, IsSlotsValid, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

validateSettings([record(Line, ["franjas", _])|Records], Settings, DayCount, SlotCount,
        IsDaysValid, IsSlotsValid, Errors) :-
    validateDuplicate(config, "franjas", Line, Settings, CurrentErrors),
    NextCount is SlotCount+1,
    validateSettings(Records, Settings, DayCount, NextCount, IsDaysValid, IsSlotsValid, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

validateSettings([record(Line, ["inicio", Time])|Records], Settings, DayCount, SlotCount,
        IsDaysValid, IsSlotsValid, Errors) :-
    validateDuplicate(config, "inicio", Line, Settings, DuplicateErrors),
    validateStartTime(Time, Line, TimeErrors),
    append(DuplicateErrors, TimeErrors, CurrentErrors),
    validateSettings(Records, Settings, DayCount, SlotCount, IsDaysValid, IsSlotsValid, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

validateSettings([record(Line, ["duracion_franja", _])|Records], Settings, DayCount, SlotCount,
        IsDaysValid, IsSlotsValid, Errors) :-
    validateDuplicate(config, "duracion_franja", Line, Settings, CurrentErrors),
    validateSettings(Records, Settings, DayCount, SlotCount, IsDaysValid, IsSlotsValid, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

%% A relationship between required keys and missing settings

validateRequiredSettings([], _, []).

validateRequiredSettings([Key|Keys], Settings, Errors) :-
    findRecord(config, Key, Settings, _), !,
    validateRequiredSettings(Keys, Settings, Errors).

validateRequiredSettings([Key|Keys], Settings, [Message|Errors]) :-
    append("CONFIG: Missing required key ", Key, Message),
    validateRequiredSettings(Keys, Settings, Errors).

%% A relationship between a start time and its range errors

validateStartTime(startTime(Hour, Minute), _, []) :-
    Hour =< 23, Minute =< 59, !.

validateStartTime(_, Line, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Invalid start time", Message).

%% A relationship between section records and all their errors

validateRecords(_, [], _, _, _, []).

validateRecords(Section, [Record|Records], Instance, IsDaysValid, IsSlotsValid, Errors) :-
    validateRecord(Section, Record, Instance, IsDaysValid, IsSlotsValid, CurrentErrors),
    validateRecords(Section, Records, Instance, IsDaysValid, IsSlotsValid, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

%% A relationship between a record and its errors

validateRecord(rooms, record(Line, [Code, _, _]),
        instance(_, Rooms, _, _, _, _), _, _, Errors) :-
    validateDuplicate(rooms, Code, Line, Rooms, Errors).

validateRecord(teachers, record(Line, [Code, _, _, Availability]),
        instance(Settings, _, Teachers, _, _, _), IsDaysValid, IsSlotsValid, Errors) :-
    validateDuplicate(teachers, Code, Line, Teachers, DuplicateErrors),
    validateAvailability(Availability, Line, Settings, IsDaysValid, IsSlotsValid, RangeErrors),
    append(DuplicateErrors, RangeErrors, Errors).

validateRecord(groups, record(Line, [Course, _, Group, _, _, Duration, _]),
        instance(Settings, _, _, Groups, Teaching, _), _, IsSlotsValid, Errors) :-
    Key = groupKey(Course, Group),
    validateDuplicate(groups, Key, Line, Groups, DuplicateErrors),
    validateDuration(Duration, Line, Settings, IsSlotsValid, DurationErrors),
    validateGroupHasTeacher(Key, Line, Teaching, TeachingErrors),
    append(DuplicateErrors, DurationErrors, Errors1),
    append(Errors1, TeachingErrors, Errors).

validateRecord(teaching, record(Line, [Course, Group, Teacher]),
        instance(_, _, Teachers, Groups, _, _), _, _, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, GroupErrors),
    validateReference(teachers, Teacher, Line, Teachers, TeacherErrors),
    append(GroupErrors, TeacherErrors, Errors).

validateRecord(restrictions, record(Line, ["aula_fija", Course, Group, Room]),
        instance(_, Rooms, _, Groups, _, _), _, _, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, GroupErrors),
    validateReference(rooms, Room, Line, Rooms, RoomErrors),
    append(GroupErrors, RoomErrors, Errors).

validateRecord(restrictions, record(Line, ["prohibida", Course, Group, DaySlot]),
        instance(Settings, _, _, Groups, _, _), IsDaysValid, IsSlotsValid, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, GroupErrors),
    validateDaySlot(DaySlot, Line, Settings, IsDaysValid, IsSlotsValid, SlotErrors),
    append(GroupErrors, SlotErrors, Errors).

validateRecord(restrictions,
        record(Line, ["excluyentes", Course, Group, OtherCourse, OtherGroup]),
        instance(_, _, _, Groups, _, _), _, _, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, Errors1),
    validateReference(groups, groupKey(OtherCourse, OtherGroup), Line, Groups, OtherErrors),
    append(Errors1, OtherErrors, Errors).

validateRecord(restrictions, record(Line, ["prefiere", Course, Group, DaySlot, _]),
        instance(Settings, _, _, Groups, _, _), IsDaysValid, IsSlotsValid, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, GroupErrors),
    validateDaySlot(DaySlot, Line, Settings, IsDaysValid, IsSlotsValid, SlotErrors),
    append(GroupErrors, SlotErrors, Errors).

validateRecord(restrictions, record(Line, ["compacta", Course, Group, _]),
        instance(_, _, _, Groups, _, _), _, _, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, Errors).

%% A relationship between a key and its matching records

findRecord(config, Key, [Record|_], Record) :-
    Record = record(_, [Key, _]).

findRecord(rooms, Code, [Record|_], Record) :-
    Record = record(_, [Code, _, _]).

findRecord(teachers, Code, [Record|_], Record) :-
    Record = record(_, [Code, _, _, _]).

findRecord(groups, groupKey(Course, Group), [Record|_], Record) :-
    Record = record(_, [Course, _, Group, _, _, _, _]).

findRecord(Section, Key, [_|Records], Record) :-
    findRecord(Section, Key, Records, Record).

%% A relationship between a declaration and an earlier duplicate

validateDuplicate(config, Key, Line, Records, [Message]) :-
    findRecord(config, Key, Records, record(FirstLine, _)),
    FirstLine < Line, !,
    number_codes(Line, LineDigits),
    number_codes(FirstLine, FirstLineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Duplicate CONFIG key, first on line ", Message2),
    append(Message2, FirstLineDigits, Message).

validateDuplicate(rooms, Code, Line, Records, [Message]) :-
    findRecord(rooms, Code, Records, record(FirstLine, _)),
    FirstLine < Line, !,
    number_codes(Line, LineDigits),
    number_codes(FirstLine, FirstLineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Duplicate room code, first on line ", Message2),
    append(Message2, FirstLineDigits, Message).

validateDuplicate(teachers, Code, Line, Records, [Message]) :-
    findRecord(teachers, Code, Records, record(FirstLine, _)),
    FirstLine < Line, !,
    number_codes(Line, LineDigits),
    number_codes(FirstLine, FirstLineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Duplicate teacher code, first on line ", Message2),
    append(Message2, FirstLineDigits, Message).

validateDuplicate(groups, Key, Line, Records, [Message]) :-
    findRecord(groups, Key, Records, record(FirstLine, _)),
    FirstLine < Line, !,
    number_codes(Line, LineDigits),
    number_codes(FirstLine, FirstLineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Duplicate course-group pair, first on line ", Message2),
    append(Message2, FirstLineDigits, Message).

validateDuplicate(_, _, _, _, []).

%% A relationship between a reference and its declaration

validateReference(Section, Key, _, Records, []) :-
    findRecord(Section, Key, Records, _), !.

validateReference(groups, groupKey(Course, Group), Line, _, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Unknown group ", Message2),
    append(Message2, Course, Message3),
    append(Message3, "/", Message4),
    append(Message4, Group, Message).

validateReference(rooms, Code, Line, _, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Unknown room ", Message2),
    append(Message2, Code, Message).

validateReference(teachers, Code, Line, _, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Unknown teacher ", Message2),
    append(Message2, Code, Message).

%% A relationship between a day and the configured days

validateDay(_, _, _, false, []) :- !.

validateDay(Day, _, Settings, true, []) :-
    member(record(_, ["dias", Days]), Settings),
    member(Day, Days), !.

validateDay(Day, Line, _, true, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Unknown day ", Message2),
    append(Message2, Day, Message).

%% A relationship between a slot index and its bounds

validateSlot(Slot, Line, _, _, [Message]) :-
    Slot < 1, !,
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Slot must be at least 1", Message).

validateSlot(_, _, _, false, []) :- !.

validateSlot(Slot, _, Settings, true, []) :-
    member(record(_, ["franjas", Slots]), Settings),
    Slot =< Slots, !.

validateSlot(_, Line, _, true, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Slot exceeds the daily limit", Message).

%% A relationship between a day-slot pair and both its checks

validateDaySlot(daySlot(Day, Slot), Line, Settings, IsDaysValid, IsSlotsValid, Errors) :-
    validateDay(Day, Line, Settings, IsDaysValid, DayErrors),
    validateSlot(Slot, Line, Settings, IsSlotsValid, SlotErrors),
    append(DayErrors, SlotErrors, Errors).

%% A relationship between availability ranges and their errors

validateAvailability(all, _, _, _, _, []).

validateAvailability([], _, _, _, _, []).

validateAvailability([Range|Ranges], Line, Settings, IsDaysValid, IsSlotsValid, Errors) :-
    validateRange(Range, Line, Settings, IsDaysValid, IsSlotsValid, CurrentErrors),
    validateAvailability(Ranges, Line, Settings, IsDaysValid, IsSlotsValid, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

%% A relationship between a range and its errors

validateRange(dayRange(Start, End), Line, Settings, IsDaysValid, IsSlotsValid, Errors) :-
    validateDaySlot(Start, Line, Settings, IsDaysValid, IsSlotsValid, StartErrors),
    validateDaySlot(End, Line, Settings, IsDaysValid, IsSlotsValid, EndErrors),
    validateRangeOrder(dayRange(Start, End), Line, OrderErrors),
    append(StartErrors, EndErrors, EndpointErrors),
    append(EndpointErrors, OrderErrors, Errors).

%% A relationship between a range and its order

validateRangeOrder(dayRange(daySlot(StartDay, _), daySlot(EndDay, _)), Line, [Message]) :-
    StartDay \= EndDay, !,
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Availability range must stay in one day", Message).

validateRangeOrder(dayRange(daySlot(Day, StartSlot), daySlot(Day, EndSlot)), Line, [Message]) :-
    StartSlot > EndSlot, !,
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Availability range starts after it ends", Message).

validateRangeOrder(dayRange(daySlot(Day, StartSlot), daySlot(Day, EndSlot)), _, []) :-
    StartSlot =< EndSlot.

%% A relationship between a session duration and the daily slot count

validateDuration(_, _, _, false, []) :- !.

validateDuration(Duration, _, Settings, true, []) :-
    member(record(_, ["franjas", Slots]), Settings),
    Duration =< Slots, !.

validateDuration(_, Line, _, true, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Group duration exceeds the daily limit", Message).

%% A relationship between a group and at least one teaching declaration

validateGroupHasTeacher(groupKey(Course, Group), _, Teaching, []) :-
    member(record(_, [Course, Group, _]), Teaching), !.

validateGroupHasTeacher(groupKey(Course, Group), Line, _, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": No teacher for group ", Message2),
    append(Message2, Course, Message3),
    append(Message3, "/", Message4),
    append(Message4, Group, Message).
