#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define Plugin_Version "1.1"
#define CHAT_TAGS "\x04[TakeOver]\x03"


static Handle:hCvar_EnableMe = INVALID_HANDLE;
static bool:g_bEnableMe = true;
static bool:g_bTakeOverInprogress = false;

static bool:g_bAwaitingBotTakeover[MAXPLAYERS+1] = false;

static Handle:hMaxSwitches = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[L4D/L4D2]BotTakeOver",
	author = "Lux",
	description = "AutoTakesOver a bot UponDeath/OnBotSpawn",
	version = Plugin_Version,
	url = "https://forums.alliedmods.net/showthread.php?p=2494319#post2494319"
};

public OnPluginStart()
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if(!StrEqual(sGameName, "left4dead") && !StrEqual(sGameName, "left4dead2"))
	SetFailState("This plugin only runs on Left 4 Dead and Left 4 Dead 2!");
	
	hMaxSwitches = FindConVar("vs_max_team_switches");
	if (hMaxSwitches == INVALID_HANDLE)
	{
		SetFailState("This Is a Strage Error Either Cvar not found or the GameCheck Failed");
	}
	
	CreateConVar("BotTakeOver", Plugin_Version, "Plugin_Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	hCvar_EnableMe = CreateConVar( "TakeOverEnabled", "1", "[1/0 = ENABLED/DISABLED]", FCVAR_NOTIFY);
	
	HookEvent("player_death", ePlayerDeath);
	HookEvent("player_team", eTeamChange);
	HookEvent("round_end", eRoundEndStart);
	HookEvent("round_start", eRoundEndStart);
	HookEvent("player_spawn", ePlayerSpawn);
	
	HookConVarChange(hCvar_EnableMe, eConvarChanged);
	
	CvarsChanged();
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

CvarsChanged()
{
	g_bEnableMe = GetConVarInt(hCvar_EnableMe) > 0;
}

public OnClientPutInServer(iClient)
{
	if(!IsFakeClient(iClient))
		g_bAwaitingBotTakeover[iClient] = true;
}

public ePlayerDeath(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	if(!g_bEnableMe)
	return;
	
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || IsFakeClient(iClient))
	return;
	
	if(GetClientTeam(iClient) != 2 || IsPlayerAlive(iClient))
	return;
	
	g_bAwaitingBotTakeover[iClient] = true;
	
	CreateTimer(0.5, TakeOverBot, iClient, TIMER_FLAG_NO_MAPCHANGE);
}

public eTeamChange(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	if(g_bTakeOverInprogress)
	return;
	
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsClientInGame(iClient) || IsFakeClient(iClient))
	return;
	
	switch(GetClientTeam(iClient))
	{
		case 3:
		{
			g_bAwaitingBotTakeover[iClient] = false;
		}
		case 2:
		{
			if(IsPlayerAlive(iClient))
			{
				g_bAwaitingBotTakeover[iClient] = false;
				return;
			}
		}
		case 1:
		{
			g_bAwaitingBotTakeover[iClient] = true;
		}
	}
}
//playerspawn is triggered even when someone changes team and a survivor bot is spawned
public ePlayerSpawn(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsClientInGame(iClient) || !IsFakeClient(iClient) || GetClientTeam(iClient) != 2)
	return;
	//check if any survivors are waiting for a takeover and clean up any bools that are incorrect
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != 2 || IsPlayerAlive(i))
		{
			g_bAwaitingBotTakeover[i] = false;
			continue;
		}
		
		if(g_bAwaitingBotTakeover[i])
		{
			iClient = i;
			break;
		}
	}
	
	if(iClient < 1)
		return;
	
	CreateTimer(0.5, TakeOverBot, iClient, TIMER_FLAG_NO_MAPCHANGE);
}

public eRoundEndStart(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		g_bAwaitingBotTakeover[i] = false;
	}
}

public OnClientDisconnect(iClient)
{
	g_bAwaitingBotTakeover[iClient] = false;
}

public Action:TakeOverBot(Handle:hTimer, any:iClient)
{
	if(!IsClientInGame(iClient) || GetClientTeam(iClient) != 2 || IsFakeClient(iClient) || IsPlayerAlive(iClient))
	{
		g_bAwaitingBotTakeover[iClient] = false;
		return Plugin_Stop;
	}
	
	if(!CheckAvailableBot(2))
	{
		PrintToChat(iClient, "%sNo Avalable Bots\n Awaiting Free Bot For \x04Hostle TakeOver", CHAT_TAGS);
		return Plugin_Stop;
	}
	
	static iMaxSwitches;
	iMaxSwitches = GetConVarInt(hMaxSwitches);
	SetConVarInt((hMaxSwitches), 99999);
	
	g_bTakeOverInprogress = true;//this bool is to stop any code from being run on eChangeTeam hook on the stack to save cpu and any unintended bad effects
	ChangeClientTeam(iClient, 1);
	FakeClientCommand(iClient,"jointeam 2");
	g_bTakeOverInprogress = false;
	
	SetConVarInt((hMaxSwitches), iMaxSwitches);
	if(IsPlayerAlive(iClient))
	g_bAwaitingBotTakeover[iClient] = false;
	
	return Plugin_Stop;
}

static bool:CheckAvailableBot(iTeam)
{
	static bool:bBot;
	bBot = false;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		continue;
		
		if(IsFakeClient(i) && GetClientTeam(i) == iTeam && IsPlayerAlive(i))
		{
			if(!HasIdlePlayer(i))
			{
				bBot = true;
				break;
			}
		}
	}
	return bBot;
}

static bool:HasIdlePlayer(iBot)
{
	if(!IsClientInGame(iBot) || GetClientTeam(iBot) != 2 || !IsPlayerAlive(iBot))
	return false;
	
	decl String:sNetClass[12];
	GetEntityNetClass(iBot, sNetClass, sizeof(sNetClass));
	
	if(IsFakeClient(iBot) && strcmp(sNetClass, "SurvivorBot") == 0)
	{
		new client = GetClientOfUserId(GetEntProp(iBot, Prop_Send, "m_humanSpectatorUserID"));
		if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 1)
		return true;
	}
	return false;
}


