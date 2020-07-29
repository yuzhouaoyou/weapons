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

void GetPlayerData(int client)
{
	char steamid[32];
	if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true))
	{
		char query[255];
		FormatEx(query, sizeof(query), "SELECT * FROM %sweapons WHERE steamid = '%s'", g_TablePrefix, steamid);
		db.Query(T_GetPlayerDataCallback, query, GetClientUserId(client));
	}
}

public void T_GetPlayerDataCallback(Database database, DBResultSet results, const char[] error, int userid)
{
	int clientIndex = GetClientOfUserId(userid);
	if(IsValidClient(clientIndex))
	{
		if (results == null)
		{
			LogError("Query failed! %s", error);
		}
		else if (results.RowCount == 0)
		{
			char steamid[32];
			if(GetClientAuthId(clientIndex, AuthId_Steam2, steamid, sizeof(steamid), true))
			{
				char query[255];
				FormatEx(query, sizeof(query), "INSERT INTO %sweapons (steamid) VALUES ('%s')", g_TablePrefix, steamid);
				DataPack pack = new DataPack();
				pack.WriteString(steamid);
				pack.WriteString(query);
				db.Query(T_InsertCallback, query, pack);
				for(int i = 0; i < sizeof(g_WeaponClasses); i++)
				{
					g_iSkins[clientIndex][i][2] = 0;
					g_iStatTrak[clientIndex][i][2] = 0;
					g_iStatTrakCount[clientIndex][i][2] = 0;
					g_NameTag[clientIndex][i][2] = "";
					g_fFloatValue[clientIndex][i][2] = 0.0;
					g_iWeaponSeed[clientIndex][i][2] = -1;
					
					g_iSkins[clientIndex][i][3] = 0;
					g_iStatTrak[clientIndex][i][3] = 0;
					g_iStatTrakCount[clientIndex][i][3] = 0;
					g_NameTag[clientIndex][i][3] = "";
					g_fFloatValue[clientIndex][i][3] = 0.0;
					g_iWeaponSeed[clientIndex][i][3] = -1;
				}
				g_iKnife[clientIndex][2] = 0;
				g_iKnife[clientIndex][3] = 0;
			}
		}
		else
		{
			if(results.FetchRow())
			{
				for(int i = 2, j = 0; j < sizeof(g_WeaponClasses); i += 6, j++) 
				{
					g_iSkins[clientIndex][j][2] = results.FetchInt(i);
					g_fFloatValue[clientIndex][j][2] = results.FetchFloat(i + 1);
					g_iStatTrak[clientIndex][j][2] = results.FetchInt(i + 2);
					g_iStatTrakCount[clientIndex][j][2] = results.FetchInt(i + 3);
					results.FetchString(i + 4, g_NameTag[clientIndex][j][2], 128);
					g_iWeaponSeed[clientIndex][j][2] = results.FetchInt(i + 5);

					g_iSkins[clientIndex][j][3] = results.FetchInt(i + (6 * 54));
					g_fFloatValue[clientIndex][j][3] = results.FetchFloat(i + (6 * 54) + 1);
					g_iStatTrak[clientIndex][j][3] = results.FetchInt(i + (6 * 54) + 2);
					g_iStatTrakCount[clientIndex][j][3] = results.FetchInt(i + (6 * 54) + 3);
					results.FetchString(i + (6 * 54) + 4, g_NameTag[clientIndex][j][3], 128);
					g_iWeaponSeed[clientIndex][j][3] = results.FetchInt(i + (6 * 54) + 5);
				}
				g_iKnife[clientIndex][2] = results.FetchInt(1);
				g_iKnife[clientIndex][3] = results.FetchInt(320);
			}
			char steamid[32];
			if(GetClientAuthId(clientIndex, AuthId_Steam2, steamid, sizeof(steamid), true))
			{
				char query[255];
				FormatEx(query, sizeof(query), "REPLACE INTO %sweapons_timestamps (steamid, last_seen) VALUES ('%s', %d)", g_TablePrefix, steamid, GetTime());
				DataPack pack = new DataPack();
				pack.WriteString(query);
				db.Query(T_TimestampCallback, query, pack);
			}
		}
	}
}

public void T_InsertCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	char steamid[32];
	pack.ReadString(steamid, 32);
	if (results == null)
	{
		char buffer[1024];
		pack.ReadString(buffer, 1024);
		LogError("Insert Query failed! query: \"%s\" error: \"%s\"", buffer, error);
	}
	else
	{
		char query[255];
		FormatEx(query, sizeof(query), "REPLACE INTO %sweapons_timestamps (steamid, last_seen) VALUES ('%s', %d)", g_TablePrefix, steamid, GetTime());
		DataPack newPack = new DataPack();
		newPack.WriteString(query);
		db.Query(T_TimestampCallback, query, newPack);
	}
	delete pack;
}

public void T_TimestampCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	if (results == null)
	{
		pack.Reset();
		char buffer[1024];
		pack.ReadString(buffer, 1024);
		LogError("Timestamp Query failed! query: \"%s\" error: \"%s\"", buffer, error);
	}
	delete pack;
}

void UpdatePlayerData(int client, char[] updateFields)
{
	char steamid[32];
	if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true))
	{
		char query[1024];
		FormatEx(query, sizeof(query), "UPDATE %sweapons SET %s WHERE steamid = '%s'", g_TablePrefix, updateFields, steamid);
		DataPack pack = new DataPack();
		pack.WriteString(query);
		db.Query(T_UpdatePlayerDataCallback, query, pack);
	}
}

public void T_UpdatePlayerDataCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	if (results == null)
	{
		pack.Reset();
		char buffer[1024];
		pack.ReadString(buffer, 1024);
		LogError("Update Player failed! query: \"%s\" error: \"%s\"", buffer, error);
	}
	delete pack;
}

public void SQLConnectCallback(Database database, const char[] error, any data)
{
	if (database == null)
	{
		LogError("Database failure: %s", error);
	}
	else
	{
		db = database;
		char dbIdentifier[10];
	
		db.Driver.GetIdentifier(dbIdentifier, sizeof(dbIdentifier));
		bool mysql = StrEqual(dbIdentifier, "mysql");
		
		CreateMainTable(mysql);
	}
}

void CreateMainTable(bool mysql)
{
	char createQuery[40960];
	
	int index = 0;
	
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
		CREATE TABLE IF NOT EXISTS %sweapons (								\
			steamid varchar(32) NOT NULL PRIMARY KEY, 						\
			knife int(4) NOT NULL DEFAULT '0', 								\
			awp int(4) NOT NULL DEFAULT '0', 								\
			awp_float decimal(3,2) NOT NULL DEFAULT '0.0', 					\
			awp_trak int(1) NOT NULL DEFAULT '0', 							\
			awp_trak_count int(10) NOT NULL DEFAULT '0', 					\
			awp_tag text, 						\
			awp_seed int(10) NOT NULL DEFAULT '-1',							\
			ak47 int(4) NOT NULL DEFAULT '0', 								\
			ak47_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ak47_trak int(1) NOT NULL DEFAULT '0', 							\
			ak47_trak_count int(10) NOT NULL DEFAULT '0', 					\
			ak47_tag text, 						\
			ak47_seed int(10) NOT NULL DEFAULT '-1',						\
			m4a1 int(4) NOT NULL DEFAULT '0', 								\
			m4a1_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			m4a1_trak int(1) NOT NULL DEFAULT '0', 							\
			m4a1_trak_count int(10) NOT NULL DEFAULT '0', 					\
			m4a1_tag text,						\
			m4a1_seed int(10) NOT NULL DEFAULT '-1', ", g_TablePrefix);
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			m4a1_silencer int(4) NOT NULL DEFAULT '0', 						\
			m4a1_silencer_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			m4a1_silencer_trak int(1) NOT NULL DEFAULT '0', 				\
			m4a1_silencer_trak_count int(10) NOT NULL DEFAULT '0', 			\
			m4a1_silencer_tag text, 			\
			m4a1_silencer_seed int(10) NOT NULL DEFAULT '-1',				\
			deagle int(4) NOT NULL DEFAULT '0', 							\
			deagle_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			deagle_trak int(1) NOT NULL DEFAULT '0', 						\
			deagle_trak_count int(10) NOT NULL DEFAULT '0', 				\
			deagle_tag text, 					\
			deagle_seed int(10) NOT NULL DEFAULT '-1',						\
			usp_silencer int(4) NOT NULL DEFAULT '0', 						\
			usp_silencer_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			usp_silencer_trak int(1) NOT NULL DEFAULT '0', 					\
			usp_silencer_trak_count int(10) NOT NULL DEFAULT '0', 			\
			usp_silencer_tag text, 				\
			usp_silencer_seed int(10) NOT NULL DEFAULT '-1',				\
			hkp2000 int(4) NOT NULL DEFAULT '0', 							\
			hkp2000_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			hkp2000_trak int(1) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			hkp2000_trak_count int(10) NOT NULL DEFAULT '0', 				\
			hkp2000_tag text, 					\
			hkp2000_seed int(10) NOT NULL DEFAULT '-1',						\
			glock int(4) NOT NULL DEFAULT '0', 								\
			glock_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			glock_trak int(1) NOT NULL DEFAULT '0', 						\
			glock_trak_count int(10) NOT NULL DEFAULT '0', 					\
			glock_tag text, 					\
			glock_seed int(10) NOT NULL DEFAULT '-1',						\
			elite int(4) NOT NULL DEFAULT '0', 								\
			elite_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			elite_trak int(1) NOT NULL DEFAULT '0', 						\
			elite_trak_count int(10) NOT NULL DEFAULT '0', 					\
			elite_tag text, 					\
			elite_seed int(10) NOT NULL DEFAULT '-1',						\
			p250 int(4) NOT NULL DEFAULT '0', 								\
			p250_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			p250_trak int(1) NOT NULL DEFAULT '0', 							\
			p250_trak_count int(10) NOT NULL DEFAULT '0', 					\
			p250_tag text, 						\
			p250_seed int(10) NOT NULL DEFAULT '-1',						\
			cz75a int(4) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			cz75a_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			cz75a_trak int(1) NOT NULL DEFAULT '0', 						\
			cz75a_trak_count int(10) NOT NULL DEFAULT '0', 					\
			cz75a_tag text, 					\
			cz75a_seed int(10) NOT NULL DEFAULT '-1',						\
			fiveseven int(4) NOT NULL DEFAULT '0', 							\
			fiveseven_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			fiveseven_trak int(1) NOT NULL DEFAULT '0', 					\
			fiveseven_trak_count int(10) NOT NULL DEFAULT '0', 				\
			fiveseven_tag text, 				\
			fiveseven_seed int(10) NOT NULL DEFAULT '-1',					\
			tec9 int(4) NOT NULL DEFAULT '0', 								\
			tec9_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			tec9_trak int(1) NOT NULL DEFAULT '0', 							\
			tec9_trak_count int(10) NOT NULL DEFAULT '0', 					\
			tec9_tag text, 						\
			tec9_seed int(10) NOT NULL DEFAULT '-1',						\
			revolver int(4) NOT NULL DEFAULT '0', 							\
			revolver_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			revolver_trak int(1) NOT NULL DEFAULT '0', 						\
			revolver_trak_count int(10) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			revolver_tag text, 					\
			revolver_seed int(10) NOT NULL DEFAULT '-1',					\
			nova int(4) NOT NULL DEFAULT '0', 								\
			nova_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			nova_trak int(1) NOT NULL DEFAULT '0', 							\
			nova_trak_count int(10) NOT NULL DEFAULT '0', 					\
			nova_tag text, 						\
			nova_seed int(10) NOT NULL DEFAULT '-1',						\
			xm1014 int(4) NOT NULL DEFAULT '0', 							\
			xm1014_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			xm1014_trak int(1) NOT NULL DEFAULT '0', 						\
			xm1014_trak_count int(10) NOT NULL DEFAULT '0', 				\
			xm1014_tag text, 					\
			xm1014_seed int(10) NOT NULL DEFAULT '-1',						\
			mag7 int(4) NOT NULL DEFAULT '0', 								\
			mag7_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			mag7_trak int(1) NOT NULL DEFAULT '0', 							\
			mag7_trak_count int(10) NOT NULL DEFAULT '0', 					\
			mag7_tag text, 						\
			mag7_seed int(10) NOT NULL DEFAULT '-1',						\
			sawedoff int(4) NOT NULL DEFAULT '0', 							\
			sawedoff_float decimal(3,2) NOT NULL DEFAULT '0.0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			sawedoff_trak int(1) NOT NULL DEFAULT '0', 						\
			sawedoff_trak_count int(10) NOT NULL DEFAULT '0', 				\
			sawedoff_tag text, 					\
			sawedoff_seed int(10) NOT NULL DEFAULT '-1',					\
			m249 int(4) NOT NULL DEFAULT '0', 								\
			m249_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			m249_trak int(1) NOT NULL DEFAULT '0', 							\
			m249_trak_count int(10) NOT NULL DEFAULT '0', 					\
			m249_tag text, 						\
			m249_seed int(10) NOT NULL DEFAULT '-1',						\
			negev int(4) NOT NULL DEFAULT '0', 								\
			negev_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			negev_trak int(1) NOT NULL DEFAULT '0', 						\
			negev_trak_count int(10) NOT NULL DEFAULT '0', 					\
			negev_tag text, 					\
			negev_seed int(10) NOT NULL DEFAULT '-1',						\
			mp9 int(4) NOT NULL DEFAULT '0', 								\
			mp9_float decimal(3,2) NOT NULL DEFAULT '0.0', 					\
			mp9_trak int(1) NOT NULL DEFAULT '0', 							\
			mp9_trak_count int(10) NOT NULL DEFAULT '0', 					\
			mp9_tag text,						\
			mp9_seed int(10) NOT NULL DEFAULT '-1', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			mac10 int(4) NOT NULL DEFAULT '0', 								\
			mac10_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			mac10_trak int(1) NOT NULL DEFAULT '0', 						\
			mac10_trak_count int(10) NOT NULL DEFAULT '0', 					\
			mac10_tag text, 					\
			mac10_seed int(10) NOT NULL DEFAULT '-1',						\
			mp7 int(4) NOT NULL DEFAULT '0', 								\
			mp7_float decimal(3,2) NOT NULL DEFAULT '0.0', 					\
			mp7_trak int(1) NOT NULL DEFAULT '0', 							\
			mp7_trak_count int(10) NOT NULL DEFAULT '0', 					\
			mp7_tag text, 						\
			mp7_seed int(10) NOT NULL DEFAULT '-1',							\
			ump45 int(4) NOT NULL DEFAULT '0', 								\
			ump45_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ump45_trak int(1) NOT NULL DEFAULT '0', 						\
			ump45_trak_count int(10) NOT NULL DEFAULT '0', 					\
			ump45_tag text, 					\
			ump45_seed int(10) NOT NULL DEFAULT '-1',						\
			p90 int(4) NOT NULL DEFAULT '0', 								\
			p90_float decimal(3,2) NOT NULL DEFAULT '0.0', 					\
			p90_trak int(1) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			p90_trak_count int(10) NOT NULL DEFAULT '0', 					\
			p90_tag text, 						\
			p90_seed int(10) NOT NULL DEFAULT '-1',							\
			bizon int(4) NOT NULL DEFAULT '0', 								\
			bizon_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			bizon_trak int(1) NOT NULL DEFAULT '0', 						\
			bizon_trak_count int(10) NOT NULL DEFAULT '0', 					\
			bizon_tag text, 					\
			bizon_seed int(10) NOT NULL DEFAULT '-1',						\
			famas int(4) NOT NULL DEFAULT '0', 								\
			famas_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			famas_trak int(1) NOT NULL DEFAULT '0', 						\
			famas_trak_count int(10) NOT NULL DEFAULT '0', 					\
			famas_tag text, 					\
			famas_seed int(10) NOT NULL DEFAULT '-1',						\
			galilar int(4) NOT NULL DEFAULT '0', 							\
			galilar_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			galilar_trak int(1) NOT NULL DEFAULT '0', 						\
			galilar_trak_count int(10) NOT NULL DEFAULT '0', 				\
			galilar_tag text, 					\
			galilar_seed int(10) NOT NULL DEFAULT '-1',						\
			ssg08 int(4) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ssg08_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ssg08_trak int(1) NOT NULL DEFAULT '0', 						\
			ssg08_trak_count int(10) NOT NULL DEFAULT '0', 					\
			ssg08_tag text, 					\
			ssg08_seed int(10) NOT NULL DEFAULT '-1',						\
			aug int(4) NOT NULL DEFAULT '0', 								\
			aug_float decimal(3,2) NOT NULL DEFAULT '0.0', 					\
			aug_trak int(1) NOT NULL DEFAULT '0', 							\
			aug_trak_count int(10) NOT NULL DEFAULT '0', 					\
			aug_tag text, 						\
			aug_seed int(10) NOT NULL DEFAULT '-1',							\
			sg556 int(4) NOT NULL DEFAULT '0', 								\
			sg556_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			sg556_trak int(1) NOT NULL DEFAULT '0', 						\
			sg556_trak_count int(10) NOT NULL DEFAULT '0', 					\
			sg556_tag text, 					\
			sg556_seed int(10) NOT NULL DEFAULT '-1',						\
			scar20 int(4) NOT NULL DEFAULT '0', 							\
			scar20_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			scar20_trak int(1) NOT NULL DEFAULT '0', 						\
			scar20_trak_count int(10) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			scar20_tag text, 					\
			scar20_seed int(10) NOT NULL DEFAULT '-1',						\
			g3sg1 int(4) NOT NULL DEFAULT '0', 								\
			g3sg1_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			g3sg1_trak int(1) NOT NULL DEFAULT '0', 						\
			g3sg1_trak_count int(10) NOT NULL DEFAULT '0', 					\
			g3sg1_tag text, 					\
			g3sg1_seed int(10) NOT NULL DEFAULT '-1',						\
			knife_karambit int(4) NOT NULL DEFAULT '0', 					\
			knife_karambit_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			knife_karambit_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_karambit_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_karambit_tag text, 			\
			knife_karambit_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_m9_bayonet int(4) NOT NULL DEFAULT '0', 					\
			knife_m9_bayonet_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			knife_m9_bayonet_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_m9_bayonet_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_m9_bayonet_tag text, 			\
			knife_m9_bayonet_seed int(10) NOT NULL DEFAULT '-1',			\
			bayonet int(4) NOT NULL DEFAULT '0', 							\
			bayonet_float decimal(3,2) NOT NULL DEFAULT '0.0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			bayonet_trak int(1) NOT NULL DEFAULT '0', 						\
			bayonet_trak_count int(10) NOT NULL DEFAULT '0', 				\
			bayonet_tag text, 					\
			bayonet_seed int(10) NOT NULL DEFAULT '-1',						\
			knife_survival_bowie int(4) NOT NULL DEFAULT '0', 				\
			knife_survival_bowie_float decimal(3,2) NOT NULL DEFAULT '0.0', \
			knife_survival_bowie_trak int(1) NOT NULL DEFAULT '0', 			\
			knife_survival_bowie_trak_count int(10) NOT NULL DEFAULT '0', 	\
			knife_survival_bowie_tag text, 		\
			knife_survival_bowie_seed int(10) NOT NULL DEFAULT '-1',		\
			knife_butterfly int(4) NOT NULL DEFAULT '0', 					\
			knife_butterfly_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			knife_butterfly_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_butterfly_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_butterfly_tag text, 			\
			knife_butterfly_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_flip int(4) NOT NULL DEFAULT '0', 						\
			knife_flip_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			knife_flip_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_flip_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_flip_tag text,				\
			knife_flip_seed int(10) NOT NULL DEFAULT '-1', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			knife_push int(4) NOT NULL DEFAULT '0', 						\
			knife_push_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			knife_push_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_push_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_push_tag text, 				\
			knife_push_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_tactical int(4) NOT NULL DEFAULT '0', 					\
			knife_tactical_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			knife_tactical_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_tactical_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_tactical_tag text, 			\
			knife_tactical_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_falchion int(4) NOT NULL DEFAULT '0', 					\
			knife_falchion_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			knife_falchion_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_falchion_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_falchion_tag text, 			\
			knife_falchion_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_gut int(4) NOT NULL DEFAULT '0', 							\
			knife_gut_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			knife_gut_trak int(1) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			knife_gut_trak_count int(10) NOT NULL DEFAULT '0', 				\
			knife_gut_tag text, 				\
			knife_gut_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_ursus int(4) NOT NULL DEFAULT '0', 						\
			knife_ursus_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			knife_ursus_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_ursus_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_ursus_tag text, 				\
			knife_ursus_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_gypsy_jackknife int(4) NOT NULL DEFAULT '0', 				\
			knife_gypsy_jackknife_float decimal(3,2) NOT NULL DEFAULT '0.0',\
			knife_gypsy_jackknife_trak int(1) NOT NULL DEFAULT '0', 		\
			knife_gypsy_jackknife_trak_count int(10) NOT NULL DEFAULT '0', 	\
			knife_gypsy_jackknife_tag text, 	\
			knife_gypsy_jackknife_seed int(10) NOT NULL DEFAULT '-1',		\
			knife_stiletto int(4) NOT NULL DEFAULT '0', 					\
			knife_stiletto_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			knife_stiletto_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_stiletto_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_stiletto_tag text, 			\
			knife_stiletto_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_widowmaker int(4) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			knife_widowmaker_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			knife_widowmaker_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_widowmaker_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_widowmaker_tag text,			\
			knife_widowmaker_seed int(10) NOT NULL DEFAULT '-1',			\
			mp5sd int(4) NOT NULL DEFAULT '0', 								\
			mp5sd_float decimal(3,2) NOT NULL DEFAULT '0.0',				\
			mp5sd_trak int(1) NOT NULL DEFAULT '0', 						\
			mp5sd_trak_count int(10) NOT NULL DEFAULT '0',					\
			mp5sd_tag text,						\
			mp5sd_seed int(10) NOT NULL DEFAULT '-1',						\
			knife_css int(4) NOT NULL DEFAULT '0', 							\
			knife_css_float decimal(3,2) NOT NULL DEFAULT '0.0',			\
			knife_css_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_css_trak_count int(10) NOT NULL DEFAULT '0', 				\
			knife_css_tag text, 				\
			knife_css_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_cord int(4) NOT NULL DEFAULT '0', 						\
			knife_cord_float decimal(3,2) NOT NULL DEFAULT '0.0',			\
			knife_cord_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_cord_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_cord_tag text, ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			knife_cord_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_canis int(4) NOT NULL DEFAULT '0', 						\
			knife_canis_float decimal(3,2) NOT NULL DEFAULT '0.0',			\
			knife_canis_trak int(1) NOT NULL DEFAULT '0', 					\
			knife_canis_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_canis_tag text, 				\
			knife_canis_seed int(10) NOT NULL DEFAULT '-1',					\
			knife_outdoor int(4) NOT NULL DEFAULT '0', 						\
			knife_outdoor_float decimal(3,2) NOT NULL DEFAULT '0.0',		\
			knife_outdoor_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_outdoor_trak_count int(10) NOT NULL DEFAULT '0', 			\
			knife_outdoor_tag text, 			\
			knife_outdoor_seed int(10) NOT NULL DEFAULT '-1',				\
			knife_skeleton int(4) NOT NULL DEFAULT '0', 					\
			knife_skeleton_float decimal(3,2) NOT NULL DEFAULT '0.0',		\
			knife_skeleton_trak int(1) NOT NULL DEFAULT '0', 				\
			knife_skeleton_trak_count int(10) NOT NULL DEFAULT '0', 		\
			knife_skeleton_tag text, 			\
			knife_skeleton_seed int(10) NOT NULL DEFAULT '-1', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_knife int(4) NOT NULL DEFAULT '0', 							\
			ct_knife_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_knife_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_knife_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_knife_tag text, 					\
			ct_knife_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_awp int(4) NOT NULL DEFAULT '0', 							\
			ct_awp_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_awp_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_awp_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_awp_tag text, 					\
			ct_awp_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_ak47 int(4) NOT NULL DEFAULT '0', 							\
			ct_ak47_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_ak47_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_ak47_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_ak47_tag text, 					\
			ct_ak47_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_m4a1 int(4) NOT NULL DEFAULT '0', 							\
			ct_m4a1_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_m4a1_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_m4a1_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_m4a1_tag text,					\
			ct_m4a1_seed int(10) NOT NULL DEFAULT '-1', ", g_TablePrefix);
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_m4a1_silencer int(4) NOT NULL DEFAULT '0', 					\
			ct_m4a1_silencer_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			ct_m4a1_silencer_trak int(1) NOT NULL DEFAULT '0', 				\
			ct_m4a1_silencer_trak_count int(10) NOT NULL DEFAULT '0', 		\
			ct_m4a1_silencer_tag text, 			\
			ct_m4a1_silencer_seed int(10) NOT NULL DEFAULT '-1',			\
			ct_deagle int(4) NOT NULL DEFAULT '0', 							\
			ct_deagle_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_deagle_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_deagle_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_deagle_tag text, 				\
			ct_deagle_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_usp_silencer int(4) NOT NULL DEFAULT '0', 					\
			ct_usp_silencer_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			ct_usp_silencer_trak int(1) NOT NULL DEFAULT '0', 				\
			ct_usp_silencer_trak_count int(10) NOT NULL DEFAULT '0', 		\
			ct_usp_silencer_tag text, 			\
			ct_usp_silencer_seed int(10) NOT NULL DEFAULT '-1',				\
			ct_hkp2000 int(4) NOT NULL DEFAULT '0', 						\
			ct_hkp2000_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_hkp2000_trak int(1) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_hkp2000_trak_count int(10) NOT NULL DEFAULT '0', 			\
			ct_hkp2000_tag text, 				\
			ct_hkp2000_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_glock int(4) NOT NULL DEFAULT '0', 							\
			ct_glock_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_glock_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_glock_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_glock_tag text, 					\
			ct_glock_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_elite int(4) NOT NULL DEFAULT '0', 							\
			ct_elite_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_elite_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_elite_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_elite_tag text, 					\
			ct_elite_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_p250 int(4) NOT NULL DEFAULT '0', 							\
			ct_p250_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_p250_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_p250_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_p250_tag text, 					\
			ct_p250_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_cz75a int(4) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_cz75a_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_cz75a_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_cz75a_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_cz75a_tag text, 					\
			ct_cz75a_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_fiveseven int(4) NOT NULL DEFAULT '0', 						\
			ct_fiveseven_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			ct_fiveseven_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_fiveseven_trak_count int(10) NOT NULL DEFAULT '0', 			\
			ct_fiveseven_tag text, 				\
			ct_fiveseven_seed int(10) NOT NULL DEFAULT '-1',				\
			ct_tec9 int(4) NOT NULL DEFAULT '0', 							\
			ct_tec9_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_tec9_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_tec9_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_tec9_tag text, 					\
			ct_tec9_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_revolver int(4) NOT NULL DEFAULT '0', 						\
			ct_revolver_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_revolver_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_revolver_trak_count int(10) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_revolver_tag text, 				\
			ct_revolver_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_nova int(4) NOT NULL DEFAULT '0', 							\
			ct_nova_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_nova_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_nova_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_nova_tag text, 					\
			ct_nova_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_xm1014 int(4) NOT NULL DEFAULT '0', 							\
			ct_xm1014_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_xm1014_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_xm1014_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_xm1014_tag text, 				\
			ct_xm1014_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_mag7 int(4) NOT NULL DEFAULT '0', 							\
			ct_mag7_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_mag7_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_mag7_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_mag7_tag text, 					\
			ct_mag7_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_sawedoff int(4) NOT NULL DEFAULT '0', 						\
			ct_sawedoff_float decimal(3,2) NOT NULL DEFAULT '0.0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_sawedoff_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_sawedoff_trak_count int(10) NOT NULL DEFAULT '0', 			\
			ct_sawedoff_tag text, 				\
			ct_sawedoff_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_m249 int(4) NOT NULL DEFAULT '0', 							\
			ct_m249_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_m249_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_m249_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_m249_tag text, 					\
			ct_m249_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_negev int(4) NOT NULL DEFAULT '0', 							\
			ct_negev_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_negev_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_negev_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_negev_tag text, 					\
			ct_negev_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_mp9 int(4) NOT NULL DEFAULT '0', 							\
			ct_mp9_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_mp9_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_mp9_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_mp9_tag text,					\
			ct_mp9_seed int(10) NOT NULL DEFAULT '-1', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_mac10 int(4) NOT NULL DEFAULT '0', 							\
			ct_mac10_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_mac10_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_mac10_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_mac10_tag text, 					\
			ct_mac10_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_mp7 int(4) NOT NULL DEFAULT '0', 							\
			ct_mp7_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_mp7_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_mp7_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_mp7_tag text, 					\
			ct_mp7_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_ump45 int(4) NOT NULL DEFAULT '0', 							\
			ct_ump45_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_ump45_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_ump45_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_ump45_tag text, 					\
			ct_ump45_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_p90 int(4) NOT NULL DEFAULT '0', 							\
			ct_p90_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_p90_trak int(1) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_p90_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_p90_tag text, 					\
			ct_p90_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_bizon int(4) NOT NULL DEFAULT '0', 							\
			ct_bizon_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_bizon_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_bizon_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_bizon_tag text, 					\
			ct_bizon_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_famas int(4) NOT NULL DEFAULT '0', 							\
			ct_famas_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_famas_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_famas_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_famas_tag text, 					\
			ct_famas_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_galilar int(4) NOT NULL DEFAULT '0', 						\
			ct_galilar_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_galilar_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_galilar_trak_count int(10) NOT NULL DEFAULT '0', 			\
			ct_galilar_tag text, 				\
			ct_galilar_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_ssg08 int(4) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_ssg08_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_ssg08_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_ssg08_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_ssg08_tag text, 					\
			ct_ssg08_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_aug int(4) NOT NULL DEFAULT '0', 							\
			ct_aug_float decimal(3,2) NOT NULL DEFAULT '0.0', 				\
			ct_aug_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_aug_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_aug_tag text, 					\
			ct_aug_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_sg556 int(4) NOT NULL DEFAULT '0', 							\
			ct_sg556_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_sg556_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_sg556_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_sg556_tag text, 					\
			ct_sg556_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_scar20 int(4) NOT NULL DEFAULT '0', 							\
			ct_scar20_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_scar20_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_scar20_trak_count int(10) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_scar20_tag text, 				\
			ct_scar20_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_g3sg1 int(4) NOT NULL DEFAULT '0', 							\
			ct_g3sg1_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_g3sg1_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_g3sg1_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_g3sg1_tag text, 					\
			ct_g3sg1_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_knife_karambit int(4) NOT NULL DEFAULT '0', 					\
			ct_knife_karambit_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			ct_knife_karambit_trak int(1) NOT NULL DEFAULT '0', 			\
			ct_knife_karambit_trak_count int(10) NOT NULL DEFAULT '0', 		\
			ct_knife_karambit_tag text, 		\
			ct_knife_karambit_seed int(10) NOT NULL DEFAULT '-1',			\
			ct_knife_m9_bayonet int(4) NOT NULL DEFAULT '0', 				\
			ct_knife_m9_bayonet_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			ct_knife_m9_bayonet_trak int(1) NOT NULL DEFAULT '0', 			\
			ct_knife_m9_bayonet_trak_count int(10) NOT NULL DEFAULT '0', 	\
			ct_knife_m9_bayonet_tag text, 		\
			ct_knife_m9_bayonet_seed int(10) NOT NULL DEFAULT '-1',			\
			ct_bayonet int(4) NOT NULL DEFAULT '0', 						\
			ct_bayonet_float decimal(3,2) NOT NULL DEFAULT '0.0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_bayonet_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_bayonet_trak_count int(10) NOT NULL DEFAULT '0', 			\
			ct_bayonet_tag text, 				\
			ct_bayonet_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_knife_survival_bowie int(4) NOT NULL DEFAULT '0', 			\
			ct_knife_survival_bowie_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			ct_knife_survival_bowie_trak int(1) NOT NULL DEFAULT '0', 			\
			ct_knife_survival_bowie_trak_count int(10) NOT NULL DEFAULT '0', 	\
			ct_knife_survival_bowie_tag text, 		\
			ct_knife_survival_bowie_seed int(10) NOT NULL DEFAULT '-1',			\
			ct_knife_butterfly int(4) NOT NULL DEFAULT '0', 					\
			ct_knife_butterfly_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			ct_knife_butterfly_trak int(1) NOT NULL DEFAULT '0', 				\
			ct_knife_butterfly_trak_count int(10) NOT NULL DEFAULT '0', 		\
			ct_knife_butterfly_tag text, 			\
			ct_knife_butterfly_seed int(10) NOT NULL DEFAULT '-1',				\
			ct_knife_flip int(4) NOT NULL DEFAULT '0', 							\
			ct_knife_flip_float decimal(3,2) NOT NULL DEFAULT '0.0', 			\
			ct_knife_flip_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_knife_flip_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_knife_flip_tag text,				\
			ct_knife_flip_seed int(10) NOT NULL DEFAULT '-1', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_knife_push int(4) NOT NULL DEFAULT '0', 						\
			ct_knife_push_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			ct_knife_push_trak int(1) NOT NULL DEFAULT '0', 				\
			ct_knife_push_trak_count int(10) NOT NULL DEFAULT '0', 			\
			ct_knife_push_tag text, 			\
			ct_knife_push_seed int(10) NOT NULL DEFAULT '-1',				\
			ct_knife_tactical int(4) NOT NULL DEFAULT '0', 					\
			ct_knife_tactical_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			ct_knife_tactical_trak int(1) NOT NULL DEFAULT '0', 			\
			ct_knife_tactical_trak_count int(10) NOT NULL DEFAULT '0', 		\
			ct_knife_tactical_tag text, 		\
			ct_knife_tactical_seed int(10) NOT NULL DEFAULT '-1',			\
			ct_knife_falchion int(4) NOT NULL DEFAULT '0', 					\
			ct_knife_falchion_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			ct_knife_falchion_trak int(1) NOT NULL DEFAULT '0', 			\
			ct_knife_falchion_trak_count int(10) NOT NULL DEFAULT '0', 		\
			ct_knife_falchion_tag text, 		\
			ct_knife_falchion_seed int(10) NOT NULL DEFAULT '-1',			\
			ct_knife_gut int(4) NOT NULL DEFAULT '0', 						\
			ct_knife_gut_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			ct_knife_gut_trak int(1) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_knife_gut_trak_count int(10) NOT NULL DEFAULT '0', 			\
			ct_knife_gut_tag text, 				\
			ct_knife_gut_seed int(10) NOT NULL DEFAULT '-1',				\
			ct_knife_ursus int(4) NOT NULL DEFAULT '0', 					\
			ct_knife_ursus_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			ct_knife_ursus_trak int(1) NOT NULL DEFAULT '0', 				\
			ct_knife_ursus_trak_count int(10) NOT NULL DEFAULT '0', 		\
			ct_knife_ursus_tag text, 			\
			ct_knife_ursus_seed int(10) NOT NULL DEFAULT '-1',				\
			ct_knife_gypsy_jackknife int(4) NOT NULL DEFAULT '0', 			\
			ct_knife_gypsy_jackknife_float decimal(3,2) NOT NULL DEFAULT '0.0',\
			ct_knife_gypsy_jackknife_trak int(1) NOT NULL DEFAULT '0', 		\
			ct_knife_gypsy_jackknife_trak_count int(10) NOT NULL DEFAULT '0', 	\
			ct_knife_gypsy_jackknife_tag text, 	\
			ct_knife_gypsy_jackknife_seed int(10) NOT NULL DEFAULT '-1',		\
			ct_knife_stiletto int(4) NOT NULL DEFAULT '0', 					\
			ct_knife_stiletto_float decimal(3,2) NOT NULL DEFAULT '0.0', 		\
			ct_knife_stiletto_trak int(1) NOT NULL DEFAULT '0', 				\
			ct_knife_stiletto_trak_count int(10) NOT NULL DEFAULT '0', 		\
			ct_knife_stiletto_tag text, 			\
			ct_knife_stiletto_seed int(10) NOT NULL DEFAULT '-1',				\
			ct_knife_widowmaker int(4) NOT NULL DEFAULT '0', ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_knife_widowmaker_float decimal(3,2) NOT NULL DEFAULT '0.0', 	\
			ct_knife_widowmaker_trak int(1) NOT NULL DEFAULT '0', 				\
			ct_knife_widowmaker_trak_count int(10) NOT NULL DEFAULT '0', 		\
			ct_knife_widowmaker_tag text,			\
			ct_knife_widowmaker_seed int(10) NOT NULL DEFAULT '-1',			\
			ct_mp5sd int(4) NOT NULL DEFAULT '0', 								\
			ct_mp5sd_float decimal(3,2) NOT NULL DEFAULT '0.0',				\
			ct_mp5sd_trak int(1) NOT NULL DEFAULT '0', 						\
			ct_mp5sd_trak_count int(10) NOT NULL DEFAULT '0',					\
			ct_mp5sd_tag text,						\
			ct_mp5sd_seed int(10) NOT NULL DEFAULT '-1',						\
			ct_knife_css int(4) NOT NULL DEFAULT '0', 							\
			ct_knife_css_float decimal(3,2) NOT NULL DEFAULT '0.0',			\
			ct_knife_css_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_knife_css_trak_count int(10) NOT NULL DEFAULT '0', 				\
			ct_knife_css_tag text, 				\
			ct_knife_css_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_knife_cord int(4) NOT NULL DEFAULT '0', 						\
			ct_knife_cord_float decimal(3,2) NOT NULL DEFAULT '0.0',			\
			ct_knife_cord_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_knife_cord_trak_count int(10) NOT NULL DEFAULT '0', 			\
			ct_knife_cord_tag text, ");
	index += FormatEx(createQuery[index], sizeof(createQuery) - index, "	\
			ct_knife_cord_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_knife_canis int(4) NOT NULL DEFAULT '0', 						\
			ct_knife_canis_float decimal(3,2) NOT NULL DEFAULT '0.0',			\
			ct_knife_canis_trak int(1) NOT NULL DEFAULT '0', 					\
			ct_knife_canis_trak_count int(10) NOT NULL DEFAULT '0', 			\
			ct_knife_canis_tag text, 				\
			ct_knife_canis_seed int(10) NOT NULL DEFAULT '-1',					\
			ct_knife_outdoor int(4) NOT NULL DEFAULT '0', 						\
			ct_knife_outdoor_float decimal(3,2) NOT NULL DEFAULT '0.0',		\
			ct_knife_outdoor_trak int(1) NOT NULL DEFAULT '0', 				\
			ct_knife_outdoor_trak_count int(10) NOT NULL DEFAULT '0', 			\
			ct_knife_outdoor_tag text, 			\
			ct_knife_outdoor_seed int(10) NOT NULL DEFAULT '-1',				\
			ct_knife_skeleton int(4) NOT NULL DEFAULT '0', 					\
			ct_knife_skeleton_float decimal(3,2) NOT NULL DEFAULT '0.0',		\
			ct_knife_skeleton_trak int(1) NOT NULL DEFAULT '0', 				\
			ct_knife_skeleton_trak_count int(10) NOT NULL DEFAULT '0', 		\
			ct_knife_skeleton_tag text, 			\
			ct_knife_skeleton_seed int(10) NOT NULL DEFAULT '-1')");
	
	if (mysql)
	{
		 index += FormatEx(createQuery[index], sizeof(createQuery) - index, " ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
	}
	
	db.Query(T_CreateMainTableCallback, createQuery, mysql, DBPrio_High);
}

public void T_CreateMainTableCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		LogError("%s Creating the main table has failed! %s", (mysql ? "MySQL" : "SQLite"), error);
	}
	else
	{
		char createQuery[512];
		Format(createQuery, sizeof(createQuery), "			\
			CREATE TABLE %sweapons_timestamps ( 			\
				steamid varchar(32) NOT NULL PRIMARY KEY, 	\
				last_seen int(11) NOT NULL)", g_TablePrefix);
		
		if (mysql)
		{
			 Format(createQuery, sizeof(createQuery), "%s ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;", createQuery);
		}
		
		db.Query(T_CreateTimestampTableCallback, createQuery, mysql, DBPrio_High);
	}
}


public void T_CreateTimestampTableCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		if(++g_iDatabaseState > 1)
		{
			LogMessage("%s DB connection successful", (mysql ? "MySQL" : "SQLite"));
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsClientAuthorized(i))
				{
					OnClientPostAdminCheck(i);
				}
			}
			DeleteInactivePlayerData();
		}
	}
	else
	{
		char insertQuery[512];
		Format(insertQuery, sizeof(insertQuery), "	\
			INSERT INTO %sweapons_timestamps  		\
				SELECT steamid, %d FROM %sweapons", g_TablePrefix, GetTime(), g_TablePrefix);
		
		db.Query(T_InsertTimestampsCallback, insertQuery, mysql, DBPrio_High);
	}
}

public void T_InsertTimestampsCallback(Database database, DBResultSet results, const char[] error, bool mysql)
{
	if (results == null)
	{
		LogError("%s Insert timestamps failed! %s", (mysql ? "MySQL" : "SQLite"), error);
	}
	else
	{
		if(++g_iDatabaseState > 1)
		{
			LogMessage("%s DB connection successful", (mysql ? "MySQL" : "SQLite"));
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsClientAuthorized(i))
				{
					OnClientPostAdminCheck(i);
				}
			}
			DeleteInactivePlayerData();
		}
	}
}

void DeleteInactivePlayerData()
{
	if(g_iGraceInactiveDays > 0)
	{
		char query[255];
		int now = GetTime();
		FormatEx(query, sizeof(query), "DELETE FROM %sweapons WHERE steamid in (SELECT steamid FROM %sweapons_timestamps WHERE last_seen < %d - (%d * 86400))", g_TablePrefix, g_TablePrefix, now, g_iGraceInactiveDays);
		DataPack pack = new DataPack();
		pack.WriteCell(now);
		pack.WriteString(query);
		db.Query(T_DeleteInactivePlayerDataCallback, query, pack);
	}
}

public void T_DeleteInactivePlayerDataCallback(Database database, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	int now = pack.ReadCell();
	if (results == null)
	{
		char buffer[1024];
		pack.ReadString(buffer, 1024);
		LogError("Delete Inactive Player Data failed! query: \"%s\" error: \"%s\"", buffer, error);
	}
	else
	{
		if(now > 0)
		{
			char query[255];
			FormatEx(query, sizeof(query), "DELETE FROM %sweapons_timestamps WHERE last_seen < %d - (%d * 86400)", g_TablePrefix, now, g_iGraceInactiveDays);
			DataPack newPack = new DataPack();
			newPack.WriteCell(0);
			newPack.WriteString(query);
			db.Query(T_DeleteInactivePlayerDataCallback, query, newPack);
		}
		else
		{
			LogMessage("Inactive players' data has been deleted");
		}
	}
	delete pack;
}