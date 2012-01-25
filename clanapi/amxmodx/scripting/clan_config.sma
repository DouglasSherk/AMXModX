#include <amxmodx>
#include <amxmisc>
#include <clanapi>
#include <sqlx>

#define MENU_OPTIONS 3
#define DB_MENU_OPTIONS 4

new g_szMenuOptions[MENU_OPTIONS][] =
{
	"Add First Member",
	"Change Database / Connect Info",
	"Change Rank Names"
}

// for some reason, these align perfectly. it's great for me ;]
new g_szDbMenuOptions[DB_MENU_OPTIONS][] =
{
	"Host",
	"User",
	"Pass",
	"DB"
}

enum
{
	HOSTNAME = 1,
	USERNAME,
	PASSWORD,
	DATABASE
}

// this will be changed if it's actually using clan_sql.ini
new g_szLocalSqlFile[64]

new g_szDbMenu[] = "mDatabaseMenu"
new g_szMainMenu[] = "mConfigMenu"
new const g_iKeys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9

new bool:g_bFirstSet

new g_iModMode[33]

public plugin_init()
{
	new szVersion[10]
	clan_get_version(szVersion,9)
	
	register_plugin("Clan API - Config",szVersion,AUTHOR)
	
	register_clcmd("clan_config","fnCmdConfig")
	
	register_clcmd("say","fnCmdSay")
	register_clcmd("say_team","fnCmdSay")
	
	register_menucmd(register_menuid(g_szMainMenu),g_iKeys,"fnHandleCmdConfig")
	register_menucmd(register_menuid(g_szDbMenu),g_iKeys,"fnHandleDbMenu")
	
	new szConfigsDir[64]
	get_configsdir(szConfigsDir,63)
	
	// I really hate hardcoding, but there's no real support for this
	// other than to just scan every directory under addons/amxmodx until
	// you find this
	if(get_cvar_num("clan_sql_config"))
		format(g_szLocalSqlFile,63,"%s/clan_sql.ini",szConfigsDir)
	else
		format(g_szLocalSqlFile,63,"%s/sql.cfg",szConfigsDir)
}

public clan_init()
	fnFirstSet()

public fnCmdConfig(id)
{	
	if(g_bFirstSet && clan_connected() && !clan_get_user_rank(id))
		return client_print(id,print_console,"You have no access to this command.")
	else if(!g_bFirstSet && get_user_flags(id) > 0 && clan_connected())
	{
		client_print(id,print_chat,"[CLAN] WARNING: Your configuration is open to intrusion by any admin.")
		client_print(id,print_chat,"Please complete the configuration and add yourself now, otherwise any admin")
		client_print(id,print_chat,"may make changes to add themselves as the leader.")
	}	
		
	static szMenu[MENU_OPTIONS * 64]
	new iPos
	
	iPos += format(szMenu,MENU_OPTIONS * 64 - 1,"Clan Config Menu^n^n")
	for(new iCount;iCount < MENU_OPTIONS;iCount++)
		iPos += format(szMenu[iPos],MENU_OPTIONS * 64 - iPos - 1,"%i. %s^n",iCount + 1,g_szMenuOptions[iCount])
	iPos += format(szMenu[iPos],MENU_OPTIONS * 64 - iPos - 1,"^n0. Exit")
	
	show_menu(id,g_iKeys,szMenu,-1,g_szMainMenu)
	
	return PLUGIN_HANDLED
}
		
public fnHandleCmdConfig(id,iKey)
	switch(iKey)
	{
		case 0 :
			fnFirstMember(id)
		case 1 :
			fnChangeDatabase(id)
		case 2 :
			fnChangeRankNames(id)
		default :
			if(iKey != 9)
				fnCmdConfig(id)
	}
	
fnFirstSet()
{
	static szQuery[512],szMemberTable[64]
	clan_get_membertable(szMemberTable,63)
	
	format(szQuery,511,"SELECT * FROM %s",szMemberTable)
	
	clan_sql_threaded_query(szQuery,"fnHandleFirstSet")
}

public fnHandleFirstSet(Handle:hQuery)
{
	if(!_:hQuery)
		return PLUGIN_CONTINUE
	
	new iNumRows = SQL_NumResults(hQuery)
	
	if(!iNumRows)
		g_bFirstSet = false
	else
		g_bFirstSet = true
		
	return PLUGIN_CONTINUE
}

fnFirstMember(id)
{
	if(g_bFirstSet || clan_get_user_rank(id))
		return client_print(id,print_chat,"[CLAN] First account is already set up.")
		
	if(!clan_connected())
		return client_print(id,print_chat,"[CLAN] Sorry, the plugin is currently not connected to the database.")
	
	static szAuthid[36],szName[33],szTag[10]
	get_user_authid(id,szAuthid,35)
	get_user_name(id,szName,32)
	
	clan_get_tag(szTag,9)
	if(szTag[0])
		while(replace(szName,32,szTag,""))
			trim(szName)
	
	clan_add_member(szAuthid,LEADER,szName)
	
	client_print(id,print_chat,"[CLAN] You have been added as the first member.")
	
	g_bFirstSet = true
	
	set_task(5.0,"fnReload")
	
	return PLUGIN_CONTINUE
}

fnChangeDatabase(id)
{
	if(clan_connected() && clan_get_user_rank(id) != LEADER)
		return client_print(id,print_chat,"[CLAN] You do not have access to this command.")
	
	if(!clan_connected())
		if(get_user_flags(id) < 1)
			return client_print(id,print_chat,"[CLAN] You do not have access to this command.")
		else
			client_print(id,print_chat,"[CLAN] WARNING: The database is currently not connected. Please change your settings.")
	
	static szMenu[DB_MENU_OPTIONS * 64],szSetting[33]
	new iPos
	
	iPos += format(szMenu,DB_MENU_OPTIONS * 64 - 1,"Clan Database Modification Menu^n^n")
	for(new iCount;iCount < DB_MENU_OPTIONS;iCount++)
	{
		fnGetSetting(iCount + 1,szSetting,32)
		iPos += format(szMenu[iPos],DB_MENU_OPTIONS * 64 - iPos - 1,"%i. %s: %s^n",iCount + 1,g_szDbMenuOptions[iCount],szSetting)
	}
	iPos += format(szMenu[iPos],MENU_OPTIONS * 64 - iPos - 1,"^n0. Exit")
	
	show_menu(id,g_iKeys,szMenu,-1,g_szDbMenu)
	
	return PLUGIN_CONTINUE
}

fnGetSetting(iSetting,szFormat[],iLen)
{
	if(!file_exists(g_szLocalSqlFile))
		return
		
	new iLine,szBuffer[64],iByrefLen,szLeft[33],szRight[33],szSearch[33]
	
	format(szSearch,32,get_cvar_num("clan_sql_config") ? "clan_sql_%s" : "amx_sql_%s",g_szDbMenuOptions[iSetting - 1])
	while(read_file(g_szLocalSqlFile,iLine++,szBuffer,63,iByrefLen))
	{
		if(containi(szBuffer,szSearch) == -1)
			continue
		
		parse(szBuffer,szLeft,32,szRight,32)
		
		remove_quotes(szRight)
		trim(szRight)
		
		copy(szFormat,iLen,szRight)
		
		break
	}
}	

fnSetSetting(iSetting,szSetting[])
{
	if(!file_exists(g_szLocalSqlFile))
		return
		
	new iLine,szBuffer[64],iByrefLen,szLeft[33],szRight[33],szSearch[33]
	
	format(szSearch,32,get_cvar_num("clan_sql_config") ? "clan_sql_%s" : "amx_sql_%s",g_szDbMenuOptions[iSetting - 1])
	
	while(read_file(g_szLocalSqlFile,iLine++,szBuffer,63,iByrefLen))
	{
		if(containi(szBuffer,szSearch) == -1)
			continue
		
		parse(szBuffer,szLeft,32,szRight,32)
		
		format(szBuffer,63,"%s ^"%s^"",szLeft,szSetting)
		
		write_file(g_szLocalSqlFile,szBuffer,iLine - 1)
		
		break
	}
}
	
public fnHandleDbMenu(id,iKey)
	if(iKey < DB_MENU_OPTIONS && iKey >= 0)
	{
		g_iModMode[id] = iKey + 1
		client_print(id,print_chat,"[CLAN] Please say (i.e. press y and type) what you would like to change this to, or say ^"cancel^" to stop.")
	}
	else if(iKey == 9)
		return
	else
		fnChangeDatabase(id)
			
fnChangeRankNames(id)
	return client_print(id,print_chat,"[CLAN] Sorry, this is currently a stub.")
	
public fnCmdSay(id)
{
	if(clan_connected())
	{
		if(clan_get_user_rank(id) != LEADER || !g_iModMode[id])
			return PLUGIN_CONTINUE
	}
	else
		if(get_user_flags(id) < 1)
			return PLUGIN_CONTINUE
		
	static szArgs[128]
	read_args(szArgs,127)
	
	remove_quotes(szArgs)
	trim(szArgs)
	
	if(equali(szArgs,"cancel"))
	{
		client_print(id,print_chat,"[CLAN] %s modification cancelled.",g_szDbMenuOptions[g_iModMode[id] - 1])
		
		g_iModMode[id] = 0
		
		return PLUGIN_HANDLED
	}
	
	while(replace(szArgs,127,"'","\'")) { }
	
	fnSetSetting(g_iModMode[id],szArgs)
	
	client_print(id,print_chat,"[CLAN] %s set, changes will take effect after map change.",g_szDbMenuOptions[g_iModMode[id] - 1])
	
	g_iModMode[id] = 0
	
	return PLUGIN_HANDLED
}

public fnReload()
	clan_reload()
