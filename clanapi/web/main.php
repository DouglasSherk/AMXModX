<?php
	session_start();
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
<b>Add member:</b><br>
<form action="member_add.php" method="post">
Auth: <input name="auth" type="text"><br>
Name: <input name="name" type="text"><br>
Rank:
   <p>
	<label>
	<input type="radio" name="rank" value="4">
    Leader</label>
    <br>
    <label>
    <input type="radio" name="rank" value="3">
    Co-Leader</label>
    <br>
    <label>
    <input type="radio" name="rank" value="2">
    Member</label>
    <br>
    <label>
    <input type="radio" name="rank" value="1">
    Recruit</label>
    <br>
  </p>
<input type="submit" value="Add Member"><br>
</form>

<?php
	include 'config.php';
	include 'access.php';
	
	$db = mysql_connect ($hostname, $username, $password) or die ('Failed to connect to database: ' . mysql_error());
	mysql_select_db($database);
	
	$query = "SELECT * FROM $member_table";
	$result = mysql_query($query) or die ('Failed to query ' . mysql_error());
?>

<table width="100%" border="0" cellspacing="5" cellpadding="10">
<tr>
<td width="100%" colspan="5" bgcolor="#00CCFF"><strong>Members</strong></td>
</tr>
<tr>
<td width="25%" bgcolor="#EAEAEA"><strong>Auth ID</strong></td>
<td width="25%" bgcolor="#EAEAEA"><strong>Rank</strong></td>
<td width="25%" bgcolor="#EAEAEA"><strong>Name</strong></td>
<td width="25%" bgcolor="#EAEAEA"><strong>Control</strong></td>
</tr>

<?php
	while ($row = mysql_fetch_assoc($result)) 
	{
		echo "<tr>";
		$auth = $row['authid'];
		echo "<td width=\"20%\" bgcolor=\"#EAEAEA\"><strong>$auth</strong></td>";
		$rank = $ranks[$row['rank']];
		echo "<td width=\"20%\" bgcolor=\"#EAEAEA\"><strong>$rank</strong></td>";
		$name = $row['name'];
		echo "<td width=\"20%\" bgcolor=\"#EAEAEA\"><strong>$name</strong></td>";
		echo "<td width=\"20%\" bgcolor=\"#EAEAEA\"><form action=\"edit.php?auth=$auth\" method=\"post\"><input type=\"submit\" value=\"Edit\"></form> <form action=\"delete.php?auth=$auth\" method=\"post\"><input type=\"submit\" value=\"Delete\"></form></td>";
		echo "</tr>";
	}
	
	echo "</table>";

	mysql_free_result($result);
	mysql_close($db);
?>
<br><br>
<a href="main.php">Main Page </a><br>
<br>
(c) Hawk552, 2006 
</body>
</html>
