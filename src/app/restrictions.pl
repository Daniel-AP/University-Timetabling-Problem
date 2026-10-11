%% A relationship between a group and a location allowed by its rules

allowedSlot(Course, Group, slot(Room, Day, Start)) :-
    group(Course, Group, _, _, _, Duration, _),
    \+ (fixedRoom(Course, Group, FixedRoom), FixedRoom \= Room),
    End is Start+Duration,
    \+ (
        forbiddenSlot(Course, Group, Day, Forbidden),
        Forbidden >= Start,
        Forbidden < End
    ).
