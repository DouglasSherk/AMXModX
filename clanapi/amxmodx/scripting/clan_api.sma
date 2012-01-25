#include <amxmodx>
#include <amxmisc>
#include <clanapi>
#include <sqlx>

// Version info
new g_szPlugin[] = "Clan API"
new g_szVersion[] = "1.2"
new g_szAuthor[] = "Hawk552"

// General SQL stuff
new Handle:g_hDbInfo
new bool:g_bSqlOk = true
new g_szTable[64]
new g_iQuery

// This is the stuff stored in SQL.
new g_szAuthids[MAX_MEMBERS][36]
new g_iRanks[MAX_MEMBERS]
new g_szNames[MAX_MEMBERS][33]

// Stores current members num
new g_iMembers

// This is the stuff used on the gameserver.
new g_iRank[33]

public plugin_init()
{
	new szConfigsdir[64]
	get_configsdir(szConfigsdir,63)
	
	server_cmd("exec %s/sql.cfg",szConfigsdir)
	server_cmd("exec %s/clanapi.cfg",szConfigsdir)
	
	register_plugin(g_szPlugin,g_szVersion,g_szAuthor)
	
	register_cvar("clan_api",g_szVersion,FCVAR_SERVER)
	register_cvar("clan_membertable","clan_members")
	register_cvar("clan_tag","")
	register_cvar("clan_name","")
	register_cvar("clan_sql_config","0")	
	
	set_task(1.0,"fnConfig")
}

public client_putinserver(id)
{	
	if(!g_bSqlOk)
		return PLUGIN_CONTINUE
	
	fnAssignAccess(id)
	
	if(!g_iRank[id])
		return PLUGIN_CONTINUE
			
	new iForward = CreateMultiForward("clan_member_join",ET_IGNORE,FP_CELL)
	if(!iForward)		
		return log_amx("clan_member_join Forward failed to be created.")
	
	new iReturn
	if(!ExecuteForward(iForward,iReturn,id))
		return log_amx("clan_member_join Forward failed to execute.")

	return DestroyForward(iForward)
}

public client_disconnect(id)
{
	if(!g_bSqlOk || !g_iRank[id])
		return PLUGIN_CONTINUE
	
	new iForward = CreateMultiForward("clan_member_leave",ET_IGNORE,FP_CELL),iReturn
	if(!iForward)
	{
		log_amx("clan_member_leave Forward failed to be created.")
		return INTERNAL_FAILURE
	}
	
	ExecuteForward(iForward,iReturn,id)
	
	g_iRank[id] = 0

	return DestroyForward(iForward)
}	

public plugin_natives()
{
	register_native("clan_connected","fnApiConnected")
	register_native("clan_add_member","fnApiAddMember")
	register_native("clan_mod_member","fnApiModMember")
	register_native("clan_del_member","fnApiDelMember")
	register_native("clan_get_user_rank","fnApiGetUserRank")
	register_native("clan_get_user_info","fnApiGetUserInfo")
	register_native("clan_get_user_name","fnApiGetUserName")
	register_native("clan_get_user_id","fnApiGetUserId")
	register_native("clan_get_membersnum","fnApiGetMembersNum")
	register_native("clan_get_version","fnApiGetVersion")
	register_native("clan_sql_get_dbinfo","fnApiSqlGetDbInfo")
	register_native("clan_sql_query","fnApiSqlQuery")
	register_native("clan_sql_threaded_query","fnApiSqlThreadedQuery")
	register_native("clan_sql_clean","fnApiSqlClean")
	register_native("clan_reload","fnApiReload")
	
	register_library("clanapi")
}

public plugin_end()
	if(g_hDbInfo)
		SQL_FreeHandle(g_hDbInfo)

public fnConfig()
{	
	new szHost[64],szUser[64],szPass[64],szDb[64],szConfigsdir[64],szText[128]
	
	if(!get_cvar_num("clan_sql_config"))
	{
		get_cvar_string("amx_sql_host", szHost, 63)
		get_cvar_string("amx_sql_user", szUser, 63)
		get_cvar_string("amx_sql_pass", szPass, 63)
		get_cvar_string("amx_sql_db", szDb, 63)
	}
	else
	{
		get_configsdir(szConfigsdir,63)
		format(szConfigsdir,63,"%s/%s",szConfigsdir,g_szSqlFile)
		
		new iFile = fopen(szConfigsdir,"r"),iFound[4]
		if(!iFile)
		{
			log_amx("Error processing SQL configuration file (%s), defaulting to sql.cfg (File doesn't exist)",szConfigsdir)
			set_cvar_num("clan_sql_config",0)
			
			return fnConfig()
		}
		
		while(!feof(iFile))
		{			
			fgets(iFile,szText,127)
			
			if(containi(szText,"clan_sql_host") != -1)
			{
				iFound[0] = 1
				parse(szText,szText,127,szHost,63)
				remove_quotes(szHost)
			}
			
			if(containi(szText,"clan_sql_user") != -1)
			{
				iFound[1] = 1
				parse(szText,szText,127,szUser,63)
				remove_quotes(szUser)
			}
				
			if(containi(szText,"clan_sql_pass") != -1)
			{
				iFound[2] = 1
				parse(szText,szText,127,szPass,63)
				remove_quotes(szPass)
			}
				
			if(containi(szText,"clan_sql_db") != -1)
			{
				iFound[3] = 1
				parse(szText,szText,127,szDb,63)
				remove_quotes(szDb)
			}
		}
		
		for(new iCount;iCount < 4;iCount++)
			if(!iFound[iCount])
			{
				log_amx("Error: Could not find all fields in SQL configuration file (%s)",g_szSqlFile)
			
				g_bSqlOk = false

				return PLUGIN_CONTINUE
			}
				
	}	
	
	g_hDbInfo = SQL_MakeDbTuple(szHost, szUser, szPass, szDb)
	
	// Because this is only done once, I'm not going to bother putting
	// pointers or anything like that in it.
	get_cvar_string("clan_membertable",g_szTable,63)
	
	new Handle:hDb = fnDbConnect()
	if(hDb > Handle:0)
	{
		fnCheckTables()
		SQL_FreeHandle(hDb)
	}
	else
		return PLUGIN_CONTINUE
		
	
	new iForward = CreateMultiForward("clan_init",ET_IGNORE),iReturn
	if(!iForward)
		return log_amx("Could not create forward clan_init")
	if(!ExecuteForward(iForward,iReturn))
		return log_amx("Could not execute forward clan_init")
		
	return fnLoadMembers()
}

public fnLoadMembers()
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	
	new szQuery[512],iData[1]
	format(szQuery,511,"SELECT * FROM %s",g_szTable)
	
	iData[0] = g_iQuery++
	
	return SQL_ThreadQuery(g_hDbInfo,"fnLoadMembersHandle",szQuery,iData,1)
}

public fnLoadMembersHandle(iFailState,Handle:hQuery,szError[],iError,iData[],iSize)
{
	if(fnThreadedQueryError(hQuery,iFailState,szError,iError) < 0)
		return PLUGIN_CONTINUE
		
	g_iMembers = 0
	
	new szRank[33]
	while(SQL_MoreResults(hQuery))
	{
		SQL_ReadResult(hQuery,0,g_szAuthids[g_iMembers],35)
		SQL_ReadResult(hQuery,1,szRank,32)
		SQL_ReadResult(hQuery,2,g_szNames[g_iMembers],32)
		
		g_iRanks[g_iMembers++] = str_to_num(szRank)
		
		SQL_NextRow(hQuery)
	}
	
	for(new iCount = g_iMembers;iCount < MAX_MEMBERS;iCount++)
	{
		// In case it was called by another plugin after deleting
		// or changing someone
		g_szAuthids[iCount][0] = 0
		g_iRanks[iCount] = 0
		g_szNames[iCount][0] = 0
	}
	
	return PLUGIN_CONTINUE
}

public fnApiReload(iPlugin,iParams)
{
	fnLoadMembers()
	
	static iPlayers[32],iPlayersnum
	get_players(iPlayers,iPlayersnum)
	
	for(new iCount;iCount < iPlayersnum;iCount++)
		fnAssignAccess(iPlayers[iCount])
}

public fnApiConnected(iPlugin,iParams)
	return g_bSqlOk

public fnApiAddMember(iPlugin,iParams)
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	else if(iParams != 3)
		return INCORRECT_USAGE
		
	new szAuthid[36],iRank,szName[33]
	get_string(1,szAuthid,35)
	iRank = get_param(2)
	get_string(3,szName,32)
	
	new szQuery[512],iData[1]
	iData[0] = g_iQuery++
	
	format(szQuery,511,"INSERT INTO %s (authid,rank,name) VALUES('%s','%i','%s');",g_szTable,szAuthid,iRank,szName)
	
	return SQL_ThreadQuery(g_hDbInfo,"fnApiMemberHandle",szQuery,iData,1)
}	

public fnApiModMember(iPlugin,iParams)
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	else if(iParams != 3)
		return INCORRECT_USAGE
		
	new szAuthid[36],szName[33],iRank
	get_string(1,szAuthid,35)
	iRank = get_param(2)
	get_string(3,szName,32)
	
	new szQuery[512],iData[1]
	iData[0] = g_iQuery++
	
	format(szQuery,511,"UPDATE %s SET name='%s', rank='%i' WHERE authid='%s'",g_szTable,szName,iRank,szAuthid)
	
	return SQL_ThreadQuery(g_hDbInfo,"fnApiMemberHandle",szQuery,iData,1)
}

public fnApiDelMember(iPlugin,iParams)
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	else if(iParams != 2)
		return INCORRECT_USAGE
		
	new szAuthid[36],szName[33]
	get_string(1,szAuthid,35)
	get_string(2,szName,32)
	
	new szQuery[512],iData[1]
	iData[0] = g_iQuery++
	
	if(szAuthid[0])
		format(szQuery,511,"DELETE FROM %s WHERE authid='%s'",g_szTable,szAuthid)
	else
		format(szQuery,511,"DELETE FROM %s WHERE name='%s'",g_szTable,szName)
	
	return SQL_ThreadQuery(g_hDbInfo,"fnApiMemberHandle",szQuery,iData,1)
}

public fnApiMemberHandle(iFailState,Handle:hQuery,szError[],iError,iData[],iSize)
	fnThreadedQueryError(hQuery,iFailState,szError,iError)

public fnApiGetUserRank(iPlugin,iParams)
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	else if(iParams != 2)
		return INCORRECT_USAGE
	
	new id = get_param(1),szAuthid[36]
	get_string(2,szAuthid,35)
	
	if(id)
		return g_iRank[id]
	else if(szAuthid[0])
		for(new iCount = 0;iCount < g_iMembers;iCount++)
			if(equali(g_szAuthids[iCount],szAuthid))
				return g_iRanks[iCount]
	
	return -1
}

public fnApiGetUserName(iPlugin,iParams)
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	else if(iParams != 3)
		return INCORRECT_USAGE
		
	new id = get_param(1),szAuthid[36]
	get_user_authid(id,szAuthid,35)
	
	for(new iCount = 0;iCount < MAX_MEMBERS;iCount++)
		if(equali(szAuthid,g_szAuthids[iCount]))
		{
			set_string(2,g_szNames[iCount],get_param(3))
			return PLUGIN_HANDLED
		}
	
	return -1
}

public fnApiGetUserId(iPlugin,iParams)
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	else if(iParams != 2)
		return INCORRECT_USAGE
		
	new szArg[36]
	get_string(1,szArg,35)
	
	if(szArg[0])
		for(new iCount = 0;iCount < MAX_MEMBERS;iCount++)
			if(equali(szArg,g_szNames[iCount]))
				return iCount
			// stupid crap 
			else { }
	else
	{
		get_string(2,szArg,35)
		
		for(new iCount = 0;iCount < MAX_MEMBERS;iCount++)
			if(equali(szArg,g_szAuthids[iCount]))
				return iCount
	}
	
	return -1
}

public fnApiGetUserInfo(iPlugin,iParams)
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	else if(iParams != 5)
		return INCORRECT_USAGE
	
	new iMemberNum = get_param(1)
	set_string(2,g_szAuthids[iMemberNum],get_param(3))
	set_string(4,g_szNames[iMemberNum],get_param(5))
	
	return PLUGIN_CONTINUE
}

public fnApiGetMembersNum(iPlugin,iParams)
	return g_iMembers

public fnApiGetVersion(iPlugin,iParams)
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	else if(iParams != 2)
		return INCORRECT_USAGE
	
	return set_string(1,g_szVersion,get_param(2))
}

public fnApiSqlGetDbInfo(iPlugin,iParams)
	return _:g_hDbInfo

public fnApiSqlQuery(iPlugin,iParams)
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	else if(iParams != 1)
		return INCORRECT_USAGE
	
	new szQuery[256]
	get_string(1,szQuery,255)
	
	return fnQuery(szQuery)
}

public fnApiSqlThreadedQuery(iPlugin,iParams)
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	else if(iParams != 2)
		return INCORRECT_USAGE
	
	new szQuery[256],szFunction[33]
	get_string(1,szQuery,255)
	get_string(2,szFunction,32)
	
	return fnThreadedQuery(szQuery,iPlugin,szFunction)
}

public fnApiSqlClean(iPlugin,iParams)
	for(new iCount = 1;iCount <= iParams;iCount++)
		SQL_FreeHandle(Handle:get_param(iCount))

Handle:fnDbConnect()
{	
	new iError,szError[255],Handle:hDb = SQL_Connect(g_hDbInfo, iError, szError, 254)
	if(!hDb)
	{
		fnConnectError(iError,szError)
		
		return Handle:QUERY_FAILURE
	}
	
	return hDb
}

fnConnectError(iError,szError[])
{
	log_amx("Unable to connect to database: [%d] %s",iError,szError)
		
	return (g_bSqlOk = false)
}

fnQueryError(Handle:hQuery,szError[] = "",iError = 0)
{
	if(!iError)
		iError = SQL_QueryError(hQuery,szError,strlen(szError))

	log_amx("Unable to query database: [%d] %s",iError,szError)
		
	return (g_bSqlOk = false)
}

fnThreadedQueryError(Handle:hQuery,iFailState,szError[],iError)
{
	if(iFailState == TQUERY_CONNECT_FAILED)
		return fnConnectError(iError,szError)
	else if(iFailState == TQUERY_QUERY_FAILED)
		return fnQueryError(hQuery,szError,iError)
	
	return PLUGIN_CONTINUE
}

fnQuery(szQuery[])
{
	new Handle:hDb = fnDbConnect()
	if(!hDb)
		return NOT_CONNECTED

	new Handle:hQuery = SQL_PrepareQuery(hDb,szQuery,g_szTable)
	if(!SQL_Execute(hQuery))
	{
		fnQueryError(hQuery)
		return QUERY_FAILURE
	}
	
	SQL_FreeHandle(hDb)
	
	return _:hQuery
}

fnThreadedQuery(szQuery[],iPlugin,szFunction[])
{
	// It's being used as both a string and int, but whatever
	new iData[50]
	format(iData,47,"%s",szFunction)
	iData[49] = iPlugin
	
	return SQL_ThreadQuery(g_hDbInfo,"fnThreadedQueryHandle",szQuery,iData,50)
}

public fnThreadedQueryHandle(iFailState,Handle:hQuery,szError[],iError,iData[],iSize)
{
	if(fnThreadedQueryError(hQuery,iFailState,szError,iError) < 0)
		return PLUGIN_CONTINUE
	
	new iForward = CreateOneForward(iData[49],iData,FP_CELL),iReturn
	if(iForward < 0)
		return log_amx("Could not send back threaded query.")
	
	if(!ExecuteForward(iForward,iReturn,_:hQuery))
		return log_amx("Could not execute forward.")
	
	return DestroyForward(iForward)
}

fnCheckTables()
{
	if(!g_bSqlOk)
		return INTERNAL_FAILURE
	
	new szQuery[256]
	format(szQuery,255,"CREATE TABLE IF NOT EXISTS %s (authid VARCHAR (36),rank VARCHAR(33),name VARCHAR (33))",g_szTable)
	
	new Handle:hQuery = Handle:fnQuery(szQuery)
		
	return hQuery ? SQL_FreeHandle(hQuery) : PLUGIN_CONTINUE
}

fnAssignAccess(id)
{
	static szAuthid[36],szName[33]
	get_user_authid(id,szAuthid,35)
	get_user_name(id,szName,32)
	
	for(new iCount;iCount < g_iMembers;iCount++)
		if(equali(g_szAuthids[iCount],szAuthid))
		{
			g_iRank[id] = g_iRanks[iCount]
			break
		}
}
