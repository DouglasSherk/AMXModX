#include <amxmodx>
#include <amxmisc>
#include <engine>

/*

Copyleft 2006
Plugin thread: http://www.amxmodx.org/forums/viewtopic.php?t=21370

SPEEDHACK
=========

Description
This plugin is allows you to move across the map at incredible speeds, as well
as lock onto other players and run right into their faces.

Commands
+speed2 - moves fast in the direction user is looking at
+speed3 - moves fast into the nearest player

CVAR amx_speedhack - enables or disables plugin (0/1)
CVAR amx_speedhack_speed - sets speed of speedhack (1-10)
CVAR amx_speedhack_radius - sets radius to detect players in for +speed3 (1-infinite)

Changelog:

	Nov 7, 2005 - v1.0 - Release
	Jun 8, 2006 - v1.1 - Cleaned up code, made more useful
	
*/

enum
{
	// Player is not speedhacking
	NONE = 0,
	// Player is moving forward, or in the direction they're looking
	FORWARD,
	// Player is moving into the closest player
	FOLLOW
}

new g_iSpeed[33]
new g_pSpeedhack
new g_pSpeedhackSpeed
new g_pSpeedhackRadius

public plugin_init()
{
	register_plugin("Speedhack","1.1","Hawk552")
	
	g_pSpeedhack = register_cvar("amx_speedhack","1")
	g_pSpeedhackSpeed = register_cvar("amx_speedhack_speed","5")
	g_pSpeedhackRadius = register_cvar("amx_speedhack_radius","99999")
	
	register_concmd("+speed2","fnSetSpeed",ADMIN_BAN,"- turns speed on while button held")
	register_concmd("-speed2","fnSetSpeed",ADMIN_BAN,"- turns speed off when +speed2 released")
	
	register_concmd("+speed3","fnSetFollow",ADMIN_BAN,"- turns follow on while button held")
	register_concmd("-speed3","fnSetFollow",ADMIN_BAN,"- turns follow off when +follow released")
}

public client_disconnect(id)
	g_iSpeed[id] = false
	
public fnSetSpeed(id,level,cid)
{
	if(!cmd_access(id,level,cid,1) || !get_pcvar_num(g_pSpeedhack))
		return PLUGIN_HANDLED
		
	new szArg[2]
	read_argv(0,szArg,1)
	
	if(szArg[0] == '+')
		g_iSpeed[id] = FORWARD
	else
		g_iSpeed[id] = NONE
		
	return PLUGIN_HANDLED
}

public fnSetFollow(id,level,cid)
{
	if(!cmd_access(id,level,cid,1) || !get_pcvar_num(g_pSpeedhack))
		return PLUGIN_HANDLED
	
	new szArg[2]
	read_argv(0,szArg,1)
	
	if(szArg[0] == '+')
		g_iSpeed[id] = FOLLOW
	else
		g_iSpeed[id] = NONE
		
	return PLUGIN_HANDLED
}	

public client_PreThink(id)
{
	if(g_iSpeed[id] == NONE || !get_pcvar_num(g_pSpeedhack))
		return PLUGIN_CONTINUE
	
	if(g_iSpeed[id] == FORWARD)
	{
		new Float:vVelocity[3],vTargetOrigin[3],vUserOrigin[3],iSpeed = get_pcvar_num(g_pSpeedhackSpeed)
	
		get_user_origin(id,vTargetOrigin,2)
		get_user_origin(id,vUserOrigin,0)
	
		vTargetOrigin[0] -= vUserOrigin[0]
		vTargetOrigin[0] *= iSpeed
	
		vTargetOrigin[1] -= vUserOrigin[1]
		vTargetOrigin[1] *= iSpeed
	
		vTargetOrigin[2] = clamp(vTargetOrigin[2],-20,0)
	
		IVecFVec(vTargetOrigin,vVelocity)
	
		entity_set_vector(id,EV_VEC_velocity,vVelocity)
	}
	else
	{
		new iEnt,Float:vUserOrigin[3],Float:vEntOrigin[3],Float:flRadius = get_pcvar_float(g_pSpeedhackRadius),szClassname[8],Float:vTrace[3],iSpeed = get_pcvar_num(g_pSpeedhackSpeed)
		entity_get_vector(id,EV_VEC_origin,vUserOrigin)
		
		while((iEnt = find_ent_in_sphere(iEnt,vUserOrigin,flRadius)) != 0)
		{
			entity_get_string(iEnt,EV_SZ_classname,szClassname,7)
			if(!equali(szClassname,"player"))
				continue
				
			entity_get_vector(iEnt,EV_VEC_origin,vEntOrigin)
			
			if(!trace_line(id,vUserOrigin,vEntOrigin,vTrace))
				continue
			
			vEntOrigin[0] -= vUserOrigin[0]
			vEntOrigin[0] *= iSpeed
	
			vEntOrigin[1] -= vUserOrigin[1]
			vEntOrigin[1] *= iSpeed
	
			vEntOrigin[2] = float(clamp(floatround(vUserOrigin[2]),-20,0))
			
			entity_set_vector(id,EV_VEC_velocity,vEntOrigin)
			
			break
		}
	}
		
	return PLUGIN_CONTINUE
}
