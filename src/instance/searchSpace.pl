%% A relationship between instance facts and their approximate search space size

searchSpaceSize(Size) :-
    findall(Code, room(Code, _, _), Rooms),
    length(Rooms, RoomCount),
    instanceSetting("dias", Days),
    length(Days, DayCount),
    instanceSetting("franjas", Slots),
    findall([WeeklySessions, Duration],
        group(_, _, _, _, WeeklySessions, Duration, _), Groups),
    searchSpaceProduct(Groups, RoomCount, DayCount, Slots, Size).

%% A relationship between group requirements and their product of choices

searchSpaceProduct([], _, _, _, 1.0).

searchSpaceProduct([[0, _]|Groups], RoomCount, DayCount, Slots, Size) :-
    searchSpaceProduct(Groups, RoomCount, DayCount, Slots, Size).

searchSpaceProduct([[WeeklySessions, Duration]|Groups], RoomCount, DayCount, Slots, Size) :-
    WeeklySessions > 0,
    RemainingSlots is Slots-Duration,
    Choices is 1.0*RoomCount*DayCount*(RemainingSlots+1.0),
    GroupSize is Choices**WeeklySessions,
    searchSpaceProduct(Groups, RoomCount, DayCount, Slots, RestSize),
    Size is GroupSize*RestSize.
