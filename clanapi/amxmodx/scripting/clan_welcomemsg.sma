#include <amxmodx>
#include <amxmisc>
#include <clanapi>

new bool:g_bSpawned[33]

public plugin_init()
{
	new szVersion[10]
	clan_get_version(szVersion,9)
	register_plugin("Clan API - Welcome Msg",szVersion,AUTHOR)

	register_event("ResetHUD","fnEventResetHUD","be")
}

public clan_member_join(id)
{
	if(!id || !clan_connected())
		return PLUGIN_CONTINUE
	
	static szName[33]
	get_user_name(id,szName,32)
	
	set_hudmessage(0, 225, 0, 0.05, 0.45, 0, 6.0, 6.0, 0.5, 0.15, -1)
	show_hudmessage(0,"Clan member %s, rank %s, has joined.",szName,g_szRanks[clan_get_user_rank(id)])
	
	return PLUGIN_CONTINUE
}

public fnEventResetHUD(id)
{
	if(!id || g_bSpawned[id] || !clan_connected())
		return PLUGIN_CONTINUE
		
	g_bSpawned[id] = true
	
	static szClanName[33]
	clan_get_name(szClanName,32)
	client_print(id,print_chat,"[CLAN] This server is running Clan API by Doug ^"Hawk552^".")
	if(clan_get_user_rank(id))
		client_print(id,print_chat,"[CLAN] You are on your clan's ( %s ) server. You are currently a %s.",szClanName,g_szRanks[clan_get_user_rank(id)])
	else
		client_print(id,print_chat,"[CLAN] You are playing on clan %s's server.",szClanName)
	
	return PLUGIN_CONTINUE
}

public clan_member_leave(id)
{
	if(!id || !clan_connected())
		return PLUGIN_CONTINUE
	
	static szName[33]
	get_user_name(id,szName,32)
	
	set_hudmessage(0, 225, 0, 0.05, 0.45, 0, 6.0, 6.0, 0.5, 0.15, -1)
	show_hudmessage(0,"Clan member %s, rank %s, has left.",szName,g_szRanks[clan_get_user_rank(id)])
	
	g_bSpawned[id] = false
	
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
	g_bSpawned[id] = false
