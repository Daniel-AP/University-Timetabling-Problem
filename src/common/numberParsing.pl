%% A relationship between number text and its integer value

parseNumber([Byte|Bytes], Number) :-
    parseNumberDigits([Byte|Bytes], 0, Number).

%% A relationship between digits and the number they form

parseNumberDigits([], Number, Number).

parseNumberDigits([Byte|Bytes], Accumulator, Number) :-
    Byte >= 48,
    Byte =< 57,
    NextAccumulator is Accumulator*10+Byte-48,
    parseNumberDigits(Bytes, NextAccumulator, Number).
