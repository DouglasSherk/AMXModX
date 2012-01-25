#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>

new g_Titanium[33]
new g_Mode[33]

new g_Menu[] = "mTitaniumKevlar"

new p_On
new p_Cost
new p_Activity
new p_Penetration
new p_HelmCost

new g_Text[256]

new g_NormalTR[33]

public plugin_init()
{
	register_plugin("Titanium Kevlar","1.1","Hawk552")
	
	register_concmd("amx_givetitanium","CmdGiveTitanium",ADMIN_KICK,"<user> - gives user titanium armor")
	
	p_On = register_cvar("amx_titanium","1")
	p_Cost = register_cvar("amx_titanium_cost","2000")
	p_HelmCost = register_cvar("amx_titanium_helmetcost","600")
	p_Activity = register_cvar("amx_show_activity","2")
	p_Penetration = register_cvar("amx_titanium_penetration","0")
	
	register_event("DeathMsg","EventDeathMsg","a")
	register_event("ItemPickup","EventItemPickup","b")
	
	register_forward(FM_TraceLine,"ForwardTraceLine",1)
	
	register_menucmd(register_menuid(g_Menu),1023,"MenuHandle")
}

public EventDeathMsg()
	g_Titanium[read_data(2)] = 0
	
public EventItemPickup(id)
{
	if(!get_pcvar_num(p_On) || g_Titanium[id] == 2 || !is_user_alive(id))
		return
	
	new Arg[32],Mode
	read_data(1,Arg,31)
	
	// kevlar + helm
	if(equali(Arg,"item_assaultsuit"))
		Mode = 1
	// kevlar
	else if(equali(Arg,"item_kevlar"))
		Mode = 0
	else
		return
	
	if(!Mode && g_Titanium[id] == 1)
		return
	
	new HelmCost = get_pcvar_num(p_HelmCost),Cost = get_pcvar_num(p_Cost) + HelmCost * Mode
	if(cs_get_user_money(id) < Cost)
		return
	
	g_Mode[id] = Mode
	
	format(g_Text,255,"Buy Titanium Kevlar%s?^n^nThis armor makes the chest%s^ncompletely bullet-proof^nCost: $%d^n^n1. Yes^n2. No^n^n0. Exit",g_Mode[id] ? " and Helmet" : "",g_Mode[id] ? " and head" : "",Cost)
	show_menu(id,MENU_KEY_1|MENU_KEY_2|MENU_KEY_0,g_Text,-1,g_Menu)
}	

public client_disconnect(id)
{
	g_Titanium[id] = 0
	g_NormalTR[id] = 0
}

public CmdGiveTitanium(id,level,cid)
{
	if(id && !cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	new Arg[33]
	read_argv(1,Arg,32)
	
	new Target = cmd_target(id,Arg,1 /* obey immunity*/| /* can do on yourself */ 2| /* must be alive */ 4),Mode
	if(!Target)
		return PLUGIN_HANDLED
	
	read_argv(2,Arg,32)
	if(equali(Arg,"helm") || equali(Arg,"helmet") || equali(Arg,"2") || equali(Arg,"vesthelm"))\
		Mode = 1

	new Name[33],AdminName[33]
	get_user_name(Target,Name,32)
	get_user_name(id,AdminName,32)
	
	switch(get_pcvar_num(p_Activity))
	{
		case 1 :
			client_print(0,print_chat,"ADMIN: Give player %s titanium kevlar%s",Name,Mode ? " and helmet" : "")
		case 2 :			
			client_print(0,print_chat,"ADMIN %s: Give player %s titanium kevlar%s",AdminName,Name,Mode ? " and helmet" : "")
	}
	
	new Authid[36]
	get_user_authid(id,Authid,35)
	
	log_amx("Cmd: ^"%s<%i><%s>^" give player %s titanium kevlar%s",AdminName,id,Authid,Name,Mode ? " and helmet" : "")
	
	g_Titanium[Target] = 1 + Mode
	
	return PLUGIN_HANDLED
}

public ForwardTraceLine(Float:v1[3],Float:v2[3],NoMonsters,EntToSkip,TR)
{
	if(!is_user_alive(EntToSkip))
		return FMRES_IGNORED
	
	if(!g_NormalTR[EntToSkip])
	{
		g_NormalTR[EntToSkip] = TR
		return FMRES_IGNORED
	}
	
	if(g_NormalTR[EntToSkip] == TR)
		return FMRES_IGNORED
	
	new Ent = get_tr(TR_pHit),Hitgroup = get_tr(TR_iHitgroup),Garbage,Weapon = get_user_weapon(EntToSkip,Garbage,Garbage),Button = pev(EntToSkip,pev_button)
	switch(Weapon)
	{
		case CSW_KNIFE,CSW_HEGRENADE,CSW_C4,CSW_FLASHBANG,CSW_SMOKEGRENADE,CSW_VEST,CSW_VESTHELM :
			return FMRES_IGNORED
	}
			
	if(is_user_alive(Ent) && Button & IN_ATTACK && !(Button & IN_RELOAD) && g_Titanium[Ent] && ((Hitgroup == HIT_CHEST || Hitgroup == HIT_STOMACH) || (Hitgroup == HIT_HEAD && g_Titanium[Ent] == 2)))
	{			
		set_tr(TR_flFraction,1.0 - float(clamp(get_pcvar_num(p_Penetration),0,100))/100.0)
		
		new Origin[3]
		get_user_origin(EntToSkip,Origin,3)
		
		emessage_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		ewrite_byte(TE_SPARKS)
		ewrite_coord(Origin[0])
		ewrite_coord(Origin[1])
		ewrite_coord(Origin[2])
		emessage_end()
	}
	
	return FMRES_IGNORED
}

public MenuHandle(id,Key)
{
	new Cost = get_pcvar_num(p_Cost) + get_pcvar_num(p_HelmCost) * g_Mode[id],Money = cs_get_user_money(id)
	
	if(!Key && Money > Cost && is_user_alive(id))
	{
		cs_set_user_money(id,Money - Cost,1)
		client_print(id,print_chat,"[AMXX] You have purchased%s titanium kevlar%s.",g_Mode[id] ? " a" : "",g_Mode[id] ? " and helmet" : "")
		
		g_Titanium[id] = g_Mode[id] + 1
	}
}
