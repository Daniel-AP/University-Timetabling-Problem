%% Find groups of equivalent rooms that are not fixed

equivalentRoomGroups(Groups) :-
    findall(room(Room, Capacity, Type), (room(Room, Capacity, Type), \+ fixedRoom(_, _, Room)), Rooms),
    buildRoomGroups(Rooms, Groups).

%% Build groups of at least two rooms with equal capacity and type

buildRoomGroups([], []).

buildRoomGroups([room(Room, Capacity, Type)|Rooms], [[Room, Match|Matches]|Groups]) :-
    splitEquivalentRooms(room(Room, Capacity, Type), Rooms, [Match|Matches], Remaining),
    buildRoomGroups(Remaining, Groups).

buildRoomGroups([Reference|Rooms], Groups) :-
    splitEquivalentRooms(Reference, Rooms, [], Remaining),
    buildRoomGroups(Remaining, Groups).

%% Split rooms by the reference capacity and type

splitEquivalentRooms(_, [], [], []).

splitEquivalentRooms(room(_, Capacity, Type), [room(Room, Capacity, Type)|Rooms], [Room|Matches], Remaining) :-
    splitEquivalentRooms(room(Room, Capacity, Type), Rooms, Matches, Remaining).

splitEquivalentRooms(room(_, Capacity, Type), [room(Room, OtherCapacity, OtherType)|Rooms], Matches, [room(Room, OtherCapacity, OtherType)|Remaining]) :-
    [Capacity, Type] \= [OtherCapacity, OtherType],
    splitEquivalentRooms(room(_, Capacity, Type), Rooms, Matches, Remaining).
