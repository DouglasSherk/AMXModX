#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine>

new bool:kickflag[33];
new gmsgDeathMsg;
new gmsgScoreInfo;

public plugin_init() 
{
	register_plugin("Jump Kick","1.2","Hawk552");
	
	register_cvar("amx_jumpkick_radius","70.0");
	register_cvar("amx_jumpkick_damage","30.0");
	register_cvar("amx_jumpkick_cooldown","1.0");
	register_cvar("amx_jumpkick_knockback","20");
	register_cvar("amx_jumpkick","1");
	
	gmsgDeathMsg = get_user_msgid("DeathMsg");
	gmsgScoreInfo = get_user_msgid("ScoreInfo");
}

public client_putinserver(id)
	kickflag[id] = false;

public client_disconnect(id)
	kickflag[id] = false;

public client_PreThink(id) 
{
	if(!get_cvar_num("amx_jumpkick"))
	{
		return 0;
	}
	
	if(kickflag[id] == false && (entity_get_int(id, EV_INT_button) & 2))
	{	
		client_cmd(id,"-jump");
		
		new Float:radius = get_cvar_float("amx_jumpkick_radius"),ent,Float:origin[3];
		entity_get_vector(id,EV_VEC_origin,origin);
		
		while((ent = find_ent_in_sphere(ent,origin,radius)) != 0) 
		{
			if(!is_user_alive(ent) || ent == id || get_user_team(id) == get_user_team(ent))
				continue;
			
			kickflag[id] = true;
			set_task(get_cvar_float("amx_jumpkick_cooldown"),"cooldown",id);
			
			damage_ent(ent,id);
		} 
	}
	
	return 0;
}

public damage_ent(vid,aid)
{
	if(is_user_alive(aid) && is_user_alive(vid))
	{
		new Float:vorigin[3],Float:aorigin[3];
		entity_get_vector(vid,EV_VEC_origin,vorigin);
		entity_get_vector(aid,EV_VEC_origin,aorigin);
		
		new i, push_factor = get_cvar_num("amx_jumpkick_knockback");
		
		for(i = 0;i <= 2;i++) 
		{
			vorigin[i] -= aorigin[i];
			vorigin[i] *= push_factor;
		}
		
		entity_set_vector(vid,EV_VEC_velocity,vorigin);
		
		if(get_user_health(vid) < get_cvar_num("amx_jumpkick_damage"))
		{
			createKill(vid,aid,"Jumpkick");
		}
		else
		{
			fakedamage(vid,"Jumpkick",get_cvar_float("amx_jumpkick_damage"),DMG_CRUSH);
			new clip,ammo,weap = get_user_weapon(vid,clip,ammo);
		
			if(weap != CSW_KNIFE && weap != CSW_HEGRENADE && weap != CSW_SMOKEGRENADE && weap != CSW_FLASHBANG)
			{
				client_cmd(vid,"drop");
				client_print(vid,print_chat,"[AMXX] Your weapon has been kicked out of your hands!");
			}
		}
	}
}

public cooldown(id)
	kickflag[id] = false;

// --------------------------------------------------------
// Thanks to Zenith77 for this section and everything below
// --------------------------------------------------------
public createKill(id, attacker, weaponDescription[] ) 
{
	new FFon = get_cvar_num("mp_friendlyfire");
	
	if (FFon && get_user_team(id) == get_user_team(attacker)) 
	{
		set_user_frags(attacker, get_user_frags(attacker) - 1);
		client_print(attacker,print_center,"You killed a teammate");
		new money = cs_get_user_money(attacker);
		if (money != 0) 
			cs_set_user_money(attacker,money - 150,1);
	}
	else if (get_user_team(id) != get_user_team(attacker)) 
	{
		set_user_frags(attacker, get_user_frags(attacker) + 1);
		new money = cs_get_user_money(attacker);
		if (money < 16000) 
			cs_set_user_money(attacker,money + 300,1);
	}
	
	
	logKill(attacker, id, weaponDescription);
	
	//Kill the victim and block the messages
	set_msg_block(gmsgDeathMsg,BLOCK_ONCE);
	set_msg_block(gmsgScoreInfo,BLOCK_ONCE);
	user_kill(id);
	
	//user_kill removes a frag, this gives it back
	set_user_frags(id,get_user_frags(id) + 1);
	
	//Replaced HUD death message
	message_begin(MSG_ALL,gmsgDeathMsg,{0,0,0},0);
	write_byte(attacker);
	write_byte(id);
	write_byte(0);
	write_string(weaponDescription);
	message_end();
	
	//Update killers scorboard with new info
	message_begin(MSG_ALL,gmsgScoreInfo);
	write_byte(attacker);
	write_short(get_user_frags(attacker));
	write_short(get_user_deaths(attacker));
	write_short(0);
	write_short(get_user_team(attacker));
	message_end();
	
	//Update victims scoreboard with correct info
	message_begin(MSG_ALL,gmsgScoreInfo);
	write_byte(id);
	write_short(get_user_frags(id));
	write_short(get_user_deaths(id));
	write_short(0);
	write_short(get_user_team(id));
	message_end();
	
}

// ------- LOG KILL------------

public logKill(id, victim, weaponDescription[] ) 
{
	new namea[32],namev[32],authida[35],authidv[35],teama[16],teamv[16];
	
	//Info On Attacker
	get_user_name(id,namea,31);
	get_user_team(id,teama,15);
	get_user_authid(id,authida,34);
	
	//Info On Victim
	get_user_name(victim,namev,31);
	get_user_team(victim,teamv,15);
	get_user_authid(victim,authidv,34);
	
	//Log This Kill
	if(id != victim) 
	{
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
		namea,get_user_userid(id),authida,teama,namev,get_user_userid(victim),authidv,teamv, weaponDescription );
	}
	else 
	{
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"%s^"",
		namea,get_user_userid(id),authida,teama, weaponDescription );
	}
} 
