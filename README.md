# University Timetabling Problem

University scheduling in GNU Prolog 1.4.5 on Linux.

## Source organization

| Directory | Responsibility |
| --- | --- |
| `src/app` | Execution arguments and application coordination |
| `src/instance` | Reading, parsing, validation, fact registration, search space and session count |
| `src/common` | Shared preparation, assignment conversion, restrictions, verification, costs, heuristics and measurements |
| `src/solvers/backtracking` | Backtracking selection, location ordering, cost bounds, symmetry checks and search |

`src/solvers/fd` is reserved for the finite domain solver and will be created when its implementation begins.

## Naming and structure

Shared predicates use descriptive names without a solver prefix. Backtracking predicates use `bt`; its entry point remains `searchBacktracking/5`. Finite domain predicates will use `fd`. File names describe their responsibility, such as `sessionSelection.pl`, `slotOrder.pl` and `costBound.pl`.

`session/3`, `slot/3`, `domain/2`, `tentativeAssignment/2`, `btState/2` and `assignment/7` retain their existing representations. A schedule contains one assignment per physical session and all distinct teachers of its group.

`Teacher` and `Teachers` identify instructors. `DailySlotCount` is a daily time slot count; `Slots` is a list of complete room/day/start locations. `LastSlot` denotes an inclusive endpoint and `EndExclusive` denotes an exclusive endpoint.

Predicates and compound terms use camelCase, variables use PascalCase, and bodies use four spaces. Predicate arguments stay on one line. Each body goal uses its own line, including comparisons and cuts. Each predicate has a brief `%% A relationship between ... and ...` comment before its clauses.

The application entry point and output components remain pending. Existing components can be consulted together in GNU Prolog; both argument and instance parsing reuse `src/common/numberParsing.pl`.
