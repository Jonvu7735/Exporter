#!/bin/bash
# Declare Variables
### Change here
exp_name="exporter_couchbase"
### Not need change
DTIME=$(date +"%Y%m%d")
HOMEPATH="/etc/prometheus"
USER='prometheus'
BINARYPATH=${HOMEPATH}/sbin
LOGPATH=${HOMEPATH}/logs
CNFPATH=${HOMEPATH}/var
SVPATH=${HOMEPATH}/services
DLog="${LOGPATH}/deploy_$IP_$DTIME.log"

### FUNTION 
function check_log() {
	[ ! -f "$LOGPATH/${exp_name}_${DTIME}.log" ] && touch $LOGPATH/${exp_name}_${DTIME}.log	
	sudo chown -R $USER:$USER $HOMEPATH
}
function init_file() {
    os=`cat /etc/redhat-release | grep -oP '(?<= )[0-9]+(?=\.)'`
	if [[ $os == 6 ]]; then
		[ ! -f "/etc/init.d/${exp_name}" ] && sudo cp $SVPATH/${exp_name}/init.d/${exp_name} /etc/init.d/

		sudo chmod +x /etc/init.d/exporter_*
		sudo chown -R $USER:$USER /etc/init.d/exporter_*
		sudo chkconfig --add ${exp_name} >/dev/null 2>&1 
		sudo chkconfig on ${exp_name} >/dev/null 2>&1 

	elif [[ $os == 7 ]]; then
		[ ! -f "/etc/systemd/system/${exp_name}.service" ] && sudo cp $SVPATH/${exp_name}/systemd/${exp_name}.service /etc/systemd/system/

		sudo chmod +x /etc/systemd/system/exporter_*.service
		sudo chown -R $USER:$USER /etc/systemd/system/exporter_*.service
		sudo systemctl daemon-reload >/dev/null 2>&1 
		sudo systemctl enable ${exp_name}.services >/dev/null 2>&1 	

    else
       echo \n "Can not detect OS"
    fi
}
function chk_cnf() {
	[ ! -f "$CNFPATH/${exp_name}.yml"] && sudo touch $CNFPATH/$exp_name.yml
	sudo chown $USER:$USER $CNFPATH/$exp_name.yml
	echo "
	---
	
	web:
	listenAddress: :11022
	telemetryPath: /metrics
	timeout: 10s

	db:
	user: #Enter user here
	password: #Enter password here
	uri: http://localhost:8091
	timeout: 10s

	log:
	level: info
	format: text

	scrape:
	cluster: true
	node: true
	bucket: true
	xdcr: true
	" > $CNFPATH/$exp_name.yml
}
function ln_file() {
	[ -f "$CNFPATH/${exp_name}.yml" ] && sudo ln -s $CNFPATH/$exp_name.yml $BINARYPATH/config.yml
}
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

# Step 1
stop_exporter 
# Step 2
check_log
init_file
chk_cnf
ln_file
# Step 3
start_exporter
# END