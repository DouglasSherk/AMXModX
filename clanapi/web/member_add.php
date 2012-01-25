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
	
	if(!isset($_POST['auth']) || !isset($_POST['rank']) || !isset($_POST['name']))
	{
		die("You must specify all fields.");
	}
	
	str_replace("\"","\'",$_POST['auth']);
	str_replace("\"","\'",$_POST['rank']);
	str_replace("\"","\'",$_POST['name']);

	$db = mysql_connect ($hostname, $username, $password) or die ('I cannot connect to the database because: ' . mysql_error());
	mysql_select_db($database);
		
	$query = "INSERT INTO $member_table (authid,rank,name) VALUES ('" . mysql_real_escape_string($_POST['auth']) . "','" . mysql_real_escape_string($_POST['rank']) . "','" . mysql_real_escape_string($_POST['name']) . "')";
	mysql_query($query) or die("Query failed " . mysql_error());
		
	mysql_close($db);
		
	echo 'Member added.';
?>
<br><br>
<a href="main.php">Main Page</a><br>
<br>
(c) Hawk552, 2006
</body>
</html>
