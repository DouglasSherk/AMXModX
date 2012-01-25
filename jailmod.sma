#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <engine>

#define MAX_JAILS 20
#define ITEMS_PER_MENU 6

#define ON_CHECK(%1) if(!get_pcvar_num(p_Mode)) return %1

new Handle:g_Sql
new bool:g_Access[33]

new p_PdJobs
new p_Table
new p_Reconnect
new p_Death
new p_Mode
new p_Distance

new g_Table[64]

new g_JailNames[MAX_JAILS][33]
new Float:g_JailOrigins[MAX_JAILS][3]
new g_JailCommands[MAX_JAILS][32]
new g_JailNum

new g_Menu[] = "JailModMenu"
new g_Keys

new g_MenuPage[33]
new g_Jailed[33] = {-1,...}

// rather than making 3 static variables, let's make 1 global
new g_Query[256]

new g_Died[33]

public plugin_init()
{
	register_plugin("Ultimate Jail Mod","1.0","Hawk552")
	
	register_clcmd("jailmodmenu","CmdJailMod")
	
	register_event("ResetHUD","EventResetHUD","be")
	register_event("DeathMsg","EventDeathMsg","a")
	
	p_PdJobs = get_cvar_pointer("rp_jobid_mcpd")
	p_Table = register_cvar("amx_jail_table","jail_users")
	p_Reconnect = register_cvar("amx_jail_reconnect","1")
	p_Death = register_cvar("amx_jail_death","1")
	p_Mode = register_cvar("amx_jail_mode","1")
	p_Distance = register_cvar("amx_jail_distance","50.0")
	
	for(new Count;Count < 10;Count++)
		g_Keys += (1<<Count)
	
	new ConfigsDir[128],MapName[33],FileName[128]
	get_configsdir(ConfigsDir,127)
	get_mapname(MapName,32)
	
	format(FileName,127,"%s/jailmod/%s.ini",ConfigsDir,MapName)
	
	new File = fopen(FileName,"r")
	if(!File)
	{
		format(g_Query,255,"No file found for this map, tried to open ^"%s^".",FileName)
		return set_fail_state(g_Query)
	}
		
	new Buffer[128],Left[33],Right[33],Origins[3][11]
	while(!feof(File) && g_JailNum < MAX_JAILS)
	{
		fgets(File,Buffer,127)
		if(Buffer[0] == ';')
			continue
			
		if(containi(Buffer,"[") != -1 && containi(Buffer,"]") != -1)
		{
			replace(Buffer,127,"[","")
			replace(Buffer,127,"]","")
			
			if(g_JailCommands[g_JailNum][0])
				register_clcmd(g_JailCommands[g_JailNum],"JailCommand")
			
			copy(g_JailNames[g_JailNum++],32,Buffer)
		}
		else if(containi(Buffer,"origin") != -1)
		{
			parse(Buffer,Left,32,Right,32)
			remove_quotes(Right)
			trim(Right)
			
			parse(Right,Origins[0],10,Origins[1],10,Origins[2],10)
			for(new Count;Count < 3;Count++)
				g_JailOrigins[g_JailNum][Count] = str_to_float(Origins[Count])
		}
		else if(containi(Buffer,"command") != -1)
		{
			parse(Buffer,Left,32,Right,32)
			remove_quotes(Right)
			trim(Right)
			
			copy(g_JailCommands[g_JailNum],32,Right)
		}
	}	
	
	g_JailNum++
	
	register_menucmd(register_menuid(g_Menu),g_Keys,"MenuHandle")
	
	new Host[64],User[64],Pass[64],Db[64]
	// no pcvars because we're only fetching them once
	get_cvar_string("economy_mysql_host",Host,32)
	get_cvar_string("economy_mysql_user",User,32) 
	get_cvar_string("economy_mysql_pass",Pass,32) 
	get_cvar_string("economy_mysql_db",Db,32) 
	
	g_Sql = SQL_MakeDbTuple(Host,User,Pass,Db)
	
	new Error[256],Errcode,Handle:SqlConnect = SQL_Connect(g_Sql,Errcode,Error,255)
	
	if(Errcode || !SqlConnect)
	{
		log_amx("Error connecting to SQL database: %s",Error)
		return set_fail_state("Could not connect to SQL database.")
	}
	
	get_pcvar_string(p_Table,g_Table,63)
	
	new Handle:Query = SQL_PrepareQuery(SqlConnect,"CREATE TABLE IF NOT EXISTS %s (authid VARCHAR(36),cell INT,map VARCHAR(33))",g_Table)
	if(!Query || !SQL_Execute(Query))
		log_amx("Failed to create jail table (%s).",g_Table)
	else
	{
		SQL_FreeHandle(Query)
		SQL_FreeHandle(SqlConnect)
	}
	
	return PLUGIN_CONTINUE
}

public EventDeathMsg()
{
	ON_CHECK()
	
	new id = read_data(2)
	g_Died[id] = 0
	
	if(get_pcvar_num(p_Death))
		FreePlayer(0,id)
	
	if(get_pcvar_num(p_Mode) == 1)
	{
		new Float:Origin[3]
		entity_get_vector(id,EV_VEC_origin,Origin)
		
		if(vector_distance(Origin,g_JailOrigins[g_Jailed[id]]) > get_pcvar_float(p_Distance))
			FreePlayer(0,id)
	}
}
		

public JailCommand(id)
{
	if(!g_Access[id] || !get_pcvar_num(p_Mode))
		return PLUGIN_HANDLED
		
	new Arg[33],Num,List[MAX_JAILS]
	read_argv(0,Arg,32)
	
	for(new Count = 1;Count <= g_JailNum;Count++)
		if(equali(Arg,g_JailCommands[Count]))
		{
			for(new Count2;Count2 < g_JailNum;Count2++)
				if(equali(g_JailCommands[Count],g_JailCommands[Count2]))
					List[Num++] = Count2
			
			Count = List[random(Num - 1)]
			
			g_MenuPage[id] = (Count - 3) / 7
			MenuHandle(id,Count - g_MenuPage[id] * 7)
			
			break
		}
	
	return PLUGIN_HANDLED
}

public client_disconnect(id)
{
	g_Jailed[id] = -1
	g_MenuPage[id] = 0
	g_Access[id] = false
	g_Died[id] = 0
}

public client_putinserver(id)
{
	ON_CHECK()
	
	new Authid[36]
	get_user_authid(id,Authid,35)
	
	new Data[1]
	format(g_Query,255,"SELECT JobID FROM money WHERE steamid='%s'",Authid)
	Data[0] = id
	
	SQL_ThreadQuery(g_Sql,"JailAccessHandle",g_Query,Data,1)
}

public JailAccessHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return set_fail_state("Internal error: consult developer.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	new PdJobs[32],Start[16],End[16],Min,Max
	get_pcvar_string(p_PdJobs,PdJobs,31)
	parse(PdJobs,Start,15,End,15)
	Min = str_to_num(Start)
	Max = str_to_num(End)
	
	new JobId = SQL_ReadResult(Query,0)
	g_Access[Data[0]] = JobId && JobId <= Max && JobId >= Min ? true : false
	
	// not necessary, but we have to since we returned values at the top
	return PLUGIN_CONTINUE
}

public EventResetHUD(id)
{
	// can't possibly be in jail, so just stop now if user has access
	if(g_Access[id] || !get_pcvar_num(p_Reconnect))
		return
	
	ON_CHECK()
	
	new Data[1],Authid[36],MapName[33]
	get_user_authid(id,Authid,35)
	
	get_mapname(MapName,32)
	
	format(g_Query,255,"SELECT cell FROM %s WHERE authid='%s' AND map='%s'",g_Table,Authid,MapName)
	Data[0] = id
	
	SQL_ThreadQuery(g_Sql,"CheckJail",g_Query,Data,1)
}

public CheckJail(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return set_fail_state("Internal error: consult developer.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	new NumResults = SQL_NumResults(Query)
	// they're not jailed, at least in this map -- let them go
	if(!NumResults)
		return PLUGIN_CONTINUE
		
	new id = Data[0]
	
	g_Jailed[id] = SQL_ReadResult(Query,0)
	// get back in jail
	entity_set_origin(id,g_JailOrigins[g_Jailed[id] + 1])
	
	client_print(id,print_chat,"[JM] You have been put back in jail because that is where you were when you last disconnected.")
	
	return PLUGIN_CONTINUE
}

public CmdJailMod(id)
{
	if(!g_Access[id])
		return client_print(id,print_chat,"[JM] You don't have access to this command.")
	
	ON_CHECK(PLUGIN_CONTINUE)
		
	static Menu[512]
	new Pos,Num,Keys = (1<<7|1<<8|1<<9),Mode = get_pcvar_num(p_Mode)
	
	Pos += format(Menu[Pos],sizeof Menu - Pos - 1,"Jail Mod^n^n")
	for(new Count = g_MenuPage[id] * ITEMS_PER_MENU;Count < g_MenuPage[id] * ITEMS_PER_MENU + ITEMS_PER_MENU;Count++)
		if(g_JailNames[Count][0] && Count < g_JailNum)
		{
			Keys |= (1<<Num)
			Pos += format(Menu[Pos],sizeof Menu - Pos - 1,"%d. %s^n",++Num,g_JailNames[Count])
		}
		
	if(Mode == 2)
		Keys |= (1<<6)
		
	Pos += format(Menu[Pos],sizeof Menu - Pos - 1,"%s^n^n8. Last Page^n9. Next Page^n^n0. Exit",Mode == 2 ? "^n7. Free Target Player" : "")
	
	show_menu(id,g_Keys,Menu,-1,g_Menu)
	
	return PLUGIN_CONTINUE
}
	
public MenuHandle(id,Key)
	switch(Key)
	{
		case 6 :
		{
			new Index,Body
			get_user_aiming(id,Index,Body,500)
			
			if(!Index || !is_user_alive(Index))
				return
			
			FreePlayer(id,Index)
		}
		case 7 :
		{
			if(g_MenuPage[id])
				g_MenuPage[id]--
			
			CmdJailMod(id)
		}
		case 8 :
		{
			if((g_MenuPage[id] + 1) * ITEMS_PER_MENU + ITEMS_PER_MENU < g_JailNum)
				g_MenuPage[id]++
			
			CmdJailMod(id)
		}
		case 9 :
			return
		default :
		{
			new RealKey = g_MenuPage[id] * ITEMS_PER_MENU + Key
			
			if(RealKey > MAX_JAILS)
			{
				// I hate adding brackets, but we have to here.
				CmdJailMod(id)
				return 
			}
			
			new Index,Body
			get_user_aiming(id,Index,Body,500)
			
			if(!Index || !is_user_alive(Index))
				return
			
			// I dunno why, but if I do this for some reason it randomly works
			entity_set_origin(Index,g_JailOrigins[RealKey + 1])
			
			new Name[33]
			get_user_name(Index,Name,32)
			client_print(id,print_chat,"[JM] You have sent %s to %s.",Name,g_JailNames[RealKey])
			get_user_name(id,Name,32)
			client_print(Index,print_chat,"[JM] You have been sent to %s by %s.",g_JailNames[RealKey],Name)
			
			g_Jailed[Index] = RealKey
			
			if(get_pcvar_num(p_Reconnect))
			{
				static Authid[36],MapName[33]
				get_user_authid(Index,Authid,35)
				get_mapname(MapName,32)
			
				format(g_Query,255,"INSERT INTO %s VALUES ('%s','%d','%s')",g_Table,Authid,g_Jailed[Index],MapName)
			
				SQL_ThreadQuery(g_Sql,"JailMenuHandle",g_Query)
			}
		}
	}

public JailMenuHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
	if(FailState == TQUERY_CONNECT_FAILED)
		set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		set_fail_state("Internal error: consult developer.")
	else if(Errcode)
		log_amx("Error on query: %s",Error)
			
FreePlayer(id,Index)
{
	if(g_Jailed[Index] < 0 || !get_pcvar_num(p_Reconnect))
		return PLUGIN_CONTINUE
	
	new Authid[36],MapName[33],Data[2]
	get_user_authid(Index,Authid,35)
	get_mapname(MapName,32)
	
	Data[0] = id
	Data[1] = Index
	
	format(g_Query,255,"DELETE FROM %s WHERE authid='%s' AND map='%s'",g_Table,Authid,MapName)
	
	SQL_ThreadQuery(g_Sql,"FreePlayerHandle",g_Query,Data,2)
	
	return PLUGIN_HANDLED
}

public FreePlayerHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		set_fail_state("Internal error: consult developer.")
	else if(Errcode)
		log_amx("Error on query: %s",Error)
	
	if(SQL_AffectedRows(Query))
	{
		new Name[33],id = Data[0],Index = Data[1]
		get_user_name(Index,Name,32)
		
		if(id)
		{
			client_print(id,print_chat,"[JM] You have freed %s from jail.",Name)
			get_user_name(id,Name,32)
			client_print(Index,print_chat,"[JM] You have been freed from jail by %s.",Name)
		}
		
		g_Jailed[Index] = -1
	}
}
