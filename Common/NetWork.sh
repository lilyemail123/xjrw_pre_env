#!/usr/bin/env bash

LOCALDIR=$(cd $(dirname $0) && pwd && cd - &> /dev/null)
BASEDIR=$(cd ${LOCALDIR}/.. && pwd && cd - &> /dev/null)
source ${BASEDIR}/Common/Log.sh

function run_command_remote(){
    # route_run_command 192.168.0.110 root 123456 'ls filename'
    remoute_ip=$1
    shift
    remoute_usr=$1
    shift
    remoute_pwd=$1
    shift
    remoute_cmd=$@
    log_info "run command on : ${remoute_ip} -> \"${remoute_cmd}\""
    expect <<EOF
    set timeout 180
    spawn ssh ${remoute_usr}@${remoute_ip} "${remoute_cmd}"
    expect {
    "*yes*" {send "yes\r";exp_continue}
    "*password*" {send "${remoute_pwd}\r";exp_continue}
    }
    catch wait result
    exit [lindex \$result 3]
EOF
    return $?
}

function cp_to_remote()
{
    local source_dir=$1
    local target_ip=$2
    local target_user=$3
    local target_pwd=$4
    local target_dir=$5
    log_info "sync file: ${source_dir} -> ${target_ip}:${target_dir} ..."
    expect <<EOF
    set timeout 1800
    spawn rsync -av ${source_dir} ${target_user}@${target_ip}:${target_dir}
    expect {
    "*yes*" {send "yes\r";exp_continue}
    "*password*" {send "${target_pwd}\r";exp_continue}
    }
    catch wait result
    exit [lindex \$result 3]
EOF
    return $?
}

function cp_from_remote(){
    local source_ip=$1
    local source_user=$2
    local source_pwd=$3
    local source_dir=$4
    local target_dir=$5
    log_info "sync file: ${source_ip}:${source_dir} -> ${target_dir} ..."
    expect <<EOF
    set timeout 1800
    spawn rsync -av ${source_user}@${source_ip}:${source_dir} ${target_dir}
    expect {
    "*yes*" {send "yes\r";exp_continue}
    "*password*" {send "${source_pwd}\r";exp_continue}
    }
    catch wait result
    exit [lindex \$result 3]
EOF
    return $?
}

function check_network_connection() {
  ip_list=$@
  return_value=0
  log_info "checking connection to: [ ${ip_list} ]"
  for ip in ${ip_list}; do
    ping ${ip} -c 4 &> /dev/null
    if [ $? -eq 0 ]; then
      log_info "ping ${ip} ... network good."
      return_value=$((return_value+0))
    else
      log_err "ping ${ip} ... failed. check your network please!!"
      return_value=$((return_value+1))
    fi
  done
  return ${return_value}
}