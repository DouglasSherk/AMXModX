#if defined _clanapi_included
	#endinput
#endif
#define _clanapi_included

#pragma library "clanapi"

// -------- VARIABLES / CONFORMITY ---------

// I made this entire thing, but it's not so much
// advertising as it is to use with the included plugins
#define AUTHOR "Hawk552"

// Max number of members
#define MAX_MEMBERS 50

// Max number of ranks
#define RANKS 5

// If your mod is DOD or CS, or any other mod that supports
// HTML MOTDs, then leave this uncommented. Most other mods
// do not support HTML MOTDs, so comment this (add //) to
// disable it. It will still work - just not look as pretty.
#define HTML_MOTD

// This is used for the SQL stuff.
// NOT_CONNECTED - currently not connected to database
// INCORRECT_USAGE - native was used incorrectly
// QUERY_FAILURE - query made failed
// INTERNAL_FAILURE - there is a problem with the API
enum
{
	NOT_CONNECTED = -4,
	INCORRECT_USAGE,
	QUERY_FAILURE,
	INTERNAL_FAILURE
}

// These are the ranks (constants) of members.
// Be sure if you change this, you also change g_szRanks and RANKS.
enum
{
	NONE = 0,
	RECRUIT,
	MEMBER,
	COLEADER,
	LEADER
}

// These are the ranks (strings) of members.
// Be sure if you change this, you also change the above enum and RANKS.
stock const g_szRanks[RANKS][] =
{
	"None",
	"Recruit",
	"Member",
	"Co-Leader",
	"Leader"
}

stock const g_szSqlFile[] = "clan_sql.ini"

// -------- FORWARDS ---------

// Called when SQL is totally ready
// plugin_init will not work for SQL simplification natives
forward clan_init()

// Called on client_putinserver if the person that joined is a clan member
forward clan_member_join(id)

// Called on client_disconnect if the person that left was a clan member
forward clan_member_leave(id)

// -------- NATIVES ---------

// Whether or not the core is connected to the database.
// Using SQL simplification natives allow you to circumvent
// this, but for a function that doesn't use normal natives
// or continues on without them, you should use this
native bool:clan_connected()

// Gets Clan API version
// szVersion - where to format version
// iVersionLen - length of szVersion
native clan_get_version(szVersion[],iVersionLen)

// Adds a member to the database
// szAuthid - The Steam ID or WON ID of the player to be added
// iRank - Access to give them
// szName - The player's name, used to add to menus or commands
native clan_add_member(szAuthid[],iRank,szName[])

// Modifies member to set data to something else
// Use szAuthid as the base param, then iRank and szName
// as the changeable params.
native clan_mod_member(szAuthid[],iRank,szName[])

// Removes a clan member from database
// Specify only szAuthid[] or szName[]
native clan_del_member(szAuthid[] = "",szName[] = "")

// Gets a user's access based on their id or authid
// Specify only szAuthid[] or id
native clan_get_user_rank(id = 0,szAuthid[] = "")

// Returns number of members
native clan_get_membersnum()

// Gets info based on a member id
// iMemberNum - any member number between 1 - MAX_MEMBERS
// szAuthid - the authid of this user
// iAuthidLen - length of szAuthid
// szName - the name of this user (in database)
// iNameLen - length of szName
// NOTE: iMemberNum starts at 0, and ends at MAX_MEMBERS - 1.
native clan_get_user_info(iMemberNum,szAuthid[],iAuthidLen,szName[],iNameLen)

// Gets a member's name based on their id in game.
// This is NOT get_user_name, this is the name stored
// inside the database.
// id - id of the player in game
// szName - string to format
// iNameLen - length of szName
native clan_get_user_name(id,szName[],iNameLen)

// Finds a member id by name or authid
// szName - searches for a user id by name
// szAuthid - searches for a user id by authid
// NOTE: Only specify one of these
native clan_get_user_id(szName[] = "",szAuthid[] = "")

// Reloads member table
// DOES NOT reload anything else
native clan_reload()

////////////////////////////////
// SQL Simplification Natives //
////////////////////////////////

// Gets the dbinfo handle
native Handle:clan_sql_get_dbinfo()

// Queries database. All error handling is done by API, just check if
// the return value is higher than 0.
// szQuery - query to run
native Handle:clan_sql_query(szQuery[])

// Threaded queries database. All error handling is done by API, just check if
// the return value is higher than 0.
// szQuery - query to run
// szFunction - function to call once completed
// NOTE: Function prototype should look like this:
// public function(Handle:hQuery)
native clan_sql_threaded_query(szQuery[],szFunction[])

// Frees handles and closes connection. Add as many
// parameters as needed.
// Note: You must cast the query to _:, as in
// clan_sql_clean(_:query,_:db)
native clan_sql_clean(hQuery,...)

// -------- STOCKS ---------

// Converts a rank name into a number.
// szRank - Name of the rank.
stock clan_get_rank_num(szRank[])
{
	for(new iCount = 0;iCount < RANKS;iCount++)
		if(equali(g_szRanks[iCount],szRank))
			return iCount
			
	return -1
}

// Gets the table members are stored in.
// szTable - string to format
// iTableLen - length of szTable
stock clan_get_membertable(szTable[],iTableLen)
	return get_cvar_string("clan_membertable",szTable,iTableLen)

// Gets the clan tag
// szTag - string to format
// iTagLen - length of szTag
stock clan_get_tag(szTag[],iTagLen)
	return get_cvar_string("clan_tag",szTag,iTagLen)

// Gets the clan name
// szName - string to format
// iNameLen - length of szName
stock clan_get_name(szName[],iNameLen)
	return get_cvar_string("clan_name",szName,iNameLen)
