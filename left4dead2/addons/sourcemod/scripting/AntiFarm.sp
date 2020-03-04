#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:Timers = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "AntiFarm",
	author = "Accelerator",
	description = "Stop farming",
	version = "3.3",
	url = "http://core-ss.org"
}
public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("finale_radio_start", Event_FinaleRadioStart);
}

public Action:Event_RoundStart(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if (Timers != INVALID_HANDLE)
	{
		CloseHandle(Timers);
		Timers = INVALID_HANDLE;
	}
	
	SetConVarInt(FindConVar("director_no_specials"), 0, false, false);
	
	new String:current_map[64];
	GetCurrentMap(current_map, 63);
	if (StrEqual(current_map, "c1m4_atrium", false))
	{
		Timers = CreateTimer(80.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c2m5_concert", false))
	{
		Timers = CreateTimer(180.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c3m4_plantation", false))
	{
		Timers = CreateTimer(500.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c4m5_milltown_escape", false))
	{
		Timers = CreateTimer(75.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c5m5_bridge", false))
	{
		Timers = CreateTimer(45.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c6m3_port", false))
	{
		Timers = CreateTimer(70.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c7m3_port", false))
	{
		Timers = CreateTimer(80.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c8m5_rooftop", false))
	{
		Timers = CreateTimer(180.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c9m2_lots", false))
	{
		Timers = CreateTimer(900.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c10m5_houseboat", false))
	{
		Timers = CreateTimer(250.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c11m5_runway", false))
	{
		Timers = CreateTimer(90.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c12m5_cornfield", false))
	{
		Timers = CreateTimer(350.0, Timer_DisableBosses);
	}
	else if (StrEqual(current_map, "c13m4_cutthroatcreek", false))
	{
		Timers = CreateTimer(55.0, Timer_DisableBosses);
	}
	else
	{
		Timers = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

public Action:Event_FinaleRadioStart(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if (Timers != INVALID_HANDLE)
	{
		CloseHandle(Timers);
		Timers = INVALID_HANDLE;
	}

	SetConVarInt(FindConVar("monsterbots_on"), 1, false, false);
	SetConVarInt(FindConVar("director_no_specials"), 0, false, false);
}

public Action:Timer_DisableBosses(Handle:timer)
{
	SetConVarInt(FindConVar("monsterbots_on"), 0, false, false);
	SetConVarInt(FindConVar("director_no_specials"), 1, false, false);
	
	Timers = INVALID_HANDLE;
	
	return Plugin_Stop;
}