<?php
	// we must never forget to start the session
	session_start();
	
	include 'config.php';

	if (isset($_POST['userid']) && isset($_POST['pass'])) 
	{
		$db = mysql_connect($hostname,$username,$password) or die("Could not connect to database.");
		mysql_select_db($database,$db);
		
		$userid = mysql_real_escape_string($_POST['userid']);
		
		$result = mysql_query("SELECT * FROM $webinterface_table WHERE username='" . $userid . "' AND password='" . mysql_real_escape_string($_POST['pass']) . "'",$db) or die("Could not query table.");
		if(!mysql_num_rows($result))
		{
			die("Invalid username / password.");
		}
		
		$_SESSION['clan_id'] = session_id();
		$_SESSION['clan_access'] = mysql_result($result,0,"access");
		
		header("Location: main.php");
		
		mysql_free_result($result);
		mysql_close($db);
	}
?>