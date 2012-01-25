#include <amxmodx>
#include <amxmisc>
// NOTE: You do not need cstrike, it'll run without it
#include <cstrike>
#include <fun>

/*

Copyleft 2006
Plugin thread: http://forums.alliedmods.net/showthread.php?t=16328

LICENSE TO KILL
===============

Description
This plugin is allows you to set spawn HP.

Commands
amx_ltk_on (hp) (ap) - turns LTK mode on with (hp) health.and (ap) armor.
amx_ltk_off - turns LTK mode off.

CVAR - amx_ltk_hp (hp) - sets LTK hp.
CVAR - amx_ltk_ap (ap) - sets LTK ap.

Credits
TyrantBoss - my old clan leader who got me to do this.

Changelog:

	Aug 9, 2005 - v1.0 - Release
	Jun 8, 2006 - v1.1 - Cleaned up code, made more useful
	Jul 7, 2006 - v1.2 - Added armor functionality
	Jul 9, 2006 - v1.3 - Fixed armor in cstrike
	Dec 29, 2006 - v1.4 - Fixed invalid player in cs_get_user_armor
	
*/

new g_pHealth
new g_pArmor

new bool:g_bCstrike

public plugin_init()
{
	register_plugin("License To Kill","1.4","Hawk552")
	
	g_pHealth = register_cvar("amx_ltk_hp","0")
	g_pArmor = register_cvar("amx_ltk_ap","0")
	
	register_event("ResetHUD","fnEventResetHUD", "b")
	
	register_clcmd("amx_ltk_on","fnLtk",ADMIN_CVAR," <hp> <ap> - turns on LTK mode with defined HP and AP")
	register_clcmd("amx_ltk_off","fnLtk",ADMIN_CVAR," - turns LTK mode off")
	
	#if AMXX_VERSION_NUM >= 175
	if(LibraryExists("cstrike",LibType_Library))
	#else
	if(module_exists("cstrike"))
	#endif
		g_bCstrike = true
}

public plugin_natives()
	set_module_filter("fnModuleFilter")

public fnModuleFilter(const szModule[])
{
	if(equali(szModule,"cstrike"))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public fnLtk(id,level,cid)
{
	new iArgs = read_argc()
	if(!access(id,level) || (iArgs != 3 && iArgs != 2 && iArgs != 1))
		return PLUGIN_HANDLED
	
	new szArg[12],iPlayers[32],iPlayersnum,iHealth,iArmor,szName[33],szAuthid[36],CsArmorType:csaArmorType
	
	read_argv(1,szArg,11)
	iHealth = str_to_num(szArg)
	set_pcvar_num(g_pHealth,iHealth)
	
	read_argv(2,szArg,11)
	iArmor = str_to_num(szArg)
	set_pcvar_num(g_pArmor,iArmor)
	
	get_user_name(id,szName,32)
	get_user_authid(id,szAuthid,35)
	
	log_amx("Cmd: ^"%s<%i><%s>^" set LTK to %i/%i",szName,id,szAuthid,iHealth,iArmor)
	
	switch(get_cvar_num("amx_show_activity"))
	{
		case 1 : 
			client_print(0,print_chat,"ADMIN: Set LTK mode to %i health and %i armor",iHealth,iArmor)
		case 2 : 
			client_print(0,print_chat,"ADMIN %s: Set LTK mode to %i health and %i armor",szName,iHealth,iArmor)
	}
	
	get_players(iPlayers,iPlayersnum,"ac")
	for(new iCount = 0;iCount < iPlayersnum;iCount++)
	{
		if(iHealth > 0)
			set_user_health(iPlayers[iCount],iHealth)
		else
			set_user_health(iPlayers[iCount],100)
			
		if(iArmor > -1)
			if(g_bCstrike)
			{
				if(cs_get_user_armor(id,csaArmorType) < iArmor)
					cs_set_user_armor(id,iArmor,CS_ARMOR_VESTHELM)
			}
			else
				if(get_user_armor(id) < iArmor)
					set_user_armor(id,iArmor)
	}
	
	return PLUGIN_HANDLED
}

public fnEventResetHUD(id)
	if(id && is_user_connected(id) && !is_user_bot(id))
		set_task(0.3,"fnSetHealth",id)

public fnSetHealth(id)
{
	if(!is_user_alive(id))
		return
	
	new iHealth = get_pcvar_num(g_pHealth),iArmor = get_pcvar_num(g_pArmor),CsArmorType:csaArmorType
	
	if(iHealth > 0)
		set_user_health(id,iHealth)
		
	if(iArmor > 0)
		if(g_bCstrike)
		{
			if(cs_get_user_armor(id,csaArmorType) < iArmor)
				cs_set_user_armor(id,iArmor,CS_ARMOR_VESTHELM)
		}
		else
			if(get_user_armor(id) < iArmor)
				set_user_armor(id,iArmor)
} 
