%% A relationship between prepared sessions and their room appearance order

fdConstrainRoomAppearanceOrder([], _, _).

fdConstrainRoomAppearanceOrder([RoomGroup|RoomGroups], Model, Maps) :-
    fdConstrainRoomGroupAppearances(RoomGroup, Model, Maps),
    fdConstrainRoomAppearanceOrder(RoomGroups, Model, Maps).

%% A relationship between a room group and its first appearances in order

fdConstrainRoomGroupAppearances([], _, _).

fdConstrainRoomGroupAppearances([_], _, _).

fdConstrainRoomGroupAppearances([PreviousRoom, NextRoom|RoomGroup], Model, Maps) :-
    Maps = indexMaps(Rooms, _),
    fdIndexValue(Rooms, PreviousRoomIndex, PreviousRoom),
    fdIndexValue(Rooms, NextRoomIndex, NextRoom),
    fdConstrainRoomPairAppearances(Model, PreviousRoomIndex, NextRoomIndex, 0),
    fdConstrainRoomGroupAppearances([NextRoom|RoomGroup], Model, Maps).

%% A relationship between consecutive room indices and their first appearances in order

fdConstrainRoomPairAppearances([], _, _, _).

fdConstrainRoomPairAppearances([fdSession(_, RoomIndex, _, _, _)|Model], PreviousRoomIndex, NextRoomIndex, HasPreviousRoomAppearance) :-
    (RoomIndex #\= NextRoomIndex) #\/
    HasPreviousRoomAppearance,
    HasPreviousRoomAppearanceForRest = (HasPreviousRoomAppearance #\/ (RoomIndex #= PreviousRoomIndex)),
    fdConstrainRoomPairAppearances(Model, PreviousRoomIndex, NextRoomIndex, HasPreviousRoomAppearanceForRest).
