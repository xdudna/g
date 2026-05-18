#!/bin/bash
version="0.3.4"

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

# Show environment variables
function showEnv() {
  for var in $(compgen -v G_); do
    echo "$var=${!var}"
  done
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

function showSimpleHelp() {
  echo "usage: g <command> [<args>]

run 'g help' for g's help.
"
}

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
    commit        m, cm:         commit
                  M, am:         commit --amend  (if you want to run 'git am', use 'git am')
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
  v=$(printf "%04d" $((RANDOM % 10000)))
  read -p  "To confirm, type [ $v ]: " input
  [[ $v != $input ]] && echo "cancelled..." && exit 1
  echo -e "${Cgreen}confirmed!${Creset}" && return 0
  return 1
}

# Core logic begins here
[ $# -eq 0 ] && showSimpleHelp && exit 0


## Command maps (data-driven)
# Commands that execute and exit immediately
declare -A EXIT_CMD_MAP=(
  [help]="showHelp" [--help]="showHelp"
  [version]="showVersion" [--version]="showVersion"
  [env]="showEnv"
)

# Normal commands -> git subcommands
declare -A CMD_MAP=(
  # add
  [a]="add"
  [aa]="add -A" [aA]="add -A"
  # blame
  [bl]="blame"
  # branch
  [b]="branch" [br]="branch"
  [be]="branch --edit-description"
  [bD]="branch -D"
  [bv]="branch -v"
  [bvv]="branch -vv"
  [ba]="branch --all"
  [B]="switch -c"
  [ps]="branch --show-current"
  # commit
  [cm]="commit $([ $G_VERBOSE_COMMIT = "true" ] && echo '--verbose')"
  [am]="commit --amend $([ $G_VERBOSE_COMMIT = "true" ] && echo '--verbose')"
  [m]="commit $([ $G_VERBOSE_COMMIT = "true" ] && echo '--verbose')"
  [M]="commit --amend $([ $G_VERBOSE_COMMIT = "true" ] && echo '--verbose')"
  # config
  [cfg]="config --list" [cfgl]="config --list"
  [cfge]="config --edit"
  # diff
  [d]="diff" [df]="diff"
  # fetch
  [f]="fetch" [fe]="fetch"
  # grep
  [g]="grep"
  # checkout
  [co]="checkout"
  # cherry-pick
  [cp]="cherry-pick" [pi]="cherry-pick"
  # reset
  [rs]="reset"
  # restore
  [x]="restore"
  [xx]="restore --staged"
  # merge
  [mr]="merge"
  # pull and push
  [p]="pull"
  [P]="push"
  [Pu]="push -u $G_UPSTREAM $(git branch --show-current 2> /dev/null)"
  [PU]="push -u $G_UPSTREAM $(git branch --show-current 2> /dev/null)"
  # rebase
  [rb]="rebase"
  [rbi]="rebase -i"
  # reflog
  [rl]="reflog -$G_LOG_SIZE"
  # remote
  [up]="remote"
  # status
  [s]="status -s" [st]="status -s"
  [S]="status"
  # stash
  [k]="stash"
  # tag
  [t]="tag"
  # switch
  [j]="switch"
  [J]="switch -" [jj]="switch -"
  # show
  [sh]="show" [so]="show"
  # log
  [l]='log --color --pretty="%C(green)%ad%C(yellow) %h %C(blue)%<(10,trunc)%an %Creset%s %C(red) %d" --date=format:"%y-%m-%d %H:%M" -$G_LOG_SIZE'
  [l1]="log --oneline -$G_LOG_SIZE"
  [l2]="log --graph --oneline --decorate -$G_LOG_SIZE"
  # help and version (git subcommands)
  [hp]="help"
  [ver]="version"
)

# Dangerous commands
declare -A DANGEROUS_CMD_MAP=(
  [CO]="checkout -- ."
  [RR]="reset --hard $G_UPSTREAM/$(git branch --show-current 2> /dev/null)"
  [PD]="push $G_UPSTREAM --delete"
  [PP]="push --force"
)

# convert converts the command to git command.
# if mismatch, it will return input.
function convert() {
  local cmd="$1"

  # Exit commands (help, version, env)
  if [[ -n "${EXIT_CMD_MAP[$cmd]+x}" ]]; then
    ${EXIT_CMD_MAP[$cmd]}
    exit 0
  fi

  # Normal commands
  if [[ -n "${CMD_MAP[$cmd]+x}" ]]; then
    top="${CMD_MAP[$cmd]}"
    return
  fi

  # Dangerous commands
  if [[ -n "${DANGEROUS_CMD_MAP[$cmd]+x}" ]]; then
    dangerous=1
    top="${DANGEROUS_CMD_MAP[$cmd]}"
    return
  fi

  # Quick branch (1-9)
  if [[ "$cmd" =~ ^[1-9]$ ]]; then
    local var="G_QUICK_BRANCH_$cmd"
    if [ -z "${!var}" ]; then
      echo "quick branch $cmd is not set."
      exit 1
    fi
    top="switch ${!var}"
    return
  fi

  # Mismatch: pass through to git
  top="$cmd"
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
[ "$G_PRINT_REAL_CMD" = true ] && echo -e "${Cgray}[g]\033[3m$realcmd\033[23m $Creset" >&2

# Dangerous operation check
[ $dangerous -eq 1 ] && echo -e "${Cyellow}hint: You are about to run '$realcmd'${Creset}" && ! dangerCheck && exit 1

eval "$realcmd"
