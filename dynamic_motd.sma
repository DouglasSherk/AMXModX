#include <amxmodx>
#include <amxmisc>

#define BGCOLOR "#0066CC"

new motd[5000];
new motd_read_file[] = "motd_dynamic.txt";
new motd_file[] = "motd.txt";
new visit_vault[] = "dynamic_motd_vault.ini";
new datadir[128];
new total_time;
new visits;

public plugin_init()
{
	register_plugin("Dynamic MOTD","1.1","Hawk552");
	
	Load_File();
	Read_File();
	Process_File();
	Write_MOTD();
}

public client_connect(id)
{
	if(is_user_bot(id))
	{
		return;
	}
	
	visits++;
	Write_File();
	Write_MOTD();
	
	return;
}

public Load_File()
{	
	get_datadir(datadir,127);
	format(datadir,127,"%s/%s",datadir,visit_vault);
	
	if(!file_exists(datadir))
	{
		Write_File();
	}
	
	new line[10],len;
	read_file(datadir,0,line,9,len);
	
	visits = str_to_num(line);
	
	read_file(datadir,1,line,9,len);
	
	total_time = str_to_num(line);
	
	return;
}

public Write_File()
{
	new str[10];
	format(str,9,"%i",visits);
	
	new str2[10];
	format(str,9,"%i",total_time);
	
	write_file(datadir,str,0);
	write_file(datadir,str2,1);
	//
	
	return;
}

public Read_File()
{
	if(!file_exists(motd_read_file))
	{
		new str[300];
		format(str,299,"<html>^n<body bgcolor=^"%s^">^n<b>Welcome! Visitors to date: <visits><br>Server uptime: <uptime></b>^n</body>^n</html>",BGCOLOR);
		write_file(motd_read_file,str,-1);
	}
	
	new i,len,motdlen;
	while(read_file(motd_read_file,i,motd[motdlen],4999,len))
	{
		motdlen += len;
		i++;
	}
}

public Process_File()
{	
	new visits_str[9];
	format(visits_str,8,"%i",visits);
	
	new Float:fuptime = get_gametime(), iuptime = floatround(fuptime), uptime[20];
	get_time_length(iuptime,0,uptime,19);
	
	while(containi(motd,"<visits>") != -1)
	{
		replace(motd,4999,"<visits>",visits_str);
	}
	
	while(containi(motd,"<uptime>") != -1)
	{
		replace(motd,4999,"<uptime>",uptime);
	}
}

public Write_MOTD()
{
	if(file_exists(motd_file) && !delete_file(motd_file))
	{
		log_amx("Unable to modify motd.txt. Please check for write protection.");
		return;
	}
	
	write_file(motd_file,motd,-1);
}

// **********************************************
// Thanks to Brad for everything below here
// **********************************************

#define TIMEUNIT_SECONDS 0
#define TIMEUNIT_MINUTES 1
#define TIMEUNIT_HOURS   2
#define TIMEUNIT_DAYS    3
#define TIMEUNIT_WEEKS   4

// define how many seconds are in each time unit
#define SECONDS_IN_MINUTE 60
#define SECONDS_IN_HOUR   3600
#define SECONDS_IN_DAY    86400
#define SECONDS_IN_WEEK   604800

stock get_time_length(iTimeUnits, iUnitType, cOutput[], iOutputLen)
{
	// iUnits:     The number of time units you want translated into verbose text.
	// iUnitType:  The type of unit (i.e. seconds, minutes, hours, days, weeks) that you are passing in.  See the defines for TIMEUNIT_.
	// cOutput:    The variable you want the verbose text to be placed in.
	// iOutputLen: The length of the cOutput variable.

	if (iTimeUnits > 0)
	{
		// determine the number of each time unit there are
		new iWeekCnt = 0, iDayCnt = 0, iHourCnt = 0, iMinuteCnt = 0, iSecondCnt = 0;
    
		switch (iUnitType)
		{
			case TIMEUNIT_SECONDS: iSecondCnt = iTimeUnits;
			case TIMEUNIT_MINUTES: iSecondCnt = iTimeUnits * SECONDS_IN_MINUTE;
			case TIMEUNIT_HOURS:   iSecondCnt = iTimeUnits * SECONDS_IN_HOUR;
			case TIMEUNIT_DAYS:    iSecondCnt = iTimeUnits * SECONDS_IN_DAY;
			case TIMEUNIT_WEEKS:   iSecondCnt = iTimeUnits * SECONDS_IN_WEEK;
		}
    
		iWeekCnt = iSecondCnt / SECONDS_IN_WEEK;
		iSecondCnt -= (iWeekCnt * SECONDS_IN_WEEK);
    
		iDayCnt = iSecondCnt / SECONDS_IN_DAY;
		iSecondCnt -= (iDayCnt * SECONDS_IN_DAY);
    
		iHourCnt = iSecondCnt / SECONDS_IN_HOUR;
		iSecondCnt -= (iHourCnt * SECONDS_IN_HOUR);
    
		iMinuteCnt = iSecondCnt / SECONDS_IN_MINUTE;
		iSecondCnt -= (iMinuteCnt * SECONDS_IN_MINUTE);
    
		// translate the unit counts into verbose text
		new iMaxElementIdx = -1;
		new acElement[5][33];
    
		if (iWeekCnt > 0)
			format(acElement[++iMaxElementIdx], 32, "%d w", iWeekCnt);
		if (iDayCnt > 0)
			format(acElement[++iMaxElementIdx], 32, "%d s", iDayCnt);
		if (iHourCnt > 0)
			format(acElement[++iMaxElementIdx], 32, "%d h", iHourCnt);
		if (iMinuteCnt > 0)
			format(acElement[++iMaxElementIdx], 32, "%d m", iMinuteCnt);
		if (iSecondCnt > 0)
			format(acElement[++iMaxElementIdx], 32, "%d s", iSecondCnt);
    
		switch(iMaxElementIdx)
		{
			case 0: format(cOutput, iOutputLen, "%s", acElement[0]);
			case 1: format(cOutput, iOutputLen, "%s, %s", acElement[0], acElement[1]);
			case 2: format(cOutput, iOutputLen, "%s, %s, %s", acElement[0], acElement[1], acElement[2]);
			case 3: format(cOutput, iOutputLen, "%s, %s, %s, %s", acElement[0], acElement[1], acElement[2], acElement[3]);
			case 4: format(cOutput, iOutputLen, "%s, %s, %s, %s, %s", acElement[0], acElement[1], acElement[2], acElement[3], acElement[4]);
		}
	}
} 
