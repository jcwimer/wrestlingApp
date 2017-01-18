#!/bin/bash
CURRENT_SESSION=wrestlingdev
tmux new-session -d -s $CURRENT_SESSION
tmux send-keys 'vim' 'C-m'
tmux send-keys ':NERDTree' 'C-m'
tmux rename-window rails-vim
tmux new-window
tmux rename-window rails
tmux send-keys 'bash rails-dev.sh wrestlingdev' 'C-m'
tmux new-window
tmux rename-window rails-git
tmux select-window -t 0
tmux attach -t $CURRENT_SESSION
