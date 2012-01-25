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
	if(!isset($_SESSION['clan_id']))
	{
		die("You are not logged in and cannot view this page.");
	}
	
	echo "Are you sure you want to delete:<br>";
	$auth = $_REQUEST['auth'];
	echo $auth;
	echo "<br><br><a href=\"deleteconfirmed.php?auth=$auth\">Yes</a>"
?>
</body>
<br><br>
<a href="main.php">Main Page</a><br>
<br>
(c) Hawk552, 2006
</html>
