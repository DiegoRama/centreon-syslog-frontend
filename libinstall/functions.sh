#!/bin/bash 
## VARS
yes="y"
no="n"
ok="OK"
fail="FAIL"
passed="PASSED"
warning="WARNING"
critical="CRITICAL"

# Init binary to empty to use pathfind or manual define
GREP=""
CAT=""
SED=""
CHMOD=""
CHOWN=""
AKW=""
CRON=/etc/init.d/cron

## COLOR FUNCTIONS
RES_COL="60"
MOVE_TO_COL="\\033[${RES_COL}G"
SETCOLOR_INFO="\\033[1;38m"
SETCOLOR_SUCCESS="\\033[1;32m"
SETCOLOR_FAILURE="\\033[1;31m"
SETCOLOR_WARNING="\\033[1;33m"
SETCOLOR_NORMAL="\\033[0;39m"

#----
## print info message
## add info message to log file
## @param	message info
## @param	type info (ex: INFO, username...)
## @Stdout	info message
## @Globals	LOG_FILE
#----
function echo_info() {
    echo -e "${1}${MOVE_TO_COL}${SETCOLOR_INFO}${2}${SETCOLOR_NORMAL}" 
    echo -e "$1 : $2" >> $LOG_FILE
}

#----
## print success message
## add success message to log file
## @param	message
## @param	word to specify success (ex: OK)
## @Stdout	success message
## @Globals	LOG_FILE
#----
function echo_success() {
    echo -e "${1}${MOVE_TO_COL}${SETCOLOR_SUCCESS}${2}${SETCOLOR_NORMAL}" 
    echo -e "$1 : $2" >> $LOG_FILE
}

#----
## print failure message
## add failure message to log file
## @param	message
## @param	word to specify failure (ex: fail)
## @Stdout	failure message
## @Globals	LOG_FILE
#----
function echo_failure() {
    echo -e "${1}${MOVE_TO_COL}${SETCOLOR_FAILURE}${2}${SETCOLOR_NORMAL}"
    echo -e "$1 : $2" >> $LOG_FILE
}

#----
## print passed message
## add passed message to log file
## @param	message
## @param	word to specify pass (ex: passed)
## @Stdout	passed message
## @Globals	LOG_FILE
#----
function echo_passed() {
    echo -e "${1}${MOVE_TO_COL}${SETCOLOR_WARNING}${2}${SETCOLOR_NORMAL}"
    echo -e "$1 : $2" >> $LOG_FILE
}

#----
## print warning message
## add warning message to log file
## @param	message
## @param	word to specify warning (ex: warn)
## @Stdout	warning message
## @Globals	LOG_FILE
#----
function echo_warning() {
    echo -e "${1}${MOVE_TO_COL}${SETCOLOR_WARNING}${2}${SETCOLOR_NORMAL}"
    echo -e "$1 : $2" >> $LOG_FILE
}

#----
## add message on log file
## @param	type of message level (debug, info, ...)
## @param	message
## @Globals	LOG_FILE
#----
function log() {
	local program="$0"
	local type="$1"
	shift
	local message="$@"
	echo -e "[$program]:$type: $message" >> $LOG_FILE
}

#----
## define a specific variables for grep,cat,sed,... binaries
## This functions was been use in first line on your script
## @return 0	All is't ok
## @return 1	problem with one variable
## @Globals	GREP, CAT, SED, CHMOD, CHOWN
#----
function define_specific_binary_vars() {
	local vars_bin="GREP CAT SED CHMOD CHOWN RM MKDIR CP MV AWK"
	local var_bin_tolower=""
	for var_bin in $vars_bin ; 
	do
		if [ -z $(eval echo \$$var_bin) ] ; then
			var_bin_tolower="$(echo $var_bin | tr [:upper:] [:lower:])"
			pathfind_ret "$var_bin_tolower" "$(echo -n $var_bin)"
			if [ "$?" -eq 0 ] ; then
				eval "$var_bin='$(eval echo \$$var_bin)/$var_bin_tolower'"
				export $(echo $var_bin)
				log "INFO" "$var_bin=$(eval echo \$$var_bin)"
			else
				return 1
			fi
		fi
	done
	return 0
}

#----
## find in $PATH if binary exist
## @param	file to test
## @return 0	found
## @return 1	not found
## @Globals	PATH
#----
function pathfind() {
	OLDIFS="$IFS"
	IFS=:
	for p in $PATH; do
		if [ -x "$p/$*" ]; then
			IFS="$OLDIFS"
			return 0
		fi
	done
	IFS="$OLDIFS"
	return 1
}

#----
## find in $PATH if binary exist and return dirname
## @param	file to test
## @param	global variable to set a result
## @return 0	found
## @return 1	not found
## @Globals	PATH
#----
function pathfind_ret() {
	local bin=$1
	local var_ref=$2
	local OLDIFS="$IFS"
	IFS=:
	for p in $PATH; do
		if [ -x "$p/$bin" ]; then
			IFS="$OLDIFS"
			eval $var_ref=$p
			return 0
		fi
	done
	IFS="$OLDIFS"
	return 1
}

#----
## make a question with yes/no possiblity
## use "no" response by default
## @param	message to print
## @param 	default response (default to no)
## @return 0 	yes
## @return 1 	no
#----
function yes_no_default() {
	local message=$1
	local default=${2:-$no}
	local res="not_define"
	while [ "$res" != "$yes" ] && [ "$res" != "$no" ] && [ ! -z "$res" ] ; do
		echo -e "\n$message\n[y/n], default to [$default]:"
		echo -en "> "
		read res
		[ -z "$res" ] && res="$default"
	done
	if [ "$res" = "$yes" ] ; then 
		return 0
	else 
		return 1
	fi
}

#----
## get right and left spaces of header line
## @return 	"$x:$y"
#----
function get_spaces_modulo_name() {
	lenght_module_name=`echo ${#RNAME}`
	let "spaces=$LINE_SIZE-19-$lenght_module_name"
	let "modulo_spaces=$spaces%2"

	if [ $modulo_spaces -eq 0 ] ; then
			let "x=$spaces/2"
			echo "$x:$x"
			return 0
	else
			let "x=$spaces/2+1"
			let "y=$spaces/2"
			echo "$x:$y"
			return 0
	fi
}

#----
## get right and left spaces of header version line
## @return 	"$x:$y"
#----
function get_spaces_modulo_version() {
	lenght_module_version=`echo ${#VERSION}`
	let "spaces=$LINE_SIZE-4-$lenght_module_version"
	let "modulo_spaces=$spaces%2"

	if [ $modulo_spaces -eq 0 ] ; then
			let "x=$spaces/2"
			echo "$x:$x"
			return 0
	else
			let "x=$spaces/2+1"
			let "y=$spaces/2"
			echo "$x:$y"
			return 0
	fi
}

#----
## print header of script installation
#----
function print_header() {
	name_spaces=`get_spaces_modulo_name;`
	spaces_x_name=`echo $name_spaces | cut -d":" -f1`
	version_spaces=`get_spaces_modulo_version;`
	spaces_x_version=`echo $version_spaces | cut -d":" -f1`

	echo -e "################################################################################"
	echo -e "#                                                                              #"
	echo -e "#\\033[${spaces_x_name}GThanks for using ${RNAME}\\033[${LINE_SIZE}G#"
	echo -e "#\\033[${spaces_x_version}Gv ${VERSION}\\033[${LINE_SIZE}G#"
	echo -e "#                                                                              #"
	echo -e "################################################################################"
}

#----
## get right and left spaces of header version line
## @return 	"$x:$y"
#----
function get_spaces_modulo_forge_url() {
	lenght_forge_url=`echo ${#FORGE_URL}`
	let "spaces=$LINE_SIZE-2-$lenght_forge_url"
	let "modulo_spaces=$spaces%2"

	if [ $modulo_spaces -eq 0 ] ; then
			let "x=$spaces/2"
			echo "$x:$x"
			return 0
	else
			let "x=$spaces/2+1"
			let "y=$spaces/2"
			echo "$x:$y"
			return 0
	fi
}

#----
## print foorter of script installation
#----
function print_footer() {
	forge_url_spaces=`get_spaces_modulo_forge_url;`
	spaces_x=`echo $forge_url_spaces | cut -d":" -f1`
	
	echo -e "################################################################################"
	echo -e "#                                                                              #"
	echo -e "#       Go to the URL : http://your-server/centreon/ to finish the setup       #"
	echo -e "#                                                                              #"
	echo -e "#       Report bugs at                                                         #"
	echo -e "#\\033[${spaces_x}G${FORGE_URL}\\033[${LINE_SIZE}G#"
	echo -e "#                                                                              #"
	echo -e "################################################################################"
}

#----
## delete white space
## @param	string
## @return	string without space at start end end
#----
function trim() { 
	echo $1; 
}

#---
## {check if xmlwriter, libssh2 and ssh2 for PHP is present}
#----
function check_phpExtensions {
	echo ""
	echo "$line"
	echo -e "\tChecking php extension"
	echo "$line"
	
	php_extension=$(php -i | ${GREP} -e "^extension_dir" | awk '{print $3}')
	ssh2_extension=$(ls $php_extension | ${GREP} "ssh2.so" | wc -l)
	xmlwriter_extension=$(ls $php_extension | ${GREP} "xmlwriter.so" | wc -l)
	
	if [ $ssh2_extension -ge 1 ]; then
		echo_success "SSH2 extension for PHP:" "$ok"
	else
		#echo_failure "SSH2 extension for PHP:" "$fail"
		echo_warning "SSH2 extension for PHP:" "$warning"
		echo -e ""
		echo -e "This PHP extension (ssh2.so) is used to export configuration from Centreon"
		echo -e "web interface to Syslog collector. You can install it after the end of this"
		echo -e "intallation. If you don't install it, you must edit directly Syslog collector"
		echo -e "configuration file on "etc" directory specified during installation of server."
		echo -e ""
	fi
	
	if [ $xmlwriter_extension -ge 1 ]; then
		echo_success "$(gettext "XML-Writer extension for PHP:")" "$ok"
	else
		xmlwriter_extension=$(php -info | grep "xmlwriter" | wc -l)
		if [ $xmlwriter_extension -ge 1 ]; then
			echo_success "$(gettext "XML-Writer extension for PHP:")" "$ok"
		else
			echo_failure "$(gettext "XML-Writer extension for PHP:")" "$fail"
			echo -e "Please install php-xml and reload install script."
			exit 1
		fi
	fi
}

function update_module_name() {
	echo ""
	echo "$line"
	echo -e "\tUpdate Module Name"
	echo "$line"
	
	FILE="$INSTALL_DIR/upgrade_configuration.php"
	$SED -i -e 's|@CENTREON_ETC@|'"$CENTREON_CONF/"'|g' $TEMP_D/$FILE 2>> $LOG_FILE
	
	php -q $FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Update module name \"Syslog\" to \"centreon-syslog\":" "$ok"
	else
		echo_failure "Update module name \"Syslog\" to \"centreon-syslog\":" "$fail"
	fi
}

#---
## {Get Centreon install dir and user/group for apache}
#----
function get_centreon_parameters_24() {
	CENTREON_DIR=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "INSTALL_DIR_CENTREON" | cut -d '=' -f2`;
	CENTREON_DIR=$(trim $CENTREON_DIR)
	CENTREON_LOG_DIR=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "CENTREON_LOG" | cut -d '=' -f2`;
	CENTREON_LOG_DIR=$(trim $CENTREON_LOG_DIR)
	CENTREON_VARLIB=`${CAT} $CENTREON_CONF/instCentStorage.conf | ${GREP} "CENTREON_VARLIB" | cut -d '=' -f2`;
	CENTREON_VARLIB=$(trim $CENTREON_VARLIB)
	CENTCORE_CMD=$CENTREON_VARLIB"/centcore.cmd"
	CENTCORE_CMD=$(trim $CENTCORE_CMD)
	
	WEB_USER=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "WEB_USER" | cut -d '=' -f2`;
	WEB_USER=$(trim $WEB_USER)
	WEB_GROUP=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "WEB_GROUP" | cut -d '=' -f2`;
	WEB_GROUP=$(trim $WEB_GROUP)
	
	NAGIOS_DIR=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "INSTALL_DIR_NAGIOS" | cut -d '=' -f2`;
	NAGIOS_DIR=$(trim $NAGIOS_DIR)
	NAGIOS_BINARY=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "NAGIOS_BINARY" | cut -d '=' -f2`;
	NAGIOS_BINARY=$(trim $NAGIOS_BINARY)
	NAGIOSTATS_BINARY=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "NAGIOSTATS_BINARY" | cut -d '=' -f2`;
	NAGIOSTATS_BINARY=$(trim $NAGIOSTATS_BINARY)
	NAGIOS_LOG_DIR=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "NAGIOS_VAR" | cut -d '=' -f2`;
	NAGIOS_LOG_DIR=$(trim $NAGIOS_LOG_DIR)
	NAGIOS_CMD=$NAGIOS_LOG_DIR"/rw/nagios.cmd"
	NAGIOS_CMD=$(trim $NAGIOS_CMD)
	NAGIOS_PLUGIN=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "NAGIOS_PLUGIN" | cut -d '=' -f2`;
	NAGIOS_PLUGIN=$(trim $NAGIOS_PLUGIN)
	NAGIOS_USER=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "NAGIOS_USER" | cut -d '=' -f2`;
	NAGIOS_USER=$(trim $NAGIOS_USER)
	NAGIOS_GROUP=`${CAT} $CENTREON_CONF/$FILE_CONF | ${GREP} "NAGIOS_GROUP" | cut -d '=' -f2`;	
	NAGIOS_GROUP=$(trim $NAGIOS_GROUP)

	RESULT=0
	# check centreon parameters
	if [ "$CENTREON_DIR" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	if [ "$CENTREON_LOG_DIR" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	if [ "$CENTREON_VARLIB" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	
	# check apache parameters
	if [ "$WEB_USER" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	if [ "$WEB_GROUP" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	
	# check Nagios parameters
	if [ "$NAGIOS_DIR" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	if [ "$NAGIOS_BINARY" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	if [ "$NAGIOSTATS_BINARY" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	if [ "$NAGIOS_LOG_DIR" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	if [ "$NAGIOS_PLUGIN" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	if [ "$NAGIOS_USER" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	if [ "$NAGIOS_GROUP" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	
	if [ "$RESULT" -eq 12 ]; then 
		return 1;
	else
		return 0;
	fi
}

function get_centreon_parameters_25() {
	CENTREON_DIR=`${CAT} $CENTREON_CONF/$FILE_CONF_CENTCORE  | ${GREP} "INSTALL_DIR_CENTREON" | cut -d '=' -f2`;
	CENTREON_DIR=$(trim $CENTREON_DIR)

	WEB_USER=`ls -l $CENTREON_DIR/www/main.php | ${AWK} '{print $3}'`;
	WEB_USER=$(trim $WEB_USER)
	WEB_GROUP=`ls -l $CENTREON_DIR/www/main.php | ${AWK} '{print $4}'`;
	WEB_GROUP=$(trim $WEB_GROUP)

	RESULT=0
	# check centreon parameters
	if [ "$CENTREON_DIR" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi

	# check apache parameters
	if [ "$WEB_USER" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi
	if [ "$WEB_GROUP" != "" ] ; then
		RESULT=`expr $RESULT + 1`
	fi

	if [ "$RESULT" -eq 3 ]; then
		return 1;
	else
		return 0;
	fi
}


#---
## {Get location of instCentWeb.conf file}
##
## @Stdout Error message if user set incorrect directory
## @Stdin Path with must contain $FILE_CONF
#----
function get_centreon_configuration_location() {
	echo ""
	echo "$line"
	echo -e "\tLoad parameters"
	echo "$line"
	err=1
	while [ $err != 0 ]
	do
		echo -e "Please specify the directory with contain \"$FILE_CONF\""
		echo -en "> "
		read temp_read

		if [ -z "$temp_read" ]; then
			echo_failure "The directory does not exist!" "$fail"
		fi

		if [ -d $temp_read ] && [ -f $temp_read/$FILE_CONF ] ; then
			err=0
			CENTREON_CONF=$temp_read
		else
			if [ -f $temp_read/$FILE_CONF_CENTCORE ] ; then
				err=0
				CENTREON_CONF=$temp_read
			else
				echo_failure "File \"$FILE_CONF\" does not exist in this directory!" "$fail"
			fi
		fi
	done
}

#---
## {Install my Module}
##
## @Stdout Actions realised by function
## @Stderr Log into $LOG_FILE
function install_module() {
	# Comment unused functions
	install_module_web;
	#install_module_binaries;
	#install_module_cron_files;
	#install_module_cron;
	install_module_end;
}

#---
## {Install Web Interface of Module}
##
## @Stdout Actions realised by function
## @Stderr Log into $LOG_FILE
function install_module_web() {
	INSTALL_DIR_MODULE=$CENTREON_DIR/$MODULE_DIR

	echo ""
	echo "$line"
	echo -e "\tInstall $RNAME web interface"
	echo "$line"
	TEMP_D="/tmp/Install_module"
	${MKDIR} -p $TEMP_D/www >> $LOG_FILE 2>> $LOG_FILE

	${CP} -Rf $MODULE_DIR/* $TEMP_D/www >> $LOG_FILE 2>> $LOG_FILE

	find $TEMP_D/www -type f \
		-exec ${SED} -i -e "s|@CENTREON_ETC@|$CENTREON_CONF|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_DIR@|$CENTREON_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_LOG_DIR@|$CENTREON_LOG_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_VARLIB@|$CENTREON_VARLIB|g" {} \; \
		-exec ${SED} -i -e "s|@CENTCORE_CMD@|$CENTCORE_CMD|g" {} \; \
		-exec ${SED} -i -e "s|@WEB_USER@|$WEB_USER|g" {} \; \
		-exec ${SED} -i -e "s|@WEB_GROUP@|$WEB_GROUP|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_DIR@|$NAGIOS_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_BINARY@|$NAGIOS_BINARY|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOSTATS_BINARY@|$NAGIOSTATS_BINARY|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_CMD@|$NAGIOS_CMD|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_LOG_DIR@|$NAGIOS_LOG_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_PLUGIN@|$NAGIOS_PLUGIN|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_USER@|$NAGIOS_USER|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_GROUP@|$NAGIOS_GROUP|g" {} \;  \
		-exec ${SED} -i -e "s|@INSTALL_DIR_CENTREON@|$CENTREON_DIR|g" {} \;
	if [ "$?" -eq 0 ] ; then
		echo_success "Changing macros" "$ok"
	else 
		echo_failure "Changing macros" "$fail"
		exit 1
	fi
	
	${CHMOD} -R 755 $TEMP_D/* >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Setting right" "$ok"
	else 
		echo_failure "Setting right" "$fail"
		exit 1
	fi	

	${CHOWN} -R $WEB_USER.$WEB_GROUP $TEMP_D/* >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Setting owner/group" "$ok"
	else 
		echo_failure "Setting owner/group" "$fail"
		exit 1
	fi
	
	${RM} -Rf $CENTREON_DIR/www/modules/Syslog
	if [ "$?" -eq 0 ] ; then
		echo_success "Delete old install module" "$ok"
	else 
		echo_failure "Delete old install module" "$fail"
		exit 1
	fi
	

	${MKDIR} -p $INSTALL_DIR_MODULE >> $LOG_FILE 2>> $LOG_FILE
	${CP} -Rf --preserve $TEMP_D/www/* $INSTALL_DIR_MODULE >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Copying module" "$ok"
	else 
		echo_failure "Copying module" "$fail"
		exit 1
	fi

	${RM} -Rf $TEMP_D >> $LOG_FILE 2>> $LOG_FILE
}

#---
## {Install binaries of Module}
##
## @Stdout Actions realised by function
## @Stderr Log into $LOG_FILE
function install_module_binaries() {
	echo ""
	echo "$line"
	echo -e "\tInstall $RNAME binaries"
	echo "$line"
	TEMP_D="/tmp/Install_module"
	${MKDIR} -p $TEMP_D/bin >> $LOG_FILE 2>> $LOG_FILE

	${CP} -Rf bin/* $TEMP_D/bin >> $LOG_FILE 2>> $LOG_FILE

	find $TEMP_D/bin -type f \
		-exec ${SED} -i -e "s|@CENTREON_ETC@|$CENTREON_CONF|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_DIR@|$CENTREON_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_LOG_DIR@|$CENTREON_LOG_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_VARLIB@|$CENTREON_VARLIB|g" {} \; \
		-exec ${SED} -i -e "s|@CENTCORE_CMD@|$CENTCORE_CMD|g" {} \; \
		-exec ${SED} -i -e "s|@WEB_USER@|$WEB_USER|g" {} \; \
		-exec ${SED} -i -e "s|@WEB_GROUP@|$WEB_GROUP|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_DIR@|$NAGIOS_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_BINARY@|$NAGIOS_BINARY|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOSTATS_BINARY@|$NAGIOSTATS_BINARY|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_CMD@|$NAGIOS_CMD|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_LOG_DIR@|$NAGIOS_LOG_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_PLUGIN@|$NAGIOS_PLUGIN|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_USER@|$NAGIOS_USER|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_GROUP@|$NAGIOS_GROUP|g" {} \;  \
		-exec ${SED} -i -e "s|@INSTALL_DIR_CENTREON@|$CENTREON_DIR|g" {} \;
	if [ "$?" -eq 0 ] ; then
		echo_success "Changing macros" "$ok"
	else 
		echo_failure "Changing macros" "$fail"
		exit 1
	fi

	${CHMOD} -R 755 $TEMP_D/* >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Setting right" "$ok"
	else 
		echo_failure "Setting right" "$fail"
		exit 1
	fi	

	${CHOWN} -R $WEB_USER.$WEB_GROUP $TEMP_D/* >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Setting owner/group" "$ok"
	else 
		echo_failure "Setting owner/group" "$fail"
		exit 1
	fi

	${CP} -Rf --preserve $TEMP_D/bin/* $CENTREON_DIR/bin/. >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Copying module" "$ok"
	else 
		echo_failure "Copying module" "$fail"
		exit 1
	fi
	
	${RM} -Rf $TEMP_D >> $LOG_FILE 2>> $LOG_FILE
}

#---
## {Install cron files of Module}
##
## @Stdout Actions realised by function
## @Stderr Log into $LOG_FILE
function install_module_cron_files() {
	echo ""
	echo "$line"
	echo -e "\tInstall $RNAME cron"
	echo "$line"
	TEMP_D="/tmp/Install_module"
	${MKDIR} -p $TEMP_D/cron >> $LOG_FILE 2>> $LOG_FILE

	${CP} -Rf cron/* $TEMP_D/cron >> $LOG_FILE 2>> $LOG_FILE

	find $TEMP_D/cron -type f \
		-exec ${SED} -i -e "s|@CENTREON_ETC@|$CENTREON_CONF|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_DIR@|$CENTREON_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_LOG_DIR@|$CENTREON_LOG_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_VARLIB@|$CENTREON_VARLIB|g" {} \; \
		-exec ${SED} -i -e "s|@CENTCORE_CMD@|$CENTCORE_CMD|g" {} \; \
		-exec ${SED} -i -e "s|@WEB_USER@|$WEB_USER|g" {} \; \
		-exec ${SED} -i -e "s|@WEB_GROUP@|$WEB_GROUP|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_DIR@|$NAGIOS_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_BINARY@|$NAGIOS_BINARY|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOSTATS_BINARY@|$NAGIOSTATS_BINARY|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_CMD@|$NAGIOS_CMD|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_LOG_DIR@|$NAGIOS_LOG_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_PLUGIN@|$NAGIOS_PLUGIN|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_USER@|$NAGIOS_USER|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_GROUP@|$NAGIOS_GROUP|g" {} \; \
		-exec ${SED} -i -e "s|@INSTALL_DIR_CENTREON@|$CENTREON_DIR|g" {} \;
	if [ "$?" -eq 0 ] ; then
		echo_success "Changing macros" "$ok"
	else 
		echo_failure "Changing macros" "$fail"
		exit 1
	fi

	${CHMOD} -R 755 $TEMP_D/* >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Setting right" "$ok"
	else 
		echo_failure "Setting right" "$fail"
		exit 1
	fi	

	${CHOWN} -R $WEB_USER.$WEB_GROUP $TEMP_D/* >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Setting owner/group" "$ok"
	else 
		echo_failure "Setting owner/group" "$fail"
		exit 1
	fi

	${CP} -Rf --preserve $TEMP_D/cron/* $CENTREON_DIR/cron/. >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Copying module" "$ok"
	else 
		echo_failure "Copying module" "$fail"
		exit 1
	fi
	
	${RM} -Rf $TEMP_D >> $LOG_FILE 2>> $LOG_FILE
}

#---
## {Install plugins of Module}
##
## @Stdout Actions realised by function
## @Stderr Log into $LOG_FILE
function install_module_plugins() {
	echo ""
	echo "$line"
	echo -e "\tInstall $RNAME plugins"
	echo "$line"
	TEMP_D="/tmp/Install_module"
	${MKDIR} -p $TEMP_D/plugins >> $LOG_FILE 2>> $LOG_FILE

	${CP} -Rf plugins/* $TEMP_D/plugins >> $LOG_FILE 2>> $LOG_FILE

	find $TEMP_D/plugins -type f \
		-exec ${SED} -i -e "s|@CENTREON_ETC@|$CENTREON_CONF|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_DIR@|$CENTREON_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_LOG_DIR@|$CENTREON_LOG_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_VARLIB@|$CENTREON_VARLIB|g" {} \; \
		-exec ${SED} -i -e "s|@CENTCORE_CMD@|$CENTCORE_CMD|g" {} \; \
		-exec ${SED} -i -e "s|@WEB_USER@|$WEB_USER|g" {} \; \
		-exec ${SED} -i -e "s|@WEB_GROUP@|$WEB_GROUP|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_DIR@|$NAGIOS_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_BINARY@|$NAGIOS_BINARY|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOSTATS_BINARY@|$NAGIOSTATS_BINARY|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_CMD@|$NAGIOS_CMD|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_LOG_DIR@|$NAGIOS_LOG_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_PLUGIN@|$NAGIOS_PLUGIN|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_USER@|$NAGIOS_USER|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_GROUP@|$NAGIOS_GROUP|g" {} \;  \
		-exec ${SED} -i -e "s|@INSTALL_DIR_CENTREON@|$CENTREON_DIR|g" {} \;
	if [ "$?" -eq 0 ] ; then
		echo_success "Changing macros" "$ok"
	else 
		echo_failure "Changing macros" "$fail"
		exit 1
	fi

	${CHMOD} -R 755 $TEMP_D/* >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Setting right" "$ok"
	else 
		echo_failure "Setting right" "$fail"
		exit 1
	fi	

	${CHOWN} -R $WEB_USER.$WEB_GROUP $TEMP_D/* >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Setting owner/group" "$ok"
	else 
		echo_failure "Setting owner/group" "$fail"
		exit 1
	fi

	${CP} -Rf --preserve $TEMP_D/plugins/* $CENTREON_DIR/plugins/. >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Copying module" "$ok"
	else 
		echo_failure "Copying module" "$fail"
		exit 1
	fi
	
	${RM} -Rf $TEMP_D >> $LOG_FILE 2>> $LOG_FILE
}

#---
## {Install plugins of Module}
##
## @Stdout Actions realised by function
## @Stderr Log into $LOG_FILE
function install_module_cron() {
	echo ""
	echo "$line"
	echo -e "\tIntegrate $NAME cron"
	echo "$line"
	TEMP_D="/tmp/Install_module"
	${MKDIR} -p $TEMP_D/cron >> $LOG_FILE 2>> $LOG_FILE

	${CP} -Rf $CRON_FILE $TEMP_D/cron/. >> $LOG_FILE 2>> $LOG_FILE
	find $TEMP_D/cron -type f \
		-exec ${SED} -i -e "s|@CENTREON_ETC@|$CENTREON_CONF|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_DIR@|$CENTREON_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_LOG_DIR@|$CENTREON_LOG_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@CENTREON_VARLIB@|$CENTREON_VARLIB|g" {} \; \
		-exec ${SED} -i -e "s|@CENTCORE_CMD@|$CENTCORE_CMD|g" {} \; \
		-exec ${SED} -i -e "s|@WEB_USER@|$WEB_USER|g" {} \; \
		-exec ${SED} -i -e "s|@WEB_GROUP@|$WEB_GROUP|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_DIR@|$NAGIOS_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_BINARY@|$NAGIOS_BINARY|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOSTATS_BINARY@|$NAGIOSTATS_BINARY|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_CMD@|$NAGIOS_CMD|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_LOG_DIR@|$NAGIOS_LOG_DIR|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_PLUGIN@|$NAGIOS_PLUGIN|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_USER@|$NAGIOS_USER|g" {} \; \
		-exec ${SED} -i -e "s|@NAGIOS_GROUP@|$NAGIOS_GROUP|g" {} \; \
		-exec ${SED} -i -e "s|@INSTALL_DIR_CENTREON@|$CENTREON_DIR|g" {} \;
	if [ "$?" -eq 0 ] ; then
		echo_success "Changing macros" "$ok"
	else 
		echo_failure "Changing macros" "$fail"
		exit 1
	fi

	${CP} -Rf $TEMP_D/cron/$CRON_FILE /etc/cron.d/$NAME >> $LOG_FILE 2>> $LOG_FILE

	${CHMOD} -R 644 /etc/cron.d/$NAME >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Setting right" "$ok"
	else 
		echo_failure "Setting right" "$fail"
		exit 1
	fi	

	${CHOWN} -R root:root /etc/cron.d/$NAME >> $LOG_FILE 2>> $LOG_FILE
	if [ "$?" -eq 0 ] ; then
		echo_success "Setting owner/group" "$ok"
	else 
		echo_failure "Setting owner/group" "$fail"
		exit 1
	fi
	
	${RM} -Rf $TEMP_D >> $LOG_FILE 2>> $LOG_FILE
}

#---
## {End of installation}
##
## @Stdout Actions realised by function
## @Stderr Log into $LOG_FILE
function install_module_end() {
	echo ""
	echo "$line"
	echo -e "\tEnd of $RNAME installation"
	echo "$line"
	echo_success "Installation of $RNAME is finished" "$ok"
	echo -e  "See README and the log file for more details."
	echo ""
}
