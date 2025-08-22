#!/bin/bash
## Environment Variables
[ -z "$G_LOG_SIZE" ] && G_LOG_SIZE=20                     # default log size of 'git log' and 'git reflog'
[ -z "$G_PRINT_REAL_CMD" ] && G_PRINT_REAL_CMD=false      # print real command
[ -z "$G_UPSTREAM" ] && G_UPSTREAM="origin"
# note: DON'T FORGET TO REWRITE THE 'showEnv' function if add new environment variables here.

# Show environment variables
function showEnv() {
  echo "G_LOG_SIZE=$G_LOG_SIZE"
  echo "G_PRINT_REAL_CMD=$G_PRINT_REAL_CMD"
  echo "G_UPSTREAM=$G_UPSTREAM"
}

# colors
Cred='\033[0;31m'
Cgreen='\033[0;32m'
Cyellow='\033[0;33m'
Cblue='\033[0;34m'
Cgray='\033[2;37m'
Creset='\033[0m'


args=($@)
op=${args[0]}

# flag of dangerous command.
# 1: dangerous command
# 0: normal command
# if dangerous is 1, it will prompt for confirmation.
dangerous=0 

function showVersion() {
  echo "g version 0.1.9
If you want to view git's version, run 'git version' or 'g ver'."
}

function showHelp() {
  echo "g is a small tool used to quickly execute git commands.

Usage: g <command>

If the command is in the following list, it will be executed directly. 
Otherwise, it will be passed to git as 'git <command>'.

Normal commands:
    add           a:          add
                  aa, aA:     add -A
    blame         bl:         blame
    branch        b, br:      branch
                  ba          branch --all
                  B:          branch -m  (create a new branch and switch to it)
                  ps:         branch --show-current
    checkout      co:         checkout
    cherry-pick   cp, pi:     cherry-pick
    commit        cm:         commit
                  am:         commit --amend  (if you want to run 'git am', use 'git am')
    config        cfg, cfgl:  config --list
                  cfge:       config --edit
    diff          d, df:      diff
    fetch         f, fe:      fetch
    grep          g:          grep
    help          hp:         help
    log           l, l1, l2:  (special format log)
    merge         mr:         merge
    pull          p:          pull
    push          P:          push
                  Pu, PU:     push -u <upstream> <branch_name>
    rebase        rb:         rebase
                  rbi:        rebase -i
    reflog        rl:         reflog
    remote        up:         remote (up: upstream)
    reset         rs:         reset
    show          sh, so:     show
    stash         k:          stash (k: keep or stack)
    status        s, st:      status --short
                  S:          status 
    tag           t:          tag
    switch        j:          switch (j: jump)
                  J, jj:      switch - (jump back to last branch)
    version       ver:        version

Dangerous commands:
    CO      Reset all the changes in local repository. (git checkout -- .)
    PP      Force push to remote repository (git push --force)
    RR      Restore local to remote branch. (git reset --hard <upstream> <branch_name>)

More commands:
    g version: Display version information about g.
      (if you want to view git's version, use 'g ver')
    g help:    Display help information about g.
      (if you want to view git's help information, use 'g hp')
    g env: View the environment variables of g.
"
}

# Dangerous operation check
function dangerCheck() {
  v=$(expr $RANDOM % 10)$(expr $RANDOM % 10)$(expr $RANDOM % 10)$(expr $RANDOM % 10)
  read -p  "To confirm, type [ $v ]: " input
  [[ $v != $input ]] && echo "cancelled..." && exit 1
  echo -e "${Cgreen}confirmed!${Creset}" && return 0
  return 1
}

# Core logic begins here
[ $# -eq 0 ] && showHelp && exit 0
case $op in
  ## reserved commands
  help | '--help' ) showHelp && exit 0 ;;
  version | '--version' ) showVersion && exit 0;;
  env )  showEnv && exit 0 ;;

  ## git commands
  # add
  a  )  op="add" ;;
  aa | aA ) op="add -A" ;;
  # blame
  bl ) op="blame" ;;
  # branch
  b | br )  op="branch" ;;
  ba ) op="branch --all" ;;
  B ) op="branch -m" ;;
  ps ) op="branch --show-current 2> /dev/null" ;;
  # commit
  cm )  op="commit" ;;
  am )  op="commit --amend" ;;
  # config
  cfg | cfgl )  op="config --list" ;;
  cfge )  op="config --edit" ;;
  # diff
  d | df ) op="diff" ;;
  # fetch
  f | fe) op="fetch" ;;
  # grep
  g ) op="grep" ;;
  # checkout 
  co ) op="checkout" ;;
  CO ) dangerous=1 && op="checkout -- ." ;;
  # cherry-pick
  cp | pi ) op="cherry-pick" ;;
  # reset 
  rs ) op="reset";;
  RR ) dangerous=1 && op="reset --hard $G_UPSTREAM/$(git branch --show-current)" ;;
  # merge
  mr ) op="merge" ;;
  # pull and push
  p  )  op="pull" ;;
  P  )  op="push" ;;
  Pu | PU )  op="push -u $G_UPSTREAM $(git branch --show-current)" ;;
  PP )  dangerous=1 && op="push --force";;
  # rebase
  rb  )  op="rebase" ;;
  rbi )  op="rebase -i" ;;
  # reflog
  rl ) op="reflog -$G_LOG_SIZE" ;;
  # remote
  up ) op="remote" ;;
  # status
  s | st )  op="status -s" ;;
  S )  op="status" ;;
  # stash
  k )  op="stach" ;;
  # tag
  t )  op="tag" ;;
  # switch
  j )  op="switch" ;;
  J | jj )  op="switch -" ;;
  # show
  sh | so ) op="show" ;;
  # log
  l )  op='''log --color --pretty="%C(green)%ad%C(yellow) %h %C(blue)%<(10,trunc)%an %Creset%s %C(red) %d" --date=format:"%y-%m-%d %H:%M" -$G_LOG_SIZE''';;
  l1 )  op='''log --oneline -$G_LOG_SIZE''' ;;
  l2 )  op='''log --graph --oneline --decorate -$G_LOG_SIZE''' ;;
  
  # help and version
  hp )  op="help" ;;
  ver ) op="version" ;;
esac

args[0]=$op
realop="git ${args[@]}"
[ "$G_PRINT_REAL_CMD" = true ] && echo -e "${Cgray}[g] $realop $Creset"

# Dangerous operation check
if [ $dangerous -eq 1 ]; then
  echo -e "${Cyellow}hint: You are about to run 'git ${args[@]}'${Creset}"
  ! dangerCheck && exit 1
fi 
eval "$realop"
