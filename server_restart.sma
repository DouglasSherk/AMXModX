#include <amxmodx>
#include <amxmisc>

/*

Copyleft 2006
Plugin thread: http://amxmodx.org/forums/viewtopic.php?p=211244

SERVER RESTART
==============

Description
This plugin is basically an extension of mysticssjgoku4's server shutdown,
which is very limited and hardcoded (although it does work). 
It also logs when admins use it, and displays messages according to 
your amx_show_activity cvar.

Commands
amx_restart (seconds 1-20) - will restart the server in (seconds), 
counting down along the way. Serverdoc or any autorestarting tool 
is not needed for this, it will restart on it's own. 
Clients will also reconnect.

amx_shutdown (seconds 1-20) - will shut down the server in (seconds),
counting down along the way. This will shut the server down entirely
unless you have serverdoc or another autorestarting tool. Clients 
will not reconnect.

Credits
mysticssjgoku4 for the original idea.

Changelog:

	Feb 1, 2006 - v2.0 - Release
	Feb 2, 2006 - v2.0 RC1 - Some fixes for Restart not working
	Feb 2, 2006 - v2.1 - Cut code down slightly, changed voice to fvox
	Jun 8, 2006 - v2.2 - Changed restart command to "reload", conformed to newer coding standards

*/

enum
{
	SHUTDOWN = 0,
	RESTART
}

new g_bShuttingDown
new g_iMode

public plugin_init()
{
	register_plugin("Server Shutdown","2.2","Hawk552")
	
	register_concmd("amx_shutdown","fnShutDown",ADMIN_RCON,"<seconds (1-20)> - shuts down the server in seconds")
	register_concmd("amx_restart","fnShutDown",ADMIN_RCON,"<seconds (1-20)> - restarts the server in seconds")
}

public fnShutDown(id,level,cid)
{
	if(!cmd_access(id,level,cid,2) || g_bShuttingDown)
		return PLUGIN_HANDLED
		
	new szArg[6]
	read_argv(0,szArg,5)
	
	// Because SHUTDOWN = 0, we can assume that if it's not
	// amx_restart, then it must be SHUTDOWN. 
	if(equali(szArg,"amx_r"))
		g_iMode = RESTART
		
	read_argv(1,szArg,5)
	new iTime = str_to_num(szArg)
	
	if(!iTime || iTime > 20)
	{
		console_print(id,"You did not supply a valid time (between 1-20 seconds)")
		
		return PLUGIN_HANDLED
	}
	
	new szName[32]
	get_user_name(id,szName,31)
	
	new szAuthid[32]
	get_user_authid(id,szAuthid,31)
	
	log_amx("Cmd: ^"%s<%i><%s>^" initiate %s",szName,id,szAuthid,g_iMode ? "restart" : "shutdown")
	
	switch(get_cvar_num("amx_show_activity"))
	{
		case 1 : client_print(0,print_chat,"ADMIN: %s server in %i seconds",g_iMode ? "Restart" : "Shutdown",iTime)
		case 2 : client_print(0,print_chat,"ADMIN %s: %s server in %i seconds",szName,g_iMode ? "Restart" : "Shutdown",iTime)
	}
	
	fnInitiate(iTime)
	
	return PLUGIN_HANDLED
}

public fnInitiate(iTime)
{
	g_bShuttingDown = true
	
	new iCount
	for(iCount = iTime;iCount != 0;iCount--)
		set_task(float(abs(iCount-iTime)),"fnCallTime",iCount)
	
	set_task(float(iTime),"fnCallTime",0)
}

public fnCallTime(iCount)
{
	if(!iCount)
	{
		switch(g_iMode)
		{
			case SHUTDOWN :
				server_cmd("quit")
			
			case RESTART :
				server_cmd("reload")
		}
	}
	
	new szWord[32]
	num_to_word(iCount,szWord,31)
	
	client_cmd(0,"spk ^"fvox/%s^"",szWord)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
