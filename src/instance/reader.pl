%% A relationship between a file and its bytes

readInstance(Path, _) :-
    catch(file_property(Path, type(directory)), Cause, throw(instanceReadError(Path, Cause))), !,
    throw(instanceReadError(Path, "Expected a file instead of a directory")).

readInstance(Path, Bytes) :-
    catch(open(Path, read, Stream, [type(binary)]), Cause, throw(instanceReadError(Path, Cause))),
    catch(
        (get_byte(Stream, Byte), readBytes(Stream, Byte, FileBytes), close(Stream)),
        Cause,
        (close(Stream, [force(true)]), throw(instanceReadError(Path, Cause)))
    ),
    Bytes = FileBytes.

%% A relationship between a stream, its current byte and the remaining bytes

readBytes(_, -1, []) :- !.

readBytes(Stream, Byte, [Byte|Bytes]) :-
    get_byte(Stream, NextByte),
    readBytes(Stream, NextByte, Bytes).
