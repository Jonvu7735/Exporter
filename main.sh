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
IP=$(/sbin/ip add | egrep '10\.|172\.' | egrep 'brd 10\.|brd 172\.' | tr -s ' ' | awk 'BEGIN{FS="inet "}{print $2}' | awk 'BEGIN{FS="/[[:digit:]]+"}{print $1}' | head -n 1)
DTIME=$(date +"%Y-%m-%d")
SDIR="~/exporter"
HOMEPATH="/etc/prometheus"
USER='prometheus'
BINARYPATH=${HOMEPATH}/sbin
LOGPATH=${HOMEPATH}/logs
CNFPATH=${HOMEPATH}/var
SVPATH=${HOMEPATH}/services
DLog="${LOGPATH}/deploy_$IP_$DTIME.log"
merge_port="11011"
node_port="11020"
########################################################################################################################################################
# Check WorkDIR
function check_homepath() {
	arr_path=("$HOMEPATH" "$BINARYPATH" "$LOGPATH" "$CNFPATH" "$SVPATH")
	for hpath in "@{arr_path}"
	do 
		[ ! -d "${hpath}" ] && sudo mkdir -p "${hpath}"
	done
}
# Check User
function check_user() {
	sudo getent passwd $USER > /dev/null 2&>1
    if [ $? -eq 0 ]; then
       echo "User exists"
	   sudo chown -R $USER:$USER $HOMEPATH
    else
       echo "Create User Prometheus"
       sudo useradd --no-create-home --shell /sbin/nologin ${USER}
	   sudo chown -R $USER:$USER $HOMEPATH
    fi
}
# Update 
function update_source() {
	sudo cp -R $SDIR/sbin $BINARYPATH
	sudo cp -R $SDIR/services $SVPATH
	sudo cp $SDIR/var/exporter_merge.yml $CNFPATH
	sudo chmod +x $BINARYPATH -R
}
# Funtion Start/Stop/Restart
function stop_exporter() {
	ps=`ps aux | grep -v grep | grep -v rsync | grep "${prog}"`
	c=`ps aux | grep -v grep | grep -v rsync | grep "${prog}" | wc -l`

	echo -n $"Stopping $prog: "
	if [ $c -gt 0 ]; then
		pids=`echo "$ps" | sed 's/  \+/ /g' | cut -d' ' -f2`
		kill -9 $pids 
		echo -e $success
	fi
}
function start_exporter() {
	ps=`ps aux | grep -v grep | grep -v rsync | grep "${prog}" | awk 'BEGIN{FS="/exporter_"}{print $2}' | awk '{print $1}'`
    
	
	echo -n $"Starting $prog: "
	if [[ $ps == merge ]]; then
		[ ! -f "$LOGPATH/exporter_merge_$DTIME.log" ] && sudo touch $LOGPATH/exporter_merge_$DTIME.log
		chown $USER: $LOGPATH/exporter_merge_$DTIME.log
		bash -c "$BINARYPATH/${prog} -c $CNFPATH/${prog}.yml --listen-port $merge_port >> $LOGPATH/exporter_merge_$DTIME.log 2>&1"
		elif [[ $ps == node ]]; then
		[ ! -f "$LOGPATH/exporter_node_$DTIME.log" ] && sudo touch $LOGPATH/exporter_node_$DTIME.log
		chown $USER: $LOGPATH/exporter_node_$DTIME.log
		bash -c "$BINARYPATH/${prog} --web.listen-address=:${node_port} >> $LOGPATH/exporter_node_$DTIME.log 2>&1"
		echo -e $success
	fi
}

function init_file() {
    bash -c "cat /etc/redhat-release | grep -oP '(?<= )[0-9]+(?=\.)'"
	if [ $? -eq 6 ]; then
		echo "OS is CentOS 6"
		[ ! -f "/etc/init.d/exporter_merge" ] && sudo cp $SVPATH/exporter_merge/init.d/exporter_merge /etc/init.d/
		[ ! -f "/etc/init.d/exporter_node" ] && sudo cp $SVPATH/exporter_node/init.d/exporter_node /etc/init.d/
		sudo chmod +x /etc/init.d/exporter_*
		sudo chkconfig enable exporter_merge
		sudo chkconfig enable exporter_node
	elif [ $? -eq 7 ]; then
		echo "OS is CentOS 7"
		[ ! -f "/etc/systemd/system/exporter_merge.service" ] && sudo cp $SVPATH/exporter_merge/systemd/exporter_merge.service /etc/systemd/system/
		[ ! -f "/etc/systemd/system/exporter_node.service" ] && sudo cp $SVPATH/exporter_node/systemd/exporter_node.service /etc/systemd/system/
		sudo chmod +x /etc/systemd/system/exporter_*.service
		sudo systemctl daemon-reload
		sudo systemctl enable exporter_merge.service
		sudo systemctl enable exporter_node.service
    else
       echo "Can not detect OS"
    fi
}

# Step 1: Base Check
check_homepath
check_user
update_source
init_file
echo -e $success
# Step 2: Start Exporter_Merge & Node
echo - e "Starting Node_Exporter"
arr_path=("exporter_merge" "exporter_node")
for prog in "@{arr_path}"
	do 
		stop_exporter
		start_exporter
	done
#END
echo "Install successful."