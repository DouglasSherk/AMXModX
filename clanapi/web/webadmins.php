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

<?php
	if(!isset($_SESSION['clan_id']))
	{
		die("You are not logged in and cannot view this page.");
	}
	
	include 'modeheader.php';
?>

<body>
<br><br>
<b>Add admin:</b><br>
<form action="web_add.php" method="post">
Username: <input name="user" type="text"><br>
Password: <input name="pass" type="password"><br>
Access:<br><br>
<?php
	include 'access.php';
	
	$size = sizeof($access) - 1;
	for($count = $size;$count > 0;$count--)
	{
		echo "<label>";
		echo "<input type=\"radio\" name=\"access\" value=\"$count\">";
		echo "$access[$count]</label><br>";
	}
?>
<input type="submit" value="Add Member"><br>
</form>

<?php
	include 'config.php';
	
	$db = mysql_connect ($hostname, $username, $password) or die ('Failed to connect to database: ' . mysql_error());
	mysql_select_db($database);
	
	$query = "SELECT * FROM $webinterface_table";
	$result = mysql_query($query) or die ('Failed to query ' . mysql_error());
?>

<table width="100%" border="0" cellspacing="5" cellpadding="10">
<tr>
<td width="100%" colspan="5" bgcolor="#00CCFF"><strong>Admins</strong></td>
</tr>
<tr>
<td width="33%" bgcolor="#EAEAEA"><strong>Username</strong></td>
<td width="33%" bgcolor="#EAEAEA"><strong>Rank</strong></td>
<td width="33%" bgcolor="#EAEAEA"><strong>Control</strong></td>
</tr>

<?php
	while($row = mysql_fetch_assoc($result)) 
	{
		echo "<tr>";
		$username = $row['username'];
		echo "<td width=\"33%\" bgcolor=\"#EAEAEA\"><strong>$username</strong></td>";
		$access_t = $access[$row['access']];
		echo "<td width=\"33%\" bgcolor=\"#EAEAEA\"><strong>$access_t</strong></td>";
		echo "<td width=\"33%\" bgcolor=\"#EAEAEA\"><form action=\"webedit.php?user=$username\" method=\"post\"><input type=\"submit\" value=\"Edit\"></form> <form action=\"webdelete.php?user=$username\" method=\"post\"><input type=\"submit\" value=\"Delete\"></form></td>";
		echo "</tr>";
	}
	
	echo "</table>";

	mysql_free_result($result);
	mysql_close($db);
?>
<br><br>
<a href="webadmins.php">Main Page </a><br>
<br>
(c) Hawk552, 2006 
</body>
</html>
