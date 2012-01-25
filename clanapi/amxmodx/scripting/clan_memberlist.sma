#include <amxmodx>
#include <amxmisc>
#include <clanapi>

public plugin_init()
{
	new szVersion[10]
	clan_get_version(szVersion,9)
	register_plugin("Clan API - Member List",szVersion,AUTHOR)
	
	register_cvar("clan_memberlist_advert","300")
	set_task(get_cvar_float("clan_memberlist_advert"),"fnAdvert")
	
	register_clcmd("say","fnCmdSay")
	register_clcmd("say_team","fnCmdSay")
	
	register_clcmd("amx_members","fnShowMembers")
}

public fnCmdSay(id)
{
	static szArgs[128]
	read_args(szArgs,127)
	
	if(containi(szArgs,"/members") != -1 && clan_connected())
		fnShowMembers(id)
	
	if(containi(szArgs,"clan") != -1 || containi(szArgs,"member") != -1)
		fnAdvert(id)
}

public fnAdvert(id)
	if(clan_connected())
		client_print(id,print_chat,"[CLAN] Say /members to see clan members.")

public fnShowMembers(id)
{
	static szName[33], iRank, szAuthid[36], iMembers, szMotd[3072]
	new iPos
	iMembers = clan_get_membersnum()
	
	#if defined HTML_MOTD
	iPos += format(szMotd[iPos],1023-iPos,"<body bgcolor=^"#000000^"><font size=^"+3^" color=^"#FFFFFF^"><strong>Clan Members</strong></font><br>")
	#else
	iPos += format(szMotd[iPos],1023-iPos,"Clan Members^n")
	#endif
	
	// We want to skip rank "None", so we end at > 0.
	// Also, because we want to show Leaders first, we start at the
	// top and decrement.
	for(new iCount = RANKS - 1;iCount > 0;iCount--)
	{
		#if defined HTML_MOTD
		iPos += format(szMotd[iPos],3071-iPos,"<br><font color=^"#FFFFFF^"><strong>%ss</strong></font><br><br>",g_szRanks[iCount])
		#else
		iPos += format(szMotd[iPos],3071-iPos,"^n%ss^n^n",g_szRanks[iCount])
		#endif
		
		for(new iCount2 = 0;iCount2 <= iMembers;iCount2++)
		{
			clan_get_user_info(iCount2,szAuthid,35,szName,32)
			iRank = clan_get_user_rank(_,szAuthid)
			if(iRank == iCount)
				#if defined HTML_MOTD
				iPos += format(szMotd[iPos],3071-iPos,"<font color=^"#FFFFFF^">%s</font><br>",szName)
				#else
				iPos += format(szMotd[iPos],3071-iPos,"%s^n",szName)
				#endif
		}
	}
	
	show_motd(id,szMotd,"Clan Members")
}
