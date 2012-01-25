/*

Copyleft 2008
Plugin thread: http://forums.alliedmods.net/showthread.php?p=633284

DUEL MOD
========

Description
This mod is designed to allow dueling, where players challenge each 
other and engage in battle. It is designed for the mod "The Specialists", 
but can be used on other mods.

Commands
say /duel - Will challenge the player being looked at to a duel.
say /accept - Will accept a challenge. Note that you can also use /duel, 
but you must be looking at the person who challenged you. With /accept, 
the last person to challenge you will be accepted.
say /punchingbag - Turns the player into a punching bag 
(requires amx_duel_punchingbag to be set to 1).

Credits
Havoc9 Community - Testing help (specifically SaderBiscut and Jimmy Striker).
Lord_Destros - Testing help.
Steely - Testing help.
sawyer - Testing help.
Frost - Testing help.
coderiz - New semiclip method.
Charming - Encouragement.

Changelog:

	Jun 1, 2008 - v1.0 -	Initial release
	Jun 2, 2008 - v1.1 -	[FIXED] Some repeated variables
				[FIXED] Message printing incorrectly
				[FIXED] Duel off not working properly
				[ADDED] Punching bag mode
				[ADDED] True semiclip
				[ADDED] Attack blocking between 
				duelists <-> players
				[ADDED] God mode to normal players
	Jun 4, 2008 - v1.2 -	[ADDED] Deny command
				[ADDED] Pair command
				[ADDED] Name parameter to /duel command
				[ADDED] Glow cvar
				[FIXED] Messages printing incorrectly
	
*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <fakemeta>
#include <hamsandwich>

new g_Dueling[33]
new g_Challenge[33]
new g_LastChallenge[33]
new g_PlayerSolid[33]
new g_MessageShown[33]
new g_Countdown[33]
new Float:g_Glow[33][3]
new g_Denied[33]
new g_Pair[33]

new g_HudObject

new g_MaxPlayers

new g_Version[] = "1.2"

new p_On
new p_OnlyDuel
new p_BlockKill
new p_Countdown
new p_PunchingBag
new p_Transparency
new p_Glow

new g_Say[11][] = 
{
	"zero",
	"one",
	"two",
	"three",
	"four",
	"five",
	"six",
	"seven",
	"eight",
	"nine",
	"ten"
}

public plugin_init()
{
	register_plugin("Duel Mod",g_Version,"Hawk552")
	register_cvar("duelmod_version",g_Version,FCVAR_SERVER)
	
	register_clcmd("say /accept","CmdAccept")
	register_clcmd("say /punchingbag","CmdPunchingBag")
	register_clcmd("say /deny","CmdDeny")
	register_clcmd("say /pair","CmdPair")
	register_clcmd("say","CmdSay")
	
	RegisterHam(Ham_TakeDamage,"player","_Ham_TakeDamage")
	
	register_forward(FM_TraceLine,"ForwardTraceLine",1)
	register_forward(FM_TraceHull,"ForwardTraceHull",1)
	register_forward(FM_PlayerPreThink,"ForwardPlayerPreThink")
	register_forward(FM_PlayerPostThink,"ForwardPlayerPostThink")
	register_forward(FM_AddToFullPack,"ForwardAddToFullPack",1)
	
	register_event("DeathMsg","EventDeathMsg","a")
	register_event("ResetHUD","EventResetHUD","b")
	
	p_On = register_cvar("amx_duel","1")
	p_OnlyDuel = register_cvar("amx_duel_onlyduel","1")
	p_BlockKill = register_cvar("amx_duel_blockkill","1")
	p_Countdown = register_cvar("amx_duel_countdown","3")
	p_PunchingBag = register_cvar("amx_duel_punchingbag","1")
	p_Transparency = register_cvar("amx_duel_transparency","80")
	p_Glow = register_cvar("amx_duel_glow","2")
	
	g_HudObject = CreateHudSyncObj()
	g_MaxPlayers = get_maxplayers()
}

public ForwardTraceLine(Float:v1[3],Float:v2[3],NoMonsters,SkipEnt,Ptr)
{
	if(!is_user_alive(SkipEnt))
		return FMRES_IGNORED
	
	new Ptr2
	engfunc(EngFunc_TraceLine,v1,v2,NoMonsters,SkipEnt,Ptr2)
	new Hit = get_tr2(0,TR_pHit)
	if(is_user_alive(Hit) && ((Hit != g_Dueling[SkipEnt] && g_Dueling[SkipEnt]) || (!g_Dueling[SkipEnt] && g_Dueling[Hit])))
		set_tr(TR_flFraction,1.0)
	
	return FMRES_IGNORED
}

public ForwardTraceHull(Float:v1[3],Float:v2[3],NoMonsters,Hull,SkipEnt,Ptr)
{
	if(!is_user_alive(SkipEnt))
		return FMRES_IGNORED
	
	new Ptr2
	engfunc(EngFunc_TraceHull,v1,v2,NoMonsters,Hull,SkipEnt,Ptr2)
	new Hit = get_tr2(0,TR_pHit)
	if(is_user_alive(Hit) && ((Hit != g_Dueling[SkipEnt] && g_Dueling[SkipEnt]) || (!g_Dueling[SkipEnt] && g_Dueling[Hit])))
		set_tr(TR_flFraction,1.0)
	
	return FMRES_IGNORED	
}

public client_kill(id)
{
	if(get_pcvar_num(p_BlockKill) && g_Dueling[id] && get_pcvar_num(p_On))
	{
		client_print(id,print_chat,"[DUEL] You cannot kill yourself while dueling.")
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
{
	if(!get_pcvar_num(p_On))
		return
	
	g_MessageShown[id] = 0
	for(new Count;Count < g_MaxPlayers;Count++)
		if(g_Challenge[Count] == id)
			g_Challenge[Count] = 0
	g_LastChallenge[id] = 0
	g_Denied[id] = 0
	g_Pair[id] = 0
	
	if(!g_Dueling[id])
		return
	
	new Name[33],Other = g_Dueling[id]
	get_user_name(id,Name,32)
	
	HudMessage(0,"%s has left while dueling",Name)
	
	g_Dueling[Other] = 0
	g_Dueling[id] = 0
	
	Render(Other,0,Float:{255.0,255.0,255.0})
	set_pev(Other,pev_health,100.0)
}

public _Ham_TakeDamage(id,Inflictor,Attacker,Float:Damage,DamageBits)
{
	if(get_pcvar_num(p_On) && is_user_alive(id) && is_user_alive(Attacker) && (g_Countdown[id] > 1 || (g_Dueling[id] != Attacker && g_Dueling[id]) || (!g_Dueling[id] && g_Dueling[Attacker]) || (get_pcvar_num(p_OnlyDuel) && !g_Dueling[id] && !g_Dueling[Attacker])))
		SetHamParamFloat(4,0.0)
	
	return HAM_IGNORED
}

public CmdPunchingBag(id)
{
	if(!get_pcvar_num(p_On))
	{
		client_print(id,print_chat,"[DUEL] Duel Mod is currently disabled.")
		return PLUGIN_HANDLED
	}		
	
	if(!is_user_alive(id))
	{
		client_print(id,print_chat,"[DUEL] You cannot use this command while dead.")
		return PLUGIN_HANDLED
	}
	
	if(!get_pcvar_num(p_PunchingBag) || !get_pcvar_num(p_OnlyDuel))
	{
		client_print(id,print_chat,"[DUEL] Punching bag mode is currently disabled.")
		return PLUGIN_HANDLED
	}	
	
	if(g_Dueling[id])
	{
		client_print(id,print_chat,"[DUEL] You cannot use punching bag mode while in a duel.")
		return PLUGIN_HANDLED
	}		
	
	new Godmode = !get_user_godmode(id)
	
	set_user_godmode(id,Godmode)
	client_print(id,print_chat,"[DUEL] You are now a %s.",Godmode ? "normal player" : "punching bag")
	
	return PLUGIN_HANDLED
}

public CmdPair(id)
{
	if(!get_pcvar_num(p_On))
	{
		client_print(id,print_chat,"[DUEL] Duel Mod is currently disabled.")
		return PLUGIN_HANDLED
	}
	
	if(g_Dueling[id])
	{
		client_print(id,print_chat,"[DUEL] You cannot pair up while in a duel.")
		return PLUGIN_HANDLED
	}		
	
	if(!is_user_alive(id))
	{
		client_print(id,print_chat,"[DUEL] You cannot use this command while dead.")
		return PLUGIN_HANDLED
	}
	
	g_Pair[id] = !g_Pair[id]
	
	if(g_Pair[id])
		for(new Count;Count < g_MaxPlayers;Count++)
			if(g_Pair[Count] && Count != id && !(g_Denied[Count] & (1<<(id - 1))))
			{
				Accept(Count,id,1)
				g_Pair[id] = 0
				g_Pair[Count] = 0
				
				return PLUGIN_HANDLED
			}
	
	client_print(id,print_chat,"[DUEL] You will %s be paired with the next available player.",g_Pair[id] ? "now" : "no longer")
	
	return PLUGIN_HANDLED
}

public CmdAccept(id)
{
	if(!get_pcvar_num(p_On))
	{
		client_print(id,print_chat,"[DUEL] Duel Mod is currently disabled.")
		return PLUGIN_HANDLED
	}	
	
	if(!is_user_alive(id))
	{
		client_print(id,print_chat,"[DUEL] You cannot use this command while dead.")
		return PLUGIN_HANDLED
	}
	
	if(!g_LastChallenge[id])
	{
		client_print(id,print_chat,"[DUEL] You have not been challenged.")
		return PLUGIN_HANDLED
	}
	
	if(g_Dueling[g_LastChallenge[id]])
	{
		client_print(id,print_chat,"[DUEL] The person who challenged you is already dueling.")
		return PLUGIN_HANDLED
	}
	
	if(!is_user_connected(g_LastChallenge[id]))
	{
		client_print(id,print_chat,"[DUEL] The person who challenged you has left the server.")
		return PLUGIN_HANDLED
	}
	
	if(!is_user_alive(g_LastChallenge[id]))
	{
		client_print(id,print_chat,"[DUEL] The person who challenged you is dead.")
		return PLUGIN_HANDLED
	}
	
	Accept(g_LastChallenge[id],id,0)
	
	return PLUGIN_HANDLED
}	

public CmdDeny(id)
{
	if(!get_pcvar_num(p_On))
	{
		client_print(id,print_chat,"[DUEL] Duel Mod is currently disabled.")
		return PLUGIN_HANDLED
	}
	
	if(!g_LastChallenge[id])
	{
		client_print(id,print_chat,"[DUEL] You have not been challenged.")
		return PLUGIN_HANDLED
	}
	
	if(!is_user_connected(g_LastChallenge[id]))
	{
		client_print(id,print_chat,"[DUEL] The person who challenged you has left the server.")
		return PLUGIN_HANDLED
	}
	
	new Names[2][33]
	get_user_name(id,Names[0],32)
	get_user_name(g_LastChallenge[id],Names[1],32)
	
	g_Denied[id] |= (1<<(g_LastChallenge[id] - 1))
	
	client_print(id,print_chat,"[DUEL] You have denied %s a duel. Say /duel or /accept to him to deactivate deny mode.",Names[1])
	client_print(g_LastChallenge[id],print_chat,"[DUEL] You have been denied a duel by %s.",Names[0])
	
	return PLUGIN_HANDLED
}

Accept(id,Index,Pair)
{
	g_Denied[id] &= ~(1<<(Index - 1))
	g_Denied[Index] &= ~(1<<(id - 1))
	
	g_LastChallenge[id] = 0
	g_LastChallenge[Index] = 0
	
	set_user_godmode(id)
	set_user_godmode(Index)
	
	new Names[2][33]
	get_user_name(id,Names[0],32)
	get_user_name(Index,Names[1],32)
	
	set_pev(id,pev_health,100.0)
	set_pev(Index,pev_health,100.0)
	
	g_Dueling[id] = Index
	g_Dueling[Index] = id
	
	g_Pair[id] = 0
	g_Pair[Index] = 0
	
	g_Challenge[id] = 0
	g_Challenge[Index] = 0
	
	g_Countdown[id] = clamp(get_pcvar_num(p_Countdown),0,10)
	g_Countdown[Index] = g_Countdown[id]
	
	set_task(1.0,"Countdown",id)
	set_task(1.0,"Countdown",Index)
	
	for(new Count;Count < 3;Count++)
	{
		g_Glow[id][Count] = random_float(0.0,255.0)
		g_Glow[Index][Count] = g_Glow[id][Count]
	}
	
	Render(id,1,g_Glow[id])
	Render(Index,1,g_Glow[id])
	
	client_print(id,print_chat,Pair ? "[DUEL] You have been paired with %s." : "[DUEL] %s has accepted your challenge!",Names[1])
	client_print(Index,print_chat,Pair ? "[DUEL] You have been paired with %s." : "[DUEL] You have accepted %s's challenge.",Names[0])
	
	HudMessage(0,"%s has engaged in a duel with %s!",Names[1],Names[0])
}

public Countdown(id)
{
	if(g_Countdown[id])
		set_task(1.0,"Countdown",id)
	else
	{
		HudMessage(id,"The duel has begun!")
		new Float:Glow = g_Glow[id][2],Float:Glow2 = g_Glow[id][1]
		g_Glow[id][2] = g_Glow[id][0]
		g_Glow[id][1] = Glow
		g_Glow[id][0] = Glow2
		Render(id,1,g_Glow[id])
	}
		
	client_cmd(id,"spk fvox/%s",g_Say[g_Countdown[id]--])
}

public EventResetHUD(id)
	set_task(1.0,"ShowGreeting",id)

public ShowGreeting(id)
{
	if(!is_user_alive(id) || !get_pcvar_num(p_On))
		return
	
	if(get_pcvar_num(p_OnlyDuel))
		set_user_godmode(id,1)
	
	if(!g_MessageShown[id])
	{
		client_print(id,print_chat,"[DUEL] This server is running Duel Mod version %s by Doug ^"Hawk552^" Karlmann.",g_Version)
		client_print(id,print_chat,"[DUEL] To begin, say ^"/duel^" in front of a player you want to duel.")
		client_print(id,print_chat,"[DUEL] You can also say ^"/pair^" to duel the next available player.")
		
		g_MessageShown[id] = 1
	}
}

public EventDeathMsg()
{
	if(!get_pcvar_num(p_On))
		return
	
	new id = read_data(2),Other = g_Dueling[id]
	if(g_Dueling[id])
	{
		ForwardPlayerPostThink(id)
		
		g_Dueling[id] = 0
		
		Render(id,0,Float:{255.0,255.0,255.0})
		
		new Names[2][33],Attacker = read_data(1)
		get_user_name(id,Names[0],32)
		get_user_name(Attacker ? Attacker : Other,Names[1],32)
		new Health = get_user_health(Attacker)
		
		if(!Attacker || !is_user_alive(Attacker))
		{
			HudMessage(0,"%s died while dueling",Names[0])
			
			g_Dueling[Other] = 0
			
			Render(Other,0,Float:{255.0,255.0,255.0})
			set_pev(Other,pev_health,100.0)
			
			return
		}
		
		client_print(id,print_chat,"[DUEL] %s has defeated you with %d health remaining.",Names[1],Health)
		client_print(Attacker,print_chat,"[DUEL] You have defeated %s with %d health remaining.",Names[0],Health)
		
		HudMessage(0,"%s was defeated by %s with %d health remaining!",Names[0],Names[1],Health)
		
		Render(Attacker,0,Float:{255.0,255.0,255.0})
		set_task(0.3,"ResetHealth",Attacker)
		
		if(get_pcvar_num(p_OnlyDuel))
			set_user_godmode(Attacker,1)
		
		g_Dueling[Attacker] = 0
	}
}

public ResetHealth(id)
	set_pev(id,pev_health,100.0)

public ForwardAddToFullPack(ES,e,Ent,Host,HostFlags,Player,pSet)
	if(Player && get_pcvar_num(p_On) && is_user_alive(Host) && is_user_alive(Ent) && ((g_Dueling[Host] && Ent != g_Dueling[Host]) || (!g_Dueling[Host] && g_Dueling[Ent])))
	{
		set_es(ES,ES_Solid,SOLID_NOT)
		set_es(ES,ES_RenderMode,kRenderTransAlpha)
		set_es(ES,ES_RenderAmt,clamp(get_pcvar_num(p_Transparency),0,255))
	}
	
public ForwardPlayerPreThink(id)
{
	if(!get_pcvar_num(p_On))
		return FMRES_IGNORED
	
	for(new Count = 1;Count <= g_MaxPlayers;Count++)
	{
		if(!is_user_connected(Count) || Count == id || (!g_Dueling[id] && !g_Dueling[Count]) || g_Dueling[id] == Count)
			continue
		
		g_PlayerSolid[Count] = pev(Count,pev_solid)
		set_pev(Count,pev_solid,SOLID_NOT)
	}
	
	return FMRES_IGNORED
}

public ForwardPlayerPostThink(id)
{
	if(!get_pcvar_num(p_On))
		return FMRES_IGNORED
	
	for(new Count;Count < g_MaxPlayers;Count++)
	{
		if(!is_user_connected(Count) || Count == id || (!g_Dueling[id] && !g_Dueling[Count]) || g_Dueling[id] == Count)
			continue
		
		set_pev(Count,pev_solid,g_PlayerSolid[Count])
	}
	
	return FMRES_IGNORED
}

public CmdSay(id)
{
	new Args[256]
	read_args(Args,255)
	
	remove_quotes(Args)
	trim(Args)
	
	// note that this does NOT mean that it contains no reference of it
	// it means that it's in the first cell
	if(!containi(Args,"/duel"))
	{
		if(!get_pcvar_num(p_On))
		{
			client_print(id,print_chat,"[DUEL] Duel Mod is currently disabled.")
			return PLUGIN_HANDLED
		}
		
		if(g_Dueling[id])
		{
			client_print(id,print_chat,"[DUEL] You are already dueling.")
			return PLUGIN_HANDLED
		}
		
		if(!is_user_alive(id))
		{
			client_print(id,print_chat,"[DUEL] You cannot use this command while dead.")
			return PLUGIN_HANDLED
		}
		
		new Command[64],Index,Body
		read_args(Command,63)
		replace(Command,63,"say","")
		remove_quotes(Command)
		trim(Command)
		replace(Command,63,"/duel","")
		if(strlen(Command))
		{
			trim(Command)
		
			Index = cmd_target(id,Command,0)
			if(!Index)
			{
				client_print(id,print_chat,"[DUEL] Invalid player; please rephrase your input.")
				return PLUGIN_HANDLED
			}
		}
		else
			get_user_aiming(id,Index,Body)
		
		if(!Index || !is_user_alive(Index))
		{
			client_print(id,print_chat,"[DUEL] You are not looking at anyone to challenge.")
			return PLUGIN_HANDLED
		}
		
		if(g_Denied[Index] & (1<<(id - 1)))
		{
			client_print(id,print_chat,"[DUEL] You have been denied by this player.")
			return PLUGIN_HANDLED
		}		
		
		if(g_Dueling[Index])
		{
			client_print(id,print_chat,"[DUEL] That user is already dueling.")
			return PLUGIN_HANDLED
		}
		
		g_Challenge[id] = Index
		g_LastChallenge[Index] = id
		
		new Names[2][33]
		get_user_name(id,Names[0],32)
		get_user_name(Index,Names[1],32)
		
		if(g_Challenge[Index] == id || g_Pair[Index])
		{
			Accept(id,Index,0)
			
			return PLUGIN_HANDLED
		}
		
		client_print(id,print_chat,"[DUEL] You have challenged %s to a duel.",Names[1])
		client_print(Index,print_chat,"[DUEL] You have been challenged to a duel by %s. Look at them and say /duel or say /accept to start!",Names[0])
		
		HudMessage(Index,"%s has challenged you to a duel!",Names[0])
		
		return PLUGIN_HANDLED
	}
	
	if(containi(Args,"duel") != -1 && containi(Args,"/duel") == -1)
		client_print(id,print_chat,"[DUEL] Say /duel to challenge someone.")
	
	return PLUGIN_CONTINUE
}

Render(id,Mode,Float:Glow[3])
{
	new GlowCvar = get_pcvar_num(p_Glow)
	if(GlowCvar)
		return
	
	set_pev(id,pev_renderamt,Mode ? 16.0 : 255.0)
	set_pev(id,pev_rendercolor,Glow)
	switch(GlowCvar)
	{
		case 1 :
		{
			set_pev(id,pev_renderfx,Mode ? kRenderFxGlowShell : kRenderFxNone)
			set_pev(id,pev_rendermode,kRenderNormal)
		}
		case 2 :
		{
			set_pev(id,pev_renderfx,kRenderFxHologram)
			set_pev(id,pev_rendermode,kRenderNormal)
		}
	}
}

HudMessage(id,Message[],{Float,Sql,Result,_}:...)
{
	static Msg[512]
	vformat(Msg,511,Message,3)
	
	set_hudmessage(255,255,255,0.5,-0.8,0,6.0,6.0,0.5,0.15,-1)
	ShowSyncHudMsg(id,g_HudObject,Msg)
}
