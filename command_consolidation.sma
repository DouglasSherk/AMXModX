#include <amxmodx>
#include <amxmisc>

/*

Copyleft 2006
Plugin thread: http://www.amxmodx.org/forums/viewtopic.php?p=141852

COMMAND CONSOLIDATION
=====================

Description
This plugin is allows you to change multiple cvars all at once.

Commands
amx_voice (voicecodec) (voicequality) (alltalk) - sets voice to
parameters. To not change a cvar, use the parameter _ (underscore)

amx_maptime (timelimit) (maxrounds) (winlimit) - sets time/map related
settings to parameters. To not change a cvar, use the parameter _ (underscore)

amx_round (freezetime) (roundtime) (startmoney) - sets voice to
parameters. To not change a cvar, use the parameter _ (underscore)

amx_teamkill (autokick) (hostagepenalty) (tkpunish) - sets voice to
parameters. To not change a cvar, use the parameter _ (underscore)

Example: amx_teamkill 1 _ 1
	- Will set mp_autokick to 1, leave mp_hostagepenalty, and set
	mp_tkpunish to 1.

Credits
tm - original inspiration and base plugin 

Changelog:

	Aug 6, 2005 - v1.0 - Release
	Jun 8, 2006 - v1.1 - Cleaned up code, made more useful

*/

public plugin_init()
{
	register_plugin("Command Consolidation","1.1","Hawk552")
	register_concmd("amx_voice","fnVoice",ADMIN_CVAR," <voicecodec> <quality> <alltalk> - Sets voice commands")
	register_concmd("amx_maptime","fnMaptime",ADMIN_CVAR," <timelimit> <maxrounds> <winlimit> - Sets map limits")
	register_concmd("amx_round","fnRound",ADMIN_CVAR," <freezetime> <roundtime> <startmoney> - Sets gameplay settings")
	register_concmd("amx_teamkill","fnTeamkill",ADMIN_CVAR," <autokick> <hostagepenalty> <tkpunish> - Sets teamkill settings")
} 

public fnTeamkill(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
	
	new szArg[5]
	
	//autokick settings
	read_argv(1,szArg,4)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("mp_autokick",str_to_num(szArg))
	
	//hostagepenalty settings
	read_argv(2,szArg,4)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("mp_hostagepenalty",str_to_num(szArg))
	
	//tkpunish settings
	read_argv(3,szArg,4)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("mp_tkpunish",str_to_num(szArg))
	
	return PLUGIN_HANDLED
} 

public fnRound(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
	
	new szArg[8]
	
	//freezetime settings
	read_argv(1,szArg,7)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("mp_freezetime",str_to_num(szArg))
	
	//roundtime settings
	read_argv(2,szArg,7)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("mp_roundtime",str_to_num(szArg))
	
	//startmoney settings
	read_argv(3,szArg,7)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("mp_startmoney",str_to_num(szArg))
	
	return PLUGIN_HANDLED
} 

public fnVoice(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
	
	//codec settings
	new szArg[8]
	read_argv(1,szArg,11)
	if(containi(szArg,"miles") != -1)
		set_cvar_string("sv_voicecodec","voice_miles")
	else if(containi(szArg,"speex") != -1)
		set_cvar_string("sv_voicecodec","voice_miles")
	
	//quality settings
	read_argv(2,szArg,7)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("sv_voicequality",str_to_num(szArg))
	
	//alltalk settings
	read_argv(3,szArg,7)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("sv_alltalk",str_to_num(szArg))
	
	return PLUGIN_HANDLED
} 

public fnMaptime(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
	
	new szArg[5]
	
	//timelimit settings
	read_argv(1,szArg,4)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("mp_timelimit",str_to_num(szArg))
	
	//roundlimit settings
	read_argv(2,szArg,4)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("mp_maxrounds",str_to_num(szArg))
	
	//alltalk settings
	read_argv(3,szArg,4)
	if(szArg[0] != '_' && szArg[0])
		set_cvar_num("mp_winlimit",str_to_num(szArg))
	
	return PLUGIN_HANDLED
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
