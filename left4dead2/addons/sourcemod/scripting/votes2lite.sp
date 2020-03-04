#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#define SCORE_DELAY_EMPTY_SERVER 3.0
#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8
#define MaxHealth 100
#define VOTE_NO "no"
#define VOTE_YES "yes"
#define L4D_MAXCLIENTS_PLUS1 (MaxClients+1)
new Votey = 0;
new Voten = 0;
new bool: game_l4d2 = false;
//new String:ReadyMode[64];
//new String:Label[16];//ready 开启/关闭
//new String:VotensReady_ED[32];
new String:VotensHp_ED[32];
new String:VotensMap_ED[32];
new String:kickplayer[MAX_NAME_LENGTH];
new String:kickplayername[MAX_NAME_LENGTH];
new String:votesmaps[MAX_NAME_LENGTH];
new String:votesmapsname[MAX_NAME_LENGTH];
new Handle:g_hVoteMenu = INVALID_HANDLE;

new Handle:g_Cvar_Limits;
//new Handle:cvarFullResetOnEmpty;
//new Handle:VotensReadyED;
new Handle:VotensHpED;
new Handle:VotensMapED;
new Handle:VotensED;
new Float:lastDisconnectTime;
 
enum voteType
{
	//ready,
	hp,
	map,
	kicks
}
new voteType:g_voteType = voteType;
public Plugin:myinfo =
{
	name = "夜店大型非官方服投票换图插件",
	author = "fenghf",
	description = "Votes Commands",
	version = "1.2.2a",
	url = "http://bbs.3dmgame.com/l4d"
};
public OnPluginStart()
{
	decl String: game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("只能在left4dead1&2使用.");
	}
	if (StrEqual(game_name, "left4dead2", false))
	{
		game_l4d2 = true;
	}
	//RegAdminCmd("sm_voter", Command_Vote, ADMFLAG_KICK|ADMFLAG_VOTE|ADMFLAG_GENERIC|ADMFLAG_BAN|ADMFLAG_CHANGEMAP, "投票开启ready插件");S
	//RegConsoleCmd("votesready", Command_Voter);
	RegConsoleCmd("voteshp", Command_VoteHp);
	RegConsoleCmd("votesmapsmenu", Command_VotemapsMenu);
	RegConsoleCmd("voteskick", Command_Voteskick);
	RegConsoleCmd("sm_vote", Command_Votes, "打开投票菜单");

	g_Cvar_Limits = CreateConVar("sm_votes_s", "0.60", "百分比.", 0, true, 0.05, true, 1.0);
	//cvarFullResetOnEmpty = CreateConVar("l4d_full_reset_on_empty", "1", " 当服务器没有人的时候关闭ready插件", FCVAR_PLUGIN|FCVAR_NOTIFY);
	//VotensReadyED = CreateConVar("l4d_VotensreadyED", "0", " 启用、关闭 投票ready功能", FCVAR_PLUGIN|FCVAR_NOTIFY);
	VotensHpED = CreateConVar("l4d_VotenshpED", "1", " 启用、关闭 投票回血功能", FCVAR_PLUGIN|FCVAR_NOTIFY);
	VotensMapED = CreateConVar("l4d_VotensmapED", "1", " 启用、关闭 投票换图功能", FCVAR_PLUGIN|FCVAR_NOTIFY);
	VotensED = CreateConVar("l4d_Votens", "1", " 启用、关闭 插件", FCVAR_PLUGIN|FCVAR_NOTIFY);
}
public OnClientPutInServer(client)
{
	CreateTimer(30.0, TimerAnnounce, client);
}
/*
public OnMapStart()
{
	new Handle:currentReadyMode = FindConVar("l4d_ready_enabled");
	GetConVarString(currentReadyMode, ReadyMode, sizeof(ReadyMode));
	
	if (strcmp(ReadyMode, "0", false) == 0)
	{
		Format(Label, sizeof(Label), "开启");
	}
	else if (strcmp(ReadyMode, "1", false) == 0)
	{
		Format(Label, sizeof(Label), "关闭");
	}
}*/
public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		PrintToChat(client, "\x04[\x03换图提示\x04]\x05 输入\x03 !vote \x04投票第三方地图,管理员才可以换图");
}
public Action:Command_Votes(client, args) 
{ 
	if(GetConVarInt(VotensED) == 1)
	{
		//new VotensReadyE_D = GetConVarInt(VotensReadyED); 
		new VotensHpE_D = GetConVarInt(VotensHpED); 
		new VotensMapE_D = GetConVarInt(VotensMapED);
		/*
		if(VotensReadyE_D == 0)
		{
			VotensReady_ED = "开启";
		}
		else if(VotensReadyE_D == 1)
		{
			VotensReady_ED = "禁用";
		}*/
		if(VotensHpE_D == 0)
		{
			VotensHp_ED = "开启";
		}
		else if(VotensHpE_D == 1)
		{
			VotensHp_ED = "禁用";
		}
		
		if(VotensMapE_D == 0)
		{
			VotensMap_ED = "开启";
		}
		else if(VotensMapE_D == 1)
		{
			VotensMap_ED = "禁用";
		}
		new Handle:menu = CreatePanel();
		new String:Value[64];
		SetPanelTitle(menu, "投票菜单");
		/*
		if (VotensReadyE_D == 0)
		{
			DrawPanelItem(menu, "禁用投票ready插件");
		}
		else if(VotensReadyE_D == 1)
		{
			Format(Value, sizeof(Value), "投票%s ready插件", Label);
			DrawPanelItem(menu, Value);
		}*/
		if (VotensHpE_D == 0)
		{
			DrawPanelItem(menu, "禁用投票回血");
		}
		else if (VotensHpE_D == 1)
		{
			DrawPanelItem(menu, "投票回血");
		}
		if (VotensMapE_D == 0)
		{
			DrawPanelItem(menu, "禁用投票换图");
		}
		else if (VotensMapE_D == 1)
		{
			DrawPanelItem(menu, "投票换图");
		}
		DrawPanelItem(menu, "投票踢人");//常用,不添加开启关闭
		if (GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS)
		{
			DrawPanelText(menu, "管理员选项");
			/*
			Format(Value, sizeof(Value), "%s 投票ready插件", VotensReady_ED);
			DrawPanelItem(menu, Value);
			*/
			Format(Value, sizeof(Value), "%s 投票回血", VotensHp_ED);
			DrawPanelItem(menu, Value);
			Format(Value, sizeof(Value), "%s 投票换图", VotensMap_ED);
			DrawPanelItem(menu, Value);
		}
		DrawPanelText(menu, " \n");
		DrawPanelItem(menu, "关闭");
		//SetMenuExitButton(menu, true);
		SendPanelToClient(menu, client,Votes_Menu, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	else if(GetConVarInt(VotensED) == 0)
	{}
	return Plugin_Stop;
}
public Votes_Menu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		//new VotensReadyE_D = GetConVarInt(VotensReadyED); 
		new VotensHpE_D = GetConVarInt(VotensHpED); 
		new VotensMapE_D = GetConVarInt(VotensMapED);
		switch (itemNum)
		{
		/*
			case 1: 
			{
				if (VotensReadyE_D == 0)
				{
					FakeClientCommand(client,"sm_votes");
					PrintToChat(client, "[ 提示] 禁用投票ready插件");
					return ;
				}
				else if (VotensReadyE_D == 1)
				{
					FakeClientCommand(client,"votesready");
				}
			}
			*/
			case 1: 
			{
				if (VotensHpE_D == 0)
				{
					FakeClientCommand(client,"sm_votes");
					PrintToChat(client, "[ 提示] 禁用投票回血");
					return;
				}
				else if (VotensHpE_D == 1)
				{
					FakeClientCommand(client,"voteshp");
				}
			}
			case 2: 
			{
				if (VotensMapE_D == 0)
				{
					FakeClientCommand(client,"sm_votes");
					PrintToChat(client, "[ 提示] 禁用投票换图");
					return ;
				}
				else if (VotensMapE_D == 1)
				{
					FakeClientCommand(client,"votesmapsmenu");
				}
			}
			case 3: 
			{
				FakeClientCommand(client,"voteskick");
			}/*
			case 5: 
			{
				if (VotensReadyE_D == 0 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensReadyE_D == 0)
				{
					SetConVarInt(FindConVar("l4d_VotensreadyED"), 1);
					PrintToChatAll("\x05[ 提示] \x04管理员 开启投票ready插件");
				}
				else if (VotensReadyE_D == 1 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensReadyE_D == 1)
				{
					SetConVarInt(FindConVar("l4d_VotensreadyED"), 0);
					PrintToChatAll("\x05[ 提示] \x04管理员 禁用投票ready插件");
				}
			}*/
			case 4: 
			{
				if (VotensHpE_D == 0 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensHpE_D == 0)
				{
					SetConVarInt(FindConVar("l4d_VotenshpED"), 1);
					PrintToChatAll("\x05[提示] \x04管理员 开启投票回血");
				}
				else if (VotensHpE_D == 1 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensHpE_D == 1)
				{
					SetConVarInt(FindConVar("l4d_VotenshpED"), 0);
					PrintToChatAll("\x05[提示] \x04管理员 禁用投票回血");
				}
			}
			case 5: 
			{
				if (VotensMapE_D == 0 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensMapE_D == 0)
				{
					SetConVarInt(FindConVar("l4d_VotensmapED"), 1);
					PrintToChatAll("\x05[提示] \x04管理员 开启投票换图");
				}
				else if (VotensMapE_D == 1 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensMapE_D == 1)
				{
					SetConVarInt(FindConVar("l4d_VotensmapED"), 0);
					PrintToChatAll("\x05[提示] \x04管理员 禁用投票换图");
				}
			}
		}
	}
}

/*
public Action:Command_Voter(client, args)
{
	if(GetConVarInt(VotensED) == 1 && GetConVarInt(VotensReadyED) == 1)
	{
		if (IsVoteInProgress())
		{
			ReplyToCommand(client, "[ 提示] 已有投票正在进行中");
			return Plugin_Handled;
		}
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
			
		PrintToChatAll("\x05[ 换图提示] \x04%N \x03发起投票换三方服 \x05%s \x03ready插件", client, Label);
		PrintToChatAll("\x05[ 提示] \x04服务器没有玩家的时候,ready插件自动关闭");
		
		g_voteType = voteType:ready;
		decl String:SteamId[35];
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		LogMessage("%N %s发起投票%s ready插件!",  client, SteamId, Label);//记录在log文件
		
		g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
		SetMenuTitle(g_hVoteMenu, "是否%s ready插件?",Label);
		AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
		AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	
		SetMenuExitButton(g_hVoteMenu, false);
		VoteMenuToAll(g_hVoteMenu, 20);		
		return Plugin_Handled;
	}
	else if(GetConVarInt(VotensED) == 0 && GetConVarInt(VotensReadyED) == 0)
	{
		PrintToChat(client, "[ 提示] 禁用投票ready插件");
	}
	return Plugin_Handled;
}
*/
public Action:Command_VoteHp(client, args)
{
	if(GetConVarInt(VotensED) == 1 
	&& GetConVarInt(VotensHpED) == 1)
	{
		if (IsVoteInProgress())
		{
			ReplyToCommand(client, "[提示] 已有投票在进行中");
			return Plugin_Handled;
		}
		
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
		PrintToChatAll("\x05[提示] \x04 %N \x03发起投票回血",client);
		
		g_voteType = voteType:hp;
		decl String:SteamId[35];
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		LogMessage("%N &s发起投票所有人回血!",  client, SteamId);//记录在log文件
		g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
		SetMenuTitle(g_hVoteMenu, "是否所有人回血?");
		AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
		AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	
		SetMenuExitButton(g_hVoteMenu, false);
		VoteMenuToAll(g_hVoteMenu, 20);		
		return Plugin_Handled;	
	}
	else if(GetConVarInt(VotensED) == 0 && GetConVarInt(VotensHpED) == 0)
	{
		PrintToChat(client, "[提示] 禁用投票回血");
	}
	return Plugin_Handled;
}

public Action:Command_Voteskick(client, args)
{
	if(client!=0) CreateVotekickMenu(client);		
	return Plugin_Handled;
}

CreateVotekickMenu(client)
{	
	new Handle:menu = CreateMenu(Menu_Voteskick);		
	new team = GetClientTeam(client);
	new String:name[MAX_NAME_LENGTH];
	new String:playerid[32];
	SetMenuTitle(menu, "选择踢出玩家");
	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==team)
		{
			Format(playerid,sizeof(playerid),"%i",GetClientUserId(i));
			if(GetClientName(i,name,sizeof(name)))
			{
				AddMenuItem(menu, playerid, name);						
			}
		}		
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}
public Menu_Voteskick(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32] , String:name[32];
		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
		kickplayer = info;
		kickplayername = name;
		PrintToChatAll("\x05[提示] \x04%N 发起投票踢出 \x05 %s", param1, kickplayername);
		DisplayVoteKickMenu(param1);		
	}
}

public DisplayVoteKickMenu(client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[提示] 已有投票正在进行中");
		return;
	}
	
	if (!TestVoteDelay(client))
	{
		return;
	}
	g_voteType = voteType:kicks;
	
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "是否踢出玩家 %s",kickplayername);
	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
}

public Action:Command_VotemapsMenu(client, args)
{
	if(GetConVarInt(VotensED) == 1 && GetConVarInt(VotensMapED) == 1)
	{
		
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
		new Handle:menu = CreateMenu(MapMenuHandler);
	
		SetMenuTitle(menu, "请选择投票地图");
		if(game_l4d2)
		{
			//AddMenuItem(menu, "option1", "返回");
			AddMenuItem(menu, "c1m1_hotel", "死亡中心_1");
			AddMenuItem(menu, "c1m2_streets", "死亡中心_2");
			AddMenuItem(menu, "c1m3_mall", "死亡中心_3");
			AddMenuItem(menu, "c1m4_atrium", "死亡中心_4");
			AddMenuItem(menu, "c2m1_highway", "黑色狂欢节_1");
			AddMenuItem(menu, "c2m2_fairgrounds", "黑色狂欢节_2");
			AddMenuItem(menu, "c2m3_coaster", "黑色狂欢节_3");
			AddMenuItem(menu, "c2m4_barns", "黑色狂欢节_4");
			AddMenuItem(menu, "c2m5_concert", "黑色狂欢节_5");
			AddMenuItem(menu, "c3m1_plankcountry", "沼泽激战_1");
			AddMenuItem(menu, "c3m2_swamp", "沼泽激战_2");
			AddMenuItem(menu, "c3m3_shantytown", "沼泽激战_3");
			AddMenuItem(menu, "c3m4_plantation", "沼泽激战_4");
			AddMenuItem(menu, "c4m1_milltown_a", "暴风骤雨_1");
			AddMenuItem(menu, "c4m2_sugarmill_a", "暴风骤雨_2");
			AddMenuItem(menu, "c4m3_sugarmill_b", "暴风骤雨_3");
			AddMenuItem(menu, "c4m4_milltown_b", "暴风骤雨_4");
			AddMenuItem(menu, "c4m5_milltown_escape", "暴风骤雨_5");
			AddMenuItem(menu, "c5m1_waterfront", "教区_1");
			AddMenuItem(menu, "c5m2_park", "教区_2");
			AddMenuItem(menu, "c5m3_cemetery", "教区_3");
			AddMenuItem(menu, "c5m4_quarter", "教区_4");
			AddMenuItem(menu, "c5m5_bridge", "教区_5");
			AddMenuItem(menu, "c6m1_riverbank", "短暂时刻_1");
			AddMenuItem(menu, "c6m2_bedlam", "短暂时刻_2");
			AddMenuItem(menu, "c6m3_port", "短暂时刻_3");
			AddMenuItem(menu, "c7m1_docks", "牺牲_1");
			AddMenuItem(menu, "c7m2_barge", "牺牲_2");
			AddMenuItem(menu, "c7m3_port", "牺牲_3");
			AddMenuItem(menu, "c8m1_apartment", "毫不留情_1");
			AddMenuItem(menu, "c8m2_subway", "毫不留情_2");
			AddMenuItem(menu, "c8m3_sewers", "毫不留情_3");
			AddMenuItem(menu, "c8m4_interior", "毫不留情_4");
			AddMenuItem(menu, "c8m5_rooftop", "毫不留情_5");
			AddMenuItem(menu, "c9m1_alleys", "坠机险途_1");
			AddMenuItem(menu, "c9m2_lots", "坠机险途_2");
			AddMenuItem(menu, "c10m1_caves", "死亡丧钟_1");
			AddMenuItem(menu, "c10m2_drainage", "死亡丧钟_2");
			AddMenuItem(menu, "c10m3_ranchhouse", "死亡丧钟_3");
			AddMenuItem(menu, "c10m4_mainstreet", "死亡丧钟_4");
			AddMenuItem(menu, "c10m5_houseboat", "死亡丧钟_5");
			AddMenuItem(menu, "c11m1_greenhouse", "静寂时分_1");
			AddMenuItem(menu, "c11m2_offices", "静寂时分_2");
			AddMenuItem(menu, "c11m3_garage", "静寂时分_3");
			AddMenuItem(menu, "c11m4_terminal", "静寂时分_4");
			AddMenuItem(menu, "c11m5_runway", "静寂时分_5");
			AddMenuItem(menu, "c12m1_hilltop", "血腥收获_1");
			AddMenuItem(menu, "c12m2_traintunnel", "血腥收获_2");
			AddMenuItem(menu, "c12m3_bridge", "血腥收获_3");
			AddMenuItem(menu, "c12m4_barn", "血腥收获_4");
			AddMenuItem(menu, "c12m5_cornfield", "血腥收获_5");
			AddMenuItem(menu, "c13m1_alpinecreek", "刺骨寒溪_1");
			AddMenuItem(menu, "c13m2_southpinestream", "刺骨寒溪_2");
			AddMenuItem(menu, "c13m3_memorialbridge", "刺骨寒溪_3");
			AddMenuItem(menu, "c13m4_cutthroatcreek", "刺骨寒溪_4");
			AddMenuItem(menu, "l4d2_diescraper1_apartment_36", "喋血蜃楼天台_1");
			AddMenuItem(menu, "l4d2_diescraper2_streets_36", "喋血蜃楼天台_2");
			AddMenuItem(menu, "l4d2_diescraper3_mid_36", "喋血蜃楼天台_3");
			AddMenuItem(menu, "l4d2_diescraper4_top_36", "喋血蜃楼天台_4");			
			AddMenuItem(menu, "fk", "方块_1");	
			AddMenuItem(menu, "fk2", "方块_2");	
			AddMenuItem(menu, "fk3", "方块_3");	
			AddMenuItem(menu, "fk4", "方块_4");	
			AddMenuItem(menu, "fk5", "方块_5");	
			AddMenuItem(menu, "fk6", "方块_6");	
			AddMenuItem(menu, "hehe4", "呵呵4_1");	
			AddMenuItem(menu, "hehe4_2", "呵呵4_2");	
			AddMenuItem(menu, "hehe4_3", "呵呵4_3");	
			AddMenuItem(menu, "hehe4_4", "呵呵4_4");	
			AddMenuItem(menu, "hehe4_5", "呵呵4_5");	
			AddMenuItem(menu, "hehe4_6", "呵呵4_6");	
			AddMenuItem(menu, "hehe4_7", "呵呵4_7");	
			AddMenuItem(menu, "hehe4_8", "呵呵4_8");	
			AddMenuItem(menu, "hehe4_9", "呵呵4_9");	
			AddMenuItem(menu, "hehe4_10", "呵呵4_10");
			AddMenuItem(menu, "city", "灰怆_1");
			AddMenuItem(menu, "fly", "灰怆_2");
			AddMenuItem(menu, "rush", "灰怆_3");
			AddMenuItem(menu, "end", "灰怆_4");
			AddMenuItem(menu, "wfp1_track", "白森林_1");
			AddMenuItem(menu, "wfp2_horn", "白森林_2");
			AddMenuItem(menu, "wfp3_mill", "白森林_3");
			AddMenuItem(menu, "wfp4_commstation", "白森林_4");
			AddMenuItem(menu, "l4d2_downtowndine01", "停车加油_1");
			AddMenuItem(menu, "l4d2_downtowndine02", "停车加油_2");
			AddMenuItem(menu, "l4d2_downtowndine03", "停车加油_3");
			AddMenuItem(menu, "l4d2_downtowndine04", "停车加油_4");
			AddMenuItem(menu, "hotel_time", "隔绝_1");
			AddMenuItem(menu, "plant_time", "隔绝_2");
			AddMenuItem(menu, "parish_time", "隔绝_3");
			AddMenuItem(menu, "carnival_time", "隔绝_4");
			AddMenuItem(menu, "home_time", "隔绝_5");
			AddMenuItem(menu, "finish_time", "隔绝_6");
			AddMenuItem(menu, "goodbye_time", "隔绝_7");
			AddMenuItem(menu, "crossover_map", "隔绝_8");
			AddMenuItem(menu, "showdown_time", "隔绝_9");
			AddMenuItem(menu, "dead_space_maps1_l4d2_pw", "死亡空间_1");
			AddMenuItem(menu, "dead_space_maps2_l4d2_pw", "死亡空间_2");
			AddMenuItem(menu, "dead_space_maps3_l4d2_pw", "死亡空间_3");
			AddMenuItem(menu, "dead_space_maps4_l4d2_pw", "死亡空间_4");
			AddMenuItem(menu, "dead_space_maps5_l4d2_pw", "死亡空间_5");		
			AddMenuItem(menu, "quart", "逃离瓦伦西亚_1");
			AddMenuItem(menu, "nuevocentro_ext", "逃离瓦伦西亚_2");
			AddMenuItem(menu, "nuevocentro_int", "逃离瓦伦西亚_3");
			AddMenuItem(menu, "metro_vic", "逃离瓦伦西亚_4");
			AddMenuItem(menu, "dw_woods", "阴暗森林_1");
			AddMenuItem(menu, "dw_underground", "阴暗森林_2");
			AddMenuItem(menu, "dw_complex", "阴暗森林_3");
			AddMenuItem(menu, "dw_otherworld", "阴暗森林_4");
			AddMenuItem(menu, "dw_final", "阴暗森林_5");		
			AddMenuItem(menu, "hehe6_1", "呵呵6_1");
			AddMenuItem(menu, "hehe6_2", "呵呵6_2");
			AddMenuItem(menu, "hehe6_3", "呵呵6_3");
			AddMenuItem(menu, "hehe6_4", "呵呵6_4");
			AddMenuItem(menu, "hehe6_5", "呵呵6_5");
			AddMenuItem(menu, "hehe6_6", "呵呵6_6");
			AddMenuItem(menu, "hehe6_7", "呵呵6_7");
			AddMenuItem(menu, "hehe6_8", "呵呵6_8");
			AddMenuItem(menu, "hehe6_9", "呵呵6_9");
			AddMenuItem(menu, "SA_01", "另一边生活_1");
			AddMenuItem(menu, "SA_02", "另一边生活_2");
			AddMenuItem(menu, "SA_03", "另一边生活_3");
			AddMenuItem(menu, "SA_04", "另一边生活_4");
			AddMenuItem(menu, "SA_05", "另一边生活_5");
			AddMenuItem(menu, "SA_06", "另一边生活_6");
			AddMenuItem(menu, "SA_07", "另一边生活_7");
		
		
		
		
		
		
		
		
		
		
		
		
		
		}
		else
		{
			//AddMenuItem(menu, "option1", "返回");
			AddMenuItem(menu, "l4d_vs_hospital01_apartment", "毫不留情");
			AddMenuItem(menu, "l4d_vs_airport01_greenhouse", "静寂时分");
			AddMenuItem(menu, "l4d_vs_smalltown01_caves", "死亡丧钟");
			AddMenuItem(menu, "l4d_vs_farm01_hilltop", "血腥收获");
			AddMenuItem(menu, "l4d_garage01_alleys", "坠机险途");
			AddMenuItem(menu, "l4d_river01_docks", "牺牲");
		}
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		
		return Plugin_Handled;
	}
	else 
	if(GetConVarInt(VotensED) == 0 && GetConVarInt(VotensMapED) == 0)
	{
		PrintToChat(client, "[ 提示] 禁用投票换图");
	}
	return Plugin_Handled;
}

public MapMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32] , String:name[32];
		GetMenuItem(menu, itemNum, info, sizeof(info), _, name, sizeof(name));
		votesmaps = info;
		votesmapsname = name;
		PrintToChatAll("\x05[ 提示] \x04%N 发起投票换图 \x05 %s", client, votesmapsname);
		DisplayVoteMapsMenu(client);		
	}
}
public DisplayVoteMapsMenu(client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[ 提示] 已有投票正在进行中");
		return;
	}
	
	if (!TestVoteDelay(client))
	{
		return;
	}
	g_voteType = voteType:map;
	
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "发起投票换图 %s %s",votesmapsname, votesmaps);
	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
}
public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	//==========================
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0: 
			{
				Votey += 1;
				PrintToChatAll("\x03%N \x05投票了.", param1);
			}
			case 1: 
			{
				Voten += 1;
				PrintToChatAll("\x03%N \x04投票了.", param1);
			}
		}
	}
	//==========================
	decl String:item[64], String:display[64];
	new Float:percent, Float:limit, votes, totalVotes;

	GetMenuVoteInfo(param2, votes, totalVotes);
	GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));
	
	if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
	{
		votes = totalVotes - votes;
	}
	percent = GetVotePercent(votes, totalVotes);

	limit = GetConVarFloat(g_Cvar_Limits);
	
	CheckVotes();
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[ 提示] 没有票数");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("[ 提示] 投票否决. 至少需要 %d%% 同意.(同意 %d%% 总共 %i 票)", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
			CreateTimer(2.0, VoteEndDelay);
		}
		else
		{
			PrintToChatAll("[ 提示] 投票可决.(同意 %d%% 总共 %i 票)", RoundToNearest(100.0*percent), totalVotes);
			CreateTimer(2.0, VoteEndDelay);
			switch (g_voteType)
			{
			/*
				case (voteType:ready):
				{
					if (strcmp(ReadyMode, "0", false) == 0 || strcmp(item, VOTE_NO) == 0 || strcmp(item, VOTE_YES) == 0 )
					{
						strcopy(item, sizeof(item), display);
						ServerCommand("sv_search_key 1");
						SetConVarInt(FindConVar("l4d_ready_enabled"), 1);
					}
					if (strcmp(ReadyMode, "1", false) == 0 || strcmp(item, VOTE_NO) == 0 || strcmp(item, VOTE_YES) == 0 )
					{
						ServerCommand("sv_search_key 1");
						SetConVarInt(FindConVar("l4d_ready_enabled"), 0);
					}
					PrintToChatAll("[ 提示] 投票的结果为: %s.", item);
					LogMessage(" 提示 %s ready通过",Label);
				}
				*/
				case (voteType:hp):
				{
					AnyHp();
					LogMessage(" 提示 所有玩家回血 ready通过");
				}
				case (voteType:map):
				{
					CreateTimer(5.0, Changelevel_Map);
					PrintToChatAll("\x03[ 提示] \x04 5秒后换图 \x05%s",votesmapsname);
					PrintToChatAll("\x04 %s",votesmaps);
					LogMessage("投票换图 %s %s 通过",votesmapsname,votesmaps);
				}
				case (voteType:kicks):
				{
					PrintToChatAll("\x05[ 提示] \x05 %s \x04投票踢出", kickplayername);
					ServerCommand("sm_kick %s 投票踢出", kickplayername);	
					LogMessage(" 投票踢出%s 通过",kickplayername);
				}
			}
		}
	}
	return 0;
}
//====================================================
public AnyHp()
{
	PrintToChatAll("\x03[ 提示]\x04所有玩家回血");
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			FakeClientCommand(i, "give health");
			SetEntityHealth(i, MaxHealth);
			//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03回血",i);
		}
		else
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)) 
		{
			new class = GetEntProp(i, Prop_Send, "m_zombieClass");
			if (class == ZOMBIECLASS_SMOKER)
			{
				SetEntityHealth(i, 250);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Smoker回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_BOOMER)
			{
				SetEntityHealth(i, 50);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Boomer回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_HUNTER)
			{
				SetEntityHealth(i, 250);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Hunter回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
            if (class == ZOMBIECLASS_SPITTER)
			{
				SetEntityHealth(i, 100);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Spitter 回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_JOCKEY)
			{
				decl String:game_name[64];
				GetGameFolderName(game_name, sizeof(game_name));
				if (!StrEqual(game_name, "left4dead2", false))
				{
					SetEntityHealth(i, 6000);
					//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Tank 回血",i);//请勿使用提示,否则知道有那些特感
				}
				else
				{
					SetEntityHealth(i, 325);
					//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Jockey回血",i);//请勿使用提示,否则知道有那些特感
				}
			}
			else
			if (class == ZOMBIECLASS_CHARGER)
			{
				SetEntityHealth(i, 600);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Charger回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_TANK)
			{
				SetEntityHealth(i, 6000);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Tank回血",i);//请勿使用提示,否则知道有那些特感
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}
//================================
CheckVotes()
{
	PrintHintTextToAll("同意: \x04%i\n不同意: \x04%i", Votey, Voten);
}
public Action:VoteEndDelay(Handle:timer)
{
	Votey = 0;
	Voten = 0;
}
public Action:Changelevel_Map(Handle:timer)
{
	ServerCommand("changelevel %s", votesmaps);
}
//===============================
VoteMenuClose()
{
	Votey = 0;
	Voten = 0;
	CloseHandle(g_hVoteMenu);
	g_hVoteMenu = INVALID_HANDLE;
}
Float:GetVotePercent(votes, totalVotes)
{
	return FloatDiv(float(votes),float(totalVotes));
}
bool:TestVoteDelay(client)
{
 	new delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		if (delay > 60)
 		{
 			PrintToChat(client, "[ 提示] 必须等待 %i 分后才可发起投票", delay % 60);
 		}
 		else
 		{
 			PrintToChat(client, "[ 提示] 必须等待 %i 秒后才可发起投票", delay);
 		}
 		return false;
 	}
	return true;
}
//=======================================
public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && IsFakeClient(client)) return;

	new Float:currenttime = GetGameTime();
	
	if (lastDisconnectTime == currenttime) return;
	
	CreateTimer(SCORE_DELAY_EMPTY_SERVER, IsNobodyConnected, currenttime);
	lastDisconnectTime = currenttime;
}

public Action:IsNobodyConnected(Handle:timer, any:timerDisconnectTime)
{
	if (timerDisconnectTime != lastDisconnectTime) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
			return  Plugin_Stop;
	}
	/*
	SetConVarInt(FindConVar("l4d_ready_enabled"), 0);		
	if (GetConVarBool(cvarFullResetOnEmpty))
	{
		SetConVarInt(FindConVar("l4d_ready_enabled"), 0);
	}*/
	
	return  Plugin_Stop;
}
