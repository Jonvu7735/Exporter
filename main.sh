#!/bin/bash
########################################################################################################################################################
# Text Reset
RCol='\e[0m'    
Gre='\e[0;32m'
Red='\e[0;31m'
success="[$Gre OK $RCol]"
fail="[$Red Fail $RCol]"
done="[$Gre Done $RCol]"
########################################################################################################################################################
# Declare Variables
declare -a service
service=("merge" "node") ### <<- INPUT SERVICE HERE
# Not need change
DTIME=$(date +"%Y%m%d")
SDIR=`pwd`
HOMEPATH="/etc/prometheus"
USER='prometheus'
exp_name="exporter_merge"
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
	echo -e "Check WORKDIR : $done"
}
# Check User
function check_user() {
	sudo getent passwd $USER > /dev/null 2&>1
    	if [ $? -eq 0 ]; then
	   	sudo chown -R $USER:$USER $HOMEPATH
		echo -e "User : $success"
    	else
       		sudo useradd --no-create-home --shell /sbin/nologin ${USER}
	   		sudo chown -R $USER:$USER $HOMEPATH
			echo -e "User : $success"
    	fi
}
# Update 
function update_source() {
	sudo rm -rf $BINARYPATH/metrics
	yes | sudo cp -rf $SDIR/sbin $HOMEPATH
	yes | sudo cp -rf $SDIR/services $HOMEPATH
	yes | sudo cp -rf $SDIR/scripts $HOMEPATH
	yes | sudo cp -rf $SDIR/var/${exp_name}.yaml $CNFPATH
	sudo chmod +x $BINARYPATH -R
	echo -e "Update Source : $done"

}
function setup_service() { 
		sudo /bin/sh $SCRPATH/exporter_${arr}.sh
		echo -e "Deploy exporter_${arr} : $done"

}

# Step 1: Base Check
check_homepath
check_user
update_source
init_file
# Step 2: Setup Exporter Service
for arr in "${service[@]}"
do 
	setup_service
done
echo -e "Install successful"
#END
