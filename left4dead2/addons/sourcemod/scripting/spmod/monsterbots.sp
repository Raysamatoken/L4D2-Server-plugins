new nummonsters;
new Handle:monstermaxbots;
new Handle:monsterbotson;
new Handle:monsterinterval;
new timertick;

public monsterbotstyStart()
{
	monstermaxbots = CreateConVar("monsterbots_maxbots", "4", "", FCVAR_PLUGIN, true, 0.0);
	monsterbotson = CreateConVar("monsterbots_on", "0", "", FCVAR_PLUGIN, true, 0.0);
	monsterinterval = CreateConVar("monsterbots_interval", "20", "", FCVAR_PLUGIN, true, 0.0);
	CreateTimer(1.0,TimerUpdate, _, TIMER_REPEAT);
}

stock GetAnyClient()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			return i;
		}
	}
	return 0;
}

public Action:Kickbot(Handle:timer, any:client)
{
	if (IsClientConnected(client))
	{
		if (IsFakeClient(client))
		{
			KickClient(client, "Kicking FakeClient");
		}
	}
	return Plugin_Stop;
}

CountMonsters()
{
	nummonsters = 0;
	decl String: classname[32];

	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 3)
			{
				if (IsFakeClient(i))
				{
					GetClientModel(i, classname, sizeof(classname));
					if (StrContains(classname, "smoker") || StrContains(classname, "boomer") || StrContains(classname, "hunter") || StrContains(classname, "spitter") || StrContains(classname, "jockey") || StrContains(classname, "charger"))
					{
						nummonsters++;
					}
				}
			}
		}
	}
}

stock SpawnCommand(client, String:command[], String:arguments[] = "")
{
	if (client)
	{
		ChangeClientTeam(client,3);
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
		CreateTimer(0.1,Kickbot,client);
	}
}

public ty_1234567654321()
{
	if (!IsServerProcessing())
		return;
	
	if (GetConVarBool(monsterbotson))
	{
		CountMonsters();
		new ty_123321 = GetConVarInt(monstermaxbots);
		if (6 <= ty_123321)
			ty_123321 = 5;

		if (nummonsters < ty_123321)
		{
			new bot = CreateFakeClient("Monster");
			if (bot > 0)
			{
				new random = GetRandomInt(1, 6);
				switch(random)
				{
					case 1:
						SpawnCommand(bot, "z_spawn_old", "smoker auto");
					case 2:
						SpawnCommand(bot, "z_spawn_old", "boomer auto");
					case 3:
						SpawnCommand(bot, "z_spawn_old", "hunter auto");
					case 4:
						SpawnCommand(bot, "z_spawn_old", "spitter auto");
					case 5:
						SpawnCommand(bot, "z_spawn_old", "jockey auto");
					case 6:
						SpawnCommand(bot, "z_spawn_old", "charger auto");
				}
			}

			CreateTimer(0.3, TimerCountMonsters);
		}
	}
}

public Action:TimerCountMonsters(Handle:timer, any:client)
{
	ty_123789();
}

public ty_123789()
{
	CountMonsters();
	if (nummonsters == 0)
	{
		if (GetAnyClient() == 0)
			return;

		new ty_random_0 = GetRandomInt(1, 4);
		switch(ty_random_0)
		{
			case 1:
				SpawntyCommand(GetAnyClient(), "z_spawn", "smoker");
			case 2:
				SpawntyCommand(GetAnyClient(), "z_spawn", "hunter");
			case 3:
				SpawntyCommand(GetAnyClient(), "z_spawn", "jockey");
		}
	}
}

public Action:TimerUpdate(Handle:timer)
{
	timertick += 1;
	if (timertick >= (2 + GetConVarInt(monsterinterval)))
	{
		ty_1234567654321();
		timertick = 0;
	}
}