#include <sourcemod>
#include <sdktools>


#define Version "1.0"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

#define CRIT_SOUND "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav" //暴击音效

/* 武器名字
pistol   普通手枪
pistol_magnum 沙鹰
smg_silenced 消音冲锋枪
smg 普通冲锋枪
pumpshotgun 散弹枪
shotgun_chrome 散弹枪二代
autoshotgun 自动散弹枪
shotgun_spas 大散弹枪
hunting_rifle 猎枪
sniper_military 连狙
rifle M16步枪
rifle_ak47 AK47步枪
rifle_desert SCAR步枪
grenade_launcher_projectile 榴弹枪
rifle_m60 M60机关枪
rifle_sg552 突击步枪
smg_mp5 MP5冲锋枪
sniper_awp AWP狙击
sniper_scout 鸟狙
chainsaw 电锯
*/
new Handle:l4d2_crit_pistol;
new Handle:l4d2_crit_pistol_magnum;
new Handle:l4d2_crit_smg_silenced;
new Handle:l4d2_crit_smg;
new Handle:l4d2_crit_pumpshotgun;
new Handle:l4d2_crit_shotgun_chrome;
new Handle:l4d2_crit_autoshotgun;
new Handle:l4d2_crit_shotgun_spas;
new Handle:l4d2_crit_hunting_rifle;
new Handle:l4d2_crit_sniper_military;
new Handle:l4d2_crit_rifle;
new Handle:l4d2_crit_rifle_ak47;
new Handle:l4d2_crit_rifle_desert;
new Handle:l4d2_crit_grenade_launcher;
new Handle:l4d2_crit_rifle_m60;
new Handle:l4d2_crit_rifle_sg552;
new Handle:l4d2_crit_smg_mp5;
new Handle:l4d2_crit_sniper_awp;
new Handle:l4d2_crit_sniper_scout;
new Handle:l4d2_crit_chainsaw;


public Plugin:myinfo =
{
	name="Crit Systeam[暴击系统]",
	author="logki",
	description="让枪械的伤害随机化,并且有暴击的特性.",
	version=Version,
	url="www.23333.com"
};

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("该插件只能用于l4d和l4d2.");
	}
	l4d2_crit_pistol = CreateConVar("l4d2_crit_pistol","5","普通手枪伤害基础值", CVAR_FLAGS)	
	l4d2_crit_pistol_magnum = CreateConVar("l4d2_crit_pistol_magnum","6","沙鹰手枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_smg_silenced = CreateConVar("l4d2_crit_smg_silenced","4","消音冲锋枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_smg = CreateConVar("l4d2_crit_smg","4","普通冲锋枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_pumpshotgun = CreateConVar("l4d2_crit_pumpshotgun","16","散弹枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_shotgun_chrome = CreateConVar("l4d2_crit_shotgun_chrome","18","散弹枪二代伤害基础值", CVAR_FLAGS)
	l4d2_crit_autoshotgun = CreateConVar("l4d2_crit_autoshotgun","14","自动散弹枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_shotgun_spas = CreateConVar("l4d2_crit_shotgun_spas","14","大型散弹枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_hunting_rifle = CreateConVar("l4d2_crit_hunting_rifle","32","猎枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_sniper_military = CreateConVar("l4d2_crit_sniper_military","30","SG550连狙伤害基础值", CVAR_FLAGS)
	l4d2_crit_rifle = CreateConVar("l4d2_crit_rifle","10","M16步枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_rifle_ak47 = CreateConVar("l4d2_crit_rifle_ak47","10","AK47步枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_rifle_desert = CreateConVar("l4d2_crit_rifle_desert","10","SCAR步枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_grenade_launcher = CreateConVar("l4d2_crit_grenade_launcher","1","榴弹炮伤害基础值", CVAR_FLAGS)
	l4d2_crit_rifle_m60 = CreateConVar("l4d2_crit_rifle_m60","8","M60机枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_rifle_sg552 = CreateConVar("l4d2_crit_rifle_sg552","10","SG552突击步枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_smg_mp5 = CreateConVar("l4d2_crit_smg_mp5","5","MP5冲锋枪伤害基础值", CVAR_FLAGS)
	l4d2_crit_sniper_awp = CreateConVar("l4d2_crit_sniper_awp","45","AWP狙击伤害基础值", CVAR_FLAGS)
	l4d2_crit_sniper_scout = CreateConVar("l4d2_crit_sniper_scout","38","scout连狙伤害基础值", CVAR_FLAGS)
	l4d2_crit_chainsaw = CreateConVar("l4d2_crit_chainsaw","30","电锯伤害基础值", CVAR_FLAGS)
	
	
	AutoExecConfig(true, "l4d2_Crit_System");
	
	HookEvent("player_hurt", Event_Player_Hurt);
}

//玩家受伤
public Action:Event_Player_Hurt(Handle:event, String:event_name[], bool:dontBroadcast) 
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dmg_health = GetEventInt(event, "dmg_health");
	new CVdmg = 0;
	new CritNum = 95;
	new MinDmg = 10;
	new MaxDmg = 100;
	new MinCritDmg = 200;
	new MaxCritDmg = 1000;
	new String:weapon[32];
	new randomdmg;
	if (userid < 1 || userid > MaxClients || attacker < 1 || attacker > MaxClients || !IsClientInGame(userid) || !IsClientInGame(attacker)) { return; }
	
	//非幸存者的攻击返回普通伤害信息提示
	if (GetClientTeam(attacker) == 3)
	{
		Hurt_Msg(userid, attacker, dmg_health, false);
		return;
	}
	
	//友军攻击返回
	if (GetClientTeam(attacker) != 2 || GetClientTeam(userid) == 2) { return; }
	

	//枪支识别
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	//PrintToChatAll("weapon: %s", weapon);
	if (StrEqual(weapon, "pistol", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_pistol);
	}
	if (StrEqual(weapon, "pistol_magnum", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_pistol_magnum);
	}
	if (StrEqual(weapon, "smg_silenced", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_smg_silenced);
	}
	if (StrEqual(weapon, "smg", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_smg);
	}
	if (StrEqual(weapon, "pumpshotgun", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_pumpshotgun);
		//散弹枪爆率和暴击伤害降低
		MaxCritDmg = 250;
		CritNum = 98;
	}
	if (StrEqual(weapon, "shotgun_chrome", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_shotgun_chrome);
		//散弹枪爆率和暴击伤害降低
		MaxCritDmg = 250;
		CritNum = 98;
	}
	if (StrEqual(weapon, "autoshotgun", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_autoshotgun);
		//散弹枪爆率和暴击伤害降低
		MaxCritDmg = 250;
		CritNum = 98;
	}
	if (StrEqual(weapon, "shotgun_spas", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_shotgun_spas);
		//散弹枪爆率和暴击伤害降低
		MaxCritDmg = 250;
		CritNum = 98;
	}
	if (StrEqual(weapon, "hunting_rifle", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_hunting_rifle);
	}
	if (StrEqual(weapon, "sniper_military", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_sniper_military);
	}
	if (StrEqual(weapon, "rifle", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_rifle);
	}
	if (StrEqual(weapon, "rifle_ak47", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_rifle_ak47);
	}	
	if (StrEqual(weapon, "rifle_desert", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_rifle_desert);
	}	
	if (StrEqual(weapon, "grenade_launcher", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_grenade_launcher);
	}	
	if (StrEqual(weapon, "rifle_m60", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_rifle_m60);
	}	
	if (StrEqual(weapon, "rifle_sg552", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_rifle_sg552);
	}	
	if (StrEqual(weapon, "smg_mp5", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_smg_mp5);
	}	
	if (StrEqual(weapon, "sniper_awp", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_sniper_awp);
		//AWP狙击普通伤害提高
		MinDmg = 100;
		MaxDmg = 200;
	}	
	if (StrEqual(weapon, "sniper_scout", false))
	{	
		CVdmg = GetConVarInt(l4d2_crit_sniper_scout);
	}	
	if (StrEqual(weapon, "chainsaw", false))
	{	
		//电锯属性调整
		CVdmg = GetConVarInt(l4d2_crit_chainsaw);
		MinDmg = 200;
		MaxDmg = 500;
		MinCritDmg = 300;
		MaxCritDmg = 700;
	}	
	
	//没有匹配武器将返回普通伤害信息提示
	if (CVdmg < 1) 
	{ 
		Hurt_Msg(userid, attacker, dmg_health, false);
		return; 
	}
	
	//取随机暴击几率
	new randomA = GetRandomInt(1 ,100);
	
	//取伤害随机倍数
	if (randomA > CritNum){ randomdmg = GetRandomInt(MinCritDmg,MaxCritDmg); }
	else { randomdmg = GetRandomInt(MinDmg,MaxDmg); }
	
	//伤害计算
	new dmg = CVdmg * (randomdmg / 10);
	new health = GetEntProp(userid, Prop_Data, "m_iHealth") + dmg_health - dmg;
	
	//生命值设置
	if (health >= 1)
	{
		SetEntProp(userid, Prop_Data, "m_iHealth", health);
	}
	else { SetEntProp(userid, Prop_Data, "m_iHealth", 0); }
	
	//暴击提示
	if (randomA > CritNum){ Hurt_Msg(userid, attacker, dmg, true); }
	else { Hurt_Msg(userid, attacker, dmg, false); }
	
	
	//PrintToChatAll("weapon: %s  dmg: %d health: %d random: %d", weapon, dmg, health, randomdmg/10);
}

//伤害显示
public Hurt_Msg(userid, attacker, dmg, bool:crit)
{	
	//获取参数
	if (!userid || !attacker) { return; }
	if (!IsClientInGame(userid) || !IsClientInGame(attacker)) { return; }
	if (GetClientTeam(userid) == GetClientTeam(attacker)) { return; }
	new health = GetEntProp(userid, Prop_Data, "m_iHealth");
	new Float:buffer = GetEntPropFloat(userid, Prop_Send, "m_healthBuffer");
	
	if (health < 1) { health = 0; }
	
	if (!IsFakeClient(attacker))
	{ 
		if (buffer > 1.0 && health == 1)
		{
			PrintCenterText(attacker, "你的攻击对 %N 造成了 %d 伤害,他剩余: %d 点HP, %.0f 点虚血.", userid, dmg , health, buffer); 
		}
		else 
		{
			PrintCenterText(attacker, "你的攻击对 %N 造成了 %d 伤害,他剩余: %d 点HP", userid, dmg , health); 
		}
	}
	
	if (crit)
	{
		if (!IsFakeClient(attacker))
		{
			EmitSoundToClient(attacker, CRIT_SOUND);
			PrintHintText(attacker, "你对 %N 造成暴击伤害: %d", userid, dmg);
		}
		
		if (!IsFakeClient(userid))
		{
			EmitSoundToClient(userid, CRIT_SOUND);
			PrintHintText(userid, "你被 %N 攻击造成暴击伤害: %d", attacker, dmg);
		}		
	}
	
}

//加载地图
public OnMapStart()
{
	//预缓存音效文件
	PrecacheSound(CRIT_SOUND, true);
}