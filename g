#!/bin/bash
version="0.3.0"

## What is g?
# g is a magic tool that can help you quickly execute git commands.
# For example, you can use 'g p' to represent 'git pull', and 'g s' to represent 'git status -s'...
#
# Not only that, you can also use g to execute other usual git commands which is a little bit long.
# 'g Pu' (real command: git push -u <origin> <branch>) to push your new branch to remote.
#
# What's more?
# You can use '+' to combine multiple commands.
# Like, use 'g j dev + p ' to run 'git switch dev && git pull'


## Environment Variables
[ -z "$G_LOG_SIZE" ] && G_LOG_SIZE=20                     # default log size of 'git log' and 'git reflog'
[ -z "$G_UPSTREAM" ] && G_UPSTREAM="origin"               # default upstream of 'git pull' and 'git push'
[ -z "$G_PRINT_REAL_CMD" ] && G_PRINT_REAL_CMD=false      # print real git command to console
[ -z "$G_VERBOSE_COMMIT" ] && G_VERBOSE_COMMIT=false      # add --verbose to commit command
[ -z "$G_QUICK_BRANCH_1" ] && G_QUICK_BRANCH_1="main"   # quick branch 1
[ -z "$G_QUICK_BRANCH_2" ] && G_QUICK_BRANCH_2="dev"    # quick branch 2
[ -z "$G_QUICK_BRANCH_3" ] && G_QUICK_BRANCH_3="fat"    # quick branch 3
# note: DON'T FORGET TO REWRITE THE 'showEnv' function if add new environment variables here.

# Show environment variables
function showEnv() {
  echo "G_LOG_SIZE=$G_LOG_SIZE"
  echo "G_PRINT_REAL_CMD=$G_PRINT_REAL_CMD"
  echo "G_UPSTREAM=$G_UPSTREAM"
  echo "G_VERBOSE_COMMIT=$G_VERBOSE_COMMIT"
  echo "G_QUICK_BRANCH_1=$G_QUICK_BRANCH_1"
  echo "G_QUICK_BRANCH_2=$G_QUICK_BRANCH_2"
  echo "G_QUICK_BRANCH_3=$G_QUICK_BRANCH_3"
}

# colors
Cred='\033[0;31m'
Cgreen='\033[0;32m'
Cyellow='\033[0;33m'
Cblue='\033[0;34m'
Cgray='\033[2;37m'
Creset='\033[0m'

# flag of dangerous command.
# 1: dangerous command
# 0: normal command
# if dangerous is 1, it will prompt for confirmation.
dangerous=0 

# top is the short version of temporary operator.
# it is used to store the converted command.
top=""

function showVersion() {
  echo "g version $version
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
                  ba:         branch --all
                  be:         branch --edit-description
                  bD:         branch -D
                  bv[v]:      branch -v[v]
                  B:          switch -c  (create a new branch and switch to it)
                  ps:         branch --show-current
    checkout      co:         checkout
    cherry-pick   cp, pi:     cherry-pick
    commit        cm:         commit
                  am:         commit --amend  (if you want to run 'git am', use 'git am')
                  (set G_VERBOSE_COMMIT, --verbose will be added)
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
    restore       x:          restore
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
    PD      Delete the branch in upsteam. (git push <upstream> --delete <branch_name>)
    
More commands:
    g version: Display version information about g.
      (if you want to view git's version, use 'g ver')
    g help: Display help information about g.
      (if you want to view git's help information, use 'g hp')
    g env: View the environment variables of g.
  
Quick branch:
    g <N>: to switch the branch defined in $G_QUICK_BRANCH_<N>.
           <N> could be 1~9.

You can use '+' to combine multiple commands.
For example: 'g j dev + s' is equivalent to 'git switch dev && git status'
"
}

# Dangerous operation check
function dangerCheck() {
  #v=$(expr $RANDOM % 10)$(expr $RANDOM % 10)$(expr $RANDOM % 10)$(expr $RANDOM % 10)
  v=$(printf "%04d" $((RANDOM % 10000)))
  read -p  "To confirm, type [ $v ]: " input
  [[ $v != $input ]] && echo "cancelled..." && exit 1
  echo -e "${Cgreen}confirmed!${Creset}" && return 0
  return 1
}

# Core logic begins here
[ $# -eq 0 ] && showHelp && exit 0


# convert converts the command to git command.
# if mismatch, it will return input.
function convert() {
  case $1 in
    ## reserved commands
    help | '--help' ) showHelp && exit 0 ;;
    version | '--version' ) showVersion && exit 0;;
    env )  showEnv && exit 0 ;;

    ## git commands
    # add
    a  )  top="add" ;;
    aa | aA ) top="add -A" ;;
    # blame
    bl ) top="blame" ;;
    # branch
    b | br )  top="branch" ;;
    be )  top="branch --edit-description" ;;
    bD )  top="branch -D" ;;
    bv )  top="branch -v" ;;
    bvv ) top="branch -vv" ;;
    ba )  top="branch --all" ;;
    B )   top="switch -c" ;;
    ps )  top="branch --show-current 2> /dev/null" ;;
    # commit
    cm )  top="commit $([ $G_VERBOSE_COMMIT = "true" ] && echo '--verbose')" ;;
    am )  top="commit --amend $([ $G_VERBOSE_COMMIT = "true" ] && echo '--verbose')" ;;
    # config
    cfg | cfgl )  top="config --list" ;;
    cfge )  top="config --edit" ;;
    # diff
    d | df ) top="diff" ;;
    # fetch
    f | fe) top="fetch" ;;
    # grep
    g ) top="grep" ;;
    # checkout 
    co ) top="checkout" ;;
    CO ) dangerous=1 && top="checkout -- ." ;;
    # cherry-pick
    cp | pi ) top="cherry-pick" ;;
    # reset 
    rs ) top="reset";;
    RR ) dangerous=1 && top="reset --hard $G_UPSTREAM/$(git branch --show-current)" ;;
    # restore
    x )  top="restore" ;;
    xx ) top="restore --staged" ;;
    # merge
    mr ) top="merge" ;;
    # pull and push
    p  )  top="pull" ;;
    P  )  top="push" ;;
    Pu | PU )  top="push -u $G_UPSTREAM $(git branch --show-current)" ;;
    PD )  dangerous=1 && top="push $G_UPSTREAM --delete" ;;
    PP )  dangerous=1 && top="push --force";;
    # rebase
    rb  )  top="rebase" ;;
    rbi )  top="rebase -i" ;;
    # reflog
    rl ) top="reflog -$G_LOG_SIZE" ;;
    # remote
    up ) top="remote" ;;
    # status
    s | st )  top="status -s" ;;
    S )  top="status" ;;
    # stash
    k )  top="stash" ;;
    # tag
    t )  top="tag" ;;
    # switch
    j )  top="switch" ;;
    J | jj )  top="switch -" ;;
    # show
    sh | so ) top="show" ;;
    # log
    l )  top='''log --color --pretty="%C(green)%ad%C(yellow) %h %C(blue)%<(10,trunc)%an %Creset%s %C(red) %d" --date=format:"%y-%m-%d %H:%M" -$G_LOG_SIZE''';;
    l1 )  top='''log --oneline -$G_LOG_SIZE''' ;;
    l2 )  top='''log --graph --oneline --decorate -$G_LOG_SIZE''' ;;

    # help and version
    hp )  top="help" ;;
    ver ) top="version" ;;

    # quick branch
    1 ) [ -z "$G_QUICK_BRANCH_1" ] && echo "quick branch 1 is not set." && exit 1
        top="switch $G_QUICK_BRANCH_1" ;;
    2 ) [ -z "$G_QUICK_BRANCH_2" ] && echo "quick branch 2 is not set." && exit 1
        top="switch $G_QUICK_BRANCH_2" ;;
    3 ) [ -z "$G_QUICK_BRANCH_3" ] && echo "quick branch 3 is not set." && exit 1
        top="switch $G_QUICK_BRANCH_3" ;;
    
    # mismatch
    * ) top="$1" ;;
  esac
}

first=true
operators=(git)
while [ $# -gt 0 ]; do
  if [ "$1" = "+" ]; then
    operators+=("&&" "git")
    first=true
  else
    if [ $first = "true" ]; then
      convert "$1"
      operators+=($top)  # no quote, because we can guarantee that $top won't lead an error.
                         # by the way, the command will look better.
      first=false
    else
      operators+=("$1")
    fi
  fi
  shift
done

# concatenate operators to form a real command.
for o in "${operators[@]}"; do
  curarg="$o"
  [[ $curarg == *" "* ]] && curarg="\"$curarg\""
  realcmd="$realcmd $curarg"
done
[ "$G_PRINT_REAL_CMD" = true ] && echo -e "${Cgray}[g] \033[3m$realcmd\033[23m $Creset"

# Dangerous operation check
[ $dangerous -eq 1 ] && echo -e "${Cyellow}hint: You are about to run '$realcmd'${Creset}" && ! dangerCheck && exit 1

eval "$realcmd"