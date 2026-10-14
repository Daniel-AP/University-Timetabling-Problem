%% A relationship between bytes, a separator and their parts

splitBytes([], _, [[]]).

splitBytes([Separator|Bytes], Separator, [[]|Parts]) :-
    !,
    splitBytes(Bytes, Separator, Parts).

splitBytes([Byte|Bytes], Separator, [[Byte|Part]|Parts]) :-
    splitBytes(Bytes, Separator, [Part|Parts]).

%% A relationship between fields and their text without outer spaces

trimFields([], []).

trimFields([Field|Fields], [TrimmedField|TrimmedFields]) :-
    trimField(Field, TrimmedField),
    trimFields(Fields, TrimmedFields).

%% A relationship between bytes and their content without outer spaces

trimField(Bytes, TrimmedBytes) :-
    removeLeadingSpaces(Bytes, WithoutLeadingSpaces),
    reverse(WithoutLeadingSpaces, ReversedBytes),
    removeLeadingSpaces(ReversedBytes, WithoutTrailingSpaces),
    reverse(WithoutTrailingSpaces, TrimmedBytes).

%% A relationship between bytes and their content without leading spaces

removeLeadingSpaces([32|Bytes], RemainingBytes) :-
    !,
    removeLeadingSpaces(Bytes, RemainingBytes).

removeLeadingSpaces(Bytes, Bytes).

%% A relationship between day text and its list of days

parseDays(Bytes, [Day]) :-
    takeCharacter(Bytes, Day, []),
    Day \= ",".

parseDays(Bytes, [Day|Days]) :-
    takeCharacter(Bytes, Day, [44, NextByte|RemainingBytes]),
    Day \= ",",
    parseDays([NextByte|RemainingBytes], Days).

%% A relationship between bytes and their first UTF-8 character

takeCharacter([Byte|Bytes], [Byte], Bytes) :-
    Byte >= 0,
    Byte =< 127.

takeCharacter([First, Second|Bytes], [First, Second], Bytes) :-
    First >= 194,
    First =< 223,
    Second >= 128,
    Second =< 191.

takeCharacter([224, Second, Third|Bytes], [224, Second, Third], Bytes) :-
    Second >= 160,
    Second =< 191,
    Third >= 128,
    Third =< 191.

takeCharacter([First, Second, Third|Bytes], [First, Second, Third], Bytes) :-
    First >= 225,
    First =< 239,
    First =\= 237,
    Second >= 128,
    Second =< 191,
    Third >= 128,
    Third =< 191.

takeCharacter([237, Second, Third|Bytes], [237, Second, Third], Bytes) :-
    Second >= 128,
    Second =< 159,
    Third >= 128,
    Third =< 191.

takeCharacter([240, Second, Third, Fourth|Bytes], [240, Second, Third, Fourth], Bytes) :-
    Second >= 144,
    Second =< 191,
    Third >= 128,
    Third =< 191,
    Fourth >= 128,
    Fourth =< 191.

takeCharacter([First, Second, Third, Fourth|Bytes], [First, Second, Third, Fourth], Bytes) :-
    First >= 241,
    First =< 243,
    Second >= 128,
    Second =< 191,
    Third >= 128,
    Third =< 191,
    Fourth >= 128,
    Fourth =< 191.

takeCharacter([244, Second, Third, Fourth|Bytes], [244, Second, Third, Fourth], Bytes) :-
    Second >= 128,
    Second =< 143,
    Third >= 128,
    Third =< 191,
    Fourth >= 128,
    Fourth =< 191.

%% A relationship between time text and its hour and minute

parseTime([HourTens, HourUnits, 58, MinuteTens, MinuteUnits], startTime(Hour, Minute)) :-
    parseNumber([HourTens, HourUnits], Hour),
    parseNumber([MinuteTens, MinuteUnits], Minute).

%% A relationship between bytes and a day with its slot number

parseDaySlot(Bytes, daySlot(Day, Slot)) :-
    takeCharacter(Bytes, Day, SlotBytes),
    parseNumber(SlotBytes, Slot).

%% A relationship between availability text and its time ranges

parseAvailability([], all) :-
    !.

parseAvailability(Bytes, Ranges) :-
    splitBytes(Bytes, 44, RangeFields),
    parseRanges(RangeFields, Ranges).

%% A relationship between range fields and their start and end

parseRanges([], []).

parseRanges([Field|Fields], [dayRange(Start, End)|Ranges]) :-
    splitBytes(Field, 45, [StartBytes, EndBytes]),
    parseDaySlot(StartBytes, Start),
    parseDaySlot(EndBytes, End),
    parseRanges(Fields, Ranges).
