#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define MAX_LINE_WIDTH	32

new ty_00000000;
new String:ty_10000000[55];
new ty_11000000[MAXPLAYERS + 1];
new String:ty_11100000[MAXPLAYERS + 1][MAX_LINE_WIDTH];
new ty_11110000[MAXPLAYERS + 1];
new ty_11111000[MAXPLAYERS + 1];
new ty_11111100[MAXPLAYERS + 1];
new ty_11111110[MAXPLAYERS + 1];
new bool:ty_defibed[MAXPLAYERS + 1];
new String:ty_11111111[MAXPLAYERS + 1][MAX_LINE_WIDTH];
new String:ty_01111111[MAXPLAYERS + 1][MAX_LINE_WIDTH];
new String:ty_00111111[MAXPLAYERS + 1][MAX_LINE_WIDTH];
new String:ty_00011111[MAXPLAYERS + 1][MAX_LINE_WIDTH];
new String:ty_defib[MAXPLAYERS + 1][MAX_LINE_WIDTH];

public Plugin:myinfo =
{
	name = "l4d2_ty_saveweapon",
	author = "ty",
	description = "l4d2_ty_saveweapon",
	version = "1.0.0.6",
	url = "http://www.semant1c.com/"
};

public OnPluginStart()
{
	HookEvent("player_spawn", Event_playerspawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("map_transition", Event_maptransition);
	HookEvent("player_transitioned", Event_playertransitioned);
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("defibrillator_used", defibEvent_PlayerDefibed);
	HookEvent("item_pickup", Event_PickUp);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return;
		
	ty_00000011(client);
}

public Action:defibEvent_PlayerDefibed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));

	if (!client)
		return;
	
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			ty_defibed[client] = true;
		}
	}
}

public Action:Event_PickUp(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return;
	
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (GetClientTeam(client) == 2)
			{
				if (!(GetPlayerWeaponSlot(client, 1) == -1)) 
				{
					decl String:modelname[128];
					GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_ModelName", modelname, 128);
					if (StrEqual(modelname, "models/weapons/melee/v_fireaxe.mdl", false))
						ty_defib[client] = "fireaxe";
					else if (StrEqual(modelname, "models/weapons/melee/v_crowbar.mdl", false))
						ty_defib[client] = "crowbar";
					else if (StrEqual(modelname, "models/weapons/melee/v_cricket_bat.mdl", false))
						ty_defib[client] = "cricket_bat";
					else if (StrEqual(modelname, "models/weapons/melee/v_katana.mdl", false))
						ty_defib[client] = "katana";
					else if (StrEqual(modelname, "models/weapons/melee/v_bat.mdl", false))
						ty_defib[client] = "baseball_bat";
					else if (StrEqual(modelname, "models/v_models/v_knife_t.mdl", false))
						ty_defib[client] = "knife";
					else if (StrEqual(modelname, "models/weapons/melee/v_electric_guitar.mdl", false))
						ty_defib[client] = "electric_guitar";
					else if (StrEqual(modelname, "models/weapons/melee/v_frying_pan.mdl", false))
						ty_defib[client] = "frying_pan";
					else if (StrEqual(modelname, "models/weapons/melee/v_machete.mdl", false))
						ty_defib[client] = "machete";
					else if (StrEqual(modelname, "models/weapons/melee/v_golfclub.mdl", false))
						ty_defib[client] = "golfclub";
					else if (StrEqual(modelname, "models/weapons/melee/v_tonfa.mdl", false))
						ty_defib[client] = "tonfa";
					else if (StrEqual(modelname, "models/weapons/melee/v_riotshield.mdl", false))
						ty_defib[client] = "riotshield";
					else
						GetEdictClassname(GetPlayerWeaponSlot(client, 1), ty_defib[client], MAX_LINE_WIDTH);
				}
			}
		}
	}
}

stock ty_00001111(client, String:command[], String:arguments[] = "")
{
	if (client)
	{
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}

public Action:Event_playerspawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client)
		return;

	if (!IsValidEntity(client))
		return;

	CreateTimer(0.1, ty_00000111, client);
}

public Action:Event_playertransitioned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client)
		return;

	if (!IsValidEntity(client))
		return;

	CreateTimer(0.1, ty_00000111, client);
}

public Action:Event_FinalWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				ty_00000011(i);
			}
		}
	}
}

public Action:ty_00000111(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
		return Plugin_Stop;

	if (GetClientTeam(client) != 2)
	{
		if (GetClientTeam(client) == 3 && IsFakeClient(client))
		{
			ty_11100000[client] = "";
			ty_00011111[client] = "";
			ty_11111111[client] = "";
			ty_01111111[client] = "";
			ty_00111111[client] = "";
			ty_defib[client] = "";
			ty_defibed[client] = false;
		}

		return Plugin_Stop;
	}

	if (GetPlayerWeaponSlot(client, 0) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
	if (GetPlayerWeaponSlot(client, 1) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	if (GetPlayerWeaponSlot(client, 2) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
	if (GetPlayerWeaponSlot(client, 3) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
	if (GetPlayerWeaponSlot(client, 4) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));

	if (ty_defibed[client] && !StrEqual(ty_defib[client], "", false))
	{
		ty_00001111(client, "give", ty_defib[client]);
		ty_defibed[client] = false;
	}
	else
		ty_00001111(client, "give", "pistol");

	return Plugin_Stop;
}

public OnMapStart()
{
	PrecacheAllItems();
	CreateTimer(0.5, ty_11000001);
}

public Action:ty_11000001(Handle:timer, any:client)
{
	ty_11100001();

	return Plugin_Stop;
}

public ty_11100001()
{
	GetCurrentMap(ty_10000000, 54);
	if (StrEqual(ty_10000000, "c1m1_hotel", false) || StrEqual(ty_10000000, "c2m1_highway", false) || StrEqual(ty_10000000, "c3m1_plankcountry", false) || StrEqual(ty_10000000, "c4m1_milltown_a", false) || StrEqual(ty_10000000, "c5m1_waterfront", false) || StrEqual(ty_10000000, "c6m1_riverbank", false) || StrEqual(ty_10000000, "c7m1_docks", false) || StrEqual(ty_10000000, "c8m1_apartment", false) || StrEqual(ty_10000000, "c9m1_alleys", false) || StrEqual(ty_10000000, "c10m1_caves", false) || StrEqual(ty_10000000, "c11m1_greenhouse", false) || StrEqual(ty_10000000, "c12m1_hilltop", false) || StrEqual(ty_10000000, "c13m1_alpinecreek", false))
	{
		ty_00000000 = 1;
	}
//	else if (StrEqual(ty_10000000, "2019_M1b", false) || StrEqual(ty_10000000, "c5m1_darkwaterfront", false) || StrEqual(ty_10000000, "l4d2_city17_01", false) || StrEqual(ty_10000000, "c1m1d_hotel", false) || StrEqual(ty_10000000, "l4d_dbd2dc_anna_is_gone", false) || StrEqual(ty_10000000, "Hideont01_v5", false) || StrEqual(ty_10000000, "L4d_ihm01_forest", false) || StrEqual(ty_10000000, "L4d2_ravenholmwar_1", false) || StrEqual(ty_10000000, "L4d2_stadium1_apartment", false))
//		ty_00000000 = 1;
	else
		ty_00000000 = 0;
}

ty_00000011(client)
{
	if (client)
	{
		ty_11100000[client] = "";
		ty_00011111[client] = "pistol";
		ty_11111111[client] = "";
		ty_01111111[client] = "";
		ty_00111111[client] = "";
		ty_defib[client] = "";
		ty_defibed[client] = false;
	}
}

public OnClientPutInServer(client)
{
	if (!client)
		return;

	if (IsFakeClient(client))
		return;

	if (ty_00000000 == 1)
		ty_00000011(client);

	ty_11000000[client] = 0;
	CreateTimer(1.5, ty_00000001, client);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, ty_11110001);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				ty_11000000[i] = 0;
				CreateTimer(1.1, ty_00000001, i);
			}
		}
	}
}

public Action:ty_00000001(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		if (ty_11000000[client]++ < 40)
			CreateTimer(0.5, ty_00000001, client);
		return Plugin_Stop;
	}

	ty_11000000[client] = 0;
	ty_11111001(client);

	return Plugin_Stop;
}

ty_11111001(client)
{
	if (!IsClientInGame(client))
		return;

	if (GetClientTeam(client) != 2)
		return;

	if (!IsPlayerAlive(client))
		return;

	if (GetPlayerWeaponSlot(client, 0) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
	if (GetPlayerWeaponSlot(client, 1) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	if (GetPlayerWeaponSlot(client, 2) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
	if (GetPlayerWeaponSlot(client, 3) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
	if (GetPlayerWeaponSlot(client, 4) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));

	if (IsFakeClient(client))
	{
		ty_00001111(client, "give", "pistol");
		return;
	}

	if (ty_00000000 == 1)
		ty_00000011(client);

	if (!StrEqual(ty_11100000[client], "", false))
	{
		ty_00001111(client, "give", ty_11100000[client]);

		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iExtraPrimaryAmmo", ty_11110000[client], 4);
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", ty_11111000[client], 4);
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec", ty_11111100[client], 4);
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ty_11111110[client], 4);
	}

	if (StrEqual(ty_00011111[client], "", false))
		ty_00001111(client, "give", "pistol");
	else 
	{
		if (StrEqual(ty_00011111[client], "dual_pistol", false)) 
		{
			ty_00001111(client, "give", "pistol");
			ty_00001111(client, "give", "pistol");
		}
		else
			ty_00001111(client, "give", ty_00011111[client]);
	}

	if (!StrEqual(ty_11111111[client], "", false))
		ty_00001111(client, "give", ty_11111111[client]);

	if (!StrEqual(ty_01111111[client], "", false))
		ty_00001111(client, "give", ty_01111111[client]);

	if (!StrEqual(ty_00111111[client], "", false))
		ty_00001111(client, "give", ty_00111111[client]);
}

ty_11111011(client, hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	new Float:newOverheal = hp * 1.0;
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

ty_10000001(client) 
{
	if (!IsClientInGame(client))
		return;
	if (GetClientTeam(client) != 2)
		return;
	if (IsFakeClient(client))
		return;
	if (!IsPlayerAlive(client))
		return;

	ty_00001111(client, "give", "health");
	SetEntProp(client, PropType:0, "m_iHealth", 100, 1);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
	ty_11111011(client, 0);

	if (!(GetPlayerWeaponSlot(client, 0) == -1)) 
	{
		GetWeaponNameAtSlot(client, 0, ty_11100000[client], MAX_LINE_WIDTH);
		if (ty_11100000[client][0] != 0) 
		{
			ty_11110000[client] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iExtraPrimaryAmmo", 4);
			ty_11111000[client] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", 4);
			ty_11111100[client] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec", 4);
			ty_11111110[client] = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
		}
	}
	else
	{
		ty_11100000[client] = "";
	}

	if (!(GetPlayerWeaponSlot(client, 1) == -1)) 
	{
		GetWeaponNameAtSlot(client, 1, ty_00011111[client], MAX_LINE_WIDTH);

		decl String:modelname[128];
		GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_ModelName", modelname, 128);
		if (StrEqual(modelname, "models/weapons/melee/v_fireaxe.mdl", false))
			ty_00011111[client] = "fireaxe";
		else if (StrEqual(modelname, "models/weapons/melee/v_crowbar.mdl", false))
			ty_00011111[client] = "crowbar";
		else if (StrEqual(modelname, "models/weapons/melee/v_cricket_bat.mdl", false))
			ty_00011111[client] = "cricket_bat";
		else if (StrEqual(modelname, "models/weapons/melee/v_katana.mdl", false))
			ty_00011111[client] = "katana";
		else if (StrEqual(modelname, "models/weapons/melee/v_bat.mdl", false))
			ty_00011111[client] = "baseball_bat";
		else if (StrEqual(modelname, "models/v_models/v_knife_t.mdl", false))
			ty_00011111[client] = "knife";
		else if (StrEqual(modelname, "models/weapons/melee/v_electric_guitar.mdl", false))
			ty_00011111[client] = "electric_guitar";
		else if (StrEqual(modelname, "models/weapons/melee/v_frying_pan.mdl", false))
			ty_00011111[client] = "frying_pan";
		else if (StrEqual(modelname, "models/weapons/melee/v_machete.mdl", false))
			ty_00011111[client] = "machete";
		else if (StrEqual(modelname, "models/weapons/melee/v_golfclub.mdl", false))
			ty_00011111[client] = "golfclub";
		else if (StrEqual(modelname, "models/weapons/melee/v_tonfa.mdl", false))
			ty_00011111[client] = "tonfa";
		else if (StrEqual(modelname, "models/weapons/melee/v_riotshield.mdl", false))
			ty_00011111[client] = "riotshield";
		else if (StrEqual(modelname, "models/v_models/v_dual_pistolA.mdl", false))
			ty_00011111[client] = "dual_pistol";
		else
			GetEdictClassname(GetPlayerWeaponSlot(client, 1), ty_00011111[client], MAX_LINE_WIDTH);
	}
	else
	{
		ty_00011111[client] = "pistol";
	}
	
	if (!(GetPlayerWeaponSlot(client, 2) == -1)) 
		GetWeaponNameAtSlot(client, 2, ty_11111111[client], MAX_LINE_WIDTH);
	else
		ty_11111111[client] = "";

	if (!(GetPlayerWeaponSlot(client, 3) == -1))
		GetWeaponNameAtSlot(client, 3, ty_01111111[client], MAX_LINE_WIDTH);
	else
		ty_01111111[client] = "";

	if (!(GetPlayerWeaponSlot(client, 4) == -1))
		GetWeaponNameAtSlot(client, 4, ty_00111111[client], MAX_LINE_WIDTH);
	else
		ty_00111111[client] = "";


	if (GetPlayerWeaponSlot(client, 0) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
	if (GetPlayerWeaponSlot(client, 1) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	if (GetPlayerWeaponSlot(client, 2) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
	if (GetPlayerWeaponSlot(client, 3) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
	if (GetPlayerWeaponSlot(client, 4) > -1)
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));
}

GetWeaponNameAtSlot(client, slot, String:weaponName[], maxlen) 
{
	new wIdx = GetPlayerWeaponSlot(client, slot);
	if (wIdx < 0)
	{
		weaponName[0] = 0;
		return;
	}

	GetEdictClassname(wIdx, weaponName, maxlen);
}

public Action:Event_maptransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				if (GetClientTeam(i) == 2)
				{
					if (IsPlayerAlive(i))
						ty_10000001(i);
					else
						ty_00000011(i);
				}
				else
					ty_00000011(i);
			}
			else
			{
				if (GetClientTeam(i) == 2)
				{
					if (IsPlayerAlive(i))
					{
						if (GetPlayerWeaponSlot(i, 0) > -1)
							RemovePlayerItem(i, GetPlayerWeaponSlot(i, 0));
						if (GetPlayerWeaponSlot(i, 1) > -1)
							RemovePlayerItem(i, GetPlayerWeaponSlot(i, 1));
						if (GetPlayerWeaponSlot(i, 2) > -1)
							RemovePlayerItem(i, GetPlayerWeaponSlot(i, 2));
						if (GetPlayerWeaponSlot(i, 3) > -1)
							RemovePlayerItem(i, GetPlayerWeaponSlot(i, 3));
						if (GetPlayerWeaponSlot(i, 4) > -1)
							RemovePlayerItem(i, GetPlayerWeaponSlot(i, 4));
					}
				}
			}
		}
	}
}

public Action:ty_11110001(Handle:timer, any:client)
{
	PrecacheAllItems();

	return Plugin_Stop;
}

public PrecacheHealth()
{
    CheckPrecacheModel("models/w_models/weapons/w_eq_Medkit.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_eq_defibrillator.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_eq_painpills.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_eq_adrenaline.mdl");
}
 
public PrecacheMeleeWeapons()
{
    CheckPrecacheModel("models/weapons/melee/w_cricket_bat.mdl");
    CheckPrecacheModel("models/weapons/melee/w_crowbar.mdl");
    CheckPrecacheModel("models/weapons/melee/w_electric_guitar.mdl");
    CheckPrecacheModel("models/weapons/melee/w_chainsaw.mdl");
    CheckPrecacheModel("models/weapons/melee/w_katana.mdl");
    CheckPrecacheModel("models/weapons/melee/w_machete.mdl");
    CheckPrecacheModel("models/weapons/melee/w_tonfa.mdl");
    CheckPrecacheModel("models/weapons/melee/w_frying_pan.mdl");
    CheckPrecacheModel("models/weapons/melee/w_fireaxe.mdl");
    CheckPrecacheModel("models/weapons/melee/w_bat.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_knife_t.mdl");
    CheckPrecacheModel("models/weapons/melee/w_golfclub.mdl");
    CheckPrecacheModel("models/weapons/melee/w_riotshield.mdl");
}
 
public PrecacheWeapons()
{
    CheckPrecacheModel("models/w_models/weapons/w_pistol_B.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_desert_eagle.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_smg_uzi.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_smg_a.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_shotgun.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_pumpshotgun_A.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_shotgun_spas.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_autoshot_m4super.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_sniper_military.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_sniper_mini14.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_rifle_m16a2.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_desert_rifle.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_rifle_ak47.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_m60.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_sniper_awp.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_grenade_launcher.mdl");
}
 
public PrecacheThrowWeapons()
{
    CheckPrecacheModel("models/w_models/weapons/w_eq_pipebomb.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_eq_molotov.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_eq_bile_flask.mdl");
}
 
public PrecacheAmmoPacks()
{
    CheckPrecacheModel("models/w_models/weapons/w_eq_explosive_ammopack.mdl");
    CheckPrecacheModel("models/w_models/weapons/w_eq_incendiary_ammopack.mdl");
}
 
public PrecacheMisc()
{
    CheckPrecacheModel("models/props_junk/explosive_box001.mdl");
    CheckPrecacheModel("models/props_junk/gascan001a.mdl");
    CheckPrecacheModel("models/props_equipment/oxygentank01.mdl");
    CheckPrecacheModel("models/props_junk/propanecanister001a.mdl");
}
 
public PrecacheSurvivors()
{
    CheckPrecacheModel("models/survivors/survivor_gambler.mdl");
    CheckPrecacheModel("models/survivors/survivor_manager.mdl");
    CheckPrecacheModel("models/survivors/survivor_coach.mdl");
    CheckPrecacheModel("models/survivors/survivor_producer.mdl");
    CheckPrecacheModel("models/survivors/survivor_teenangst.mdl");
    CheckPrecacheModel("models/survivors/survivor_biker.mdl");
    CheckPrecacheModel("models/survivors/survivor_namvet.mdl");
    CheckPrecacheModel("models/survivors/survivor_mechanic.mdl");
    CheckPrecacheModel("models/infected/witch.mdl");
    CheckPrecacheModel("models/infected/witch_bride.mdl");
    CheckPrecacheModel("models/infected/hulk.mdl");
    CheckPrecacheModel("models/infected/hulk_dlc3.mdl");
}
 
public PrecacheAllItems()
{
    PrecacheSurvivors();
    PrecacheHealth();
    PrecacheMeleeWeapons();
    PrecacheWeapons();
    PrecacheThrowWeapons();
    PrecacheAmmoPacks();
    PrecacheMisc();
}

public CheckPrecacheModel(String:Model[])
{
    if (!IsModelPrecached(Model)) 
    {
        PrecacheModel(Model);
    }
}