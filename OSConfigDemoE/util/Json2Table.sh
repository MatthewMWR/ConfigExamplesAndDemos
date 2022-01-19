#!/bin/bash

DISPLAY_MAXCOLUMNWIDTH=$1

cat - \
| in2csv -f json -u 1 \
| csvlook --max-column-width "$DISPLAY_MAXCOLUMNWIDTH"