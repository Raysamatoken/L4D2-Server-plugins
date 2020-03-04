#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define MaxClients 32
#define PLUGIN_VERSION "1.5.5"

public Plugin:myinfo =
{
	name = "L4D2 Infinite Ammo",
	author = "Machine",
	description = "Gives Infinite Ammo to players",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=123100"
};

new InfiniteAmmo[MaxClients+1];
new Throwing[MaxClients+1];
new Handle:IAmmo = INVALID_HANDLE;
new Handle:AllowGL = INVALID_HANDLE;
new Handle:AllowM60 = INVALID_HANDLE;
new Handle:AllowChainsaw = INVALID_HANDLE;
new Handle:AllowThrowables = INVALID_HANDLE;
new Handle:AllowUpgradeAmmo = INVALID_HANDLE;
new Handle:AllowMeds = INVALID_HANDLE;
new Handle:AllowDefibs = INVALID_HANDLE;
new Handle:AllowPills = INVALID_HANDLE;
new Handle:AllowShots = INVALID_HANDLE;
new Handle:AdminOverride = INVALID_HANDLE;

new Handle:hAdminMenu = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("l4d2_iammo", Command_IAmmo, ADMFLAG_BAN, "sm_iammo <#userid|name> <0|1> - Toggles Infinite Ammo on player(s)");

	CreateConVar("l4d2_iammo_version", PLUGIN_VERSION, "插件版本", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	IAmmo = CreateConVar("l4d2_iammo_enable", "1", "<0|1|2> 开启无限子弹? 0=关闭 1=开启 2=所有玩家无限子弹", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowGL = CreateConVar("l4d2_iammo_gl", "1", "<0|1|2> 允许榴弹无限? 0=关闭 1=开启 2=只有管理员可用", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowM60 = CreateConVar("l4d2_iammo_m60", "1", "<0|1|2> 允许M60弹药无限? 0=关闭 1=开启 2=只有管理员可用", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowChainsaw = CreateConVar("l4d2_iammo_chainsaw", "1", "<0|1|2> 电锯燃料无限? 0=关闭 1=开启 2=只有管理员可用", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowThrowables = CreateConVar("l4d2_iammo_throwables", "1", "<0|1|2> 投掷物无限? 0=关闭 1=开启 2=只有管理员可用", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowUpgradeAmmo = CreateConVar("l4d2_iammo_upgradeammo", "1", "<0|1> 高爆弹和燃烧弹无限? 0=关闭 1=开启", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AllowMeds = CreateConVar("l4d2_iammo_meds", "1", "<0|1|2> 医疗包无限? 0=关闭 1=开启 2=只有管理员可用", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowDefibs = CreateConVar("l4d2_iammo_defibs", "1", "<0|1|2> 电击器无限? 0=关闭 1=开启 2=只有管理员可用", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowPills = CreateConVar("l4d2_iammo_pills", "1", "<0|1|2> 止痛药无限? 0=关闭 1=开启 2=只有管理员可用", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AllowShots = CreateConVar("l4d2_iammo_shots", "1", "<0|1|2> 肾上腺无限? 0=关闭 1=开启 2=只有管理员可用", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);

	AdminOverride = CreateConVar("l4d2_admin_override", "1", "<0|1> 管理员一直有无限子弹? 0=关闭 1=开启", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	HookEvent("defibrillator_used", Event_DefibrillatorUsed);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("adrenaline_used", Event_AdrenalineUsed);
	HookEvent("pills_used", Event_PillsUsed);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("weapon_drop", Event_WeaponDrop);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookConVarChange(IAmmo, IAmmoChanged);
	HookConVarChange(AllowGL, AllowGLChanged);
	HookConVarChange(AllowM60, AllowM60Changed);
	HookConVarChange(AllowChainsaw, AllowChainsawChanged);
	HookConVarChange(AllowThrowables, AllowThrowablesChanged);
	HookConVarChange(AllowUpgradeAmmo, AllowUpgradeAmmoChanged);
	HookConVarChange(AllowMeds, AllowMedsChanged);
	HookConVarChange(AllowDefibs, AllowDefibsChanged);
	HookConVarChange(AllowPills, AllowPillsChanged);
	HookConVarChange(AllowShots, AllowShotsChanged);
	HookConVarChange(AdminOverride, AdminOverrideChanged);

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	LoadTranslations("common.phrases");	
}
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}

	hAdminMenu = topmenu;

	new TopMenuObject:menu_category = AddToTopMenu(hAdminMenu, "l4d2_ia_topmenu", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT);

	if (menu_category != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu, "l4d2_ia_enable_player_menu", TopMenuObject_Item, AdminMenu_IAEnablePlayer, menu_category, "l4d2_ia_enable_player_menu", ADMFLAG_SLAY);
		AddToTopMenu(hAdminMenu, "l4d2_ia_disable_player_menu", TopMenuObject_Item, AdminMenu_IADisablePlayer, menu_category, "l4d2_ia_disable_player_menu", ADMFLAG_SLAY);
		AddToTopMenu(hAdminMenu, "l4d2_ia_config_menu", TopMenuObject_Item, AdminMenu_IAConfigMenu, menu_category, "l4d2_ia_config_menu", ADMFLAG_SLAY);
	}
}
public Handle_Category(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "无限子弹选项");
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "无限子弹选项");
	}
}
public AdminMenu_IAEnablePlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "启动无限子弹");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayEnablePlayerMenu(param);
	}
}
public DisplayEnablePlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_EnablePlayer);
	SetMenuTitle(menu, "开启无限子弹选项");

	SetMenuExitBackButton(menu, true);

	decl String:name[32];
	decl String:info[32];

	if (InfiniteAmmo[client] == 0)
	{
		Format(name, sizeof(name), "启动我无限子弹");
		Format(info, sizeof(info), "%i", client);
		AddMenuItem(menu, info, name);
	}
	Format(name, sizeof(name), "启动所有玩家无限子弹");
	Format(info, sizeof(info), "477");
	AddMenuItem(menu, info, name);
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && InfiniteAmmo[i] == 0 && i != client)
		{
			Format(name, sizeof(name), "%N", i);
			Format(info, sizeof(info), "%i", i);
			AddMenuItem(menu, info, name);
		}
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_EnablePlayer(Handle:menu, MenuAction:action, client, param)
{
	decl String:name[32];
	decl String:info[32];

	GetMenuItem(menu, param, info, sizeof(info), _, name, sizeof(name));
	new target = StringToInt(info);

	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		if (target > 0)
		{
			if (target == client)
			{
				InfiniteAmmo[client] = 1;
				PrintToChat(client,"\x01[SM] 无限子弹 \x03启动");	
			}
			else if (target == 477)
			{
				new count = 0;
				for (new i=1; i<=MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && InfiniteAmmo[i] == 0 && i != client)
					{
						InfiniteAmmo[i] = 1;
						PrintToChat(client,"[SM] 无限子弹启动 %N", i);
						PrintToChat(i, "\x01[SM] You have been given \x03Infinite Ammo");
						count++;
					}
				}
				if (count == 0)
				{
					PrintToChat(client,"[SM] 没有其他玩家，无法启动无限子弹");
				}
			}
			else if (target > 0)
			{
				if (IsClientInGame(target) && GetClientTeam(target) == 2 && !IsFakeClient(target) && InfiniteAmmo[target] == 0)
				{
					InfiniteAmmo[target] = 1;
					PrintToChat(client,"[SM] 无限子弹启动 %N", target);
					PrintToChat(target, "\x01[SM] You have been given \x03Infinite Ammo");
				}
			}
			DisplayEnablePlayerMenu(client);
		}
	}
}
public AdminMenu_IADisablePlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "关闭无限子弹");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayDisablePlayerMenu(param);
	}
}
public DisplayDisablePlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DisablePlayer);
	SetMenuTitle(menu, "关闭无限子弹选项");

	SetMenuExitBackButton(menu, true);

	decl String:name[32];
	decl String:info[32];

	if (InfiniteAmmo[client] == 1)
	{
		Format(name, sizeof(name), "关闭我无限子弹");
		Format(info, sizeof(info), "%i", client);
		AddMenuItem(menu, info, name);
	}
	Format(name, sizeof(name), "关闭所有玩家无限子弹");
	Format(info, sizeof(info), "477");
	AddMenuItem(menu, info, name);
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && InfiniteAmmo[i] == 1 && i != client)
		{
			Format(name, sizeof(name), "%N", i);
			Format(info, sizeof(info), "%i", i);
			AddMenuItem(menu, info, name);
		}
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_DisablePlayer(Handle:menu, MenuAction:action, client, param)
{
	decl String:name[32];
	decl String:info[32];

	GetMenuItem(menu, param, info, sizeof(info), _, name, sizeof(name));
	new target = StringToInt(info);

	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		if (target > 0)
		{
			if (target == client)
			{
				InfiniteAmmo[client] = 0;
				PrintToChat(client,"\x01[SM] 无限子弹 \x05关闭");	
			}
			else if (target == 477)
			{
				new count = 0;
				for (new i=1; i<=MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && InfiniteAmmo[i] == 1 && i != client)
					{
						InfiniteAmmo[i] = 0;
						PrintToChat(client,"[SM] 无限子弹关闭 %N", i);
						PrintToChat(i,"\x01[SM] You have lost \x05Infinite Ammo");
						count++;
					}
				}
				if (count == 0)
				{
					PrintToChat(client,"[SM] 没有其他玩家，无法关闭无限子弹");
				}
			}
			else if (target > 0)
			{
				if (IsClientInGame(target) && GetClientTeam(target) == 2 && !IsFakeClient(target) && InfiniteAmmo[target] == 1)
				{
					InfiniteAmmo[target] = 0;
					PrintToChat(client,"[SM] 无限子弹关闭 %N", target);
					PrintToChat(target,"\x01[SM] You have lost \x05Infinite Ammo");
				}
			}
			DisplayDisablePlayerMenu(client);
		}
	}
}
public AdminMenu_IAConfigMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "无限子弹配置");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayIAConfigMenu(param);
	}
}
public DisplayIAConfigMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_IAConfigMenu);
	SetMenuTitle(menu, "无限子弹配置选项");

	SetMenuExitBackButton(menu, true);

	decl String:name[64];

	if (GetConVarInt(IAmmo) == 0)
	{
		Format(name, sizeof(name), "启动无限子弹");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "关闭无限子弹");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowGL) == 0)
	{
		Format(name, sizeof(name), "开启无限榴弹炮子弹");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "关闭无限榴弹炮子弹");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowM60) == 0)
	{
		Format(name, sizeof(name), "开启M60无限子弹");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "关闭M60无限子弹");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowChainsaw) == 0)
	{
		Format(name, sizeof(name), "开启无限电锯燃料");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "关闭无限电锯燃料");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowThrowables) == 0)
	{
		Format(name, sizeof(name), "开启无限投掷品");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "关闭无限投掷品");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowMeds) == 0)
	{
		Format(name, sizeof(name), "开启无限医疗包");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "关闭无限医疗包");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowDefibs) == 0)
	{
		Format(name, sizeof(name), "开启无限电疗器");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "关闭无限电疗器");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowPills) == 0)
	{
		Format(name, sizeof(name), "开启无限止痛药");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "关闭无限止痛药");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AllowShots) == 0)
	{
		Format(name, sizeof(name), "开启无限肾上腺");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "关闭无限肾上腺");
		AddMenuItem(menu, name, name);
	}

	if (GetConVarInt(AdminOverride) == 0)
	{
		Format(name, sizeof(name), "开启管理员无限子弹");
		AddMenuItem(menu, name, name);
	}
	else
	{
		Format(name, sizeof(name), "关闭管理员无限子弹");
		AddMenuItem(menu, name, name);
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_IAConfigMenu(Handle:menu, MenuAction:action, client, param)
{
	decl String:name[64];

	GetMenuItem(menu, param, name, sizeof(name), _, name, sizeof(name));

	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		if (StrContains(name, "启动无限子弹", false) != -1)
		{
			SetConVarInt(IAmmo, 1);
			PrintToChat(client,"[SM] 无限子弹已启动");
		}
		else if (StrContains(name, "关闭无限子弹", false) != -1)
		{
			SetConVarInt(IAmmo, 0);
			PrintToChat(client,"[SM] 无限子弹已关闭");
		}
		else if (StrContains(name, "启动榴弹炮无限弹药", false) != -1)
		{
			SetConVarInt(AllowGL, 1);
			PrintToChat(client,"[SM] 无限榴弹炮已开启");
		}
		else if (StrContains(name, "关闭榴弹炮无限弹药", false) != -1)
		{
			SetConVarInt(AllowGL, 0);
			PrintToChat(client,"[SM] 无限榴弹炮已关闭");
		}
		else if (StrContains(name, "启动无限M60子弹", false) != -1)
		{
			SetConVarInt(AllowM60, 1);
			PrintToChat(client,"[SM] 无限M60已开启");
		}
		else if (StrContains(name, "关闭无限M60子弹", false) != -1)
		{
			SetConVarInt(AllowM60, 0);
			PrintToChat(client,"[SM] 无限M60已关闭");
		}
		else if (StrContains(name, "启动电锯无限燃料", false) != -1)
		{
			SetConVarInt(AllowChainsaw, 1);
			PrintToChat(client,"[SM] 无限电锯已开启");
		}
		else if (StrContains(name, "关闭电锯无限燃料", false) != -1)
		{
			SetConVarInt(AllowChainsaw, 0);
			PrintToChat(client,"[SM] 无限电锯已关闭");
		}
		else if (StrContains(name, "开启无限投掷品", false) != -1)
		{
			SetConVarInt(AllowThrowables, 1);
			PrintToChat(client,"[SM] 无限投掷品已开启");
		}
		else if (StrContains(name, "关闭无限投掷品", false) != -1)
		{
			SetConVarInt(AllowThrowables, 0);
			PrintToChat(client,"[SM] 无限投掷品已关闭");
		}
		else if (StrContains(name, "开启无限医疗包", false) != -1)
		{
			SetConVarInt(AllowMeds, 1);
			PrintToChat(client,"[SM] 无限医疗包已开启");
		}
		else if (StrContains(name, "关闭无限医疗包", false) != -1)
		{
			SetConVarInt(AllowMeds, 0);
			PrintToChat(client,"[SM] 无限医疗包已关闭");
		}
		else if (StrContains(name, "开启无限电击器", false) != -1)
		{
			SetConVarInt(AllowDefibs, 1);
			PrintToChat(client,"[SM] 无限电击器已开启");
		}
		else if (StrContains(name, "关闭无限电击器", false) != -1)
		{
			SetConVarInt(AllowDefibs, 0);
			PrintToChat(client,"[SM] 无限电击器已关闭");
		}
		else if (StrContains(name, "开启无限止痛药", false) != -1)
		{
			SetConVarInt(AllowPills, 1);
			PrintToChat(client,"[SM] 无限止痛药已开启");
		}
		else if (StrContains(name, "关闭无限止痛药", false) != -1)
		{
			SetConVarInt(AllowPills, 0);
			PrintToChat(client,"[SM] 无限止痛药已关闭");
		}
		else if (StrContains(name, "开启无限肾上腺", false) != -1)
		{
			SetConVarInt(AllowShots, 1);
			PrintToChat(client,"[SM] 无限肾上腺已开启");
		}
		else if (StrContains(name, "关闭无限肾上腺", false) != -1)
		{
			SetConVarInt(AllowShots, 0);
			PrintToChat(client,"[SM] 无限肾上腺已关闭");
		}
		else if (StrContains(name, "开启管理员无限子弹", false) != -1)
		{
			SetConVarInt(AdminOverride, 1);
			PrintToChat(client,"[SM] 管理员无限子弹已开启");
		}
		else if (StrContains(name, "关闭管理员无限子弹", false) != -1)
		{
			SetConVarInt(AdminOverride, 0);
			PrintToChat(client,"[SM] 管理员无限子弹已关闭");
		}
		DisplayIAConfigMenu(client);
	}
}
public IAmmoChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == IAmmo)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(IAmmo, oldval);
		}
		else
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientConnected(i))
				{
					if (oldval == 2)
					{
						InfiniteAmmo[i] = 0;
						PrintToChat(i, "\x01[SM] 你已经关闭 \x05无限子弹");
					}
					else if (newval == 2) 
					{
						InfiniteAmmo[i] = 1;
						PrintToChat(i, "\x01[SM] 你已经启动了 \x03无限子弹");
					}
				}
			}
		}
	}
}
public AllowGLChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowGL)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowGL, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowM60Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowM60)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowM60, oldval);
		}		
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowChainsawChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowChainsaw)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowChainsaw, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowThrowablesChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowThrowables)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowThrowables, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowUpgradeAmmoChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowUpgradeAmmo)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 1)
			SetConVarInt(AllowUpgradeAmmo, oldval);
	}
}
public AllowMedsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowMeds)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowMeds, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowDefibsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowDefibs)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowDefibs, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowPills, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowPillsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowPills)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowPills, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowShots, 0);
		}
	}
}
public AllowShotsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AllowShots)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 2)
		{
			SetConVarInt(AllowShots, oldval);
		}
		else if (newval == 2)
		{
			SetConVarInt(AllowGL, 0);
			SetConVarInt(AllowM60, 0);
			SetConVarInt(AllowThrowables, 0);
			SetConVarInt(AllowChainsaw, 0);
			SetConVarInt(AllowMeds, 0);
			SetConVarInt(AllowDefibs, 0);
			SetConVarInt(AllowPills, 0);
		}
	}
}
public AdminOverrideChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == AdminOverride)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);
		
		if (newval == oldval) 
			return;
		
		if (newval < 0 || newval > 1)
			SetConVarInt(AdminOverride, oldval);
	}
}
public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(IAmmo) == 2)
	{
		InfiniteAmmo[client] = 1;
	}
}
public Action:Command_IAmmo(client, args)
{
	new EnableVar = GetConVarInt(IAmmo);
	if (EnableVar == 0)
	{
		ReplyToCommand(client, "[SM] 无限子弹已经禁用");
		return Plugin_Handled;
	}	
	if (args < 1)
	{
		if (client > 0)
		{
			if (InfiniteAmmo[client] == 0)
			{
				InfiniteAmmo[client] = 1;
				PrintToChat(client,"\x01[SM] 无限子弹 \x03启动");
			}
			else
			{
				InfiniteAmmo[client] = 0;
				PrintToChat(client,"\x01[SM] 无限子弹 \x05关闭");
			}
		}
		else
		{
			ReplyToCommand(client, "[SM] 游戏中启动自己无限子弹");	
		}
	}		
	else if (args == 1)
	{
		ReplyToCommand(client, "[SM] Usage: l4d2_iammo <#userid|name> <0|1>");
	}
	else if (args == 2)
	{
		new String:target[32], String:arg2[32];
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, arg2, sizeof(arg2));
		new args2 = StringToInt(arg2);
			
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for (new i=0; i<target_count; i++)
		{
			new String:clientname[64];
			GetClientName(target_list[i], clientname, sizeof(clientname));
			if (args2 == 0)
			{
				ReplyToCommand(client,"[SM] 无限子弹关闭 %s",clientname);	
				InfiniteAmmo[target_list[i]] = 0;
				PrintToChat(target_list[i],"\x01[SM] You have lost \x05Infinite Ammo");
			}
			else if (args2 == 1)
			{
				ReplyToCommand(client,"[SM] 无限子弹启动 %s",clientname);	
				InfiniteAmmo[target_list[i]] = 1;
				PrintToChat(target_list[i],"\x01[SM] You have been given \x03Infinite Ammo");
			}			
			else
			{
				ReplyToCommand(client, "[SM] Usage: l4d2_iammo <#userid|name> <0|1>");
			}		
		}
	}
	else if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: l4d2_iammo <#userid|name> <0|1>");
	}

	return Plugin_Handled;
}
public Action:Event_PlayerDisconnect(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (InfiniteAmmo[client] == 1)
	{
		InfiniteAmmo[client] = 0;
	}
}
public Action:Event_WeaponDrop(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "item", weapon, sizeof(weapon));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				if (GetConVarInt(AllowThrowables) > 0 || IsAdminOverride(client))
				{
					if (Throwing[client] == 1)
					{
						if (StrEqual(weapon, "pipe_bomb"))
						{
							CheatCommand(client, "give", "pipe_bomb");
						}
						else if (StrEqual(weapon, "vomitjar"))
						{
							CheatCommand(client, "give", "vomitjar");
						}
						else if (StrEqual(weapon, "molotov"))
						{
							CheatCommand(client, "give", "molotov");
						}
						Throwing[client] = 0;
					}
				}
			}
		}
	}
}

public CheckForOnlyOn()
{
	if (GetConVarInt(AllowGL) == 2)
		return true;
	else if (GetConVarInt(AllowM60) == 2)
		return true;
	else if (GetConVarInt(AllowChainsaw) == 2)
		return true;
	else if (GetConVarInt(AllowThrowables) == 2)
		return true;
	else if (GetConVarInt(AllowMeds) == 2)
		return true;
	else if (GetConVarInt(AllowDefibs) == 2)
		return true;
	else if (GetConVarInt(AllowPills) == 2)
		return true;
	else if (GetConVarInt(AllowShots) == 2)
		return true;
	else
		return false;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				new slot = -1;
				new clipsize;
				Throwing[client] = 0;
				if (StrEqual(weapon, "pipe_bomb") || StrEqual(weapon, "vomitjar") || StrEqual(weapon, "molotov"))
				{
					if (GetConVarInt(AllowThrowables) > 0 || IsAdminOverride(client))
						Throwing[client] = 1;
				}
				else if (StrEqual(weapon, "grenade_launcher"))
				{
					if (GetConVarInt(AllowGL) > 0 || IsAdminOverride(client))
					{
						slot = 0;
						clipsize = 1;
					}
				}
				else if (StrEqual(weapon, "pumpshotgun") || StrEqual(weapon, "shotgun_chrome"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 8;
					}
				}
				else if (StrEqual(weapon, "autoshotgun") || StrEqual(weapon, "shotgun_spas"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 10;
					}
				}
				else if (StrEqual(weapon, "hunting_rifle") || StrEqual(weapon, "sniper_scout"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 15;
					}
				}
				else if (StrEqual(weapon, "sniper_awp"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 20;
					}
				}
				else if (StrEqual(weapon, "sniper_military"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 30;
					}
				}
				else if (StrEqual(weapon, "rifle_ak47"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 40;
					}
				}
				else if (StrEqual(weapon, "smg") || StrEqual(weapon, "smg_silenced") || StrEqual(weapon, "smg_mp5") || StrEqual(weapon, "rifle") || StrEqual(weapon, "rifle_sg552"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 50;
					}
				}
				else if (StrEqual(weapon, "rifle_desert"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 0;
						clipsize = 60;
					}
				}
				else if (StrEqual(weapon, "rifle_m60"))
				{
					if (GetConVarInt(AllowM60) > 0 || IsAdminOverride(client))
					{
						slot = 0;
						clipsize = 150;
					}
				}
				else if (StrEqual(weapon, "pistol"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 1;
						if (GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_isDualWielding") > 0)
							clipsize = 30;
						else
							clipsize = 15;
					}
				}
				else if (StrEqual(weapon, "pistol_magnum"))
				{
					if (!CheckForOnlyOn())
					{
						slot = 1;
						clipsize = 8;
					}
				}
				else if (StrEqual(weapon, "chainsaw"))
				{
					if (GetConVarInt(AllowChainsaw) > 0 || IsAdminOverride(client))
					{
						slot = 1;
						clipsize = 30;
					}
				}
				if (slot == 0 || slot == 1)
				{
					new weaponent = GetPlayerWeaponSlot(client, slot);
					if (weaponent > 0 && IsValidEntity(weaponent))
					{
						SetEntProp(weaponent, Prop_Send, "m_iClip1", clipsize+1);
						if (slot == 0 && (GetConVarInt(AllowUpgradeAmmo) > 0 || IsAdminOverride(client)))
						{
							new upgradedammo = GetEntProp(weaponent, Prop_Send, "m_upgradeBitVec");
							if (upgradedammo == 1 || upgradedammo == 2 || upgradedammo == 5 || upgradedammo == 6)
								SetEntProp(weaponent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", clipsize+1);
						}
					}
				}
			}
		}
	}
}
public Action:Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				if (GetConVarInt(AllowMeds) > 0 || IsAdminOverride(client))
				{
					CreateTimer(0.1, TimerMedkit, client);
				}
			}
		}
	}
}
public Action:TimerMedkit(Handle:timer, any:client)
{
	CheatCommand(client, "give", "first_aid_kit");
}
public Action:Event_DefibrillatorUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				if (GetConVarInt(AllowDefibs) > 0 || IsAdminOverride(client))
				{
					CreateTimer(0.1, TimerDefib, client);
				}
			}
		}
	}
}
public Action:TimerDefib(Handle:timer, any:client)
{
	CheatCommand(client, "give", "defibrillator");
}
public Action:Event_PillsUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				if (GetConVarInt(AllowPills) > 0 || IsAdminOverride(client))
				{
					CreateTimer(0.1, TimerPills, client);
				}
			}
		}
	}
}
public Action:TimerPills(Handle:timer, any:client)
{
	CheatCommand(client, "give", "pain_pills");
}
public Action:Event_AdrenalineUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(IAmmo) > 0)
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && InfiniteAmmo[client] == 1)
			{
				if (GetConVarInt(AllowShots) > 0 || IsAdminOverride(client))
				{
					CreateTimer(0.1, TimerShot, client);
				}
			}
		}
	}
}
public Action:TimerShot(Handle:timer, any:client)
{
	CheatCommand(client, "give", "adrenaline");
}
public IsAdminOverride(client)
{
	if (GetConVarInt(AdminOverride) > 0)
	{
		if (GetUserFlagBits(client) > 0)
		{
			return true;
		}
	}
	return false;	
}
stock CheatCommand(client, const String:command[], const String:arguments[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments );
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}