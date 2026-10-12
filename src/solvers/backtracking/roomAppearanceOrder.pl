%% A relationship between a branch and its room appearance order

btCheckRoomAppearanceOrder(RoomGroups, OriginalSessions, State) :-
    btSessionRooms(OriginalSessions, State, Rooms),
    btCheckRoomAppearances(RoomGroups, Rooms).

%% A relationship between sessions and their rooms in the original order

btSessionRooms([], _, []).

btSessionRooms([Session|Sessions], btState(PendingSessions, AssignedSessions), [pending|Rooms]) :-
    member(Session, PendingSessions),
    btSessionRooms(Sessions, btState(PendingSessions, AssignedSessions), Rooms).

btSessionRooms([Session|Sessions], btState(PendingSessions, AssignedSessions), [room(Room)|Rooms]) :-
    member(tentativeAssignment(Session, slot(Room, _, _)), AssignedSessions),
    btSessionRooms(Sessions, btState(PendingSessions, AssignedSessions), Rooms).

%% A relationship between room groups and their first appearances in order

btCheckRoomAppearances(_, []).

btCheckRoomAppearances(RoomGroups, [pending|Rooms]) :-
    btCheckRoomAppearances(RoomGroups, Rooms),
    !.

btCheckRoomAppearances(RoomGroups, [pending|Rooms]) :-
    append(Before, [[_|RemainingRooms]|After], RoomGroups),
    append(Before, [RemainingRooms|After], RemainingGroups),
    btCheckRoomAppearances(RemainingGroups, Rooms),
    !.

btCheckRoomAppearances(RoomGroups, [room(Room)|Rooms]) :-
    \+ (
        member(Group, RoomGroups),
        member(Room, Group)
    ),
    btCheckRoomAppearances(RoomGroups, Rooms).

btCheckRoomAppearances(RoomGroups, [room(Room)|Rooms]) :-
    append(Before, [[Room|RemainingRooms]|After], RoomGroups),
    append(Before, [RemainingRooms|After], RemainingGroups),
    btCheckRoomAppearances(RemainingGroups, Rooms).
