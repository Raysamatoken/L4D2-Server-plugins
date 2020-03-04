new Handle:sm_logfile_chat;
new Handle:sm_logfile_commands;
//new Handle:db = INVALID_HANDLE;

public logtyStart()
{
	//ConnectDB();
	sm_logfile_chat = CreateConVar("sm_logfile_chat", "logs/chat.log", "", FCVAR_PLUGIN|FCVAR_SPONLY);
	sm_logfile_commands = CreateConVar("sm_logfile_commands", "logs/cmds.log", "", FCVAR_PLUGIN|FCVAR_SPONLY);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public Action:logOnClientPutInServer(Handle:timer, any:client)
{
	if (IsServerProcessing() && IsClientInGame(client) && !IsFakeClient(client))
	{
		decl String:file[PLATFORM_MAX_PATH];
		new String:ClientIP[24];
		new String:steamid[24];
		GetClientAuthString(client, steamid, sizeof(steamid));
		GetClientIP(client, ClientIP, sizeof(ClientIP), false);
		BuildPath(Path_SM, file, sizeof(file), "logs\\logip.log");
		LogToFile(file, "%N - %s - %s", client, steamid, ClientIP);
	}

	return Plugin_Stop;
}

/*public ConnectDB()
{
	if (SQL_CheckConfig("chatlog"))
	{
		new String:Error[256];
		db = SQL_Connect("chatlog", true, Error, sizeof(Error));

		if (db == INVALID_HANDLE)
			LogError("Failed to connect to database: %s", Error);
		else
			SendSQLUpdate("SET NAMES 'utf8'");
	}
	else
		LogError("Database.cfg missing 'chatlog' entry!");
}

public SendSQLUpdate(String:query[])
{
	if (db == INVALID_HANDLE)
		return;

	SQL_TQuery(db, SQLErrorCheckCallback, query);
}*/

public Action:OnClientCommand(client, args)
{
	decl String:CommandName[50];
	GetCmdArg(0, CommandName, sizeof(CommandName));

	if (StrEqual(CommandName, "developer", false) || StrEqual(CommandName, "fps_modem", false) || StrEqual(CommandName, "fps_max", false) || StrEqual(CommandName, "+speeding", false) || StrEqual(CommandName, "-speeding", false) || StrEqual(CommandName, "fps_max_override", false) || StrEqual(CommandName, "hldj_playaudio", false))
	{
		ServerCommand("sm_ban \"%N\" %i \"%s\"", client, 300, "banned command the console");
	}
	
	if (StrEqual(CommandName, "vocalize", false) || StrEqual(CommandName, "VModEnable", false) || StrEqual(CommandName, "vban", false) || StrEqual(CommandName, "menuselect", false) || StrEqual(CommandName, "sm_rank", false) || StrEqual(CommandName, "joingame", false) || StrEqual(CommandName, "jointeam", false) || StrEqual(CommandName, "spec_next", false) || StrEqual(CommandName, "choose_opendoor", false) || StrEqual(CommandName, "choose_closedoor", false) || StrEqual(CommandName, "spec_mode", false) || StrEqual(CommandName, "spec_prev", false) || StrEqual(CommandName, "changelevel", false) || StrEqual(CommandName, "sm_info", false) || StrEqual(CommandName, "sm_join", false) || StrEqual(CommandName, "sm_next", false))
	{
		return Plugin_Continue;
	}

	new String:cvar_logfile_commands[128];
	GetConVarString(sm_logfile_commands, cvar_logfile_commands, sizeof(cvar_logfile_commands));
	if (StrEqual(cvar_logfile_commands, "", false) == true)
	{
		return Plugin_Continue;
	}

	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), cvar_logfile_commands);

	if (args > 0)
	{
		decl String:argstring[255];
		GetCmdArgString(argstring, sizeof(argstring));
		LogToFileEx(file, "%N - %s [%s]", client, CommandName, argstring);
		return Plugin_Continue;
	}

	LogToFileEx(file, "%N - %s", client, CommandName);
	return Plugin_Continue;
}

public Action:Command_Say(client, args)
{
	new String:cvar_logfile_chat[128];
	GetConVarString(sm_logfile_chat, cvar_logfile_chat, sizeof(cvar_logfile_chat));
	if (StrEqual(cvar_logfile_chat, "", false) == true)
	{
		return Plugin_Continue;
	}

	if (!client)
	{
		return Plugin_Continue;
	}

	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}

	new startidx = 0;

	if (text[strlen(text) - 1] == '"')
	{
		text[strlen(text) - 1] = '\0';
		startidx = 1;
	}

	/*new String:Name[32], String:IP[32], String:Steamid[32];
	GetClientName(client, Name, sizeof(Name));
	GetClientAuthString(client, Steamid, sizeof(Steamid));
	GetClientIP(client, IP, sizeof(IP), true);
	
	ReplaceString(Name, sizeof(Name), "<?php", "");
	ReplaceString(Name, sizeof(Name), "<?PHP", "");
	ReplaceString(Name, sizeof(Name), "?>", "");
	ReplaceString(Name, sizeof(Name), "\\", "");
	ReplaceString(Name, sizeof(Name), "\"", "");
	ReplaceString(Name, sizeof(Name), "'", "");
	ReplaceString(Name, sizeof(Name), ";", "");
	ReplaceString(Name, sizeof(Name), "´", "");
	ReplaceString(Name, sizeof(Name), "`", "");
	
	decl String:text2[192];
	SQL_EscapeString(db, text[startidx], text2, sizeof(text2));
	
	decl String:query[1024];
	Format(query, sizeof(query), "INSERT INTO `chatlog` (`name`, `steamid`, `time`, `ip`, `msg`) VALUES ('%s', '%s', '%i', '%s', '%s')", Name, Steamid, GetTime(), IP, text2);
	SQL_TQuery(db, SQLErrorCheckCallback, query);*/
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), cvar_logfile_chat);
	LogToFileEx(file, "[%N]: %s", client, text[startidx]);

	return Plugin_Continue;
}

/*public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (db == INVALID_HANDLE)
		return;

	if(!StrEqual("", error))
		LogError("SQL Error: %s", error);
}*/