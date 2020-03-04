#include <sourcemod>
#include <sdktools>
#include <BuiltinVotes>
#include <BuiltinVotes.ext.2.l4d2_fix>
#pragma semicolon 1

#define CVAR_FLAGS					FCVAR_NOTIFY

public Plugin:myinfo = 
{
	name = "L4D2_VoteChangeMission(Unofficial)",
	author = "MicroLeo",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

static const String:DefaultMap[][] = 	
{ 
	"c1m4_atrium"
};

static Handle:VoteChangeMission[4];
static bool:IsUnofficialMap;

static Handle:MapDataPack_MapCode[33];
static Handle:MapDataPack_MapName[33];

static String:TargetMap_Code[128];
static String:TargetMap_Name[128];

static Handle:g_Vote;

static String:OldMapName[128];

public OnPluginStart()
{
	// Add your own code here...
	VoteChangeMission[0] = CreateConVar("l4d2_VoteChangeUnofficialMission_Plugin_Enabled","1","是否开启插件(Enable or Disable Plugin) 1/0", CVAR_FLAGS,true,0.0,true,1.0);
	VoteChangeMission[1] = CreateConVar("l4d2_VoteChangeUnofficialMission_DefaultVote_Enabled","1","是否关闭游戏默认投票换图功能(推荐值爲1,避免玩家从Esc中投票官方地图)(Enable or Disable the DefaultVoteChangeMissionPanel in the game) 1/0", CVAR_FLAGS,true,0.0,true,1.0);
	VoteChangeMission[2] = CreateConVar("l4d2_VoteChangeUnofficialMission_ForceUnofficialMap_Enabled","1","开启非官方地图强制转换,如有插件企图从非官方地图转换成官方地图,会强制随机转回非官方地图(Enable or Disable ForceChangeLevel for Unofficial Map) 1/0", CVAR_FLAGS,true,0.0,true,1.0);
	VoteChangeMission[3] = CreateConVar("l4d2_VoteChangeUnofficialMission_AutoData_Enabled","1","是否开启自动收集地图数据(Enable or Disable Auto GetMapData) 1/0", CVAR_FLAGS,true,0.0,true,1.0);
	RegConsoleCmd("sm_votechangemission", Command_VoteChangeMission);
	RegAdminCmd("sm_v", Command_VoteChangeMission, ADMFLAG_KICK|ADMFLAG_VOTE|ADMFLAG_GENERIC|ADMFLAG_BAN|ADMFLAG_CHANGEMAP);
	
	AutoExecConfig(true,"l4d2_VoteChangeUnofficialMission");
	
	CreateConfigFile();
	
	BuiltinVotes_OnPluginStart();
}

public OnMapStart()
{
	new String:MapName[64];
	GetCurrentMap(MapName,sizeof(MapName));
	if(IsDefaultMap(MapName) && GetConVarBool(VoteChangeMission[0]))
	{
		if(GetConVarBool(VoteChangeMission[2]) && !IsDefaultMap(OldMapName) && strlen(OldMapName))
		{
			CreateTimer(1.0,RandomChangeMission);
			Format(OldMapName,sizeof(OldMapName),"");
		}
		else
		{
			SetConVarInt(FindConVar("sv_vote_issue_change_mission_allowed"), 1, true, false);
		}
	}
	else
	{
		if(GetConVarBool(VoteChangeMission[0]))
		{
			if(GetConVarBool(VoteChangeMission[1]))
			{
				SetConVarInt(FindConVar("sv_vote_issue_change_mission_allowed"), 0, true, false);
			}
			
			if(IsFirstMap())
			{
				CreateTimer(3.0,Timer_WriteConfigFlie);
			}
			IsUnofficialMap =true;
		}
	}
}

public OnMapEnd()
{
	IsUnofficialMap = false;
	if(GetConVarBool(VoteChangeMission[2]))
	{
		GetCurrentMap(OldMapName,sizeof(OldMapName));
	}
}
	
public Action:Command_VoteChangeMission(client,args)
{
	if(IsValidClient(client))
	{
		if(IsUnofficialMap)
		{
			if(GetClientTeam(client)!=1)
			{
				if(GetConVarBool(VoteChangeMission[0]))
				{
					if(MapDataPack_MapCode[client]==INVALID_HANDLE)
					{
						MapDataPack_MapCode[client] = CreateDataPack();
					}
					else
					{
						ResetPack(MapDataPack_MapCode[client],true);
					}
					
					if(MapDataPack_MapName[client]==INVALID_HANDLE)
					{
						MapDataPack_MapName[client] = CreateDataPack();
					}
					else
					{
						ResetPack(MapDataPack_MapName[client],true);
					}
					
					new Handle:KeyValues_0 = CreateKeyValues("UnofficialMapList");
					new String:FileName[128];
					BuildPath(Path_SM, FileName, sizeof(FileName),"data/l4d2_VoteChangeUnofficialMission.txt");
					if(FileToKeyValues(KeyValues_0, FileName))
					{
						new MaxCount = KvGetNum(KeyValues_0,"max count",0);
						new Handle:menu = CreateMenu(Start_Menu);
						SetMenuTitle(menu, "换图");
						for(new i=0;i<=MaxCount;i++)
						{
							new String:num[4];
							IntToString(i,num,sizeof(num));
							if(KvJumpToKey(KeyValues_0, num))
							{
								new String:map_code[128];
								KvGetString(KeyValues_0,"MapCode",map_code,sizeof(map_code));
								if(IsMapValid(map_code))
								{
									new String:map_name[128];
									KvGetString(KeyValues_0,map_code,map_name,sizeof(map_name));
									WritePackString(MapDataPack_MapCode[client],map_code);
									WritePackString(MapDataPack_MapName[client],map_name);
									AddMenuItem(menu, "", map_name);
									
								}
								KvGoBack(KeyValues_0);
							}
						}
						SetMenuExitButton(menu, true);
						DisplayMenu(menu, client, MENU_TIME_FOREVER);
					}
					KvRewind(KeyValues_0);
					CloseHandle(KeyValues_0);
				}
			}
			else
			{
				ReplyToCommand(client,"You can't using this command.");
			}
		}
		else
		{
			ReplyToCommand(client,"Only using in unofficial map.");
		}
	}
}

public Start_Menu(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select)
	{	
		
		if (IsNewBuiltinVoteAllowed() && !IsVoting_ALL())
		{
			SetBuiltinVoteDelay(13.0);
			
			ResetPack(MapDataPack_MapCode[client]);
			ResetPack(MapDataPack_MapName[client]);
			
			for(new i=0;i<=itemNum;i++)
			{
				ReadPackString(MapDataPack_MapCode[client],TargetMap_Code,sizeof(TargetMap_Code));
				ReadPackString(MapDataPack_MapName[client],TargetMap_Name,sizeof(TargetMap_Name));
			}
			
			if(IsMapValid(TargetMap_Code))
			{
				g_Vote = CreateBuiltinVote(HandleVote_ChangeMission, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
				SetBuiltinVoteInitiator(g_Vote, client);
				SetBuiltinVoteTeam(g_Vote, -1);
				
				decl String:VoteArgument[128];
				Format(VoteArgument,sizeof(VoteArgument),"服务器地图即将改为： %s ?",TargetMap_Name);
				SetBuiltinVoteArgument(g_Vote, VoteArgument);
				DisplayBuiltinVoteToAll(g_Vote, 14);
			}
			else
			{
				ReplyToCommand(client, "这个地图无效。");
			}
		}
		else
		{
			ReplyToCommand(client, "请不要频繁投票。");
		}
	}
}

public HandleVote_ChangeMission(Handle:vote, BuiltinVoteAction:action, param1, param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			g_Vote = INVALID_HANDLE;
			CloseHandle(vote);
		}
		
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
		}
		
		case BuiltinVoteAction_VoteEnd:
		{
			if (param1 == BUILTINVOTES_VOTE_YES)
			{
				if(IsMapValid(TargetMap_Code))
				{
					decl String:PassStr[64];
					Format(PassStr,sizeof(PassStr),"更改战役中...");
					DisplayBuiltinVotePass(vote, PassStr);
					CreateTimer(2.5,ChangeLevel);
				}
				else
				{
					DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Generic);
					PrintToChatAll("这个地图无效。");
				}
			}
			else if (param1 == BUILTINVOTES_VOTE_NO)
			{
				DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
			}
			else
			{
				// Should never happen, but is here as a diagnostic
				DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Generic);
				LogMessage("Vote failure. winner = %d", param1);
			}
		}
	}
}

public Action:ChangeLevel(Handle:Timer)
{
	ServerCommand("changelevel %s",TargetMap_Code);
}

public Action:Timer_WriteConfigFlie(Handle:Timer)
{
	new String:MapName[64];
	GetCurrentMap(MapName,sizeof(MapName));
	if(GetConVarBool(VoteChangeMission[3]))
	{
		WriteConfigFlie(MapName);
	}
}

WriteConfigFlie(const String:MapName[])
{
	new Handle:KeyValues_0 = CreateKeyValues("UnofficialMapList");
	new String:FileName[128];
	BuildPath(Path_SM, FileName, sizeof(FileName),"data/l4d2_VoteChangeUnofficialMission.txt");
	if(FileToKeyValues(KeyValues_0, FileName))
	{
		new MaxCount = KvGetNum(KeyValues_0,"max count",0);
		for(new i=0;i<=MaxCount;i++)
		{
			new String:num[4];
			IntToString(i,num,sizeof(num));
			if(KvJumpToKey(KeyValues_0, num))
			{
				if(KvJumpToKey(KeyValues_0, MapName))
				{
					break;
				}
				else
				{
					KvRewind(KeyValues_0);
					continue;
				}
			}
			else
			{
				KvSetNum(KeyValues_0,"max count",MaxCount+1);
				KvJumpToKey(KeyValues_0, num,true);
				new String:TempMapName[128];
				Format(TempMapName,sizeof(TempMapName),"%s(UnKnowMapName)",MapName);
				KvSetString(KeyValues_0,MapName,TempMapName);
				KvSetString(KeyValues_0,"MapCode",MapName);
				KvRewind(KeyValues_0);
				KeyValuesToFile(KeyValues_0, FileName);
				break;
			}
		}
	}
	CloseHandle(KeyValues_0);
}

CreateConfigFile()
{
	new Handle:KeyValues_0 = CreateKeyValues("UnofficialMapList");
	new String:FileName[128];
	BuildPath(Path_SM, FileName, sizeof(FileName),"data/l4d2_VoteChangeUnofficialMission.txt");
	if(!FileExists(FileName))
	{
		KvSetString(KeyValues_0,"请使用专业代码修改软件进行修改本文档,文档编码格式爲:UTF-8 without BOM(Please using the professional software to modify this document,File type:UTF-8 without BOM)","软件下载地址(Download URL): http://notepad-plus-plus.org/");
		KeyValuesToFile(KeyValues_0, FileName);
	}
	CloseHandle(KeyValues_0);
}

bool:IsDefaultMap(const String:CurrenMap[])
{
	for(new i=0;i<sizeof(DefaultMap);i++)
	{
		if(StrEqual(CurrenMap,DefaultMap[i]))
		{
			return true;
		}
	}
	return false;
}

IsValidClient(client)
{
	if(client>0&&client<=MaxClients)
	{
		if(IsValidEntity(client))
		{
			if(IsClientConnected(client))
			{
				return true;
			}
		}
	}
	return false;
}

public Action:RandomChangeMission(Handle:Timer)
{
	new Handle:KeyValues_0 = CreateKeyValues("UnofficialMapList");
	new String:FileName[128];
	BuildPath(Path_SM, FileName, sizeof(FileName),"data/l4d2_VoteChangeUnofficialMission.txt");
	if(FileToKeyValues(KeyValues_0, FileName))
	{
		new MaxCount = KvGetNum(KeyValues_0,"max count",0);
		new random = GetRandomInt(0,MaxCount-1);
		new String:num[4];
		IntToString(random,num,sizeof(num));
		if(KvJumpToKey(KeyValues_0, num))
		{
			new String:MapCode[64];
			KvGetString(KeyValues_0,"MapCode",MapCode,sizeof(MapCode));
			if(IsMapValid(MapCode))
			{
				ServerCommand("changelevel %s",MapCode);
			}
		}
	}
	CloseHandle(KeyValues_0);
}

bool:IsFirstMap()
{
	new String:mClassName[64];
	for (new i = 1; i<GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, mClassName, sizeof(mClassName));
			if (StrEqual(mClassName, "point_viewcontrol_survivor"))
			{
				return true;
			}
		}
	}
	return false;
}