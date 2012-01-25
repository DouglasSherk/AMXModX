<?php
	session_start();
?>

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
	
	session_destroy();
	
	echo "You have been logged out.";
?>
</body>
</html>
