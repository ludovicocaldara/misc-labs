# I use TITLE to show the end-time of the session in the Presenter window
TITLE="00:00"
SESSION="dgconfig"
# The window names '-' 'DEMO' and 'Presenter' are used to minimize/maximize with the MaximizeDEMO MinimizeDEMO shortcuts
echo -en "\033]0;-\a"
# following is needed if tmux installed in /usr/local by compiling the source
# -A means attached if the session already exists.
alias demo='if tmux list-session ; then echo -en "\033]0;Presenter $TITLE\a"; else echo -en "\033]0;DEMO Screen\a"; fi; tmux new-session -A -s $SESSION'
shopt -s histappend
history -a
HISTCONTROL=ignoreboth
