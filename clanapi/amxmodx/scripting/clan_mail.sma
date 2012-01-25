#include <amxmodx>
#include <amxmisc>
#include <clanapi>
#include <sqlx>

// CONFIGURE THESE TO YOUR LIKING

// Note, do not increase this as there is no multi-paging system
// yet. You can decrease it however to whatever you want.
#define MAX_MAIL 9

// DO NOT CHANGE ANYTHING BEYOND HERE

#define MAIN_MENU_OPTIONS 3

new g_iCurId
new g_szTable[64]
new g_iSendTo[33]
new g_szMainMenu[] = "mMailMain"
new g_szReadMenu[] = "mMailRead"
new g_szSendMenu[] = "mMailSend"
new g_szDeleteMenu[] = "mMailDelete"

new g_iMenuPosition[33]

// *sigh* ugly hack, but oh well
new g_szTitles[33][MAX_MAIL][36]
new g_iKey[33]

new g_iKeys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9

new g_szMainMenuOptions[MAIN_MENU_OPTIONS][] =
{
	"Read Mail",
	"Send Mail",
	"Delete Mail"
}

public plugin_init()
{
	new szVersion[10]
	clan_get_version(szVersion,9)
	register_plugin("Clan API - Mail",szVersion,AUTHOR)
	
	register_cvar("clan_mail_table","clan_mail")
	
	register_clcmd("say /mail","fnCmdMail")
	register_clcmd("say_team /mail","fnCmdMail")
	
	register_clcmd("sendmail","fnCmdSend")
	
	register_event("ResetHUD","fnEventResetHUD","be")
	
	register_menucmd(register_menuid(g_szMainMenu),g_iKeys,"fnMainMenuHandle")
	register_menucmd(register_menuid(g_szReadMenu),g_iKeys,"fnReadMenuHandle")
	register_menucmd(register_menuid(g_szSendMenu),g_iKeys,"fnSendMenuHandle")
	register_menucmd(register_menuid(g_szDeleteMenu),g_iKeys,"fnDeleteMenuHandle")
}

public clan_init()
{
	get_cvar_string("clan_mail_table",g_szTable,63)
	
	new szQuery[512],Handle:hQuery
	format(szQuery,511,"CREATE TABLE IF NOT EXISTS %s (authid VARCHAR (36), sender VARCHAR(36), title VARCHAR(36), message TEXT(512), unread INT(1) DEFAULT 0 NOT NULL)",g_szTable)
	
	hQuery = clan_sql_query(szQuery)
	if(!hQuery)
		log_amx("Could not create member table.")
	
	clan_sql_clean(_:hQuery)
}
	
public fnCmdSend(id)
{
	if(!g_iSendTo[id]--)
		return client_print(id,print_console,"You have not selected someone to send this message to.")
	else if(!clan_connected())
		return PLUGIN_CONTINUE
		
	static szArgs[512]
	read_args(szArgs,511)
		
	g_iCurId = id
	
	static szQuery[512],szRecieverAuthid[36],szPlaceholder[2],szSenderName[33],szSenderAuthid[36],iSenderId,szTitle[16]
	
	// Basically we're just taking the first 15 characters of the message for title
	remove_quotes(szArgs)
	while(containi(szArgs,"'") != -1)
		replace(szArgs,511,"'","^"")
	format(szTitle,15,"%s",szArgs)
	split(szTitle,szTitle,15,szPlaceholder,1,"/")
	remove_quotes(szTitle)
	replace(szArgs,511,szTitle,"")
	replace(szArgs,511,"/","")
	trim(szArgs)
	trim(szTitle)
	
	// NOTE, we are NOT USING the szSenderName returned by this, it is
	// simply to make the native function properly
	clan_get_user_info(g_iSendTo[id],szRecieverAuthid,35,szPlaceholder,1)
	get_user_authid(id,szSenderAuthid,35)
	iSenderId = clan_get_user_id(_,szSenderAuthid)
	if(iSenderId < 0)
		return client_print(id,print_chat,"Error finding in database.")
	
	g_iSendTo[id] = 0
	
	clan_get_user_info(iSenderId,szPlaceholder,1,szSenderName,35)
	
	format(szQuery,511,"INSERT INTO %s (authid,sender,title,message,unread) VALUES ('%s','%s','%s','%s',1)",g_szTable,szRecieverAuthid,szSenderName,szTitle,szArgs)
	clan_sql_threaded_query(szQuery,"fnCmdSayHandle")
	
	return PLUGIN_HANDLED
}

public fnCmdSayHandle(Handle:hQuery)
{
	if(!hQuery)		
		return client_print(g_iCurId,print_chat,"[CLAN] Your message could not be sent.")
	
	return client_print(g_iCurId,print_chat,"[CLAN] Your message has been sent.")
}

public fnEventResetHUD(id)
	if(!task_exists(id) && clan_connected())
		set_task(1.0,"fnShowMessages",id)
	
public fnShowMessages(id)
{
	static szQuery[512],szAuthid[36],iMessages,Handle:hQuery
	
	if(!clan_get_user_rank(id))
		return PLUGIN_CONTINUE
		
	get_user_authid(id,szAuthid,35)
	format(szQuery,511,"SELECT * FROM %s WHERE authid='%s' and unread=1",g_szTable,szAuthid)
	hQuery = clan_sql_query(szQuery)
		
	if(!hQuery)
		return PLUGIN_CONTINUE
		
	iMessages = SQL_NumResults(hQuery)
	if(iMessages > MAX_MAIL)
		client_print(id,print_chat,"[CLAN] You have more than the max messages, delete some to see more.")
	else if(iMessages)
		client_print(id,print_chat,"[CLAN] You have %i messages. Say /mail to read.",iMessages)
			
	clan_sql_clean(_:hQuery)
	
	return PLUGIN_CONTINUE
}	

public fnMailHandle(Handle:hQuery)
{
	if(!hQuery)
		return QUERY_FAILURE
	
	new iMessages = SQL_NumResults(hQuery)
	if(iMessages > MAX_MAIL)
		client_print(g_iCurId,print_chat,"[CLAN] You have more than the max messages, delete some to see more.")
	else if(iMessages)
		client_print(g_iCurId,print_chat,"[CLAN] You have %i messages. Say /mail to read.",iMessages)
		
	return PLUGIN_CONTINUE
}

public fnCmdMail(id)
{
	if(!clan_connected() || !clan_get_user_rank(id))
		return client_print(id,print_console,"You have no access to this command.")
	
	static szMenu[512]
	new iPos
	
	iPos += format(szMenu[iPos],511-iPos,"Clan Mail Menu^n^n")
	for(new iCount = 0;iCount < MAIN_MENU_OPTIONS;iCount++)
		iPos += format(szMenu[iPos],511-iPos,"%i. %s^n",iCount + 1,g_szMainMenuOptions[iCount])
	iPos += format(szMenu[iPos],511-iPos,"^n^n0. Exit")
	
	return show_menu(id,g_iKeys,szMenu,_,g_szMainMenu)
}

public fnMainMenuHandle(id,iKey)
	switch(iKey)
	{
		case 0 :
			fnReadMail(id)
		case 1 :
			fnSendMail(id)
		case 2 :
			fnDeleteMail(id)
		default :
			// if the user didn't press 0. Exit
			if(iKey != 9)
				fnCmdMail(id)
	}
	
fnSendMail(id)
{
	new iPos,iNum,iMembersNum = clan_get_membersnum()
	static szMenu[1024],szAuthid[36],szName[33]
	
	iPos += format(szMenu[iPos],1023-iPos,"Clan Send Mail^n^n")
	for(new iCount = g_iMenuPosition[id] * 7;iCount < (g_iMenuPosition[id] * 7) + 7;iCount++)
	{		
		if(iCount >= iMembersNum)
			break
			
		clan_get_user_info(iCount,szAuthid,35,szName,32)
		iPos += format(szMenu[iPos],1023-iPos,"%i. %s^n",++iNum,szName)
	}
	iPos += format(szMenu[iPos],1023-iPos,"^n^n8. Back^n9. Next^n^n0. Exit")
	
	show_menu(id,g_iKeys,szMenu,-1,g_szSendMenu)
}	

public fnSendMenuHandle(id,iKey)
{
	switch(iKey)
	{
		case 7:
		{
			if(g_iMenuPosition[id] > 0)
				g_iMenuPosition[id]--
			
			fnSendMail(id)
		}
		case 8:
		{
			if(((g_iMenuPosition[id] + 1) * 7) - 6 < clan_get_membersnum())
				g_iMenuPosition[id]++
				
			fnSendMail(id)
		}
		case 9:
			return PLUGIN_CONTINUE
		default :
		{
			g_iSendTo[id] = (g_iMenuPosition[id] * 7) + iKey + 1
			client_print(id,print_chat,"[CLAN] Please type ^"sendmail <your message>^" in your console to send your message.")
			client_print(id,print_chat,"[CLAN] Seperate the title and message with /. For example, ^"My Title / My Message^".")
		}
	}

	return PLUGIN_CONTINUE
}

fnDeleteMail(id)
{
	static szQuery[512],szAuthid[36]
	
	get_user_authid(id,szAuthid,35)
	format(szQuery,511,"SELECT * FROM %s WHERE authid='%s'",g_szTable,szAuthid)
	
	g_iCurId = id
	clan_sql_threaded_query(szQuery,"fnDeleteMailHandle")
}

public fnDeleteMailHandle(Handle:hQuery)
{
	if(!hQuery)
		return PLUGIN_CONTINUE
	
	static szMenu[1024]
	new iPos,iRow,iMenuNum
	
	iPos += format(szMenu[iPos],1023-iPos,"Clan Read Mail^n^n")
		
	while(SQL_MoreResults(hQuery) && iRow <= MAX_MAIL)
	{
		
		SQL_ReadResult(hQuery,2,g_szTitles[g_iCurId][iMenuNum],35)
		iPos += format(szMenu[iPos],1023-iPos,"%i.%s %s^n",++iRow,SQL_ReadResult(hQuery,4) ? " [UNREAD]" : "",g_szTitles[g_iCurId][iMenuNum++])
			
		SQL_NextRow(hQuery)
	}
	
	iPos += format(szMenu[iPos],1023-iPos,"^n^n0. Exit")
	show_menu(g_iCurId,g_iKeys,szMenu,_,g_szDeleteMenu)
	
	return PLUGIN_CONTINUE
}

public fnDeleteMenuHandle(id,iKey)
{
	g_iCurId = id
	g_iKey[id] = iKey
	
	switch(iKey)
	{
		case 9:
			return PLUGIN_CONTINUE
		default :
		{	
			static szQuery[512],szAuthid[36]
			get_user_authid(id,szAuthid,35)
			format(szQuery,511,"DELETE FROM %s WHERE title='%s' AND authid='%s'",g_szTable,g_szTitles[id][iKey],szAuthid)
			
			clan_sql_threaded_query(szQuery,"fnDeleteMessageHandle")
			
			client_print(id,print_chat,"[CLAN] Message deleted.")
		}
	}
	
	return PLUGIN_CONTINUE
}

public fnDeleteMessageHandle(Handle:hQuery)
	return PLUGIN_CONTINUE
	
fnReadMail(id)
{
	static szQuery[512],szAuthid[36]
	
	get_user_authid(id,szAuthid,35)
	format(szQuery,511,"SELECT * FROM %s WHERE authid='%s'",g_szTable,szAuthid)
	
	g_iCurId = id
	clan_sql_threaded_query(szQuery,"fnReadMailHandle")
}

public fnReadMailHandle(Handle:hQuery)
{
	if(!hQuery)
		return PLUGIN_CONTINUE
	
	static szMenu[1024]
	new iPos,iRow,iMenuNum
	
	iPos += format(szMenu[iPos],1023-iPos,"Clan Read Mail^n^n")
		
	while(SQL_MoreResults(hQuery) && iRow <= MAX_MAIL)
	{
		SQL_ReadResult(hQuery,2,g_szTitles[g_iCurId][iMenuNum],35)
		iPos += format(szMenu[iPos],1023-iPos,"%i.%s %s^n",++iRow,SQL_ReadResult(hQuery,4) ? " [UNREAD]" : "",g_szTitles[g_iCurId][iMenuNum++])
			
		SQL_NextRow(hQuery)
	}
	
	iPos += format(szMenu[iPos],1023-iPos,"^n^n0. Exit")
	
	return show_menu(g_iCurId,g_iKeys,szMenu,_,g_szReadMenu)
}

public fnReadMenuHandle(id,iKey)
{
	g_iCurId = id
	g_iKey[id] = iKey
	
	switch(iKey)
	{
		case 9:
			return PLUGIN_CONTINUE
		default :
		{	
			static szQuery[512],szAuthid[36]
			get_user_authid(id,szAuthid,35)
			format(szQuery,511,"SELECT * FROM %s WHERE title='%s' AND authid='%s'",g_szTable,g_szTitles[id][iKey],szAuthid)
			
			clan_sql_threaded_query(szQuery,"fnReadMessageHandle")
		}
	}
	
	return PLUGIN_CONTINUE
}

public fnReadMessageHandle(Handle:hQuery)
{
	if(!hQuery || !SQL_MoreResults(hQuery))
		return PLUGIN_CONTINUE
		
	static szMessage[768],szSender[36]
	SQL_ReadResult(hQuery,1,szSender,35)
	SQL_ReadResult(hQuery,3,szMessage,767)
	
	#if defined HTML_MOTD
	format(szMessage,767,"<html><body bgcolor=^"#000000^"><font color=^"#FFFFFF^">Sender: %s<br><br>Message: %s</font></body></html>",szSender,szMessage)
	#else
	format(szMessage,767,"Sender: %s^n^nMessage: %s",szSender,szMessage)
	#endif
	
	show_motd(g_iCurId,szMessage," ")	
	
	return fnSetRead()
}

// this function will set the message to read
fnSetRead()
{
	static szQuery[512],szAuthid[36]
	get_user_authid(g_iCurId,szAuthid,35)
	
	format(szQuery,511,"UPDATE %s SET unread=0 WHERE title='%s' AND authid='%s'",g_szTable,g_szTitles[g_iCurId][g_iKey[g_iCurId]],szAuthid)
	return clan_sql_threaded_query(szQuery,"fnSetReadHandle")
}

public fnSetReadHandle(Handle:hQuery)
	return PLUGIN_CONTINUE
