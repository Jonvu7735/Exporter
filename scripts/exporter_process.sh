#!/bin/bash
# Text Reset
RCol='\e[0m'
Gre='\e[0;32m'
Red='\e[0;31m'
success="[$Gre OK $RCol]"
fail="[$Red Fail $RCol]"
done="[$Gre Done $RCol]"

# Declare Variables
### Change here
exp_name="exporter_process"

### Not need change
os=$(grep -oP '(?<= )[0-9]+(?=\.)' /etc/redhat-release)
DTIME=$(date +"%Y%m%d")
HOMEPATH="/etc/prometheus"
USER='prometheus'
BINARYPATH=${HOMEPATH}/sbin
LOGPATH=${HOMEPATH}/logs
CNFPATH=${HOMEPATH}/var
SVPATH=${HOMEPATH}/services
DLog="${LOGPATH}/deploy_$IP_$DTIME.log"

### FUNCTION
function check_log() {
    [ ! -f "$LOGPATH/${exp_name}_${DTIME}.log" ] && touch $LOGPATH/${exp_name}_${DTIME}.log
    sudo chown -R $USER:$USER $HOMEPATH
}
function init_file() {
    if [[ $os == 6 ]]; then
        yes | sudo cp -f $SVPATH/${exp_name}/init.d/${exp_name} /etc/init.d/
        sudo chmod +x /etc/init.d/exporter_*
        sudo chown -R $USER:$USER /etc/init.d/exporter_*
        sudo chkconfig --add ${exp_name} >/dev/null 2>&1
        sudo chkconfig on ${exp_name} >/dev/null 2>&1
        echo -e "Init File: $done "

    elif [[ $os == 7 ]]; then
        yes | sudo cp -f $SVPATH/${exp_name}/systemd/${exp_name}.service /etc/systemd/system/
        sudo chown -R $USER:$USER /etc/systemd/system/${exp_name}.service
        sudo systemctl daemon-reload >/dev/null 2>&1
        sudo systemctl enable ${exp_name}.service >/dev/null 2>&1
        echo -e "Init File: $done "
    else
        echo "Can not detect OS"
    fi
}
function stop_exporter() {
    if [[ $os == 6 ]]; then
        /etc/init.d/${exp_name} stop >/dev/null 2>&1
        retval=$?
        [ $retval -eq 0 ] && sudo /usr/bin/kill "$(pgrep ${exp_name})" >/dev/null 2>&1
        echo -e $"Kill $exp_name : $success"
    elif [[ $os == 7 ]]; then
        sudo kill -9 $(pgrep ${exp_name}) >/dev/null 2>&1
        echo -e $"Kill $exp_name : $success"
    else
        echo -e "Process $exp_name not Kill : $fail"
    fi
}
function start_exporter() {
    if [[ $os == 6 ]]; then
        /etc/init.d/${exp_name} start >> ${DLog}
        echo -e $"Start $exp_name : $success"
    elif [[ $os == 7 ]]; then
        sudo systemctl start ${exp_name}.service >> ${DLog}
        echo -e $"Start $exp_name : $success"
    else
        echo "Can not start ${exp_name} : $fail"
  fi
}

function check_config() {
    if [[ ! -f "${CNFPATH}/${exp_name}.yaml" ]]; then
        local base_path=$(dirname "$0")
        local var_path="${base_path}/../var/${exp_name}.yaml"
        if [[ -f "${var_path}" && ! -f "${CNFPATH}/${exp_name}.yaml" ]]; then
            sudo cp -f "${var_path}" "${CNFPATH}/${exp_name}.yaml" || sudo touch "${CNFPATH}/${exp_name}.yaml"
            sudo chown -R $USER:$USER /"${CNFPATH}/${exp_name}.yaml"
        fi
        echo -e $"Check config: $success"
    fi
}

# Step 1
check_log
init_file
check_config
# Step 2
stop_exporter
start_exporter
# END
