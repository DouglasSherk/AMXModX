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
	
	if(!isset($_SESSION['clan_id']))
	{
		die("You are not logged in and cannot view this page.");
	}

	$db = mysql_connect ($hostname, $username, $password) or die ('I cannot connect to the database because: ' . mysql_error());
	mysql_select_db($database);
		
	$query = "DELETE from $member_table WHERE CONVERT(authid using utf8)='" . $_REQUEST['auth'] . "'";
	mysql_query($query) or die("Query failed " . mysql_error());
		
	mysql_close($db);
		
	echo 'Member deleted.';
?>
<br><br>
<a href="main.php">Main Page</a><br>
<br>
(c) Hawk552, 2006
</body>
</html>
