#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>
#include <sdkhooks>
#include <sdktools>
#include <sceneprocessor>
#include <l4d_stocks>
#include <glow>

#undef REQUIRE_PLUGIN
#include <bawn>
#include <self_help>
#define REQUIRE_PLUGIN

#undef REQUIRE_EXTENSIONS
#include <left4downtown>
#define REQUIRE_EXTENSIONS

#define MCGL_CVAR FindConVar("multi-clip_grenade_launchers-l4d2_version")
#define BAWN_CVAR FindConVar("black_and_white_notifier_version")

#define LASERBEAM_SPRITE "materials/sprites/laserbeam.vmt"
#define HALO_SPRITE "materials/sprites/halo01.vmt"
#define BLOODSPRAY_SPRITE "materials/sprites/bloodspray.vmt"
#define BLOOD_SPRITE "materials/sprites/blood.vmt"
#define EXPLOSION_SPRITE "materials/sprites/flamelet1.vmt"

ConVar napEnable, napFreezeDuration, napFreezeRadius, napMatrixDuration, napMatrixGlow, napSpeedDuration, napSpeedIncrease,
	napImmuneDuration, napImmuneType, napHealType, napHealAmount, napGravityDuration, napGravityAmount, napGravityType,
	napInvisibleDuration, napInvisibleType, napInvisibleDummy, napInvisibleDummyGlow, napNotification, napUAMultiplied,
	napJingleDuration, napJingleBurnContact, napJingleKillContact, napBileRadius, napBileSpecial, napBileCommon, napBileWitch,
	napMobCount, napRealismDuration, napRealismDmgMultiplier, napMeteorFallDuration, napMeteorFallDamage, napFireworksDuration,
	napFireworksBurnContact, napPetProtectRange, napPetHeight, napPetDuration, napArmorDuration, napShoutDamage, napShoutDuration,
	napShoutRange, napBlindDuration, napBlurDuration, napSnowDuration, napSnowFreezeChance, napWarpFrequency, napWarpDuration,
	napDistortionDuration, napInfectedSpawnType, napDistortionType, napFlashDuration;

float fFreezeDuration, fFreezeRadius, fMatrixDuration, fSpeedDuration, fSpeedIncrease, fImmuneDuration, fGravityDuration,
	fGravityAmount, fInvisibleDuration, fJingleDuration, fBileRadius, fRealismDuration, fRealismDmgMultiplier, fMeteorFallDuration,
	fMeteorFallDamage, fFireworksDuration, fPetDuration, fPetProtectRange, fPetHeight, fArmorDuration, fShoutDamage, fShoutDuration,
	fShoutRange, fBlindDuration, fBlurDuration, fSnowDuration, fWarpFrequency, fWarpDuration, fDistortionDuration, 
	fFlashDuration, fTime[MAXPLAYERS+1][19];

bool bEnabled, bInvisibleDummy, bInvisibleDummyGlow, bJingleBurnContact, bJingleKillContact, bBileSpecial, bBileCommon, bBileWitch,
	bFireworksBurnContact, bPetFireInterval[2048], bIsPetFollowing[2048], bIsPetHovering[2048], bNotification, bFrozen[MAXPLAYERS+1],
	bMatrixApplied, bRealismApplied, bFast[MAXPLAYERS+1], bImmune[MAXPLAYERS+1], bInvisible[MAXPLAYERS+1], bFloating[MAXPLAYERS+1],
	bJingling[MAXPLAYERS+1], bWatchingMeteors[MAXPLAYERS+1], bDoingFirework[MAXPLAYERS+1], bHasPet[MAXPLAYERS+1],
	bHasParachute[MAXPLAYERS+1], bParachuteUseWarned[MAXPLAYERS+1], bParachuteUsed[2048], bHasArmor[MAXPLAYERS+1], bShouting[MAXPLAYERS+1],
	bBlinded[MAXPLAYERS+1], bBlurApplied, bSnowApplied, bWarping[MAXPLAYERS+1], bDistorted[MAXPLAYERS+1], bSoundDistorted[MAXPLAYERS+1],
	bFlashed[MAXPLAYERS+1], bAmmoPackUsed[10][MAXPLAYERS+1], bUAMultiplied;

int iMatrixGlow, iImmuneType, iHealType, iHealAmount, iInvisibleType, iGravityType, iMobCount, iInfectedSpawnType, iAPIndex[MAXPLAYERS+1],
	iGameMode, iTimeEnt, iDummy[MAXPLAYERS+1], iPetEnt[MAXPLAYERS+1], iPetExtras[2048][2], iPetTarget[2048], iParachuteEnt[MAXPLAYERS+1],
	iParachuteUseWarnTimes[MAXPLAYERS+1], iExtraParachute[MAXPLAYERS+1], iArmorEnt[MAXPLAYERS+1], iBlurEnt[2], iSnowEnt, iSnowFreezeChance,
	iDistortionType, iPredict[MAXPLAYERS+1], iSprite[5], iAPCountFix, iLastDeployer, iAmmoPackCount, iLastDeployedAP, iAmmoPackID[10],
	iAPMaxUses[10], iLastData[MAXPLAYERS+1][7][2];

ArrayList alPlayerList;
char sMap[64], sAPName[MAXPLAYERS+1][32], sLastData[MAXPLAYERS+1][6][128];
Handle hFreezeTime[MAXPLAYERS+1] = null, hMatrixTime = null, hSpeedTime[MAXPLAYERS+1] = null, hImmuneTime[MAXPLAYERS+1] = null,
	hGravityTime[MAXPLAYERS+1] = null, hInvisibleTime[MAXPLAYERS+1] = null, hJingleTime[MAXPLAYERS+1] = null, hRealismTime = null,
	hMeteorFallTime[MAXPLAYERS+1] = null, hFireworksTime[MAXPLAYERS+1] = null, hPetTime[MAXPLAYERS+1] = null, hArmorTime[MAXPLAYERS+1] = null,
	hShoutTime[MAXPLAYERS+1] = null, hBlindTime[MAXPLAYERS+1] = null, hBlurTime = null, hSnowTime = null, hWarpTime[MAXPLAYERS+1], 
	hDistortionTime[MAXPLAYERS+1] = null, hFlashTime[MAXPLAYERS+1] = null, hNAPGamedata = null, hNAPSetTempHP = null, hNAPApplyAdrenaline = null,
	hNAPFindUseEntity = null, hNAPBileSurvivor = null, hNAPBileInfected = null, hNAPBileCommon = null, hNAPDetonateSpit = null,
	hNAPFlingPlayer = null, hNAPStaggerPlayer = null, hNAPInitForward, hNAPHBPreForward, hNAPHBForward, hNAPHBPostForward, hNAPAirstrikeHitForward,
	hNAPPredictionSetting, hAmmoPackResetTime[10] = null;

float fDistortionAng[20] =
{
	0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0,
	0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0
};

char sNAPModels[15][] =
{
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/f18/f18_sb.mdl",
	"models/w_models/weapons/w_he_grenade.mdl",
	"models/missiles/f18_agm65maverick.mdl",
	"models/parachute/parachute_blue.mdl",
	"models/parachute/parachute_carbon.mdl",
	"models/parachute/parachute_green_v2.mdl",
	"models/parachute/parachute_ice_v2.mdl",
	"models/infected/common_male_riot.mdl",
	"models/infected/common_male_ceda.mdl",
	"models/infected/common_male_clown.mdl",
	"models/infected/common_male_mud.mdl",
	"models/infected/common_male_roadcrew.mdl",
	"models/infected/common_male_jimmy.mdl",
	"models/infected/common_male_fallen_survivor.mdl"
};

char sNAPParticles[16][] =
{
	"fire_barrel_big",
	"fireworks_01",
	"fireworks_02",
	"fireworks_03",
	"fireworks_04",
	"weapon_grenade_explosion",
	"explosion_huge_b",
	"gas_explosion_ground_fire",
	"FluidExplosion_fps",
	"weapon_tracers_50cal",
	"electrical_arc_01_system",
	"water_splash",
	"rpg_smoke",
	"missile_hit1",
	"gas_explosion_main",
	"explosion_huge"
};

char sNAPScenes[67][] =
{
	/* Shout Scenes */
	"scenes/Gambler/DeathScream01.vcd", "scenes/Gambler/DeathScream02.vcd", "scenes/Gambler/DeathScream03.vcd", "scenes/Gambler/DeathScream06.vcd", "scenes/Gambler/DeathScream07.vcd",
	"scenes/Producer/DeathScream01.vcd", "scenes/Producer/DeathScream02.vcd",
	"scenes/Coach/DeathScream01.vcd", "scenes/Coach/DeathScream02.vcd", "scenes/Coach/DeathScream03.vcd", "scenes/Coach/DeathScream06.vcd",
	"scenes/Mechanic/DeathScream01.vcd", "scenes/Mechanic/DeathScream02.vcd", "scenes/Mechanic/DeathScream03.vcd", "scenes/Mechanic/DeathScream05.vcd",
	"scenes/NamVet/DeathScream01.vcd", "scenes/NamVet/DeathScream03.vcd", "scenes/NamVet/DeathScream04.vcd",
	"scenes/TeenGirl/DeathScream05.vcd", "scenes/TeenGirl/DeathScream06.vcd", "scenes/TeenGirl/DeathScream07.vcd", "scenes/TeenGirl/DeathScream08.vcd", "scenes/TeenGirl/DeathScream09.vcd", "scenes/TeenGirl/DeathScream10.vcd", "scenes/TeenGirl/DeathScream11.vcd",
	"scenes/Biker/DeathScream05.vcd", "scenes/Biker/DeathScream06.vcd", "scenes/Biker/DeathScream07.vcd", "scenes/Biker/DeathScream08.vcd", "scenes/Biker/DeathScream09.vcd", "scenes/Biker/DeathScream10.vcd",
	"scenes/Manager/DeathScream04.vcd", "scenes/Manager/DeathScream05.vcd", "scenes/Manager/DeathScream06.vcd", "scenes/Manager/DeathScream07.vcd",
	/* Airstrike Scenes */
	"scenes/Gambler/WorldC5M4B09.vcd", "scenes/Gambler/WorldC5M4B05.vcd", "scenes/Gambler/World220.vcd", "scenes/Gambler/WorldC5M4B03.vcd",
	"scenes/Producer/WorldC5M4B04.vcd", "scenes/Producer/WorldC5M4B01.vcd", "scenes/Producer/WorldC5M4B03.vcd",
	"scenes/Coach/WorldC5M4B04.vcd", "scenes/Coach/WorldC5M4B05.vcd", "scenes/Coach/WorldC5M4B02.vcd",
	"scenes/Mechanic/WorldC5M4B02.vcd", "scenes/Mechanic/WorldC5M4B03.vcd", "scenes/Mechanic/WorldC5M4B04.vcd", "scenes/Mechanic/WorldC5M4B05.vcd", "scenes/Mechanic/WorldC5M103.vcd", "scenes/Mechanic/WorldC5M104.vcd",
	"scenes/NamVet/FriendlyFire03.vcd", "scenes/NamVet/FriendlyFire06.vcd", "scenes/NamVet/FriendlyFire13.vcd",
	"scenes/TeenGirl/FriendlyFire05.vcd", "scenes/TeenGirl/FriendlyFire08.vcd", "scenes/TeenGirl/FriendlyFire10.vcd", "scenes/TeenGirl/FriendlyFire14.vcd", "scenes/TeenGirl/FriendlyFire17.vcd", "scenes/TeenGirl/FriendlyFire18.vcd",
	"scenes/Biker/FriendlyFire06.vcd", "scenes/Biker/FriendlyFire07.vcd", "scenes/Biker/FriendlyFire19.vcd",
	"scenes/Manager/FriendlyFire01.vcd", "scenes/Manager/FriendlyFire03.vcd", "scenes/Manager/FriendlyFire06.vcd", "scenes/Manager/FriendlyFire13.vcd"
};

char sNAPSounds[36][] =
{
	"physics/glass/glass_impact_bullet4.wav",
	"music/flu/jukebox/badman.wav",
	"ambient/atmosphere/firewerks_launch_01.wav",
	"ambient/atmosphere/firewerks_launch_02.wav",
	"ambient/atmosphere/firewerks_launch_03.wav",
	"ambient/atmosphere/firewerks_launch_04.wav",
	"ambient/atmosphere/firewerks_launch_05.wav",
	"ambient/atmosphere/firewerks_launch_06.wav",
	"ambient/atmosphere/firewerks_burst_01.wav",
	"ambient/atmosphere/firewerks_burst_02.wav",
	"ambient/atmosphere/firewerks_burst_03.wav",
	"ambient/atmosphere/firewerks_burst_04.wav",
	"ambient/explosions/explode_1.wav",
	"ambient/explosions/explode_2.wav",
	"ambient/explosions/explode_3.wav",
	"animation/van_inside_debris.wav",
	"npc/soldier1/misc05.wav",
	"npc/soldier1/misc06.wav",
	"npc/soldier1/misc10.wav",
	"animation/jets/jet_by_01_lr.wav",
	"weapons/machinegun_m60/gunfire/machinegun_fire_1_incendiary.wav",
	"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav",
	"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_2.wav",
	"ambient/random_amb_sounds/randbridgegroan_03.wav",
	"music/flu/jukebox/all_i_want_for_xmas.wav",
	"ambient/energy/zap9.wav",
	"animation/jets/jet_by_01_mono.wav",
	"animation/jets/jet_by_02_mono.wav",
	"animation/jets/jet_by_02_lr.wav",
	"animation/jets/jet_by_03_lr.wav",
	"animation/jets/jet_by_04_lr.wav",
	"animation/jets/jet_by_05_lr.wav",
	"weapons/hegrenade/explode3.wav",
	"weapons/hegrenade/explode4.wav",
	"weapons/hegrenade/explode5.wav",
	"weapons/flash/flash01.wav"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGame[12];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		strcopy(error, err_max, "[NAP] Plugin Supports L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	CreateNative("HasEffect", NAP_HasEffect);
	CreateNative("GetEffectTimeLeft", NAP_GetEffectTimeLeft);
	CreateNative("GetAPIndex", NAP_GetAPIndex);
	CreateNative("SetAPIndex", NAP_SetAPIndex);
	CreateNative("GetAPName", NAP_GetAPName);
	CreateNative("SetAPName", NAP_SetAPName);
	
	RegPluginLibrary("nap-l4d2_helpers");
	return APLRes_Success;
}

public NAP_HasEffect(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Must Be A Living Survivor!");
		return false;
	}
	
	int givenIndex = GetNativeCell(2);
	if (givenIndex < 1 || givenIndex > 35)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Incorrect Ammo Pack Index!");
		return false;
	}
	
	switch (givenIndex)
	{
		case 1: return bFrozen[client];
		case 3: return bFast[client];
		case 4: return bImmune[client];
		case 6: return bFloating[client];
		case 7: return bInvisible[client];
		case 10: return bJingling[client];
		case 18: return bWatchingMeteors[client];
		case 19: return bDoingFirework[client];
		case 22: return bHasPet[client];
		case 23: return bHasParachute[client];
		case 24: return bHasArmor[client];
		case 25: return bShouting[client];
		case 26: return bBlinded[client];
		case 29: return bWarping[client];
		case 30: return bDistorted[client];
		case 35: return bFlashed[client];
	}
	
	return false;
}

public NAP_GetEffectTimeLeft(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Must Be A Living Survivor!");
		return _:0.0;
	}
	
	int givenIndex = GetNativeCell(2);
	if (givenIndex < 1 || givenIndex > 35)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Incorrect Ammo Pack Index!");
		return _:0.0;
	}
	
	switch (givenIndex)
	{
		case 1: return _:fTime[client][0];
		case 2: return _:fTime[0][1];
		case 3: return _:fTime[client][2];
		case 4: return _:fTime[client][3];
		case 6: return _:fTime[client][4];
		case 7: return _:fTime[client][5];
		case 10: return _:fTime[client][6];
		case 16: return _:fTime[0][7];
		case 18: return _:fTime[client][8];
		case 19: return _:fTime[client][9];
		case 22: return _:fTime[client][10];
		case 24: return _:fTime[client][11];
		case 25: return _:fTime[client][12];
		case 26: return _:fTime[client][13];
		case 27: return _:fTime[0][14];
		case 28: return _:fTime[0][15];
		case 29: return _:fTime[client][16];
		case 30: return _:fTime[client][17];
		case 35: return _:fTime[client][18];
	}
	
	return _:0.0;
}

public int NAP_GetAPIndex(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Must Be A Living Survivor!");
		return 0;
	}
	
	return iAPIndex[client];
}

public NAP_SetAPIndex(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Must Be A Living Survivor!");
		return;
	}
	
	int givenIndex = GetNativeCell(2);
	if (givenIndex < 0 || givenIndex > 35)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Incorrect Ammo Pack Index!");
		return;
	}
	
	iAPIndex[client] = givenIndex;
}

public int NAP_GetAPName(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Must Be A Living Survivor!");
		return 0;
	}
	
	int iAPNameSize = GetNativeCell(3);
	if (iAPNameSize < 0 || iAPNameSize > 32)
	{
		return 0;
	}
	
	int iBytesWritten;
	SetNativeString(2, sAPName[client], iAPNameSize, _, iBytesWritten);
	return iBytesWritten;
}

public NAP_SetAPName(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Must Be A Living Survivor!");
		return;
	}
	
	GetNativeString(2, sAPName[client], 32);
}

public Plugin myinfo =
{
	name = "[L4D2] New Ammo Packs",
	author = "cravenge (and a whole lot of other coders)",
	description = "Provides New Ammo Packs With Better Functions.",
	version = "3.2",
	url = ""
};

public void OnPluginStart()
{
	hNAPPredictionSetting = RegClientCookie("nap-l4d2_predict", "Client's Prediction Setting", CookieAccess_Protected);
	
	hNAPInitForward = CreateGlobalForward("NAP_OnInit", ET_Ignore, Param_Cell);
	hNAPHBPreForward = CreateGlobalForward("NAP_OnHBPre", ET_Ignore, Param_Cell);
	hNAPHBForward = CreateGlobalForward("NAP_OnHB", ET_Ignore, Param_Cell);
	hNAPHBPostForward = CreateGlobalForward("NAP_OnHBPost", ET_Ignore, Param_Cell);
	hNAPAirstrikeHitForward = CreateGlobalForward("NAP_OnAirstrikeHit", ET_Ignore, Param_Float, Param_Float, Param_Float);
	
	hNAPGamedata = LoadGameConfigFile("new_ammo_packs-l4d2");
	if (hNAPGamedata == null)
	{
		SetFailState("[NAP] Game Data Missing!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hNAPGamedata, SDKConf_Signature, "SetHealthBuffer");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	hNAPSetTempHP = EndPrepSDKCall();
	if (hNAPSetTempHP == null)
	{
		SetFailState("[NAP] Signature 'SetHealthBuffer' Broken!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hNAPGamedata, SDKConf_Signature, "OnAdrenalineUsed");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	hNAPApplyAdrenaline = EndPrepSDKCall();
	if (hNAPApplyAdrenaline == null)
	{
		SetFailState("[NAP] Signature 'OnAdrenalineUsed' Broken!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hNAPGamedata, SDKConf_Signature, "FindUseEntity");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	hNAPFindUseEntity = EndPrepSDKCall();
	if (hNAPFindUseEntity == null)
	{
		SetFailState("[NAP] Signature 'FindUseEntity' Broken!");
	}
	
	iAPCountFix = GameConfGetOffset(hNAPGamedata, "UpgradePackUseCountFix");
	if (iAPCountFix == -1)
	{
		SetFailState("[NAP] Offset 'UpgradePackUseCountFix' Incorrect!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hNAPGamedata, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hNAPBileSurvivor = EndPrepSDKCall();
	if (hNAPBileSurvivor == null)
	{
		SetFailState("[NAP] Signature 'CTerrorPlayer_OnVomitedUpon' Broken!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hNAPGamedata, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hNAPBileInfected = EndPrepSDKCall();
	if (hNAPBileInfected == null)
	{
		SetFailState("[NAP] Signature 'CTerrorPlayer_OnHitByVomitJar' Broken!");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hNAPGamedata, SDKConf_Signature, "Infected_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hNAPBileCommon = EndPrepSDKCall();
	if (hNAPBileCommon == null)
	{
		SetFailState("[NAP] Signature 'Infected_OnHitByVomitJar' Broken!");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hNAPGamedata, SDKConf_Signature, "CSpitterProjectile_Detonate");
	hNAPDetonateSpit = EndPrepSDKCall();
	if (hNAPDetonateSpit == null)
	{
		SetFailState("[NAP] Signature 'CSpitterProjectile_Detonate' Broken!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hNAPGamedata, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	hNAPFlingPlayer = EndPrepSDKCall();
	if (hNAPFlingPlayer == null)
	{
		SetFailState("[NAP] Signature 'CTerrorPlayer_Fling' Broken!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hNAPGamedata, SDKConf_Signature, "CTerrorPlayer_OnStaggered");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	hNAPStaggerPlayer = EndPrepSDKCall();
	if (hNAPStaggerPlayer == null)
	{
		SetFailState("[NAP] Signature 'CTerrorPlayer_OnStaggered' Broken!");
	}
	
	delete hNAPGamedata;
	
	iGameMode = GetGameModeNumber();
	
	CreateConVar("nap-l4d2_version", "3.26", "New Ammo Packs Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	napEnable = CreateConVar("nap-l4d2_enable", "1", "Enable/Disable Plugin", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napFreezeDuration = CreateConVar("nap-l4d2_freeze_duration", "15.0", "Duration Of Freeze Effect", FCVAR_SPONLY|FCVAR_NOTIFY, true, 1.0);
	napFreezeRadius = CreateConVar("nap-l4d2_freeze_radius", "400.0", "Radius Covered By Freeze Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napMatrixDuration = CreateConVar("nap-l4d2_matrix_duration", "10.0", "Duration Of Matrix Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napMatrixGlow = CreateConVar("nap-l4d2_matrix_glow", "3", "Glow Mode: 1=Deployer Only, 2=Survivors, 3=Infected, 4=All", FCVAR_SPONLY|FCVAR_NOTIFY, true, 1.0, true, 4.0);
	napSpeedDuration = CreateConVar("nap-l4d2_speed_duration", "17.5", "Duration Of Speed Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napSpeedIncrease = CreateConVar("nap-l4d2_speed_increase", "1.5", "Increase Of Deployer's Speed", FCVAR_SPONLY|FCVAR_NOTIFY);
	napImmuneDuration = CreateConVar("nap-l4d2_immune_duration", "20.0", "Duration Of Immune Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napImmuneType = CreateConVar("nap-l4d2_immune_type", "1", "Immune Type: 0=Damage Only, 1=All", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napHealType = CreateConVar("nap-l4d2_heal_type", "3", "Heal Type: 1=Static Amount, 2=Max HP, 3=Full", FCVAR_SPONLY|FCVAR_NOTIFY, true, 1.0, true, 3.0);
	napHealAmount = CreateConVar("nap-l4d2_heal_amount", "50", "Amount Of HP To Heal", FCVAR_SPONLY|FCVAR_NOTIFY);
	napGravityDuration = CreateConVar("nap-l4d2_gravity_duration", "22.5", "Duration Of Gravity Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napGravityAmount = CreateConVar("nap-l4d2_gravity_amount", "0.3", "Amount Of Gravity Applied", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.1, true, 0.5);
	napGravityType = CreateConVar("nap-l4d2_gravity_type", "0", "Gravity Type: 0=Deployer Only, 1=Whole Team", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napInvisibleDuration = CreateConVar("nap-l4d2_invisible_duration", "12.5", "Duration Of Invisible Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napInvisibleType = CreateConVar("nap-l4d2_invisible_type", "1", "Invisible Type: 0=Model Only, 1=Complete", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napInvisibleDummy = CreateConVar("nap-l4d2_invisible_dummy", "1", "Enable/Disable Dummy While Invisible", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napInvisibleDummyGlow = CreateConVar("nap-l4d2_invisible_dummy_glow", "1", "Enable/Disable Glow On Dummy", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napJingleDuration = CreateConVar("nap-l4d2_jingle_duration", "35.0", "Duration Of Jingle Effect", FCVAR_SPONLY|FCVAR_NOTIFY, true, 25.0, true, 80.0);
	napJingleBurnContact = CreateConVar("nap-l4d2_jingle_burn_contact", "1", "Enable/Disable Burn Contact During Jingle Effect", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napJingleKillContact = CreateConVar("nap-l4d2_jingle_kill_contact", "1", "Enable/Disable Kill Contact During Jingle Effect", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napBileRadius = CreateConVar("nap-l4d2_bile_radius", "450.0", "Radius Covered By Bile", FCVAR_SPONLY|FCVAR_NOTIFY);
	napBileSpecial = CreateConVar("nap-l4d2_bile_special", "1", "Include/Exclude Special Infected From Being Biled", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napBileCommon = CreateConVar("nap-l4d2_bile_common", "1", "Include/Exclude Common Infected From Being Biled", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napBileWitch = CreateConVar("nap-l4d2_bile_witch", "1", "Include/Exclude Witches From Being Biled", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napMobCount = CreateConVar("nap-l4d2_mob_count", "2", "Amount Of Mob To Spawn", FCVAR_SPONLY|FCVAR_NOTIFY, true, 1.0, true, 3.0);
	napRealismDuration = CreateConVar("nap-l4d2_realism_duration", "25.0", "Duration Of Realism Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napRealismDmgMultiplier = CreateConVar("nap-l4d2_realism_damage_multiplier", "1.3", "Multiplier Applied To Damages During Realism Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napMeteorFallDuration = CreateConVar("nap-l4d2_meteor_fall_duration", "10.0", "Duration Of Meteor Fall Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napMeteorFallDamage = CreateConVar("nap-l4d2_meteor_fall_damage", "15.0", "Damage Dealt By Meteors", FCVAR_SPONLY|FCVAR_NOTIFY);
	napFireworksDuration = CreateConVar("nap-l4d2_fireworks_duration", "30.0", "Duration Of Fireworks Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napFireworksBurnContact = CreateConVar("nap-l4d2_fireworks_burn_contact", "1", "Enable/Disable Burn Contact During Fireworks Effect", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napPetProtectRange = CreateConVar("nap-l4d2_pet_protect_range", "400.0", "Range Covered By Pet's Protection", FCVAR_SPONLY|FCVAR_NOTIFY);
	napPetHeight = CreateConVar("nap-l4d2_pet_height", "60.0", "Height Added To Pet", FCVAR_SPONLY|FCVAR_NOTIFY);
	napPetDuration = CreateConVar("nap-l4d2_pet_duration", "90.0", "Duration Of Pet Effect", FCVAR_SPONLY|FCVAR_NOTIFY, true, 60.0, true, 160.0);
	napArmorDuration = CreateConVar("nap-l4d2_armor_duration", "45.0", "Duration Of Armor Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napShoutDamage = CreateConVar("nap-l4d2_shout_damage", "10.0", "Damage Caused By Shouts", FCVAR_SPONLY|FCVAR_NOTIFY);
	napShoutDuration = CreateConVar("nap-l4d2_shout_duration", "40.0", "Duration Of Shout Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napShoutRange = CreateConVar("nap-l4d2_shout_range", "350.0", "Range Covered By Shouts", FCVAR_SPONLY|FCVAR_NOTIFY);
	napBlindDuration = CreateConVar("nap-l4d2_blind_duration", "20.0", "Duration Of Blind Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napBlurDuration = CreateConVar("nap-l4d2_blur_duration", "17.5", "Duration Of Blur Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napSnowDuration = CreateConVar("nap-l4d2_snow_duration", "22.5", "Duration Of Snow Effect", FCVAR_SPONLY|FCVAR_NOTIFY, true, 15.0, true, 45.0);
	napSnowFreezeChance = CreateConVar("nap-l4d2_snow_freeze_chance", "25", "Chance Of Getting Frozen Duraing Snow Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napWarpFrequency = CreateConVar("nap-l4d2_warp_frequency", "2.5", "Frequency Of Warping", FCVAR_SPONLY|FCVAR_NOTIFY, true, 2.5, true, 10.0);
	napWarpDuration = CreateConVar("nap-l4d2_warp_duration", "17.5", "Duration Of Warp Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napDistortionDuration = CreateConVar("nap-l4d2_distortion_duration", "25.0", "Duration Of Distortion Effect", FCVAR_SPONLY|FCVAR_NOTIFY, true, 5.0, true, 30.0);
	napDistortionType = CreateConVar("nap-l4d2_distortion_type", "3", "Distort Type: 0=Colors, 1=Player Views, 2=Sounds, 3=All", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	napFlashDuration = CreateConVar("nap-l4d2_flash_duration", "15.0", "Duration Of Flash Effect", FCVAR_SPONLY|FCVAR_NOTIFY);
	napInfectedSpawnType = CreateConVar("nap-l4d2_boss_spawn_type", "1", "Spawn Method: 0=Sourcemod, 1=Left 4 Downtown 2", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napNotification = CreateConVar("nap-l4d2_notification", "1", "Enable/Disable Notifications", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	napUAMultiplied = CreateConVar("nap-l4d2_upgrade_ammo_multiplied", "1", "Enable/Disable Upgrade Ammo Multiplier", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	iMatrixGlow = napMatrixGlow.IntValue;
	iImmuneType = napImmuneType.IntValue;
	iHealType = napHealType.IntValue;
	iHealAmount = napHealAmount.IntValue;
	iGravityType = napGravityType.IntValue;
	iInvisibleType = napInvisibleType.IntValue;
	iMobCount = napMobCount.IntValue;
	iSnowFreezeChance = napSnowFreezeChance.IntValue;
	iDistortionType = napDistortionType.IntValue;
	iInfectedSpawnType = napInfectedSpawnType.IntValue;
	
	bEnabled = napEnable.BoolValue;
	bInvisibleDummy = napInvisibleDummy.BoolValue;
	bInvisibleDummyGlow = napInvisibleDummyGlow.BoolValue;
	bJingleBurnContact = napJingleBurnContact.BoolValue;
	bJingleKillContact = napJingleKillContact.BoolValue;
	bBileSpecial = napBileSpecial.BoolValue;
	bBileCommon = napBileCommon.BoolValue;
	bBileWitch = napBileWitch.BoolValue;
	bFireworksBurnContact = napFireworksBurnContact.BoolValue;
	bNotification = napNotification.BoolValue;
	bUAMultiplied = napUAMultiplied.BoolValue;
	
	fFreezeDuration = napFreezeDuration.FloatValue;
	fFreezeRadius = napFreezeRadius.FloatValue;
	fMatrixDuration = napMatrixDuration.FloatValue;
	fSpeedDuration = napSpeedDuration.FloatValue;
	fSpeedIncrease = napSpeedIncrease.FloatValue;
	fImmuneDuration = napImmuneDuration.FloatValue;
	fGravityDuration = napGravityDuration.FloatValue;
	fGravityAmount = napGravityAmount.FloatValue;
	fInvisibleDuration = napInvisibleDuration.FloatValue;
	fJingleDuration = napJingleDuration.FloatValue;
	fBileRadius = napBileRadius.FloatValue;
	fRealismDuration = napRealismDuration.FloatValue;
	fRealismDmgMultiplier = napRealismDmgMultiplier.FloatValue;
	fMeteorFallDuration = napMeteorFallDuration.FloatValue;
	fMeteorFallDamage = napMeteorFallDamage.FloatValue;
	fFireworksDuration = napFireworksDuration.FloatValue;
	fPetProtectRange = napPetProtectRange.FloatValue;
	fPetHeight = napPetHeight.FloatValue;
	fPetDuration = napPetDuration.FloatValue;
	fArmorDuration = napArmorDuration.FloatValue;
	fShoutDamage = napShoutDamage.FloatValue;
	fShoutDuration = napShoutDuration.FloatValue;
	fShoutRange = napShoutRange.FloatValue;
	fBlindDuration = napBlindDuration.FloatValue;
	fBlurDuration = napBlurDuration.FloatValue;
	fSnowDuration = napSnowDuration.FloatValue;
	fWarpFrequency = napWarpFrequency.FloatValue;
	fWarpDuration = napWarpDuration.FloatValue;
	fDistortionDuration = napDistortionDuration.FloatValue;
	fFlashDuration = napFlashDuration.FloatValue;
	
	napEnable.AddChangeHook(OnNAPCVarsChanged);
	napFreezeDuration.AddChangeHook(OnNAPCVarsChanged);
	napFreezeRadius.AddChangeHook(OnNAPCVarsChanged);
	napMatrixDuration.AddChangeHook(OnNAPCVarsChanged);
	napMatrixGlow.AddChangeHook(OnNAPCVarsChanged);
	napSpeedDuration.AddChangeHook(OnNAPCVarsChanged);
	napSpeedIncrease.AddChangeHook(OnNAPCVarsChanged);
	napImmuneDuration.AddChangeHook(OnNAPCVarsChanged);
	napImmuneType.AddChangeHook(OnNAPCVarsChanged);
	napHealType.AddChangeHook(OnNAPCVarsChanged);
	napHealAmount.AddChangeHook(OnNAPCVarsChanged);
	napGravityDuration.AddChangeHook(OnNAPCVarsChanged);
	napGravityAmount.AddChangeHook(OnNAPCVarsChanged);
	napGravityType.AddChangeHook(OnNAPCVarsChanged);
	napInvisibleDuration.AddChangeHook(OnNAPCVarsChanged);
	napInvisibleType.AddChangeHook(OnNAPCVarsChanged);
	napInvisibleDummy.AddChangeHook(OnNAPCVarsChanged);
	napInvisibleDummyGlow.AddChangeHook(OnNAPCVarsChanged);
	napJingleDuration.AddChangeHook(OnNAPCVarsChanged);
	napJingleBurnContact.AddChangeHook(OnNAPCVarsChanged);
	napJingleKillContact.AddChangeHook(OnNAPCVarsChanged);
	napBileRadius.AddChangeHook(OnNAPCVarsChanged);
	napBileSpecial.AddChangeHook(OnNAPCVarsChanged);
	napBileCommon.AddChangeHook(OnNAPCVarsChanged);
	napBileWitch.AddChangeHook(OnNAPCVarsChanged);
	napMobCount.AddChangeHook(OnNAPCVarsChanged);
	napRealismDuration.AddChangeHook(OnNAPCVarsChanged);
	napRealismDmgMultiplier.AddChangeHook(OnNAPCVarsChanged);
	napMeteorFallDuration.AddChangeHook(OnNAPCVarsChanged);
	napMeteorFallDamage.AddChangeHook(OnNAPCVarsChanged);
	napFireworksDuration.AddChangeHook(OnNAPCVarsChanged);
	napFireworksBurnContact.AddChangeHook(OnNAPCVarsChanged);
	napPetProtectRange.AddChangeHook(OnNAPCVarsChanged);
	napPetHeight.AddChangeHook(OnNAPCVarsChanged);
	napPetDuration.AddChangeHook(OnNAPCVarsChanged);
	napArmorDuration.AddChangeHook(OnNAPCVarsChanged);
	napShoutDamage.AddChangeHook(OnNAPCVarsChanged);
	napShoutDuration.AddChangeHook(OnNAPCVarsChanged);
	napShoutRange.AddChangeHook(OnNAPCVarsChanged);
	napBlindDuration.AddChangeHook(OnNAPCVarsChanged);
	napBlurDuration.AddChangeHook(OnNAPCVarsChanged);
	napSnowDuration.AddChangeHook(OnNAPCVarsChanged);
	napSnowFreezeChance.AddChangeHook(OnNAPCVarsChanged);
	napWarpFrequency.AddChangeHook(OnNAPCVarsChanged);
	napWarpDuration.AddChangeHook(OnNAPCVarsChanged);
	napDistortionDuration.AddChangeHook(OnNAPCVarsChanged);
	napDistortionType.AddChangeHook(OnNAPCVarsChanged);
	napInfectedSpawnType.AddChangeHook(OnNAPCVarsChanged);
	napFlashDuration.AddChangeHook(OnNAPCVarsChanged);
	napNotification.AddChangeHook(OnNAPCVarsChanged);
	napUAMultiplied.AddChangeHook(OnNAPCVarsChanged);
	
	AutoExecConfig(true, "new_ammo_packs-l4d2");
	
	HookEvent("upgrade_pack_begin", OnUpgradePackBegin);
	HookEvent("upgrade_pack_used", OnUpgradePackUsed);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("upgrade_pack_added", OnUpgradePackAdded_Pre, EventHookMode_Pre);
	HookEvent("player_now_it", OnPlayerNowIt);
	HookEvent("revive_begin", OnReviveBegin);
	HookEvent("revive_success", OnReviveSuccess);
	
	HookEvent("round_start", OnRoundEvents);
	HookEvent("round_end", OnRoundEvents);
	HookEvent("finale_win", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	
	HookEvent("tongue_grab", OnInfectedGrab);
	HookEvent("lunge_pounce", OnInfectedGrab);
	HookEvent("jockey_ride", OnInfectedGrab);
	HookEvent("charger_carry_start", OnInfectedGrab);
	
	HookEvent("tongue_release", OnInfectedRelease);
	HookEvent("pounce_end", OnInfectedRelease);
	HookEvent("jockey_ride_end", OnInfectedRelease);
	HookEvent("charger_carry_end", OnInfectedRelease);
	HookEvent("charger_pummel_end", OnInfectedRelease);
	
	RegConsoleCmd("sm_nap_info", ShowInfoMenu, "Shows Information Menu");
	RegConsoleCmd("sm_nap_predict", TogglePrediction, "Toggles Prediction");
	
	AddNormalSoundHook(nshAllSounds);
	
	alPlayerList = new ArrayList();
}

int GetGameModeNumber()
{
	int value = 0;
	
	char strGameMode[16];
	FindConVar("mp_gamemode").GetString(strGameMode, sizeof(strGameMode));
	if (StrEqual(strGameMode, "survival", false))
	{
		value = 3;
	}
	else if (StrEqual(strGameMode, "versus", false) || StrEqual(strGameMode, "teamversus", false) || StrEqual(strGameMode, "scavenge", false) || StrEqual(strGameMode, "teamscavenge", false))
	{
		value = 2;
	}
	else if (StrEqual(strGameMode, "coop", false) || StrEqual(strGameMode, "realism", false))
	{
		value = 1;
	}
	
	return value;
}

public void OnNAPCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	iMatrixGlow = napMatrixGlow.IntValue;
	iImmuneType = napImmuneType.IntValue;
	iHealType = napHealType.IntValue;
	iHealAmount = napHealAmount.IntValue;
	iGravityType = napGravityType.IntValue;
	iInvisibleType = napInvisibleType.IntValue;
	iMobCount = napMobCount.IntValue;
	iSnowFreezeChance = napSnowFreezeChance.IntValue;
	iDistortionType = napDistortionType.IntValue;
	iInfectedSpawnType = napInfectedSpawnType.IntValue;
	
	bEnabled = napEnable.BoolValue;
	bInvisibleDummy = napInvisibleDummy.BoolValue;
	bInvisibleDummyGlow = napInvisibleDummyGlow.BoolValue;
	bJingleBurnContact = napJingleBurnContact.BoolValue;
	bJingleKillContact = napJingleKillContact.BoolValue;
	bBileSpecial = napBileSpecial.BoolValue;
	bBileCommon = napBileCommon.BoolValue;
	bBileWitch = napBileWitch.BoolValue;
	bFireworksBurnContact = napFireworksBurnContact.BoolValue;
	bNotification = napNotification.BoolValue;
	bUAMultiplied = napUAMultiplied.BoolValue;
	
	fFreezeDuration = napFreezeDuration.FloatValue;
	fFreezeRadius = napFreezeRadius.FloatValue;
	fMatrixDuration = napMatrixDuration.FloatValue;
	fSpeedDuration = napSpeedDuration.FloatValue;
	fSpeedIncrease = napSpeedIncrease.FloatValue;
	fImmuneDuration = napImmuneDuration.FloatValue;
	fGravityDuration = napGravityDuration.FloatValue;
	fGravityAmount = napGravityAmount.FloatValue;
	fInvisibleDuration = napInvisibleDuration.FloatValue;
	fJingleDuration = napJingleDuration.FloatValue;
	fBileRadius = napBileRadius.FloatValue;
	fRealismDuration = napRealismDuration.FloatValue;
	fRealismDmgMultiplier = napRealismDmgMultiplier.FloatValue;
	fMeteorFallDuration = napMeteorFallDuration.FloatValue;
	fMeteorFallDamage = napMeteorFallDamage.FloatValue;
	fFireworksDuration = napFireworksDuration.FloatValue;
	fPetProtectRange = napPetProtectRange.FloatValue;
	fPetHeight = napPetHeight.FloatValue;
	fPetDuration = napPetDuration.FloatValue;
	fArmorDuration = napArmorDuration.FloatValue;
	fShoutDamage = napShoutDamage.FloatValue;
	fShoutDuration = napShoutDuration.FloatValue;
	fShoutRange = napShoutRange.FloatValue;
	fBlindDuration = napBlindDuration.FloatValue;
	fBlurDuration = napBlurDuration.FloatValue;
	fSnowDuration = napSnowDuration.FloatValue;
	fWarpFrequency = napWarpFrequency.FloatValue;
	fWarpDuration = napWarpDuration.FloatValue;
	fDistortionDuration = napDistortionDuration.FloatValue;
	fFlashDuration = napFlashDuration.FloatValue;
	
	if (bEnabled)
	{
		Call_StartForward(hNAPInitForward);
		Call_PushCell(1);
		Call_Finish();
	}
	else
	{
		Call_StartForward(hNAPInitForward);
		Call_PushCell(0);
		Call_Finish();
		
		RemoveOtherEffects();
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				ClearNAPData(i);
			}
		}
	}
}

public Action ShowInfoMenu(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	Menu napInfo = new Menu(napInfoHandler);
	napInfo.SetTitle("Ammo Packs Information:");
	
	napInfo.AddItem("", "Freeze Box");
	napInfo.AddItem("", "Matrix Box");
	napInfo.AddItem("", "Speed Box");
	napInfo.AddItem("", "Immune Box");
	napInfo.AddItem("", "Heal Box");
	napInfo.AddItem("", "Gravity Box");
	napInfo.AddItem("", "Invisible Box");
	napInfo.AddItem("", "Ammo Box");
	napInfo.AddItem("", "Weaponry Box");
	napInfo.AddItem("", "Jingle Box");
	napInfo.AddItem("", "Bile Box");
	napInfo.AddItem("", "Mob Box");
	napInfo.AddItem("", "Flame Box");
	napInfo.AddItem("", "Sparkle Box");
	napInfo.AddItem("", "Item Box");
	napInfo.AddItem("", "Realism Box");
	napInfo.AddItem("", "Spit Box");
	napInfo.AddItem("", "Meteor Fall Box");
	napInfo.AddItem("", "Fireworks Box");
	napInfo.AddItem("", "Explosion Box");
	napInfo.AddItem("", "Bleed Box");
	napInfo.AddItem("", "Pet Box");
	napInfo.AddItem("", "Parachute Box");
	napInfo.AddItem("", "Armor Box");
	napInfo.AddItem("", "Shout Box");
	napInfo.AddItem("", "Blind Box");
	napInfo.AddItem("", "Blur Box");
	napInfo.AddItem("", "Snow Box");
	napInfo.AddItem("", "Warp Box");
	napInfo.AddItem("", "Distortion Box"); 
	napInfo.AddItem("", "Tank Box"); 
	napInfo.AddItem("", "Witch Box");
	napInfo.AddItem("", "Party Box"); 
	napInfo.AddItem("", "Airstrike Box");
	napInfo.AddItem("", "Flash Box");
	
	napInfo.ExitButton = true;
	napInfo.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int napInfoHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			DisplayBoxInfo(param1, param2);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action TogglePrediction(int client, int args)
{
	if (!IsSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	if (!(GetUserFlagBits(client) & ADMFLAG_GENERIC) && !(GetUserFlagBits(client) & ADMFLAG_ROOT) && !(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) && !(GetUserFlagBits(client) & ADMFLAG_CUSTOM2) && !(GetUserFlagBits(client) & ADMFLAG_CUSTOM3) && !(GetUserFlagBits(client) & ADMFLAG_CUSTOM4) && !(GetUserFlagBits(client) & ADMFLAG_CUSTOM5) && !(GetUserFlagBits(client) & ADMFLAG_CUSTOM6))
	{
		PrintToChat(client, "\x05[\x03NAP\x05]\x04 Admin\x01 and \x04VIP\x01 Access Only!");
		return Plugin_Handled;
	}
	
	if (iPredict[client] == 0)
	{
		iPredict[client] = 1;
		PrintToChat(client, "\x05[\x03NAP\x05]\x01 Prediction \x04Enabled\x01!");
	}
	else
	{
		iPredict[client] = 0;
		PrintToChat(client, "\x05[\x03NAP\x05]\x01 Prediction \x04Disabled\x01!");
	}
	
	char sNAPPredictionSetting[2];
	IntToString(iPredict[client], sNAPPredictionSetting, 2);
	SetClientCookie(client, hNAPPredictionSetting, sNAPPredictionSetting);
	
	return Plugin_Handled;
}

public Action nshAllSounds(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (!bEnabled || !IsSurvivor(entity))
	{
		return Plugin_Continue;
	}
	
	if (hDistortionTime[entity] != null && bDistorted[entity])
	{
		if (iDistortionType != 2 && iDistortionType != 3)
		{
			return Plugin_Continue;
		}
		
		if (StrContains(sample, "tank", false) != -1)
		{
			if (bSoundDistorted[entity])
			{
				bSoundDistorted[entity] = false;
				return Plugin_Continue;
			}
			
			bSoundDistorted[entity] = true;
			if (StrContains(sMap, "c4m", false) != -1)
			{
				int randDistortReplacement = GetRandomInt(1, 8);
				switch (randDistortReplacement)
				{
					case 1: EmitSoundToClient(entity, "music/witch/lost_little_witch_01a.wav");
					case 2: EmitSoundToClient(entity, "music/witch/lost_little_witch_01b.wav");
					case 3: EmitSoundToClient(entity, "music/witch/lost_little_witch_02a.wav");
					case 4: EmitSoundToClient(entity, "music/witch/lost_little_witch_02b.wav");
					case 5: EmitSoundToClient(entity, "music/witch/lost_little_witch_03a.wav");
					case 6: EmitSoundToClient(entity, "music/witch/lost_little_witch_03b.wav");
					case 7: EmitSoundToClient(entity, "music/witch/lost_little_witch_04a.wav");
					case 8: EmitSoundToClient(entity, "music/witch/lost_little_witch_04b.wav");
				}
			}
			else if (StrEqual(sMap, "c6m1_riverbank", false))
			{
				EmitSoundToClient(entity, "music/witch/witchencroacher_bride.wav");
			}
			else
			{
				EmitSoundToClient(entity, "music/witch/witchencroacher.wav");
			}
			return Plugin_Stop;
		}
		else if (StrContains(sample, "witch", false) != -1)
		{
			if (bSoundDistorted[entity])
			{
				bSoundDistorted[entity] = false;
				return Plugin_Continue;
			}
			
			bSoundDistorted[entity] = true;
			if (StrEqual(sMap, "c2m5_concert", false))
			{
				int randDistortReplacement = GetRandomInt(1, 2);
				switch (randDistortReplacement)
				{
					case 1: EmitSoundToClient(entity, "music/tank/midnighttank.wav");
					case 2: EmitSoundToClient(entity, "music/tank/onebadtank.wav");
				}
			}
			else
			{
				int randDistortReplacement = GetRandomInt(1, 2);
				switch (randDistortReplacement)
				{
					case 1: EmitSoundToClient(entity, "music/tank/tank.wav");
					case 2: EmitSoundToClient(entity, "music/tank/taank.wav");
				}
			}
			return Plugin_Stop;
		}
		else if (StrContains(sample, "finalnail", false) != -1 || StrContains(sample, "snowballinhell", false) != -1 || StrContains(sample, "yourownfuneral", false) != -1)
		{
			if (bSoundDistorted[entity])
			{
				bSoundDistorted[entity] = false;
				return Plugin_Continue;
			}
			
			bSoundDistorted[entity] = true;
			EmitSoundToClient(entity, "music/the_end/skinonourteeth.wav");
			return Plugin_Stop;
		}
		else if (StrContains(sample, "skinonourteeth", false) != -1)
		{
			if (bSoundDistorted[entity])
			{
				bSoundDistorted[entity] = false;
				return Plugin_Continue;
			}
			
			bSoundDistorted[entity] = true;
			
			int randDistortReplacement = GetRandomInt(1, 3);
			switch (randDistortReplacement)
			{
				case 1: EmitSoundToClient(entity, "music/the_end/yourownfuneral.wav");
				case 2: EmitSoundToClient(entity, "music/the_end/finalnail.wav");
				case 3: EmitSoundToClient(entity, "music/the_end/snowballinhell.wav");
			}
			return Plugin_Stop;
		}
		else if (StrContains(sample, "themonsterswithin", false) != -1)
		{
			if (bSoundDistorted[entity])
			{
				bSoundDistorted[entity] = false;
				return Plugin_Continue;
			}
			
			bSoundDistorted[entity] = true;
			
			int randDistortReplacement = GetRandomInt(1, 2);
			switch (randDistortReplacement)
			{
				case 1: EmitSoundToClient(entity, "music/safe/themonsterswithout.wav");
				case 2: EmitSoundToClient(entity, "music/safe/themonsterswithout_s.wav");
			}
			return Plugin_Stop;
		}
		else if (StrContains(sample, "themonsterswithout", false) != -1)
		{
			if (bSoundDistorted[entity])
			{
				bSoundDistorted[entity] = false;
				return Plugin_Continue;
			}
			
			bSoundDistorted[entity] = true;
			EmitSoundToClient(entity, "music/unalive/themonsterswithin.wav");
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	napEnable.RemoveChangeHook(OnNAPCVarsChanged);
	napFreezeDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napFreezeRadius.RemoveChangeHook(OnNAPCVarsChanged);
	napMatrixDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napMatrixGlow.RemoveChangeHook(OnNAPCVarsChanged);
	napSpeedDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napSpeedIncrease.RemoveChangeHook(OnNAPCVarsChanged);
	napImmuneDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napImmuneType.RemoveChangeHook(OnNAPCVarsChanged);
	napHealType.RemoveChangeHook(OnNAPCVarsChanged);
	napHealAmount.RemoveChangeHook(OnNAPCVarsChanged);
	napGravityDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napGravityAmount.RemoveChangeHook(OnNAPCVarsChanged);
	napGravityType.RemoveChangeHook(OnNAPCVarsChanged);
	napInvisibleDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napInvisibleType.RemoveChangeHook(OnNAPCVarsChanged);
	napInvisibleDummy.RemoveChangeHook(OnNAPCVarsChanged);
	napInvisibleDummyGlow.RemoveChangeHook(OnNAPCVarsChanged);
	napJingleDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napJingleBurnContact.RemoveChangeHook(OnNAPCVarsChanged);
	napJingleKillContact.RemoveChangeHook(OnNAPCVarsChanged);
	napBileRadius.RemoveChangeHook(OnNAPCVarsChanged);
	napBileSpecial.RemoveChangeHook(OnNAPCVarsChanged);
	napBileCommon.RemoveChangeHook(OnNAPCVarsChanged);
	napBileWitch.RemoveChangeHook(OnNAPCVarsChanged);
	napMobCount.RemoveChangeHook(OnNAPCVarsChanged);
	napRealismDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napRealismDmgMultiplier.RemoveChangeHook(OnNAPCVarsChanged);
	napMeteorFallDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napMeteorFallDamage.RemoveChangeHook(OnNAPCVarsChanged);
	napFireworksDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napFireworksBurnContact.RemoveChangeHook(OnNAPCVarsChanged);
	napPetProtectRange.RemoveChangeHook(OnNAPCVarsChanged);
	napPetHeight.RemoveChangeHook(OnNAPCVarsChanged);
	napPetDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napArmorDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napShoutDamage.RemoveChangeHook(OnNAPCVarsChanged);
	napShoutDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napShoutRange.RemoveChangeHook(OnNAPCVarsChanged);
	napBlindDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napBlurDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napSnowDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napSnowFreezeChance.RemoveChangeHook(OnNAPCVarsChanged);
	napWarpFrequency.RemoveChangeHook(OnNAPCVarsChanged);
	napWarpDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napDistortionDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napDistortionType.RemoveChangeHook(OnNAPCVarsChanged);
	napFlashDuration.RemoveChangeHook(OnNAPCVarsChanged);
	napInfectedSpawnType.RemoveChangeHook(OnNAPCVarsChanged);
	napNotification.RemoveChangeHook(OnNAPCVarsChanged);
	napUAMultiplied.RemoveChangeHook(OnNAPCVarsChanged);
	
	delete napEnable;
	delete napFreezeDuration;
	delete napFreezeRadius;
	delete napMatrixDuration;
	delete napMatrixGlow;
	delete napSpeedDuration;
	delete napSpeedIncrease;
	delete napImmuneDuration;
	delete napImmuneType;
	delete napHealType;
	delete napHealAmount;
	delete napGravityDuration;
	delete napGravityAmount;
	delete napGravityType;
	delete napInvisibleDuration;
	delete napInvisibleType;
	delete napInvisibleDummy;
	delete napInvisibleDummyGlow;
	delete napJingleDuration;
	delete napJingleBurnContact;
	delete napJingleKillContact;
	delete napBileRadius;
	delete napBileCommon;
	delete napBileSpecial;
	delete napBileWitch;
	delete napMobCount;
	delete napRealismDuration;
	delete napRealismDmgMultiplier;
	delete napMeteorFallDuration;
	delete napMeteorFallDamage;
	delete napFireworksDuration;
	delete napFireworksBurnContact;
	delete napPetProtectRange;
	delete napPetHeight;
	delete napPetDuration;
	delete napArmorDuration;
	delete napShoutDamage;
	delete napShoutDuration;
	delete napShoutRange;
	delete napBlindDuration;
	delete napBlurDuration;
	delete napSnowDuration;
	delete napSnowFreezeChance;
	delete napWarpFrequency;
	delete napWarpDuration;
	delete napDistortionDuration;
	delete napDistortionType;
	delete napFlashDuration;
	delete napInfectedSpawnType;
	delete napNotification;
	delete napUAMultiplied;
	
	UnhookEvent("upgrade_pack_begin", OnUpgradePackBegin);
	UnhookEvent("upgrade_pack_used", OnUpgradePackUsed);
	UnhookEvent("player_spawn", OnPlayerSpawn);
	UnhookEvent("player_death", OnPlayerDeath);
	UnhookEvent("upgrade_pack_added", OnUpgradePackAdded_Pre, EventHookMode_Pre);
	UnhookEvent("player_now_it", OnPlayerNowIt);
	UnhookEvent("revive_begin", OnReviveBegin);
	UnhookEvent("revive_success", OnReviveSuccess);
	
	UnhookEvent("round_start", OnRoundEvents);
	UnhookEvent("round_end", OnRoundEvents);
	UnhookEvent("finale_win", OnRoundEvents);
	UnhookEvent("mission_lost", OnRoundEvents);
	
	UnhookEvent("tongue_grab", OnInfectedGrab);
	UnhookEvent("lunge_pounce", OnInfectedGrab);
	UnhookEvent("jockey_ride", OnInfectedGrab);
	UnhookEvent("charger_carry_start", OnInfectedGrab);
	
	UnhookEvent("tongue_release", OnInfectedRelease);
	UnhookEvent("pounce_end", OnInfectedRelease);
	UnhookEvent("jockey_ride_end", OnInfectedRelease);
	UnhookEvent("charger_carry_end", OnInfectedRelease);
	UnhookEvent("charger_pummel_end", OnInfectedRelease);
	
	RemoveNormalSoundHook(nshAllSounds);
	
	alPlayerList.Clear();
	delete alPlayerList;
	
	RemoveOtherEffects();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, OnCheckDamages);
			
			ClearNAPData(i);
		}
	}
}

public void OnAllPluginsLoaded()
{
	if (!FileExists("../addons/sourcemod/extensions/left4downtown.ext.2.l4d2.dll"))
	{
		iInfectedSpawnType = 0;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnCheckDamages);
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	CreateTimer(1.0, NAP_Advertise, client, TIMER_REPEAT);
}

public Action NAP_Advertise(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	PrintToChat(client, "\x05[\x03NAP\x05]\x01 For Information About Box Types, Type \x04!nap_info");
	if ((GetUserFlagBits(client) & ADMFLAG_GENERIC) || (GetUserFlagBits(client) & ADMFLAG_ROOT) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM1) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM2) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM3) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM4) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM5) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM6))
	{
		PrintToChat(client, "\x05[\x03NAP\x05]\x01 As \x04Admin\x01/\x04VIP\x01, Type \x04!nap_predict\x01 To Toggle Your Prediction!");
	}
	return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnCheckDamages);
}

public Action OnCheckDamages(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!bEnabled || !IsSurvivor(victim) || !IsPlayerAlive(victim))
	{
		return Plugin_Continue;
	}
	
	if (bImmune[victim] || bJingling[victim] || bHasArmor[victim])
	{
		return Plugin_Handled;
	}
	else if (bRealismApplied)
	{
		damage *= fRealismDmgMultiplier;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof(sMap));
	
	PrecacheModel("materials/sprites/muzzleflash4.vmt", true);
	PrecacheModel("materials/sprites/muzzleflash4.vtf", true);
	
	iSprite[0] = PrecacheModel(LASERBEAM_SPRITE, true);
	iSprite[1] = PrecacheModel(HALO_SPRITE, true);
	iSprite[2] = PrecacheModel(BLOODSPRAY_SPRITE, true);
	iSprite[3] = PrecacheModel(BLOOD_SPRITE, true);
	iSprite[4] = PrecacheModel(EXPLOSION_SPRITE, true);
	
	for (int i = 0; i < 15; i++)
	{
		PrecacheModel(sNAPModels[i], true);
	}
	
	for (int i = 0; i < 36; i++)
	{
		PrefetchSound(sNAPSounds[i]);
		PrecacheSound(sNAPSounds[i], true);
	}
	
	for (int i = 0; i < 16; i++)
	{
		PrecacheParticle(sNAPParticles[i]);
	}
	
	RemoveOtherEffects();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			ClearNAPData(i);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity <= 0 || entity > 2048)
	{
		return;
	}
	
	if (StrEqual(classname, "infected") || StrEqual(classname, "witch"))
	{
		SDKHook(entity, SDKHook_StartTouch, OnEntityTouch);
		SDKHook(entity, SDKHook_Touch, OnEntityTouch);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEdict(entity))
	{
		return;
	}
	
	char sEntityClass[64];
	GetEdictClassname(entity, sEntityClass, sizeof(sEntityClass));
	if (StrEqual(sEntityClass, "infected") || StrEqual(sEntityClass, "witch"))
	{
		SDKUnhook(entity, SDKHook_StartTouch, OnEntityTouch);
		SDKUnhook(entity, SDKHook_Touch, OnEntityTouch);
	}
}

public Action OnEntityTouch(int entity, int other)
{
	if (!bEnabled || !bJingleBurnContact)
	{
		return Plugin_Continue;
	}
	
	if (!IsSurvivor(other) || !IsPlayerAlive(other) || !bJingling[other])
	{
		return Plugin_Continue;
	}
	
	if (IsValidEnt(entity))
	{
		char sEntityClass[64];
		GetEdictClassname(entity, sEntityClass, sizeof(sEntityClass));
		if (StrEqual(sEntityClass, "infected"))
		{
			IgniteEntity(entity, 2.0);
			
			Event OnInfectedDeath = CreateEvent("infected_death", true);
			OnInfectedDeath.SetInt("attacker", GetClientUserId(other));
			OnInfectedDeath.SetInt("infected_id", entity);
			OnInfectedDeath.Fire();
			
			AcceptEntityInput(entity, "BecomeRagdoll");
		}
		else if (StrEqual(sEntityClass, "witch"))
		{
			IgniteEntity(entity, 500.0);
		}
	}
	
	return Plugin_Continue;
}

public Action OnUpgradePackBegin(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return Plugin_Continue;
	}
	
	int deployer = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(deployer) || !IsPlayerAlive(deployer) || !(GetEntProp(deployer, Prop_Send, "m_fFlags") & FL_ONGROUND))
	{
		return Plugin_Continue;
	}
	
	int randAPIndex = GetRandomInt(1, 47);
	switch (randAPIndex)
	{
		case 1,5,9,13,17,21,25,29,33,37,41,45:
		{
			iAPIndex[deployer] = 0;
			sAPName[deployer][0] = '\0';
		}
		case 2:
		{
			iAPIndex[deployer] = 1;
			strcopy(sAPName[deployer], 32, "Freeze Box");
		}
		case 3:
		{
			iAPIndex[deployer] = 2;
			strcopy(sAPName[deployer], 32, "Matrix Box");
		}
		case 4:
		{
			iAPIndex[deployer] = 3;
			strcopy(sAPName[deployer], 32, "Speed Box");
		}
		case 6:
		{
			iAPIndex[deployer] = 4;
			strcopy(sAPName[deployer], 32, "Immune Box");
		}
		case 7:
		{
			iAPIndex[deployer] = 5;
			strcopy(sAPName[deployer], 32, "Heal Box");
		}
		case 8:
		{
			iAPIndex[deployer] = 6;
			strcopy(sAPName[deployer], 32, "Gravity Box");
		}
		case 10:
		{
			iAPIndex[deployer] = 7;
			strcopy(sAPName[deployer], 32, "Invisible Box");
		}
		case 11:
		{
			iAPIndex[deployer] = 8;
			strcopy(sAPName[deployer], 32, "Ammo Box");
		}
		case 12:
		{
			iAPIndex[deployer] = 9;
			strcopy(sAPName[deployer], 32, "Weaponry Box");
		}
		case 14:
		{
			iAPIndex[deployer] = 10;
			strcopy(sAPName[deployer], 32, "Jingle Box");
		}
		case 15:
		{
			iAPIndex[deployer] = 11;
			strcopy(sAPName[deployer], 32, "Bile Box");
		}
		case 16:
		{
			iAPIndex[deployer] = 12;
			strcopy(sAPName[deployer], 32, "Mob Box");
		}
		case 18:
		{
			iAPIndex[deployer] = 13;
			strcopy(sAPName[deployer], 32, "Flame Box");
		}
		case 19:
		{
			iAPIndex[deployer] = 14;
			strcopy(sAPName[deployer], 32, "Sparkle Box");
		}
		case 20:
		{
			iAPIndex[deployer] = 15;
			strcopy(sAPName[deployer], 32, "Item Box");
		}
		case 22:
		{
			iAPIndex[deployer] = 16;
			strcopy(sAPName[deployer], 32, "Realism Box");
		}
		case 23:
		{
			iAPIndex[deployer] = 17;
			strcopy(sAPName[deployer], 32, "Spit Box");
		}
		case 24:
		{
			iAPIndex[deployer] = 18;
			strcopy(sAPName[deployer], 32, "Meteor Fall Box");
		}
		case 26:
		{
			iAPIndex[deployer] = 19;
			strcopy(sAPName[deployer], 32, "Fireworks Box");
		}
		case 27:
		{
			iAPIndex[deployer] = 20;
			strcopy(sAPName[deployer], 32, "Explosion Box");
		}
		case 28:
		{
			iAPIndex[deployer] = 21;
			strcopy(sAPName[deployer], 32, "Bleed Box");
		}
		case 30:
		{
			iAPIndex[deployer] = 22;
			strcopy(sAPName[deployer], 32, "Pet Box");
		}
		case 31:
		{
			iAPIndex[deployer] = 23;
			strcopy(sAPName[deployer], 32, "Parachute Box");
		}
		case 32:
		{
			iAPIndex[deployer] = 24;
			strcopy(sAPName[deployer], 32, "Armor Box");
		}
		case 34:
		{
			iAPIndex[deployer] = 25;
			strcopy(sAPName[deployer], 32, "Shout Box");
		}
		case 35:
		{
			iAPIndex[deployer] = 26;
			strcopy(sAPName[deployer], 32, "Blind Box");
		}
		case 36:
		{
			iAPIndex[deployer] = 27;
			strcopy(sAPName[deployer], 32, "Blur Box");
		}
		case 38:
		{
			iAPIndex[deployer] = 28;
			strcopy(sAPName[deployer], 32, "Snow Box");
		}
		case 39:
		{
			iAPIndex[deployer] = 29;
			strcopy(sAPName[deployer], 32, "Warp Box");
		}
		case 40:
		{
			iAPIndex[deployer] = 30;
			strcopy(sAPName[deployer], 32, "Distortion Box");
		}
		case 42:
		{
			iAPIndex[deployer] = 31;
			strcopy(sAPName[deployer], 32, "Tank Box");
		}
		case 43:
		{
			iAPIndex[deployer] = 32;
			strcopy(sAPName[deployer], 32, "Witch Box");
		}
		case 44:
		{
			iAPIndex[deployer] = 33;
			strcopy(sAPName[deployer], 32, "Party Box");
		}
		case 46:
		{
			iAPIndex[deployer] = 34;
			strcopy(sAPName[deployer], 32, "Airstrike Box");
		}
		case 47:
		{
			iAPIndex[deployer] = 35;
			strcopy(sAPName[deployer], 32, "Flash Box");
		}
	}
	
	if (iPredict[deployer] == 1 && iAPIndex[deployer] != 0 && sAPName[deployer][0] != '\0')
	{
		PrintToChat(deployer, "\x05[\x03NAP\x05]\x01 Box Type: \x04%s", sAPName[deployer]);
	}
	return Plugin_Continue;
}

public Action OnUpgradePackUsed(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return Plugin_Continue;
	}
	
	int deployer = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(deployer) || !IsPlayerAlive(deployer))
	{
		return Plugin_Continue;
	}
	
	int deployed = event.GetInt("upgradeid");
	if (!IsValidEnt(deployed))
	{
		return Plugin_Continue;
	}
	
	char sUpgradeType[256];
	GetEdictClassname(deployed, sUpgradeType, sizeof(sUpgradeType));
	if (StrEqual(sUpgradeType, "upgrade_laser_sight"))
	{
		return Plugin_Continue;
	}
	
	iLastDeployer = deployer;
	
	AmmoPackEffects(deployer, iAPIndex[deployer]);
	if (iAPIndex[deployer] > 0)
	{
		DeleteEntity(deployed);
		iAPIndex[deployer] = 0;
	}
	
	return Plugin_Continue;
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return Plugin_Continue;
	}
	
	int spawned = GetClientOfUserId(event.GetInt("userid"));
	if (IsSurvivor(spawned))
	{
		if (!IsFakeClient(spawned))
		{
			char sLastPredict[2];
			GetClientCookie(spawned, hNAPPredictionSetting, sLastPredict, sizeof(sLastPredict));
			if (strlen(sLastPredict))
			{
				iPredict[spawned] = StringToInt(sLastPredict);
			}
		}
		
		if (bMatrixApplied)
		{
			if (iMatrixGlow == 2 || iMatrixGlow == 4)
			{
				if (spawned == iLastDeployer)
				{
					L4D2_SetEntGlow(spawned, L4D2Glow_Constant, 100000, 0, {255, 255, 0}, false);
				}
				else
				{
					L4D2_SetEntGlow(spawned, L4D2Glow_Constant, 100000, 0, {0, 0, 255}, false);
				}
			}
			else if (iMatrixGlow == 1 && spawned == iLastDeployer)
			{
				L4D2_SetEntGlow(spawned, L4D2Glow_Constant, 100000, 0, {255, 255, 0}, false);
			}
		}
	}
	else if (IsInfected(spawned) && bMatrixApplied && iMatrixGlow > 2)
	{
		L4D2_SetEntGlow(spawned, L4D2Glow_Constant, 100000, 0, {255, 0, 0}, false);
	}
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return Plugin_Continue;
	}
	
	int died = GetClientOfUserId(event.GetInt("userid"));
	if (IsInfected(died) && bMatrixApplied && iMatrixGlow > 2)
	{
		L4D2_SetEntGlow(died, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
	}
	else if (IsSurvivor(died))
	{
		ClearNAPData(died);
		if (iMatrixGlow != 3)
		{
			L4D2_SetEntGlow(died, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
		}
	}
	return Plugin_Continue;
}

public Action OnUpgradePackAdded_Pre(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return Plugin_Continue;
	}
	
	int deployer = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(deployer) || !IsPlayerAlive(deployer))
	{
		return Plugin_Continue;
	}
	
	int deployed = event.GetInt("upgradeid");
	if (!IsValidEnt(deployed))
	{
		return Plugin_Continue;
	}
	
	char sUpgradeType[256];
	GetEdictClassname(deployed, sUpgradeType, sizeof(sUpgradeType));
	if (StrEqual(sUpgradeType, "upgrade_laser_sight"))
	{
		return Plugin_Continue;
	}
	
	int iEntityUsed = SDKCall(hNAPFindUseEntity, deployer, 96.0, 0.0, 0.0, 0, false);
	if (!IsValidEntity(iEntityUsed))
	{
		return Plugin_Continue;
	}
	
	int iCurrentAPID = GetAmmoPackID(iEntityUsed);
	
	bAmmoPackUsed[iCurrentAPID][deployer] = true;
	iAPMaxUses[iCurrentAPID] -= 1;
	
	SetEntData(iEntityUsed, iAPCountFix, iAPMaxUses[iCurrentAPID], 1, true);
	if (hAmmoPackResetTime[iCurrentAPID] == null)
	{
		hAmmoPackResetTime[iCurrentAPID] = CreateTimer(0.2, ResetAmmoPack, iCurrentAPID);
	}
	
	int iUpgradeAmmo = GetUpgradeAmmoCount(deployer, bUAMultiplied);
	if (iUpgradeAmmo > 1)
	{
		SetUpgradeAmmoCount(deployer, iUpgradeAmmo);
	}
	
	return Plugin_Continue;
}

public Action ResetAmmoPack(Handle timer, any entityID)
{
	if (!IsValidEntity(iAmmoPackID[entityID]))
	{
		return Plugin_Stop;
	}
	
	SetEntData(iAmmoPackID[entityID], FindSendPropInfo("CBaseUpgradeItem", "m_iUsedBySurvivorsMask"), 0, 1, true);
	
	hAmmoPackResetTime[entityID] = null;
	return Plugin_Stop;
}

public Action OnReviveBegin(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return Plugin_Continue;
	}
	
	int reviver = GetClientOfUserId(event.GetInt("userid")),
		revived = GetClientOfUserId(event.GetInt("subject"));
	
	if (!IsSurvivor(reviver) || !IsSurvivor(revived) || !bJingling[revived])
	{
		return Plugin_Continue;
	}
	
	int buttons = GetClientButtons(reviver);
	SetEntProp(reviver, Prop_Data, "m_nButtons", buttons & ~IN_USE);
	
	return Plugin_Continue;
}

public Action OnReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return Plugin_Continue;
	}
	
	int revived = GetClientOfUserId(event.GetInt("subject"));
	if (!IsSurvivor(revived) || !bFrozen[revived])
	{
		return Plugin_Continue;
	}
	
	SetEntityMoveType(revived, MOVETYPE_NONE);
	return Plugin_Continue;
}

public Action OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return Plugin_Continue;
	}
	
	RemoveOtherEffects();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			ClearNAPData(i);
		}
	}
	if (StrEqual(name, "round_start"))
	{
		ResetAPStats();
		CreateTimer(1.0, StartNAPInit);
	}
	else
	{
		if (StrEqual(name, "round_end") && iGameMode != 2)
		{
			return Plugin_Continue;
		}
		
		Call_StartForward(hNAPInitForward);
		Call_PushCell(0);
		Call_Finish();
	}
	
	return Plugin_Continue;
}

public Action StartNAPInit(Handle timer)
{
	Call_StartForward(hNAPInitForward);
	Call_PushCell(1);
	Call_Finish();
	
	return Plugin_Stop;
}

public Action OnInfectedGrab(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled || !bJingleKillContact)
	{
		return Plugin_Continue;
	}
	
	int grabber = GetClientOfUserId(event.GetInt("userid")),
		grabbed = GetClientOfUserId(event.GetInt("victim"));
	
	if (!IsInfected(grabber) || !IsSurvivor(grabbed))
	{
		return Plugin_Continue;
	}
	
	if (bJingling[grabbed])
	{
		IgniteEntity(grabber, 5.0);
		
		switch (GetEntProp(grabber, Prop_Send, "m_zombieClass"))
		{
			case 1:
			{
				Event OnTonguePullStopped = CreateEvent("tongue_pull_stopped", true);
				OnTonguePullStopped.SetInt("userid", GetClientUserId(grabbed));
				OnTonguePullStopped.SetInt("victim", GetClientUserId(grabbed));
				OnTonguePullStopped.SetInt("smoker", GetClientUserId(grabber));
				OnTonguePullStopped.Fire(false);
			}
			case 3:
			{
				Event OnPounceStopped = CreateEvent("pounce_stopped", true);
				OnPounceStopped.SetInt("userid", GetClientUserId(grabbed));
				OnPounceStopped.SetInt("victim", GetClientUserId(grabbed));
				OnPounceStopped.Fire(false);
			}
			case 5:
			{
				Event OnJockeyRideEnd = CreateEvent("jockey_ride_end", true);
				OnJockeyRideEnd.SetInt("userid", GetClientUserId(grabber));
				OnJockeyRideEnd.SetInt("victim", GetClientUserId(grabbed));
				OnJockeyRideEnd.SetInt("rescuer", GetClientUserId(grabbed));
				OnJockeyRideEnd.Fire(false);
			}
			case 6:
			{
				Event OnChargerKilled = CreateEvent("charger_killed", true);
				OnChargerKilled.SetInt("userid", GetClientUserId(grabber));
				OnChargerKilled.SetInt("attacker", GetClientUserId(grabbed));
				OnChargerKilled.SetBool("charging", true);
				OnChargerKilled.Fire(false);
			}
		}
		
		Event playerDeathEvent = CreateEvent("player_death");
		playerDeathEvent.SetInt("userid", GetClientUserId(grabber));
		playerDeathEvent.SetInt("attacker", GetClientUserId(grabbed));
		playerDeathEvent.Fire(false);
		
		ForcePlayerSuicide(grabber);
	}
	else if (bHasPet[grabbed] && IsValidEnt(iPetEnt[grabbed]))
	{
		iPetTarget[iPetEnt[grabbed]] = grabber;
	}
	
	return Plugin_Continue;
}

public Action OnInfectedRelease(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return Plugin_Continue;
	}
	
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!IsSurvivor(victim) || !IsPlayerAlive(victim))
	{
		return Plugin_Continue;
	}
	
	if (bFrozen[victim])
	{
		SetEntityMoveType(victim, MOVETYPE_NONE);
	}
	
	if (bHasPet[victim] && IsValidEnt(iPetEnt[victim]))
	{
		iPetTarget[iPetEnt[victim]] = 0;
	}
	
	return Plugin_Continue;
}

public Action OnPlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled || iImmuneType == 0)
	{
		return Plugin_Continue;
	}
	
	int vomited = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(vomited) || !IsPlayerAlive(vomited) || !bImmune[vomited])
	{
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public void OnGameFrame()
{
	if (!bEnabled)
	{
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			if (!bHasParachute[i] || !IsValidEnt(iParachuteEnt[i]))
			{
				continue;
			}
			
			int iButtons = GetClientButtons(i);
			if (iButtons & IN_USE)
			{
				float fFallHeight = GetFallHeight(i);
				if (fFallHeight > 750.0)
				{
					if (bParachuteUseWarned[i])
					{
						if (iParachuteUseWarnTimes[i] >= 45)
						{
							bParachuteUseWarned[i] = false;
							iParachuteUseWarnTimes[i] = 0;
						}
						else
						{
							iParachuteUseWarnTimes[i] += 1;
						}
					}
					else
					{
						bParachuteUseWarned[i] = true;
						PrintToChat(i, "\x05[\x03NAP\x05]\x01 Height Too High!");
					}
					continue;
				}
				else if (fFallHeight >= 200.0 && fFallHeight <= 750.0)
				{
					if (bParachuteUsed[iParachuteEnt[i]])
					{
						BeginParachuteFall(i);
						
						float fParachuteUserPos[3], fParachuteUserAng[3], fParachuteAngle[3];
						
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", fParachuteUserPos);
						GetEntPropVector(i, Prop_Send, "m_angRotation", fParachuteUserAng);
						
						fParachuteAngle[1] = fParachuteUserAng[1];
						TeleportEntity(iParachuteEnt[i], fParachuteUserPos, fParachuteAngle, NULL_VECTOR);
					}
					else
					{
						bParachuteUsed[iParachuteEnt[i]] = true;
						
						float fParachuteUserPos[3], fParachuteUserAng[3], fParachuteAngle[3];
						
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", fParachuteUserPos);
						GetEntPropVector(i, Prop_Send, "m_angRotation", fParachuteUserAng);
						
						fParachuteAngle[1] = fParachuteUserAng[1];
						TeleportEntity(iParachuteEnt[i], fParachuteUserPos, fParachuteAngle, NULL_VECTOR);
						
						char sParachuteModel[128];
						GetEntPropString(iParachuteEnt[i], Prop_Data, "m_ModelName", sParachuteModel, sizeof(sParachuteModel));
						if (StrEqual(sParachuteModel, sNAPModels[4], false))
						{
							L4D2_SetEntGlow(iParachuteEnt[i], L4D2Glow_Constant, 5000, 0, {0, 0, 255}, false);
						}
						else if (StrEqual(sParachuteModel, sNAPModels[5], false))
						{
							L4D2_SetEntGlow(iParachuteEnt[i], L4D2Glow_Constant, 5000, 0, {0, 110, 0}, false);
						}
						else if (StrEqual(sParachuteModel, sNAPModels[6], false))
						{
							L4D2_SetEntGlow(iParachuteEnt[i], L4D2Glow_Constant, 5000, 0, {0, 255, 0}, false);
						}
						else if (StrEqual(sParachuteModel, sNAPModels[7], false))
						{
							L4D2_SetEntGlow(iParachuteEnt[i], L4D2Glow_Constant, 5000, 0, {0, 0, 110}, false);
						}
					}
				}
				else if (fFallHeight <= 100.0)
				{
					if (!bParachuteUsed[iParachuteEnt[i]])
					{
						continue;
					}
					
					bParachuteUsed[iParachuteEnt[i]] = false;
					RemoveParachute(i);
					
					if (iExtraParachute[i] > 0)
					{
						ProvideParachute(i);
						iExtraParachute[i] -= 1;
					}
					else
					{
						bHasParachute[i] = false;
					}
					PrintToChat(i, "\x05[\x03NAP\x05]\x01 You've Landed Safely!");
				}
			}
			else
			{
				if (!bParachuteUsed[iParachuteEnt[i]])
				{
					continue;
				}
				
				bParachuteUsed[iParachuteEnt[i]] = false;
				
				TeleportEntity(iParachuteEnt[i], view_as<float>({ 0.0, 0.0, 0.0 }), NULL_VECTOR, NULL_VECTOR);
				L4D2_SetEntGlow(iParachuteEnt[i], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
				
				SetEntityGravity(i, 1.0);
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!bEnabled || !IsSurvivor(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	if (buttons & IN_USE)
	{
		int iEntityUsed = SDKCall(hNAPFindUseEntity, client, 96.0, 0.0, 0.0, 0, false);
		if (!IsValidEntity(iEntityUsed))
		{
			return Plugin_Continue;
		}
		
		char sEntityNetClass[30];
		GetEntityNetClass(iEntityUsed, sEntityNetClass, sizeof(sEntityNetClass));
		if (!strcmp(sEntityNetClass, "CBaseUpgradeItem"))
		{
			iLastDeployedAP = GetAmmoPackID(iEntityUsed);
			CheckUsableAmmoPack(client, iLastDeployedAP);
		}
		else
		{
			float fPos[2][3];
			
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos[0]);
			if (iLastDeployedAP > -1 && IsValidEntity(iAmmoPackID[iLastDeployedAP]))
			{
				GetEntityNetClass(iAmmoPackID[iLastDeployedAP], sEntityNetClass, sizeof(sEntityNetClass));
				if (!strcmp(sEntityNetClass, "CBaseUpgradeItem"))
				{
					GetEntPropVector(iAmmoPackID[iLastDeployedAP], Prop_Send, "m_vecOrigin", fPos[1]);
					
					if (GetVectorDistance(fPos[1], fPos[0]) < 196.0)
					{
						CheckUsableAmmoPack(client, iLastDeployedAP);
					}
				}
				else
				{
					iLastDeployedAP = -1;
				}
			}
			else
			{
				iLastDeployedAP = -1;
			}
		}
	}
	else if (buttons & IN_RELOAD)
	{
		int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEnt(iActiveWeapon) && GetEntProp(iActiveWeapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1) > 0)
		{
			buttons &= ~IN_RELOAD;
		}
	}
	
	return Plugin_Continue;
}

public void OnMapEnd()
{
	alPlayerList.Clear();
	
	RemoveOtherEffects();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ClearNAPData(i);
		}
	}
}

void DisplayBoxInfo(int client, int iAmmoPackType)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}
	
	char sTitle[128], sText[3][128];
	switch (iAmmoPackType)
	{
		case 0:
		{
			strcopy(sTitle, sizeof(sTitle), "Freeze Box Info:");
			strcopy(sText[0], 128, "- Freezes the deployer and nearby teammates.");
			strcopy(sText[1], 128, "- Creates a blue beam ring around the deployer.");
			strcopy(sText[2], 128, "- Freezes you back after being released by infected.");
		}
		case 1:
		{
			strcopy(sTitle, sizeof(sTitle), "Matrix Box Info:");
			strcopy(sText[0], 128, "- Activates Slow Motion.");
			strcopy(sText[1], 128, "- Location of players will be known.");
		}
		case 2:
		{
			strcopy(sTitle, sizeof(sTitle), "Speed Box Info:");
			strcopy(sText[0], 128, "- Gives the deployer an increased speed.");
			strcopy(sText[1], 128, "- Adds adrenaline effect for realistic display.");
		}
		case 3:
		{
			strcopy(sTitle, sizeof(sTitle), "Immune Box Info:");
			strcopy(sText[0], 128, "- Temporary god mode for the deployer.");
			strcopy(sText[1], 128, "- Black aura for status indication.");
		}
		case 4:
		{
			strcopy(sTitle, sizeof(sTitle), "Heal Box Info:");
			strcopy(sText[0], 128, "- Heals you and removes your injuries.");
		}
		case 5:
		{
			strcopy(sTitle, sizeof(sTitle), "Gravity Box Info:");
			strcopy(sText[0], 128, "- Changes every player's gravity.");
			strcopy(sText[1], 128, "- Infected will have a hard time capturing you.");
		}
		case 6:
		{
			strcopy(sTitle, sizeof(sTitle), "Invisible Box Info:");
			strcopy(sText[0], 128, "- Deployer will be non-visible to everyone.");
			strcopy(sText[1], 128, "- Equipped weapons will be cloaked.");
			strcopy(sText[2], 128, "- Infected wlll attack your dummy (if there any) instead.");
		}
		case 7:
		{
			strcopy(sTitle, sizeof(sTitle), "Ammo Box Info:");
			strcopy(sText[0], 128, "- Spawn 2 ammo packs of each kind.");
			strcopy(sText[1], 128, "- They will have a glow around them to let others notice.");
		}
		case 8:
		{
			strcopy(sTitle, sizeof(sTitle), "Weaponry Box Info:");
			strcopy(sText[0], 128, "- Spawn lots of weapons.");
			strcopy(sText[1], 128, "- Either Tier 1, Tier 2, or Tier 3.");
			strcopy(sText[2], 128, "- Useful for players that are running out of ammo.");
		}
		case 9:
		{
			strcopy(sTitle, sizeof(sTitle), "Jingle Box Info:");
			strcopy(sText[0], 128, "- Incaps the deployer while giving him immunity.");
			strcopy(sText[1], 128, "- Burns common and kills special infected on contact (if enabled).");
			strcopy(sText[2], 128, "- Deployer can't be revived until the effect wears off.");
		}
		case 10:
		{
			strcopy(sTitle, sizeof(sTitle), "Bile Box Info:");
			strcopy(sText[0], 128, "- Vomits the deployer and nearby teammates.");
			strcopy(sText[1], 128, "- (If enabled) Nearby infected will be covered by bile.");
			strcopy(sText[2], 128, "- (If enabled) Nearby witches will be covered by bile.");
		}
		case 11:
		{
			strcopy(sTitle, sizeof(sTitle), "Mob Box Info:");
			strcopy(sText[0], 128, "- Calls mega mobs to swarm the Survivors.");
		}
		case 12:
		{
			strcopy(sTitle, sizeof(sTitle), "Flame Box Info:");
			strcopy(sText[0], 128, "- Burns everything around the deployer.");
		}
		case 13:
		{
			strcopy(sTitle, sizeof(sTitle), "Sparkle Box Info:");
			strcopy(sText[0], 128, "- Burns everything around the deployer.");
			strcopy(sText[1], 128, "- Additional firecracker effect.");
		}
		case 14:
		{
			strcopy(sTitle, sizeof(sTitle), "Item Box Info:");
			strcopy(sText[0], 128, "- Spawns a bunch of items.");
			strcopy(sText[1], 128, "- Either throwables or health-related.");
			strcopy(sText[2], 128, "- Useful for hordes or when limping.");
		}
		case 15:
		{
			strcopy(sTitle, sizeof(sTitle), "Realism Box Info:");
			strcopy(sText[0], 128, "- Fellow Survivors will have their glows removed.");
			strcopy(sText[1], 128, "- All damages are multiplied.");
		}
		case 16:
		{
			strcopy(sTitle, sizeof(sTitle), "Spit Box Info:");
			strcopy(sText[0], 128, "- Spawns an acid spit at the deployer's feet.");
			strcopy(sText[1], 128, "- The deployer will be the attacker by default.");
		}
		case 17:
		{
			strcopy(sTitle, sizeof(sTitle), "Meteor Fall Box Info:");
			strcopy(sText[0], 128, "- Summons meteors that will fall from the sky.");
			strcopy(sText[1], 128, "- Avoid them to prevent from taking any damage.");
			strcopy(sText[2], 128, "- Be careful as they will make you push back.");
		}
		case 18:
		{
			strcopy(sTitle, sizeof(sTitle), "Fireworks Box Info:");
			strcopy(sText[0], 128, "- Displays a bunch of fireworks.");
			strcopy(sText[1], 128, "- Common Infected will be attracted to it.");
			strcopy(sText[2], 128, "- Burns anything around it.");
		}
		case 19:
		{
			strcopy(sTitle, sizeof(sTitle), "Explosion Box Info:");
			strcopy(sText[0], 128, "- Spawns an explosion at the deployer's position.");
			strcopy(sText[1], 128, "- Deals tremendous damage so be careful.");
			strcopy(sText[2], 128, "- Knocks back deployer and nearby teammates.");
		}
		case 20:
		{
			strcopy(sTitle, sizeof(sTitle), "Bleed Box Info:");
			strcopy(sText[0], 128, "- Your permanent health will be turned into");
			strcopy(sText[1], 128, "  temporary health.");
			strcopy(sText[2], 128, "- Your temporary health will be added.");
		}
		case 21:
		{
			strcopy(sTitle, sizeof(sTitle), "Pet Box Info:");
			strcopy(sText[0], 128, "- Summons a pet to act as your shield.");
			strcopy(sText[1], 128, "- It will scan for enemies and shoots them.");
		}
		case 22:
		{
			strcopy(sTitle, sizeof(sTitle), "Parachute Box Info:");
			strcopy(sText[0], 128, "- Gives the deployer a parachute.");
			strcopy(sText[1], 128, "- The parachute has a complex mechanism.");
			strcopy(sText[2], 128, "- Useful when falling from tall heights.");
		}
		case 23:
		{
			strcopy(sTitle, sizeof(sTitle), "Armor Box Info:");
			strcopy(sText[0], 128, "- Gives armor to the deployer.");
			strcopy(sText[1], 128, "- All damages are taken by the armor.");
		}
		case 24:
		{
			strcopy(sTitle, sizeof(sTitle), "Shout Box Info:");
			strcopy(sText[0], 128, "- Makes the deployer shout.");
			strcopy(sText[1], 128, "- Nearby teammates and enemies will stagger.");
			strcopy(sText[2], 128, "- Added shouting effect for style.");
		}
		case 25:
		{
			strcopy(sTitle, sizeof(sTitle), "Blind Box Info:");
			strcopy(sText[0], 128, "- Lessens the brightness of the deployer's sight.");
		}
		case 26:
		{
			strcopy(sTitle, sizeof(sTitle), "Blur Box Info:");
			strcopy(sText[0], 128, "- All players' visions will be blurred.");
		}
		case 27:
		{
			strcopy(sTitle, sizeof(sTitle), "Snow Box Info:");
			strcopy(sText[0], 128, "- Makes the map provide snow.");
			strcopy(sText[1], 128, "- Randomly, one survivor will catch frost bite.");
		}
		case 28:
		{
			strcopy(sTitle, sizeof(sTitle), "Warp Box Info:");
			strcopy(sText[0], 128, "- Teleports the deployer to every teammate.");
			strcopy(sText[1], 128, "- Added effect and sound for touch.");
		}
		case 29:
		{
			strcopy(sTitle, sizeof(sTitle), "Distortion Box Info:");
			strcopy(sText[0], 128, "- Deployer will experience distorted reality.");
			strcopy(sText[1], 128, "- He/She will see different colors, views, and");
			strcopy(sText[2], 128, "  hear sounds that are opposite to what is being played.");
		}
		case 30:
		{
			strcopy(sTitle, sizeof(sTitle), "Tank Box Info:");
			strcopy(sText[0], 128, "- Spawns a tank at the deployer's position.");
		}
		case 31:
		{
			strcopy(sTitle, sizeof(sTitle), "Witch Box Info:");
			strcopy(sText[0], 128, "- Spawns a witch at the deployer's position.");
		}
		case 32:
		{
			strcopy(sTitle, sizeof(sTitle), "Party Box Info:");
			strcopy(sText[0], 128, "- All possible threats will surround you.");
			strcopy(sText[1], 128, "- Either every uncommon or special infected.");
			strcopy(sText[2], 128, "- As a bonus, a mega mob will spawn.");
		}
		case 33:
		{
			strcopy(sTitle, sizeof(sTitle), "Airstrike Box Info:");
			strcopy(sText[0], 128, "- Deployer commands an F-18 plane to launch");
			strcopy(sText[1], 128, "  a bomb at his position.");
			strcopy(sText[2], 128, "- Hurts everything around the bombed area.");
		}
		case 34:
		{
			strcopy(sTitle, sizeof(sTitle), "Flash Box Info:");
			strcopy(sText[0], 128, "- Turns the vision of everyone in range");
			strcopy(sText[1], 128, "  to white similar to being blinded by a");
			strcopy(sText[2], 128, "  flashbang on other Source games.");
		}
	}
	
	Panel infoPanel = new Panel();
	infoPanel.SetTitle(sTitle);
	infoPanel.DrawText(" \n");
	
	infoPanel.DrawText(sText[0]);
	if (!StrEqual(sText[1], ""))
	{
		infoPanel.DrawText(sText[1]);
	}
	if (!StrEqual(sText[2], ""))
	{
		infoPanel.DrawText(sText[2]);
	}
	
	infoPanel.DrawText(" \n");
	infoPanel.DrawItem("Back");
	
	infoPanel.Send(client, napInfoPanel, 20);
	delete infoPanel;
}

public int napInfoPanel(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			Menu napInfo = new Menu(napInfoHandler);
			napInfo.SetTitle("Ammo Packs Information:");
			
			napInfo.AddItem("", "Freeze Box");
			napInfo.AddItem("", "Matrix Box");
			napInfo.AddItem("", "Speed Box");
			napInfo.AddItem("", "Immune Box");
			napInfo.AddItem("", "Heal Box");
			napInfo.AddItem("", "Gravity Box");
			napInfo.AddItem("", "Invisible Box");
			napInfo.AddItem("", "Ammo Box");
			napInfo.AddItem("", "Weaponry Box");
			napInfo.AddItem("", "Jingle Box");
			napInfo.AddItem("", "Bile Box");
			napInfo.AddItem("", "Mob Box");
			napInfo.AddItem("", "Flame Box");
			napInfo.AddItem("", "Sparkle Box");
			napInfo.AddItem("", "Item Box");
			napInfo.AddItem("", "Realism Box");
			napInfo.AddItem("", "Spit Box");
			napInfo.AddItem("", "Meteor Fall Box");
			napInfo.AddItem("", "Fireworks Box");
			napInfo.AddItem("", "Explosion Box");
			napInfo.AddItem("", "Bleed Box");
			napInfo.AddItem("", "Pet Box");
			napInfo.AddItem("", "Parachute Box");
			napInfo.AddItem("", "Armor Box");
			napInfo.AddItem("", "Shout Box");
			napInfo.AddItem("", "Blind Box");
			napInfo.AddItem("", "Blur Box");
			napInfo.AddItem("", "Snow Box");
			napInfo.AddItem("", "Warp Box");
			napInfo.AddItem("", "Distortion Box");
			napInfo.AddItem("", "Tank Box");
			napInfo.AddItem("", "Witch Box");
			napInfo.AddItem("", "Party Box");
			napInfo.AddItem("", "Airstrike Box");
			napInfo.AddItem("", "Flash Box");
			
			napInfo.ExitButton = true;
			napInfo.Display(param1, MENU_TIME_FOREVER);
		}
	}
}

void PrecacheParticle(char[] sParticle)
{
	int iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{
		DispatchKeyValue(iParticle, "effect_name", sParticle);
		DispatchSpawn(iParticle);
		
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
		
		CreateTimer(0.01, RemoveParticle, iParticle);
	}
}

public Action RemoveParticle(Handle timer, any entity)
{
	if (!IsValidEntity(entity) || !IsValidEdict(entity))
	{
		return Plugin_Stop;
	}
	
	char entClass[64];
	GetEdictClassname(entity, entClass, sizeof(entClass));
	if (StrEqual(entClass, "info_particle_system", false))
	{
		AcceptEntityInput(entity, "Stop");
		DeleteEntity(entity);
	}
	
	return Plugin_Stop;
}

void FillInNAPData(int client)
{
	iLastData[client][0][0] = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	iLastData[client][1][0] = GetEntProp(client, Prop_Send, "m_iHealth");
	iLastData[client][2][0] = RoundToNearest(GetEntPropFloat(client, Prop_Send, "m_healthBuffer"));
	iLastData[client][3][0] = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	iLastData[client][4][0] = GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
	iLastData[client][5][0] = GetEntProp(client, Prop_Send, "m_isGoingToDie");
	
	char sPlayerModel[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", sPlayerModel, sizeof(sPlayerModel));
	strcopy(sLastData[client][0], 128, sPlayerModel);
	
	for (int i = 0; i < 5; i++)
	{
		int iInventory = GetPlayerWeaponSlot(client, i);
		if (!IsValidEnt(iInventory))
		{
			continue;
		}
		
		char sInventoryClass[64];
		GetEdictClassname(iInventory, sInventoryClass, sizeof(sInventoryClass));
		strcopy(sLastData[client][i+1], 64, sInventoryClass);
		
		if (i == 0)
		{
			iLastData[client][0][1] = GetEntProp(iInventory, Prop_Send, "m_iClip1", 4);
			iLastData[client][1][1] = GetWeaponAmmo(iInventory, sInventoryClass);
			iLastData[client][2][1] = GetEntProp(iInventory, Prop_Send, "m_upgradeBitVec", 4);
			iLastData[client][3][1] = GetEntProp(iInventory, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
			iLastData[client][4][1] = GetEntProp(iInventory, Prop_Data, "m_nModelIndex");
			iLastData[client][5][1] = GetEntProp(iInventory, Prop_Data, "m_nViewModelIndex");
		}
	}
}

void RestoreNAPData(int client)
{
	SetEntProp(client, Prop_Send, "m_survivorCharacter", iLastData[client][0][0]);
	SetEntProp(client, Prop_Send, "m_iHealth", iLastData[client][1][0], 1);
	SetEntProp(client, Prop_Send, "m_iMaxHealth", FindConVar("z_survivor_respawn_health").IntValue, 1);
	SDKCall(hNAPSetTempHP, client, float(iLastData[client][2][0]));
	SetEntProp(client, Prop_Send, "m_currentReviveCount", iLastData[client][3][0]);
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", iLastData[client][4][0]);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", iLastData[client][5][0]);
	
	SetEntityModel(client, sLastData[client][0]);
	
	for (int i = 0; i < 5; i++)
	{
		ExecuteCommand(client, "give", sLastData[client][i+1]);
		
		if (i == 0)
		{
			int iPrimary = GetPlayerWeaponSlot(client, 0);
			if (IsValidEnt(iPrimary))
			{
				SetEntProp(iPrimary, Prop_Send, "m_iClip1", iLastData[client][0][1], 4);
				SetWeaponAmmo(client, _, iLastData[client][1][1]);
				SetEntProp(iPrimary, Prop_Send, "m_upgradeBitVec", iLastData[client][2][1], 4);
				SetEntProp(iPrimary, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", iLastData[client][3][1], 4);
				SetEntProp(iPrimary, Prop_Data, "m_nModelIndex", iLastData[client][4][1]);
				SetEntProp(iPrimary, Prop_Data, "m_nViewModelIndex", iLastData[client][5][1]);
			}
		}
	}
	
	UpdateGlow(client, (iLastData[client][4][0] == 1) ? true : false);
	SetSHStats(client, iLastData[client][3][0], iLastData[client][3][0]);
}

void ClearNAPData(int client)
{
	for (int i = 0; i < 6; i++)
	{
		for (int i2 = 0; i2 < 2; i2++)
		{
			iLastData[client][i][i2] = 0;
		}
	}
	
	sAPName[client][0] = '\0';
	for (int i = 0; i < 6; i++)
	{
		sLastData[client][i][0] = '\0';
	}
	
	fTime[0][1] = 0.0;
	fTime[0][7] = 0.0;
	fTime[0][14] = 0.0;
	fTime[0][15] = 0.0;
	
	for (int i = 0; i < 19; i++)
	{
		if (i == 1 || i == 7 || i == 14 || i == 15)
		{
			continue;
		}
		
		fTime[client][i] = 0.0;
	}
	
	if (bFrozen[client])
	{
		bFrozen[client] = false;
		
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColor(client);
		
		ScreenEffects(client, {0, 0, 0, 0}, _, 0);
		
		if (hFreezeTime[client] != null)
		{
			KillTimer(hFreezeTime[client]);
			hFreezeTime[client] = null;
		}
	}
	
	if (bFast[client])
	{
		bFast[client] = false;
		
		SDKCall(hNAPApplyAdrenaline, client, 0.1);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		
		if (hSpeedTime[client] != null)
		{
			KillTimer(hSpeedTime[client]);
			hSpeedTime[client] = null;
		}
	}
	
	if (bImmune[client])
	{
		bImmune[client] = false;
		
		L4D2_SetEntGlow(client, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		
		if (iImmuneType == 1)
		{
			
		}
		
		if (hImmuneTime[client] != null)
		{
			KillTimer(hImmuneTime[client]);
			hImmuneTime[client] = null;
		}
	}
	
	if (bFloating[client])
	{
		bFloating[client] = false;
		SetEntityGravity(client, 1.0);
		
		if (hGravityTime[client] != null)
		{
			KillTimer(hGravityTime[client]);
			hGravityTime[client] = null;
		}
	}
	
	if (bInvisible[client])
	{
		bInvisible[client] = false;
		
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client);
		
		if (iInvisibleType == 1)
		{
			SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 1);
			
			if (bInvisibleDummy && IsValidEnt(iDummy[client]))
			{
				if (bInvisibleDummyGlow)
				{
					L4D2_SetEntGlow(iDummy[client], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
				}
				
				DeleteEntity(iDummy[client]);
				iDummy[client] = 0;
			}
		}
		
		if (hInvisibleTime[client] != null)
		{
			KillTimer(hInvisibleTime[client]);
			hInvisibleTime[client] = null;
		}
	}
	
	if (bJingling[client])
	{
		bJingling[client] = false;
		
		ExtinguishEntity(client);
		StopSound(client, SNDCHAN_AUTO, sNAPSounds[1]);
		
		ExecuteCommand(_, "ent_fire", "nap-l4d2_myparticle KillHierarchy");
		
		if (hJingleTime[client] != null)
		{
			KillTimer(hJingleTime[client]);
			hJingleTime[client] = null;
		}
	}
	
	if (bWatchingMeteors[client])
	{
		bWatchingMeteors[client] = false;
		
		int iMeteorEnt = -1;
		while ((iMeteorEnt = FindEntityByClassname(iMeteorEnt, "tank_rock")) != INVALID_ENT_REFERENCE)
		{
			if (!IsValidEntity(iMeteorEnt) || !IsValidEdict(iMeteorEnt))
			{
				continue;
			}
			
			if (client == GetEntProp(iMeteorEnt, Prop_Send, "m_hOwnerEntity"))
			{
				MeteorFallExplosion(iMeteorEnt, client);
			}
		}
		
		if (hMeteorFallTime[client] != null)
		{
			KillTimer(hMeteorFallTime[client]);
			hMeteorFallTime[client] = null;
		}
	}
	
	if (bDoingFirework[client])
	{
		bDoingFirework[client] = false;
		
		if (hFireworksTime[client] != null)
		{
			KillTimer(hFireworksTime[client]);
			hFireworksTime[client] = null;
		}
	}
	
	if (bHasPet[client])
	{
		bHasPet[client] = false;
		
		if (IsValidEnt(iPetEnt[client]))
		{
			bPetFireInterval[iPetEnt[client]] = false;
			bIsPetFollowing[iPetEnt[client]] = false;
			bIsPetHovering[iPetEnt[client]] = false;
			
			float fPetAngle[3], fPetVelocity[3];
			
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_angRotation", fPetAngle);
			fPetAngle[0] -= 20.0;
			
			GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(fPetVelocity, fPetVelocity);
			ScaleVector(fPetVelocity, 900.0);
			
			TeleportEntity(iPetEnt[client], NULL_VECTOR, NULL_VECTOR, fPetVelocity);
			
			CreateTimer(0.3, RemovePetEntities, iPetEnt[client]);
			CreateTimer(0.3, RemovePetEntities, iPetExtras[iPetEnt[client]][0]);
			CreateTimer(0.3, RemovePetEntities, iPetExtras[iPetEnt[client]][1]);
			
			EmitSoundToClient(client, sNAPSounds[19]);
			
			iPetTarget[iPetEnt[client]] = 0;
			for (int i = 0; i < 2; i++)
			{
				iPetExtras[iPetEnt[client]][i] = 0;
			}
			iPetEnt[client] = 0;
		}
		
		if (hPetTime[client] != null)
		{
			KillTimer(hPetTime[client]);
			hPetTime[client] = null;
		}
	}
	
	if (bHasParachute[client])
	{
		bHasParachute[client] = false;
		bParachuteUseWarned[client] = false;
		
		iParachuteUseWarnTimes[client] = 0;
		iExtraParachute[client] = 0;
		
		if (IsValidEnt(iParachuteEnt[client]))
		{
			bParachuteUsed[iParachuteEnt[client]] = false;
			L4D2_SetEntGlow(iParachuteEnt[client], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
			
			DeleteEntity(iParachuteEnt[client]);
			iParachuteEnt[client] = 0;
		}
	}
	
	if (bHasArmor[client])
	{
		bHasArmor[client] = false;
		if (IsValidEnt(iArmorEnt[client]))
		{
			L4D2_SetEntGlow(iArmorEnt[client], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
			SDKUnhook(iArmorEnt[client], SDKHook_SetTransmit, OnArmorTransmit);
			
			AcceptEntityInput(iArmorEnt[client], "ClearParent");
			DeleteEntity(iArmorEnt[client]);
			
			iArmorEnt[client] = 0;
		}
		
		if (hArmorTime[client] != null)
		{
			KillTimer(hArmorTime[client]);
			hArmorTime[client] = null;
		}
	}
	
	if (bShouting[client])
	{
		bShouting[client] = false;
		
		if (hShoutTime[client] != null)
		{
			KillTimer(hShoutTime[client]);
			hShoutTime[client] = null;
		}
	}
	
	if (bBlinded[client])
	{
		bBlinded[client] = false;
		ScreenEffects(client, {0, 0, 0, 0}, _, 1);
		
		if (hBlindTime[client] != null)
		{
			KillTimer(hBlindTime[client]);
			hBlindTime[client] = null;
		}
	}
	
	if (bWarping[client])
	{
		bWarping[client] = false;
		
		if (hWarpTime[client] != null)
		{
			KillTimer(hWarpTime[client]);
			hWarpTime[client] = null;
		}
	}
	
	if (bDistorted[client])
	{
		bDistorted[client] = false;
		bSoundDistorted[client] = false;
		
		ScreenEffects(client, {0, 0, 0, 0}, _, 2);
		
		float fFixedEyeAng[3];
		GetClientEyeAngles(client, fFixedEyeAng);
		fFixedEyeAng[2] = 0.0;
		
		TeleportEntity(client, NULL_VECTOR, fFixedEyeAng, NULL_VECTOR);
		
		if (hDistortionTime[client] != null)
		{
			KillTimer(hDistortionTime[client]);
			hDistortionTime[client] = null;
		}
	}
	
	if (bFlashed[client])
	{
		bFlashed[client] = false;
		ScreenEffects(client, {0, 0, 0, 0}, _, 3);
		
		if (hFlashTime[client] == null)
		{
			KillTimer(hFlashTime[client]);
			hFlashTime[client] = null;
		}
	}
}

void RemoveOtherEffects()
{
	if (bMatrixApplied)
	{
		bMatrixApplied = false;
		
		if (IsValidEdict(iTimeEnt))
		{
			AcceptEntityInput(iTimeEnt, "Stop");
			DeleteEntity(iTimeEnt);
			
			iTimeEnt = 0;
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) > 1)
			{
				L4D2_SetEntGlow(i, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
			}
		}
		if (hMatrixTime != null)
		{
			KillTimer(hMatrixTime);
			hMatrixTime = null;
		}
	}
	
	if (bRealismApplied)
	{
		bRealismApplied = false;
		FindConVar("sv_disable_glow_survivors").RestoreDefault(true, false);
		
		if (hRealismTime != null)
		{
			KillTimer(hRealismTime);
			hRealismTime = null;
		}
	}
	
	if (bBlurApplied)
	{
		bBlurApplied = false;
		if (IsValidEntRef(iBlurEnt[0]))
		{
			DeleteEntity(iBlurEnt[0]);
			iBlurEnt[0] = 0;
		}
		
		if (IsValidEnt(iBlurEnt[1]))
		{
			DeleteEntity(iBlurEnt[1]);
			iBlurEnt[1] = 0;
		}
		
		if (hBlurTime != null)
		{
			KillTimer(hBlurTime);
			hBlurTime = null;
		}
	}
	
	if (bSnowApplied)
	{
		bSnowApplied = false;
		
		if (IsValidEnt(iSnowEnt))
		{
			DeleteEntity(iSnowEnt);
			iSnowEnt = 0;
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				StopSound(i, SNDCHAN_AUTO, sNAPSounds[24]);
			}
		}
		if (hSnowTime != null)
		{
			KillTimer(hSnowTime);
			hSnowTime = null;
		}
	}
}

void ResetAPStats()
{
	iLastDeployer = 0;
	
	iAmmoPackCount = 0;
	iLastDeployedAP = 0;
	
	for (int i; i < 10; i++)
	{
		iAmmoPackID[i] = -1;
		iAPMaxUses[i] = 0;
		
		for (int j = 1; j <= MaxClients; j++)
		{
			if (IsClientInGame(j) && GetClientTeam(j) == 2)
			{
				bAmmoPackUsed[i][j] = false;
			}
		}
	}
}

int GetWeaponAmmo(int client, char sWeapon[64] = "")
{
	if (sWeapon[0] == '\0')
	{
		int iPrimary = GetPlayerWeaponSlot(client, 0);
		if (!IsValidEnt(iPrimary))
		{
			return 0;
		}
		
		GetEdictClassname(iPrimary, sWeapon, sizeof(sWeapon));
	}
	
	int iWeaponOffset = DetermineWeapon(sWeapon);
	return (iWeaponOffset == 0) ? 0 : GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo") + (iWeaponOffset));
}

void SetWeaponAmmo(int client, char sWeapon[64] = "", int iAmount)
{
	if (sWeapon[0] == '\0')
	{
		int iPrimary = GetPlayerWeaponSlot(client, 0);
		if (!IsValidEnt(iPrimary))
		{
			return;
		}
		
		GetEdictClassname(iPrimary, sWeapon, sizeof(sWeapon));
	}
	
	int iWeaponOffset = DetermineWeapon(sWeapon);
	if (iWeaponOffset == 0)
	{
		return;
	}
	
	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo") + (iWeaponOffset), iAmount);
}

int DetermineWeapon(char sWeapon[64])
{
	if (sWeapon[0] == '\0')
	{
		return 0;
	}
	
	int iRetOffset = 0;
	if (StrEqual(sWeapon, "weapon_rifle", false) || StrEqual(sWeapon, "weapon_rifle_desert", false) || StrEqual(sWeapon, "weapon_rifle_ak47", false) || StrEqual(sWeapon, "weapon_rifle_sg552", false) || StrEqual(sWeapon, "weapon_rifle_m60", false))
	{
		iRetOffset = 12;
	}
	else if (StrEqual(sWeapon, "weapon_smg", false) || StrEqual(sWeapon, "weapon_smg_silenced", false) || StrEqual(sWeapon, "weapon_smg_mp5", false))
	{
		iRetOffset = 20;
	}
	else if (StrEqual(sWeapon, "weapon_pumpshotgun", false) || StrEqual(sWeapon, "weapon_shotgun_chrome", false))
	{
		iRetOffset = 28;
	}
	else if (StrEqual(sWeapon, "weapon_autoshotgun", false) || StrEqual(sWeapon, "weapon_shotgun_spas", false))
	{
		iRetOffset = 32;
	}
	else if (StrEqual(sWeapon, "weapon_hunting_rifle", false))
	{
		iRetOffset = 36;
	}
	else if (StrEqual(sWeapon, "weapon_sniper_military", false) || StrEqual(sWeapon, "weapon_sniper_scout", false) || StrEqual(sWeapon, "weapon_sniper_awp", false))
	{
		iRetOffset = 40;
	}
	else if (StrEqual(sWeapon, "weapon_grenade_launcher", false))
	{
		iRetOffset = 68;
	}
	return iRetOffset;
}

void AmmoPackEffects(int client, int iIndex)
{
	float fPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
	
	switch (iIndex)
	{
		case 1:
		{
			TE_SetupBeamRingPoint(fPos, 10.0, fFreezeRadius, iSprite[0], iSprite[1], 0, 10, 0.3, 10.0, 0.5, {0, 0, 255, 255}, 400, 0);
			TE_SendToAll();
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				{
					float fOtherPos[3];
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOtherPos);
					
					if (GetVectorDistance(fPos, fOtherPos) > fFreezeRadius)
					{
						continue;
					}
					
					if (sNAPSounds[0][0])
					{
						float vec[3];
						GetClientEyePosition(i, vec);
						EmitAmbientSound(sNAPSounds[0], vec, i, SNDLEVEL_RAIDSIREN);
					}
					
					if (!bFrozen[i])
					{
						bFrozen[i] = true;
						
						SetEntityMoveType(i, MOVETYPE_NONE);
						SetEntityRenderColor(i, 0, 0, 255, 180);
						
						ScreenEffects(i, {0, 0, 255, 150}, RoundFloat(FloatMul(fFreezeDuration, 500.0)), 0);
						
						if (hFreezeTime[i] == null)
						{
							fTime[i][0] = fFreezeDuration;
							hFreezeTime[i] = CreateTimer(fTime[i][0], StopFreezeEffect, i);
							
							CreateTimer(0.1, CheckFreezeEffect, i, TIMER_REPEAT);
						}
					}
					else
					{
						fTime[i][0] += fFreezeDuration;
						
						ScreenEffects(i, {0, 0, 255, 150}, _, 0);
						ScreenEffects(i, {0, 0, 255, 150}, RoundFloat(FloatMul(fTime[i][0], 500.0)), 0);
						
						if (hFreezeTime[i] != null)
						{
							KillTimer(hFreezeTime[i]);
							hFreezeTime[i] = null;
						}
						hFreezeTime[i] = CreateTimer(fTime[i][0], StopFreezeEffect, i);
						
						CreateTimer(0.1, CheckFreezeEffect, i, TIMER_REPEAT);
					}
				}
			}
		}
		case 2:
		{
			if (!bMatrixApplied)
			{
				bMatrixApplied = true;
				
				int iTimeScale = CreateEntityByName("func_timescale");
				
				DispatchKeyValue(iTimeScale, "desiredTimescale", "0.2");
				DispatchKeyValue(iTimeScale, "acceleration", "2.0");
				DispatchKeyValue(iTimeScale, "minBlendRate", "1.0");
				DispatchKeyValue(iTimeScale, "blendDeltaMultiplier", "2.0");
				
				DispatchSpawn(iTimeScale);
				AcceptEntityInput(iTimeScale, "Start");
				
				iTimeEnt = iTimeScale;
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && IsPlayerAlive(i))
					{
						if (iMatrixGlow != 3 && GetClientTeam(i) == 2 && i == iLastDeployer)
						{
							L4D2_SetEntGlow(i, L4D2Glow_Constant, 100000, 0, {255, 255, 0}, false);
						}
						
						if ((iMatrixGlow == 2 || iMatrixGlow == 4) && GetClientTeam(i) == 2 && i != iLastDeployer)
						{
							L4D2_SetEntGlow(i, L4D2Glow_Constant, 100000, 0, {0, 0, 255}, false);
						}
						
						if ((iMatrixGlow == 3 || iMatrixGlow == 4) && GetClientTeam(i) == 3)
						{
							L4D2_SetEntGlow(i, L4D2Glow_Constant, 100000, 0, {255, 0, 0}, false);
						}
					}
				}
				if (hMatrixTime == null)
				{
					fTime[0][1] = fMatrixDuration;
					hMatrixTime = CreateTimer(fTime[0][1], StopMatrixEffect, iTimeScale);
					
					CreateTimer(0.1, CheckMatrixEffect, _, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[0][1] += fMatrixDuration;
				
				if (hMatrixTime != null)
				{
					KillTimer(hMatrixTime);
					hMatrixTime = null;
				}
				hMatrixTime = CreateTimer(fTime[0][1], StopMatrixEffect, iTimeEnt);
				
				CreateTimer(0.1, CheckMatrixEffect, _, TIMER_REPEAT);
			}
		}
		case 3:
		{
			if (!bFast[client])
			{
				bFast[client] = true;
				
				SDKCall(hNAPApplyAdrenaline, client, fSpeedDuration);
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", fSpeedIncrease);
				
				if (hSpeedTime[client] == null)
				{
					fTime[client][2] = fSpeedDuration;
					hSpeedTime[client] = CreateTimer(fTime[client][2], StopSpeedEffect, client);
					
					CreateTimer(0.1, CheckSpeedEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][2] += fSpeedDuration;
				
				SDKCall(hNAPApplyAdrenaline, client, 0.1);
				SDKCall(hNAPApplyAdrenaline, client, fTime[client][2]);
				
				if (hSpeedTime[client] != null)
				{
					KillTimer(hSpeedTime[client]);
					hSpeedTime[client] = null;
				}
				hSpeedTime[client] = CreateTimer(fTime[client][2], StopSpeedEffect, client);
				
				CreateTimer(0.1, CheckSpeedEffect, client, TIMER_REPEAT);
			}
		}
		case 4:
		{
			if (!bImmune[client])
			{
				if (bJingling[client])
				{
					bJingling[client] = false;
					PrintToChat(client, "\x03[\x05NAP\x03]\x01 Removing \x04Jingle\x01 Effect!");
					
					ExtinguishEntity(client);
					StopSound(client, SNDCHAN_AUTO, sNAPSounds[1]);
					
					ExecuteCommand(_, "ent_fire", "nap-l4d2_myparticle KillHierarchy");
					
					if (hJingleTime[client] != null)
					{
						KillTimer(hJingleTime[client]);
						hJingleTime[client] = null;
					}
				}
				else if (bHasArmor[client])
				{
					bHasArmor[client] = false;
					PrintToChat(client, "\x03[\x05NAP\x03]\x01 Removing \x04Armor\x01 Effect!");
					
					if (IsValidEnt(iArmorEnt[client]))
					{
						L4D2_SetEntGlow(iArmorEnt[client], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
						SDKUnhook(iArmorEnt[client], SDKHook_SetTransmit, OnArmorTransmit);
						
						AcceptEntityInput(iArmorEnt[client], "ClearParent");
						DeleteEntity(iArmorEnt[client]);
						
						iArmorEnt[client] = 0;
						
						SetEntityRenderMode(client, RENDER_NORMAL);
						SetEntityRenderColor(client);
					}
					
					if (hArmorTime[client] != null)
					{
						KillTimer(hArmorTime[client]);
						hArmorTime[client] = null;
					}
				}
				
				bImmune[client] = true;
				
				L4D2_SetEntGlow(client, L4D2Glow_Constant, 100000, 0, {33, 34, 35}, false);
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				
				if (hImmuneTime[client] == null)
				{
					fTime[client][3] = fImmuneDuration;
					hImmuneTime[client] = CreateTimer(fTime[client][3], StopImmuneEffect, client);
					
					CreateTimer(0.1, CheckImmuneEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][3] += fImmuneDuration;
				
				if (hImmuneTime[client] != null)
				{
					KillTimer(hImmuneTime[client]);
					hImmuneTime[client] = null;
				}
				hImmuneTime[client] = CreateTimer(fTime[client][3], StopImmuneEffect, client);
				
				CreateTimer(0.1, CheckImmuneEffect, client, TIMER_REPEAT);
			}
		}
		case 5:
		{
			switch (iHealType)
			{
				case 1:
				{
					int iCurrentHP = GetEntProp(client, Prop_Send, "m_iHealth");
					SetEntProp(client, Prop_Send, "m_iHealth", iCurrentHP + iHealAmount, 1);
				}
				case 2:
				{
					int iMaximumHP = GetEntProp(client, Prop_Send, "m_iMaxHealth");
					
					SetEntProp(client, Prop_Send, "m_iHealth", iMaximumHP, 1);
					SetEntProp(client, Prop_Send, "m_iMaxHealth", iMaximumHP, 1);
					
					SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
				}
				case 3:
				{
					Call_StartForward(hNAPHBPreForward);
					Call_PushCell(client);
					Call_Finish();
					
					int iMaximumHP = GetEntProp(client, Prop_Send, "m_iMaxHealth");
					
					SetEntProp(client, Prop_Send, "m_iHealth", iMaximumHP, 1);
					SetEntProp(client, Prop_Send, "m_iMaxHealth", iMaximumHP, 1);
					
					SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
					
					Call_StartForward(hNAPHBForward);
					Call_PushCell(client);
					Call_Finish();
					
					SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
					SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
					SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
					
					Call_StartForward(hNAPHBPostForward);
					Call_PushCell(client);
					Call_Finish();
					
					if (BAWN_CVAR != null)
					{
						SetEntProp(client, Prop_Send, "m_iGlowType", 0);
						SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
					}
				}
			}
		}
		case 6:
		{
			switch (iGravityType)
			{
				case 0:
				{
					if (!bFloating[client])
					{
						bFloating[client] = true;
						SetEntityGravity(client, fGravityAmount);
						
						if (hGravityTime[client] == null)
						{
							fTime[client][4] = fGravityDuration;
							hGravityTime[client] = CreateTimer(fTime[client][4], StopGravityEffect, client);
							
							CreateTimer(0.1, CheckGravityEffect, client, TIMER_REPEAT);
						}
					}
					else
					{
						fTime[client][4] += fGravityDuration;
						
						if (hGravityTime[client] != null)
						{
							KillTimer(hGravityTime[client]);
							hGravityTime[client] = null;
						}
						hGravityTime[client] = CreateTimer(fTime[client][4], StopGravityEffect, client);
						
						CreateTimer(0.1, CheckGravityEffect, client, TIMER_REPEAT);
					}
				}
				case 1:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && IsPlayerAlive(i))
						{
							if (!bFloating[i])
							{
								bFloating[i] = true;
								SetEntityGravity(i, fGravityAmount);
								
								if (hGravityTime[i] == null)
								{
									fTime[i][4] = fGravityDuration;
									hGravityTime[i] = CreateTimer(fTime[i][4], StopGravityEffect, i);
									
									CreateTimer(0.1, CheckGravityEffect, i, TIMER_REPEAT);
								}
							}
							else
							{
								fTime[i][4] += fGravityDuration;
								
								if (hGravityTime[i] != null)
								{
									KillTimer(hGravityTime[i]);
									hGravityTime[i] = null;
								}
								hGravityTime[i] = CreateTimer(fTime[i][4], StopGravityEffect, i);
								
								CreateTimer(0.1, CheckGravityEffect, i, TIMER_REPEAT);
							}
						}
					}
				}
			}
		}
		case 7:
		{
			if (!bInvisible[client])
			{
				bInvisible[client] = true;
				
				SetEntityRenderMode(client, RENDER_TRANSALPHA);
				SetEntityRenderColor(client, 255, 255, 255, 0);
				
				if (iInvisibleType == 1)
				{
					SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 0);
					
					if (bInvisibleDummy && !IsValidEnt(iDummy[client]))
					{
						float fDummyPos[3], fDummyAng[3];
						
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", fDummyPos);
						GetEntPropVector(client, Prop_Send, "m_angRotation", fDummyAng);
						
						char sDummyModel[128];
						GetEntPropString(client, Prop_Data, "m_ModelName", sDummyModel, sizeof(sDummyModel));
						
						int dummy = CreateEntityByName("prop_dynamic_override");
						DispatchKeyValue(dummy, "model", sDummyModel);
						
						TeleportEntity(dummy, fDummyPos, fDummyAng, NULL_VECTOR);
						DispatchSpawn(dummy);
						
						int iSequence = GetEntProp(client, Prop_Send, "m_nSequence");
						SetEntProp(dummy, Prop_Send, "m_nSequence", iSequence);
						
						SetEntProp(dummy, Prop_Send, "m_nMinGPULevel", 1);
						SetEntProp(dummy, Prop_Send, "m_nMaxGPULevel", 1);
						
						SetEntPropFloat(dummy, Prop_Send, "m_fadeMinDist", 10000.0);
						SetEntPropFloat(dummy, Prop_Send, "m_fadeMaxDist", 20000.0);
						
						if (bInvisibleDummyGlow)
						{
							int iHP = GetEntProp(client, Prop_Send, "m_iHealth"),
								iMaxHP = GetEntProp(client, Prop_Send, "m_iMaxHealth");
							
							if (iHP > iMaxHP * 0.6 && iHP <= iMaxHP)
							{
								L4D2_SetEntGlow(dummy, L4D2Glow_Constant, 20000, 0, {0, 180, 0}, false);
							}
							else if (iHP <= iMaxHP * 0.6 && iHP > iMaxHP * 0.3)
							{
								L4D2_SetEntGlow(dummy, L4D2Glow_Constant, 20000, 0, {90, 90, 0}, false);
							}
							else if ((iHP > 0 && iHP <= iMaxHP * 0.3) || GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
							{
								L4D2_SetEntGlow(dummy, L4D2Glow_Constant, 20000, 0, {180, 0, 0}, false);
							}
						}
						
						iDummy[client] = dummy;
					}
				}
				
				if (hInvisibleTime[client] == null)
				{
					fTime[client][5] = fInvisibleDuration;
					hInvisibleTime[client] = CreateTimer(fTime[client][5], StopInvisibleEffect, client);
					
					CreateTimer(0.1, CheckInvisibleEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][5] += fInvisibleDuration;
				
				if (hInvisibleTime[client] != null)
				{
					KillTimer(hInvisibleTime[client]);
					hInvisibleTime[client] = null;
				}
				hInvisibleTime[client] = CreateTimer(fTime[client][5], StopInvisibleEffect, client);
				
				CreateTimer(0.1, CheckInvisibleEffect, client, TIMER_REPEAT);
			}
		}
		case 8:
		{
			fPos[2] += 20.0;
			
			TE_SetupBeamRingPoint(fPos, 30.0, 50.0, iSprite[0], iSprite[1], 0, 10, 7.5, 10.0, 0.5, {255, 0, 255, 255}, 1, 0);
			TE_SendToAll();
			
			float ammoVel[3];
			
			ammoVel[0] = GetRandomFloat(-80.0, 80.0);
			ammoVel[1] = GetRandomFloat(-80.0, 80.0);
			ammoVel[2] = GetRandomFloat(40.0, 80.0);
			
			char sAmmoName[64];
			for (int i = 0; i < 4; i++)
			{
				if (i < 2)
				{
					strcopy(sAmmoName, sizeof(sAmmoName), "weapon_upgradepack_incendiary_spawn");
				}
				else
				{
					strcopy(sAmmoName, sizeof(sAmmoName), "weapon_upgradepack_explosive_spawn");
				}
				
				int ammoEnt = CreateEntityByName(sAmmoName);
				if (ammoEnt != -1)
				{
					DispatchKeyValueVector(ammoEnt, "origin", fPos);
					DispatchKeyValue(ammoEnt, "spawnflags", "1");
					
					DispatchKeyValue(ammoEnt, "solid", "6");
					
					TeleportEntity(ammoEnt, fPos, NULL_VECTOR, ammoVel);
					DispatchSpawn(ammoEnt);
					ActivateEntity(ammoEnt);
				}
			}
		}
		case 9:
		{
			fPos[2] += 20.0;
			
			TE_SetupBeamRingPoint(fPos, 80.0, 100.0, iSprite[0], iSprite[1], 0, 10, 7.5, 10.0, 0.5, {0, 255, 255, 255}, 1, 0);
			TE_SendToAll();
			
			float weaponVel[3];
			
			weaponVel[0] = GetRandomFloat(-80.0, 80.0);
			weaponVel[1] = GetRandomFloat(-80.0, 80.0);
			weaponVel[2] = GetRandomFloat(40.0, 80.0);
			
			char sWeaponName[64];
			
			int randTier = GetRandomInt(1, 3);
			switch (randTier)
			{
				case 1:
				{
					for (int i = 0; i < 2; i++)
					{
						if (i == 0)
						{
							strcopy(sWeaponName, sizeof(sWeaponName), "weapon_rifle_m60");
						}
						else
						{
							strcopy(sWeaponName, sizeof(sWeaponName), "weapon_grenade_launcher");
						}
						
						int weaponEnt = CreateEntityByName(sWeaponName);
						if (weaponEnt != -1)
						{
							TeleportEntity(weaponEnt, fPos, NULL_VECTOR, weaponVel);
							DispatchSpawn(weaponEnt);
							ActivateEntity(weaponEnt);
						}
					}
				}
				case 2:
				{
					for (int i = 0; i < 5; i++)
					{
						if (i == 0)
						{
							strcopy(sWeaponName, sizeof(sWeaponName), "weapon_smg");
						}
						else if (i == 1)
						{
							strcopy(sWeaponName, sizeof(sWeaponName), "weapon_smg_silenced");
						}
						else if (i == 2)
						{
							strcopy(sWeaponName, sizeof(sWeaponName), "weapon_smg_mp5");
						}
						else if (i == 3)
						{
							strcopy(sWeaponName, sizeof(sWeaponName), "weapon_pumpshotgun");
						}
						else
						{
							strcopy(sWeaponName, sizeof(sWeaponName), "weapon_shotgun_chrome");
						}
						
						int weaponEnt = CreateEntityByName(sWeaponName);
						if (weaponEnt != -1)
						{
							TeleportEntity(weaponEnt, fPos, NULL_VECTOR, weaponVel);
							DispatchSpawn(weaponEnt);
							ActivateEntity(weaponEnt);
						}
					}
				}
				case 3:
				{
					int randSet = GetRandomInt(0, 2);
					switch (randSet)
					{
						case 0:
						{
							for (int i = 0; i < 4; i++)
							{
								if (i == 0)
								{
									strcopy(sWeaponName, sizeof(sWeaponName), "weapon_hunting_rifle");
								}
								else if (i == 1)
								{
									strcopy(sWeaponName, sizeof(sWeaponName), "weapon_sniper_military");
								}
								else if (i == 2)
								{
									strcopy(sWeaponName, sizeof(sWeaponName), "weapon_sniper_scout");
								}
								else
								{
									strcopy(sWeaponName, sizeof(sWeaponName), "weapon_sniper_awp");
								}
								
								int weaponEnt = CreateEntityByName(sWeaponName);
								if (weaponEnt != -1)
								{
									TeleportEntity(weaponEnt, fPos, NULL_VECTOR, weaponVel);
									DispatchSpawn(weaponEnt);
									ActivateEntity(weaponEnt);
								}
							}
						}
						case 1:
						{
							for (int i = 0; i < 4; i++)
							{
								if (i == 0)
								{
									strcopy(sWeaponName, sizeof(sWeaponName), "weapon_rifle");
								}
								else if (i == 1)
								{
									strcopy(sWeaponName, sizeof(sWeaponName), "weapon_rifle_ak47");
								}
								else if (i == 2)
								{
									strcopy(sWeaponName, sizeof(sWeaponName), "weapon_rifle_desert");
								}
								else
								{
									strcopy(sWeaponName, sizeof(sWeaponName), "weapon_rifle_sg552");
								}
								
								int weaponEnt = CreateEntityByName(sWeaponName);
								if (weaponEnt != -1)
								{
									TeleportEntity(weaponEnt, fPos, NULL_VECTOR, weaponVel);
									DispatchSpawn(weaponEnt);
									ActivateEntity(weaponEnt);
								}
							}
						}
						case 2:
						{
							for (int i = 0; i < 2; i++)
							{
								if (i == 0)
								{
									strcopy(sWeaponName, sizeof(sWeaponName), "weapon_autoshotgun");
								}
								else
								{
									strcopy(sWeaponName, sizeof(sWeaponName), "weapon_shotgun_spas");
								}
								
								int weaponEnt = CreateEntityByName(sWeaponName);
								if (weaponEnt != -1)
								{
									TeleportEntity(weaponEnt, fPos, NULL_VECTOR, weaponVel);
									DispatchSpawn(weaponEnt);
									ActivateEntity(weaponEnt);
								}
							}
						}
					}
				}
			}
		}
		case 10:
		{
			if (!bJingling[client])
			{
				if (bImmune[client])
				{
					bImmune[client] = false;
					
					L4D2_SetEntGlow(client, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
					SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
					
					PrintToChat(client, "\x03[\x05NAP\x03]\x01 Removing \x04Immune\x01 Effect!");
					
					if (hImmuneTime[client] != null)
					{
						KillTimer(hImmuneTime[client]);
						hImmuneTime[client] = null;
					}
				}
				else if (bHasArmor[client])
				{
					bHasArmor[client] = false;
					PrintToChat(client, "\x03[\x05NAP\x03]\x01 Removing \x04Armor\x01 Effect!");
					
					if (IsValidEnt(iArmorEnt[client]))
					{
						L4D2_SetEntGlow(iArmorEnt[client], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
						SDKUnhook(iArmorEnt[client], SDKHook_SetTransmit, OnArmorTransmit);
						
						AcceptEntityInput(iArmorEnt[client], "ClearParent");
						DeleteEntity(iArmorEnt[client]);
						
						iArmorEnt[client] = 0;
						
						SetEntityRenderMode(client, RENDER_NORMAL);
						SetEntityRenderColor(client);
					}
					
					if (hArmorTime[client] != null)
					{
						KillTimer(hArmorTime[client]);
						hArmorTime[client] = null;
					}
				}
				
				SetEntProp(client, Prop_Send, "m_iHealth", 1, 1);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
				
				int iPointHurt = CreateEntityByName("point_hurt");
				
				DispatchKeyValue(client, "targetname", "hurtme");
				DispatchKeyValue(iPointHurt, "DamageTarget", "hurtme");
				DispatchKeyValue(iPointHurt, "Damage", "1");
				DispatchKeyValue(iPointHurt, "DamageType", "65536");
				
				DispatchSpawn(iPointHurt);
				
				AcceptEntityInput(iPointHurt, "Hurt", 0);
				DeleteEntity(iPointHurt);
				
				DispatchKeyValue(client, "targetname", "donthurtme");
				
				bJingling[client] = true;
				
				IgniteEntity(client, fJingleDuration);
				EmitSoundToAll(sNAPSounds[1], client);
				
				AttachParticle(client, sNAPParticles[0], fJingleDuration);
				if (hJingleTime[client] == null)
				{
					fTime[client][6] = fJingleDuration;
					hJingleTime[client] = CreateTimer(fTime[client][6], StopJingleEffect, client);
					
					CreateTimer(0.1, CheckJingleEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				ExtinguishEntity(client);
				
				StopSound(client, SNDCHAN_AUTO, sNAPSounds[1]);
				EmitSoundToAll(sNAPSounds[1], client);
				
				ExecuteCommand(_, "ent_fire", "nap-l4d2_myparticle KillHierarchy");
				
				fTime[client][6] += fJingleDuration;
				
				AttachParticle(client, sNAPParticles[0], fTime[client][6]);
				IgniteEntity(client, fTime[client][6]);
				
				if (hJingleTime[client] != null)
				{
					KillTimer(hJingleTime[client]);
					hJingleTime[client] = null;
				}
				hJingleTime[client] = CreateTimer(fTime[client][6], StopJingleEffect, client);
				
				CreateTimer(0.1, CheckJingleEffect, client, TIMER_REPEAT);
			}
		}
		case 11:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) > 1 && IsPlayerAlive(i))
				{
					float fOtherPos[3];
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOtherPos);
					
					if (GetVectorDistance(fPos, fOtherPos) > fBileRadius)
					{
						continue;
					}
					
					if (GetClientTeam(i) == 2)
					{
						SDKCall(hNAPBileSurvivor, i, client, true);
					}
					else if (GetClientTeam(i) == 3 && bBileSpecial)
					{
						SDKCall(hNAPBileInfected, i, client, true);
					}
				}
			}
			
			for (int i = 1; i <= GetMaxEntities(); i++)
			{
				if (!IsValidEntity(i) || !IsValidEdict(i))
				{
					continue;
				}
				
				char sClassname[64];
				GetEdictClassname(i, sClassname, sizeof(sClassname));
				if ((StrEqual(sClassname, "infected") && bBileCommon) || (StrEqual(sClassname, "witch") && bBileWitch))
				{
					float fNPCPos[3];
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fNPCPos);
					
					if (GetVectorDistance(fPos, fNPCPos) > fBileRadius)
					{
						continue;
					}
					
					SDKCall(hNAPBileCommon, i, client, true);
				}
			}
		}
		case 12:
		{
			for (int i = 0; i < iMobCount; i++)
			{
				int iDirector = CreateEntityByName("info_director");
				DispatchSpawn(iDirector);
				
				AcceptEntityInput(iDirector, "ForcePanicEvent");
				DeleteEntity(iDirector);
			}
		}
		case 13:
		{
			int flame = CreateEntityByName("prop_physics");
			DispatchKeyValue(flame, "model", "models/props_junk/gascan001a.mdl");
			DispatchSpawn(flame);
			
			SetEntProp(flame, Prop_Send, "m_CollisionGroup", 1, 1);
			
			TeleportEntity(flame, fPos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(flame, "Break");
			RemoveEdict(flame);
		}
		case 14:
		{
			int sparkle = CreateEntityByName("prop_physics");
			DispatchKeyValue(sparkle, "model", "models/props_junk/explosive_box001.mdl");
			DispatchSpawn(sparkle);
			
			SetEntProp(sparkle, Prop_Send, "m_CollisionGroup", 1, 1);
			
			TeleportEntity(sparkle, fPos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(sparkle, "Break");
			RemoveEdict(sparkle);
		}
		case 15:
		{
			fPos[2] += 20.0;
			
			TE_SetupBeamRingPoint(fPos, 85.0, 100.0, iSprite[0], iSprite[1], 0, 10, 7.5, 10.0, 0.5, {255, 255, 0, 255}, 1, 0);
			TE_SendToAll();
			
			float itemVel[3];
			
			itemVel[0] = GetRandomFloat(-80.0, 80.0);
			itemVel[1] = GetRandomFloat(-80.0, 80.0);
			itemVel[2] = GetRandomFloat(40.0, 80.0);
			
			char sItemName[64];
			
			int randItemSet = GetRandomInt(0, 1);
			switch (randItemSet)
			{
				case 0:
				{
					for (int i = 1; i < 4; i++)
					{
						if (i == 3)
						{
							strcopy(sItemName, sizeof(sItemName), "weapon_molotov");
						}
						else if (i == 2)
						{
							strcopy(sItemName, sizeof(sItemName), "weapon_pipe_bomb");
						}
						else
						{
							strcopy(sItemName, sizeof(sItemName), "weapon_vomitjar");
						}
						
						int itemEnt = CreateEntityByName(sItemName);
						if (itemEnt != -1)
						{
							TeleportEntity(itemEnt, fPos, NULL_VECTOR, itemVel);
							DispatchSpawn(itemEnt);
							ActivateEntity(itemEnt);
						}
					}
				}
				case 1:
				{
					for (int i = 1; i < 5; i++)
					{
						if (i == 4)
						{
							strcopy(sItemName, sizeof(sItemName), "weapon_first_aid_kit");
						}
						else if (i == 3)
						{
							strcopy(sItemName, sizeof(sItemName), "weapon_defibrillator");
						}
						else if (i == 2)
						{
							strcopy(sItemName, sizeof(sItemName), "weapon_pain_pills");
						}
						else
						{
							strcopy(sItemName, sizeof(sItemName), "weapon_adrenaline");
						}
						
						int itemEnt = CreateEntityByName(sItemName);
						if (itemEnt != -1)
						{
							TeleportEntity(itemEnt, fPos, NULL_VECTOR, itemVel);
							DispatchSpawn(itemEnt);
							ActivateEntity(itemEnt);
						}
					}
				}
			}
		}
		case 16:
		{
			if (!bRealismApplied)
			{
				bRealismApplied = true;
				FindConVar("sv_disable_glow_survivors").SetInt(1, true, false);
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					{
						if (bImmune[i])
						{
							bImmune[i] = false;
							
							L4D2_SetEntGlow(i, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
							SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
							
							PrintToChat(i, "\x03[\x05NAP\x03]\x01 Removing \x04Immune\x01 Effect!");
							
							if (hImmuneTime[i] != null)
							{
								KillTimer(hImmuneTime[i]);
								hImmuneTime[i] = null;
							}
						}
						else if (bJingling[i])
						{
							bJingling[i] = false;
							PrintToChat(i, "\x03[\x05NAP\x03]\x01 Removing \x04Jingle\x01 Effect!");
							
							ExtinguishEntity(i);
							StopSound(i, SNDCHAN_AUTO, sNAPSounds[1]);
							
							ExecuteCommand(_, "ent_fire", "nap-l4d2_myparticle KillHierarchy");
							
							if (hJingleTime[i] != null)
							{
								KillTimer(hJingleTime[i]);
								hJingleTime[i] = null;
							}
						}
						else if (bHasArmor[i])
						{
							bHasArmor[i] = false;
							PrintToChat(i, "\x03[\x05NAP\x03]\x01 Removing \x04Armor\x01 Effect!");
							
							if (IsValidEnt(iArmorEnt[i]))
							{
								L4D2_SetEntGlow(iArmorEnt[i], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
								SDKUnhook(iArmorEnt[i], SDKHook_SetTransmit, OnArmorTransmit);
								
								AcceptEntityInput(iArmorEnt[i], "ClearParent");
								DeleteEntity(iArmorEnt[i]);
								
								iArmorEnt[i] = 0;
								
								SetEntityRenderMode(i, RENDER_NORMAL);
								SetEntityRenderColor(i);
							}
							
							if (hArmorTime[i] != null)
							{
								KillTimer(hArmorTime[i]);
								hArmorTime[i] = null;
							}
						}
					}
				}
				if (hRealismTime == null)
				{
					fTime[0][7] = fRealismDuration;
					hRealismTime = CreateTimer(fTime[0][7], StopRealismEffect);
					
					CreateTimer(0.1, CheckRealismEffect, _, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[0][7] += fRealismDuration;
				
				if (hRealismTime != null)
				{
					KillTimer(hRealismTime);
					hRealismTime = null;
				}
				hRealismTime = CreateTimer(fTime[0][7], StopRealismEffect);
				
				CreateTimer(0.1, CheckRealismEffect, _, TIMER_REPEAT);
			}
		}
		case 17:
		{
			fPos[2] += 16.0;
			
			int iSpitEnt = CreateEntityByName("spitter_projectile");
			if (IsValidEntity(iSpitEnt))
			{
				TeleportEntity(iSpitEnt, fPos, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(iSpitEnt);
				
				SetEntPropFloat(iSpitEnt, Prop_Send, "m_DmgRadius", 1024.0);
				SetEntProp(iSpitEnt, Prop_Send, "m_bIsLive", 1);
				SetEntPropEnt(iSpitEnt, Prop_Send, "m_hThrower", client);
				
				SDKCall(hNAPDetonateSpit, iSpitEnt);
			}
		}
		case 18:
		{
			DataPack dpMeteorFall = new DataPack();
			dpMeteorFall.WriteCell(GetClientUserId(client));
			dpMeteorFall.WriteFloat(fPos[0]);
			dpMeteorFall.WriteFloat(fPos[1]);
			dpMeteorFall.WriteFloat(fPos[2]);
			CreateTimer(0.5, DoMeteorFall, dpMeteorFall, TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
			
			if (!bWatchingMeteors[client])
			{
				bWatchingMeteors[client] = true;
				
				if (hMeteorFallTime[client] == null)
				{
					fTime[client][8] = fMeteorFallDuration;
					hMeteorFallTime[client] = CreateTimer(fTime[client][8], StopMeteorFallEffect, client);
					
					CreateTimer(0.1, CheckMeteorFallEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][8] += fMeteorFallDuration;
				
				if (hMeteorFallTime[client] != null)
				{
					KillTimer(hMeteorFallTime[client]);
					hMeteorFallTime[client] = null;
				}
				hMeteorFallTime[client] = CreateTimer(fTime[client][8], StopMeteorFallEffect, client);
				
				CreateTimer(0.1, CheckMeteorFallEffect, client, TIMER_REPEAT);
			}
		}
		case 19:
		{
			int iDistractEnt = CreateEntityByName("info_goal_infected_chase");
			
			fPos[2] += 2.0;
			
			TeleportEntity(iDistractEnt, fPos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(iDistractEnt);
			
			char sTemp[42];
			Format(sTemp, sizeof(sTemp), "OnUser1 !self:kill::%i:1", RoundToNearest(fFireworksDuration));
			SetVariantString(sTemp);
			
			AcceptEntityInput(iDistractEnt, "AddOutput");
			AcceptEntityInput(iDistractEnt, "FireUser1");
			AcceptEntityInput(iDistractEnt, "Enable");
			
			fPos[2] -= 2.0;
			
			DataPack dpFireworks = new DataPack();
			dpFireworks.WriteCell(GetClientUserId(client));
			dpFireworks.WriteFloat(fPos[0]);
			dpFireworks.WriteFloat(fPos[1]);
			dpFireworks.WriteFloat(fPos[2]);
			CreateTimer(2.0, MakeFireworks, dpFireworks, TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
			
			if (!bDoingFirework[client])
			{
				bDoingFirework[client] = true;
				
				if (hFireworksTime[client] == null)
				{
					fTime[client][9] = fFireworksDuration;
					hFireworksTime[client] = CreateTimer(fTime[client][9], StopFireworksEffect, client);
					
					CreateTimer(0.1, CheckFireworksEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][9] += fFireworksDuration;
				
				if (hFireworksTime[client] != null)
				{
					KillTimer(hFireworksTime[client]);
					hFireworksTime[client] = null;
				}
				hFireworksTime[client] = CreateTimer(fTime[client][9], StopFireworksEffect, client);
				
				CreateTimer(0.1, CheckFireworksEffect, client, TIMER_REPEAT);
			}
		}
		case 20:
		{
			char sExplodeRadius[256], sExplodePower[256];
			
			IntToString(450, sExplodeRadius, sizeof(sExplodeRadius));
			IntToString(450, sExplodePower, sizeof(sExplodePower));
			
			for (int i = 0; i < 4; i++)
			{
				ShowParticle(fPos, NULL_VECTOR, sNAPParticles[i+5], 19.0);
			}
			
			int iExplosionEnt = CreateEntityByName("env_explosion");
			DispatchKeyValue(iExplosionEnt, "fireballsprite", "materials/sprites/muzzleflash4.vmt");
			DispatchKeyValue(iExplosionEnt, "iMagnitude", sExplodePower);
			DispatchKeyValue(iExplosionEnt, "iRadiusOverride", sExplodeRadius);
			DispatchKeyValue(iExplosionEnt, "spawnflags", "828");
			
			TeleportEntity(iExplosionEnt, fPos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(iExplosionEnt);
			
			AcceptEntityInput(iExplosionEnt, "Explode");
			
			int iPhysExplosionEnt = CreateEntityByName("env_physexplosion");
			DispatchKeyValue(iPhysExplosionEnt, "radius", sExplodeRadius);
			DispatchKeyValue(iPhysExplosionEnt, "magnitude", sExplodePower);
			
			TeleportEntity(iPhysExplosionEnt, fPos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(iPhysExplosionEnt);
			
			AcceptEntityInput(iPhysExplosionEnt, "Explode");
			
			int iHurtEnt = CreateEntityByName("point_hurt");
			DispatchKeyValue(iHurtEnt, "DamageRadius", sExplodeRadius);
			DispatchKeyValue(iHurtEnt, "DamageDelay", "0.5");
			DispatchKeyValue(iHurtEnt, "Damage", "50");
			DispatchKeyValue(iHurtEnt, "DamageType", "8");
			
			TeleportEntity(iHurtEnt, fPos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(iHurtEnt);
			
			AcceptEntityInput(iHurtEnt, "TurnOn");
			CreateTimer(17.5, DisablePointHurt, iHurtEnt);
			
			EmitSoundToAll(sNAPSounds[GetRandomInt(12, 14)]);
			EmitSoundToAll(sNAPSounds[15]);
			
			DataPack dpExplosion = new DataPack();
			dpExplosion.WriteCell(iExplosionEnt);
			dpExplosion.WriteCell(iPhysExplosionEnt);
			dpExplosion.WriteCell(iHurtEnt);
			CreateTimer(19.0, RemoveExplosion, dpExplosion, TIMER_DATA_HNDL_CLOSE);
			
			float fOtherPos[3], fTraceVector[3], fKnockForce[3], fVelocity[3];
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOtherPos);
					
					if (GetVectorDistance(fPos, fOtherPos) <= 450.0)
					{
						MakeVectorFromPoints(fPos, fOtherPos, fTraceVector);
						GetVectorAngles(fTraceVector, fKnockForce);
						
						fKnockForce[0] = Cosine(DegToRad(fKnockForce[1])) * 450.0;
						fKnockForce[1] = Sine(DegToRad(fKnockForce[1])) * 450.0;
						fKnockForce[2] = 450.0;
						
						GetEntPropVector(i, Prop_Data, "m_vecVelocity", fVelocity);
						
						fKnockForce[0] += fVelocity[0];
						fKnockForce[1] += fVelocity[1];
						fKnockForce[2] += fVelocity[2];
						
						SDKCall(hNAPFlingPlayer, i, fKnockForce, 76, client, 3.0);
					}
				}
			}
		}
		case 21:
		{
			float fHealth = float(GetEntProp(client, Prop_Send, "m_iHealth")),
				fTempHealth = GetPlayerTemporaryHP(client), fTotalHealth = fHealth + fTempHealth;
			
			SetEntProp(client, Prop_Send, "m_iHealth", 1, 1);
			SDKCall(hNAPSetTempHP, client, fTotalHealth);
		}
		case 22:
		{
			if (!bHasPet[client])
			{
				bHasPet[client] = true;
				
				fPos[2] += 3000.0;
				
				float fPetAngle[3];
				GetEntPropVector(client, Prop_Send, "m_angRotation", fPetAngle);
				
				int iPetBody = CreateEntityByName("molotov_projectile");
				if (iPetBody != -1)
				{
					DispatchKeyValueVector(iPetBody, "origin", fPos);
					DispatchKeyValueVector(iPetBody, "angles", fPetAngle);
					
					DispatchKeyValue(iPetBody, "model", sNAPModels[0]);
					DispatchSpawn(iPetBody);
					
					SetEntProp(iPetBody, Prop_Send, "m_hOwnerEntity", client);
					
					SetEntPropFloat(iPetBody, Prop_Send, "m_flModelScale", 0.001);
					SetEntityGravity(iPetBody, 0.01);
				}
				
				fPos[2] -= 3000.0;
				
				float fSteamOrigin[3], fSteamAngle[3];
				
				fSteamOrigin[0] = -7.0; fSteamOrigin[1] = 0.0; fSteamOrigin[2] = -3000.0;
				fSteamAngle[0] = 0.0; fSteamAngle[1] = 180.0; fSteamAngle[2] = 0.0;
				
				int iPetSteam = CreateEntityByName("env_steam");
				if (iPetSteam != -1)
				{
					DispatchKeyValueVector(iPetSteam, "origin", fPos);
					DispatchKeyValueVector(iPetSteam, "angles", fPetAngle);
					
					DispatchKeyValue(iPetSteam, "spawnflags", "1");
					DispatchKeyValue(iPetSteam, "Type", "0");
					DispatchKeyValue(iPetSteam, "InitialState", "1");
					DispatchKeyValue(iPetSteam, "Spreadspeed", "10");
					DispatchKeyValue(iPetSteam, "Speed", "200");
					DispatchKeyValue(iPetSteam, "Startsize", "5");
					DispatchKeyValue(iPetSteam, "EndSize", "30");
					DispatchKeyValue(iPetSteam, "Rate", "555");
					DispatchKeyValue(iPetSteam, "RenderColor", "60 80 200");
					DispatchKeyValue(iPetSteam, "JetLength", "20.0"); 
					DispatchKeyValue(iPetSteam, "RenderAmt", "180");
					
					SetVariantString("!activator");
					AcceptEntityInput(iPetSteam, "SetParent", iPetBody, iPetSteam);
					
					TeleportEntity(iPetSteam, fSteamOrigin, fSteamAngle, NULL_VECTOR);
					DispatchSpawn(iPetSteam);
					
					AcceptEntityInput(iPetSteam, "TurnOn");
				}
				
				float fAttachmentPos[3], fAttachmentAngle[3];
				
				fAttachmentPos[0] = 0.0; fAttachmentPos[1] = 0.0; fAttachmentPos[2] = -3000.0;
				fAttachmentAngle[0] = 0.0; fAttachmentAngle[1] = 0.0; fAttachmentAngle[2] = 0.0;
				
				int iPetAttachment = CreateEntityByName("prop_dynamic_override");
				if (iPetAttachment != -1)
				{
					DispatchKeyValueVector(iPetAttachment, "origin", fPos);
					DispatchKeyValueVector(iPetAttachment, "angles", fPetAngle);
					
					DispatchKeyValue(iPetAttachment, "model", sNAPModels[1]);
					
					SetVariantString("!activator");
					AcceptEntityInput(iPetAttachment, "SetParent", iPetBody, iPetAttachment);
					
					TeleportEntity(iPetAttachment, fAttachmentPos, fAttachmentAngle, NULL_VECTOR);
					DispatchSpawn(iPetAttachment);
					
					SetEntProp(iPetAttachment, Prop_Send, "m_nMinGPULevel", 1);
					SetEntProp(iPetAttachment, Prop_Send, "m_nMaxGPULevel", 1);
					
					SetEntPropFloat(iPetAttachment, Prop_Send, "m_flModelScale", 1.0);
				}
				
				fPos[2] += 3005.0;
				TeleportEntity(iPetBody, fPos, NULL_VECTOR, NULL_VECTOR);
				
				iPetEnt[client] = iPetBody;
				iPetExtras[iPetEnt[client]][0] = iPetAttachment;
				iPetExtras[iPetEnt[client]][1] = iPetSteam;
				
				EmitSoundToClient(client, sNAPSounds[GetRandomInt(16, 18)]);
				
				CreateTimer(0.2, DoPetScan, client, TIMER_REPEAT);
				if (hPetTime[client] == null)
				{
					fTime[client][10] = fPetDuration;
					hPetTime[client] = CreateTimer(fTime[client][10], StopPetEffect, client);
					
					CreateTimer(0.1, CheckPetEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][10] += fPetDuration;
				
				if (hPetTime[client] != null)
				{
					KillTimer(hPetTime[client]);
					hPetTime[client] = null;
				}
				hPetTime[client] = CreateTimer(fTime[client][10], StopPetEffect, client);
				
				CreateTimer(0.1, CheckPetEffect, client, TIMER_REPEAT);
			}
		}
		case 23:
		{
			if (!bHasParachute[client])
			{
				bHasParachute[client] = true;
				ProvideParachute(client);
				
				iExtraParachute[client] = 0;
			}
			else
			{
				iExtraParachute[client] += 1;
				PrintToChat(client, "\x03[\x05NAP\x03]\x01 You've Obtained Extra \x04Parachute\x01!");
			}
		}
		case 24:
		{
			if (!bHasArmor[client])
			{
				if (bImmune[client])
				{
					bImmune[client] = false;
					
					L4D2_SetEntGlow(client, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
					SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
					
					PrintToChat(client, "\x03[\x05NAP\x03]\x01 Removing \x04Immune\x01 Effect!");
					
					if (hImmuneTime[client] != null)
					{
						KillTimer(hImmuneTime[client]);
						hImmuneTime[client] = null;
					}
				}
				else if (bJingling[client])
				{
					bJingling[client] = false;
					PrintToChat(client, "\x03[\x05NAP\x03]\x01 Removing \x04Jingle\x01 Effect!");
					
					ExtinguishEntity(client);
					StopSound(client, SNDCHAN_AUTO, sNAPSounds[1]);
					
					ExecuteCommand(_, "ent_fire", "nap-l4d2_myparticle KillHierarchy");
					
					if (hJingleTime[client] != null)
					{
						KillTimer(hJingleTime[client]);
						hJingleTime[client] = null;
					}
				}
				
				bHasArmor[client] = true;
				
				SetEntityRenderMode(client, RENDER_TRANSALPHA);
				SetEntityRenderColor(client, _, _, _, 0);
				
				int iArmor = CreateEntityByName("prop_dynamic_ornament");
				DispatchKeyValue(iArmor, "model", sNAPModels[8]);
				
				DispatchSpawn(iArmor);
				ActivateEntity(iArmor);
				
				SetVariantString("!activator");
				AcceptEntityInput(iArmor, "SetParent", client, iArmor);
				SetVariantString("!activator");
				AcceptEntityInput(iArmor, "SetAttached", client, iArmor);
				AcceptEntityInput(iArmor, "TurnOn");
				
				SetEntProp(iArmor, Prop_Send, "m_nMinGPULevel", 1);
				SetEntProp(iArmor, Prop_Send, "m_nMaxGPULevel", 1);
				
				L4D2_SetEntGlow(iArmor, L4D2Glow_Constant, 20000, 0, {0, 255, 0}, false);
				
				iArmorEnt[client] = iArmor;
				SDKHook(iArmorEnt[client], SDKHook_SetTransmit, OnArmorTransmit);
				
				if (hArmorTime[client] == null)
				{
					fTime[client][11] = fArmorDuration;
					hArmorTime[client] = CreateTimer(fTime[client][11], StopArmorEffect, client);
					
					CreateTimer(0.1, CheckArmorEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][11] += fArmorDuration;
				
				if (hArmorTime[client] != null)
				{
					KillTimer(hArmorTime[client]);
					hArmorTime[client] = null;
				}
				hArmorTime[client] = CreateTimer(fTime[client][11], StopArmorEffect, client);
				
				CreateTimer(0.1, CheckArmorEffect, client, TIMER_REPEAT);
			}
		}
		case 25:
		{
			if (!bShouting[client])
			{
				bShouting[client] = true;
				CreateTimer(1.0, DoShout, client, TIMER_REPEAT);
				
				if (hShoutTime[client] == null)
				{
					fTime[client][12] = fShoutDuration;
					hShoutTime[client] = CreateTimer(fTime[client][12], StopShoutEffect, client);
					
					CreateTimer(0.1, CheckShoutEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][12] += fShoutDuration;
				
				if (hShoutTime[client] != null)
				{
					KillTimer(hShoutTime[client]);
					hShoutTime[client] = null;
				}
				hShoutTime[client] = CreateTimer(fTime[client][12], StopShoutEffect, client);
				
				CreateTimer(0.1, CheckShoutEffect, client, TIMER_REPEAT);
			}
		}
		case 26:
		{
			if (!bBlinded[client])
			{
				bBlinded[client] = true;
				ScreenEffects(client, {0, 0, 0, 200}, _, 1);
				
				if (hBlindTime[client] == null)
				{
					fTime[client][13] = fBlindDuration;
					hBlindTime[client] = CreateTimer(fTime[client][13], StopBlindEffect, client);
					
					CreateTimer(0.1, CheckBlindEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][13] += fBlindDuration;
				
				ScreenEffects(client, {0, 0, 0, 0}, _, 1);
				ScreenEffects(client, {0, 0, 0, 200}, _, 1);
				
				if (hBlindTime[client] != null)
				{
					KillTimer(hBlindTime[client]);
					hBlindTime[client] = null;
				}
				hBlindTime[client] = CreateTimer(fTime[client][13], StopBlindEffect, client);
				
				CreateTimer(0.1, CheckBlindEffect, client, TIMER_REPEAT);
			}
		}
		case 27:
		{
			if (!bBlurApplied)
			{
				bBlurApplied = true;
				
				char sBlurIntensity[16];
				strcopy(sBlurIntensity, sizeof(sBlurIntensity), "-1.0");
				
				int iPPControl = CreateEntityByName("postprocess_controller");
				if (iPPControl)
				{
					DispatchKeyValue(iPPControl, "targetname", "nap-l4d2_blur");
					DispatchKeyValue(iPPControl, "spawnflags", "1");
					DispatchKeyValue(iPPControl, "vignettestart", "1");
					DispatchKeyValue(iPPControl, "vignetteend", "4");
					DispatchKeyValue(iPPControl, "vignetteblurstrength", "0");
					DispatchKeyValue(iPPControl, "topvignettestrength", "1");
					DispatchKeyValue(iPPControl, "localcontraststrength", sBlurIntensity);
					DispatchKeyValue(iPPControl, "localcontrastedgestrength", "-.3");
					DispatchKeyValue(iPPControl, "grainstrength", "1");
					DispatchKeyValue(iPPControl, "fadetime", "3");
					
					DispatchSpawn(iPPControl);
					ActivateEntity(iPPControl);
					
					TeleportEntity(iPPControl, fPos, NULL_VECTOR, NULL_VECTOR);
					iBlurEnt[0] = EntIndexToEntRef(iPPControl);
				}
				
				FindBlurryFogs();
				
				int iFogVolume = CreateEntityByName("fog_volume");
				if (iFogVolume != -1)
				{
					DispatchKeyValue(iFogVolume, "PostProcessName", "nap-l4d2_blur");
					DispatchKeyValue(iFogVolume, "spawnflags", "0");
					
					DispatchSpawn(iFogVolume);
					ActivateEntity(iFogVolume);
					
					float fFogMins[3] = {-5000.0, -5000.0, -5000.0},
						fFogMaxs[3] = {5000.0, 5000.0, 5000.0};
					
					SetEntPropVector(iFogVolume, Prop_Send, "m_vecMins", fFogMins);
					SetEntPropVector(iFogVolume, Prop_Send, "m_vecMaxs", fFogMaxs);
					
					TeleportEntity(iFogVolume, fPos, NULL_VECTOR, NULL_VECTOR);
					iBlurEnt[1] = iFogVolume;
				}
				
				FindBlurryFogs(true);
				
				if (hBlurTime == null)
				{
					fTime[0][14] = fBlurDuration;
					hBlurTime = CreateTimer(fTime[0][14], StopBlurEffect);
					
					CreateTimer(0.1, CheckBlurEffect, _, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[0][14] += fBlurDuration;
				
				if (hBlurTime != null)
				{
					KillTimer(hBlurTime);
					hBlurTime = null;
				}
				hBlurTime = CreateTimer(fTime[0][14], StopBlurEffect);
				
				CreateTimer(0.1, CheckBlurEffect, _, TIMER_REPEAT);
			}
		}
		case 28:
		{
			if (!bSnowApplied)
			{
				bSnowApplied = true;
				EmitSoundToAll(sNAPSounds[24]);
				
				if (StrContains(sMap, "c4m", false) == -1)
				{
					int iPrecipitationEnt = -1;
					while ((iPrecipitationEnt = FindEntityByClassname(iPrecipitationEnt, "func_precipitation")) != INVALID_ENT_REFERENCE)
					{
						if (!IsValidEntity(iPrecipitationEnt) || !IsValidEdict(iPrecipitationEnt) || iPrecipitationEnt == iSnowEnt)
						{
							continue;
						}
						
						DeleteEntity(iPrecipitationEnt);
					}
				}
				
				char sSnowModel[PLATFORM_MAX_PATH];
				float fSnowMins[3], fSnowMaxs[3], fSnowVector[3];
				
				Format(sSnowModel, sizeof(sSnowModel), "maps/%s.bsp", sMap);
				PrecacheModel(sSnowModel, true);
				
				int iSnowPrecipitation = CreateEntityByName("func_precipitation");
				DispatchKeyValue(iSnowPrecipitation, "model", sSnowModel);
				DispatchKeyValue(iSnowPrecipitation, "preciptype", "3");
				
				GetEntPropVector(0, Prop_Data, "m_WorldMins", fSnowMins);
				GetEntPropVector(0, Prop_Data, "m_WorldMaxs", fSnowMaxs);
				
				SetEntPropVector(iSnowPrecipitation, Prop_Send, "m_vecMins", fSnowMins);
				SetEntPropVector(iSnowPrecipitation, Prop_Send, "m_vecMaxs", fSnowMaxs);
				
				fSnowVector[0] = fSnowMins[0] + fSnowMaxs[0];
				fSnowVector[1] = fSnowMins[1] + fSnowMaxs[1];
				fSnowVector[2] = fSnowMins[2] + fSnowMaxs[2];
				
				TeleportEntity(iSnowPrecipitation, fSnowVector, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(iSnowPrecipitation);
				ActivateEntity(iSnowPrecipitation);
				
				iSnowEnt = iSnowPrecipitation;
				
				CreateTimer(3.0, GiveFrostBite, _, TIMER_REPEAT);
				if (hSnowTime == null)
				{
					fTime[0][15] = fSnowDuration;
					hSnowTime = CreateTimer(fTime[0][15], StopSnowEffect);
					
					CreateTimer(0.1, CheckSnowEffect, _, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[0][15] += fSnowDuration;
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i))
					{
						StopSound(i, SNDCHAN_AUTO, sNAPSounds[24]);
					}
				}
				
				EmitSoundToAll(sNAPSounds[24]);
				if (hSnowTime != null)
				{
					KillTimer(hSnowTime);
					hSnowTime = null;
				}
				hSnowTime = CreateTimer(fTime[0][15], StopSnowEffect);
				
				CreateTimer(0.1, CheckSnowEffect, _, TIMER_REPEAT);
			}
		}
		case 29:
		{
			if (!bWarping[client])
			{
				bWarping[client] = true;
				CreateTimer(fWarpFrequency, DoWarpMechanism, client, TIMER_REPEAT);
				
				if (hWarpTime[client] == null)
				{
					fTime[client][16] = fWarpDuration;
					hWarpTime[client] = CreateTimer(fTime[client][16], StopWarpEffect, client);
					
					CreateTimer(0.1, CheckWarpEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][16] += fWarpDuration;
				
				if (hWarpTime[client] != null)
				{
					KillTimer(hWarpTime[client]);
					hWarpTime[client] = null;
				}
				hWarpTime[client] = CreateTimer(fTime[client][16], StopWarpEffect, client);
				
				CreateTimer(0.1, CheckWarpEffect, client, TIMER_REPEAT);
			}
		}
		case 30:
		{
			if (!bDistorted[client])
			{
				bDistorted[client] = true;
				bSoundDistorted[client] = false;
				
				if (iDistortionType == 0 || iDistortionType == 3)
				{
					CreateTimer(1.0, ChangeViewColor, client, TIMER_REPEAT);
				}
				
				if (iDistortionType == 1 || iDistortionType == 3)
				{
					CreateTimer(1.0, ChangeViewAngle, client, TIMER_REPEAT);
				}
				
				if (hDistortionTime[client] == null)
				{
					fTime[client][17] = fDistortionDuration;
					hDistortionTime[client] = CreateTimer(fTime[client][17], StopDistortionEffect, client);
					
					CreateTimer(0.1, CheckDistortionEffect, client, TIMER_REPEAT);
				}
			}
			else
			{
				fTime[client][17] += fDistortionDuration;
				
				if (hDistortionTime[client] != null)
				{
					KillTimer(hDistortionTime[client]);
					hDistortionTime[client] = null;
				}
				hDistortionTime[client] = CreateTimer(fTime[client][17], StopDistortionEffect, client);
				
				CreateTimer(0.1, CheckDistortionEffect, client, TIMER_REPEAT);
			}
		}
		case 31:
		{
			float fTankAng[3];
			GetEntPropVector(client, Prop_Send, "m_angRotation", fTankAng);
			fTankAng[1] += 180.0;
			
			switch (iInfectedSpawnType)
			{
				case 0: ExecuteCommand(client, "z_spawn", "tank auto");
				case 1: L4D2_SpawnTank(fPos, fTankAng);
			}
		}
		case 32:
		{
			float fWitchAng[3];
			GetEntPropVector(client, Prop_Send, "m_angRotation", fWitchAng);
			fWitchAng[1] += 180.0;
			
			if (StrEqual(sMap, "c6m1_riverbank", false))
			{
				switch (iInfectedSpawnType)
				{
					case 0: ExecuteCommand(client, "z_spawn", "witch_bride");
					case 1: L4D2_SpawnWitchBride(fPos, fWitchAng);
				}
			}
			else
			{
				switch (iInfectedSpawnType)
				{
					case 0: ExecuteCommand(client, "z_spawn", "witch");
					case 1: L4D2_SpawnWitch(fPos, fWitchAng);
				}
			}
		}
		case 33:
		{
			float fPartyAng[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPartyAng);
			
			int randPartyGuests = GetRandomInt(0, 1);
			switch (randPartyGuests)
			{
				case 0:
				{
					for (int i = 0; i < 7; i++)
					{
						int iUncommonGuest = CreateEntityByName("infected");
						
						if (i == 0)
						{
							DispatchKeyValue(iUncommonGuest, "model", sNAPModels[9]);
							
							fPos[0] -= 20.0;
							fPos[1] -= 15.0;
							
							fPartyAng[1] += 70.0;
						}
						else if (i == 1)
						{
							DispatchKeyValue(iUncommonGuest, "model", sNAPModels[10]);
							
							fPos[1] -= 20.0;
							fPartyAng[1] += 90.0;
						}
						else if (i == 2)
						{
							DispatchKeyValue(iUncommonGuest, "model", sNAPModels[11]);
							
							fPos[0] -= 15.0;
							fPos[1] -= 20.0;
							
							fPartyAng[1] += 150.0;
						}
						else if (i == 3)
						{
							DispatchKeyValue(iUncommonGuest, "model", sNAPModels[8]);
							
							fPos[0] += 20.0;
							fPos[1] += 15.0;
							
							fPartyAng[1] -= 70.0;
						}
						else if (i == 4)
						{
							DispatchKeyValue(iUncommonGuest, "model", sNAPModels[12]);
							
							fPos[1] += 20.0;
							
							fPartyAng[1] -= 90.0;
						}
						else if (i == 5)
						{
							DispatchKeyValue(iUncommonGuest, "model", sNAPModels[13]);
							
							fPos[0] += 15.0;
							fPos[1] += 20.0;
							
							fPartyAng[1] -= 150.0;
						}
						else if (i == 6)
						{
							DispatchKeyValue(iUncommonGuest, "model", sNAPModels[14]);
							fPartyAng[1] += 180.0;
						}
						
						TeleportEntity(iUncommonGuest, fPos, fPartyAng, NULL_VECTOR);
						DispatchSpawn(iUncommonGuest);
					}
				}
				case 1:
				{
					for (int i = 0; i < 7; i++)
					{
						switch (iInfectedSpawnType)
						{
							case 0:
							{
								// To do: Perfect the sourcemod spawning of specials..
								// Temporarily do nothing here..
							}
							case 1:
							{
								if (i == 0)
								{
									fPos[0] -= 20.0;
									fPos[1] -= 15.0;
									
									fPartyAng[1] += 70.0;
									L4D2_SpawnSpecial(1, fPos, fPartyAng);
								}
								else if (i == 1)
								{
									fPos[1] -= 20.0;
									fPartyAng[1] += 90.0;
									
									L4D2_SpawnSpecial(2, fPos, fPartyAng);
								}
								else if (i == 2)
								{
									fPos[0] -= 15.0;
									fPos[1] -= 20.0;
									
									fPartyAng[1] += 150.0;
									L4D2_SpawnSpecial(3, fPos, fPartyAng);
								}
								else if (i == 3)
								{
									fPos[0] += 20.0;
									fPos[1] += 15.0;
									
									fPartyAng[1] -= 70.0;
									L4D2_SpawnSpecial(4, fPos, fPartyAng);
								}
								else if (i == 4)
								{
									fPos[1] += 20.0;
									fPartyAng[1] -= 90.0;
									
									L4D2_SpawnSpecial(5, fPos, fPartyAng);
								}
								else if (i == 5)
								{
									fPos[0] += 15.0;
									fPos[1] += 20.0;
									
									fPartyAng[1] -= 150.0;
									L4D2_SpawnSpecial(6, fPos, fPartyAng);
								}
								else if (i == 6)
								{
									fPartyAng[1] += 180.0;
									L4D2_SpawnSpecial(GetRandomInt(1, 6), fPos, fPartyAng);
								}
							}
						}
					}
				}
			}
			
			int iPartyExtras = CreateEntityByName("info_director");
			DispatchSpawn(iPartyExtras);
			
			AcceptEntityInput(iPartyExtras, "ForcePanicEvent");
			DeleteEntity(iPartyExtras);
		}
		case 34:
		{
			float fTargetAng[3], fAirstrikeAng[3];
			
			GetClientEyeAngles(client, fTargetAng);
			
			fAirstrikeAng[0] = 0.0;
			fAirstrikeAng[1] = fTargetAng[1];
			fAirstrikeAng[2] = 0.0;
			
			float fWorldMax[3];
			GetEntPropVector(0, Prop_Data, "m_WorldMaxs", fWorldMax);
			
			int iAirstrikeEnt = CreateEntityByName("prop_dynamic_override");
			DispatchKeyValue(iAirstrikeEnt, "model", sNAPModels[1]);
			DispatchKeyValue(iAirstrikeEnt, "disableshadows", "1");
			
			float fAirstikeHeight = fPos[2] + 1150.0;
			if (fAirstikeHeight > fWorldMax[2] - 200)
			{
				fPos[2] = fWorldMax[2] - 200;
			}
			else
			{
				fPos[2] = fAirstikeHeight;
			}
			TeleportEntity(iAirstrikeEnt, fPos, fAirstrikeAng, NULL_VECTOR);
			DispatchSpawn(iAirstrikeEnt);
			
			SetEntProp(iAirstrikeEnt, Prop_Send, "m_nMinGPULevel", 1);
			SetEntProp(iAirstrikeEnt, Prop_Send, "m_nMaxGPULevel", 1);
			
			SetEntProp(iAirstrikeEnt, Prop_Data, "m_iHammerID", RoundToNearest(fPos[2]));
			SetEntPropFloat(iAirstrikeEnt, Prop_Send, "m_flModelScale", 5.0);
			
			int randAirstrikeAnim = GetRandomInt(1, 5);
			switch (randAirstrikeAnim)
			{
				case 1: SetVariantString("flyby1");
				case 2: SetVariantString("flyby2");
				case 3: SetVariantString("flyby3");
				case 4: SetVariantString("flyby4");
				case 5: SetVariantString("flyby5");
			}
			AcceptEntityInput(iAirstrikeEnt, "SetAnimation");
			AcceptEntityInput(iAirstrikeEnt, "Enable");
			
			SetVariantString("OnUser1 !self:Kill::6.5:1");
			AcceptEntityInput(iAirstrikeEnt, "AddOutput");
			AcceptEntityInput(iAirstrikeEnt, "FireUser1");
			
			CreateTimer(0.5, DelayAirstrikeBomb, EntIndexToEntRef(iAirstrikeEnt));
		}
		case 35:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) > 1 && !IsFakeClient(i))
				{
					float fEyePos[3];
					GetClientEyePosition(i, fEyePos);
					
					TR_TraceRayFilter(fPos, fEyePos, MASK_VISIBLE_AND_NPCS, RayType_EndPoint, FilterSelf, client);
					
					bool bIsVisible = IsAccuratelyVisible(i, client, _, GetVectorDistance(fPos, fEyePos), true);
					int iBlocked = TR_GetEntityIndex();
					
					if (!bIsVisible || iBlocked != -1)
					{
						if (!bFlashed[i])
						{
							bFlashed[i] = true;
							ScreenEffects(i, _, RoundFloat(FloatMul(fFlashDuration, 500.0)) / 2, 3);
							
							if (hFlashTime[i] == null)
							{
								fTime[i][18] = fFlashDuration / 2.0;
								hFlashTime[i] = CreateTimer(fTime[i][18], StopFlashEffect, i);
								
								CreateTimer(1.0, CheckFlashEffect, i, TIMER_REPEAT);
							}
						}
						else
						{
							fTime[i][18] += (fFlashDuration / 2.0);
							
							ScreenEffects(i, _, _, 3);
							ScreenEffects(i, _, RoundFloat(FloatMul(fTime[i][18], 500.0)), 3);
							
							if (hFlashTime[i] != null)
							{
								KillTimer(hFlashTime[i]);
								hFlashTime[i] = null;
							}
							hFlashTime[i] = CreateTimer(fTime[i][18], StopFlashEffect, i);
							
							CreateTimer(1.0, CheckFlashEffect, i, TIMER_REPEAT);
						}
					}
					else
					{
						if (!bFlashed[i])
						{
							bFlashed[i] = true;
							ScreenEffects(i, _, RoundFloat(FloatMul(fFlashDuration, 500.0)), 3);
							
							if (hFlashTime[i] == null)
							{
								fTime[i][18] = fFlashDuration;
								hFlashTime[i] = CreateTimer(fTime[i][18], StopFlashEffect, i);
								
								CreateTimer(1.0, CheckFlashEffect, i, TIMER_REPEAT);
							}
						}
						else
						{
							fTime[i][18] += fFlashDuration;
							
							ScreenEffects(i, _, _, 3);
							ScreenEffects(i, _, RoundFloat(FloatMul(fTime[i][18], 500.0)), 3);
							
							if (hFlashTime[i] != null)
							{
								KillTimer(hFlashTime[i]);
								hFlashTime[i] = null;
							}
							hFlashTime[i] = CreateTimer(fTime[i][18], StopFlashEffect, i);
							
							CreateTimer(1.0, CheckFlashEffect, i, TIMER_REPEAT);
						}
					}
				}
			}
		}
	}
	
	if (bNotification && iAPIndex[client] != 0 && sAPName[client][0] != '\0')
	{
		PrintHintTextToAll("[NAP] %N Has Deployed %s!", client, sAPName[client]);
		sAPName[client][0] = '\0';
	}
}

public Action StopFreezeEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hFreezeTime[client] == null || !bFrozen[client])
	{
		return Plugin_Stop;
	}
	
	bFrozen[client] = false;
	
	if (sNAPSounds[0][0])
	{
		float vec[3];
		GetClientEyePosition(client, vec);
		EmitAmbientSound(sNAPSounds[0], vec, client, SNDLEVEL_RAIDSIREN);
	}
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderColor(client);
	
	KillTimer(hFreezeTime[client]);
	hFreezeTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckFreezeEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hFreezeTime[client] == null || fTime[client][0] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][0] -= 0.1;
	return Plugin_Continue;
}

public Action StopMatrixEffect(Handle timer, any entity)
{
	if (!IsValidEdict(entity) || hMatrixTime == null || !bMatrixApplied)
	{
		return Plugin_Stop;
	}
	
	bMatrixApplied = false;
	
	AcceptEntityInput(entity, "Stop");
	DeleteEntity(entity);
	
	iTimeEnt = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && IsPlayerAlive(i))
		{
			L4D2_SetEntGlow(i, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
		}
	}
	
	KillTimer(hMatrixTime);
	hMatrixTime = null;
	
	return Plugin_Stop;
}

public Action CheckMatrixEffect(Handle timer)
{
	if (hMatrixTime == null || fTime[0][1] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[0][1] -= 0.1;
	return Plugin_Continue;
}

public Action StopSpeedEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hSpeedTime[client] == null || !bFast[client])
	{
		return Plugin_Stop;
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	bFast[client] = false;
	
	KillTimer(hSpeedTime[client]);
	hSpeedTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckSpeedEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hSpeedTime[client] == null || fTime[client][2] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][2] -= 0.1;
	return Plugin_Continue;
}

public Action StopImmuneEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hImmuneTime[client] == null || !bImmune[client])
	{
		return Plugin_Stop;
	}
	
	L4D2_SetEntGlow(client, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	
	bImmune[client] = false;
	
	KillTimer(hImmuneTime[client]);
	hImmuneTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckImmuneEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hImmuneTime[client] == null || fTime[client][3] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][3] -= 0.1;
	return Plugin_Continue;
}

public Action StopGravityEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hGravityTime[client] == null || !bFloating[client])
	{
		return Plugin_Stop;
	}
	
	SetEntityGravity(client, 1.0);
	bFloating[client] = false;
	
	KillTimer(hGravityTime[client]);
	hGravityTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckGravityEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hGravityTime[client] == null || fTime[client][4] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][4] -= 0.1;
	return Plugin_Continue;
}

public Action StopInvisibleEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hInvisibleTime[client] == null || !bInvisible[client])
	{
		return Plugin_Stop;
	}
	
	bInvisible[client] = false;
	
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client);
	
	if (iInvisibleType == 1)
	{
		SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 1);
		
		if (bInvisibleDummy && IsValidEnt(iDummy[client]))
		{
			if (bInvisibleDummyGlow)
			{
				L4D2_SetEntGlow(iDummy[client], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
			}
			
			DeleteEntity(iDummy[client]);
			iDummy[client] = 0;
		}
	}
	
	KillTimer(hInvisibleTime[client]);
	hInvisibleTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckInvisibleEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hInvisibleTime[client] == null || fTime[client][5] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][5] -= 0.1;
	return Plugin_Continue;
}

public Action StopJingleEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hJingleTime[client] == null || !bJingling[client])
	{
		return Plugin_Stop;
	}
	
	bJingling[client] = false;
	StopSound(client, SNDCHAN_AUTO, sNAPSounds[1]);
	
	KillTimer(hJingleTime[client]);
	hJingleTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckJingleEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hJingleTime[client] == null || fTime[client][6] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][6] -= 0.1;
	return Plugin_Continue;
}

public Action StopRealismEffect(Handle timer)
{
	if (hRealismTime == null || !bRealismApplied)
	{
		return Plugin_Stop;
	}
	
	FindConVar("sv_disable_glow_survivors").RestoreDefault(true, false);
	bRealismApplied = false;
	
	KillTimer(hRealismTime);
	hRealismTime = null;
	
	return Plugin_Stop;
}

public Action CheckRealismEffect(Handle timer)
{
	if (hRealismTime == null || fTime[0][7] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[0][7] -= 0.1;
	return Plugin_Continue;
}

public Action DoMeteorFall(Handle timer, Handle dpMeteorFall)
{
	ResetPack(dpMeteorFall);
	
	int client = GetClientOfUserId(ReadPackCell(dpMeteorFall));
	if (!IsSurvivor(client) || hMeteorFallTime[client] == null || !bWatchingMeteors[client])
	{
		return Plugin_Stop;
	}
	
	float fMeteorFallPos[3];
	
	fMeteorFallPos[0] = ReadPackFloat(dpMeteorFall);
	fMeteorFallPos[1] = ReadPackFloat(dpMeteorFall);
	fMeteorFallPos[2] = ReadPackFloat(dpMeteorFall);
	
	float fAngle[3], fHitPos[3];
	
	fAngle[0] = GetRandomFloat(-20.0, 20.0);
	fAngle[1] = GetRandomFloat(-20.0, 20.0);
	fAngle[2] = 60.0;
	
	GetVectorAngles(fAngle, fAngle);
	GetRayHitPos(fMeteorFallPos, fAngle, fHitPos, client, true);
	
	float fDistance = GetVectorDistance(fMeteorFallPos, fHitPos);
	if (fDistance > 2000.0)
	{
		fDistance = 1600.0;
	}
	
	float fVector[3];
	
	MakeVectorFromPoints(fMeteorFallPos, fHitPos, fVector);
	NormalizeVector(fVector, fVector);
	ScaleVector(fVector, fDistance - 40.0);
	AddVectors(fMeteorFallPos, fVector, fHitPos);
	
	if (fDistance > 100.0)
	{
		int iMeteorEnt = CreateEntityByName("tank_rock");
		if (iMeteorEnt != -1)
		{
			DispatchKeyValue(iMeteorEnt, "model", "models/props_debris/concrete_chunk01a.mdl");
			
			float fMeteorFallAngle[3], fVelocity[3];
			
			fMeteorFallAngle[0] = GetRandomFloat(-180.0, 180.0);
			fMeteorFallAngle[1] = GetRandomFloat(-180.0, 180.0);
			fMeteorFallAngle[2] = GetRandomFloat(-180.0, 180.0);
			
			fVelocity[0] = GetRandomFloat(0.0, 350.0);
			fVelocity[1] = GetRandomFloat(0.0, 350.0);
			fVelocity[2] = GetRandomFloat(0.0, 30.0);
			
			TeleportEntity(iMeteorEnt, fHitPos, fMeteorFallAngle, fVelocity);
			DispatchSpawn(iMeteorEnt);
			ActivateEntity(iMeteorEnt);
			
			AcceptEntityInput(iMeteorEnt, "Ignite");
			
			SetEntProp(iMeteorEnt, Prop_Send, "m_hOwnerEntity", client);
		}
	}
	
	int iMeteorEnt = -1;
	while ((iMeteorEnt = FindEntityByClassname(iMeteorEnt, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(iMeteorEnt) || !IsValidEdict(iMeteorEnt))
		{
			continue;
		}
		
		if (client == GetEntProp(iMeteorEnt, Prop_Send, "m_hOwnerEntity"))
		{
			if (MeasureGroundDistance(iMeteorEnt) < 200.0)
			{
				MeteorFallExplosion(iMeteorEnt, client);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action StopMeteorFallEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hMeteorFallTime[client] == null || !bWatchingMeteors[client])
	{
		return Plugin_Stop;
	}
	
	bWatchingMeteors[client] = false;
	
	int iMeteorEnt = -1;
	while ((iMeteorEnt = FindEntityByClassname(iMeteorEnt, "tank_rock")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(iMeteorEnt) || !IsValidEdict(iMeteorEnt))
		{
			continue;
		}
		
		if (client == GetEntProp(iMeteorEnt, Prop_Send, "m_hOwnerEntity"))
		{
			MeteorFallExplosion(iMeteorEnt, client);
		}
	}
	
	KillTimer(hMeteorFallTime[client]);
	hMeteorFallTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckMeteorFallEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hMeteorFallTime[client] == null || fTime[client][8] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][8] -= 0.1;
	return Plugin_Continue;
}

public Action MakeFireworks(Handle timer, Handle dpFireworks)
{
	ResetPack(dpFireworks);
	
	int client = GetClientOfUserId(ReadPackCell(dpFireworks));
	if (!IsSurvivor(client) || hFireworksTime[client] == null || !bDoingFirework[client])
	{
		return Plugin_Stop;
	}
	
	float fFireworksPos[3];
	
	fFireworksPos[0] = ReadPackFloat(dpFireworks);
	fFireworksPos[1] = ReadPackFloat(dpFireworks);
	fFireworksPos[2] = ReadPackFloat(dpFireworks);
	
	float fFireworksHeight = GetRandomFloat(500.0, 800.0);
	fFireworksPos[2] -= fFireworksHeight;
	
	float fFireworksAngle[3];
	
	fFireworksAngle[0] = GetRandomFloat(-10.0, 10.0);
	fFireworksAngle[1] = GetRandomFloat(-10.0, 10.0);
	fFireworksAngle[2] = GetRandomFloat(-10.0, 10.0);
	
	int randFirework = GetRandomInt(1, 4);
	ShowParticle(fFireworksPos, fFireworksAngle, sNAPParticles[randFirework], 7.5);
	PlaySound(sNAPSounds[GetRandomInt(2, 7)], fFireworksPos);
	
	DataPack dpFireworksSound = new DataPack();
	dpFireworksSound.WriteFloat(fFireworksPos[0]);
	dpFireworksSound.WriteFloat(fFireworksPos[1]);
	dpFireworksSound.WriteFloat(fFireworksPos[2]);
	CreateTimer(2.0, BurstFireworks, dpFireworksSound, TIMER_DATA_HNDL_CLOSE);
	
	fFireworksPos[2] += fFireworksHeight;
	
	if (bFireworksBurnContact)
	{
		for (int i = 1; i < 2049; i++)
		{
			if (IsValidEntity(i) && IsValidEdict(i))
			{
				char sEntityClass[64];
				GetEdictClassname(i, sEntityClass, sizeof(sEntityClass));
				if (!StrEqual(sEntityClass, "infected", false))
				{
					continue;
				}
				
				float fCommonPos[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fCommonPos);
				
				if (GetVectorDistance(fFireworksPos, fCommonPos) > 250.0)
				{
					continue;
				}
				
				IgniteEntity(i, 3.0);
			}
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) > 1 && IsPlayerAlive(i))
			{
				float fSurvivorPos[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fSurvivorPos);
				
				if (GetVectorDistance(fFireworksPos, fSurvivorPos) > 250.0)
				{
					continue;
				}
				
				SDKHooks_TakeDamage(i, 0, client, 1.0, DMG_BURN);
				IgniteEntity(i, 3.0);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action BurstFireworks(Handle timer, Handle dpFireworksSound)
{
	ResetPack(dpFireworksSound);
	
	float fNewSoundPos[3];
	
	fNewSoundPos[0] = ReadPackFloat(dpFireworksSound);
	fNewSoundPos[1] = ReadPackFloat(dpFireworksSound);
	fNewSoundPos[2] = ReadPackFloat(dpFireworksSound) + 400.0;
	
	PlaySound(sNAPSounds[GetRandomInt(8, 11)], fNewSoundPos);
	return Plugin_Stop;
}

public Action StopFireworksEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hFireworksTime[client] == null || !bDoingFirework[client])
	{
		return Plugin_Stop;
	}
	
	bDoingFirework[client] = false;
	
	KillTimer(hFireworksTime[client]);
	hFireworksTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckFireworksEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hFireworksTime[client] == null || fTime[client][9] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][9] -= 0.1;
	return Plugin_Continue;
}

public Action DisablePointHurt(Handle timer, any entity)
{
	if (!IsValidEntity(entity))
	{
		return Plugin_Stop;
	}
	
	AcceptEntityInput(entity, "TurnOff");
	return Plugin_Stop;
}

public Action RemoveExplosion(Handle timer, Handle dpExplosion)
{
	ResetPack(dpExplosion);
	
	for (int i = 1; i < 4; i++)
	{
		int iLeftEntity = ReadPackCell(dpExplosion);
		if (!IsValidEntity(iLeftEntity))
		{
			continue;
		}
		
		DeleteEntity(iLeftEntity);
	}
	
	return Plugin_Stop;
}

public Action DoPetScan(Handle timer, any client)
{
	if (!IsClientInGame(client) || hPetTime[client] == null || !bHasPet[client])
	{
		return Plugin_Stop;
	}
	
	float fPetOwnerPos[3], fPetOwnerAng[3], fPetPos[3], fPetAngle[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPetOwnerPos);
	GetEntPropVector(client, Prop_Send, "m_angRotation", fPetOwnerAng);
	
	fPetOwnerPos[2] += fPetHeight;
	
	GetEntPropVector(iPetEnt[client], Prop_Send, "m_vecOrigin", fPetPos);
	GetEntPropVector(iPetEnt[client], Prop_Send, "m_angRotation", fPetAngle);
	
	fPetPos[2] -= 3000.0;
	
	int iEnemy = iPetTarget[iPetEnt[client]];
	if (IsInfected(iEnemy))
	{
		float fPetTargetPos[3];
		GetEntPropVector(iPetTarget[iPetEnt[client]], Prop_Send, "m_vecOrigin", fPetTargetPos);
		
		if (GetVectorDistance(fPetTargetPos, fPetPos) <= fPetProtectRange)
		{
			AlignPetToTarget(client);
			if (TraceFireCollision(client))
			{
				MakePetFire(client, 0);
				if (!bPetFireInterval[iPetEnt[client]])
				{
					bPetFireInterval[iPetEnt[client]] = true;
					
					if (GetEntProp(iEnemy, Prop_Send, "m_zombieClass") != 8)
					{
						CreateTimer(2.0, ReloadPetEquipments, iPetEnt[client]);
						
						MakePetFire(client, 1);
					}
					else
					{
						float fAdditionalTime = 0.0;
						
						for (int i = 1; i < 4; i++)
						{
							MakePetFire(client, 2);
							fAdditionalTime += 0.2;
						}
						
						CreateTimer(10.0 + fAdditionalTime, ReloadPetEquipments, iPetEnt[client]);
					}
				}
			}
			else
			{
				iPetTarget[iPetEnt[client]] = 0;
			}
		}
	}
	else
	{
		GivePetOrder(client, 0);
		
		if (bIsPetFollowing[iPetEnt[client]])
		{
			if (GetVectorDistance(fPetOwnerPos, fPetPos) < 50.0)
			{
				bIsPetFollowing[iPetEnt[client]] = false;
			}
			GivePetOrder(client, 1);
		}
		else
		{
			if (GetVectorDistance(fPetOwnerPos, fPetPos) >= 1000.0)
			{
				TeleportEntity(iPetEnt[client], fPetOwnerPos, fPetOwnerAng, NULL_VECTOR);
			}
			else if (GetVectorDistance(fPetOwnerPos, fPetPos) > 200.0 && GetVectorDistance(fPetOwnerPos, fPetPos) < 1000.0)
			{
				bIsPetFollowing[iPetEnt[client]] = true;
			}
			else if (GetVectorDistance(fPetOwnerPos, fPetPos) <= 200.0)
			{
				GivePetOrder(client, 2);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action RemovePetEntities(Handle timer, any entity)
{
	if (!IsValidEntity(entity) || !IsValidEdict(entity))
	{
		return Plugin_Stop;
	}
	
	char sEntityClass[64];
	GetEdictClassname(entity, sEntityClass, sizeof(sEntityClass));
	if (StrEqual(sEntityClass, "env_steam", false))
	{
		AcceptEntityInput(entity, "TurnOff");
	}
	DeleteEntity(entity);
	
	return Plugin_Stop;
}

public Action ReloadPetEquipments(Handle timer, any entity)
{
	if (!bPetFireInterval[entity])
	{
		return Plugin_Stop;
	}
	
	bPetFireInterval[entity] = false;
	return Plugin_Stop;
}

public Action StopPetEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hPetTime[client] == null || !bHasPet[client])
	{
		return Plugin_Stop;
	}
	
	bHasPet[client] = false;
	
	if (IsValidEnt(iPetEnt[client]))
	{
		bPetFireInterval[iPetEnt[client]] = false;
		bIsPetFollowing[iPetEnt[client]] = false;
		bIsPetHovering[iPetEnt[client]] = false;
		
		float fPetAngle[3], fPetVelocity[3];
		
		GetEntPropVector(iPetEnt[client], Prop_Send, "m_angRotation", fPetAngle);
		fPetAngle[0] -= 20.0;
		
		GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(fPetVelocity, fPetVelocity);
		ScaleVector(fPetVelocity, 900.0);
		
		TeleportEntity(iPetEnt[client], NULL_VECTOR, NULL_VECTOR, fPetVelocity);
		
		CreateTimer(0.3, RemovePetEntities, iPetEnt[client]);
		CreateTimer(0.3, RemovePetEntities, iPetExtras[iPetEnt[client]][0]);
		CreateTimer(0.3, RemovePetEntities, iPetExtras[iPetEnt[client]][1]);
		
		EmitSoundToClient(client, sNAPSounds[19]);
		
		iPetTarget[iPetEnt[client]] = 0;
		for (int i = 0; i < 2; i++)
		{
			iPetExtras[iPetEnt[client]][i] = 0;
		}
		iPetEnt[client] = 0;
	}
	
	KillTimer(hPetTime[client]);
	hPetTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckPetEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hPetTime[client] == null || fTime[client][10] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][10] -= 0.1;
	return Plugin_Continue;
}

public Action OnArmorTransmit(int entity, int other)
{
	if (entity == iArmorEnt[other] && !IsThirdPersonView(other))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action StopArmorEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hArmorTime[client] == null || !bHasArmor[client])
	{
		return Plugin_Stop;
	}
	
	bHasArmor[client] = false;
	if (IsValidEnt(iArmorEnt[client]))
	{
		L4D2_SetEntGlow(iArmorEnt[client], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
		SDKUnhook(iArmorEnt[client], SDKHook_SetTransmit, OnArmorTransmit);
		
		AcceptEntityInput(iArmorEnt[client], "ClearParent");
		DeleteEntity(iArmorEnt[client]);
		
		iArmorEnt[client] = 0;
		
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client);
	}
	
	KillTimer(hArmorTime[client]);
	hArmorTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckArmorEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hArmorTime[client] == null || fTime[client][11] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][11] -= 0.1;
	return Plugin_Continue;
}

public Action DoShout(Handle timer, any client)
{
	if (!IsClientInGame(client) || hShoutTime[client] == null || !bShouting[client])
	{
		return Plugin_Stop;
	}
	
	if (IsActorBusy(client))
	{
		return Plugin_Continue;
	}
	
	float fShouterPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fShouterPos);
	
	AttachParticle(client, sNAPParticles[10], 7.5);
	
	char sShouterModel[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", sShouterModel, sizeof(sShouterModel));
	if (sShouterModel[26] == 'g')
	{
		PerformSceneEx(client, "", sNAPScenes[GetRandomInt(0, 4)]);
	}
	else if (sShouterModel[26] == 'p')
	{
		PerformSceneEx(client, "", sNAPScenes[GetRandomInt(5, 6)]);
	}
	else if (sShouterModel[26] == 'c')
	{
		PerformSceneEx(client, "", sNAPScenes[GetRandomInt(7, 10)]);
	}
	else if (sShouterModel[26] == 'm' && sShouterModel[27] == 'e')
	{
		PerformSceneEx(client, "", sNAPScenes[GetRandomInt(11, 14)]);
	}
	else if (sShouterModel[26] == 'n')
	{
		PerformSceneEx(client, "", sNAPScenes[GetRandomInt(15, 17)]);
	}
	else if (sShouterModel[26] == 't')
	{
		PerformSceneEx(client, "", sNAPScenes[GetRandomInt(18, 24)]);
	}
	else if (sShouterModel[26] == 'b')
	{
		PerformSceneEx(client, "", sNAPScenes[GetRandomInt(25, 30)]);
	}
	else if (sShouterModel[26] == 'm' && sShouterModel[27] == 'a')
	{
		PerformSceneEx(client, "", sNAPScenes[GetRandomInt(31, 34)]);
	}
	else if (sShouterModel[26] == 'a')
	{
		PerformSceneEx(client, "", sNAPScenes[GetRandomInt(5, 6)], _, _, SCENE_INITIATOR_WORLD);
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && IsPlayerAlive(i) && i != client)
		{
			float fListenerPos[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", fListenerPos);
			
			if (GetVectorDistance(fShouterPos, fListenerPos) <= fShoutRange)
			{
				SDKHooks_TakeDamage(i, 0, client, fShoutDamage, DMG_SHOCK);
				SDKCall(hNAPStaggerPlayer, i, client, fShouterPos);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action StopShoutEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hShoutTime[client] == null || !bShouting[client])
	{
		return Plugin_Stop;
	}
	
	bShouting[client] = false;
	
	KillTimer(hShoutTime[client]);
	hShoutTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckShoutEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hShoutTime[client] == null || fTime[client][12] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][12] -= 0.1;
	return Plugin_Continue;
}

public Action StopBlindEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hBlindTime[client] == null || !bBlinded[client])
	{
		return Plugin_Stop;
	}
	
	bBlinded[client] = false;
	ScreenEffects(client, {0, 0, 0, 0}, _, 1);
	
	KillTimer(hBlindTime[client]);
	hBlindTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckBlindEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hBlindTime[client] == null || fTime[client][13] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][13] -= 0.1;
	return Plugin_Continue;
}

public Action StopBlurEffect(Handle timer)
{
	if (hBlurTime == null || !bBlurApplied)
	{
		return Plugin_Stop;
	}
	
	bBlurApplied = false;
	if (IsValidEntRef(iBlurEnt[0]))
	{
		DeleteEntity(iBlurEnt[0]);
		iBlurEnt[0] = 0;
	}
	
	if (IsValidEnt(iBlurEnt[1]))
	{
		DeleteEntity(iBlurEnt[1]);
		iBlurEnt[1] = 0;
	}
	
	KillTimer(hBlurTime);
	hBlurTime = null;
	
	return Plugin_Stop;
}

public Action CheckBlurEffect(Handle timer)
{
	if (hBlurTime == null || fTime[0][14] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[0][14] -= 0.1;
	return Plugin_Continue;
}

public Action GiveFrostBite(Handle timer)
{
	if (iSnowFreezeChance == 0 || hSnowTime == null || !bSnowApplied)
	{
		return Plugin_Stop;
	}
	
	int iFBChance = GetRandomInt(1, 99);
	if (iFBChance > iSnowFreezeChance)
	{
		return Plugin_Continue;
	}
	
	int iFBVictim = ChooseRandomSurvivor();
	
	SetEntityMoveType(iFBVictim, MOVETYPE_NONE);
	SetEntityRenderColor(iFBVictim, 0, 0, 255, 180);
	
	ScreenEffects(iFBVictim, {0, 0, 255, 150}, 2500, 0);
	CreateTimer(5.0, ThawFrostBite, iFBVictim);
	
	return Plugin_Continue;
}

public Action ThawFrostBite(Handle timer, any client)
{
	if (!IsValidEntity(client))
	{
		return Plugin_Stop;
	}
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderColor(client);
	
	return Plugin_Continue;
}

public Action StopSnowEffect(Handle timer)
{
	if (hSnowTime == null || !bSnowApplied)
	{
		return Plugin_Stop;
	}
	
	bSnowApplied = false;
	if (IsValidEnt(iSnowEnt))
	{
		DeleteEntity(iSnowEnt);
		iSnowEnt = 0;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			StopSound(i, SNDCHAN_AUTO, sNAPSounds[24]);
		}
	}
	
	KillTimer(hSnowTime);
	hSnowTime = null;
	
	return Plugin_Stop;
}

public Action CheckSnowEffect(Handle timer)
{
	if (hSnowTime == null || fTime[0][15] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[0][15] -= 0.1;
	return Plugin_Continue;
}

public Action DoWarpMechanism(Handle timer, any client)
{
	if (!IsClientInGame(client) || hWarpTime[client] == null || !bWarping[client])
	{
		return Plugin_Stop;
	}
	
	int iWarpTarget = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && i != client)
		{
			iWarpTarget = i;
			break;
		}
	}
	if (iWarpTarget != 0)
	{
		float fOtherPos[3], fOtherAng[3];
		
		GetEntPropVector(iWarpTarget, Prop_Send, "m_vecOrigin", fOtherPos);
		GetEntPropVector(iWarpTarget, Prop_Send, "m_angRotation", fOtherAng);
		
		ShowParticle(fOtherPos, fOtherAng, sNAPParticles[11], 2.0);
		TeleportEntity(client, fOtherPos, fOtherAng, NULL_VECTOR);
		
		EmitSoundToAll(sNAPSounds[25], client);
	}
	
	return Plugin_Continue;
}

public Action StopWarpEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hWarpTime[client] == null || !bWarping[client])
	{
		return Plugin_Stop;
	}
	
	bWarping[client] = false;
	
	KillTimer(hWarpTime[client]);
	hWarpTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckWarpEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hWarpTime[client] == null || fTime[client][16] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][16] -= 0.1;
	return Plugin_Continue;
}

public Action ChangeViewColor(Handle timer, any client)
{
	if (!IsClientInGame(client) || hDistortionTime[client] == null || !bDistorted[client])
	{
		return Plugin_Stop;
	}
	
	int iDistortionColor[4];
	
	iDistortionColor[0] = GetRandomInt(0, 255);
	iDistortionColor[1] = GetRandomInt(0, 255);
	iDistortionColor[2] = GetRandomInt(0, 255);
	iDistortionColor[3] = 128;
	
	ScreenEffects(client, iDistortionColor, _, 2);
	return Plugin_Continue;
}

public Action ChangeViewAngle(Handle timer, any client)
{
	if (!IsClientInGame(client) || hDistortionTime[client] == null || !bDistorted[client])
	{
		return Plugin_Stop;
	}
	
	float fNewEyeAng[3];
	GetClientEyeAngles(client, fNewEyeAng);
	fNewEyeAng[2] = fDistortionAng[GetRandomInt(0, 100) % 20];
	
	TeleportEntity(client, NULL_VECTOR, fNewEyeAng, NULL_VECTOR);
	return Plugin_Continue;
}

public Action StopDistortionEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hDistortionTime[client] == null || !bDistorted[client])
	{
		return Plugin_Stop;
	}
	
	bDistorted[client] = false;
	bSoundDistorted[client] = false;
	
	if (iDistortionType == 0 || iDistortionType == 3)
	{
		ScreenEffects(client, {0, 0, 0, 0}, _, 2);
	}
	
	if (iDistortionType == 1 || iDistortionType == 3)
	{
		float fFixedEyeAng[3];
		GetClientEyeAngles(client, fFixedEyeAng);
		fFixedEyeAng[2] = 0.0;
		
		TeleportEntity(client, NULL_VECTOR, fFixedEyeAng, NULL_VECTOR);
	}
	
	KillTimer(hDistortionTime[client]);
	hDistortionTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckDistortionEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hDistortionTime[client] == null || fTime[client][17] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][17] -= 0.1;
	return Plugin_Continue;
}

public Action DelayAirstrikeBomb(Handle timer, any entity)
{
	if (!IsValidEntRef(entity))
	{
		return Plugin_Stop;
	}
	
	float fBombPos[3], fBombAng[3], fBombVec[3];
	
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", fBombPos);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", fBombAng);
	
	int iBombEnt = CreateEntityByName("grenade_launcher_projectile");
	DispatchKeyValue(iBombEnt, "model", sNAPModels[3]);
	
	GetAngleVectors(fBombAng, fBombVec, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(fBombVec, fBombVec);
	ScaleVector(fBombVec, -700.0);
	
	float fTrajectory = fBombPos[2] - float(GetEntProp(entity, Prop_Data, "m_iHammerID")) + 1600.0;
	fTrajectory -= (fTrajectory / 10);
	
	MoveForward(fBombPos, fBombAng, fBombPos, fTrajectory);
	
	fBombPos[0] += GetRandomFloat(-200.0, 200.0);
	fBombPos[1] += GetRandomFloat(-200.0, 200.0);
	
	TeleportEntity(iBombEnt, fBombPos, fBombAng, fBombVec);
	DispatchSpawn(iBombEnt);
	
	SetEntityMoveType(iBombEnt, MOVETYPE_NOCLIP);
	CreateTimer(1.2, DelayBombCheck, EntIndexToEntRef(iBombEnt));
	
	SetVariantString("OnUser1 !self:Kill::10.0:1");
	AcceptEntityInput(iBombEnt, "AddOutput");
	AcceptEntityInput(iBombEnt, "FireUser1");
	
	SetEntPropFloat(iBombEnt, Prop_Send, "m_flModelScale", 0.3);
	
	int randBombSound = GetRandomInt(1, 7);
	EmitSoundToAll(sNAPSounds[(randBombSound == 3) ? 19 : GetRandomInt(26, 31)], iBombEnt, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
	
	int iBombParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iBombParticle))
	{
		DispatchKeyValue(iBombParticle, "effect_name", sNAPParticles[12]);
		
		TeleportEntity(iBombParticle, fBombPos, fBombAng, NULL_VECTOR);
		DispatchSpawn(iBombParticle);
		ActivateEntity(iBombParticle);
		
		AcceptEntityInput(iBombParticle, "Start");
		
		SetVariantString("!activator");
		AcceptEntityInput(iBombParticle, "SetParent", iBombEnt, iBombParticle);
		
		SetVariantString("OnUser3 !self:Kill::10.0:1");
		AcceptEntityInput(iBombParticle, "AddOutput");
		AcceptEntityInput(iBombParticle, "FireUser3");
		
		SetVariantString("OnUser1 !self:Stop::0.65:-1");
		AcceptEntityInput(iBombParticle, "AddOutput");
		SetVariantString("OnUser1 !self:FireUser2::0.7:-1");
		AcceptEntityInput(iBombParticle, "AddOutput");
		AcceptEntityInput(iBombParticle, "FireUser1");
		
		SetVariantString("OnUser2 !self:Start::0:-1");
		AcceptEntityInput(iBombParticle, "AddOutput");
		SetVariantString("OnUser2 !self:FireUser1::0:-1");
		AcceptEntityInput(iBombParticle, "AddOutput");
	}
	
	return Plugin_Stop;
}

public Action DelayBombCheck(Handle timer, any entity)
{	
	if (!IsValidEntRef(entity))
	{
		return Plugin_Stop;
	}
	
	CreateTimer(0.1, RecordBombID, entity, TIMER_REPEAT);
	return Plugin_Stop;
}

public Action RecordBombID(Handle timer, any entity)
{
	if (!IsValidEntRef(entity))
	{
		return Plugin_Stop;
	}
	
	int iEntityID = GetEntProp(entity, Prop_Data, "m_iHammerID");
	if (iEntityID > 15)
	{
		SDKHook(EntRefToEntIndex(entity), SDKHook_Touch, OnAirstrikeBombTouch);
		SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
		
		return Plugin_Stop;
	}
	
	SetEntProp(entity, Prop_Data, "m_iHammerID", iEntityID + 1);
	
	float fBombVec[3];
	GetEntPropVector(entity, Prop_Data, "m_vecVelocity", fBombVec);
	fBombVec[2] -= 50.0;
	
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fBombVec);
	return Plugin_Continue;
}

public void OnAirstrikeBombTouch(int entity, int other)
{
	char sToucher[64];
	GetEdictClassname(other, sToucher, sizeof(sToucher));
	if (strcmp(sToucher, "trigger_multiple") && strcmp(sToucher, "trigger_hurt"))
	{
		CreateTimer(0.1, DelayBombExplosion, EntIndexToEntRef(entity));
		SDKUnhook(entity, SDKHook_Touch, OnAirstrikeBombTouch);
	}
}

public Action DelayBombExplosion(Handle timer, any entity)
{
	if (EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}
	
	float fExplosionPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", fExplosionPos);
	
	DeleteEntity(entity);
	
	Call_StartForward(hNAPAirstrikeHitForward);
	Call_PushFloat(fExplosionPos[0]);
	Call_PushFloat(fExplosionPos[1]);
	Call_PushFloat(fExplosionPos[2]);
	Call_Finish();
	
	char sTemp[16];
	
	int iAirstrikeExplosion = CreateEntityByName("env_explosion");
	
	DispatchKeyValue(iAirstrikeExplosion, "spawnflags", "1916");
	IntToString(300, sTemp, sizeof(sTemp));
	DispatchKeyValue(iAirstrikeExplosion, "iMagnitude", sTemp);
	IntToString(800, sTemp, sizeof(sTemp));
	DispatchKeyValue(iAirstrikeExplosion, "iRadiusOverride", sTemp);
	
	TeleportEntity(iAirstrikeExplosion, fExplosionPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iAirstrikeExplosion);
	
	AcceptEntityInput(iAirstrikeExplosion, "Explode");
	
	int iExplosionShake = CreateEntityByName("env_shake");
	if (iExplosionShake != -1)
	{
		DispatchKeyValue(iExplosionShake, "spawnflags", "8");
		DispatchKeyValue(iExplosionShake, "amplitude", "16.0");
		DispatchKeyValue(iExplosionShake, "frequency", "1.5");
		DispatchKeyValue(iExplosionShake, "duration", "0.9");
		IntToString(1500, sTemp, sizeof(sTemp));
		DispatchKeyValue(iExplosionShake, "radius", sTemp);
		
		DispatchSpawn(iExplosionShake);
		ActivateEntity(iExplosionShake);
		AcceptEntityInput(iExplosionShake, "Enable");
		
		TeleportEntity(iExplosionShake, fExplosionPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iExplosionShake, "StartShake");
		
		SetVariantString("OnUser1 !self:Kill::1.1:1");
		AcceptEntityInput(iExplosionShake, "AddOutput");
		AcceptEntityInput(iExplosionShake, "FireUser1");
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				float fVictimPos[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fVictimPos);
				
				if (GetVectorDistance(fExplosionPos, fVictimPos) <= 1500.0)
				{
					SDKCall(hNAPStaggerPlayer, i, iExplosionShake, fExplosionPos);
					
					char sVictimModel[128];
					GetEntPropString(i, Prop_Data, "m_ModelName", sVictimModel, sizeof(sVictimModel));
					if (sVictimModel[26] == 'g')
					{
						PerformSceneEx(i, "", sNAPScenes[GetRandomInt(35, 38)]);
					}
					else if (sVictimModel[26] == 'p')
					{
						PerformSceneEx(i, "", sNAPScenes[GetRandomInt(39, 41)]);
					}
					else if (sVictimModel[26] == 'c')
					{
						PerformSceneEx(i, "", sNAPScenes[GetRandomInt(42, 44)]);
					}
					else if (sVictimModel[26] == 'm' && sVictimModel[27] == 'e')
					{
						PerformSceneEx(i, "", sNAPScenes[GetRandomInt(45, 50)]);
					}
					else if (sVictimModel[26] == 'n')
					{
						PerformSceneEx(i, "", sNAPScenes[GetRandomInt(51, 53)]);
					}
					else if (sVictimModel[26] == 't')
					{
						PerformSceneEx(i, "", sNAPScenes[GetRandomInt(54, 59)]);
					}
					else if (sVictimModel[26] == 'b')
					{
						PerformSceneEx(i, "", sNAPScenes[GetRandomInt(60, 62)]);
					}
					else if (sVictimModel[26] == 'm' && sVictimModel[27] == 'e')
					{
						PerformSceneEx(i, "", sNAPScenes[GetRandomInt(63, 66)]);
					}
					else if (sVictimModel[26] == 'a')
					{
						PerformSceneEx(i, "", sNAPScenes[GetRandomInt(39, 41)], _, _, SCENE_INITIATOR_WORLD);
					}
				}
			}
		}
	}
	
	int iExplosionParticle = CreateEntityByName("info_particle_system");
	if (iExplosionParticle != -1)
	{
		int randExplosionParticle = GetRandomInt(1, 4);
		DispatchKeyValue(iExplosionParticle, "effect_name", sNAPParticles[(randExplosionParticle == 1) ? 8 : GetRandomInt(13, 15)]);
		
		switch (randExplosionParticle)
		{
			case 1: fExplosionPos[2] += 175.0;
			case 3: fExplosionPos[2] += 100.0;
			case 4: fExplosionPos[2] += 25.0;
		}
		
		TeleportEntity(iExplosionParticle, fExplosionPos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iExplosionParticle);
		ActivateEntity(iExplosionParticle);
		
		AcceptEntityInput(iExplosionParticle, "Start");
		
		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(iExplosionParticle, "AddOutput");
		AcceptEntityInput(iExplosionParticle, "FireUser1");
	}
	
	EmitSoundToAll(sNAPSounds[GetRandomInt(31, 34)], entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
	return Plugin_Stop;
}

public bool FilterSelf(int entity, int contentsMask, any data)
{
	if (IsSurvivor(entity) && entity == data)
	{
		return false;
	}
	return true;
}

public Action StopFlashEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hFlashTime[client] == null || !bFlashed[client])
	{
		return Plugin_Stop;
	}
	
	bFlashed[client] = false;
	ScreenEffects(client, {0, 0, 0, 0}, _, 3);
	
	KillTimer(hFlashTime[client]);
	hFlashTime[client] = null;
	
	return Plugin_Stop;
}

public Action CheckFlashEffect(Handle timer, any client)
{
	if (!IsClientInGame(client) || hFlashTime[client] == null || fTime[client][18] <= 0.0)
	{
		return Plugin_Stop;
	}
	
	fTime[client][18] -= 0.1;
	return Plugin_Continue;
}

void DeleteEntity(int entity)
{
	AcceptEntityInput(entity, "Kill");
	RemoveEdict(entity);
}

void ScreenEffects(int target, int iColorOverride[4] = {255, 255, 255, 255}, int duration = 0, int iEffectType)
{
	switch (iEffectType)
	{
		case 0:
		{
			Handle hFreezeMsg = StartMessageOne("Fade", target);
			BfWriteShort(hFreezeMsg, 500);
			BfWriteShort(hFreezeMsg, duration);
			BfWriteShort(hFreezeMsg, (0x0001 | 0x0010));
			BfWriteByte(hFreezeMsg, iColorOverride[0]);
			BfWriteByte(hFreezeMsg, iColorOverride[1]);
			BfWriteByte(hFreezeMsg, iColorOverride[2]);
			BfWriteByte(hFreezeMsg, iColorOverride[3]);
			EndMessage();
		}
		case 1:
		{
			int iBlindTarget[2];
			iBlindTarget[0] = target;
			
			Handle hBlindMsg = StartMessageEx(GetUserMessageId("Fade"), iBlindTarget, 1);
			BfWriteShort(hBlindMsg, 1536);
			BfWriteShort(hBlindMsg, 1536);
			if (iColorOverride[3] != 0)
			{
				BfWriteShort(hBlindMsg, (0x0002 | 0x0008));
			}
			else
			{
				BfWriteShort(hBlindMsg, (0x0001 | 0x0010));
			}
			BfWriteByte(hBlindMsg, iColorOverride[0]);
			BfWriteByte(hBlindMsg, iColorOverride[1]);
			BfWriteByte(hBlindMsg, iColorOverride[2]);
			BfWriteByte(hBlindMsg, iColorOverride[3]);
			EndMessage();
		}
		case 2:
		{
			int iDistortionTarget[2];
			iDistortionTarget[0] = target;
			
			Handle hDistortionMsg = StartMessageEx(GetUserMessageId("Fade"), iDistortionTarget, 1);
			if (iColorOverride[0] != 0 || iColorOverride[1] != 0 || iColorOverride[2] != 0 || iColorOverride[3] != 0)
			{
				BfWriteShort(hDistortionMsg, 255);
				BfWriteShort(hDistortionMsg, 255);
				BfWriteShort(hDistortionMsg, 0x0002);
			}
			else
			{
				BfWriteShort(hDistortionMsg, 1536);
				BfWriteShort(hDistortionMsg, 1536);
				BfWriteShort(hDistortionMsg, (0x0001 | 0x0010));
			}
			BfWriteByte(hDistortionMsg, iColorOverride[0]);
			BfWriteByte(hDistortionMsg, iColorOverride[1]);
			BfWriteByte(hDistortionMsg, iColorOverride[2]);
			BfWriteByte(hDistortionMsg, iColorOverride[3]);
			EndMessage();
		}
		case 3:
		{
			Handle hFlashMsg = StartMessageOne("Fade", target);
			BfWriteShort(hFlashMsg, duration);
			BfWriteShort(hFlashMsg, duration);
			BfWriteShort(hFlashMsg, (0x0001|0x0010));
			BfWriteByte(hFlashMsg, iColorOverride[0]);
			BfWriteByte(hFlashMsg, iColorOverride[1]);
			BfWriteByte(hFlashMsg, iColorOverride[2]);
			BfWriteByte(hFlashMsg, iColorOverride[3]);
			EndMessage();
		}
	}
}

int GetAmmoPackID(int entity)
{
	for (int i; i < 10; i++)
	{
		if (iAmmoPackID[i] == entity)
		{
			return i;
		}
	}
	
	return RecreateAmmoPack(entity);
}

int RecreateAmmoPack(int entity)
{
	iAPMaxUses[iAmmoPackCount] = GetTeamClientCount(2);
	iAmmoPackID[iAmmoPackCount] = entity;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			bAmmoPackUsed[iAmmoPackCount][i] = false;
		}
	}
	
	int iAPRecreated = iAmmoPackCount;
	
	iAmmoPackCount += 1;
	if (iAmmoPackCount == 10)
	{
		iAmmoPackCount = 0;
	}
	
	return iAPRecreated;
}

int GetUpgradeAmmoCount(int client, bool bMultiplied = false)
{
	int primary = GetPlayerWeaponSlot(client, 0);
	if (!IsValidEnt(primary))
	{
		return 0;
	}
	
	char sPrimaryWeapon[64];
	GetEdictClassname(primary, sPrimaryWeapon, sizeof(sPrimaryWeapon));
	if (StrEqual(sPrimaryWeapon, "weapon_rifle_m60", false))
	{
		if (!bMultiplied)
		{
			return 150;
		}
		else
		{
			int randAdd, randChoice = GetRandomInt(0, 2);
			switch (randChoice)
			{
				case 0: randAdd = 25;
				case 1: randAdd = 50;
				case 2: randAdd = 100;
			}
			return 150 + randAdd;
		}
	}
	else if (StrEqual(sPrimaryWeapon, "weapon_grenade_launcher", false))
	{
		if (bMultiplied)
		{
			int randMultiplier, randChoice = GetRandomInt(0, 2);
			switch (randChoice)
			{
				case 0: randMultiplier = 1;
				case 1: randMultiplier = 2;
				case 2: randMultiplier = 3;
			}
			
			if (MCGL_CVAR != null)
			{
				return FindConVar("multi-clip_grenade_launchers-l4d2_max").IntValue * randMultiplier;
			}
			else
			{
				return 1 * randMultiplier;
			}
		}
		else
		{
			return 1;
		}
	}
	else
	{
		if (bMultiplied)
		{
			int randMultiplier, randChoice = GetRandomInt(0, 2);
			switch (randChoice)
			{
				case 0: randMultiplier = 1;
				case 1: randMultiplier = 3;
				case 2: randMultiplier = 5;
			}
			return randMultiplier * GetEntProp(primary, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
		}
		else
		{
			return GetEntProp(primary, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
		}
	}
}

void SetUpgradeAmmoCount(int client, int amount)
{
	int primary = GetPlayerWeaponSlot(client, 0);
	if (!IsValidEnt(primary))
	{
		return;
	}
	
	SetEntProp(primary, Prop_Send, "m_iClip1", amount, 1);
	SetEntProp(primary, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount, 1);
}

void CheckUsableAmmoPack(int client, int entity)
{
	if (!IsDeployedAmmoPack(entity))
	{
		return;
	}
	
	SetEntData(iAmmoPackID[entity], FindSendPropInfo("CBaseUpgradeItem", "m_iUsedBySurvivorsMask"), (bAmmoPackUsed[entity][client] ? 255 : 0), 1, true);
	if (bAmmoPackUsed[entity][client] && hAmmoPackResetTime[entity] == null)
	{
		hAmmoPackResetTime[entity] = CreateTimer(0.2, ResetAmmoPack, entity);
	}
}

void AttachParticle(int client, char[] sParticle, float fLifeSpan)
{
	int iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{
		float fPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		TeleportEntity(iParticle, fPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "targetname", "nap-l4d2_myparticle");
		DispatchKeyValue(iParticle, "effect_name", sParticle);
		DispatchSpawn(iParticle);
		
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", client, iParticle);
		
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
		
		CreateTimer(fLifeSpan, RemoveParticle, iParticle);
	}
}

int GetRayHitPos(float fGivenPos[3], float fGivenAngle[3], float fGivenHitPos[3], int entity, bool bExact)
{
	int iEntityHit = 0;
	
	Handle hTrace = TR_TraceRayFilterEx(fGivenPos, fGivenAngle, MASK_SOLID, RayType_Infinite, ExcludeSelfAndAlive, entity);
	if (TR_DidHit(hTrace))
	{
		TR_GetEndPosition(fGivenHitPos, hTrace);
		iEntityHit = TR_GetEntityIndex(hTrace);
	}
	delete hTrace;
	
	if (bExact)
	{
		float fVector[3];
		MakeVectorFromPoints(fGivenHitPos, fGivenPos, fVector);
		NormalizeVector(fVector, fVector);
		
		ScaleVector(fVector, 15.0);
		AddVectors(fGivenHitPos, fVector, fGivenHitPos);
	}
	
	return iEntityHit;
}

public bool ExcludeSelfAndAlive(int entity, int contentsMask, any data)
{
	if (entity == data) 
	{
		return false; 
	}
	else if (entity > 0 && entity <= MaxClients)
	{
		if (IsClientInGame(entity))
		{
			return false;
		}
	}
	
	return true;
}

float MeasureGroundDistance(int entity)
{
	if (!(GetEntityFlags(entity) & FL_ONGROUND))
	{
		float fEntityOrigin[3], fEntityPos[3], fBelowAngle[3] = { 90.0, 0.0, 0.0 }, f_Units;
		
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fEntityOrigin);
		
		Handle hTrace = TR_TraceRayFilterEx(fEntityOrigin, fBelowAngle, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, ExcludeSelfAndAlive, entity);
		if (TR_DidHit(hTrace))
		{
			TR_GetEndPosition(fEntityPos, hTrace);
			
			f_Units = fEntityOrigin[2] - fEntityPos[2];
		}
		delete hTrace;
		return f_Units;
	}
	
	return 0.0;
}

void MeteorFallExplosion(int entity, int client)
{
	if (!IsValidEnt(entity))
	{
		return;
	}
	
	char sEntityClass[64];
	GetEdictClassname(entity, sEntityClass, sizeof(sEntityClass));
	if (!StrEqual(sEntityClass, "tank_rock", true))
	{
		return;
	}
	
	float fEntityPos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fEntityPos);
	fEntityPos[2] += 50.0;
	
	DeleteEntity(entity);
	
	int iExplodeEnt = CreateEntityByName("prop_physics"); 		
	DispatchKeyValue(iExplodeEnt, "model", "models/props_junk/propanecanister001a.mdl");
	
	TeleportEntity(iExplodeEnt, fEntityPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iExplodeEnt);
	ActivateEntity(iExplodeEnt);
	
	AcceptEntityInput(iExplodeEnt, "Break");
	RemoveEdict(iExplodeEnt);
	
	int iHurtEnt = CreateEntityByName("point_hurt");
	DispatchKeyValueFloat(iHurtEnt, "Damage", fMeteorFallDamage);
	DispatchKeyValue(iHurtEnt, "DamageType", "2");
	DispatchKeyValue(iHurtEnt, "DamageDelay", "0.0");
	DispatchKeyValueFloat(iHurtEnt, "DamageRadius", 200.0);
	
	TeleportEntity(iHurtEnt, fEntityPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iHurtEnt);
	ActivateEntity(iHurtEnt);
	
	AcceptEntityInput(iHurtEnt, "Hurt", client);
	DeleteEntity(iHurtEnt);
	
	int iPushEnt = CreateEntityByName("point_push");
  	DispatchKeyValueFloat(iPushEnt, "magnitude", 600.0);
	DispatchKeyValueFloat(iPushEnt, "radius", 200.0 * 1.0);
	
  	SetVariantString("spawnflags 24");
	AcceptEntityInput(iPushEnt, "AddOutput");
	
	TeleportEntity(iPushEnt, fEntityPos, NULL_VECTOR, NULL_VECTOR);
 	DispatchSpawn(iPushEnt);
	ActivateEntity(iPushEnt);
	
 	AcceptEntityInput(iPushEnt, "Enable", -1, -1);
	DeleteEntity(iPushEnt);
}

void ShowParticle(float fParticlePos[3], float fParticleAngle[3], char[] sParticle, float fParticleDuration)
{
	int iParticle = CreateEntityByName("info_particle_system");
	if (iParticle != -1)
	{
		DispatchKeyValue(iParticle, "effect_name", sParticle);
		
		TeleportEntity(iParticle, fParticlePos, fParticleAngle, NULL_VECTOR);
		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		
		AcceptEntityInput(iParticle, "Start");
		
		CreateTimer(fParticleDuration, RemoveParticle, iParticle);
	}
}

void PlaySound(char[] sSound, float fSoundPos[3])
{
	fSoundPos[2] += 200.0;
	EmitAmbientSound(sSound, fSoundPos, SOUND_FROM_WORLD, SNDLEVEL_HELICOPTER, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
}

float GetPlayerTemporaryHP(int client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsClientObserver(client))
	{
		return 0.0;
	}
	
	float fTemporaryHP, fHealthBuffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	
	if (fHealthBuffer <= 0.0)
	{
		fTemporaryHP = 0.0;
	}
	else
	{
		float fHealthBufferTime = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime"),
			fTemporaryHPDecay = 1.0 / FindConVar("pain_pills_decay_rate").FloatValue;
		
		fTemporaryHP = fHealthBuffer - (fHealthBufferTime / fTemporaryHPDecay);
	}
	
	if (fTemporaryHP < 0.0)
	{
		fTemporaryHP = 0.0;
	}
	
	return float(RoundToFloor(fTemporaryHP));
}

void GivePetOrder(int client, int iOrder)
{
	if (!IsValidEnt(iPetEnt[client]))
	{
		return;
	}
	
	switch (iOrder)
	{
		case 0:
		{
			float fPetOwnerPos[3], fTargetPos[3];
			
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPetOwnerPos);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fTargetPos);
					
					if (GetVectorDistance(fPetOwnerPos, fTargetPos) <= fPetProtectRange)
					{
						iPetTarget[iPetEnt[client]] = i;
						break;
					}
				}
			}
		}
		case 1:
		{
			bool bPetSwitch = false;
			
			float fPetOwnerPos[3], fPetOwnerVec[3], fPetPos[3], fPetAngle[3], fPetVelocity[3];
			
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPetOwnerPos);
			fPetOwnerPos[2] += fPetHeight;
			
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_vecOrigin", fPetPos);
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_angRotation", fPetAngle);
			
			fPetPos[2] -= 3000.0;
			
			if (GetAngleBetweenVector(iPetEnt[client], client) > 30.0)
			{
				if (bIsPetHovering[iPetEnt[client]])
				{
					fPetAngle[1] += 20.0;
				}
				else
				{
					fPetAngle[1] -= 20.0;
				}
				bPetSwitch = true;
			}
			else
			{
				if (GetVectorDistance(fPetPos, fPetOwnerPos) > 50.0)
				{
					MakeVectorFromPoints(fPetPos, fPetOwnerPos, fPetOwnerVec);
					NormalizeVector(fPetOwnerVec, fPetOwnerVec);
					GetVectorAngles(fPetOwnerVec, fPetAngle);
				}
			}
			
			if (fPetPos[2] < fPetOwnerPos[2])
			{
				fPetAngle[0] = -10.0;
				
				GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(fPetVelocity, fPetVelocity);
				
				fPetAngle[0] = 0.0;
			}
			else if (fPetPos[2] > fPetOwnerPos[2] + 15.0)
			{
				fPetAngle[0] = 10.0;
				
				GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(fPetVelocity, fPetVelocity);
				
				fPetAngle[0] = 0.0;
			}
			else
			{
				fPetAngle[0] = 0.0;
				
				GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(fPetVelocity, fPetVelocity);
			}
			
			if (bPetSwitch)
			{
				ScaleVector(fPetVelocity, 120.0);
			}
			else
			{
				ScaleVector(fPetVelocity, 230.0);
			}
			
			TeleportEntity(iPetEnt[client], NULL_VECTOR, fPetAngle, fPetVelocity);
		}
		case 2:
		{
			float fPetOwnerPos[3], fPetPos[3], fPetAngle[3], fPetVelocity[3];
			
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPetOwnerPos);
			fPetOwnerPos[2] += fPetHeight;
			
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_vecOrigin", fPetPos);
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_angRotation", fPetAngle);
			
			fPetPos[2] -= 3000.0;
			
			if (GetAngleBetweenVector(iPetEnt[client], client) > 15.0)
			{
				if (bIsPetHovering[iPetEnt[client]])
				{
					fPetAngle[1] += 15.0;
				}
				else
				{
					fPetAngle[1] -= 15.0;
				}
			}
			else
			{
				if (GetVectorDistance(fPetOwnerPos, fPetPos) > 50.0)
				{
					MakeVectorFromPoints(fPetPos, fPetOwnerPos, fPetVelocity);
					NormalizeVector(fPetVelocity, fPetVelocity);
					GetVectorAngles(fPetVelocity, fPetAngle);
				}
				else
				{
					if (bIsPetHovering[iPetEnt[client]])
					{
						bIsPetHovering[iPetEnt[client]] = false;
					}
					else
					{
						bIsPetHovering[iPetEnt[client]] = true;
					}
					
					if (bIsPetHovering[iPetEnt[client]])
					{
						fPetAngle[1] += 15.0;
					}
					else
					{
						fPetAngle[1] -= 15.0;
					}
					TeleportEntity(iPetEnt[client], NULL_VECTOR, fPetAngle, NULL_VECTOR);
					
					if (bIsPetHovering[iPetEnt[client]])
					{
						fPetAngle[1] += 15.0;
					}
					else
					{
						fPetAngle[1] -= 15.0;
					}
				}
			}
			
			if (fPetPos[2] < fPetOwnerPos[2])
			{
				fPetAngle[0] = -10.0;
				
				GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(fPetVelocity, fPetVelocity);
				
				fPetAngle[0] = 0.0;
			}
			else if (fPetPos[2] > fPetOwnerPos[2] + 15.0)
			{
				fPetAngle[0] = 10.0;
				
				GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(fPetVelocity, fPetVelocity);
				
				fPetAngle[0] = 0.0;
			}
			else
			{
				fPetAngle[0] = 0.0;
				
				GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(fPetVelocity, fPetVelocity);
			}
			ScaleVector(fPetVelocity, 60.0);
			
			TeleportEntity(iPetEnt[client], NULL_VECTOR, fPetAngle, fPetVelocity);
		}
	}
}

float GetAngleBetweenVector(int entity, int client)
{
	if (!IsValidEnt(entity))
	{
		return 0.0;
	}
	
	float fPetPos[3], fPetAngle[3], fPetOwnerPos[3], fOutput, fDirectory[3];
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fPetPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", fPetAngle);
	
	fPetAngle[0] = 0.0;
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPetOwnerPos);
	
	GetAngleVectors(fPetAngle, fDirectory, NULL_VECTOR, NULL_VECTOR);
	
	fPetPos[0] = fPetOwnerPos[0] - fPetPos[0];
	fPetPos[1] = fPetOwnerPos[1] - fPetPos[1];
	fPetPos[2] = 0.0;
	
	fDirectory[2] = 0.0;
	
	NormalizeVector(fDirectory, fDirectory);
	ScaleVector(fPetPos, 1 / SquareRoot(fPetPos[0] * fPetPos[0] + fPetPos[1] * fPetPos[1] + fPetPos[2] * fPetPos[2]));
	
	fOutput = ArcCosine(fPetPos[0] * fDirectory[0] + fPetPos[1] * fDirectory[1] + fPetPos[2] * fDirectory[2]);
	return RadToDeg(fOutput);
}

void AlignPetToTarget(int client)
{
	if (!IsValidEnt(iPetEnt[client]) || iPetTarget[iPetEnt[client]] == 0)
	{
		return;
	}
	
	float fPetOwnerPos[3], fPetTargetPos[3], fPetPos[3], fPetAngle[3], fPetVelocity[3], fVector[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPetOwnerPos);
	fPetOwnerPos[2] += fPetHeight;
	
	GetEntPropVector(iPetEnt[client], Prop_Send, "m_vecOrigin", fPetPos);
	fPetPos[2] -= 3000.0;
	
	GetEntPropVector(iPetTarget[iPetEnt[client]], Prop_Send, "m_vecOrigin", fPetTargetPos);
	
	MakeVectorFromPoints(fPetPos, fPetTargetPos, fVector);
	NormalizeVector(fVector, fVector);
	GetVectorAngles(fVector, fPetAngle);
	
	if (fPetPos[2] < fPetOwnerPos[2])
	{
		fPetAngle[0] = -80.0;
		
		GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(fPetVelocity, fPetVelocity);
		
		fPetAngle[0] = 0.0;
		
		ScaleVector(fPetVelocity, 10.0);
	}
	else if (fPetPos[2] > fPetOwnerPos[2] + 15.0)
	{
		fPetAngle[0] = 80.0;
		
		GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(fPetVelocity, fPetVelocity);
		
		fPetAngle[0] = 0.0;
		
		ScaleVector(fPetVelocity, 10.0);
	}
	else
	{
		fPetAngle[0] = 0.0;
		
		GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(fPetVelocity, fPetVelocity);
		
		ScaleVector(fPetVelocity, 1.0);
	}
	
	TeleportEntity(iPetEnt[client], NULL_VECTOR, fPetAngle, fPetVelocity);
}

bool TraceFireCollision(int client)
{
	if (!IsValidEnt(iPetEnt[client]))
	{
		return false;
	}
	
	float fPetPos[2][3], fPetAngle[3], fPetVelocity[3];
	
	GetEntPropVector(iPetEnt[client], Prop_Send, "m_vecOrigin", fPetPos[0]);
	fPetPos[0][2] -= 2990.0;
	
	GetEntPropVector(iPetEnt[client], Prop_Send, "m_vecOrigin", fPetPos[1]);
	fPetPos[1][2] += 30.0;
	
	MakeVectorFromPoints(fPetPos[0], fPetPos[1], fPetVelocity);
	NormalizeVector(fPetVelocity, fPetVelocity);
	GetVectorAngles(fPetVelocity, fPetAngle);
	
	Handle hTrace = TR_TraceRayFilterEx(fPetPos[0], fPetAngle, MASK_SHOT, RayType_Infinite, FilterAlliesAndSelf, GetClientUserId(client));
	if (TR_DidHit(hTrace))
	{
		if (IsValidEntity(TR_GetEntityIndex(hTrace)))
		{
			delete hTrace;
			return true;
		}
	}
	delete hTrace;
	return false;
}

public bool FilterAlliesAndSelf(int entity, int contentsMask, any data)
{
	if (IsValidEntity(entity))
	{
		int ally = GetClientOfUserId(data);
		if (IsSurvivor(ally))
		{
			return false;
		}
		else if (entity == iPetExtras[iPetEnt[ally]][0] || entity == iPetExtras[iPetEnt[ally]][1])
		{
			return false;
		}
	}
	
	return true;
}

void MakePetFire(int client, int iFireType)
{
	if (!IsValidEnt(iPetEnt[client]) || iPetTarget[iPetEnt[client]] == 0)
	{
		return;
	}
	
	switch (iFireType)
	{
		case 0:
		{
			float fPetPos[3], fPetAngle[3], fPetTargetPos[3], fPetTargetAng[3];
			
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_vecOrigin", fPetPos);
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_angRotation", fPetAngle);
			
			fPetPos[2] -= 3000.0;
			
			GetEntPropVector(iPetTarget[iPetEnt[client]], Prop_Send, "m_vecOrigin", fPetTargetPos);
			GetEntPropVector(iPetTarget[iPetEnt[client]], Prop_Send, "m_angRotation", fPetTargetAng);
			
			fPetTargetPos[2] += 40.0;
			
			TE_SetupBloodSprite(fPetTargetPos, fPetTargetAng, view_as<int>({255, 15, 15, 255}), 3, iSprite[2], iSprite[3]);
			TE_SendToAll();
			
			TE_SetupMuzzleFlash(fPetPos, fPetAngle, 2.0, 1);
			TE_SendToAll();
			
			char sTemp[16];
			
			int iParticleTarget = CreateEntityByName("info_particle_target"),
				iParticle = CreateEntityByName("info_particle_system");
			
			if (iParticleTarget != -1 && iParticle != -1 && IsValidEntity(iParticleTarget) && IsValidEntity(iParticle))
			{
				Format(sTemp, sizeof(sTemp), "cptarget%d", iParticleTarget);
				DispatchKeyValue(iParticleTarget, "targetname", sTemp);
				
				TeleportEntity(iParticleTarget, fPetTargetPos, NULL_VECTOR, NULL_VECTOR); 
				ActivateEntity(iParticleTarget);
				
				DispatchKeyValue(iParticle, "effect_name", sNAPParticles[9]);
				DispatchKeyValue(iParticle, "cpoint1", sTemp);
				
				TeleportEntity(iParticle, fPetPos, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(iParticle);
				ActivateEntity(iParticle);
				
				AcceptEntityInput(iParticle, "Start");
				CreateTimer(0.01, RemoveParticle, iParticle);
				
				DeleteEntity(iParticleTarget);
			}
			
			DealPetDamage(GetEntProp(iPetEnt[client], Prop_Send, "m_hOwnerEntity"), iPetTarget[iPetEnt[client]], 25);
			EmitSoundToAll(sNAPSounds[20], iPetEnt[client], SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
		}
		case 1:
		{
			float fPetTargetPos[3], fPetPos[3], fPetAngle[3], fPetVelocity[3];
			
			GetEntPropVector(iPetTarget[iPetEnt[client]], Prop_Send, "m_vecOrigin", fPetTargetPos);
			fPetTargetPos[2] += 30.0;
			
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_vecOrigin", fPetPos);
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_angRotation", fPetAngle);
			
			fPetPos[2] -= 3000.0;
			
			int iMissileBody = CreateEntityByName("molotov_projectile");
			if (iMissileBody != -1)
			{
				DispatchKeyValueVector(iMissileBody, "origin", fPetPos);
				DispatchKeyValueVector(iMissileBody, "angles", fPetAngle);
				
				DispatchKeyValue(iMissileBody, "targetname", "nap-l4d2_pet_missile");
				DispatchKeyValue(iMissileBody, "model", sNAPModels[0]);
				DispatchSpawn(iMissileBody);
				
				SetEntProp(iMissileBody, Prop_Send, "m_hOwnerEntity", client);
				
				SetEntPropFloat(iMissileBody, Prop_Send, "m_flModelScale", 0.001);
				SetEntityGravity(iMissileBody, 0.01);
			}
			
			float fSteamOrigin[3], fSteamAngle[3];
			
			fSteamOrigin[0] = 0.0; fSteamOrigin[1] = 0.0; fSteamOrigin[2] = 0.0;
			fSteamAngle[0] = 0.0; fSteamAngle[1] = 180.0; fSteamAngle[2] = 0.0;
			
			int iMissileSteam = CreateEntityByName("env_steam");
			if (iMissileSteam != -1)
			{
				DispatchKeyValue(iMissileSteam, "targetname", "nap-l4d2_pet_missile");
				
				DispatchKeyValue(iMissileSteam, "spawnflags", "1");
				DispatchKeyValue(iMissileSteam, "Type", "0");
				DispatchKeyValue(iMissileSteam, "InitialState", "1");
				DispatchKeyValue(iMissileSteam, "Spreadspeed", "10");
				DispatchKeyValue(iMissileSteam, "Speed", "200");
				DispatchKeyValue(iMissileSteam, "Startsize", "5");
				DispatchKeyValue(iMissileSteam, "EndSize", "30");
				DispatchKeyValue(iMissileSteam, "Rate", "555");
				DispatchKeyValue(iMissileSteam, "RenderColor", "60 80 200");
				DispatchKeyValue(iMissileSteam, "JetLength", "10.0"); 
				DispatchKeyValue(iMissileSteam, "RenderAmt", "180");
				
				SetVariantString("!activator");
				AcceptEntityInput(iMissileSteam, "SetParent", iMissileBody, iMissileSteam);
				
				TeleportEntity(iMissileSteam, fSteamOrigin, fSteamAngle, NULL_VECTOR);
				DispatchSpawn(iMissileSteam);
				
				AcceptEntityInput(iMissileSteam, "TurnOn");
			}
			
			float fAttachmentPos[3], fAttachmentAngle[3], fMissileDirectory[3];
			
			fMissileDirectory[0] = 50.0; fMissileDirectory[1] = 0.0; fMissileDirectory[2] = 0.0;
			
			GetEntPropVector(iMissileBody, Prop_Send, "m_vecOrigin", fAttachmentPos);
			GetEntPropVector(iMissileBody, Prop_Send, "m_angRotation", fAttachmentAngle);
			
			int iMissileAttachment = CreateEntityByName("prop_dynamic_override");
			if (iMissileAttachment != -1)
			{
				DispatchKeyValueVector(iMissileAttachment, "origin", fAttachmentPos);
				DispatchKeyValueVector(iMissileAttachment, "angles", fAttachmentAngle);
				
				DispatchKeyValue(iMissileAttachment, "targetname", "nap-l4d2_pet_missile");
				DispatchKeyValue(iMissileAttachment, "model", sNAPModels[3]);
				
				DispatchKeyValueFloat(iMissileAttachment, "fademindist", 10000.0);
				DispatchKeyValueFloat(iMissileAttachment, "fademaxdist", 20000.0);
				DispatchKeyValueFloat(iMissileAttachment, "fadescale", 0.0); 
				
				SetVariantString("!activator");
				AcceptEntityInput(iMissileAttachment, "SetParent", iMissileBody, iMissileAttachment);
				
				TeleportEntity(iMissileAttachment, fAttachmentPos, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(iMissileAttachment);
				
				SetEntProp(iMissileAttachment, Prop_Send, "m_nMinGPULevel", 1);
				SetEntProp(iMissileAttachment, Prop_Send, "m_nMaxGPULevel", 1);
				
				SetEntPropFloat(iMissileAttachment, Prop_Send, "m_flModelScale", 0.07);
			}
			
			SDKHook(iMissileBody, SDKHook_TouchPost, OnPetMissileTouchPost);
			
			fPetPos[0] += GetRandomFloat(-20.0, 20.0);
			fPetPos[1] += GetRandomFloat(-20.0, 20.0);
			fPetPos[2] += GetRandomFloat(-10.0, 5.0);
			
			MakeVectorFromPoints(fPetPos, fPetTargetPos, fPetVelocity);
			NormalizeVector(fPetVelocity, fPetVelocity);
			GetVectorAngles(fPetVelocity, fPetAngle);
			
			ScaleVector(fPetVelocity, 500.0);
			
			TeleportEntity(iMissileBody, NULL_VECTOR, fPetAngle, fPetVelocity);
		}
		case 2:
		{
			float fPetTargetPos[3], fPetPos[3], fPetAngle[3], fPetVelocity[3], fGrenadeDistance;
			
			GetEntPropVector(iPetTarget[iPetEnt[client]], Prop_Send, "m_vecOrigin", fPetTargetPos);
			
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_vecOrigin", fPetPos);
			GetEntPropVector(iPetEnt[client], Prop_Send, "m_angRotation", fPetAngle);
			
			fPetPos[2] -= 3000.0;
			
			int iGrenadeEnt = CreateEntityByName("grenade_launcher_projectile");
			if (iGrenadeEnt != -1)
			{
				DispatchKeyValueVector(iGrenadeEnt, "origin", fPetPos);
				DispatchKeyValueVector(iGrenadeEnt, "angles", fPetAngle);
				
				DispatchKeyValue(iGrenadeEnt, "model", sNAPModels[2]);
				DispatchSpawn(iGrenadeEnt);
				
				SetEntProp(iGrenadeEnt, Prop_Send, "m_hOwnerEntity", client);
				SetEntityGravity(iGrenadeEnt, 1.0);
				
				SDKHook(iGrenadeEnt, SDKHook_TouchPost, OnPetGrenadeTouchPost);
				
				fPetPos[0] += GetRandomFloat(-40.0, 40.0);
				fPetPos[1] += GetRandomFloat(-40.0, 40.0);
				fPetPos[2] += GetRandomFloat(10.0, 15.0);
				
				fPetTargetPos[0] += GetRandomFloat(-40.0, 40.0);
				fPetTargetPos[1] += GetRandomFloat(-40.0, 40.0);
				fPetTargetPos[2] += GetRandomFloat(-20.0, 15.0);
				
				fGrenadeDistance = GetVectorDistance(fPetPos, fPetTargetPos);
				
				MakeVectorFromPoints(fPetPos, fPetTargetPos, fPetVelocity);
				NormalizeVector(fPetVelocity, fPetVelocity);
				GetVectorAngles(fPetVelocity, fPetAngle);
				
				fPetAngle[0] -= 45.0;
				
				GetAngleVectors(fPetAngle, fPetVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(fPetVelocity, fPetVelocity);
				
				ScaleVector(fPetVelocity, (fGrenadeDistance * 1.25));
				
				TeleportEntity(iGrenadeEnt, fPetPos, NULL_VECTOR, NULL_VECTOR);
				TeleportEntity(iGrenadeEnt, NULL_VECTOR, fPetAngle, fPetVelocity);
			}
		}
	}
}

public void OnPetMissileTouchPost(int entity, int other)
{	
	PetWeaponExplosion(entity);
	SDKUnhook(entity, SDKHook_TouchPost, OnPetMissileTouchPost);
	
	ExecuteCommand(_, "ent_fire", "nap-l4d2_pet_missile KillHierarchy");
}

public void OnPetGrenadeTouchPost(int entity, int other)
{
	PetWeaponExplosion(entity);
	SDKUnhook(entity, SDKHook_TouchPost, OnPetGrenadeTouchPost);
	
	DeleteEntity(entity);
}

void PetWeaponExplosion(int entity)
{
	if (!IsValidEnt(entity))
	{
		return;
	}
	
	float fExplosionPos[3], fTargetPos[2][3];
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fExplosionPos);
	
	TE_SetupExplosion(fExplosionPos, iSprite[4], 3.0, 1, 0, 10, 1000);
	TE_SendToAll();
	
	EmitSoundToAll(sNAPSounds[GetRandomInt(21, 22)], entity, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", fTargetPos[0]);
			
			if (GetVectorDistance(fExplosionPos, fTargetPos[0]) <= 50.0)
			{
				DealPetDamage(GetEntProp(entity, Prop_Send, "m_hOwnerEntity"), i, 50);
			}
		}
	}
	
	for (int i = 1; i < 2049; i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			char sEntityClass[64];
			GetEdictClassname(i, sEntityClass, sizeof(sEntityClass));
			if (StrEqual(sEntityClass, "infected", false) || StrEqual(sEntityClass, "witch", false))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fTargetPos[1]);
				
				if (GetVectorDistance(fExplosionPos, fTargetPos[1]) <= 50.0)
				{
					DealPetDamage(GetEntProp(entity, Prop_Send, "m_hOwnerEntity"), i, 50);
				}
			}
		}
	}
}

void DealPetDamage(int attacker, int victim, int iDamage)
{
	char sDamage[16];
	IntToString(iDamage, sDamage, sizeof(sDamage));
	
	int iPointHurt = CreateEntityByName("point_hurt");
	
	DispatchKeyValue(victim, "targetname", "hurtme");
	DispatchKeyValue(iPointHurt, "DamageTarget", "hurtme");
	DispatchKeyValue(iPointHurt, "Damage", sDamage);
	DispatchKeyValue(iPointHurt, "DamageType", "-2130706430");
	
	DispatchSpawn(iPointHurt);
	
	AcceptEntityInput(iPointHurt, "Hurt", attacker);
	DeleteEntity(iPointHurt);
	
	DispatchKeyValue(victim, "targetname", "donthurtme");
}

float GetFallHeight(int client)
{
	float fFallPos[3], fHeightAngle[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fFallPos);
	fHeightAngle[0] = 90.0; fHeightAngle[1] = 0.0; fHeightAngle[2] = 0.0;
	
	Handle hTrace = TR_TraceRayFilterEx(fFallPos, fHeightAngle, MASK_SHOT, RayType_Infinite, FilterEntities);
	
	float fTraceEnd[3];
	TR_GetEndPosition(fTraceEnd, hTrace);
	delete hTrace;
	
	return GetVectorDistance(fFallPos, fTraceEnd, false);
}

public bool FilterEntities(int entity, int contentsMask, any data)
{
	return (entity && IsValidEntity(entity));
}

void ProvideParachute(int client)
{
	if (IsValidEnt(iParachuteEnt[client]))
	{
		return;
	}
	
	AcceptEntityInput(client, "DisableLedgeHang");
	
	int iParachute = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(iParachute, "model", sNAPModels[GetRandomInt(4, 7)]);
	
	DispatchSpawn(iParachute);
	SetEntityMoveType(iParachute, MOVETYPE_NOCLIP);
	
	SetEntProp(iParachute, Prop_Send, "m_nMinGPULevel", 1);
	SetEntProp(iParachute, Prop_Send, "m_nMaxGPULevel", 1);
	
	iParachuteEnt[client] = iParachute;
}

void RemoveParachute(int client)
{
	if (!IsValidEnt(iParachuteEnt[client]))
	{
		return;
	}
	
	AcceptEntityInput(client, "EnableLedgeHang");
	
	SetEntityGravity(client, 1.0);
	L4D2_SetEntGlow(iParachuteEnt[client], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
	
	DeleteEntity(iParachuteEnt[client]);
	iParachuteEnt[client] = 0;
}

void BeginParachuteFall(int client)
{
	if (FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]") == -1 || !IsValidEnt(iParachuteEnt[client]))
	{
		return;
	}
	
	bool bIsFalling = false;
	float fParachuteVelocity[3], fFallSpeed = -100.0;
	
	GetEntDataVector(client, FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]"), fParachuteVelocity);
	if (fParachuteVelocity[2] >= fFallSpeed)
	{
		bIsFalling = true;
	}
	
	if (fParachuteVelocity[2] < 0.0)
	{
		if (bIsFalling)
		{
			fParachuteVelocity[2] = fFallSpeed;
		}
		else
		{
			fParachuteVelocity[2] += 50.0;
		}
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fParachuteVelocity);
		
		SetEntDataVector(client, FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]"), fParachuteVelocity, true);
		SetEntityGravity(client, 0.1);
	}
}

bool IsDeployedAmmoPack(int entity)
{
	if (IsValidEnt(entity))
	{
		char sEntityClass[64];
		GetEdictClassname(entity, sEntityClass, sizeof(sEntityClass));
		return (StrEqual(sEntityClass, "upgrade_ammo_incendiary", false) || StrEqual(sEntityClass, "upgrade_ammo_explosive", false));
	}
	return false;
}

void FindBlurryFogs(bool bToggle = false)
{
	if (bToggle && IsValidEntRef(iBlurEnt[1]))
	{
		AcceptEntityInput(iBlurEnt[1], "Disable");
		AcceptEntityInput(iBlurEnt[1], "Enable");
	}
	
	int iFogEnt = -1;
	while ((iFogEnt = FindEntityByClassname(iFogEnt, "fog_volume")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(iFogEnt) || iFogEnt == iBlurEnt[1])
		{
			break;
		}
		
		if (bToggle)
		{
			if (GetEntProp(iFogEnt, Prop_Data, "m_bDisabled") == 0)
			{
				AcceptEntityInput(iFogEnt, "Enable");
			}
		}
		else
		{
			SetEntProp(iFogEnt, Prop_Data, "m_iHammerID", GetEntProp(iFogEnt, Prop_Data, "m_bDisabled"));
			AcceptEntityInput(iFogEnt, "Disable");
		}
	}
}

int ChooseRandomSurvivor()
{
	int iSurvivorCount, iTotalSurvivors[MAXPLAYERS+1];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			iTotalSurvivors[iSurvivorCount++] = i;
		}
	}
	return (iSurvivorCount == 0) ? 0 : iTotalSurvivors[GetRandomInt(0, iSurvivorCount -1)];
}

void MoveForward(float fGivenPos[3], float fGivenAng[3], float fReturnPos[3], float fGivenDis)
{
	float fDirectory[3];
	GetAngleVectors(fGivenAng, fDirectory, NULL_VECTOR, NULL_VECTOR);
	
	fReturnPos = fGivenPos;
	
	fReturnPos[0] += fDirectory[0] * fGivenDis;
	fReturnPos[1] += fDirectory[1] * fGivenDis;
	fReturnPos[2] += fDirectory[2] * fGivenDis;
}

bool IsThirdPersonView(int client)
{
	if (GetEntProp(client, Prop_Send, "m_iObserverMode") == 1 || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") > 0 || 
		GetEntPropEnt(client, Prop_Send, "m_hViewEntity") > 0 || GetEntPropEnt(client, Prop_Send, "m_reviveTarget") > 0 || GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 || 
		GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 || GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 || GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 || 
		GetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView") > GetGameTime() || GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0)
	{
		return true;
	}
	
	switch (L4D2_GetPlayerUseAction(client))
	{
		case L4D2UseAction_Healing:
		{
			int iHealed = L4D2_GetPlayerUseActionTarget(client);
			if (iHealed == L4D2_GetPlayerUseActionOwner(client) || iHealed != client)
			{
				return true;
			}
		}
		case L4D2UseAction_Defibing, 6, 7, L4D2UseAction_PouringGas, L4D2UseAction_Cola, L4D2UseAction_Button: return true;
	}
	
	return false;
}

bool IsAccuratelyVisible(int client, int target, float fCheckAng = 180.0, float fCheckDis = 0.0, bool bGetHeight = false, bool bNegateAngle = false)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		return false;
	}
	
	if (!IsSurvivor(target) || !IsPlayerAlive(target))
	{
		return false;
	}
	
	if (fCheckAng < 0.0 || fCheckAng > 360.0)
	{
		return false;
	}
	
	float fCheckPos[2][3], fEyeAngles[3], fCheckVec[3], fCheckResult, fResultPos;
	
	GetClientEyeAngles(client, fEyeAngles);
	fEyeAngles[0] = fEyeAngles[2] = 0.0;
	
	GetAngleVectors(fEyeAngles, fEyeAngles, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(fEyeAngles, fEyeAngles);
	if (bNegateAngle)
	{
		NegateVector(fEyeAngles);
	}
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fCheckPos[0]);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", fCheckPos[1]);
	
	if (bGetHeight && fCheckDis > 0)
	{
		fResultPos = GetVectorDistance(fCheckPos[0], fCheckPos[1]);
	}
	fCheckPos[0][2] = fCheckPos[1][2] = 0.0;
	
	MakeVectorFromPoints(fCheckPos[0], fCheckPos[1], fCheckVec);
	NormalizeVector(fCheckVec, fCheckVec);
	
	fCheckResult = RadToDeg(ArcCosine(GetVectorDotProduct(fCheckVec, fEyeAngles)));
	if (fCheckResult > fCheckAng / 2)	
	{
		return false;
	}
	
	if (fCheckDis > 0)
	{
		if (!bGetHeight)
		{
			fResultPos = GetVectorDistance(fCheckPos[0], fCheckPos[1]);
		}
		
		if (fCheckDis < fResultPos)
		{
			return false;
		}
	}
	
	return true;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsInfected(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

stock bool IsValidEntRef(int entity)
{
	return (entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE);
}

stock void ExecuteCommand(int executer = 0, char[] sCommand, char[] sArguments)
{
	if (!executer || !IsClientInGame(executer))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				executer = i;
				break;
			}
		}
		if (!executer || !IsClientInGame(executer))
		{
			return;
		}
	}
	
	int iFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(executer, "%s %s", sCommand, sArguments);
	SetCommandFlags(sCommand, iFlags|FCVAR_CHEAT);
}

