#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new String:current_map[55];

stock ClearAllSlots(client)
{
	if (GetPlayerWeaponSlot(client, 0) > -1) 
	{
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
	}
	if (GetPlayerWeaponSlot(client, 1) > -1) 
	{
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	}
	if (GetPlayerWeaponSlot(client, 2) > -1) 
	{
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
	}
	if (GetPlayerWeaponSlot(client, 3) > -1) 
	{
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
	}
	if (GetPlayerWeaponSlot(client, 4) > -1) 
	{
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));
	}
}

#include "spmod/drop.sp"
#include "spmod/superboss.sp"
#include "spmod/log.sp"
#include "spmod/monsterbots.sp"
#include "spmod/join.sp"

#define NOOBNAME false

#define PANIC_SOUND "npc/mega_mob/mega_mob_incoming.wav"

public Plugin:myinfo =
{
	name = "[L4D2] Supercoop Addition Options",
	author = "Accelerator & TY",
	description = "Supercoop Addition Options",
	version = "7.0",
	url = "<- URL ->"
};

public OnPluginStart()
{
	superbosstyStart(); // супербосы
	logtyStart(); // ведение логов
	monsterbotstyStart(); // спавн зараженных
	jointyStart(); // выход из спектров
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_now_it", Event_player_now_it);
	RegAdminCmd("sm_panic", CMD_Panic, ADMFLAG_SLAY, "");
	RegAdminCmd("sm_kickfakeclients", CMD_KickFakeClients, ADMFLAG_GENERIC, "");
	RegAdminCmd("sm_teleport", CMD_Teleport, ADMFLAG_UNBAN, "");
	RegAdminCmd("sm_veto", CMD_Veto, ADMFLAG_VOTE, "");
	RegConsoleCmd("sm_suicide", Command_Cfs);
	RegConsoleCmd("sm_ping", Command_Ping);
	RegConsoleCmd("sm_cfs", Command_Cfs);
	RegConsoleCmd("sm_drop", Command_Drop);
	RegConsoleCmd("sm_entityscount", Command_EntitysCount);
}

public OnClientPutInServer(client)
{
	new ClientsCount = GetClientCount(false);
	
	if (ClientsCount > 30)
	{
		//LogError("Warning! Clients count %i", ClientsCount);
		ty_Kickmob();
	}
	
	if (!IsFakeClient(client))
	{
		CreateTimer(5.0, logOnClientPutInServer, client); // ведение логов
		CreateTimer(20.0, JoinInGame, client);
		#if NOOBNAME
		CreateTimer(10.0, Kickclientnoobname, client);
		#endif
	}
}

public ty_Kickmob()
{
	//new String:Name[32];
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (IsFakeClient(i))
			{
				if (IsClientInGame(i))
				{
					if (IsPlayerAlive(i))
					{
						if (GetClientTeam(i) == 2)
						{
							ClearAllSlots(i);
						}
						
						if (GetClientTeam(i) == 3)
						{
							continue;
						}
					}
				}
				
				//GetClientName(i, Name, sizeof(Name));
				KickClient(i, "Server is full!");
				//LogError("FakeClient %s kicked!", Name);
			}
		}
	}
}

public Action:JoinInGame(Handle:timer, any:client)
{
	if (IsClientInGame(client) && (GetClientTeam(client) == 1))
	{
		PrintHintText(client, "Write !join to join in the game");
	}
	
	return Plugin_Stop;
}

public OnMapStart()
{
	GetCurrentMap(current_map, 54);
	
	PrecacheSound(PANIC_SOUND, true);
}

public Action:Event_RoundStart(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{	
	CreateTimer(0.1, ty_map);
	CreateTimer(1.0, TimedtyEntityes);

	return Plugin_Continue;
}

public Action:ty_map(Handle:timer, any:client)
{
	ty_l4d2_map();
	return Plugin_Stop;
}

public ty_l4d2_map()
{
	ServerCommand("exec maps\\%s.cfg", current_map);
}

public Action:TimedtyEntityes(Handle:timer, any:client)
{
	RemovetyEntityes();

	return Plugin_Stop;
}

public RemovetyEntityes()
{
	if (!IsModelPrecached("models/v_models/v_snip_awp.mdl"))
		PrecacheModel("models/v_models/v_snip_awp.mdl");
	if (!IsModelPrecached("models/v_models/v_snip_scout.mdl")) 
		PrecacheModel("models/v_models/v_snip_scout.mdl");
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (IsFakeClient(i))
			{
				KickClient(i);
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_player_now_it(Handle:event, const String:name[], bool:dontBroadcast)
{
	ExtinguishEntity(GetClientOfUserId(GetEventInt(event, "userid")));

	return Plugin_Continue;
}

/*public PanicEvent()
{
	new Director = CreateEntityByName("info_director");
	DispatchSpawn(Director);
	AcceptEntityInput(Director, "ForcePanicEvent");
	AcceptEntityInput(Director, "Kill");
}*/

public Action:PanicEvent(Handle:timer)
{
	EmitSoundToAll(PANIC_SOUND);
	
	new bot = CreateFakeClient("mob");
	
	if (bot > 0)
	{
		if (IsFakeClient(bot))
		{
			SpawntyCommand(bot, "z_spawn_old", "mob auto");
			KickClient(bot);
		}
	}

	return Plugin_Stop;
}

public Action:CMD_KickFakeClients(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_kickfakeclients <0-all|1-spectators|2-survivors|3-infected>");
		return Plugin_Handled;
	}

	decl String:clients[11];
	GetCmdArg(1, clients, sizeof(clients));
	
	new team = StringToInt(clients);
	
	new j = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i))
			{
				if (team > 0)
				{
					if (GetClientTeam(i) == team)
					{
						KickClient(i);
						j++;
					}
				}
				else
				{
					KickClient(i);
					j++;
				}
			}
		}
	}
	
	if (client)
		PrintToChat(client, "[SP] Kicked %i fake clients", j);
	else
		PrintToServer("[SP] Kicked %i fake clients", j);
	
	return Plugin_Continue;
}

public Action:CMD_Teleport(client, args)
{
	if (!client)
		return Plugin_Handled;
		
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_teleport <target> <client>");
		return Plugin_Handled;
	}
		
	decl String:target[65], String:player[65];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, player, sizeof(player));
	
	new thetarget = FindTarget(client, target, true);
	if (thetarget == -1)
	{
		return Plugin_Handled;
	}
	new toplayer = FindTarget(client, player, true);
	if (toplayer == -1)
	{
		return Plugin_Handled;
	}
	
	new Float:position[3];
	GetEntPropVector(toplayer, Prop_Send, "m_vecOrigin", position);
	
	TeleportEntity(thetarget, position, NULL_VECTOR, NULL_VECTOR);

	return Plugin_Continue;
}

public Action:CMD_Veto(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_veto <Yes|No>");
		return Plugin_Handled;
	}
	
	decl String:veto[31];
	GetCmdArg(1, veto, sizeof(veto));
	
	if (StrEqual(veto, "Yes", false) || StrEqual(veto, "No", false))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidEntity(i))
			{
				FakeClientCommand(i, "Vote %s", veto);
			}
		}
	}
	else
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:CMD_Panic(client, args)
{
	//PanicEvent();
	
	CreateTimer(2.0, PanicEvent);
	
	return Plugin_Continue;
}

public Action:Command_EntitysCount(client, args)
{
	PrintToChat(client, "Creatures Count on the server: %i/%i", GetClientCount(false), GetMaxClients());
	PrintToChat(client, "Entitys Count on the server: %i/%i", GetEntityCount(), GetMaxEntities());
	return Plugin_Continue;
}

public Action:Command_Cfs(client, args)
{
	if (client)
	{
		ForcePlayerSuicide(client);
		PrintHintText(client, "Command for Suicide");
	}
	return Plugin_Handled;
}

public Action:Command_Ping(client, args)
{
	PrintToChat(client, "\x05Ping (Current / Average):\nOutgouing: \x043%d / %d\x05 | Incoming: \x04%d / %d\x05 | Both: \x04%d / %d", RoundToZero(1000 * GetClientLatency(client, NetFlow:0)), RoundToZero(1000 * GetClientAvgLatency(client, NetFlow:0)), RoundToZero(1000 * GetClientLatency(client, NetFlow:1)), RoundToZero(1000 * GetClientAvgLatency(client, NetFlow:1)), RoundToZero(1000 * GetClientLatency(client, NetFlow:2)), RoundToZero(1000 * GetClientAvgLatency(client, NetFlow:2)));
}
#if NOOBNAME
public Action:Kickclientnoobname(Handle:timer, any:client)
{
	if (IsServerProcessing() && IsClientInGame(client))
	{
		new String:clientname[128];

		GetClientName(client, clientname, 128);
		if (StrEqual(clientname, "CSmaniaRU") || StrEqual(clientname, "wwwprogamerorg") || StrEqual(clientname, "wwwdeadlandsu") || StrEqual(clientname, "Unnamed") || StrEqual(clientname, "REVOLUTiON") || StrEqual(clientname, "admin") || StrEqual(clientname, "LDsupportcom") || StrEqual(clientname, "by FriendlyGameSRu") || StrEqual(clientname, "cssbcmnetua") || StrEqual(clientname, " ") || StrEqual(clientname, "aviararo") || StrEqual(clientname, "BrussOrgRu") || StrEqual(clientname, "nosteamro"))
		{
			KickClient(client, "Noobname");
		}
	}

	return Plugin_Stop;
}
#endif
stock SpawntyCommand(client, String:command[], String:arguments[] = "")
{
	if (client)
	{
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}
