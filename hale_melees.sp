#pragma semicolon 1
#pragma newdecls optional

#include <sourcemod>
#include <tf2attributes>
#include <tf2_stocks>
#include <sdkhooks>
#include <saxtonhale>
#include <morecolors>


#define TF_MAX_PLAYERS	34

public Plugin myinfo =
{
	name = "[VSH] Stock Melee Enhancer",
	author = "Starblaster64",
	description = "Grants most stock melees small bonuses.",
	version = "0.4a",
	url = "https://github.com/Starblaster64/vsh-enhanced-stock-melees"
};

//Variables
ConVar cvarEnabled, cvarAnnounce, cvarReskins, cvarScout, cvarScoutVar, cvarSoldier, cvarSoldierVar, cvarDemo, cvarDemoVar, cvarHeavy, cvarHeavyVar, cvarEngineer, cvarEngineerVar;
bool g_bEnabled = false;
int IsEnabled, ReskinsEnabled, ScoutUse, SoldierUse, DemoUse, HeavyUse, EngineerUse, EngineerVar;
float ScoutVar, SoldierVar, DemoVar, HeavyVar, Announce = 45.0;
int MeleeUses[TF_MAX_PLAYERS];
//Handle useHUD;

public void OnPluginStart()
{
	//Create CVARs
	cvarEnabled = CreateConVar("hale_melees_enabled", "1.0", "Enables the plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAnnounce = CreateConVar("hale_melees_announce", "45.0", "Broadcasts of any enabled enhanced melees will be displayed every X seconds. Must be > 1 to display at all.", FCVAR_PLUGIN, true, 0.0, false);
	cvarReskins = CreateConVar("hale_melees_reskins", "0.0", "Sets whether reskins of stock melees will receive the same bonuses as stock melees.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvarScout = CreateConVar("hale_melees_scout", "2.0", "Determines how many times the Scout's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarScoutVar = CreateConVar("hale_melees_scout_variable", "1.0", "Sets how long the Bonk! condition lasts for.", FCVAR_PLUGIN, true, 0.0, false);
	
	cvarSoldier = CreateConVar("hale_melees_soldier", "1.0", "Enables/Disables the Soldier's melee enhancement.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarSoldierVar = CreateConVar("hale_melees_soldier_variable", "1.30", "Sets how much faster Ubercharge is generated while healing a Soldier with a Shovel out. Cannot be lower than 1.0.", FCVAR_PLUGIN, true, 1.0, false);
	
	//cvarPyro = CreateConVar("hale_melees_pyro", "-1.0", "Determines how many times the Pyro's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	//cvarPyroVar = CreateConVar("hale_melees_pyro_variable", "5.0", "Something soething Pyro", FCVAR_PLUGIN, true, 0.0, false);
	
	cvarDemo = CreateConVar("hale_melees_demo", "2.0", "Determines how many times the Demoman's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarDemoVar = CreateConVar("hale_melees_demo_variable", "1.5", "Sets how long the healing effect lasts in seconds. Cannot be negative.", FCVAR_PLUGIN, true, 0.0, false);
	
	cvarHeavy = CreateConVar("hale_melees_heavy", "2.0", "Determines how many times the Heavy's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarHeavyVar = CreateConVar("hale_melees_heavy_variable", "400.0", "Sets how much extra knockback the fists receive in Hammer Units. Can be negative.", FCVAR_PLUGIN);
	
	cvarEngineer = CreateConVar("hale_melees_engineer", "1.0", "Determines how many times the Engineer's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	cvarEngineerVar = CreateConVar("hale_melees_engineer_variable", "100.0", "Sets how much metal is gained per use. Cannot be negative.", FCVAR_PLUGIN, true, 0.0, false);
	
	//cvarMedic = CreateConVar("hale_melees_medic", "1.0", "Determines how many times the Medic's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	//cvarMedicVar = CreateConVar("hale_melees_medic_variable", "1.0", "Sets how many team-mates to revive per use. -1 for the entire team (not recommended).", FCVAR_PLUGIN, true, 0.0, false);
	
	//cvarSniper = CreateConVar("hale_melees_sniper", "-1.0", "Determines how many times the Sniper's stock ability can trigger. -1 for infinite.", FCVAR_PLUGIN, true, -1.0, false);
	//cvarSniperVar = CreateConVar("hale_melees_sniper_variable", "5.0", ".", FCVAR_PLUGIN, true, 0.0, false);
	
	AutoExecConfig(true, "VSHMeleeEnhancer"); //Generates config file in cfg/sourcemod
	
	//Create hud element (like VSH's rageHUD)
	//useHUD = CreateHudSynchronizer();

	for (new client = 1; client <= MaxClients; client++)
	{
		MeleeUses[client] = 0;
		if (IsClientInGame(client)) // IsValidClient(client, false)
		{
			SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		}
	}
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
	//HookEvent("player_hurt", event_hurt, EventHookMode_Pre);
	
	RegConsoleCmd("taunt", OnPlayerTaunt);
}

public void OnConfigsExecuted()
{
	IsEnabled = GetConVarInt(cvarEnabled);
	Announce = GetConVarFloat(cvarAnnounce);
	ReskinsEnabled = GetConVarInt(cvarReskins);
	
	ScoutUse = GetConVarInt(cvarScout);
	ScoutVar = GetConVarFloat(cvarScoutVar);
	
	SoldierUse = GetConVarInt(cvarSoldier);
	SoldierVar = GetConVarFloat(cvarSoldierVar);
	
	DemoUse = GetConVarInt(cvarDemo);
	DemoVar = GetConVarFloat(cvarDemoVar);
	
	HeavyUse = GetConVarInt(cvarHeavy);
	HeavyVar = GetConVarFloat(cvarHeavyVar);
	
	EngineerUse = GetConVarInt(cvarEngineer);
	EngineerVar = GetConVarInt(cvarEngineerVar);
	
	//MedicUse = GetConVarInt(cvarMedic);
	//MedicVar = GetConVarInt(cvarMedicVar);
	
	//SniperUse = cvarSniper.IntValue;
	//SniperVar = cvarSniperVar.FloatValue;
	
	//SpyUse = cvarSpy.IntValue;
	//SpyVar = cvarSpyVar.FloatValue;
	
	//PyroUse = cvarPyro.IntValue;
	//PyroVar = cvarPyroVar.FloatValue;
	
	if (VSH_IsSaxtonHaleModeMap() && IsEnabled)
	{
		g_bEnabled = true;
		
		if (Announce > 1.0)
			CreateTimer(Announce, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		g_bEnabled = false;
	}
}

public void OnClientPostAdminCheck(int client)
{
	MeleeUses[client] = 0;
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public Action event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int HaleTeam = VSH_GetSaxtonHaleTeam();
	MeleeUses[client] = 0;
	if (g_bEnabled && VSH_GetRoundState() != -1 && GetClientTeam(client) !=HaleTeam)
	{
		if ((GetMelee(client) == 0 || (GetMelee(client) == 1 && ReskinsEnabled)) && GetMelee(client) == 0 && TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			MeleeUses[client] = ScoutUse;
			if (MeleeUses[client] == -1)
				CPrintToChat(client, "You have {unique}infinite{default} stock melee uses this life!");
			else
				CPrintToChat(client, "You have {unique}%i{default} stock melee uses this life!", MeleeUses[client]);
		}
		if ((GetMelee(client) == 0 || (GetMelee(client) == 1 && ReskinsEnabled)) && TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			MeleeUses[client] = SoldierUse;
			if (MeleeUses[client] > 0)
			{
				CPrintToChat(client, "Your stock melee enhancement is active this life!");
				RequestFrame(Frame_Spawn, client);
			}
		}
		if ((GetMelee(client) == 0 || (GetMelee(client) == 1 && ReskinsEnabled)) && TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			MeleeUses[client] = DemoUse;
			if (MeleeUses[client] == -1)
				CPrintToChat(client, "You have {unique}infinite{default} stock melee uses this life!");
			else
				CPrintToChat(client, "You have {unique}%i{default} stock melee uses this life!", MeleeUses[client]);
		}
		if ((GetMelee(client) == 0 || (GetMelee(client) == 1 && ReskinsEnabled)) && TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			MeleeUses[client] = HeavyUse;
			if (MeleeUses[client] > 0 || MeleeUses[client] == -1)
			{
				if (MeleeUses[client] == -1)
					CPrintToChat(client, "You have {unique}infinite{default} stock melee uses this life!");
				else
					CPrintToChat(client, "You have {unique}%i{default} stock melee uses this life!", MeleeUses[client]);
				RequestFrame(Frame_Spawn, client);
			}
		}
		if ((GetMelee(client) == 0 || (GetMelee(client) == 1 && ReskinsEnabled)) && TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			MeleeUses[client] = EngineerUse;
			if (MeleeUses[client] == -1)
				CPrintToChat(client, "You have {unique}infinite{default} stock melee uses this life!");
			else
				CPrintToChat(client, "You have {unique}%i{default} stock melee uses this life!", MeleeUses[client]);
		}
		/*if ((GetMelee(client) == 0 || (GetMelee(client) == 1 && ReskinsEnabled)) && TF2_GetPlayerClass(client) == TFClass_Medic)
			MeleeUses[client] = MedicUse;*/
		/*if ((GetMelee(client) == 0 || (GetMelee(client) == 1 && ReskinsEnabled)) && TF2_GetPlayerClass(client) == TFClass_Sniper)
			MeleeUses[client] = SniperUse;*/
		/*else
			MeleeUses[client] = 0; //Players who spawn mid-round will not recieve enhancements.*/
	}
	return Plugin_Continue;
}

public Frame_Spawn(any client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		int swepindex = (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		switch (swepindex)
		{
			case 5, 195: //Stock Fists
			{
				TF2Attrib_SetByDefIndex(weapon, 215, HeavyVar);
				TF2Attrib_SetByDefIndex(weapon, 216, HeavyVar);
			}
			case 6, 196: //Stock Shovel
			{
				TF2Attrib_SetByDefIndex(weapon, 128, 1.0);
				TF2Attrib_SetByDefIndex(weapon, 239, SoldierVar);
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
						TF2Attrib_SetByDefIndex(weapon, 239, SoldierVar);
					}
				} 
			}
		}
	}
}

public Action event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bEnabled && VSH_GetRoundState() != -1)
	{
		MeleeUses[client] = 0;
	}
	return Plugin_Continue;
}

public Action OnTakeDamageAlive(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsEnabled || VSH_GetRoundState() != 1)
		return Plugin_Continue;

	if (client == attacker)
		return Plugin_Continue;
		
	int HaleTeam = VSH_GetSaxtonHaleTeam();
	if (GetClientTeam(client) != HaleTeam)
		return Plugin_Continue;

	if (!IsPlayerAlive(attacker) || !IsPlayerAlive(client) || client == attacker)
		return Plugin_Continue;
		
	//int meleeindex = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
	//int wepindex = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
	int meleeweapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);
	
	if (!GetMeleeActive(attacker))
		return Plugin_Continue;
	
	if (TF2_GetPlayerClass(attacker) == TFClass_Scout)
	{
		if (GetMelee(attacker) == 0 || (ReskinsEnabled && GetMelee(attacker) != -1))
		{
			if (MeleeUses[attacker] > 0 || MeleeUses[attacker] == -1)
			{
				TF2_AddCondition(attacker, TFCond_Bonked, ScoutVar);
				if (MeleeUses[attacker] != -1)
				{
					MeleeUses[attacker] -= 1;
					CPrintToChat(attacker, "You have {unique}%i{default} melee uses left!", MeleeUses[attacker]);
				}
				return Plugin_Changed;
			}
		}
	}
	if (TF2_GetPlayerClass(attacker) == TFClass_Heavy)
	{
		if (GetMelee(attacker) == 0 || (ReskinsEnabled && GetMelee(attacker) != -1))
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
					CPrintToChat(attacker, "You have {unique}%i{default} melee uses left!", MeleeUses[attacker]);
				}
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerTaunt(int client, int args)
{
	if (!IsPlayerAlive(client) || GetClientTeam(client) == VSH_GetSaxtonHaleTeam())
		return Plugin_Continue;
	
	if (!GetMeleeActive(client))
		return Plugin_Continue;
			
	if (GetMelee(client) == 0 || (ReskinsEnabled && GetMelee(client) != -1))
	{
		if (!TF2_IsPlayerInCondition(client, TFCond_Taunting))
			RequestFrame(Frame_TauntBonus, client);
	}
	
	return Plugin_Continue;
}

public Action Timer_TauntBonusDemo(Handle mTimer, any client)
{
	if (!TF2_IsPlayerInCondition(client, view_as<TFCond>(73)))
	{
		TF2_AddCondition(client, view_as<TFCond>(73), DemoVar);
		if (MeleeUses[client] != -1)
		{
			MeleeUses[client] -= 1;
			CPrintToChat(client, "You have {unique}%i{default} melee uses left!", MeleeUses[client]);
		}
	}
}

public Action Timer_TauntBonusEngineer(Handle mTimer, any client) //Broadcasts
{
	int metal = TF2_GetMetal(client);
	TF2_SetMetal(client, metal + EngineerVar);
	if (MeleeUses[client] != -1)
	{
		MeleeUses[client] -= 1;
		CPrintToChat(client, "You have {unique}%i{default} melee uses left!", MeleeUses[client]);
	}
}

public Frame_TauntBonus(any clientid)
{
	int client = clientid;
	if ((MeleeUses[client] > 0 || MeleeUses[client] == -1) && TF2_IsPlayerInCondition(client, TFCond_Taunting))
	{
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			CreateTimer(4.0, Timer_TauntBonusDemo, client, TIMER_FLAG_NO_MAPCHANGE);
		} //(Mostly) Stops players cheating the system with partner taunts.
		if (TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			CreateTimer(4.0, Timer_TauntBonusEngineer, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		/*if (TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			PrintToChatAll("placeholder"); //DEBUG
		}*/
	}
}

public void OnClientDisconnect(int client)
{
	MeleeUses[client] = 0;
}

public Action Timer_Announce(Handle mTimer) //Broadcasts
{
	int RandAnnounce = (GetRandomInt(0, 6));
	if (Announce > 1.0 && g_bEnabled)
	{
		switch (RandAnnounce)
		{
			case 0: //Credits
			{
				CPrintToChatAll("{olive}[VSH]{default} Stock Melee Enhancer {steelblue}v0.4a{default} by {unique}Starblaster64{default}.");
			}
			case 1: //Scout
			{
				if (ScoutUse == 0)
					RequestFrame(Frame_Reroll);

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
					RequestFrame(Frame_Reroll);

				if (ReskinsEnabled && SoldierUse != 0)
				{
					CPrintToChatAll("{olive}[VSH]{tomato} Soldiers{default} can help Medics build uber {unique}%.2fx{default} faster by holding out their stock shovel or reskins.", SoldierVar);
				}
				else if (SoldierUse != 0)
				{
					CPrintToChatAll("{olive}[VSH]{tomato} Soldiers{default} can help Medics build uber {unique}%.2fx{default} faster by holding out their stock Shovel.", SoldierVar);
				}
			}
			case 3: //Demoman
			{
				if (DemoUse == 0)
					RequestFrame(Frame_Reroll);

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
					RequestFrame(Frame_Reroll);

				if (ReskinsEnabled && HeavyUse != 0)
				{
					if (HeavyUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Heavies{default} can punch Hale with their stock Fists or reskins for {unique}%.0fHU{default} extra knockback force.", HeavyVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Heavies{default} can punch Hale with their stock Fists or reskins for {unique}%.0fHU{default} extra knockback force up to {unique}%i{default} times per life.", HeavyVar, HeavyUse);
				}
				else if (HeavyUse != 0)
				{
					if (HeavyUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Heavies{default} can punch Hale with their stock Fists for {unique}%.0fHU{default} extra knockback force.", HeavyVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Heavies{default} can punch Hale with their stock Fists for {unique}%.0fHU{default} extra knockback force up to {unique}%i{default} times per life.", HeavyVar, HeavyUse);
				}
			}
			case 5: //Engineer
			{
				if (EngineerUse == 0)
					RequestFrame(Frame_Reroll);

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
			/*case 6: //Medic
			{
				if (MedicUse == 0)
					RequestFrame(Frame_Reroll);

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
			}*/
			/*case 7: //Sniper
			{
				//announcecount = 0;
				
				if (SniperUse == 0)
					RequestFrame(Frame_Reroll);
				
				if (ReskinsEnabled && SniperUse != 0)
				{
					if (SniperUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Snipers{default} can use their stock Kukri or reskins to outline Hale on hit for {unique}%.2f{default} seconds.", SniperVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Snipers{default} can use their stock Kukri or reskins to outline Hale on hit for {unique}%.2f{default} seconds up to {unique}%i{default} times per life.", SniperVar, SniperUse);
				}
				else if (SniperUse != 0)
				{CPrintToChat(client, "You have {unique}%i{default} uses left!", MeleeUses[client]);
					if (SniperUse == -1)
						CPrintToChatAll("{olive}[VSH]{tomato} Snipers{default} can use their stock Kukri to outline Hale on hit for {unique}%.2f{default} seconds.", SniperVar);
					else
						CPrintToChatAll("{olive}[VSH]{tomato} Snipers{default} can use their stock Kukri to outline Hale on hit for {unique}%.2f{default} seconds up to {unique}%i{default} times per life.", SniperVar, SniperUse);
				}
			}*/
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

public Frame_Reroll(any data) //Re-roll for announcements if one selected was for a disabled feature
{
	CreateTimer(0.1, Timer_Announce, TIMER_FLAG_NO_MAPCHANGE);
}

/*
	Following stocks taken from VSH.
	Credit to their original creators.
*/
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
	Player health adder.
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

stock int GetMeleeActive(int client)
{
	int melee = -1;
	if (GetMelee(client) > -1)
	{
		int ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (ActiveWeapon != -1)
		{
			int MeleeIndex = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
			if (ActiveWeapon == MeleeIndex)
				return melee = 1;
		}
		melee = 0;
	}
				
	return melee;
}

stock int GetMelee(int client)
{
	/*int ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (ActiveWeapon == -1)
		return Plugin_Continue;
	
	int wepindex = GetEntProp(ActiveWeapon, Prop_Send, "m_iItemDefinitionIndex");*/
	
	int wepindex = GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee);
	int reskin = -1;
	
	if (wepindex == 0 || 
		wepindex == 1 || 
		wepindex == 3 || 
		wepindex == 5 || 
		wepindex == 6 || 
		wepindex == 7 || 
		wepindex == 8 ||
		wepindex == 190 || 
		wepindex == 191 || 
		wepindex == 193 || 
		wepindex == 195 || 
		wepindex == 196 || 
		wepindex == 197 || 
		wepindex == 198)
			reskin = 0;
		
	if (wepindex == 609 ||
		wepindex == 587 || 
		wepindex == 660 || 
		wepindex == 196 || 
		wepindex == 662 || 
		wepindex == 795 || 
		wepindex == 804 || 
		wepindex == 884 || 
		wepindex == 893 || 
		wepindex == 902 || 
		wepindex == 911 || 
		wepindex == 960 || 
		wepindex == 969 ||
		wepindex == 1143 ||
		wepindex == 264 || 
		wepindex == 423 || 
		wepindex == 474 || 
		wepindex == 880 || 
		wepindex == 939 || 
		wepindex == 954 || 
		wepindex == 1013 || 
		wepindex == 1071 || 
		wepindex == 1123 || 
		wepindex == 1127)
			reskin = 1;
			
	return reskin;
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