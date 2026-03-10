#!/usr/bin/env bash
tmux capture-pane -p -S -1000 -t "$1" | grep . | tail -20 | awk '{a[NR]=$0} END{for(i=NR;i>=1;i--) print a[i]}'
