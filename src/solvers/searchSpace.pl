%% A relationship between instance facts and an estimate of the search size

searchSpaceSize(Size) :-
    findall(Code, room(Code, _, _), Rooms),
    length(Rooms, RoomCount),
    instanceSetting("dias", Days),
    length(Days, DayCount),
    instanceSetting("franjas", DailySlotCount),
    findall([WeeklySessions, Duration], group(_, _, _, _, WeeklySessions, Duration, _), Groups),
    searchSpaceProduct(Groups, RoomCount, DayCount, DailySlotCount, Size).

%% A relationship between group requirements and the number of possible schedules

searchSpaceProduct([], _, _, _, 1.0).

searchSpaceProduct([[0, _]|Groups], RoomCount, DayCount, DailySlotCount, Size) :-
    searchSpaceProduct(Groups, RoomCount, DayCount, DailySlotCount, Size).

searchSpaceProduct([[WeeklySessions, Duration]|Groups], RoomCount, DayCount, DailySlotCount, Size) :-
    WeeklySessions > 0,
    StartOffset is DailySlotCount-Duration,
    Choices is 1.0*RoomCount*DayCount*(StartOffset+1.0),
    GroupSize is Choices**WeeklySessions,
    searchSpaceProduct(Groups, RoomCount, DayCount, DailySlotCount, RestSize),
    Size is GroupSize*RestSize.
