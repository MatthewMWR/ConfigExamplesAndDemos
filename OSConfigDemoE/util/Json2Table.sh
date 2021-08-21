#!/bin/bash

DISPLAY_COLUMNS=$1

DISPLAY_MAXCOLUMNWIDTH=$2

cat - \
| in2csv -f json \
| csvcut -c "$DISPLAY_COLUMNS" \
| csvlook --max-column-width "$DISPLAY_MAXCOLUMNWIDTH"