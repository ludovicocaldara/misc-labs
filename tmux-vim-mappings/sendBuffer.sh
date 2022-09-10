cat - > /tmp/tempbuffer.log
tmux load-buffer /tmp/tempbuffer.log 
tmux paste-buffer -d
