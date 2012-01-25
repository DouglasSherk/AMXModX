/*

Copyleft 2006
Plugin thread: http://forums.alliedmods.net/showthread.php?t=18237

GAME STATUS HUD DISPLAY
=======================

Description
This plugin is designed to tell you what's going on for the server, its FPS, 
and everyone's ping. It is basically an extension of EKS' Server Performance Monitor.

Commands
amx_gamestatus - turns on the display
say /gamestatus - turns on the display

Changelog:

	???  , 2005 - v1.0 - Release
	???  , 2005 - v1.1 - Fixed errors that I forget
	???  , 2006 - v2.0 - Total rewrite to fix errors and add new features
	Nov 30, 2006 - v2.1 - Added HUD_CHANNEL_x defines
	Dec 1, 2006 - v2.2 - Fixed HUD flickering and ported to pcvars, sync huds, and optimizations
	
*/

// You probably shouldn't change this if you want the FPS to be accurate
#define INTERVAL 		1.0

// You probably shouldn't change these.
#define ADMIN 			2
#define CLIENT 			1

// What access is needed for the admin section.
#define ADMIN_ACCESS 		ADMIN_KICK

// For GetPing() function
#define PING 			1
#define LOSS 			2

// For GetPlayers() function
enum
{
	LIVE_PLAYERS = 1,
	BOTS,
	CONNECTING_PLAYERS,
	CONNECTED_PLAYERS,
	TOTAL_PLAYERS,
	ADMINS,
	TERRORIST,
	CT,
	SPECTATOR,
	ALIVE_TERRORIST,
	ALIVE_CT
}

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike> 

new g_ClientFPS[33]
new g_ServerFPS[33]

// This also contains their access. If it's 1, they're a client. 2 is admin.
new g_HudOn[33]

// This contains the lag chat instances
new g_LagChat

new g_MainHud
new g_AuxHud

new g_Cstrike

new p_Cvars[18]
new p_On

new g_HudMessage[1024]

#if !defined CreateHudSyncObj
native CreateHudSyncObj(num=0, ...)
#endif

#if !defined ShowSyncHudMsg
native ShowSyncHudMsg(target, syncObj, const fmt[], ...)
#endif

public plugin_init()
{
	register_plugin("Game Status HUD Display","2.2","Hawk552")
	
	register_clcmd("say /gamestatus","GameCommand")
	register_clcmd("amx_gamestatus","GameCommand")
	
	register_clcmd("say","HookSay")
	register_clcmd("say_team","HookSay")
	
	p_On = register_cvar("amx_gamestatus","1")
	
	// Add the flags together. 1 = CLIENT, 2 = ADMIN. 
	// For both, use 3 (1+2=3)	
	p_Cvars[0] = register_cvar("amx_gamestatus_ping","3")
	p_Cvars[1] = register_cvar("amx_gamestatus_loss","3")
	p_Cvars[2] = register_cvar("amx_gamestatus_avgping","2")
	p_Cvars[3] = register_cvar("amx_gamestatus_avgloss","2")
	p_Cvars[4] = register_cvar("amx_gamestatus_lagchat","2")
	p_Cvars[5] = register_cvar("amx_gamestatus_liveplayers","3")
	p_Cvars[6] = register_cvar("amx_gamestatus_bots","3")
	p_Cvars[7] = register_cvar("amx_gamestatus_connectingplayers","3")
	p_Cvars[8] = register_cvar("amx_gamestatus_connectedplayers","3")
	p_Cvars[9] = register_cvar("amx_gamestatus_totalplayers","3")
	p_Cvars[10] = register_cvar("amx_gamestatus_serverfps","2")
	p_Cvars[11] = register_cvar("amx_gamestatus_clientfps","3")
	p_Cvars[12] = register_cvar("amx_gamestatus_adminsonline","2")
	
	new ModName[33]
	get_modname(ModName,32)
	
	if(equali(ModName,"cstrike") || equali(ModName,"czero"))
		g_Cstrike = 1
	
	if(g_Cstrike)
	{
		p_Cvars[13] = register_cvar("amx_gamestatus_ts","3")
		p_Cvars[14] = register_cvar("amx_gamestatus_cts","3")
		p_Cvars[15] = register_cvar("amx_gamestatus_specs","3")
		p_Cvars[16] = register_cvar("amx_gamestatus_tsalive","3")
		p_Cvars[17] = register_cvar("amx_gamestatus_ctsalive","3")
	}
	
	g_MainHud = CreateHudSyncObj()
	g_AuxHud = CreateHudSyncObj()
	
	register_forward(FM_StartFrame,"ForwardStartFrame")
	register_forward(FM_PlayerPostThink,"ForwardPlayerPostThink")
}

public client_disconnect(id)
{
	g_HudOn[id] = 0
	#if defined FPS_MODE
	g_ClientFPS[id] = 0
	g_ServerFPS[id] = 0
	#endif
}

public GameCommand(id)
{
	if(!get_pcvar_num(p_On))
		return PLUGIN_CONTINUE
	
	new bool:Admin = (get_user_flags(id) & ADMIN_ACCESS) ? true : false
	
	if(!g_HudOn[id])
	{
		g_HudOn[id] = Admin ? ADMIN : CLIENT
			
		client_print(id,print_chat,"[AMXX] You have enabled your status display.")
		
		set_task(INTERVAL,"ShowDisplay",id)
	}
	else
	{
		g_HudOn[id] = 0
		
		client_print(id,print_chat,"[AMXX] You have disabled your status display.")
	}
		
	return PLUGIN_HANDLED
}

public HookSay(id)
{
	new Args[256]
	read_args(Args,255)
	
	if(containi(Args,"lag") != -1)
		g_LagChat++
}

public ShowDisplay(id)
{	
	if(!is_user_connected(id) || !g_HudOn[id] || !get_pcvar_num(p_On))
		return PLUGIN_CONTINUE
	
	// It doesn't hurt too much, and it's really not good to do it twice, so we'll
	// just do it anyways.
	new Ping, Loss, Pos
	get_user_ping(id,Ping,Loss)
	
	Pos += format(g_HudMessage,sizeof g_HudMessage - 1,"Game Status^n")
		
	if(get_pcvar_num(p_Cvars[0]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nPing: %i",Ping)
		
	if(get_pcvar_num(p_Cvars[1]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nLoss: %i",Loss)
		
	if(get_pcvar_num(p_Cvars[2]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nAverage Ping: %i",GetPing(PING))
		
	if(get_pcvar_num(p_Cvars[3]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nAverage Loss: %i",GetPing(LOSS))
		
	if(get_pcvar_num(p_Cvars[4]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^n^"Lag^" in Chat: %i",g_LagChat)
	
	if(get_pcvar_num(p_Cvars[5]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^n^nLive Players: %i",GetPlayers(LIVE_PLAYERS))
	
	if(get_pcvar_num(p_Cvars[6]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nBots: %i",GetPlayers(BOTS))
		
	if(get_pcvar_num(p_Cvars[7]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nConnecting Players: %i",GetPlayers(CONNECTING_PLAYERS))
		
	if(get_pcvar_num(p_Cvars[8]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nConnected Players: %i",GetPlayers(CONNECTED_PLAYERS))
	
	if(get_pcvar_num(p_Cvars[9]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nTotal Players: %i",GetPlayers(TOTAL_PLAYERS))
		
	if(get_pcvar_num(p_Cvars[10]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nAdmins Online: %i",GetPlayers(ADMINS))
		
	if(get_pcvar_num(p_Cvars[11]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^n^nClient FPS: %i",g_ClientFPS[id])
		
	if(get_pcvar_num(p_Cvars[12]) & g_HudOn[id])
		Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nServer FPS: %i",g_ServerFPS[id])
		
	g_ClientFPS[id] = 0
	g_ServerFPS[id] = 0
	
	set_hudmessage(255,255,255,0.01,0.12,0,INTERVAL * 2,INTERVAL * 2,0.01,0.01,-1)
	ShowSyncHudMsg(id,g_MainHud,g_HudMessage)
	
	Pos = 0
	g_HudMessage[0] = 0
	
	if(g_Cstrike)
	{
		if(get_pcvar_num(p_Cvars[13]) & g_HudOn[id])
			Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nTerrorists: %i",GetPlayers(TERRORIST))
			
		if(get_pcvar_num(p_Cvars[14]) & g_HudOn[id])
			Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nCTs: %i",GetPlayers(CT))
			
		if(get_pcvar_num(p_Cvars[15]) & g_HudOn[id])
			Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nSpectators: %i",GetPlayers(SPECTATOR))
			
		if(get_pcvar_num(p_Cvars[16]) & g_HudOn[id])
			Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nLive Terrorists: %i",GetPlayers(ALIVE_TERRORIST))
		
		if(get_pcvar_num(p_Cvars[17]) & g_HudOn[id])
			Pos += format(g_HudMessage[Pos],sizeof g_HudMessage - 1 - Pos,"^nLive CTs: %i",GetPlayers(ALIVE_CT))
		
		set_hudmessage(255,255,255,1.0,0.12,0,INTERVAL + 0.1,INTERVAL + 0.1,0.01,0.01,-1)
		ShowSyncHudMsg(id,g_AuxHud,g_HudMessage)
	}
		
	set_task(INTERVAL,"ShowDisplay",id)
	
	return PLUGIN_CONTINUE
}
		
GetPing(Mode)
{
	new Playersnum,Players[32],Player,Count,Ping,Loss,Average
	get_players(Players,Playersnum,"c")
		
	for(Count = 0;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		
		get_user_ping(Player,Ping,Loss)
		
		switch(Mode)
		{
			case PING : Average += Ping
			case LOSS : Average += Loss
		}
	}
	
	return Average / Playersnum
}

GetPlayers(Mode)
{
	new Playersnum,Players[32]
	switch(Mode)
	{
		case LIVE_PLAYERS : 
			get_players(Players,Playersnum,"a")
		case BOTS : 
			get_players(Players,Playersnum,"d")
		// No function for this :(
		case CONNECTING_PLAYERS : 
		{
			new Count
			new Num
			Playersnum = get_playersnum(1)
			
			for(Count = 0;Count <= Playersnum;Count++)
				if(is_user_connecting(Count))
					Num++
			
			Playersnum = Num
		}
		// No function for this either :(
		case CONNECTED_PLAYERS :
		{
			new Count
			new Num
			Playersnum = get_playersnum()
			
			for(Count = 0;Count <= Playersnum;Count++)
				if(is_user_connected(Count))
					Num++
			
			Playersnum = Num
		}
		case TOTAL_PLAYERS : Playersnum = get_playersnum(1)
		// No function for this either :(
		case ADMINS :
		{
			new Count
			new Num
			Playersnum = get_playersnum()
			
			for(Count = 0;Count <= Playersnum;Count++)
				if(is_user_admin(Count))
					Num++
			
			Playersnum = Num
		}
		case TERRORIST:
			get_players(Players,Playersnum,"e","TERRORIST")
		case CT:
			get_players(Players,Playersnum,"e","CT")
		case SPECTATOR:
			get_players(Players,Playersnum,"e","SPECTATOR")
		case ALIVE_TERRORIST:
			get_players(Players,Playersnum,"ae","TERRORIST")
		case ALIVE_CT:
			get_players(Players,Playersnum,"ae","CT")
	}
	
	return Playersnum
}

public ForwardPlayerPostThink(id)
	if(get_pcvar_num(p_On) && is_user_alive(id) && g_HudOn[id])
		g_ClientFPS[id]++
	
public ForwardStartFrame()
{
	if(!get_pcvar_num(p_On))
		return FMRES_IGNORED
	
	new Count,Playersnum,Players[32],Player
	get_players(Players,Playersnum,"c")
	
	for(Count = 0;Count <= Playersnum;Count++)
	{
		Player = Players[Count]
		if(g_HudOn[Player])
			g_ServerFPS[Player]++
	}
	
	return FMRES_IGNORED
}
