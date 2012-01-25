#include <amxmodx>
#include <amxmisc>
#include <clanapi>

#define JOIN_OFFSET 12932193

public plugin_init()
{
	new szVersion[10]
	clan_get_version(szVersion,9)
	register_plugin("Clan API - Tag Protection",szVersion,AUTHOR)
}

public clan_member_join(id)
	set_task(10.0,"fnCheckName",id + JOIN_OFFSET)

public client_infochanged(id)
	fnCheckName(id)
	
public fnCheckName(id)
{	
	new Mode
	if(id > 32)
	{
		id -= JOIN_OFFSET
		Mode = 1
	}
	
	if(clan_get_user_rank(id))
		return PLUGIN_CONTINUE
	
	static szName[33],szTag[10],szTemp[33]
	clan_get_tag(szTag,9)
	
	if(!szTag[0])
		return PLUGIN_CONTINUE
		
	get_user_info(id,"name",szName,32)
	get_user_name(id,szTemp,32)
	
	if(containi(szName,szTag) != -1 && (!equali(szTemp,szName) && !Mode))
	{		
		server_cmd("kick ^"%s^" ^"Clan tag %s reserved.^"",szName,szTag)
		
		static szAuthid[36]
		get_user_authid(id,szAuthid,35)
		
		log_amx("Kicked %s<%s><%d> for wearing reserved tag %s",szName,szAuthid,get_user_userid(id),szTag)
	
		client_print(0,print_chat,"[CLAN] %s was kicked for wearing the tag %s without being a member.",szName,szTag)
	}
	
	return PLUGIN_CONTINUE
}
