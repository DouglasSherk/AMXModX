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
	
	if(!isset($_POST['user']) || !isset($_POST['pass']) || !isset($_POST['access']))
	{
		die("You must specify all fields.");
	}
	
	str_replace("\"","\'",$_POST['user']);
	str_replace("\"","\'",$_POST['pass']);
	str_replace("\"","\'",$_POST['access']);
	
	if($_POST['access'] > $_SESSION['clan_access'] || $_POST['access'] == sizeof($access) - 1)
	{
		die("You cannot add someone such that they have higher access than you.");
	}

	$db = mysql_connect ($hostname, $username, $password) or die ('Cannot connect to database: ' . mysql_error());
	mysql_select_db($database);
		
	$query = "INSERT INTO $webinterface_table (username,password,access) VALUES ('" . mysql_real_escape_string($_POST['user']) . "','" . mysql_real_escape_string($_POST['pass']) . "','" . mysql_real_escape_string($_POST['access']) . "')";
	mysql_query($query) or die("Query failed " . mysql_error());
		
	mysql_close($db);
		
	echo 'Member added.';
?>
<br><br>
<a href="webadmins.php">Main Page</a><br>
<br>
(c) Hawk552, 2006
</body>
</html>
