%% A relationship between a group and a location allowed by its rules

allowedSlot(Course, Group, slot(Room, Day, Start)) :-
    group(Course, Group, _, _, _, Duration, _),
    \+ (
        fixedRoom(Course, Group, FixedRoom),
        FixedRoom \= Room
    ),
    EndExclusive is Start+Duration,
    \+ (
        forbiddenSlot(Course, Group, Day, ForbiddenSlot),
        ForbiddenSlot >= Start,
        ForbiddenSlot < EndExclusive
    ).
