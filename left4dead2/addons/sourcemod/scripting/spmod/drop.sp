public Action:Command_Drop(client, args)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Handled;

	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);

	if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle") || StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5") || StrEqual(weapon, "weapon_shotgun_spas") || StrEqual(weapon, "weapon_shotgun_chrome") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_grenade_launcher") || StrEqual(weapon, "weapon_rifle_m60"))
		DropSlot(client, 0);

	return Plugin_Continue;
}

public DropSlot(client, slot)
{
	if (GetPlayerWeaponSlot(client, slot) > 0)
	{
		new String:weapon[32];
		new ammo;
		new clip;
		new upgrade;
		new upammo;
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(GetPlayerWeaponSlot(client, slot), weapon, 32);

		if (slot == 0)
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
			upgrade = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec");
			upammo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
			if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
			{
				ammo = GetEntData(client, ammoOffset+(12));
				SetEntData(client, ammoOffset+(12), 0);
			}
			else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
			{
				ammo = GetEntData(client, ammoOffset+(20));
				SetEntData(client, ammoOffset+(20), 0);
			}
			else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
			{
				ammo = GetEntData(client, ammoOffset+(28));
				SetEntData(client, ammoOffset+(28), 0);
			}
			else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
			{
				ammo = GetEntData(client, ammoOffset+(32));
				SetEntData(client, ammoOffset+(32), 0);
			}
			else if (StrEqual(weapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(36));
				SetEntData(client, ammoOffset+(36), 0);
			}
			else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
			{
				ammo = GetEntData(client, ammoOffset+(40));
				SetEntData(client, ammoOffset+(40), 0);
			}
			else if (StrEqual(weapon, "weapon_grenade_launcher"))
			{
				ammo = GetEntData(client, ammoOffset+(68));
				SetEntData(client, ammoOffset+(68), 0);
			}
		}

		new index = CreateEntityByName(weapon);
		new Float:origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		origin[2]+=20;
		TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(index);
		ActivateEntity(index);
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, slot));

		if (slot == 0)
		{
			SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
			SetEntProp(index, Prop_Send, "m_iClip1", clip);
			SetEntProp(index, Prop_Send, "m_upgradeBitVec", upgrade);
			SetEntProp(index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo);
		}

	}
}

/*public Action:Command_Drop(client, args)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Continue;

	DropSlot(client);
	return Plugin_Handled;
}

public DropSlot(client)
{
	if (!(GetPlayerWeaponSlot(client, 0) == -1)) 
	{
		new String:weapon[32];
		new Ammo;
		new clip;
		new upgrade;
		new upammo;

		GetEdictClassname(GetPlayerWeaponSlot(client, 0), weapon, 32);
		if (!StrEqual(weapon, "", false))
		{
			Ammo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iExtraPrimaryAmmo", 4);
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", 4);
			upgrade = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec", 4);
			upammo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);

			new index = CreateEntityByName(weapon);
			new Float:origin[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
			origin[2]+=20;
			TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(index);
			ActivateEntity(index);
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
			SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", Ammo, 4);
			SetEntProp(index, Prop_Send, "m_iClip1", clip, 4);
			SetEntProp(index, Prop_Send, "m_upgradeBitVec", upgrade, 4);
			SetEntProp(index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo, 4);
		}
	}
}*/