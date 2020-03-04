#pragma semicolon 0
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#define PARTICLE_FIRE	"burning_engine_fire"
#define PARTICLE_FIRE2	"fire_medium_base"
//new Handle:KillIgniteInfected_Ignite = INVALID_HANDLE;
//new Handle:KillIgniteInfected_Health;
//new Handle:KillIgniteInfected_Speed;
//new Handle:KillIgniteInfected_Range;
//new Handle:KillIgniteInfected_Time;
//new Handle:KillInfected_ExtinguisEntity
//new Handle:KillIgniteInfected_ScaleMin;
//new Handle:KillIgniteInfected_ScaleMax;
new Handle:KillInfected_Death;
new Handle:KillInfected_DeathMap;
//new Handle:Cvar_Z_Health;
//new Handle:Cvar_Z_Speed;
//new Handle:Cvar_Z_Range;
//new Handle:Cvar_Z_Time;


enum ()
{
	ENUM_PARTICLE_FIRE,
	ENUM_PARTICLE_FIRE2
}


public Plugin:myinfo=
{
	name = "丧尸死亡_尸体消失",
	author = "-",
	description = "-",
	version = "-",
	url = "-"
}
public OnPluginStart()
{
	KillInfected_Death			= CreateConVar("KillInfected_Death",			"1",		"普通僵尸死亡后尸体是否立即消失?  0=否 1=是", FCVAR_SPONLY|FCVAR_NOTIFY);
	KillInfected_DeathMap		= CreateConVar("KillInfected_DeathMap",			"1",		"普通僵尸死亡后尸体立即消失适用于哪些地图.  1=官方地图 2=任何地图(保持默认值1)", FCVAR_SPONLY|FCVAR_NOTIFY);
	//KillIgniteInfected_Ignite		= CreateConVar("KillIgniteInfected_Ignite", 		"50.0", 	"设置燃烧丧尸出现的概率[0.0, 100.0]，0.0=关闭燃烧丧尸", FCVAR_SPONLY|FCVAR_NOTIFY);
	//KillInfected_ExtinguisEntity		= CreateConVar("KillInfected_ExtinguisEntity",		"1",		"设置燃烧丧尸对火免疫,如燃烧瓶和油气桶(0:否, 1:是)", FCVAR_SPONLY|FCVAR_NOTIFY);
	//KillIgniteInfected_Health 		= CreateConVar("KillIgniteInfected_Health",		"100", 	"设置丧尸生命", FCVAR_NOTIFY);
	//KillIgniteInfected_Speed 		= CreateConVar("KillIgniteInfected_Speed",		"300", 	"设置丧尸速度", FCVAR_NOTIFY);
	//KillIgniteInfected_Range 		= CreateConVar("KillIgniteInfected_Range",		"1000", 	"设置丧尸视野", FCVAR_NOTIFY);
	//KillIgniteInfected_Time 		= CreateConVar("KillIgniteInfected_Time",			"1.0", 	"设置丧尸反应", FCVAR_NOTIFY);
	//KillIgniteInfected_ScaleMin 	= CreateConVar("KillIgniteInfected_ScaleMin", 		"1.0", 	"设置燃烧丧尸大小最小值 [0.1, 3.0] ", FCVAR_SPONLY|FCVAR_NOTIFY);
	//KillIgniteInfected_ScaleMax 	= CreateConVar("KillIgniteInfected_ScaleMax", 		"2.0", 	"设置燃烧丧尸大小最大值 [Min, 3.0] ", FCVAR_SPONLY|FCVAR_NOTIFY);
	HookEvent("player_death",			Event_PlayerDeath);
	AutoExecConfig(true, "l4d2_Infected_Death");
	//Cvar_Z_Health = FindConVar("z_health"); 
	//Cvar_Z_Speed = FindConVar("z_speed"); 
	//Cvar_Z_Range = FindConVar("z_acquire_far_range");
	//Cvar_Z_Time = FindConVar("z_acquire_far_time");
}
/*
public OnMapStart()
{
	PrecacheParticle(PARTICLE_FIRE);
	PrecacheParticle(PARTICLE_FIRE2);
}

public OnEntityCreated(entity, const String:classname[])
{
	new Float:IgniteInfected = GetConVarFloat(KillIgniteInfected_Ignite);
	if(IgniteInfected == 0.0)return;
	new Float:Ignite = GetRandomFloat(0.0, 100.0);
	if( strcmp(classname, "infected") == 0 )
	{
		if(Ignite < IgniteInfected)
		{
			SDKHook(entity, SDKHook_SpawnPost, OnSpawnCommon);
		}
		SetConVarInt(Cvar_Z_Health, GetConVarInt(KillIgniteInfected_Health));
		SetConVarInt(Cvar_Z_Speed, GetConVarInt(KillIgniteInfected_Speed));
		SetConVarInt(Cvar_Z_Range, GetConVarInt(KillIgniteInfected_Range));
		SetConVarInt(Cvar_Z_Time, GetConVarInt(KillIgniteInfected_Time));
	}
}*/

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entityID = GetEventInt(event, "entityid");
	if(GetConVarInt(KillInfected_Death) == 1)
	{
		if(IsValidEntity(entityID))
		{
			new String:entname[128];
			if(GetEdictClassname(entityID, entname, sizeof(entname)))
			{
				if(StrEqual(entname, "infected", true))
				{
					if(GetConVarInt(KillInfected_DeathMap) == 1)
					{
						if(BoolMap() == true)
						{
							AcceptEntityInput(entityID, "Kill");
						}
					}
					if(GetConVarInt(KillInfected_DeathMap) == 2)
					{
						AcceptEntityInput(entityID, "Kill");
					}
				}
			}
		}
	}
	return Plugin_Handled;
}
stock bool:BoolMap()
{
	decl String:CurrentMap[255];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap))
	
	if(StrEqual(CurrentMap, "c1m1_hotel") == true || StrEqual(CurrentMap, "c1m2_streets") == true || StrEqual(CurrentMap, "c1m3_mall") == true || 
		StrEqual(CurrentMap, "c1m4_atrium") == true || StrEqual(CurrentMap, "c2m1_highway") == true || StrEqual(CurrentMap, "c2m2_fairgrounds") == true || 
		StrEqual(CurrentMap, "c2m3_coaster") == true || StrEqual(CurrentMap, "c2m4_barns") == true || StrEqual(CurrentMap, "c2m5_concert") == true || 
		StrEqual(CurrentMap, "c3m1_plankcountry") == true || StrEqual(CurrentMap, "c3m2_swamp") == true || StrEqual(CurrentMap, "c3m3_shantytown") == true || 
		StrEqual(CurrentMap, "c3m4_plantation") == true || StrEqual(CurrentMap, "c4m1_milltown_a") == true || StrEqual(CurrentMap, "c4m2_sugarmill_a") == true || 
		StrEqual(CurrentMap, "c4m3_sugarmill_b") == true || StrEqual(CurrentMap, "c4m4_milltown_b") == true || StrEqual(CurrentMap, "c4m5_milltown_escape") == true || 
		StrEqual(CurrentMap, "c5m1_waterfront") == true || StrEqual(CurrentMap, "c5m2_park") == true || StrEqual(CurrentMap, "c5m3_cemetery") == true || 
		StrEqual(CurrentMap, "c5m4_quarter") == true || StrEqual(CurrentMap, "c5m5_bridge") == true || StrEqual(CurrentMap, "c6m1_riverbank") == true || 
		StrEqual(CurrentMap, "c6m2_bedlam") == true || StrEqual(CurrentMap, "c6m3_port") == true || StrEqual(CurrentMap, "c7m1_docks") == true || StrEqual(CurrentMap, "c7m2_barge") == true || 
		StrEqual(CurrentMap, "c7m3_port") == true || StrEqual(CurrentMap, "c8m1_apartment") == true || StrEqual(CurrentMap, "c8m2_subway") == true || 
		StrEqual(CurrentMap, "c8m3_sewers") == true || StrEqual(CurrentMap, "c8m4_interior") == true || StrEqual(CurrentMap, "c8m5_rooftop") == true || 
		StrEqual(CurrentMap, "c9m1_alleys") == true || StrEqual(CurrentMap, "c9m2_lots") == true || StrEqual(CurrentMap, "c10m1_caves") == true || 
		StrEqual(CurrentMap, "c10m2_drainage") == true || StrEqual(CurrentMap, "c10m3_ranchhouse") == true || StrEqual(CurrentMap, "c10m4_mainstreet") == true || 
		StrEqual(CurrentMap, "c10m5_houseboat") == true || StrEqual(CurrentMap, "c11m1_greenhouse") == true || StrEqual(CurrentMap, "c11m2_offices") == true || 
		StrEqual(CurrentMap, "c11m3_garage") == true || StrEqual(CurrentMap, "c11m4_terminal") == true || StrEqual(CurrentMap, "c11m5_runway") == true || 
		StrEqual(CurrentMap, "c12m1_hilltop") == true || StrEqual(CurrentMap, "c12m2_traintunnel") == true || StrEqual(CurrentMap, "c12m3_bridge") == true || 
		StrEqual(CurrentMap, "c12m4_barn") == true || StrEqual(CurrentMap, "c12m5_cornfield") == true || StrEqual(CurrentMap, "c13m1_alpinecreek") == true || 
		StrEqual(CurrentMap, "c13m2_southpinestream") == true || StrEqual(CurrentMap, "c13m3_memorialbridge") == true || StrEqual(CurrentMap, "c13m4_cutthroatcreek"))
	{
		return true;
	}
	
	return false;
}
/*
MutantFireSetup(common, bool:spawn)
{
	SetEntProp(common, Prop_Data, "m_lifeState", 0);
	SDKHook(common, SDKHook_OnTakeDamage, OnTakeDamageFire);
	new Float:scale;
	scale = GetRandomFloat(GetConVarFloat(KillIgniteInfected_ScaleMin), GetConVarFloat(KillIgniteInfected_ScaleMax));
	if(scale>0.1 && scale<10.0)
	{
		SetEntPropFloat(common, Prop_Send,"m_flModelScale", scale); 
	}
	if(GetConVarInt(KillInfected_ExtinguisEntity) == 1)
	{
		CreateTimer(0.1, Extinguis_Entity, common, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	if(spawn)
	{
		IgniteEntity(common, 100000.0);
	} else
	{
		new entityflame = CreateEntityByName("entityflame");
		DispatchSpawn(entityflame);
		decl Float:vPos[3];
		GetEntPropVector(common, Prop_Data, "m_vecOrigin", vPos);
		TeleportEntity(entityflame, vPos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropFloat(entityflame, Prop_Data, "m_flLifetime", 6000.0);
		SetEntPropEnt(entityflame, Prop_Data, "m_hEntAttached", common);
		SetEntPropEnt(common, Prop_Data, "m_hEffectEntity", entityflame);
		SetEntPropEnt(common, Prop_Send, "m_hEffectEntity", entityflame);
		ActivateEntity(entityflame);
		AcceptEntityInput(entityflame, "Enable");
		decl String:sTemp[16];
		Format(sTemp, sizeof(sTemp), "fire%d%d", entityflame, common);
		DispatchKeyValue(common, "targetname", sTemp);
		SetVariantString(sTemp);
		AcceptEntityInput(entityflame, "IgniteEntity", common, common, 100000); //点燃丧尸_燃烧时间
		SetVariantString(sTemp);
		AcceptEntityInput(entityflame, "Ignite", common, common, 100000); //点燃丧尸_燃烧时间
	}
}

public Action:OnTakeDamageFire(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if( damagetype == 8 || damagetype == 2056 || damagetype == 268435464 )
	{
		damage = 0.0;
		return Plugin_Handled;
	}

	if(attacker > 0 && attacker <= MaxClients)
		FireDrop(victim);
	return Plugin_Continue;
}
FireDrop(entity)
{
	new trigger = CreateEntityByName("trigger_multiple");
	DispatchKeyValue(trigger, "spawnflags", "1");
	DispatchSpawn(trigger);

	decl Float:vPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	TeleportEntity(trigger, vPos, NULL_VECTOR, NULL_VECTOR);

	new Float:vMins[3], Float:vMaxs[3];
	new random = GetRandomInt(0,1);
	if( random )
	{
		vMins = Float:{-10.0, -10.0, 0.0};
		vMaxs = Float:{10.0, 10.0, 50.0};
	}
	else
	{
		vMins = Float:{-20.0, -20.0, 0.0};
		vMaxs = Float:{20.0, 20.0, 50.0};
	}
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", vMaxs);
	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);

	decl String:sTemp[32];
	Format(sTemp, sizeof(sTemp), "OnUser1 !self:Kill::1.0:-1"); //丧尸死亡_火焰消逝
	SetVariantString(sTemp);
	AcceptEntityInput(trigger, "AddOutput");
	AcceptEntityInput(trigger, "FireUser1");

	if( random )
		CreateParticle(entity, ENUM_PARTICLE_FIRE);
	else
		CreateParticle(entity, ENUM_PARTICLE_FIRE2);
}
CreateParticle(client, type)
{
	new entity = CreateEntityByName("info_particle_system");
	if(type == ENUM_PARTICLE_FIRE)
	{
		DispatchKeyValue(entity, "effect_name", PARTICLE_FIRE);
	} else
	if(type == ENUM_PARTICLE_FIRE2)
	{
		DispatchKeyValue(entity, "effect_name", PARTICLE_FIRE2);
	}
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start");
	
	if(type == ENUM_PARTICLE_FIRE || type == ENUM_PARTICLE_FIRE2)
	{
		decl Float:vPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
		vPos[2] += 10.0;
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	}
	switch( type )
	{
		case ENUM_PARTICLE_FIRE, ENUM_PARTICLE_FIRE2:
		{
			decl String:sTemp[32];
			Format(sTemp, sizeof(sTemp), "OnUser1 !self:Kill::1.0:-1"); //丧尸死亡_火焰消逝
			SetVariantString(sTemp);
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}
	}
	return EntIndexToEntRef(entity);
}
public Action:Extinguis_Entity(Handle:timer, any:entity)
{
	if(IsValidEntity(entity))
	{
		ExtinguishEntity(entity);
	} else KillTimer(timer);
}

public OnSpawnCommon(common)
{
	SpawnCommon(common); 
}
SpawnCommon(common)
{
	MutantFireSetup(common, true);
}
*/
public PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(2.0, DeleteParticles, particle);
	}
}
public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle) || IsValidEdict(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
}