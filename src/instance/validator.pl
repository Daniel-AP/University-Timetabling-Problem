%% A relationship between an instance and its errors

validateInstance(Instance, Errors) :-
    Instance = instance(Settings, Rooms, Teachers, Groups, Teaching, Restrictions),
    validateSettings(Settings, HasSingleDaySetting, HasSingleSlotSetting, SettingsErrors),
    validateRecords(rooms, Rooms, Instance, HasSingleDaySetting, HasSingleSlotSetting, RoomErrors),
    validateRecords(teachers, Teachers, Instance, HasSingleDaySetting, HasSingleSlotSetting, TeacherErrors),
    validateRecords(groups, Groups, Instance, HasSingleDaySetting, HasSingleSlotSetting, GroupErrors),
    validateRecords(teaching, Teaching, Instance, HasSingleDaySetting, HasSingleSlotSetting, TeachingErrors),
    validateRecords(restrictions, Restrictions, Instance, HasSingleDaySetting, HasSingleSlotSetting, RestrictionErrors),
    append(SettingsErrors, RoomErrors, Errors1),
    append(Errors1, TeacherErrors, Errors2),
    append(Errors2, GroupErrors, Errors3),
    append(Errors3, TeachingErrors, Errors4),
    append(Errors4, RestrictionErrors, Errors).

%% A relationship between settings and their errors

validateSettings(Settings, HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    Keys = ["dias", "franjas", "inicio", "duracion_franja"],
    validateRequiredSettings(Keys, Settings, MissingErrors),
    validateSettingRecords(Settings, Settings, 0, 0, HasSingleDaySetting, HasSingleSlotSetting, RecordErrors),
    append(MissingErrors, RecordErrors, Errors).

%% A relationship between settings and their key counts

validateSettingRecords([], _, 1, 1, true, true, []).

validateSettingRecords([], _, 1, SlotSettingCount, true, false, []) :-
    SlotSettingCount =\= 1.

validateSettingRecords([], _, DaySettingCount, 1, false, true, []) :-
    DaySettingCount =\= 1.

validateSettingRecords([], _, DaySettingCount, SlotSettingCount, false, false, []) :-
    DaySettingCount =\= 1,
    SlotSettingCount =\= 1.

validateSettingRecords([record(Line, ["dias", Days])|Records], Settings, DaySettingCount, SlotSettingCount, HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateDuplicate(config, "dias", Line, Settings, DuplicateErrors),
    validateDays(Days, Line, DayErrors),
    append(DuplicateErrors, DayErrors, CurrentErrors),
    NextCount is DaySettingCount+1,
    validateSettingRecords(Records, Settings, NextCount, SlotSettingCount, HasSingleDaySetting, HasSingleSlotSetting, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

validateSettingRecords([record(Line, ["franjas", _])|Records], Settings, DaySettingCount, SlotSettingCount, HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateDuplicate(config, "franjas", Line, Settings, CurrentErrors),
    NextCount is SlotSettingCount+1,
    validateSettingRecords(Records, Settings, DaySettingCount, NextCount, HasSingleDaySetting, HasSingleSlotSetting, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

validateSettingRecords([record(Line, ["inicio", Time])|Records], Settings, DaySettingCount, SlotSettingCount, HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateDuplicate(config, "inicio", Line, Settings, DuplicateErrors),
    validateStartTime(Time, Line, TimeErrors),
    append(DuplicateErrors, TimeErrors, CurrentErrors),
    validateSettingRecords(Records, Settings, DaySettingCount, SlotSettingCount, HasSingleDaySetting, HasSingleSlotSetting, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

validateSettingRecords([record(Line, ["duracion_franja", _])|Records], Settings, DaySettingCount, SlotSettingCount, HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateDuplicate(config, "duracion_franja", Line, Settings, CurrentErrors),
    validateSettingRecords(Records, Settings, DaySettingCount, SlotSettingCount, HasSingleDaySetting, HasSingleSlotSetting, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

%% A relationship between configured days and their errors

validateDays([], _, []).

validateDays([Day|Days], Line, [Message|Errors]) :-
    member(Day, Days),
    !,
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Duplicate day ", Message2),
    append(Message2, Day, Message),
    validateDays(Days, Line, Errors).

validateDays([_|Days], Line, Errors) :-
    validateDays(Days, Line, Errors).

%% A relationship between required keys and missing settings

validateRequiredSettings([], _, []).

validateRequiredSettings([Key|Keys], Settings, Errors) :-
    findRecord(config, Key, Settings, _),
    !,
    validateRequiredSettings(Keys, Settings, Errors).

validateRequiredSettings([Key|Keys], Settings, [Message|Errors]) :-
    append("CONFIG: Missing required key ", Key, Message),
    validateRequiredSettings(Keys, Settings, Errors).

%% A relationship between a start time and its errors

validateStartTime(startTime(Hour, Minute), _, []) :-
    Hour =< 23,
    Minute =< 59,
    !.

validateStartTime(_, Line, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Invalid start time", Message).

%% A relationship between section records and their errors

validateRecords(_, [], _, _, _, []).

validateRecords(Section, [Record|Records], Instance, HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateRecord(Section, Record, Instance, HasSingleDaySetting, HasSingleSlotSetting, CurrentErrors),
    validateRecords(Section, Records, Instance, HasSingleDaySetting, HasSingleSlotSetting, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

%% A relationship between a record and its errors

validateRecord(rooms, record(Line, [Code, _, _]), instance(_, Rooms, _, _, _, _), _, _, Errors) :-
    validateDuplicate(rooms, Code, Line, Rooms, Errors).

validateRecord(teachers, record(Line, [Teacher, _, _, Availability]), instance(Settings, _, Teachers, _, _, _), HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateDuplicate(teachers, Teacher, Line, Teachers, DuplicateErrors),
    validateAvailability(Availability, Line, Settings, HasSingleDaySetting, HasSingleSlotSetting, RangeErrors),
    append(DuplicateErrors, RangeErrors, Errors).

validateRecord(groups, record(Line, [Course, _, Group, _, _, Duration, _]), instance(Settings, _, _, Groups, Teaching, _), _, HasSingleSlotSetting, Errors) :-
    Key = groupKey(Course, Group),
    validateDuplicate(groups, Key, Line, Groups, DuplicateErrors),
    validateDuration(Duration, Line, Settings, HasSingleSlotSetting, DurationErrors),
    validateGroupHasTeacher(Key, Line, Teaching, TeachingErrors),
    append(DuplicateErrors, DurationErrors, Errors1),
    append(Errors1, TeachingErrors, Errors).

validateRecord(teaching, record(Line, [Course, Group, Teacher]), instance(_, _, Teachers, Groups, _, _), _, _, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, GroupErrors),
    validateReference(teachers, Teacher, Line, Teachers, TeacherErrors),
    append(GroupErrors, TeacherErrors, Errors).

validateRecord(restrictions, record(Line, ["aula_fija", Course, Group, Room]), instance(_, Rooms, _, Groups, _, _), _, _, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, GroupErrors),
    validateReference(rooms, Room, Line, Rooms, RoomErrors),
    append(GroupErrors, RoomErrors, Errors).

validateRecord(restrictions, record(Line, ["prohibida", Course, Group, DaySlot]), instance(Settings, _, _, Groups, _, _), HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, GroupErrors),
    validateDaySlot(DaySlot, Line, Settings, HasSingleDaySetting, HasSingleSlotSetting, SlotErrors),
    append(GroupErrors, SlotErrors, Errors).

validateRecord(restrictions, record(Line, ["excluyentes", Course, Group, OtherCourse, OtherGroup]), instance(_, _, _, Groups, _, _), _, _, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, Errors1),
    validateReference(groups, groupKey(OtherCourse, OtherGroup), Line, Groups, OtherErrors),
    append(Errors1, OtherErrors, Errors).

validateRecord(restrictions, record(Line, ["prefiere", Course, Group, DaySlot, _]), instance(Settings, _, _, Groups, _, _), HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, GroupErrors),
    validateDaySlot(DaySlot, Line, Settings, HasSingleDaySetting, HasSingleSlotSetting, SlotErrors),
    append(GroupErrors, SlotErrors, Errors).

validateRecord(restrictions, record(Line, ["compacta", Course, Group, _]), instance(_, _, _, Groups, _, _), _, _, Errors) :-
    validateReference(groups, groupKey(Course, Group), Line, Groups, Errors).

%% A relationship between a key and its matching records

findRecord(config, Key, [Record|_], Record) :-
    Record = record(_, [Key, _]).

findRecord(rooms, Code, [Record|_], Record) :-
    Record = record(_, [Code, _, _]).

findRecord(teachers, Teacher, [Record|_], Record) :-
    Record = record(_, [Teacher, _, _, _]).

findRecord(groups, groupKey(Course, Group), [Record|_], Record) :-
    Record = record(_, [Course, _, Group, _, _, _, _]).

findRecord(Section, Key, [_|Records], Record) :-
    findRecord(Section, Key, Records, Record).

%% A relationship between a record and an earlier duplicate

validateDuplicate(config, Key, Line, Records, [Message]) :-
    findRecord(config, Key, Records, record(FirstLine, _)),
    FirstLine < Line,
    !,
    number_codes(Line, LineDigits),
    number_codes(FirstLine, FirstLineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Duplicate CONFIG key, first on line ", Message2),
    append(Message2, FirstLineDigits, Message).

validateDuplicate(rooms, Code, Line, Records, [Message]) :-
    findRecord(rooms, Code, Records, record(FirstLine, _)),
    FirstLine < Line,
    !,
    number_codes(Line, LineDigits),
    number_codes(FirstLine, FirstLineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Duplicate room code, first on line ", Message2),
    append(Message2, FirstLineDigits, Message).

validateDuplicate(teachers, Teacher, Line, Records, [Message]) :-
    findRecord(teachers, Teacher, Records, record(FirstLine, _)),
    FirstLine < Line,
    !,
    number_codes(Line, LineDigits),
    number_codes(FirstLine, FirstLineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Duplicate teacher code, first on line ", Message2),
    append(Message2, FirstLineDigits, Message).

validateDuplicate(groups, Key, Line, Records, [Message]) :-
    findRecord(groups, Key, Records, record(FirstLine, _)),
    FirstLine < Line,
    !,
    number_codes(Line, LineDigits),
    number_codes(FirstLine, FirstLineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Duplicate course-group pair, first on line ", Message2),
    append(Message2, FirstLineDigits, Message).

validateDuplicate(_, _, _, _, []).

%% A relationship between a used code and its declared record

validateReference(Section, Key, _, Records, []) :-
    findRecord(Section, Key, Records, _),
    !.

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

validateReference(teachers, Teacher, Line, _, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Unknown teacher ", Message2),
    append(Message2, Teacher, Message).

%% A relationship between a day and the allowed days

validateDay(_, _, _, false, []) :-
    !.

validateDay(Day, _, Settings, true, []) :-
    member(record(_, ["dias", Days]), Settings),
    member(Day, Days),
    !.

validateDay(Day, Line, _, true, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Unknown day ", Message2),
    append(Message2, Day, Message).

%% A relationship between a slot number and its allowed range

validateSlot(Slot, Line, _, _, [Message]) :-
    Slot < 1,
    !,
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Slot must be at least 1", Message).

validateSlot(_, _, _, false, []) :-
    !.

validateSlot(Slot, _, Settings, true, []) :-
    member(record(_, ["franjas", DailySlotCount]), Settings),
    Slot =< DailySlotCount,
    !.

validateSlot(_, Line, _, true, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Slot exceeds the daily limit", Message).

%% A relationship between a day and slot number and their errors

validateDaySlot(daySlot(Day, Slot), Line, Settings, HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateDay(Day, Line, Settings, HasSingleDaySetting, DayErrors),
    validateSlot(Slot, Line, Settings, HasSingleSlotSetting, SlotErrors),
    append(DayErrors, SlotErrors, Errors).

%% A relationship between availability ranges and their errors

validateAvailability(all, _, _, _, _, []).

validateAvailability([], _, _, _, _, []).

validateAvailability([Range|Ranges], Line, Settings, HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateRange(Range, Line, Settings, HasSingleDaySetting, HasSingleSlotSetting, CurrentErrors),
    validateAvailability(Ranges, Line, Settings, HasSingleDaySetting, HasSingleSlotSetting, RestErrors),
    append(CurrentErrors, RestErrors, Errors).

%% A relationship between a range and its errors

validateRange(dayRange(Start, End), Line, Settings, HasSingleDaySetting, HasSingleSlotSetting, Errors) :-
    validateDaySlot(Start, Line, Settings, HasSingleDaySetting, HasSingleSlotSetting, StartErrors),
    validateDaySlot(End, Line, Settings, HasSingleDaySetting, HasSingleSlotSetting, EndErrors),
    validateRangeOrder(dayRange(Start, End), Line, OrderErrors),
    append(StartErrors, EndErrors, EndpointErrors),
    append(EndpointErrors, OrderErrors, Errors).

%% A relationship between a range and its order

validateRangeOrder(dayRange(daySlot(StartDay, _), daySlot(EndDay, _)), Line, [Message]) :-
    StartDay \= EndDay,
    !,
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Availability range must stay in one day", Message).

validateRangeOrder(dayRange(daySlot(Day, StartSlot), daySlot(Day, EndSlot)), Line, [Message]) :-
    StartSlot > EndSlot,
    !,
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Availability range starts after it ends", Message).

validateRangeOrder(dayRange(daySlot(Day, StartSlot), daySlot(Day, EndSlot)), _, []) :-
    StartSlot =< EndSlot.

%% A relationship between a session duration and the daily slot count

validateDuration(_, _, _, false, []) :-
    !.

validateDuration(Duration, _, Settings, true, []) :-
    member(record(_, ["franjas", DailySlotCount]), Settings),
    Duration =< DailySlotCount,
    !.

validateDuration(_, Line, _, true, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": Group duration exceeds the daily limit", Message).

%% A relationship between a group and its teacher

validateGroupHasTeacher(groupKey(Course, Group), _, Teaching, []) :-
    member(record(_, [Course, Group, _]), Teaching),
    !.

validateGroupHasTeacher(groupKey(Course, Group), Line, _, [Message]) :-
    number_codes(Line, LineDigits),
    append("Line ", LineDigits, Message1),
    append(Message1, ": No teacher for group ", Message2),
    append(Message2, Course, Message3),
    append(Message3, "/", Message4),
    append(Message4, Group, Message).
