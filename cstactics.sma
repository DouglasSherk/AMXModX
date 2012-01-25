/*

	Copyleft 2009
	MADE IN CANADA
	Plugin thread: http://forums.alliedmods.net/showthread.php?t=102839

Counter-Strike Tactics
======================

Description:

	This mod converts CS into an FPS/RTS. It does this by adding a commander to each team, who is 
	given the responsibility of buying equipment, resupplying soldiers, and ordering them to their 
	objective. The commander's interface is extremely advanced and follows most conventions that 
	RTS's do (such as the ability to add concurrent waypoints, select/deselect by holding ctrl, 
	assign squads, etc.). The commander is voted in when the mod starts or the previous commander 
	steps down/leaves the game. 

Commands:

	say /help - displays a help MOTD
	say /menu - displays the main menu for players or the commander

Changelog:

	Sep 6, 2009 - v1.0 - Release
	Nov 26, 2009 - v1.1 - Fixed some bugs, added bots
	
Credits:

	VEN - some small snippets of code here and there
	xPaw - money hiding code
	fang - test server and testing help
	dMoN - testing help
	Fal0x - testing help
	Zenith77 - testing help
	
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <engine>
#include <bot_api>

// buyzone bit, by VEN
#define BIT_BUYZONE (1<<0)

// fake buyzone absmin and absmax, by VEN
new Float:gBuyZoneMin[3] = { -8192.0, -8192.0, -8192.0 }
new Float:gBuyZoneMax[3] = { -8191.0, -8191.0, -8191.0 }

/* End VEN */

new gMsgIdIcon
//new gMsgHideWeapon
//new gMsgResetHUD
new gIconName[] = "buyzone"
new gObjectiveClass[] = "cst_objective"
new gObjectiveSprite[] = "sprites/dot.spr"
new gObjectiveSpriteId

new gBuyZone

#define MAX_WAYPOINTS 20

// Offset has the team added to it.
#define VOTE_TASK 9129321
#define BOMB_TASK 9123881

// Thanks to xPaw for this.
#define HUD_MONEY ( 1 << 5 )
new const m_iHideHUD = 361

new gActive

new gCommander[CsTeams]
new gMoney[CsTeams]
new gLastTeleported[CsTeams]
new Float:gAlert[CsTeams][3]
new Float:gLastAlert[CsTeams]
new Float:gLastBuy[CsTeams]
new Float:gLastOrder[CsTeams]
new Float:gLastRadio[33]
new gSelected[33]
new gSquad[33]
new ORDERS:gOrders[33]
//new gBombCarrier
//new gBombSelected
//new gBombDropped
new gBomb
new gRoundFlag
new Float:gBombTime

new gUniqueId[33]

new gBot[33]
new gBotNum
new gFollow[33]

new gObjectiveEnt[33]
new Float:gWaypoints[33][MAX_WAYPOINTS][3]
new gWaypointNum[33]

new gShieldFlag

new pEnabled
new pMinPlayers
new pVoteTime
new pMaxMoney
new pHudX
new pHudY
new pTimer
new pHealthCost
new pAmmoCost
new pBombTime
new pEjectTime
new pEjectPercentage
new pShowVotes
new pTeamObjectives
new pReinforceCost
new pBotCost
new pBotPathfinding
new pBotDifficulty
new pBotLimit

// Not our cvars.
new pRestartRound

new gVoteMenu[CsTeams]
new gVotes[CsTeams][33]

new Float:gLastEjectVote[CsTeams]
new gEjectVotes[CsTeams][2]

new gComMenu
new gSelectMenu
new gOrdersMenu
new gSquadAssignMenu
new gReinforceMenu
new gPlayerMenu
new gEjectMenu

new gLightSprite
new gLaserSprite

//new gAmmoModel[] = "models/cstactics/w_ammopack.mdl"
//new gHealthModel[] = "models/cstactics/w_healthpack.mdl"
new gAmmoModel[] = "models/w_weaponbox.mdl"
new gHealthModel[] = "models/w_medkit.mdl"

new gAmmoClassname[] = "cst_ammopack"
new gHealthClassname[] = "cst_healthpack"

enum HUD
{
	TITLE,
	INFO
}

enum ORDERS
{
	NONE,
	ATTACK,
	DEFEND,
	EQUIP
}

enum SOUNDS
{
	C_NONE,
	C_ATTACK,
	C_DEFEND,
	C_GET,
	C_GIVEORDERS,
	C_GOTOALERT,
	C_GUARD,
	C_MORE,
	C_MOVE1,
	C_MOVE2,
	C_MOVE3,
	C_MOVE4,
	C_NEEDSAMMO1,
	C_NEEDSAMMO2,
	C_NEEDSHEALTH1,
	C_NEEDSHEALTH2,
	C_NEEDSORDER1,
	C_NEEDSORDER2,
	C_ONLINE,
	C_SELECT,
	C_SOLDIERLOST1,
	C_SOLDIERLOST2,
	C_SOLDIERUNDERATTACK,
	C_SQUAD1,
	C_SQUAD2,
	C_SQUAD3,
	C_SQUAD4,
	C_SQUAD5,
	T_C_EJECTED,
	T_COMPLETE1,
	T_COMPLETE2,
	T_COMPLETE3,
	T_COMPLETE4,
	T_COMPLETE5,
	T_COMPLETE6,
	T_NEEDSAMMO1,
	T_NEEDSAMMO2,
	T_NEEDSHEALTH1,
	T_NEEDSHEALTH2,
	T_NEEDSORDER1,
	T_NEEDSORDER2,
	T_SQUAD1,
	T_SQUAD2,
	T_SQUAD3,
	T_SQUAD4,
	T_SQUAD5,
	I_PACK,
	I_HEAL,
	I_AMMO,
	I_WAYPOINT
}

new gSounds[SOUNDS][] =
{
	"items/suitchargeno1.wav",
	"cstactics/commander_attack.wav",
	"cstactics/commander_defend.wav",
	"cstactics/commander_get.wav",
	"cstactics/commander_giveorders.wav",
	"cstactics/commander_gotoalert.wav",
	"cstactics/commander_guard.wav",
	"cstactics/commander_more.wav",
	"cstactics/commander_move1.wav",
	"cstactics/commander_move2.wav",
	"cstactics/commander_move3.wav",
	"cstactics/commander_move4.wav",
	"cstactics/commander_needsammo1.wav",
	"cstactics/commander_needsammo2.wav",
	"cstactics/commander_needshealth1.wav",
	"cstactics/commander_needshealth2.wav",
	"cstactics/commander_needsorder1.wav",
	"cstactics/commander_needsorder2.wav",
	"cstactics/commander_online.wav",
	"cstactics/commander_select.wav",
	"cstactics/commander_soldierlost1.wav",
	"cstactics/commander_soldierlost2.wav",
	"cstactics/commander_soldierunderattack.wav",
	"cstactics/commander_squad1.wav",
	"cstactics/commander_squad2.wav",
	"cstactics/commander_squad3.wav",
	"cstactics/commander_squad4.wav",
	"cstactics/commander_squad5.wav",
	"cstactics/team_commander_ejected.wav",
	"cstactics/team_complete1.wav",
	"cstactics/team_complete2.wav",
	"cstactics/team_complete3.wav",
	"cstactics/team_complete4.wav",
	"cstactics/team_complete5.wav",
	"cstactics/team_complete6.wav",
	"cstactics/team_needsammo1.wav",
	"cstactics/team_needsammo2.wav",
	"cstactics/team_needshealth1.wav",
	"cstactics/team_needshealth2.wav",
	"cstactics/team_needsorder1.wav",
	"cstactics/team_needsorder2.wav",
	"cstactics/team_squad1.wav",
	"cstactics/team_squad2.wav",
	"cstactics/team_squad3.wav",
	"cstactics/team_squad4.wav",
	"cstactics/team_squad5.wav",
	"debris/beamstart9.wav",
	"items/smallmedkit1.wav",
	"items/9mmclip1.wav",
	"items/suitchargeok1.wav"
}

#define MAX_WEAPONS 33

new gCosts[MAX_WEAPONS] = 
{
	0,
	600,
	0,
	2750,
	300,
	3000,
	0,
	1400,
	3500,
	300,
	800,
	750,
	1700,
	4200,
	2000,
	2250,
	500,
	400,
	4750,
	1500,
	5750,
	1700,
	3100,
	1250,
	5000,
	200,
	650,
	3500,
	2500,
	0,
	2350,
	0,
	0
}

new const gAmmo[MAX_WEAPONS][] =
{
	{ -1, -1 },
	{ 13, 52 },
	{ -1, -1 },
	{ 10, 90 },
	{ -1, -1 },
	{ 7, 32 },
	{ -1, -1 },
	{ 30, 100 },
	{ 30, 90 },
	{ -1, -1 },
	{ 30, 120 },
	{ 20, 100 },
	{ 25, 100 },
	{ 30, 90 },
	{ 35, 90 },
	{ 25, 90 },
	{ 12, 100 },
	{ 20, 120 },
	{ 10, 30 },
	{ 30, 120 },
	{ 100, 200 },
	{ 8, 32 },
	{ 30, 90 },
	{ 30, 120 },
	{ 20, 90 },
	{ -1, -1 },
	{ 7, 35 },
	{ 30, 90 },
	{ 30, 90 },
	{ -1, -1 },
	{ 50, 100 },
	{ -1, -1 },
	{ -1, -1 }
}

#define MAX_NAMES 32

new gNames[MAX_NAMES][] =
{
	"Domingo Chavez",
	"John Clark",
	"Logan Keller",
	"Michael Walters",
	"Timothy Hanley",
	"Kazimiera Rakuzanka",
	"Annika Lofquist",
	"Alexandre Noronha",
	"Karl Haider",
	"Pak Suo-Won",
	"Kevin Sweeny",
	"Kure Galanos",
	"Homer Johnston",
	"Jamal Murad",
	"Arkadi Novikov",
	"Alain DuBarry",
	"Genedy Filatov",
	"Louis Loiselle",
	"Andrew Burke",
	"Emilio Narino",
	"Einar Petersen",
	"Lars Beckenbauer",
	"Antonio Maldini",
	"Santiago Arnavisca",
	"Roger McAllen",
	"Daniel Bogart",
	"Gerald Morris",
	"Renee Raymond",
	"Tracy Woo",
	"Jorg Walther",
	"Ayana Yacoby",
	"Sam Fisher"
}

new gVersion[] = "1.1"

public plugin_init()
{
	register_plugin( "CS Tactics", gVersion, "Hawk552" )
	
	register_event( "HLTV", "EventHLTV", "a", "1=0", "2=0" )
	register_event( "Battery", "EventBattery", "b" )
	register_event( "Money", "EventMoney", "b" )
	register_event( "ResetHUD", "EventResetHUD", "b" )
	register_event( "TextMsg", "EventTextMsg", "a", "2=#Game_Commencing" )
	register_event( "DeathMsg", "EventDeathMsg", "a" )
	register_event( "TeamInfo", "EventTeamInfo", "a" )
	register_event( "CurWeapon", "EventCurWeapon", "b", "1=1" )
	register_event( "ItemStatus", "EventItemStatus", "be", "1=2" )
	register_event( "HideWeapon", "EventHideWeapon", "b" )
	//register_event( "WeapPickup", "EventWeapPickup", "be", "1=6" )
	
	register_logevent( "LogEventRoundEnd", 2, "1=Round_End" ) 
	register_logevent( "LogEventRoundStart", 2, "1=Round_Start" ) 
	register_logevent( "LogEventSpawnedWithTheBomb", 3, "2=Spawned_With_The_Bomb" )
	
	//register_logevent( "LogEventDroppedTheBomb", 3, "2=Dropped_The_Bomb" )
	register_cvar( "cst_version", gVersion, FCVAR_SERVER )
	
	pMinPlayers = register_cvar( "cst_min_players", "2" )
	pEnabled = register_cvar( "cst_enabled", "1" )
	pVoteTime = register_cvar( "cst_vote_time", "20" )
	pMaxMoney = register_cvar( "cst_max_money", "-1" )
	pHudX = register_cvar( "cst_hud_x", "0.1" )
	pHudY = register_cvar( "cst_hud_y", "0.1" )
	pTimer = register_cvar( "cst_timer", "0.1" )
	pHealthCost = register_cvar( "cst_health_cost", "500" )
	pAmmoCost = register_cvar( "cst_ammo_cost", "250" )
	pBombTime = register_cvar( "cst_bomb_time", "10" )
	pEjectTime = register_cvar( "cst_eject_time", "120" )
	pEjectPercentage = register_cvar( "cst_eject_percentage", "0.60" )
	pShowVotes = register_cvar( "cst_show_votes", "1" )
	pTeamObjectives = register_cvar( "cst_team_objectives", "1" )
	pReinforceCost = register_cvar( "cst_reinforce_cost", "5000" )
	pBotCost = register_cvar( "cst_bot_cost", "7500" )
	pBotDifficulty = register_cvar( "cst_bot_difficulty", "0.1" )
	pBotPathfinding = register_cvar( "cst_bot_pathfinding", "1" )
	pBotLimit = register_cvar( "cst_bot_limit", "-1" )
	
	// Not our cvars.
	pRestartRound = get_cvar_pointer( "sv_restartround" )
	
	// Health pack.
	register_clcmd( "primammo", "CmdPrimAmmo" )
	register_clcmd( "buyammo1", "CmdPrimAmmo" )
	// Ammo pack.
	register_clcmd( "secammo", "CmdSecAmmo" )
	register_clcmd( "buyammo2", "CmdSecAmmo" )
	
	register_clcmd( "say /help", "CmdHelp", _, "Displays help MOTD for CST mod" )
	register_clcmd( "say /menu", "CmdMenu", _, "Displays player menu for CST mod" )
	
	register_forward( FM_AddToFullPack, "ForwardAddToFullPack", 1 )
	register_forward( FM_CmdStart, "ForwardCmdStart" )
	register_forward( FM_PlayerPostThink, "ForwardPlayerPostThink" )
	register_forward( FM_PlayerPreThink, "ForwardPlayerPreThink" )
	register_forward( FM_SetModel, "ForwardSetModel" )
	register_forward( FM_Touch, "ForwardTouch" )
	register_forward( FM_EmitSound, "ForwardEmitSound" )
	
	//register_touch( gAmmoClassname, "player", "TouchAmmo" )
	//register_touch( gHealthClassname, "player", "TouchHealth" )
	
	RegisterHam( Ham_Spawn, "player", "HamSpawn", 1 )
	RegisterHam( Ham_Use, "grenade", "HamUse" )
	
	set_task( get_pcvar_float( pTimer ), "ShowHUD", _, _, _, "b" )
	set_task( 1.0, "BeamMessages", _, _ ,_, "b" )
	
	//gMsgHideWeapon = get_user_msgid( "HideWeapon" )
	gMsgIdIcon = get_user_msgid( "StatusIcon" )
	//gMsgResetHUD = get_user_msgid( "ResetHUD" )
	
	gBuyZone = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "func_buyzone" ) )
	dllfunc( DLLFunc_Spawn, gBuyZone )
	engfunc( EngFunc_SetSize, gBuyZone, gBuyZoneMin, gBuyZoneMax )
	
	gComMenu = menu_create( "Commander Menu", "ComMenuHandle" )
	menu_additem( gComMenu, "Selection Menu" )
	menu_additem( gComMenu, "Orders Menu" )
	menu_additem( gComMenu, "Squad Assignment Menu" )
	menu_additem( gComMenu, "Reinforcement Menu" )
	menu_additem( gComMenu, "Leave Command Station" )
	
	gSelectMenu = menu_create( "Selection Menu", "SelectMenuHandle" )
	menu_additem( gSelectMenu, "Select Squad 1" )
	menu_additem( gSelectMenu, "Select Squad 2" )
	menu_additem( gSelectMenu, "Select Squad 3" )
	menu_additem( gSelectMenu, "Select Squad 4" )
	menu_additem( gSelectMenu, "Select Squad 5" )
	//menu_additem( gSelectMenu, "Select None" )
	menu_addblank( gSelectMenu, 0 )
	menu_additem( gSelectMenu, "Select Random" )
	menu_additem( gSelectMenu, "Select All" )
	
	gOrdersMenu = menu_create( "Orders Menu", "OrdersMenuHandle" )
	menu_additem( gOrdersMenu, "None/Free" )
	menu_additem( gOrdersMenu, "Attack" )
	menu_additem( gOrdersMenu, "Defend" )
	menu_additem( gOrdersMenu, "Pickup Equipment" )
	
	gSquadAssignMenu = menu_create( "Squad Assignment Menu", "SquadAssignMenuHandle" )
	menu_additem( gSquadAssignMenu, "Assign Squad 1" )
	menu_additem( gSquadAssignMenu, "Assign Squad 2" )
	menu_additem( gSquadAssignMenu, "Assign Squad 3" )
	menu_additem( gSquadAssignMenu, "Assign Squad 4" )
	menu_additem( gSquadAssignMenu, "Assign Squad 5" )
	
	gReinforceMenu = menu_create( "Reinforcements Menu", "ReinforceMenuHandle" )
	menu_additem( gReinforceMenu, "Spawn Dead Player" )
	menu_additem( gReinforceMenu, "Call in Bot" )
	
	gPlayerMenu = menu_create( "Player-Commander Menu", "PlayerMenuHandle" )
	menu_additem( gPlayerMenu, "Need Orders" )
	menu_additem( gPlayerMenu, "Need Ammo" )
	menu_additem( gPlayerMenu, "Need Health" )
	menu_addblank( gPlayerMenu )
	menu_additem( gPlayerMenu, "Vote Eject Commander" )
	
	gEjectMenu = menu_create( "Commander Eject Menu", "EjectMenuHandle" )
	menu_additem( gEjectMenu, "Yes" )
	menu_additem( gEjectMenu, "No" )
}

public CmdHelp( id )
{
	if ( !ModEnabled() )
		return PLUGIN_CONTINUE
	
	static motd[4096]
	if ( !motd[0] )
	{
		new len
		len += format( motd[len], sizeof motd - len - 1, "<style type=^"text/css^"><!--.sty1 {color: #CC9900;font-family: Arial, Helvetica, sans-serif;}--></style><body bgcolor=^"#000000^"><span class=^"sty1^">" )
		len += format( motd[len], sizeof motd - len - 1, "Welcome to Counter-Strike Tactics Mod v%s by Hawk552. Before you get started, you should familiarize yourself with these basic commands:<br><br>", gVersion )
		len += format( motd[len], sizeof motd - len - 1, "<strong>say /help</strong> - brings up this help window<br>" )
		len += format( motd[len], sizeof motd - len - 1, "<strong>say /menu</strong> - brings up the main menu<br>" )
		len += format( motd[len], sizeof motd - len - 1, "<br>The mod centers around the addition of a commander to each team. The commander's job is to buy weapons for the team, order them around, and provide support. " )
		len += format( motd[len], sizeof motd - len - 1, "If you are ordered to do something by your commander, you will see a line indicating the position that the commander expects you to move to, as well as a dot at the end point. " )
		len += format( motd[len], sizeof motd - len - 1, "If you do not follow the commander's orders, he will likely avoid buying you new equipment. If you are voted in to be the commander, there are a number of commands that you should familiarize yourself with: <br><br>" )
		len += format( motd[len], sizeof motd - len - 1, "<strong>left click</strong> - select a team member<br>" )
		len += format( motd[len], sizeof motd - len - 1, "<strong>right click</strong> - order a team member to a destination<br>" )
		len += format( motd[len], sizeof motd - len - 1, "<strong>ctrl</strong> - allows selection of multiple users / place waypoint<br>" )
		len += format( motd[len], sizeof motd - len - 1, "<strong>shift</strong> - enables fast movement<br>" )
		len += format( motd[len], sizeof motd - len - 1, "<strong>reload</strong> - brings up quick-selection menu<br>" )
		len += format( motd[len], sizeof motd - len - 1, "<strong>use</strong> - brings up commander menu<br>" )
		len += format( motd[len], sizeof motd - len - 1, "<strong>space</strong> - move to alert or next player<br>" )
		len += format( motd[len], sizeof motd - len - 1, "<br>Strategy is beyond the scope of this help window and you will have to learn by experience or online guides. Good luck.</span></body>" )
	}
	
	show_motd( id, motd, "Counter-Strike Tactics Mod Help" )
	
	return PLUGIN_HANDLED
}

public CmdMenu( id )
{	
	if ( ModEnabled() )
	{
		menu_display( id, ( gCommander[CS_TEAM_T] == id || gCommander[CS_TEAM_CT] == id ) ? gComMenu : gPlayerMenu )
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

//public EventWeapPickup( id )
//	gBombCarrier = id

public HamUse( c4, id, idActivator, useType, Float:value )
{
	if ( useType != 2 || value != 1.0 || ( gCommander[CS_TEAM_T] != id && gCommander[CS_TEAM_CT] != id ) )
		return HAM_IGNORED
	
	return HAM_SUPERCEDE
}
	
public HamSpawn( id )
{	
	// Should never happen.
	if ( !is_user_alive( id ) )
		return HAM_IGNORED
	
	if ( !gActive && get_pcvar_num( pEnabled ) )
	{
		new players[32], playersNum, numActive, CsTeams:team
		get_players( players, playersNum )
		
		for ( new i; i < playersNum; i++ )
		{
			team = cs_get_user_team( players[i] )
			// If for some reason spectators are being bitches.
			if ( team == CS_TEAM_T || team == CS_TEAM_CT )
				numActive++
		}
		
		if ( numActive >= get_pcvar_num( pMinPlayers ) )
		{
			gActive = 1
			set_pcvar_num( pRestartRound, 1 )
			client_print( 0, print_chat, "[CST] There are enough players to start CST mod. The round is restarting to begin voting." )
		}
	}
	else if ( ModEnabled() )
	{
		new uniqueId = get_user_userid( id )
		if ( gUniqueId[id] != uniqueId )
		{
			client_print( id, print_chat, "[CST] This server is running Counter-Strike Tactics Mod v%s by Hawk552.", gVersion )
			client_print( id, print_chat, "[CST] Say /help to get started." )
			
			gUniqueId[id] = uniqueId
		}
		
		EndObjective( id )
		GiveAmmo( id )
	}
	
	return HAM_IGNORED
}

public EventHideWeapon( id )
	if ( ModEnabled() )
		set_pdata_int( id, m_iHideHUD, read_data( 1 ) | HUD_MONEY )

public BombMenu()
{	
	client_print( gCommander[CS_TEAM_T], print_chat, "[CST] You have %d seconds to decide who will carry the bomb.", get_pcvar_num( pBombTime ) )
	
	new menu = menu_create( "Bomb Menu", "BombMenuHandle" ), players[32], playersNum, player, name[33], idStr[3]
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
	{
		player = players[i]
		if ( player == gCommander[CS_TEAM_T] || cs_get_user_team( player ) != CS_TEAM_T )
			continue
		
		get_user_name( player, name, 32 )
		
		num_to_str( player, idStr, 2 )
		
		menu_additem( menu, name, idStr )
	}
	
	menu_display( gCommander[CS_TEAM_T], menu )
	
	gBombTime = get_gametime()
	//set_task( get_pcvar_float( pBombTime ), "SetBomb", BOMB_TASK )
}

public BombMenuHandle( id, menu, item )
{
	if ( item == MENU_EXIT )
		goto bombEnd
	
	if ( get_gametime() - gBombTime > get_pcvar_num( pBombTime ) )
	{
		client_print( id, print_chat, "[CST] You have waited too long to decide who will carry the bomb. Your team must go the round without it." )
		goto bombEnd
	}
	
	new name[33], idStr[3], player, garbage
	menu_item_getinfo( menu, item, garbage, idStr, 2, name, 32, garbage )
	
	player = str_to_num( idStr )
	
	if ( !player || cs_get_user_team( player ) != CS_TEAM_T || !is_user_alive( player ) )
	{
		client_print( id, print_chat, "[CST] %s is no longer a valid player. Select a new bomb carrier.", name )
		remove_task( BOMB_TASK )
		BombMenu()
		goto bombEnd
	}
	
	client_print( id, print_chat, "[CST] You have selected %s to carry the bomb.", name )
	
	new Float:origin[3]
	pev( player, pev_origin, origin )
	engfunc( EngFunc_SetOrigin, gBomb, origin )
	set_pev( gBomb, pev_velocity, Float:{ 0.0, 0.0, -99999.0 } )
	
	//dllfunc( DLLFunc_Touch, gBomb, player )
	
	//gBombSelected = 1
	
bombEnd:
	menu_destroy( menu )
	return PLUGIN_HANDLED
}

//public SetBomb()
//	gBombSelected = 1

GiveAmmo( id )
{
	new weapon, weaponName[33]
	
	for ( new j; j < MAX_WEAPONS; j++ )
		if ( gAmmo[j][1] != -1 )
		{
			cs_set_user_bpammo( id, j, gAmmo[j][1] )
			if ( user_has_weapon( id, j ) )
			{
				get_weaponname( j, weaponName, 32 )
				while ( ( weapon = engfunc( EngFunc_FindEntityByString, weapon, "classname", weaponName ) ) && pev( weapon, pev_owner ) != id ) { }
				if ( pev_valid( weapon ) )
					cs_set_weapon_ammo( weapon, gAmmo[j][0] )
			}
		}
}

public plugin_log() 
{
	if ( read_logargc() != 2 )
		return

	new arg[16]
	read_logargv( 1, arg, 15 )
	if ( equal( arg, "Restart_Round_(" ) ) 
		EventTextMsg()
}

public ForwardTouch( toucher, touched )
{
	if ( !pev_valid( toucher ) || !is_user_alive( touched ) )
		return FMRES_IGNORED
	
	new className[33]
	pev( toucher, pev_classname, className, 32 )
	
	if ( equali( className, gAmmoClassname ) )
		TouchAmmo( toucher, touched )
	else if ( equali( className, gHealthClassname ) )
		TouchHealth( toucher, touched )
	
	return FMRES_IGNORED
}

TouchAmmo( ent, id )
{
	if ( pev( ent, pev_iuser1 ) != _:cs_get_user_team( id ) )
		return
	
	new weapon = get_user_weapon( id )
	// should never be greater
	if ( cs_get_user_bpammo( id, weapon ) >= gAmmo[weapon][1] )
		return
	
	GiveAmmo( id )
	
	emit_sound( id, CHAN_AUTO, gSounds[I_AMMO], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
	
	engfunc( EngFunc_RemoveEntity, ent )
}

TouchHealth( ent, id )
{
	if ( pev( ent, pev_iuser1 ) != _:cs_get_user_team( id ) || get_user_health( id ) >= 100 )
		return
	
	set_user_health( id, 100 )
	
	emit_sound( id, CHAN_AUTO, gSounds[I_HEAL], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
	
	engfunc( EngFunc_RemoveEntity, ent )
}

public CmdPrimAmmo( id )
{
	new CsTeams:team
	if ( gCommander[CS_TEAM_T] == id )
		team = CS_TEAM_T
	else if ( gCommander[CS_TEAM_CT] == id )
		team = CS_TEAM_CT
	
	if ( !team )
		return PLUGIN_CONTINUE
	
	new Float:curTime = get_gametime()
	if ( curTime - 0.5 < gLastBuy[team] )
		return PLUGIN_CONTINUE	
	
	gLastBuy[team] = curTime
	
	new cost = get_pcvar_num( pHealthCost )
	if ( gMoney[team] < cost )
	{
		client_print( id, print_chat, "[CST] You do not have enough money to buy a health pack." )
		client_cmd( id, "spk %s", gSounds[C_MORE] )
		return PLUGIN_CONTINUE
	}
	
	if ( CreatePack( id, 1 ) )
		cs_set_user_money( id, gMoney[team] -= cost )
	
	return PLUGIN_HANDLED
}

public CmdSecAmmo( id )
{
	new CsTeams:team
	if ( gCommander[CS_TEAM_T] == id )
		team = CS_TEAM_T
	else if ( gCommander[CS_TEAM_CT] == id )
		team = CS_TEAM_CT
	
	if ( !team )
		return PLUGIN_CONTINUE
	
	new Float:curTime = get_gametime()
	if ( curTime - 0.5 < gLastBuy[team] )
		return PLUGIN_CONTINUE	
	
	gLastBuy[team] = curTime
	
	new cost = get_pcvar_num( pAmmoCost )
	if ( gMoney[team] < cost )
	{
		client_print( id, print_chat, "[CST] You do not have enough money to buy an ammo pack." )
		client_cmd( id, "spk %s", gSounds[C_MORE] )
		return PLUGIN_CONTINUE
	}
	
	if ( CreatePack( id, 0 ) )
		cs_set_user_money( id, gMoney[team] -= cost )
	
	return PLUGIN_HANDLED
}

CreatePack( id, mode )
{	
	new Float:origin[3], Float:angle[3], Float:fwd[3], Float:end[3]
	pev( id, pev_origin, origin )  
	pev( id, pev_v_angle, angle ) 
	
	engfunc( EngFunc_MakeVectors, angle ) 
	
	global_get( glb_v_forward, fwd ) 
	
	fwd[0] = origin[0] + fwd[0] * 5000
	fwd[1] = origin[1] + fwd[1] * 5000
	fwd[2] = origin[2] + fwd[2] * 5000
	
	engfunc( EngFunc_TraceLine, origin, fwd, 0, id, 0 )
	get_tr2( 0, TR_vecEndPos, end )
	
	new ent = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) ), CsTeams:team = cs_get_user_team( id ), Float:color[3]
	if ( !ent )
		return 0
	
	color[0] = team == CS_TEAM_T ? 255.0 : 0.0
	color[1] = 0.0
	color[2] = team == CS_TEAM_CT ? 255.0 : 0.0
	
	set_pev( ent, pev_classname, mode ? gHealthClassname : gAmmoClassname )
	engfunc( EngFunc_SetModel, ent, mode ? gHealthModel : gAmmoModel )
	//engfunc( EngFunc_SetOrigin, ent, end )
	//entity_set_vector( ent, EV_VEC_angles, angle )
	engfunc( EngFunc_SetSize, ent, Float:{ -16.0, -16.0, -1.0 }, Float:{ 16.0, 16.0, 1.0 } )
	set_pev( ent, pev_movetype, MOVETYPE_TOSS )
	set_pev( ent, pev_solid, SOLID_TRIGGER )
	set_pev( ent, pev_iuser1, _:team )
	set_pev( ent, pev_renderfx, kRenderFxGlowShell )
	set_pev( ent, pev_rendercolor, color )
	set_pev( ent, pev_rendermode, kRenderNormal )
	set_pev( ent, pev_renderamt, 16.0 )	
	
	end[2] += 10.0
	
	new passes, TR, Float:newEnd[3], startOver
	newEnd = end
	while ( engfunc( EngFunc_TraceMonsterHull, ent, newEnd, newEnd, 0, ent, 0 ) && ( PointContents( newEnd ) != CONTENTS_EMPTY || get_tr2( TR, TraceResult:TR_StartSolid ) || get_tr2( TR, TraceResult:TR_AllSolid ) || !get_tr2( TR, TraceResult:TR_InOpen ) ) )
	{
		//engfunc( EngFunc_TraceHull, newEnd, newEnd, 0, HULL_HUMAN, 0, TR )

		if ( passes++ > 100 )
		{
			// Start over in case we got ourselves in a jam unnecessarily.
			if ( startOver++ < 10 )
			{
				newEnd = end
				passes = 0
			}
			else
			{
				engfunc( EngFunc_RemoveEntity, ent )
				return 0
			}
		}
		
		for ( new i; i < 2; i++ )
			newEnd[i] += random_float( -5.0, 5.0 )
	}

	engfunc( EngFunc_SetOrigin, ent, newEnd )
	
	new location[3]
	FVecIVec( newEnd, location )
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_IMPLOSION )
	write_coord( location[0] )
	write_coord( location[1] )
	write_coord( location[2] )
	write_byte( 50 )
	write_byte( 20 )
	write_byte( 10 )
	message_end()
	
	emit_sound( ent, CHAN_AUTO, gSounds[I_PACK], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
	
	return 1
}

public client_kill( id )
	return ( gCommander[CS_TEAM_T] == id || gCommander[CS_TEAM_CT] == id ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE

public plugin_precache()
{
	gLightSprite = precache_model( "sprites/lgtning.spr" ) 
	gLaserSprite = precache_model( "sprites/laserbeam.spr" )
	
	gObjectiveSpriteId = precache_model( gObjectiveSprite )
	precache_model( gAmmoModel )
	precache_model( gHealthModel )
	
	for ( new SOUNDS:i; i < SOUNDS; i++ )
		precache_sound( gSounds[i] )
}

public EventItemStatus( id )
{
	if ( !ModEnabled() )
		return PLUGIN_CONTINUE

	new CsTeams:team
	if ( gCommander[CS_TEAM_T] == id )
		team = CS_TEAM_T
	else if ( gCommander[CS_TEAM_CT] == id )
		team = CS_TEAM_CT
	
	if ( !team )
		return PLUGIN_CONTINUE
	
	cs_set_user_defuse( id, 0 )
	
	new Float:curTime = get_gametime()
	if ( curTime - 0.5 < gLastBuy[team] )
		return PLUGIN_CONTINUE	
	
	gLastBuy[team] = curTime
	
	new players[32], playersNum, player, teamPlayers[32], teamNum
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
	{
		player = players[i]
		if ( gSelected[player] && cs_get_user_team( player ) == team )
			teamPlayers[teamNum++] = player
	}
	
	new cost = teamNum * 200
	
	if ( !teamNum )
		return PLUGIN_HANDLED
	
	if ( gMoney[team] < cost )
	{
		client_print( id, print_chat, "[CST] You do not have enough money to buy this for everyone you have selected." )
		client_cmd( id, "spk %s", gSounds[C_MORE] )
		return PLUGIN_HANDLED
	}
	for ( new i; i < teamNum; i++ )
		cs_set_user_defuse( teamPlayers[i], 1 )
	
	cs_set_user_money( id, gMoney[team] -= cost )
	
	return PLUGIN_HANDLED
}

public EventBattery( id )
{
	if ( !ModEnabled() )
		return PLUGIN_CONTINUE
		
	new CsTeams:team
	if ( gCommander[CS_TEAM_T] == id )
		team = CS_TEAM_T
	else if ( gCommander[CS_TEAM_CT] == id )
		team = CS_TEAM_CT
	
	if ( !team )
		return PLUGIN_CONTINUE
	
	new CsArmorType:armorType, armorAmount, cost
	armorAmount = cs_get_user_armor( id, armorType )
	
	cs_set_user_armor( id, 0, CS_ARMOR_NONE )
	
	new Float:curTime = get_gametime()
	if ( curTime - 0.5 < gLastBuy[team] )
		return PLUGIN_CONTINUE	
	
	gLastBuy[team] = curTime
	
	switch ( armorType )
	{
		case CS_ARMOR_NONE : 
			return PLUGIN_CONTINUE
		
		case CS_ARMOR_KEVLAR :
			cost = 650
		
		case CS_ARMOR_VESTHELM :
			cost = 1000
	}
	
	new players[32], playersNum, player, teamPlayers[32], teamNum
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
	{
		player = players[i]
		if ( gSelected[player] && cs_get_user_team( player ) == team )
			teamPlayers[teamNum++] = player
	}
	
	cost *= teamNum
	
	if ( !teamNum )
		return PLUGIN_HANDLED
	
	if ( gMoney[team] < cost )
	{
		client_print( id, print_chat, "[CST] You do not have enough money to buy this for everyone you have selected." )
		client_cmd( id, "spk %s", gSounds[C_MORE] )
		return PLUGIN_HANDLED
	}
	
	new CsArmorType:playerArmorType, playerArmorAmount
	for ( new i; i < teamNum; i++ )
	{
		player = teamPlayers[i]		
		
		playerArmorAmount = cs_get_user_armor( player, playerArmorType )
		if ( playerArmorType < armorType || playerArmorAmount < armorAmount )
			cs_set_user_armor( player, armorAmount, armorType )
	}
	
	cs_set_user_money( id, gMoney[team] -= cost )
	
	return PLUGIN_HANDLED
}

public EventCurWeapon( id )
{
	if ( !is_user_alive( id ) )
		return
	
	if ( gCommander[CS_TEAM_T] == id || gCommander[CS_TEAM_CT] == id )
		set_user_maxspeed( id, 420.0 )

#if 0
	if ( gCommander[CS_TEAM_T] && !gBombSelected && gBombCarrier == id && !gBombDropped )
		engclient_cmd( id, "drop", "weapon_c4" )
#endif
}

public EventTeamInfo()
{
	if ( !ModEnabled() )
		return
	
	CheckGame()
	
	new id = read_data( 1 ), name[33], CsTeams:team, CsTeams:newTeam
	if ( gCommander[CS_TEAM_T] == id )
		team = CS_TEAM_T
	else if ( gCommander[CS_TEAM_CT] == id )
		team = CS_TEAM_CT
	
	read_data( 2, name, 32 )
	if ( equali( name, "CT" ) )
		newTeam = CS_TEAM_CT
	else if ( equali( name, "TERRORIST" ) )
		newTeam = CS_TEAM_T
	
	if ( !team || newTeam == team || !newTeam )
		return
	
	get_user_name( id, name, 32 )
	
	SetNormal( id, 0 )
	
	if ( NumActive( team ) > 1 )
	{
		client_print( 0, print_chat, "[CST] %s has left the command station. A vote is being cast to find a new commander.", name )
		
		VoteCommander( team )
	}
	else
		client_print( 0, print_chat, "[CST] %s has left the command station.", name )
}  

public EventDeathMsg()
{
	if ( !ModEnabled() )
		return
	
	new id = read_data( 2 ), CsTeams:team = cs_get_user_team( id ), Float:origin[3]
	pev( id, pev_origin, origin )
	
	SetAlert( team, origin )
	
	if ( gCommander[team] )
		client_cmd( gCommander[team], "spk %s", gSounds[SOUNDS:random_num( _:C_SOLDIERLOST1, _:C_SOLDIERLOST2 )] )
	
	CheckRound( team )
	
	EndObjective( id )
	gSelected[id] = 0
	gOrders[id] = NONE
	if ( gLastTeleported[team] == id )
		gLastTeleported[team] = 0
	UnFollow( id )
}

CheckRound( CsTeams:team )
{
	new players[32], playersNum, player, teamNum
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
	{
		player = players[i]
		if ( cs_get_user_team( player ) == team && player != gCommander[team] && is_user_alive( player ) )
			teamNum++
	}
	
	if ( !teamNum && gCommander[team] )
	{
		cs_set_user_team( gCommander[team], CS_TEAM_SPECTATOR )
		set_task( 0.1, "SetTeam", _:team )
	}
}

public SetTeam( CsTeams:team )
	if ( is_user_connected( gCommander[team] ) )
		cs_set_user_team( gCommander[team], team )

public ForwardSetModel( id, model[] )
{	
	if ( !ModEnabled() || !pev_valid( id ) )
		return FMRES_IGNORED
	
	new className[33]
	pev( id, pev_classname, className, 32 )
	
	if ( equali( className, "weaponbox" ) )
	{
#if 0
		if ( containi( model, "w_backpack.mdl" ) != - 1 && gCommander[CS_TEAM_T] && !gBombSelected && gBombCarrier == id && !gBombDropped )
		{
			gBomb = id
			engfunc( EngFunc_SetOrigin, gBomb, Float:{ 4096.0, 4096.0, 4096.0 } )
			
			gBombDropped = 1
			
			BombMenu()
		}
#endif
		if ( containi( model, "w_shield.mdl" ) != -1 && gShieldFlag )	
		{
			set_task( 0.1, "RemoveGun", id )
			gShieldFlag = 0
		}
	}
	
	return FMRES_IGNORED
}

public RemoveGun( id )
	if ( pev_valid( id ) )
		engfunc( EngFunc_RemoveEntity, id )

public ForwardPlayerPostThink( id )
	if ( is_user_alive( id ) && ModEnabled() && gCommander[CS_TEAM_T] == id || gCommander[CS_TEAM_CT] == id )
		dllfunc( DLLFunc_Touch, gBuyZone, id )

public ForwardAddToFullPack( ES_Handle, e, ent, host, hostFlags, player, pSet )
{
	if ( !ent || !pev_valid( ent ) || !is_user_alive( host ) || !ModEnabled() ) 
		return FMRES_IGNORED

	new className[33], CsTeams:team = cs_get_user_team( host )
	pev( ent, pev_classname, className, 32 )

	if ( equali( className, gObjectiveClass ) )
	{
		new teamObjectives = get_pcvar_num( pTeamObjectives )
		if ( ( teamObjectives && CsTeams:pev( ent, pev_iuser2 ) != team ) || ( !teamObjectives && gCommander[CsTeams:pev( ent, pev_iuser2 )] != host && pev( ent, pev_iuser1 ) != host ) )
		{
			set_es( ES_Handle, ES_RenderMode, kRenderTransAlpha )
			set_es( ES_Handle, ES_RenderAmt, 0 )
		}
	}
	else if ( is_user_alive( ent ) && ( gCommander[CS_TEAM_T] == host || gCommander[CS_TEAM_CT] == host ) )
	{
		new amount = 16, players[32], playersNum, id, CsTeams:entTeam = cs_get_user_team( ent ), canSee
		get_players( players, playersNum )
		
		for ( new i; i < playersNum; i++ )
		{
			id = players[i]
			if ( id != host && is_user_alive( id ) && cs_get_user_team( id ) == team && IsVisible( id, ent ) && ent != gCommander[CS_TEAM_T] && ent != gCommander[CS_TEAM_CT] )
			{
				canSee = 1
				break
			}
		}
		
		if ( !canSee )
			amount = 0
		
		new color[3]
		if ( gSelected[ent] && team == entTeam )
		{
			color[0] = 255
			color[1] = 255
			color[2] = 255
		}
		else
		{
			color[0] = entTeam == CS_TEAM_T ? 255 : 0
			color[1] = 0
			color[2] = entTeam == CS_TEAM_CT ? 255 : 0
		}
		
		if ( canSee )
		{
			set_es( ES_Handle, ES_RenderFx, kRenderFxGlowShell )
			set_es( ES_Handle, ES_RenderColor, color )
		}
		else
			set_es( ES_Handle, ES_RenderMode, kRenderTransAlpha )
		
		set_es( ES_Handle, ES_RenderAmt, amount )
	}

	return FMRES_IGNORED
}

#if 0
EndSprite( id, origin[3] )
{
	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, id )
	write_byte( TE_SPRITE )
	write_coord( origin[0] )
	write_coord( origin[1] )
	write_coord( origin[2] )
	write_short( gEndSprite )
	write_byte( 10 )
	write_byte( 20 )
	message_end()
}
#endif

public bot_think( id )
{
	if ( !is_user_alive( id ) )
		return
	
	new Float:origin[3], CsTeams:team = cs_get_user_team( id )
	
	if ( is_user_alive( gFollow[id] ) )
		pev( gFollow[id], pev_origin, origin )
	
	new players[32],playersNum, player, clip, ammo, weapon = get_user_weapon( id, clip, ammo ), button, Float:difficulty = 1.0 - get_pcvar_float( pBotDifficulty ), Float:curOrigin[3]
	pev( id, pev_origin, curOrigin )
	get_players( players, playersNum )
		
	if ( gAmmo[weapon][0] != -1 && !clip )
	{
		set_bot_data( id, bot_buttons, IN_RELOAD )
		return
	}
	
	for ( new i; i < playersNum; i++ )
	{
		player = players[i]
		
		if ( is_user_alive( player ) && IsVisible( id, player ) && cs_get_user_team( player ) != team && player != gCommander[CS_TEAM_T] && player != gCommander[CS_TEAM_CT] )
		{
			pev( player, pev_origin, origin )
			for ( new j; j < 3; j++ )
				origin[j] += random_float( 0.0, 100.0 * difficulty )
			
			if ( random( 4 ) ) 
				button |= IN_ATTACK
			
			break
		}
	}
	
	if ( team == CS_TEAM_T && !button && user_has_weapon( id, CSW_C4 ) )
	{
		new ent
		while ( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", "func_bomb_target" ) ) != 0 )
		{
			if ( !fm_boxents_distance( id, ent ) ) 
			{
				if ( weapon != CSW_C4 )
					engclient_cmd( id, "weapon_c4" )
				
				button |= IN_ATTACK
			}
		}
	}
	
	if ( team == CS_TEAM_CT && !button )
	{
		new ent
		static model[33]
		while ( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", "grenade" ) ) != 0 )
		{
			pev( ent, pev_model, model, 32 )
			if ( equali( model, "models/w_c4.mdl" ) )
			{
				new Float:bombOrigin[3]
				pev( ent, pev_origin, bombOrigin )
				
				if ( vector_distance( bombOrigin, curOrigin ) < 75.0 )
				{
					origin = bombOrigin
					button |= IN_USE
				}
				else if ( IsVisible( id, ent ) )
					origin = bombOrigin
			}
		}
	}
	
	// button can be set in the previous block, so we're retesting the condition
	if ( team == CS_TEAM_CT && !button )
	{
		new ent
		while ( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", "hostage_entity" ) ) != 0 )
		{
			if ( cs_get_hostage_foll( ent ) )
				continue
			
			new Float:hostageOrigin[3]
			pev( ent, pev_origin, hostageOrigin )
			
			if ( vector_distance( hostageOrigin, curOrigin ) < 150.0 )
			{
				origin = hostageOrigin
				button |= IN_USE
			}
			else if ( IsVisible( id, ent ) )
				origin = hostageOrigin
		}
	}
	
	set_bot_data( id, bot_buttons, button )
	
	if ( gWaypointNum[id] && !origin[0] && !origin[1] && !origin[2] && !( button & IN_ATTACK ) )
	{
		origin = gWaypoints[id][0]
		origin[2] += 8.1
		
		switch ( get_pcvar_num( pBotPathfinding ) )
		{
			case 1 :
			{
				new Float:fraction
				engfunc( EngFunc_TraceHull, curOrigin, origin, 0, HULL_HUMAN, id, 0 )
				
				get_tr2( 0, TR_flFraction, fraction )
				
				if ( fraction != 1.0 && floatabs( origin[2] - curOrigin[2] ) < 7.1 )	
				//if ( endPos[0] == 0.0 && endPos[1] == 0.0 && endPos[2] == 0.0 )
				{
					// We rotate around the player in 10 degree increments, then gradually expand outward
					//	until we get a valid hull trace. This is for the limited pathfinding correction.
					new Float:curRotation[3], breakOuter, TR1 = create_tr2(), TR2 = create_tr2()
					curRotation = curOrigin
					for ( new Float:radius = 150.1, Float:angle; radius <= 500.0 && !breakOuter; radius += 50.0 )
						for ( angle = 0.0; angle < M_PI * 2; angle += M_PI/18 )
						{
							curRotation[0] += radius * floatcos( angle )
							curRotation[1] += radius * floatsin( angle )
							
							engfunc( EngFunc_TraceHull, curOrigin, curRotation, 0, HULL_HUMAN, id, TR1 )
							
							get_tr2( TR1, TR_flFraction, fraction )
							
							if ( fraction == 1.0 )
							{				
								curRotation[2] = origin[2]
								
								engfunc( EngFunc_TraceHull, curRotation, origin, 0, HULL_HUMAN, id, TR2 )
							
								get_tr2( TR2, TR_flFraction, fraction )
								
								if ( fraction == 1.0 )
								{
									breakOuter = 1
									origin = curRotation
									break
								}
							}
							
							curRotation = curOrigin
						}
					
					free_tr2( TR1 )
					free_tr2( TR2 )
				}
			}
			
			case 2 :
			{
				// you are a faggot
			}
		}
	}
	
	if ( origin[0] || origin[1] || origin[2] )
		set_bot_angles( id, origin )
	
	// I wanted to compress this but I get a tag mismatch.
	if ( ( origin[0] || origin[1] || origin[2] ) && vector_distance( curOrigin, origin ) > 150.0 )
	{
		new Float:maxSpeed
		pev( id, pev_maxspeed, maxSpeed )
		
		set_bot_data( id, bot_forward_move, maxSpeed )
	}
	else
		set_bot_data( id, bot_forward_move, 0.0 )
}

public client_putinserver( id )
{
	if ( !ModEnabled() )
		return
	
	new players[32], playersNum, botLimit = get_pcvar_num( pBotLimit )
	get_players( players, playersNum )
	
	switch ( botLimit )
	{
		
	}
}

public ForwardPlayerPreThink( id )
{
	if ( !ModEnabled() || !is_user_alive( id ) )
		return
	
	new CsTeams:team, buttons = pev( id, pev_button ), oldbuttons = pev( id, pev_oldbuttons )
	if ( gCommander[CS_TEAM_T] == id )
		team = CS_TEAM_T
	else if ( gCommander[CS_TEAM_CT] == id )
		team = CS_TEAM_CT

	//if ( !team && ButtonTouch( IN_USE, buttons, oldbuttons ) )
	//	menu_display( id, gPlayerMenu )
	
	if ( !team )
		return
	
	static msg[128]
	
	if ( ButtonTouch( IN_ATTACK, buttons, oldbuttons  ) )
	{
		new Float:origin[3], Float:angle[3], Float:fwd[3], Float:end[3]
		pev( id, pev_origin, origin )  
		pev( id, pev_v_angle, angle ) 
		
		engfunc( EngFunc_MakeVectors, angle ) 
		
		global_get( glb_v_forward, fwd ) 
		
		fwd[0] = origin[0] + fwd[0] * 5000
		fwd[1] = origin[1] + fwd[1] * 5000
		fwd[2] = origin[2] + fwd[2] * 5000
		
		engfunc( EngFunc_TraceLine, origin, fwd, 0, id, 0 )
		get_tr2( 0, TR_vecEndPos, end )
		new target = get_tr2( 0, TR_pHit )
		if ( !target || !is_user_alive( target ) )
		{
			target = 0
			while ( ( target = engfunc( EngFunc_FindEntityInSphere, target, end, 100.0 ) ) != 0 && !is_user_alive( target ) ) { }
		}
		if ( !target || !is_user_alive( target ) || cs_get_user_team( target ) != team || target == id )
		{
			new location[3]
			FVecIVec( end, location )
			
			message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id )
			write_byte( TE_BEAMTORUS )
			write_coord( location[0] )
			write_coord( location[1] )
			write_coord( location[2] )
			write_coord( location[0] + 24 )
			write_coord( location[1] + 45 )
			write_coord( location[2] + -66 )
			write_short( gLightSprite )
			write_byte( 0 ) // starting frame
			write_byte( 15 ) // frame rate in 0.1s
			write_byte( 10 ) // life in 0.1s
			write_byte( 10 ) // line width in 0.1s
			write_byte( 1 ) // noise amplitude in 0.01s
			write_byte( 255 )
			write_byte( 255 )
			write_byte( 255 )
			write_byte( 300 ) // brightness
			write_byte( 1 ) // scroll speed in 0.1s
			message_end()
			
			if ( !( pev( id, pev_button ) & IN_DUCK ) )
			{
				new players[32], playersNum, player
				get_players( players, playersNum )
				
				for ( new i; i < playersNum; i++ )
				{
					player = players[i]
					if ( cs_get_user_team( player ) == team )
						gSelected[player] = 0
				}
			}
		}
		else if ( is_user_alive( target ) )
		{
			client_cmd( id, "spk %s", gSounds[C_SELECT] )
			
			if ( gSelected[target] )
			{
				gSelected[target] = 0
				
				if ( !( pev( id, pev_button ) & IN_DUCK ) )
				{
					new players[32], playersNum, player
					get_players( players, playersNum )
					
					for ( new i; i < playersNum; i++ )
					{
						player = players[i]
						if ( cs_get_user_team( player ) == team )
							gSelected[player] = 0
					}
				}
			}
			else
			{
				gSelected[target] = 1
				
				if ( !( pev( id, pev_button ) & IN_DUCK ) )
				{
					new players[32], playersNum, player
					get_players( players, playersNum )
					
					for ( new i; i < playersNum; i++ )
					{
						player = players[i]
						if ( cs_get_user_team( player ) == team && player != target )
							gSelected[player] = 0
					}
				}
			}				
		}
	}
	
	if ( ButtonTouch( IN_ATTACK2, buttons, oldbuttons ) )
	{
		new Float:curTime = get_gametime()
		if ( curTime - 1.0 < gLastOrder[team] )
			return
		
		gLastOrder[team] = curTime
		
		new Float:origin[3], Float:angle[3], Float:fwd[3], Float:end[3], name[33]
		pev( id, pev_origin, origin )  
		pev( id, pev_v_angle, angle ) 
		
		engfunc( EngFunc_MakeVectors, angle ) 
		
		global_get( glb_v_forward, fwd ) 
		
		fwd[0] = origin[0] + fwd[0] * 5000
		fwd[1] = origin[1] + fwd[1] * 5000
		fwd[2] = origin[2] + fwd[2] * 5000
		
		engfunc( EngFunc_TraceLine, origin, fwd, 0, id, 0 )
		get_tr2( 0, TR_vecEndPos, end )
		
		end[2] += 32.0
		
		new players[32], playersNum, player, color[3], location[3], closePlayer, Float:followOrigin[3]//, className[33]
		color = team == CS_TEAM_T ? { 255, 0, 0 } : { 0, 0, 255 }
		FVecIVec( end, location )
		
		while ( ( closePlayer = engfunc( EngFunc_FindEntityInSphere, closePlayer, end, 100.0 ) ) != 0 ) 
			if ( is_user_alive( closePlayer ) && cs_get_user_team( closePlayer ) == team && gCommander[team] != closePlayer )
				break
		
		if ( closePlayer )
			pev( closePlayer, pev_origin, followOrigin )
			
		get_players( players, playersNum )
		for ( new i, ent; i < playersNum; i++ )
		{
			player = players[i]
			if ( cs_get_user_team( player ) == team && gSelected[player] )
			{
				if ( closePlayer && !( buttons & IN_DUCK ) )
				{					
					if ( closePlayer == player )
						continue
					
					gWaypointNum[player] = 0
					
					get_user_name( player, name, 32 )
					formatex( msg, 127, "%s, move to your waypoint.", name )
					ComMessage( player, msg )
					client_cmd( player, "spk %s", gSounds[SOUNDS:random_num( _:C_MOVE1, _:C_MOVE4 )] )
					
					if ( get_pcvar_num( pTeamObjectives ) )
					{
						for ( new j, player2; j < playersNum; j++ )
						{
							player2 = players[j]
							if ( cs_get_user_team( player2 ) == team )
								CreateTrackingBeam( player2, closePlayer, player )
						}
					}
					else
					{
						CreateTrackingBeam( player, closePlayer, player )
						CreateTrackingBeam( id, closePlayer, player )
					}
					
					gFollow[player] = closePlayer
				}
				else if ( buttons & IN_DUCK && gWaypointNum[player] && !gFollow[player] )
				{
					if ( gWaypointNum[player] != MAX_WAYPOINTS )
					{				
						// Mark it as found.
						name[0] = 1
						gWaypoints[player][gWaypointNum[player]++] = end
					}
				}
				else
				{
					gFollow[player] = 0
					
					gWaypoints[player][0] = end
					gWaypointNum[player] = 1
					get_user_name( player, name, 32 )
					formatex( msg, 127, "%s, move to your waypoint.", name )
					ComMessage( player, msg )
					client_cmd( player, "spk %s", gSounds[SOUNDS:random_num( _:C_MOVE1, _:C_MOVE4 )] )
					
					//KillBeam( player )
					if ( get_pcvar_num( pTeamObjectives ) )
					{
						for ( new j, player2; j < playersNum; j++ )
						{
							player2 = players[j]
							if ( cs_get_user_team( player2 ) == team )
								CreateBeam( player2, gWaypoints[player][0], player )
						}
					}
					else
					{
						CreateBeam( player, gWaypoints[player][0], player )
						CreateBeam( id, gWaypoints[player][0], player )
					}
					
					if ( pev_valid( gObjectiveEnt[player] ) )
					{
						engfunc( EngFunc_RemoveEntity, gObjectiveEnt[player] )
						gObjectiveEnt[player] = 0
					}
					
					new Float:renderColor[3]
					renderColor[0] = team == CS_TEAM_T ? 255.0 : 80.0
					renderColor[1] = 80.0
					renderColor[2] = team == CS_TEAM_CT ? 255.0 : 80.0
					
					ent = gObjectiveEnt[player] = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "env_sprite" ) )
					set_pev( ent, pev_classname, gObjectiveClass )
					set_pev( ent, pev_modelindex, gObjectiveSpriteId )
					set_pev( ent, pev_iuser1, player )
					set_pev( ent, pev_iuser2, _:team )
					//set_pev( ent, pev_scale, 1.0 )
					set_pev( ent, pev_rendermode, 5 ) // additive
					set_pev( ent, pev_renderamt, 255.0 )
					set_pev( ent, pev_rendercolor, renderColor )
					engfunc( EngFunc_SetOrigin, ent, gWaypoints[player][0] )
				}
			}
		}
		
		// If it found anyone to give the order to.
		if ( name[0] ) 
		{
			client_cmd( id, "spk %s", gSounds[SOUNDS:random_num( _:C_MOVE1, _:C_MOVE4 )] )
			LightEffect( id, color, location )
		}
	}
	
	if ( ButtonTouch( IN_USE, buttons, oldbuttons ) )
		menu_display( id, gComMenu )
	
	if ( ButtonTouch( IN_RELOAD, buttons, oldbuttons ) )
		menu_display( id, gSelectMenu )
	
	if ( ButtonTouch( IN_JUMP, buttons, oldbuttons ) )
	{
		if ( get_gametime() - gLastAlert[team] > 5 )
		{
			new players[32], playersNum, foundCurrent, player, teleportTo, Float:origin[3]
			get_players( players, playersNum )
			
			if ( gLastTeleported[team] && ( !is_user_connected( gLastTeleported[team] ) || cs_get_user_team( gLastTeleported[team] ) != team ) )
				gLastTeleported[team] = 0
			
			for ( new i; i < playersNum; i++ )
			{
				player = players[i]
				if ( cs_get_user_team( player ) != team || gCommander[team] == player || !is_user_alive( player ) )
				{
					if ( i == playersNum - 1 && playersNum > 1 )
					{
						playersNum--
						i = -1
						gLastTeleported[team] = 0
					}
					
					continue
				}
				
				if ( !gLastTeleported[team] )
				{
					teleportTo = player
					break
				}
				
				if ( player == gLastTeleported[team] )
				{
					foundCurrent = 1
					
					if ( i == playersNum - 1 && playersNum > 1 )
					{
						playersNum--
						i = -1
						gLastTeleported[team] = 0
					}
					
					continue
				}
				
				if ( foundCurrent )
				{
					teleportTo = player					
					break
				}
				
				/*
				if ( i == playersNum - 1 && playersNum > 1 )
				{
					foundCurrent = 1
					gLastTeleported[team] = 0
					i = -1
					continue
				}
				*/
			}
			
			if ( teleportTo )
			{	
				gLastTeleported[team] = teleportTo
				pev( teleportTo, pev_origin, origin )
				origin[2] += 48.0
				engfunc( EngFunc_SetOrigin, id, origin )
			}
			
			return
		}
		
		engfunc( EngFunc_SetOrigin, id, gAlert[team] )
		
		gLastAlert[team] = 0.0
	}
}

public SquadAssignMenuHandle( id, menu, item )
{
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED
	
	new CsTeams:team = cs_get_user_team( id ), assignedFlag, message[33]
	format( message, 32, "You're squad %d.", item + 1 )
	for ( new i; i < 33; i++ )
		if ( gSelected[i] && cs_get_user_team( i ) == team )
		{
			ComMessage( i, message )
			client_cmd( i, "spk %s", gSounds[T_SQUAD1 + SOUNDS:item] )
			gSquad[i] = item + 1
			assignedFlag = 1
		}
	
	if ( assignedFlag )
	{
		client_print( id, print_chat, "[CST] You have assigned your selected players to squad %d.", item + 1 )
		client_cmd( id, "spk %s", gSounds[T_SQUAD1 + SOUNDS:item] )
	}
	else
		client_print( id, print_chat, "[CST] You have no one selected to add to squad %d.", item + 1 )
	
	return PLUGIN_HANDLED
}

public PlayerMenuHandle( id, menu, item )
{
	new CsTeams:team = cs_get_user_team( id )
	if ( !gCommander[team] )
	{
		client_print( id, print_chat, "[CST] There is no commander on your team." )
		return PLUGIN_HANDLED
	}
	
	new name[33]
	get_user_name( id, name, 32 )
	
	new Float:curTime = get_gametime()
	if ( curTime - 2.0 < gLastRadio[id] )
		return PLUGIN_HANDLED
	
	gLastRadio[id] = curTime
	
	switch ( item )
	{
		case 0 :
		{
			client_cmd( id, "spk %s", gSounds[SOUNDS:random_num( _:T_NEEDSORDER1, _:T_NEEDSORDER2 )] )
			client_cmd( gCommander[team], "spk %s", gSounds[SOUNDS:random_num( _:C_NEEDSORDER1, _:C_NEEDSORDER2 )] )
			
			client_print( id, print_chat, "%s (RADIO): Standing by.", name )
			client_print( gCommander[team], print_chat, "%s (RADIO): Standing by.", name )
			
			new Float:origin[3]
			pev( id, pev_origin, origin )
			SetAlert( team, origin )
		}
		
		case 1 : 
		{
			client_cmd( id, "spk %s", gSounds[SOUNDS:random_num( _:T_NEEDSAMMO1, _:T_NEEDSAMMO2 )] )
			client_cmd( gCommander[team], "spk %s", gSounds[SOUNDS:random_num( _:C_NEEDSAMMO1, _:C_NEEDSAMMO2 )] )
			
			client_print( id, print_chat, "%s (RADIO): Commander, I need ammo.", name )
			client_print( gCommander[team], print_chat, "%s (RADIO): Commander, I need ammo.", name )
			
			new Float:origin[3]
			pev( id, pev_origin, origin )
			SetAlert( team, origin )
		}
		
		case 2 : 
		{
			client_cmd( id, "spk %s", gSounds[SOUNDS:random_num( _:T_NEEDSHEALTH1, _:T_NEEDSHEALTH2 )] )
			client_cmd( gCommander[team], "spk %s", gSounds[SOUNDS:random_num( _:C_NEEDSHEALTH1, _:C_NEEDSHEALTH2 )] )
			
			client_print( id, print_chat, "%s (RADIO): Commander, I need a medpack.", name )
			client_print( gCommander[team], print_chat, "%s (RADIO): Commander, I need a medpack.", name )
			
			new Float:origin[3]
			pev( id, pev_origin, origin )
			SetAlert( team, origin )
		}
		
		default :
		{
			new Float:curTime = get_gametime()
			if ( curTime - gLastEjectVote[team] < get_pcvar_float( pEjectTime ) ) 
			{
				client_print( id, print_chat, "[CST] There has recently been a vote to eject the commander." )
				return PLUGIN_HANDLED
			}
			
			new players[32], playersNum, name[33]
			get_players( players, playersNum )
			
			get_user_name( gCommander[team], name, 32 )
			
			if ( get_pcvar_num( pShowVotes ) )
			{
				new playerName[33]
				get_user_name( id, playerName, 32 )
				
				client_print( 0, print_chat, "[CST] %s has started a vote to eject %s.", playerName, name )
			}
			else
				client_print( 0, print_chat, "[CST] A vote has been started to eject %s.", name )
			
			gEjectVotes[team][0] = 1
			gEjectVotes[team][1] = 0
			
			for ( new i, player; i < playersNum; i++ )
			{
				player = players[i]
				if ( player != id && cs_get_user_team( player ) == team && gCommander[team] != player )
					menu_display( player, gEjectMenu )
			}
			
			gLastEjectVote[team] = curTime
			
			set_task( 10.0, "EjectVoteDone", _:team )
		}
	}
	
	return PLUGIN_HANDLED
}

public EjectMenuHandle( id, menu, item )
{
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED
	
	if ( get_pcvar_num( pShowVotes ) )
	{
		new name[33]
		get_user_name( id, name, 32 )
		
		client_print( 0, print_chat, "[CST] %s has voted to%s eject the commander.", name, item ? " not" : "" )
	}
	
	gEjectVotes[cs_get_user_team( id )][item]++
	
	return PLUGIN_HANDLED
}

public EjectVoteDone( CsTeams:team )
{
	if ( !gCommander[team] )
		return
	
	new name[33]
	get_user_name( gCommander[team], name, 32 )
	
	if ( !gEjectVotes[team][1] || float( gEjectVotes[team][0] ) / float( gEjectVotes[team][0] + gEjectVotes[team][1] ) >= get_pcvar_float( pEjectPercentage ) )
	{
		client_print( 0, print_chat, "[CST] %s has been ejected.", name )
		
		new players[32], playersNum
		get_players( players, playersNum )
		
		for ( new i; i < playersNum; i++ )
			if ( cs_get_user_team( players[i] ) == team )
				client_cmd( players[i], "spk %s", gSounds[T_C_EJECTED] )
		
		SetNormal( gCommander[team], 1 )
		if ( NumActive( team ) > 1 )
			VoteCommander( team )
	}
	else
		client_print( 0, print_chat, "[CST] The vote has failed to eject %s.", name )
}

public ForwardEmitSound( id )
{
	if ( ModEnabled() && ( id == gCommander[CS_TEAM_T] || id == gCommander[CS_TEAM_CT] ) )
		return FMRES_SUPERCEDE
	
	return FMRES_IGNORED
}

public ForwardCmdStart( id, UC_handle )
{
	if ( !ModEnabled() || id != gCommander[CS_TEAM_T] && id != gCommander[CS_TEAM_CT] || !is_user_alive( id ) )
		return FMRES_IGNORED
	
	new Float:forwardMove, Float:sideMove
	get_uc( UC_handle, UC_ForwardMove, forwardMove )
	get_uc( UC_handle, UC_SideMove, sideMove )

	new Float:maxSpeed
	pev( id, pev_maxspeed, maxSpeed )
	
	new Float:walkSpeed = maxSpeed * 0.52
	forwardMove = floatabs( forwardMove )
	sideMove = floatabs( sideMove )
    
	if( forwardMove <= walkSpeed && sideMove <= walkSpeed && ( forwardMove || sideMove ) && pev( id, pev_button ) & IN_FORWARD )
	{
		new Float:origin[3], Float:angle[3], Float:fwd[3]
		pev( id, pev_origin, origin )  
		pev( id, pev_v_angle, angle ) 
		
		engfunc( EngFunc_MakeVectors, angle ) 
		
		global_get( glb_v_forward, fwd ) 
		
		fwd[0] = origin[0] + fwd[0] * 20
		fwd[1] = origin[1] + fwd[1] * 20
		fwd[2] = origin[2] + fwd[2] * 20
		
		engfunc( EngFunc_SetOrigin, id, fwd )
	}
	
	return FMRES_IGNORED
}

public ComMenuHandle( id, menu, item )
{
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED
	
	switch ( item )
	{
		case 0 :
			menu_display( id, gSelectMenu )
		case 1 :
			menu_display( id, gOrdersMenu )
		case 2 :
			menu_display( id, gSquadAssignMenu )
		case 3 :
			menu_display( id, gReinforceMenu )
		case 4 :
		{
			SetNormal( id, 1 )
			
			new name[33]
			get_user_name( id, name, 32 )
			
			client_print( 0, print_chat, "[CST] %s has left the command station.", name )
			
			new CsTeams:team = cs_get_user_team( id )
			if ( NumActive( team ) > 1 )
				VoteCommander( team )
		}
	}
	
	return PLUGIN_HANDLED
}

public ReinforceMenuHandle( id, menu, item )
{
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED
	
	new CsTeams:team
	if ( gCommander[CS_TEAM_T] == id )
		team = CS_TEAM_T
	else if ( gCommander[CS_TEAM_CT] == id )
		team = CS_TEAM_CT
	
	if ( !team )
		return PLUGIN_HANDLED
	
	new cost = get_pcvar_num( item ? pBotCost : pReinforceCost )
	if ( gMoney[team] < cost )
	{
		client_print( id, print_chat, "[CST] You do not have enough money for %s.", item ? "a bot" : "reinforcements" )
		client_cmd( id, "spk %s", gSounds[C_MORE] )
		return PLUGIN_HANDLED
	}
	
	switch ( item )
	{
		case 0 :
		{
			new players[32], playersNum, player, teamPlayers[32], numPlayers
			get_players( players, playersNum )
			
			for ( new i; i < playersNum; i++ )
			{
				player = players[i]
				if ( cs_get_user_team( player ) == team && player != id && !is_user_alive( player ) )
					teamPlayers[numPlayers++] = player
			}
			
			if ( !numPlayers )
			{
				client_print( id, print_chat, "[CST] There are no team members to select." )
				return PLUGIN_HANDLED
			}
			
			new randomPlayer = teamPlayers[random( numPlayers )]
			
			cs_user_spawn( randomPlayer )
			give_item( randomPlayer, team == CS_TEAM_T ? "weapon_glock18" : "weapon_usp" )
			give_item( randomPlayer, "weapon_knife" )
			
			new name[33]
			get_user_name( randomPlayer, name, 32 )
			
			client_print( id, print_chat, "[CST] You have respawned %s.", name )
			client_print( randomPlayer, print_chat, "[CST] You have been ordered in as reinforcements by the commander." )
		}
		
		case 1 :
		{
			new botLimit = get_pcvar_num( pBotLimit ), players[32], playersNum
			get_players( players, playersNum )
			
			switch ( botLimit )
			{
				case -32 .. -1 :
				{
					new teamPlayers
					for ( new i; i < playersNum; i++ )
						if ( cs_get_user_team( players[i] ) == team )
							teamPlayers++
					
					if ( get_maxplayers() / 2 - teamPlayers <= -botLimit )
					{
						client_print( id, print_chat, "[CST] There are too many players on your team already." )
						return PLUGIN_HANDLED
					}
				}
				case 1 .. 32 :
				{
					// code is repeated but it's worth skipping caching it in the 0 case
					new teamPlayers, botPlayers
					for ( new i; i < playersNum; i++ )
						if ( cs_get_user_team( players[i] ) == team )
						{
							teamPlayers++
							if ( gBot[players[i]] )
								botPlayers++
						}
						
					if ( botPlayers >= botLimit || get_maxplayers() / 2 <= teamPlayers )
					{
						client_print( id, print_chat, "[CST] There are too many bots on your team already." )
						return PLUGIN_HANDLED
					}
				}
				// 0, <-32, >32 are all treated as no limit
			}
			
			if ( playersNum >= get_maxplayers() )
			{
				// Unfortunately, I'm not God, so I can't add extra slots.
				client_print( id, print_chat, "[CST] There are too many players on the server already." )
				return PLUGIN_HANDLED
			}
			
			new botNameIndex
			do
				botNameIndex = random( MAX_NAMES )
			// Can't possibly run out of names, unless you remove some.
			while ( get_user_index( gNames[botNameIndex] ) )
			
			new bot = create_bot( gNames[botNameIndex] )
			if ( !bot )
				return PLUGIN_HANDLED
			
			gBot[bot] = 1
			gBotNum++
			
			//cs_set_user_team( bot, team, team == CS_TEAM_T ? CS_T_TERROR : CS_CT_SAS )
			engclient_cmd( bot, "jointeam", team == CS_TEAM_T ? "1" : "2" )
			engclient_cmd( bot, "joinclass", "1" )
			
			set_task( 0.1, "BotSpawn", bot )
			
			client_print( id, print_chat, "[CST] You have called in a bot for reinforcements." )
		}
	}
	
	gMoney[team] -= cost
	
	return PLUGIN_HANDLED
}

public BotSpawn( bot )
{
	cs_user_spawn( bot )
	give_item( bot, cs_get_user_team( bot ) == CS_TEAM_T ? "weapon_glock18" : "weapon_usp" )
	give_item( bot, "weapon_knife" )
}

public OrdersMenuHandle( id, menu, item )
{
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED
	
	new CsTeams:team
	if ( gCommander[CS_TEAM_T] == id )
		team = CS_TEAM_T
	else if ( gCommander[CS_TEAM_CT] == id )
		team = CS_TEAM_CT
	
	if ( !team )
		return PLUGIN_HANDLED
	
	new Float:curTime = get_gametime()
	if ( curTime - 1.0 < gLastOrder[team] )
		return PLUGIN_HANDLED
	
	gLastOrder[team] = curTime
	
	new assignedFlag, message[33]
	switch ( ORDERS:item )
	{
		case NONE :
			format( message, 32, "You are left to your discretion." )
		
		case ATTACK :
			format( message, 32, "Your orders are to attack." )
			
		case DEFEND :
			format( message, 32, "Defend this position." )
		
		case EQUIP :
			format( message, 32, "Equip/plant bomb/get hostages." )
	}
	
	for ( new i; i < 33; i++ )
		if ( gSelected[i] && cs_get_user_team( i ) == team )
		{
			ComMessage( i, message )
			client_cmd( i, "spk %s", gSounds[C_NONE + SOUNDS:item] )
			gOrders[i] = ORDERS:item
			assignedFlag = 1
		}
	
	switch ( ORDERS:item )
	{
		case NONE :
			format( message, 32, "free roam" )
		
		case ATTACK :
			format( message, 32, "attack" )
			
		case DEFEND :
			format( message, 32, "defend" )
		
		case EQUIP :
			format( message, 32, "get equip/plant bomb/hostages" )
	}
	
	if ( assignedFlag )
	{
		client_print( id, print_chat, "[CST] You have ordered your select players to %s.", message )
		client_cmd( id, "spk %s", gSounds[C_NONE + SOUNDS:item] )
	}
	else
		client_print( id, print_chat, "[CST] You have no one selected to order to %s.", message )
	
	return PLUGIN_HANDLED
}

public SelectMenuHandle( id, menu, item )
{
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED
	
	new CsTeams:team
	if ( gCommander[CS_TEAM_T] == id )
		team = CS_TEAM_T
	else if ( gCommander[CS_TEAM_CT] == id )
		team = CS_TEAM_CT
	
	if ( !team )
		return PLUGIN_HANDLED
	
	new players[32], playersNum, player, teamPlayers[32], numPlayers
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
	{
		player = players[i]
		if ( cs_get_user_team( player ) == team && player != id && is_user_alive( player ) )
			teamPlayers[numPlayers++] = player
	}
	
	if ( !numPlayers )
	{
		client_print( id, print_chat, "[CST] There are no team members to select." )
		return PLUGIN_HANDLED
	}
	
	switch ( item )
	{
		case 5 :
		{
			if ( !( pev( id, pev_button ) & IN_DUCK ) )
				for ( new i; i < playersNum; i++ )
				{
					player = players[i]
					if ( cs_get_user_team( player ) == team && player != id )
						gSelected[player] = 0
				}
			
			client_cmd( id, "spk %s", gSounds[C_SELECT] )
			
			new randomPlayer = teamPlayers[numPlayers == 1 ? 0 : random_num( 0, numPlayers - 1 )]
			gSelected[randomPlayer] = 1
			client_print( id, print_chat, "[CST] You have selected a random team member." )
		}
		case 6 :
		{
			for ( new i; i < numPlayers; i++ )
				gSelected[teamPlayers[i]] = 1
			
			client_cmd( id, "spk %s", gSounds[C_SELECT] )
			
			client_print( id, print_chat, "[CST] You have selected your entire team." )
		}
		default :
		{
			if ( !( pev( id, pev_button ) & IN_DUCK ) )
				for ( new i; i < playersNum; i++ )
				{
					player = players[i]
					if ( cs_get_user_team( player ) == team && player != id )
						gSelected[player] = 0
				}
			
			new selectedFlag
			for ( new i; i < numPlayers; i++ )
			{
				player = teamPlayers[i]
				if ( gSquad[player] == item + 1 )
				{
					selectedFlag = 1
					gSelected[player] = 1
				}
			}
			
			if ( !selectedFlag )
				client_print( id, print_chat, "[CST] There is no one in this squad to select." )
			else
				client_cmd( id, "spk %s", gSounds[C_SQUAD1 + SOUNDS:item] )
		}	
	}
	
	return PLUGIN_HANDLED
}

LightEffect( id, color[3], location[3] )
{
	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id )
	write_byte( TE_BEAMTORUS )
	write_coord( location[0] )
	write_coord( location[1] )
	write_coord( location[2] )
	write_coord( location[0] + 24 )
	write_coord( location[1] + 45 )
	write_coord( location[2] + -66 )
	write_short( gLightSprite )
	write_byte( 0 ) // starting frame
	write_byte( 15 ) // frame rate in 0.1s
	write_byte( 10 ) // life in 0.1s
	write_byte( 10 ) // line width in 0.1s
	write_byte( 1 ) // noise amplitude in 0.01s
	write_byte( color[0] )
	write_byte( color[1] )
	write_byte( color[2] )
	write_byte( 300 ) // brightness
	write_byte( 1 ) // scroll speed in 0.1s
	message_end()
}

ComMessage( id, msg[] )
{
	new name[33]
	get_user_name( gCommander[cs_get_user_team( id ) == CS_TEAM_T ? CS_TEAM_T : CS_TEAM_CT], name, 32 )
	client_print( id, print_chat, "%s (COMMANDER): %s", name, msg )
}

ButtonTouch( button, buttons, oldbuttons )
	return buttons & button && !( oldbuttons & button )

public ShowHUD()
{
	if ( !ModEnabled() )
		return
	
	new players[32], playersNum, player, id, name[33], numSelected[CsTeams], Float:HudX = get_pcvar_float( pHudX ), Float:HudY = get_pcvar_float( pHudY ), msgLen, Float:timer = get_pcvar_float(pTimer), temp[24], squadMembers[5][32], squadNum[5], CsArmorType:garbage, followName[33]
	get_players( players, playersNum )
	
	static msg[512]
	gCommander[CS_TEAM_T] ? get_user_name( gCommander[CS_TEAM_T], name, 32 ) : copy( name, 32, "None" )
	msgLen = format( msg, 511, "Commander^n%s^n^nTeam Money^n$%d^n^nSquad: ", name, gMoney[CS_TEAM_T] )
	
	for ( new i; i < playersNum; i++ )
	{
		id = players[i]
		if ( id != gCommander[CS_TEAM_T] && cs_get_user_team( id ) == CS_TEAM_T )
		{
			if ( gSelected[id] )				
				numSelected[CS_TEAM_T]++
			
			if ( gSquad[id] )
				squadMembers[gSquad[id] - 1][squadNum[gSquad[id] - 1]++] = id
			
			gSquad[id] ? format( temp, 23, "%d", gSquad[id] ) : copy( temp, 23, "None" )
			add( msg[msgLen], 511 - msgLen, temp )
			
			switch ( gOrders[id] )
			{
				case NONE :
					if ( gFollow[id] )
					{
						get_user_name( gFollow[id], followName, 32 )
						format( temp, 23, "Follow %s", followName )
					}
					else
						format( temp, 23, gWaypointNum[id] ? "Move to Waypoint" : "None/Free" )
				
				case ATTACK :
					format( temp, 23, "Attack" )
				
				case DEFEND : 
					format( temp, 23, "Defend" )
				
				case EQUIP :
					format( temp, 23, "Equip/Bomb/Hostages" )
			}
			
			add( msg, 511, "^n^nOrders: " )
			add( msg, 511, temp )
			
			if ( gWaypointNum[id] )
			{
				new Float:origin[3]
				pev( id, pev_origin, origin)
				
				new Float:distance = vector_distance( origin, gWaypoints[id][0] )
				if ( distance < 150.0 )
				{
					get_user_name( id, name, 32 )
					client_print( id, print_chat, "%s (RADIO): I'm in position.", name )
					client_print( gCommander[CS_TEAM_T], print_chat, "%s (RADIO): I'm in position.", name )
					
					client_cmd( id, "spk %s", gSounds[SOUNDS:random_num( _:T_COMPLETE1, _:T_COMPLETE2 )] )
					client_cmd( gCommander[CS_TEAM_T], "spk %s", gSounds[SOUNDS:random_num( _:T_COMPLETE1, _:T_COMPLETE2 )] )
					
					NextObjective( id )
				}
				else
				{					
					format( temp, 23, "%dm away", floatround( distance * 0.0254 ) )
					
					add( msg[msgLen], 511 - msgLen, "^n^nObjective^n" )
					add( msg[msgLen], 511 - msgLen, temp )
				}
			}
			
			set_hudmessage( 255, 255, 255, HudX, HudY, 0, 0.0, timer + 0.2, 0.0, 0.0, 4 )
			show_hudmessage( id, "%s", msg )
			
			msg[msgLen] = 0
		}
	}	
	
	if ( gCommander[CS_TEAM_T] )
	{
		format( msg, 511, "Commander HUD^n^nTeam Money^n$%d^n^nSelected^n", gMoney[CS_TEAM_T] )
		
		if ( numSelected[CS_TEAM_T] )
		{			
			for ( new i, numFound; i < playersNum; i++ )
			{
				id = players[i]
				
				if ( gSelected[id] && cs_get_user_team( id ) == CS_TEAM_T )
				{
					get_user_name( id, name, 32 )
					
					add( msg, 511, name )
					format( temp, 23, " (%d)", get_user_health( id ) )
					add( msg, 511, temp )
					format( temp, 23, " (%d)", cs_get_user_armor( id, garbage ) )
					add( msg, 511, temp )
					switch ( gOrders[id] )
					{
						case NONE :
							format( temp, 23, " (/)" )
							
						case ATTACK :
							format( temp, 23, " (A)" )
							
						case DEFEND :
							format( temp, 23, " (D)" )
							
						case EQUIP :
							format( temp, 23, " (E)" )
					}
					
					add( msg, 511, temp )
					
					if ( gWaypointNum[id] )
						add( msg, 511, " [->]" )
					
					add( msg, 511, "^n" )
					
					if ( ++numFound > 5 )
					{
						add( msg, 511, "..." )
						break
					}
				}
			}
		}
		else
			add( msg, 511, "None" )
		
		set_hudmessage( 255, 255, 255, HudX, HudY, 0, 0.0, timer + 0.3, 0.0, 0.0, 4 )
		show_hudmessage( gCommander[CS_TEAM_T], "%s", msg )
		
		format( msg, 511, "Squads^n" )
		
		new squadFlag
		for ( new i; i < 5; i++ )
		{
			if ( !squadNum[i] )
				continue
			
			squadFlag = 1
			
			format( temp, 23, "^nSquad %d^n", i + 1 )
			add( msg, 511, temp )
			
			for ( new j; j < squadNum[i] && j < 5; j++ )
			{
				player = squadMembers[i][j]
				get_user_name( player, name, 32 )
				add( msg, 511, name )
				if ( is_user_alive( player ) )
				{
					format( temp, 23, " (%d)", get_user_health( player ) )
					add( msg, 511, temp )
					format( temp, 23, " (%d)", cs_get_user_armor( player, garbage ) )
					add( msg, 511, temp )
					switch ( gOrders[player] )
					{
						case NONE :
							format( temp, 23, " (/)" )
							
						case ATTACK :
							format( temp, 23, " (A)" )
							
						case DEFEND :
							format( temp, 23, " (D)" )
							
						case EQUIP :
							format( temp, 23, " (E)" )
							
					}
					add( msg, 511, temp )
					
					if ( gWaypointNum[player] )
						add( msg, 511, " [->]" )
				}
				else
					add( msg, 511, " (DEAD)" )
				
				if ( gSelected[player] )
					add( msg, 511, " *" )
					
				add( msg, 511, "^n" )
			}
			
			if ( squadNum[i] > 4 )
				add( msg, 511, "...^n" )
		}
		
		if ( !squadFlag )
			add( msg, 511, "None" )
		
		set_hudmessage( 255, 255, 255, HudX + 0.2, HudY, 0, 0.0, timer + 0.3, 0.0, 0.0, 3 )
		show_hudmessage( gCommander[CS_TEAM_T], "%s", msg )
	}
	
	for ( new i; i < 5; i++ )
		squadNum[i] = 0
	
	gCommander[CS_TEAM_CT] ? get_user_name( gCommander[CS_TEAM_CT], name, 32 ) : copy( name, 32, "None" )
	msgLen = format( msg, 511, "Commander^n%s^n^nTeam Money^n$%d^n^nSquad: ", name, gMoney[CS_TEAM_CT] )
	
	for ( new i; i < playersNum; i++ )
	{
		id = players[i]
		if ( id != gCommander[CS_TEAM_CT] && cs_get_user_team( id ) == CS_TEAM_CT )
		{
			if ( gSelected[id] )				
				numSelected[CS_TEAM_CT]++
			
			if ( gSquad[id] )
				squadMembers[gSquad[id] - 1][squadNum[gSquad[id] - 1]++] = id
			
			gSquad[id] ? format( temp, 23, "%d", gSquad[id] ) : copy( temp, 23, "None" )
			add( msg[msgLen], 511 - msgLen, temp )
			
			switch ( gOrders[id] )
			{
				case NONE :
					if ( gFollow[id] )
					{
						get_user_name( gFollow[id], followName, 32 )
						format( temp, 23, "Follow %s", followName )
					}
					else
						format( temp, 23, gWaypointNum[id] ? "Move to Waypoint" : "None/Free" )
				
				case ATTACK :
					format( temp, 23, "Attack" )
				
				case DEFEND : 
					format( temp, 23, "Defend" )
				
				case EQUIP :
					format( temp, 23, "Equip/Bomb/Hostages" )
			}
			
			add( msg, 511, "^n^nOrders: " )
			add( msg, 511, temp )
			
			if ( gWaypointNum[id] )
			{
				new Float:origin[3]
				pev( id, pev_origin, origin)
				
				new Float:distance = vector_distance( origin, gWaypoints[id][0] )
				if ( distance < 150.0 )
				{
					get_user_name( id, name, 32 )
					client_print( id, print_chat, "%s (RADIO): I'm in position.", name )
					client_print( gCommander[CS_TEAM_CT], print_chat, "%s (RADIO): I'm in position.", name )
					
					client_cmd( id, "spk %s", gSounds[SOUNDS:random_num( _:T_COMPLETE1, _:T_COMPLETE2 )] )
					client_cmd( gCommander[CS_TEAM_CT], "spk %s", gSounds[SOUNDS:random_num( _:T_COMPLETE1, _:T_COMPLETE2 )] )
					
					NextObjective( id )
				}
				else
				{					
					format( temp, 23, "%dm away", floatround( distance * 0.0254 ) )
					
					add( msg[msgLen], 511 - msgLen, "^n^nObjective^n" )
					add( msg[msgLen], 511 - msgLen, temp )
				}
			}
			
			set_hudmessage( 255, 255, 255, HudX, HudY, 0, 0.0, timer + 0.2, 0.0, 0.0, 4 )
			show_hudmessage( id, "%s", msg )
			
			msg[msgLen] = 0
		}
	}	
	
	if ( gCommander[CS_TEAM_CT] )
	{
		format( msg, 511, "Commander HUD^n^nTeam Money^n$%d^n^nSelected^n", gMoney[CS_TEAM_CT] )
		
		if ( numSelected[CS_TEAM_CT] )
		{			
			for ( new i, numFound; i < playersNum; i++ )
			{
				id = players[i]
				
				if ( gSelected[id] && cs_get_user_team( id ) == CS_TEAM_CT )
				{
					get_user_name( id, name, 32 )
					
					add( msg, 511, name )
					format( temp, 23, " (%d)", get_user_health( id ) )
					add( msg, 511, temp )
					format( temp, 23, " (%d)", cs_get_user_armor( id, garbage ) )
					add( msg, 511, temp )
					switch ( gOrders[id] )
					{
						case NONE :
							format( temp, 23, " (/)" )
							
						case ATTACK :
							format( temp, 23, " (A)" )
							
						case DEFEND :
							format( temp, 23, " (D)" )
							
						case EQUIP :
							format( temp, 23, " (E)" )
							
					}
					add( msg, 511, temp )
					
					if ( gWaypointNum[id] )
						add( msg, 511, " [->]" )
					
					add( msg, 511, "^n" )
					
					if ( ++numFound > 5 )
					{
						add( msg, 511, "..." )
						break
					}
				}
			}
		}
		else
			add( msg, 511, "^nNone" )
		
		set_hudmessage( 255, 255, 255, HudX, HudY, 0, 0.0, timer + 0.3, 0.0, 0.0, 4 )
		show_hudmessage( gCommander[CS_TEAM_CT], "%s", msg )
		
		format( msg, 511, "Squads^n" )
		
		new squadFlag
		for ( new i; i < 5; i++ )
		{
			if ( !squadNum[i] )
				continue
			
			squadFlag = 1
			
			format( temp, 23, "^nSquad %d^n", i + 1 )
			add( msg, 511, temp )
			
			for ( new j; j < squadNum[i] && j < 5; j++ )
			{
				player = squadMembers[i][j]
				get_user_name( player, name, 32 )
				add( msg, 511, name )
				if ( is_user_alive( player ) )
				{
					format( temp, 23, " (%d)", get_user_health( player ) )
					add( msg, 511, temp )
					format( temp, 23, " (%d)", cs_get_user_armor( player, garbage ) )
					add( msg, 511, temp )
					switch ( gOrders[player] )
					{
						case NONE :
							format( temp, 23, " (/)" )
							
						case ATTACK :
							format( temp, 23, " (A)" )
							
						case DEFEND :
							format( temp, 23, " (D)" )
							
						case EQUIP :
							format( temp, 23, " (E)" )
							
					}
					add( msg, 511, temp )
					
					if ( gWaypointNum[player] )
						add( msg, 511, " [->]" )
				}
				else
					add( msg, 511, " (DEAD)" )
				
				if ( gSelected[player] )
					add( msg, 511, " *" )
					
				add( msg, 511, "^n" )
			}
			
			if ( squadNum[i] > 4 )
				add( msg, 511, "...^n" )
		}
		
		if ( !squadFlag )
			add( msg, 511, "^nNone" )
		
		set_hudmessage( 255, 255, 255, HudX + 0.2, HudY, 0, 0.0, timer + 0.3, 0.0, 0.0, 3 )
		show_hudmessage( gCommander[CS_TEAM_CT], "%s", msg )
	}
	
	//set_task( timer, "ShowHUD" )
}

public BeamMessages()
{
	new players[32], playersNum, id
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
	{
		id = players[i]
		
		if ( cs_get_user_team( id ) == CS_TEAM_T )
		{
			if ( gFollow[id] )
			{
				if ( get_pcvar_num( pTeamObjectives ) )
				{
					for ( new j, player; j < playersNum; j++ )
					{
						player = players[j]
						if ( cs_get_user_team( player ) == CS_TEAM_T )
							CreateTrackingBeam( player, gFollow[id], id )
					}
				}
				else
				{
					CreateTrackingBeam( id, gFollow[id], id )
					if ( gCommander[CS_TEAM_T] )
						CreateTrackingBeam( gCommander[CS_TEAM_T], gFollow[id], id )
				}
			}
			else if ( gWaypointNum[id] )
			{
				if ( get_pcvar_num( pTeamObjectives ) )
				{
					for ( new j, player; j < playersNum; j++ )
					{
						player = players[j]
						if ( cs_get_user_team( player ) == CS_TEAM_T )
							CreateBeam( player, gWaypoints[id][0], id )
					}
				}
				else
				{
					CreateBeam( id, gWaypoints[id][0], id )
					if ( gCommander[CS_TEAM_T] )
						CreateBeam( gCommander[CS_TEAM_T], gWaypoints[id][0], id )
				}
			}
		}
	}
	
	for ( new i; i < playersNum; i++ )
	{
		id = players[i]
		
		if ( cs_get_user_team( id ) == CS_TEAM_CT )
		{
			if ( gFollow[id] )
			{
				if ( get_pcvar_num( pTeamObjectives ) )
				{
					for ( new j, player; j < playersNum; j++ )
					{
						player = players[j]
						if ( cs_get_user_team( player ) == CS_TEAM_CT )
							CreateTrackingBeam( player, gFollow[id], id )
					}
				}
				else
				{
					CreateTrackingBeam( id, gFollow[id], id )
					if ( gCommander[CS_TEAM_CT] )
						CreateTrackingBeam( gCommander[CS_TEAM_CT], gFollow[id], id )
				}
			}
			else if ( gWaypointNum[id] )
			{
				if ( get_pcvar_num( pTeamObjectives ) )
				{
					for ( new j, player; j < playersNum; j++ )
					{
						player = players[j]
						if ( cs_get_user_team( player ) == CS_TEAM_CT )
							CreateBeam( player, gWaypoints[id][0], id )
					}
				}
				else
				{
					CreateBeam( id, gWaypoints[id][0], id )
					if ( gCommander[CS_TEAM_CT] )
						CreateBeam( gCommander[CS_TEAM_CT], gWaypoints[id][0], id )
				}
			}
		}
	}
}

CreateBeam( id, Float:origin[3], to )
{
	new CsTeams:team = cs_get_user_team( to ), start[3]
	FVecIVec( origin, start )
	
	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id ) //message begin
	write_byte( TE_BEAMENTPOINT )
	write_short( to )
	write_coord( start[0] ) // start position
	write_coord( start[1] )
	write_coord( start[2] )
	write_short( gLaserSprite ) // sprite index
	write_byte( 0 ) // starting frame
	write_byte( 0 ) // frame rate in 0.1's
	write_byte( 10 ) // life in 0.1's
	write_byte( 10 ) // line width in 0.1's
	write_byte( 0 ) // noise amplitude in 0.01's
	write_byte( team == CS_TEAM_T ? 255 : 80 )
	write_byte( 80 )
	write_byte( team == CS_TEAM_T ? 80 : 255 )
	write_byte( 255 ) // brightness)
	write_byte( 0 ) // scroll speed in 0.1's
	message_end()
}

CreateTrackingBeam( id, from, to )
{
	new CsTeams:team = cs_get_user_team( to )
	
	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id ) //message begin
	write_byte( TE_BEAMENTS )
	write_short( to )
	write_short( from )
	write_short( gLaserSprite ) // sprite index
	write_byte( 0 ) // starting frame
	write_byte( 0 ) // frame rate in 0.1's
	write_byte( 10 ) // life in 0.1's
	write_byte( 10 ) // line width in 0.1's
	write_byte( 0 ) // noise amplitude in 0.01's
	write_byte( team == CS_TEAM_T ? 255 : 80 )
	write_byte( 80 )
	write_byte( team == CS_TEAM_T ? 80 : 255 )
	write_byte( 255 ) // brightness)
	write_byte( 0 ) // scroll speed in 0.1's
	message_end()
}

KillBeam( id )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_KILLBEAM )
	write_short( id )
	message_end()
}

public EventTextMsg()
{
	if ( gCommander[CS_TEAM_T] )
		SetNormal( gCommander[CS_TEAM_T], 0 )
	if ( gCommander[CS_TEAM_CT] )
		SetNormal( gCommander[CS_TEAM_CT], 0 )
	
	gLastTeleported[CS_TEAM_T] = gLastTeleported[CS_TEAM_CT] = gMoney[CS_TEAM_T] = gMoney[CS_TEAM_CT] = gCommander[CS_TEAM_T] = gCommander[CS_TEAM_CT] = 0
	
	if ( task_exists( VOTE_TASK + _:CS_TEAM_T ) )
		remove_task( VOTE_TASK + _:CS_TEAM_T )
	
	if ( task_exists( VOTE_TASK + _:CS_TEAM_CT ) )
		remove_task( VOTE_TASK + _:CS_TEAM_CT )
}

public EventResetHUD( id )
{
	if ( !ModEnabled() )
		return
	
	if ( gCommander[CS_TEAM_T] != id && gCommander[CS_TEAM_CT] != id )
		set_pdata_int( id, m_iHideHUD, HUD_MONEY )
		//message_begin( MSG_ONE_UNRELIABLE, gMsgHideWeapon, _, id )
		//write_byte( ( 1<<5 ) )
		//message_end()
	else
		set_task( 0.1, "ResetCommander", id )
}

public ResetCommander( id )
	if ( gCommander[CS_TEAM_T] == id || gCommander[CS_TEAM_CT] == id )
	{
		SetCommander( id )
		
		message_begin( MSG_ONE_UNRELIABLE, gMsgIdIcon, _, id )
		write_byte( 1 )
		write_string( gIconName )
		write_byte( 0 )
		write_byte( 160 )
		write_byte( 0 )
		message_end()
	}

public client_disconnect( id )
{
	if ( !ModEnabled() )
		return
	
	CheckGame()
	
	if ( gCommander[CS_TEAM_T] == id )
	{
		gCommander[CS_TEAM_T] = 0
		if ( NumActive( CS_TEAM_T ) > 1 )
		{
			client_print( 0, print_chat, "[CST] The terrorist commander has left the game. A vote has been started to find a new commander." )
			VoteCommander( CS_TEAM_T )
		}
		else
			client_print( 0, print_chat, "[CST] The terrorist commander has left the game." )
	}
	if ( gCommander[CS_TEAM_CT] == id )
	{
		gCommander[CS_TEAM_CT] = 0
		if ( NumActive( CS_TEAM_CT ) > 1 )
		{
			client_print( 0, print_chat, "[CST] The counter-terrorist commander has left the game. A vote has been started to find a new commander." )
			VoteCommander( CS_TEAM_CT )
		}
		else
			client_print( 0, print_chat, "[CST] The counter-terrorist commander has left the game." )
	}
	
	if ( pev_valid( gObjectiveEnt[id] ) )
	{
		engfunc( EngFunc_RemoveEntity, gObjectiveEnt[id] )
		gObjectiveEnt[id] = 0
	}
	
	CheckRound( cs_get_user_team( id ) )
	
	gSelected[id] = 0
	gOrders[id] = NONE
	gSquad[id] = 0
	
	UnFollow( id )
}

UnFollow( id )
{
	new players[32], playersNum, player
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
	{
		player = players[i]
		if ( gFollow[player] == id )
			gFollow[player] = 0
	}
}

public EventMoney( id )
{
	if ( !ModEnabled() || !is_user_alive( id ) )
		return PLUGIN_CONTINUE
	
	if ( gCommander[CS_TEAM_T] == id || gCommander[CS_TEAM_CT] == id )
	{
		cs_set_user_money( id, gMoney[cs_get_user_team( id )] )
		
		static weapons[32], x
		
		new shield = cs_get_user_shield( id )		
		if ( !( x = get_user_weapons( id, weapons, weapons[0] ) ) && !shield )
			return PLUGIN_CONTINUE
		
		new players[32], playersNum, player, CsTeams:team = cs_get_user_team( id ), teamPlayers[32], teamNum, weaponName[33]
		get_players( players, playersNum )
		
		new weapon = -1
		do 
			++weapon
		while ( ( x /= 2 ) >= 1)
		
		if ( !shield )
			get_weaponname( weapon, weaponName, 32 )
		
		for ( new i; i < playersNum; i++ )
		{
			player = players[i]
			if ( gSelected[player] && cs_get_user_team( player ) == team )
				teamPlayers[teamNum++] = player
		}
		
		strip_user_weapons( id )
		
		if ( !teamNum )
			return PLUGIN_CONTINUE
		
		new Float:curTime = get_gametime()
		if ( curTime - 0.5 < gLastBuy[team] )
			return PLUGIN_CONTINUE	
		
		gLastBuy[team] = curTime
		
		new cost = teamNum * gCosts[weapon], type = WeaponGroup( weapon )
		
		if ( shield )
		{
			type = 0
			copy( weaponName, 32, "weapon_shield" )
			gShieldFlag = 1
			set_task( 0.1, "DropShield", id )
			cost = teamNum * 2200
		}
			
		if ( gMoney[team] < cost )
		{
			client_print( id, print_chat, "[CST] You do not have enough money to buy this for everyone you have selected." )
			client_cmd( id, "spk %s", gSounds[C_MORE] )
			return PLUGIN_CONTINUE
		}
		
		for ( new i; i < teamNum; i++ )
		{
			player = teamPlayers[i]
			
			if ( type )
				drop_weapons( player, type )
			
			give_item( player, weaponName )
		}
		
		cs_set_user_money( id, gMoney[team] -= cost )
		
		set_user_maxspeed( id, 420.0 )
		
		return PLUGIN_CONTINUE
	}
	
	//message_begin( MSG_ONE_UNRELIABLE, gMsgHideWeapon, _, id )
	//write_byte( ( 1<<5 ) )
	//message_end()
	
	set_pdata_int( id, m_iHideHUD, HUD_MONEY )
	
	TeamAddMoney( cs_get_user_team( id ), cs_get_user_money( id ) )
	cs_set_user_money( id, 0, 0 )
	
	return PLUGIN_CONTINUE
}

public DropShield( id )
	engclient_cmd( id, "drop", "weapon_shield" )
	//client_cmd( id, "drop" )

TeamAddMoney( CsTeams:team, money )
{
	new maxMoney = get_pcvar_num( pMaxMoney )
	switch ( maxMoney )
	{
		case 0 :
			gMoney[team] += money
			
		case -1 :
		{
			new players[32], playersNum, teamMembers
			get_players( players, playersNum )
			
			for ( new i; i < playersNum; i++ )
				if ( cs_get_user_team( players[i] ) == team )
					teamMembers++
				
			gMoney[team] = min( gMoney[team] + money, 16000 * teamMembers )
		}
		
		default :
			gMoney[team] = min( gMoney[team] + money, maxMoney )
	}
}

public LogEventRoundEnd()
{
	gRoundFlag = 0
	
	for ( new i = 1; i < 33; i++ )
		if ( gBot[i] ) 
		{
			gBot[i] = 0
			remove_bot( i )
		}
}

public LogEventRoundStart()
{
	// Solve the speed glitch.
	if ( gCommander[CS_TEAM_T] )
		set_task( 0.1, "EventCurWeapon", gCommander[CS_TEAM_T] )
	
	if ( gCommander[CS_TEAM_CT] )
		set_task( 0.1, "EventCurWeapon", gCommander[CS_TEAM_CT] )
}

public LogEventSpawnedWithTheBomb()
	LogEventSpawnedWithTheBombEx( getLogUser() )

LogEventSpawnedWithTheBombEx( id )
    if ( ModEnabled() && gCommander[CS_TEAM_T] && !gRoundFlag )
	{
		gRoundFlag = 1
		//gBombDropped = 1
		engclient_cmd( id, "drop", "weapon_c4" )
		
		set_task( 0.1, "LogEventDroppedTheBombEx" )
	}

//public LogEventDroppedTheBomb()
//	if ( gCommander[CS_TEAM_T] && gBombDropped )
//		set_task( 0.2, "LogEventDroppedTheBombEx" )

public LogEventDroppedTheBombEx()
{
	BombMenu()
	//gBombDropped = 0
	
	gBomb = engfunc( EngFunc_FindEntityByString, -1, "classname", "weapon_c4" )
	if ( !gBomb )
		// wtf?
		return
	
	gBomb = pev( gBomb, pev_owner )
	if ( !gBomb )
		return
	
	engfunc( EngFunc_SetOrigin, gBomb, Float:{ 4096.0, 4096.0, 4096.0 } )
}

getLogUser()
{
	new logUser[80], name[32]
	read_logargv( 0, logUser, 79 )
	parse_loguser( logUser, name, 31 )
	
	return get_user_index( name )
}

public EventHLTV()
{
	if ( !ModEnabled() )
		return
	
	set_task( 0.1, "RoundStart" )
}

public RoundStart()
{	
	new ent
	while ( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", gAmmoClassname ) ) != 0 )
		engfunc( EngFunc_RemoveEntity, ent )
	
	ent = 0
	while ( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", gHealthClassname ) ) != 0 )
		engfunc( EngFunc_RemoveEntity, ent )
	
	if ( !gCommander[CS_TEAM_T] && !task_exists( VOTE_TASK + _:CS_TEAM_T ) && NumActive( CS_TEAM_T ) > 1 )
		VoteCommander( CS_TEAM_T )
	if ( !gCommander[CS_TEAM_CT] && !task_exists( VOTE_TASK + _:CS_TEAM_CT ) && NumActive( CS_TEAM_CT ) > 1 )
		VoteCommander( CS_TEAM_CT )
	
	gLastTeleported[CS_TEAM_T] = gLastTeleported[CS_TEAM_CT] = 0
}

VoteCommander( CsTeams:team )
{
	if ( gVoteMenu[team] )
		menu_destroy( gVoteMenu[team] )
	
	gVoteMenu[team] = menu_create( "Vote for a Commander", "VoteCommanderHandle" )
	
	new players[32], playersNum, id, name[33], idStr[3]
	get_players( players, playersNum )
	
	// Build the menu.
	for ( new i; i < playersNum; i++ )
	{
		id = players[i]
		
		// Using this method since get_playerrs() with flags is broken.
		if ( cs_get_user_team( id ) != team || !is_user_alive( id ) )
			continue
		
		get_user_name( id, name, 32 )
		num_to_str( id, idStr, 2 )
		
		menu_additem( gVoteMenu[team], name, idStr )
	}
	
	// Zero the votes.
	for ( new i; i < 33; i++ )
		gVotes[team][i] = 0
	
	// Display the menu.
	for ( new i; i < playersNum; i++ )
	{
		id = players[i]
		if ( cs_get_user_team( id ) == team )
			menu_display( id, gVoteMenu[team] )
	}
	set_task( get_pcvar_float( pVoteTime ), "VoteCommanderDone", VOTE_TASK + _:team )
}

public VoteCommanderHandle( id, menu, item )
{
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED
	
	new idStr[3], garbage, votedName[33], voterName[33]
	menu_item_getinfo( menu, item, garbage, idStr, 2, _, _, garbage )
	
	new vote = str_to_num( idStr )
	if ( !is_user_connected( vote ) )
	{
		client_print( id, print_chat, "[CST] That player is no longer connected. Your vote has been discarded." )
		return PLUGIN_HANDLED
	}
	
	new CsTeams:team = cs_get_user_team( id )
	if ( !task_exists( VOTE_TASK + _:team ) )
		return PLUGIN_HANDLED
	
	gVotes[team][vote]++
	
	if ( get_pcvar_num( pShowVotes ) )
	{
		get_user_name( vote, votedName, 32 )
		get_user_name( id, voterName, 32 )
		client_print( 0, print_chat, "[CST] %s has voted for %s to be the commander.", voterName, votedName )
	}
	
	return PLUGIN_HANDLED
}

public VoteCommanderDone( CsTeams:team )
{	
	team -= CsTeams:VOTE_TASK
	
	new winner, winnerVotes
	for ( new i = 1; i < 33; i++ )
		if ( gVotes[team][i] > winnerVotes )
		{
			winner = i
			winnerVotes = gVotes[team][i]
		}
	
	if ( NumActive( team ) < 2 )
		return
	
	if ( !winnerVotes )
	{
		client_print( 0, print_chat, "[CST] The vote for the %sterrorist commander has failed. It is being restarted.", team == CS_TEAM_T ? "" : "counter-" )
		VoteCommander( team )
		
		return
	}
	
	if ( !is_user_connected( winner ) || cs_get_user_team( winner ) != team || !is_user_alive( winner ) )
	{
		client_print( 0, print_chat, "[CST] The winner of the commander vote is no longer a valid candidate. The vote is being redone." )
		VoteCommander( team )
		return
	}
	
	new name[33]
	get_user_name( winner, name, 32 )
	
	client_print( 0, print_chat, "[CST] %s has won the commander nomination for the %sterrorists.", name, team == CS_TEAM_T ? "" : "counter-" )
	
	SetCommander( winner )
}

NumActive( CsTeams:team )
{
	new numActive, players[32], playersNum, player
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
	{
		player = players[i]
		
		if ( cs_get_user_team( player ) == team && player != gCommander[team] && is_user_alive( player ) )
			numActive++
	}
	
	return numActive
}

SetCommander( id )
{	
	new CsTeams:team = cs_get_user_team( id )
	gCommander[team] = id
	
	//message_begin( MSG_ONE_UNRELIABLE, gMsgResetHUD, _, id )
	//message_end()
	
	set_pdata_int( id, m_iHideHUD, get_pdata_int( id, m_iHideHUD ) & ~HUD_MONEY )
	
	if ( user_has_weapon( id, CSW_C4 ) )
		LogEventSpawnedWithTheBombEx( id )

	EventCurWeapon( id )
	//EventHideWeapon( id )
	strip_user_weapons( id )
	set_user_godmode( id, 1 )
	//set_user_maxspeed( id, 420.0 ) // happens inside EventCurWeapon()
	set_user_noclip( id, 1 )
	set_pev( id, pev_solid, SOLID_NOT )
	cs_set_user_armor( id, 0, CS_ARMOR_NONE )
	cs_set_user_nvg( id, 1 )
	
	client_cmd( id, "spk %s", gSounds[C_ONLINE] )
	
	set_task( 0.1, "EventMoney", id )
	set_task( 4.0, "GiveOrders", id )
	
	new players[32], playersNum
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
		if ( cs_get_user_team( players[i] ) == team )
		{
			gSelected[players[i]] = 0
			gOrders[players[i]] = NONE
		}
	
	gLastTeleported[team] = 0
	
	set_pev( id, pev_renderfx, kRenderFxGlowShell )
	set_pev( id, pev_rendercolor, Float:{ 0.0, 0.0, 0.0 } )
	set_pev( id, pev_rendermode, kRenderTransAlpha )
	set_pev( id, pev_renderamt, 0 )
}

SetNormal( id, doSpawn )
{
	new CsTeams:team
	if ( gCommander[CS_TEAM_T] == id )
		team = CS_TEAM_T
	else if ( gCommander[CS_TEAM_CT] == id )
		team = CS_TEAM_CT
	
	if ( !team )
		return
	
	gCommander[team] = 0

	if ( doSpawn )
	{
		give_item( id, team == CS_TEAM_T ? "weapon_glock18" : "weapon_usp" )
		give_item( id, "weapon_knife" )
		cs_user_spawn( id )
	}
	
	set_user_godmode( id, 0 )
	set_user_noclip( id, 0 )
	cs_set_user_money( id, 0 )
	set_pev( id, pev_solid, SOLID_BBOX )
	cs_set_user_nvg( id, 0 )
	
	set_pev( id, pev_renderfx, kRenderFxNone )
	set_pev( id, pev_rendercolor, Float:{ 0.0, 0.0, 0.0 } )
	set_pev( id, pev_rendermode, kRenderNormal )
	set_pev( id, pev_renderamt, 255 )
}

public GiveOrders( id )
	client_cmd( id, "spk %s", gSounds[C_GIVEORDERS] )

IsVisible( id, target )
{
	new Float:tOrigin[3], Float:iOrigin[3], Float:end[3]
	pev( id, pev_origin, iOrigin )
	pev( target, pev_origin, tOrigin )
	
	engfunc( EngFunc_TraceLine, iOrigin, tOrigin, 0, id, 0 )
	get_tr2( 0, TR_vecEndPos, end )
	
	return vector_distance( tOrigin, end ) < 50.0
}

WeaponGroup( weapon )
{
    //primary returns 1, secondary returns 2
    switch ( weapon )
    {
        case CSW_SCOUT, CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_UMP45, CSW_SG550, CSW_GALIL, CSW_FAMAS, CSW_AWP, CSW_MP5NAVY, CSW_M249, CSW_M3, CSW_M4A1, CSW_TMP, CSW_G3SG1, CSW_SG552, CSW_AK47, CSW_P90: return 1
        case CSW_P228, CSW_ELITE, CSW_FIVESEVEN, CSW_USP, CSW_GLOCK18, CSW_DEAGLE: return 2
    }
    
    return 0
}

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
    // Get user weapons
    static weapons[32], num, i, weaponid
    num = 0 // reset passed weapons count (bugfix)
    get_user_weapons(id, weapons, num)
    
    // Loop through them and drop primaries or secondaries
    for (i = 0; i < num; i++)
    {
        // Prevent re-indexing the array
        weaponid = weapons[i]
        
        if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
        {
            // Get the weapon entity
            static wname[32]//, weapon_ent
            get_weaponname(weaponid, wname, sizeof wname - 1)
            //weapon_ent = fm_find_ent_by_owner(-1, wname, id);
            
            // Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
            //set_pev(weapon_ent, pev_iuser1, cs_get_user_bpammo(id, weaponid))
            
            // Player drops the weapon and looses his bpammo
            engclient_cmd(id, "drop", wname)
            //fm_set_user_bpammo(id, weaponid, 0)
        }
    }
}

NextObjective( id )
{
	if ( gWaypointNum[id] == 1 )
		EndObjective( id )
	else if ( gWaypointNum[id] > 1 )
	{
		new CsTeams:team = cs_get_user_team( id )
		
		gWaypointNum[id]--
		
		for ( new i; i < gWaypointNum[id]; i++ )
			gWaypoints[id][i] = gWaypoints[id][i + 1]
		
		engfunc( EngFunc_SetOrigin, gObjectiveEnt[id], gWaypoints[id][0] )
		
		if ( get_pcvar_num( pTeamObjectives ) )
		{
			new players[32], playersNum
			get_players( players, playersNum )
			
			for ( new i, player; i < playersNum; i++ )
			{
				player = players[i]
				if ( cs_get_user_team( player ) == team )
					CreateBeam( player, gWaypoints[id][0], id )
			}
		}
		else
		{
			CreateBeam( id, gWaypoints[id][0], id )
			if ( gCommander[team] )
				CreateBeam( gCommander[team], gWaypoints[id][0], id )
		}
		
		client_cmd( id, "spk %s", gSounds[I_WAYPOINT] )
	}
}

EndObjective( id )
{
	if ( pev_valid( gObjectiveEnt[id] ) )
	{
		engfunc( EngFunc_RemoveEntity, gObjectiveEnt[id] )
		gObjectiveEnt[id] = 0
	}
	
	gWaypointNum[id] = 0
	gFollow[id] = 0
	KillBeam( id )
}

ModEnabled()
	return gActive && get_pcvar_num( pEnabled )
	
SetAlert( CsTeams:team, Float:origin[3] )
{
	gAlert[team] = origin
	gLastAlert[team] = get_gametime()
}

CheckGame()
{
	if ( !gActive )
		return
	
	new players[32], playersNum, CsTeams:team, numActive
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
	{
		team = cs_get_user_team( players[i] )
		if ( team == CS_TEAM_T || team == CS_TEAM_CT )
			numActive++
	}
	
	if ( numActive < get_pcvar_num( pMinPlayers ) )
	{
		EventTextMsg()
		
		new ent
		while ( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", gAmmoClassname ) ) != 0 )
			engfunc( EngFunc_RemoveEntity, ent )
		
		ent = 0
		while ( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", gHealthClassname ) ) != 0 )
			engfunc( EngFunc_RemoveEntity, ent )
		
		ent = 0
		while ( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", gObjectiveClass ) ) != 0 )
			engfunc( EngFunc_RemoveEntity, ent )
		
		gActive = 0
		client_print( 0, print_chat, "[CST] There are not enough players to continue with NS mod. The game will return to classic CS gameplay." )
		set_pcvar_num( pRestartRound, 1 )
	}
}

stock Float:fm_boxents_distance(boxent1, boxent2) {
	new Float:mins1[3], Float:maxs1[3]
	pev(boxent1, pev_absmin, mins1)
	pev(boxent1, pev_absmax, maxs1)

	new Float:mins2[3], Float:maxs2[3]
	pev(boxent2, pev_absmin, mins2)
	pev(boxent2, pev_absmax, maxs2)

	return fm_boxes_distance(mins1, maxs1, mins2, maxs2)
}

stock Float:fm_boxes_distance(const Float:mins1[3], const Float:maxs1[3], const Float:mins2[3], const Float:maxs2[3]) {
	new Float:dist[3]
	for (new i = 0; i < 3; ++i) {
		if (mins1[i] > maxs2[i])
			dist[i] = mins1[i] - maxs2[i]
		else if (mins2[i] > maxs1[i])
			dist[i] = mins2[i] - maxs1[i]
	}

	return vector_length(dist)
}

stock bool:fm_is_bbox_in_sight( Float:start[3], Float:end[3], bboxoffset ) 
{    
    new Float:mins[3]
    new Float:maxs[3]
    pev(entity, pev_absmin, mins)
    pev(entity, pev_absmax, maxs)
    
    mins[0] -= bboxoffset
    mins[1] -= bboxoffset
    mins[2] -= bboxoffset
    
    maxs[0] += bboxoffset
    maxs[1] += bboxoffset
    maxs[2] += bboxoffset
    
    new Float:boxEdges[8][3]
    
    //A
    boxEdges[0][0] = mins[0] 
    boxEdges[0][1] = mins[1]
    boxEdges[0][2] = mins[2]
    //B
    boxEdges[1][0] = mins[0] 
    boxEdges[1][1] = mins[1] + (maxs[1] - mins[1])
    boxEdges[1][2] = mins[2]
    //C
    boxEdges[2][0] = mins[0] + (maxs[0] - mins[0])
    boxEdges[2][1] = mins[1] + (maxs[1] - mins[1])
    boxEdges[2][2] = mins[2] 
    //D
    boxEdges[3][0] = mins[0] + (maxs[0] - mins[0])
    boxEdges[3][1] = mins[1] 
    boxEdges[3][2] = mins[2] 
    //E
    boxEdges[4][0] = mins[0] 
    boxEdges[4][1] = mins[1]
    boxEdges[4][2] = mins[2] + (maxs[2] - mins[2])
    //F
    boxEdges[5][0] = mins[0] 
    boxEdges[5][1] = mins[1] + (maxs[1] - mins[1])
    boxEdges[5][2] = mins[2] + (maxs[2] - mins[2])
    //G
    boxEdges[6][0] = mins[0] + (maxs[0] - mins[0])
    boxEdges[6][1] = mins[1] + (maxs[1] - mins[1])
    boxEdges[6][2] = mins[2] + (maxs[2] - mins[2])
    //H
    boxEdges[7][0] = mins[0] + (maxs[0] - mins[0])
    boxEdges[7][1] = mins[1] 
    boxEdges[7][2] = mins[2] + (maxs[2] - mins[2])
        
    for(new i = 0; i < 8; i++)
    {
        engfunc(EngFunc_TraceLine, eyepos, boxEdges[i], 0, index)
        new Float:fraction
        global_get(glb_trace_fraction, fraction)
        if (fraction == 1.0)
            return true
    }
    
    new Float:entpos[3]
    pev(entity, pev_origin, entpos)
    engfunc(EngFunc_TraceLine, eyepos, entpos, 0, index)

    switch (pev(entity, pev_solid)) {
        case SOLID_BBOX..SOLID_BSP: return (global_get(glb_trace_ent) == entity)
    }
    
    new Float:fraction
    global_get(glb_trace_fraction, fraction)
    return (fraction == 1.0)
}