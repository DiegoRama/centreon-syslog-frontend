<?php
/*
 * Copyright 2005-2011 MERETHIS
 * Centreon is developped by : Julien Mathis and Romain Le Merlus under
 * GPL Licence 2.0.
 * 
 * This program is free software; you can redistribute it and/or modify it under 
 * the terms of the GNU General Public License as published by the Free Software 
 * Foundation ; either version 2 of the License.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
 * PARTICULAR PURPOSE. See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with 
 * this program; if not, see <http://www.gnu.org/licenses>.
 * 
 * Linking this program statically or dynamically with other modules is making a 
 * combined work based on this program. Thus, the terms and conditions of the GNU 
 * General Public License cover the whole combination.
 * 
 * As a special exception, the copyright holders of this program give MERETHIS 
 * permission to link this program with independent modules to produce an executable, 
 * regardless of the license terms of these independent modules, and to copy and 
 * distribute the resulting executable under terms of MERETHIS choice, provided that 
 * MERETHIS also meet, for each linked independent module, the terms  and conditions 
 * of the license of that module. An independent module is a module which is not 
 * derived from this program. If you modify this program, you may extend this 
 * exception to your version of the program, but you are not obliged to do so. If you
 * do not wish to do so, delete this exception statement from your version.
 * 
 * For more information : contact@centreon.com
 * 
 * Project name : Centreon Syslog
 * Module name: Centreon-Syslog-Frontend
 * 
 * SVN : $URL$
 * SVN : $Id$
 * 
 */
	include ("@CENTREON_ETC@centreon.conf.php");

	require_once $centreon_path . "www/modules/centreon-syslog-frontend/include/common/header.php";
	
	/*
	 * Common functions
	 */
	require_once $syslog_mod_path . 'class/syslogDB.class.php';
	require_once $syslog_mod_path . 'include/common/common-Func.php';
	require_once $syslog_mod_path . 'lib/odtPHP/odf.php';
	require_once $centreon_path . 'www/include/common/common-Func.php';
	
	/*
	 * Set language
	 */ 
	$locale = $oreon->user->get_lang();
	putenv("LANG=$locale");
	setlocale(LC_ALL, $locale);
	bindtextdomain("messages", $syslog_mod_path . "locale/");
	bind_textdomain_codeset("messages", "UTF-8"); 
	textdomain("messages");
	
	/*
	 * New ODT object
	 */
	$odf = new odf($syslog_mod_path ."include/export/odtPHP/template/syslog_events.odt");
	$odf->setVars('title', _("Syslog events"), true, 'UTF-8');
	$odf->setVars('from', _("From"), true, 'UTF-8');
	$odf->setVars('to', _("To"), true, 'UTF-8');
	
	/*
	 * Build PEAR DB object
	 */
	if (isset($_GET['collector']) && $_GET['collector'] != "" )
		$pearSyslogDB = new SyslogDB("syslog", $_GET['collector']);
	else
		exit(1);
	
	/*
	 * Database retrieve information for Centreon-Syslog
	 */
	$cfg_syslog = getSyslogOption($_GET['collector']);

	if (isset($_GET['type']) && $_GET['type'] != "" )
		$type=$_GET['type'];
	/*
	 * Get filters
	 */
	$sql_filter = array();
	if (isset($_GET['program']) && $_GET['program'] != "" )
		array_push($sql_filter ," (program = '". htmlentities($_GET['program'] , ENT_QUOTES) ."')  ");

	if (isset($_GET['host']) && $_GET['host'] != "")
		array_push($sql_filter ," (host = '". htmlentities($_GET['host'] , ENT_QUOTES) ."')  ");	

	if (isset($_GET['facility']) && $_GET['facility'] != "")
		if ((strcmp($_GET['Ffacility'], "") == 0) || (strcmp($_GET['Ffacility'], "eq") == 0)) {
			array_push($sql_filter ," (facility = '". htmlentities($_GET['facility'] , ENT_QUOTES) ."')  ");
		} else {
			$list_facilities = getListOfFacilities($_GET['facility'], $_GET['Ffacility']);
			$list = "";
			$listKeys = array_keys($list_facilities);
			foreach ($list_facilities as $key=>$value) {
				if (strcmp($list, "") != 0) {
					$list .= ",";
				}
				$list .= "'".$key."'";
			}
			array_push($sql_filter ," (facility IN (".$list."))  ");
		}

	if (isset($_GET['severity']) && $_GET['severity'] != "")
		if ((strcmp($_GET['Fseverity'], "") == 0) || (strcmp($_GET['Fseverity'], "eq") == 0)) {
			array_push($sql_filter ," (priority = '". htmlentities($_GET['severity'] , ENT_QUOTES) ."')  ");
		} else {
			$list_severities = getListOfSeverities($_GET['severity'], $_GET['Fseverity']);
			$list = "";
			$listKeys = array_keys($list_severities);
			foreach ($list_severities as $key=>$value) {
				if (strcmp($list, "") != 0) {
					$list .= ",";
				}
				$list .= "'".$key."'";
			}
			array_push($sql_filter ," (priority IN (".$list."))  ");
		}

	if (isset($_GET['msg']) && $_GET['msg'] != "")
		array_push($sql_filter ," (msg LIKE '%". htmlentities($_GET['msg'] , ENT_QUOTES) ."%')  ");

	$req_sql_filter = "";	
	if (isset( $sql_filter ))
		$req_sql_filter = join(" AND " , $sql_filter);

	/*
	 * Get start time and date
	 */
	if (isset($_GET["start_date"])) {
		$start_date = $_GET["start_date"];
		$StartDate = mktime (0, 0, 0, substr($start_date, 0, 2), substr($start_date, 3, 2), substr($start_date, 6, 4));
	} else
		$StartDate =  time();

	if (isset($_GET["start_time"])) {
		$StartTime = $_GET["start_time"];
	} else
		$StartTime = (Date("H")-1).":".Date("i");

	/*
	 * Get start time and date
	 */
	if (isset($_GET["end_date"])) {
		$end_date = $_GET["end_date"];
		$EndDate = mktime (0, 0, 0, substr($end_date, 0, 2), substr($end_date, 3, 2), substr($end_date, 6, 4));
	} else
		$EndDate = time();

	if (isset($_GET["end_time"])) {
		$EndTime = $_GET["end_time"];
	} else
		$EndTime = Date("H:i");
		
	$odf->setVars('datestart', $_GET["start_date"]." ".$StartTime, true, 'UTF-8');
	$odf->setVars('dateend', $_GET["end_date"]." ".$EndTime, true, 'UTF-8');

	/*
	 * Build SQL request
	 */
	if (isset($StartDate))
		$start_sql = strftime("%Y-%m-%d " , $StartDate).$StartTime;

	if (isset($EndDate))
		$end_sql = strftime("%Y-%m-%d " , $EndDate).$EndTime;

	if (count( $sql_filter ) > 0 ) 
		$req = "SELECT * FROM ".$cfg_syslog["db_table_logs_merge"]." WHERE datetime > '$start_sql' AND datetime <= '$end_sql' AND ". $req_sql_filter." ORDER BY datetime";
	else
		$req = "SELECT * FROM ".$cfg_syslog["db_table_logs_merge"]." WHERE datetime > '$start_sql' AND datetime <= '$end_sql' ORDER BY datetime";

	$nom = "syslog_events";

	$DBRESULT =& $pearSyslogDB->query($req);
	if (PEAR::isError($DBRESULT))
		print "Mysql Error : ".$DBRESULT->getMessage()."\n";

	$odf->setVars('tdatetime',_("Date / Time"), true, 'UTF-8');
	$odf->setVars('thost',_("Host"), true, 'UTF-8');
	$odf->setVars('tfacility',_("Facility"), true, 'UTF-8');
	$odf->setVars('tseverity',_("Severity"), true, 'UTF-8');
	$odf->setVars('tprogram',_("Program"), true, 'UTF-8');
	$odf->setVars('tmessage',_("Message"));
		
	$resource = $odf->setSegment('s');

	while ($DBRESULT->fetchInto($data)) {
		$resource->setVars('datetime', $data["datetime"], true, 'UTF-8');
		$resource->setVars('host', $data["host"], true, 'UTF-8');
		$resource->setVars('facility', $data["facility"], true, 'UTF-8');
		$resource->setVars('severity', $data["priority"], true, 'UTF-8');
		$resource->setVars('program', $data["program"], true, 'UTF-8');
		$resource->setVars('message', utf8_decode($data["msg"]));
		$resource->merge();
	}
	
	$odf->mergeSegment($resource);
	$odf->exportAsAttachedFile("syslog_events.odt");
 ?>