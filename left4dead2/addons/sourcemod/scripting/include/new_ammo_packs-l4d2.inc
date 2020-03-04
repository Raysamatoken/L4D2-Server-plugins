#if defined _naphelpers_included_
  #endinput
#endif
#define _naphelpers_included_

/**
 * Fires when the plugin is (un)loaded.
 *
 * @param iState		Initialization state.
 * @noreturn
 */
forward void NAP_OnInit(int iState);

/**
 * Fires before a Heal Box's effect is applied to the deployer.
 * @remarks This forward only runs when nap-l4d2_heal_type is
 *          set to 3.
 *
 * @param client		Given client index
 * @noreturn
 */
forward void NAP_OnHBPre(int client);

/**
 * Fires during the effect of a Heal Box being applied to the deployer.
 * @remarks This forward only runs when nap-l4d2_heal_type is set to 3.
 *
 * @param client		Given client index
 * @noreturn
 */
forward void NAP_OnHB(int client);

/**
 * Fires after a Heal Box's effect is applied to the deployer.
 * @remarks This forward only occurs when nap-l4d2_heal_type
 *          is set to 3.
 *
 * @param client		Given client index
 * @noreturn
 */
forward void NAP_OnHBPost(int client);

/**
 * Fires when an airstrike bomb explodes at a position.
 *
 * @param fHitX		X axis of the bombed position
 * @param fHitY		Y axis of the bombed position
 * @param fHitZ		Z axis of the bombed position
 *
 * @noreturn
 */
forward void NAP_OnAirstikeHit(float fHitX, float fHitY, float fHitZ);

/**
 * Checks to see if a client still feels effects from deployed ammo packs.
 *
 * @param client		Client index
 * @param effectIndex	Index of ammo pack with effect.
 *
 * @error				Invalid client or incorrect index
 * @return				true if it is still there, false otherwise
 */
native bool HasEffect(int client, int effectIndex);

/**
 * Returns the time left an ammo pack effect has.
 *
 * @param client		Client index
 * @param effectIndex	Index of ammo pack with effect
 *
 * @error				Invalid client or incorrect index
 * @return				time left on success, 0.0 on failure
 */
native float GetEffectTime(int client, int effectIndex);

/**
 * Gets the index of a deployer's ammo pack.
 *
 * @param client		Client index
 * @param effectIndex	Index of ammo pack with effect
 *
 * @error				Invalid client
 * @return				deployer's ammo pack index, else 0
 */
native int GetAPIndex(int client);

/**
 * Sets the index of a deployer's ammo pack.
 *
 * @param client		Client index
 * @param APIndex		Chosen index of ammo pack.
 *
 * @error				Invalid client or incorrect index
 * @noreturn
 */
native void SetAPIndex(int client, int APIndex);

/**
 * Gets the name of the ammo pack being deployed.
 *
 * @param client		Client index
 * @param sBuffer		String used to store the name
 * @param iBufferSize	Size of the string
 *
 * @error				Invalid client or incorrect buffer size
 * @return				Number of bytes written
 */
native int GetAPName(int client, char[] sBuffer, int iBufferSize);

/**
 * Sets the name of the ammo pack being deployed.
 *
 * @param client		Client index
 * @param sBuffer		String used to change the name
 *
 * @error				Invalid client
 * @noreturn
 */
native void SetAPName(int client, char[] sBuffer);

public void __pl_naphelpers_SetNTVOptional()
{
	MarkNativeAsOptional("HasEffect");
	MarkNativeAsOptional("GetEffectTime");
	MarkNativeAsOptional("GetAPIndex");
	MarkNativeAsOptional("SetAPIndex");
	MarkNativeAsOptional("GetAPName");
	MarkNativeAsOptional("SetAPName");
}

public SharedPlugin __pl_naphelpers =
{
	name = "nap-l4d2_helpers",
	file = "new_ammo_packs-l4d2.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

