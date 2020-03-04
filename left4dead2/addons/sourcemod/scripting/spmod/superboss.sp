#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6
#define ZOMBIECLASS_TANK	8

new Handle:l4d2_probability[9];
new Handle:l4d2_HP[9];
new Handle:l4d2_movemultiple[9];

public superbosstyStart()
{
	l4d2_probability[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d2_probability_superhunter", "10.0", "", FCVAR_PLUGIN);
	l4d2_probability[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d2_probability_supersmoker", "8.0", "", FCVAR_PLUGIN);
	l4d2_probability[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d2_probability_superboomer", "30.0", "", FCVAR_PLUGIN);
	l4d2_probability[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d2_probability_superjockey", "30.0", "", FCVAR_PLUGIN);
	l4d2_probability[ZOMBIECLASS_SPITTER] = CreateConVar("l4d2_probability_superspitter", "30.0", "", FCVAR_PLUGIN);
	l4d2_probability[ZOMBIECLASS_CHARGER] = CreateConVar("l4d2_probability_supercharger", "15.0", "", FCVAR_PLUGIN);
	l4d2_probability[ZOMBIECLASS_TANK] = CreateConVar("l4d2_probability_supertank", "30.0", "", FCVAR_PLUGIN);

	l4d2_HP[ZOMBIECLASS_HUNTER]  =  CreateConVar("l4d2_HP_superhunter", "5.0", "", FCVAR_PLUGIN);
	l4d2_HP[ZOMBIECLASS_SMOKER]  =  CreateConVar("l4d2_HP_supersmoker", "4.0", "", FCVAR_PLUGIN);
	l4d2_HP[ZOMBIECLASS_BOOMER]  =  CreateConVar("l4d2_HP_superboomer", "6.0", "", FCVAR_PLUGIN);
	l4d2_HP[ZOMBIECLASS_JOCKEY]  =  CreateConVar("l4d2_HP_superjockey", "6.0", "", FCVAR_PLUGIN);
	l4d2_HP[ZOMBIECLASS_SPITTER]  = CreateConVar("l4d2_HP_superspitter", "8.0", "", FCVAR_PLUGIN);
	l4d2_HP[ZOMBIECLASS_CHARGER]  = CreateConVar("l4d2_HP_supercharger", "5.0", "", FCVAR_PLUGIN);
	l4d2_HP[ZOMBIECLASS_TANK]  = CreateConVar("l4d2_HP_supertank", "1.0", "", FCVAR_PLUGIN);

	l4d2_movemultiple[ZOMBIECLASS_HUNTER]  =  CreateConVar("l4d2_movemultiple_superhunter", "1.3", "", FCVAR_PLUGIN);
	l4d2_movemultiple[ZOMBIECLASS_SMOKER]  =  CreateConVar("l4d2_movemultiple_supersmoker", "1.4", "", FCVAR_PLUGIN);
	l4d2_movemultiple[ZOMBIECLASS_BOOMER]  =  CreateConVar("l4d2_movemultiple_superboomer", "1.2", "", FCVAR_PLUGIN);
	l4d2_movemultiple[ZOMBIECLASS_JOCKEY]  =  CreateConVar("l4d2_movemultiple_superjockey", "1.3", "", FCVAR_PLUGIN);
	l4d2_movemultiple[ZOMBIECLASS_SPITTER]  = CreateConVar("l4d2_movemultiple_superspitter", "1.5", "", FCVAR_PLUGIN);
	l4d2_movemultiple[ZOMBIECLASS_CHARGER]  = CreateConVar("l4d2_movemultiple_supercharger", "1.6", "", FCVAR_PLUGIN);
	l4d2_movemultiple[ZOMBIECLASS_TANK]  = CreateConVar("l4d2_movemultiple_supertank", "1.3", "", FCVAR_PLUGIN);

	AutoExecConfig(true, "l4d2_superboss");
	
	HookEvent("player_spawn", Event_Player_Spawn);
}

public Action:Event_Player_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsValidEntity(client))
		return Plugin_Continue;

	if (client < 1)
		return Plugin_Continue;

	if(IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		new Float:p=GetConVarFloat(l4d2_probability[class]);
		new Float:r=GetRandomFloat(0.0, 100.0);
		if (r < p)
			CreateTimer(5.0, CreatesuperBoss, client);
	}
	return Plugin_Continue;
}

public Action:CreatesuperBoss(Handle:timer, any:client)
{
	if (IsServerProcessing() && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		new Float:hp = 0.0;
		new Float:move = 0.0;
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");

		hp = GetConVarFloat(l4d2_HP[class]);
		move = GetConVarFloat(l4d2_movemultiple[class]);
		new HP = 0;
		if(hp > 0.0)
		{
			HP = RoundFloat((GetEntProp(client, Prop_Send, "m_iHealth")*hp));
			if (HP > 65535)
			{
				HP = 65535;
			}
			SetEntProp(client, Prop_Send, "m_iHealth", HP);
			SetEntProp(client, Prop_Send, "m_iMaxHealth", HP);
		}
		if(move > 0.0)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue",  move);
		}

		if (HP < 10000)
			SetEntityRenderColor(client, 0, 153, 51, 255);
		else
			SetEntityRenderColor(client, 255, 51, 204, 255);
	}
	
	return Plugin_Stop;
}