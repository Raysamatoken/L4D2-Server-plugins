new blockjoin[MAXPLAYERS + 1];

public jointyStart()
{
	RegConsoleCmd("sm_join", Command_Join);
	HookEvent("player_activate", Event_PlayerActivate, EventHookMode_Post);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);
}

public Action:Command_Join(client, args)
{
	if (client)
	{
		if (GetClientTeam(client) == 2)
		{
			PrintHintText(client, "You are already playing in a team of survivors!");
		}
		else if(IsClientIdle(client))
		{
			PrintHintText(client, "You are now idle. Press mouse to play as survivor");
		}
		else
		{
			if (blockjoin[client]++ > 1)
				return Plugin_Handled;
			
			if (TotalFreeBots() == 0)
				SpawntyFakeClient();

			CreateTimer(2.0, Timer_AutoJoinTeam, client);
			CreateTimer(5.0, Timer_UnBlockJoin, client);
		}
	}
	return Plugin_Handled;
}

public Action:Timer_UnBlockJoin(Handle:timer, any:client)
{
	blockjoin[client] = 0;
	
	return Plugin_Stop;
}

public Action:Timer_AutoJoinTeam(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			FakeClientCommand(client, "jointeam 2");
		}
	}
}

public Event_PlayerActivate(Handle: event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsFakeClient(client))
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) != 2)
			{
				if (TotalFreeBots() == 0)
					SpawntyFakeClient();
				
				CreateTimer(10.0, Timer_AutoJoinTeam, client);
			}
		}
	}
}

public evtBotReplacedPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	if(GetClientTeam(bot) == 2)
		CreateTimer(5.0, Timer_KickNoNeededBot, bot);
}

public Action:Timer_KickNoNeededBot(Handle:timer, any:bot)
{
	if(IsClientConnected(bot) && IsClientInGame(bot))
	{
		if(GetClientTeam(bot) != 2)
			return Plugin_Stop;
		
		decl String:BotName[100];
		GetClientName(bot, BotName, sizeof(BotName));			
		if(StrEqual(BotName, "SurvivorBot", true))
			return Plugin_Stop;
		
		if(!HasSpectator(bot))
		{
			ClearAllSlots(bot);
			KickClient(bot, "Kicking No Needed Bot");
		}
	}	
	return Plugin_Stop;
}

public Action:Timer_KickTYFakeClient(Handle:timer, any:client)
{
	if (IsClientConnected(client))
	{
		KickClient(client, "Kicking Fake Client");
	}

	return Plugin_Stop;
}

stock TotalFreeBots()
{
	new ty_free_mob = 0;

	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i))
			{
				if (GetClientTeam(i) == 2)
				{
					if (IsPlayerAlive(i))
					{
						if(!HasSpectator(i))
							ty_free_mob++;
					}
				}
			}
		}
	}
	
	return ty_free_mob;
}

bool:HasSpectator(client)
{
	decl String:sNetClass[12];
	GetEntityNetClass(client, sNetClass, sizeof(sNetClass));

	if (strcmp(sNetClass, "SurvivorBot") == 0)
	{
		if(!GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
			return false;
	}
	return true;
}

bool:IsClientIdle(client)
{
	decl String:sNetClass[12];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			if((GetClientTeam(i) == 2) && IsPlayerAlive(i))
			{
				if(IsFakeClient(i))
				{
					GetEntityNetClass(i, sNetClass, sizeof(sNetClass));
					if (strcmp(sNetClass, "SurvivorBot") == 0)
					{
						if (GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) == client)
							return true;
					}
				}
			}
		}
	}
	return false;
}

bool:SpawntyFakeClient()
{
	new bool:ret = false;
	new client = 0;
	client = CreateFakeClient("SurvivorBot");

	if (client != 0)
	{
		ChangeClientTeam(client, 2);

		if (DispatchKeyValue(client, "classname", "SurvivorBot") == true)
		{
			if (DispatchSpawn(client) == true)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && (GetClientTeam(i) == 2) && !IsFakeClient(i) && IsPlayerAlive(i) && i != client)
					{						
						new Float:teleportOrigin[3];
						GetClientAbsOrigin(i, teleportOrigin);
						TeleportEntity(client, teleportOrigin, NULL_VECTOR, NULL_VECTOR);
						break;
					}
				}
				
				CreateTimer(0.1, Timer_KickTYFakeClient, client, TIMER_REPEAT);
				ret = true;
			}
		}

		if (ret == false)
		{
			KickClient(client, "fake client problem?");
		}
	}

	return ret;
}