// SPDX-FileCopyrightText: © Andrew Betson
// SPDX-License-Identifier: AGPL-3.0-or-later

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#if !defined PLUGIN_VERSION
	#define PLUGIN_VERSION "1.0.0"
#endif // !defined PLUGIN_VERSION

float gLastTickRageMeter[ MAXPLAYERS + 1 ] = { 0.0, ... };

public Plugin myinfo =
{
	name		= "[TF2] Phlogistinator Fix",
	description	= "Fixes the Phlog's mmmph meter building from damage dealt with secondaries like the Scorch Shot",
	author		= "Andrew \"andrewb\" Betson",
	version		= PLUGIN_VERSION,
	url			= "https://www.github.com/AndrewBetson/TF-PhlogFix/"
};

public void OnPluginStart()
{
	HookEvent( "player_activate", Event_PlayerActivate );
}

public void Event_PlayerActivate( Event Evt, const char[] Name, bool bDontBroadcast )
{
	int Client = GetClientOfUserId( Evt.GetInt( "userid" ) );

	SDKHook( Client, SDKHook_OnTakeDamage, OnTakeDamage );
	SDKHook( Client, SDKHook_OnTakeDamagePost, OnTakeDamagePost );
}

public void OnClientDisconnect( int Client )
{
	gLastTickRageMeter[ Client ] = 0.0;
}

public Action OnTakeDamage( int Victim, int &Attacker, int &Inflictor, float &Damage, int &DamageType )
{
	if ( TF2_GetPlayerClass( Attacker ) != TFClass_Pyro )
	{
		return Plugin_Continue;
	}

	// Burn is obvious
	// Ignite and crit (which includes minicrits) are used by various flare guns
	if ( !( DamageType & DMG_BURN ) && !( DamageType & DMG_IGNITE ) && !( DamageType & DMG_CRIT ) )
	{
		return Plugin_Continue;
	}

	int FlamethrowerHandle = GetEntPropEnt( Attacker, Prop_Send, "m_hMyWeapons", 0 );
	int FlamethrowerDefIdx = GetEntProp( FlamethrowerHandle, Prop_Send, "m_iItemDefinitionIndex" );
	if ( FlamethrowerDefIdx != 594 ) // The Phlogistinator
	{
		return Plugin_Continue;
	}

	gLastTickRageMeter[ Attacker ] = GetEntPropFloat( Attacker, Prop_Send, "m_flRageMeter" );

	return Plugin_Continue;
}

void OnTakeDamagePost(
	int Victim, int Attacker, int Inflictor,
	float Damage, int DamageType, int Weapon,
	float DamageForce[3], float DamagePosition[3]
)
{
	if ( TF2_GetPlayerClass( Attacker ) != TFClass_Pyro )
	{
		return;
	}

	// Burn is obvious
	// Ignite and crit (which includes minicrits) are used by various flare guns
	if ( !( DamageType & DMG_BURN ) && !( DamageType & DMG_IGNITE ) && !( DamageType & DMG_CRIT ) )
	{
		return;
	}

	int FlamethrowerHandle = GetEntPropEnt( Attacker, Prop_Send, "m_hMyWeapons", 0 );
	int FlamethrowerDefIdx = GetEntProp( FlamethrowerHandle, Prop_Send, "m_iItemDefinitionIndex" );
	if ( FlamethrowerDefIdx != 594 ) // The Phlogistinator
	{
		return;
	}

	int WeaponDefIdx = GetEntProp( Weapon, Prop_Send, "m_iItemDefinitionIndex" );
	if ( WeaponDefIdx == 594 ) // The Phlogistinator
	{
		return;
	}

	SetEntPropFloat( Attacker, Prop_Send, "m_flRageMeter", gLastTickRageMeter[ Attacker ] );
}
