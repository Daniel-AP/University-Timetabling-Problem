#!/bin/sh
exec gprolog --consult-file "$(dirname "$0")/horarios.pl" --entry-goal main -- "$@"
