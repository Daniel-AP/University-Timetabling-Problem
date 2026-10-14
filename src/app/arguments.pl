%% A relationship between arguments and execution settings

parseArguments([Input, _, _|_], _, _) :-
    \+ atom(Input),
    !,
    throw(argumentError(Input, "Invalid input path")).

parseArguments(['', _, _|_], _, _) :-
    !,
    throw(argumentError('', "Invalid input path")).

parseArguments([_, Output, _|_], _, _) :-
    \+ atom(Output),
    !,
    throw(argumentError(Output, "Invalid output path")).

parseArguments([_, '', _|_], _, _) :-
    !,
    throw(argumentError('', "Invalid output path")).

parseArguments([_, _, Strategy|_], _, _) :-
    \+ atom(Strategy),
    !,
    throw(argumentError(Strategy, "Use bt or clpfd")).

parseArguments([_, _, Strategy|_], _, _) :-
    \+ member(Strategy, [bt, clpfd]),
    !,
    throw(argumentError(Strategy, "Use bt or clpfd")).

parseArguments([Input, Output, Strategy|Options], Config, ExecutionOptions) :-
    !,
    InitialConfig = config(Input, Output, Strategy, original, false, none),
    InitialExecutionOptions = executionOptions(none, false),
    parseOptions(Options, InitialConfig, InitialExecutionOptions, Config, ExecutionOptions).

parseArguments(Arguments, _, _) :-
    throw(argumentError(Arguments, "Missing input, output or strategy")).

%% A relationship between options and execution settings

parseOptions([], Config, ExecutionOptions, Config, ExecutionOptions).

parseOptions(['--optimizar'|Options], _, _, _, _) :-
    member('--optimizar', Options),
    !,
    throw(argumentError('--optimizar', "Repeated option")).

parseOptions(['--optimizar'|Options], config(Input, Output, Strategy, Heuristic, _, Limit), ExecutionOptions, Config, FinalExecutionOptions) :-
    !,
    NextConfig = config(Input, Output, Strategy, Heuristic, true, Limit),
    parseOptions(Options, NextConfig, ExecutionOptions, Config, FinalExecutionOptions).

parseOptions([Option|Options], _, _, _, _) :-
    atom(Option),
    atom_concat('--heuristica=', _, Option),
    member(Other, Options),
    atom(Other),
    atom_concat('--heuristica=', _, Other),
    !,
    throw(argumentError(Option, "Repeated option")).

parseOptions([Option|Options], config(Input, Output, Strategy, _, IsOptimizationEnabled, Limit), ExecutionOptions, Config, FinalExecutionOptions) :-
    atom(Option),
    atom_concat('--heuristica=', Heuristic, Option),
    member(Heuristic, [original, mrv, degree, demand, lcv]),
    !,
    NextConfig = config(Input, Output, Strategy, Heuristic, IsOptimizationEnabled, Limit),
    parseOptions(Options, NextConfig, ExecutionOptions, Config, FinalExecutionOptions).

parseOptions(['--heuristica=ff'|Options], config(Input, Output, clpfd, _, IsOptimizationEnabled, Limit), ExecutionOptions, Config, FinalExecutionOptions) :-
    !,
    NextConfig = config(Input, Output, clpfd, ff, IsOptimizationEnabled, Limit),
    parseOptions(Options, NextConfig, ExecutionOptions, Config, FinalExecutionOptions).

parseOptions([Option|_], _, _, _, _) :-
    atom(Option),
    atom_concat('--heuristica=', _, Option),
    !,
    throw(argumentError(Option, "Invalid heuristic for this strategy")).

parseOptions([Option|Options], _, _, _, _) :-
    atom(Option),
    atom_concat('--limite=', _, Option),
    member(Other, Options),
    atom(Other),
    atom_concat('--limite=', _, Other),
    !,
    throw(argumentError(Option, "Repeated option")).

parseOptions([Option|Options], config(Input, Output, Strategy, Heuristic, IsOptimizationEnabled, _), ExecutionOptions, Config, FinalExecutionOptions) :-
    atom(Option),
    atom_concat('--limite=', Text, Option),
    !,
    parseLimit(Text, Limit),
    NextConfig = config(Input, Output, Strategy, Heuristic, IsOptimizationEnabled, Limit),
    parseOptions(Options, NextConfig, ExecutionOptions, Config, FinalExecutionOptions).

parseOptions(['--horarios-por-aula'|Options], _, _, _, _) :-
    member('--horarios-por-aula', Options),
    !,
    throw(argumentError('--horarios-por-aula', "Repeated option")).

parseOptions(['--horarios-por-aula'|Options], InitialConfig, executionOptions(PrologOutput, _), Config, ExecutionOptions) :-
    !,
    parseOptions(Options, InitialConfig, executionOptions(PrologOutput, true), Config, ExecutionOptions).

parseOptions([Option|Options], _, _, _, _) :-
    atom(Option),
    atom_concat('--exportar-prolog=', _, Option),
    member(Other, Options),
    atom(Other),
    atom_concat('--exportar-prolog=', _, Other),
    !,
    throw(argumentError(Option, "Repeated option")).

parseOptions(['--exportar-prolog='|_], _, _, _, _) :-
    !,
    throw(argumentError('--exportar-prolog=', "Invalid export path")).

parseOptions([Option|_], config(Input, Output, _, _, _, _), _, _, _) :-
    atom(Option),
    atom_concat('--exportar-prolog=', PrologPath, Option),
    member(PrologPath, [Input, Output]),
    !,
    throw(argumentError(Option, "Export path matches input or report")).

parseOptions([Option|Options], InitialConfig, executionOptions(_, IsRoomGridEnabled), Config, ExecutionOptions) :-
    atom(Option),
    atom_concat('--exportar-prolog=', PrologPath, Option),
    !,
    parseOptions(Options, InitialConfig, executionOptions(prologFile(PrologPath), IsRoomGridEnabled), Config, ExecutionOptions).

parseOptions([Option|_], _, _, _, _) :-
    throw(argumentError(Option, "Unknown option")).

%% A relationship between number text and a search limit

parseLimit(Text, Limit) :-
    atom(Text),
    atom_codes(Text, Bytes),
    parseNumber(Bytes, Limit),
    !.

parseLimit(Text, _) :-
    throw(argumentError(Text, "Invalid limit")).
