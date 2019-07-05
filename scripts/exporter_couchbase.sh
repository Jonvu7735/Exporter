#!/bin/bash
read -p 'Username: ' uservar
read -sp 'Password: ' passvar
# Text Reset
RCol='\e[0m'    
Gre='\e[0;32m'
Red='\e[0;31m'
success="[$Gre OK $RCol]"
fail="[$Red Fail $RCol]"
done="[$Gre Done $RCol]"
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
		yes | sudo cp -f $SVPATH/${exp_name}/init.d/${exp_name} /etc/init.d/

		sudo chmod +x /etc/init.d/exporter_*
		sudo chown -R $USER:$USER /etc/init.d/exporter_*
		sudo chkconfig --add ${exp_name} >/dev/null 2>&1 
		sudo chkconfig on ${exp_name} >/dev/null 2>&1 
		echo \n "INIT FILE : "
		echo -e $done

	elif [[ $os == 7 ]]; then
		yes | sudo cp -f $SVPATH/${exp_name}/init.d/${exp_name} /etc/init.d/

		sudo chmod +x /etc/systemd/system/exporter_*.service
		sudo chown -R $USER:$USER /etc/systemd/system/exporter_*.service
		sudo systemctl daemon-reload >/dev/null 2>&1 
		sudo systemctl enable ${exp_name}.services >/dev/null 2>&1
		echo \n "INIT FILE : "
		echo -e $done 	

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
	user: ${uservar}
	password: ${passvar}
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
	echo "Create CNF file :"
	echo -e $done
}
function ln_file() {
	[ ! -f "${CNFPATH}/${exp_name}.yml" ] && sudo ln -s $CNFPATH/$exp_name.yml $BINARYPATH/config.yml
	[ ! -d "${BINARYPATH}/metrics"] && sudo ln -s $SVPATH/$exp_name/metrics $BINARYPATH/metrics
	echo "Soft Link Config :"
	echo -e $done
}
function stop_exporter() {
	os=`cat /etc/redhat-release | grep -oP '(?<= )[0-9]+(?=\.)'`
	local pid=`ps aux | grep -v grep | grep "${exp_name}" | sed 's/  \+/ /g' | cut -d' ' -f2`
	if [[ $os == 6 ]]; then
		sudo kill -9 $pid
		echo \n $"Stopping $exp_name: "
		echo -e $success
	elif [[ $os == 7 ]]; then
		sudo kill -9 $pid
		echo \n $"Stopping $exp_name: "
		echo -e $success
	else
        echo \n "Process ${exp_name} NOT RUN"
	fi
}
function start_exporter() {
	os=`cat /etc/redhat-release | grep -oP '(?<= )[0-9]+(?=\.)'`
	if [[ $os == 6 ]]; then
		/etc/init.d/${exp_name} start
		echo \n $"Start $exp_name: "
		echo -e $success
	elif [[ $os == 7 ]]; then
		sudo systemctl start ${exp_name}.service
		echo \n $"Start $exp_name: "
		echo -e $success
	else
        echo \n "Can not start ${exp_name}"
	fi
}

# Step 1
stop_exporter 
# Step 2
check_log
init_file
[ ! -f "$CNFPATH/${exp_name}.yml" ]  && chk_cnf
ln_file
# Step 3
start_exporter
# END