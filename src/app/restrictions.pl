%% A relationship between a group and a slot respecting its fixed room and forbidden times

allowedSlot(Course, Group, slot(Room, Day, Start)) :-
    group(Course, Group, _, _, _, Duration, _),
    \+ (fixedRoom(Course, Group, FixedRoom), FixedRoom \= Room),
    End is Start+Duration,
    \+ (
        forbiddenSlot(Course, Group, Day, Forbidden),
        Forbidden >= Start,
        Forbidden < End
    ).
