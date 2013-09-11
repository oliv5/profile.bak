#!/bin/sh
. ssh_config.sh ""

SSH_ENV="${HOME}/.ssh/environment"

function start_agent {
  mkdir ${SSH_ENV%/*} >/dev/null 2>&1
  ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
  chmod 600 "${SSH_ENV}"
  . "${SSH_ENV}" > /dev/null
}

function start {
  # Source SSH settings, if applicable
  if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    #ps ${SSH_AGENT_PID} doesn't work under cywgin
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
      start_agent;
    }
  else
    start_agent;
  fi
}

function killall {
  for i in `ps | grep -i ssh-agent | cut -d ' ' -f 6`
  do
    echo Kill PID $i
    kill -9 $i
  done
}

# Main
case "$1" in

  "" | start )
    start;
    ssh-add ${2-"${SSHPACK_PKEY}"} ${3+-t $3}
  ;;
    
  add )
    ssh-add ${2-"${SSHPACK_PKEY}"} ${3+-t $3}
  ;;

  remove )
    ssh-add -d ${2-"${SSHPACK_PKEY}"}
  ;;

  clear )
    ssh-add -D
  ;;

  lock )
    ssh-add -x
  ;;
  
  unlock )
    ssh-add -X
  ;;
  
  stop )
    ssh-agent -k
  ;;
  
  kill )
    killall;
  ;;
  
  * )
    echo Unknown parameter "$1"
  ;;

esac
true
