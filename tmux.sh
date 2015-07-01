#!/bin/bash
CURRENT_SESSION=${PWD##*/}
tmux new-session -d -s $CURRENT_SESSION
tmux send-keys 'vim' 'C-m'
tmux rename-window vim
tmux new-window
tmux rename-window server
tmux select-window -t 0
tmux attach -t $CURRENT_SESSION
