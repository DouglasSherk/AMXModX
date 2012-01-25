<?php
	session_start();
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
	
	$rank = $_POST['rank']; //$_REQUEST['rank'];

	$db = mysql_connect ($hostname, $username, $password) or die ('Failed to connect to database: ' . mysql_error());
	mysql_select_db($database);
	
	$query = "UPDATE $member_table SET name = '" . mysql_real_escape_string($_POST['name']) . "', rank = '" . mysql_real_escape_string($rank) . "' WHERE CONVERT(authid using utf8) = '" . mysql_real_escape_string($_POST['auth']) . "'";
	mysql_query($query) or die("Query failed: " . mysql_error());
		
	mysql_close($db);
		
	echo 'Member updated.';
?>
<br><br>
<a href="main.php">Main Page </a><br>
<br>
(c) Hawk552, 2006
</body>
</html>