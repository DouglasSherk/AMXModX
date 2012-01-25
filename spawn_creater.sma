/*

Copyleft 2007
Plugin thread: http://forums.alliedmods.net/showthread.php?p=432086

SPAWN CREATER
=============

Description
Have you ever played a map that didn't have enough spawn points 
for 32 players? Well, this plugin tries to remedy that. It can 
either dynamically add more spawns, or it can do it manually 
through config files.

Commands
	spawnmenu - opens spawn manipulation menu

Changelog:
	Jan 26, 2007 - v1.0 - 	Release		
	Jan 27, 2007 - v1.1 - 	[BUG] Fixed spawns being created in mid-air
				[BUG] Fixed menu's spawn creation getting wrong z-axis
				[FEATURE] Added "players" param to "t_spawns" and "ct_spawns"
	Feb 1, 2007 - v1.2 - 	[BUG] Added precision to the random spawner
	
Credits:
	execgroup3000 - idea
	XxAvalanchexX - trace hull suggestion and implementation help
	
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_stocks>

new g_Directory[] = "/spawncreater/"
new g_FileName[256]

new g_Buyzone[] = "func_buyzone"
new g_TSpawn[] = "info_player_deathmatch"
new g_CTSpawn[] = "info_player_start"

new g_Menu

new g_CTTarget
new g_TTarget

new g_TEnts[32][2]
new g_CTEnts[32][2]

new g_Config[33]

new g_TEntsNum
new g_CTEntsNum

new Float:g_DistanceLimit

new g_BuyzoneDisable

#if sizeof g_TSpawn > sizeof g_CTSpawn
	#define SPAWN_LEN sizeof g_TSpawn
#else
	#define SPAWN_LEN sizeof g_CTSpawn
#endif

#define TEAM_CT 2
#define TEAM_T 1

public plugin_init()
{
	register_plugin("Spawn Creater","1.2","Hawk552")
	
	register_clcmd("spawnmenu","CmdSpawnMenu",ADMIN_RCON,"- opens dynamic spawns menu")
	
	g_Menu = menu_create("Spawn Creater","MainMenuHandle")
	menu_additem(g_Menu,"Map Config","mcfg")
	menu_additem(g_Menu,"Default Config","dcfg")
	menu_additem(g_Menu,"Create Spawn Here","mk")
	menu_additem(g_Menu,"Current Spawn Info","inf")
	menu_addblank(g_Menu)
	
	set_task(1.0,"CreateSpawns")
}

public CmdSpawnMenu(id,level,cid)
{
	if(cmd_access(id,level,cid,1))
		menu_display(id,g_Menu,0)
	
	return PLUGIN_HANDLED
}

public MainMenuHandle(id,Menu,Key)
	switch(Key)
	{
		case 0 :
		{
			g_Config[id] = 0
			ConfigMenu(id)
		}
		case 1 :
		{
			g_Config[id] = 1
			ConfigMenu(id)
		}
		case 2 :
		{
			new Float:Origin[3]
			pev(id,pev_origin,Origin)
			
			new Team = get_user_team(id),Write[128]
			format(Write,127,"spawn ^"%d %d %d^" %d",floatround(Origin[0]),floatround(Origin[1]),floatround(Origin[2]),Team - 1)
			
			write_file(g_FileName,Write)
			
			client_print(id,print_chat,"[SPAWN] Spawn added here for team %s.",(Team - 1) ? "counter-terrorists" : "terrorists")
		}
		case 3 :
		{
			new Ent,TCustom,TNum,CTCustom,CTNum
			while((Ent = engfunc(EngFunc_FindEntityByString,Ent,"classname",g_TSpawn)) != 0)
			{
				TNum++
				if(pev(Ent,pev_iuser1))
					TCustom++
			}
			
			Ent = 0
			while((Ent = engfunc(EngFunc_FindEntityByString,Ent,"classname",g_CTSpawn)) != 0)
			{
				CTNum++
				if(pev(Ent,pev_iuser1))
					CTCustom++
			}
			
			new Menu = menu_create("Current Spawns","ConfigHandle"),Text[33]
			format(Text,32,"Total T Spawns: %d",TNum)
			menu_additem(Menu,Text)
			format(Text,32,"Created T Spawns: %d",TCustom)
			menu_additem(Menu,Text)
			menu_addblank(Menu)
			format(Text,32,"Total CT Spawns: %d",CTNum)
			menu_additem(Menu,Text)
			format(Text,32,"Created CT Spawns: %d",CTCustom)
			menu_additem(Menu,Text)
			menu_addblank(Menu)
			
			menu_display(id,Menu,0)
			
			menu_destroy(Menu)
		}
	}

ConfigMenu(id)
{	
	new FileName[256]
	copy(FileName,255,g_FileName)
	
	if(g_Config[id])
	{
		new MapName[33]
		get_mapname(MapName,32)
		
		replace(FileName,255,MapName,"default")
	}
	
	new File = fopen(FileName,"r")
	if(!File)
		return
	
	g_CTTarget = -1
	g_TTarget = -1
	g_DistanceLimit = -1.0
	g_BuyzoneDisable = -1
	
	LoadFile(File,0)
	
	new MenuName[33]
	copy(MenuName,32,g_Config[id] ? "Default Config" : "Map Config")
	
	new Menu = menu_create(MenuName,"ConfigHandle"),String[24]
	g_DistanceLimit != -1 ? format(String,23,"%d",floatround(g_DistanceLimit)) : format(String,23,"Not Defined")
	format(MenuName,32,"Max Distance: %s",String)
	menu_additem(Menu,MenuName)
	g_CTTarget != -1 ? format(String,23,"%d",g_CTTarget) : format(String,23,"Not Defined")
	format(MenuName,32,"CT Spawn Target: %s",String)
	menu_additem(Menu,MenuName)
	g_TTarget != -1 ? format(String,23,"%d",g_TTarget) : format(String,23,"Not Defined")
	format(MenuName,32,"T Spawn Target: %s",String)
	menu_additem(Menu,MenuName)
	g_BuyzoneDisable != -1 ? format(String,23,"%s",g_BuyzoneDisable ? "Yes" : "No") : format(String,23,"Not Defined")
	format(MenuName,32,"Disable Buyzone Addition: %s",String)
	menu_additem(Menu,MenuName)
	menu_addblank(Menu)
	
	menu_display(id,Menu,0)
	
	menu_destroy(Menu)
}

public ConfigHandle(id,Menu,Key)
	if(Key > 0)
		set_task(0.1,"SpawnMenuCommand",id)

public SpawnMenuCommand(id)
	client_cmd(id,"spawnmenu")
	
public CreateSpawns()
{	
	new TNum,CTNum,Ent,String[] = "classname"
	while((Ent = engfunc(EngFunc_FindEntityByString,Ent,String,g_TSpawn)) != 0)
		if(!pev(Ent,pev_iuser2))
			TNum++
	
	while((Ent = engfunc(EngFunc_FindEntityByString,Ent,String,g_CTSpawn)) != 0)
		if(!pev(Ent,pev_iuser2))
			CTNum++
	
	Ent = 0
	new TEnt,CTEnt
	while((Ent = engfunc(EngFunc_FindEntityByString,Ent,String,g_TSpawn)) != 0)
		if(pev(Ent,pev_iuser2))
			continue
		else
		{
			TEnt = Ent
			break
		}
	
	Ent = 0	
	while((Ent = engfunc(EngFunc_FindEntityByString,Ent,String,g_CTSpawn)) != 0)
		if(pev(Ent,pev_iuser2))
			continue
		else
		{
			CTEnt = Ent
			break
		}
	
	Ent = 0
	new Float:Origin[3],Num,ScannedNum,Total = TNum
	while((Ent = engfunc(EngFunc_FindEntityByString,Ent,String,g_TSpawn)) != 0 && ScannedNum < g_TEntsNum && Total < g_TTarget)
		if(pev(Ent,pev_iuser2))
		{		
			Num = 0

			if(!FindEmptyLoc(TEnt,Origin,Num,g_TSpawn))
				break
			
			engfunc(EngFunc_SetOrigin,g_TEnts[ScannedNum][0],Origin)
			engfunc(EngFunc_SetOrigin,g_TEnts[ScannedNum++][1],Origin)
			
			Total++
		}
	
	for(new Count = ScannedNum;Count < g_TEntsNum && Count < 32;Count++)
		if(pev_valid(g_TEnts[Count][0]) && pev_valid(g_TEnts[Count][1]))
		{
			engfunc(EngFunc_RemoveEntity,g_TEnts[Count][0])
			engfunc(EngFunc_RemoveEntity,g_TEnts[Count][1])
		}
	
	Ent = 0
	Num = 0
	ScannedNum = 0
	Total = CTNum
	while((Ent = engfunc(EngFunc_FindEntityByString,Ent,String,g_CTSpawn)) != 0 && ScannedNum < g_CTEntsNum && Total < g_CTTarget)
		if(pev(Ent,pev_iuser2))
		{		
			Num = 0
			if(!FindEmptyLoc(CTEnt,Origin,Num,g_CTSpawn))
				break
			
			engfunc(EngFunc_SetOrigin,g_CTEnts[ScannedNum][0],Origin)
			engfunc(EngFunc_SetOrigin,g_CTEnts[ScannedNum++][1],Origin)
			
			Total++
		}

	for(new Count = ScannedNum;Count < g_CTEntsNum && Count < 32;Count++)
		if(pev_valid(g_CTEnts[Count][0]) && pev_valid(g_CTEnts[Count][1]))
		{
			engfunc(EngFunc_RemoveEntity,g_CTEnts[Count][0])
			engfunc(EngFunc_RemoveEntity,g_CTEnts[Count][1])
		}
}

public plugin_precache()
{
	new ConfigsDir[64],MapName[33]
	get_configsdir(ConfigsDir,63)
	get_mapname(MapName,32)
	
	copy(g_FileName,127,ConfigsDir)
	add(g_FileName,127,g_Directory)
	add(g_FileName,127,"default.ini")
	
	new File = fopen(g_FileName,"rt+")
	if(!File)
		return
		
	LoadFile(File,1)
	
	copy(g_FileName,127,ConfigsDir)
	add(g_FileName,127,g_Directory)
	add(g_FileName,127,MapName)
	add(g_FileName,127,".ini")
	
	File = fopen(g_FileName,"rt+")
	File ? LoadFile(File,1) : write_file(g_FileName,"")
	
	for(new Count;Count < g_TTarget && Count < 32;Count++)
	{
		g_TEntsNum++
		CreateSpawn(TEAM_T - 1,Float:{4096.0,4096.0,4096.0},g_TEnts[Count])
		
		set_pev(g_TEnts[Count][0],pev_iuser2,1)
	}	
	for(new Count;Count < g_CTTarget && Count < 32;Count++)
	{
		g_CTEntsNum++
		CreateSpawn(TEAM_CT - 1,Float:{4096.0,4096.0,4096.0},g_CTEnts[Count])		
		
		set_pev(g_CTEnts[Count][0],pev_iuser2,1)
	}
}
	
FindEmptyLoc(Ent,Float:Origin[3],&Num,Spawn[])
{
	if(Num++ > 20)
		return 0
	
	new Float:pOrigin[3]
	pev(Ent,pev_origin,pOrigin)
	
	if(!g_DistanceLimit)
		g_DistanceLimit = -500.0
	
	for(new Count;Count < 2;Count++)
		pOrigin[Count] += random_num(-floatround(g_DistanceLimit),floatround(g_DistanceLimit))
	
	new Float:Result[3],Float:End[3]
	End = pOrigin
	End[2] = -8000.0
	
	engfunc(EngFunc_TraceLine,pOrigin,End,1,-1,0)
	get_tr2(0,TR_vecEndPos,Result)
	
	Result[2] += 36.1
	
	if(EF_PointContents(Result) != CONTENTS_EMPTY && EF_PointContents(Result) != CONTENTS_SKY)
	{
		new Result = FindEmptyLoc(Ent,Origin,Num,Spawn)
		return Result
	}
	
	new TR
	engfunc(EngFunc_TraceHull,Result,Result,0,HULL_HUMAN,0,TR)
	if(get_tr2(TR,TR_StartSolid) || get_tr2(TR,TR_AllSolid) || !get_tr2(TR,TR_InOpen))
	{
		new Result = FindEmptyLoc(Ent,Origin,Num,Spawn)
		return Result
	}
	
	new Ent,Classname[33]
	while((Ent = engfunc(EngFunc_FindEntityInSphere,Ent,Result,25.0)) != 0)
	{
		pev(Ent,pev_classname,Classname,32)
		if(equali(Classname,Spawn) || containi(Classname,"trigger_") != -1)
		{
			new Result = FindEmptyLoc(Ent,Origin,Num,Spawn)
			return Result
		}
	}
	
	Origin = Result

	return PLUGIN_HANDLED
}
	
LoadFile(File,Mode)
{
	new Buffer[128],Temp[3][24],OriginTemp[3][10],Float:Origin[3],Dummy[2]
	while(!feof(File))
	{
		fgets(File,Buffer,127)
		if(equali(Buffer,"spawn",5) && Mode)
		{
			parse(Buffer,Temp[0],1,Temp[1],23,Temp[2],23)
			remove_quotes(Temp[1])
			parse(Temp[1],OriginTemp[0],9,OriginTemp[1],9,OriginTemp[2],9)
			
			for(new Count;Count < 3;Count++)
				Origin[Count] = str_to_float(OriginTemp[Count])
			
			CreateSpawn(str_to_num(Temp[2]),Origin,Dummy)
		}
		else if(equali(Buffer,"t_spawns",8))
		{
			parse(Buffer,Temp[0],1,Temp[1],23)
			g_TTarget = equali(Temp[1],"players") ? (get_maxplayers() / 2) + 1 : str_to_num(Temp[1])
		}
		else if(equali(Buffer,"ct_spawns",9))
		{
			parse(Buffer,Temp[0],1,Temp[1],23)
			g_CTTarget = equali(Temp[1],"players") ? (get_maxplayers() / 2) + 1 : str_to_num(Temp[1])
		}
		else if(equali(Buffer,"buyzone_disable",15))
		{
			parse(Buffer,Temp[0],1,Temp[1],23)
			g_BuyzoneDisable = str_to_num(Temp[1])
		}
		else if(equali(Buffer,"distance_limit",14))
		{
			parse(Buffer,Temp[0],1,Temp[1],23)
			g_DistanceLimit = str_to_float(Temp[1])
		}
	}
	
	fclose(File)
}

CreateSpawn(Team,Float:Origin[3],Ents[2])
{
	new Ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,Team ? g_CTSpawn : g_TSpawn)),Retn[2]
	if(!Ent)
		return 0
		
	Retn[0] = Ent
	
	//set_pev(Ent,pev_classname,Team ? g_CTSpawn : g_TSpawn)
	//engfunc(EngFunc_SetSize,Ent,Float:{-1.0,-1.0,-1.0},Float:{1.0,1.0,1.0})
	
	new Float:Mins[3],Float:Maxs[3]
	Mins = Origin
	Maxs = Origin
	
	for(new Count;Count < 3;Count++)
	{	
		Mins[Count]--
		Maxs[Count]++
	}
	
	set_pev(Ent,pev_absmin,Mins)	
	set_pev(Ent,pev_absmax,Maxs)
	engfunc(EngFunc_SetOrigin,Ent,Origin)
	
	new Float:Angles[3]
	Angles[1] = random_float(-90.0,90.0)
	set_pev(Ent,pev_fixangle,1)
	set_pev(Ent,pev_angles,Angles)
	set_pev(Ent,pev_iuser1,1)
	
	dllfunc(DLLFunc_Spawn,Ent)
	
	if(g_BuyzoneDisable)
		return 1
	
	Ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,g_Buyzone))
	if(!Ent)
		return 0
	
	Retn[1] = Ent
		
	set_pev(Ent,pev_team,Team + 1)
	dllfunc(DLLFunc_Spawn,Ent)
	engfunc(EngFunc_SetOrigin,Ent,Origin)
	engfunc(EngFunc_SetSize,Ent,Float:{-128.0,-128.0,-64.0},Float:{128.0,128.0,64.0})
	set_pev(Ent,pev_owner,Retn[0])
	
	Ents = Retn
	
	return 1
}
