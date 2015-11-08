#pragma semicolon 1
#pragma newdecls optional

#include <sourcemod>
#include <tf2items>
#include <tf2attributes>
#include <tf2_stocks>
#include <sdkhooks>
#include <saxtonhale>
#include <morecolors>

//#tryinclude <saxtonhale> //COMPILE WITH ONLY VSH OR FF2, NOT BOTH
//#tryinclude <freak_fortress_2>

#define TF_MAX_PLAYERS	34

public Plugin myinfo =
{
	name = "[VSH] Stock Melee Enhancer",
	author = "Starblaster64",
	description = "Grants most stock melees small bonuses.",
	version = "0.2",
	url = "https://github.com/Starblaster64/vsh-enhanced-stock-melees"
};

//Variables
ConVar cvarEnabled, cvarAnnounce, cvarReskins, cvarScout, cvarScoutVar, cvarSoldier, cvarSoldierVar, cvarDemo, cvarDemoVar, cvarHeavy, cvarHeavyVar, cvarEngineer, cvarEngineerVar, cvarMedic, cvarMedicVar, cvarSniper, cvarSniperVar ;
bool g_bEnabled = false;
int IsEnabled, ReskinsEnabled, ScoutUse, SoldierUse, DemoUse, HeavyUse, EngineerUse, EngineerVar, MedicUse, MedicVar, SniperUse;
float ScoutVar, SoldierVar, DemoVar, HeavyVar, SniperVar, Announce = 45.0;
int MeleeUses[TF_MAX_PLAYERS];
Handle useHUD;

public void OnPluginStart()
{
	//Create CVARs
	cvarEnabled = CreateConVar("hale_melees_enabled", "1.0", "Enables the plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAnnounce = CreateConVar("hale_melees_announce", "45.0", "Broadcasts of any enabled enhanced melees will be displayed every X seconds. Must be > 1 to display at all.", FCVAR_PLUGIN, true, 0.0, false);
	cvarReskins = CreateConVar("hale_melees_reskins", "0.0", "Sets whether reskins of stock melees will receive the same bonuses as stock melees.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvarScout = CreateConVar("hale_melees_scout", "1.0", "Controls how many times the Scout's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarScoutVar = CreateConVar("hale_melees_scout_variable", "2.0", "Sets how long the Bonk! condition lasts for.", FCVAR_PLUGIN, true, 0.0, false);
	
	cvarSoldier = CreateConVar("hale_melees_soldier", "1.0", "Controls how many times the Soldier's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarSoldierVar = CreateConVar("hale_melees_soldier_variable", "1.5", "Sets how much faster taunts are with shovel out as a percentage. Cannot be lower than 1.", FCVAR_PLUGIN, true, 1.0, false);
	
	cvarDemo = CreateConVar("hale_melees_demo", "2.0", "Controls how many times the Demoman's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarDemoVar = CreateConVar("hale_melees_demo_variable", "1.5", "Sets how long the healing effect lasts in seconds. Cannot be negative.", FCVAR_PLUGIN, true, 0.0, false);
	
	cvarHeavy = CreateConVar("hale_melees_heavy", "2.0", "Controls how many times the Heavy's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarHeavyVar = CreateConVar("hale_melees_heavy_variable", "400.0", "Sets how much extra knockback the fists receive in Hammer Units. Can be negative.", FCVAR_PLUGIN);
	
	cvarEngineer = CreateConVar("hale_melees_engineer", "1.0", "Controls how many times the Engineer's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarEngineerVar = CreateConVar("hale_melees_engineer_variable", "100.0", "Sets how much metal is gained per use. Cannot be negative.", FCVAR_PLUGIN, true, 0.0, false);
	
	cvarMedic = CreateConVar("hale_melees_medic", "1.0", "Controls how many times the Medic's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarMedicVar = CreateConVar("hale_melees_medic_variable", "1.0", "Sets how many team-mates to revive per use. -1 for the entire team (not recommended).", FCVAR_PLUGIN, true, 0.0, false);
	
	cvarSniper = CreateConVar("hale_melees_sniper", "-1.0", "Controls how many times the Sniper's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarSniperVar = CreateConVar("hale_melees_variable", "5.0", "Sets how long the outline lasts. Cannot be negative (duh).", FCVAR_PLUGIN, true, 0.0, false);
	
	AutoExecConfig(true, "VSHMeleeEnhancer"); //Generates config file in cfg/sourcemod
	
	//Create hud element (like VSH's rageHUD)
	useHUD = CreateHudSynchronizer();

	for (new client = 1; client <= MaxClients; client++)
	{
		MeleeUses[client] = 0;
		if (IsClientInGame(client)) // IsValidClient(client, false)
		{
			//SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
	HookEvent("player_hurt", event_hurt, EventHookMode_Pre);
	
	RegConsoleCmd("taunt", OnPlayerTaunt);
}

public void OnConfigsExecuted()
{
	IsEnabled = cvarEnabled.IntValue;
	Announce = cvarAnnounce.FloatValue;
	ReskinsEnabled = cvarReskins.IntValue;
	
	ScoutUse = cvarScout.IntValue;
	ScoutVar = cvarScoutVar.FloatValue;
	
	SoldierUse = cvarSoldier.IntValue;
	SoldierVar = cvarSoldierVar.FloatValue;
	
	DemoUse = cvarDemo.IntValue;
	DemoVar = cvarDemoVar.FloatValue;
	
	HeavyUse = cvarHeavy.IntValue;
	HeavyVar = cvarHeavyVar.FloatValue;
	
	EngineerUse = cvarEngineer.IntValue;
	EngineerVar = cvarEngineerVar.IntValue;
	
	MedicUse = cvarMedic.IntValue;
	MedicVar = cvarMedicVar.IntValue;
	
	SniperUse = cvarSniper.IntValue;
	SniperVar = cvarSniperVar.FloatValue;
	
	/*SpyUse = cvarSpy.IntValue;
	SpyVar = cvarSpyVar.FloatValue;
	
	PyroUse = cvarPyro.IntValue;
	PyroVar = cvarPyroVar.FloatValue;*/
	
	//PrintToChatAll("Attributes: %s", BallAttributes); //DEBUG
	
	if (VSH_IsSaxtonHaleModeMap() && IsEnabled)
	{
		g_bEnabled = true;
		PrintToChatAll("g_bEnabled true"); //DEBUG
		
		if (Announce > 1.0)
			CreateTimer(Announce, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		g_bEnabled = false;
		PrintToChatAll("g_bEnabled false"); //DEBUG
	}
}

public void OnClientPostAdminCheck(int client)
{
	MeleeUses[client] = 0;
	//SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToChatAll("player %i spawned", client); //DEBUG
	if (g_bEnabled && VSH_GetRoundState() != -1 && client != VSH_GetSaxtonHaleUserId())
	{
		if (TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			MeleeUses[client] = ScoutUse;
			PrintToChatAll("testbatspawn %i", MeleeUses[client]); //DEBUG
		}
		if (TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			MeleeUses[client] = SoldierUse;
			RequestFrame(Frame_Spawn, client);
		}
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
			MeleeUses[client] = DemoUse;
		if (TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			MeleeUses[client] = HeavyUse;
			PrintToChatAll("testheavy"); //DEBUG
			PrintToChatAll("%i uses", MeleeUses[client]); //DEBUG
			RequestFrame(Frame_Spawn, client);
		}
		if (TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			MeleeUses[client] = EngineerUse;
			PrintToChatAll("%i uses", MeleeUses[client]); //DEBUG
		}
		if (TF2_GetPlayerClass(client) == TFClass_Medic)
			MeleeUses[client] = MedicUse;
		if (TF2_GetPlayerClass(client) == TFClass_Sniper)
			MeleeUses[client] = SniperUse;
		/*else
			MeleeUses[client] = 0;*/
	}
	return Plugin_Continue;
}

public Frame_Spawn(any:client)
{
	PrintToChatAll("timer made"); //DEBUG

	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		int swepindex = (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		PrintToChatAll("testst2"); //DEBUG
		switch (swepindex)
		{
			case 5, 195: //Stock Fists
			{
				TF2Attrib_SetByDefIndex(weapon, 215, HeavyVar);
				TF2Attrib_SetByDefIndex(weapon, 216, HeavyVar);
				PrintToChatAll("Fists changed! from spawn timer"); //DEBUG
			}
			case 6, 196: //Stock Shovel
			{
				TF2Attrib_SetByDefIndex(weapon, 128, 1.0);
				TF2Attrib_SetByDefIndex(weapon, 201, SoldierVar);
			}
			case 1127, 1123, 1071, 1013, 954, 939, 880, 474, 423, 264, 587: //Reskins
			{
				if (ReskinsEnabled)
				{
					if (TF2_GetPlayerClass(client) == TFClass_Heavy)
					{
						TF2Attrib_SetByDefIndex(weapon, 215, HeavyVar);
						TF2Attrib_SetByDefIndex(weapon, 216, HeavyVar);
					}
					if (TF2_GetPlayerClass(client) == TFClass_Soldier)
					{
						TF2Attrib_SetByDefIndex(weapon, 128, 1.0);
						TF2Attrib_SetByDefIndex(weapon, 201, SoldierVar);
					}
				}
			}
		}
	}
}

public Action event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	for (int iclient = 1; iclient <= MaxClients; iclient++)
	{
		
	}
	
	if (g_bEnabled && VSH_GetRoundState() == 0)
	{
		//CreateTimer(9.1, StartBallTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		
	}
	
	return Plugin_Continue;
}

public Action event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bEnabled && VSH_GetRoundState() == 1)
	{
		MeleeUses[client] = 0;
	}
	return Plugin_Continue;
}

/*public OnEntityCreated(entity, const char[] classname)
{
	if (!StrEqual(classname, "instanced_scripted_scene", false)) return;
	SDKHook(entity, SDKHook_Spawn, OnSceneSpawned);
}

public Action OnSceneSpawned(entity) //Checks for stock taunts
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwner");
	char scenefile[128];
	GetEntPropString(entity, Prop_Data, "m_iszSceneFile", scenefile, sizeof(scenefile));
	if (StrContains(scenefile, "taunt03") || //Stock melee taunt
		StrContains(scenefile, "taunt02") || //Secondary weapon taunts (used on most classes for Saxxy class weapons)
		StrContains(scenefile, "taunt06") || //Halloween thriller taunt (for Halloween compatibility)
		StrContains(scenefile, "taunt09"))	//Soldier Robot Costume taunt (Also for Halloween compatibility)
	{
		// Stock-compatible taunt played, now check if holding stock weapon
		PrintToChatAll("Stock compat taunt detected!!"); //DEBUG
	}
}*/

public Action event_hurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsEnabled || VSH_GetRoundState() != 1)
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToChatAll("client %i", client); //DEBUG
	PrintToChatAll("hale %i", VSH_GetSaxtonHaleUserId());
	
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	PrintToChatAll("attacker %i", attacker); //DEBUG
	
	int HaleTeam = VSH_GetSaxtonHaleTeam();
	PrintToChatAll("hale team %i", HaleTeam); //DEBUG

	//new damage = GetEventInt(event, "damageamount");
	//new custom = GetEventInt(event, "custom");
	int weapon = GetEventInt(event, "weaponid");
	if (GetClientTeam(attacker) == HaleTeam)
		return Plugin_Continue;

	if (!IsPlayerAlive(attacker) || !IsPlayerAlive(client) || client == attacker)
		return Plugin_Continue;

	int meleeindex = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
	int meleeweapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);
	int reskin = -1;

	if (meleeindex == 1127 || //Reskins
		meleeindex == 1123 ||
		meleeindex == 1071 ||
		meleeindex == 1013 ||
		meleeindex == 954 ||
		meleeindex == 939 ||
		meleeindex == 880 ||
		meleeindex == 474 ||
		meleeindex == 423 ||
		meleeindex == 264 ||
		meleeindex == 587)
		reskin = 1;

	if (meleeindex == 0 || //Stock
		meleeindex == 190 ||
		meleeindex == 5 ||
		meleeindex == 195 ||
		meleeindex == 3 ||
		meleeindex == 193)
		reskin = 0;

	if (TF2_GetPlayerClass(attacker) == TFClass_Scout)
	{
		if (weapon == TF_WEAPON_BAT || weapon == TF_WEAPON_BAT_FISH && (reskin == 0 || (ReskinsEnabled && reskin != -1)))
		{
			PrintToChatAll("testbat, %i", MeleeUses[attacker]); //DEBUG
			if (MeleeUses[attacker] > 0 || MeleeUses[attacker] == -1)
			{
				TF2_AddCondition(attacker, TFCond_Bonked, ScoutVar);
				if (MeleeUses[attacker] != -1)
					MeleeUses[attacker] -= 1;
				return Plugin_Changed;
			}
		}
	}
	/*if (TF2_GetPlayerClass(attacker) == TFClass_Sniper)
	{
		if (weapon == TF_WEAPON_CLUB && (reskin == 0 || (ReskinsEnabled && reskin != -1)))
		{
			PrintToChatAll("testkukri, %i", MeleeUses[attacker]); //DEBUG
			if (MeleeUses[attacker] > 0 || MeleeUses[attacker] == -1)
			{
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
				CreateTimer()
				if (MeleeUses[attacker] != -1)
					MeleeUses[attacker] -= 1;
				return Plugin_Changed;
			}
		}
	}*/
	if (TF2_GetPlayerClass(attacker) == TFClass_Heavy)
	{
		if (weapon == TF_WEAPON_FISTS && (reskin == 0 || (ReskinsEnabled && reskin != -1)))
		{
			if (MeleeUses[attacker] == 0)
			{
				TF2Attrib_RemoveByDefIndex(meleeweapon, 215);
				TF2Attrib_RemoveByDefIndex(meleeweapon, 216);
			}
			if (MeleeUses[attacker] > 0 || MeleeUses[attacker] == -1)
			{
				if (MeleeUses[attacker] != -1)
				{
					MeleeUses[attacker] -= 1;
					PrintToChatAll("testfists, %i", MeleeUses[attacker]); //DEBUG
				}
				//return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerTaunt(int client, int args)
{
	if (!IsPlayerAlive(client) || GetClientTeam(client) == VSH_GetSaxtonHaleTeam())
		return Plugin_Continue;
	
	int ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (ActiveWeapon == -1)
		return Plugin_Continue;
	
	int wepindex = GetEntProp(ActiveWeapon, Prop_Send, "m_iItemDefinitionIndex");
	int reskin = -1;
	
	if (wepindex == 1 || wepindex == 6 || wepindex == 7 || wepindex == 8 || //Stock
		wepindex == 191 || wepindex == 196 || wepindex == 197 || wepindex == 198) //Strange Stock
			reskin = 0;
		
	if (wepindex == 609 || //Demo Reskins
		wepindex == 196 || wepindex == 662 || wepindex == 795 || wepindex == 804 || wepindex == 884 || 
		wepindex == 893 || wepindex == 902 || wepindex == 911 || wepindex == 960 || wepindex == 969 || //Engineer Reskins
		wepindex == 1143 || //Medic Reskins
		wepindex == 264 || wepindex == 423 || wepindex == 474 || wepindex == 880 || wepindex == 939 || 
		wepindex == 954 || wepindex == 1013 || wepindex == 1071 || wepindex == 1123 || wepindex == 1127) //Multi-class Reskins
			reskin = 1;
			
	if (reskin == 0 || (ReskinsEnabled && reskin != -1))
	{
		PrintToChatAll("Stock compat taunt detected!!"); //DEBUG
		//if (MeleeUses[client] > 0 || MeleeUses[client] == -1)
		if (!TF2_IsPlayerInCondition(client, TFCond_Taunting))
			RequestFrame(Frame_TauntBonus, client);
	}
	
	return Plugin_Continue;
}
public Frame_TauntBonus(any:clientid)
{
	int client = clientid;
	PrintToChatAll("firt frame"); //DEBUG
	PrintToChatAll("%i has %i uses", client, MeleeUses[client]); //DEBUG
	if (MeleeUses[client] > 0 || MeleeUses[client] == -1)
	{
		if (TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			if (TF2_IsPlayerInCondition(client, TFCond_Dazed))
			{
				TF2_RemoveCondition(client, TFCond_Dazed);
				if (MeleeUses[client] != -1)
					MeleeUses[client] -= 1;
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			if (!TF2_IsPlayerInCondition(client, view_as<TFCond>(73)))
			{
				TF2_AddCondition(client, view_as<TFCond>(73), DemoVar);
				if (MeleeUses[client] != -1)
					MeleeUses[client] -= 1;
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			int metal = TF2_GetMetal(client);
			TF2_SetMetal(client, metal + 100);
			if (MeleeUses[client] != -1)
				MeleeUses[client] -= 1;
			PrintToChatAll("metal give"); //DEBUG
			//return Plugin_Handled;
		}
		if (TF2_GetPlayerClass(client) == TFClass_Medic)
			PrintToChatAll("place"); //DEBUG
	}
}

public void OnClientDisconnect(int client)
{
	MeleeUses[client] = 0;
}

public Action Timer_Announce(Handle mTimer) //Broadcasts
{
	//static int announcecount = -1;
	//announcecount++;
	int RandAnnounce = (GetRandomInt(1, 9));
	if (Announce > 1.0 && g_bEnabled)
	{
		switch (RandAnnounce)
		{
			case 1: //Scout
			{
				if (ScoutUse == 0)
					RequestFrame(Timer_Reroll);

				if (ReskinsEnabled && ScoutUse != 0)
				{
					if (ScoutUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Scouts{default} can hit Hale with their stock Bat or reskins to gain {unique}%.2f{default} seconds of Bonk!.", ScoutVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Scouts{default} can hit Hale with their stock Bat or reskins to gain {unique}%.2f{default} seconds of Bonk! up to {unique}%i{default} times per life.", ScoutVar, ScoutUse);
				}
				else if (ScoutUse != 0)
				{
					if (ScoutUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Scouts{default} can hit Hale with their stock Bat to gain {unique}%.2f{default} seconds of Bonk!.", ScoutVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Scouts{default} can hit Hale with their stock Bat to gain {unique}%.2f{default} seconds of Bonk! up to {unique}%i{default} times per life.", ScoutVar, ScoutUse);
				}
			}
			case 2: //Soldier
			{
				if (SoldierUse == 0)
					RequestFrame(Timer_Reroll);

				if (ReskinsEnabled && SoldierUse != 0)
				{
					if (SoldierUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Soldiers{default} can taunt with their stock Shovel or reskins while raged to unrage themselves. Also makes them taunt {unique}%.2fx{default} faster.", SoldierVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Soldiers{default} can taunt with their stock Shovel or reskins while raged to unrage themselves up to {unique}%i{default} times per life. Also makes them taunt {unique}%.2fx{default} faster.", SoldierUse, SoldierVar);
				}
				else if (SoldierUse != 0)
				{
					if (SoldierUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Soldiers{default} can taunt with their stock Shovel while raged to unrage themselves. Also makes them taunt {unique}%.2fx{default} faster.", SoldierVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Soldiers{default} can taunt with their stock Shovel while raged to unrage themselves up to {unique}%i{default} times per life. Also makes them taunt {unique}%.2fx{default} faster.", SoldierUse, SoldierVar);
				}
			}
			case 3: //Demoman
			{
				if (DemoUse == 0)
					RequestFrame(Timer_Reroll);

				if (ReskinsEnabled && DemoUse != 0)
				{
					if (DemoUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Demomen{default} can taunt with their stock Bottle or reskins to regain HP for {unique}%.2f{default} seconds.", DemoVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Demomen{default} can taunt with their stock Bottle or reskins to regain HP for {unique}%.2f{default} seconds up to {unique}%i{default} times per life.", DemoVar, DemoUse);
				}
				else if (DemoUse != 0)
				{
					if (DemoUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Demomen{default} can taunt with their stock Bottle to regain HP for {unique}%.2f{default} seconds.", DemoVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Demomen{default} can taunt with their stock Bottle to regain HP for {unique}%.2f{default} seconds up to {unique}%i{default} times per life.", DemoVar, DemoUse);
				}
			}
			case 4: //Heavy
			{
				if (HeavyUse == 0)
					RequestFrame(Timer_Reroll);

				if (ReskinsEnabled && HeavyUse != 0)
				{
					if (HeavyUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Heavies{default} can punch Hale with their stock Fists or reskins for {unique}%.2fHU{default} extra knockback force.", HeavyVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Heavies{default} can punch Hale with their stock Fists or reskins for {unique}%.2fHU{default} extra knockback force up to {unique}%i{default} times per life.", HeavyVar, HeavyUse);
				}
				else if (HeavyUse != 0)
				{
					if (HeavyUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Heavies{default} can punch Hale with their stock Fists for {unique}%.2fHU{default} extra knockback force.", HeavyVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Heavies{default} can punch Hale with their stock Fists for {unique}%.2fHU{default} extra knockback force up to {unique}%i{default} times per life.", HeavyVar, HeavyUse);
				}
			}
			case 5: //Engineer
			{
				if (EngineerUse == 0)
					RequestFrame(Timer_Reroll);

				if (ReskinsEnabled && EngineerUse != 0)
				{
					if (EngineerUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Engineers{default} can taunt with their stock Wrench or reskins to gain {unique}%i{default} metal.", EngineerVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Engineers{default} can taunt with their stock Wrench or reskins to gain {unique}%i{default} metal up to {unique}%i{default} times per life.", EngineerVar, EngineerUse);
				}
				else if (EngineerUse != 0)
				{
					if (EngineerUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Engineers{default} can taunt with their stock Wrench to gain {unique}%i{default} metal.", EngineerVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Engineers{default} can taunt with their stock Wrench to gain {unique}%i{default} metal up to {unique}%i{default} times per life.", EngineerVar, EngineerUse);
				}
			}
			case 6: //Medic
			{
				if (MedicUse == 0)
					RequestFrame(Timer_Reroll);

				if (ReskinsEnabled && MedicUse != 0)
				{
					if (MedicUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Medics{default} can revive up to {unique}%i{default} team-mates at once by taunting with their stock Bonesaw or reskins out.", MedicVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Medics{default} can revive up to {unique}%i{default} team-mates at once up to {unique}%i{default} times per life by taunting with their stock Bonesaw or reskins out.", MedicVar, MedicUse);
				}
				else if (MedicUse != 0)
				{
					if (MedicUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Medics{default} can revive up to {unique}%i{default} team-mates at once by taunting with their stock Bonesaw.", MedicVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Medics{default} can revive up to {unique}%i{default} team-mates at once up to {unique}%i{default} times per life by taunting with their stock Bonesaw out.", MedicVar, MedicUse);
				}
			}
			case 7: //Sniper
			{
				//announcecount = 0;
				
				if (SniperUse == 0)
					RequestFrame(Timer_Reroll);
				
				if (ReskinsEnabled && SniperUse != 0)
				{
					if (SniperUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Snipers{default} can use their stock Kukri or reskins to outline Hale on hit for {unique}%.2f{default} seconds.", SniperVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Snipers{default} can use their stock Kukri or reskins to outline Hale on hit for {unique}%.2f{default} seconds up to {unique}%i{default} times per life.", SniperVar, SniperUse);
				}
				else if (SniperUse != 0)
				{
					if (SniperUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Snipers{default} can use their stock Kukri to outline Hale on hit for {unique}%.2f{default} seconds.", SniperVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Snipers{default} can use their stock Kukri to outline Hale on hit for {unique}%.2f{default} seconds up to {unique}%i{default} times per life.", SniperVar, SniperUse);
				}
			}
			default:
			{
				if (ReskinsEnabled)
					CPrintToChatAll("{olive}[VSH]{default} Some classes have a special effect on their stock melee weapons and reskins!");
				else
					CPrintToChatAll("{olive}[VSH]{default} Some classes have a special effect on their stock melee weapons!");
			}
		}
	}
}

public Timer_Reroll(any:data) //Re-roll for announcements
{
	CreateTimer(0.1, Timer_Announce, TIMER_FLAG_NO_MAPCHANGE);
}

stock int TF2_GetMetal(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return 0;
	return GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);
}

stock void TF2_SetMetal(int client, int metal)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return;
	SetEntProp(client, Prop_Send, "m_iAmmo", metal, _, 3);
}

/*
	Player health adder
	By: Chdata
*/
stock void AddPlayerHealth(int iClient, int iAdd, int iOverheal = 0, bool bStaticMax = false)
{
	int iHealth = GetClientHealth(iClient);
	int iNewHealth = iHealth + iAdd;
	int iMax = bStaticMax ? iOverheal : GetEntProp(iClient, Prop_Data, "m_iMaxHealth") + iOverheal;
	if (iHealth < iMax)
	{
		iNewHealth = min(iNewHealth, iMax);
		SetEntityHealth(iClient, iNewHealth);
	}
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon > MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}

stock bool IsValidClient(int iClient)
{
	return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

/*stock GetPlayerCount()
{
	new iCount, i; iCount = 0;

	for( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i))
		{
			iCount++;
		}
	}

	return iCount;
}*/