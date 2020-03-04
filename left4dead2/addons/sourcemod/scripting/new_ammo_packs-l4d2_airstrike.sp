#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <new_ammo_packs-l4d2>

char sMap[64];

public Plugin myinfo =
{
	name = "[L4D2] New Ammo Packs - Airstrike",
	author = "cravenge & Silvershot",
	description = "Adds Some Extras For Deployed Airstrike Boxes.",
	version = "1.2",
	url = ""
};

public void OnAllPluginsLoaded()
{
	if (!LibraryExists("nap-l4d2_helpers"))
	{
		SetFailState("[NAP - Airstrike] Main Plugin Missing!");
	}
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof(sMap));
}

public void NAP_OnAirstrikeHit(float fHitX, float fHitY, float fHitZ)
{
	float fHitPos[3];
	
	fHitPos[0] = fHitX;
	fHitPos[1] = fHitY;
	fHitPos[2] = fHitZ;
	
	int iEntityHit = -1;
	if (StrEqual(sMap, "c8m3_sewers", false))
	{
		while ((iEntityHit = FindEntityByClassname(iEntityHit, "prop_physics")) != INVALID_ENT_REFERENCE)
		{
			if (!IsValidEntity(iEntityHit) || !IsValidEdict(iEntityHit))
			{
				continue;
			}
			
			char sEntityHitName[128];
			GetEntPropString(iEntityHit, Prop_Data, "m_iName", sEntityHitName, sizeof(sEntityHitName));
			if (StrEqual(sEntityHitName, "pump01_breakable", false))
			{
				float fEntityHitPos[3];
				GetEntPropVector(iEntityHit, Prop_Data, "m_vecAbsOrigin", fEntityHitPos);
				
				if (GetVectorDistance(fHitPos, fEntityHitPos) <= 600.0)
				{
					AcceptEntityInput(iEntityHit, "Break");
				}
			}
			else if (StrEqual(sEntityHitName, "pump02_breakable", false))
			{
				float fEntityHitPos[3];
				GetEntPropVector(iEntityHit, Prop_Data, "m_vecAbsOrigin", fEntityHitPos);
				
				if (GetVectorDistance(fHitPos, fEntityHitPos) <= 600.0)
				{
					AcceptEntityInput(iEntityHit, "Break");
				}
			}
		}
	}
	else if (StrEqual(sMap, "c11m3_garage", false))
	{
		while ((iEntityHit = FindEntityByClassname(iEntityHit, "prop_physics")) != INVALID_ENT_REFERENCE)
		{
			if (!IsValidEntity(iEntityHit) || !IsValidEdict(iEntityHit))
			{
				continue;
			}
			
			char sEntityHitName[128];
			GetEntPropString(iEntityHit, Prop_Data, "m_iName", sEntityHitName, sizeof(sEntityHitName));
			if (StrEqual(sEntityHitName, "barricade_gas_can", false))
			{
				float fEntityHitPos[3];
				GetEntPropVector(iEntityHit, Prop_Data, "m_vecAbsOrigin", fEntityHitPos);
				
				if (GetVectorDistance(fHitPos, fEntityHitPos) <= 600.0)
				{
					IgniteEntity(iEntityHit, 3.0);
				}
			}
		}
	}
}

