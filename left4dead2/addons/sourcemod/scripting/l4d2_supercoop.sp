#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <geoip>

#define VERSION "2.8.2"
#define DATE "04.10.2012"

#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_DEFROST	"physics/glass/glass_sheet_break1.wav"

#define SOUND_IMPACT01	"animation/van_inside_hit_wall.wav"
#define SOUND_IMPACT02	"ambient/explosions/explode_3.wav"

#define SOUND_JAR		"weapons/ceda_jar/ceda_jar_explode.wav"

#define EXPLOSION_SOUND "ambient/explosions/explode_1.wav"

#define HEAL_SOUND "items/suitchargeok1.wav"

#define PANIC_SOUND "npc/mega_mob/mega_mob_incoming.wav"

#define EXPLOSION_PARTICLE "FluidExplosion_fps"
#define EXPLOSION_PARTICLE2 "weapon_grenade_explosion"
#define EXPLOSION_PARTICLE3 "explosion_huge_b"

#define FIRESMALL_PARTICLE "fire_small_01"

#define SPRITE_BEAM		"materials/sprites/laserbeam.vmt"
#define SPRITE_HALO		"materials/sprites/halo01.vmt"

#define LEVELS false

#define EXPLOSIONBOX true //Used SDK Tools
#define VOMITBOX true //Used SDK Tools

#define BONUSBOXMULTIPLIER 1.5

new freeze[MAXPLAYERS+1];
new g_GlowSprite;
new g_BeamSprite;
new g_HaloSprite;

new Float:l4d2_freeze_radius = 300.0;
new Float:l4d2_freeze_time = 15.0;
#if VOMITBOX
new Float:l4d2_vomit_radius = 300.0;
#endif
new Float:l4d2_healbox_radius = 250.0;
#if EXPLOSIONBOX
new g_cvarRadius = 350;
new g_cvarPower = 450;
new g_cvarDuration = 15;
#endif

new Float:XDifficultyMultiplier = 2.89;
new Float:BonusBoxDropMultiplier = 1.0;

new String:l4d2_ty_z_mod_38[64];
new String:l4d2_ty_z_mod_39[54];
new String:l4d2_ty_z_mod_40[55];
new bool:l4d2_ty_z_mod_36;
new Handle:l4d2_ty_z_mod_37;
new ty_players;
//new Handle:z_mod_dmg;
new Handle:l4d2_ammo_nextbox;
new Handle:l4d2_ammochance_nothing;
new Handle:l4d2_ammochance_firebox;
new Handle:l4d2_ammochance_boombox;
new Handle:l4d2_ammochance_freezebox;
new Handle:l4d2_ammochance_laserbox;
new Handle:l4d2_ammochance_medbox;
new Handle:l4d2_ammochance_nextbox;
new Handle:l4d2_ammochance_healbox;
new Handle:l4d2_ammochance_panicbox;
new Handle:l4d2_ammochance_witchbox;
new Handle:l4d2_ammochance_tankbox;
new Handle:l4d2_ammochance_bonusbox;
new Handle:l4d2_ammochance_hardbox;
new Handle:l4d2_ammochance_bloodbox;
new Handle:l4d2_ammochance_realismbox;
new bool:IsBloodBox;
new bool:IsRealismBox;
#if VOMITBOX || EXPLOSIONBOX
new Handle:g_hGameConf = INVALID_HANDLE;
#endif
#if VOMITBOX
new Handle:sdkVomitInfected = INVALID_HANDLE;
new Handle:sdkVomitSurvivor = INVALID_HANDLE;
new Handle:l4d2_ammochance_vomitbox;
#endif
#if EXPLOSIONBOX
new Handle:sdkCallPushPlayer = INVALID_HANDLE;
new Handle:l4d2_ammochance_explosionbox;
#endif

new Handle:l4d2_damage_hunter;
new Handle:l4d2_damage_smoker;
new Handle:l4d2_damage_boomer;
new Handle:l4d2_damage_spitter1;
new Handle:l4d2_damage_spitter2;
new Handle:l4d2_damage_jockey;
new Handle:l4d2_damage_charger;
new Handle:l4d2_damage_tank;
new Handle:l4d2_damage_tankrock;
new Handle:l4d2_damage_common;

new Handle:l4d2_damage_ak47;
new Handle:l4d2_damage_awp;
new Handle:l4d2_damage_scout;
new Handle:l4d2_damage_m60;
new Handle:l4d2_damage_spas;
new Handle:l4d2_damage_pipebomb;

new Handle:IsMapFinished;
new Handle:IsHardBox;

//Hardmod balanse
new Handle:l4d2_autodifficulty;
new Handle:z_special_spawn_interval;
new Handle:special_respawn_interval;
new Handle:tank_burn_duration;
new Handle:tank_burn_duration_hard;
new Handle:tank_burn_duration_expert;
new Handle:z_hunter_health;
new Handle:z_smoker_health;
new Handle:z_boomer_health;
new Handle:z_charger_health;
new Handle:z_spitter_health;
new Handle:z_jockey_health;
new Handle:z_witch_health;
new Handle:z_tank_health;
new Handle:z_health;
new Handle:z_hunter_limit;
new Handle:z_smoker_limit;
new Handle:z_boomer_limit;
new Handle:z_charger_limit;
new Handle:z_spitter_limit;
new Handle:z_jockey_limit;
new Handle:z_spitter_max_wait_time;
new Handle:z_vomit_interval;

new Handle:z_smoker_speed;
new Handle:z_boomer_speed;
new Handle:z_spitter_speed;
new Handle:z_tank_speed;

new Handle:jockey_pz_claw_dmg;
new Handle:smoker_pz_claw_dmg;
new Handle:tongue_choke_damage_amount;
new Handle:tongue_drag_damage_amount;
new Handle:tongue_miss_delay;
new Handle:tongue_hit_delay;
new Handle:tongue_range;

new Handle:grenadelauncher_damage;

new Handle:z_spitter_range;
new Handle:z_spit_interval;

new Handle:l4d2_loot_h_drop_items;
new Handle:l4d2_loot_b_drop_items;
new Handle:l4d2_loot_s_drop_items;
new Handle:l4d2_loot_c_drop_items;
new Handle:l4d2_loot_sp_drop_items;
new Handle:l4d2_loot_j_drop_items;
new Handle:l4d2_loot_t_drop_items;

new Handle:l4d2_engine_health_zombie_num_players;

new Handle:sv_disable_glow_survivors;
new Handle:ServerStart;

public Plugin:myinfo =
{
	name = "L4D2 Super Coop",
	author = "Accelerator",
	description = "Playing the increased complexity",
	version = VERSION,
	url = "http://core-ss.org"
};

public OnPluginStart()
{
	ServerStart = CreateConVar("l4d2_serverstart", "0", "", FCVAR_PLUGIN);
	
	if (GetConVarInt(ServerStart) < 1)
		SetConVarInt(ServerStart, GetTime(), false, false);

	HookEvent("player_changename", Event_PlayerChangeName, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("charger_carry_end", Event_ChargerCarryEnd, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("upgrade_pack_used", Event_UpgradePackUsed);
	HookEvent("upgrade_pack_added", Event_upgradePackAdded);
	HookEvent("revive_success", EventwhiteReviveSuccess);
	HookEvent("player_death", EventwhitePlayerDeath);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("heal_success", Event_whiteHealSuccess);
	HookEvent("defibrillator_used", defibEvent_PlayerDefibed);
	HookEvent("player_entered_checkpoint", Event_CheckPoint);
	RegAdminCmd("sm_spawnitem", Command_SpawnItem, ADMFLAG_CHEATS, "sm_spawnitem <parameters>");
	RegConsoleCmd("go_away_from_keyboard", Command_AFK);
	RegConsoleCmd("sm_supercoop", Command_Thanks);
	RegConsoleCmd("sm_info", Command_info);
	RegConsoleCmd("vocalize", Command_vocalize);
	RegAdminCmd("sm_fire", Command_Fire, ADMFLAG_CHEATS, "sm_fire");
	RegAdminCmd("sm_boom", Command_Boom, ADMFLAG_CHEATS, "sm_boom");
	RegAdminCmd("sm_healbox", Command_Heal, ADMFLAG_CHEATS, "sm_healbox");
	#if EXPLOSIONBOX
	RegAdminCmd("sm_explode", Command_Explode, ADMFLAG_CHEATS, "sm_explode");
	RegAdminCmd("sm_glowfire", Command_GlowFire, ADMFLAG_CHEATS, "sm_glowfire");
	RegAdminCmd("sm_flying", Command_Flying, ADMFLAG_CHEATS, "sm_flying");
	#endif
	#if VOMITBOX
	RegAdminCmd("sm_vomitbox", Command_Vomit, ADMFLAG_CHEATS, "sm_vomitbox");
	#endif
	RegAdminCmd("sm_grenadelauncher", Command_GrenadeLauncher, ADMFLAG_CHEATS, "sm_grenadelauncher");
	RegAdminCmd("sm_null", Command_Null, ADMFLAG_CHEATS, "sm_null");
	RegAdminCmd("sm_melee", Command_Melee, ADMFLAG_CHEATS, "sm_melee");
	RegAdminCmd("sm_spawnnewitem", Command_SpawnNewItem, ADMFLAG_RCON, "sm_spawnnewitem <parameters>");
	RegAdminCmd("sm_killallfreezes", Command_KillAllFreezes, ADMFLAG_CHEATS, "sm_killallfreezes");
	RegAdminCmd("sm_freezebox", Command_FreezeBox, ADMFLAG_CHEATS, "sm_killallfreezes");
	RegAdminCmd("sm_cmd", Command_Cmd, ADMFLAG_CHEATS, "sm_cmd <command> <parameter>");
	RegAdminCmd("sm_cmdall", Command_CmdAll, ADMFLAG_ROOT, "sm_cmdall <command> <parameter>");
	#if LEVELS
	RegAdminCmd("sm_grantlevel", Command_GrantLevel, ADMFLAG_ROOT, "sm_grantlevel <#userid|name> <level>");
	#endif
	//z_mod_dmg = CreateConVar("l4d2_ty_z_mod_dmg", "1", "", FCVAR_PLUGIN, true, 0.0);
	l4d2_ty_z_mod_36 = true;
	BuildPath(PathType:0, l4d2_ty_z_mod_38, 256, "gamedata/lastmap.cfg");
	l4d2_ty_z_mod_37 = CreateConVar("l4d2_loadlastmap", "1", "", FCVAR_PLUGIN);
	
	l4d2_ammo_nextbox = CreateConVar("l4d2_ammo_nextbox", "random", "", FCVAR_PLUGIN);
	l4d2_ammochance_nothing = CreateConVar("l4d2_ammochance_nothing", "300", "", FCVAR_PLUGIN);
	l4d2_ammochance_firebox = CreateConVar("l4d2_ammochance_firebox", "20", "", FCVAR_PLUGIN);
	l4d2_ammochance_boombox = CreateConVar("l4d2_ammochance_boombox", "15", "", FCVAR_PLUGIN);
	l4d2_ammochance_freezebox = CreateConVar("l4d2_ammochance_freezebox", "25", "", FCVAR_PLUGIN);
	l4d2_ammochance_laserbox = CreateConVar("l4d2_ammochance_laserbox", "30", "", FCVAR_PLUGIN);
	l4d2_ammochance_medbox = CreateConVar("l4d2_ammochance_medbox", "15", "", FCVAR_PLUGIN);
	l4d2_ammochance_nextbox = CreateConVar("l4d2_ammochance_nextbox", "30", "", FCVAR_PLUGIN);
	l4d2_ammochance_panicbox = CreateConVar("l4d2_ammochance_panicbox", "35", "", FCVAR_PLUGIN);
	l4d2_ammochance_witchbox = CreateConVar("l4d2_ammochance_witchbox", "15", "", FCVAR_PLUGIN);
	l4d2_ammochance_healbox = CreateConVar("l4d2_ammochance_healbox", "10", "", FCVAR_PLUGIN);
	l4d2_ammochance_tankbox = CreateConVar("l4d2_ammochance_tankbox", "8", "", FCVAR_PLUGIN);
	l4d2_ammochance_bonusbox = CreateConVar("l4d2_ammochance_bonusbox", "5", "", FCVAR_PLUGIN);
	l4d2_ammochance_hardbox = CreateConVar("l4d2_ammochance_hardbox", "2", "", FCVAR_PLUGIN);
	#if VOMITBOX
	l4d2_ammochance_vomitbox = CreateConVar("l4d2_ammochance_vomitbox", "12", "", FCVAR_PLUGIN);
	#endif
	#if EXPLOSIONBOX
	l4d2_ammochance_explosionbox = CreateConVar("l4d2_ammochance_explosionbox", "1", "", FCVAR_PLUGIN);
	#endif
	l4d2_ammochance_realismbox = CreateConVar("l4d2_ammochance_realismbox", "3", "", FCVAR_PLUGIN);
	l4d2_ammochance_bloodbox = CreateConVar("l4d2_ammochance_bloodbox", "2", "", FCVAR_PLUGIN);
	
	l4d2_damage_hunter = CreateConVar("l4d2_damage_hunter", "0", "Hunter additional damage", FCVAR_PLUGIN);
	l4d2_damage_smoker = CreateConVar("l4d2_damage_smoker", "0", "Smoker additional damage", FCVAR_PLUGIN);
	l4d2_damage_boomer = CreateConVar("l4d2_damage_boomer", "0", "Boomer additional damage", FCVAR_PLUGIN);
	l4d2_damage_spitter1 = CreateConVar("l4d2_damage_spitter1", "0", "Spitter additional damage", FCVAR_PLUGIN);
	l4d2_damage_spitter2 = CreateConVar("l4d2_damage_spitter2", "0", "Spitter additional damage (spit)", FCVAR_PLUGIN);
	l4d2_damage_jockey = CreateConVar("l4d2_damage_jockey", "0", "Jockey additional damage", FCVAR_PLUGIN);
	l4d2_damage_charger = CreateConVar("l4d2_damage_charger", "0", "Charger additional damage", FCVAR_PLUGIN);
	l4d2_damage_tank = CreateConVar("l4d2_damage_tank", "0", "Tank additional damage", FCVAR_PLUGIN);
	l4d2_damage_tankrock = CreateConVar("l4d2_damage_tankrock", "0", "Tank additional damage", FCVAR_PLUGIN);
	l4d2_damage_common = CreateConVar("l4d2_damage_common", "0", "Common additional damage", FCVAR_PLUGIN);
	
	l4d2_damage_ak47 = CreateConVar("l4d2_damage_ak47", "0", "AK47 additional damage", FCVAR_PLUGIN);
	l4d2_damage_awp = CreateConVar("l4d2_damage_awp", "0", "AWP additional damage", FCVAR_PLUGIN);
	l4d2_damage_scout = CreateConVar("l4d2_damage_scout", "0", "Scout additional damage", FCVAR_PLUGIN);
	l4d2_damage_m60 = CreateConVar("l4d2_damage_m60", "0", "M60 additional damage", FCVAR_PLUGIN);
	l4d2_damage_spas = CreateConVar("l4d2_damage_spas", "0", "Spas additional damage", FCVAR_PLUGIN);
	l4d2_damage_pipebomb = CreateConVar("l4d2_damage_pipebomb", "0", "Pipe bomb additional damage", FCVAR_PLUGIN);
	
	l4d2_engine_health_zombie_num_players = CreateConVar("l4d2_engine_health_zombie_num_players", "0", "Number player for zombie health balance", FCVAR_PLUGIN);
	
	IsMapFinished = CreateConVar("l4d2_mapfinished", "0", "", FCVAR_PLUGIN);
	IsHardBox = CreateConVar("l4d2_hardbox", "0", "", FCVAR_PLUGIN);
	
	HookConVarChange(IsMapFinished, IsMapFinishedChanged);
	
	
	//Hardmod balans
	l4d2_autodifficulty = CreateConVar("l4d2_autodifficulty", "1", "Is the plugin enabled.", FCVAR_PLUGIN);

	z_special_spawn_interval = FindConVar("z_special_spawn_interval");
	special_respawn_interval = FindConVar("director_special_respawn_interval");
	tank_burn_duration = FindConVar("tank_burn_duration");
	tank_burn_duration_hard = FindConVar("tank_burn_duration_hard");
	tank_burn_duration_expert = FindConVar("tank_burn_duration_expert");
	z_hunter_health = FindConVar("z_hunter_health");
	z_smoker_health = FindConVar("z_gas_health");
	z_boomer_health = FindConVar("z_exploding_health");
	z_charger_health = FindConVar("z_charger_health");
	z_spitter_health = FindConVar("z_spitter_health");
	z_jockey_health = FindConVar("z_jockey_health");
	z_witch_health = FindConVar("z_witch_health");
	z_tank_health = FindConVar("z_tank_health");
	z_hunter_limit = FindConVar("z_hunter_limit");
	z_smoker_limit = FindConVar("z_smoker_limit");
	z_boomer_limit = FindConVar("z_boomer_limit");
	z_charger_limit = FindConVar("z_charger_limit");
	z_spitter_limit = FindConVar("z_spitter_limit");
	z_jockey_limit = FindConVar("z_jockey_limit");
	z_health = FindConVar("z_health");
	z_spitter_max_wait_time = FindConVar("z_spitter_max_wait_time");
	z_vomit_interval = FindConVar("z_vomit_interval");

	z_smoker_speed = FindConVar("z_gas_speed");
	z_boomer_speed = FindConVar("z_exploding_speed");
	z_spitter_speed = FindConVar("z_spitter_speed");
	z_tank_speed = FindConVar("z_tank_speed");

	grenadelauncher_damage = FindConVar("grenadelauncher_damage");
	
	jockey_pz_claw_dmg = FindConVar("jockey_pz_claw_dmg");
	smoker_pz_claw_dmg = FindConVar("smoker_pz_claw_dmg");
	tongue_choke_damage_amount = FindConVar("tongue_choke_damage_amount");
	tongue_drag_damage_amount = FindConVar("tongue_drag_damage_amount");
	tongue_miss_delay = FindConVar("tongue_miss_delay");
	tongue_hit_delay = FindConVar("tongue_hit_delay");
	tongue_range = FindConVar("tongue_range");
	
	z_spitter_range = FindConVar("z_spitter_range");
	z_spit_interval = FindConVar("z_spit_interval");
	
	sv_disable_glow_survivors = FindConVar("sv_disable_glow_survivors");
	
	#if VOMITBOX || EXPLOSIONBOX
	g_hGameConf = LoadGameConfigFile("l4d2_supercoop");
	if(g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	}
	#endif
	#if VOMITBOX
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkVomitSurvivor = EndPrepSDKCall();
	if(sdkVomitSurvivor == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CTerrorPlayer_OnVomitedUpon\" signature, check the file version!");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkVomitInfected = EndPrepSDKCall();
	if(sdkVomitInfected == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CTerrorPlayer_OnHitByVomitJar\" signature, check the file version!");
	}
	#endif
	#if EXPLOSIONBOX
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallPushPlayer = EndPrepSDKCall();
	if(sdkCallPushPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
	}
	#endif
}

public Action:Command_vocalize(client, args)
{
	return Plugin_Handled;
}

public Action:Command_AFK(client, args)
{
	if (!client)
		return Plugin_Handled;

	#if LEVELS
	if (GetAdminImmunityLevel(GetUserAdmin(client)) > 24)
		return Plugin_Continue;
	#endif
		
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return Plugin_Continue;

	return Plugin_Handled;
}

public Action:Command_KillAllFreezes(client, args)
{
	KillAllFreezes();

	return Plugin_Continue;
}

public OnClientPostAdminCheck(client)
{
	decl String:ip[16];
	decl String:country[46];
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			GetClientIP(client, ip, 16); 
			new flags = GetUserFlagBits(client);
			#if LEVELS
			new AdminLevel = GetAdminImmunityLevel(GetUserAdmin(client));
			#endif
			if(GeoipCountry(ip, country, 45))
			{
				if ((flags & ADMFLAG_ROOT) || (flags & ADMFLAG_GENERIC))
				{
					#if LEVELS
					PrintToChatAll("\x03Admin (level %d) \x04%N\x03 (%s) has joined in the game", AdminLevel, client, country);
					#else
					PrintToChatAll("\x03Admin \x04%N\x03 (%s) has joined in the game", client, country);
					#endif
				}
				else
				{
					#if LEVELS
					PrintToChatAll("\x05Player (level %d) \x04%N\x05 (%s) has joined in the game", AdminLevel, client, country);
					#else
					PrintToChatAll("\x05Player \x04%N\x05 (%s) has joined in the game", client, country);
					#endif
				}
			}
			else
			{
				if ((flags & ADMFLAG_ROOT) || (flags & ADMFLAG_GENERIC))
				{
					#if LEVELS
					PrintToChatAll("\x03Admin (level %d) \x04%N\x03 has joined in the game", AdminLevel, client);
					#else
					PrintToChatAll("\x03Admin \x04%N\x03 has joined in the game", client);
					#endif
				}
				else
				{
					#if LEVELS
					PrintToChatAll("\x05Player (level %d) \x04%N\x05 has joined in the game", AdminLevel, client);
					#else
					PrintToChatAll("\x05Player \x04%N\x05 has joined in the game", client);
					#endif
				}
			}
		}
	}
	//Autodifficulty(ty_11111111111111());
}

#if LEVELS
public Action:Command_GrantLevel(client, args)
{
	if (args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_grantlevel <#userid|name> <level>");
		return Plugin_Handled;
	}

	decl len, next_len;
	decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	decl String:arg[65];
	len = BreakString(Arguments, arg, sizeof(arg));

	new target = FindTarget(client, arg, true);
	if (target == -1)
	{
		return Plugin_Handled;
	}

	decl String:lvl[12];
	if ((next_len = BreakString(Arguments[len], lvl, sizeof(lvl))) != -1)
	{
		len += next_len;
	}
	else
	{
		len = 0;
		Arguments[0] = '\0';
	}

	new level = StringToInt(lvl);

	SetAdminLvl(target, level);
	
	return Plugin_Handled;
}

public SetAdminLvl(client, level)
{
	new flags = GetUserFlagBits(client);
	new AdminId:Admin = GetUserAdmin(client);
	new AdminLevel = GetAdminImmunityLevel(Admin);
	if (AdminLevel < level)
	{
		if ((flags & ADMFLAG_ROOT) || (flags & ADMFLAG_GENERIC))
		{
			PrintToChatAll("\x03Admin (level %d) \x04%N\x03 upgraded to level %d", AdminLevel, client, level);
		}
		else
		{
			PrintToChatAll("\x05Player (level %d) \x04%N\x05 upgraded to level %d", AdminLevel, client, level);
		}
		SetAdminImmunityLevel(Admin, level);
	}
}
#endif

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	CheckName(client);
	new String:clientname[128];
	GetClientName(client, clientname, 128);
	if (strlen(clientname) < 1)
	{
		return false;
	}
	return true;
}

public Action:Command_Thanks(client, args)
{
	ReplyToCommand(client, "Left 4 Dead 2 Super Coop %s (%s) by Accelerator (http://core-ss.org):", VERSION, DATE);
	ReplyToCommand(client, "Thanks:");
	ReplyToCommand(client, "[L4D & L4D2] New custom commands by honorcode23: http://forums.alliedmods.net/showthread.php?p=1251446");
	ReplyToCommand(client, "Hardmod by Jonny: http://forum.csmania.ru/viewtopic.php?f=28&t=20749");
	ReplyToCommand(client, "l4d2_ty_z_mod by TY: http://semant1c.com");
	ReplyToCommand(client, "AlliedModders (sourcemod, sourcemod plugins): http://forums.alliedmods.net, http://sourcemod.net");
	ReplyToCommand(client, "# ------------------------------------------------------------ #");
	ReplyToCommand(client, "COMPILED ON SOURCEMOD VERSION: %s", SOURCEMOD_VERSION);
}

public CheckName(client)
{
	new String:clientname[128];
	if (IsFakeClient(client))
	{
		return;
	}
	GetClientName(client, clientname, 128);
	ReplaceString(clientname, 128, "0", "", false);
	ReplaceString(clientname, 128, "1", "", false);
	ReplaceString(clientname, 128, "2", "", false);
	ReplaceString(clientname, 128, "3", "", false);
	ReplaceString(clientname, 128, "4", "", false);
	ReplaceString(clientname, 128, "5", "", false);
	ReplaceString(clientname, 128, "6", "", false);
	ReplaceString(clientname, 128, "7", "", false);
	ReplaceString(clientname, 128, "8", "", false);
	ReplaceString(clientname, 128, "9", "", false);
	ReplaceString(clientname, 128, "^", "", false);
	ReplaceString(clientname, 128, "<", "", false);
	ReplaceString(clientname, 128, ">", "", false);
	ReplaceString(clientname, 128, "(", "", false);
	ReplaceString(clientname, 128, ")", "", false);
	ReplaceString(clientname, 128, "[", "", false);
	ReplaceString(clientname, 128, "]", "", false);
	ReplaceString(clientname, 128, "{", "", false);
	ReplaceString(clientname, 128, "}", "", false);
	ReplaceString(clientname, 128, ".", "", false);
	ReplaceString(clientname, 128, ",", "", false);
	ReplaceString(clientname, 128, "$", "", false);
	ReplaceString(clientname, 128, "%", "", false);
	ReplaceString(clientname, 128, ":", "", false);
	ReplaceString(clientname, 128, "@", "", false);
	ReplaceString(clientname, 128, "*", "", false);
	ReplaceString(clientname, 128, "\"", "", false);
	ReplaceString(clientname, 128, "/", "", false);
	ReplaceString(clientname, 128, "™", "", false);
	ReplaceString(clientname, 128, "☣", "", false);
	ReplaceString(clientname, 128, "☢", "", false);
	ReplaceString(clientname, 128, "|", "", false);
	ReplaceString(clientname, 128, "-", "", false);
	ReplaceString(clientname, 128, "=", "", false);
	ReplaceString(clientname, 128, "★", "", false);
	ReplaceString(clientname, 128, "+", "", false);
	ReplaceString(clientname, 128, "?", "", false);

	if (strlen(clientname) < 1)
	{
		KickClient(client, "Stupid names is not allowed");
	}
	SetClientInfo(client, "name", clientname);
}

public OnMapStart()
{
	GetCurrentMap(l4d2_ty_z_mod_40, 54);

	if (l4d2_ty_z_mod_36)
	{
		l4d2_ty_z_mod_57();
		if (!StrEqual(l4d2_ty_z_mod_39, l4d2_ty_z_mod_40, false))
		{
			if (0 < GetConVarInt(l4d2_ty_z_mod_37))
			{
				SetConVarInt(l4d2_ty_z_mod_37, 0, false, false);
				ServerCommand("changelevel %s", l4d2_ty_z_mod_39);
			}
		}
	}
	else
	{
		l4d2_ty_z_mod_58();
		l4d2_ty_z_mod_59();
	}
	
	g_BeamSprite = PrecacheModel(SPRITE_BEAM);
	g_HaloSprite = PrecacheModel(SPRITE_HALO);
	PrecacheSound(SOUND_FREEZE, true);
	PrecacheSound(SOUND_DEFROST, true);
	PrecacheSound(SOUND_IMPACT01, true);
	PrecacheSound(SOUND_IMPACT02, true);
	PrecacheSound(HEAL_SOUND, true);
	PrecacheSound(PANIC_SOUND, true);
	#if VOMITBOX
	PrecacheSound(SOUND_JAR, true);
	#endif
	#if EXPLOSIONBOX
	PrecacheSound(EXPLOSION_SOUND);
	PrefetchSound(EXPLOSION_SOUND);
	PrecacheParticle(EXPLOSION_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE2);
	PrecacheParticle(EXPLOSION_PARTICLE3);
	PrecacheParticle(FIRESMALL_PARTICLE);
	#endif
	
	l4d2_ty_z_mod_36 = false;
	return;
}
#if EXPLOSIONBOX
stock PrecacheParticle(String:ParticleName[])
{
	new Particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		DispatchSpawn(Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		CreateTimer(0.3, timerRemovePrecacheParticle, Particle);
	}
}

public Action:timerRemovePrecacheParticle(Handle:timer, any:Particle)
{
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		AcceptEntityInput(Particle, "Kill");
	}
	
	return Plugin_Stop;
}
#endif
l4d2_ty_z_mod_58()
{
	new Handle:file = OpenFile(l4d2_ty_z_mod_38, "w+");
	if (file) 
	{
		CloseHandle(file);
		return;
	}
	return;
}

l4d2_ty_z_mod_59()
{
	new Handle:file = OpenFile(l4d2_ty_z_mod_38, "a+");
	if (file) 
	{
		FileSeek(file, 0, SEEK_SET);
		if (!WriteFileLine(file, "%s", l4d2_ty_z_mod_40)) 
		{
			CloseHandle(file);
			return;
		}
		CloseHandle(file);
		return;
	}
	return;
}

l4d2_ty_z_mod_57()
{
	new Handle:file = OpenFile(l4d2_ty_z_mod_38, "r");
	if (file) 
	{
		FileSeek(file, 0, SEEK_SET);
		while (!IsEndOfFile(file)) 
		{
			if (!ReadFileLine(file, l4d2_ty_z_mod_39, sizeof(l4d2_ty_z_mod_39))) 
			{
				CloseHandle(file);
				return;
			}
		}
		CloseHandle(file);
		return;
	}
	return;
}


/*public OnClientDisconnect(client)
{
	Autodifficulty(ty_11111111111111());
}*/

public Action:Command_SpawnNewItem(client, args)
{
	if (!client)
		return Plugin_Continue;

	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3];
	
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;

	if (text[strlen(text) - 1] == '"')
	{
		text[strlen(text) - 1] = '\0';
		startidx = 1;
	}

	new NewItem = CreateEntityByName(text[startidx]);

	if (NewItem == -1 || NewItem == 0)
	{
		ReplyToCommand(client, "[SM] Spawn Failed: %s", text[startidx]);
	}

	DispatchKeyValue(NewItem, "model", "newitem");
	DispatchKeyValueFloat (NewItem, "MaxPitch", 360.00);
	DispatchKeyValueFloat (NewItem, "MinPitch", -360.00);
	DispatchKeyValueFloat (NewItem, "MaxYaw", 90.00);
	DispatchSpawn(NewItem);

	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 32;
	VecOrigin[1] += VecDirection[1] * 32;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;

	PrintToChat(client, "\x03sm_spawnitem %s %f %f %f %f %f %f %f", text[startidx], VecDirection[0], VecDirection[1], VecDirection[2], VecOrigin[0], VecOrigin[1], VecOrigin[2], VecAngles[1]);

	DispatchKeyValueVector(NewItem, "Angles", VecAngles);
	DispatchSpawn(NewItem);
	TeleportEntity(NewItem, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Continue;
}

public Action:Command_FreezeBox(client, args)
{
	if (!client)
		return;
		
	decl Float:position[3];
	GetClientAbsOrigin(client, position);
	Blizzard(client, position);
}
#if VOMITBOX
public Action:Command_Vomit(client, args)
{
	if (!client)
		return;
		
	decl Float:position[3];
	GetClientAbsOrigin(client, position);
	Vomit(client, position);
}
#endif
#if EXPLOSIONBOX
public Action:Command_Explode(client, args)
{
	if (!client)
		return;

	decl Float:position[3];
	GetClientAbsOrigin(client, position);
	CreateExplosion(position);
}

public Action:Command_GlowFire(client, args)
{
	if (!client)
		return Plugin_Handled;
		
	if (args < 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_glowfire <seconds> <0|1> <#userid|name>");
		return Plugin_Handled;
	}
		
	decl String:time[11], String:parent[24], String:player[65];
	GetCmdArg(1, time, sizeof(time));
	GetCmdArg(2, parent, sizeof(parent));
	GetCmdArg(3, player, sizeof(player));
	
	new target = FindTarget(client, player, true);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	new bool:ParentOpt = true;
	
	if (StringToInt(parent))
		ParentOpt = true;
	else
		ParentOpt = false;
	
	new seconds = StringToInt(time);

	if (seconds > 30)
		seconds = 30;

	CreateParticle(target, FIRESMALL_PARTICLE, ParentOpt, float(seconds));
	
	return Plugin_Continue;
}

public Action:Command_Flying(client, args)
{
	if (!client)
		return Plugin_Handled;
		
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_flying <#userid|name>");
		return Plugin_Handled;
	}
		
	decl String:player[65];
	GetCmdArg(1, player, sizeof(player));
	
	new target = FindTarget(client, player, true);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	if (!IsValidEntity(target) || !IsClientInGame(target) || !IsPlayerAlive(target))
	{
		return Plugin_Handled;
	}
	if (GetClientTeam(target) != 2)
	{
		return Plugin_Handled;
	}
	
	decl Float:position[3];
	GetClientAbsOrigin(target, position);
	new Float:power = g_cvarPower * 1.0;
	decl Float:tpos[3], Float:traceVec[3], Float:resultingFling[3], Float:currentVelVec[3];
	MakeVectorFromPoints(position, tpos, traceVec);				// draw a line from car to Survivor
	GetVectorAngles(traceVec, resultingFling);							// get the angles of that line
	
	resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;	// use trigonometric magic
	resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
	resultingFling[2] = power;
	
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
	resultingFling[0] += currentVelVec[0];
	resultingFling[1] += currentVelVec[1];
	resultingFling[2] += currentVelVec[2];

	FlingPlayer(target, resultingFling, client);
	
	return Plugin_Continue;
}
#endif
public Action:Event_PlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	#if LEVELS
	if (GetAdminImmunityLevel(GetUserAdmin(client)) > 24)
		return Plugin_Continue;
	#endif
		
	if ((GetUserFlagBits(client) & ADMFLAG_GENERIC) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		return Plugin_Continue;

	KickClient(client, "Nick change is prohibited!");

	return Plugin_Continue;
}

public Action:Command_Heal(client, args)
{
	if (!client)
		return;

	decl Float:position[3];
	GetClientAbsOrigin(client, position);
	HealBox(client, true, position);
}

public Action:Command_SpawnItem(client, args)
{
	if (args < 8)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spawnitem <parameters>");
		return Plugin_Handled;
	}

	decl Float:VecDirection[3];
	decl Float:VecOrigin[3];
	decl Float:VecAngles[3];
	decl String:modelname[64];
	GetCmdArg(1, modelname, sizeof(modelname));

	decl String:TempString[20];
	GetCmdArg(2, TempString, sizeof(TempString));
	VecDirection[0] = StringToFloat(TempString);
	GetCmdArg(3, TempString, sizeof(TempString));
	VecDirection[1] = StringToFloat(TempString);
	GetCmdArg(4, TempString, sizeof(TempString));
	VecDirection[2] = StringToFloat(TempString);
	GetCmdArg(5, TempString, sizeof(TempString));
	VecOrigin[0] = StringToFloat(TempString);
	GetCmdArg(6, TempString, sizeof(TempString));
	VecOrigin[1] = StringToFloat(TempString);
	GetCmdArg(7, TempString, sizeof(TempString));
	VecOrigin[2] = StringToFloat(TempString);
	GetCmdArg(8, TempString, sizeof(TempString));
	VecAngles[0] = 0.0;
	VecAngles[1] = StringToFloat(TempString);
	VecAngles[2] = 0.0;

	new spawned_item = CreateEntityByName(modelname);

	DispatchKeyValue(spawned_item, "model", "Custom_Spawn");
	DispatchKeyValueFloat(spawned_item, "MaxPitch", 360.00);
	DispatchKeyValueFloat(spawned_item, "MinPitch", -360.00);
	DispatchKeyValueFloat(spawned_item, "MaxYaw", 90.00);
	DispatchSpawn(spawned_item);

	DispatchKeyValueVector(spawned_item, "Angles", VecAngles);
	DispatchSpawn(spawned_item);
	TeleportEntity(spawned_item, VecOrigin, NULL_VECTOR, NULL_VECTOR);

	return Plugin_Continue;
}

public Action:Command_Fire(client, args)
{
	if (!client)
		return;

	new Float:position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	Fire(position);
}

public Action:Command_Boom(client, args)
{
	if (!client)
		return;

	new Float:position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	Boom(position);
}

public Action:Command_GrenadeLauncher(client, args)
{
	for(new i=1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			SetNullWeapon(i);
			l4d2_ty_z_mod_48(i, "give", "health");
			SetEntProp(i, PropType:0, "m_iHealth", 100, 1);
			SetEntProp(i, Prop_Send, "m_isGoingToDie", 0);
			SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
			without_aura(i);
			l4d2_ty_z_mod_48(i, "give", "grenade_launcher");
			l4d2_ty_z_mod_48(i, "give", "chainsaw");
			l4d2_ty_z_mod_48(i, "give", "molotov");
			l4d2_ty_z_mod_48(i, "give", "first_aid_kit");
			l4d2_ty_z_mod_48(i, "give", "pain_pills");
			SetEntProp(GetPlayerWeaponSlot(i, 0), PropType:0, "m_iExtraPrimaryAmmo", any:0, 4);
			SetEntProp(GetPlayerWeaponSlot(i, 0), PropType:0, "m_iClip1", any:10, 4);
			SetEntProp(GetPlayerWeaponSlot(i, 0), PropType:0, "m_upgradeBitVec", any:1, 4);
			SetEntProp(GetPlayerWeaponSlot(i, 0), PropType:0, "m_nUpgradedPrimaryAmmoLoaded", any:10, 4);
		}
	}
}

public Action:Command_Null(client, args)
{
	for(new i=1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			SetNullWeapon(i);
			l4d2_ty_z_mod_48(i, "give", "health");
			SetEntProp(i, PropType:0, "m_iHealth", 100, 1);
			SetEntProp(i, Prop_Send, "m_isGoingToDie", 0);
			SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
			without_aura(i);
			l4d2_ty_z_mod_48(i, "give", "pistol");
		}
	}
}

public Action:Command_Melee(client, args)
{
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	new Melee;
	new const String:g_Melees[12][] = {
		"fireaxe",
		"crowbar",
		"cricket_bat",
		"katana",
		"baseball_bat",
		"knife",
		"electric_guitar",
		"frying_pan",
		"machete",
		"golfclub",
		"tonfa",
		"chainsaw"
	};
	
	for(new k=0; k < sizeof(g_Melees); k++)
	{
		SetNullWeapon(client);
		l4d2_ty_z_mod_48(client, "give", g_Melees[k]);

		if (GetPlayerWeaponSlot(client, 1) > -1)
		{
			Melee = k;
			
			break;
		}
		else
		{
			continue;
		}
	}

	for(new i=1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			SetNullWeapon(i);
			l4d2_ty_z_mod_48(i, "give", "health");
			SetEntProp(i, PropType:0, "m_iHealth", 100, 1);
			SetEntProp(i, Prop_Send, "m_isGoingToDie", 0);
			SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
			without_aura(i);
			l4d2_ty_z_mod_48(i, "give", g_Melees[Melee]);
			l4d2_ty_z_mod_48(i, "give", "pipe_bomb");
			l4d2_ty_z_mod_48(i, "give", "first_aid_kit");
			l4d2_ty_z_mod_48(i, "give", "adrenaline");
		}
	}
}

public Action:Command_Cmd(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_cmd <command> <parameter>");
		return Plugin_Handled;
	}
	
	decl String:command_text[192];
	GetCmdArg(1, command_text, sizeof(command_text));

	if (args > 1)
	{
		decl String:parameters_text[192];
		parameters_text = "";
		decl String:temp_text[40];
		for (new i = 2; i <= args; i++)
		{
			GetCmdArg(i, temp_text, sizeof(temp_text));
			StrCat(parameters_text, sizeof(parameters_text), temp_text);
		}

		CheatCMD(client, command_text, parameters_text);
		return Plugin_Continue;
	}
	
	CheatCMD(client, command_text, "");
	return Plugin_Continue;
	
}

public CheatCMD(client, String:Command[], String:Parameters[])
{
	if (!client)
	{
		client = GetAnyClient();
	}
	if (!client)
	{
		new bot = CreateFakeClient("z_modbot");
		if (bot > 0)
		{
			l4d2_ty_z_mod_48(bot, Command, Parameters);
			CreateTimer(0.1,Kickbot,bot);
		}
		return;
	}
	if (!client)
	{
		ServerCommand("%s %s", Command, Parameters);
	}
	else
	{
		l4d2_ty_z_mod_48(client, Command, Parameters);
	}
}

public Action:Command_CmdAll(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_cmdall <command> <parameter>");
		return;	
	}
	
	decl String:cmd[256], String:arg[256];
	GetCmdArg(1, cmd, sizeof(cmd));
	GetCmdArg(2, arg, sizeof(arg));

	for(new i=1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			l4d2_ty_z_mod_48(i, cmd, arg);
		}
	}
}

public SetNullWeapon(client)
{
    if (!client) {
        return 0;
    }
    if (GetPlayerWeaponSlot(client, 0) > -1) {
        RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
    }
    if (GetPlayerWeaponSlot(client, 1) > -1) {
        RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
    }
    if (GetPlayerWeaponSlot(client, 2) > -1) {
        RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
    }
    if (GetPlayerWeaponSlot(client, 3) > -1) {
        RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
    }
    if (GetPlayerWeaponSlot(client, 4) > -1) {
        RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));
    }
    SetEntProp(client, PropType:0, "m_iHealth", any:100);
    SetEntProp(client, PropType:0, "m_isGoingToDie", any:0);
    SetEntProp(client, PropType:0, "m_currentReviveCount", any:0);
    return 0;
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		without_aura(client);
	}
}

public Action:Event_RoundStart(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	IsRealismBox = false;
	IsBloodBox = false;
	
	BonusBoxDropMultiplier = 1.0;

	CreateTimer(1.0, l4d2_ty_z_mod_60);
	CreateTimer(10.0, l4d2_ty_z_mod_60);
	CreateTimer(40.0, l4d2_ty_z_mod_60);
	CreateTimer(150.0, l4d2_ty_z_mod_60);
	CreateTimer(250.0, l4d2_ty_z_mod_60);
	
	CreateTimer(5.0, Timercleancoloring);

	SetConVarInt(IsMapFinished, 0, false, false);
	SetConVarInt(IsHardBox, 0, false, false);
	
	return Plugin_Continue;
}

public Action:Timercleancoloring(Handle:timer, any:client)
{
	cleancoloring();

	return Plugin_Stop;
}

public cleancoloring()
{
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				without_aura(i);
			}
		}
	}
}

public Action:l4d2_ty_z_mod_60(Handle:timer, any:client)
{
	Autodifficulty(ty_11111111111111());
//	ty_222222222222();
	return Plugin_Stop;
}

GetAnyClient()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			return i;
		}
	}
	return 0;
}

public Action:Kickbot(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsFakeClient(client))
		{
			KickClient(client);
		}
	}

	return Plugin_Stop;
}

stock l4d2_ty_z_mod_48(client, String:command[], String:arguments[] = "")
{
	if (client)
	{
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}

public ty_11111111111111()
{
	ty_players = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				ty_players++;
			}
		}
	}
	
	return ty_players;
}

public Autodifficulty(playerscount)
{
	if (GetConVarInt(l4d2_autodifficulty) < 1)
	{
		return;
	}

	if (playerscount < 4)
		playerscount = 4;
		
	new ItemsDropCount[7];

//	GetTotalDifficultyMultiplier();

	l4d2_loot_h_drop_items = FindConVar("l4d2_loot_h_drop_items");
	l4d2_loot_b_drop_items = FindConVar("l4d2_loot_b_drop_items");
	l4d2_loot_s_drop_items = FindConVar("l4d2_loot_s_drop_items");
	l4d2_loot_c_drop_items = FindConVar("l4d2_loot_c_drop_items");
	l4d2_loot_sp_drop_items = FindConVar("l4d2_loot_sp_drop_items");
	l4d2_loot_j_drop_items = FindConVar("l4d2_loot_j_drop_items");
	l4d2_loot_t_drop_items = FindConVar("l4d2_loot_t_drop_items");
	
//	l4d2_loot_g_chance_nodrop = FindConVar("l4d2_loot_g_chance_nodrop");

	new zombie_health_balance_num_players = GetConVarInt(l4d2_engine_health_zombie_num_players);
	
	if (!IsRealismBox)
	{
		if (XDifficultyMultiplier < 5)
		{
			SetConVarInt(sv_disable_glow_survivors, 0, false, false);
		}
		else
		{
			SetConVarInt(sv_disable_glow_survivors, 1, false, false);
		}
	}

	if (playerscount > 4)
	{
		SetConVarInt(tank_burn_duration, RoundToZero(1.5 * playerscount * XDifficultyMultiplier), false, false);
		SetConVarInt(tank_burn_duration_hard, RoundToZero(2.0 * playerscount * XDifficultyMultiplier), false, false);
		SetConVarInt(tank_burn_duration_expert, RoundToZero(4.0 * playerscount * XDifficultyMultiplier), false, false);

		SetConVarInt(z_spitter_max_wait_time, 34 - playerscount, false, false);
		SetConVarInt(z_vomit_interval, 34 - playerscount, false, false);

		SetConVarInt(z_smoker_speed, 210 + RoundToZero(3.0 * (playerscount - 4) * XDifficultyMultiplier), false, false); 
		SetConVarInt(z_boomer_speed, 175 + RoundToZero(3.0 * (playerscount - 4) * XDifficultyMultiplier), false, false); 
		SetConVarInt(z_spitter_speed, 160 + RoundToZero(15.0 * playerscount * XDifficultyMultiplier), false, false);
		SetConVarInt(z_tank_speed, 210 + RoundToZero((playerscount - 4) * 5 * XDifficultyMultiplier), false, false);

		SetConVarInt(z_hunter_limit, RoundToZero(2.5 + (playerscount / 5)), false, false);
		SetConVarInt(z_smoker_limit, RoundToZero(1.5 + (playerscount / 6)), false, false);
		SetConVarInt(z_boomer_limit, RoundToZero(1.5 + (playerscount / 7)), false, false);
		SetConVarInt(z_charger_limit, RoundToZero(0.3 + (playerscount / 7)), false, false);
		SetConVarInt(z_spitter_limit, RoundToZero(1.4 + (playerscount / 6)), false, false);
		SetConVarInt(z_jockey_limit, RoundToZero(0.5 + (playerscount / 8)), false, false);
	
		ItemsDropCount[0] = CheckCvarRange(RoundToZero((playerscount / 5.3) * SquareRoot(XDifficultyMultiplier)), 1, 100);
		ItemsDropCount[1] = CheckCvarRange(RoundToZero((playerscount / 4.0) * SquareRoot(XDifficultyMultiplier)), 1, 100);
		ItemsDropCount[2] = CheckCvarRange(RoundToZero((playerscount / 4.0) * SquareRoot(XDifficultyMultiplier)), 1, 100);
		ItemsDropCount[3] = CheckCvarRange(RoundToZero((playerscount / 4.2) * SquareRoot(XDifficultyMultiplier)), 1, 100);
		ItemsDropCount[4] = CheckCvarRange(RoundToZero((playerscount / 4.6) * SquareRoot(XDifficultyMultiplier)), 1, 100);
		ItemsDropCount[5] = CheckCvarRange(RoundToZero((playerscount / 4.6) * SquareRoot(XDifficultyMultiplier)), 1, 100);
		ItemsDropCount[6] = CheckCvarRange(RoundToZero(playerscount * 5 * SquareRoot(XDifficultyMultiplier)), 5, 100);
		
		SetConVarInt(l4d2_loot_h_drop_items, CheckCvarRange(ItemsDropCount[0], 0, RoundToZero(2 * BonusBoxDropMultiplier)), false, false);
		SetConVarInt(l4d2_loot_b_drop_items, CheckCvarRange(ItemsDropCount[1], 0, RoundToZero(4 * BonusBoxDropMultiplier)), false, false);
		SetConVarInt(l4d2_loot_s_drop_items, CheckCvarRange(ItemsDropCount[2], 0, RoundToZero(2 * BonusBoxDropMultiplier)), false, false);
		SetConVarInt(l4d2_loot_c_drop_items, CheckCvarRange(ItemsDropCount[3], 0, RoundToZero(5 * BonusBoxDropMultiplier)), false, false);
		SetConVarInt(l4d2_loot_sp_drop_items, CheckCvarRange(ItemsDropCount[4], 0, RoundToZero(3 * BonusBoxDropMultiplier)), false, false);
		SetConVarInt(l4d2_loot_j_drop_items, CheckCvarRange(ItemsDropCount[5], 0, RoundToZero(3 * BonusBoxDropMultiplier)), false, false);
		SetConVarInt(l4d2_loot_t_drop_items, CheckCvarRange(ItemsDropCount[6], 0, RoundToZero(playerscount * BonusBoxDropMultiplier)), false, false);

		SetConVarInt(z_hunter_health, CheckCvarRange(RoundToZero(40.0 * playerscount * XDifficultyMultiplier), 1, 2000), false, false);
		SetConVarInt(z_smoker_health, CheckCvarRange(RoundToZero(52.5 * playerscount * XDifficultyMultiplier), 1, 3500), false, false);
		SetConVarInt(z_boomer_health, CheckCvarRange(RoundToZero(15.5 * playerscount * XDifficultyMultiplier), 1, 900), false, false);
		SetConVarInt(z_charger_health, CheckCvarRange(RoundToZero(80.0 * playerscount * XDifficultyMultiplier), 1, 3500), false, false);
		SetConVarInt(z_spitter_health, CheckCvarRange(RoundToZero(30.0 * playerscount * XDifficultyMultiplier), 1, 1500), false, false);
		SetConVarInt(z_jockey_health, CheckCvarRange(RoundToZero(50.25 * playerscount * XDifficultyMultiplier), 1, 3800), false, false);
//		SetConVarInt(z_witch_health, CheckCvarMax(RoundToZero(250.0 * playerscount * XDifficultyMultiplier), 3000), false, false);
		
		SetConVarInt(grenadelauncher_damage, CheckCvarRange(RoundToZero((187.5 * playerscount) + 0.3), 400, 3125), false, false);
		
		SetConVarInt(z_special_spawn_interval, CheckCvarRange(49 - (playerscount * 3), 5, 100), false, false);
		SetConVarInt(special_respawn_interval, CheckCvarRange(49 - (playerscount * 3), 5, 100), false, false);
	}
	else
	{
		SetConVarInt(z_hunter_health, 500, false, false);
		SetConVarInt(z_smoker_health, 850, false, false);
		SetConVarInt(z_boomer_health, 150, false, false);
		SetConVarInt(z_charger_health, 1000, false, false);
		SetConVarInt(z_spitter_health, 450, false, false);
		SetConVarInt(z_jockey_health, 750, false, false);
//		SetConVarInt(z_witch_health, 1000, false, false);
//		SetConVarInt(z_health, 50, false, false);

		SetConVarInt(z_special_spawn_interval, 45, false, false);

		SetConVarInt(z_hunter_limit, 1, false, false);
		SetConVarInt(z_smoker_limit, 1, false, false);
		SetConVarInt(z_boomer_limit, 1, false, false);
		SetConVarInt(z_charger_limit, 1, false, false);
		SetConVarInt(z_spitter_limit, 1, false, false);
		SetConVarInt(z_jockey_limit, 1, false, false);

		SetConVarInt(z_smoker_speed, 210, false, false);
		SetConVarInt(z_spitter_max_wait_time, 30, false, false);
		SetConVarInt(z_boomer_speed, 175, false, false);
		SetConVarInt(z_spitter_speed, 210, false, false);
		SetConVarInt(z_tank_speed, 210, false, false);

		SetConVarInt(grenadelauncher_damage, 400, false, false);
	}
	
	if (zombie_health_balance_num_players)
	{
		if (playerscount > zombie_health_balance_num_players)
		{
			SetConVarInt(z_health, RoundToZero(2.5 * playerscount * XDifficultyMultiplier), false, false);
		}
	}
	
	SetConVarInt(smoker_pz_claw_dmg, playerscount, false, false);
	SetConVarInt(jockey_pz_claw_dmg, playerscount, false, false);
	SetConVarInt(tongue_choke_damage_amount, RoundToZero((10 + (playerscount - 4) * 1.666) * XDifficultyMultiplier), false, false);
	SetConVarInt(tongue_drag_damage_amount, RoundToZero(playerscount * 0.75 * XDifficultyMultiplier), false, false);
	SetConVarInt(tongue_miss_delay, CheckCvarRange(17 - playerscount, 1, 100), false, false);
	SetConVarInt(tongue_hit_delay, CheckCvarRange(17 - playerscount, 1, 100), false, false);
	
//	SetConVarInt(l4d2_loot_g_chance_nodrop, CheckCvarMin(RoundToZero(65 / XDifficultyMultiplier), 5), false, false);
	if ((GetConVarInt(IsMapFinished) == 0) && (GetConVarInt(IsHardBox) == 0))
	{
		new Handle:monsterbots_interval = FindConVar("monsterbots_interval");
		SetConVarInt(monsterbots_interval, CheckCvarRange(24 - playerscount, 6, 100), false, false);
	}
	
	SetConVarInt(tongue_range, 750 + RoundToZero((playerscount - 4) * 20 * XDifficultyMultiplier), false, false);

	SetConVarInt(z_spitter_range, 850 + RoundToZero((playerscount - 4) * 20 * XDifficultyMultiplier), false, false);
	SetConVarInt(z_spit_interval, CheckCvarRange(20 - RoundToZero((playerscount - 4) * 0.83 * XDifficultyMultiplier), 5, 100), false, false);
		
	new TankHP = 4000;
		
	TankHP = RoundToZero(1150 * XDifficultyMultiplier * playerscount);
	
	TankHP = CheckCvarRange(TankHP, 4000, 50000);
	SetConVarInt(z_tank_health, TankHP, false, false);
}

GetTankHP()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			if(GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
			{
				if(GetEntProp(i, Prop_Send, "m_isIncapacitated"))
					return 0;
					
				return GetClientHealth(i);
			}
		}
	}
	return GetConVarInt(FindConVar("z_tank_health")) * 2;
}

CheckCvarRange(Cvar_Value, Cvar_Value_Min, Cvar_Value_Max)
{
    if (Cvar_Value < Cvar_Value_Min) {
        return Cvar_Value_Min;
    }
    if (Cvar_Value > Cvar_Value_Max) {
        return Cvar_Value_Max;
    }
    return Cvar_Value;
}

public bool:IsIncapacitated(client)
{
    new isIncap = GetEntProp(client, PropType:0, "m_isIncapacitated", 4);
    if (isIncap) {
        return true;
    }
    return false;
}

public Action:Command_info(client, args)
{
	if (IsClientInGame(client))
	{
		ty_11111111111111();
		
		if (GetConVarInt(ServerStart) < 1)
			SetConVarInt(ServerStart, GetTime(), false, false);
		
		new theTime = GetTime() - GetConVarInt(ServerStart);
		new days = theTime /60/60/24;
		new hours = theTime/60/60%24;
		new minutes = theTime/60%60;
		//new seconds       = RoundToZero(theTime - days - hours - minutes);
		//new milli         = RoundToZero( (theTime - days - hours - minutes - seconds) * 1000);
		
		new String:uptime[128];
		if (hours == 0 && days == 0)
			Format(uptime, sizeof(uptime), "%d min", minutes);
		else if (days == 0)
			Format(uptime, sizeof(uptime), "%dh %dm", hours, minutes);
		else
			Format(uptime, sizeof(uptime), "%dd %dh %dm", days, hours, minutes);
		
		PrintToChat(client, "\x05L4D2 Super Coop (%s) | Players: \x04%i\x05 | UpTime: \x04%s\x03", VERSION, ty_players, uptime);
		if (IsTankAlive())
		{
			PrintToChat(client, "\x05Tank HP: \x03%i\x05 | Witch HP: \x04%i\x05 | Zombie HP: \x04%i\x03", GetTankHP(), GetConVarInt(z_witch_health), GetConVarInt(z_health));
		}
		else
		{
			PrintToChat(client, "\x05Tank HP: \x04%i\x05 | Witch HP: \x04%i\x05 | Zombie HP: \x04%i\x03", GetTankHP(), GetConVarInt(z_witch_health), GetConVarInt(z_health));
		}
		PrintToChat(client, "\x05Hunter HP: \x04%i\x05 | Smoker HP: \x04%i\x05 | Boomer HP: \x04%i\x05 \nCharger HP: \x04%i\x05 | Spitter HP: \x04%i\x05 | Jockey HP: \x04%i\x03", GetConVarInt(z_hunter_health), GetConVarInt(z_smoker_health), GetConVarInt(z_boomer_health), GetConVarInt(z_charger_health), GetConVarInt(z_spitter_health), GetConVarInt(z_jockey_health));
		PrintToChat(client, "\x05Grenade Launcher Damage = \x04%d\x03", GetConVarInt(grenadelauncher_damage));
	}
	return Plugin_Continue;
}

public Action:Event_ChargerCarryEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
//	ty_11111111111111();
	if (ty_players < 6)
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	CreateTimer(0.1, ty_ChargerCarryStart, client);
	return Plugin_Continue;
}

public Action:ty_ChargerCarryStart(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		ForcePlayerSuicide(client);
	}

	return Plugin_Stop;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new enemy = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (target == 0)
		return Plugin_Continue;

	if (enemy == 0)
		return Plugin_Continue;

	/*if (enemy == target)
		return Plugin_Continue;*/

	decl String:weapon[16];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	new damagetype = GetEventInt(event, "type");

	if (StrEqual(weapon, "rifle_ak47"))
	{
		if (GetClientTeam(target) == 2)
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_ak47) * 0.2);
		}
		else
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_ak47) * 1.0);
		}
	}
	else if (StrEqual(weapon, "sniper_awp"))
	{
		if (GetClientTeam(target) == 2)
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_awp) * 0.2);
		}
		else
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_awp) * 1.0);
		}
	}
	else if (StrEqual(weapon, "sniper_scout"))
	{
		if (GetClientTeam(target) == 2)
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_scout) * 0.2);
		}
		else
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_scout) * 1.0);
		}
	}
	else if (StrEqual(weapon, "rifle_m60"))
	{
		if (GetClientTeam(target) == 2)
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_m60) * 0.2);
		}
		else
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_m60) * 1.0);
		}
	}
	else if (StrEqual(weapon, "shotgun_spas"))
	{
		if (GetClientTeam(target) == 2)
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_spas) * 0.2);
		}
		else
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_spas) * 1.0);
		}
	}
	else if (StrEqual(weapon, "pipe_bomb"))
	{
		if (GetClientTeam(target) == 2)
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_pipebomb) * 1.0);
		}
		else
		{
			l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_pipebomb) * 1.5);
		}
	}

	if (GetClientTeam(enemy) == 3 && GetClientTeam(target) == 3)
		return Plugin_Continue;

	if (StrEqual(weapon, "", false))
	{
		if (damagetype != 128)
		{
			return Plugin_Continue;
		}
		l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_common) * 1.0);
	}
	else if (StrEqual(weapon, "boomer_claw", false))
	{
		if (damagetype != 128)
		{
			return Plugin_Continue;
		}
		l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_boomer) * 1.0);
	}
	else if (StrEqual(weapon, "charger_claw", false))
	{
		if (damagetype != 128)
		{
			return Plugin_Continue;
		}
		l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_charger) * 1.0);
	}
	else if (StrEqual(weapon, "hunter_claw", false))
	{
		if (damagetype != 128)
		{
			return Plugin_Continue;
		}
		l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_hunter) * 1.0);
	}
	else if (StrEqual(weapon, "smoker_claw", false))
	{
		if (damagetype != 128)
		{
			return Plugin_Continue;
		}
		l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_smoker) * 1.0);
	}
	else if (StrEqual(weapon, "spitter_claw", false))
	{
		if (damagetype != 128)
		{
			return Plugin_Continue;
		}
		l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_spitter1) * 1.0);
	}
	else if (StrEqual(weapon, "insect_swarm", false))
	{
		if (damagetype != 263168)
		{
			return Plugin_Continue;
		}
		l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_spitter2) * 1.0);
	}
	else if (StrEqual(weapon, "jockey_claw", false))
	{
		if (damagetype != 128)
		{
			return Plugin_Continue;
		}
		l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_jockey) * 1.0);
	}
	else if (StrEqual(weapon, "tank_claw", false))
	{
		if (damagetype != 128)
		{
			return Plugin_Continue;
		}
		l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_tank) * 1.0);
	}
	else if (StrEqual(weapon, "tank_rock", false))
	{
		if (damagetype != 128)
		{
			return Plugin_Continue;
		}
		l4d2_ty_z_mod_62(target, GetConVarInt(l4d2_damage_tankrock) * 1.0);
	}

	return Plugin_Continue;
}
	

public l4d2_ty_z_mod_62(any:client, Float:damage)
{
	if (GetHealth(client) < 0)
	{
		return;
	}

	if (GetHealth(client) * 1.0 <= damage)
	{
		if (GetClientTeam(client) == 2 && !IsGoingToDie(client))
		{
			IncapTarget(client);
			return;
		}
		damage = (GetHealth(client) - 0) * 1.0;
	}

	FakeDamageEffect(client, damage);
}

stock FakeDamageEffect(target, Float:damage) 
{
	SetEntityHealth(target, RoundToZero(GetHealth(target) - damage));
}

public IncapTarget(target)
{
	if(IsValidEntity(target))
	{
		new iDmgEntity = CreateEntityByName("point_hurt");
		SetEntityHealth(target, 1);
		DispatchKeyValue(target, "targetname", "bm_target");
		DispatchKeyValue(iDmgEntity, "DamageTarget", "bm_target");
		DispatchKeyValue(iDmgEntity, "Damage", "100");
		DispatchKeyValue(iDmgEntity, "DamageType", "0");
		DispatchSpawn(iDmgEntity);
		AcceptEntityInput(iDmgEntity, "Hurt", target);
		DispatchKeyValue(target, "targetname", "bm_targetoff");
		RemoveEdict(iDmgEntity);
	}
}

public bool:IsGoingToDie(client)
{
	new m_isGoingToDie = GetEntProp(client, Prop_Send, "m_isGoingToDie");

	if (m_isGoingToDie > 1)
	{
		return true;
	}

	return false;
}

public GetHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

SetSpecialAmmoInPlayerGun(client, amount)
{
	if (!client)
	{
		return;
	}
	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		SetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount, 1);
}

WitchBox(client)
{
	for (new i = 1; i <= 12; i++)
	{
		l4d2_ty_z_mod_48(client, "z_spawn_old", "witch auto");
	}
}

public MedBox(client)
{
	new l4d2_ty_z_mod_50;
	new String:l4d2_ty_z_mod_51[36];
	for (new i = 0; i < 9; i++)
	{
		l4d2_ty_z_mod_50 = GetRandomInt(1, 4);
		switch (l4d2_ty_z_mod_50)
		{
			case 1: 
				l4d2_ty_z_mod_51 = "weapon_defibrillator";
			case 2: 
				l4d2_ty_z_mod_51 = "weapon_first_aid_kit";
			case 3: 
				l4d2_ty_z_mod_51 = "weapon_pain_pills";
			case 4: 
				l4d2_ty_z_mod_51 = "weapon_adrenaline";
		}
		l4d2_ty_z_mod_52(client, l4d2_ty_z_mod_51);
	}
}

public ReplaceAmmoWithLaser(entity)
{
	new LaserEntity = CreateEntityByName("upgrade_laser_sight");
	if (LaserEntity == -1)
	{
		return;
	}
	new Float:vecOrigin[3];
	new Float:angRotation[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", angRotation);
	RemoveEdict(entity);
	TeleportEntity(LaserEntity, vecOrigin, angRotation, NULL_VECTOR);
	DispatchSpawn(LaserEntity);
}

public l4d2_ty_z_mod_52(any:client, const String:l4d2_ty_z_mod_51[])
{
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3];

	new SpawnItemEntity = CreateEntityByName(l4d2_ty_z_mod_51);

	if (SpawnItemEntity == -1)
	{
		ReplyToCommand(client, "\x05[SM] \x03 Spawn Failed (\x01%s\x03)", l4d2_ty_z_mod_51);
	}

	DispatchKeyValue(SpawnItemEntity, "model", "spawn_entity_1");
	DispatchKeyValueFloat (SpawnItemEntity, "MaxPitch", 360.00);
	DispatchKeyValueFloat (SpawnItemEntity, "MinPitch", -360.00);
	DispatchKeyValueFloat (SpawnItemEntity, "MaxYaw", 90.00);
	DispatchSpawn(SpawnItemEntity);

	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 32;
	VecOrigin[1] += VecDirection[1] * 32;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;

	DispatchKeyValueVector(SpawnItemEntity, "Angles", VecAngles);
	DispatchSpawn(SpawnItemEntity);
	TeleportEntity(SpawnItemEntity, VecOrigin, NULL_VECTOR, NULL_VECTOR);
}

stock IsTankAlive()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 3)
			{
				if (IsPlayerAlive(i))
				{
					if(GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
					{
						return 1;
					}
				}
			}
		}
	}
	return 0;
}

public Boom(Float:position[3])
{
	for (new i = 1; i <= 3; i++)
	{
		new entity = CreateEntityByName("prop_physics");
		if (!IsValidEntity(entity))
			return;

		DispatchKeyValue(entity, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}

public Fire(Float:position[3])
{
	new entity = CreateEntityByName("prop_physics");
	if (!IsValidEntity(entity))
		return;

	if (GetRandomInt(1, 2) == 1)
	{
		DispatchKeyValue(entity, "model", "models/props_junk/gascan001a.mdl"); //Fire
	}
	else
	{
		DispatchKeyValue(entity, "model", "models/props_junk/explosive_box001.mdl"); //Fireworks
	}
	DispatchSpawn(entity);
	SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
	TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "break");
}

public Action:Event_UpgradePackUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new upgradeid = GetEventInt(event, "upgradeid");

	new Float:position[3];
	GetEntPropVector(upgradeid, Prop_Send, "m_vecOrigin", position);

	new String:cvar_l4d2_ammo_nextbox[24];
	GetConVarString(l4d2_ammo_nextbox, cvar_l4d2_ammo_nextbox, sizeof(cvar_l4d2_ammo_nextbox));
	
	if (StrEqual(cvar_l4d2_ammo_nextbox, "random", false))
	{
		new Sum = 0;
		Sum += GetConVarInt(l4d2_ammochance_nothing);
		Sum += GetConVarInt(l4d2_ammochance_firebox);
		Sum += GetConVarInt(l4d2_ammochance_boombox);
		Sum += GetConVarInt(l4d2_ammochance_freezebox);
		Sum += GetConVarInt(l4d2_ammochance_laserbox);
		Sum += GetConVarInt(l4d2_ammochance_medbox);
		Sum += GetConVarInt(l4d2_ammochance_nextbox);
		Sum += GetConVarInt(l4d2_ammochance_panicbox);
		Sum += GetConVarInt(l4d2_ammochance_witchbox);
		Sum += GetConVarInt(l4d2_ammochance_tankbox);
		Sum += GetConVarInt(l4d2_ammochance_bonusbox);
		Sum += GetConVarInt(l4d2_ammochance_hardbox);
		Sum += GetConVarInt(l4d2_ammochance_healbox);
		#if VOMITBOX
		Sum += GetConVarInt(l4d2_ammochance_vomitbox);
		#endif
		#if EXPLOSIONBOX
		Sum += GetConVarInt(l4d2_ammochance_explosionbox);
		#endif
		Sum += GetConVarInt(l4d2_ammochance_realismbox);
		Sum += GetConVarInt(l4d2_ammochance_bloodbox);
		
		if (Sum > 0)
		{
			new Float:X = 1000.0 / Sum;
			new Float:Y = GetRandomFloat(0.0, 1000.0);
			new Float:A = 0.0;
			new Float:B = GetConVarInt(l4d2_ammochance_nothing) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "nothing";
			}			
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_firebox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "firebox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_boombox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "boombox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_freezebox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "freezebox";
			}		
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_laserbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "laserbox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_medbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "medbox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_nextbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "nextbox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_panicbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "panicbox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_witchbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "witchbox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_tankbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "tankbox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_bonusbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "bonusbox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_hardbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "hardbox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_healbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "healbox";
			}
			#if VOMITBOX
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_vomitbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "vomitbox";
			}
			#endif
			#if EXPLOSIONBOX
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_explosionbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "explosionbox";
			}
			#endif
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_realismbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "realismbox";
			}
			A = A + B;
			B = GetConVarInt(l4d2_ammochance_bloodbox) * X;
			if (Y >= A && Y < A + B)
			{
				cvar_l4d2_ammo_nextbox = "bloodbox";
			}
		}
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "nothing", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "firebox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		PrintHintTextToAll("%N have found a firebox!", client);
		Fire(position);
		RemoveEdict(upgradeid);
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "boombox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		PrintHintTextToAll("%N have found a boombox!", client);
		Boom(position);
		RemoveEdict(upgradeid);
	}	
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "freezebox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		PrintHintTextToAll("%N have found a freezebox!", client);
		if (GetRandomInt(1, 2) == 1)
		{
			Blizzard(client, position);
		}
		else
		{
			if (freeze[client] == 0)
				FreezePlayer(client, position);
		}
		RemoveEdict(upgradeid);
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "laserbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		PrintHintTextToAll("%N have found a laserbox!", client);
		ReplaceAmmoWithLaser(upgradeid);
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "medbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		PrintHintTextToAll("%N have found a medbox!", client);
		MedBox(client);
		RemoveEdict(upgradeid);
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "witchbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		WitchBox(client);
		PrintHintTextToAll("%N have found a witchbox!", client);
		RemoveEdict(upgradeid);
	}	
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "panicbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		PrintHintTextToAll("%N have found a panicbox!", client);
		CreateTimer(2.0, PanicEvent);
		RemoveEdict(upgradeid);
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "tankbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		l4d2_ty_z_mod_48(client, "z_spawn_old", "tank auto");
		PrintHintTextToAll("%N have found a tankbox!", client);
		RemoveEdict(upgradeid);
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "bonusbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		BonusBoxDropMultiplier = BONUSBOXMULTIPLIER;
		Autodifficulty(ty_11111111111111());
		ServerCommand("exec l4d2_supercoop/bonusbox.cfg");
		PrintHintTextToAll("%N have found a bonusbox!", client);
		RemoveEdict(upgradeid);
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "hardbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		SetConVarInt(IsHardBox, 1, false, false);
		SetConVarInt(FindConVar("monsterbots_interval"), 1, false, false);
		ServerCommand("exec l4d2_supercoop/hardbox.cfg");
		PrintHintTextToAll("%N have found a hardbox!", client);
		RemoveEdict(upgradeid);
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "healbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		HealBox(client, false, position);
		PrintHintTextToAll("%N have found a healbox!", client);
		RemoveEdict(upgradeid);
	}
	#if VOMITBOX
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "vomitbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		Vomit(client, position);
		PrintHintTextToAll("%N have found a vomitbox!", client);
		RemoveEdict(upgradeid);
	}
	#endif
	#if EXPLOSIONBOX
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "explosionbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		CreateExplosion(position);
		PrintHintTextToAll("%N have found a explosionbox!", client);
		RemoveEdict(upgradeid);
	}
	#endif
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "realismbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		RealismBox();
		PrintHintTextToAll("%N have found a realismbox!", client);
		RemoveEdict(upgradeid);
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "bloodbox", false))
	{
		cvar_l4d2_ammo_nextbox = "random";
		BloodBox();
		PrintHintTextToAll("%N have found a bloodbox!", client);
		RemoveEdict(upgradeid);
	}
	else if (StrEqual(cvar_l4d2_ammo_nextbox, "nextbox", false))
	{
		new NextBoxRnd;
		#if VOMITBOX
		NextBoxRnd = GetRandomInt(0, 13);
		#else
		NextBoxRnd = GetRandomInt(0, 12);
		#endif
		switch(NextBoxRnd)
		{
			case 0: cvar_l4d2_ammo_nextbox = "nextbox";
			case 1: cvar_l4d2_ammo_nextbox = "firebox";
			case 2: cvar_l4d2_ammo_nextbox = "boombox";
			case 3: cvar_l4d2_ammo_nextbox = "freezebox";
			case 4: cvar_l4d2_ammo_nextbox = "laserbox";
			case 5: cvar_l4d2_ammo_nextbox = "medbox";
			case 6: cvar_l4d2_ammo_nextbox = "witchbox";
			case 7: cvar_l4d2_ammo_nextbox = "panicbox";
			case 8: cvar_l4d2_ammo_nextbox = "tankbox";
			case 9: cvar_l4d2_ammo_nextbox = "hardbox";
			case 10: cvar_l4d2_ammo_nextbox = "healbox";
			case 11: cvar_l4d2_ammo_nextbox = "bloodbox";
			//case 12: cvar_l4d2_ammo_nextbox = "realismbox";
			case 12: cvar_l4d2_ammo_nextbox = "bonusbox";
			#if VOMITBOX
			case 13: cvar_l4d2_ammo_nextbox = "vomitbox";
			#endif
		}
		PrintHintTextToAll("%N have found a nextbox (%s)!", client, cvar_l4d2_ammo_nextbox);
		RemoveEdict(upgradeid);
	}
	else
	{
		cvar_l4d2_ammo_nextbox = "random";
	}
	SetConVarString(l4d2_ammo_nextbox, cvar_l4d2_ammo_nextbox);
}

stock GetSpecialAmmoInPlayerGun(client)
{
	if (!client)
		return 0;

	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		return GetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
	else
		return 0;
}

public Action:PanicEvent(Handle:timer)
{
	EmitSoundToAll(PANIC_SOUND);
	
	new bot = CreateFakeClient("mob");
	
	if (bot > 0)
	{
		if (IsFakeClient(bot))
		{
			l4d2_ty_z_mod_48(bot, "z_spawn_old", "mob auto");
			KickClient(bot);
		}
	}

	return Plugin_Stop;
}

public Action:Event_upgradePackAdded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new upgradeid = GetEventInt(event, "upgradeid");

	if (!IsValidEdict(upgradeid))
		return;

	decl String:class[256];
	GetEdictClassname(upgradeid, class, 256);
	if (StrEqual(class, "upgrade_laser_sight", true)) 
	{
		if (GetRandomInt(1, 2) == 1) 
		{
			RemoveEdict(upgradeid);
		}
		return;
	}

	decl String:PrimaryWeaponName[64];
	GetEdictClassname(GetPlayerWeaponSlot(client, 0), PrimaryWeaponName, sizeof(PrimaryWeaponName));
	if (StrEqual(PrimaryWeaponName, "weapon_grenade_launcher", false))
	{
		RemoveEdict(upgradeid);

		if (GetRandomInt(1, 10) == 1)
		{
			SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", 60);
			SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 60, 1);
		}
		else
		{
			SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", 15);
			SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 15, 1);
		}
		return;
	}
	if (StrEqual(PrimaryWeaponName, "weapon_rifle_m60", false))
	{
		RemoveEdict(upgradeid);
		new ammo = GetEntProp(GetPlayerWeaponSlot(client, 0), PropType:0, "m_iClip1", 4);
		new ammoupgrade = GetEntProp(GetPlayerWeaponSlot(client, 0), PropType:0, "m_upgradeBitVec", 4);

		if (4 <= ammoupgrade)
		{
			ammoupgrade = 4;
		}
		else
		{
			ammoupgrade = 0;
		}

		if (250 >= ammo)
		{
			ammo = ammo + 100;
			if (ammo > 250)
			{
				ammo = 250;
			}
		}
		else
		{
			ammo = 250;
		}

		SetEntProp(GetPlayerWeaponSlot(client, 0), PropType:0, "m_iClip1", ammo, 4);
		SetEntProp(GetPlayerWeaponSlot(client, 0), PropType:0, "m_nUpgradedPrimaryAmmoLoaded", 0, 4);
		SetEntProp(GetPlayerWeaponSlot(client, 0), PropType:0, "m_upgradeBitVec", ammoupgrade, 4);
		return;
	}
	else if (GetSpecialAmmoInPlayerGun(client) > 1)
	{
		new AMMORND = GetRandomInt(1, 3);
		SetSpecialAmmoInPlayerGun(client, AMMORND * GetSpecialAmmoInPlayerGun(client));
	}

	RemoveEdict(upgradeid);
}

public EventwhiteReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsRealismBox)
		return;

	if (!GetEventBool(event, "lastlife"))
		return;

	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	white_aura(client);
}

public EventwhitePlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	without_aura(client);
}

public Event_whiteHealSuccess(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));

	if (IsBloodBox)
	{
		SetBlood(client);
		return;
	}

	SetEntProp(client, PropType:0, "m_iHealth", any:100);
	SetEntProp(client, PropType:0, "m_isGoingToDie", any:0);
	SetEntProp(client, PropType:0, "m_currentReviveCount", any:0);

	without_aura(client);
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsBloodBox)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client)
		return;

	if (!IsValidEntity(client))
		return;
		
	CreateTimer(1.0, TimerSetBlood, client);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	IsBloodBox = false;
}

public Action:TimerSetBlood(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (GetClientTeam(client) == 2)
			{
				if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == 0)
				{
					SetBlood(client);
				}
			}
		}
	}
	
	return Plugin_Stop;
}

public SetBlood(client)
{
	SetEntProp(client, Prop_Send, "m_currentReviveCount", 1);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	SetEntProp(client, Prop_Send, "m_iHealth", 1);
	SetTempHealth(client, 99);
	without_aura(client);
}

public without_aura(client)
{
	if (client < 1)
		return;

	if (!IsValidEntity(client))
		return;

	if (!IsClientInGame(client))
		return;

	if (GetClientTeam(client) != 2)
		return;

	SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
}

public white_aura(client)
{
	if (client < 1)
		return;

	if (!IsValidEntity(client))
		return;

	if (!IsClientInGame(client))
		return;

	if (GetClientTeam(client) != 2)
		return;

	if (!IsPlayerAlive(client))
		return;

	SetEntProp(client, Prop_Send, "m_iGlowType", 3);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", 16777215);
}

public BloodBox()
{
	IsBloodBox = true;

	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (IsPlayerAlive(i))
			{
				if (GetClientTeam(i) == 2)
				{
					if (GetEntProp(i, Prop_Send, "m_currentReviveCount") == 0)
					{
						SetBlood(i);
					}
				}
			}
		}
	}
}

public RealismBox()
{
	IsRealismBox = true;
	SetConVarInt(sv_disable_glow_survivors, 1, false, false);
	cleancoloring();
}

public Action:defibEvent_PlayerDefibed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));

	if (client)
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", 2);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		SetEntProp(client, Prop_Send, "m_iHealth", 1);
		SetTempHealth(client, 40);
		white_aura(client);
	}

	return Plugin_Continue;
}

SetTempHealth(client, hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	new Float:newOverheal = hp * 1.0;
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

public HealBox(client, bool:multiply, Float:trspos[3])
{
	if ((GetRandomInt(1, 10) == 1) || multiply)
	{
		/* Laser effect */
	//	CreateLaserEffect(client, 80, 80, 230, 230, 6.0, 1.0, VARTICAL);
		TE_SetupBeamRingPoint(trspos, 10.0, l4d2_healbox_radius, g_BeamSprite, g_HaloSprite, 0, 10, 0.3, 10.0, 0.5, {255, 255, 255, 230}, 400, 0);
		TE_SendToAll();
		
		/* Freeze special infected and survivor in the radius */
		decl Float:position[3];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
				continue;
				
			GetClientEyePosition(i, position);
			
			if(GetVectorDistance(position, trspos) < l4d2_healbox_radius)
			{
				EmitAmbientSound(HEAL_SOUND, position, i, SNDLEVEL_RAIDSIREN);
				l4d2_ty_z_mod_48(i, "give", "health");
				if (IsBloodBox)
				{
					SetBlood(i);
				}
				else
				{
					SetEntProp(i, PropType:0, "m_iHealth", 100, 1);
					SetEntProp(i, Prop_Send, "m_isGoingToDie", 0);
					SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
					SetTempHealth(i, 0);
					without_aura(i);
				}
			}
		}
	}
	else
	{
		EmitAmbientSound(HEAL_SOUND, trspos, client, SNDLEVEL_RAIDSIREN);
		if (IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client))
		{
			if (IsBloodBox)
			{
				SetBlood(client);
			}
			else
			{
				l4d2_ty_z_mod_48(client, "give", "health");
				SetEntProp(client, PropType:0, "m_iHealth", 100, 1);
				SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
				SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
				SetTempHealth(client, 0);
				without_aura(client);
			}
		}
	}
}

public IsMapFinishedChanged(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
	if (GetConVarInt(IsMapFinished) == 0) 
	{
		ServerCommand("exec l4d2_supercoop/PlayerLeavesRescueZone.cfg");
	}
	else
	{
		ServerCommand("exec l4d2_supercoop/PlayerEnterRescueZone.cfg");
	}
}

public Action:Event_CheckPoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(IsMapFinished) > 0)
	{
		return Plugin_Continue;
	}
	
	new Target = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:strBuffer[128];
	GetEventString(event, "doorname", strBuffer, sizeof(strBuffer));
	
	if (Target && (GetClientTeam(Target)) == 2)
	{
		if (StrEqual(strBuffer, "checkpoint_entrance", false)) 
		{
			CheckPointReached(Target);
		}
		else
		{
			new area = GetEventInt(event, "area");
			
			new String:current_map[55];
			GetCurrentMap(current_map, 54);
			
			if (StrEqual(current_map, "c2m1_highway", false)) 
			{
				if (area == 89583) 
				{
					CheckPointReached(Target);
				}
			} 
			if (StrEqual(current_map, "c4m4_milltown_b", false)) 
			{
				if (area == 502575) 
				{
					CheckPointReached(Target);
				}
			}
			if (StrEqual(current_map, "c5m1_waterfront", false)) 
			{
				if (area == 54867) 
				{
					CheckPointReached(Target);
				}
			}
			if (StrEqual(current_map, "c5m2_park", false)) 
			{
				if (area == 196623) 
				{
					CheckPointReached(Target);
				}
			}
			if (StrEqual(current_map, "c7m1_docks", false))
			{
				if (area == 4475)
				{
					CheckPointReached(Target);
				}
			}
			if (StrEqual(current_map, "c7m2_barge", false)) 
			{
				if (area == 52626) 
				{
					CheckPointReached(Target);
				}
			}
			if (StrEqual(current_map, "c9m1_alleys", false))
			{
				if (area == 21211) 
				{
					CheckPointReached(Target);
				}
			}
			if (StrEqual(current_map, "c10m4_mainstreet", false)) 
			{
				if (area == 85038) 
				{
					CheckPointReached(Target);
				}
				if (area == 85093) 
				{
					CheckPointReached(Target);
				}
			}
			if (StrEqual(current_map, "C12m1_hilltop", false)) 
			{
				if (area == 60481) 
				{
					CheckPointReached(Target);
				}
			}
			if (StrEqual(current_map, "c13m1_alpinecreek", false)) {
				if (area == 14681) 
				{
					CheckPointReached(Target);
				}
			}
			if (StrEqual(current_map, "c13m2_southpinestream", false)) {
				if (area == 2910) 
				{
					CheckPointReached(Target);
				}
			}
			if (StrEqual(current_map, "c13m3_memorialbridge", false)) 
			{
				if (area == 154511)
				{
					CheckPointReached(Target);
				}
			}
		}
	}
	return Plugin_Continue;
}

public CheckPointReached(any:client)
{
	SetConVarInt(IsMapFinished, 1, false, false);
}

public Blizzard(client, Float:trspos[3])
{
	/* Emit impact sound */
	EmitAmbientSound(SOUND_IMPACT01, trspos);
	EmitAmbientSound(SOUND_IMPACT02, trspos);
	
	/* Laser effect */
//	CreateLaserEffect(client, 80, 80, 230, 230, 6.0, 1.0, VARTICAL);
	TE_SetupBeamRingPoint(trspos, 10.0, l4d2_freeze_radius,	g_BeamSprite, g_HaloSprite, 0, 10, 0.3, 10.0, 0.5, {40, 40, 230, 230}, 400, 0);
	TE_SendToAll();
	
	/* Freeze special infected and survivor in the radius */
	decl Float:position[3];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
			
		GetClientEyePosition(i, position);
		
		if(GetVectorDistance(position, trspos) <= l4d2_freeze_radius)
		{
			if (freeze[i] == 0)
				FreezePlayer(i, position);
		}
	}
}

public FreezePlayer(entity, Float:position[3])
{
	SetEntityMoveType(entity, MOVETYPE_NONE);
	SetEntityRenderColor(entity, 102, 204, 255, 195);
	ScreenFade(entity, 0, 128, 255, 192, RoundToZero(l4d2_freeze_time * 1000), 1);
	EmitAmbientSound(SOUND_FREEZE, position, entity, SNDLEVEL_RAIDSIREN);
	TE_SetupGlowSprite(position, g_GlowSprite, l4d2_freeze_time, 0.5, 130);
	TE_SendToAll();
	freeze[entity] = 1;
	CreateTimer(l4d2_freeze_time, DefrostPlayer, entity);
}

public Action:DefrostPlayer(Handle:timer, any:entity)
{
	if (IsValidEdict(entity) && IsValidEntity(entity) && (freeze[entity] == 1))
	{
		Func_DefrostPlayer(entity);
	}
	
	return Plugin_Stop;
}

Func_DefrostPlayer(client)
{
	decl Float:entPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", entPos);
	EmitAmbientSound(SOUND_DEFROST, entPos, client, SNDLEVEL_RAIDSIREN);
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	ScreenFade(client, 0, 0, 0, 0, 0, 1);
	freeze[client] = 0;
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	new Handle:msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
		BfWriteShort(msg, (0x0002 | 0x0008));
	else
		BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

KillAllFreezes()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && (freeze[i] == 1))
		{
			Func_DefrostPlayer(i);
		}
	}
}

public CreateRingEffect(client, colRed, colGre, colBlu, alpha, Float:width)
{ // stock TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, 
 //       FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
	decl color[4];
	color[0] = colRed;
	color[1] = colGre;
	color[2] = colBlu;
	color[3] = alpha;
	
	new Float:position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	position[2] += 10;
	TE_SetupBeamRingPoint(position, 10.0, 50.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.3, width, 1.5, color, 300, 0);
	TE_SendToAll();
}
#if VOMITBOX
public Vomit(client, Float:trspos[3])
{
	/* Emit impact sound */
	EmitAmbientSound(SOUND_JAR, trspos);
	
	/* Laser effect */
//	CreateLaserEffect(client, 80, 80, 230, 230, 6.0, 1.0, VARTICAL);
	TE_SetupBeamRingPoint(trspos, 10.0, l4d2_vomit_radius, g_BeamSprite, g_HaloSprite, 0, 10, 0.3, 10.0, 0.5, {51, 153, 0, 230}, 400, 0);
	TE_SendToAll();
	
	/* Freeze special infected and survivor in the radius */
	decl Float:position[3];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
			
		GetClientEyePosition(i, position);
		
		if(GetVectorDistance(position, trspos) <= l4d2_vomit_radius)
		{
			VomitPlayer(i, client);
		}
	}
}

VomitPlayer(target, sender)
{
	if(GetClientTeam(target) == 3)
		SDKCall(sdkVomitInfected, target, sender, true);
	if(GetClientTeam(target) == 2)
		SDKCall(sdkVomitSurvivor, target, sender, true);
}
#endif
#if EXPLOSIONBOX
CreateExplosion(Float:position[3])
{
	decl String:sRadius[256];
	decl String:sPower[256];
	new Float:flMaxDistance = g_cvarRadius * 1.0;
	new Float:power = g_cvarPower * 1.0;
	new Float:cvarDuration = g_cvarDuration * 1.0;
	IntToString(g_cvarRadius, sRadius, sizeof(sRadius));
	IntToString(g_cvarPower, sPower, sizeof(sPower));
	new exParticle2 = CreateEntityByName("info_particle_system");
	new exParticle3 = CreateEntityByName("info_particle_system");
	new exPhys = CreateEntityByName("env_physexplosion");
	new exParticle = CreateEntityByName("info_particle_system");
	new exEntity = CreateEntityByName("env_explosion");
	/*new exPush = CreateEntityByName("point_push");*/
	
	//Set up the particle explosion
	DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE);
	DispatchSpawn(exParticle);
	ActivateEntity(exParticle);
	TeleportEntity(exParticle, position, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE2);
	DispatchSpawn(exParticle2);
	ActivateEntity(exParticle2);
	TeleportEntity(exParticle2, position, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE3);
	DispatchSpawn(exParticle3);
	ActivateEntity(exParticle3);
	TeleportEntity(exParticle3, position, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up explosion entity
	DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
	DispatchKeyValue(exEntity, "iMagnitude", sPower);
	DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
	DispatchKeyValue(exEntity, "spawnflags", "828");
	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, position, NULL_VECTOR, NULL_VECTOR);
	
	//Set up physics movement explosion
	DispatchKeyValue(exPhys, "radius", sRadius);
	DispatchKeyValue(exPhys, "magnitude", sPower);
	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, position, NULL_VECTOR, NULL_VECTOR);
	
	EmitSoundToAll(EXPLOSION_SOUND, exParticle);
	
	//BOOM!
	AcceptEntityInput(exParticle, "Start");
	AcceptEntityInput(exParticle2, "Start");
	AcceptEntityInput(exParticle3, "Start");
	AcceptEntityInput(exEntity, "Explode");
	AcceptEntityInput(exPhys, "Explode");
	
	new Handle:pack2 = CreateDataPack();
	WritePackCell(pack2, exParticle);
	WritePackCell(pack2, exParticle2);
	WritePackCell(pack2, exParticle3);
	WritePackCell(pack2, exEntity);
	WritePackCell(pack2, exPhys);
	CreateTimer(cvarDuration+1.5, timerDeleteParticles, pack2, TIMER_FLAG_NO_MAPCHANGE);
	
	decl Float:tpos[3], Float:traceVec[3], Float:resultingFling[3], Float:currentVelVec[3];
	for(new i=1; i<=MaxClients; i++)
	{
		if(i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		if(GetClientTeam(i) != 2)
		{
			continue;
		}
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);

		if(GetVectorDistance(position, tpos) <= flMaxDistance)
		{
			MakeVectorFromPoints(position, tpos, traceVec);				// draw a line from car to Survivor
			GetVectorAngles(traceVec, resultingFling);							// get the angles of that line
			
			resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;	// use trigonometric magic
			resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
			resultingFling[2] = power;
			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
			resultingFling[0] += currentVelVec[0];
			resultingFling[1] += currentVelVec[1];
			resultingFling[2] += currentVelVec[2];
			
			FlingPlayer(i, resultingFling, i);
			
			CreateParticle(i, FIRESMALL_PARTICLE, true, 5.0);
		}
	}
}

CreateParticle(client, String:Particle_Name[], bool:Parent, Float:duration)
{
    decl Float:pos[3];
    decl String:sName[64];
    new Particle = CreateEntityByName("info_particle_system");
    GetClientAbsOrigin(client, pos);
    TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
    DispatchKeyValue(Particle, "effect_name", Particle_Name);
    if (Parent) 
	{
        new userid = GetClientUserId(client);
        Format(sName, 64, "%d", userid);
        DispatchKeyValue(client, "targetname", sName);
    }
    DispatchSpawn(Particle);
    if (Parent) 
	{
        SetVariantString(sName);
        AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
    }
    ActivateEntity(Particle);
    AcceptEntityInput(Particle, "Start");
    CreateTimer(duration, timerRemovePrecacheParticle, Particle);
}

public Action:timerDeleteParticles(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new entity;
	for (new i = 1; i <= 5; i++)
	{
		entity = ReadPackCell(pack);
		
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	CloseHandle(pack);
	
	return Plugin_Stop;
}

stock FlingPlayer(target, Float:vector[3], attacker, Float:stunTime = 3.0)
{
	SDKCall(sdkCallPushPlayer, target, vector, 96, attacker, stunTime);
}
#endif