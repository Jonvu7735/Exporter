#!/bin/bash
########################################################################################################################################################
# Text Reset
RCol='\e[0m'    
Gre='\e[0;32m'
Red='\e[0;31m'
success="[$Gre OK $RCol]"
fail="[$Red Fail $RCol]"
########################################################################################################################################################
# Declare Variables
exp_name="exprter_merge"
# Not need change
DTIME=$(date +"%Y%m%d")
SDIR=`pwd`
HOMEPATH="/etc/prometheus"
USER='prometheus'
BINARYPATH=${HOMEPATH}/sbin
LOGPATH=${HOMEPATH}/logs
CNFPATH=${HOMEPATH}/var
SVPATH=${HOMEPATH}/services
SCRPATH=${HOMEPATH}/scripts
DLog="${LOGPATH}/deploy_$IP_$DTIME.log"
########################################################################################################################################################
# Check WorkDIR
function check_homepath() {
	arr_path=(${HOMEPATH} ${BINARYPATH} ${LOGPATH} ${CNFPATH} ${SVPATH} ${SCRPATH})
	for hpath in "${arr_path[@]}"
	do 
		[ ! -d "${hpath}" ] && sudo mkdir -p "${hpath}"
	done
}
# Check User
function check_user() {
	sudo getent passwd $USER > /dev/null 2&>1
    	if [ $? -eq 0 ]; then
	   	sudo chown -R $USER:$USER $HOMEPATH
    	else
       		sudo useradd --no-create-home --shell /sbin/nologin ${USER}
	   		sudo chown -R $USER:$USER $HOMEPATH
    	fi
}
# Log File
function check_log() {
	[ ! -f "$LOGPATH/${exp_name}_${DTIME}.log" ] && touch $LOGPATH/${exp_name}_${DTIME}.log
	sudo chown -R $USER:$USER $HOMEPATH 
}
# Update 
function update_source() {
	yes | sudo cp -rf $SDIR/sbin $HOMEPATH
	yes | sudo cp -rf $SDIR/services $HOMEPATH
	yes | sudo cp -rf $SDIR/scripts $HOMEPATH
	yes | sudo cp $SDIR/var/${exp_name}.yaml $CNFPATH
	sudo chmod +x $BINARYPATH -R
}
function init_file() {
        os=`cat /etc/redhat-release | grep -oP '(?<= )[0-9]+(?=\.)'`
	if [[ $os == 6 ]]; then
		[ ! -f "/etc/init.d/${exp_name}" ] && sudo cp $SVPATH/${exp_name}/init.d/${exp_name} /etc/init.d/

		sudo chmod +x /etc/init.d/exporter_*
		sudo chown $USER:$USER /etc/init.d/exporter_*
		sudo chkconfig --add ${exp_name} >/dev/null 2>&1 
		sudo chkconfig on ${exp_name} >/dev/null 2>&1 

	elif [[ $os == 7 ]]; then
		[ ! -f "/etc/systemd/system/${exp_name}.service" ] && sudo cp $SVPATH/${exp_name}/systemd/${exp_name}.service /etc/systemd/system/

		sudo chmod +x /etc/systemd/system/exporter_*.service
		sudo chown $USER:$USER /etc/systemd/system/exporter_*.service
		sudo systemctl daemon-reload
		sudo systemctl enable ${exp_name}.service

    else
       echo "Can not detect OS"
    fi
}
# Funtion Start/Stop
function stop_exporter() {
	os=`cat /etc/redhat-release | grep -oP '(?<= )[0-9]+(?=\.)'`
	if [[ $os == 6 ]]; then
		/etc/init.d/${exp_name} stop
		echo \n $"Stopping $exp_name: "
	elif [[ $os == 7 ]]; then
		sudo systemctl stop ${exp_name}.service
		echo \n $"Stopping $exp_name: "
	else
        echo \n "Can not stop ${exp_name}"
	fi
}
function start_exporter() {
	os=`cat /etc/redhat-release | grep -oP '(?<= )[0-9]+(?=\.)'`
	if [[ $os == 6 ]]; then
		/etc/init.d/${exp_name} start
		echo \n $"Start $exp_name: "
	elif [[ $os == 7 ]]; then
		sudo systemctl start ${exp_name}.service
		echo \n $"Start $exp_name: "
	else
        echo \n "Can not start ${exp_name}"
	fi
}

# Step 1: Stop service
stop_exporter
# Step 2: Base Check
check_homepath
check_user
check_log
update_source
init_file
# Step 2: Start ${exp_name} & Node
start_exporter
echo "Install successful"
#END
