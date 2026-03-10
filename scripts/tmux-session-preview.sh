#!/usr/bin/env bash
tmux capture-pane -p -e -S -1000 -t "$1" | tail -50
