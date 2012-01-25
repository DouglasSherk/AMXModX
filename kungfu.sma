#include <amxmodx>
#include <amxmisc>
#include <fun> 
#include <engine>
#include <cstrike>

#define FLURRY_ATTACKS 20

new bool:g_abFu[33]
new bool:g_abCooldown[33]
new g_aFuMeter[33]
new g_szCurMove[33][20]
new g_iMsgDeathMsg
new g_iMsgScoreInfo
new g_szSound1[] = "weapons/cbar_miss1.wav"
new g_szSound2[] = "weapons/cbar_hitbod1.wav"
new g_szSound3[] = "weapons/cbar_hitbod3.wav"

public plugin_init()
{
	register_plugin("KungFu","1.2","Hawk552")
	
	register_cvar("amx_fu_fist","1")
	register_cvar("amx_fu_fist_range","70.0")
	register_cvar("amx_fu_fist_knockback","5")
	register_cvar("amx_fu_fist_damage","15")
	register_cvar("amx_fu_fist_power","5")
	
	register_cvar("amx_fu_kick","1")
	register_cvar("amx_fu_kick_range","100.0")
	register_cvar("amx_fu_kick_knockback","10")
	register_cvar("amx_fu_kick_damage","30")
	register_cvar("amx_fu_kick_power","10")
	
	register_cvar("amx_fu_jumpkick","1")
	register_cvar("amx_fu_jumpkick_knockback","10")
	register_cvar("amx_fu_jumpkick_damage","20")
	
	register_cvar("amx_fu_dragonkick","1")
	register_cvar("amx_fu_dragonkick_damage","50")
	register_cvar("amx_fu_dragonkick_knockback","20")
	register_cvar("amx_fu_dragonkick_power","50")
	
	register_cvar("amx_fu_flurry","1")
	
	register_cvar("amx_fu_meter_regen","20")
	
	register_clcmd("say","fHookSay")
	register_clcmd("say_team","fHookSay")
	
	register_clcmd("say /kungfuhelp","fShowHelp")
	register_clcmd("say_team /kungfuhelp","fShowHelp")
	
	register_event("CurWeapon","fEventCurWeapon","be")
	register_event("DeathMsg","fEventDeathMsg","a")
	
	g_iMsgDeathMsg = get_user_msgid("DeathMsg")
	g_iMsgScoreInfo = get_user_msgid("ScoreInfo")
}

public plugin_precache()
{
	precache_sound(g_szSound1)
	precache_sound(g_szSound2)
	precache_sound(g_szSound3)
}

public client_disconnect(id)
{
	g_abFu[id] = false
	
	g_szCurMove[id][0] = 0
}

public client_putinserver(id)	
{
	set_task(1.0,"fShowFuMeter",id,_,_,"b")
	set_task(1.0,"fSetFuMeter",id,_,_,"b")
	set_task(300.0,"fShowFuMessage",id,_,_,"b")
}

public fShowFuMessage(id)
	client_print(id,print_chat,"[AMXX] Kung Fu is enabled on this server. Say /kungfuhelp for help.")
	
public fShowHelp(id)
{
	new szMotd[1024], iPos
	iPos += format(szMotd[iPos],1023-iPos,"<b>Kung Fu Help</b><br>")
	iPos += format(szMotd[iPos],1023-iPos,"Kung Fu is a replacement for the knife. When you draw your knife, you should see no models.")
	iPos += format(szMotd[iPos],1023-iPos," To use Kung Fu, consult the moves below.<br><br>")
	iPos += format(szMotd[iPos],1023-iPos,"<b>Punch</b><br>")
	iPos += format(szMotd[iPos],1023-iPos,"The most basic move, the punch is a quick attack that deals low damage and requires little energy. (Press Mouse1)<br><br>")
	iPos += format(szMotd[iPos],1023-iPos,"<b>Kick</b><br>")
	iPos += format(szMotd[iPos],1023-iPos,"(Will knock gun out of opponent's hands) The second most basic move, the kick is a quick attack that deals medium damage and requires medium energy. (Press Mouse2)<br><br>")
	iPos += format(szMotd[iPos],1023-iPos,"<b>Dragon Kick</b><br>")
	iPos += format(szMotd[iPos],1023-iPos,"(Will knock gun out of opponent's hands) A more complicated move, the Dragon Kick deals high damage and uses a high amount of energy. It is the most commonly used move. (Press Mouse2 while crouching/ducking)<br><br>")
	iPos += format(szMotd[iPos],1023-iPos,"<b>Jumpkick</b><br>")
	iPos += format(szMotd[iPos],1023-iPos,"(Will knock gun out of opponent's hands) A relatively easy move, the jump kick is more to repel enemies close to you than fight with. (Press Jump while near an enemy)<br><br>")
	iPos += format(szMotd[iPos],1023-iPos,"<b>Flurry of Blows</b><br>")
	iPos += format(szMotd[iPos],1023-iPos,"The Flurry of Blows is a slower and more consistent move. It allows you to punch %i times sequentially without pressing any buttons. (Press Mouse1 and Mouse2 at the same time)<br><br>",FLURRY_ATTACKS)
	iPos += format(szMotd[iPos],1023-iPos,"Have fun!")
	
	show_motd(id,szMotd,"Kung Fu Help")
}
	
public fHookSay(id)
{
	new szArgs[128]
	read_args(szArgs,127)
	
	if(containi(szArgs,"kung") != -1 || containi(szArgs,"fu") != -1 || containi(szArgs,"knife") != -1)
		fShowFuMessage(id)
}

public fShowFuMeter(id)
{
	if(!g_abFu[id])		
		return PLUGIN_CONTINUE
	
	if(g_aFuMeter[id] < 0)
		g_aFuMeter[id] = 0
	else if(g_aFuMeter[id] > 100)
		g_aFuMeter[id] = 100

	new szMessage[128]
	fFuMeterStr(id,szMessage,127)
	
	set_hudmessage(255,255,255,-0.05,-0.05,0,1.0,1.0,1.0,1.0,2)
	show_hudmessage(id,szMessage)
	
	return PLUGIN_CONTINUE
}	

public fSetFuMeter(id)
	g_aFuMeter[id] += get_cvar_num("amx_fu_meter_regen")
	
public fShowCurMove(id)
{
	set_hudmessage(255,255,255,0.45,0.5,0,5.0,5.0,1.0,1.0,4)
	show_hudmessage(id,"%s",g_szCurMove[id])
	
	g_szCurMove[id][0] = 0
}

fFuMeterStr(id,str[],len)
{
	new Float:flFuMeter = float(g_aFuMeter[id])/10.0, iFuMeter = floatround(flFuMeter) * 10
	
	switch(iFuMeter)
	{
		case 0 : format(str,len,"KUNG FU METER: 0%% ^n ~~~~~~~~~~")
		case 10 : format(str,len,"KUNG FU METER: 10%% ^n O~~~~~~~~~")
		case 20 : format(str,len,"KUNG FU METER: 20%% ^n OO~~~~~~~~")
		case 30 : format(str,len,"KUNG FU METER: 30%% ^n OOO~~~~~~~")
		case 40 : format(str,len,"KUNG FU METER: 40%% ^n OOOO~~~~~~")
		case 50 : format(str,len,"KUNG FU METER: 50%% ^n OOOOO~~~~~")
		case 60 : format(str,len,"KUNG FU METER: 60%% ^n OOOOOO~~~~")
		case 70 : format(str,len,"KUNG FU METER: 70%% ^n OOOOOOO~~~")
		case 80 : format(str,len,"KUNG FU METER: 80%% ^n OOOOOOOO~~")
		case 90 : format(str,len,"KUNG FU METER: 90%% ^n OOOOOOOOO~")
		case 100 : format(str,len,"KUNG FU METER: 100%% ^n OOOOOOOOOO")
		
		// It's pretty rare that this will happen, unless of course my code is fucked ;]
		default : format(str,len,"KUNG FU METER: %i%%",g_aFuMeter[id])
	}
	
	return PLUGIN_CONTINUE
}

public fEventCurWeapon(id)
{
	if(is_user_bot(id))
		return PLUGIN_CONTINUE
	
	new iClip, iAmmo, iWeap = get_user_weapon(id,iClip,iAmmo)
	if(iWeap == CSW_KNIFE)
	{
		g_abFu[id] = true
		entity_set_string(id,EV_SZ_viewmodel,"")
		entity_set_string(id,EV_SZ_weaponmodel,"")
		client_cmd(id,"stopsound")
	}
	else 
		g_abFu[id] = false
	
	return PLUGIN_CONTINUE
}

public fEventDeathMsg()
{
	new iVictim = read_data(2)
	
	g_abFu[iVictim] = false
	g_aFuMeter[iVictim] = 100
}

public client_PreThink(id)
{
	if(g_abFu[id])
	{
		new iButton = get_user_button(id)
		
		fCheckAttack(id,iButton)
	}
	
	return PLUGIN_CONTINUE
}

public fCheckAttack(id,iButton)
{
	if((iButton & IN_ATTACK) && (iButton & IN_ATTACK2) && get_cvar_num("amx_fu_flurry"))
	{
		entity_set_int(id,EV_INT_button,IN_CANCEL)
			
		if(!g_abCooldown[id] && g_aFuMeter[id] >= get_cvar_num("amx_fu_fist_power")) 
		{				
			g_abCooldown[id] = true
			
			fShowFuMeter(id)
			
			copy(g_szCurMove[id],19,"Flurry of Blows")
			fShowCurMove(id)
				
			for(new Float:iCount = 0.1;iCount <= FLURRY_ATTACKS/10;iCount += 0.1)
			{
				set_task(iCount,"fFlurryOfBlows",id)
			}
		}
	}
	else if((iButton & IN_ATTACK2) && (iButton & IN_DUCK) && get_cvar_num("amx_fu_dragonkick"))
	{
		entity_set_int(id,EV_INT_button,IN_CANCEL)
			
		if(!g_abCooldown[id] && g_aFuMeter[id] >= get_cvar_num("amx_fu_dragonkick_power")) 
		{
			g_aFuMeter[id] -= get_cvar_num("amx_fu_dragonkick_power")
				
			g_abCooldown[id] = true
			
			fShowFuMeter(id)
			
			copy(g_szCurMove[id],19,"Dragon Kick")
			fShowCurMove(id)
				
			new iIndex,iBody
			get_user_aiming(id,iIndex,iBody,get_cvar_num("amx_fu_kick_range"))
				
			new Float:vVel[3]
				
			for(new i = 0;i <= 2;i++)
				vVel[i] = random_float(-20.0,20.0)	
				
			entity_set_vector(id,EV_VEC_punchangle,vVel)
				
			if(iIndex)
			{
				fDamageEnt(iIndex,id,get_cvar_float("amx_fu_dragonkick_knockback"),get_cvar_float("amx_fu_dragonkick_damage"),"KungFu Dragon Kick",true)
				
				emit_sound(id,CHAN_WEAPON,g_szSound2,1.0,ATTN_NORM,0,PITCH_NORM)
			}
			else
				emit_sound(id,CHAN_WEAPON,g_szSound1,1.0,ATTN_NORM,0,PITCH_NORM)
		}
	}
	else if((iButton & IN_ATTACK) && get_cvar_num("amx_fu_fist"))
	{
		entity_set_int(id,EV_INT_button,IN_CANCEL)
			
		if(!g_abCooldown[id] && g_aFuMeter[id] >= get_cvar_num("amx_fu_fist_power")) 
		{
			g_aFuMeter[id] -= get_cvar_num("amx_fu_fist_power")
				
			g_abCooldown[id] = true
			
			fShowFuMeter(id)
			
			copy(g_szCurMove[id],19,"Punch")
			fShowCurMove(id)
				
			new iIndex,iBody
			get_user_aiming(id,iIndex,iBody,get_cvar_num("amx_fu_fist_range"))
				
			new Float:vVel[3]
				
			for(new i = 0;i <= 2;i++)
				vVel[i] = random_float(-5.0,5.0)	
				
			entity_set_vector(id,EV_VEC_punchangle,vVel)
				
			if(iIndex)
			{
				fDamageEnt(iIndex,id,get_cvar_float("amx_fu_fist_knockback"),get_cvar_float("amx_fu_fist_damage"),"KungFu Fist",false)
				
				emit_sound(id,CHAN_WEAPON,g_szSound2,1.0,ATTN_NORM,0,PITCH_NORM)
			}
			else
				emit_sound(id,CHAN_WEAPON,g_szSound1,1.0,ATTN_NORM,0,PITCH_NORM)
		}
	}
	else if((iButton & IN_ATTACK2) && get_cvar_num("amx_fu_kick"))
	{
		entity_set_int(id,EV_INT_button,IN_CANCEL)
		
		if(!g_abCooldown[id] && g_aFuMeter[id] >= get_cvar_num("amx_fu_kick_power")) 
		{
			g_aFuMeter[id] -= get_cvar_num("amx_fu_kick_power")
							
			g_abCooldown[id] = true
			
			fShowFuMeter(id)
			
			copy(g_szCurMove[id],19,"Kick")
			fShowCurMove(id)
			
			new iIndex,iBody
			get_user_aiming(id,iIndex,iBody,get_cvar_num("amx_fu_kick_range"))
			
			new Float:vVel[3]
			
			for(new i = 0;i <= 2;i++)
				vVel[i] = random_float(-10.0,10.0)
			
			entity_set_vector(id,EV_VEC_punchangle,vVel)
			
			if(iIndex)
			{
				fDamageEnt(iIndex,id,get_cvar_float("amx_fu_kick_knockback"),get_cvar_float("amx_fu_kick_damage"),"KungFu Kick",true)
				
				emit_sound(id,CHAN_WEAPON,g_szSound3,1.0,ATTN_NORM,0,PITCH_NORM)
			}
			else
				emit_sound(id,CHAN_WEAPON,g_szSound1,1.0,ATTN_NORM,0,PITCH_NORM)
		}
	}
	else if(!g_abCooldown[id] && (get_user_button(id) & IN_JUMP) && get_cvar_num("amx_fu_jumpkick"))
	{	
		client_cmd(id,"-jump")
		
		g_abCooldown[id] = true
		
		new Float:flRadius = get_cvar_float("amx_fu_kick_range"),iEnt,Float:vOrigin[3]
		entity_get_vector(id,EV_VEC_origin,vOrigin)
		
		while((iEnt = find_ent_in_sphere(iEnt,vOrigin,flRadius)) != 0) 
		{
			if(!is_user_alive(iEnt) || iEnt == id || get_user_team(id) == get_user_team(iEnt))
				continue
			
			emit_sound(id,CHAN_WEAPON,g_szSound3,1.0,ATTN_NORM,0,PITCH_NORM)
			
			copy(g_szCurMove[id],19,"Jumpkick")
			fShowCurMove(id)
			
			fDamageEnt(iEnt,id,get_cvar_float("amx_fu_jumpkick_knockback"),get_cvar_float("amx_fu_jumpkick_damage"),"KungFu Jumpkick",true)
		} 
	}
	else if(g_abCooldown[id])
		g_abCooldown[id] = false
		
}

public fSetCooldown(id)
	g_abCooldown[id] = false
	
public fFlurryOfBlows(id)
{
	if(!g_abFu[id])
		return PLUGIN_CONTINUE
	
	new iIndex,iBody
	get_user_aiming(id,iIndex,iBody,get_cvar_num("amx_fu_fist_range"))
				
	new Float:vVel[3]
				
	for(new i = 0;i <= 2;i++)
		vVel[i] = random_float(-5.0,5.0)	
				
	entity_set_vector(id,EV_VEC_punchangle,vVel)
	
	g_aFuMeter[id] -= get_cvar_num("amx_fu_fist_power")
				
	if(iIndex)
	{
		fDamageEnt(iIndex,id,get_cvar_float("amx_fu_fist_knockback"),get_cvar_float("amx_fu_fist_damage"),"KungFu Flurry of Blows",false)
				
		emit_sound(id,CHAN_WEAPON,g_szSound2,1.0,ATTN_NORM,0,PITCH_NORM)
	}
	else
		emit_sound(id,CHAN_WEAPON,g_szSound1,1.0,ATTN_NORM,0,PITCH_NORM)
		
	return PLUGIN_CONTINUE
}

fDamageEnt(iVictim,iAttacker,Float:flKnockback,Float:flDamage,szWeapname[],bDrop)
{
	new iFriendlyFire = get_cvar_num("mp_friendlyfire")
	
	if(is_user_alive(iAttacker) && is_user_alive(iVictim))
	{		
		if(iFriendlyFire == 0 && get_user_team(iVictim) == get_user_team(iAttacker))
			return PLUGIN_CONTINUE
		
		g_abCooldown[iAttacker] = true
		
		new Float:vVictimOrigin[3],Float:vAttackerOrigin[3]
		entity_get_vector(iVictim,EV_VEC_origin,vVictimOrigin)
		entity_get_vector(iAttacker,EV_VEC_origin,vAttackerOrigin)
		
		for(new i = 0;i <= 2;i++) 
		{
			vVictimOrigin[i] -= vAttackerOrigin[i]
			vVictimOrigin[i] *= flKnockback
		}
		
		entity_set_vector(iVictim,EV_VEC_velocity,vVictimOrigin)
		
		if(get_user_health(iVictim) < flDamage)
			createKill(iVictim,iAttacker,szWeapname)
		else
		{
			fakedamage(iVictim,szWeapname,flDamage,DMG_CRUSH)
			new iClip,iAmmo,iWeap = get_user_weapon(iVictim,iClip,iAmmo)
			
			if(iWeap != CSW_KNIFE && iWeap != CSW_HEGRENADE && iWeap != CSW_SMOKEGRENADE && iWeap != CSW_FLASHBANG && bDrop)
			{
				client_cmd(iVictim,"drop")
				client_print(iVictim,print_chat,"[AMXX] Your weapon has been knocked out of your hands!")
			}
		}
	}
	
	return PLUGIN_CONTINUE
}

// --------------------------------------------------------
// Thanks to Zenith77 for this section and everything below
// --------------------------------------------------------
public createKill(id, attacker, weaponDescription[] ) 
{
	new FFon = get_cvar_num("mp_friendlyfire")
	
	if (FFon && get_user_team(id) == get_user_team(attacker)) 
	{
		set_user_frags(attacker, get_user_frags(attacker) - 1)
		client_print(attacker,print_center,"You killed a teammate")
		new money = cs_get_user_money(attacker)
		if (money != 0) 
			cs_set_user_money(attacker,money - 150,1)
	}
	else if (get_user_team(id) != get_user_team(attacker)) 
	{
		set_user_frags(attacker, get_user_frags(attacker) + 1)
		new money = cs_get_user_money(attacker)
		if (money < 16000) 
			cs_set_user_money(attacker,money + 300,1)
	}
	
	
	logKill(attacker, id, weaponDescription)
	
	//Kill the victim and block the messages
	set_msg_block(g_iMsgDeathMsg,BLOCK_ONCE)
	set_msg_block(g_iMsgScoreInfo,BLOCK_ONCE)
	user_kill(id)
	
	//user_kill removes a frag, this gives it back
	set_user_frags(id,get_user_frags(id) + 1)
	
	//Replaced HUD death message
	message_begin(MSG_ALL,g_iMsgDeathMsg,{0,0,0},0)
	write_byte(attacker)
	write_byte(id)
	write_byte(0)
	write_string(weaponDescription)
	message_end()
	
	//Update killers scorboard with new info
	message_begin(MSG_ALL,g_iMsgScoreInfo)
	write_byte(attacker)
	write_short(get_user_frags(attacker))
	write_short(get_user_deaths(attacker))
	write_short(0)
	write_short(get_user_team(attacker))
	message_end()
	
	//Update victims scoreboard with correct info
	message_begin(MSG_ALL,g_iMsgScoreInfo)
	write_byte(id)
	write_short(get_user_frags(id))
	write_short(get_user_deaths(id))
	write_short(0)
	write_short(get_user_team(id))
	message_end()
	
}

// ------- LOG KILL------------

public logKill(id, victim, weaponDescription[] ) 
{
	new namea[32],namev[32],authida[35],authidv[35],teama[16],teamv[16]
	
	//Info On Attacker
	get_user_name(id,namea,31)
	get_user_team(id,teama,15)
	get_user_authid(id,authida,34)
	
	//Info On Victim
	get_user_name(victim,namev,31)
	get_user_team(victim,teamv,15)
	get_user_authid(victim,authidv,34)
	
	//Log This Kill
	if(id != victim) 
	{
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
		namea,get_user_userid(id),authida,teama,namev,get_user_userid(victim),authidv,teamv, weaponDescription )
	}
	else 
	{
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"%s^"",
		namea,get_user_userid(id),authida,teama, weaponDescription )
	}
}
