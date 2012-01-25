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
	
	$db = mysql_connect ($hostname, $username, $password) or die ('Failed to connect to database: ' . mysql_error());
	mysql_select_db ($database);
	
	$query = "SELECT * FROM $member_table WHERE authid='" . $_REQUEST['auth'] . "'";
	$result = mysql_query($query) or die ("Cannot query table " . mysql_error());
	
	$row = mysql_fetch_assoc($result);
	
	$auth = $row['authid'];
	$rank = $row['rank'];
	$name = $row['name'];
	
	mysql_free_result($result);
	mysql_close($db);
	
	echo "<form action=\"member_update.php\" method=\"post\">";
	echo "Auth ID: <input name=\"auth\" type=\"text\" value=\"$auth\"><br>";
	echo "Name: <input name=\"name\" type=\"text\" value=\"$name\"><br>";
	echo "Rank:<br>";
	//echo "Rank: <input name\"rank\" type=\"text\" value=\"$rank\"><br>";
	
	$size = sizeof($ranks) - 1;
	echo "<p>";
	for($count = $size;$count > 0;$count--)
	{
		echo "<label>";
		echo "<input type=\"radio\" name=\"rank\" value=\"$count\"";
		if($rank == $count)
		{
			echo " checked";
		}
		echo ">$ranks[$count]</label><br>";
	}
	echo "<br><input type=\"submit\" value=\"Update Member\"><br></form>";
?>
<br><br>
<a href="main.php">Main Page </a><br>
<br>
(c) Hawk552, 2006
</body>
</html>
