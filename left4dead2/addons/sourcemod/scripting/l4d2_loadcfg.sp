#pragma semicolon 1
#include <sourcemod>

new bool:rs_start;

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("map_transition", Event_maptransition);
	HookEvent("round_start_post_nav", Event_round_start_post_nav);
	HookEvent("round_freeze_end", Event_round_freeze_end);
}

public Action:Event_RoundStart(Handle:Event, const String:strName[], bool:DontBroadcast)
{
	rs_start = false;

	CreateTimer(1.0, ty_10000000);
	CreateTimer(10.0, ty_10000000);
	CreateTimer(20.0, ty_10000002);
	CreateTimer(60.0, ty_10000000);
	CreateTimer(200.0, ty_10000000);
	CreateTimer(300.0, ty_10000000);

	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ServerCommand("exec loadcfg/round_end.cfg");

	return Plugin_Continue;
}

public Action:Event_maptransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	ServerCommand("exec loadcfg/map_transition.cfg");

	return Plugin_Continue;
}
public Action:Event_round_start_post_nav(Handle:event, const String:name[], bool:dontBroadcast)
{
	ServerCommand("exec loadcfg/round_start_post_nav.cfg");

	return Plugin_Continue;
}

public Action:Event_round_freeze_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	ServerCommand("exec loadcfg/round_freeze_end.cfg");

	return Plugin_Continue;
}

public ty_10000001()
{
	ServerCommand("exec loadcfg/timerupdate.cfg");
}

public Action:ty_10000000(Handle:timer, any:client)
{
	if (!rs_start)
	{
		ServerCommand("exec loadcfg/round_start.cfg");
		rs_start = true;
	}
	
	ty_10000001();

	return Plugin_Stop;
}

public ty_10000003()
{
	ServerCommand("exec loadcfg/timer_round_start.cfg");
}

public Action:ty_10000002(Handle:timer, any:client)
{
	ty_10000003();

	return Plugin_Stop;
}