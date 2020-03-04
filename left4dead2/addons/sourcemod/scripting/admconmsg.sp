#include <sourcemod>
#define PLUGIN_VERSION "0.0.3"
public Plugin:myinfo = 
{
	name = "AdminConnectmsg",
	author = "R-Hehl",
	description = "Shows players connecting admins",
	version = PLUGIN_VERSION,
	url = "http://www.compactaim.de/"
};
public OnPluginStart()
{
	// Create the rest of the cvar's
	CreateConVar("sm_admin_conmsg_version", PLUGIN_VERSION, "本插件版本", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public OnClientPostAdminCheck(client) 
{
	new AdminId:id = GetUserAdmin(client);
	if (id != INVALID_ADMIN_ID)
	{
	new String:name[32];
	GetClientName(client, name, 32);
	PrintCenterTextAll("[OP]%s已载入游戏.",name);
	}
	return true;
}