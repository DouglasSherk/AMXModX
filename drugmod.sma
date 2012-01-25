/*

Copyleft 2007
Plugin thread: http://forums.alliedmods.net/showthread.php?t=16328

DRUG MOD
========

Description
This is a plugin designed to go alongside Harbu RP which attempts to 
bring some extra drug effects to the roleplaying. There are 6 drugs 
included: crack, heroin, PCP, mushrooms (colloquially "shrooms"), 
cocaine and acid.

Commands
This is installed like any other item plugin. 
The item IDs do not matter (any should work) 
and the syntax for each is:

item_drug_crack <id>
item_drug_heroin <id>
item_drug_pcp <id>
item_drug_mushroom <id>
item_drug_cocaine <id>
item_drug_acid <id>

Here are how each of them work:
Crack: Gives a short speed boost, halves health, gives blue screen fade
Heroin: Gives purple screen fade, sets health to 75 and gives short 
speed boost
PCP: Gives god mode temporarily with a green screen fade and short 
speed loss and +100 HP
Mushroom: Short speed loss with a short hallucination effect 
(random effects all around the player)
Cocaine: Short speed loss with +30 HP.
Acid: Long speed loss with a long hallucination effect 
(random effects all around the player)

Credits
Zack (from Zack's City) - original idea
HaTeR (from Zack's City) - original idea

Changelog:

	Jan 18, 2007 - v1.0 - Release
	Jan 19, 2007 - v1.1 - [BUG] Fixed effects appearing after death
	
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <fun>

#define GETID new id = GetArgs(); if(!id) return PLUGIN_CONTINUE;
#define CHECKUSE if(g_InUse[id]) return client_print(id,print_chat,"[DRUG] You are already using another drug."); g_InUse[id] = 1;

new Float:g_MaxSpeed[33]
new g_SpeedMode[33]
new g_Color[33][3]

new g_InUse[33]

public plugin_init()
{
	new Version[] = "1.1"
	
	register_plugin("Drug Mod",Version,"Hawk552")
	
	register_cvar("drugmod_version",Version,FCVAR_SERVER|FCVAR_SPONLY)
	
	register_srvcmd("item_drug_crack","CmdCrack")
	register_srvcmd("item_drug_heroin","CmdHeroin")
	register_srvcmd("item_drug_pcp","CmdPcp")
	register_srvcmd("item_drug_mushroom","CmdMushroom")
	register_srvcmd("item_drug_cocaine","CmdCocaine")
	register_srvcmd("item_drug_acid","CmdAcid")
	
	register_forward(FM_PlayerPreThink,"ForwardPlayerPreThink")
	
	register_event("DeathMsg","EventDeathMsg","a")
}

public EventDeathMsg()
	ClearEffects(read_data(2))

public client_disconnect(id)
	ClearEffects(id)

public CmdCrack()
{
	GETID
	CHECKUSE
	
	pev(id,pev_maxspeed,g_MaxSpeed[id])
	
	new Float:Health
	g_Color[id] = {0,0,255}
	pev(id,pev_health,Health)
	set_pev(id,pev_health,Health / 2)
	
	ScreenPulse(id)
	
	for(new Float:Count = 2.0;Count <= 10.0;Count += 2.0)
		set_task(Count,"ScreenPulse",id)
	
	set_task(12.0,"ClearEffects",id)
	
	g_SpeedMode[id] = 0
	
	return PLUGIN_CONTINUE
}

public CmdHeroin()
{
	GETID
	CHECKUSE
	
	set_pev(id,pev_health,75.0)
	
	g_Color[id] = {255,0,255}
	
	ScreenPulse(id)
	
	for(new Float:Count = 2.0;Count <= 10.0;Count += 2.0)
		set_task(Count,"ScreenPulse",id)
		
	g_SpeedMode[id] = 1
	
	pev(id,pev_maxspeed,g_MaxSpeed[id])
	
	set_task(12.0,"ClearEffects",id)
	
	return PLUGIN_CONTINUE
}

public CmdPcp()
{
	GETID
	CHECKUSE
	
	new Float:Health
	pev(id,pev_health,Health)
	set_pev(id,pev_health,float(clamp(floatround(Health + 100.0),0,200)))
	
	g_Color[id] = {0,255,0}
	
	set_user_godmode(id,1)
	
	ScreenPulse(id)
	
	for(new Float:Count = 2.0;Count <= 10.0;Count += 2.0)
		set_task(Count,"ScreenPulse",id)
		
	pev(id,pev_maxspeed,g_MaxSpeed[id])
		
	g_SpeedMode[id] = 1
	
	set_rendering(id,kRenderFxGlowShell,255,0,255,kRenderNormal,16)
	
	set_task(12.0,"ClearEffects",id)
	
	return PLUGIN_CONTINUE
}

public CmdMushroom()
{
	GETID
	CHECKUSE
	
	g_SpeedMode[id] = 1
	
	pev(id,pev_maxspeed,g_MaxSpeed[id])
	
	set_rendering(id,kRenderFxGlowShell,0,0,255,kRenderNormal,16)
	
	new Float:Health
	pev(id,pev_health,Health)
	set_pev(id,pev_health,float(clamp(floatround(Health + 50.0),0,200)))
	
	for(new Float:Count = 0.5;Count <= 25.0;Count += 0.5)
		set_task(Count,"Hallucinate",id)
	
	set_task(26.0,"ClearEffects",id)
	
	return PLUGIN_CONTINUE
}	

public CmdCocaine()
{
	GETID
	CHECKUSE
	
	g_SpeedMode[id] = 0
	
	pev(id,pev_maxspeed,g_MaxSpeed[id])
	
	set_task(7.0,"ClearEffects",id)
	
	new Float:Health
	pev(id,pev_health,Health)
	set_pev(id,pev_health,float(clamp(floatround(Health + 30.0),0,200)))
	
	set_rendering(id,kRenderFxGlowShell,255,255,255,kRenderNormal,16)
	
	return PLUGIN_CONTINUE
}

public CmdAcid()
{
	GETID
	CHECKUSE
	
	g_SpeedMode[id] = 1
	
	pev(id,pev_maxspeed,g_MaxSpeed[id])
	
	new Float:Health
	pev(id,pev_health,Health)
	set_pev(id,pev_health,float(clamp(floatround(Health + 50.0),0,200)))
	
	for(new Float:Count = 0.25;Count <= 180.0;Count += 0.5)
		set_task(Count,"Hallucinate",id + 32)
	
	set_task(181.0,"ClearEffects",id)
	
	return PLUGIN_CONTINUE
}	

public ScreenPulse(id)
{
	message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("ScreenFade"),{0,0,0},id)
	write_short(1<<300)
	write_short(1<<300)
	write_short(1<<12)
	write_byte(g_Color[id][0])
	write_byte(g_Color[id][1]) 
	write_byte(g_Color[id][2])
	write_byte(150)
	message_end()
}

GetArgs()
{
	new Args[10]
	read_args(Args,9)
	
	new id = str_to_num(Args)
	
	return is_user_alive(id) ? id : 0
}

public ForwardPlayerPreThink(id)
{
	if(!g_MaxSpeed[id])
		return
	
	set_pev(id,pev_maxspeed,g_SpeedMode[id] ? 180.0 : 400.0)
}

public ClearEffects(id)
{
	if(g_MaxSpeed[id])
	{
		set_pev(id,pev_maxspeed,g_MaxSpeed[id])
		g_MaxSpeed[id] = 0.0
	}
	
	set_user_godmode(id)
	
	set_rendering(id,kRenderFxNone,0,0,0,kRenderNormal,255)
	
	g_InUse[id] = 0
	
	if(task_exists(id))
		remove_task(id)
	
	if(task_exists(id + 32))
		remove_task(id + 32)
}

public Hallucinate(id)
{
	new Mode
	if(id > 32)
	{
		id -= 32
		Mode = 1
		
		set_rendering(id,kRenderFxGlowShell,random_num(0,255),random_num(0,255),random_num(0,255),kRenderNormal,16)
	}
	
	new Origin[3],Num
	FindEmptyLoc(id,Origin,Num)
	
	switch(random_num(0,Mode ? 9 : 4))
	{
		case 0 :
		{			
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id)
			write_byte(TE_GUNSHOT)
			write_coord(Origin[0])
			write_coord(Origin[1])
			write_coord(Origin[2])
			message_end()
		}
		
		case 1 :
		{
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id)
			write_byte(TE_EXPLOSION2)
			write_coord(Origin[0])
			write_coord(Origin[1])
			write_coord(Origin[2])
			write_byte(0)
			write_byte(255)
			message_end()
		}
		
		case 2 :
		{
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id)
			write_byte(TE_IMPLOSION)
			write_coord(Origin[0])
			write_coord(Origin[1])
			write_coord(Origin[2])
			write_byte(255)
			write_byte(255)
			write_byte(20)
			message_end()
		}
		
		case 3 :
		{
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id)
			write_byte(TE_LAVASPLASH)
			write_coord(Origin[0])
			write_coord(Origin[1])
			write_coord(Origin[2])
			message_end()
		}
		
		case 4 :
		{
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id)
			write_byte(TE_TELEPORT)
			write_coord(Origin[0])
			write_coord(Origin[1])
			write_coord(Origin[2])
			message_end()
		}
		
		case 5 :
		{
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id)
			write_byte(TE_SPARKS)
			write_coord(Origin[0])
			write_coord(Origin[1])
			write_coord(Origin[2])
			message_end()
		}
		
		case 6 :
		{
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id)
			write_byte(TE_TAREXPLOSION)
			write_coord(Origin[0])
			write_coord(Origin[1])
			write_coord(Origin[2])
			message_end()
		}
		
		case 7 :
		{
			new Float:Punchangle[3]
			for(new Count;Count < 3;Count++)
				Punchangle[Count] = random_float(-100.0,100.0)
			
			entity_set_vector(id,EV_VEC_punchangle,Punchangle)
		}
		
		case 8 :
		{
			for(new Count;Count < 3;Count++)
				g_Color[id][Count] = random_num(0,255)
			
			ScreenPulse(id)
		}
		
		case 9 :
		{
			message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id)
			write_byte(TE_ARMOR_RICOCHET)
			write_coord(Origin[0])
			write_coord(Origin[1])
			write_coord(Origin[2])
			write_byte(2)
			message_end()
		}			
	}			
}

FindEmptyLoc(id,Origin[3],&Num)
{
	if(Num++ > 100)
		return client_print(id,print_chat,"You are in an invalid position to use this drug.")
	
	new Float:pOrigin[3]
	pev(id,pev_origin,pOrigin)
	
	for(new Count;Count < 2;Count++)
		pOrigin[Count] += random_float(-100.0,100.0)
	
	if(PointContents(pOrigin) != CONTENTS_EMPTY && PointContents(pOrigin) != CONTENTS_SKY)
		return FindEmptyLoc(id,Origin,Num)
	
	Origin[0] = floatround(pOrigin[0])
	Origin[1] = floatround(pOrigin[1])
	Origin[2] = floatround(pOrigin[2])
	
	return PLUGIN_HANDLED
}
