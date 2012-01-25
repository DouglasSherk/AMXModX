#include <amxmodx>
#include <amxmisc>
#include <clanapi>

#define ALLOWED LEADER

#define MAIN_MENU_OPTIONS 3

new g_szMainMenuOptions[MAIN_MENU_OPTIONS][] =
{
	"Add Member",
	"Promote / Demote Member",
	"Delete Member"
}

new g_szMainMenu[] = "mMemberMain"
new g_szAddMenu[] = "mMemberAdd"
new g_szModMenu[] = "mMemberMod"
new g_szDeleteMenu[] = "mMemberDelete"
new const g_iKeys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9

new g_iMenuPosition[33]
new g_iAddMode[33] = {1,...}

new g_iPlayers[32]

public plugin_init()
{
	new szVersion[10]
	clan_get_version(szVersion,9)
	register_plugin("Clan API - Member Management",szVersion,AUTHOR)
	
	register_clcmd("clan_members","fnCmdClanMembers")
	
	register_menucmd(register_menuid(g_szMainMenu),g_iKeys,"fnMainMenuHandle")
	register_menucmd(register_menuid(g_szAddMenu),g_iKeys,"fnAddMenuHandle")
	register_menucmd(register_menuid(g_szModMenu),g_iKeys,"fnModMenuHandle")
	register_menucmd(register_menuid(g_szDeleteMenu),g_iKeys,"fnDeleteMenuHandle")
}

public fnCmdClanMembers(id)
{
	if(clan_get_user_rank(id) != LEADER && clan_get_user_rank(id) != COLEADER)
		return client_print(id,print_chat,"[CLAN] You do not have access to this command.")
	else if(!clan_connected())
		return PLUGIN_CONTINUE
	
	static szMenu[512]
	new iPos
	
	iPos += format(szMenu[iPos],511-iPos,"Clan Member Menu^n^n")
	for(new iCount = 0;iCount < MAIN_MENU_OPTIONS;iCount++)
		iPos += format(szMenu[iPos],511-iPos,"%i. %s^n",iCount + 1,g_szMainMenuOptions[iCount])
	iPos += format(szMenu[iPos],511-iPos,"^n^n0. Exit")
		
	return show_menu(id,g_iKeys,szMenu,_,g_szMainMenu)
}

public fnMainMenuHandle(id,iKey)
{
	g_iMenuPosition[id] = 0
	
	switch(iKey)
	{
		case 0 :
			fnAddMemberMenu(id)
		case 1 :
			fnModMemberMenu(id)
		case 2 :
			fnDelMemberMenu(id)
		default :
			if(iKey != 9)
				fnCmdClanMembers(id)
	}
}
	
public fnAddMemberMenu(id)
{	
	static iPlayersnum,iPlayer,szName[33],szMenu[512]
	new iPos,iNum
	get_players(g_iPlayers,iPlayersnum)
	
	iPos += format(szMenu[iPos],511-iPos,"Clan Add Member^n^n")
	for(new iCount = g_iMenuPosition[id] * 6;iCount < (g_iMenuPosition[id] * 6) + 6;iCount++)
	{
		if(iCount >= iPlayersnum)
			break
			
		iPlayer = g_iPlayers[iCount]
		get_user_name(iPlayer,szName,32)
		
		iPos += format(szMenu[iPos],511-iPos,"%i. %s^n",++iNum,szName)
	}	
	iPos += format(szMenu[iPos],511-iPos,"^n7. Add as %s^n",g_szRanks[g_iAddMode[id]])
	iPos += format(szMenu[iPos],511-iPos,"^n8. Back^n9. Next^n^n0. Exit")
	
	return show_menu(id,g_iKeys,szMenu,_,g_szAddMenu)
}

public fnAddMenuHandle(id,iKey)
{
	switch(iKey)
	{
		case 6:
		{
			if(g_iAddMode[id] >= RANKS - 1)
				g_iAddMode[id] = 1
			else
				g_iAddMode[id]++
				
			fnAddMemberMenu(id)
		}
		case 7:
		{
			if(g_iMenuPosition[id] > 0)
				g_iMenuPosition[id]--
			
			fnAddMemberMenu(id)
		}
		case 8:
		{
			if((g_iMenuPosition[id] * 6) - 5 < get_playersnum())
				g_iMenuPosition[id]++
				
			fnAddMemberMenu(id)
		}
		default :
			if(iKey != 9)
			{
				if(g_iAddMode[id] > clan_get_user_rank(id))
					return client_print(id,print_chat,"[CLAN] You cannot add someone as a higher rank than you.")
				
				new iPlayer = g_iPlayers[(g_iMenuPosition[id] * 6) + iKey]
				
				if(get_playersnum() < (g_iMenuPosition[id] * 6) + iKey || clan_get_user_rank(iPlayer)) 
					return fnAddMemberMenu(id)
				
				static szAuthid[36],szName[33]
				get_user_authid(iPlayer,szAuthid,35)
				get_user_name(iPlayer,szName,32)
				
				clan_add_member(szAuthid,g_iAddMode[id],szName)
				
				client_print(id,print_chat,"[CLAN] Member added.")
				client_print(iPlayer,print_chat,"[CLAN] You have been added to the clan as a %s.",g_szRanks[g_iAddMode[id]])
				
				set_task(0.5,"fnReload")
			}
	}
	
	return PLUGIN_CONTINUE
}
	
public fnDelMemberMenu(id)
{
	new iPos,iNum,iMembersNum = clan_get_membersnum(),iCount
	static szMenu[512],szAuthid[36],szName[33]
	
	iPos += format(szMenu[iPos],511-iPos,"Clan Delete Member^n^n")
	for(iCount = g_iMenuPosition[id] * 7;iCount < (g_iMenuPosition[id] * 7) + 7;iCount++)
	{		
		if(iCount >= iMembersNum)
			break
			
		clan_get_user_info(iCount,szAuthid,35,szName,32)
		iPos += format(szMenu[iPos],511-iPos,"%i. %s^n",++iNum,szName)
	}
	iPos += format(szMenu[iPos],511-iPos,"^n^n8. Back^n9. Next^n^n0. Exit")
	
	if(iCount == g_iMenuPosition[id] * 7)
	{
		g_iMenuPosition[id]--
		return fnDelMemberMenu(id)
	}
	
	return show_menu(id,g_iKeys,szMenu,-1,g_szDeleteMenu)
}

public fnDeleteMenuHandle(id,iKey)
{
	switch(iKey)
	{
		case 7:
		{
			if(g_iMenuPosition[id] > 0)
				g_iMenuPosition[id]--
			
			fnDelMemberMenu(id)
		}
		case 8:
		{
			if(((g_iMenuPosition[id] + 1) * 7) - 6 < clan_get_membersnum())
				g_iMenuPosition[id]++
				
			fnDelMemberMenu(id)
		}
		case 9:
			return PLUGIN_CONTINUE
		default :
		{
			new szName[33],szAuthid[36]
			clan_get_user_info(g_iMenuPosition[id] * 7 + iKey,szAuthid,35,szName,32)
			
			if(clan_get_user_rank(_,szAuthid) >= clan_get_user_rank(id))
				return client_print(id,print_chat,"[CLAN] This member's rank is greater than or equal to yours.")
			
			clan_del_member(_,szName)
			
			client_print(id,print_chat,"[CLAN] Member deleted.")
			
			set_task(0.5,"fnReload")
		}
	}

	return PLUGIN_CONTINUE
}

public fnModMemberMenu(id)
{
	new iPos,iNum,iMembersNum = clan_get_membersnum(),iCount
	static szMenu[512],szAuthid[36],szName[33]
	
	iPos += format(szMenu[iPos],511-iPos,"Clan Promote / Demote Member^n^n")
	for(iCount = g_iMenuPosition[id] * 6;iCount < (g_iMenuPosition[id] * 6) + 6;iCount++)
	{		
		if(iCount >= iMembersNum)
			break
			
		clan_get_user_info(iCount,szAuthid,35,szName,32)
		iPos += format(szMenu[iPos],511-iPos,"%i. %s^n",++iNum,szName)
	}
	iPos += format(szMenu[iPos],511-iPos,"^n7. Set as %s^n",g_szRanks[g_iAddMode[id]])
	iPos += format(szMenu[iPos],511-iPos,"^n^n8. Back^n9. Next^n^n0. Exit")
	
	if(iCount == g_iMenuPosition[id] * 7)
	{
		g_iMenuPosition[id]--
		return fnModMemberMenu(id)
	}
	
	return show_menu(id,g_iKeys,szMenu,-1,g_szModMenu)
}

public fnModMenuHandle(id,iKey)
{
	switch(iKey)
	{
		case 6:
		{
			if(g_iAddMode[id] >= RANKS - 1)
				g_iAddMode[id] = 1
			else
				g_iAddMode[id]++
				
			fnModMemberMenu(id)
		}
		case 7:
		{
			if(g_iMenuPosition[id] > 0)
				g_iMenuPosition[id]--
			
			fnModMemberMenu(id)
		}
		case 8:
		{
			if(((g_iMenuPosition[id] + 1) * 6) - 5 < clan_get_membersnum())
				g_iMenuPosition[id]++
				
			fnModMemberMenu(id)
		}
		default :
		{
			if(iKey != 9)
			{
				new iPlayer = (g_iMenuPosition[id] * 6) + iKey		
				static szAuthid[36],szName[33]
			
				clan_get_user_info(iPlayer,szAuthid,35,szName,32)
			
				if(clan_get_user_rank(id) <= clan_get_user_rank(_,szAuthid))
					return client_print(id,print_chat,"[CLAN] You cannot modify someone whos rank is greater than or equal to yours.")
				else if(g_iAddMode[id] >= clan_get_user_rank(id))
					return client_print(id,print_chat,"[CLAN] You cannot modify someone to set them to a higher/equal level to you.")
			
				clan_mod_member(szAuthid,g_iAddMode[id],szName)
			
				client_print(id,print_chat,"[CLAN] Member set.")
			}
		}
	}
	
	return PLUGIN_CONTINUE
}

public fnReload()
	clan_reload()
