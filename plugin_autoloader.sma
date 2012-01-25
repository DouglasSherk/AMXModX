#include <amxmodx>
#include <amxmisc>

#define MAX_PLUGINS 200

new g_Plugin

enum _:PLUGINS
{
	LOADED,
	UNLOADED,
	PAUSED,
	DEBUG
}

new g_Plugins[PLUGINS][MAX_PLUGINS][33]
new g_PluginsNum[PLUGINS]

new g_ConfigFile[128]

public plugin_init()
{
	g_Plugin = register_plugin("Plugin Autoloader","1.0","Hawk552")
	LoadPlugins()
}

LoadPlugins()
{
	get_configsdir(g_ConfigFile,127)
	add(g_ConfigFile,127,"/autoloader.ini")
	
	new File = fopen(g_ConfigFile,"rt")
	if(!File)
		return
	
	new Buffer[128],Left[64],Right[64]
	while(!feof(File))
	{				
		fgets(File,Buffer,127)
		
		if(Buffer[0] == ';')
			continue
		
		parse(Buffer,Left,63,Right,63)
		replace_all(Buffer,127,"^n","")
		remove_quotes(Left)
		trim(Left)
		remove_quotes(Right)
		trim(Right)
		
		if(containi(Left,".amx") == -1)
			continue
		
		if(equali(Right,"pause"))
			copy(g_Plugins[PAUSED][g_PluginsNum[PAUSED]++],32,Left)
		else if(equali(Right,"unload"))
			copy(g_Plugins[UNLOADED][g_PluginsNum[UNLOADED]++],32,Left)
		else if(equali(Right,"debug"))
			copy(g_Plugins[DEBUG][g_PluginsNum[DEBUG]++],32,Left)
			
	}
	
	fclose(File)
	
	get_localinfo("amxx_plugins",g_ConfigFile,127)
	File = fopen(g_ConfigFile,"rt")
	if(!File)
		return
	
	new SplitHolder[2]
	while(!feof(File))
	{
		fgets(File,Buffer,127)
		if(containi(Buffer,";") != -1)
			strtok(Buffer,Buffer,127,SplitHolder,1,';',1)
		
		if(containi(Buffer,".amx") != -1)
		{
			replace(Buffer,127," debug","")
			remove_quotes(Buffer)
			trim(Buffer)
			copy(g_Plugins[UNLOADED][g_PluginsNum[UNLOADED]++],32,Buffer)
		}
	}
	
	fclose(File)
	
	new Num = get_pluginsnum(),Dummy[2]
	for(new Count = 1;Count <= Num;Count++)
	{			
		get_plugin(Count,g_Plugins[LOADED][g_PluginsNum[LOADED]],32,Dummy,1,Dummy,1,Dummy,1,Dummy,1)
		
		for(new Count2;Count2 < g_PluginsNum[PAUSED];Count2++)
			if(equali(g_Plugins[PAUSED][Count2],g_Plugins[LOADED][g_PluginsNum[LOADED]]))
				server_cmd("amxx pause ^"%s^"",g_Plugins[LOADED][g_PluginsNum[LOADED]++])
	}
	
	new FileName[128]
	get_configsdir(FileName,127)
	add(FileName,127,"/plugins-autoloader.ini")
	delete_file(FileName)
	
	File = fopen(FileName,"wt")
	if(!File)
		return
	
	new Directory[64],Plugin[64],Pos,Garbage,ThisPlugin[64],Flag
	// the only important thing here is the name itself
	get_plugin(g_Plugin,ThisPlugin,63,Plugin,1,Plugin,1,Plugin,1,Plugin,1)
	get_localinfo("amxx_pluginsdir",Directory,63)
	
	while(read_dir(Directory,Pos++,Plugin,63,Garbage))
	{		
		if(!Plugin[0] || equali(Plugin,".") || equali(Plugin,"..") || equali(ThisPlugin,Plugin) || containi(Plugin,"rem-") != -1)
			continue
		
		Flag = 0
		for(new Count;Count < g_PluginsNum[UNLOADED];Count++)
		{
			if(equali(g_Plugins[UNLOADED][Count],Plugin))
			{
				Flag = 1
				break
			}
		}
		
		if(Flag)
			continue
		
		fputs(File,Plugin)
		for(new Count;Count < g_PluginsNum[DEBUG];Count++)
			if(equali(Plugin,g_Plugins[DEBUG][Count]))
			{
				fputs(File," debug")
				break
			}				
		fputs(File,"^n")
	}
	
	fclose(File)

}

public plugin_end()
	LoadPlugins()