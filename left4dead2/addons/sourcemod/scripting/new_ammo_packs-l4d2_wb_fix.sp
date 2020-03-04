#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

bool bCooldown[MAXPLAYERS+1], bAmmoGiven[2048];

public Plugin myinfo =
{
	name = "[L4D2] New Ammo Packs - Weaponry Box Fix",
	author = "cravenge",
	description = "Fixes Weapons With No Ammunitions After Deploying Weaponry Boxes.",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookEvent("ammo_pile_weapon_cant_use_ammo", OnAmmoPileFailed, EventHookMode_Pre);
}

public void OnPluginEnd()
{
	UnhookEvent("round_start", OnRoundStart);
	UnhookEvent("ammo_pile_weapon_cant_use_ammo", OnAmmoPileFailed, EventHookMode_Pre);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
		}
	}
}

public void OnAllPluginsLoaded()
{
	if (!LibraryExists("nap-l4d2_helpers"))
	{
		SetFailState("[FIX] Main Plugin Missing!");
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnWeaponEquipPost(int client, int weapon)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		return;
	}
	
	if (weapon == -1 || !IsValidEntity(weapon) || !IsValidEdict(weapon))
	{
		return;
	}
	
	if (!bAmmoGiven[weapon])
	{
		bAmmoGiven[weapon] = true;
		
		int iWeaponAmmo = 0;
		char sWeaponEquipped[64];
		
		GetEdictClassname(weapon, sWeaponEquipped, sizeof(sWeaponEquipped));
		if (StrEqual(sWeaponEquipped, "weapon_smg", false) || StrEqual(sWeaponEquipped, "weapon_smg_silenced", false) || StrEqual(sWeaponEquipped, "weapon_smg_mp5", false))
		{
			iWeaponAmmo = FindConVar("ammo_smg_max").IntValue;
		}
		else if (StrEqual(sWeaponEquipped, "weapon_pumpshotgun", false) || StrEqual(sWeaponEquipped, "weapon_shotgun_chrome", false))
		{
			iWeaponAmmo = FindConVar("ammo_shotgun_max").IntValue;
		}
		else if (StrEqual(sWeaponEquipped, "weapon_rifle", false) || StrEqual(sWeaponEquipped, "weapon_rifle_ak47", false) || StrEqual(sWeaponEquipped, "weapon_rifle_desert", false) || StrEqual(sWeaponEquipped, "weapon_rifle_sg552", false))
		{
			iWeaponAmmo = FindConVar("ammo_assaultrifle_max").IntValue;
		}
		else if (StrEqual(sWeaponEquipped, "weapon_autoshotgun", false) || StrEqual(sWeaponEquipped, "weapon_shotgun_spas", false))
		{
			iWeaponAmmo = FindConVar("ammo_autoshotgun_max").IntValue;
		}
		else if (StrEqual(sWeaponEquipped, "weapon_hunting_rifle", false))
		{
			iWeaponAmmo = FindConVar("ammo_huntingrifle_max").IntValue;
		}
		else if (StrEqual(sWeaponEquipped, "weapon_sniper_military", false) || StrEqual(sWeaponEquipped, "weapon_sniper_scout", false) || StrEqual(sWeaponEquipped, "weapon_sniper_awp", false))
		{
			iWeaponAmmo = FindConVar("ammo_sniperrifle_max").IntValue;
		}
		else if (StrEqual(sWeaponEquipped, "weapon_rifle_m60", false))
		{
			iWeaponAmmo = FindConVar("ammo_m60_max").IntValue;
		}
		else if (StrEqual(sWeaponEquipped, "weapon_grenade_launcher", false))
		{
			iWeaponAmmo = FindConVar("ammo_grenadelauncher_max").IntValue;
		}
		else
		{
			return;
		}
		
		int iCurrentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"));
		if (iCurrentAmmo < 1)
		{
			SetEntProp(client, Prop_Send, "m_iAmmo", iWeaponAmmo, _, GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"));
		}
	}
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			bCooldown[i] = false;
		}
	}
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= GetMaxEntities(); i++)
	{
		if (!IsValidEntity(i) || !IsValidEdict(i))
		{
			continue;
		}
		
		bAmmoGiven[i] = false;
	}
	
	return Plugin_Continue;
}

public Action OnAmmoPileFailed(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vec[3], float angles[3], int &weapon)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	if ((buttons & IN_USE) && !bCooldown[client])
	{
		int target = GetClientAimTarget(client, false);
		if (target == -1 || !IsValidEntity(target) || !IsValidEdict(target))
		{
			return Plugin_Continue;
		}
		
		int primary = GetPlayerWeaponSlot(client, 0);
		if (primary == -1 || !IsValidEntity(primary) || !IsValidEdict(primary))
		{
			return Plugin_Continue;
		}
		
		char sTargetClass[64], sPrimaryClass[64];
		
		GetEdictClassname(target, sTargetClass, sizeof(sTargetClass));
		GetEdictClassname(primary, sPrimaryClass, sizeof(sPrimaryClass));
		
		if (StrEqual(sTargetClass, "weapon_ammo_spawn", false))
		{
			if (StrEqual(sPrimaryClass, "weapon_rifle_m60", false))
			{
				bCooldown[client] = true;
				CreateTimer(2.0, StopCooldown, client);
				
				SetEntProp(client, Prop_Send, "m_iAmmo", FindConVar("ammo_m60_max").IntValue, _, GetEntProp(primary, Prop_Send, "m_iPrimaryAmmoType"));
			}
			else if (StrEqual(sPrimaryClass, "weapon_grenade_launcher", false))
			{
				bCooldown[client] = true;
				CreateTimer(2.0, StopCooldown, client);
				
				SetEntData(client, FindDataMapInfo(client, "m_iAmmo") + (68), FindConVar("ammo_grenadelauncher_max").IntValue);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action StopCooldown(Handle timer, any client)
{
	if (!bCooldown[client])
	{
		return Plugin_Stop;
	}
	
	bCooldown[client] = false;
	return Plugin_Stop;
}

