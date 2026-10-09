%% A relationship between execution arguments and their configuration

parseArguments([Input, _, _|_], _) :-
    \+ atom(Input), !,
    throw(argumentError(Input, "Expected a nonempty input path")).

parseArguments(['', _, _|_], _) :-
    !,
    throw(argumentError('', "Expected a nonempty input path")).

parseArguments([_, Output, _|_], _) :-
    \+ atom(Output), !,
    throw(argumentError(Output, "Expected a nonempty output path")).

parseArguments([_, '', _|_], _) :-
    !,
    throw(argumentError('', "Expected a nonempty output path")).

parseArguments([_, _, Strategy|_], _) :-
    \+ atom(Strategy), !,
    throw(argumentError(Strategy, "Expected bt or clpfd")).

parseArguments([_, _, Strategy|_], _) :-
    \+ member(Strategy, [bt, clpfd]), !,
    throw(argumentError(Strategy, "Expected bt or clpfd")).

parseArguments([Input, Output, Strategy|Options], Config) :-
    !,
    InitialConfig = config(Input, Output, Strategy, original, false, none),
    parseOptions(Options, InitialConfig, Config).

parseArguments(Arguments, _) :-
    throw(argumentError(Arguments, "Expected input path, output path and strategy")).

%% A relationship between execution options and configuration fields

parseOptions([], Config, Config).

parseOptions(['--optimizar'|Options], _, _) :-
    member('--optimizar', Options), !,
    throw(argumentError('--optimizar', "Optimization was specified more than once")).

parseOptions(['--optimizar'|Options], config(Input, Output, Strategy, Heuristic, _, Limit), Config) :-
    !,
    NextConfig = config(Input, Output, Strategy, Heuristic, true, Limit),
    parseOptions(Options, NextConfig, Config).

parseOptions([Option|Options], _, _) :-
    atom(Option), atom_concat('--heuristica=', _, Option),
    member(Other, Options), atom(Other), atom_concat('--heuristica=', _, Other), !,
    throw(argumentError(Option, "A heuristic was specified more than once")).

parseOptions([Option|Options], config(Input, Output, Strategy, _, Optimize, Limit), Config) :-
    atom(Option), atom_concat('--heuristica=', Heuristic, Option),
    member(Heuristic, [original, mrv, degree, demand, lcv]), !,
    NextConfig = config(Input, Output, Strategy, Heuristic, Optimize, Limit),
    parseOptions(Options, NextConfig, Config).

parseOptions(['--heuristica=ff'|Options], config(Input, Output, clpfd, _, Optimize, Limit), Config) :-
    !,
    NextConfig = config(Input, Output, clpfd, ff, Optimize, Limit),
    parseOptions(Options, NextConfig, Config).

parseOptions([Option|_], _, _) :-
    atom(Option), atom_concat('--heuristica=', _, Option), !,
    throw(argumentError(Option, "Unknown heuristic or incompatible strategy")).

parseOptions([Option|Options], _, _) :-
    atom(Option), atom_concat('--limite=', _, Option),
    member(Other, Options), atom(Other), atom_concat('--limite=', _, Other), !,
    throw(argumentError(Option, "A limit was specified more than once")).

parseOptions([Option|Options], config(Input, Output, Strategy, Heuristic, Optimize, _), Config) :-
    atom(Option), atom_concat('--limite=', Text, Option), !,
    parseLimit(Text, Limit),
    NextConfig = config(Input, Output, Strategy, Heuristic, Optimize, Limit),
    parseOptions(Options, NextConfig, Config).

parseOptions([Option|_], _, _) :-
    throw(argumentError(Option, "Unknown execution option")).

%% A relationship between decimal text and a search limit

parseLimit(Text, Limit) :-
    atom(Text), atom_codes(Text, Codes), Codes = [_|_],
    parseLimitDigits(Codes, 0, Limit), !.

parseLimit(Text, _) :-
    throw(argumentError(Text, "Expected a nonnegative decimal integer")).

%% A relationship between decimal digits and their accumulated value

parseLimitDigits([], Limit, Limit).

parseLimitDigits([Code|Codes], Accum, Limit) :-
    Code > 47, Code < 58,
    Digit is Code-48,
    NextAccum is Accum*10+Digit,
    parseLimitDigits(Codes, NextAccum, Limit).
