%% A relationship between a branch and its room appearance order

checkRoomAppearanceOrder(RoomGroups, OriginalSessions, State) :-
    sessionRooms(OriginalSessions, State, Rooms),
    checkRoomAppearances(RoomGroups, Rooms).

%% A relationship between sessions and their rooms in the original order

sessionRooms([], _, []).

sessionRooms([Session|Sessions], btState(PendingSessions, AssignedSessions), [pending|Rooms]) :-
    member(Session, PendingSessions),
    sessionRooms(Sessions, btState(PendingSessions, AssignedSessions), Rooms).

sessionRooms([Session|Sessions], btState(PendingSessions, AssignedSessions), [room(Room)|Rooms]) :-
    member(tentativeAssignment(Session, slot(Room, _, _)), AssignedSessions),
    sessionRooms(Sessions, btState(PendingSessions, AssignedSessions), Rooms).

%% A relationship between room groups and their first appearances in order

checkRoomAppearances(_, []).

checkRoomAppearances(RoomGroups, [pending|Rooms]) :-
    checkRoomAppearances(RoomGroups, Rooms), !.

checkRoomAppearances(RoomGroups, [pending|Rooms]) :-
    append(Before, [[_|RemainingRooms]|After], RoomGroups),
    append(Before, [RemainingRooms|After], RemainingGroups),
    checkRoomAppearances(RemainingGroups, Rooms), !.

checkRoomAppearances(RoomGroups, [room(Room)|Rooms]) :-
    \+ (member(Group, RoomGroups), member(Room, Group)),
    checkRoomAppearances(RoomGroups, Rooms).

checkRoomAppearances(RoomGroups, [room(Room)|Rooms]) :-
    append(Before, [[Room|RemainingRooms]|After], RoomGroups),
    append(Before, [RemainingRooms|After], RemainingGroups),
    checkRoomAppearances(RemainingGroups, Rooms).
