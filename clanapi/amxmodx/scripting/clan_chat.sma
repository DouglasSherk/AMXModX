#include <amxmodx>
#include <amxmisc>
#include <clanapi>

// Defines whether or not the message should be green
#define GREEN_MESSAGE

new g_iMsgSayText

public plugin_init()
{
	new szVersion[10]
	clan_get_version(szVersion,9)
	register_plugin("Clan API - Clan Chat",szVersion,AUTHOR)
	
	register_concmd("amx_clanchat","fnCmdClanChat")
	
	register_clcmd("say","fnCmdSay")
	register_clcmd("say_team","fnCmdSay")
	
	g_iMsgSayText = get_user_msgid("SayText")
}

public fnCmdSay(id)
{
	static szArgs[256]
	read_args(szArgs,255)
	
	remove_quotes(szArgs)
	trim(szArgs)
	
	if(szArgs[0] == '#')
	{
		replace(szArgs,255,"#","")
		client_cmd(id,"amx_clanchat ^"%s^"",szArgs)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public fnCmdClanChat(id)
{
	static szArgs[512],szName[33],iPlayers[32],iPlayersnum,iPlayer
	read_args(szArgs,511)
	remove_quotes(szArgs)
	get_user_name(id,szName,32)
	
	#if defined GREEN_MESSAGE
	format(szArgs,511,"^x04 (CLAN) %s :  %s",szName,szArgs)
	#else
	format(szArgs,511,"(CLAN) %s :  %s",szName,szArgs)
	#endif
	
	get_players(iPlayers,iPlayersnum)
	for(new iCount = 0;iCount < iPlayersnum;iCount++)
	{
		iPlayer = iPlayers[iCount]
		if(clan_get_user_rank(iPlayer))
			#if defined GREEN_MESSAGE
			fnSendMessage(szArgs,iPlayer)
			#else
			client_print(iPlayer,print_chat,"%s",szArgs)
			#endif
	}
}

#if defined GREEN_MESSAGE
fnSendMessage(szMessage[],iRecieverID)
{
	message_begin(MSG_ONE, g_iMsgSayText, {0,0,0}, iRecieverID)
	write_byte(iRecieverID)
	write_string(szMessage)
	message_end()
}
#endif
