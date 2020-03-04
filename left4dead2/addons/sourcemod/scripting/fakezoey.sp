/* Includes */
#pragma semicolon 1
#include <sourcemod>
#include <sceneprocessor>
#include <sdktools_functions>

#define PLUGIN_VERSION "1.0.0"

/* Plugin Information */ 
public Plugin:myinfo = { 
	name        = "Fake Zoey", 
	author        = "DeathChaos25", 
	description    = "Implements a fake Zoey makeup to Nick", 
	version        = PLUGIN_VERSION, 
	url        = "https://forums.alliedmods.net/showthread.php?t=258189" 
}

/* Huge thanks to machine and Mr.Zero, this plugin wouldn't have been possible without them! */

/* Globals */ 
#define DEBUG 0 /* Change this to 0 to disable debug info to be printed */ 
#define DEBUG_TAG "Fake Zoey" 
#define DEBUG_PRINT_FORMAT "[%s] %s"

static const String:MODEL_NICK[] 		= "models/survivors/survivor_gambler.mdl";
static const String:MODEL_ROCHELLE[] 		= "models/survivors/survivor_producer.mdl";
static const String:MODEL_COACH[] 		= "models/survivors/survivor_coach.mdl";
static const String:MODEL_ELLIS[] 		= "models/survivors/survivor_mechanic.mdl";
static const String:MODEL_BILL[] 		= "models/survivors/survivor_namvet.mdl";
static const String:MODEL_ZOEY[] 		= "models/survivors/survivor_teenangst.mdl";
static const String:MODEL_FRANCIS[] 		= "models/survivors/survivor_biker.mdl";
static const String:MODEL_LOUIS[] 		= "models/survivors/survivor_manager.mdl";

static const String:CONFIG_FAKEZOEY[]	= "data/fakezoey.cfg";
static String:sSavedScene[64];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder)); 
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!"); 
		return APLRes_Failure;
	}
	return APLRes_Success; 
}

static iDeathBody = 0;
static iDeathScene = 0;

static MODEL_LOUIS_INDEX;
static MODEL_FRANCIS_INDEX;
static MODEL_BILL_INDEX;

/* Plugin Functions */ 
public OnPluginStart() 
{
	HookEvent("lunge_pounce", LungePounce_Event);
	HookEvent("charger_pummel_start", ChargerPummelStart_Event);
	CreateTimer(1.0, TimerUpdate, _, TIMER_REPEAT);
	CreateConVar("l4d2_fake_zoey_version", PLUGIN_VERSION, "Current Version of Fake Zoey", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD); 
}
public OnMapStart()
{
	CheckModelPreCache(MODEL_NICK);
	CheckModelPreCache(MODEL_ROCHELLE);
	CheckModelPreCache(MODEL_COACH);
	CheckModelPreCache(MODEL_ELLIS);
	CheckModelPreCache(MODEL_BILL);
	CheckModelPreCache(MODEL_ZOEY);
	CheckModelPreCache(MODEL_FRANCIS);
	CheckModelPreCache(MODEL_LOUIS);
	
	MODEL_LOUIS_INDEX = PrecacheModel(MODEL_LOUIS, true);
	MODEL_FRANCIS_INDEX = PrecacheModel(MODEL_FRANCIS, true);
	MODEL_BILL_INDEX = PrecacheModel(MODEL_BILL, true);
}
stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile, true);
		PrintToServer("Precaching Model:%s",Modelfile);
	}
}
public OnSceneStageChanged(scene, SceneStages:stage)  
{  
	if (stage != SceneStage_Started || GetSceneInitiator(scene) == SCENE_INITIATOR_PLUGIN) /* Do not capture scenes spawned by the plugin, to prevent a loop */
	{
		return;
	}
	
	new actor = GetActorFromScene(scene);
	if (IsFakeZoey(actor)) 
	{
		decl String:sceneFile[MAX_SCENEFILE_LENGTH];
		GetSceneFile(scene, sceneFile, sizeof(sceneFile));
		CancelScene(scene);
		
		ReplaceScene(sceneFile, "fakezoey");
		if (StrEqual(sSavedScene, "0", false))
		{
			#if DEBUG
			Debug_PrintText("Not replacing scene (\"%s\") as no replacement scene (\"%s\", newSceneLen %d) can be found in trie.", sceneFile, sSavedScene);
			#endif
			return;
		} 
		
		/* new Float:preDelay = GetScenePreDelay(scene) */
		new Float:pitch = GetScenePitch(scene);
		
		#if DEBUG 
		Debug_PrintText("Cancelling old scene (\"%s\")...", sceneFile);
		#endif 
		
		#if DEBUG 
		Debug_PrintText("Performing new scene (\"%s\", preDelay %.2f, pitch %.2f)...", sSavedScene, preDelay, pitch);
		#endif 
		PerformSceneEx(actor, "", sSavedScene, 0.0, pitch); /* SCENE_INITIATOR_PLUGIN is default and does not need to be specified */
		#if DEBUG 
		Debug_PrintText("Scene replaced for fake Zoey actor %N!", actor);
		#endif
	}
	switch (stage) 
	{ 
		case SceneStage_Started: 
		{ 
			new client = GetActorFromScene(scene);
			if (IsSurvivor(client))
			{
				decl String:vocalize[MAX_VOCALIZE_LENGTH];
				if (GetSceneVocalize(scene, vocalize, sizeof(vocalize)) != 0) 
				{ 
					if (StrEqual(vocalize, "smartlook", false))
					{
						new target = GetClientAimTarget(client, true);
						if (IsFakeZoey(target))
							CancelScene(scene);
					}
				} 
			}
		}
	}
}

stock ReplaceScene(String:sScene[], String:sCharacter[])
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_FAKEZOEY);
	if (!FileExists(sPath))
	{
		PrintToServer("[FakeZoey] Error: Cannot read the config %s", sPath);
		return;
	}
	// Get scenes from config
	new Handle:hFile = CreateKeyValues("scenes");
	if (!FileToKeyValues(hFile, sPath))
	{
		PrintToServer("[FakeZoey] Error: Failed to get scenes from %s", sPath);
		CloseHandle(hFile);
		return;
	}
	// Check the character to get scene info from
	if (!KvJumpToKey(hFile, sCharacter))
	{
		PrintToServer("[FakeZoey] Error: Failed to get character from %s", sPath);
		CloseHandle(hFile);
		return;
	}
	// Retrieve how many scenes for this character
	new maxscenes = KvGetNum(hFile, "max_scenes", 0);
	if (maxscenes == 0)
	{
		PrintToServer("[FakeZoey] Error: Failed to get max_scenes from %s", sPath);
		CloseHandle(hFile);
		return;
	}
	// Get the scene replacement info
	decl String:sTemp[10], String:sSceneTemp[64];
	for (new i=1; i<=maxscenes; i++)
	{
		IntToString(i, sTemp, sizeof(sTemp));
		if (KvJumpToKey(hFile, sTemp))
		{
			KvGetString(hFile, "scene", sSceneTemp, sizeof(sSceneTemp));
			if (StrEqual(sScene, sSceneTemp, false))
			{
				KvGetString(hFile, "replace", sSavedScene, sizeof(sSavedScene));
				CloseHandle(hFile);
				return;
			}
			//if we are to the end of all the scenes
			if (i == maxscenes)
			{
				sSavedScene = "0";
			}
			KvGoBack(hFile);
		}
	}
	CloseHandle(hFile);
}


/* "A Hunter's got Zoey!"
* Here, A few things are done, all of them related to Hunters having pounced a Survivor.
* 
* First, we prevent the L4D2 survivors from saying "Hunter's got Nick!
* When our Fake Zoey gets pounced by a Hunter While Instead giving them
* the generic Hunter Pounced Line they would use for Rochelle
* From Dead Center, the lines being, "One of those things got her!" (not yet implemented)
* 
* 
* Then we also allow the L4D1 survivors to warn for Zoey getting pounced (done)
* 
* And Finally, our Fake Zoey will also warn if a fellow L4D1 Survivor gets pounced (not yet implemented)*/

public LungePounce_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (IsFakeZoey(client))
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsSurvivor(i) && IsPlayerAlive(i))
			{
				decl String:model[PLATFORM_MAX_PATH];
				GetClientModel(i, model, sizeof(model));
				
				/* L4D1 Survivors warn "Hunter's on Zoey!" if she's the victim*/
				new random = GetRandomInt(1,6);
				if (StrEqual(model, MODEL_FRANCIS, false))
				{
					switch(random)
					{
						case 1: PerformSceneEx(i, "", "scenes/Biker/HunterZoeyPounced01.vcd");
						case 2: PerformSceneEx(i, "", "scenes/Biker/HunterZoeyPounced02.vcd");
						case 3: PerformSceneEx(i, "", "scenes/Biker/HunterZoeyPounced03.vcd");
						default: return;
					}
				}
				else if (StrEqual(model, MODEL_BILL, false))
				{
					switch(random)
					{
						case 1: PerformSceneEx(i, "", "scenes/Namvet/HunterZoeyPounced01.vcd");
						case 2: PerformSceneEx(i, "", "scenes/Namvet/HunterZoeyPounced02.vcd");
						case 3: PerformSceneEx(i, "", "scenes/Namvet/HunterZoeyPounced03.vcd");
						default: return;
					}
				}
				else if (StrEqual(model, MODEL_LOUIS, false))
				{
					switch(random)
					{
						case 1: PerformSceneEx(i, "", "scenes/manager/HunterZoeyPounced01.vcd");
						case 2: PerformSceneEx(i, "", "scenes/manager/HunterZoeyPounced02.vcd");
						case 3: PerformSceneEx(i, "", "scenes/manager/HunterZoeyPounced03.vcd");
						default: return;
					}
				}
				/* And Nick too since he otherwise won't recognize our Fake Zoey */
				else if (StrEqual(model, MODEL_NICK, false))
				{
					switch(random)
					{
						case 1: PerformSceneEx(i, "", "scenes/Gambler/HunterPouncedC1Producer01.vcd");
						case 2: PerformSceneEx(i, "", "scenes/Gambler/HunterPouncedC1Producer02.vcd");
						default: return;
					}
				}
				/* Since Rochelle contains no possible lines to warn for Zoey,
				* we can re-use the ToTheRescue lines instead ;p*/
				else if (StrEqual(model, MODEL_ROCHELLE, false))
				{
					switch(random)
					{
						case 1: PerformSceneEx(i, "", "scenes/producer/totherescue01.vcd");
						case 2: PerformSceneEx(i, "", "scenes/producer/totherescue02.vcd");
						case 3: PerformSceneEx(i, "", "scenes/producer/totherescue03.vcd");
						case 4: PerformSceneEx(i, "", "scenes/producer/totherescue04.vcd");
						case 5: PerformSceneEx(i, "", "scenes/producer/totherescue05.vcd");
						case 6: PerformSceneEx(i, "", "scenes/producer/totherescue06.vcd");
						default: return;
					}
				}
			}
		}
	}
	
	else if (IsClientNick(client))
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsSurvivor(i) && IsPlayerAlive(i))
			{
				decl String:model[PLATFORM_MAX_PATH];
				GetClientModel(i, model, sizeof(model));
				
				/* L4D2 Survivors warn "Hunter's on Nick!" because these lines had to be
				*  hunted and cancelled so we could differentiate Nick from our Fake Zoey*/
				new random = GetRandomInt(1,3);
				if (StrEqual(model, MODEL_ELLIS, false))
				{
					switch(random)
					{
						case 1: PerformSceneEx(i, "", "scenes/mechanic/hunternickpounced01.vcd");
						case 2: PerformSceneEx(i, "", "scenes/mechanic/hunternickpounced02.vcd");
						default: return;
					}
				}
				else if (StrEqual(model, MODEL_COACH, false))
				{
					switch(random)
					{
						case 1: PerformSceneEx(i, "", "scenes/coach/hunternickpounced01.vcd");
						case 2: PerformSceneEx(i, "", "scenes/coach/hunternickpounced02.vcd");
						default: return;
					}
				}
				else if (StrEqual(model, MODEL_ROCHELLE, false))
				{
					switch(random)
					{
						case 1: PerformSceneEx(i, "", "scenes/producer/hunternickpounced01.vcd");
						case 2: PerformSceneEx(i, "", "scenes/producer/hunternickpounced02.vcd");
						default: return;
					}
				}
				else if (StrEqual(model, MODEL_NICK, false))
				{
					if (client != i)
					{
						switch(random)
						{
							case 1: PerformSceneEx(i, "", "scenes/Gambler/HunterPouncedC101.vcd");
							case 2: PerformSceneEx(i, "", "scenes/Gambler/HunterPouncedC102.vcd");
							case 3: PerformSceneEx(i, "", "scenes/Gambler/HunterPouncedC103.vcd");
							default: return;
						}
					}
				}
			}
		}
	}
}

/* "That Charger's just beating the shit outta Nick..." */
public ChargerPummelStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (IsSurvivor(client))
	{
		decl String:model[PLATFORM_MAX_PATH];
		GetClientModel(client, model, sizeof(model));
		if (StrEqual(model, MODEL_NICK, false))
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsSurvivor(i) && IsPlayerAlive(i)) 
				{	
					GetClientModel(i, model, sizeof(model));
					if (StrEqual(model, MODEL_ZOEY, false))
					{
						PerformSceneEx(i, "", "scenes/TeenGirl/DLC1_C6M3_L4D11stSpot07.vcd");
					}
				}
			}
		}
	}
}

stock bool:IsFakeZoey(client)
{
	if (IsSurvivor(client))
	{
		new character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (character == 0)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_ZOEY, false))
			{
				return true;
			}
		}
	}
	return false;
}
stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}
stock bool:IsClientNick(client) 
{
	if (IsSurvivor(client))
	{
		new character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (character == 0)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_NICK, false))
			{
				return true;
			}
		}
	}
	return false;
}

public Action:TimerUpdate(Handle:timer)
{
	if (!IsServerProcessing()) return Plugin_Continue;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsFakeZoey(i))
		{
			decl Float:Origin[3], Float:TOrigin[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", Origin);
			if (iDeathBody == 0 && iDeathScene == 0)
			{
				new entity = -1;
				while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE)
				{
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(Origin, TOrigin);
					if (distance <= 80.0)
					{
						iDeathBody = entity;
						MournSurvivor(i);
						iDeathScene = 1;
					}
				}
			}
			else if (iDeathBody > 0 && iDeathScene == 0)
			{
				if (IsValidEntity(iDeathBody))
				{
					GetEntPropVector(iDeathBody, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(Origin, TOrigin);
					if (distance <= 80.0)
					{
						MournSurvivor(i);
						iDeathScene = 1;
					}
				}
				else
				{
					iDeathBody = 0;
					iDeathScene = 0;
				}
			}
			else if (iDeathBody > 0 && iDeathScene > 0)
			{
				if (IsValidEntity(iDeathBody))
				{
					GetEntPropVector(iDeathBody, Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(Origin, TOrigin);
					if (distance > 120.0)
					{
						iDeathBody = 0;
						iDeathScene = 0;
					}
				}
				else
				{
					iDeathBody = 0;
					iDeathScene = 0;
				}
			}	
		}
	}
	return Plugin_Continue;
}

stock MournSurvivor(client)
{
	if (IsFakeZoey(client) && iDeathBody > 0 && IsValidEntity(iDeathBody))
	{
		new random = GetRandomInt(1,5);
		new index = GetEntProp(iDeathBody, Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch(random)
			{
				case 1: PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager03.vcd");
				case 2: PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager08.vcd");
				case 3: PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager09.vcd");
				case 4: PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager11.vcd");
				case 5: PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager12.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch(random)
			{
				case 1: PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet02.vcd");
				case 2: PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet03.vcd");
				case 3: PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet04.vcd");
				case 4: PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet07.vcd");
				case 5: PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet11.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch(random)
			{
				case 1: PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker04.vcd");
				case 4: PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker06.vcd");
				case 5: PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker07.vcd");
			}
		}
	}
}

#if DEBUG 
stock Debug_PrintText(const String:format[], any:...) 
{ 
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	LogMessage(buffer);
	
	new AdminId:adminId;
	for (new client=1; client<=MaxClients; client++)
	{ 
		if (!IsClientInGame(client) || IsFakeClient(client))
		{ 
			continue;
		} 
		adminId = GetUserAdmin(client) 
		if (adminId == INVALID_ADMIN_ID || !GetAdminFlag(adminId, Admin_Root))
		{ 
			continue;
		}
		PrintToChat(client, DEBUG_PRINT_FORMAT, DEBUG_TAG, buffer);
	} 
}
#endif
