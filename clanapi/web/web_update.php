<?php
	session_start();
	
	if($_SESSION['clan_access'] == 1)
	{
		die("Sorry, users do not have access to the admin section.");
	}
?>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Clan API Web Interface by Hawk552</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>

<body>
<?php
	include 'config.php';
	include 'access.php';
	
	if(!isset($_SESSION['clan_id']))
	{
		die("You are not logged in and cannot view this page.");
	}
	
	$access = $_POST['access']; //$_REQUEST['rank'];
	
	if($access >= $_SESSION['clan_access'])
	{
		die("You cannot edit someone's account whos access is equal to or greater than yours.");
	}

	$db = mysql_connect ($hostname, $username, $password) or die ('Failed to connect to database: ' . mysql_error());
	mysql_select_db($database);
	
	if(strlen($_POST['pass']) > 1)
	{
		$query = "UPDATE $webinterface_table SET password = '" . mysql_real_escape_string($_POST['pass']) . "', access = '" . mysql_real_escape_string($access) . "' WHERE CONVERT(username using utf8) = '" . mysql_real_escape_string($_POST['user']) . "'";
	}
	else
	{
		$query = "UPDATE $webinterface_table SET access = '" . mysql_real_escape_string($access) . "' WHERE CONVERT(username using utf8) = '" . mysql_real_escape_string($_POST['user']) . "'";
	}
	
	mysql_query($query) or die("Query failed: " . mysql_error());
		
	mysql_close($db);
		
	echo 'Member updated.';
?>
<br><br>
<a href="webadmins.php">Main Page </a><br>
<br>
(c) Hawk552, 2006
</body>
</html>