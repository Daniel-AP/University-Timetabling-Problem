:- dynamic(instanceSetting/2).
:- dynamic(room/3).
:- dynamic(teacher/4).
:- dynamic(group/7).
:- dynamic(teaches/3).
:- dynamic(fixedRoom/3).
:- dynamic(forbiddenSlot/4).
:- dynamic(exclusiveGroups/4).
:- dynamic(preferredSlot/5).
:- dynamic(compactGroup/3).

%% A relationship between a validated instance and its registered facts

registerInstance(instance(Settings, Rooms, Teachers, Groups, Teaching, Restrictions)) :-
    clearInstance,
    registerRecords(config, Settings),
    registerRecords(rooms, Rooms),
    registerRecords(teachers, Teachers),
    registerRecords(groups, Groups),
    registerRecords(teaching, Teaching),
    registerRecords(restrictions, Restrictions).

%% Remove the facts of the current instance

clearInstance :-
    retractall(instanceSetting(_, _)),
    retractall(room(_, _, _)),
    retractall(teacher(_, _, _, _)),
    retractall(group(_, _, _, _, _, _, _)),
    retractall(teaches(_, _, _)),
    retractall(fixedRoom(_, _, _)),
    retractall(forbiddenSlot(_, _, _, _)),
    retractall(exclusiveGroups(_, _, _, _)),
    retractall(preferredSlot(_, _, _, _, _)),
    retractall(compactGroup(_, _, _)).

%% A relationship between section records and their registered facts

registerRecords(_, []).

registerRecords(Section, [Record|Records]) :-
    registerRecord(Section, Record),
    registerRecords(Section, Records).

%% A relationship between a record and its registered fact

registerRecord(config, record(_, [Key, Value])) :-
    assertz(instanceSetting(Key, Value)).

registerRecord(rooms, record(_, [Code, Capacity, Type])) :-
    assertz(room(Code, Capacity, Type)).

registerRecord(teachers, record(_, [Code, Name, MaxSlots, Availability])) :-
    assertz(teacher(Code, Name, MaxSlots, Availability)).

registerRecord(groups, record(_, [Course, Name, Group, Enrolled, WeeklySessions, Duration, Requirement])) :-
    assertz(group(Course, Group, Name, Enrolled, WeeklySessions, Duration, Requirement)).

registerRecord(teaching, record(_, [Course, Group, Teacher])) :-
    assertz(teaches(Course, Group, Teacher)).

registerRecord(restrictions, record(_, ["aula_fija", Course, Group, Room])) :-
    assertz(fixedRoom(Course, Group, Room)).

registerRecord(restrictions, record(_, ["prohibida", Course, Group, daySlot(Day, Slot)])) :-
    assertz(forbiddenSlot(Course, Group, Day, Slot)).

registerRecord(restrictions, record(_, ["excluyentes", Course, Group, OtherCourse, OtherGroup])) :-
    assertz(exclusiveGroups(Course, Group, OtherCourse, OtherGroup)).

registerRecord(restrictions, record(_, ["prefiere", Course, Group, daySlot(Day, Slot), Weight])) :-
    assertz(preferredSlot(Course, Group, Day, Slot, Weight)).

registerRecord(restrictions, record(_, ["compacta", Course, Group, Weight])) :-
    assertz(compactGroup(Course, Group, Weight)).
