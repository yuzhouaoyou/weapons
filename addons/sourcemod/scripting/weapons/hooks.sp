/*  CS:GO Weapons&Knives SourceMod Plugin
 *
 *  Copyright (C) 2017 Kağan 'kgns' Üstüngel
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

public void HookPlayer(int client)
{
	if(g_bEnableStatTrak)
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public void UnhookPlayer(int client)
{
	if(g_bEnableStatTrak)
		SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

Action GiveNamedItemPre(int client, char classname[64], CEconItemView &item, bool &ignoredCEconItemView, bool &OriginIsNULL, float Origin[3])
{
	if (IsValidClient(client))
	{
		int team = GetClientTeam(client);
		
		if (g_iKnife[client][team] != 0 && IsKnifeClass(classname))
		{
			ignoredCEconItemView = true;

			if (g_iKnife[client][team] == -1)
			{
				int max = menuKnife.ItemCount - 1;
				int random = GetRandomInt(2, max);
				
				char output[4];
				menuKnife.GetItem(random, output, sizeof(output));
				strcopy(classname, sizeof(classname), g_WeaponClasses[StringToInt(output)]);
			}
			else
			{
				strcopy(classname, sizeof(classname), g_WeaponClasses[g_iKnife[client][team]]);
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

void GiveNamedItemPost(int client, const char[] classname, const CEconItemView item, int entity, bool OriginIsNULL, const float Origin[3])
{
	if (IsValidClient(client) && IsValidEntity(entity))
	{
		int index;
		if (g_smWeaponIndex.GetValue(classname, index))
		{
			if (IsKnifeClass(classname))
			{
				EquipPlayerWeapon(client, entity);
			}
			SetWeaponProps(client, entity);
		}
	}
}

public Action ChatListener(int client, const char[] command, int args)
{
	char msg[128];
	GetCmdArgString(msg, sizeof(msg));
	StripQuotes(msg);
	if (StrEqual(msg, "!ws") || StrEqual(msg, "!knife") || StrEqual(msg, "!wslang") || StrContains(msg, "!nametag") == 0 || StrContains(msg, "!seed") == 0)
	{
		return Plugin_Handled;
	}
	else if (g_bWaitingForNametag[client] && IsValidClient(client) && g_iIndex[client] > -1 && !IsChatTrigger())
	{
		CleanNameTag(msg, sizeof(msg));
		
		g_bWaitingForNametag[client] = false;
		
		if (StrEqual(msg, "!cancel") || StrEqual(msg, "!iptal"))
		{
			PrintToChat(client, " %s \x02%t", g_ChatPrefix, "NameTagCancelled");
			return Plugin_Handled;
		}
		
		//int team = IsWeaponIndexInOnlyOneTeam(g_iIndex[client]) ? CS_TEAM_T : GetClientTeam(client);
		int team = GetClientTeam(client);
		g_NameTag[client][g_iIndex[client]][team] = msg;
		
		RefreshWeapon(client, g_iIndex[client]);
		
		char updateFields[1024];
		char escaped[257];
		db.Escape(msg, escaped, sizeof(escaped));
		char weaponName[32];
		RemoveWeaponPrefix(g_WeaponClasses[g_iIndex[client]], weaponName, sizeof(weaponName));
		char teamName[4];
		teamName = team == CS_TEAM_T ? "" : "ct_";
		Format(updateFields, sizeof(updateFields), "%s%s_tag = '%s'", teamName, weaponName, escaped);
		UpdatePlayerData(client, updateFields);
		
		PrintToChat(client, " %s \x04%t: \x01\"%s\"", g_ChatPrefix, "NameTagSuccess", msg);
		
		/* NAMETAGCOLOR
		int menuTime;
		if((menuTime = GetRemainingGracePeriodSeconds(client)) >= 0)
		{
			CreateColorsMenu(client).Display(client, menuTime);
		}
		*/
		
		return Plugin_Handled;
	}
	else if (g_bWaitingForSeed[client] && IsValidClient(client) && g_iIndex[client] > -1 && !IsChatTrigger())
	{
		g_bWaitingForSeed[client] = false;
		
		int seedInt;
		if (StrEqual(msg, "!cancel") || StrEqual(msg, "!iptal") || StrEqual(msg, ""))
		{
			PrintToChat(client, " %s \x02%t", g_ChatPrefix, "SeedCancelled");
			return Plugin_Handled;
		}
		else if ((seedInt = StringToInt(msg)) < 0 || seedInt > 8192)
		{
			PrintToChat(client, " %s \x02%t", g_ChatPrefix, "SeedFailed");
			return Plugin_Handled;
		}
		//int team = IsWeaponIndexInOnlyOneTeam(g_iIndex[client]) ? CS_TEAM_T : GetClientTeam(client);
		int team = GetClientTeam(client);
		g_iWeaponSeed[client][g_iIndex[client]][team] = seedInt;
		g_iSeedRandom[client][g_iIndex[client]] = -1;
		
		RefreshWeapon(client, g_iIndex[client]);
		
		CreateTimer(0.1, SeedMenuTimer, GetClientUserId(client));
		
		PrintToChat(client, " %s \x04%t: \x01%i", g_ChatPrefix, "SeedSuccess", seedInt);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (float(GetClientHealth(victim)) - damage > 0.0)
		return Plugin_Continue;
		
	if (!(damagetype & DMG_SLASH) && !(damagetype & DMG_BULLET))
		return Plugin_Continue;
		
	if (!IsValidClient(attacker))
		return Plugin_Continue;
		
	if (!IsValidWeapon(weapon))
		return Plugin_Continue;
		
	int index = GetWeaponIndex(weapon);
	
	//int team = IsWeaponIndexInOnlyOneTeam(g_iIndex[attacker]) ? CS_TEAM_T : GetClientTeam(attacker);
	int team = GetClientTeam(attacker);
	if (index != -1 && g_iSkins[attacker][index][team] != 0 && g_iStatTrak[attacker][index][team] != 1)
		return Plugin_Continue;
		
	if (GetEntProp(weapon, Prop_Send, "m_nFallbackStatTrak") == -1)
		return Plugin_Continue;
		
	int previousOwner;
	if ((previousOwner = GetEntPropEnt(weapon, Prop_Send, "m_hPrevOwner")) != INVALID_ENT_REFERENCE && previousOwner != attacker)
		return Plugin_Continue;
	
	g_iStatTrakCount[attacker][index][team]++;
	/*
	if (IsKnife(weapon))
	{
		SetEntProp(weapon, Prop_Send, "m_nFallbackStatTrak", g_iKnifeStatTrakMode == 0 ? GetTotalKnifeStatTrakCount(attacker) : g_iStatTrakCount[attacker][index]);
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_nFallbackStatTrak", g_iStatTrakCount[attacker][index]);
	}
	*/

	char updateFields[256];
	char weaponName[32];
	RemoveWeaponPrefix(g_WeaponClasses[index], weaponName, sizeof(weaponName));
	char teamName[4];
	teamName = team == CS_TEAM_T ? "" : "ct_";
	Format(updateFields, sizeof(updateFields), "%s%s_trak_count = %d", teamName, weaponName, g_iStatTrakCount[attacker][index][team]);
	UpdatePlayerData(attacker, updateFields);
	return Plugin_Continue;
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_iRoundStartTime = GetTime();
}

Action WeaponCanUsePre(int client, int weapon, bool& pickup)
{
	if (IsKnife(weapon) && IsValidClient(client))
	{
		pickup = true;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
