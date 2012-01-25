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
	
	$db = mysql_connect ($hostname, $username, $password) or die ('Failed to connect to database: ' . mysql_error());
	mysql_select_db ($database);
	
	$query = "SELECT * FROM $webinterface_table WHERE username='" . mysql_real_escape_string($_REQUEST['user']) . "'";
	$result = mysql_query($query) or die ("Cannot query table " . mysql_error());
	
	$row = mysql_fetch_assoc($result);
	
	$user = $row['username'];
	$pass = ""; //$row['password']; // we probably don't want to display this
	$access_t = $row['access'];
	
	if($access_t >= $_SESSION['clan_access'])
	{
		die("You cannot edit someone's account whos access is equal to or greater than yours.");
	}
	
	mysql_free_result($result);
	mysql_close($db);
	
	echo "<form action=\"web_update.php\" method=\"post\">";
	echo "Username: <input name=\"user\" type=\"text\" value=\"$user\"><br>";
	echo "Password: <input name=\"pass\" type=\"password\" value=\"$pass\"><br>";
	echo "NOTE: Leave password blank and it will not be changed.<br>";
	//echo "Rank: <input name\"rank\" type=\"text\" value=\"$rank\"><br>";
	
	$size = sizeof($access) - 1;
	echo "<p>";
	for($count = $size;$count > 0;$count--)
	{
		echo "<label>";
		echo "<input type=\"radio\" name=\"access\" value=\"$count\"";
		if($access_t == $count)
		{
			echo " checked";
		}
		echo ">$access[$count]</label><br>";
	}

	echo "</p><input type=\"submit\" value=\"Update Member\"><br></form>";
?>
<br><br>
<a href="webadmins.php">Main Page </a><br>
<br>
(c) Hawk552, 2006
</body>
</html>
