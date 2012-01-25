<?php
	include 'config.php';
	
	print("Attempting to connect to database.<br>");	
	
	$db = mysql_connect($hostname,$username,$password);
	if(!$db)
	{
		die("ERROR: Could not connect to host.<br>");
	}
	else
	{
		print("Connected to database.<br>");
	}
	
	mysql_select_db($database,$db);
	
	print("Attempting to create table $webinterface_table.<br>");
	
	$result = mysql_query("CREATE TABLE $webinterface_table (username varchar(32), password varchar(32), access int(2))",$db);
	if(!$result)
	{
		die("ERROR: Could not create table $webinterface_table.<br>");
	}
	else
	{
		print("Created table $webinterface_table.<br>");
	}
	// for some reason it keeps throwing some stupid error about this not being a valid MySQL resource,
	// probably because you can't do anything with a CREATE TABLE.
	
	$result = mysql_query("SELECT * FROM $member_table");
	if(!$result)
	{
		print("WARNING: Could not find the member table $member_table. (plugin will create this)<br>");
	}
	else
	{
		print("Found members table ($member_table).<br>");
	}
	
	mysql_free_result($result);
	
	print("Attempting to insert master account into database.<br>");
	$result = mysql_query("INSERT INTO $webinterface_table (username,password,access) VALUES ('$master_username','$master_password','2')");
	if(!$result)
	{
		die("ERROR: Could not create master account.<br>" . mysql_error($db));
	}
	else
	{
		print("Master account created.<br>");
	}
	
	print("<br>Setup complete. Please delete this file.");
	
	mysql_close($db);
?>