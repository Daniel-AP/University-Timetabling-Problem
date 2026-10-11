%% A relationship between instance rooms and their equivalent groups

equivalentRoomGroups(Groups) :-
    findall(room(Room, Capacity, Type), (room(Room, Capacity, Type), \+ fixedRoom(_, _, Room)), Rooms),
    buildRoomGroups(Rooms, Groups).

%% A relationship between rooms and groups with the same capacity and type

buildRoomGroups([], []).

buildRoomGroups([room(Room, Capacity, Type)|Rooms], [[Room, Match|Matches]|Groups]) :-
    splitEquivalentRooms(room(Room, Capacity, Type), Rooms, [Match|Matches], Remaining),
    buildRoomGroups(Remaining, Groups).

buildRoomGroups([Reference|Rooms], Groups) :-
    splitEquivalentRooms(Reference, Rooms, [], Remaining),
    buildRoomGroups(Remaining, Groups).

%% A relationship between a room, matching rooms and the remaining rooms

splitEquivalentRooms(_, [], [], []).

splitEquivalentRooms(room(_, Capacity, Type), [room(Room, Capacity, Type)|Rooms], [Room|Matches], Remaining) :-
    splitEquivalentRooms(room(Room, Capacity, Type), Rooms, Matches, Remaining).

splitEquivalentRooms(room(_, Capacity, Type), [room(Room, OtherCapacity, OtherType)|Rooms], Matches, [room(Room, OtherCapacity, OtherType)|Remaining]) :-
    [Capacity, Type] \= [OtherCapacity, OtherType],
    splitEquivalentRooms(room(_, Capacity, Type), Rooms, Matches, Remaining).
