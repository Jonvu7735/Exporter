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
	sudo chmod +x $BINARYPATH
}
# Funtion Start/Stop/Restart
function stop() {
	ps=`ps aux | grep -v grep | grep -v rsync | grep "${prog}"`
	c=`ps aux | grep -v grep | grep -v rsync | grep "${prog}" | wc -l`

	echo -n $"Stopping $prog: "
	if [ $c -gt 0 ]; then
		pids=`echo "$ps" | sed 's/  \+/ /g' | cut -d' ' -f2`
		kill -9 $pids
		echo -e $success
	fi
}
function start() {
	ps=`ps aux | grep -v grep | grep -v rsync | grep "${prog}"`
	c=`ps aux | grep -v grep | grep -v rsync | grep "${prog}" | wc -l`

	echo -n $"Starting $prog: "
	if [ $c -eq 0 ]; then
		else -c $BINARYPATH/exporter_merge -c $CNFPATH/exporter_merge.yml --listen-port $merge_port >> $LOGPATH/exporter_merge_$DTIME.log 2>&1
		echo -e $success
	fi
}
function restart() {
	stop	#1
	start	#2
}

# Function exporter services
function exporter_node() {
	ps=`ps aux | grep -v grep | grep -v rsync | grep exporter_node"`
	c=`ps aux | grep -v grep | grep -v rsync | grep exporter_node | wc -l`
	
	if [ $c -gt 0 ]; then
		pids=`echo "$ps" | sed 's/  \+/ /g' | cut -d' ' -f2`
		kill -9 $pids >> $LOGPATH/exporter_node_$DTIME.log 2>&1
		$BINARYPATH/exporter_node --web.listen-address=:11020 >> $LOGPATH/exporter_node_$DTIME.log 2>&1
		echo -e $success
	fi
	
} 

########################################################################################################################################################
# Step 1: Base Check
check_homepath()
check_user()
update_source()
echo -e $success
# Step 3 : Start Exporter_Node
echo - e "Starting Node_Exporter"
exporter_node()
### Restart Exporter_Merge
stop()
start()
#END
echo "Install successful."