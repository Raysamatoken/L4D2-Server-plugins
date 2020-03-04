/* Includes */
#include <sourcemod>
#include <sceneprocessor>
#include <sdktools_functions>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0"

/* Plugin Information */
public Plugin:myinfo =  {
	name = "[L4D2] CSM The Passing Fix", 
	author = "DeathChaos25", 
	description = "Fixes an Issue with The Passing campaign where map restarts causes players who are L4D1 survivors to teleport to the bridge", 
	url = ""
}

/* Globals */
static bool:IsThePassing = false;
static bool:Restore[MAXPLAYERS + 1] = false;
static Survivor[MAXPLAYERS + 1] = -1;

/* Plugin Functions */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}
public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	CreateTimer(1.0, CSMFix, _, TIMER_REPEAT);
	CreateConVar("l4d2_csm_passing_fix", PLUGIN_VERSION, "Current Version of CSM The Passing Fix", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public OnMapStart()
{
	decl String:CurrentMap[100];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	if (StrEqual(CurrentMap, "c6m3_port") == true)
	{
		IsThePassing = true;
		for (new i = 0; i <= MAXPLAYERS; i++)
		{
			Survivor[i] = 0;
			Restore[i] = true;
		}
	}
	else IsThePassing = false;
}

public OnClientConnected(client)
{
	Restore[client] = true;
}
public Action:CSMFix(Handle:timer)
{
	if (!IsServerProcessing() || !IsThePassing)
	{
		return Plugin_Continue;
	}
	decl Float:Origin[3], Float:Button[3], Float:Stairs[3];
	// setpos_exact -695.448181 -573.218567 0.461658;
	Button[0] = -695.448181;
	Button[1] = -573.218567;
	Button[2] = 0.461658;
	
	//-2015.213989 -723.742432 -191.968750;
	Stairs[0] = -2015.213989;
	Stairs[1] = -723.742432;
	Stairs[2] = -191.968750;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", Origin);
			new Float:distance = GetVectorDistance(Button, Origin);
			new Float:distance2 = GetVectorDistance(Stairs, Origin);
			
			if (distance < 150)
			{
				for (new client = 1; client <= MaxClients; client++)
				{
					if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
					{
						if (Survivor[client] == 5 || Survivor[client] == 6 || Survivor[client] == 7)
						{
							if (Restore[client])
							{
								SetEntProp(client, Prop_Send, "m_survivorCharacter", Survivor[client]);
								Restore[client] = false;
								PrintHintText(client, "The Bug has been prevented.\nYour survivor character has been restored!");
							}
						}
					}
				}
			}
			else if (distance2 < 200)
			{
				for (new client = 1; client <= MaxClients; client++)
				{
					if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
					{
						if (Survivor[client] == 5 || Survivor[client] == 6 || Survivor[client] == 7)
						{
							if (Restore[client])
							{
								CreateTimer(0.1, ChangeSurvivor, GetClientUserId(client))
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsSurvivor(client) && Restore[client] && IsThePassing)
	{
		CreateTimer(3.0, ChangeSurvivor, GetClientUserId(client))
	}
}

public Action:ChangeSurvivor(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (IsSurvivor(client))
	{
		if (GetEntProp(client, Prop_Send, "m_survivorCharacter") == 5 || GetEntProp(client, Prop_Send, "m_survivorCharacter") == 6 || GetEntProp(client, Prop_Send, "m_survivorCharacter") == 7)
		{
			Survivor[client] = GetEntProp(client, Prop_Send, "m_survivorCharacter");
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 0);
			PrintHintText(client, "Your survivor has been changed to prevent a bug on this map.\nYour character will be restored once the bug has been prevented!");
		}
	}
} 